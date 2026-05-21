import pymysql

DB_CONFIG = {
    'host': '35.154.96.221',
    'user': 'admin',
    'password': 'Connect@$999',
    'database': 'connectthrivelatest',
}

def check():
    conn = pymysql.connect(**DB_CONFIG)
    cursor = conn.cursor()
    
    # Check all tables to see where user to batch relation is stored
    cursor.execute("SHOW TABLES")
    tables = [row[0] for row in cursor.fetchall()]
    print("Tables in DB:", tables)
    
    # Look for user tables or batch tables
    for t in ['student', 'user', 'user_batch', 'student_batch', 'batch', 'batch_students', 'batch_concepts']:
        if t in tables:
            cursor.execute(f"DESCRIBE {t}")
            columns = [c[0] for c in cursor.fetchall()]
            print(f"\nTable {t} columns: {columns}")
            
            # Let's see if we can query user 1
            if t == 'student' or t == 'user':
                cursor.execute(f"SELECT * FROM {t} WHERE id = 1")
                print(f"User 1 in {t}:", cursor.fetchall())
            elif 'batch_id' in columns:
                cursor.execute(f"SELECT * FROM {t} LIMIT 5")
                print(f"Sample data from {t}:", cursor.fetchall())
                
    conn.close()

if __name__ == "__main__":
    check()
