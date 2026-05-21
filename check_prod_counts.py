
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
    cursor.execute("SELECT count(*) FROM course_module")
    print(f"Modules in Prod: {cursor.fetchone()[0]}")
    cursor.execute("SELECT count(*) FROM concept")
    print(f"Concepts in Prod: {cursor.fetchone()[0]}")
    conn.close()

if __name__ == "__main__":
    check()
