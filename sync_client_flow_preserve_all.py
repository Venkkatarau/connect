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

MODULE_NAMES = {
    '1': 'Introduction & Basic Setup',
    '2': 'Cash Management Basics',
    '3': 'Oracle Fusion Basics',
    '4': 'Reporting & Analytics',
    '5': 'Security & Role Management',
    '6': 'Enterprise Structure Basics',
    '7': 'Oracle Fusion GL - Introduction',
    '8': 'Oracle AIM/OUM Methodology',
    '9': 'ORA_GL',
    '10': 'AP/AR Interview Questions',
    '11': 'Accounts Payable (AP) - Basics',
    '12': 'Fixed Assets (FA)',
    '13': 'Interview Preparation Checklist',
    '14': 'Advanced Interview Mastery',
    '15': 'Cash Management (CM) - Core',
    '16': 'test1',
    '25': 'Accounts Payable',
    '28': 'Oracle Fusion Financials Demo Session',
    '29': 'GL-Introduction',
    '30': 'Miscellaneous Videos',
    '31': 'Accounts Receivable'
}


def clean_title(filename):
    name = re.sub(r'^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}_', '', filename)
    name = re.sub(r'\.mp4$', '', name)
    return name.replace('_', ' ').replace('-', ' ').strip()

def detect_video_type(filename):
    transaction_keywords = [
        'trx', 'transaction', 'process', 'invoice', 'creation', 'refund', 
        'journal', 'payment', 'reconciliation', 'transfer', 'billing', 'receipt'
    ]
    name_lower = filename.lower()
    for kw in transaction_keywords:
        if kw in name_lower:
            return 'Transaction Videos'
    return 'Setup Videos'

def sync():
    s3 = boto3.client('s3', region_name=AWS_REGION, aws_access_key_id=AWS_ACCESS_KEY, aws_secret_access_key=AWS_SECRET_KEY)
    paginator = s3.get_paginator('list_objects_v2')
    
    # Fetch all S3 videos grouped by folder
    videos_by_folder = {}
    all_videos = []
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
                all_videos.append((folder, filename, key))
                
    print(f"Fetched {len(all_videos)} S3 videos successfully.")
    
    conn = pymysql.connect(**DB_CONFIG)
    cursor = conn.cursor()
    
    try:
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
        cursor.execute("INSERT INTO batch (id, name) VALUES (1, 'Regular Batch')")
        cursor.execute("INSERT INTO batch (id, name) VALUES (2, 'Corp Batch')")
        cursor.execute("INSERT INTO batch (id, name) VALUES (3, 'CTT-MAY 2026 PAID')")
        
        # 3. Insert Client-Specific Modules (IDs 1 to 5)
        cursor.execute("INSERT INTO course_module (id, name, tier, description, course_id) VALUES (1, 'Default Group', 'FREE', 'Default Group after Login', 1)")
        cursor.execute("INSERT INTO course_module (id, name, tier, description, course_id) VALUES (2, 'General Ledger (GL)', 'PAID', 'General Ledger Concepts', 1)")
        cursor.execute("INSERT INTO course_module (id, name, tier, description, course_id) VALUES (3, 'Accounts Payable (AP)', 'PAID', 'Accounts Payable Concepts', 1)")
        cursor.execute("INSERT INTO course_module (id, name, tier, description, course_id) VALUES (4, 'Accounts Receivable (AR)', 'PAID', 'Accounts Receivable Concepts', 1)")
        cursor.execute("INSERT INTO course_module (id, name, tier, description, course_id) VALUES (5, 'Cash Management (CM)', 'PAID', 'Cash Management Concepts', 1)")
        
        # 4. Insert Standard Folder Modules (IDs 10+)
        folder_to_module_id = {}
        module_id_seq = 10
        for folder in sorted(videos_by_folder.keys(), key=lambda x: int(x) if x.isdigit() else x):
            module_name = MODULE_NAMES.get(folder, f"Additional Content (Folder {folder})")
            tier = 'PAID' if folder == '16' else 'FREE'
            cursor.execute(
                "INSERT INTO course_module (id, name, tier, description, course_id) VALUES (%s, %s, %s, %s, 1)",
                (module_id_seq, module_name, tier, f"All videos from {module_name}")
            )
            folder_to_module_id[folder] = module_id_seq
            module_id_seq += 1
            
        # 5. Associate Users
        cursor.execute("UPDATE users SET batch_id = 3 WHERE id = 23")
        cursor.execute("UPDATE users SET batch_id = 2 WHERE id = 24")
        
        concept_id_seq = 1
        
        # 6. Insert ALL S3 videos under their standard folder modules (linked to Batch 1 - Regular Batch)
        print("Inserting all existing videos under standard modules...")
        for folder, filename, key in all_videos:
            title = clean_title(filename)
            video_type = detect_video_type(filename)
            cursor.execute(
                "INSERT INTO concept (id, title, video_file_name, thumbnail_file_name, video_type, module_id) "
                "VALUES (%s, %s, %s, 'thumbnail.png', %s, %s)",
                (concept_id_seq, title, key, video_type, folder_to_module_id[folder])
            )
            cursor.execute(
                "INSERT INTO batch_concepts (batch_id, concept_id) VALUES (1, %s)",
                (concept_id_seq,)
            )
            # Map specific folder 29 videos to Batch 2 and 3 dynamically
            if folder == '29':
                if '233b345f' in filename or '066a6862' in filename:
                    cursor.execute(
                        "INSERT INTO batch_concepts (batch_id, concept_id) VALUES (2, %s)",
                        (concept_id_seq,)
                    )
                elif '2b91e9d1' in filename or '3bbabe28' in filename:
                    cursor.execute(
                        "INSERT INTO batch_concepts (batch_id, concept_id) VALUES (3, %s)",
                        (concept_id_seq,)
                    )
            concept_id_seq += 1
            
        # 9. Pre-approve Module Access for Paid Batch student (User 23)
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
