terraform {
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

# ─── Data sources ─────────────────────────────────────────────────────────
data "aws_caller_identity" "current" {}

# ─── S3: Data Lake Bucket (already created in Module 1) ───────────────────
# This is a reference — Terraform will manage additional resources
# but NOT re-create the existing bucket to avoid destroying Module 1 data.

# ─── Glue Database (already created in Module 1) ─────────────────────────
resource "aws_glue_catalog_database" "ny_taxi_db" {
  name = var.glue_database_name
}

# ─── Glue Table: green_taxi_trips (points to S3 raw/ prefix) ─────────────
resource "aws_glue_catalog_table" "green_taxi_trips" {
  database_name = aws_glue_catalog_database.ny_taxi_db.name
  name          = "green_taxi_trips"

  table_type = "EXTERNAL_TABLE"

  parameters = {
    "classification"        = "parquet"
    "parquet.compression"   = "SNAPPY"
    "EXTERNAL"              = "TRUE"
  }

  storage_descriptor {
    location      = "s3://${var.s3_bucket_name}/raw/"
    input_format  = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetInputFormat"
    output_format = "org.apache.hadoop.hive.ql.io.parquet.MapredParquetOutputFormat"

    ser_de_info {
      serialization_library = "org.apache.hadoop.hive.ql.io.parquet.serde.ParquetHiveSerDe"
    }

    columns {
      name = "vendorid"
      type = "int"
    }
    columns {
      name = "lpep_pickup_datetime"
      type = "timestamp"
    }
    columns {
      name = "lpep_dropoff_datetime"
      type = "timestamp"
    }
    columns {
      name = "passenger_count"
      type = "int"
    }
    columns {
      name = "trip_distance"
      type = "double"
    }
    columns {
      name = "pulocationid"
      type = "int"
    }
    columns {
      name = "dolocationid"
      type = "int"
    }
    columns {
      name = "total_amount"
      type = "double"
    }
    columns {
      name = "payment_type"
      type = "int"
    }
  }
}

# ─── Outputs ──────────────────────────────────────────────────────────────
output "glue_database_name" {
  value = aws_glue_catalog_database.ny_taxi_db.name
}

output "glue_table_name" {
  value = aws_glue_catalog_table.green_taxi_trips.name
}
