import pymysql
import sys

DB_CONFIG = {
    'host': '35.154.96.221',
    'user': 'admin',
    'password': 'Connect@$999',
    'database': 'connectthrivelatest',
}

def get_latest_otp(mobile_number):
    try:
        conn = pymysql.connect(**DB_CONFIG)
        cursor = conn.cursor()
        cursor.execute("SELECT otp, expiry_time FROM otp_verifications WHERE mobile_number = %s ORDER BY expiry_time DESC LIMIT 1", (mobile_number,))
        row = cursor.fetchone()
        if row:
            print(f"Latest OTP for {mobile_number}: {row[0]} (Expires: {row[1]})")
        else:
            print(f"No OTP found for {mobile_number}")
        conn.close()
    except Exception as e:
        print(f"Error querying production DB: {e}")

if __name__ == "__main__":
    mobile = sys.argv[1] if len(sys.argv) > 1 else '9876543210'
    get_latest_otp(mobile)
