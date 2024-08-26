import pandas as pd
import pyodbc
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Database connection function
def connect_to_db():
    conn = pyodbc.connect(f'SERVER={os.getenv("DB_SERVER")};'
                          f'DATABASE={os.getenv("DB_NAME")};'
                          f'Trusted_Connection=yes;')
    return conn

# Function to get all view names from the database
def get_view_names(conn):
    cursor = conn.cursor()
    cursor.execute("SELECT TABLE_NAME FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_SCHEMA = 'dbo'")
    views = [row.TABLE_NAME for row in cursor.fetchall()]
    cursor.close()
    return views

# Function to execute SQL query and return results as a DataFrame
def get_data_from_db(conn, query):
    return pd.read_sql(query, conn)

# Create a directory to store the CSV files
output_dir = 'nashville_housing_views'
os.makedirs(output_dir, exist_ok=True)

# Connect to the database
conn = connect_to_db()

# Get all view names
view_names = get_view_names(conn)

# Download each view as a CSV file
for view_name in view_names:
    print(f"Downloading {view_name}...")
    query = f"SELECT * FROM {view_name}"
    df = get_data_from_db(conn, query)
    
    # Save to CSV
    csv_path = os.path.join(output_dir, f"{view_name}.csv")
    df.to_csv(csv_path, index=False)
    print(f"Saved {view_name} to {csv_path}")

# Close the database connection
conn.close()

print("All views have been downloaded as CSV files.")