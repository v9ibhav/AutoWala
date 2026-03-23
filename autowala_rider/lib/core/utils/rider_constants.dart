/// Constants for AutoWala Rider App
class RiderConstants {
  // App Information
  static const String appName = 'AutoWala Rider';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Simple and clean interface for auto-rickshaw drivers';

  // API Configuration
  static const String baseApiUrl = 'https://api.autowala.com';
  static const String apiVersion = 'v1';
  static const Duration apiTimeout = Duration(seconds: 30);

  // Firebase Configuration
  static const String firebaseProjectId = 'autowala-production';
  static const String firebaseRealTimeDb = 'autowala-rider-tracking';

  // Location Settings
  static const double defaultLatitude = 19.0760;
  static const double defaultLongitude = 72.8777; // Mumbai coordinates
  static const int locationUpdateIntervalSeconds =
      10; // Update location every 10 seconds when online
  static const int minimumLocationAccuracy = 15; // meters
  static const int locationTimeoutSeconds = 30;

  // Ride Settings
  static const int maxPassengersPerRide = 3;
  static const double maxRideDistanceKm = 50.0;
  static const int rideRequestTimeoutMinutes = 5;

  // Driver Status
  static const String statusOffline = 'offline';
  static const String statusOnline = 'online';
  static const String statusInRide = 'in_ride';
  static const String statusBreak = 'break';

  // UI Settings
  static const double cardBorderRadius = 16.0;
  static const double buttonHeight = 56.0;
  static const double inputHeight = 48.0;
  static const double screenPadding = 24.0;

  // Validation
  static const int minPasswordLength = 6;
  static const int otpLength = 6;

  // Notifications
  static const String defaultNotificationChannelId =
      'autowala_rider_notifications';
  static const String defaultNotificationChannelName = 'AutoWala Rider';
  static const String rideNotificationChannelId = 'autowala_ride_updates';
  static const String rideNotificationChannelName = 'Ride Updates';

  // Storage Keys
  static const String keyAccessToken = 'access_token';
  static const String keyRefreshToken = 'refresh_token';
  static const String keyUserData = 'user_data';
  static const String keyRiderProfile = 'rider_profile';
  static const String keyLastLocation = 'last_location';
  static const String keyOnlineStatus = 'online_status';

  // Background Services
  static const String locationServiceTaskName = 'location_update_task';
  static const Duration backgroundLocationInterval = Duration(seconds: 15);

  // Error Messages
  static const String genericErrorMessage =
      'Something went wrong. Please try again.';
  static const String networkErrorMessage =
      'Please check your internet connection and try again.';
  static const String locationErrorMessage =
      'Unable to access location. Please enable location services.';
  static const String authErrorMessage =
      'Authentication failed. Please login again.';

  // Success Messages
  static const String loginSuccessMessage = 'Login successful! Welcome back.';
  static const String onlineSuccessMessage =
      'You are now online and ready for rides!';
  static const String offlineSuccessMessage = 'You are now offline. Stay safe!';

  // Currency
  static const String currencySymbol = '₹';
  static const String currencyCode = 'INR';

  // Date Formats
  static const String dateFormat = 'dd MMM yyyy';
  static const String timeFormat = 'hh:mm a';
  static const String dateTimeFormat = 'dd MMM yyyy, hh:mm a';

  // File Sizes (for KYC uploads)
  static const int maxFileSize = 5 * 1024 * 1024; // 5 MB
  static const List<String> allowedImageFormats = ['jpg', 'jpeg', 'png'];

  // KYC Document Types
  static const String kycAadhaar = 'aadhaar';
  static const String kycDrivingLicense = 'driving_license';
  static const String kycVehicleRegistration = 'vehicle_registration';
  static const String kycPhotoSelfie = 'photo_selfie';

  // Regex Patterns
  static const String phoneRegex = r'^[6-9]\d{9}$';
  static const String emailRegex =
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String vehicleNumberRegex =
      r'^[A-Z]{2}[0-9]{1,2}[A-Z]{1,2}[0-9]{4}$';

  // Shared Preferences Keys
  static const String keyFirstTimeUser = 'first_time_user';
  static const String keyNotificationEnabled = 'notification_enabled';
  static const String keyLocationPermissionAsked = 'location_permission_asked';
  static const String keyKycCompleted = 'kyc_completed';
}
