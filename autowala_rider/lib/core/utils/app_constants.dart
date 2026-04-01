import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppConstants {
  // App Information
  static const String appName = 'AutoWala Rider';
  static const String appDescription = 'AutoWala Driver Partner App';
  static const String version = '1.0.0';
  static const String appVersion = version;
  static const String buildNumber = '1';

  // Environment
  static bool get isDebugMode => kDebugMode;
  static bool get isReleaseMode => kReleaseMode;
  static bool get isProfileMode => kProfileMode;

  // API Configuration - Railway deployment URL
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://autowala-backend-production.up.railway.app',
  );
  static const String apiVersion = 'v1';
  static const String apiBaseUrl = '$baseUrl/api/$apiVersion';

  // Endpoints
  static const String authEndpoint = '$apiBaseUrl/rider/auth';
  static const String ridesEndpoint = '$apiBaseUrl/rider/rides';
  static const String riderEndpoint = '$apiBaseUrl/rider';

  // Google Maps Configuration
  static const String googleMapsApiKey =
      'AIzaSyBdVl-cGnaq2rt_HEHhoqa_SkGBMiMeBiE'; // Demo key - Update with real key later
  static const double defaultZoom = 16.0;
  static const double defaultLocationZoom = 18.0;

  // Firebase Configuration
  static const String firebaseProjectId = 'autowala-6610e';
  static const String firebaseDatabaseUrl =
      'https://autowala-6610e-default-rtdb.firebaseio.com/';

  // Location Configuration
  static const double defaultLatitude = 19.0760; // Mumbai
  static const double defaultLongitude = 72.8777;
  static const double trackingRadiusKm =
      10.0; // How far riders can accept rides
  static const int locationUpdateIntervalMs = 3000; // 3 seconds for riders
  static const int backgroundLocationIntervalMs =
      10000; // 10 seconds in background

  // UI Configuration
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration fastAnimationDuration = Duration(milliseconds: 150);
  static const Duration slowAnimationDuration = Duration(milliseconds: 500);

  // Timeouts
  static const Duration networkTimeout = Duration(seconds: 30);
  static const Duration shortTimeout = Duration(seconds: 10);
  static const Duration longTimeout = Duration(minutes: 2);
  static const Duration rideRequestTimeout =
      Duration(seconds: 15); // Time to respond to ride requests

  // Cache Configuration
  static const Duration cacheTimeout = Duration(minutes: 15);
  static const int maxCacheSize = 100;
  static const Duration imageCacheTimeout = Duration(days: 7);

  // Rate Limiting
  static const int maxOtpAttempts = 3;
  static const Duration otpResendDelay = Duration(minutes: 1);
  static const int maxLocationUpdatesPerMinute = 20; // Higher for riders

  // Business Logic - Rider Specific
  static const double rideAcceptanceRadiusKm =
      5.0; // Max distance to accept rides
  static const Duration onlineStatusTimeout =
      Duration(minutes: 5); // Auto offline after inactivity
  static const int maxConsecutiveRejections = 3; // Before temporary suspension
  static const Duration rejectionPenaltyDuration = Duration(minutes: 10);

  // Earnings
  static const double baseFarePerRide = 30.0;
  static const double commissionPercentage = 15.0; // Platform commission
  static const String defaultCurrency = 'INR';
  static const String currencySymbol = '₹';

  // Storage Keys
  static const String authTokenKey = 'rider_auth_token';
  static const String riderDataKey = 'rider_data';
  static const String settingsKey = 'rider_app_settings';
  static const String locationPermissionKey = 'location_permission_granted';
  static const String onboardingCompleteKey = 'rider_onboarding_complete';
  static const String onlineStatusKey = 'rider_online_status';
  static const String vehicleDataKey = 'rider_vehicle_data';
  static const String currentRideKey = 'current_active_ride';

  // Localization
  static const Locale defaultLocale = Locale('en', 'IN');
  static const List<Locale> supportedLocales = [
    Locale('en', 'IN'), // English (India)
    Locale('hi', 'IN'), // Hindi (India)
  ];

  // Error Messages
  static const String networkErrorMessage =
      'Please check your internet connection and try again.';
  static const String locationErrorMessage =
      'Unable to get your location. Please check permissions.';
  static const String unknownErrorMessage =
      'Something went wrong. Please try again.';
  static const String rideRequestExpiredMessage = 'Ride request has expired.';
  static const String noActiveRideMessage = 'No active ride found.';

  // Success Messages
  static const String otpSentMessage =
      'OTP sent successfully to your phone number.';
  static const String rideAcceptedMessage = 'Ride accepted successfully!';
  static const String locationUpdatedMessage = 'Location updated successfully.';
  static const String wentOnlineMessage =
      'You are now online and accepting rides.';
  static const String wentOfflineMessage = 'You are now offline.';

  // Validation
  static const int minPhoneNumberLength = 10;
  static const int maxPhoneNumberLength = 10;
  static const int otpLength = 6;
  static const String phoneNumberPattern =
      r'^[6-9]\d{9}$'; // Indian mobile numbers

  // Map Styling
  static const String mapStyleDay = '''[
    {
      "featureType": "poi.business",
      "stylers": [{"visibility": "off"}]
    },
    {
      "featureType": "poi.park",
      "elementType": "labels.text",
      "stylers": [{"visibility": "off"}]
    },
    {
      "featureType": "road",
      "elementType": "geometry.stroke",
      "stylers": [{"color": "#2E7D32", "weight": 0.8}]
    },
    {
      "featureType": "transit",
      "stylers": [{"visibility": "off"}]
    }
  ]''';

  // Performance
  static const int imageCompressionQuality = 85;
  static const Duration debounceDelay =
      Duration(milliseconds: 300); // Faster for rider interactions
  static const int maxRetryAttempts = 3;

  // Rider Status
  static const List<String> riderStatuses = [
    'offline',
    'online',
    'busy',
    'break'
  ];
  static const Map<String, String> statusLabels = {
    'offline': 'Offline',
    'online': 'Online - Available',
    'busy': 'Busy - On Trip',
    'break': 'On Break',
  };

  // Vehicle Types
  static const List<String> supportedVehicleTypes = ['auto_rickshaw', 'taxi'];
  static const Map<String, Map<String, dynamic>> vehicleConfig = {
    'auto_rickshaw': {
      'name': 'Auto Rickshaw',
      'maxPassengers': 3,
      'fuelType': 'CNG/Petrol',
      'avgSpeed': 25, // km/h
    },
    'taxi': {
      'name': 'Taxi',
      'maxPassengers': 4,
      'fuelType': 'Petrol/Diesel',
      'avgSpeed': 35, // km/h
    },
  };

  // App Links
  static const String privacyPolicyUrl = 'https://autowala.in/rider/privacy';
  static const String termsOfServiceUrl = 'https://autowala.in/rider/terms';
  static const String supportUrl = 'https://autowala.in/rider/support';
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=in.autowala.rider';

  // Emergency
  static const String emergencyNumber = '112';
  static const List<String> emergencyContacts = ['100', '101', '102', '112'];

  // Feature Flags
  static const bool enableRealTimeTracking = true;
  static const bool enablePushNotifications = true;
  static const bool enableCrashlytics = true;
  static const bool enableAnalytics = true;
  static const bool enableAutoStartRide = false; // Auto-start when near pickup
  static const bool enableOfflineMode =
      true; // Cache rides for offline handling

  // Device Support
  static const double minScreenWidth = 320.0;
  static const double minScreenHeight = 568.0;
  static const List<String> supportedPlatforms = ['android', 'ios'];

  // Asset Paths
  static const String imagesPath = 'assets/images/';
  static const String iconsPath = 'assets/icons/';
  static const String animationsPath = 'assets/animations/';
  static const String logosPath = 'assets/logos/';

  // Image Assets - Rider Specific
  static const String appLogoPath = '${logosPath}rider_logo.png';
  static const String splashLogoPath = '${logosPath}rider_splash_logo.png';
  static const String autoRickshawIconPath = '${iconsPath}auto_rickshaw.png';
  static const String mapMarkerPath = '${iconsPath}rider_marker.png';
  static const String onlineIconPath = '${iconsPath}online_status.png';
  static const String offlineIconPath = '${iconsPath}offline_status.png';

  // Animation Assets
  static const String loadingAnimationPath = '${animationsPath}loading.json';
  static const String successAnimationPath = '${animationsPath}success.json';
  static const String errorAnimationPath = '${animationsPath}error.json';
  static const String rideRequestAnimationPath =
      '${animationsPath}ride_request.json';

  // Notifications
  static const String notificationChannelId = 'autowala_rider_rides';
  static const String notificationChannelName = 'Ride Requests & Updates';
  static const String notificationChannelDescription =
      'Notifications about ride requests, ongoing rides, and earnings updates';

  // Quality Settings - Optimized for riders
  static const Map<String, Map<String, dynamic>> qualitySettings = {
    'high': {
      'mapQuality': 'high',
      'animationsEnabled': true,
      'imageQuality': 100,
      'locationUpdateInterval': 2000, // Very frequent for real-time tracking
      'backgroundSync': true,
    },
    'medium': {
      'mapQuality': 'medium',
      'animationsEnabled': true,
      'imageQuality': 85,
      'locationUpdateInterval': 3000,
      'backgroundSync': true,
    },
    'low': {
      'mapQuality': 'low',
      'animationsEnabled': false,
      'imageQuality': 70,
      'locationUpdateInterval': 5000,
      'backgroundSync': false,
    },
  };

  // Rider Performance Metrics
  static const Map<String, double> performanceThresholds = {
    'acceptanceRate': 0.80, // 80% minimum acceptance rate
    'cancellationRate': 0.05, // 5% maximum cancellation rate
    'avgRating': 4.0, // Minimum 4.0 rating
    'responseTime': 30.0, // 30 seconds max response time
  };

  // Compliance & Safety
  static const Duration maxDrivingHours = Duration(hours: 12); // Per day
  static const Duration mandatoryBreakDuration = Duration(minutes: 15);
  static const Duration maxContinuousDriving = Duration(hours: 4);
  static const int maxSpeedLimit = 60; // km/h for safety alerts
}
