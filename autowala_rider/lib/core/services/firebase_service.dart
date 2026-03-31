import 'dart:async';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../utils/app_constants.dart';
import '../utils/logger.dart';

/// Firebase service for AutoWala Rider app
/// Handles real-time database, messaging, and rider-specific Firebase operations
class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance => _instance ??= FirebaseService._();

  FirebaseService._();

  FirebaseDatabase? _database;
  FirebaseMessaging? _messaging;
  String? _riderId;
  StreamSubscription<DatabaseEvent>? _rideRequestSubscription;
  StreamSubscription<DatabaseEvent>? _activeRideSubscription;

  /// Initialize Firebase services
  Future<void> init() async {
    try {
      // Initialize Firebase if not already done
      await Firebase.initializeApp();

      // Initialize Realtime Database
      _database = FirebaseDatabase.instance;

      // Configure database for offline persistence
      await _database!.setPersistenceEnabled(true);
      await _database!.setPersistenceCacheSizeBytes(10000000); // 10MB cache

      // Initialize Firebase Messaging
      _messaging = FirebaseMessaging.instance;

      // Request notification permissions
      await _requestNotificationPermission();

      // Set up message handlers
      _setupMessageHandlers();

      AppLogger.info('Rider FirebaseService initialized successfully');
    } catch (e, stackTrace) {
      AppLogger.error('Failed to initialize Rider FirebaseService', e, stackTrace);
      rethrow;
    }
  }

  /// Request notification permissions
  Future<void> _requestNotificationPermission() async {
    try {
      final settings = await _messaging!.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        announcement: false,
        carPlay: false,
        criticalAlert: false,
      );

      AppLogger.info('Rider notification permission status: ${settings.authorizationStatus}');
    } catch (e) {
      AppLogger.error('Failed to request notification permission', e);
    }
  }

  /// Set up Firebase messaging handlers
  void _setupMessageHandlers() {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      AppLogger.info('Rider received foreground message', {
        'title': message.notification?.title,
        'body': message.notification?.body,
        'data': message.data,
      });

      _handleIncomingMessage(message);
    });

    // Handle messages when app is in background/terminated and user taps notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      AppLogger.info('Rider app opened via notification', {
        'title': message.notification?.title,
        'body': message.notification?.body,
        'data': message.data,
      });

      _handleNotificationTap(message);
    });

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  /// Handle incoming messages based on type
  void _handleIncomingMessage(RemoteMessage message) {
    final messageType = message.data['type'];

    switch (messageType) {
      case 'ride_request':
        _handleRideRequest(message.data);
        break;
      case 'ride_cancelled':
        _handleRideCancellation(message.data);
        break;
      case 'payment_received':
        _handlePaymentNotification(message.data);
        break;
      default:
        AppLogger.debug('Rider received unknown message type: $messageType');
    }
  }

  /// Handle notification tap navigation
  void _handleNotificationTap(RemoteMessage message) {
    final messageType = message.data['type'];
    final rideId = message.data['ride_id'];

    // TODO: Navigate to appropriate screen based on message type
    // This would be implemented with the navigation service
    AppLogger.riderAction('notification_tapped', parameters: {
      'message_type': messageType,
      'ride_id': rideId,
    });
  }

  /// Handle ride request notifications
  void _handleRideRequest(Map<String, dynamic> data) {
    AppLogger.ride('request_received', data: data);

    // TODO: Show ride request UI
    // This would trigger a local notification or update UI state
  }

  /// Handle ride cancellation notifications
  void _handleRideCancellation(Map<String, dynamic> data) {
    AppLogger.ride('request_cancelled', data: data);

    // TODO: Update UI to remove ride request
  }

  /// Handle payment notifications
  void _handlePaymentNotification(Map<String, dynamic> data) {
    AppLogger.earnings('payment_received',
        amount: double.tryParse(data['amount']?.toString() ?? '0'),
        data: data);

    // TODO: Update earnings UI
  }

  /// Set rider ID for personalized notifications
  void setRiderId(String riderId) {
    _riderId = riderId;
    AppLogger.info('Rider ID set for Firebase: $riderId');
  }

  /// Get FCM token for push notifications
  Future<String?> getMessagingToken() async {
    try {
      final token = await _messaging!.getToken();
      AppLogger.debug('Rider FCM token obtained', {'token_length': token?.length});
      return token;
    } catch (e) {
      AppLogger.error('Failed to get FCM token', e);
      return null;
    }
  }

  /// Update rider location in real-time database
  Future<void> updateLocation({
    required double latitude,
    required double longitude,
    double? heading,
    double? speed,
    int? accuracy,
  }) async {
    if (_riderId == null || _database == null) {
      AppLogger.warning('Cannot update location: Rider ID or database not initialized');
      return;
    }

    try {
      final locationData = {
        'latitude': latitude,
        'longitude': longitude,
        'heading': heading ?? 0,
        'speed': speed ?? 0,
        'accuracy': accuracy ?? 10,
        'timestamp': ServerValue.timestamp,
        'last_update': DateTime.now().toIso8601String(),
      };

      await _database!
          .ref('active_riders/$_riderId/location')
          .set(locationData);

      AppLogger.location('updated', latitude: latitude, longitude: longitude, data: {
        'heading': heading,
        'speed': speed,
        'accuracy': accuracy,
      });
    } catch (e) {
      AppLogger.error('Failed to update rider location in Firebase', e);
    }
  }

  /// Set rider online status
  Future<void> setOnlineStatus(bool isOnline) async {
    if (_riderId == null || _database == null) return;

    try {
      final statusData = {
        'is_online': isOnline,
        'status': isOnline ? 'online' : 'offline',
        'timestamp': ServerValue.timestamp,
        'last_status_change': DateTime.now().toIso8601String(),
      };

      await _database!
          .ref('active_riders/$_riderId/status')
          .set(statusData);

      AppLogger.statusChange(
        isOnline ? 'online' : 'offline',
        data: statusData,
      );

      if (isOnline) {
        _startListeningForRideRequests();
      } else {
        _stopListeningForRideRequests();
        await _removeFromActiveRiders();
      }
    } catch (e) {
      AppLogger.error('Failed to update rider online status', e);
    }
  }

  /// Remove rider from active riders when going offline
  Future<void> _removeFromActiveRiders() async {
    if (_riderId == null || _database == null) return;

    try {
      await _database!.ref('active_riders/$_riderId').remove();
      AppLogger.info('Rider removed from active riders list');
    } catch (e) {
      AppLogger.error('Failed to remove rider from active riders', e);
    }
  }

  /// Start listening for ride requests
  void _startListeningForRideRequests() {
    if (_riderId == null || _database == null) return;

    _rideRequestSubscription?.cancel();

    _rideRequestSubscription = _database!
        .ref('ride_requests/rider_$_riderId')
        .onValue
        .listen((DatabaseEvent event) {

      if (event.snapshot.exists) {
        final rideData = Map<String, dynamic>.from(event.snapshot.value as Map);
        AppLogger.info('Rider received ride request via Firebase', rideData);

        _handleRideRequest(rideData);
      }
    });

    AppLogger.info('Started listening for ride requests');
  }

  /// Stop listening for ride requests
  void _stopListeningForRideRequests() {
    _rideRequestSubscription?.cancel();
    _rideRequestSubscription = null;
    AppLogger.info('Stopped listening for ride requests');
  }

  /// Accept ride request
  Future<void> acceptRideRequest(String rideId) async {
    if (_riderId == null || _database == null) return;

    try {
      final acceptanceData = {
        'rider_id': _riderId,
        'status': 'accepted',
        'accepted_at': ServerValue.timestamp,
        'accepted_timestamp': DateTime.now().toIso8601String(),
      };

      // Update ride status
      await _database!
          .ref('rides/$rideId/acceptance')
          .set(acceptanceData);

      // Remove from rider's request queue
      await _database!
          .ref('ride_requests/rider_$_riderId/$rideId')
          .remove();

      // Start active ride session
      await _startActiveRideSession(rideId);

      AppLogger.ride('accepted', rideId: rideId, data: acceptanceData);
    } catch (e) {
      AppLogger.error('Failed to accept ride request', e);
    }
  }

  /// Reject ride request
  Future<void> rejectRideRequest(String rideId, String reason) async {
    if (_riderId == null || _database == null) return;

    try {
      // Remove from rider's request queue
      await _database!
          .ref('ride_requests/rider_$_riderId/$rideId')
          .remove();

      // Log rejection
      await _database!
          .ref('ride_rejections/$rideId/riders/$_riderId')
          .set({
            'rejected_at': ServerValue.timestamp,
            'reason': reason,
          });

      AppLogger.ride('rejected', rideId: rideId, data: {'reason': reason});
    } catch (e) {
      AppLogger.error('Failed to reject ride request', e);
    }
  }

  /// Start active ride session
  Future<void> _startActiveRideSession(String rideId) async {
    if (_riderId == null || _database == null) return;

    try {
      _activeRideSubscription?.cancel();

      _activeRideSubscription = _database!
          .ref('active_rides/$rideId')
          .onValue
          .listen((DatabaseEvent event) {

        if (event.snapshot.exists) {
          final rideData = Map<String, dynamic>.from(event.snapshot.value as Map);
          AppLogger.debug('Active ride update received', rideData);

          // TODO: Update UI with ride status changes
        }
      });

      AppLogger.info('Started active ride session for ride: $rideId');
    } catch (e) {
      AppLogger.error('Failed to start active ride session', e);
    }
  }

  /// Update ride status (pickup, complete, etc.)
  Future<void> updateRideStatus(String rideId, String status, {
    Map<String, dynamic>? additionalData,
  }) async {
    if (_riderId == null || _database == null) return;

    try {
      final updateData = {
        'status': status,
        'rider_id': _riderId,
        'updated_at': ServerValue.timestamp,
        'updated_timestamp': DateTime.now().toIso8601String(),
        if (additionalData != null) ...additionalData,
      };

      await _database!
          .ref('active_rides/$rideId/status_updates/$status')
          .set(updateData);

      AppLogger.ride('status_updated', rideId: rideId, data: updateData);
    } catch (e) {
      AppLogger.error('Failed to update ride status', e);
    }
  }

  /// Complete ride and end session
  Future<void> completeRide(String rideId, Map<String, dynamic> completionData) async {
    if (_riderId == null || _database == null) return;

    try {
      // Update ride completion data
      await updateRideStatus(rideId, 'completed', additionalData: completionData);

      // End active ride session
      _activeRideSubscription?.cancel();
      _activeRideSubscription = null;

      // Move to completed rides
      await _database!
          .ref('completed_rides/$rideId')
          .set({
            'rider_id': _riderId,
            'completed_at': ServerValue.timestamp,
            ...completionData,
          });

      // Remove from active rides
      await _database!.ref('active_rides/$rideId').remove();

      AppLogger.ride('completed', rideId: rideId, data: completionData);
    } catch (e) {
      AppLogger.error('Failed to complete ride', e);
    }
  }

  /// Send rider status update (break, busy, etc.)
  Future<void> updateRiderStatus(String status, {
    Map<String, dynamic>? metadata,
  }) async {
    if (_riderId == null || _database == null) return;

    try {
      final statusData = {
        'status': status,
        'timestamp': ServerValue.timestamp,
        'updated_at': DateTime.now().toIso8601String(),
        if (metadata != null) ...metadata,
      };

      await _database!
          .ref('active_riders/$_riderId/rider_status')
          .set(statusData);

      AppLogger.statusChange(status, data: statusData);
    } catch (e) {
      AppLogger.error('Failed to update rider status', e);
    }
  }

  /// Clean up resources
  Future<void> dispose() async {
    try {
      _rideRequestSubscription?.cancel();
      _activeRideSubscription?.cancel();

      if (_riderId != null) {
        await _removeFromActiveRiders();
      }

      AppLogger.info('Rider FirebaseService disposed');
    } catch (e) {
      AppLogger.error('Error disposing Rider FirebaseService', e);
    }
  }

  /// Check if Firebase is initialized and ready
  bool get isInitialized => _database != null && _messaging != null;
}

/// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();

  AppLogger.info('Rider handling background message', {
    'title': message.notification?.title,
    'body': message.notification?.body,
    'data': message.data,
  });

  // Handle critical background actions like ride cancellations
  final messageType = message.data['type'];
  if (messageType == 'ride_cancelled' || messageType == 'urgent_update') {
    // Handle urgent background notifications
    // This could trigger local notifications or update local storage
  }
}