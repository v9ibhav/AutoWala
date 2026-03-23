# ⚡ AutoWala - Quick Command Reference

## 🚀 Deployment

```bash
# ONE-STEP DEPLOYMENT
./scripts/deploy-autowala.sh

# Check prerequisites first
./scripts/validate-prerequisites.sh

# Check status anytime
./scripts/check-status.sh
```

## 📊 Monitoring

```bash
# View API logs (live)
aws logs tail /ecs/autowala-app --follow --region ap-south-1

# View admin logs (live)
aws logs tail /ecs/autowala-admin --follow --region ap-south-1

# Check service status
aws ecs describe-services --cluster autowala-cluster --services autowala-api --region ap-south-1

# Check health
curl https://api.yourapp.com/api/health
```

## 🔧 Common Operations

```bash
# Run migrations
TASK=$(aws ecs list-tasks --cluster autowala-cluster --service autowala-api --query 'taskArns[0]' --output text --region ap-south-1)
aws ecs execute-command --cluster autowala-cluster --task $TASK --container autowala-api --command "php artisan migrate --force" --interactive --region ap-south-1

# Clear cache
aws ecs execute-command --cluster autowala-cluster --task $TASK --container autowala-api --command "php artisan cache:clear" --interactive --region ap-south-1

# Scale up
aws ecs update-service --cluster autowala-cluster --service autowala-api --desired-count 5 --region ap-south-1

# Scale down
aws ecs update-service --cluster autowala-cluster --service autowala-api --desired-count 2 --region ap-south-1

# Force new deployment
aws ecs update-service --cluster autowala-cluster --service autowala-api --force-new-deployment --region ap-south-1
```

## 🗄️ Database

```bash
# Get RDS endpoint
aws rds describe-db-clusters --db-cluster-identifier autowala-cluster --query 'DBClusters[0].Endpoint' --output text --region ap-south-1

# Create manual snapshot
aws rds create-db-cluster-snapshot --db-cluster-identifier autowala-cluster --db-cluster-snapshot-identifier manual-$(date +%Y%m%d) --region ap-south-1

# List snapshots
aws rds describe-db-cluster-snapshots --db-cluster-identifier autowala-cluster --region ap-south-1
```

## 🐳 Docker

```bash
# Build and push API
cd autowala-backend
docker build -t $AWS_ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com/autowala-api:latest .
docker push $AWS_ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com/autowala-api:latest

# Build and push Admin
cd autowala-admin
docker build -t $AWS_ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com/autowala-admin:latest .
docker push $AWS_ACCOUNT_ID.dkr.ecr.ap-south-1.amazonaws.com/autowala-admin:latest
```

## 📱 Mobile Apps

```bash
# Build User App (Android)
cd autowala_user
flutter pub get
flutter build apk --release

# Build User App (iOS)
flutter build ios --release

# Build Rider App
cd ../autowala_rider
flutter pub get
flutter build apk --release
```

## 🚨 Emergency

```bash
# Restart service
aws ecs update-service --cluster autowala-cluster --service autowala-api --force-new-deployment --region ap-south-1

# Emergency scale up
aws ecs update-service --cluster autowala-cluster --service autowala-api --desired-count 10 --region ap-south-1

# Check for errors
aws logs tail /ecs/autowala-app --follow --filter-pattern "ERROR" --region ap-south-1
```

## 💰 Cost Check

```bash
# Current month cost
aws ce get-cost-and-usage --time-period Start=$(date -d "$(date +%Y-%m-01)" +%Y-%m-%d),End=$(date +%Y-%m-%d) --granularity MONTHLY --metrics BlendedCost --region us-east-1
```

## 🔗 Quick Links

- **AWS Console:** https://ap-south-1.console.aws.amazon.com
- **ECS:** https://ap-south-1.console.aws.amazon.com/ecs/v2/clusters/autowala-cluster
- **CloudWatch:** https://ap-south-1.console.aws.amazon.com/cloudwatch
- **RDS:** https://ap-south-1.console.aws.amazon.com/rds

---

**For detailed explanations, see:** AWS_QUICK_REFERENCE.md
