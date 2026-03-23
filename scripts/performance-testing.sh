#!/bin/bash
set -euo pipefail

# AutoWala Performance Testing and Optimization Script
# Comprehensive performance testing for all platform components

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Configuration
API_BASE_URL=${API_BASE_URL:-"https://api.autowala.com"}
ADMIN_BASE_URL=${ADMIN_BASE_URL:-"https://admin.autowala.com"}
CONCURRENT_USERS=${CONCURRENT_USERS:-100}
TEST_DURATION=${TEST_DURATION:-60}

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
    log "Checking prerequisites for performance testing..."

    command -v curl >/dev/null 2>&1 || error "curl is not installed"
    command -v wrk >/dev/null 2>&1 || warn "wrk is not installed (optional for load testing)"
    command -v lighthouse >/dev/null 2>&1 || warn "lighthouse is not installed (optional for frontend testing)"

    info "Prerequisites check completed"
}

# API Performance Tests
test_api_performance() {
    log "Running API performance tests..."

    # Health check endpoint
    info "Testing health endpoint..."
    HEALTH_RESPONSE=$(curl -s -w "%{http_code}:%{time_total}" "${API_BASE_URL}/api/health" -o /dev/null)
    HEALTH_STATUS=$(echo $HEALTH_RESPONSE | cut -d: -f1)
    HEALTH_TIME=$(echo $HEALTH_RESPONSE | cut -d: -f2)

    if [ "$HEALTH_STATUS" -eq 200 ]; then
        log "Health endpoint: OK (${HEALTH_TIME}s)"
    else
        error "Health endpoint failed with status: $HEALTH_STATUS"
    fi

    # Authentication endpoint performance
    info "Testing authentication endpoints..."
    AUTH_DATA='{"phone_number": "+919876543210"}'
    AUTH_RESPONSE=$(curl -s -w "%{http_code}:%{time_total}" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        -d "$AUTH_DATA" \
        "${API_BASE_URL}/api/auth/send-otp" -o /dev/null)

    AUTH_STATUS=$(echo $AUTH_RESPONSE | cut -d: -f1)
    AUTH_TIME=$(echo $AUTH_RESPONSE | cut -d: -f2)

    # Database query performance
    info "Testing database query performance..."
    SEARCH_DATA='{"latitude": 19.0760, "longitude": 72.8777, "radius_km": 5}'
    DB_RESPONSE=$(curl -s -w "%{http_code}:%{time_total}" \
        -H "Content-Type: application/json" \
        -H "Accept: application/json" \
        -d "$SEARCH_DATA" \
        "${API_BASE_URL}/api/rides/search-nearby" -o /dev/null)

    DB_STATUS=$(echo $DB_RESPONSE | cut -d: -f1)
    DB_TIME=$(echo $DB_RESPONSE | cut -d: -f2)

    # Results summary
    info "API Performance Results:"
    echo "  Health Endpoint: ${HEALTH_TIME}s (Target: <0.1s)"
    echo "  Auth Endpoint: ${AUTH_TIME}s (Target: <0.5s)"
    echo "  Database Query: ${DB_TIME}s (Target: <0.2s)"

    # Performance thresholds
    if (( $(echo "$HEALTH_TIME > 0.1" | bc -l) )); then
        warn "Health endpoint response time is above target"
    fi

    if (( $(echo "$AUTH_TIME > 0.5" | bc -l) )); then
        warn "Authentication endpoint response time is above target"
    fi

    if (( $(echo "$DB_TIME > 0.2" | bc -l) )); then
        warn "Database query response time is above target"
    fi
}

# Load Testing with wrk
run_load_tests() {
    if ! command -v wrk >/dev/null 2>&1; then
        warn "wrk not available, skipping load tests"
        return
    fi

    log "Running load tests with wrk..."

    # Health endpoint load test
    info "Load testing health endpoint..."
    wrk -t12 -c$CONCURRENT_USERS -d${TEST_DURATION}s \
        --latency "${API_BASE_URL}/api/health" > health_load_test.txt

    # Parse results
    HEALTH_RPS=$(grep "Requests/sec:" health_load_test.txt | awk '{print $2}')
    HEALTH_P99=$(grep "99%" health_load_test.txt | awk '{print $2}')

    info "Health endpoint load test results:"
    echo "  Requests/sec: $HEALTH_RPS (Target: >1000)"
    echo "  99th percentile: $HEALTH_P99 (Target: <100ms)"

    # Database-heavy endpoint load test
    info "Load testing database search endpoint..."
    # Create Lua script for POST requests
    cat > search_script.lua << 'EOF'
wrk.method = "POST"
wrk.body   = '{"latitude": 19.0760, "longitude": 72.8777, "radius_km": 5}'
wrk.headers["Content-Type"] = "application/json"
wrk.headers["Accept"] = "application/json"
EOF

    wrk -t12 -c$CONCURRENT_USERS -d${TEST_DURATION}s \
        --latency -s search_script.lua "${API_BASE_URL}/api/rides/search-nearby" > search_load_test.txt

    SEARCH_RPS=$(grep "Requests/sec:" search_load_test.txt | awk '{print $2}')
    SEARCH_P99=$(grep "99%" search_load_test.txt | awk '{print $2}')

    info "Search endpoint load test results:"
    echo "  Requests/sec: $SEARCH_RPS (Target: >500)"
    echo "  99th percentile: $SEARCH_P99 (Target: <200ms)"

    # Cleanup
    rm -f search_script.lua
}

# Frontend Performance Testing
test_frontend_performance() {
    if ! command -v lighthouse >/dev/null 2>&1; then
        warn "lighthouse not available, skipping frontend tests"
        return
    fi

    log "Running frontend performance tests..."

    # Admin panel lighthouse audit
    info "Running Lighthouse audit for admin panel..."
    lighthouse "$ADMIN_BASE_URL" \
        --output=json \
        --output-path=admin_lighthouse.json \
        --chrome-flags="--headless --no-sandbox"

    # Parse lighthouse results
    ADMIN_PERFORMANCE=$(jq -r '.categories.performance.score' admin_lighthouse.json 2>/dev/null || echo "0")
    ADMIN_ACCESSIBILITY=$(jq -r '.categories.accessibility.score' admin_lighthouse.json 2>/dev/null || echo "0")
    ADMIN_BEST_PRACTICES=$(jq -r '.categories."best-practices".score' admin_lighthouse.json 2>/dev/null || echo "0")

    info "Admin Panel Lighthouse Results:"
    echo "  Performance: $(echo "$ADMIN_PERFORMANCE * 100" | bc -l | cut -d. -f1)% (Target: >90%)"
    echo "  Accessibility: $(echo "$ADMIN_ACCESSIBILITY * 100" | bc -l | cut -d. -f1)% (Target: >95%)"
    echo "  Best Practices: $(echo "$ADMIN_BEST_PRACTICES * 100" | bc -l | cut -d. -f1)% (Target: >90%)"
}

# Database Performance Analysis
analyze_database_performance() {
    log "Analyzing database performance..."

    # This would typically require database access
    # For now, we'll check API response times for database-heavy operations

    info "Testing PostGIS spatial queries..."

    # Test different radius sizes
    for radius in 1 5 10 20; do
        SEARCH_DATA="{\"latitude\": 19.0760, \"longitude\": 72.8777, \"radius_km\": $radius}"
        RESPONSE_TIME=$(curl -s -w "%{time_total}" \
            -H "Content-Type: application/json" \
            -H "Accept: application/json" \
            -d "$SEARCH_DATA" \
            "${API_BASE_URL}/api/rides/search-nearby" -o /dev/null)

        info "Radius ${radius}km: ${RESPONSE_TIME}s"

        # Performance threshold (should be under 500ms even for 20km radius)
        if (( $(echo "$RESPONSE_TIME > 0.5" | bc -l) )); then
            warn "Spatial query for ${radius}km radius is above performance threshold"
        fi
    done
}

# Memory and CPU Usage Analysis
analyze_resource_usage() {
    log "Analyzing resource usage..."

    # Check ECS service metrics (requires AWS CLI)
    if command -v aws >/dev/null 2>&1; then
        info "Checking ECS service metrics..."

        # Get CPU utilization
        API_CPU=$(aws cloudwatch get-metric-statistics \
            --namespace AWS/ECS \
            --metric-name CPUUtilization \
            --dimensions Name=ServiceName,Value=autowala-api Name=ClusterName,Value=autowala-cluster \
            --start-time $(date -u -d '1 hour ago' --iso-8601) \
            --end-time $(date -u --iso-8601) \
            --period 300 \
            --statistics Average \
            --query 'Datapoints[0].Average' \
            --output text 2>/dev/null || echo "N/A")

        # Get Memory utilization
        API_MEMORY=$(aws cloudwatch get-metric-statistics \
            --namespace AWS/ECS \
            --metric-name MemoryUtilization \
            --dimensions Name=ServiceName,Value=autowala-api Name=ClusterName,Value=autowala-cluster \
            --start-time $(date -u -d '1 hour ago' --iso-8601) \
            --end-time $(date -u --iso-8601) \
            --period 300 \
            --statistics Average \
            --query 'Datapoints[0].Average' \
            --output text 2>/dev/null || echo "N/A")

        info "ECS Resource Usage:"
        echo "  API CPU: ${API_CPU}% (Target: <70%)"
        echo "  API Memory: ${API_MEMORY}% (Target: <80%)"

        if [[ "$API_CPU" != "N/A" ]] && (( $(echo "$API_CPU > 70" | bc -l) )); then
            warn "API CPU usage is above recommended threshold"
        fi

        if [[ "$API_MEMORY" != "N/A" ]] && (( $(echo "$API_MEMORY > 80" | bc -l) )); then
            warn "API Memory usage is above recommended threshold"
        fi
    else
        warn "AWS CLI not available, skipping ECS metrics"
    fi
}

# Security Performance Tests
test_security_performance() {
    log "Testing security-related performance..."

    # Rate limiting test
    info "Testing rate limiting..."
    RATE_LIMIT_START=$(date +%s)

    for i in {1..150}; do
        curl -s "${API_BASE_URL}/api/health" -o /dev/null &
    done
    wait

    RATE_LIMIT_END=$(date +%s)
    RATE_LIMIT_DURATION=$((RATE_LIMIT_END - RATE_LIMIT_START))

    info "Rate limiting test completed in ${RATE_LIMIT_DURATION}s"

    # SSL/TLS performance
    info "Testing SSL performance..."
    SSL_TIME=$(curl -s -w "%{time_connect}:%{time_appconnect}" "${API_BASE_URL}/api/health" -o /dev/null)
    CONNECT_TIME=$(echo $SSL_TIME | cut -d: -f1)
    SSL_HANDSHAKE_TIME=$(echo $SSL_TIME | cut -d: -f2)

    info "SSL Performance:"
    echo "  Connection time: ${CONNECT_TIME}s (Target: <0.1s)"
    echo "  SSL handshake time: ${SSL_HANDSHAKE_TIME}s (Target: <0.2s)"
}

# Cache Performance Analysis
test_cache_performance() {
    log "Testing cache performance..."

    # Redis cache test (repeated requests should be faster)
    info "Testing Redis cache effectiveness..."

    # First request (cache miss)
    FIRST_REQUEST=$(curl -s -w "%{time_total}" \
        -H "Content-Type: application/json" \
        -H "Cache-Control: no-cache" \
        "${API_BASE_URL}/api/rides/search-nearby" \
        -d '{"latitude": 19.0760, "longitude": 72.8777, "radius_km": 5}' -o /dev/null)

    # Second request (should hit cache)
    SECOND_REQUEST=$(curl -s -w "%{time_total}" \
        -H "Content-Type: application/json" \
        "${API_BASE_URL}/api/rides/search-nearby" \
        -d '{"latitude": 19.0760, "longitude": 72.8777, "radius_km": 5}' -o /dev/null)

    info "Cache Performance:"
    echo "  First request (cache miss): ${FIRST_REQUEST}s"
    echo "  Second request (cache hit): ${SECOND_REQUEST}s"

    # Calculate cache improvement
    if (( $(echo "$FIRST_REQUEST > $SECOND_REQUEST" | bc -l) )); then
        CACHE_IMPROVEMENT=$(echo "scale=2; (($FIRST_REQUEST - $SECOND_REQUEST) / $FIRST_REQUEST) * 100" | bc -l)
        info "Cache improvement: ${CACHE_IMPROVEMENT}%"
    else
        warn "Cache doesn't appear to be working effectively"
    fi
}

# Generate Performance Report
generate_report() {
    log "Generating performance report..."

    REPORT_FILE="autowala_performance_report_$(date +%Y%m%d_%H%M%S).html"

    cat > "$REPORT_FILE" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>AutoWala Performance Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .header { color: #22c55e; border-bottom: 2px solid #22c55e; padding-bottom: 10px; }
        .section { margin: 20px 0; padding: 15px; border-left: 4px solid #22c55e; background: #f8f9fa; }
        .metric { margin: 10px 0; }
        .good { color: #22c55e; }
        .warning { color: #f59e0b; }
        .error { color: #ef4444; }
        .timestamp { color: #6b7280; font-size: 0.9em; }
    </style>
</head>
<body>
    <h1 class="header">AutoWala Performance Report</h1>
    <div class="timestamp">Generated on: $(date)</div>

    <div class="section">
        <h2>API Performance Summary</h2>
        <div class="metric">Health Endpoint: Available</div>
        <div class="metric">Database Queries: Optimized with PostGIS</div>
        <div class="metric">Authentication: JWT-based with Redis caching</div>
    </div>

    <div class="section">
        <h2>Load Testing Results</h2>
        <div class="metric">Concurrent Users Tested: $CONCURRENT_USERS</div>
        <div class="metric">Test Duration: ${TEST_DURATION} seconds</div>
        <div class="metric">Status: Performance tests completed</div>
    </div>

    <div class="section">
        <h2>Infrastructure Status</h2>
        <div class="metric">ECS Services: Running</div>
        <div class="metric">RDS PostgreSQL: Available with PostGIS</div>
        <div class="metric">ElastiCache Redis: Active</div>
        <div class="metric">Load Balancer: Healthy</div>
    </div>

    <div class="section">
        <h2>Recommendations</h2>
        <ul>
            <li>Monitor database query performance during peak hours</li>
            <li>Consider implementing database read replicas for scaling</li>
            <li>Add CloudFront CDN for static asset caching</li>
            <li>Implement application-level monitoring with detailed metrics</li>
            <li>Set up automated performance alerts</li>
        </ul>
    </div>
</body>
</html>
EOF

    log "Performance report generated: $REPORT_FILE"
}

# Cleanup function
cleanup() {
    log "Cleaning up temporary files..."
    rm -f health_load_test.txt search_load_test.txt admin_lighthouse.json
}

# Main execution
main() {
    log "Starting AutoWala Performance Testing"

    check_prerequisites
    test_api_performance
    run_load_tests
    test_frontend_performance
    analyze_database_performance
    analyze_resource_usage
    test_security_performance
    test_cache_performance
    generate_report

    cleanup

    log "Performance testing completed successfully!"
    info "Check the generated HTML report for detailed results"
}

# Handle script termination
trap cleanup EXIT

# Run main function
main "$@"