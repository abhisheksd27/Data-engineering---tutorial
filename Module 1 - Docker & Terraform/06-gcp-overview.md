# ☁️ Topic 6: Google Cloud Platform (GCP) Overview

> **GitHub**: [2_gcp_overview.md](https://github.com/DataTalksClub/data-engineering-zoomcamp/blob/main/01-docker-terraform/terraform/2_gcp_overview.md)  
> **Video**: [Introduction to GCP](https://youtu.be/18jIzE41fJ4)

---

## 🤔 Why GCP?

In Module 1, we run everything **locally** (on your laptop). But real data engineering happens in the **cloud**:
- Data too large for local storage
- Need scalable compute
- Team collaboration
- 24/7 availability

The **Data Engineering Zoomcamp** uses **Google Cloud Platform (GCP)** because:
- Has a **free tier** / free trial (\$300 credits for 90 days)
- Used heavily in the industry
- Has BigQuery (Module 3), Cloud Storage, Dataproc, etc.

---

## 🏗️ GCP Architecture for This Course

```
GCP Project
│
├── Cloud Storage (GCS)          ← Data Lake (raw files)
│   └── Bucket: de-zoomcamp-xxxx
│
├── BigQuery                     ← Data Warehouse (Module 3)
│   └── Dataset: ny_taxi
│
├── IAM & Admin                  ← Access control
│   └── Service Account: de-zoomcamp@...
│
└── Compute Engine (optional)    ← VMs if needed
```

---

## 📋 Step-by-Step GCP Setup

### Step 1: Create a GCP Account

1. Go to [console.cloud.google.com](https://console.cloud.google.com/)
2. Sign in with a Google account
3. Activate the **free trial** (\$300 free credits)

### Step 2: Create a New Project

1. Click the project dropdown at the top
2. Click "New Project"
3. Name it: `de-zoomcamp` (or similar)
4. Note your **Project ID** (auto-generated, looks like `de-zoomcamp-12345`)

### Step 3: Enable Required APIs

In GCP Console → APIs & Services → Library, enable:
- **Cloud Storage API**
- **BigQuery API**
- **Compute Engine API** (optional)

Or via command line:
```bash
gcloud services enable storage.googleapis.com
gcloud services enable bigquery.googleapis.com
```

### Step 4: Create a Service Account

A **service account** is like a "robot user" — it lets Terraform and other tools authenticate to GCP programmatically.

1. Go to IAM & Admin → Service Accounts
2. Click "Create Service Account"
3. Name: `de-zoomcamp-sa`
4. Assign roles:
   - **Storage Admin** (full access to GCS)
   - **BigQuery Admin** (full access to BigQuery)
   - **Viewer** (basic read access)

### Step 5: Create and Download Service Account Key

1. Click on the service account → Keys tab
2. Add Key → Create new key → JSON
3. Download the JSON key file — **keep this secret!**
4. Save it as `~/.google/credentials/google_credentials.json`

> ⚠️ **NEVER commit credentials to Git!** Add to `.gitignore`

### Step 6: Install Google Cloud SDK

```bash
# macOS
brew install --cask google-cloud-sdk

# Or download from: https://cloud.google.com/sdk/docs/install
```

```bash
# Initialize and login
gcloud init
gcloud auth login

# Set your project
gcloud config set project YOUR-PROJECT-ID

# Authenticate for applications (Terraform uses this)
gcloud auth application-default login
```

---

## 🗄️ Google Cloud Storage (GCS)

GCS is an object storage service — think of it like a giant file system in the cloud.

In data engineering, we use GCS as a **Data Lake**:
- Store raw files (CSV, Parquet)
- Cheap storage for large data
- Accessible from BigQuery, Dataproc, etc.

### Creating a bucket via CLI

```bash
# Create a storage bucket
gsutil mb -l US gs://de-zoomcamp-YOUR-PROJECT-ID/
```

### Bucket naming rules
- Must be globally unique
- Lowercase letters, numbers, hyphens only
- 3–63 characters

---

## 🏭 BigQuery Overview

BigQuery is Google's **cloud data warehouse** — a serverless, highly scalable database.

Key features:
- Query terabytes of data in seconds
- Pay only for what you query
- Built-in ML capabilities
- No infrastructure to manage

We'll use BigQuery extensively in **Module 3**.

### BigQuery structure:
```
GCP Project
└── BigQuery Dataset (like a schema/database)
    └── Table (your data)
    └── Table (another table)
    └── View (virtual table)
```

---

## 🔑 GCP IAM (Identity and Access Management)

IAM controls **who can do what** in GCP.

### Key concepts:

| Concept | Description | Example |
|---------|-------------|---------|
| **Principal** | Who is acting | User, Service Account |
| **Role** | Set of permissions | Storage Admin, BigQuery Viewer |
| **Policy** | Binds principal to role | "SA X has role Y on resource Z" |

### Principle of Least Privilege
Only grant the permissions you actually need:
- ❌ Don't give `Owner` role unless necessary
- ✅ Use `Storage Admin` only if you need to manage storage
- ✅ Use `BigQuery Data Viewer` if you only need to read data

---

## 🔧 Setting Up Credentials for Terraform

Terraform needs to know how to authenticate to GCP:

```bash
# Option 1: Set environment variable
export GOOGLE_APPLICATION_CREDENTIALS="~/.google/credentials/google_credentials.json"

# Option 2: Use gcloud auth
gcloud auth application-default login
```

In your Terraform code:
```hcl
provider "google" {
  credentials = file(var.credentials)
  project     = var.project
  region      = var.region
}
```

---

## 📊 GCP Services Used in This Course

| Module | GCP Service | Purpose |
|--------|-------------|---------|
| Module 1 | Cloud Storage | Create bucket with Terraform |
| Module 1 | BigQuery | Create dataset with Terraform |
| Module 2 | Cloud Storage | Kestra workflow storage |
| Module 3 | BigQuery | Data warehouse |
| Module 4 | BigQuery | dbt transformations |
| Module 5 | Dataproc | Spark cluster |
| Module 6 | Pub/Sub + BigQuery | Streaming data |

---

## 💡 GCP Free Tier Resources

| Service | Free Tier |
|---------|-----------|
| Cloud Storage | 5 GB/month |
| BigQuery | 1 TB queries/month, 10 GB storage |
| Cloud Functions | 2M invocations/month |
| Cloud Run | 2M requests/month |

> 💰 The \$300 free trial is more than enough for this entire course!

---

*Previous: [Topic 5 - SQL Refresher](05-sql-refresher.md) | Next: [Topic 7 - Terraform →](07-terraform-concepts.md)*
