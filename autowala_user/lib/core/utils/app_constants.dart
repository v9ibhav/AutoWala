import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppConstants {
  // App Information
  static const String appName = 'AutoWala';
  static const String appDescription = 'Premium Ride Discovery Platform';
  static const String version = '1.0.0';
  static const String buildNumber = '1';

  // Environment
  static bool get isDebugMode => kDebugMode;
  static bool get isReleaseMode => kReleaseMode;
  static bool get isProfileMode => kProfileMode;

  // API Configuration
  static const String baseUrl = 'https://api.autowala.in';
  static const String apiVersion = 'v1';
  static const String apiBaseUrl = '$baseUrl/api/$apiVersion';

  // Endpoints
  static const String authEndpoint = '$apiBaseUrl/auth';
  static const String ridesEndpoint = '$apiBaseUrl/rides';
  static const String userEndpoint = '$apiBaseUrl/user';

  // Google Maps Configuration
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
  static const double defaultZoom = 16.0;
  static const double defaultLocationZoom = 18.0;

  // Firebase Configuration
  static const String firebaseProjectId = 'autowala-ride-discovery';
  static const String firebaseDatabaseUrl =
      'https://autowala-ride-discovery-default-rtdb.asia-southeast1.firebasedatabase.app/';

  // Location Configuration
  static const double defaultLatitude = 19.0760; // Mumbai
  static const double defaultLongitude = 72.8777;
  static const double searchRadiusKm = 5.0;
  static const double maxSearchRadiusKm = 25.0;
  static const int locationUpdateIntervalMs = 5000; // 5 seconds

  // UI Configuration
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration fastAnimationDuration = Duration(milliseconds: 150);
  static const Duration slowAnimationDuration = Duration(milliseconds: 500);

  // Timeouts
  static const Duration networkTimeout = Duration(seconds: 30);
  static const Duration shortTimeout = Duration(seconds: 10);
  static const Duration longTimeout = Duration(minutes: 2);

  // Cache Configuration
  static const Duration cacheTimeout = Duration(minutes: 30);
  static const int maxCacheSize = 50; // Number of items
  static const Duration imageCacheTimeout = Duration(days: 7);

  // Rate Limiting
  static const int maxOtpAttempts = 3;
  static const Duration otpResendDelay = Duration(minutes: 1);
  static const int maxLocationUpdatesPerMinute = 12;

  // Business Logic
  static const int minPassengers = 1;
  static const int maxPassengers = 3;
  static const double baseFareAmount = 30.0;
  static const String defaultCurrency = 'INR';
  static const String currencySymbol = '₹';

  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String userDataKey = 'user_data';
  static const String settingsKey = 'app_settings';
  static const String locationPermissionKey = 'location_permission_granted';
  static const String onboardingCompleteKey = 'onboarding_complete';

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
  static const String noRidersFoundMessage =
      'No auto-rickshaws found nearby. Try expanding your search radius.';

  // Success Messages
  static const String otpSentMessage =
      'OTP sent successfully to your phone number.';
  static const String rideBookedMessage = 'Auto-rickshaw booked successfully!';
  static const String locationUpdatedMessage = 'Location updated successfully.';

  // Validation
  static const int minPhoneNumberLength = 10;
  static const int maxPhoneNumberLength = 10;
  static const int otpLength = 6;
  static const String phoneNumberPattern =
      r'^[6-9]\d{9}$'; // Indian mobile numbers

  // Map Styling
  static const String mapStyleDay = '''[
    {
      "featureType": "all",
      "elementType": "geometry.fill",
      "stylers": [
        {
          "weight": "2.00"
        }
      ]
    },
    {
      "featureType": "all",
      "elementType": "geometry.stroke",
      "stylers": [
        {
          "color": "#9c9c9c"
        }
      ]
    },
    {
      "featureType": "all",
      "elementType": "labels.text",
      "stylers": [
        {
          "visibility": "on"
        }
      ]
    }
  ]''';

  // Performance
  static const int imageCompressionQuality = 80;
  static const Duration debounceDelay = Duration(milliseconds: 500);
  static const int maxRetryAttempts = 3;

  // Auto-Rickshaw Specifications
  static const double averageAutoSpeed = 25.0; // km/h
  static const double averageAutoSpeedTraffic = 15.0; // km/h in heavy traffic
  static const double walkingSpeed = 5.0; // km/h
  static const double maxWalkingDistance = 1.0; // km

  // Ride Categories
  static const List<String> rideTypes = ['Auto-Rickshaw'];
  static const Map<String, String> vehicleTypes = {
    'auto': 'Auto-Rickshaw',
    'shared_auto': 'Shared Auto-Rickshaw',
  };

  // App Links
  static const String privacyPolicyUrl = 'https://autowala.in/privacy';
  static const String termsOfServiceUrl = 'https://autowala.in/terms';
  static const String supportUrl = 'https://autowala.in/support';
  static const String playStoreUrl =
      'https://play.google.com/store/apps/details?id=in.autowala.user';

  // Emergency
  static const String emergencyNumber = '112'; // India's emergency number
  static const List<String> emergencyContacts = ['100', '101', '102', '112'];

  // Feature Flags
  static const bool enableRealTimeTracking = true;
  static const bool enablePushNotifications = true;
  static const bool enableCrashlytics = true;
  static const bool enableAnalytics = true;

  // Device Support
  static const double minScreenWidth = 320.0;
  static const double minScreenHeight = 568.0;
  static const List<String> supportedPlatforms = ['android', 'ios'];

  // Asset Paths
  static const String imagesPath = 'assets/images/';
  static const String iconsPath = 'assets/icons/';
  static const String animationsPath = 'assets/animations/';
  static const String logosPath = 'assets/logos/';

  // Image Assets
  static const String appLogoPath = '${logosPath}logo.png';
  static const String splashLogoPath = '${logosPath}splash_logo.png';
  static const String autoRickshawIconPath = '${iconsPath}auto_rickshaw.png';
  static const String mapMarkerPath = '${iconsPath}map_marker.png';

  // Animation Assets
  static const String loadingAnimationPath = '${animationsPath}loading.json';
  static const String successAnimationPath = '${animationsPath}success.json';
  static const String errorAnimationPath = '${animationsPath}error.json';

  // Notifications
  static const String notificationChannelId = 'autowala_rides';
  static const String notificationChannelName = 'Ride Updates';
  static const String notificationChannelDescription =
      'Notifications about your rides and auto-rickshaw updates';

  // Quality Settings based on device tier
  static const Map<String, Map<String, dynamic>> qualitySettings = {
    'high': {
      'mapQuality': 'high',
      'animationsEnabled': true,
      'imageQuality': 100,
      'locationUpdateInterval': 3000,
    },
    'medium': {
      'mapQuality': 'medium',
      'animationsEnabled': true,
      'imageQuality': 80,
      'locationUpdateInterval': 5000,
    },
    'low': {
      'mapQuality': 'low',
      'animationsEnabled': false,
      'imageQuality': 60,
      'locationUpdateInterval': 10000,
    },
  };
}

/// Region-specific constants for India
class IndiaConstants {
  // Major Cities
  static const Map<String, Map<String, double>> majorCities = {
    'mumbai': {'lat': 19.0760, 'lon': 72.8777},
    'delhi': {'lat': 28.7041, 'lon': 77.1025},
    'bangalore': {'lat': 12.9716, 'lon': 77.5946},
    'hyderabad': {'lat': 17.3850, 'lon': 78.4867},
    'pune': {'lat': 18.5204, 'lon': 73.8567},
    'kolkata': {'lat': 22.5726, 'lon': 88.3639},
    'chennai': {'lat': 13.0827, 'lon': 80.2707},
    'ahmedabad': {'lat': 23.0225, 'lon': 72.5714},
    'jaipur': {'lat': 26.9124, 'lon': 75.7873},
    'surat': {'lat': 21.1702, 'lon': 72.8311},
  };

  // Country bounds for India
  static const double northLat = 37.6;
  static const double southLat = 6.4;
  static const double westLon = 68.1;
  static const double eastLon = 97.4;

  // Common auto-rickshaw brands
  static const List<String> autoRickshawBrands = [
    'Bajaj',
    'Mahindra',
    'Piaggio',
    'TVS',
    'Force',
  ];

  // State codes
  static const Map<String, String> stateCodes = {
    'maharashtra': 'MH',
    'delhi': 'DL',
    'karnataka': 'KA',
    'telangana': 'TS',
    'gujarat': 'GJ',
    'tamil_nadu': 'TN',
    'west_bengal': 'WB',
    'rajasthan': 'RJ',
    'uttar_pradesh': 'UP',
    'punjab': 'PB',
  };
}

/// Device-specific configuration
class DeviceConstants {
  // Screen size breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Performance tiers based on device capabilities
  static const Map<String, String> performanceTiers = {
    'low_end': 'Devices with <3GB RAM',
    'mid_tier': 'Devices with 3-6GB RAM',
    'high_end': 'Devices with >6GB RAM',
  };
}
