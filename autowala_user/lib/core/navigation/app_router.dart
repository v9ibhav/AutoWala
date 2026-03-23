import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/pages/onboarding_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/otp_verification_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/ride/presentation/pages/ride_booking_page.dart';
import '../../features/ride/presentation/pages/ride_tracking_page.dart';
import '../../features/ride/presentation/pages/ride_completed_page.dart';
import '../../features/profile/presentation/pages/profile_page.dart';
import '../../features/profile/presentation/pages/ride_history_page.dart';
import '../../features/profile/presentation/pages/settings_page.dart';
import '../utils/app_constants.dart';
import '../utils/logger.dart';

/// Navigation routes for the AutoWala app
class AppRoutes {
  // Root routes
  static const String splash = '/';
  static const String onboarding = '/onboarding';

  // Authentication routes
  static const String login = '/auth/login';
  static const String otpVerification = '/auth/otp-verification';

  // Main app routes
  static const String home = '/home';
  static const String rideBooking = '/ride/booking';
  static const String rideTracking = '/ride/tracking';
  static const String rideCompleted = '/ride/completed';

  // Profile routes
  static const String profile = '/profile';
  static const String rideHistory = '/profile/ride-history';
  static const String settings = '/profile/settings';

  // Deep link routes
  static const String rideDeepLink = '/ride';
  static const String shareRide = '/share/ride';
}

/// Navigation provider for dependency injection
final appRouterProvider = Provider<GoRouter>((ref) {
  return AppRouter.createRouter(ref);
});

/// Main router configuration class
class AppRouter {
  /// Create the main GoRouter instance with all routes and navigation logic
  static GoRouter createRouter(Ref ref) {
    return GoRouter(
      debugLogDiagnostics: AppConstants.isDebugMode,
      initialLocation: AppRoutes.splash,

      // Global navigation observers for analytics
      observers: [
        NavigationObserver(),
      ],

      // Error handling
      errorBuilder: (context, state) => AppErrorPage(
        error: state.error.toString(),
        route: state.location,
      ),

      // Route definitions
      routes: [
        // Splash and Onboarding
        GoRoute(
          path: AppRoutes.splash,
          name: 'splash',
          builder: (context, state) => const SplashPage(),
        ),

        GoRoute(
          path: AppRoutes.onboarding,
          name: 'onboarding',
          builder: (context, state) => const OnboardingPage(),
        ),

        // Authentication Flow
        GoRoute(
          path: AppRoutes.login,
          name: 'login',
          builder: (context, state) => const LoginPage(),
          routes: [
            GoRoute(
              path: 'otp-verification',
              name: 'otp-verification',
              builder: (context, state) {
                final phoneNumber = state.extra as String?;
                return OTPVerificationPage(phoneNumber: phoneNumber ?? '');
              },
            ),
          ],
        ),

        // Main App Routes
        GoRoute(
          path: AppRoutes.home,
          name: 'home',
          builder: (context, state) => const HomePage(),
          routes: [
            // Ride Flow
            GoRoute(
              path: 'ride/booking',
              name: 'ride-booking',
              builder: (context, state) {
                final extra = state.extra as Map<String, dynamic>?;
                return RideBookingPage(
                  pickupLocation: extra?['pickup_location'],
                  dropoffLocation: extra?['dropoff_location'],
                );
              },
            ),

            GoRoute(
              path: 'ride/tracking/:rideId',
              name: 'ride-tracking',
              builder: (context, state) {
                final rideId = state.pathParameters['rideId']!;
                return RideTrackingPage(rideId: rideId);
              },
            ),

            GoRoute(
              path: 'ride/completed/:rideId',
              name: 'ride-completed',
              builder: (context, state) {
                final rideId = state.pathParameters['rideId']!;
                return RideCompletedPage(rideId: rideId);
              },
            ),

            // Profile Routes
            GoRoute(
              path: 'profile',
              name: 'profile',
              builder: (context, state) => const ProfilePage(),
              routes: [
                GoRoute(
                  path: 'ride-history',
                  name: 'ride-history',
                  builder: (context, state) => const RideHistoryPage(),
                ),
                GoRoute(
                  path: 'settings',
                  name: 'settings',
                  builder: (context, state) => const SettingsPage(),
                ),
              ],
            ),
          ],
        ),

        // Deep Link Routes
        GoRoute(
          path: '/ride/:rideId',
          name: 'ride-deep-link',
          builder: (context, state) {
            final rideId = state.pathParameters['rideId']!;
            return RideTrackingPage(rideId: rideId);
          },
        ),

        GoRoute(
          path: '/share/ride/:rideId',
          name: 'share-ride',
          builder: (context, state) {
            final rideId = state.pathParameters['rideId']!;
            // TODO: Implement ride sharing page
            return RideTrackingPage(rideId: rideId);
          },
        ),
      ],

      // Redirect logic for authentication and initial routing
      redirect: (context, state) => _handleRedirect(context, state, ref),
    );
  }

  /// Handle navigation redirects based on app state
  static String? _handleRedirect(
      BuildContext context, GoRouterState state, Ref ref) {
    final location = state.location;

    // TODO: Check authentication status from provider
    // final authState = ref.read(authStateProvider);
    // For now, using placeholder logic

    // Skip redirects for auth routes to avoid loops
    if (location.startsWith('/auth') ||
        location == AppRoutes.splash ||
        location == AppRoutes.onboarding) {
      return null;
    }

    // Check if user needs onboarding
    // TODO: Get from app state provider
    bool needsOnboarding = false; // await _checkNeedsOnboarding();
    if (needsOnboarding && location != AppRoutes.onboarding) {
      AppLogger.navigation('redirect_to_onboarding', location);
      return AppRoutes.onboarding;
    }

    // Check authentication for protected routes
    bool isAuthenticated = false; // await _checkAuthentication();
    if (!isAuthenticated && _isProtectedRoute(location)) {
      AppLogger.navigation('redirect_to_login', location);
      return AppRoutes.login;
    }

    // Allow navigation to continue
    return null;
  }

  /// Check if route requires authentication
  static bool _isProtectedRoute(String location) {
    final protectedRoutes = [
      AppRoutes.home,
      AppRoutes.rideBooking,
      AppRoutes.rideTracking,
      AppRoutes.profile,
      AppRoutes.rideHistory,
      AppRoutes.settings,
    ];

    return protectedRoutes.any((route) => location.startsWith(route));
  }
}

/// Custom navigation observer for analytics and logging
class NavigationObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPush(route, previousRoute);
    _logNavigation('push', route, previousRoute);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    super.didPop(route, previousRoute);
    _logNavigation('pop', route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
    _logNavigation('replace', newRoute, oldRoute);
  }

  void _logNavigation(
      String action, Route<dynamic>? route, Route<dynamic>? previousRoute) {
    final routeName = route?.settings.name ?? 'unknown';
    final previousRouteName = previousRoute?.settings.name ?? 'none';

    AppLogger.navigation(
      action,
      '$previousRouteName -> $routeName',
      data: {
        'action': action,
        'from': previousRouteName,
        'to': routeName,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
}

/// Error page for navigation errors
class AppErrorPage extends StatelessWidget {
  final String error;
  final String route;

  const AppErrorPage({
    super.key,
    required this.error,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        title: const Text('Navigation Error'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFFF44336).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 40,
                  color: Color(0xFFF44336),
                ),
              ),

              const SizedBox(height: 24),

              // Error Title
              const Text(
                'Page Not Found',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF000000),
                ),
              ),

              const SizedBox(height: 16),

              // Error Message
              Text(
                'The page you\'re looking for doesn\'t exist or has been moved.',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF757575),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              if (AppConstants.isDebugMode) ...[
                Text(
                  'Route: $route',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9E9E9E),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Error: $error',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF9E9E9E),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 32),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed: () => context.go(AppRoutes.home),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF000000),
                      foregroundColor: const Color(0xFFFFFFFF),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Go Home'),
                  ),
                  const SizedBox(width: 16),
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF000000),
                      side: const BorderSide(color: Color(0xFFE0E0E0)),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Go Back'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Navigation extensions for easy route access
extension AppNavigation on BuildContext {
  /// Navigate to home page
  void goToHome() => go(AppRoutes.home);

  /// Navigate to login page
  void goToLogin() => go(AppRoutes.login);

  /// Navigate to OTP verification
  void goToOTPVerification(String phoneNumber) {
    go('${AppRoutes.login}/otp-verification', extra: phoneNumber);
  }

  /// Navigate to ride booking with location data
  void goToRideBooking({
    Map<String, dynamic>? pickupLocation,
    Map<String, dynamic>? dropoffLocation,
  }) {
    go('${AppRoutes.home}/ride/booking', extra: {
      'pickup_location': pickupLocation,
      'dropoff_location': dropoffLocation,
    });
  }

  /// Navigate to ride tracking
  void goToRideTracking(String rideId) {
    go('${AppRoutes.home}/ride/tracking/$rideId');
  }

  /// Navigate to profile page
  void goToProfile() => go('${AppRoutes.home}/profile');

  /// Navigate to settings
  void goToSettings() => go('${AppRoutes.home}/profile/settings');

  /// Navigate to ride history
  void goToRideHistory() => go('${AppRoutes.home}/profile/ride-history');
}

/// Route information class for navigation state
class RouteInfo {
  final String name;
  final String path;
  final Map<String, dynamic> parameters;
  final dynamic extra;

  const RouteInfo({
    required this.name,
    required this.path,
    this.parameters = const {},
    this.extra,
  });
}

/// Provider for current route information
final currentRouteProvider = Provider<RouteInfo?>((ref) {
  // TODO: Implement with GoRouter state watching
  return null;
});
