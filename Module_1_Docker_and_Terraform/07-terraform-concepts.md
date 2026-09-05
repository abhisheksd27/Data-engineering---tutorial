# 🏗️ Topic 7: Terraform — Infrastructure as Code with AWS

> **GitHub Reference**: [terraform/](https://github.com/DataTalksClub/data-engineering-zoomcamp/tree/main/01-docker-terraform/terraform)  
> **Terraform Concepts Video**: [Terraform Concepts](https://youtu.be/s2bOYDCKl_M)

---

## 🤔 What is Terraform?

**Terraform** is an open-source tool by HashiCorp that allows you to define and manage cloud infrastructure using code (known as **Infrastructure as Code** or IaC).

### Without Terraform (Manual AWS Console clicks)
1. Open the AWS Web Console.
2. Click S3 ➔ Create Bucket ➔ configure versioning, retention rules, tags.
3. Click Glue ➔ Create Database ➔ configure schema.
4. Click Athena ➔ Create Workgroup ➔ create an S3 results bucket.
5. If you want to replicate this in staging or prod, you must click through everything again and risk human error.

### With Terraform (IaC)
You describe all resources in `.tf` files. A single command (`terraform apply`) creates the exact same infrastructure reliably every time. When you are done, `terraform destroy` wipes everything so you never incur unexpected cloud bills.

---

## 🔑 The 4 Essential Terraform Commands

```
   terraform init       → Downloads AWS provider plugins and sets up workspace
         ↓
   terraform plan       → Dry-run preview: shows what resources will be added (+), modified (~), or deleted (-)
         ↓
   terraform apply      → Executes the changes against AWS API to create resources
         ↓
   terraform destroy    → Tears down all provisioned resources (saves money!)
```

---

## 🧱 Core Terraform Building Blocks

### 1. Provider
Tells Terraform which cloud platform to manage (in our case, `aws`):

```hcl
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
  # Authentication is automatically discovered from ~/.aws/credentials or AWS env vars
}
```

### 2. Resources
Defines components in AWS:
- `aws_s3_bucket`: Creates the S3 storage bucket.
- `aws_s3_bucket_lifecycle_configuration`: Automatically deletes files older than 30 days to avoid storage bloat.
- `aws_glue_catalog_database`: Metadata schema definition.
- `aws_athena_workgroup`: Sets up query output locations.

### 3. Variables (`variables.tf`)
Keeps your code generic and reusable across environments:

```hcl
variable "aws_region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "s3_bucket_name" {
  description = "Globally unique Amazon S3 bucket name"
  type        = string
  default     = "ny-taxi-data-lake-unique-12345"
}

variable "glue_database_name" {
  description = "Name of the Glue Data Catalog database"
  type        = string
  default     = "ny_taxi_db"
}
```

---

## 📝 Complete AWS Terraform Code

### `main.tf`

```hcl
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# ── 1. AWS Provider ─────────────────────────────────────────
provider "aws" {
  region = var.aws_region
}

# ── 2. Amazon S3 Bucket (Data Lake) ─────────────────────────
resource "aws_s3_bucket" "data_lake" {
  bucket        = var.s3_bucket_name
  force_destroy = true # Allows Terraform to delete bucket even if it has files
}

# Enable versioning on S3 data lake
resource "aws_s3_bucket_versioning" "data_lake_versioning" {
  bucket = aws_s3_bucket.data_lake.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Lifecycle rule: Expire old files after 30 days
resource "aws_s3_bucket_lifecycle_configuration" "data_lake_lifecycle" {
  bucket = aws_s3_bucket.data_lake.id

  rule {
    id     = "expire-old-files-after-30-days"
    status = "Enabled"

    expiration {
      days = 30
    }
  }
}

# ── 3. AWS Glue Catalog Database (Metadata Store) ───────────
resource "aws_glue_catalog_database" "taxi_database" {
  name        = var.glue_database_name
  description = "Glue Catalog Database for NYC Taxi dataset"
}

# ── 4. Athena Workgroup & Query Results Bucket ───────────────
# Athena requires an S3 bucket to save CSV query results
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
```

---

## 🔒 Security Best Practice: `.gitignore` for Terraform

Terraform generates a `terraform.tfstate` file after applying. This file contains metadata and sensitive IDs. **Never commit state files or credentials to Git!**

```gitignore
# Local state files
*.tfstate
*.tfstate.*
*.tfstate.backup

# Working directory and lock file
.terraform/
.terraform.lock.hcl

# Variable files containing secret values
*.tfvars
*.tfvars.json

# Credentials
*.csv
keys/
```

---

## 🚀 Running Terraform Step-by-Step

Make sure your AWS CLI credentials are configured (`aws configure`):

```bash
# 1. Move into the terraform directory
cd terraform

# 2. Initialize Terraform (downloads AWS plugin)
terraform init

# 3. Dry-run to preview what will be created
terraform plan

# 4. Apply changes (provisions S3 bucket, Glue DB, and Athena workgroup)
terraform apply -auto-approve

# 5. Verify in AWS Console:
#    - S3: See your data lake bucket
#    - Glue: See ny_taxi_db database
#    - Athena: See ny_taxi_workgroup

# 6. When you are done with your practice:
terraform destroy -auto-approve
```

---

*Previous: [Topic 6 - AWS Overview](06-aws-overview.md) | Next: [Topic 8 - Module 1 Project →](08-project.md)*
