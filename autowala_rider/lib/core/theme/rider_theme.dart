import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Simple and clean color palette for rider app
/// Focused on clarity and ease of use while driving
class RiderColors {
  // Core colors - simplified for driver use
  static const Color primaryWhite = Color(0xFFFFFFFF);
  static const Color primaryBlack = Color(0xFF1A1A1A);
  static const Color primaryGreen = Color(0xFF22C55E);
  static const Color surfaceGray = Color(0xFFF8F9FA);

  // Status colors
  static const Color onlineGreen = Color(0xFF059669);
  static const Color offlineGray = Color(0xFF6B7280);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color errorRed = Color(0xFFDC2626);

  // Text colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textMuted = Color(0xFF9CA3AF);

  // Border and surface colors
  static const Color border = Color(0xFFE5E7EB);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color divider = Color(0xFFF3F4F6);
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

/// Rider app theme configuration
class RiderTheme {
  static ThemeData get light {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: RiderColors.primaryGreen,
        brightness: Brightness.light,
        surface: RiderColors.primaryWhite,
        primary: RiderColors.primaryGreen,
        onPrimary: RiderColors.primaryWhite,
        secondary: RiderColors.primaryBlack,
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
      scaffoldBackgroundColor: RiderColors.primaryWhite,
      appBarTheme: AppBarTheme(
        backgroundColor: RiderColors.primaryWhite,
        foregroundColor: RiderColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: RiderTextStyles.h3,
        iconTheme: const IconThemeData(
          color: RiderColors.textPrimary,
          size: 24,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: RiderColors.primaryGreen,
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
        fillColor: RiderColors.surfaceGray,
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
            color: RiderColors.primaryGreen,
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
