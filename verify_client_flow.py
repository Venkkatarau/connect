import pymysql

DB_CONFIG = {
    'host': '35.154.96.221',
    'user': 'admin',
    'password': 'Connect@$999',
    'database': 'connectthrivelatest',
}

def verify():
    conn = pymysql.connect(**DB_CONFIG)
    cursor = conn.cursor()
    
    # 1. Print Batches and count of associated concepts
    cursor.execute("SELECT id, name FROM batch")
    batches = cursor.fetchall()
    
    print("=== Batch Verification ===")
    for bid, name in batches:
        cursor.execute("SELECT count(*) FROM batch_concepts WHERE batch_id = %s", (bid,))
        concept_count = cursor.fetchone()[0]
        print(f"Batch ID: {bid} | Name: {name} | Total Videos Assigned: {concept_count}")
        
        # Detail modules and Setup vs Transaction counts for this batch
        cursor.execute("""
            SELECT m.id, m.name, c.video_type, count(c.id)
            FROM batch_concepts bc
            JOIN concept c ON bc.concept_id = c.id
            JOIN course_module m ON c.module_id = m.id
            WHERE bc.batch_id = %s
            GROUP BY m.id, m.name, c.video_type
            ORDER BY m.id, c.video_type
        """, (bid,))
        details = cursor.fetchall()
        for mid, mname, vtype, count in details:
            print(f"  -> Module: {mname} (ID: {mid}) | Video Type: {vtype} | Count: {count}")
            
    print("\n=== User Association Verification ===")
    cursor.execute("SELECT id, username, mobile_number, batch_id FROM users WHERE id IN (23, 24)")
    for uid, name, mobile, bid in cursor.fetchall():
        cursor.execute("SELECT name FROM batch WHERE id = %s", (bid,))
        bname = cursor.fetchone()
        bname = bname[0] if bname else "None"
        print(f"User ID: {uid} | Username: {name} | Mobile: {mobile} | Assigned Batch: {bname} (ID: {bid})")
        
    print("\n=== Pre-Approved Module Access Requests (Student ID: 23) ===")
    cursor.execute("""
        SELECT r.module_id, m.name, r.is_approved
        FROM module_access_request r
        JOIN course_module m ON r.module_id = m.id
        WHERE r.student_id = 23
    """)
    for mid, mname, approved in cursor.fetchall():
        print(f"Module ID: {mid} | Name: {mname} | Approved: {approved}")
        
    conn.close()

if __name__ == "__main__":
    verify()
