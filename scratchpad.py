
import os
import plotly.express as px
import plotly.graph_objects as go
#from web3 import Web3 
from datetime import datetime, timedelta
import json
from database_connection import execute_query_from_file, get_db_connection
import pandas as pd
import multiprocessing

def process_block_range(start_block, end_block):
    db = execute_query_from_file('best_offers_by_block.sql', {'start_block' : start_block, 'end_block' : end_block})
    db.to_csv(f'data/spread_{start_block}_{end_block}.csv')



def main():
    min_block = 214450	
    min_block = 1517247
    max_block = 2015047
    block_step = 100

    # Create a pool of processes

    # Generate a list of block ranges
    block_ranges = [(start_block, min(start_block + block_step - 1, max_block)) for start_block in range(min_block, max_block, block_step)]

    # Execute the process for each block range in parallel
    pool = multiprocessing.Pool()
    pool.starmap(process_block_range, block_ranges)
    # Close the pool
    pool.close()
    pool.join()


if __name__ == '__main__':
    main()