import psycopg2

try:
    print("Attempting to connect  to sports_arbitrage_db...")

    # Connect to your local database engine
    conn = psycopg2.connect(
        host='localhost',
        database="sports_arbitrage_db",
        user="postgres",
        password="your_superuser_password"
    )

    cursor = conn.cursor()
    print("Successfully connected to the database!")

    # Insert a dummy row to test our tracking data integrity
    print("Testing data ingestion...")
    insert_query = """
        INSERT INTO transaction_ledger (platform_name, transaction_type, amount_spent, actual_return)
        VALUES ('Smarkets', 'Database Test Bet', 10.00, 15.50);
        """
    cursor.execute(insert_query)

    # Save the transaction to the database
    conn.commit()
    print("Test row successfully injected into the ledger!")

except Exception as error:
        print(f"Pipeline Connection Failed: {error}")

finally:
    if 'conn' in locals() and conn:
        cursor.close()
        conn.close()
        print("Database connection closed cleanly.")
