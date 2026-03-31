import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';

class FirebaseService {
  static FirebaseService? _instance;
  static FirebaseService get instance => _instance ??= FirebaseService._();

  FirebaseService._();

  late FirebaseDatabase _database;
  late FirebaseMessaging _messaging;
  late FirebaseAnalytics _analytics;

  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await Firebase.initializeApp();

      _database = FirebaseDatabase.instance;
      _messaging = FirebaseMessaging.instance;
      _analytics = FirebaseAnalytics.instance;

      // Configure Firebase Crashlytics
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

      // Initialize messaging
      await _initializeMessaging();

      _isInitialized = true;
    } catch (e) {
      print('Firebase initialization failed: $e');
      rethrow;
    }
  }

  Future<void> _initializeMessaging() async {
    // Request permission for notifications
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('User granted permission');
    } else {
      print('User declined or has not accepted permission');
    }

    // Get FCM token
    String? token = await _messaging.getToken();
    print('FCM Token: $token');

    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Received foreground message: ${message.notification?.title}');

      // Handle the message here - show local notification or update UI
      _handleMessage(message);
    });
  }

  void _handleMessage(RemoteMessage message) {
    // Handle different types of messages
    final messageType = message.data['type'];

    switch (messageType) {
      case 'ride_request':
        _handleRideRequest(message);
        break;
      case 'ride_accepted':
        _handleRideAccepted(message);
        break;
      case 'ride_started':
        _handleRideStarted(message);
        break;
      case 'ride_completed':
        _handleRideCompleted(message);
        break;
      case 'location_update':
        _handleLocationUpdate(message);
        break;
      default:
        print('Unknown message type: $messageType');
    }
  }

  void _handleRideRequest(RemoteMessage message) {
    final rideId = message.data['ride_id'];
    print('New ride request: $rideId');
    // Implement ride request handling
  }

  void _handleRideAccepted(RemoteMessage message) {
    final rideId = message.data['ride_id'];
    print('Ride accepted: $rideId');
    // Implement ride accepted handling
  }

  void _handleRideStarted(RemoteMessage message) {
    final rideId = message.data['ride_id'];
    print('Ride started: $rideId');
    // Implement ride started handling
  }

  void _handleRideCompleted(RemoteMessage message) {
    final rideId = message.data['ride_id'];
    print('Ride completed: $rideId');
    // Implement ride completed handling
  }

  void _handleLocationUpdate(RemoteMessage message) {
    final riderId = message.data['rider_id'];
    final latitude = double.tryParse(message.data['latitude'] ?? '0');
    final longitude = double.tryParse(message.data['longitude'] ?? '0');
    print('Location update for rider $riderId: $latitude, $longitude');
    // Implement location update handling
  }

  // Real-time database methods
  DatabaseReference getRiderLocationRef(String riderId) {
    return _database.ref('riders/$riderId/location');
  }

  DatabaseReference getRideTrackingRef(String rideId) {
    return _database.ref('rides/$rideId/tracking');
  }

  Stream<DatabaseEvent> watchRiderLocation(String riderId) {
    return getRiderLocationRef(riderId).onValue;
  }

  Stream<DatabaseEvent> watchRideUpdates(String rideId) {
    return getRideTrackingRef(rideId).onValue;
  }

  // Ride tracking methods (aliases for providers)
  void listenToRideUpdates(String rideId, Function(Map<String, dynamic>) onUpdate, Function(String) onError) {
    try {
      watchRideUpdates(rideId).listen(
        (event) {
          if (event.snapshot.exists && event.snapshot.value != null) {
            final data = Map<String, dynamic>.from(event.snapshot.value as Map);
            onUpdate(data);
          }
        },
        onError: (error) {
          onError(error.toString());
        },
      );
    } catch (e) {
      onError(e.toString());
    }
  }

  void stopListeningToRideUpdates() {
    // In a real implementation, you'd cancel the subscription
    // For now, this is a placeholder
  }

  Future<void> updateRiderLocation(String riderId, Map<String, dynamic> locationData) async {
    try {
      await getRiderLocationRef(riderId).set({
        ...locationData,
        'timestamp': ServerValue.timestamp,
      });
    } catch (e) {
      print('Failed to update rider location: $e');
      rethrow;
    }
  }

  Future<void> updateRideTracking(String rideId, Map<String, dynamic> trackingData) async {
    try {
      await getRideTrackingRef(rideId).update({
        ...trackingData,
        'timestamp': ServerValue.timestamp,
      });
    } catch (e) {
      print('Failed to update ride tracking: $e');
      rethrow;
    }
  }

  // User presence
  Future<void> setUserOnline(String userId) async {
    try {
      final userRef = _database.ref('users/$userId');
      await userRef.update({
        'online': true,
        'lastSeen': ServerValue.timestamp,
      });

      // Set user offline when connection is lost
      userRef.onDisconnect().update({
        'online': false,
        'lastSeen': ServerValue.timestamp,
      });
    } catch (e) {
      print('Failed to set user online: $e');
    }
  }

  Future<void> setUserOffline(String userId) async {
    try {
      await _database.ref('users/$userId').update({
        'online': false,
        'lastSeen': ServerValue.timestamp,
      });
    } catch (e) {
      print('Failed to set user offline: $e');
    }
  }

  // Analytics methods
  Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
    } catch (e) {
      print('Failed to log analytics event: $e');
    }
  }

  Future<void> logLogin(String loginMethod) async {
    await logEvent('login', parameters: {'method': loginMethod});
  }

  Future<void> logRideBooked(String rideId, double fare) async {
    await logEvent('ride_booked', parameters: {
      'ride_id': rideId,
      'fare': fare,
    });
  }

  Future<void> logRideCompleted(String rideId, double fare, int rating) async {
    await logEvent('ride_completed', parameters: {
      'ride_id': rideId,
      'fare': fare,
      'rating': rating,
    });
  }

  // Error reporting
  Future<void> recordError(dynamic exception, StackTrace stackTrace) async {
    try {
      await FirebaseCrashlytics.instance.recordError(
        exception,
        stackTrace,
        fatal: false,
      );
    } catch (e) {
      print('Failed to record error: $e');
    }
  }

  Future<void> setUserId(String userId) async {
    try {
      await FirebaseCrashlytics.instance.setUserIdentifier(userId);
      await _analytics.setUserId(id: userId);
    } catch (e) {
      print('Failed to set user ID: $e');
    }
  }

  Future<void> setUserProperty(String name, String value) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      print('Failed to set user property: $e');
    }
  }

  // FCM token management
  Future<String?> getFCMToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      print('Failed to get FCM token: $e');
      return null;
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _messaging.subscribeToTopic(topic);
    } catch (e) {
      print('Failed to subscribe to topic: $e');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _messaging.unsubscribeFromTopic(topic);
    } catch (e) {
      print('Failed to unsubscribe from topic: $e');
    }
  }
}

// Background message handler (must be top level function)
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print('Handling background message: ${message.messageId}');
}

// Riverpod provider
final firebaseServiceProvider = Provider<FirebaseService>((ref) {
  return FirebaseService.instance;
});