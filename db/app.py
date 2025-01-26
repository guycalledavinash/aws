import sqlalchemy as avinash
import pymysql
from sqlalchemy import create_engine, text

# Create engine
engine = create_engine('mysql+pymysql://[username]:[password]@[endpoint]/myflixdb')

# Create connection
connection = engine.connect()

# Execute query
query = text("select * from movies")
result_proxy = connection.execute(query)

# Fetch all rows
data = result_proxy.fetchall()

# Close connection
connection.close()

# Print fetched data
for item in data:
    print(item)
