variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "s3_bucket_name" {
  description = "S3 data lake bucket name (created in Module 1)"
  type        = string
  default     = "ny-taxi-data-lake-abhishekshankar-826674"
}

variable "glue_database_name" {
  description = "AWS Glue catalog database name"
  type        = string
  default     = "ny_taxi_db"
}
