import streamlit as st
import pandas as pd
import plotly.express as px
import plotly.graph_objects as go
#from web3 import Web3 
from datetime import datetime, timedelta




from database_connection import execute_query_from_file, get_db_connection

st.set_page_config(layout="wide")

#blast =  Web3(Web3.HTTPProvider('https://rpc.blast.io'))
# Get current time
current_time = datetime.now()

#LATEST_BLOCK_NUMBER = blast.eth.get_block('latest').get('number')
# 2 blocks per second in blast --> 30 * 60 * 24 per day
#LAST_24H_BLOCK_NUMBER = LATEST_BLOCK_NUMBER - 30 * 60 * 24


overall, maker, taker = st.tabs(["Overall Analytics", "Maker Anlaytics", "Taker Analytics"])

overall.markdown(
    "# 📊 Mangrove Analytics App",
    unsafe_allow_html=True,
)
overall.markdown(f"Last updated : {(current_time - timedelta(hours = 1)).strftime('%Y-%m-%d %H:%S CET')}")

########################################################################

overall.markdown("## User Metrics")
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

#################################
overall.markdown("## Volume Metrics")

volume = execute_query_from_file('quote_volume.sql')
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


#########################
#      Maker Page
#########################

maker.markdown('## Limit Orders Stats')

los = execute_query_from_file('lo_hist.sql')

maker.dataframe(los.offered_volume.apply(float).describe())

lo_hist = px.histogram(los, x='offered_volume', nbins=100)

# Update layout
lo_hist.update_layout(
    title='Histogram',
    xaxis_title='Offered Volume',
    yaxis_title='Frequency'
)

maker.plotly_chart(lo_hist)

#########################
#      Taker Page
#########################

taker.markdown('## Market Orders Stats')

mos = execute_query_from_file('mo_hist.sql')

taker.dataframe(mos.taken_volume.apply(float).describe())

mo_hist = px.histogram(mos, x='taken_volume', nbins=100)

# Update layout
mo_hist.update_layout(
    title='Histogram',
    xaxis_title='Market Order Volume',
    yaxis_title='Frequency'
)

taker.plotly_chart(mo_hist)