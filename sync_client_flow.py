import os
import boto3
import pymysql
import re

# S3 Config
S3_BUCKET = 'connectthrive'
if os.path.exists('.env'):
    for line in open('.env'):
        if '=' in line and not line.startswith('#'):
            k, v = line.strip().split('=', 1)
            os.environ[k.strip()] = v.strip().strip("'").strip('"')

AWS_ACCESS_KEY = os.environ.get('AWS_ACCESS_KEY_ID', '')
AWS_SECRET_KEY = os.environ.get('AWS_SECRET_ACCESS_KEY', '')
AWS_REGION = 'ap-south-1'

# DB Config
DB_CONFIG = {
    'host': '35.154.96.221',
    'user': 'admin',
    'password': 'Connect@$999',
    'database': 'connectthrivelatest',
}

def clean_title(filename):
    # Remove UUID prefix and .mp4 extension
    name = re.sub(r'^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}_', '', filename)
    name = re.sub(r'\.mp4$', '', name)
    return name.replace('_', ' ').replace('-', ' ').strip()

def sync():
    s3 = boto3.client('s3', region_name=AWS_REGION, aws_access_key_id=AWS_ACCESS_KEY, aws_secret_access_key=AWS_SECRET_KEY)
    paginator = s3.get_paginator('list_objects_v2')
    
    # Fetch all S3 videos grouped by folder
    videos_by_folder = {}
    for page in paginator.paginate(Bucket=S3_BUCKET):
        for obj in page.get('Contents', []):
            key = obj['Key']
            if not key.endswith('.mp4'):
                continue
            parts = key.split('/')
            if len(parts) >= 2:
                folder = parts[0]
                filename = parts[-1]
                if folder not in videos_by_folder:
                    videos_by_folder[folder] = []
                videos_by_folder[folder].append((filename, key))
                
    print("Fetched S3 video lists successfully.")
    
    # Establish DB connection
    conn = pymysql.connect(**DB_CONFIG)
    cursor = conn.cursor()
    
    try:
        # Disable foreign key checks for clearing
        cursor.execute("SET FOREIGN_KEY_CHECKS = 0;")
        
        # Clear tables
        cursor.execute("TRUNCATE TABLE module_access_request;")
        cursor.execute("TRUNCATE TABLE batch_concepts;")
        cursor.execute("TRUNCATE TABLE concept;")
        cursor.execute("TRUNCATE TABLE course_module;")
        cursor.execute("TRUNCATE TABLE batch;")
        cursor.execute("TRUNCATE TABLE course;")
        
        # 1. Insert Course
        cursor.execute("INSERT INTO course (id, name) VALUES (1, 'Oracle Fusion Financials')")
        
        # 2. Insert Batches
        cursor.execute("INSERT INTO batch (id, name) VALUES (1, 'Corp Batch')")
        cursor.execute("INSERT INTO batch (id, name) VALUES (2, 'CTT-MAY 2026 PAID')")
        
        # 3. Insert Modules
        # Module 1: Default Group for free corp batch
        cursor.execute("INSERT INTO course_module (id, name, tier, description, course_id) VALUES (1, 'Default Group', 'FREE', 'Default Group after Login', 1)")
        # Module 2-5: GL, AP, AR, CM for Paid batch
        cursor.execute("INSERT INTO course_module (id, name, tier, description, course_id) VALUES (2, 'General Ledger (GL)', 'PAID', 'General Ledger Concepts', 1)")
        cursor.execute("INSERT INTO course_module (id, name, tier, description, course_id) VALUES (3, 'Accounts Payable (AP)', 'PAID', 'Accounts Payable Concepts', 1)")
        cursor.execute("INSERT INTO course_module (id, name, tier, description, course_id) VALUES (4, 'Accounts Receivable (AR)', 'PAID', 'Accounts Receivable Concepts', 1)")
        cursor.execute("INSERT INTO course_module (id, name, tier, description, course_id) VALUES (5, 'Cash Management (CM)', 'PAID', 'Cash Management Concepts', 1)")
        
        # 4. Associate Users to their batches
        # User 23 ("venkatarao", mobile 9876543210) -> Batch 2
        cursor.execute("UPDATE users SET batch_id = 2 WHERE id = 23")
        # User 24 ("Venkata Rao", mobile 9573631767) -> Batch 1
        cursor.execute("UPDATE users SET batch_id = 1 WHERE id = 24")
        
        concept_id_seq = 1
        
        # 5. Populate Batch 1 ("Corp Batch") -> 15 videos under Module 1 ("Default Group")
        # We will select 15 videos from folders 1, 3, etc.
        corp_videos = []
        for folder in ['1', '3']:
            if folder in videos_by_folder:
                corp_videos.extend(videos_by_folder[folder])
        corp_videos = corp_videos[:15]
        
        print(f"Assigning {len(corp_videos)} videos to Corp Batch...")
        for idx, (filename, key) in enumerate(corp_videos):
            title = clean_title(filename)
            video_type = 'Setup Videos' if idx % 2 == 0 else 'Transaction Videos'
            # Insert concept
            cursor.execute(
                "INSERT INTO concept (id, title, video_file_name, thumbnail_file_name, video_type, module_id) "
                "VALUES (%s, %s, %s, 'thumbnail.png', %s, 1)",
                (concept_id_seq, title, key, video_type)
            )
            # Map concept to Batch 1
            cursor.execute(
                "INSERT INTO batch_concepts (batch_id, concept_id) VALUES (1, %s)",
                (concept_id_seq,)
            )
            concept_id_seq += 1
            
        # 6. Populate Batch 2 ("CTT-MAY 2026 PAID") -> 30 videos distributed across modules 2, 3, 4, 5
        # GL: 8 videos from folder 7
        # AP: 8 videos from folder 25
        # AR: 8 videos from folder 31
        # CM: 6 videos from folder 15 (4 videos) and folder 2 (2 videos)
        paid_module_mapping = [
            # (module_id, folder_names, count)
            (2, ['7'], 8),   # GL
            (3, ['25'], 8),  # AP
            (4, ['31'], 8),  # AR
            (5, ['15', '2'], 6) # CM
        ]
        
        for module_id, folders, count in paid_module_mapping:
            module_videos = []
            for folder in folders:
                if folder in videos_by_folder:
                    module_videos.extend(videos_by_folder[folder])
            module_videos = module_videos[:count]
            print(f"Assigning {len(module_videos)} videos to Module {module_id}...")
            
            for idx, (filename, key) in enumerate(module_videos):
                title = clean_title(filename)
                video_type = 'Setup Videos' if idx % 2 == 0 else 'Transaction Videos'
                cursor.execute(
                    "INSERT INTO concept (id, title, video_file_name, thumbnail_file_name, video_type, module_id) "
                    "VALUES (%s, %s, %s, 'thumbnail.png', %s, %s)",
                    (concept_id_seq, title, key, video_type, module_id)
                )
                # Map concept to Batch 2
                cursor.execute(
                    "INSERT INTO batch_concepts (batch_id, concept_id) VALUES (2, %s)",
                    (concept_id_seq,)
                )
                concept_id_seq += 1
                
        # 7. Pre-approve Module Access for Paid Batch student (User 23)
        # Module IDs 2, 3, 4, 5 are the paid modules
        for mod_id in [2, 3, 4, 5]:
            cursor.execute(
                "INSERT INTO module_access_request (student_id, module_id, is_approved, requested_at) "
                "VALUES (23, %s, 1, NOW())",
                (mod_id,)
            )
            
        cursor.execute("SET FOREIGN_KEY_CHECKS = 1;")
        conn.commit()
        print("Database sync completed successfully!")
        
    except Exception as e:
        conn.rollback()
        print(f"An error occurred: {e}")
        raise e
    finally:
        conn.close()

if __name__ == "__main__":
    sync()
