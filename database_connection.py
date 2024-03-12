import psycopg2
import pandas as pd
from typing import List
import os
from dotenv import load_dotenv

load_dotenv('.env')

DB_NAME = os.environ.get("DB_NAME")
USER = os.environ.get("USER")
PSWD = os.environ.get("PSWD")
HOST = os.environ.get("HOST")
PORT = os.environ.get("PORT")

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


def execute_query_from_file(filename: str) -> pd.DataFrame:
    query_file = os.path.join('queries', filename)
    with open(query_file, 'r') as f:
        query = f.read()
    return execute_read_query(query)
    


