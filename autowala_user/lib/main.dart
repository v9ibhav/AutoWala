import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/navigation/app_router.dart';
import 'core/services/app_initialization_service.dart';
import 'core/utils/app_constants.dart';
import 'core/utils/logger.dart';

void main() async {
  // Ensure Flutter bindings are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging
  AppLogger.init();

  try {
    // Set system UI overlay style for premium look
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: AppColors.primaryWhite,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    // Set preferred orientations (portrait only for optimal UX)
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    // Initialize core services
    await _initializeApp();

    // Run the app
    runApp(
      const ProviderScope(
        child: AutoWalaApp(),
      ),
    );
  } catch (error, stackTrace) {
    AppLogger.error('Failed to initialize app', error, stackTrace);

    // Run error app if main initialization fails
    runApp(
      MaterialApp(
        title: 'AutoWala Error',
        home: AppErrorWidget(error: error.toString()),
      ),
    );
  }
}

/// Initialize all core app services
Future<void> _initializeApp() async {
  // Initialize Hive for local storage
  await Hive.initFlutter();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Initialize other services
  await AppInitializationService.initialize();

  AppLogger.info('App initialization completed successfully');
}

class AutoWalaApp extends ConsumerWidget {
  const AutoWalaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      // App Configuration
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,

      // Theme
      theme: AppTheme.lightTheme,
      themeMode: ThemeMode.light,

      // Navigation
      routerConfig: router,

      // Localization
      supportedLocales: AppConstants.supportedLocales,
      locale: AppConstants.defaultLocale,

      // Builder for global overlays and error handling
      builder: (context, child) {
        return MediaQuery(
          // Scale text size for better readability on low-end devices
          data: MediaQuery.of(context).copyWith(
            textScaleFactor:
                MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.2),
          ),
          child: child ?? const SizedBox(),
        );
      },
    );
  }
}

/// Error widget displayed when app fails to initialize
class AppErrorWidget extends StatelessWidget {
  final String error;

  const AppErrorWidget({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Material(
      child: Container(
        color: AppColors.primaryWhite,
        padding: const EdgeInsets.all(24),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 40,
                  color: AppColors.error,
                ),
              ),

              const SizedBox(height: 24),

              // Error Title
              Text(
                'AutoWala Startup Error',
                style: AppTextStyles.h3.copyWith(
                  color: AppColors.primaryBlack,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Error Message
              Text(
                'We encountered an issue starting the app. Please restart and try again.',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.gray600,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Retry Button
              ElevatedButton(
                onPressed: () {
                  // Close app and let user restart
                  SystemNavigator.pop();
                },
                child: const Text('Restart App'),
              ),

              const SizedBox(height: 16),

              // Error Details (Debug mode only)
              if (AppConstants.isDebugMode) ...[
                ExpansionTile(
                  title: const Text('Error Details'),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        error,
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
