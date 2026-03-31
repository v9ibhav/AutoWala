import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_constants.dart';
import '../utils/logger.dart';

/// Secure storage service for AutoWala Rider app
/// Handles authentication tokens, rider data, and app settings with encryption
class StorageService {
  static StorageService? _instance;
  static StorageService get instance => _instance ??= StorageService._();

  StorageService._();

  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  SharedPreferences? _prefs;

  /// Initialize storage service
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      AppLogger.info('Rider StorageService initialized successfully');
    } catch (e) {
      AppLogger.error('Failed to initialize Rider StorageService', e);
      rethrow;
    }
  }

  /// Authentication Token Management

  /// Store access token securely
  Future<void> setAccessToken(String token) async {
    try {
      await _secureStorage.write(key: AppConstants.authTokenKey, value: token);
      AppLogger.debug('Rider access token stored');
    } catch (e) {
      AppLogger.error('Failed to store access token', e);
      rethrow;
    }
  }

  /// Get access token
  Future<String?> getAccessToken() async {
    try {
      final token = await _secureStorage.read(key: AppConstants.authTokenKey);
      AppLogger.debug('Rider access token retrieved', {'has_token': token != null});
      return token;
    } catch (e) {
      AppLogger.error('Failed to get access token', e);
      return null;
    }
  }

  /// Store refresh token securely
  Future<void> setRefreshToken(String token) async {
    try {
      await _secureStorage.write(key: '${AppConstants.authTokenKey}_refresh', value: token);
      AppLogger.debug('Rider refresh token stored');
    } catch (e) {
      AppLogger.error('Failed to store refresh token', e);
      rethrow;
    }
  }

  /// Get refresh token
  Future<String?> getRefreshToken() async {
    try {
      final token = await _secureStorage.read(key: '${AppConstants.authTokenKey}_refresh');
      return token;
    } catch (e) {
      AppLogger.error('Failed to get refresh token', e);
      return null;
    }
  }

  /// Check if rider is authenticated (has valid tokens)
  Future<bool> isAuthenticated() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();
    return accessToken != null && refreshToken != null;
  }

  /// Clear all authentication data
  Future<void> clearAuthData() async {
    try {
      await _secureStorage.delete(key: AppConstants.authTokenKey);
      await _secureStorage.delete(key: '${AppConstants.authTokenKey}_refresh');
      await clearRiderData();

      AppLogger.info('Rider authentication data cleared');
      AppLogger.riderAction('logged_out');
    } catch (e) {
      AppLogger.error('Failed to clear auth data', e);
    }
  }

  /// Rider Data Management

  /// Store rider profile data
  Future<void> setRiderData(Map<String, dynamic> riderData) async {
    try {
      final jsonString = json.encode(riderData);
      await _secureStorage.write(key: AppConstants.riderDataKey, value: jsonString);

      AppLogger.debug('Rider data stored', {
        'rider_id': riderData['id'],
        'name': riderData['name'],
      });
    } catch (e) {
      AppLogger.error('Failed to store rider data', e);
      rethrow;
    }
  }

  /// Get rider profile data
  Future<Map<String, dynamic>?> getRiderData() async {
    try {
      final jsonString = await _secureStorage.read(key: AppConstants.riderDataKey);
      if (jsonString != null) {
        final riderData = Map<String, dynamic>.from(json.decode(jsonString));
        AppLogger.debug('Rider data retrieved', {'rider_id': riderData['id']});
        return riderData;
      }
      return null;
    } catch (e) {
      AppLogger.error('Failed to get rider data', e);
      return null;
    }
  }

  /// Clear rider data
  Future<void> clearRiderData() async {
    try {
      await _secureStorage.delete(key: AppConstants.riderDataKey);
      await _secureStorage.delete(key: AppConstants.vehicleDataKey);
    } catch (e) {
      AppLogger.error('Failed to clear rider data', e);
    }
  }

  /// Store vehicle data
  Future<void> setVehicleData(Map<String, dynamic> vehicleData) async {
    try {
      final jsonString = json.encode(vehicleData);
      await _secureStorage.write(key: AppConstants.vehicleDataKey, value: jsonString);

      AppLogger.debug('Vehicle data stored', {
        'vehicle_id': vehicleData['id'],
        'registration': vehicleData['registration_number'],
      });
    } catch (e) {
      AppLogger.error('Failed to store vehicle data', e);
      rethrow;
    }
  }

  /// Get vehicle data
  Future<Map<String, dynamic>?> getVehicleData() async {
    try {
      final jsonString = await _secureStorage.read(key: AppConstants.vehicleDataKey);
      if (jsonString != null) {
        return Map<String, dynamic>.from(json.decode(jsonString));
      }
      return null;
    } catch (e) {
      AppLogger.error('Failed to get vehicle data', e);
      return null;
    }
  }

  /// Current Ride Management

  /// Store current active ride data
  Future<void> setCurrentRide(Map<String, dynamic> rideData) async {
    try {
      final jsonString = json.encode(rideData);
      await _secureStorage.write(key: AppConstants.currentRideKey, value: jsonString);

      AppLogger.ride('data_stored', rideId: rideData['id']?.toString());
    } catch (e) {
      AppLogger.error('Failed to store current ride data', e);
    }
  }

  /// Get current active ride data
  Future<Map<String, dynamic>?> getCurrentRide() async {
    try {
      final jsonString = await _secureStorage.read(key: AppConstants.currentRideKey);
      if (jsonString != null) {
        return Map<String, dynamic>.from(json.decode(jsonString));
      }
      return null;
    } catch (e) {
      AppLogger.error('Failed to get current ride data', e);
      return null;
    }
  }

  /// Clear current ride data
  Future<void> clearCurrentRide() async {
    try {
      await _secureStorage.delete(key: AppConstants.currentRideKey);
      AppLogger.debug('Current ride data cleared');
    } catch (e) {
      AppLogger.error('Failed to clear current ride data', e);
    }
  }

  /// Check if rider has an active ride
  Future<bool> hasActiveRide() async {
    final rideData = await getCurrentRide();
    return rideData != null;
  }

  /// Online Status Management

  /// Set rider online status
  Future<void> setOnlineStatus(bool isOnline) async {
    try {
      await _prefs?.setBool(AppConstants.onlineStatusKey, isOnline);

      AppLogger.statusChange(
        isOnline ? 'online' : 'offline',
        data: {'stored_locally': true},
      );
    } catch (e) {
      AppLogger.error('Failed to set online status', e);
    }
  }

  /// Get rider online status
  Future<bool> getOnlineStatus() async {
    try {
      return _prefs?.getBool(AppConstants.onlineStatusKey) ?? false;
    } catch (e) {
      AppLogger.error('Failed to get online status', e);
      return false;
    }
  }

  /// App Settings Management

  /// Store app settings
  Future<void> setSettings(Map<String, dynamic> settings) async {
    try {
      final jsonString = json.encode(settings);
      await _prefs?.setString(AppConstants.settingsKey, jsonString);

      AppLogger.debug('Rider app settings stored');
    } catch (e) {
      AppLogger.error('Failed to store app settings', e);
    }
  }

  /// Get app settings
  Future<Map<String, dynamic>> getSettings() async {
    try {
      final jsonString = _prefs?.getString(AppConstants.settingsKey);
      if (jsonString != null) {
        return Map<String, dynamic>.from(json.decode(jsonString));
      }

      // Return default settings
      return _getDefaultSettings();
    } catch (e) {
      AppLogger.error('Failed to get app settings', e);
      return _getDefaultSettings();
    }
  }

  /// Get default app settings
  Map<String, dynamic> _getDefaultSettings() {
    return {
      'notifications_enabled': true,
      'sound_enabled': true,
      'vibration_enabled': true,
      'auto_accept_rides': false,
      'preferred_language': 'en',
      'night_mode': 'auto',
      'location_accuracy': 'high',
      'background_location': true,
      'ride_request_timeout': 15, // seconds
      'max_distance_km': 5.0,
      'quality_tier': 'medium',
    };
  }

  /// Update specific setting
  Future<void> updateSetting(String key, dynamic value) async {
    try {
      final settings = await getSettings();
      settings[key] = value;
      await setSettings(settings);

      AppLogger.debug('Setting updated', {'key': key, 'value': value});
      AppLogger.riderAction('setting_changed', parameters: {
        'setting_key': key,
        'new_value': value.toString(),
      });
    } catch (e) {
      AppLogger.error('Failed to update setting', e);
    }
  }

  /// Get specific setting
  Future<T?> getSetting<T>(String key, [T? defaultValue]) async {
    try {
      final settings = await getSettings();
      return settings[key] as T? ?? defaultValue;
    } catch (e) {
      AppLogger.error('Failed to get setting', e);
      return defaultValue;
    }
  }

  /// Permission Status Management

  /// Set location permission status
  Future<void> setLocationPermissionGranted(bool granted) async {
    try {
      await _prefs?.setBool(AppConstants.locationPermissionKey, granted);
      AppLogger.debug('Location permission status stored', {'granted': granted});
    } catch (e) {
      AppLogger.error('Failed to store location permission status', e);
    }
  }

  /// Check if location permission was granted
  Future<bool> isLocationPermissionGranted() async {
    try {
      return _prefs?.getBool(AppConstants.locationPermissionKey) ?? false;
    } catch (e) {
      AppLogger.error('Failed to get location permission status', e);
      return false;
    }
  }

  /// Onboarding Status

  /// Mark onboarding as complete
  Future<void> setOnboardingComplete() async {
    try {
      await _prefs?.setBool(AppConstants.onboardingCompleteKey, true);
      AppLogger.riderAction('onboarding_completed');
    } catch (e) {
      AppLogger.error('Failed to set onboarding complete', e);
    }
  }

  /// Check if onboarding is complete
  Future<bool> isOnboardingComplete() async {
    try {
      return _prefs?.getBool(AppConstants.onboardingCompleteKey) ?? false;
    } catch (e) {
      AppLogger.error('Failed to get onboarding status', e);
      return false;
    }
  }

  /// FCM Token Management

  /// Store FCM token
  Future<void> setFCMToken(String token) async {
    try {
      await _secureStorage.write(key: 'fcm_token', value: token);
      AppLogger.debug('FCM token stored');
    } catch (e) {
      AppLogger.error('Failed to store FCM token', e);
    }
  }

  /// Get FCM token
  Future<String?> getFCMToken() async {
    try {
      return await _secureStorage.read(key: 'fcm_token');
    } catch (e) {
      AppLogger.error('Failed to get FCM token', e);
      return null;
    }
  }

  /// Cache Management

  /// Store data in cache with expiration
  Future<void> cacheData(String key, Map<String, dynamic> data, {
    Duration? expiration,
  }) async {
    try {
      final cacheData = {
        'data': data,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'expiration': expiration?.inMilliseconds ?? AppConstants.cacheTimeout.inMilliseconds,
      };

      final jsonString = json.encode(cacheData);
      await _prefs?.setString('cache_$key', jsonString);
    } catch (e) {
      AppLogger.error('Failed to cache data', e);
    }
  }

  /// Get cached data if not expired
  Future<Map<String, dynamic>?> getCachedData(String key) async {
    try {
      final jsonString = _prefs?.getString('cache_$key');
      if (jsonString == null) return null;

      final cacheData = Map<String, dynamic>.from(json.decode(jsonString));
      final timestamp = cacheData['timestamp'] as int;
      final expiration = cacheData['expiration'] as int;

      final age = DateTime.now().millisecondsSinceEpoch - timestamp;
      if (age > expiration) {
        // Cache expired, remove it
        await _prefs?.remove('cache_$key');
        return null;
      }

      return Map<String, dynamic>.from(cacheData['data']);
    } catch (e) {
      AppLogger.error('Failed to get cached data', e);
      return null;
    }
  }

  /// Clear all cache
  Future<void> clearCache() async {
    try {
      final keys = _prefs?.getKeys().where((key) => key.startsWith('cache_')).toList() ?? [];
      for (final key in keys) {
        await _prefs?.remove(key);
      }
      AppLogger.debug('Cache cleared', {'items_removed': keys.length});
    } catch (e) {
      AppLogger.error('Failed to clear cache', e);
    }
  }

  /// Clear all data (except settings)
  Future<void> clearAllData() async {
    try {
      await clearAuthData();
      await clearCurrentRide();
      await clearCache();
      await setOnlineStatus(false);

      AppLogger.info('All rider data cleared');
      AppLogger.riderAction('all_data_cleared');
    } catch (e) {
      AppLogger.error('Failed to clear all data', e);
    }
  }

  /// Get storage usage info
  Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final allKeys = _prefs?.getKeys() ?? <String>{};
      final secureKeys = [
        AppConstants.authTokenKey,
        '${AppConstants.authTokenKey}_refresh',
        AppConstants.riderDataKey,
        AppConstants.vehicleDataKey,
        AppConstants.currentRideKey,
        'fcm_token',
      ];

      final cacheKeys = allKeys.where((key) => key.startsWith('cache_')).length;

      return {
        'total_preference_keys': allKeys.length,
        'cache_keys': cacheKeys,
        'secure_keys': secureKeys.length,
        'has_auth_data': await isAuthenticated(),
        'has_active_ride': await hasActiveRide(),
        'is_onboarding_complete': await isOnboardingComplete(),
        'online_status': await getOnlineStatus(),
      };
    } catch (e) {
      AppLogger.error('Failed to get storage info', e);
      return {};
    }
  }

  /// Dispose resources
  void dispose() {
    _instance = null;
    AppLogger.info('Rider StorageService disposed');
  }
}