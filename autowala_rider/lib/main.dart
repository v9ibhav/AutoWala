import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/rider_theme.dart';
import 'core/utils/rider_constants.dart';
import 'features/auth/presentation/pages/rider_login_page.dart';
import 'features/dashboard/presentation/pages/rider_dashboard_page.dart';

/// AutoWala Rider App - Clean and simple interface for drivers
/// Focused on essential functionality without distractions
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set preferred orientations - portrait only for simplicity
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Set system UI overlay style for outdoor visibility
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: RiderColors.primaryWhite,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ProviderScope(child: AutoWalaRiderApp()));
}

class AutoWalaRiderApp extends ConsumerWidget {
  const AutoWalaRiderApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: RiderConstants.appName,
      theme: RiderTheme.light,
      debugShowCheckedModeBanner: false,
      home: const RiderAuthWrapper(),
      routes: {
        '/login': (context) => const RiderLoginPage(),
        '/dashboard': (context) => const RiderDashboardPage(),
      },
    );
  }
}

/// Simple authentication wrapper
class RiderAuthWrapper extends ConsumerWidget {
  const RiderAuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // TODO: Check authentication status and navigate accordingly
    // For now, start with login page
    return const RiderLoginPage();
  }
}
