#!/usr/bin/env python3
"""
Upload a local file to an Amazon S3 Bucket (AWS Data Lake)
"""

import argparse
import boto3
from botocore.exceptions import ClientError, NoCredentialsError


def upload_to_s3(bucket_name, local_file_path, destination_s3_key, region="us-east-1"):
    print(f"\n[S3 Upload] Starting upload...")
    print(f"  Source: {local_file_path}")
    print(f"  Target: s3://{bucket_name}/{destination_s3_key}")

    # Boto3 automatically reads AWS_ACCESS_KEY_ID & AWS_SECRET_ACCESS_KEY from env or ~/.aws/credentials
    s3_client = boto3.client("s3", region_name=region)

    try:
        s3_client.upload_file(local_file_path, bucket_name, destination_s3_key)
        print(f"✅ Successfully uploaded to s3://{bucket_name}/{destination_s3_key}")
    except FileNotFoundError:
        print(f"❌ Error: Local file '{local_file_path}' not found.")
    except NoCredentialsError:
        print("❌ Error: AWS credentials not found. Run 'aws configure' or check your .env file.")
    except ClientError as e:
        print(f"❌ AWS Client Error: {e}")


def main():
    parser = argparse.ArgumentParser(description="Upload file to Amazon S3")
    parser.add_argument("--bucket",     required=True, help="S3 bucket name")
    parser.add_argument("--local_file", required=True, help="Path to local file")
    parser.add_argument("--s3_key",     required=True, help="Destination key in S3")
    parser.add_argument("--region",     default="us-east-1", help="AWS region")

    args = parser.parse_args()
    upload_to_s3(args.bucket, args.local_file, args.s3_key, args.region)


if __name__ == "__main__":
    main()