# 🏗️ Topic 7: Terraform — Infrastructure as Code

> **GitHub**: [terraform/](https://github.com/DataTalksClub/data-engineering-zoomcamp/tree/main/01-docker-terraform/terraform)  
> **Video 1**: [Terraform Concepts](https://youtu.be/s2bOYDCKl_M)  
> **Video 2**: [Terraform Basics](https://youtu.be/Y2ux7gq3Z0o)  
> **Video 3**: [Variables File](https://youtu.be/PBi0hHjLftk)

---

## 🤔 What is Terraform?

**Terraform** is an open-source tool by HashiCorp that lets you define cloud infrastructure using code (called **Infrastructure as Code** or IaC).

### Without Terraform (manual)
1. Log into GCP Console
2. Click "Create Bucket"
3. Fill in name, region, settings
4. Click "Create"
5. Repeat for every resource
6. Hope you remember exactly what settings you used!

### With Terraform (IaC)
```hcl
resource "google_storage_bucket" "data-lake-bucket" {
  name     = "de_zoomcamp_data_lake"
  location = "US"
}
```
Run `terraform apply` → Bucket created automatically, reproducibly, every time!

---

## 🌟 Why Use Terraform?

| Benefit | Explanation |
|---------|-------------|
| **Reproducibility** | Same config → same infrastructure, every time |
| **Version Control** | Infrastructure in Git = track changes, rollback |
| **Collaboration** | Team can review infra changes via Pull Requests |
| **Documentation** | Config file IS the documentation |
| **Multi-cloud** | Works with AWS, Azure, GCP, and 100+ providers |
| **Dry runs** | `terraform plan` shows what WILL change before applying |

---

## 🔑 Core Terraform Concepts

### 1. Provider
Tells Terraform which cloud platform to talk to:

```hcl
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project     = "de-zoomcamp-123456"
  region      = "us-central1"
  credentials = file("~/.google/credentials/google_credentials.json")
}
```

### 2. Resource
Something you want to create in the cloud:

```hcl
resource "provider_type" "local_name" {
  # configuration
}
```

Example — Creating a GCS Bucket:
```hcl
resource "google_storage_bucket" "data_lake" {
  name          = "de_zoomcamp_data_lake_123456"
  location      = "US"
  force_destroy = true

  lifecycle_rule {
    condition {
      age = 30  # Delete objects older than 30 days
    }
    action {
      type = "Delete"
    }
  }
}
```

### 3. Variable
Makes your configuration reusable:

```hcl
variable "project" {
  description = "GCP Project ID"
  default     = "de-zoomcamp-123456"
}

variable "region" {
  description = "GCP Region"
  default     = "us-central1"
}

variable "bq_dataset_name" {
  description = "BigQuery Dataset Name"
  default     = "demo_dataset"
}

variable "gcs_bucket_name" {
  description = "GCS Bucket Name"
  default     = "demo-bucket-unique-name"
}
```

### 4. Output
Print values after resources are created:

```hcl
output "bucket_url" {
  value = google_storage_bucket.data_lake.url
}
```

---

## 📁 Terraform File Structure

```
terraform/
├── main.tf          ← Main resource definitions
├── variables.tf     ← Variable declarations
├── terraform.tfvars ← Variable values (NOT in Git!)
└── outputs.tf       ← Output definitions
```

**`.gitignore`** for Terraform:
```
.terraform/
terraform.tfvars
*.tfstate
*.tfstate.backup
.terraform.lock.hcl
```

---

## 📝 Complete Example: `main.tf`

This is the actual code used in the zoomcamp to set up GCP infrastructure:

```hcl
terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.6.0"
    }
  }
}

provider "google" {
  credentials = file(var.credentials)
  project     = var.project
  region      = var.region
}

# Google Cloud Storage Bucket (Data Lake)
resource "google_storage_bucket" "demo-bucket" {
  name          = var.gcs_bucket_name
  location      = var.location
  force_destroy = true

  lifecycle_rule {
    condition {
      age = 1
    }
    action {
      type = "AbortIncompleteMultipartUpload"
    }
  }
}

# BigQuery Dataset (Data Warehouse)
resource "google_bigquery_dataset" "demo_dataset" {
  dataset_id = var.bq_dataset_name
  location   = var.location
}
```

**`variables.tf`**:

```hcl
variable "credentials" {
  description = "My Credentials"
  default     = "./keys/my-creds.json"
}

variable "project" {
  description = "Project"
  default     = "your-project-id"
}

variable "region" {
  description = "Region"
  default     = "us-central1"
}

variable "location" {
  description = "Project Location"
  default     = "US"
}

variable "bq_dataset_name" {
  description = "My BigQuery Dataset Name"
  default     = "demo_dataset"
}

variable "gcs_bucket_name" {
  description = "My Storage Bucket Name"
  default     = "demo-terra-bucket"
}

variable "gcs_storage_class" {
  description = "Bucket Storage Class"
  default     = "STANDARD"
}
```

---

## 🚀 Terraform Workflow (The 4 Commands)

### 1. `terraform init`
Downloads provider plugins and sets up the working directory.

```bash
terraform init
```

Output:
```
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/google versions matching "5.6.0"...
- Installing hashicorp/google v5.6.0...
Terraform has been successfully initialized!
```

### 2. `terraform plan`
Shows what Terraform WILL do — **dry run, no changes made**.

```bash
terraform plan
```

Output:
```
Terraform will perform the following actions:

  # google_bigquery_dataset.demo_dataset will be created
  + resource "google_bigquery_dataset" "demo_dataset" {
      + dataset_id = "demo_dataset"
      + location   = "US"
      ...
    }

  # google_storage_bucket.demo-bucket will be created
  + resource "google_storage_bucket" "demo-bucket" {
      + name     = "demo-terra-bucket"
      + location = "US"
      ...
    }

Plan: 2 to add, 0 to change, 0 to destroy.
```

### 3. `terraform apply`
Actually creates/modifies the infrastructure.

```bash
terraform apply
```

You'll see the plan again, then a prompt:
```
Do you want to perform these actions? (yes/no): yes
```

Type `yes` and resources are created!

```
google_storage_bucket.demo-bucket: Creating...
google_storage_bucket.demo-bucket: Creation complete after 1s
google_bigquery_dataset.demo_dataset: Creating...
google_bigquery_dataset.demo_dataset: Creation complete after 2s

Apply complete! Resources: 2 added, 0 changed, 0 destroyed.
```

### 4. `terraform destroy`
Destroys all resources (avoids cloud costs when done).

```bash
terraform destroy
```

> ⚠️ **Always run `terraform destroy`** when you're done to avoid unexpected GCP bills!

---

## 📊 Terraform State

Terraform tracks the current state of your infrastructure in a **state file** (`terraform.tfstate`).

```json
{
  "resources": [
    {
      "type": "google_storage_bucket",
      "name": "demo-bucket",
      "instances": [
        {
          "attributes": {
            "name": "demo-terra-bucket",
            "location": "US",
            "url": "gs://demo-terra-bucket"
          }
        }
      ]
    }
  ]
}
```

- Never edit this file manually
- In teams, store state in GCS (remote backend)
- **Add to `.gitignore`** — it may contain sensitive data

---

## 🔄 Terraform Lifecycle

```
Code Changes (main.tf)
      ↓
terraform plan (preview changes)
      ↓
Code Review (optional, team)
      ↓
terraform apply (make changes)
      ↓
Verify in GCP Console
      ↓
[Use infrastructure for the course]
      ↓
terraform destroy (when done, save money!)
```

---

## 🌐 How Terraform Connects to the Rest of the Course

```
Terraform (Module 1)
    ↓ creates
GCS Bucket ─────────────────────────────────┐
BigQuery Dataset ───────────────────────────┤
                                            ↓
                              Module 2: Kestra writes data to GCS
                              Module 3: BigQuery queries warehouse
                              Module 4: dbt transforms in BigQuery
                              Module 5: Spark reads from GCS
                              Module 6: Streaming data → BigQuery
```

You provision infrastructure **once** with Terraform, and all subsequent modules USE that infrastructure!

---

## ✅ Quick Reference

```bash
# Install Terraform (macOS)
brew tap hashicorp/tap
brew install hashicorp/tap/terraform

# Verify installation
terraform version

# The 4 commands
terraform init     # Set up working directory
terraform plan     # Preview changes (dry run)
terraform apply    # Apply changes to cloud
terraform destroy  # Tear down all resources
```

---

*Previous: [Topic 6 - GCP Overview](06-gcp-overview.md) | Next: [Topic 8 - Module 1 Project →](08-project.md)*
