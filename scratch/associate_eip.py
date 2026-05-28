import os
import boto3

# Load .env
if os.path.exists('.env'):
    for line in open('.env'):
        if '=' in line and not line.startswith('#'):
            k, v = line.strip().split('=', 1)
            os.environ[k.strip()] = v.strip().strip("'").strip('"')

aws_access_key = os.environ.get('AWS_ACCESS_KEY_ID', '')
aws_secret_key = os.environ.get('AWS_SECRET_ACCESS_KEY', '')
aws_region = 'ap-south-1'

ec2 = boto3.client('ec2', region_name=aws_region, aws_access_key_id=aws_access_key, aws_secret_access_key=aws_secret_key)

try:
    print("Attempting to associate Elastic IP 35.154.96.221 to instance i-0a3f259349bc80141...")
    response = ec2.associate_address(
        InstanceId='i-0a3f259349bc80141',
        PublicIp='35.154.96.221'
    )
    print("Success! Association details:")
    print(response)
except Exception as e:
    print("Failed to associate via API:")
    print(e)
