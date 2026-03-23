import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Centralized logging system for AutoWala
/// Handles console logging, crash reporting, and analytics
class AppLogger {
  static bool _isInitialized = false;

  /// Initialize logging system
  static Future<void> init() async {
    if (_isInitialized) return;

    try {
      // Set up Crashlytics for release mode
      if (kReleaseMode) {
        FlutterError.onError =
            FirebaseCrashlytics.instance.recordFlutterFatalError;
        PlatformDispatcher.instance.onError = (error, stack) {
          FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
          return true;
        };
      }

      _isInitialized = true;
      info('AppLogger initialized successfully');
    } catch (e, stackTrace) {
      // Fallback to console logging if Crashlytics fails
      developer.log(
        'Failed to initialize AppLogger: $e',
        name: 'AppLogger',
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

    // Report to Crashlytics in release mode
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
      AppLogger.error('API Error: $method $url', error, null, data);
    } else {
      AppLogger.debug('API: $method $url ${statusCode ?? ''}', data);
    }
  }

  /// Log user interactions for analytics
  static void userAction(
    String action, {
    String? screen,
    Map<String, dynamic>? parameters,
  }) {
    final data = <String, dynamic>{
      'action': action,
      if (screen != null) 'screen': screen,
      if (parameters != null) ...parameters,
      'timestamp': DateTime.now().toIso8601String(),
    };

    info('User Action: $action', data);

    // TODO: Send to analytics service in production
    _sendToAnalytics('user_action', data);
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
      'timestamp': DateTime.now().toIso8601String(),
      if (metadata != null) ...metadata,
    };

    info('Performance: $operation took ${duration.inMilliseconds}ms', data);
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

    // Console logging
    switch (level) {
      case LogLevel.debug:
        developer.log(
          logMessage,
          name: 'AutoWala.Debug',
          time: DateTime.now(),
        );
        break;

      case LogLevel.info:
        developer.log(
          logMessage,
          name: 'AutoWala.Info',
          time: DateTime.now(),
        );
        break;

      case LogLevel.warning:
        developer.log(
          logMessage,
          name: 'AutoWala.Warning',
          time: DateTime.now(),
          level: 900,
        );
        break;

      case LogLevel.error:
        developer.log(
          logMessage,
          name: 'AutoWala.Error',
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
        name: 'AutoWala.Data',
      );
    }
  }

  /// Format log message with consistent structure
  static String _formatLogMessage(
      LogLevel level, String message, String timestamp) {
    final levelStr = level.toString().split('.').last.toUpperCase();
    return '[$levelStr] $message';
  }

  /// Report errors to Crashlytics
  static Future<void> _reportToCrashlytics(
    String message,
    Object error,
    StackTrace? stackTrace,
    Map<String, dynamic>? data,
  ) async {
    try {
      // Set custom keys for additional context
      final crashlytics = FirebaseCrashlytics.instance;

      if (data != null) {
        for (final entry in data.entries) {
          await crashlytics.setCustomKey(entry.key, entry.value.toString());
        }
      }

      // Record the error
      await crashlytics.recordError(
        error,
        stackTrace,
        reason: message,
        fatal: false,
      );
    } catch (e) {
      // Fallback to console if Crashlytics fails
      developer.log(
        'Failed to report to Crashlytics: $e',
        name: 'AppLogger.Crashlytics',
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

  /// Set user identifier for crash reporting
  static Future<void> setUserId(String userId) async {
    try {
      if (kReleaseMode) {
        await FirebaseCrashlytics.instance.setUserIdentifier(userId);
      }
      debug('User ID set for crash reporting: $userId');
    } catch (e) {
      debug('Failed to set user ID for crash reporting: $e');
    }
  }

  /// Set custom user properties
  static Future<void> setUserProperties(Map<String, String> properties) async {
    try {
      if (kReleaseMode) {
        final crashlytics = FirebaseCrashlytics.instance;
        for (final entry in properties.entries) {
          await crashlytics.setCustomKey(entry.key, entry.value);
        }
      }
      debug('User properties set: $properties');
    } catch (e) {
      debug('Failed to set user properties: $e');
    }
  }

  /// Log app lifecycle events
  static void appLifecycle(String event, {Map<String, dynamic>? data}) {
    info('App Lifecycle: $event', data);
    userAction('app_lifecycle_$event');
  }

  /// Log navigation events
  static void navigation(String from, String to, {Map<String, dynamic>? data}) {
    final navigationData = <String, dynamic>{
      'from': from,
      'to': to,
      if (data != null) ...data,
    };

    debug('Navigation: $from -> $to', navigationData);
    userAction('navigation', parameters: navigationData);
  }

  /// Log network connectivity changes
  static void connectivity(String status, {Map<String, dynamic>? data}) {
    info('Connectivity: $status', data);
    userAction('connectivity_change',
        parameters: {'status': status, if (data != null) ...data});
  }

  /// Log location events
  static void location(String event,
      {double? latitude, double? longitude, Map<String, dynamic>? data}) {
    final locationData = <String, dynamic>{
      'event': event,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (data != null) ...data,
    };

    debug('Location: $event', locationData);
    userAction('location_$event', parameters: locationData);
  }

  /// Log ride-related events
  static void ride(String event, {String? rideId, Map<String, dynamic>? data}) {
    final rideData = <String, dynamic>{
      'event': event,
      if (rideId != null) 'ride_id': rideId,
      if (data != null) ...data,
    };

    info('Ride: $event', rideData);
    userAction('ride_$event', parameters: rideData);
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

/// Specialized logger for performance monitoring
class PerformanceLogger {
  final String _operation;
  final Stopwatch _stopwatch = Stopwatch();
  final Map<String, dynamic>? _metadata;

  PerformanceLogger(this._operation, [this._metadata]) {
    _stopwatch.start();
    AppLogger.debug('Performance: Starting $operation');
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
        'Performance: $operation checkpoint "$checkpointName" at ${elapsed.inMilliseconds}ms');
  }

  /// Get current elapsed time
  Duration get elapsed => _stopwatch.elapsed;
}

/// Extension for easy performance logging
extension PerformanceLogging on Function {
  /// Wrap function execution with performance logging
  Future<T> withPerformanceLogging<T>(
    String operationName, [
    Map<String, dynamic>? metadata,
  ]) async {
    final logger = PerformanceLogger(operationName, metadata);
    try {
      final result = await this();
      logger.stop('completed');
      return result;
    } catch (e, stackTrace) {
      logger.stop('failed');
      AppLogger.error('Performance: $operationName failed', e, stackTrace);
      rethrow;
    }
  }
}
