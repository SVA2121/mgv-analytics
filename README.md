## Setup

Run the following commands in order:

python -m venv .env-analytics

sudo apt-get install libpq-dev

source .env-analytics/bin/activate

pip install -r requirements.txt

## To Run App

streamlit run MgvAnalytics.py


## Contribute

### General Idea

All the queries are stored in the queries/ folder.
They are ran with execute_query_from_file function in database_connection.py

Each page **needs** to be created in the pages/ folder.



