#!/bin/bash
set -euo pipefail

# AutoWala AWS Infrastructure Setup Script
# This script initializes the complete AWS infrastructure for production deployment

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
AWS_REGION=${AWS_REGION:-ap-south-1}
ENVIRONMENT=${ENVIRONMENT:-production}
PROJECT_NAME="autowala"

# Logger function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."

    # Check if required tools are installed
    command -v aws >/dev/null 2>&1 || error "AWS CLI is not installed"
    command -v terraform >/dev/null 2>&1 || error "Terraform is not installed"
    command -v jq >/dev/null 2>&1 || error "jq is not installed"

    # Check AWS credentials
    aws sts get-caller-identity >/dev/null 2>&1 || error "AWS credentials not configured"

    info "Prerequisites check passed"
}

# Create ECR repositories
create_ecr_repositories() {
    log "Creating ECR repositories..."

    repositories=("autowala-api" "autowala-admin")

    for repo in "${repositories[@]}"; do
        if aws ecr describe-repositories --repository-names "$repo" --region "$AWS_REGION" >/dev/null 2>&1; then
            info "ECR repository $repo already exists"
        else
            aws ecr create-repository \
                --repository-name "$repo" \
                --region "$AWS_REGION" \
                --image-scanning-configuration scanOnPush=true \
                --encryption-configuration encryptionType=AES256

            # Set lifecycle policy to keep only latest 10 images
            aws ecr put-lifecycle-policy \
                --repository-name "$repo" \
                --region "$AWS_REGION" \
                --lifecycle-policy-text '{
                    "rules": [
                        {
                            "rulePriority": 1,
                            "description": "Keep last 10 images",
                            "selection": {
                                "tagStatus": "any",
                                "countType": "imageCountMoreThan",
                                "countNumber": 10
                            },
                            "action": {
                                "type": "expire"
                            }
                        }
                    ]
                }'

            log "Created ECR repository: $repo"
        fi
    done
}

# Create S3 bucket for Terraform state
create_terraform_state_bucket() {
    log "Creating S3 bucket for Terraform state..."

    BUCKET_NAME="autowala-terraform-state-$(date +%s)"

    # Create bucket
    if aws s3api head-bucket --bucket "$BUCKET_NAME" 2>/dev/null; then
        info "S3 bucket $BUCKET_NAME already exists"
    else
        aws s3api create-bucket \
            --bucket "$BUCKET_NAME" \
            --region "$AWS_REGION" \
            --create-bucket-configuration LocationConstraint="$AWS_REGION"

        # Enable versioning
        aws s3api put-bucket-versioning \
            --bucket "$BUCKET_NAME" \
            --versioning-configuration Status=Enabled

        # Enable encryption
        aws s3api put-bucket-encryption \
            --bucket "$BUCKET_NAME" \
            --server-side-encryption-configuration '{
                "Rules": [
                    {
                        "ApplyServerSideEncryptionByDefault": {
                            "SSEAlgorithm": "AES256"
                        }
                    }
                ]
            }'

        # Block public access
        aws s3api put-public-access-block \
            --bucket "$BUCKET_NAME" \
            --public-access-block-configuration \
            "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"

        log "Created S3 bucket for Terraform state: $BUCKET_NAME"

        # Update Terraform configuration
        sed -i.bak "s/autowala-terraform-state/$BUCKET_NAME/g" infrastructure/terraform/main.tf
        rm infrastructure/terraform/main.tf.bak
    fi
}

# Initialize Terraform
initialize_terraform() {
    log "Initializing Terraform..."

    cd infrastructure/terraform

    terraform init
    terraform validate

    log "Terraform initialized successfully"

    cd ../..
}

# Plan Terraform deployment
plan_terraform() {
    log "Planning Terraform deployment..."

    cd infrastructure/terraform

    terraform plan -out=tfplan

    info "Terraform plan created. Review the plan above."
    read -p "Do you want to proceed with the deployment? (y/N): " -r

    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        info "Deployment cancelled by user"
        exit 0
    fi

    cd ../..
}

# Apply Terraform configuration
apply_terraform() {
    log "Applying Terraform configuration..."

    cd infrastructure/terraform

    terraform apply tfplan

    # Get outputs
    VPC_ID=$(terraform output -raw vpc_id)
    RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
    REDIS_ENDPOINT=$(terraform output -raw redis_endpoint)
    LOAD_BALANCER_DNS=$(terraform output -raw load_balancer_dns)

    log "Terraform applied successfully"
    info "VPC ID: $VPC_ID"
    info "RDS Endpoint: $RDS_ENDPOINT"
    info "Redis Endpoint: $REDIS_ENDPOINT"
    info "Load Balancer DNS: $LOAD_BALANCER_DNS"

    cd ../..
}

# Set up Route53 hosted zone (if needed)
setup_route53() {
    log "Setting up Route53 hosted zone..."

    DOMAIN_NAME=${DOMAIN_NAME:-"autowala.com"}

    # Check if hosted zone exists
    ZONE_ID=$(aws route53 list-hosted-zones-by-name \
        --dns-name "$DOMAIN_NAME" \
        --query "HostedZones[?Name=='${DOMAIN_NAME}.'].Id" \
        --output text | cut -d'/' -f3)

    if [ -z "$ZONE_ID" ]; then
        warn "Hosted zone for $DOMAIN_NAME not found. Please create it manually in Route53."
        info "After creating the hosted zone, update your domain registrar's name servers."
    else
        info "Hosted zone found: $ZONE_ID"
    fi
}

# Build and push initial Docker images
build_and_push_images() {
    log "Building and pushing initial Docker images..."

    # Get ECR login token
    aws ecr get-login-password --region "$AWS_REGION" | \
        docker login --username AWS --password-stdin \
        "$(aws sts get-caller-identity --query Account --output text).dkr.ecr.${AWS_REGION}.amazonaws.com"

    ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
    ECR_REGISTRY="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

    # Build and push API image
    log "Building AutoWala API image..."
    cd autowala-backend
    docker build -t "${ECR_REGISTRY}/autowala-api:latest" .
    docker push "${ECR_REGISTRY}/autowala-api:latest"
    cd ..

    # Build and push Admin image
    log "Building AutoWala Admin image..."
    cd autowala-admin
    docker build -t "${ECR_REGISTRY}/autowala-admin:latest" .
    docker push "${ECR_REGISTRY}/autowala-admin:latest"
    cd ..

    log "Docker images built and pushed successfully"
}

# Create GitHub secrets for CI/CD
create_github_secrets() {
    log "Setting up GitHub secrets..."

    warn "Please manually add the following secrets to your GitHub repository:"
    echo ""
    echo "AWS_ACCESS_KEY_ID: <Your AWS Access Key>"
    echo "AWS_SECRET_ACCESS_KEY: <Your AWS Secret Key>"
    echo "SLACK_WEBHOOK: <Your Slack webhook URL for notifications>"
    echo "CLOUDFRONT_DISTRIBUTION_ID: <Your CloudFront distribution ID>"
    echo ""

    read -p "Press Enter after adding the secrets to continue..."
}

# Verify deployment
verify_deployment() {
    log "Verifying deployment..."

    # Check ECS services
    API_SERVICE_STATUS=$(aws ecs describe-services \
        --cluster autowala-cluster \
        --services autowala-api \
        --region "$AWS_REGION" \
        --query 'services[0].status' \
        --output text)

    ADMIN_SERVICE_STATUS=$(aws ecs describe-services \
        --cluster autowala-cluster \
        --services autowala-admin \
        --region "$AWS_REGION" \
        --query 'services[0].status' \
        --output text)

    if [[ "$API_SERVICE_STATUS" == "ACTIVE" && "$ADMIN_SERVICE_STATUS" == "ACTIVE" ]]; then
        log "ECS services are running successfully"
    else
        warn "Some ECS services may not be running properly"
        info "API Service Status: $API_SERVICE_STATUS"
        info "Admin Service Status: $ADMIN_SERVICE_STATUS"
    fi
}

# Cleanup function
cleanup() {
    log "Cleaning up temporary files..."
    rm -f infrastructure/terraform/tfplan
}

# Main execution
main() {
    log "Starting AutoWala AWS Infrastructure Setup"

    check_prerequisites
    create_ecr_repositories
    create_terraform_state_bucket
    initialize_terraform
    plan_terraform
    apply_terraform
    setup_route53
    build_and_push_images
    create_github_secrets
    verify_deployment

    cleanup

    log "AutoWala infrastructure setup completed successfully!"
    info "Next steps:"
    echo "1. Update your domain's nameservers to point to Route53"
    echo "2. Configure GitHub secrets for CI/CD"
    echo "3. Push your code to trigger the first deployment"
    echo "4. Monitor the deployment in AWS ECS console"
}

# Handle script termination
trap cleanup EXIT

# Run main function
main "$@"