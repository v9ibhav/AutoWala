# AutoWala - Complete AWS Deployment Checklist

## Project Overview
AutoWala is a production-ready ride discovery platform with:
- **Backend:** Laravel 11 REST API with PostGIS support
- **Admin Panel:** React + TypeScript dashboard
- **Mobile Apps:** Flutter (User & Rider apps)
- **Infrastructure:** AWS (ECS Fargate, RDS PostgreSQL, ElastiCache Redis)

---

## Prerequisites Checklist

### 1. AWS Account Setup
- [ ] AWS Account created and verified
- [ ] AWS CLI installed and configured (`aws configure`)
- [ ] IAM user with programmatic access created
- [ ] Required IAM permissions attached:
  - EC2 Full Access
  - ECS Full Access
  - RDS Full Access
  - ElastiCache Full Access
  - VPC Full Access
  - Route53 Full Access
  - CloudFront Full Access
  - S3 Full Access
  - Secrets Manager Full Access
  - CloudWatch Full Access

### 2. Domain & DNS
- [ ] Domain registered (e.g., autowala.com)
- [ ] Domain transferred to Route53 OR nameservers updated to point to Route53
- [ ] Route53 hosted zone created

### 3. External Services Setup
#### Firebase
- [ ] Firebase project created
- [ ] Firebase Realtime Database enabled (Asia region recommended)
- [ ] Firebase service account JSON downloaded
- [ ] Firebase Cloud Messaging (FCM) enabled
- [ ] Firebase web API key obtained

#### Google Cloud Platform
- [ ] Google Cloud project created
- [ ] Google Maps Platform APIs enabled:
  - Maps SDK for Android
  - Maps SDK for iOS
  - Places API
  - Directions API
  - Distance Matrix API
  - Geocoding API
- [ ] Billing account linked
- [ ] API keys generated with restrictions:
  - Android key (restricted to app package)
  - iOS key (restricted to bundle ID)
  - Web/Backend key (restricted to IP ranges)

### 4. Local Development Tools
- [ ] Docker installed (v20.10+)
- [ ] Terraform installed (v1.0+)
- [ ] Node.js installed (v18+)
- [ ] PHP installed (v8.2+)
- [ ] Composer installed
- [ ] Flutter SDK installed (v3.16+)
- [ ] Git configured
- [ ] jq installed (for JSON processing)

---

## Phase 1: Infrastructure Setup (1-2 hours)

### Step 1.1: Configure Environment Variables
Create `.env.production` file in project root:

```bash
# AWS Configuration
AWS_REGION=ap-south-1
AWS_ACCOUNT_ID=123456789012  # Replace with your account ID

# Domain Configuration
DOMAIN_NAME=autowala.com  # Replace with your domain
API_DOMAIN=api.autowala.com
ADMIN_DOMAIN=admin.autowala.com

# Firebase Configuration
FIREBASE_PROJECT_ID=autowala-production
FIREBASE_WEB_API_KEY=AIza...  # From Firebase console
FIREBASE_DATABASE_URL=https://autowala-production-default-rtdb.asia-southeast1.firebasedatabase.app
FIREBASE_SERVICE_ACCOUNT=/path/to/firebase-service-account.json

# Google Maps API
GOOGLE_MAPS_API_KEY=AIza...  # From Google Cloud console
GOOGLE_MAPS_ANDROID_KEY=AIza...
GOOGLE_MAPS_IOS_KEY=AIza...

# Application
APP_ENV=production
APP_DEBUG=false
APP_KEY=  # Will be auto-generated

# Slack Notifications (optional)
SLACK_WEBHOOK=https://hooks.slack.com/services/...
```

### Step 1.2: Initialize AWS Infrastructure
```bash
cd /e/AutoWala

# Make scripts executable
chmod +x scripts/setup-aws-infrastructure.sh
chmod +x scripts/performance-testing.sh

# Run infrastructure setup
./scripts/setup-aws-infrastructure.sh
```

**What this script does:**
- ✅ Creates ECR repositories for Docker images
- ✅ Sets up S3 bucket for Terraform state
- ✅ Initializes Terraform
- ✅ Creates VPC with public/private/database subnets
- ✅ Deploys RDS Aurora PostgreSQL cluster with PostGIS
- ✅ Sets up ElastiCache Redis cluster
- ✅ Configures Application Load Balancer
- ✅ Creates ECS Fargate cluster
- ✅ Sets up CloudWatch logging
- ✅ Configures auto-scaling policies
- ✅ Creates SSL certificates via ACM

**Expected Duration:** 30-45 minutes

### Step 1.3: Verify Infrastructure Deployment
```bash
# Check ECS cluster
aws ecs describe-clusters --clusters autowala-cluster --region ap-south-1

# Check RDS cluster
aws rds describe-db-clusters --db-cluster-identifier autowala-cluster --region ap-south-1

# Check load balancer
aws elbv2 describe-load-balancers --names autowala-alb --region ap-south-1

# Get important outputs
cd infrastructure/terraform
terraform output
```

**Expected Outputs:**
- VPC ID
- RDS endpoint
- Redis endpoint
- Load balancer DNS
- CloudFront domain
- S3 bucket name

---

## Phase 2: Database Setup (30 minutes)

### Step 2.1: Enable PostGIS Extension
```bash
# Get RDS endpoint from Terraform output
RDS_ENDPOINT=$(cd infrastructure/terraform && terraform output -raw rds_endpoint)

# Get database password from AWS Secrets Manager
DB_PASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id autowala-cluster-master-password \
  --query SecretString --output text | jq -r .password)

# Connect to database (install psql if needed)
PGPASSWORD=$DB_PASSWORD psql -h $RDS_ENDPOINT -U autowala_admin -d autowala

# Run these commands in psql:
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;
SELECT PostGIS_version();
\q
```

### Step 2.2: Upload Service Account Credentials
```bash
# Upload Firebase service account to AWS Secrets Manager
aws secretsmanager create-secret \
  --name autowala/firebase-service-account \
  --description "Firebase service account for AutoWala" \
  --secret-string file://path/to/firebase-service-account.json \
  --region ap-south-1

# Upload Google Maps API key
aws secretsmanager create-secret \
  --name autowala/google-maps-key \
  --description "Google Maps API key" \
  --secret-string "$GOOGLE_MAPS_API_KEY" \
  --region ap-south-1
```

---

## Phase 3: Application Deployment (1 hour)

### Step 3.1: Prepare Backend Configuration Files

Create `autowala-backend/.env.production`:
```env
APP_NAME=AutoWala
APP_ENV=production
APP_DEBUG=false
APP_URL=https://api.autowala.com

DB_CONNECTION=pgsql
DB_HOST=<RDS_ENDPOINT>  # From terraform output
DB_PORT=5432
DB_DATABASE=autowala
DB_USERNAME=autowala_admin
DB_PASSWORD=  # Retrieved from Secrets Manager at runtime

REDIS_HOST=<REDIS_ENDPOINT>  # From terraform output
REDIS_PORT=6379
REDIS_PASSWORD=null

CACHE_DRIVER=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis

FIREBASE_PROJECT_ID=autowala-production
FIREBASE_DATABASE_URL=https://autowala-production-default-rtdb.asia-southeast1.firebasedatabase.app

GOOGLE_MAPS_API_KEY=  # Retrieved from Secrets Manager
```

Create required Docker config files:
```bash
# Create nginx config
mkdir -p autowala-backend/docker/nginx
cat > autowala-backend/docker/nginx/autowala.conf << 'EOF'
server {
    listen 80;
    server_name _;
    root /var/www/public;
    index index.php;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass 127.0.0.1:9000;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
EOF

# Create PHP config
mkdir -p autowala-backend/docker/php
cat > autowala-backend/docker/php/php.ini << 'EOF'
memory_limit = 256M
post_max_size = 50M
upload_max_filesize = 50M
max_execution_time = 300
date.timezone = Asia/Kolkata
EOF

# Create supervisord config
mkdir -p autowala-backend/docker/supervisord
cat > autowala-backend/docker/supervisord/supervisord.conf << 'EOF'
[supervisord]
nodaemon=true
user=autowala

[program:php-fpm]
command=/usr/local/sbin/php-fpm
autostart=true
autorestart=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0

[program:nginx]
command=/usr/sbin/nginx -g "daemon off;"
autostart=true
autorestart=true
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0

[program:queue-worker]
command=php /var/www/artisan queue:work --tries=3 --timeout=90
autostart=true
autorestart=true
numprocs=2
stdout_logfile=/dev/stdout
stdout_logfile_maxbytes=0
stderr_logfile=/dev/stderr
stderr_logfile_maxbytes=0
EOF
```

### Step 3.2: Build and Push Docker Images
```bash
# Get AWS account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=ap-south-1

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | \
  docker login --username AWS --password-stdin \
  $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com

# Build and push Backend API
cd autowala-backend
docker build -t $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/autowala-api:latest .
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/autowala-api:latest
cd ..

# Build and push Admin Panel
cd autowala-admin
# Create nginx configs first
mkdir -p docker
cat > docker/nginx.conf << 'EOF'
user autowala;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    sendfile on;
    keepalive_timeout 65;
    gzip on;
    include /etc/nginx/conf.d/*.conf;
}
EOF

cat > docker/default.conf << 'EOF'
server {
    listen 80;
    server_name _;
    root /usr/share/nginx/html;
    index index.html;

    location / {
        try_files $uri $uri/ /index.html;
    }

    location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }
}
EOF

docker build -t $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/autowala-admin:latest .
docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/autowala-admin:latest
cd ..
```

### Step 3.3: Update ECS Task Definitions
The task definitions will automatically use the latest images from ECR. Update the image URIs in `infrastructure/terraform/ecs.tf` if needed.

### Step 3.4: Deploy to ECS
```bash
# Update ECS services
aws ecs update-service \
  --cluster autowala-cluster \
  --service autowala-api \
  --force-new-deployment \
  --region ap-south-1

aws ecs update-service \
  --cluster autowala-cluster \
  --service autowala-admin \
  --force-new-deployment \
  --region ap-south-1

# Wait for services to stabilize
aws ecs wait services-stable \
  --cluster autowala-cluster \
  --services autowala-api autowala-admin \
  --region ap-south-1
```

### Step 3.5: Run Database Migrations
```bash
# Get running task ARN
TASK_ARN=$(aws ecs list-tasks \
  --cluster autowala-cluster \
  --service autowala-api \
  --region ap-south-1 \
  --query 'taskArns[0]' \
  --output text)

# Run migrations
aws ecs execute-command \
  --cluster autowala-cluster \
  --task $TASK_ARN \
  --container autowala-api \
  --command "php artisan migrate --force" \
  --interactive \
  --region ap-south-1
```

---

## Phase 4: DNS & SSL Configuration (30 minutes)

### Step 4.1: Configure Route53 DNS Records
DNS records are automatically created by Terraform, but verify:

```bash
# Check DNS records
aws route53 list-resource-record-sets \
  --hosted-zone-id $(aws route53 list-hosted-zones --query "HostedZones[?Name=='autowala.com.'].Id" --output text | cut -d'/' -f3) \
  --region ap-south-1
```

Should show:
- `api.autowala.com` → ALB
- `admin.autowala.com` → ALB

### Step 4.2: Verify SSL Certificates
```bash
# Check certificate status
aws acm list-certificates --region ap-south-1

# Certificate should show ISSUED status
```

### Step 4.3: Update Nameservers (If Not Already Done)
```bash
# Get Route53 nameservers
aws route53 get-hosted-zone \
  --id $(aws route53 list-hosted-zones --query "HostedZones[?Name=='autowala.com.'].Id" --output text | cut -d'/' -f3)
```

Update your domain registrar with these nameservers.

---

## Phase 5: GitHub Actions CI/CD Setup (15 minutes)

### Step 5.1: Add GitHub Secrets
Go to your GitHub repository → Settings → Secrets and variables → Actions

Add these secrets:
```
AWS_ACCESS_KEY_ID=<Your AWS Access Key>
AWS_SECRET_ACCESS_KEY=<Your AWS Secret Key>
SLACK_WEBHOOK=<Your Slack webhook URL>
CLOUDFRONT_DISTRIBUTION_ID=<Your CloudFront distribution ID>
```

### Step 5.2: Enable GitHub Actions
The workflows are already configured in `.github/workflows/`. They will automatically:
- Run tests on push to main
- Build Docker images
- Push to ECR
- Deploy to ECS
- Run migrations
- Notify via Slack

---

## Phase 6: Mobile App Configuration (30 minutes)

### Step 6.1: Configure Flutter User App
Update `autowala_user/lib/config/app_config.dart`:
```dart
class AppConfig {
  static const String apiBaseUrl = 'https://api.autowala.com';
  static const String environment = 'production';

  // Firebase
  static const String firebaseDatabaseUrl =
    'https://autowala-production-default-rtdb.asia-southeast1.firebasedatabase.app';

  // Google Maps
  static const String googleMapsApiKey = 'YOUR_ANDROID_KEY';
}
```

Update `autowala_user/ios/Runner/AppDelegate.swift` with iOS Maps key.

### Step 6.2: Configure Flutter Rider App
Same as above for `autowala_rider/`.

### Step 6.3: Build Mobile Apps
```bash
# User App
cd autowala_user
flutter pub get
flutter build apk --release  # For Android
flutter build ios --release  # For iOS
cd ..

# Rider App
cd autowala_rider
flutter pub get
flutter build apk --release
flutter build ios --release
cd ..
```

### Step 6.4: Publish to Stores
- **Google Play Store:** Upload APK via Play Console
- **Apple App Store:** Upload IPA via App Store Connect

---

## Phase 7: Testing & Verification (30 minutes)

### Step 7.1: Health Checks
```bash
# Test API health
curl https://api.autowala.com/api/health

# Test Admin panel
curl https://admin.autowala.com/

# Check ECS service status
aws ecs describe-services \
  --cluster autowala-cluster \
  --services autowala-api autowala-admin \
  --region ap-south-1
```

### Step 7.2: Database Connectivity
```bash
# Check database connections
aws rds describe-db-clusters \
  --db-cluster-identifier autowala-cluster \
  --region ap-south-1
```

### Step 7.3: Redis Connectivity
```bash
# Check Redis endpoint
aws elasticache describe-replication-groups \
  --replication-group-id autowala-redis \
  --region ap-south-1
```

### Step 7.4: Load Testing
```bash
# Run performance tests
./scripts/performance-testing.sh
```

---

## Phase 8: Monitoring & Alerting (15 minutes)

### Step 8.1: CloudWatch Dashboards
Dashboards are automatically created. Access them:
1. Go to AWS Console → CloudWatch → Dashboards
2. View:
   - ECS metrics (CPU, memory)
   - RDS metrics (connections, CPU)
   - ALB metrics (requests, latency)

### Step 8.2: Configure SNS Alerts
```bash
# Subscribe to alerts topic
aws sns subscribe \
  --topic-arn arn:aws:sns:ap-south-1:$AWS_ACCOUNT_ID:autowala-alerts \
  --protocol email \
  --notification-endpoint your-email@example.com \
  --region ap-south-1
```

---

## Phase 9: Production Checklist

### Security
- [ ] All secrets stored in AWS Secrets Manager
- [ ] SSL/TLS enabled on all endpoints
- [ ] Security groups configured with minimal access
- [ ] Database in private subnet
- [ ] S3 buckets have public access blocked
- [ ] IAM roles follow principle of least privilege

### Performance
- [ ] Redis caching enabled
- [ ] CloudFront CDN configured
- [ ] Database indexes created
- [ ] Auto-scaling policies configured
- [ ] Load balancer health checks passing

### Monitoring
- [ ] CloudWatch logs enabled
- [ ] CloudWatch alarms configured
- [ ] SNS notifications set up
- [ ] Slack integration working

### Backup & Recovery
- [ ] RDS automated backups enabled (7-day retention)
- [ ] RDS snapshots scheduled
- [ ] Terraform state backed up
- [ ] Disaster recovery plan documented

### Compliance
- [ ] GDPR compliance reviewed
- [ ] Data retention policies defined
- [ ] Access logs enabled
- [ ] Encryption at rest enabled

---

## Estimated Total Costs (Mumbai Region)

### Monthly Breakdown:
- **ECS Fargate:** $150-300 (2-6 tasks)
- **RDS Aurora PostgreSQL:** $200-400 (db.r6g.large, 2 instances)
- **ElastiCache Redis:** $100-200 (cache.r6g.large, 2 nodes)
- **Application Load Balancer:** $25
- **Data Transfer:** $50-100
- **CloudWatch Logs:** $20-50
- **S3 Storage:** $10-30
- **Route53:** $1
- **Secrets Manager:** $2-5

**Total Estimated:** $560-1,106 per month

### Cost Optimization Tips:
1. Use Reserved Instances for predictable workloads (30-50% savings)
2. Enable auto-scaling to reduce idle resources
3. Use S3 Intelligent-Tiering for old documents
4. Monitor and optimize data transfer costs
5. Archive old logs to S3 Glacier

---

## Troubleshooting Guide

### Issue: ECS Tasks Not Starting
```bash
# Check service events
aws ecs describe-services --cluster autowala-cluster --services autowala-api

# Check task logs
aws logs tail /ecs/autowala-app --follow
```

### Issue: Database Connection Failed
```bash
# Test connectivity from ECS task
aws ecs execute-command \
  --cluster autowala-cluster \
  --task $TASK_ARN \
  --container autowala-api \
  --command "nc -zv $RDS_ENDPOINT 5432" \
  --interactive
```

### Issue: High Latency
1. Check CloudWatch metrics for bottlenecks
2. Review slow query logs in RDS
3. Verify Redis hit rate
4. Check ALB target health

---

## Support & Maintenance

### Regular Tasks:
- **Daily:** Monitor CloudWatch dashboards
- **Weekly:** Review cost explorer, check for security updates
- **Monthly:** Database backup verification, performance review
- **Quarterly:** Disaster recovery drill, security audit

### Contacts:
- **DevOps Lead:** vaibhavka49@gmail.com
- **Emergency:** +91-7905801644

---

## Next Steps After Deployment

1. **Load Testing:** Run comprehensive load tests
2. **Security Audit:** Conduct penetration testing
3. **Documentation:** Update API docs and runbooks
4. **Training:** Train support team
5. **Marketing:** Plan launch campaign
6. **Monitoring:** Set up 24/7 monitoring rotation

---

**Deployment Status:** Ready for Production ✅
**Last Updated:** March 23, 2026
**Version:** 1.0
