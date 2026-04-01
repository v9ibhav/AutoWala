import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// AutoWala Rider Design System - Yellow/Gold Theme
/// Auto-rickshaw inspired colors optimized for driver use
class RiderColors {
  // Primary Colors - Yellow/Gold Auto-rickshaw Theme
  static const Color primaryYellow = Color(0xFFF59E0B);  // Main amber/yellow
  static const Color primaryGold = Color(0xFFD97706);    // Darker gold
  static const Color primaryDark = Color(0xFF92400E);    // Brown accent
  static const Color primaryWhite = Color(0xFFFFFFFF);
  static const Color primaryBlack = Color(0xFF1C1917);   // Warm black

  // Yellow/Gold Palette
  static const Color amber50 = Color(0xFFFFFBEB);
  static const Color amber100 = Color(0xFFFEF3C7);
  static const Color amber200 = Color(0xFFFDE68A);
  static const Color amber300 = Color(0xFFFCD34D);
  static const Color amber400 = Color(0xFFFBBF24);
  static const Color amber500 = Color(0xFFF59E0B);  // Primary
  static const Color amber600 = Color(0xFFD97706);
  static const Color amber700 = Color(0xFFB45309);
  static const Color amber800 = Color(0xFF92400E);
  static const Color amber900 = Color(0xFF78350F);

  // Simplified surface colors for driver use
  static const Color surfaceGray = Color(0xFFFFFBEB);  // Warm cream background

  // Status colors
  static const Color onlineGreen = Color(0xFF16A34A);
  static const Color offlineGray = Color(0xFF6B7280);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFDC2626);
  static const Color success = onlineGreen;

  // Text colors
  static const Color textPrimary = Color(0xFF1C1917);
  static const Color textSecondary = Color(0xFF78350F);
  static const Color textMuted = Color(0xFF92400E);

  // Border and surface colors
  static const Color border = Color(0xFFFDE68A);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFFEF3C7);

  // Legacy aliases
  static const Color primaryGreen = onlineGreen;
}

/// Typography for rider app - optimized for readability
class RiderTextStyles {
  static TextStyle get _baseTextStyle =>
      GoogleFonts.inter(color: RiderColors.textPrimary);

  // Headings
  static TextStyle get h1 => _baseTextStyle.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static TextStyle get h2 => _baseTextStyle.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    height: 1.2,
  );

  static TextStyle get h3 => _baseTextStyle.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static TextStyle get h4 => _baseTextStyle.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  // Body text - larger for outdoor readability
  static TextStyle get bodyLarge => _baseTextStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle get bodyMedium => _baseTextStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle get bodySmall => _baseTextStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  // Labels and buttons
  static TextStyle get labelLarge => _baseTextStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  static TextStyle get labelMedium => _baseTextStyle.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  static TextStyle get labelSmall => _baseTextStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.3,
  );

  // Special text styles
  static TextStyle get buttonText => _baseTextStyle.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.2,
  );

  static TextStyle get caption => _baseTextStyle.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: RiderColors.textMuted,
    height: 1.3,
  );
}

/// Simple shadows for clean interface
class RiderShadows {
  static const List<BoxShadow> soft = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  static const List<BoxShadow> medium = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 16, offset: Offset(0, 4)),
  ];

  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x08000000), blurRadius: 10, offset: Offset(0, 3)),
  ];
}

/// Rider app theme configuration - Yellow/Gold
class RiderTheme {
  static ThemeData get light {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: RiderColors.primaryYellow,
        brightness: Brightness.light,
        surface: RiderColors.primaryWhite,
        primary: RiderColors.primaryYellow,
        onPrimary: RiderColors.primaryWhite,
        secondary: RiderColors.primaryGold,
        onSecondary: RiderColors.primaryWhite,
      ),
      textTheme: TextTheme(
        displayLarge: RiderTextStyles.h1,
        displayMedium: RiderTextStyles.h2,
        displaySmall: RiderTextStyles.h3,
        headlineLarge: RiderTextStyles.h3,
        headlineMedium: RiderTextStyles.h4,
        bodyLarge: RiderTextStyles.bodyLarge,
        bodyMedium: RiderTextStyles.bodyMedium,
        bodySmall: RiderTextStyles.bodySmall,
        labelLarge: RiderTextStyles.labelLarge,
        labelMedium: RiderTextStyles.labelMedium,
        labelSmall: RiderTextStyles.labelSmall,
      ),
      scaffoldBackgroundColor: RiderColors.amber50,
      appBarTheme: AppBarTheme(
        backgroundColor: RiderColors.primaryYellow,
        foregroundColor: RiderColors.primaryWhite,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: RiderTextStyles.h3.copyWith(color: RiderColors.primaryWhite),
        iconTheme: const IconThemeData(
          color: RiderColors.primaryWhite,
          size: 24,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: RiderColors.primaryYellow,
          foregroundColor: RiderColors.primaryWhite,
          textStyle: RiderTextStyles.buttonText,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          minimumSize: const Size(double.infinity, 56),
        ),
      ),
      cardTheme: CardTheme(
        color: RiderColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: RiderColors.border, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: RiderColors.amber50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: RiderColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: RiderColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: RiderColors.primaryYellow,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: RiderColors.errorRed),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: RiderTextStyles.bodyMedium.copyWith(
          color: RiderColors.textMuted,
        ),
        labelStyle: RiderTextStyles.labelMedium.copyWith(
          color: RiderColors.textSecondary,
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: RiderColors.primaryYellow,
        foregroundColor: RiderColors.primaryWhite,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: RiderColors.primaryYellow,
      ),
      useMaterial3: true,
    );
  }
}

/// Spacing and sizing constants
class RiderSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Component sizes
  static const double buttonHeight = 56.0;
  static const double inputHeight = 48.0;
  static const double cardPadding = 20.0;
  static const double screenPadding = 24.0;
}

/// Border radius constants
class RiderRadius {
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double lg = 16.0;
  static const double xl = 20.0;
  static const double xxl = 24.0;
  static const double full = 999.0;
}
