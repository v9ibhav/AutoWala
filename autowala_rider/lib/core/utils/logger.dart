import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
// Note: Firebase will be added when credentials are provided
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Centralized logging system for AutoWala Rider
/// Handles console logging, crash reporting, and rider-specific analytics
class AppLogger {
  static bool _isInitialized = false;

  /// Initialize logging system
  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Set up Crashlytics for release mode (when Firebase is configured)
      if (kReleaseMode) {
        // TODO: Uncomment when Firebase is properly configured
        /*
        FlutterError.onError =
            FirebaseCrashlytics.instance.recordFlutterFatalError;
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
        */
      }

      _isInitialized = true;
      info('Rider AppLogger initialized successfully');
    } catch (e, stackTrace) {
      // Fallback to console logging if Crashlytics fails
      developer.log(
        'Failed to initialize Rider AppLogger: $e',
        name: 'RiderAppLogger',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Log info messages
  static void info(String message, [Map<String, dynamic>? data]) {
    _log(LogLevel.info, message, data: data);
  }

  /// Log warning messages
  static void warning(String message, [Map<String, dynamic>? data]) {
    _log(LogLevel.warning, message, data: data);
  }

  /// Log error messages
  static void error(
    String message, [
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  ]) {
    _log(
      LogLevel.error,
      message,
      error: error,
      stackTrace: stackTrace,
      data: data,
    );

    // Report to Crashlytics in release mode (when available)
    if (kReleaseMode && error != null) {
      _reportToCrashlytics(message, error, stackTrace, data);
    }
  }

  /// Log debug messages (only in debug mode)
  static void debug(String message, [Map<String, dynamic>? data]) {
    if (kDebugMode) {
      _log(LogLevel.debug, message, data: data);
    }
  }

  /// Log API requests and responses
  static void api(
    String method,
    String url, {
    int? statusCode,
    Object? requestData,
    Object? responseData,
    Object? error,
    Duration? duration,
  }) {
    final data = <String, dynamic>{
      'method': method,
      'url': url,
      if (statusCode != null) 'statusCode': statusCode,
      if (requestData != null) 'request': requestData,
      if (responseData != null) 'response': responseData,
      if (duration != null) 'duration': '${duration.inMilliseconds}ms',
    };

    if (error != null) {
      AppLogger.error('Rider API Error: $method $url', error, null, data);
    } else {
      AppLogger.debug('Rider API: $method $url ${statusCode ?? ''}', data);
    }
  }

  /// Log rider-specific actions for analytics
  static void riderAction(
    String action, {
    String? screen,
    String? rideId,
    Map<String, dynamic>? parameters,
  }) {
    final data = <String, dynamic>{
      'action': action,
      'user_type': 'rider',
      if (screen != null) 'screen': screen,
      if (rideId != null) 'ride_id': rideId,
      if (parameters != null) ...parameters,
      'timestamp': DateTime.now().toIso8601String(),
    };

    info('Rider Action: $action', data);

    // Send to analytics service in production
    _sendToAnalytics('rider_action', data);
  }

  /// Log performance metrics
  static void performance(
    String operation,
    Duration duration, {
    Map<String, dynamic>? metadata,
  }) {
    final data = <String, dynamic>{
      'operation': operation,
      'duration_ms': duration.inMilliseconds,
      'user_type': 'rider',
      'timestamp': DateTime.now().toIso8601String(),
      if (metadata != null) ...metadata,
    };

    info('Rider Performance: $operation took ${duration.inMilliseconds}ms', data);
  }

  /// Core logging implementation
  static void _log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final logMessage = _formatLogMessage(level, message, timestamp);

    // Console logging with rider-specific prefix
    switch (level) {
      case LogLevel.debug:
        developer.log(
          logMessage,
          name: 'AutoWala.Rider.Debug',
          time: DateTime.now(),
        );
        break;

      case LogLevel.info:
        developer.log(
          logMessage,
          name: 'AutoWala.Rider.Info',
          time: DateTime.now(),
        );
        break;

      case LogLevel.warning:
        developer.log(
          logMessage,
          name: 'AutoWala.Rider.Warning',
          time: DateTime.now(),
          level: 900,
        );
        break;

      case LogLevel.error:
        developer.log(
          logMessage,
          name: 'AutoWala.Rider.Error',
          error: error,
          stackTrace: stackTrace,
          time: DateTime.now(),
          level: 1000,
        );
        break;
    }

    // Print additional data in debug mode
    if (kDebugMode && data != null && data.isNotEmpty) {
      developer.log(
        'Data: ${data.toString()}',
        name: 'AutoWala.Rider.Data',
      );
    }
  }

  /// Format log message with consistent structure
  static String _formatLogMessage(
      LogLevel level, String message, String timestamp) {
    final levelStr = level.toString().split('.').last.toUpperCase();
    return '[RIDER-$levelStr] $message';
  }

  /// Report errors to Crashlytics (when available)
  static Future<void> _reportToCrashlytics(
    String message,
    Object error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  ) async {
    try {
      // TODO: Uncomment when Firebase is configured
      /*
      final crashlytics = FirebaseCrashlytics.instance;

      // Set custom keys for additional context
      if (data != null) {
        for (final entry in data.entries) {
          await crashlytics.setCustomKey(entry.key, entry.value.toString());
        }
      }

      // Mark as rider app
      await crashlytics.setCustomKey('app_type', 'rider');

      // Record the error
      await crashlytics.recordError(
        error,
        stackTrace,
        reason: message,
        fatal: false,
      );
      */
    } catch (e) {
      // Fallback to console if Crashlytics fails
      developer.log(
        'Failed to report to Crashlytics: $e',
        name: 'RiderAppLogger.Crashlytics',
        error: e,
      );
    }
  }

  /// Send events to analytics service
  static void _sendToAnalytics(
      String eventName, Map<String, dynamic> parameters) {
    if (!kReleaseMode) return;

    try {
      // TODO: Implement Firebase Analytics or other analytics service
      // FirebaseAnalytics.instance.logEvent(
      //   name: eventName,
      //   parameters: parameters,
      // );
    } catch (e) {
      debug('Failed to send analytics event: $e');
    }
  }

  /// Rider-specific logging methods

  /// Log ride events
  static void ride(String event, {String? rideId, Map<String, dynamic>? data}) {
    final rideData = <String, dynamic>{
      'event': event,
      'user_type': 'rider',
      if (rideId != null) 'ride_id': rideId,
      if (data != null) ...data,
    };

    info('Rider Ride: $event', rideData);
    riderAction('ride_$event', parameters: rideData);
  }

  /// Log location events
  static void location(String event,
      {double? latitude, double? longitude, Map<String, dynamic>? data}) {
    final locationData = <String, dynamic>{
      'event': event,
      'user_type': 'rider',
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (data != null) ...data,
    };

    debug('Rider Location: $event', locationData);
    riderAction('location_$event', parameters: locationData);
  }

  /// Log online/offline status changes
  static void statusChange(String status, {Map<String, dynamic>? data}) {
    final statusData = <String, dynamic>{
      'status': status,
      'user_type': 'rider',
      'timestamp': DateTime.now().toIso8601String(),
      if (data != null) ...data,
    };

    info('Rider Status Change: $status', statusData);
    riderAction('status_change', parameters: statusData);
  }

  /// Log earnings events
  static void earnings(String event, {double? amount, Map<String, dynamic>? data}) {
    final earningsData = <String, dynamic>{
      'event': event,
      'user_type': 'rider',
      if (amount != null) 'amount': amount,
      if (data != null) ...data,
    };

    info('Rider Earnings: $event', earningsData);
    riderAction('earnings_$event', parameters: earningsData);
  }

  /// Set rider identifier for crash reporting
  static Future<void> setRiderId(String riderId) async {
    try {
      if (kReleaseMode) {
        // TODO: Uncomment when Firebase is configured
        // await FirebaseCrashlytics.instance.setUserIdentifier(riderId);
      }
      debug('Rider ID set for crash reporting: $riderId');
    } catch (e) {
      debug('Failed to set rider ID for crash reporting: $e');
    }
  }

  /// Set rider properties
  static Future<void> setRiderProperties(Map<String, String> properties) async {
    try {
      if (kReleaseMode) {
        // TODO: Uncomment when Firebase is configured
        /*
        final crashlytics = FirebaseCrashlytics.instance;
        await crashlytics.setCustomKey('app_type', 'rider');
        for (final entry in properties.entries) {
          await crashlytics.setCustomKey(entry.key, entry.value);
        }
        */
      }
      debug('Rider properties set: $properties');
    } catch (e) {
      debug('Failed to set rider properties: $e');
    }
  }

  /// Log app lifecycle events
  static void appLifecycle(String event, {Map<String, dynamic>? data}) {
    info('Rider App Lifecycle: $event', data);
    riderAction('app_lifecycle_$event');
  }

  /// Log navigation events
  static void navigation(String from, String to, {Map<String, dynamic>? data}) {
    final navigationData = <String, dynamic>{
      'from': from,
      'to': to,
      'user_type': 'rider',
      if (data != null) ...data,
    };

    debug('Rider Navigation: $from -> $to', navigationData);
    riderAction('navigation', parameters: navigationData);
  }

  /// Log network connectivity changes
  static void connectivity(String status, {Map<String, dynamic>? data}) {
    info('Rider Connectivity: $status', data);
    riderAction('connectivity_change',
        parameters: {'status': status, if (data != null) ...data});
  }

  /// Check if logger is initialized
  static bool get isInitialized => _isInitialized;
}

/// Log levels for categorizing messages
enum LogLevel {
  debug,
  info,
  warning,
  error,
}

/// Specialized logger for rider performance monitoring
class RiderPerformanceLogger {
  final String _operation;
  final Stopwatch _stopwatch = Stopwatch();
  final Map<String, dynamic>? _metadata;

  RiderPerformanceLogger(this._operation, [this._metadata]) {
    _stopwatch.start();
    AppLogger.debug('Rider Performance: Starting $operation');
  }

  String get operation => _operation;

  /// Stop timing and log performance
  void stop([String? additionalInfo]) {
    _stopwatch.stop();
    final message =
        additionalInfo != null ? '$operation - $additionalInfo' : operation;

    AppLogger.performance(message, _stopwatch.elapsed, metadata: _metadata);
  }

  /// Add checkpoint timing
  void checkpoint(String checkpointName) {
    final elapsed = _stopwatch.elapsed;
    AppLogger.debug(
        'Rider Performance: $operation checkpoint "$checkpointName" at ${elapsed.inMilliseconds}ms');
  }

  /// Get current elapsed time
  Duration get elapsed => _stopwatch.elapsed;
}