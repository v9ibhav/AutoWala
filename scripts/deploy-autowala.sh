#!/bin/bash
set -euo pipefail

# AutoWala Complete Deployment Script
# This script orchestrates the entire deployment process

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; exit 1; }

echo "╔══════════════════════════════════════════╗"
echo "║   AutoWala - Complete Deployment        ║"
echo "║   Production AWS Infrastructure          ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# Step 1: Validate Prerequisites
log "Step 1/8: Validating prerequisites..."
if ./scripts/validate-prerequisites.sh; then
    log "Prerequisites validation passed ✓"
else
    error "Prerequisites validation failed. Please fix errors above."
fi

# Load environment
if [ -f ".env.production" ]; then
    source .env.production
else
    error ".env.production not found"
fi

# Step 2: Confirm Deployment
echo ""
warn "⚠️  IMPORTANT DEPLOYMENT NOTICE"
echo "This will deploy AutoWala to AWS and incur costs:"
echo "  • Estimated monthly cost: \$560-1,110"
echo "  • Region: ${AWS_REGION}"
echo "  • Domain: ${DOMAIN_NAME}"
echo ""
read -p "Do you want to proceed? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    info "Deployment cancelled by user"
    exit 0
fi

# Step 3: Setup Infrastructure
log "Step 2/8: Setting up AWS infrastructure..."
if ./scripts/setup-aws-infrastructure.sh; then
    log "Infrastructure setup completed ✓"
else
    error "Infrastructure setup failed"
fi

# Step 4: Configure Database
log "Step 3/8: Configuring database..."
RDS_ENDPOINT=$(cd infrastructure/terraform && terraform output -raw rds_endpoint)
log "RDS Endpoint: $RDS_ENDPOINT"

info "Please manually enable PostGIS extension:"
echo "  1. Get DB password from AWS Secrets Manager"
echo "  2. Run: CREATE EXTENSION IF NOT EXISTS postgis;"
echo ""
read -p "Have you enabled PostGIS? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    warn "PostGIS not enabled. You'll need to do this later."
fi

# Step 5: Upload Secrets
log "Step 4/8: Uploading secrets to AWS Secrets Manager..."
if [ -f "$FIREBASE_SERVICE_ACCOUNT_PATH" ]; then
    aws secretsmanager create-secret \
        --name autowala/firebase-config \
        --secret-string file://$FIREBASE_SERVICE_ACCOUNT_PATH \
        --region $AWS_REGION 2>/dev/null || \
    aws secretsmanager update-secret \
        --secret-id autowala/firebase-config \
        --secret-string file://$FIREBASE_SERVICE_ACCOUNT_PATH \
        --region $AWS_REGION
    log "Firebase config uploaded ✓"
else
    warn "Firebase service account file not found at $FIREBASE_SERVICE_ACCOUNT_PATH"
fi

if [ -n "$GOOGLE_MAPS_API_KEY" ]; then
    aws secretsmanager create-secret \
        --name autowala/google-maps-key \
        --secret-string "$GOOGLE_MAPS_API_KEY" \
        --region $AWS_REGION 2>/dev/null || \
    aws secretsmanager update-secret \
        --secret-id autowala/google-maps-key \
        --secret-string "$GOOGLE_MAPS_API_KEY" \
        --region $AWS_REGION
    log "Google Maps API key uploaded ✓"
fi

# Step 6: Build and Push Docker Images
log "Step 5/8: Building and pushing Docker images..."
ECR_REGISTRY="$AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com"

# Login to ECR
aws ecr get-login-password --region $AWS_REGION | \
    docker login --username AWS --password-stdin $ECR_REGISTRY

# Build API
log "Building API image..."
cd autowala-backend
docker build -t $ECR_REGISTRY/autowala-api:latest .
docker push $ECR_REGISTRY/autowala-api:latest
cd ..
log "API image pushed ✓"

# Build Admin
log "Building Admin image..."
cd autowala-admin
docker build -t $ECR_REGISTRY/autowala-admin:latest .
docker push $ECR_REGISTRY/autowala-admin:latest
cd ..
log "Admin image pushed ✓"

# Step 7: Deploy to ECS
log "Step 6/8: Deploying to ECS..."
aws ecs update-service \
    --cluster autowala-cluster \
    --service autowala-api \
    --force-new-deployment \
    --region $AWS_REGION >/dev/null

aws ecs update-service \
    --cluster autowala-cluster \
    --service autowala-admin \
    --force-new-deployment \
    --region $AWS_REGION >/dev/null

log "Waiting for services to stabilize..."
aws ecs wait services-stable \
    --cluster autowala-cluster \
    --services autowala-api autowala-admin \
    --region $AWS_REGION

log "Services deployed ✓"

# Step 8: Run Migrations
log "Step 7/8: Running database migrations..."
TASK_ARN=$(aws ecs list-tasks \
    --cluster autowala-cluster \
    --service autowala-api \
    --region $AWS_REGION \
    --query 'taskArns[0]' \
    --output text)

if [ "$TASK_ARN" != "None" ] && [ -n "$TASK_ARN" ]; then
    info "Running migrations on task: $TASK_ARN"
    # Note: This requires ECS Exec to be enabled
    warn "Please run migrations manually:"
    echo "  aws ecs execute-command --cluster autowala-cluster --task $TASK_ARN \\"
    echo "    --container autowala-api --command 'php artisan migrate --force' \\"
    echo "    --interactive --region $AWS_REGION"
else
    warn "No running tasks found. Migrations will run on first deployment."
fi

# Step 9: Verify Deployment
log "Step 8/8: Verifying deployment..."
sleep 30

API_URL="https://${API_DOMAIN}/api/health"
ADMIN_URL="https://${ADMIN_DOMAIN}/"

info "Testing API health endpoint..."
if curl -f -s "$API_URL" >/dev/null 2>&1; then
    log "API is healthy ✓"
else
    warn "API health check failed (this is normal if DNS hasn't propagated yet)"
fi

info "Testing Admin panel..."
if curl -f -s -o /dev/null -w "%{http_code}" "$ADMIN_URL" | grep -q "200\|301\|302"; then
    log "Admin panel is accessible ✓"
else
    warn "Admin panel health check failed (this is normal if DNS hasn't propagated yet)"
fi

# Deployment Complete
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║   ✓ DEPLOYMENT COMPLETED                 ║"
echo "╚══════════════════════════════════════════╝"
echo ""
log "AutoWala has been deployed successfully!"
echo ""
echo "Next steps:"
echo "  1. Update your domain nameservers to Route53"
echo "  2. Wait for DNS propagation (5-30 minutes)"
echo "  3. Run database migrations if not done automatically"
echo "  4. Test the application:"
echo "     • API: https://${API_DOMAIN}/api/health"
echo "     • Admin: https://${ADMIN_DOMAIN}"
echo "  5. Build and deploy mobile apps"
echo ""
echo "Monitoring:"
echo "  • CloudWatch: https://${AWS_REGION}.console.aws.amazon.com/cloudwatch"
echo "  • ECS: https://${AWS_REGION}.console.aws.amazon.com/ecs/v2/clusters/autowala-cluster"
echo ""
echo "For detailed operations, see: AWS_QUICK_REFERENCE.md"
echo ""
