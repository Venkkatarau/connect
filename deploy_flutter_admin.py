import os
import subprocess
import boto3
import mimetypes
import time

# AWS Config
S3_BUCKET = 'connectreactadmin'
AWS_REGION = 'ap-south-1'

# Load .env file
env_path = '/Users/venkata.rao/Documents/code/.env'
if os.path.exists(env_path):
    for line in open(env_path):
        if '=' in line and not line.startswith('#'):
            k, v = line.strip().split('=', 1)
            os.environ[k.strip()] = v.strip().strip("'").strip('"')

AWS_ACCESS_KEY = os.environ.get('AWS_ACCESS_KEY_ID', '')
AWS_SECRET_KEY = os.environ.get('AWS_SECRET_ACCESS_KEY', '')

def run_command(command, cwd):
    print(f"Running command: {command} inside {cwd}...")
    result = subprocess.run(command, shell=True, cwd=cwd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if result.returncode != 0:
        print("Command failed!")
        print("STDOUT:", result.stdout)
        print("STDERR:", result.stderr)
        raise RuntimeError("Build failed")
    print("Command succeeded.")
    print(result.stdout)

def deploy():
    flutter_dir = '/Users/venkata.rao/Documents/code/connectthrive_admin_web_flutter'
    build_dir = os.path.join(flutter_dir, 'build/web')
    
    # 1. Run flutter build web --release
    print("Building Flutter Web App...")
    run_command("flutter build web --release", flutter_dir)
    
    # 2. Upload to S3
    print("Initializing S3 Client...")
    s3 = boto3.client('s3', region_name=AWS_REGION, aws_access_key_id=AWS_ACCESS_KEY, aws_secret_access_key=AWS_SECRET_KEY)
    
    print("Uploading build files to S3 bucket:", S3_BUCKET)
    for root, dirs, files in os.walk(build_dir):
        for filename in files:
            local_path = os.path.join(root, filename)
            relative_path = os.path.relpath(local_path, build_dir)
            
            # Determine content type
            content_type, _ = mimetypes.guess_type(local_path)
            if not content_type:
                if filename.endswith('.json'):
                    content_type = 'application/json'
                elif filename.endswith('.map'):
                    content_type = 'application/json'
                else:
                    content_type = 'binary/octet-stream'
            
            print(f"Uploading {relative_path} ({content_type})...")
            
            with open(local_path, 'rb') as f:
                s3.put_object(
                    Bucket=S3_BUCKET,
                    Key=relative_path,
                    Body=f,
                    ContentType=content_type
                )
                
    print("Deployment complete! Invalidating CloudFront cache...")
    
    try:
        # Direct invalidation using the Distribution ID from the screenshot
        cf = boto3.client('cloudfront', region_name=AWS_REGION, aws_access_key_id=AWS_ACCESS_KEY, aws_secret_access_key=AWS_SECRET_KEY)
        target_dist_id = "E2JSG2UVFKAZB"
        
        print(f"Creating CloudFront invalidation for Distribution ID: {target_dist_id}...")
        cf.create_invalidation(
            DistributionId=target_dist_id,
            InvalidationBatch={
                'Paths': {
                    'Quantity': 1,
                    'Items': ['/*']
                },
                'CallerReference': str(time.time())
            }
        )
        print("Invalidation created successfully!")
    except Exception as e:
        print(f"Skipping CloudFront Invalidation (Permission Denied / Access Denied): {e}")

if __name__ == '__main__':
    deploy()
