# AutoWala - Database Schema (PostgreSQL + PostGIS)

---

## 1. USER MANAGEMENT

### `users` Table
```sql
CREATE TABLE users (
    id BIGSERIAL PRIMARY KEY,
    phone_number VARCHAR(20) UNIQUE NOT NULL,
    country_code VARCHAR(5) DEFAULT '+91',
    full_name VARCHAR(255),

    -- Profile
    profile_photo_url TEXT,
    email VARCHAR(255) UNIQUE,

    -- OTP & Auth
    otp_code VARCHAR(6),
    otp_expires_at TIMESTAMP,
    otp_attempts INT DEFAULT 0,

    -- Account Status
    is_active BOOLEAN DEFAULT TRUE,
    is_verified BOOLEAN DEFAULT FALSE,
    verified_at TIMESTAMP,

    -- Preferences
    preferred_language VARCHAR(10) DEFAULT 'en',
    notification_enabled BOOLEAN DEFAULT TRUE,

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP -- Soft delete
);

CREATE UNIQUE INDEX idx_users_phone ON users(phone_number) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_is_active ON users(is_active);
CREATE INDEX idx_users_created_at ON users(created_at);
```

### `user_ratings` Table
```sql
CREATE TABLE user_ratings (
    id BIGSERIAL PRIMARY KEY,
    from_user_id BIGINT NOT NULL REFERENCES users(id),
    to_rider_id BIGINT NOT NULL REFERENCES riders(id),
    ride_log_id BIGINT NOT NULL REFERENCES ride_logs(id),

    -- Rating
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    feedback TEXT,

    -- Metadata
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX idx_unique_rating_per_ride ON user_ratings(from_user_id, ride_log_id);
CREATE INDEX idx_to_rider_ratings ON user_ratings(to_rider_id);
```

### `user_complaints` Table
```sql
CREATE TABLE user_complaints (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id),
    rider_id BIGINT REFERENCES riders(id),
    ride_log_id BIGINT REFERENCES ride_logs(id),

    -- Complaint Details
    complaint_type VARCHAR(50) NOT NULL, -- 'rude_behavior', 'dirty_vehicle', 'overcharge', 'safety', 'other'
    description TEXT,
    attachments JSONB, -- Array of S3 URLs

    -- Status
    status VARCHAR(50) DEFAULT 'open', -- 'open', 'investigating', 'resolved', 'rejected'
    resolution_notes TEXT,
    resolved_at TIMESTAMP,

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_complaints_user ON user_complaints(user_id);
CREATE INDEX idx_complaints_status ON user_complaints(status);
CREATE INDEX idx_complaints_created_at ON user_complaints(created_at);
```

---

## 2. RIDER MANAGEMENT

### `riders` Table
```sql
CREATE TABLE riders (
    id BIGSERIAL PRIMARY KEY,
    user_id BIGINT NOT NULL UNIQUE REFERENCES users(id),

    -- Profile
    full_name VARCHAR(255) NOT NULL,
    phone_number VARCHAR(20) NOT NULL,
    country_code VARCHAR(5) DEFAULT '+91',
    profile_photo_url TEXT,

    -- KYC Status
    kyc_status VARCHAR(50) DEFAULT 'pending', -- 'pending', 'verified', 'rejected', 'expired'
    kyc_verified_at TIMESTAMP,
    kyc_rejection_reason TEXT,

    -- Vehicle Info
    vehicle_id BIGINT REFERENCES vehicles(id),

    -- Ratings & Reputation
    average_rating DECIMAL(3,2) DEFAULT 5.0,
    total_rides INT DEFAULT 0,

    -- Current Status
    is_online BOOLEAN DEFAULT FALSE,
    last_online_at TIMESTAMP,
    current_location GEOMETRY(POINT, 4326), -- PostGIS for location
    location_updated_at TIMESTAMP,

    -- Settings
    preferred_language VARCHAR(10) DEFAULT 'en',
    fare_per_passenger DECIMAL(10,2) NOT NULL DEFAULT 30, -- INR

    -- Account
    is_active BOOLEAN DEFAULT TRUE,
    account_suspended_at TIMESTAMP,
    suspension_reason TEXT,

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

CREATE UNIQUE INDEX idx_riders_user_id ON riders(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_riders_is_online ON riders(is_online);
CREATE INDEX idx_riders_kyc_status ON riders(kyc_status);
CREATE INDEX idx_riders_location ON riders USING GIST(current_location);
```

### `documents` Table (KYC)
```sql
CREATE TABLE documents (
    id BIGSERIAL PRIMARY KEY,
    rider_id BIGINT NOT NULL REFERENCES riders(id),

    -- Document Details
    document_type VARCHAR(50) NOT NULL, -- 'aadhar', 'license', 'registration', 'insurance', 'bank_account'
    document_number VARCHAR(100) NOT NULL,

    -- Storage
    document_url_front TEXT,
    document_url_back TEXT,
    document_url_additional TEXT,

    -- Verification
    is_verified BOOLEAN DEFAULT FALSE,
    verified_by_admin_id BIGINT REFERENCES admins(id),
    verified_at TIMESTAMP,
    verification_notes TEXT,

    -- Expiry
    expiry_date DATE,

    -- Timestamps
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

CREATE INDEX idx_documents_rider ON documents(rider_id);
CREATE INDEX idx_documents_type ON documents(document_type);
```

### `vehicles` Table
```sql
CREATE TABLE vehicles (
    id BIGSERIAL PRIMARY KEY,
    rider_id BIGINT NOT NULL REFERENCES riders(id),

    -- Vehicle Details
    registration_number VARCHAR(20) UNIQUE NOT NULL,
    make VARCHAR(100), -- 'Bajaj', 'Piaggio', etc.
    model VARCHAR(100),
    color VARCHAR(50),
    year INT,

    -- Capacity
    max_passengers INT DEFAULT 3,

    -- Documents
    registration_doc_url TEXT,
    insurance_doc_url TEXT,
    pollution_certificate_url TEXT,

    -- Status
    is_verified BOOLEAN DEFAULT FALSE,
    verification_notes TEXT,

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

CREATE UNIQUE INDEX idx_vehicles_registration ON vehicles(registration_number) WHERE deleted_at IS NULL;
CREATE INDEX idx_vehicles_rider ON vehicles(rider_id);
```

---

## 3. ROUTE MANAGEMENT

### `routes` Table
```sql
CREATE TABLE routes (
    id BIGSERIAL PRIMARY KEY,
    rider_id BIGINT NOT NULL REFERENCES riders(id),

    -- Route Details
    route_name VARCHAR(255), -- e.g., "Andheri - Fort"
    description TEXT,

    -- Geometry
    route_geometry GEOMETRY(LINESTRING, 4326), -- PostGIS for route path

    -- Status
    is_active BOOLEAN DEFAULT TRUE,
    is_deleted BOOLEAN DEFAULT FALSE,

    -- Statistics
    total_distance_km DECIMAL(8,2),
    estimated_duration_min INT,

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    deleted_at TIMESTAMP
);

CREATE INDEX idx_routes_rider ON routes(rider_id);
CREATE INDEX idx_routes_is_active ON routes(is_active);
CREATE INDEX idx_routes_geometry ON routes USING GIST(route_geometry);
```

### `route_points` Table (Waypoints)
```sql
CREATE TABLE route_points (
    id BIGSERIAL PRIMARY KEY,
    route_id BIGINT NOT NULL REFERENCES routes(id) ON DELETE CASCADE,

    -- Location
    location_name VARCHAR(255), -- e.g., "Andheri Station"
    location_address TEXT,
    location_lat DECIMAL(10,8),
    location_lon DECIMAL(11,8),
    location_geom GEOMETRY(POINT, 4326),

    -- Sequence
    sequence_order INT NOT NULL,

    -- Timing
    estimated_arrival_min INT, -- Minutes from route start

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_route_points_route ON route_points(route_id);
CREATE INDEX idx_route_points_sequence ON route_points(route_id, sequence_order);
CREATE INDEX idx_route_points_geom ON route_points USING GIST(location_geom);
```

---

## 4. RIDE MANAGEMENT

### `ride_logs` Table
```sql
CREATE TABLE ride_logs (
    id BIGSERIAL PRIMARY KEY,

    -- Parties
    user_id BIGINT NOT NULL REFERENCES users(id),
    rider_id BIGINT NOT NULL REFERENCES riders(id),
    vehicle_id BIGINT NOT NULL REFERENCES vehicles(id),
    route_id BIGINT REFERENCES routes(id),

    -- Pickup & Dropoff
    pickup_location_name VARCHAR(255),
    pickup_lat DECIMAL(10,8),
    pickup_lon DECIMAL(11,8),
    pickup_time TIMESTAMP,
    pickup_address TEXT,

    dropoff_location_name VARCHAR(255),
    dropoff_lat DECIMAL(10,8),
    dropoff_lon DECIMAL(11,8),
    dropoff_time TIMESTAMP,
    dropoff_address TEXT,

    -- Ride Details
    status VARCHAR(50) DEFAULT 'matched', -- 'matched', 'in_transit', 'completed', 'cancelled'
    no_of_passengers INT DEFAULT 1,

    -- Fare (Display only - payment is CASH)
    fare_amount DECIMAL(10,2),
    fare_currency VARCHAR(3) DEFAULT 'INR',

    -- Tracking
    pickup_route_index INT, -- Which stoppoint in the route
    is_user_picked_up BOOLEAN DEFAULT FALSE,
    is_ride_completed BOOLEAN DEFAULT FALSE,

    -- Navigation
    estimated_pickup_time TIMESTAMP,
    estimated_dropoff_time TIMESTAMP,
    actual_pickup_time TIMESTAMP,
    actual_dropoff_time TIMESTAMP,

    -- Distance & Time
    actual_distance_km DECIMAL(8,2),
    actual_duration_min INT,

    -- Firebase Session ID (for real-time tracking)
    firebase_session_id VARCHAR(255) UNIQUE,

    -- Cancellation
    cancelled_by VARCHAR(50), -- 'user', 'rider', 'system'
    cancelled_at TIMESTAMP,
    cancellation_reason TEXT,

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    completed_at TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_ride_logs_user ON ride_logs(user_id);
CREATE INDEX idx_ride_logs_rider ON ride_logs(rider_id);
CREATE INDEX idx_ride_logs_status ON ride_logs(status);
CREATE INDEX idx_ride_logs_created_at ON ride_logs(created_at);
CREATE INDEX idx_ride_logs_firebase_session ON ride_logs(firebase_session_id);
```

### `ride_tracking_history` Table
```sql
CREATE TABLE ride_tracking_history (
    id BIGSERIAL PRIMARY KEY,
    ride_log_id BIGINT NOT NULL REFERENCES ride_logs(id) ON DELETE CASCADE,

    -- Location Update
    latitude DECIMAL(10,8),
    longitude DECIMAL(11,8),
    location_geom GEOMETRY(POINT, 4326),
    accuracy_meters INT,

    -- Timestamps
    recorded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_tracking_ride ON ride_tracking_history(ride_log_id);
CREATE INDEX idx_tracking_recorded_at ON ride_tracking_history(recorded_at);
```

---

## 5. ADMIN & SUPPORT

### `admins` Table
```sql
CREATE TABLE admins (
    id BIGSERIAL PRIMARY KEY,

    -- Profile
    full_name VARCHAR(255) NOT NULL,
    email VARCHAR(255) UNIQUE NOT NULL,
    phone_number VARCHAR(20),

    -- Auth
    password_hash VARCHAR(255) NOT NULL,

    -- Permissions
    role VARCHAR(50) NOT NULL, -- 'super_admin', 'kyc_reviewer', 'support', 'analyst'
    permissions JSONB, -- Granular permissions

    -- Account
    is_active BOOLEAN DEFAULT TRUE,
    last_login_at TIMESTAMP,

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX idx_admins_email ON admins(email);
CREATE INDEX idx_admins_role ON admins(role);
```

### `support_tickets` Table
```sql
CREATE TABLE support_tickets (
    id BIGSERIAL PRIMARY KEY,

    -- Ticket Details
    ticket_number VARCHAR(20) UNIQUE NOT NULL,
    user_id BIGINT REFERENCES users(id),
    rider_id BIGINT REFERENCES riders(id),
    ride_log_id BIGINT REFERENCES ride_logs(id),

    -- Issue
    issue_category VARCHAR(50) NOT NULL, -- 'ride_issue', 'payment', 'safety', 'account', 'other'
    issue_description TEXT NOT NULL,
    attachments JSONB, -- Array of S3 URLs

    -- Status & Assignment
    status VARCHAR(50) DEFAULT 'open', -- 'open', 'assigned', 'in_progress', 'resolved', 'closed'
    assigned_to_admin_id BIGINT REFERENCES admins(id),

    -- Priority
    priority VARCHAR(50) DEFAULT 'medium', -- 'low', 'medium', 'high', 'critical'

    -- Resolution
    resolution TEXT,
    resolved_at TIMESTAMP,

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_support_tickets_status ON support_tickets(status);
CREATE INDEX idx_support_tickets_user ON support_tickets(user_id);
CREATE INDEX idx_support_tickets_priority ON support_tickets(priority);
```

---

## 6. ANALYTICS & METRICS

### `daily_metrics` Table (Aggregated)
```sql
CREATE TABLE daily_metrics (
    id BIGSERIAL PRIMARY KEY,
    date DATE NOT NULL,

    -- Users
    total_active_users INT,
    new_user_signups INT,
    returning_users INT,

    -- Riders
    total_active_riders INT,
    new_rider_signups INT,
    riders_online_peak INT,

    -- Rides
    total_rides_completed INT,
    total_rides_cancelled INT,
    avg_user_rating DECIMAL(3,2),
    avg_rider_rating DECIMAL(3,2),

    -- Geography
    cities_active INT,

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE UNIQUE INDEX idx_daily_metrics_date ON daily_metrics(date);
```

### `hourly_metrics` Table (Real-time Dashboard)
```sql
CREATE TABLE hourly_metrics (
    id BIGSERIAL PRIMARY KEY,
    date_hour TIMESTAMP NOT NULL,

    -- Live Data
    riders_online INT,
    active_rides INT,
    new_users_this_hour INT,

    -- KPIs
    avg_wait_time_sec INT,
    discovery_success_rate DECIMAL(5,2), -- Percentage

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_hourly_metrics_date_hour ON hourly_metrics(date_hour);
```

---

## 7. NOTIFICATIONS & COMMUNICATION

### `notifications` Table
```sql
CREATE TABLE notifications (
    id BIGSERIAL PRIMARY KEY,

    -- Recipient
    user_id BIGINT REFERENCES users(id),
    rider_id BIGINT REFERENCES riders(id),

    -- Content
    notification_type VARCHAR(50) NOT NULL, -- 'auto_nearby', 'ride_started', 'eta_update', 'rider_arrived', etc.
    title VARCHAR(255),
    message TEXT,

    -- Metadata
    related_ride_log_id BIGINT REFERENCES ride_logs(id),
    data JSONB, -- Additional JSON data

    -- Status
    is_read BOOLEAN DEFAULT FALSE,
    read_at TIMESTAMP,

    -- FCM
    fcm_message_id VARCHAR(255),

    -- Timestamps
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_notifications_user ON notifications(user_id);
CREATE INDEX idx_notifications_rider ON notifications(rider_id);
CREATE INDEX idx_notifications_is_read ON notifications(is_read);
```

---

## 8. FIREBASE REALTIME STRUCTURE (JSON)

```json
{
  "active_riders": {
    "rider_123": {
      "user_id": "user_456",
      "full_name": "Raj Kumar",
      "phone_number": "9876543210",
      "lat": 19.0760,
      "lon": 72.8777,
      "heading": 45,
      "accuracy": 15,
      "route_id": "route_789",
      "status": "online",
      "rating": 4.8,
      "fare_per_passenger": 30,
      "vehicle_number": "MH01AB1234",
      "last_update": 1679230560000,
      "timestamp": 1679230560000
    }
  },

  "active_rides": {
    "ride_log_999": {
      "user_id": "user_456",
      "rider_id": "rider_123",
      "status": "in_transit",
      "pickup_lat": 19.0700,
      "pickup_lon": 72.8800,
      "dropoff_lat": 19.1000,
      "dropoff_lon": 72.9000,
      "current_rider_lat": 19.0760,
      "current_rider_lon": 72.8777,
      "eta_pickup_sec": 120,
      "eta_dropoff_sec": 600,
      "timestamp": 1679230560000
    }
  },

  "rider_sessions": {
    "rider_123": {
      "session_id": "session_abc123",
      "start_time": 1679230000000,
      "is_active": true,
      "routes_serving": ["route_789", "route_790"]
    }
  }
}
```

---

## 9. DATABASE INITIALIZATION

```sql
-- Enable PostGIS extension
CREATE EXTENSION IF NOT EXISTS postgis;
CREATE EXTENSION IF NOT EXISTS postgis_topology;

-- Create indexes for better performance
CREATE INDEX idx_users_phone_idx ON users(phone_number);
CREATE INDEX idx_riders_location_idx ON riders USING BRIN(current_location);

-- Set up auto-update timestamp trigger
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Apply trigger to all tables with updated_at
CREATE TRIGGER update_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_riders_updated_at BEFORE UPDATE ON riders
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Spatial index for better geo queries
CREATE INDEX idx_riders_location_spatial ON riders USING GIST(current_location);
CREATE INDEX idx_routes_geometry_spatial ON routes USING GIST(route_geometry);
```

---

## 10. DATABASE MIGRATION STRATEGY

**Migration Files (Laravel):**
```
migrations/
  2026_03_22_000001_create_users_table.php
  2026_03_22_000002_create_riders_table.php
  2026_03_22_000003_create_routes_table.php
  2026_03_22_000004_create_ride_logs_table.php
  2026_03_22_000005_create_ratings_table.php
  2026_03_22_000006_create_admin_tables.php
  2026_03_22_000007_add_spatial_indexes.php
```

**Key Constraints:**
- Foreign keys with CASCADE delete for related data
- UNIQUE constraints for phone numbers, emails
- CHECK constraints for ratings (1-5), status enums
- PostGIS GEOMETRY types for location data

