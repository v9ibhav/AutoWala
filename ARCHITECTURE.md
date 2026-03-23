# AutoWala - System Architecture & Design Document

**Version:** 1.0
**Last Updated:** March 2026
**Status:** Production-Ready Design

---

## 1. SYSTEM OVERVIEW

```
┌─────────────────────────────────────────────────────────────────┐
│                      AUTOWALA PLATFORM                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                   │
│  ┌──────────────┐      ┌──────────────┐      ┌──────────────┐   │
│  │  User App    │      │  Rider App   │      │ Admin Panel  │   │
│  │  (Flutter)   │      │  (Flutter)   │      │   (React)    │   │
│  └──────┬───────┘      └──────┬───────┘      └──────┬───────┘   │
│         │                     │                      │            │
│         └─────────────────────┼──────────────────────┘            │
│                               │                                   │
│                     ┌─────────▼─────────┐                        │
│                     │   API Gateway     │                        │
│                     │  (Laravel REST)   │                        │
│                     └─────────┬─────────┘                        │
│                               │                                   │
│         ┌─────────────────────┼─────────────────────┐            │
│         │                     │                     │            │
│    ┌────▼────┐         ┌─────▼──────┐      ┌─────▼──────┐       │
│    │Auth API │         │Ride APIs   │      │ Admin APIs │       │
│    └──────────┘         └────────────┘      └────────────┘       │
│                                                                   │
│  ┌──────────┐  ┌──────────────┐  ┌──────────┐  ┌──────────┐    │
│  │PostgreSQL│  │    Redis     │  │ Firebase │  │Google Maps│   │
│  │+PostGIS  │  │   (Cache)    │  │ Realtime │  │   API    │    │
│  └──────────┘  └──────────────┘  └──────────┘  └──────────┘    │
│                                                                   │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │            AWS Cloud Infrastructure                      │    │
│  │  EC2 | RDS | ElastiCache | S3 | CloudFront | ALB       │    │
│  └─────────────────────────────────────────────────────────┘    │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. TECHNOLOGY STACK

### Frontend
- **Mobile Apps:** Flutter (cross-platform iOS/Android)
- **UI Theme:** Minimal modern design - White/Black/Green accent
- **State Management:** Riverpod or GetX
- **Maps:** Google Maps SDK + Google Places API
- **Real-time:** Firebase Realtime Database Listeners

### Backend
- **Framework:** Laravel 11 (REST API)
- **Language:** PHP 8.2+
- **HTTP Client:** Guzzle
- **Authentication:** JWT tokens
- **Validation:** Form Request classes

### Database
- **Primary:** PostgreSQL 15+ with PostGIS 3.4 (spatial queries)
- **Cache:** Redis (location caching, session management)
- **Real-time:** Firebase Realtime Database (live tracking)

### Infrastructure
- **Cloud:** AWS (primary)
- **Compute:** EC2 (t3.medium → t3.large scaling)
- **Database:** RDS PostgreSQL (Multi-AZ)
- **Cache:** ElastiCache Redis (standalone → cluster)
- **Storage:** S3 (KYC documents, profile images)
- **CDN:** CloudFront (image delivery)
- **Load Balancer:** Application Load Balancer (ALB)
- **DNS:** Route 53

### External Services
- **Maps:** Google Maps Platform
- **SMS/OTP:** AWS SNS or Twilio
- **Push Notifications:** Firebase Cloud Messaging (FCM)
- **Crash Reporting:** Firebase Crashlytics
- **Analytics:** Firebase Analytics

---

## 3. DATA FLOW ARCHITECTURE

### Real-Time Location Sharing Flow
```
Rider App (Location Service)
         ↓ (every 3-5 seconds)
Firebase Realtime DB
         ↓ (listener subscribed)
User App (Map Updates)
```

### Ride Discovery Flow
```
User enters destination
         ↓
Query nearby riders (PostgreSQL + PostGIS)
         ↓
Filter by route overlap + ETA
         ↓
Fetch live location from Firebase
         ↓
Display on map + bottom sheet
```

### Ride Booking & Tracking Flow
```
User selects auto
         ↓
Create ride_log entry
         ↓
Link user to Firebase real-time session
         ↓
Live tracking with location updates
         ↓
Rider picks up user (manual confirmation)
         ↓
Ride completes (user/rider both confirm)
         ↓
Rating + feedback submission
```

---

## 4. SCALABILITY ARCHITECTURE

### Database Optimization
- **PostGIS Indexing:** GIST indexes for spatial queries
- **Connection Pooling:** PgBouncer for connection management
- **Read Replicas:** Multiple read replicas for scaling SELECT queries
- **Sharding Strategy:** Location-based sharding for high-scale (future)

### Caching Strategy
- **User Sessions:** Redis TTL 24 hours
- **Route Data:** Redis TTL 1 hour (expires when route is updated)
- **Location Cache:** Firebase with 5-second update window
- **Nearby Autos:** Redis cache (30-second expiry)

### API Optimization
- **Rate Limiting:** 100 requests/minute per user
- **Request Batching:** Location updates batched in 5-second intervals
- **CDN for Static Assets:** CloudFront for images, docs
- **HTTP/2:** Enable multiplexing
- **Compression:** Gzip + Brotli

### Load Balancing
```
Internet → ALB (Route 53)
         ↓
    ┌────┴────┐
    ↓         ↓
  EC2-1    EC2-2    EC2-3 (Auto-scaling group)
    │       │        │
    └───────┴────────┘
         ↓
   RDS (Primary)
         ↓
   Read Replicas
```

---

## 5. RELIABILITY & REDUNDANCY

### High Availability
- **Multi-region:** Primary (Mumbai) + Standby (Bangalore)
- **Database:** Multi-AZ RDS setup
- **Load Balancer:** Cross-AZ ALB
- **Auto-scaling:** Min 2, Max 10 EC2 instances

### Disaster Recovery
- **RTO:** < 1 hour
- **RPO:** < 15 minutes (daily snapshots + transaction logs)
- **Backup:** Automated daily snapshots + cross-region replication

### Monitoring & Alerting
- **CloudWatch:** Monitor CPU, Memory, API latency
- **Alarms:** Alert when latency > 500ms or error rate > 2%
- **Logging:** CloudWatch Logs + Log Insights
- **APM:** DataDog or New Relic (optional)

---

## 6. SECURITY ARCHITECTURE

### API Security
- **Authentication:** JWT tokens (30-min expiry)
- **Rate Limiting:** Per-user request throttling
- **CORS:** Strict origin validation
- **SSL/TLS:** All traffic encrypted (HSTS enabled)

### Data Security
- **Database:** Encrypted at rest (RDS encryption)
- **Communication:** End-to-end encryption for sensitive data
- **KYC Documents:** Encrypted in S3 with server-side encryption (SSE-S3)
- **GDPR Compliance:** User data retention policies

### Application Security
- **Input Validation:** Laravel Form Requests
- **CSRF Protection:** Token-based CSRF
- **SQL Injection Prevention:** Parameterized queries
- **XSS Prevention:** Blade template escaping

---

## 7. PERFORMANCE TARGETS

| Metric | Target | Tech |
|--------|--------|------|
| API Response Time | < 200ms | Redis cache + DB optimization |
| Map Load Time | < 1.5s | CloudFront + Image optimization |
| Location Update | < 500ms delay | Firebase real-time |
| Nearby Autos Query | < 100ms | PostGIS + Redis cache |
| App Cold Start | < 3s | Lazy loading + code splitting |
| Battery Impact (riders) | < 3% per hour | Location batching + efficient tracking |

---

## 8. DEPLOYMENT PIPELINE

```
GitHub Commit
      ↓
   CI/CD (GitHub Actions)
      ↓
   Run Tests + Build
      ↓
   Deploy to Staging
      ↓
   Smoke Tests
      ↓
   Deploy to Production (blue-green)
      ↓
   Verify + Rollback (if needed)
```

---

## 9. MONITORING & OBSERVABILITY

### Key Metrics
- Active ridersOnline
- Nearby autos found (discovery rate)
- Ride completion rate
- Average ETA accuracy
- User retention
- Rider retention

### Dashboards
1. **Real-time Operations Dashboard**
2. **KPI Monitoring Dashboard**
3. **Infrastructure Health Dashboard**
4. **Error Tracking Dashboard**

---

## 10. COST OPTIMIZATION

| Component | Optimization |
|-----------|---------------|
| Compute | Auto-scaling, use Spot instances for non-critical |
| Database | Read replicas only for peak load, archive old ride logs |
| Storage | S3 Intelligent-Tiering for old documents |
| Data Transfer | CloudFront for images, local caching |
| API Calls | Batch updates, cache aggressively |

**Estimated Monthly Cost (10K MAU):** $800-1200 (scales with usage)

