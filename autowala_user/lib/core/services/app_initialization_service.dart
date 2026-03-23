import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../utils/logger.dart';
import '../utils/app_constants.dart';

/// Handles all app initialization tasks
/// Ensures services are ready before the UI loads
class AppInitializationService {
  static bool _isInitialized = false;
  static final List<String> _initializationSteps = [];

  /// Main initialization method
  static Future<void> initialize() async {
    if (_isInitialized) return;

    final performanceLogger = PerformanceLogger('app_initialization');

    try {
      AppLogger.info('Starting app initialization...');

      // Step 1: Initialize core services
      await _initializeCoreServices();
      performanceLogger.checkpoint('core_services');

      // Step 2: Initialize storage
      await _initializeStorage();
      performanceLogger.checkpoint('storage');

      // Step 3: Check device capabilities
      await _checkDeviceCapabilities();
      performanceLogger.checkpoint('device_capabilities');

      // Step 4: Initialize Firebase services
      await _initializeFirebase();
      performanceLogger.checkpoint('firebase');

      // Step 5: Initialize location services
      await _initializeLocationServices();
      performanceLogger.checkpoint('location');

      // Step 6: Initialize network monitoring
      await _initializeNetworkMonitoring();
      performanceLogger.checkpoint('network');

      // Step 7: Restore user session
      await _restoreUserSession();
      performanceLogger.checkpoint('session');

      _isInitialized = true;
      performanceLogger.stop('completed successfully');

      AppLogger.info('App initialization completed', {
        'steps_completed': _initializationSteps,
        'duration_ms': performanceLogger.elapsed.inMilliseconds,
      });
    } catch (error, stackTrace) {
      performanceLogger.stop('failed with error');
      AppLogger.error('App initialization failed', error, stackTrace, {
        'completed_steps': _initializationSteps,
      });
      rethrow;
    }
  }

  /// Initialize core platform services
  static Future<void> _initializeCoreServices() async {
    try {
      // Initialize device info
      final deviceInfo = DeviceInfoPlugin();

      // Store device information for analytics and debugging
      await _storeDeviceInfo(deviceInfo);

      _initializationSteps.add('core_services');
      AppLogger.info('Core services initialized');
    } catch (e) {
      AppLogger.error('Failed to initialize core services', e);
      rethrow;
    }
  }

  /// Initialize Hive and SharedPreferences
  static Future<void> _initializeStorage() async {
    try {
      // Initialize SharedPreferences
      await SharedPreferences.getInstance();

      // Register Hive adapters for custom objects
      // TODO: Add custom adapters when models are created
      // Hive.registerAdapter(UserAdapter());
      // Hive.registerAdapter(RideAdapter());

      // Open necessary Hive boxes
      await Hive.openBox('app_settings');
      await Hive.openBox('user_data');
      await Hive.openBox('cache');
      await Hive.openBox('offline_data');

      _initializationSteps.add('storage');
      AppLogger.info('Storage services initialized');
    } catch (e) {
      AppLogger.error('Failed to initialize storage', e);
      rethrow;
    }
  }

  /// Check device capabilities and performance tier
  static Future<void> _checkDeviceCapabilities() async {
    try {
      final deviceInfo = DeviceInfoPlugin();

      if (AppConstants.isReleaseMode) {
        // Check device specifications for performance optimization
        final androidInfo = await deviceInfo.androidInfo;
        final sdkVersion = androidInfo.version.sdkInt;
        final totalMemory = androidInfo.systemFeatures.length;

        // Determine performance tier based on device specs
        String performanceTier =
            _determinePerformanceTier(sdkVersion, totalMemory);

        // Store performance settings
        final settingsBox = Hive.box('app_settings');
        await settingsBox.put('performance_tier', performanceTier);
        await settingsBox.put('device_sdk', sdkVersion);

        AppLogger.info('Device capabilities checked', {
          'sdk_version': sdkVersion,
          'performance_tier': performanceTier,
        });
      }

      _initializationSteps.add('device_capabilities');
    } catch (e) {
      AppLogger.warning(
          'Failed to check device capabilities', {'error': e.toString()});
      // Non-critical, continue initialization
    }
  }

  /// Initialize Firebase services
  static Future<void> _initializeFirebase() async {
    try {
      // Initialize Firebase Messaging
      final messaging = FirebaseMessaging.instance;

      // Request notification permissions
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      // Get FCM token for push notifications
      final fcmToken = await messaging.getToken();
      if (fcmToken != null) {
        AppLogger.info('FCM token obtained', {'token_length': fcmToken.length});

        // Store FCM token
        final settingsBox = Hive.box('app_settings');
        await settingsBox.put('fcm_token', fcmToken);
      }

      // Set up message handlers
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // Initialize Crashlytics
      if (AppConstants.isReleaseMode) {
        await FirebaseCrashlytics.instance
            .setCrashlyticsCollectionEnabled(true);
      }

      _initializationSteps.add('firebase');
      AppLogger.info('Firebase services initialized');
    } catch (e) {
      AppLogger.error('Failed to initialize Firebase', e);
      rethrow;
    }
  }

  /// Initialize location services and permissions
  static Future<void> _initializeLocationServices() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.warning('Location services are disabled');
        return;
      }

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      // Store permission status
      final settingsBox = Hive.box('app_settings');
      await settingsBox.put('location_permission', permission.name);

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        // Test location access
        try {
          await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
            timeLimit: const Duration(seconds: 5),
          );
          await settingsBox.put('location_working', true);
          AppLogger.info('Location services are working');
        } catch (e) {
          await settingsBox.put('location_working', false);
          AppLogger.warning(
              'Location access test failed', {'error': e.toString()});
        }
      }

      _initializationSteps.add('location');
      AppLogger.info('Location services initialized', {
        'service_enabled': serviceEnabled,
        'permission': permission.name,
      });
    } catch (e) {
      AppLogger.error('Failed to initialize location services', e);
      // Non-critical for app startup
    }
  }

  /// Initialize network monitoring
  static Future<void> _initializeNetworkMonitoring() async {
    try {
      final connectivity = Connectivity();

      // Check initial connectivity
      final connectivityResult = await connectivity.checkConnectivity();

      // Store connectivity status
      final settingsBox = Hive.box('app_settings');
      await settingsBox.put('connectivity_status', connectivityResult.name);

      // Set up connectivity monitoring
      connectivity.onConnectivityChanged.listen((ConnectivityResult result) {
        AppLogger.connectivity(result.name);
        settingsBox.put('connectivity_status', result.name);
      });

      _initializationSteps.add('network');
      AppLogger.info('Network monitoring initialized', {
        'initial_connectivity': connectivityResult.name,
      });
    } catch (e) {
      AppLogger.error('Failed to initialize network monitoring', e);
      // Non-critical, continue
    }
  }

  /// Restore user session if available
  static Future<void> _restoreUserSession() async {
    try {
      final userDataBox = Hive.box('user_data');

      // Check if user data exists
      final hasUserData = userDataBox.containsKey('current_user');
      final hasAuthToken = userDataBox.containsKey('auth_token');

      if (hasUserData && hasAuthToken) {
        AppLogger.info('User session found, will attempt restore');

        // TODO: Validate token with backend
        // For now, just log that session exists

        final settingsBox = Hive.box('app_settings');
        await settingsBox.put('has_active_session', true);
      } else {
        AppLogger.info('No previous user session found');
        final settingsBox = Hive.box('app_settings');
        await settingsBox.put('has_active_session', false);
      }

      _initializationSteps.add('session');
      AppLogger.info('Session restoration completed');
    } catch (e) {
      AppLogger.error('Failed to restore user session', e);
      // Non-critical, user can login again
    }
  }

  /// Store device information for analytics
  static Future<void> _storeDeviceInfo(DeviceInfoPlugin deviceInfo) async {
    try {
      final settingsBox = Hive.box('app_settings');
      final androidInfo = await deviceInfo.androidInfo;

      final deviceData = {
        'brand': androidInfo.brand,
        'device': androidInfo.device,
        'model': androidInfo.model,
        'version_release': androidInfo.version.release,
        'sdk_int': androidInfo.version.sdkInt,
        'manufacturer': androidInfo.manufacturer,
        'supported_abis': androidInfo.supportedAbis,
      };

      await settingsBox.put('device_info', deviceData);

      AppLogger.info('Device info stored', {
        'brand': androidInfo.brand,
        'model': androidInfo.model,
        'sdk_version': androidInfo.version.sdkInt,
      });
    } catch (e) {
      AppLogger.warning('Failed to store device info', {'error': e.toString()});
    }
  }

  /// Determine device performance tier
  static String _determinePerformanceTier(int sdkVersion, int featureCount) {
    // Simple heuristic for performance tier
    // In a real app, you'd use more sophisticated checks
    if (sdkVersion >= 30 && featureCount > 100) {
      return 'high_end';
    } else if (sdkVersion >= 26 && featureCount > 50) {
      return 'mid_tier';
    } else {
      return 'low_end';
    }
  }

  /// Handle foreground push notifications
  static void _handleForegroundMessage(RemoteMessage message) {
    AppLogger.info('Received foreground message', {
      'title': message.notification?.title,
      'body': message.notification?.body,
      'data': message.data,
    });

    // TODO: Show local notification or update UI
  }

  /// Handle notification taps that open the app
  static void _handleMessageOpenedApp(RemoteMessage message) {
    AppLogger.info('App opened from notification', {
      'title': message.notification?.title,
      'data': message.data,
    });

    // TODO: Navigate to appropriate screen
  }

  /// Check if app is initialized
  static bool get isInitialized => _isInitialized;

  /// Get initialization steps completed
  static List<String> get completedSteps =>
      List.unmodifiable(_initializationSteps);

  /// Reset initialization state (for testing)
  static void reset() {
    _isInitialized = false;
    _initializationSteps.clear();
  }
}

/// Service for managing app performance settings
class PerformanceManager {
  static String? _performanceTier;

  /// Get current performance tier
  static String get performanceTier {
    _performanceTier ??= _getStoredPerformanceTier();
    return _performanceTier!;
  }

  /// Get performance settings for current device
  static Map<String, dynamic> get settings {
    return AppConstants.qualitySettings[performanceTier] ??
        AppConstants.qualitySettings['medium']!;
  }

  /// Check if animations should be enabled
  static bool get animationsEnabled {
    return settings['animationsEnabled'] as bool? ?? true;
  }

  /// Get appropriate image quality
  static int get imageQuality {
    return settings['imageQuality'] as int? ?? 80;
  }

  /// Get location update interval
  static int get locationUpdateInterval {
    return settings['locationUpdateInterval'] as int? ?? 5000;
  }

  static String _getStoredPerformanceTier() {
    try {
      final settingsBox = Hive.box('app_settings');
      return settingsBox.get('performance_tier', defaultValue: 'medium');
    } catch (e) {
      AppLogger.warning(
          'Failed to get stored performance tier', {'error': e.toString()});
      return 'medium';
    }
  }
}
