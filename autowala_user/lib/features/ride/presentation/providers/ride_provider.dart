import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/firebase_service.dart';
import '../../../../core/utils/logger.dart';

/// Ride state model
class RideState {
  final bool isLoading;
  final String? error;
  final Map<String, dynamic>? currentRide;
  final String? rideStatus;
  final Map<String, dynamic>? liveTracking;

  const RideState({
    this.isLoading = false,
    this.error,
    this.currentRide,
    this.rideStatus,
    this.liveTracking,
  });

  RideState copyWith({
    bool? isLoading,
    String? error,
    Map<String, dynamic>? currentRide,
    String? rideStatus,
    Map<String, dynamic>? liveTracking,
  }) {
    return RideState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentRide: currentRide ?? this.currentRide,
      rideStatus: rideStatus ?? this.rideStatus,
      liveTracking: liveTracking ?? this.liveTracking,
    );
  }
}

/// Ride notifier
class RideNotifier extends StateNotifier<RideState> {
  final ApiService _apiService;
  final FirebaseService _firebaseService;
  final Ref _ref;

  RideNotifier(this._apiService, this._firebaseService, this._ref)
      : super(const RideState());

  /// Book a ride
  Future<void> bookRide({
    required String riderId,
    required Map<String, dynamic> pickupLocation,
    required Map<String, dynamic> dropoffLocation,
    required int passengerCount,
    String? additionalNotes,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _apiService.post('/rides/book', {
        'rider_id': riderId,
        'pickup_location': pickupLocation,
        'dropoff_location': dropoffLocation,
        'passenger_count': passengerCount,
        'additional_notes': additionalNotes,
      });

      if (response['success'] == true) {
        final rideData = response['data'];

        state = state.copyWith(
          isLoading: false,
          currentRide: rideData,
          rideStatus: rideData['status'],
        );

        // Start listening to real-time updates
        _startRealTimeTracking(rideData['id']);

        AppLogger.userAction('ride_booked_successfully', parameters: {
          'ride_id': rideData['id'],
          'rider_id': riderId,
          'passenger_count': passengerCount,
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to book ride');
      }
    } catch (e) {
      AppLogger.error('Failed to book ride', error: e.toString(), parameters: {
        'rider_id': riderId,
        'passenger_count': passengerCount,
      });

      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
      rethrow;
    }
  }

  /// Cancel current ride
  Future<void> cancelRide(String rideId, [String? cancellationReason]) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _apiService.post('/rides/$rideId/cancel', {
        'cancellation_reason': cancellationReason,
      });

      if (response['success'] == true) {
        state = state.copyWith(
          isLoading: false,
          currentRide: null,
          rideStatus: 'cancelled',
          liveTracking: null,
        );

        // Stop real-time tracking
        _stopRealTimeTracking();

        AppLogger.userAction('ride_cancelled', parameters: {
          'ride_id': rideId,
          'reason': cancellationReason,
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to cancel ride');
      }
    } catch (e) {
      AppLogger.error('Failed to cancel ride',
          error: e.toString(),
          parameters: {
            'ride_id': rideId,
          });

      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
      rethrow;
    }
  }

  /// Complete ride (mark as finished)
  Future<void> completeRide(
    String rideId, {
    required double rating,
    String? feedback,
    String? tip,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _apiService.post('/rides/$rideId/complete', {
        'rating': rating,
        'feedback': feedback,
        'tip': tip,
      });

      if (response['success'] == true) {
        final completedRide = response['data'];

        state = state.copyWith(
          isLoading: false,
          currentRide: completedRide,
          rideStatus: 'completed',
          liveTracking: null,
        );

        // Stop real-time tracking
        _stopRealTimeTracking();

        AppLogger.userAction('ride_completed', parameters: {
          'ride_id': rideId,
          'rating': rating,
          'has_feedback': feedback != null,
          'has_tip': tip != null,
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to complete ride');
      }
    } catch (e) {
      AppLogger.error('Failed to complete ride',
          error: e.toString(),
          parameters: {
            'ride_id': rideId,
          });

      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
      rethrow;
    }
  }

  /// Get ride history
  Future<List<Map<String, dynamic>>> getRideHistory({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiService.get('/rides/history', queryParams: {
        'page': page.toString(),
        'limit': limit.toString(),
      });

      if (response['success'] == true) {
        final rideHistory = List<Map<String, dynamic>>.from(
          response['data']['rides'] ?? [],
        );

        AppLogger.userAction('ride_history_fetched', parameters: {
          'page': page,
          'count': rideHistory.length,
        });

        return rideHistory;
      } else {
        throw Exception(response['message'] ?? 'Failed to fetch ride history');
      }
    } catch (e) {
      AppLogger.error('Failed to fetch ride history',
          error: e.toString(),
          parameters: {
            'page': page,
            'limit': limit,
          });

      throw Exception(_getErrorMessage(e));
    }
  }

  /// Get current ride details
  Future<void> getCurrentRide() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _apiService.get('/rides/current');

      if (response['success'] == true) {
        final currentRide = response['data'];

        if (currentRide != null) {
          state = state.copyWith(
            isLoading: false,
            currentRide: currentRide,
            rideStatus: currentRide['status'],
          );

          // Start real-time tracking if ride is active
          if (['booked', 'in_transit', 'arrived']
              .contains(currentRide['status'])) {
            _startRealTimeTracking(currentRide['id']);
          }
        } else {
          state = state.copyWith(
            isLoading: false,
            currentRide: null,
            rideStatus: null,
          );
        }
      } else {
        throw Exception(response['message'] ?? 'Failed to get current ride');
      }
    } catch (e) {
      AppLogger.error('Failed to get current ride', error: e.toString());

      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
    }
  }

  /// Start real-time tracking for active ride
  void _startRealTimeTracking(dynamic rideId) {
    try {
      _firebaseService.listenToRideUpdates(
        rideId.toString(),
        (trackingData) {
          if (mounted) {
            state = state.copyWith(
              liveTracking: trackingData,
              rideStatus: trackingData['status'],
            );

            AppLogger.debug('Live tracking update received', parameters: {
              'ride_id': rideId,
              'rider_lat': trackingData['current_rider_lat'],
              'rider_lon': trackingData['current_rider_lon'],
              'status': trackingData['status'],
            });
          }
        },
      );

      AppLogger.info('Started real-time tracking', parameters: {
        'ride_id': rideId,
      });
    } catch (e) {
      AppLogger.error('Failed to start real-time tracking',
          error: e.toString(),
          parameters: {
            'ride_id': rideId,
          });
    }
  }

  /// Stop real-time tracking
  void _stopRealTimeTracking() {
    try {
      _firebaseService.stopListeningToRideUpdates();

      AppLogger.info('Stopped real-time tracking');
    } catch (e) {
      AppLogger.error('Failed to stop real-time tracking', error: e.toString());
    }
  }

  /// Search for nearby riders
  Future<List<Map<String, dynamic>>> searchNearbyRiders({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) async {
    try {
      final response = await _apiService.post('/rides/search-nearby', {
        'latitude': latitude,
        'longitude': longitude,
        'radius_km': radiusKm,
      });

      if (response['success'] == true) {
        final nearbyRiders = List<Map<String, dynamic>>.from(
          response['data']['riders'] ?? [],
        );

        AppLogger.userAction('nearby_riders_searched', parameters: {
          'latitude': latitude,
          'longitude': longitude,
          'radius_km': radiusKm,
          'found_count': nearbyRiders.length,
        });

        return nearbyRiders;
      } else {
        throw Exception(
            response['message'] ?? 'Failed to search nearby riders');
      }
    } catch (e) {
      AppLogger.error('Failed to search nearby riders',
          error: e.toString(),
          parameters: {
            'latitude': latitude,
            'longitude': longitude,
            'radius_km': radiusKm,
          });

      throw Exception(_getErrorMessage(e));
    }
  }

  /// Get estimated fare for a trip
  Future<Map<String, dynamic>> getEstimatedFare({
    required double pickupLat,
    required double pickupLon,
    required double dropoffLat,
    required double dropoffLon,
    int passengerCount = 1,
  }) async {
    try {
      final response = await _apiService.post('/rides/estimate-fare', {
        'pickup_lat': pickupLat,
        'pickup_lon': pickupLon,
        'dropoff_lat': dropoffLat,
        'dropoff_lon': dropoffLon,
        'passenger_count': passengerCount,
      });

      if (response['success'] == true) {
        final fareEstimate = response['data'];

        AppLogger.userAction('fare_estimated', parameters: {
          'pickup_lat': pickupLat,
          'pickup_lon': pickupLon,
          'dropoff_lat': dropoffLat,
          'dropoff_lon': dropoffLon,
          'passenger_count': passengerCount,
          'estimated_fare': fareEstimate['total_fare'],
        });

        return fareEstimate;
      } else {
        throw Exception(response['message'] ?? 'Failed to estimate fare');
      }
    } catch (e) {
      AppLogger.error('Failed to estimate fare',
          error: e.toString(),
          parameters: {
            'pickup_lat': pickupLat,
            'pickup_lon': pickupLon,
            'dropoff_lat': dropoffLat,
            'dropoff_lon': dropoffLon,
          });

      throw Exception(_getErrorMessage(e));
    }
  }

  /// Clear current ride state
  void clearCurrentRide() {
    state = state.copyWith(
      currentRide: null,
      rideStatus: null,
      liveTracking: null,
      error: null,
    );

    _stopRealTimeTracking();

    AppLogger.debug('Ride state cleared');
  }

  /// Get user-friendly error message
  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString();

    if (errorStr.contains('network') || errorStr.contains('connection')) {
      return 'Please check your internet connection';
    } else if (errorStr.contains('rider not available')) {
      return 'This rider is no longer available. Please select another';
    } else if (errorStr.contains('already booked') ||
        errorStr.contains('duplicate')) {
      return 'You already have an active booking';
    } else if (errorStr.contains('timeout')) {
      return 'Request timed out. Please try again';
    } else if (errorStr.contains('location')) {
      return 'Unable to determine your location. Please try again';
    } else {
      return 'Something went wrong. Please try again';
    }
  }

  @override
  void dispose() {
    _stopRealTimeTracking();
    super.dispose();
  }
}

/// Ride provider
final rideProvider = StateNotifierProvider<RideNotifier, RideState>((ref) {
  final apiService = ref.read(apiServiceProvider);
  final firebaseService = ref.read(firebaseServiceProvider);

  return RideNotifier(apiService, firebaseService, ref);
});

/// Convenience providers
final currentRideProvider = Provider<Map<String, dynamic>?>((ref) {
  return ref.watch(rideProvider).currentRide;
});

final rideStatusProvider = Provider<String?>((ref) {
  return ref.watch(rideProvider).rideStatus;
});

final liveTrackingProvider = Provider<Map<String, dynamic>?>((ref) {
  return ref.watch(rideProvider).liveTracking;
});

final rideLoadingProvider = Provider<bool>((ref) {
  return ref.watch(rideProvider).isLoading;
});

final rideErrorProvider = Provider<String?>((ref) {
  return ref.watch(rideProvider).error;
});
