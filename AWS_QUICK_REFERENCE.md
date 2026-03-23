# AutoWala - AWS Quick Reference Guide

## Common AWS Commands

### 1. ECS Operations

#### View Running Services
```bash
aws ecs list-services --cluster autowala-cluster --region ap-south-1
```

#### Check Service Status
```bash
aws ecs describe-services \
  --cluster autowala-cluster \
  --services autowala-api autowala-admin \
  --region ap-south-1 \
  --query 'services[].[serviceName, status, runningCount, desiredCount]' \
  --output table
```

#### View Running Tasks
```bash
aws ecs list-tasks \
  --cluster autowala-cluster \
  --service-name autowala-api \
  --region ap-south-1
```

#### Get Task Details
```bash
TASK_ARN=$(aws ecs list-tasks --cluster autowala-cluster --service-name autowala-api --region ap-south-1 --query 'taskArns[0]' --output text)

aws ecs describe-tasks \
  --cluster autowala-cluster \
  --tasks $TASK_ARN \
  --region ap-south-1
```

#### Execute Command in Running Container
```bash
aws ecs execute-command \
  --cluster autowala-cluster \
  --task $TASK_ARN \
  --container autowala-api \
  --command "/bin/bash" \
  --interactive \
  --region ap-south-1
```

#### Restart Service (Force New Deployment)
```bash
aws ecs update-service \
  --cluster autowala-cluster \
  --service autowala-api \
  --force-new-deployment \
  --region ap-south-1
```

#### Scale Service
```bash
# Scale up to 5 tasks
aws ecs update-service \
  --cluster autowala-cluster \
  --service autowala-api \
  --desired-count 5 \
  --region ap-south-1

# Scale down to 2 tasks
aws ecs update-service \
  --cluster autowala-cluster \
  --service autowala-api \
  --desired-count 2 \
  --region ap-south-1
```

### 2. CloudWatch Logs

#### View Recent Logs
```bash
# Last 10 minutes
aws logs tail /ecs/autowala-app \
  --follow \
  --since 10m \
  --region ap-south-1
```

#### Search Logs
```bash
# Search for errors
aws logs filter-log-events \
  --log-group-name /ecs/autowala-app \
  --filter-pattern "ERROR" \
  --start-time $(date -u -d '1 hour ago' +%s)000 \
  --region ap-south-1
```

#### Export Logs to S3
```bash
aws logs create-export-task \
  --log-group-name /ecs/autowala-app \
  --from $(date -u -d '1 day ago' +%s)000 \
  --to $(date -u +%s)000 \
  --destination autowala-logs-backup \
  --destination-prefix logs/$(date +%Y-%m-%d) \
  --region ap-south-1
```

### 3. RDS Operations

#### Check Cluster Status
```bash
aws rds describe-db-clusters \
  --db-cluster-identifier autowala-cluster \
  --region ap-south-1 \
  --query 'DBClusters[0].[Status, Endpoint, ReaderEndpoint]' \
  --output table
```

#### Create Manual Snapshot
```bash
aws rds create-db-cluster-snapshot \
  --db-cluster-identifier autowala-cluster \
  --db-cluster-snapshot-identifier autowala-manual-$(date +%Y%m%d-%H%M%S) \
  --region ap-south-1
```

#### List Snapshots
```bash
aws rds describe-db-cluster-snapshots \
  --db-cluster-identifier autowala-cluster \
  --region ap-south-1 \
  --query 'DBClusterSnapshots[].[DBClusterSnapshotIdentifier, SnapshotCreateTime, Status]' \
  --output table
```

#### Restore from Snapshot
```bash
aws rds restore-db-cluster-from-snapshot \
  --db-cluster-identifier autowala-cluster-restored \
  --snapshot-identifier autowala-snapshot-20260323 \
  --engine aurora-postgresql \
  --region ap-south-1
```

#### Connect to Database
```bash
# Get DB endpoint
RDS_ENDPOINT=$(aws rds describe-db-clusters \
  --db-cluster-identifier autowala-cluster \
  --query 'DBClusters[0].Endpoint' \
  --output text \
  --region ap-south-1)

# Get password from Secrets Manager
DB_PASSWORD=$(aws secretsmanager get-secret-value \
  --secret-id autowala-cluster-master-password \
  --query SecretString \
  --output text \
  --region ap-south-1 | jq -r .password)

# Connect
PGPASSWORD=$DB_PASSWORD psql -h $RDS_ENDPOINT -U autowala_admin -d autowala
```

### 4. ElastiCache Redis

#### Check Cluster Status
```bash
aws elasticache describe-replication-groups \
  --replication-group-id autowala-redis \
  --region ap-south-1 \
  --query 'ReplicationGroups[0].[Status, ConfigurationEndpoint.Address]' \
  --output table
```

#### Get Redis Metrics
```bash
aws cloudwatch get-metric-statistics \
  --namespace AWS/ElastiCache \
  --metric-name CPUUtilization \
  --dimensions Name=CacheClusterId,Value=autowala-redis-001 \
  --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average \
  --region ap-south-1
```

#### Connect to Redis (via EC2 jumpbox)
```bash
# First, create a jumpbox in the same VPC
REDIS_ENDPOINT=$(aws elasticache describe-replication-groups \
  --replication-group-id autowala-redis \
  --query 'ReplicationGroups[0].ConfigurationEndpoint.Address' \
  --output text \
  --region ap-south-1)

# SSH to jumpbox, then:
redis-cli -h $REDIS_ENDPOINT -p 6379 --tls
```

### 5. S3 Operations

#### List Buckets
```bash
aws s3 ls
```

#### Sync Files to S3
```bash
aws s3 sync ./local-folder s3://autowala-app-storage/path/ --region ap-south-1
```

#### Download Files from S3
```bash
aws s3 cp s3://autowala-app-storage/file.txt ./local-file.txt --region ap-south-1
```

#### Set Lifecycle Policy
```bash
aws s3api put-bucket-lifecycle-configuration \
  --bucket autowala-app-storage \
  --lifecycle-configuration file://s3-lifecycle.json \
  --region ap-south-1
```

**s3-lifecycle.json:**
```json
{
  "Rules": [
    {
      "Id": "Move old KYC docs to Glacier",
      "Status": "Enabled",
      "Prefix": "kyc/",
      "Transitions": [
        {
          "Days": 90,
          "StorageClass": "GLACIER"
        }
      ]
    }
  ]
}
```

### 6. Secrets Manager

#### Get Secret Value
```bash
aws secretsmanager get-secret-value \
  --secret-id autowala/firebase-config \
  --query SecretString \
  --output text \
  --region ap-south-1
```

#### Update Secret
```bash
aws secretsmanager update-secret \
  --secret-id autowala/google-maps-key \
  --secret-string "new-api-key-here" \
  --region ap-south-1
```

#### List All Secrets
```bash
aws secretsmanager list-secrets \
  --region ap-south-1 \
  --query 'SecretList[].[Name, LastChangedDate]' \
  --output table
```

### 7. CloudWatch Alarms

#### List Alarms
```bash
aws cloudwatch describe-alarms \
  --alarm-names autowala-api-high-cpu autowala-api-high-memory \
  --region ap-south-1
```

#### Set Alarm State (for testing)
```bash
aws cloudwatch set-alarm-state \
  --alarm-name autowala-api-high-cpu \
  --state-value ALARM \
  --state-reason "Testing alert system" \
  --region ap-south-1
```

#### Get Alarm History
```bash
aws cloudwatch describe-alarm-history \
  --alarm-name autowala-api-high-cpu \
  --max-records 10 \
  --region ap-south-1
```

### 8. Load Balancer

#### Check Target Health
```bash
# Get target group ARN
TG_ARN=$(aws elbv2 describe-target-groups \
  --names autowala-api-tg \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text \
  --region ap-south-1)

# Check health
aws elbv2 describe-target-health \
  --target-group-arn $TG_ARN \
  --region ap-south-1 \
  --query 'TargetHealthDescriptions[].[Target.Id, TargetHealth.State, TargetHealth.Reason]' \
  --output table
```

#### Get Load Balancer DNS
```bash
aws elbv2 describe-load-balancers \
  --names autowala-alb \
  --query 'LoadBalancers[0].DNSName' \
  --output text \
  --region ap-south-1
```

### 9. ECR (Container Registry)

#### List Images
```bash
aws ecr list-images \
  --repository-name autowala-api \
  --region ap-south-1
```

#### Delete Old Images
```bash
# Delete images older than 30 days (lifecycle policy should handle this)
aws ecr batch-delete-image \
  --repository-name autowala-api \
  --image-ids imageTag=old-tag \
  --region ap-south-1
```

#### Get Image Details
```bash
aws ecr describe-images \
  --repository-name autowala-api \
  --region ap-south-1 \
  --query 'sort_by(imageDetails,& imagePushedAt)[-1]' \
  --output table
```

### 10. Cost & Billing

#### Get Current Month Cost
```bash
START_DATE=$(date -d "$(date +%Y-%m-01)" +%Y-%m-%d)
END_DATE=$(date +%Y-%m-%d)

aws ce get-cost-and-usage \
  --time-period Start=$START_DATE,End=$END_DATE \
  --granularity MONTHLY \
  --metrics BlendedCost UnblendedCost \
  --region us-east-1
```

#### Cost by Service
```bash
aws ce get-cost-and-usage \
  --time-period Start=$START_DATE,End=$END_DATE \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --group-by Type=DIMENSION,Key=SERVICE \
  --region us-east-1 \
  --query 'ResultsByTime[0].Groups' \
  --output table
```

---

## Terraform Commands

### Initialize Terraform
```bash
cd infrastructure/terraform
terraform init
```

### Plan Changes
```bash
terraform plan -out=tfplan
```

### Apply Changes
```bash
terraform apply tfplan
```

### Show Current State
```bash
terraform show
```

### View Outputs
```bash
terraform output
```

### Import Existing Resource
```bash
terraform import aws_instance.example i-1234567890abcdef0
```

### Destroy Infrastructure (DANGEROUS!)
```bash
# Only for development/testing
terraform destroy
```

### Refresh State
```bash
terraform refresh
```

---

## Database Management

### Run Migrations
```bash
# Via ECS exec
TASK_ARN=$(aws ecs list-tasks --cluster autowala-cluster --service-name autowala-api --query 'taskArns[0]' --output text --region ap-south-1)

aws ecs execute-command \
  --cluster autowala-cluster \
  --task $TASK_ARN \
  --container autowala-api \
  --command "php artisan migrate --force" \
  --interactive \
  --region ap-south-1
```

### Rollback Migration
```bash
aws ecs execute-command \
  --cluster autowala-cluster \
  --task $TASK_ARN \
  --container autowala-api \
  --command "php artisan migrate:rollback --step=1 --force" \
  --interactive \
  --region ap-south-1
```

### Run Database Seeder
```bash
aws ecs execute-command \
  --cluster autowala-cluster \
  --task $TASK_ARN \
  --container autowala-api \
  --command "php artisan db:seed --class=ProductionSeeder --force" \
  --interactive \
  --region ap-south-1
```

### Clear Application Cache
```bash
aws ecs execute-command \
  --cluster autowala-cluster \
  --task $TASK_ARN \
  --container autowala-api \
  --command "php artisan cache:clear && php artisan config:clear && php artisan route:clear" \
  --interactive \
  --region ap-south-1
```

### Optimize Application
```bash
aws ecs execute-command \
  --cluster autowala-cluster \
  --task $TASK_ARN \
  --container autowala-api \
  --command "php artisan optimize" \
  --interactive \
  --region ap-south-1
```

---

## Monitoring Scripts

### Quick Health Check
```bash
#!/bin/bash
echo "=== AutoWala Health Check ==="

echo "\n📊 ECS Services:"
aws ecs describe-services \
  --cluster autowala-cluster \
  --services autowala-api autowala-admin \
  --region ap-south-1 \
  --query 'services[].[serviceName, status, runningCount, desiredCount]' \
  --output table

echo "\n🗄️ Database Status:"
aws rds describe-db-clusters \
  --db-cluster-identifier autowala-cluster \
  --region ap-south-1 \
  --query 'DBClusters[0].[Status, Endpoint]' \
  --output table

echo "\n🔴 Redis Status:"
aws elasticache describe-replication-groups \
  --replication-group-id autowala-redis \
  --region ap-south-1 \
  --query 'ReplicationGroups[0].[Status, ConfigurationEndpoint.Address]' \
  --output table

echo "\n🌐 API Health:"
curl -f https://api.autowala.com/api/health && echo "✅ OK" || echo "❌ FAILED"

echo "\n🔧 Admin Health:"
curl -f https://admin.autowala.com/ -o /dev/null -w "%{http_code}\n" && echo "✅ OK" || echo "❌ FAILED"
```

### Performance Metrics
```bash
#!/bin/bash
echo "=== AutoWala Performance Metrics ==="

# API Response Time
echo "\n⏱️ API Response Time:"
curl -o /dev/null -s -w "Connect: %{time_connect}s\nTTFB: %{time_starttransfer}s\nTotal: %{time_total}s\n" https://api.autowala.com/api/health

# ECS CPU/Memory
echo "\n💻 ECS Metrics (Last 5 minutes):"
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ServiceName,Value=autowala-api Name=ClusterName,Value=autowala-cluster \
  --start-time $(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average \
  --region ap-south-1 \
  --query 'Datapoints[0].Average' \
  --output text
```

---

## Emergency Procedures

### Rollback Deployment
```bash
#!/bin/bash
# Get previous task definition
PREVIOUS_TASK=$(aws ecs describe-task-definition \
  --task-definition autowala-api \
  --query 'taskDefinition.revision' \
  --output text \
  --region ap-south-1)

ROLLBACK_TASK=$((PREVIOUS_TASK - 1))

echo "Rolling back to revision $ROLLBACK_TASK..."

# Update service with previous task definition
aws ecs update-service \
  --cluster autowala-cluster \
  --service autowala-api \
  --task-definition autowala-api:$ROLLBACK_TASK \
  --force-new-deployment \
  --region ap-south-1

echo "Rollback initiated. Monitoring stability..."
aws ecs wait services-stable \
  --cluster autowala-cluster \
  --services autowala-api \
  --region ap-south-1

echo "✅ Rollback completed!"
```

### Emergency Scale-Up
```bash
#!/bin/bash
echo "Emergency scale-up initiated..."

# Scale API service to 10 tasks
aws ecs update-service \
  --cluster autowala-cluster \
  --service autowala-api \
  --desired-count 10 \
  --region ap-south-1

# Scale Admin service to 5 tasks
aws ecs update-service \
  --cluster autowala-cluster \
  --service autowala-admin \
  --desired-count 5 \
  --region ap-south-1

echo "Services scaled up. Monitoring..."
```

### Clear All Caches
```bash
#!/bin/bash
echo "Clearing all caches..."

# Get task ARN
TASK_ARN=$(aws ecs list-tasks \
  --cluster autowala-cluster \
  --service-name autowala-api \
  --query 'taskArns[0]' \
  --output text \
  --region ap-south-1)

# Clear Laravel caches
aws ecs execute-command \
  --cluster autowala-cluster \
  --task $TASK_ARN \
  --container autowala-api \
  --command "php artisan cache:clear && php artisan config:clear && php artisan route:clear && php artisan view:clear" \
  --interactive \
  --region ap-south-1

# Clear Redis (CAREFUL!)
# Connect to Redis and run: FLUSHALL

# Clear CloudFront cache
DIST_ID=$(aws cloudfront list-distributions \
  --query "DistributionList.Items[?Comment=='AutoWala CDN Distribution'].Id" \
  --output text)

aws cloudfront create-invalidation \
  --distribution-id $DIST_ID \
  --paths "/*" \
  --region ap-south-1

echo "✅ All caches cleared!"
```

---

## Useful Aliases

Add to your `~/.bashrc` or `~/.zshrc`:

```bash
# AutoWala aliases
alias awala='aws --region ap-south-1'
alias ecs-api='aws ecs describe-services --cluster autowala-cluster --services autowala-api --region ap-south-1'
alias ecs-admin='aws ecs describe-services --cluster autowala-cluster --services autowala-admin --region ap-south-1'
alias logs-api='aws logs tail /ecs/autowala-app --follow --region ap-south-1'
alias logs-admin='aws logs tail /ecs/autowala-admin --follow --region ap-south-1'
alias health-check='curl -f https://api.autowala.com/api/health'
alias costs='aws ce get-cost-and-usage --time-period Start=$(date -d "1 month ago" +%Y-%m-%d),End=$(date +%Y-%m-%d) --granularity MONTHLY --metrics BlendedCost --region us-east-1'
```

---

## AWS Console Quick Links

- **ECS Console:** https://ap-south-1.console.aws.amazon.com/ecs/v2/clusters/autowala-cluster
- **RDS Console:** https://ap-south-1.console.aws.amazon.com/rds/home
- **CloudWatch:** https://ap-south-1.console.aws.amazon.com/cloudwatch/home
- **EC2 Load Balancers:** https://ap-south-1.console.aws.amazon.com/ec2/home#LoadBalancers
- **S3 Console:** https://s3.console.aws.amazon.com/s3/buckets/autowala-app-storage
- **Cost Explorer:** https://console.aws.amazon.com/cost-management/home#/cost-explorer

---

## Support Resources

- **AWS Support:** https://console.aws.amazon.com/support/home
- **AWS Status:** https://status.aws.amazon.com/
- **AutoWala Docs:** `/docs/`
- **Emergency Contact:** +91-7905801644

---

**Last Updated:** March 23, 2026
**Maintainer:** DevOps Team
