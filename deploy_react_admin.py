import os
import boto3
import mimetypes

# AWS Config
S3_BUCKET = 'connectreactadmin'
if os.path.exists('.env'):
    for line in open('.env'):
        if '=' in line and not line.startswith('#'):
            k, v = line.strip().split('=', 1)
            os.environ[k.strip()] = v.strip().strip("'").strip('"')

AWS_ACCESS_KEY = os.environ.get('AWS_ACCESS_KEY_ID', '')
AWS_SECRET_KEY = os.environ.get('AWS_SECRET_ACCESS_KEY', '')
AWS_REGION = 'ap-south-1'

def deploy():
    print("Initializing S3 Client...")
    s3 = boto3.client('s3', region_name=AWS_REGION, aws_access_key_id=AWS_ACCESS_KEY, aws_secret_access_key=AWS_SECRET_KEY)
    
    build_dir = '/Users/venkata.rao/Documents/code/connectthrive_admin_web_app/build'
    
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
        # Let's find all CloudFront distributions to invalidate the index.html cache
        cf = boto3.client('cloudfront', region_name=AWS_REGION, aws_access_key_id=AWS_ACCESS_KEY, aws_secret_access_key=AWS_SECRET_KEY)
        dists = cf.list_distributions()
        
        # We want to invalidate the distribution that serves admin.connectthrive.in
        target_dist_id = None
        for item in dists.get('DistributionList', {}).get('Items', []):
            aliases = item.get('Aliases', {}).get('Items', [])
            if 'admin.connectthrive.in' in aliases:
                target_dist_id = item['Id']
                break
                
        if target_dist_id:
            print(f"Found CloudFront Distribution ID: {target_dist_id}. Creating invalidation...")
            import time
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
        else:
            print("CloudFront distribution for admin.connectthrive.in not found or not accessible.")
    except Exception as e:
        print(f"Skipping CloudFront Invalidation (Permission Denied / Access Denied): {e}")

if __name__ == '__main__':
    deploy()
