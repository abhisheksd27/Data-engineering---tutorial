# 🚖 NYC Taxi Data Pipeline (Docker, PostgreSQL & AWS)

An end-to-end containerized data engineering project ingesting NYC Green Taxi data into PostgreSQL and managing cloud Data Lake infrastructure on Amazon Web Services (AWS) via Terraform.

---

## 🏗️ Architecture

1. **PostgreSQL 17**: Local relational database running inside Docker (`port 5432`).
2. **pgAdmin 4**: Web GUI for managing database tables and running queries (`http://localhost:8080`).
3. **taxi_ingest Container**: Custom Python container that downloads Parquet data and loads it into PostgreSQL in chunks.
4. **AWS S3**: Cloud Data Lake for raw files (provisioned via Terraform).
5. **AWS Glue Data Catalog**: Metadata catalog storing the schema for our taxi dataset.
6. **Amazon Athena**: Serverless SQL engine querying S3 directly.

---

## 🔑 Prerequisites & AWS IAM Setup

Before running Terraform, ensure your AWS IAM user has the necessary permissions:

1. **Open AWS IAM Console**:
   - Go to [AWS IAM Console](https://console.aws.amazon.com/iam) ➔ **Users** ➔ click your username (e.g. `abhishekshankar`).
2. **Attach Required Managed Policies**:
   - Click **Add permissions** ➔ **Attach policies directly**.
   - Search and attach:
     - **`AmazonS3FullAccess`** (allows Terraform to create S3 buckets and upload data)
     - **`AmazonAthenaFullAccess`** (allows managing Athena workgroups & queries)
     - **`AWSGlueConsoleFullAccess`** (allows managing Glue catalog databases)
   - *(Or via CLI)*:
     ```bash
     aws iam attach-user-policy --user-name abhishekshankar --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
     aws iam attach-user-policy --user-name abhishekshankar --policy-arn arn:aws:iam::aws:policy/AmazonAthenaFullAccess
     ```

3. **Configure AWS CLI on your machine**:
   ```bash
   aws configure
   ```

4. **Set a Globally Unique S3 Bucket Name**:
   - S3 bucket names must be unique across all AWS accounts worldwide.
   - Edit `terraform/variables.tf` and change the default `s3_bucket_name` to include your name or account digits:
     ```hcl
     variable "s3_bucket_name" {
       description = "Globally unique Amazon S3 bucket name"
       type        = string
       default     = "ny-taxi-data-lake-abhishekshankar-826674"
     }
     ```

---

## 🚀 Execution Guide (Step-by-Step)

### Step 1: Clean any existing/conflicting containers
Avoid container name collision errors:
```bash
docker rm -f postgres pgadmin taxi_ingest 2>/dev/null || true
```

### Step 2: Start the pipeline
Move into the project folder and launch containers:
```bash
cd "/Users/abhishekshankar/Data engineering - tutorial/Module_1_Docker_and_Terraform/nyc_taxi_pipeline"
docker-compose up -d
```

### Step 3: Monitor data ingestion
Watch the Python script download and ingest the November 2025 data:
```bash
docker logs -f taxi_ingest
```
*(Press `Ctrl + C` once ingestion finishes).*

### Step 4: Access pgAdmin
1. Open your browser: [http://localhost:8080](http://localhost:8080)
2. Login with credentials from `.env`:
   - **Email**: `admin@admin.com`
   - **Password**: `root`
3. Connect to the database:
   - Right-click **Servers** ➔ **Register** ➔ **Server...**
   - **General tab**: Name = `Local Postgres`
   - **Connection tab**:
     - Host: `postgres` (or `localhost` if connecting from host machine tools)
     - Port: `5432`
     - Database: `ny_taxi`
     - Username: `root`
     - Password: `root`
   - Click **Save**.

### Step 5: Ingest the Taxi Zones lookup table
Run the ingestion script from your terminal to load the lookup zones:
```bash
python scripts/ingest_data.py \
  --user root \
  --password root \
  --host localhost \
  --port 5432 \
  --db ny_taxi \
  --table_name zones \
  --url https://github.com/DataTalksClub/nyc-tlc-data/releases/download/misc/taxi_zone_lookup.csv
```

### Step 6: Run SQL Queries in pgAdmin
Open the **Query Tool** in pgAdmin on the `ny_taxi` database and paste queries from:
- `queries/analysis.sql` (Daily revenue, rush hour, etc.)
- `queries/homework.sql` (Module 1 homework answers)

### Step 7: Provision AWS Infrastructure with Terraform
```bash
cd terraform
terraform init
terraform plan
terraform apply -auto-approve
```

### Step 8: Upload raw Parquet data to Amazon S3
```bash
cd ..
python scripts/upload_to_s3.py \
  --bucket YOUR-S3-BUCKET-NAME \
  --local_file data/green_tripdata_2025-11.parquet \
  --s3_key raw/green_tripdata_2025-11.parquet \
  --region us-east-1
```

### Step 9: Query S3 Data Lake with Amazon Athena
Open the **AWS Console** ➔ **Amazon Athena** ➔ **Query Editor**, select `ny_taxi_workgroup` and run queries from:
- `queries/athena_queries.sql`

### Step 10: Teardown & Cleanup
Stop local containers and destroy AWS resources to avoid ongoing costs:
```bash
docker-compose down
cd terraform && terraform destroy -auto-approve
```

---

## 🛠️ Common Troubleshooting

| Error | Cause | Solution |
| :--- | :--- | :--- |
| `Conflict. The container name "/pgadmin" is already in use` | Old container still exists | Run `docker rm -f pgadmin postgres taxi_ingest` |
| `403 AccessDenied: s3:CreateBucket` | IAM user lacks S3 policy | Attach `AmazonS3FullAccess` to your IAM user in AWS Console |
| `BucketAlreadyExists` | Bucket name is taken globally | Change `s3_bucket_name` in `variables.tf` to a unique name |
| `gzip.BadGzipFile: Not a gzipped file` | Script treated plain CSV as gzip | `scripts/ingest_data.py` auto-detects `.parquet`, `.csv.gz`, and `.csv` |
| `attribute version is obsolete` | Docker Compose v2 syntax | Top-level `version` line has been removed from `docker-compose.yaml` |
