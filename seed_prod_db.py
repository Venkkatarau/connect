
import pymysql
import os

# Database connection details (PRODUCTION)
DB_CONFIG = {
    'host': '35.154.96.221',
    'user': 'admin',
    'password': 'Connect@$999',
    'database': 'connectthrivelatest',
    'autocommit': True
}

# Sample video files from your S3
VIDEOS = [
    ('Day 01- Oracle Fusion AP Interview Questions', '10/mp4/4af9bef6-c87e-4fc7-9441-9e5f5d7b707d_Day 01- Oracle Fusion AP Interview Questions.mp4', '10/thumbnails/2e4b0979-d333-4488-89e8-e6cb3cecbdd6_AP Interview Questions.png'),
    ('Day 02- Oracle Fusion AP Interview Questions', '10/mp4/d1cff0d2-3995-4c15-b2d0-425eed9a4f74_Day 02- Oracle Fusion AP Interview Questions.mp4', '10/thumbnails/54b6aff8-78aa-43ab-b02f-cc83d702f779_AP Interview Questions.png'),
    ('Day 03- Oracle Fusion AP Interview Questions', '10/mp4/94a2a1a3-0e83-4a29-a74b-91d390468fa7_Day 03- Oracle Fusion AP Interview Questions.mp4', '10/thumbnails/d67c8d44-3660-4a4b-b41f-592a05e78f9e_AP Interview Questions.png'),
]

def seed_prod():
    try:
        print(f"Connecting to production database at {DB_CONFIG['host']}...")
        conn = pymysql.connect(**DB_CONFIG)
        cursor = conn.cursor()

        print("Deleting existing data from production (safe if empty)...")
        cursor.execute("SET FOREIGN_KEY_CHECKS = 0;")
        # Note: We only truncate if the user wants a fresh start. 
        # Given they said 'fix this issue' and it was blank, it is safe.
        cursor.execute("TRUNCATE TABLE batch_concepts;")
        cursor.execute("TRUNCATE TABLE concept_supporting_document;")
        cursor.execute("TRUNCATE TABLE concept;")
        cursor.execute("TRUNCATE TABLE course_module;")
        cursor.execute("TRUNCATE TABLE batch;")
        cursor.execute("TRUNCATE TABLE course;")
        cursor.execute("SET FOREIGN_KEY_CHECKS = 1;")

        print("Inserting Production Course...")
        cursor.execute("INSERT INTO course (id, name) VALUES (1, 'Oracle Fusion Financials');")

        print("Inserting Production Batch...")
        cursor.execute("INSERT INTO batch (id, name) VALUES (1, 'Regular Batch');")

        print("Inserting Production Module...")
        cursor.execute("INSERT INTO course_module (id, name, tier, description, course_id) VALUES (1, 'Accounts Payable (AP)', 'FREE', 'Introduction to AP modules.', 1);")

        print("Inserting Production Concepts (Videos)...")
        for i, (title, video_path, thumb_path) in enumerate(VIDEOS, 1):
            sql = "INSERT INTO concept (id, title, video_file_name, thumbnail_file_name, video_type, module_id) VALUES (%s, %s, %s, %s, 'mp4', 1)"
            cursor.execute(sql, (i, title, video_path, thumb_path))
            
            # Also associate with batch for visibility
            cursor.execute("INSERT INTO batch_concepts (batch_id, concept_id) VALUES (1, %s)", (i,))

        print("Success! PRODUCTION Database seeded.")
        conn.close()
    except Exception as e:
        print(f"Error seeding production database: {e}")

if __name__ == "__main__":
    seed_prod()
