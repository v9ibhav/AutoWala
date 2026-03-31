import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

class LocationService {
  static LocationService? _instance;
  static LocationService get instance => _instance ??= LocationService._();

  LocationService._();

  Position? _currentPosition;
  StreamSubscription<Position>? _positionStream;
  String? _currentAddress;

  // Location settings
  static const LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    distanceFilter: 10, // Update every 10 meters
  );

  // Check if location permissions are granted
  Future<bool> isLocationPermissionGranted() async {
    final permission = await Permission.location.status;
    return permission.isGranted;
  }

  // Request location permissions
  Future<bool> requestLocationPermission() async {
    final permission = await Permission.location.request();

    if (permission.isDenied) {
      return false;
    } else if (permission.isPermanentlyDenied) {
      // Open app settings
      await openAppSettings();
      return false;
    }

    return permission.isGranted;
  }

  // Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // Get current position
  Future<Position?> getCurrentPosition() async {
    try {
      // Check permissions and service
      if (!await isLocationServiceEnabled()) {
        throw LocationServiceDisabledException();
      }

      if (!await isLocationPermissionGranted()) {
        final granted = await requestLocationPermission();
        if (!granted) {
          throw PermissionDeniedException('Location permission denied');
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _currentPosition = position;
      return position;
    } catch (e) {
      print('Error getting current position: $e');
      rethrow;
    }
  }

  // Alias for backward compatibility
  Future<Position?> getCurrentLocation() async {
    return await getCurrentPosition();
  }

  // Get cached current position (doesn't make new GPS request)
  Position? getCachedPosition() {
    return _currentPosition;
  }

  // Start watching position changes
  Stream<Position> watchPosition() {
    return Geolocator.getPositionStream(
      locationSettings: _locationSettings,
    );
  }

  // Start continuous location tracking
  Future<void> startLocationTracking({
    required Function(Position) onLocationUpdate,
    Function(String)? onError,
  }) async {
    try {
      if (!await isLocationPermissionGranted()) {
        throw PermissionDeniedException('Location permission required');
      }

      _positionStream = watchPosition().listen(
        (Position position) {
          _currentPosition = position;
          onLocationUpdate(position);
        },
        onError: (error) {
          print('Location tracking error: $error');
          onError?.call(error.toString());
        },
      );
    } catch (e) {
      print('Failed to start location tracking: $e');
      onError?.call(e.toString());
    }
  }

  // Stop location tracking
  void stopLocationTracking() {
    _positionStream?.cancel();
    _positionStream = null;
  }

  // Get address from coordinates (reverse geocoding)
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];

        String address = '';

        if (place.name != null && place.name!.isNotEmpty) {
          address += place.name!;
        }

        if (place.locality != null && place.locality!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          address += place.locality!;
        }

        if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          address += place.administrativeArea!;
        }

        if (place.country != null && place.country!.isNotEmpty) {
          if (address.isNotEmpty) address += ', ';
          address += place.country!;
        }

        _currentAddress = address;
        return address.isNotEmpty ? address : 'Unknown location';
      }

      return 'Unknown location';
    } catch (e) {
      print('Error getting address: $e');
      return null;
    }
  }

  // Get coordinates from address (geocoding)
  Future<Position?> getCoordinatesFromAddress(String address) async {
    try {
      List<Location> locations = await locationFromAddress(address);

      if (locations.isNotEmpty) {
        Location location = locations[0];
        return Position(
          latitude: location.latitude,
          longitude: location.longitude,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      }

      return null;
    } catch (e) {
      print('Error getting coordinates: $e');
      return null;
    }
  }

  // Calculate distance between two points
  double calculateDistance(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  // Calculate bearing between two points
  double calculateBearing(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.bearingBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }

  // Get human readable distance
  String getHumanReadableDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} m';
    } else {
      double distanceInKm = distanceInMeters / 1000;
      return '${distanceInKm.toStringAsFixed(1)} km';
    }
  }

  // Get ETA based on distance and average speed
  String getEstimatedTime(double distanceInMeters, {double averageSpeedKmH = 25}) {
    double distanceInKm = distanceInMeters / 1000;
    double timeInHours = distanceInKm / averageSpeedKmH;
    int timeInMinutes = (timeInHours * 60).round();

    if (timeInMinutes < 60) {
      return '$timeInMinutes min';
    } else {
      int hours = timeInMinutes ~/ 60;
      int remainingMinutes = timeInMinutes % 60;
      return '${hours}h ${remainingMinutes}min';
    }
  }

  // Check if two positions are within a certain distance
  static bool isWithinRadius(
    Position position1,
    Position position2,
    double radiusInMeters,
  ) {
    double distance = Geolocator.distanceBetween(
      position1.latitude,
      position1.longitude,
      position2.latitude,
      position2.longitude,
    );
    return distance <= radiusInMeters;
  }

  // Get current address (cached if available)
  String? getCurrentAddress() {
    return _currentAddress;
  }

  // Update current address
  Future<void> updateCurrentAddress() async {
    if (_currentPosition != null) {
      _currentAddress = await getAddressFromCoordinates(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
      );
    }
  }

  // Cleanup
  void dispose() {
    stopLocationTracking();
  }
}

// Custom exceptions
class PermissionDeniedException implements Exception {
  final String message;
  PermissionDeniedException(this.message);

  @override
  String toString() => 'PermissionDeniedException: $message';
}

// Riverpod provider
final locationServiceProvider = Provider<LocationService>((ref) {
  return LocationService.instance;
});