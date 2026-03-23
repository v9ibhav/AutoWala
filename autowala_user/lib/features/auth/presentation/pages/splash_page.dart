import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/app_constants.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/navigation/app_router.dart';

/// Premium splash screen with smooth animations
/// Sets the tone for the entire app experience
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _startInitialization();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
  }

  Future<void> _startInitialization() async {
    final performanceLogger = PerformanceLogger('splash_initialization');

    try {
      // Start animations
      _animationController.forward();

      // Minimum splash duration for smooth UX
      final minDuration = Future.delayed(const Duration(milliseconds: 2500));

      // Check app state and determine next route
      final nextRoute = await _determineNextRoute();

      // Wait for minimum duration to complete
      await minDuration;

      performanceLogger.stop('completed');

      if (mounted) {
        _navigateToNext(nextRoute);
      }
    } catch (error, stackTrace) {
      performanceLogger.stop('failed');
      AppLogger.error('Splash initialization failed', error, stackTrace);

      if (mounted) {
        _navigateToNext(AppRoutes.login);
      }
    }
  }

  Future<String> _determineNextRoute() async {
    try {
      final settingsBox = Hive.box('app_settings');

      // Check if user has completed onboarding
      final hasCompletedOnboarding =
          settingsBox.get('onboarding_complete', defaultValue: false);
      if (!hasCompletedOnboarding) {
        AppLogger.info('User needs onboarding');
        return AppRoutes.onboarding;
      }

      // Check if user has an active session
      final hasActiveSession =
          settingsBox.get('has_active_session', defaultValue: false);
      if (hasActiveSession) {
        // TODO: Validate token with backend
        AppLogger.info('Active session found, going to home');
        return AppRoutes.home;
      }

      // Default to login
      AppLogger.info('No active session, going to login');
      return AppRoutes.login;
    } catch (e) {
      AppLogger.error('Failed to determine next route', e);
      return AppRoutes.login;
    }
  }

  void _navigateToNext(String route) {
    // Use haptic feedback for premium feel
    HapticFeedback.lightImpact();

    context.go(route);

    AppLogger.navigation(
      'splash_navigation',
      'splash -> $route',
      data: {'destination': route},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryWhite,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primaryWhite,
              AppColors.gray50,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Spacer to center content
              const Spacer(flex: 2),

              // Logo and Brand Section
              _buildLogoSection(),

              const Spacer(flex: 3),

              // Loading indicator and powered by section
              _buildBottomSection(),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Main Logo
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            color: AppColors.primaryBlack,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppShadows.medium,
          ),
          child: const Icon(
            Icons.directions_car,
            size: 64,
            color: AppColors.primaryWhite,
          ),
        )
            .animate(controller: _animationController)
            .scale(
              duration: 800.ms,
              curve: Curves.elasticOut,
              begin: const Offset(0.8, 0.8),
              end: const Offset(1.0, 1.0),
            )
            .fadeIn(duration: 600.ms),

        const SizedBox(height: 32),

        // App Name
        Text(
          AppConstants.appName,
          style: AppTextStyles.h1.copyWith(
            fontSize: 36,
            letterSpacing: -1,
            fontWeight: FontWeight.w800,
          ),
        )
            .animate(controller: _animationController)
            .fadeIn(delay: 400.ms, duration: 600.ms)
            .slideY(
              begin: 0.3,
              end: 0.0,
              duration: 800.ms,
              curve: Curves.easeOutCubic,
            ),

        const SizedBox(height: 8),

        // Tagline
        Text(
          'Premium Ride Discovery',
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.gray600,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        )
            .animate(controller: _animationController)
            .fadeIn(delay: 600.ms, duration: 600.ms)
            .slideY(
              begin: 0.3,
              end: 0.0,
              duration: 800.ms,
              curve: Curves.easeOutCubic,
            ),

        const SizedBox(height: 16),

        // Subtitle
        Text(
          'Connect with Auto-Rickshaws instantly',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.gray500,
          ),
        )
            .animate(controller: _animationController)
            .fadeIn(delay: 800.ms, duration: 600.ms),
      ],
    );
  }

  Widget _buildBottomSection() {
    return Column(
      children: [
        // Loading indicator
        _buildLoadingIndicator(),

        const SizedBox(height: 32),

        // Powered by section
        _buildPoweredBySection(),
      ],
    );
  }

  Widget _buildLoadingIndicator() {
    return Column(
      children: [
        // Custom loading animation
        SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            children: [
              // Background circle
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.gray200,
                    width: 3,
                  ),
                ),
              ),

              // Animated progress circle
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.accentGreen,
                  ),
                  backgroundColor: Colors.transparent,
                ),
              ),
            ],
          ),
        )
            .animate(controller: _animationController)
            .fadeIn(delay: 1000.ms, duration: 400.ms)
            .scale(delay: 1000.ms, duration: 400.ms),

        const SizedBox(height: 16),

        // Loading text
        Text(
          'Setting up your experience...',
          style: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.gray500,
          ),
        )
            .animate(controller: _animationController)
            .fadeIn(delay: 1200.ms, duration: 400.ms),
      ],
    );
  }

  Widget _buildPoweredBySection() {
    return Column(
      children: [
        Text(
          'Made with ❤️ in India',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.gray400,
            fontSize: 11,
          ),
        )
            .animate(controller: _animationController)
            .fadeIn(delay: 1400.ms, duration: 400.ms),

        const SizedBox(height: 8),

        // Version info (only in debug mode)
        if (AppConstants.isDebugMode) ...[
          Text(
            'v${AppConstants.version}',
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.gray300,
              fontSize: 10,
            ),
          )
              .animate(controller: _animationController)
              .fadeIn(delay: 1500.ms, duration: 400.ms),
        ],
      ],
    );
  }
}

/// Custom loading widget for reuse throughout the app
class AutoWalaLoadingWidget extends StatelessWidget {
  final String? text;
  final double size;
  final Color? color;

  const AutoWalaLoadingWidget({
    super.key,
    this.text,
    this.size = 40,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: size * 0.075, // Proportional stroke width
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? AppColors.accentGreen,
            ),
            backgroundColor: AppColors.gray200,
          ),
        ),
        if (text != null) ...[
          SizedBox(height: size * 0.4),
          Text(
            text!,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.gray500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

/// Simple loading overlay for use in other screens
class LoadingOverlay extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final String? loadingText;

  const LoadingOverlay({
    super.key,
    required this.child,
    required this.isLoading,
    this.loadingText,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: AppColors.primaryWhite.withOpacity(0.8),
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primaryWhite,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: AppShadows.medium,
                ),
                child: AutoWalaLoadingWidget(
                  text: loadingText ?? 'Loading...',
                ),
              ),
            ),
          ),
      ],
    );
  }
}
