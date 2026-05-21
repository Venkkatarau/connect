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

def sync_s3_to_db():
    print("Connecting to S3 and Database...")
    s3 = boto3.client('s3', region_name=AWS_REGION, aws_access_key_id=AWS_ACCESS_KEY, aws_secret_access_key=AWS_SECRET_KEY)
    conn = pymysql.connect(**DB_CONFIG)
    cursor = conn.cursor()

    # 1. Clean existing data (Full refresh)
    print("Clearing existing data for a full sync...")
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

    # 3. Scan S3 and create Modules/Concepts
    print("Scanning S3 bucket...")
    paginator = s3.get_paginator('list_objects_v2')
    
    modules = {} # folder_name -> module_id
    concept_id_counter = 1
    module_id_counter = 1

    MODULE_NAMES = {
        '7': 'General Ledger (GL) - Part 1',
        '8': 'General Ledger (GL) - Part 2',
        '9': 'GL Interview Preparation',
        '10': 'AP/AR Interview Questions',
        '11': 'Accounts Payable (AP)',
        '12': 'Fixed Assets (FA)',
        '31': 'Accounts Receivable (AR)'
    }

    for page in paginator.paginate(Bucket=S3_BUCKET):
        for obj in page.get('Contents', []):
            key = obj['Key']
            if not key.endswith('.mp4'):
                continue
            
            parts = key.split('/')
            if len(parts) < 2: continue 
            
            folder = parts[0]
            filename = parts[-1]
            
            if folder not in modules:
                module_name = MODULE_NAMES.get(folder, f"Module {folder}")
                cursor.execute("INSERT INTO course_module (id, name, tier, description, course_id) VALUES (%s, %s, 'FREE', %s, 1)", 
                              (module_id_counter, module_name, f"Content from S3 folder {folder}"))
                modules[folder] = module_id_counter
                module_id_counter += 1

            title = filename.split('_', 1)[-1].replace('.mp4', '') if '_' in filename else filename.replace('.mp4', '')
            thumb_key = key.replace('/mp4/', '/thumbnails/').replace('.mp4', '.png')
            
            sql = "INSERT INTO concept (id, title, video_file_name, thumbnail_file_name, video_type, module_id) VALUES (%s, %s, %s, %s, 'Transaction', %s)"
            cursor.execute(sql, (concept_id_counter, title, key, thumb_key, modules[folder]))
            
            cursor.execute("INSERT INTO batch_concepts (batch_id, concept_id) VALUES (1, %s)", (concept_id_counter,))
            concept_id_counter += 1

    print(f"Sync complete! Created {module_id_counter-1} modules and {concept_id_counter-1} concepts.")
    conn.close()

if __name__ == "__main__":
    sync_s3_to_db()
