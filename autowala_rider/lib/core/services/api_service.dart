import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import '../utils/app_constants.dart';
import '../utils/logger.dart';

/// HTTP client service for AutoWala Rider API communication
class ApiService {
  static ApiService? _instance;
  static ApiService get instance => _instance ??= ApiService._();

  ApiService._();

  late final http.Client _client;
  String? _authToken;

  /// Initialize the API service
  void init() {
    _client = http.Client();
    AppLogger.info('ApiService initialized');
  }

  /// Set authentication token
  void setAuthToken(String? token) {
    _authToken = token;
    AppLogger.debug('Auth token updated', {'has_token': token != null});
  }

  /// Get authentication token
  String? get authToken => _authToken;

  /// Check if user is authenticated
  bool get isAuthenticated => _authToken != null && _authToken!.isNotEmpty;

  /// Build request headers
  Map<String, String> _buildHeaders({Map<String, String>? additionalHeaders}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'AutoWala-Rider/${AppConstants.version}',
    };

    // Add auth token if available
    if (_authToken != null && _authToken!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    // Add additional headers
    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  /// Build full URL
  String _buildUrl(String endpoint) {
    final baseUrl = AppConstants.apiBaseUrl;

    // Remove leading slash if present
    if (endpoint.startsWith('/')) {
      endpoint = endpoint.substring(1);
    }

    return '$baseUrl/$endpoint';
  }

  /// Handle API response
  Map<String, dynamic> _handleResponse(
    http.Response response,
    String method,
    String url,
  ) {
    final statusCode = response.statusCode;

    AppLogger.api(
      method,
      url,
      statusCode: statusCode,
      duration: null, // Could add timing if needed
    );

    try {
      final body = utf8.decode(response.bodyBytes);
      final data = json.decode(body) as Map<String, dynamic>;

      if (statusCode >= 200 && statusCode < 300) {
        return data;
      } else {
        final errorMessage = data['message'] ?? 'Request failed';
        throw ApiException(
          message: errorMessage,
          statusCode: statusCode,
          data: data,
        );
      }
    } catch (e) {
      if (e is ApiException) rethrow;

      AppLogger.error('Failed to parse API response', e, null, {
        'status_code': statusCode,
        'response_body': response.body,
        'url': url,
      });

      throw ApiException(
        message: 'Failed to parse server response',
        statusCode: statusCode,
        data: {'raw_response': response.body},
      );
    }
  }

  /// Handle network errors
  Never _handleNetworkError(Object error, String method, String url) {
    String message;

    if (error is SocketException) {
      message = 'No internet connection available';
    } else if (error is HttpException) {
      message = 'Network request failed';
    } else if (error is FormatException) {
      message = 'Invalid server response format';
    } else {
      message = 'Network error occurred';
    }

    AppLogger.error('Network error', error, null, {
      'method': method,
      'url': url,
      'error_type': error.runtimeType.toString(),
    });

    throw ApiException(
      message: message,
      statusCode: 0,
      data: {'original_error': error.toString()},
    );
  }

  /// Perform GET request
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, String>? headers,
    Map<String, String>? queryParams,
  }) async {
    try {
      var url = _buildUrl(endpoint);

      // Add query parameters
      if (queryParams != null && queryParams.isNotEmpty) {
        final uri = Uri.parse(url);
        final newUri = uri.replace(queryParameters: {
          ...uri.queryParameters,
          ...queryParams,
        });
        url = newUri.toString();
      }

      final response = await _client
          .get(
            Uri.parse(url),
            headers: _buildHeaders(additionalHeaders: headers),
          )
          .timeout(AppConstants.networkTimeout);

      return _handleResponse(response, 'GET', url);
    } catch (e) {
      _handleNetworkError(e, 'GET', endpoint);
    }
  }

  /// Perform POST request
  Future<Map<String, dynamic>> post(
    String endpoint,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
  }) async {
    try {
      final url = _buildUrl(endpoint);
      final response = await _client
          .post(
            Uri.parse(url),
            headers: _buildHeaders(additionalHeaders: headers),
            body: json.encode(data),
          )
          .timeout(AppConstants.networkTimeout);

      return _handleResponse(response, 'POST', url);
    } catch (e) {
      _handleNetworkError(e, 'POST', endpoint);
    }
  }

  /// Perform PUT request
  Future<Map<String, dynamic>> put(
    String endpoint,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
  }) async {
    try {
      final url = _buildUrl(endpoint);
      final response = await _client
          .put(
            Uri.parse(url),
            headers: _buildHeaders(additionalHeaders: headers),
            body: json.encode(data),
          )
          .timeout(AppConstants.networkTimeout);

      return _handleResponse(response, 'PUT', url);
    } catch (e) {
      _handleNetworkError(e, 'PUT', endpoint);
    }
  }

  /// Perform PATCH request
  Future<Map<String, dynamic>> patch(
    String endpoint,
    Map<String, dynamic> data, {
    Map<String, String>? headers,
  }) async {
    try {
      final url = _buildUrl(endpoint);
      final response = await _client
          .patch(
            Uri.parse(url),
            headers: _buildHeaders(additionalHeaders: headers),
            body: json.encode(data),
          )
          .timeout(AppConstants.networkTimeout);

      return _handleResponse(response, 'PATCH', url);
    } catch (e) {
      _handleNetworkError(e, 'PATCH', endpoint);
    }
  }

  /// Perform DELETE request
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    Map<String, String>? headers,
  }) async {
    try {
      final url = _buildUrl(endpoint);
      final response = await _client
          .delete(
            Uri.parse(url),
            headers: _buildHeaders(additionalHeaders: headers),
          )
          .timeout(AppConstants.networkTimeout);

      return _handleResponse(response, 'DELETE', url);
    } catch (e) {
      _handleNetworkError(e, 'DELETE', endpoint);
    }
  }

  /// Rider-specific API methods

  /// Send OTP for rider authentication
  Future<Map<String, dynamic>> sendRiderOTP(String phoneNumber) async {
    return await post('/rider/auth/send-otp', {
      'phone_number': phoneNumber,
    });
  }

  /// Verify OTP for rider authentication
  Future<Map<String, dynamic>> verifyRiderOTP(String phoneNumber, String otp) async {
    return await post('/rider/auth/verify-otp', {
      'phone_number': phoneNumber,
      'otp': otp,
    });
  }

  /// Update rider location
  Future<Map<String, dynamic>> updateLocation(Map<String, dynamic> locationData) async {
    return await post('/rider/location-update', locationData);
  }

  /// Get rider profile
  Future<Map<String, dynamic>> getRiderProfile() async {
    return await get('/rider/profile');
  }

  /// Update rider profile
  Future<Map<String, dynamic>> updateRiderProfile(Map<String, dynamic> profileData) async {
    return await put('/rider/profile', profileData);
  }

  /// Go online
  Future<Map<String, dynamic>> goOnline() async {
    return await post('/rider/go-online', {});
  }

  /// Go offline
  Future<Map<String, dynamic>> goOffline() async {
    return await post('/rider/go-offline', {});
  }

  /// Accept ride request
  Future<Map<String, dynamic>> acceptRide(String rideId) async {
    return await post('/rider/rides/$rideId/accept', {});
  }

  /// Start ride (pickup user)
  Future<Map<String, dynamic>> startRide(String rideId) async {
    return await post('/rider/rides/$rideId/start', {});
  }

  /// Complete ride
  Future<Map<String, dynamic>> completeRide(String rideId, Map<String, dynamic> completionData) async {
    return await post('/rider/rides/$rideId/complete', completionData);
  }

  /// Cancel ride
  Future<Map<String, dynamic>> cancelRide(String rideId, String reason) async {
    return await post('/rider/rides/$rideId/cancel', {
      'reason': reason,
    });
  }

  /// Get active ride
  Future<Map<String, dynamic>> getActiveRide() async {
    return await get('/rider/rides/active');
  }

  /// Get ride history
  Future<Map<String, dynamic>> getRideHistory({
    int page = 1,
    int limit = 20,
  }) async {
    return await get('/rider/ride-history', queryParams: {
      'page': page.toString(),
      'limit': limit.toString(),
    });
  }

  /// Get earnings summary
  Future<Map<String, dynamic>> getEarnings({
    String? period = 'week', // week, month, year
  }) async {
    return await get('/rider/earnings', queryParams: {
      if (period != null) 'period': period,
    });
  }

  /// Upload KYC documents
  Future<Map<String, dynamic>> uploadKYCDocument({
    required String documentType,
    required String filePath,
  }) async {
    // Note: This would need multipart/form-data handling for file upload
    // Implementation would depend on the specific file upload approach
    throw UnimplementedError('File upload not implemented yet');
  }

  /// Get KYC status
  Future<Map<String, dynamic>> getKYCStatus() async {
    return await get('/rider/kyc-status');
  }

  /// Clear authentication data
  void clearAuth() {
    _authToken = null;
    AppLogger.info('Authentication cleared');
  }

  /// Dispose of resources
  void dispose() {
    _client.close();
    _instance = null;
    AppLogger.info('ApiService disposed');
  }
}

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final Map<String, dynamic>? data;

  const ApiException({
    required this.message,
    required this.statusCode,
    this.data,
  });

  @override
  String toString() {
    return 'ApiException: $message (Status: $statusCode)';
  }

  /// Check if error is due to authentication failure
  bool get isAuthError => statusCode == 401 || statusCode == 403;

  /// Check if error is due to network connectivity
  bool get isNetworkError => statusCode == 0;

  /// Check if error is server-side
  bool get isServerError => statusCode >= 500;

  /// Check if error is client-side
  bool get isClientError => statusCode >= 400 && statusCode < 500;
}