import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../core/utils/logger.dart';

/// Authentication state model
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;
  final String? accessToken;
  final String? refreshToken;
  final Map<String, dynamic>? user;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
    this.accessToken,
    this.refreshToken,
    this.user,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
    String? accessToken,
    String? refreshToken,
    Map<String, dynamic>? user,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      user: user ?? this.user,
    );
  }
}

/// Authentication notifier
class AuthNotifier extends StateNotifier<AuthState> {
  final ApiService _apiService;
  final StorageService _storageService;

  AuthNotifier(this._apiService, this._storageService)
      : super(const AuthState()) {
    _initializeAuth();
  }

  /// Initialize authentication state from storage
  Future<void> _initializeAuth() async {
    try {
      state = state.copyWith(isLoading: true);

      final accessToken = await _storageService.getAccessToken();
      final refreshToken = await _storageService.getRefreshToken();
      final userData = await _storageService.getUserData();

      if (accessToken != null && refreshToken != null) {
        // Validate token with API
        final isValid = await _validateToken(accessToken);

        if (isValid) {
          state = state.copyWith(
            isAuthenticated: true,
            isLoading: false,
            accessToken: accessToken,
            refreshToken: refreshToken,
            user: userData,
          );

          AppLogger.info('User authenticated from storage');
        } else {
          // Try to refresh token
          final refreshed = await _refreshAccessToken(refreshToken);
          if (!refreshed) {
            await _clearAuthData();
          }
        }
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      AppLogger.error('Failed to initialize auth', e.toString());
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to initialize authentication',
      );
    }
  }

  /// Send OTP to phone number
  Future<void> sendOTP(String phoneNumber) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _apiService.post('/auth/send-otp', {
        'phone_number': phoneNumber,
      });

      if (response['success'] == true) {
        state = state.copyWith(isLoading: false);

        AppLogger.userAction('otp_sent_successfully', parameters: {
          'phone_number': phoneNumber,
          'session_id': response['data']?['session_id'],
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      AppLogger.error('Failed to send OTP', e, null, {'phone_number': phoneNumber});

      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
      rethrow;
    }
  }

  /// Verify OTP and authenticate user
  Future<void> verifyOTP(String phoneNumber, String otp) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final response = await _apiService.post('/auth/verify-otp', {
        'phone_number': phoneNumber,
        'otp': otp,
      });

      if (response['success'] == true) {
        final data = response['data'];
        final accessToken = data['access_token'];
        final refreshToken = data['refresh_token'];
        final user = data['user'];

        // Store tokens and user data
        await _storageService.setAccessToken(accessToken);
        await _storageService.setRefreshToken(refreshToken);
        await _storageService.setUserData(user);

        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
          accessToken: accessToken,
          refreshToken: refreshToken,
          user: user,
        );

        AppLogger.userAction('user_authenticated_successfully', parameters: {
          'phone_number': phoneNumber,
          'user_id': user['id'],
          'is_new_user': data['is_new_user'] ?? false,
        });
      } else {
        throw Exception(response['message'] ?? 'Invalid OTP');
      }
    } catch (e) {
      AppLogger.error('Failed to verify OTP', e, null, {
        'phone_number': phoneNumber,
        'otp_length': otp.length,
      });

      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
      rethrow;
    }
  }

  /// Refresh access token
  Future<bool> _refreshAccessToken(String refreshToken) async {
    try {
      final response = await _apiService.post('/auth/refresh-token', {
        'refresh_token': refreshToken,
      });

      if (response['success'] == true) {
        final data = response['data'];
        final newAccessToken = data['access_token'];
        final newRefreshToken = data['refresh_token'];

        await _storageService.setAccessToken(newAccessToken);
        await _storageService.setRefreshToken(newRefreshToken);

        state = state.copyWith(
          accessToken: newAccessToken,
          refreshToken: newRefreshToken,
          isAuthenticated: true,
        );

        AppLogger.info('Access token refreshed successfully');
        return true;
      }
    } catch (e) {
      AppLogger.error('Failed to refresh token', e.toString());
    }

    return false;
  }

  /// Validate access token
  Future<bool> _validateToken(String accessToken) async {
    try {
      final response = await _apiService.get('/auth/validate-token', headers: {
        'Authorization': 'Bearer $accessToken',
      });

      return response['success'] == true;
    } catch (e) {
      AppLogger.debug('Token validation failed', {'error': e.toString()});
      return false;
    }
  }

  /// Clear authentication data
  Future<void> _clearAuthData() async {
    await _storageService.clearAuthData();

    state = const AuthState(
      isAuthenticated: false,
      isLoading: false,
    );

    AppLogger.info('Authentication data cleared');
  }

  /// Logout user
  Future<void> logout() async {
    try {
      state = state.copyWith(isLoading: true);

      // Call logout API to invalidate tokens
      if (state.accessToken != null) {
        try {
          await _apiService.post('/auth/logout', {}, headers: {
            'Authorization': 'Bearer ${state.accessToken}',
          });
        } catch (e) {
          // Logout API call failed, but we'll still clear local data
          AppLogger.warning('Logout API call failed', e.toString());
        }
      }

      await _clearAuthData();

      AppLogger.userAction('user_logged_out');
    } catch (e) {
      AppLogger.error('Failed to logout', e.toString());

      // Still clear local data even if logout failed
      await _clearAuthData();
    }
  }

  /// Update user profile
  Future<void> updateProfile(Map<String, dynamic> updates) async {
    try {
      state = state.copyWith(isLoading: true, null);

      final response =
          await _apiService.put('/user/profile', updates, headers: {
        'Authorization': 'Bearer ${state.accessToken}',
      });

      if (response['success'] == true) {
        final updatedUser = response['data']['user'];
        await _storageService.setUserData(updatedUser);

        state = state.copyWith(
          user: updatedUser,
          isLoading: false,
        );

        AppLogger.userAction('profile_updated', parameters: {
          'user_id': updatedUser['id'],
          'updated_fields': updates.keys.toList(),
        });
      } else {
        throw Exception(response['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      AppLogger.error('Failed to update profile', e.toString());

      state = state.copyWith(
        isLoading: false,
        error: _getErrorMessage(e),
      );
      rethrow;
    }
  }

  /// Get user-friendly error message
  String _getErrorMessage(dynamic error) {
    final errorStr = error.toString();

    if (errorStr.contains('network') || errorStr.contains('connection')) {
      return 'Please check your internet connection';
    } else if (errorStr.contains('invalid') || errorStr.contains('expired')) {
      return 'Invalid or expired code. Please try again';
    } else if (errorStr.contains('rate limit') ||
        errorStr.contains('too many')) {
      return 'Too many attempts. Please try again later';
    } else if (errorStr.contains('timeout')) {
      return 'Request timed out. Please try again';
    } else {
      return 'Something went wrong. Please try again';
    }
  }
}

/// Authentication provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final apiService = ref.read(apiServiceProvider);
  final storageService = ref.read(storageServiceProvider);

  return AuthNotifier(apiService, storageService);
});

/// Convenience providers
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final currentUserProvider = Provider<Map<String, dynamic>?>((ref) {
  return ref.watch(authProvider).user;
});

final authLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});

final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).error;
});
