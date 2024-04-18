import streamlit as st
import pandas as pd
import os
import plotly.express as px
import plotly.graph_objects as go
#from web3 import Web3 
from datetime import datetime, timedelta, timezone
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


st.title("Book Analytics")

st.markdown("## Spread")

mkts = ["WETHUSDB", "PUNKS20WETH", "PUNKS40WETH"]
selected_mkt = st.selectbox("Market", options = mkts, index = 0)

book = execute_query_from_file('spread.sql', {})

book = book[book.mkt_name == selected_mkt]

st.dataframe(book)


fig = px.line(book, x='block', y='spread', title='Spread vs. Block')

# Update layout if needed
fig.update_layout(
    xaxis_title='Block',
    yaxis_title='Spread'
)

# Show the plot
st.plotly_chart(fig)