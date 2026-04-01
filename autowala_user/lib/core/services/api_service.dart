import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ApiService {
  late Dio _dio;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Configure base URL - will be set from environment or Railway deployment URL
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://autowala-backend-production.up.railway.app/api',
  );

  ApiService() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Add JWT token if available
          final token = await _storage.read(key: 'jwt_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            // Token expired, attempt refresh
            await _refreshToken();
            handler.next(e);
          } else {
            handler.next(e);
          }
        },
      ),
    );
  }

  // Generic API methods
  Future<Map<String, dynamic>> get(String path,
      {Map<String, dynamic>? queryParams, Map<String, String>? headers}) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: queryParams,
        options: headers != null ? Options(headers: headers) : null,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> post(String path, dynamic data,
      {Map<String, String>? headers}) async {
    try {
      final response = await _dio.post(
        path,
        data: data,
        options: headers != null ? Options(headers: headers) : null,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> put(String path, dynamic data,
      {Map<String, String>? headers}) async {
    try {
      final response = await _dio.put(
        path,
        data: data,
        options: headers != null ? Options(headers: headers) : null,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> delete(String path,
      {Map<String, String>? headers}) async {
    try {
      final response = await _dio.delete(
        path,
        options: headers != null ? Options(headers: headers) : null,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> sendOTP(String phoneNumber) async {
    try {
      final response = await _dio.post('/auth/send-otp', data: {
        'phone': phoneNumber,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> verifyOTP(String phoneNumber, String otp) async {
    try {
      final response = await _dio.post('/auth/verify-otp', data: {
        'phone': phoneNumber,
        'otp': otp,
      });

      // Store token if successful
      if (response.data['status'] == 'success') {
        final token = response.data['data']['token'];
        await _storage.write(key: 'jwt_token', value: token);
      }

      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _refreshToken() async {
    try {
      final refreshToken = await _storage.read(key: 'refresh_token');
      if (refreshToken != null) {
        final response = await _dio.post('/auth/refresh', data: {
          'refresh_token': refreshToken,
        });

        final newToken = response.data['data']['token'];
        await _storage.write(key: 'jwt_token', value: newToken);
      }
    } catch (e) {
      // Clear tokens on refresh failure
      await _storage.delete(key: 'jwt_token');
      await _storage.delete(key: 'refresh_token');
    }
  }

  // Ride endpoints
  Future<Map<String, dynamic>> searchNearbyRiders({
    required double latitude,
    required double longitude,
    required String pickupAddress,
    required String destinationAddress,
    required double destinationLatitude,
    required double destinationLongitude,
    int? radius,
  }) async {
    try {
      final response = await _dio.post('/rides/search-nearby', data: {
        'latitude': latitude,
        'longitude': longitude,
        'pickup_address': pickupAddress,
        'destination_address': destinationAddress,
        'destination_latitude': destinationLatitude,
        'destination_longitude': destinationLongitude,
        'radius': radius,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getRiderDetails(String riderId) async {
    try {
      final response = await _dio.get('/rides/rider/$riderId/details');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> bookRide({
    required String riderId,
    required double pickupLatitude,
    required double pickupLongitude,
    required String pickupAddress,
    required double destinationLatitude,
    required double destinationLongitude,
    required String destinationAddress,
    int passengerCount = 1,
  }) async {
    try {
      final response = await _dio.post('/rides/book', data: {
        'rider_id': riderId,
        'pickup_latitude': pickupLatitude,
        'pickup_longitude': pickupLongitude,
        'pickup_address': pickupAddress,
        'destination_latitude': destinationLatitude,
        'destination_longitude': destinationLongitude,
        'destination_address': destinationAddress,
        'passenger_count': passengerCount,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> trackRide(String rideId) async {
    try {
      final response = await _dio.get('/rides/$rideId/track');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> rateRide(
    String rideId, {
    required int rating,
    String? feedback,
    List<String>? categories,
  }) async {
    try {
      final response = await _dio.post('/rides/$rideId/rating', data: {
        'rating': rating,
        'feedback': feedback,
        'categories': categories,
      });
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  // User profile endpoints
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _dio.get('/user/profile');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getRideHistory() async {
    try {
      final response = await _dio.get('/user/ride-history');
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (e) {
      // Continue with logout even if API call fails
    } finally {
      // Clear stored tokens
      await _storage.delete(key: 'jwt_token');
      await _storage.delete(key: 'refresh_token');
    }
  }
}

// Riverpod provider
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});
