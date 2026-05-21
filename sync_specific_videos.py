import os
import boto3
import pymysql

# AWS Config
S3_BUCKET = 'connectthrive'
if os.path.exists('.env'):
    for line in open('.env'):
        if '=' in line and not line.startswith('#'):
            k, v = line.strip().split('=', 1)
            os.environ[k.strip()] = v.strip().strip("'").strip('"')

AWS_ACCESS_KEY = os.environ.get('AWS_ACCESS_KEY_ID', '')
AWS_SECRET_KEY = os.environ.get('AWS_SECRET_ACCESS_KEY', '')
AWS_REGION = 'ap-south-1'

# DB Config (PRODUCTION)
DB_CONFIG = {
    'host': '35.154.96.221',
    'user': 'admin',
    'password': 'Connect@$999',
    'database': 'connectthrivelatest',
    'autocommit': True
}

def sync_filtered_videos():
    print("Connecting to S3 and Database...")
    s3 = boto3.client('s3', region_name=AWS_REGION, aws_access_key_id=AWS_ACCESS_KEY, aws_secret_access_key=AWS_SECRET_KEY)
    conn = pymysql.connect(**DB_CONFIG)
    cursor = conn.cursor()

    # 1. Clean existing data
    print("Clearing existing data...")
    cursor.execute("SET FOREIGN_KEY_CHECKS = 0;")
    cursor.execute("TRUNCATE TABLE batch_concepts;")
    cursor.execute("TRUNCATE TABLE concept;")
    cursor.execute("TRUNCATE TABLE course_module;")
    cursor.execute("TRUNCATE TABLE batch;")
    cursor.execute("TRUNCATE TABLE course;")
    cursor.execute("SET FOREIGN_KEY_CHECKS = 1;")

    # 2. Create Base Course and Batch
    cursor.execute("INSERT INTO course (id, name) VALUES (1, 'Oracle Fusion Financials');")
    cursor.execute("INSERT INTO batch (id, name) VALUES (1, 'Regular Batch');")

    # 3. Create the 4 Specific Modules
    MODULE_MAP = {
        'General Ledger (GL)': 1,
        'Account Payable (AP)': 2,
        'Accounts Receivable (AR)': 3,
        'Fixed Assets (FA)': 4
    }
    
    # Insert modules
    cursor.execute("INSERT INTO course_module (id, name, tier, description, course_id) VALUES (1, 'General Ledger (GL)', 'FREE', 'General Ledger concepts', 1)")
    cursor.execute("INSERT INTO course_module (id, name, tier, description, course_id) VALUES (2, 'Account Payable (AP)', 'FREE', 'Accounts Payable concepts', 1)")
    cursor.execute("INSERT INTO course_module (id, name, tier, description, course_id) VALUES (3, 'Accounts Receivable (AR)', 'FREE', 'Accounts Receivable concepts', 1)")
    cursor.execute("INSERT INTO course_module (id, name, tier, description, course_id) VALUES (4, 'Fixed Assets (FA)', 'PAID', 'Fixed Assets concepts', 1)")

    # 4. Map S3 Folders to these 4 Modules
    FOLDER_TO_MODULE = {
        '7': 1, '8': 1, '9': 1,   # GL
        '10': 2, '11': 2,        # AP
        '31': 3,                 # AR
        '12': 4                  # FA
    }

    print("Scanning S3 bucket and mapping videos...")
    paginator = s3.get_paginator('list_objects_v2')
    concept_id_counter = 1

    for page in paginator.paginate(Bucket=S3_BUCKET):
        for obj in page.get('Contents', []):
            key = obj['Key']
            if not key.endswith('.mp4'):
                continue
            
            parts = key.split('/')
            if len(parts) < 2: continue 
            
            folder = parts[0]
            if folder not in FOLDER_TO_MODULE:
                continue # Skip other modules
            
            target_module_id = FOLDER_TO_MODULE[folder]
            filename = parts[-1]
            title = filename.split('_', 1)[-1].replace('.mp4', '') if '_' in filename else filename.replace('.mp4', '')
            thumb_key = key.replace('/mp4/', '/thumbnails/').replace('.mp4', '.png')
            
            sql = "INSERT INTO concept (id, title, video_file_name, thumbnail_file_name, video_type, module_id) VALUES (%s, %s, %s, %s, 'Transaction', %s)"
            cursor.execute(sql, (concept_id_counter, title, key, thumb_key, target_module_id))
            
            cursor.execute("INSERT INTO batch_concepts (batch_id, concept_id) VALUES (1, %s)", (concept_id_counter,))
            concept_id_counter += 1

    print(f"Sync complete! Created 4 modules and {concept_id_counter-1} concepts.")
    conn.close()

if __name__ == "__main__":
    sync_filtered_videos()
