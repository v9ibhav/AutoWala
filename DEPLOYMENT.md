# AutoWala Deployment Guide
# Complete production deployment guide for the ride discovery platform

## Overview

This guide covers the complete deployment of AutoWala - a production-ready ride discovery platform with Laravel backend, React admin panel, and Flutter mobile apps. The infrastructure is deployed on AWS using containerized services with auto-scaling capabilities.

## Architecture Overview

```
┌─────────────────┐    ┌──────────────────┐    ┌─────────────────────┐
│   Flutter Apps  │    │   React Admin    │    │   Laravel API       │
│   (iOS/Android) │────│   Panel          │────│   (ECS Fargate)     │
└─────────────────┘    └──────────────────┘    └─────────────────────┘
         │                       │                         │
         └───────────────────────┼─────────────────────────┘
                                 │
    ┌────────────────────────────┼────────────────────────────┐
    │                            │                            │
    ▼                            ▼                            ▼
┌──────────────┐    ┌─────────────────────┐    ┌──────────────────────┐
│  CloudFront  │    │  Application Load   │    │    Firebase          │
│     (CDN)    │    │     Balancer        │    │   Realtime DB        │
└──────────────┘    └─────────────────────┘    └──────────────────────┘
                              │
                              ▼
                    ┌─────────────────────┐
                    │   PostgreSQL RDS    │
                    │   with PostGIS      │
                    │   (Multi-AZ)        │
                    └─────────────────────┘
                              │
                              ▼
                    ┌─────────────────────┐
                    │  ElastiCache Redis  │
                    │   (Cluster Mode)    │
                    └─────────────────────┘
```

## Prerequisites

### Required Tools
- **AWS CLI** (latest version)
- **Terraform** >= 1.0
- **Docker** >= 20.10
- **Node.js** >= 18.0
- **PHP** >= 8.2
- **Composer**
- **Flutter SDK** >= 3.16

### Required AWS Permissions
Your AWS user/role needs the following permissions:
- EC2 Full Access
- ECS Full Access
- RDS Full Access
- ElastiCache Full Access
- VPC Full Access
- Route53 Full Access
- CloudFront Full Access
- S3 Full Access
- Secrets Manager Full Access

### Environment Variables
Create a `.env.production` file with the following variables:
```bash
# AWS Configuration
AWS_REGION=ap-south-1
AWS_ACCOUNT_ID=your-aws-account-id

# Domain Configuration
DOMAIN_NAME=autowala.com
API_DOMAIN=api.autowala.com
ADMIN_DOMAIN=admin.autowala.com

# Firebase Configuration
FIREBASE_PROJECT_ID=autowala-production
FIREBASE_WEB_API_KEY=your-firebase-web-api-key
FIREBASE_DATABASE_URL=https://autowala-production-default-rtdb.asia-southeast1.firebasedatabase.app

# Google Maps API
GOOGLE_MAPS_API_KEY=your-google-maps-api-key

# External Services
SLACK_WEBHOOK=your-slack-webhook-url
```

## Step-by-Step Deployment

### 1. Infrastructure Setup

#### 1.1 Initialize AWS Infrastructure
```bash
# Clone the repository
git clone https://github.com/your-org/autowala.git
cd autowala

# Make setup script executable
chmod +x scripts/setup-aws-infrastructure.sh

# Run infrastructure setup
./scripts/setup-aws-infrastructure.sh
```

This script will:
- ✅ Create ECR repositories for Docker images
- ✅ Set up S3 bucket for Terraform state
- ✅ Initialize and apply Terraform configuration
- ✅ Create VPC, subnets, security groups
- ✅ Deploy RDS PostgreSQL with PostGIS
- ✅ Set up ElastiCache Redis cluster
- ✅ Configure Application Load Balancer
- ✅ Create ECS cluster and services

#### 1.2 Verify Infrastructure
```bash
# Check ECS cluster status
aws ecs describe-clusters --clusters autowala-cluster

# Check RDS cluster status
aws rds describe-db-clusters --db-cluster-identifier autowala-cluster

# Check load balancer status
aws elbv2 describe-load-balancers --names autowala-alb
```

### 2. Database Setup

#### 2.1 Enable PostGIS Extension
```bash
# Connect to RDS instance
psql -h your-rds-endpoint -U autowala_admin -d autowala

# Enable PostGIS extension
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;

# Verify PostGIS installation
SELECT PostGIS_version();
\q
```

#### 2.2 Run Database Migrations
```bash
cd autowala-backend

# Install dependencies
composer install --no-dev --optimize-autoloader

# Set production environment variables
export DB_HOST=your-rds-endpoint
export DB_USERNAME=autowala_admin
export DB_PASSWORD=your-rds-password
export DB_DATABASE=autowala

# Run migrations
php artisan migrate --force

# Seed initial data (optional)
php artisan db:seed --class=ProductionSeeder
```

### 3. Application Deployment

#### 3.1 Build and Push Docker Images
```bash
# Get ECR login token
aws ecr get-login-password --region ap-south-1 | docker login --username AWS --password-stdin $AWS_ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com

# Build and push API image
cd autowala-backend
docker build -t $AWS_ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com/autowala-api:latest .
docker push $AWS_ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com/autowala-api:latest

# Build and push Admin image
cd ../autowala-admin
docker build -t $AWS_ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com/autowala-admin:latest .
docker push $AWS_ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com/autowala-admin:latest
```

#### 3.2 Deploy to ECS
```bash
# Update ECS services with new images
aws ecs update-service \
    --cluster autowala-cluster \
    --service autowala-api \
    --force-new-deployment

aws ecs update-service \
    --cluster autowala-cluster \
    --service autowala-admin \
    --force-new-deployment

# Wait for deployment to complete
aws ecs wait services-stable \
    --cluster autowala-cluster \
    --services autowala-api autowala-admin
```

### 4. Domain and SSL Setup

#### 4.1 Configure Route53
```bash
# Create hosted zone (if not exists)
aws route53 create-hosted-zone \
    --name autowala.com \
    --caller-reference $(date +%s)

# Update your domain registrar with Route53 nameservers
# Get nameservers from the hosted zone
aws route53 get-hosted-zone --id YOUR_HOSTED_ZONE_ID
```

#### 4.2 SSL Certificate
SSL certificates are automatically provisioned via AWS Certificate Manager in the Terraform configuration. Verify:
```bash
aws acm list-certificates --region ap-south-1
```

### 5. CI/CD Pipeline Setup

#### 5.1 GitHub Secrets
Add the following secrets to your GitHub repository:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `SLACK_WEBHOOK`
- `CLOUDFRONT_DISTRIBUTION_ID`

#### 5.2 Enable GitHub Actions
The CI/CD pipelines are automatically configured in `.github/workflows/`. They will trigger on pushes to the main branch.

### 6. Mobile App Deployment

#### 6.1 Flutter User App
```bash
cd autowala_user

# Install dependencies
flutter pub get

# Build for production
flutter build apk --release
flutter build ios --release

# Deploy to Play Store/App Store using your preferred deployment method
```

#### 6.2 Flutter Rider App
```bash
cd autowala_rider

# Install dependencies
flutter pub get

# Build for production
flutter build apk --release
flutter build ios --release
```

## Performance Optimizations

### 1. Database Optimizations

#### PostgreSQL Configuration
```sql
-- Spatial indexes for location-based queries
CREATE INDEX CONCURRENTLY idx_riders_location ON riders USING GIST (current_location);
CREATE INDEX CONCURRENTLY idx_rides_pickup_location ON ride_logs USING GIST (pickup_location);

-- Performance indexes
CREATE INDEX CONCURRENTLY idx_riders_status ON riders (status) WHERE status = 'online';
CREATE INDEX CONCURRENTLY idx_rides_created_at ON ride_logs (created_at DESC);
```

#### Connection Pooling
```bash
# Configure PgBouncer (already included in RDS)
# Max connections: 100
# Pool size: 25
# Pool mode: transaction
```

### 2. Redis Configuration
```bash
# Memory optimization
maxmemory-policy allkeys-lru
maxmemory 2gb

# Persistence (for production)
save 900 1
save 300 10
save 60 10000
```

### 3. Application Optimizations

#### Laravel Optimizations
```bash
# Production optimizations
php artisan config:cache
php artisan route:cache
php artisan view:cache
php artisan optimize

# Queue workers (already configured in Docker)
php artisan queue:work --tries=3 --timeout=90
```

#### React Admin Panel
```javascript
// Bundle optimization already configured
// Lazy loading components
// Code splitting
// Service worker caching
```

## Monitoring and Alerts

### 1. CloudWatch Dashboards
Comprehensive monitoring is automatically configured for:
- ECS CPU and memory utilization
- RDS performance metrics
- Application Load Balancer metrics
- Custom application metrics

### 2. Alerts Configuration
Automatic alerts are configured for:
- High CPU usage (>80%)
- High memory usage (>90%)
- Database connection issues
- Application errors

### 3. Log Aggregation
All application logs are centralized in CloudWatch:
- `/ecs/autowala-api` - API application logs
- `/ecs/autowala-admin` - Admin panel logs

## Security Considerations

### 1. Network Security
- ✅ Private subnets for application servers
- ✅ Public subnets only for load balancers
- ✅ Security groups with minimal required access
- ✅ No direct internet access to databases

### 2. Application Security
- ✅ SSL/TLS encryption in transit
- ✅ Encryption at rest for RDS and S3
- ✅ Secrets managed via AWS Secrets Manager
- ✅ Regular security updates via automated deployments

### 3. API Security
- ✅ JWT token authentication
- ✅ Rate limiting (100 requests/minute)
- ✅ Input validation and sanitization
- ✅ SQL injection prevention via Eloquent ORM

## Scaling Considerations

### 1. Auto Scaling
- ✅ ECS services configured with auto scaling policies
- ✅ Target tracking scaling based on CPU/memory
- ✅ Min: 2 instances, Max: 10 instances per service

### 2. Database Scaling
- ✅ RDS Aurora cluster with read replicas
- ✅ Automatic failover for high availability
- ✅ Performance Insights enabled

### 3. Caching Strategy
- ✅ Redis for session storage and caching
- ✅ CloudFront CDN for static assets
- ✅ Application-level caching for location queries

## Troubleshooting

### Common Issues

#### 1. ECS Service Not Starting
```bash
# Check service events
aws ecs describe-services --cluster autowala-cluster --services autowala-api

# Check container logs
aws logs get-log-events \
    --log-group-name /ecs/autowala-api \
    --log-stream-name ecs/autowala-api/container-id
```

#### 2. Database Connection Issues
```bash
# Test database connectivity
telnet your-rds-endpoint 5432

# Check security groups
aws ec2 describe-security-groups --group-ids sg-your-id
```

#### 3. Load Balancer Health Checks Failing
```bash
# Check target group health
aws elbv2 describe-target-health --target-group-arn your-target-group-arn

# Test health endpoint
curl -f https://api.autowala.com/api/health
```

## Backup and Disaster Recovery

### 1. Database Backups
- ✅ Automated daily backups with 7-day retention
- ✅ Point-in-time recovery enabled
- ✅ Cross-region backup replication

### 2. Application Backups
- ✅ ECR image versioning
- ✅ S3 versioning for static assets
- ✅ Terraform state backup

### 3. Recovery Procedures
Detailed disaster recovery procedures are documented in `/docs/disaster-recovery.md`

## Cost Optimization

### Monthly Cost Estimate (Mumbai Region)
- **ECS Fargate**: ~$150-300 (2-6 containers)
- **RDS Aurora PostgreSQL**: ~$200-400 (r6g.large instances)
- **ElastiCache Redis**: ~$100-200 (cache.r6g.large)
- **Load Balancer**: ~$25
- **Data Transfer**: ~$50-100
- **Total**: ~$525-1025 per month

### Cost Optimization Tips
1. Use Reserved Instances for predictable workloads
2. Implement auto scaling to reduce idle resources
3. Monitor and optimize data transfer costs
4. Regular cleanup of unused resources

## Support and Maintenance

### 1. Regular Updates
- Security patches applied automatically
- Application updates via CI/CD pipeline
- Infrastructure updates via Terraform

### 2. Monitoring
- 24/7 monitoring via CloudWatch
- Slack notifications for critical alerts
- Regular performance reviews

### 3. Documentation
- API documentation: `/docs/api/`
- Infrastructure docs: `/docs/infrastructure/`
- Runbooks: `/docs/runbooks/`

---

## Quick Reference

### Useful Commands
```bash
# Check ECS service status
aws ecs describe-services --cluster autowala-cluster --services autowala-api

# View application logs
aws logs tail /ecs/autowala-api --follow

# Scale ECS service
aws ecs update-service --cluster autowala-cluster --service autowala-api --desired-count 4

# Database migration
kubectl exec -it deployment/api -- php artisan migrate

# Clear application cache
kubectl exec -it deployment/api -- php artisan cache:clear
```

### Emergency Contacts
- **DevOps Lead**: vaibhavka49@gmail.com
- **Architecture Team**: vaibhavka49@gmail.com
- **24/7 Support**: +91-7905801644

This deployment guide ensures a production-ready, scalable, and maintainable AutoWala platform with enterprise-grade security and monitoring.