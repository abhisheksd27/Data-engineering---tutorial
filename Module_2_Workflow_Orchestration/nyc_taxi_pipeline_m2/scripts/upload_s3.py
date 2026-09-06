"""
upload_s3.py
------------
Upload a local file to AWS S3.
In Module 2, Kestra handles S3 uploads natively via io.kestra.plugin.aws.s3.Upload.
This script is kept as a standalone fallback / reference.

Usage:
    python upload_s3.py \
        --file data/green_tripdata_2025-11.parquet \
        --bucket ny-taxi-data-lake-abhishekshankar-826674 \
        --key raw/green_tripdata_2025-11.parquet \
        --region us-east-1
"""

import argparse
import boto3
from botocore.exceptions import ClientError
import os


def upload_to_s3(local_file: str, bucket: str, s3_key: str, region: str = "us-east-1") -> str:
    """Upload a file to an S3 bucket. Returns the S3 URI on success."""

    s3_client = boto3.client(
        "s3",
        region_name=region,
        aws_access_key_id=os.getenv("AWS_ACCESS_KEY_ID"),
        aws_secret_access_key=os.getenv("AWS_SECRET_ACCESS_KEY"),
    )

    try:
        print(f"Uploading {local_file} → s3://{bucket}/{s3_key}")
        s3_client.upload_file(local_file, bucket, s3_key)
        s3_uri = f"s3://{bucket}/{s3_key}"
        print(f"✅ Upload complete: {s3_uri}")
        return s3_uri

    except ClientError as e:
        print(f"❌ Upload failed: {e}")
        raise


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Upload file to AWS S3")
    parser.add_argument("--file", required=True, help="Local file path")
    parser.add_argument("--bucket", required=True, help="S3 bucket name")
    parser.add_argument("--key", required=True, help="S3 object key (path within bucket)")
    parser.add_argument("--region", default="us-east-1", help="AWS region")
    args = parser.parse_args()

    upload_to_s3(
        local_file=args.file,
        bucket=args.bucket,
        s3_key=args.key,
        region=args.region,
    )
