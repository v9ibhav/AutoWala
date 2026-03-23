#!/bin/bash
set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [ -f ".env.production" ]; then
    source .env.production
else
    echo "⚠️  .env.production not found"
    AWS_REGION=${AWS_REGION:-ap-south-1}
fi

echo "╔══════════════════════════════════════════╗"
echo "║   AutoWala - Status Check                ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# ECS Services
echo -e "${BLUE}📊 ECS Services Status:${NC}"
aws ecs describe-services \
    --cluster autowala-cluster \
    --services autowala-api autowala-admin \
    --region $AWS_REGION \
    --query 'services[].[serviceName, status, runningCount, desiredCount]' \
    --output table 2>/dev/null || echo "  ⚠️  ECS services not found"

echo ""

# Database
echo -e "${BLUE}🗄️  Database Status:${NC}"
aws rds describe-db-clusters \
    --db-cluster-identifier autowala-cluster \
    --region $AWS_REGION \
    --query 'DBClusters[0].[Status, Endpoint]' \
    --output table 2>/dev/null || echo "  ⚠️  RDS cluster not found"

echo ""

# Redis
echo -e "${BLUE}🔴 Redis Status:${NC}"
aws elasticache describe-replication-groups \
    --replication-group-id autowala-redis \
    --region $AWS_REGION \
    --query 'ReplicationGroups[0].[Status, ConfigurationEndpoint.Address]' \
    --output table 2>/dev/null || echo "  ⚠️  Redis cluster not found"

echo ""

# Load Balancer
echo -e "${BLUE}⚖️  Load Balancer:${NC}"
aws elbv2 describe-load-balancers \
    --names autowala-alb \
    --region $AWS_REGION \
    --query 'LoadBalancers[0].[State.Code, DNSName]' \
    --output table 2>/dev/null || echo "  ⚠️  Load balancer not found"

echo ""

# Health Checks
if [ -n "${API_DOMAIN:-}" ]; then
    echo -e "${BLUE}🏥 Health Checks:${NC}"
    
    echo -n "  API (https://${API_DOMAIN}/api/health): "
    if curl -f -s "https://${API_DOMAIN}/api/health" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ OK${NC}"
    else
        echo -e "${RED}✗ FAILED${NC}"
    fi
    
    echo -n "  Admin (https://${ADMIN_DOMAIN}/): "
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" "https://${ADMIN_DOMAIN}/" 2>/dev/null || echo "000")
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
        echo -e "${GREEN}✓ OK (HTTP $HTTP_CODE)${NC}"
    else
        echo -e "${RED}✗ FAILED (HTTP $HTTP_CODE)${NC}"
    fi
fi

echo ""

# Recent Logs
echo -e "${BLUE}📝 Recent API Logs (last 5 entries):${NC}"
aws logs tail /ecs/autowala-app \
    --since 5m \
    --format short \
    --region $AWS_REGION 2>/dev/null | tail -5 || echo "  ⚠️  No logs found"

echo ""
echo "For detailed commands, see: AWS_QUICK_REFERENCE.md"
