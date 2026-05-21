import pymysql

DB_CONFIG = {
    'host': '35.154.96.221',
    'user': 'admin',
    'password': 'Connect@$999',
    'database': 'connectthrivelatest',
    'autocommit': True
}

def main():
    try:
        conn = pymysql.connect(**DB_CONFIG)
        cursor = conn.cursor()
        
        cursor.execute("SELECT * FROM module_access_request;")
        requests = cursor.fetchall()
        print("\nAll Module Access Requests:")
        for req in requests:
            print(req)
            
        conn.close()
    except Exception as e:
        print("Error:", e)

if __name__ == "__main__":
    main()
