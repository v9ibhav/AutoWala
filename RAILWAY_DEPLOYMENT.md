# 🎯 Railway.app - Complete Deployment Guide (30 Minutes)

## Why Railway.app?

- ✅ **Easiest:** Just connect GitHub, click deploy
- ✅ **Cheapest:** $0 trial, then $10-20/month (vs $560+ on AWS)
- ✅ **Automatic:** Database, Redis, SSL all included
- ✅ **No DevOps:** No server management needed
- ✅ **Auto-deploy:** Push to GitHub = Auto deploy

---

## Part 1: Upload to GitHub (10 minutes)

### Step 1.1: Create GitHub Repository

1. **Open browser:** https://github.com
2. **Login** to your account
3. **Click the `+` icon** (top right corner) → **"New repository"**
4. **Fill in:**
   - Repository name: `autowala`
   - Description: `AutoWala ride discovery platform`
   - Make it **Private** (recommended)
   - **DO NOT** check "Initialize with README"
5. **Click "Create repository"**

### Step 1.2: Push Your Code

Open terminal in your project:

```bash
cd e:\AutoWala

# Initialize git
git init

# Add all files
git add .

# Create first commit
git commit -m "Initial commit - AutoWala production code"

# Rename branch to main
git branch -M main

# Add your GitHub repository (REPLACE YOUR_USERNAME!)
git remote add origin https://github.com/YOUR_USERNAME/autowala.git

# Push to GitHub
git push -u origin main
```

**Verify:** Refresh GitHub page - you should see all your files!

---

## Part 2: Setup Firebase (15 minutes)

### Step 2.1: Create Firebase Project

1. **Go to:** https://console.firebase.google.com
2. **Click "Add project"** (or "Create a project")
3. **Project name:** `autowala-production`
4. **Disable Google Analytics** (optional - easier without it)
5. **Click "Create project"**
6. **Wait 30 seconds** for it to create
7. **Click "Continue"**

### Step 2.2: Enable Realtime Database

1. In left sidebar, click **"Build"** → **"Realtime Database"**
2. Click **"Create Database"** button
3. **Location:** Choose `asia-southeast1 (Singapore)` - closest to India
4. **Security rules:** Start in **"Locked mode"** (we'll configure later)
5. Click **"Enable"**

**Copy the Database URL!** It looks like:
```
https://autowala-production-default-rtdb.asia-southeast1.firebasedatabase.app
```

### Step 2.3: Get Web API Key

1. Click the **⚙️ Settings icon** (top left) → **"Project settings"**
2. Scroll down to **"Your apps"** section
3. Click the **`</>`** icon (Web app)
4. **App nickname:** `AutoWala Web`
5. **DO NOT** check "Also set up Firebase Hosting"
6. Click **"Register app"**
7. **Copy the `apiKey` value** (starts with `AIza...`)

### Step 2.4: Download Service Account

1. Still in **"Project settings"**
2. Click **"Service accounts"** tab (top)
3. Click **"Generate new private key"** button
4. Click **"Generate key"** in confirmation dialog
5. **Save the downloaded file** as: `firebase-service-account.json`
6. **Keep this file safe** - you'll upload it later

**What you should have now:**
- ✅ Firebase Database URL
- ✅ Firebase Web API Key
- ✅ firebase-service-account.json file

---

## Part 3: Setup Google Maps (15 minutes)

### Step 3.1: Create Google Cloud Project

1. **Go to:** https://console.cloud.google.com
2. **Click project dropdown** (top left, says "Select a project")
3. Click **"New Project"** (top right)
4. **Project name:** `autowala-maps`
5. Click **"Create"**
6. **Wait for project to be created** (notification bell shows progress)

### Step 3.2: Enable Required APIs

1. In left menu, click **"APIs & Services"** → **"Library"**
2. **Enable these 6 APIs** (one by one):

   **API 1: Maps SDK for Android**
   - Search: `Maps SDK for Android`
   - Click on it
   - Click **"Enable"**
   - Wait 30 seconds

   **API 2: Maps SDK for iOS**
   - Click **"Go back"**
   - Search: `Maps SDK for iOS`
   - Click **"Enable"**

   **API 3: Places API**
   - Click **"Go back"**
   - Search: `Places API`
   - Click **"Enable"**

   **API 4: Directions API**
   - Click **"Go back"**
   - Search: `Directions API`
   - Click **"Enable"**

   **API 5: Distance Matrix API**
   - Click **"Go back"**
   - Search: `Distance Matrix API`
   - Click **"Enable"**

   **API 6: Geocoding API**
   - Click **"Go back"**
   - Search: `Geocoding API`
   - Click **"Enable"**

### Step 3.3: Create API Key (Backend)

1. Go to **"APIs & Services"** → **"Credentials"**
2. Click **"+ Create Credentials"** → **"API key"**
3. **Copy the key immediately!** (starts with `AIza...`)
4. Click **"Restrict Key"** (don't skip this!)
5. **Name:** `AutoWala Backend`
6. Under **"API restrictions":**
   - Select **"Restrict key"**
   - Check these APIs:
     - ✅ Places API
     - ✅ Directions API
     - ✅ Distance Matrix API
     - ✅ Geocoding API
7. Click **"Save"**

**Save this key as "Backend API Key"**

### Step 3.4: Create API Key (Android)

1. Click **"+ Create Credentials"** → **"API key"**
2. **Copy the key!**
3. Click **"Restrict Key"**
4. **Name:** `AutoWala Android`
5. Under **"Application restrictions":**
   - Select **"Android apps"**
   - Click **"Add an item"**
   - **Package name:** `com.autowala.user`
   - **SHA-1:** Leave blank for now (add later from Android Studio)
   - Click **"Done"**
6. Under **"API restrictions":**
   - Select **"Restrict key"**
   - Check:
     - ✅ Maps SDK for Android
     - ✅ Places API
7. Click **"Save"**

**Save this as "Android API Key"**

### Step 3.5: Create API Key (iOS)

1. Click **"+ Create Credentials"** → **"API key"**
2. **Copy the key!**
3. Click **"Restrict Key"**
4. **Name:** `AutoWala iOS`
5. Under **"Application restrictions":**
   - Select **"iOS apps"**
   - Click **"Add an item"**
   - **Bundle ID:** `com.autowala.user`
   - Click **"Done"**
6. Under **"API restrictions":**
   - Select **"Restrict key"**
   - Check:
     - ✅ Maps SDK for iOS
     - ✅ Places API
7. Click **"Save"**

**Save this as "iOS API Key"**

### Step 3.6: Enable Billing (Required)

1. Click **"☰"** (hamburger menu) → **"Billing"**
2. Click **"Link a billing account"**
3. **Add payment method** (credit/debit card)
4. **Don't worry:** Google Maps has **$200 free credit every month**
5. For starting, you won't exceed this

**What you should have now:**
- ✅ Backend/Web API Key
- ✅ Android API Key
- ✅ iOS API Key

---

## Part 4: Deploy on Railway.app (15 minutes)

### Step 4.1: Sign Up on Railway

1. **Go to:** https://railway.app
2. Click **"Login"** (top right)
3. Click **"Login with GitHub"**
4. **Authorize Railway** to access your GitHub
5. You'll be redirected to Railway dashboard

### Step 4.2: Create New Project

1. Click **"New Project"** (center or top right)
2. Click **"Deploy from GitHub repo"**
3. If asked, click **"Configure GitHub App"**
4. Select your GitHub account
5. Choose **"Only select repositories"**
6. Select **"autowala"** repository
7. Click **"Install & Authorize"**

### Step 4.3: Deploy Backend Service

1. Back in Railway, select **autowala** repo
2. It will ask **"Which directory to deploy?"**
3. Click **"Add Service"** → **"GitHub Repo"**
4. Select **autowala** repository
5. In the service settings:
   - **Name:** Change to `autowala-backend`
   - **Root Directory:** Click edit, enter `/autowala-backend`
   - **Builder:** Should automatically detect Dockerfile
6. Click **"Deploy"**

**Wait 2-3 minutes** for initial deployment (watch logs in **"Deployments"** tab)

### Step 4.4: Add PostgreSQL Database

1. In your Railway project, click **"+ New"** (top right)
2. Click **"Database"**
3. Click **"Add PostgreSQL"**
4. Railway automatically creates database!
5. Click on the **PostgreSQL service**
6. Click **"Variables"** tab
7. **Copy the `DATABASE_URL`** value - you'll need it!

**Important: Enable PostGIS**
1. In PostgreSQL service → **"Data"** tab
2. Click **"Connect"**
3. This opens a psql console
4. Run:
   ```sql
   CREATE EXTENSION IF NOT EXISTS postgis;
   SELECT PostGIS_version();
   ```
5. You should see version number - PostGIS is enabled! ✅

### Step 4.5: Add Redis Cache

1. Click **"+ New"** → **"Database"** → **"Add Redis"**
2. Done! Railway auto-configures it
3. Click on Redis service → **"Variables"**
4. **Copy the `REDIS_URL`** value

### Step 4.6: Configure Backend Environment Variables

1. Click on **autowala-backend** service
2. Click **"Variables"** tab
3. Click **"+ New Variable"** button
4. **Add these variables ONE BY ONE:**

```bash
# Application
APP_ENV=production
APP_DEBUG=false
APP_URL=${{RAILWAY_PUBLIC_DOMAIN}}

# Database (Auto-linked by Railway, but Laravel needs individual vars)
DB_CONNECTION=pgsql
DB_HOST=${{Postgres.PGHOST}}
DB_PORT=${{Postgres.PGPORT}}
DB_DATABASE=${{Postgres.PGDATABASE}}
DB_USERNAME=${{Postgres.PGUSER}}
DB_PASSWORD=${{Postgres.PGPASSWORD}}

# Redis (Auto-linked)
REDIS_HOST=${{Redis.REDIS_HOST}}
REDIS_PORT=${{Redis.REDIS_PORT}}
REDIS_PASSWORD=${{Redis.REDIS_PASSWORD}}
CACHE_DRIVER=redis
SESSION_DRIVER=redis
QUEUE_CONNECTION=redis

# Firebase (Your values!)
FIREBASE_PROJECT_ID=autowala-production
FIREBASE_DATABASE_URL=https://autowala-production-default-rtdb.asia-southeast1.firebasedatabase.app
FIREBASE_WEB_API_KEY=AIzaSy...YOUR_KEY_HERE

# Google Maps (Your Backend key!)
GOOGLE_MAPS_API_KEY=AIzaSy...YOUR_BACKEND_KEY_HERE

# Laravel will generate this
APP_KEY=base64:...WILL_GENERATE_BELOW
```

**Replace the `...YOUR_KEY_HERE` parts with your actual keys from Part 2 & 3!**

### Step 4.7: Generate APP_KEY

1. In **autowala-backend** service → **"Deployments"** tab
2. Click **"View Logs"** on latest deployment
3. Wait for deployment to complete
4. Click **"Deploy"** tab → **"⚙️"** (settings) → **"Custom Start Command"**
5. Temporarily change to:
   ```bash
   php artisan key:generate --show
   ```
6. Click **"Deploy"** (it will redeploy)
7. Watch logs - you'll see output like:
   ```
   base64:SOME_LONG_STRING_HERE
   ```
8. **Copy this entire string** (including `base64:`)
9. Go to **"Variables"** tab
10. Find `APP_KEY` and paste the value
11. Go back to **"Settings"** → **"Custom Start Command"**
12. Remove it (leave blank for default)
13. Click **"Deploy"** again

### Step 4.8: Run Database Migrations

1. In **autowala-backend** service → **"Settings"**
2. Under **"Deploy"** section, find **"Custom Start Command"**
3. Add:
   ```bash
   php artisan migrate --force && php artisan optimize && php artisan serve --host=0.0.0.0 --port=$PORT
   ```
4. Click **"Deploy"**
5. Watch logs - migrations will run automatically!

### Step 4.9: Enable Public Access

1. In **autowala-backend** service → **"Settings"**
2. Under **"Networking"**, click **"Generate Domain"**
3. Railway gives you a URL like:
   ```
   https://autowala-backend-production-1a2b.up.railway.app
   ```
4. **Copy this URL** - this is your API URL!
5. Test it: Open in browser - you should see Laravel default page or API response

### Step 4.10: Deploy Admin Panel

1. In Railway project, click **"+ New"** → **"GitHub Repo"**
2. Select **autowala** repository
3. Configure service:
   - **Name:** `autowala-admin`
   - **Root Directory:** `/autowala-admin`
4. Add **Variables:**
   ```bash
   VITE_API_URL=https://YOUR-BACKEND-URL-FROM-STEP-4.9.up.railway.app
   ```
5. Click **"Settings"** → **"Networking"** → **"Generate Domain"**
6. **Copy this URL** - this is your Admin Panel URL!

**Your Admin Panel will auto-deploy!**

---

## Part 5: Test Your Deployment (5 minutes)

### Step 5.1: Test Backend API

Open in browser or use curl:
```bash
curl https://your-backend-url.up.railway.app/api/health
```

Should return:
```json
{"status":"healthy","database":"connected"}
```

### Step 5.2: Test Admin Panel

Open your admin URL in browser:
```
https://your-admin-url.up.railway.app
```

You should see the admin login page!

### Step 5.3: Check Logs

If something doesn't work:
1. Go to Railway → Click service
2. **"Deployments"** tab → Latest deployment → **"View Logs"**
3. Look for errors in red

---

## Part 6: Update Mobile Apps (10 minutes)

### Step 6.1: Update User App

Edit `autowala_user/lib/config/app_config.dart`:

```dart
class AppConfig {
  // Replace with YOUR Railway backend URL
  static const String apiBaseUrl = 'https://your-backend-url.up.railway.app';
  static const String environment = 'production';

  // Firebase
  static const String firebaseDatabaseUrl =
    'https://autowala-production-default-rtdb.asia-southeast1.firebasedatabase.app';

  // Google Maps - YOUR Android key
  static const String googleMapsApiKey = 'AIzaSy...YOUR_ANDROID_KEY';
}
```

### Step 6.2: Update iOS App

Edit `autowala_user/ios/Runner/AppDelegate.swift`:

Add your iOS Maps key:
```swift
GMSServices.provideAPIKey("YOUR_IOS_KEY_HERE")
```

### Step 6.3: Update Android App

Edit `autowala_user/android/app/src/main/AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="YOUR_ANDROID_KEY_HERE"/>
```

### Step 6.4: Do Same for Rider App

Repeat for `autowala_rider/` folder.

### Step 6.5: Build APK

```bash
cd autowala_user
flutter pub get
flutter build apk --release

# APK at: build/app/outputs/flutter-apk/app-release.apk
```

---

## Part 7: Enable Auto-Deploy (5 minutes)

### Step 7.1: Commit and Push

```bash
cd e:\AutoWala
git add .
git commit -m "Configure production URLs and API keys"
git push origin main
```

### Step 7.2: Auto-Deploy Activated!

Railway automatically detects the push and redeploys! 🎉

From now on:
- **Push to main** = **Auto deploy** on Railway
- No manual work needed!

---

## ✅ Deployment Complete!

### What You Have Now:

- ✅ Backend API running on Railway
- ✅ Admin Panel running on Railway
- ✅ PostgreSQL database with PostGIS
- ✅ Redis cache
- ✅ Auto SSL certificates
- ✅ Auto-deploy from GitHub
- ✅ Monitoring and logs
- ✅ Mobile apps configured and built

### Your URLs:

- **API:** `https://your-backend.up.railway.app`
- **Admin:** `https://your-admin.up.railway.app`
- **Railway Dashboard:** https://railway.app/dashboard

---

## 💰 Pricing on Railway

### Free Trial:
- $5 free credit
- Enough for 1-2 days of testing

### After Trial (Pay-as-you-go):
- **PostgreSQL:** ~$5/month
- **Redis:** ~$2/month
- **Backend App:** ~$3-8/month (depends on usage)
- **Admin App:** ~$2-5/month
- **Total:** ~$12-20/month

**Much cheaper than AWS ($560+/month)!**

---

## 🎓 Next Steps

### 1. Create Admin User

In Railway → autowala-backend → Deployments → View Logs → Click into container:

```bash
php artisan tinker

# Then run:
User::create([
    'name' => 'Admin',
    'email' => 'admin@autowala.com',
    'password' => bcrypt('password123'),
    'role' => 'admin'
]);
```

### 2. Configure Firebase Security Rules

In Firebase Console → Realtime Database → Rules:

```json
{
  "rules": {
    "locations": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "rides": {
      ".read": "auth != null",
      ".write": "auth != null"
    }
  }
}
```

### 3. Test Mobile Apps

Install APK on your phone and test!

### 4. Monitor Usage

Railway Dashboard shows:
- CPU/Memory usage
- Database queries
- Logs
- Costs

---

## 🔧 Troubleshooting

### Database Connection Failed?

Check Variables tab - make sure `DB_HOST`, `DB_PORT`, etc. are set correctly using Railway's variable references: `${{Postgres.PGHOST}}`

### Migrations Not Running?

1. Check logs for errors
2. Manually run in Railway shell:
   ```bash
   php artisan migrate --force
   ```

### App Not Accessible?

Make sure you generated a public domain in Settings → Networking

### 500 Error?

Check logs in Deployments tab - usually APP_KEY not set or database connection issue

---

## 📞 Need Help?

- **Railway Discord:** https://discord.gg/railway
- **Railway Docs:** https://docs.railway.app
- **AutoWala Support:** vaibhavka49@gmail.com

---

## 🎉 Congratulations!

Your AutoWala platform is now **live on Railway** and:
- Costs **50x less** than AWS
- Was **10x easier** to set up
- Auto-deploys from GitHub
- Scales automatically

**Start testing and get your first users!** 🚀

When you grow to 50k+ users, you can migrate to AWS using the `EXACT_STEP_BY_STEP_GUIDE.md`
