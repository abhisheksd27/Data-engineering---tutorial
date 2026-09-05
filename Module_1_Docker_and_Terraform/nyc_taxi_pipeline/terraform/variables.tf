variable "aws_region" {
  description = "AWS Region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "s3_bucket_name" {
  description = "Globally unique Amazon S3 bucket name"
  type        = string
  default     = "ny-taxi-data-lake-abhishekshankar-826674"
}

variable "glue_database_name" {
  description = "Name of the Glue Data Catalog database"
  type        = string
  default     = "ny_taxi_db"
}