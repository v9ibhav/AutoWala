#!/bin/bash
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=================================="
echo "AutoWala - Prerequisites Validator"
echo "=================================="
echo ""

ERRORS=0
WARNINGS=0

# Check required tools
echo "Checking required tools..."

check_tool() {
    if command -v $1 >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $1 installed"
        return 0
    else
        echo -e "${RED}✗${NC} $1 not installed"
        ((ERRORS++))
        return 1
    fi
}

check_tool "aws"
check_tool "terraform"
check_tool "docker"
check_tool "jq"
check_tool "git"

echo ""
echo "Checking AWS credentials..."
if aws sts get-caller-identity >/dev/null 2>&1; then
    AWS_ACCOUNT=$(aws sts get-caller-identity --query Account --output text)
    echo -e "${GREEN}✓${NC} AWS credentials configured (Account: $AWS_ACCOUNT)"
else
    echo -e "${RED}✗${NC} AWS credentials not configured"
    echo "  Run: aws configure"
    ((ERRORS++))
fi

echo ""
echo "Checking environment configuration..."
if [ -f ".env.production" ]; then
    echo -e "${GREEN}✓${NC} .env.production exists"
    
    # Check required variables
    check_env_var() {
        if grep -q "^$1=.\+" .env.production 2>/dev/null; then
            echo -e "${GREEN}✓${NC} $1 configured"
        else
            echo -e "${RED}✗${NC} $1 not configured"
            ((ERRORS++))
        fi
    }
    
    check_env_var "AWS_REGION"
    check_env_var "AWS_ACCOUNT_ID"
    check_env_var "DOMAIN_NAME"
    check_env_var "FIREBASE_PROJECT_ID"
    check_env_var "GOOGLE_MAPS_API_KEY"
else
    echo -e "${RED}✗${NC} .env.production not found"
    echo "  Copy .env.example to .env.production and fill in values"
    ((ERRORS++))
fi

echo ""
echo "Checking Docker..."
if docker info >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Docker is running"
else
    echo -e "${RED}✗${NC} Docker is not running"
    ((ERRORS++))
fi

echo ""
echo "Checking Terraform..."
cd infrastructure/terraform 2>/dev/null || {
    echo -e "${RED}✗${NC} Terraform directory not found"
    ((ERRORS++))
    cd ../..
}
if [ -f "main.tf" ]; then
    echo -e "${GREEN}✓${NC} Terraform configuration found"
else
    echo -e "${RED}✗${NC} Terraform configuration not found"
    ((ERRORS++))
fi
cd ../.. 2>/dev/null || true

echo ""
echo "=================================="
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓ All prerequisites met!${NC}"
    echo "You're ready to deploy."
    exit 0
else
    echo -e "${RED}✗ $ERRORS error(s) found${NC}"
    echo "Please fix the errors above before deploying."
    exit 1
fi
