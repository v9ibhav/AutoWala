import 'dart:async';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/app_constants.dart';
import '../utils/logger.dart';
import 'firebase_service.dart';

/// Location service for AutoWala Rider app
/// Handles continuous location tracking, permissions, and background updates
class LocationService {
  static LocationService? _instance;
  static LocationService get instance => _instance ??= LocationService._();

  LocationService._();

  StreamSubscription<Position>? _positionSubscription;
  Position? _lastKnownPosition;
  bool _isTracking = false;
  bool _hasPermission = false;
  Timer? _backgroundTimer;

  /// Initialize location service and request permissions
  Future<bool> init() async {
    try {
      AppLogger.info('Initializing Rider LocationService');

      // Check and request permissions
      _hasPermission = await _requestLocationPermissions();

      if (!_hasPermission) {
        AppLogger.warning('Location permissions not granted');
        return false;
      }

      // Get initial location
      await _updateCurrentLocation();

      AppLogger.info('Rider LocationService initialized successfully');
      return true;
    } catch (e) {
      AppLogger.error('Failed to initialize Rider LocationService', e);
      return false;
    }
  }

  /// Request location permissions (including background permission for riders)
  Future<bool> _requestLocationPermissions() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.warning('Location services are disabled');
        return false;
      }

      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          AppLogger.warning('Location permission denied');
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        AppLogger.warning('Location permission permanently denied');
        return false;
      }

      // For riders, we need background location permission
      if (permission != LocationPermission.always) {
        AppLogger.info('Requesting background location permission for rider');

        // Request background location permission using permission_handler
        final backgroundStatus = await Permission.locationAlways.request();

        if (!backgroundStatus.isGranted) {
          AppLogger.warning('Background location permission not granted');
          // Still allow foreground usage
        }
      }

      AppLogger.info('Location permissions granted', {
        'permission': permission.toString(),
      });

      return true;
    } catch (e) {
      AppLogger.error('Error requesting location permissions', e);
      return false;
    }
  }

  /// Start continuous location tracking for riders
  Future<void> startTracking() async {
    if (_isTracking) {
      AppLogger.debug('Location tracking already started');
      return;
    }

    if (!_hasPermission) {
      AppLogger.warning('Cannot start tracking: No location permission');
      return;
    }

    try {
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5, // Update every 5 meters
        timeLimit: Duration(seconds: 30), // Max 30 seconds for location fix
      );

      _positionSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        _onLocationUpdate,
        onError: _onLocationError,
      );

      // Start background timer for less frequent updates when app is backgrounded
      _startBackgroundTimer();

      _isTracking = true;
      AppLogger.location('tracking_started');
      AppLogger.riderAction('location_tracking_started');
    } catch (e) {
      AppLogger.error('Failed to start location tracking', e);
    }
  }

  /// Stop location tracking
  Future<void> stopTracking() async {
    if (!_isTracking) return;

    try {
      await _positionSubscription?.cancel();
      _positionSubscription = null;

      _backgroundTimer?.cancel();
      _backgroundTimer = null;

      _isTracking = false;
      AppLogger.location('tracking_stopped');
      AppLogger.riderAction('location_tracking_stopped');
    } catch (e) {
      AppLogger.error('Failed to stop location tracking', e);
    }
  }

  /// Handle location updates
  void _onLocationUpdate(Position position) {
    _lastKnownPosition = position;

    AppLogger.location('updated',
        latitude: position.latitude,
        longitude: position.longitude,
        data: {
          'accuracy': position.accuracy,
          'altitude': position.altitude,
          'heading': position.heading,
          'speed': position.speed,
          'timestamp': position.timestamp?.toIso8601String(),
        });

    // Update location in Firebase for real-time tracking
    _updateFirebaseLocation(position);

    // TODO: Update local database/cache for offline usage
  }

  /// Handle location errors
  void _onLocationError(Object error) {
    AppLogger.error('Location update error', error);

    // Try to get cached location on error
    _updateCurrentLocation();
  }

  /// Update location in Firebase
  Future<void> _updateFirebaseLocation(Position position) async {
    try {
      await FirebaseService.instance.updateLocation(
        latitude: position.latitude,
        longitude: position.longitude,
        heading: position.heading,
        speed: position.speed,
        accuracy: position.accuracy.round(),
      );
    } catch (e) {
      AppLogger.error('Failed to update Firebase location', e);
    }
  }

  /// Start background timer for less frequent updates
  void _startBackgroundTimer() {
    _backgroundTimer = Timer.periodic(
      const Duration(milliseconds: AppConstants.backgroundLocationIntervalMs),
      (timer) async {
        // Only update if we haven't gotten a recent foreground update
        if (_lastKnownPosition != null) {
          final timeSinceLastUpdate = DateTime.now().difference(
            _lastKnownPosition!.timestamp ?? DateTime.now(),
          );

          if (timeSinceLastUpdate.inMilliseconds > AppConstants.backgroundLocationIntervalMs) {
            await _updateCurrentLocation();
          }
        }
      },
    );
  }

  /// Get current location (single request)
  Future<Position?> getCurrentLocation({bool forceUpdate = false}) async {
    if (!_hasPermission) {
      AppLogger.warning('Cannot get location: No permission');
      return null;
    }

    // Return cached location if recent and not forcing update
    if (!forceUpdate && _lastKnownPosition != null) {
      final age = DateTime.now().difference(
        _lastKnownPosition!.timestamp ?? DateTime.now(),
      );

      if (age.inSeconds < 30) {
        return _lastKnownPosition;
      }
    }

    try {
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      );

      final position = await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      );

      _lastKnownPosition = position;

      AppLogger.location('current_obtained',
          latitude: position.latitude,
          longitude: position.longitude);

      return position;
    } catch (e) {
      AppLogger.error('Failed to get current location', e);
      return _lastKnownPosition;
    }
  }

  /// Update current location and cache it
  Future<void> _updateCurrentLocation() async {
    final position = await getCurrentLocation(forceUpdate: true);
    if (position != null) {
      _onLocationUpdate(position);
    }
  }

  /// Calculate distance between two points
  double calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // Convert to km
  }

  /// Calculate bearing between two points
  double calculateBearing(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    return Geolocator.bearingBetween(lat1, lon1, lat2, lon2);
  }

  /// Check if rider is within acceptance radius of a pickup point
  bool isWithinAcceptanceRadius(double pickupLat, double pickupLon) {
    if (_lastKnownPosition == null) return false;

    final distance = calculateDistance(
      _lastKnownPosition!.latitude,
      _lastKnownPosition!.longitude,
      pickupLat,
      pickupLon,
    );

    return distance <= AppConstants.rideAcceptanceRadiusKm;
  }

  /// Check if location accuracy is good enough for reliable tracking
  bool get hasGoodAccuracy {
    if (_lastKnownPosition == null) return false;
    return _lastKnownPosition!.accuracy <= 20; // 20 meters or better
  }

  /// Get location accuracy description
  String get accuracyDescription {
    if (_lastKnownPosition == null) return 'Unknown';

    final accuracy = _lastKnownPosition!.accuracy;
    if (accuracy <= 5) return 'Excellent';
    if (accuracy <= 10) return 'Good';
    if (accuracy <= 20) return 'Fair';
    if (accuracy <= 50) return 'Poor';
    return 'Very Poor';
  }

  /// Get current speed in km/h
  double? get currentSpeed {
    if (_lastKnownPosition?.speed == null) return null;
    return _lastKnownPosition!.speed! * 3.6; // Convert m/s to km/h
  }

  /// Check if rider is moving
  bool get isMoving {
    final speed = currentSpeed;
    return speed != null && speed > 2.0; // Moving if speed > 2 km/h
  }

  /// Get location age in seconds
  int? get locationAge {
    if (_lastKnownPosition?.timestamp == null) return null;
    return DateTime.now().difference(_lastKnownPosition!.timestamp!).inSeconds;
  }

  /// Check if location is stale (older than 30 seconds)
  bool get isLocationStale {
    final age = locationAge;
    return age == null || age > 30;
  }

  /// Open device location settings
  Future<void> openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
      AppLogger.riderAction('location_settings_opened');
    } catch (e) {
      AppLogger.error('Failed to open location settings', e);
    }
  }

  /// Open app location permission settings
  Future<void> openPermissionSettings() async {
    try {
      await Geolocator.openAppSettings();
      AppLogger.riderAction('permission_settings_opened');
    } catch (e) {
      AppLogger.error('Failed to open app settings', e);
    }
  }

  /// Check if high accuracy mode is available
  Future<bool> isHighAccuracyAvailable() async {
    try {
      final permission = await Geolocator.checkPermission();
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      return serviceEnabled && permission == LocationPermission.always;
    } catch (e) {
      return false;
    }
  }

  /// Get location status summary
  Map<String, dynamic> getLocationStatus() {
    return {
      'has_permission': _hasPermission,
      'is_tracking': _isTracking,
      'has_location': _lastKnownPosition != null,
      'accuracy': _lastKnownPosition?.accuracy ?? 0,
      'accuracy_description': accuracyDescription,
      'is_moving': isMoving,
      'current_speed': currentSpeed,
      'location_age': locationAge,
      'is_stale': isLocationStale,
      'last_update': _lastKnownPosition?.timestamp?.toIso8601String(),
    };
  }

  /// Getters
  Position? get lastKnownPosition => _lastKnownPosition;
  bool get isTracking => _isTracking;
  bool get hasPermission => _hasPermission;

  /// Dispose resources
  Future<void> dispose() async {
    await stopTracking();
    _instance = null;
    AppLogger.info('Rider LocationService disposed');
  }
}