import streamlit as st
import pandas as pd
import os
import plotly.express as px
import plotly.graph_objects as go
from web3 import Web3 
from datetime import datetime, timedelta
import json

from database_connection import execute_query_from_file

blast =  Web3(Web3.HTTPProvider('https://rpc.blast.io'))


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

balances = get_balances()
col1up.dataframe(balances)


overall.markdown("## Volume Metrics")

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

