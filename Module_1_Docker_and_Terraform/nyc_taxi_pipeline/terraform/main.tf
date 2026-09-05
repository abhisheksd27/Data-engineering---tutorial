terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# 1. Amazon S3 Data Lake Bucket
resource "aws_s3_bucket" "data_lake" {
  bucket        = var.s3_bucket_name
  force_destroy = true
}

resource "aws_s3_bucket_versioning" "data_lake_versioning" {
  bucket = aws_s3_bucket.data_lake.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "data_lake_lifecycle" {
  bucket = aws_s3_bucket.data_lake.id

  rule {
    id     = "expire-old-files-after-30-days"
    status = "Enabled"

    filter {}

    expiration {
      days = 30
    }
  }
}

# 2. AWS Glue Catalog Database (Metadata & Schema store)
resource "aws_glue_catalog_database" "taxi_database" {
  name        = var.glue_database_name
  description = "Glue Catalog Database for NYC Taxi dataset"
}

# 3. Amazon Athena Workgroup & Results Bucket
resource "aws_s3_bucket" "athena_results" {
  bucket        = "${var.s3_bucket_name}-athena-results"
  force_destroy = true
}

resource "aws_athena_workgroup" "taxi_workgroup" {
  name          = "ny_taxi_workgroup"
  force_destroy = true

  configuration {
    enforce_workgroup_configuration    = true
    publish_cloudwatch_metrics_enabled = true

    result_configuration {
      output_location = "s3://${aws_s3_bucket.athena_results.bucket}/output/"
    }
  }
}