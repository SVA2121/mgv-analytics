import streamlit as st
import pandas as pd
import os
import plotly.express as px
import plotly.graph_objects as go
#from web3 import Web3 
from datetime import datetime, timedelta
import json
import numpy as np

CONN = st.connection("postgresql", type="sql")
#####################
# Helper Functions
####################
def execute_query_from_file(filename: str, kwargs = None) -> pd.DataFrame:
    query_file = os.path.join('queries', filename)
    with open(query_file, 'r') as f:
        query_str = f.read()
        if kwargs:
            query_str = query_str.format(**{key: f"'{value}'" for key, value in kwargs.items()})
    return CONN.query(query_str)

#blast =  Web3(Web3.HTTPProvider('https://rpc.blast.io'))


def get_balances() -> pd.DataFrame:
    tokens = {
        'USDB': "0x4300000000000000000000000000000000000003",
        'WETH': "0x4300000000000000000000000000000000000004",
        'PUNKS20' : "0x9a50953716bA58e3d6719Ea5c437452ac578705F",
        'PUNKS40' : "0x999f220296B5843b2909Cc5f8b4204AacA5341D8",
      }
    address_to_check = {
        'researchMainAccount': "0x4716accb346ddedcda859db0101a0e74bb686700",
        'researchTestAccount': "0x3FD9B7960a47f16250Db3fb853B86cEe54c220c8",
        'HeKBotAccount' :"0xc852df6f5aB7F22A18388D821093f74e5F0992D0",
        'MetaStreetAccount': "0xF6681cb5f5A5804b159Eb4fdAAe222286c61F6FF",
        'Kandle_WETH_USDB_1':  "0x4e44d45e57021C3ce22433C748669b6ca03F2D5C",
        'Kandle_WETH_USDB_2':  "0xbFa472A82cE3b0f12a890AF735F63860493E0494",
        'Kandle_WETH_PUNKS20': "0x0Ce773E17755B00f3E17b87C5C666c9511751261",
        'Kandle_WETH_PUNKS40': "0x0f0210181f7dac6307878C8EeD6A851b3EF1d3a7",
      }
    with open('abis/ERC20.json', 'r') as file:
        erc20_abi = json.load(file)
    filename = 'balances/balances_' + datetime.today().strftime('%Y%m%d') + '.csv'
    if os.path.exists(filename):
        print('Balances from cache')
        res = pd.read_csv(filename, index_col=0)
    else:
        res = address_to_check.copy()
        for name, address in address_to_check.items():
            balances = tokens.copy()
            for token, token_address in tokens.items():
                contract = blast.eth.contract(address = token_address,
                                        abi = erc20_abi)
                balance = contract.functions.balanceOf(Web3.to_checksum_address(address)).call()
                decimals = contract.functions.decimals().call()
                balances[token] = balance / 10**decimals
            res[name] = balances
        res = pd.DataFrame(res)
        res.to_csv(filename)
    return res

def get_prices() -> pd.DataFrame:
    prices = execute_query_from_file('mgv_prices.sql')
    prices.index = pd.to_datetime(prices.creation_date.apply(int), unit='s')
    prices.drop('creation_date', axis = 1, inplace = True)
    prices = prices.bfill().ffill()
    prices.resample('D').last()
    return prices

st.title("Research Kandels Analytics")

overall, by_instance = st.tabs(["Wallet Analytics", "Deep Dive by Instance"])

    
overall.markdown("## Overall Research Wallet Analytics")
col1up, col2up = overall.columns(2)
col1up.metric(label = "Research Account MtM", value=1000)
col2up.metric(label = "Research Account MtM", value=1000)
col1up.markdown("#### Balances")

#balances = get_balances()
#col1up.dataframe(balances)


overall.markdown("## Research Volume Metrics")

volume = execute_query_from_file('quote_volume_research.sql')
volume.index = volume.creation_date
volume.drop('creation_date', axis = 1, inplace = True)
volume['total_volume'] = volume.quote_volume.cumsum()


col1vol, col2vol, col3vol, col4vol = overall.columns(4)
col1vol.metric("Total Volume USDB", "{:,.0f}".format(volume.total_volume.iloc[-1]))
col2vol.metric("Total Volume USDB (24H)", "{:,.0f}".format(volume.last_24h_volume.sum()))
col3vol.metric("Total # Transactions", "{:,.0f}".format(volume.n_transactions.sum()))
col4vol.metric("Total # Transactions (24H)", "{:,.0f}".format(volume.last_24h_transactions.sum()))
# Plot stacked area chart
fig_vol = go.Figure()

fig_vol.add_trace(go.Bar(x=volume.index, y=volume.quote_volume, name='Volume'))
fig_vol.add_trace(go.Scatter(x=volume.index, y=volume.total_volume,
                                 mode='lines', name = 'Total Volume'))

# Update layout
fig_vol.update_layout(title='Volume by Day',
                        yaxis_title='Volume in USDB',
                        xaxis=dict(title='Day'))

overall.plotly_chart(fig_vol, use_container_width= True)


by_instance.markdown("## Deep Dive")

by_instance.markdown("#### Address")
wallet = by_instance.selectbox(label= "Choose a user address", options = ["4716accb346ddedcda859db0101a0e74bb686700"])

by_instance.markdown("#### Instances")
research_kandels = execute_query_from_file('research_kandels.sql', {'wallet' : wallet})
by_instance.dataframe(research_kandels)

instance = by_instance.selectbox(label="Select an instance for details",
                      options = research_kandels.instance_address)

by_instance.markdown("#### Resets")
resets = execute_query_from_file('kandel_instance_resets.sql', {'instance' : instance})
by_instance.dataframe(resets)

reset_id = by_instance.selectbox(label="Select a reset id", options = resets.reset_id.unique())

is_live_version = reset_id == resets.reset_id.max()

instance = resets[resets.reset_id == reset_id]

if not is_live_version:

    by_instance.markdown("## Parameters")
    price_at_start = execute_query_from_file('get_last_price.sql',
                                            {'block' : int(instance.reset_block.iloc[0])})
    price_at_start = float(price_at_start.iloc[0])
    price_at_end = execute_query_from_file('get_last_price.sql',
                                            {'block' : int(instance.exit_block.iloc[0])})
    price_at_end = float(price_at_end.iloc[0])

    col1, col2 = by_instance.columns(2)
    col1.metric("Reset Date", pd.to_datetime(instance.reset_date.min()).strftime("%Y-%M-%d : %HH:%MM"))
    col2.metric("Exit Date", pd.to_datetime(instance.exit_date.max()).strftime("%Y-%M-%d : %HH:%MM"))
    instance_duration = (instance.exit_date.max() - instance.reset_date.min()).total_seconds() / 60 / 1440
    col1.metric("Kandel Duration (in days)", "{:,.2f}".format(instance_duration))
    col2.metric('', None)
    col1.metric("Start Price", "{:,.0f}".format(price_at_start))
    col2.metric("End Price", "{:,.0f}".format(price_at_end))

    col1, col2, col3, col4 = by_instance.columns(4)
    col1.metric("Initial Quote", float(instance[instance.tkn == 'USDB'].deposited_amount.iloc[0]))
    col2.metric("Final Quote", float(instance[instance.tkn == 'USDB'].withdrawn_amount.iloc[0]))
    col3.metric("Initial Base", float(instance[instance.tkn == 'WETH'].deposited_amount.iloc[0]))
    col4.metric("Final Base", float(instance[instance.tkn == 'WETH'].withdrawn_amount.iloc[0]))

    price_grid = execute_query_from_file('price_grid.sql',
                        {'instance' : instance.instance_address.iloc[0],
                          'block' : instance.reset_block.iloc[0]})
    gridstep = ((price_grid.price - price_grid.price.shift()) / price_grid.price.shift()).mean()
    col1params, col2params, col3params, col4params = by_instance.columns(4)
    col1params.metric("N Points", len(price_grid))
    col2params.metric("Min Price", price_grid.price.min())
    col3params.metric("Max Price", price_grid.price.max())
    col4params.metric("GridStep in bps", round(gridstep * 10000, 2))

    

    by_instance.markdown("## PNL")
    col1pnl, col2pnl, col3pnl = by_instance.columns(3)
    
    initial_balance = float(instance[instance.tkn == 'USDB'].deposited_amount.iloc[0]) \
                        + float(instance[instance.tkn == 'WETH'].deposited_amount.iloc[0]) * price_at_start 
    end_balance = float(instance[instance.tkn == 'USDB'].withdrawn_amount.iloc[0]) \
                        + float(instance[instance.tkn == 'WETH'].withdrawn_amount.iloc[0]) * price_at_end 
    col1pnl.metric("Initial MtM USDB",
                "{:,.0f}".format(initial_balance))
    col2pnl.metric("Final Mtm USDB",
                "{:,.0f}".format(end_balance))
    pnl = end_balance - initial_balance
    col3pnl.metric("PNL USDB", "{:,.0f}".format(pnl))
    col1pnl.metric("Total Return Rate (%)", "{:,.2f}".format(100 * pnl / initial_balance ))
    col2pnl.metric("Daily Return Rate (%)", "{:,.2f}".format(100 * pnl / initial_balance / np.sqrt(instance_duration)))
    col3pnl.metric("APY (%)", "{:,.2f}".format(100 * pnl / initial_balance / np.sqrt(instance_duration) * np.sqrt(365)))
 

    by_instance.markdown("## Volume")
    transactions = execute_query_from_file('instance_transactions.sql',
                        {'instance' : instance.instance_address.iloc[0],
                          'start_block' : int(instance.reset_block.iloc[0]),
                          'end_block' : int(instance.exit_block.iloc[0])})
    col1vol, col2vol, col3vol, col4vol = by_instance.columns(4)
    col1vol.metric("N Transactions", len(transactions))
    col2vol.metric("Total Volume USDB", "{:,.0f}".format(transactions.volume_traded.sum()))
    col3vol.metric("Volume Multiplier", "{:,.2f}".format(transactions.volume_traded.sum() / initial_balance))
    col4vol.metric("Cost of Volume", "{:,.2f}".format(transactions.volume_traded.sum() / pnl))


