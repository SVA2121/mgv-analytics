import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
import os
#from web3 import Web3 
from datetime import datetime, timedelta

st.set_page_config(layout="wide")
CONN = st.connection("postgresql", type="sql")

key_gen = (i for i in range(30))
#####################
# Helper Functions
####################
@st.cache_data
def execute_query_from_file(filename: str) -> pd.DataFrame:
    query_file = os.path.join('queries', filename)
    with open(query_file, 'r') as f:
        query_str = f.read()
    return CONN.query(query_str)
    
#from database_connection import execute_query_from_file, get_db_connection


#blast =  Web3(Web3.HTTPProvider('https://rpc.blast.io'))
# Get current time
current_time = datetime.now()

#LATEST_BLOCK_NUMBER = blast.eth.get_block('latest').get('number')
# 2 blocks per second in blast --> 30 * 60 * 24 per day
#LAST_24H_BLOCK_NUMBER = LATEST_BLOCK_NUMBER - 30 * 60 * 24

db = execute_query_from_file('detailed_volume.sql')
#db = pd.read_csv('dump_db.csv')
#db.date = pd.to_datetime(db.date)

overall, deep = st.tabs(["Overall Analytics", "Volume Deep Dive"])

overall.markdown(
    "# 📊 Mangrove Analytics App",
    unsafe_allow_html=True,
)
overall.markdown(f"Last updated : {(current_time - timedelta(hours = 1)).strftime('%Y-%m-%d %H:%S CET')}")

########################################################################
overall.markdown("## Volume Metrics")

mkts = ["WETHUSDB", "PUNKS20WETH", "PUNKS40WETH"]
selected_mkts = overall.multiselect("Market", options = mkts, default = mkts)

agg_option = overall.selectbox(label = 'Aggregate By', options = ['Minute', 'Day', 'Week', 'Month', 'Year'], index = 1)

filtered_volume = db[db.mkt_name.isin(selected_mkts)]

filtered_volume.index = filtered_volume.date
filtered_volume.drop('date', axis = 1, inplace = True)

if agg_option == 'Mintute':
    agg = 'min'
elif agg_option == 'Day':
    agg = 'D'
elif agg_option == 'Week':
    agg = 'W'
elif agg_option == 'Month':
    agg = 'M'
elif agg_option == 'Year':
    agg = 'YS'
    
filtered_transactions = filtered_volume.copy()
filtered_volume = filtered_volume.resample(agg).sum()
filtered_transactions = filtered_transactions.resample(agg).count()

filtered_volume['total_volume'] = filtered_volume.volume_usdb.cumsum()

col1vol, col2vol, col3vol, col4vol = overall.columns(4)
col1vol.metric("Total Volume USDB", "{:,.0f}".format(filtered_volume.total_volume.iloc[-1]))
col2vol.metric("Total Volume USDB Last " + agg_option, "{:,.0f}".format(filtered_volume.iloc[-1].volume_usdb.sum()))
col3vol.metric("Total # Transactions", "{:,.0f}".format(filtered_transactions.volume_usdb.sum()))
col4vol.metric("Total # Transactions Last " + agg_option, "{:,.0f}".format(filtered_transactions.volume_usdb.iloc[-1]))


fig_vol = go.Figure()
fig_vol.add_trace(go.Bar(x=filtered_volume.index, y=filtered_volume.volume_usdb, name='Volume'))
# Update layout
fig_vol.update_layout(title='Volume by ' + agg_option,
                        yaxis_title='Volume in USDB',
                        xaxis=dict(title=agg_option))

overall.plotly_chart(fig_vol, use_container_width= True)


# Total volume
total_volume = filtered_volume.groupby('date')['volume_usdb'].sum().cumsum().to_frame('volume_usdb')
fig_vol_total = go.Figure()
fig_vol_total.add_trace(go.Scatter(x=total_volume.index, y=total_volume.volume_usdb, name='Volume'))
# Update layout
fig_vol_total.update_layout(title='Total Cumulated Volume',
                        yaxis_title='Volume in USDB',
                        xaxis=dict(title=agg_option))

overall.plotly_chart(fig_vol_total, use_container_width= True)
########################################################################
overall.markdown("## User Metrics")
_ = """
user_data = execute_query_from_file('distinct_users.sql')
user_data['total_users'] = user_data.new_users.cumsum()

col1users, col2users, col3users, col4users = overall.columns(4)
col1users.metric("Total Users", "{:,.0f}".format(user_data.total_users.iloc[-1]))
col2users.metric("Total New Users (24H)", "{:,.0f}".format(user_data.last_24h.sum()))
col3users.metric("Total Active Users", "{:,.0f}".format(user_data[user_data.category != 'unactive'].new_users.sum()))
col4users.metric("Total Inactive Users", "{:,.0f}".format(user_data[user_data.category == 'unactive'].new_users.sum()))


fig_users = px.bar(user_data, x='creation_date', y='new_users', color='category', barmode='stack',
             labels={'created_date': 'Date', 'new_users': 'New Users', 'category': 'Category'},
             title='Total New Users per Day per Category')
total_users = user_data.groupby('creation_date')['total_users'].max().to_frame('total_users').reset_index()
fig_users.add_scatter(x=total_users.creation_date, y=total_users.total_users,
                    mode='lines', name='Total Users', line_color = 'blue')
fig_users.update_layout(title='New Users by Day',
                        yaxis_title='Number of Users',
                        xaxis=dict(title='Day'))


overall.plotly_chart(fig_users, use_container_width= True)
"""
#################################

#################################



#########################
#      Volume Deep Dive Page
#########################
selected_mkt = deep.selectbox("Market", options = mkts, index = 0)
dd = db[db.mkt_name == selected_mkt]
col1, col2 = deep.columns(2)

start_day = col1.date_input(label = 'Start Time', 
                            value = datetime.today(),
                            format='YYYY-MM-DD',
                            key=next(key_gen))
start_time = col2.time_input(label='',
                            value = datetime.now().replace(hour = 0, minute=0, second=0),
                            step = 60, key = next(key_gen))
end_day = col1.date_input(label = 'End Time',
                        value = datetime.today(),
                        format='YYYY-MM-DD',
                        key = next(key_gen))
end_time = col2.time_input(label='', value = "now",
                           step = 60, key = next(key_gen))
start = str(start_day) + ' ' + str(start_time)
end = str(end_day) + ' ' + str(end_time)

dd = dd[(dd.date >= start) & (db.date <= end)]

col1dd, col2dd, col3dd, col4dd = deep.columns(4)
col1dd.metric("Total Volume USDB", "{:,.0f}".format(dd.volume_usdb.sum()))
col2dd.metric("Total # Transactions", "{:,.0f}".format(len(dd)))
col3dd.metric("Total Makers", "{:,.0f}".format(dd.maker.nunique()))
col4dd.metric("Total Takers", "{:,.0f}".format(dd.taker.nunique()))

deep.download_button(label = 'Click to download transaction data',
                     file_name=f'{selected_mkt}_transactions_{start}_{end}.csv',
                     data = dd.to_csv())

col_makers, col_takers = deep.columns(2)
col_makers.markdown("## Top Makers")
maker_df = dd.groupby('maker')['volume_usdb'].sum().sort_values(ascending=False).to_frame()
maker_df['pct'] = dd.groupby('maker')['volume_usdb'].sum().sort_values(ascending=False) / dd.volume_usdb.sum()
maker_df['pct_cumsum'] = maker_df.pct.cumsum()
maker_df['volume_usdb'] = maker_df['volume_usdb'].to_frame().applymap("{:,.0f}".format)
maker_df[['pct', 'pct_cumsum']] = maker_df[['pct', 'pct_cumsum']].applymap("{:,.4f}".format)
col_makers.dataframe(maker_df)


col_takers.markdown("## Top Takers")
taker_df = dd.groupby('taker')['volume_usdb'].sum().sort_values(ascending=False).to_frame()
taker_df['pct'] = dd.groupby('taker')['volume_usdb'].sum().sort_values(ascending=False) / dd.volume_usdb.sum()
taker_df['pct_cumsum'] = taker_df.pct.cumsum()
taker_df['volume_usdb'] = taker_df['volume_usdb'].to_frame().applymap("{:,.0f}".format)
taker_df[['pct', 'pct_cumsum']] = taker_df[['pct', 'pct_cumsum']].applymap("{:,.4f}".format)
col_takers.dataframe(taker_df)

deep.markdown("## Maker Interactions")

maker = deep.text_input(label = 'Input Maker Address', value = maker_df.index[0])

makerdb = dd[dd.maker == maker]

deep.markdown("#### Top Taker Interactions")
top_takers = makerdb.groupby('taker')['volume_usdb'].sum().sort_values(ascending=False).to_frame()
top_takers['pct'] = makerdb.groupby('taker')['volume_usdb'].sum().sort_values(ascending=False) / makerdb.volume_usdb.sum()
top_takers['pct_cumsum'] = top_takers.pct.cumsum()
top_takers['volume_usdb'] = top_takers['volume_usdb'].to_frame().applymap("{:,.0f}".format)
top_takers[['pct', 'pct_cumsum']] = top_takers[['pct', 'pct_cumsum']].applymap("{:,.4f}".format)
deep.dataframe(top_takers)


taker_filter = deep.slider(label = 'Taker Filter', min_value=float(top_takers.pct_cumsum.iloc[0]), max_value=1.0)
takers = top_takers[pd.to_numeric(top_takers.pct_cumsum) <= float(taker_filter)].index

taker_flow = dd[dd.taker.isin(takers)]
taker_flow['vol'] = taker_flow[['side', 'volume_usdb']].apply(lambda x: x.volume_usdb if x.side == 'ask' else -x.volume_usdb, axis = 1)
taker_flow = taker_flow.groupby(['date', 'taker', 'tx_hash'])['vol'].sum().reset_index()
fig = px.scatter(taker_flow, x='date', y='vol', color='taker', hover_data=['taker'], title='Volume by Taker')
deep.plotly_chart(fig, use_container_width=True)