import psycopg2
import pandas as pd
from typing import List
import os


DB_NAME = "graph_node_addma_3"
USER = "addma_team"
PSWD = "MkZDSqigKLco5OeYRHiW"
HOST = "addma-graph-node-production-3.cg7azkhq5rv5.us-east-1.rds.amazonaws.com"
PORT = "5432"

def get_db_connection(db_name : str = DB_NAME,
                      user : str = USER,
                      password : str = PSWD,
                      host : str = HOST,
                      port : str = PORT):
    # Establish connection parameters

    db_url = f"postgresql://{user}:{password}@{host}:{port}/{db_name}"
    # Construct a connection string
    conn_string = f"dbname='{db_name}' user='{user}' password='{password}' host='{host}' port='{port}'"

    # Establish connection
    try:
        conn = psycopg2.connect(conn_string)
        print("Connected successfully!")
    except psycopg2.OperationalError as e:
        print(f"Unable to connect!\n{e}")


    return conn

def execute_read_query(query : str) -> List:
    conn = get_db_connection()
    cursor = conn.cursor()
    cursor.execute(query)
    columns = [desc[0] for desc in cursor.description]
    res = pd.DataFrame(cursor.fetchall(), columns = columns)
    cursor.close()
    conn.close()

    return res


def execute_query_from_file(filename: str, kwargs) -> pd.DataFrame:
    query_file = os.path.join('queries', filename)
    with open(query_file, 'r') as f:
        query = f.read()
        if kwargs:
            query = query.format(**{key: f"'{value}'" for key, value in kwargs.items()})
    return execute_read_query(query)