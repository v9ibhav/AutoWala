import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';

class StorageService {
  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage();

  // Secure storage for sensitive data
  Future<void> writeSecure(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  Future<String?> readSecure(String key) async {
    return await _secureStorage.read(key: key);
  }

  Future<void> deleteSecure(String key) async {
    await _secureStorage.delete(key: key);
  }

  Future<void> clearSecure() async {
    await _secureStorage.deleteAll();
  }

  // Regular storage for non-sensitive data
  Future<void> setBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<bool> getBool(String key, {bool defaultValue = false}) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(key) ?? defaultValue;
  }

  Future<void> setString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  Future<String?> getString(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<void> setInt(String key, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(key, value);
  }

  Future<int?> getInt(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(key);
  }

  Future<void> setDouble(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, value);
  }

  Future<double?> getDouble(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(key);
  }

  Future<void> setStringList(String key, List<String> value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(key, value);
  }

  Future<List<String>?> getStringList(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key);
  }

  // JSON storage helpers
  Future<void> setJson(String key, Map<String, dynamic> value) async {
    final jsonString = jsonEncode(value);
    await setString(key, jsonString);
  }

  Future<Map<String, dynamic>?> getJson(String key) async {
    final jsonString = await getString(key);
    if (jsonString != null) {
      try {
        return jsonDecode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<void> remove(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(key);
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  // Auth-specific storage methods
  Future<void> saveAuthToken(String token) async {
    await writeSecure('auth_token', token);
  }

  Future<String?> getAuthToken() async {
    return await readSecure('auth_token');
  }

  // Alias methods for backward compatibility
  Future<void> setAccessToken(String token) async {
    await saveAuthToken(token);
  }

  Future<String?> getAccessToken() async {
    return await getAuthToken();
  }

  Future<void> saveRefreshToken(String token) async {
    await writeSecure('refresh_token', token);
  }

  Future<String?> getRefreshToken() async {
    return await readSecure('refresh_token');
  }

  Future<void> setRefreshToken(String token) async {
    await saveRefreshToken(token);
  }

  Future<void> saveUserData(Map<String, dynamic> userData) async {
    await setJson('user_data', userData);
  }

  Future<Map<String, dynamic>?> getUserData() async {
    return await getJson('user_data');
  }

  Future<void> setUserData(Map<String, dynamic> userData) async {
    await saveUserData(userData);
  }

  Future<void> clearAuthData() async {
    await deleteSecure('auth_token');
    await deleteSecure('refresh_token');
    await remove('user_data');
  }

  // App settings
  Future<void> setFirstLaunch(bool isFirstLaunch) async {
    await setBool('is_first_launch', isFirstLaunch);
  }

  Future<bool> isFirstLaunch() async {
    return await getBool('is_first_launch', defaultValue: true);
  }

  Future<void> setLocationPermissionGranted(bool granted) async {
    await setBool('location_permission_granted', granted);
  }

  Future<bool> isLocationPermissionGranted() async {
    return await getBool('location_permission_granted');
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    await setBool('notifications_enabled', enabled);
  }

  Future<bool> areNotificationsEnabled() async {
    return await getBool('notifications_enabled', defaultValue: true);
  }

  // Recent searches and preferences
  Future<void> addRecentSearch(String address) async {
    final recentSearches = await getStringList('recent_searches') ?? [];

    // Remove if already exists to avoid duplicates
    recentSearches.removeWhere((search) => search == address);

    // Add to the beginning
    recentSearches.insert(0, address);

    // Keep only last 10 searches
    if (recentSearches.length > 10) {
      recentSearches.removeRange(10, recentSearches.length);
    }

    await setStringList('recent_searches', recentSearches);
  }

  Future<List<String>> getRecentSearches() async {
    return await getStringList('recent_searches') ?? [];
  }

  Future<void> clearRecentSearches() async {
    await remove('recent_searches');
  }

  // Saved places
  Future<void> saveFavoritePlace(String name, double latitude, double longitude, String address) async {
    final favoritePlaces = await getJson('favorite_places') ?? {};
    favoritePlaces[name] = {
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'saved_at': DateTime.now().toIso8601String(),
    };
    await setJson('favorite_places', favoritePlaces);
  }

  Future<Map<String, dynamic>?> getFavoritePlaces() async {
    return await getJson('favorite_places');
  }

  Future<void> removeFavoritePlace(String name) async {
    final favoritePlaces = await getJson('favorite_places');
    if (favoritePlaces != null) {
      favoritePlaces.remove(name);
      await setJson('favorite_places', favoritePlaces);
    }
  }
}

// Riverpod provider
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});