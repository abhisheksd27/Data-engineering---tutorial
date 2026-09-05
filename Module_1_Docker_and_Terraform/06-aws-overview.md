# ☁️ Topic 6: Amazon Web Services (AWS) Overview

> **Cloud Focus**: Amazon Web Services (AWS) replacing Google Cloud Platform (GCP)  
> **Core Services**: Amazon S3 (Data Lake), AWS Glue Data Catalog (Metadata), Amazon Athena (Serverless SQL), AWS IAM (Access Control)

---

## 🤔 Why AWS for Data Engineering?

**Amazon Web Services (AWS)** is the most widely adopted cloud platform in the world. In data engineering, AWS provides industry-standard building blocks:
- **Scalability**: Store infinite amounts of data in Amazon S3.
- **Cost Efficiency**: Serverless services like Amazon Athena charge only for the queries you run (no standing server cost).
- **Ecosystem**: Native integration with Spark (EMR), Airflow (MWAA), Kafka (MSK), and modern data tools (dbt, Kestra).

---

## 🎁 AWS Free Tier Overview

When you create a free AWS account, you receive:

### 1. 12 Months Free Tier
- **Amazon S3 (Data Lake)**: **5 GB** of standard storage, 20,000 GET requests, 2,000 PUT requests per month for 12 months.
- **Amazon EC2 (Virtual Machines)**: 750 hours/month of `t2.micro` or `t3.micro`.
- **Amazon RDS (Relational Database)**: 750 hours/month of `db.t2.micro` or `db.t3.micro` for PostgreSQL/MySQL.

### 2. Always Free Tier
- **AWS Lambda**: 1,000,000 free requests per month.
- **AWS Glue Data Catalog**: First 1,000,000 objects/tables stored are free.
- **Amazon CloudWatch**: Basic monitoring, metrics, and alarms.

### 3. Serverless Querying with Amazon Athena
- **Pricing**: Pay purely per query scanned at **\$5.00 per 1 TB**.
- For NYC Taxi Parquet datasets (~100 MB–500 MB), scanning costs **less than \$0.001 (a fraction of a single cent)** per query.
- Unlike traditional cloud warehouses (such as Redshift clusters or Snowflake), Athena has **no monthly standing server fee**. If you do not run a query, your cost is **\$0.00**.

---

## 🏗️ AWS Data Lake Architecture

```
AWS Account (us-east-1)
│
├── IAM (Identity & Access Management)
│   └── User: de-zoomcamp-admin (Programmatic Access Keys)
│
├── Amazon S3 (Object Storage / Data Lake)
│   ├── s3://<your-bucket-name>/
│   │   ├── raw/                      ← Raw CSV / Parquet trip data
│   │   └── lookup/                   ← Zone lookup CSVs
│   └── s3://<your-bucket-name>-athena-results/
│       └── output/                   ← Athena query outputs
│
├── AWS Glue Data Catalog (Metadata Store)
│   └── Database: ny_taxi_db
│       └── Table: green_taxi_trips   ← External table schema pointing to S3
│
└── Amazon Athena (Serverless Query Engine)
    └── Workgroup: ny_taxi_workgroup  ← Executes standard SQL directly on S3 files
```

---

## 📋 Step-by-Step AWS Setup

### Step 1: Create an AWS Account
1. Go to [https://aws.amazon.com](https://aws.amazon.com).
2. Click **Create an AWS Account** (requires email, password, and credit/debit card for verification).
3. Choose the **Free Basic Support** plan.

### Step 2: Create an IAM Admin User for Terraform and Scripts
Best security practice: Never use your root account for development or coding!

1. In the AWS Console search bar, type **IAM** and select **IAM**.
2. Click **Users** ➔ **Create user**.
3. Name: `de-zoomcamp-admin`.
4. Select **Attach policies directly** and attach:
   - `AmazonS3FullAccess` (to create buckets and upload data)
   - `AmazonAthenaFullAccess` (to execute queries)
   - `AWSGlueConsoleFullAccess` (to manage catalog databases & schemas)
5. Click **Create user**.

### Step 3: Generate Access Keys
1. Click on the user you just created (`de-zoomcamp-admin`).
2. Go to the **Security credentials** tab.
3. Scroll down to **Access keys** ➔ Click **Create access key**.
4. Select **Command Line Interface (CLI)**.
5. Check the confirmation box and click **Next** ➔ **Create access key**.
6. Copy or download the `.csv` containing:
   - `Access Key ID` (e.g., `AKIAIOSFODNN7EXAMPLE`)
   - `Secret Access Key` (e.g., `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`)

> ⚠️ **IMPORTANT**: Never commit your Access Key or Secret Key to GitHub! Always add `.env` and `*.csv` to your `.gitignore`.

### Step 4: Install and Configure AWS CLI on Your Machine

Install AWS CLI via Homebrew (macOS):
```bash
brew install awscli
```

Verify installation:
```bash
aws --version
```

Configure your credentials:
```bash
aws configure
```

When prompted, paste:
- **AWS Access Key ID**: `YOUR_ACCESS_KEY_ID`
- **AWS Secret Access Key**: `YOUR_SECRET_ACCESS_KEY`
- **Default region name**: `us-east-1` (or your preferred region like `ap-south-1`)
- **Default output format**: `json`

Test your connection:
```bash
aws sts get-caller-identity
```
If configured correctly, this prints your Account ID and User ARN!

---

## 🗄️ Core AWS Services in This Course

### 1. Amazon S3 (Simple Storage Service)
S3 stores files (objects) inside containers called **Buckets**.
- **Bucket Naming Rule**: Bucket names must be **globally unique across all AWS accounts worldwide** (e.g. `ny-taxi-data-lake-abhishek-12345`).
- **Standard Storage Class**: High durability (99.999999999% - 11 9's) and low latency.

#### Helpful AWS S3 CLI Commands:
```bash
# List all your buckets
aws s3 ls

# Create a new bucket in us-east-1
aws s3 mb s3://my-taxi-data-lake-unique-12345 --region us-east-1

# Upload a local file to S3
aws s3 cp data/green_tripdata_2025-11.parquet s3://my-taxi-data-lake-unique-12345/raw/

# List files inside a specific prefix/folder
aws s3 ls s3://my-taxi-data-lake-unique-12345/raw/

# Download a file from S3 to local disk
aws s3 cp s3://my-taxi-data-lake-unique-12345/raw/green_tripdata_2025-11.parquet ./downloaded.parquet

# Delete an object
aws s3 rm s3://my-taxi-data-lake-unique-12345/raw/green_tripdata_2025-11.parquet
```

### 2. AWS Glue Data Catalog
The Glue Data Catalog acts as a central **metadata repository** (similar to Hive Metastore).
- It stores table schemas, column data types, and the physical location in S3.
- It allows SQL engines like **Amazon Athena** or **Apache Spark** to understand what format the files are in without moving the data.

### 3. Amazon Athena
Athena is an interactive query service that makes it easy to analyze data directly in Amazon S3 using standard SQL.
- **Serverless**: No servers to manage, no clusters to start or stop.
- **Direct S3 Querying**: You can write `SELECT * FROM ny_taxi_db.green_taxi_trips` and Athena reads the raw Parquet files from S3 on the fly!
- **Athena Result Bucket**: Every Athena query saves its output as a CSV in an S3 bucket (which we configure in Terraform).

---

## 🔄 How AWS Connects to Later Modules

```
Module 1 (Docker & Terraform)
    ↓ provisions
Amazon S3 Bucket + AWS Glue Catalog + Athena
    ↓
Module 2 (Workflow Orchestration - Kestra)
    ↓ loads automated daily data into
s3://my-taxi-data-lake/raw/
    ↓
Module 3 & 4 (Data Warehouse & dbt)
    ↓ queries and transforms models using
Amazon Athena (via dbt-athena) or Amazon Redshift
    ↓
Module 5 (Distributed Processing - Spark)
    ↓ reads distributed data from
s3a://my-taxi-data-lake/raw/*.parquet
```

---

*Previous: [Topic 5 - SQL Refresher](05-sql-refresher.md) | Next: [Topic 7 - Terraform (AWS) →](07-terraform-concepts.md)*
