# 🚀 AutoWala - Complete Step-by-Step Deployment Guide

## Part 1: Upload to GitHub (10 minutes)

### Step 1.1: Create GitHub Repository

1. **Go to GitHub:**
   - Open browser: https://github.com
   - Login to your account

2. **Create New Repository:**
   - Click the `+` icon (top right) → "New repository"
   - Repository name: `autowala`
   - Description: `AutoWala - Smart Auto-Rickshaw Discovery Platform`
   - Choose: `Private` (recommended) or `Public`
   - **DO NOT** check "Initialize with README" (we already have files)
   - Click `Create repository`

3. **Copy the Repository URL:**
   - You'll see: `https://github.com/YOUR_USERNAME/autowala.git`
   - Keep this page open

### Step 1.2: Initialize Git in Your Project

Open terminal in your project directory (`e:\AutoWala`):

```bash
# 1. Initialize git (if not already done)
git init

# 2. Add all files
git add .

# 3. Create first commit
git commit -m "Initial commit - AutoWala production-ready code"

# 4. Rename branch to main (if needed)
git branch -M main

# 5. Add your GitHub repository as remote
git remote add origin https://github.com/YOUR_USERNAME/autowala.git

# 6. Push to GitHub
git push -u origin main
```

**Replace `YOUR_USERNAME` with your actual GitHub username!**

### Step 1.3: Verify Upload

1. Refresh your GitHub repository page
2. You should see all your files uploaded
3. Check that these folders exist:
   - `autowala-backend/`
   - `autowala-admin/`
   - `autowala_user/`
   - `autowala_rider/`
   - `infrastructure/`
   - `scripts/`

✅ **GitHub Upload Complete!**

---

## Part 2: Setup GitHub Secrets for CI/CD (5 minutes)

### Step 2.1: Add AWS Credentials to GitHub

1. **In your GitHub repository**, click:
   - `Settings` (top menu)
   - `Secrets and variables` → `Actions` (left sidebar)
   - Click `New repository secret`

2. **Add these secrets ONE BY ONE:**

**Secret 1:**
```
Name: AWS_ACCESS_KEY_ID
Value: [Your AWS Access Key ID - get from AWS Console → IAM]
```

**Secret 2:**
```
Name: AWS_SECRET_ACCESS_KEY
Value: [Your AWS Secret Access Key]
```

**Secret 3 (Optional for notifications):**
```
Name: SLACK_WEBHOOK
Value: [Your Slack webhook URL if you have one]
```

**Secret 4 (Will add later after CloudFront is created):**
```
Name: CLOUDFRONT_DISTRIBUTION_ID
Value: [Will get this after infrastructure deployment]
```

### Step 2.2: How to Get AWS Credentials

1. **Login to AWS Console:** https://console.aws.amazon.com
2. **Navigate to IAM:**
   - Search for "IAM" in the top search bar
   - Click "IAM"
3. **Create Access Key:**
   - Click "Users" (left sidebar)
   - Click your username
   - Click "Security credentials" tab
   - Scroll to "Access keys"
   - Click "Create access key"
   - Choose "Command Line Interface (CLI)"
   - Click "Next" → "Create access key"
   - **IMPORTANT:** Download the CSV or copy both:
     - Access Key ID (starts with AKIA...)
     - Secret Access Key (only shown once!)

✅ **GitHub Secrets Configured!**

---

## Part 3: Prepare Your Computer (15 minutes)

### Step 3.1: Install Required Tools

**On Windows (use PowerShell as Administrator):**

```powershell
# Install Chocolatey (package manager) if not installed
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Install AWS CLI
choco install awscli -y

# Install Terraform
choco install terraform -y

# Install jq
choco install jq -y

# Verify Docker is running
docker --version
```

**On macOS:**
```bash
# Install Homebrew if not installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install tools
brew install awscli terraform jq

# Verify Docker is running
docker --version
```

**On Linux (Ubuntu/Debian):**
```bash
# AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Terraform
wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
sudo apt update && sudo apt install terraform

# jq
sudo apt install jq -y
```

### Step 3.2: Configure AWS CLI

```bash
# Run AWS configure
aws configure

# Enter when prompted:
AWS Access Key ID: [paste your Access Key ID]
AWS Secret Access Key: [paste your Secret Access Key]
Default region name: ap-south-1
Default output format: json

# Verify it works
aws sts get-caller-identity
```

You should see your AWS Account ID and username.

✅ **Computer Setup Complete!**

---

## Part 4: Setup Firebase & Google Maps (20 minutes)

### Step 4.1: Create Firebase Project

1. **Go to Firebase Console:** https://console.firebase.google.com
2. **Create Project:**
   - Click "Add project"
   - Project name: `autowala-production`
   - Disable Google Analytics (optional)
   - Click "Create project"

3. **Enable Realtime Database:**
   - In project, click "Build" → "Realtime Database"
   - Click "Create Database"
   - Choose location: `asia-southeast1` (Singapore - closest to India)
   - Start in "locked mode" (we'll configure rules later)
   - Click "Enable"

4. **Get Database URL:**
   - You'll see: `https://autowala-production-default-rtdb.asia-southeast1.firebasedatabase.app`
   - **Copy this URL** - you'll need it

5. **Get Web API Key:**
   - Click ⚙️ (Settings) → "Project settings"
   - Scroll to "Your apps"
   - Click "Web" icon (`</>`)
   - Register app name: "AutoWala Web"
   - Copy the `apiKey` value (starts with `AIza...`)

6. **Download Service Account:**
   - Still in Project Settings
   - Click "Service accounts" tab
   - Click "Generate new private key"
   - Click "Generate key"
   - Save file as `firebase-service-account.json`
   - **Move this file to:** `e:\AutoWala\firebase-service-account.json`

### Step 4.2: Setup Google Maps API

1. **Go to Google Cloud Console:** https://console.cloud.google.com
2. **Create Project:**
   - Click project dropdown (top) → "New Project"
   - Project name: `autowala-maps`
   - Click "Create"

3. **Enable APIs:**
   - Go to "APIs & Services" → "Library"
   - Search and enable each of these:
     - ✅ Maps SDK for Android
     - ✅ Maps SDK for iOS
     - ✅ Places API
     - ✅ Directions API
     - ✅ Distance Matrix API
     - ✅ Geocoding API

4. **Create API Keys (3 keys needed):**

   **Key 1 - Backend/Web Key:**
   - Go to "APIs & Services" → "Credentials"
   - Click "Create Credentials" → "API key"
   - Copy the key
   - Click "Restrict Key"
   - Name: `AutoWala Backend`
   - API restrictions: Select "Restrict key"
     - Check: Places API, Directions API, Distance Matrix API, Geocoding API
   - Click "Save"

   **Key 2 - Android Key:**
   - Click "Create Credentials" → "API key"
   - Copy the key
   - Click "Restrict Key"
   - Name: `AutoWala Android`
   - Application restrictions: Select "Android apps"
   - Click "Add an item"
   - Package name: `com.autowala.user` (for user app)
   - SHA-1: (leave blank for now, add later from Android Studio)
   - API restrictions: Maps SDK for Android, Places API
   - Click "Save"

   **Key 3 - iOS Key:**
   - Click "Create Credentials" → "API key"
   - Copy the key
   - Click "Restrict Key"
   - Name: `AutoWala iOS`
   - Application restrictions: Select "iOS apps"
   - Bundle ID: `com.autowala.user`
   - API restrictions: Maps SDK for iOS, Places API
   - Click "Save"

5. **Enable Billing:**
   - Go to "Billing" (left menu)
   - Link a payment method
   - **Note:** Google Maps has $200 free credit per month

✅ **Firebase & Google Maps Setup Complete!**

---

## Part 5: Configure Environment File (10 minutes)

### Step 5.1: Create Production Environment File

```bash
# Navigate to project directory
cd e:\AutoWala

# Copy template
cp .env.example .env.production
```

### Step 5.2: Fill in ALL Values

Open `.env.production` in your editor and fill in:

```bash
# ========================================
# AWS Configuration
# ========================================
AWS_REGION=ap-south-1
AWS_ACCOUNT_ID=123456789012                    # ← Your AWS Account ID (12 digits)
AWS_ACCESS_KEY_ID=AKIAIOSFODNN7EXAMPLE         # ← Your AWS Access Key
AWS_SECRET_ACCESS_KEY=wJalrXUtn...             # ← Your AWS Secret Key

# ========================================
# Domain Configuration
# ========================================
DOMAIN_NAME=autowala.com                        # ← YOUR domain (change this!)
API_DOMAIN=api.autowala.com                     # ← YOUR domain
ADMIN_DOMAIN=admin.autowala.com                 # ← YOUR domain

# ========================================
# Firebase Configuration
# ========================================
FIREBASE_PROJECT_ID=autowala-production         # ← From Firebase console
FIREBASE_WEB_API_KEY=AIzaSyC...                # ← From Firebase project settings
FIREBASE_DATABASE_URL=https://autowala-production-default-rtdb.asia-southeast1.firebasedatabase.app
FIREBASE_SERVICE_ACCOUNT_PATH=./firebase-service-account.json

# ========================================
# Google Maps API
# ========================================
GOOGLE_MAPS_API_KEY=AIzaSyB...                 # ← Backend/Web key
GOOGLE_MAPS_ANDROID_KEY=AIzaSyA...             # ← Android key
GOOGLE_MAPS_IOS_KEY=AIzaSyD...                 # ← iOS key

# ========================================
# Slack Notifications (Optional)
# ========================================
SLACK_WEBHOOK=https://hooks.slack.com/...       # ← Optional

# ========================================
# Environment
# ========================================
ENVIRONMENT=production
```

### Step 5.3: Get Your AWS Account ID

```bash
# Run this command:
aws sts get-caller-identity --query Account --output text
```

Copy the number and paste it as `AWS_ACCOUNT_ID`.

✅ **Environment Configured!**

---

## Part 6: Deploy Infrastructure to AWS (60 minutes)

### Step 6.1: Validate Prerequisites

```bash
cd e:\AutoWala

# Make scripts executable
chmod +x scripts/*.sh

# Run validation
./scripts/validate-prerequisites.sh
```

**Fix any errors before proceeding!**

### Step 6.2: Deploy Infrastructure

```bash
# Run the setup script
./scripts/setup-aws-infrastructure.sh
```

**What this does (automatically):**
1. ✅ Creates ECR repositories for Docker images
2. ✅ Creates S3 bucket for Terraform state
3. ✅ Initializes Terraform
4. ✅ Creates VPC with subnets
5. ✅ Creates RDS PostgreSQL database
6. ✅ Creates ElastiCache Redis
7. ✅ Creates Application Load Balancer
8. ✅ Creates ECS Cluster
9. ✅ Creates CloudWatch logs and alarms
10. ✅ Creates SSL certificates

**This takes 30-45 minutes. Go get coffee! ☕**

### Step 6.3: Save Infrastructure Outputs

After Terraform completes, save the outputs:

```bash
cd infrastructure/terraform

# Save all outputs to a file
terraform output > ../../infrastructure-outputs.txt

# View important values
terraform output vpc_id
terraform output rds_endpoint
terraform output redis_endpoint
terraform output load_balancer_dns
```

**Copy these values - you'll need them!**

✅ **Infrastructure Deployed!**

---

## Part 7: Configure Database on AWS (15 minutes)

### Step 7.1: Get Database Password

The password is stored in AWS Secrets Manager:

```bash
# Get the password
aws secretsmanager get-secret-value \
  --secret-id autowala-cluster-master-password \
  --region ap-south-1 \
  --query SecretString \
  --output text | jq -r .password
```

**Copy this password!**

### Step 7.2: Get Database Endpoint

```bash
# Get RDS endpoint
aws rds describe-db-clusters \
  --db-cluster-identifier autowala-cluster \
  --region ap-south-1 \
  --query 'DBClusters[0].Endpoint' \
  --output text
```

**Copy this endpoint!** (looks like: `autowala-cluster.cluster-xxxxx.ap-south-1.rds.amazonaws.com`)

### Step 7.3: Install PostgreSQL Client

**On Windows:**
```bash
choco install postgresql -y
```

**On macOS:**
```bash
brew install postgresql
```

**On Linux:**
```bash
sudo apt install postgresql-client -y
```

### Step 7.4: Connect and Enable PostGIS

```bash
# Connect to database (replace with your values)
PGPASSWORD='YOUR_PASSWORD_FROM_STEP_7.1' psql \
  -h YOUR_ENDPOINT_FROM_STEP_7.2 \
  -U autowala_admin \
  -d autowala
```

Once connected, run these SQL commands:

```sql
-- Enable PostGIS extension
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;

-- Verify it worked
SELECT PostGIS_version();

-- You should see version number like "3.4.0"

-- Exit
\q
```

✅ **Database Configured!**

---

## Part 8: Upload Secrets to AWS (5 minutes)

### Step 8.1: Upload Firebase Service Account

```bash
cd e:\AutoWala

# Upload Firebase config
aws secretsmanager create-secret \
  --name autowala/firebase-config \
  --description "Firebase service account for AutoWala" \
  --secret-string file://firebase-service-account.json \
  --region ap-south-1
```

If it says secret already exists:
```bash
aws secretsmanager update-secret \
  --secret-id autowala/firebase-config \
  --secret-string file://firebase-service-account.json \
  --region ap-south-1
```

### Step 8.2: Upload Google Maps API Key

```bash
# Load your environment file
source .env.production

# Upload Google Maps key
aws secretsmanager create-secret \
  --name autowala/google-maps-key \
  --description "Google Maps API key" \
  --secret-string "$GOOGLE_MAPS_API_KEY" \
  --region ap-south-1
```

If it exists:
```bash
aws secretsmanager update-secret \
  --secret-id autowala/google-maps-key \
  --secret-string "$GOOGLE_MAPS_API_KEY" \
  --region ap-south-1
```

✅ **Secrets Uploaded!**

---

## Part 9: Build and Deploy Applications (30 minutes)

### Step 9.1: Login to ECR (Container Registry)

```bash
# Get your AWS account ID
export AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
export AWS_REGION=ap-south-1

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin \
  $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com
```

You should see: `Login Succeeded`

### Step 9.2: Build and Push Backend API

```bash
cd e:\AutoWala\autowala-backend

# Build Docker image
docker build -t $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/autowala-api:latest .

# Push to ECR
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/autowala-api:latest

cd ..
```

**This takes 5-10 minutes.**

### Step 9.3: Build and Push Admin Panel

```bash
cd e:\AutoWala\autowala-admin

# Build Docker image
docker build -t $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/autowala-admin:latest .

# Push to ECR
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/autowala-admin:latest

cd ..
```

**This takes 5-10 minutes.**

### Step 9.4: Deploy to ECS

```bash
# Deploy API service
aws ecs update-service \
  --cluster autowala-cluster \
  --service autowala-api \
  --force-new-deployment \
  --region ap-south-1

# Deploy Admin service
aws ecs update-service \
  --cluster autowala-cluster \
  --service autowala-admin \
  --force-new-deployment \
  --region ap-south-1
```

### Step 9.5: Wait for Deployment

```bash
# This waits until services are running
aws ecs wait services-stable \
  --cluster autowala-cluster \
  --services autowala-api autowala-admin \
  --region ap-south-1
```

**This takes 5-10 minutes. Services are starting...**

✅ **Applications Deployed!**

---

## Part 10: Run Database Migrations (5 minutes)

### Step 10.1: Get Running Task

```bash
# Get the task ARN
TASK_ARN=$(aws ecs list-tasks \
  --cluster autowala-cluster \
  --service autowala-api \
  --region ap-south-1 \
  --query 'taskArns[0]' \
  --output text)

echo "Task ARN: $TASK_ARN"
```

### Step 10.2: Run Migrations

```bash
# Run migrations
aws ecs execute-command \
  --cluster autowala-cluster \
  --task $TASK_ARN \
  --container autowala-api \
  --command "php artisan migrate --force" \
  --interactive \
  --region ap-south-1
```

**Note:** If ECS Exec is not enabled, you can run migrations after first deployment via GitHub Actions, or enable it and retry.

✅ **Database Migrated!**

---

## Part 11: Configure DNS (30 minutes)

### Step 11.1: Get Route53 Nameservers

```bash
# Get hosted zone ID
ZONE_ID=$(aws route53 list-hosted-zones \
  --query "HostedZones[?Name=='autowala.com.'].Id" \
  --output text | cut -d'/' -f3)

# Get nameservers
aws route53 get-hosted-zone --id $ZONE_ID \
  --query 'DelegationSet.NameServers' \
  --output table
```

You'll see 4 nameservers like:
```
ns-1234.awsdns-12.org
ns-5678.awsdns-34.com
ns-91.awsdns-56.net
ns-1011.awsdns-78.co.uk
```

### Step 11.2: Update Domain Nameservers

**Go to your domain registrar** (GoDaddy, Namecheap, etc.):

1. Login to your domain registrar
2. Find "DNS Settings" or "Nameservers"
3. Select "Custom Nameservers"
4. Enter all 4 nameservers from above
5. Save changes

**DNS propagation takes 5-30 minutes (sometimes up to 48 hours)**

### Step 11.3: Verify DNS (after 30 minutes)

```bash
# Check if DNS is propagated
nslookup api.autowala.com
nslookup admin.autowala.com
```

✅ **DNS Configured!**

---

## Part 12: Test Your Deployment (10 minutes)

### Step 12.1: Check Service Status

```bash
# Run status check
./scripts/check-status.sh
```

### Step 12.2: Test API Endpoint

```bash
# Test health endpoint
curl https://api.autowala.com/api/health

# Should return: {"status":"healthy"}
```

### Step 12.3: Test Admin Panel

Open in browser:
```
https://admin.autowala.com
```

You should see the admin login page.

### Step 12.4: View Logs

```bash
# View API logs
aws logs tail /ecs/autowala-app --follow --region ap-south-1

# Stop with Ctrl+C
```

✅ **Deployment Complete!**

---

## Part 13: Configure Mobile Apps (15 minutes)

### Step 13.1: Update User App Configuration

Edit `autowala_user/lib/config/app_config.dart`:

```dart
class AppConfig {
  // Replace with YOUR domain
  static const String apiBaseUrl = 'https://api.autowala.com';
  static const String environment = 'production';

  // Firebase - replace with YOUR values
  static const String firebaseDatabaseUrl =
    'https://autowala-production-default-rtdb.asia-southeast1.firebasedatabase.app';

  // Google Maps - YOUR Android key
  static const String googleMapsApiKey = 'AIzaSy...';
}
```

### Step 13.2: Update iOS Configuration

Edit `autowala_user/ios/Runner/AppDelegate.swift`:

Add your iOS Google Maps key:
```swift
GMSServices.provideAPIKey("YOUR_IOS_GOOGLE_MAPS_KEY")
```

### Step 13.3: Update Android Configuration

Edit `autowala_user/android/app/src/main/AndroidManifest.xml`:

Add your Android Google Maps key:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ANDROID_GOOGLE_MAPS_KEY"/>
```

### Step 13.4: Repeat for Rider App

Do the same for `autowala_rider/` folder.

### Step 13.5: Build Apps

```bash
# Build User App
cd autowala_user
flutter pub get
flutter build apk --release

# APK will be at: build/app/outputs/flutter-apk/app-release.apk

# Build Rider App
cd ../autowala_rider
flutter pub get
flutter build apk --release
```

✅ **Mobile Apps Built!**

---

## Part 14: Enable Automatic Deployments (5 minutes)

### Step 14.1: Push Changes to GitHub

```bash
cd e:\AutoWala

# Add all changes
git add .

# Commit
git commit -m "Configure production environment and mobile apps"

# Push
git push origin main
```

### Step 14.2: Monitor GitHub Actions

1. Go to your GitHub repository
2. Click "Actions" tab
3. You'll see workflows running:
   - `Deploy AutoWala API to Production`
   - `Deploy AutoWala Admin Panel to Production`

4. Click on a workflow to see progress
5. It should complete in 10-15 minutes

**From now on, every push to main will automatically deploy!**

✅ **CI/CD Enabled!**

---

## Summary Checklist

### ✅ Completed Steps:

- [x] Created GitHub repository
- [x] Uploaded code to GitHub
- [x] Added GitHub secrets
- [x] Installed required tools
- [x] Configured AWS CLI
- [x] Created Firebase project
- [x] Created Google Maps API keys
- [x] Created .env.production file
- [x] Deployed AWS infrastructure (Terraform)
- [x] Configured database with PostGIS
- [x] Uploaded secrets to AWS
- [x] Built Docker images
- [x] Deployed to ECS
- [x] Ran database migrations
- [x] Configured DNS
- [x] Tested deployment
- [x] Configured mobile apps
- [x] Enabled CI/CD

---

## Next Steps

### 1. Monitor Your Application
```bash
# Check status anytime
./scripts/check-status.sh

# View logs
aws logs tail /ecs/autowala-app --follow --region ap-south-1
```

### 2. Create First Admin User

SSH into a running container and create admin:
```bash
# Get task ARN
TASK_ARN=$(aws ecs list-tasks --cluster autowala-cluster --service autowala-api --query 'taskArns[0]' --output text --region ap-south-1)

# Create admin user
aws ecs execute-command \
  --cluster autowala-cluster \
  --task $TASK_ARN \
  --container autowala-api \
  --command "php artisan tinker --execute='User::create([\"name\"=>\"Admin\",\"email\"=>\"admin@autowala.com\",\"password\"=>bcrypt(\"password123\")])'" \
  --interactive \
  --region ap-south-1
```

### 3. Test Mobile Apps

Install the APK on your Android phone:
```bash
# The APK is at:
autowala_user/build/app/outputs/flutter-apk/app-release.apk
```

### 4. Monitor Costs

View AWS costs:
```bash
aws ce get-cost-and-usage \
  --time-period Start=$(date -d "1 month ago" +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --region us-east-1
```

---

## Troubleshooting

### If Deployment Fails:

```bash
# Check ECS service events
aws ecs describe-services \
  --cluster autowala-cluster \
  --services autowala-api \
  --region ap-south-1 \
  --query 'services[0].events[0:5]'

# Check logs for errors
aws logs tail /ecs/autowala-app \
  --follow \
  --filter-pattern "ERROR" \
  --region ap-south-1
```

### If DNS Not Working:

Wait 30-60 minutes for propagation, then check:
```bash
dig api.autowala.com
```

### If Database Connection Fails:

Check security groups allow ECS to connect to RDS.

---

## 🎉 Congratulations!

Your AutoWala platform is now live on AWS!

- **API:** https://api.autowala.com
- **Admin:** https://admin.autowala.com
- **AWS Console:** https://ap-south-1.console.aws.amazon.com/ecs/v2/clusters/autowala-cluster

---

**Need Help?**
- Email: vaibhavka49@gmail.com
- Emergency: +91-7905801644

**Monthly Cost:** $560-1,110 (optimize with Reserved Instances)
