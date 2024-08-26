import pandas as pd
import pyodbc
import os
from dotenv import load_dotenv

# Load environment variables
load_dotenv()

# Define the path for the views folder
VIEWS_FOLDER = os.path.join('data', 'Views')

# Create the Views folder if it doesn't exist
os.makedirs(VIEWS_FOLDER, exist_ok=True)

# Database connection function
def connect_to_db():
    conn = pyodbc.connect(f'SERVER={os.getenv("DB_SERVER")};'
                          f'DATABASE={os.getenv("DB_NAME")};'
                          f'UID={os.getenv("DB_USERNAME")};'
                          f'PWD={os.getenv("DB_PASSWORD")};')
    return conn

# Function to get all view names from the database
def get_view_names(conn):
    cursor = conn.cursor()
    cursor.execute("SELECT TABLE_NAME FROM INFORMATION_SCHEMA.VIEWS WHERE TABLE_SCHEMA = 'dbo'")
    views = [row.TABLE_NAME for row in cursor.fetchall()]
    cursor.close()
    return views

# Function to export views to CSV
def export_views_to_csv():
    conn = connect_to_db()
    view_names = get_view_names(conn)
    
    for view_name in view_names:
        print(f"Exporting {view_name}...")
        query = f"SELECT * FROM {view_name}"
        df = pd.read_sql(query, conn)
        
        # Save to CSV in the Views folder
        csv_path = os.path.join(VIEWS_FOLDER, f"{view_name}.csv")
        df.to_csv(csv_path, index=False)
        print(f"Saved {view_name} to {csv_path}")
    
    conn.close()
    print("All views have been exported as CSV files.")

if __name__ == "__main__":
    export_views_to_csv()