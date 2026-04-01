import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Premium AutoWala Design System
/// Yellow/Gold primary (Auto-rickshaw inspired), White surface, Black text
class AppColors {
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

  // Grayscale Palette
  static const Color gray50 = Color(0xFFFAFAFA);
  static const Color gray100 = Color(0xFFF5F5F5);
  static const Color gray200 = Color(0xFFEEEEEE);
  static const Color gray300 = Color(0xFFE0E0E0);
  static const Color gray400 = Color(0xFFBDBDBD);
  static const Color gray500 = Color(0xFF9E9E9E);
  static const Color gray600 = Color(0xFF757575);
  static const Color gray700 = Color(0xFF616161);
  static const Color gray800 = Color(0xFF424242);
  static const Color gray900 = Color(0xFF212121);

  // Status Colors (High Visibility)
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);  // Same as primary
  static const Color error = Color(0xFFDC2626);
  static const Color errorRed = error;
  static const Color info = Color(0xFF2563EB);

  // Semantic Colors
  static const Color online = Color(0xFF16A34A);
  static const Color offline = Color(0xFF9E9E9E);
  static const Color rideActive = Color(0xFFF59E0B);  // Yellow for active
  static const Color rideCompleted = Color(0xFF16A34A);
  static const Color rideCancelled = Color(0xFFDC2626);

  // Surface Colors
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFFEF3C7);  // Light amber
  static const Color background = Color(0xFFFFFBEB);      // Cream background
  static const Color backgroundVariant = Color(0xFFFEF3C7);

  // Card Colors
  static const Color cardWhite = Color(0xFFFFFFFF);
  static const Color cardElevated = Color(0xFFFFFFFF);

  // Legacy color names for backward compatibility
  static const Color accentGreen = success;

  // Shadow Colors
  static const Color shadowLight = Color(0x1AF59E0B);
  static const Color shadowMedium = Color(0x33F59E0B);
  static const Color shadowStrong = Color(0x4DF59E0B);
}

class AppTextStyles {
  static TextStyle get baseTextStyle => GoogleFonts.inter();

  // Headlines (Bold, High Contrast)
  static TextStyle get h1 => baseTextStyle.copyWith(
        fontSize: 32,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: AppColors.primaryBlack,
      );

  static TextStyle get h2 => baseTextStyle.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.25,
        color: AppColors.primaryBlack,
      );

  static TextStyle get h3 => baseTextStyle.copyWith(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: AppColors.primaryBlack,
      );

  static TextStyle get h4 => baseTextStyle.copyWith(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        color: AppColors.primaryBlack,
      );

  // Body Text (Optimized for Reading)
  static TextStyle get bodyLarge => baseTextStyle.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.15,
        color: AppColors.primaryBlack,
      );

  static TextStyle get bodyMedium => baseTextStyle.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.25,
        color: AppColors.primaryBlack,
      );

  static TextStyle get bodySmall => baseTextStyle.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: AppColors.gray700,
      );

  // Labels & Buttons
  static TextStyle get labelLarge => baseTextStyle.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.1,
        color: AppColors.primaryBlack,
      );

  static TextStyle get labelMedium => baseTextStyle.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: AppColors.primaryBlack,
      );

  static TextStyle get labelSmall => baseTextStyle.copyWith(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
        color: AppColors.gray600,
      );

  // Special Styles
  static TextStyle get buttonText => baseTextStyle.copyWith(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.1,
        color: AppColors.primaryWhite,
      );

  static TextStyle get caption => baseTextStyle.copyWith(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.4,
        color: AppColors.gray600,
      );

  static TextStyle get overline => baseTextStyle.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w400,
        letterSpacing: 1.5,
        color: AppColors.gray600,
      );
}

class AppTheme {
  /// Premium Light Theme for AutoWala - Yellow/Gold
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color Scheme - Yellow/Gold Theme
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryYellow,
        onPrimary: AppColors.primaryWhite,
        secondary: AppColors.primaryGold,
        onSecondary: AppColors.primaryWhite,
        tertiary: AppColors.success,
        surface: AppColors.surface,
        onSurface: AppColors.primaryBlack,
        background: AppColors.background,
        onBackground: AppColors.primaryBlack,
        error: AppColors.error,
        onError: AppColors.primaryWhite,
      ),

      // Typography
      textTheme: TextTheme(
        displayLarge: AppTextStyles.h1,
        displayMedium: AppTextStyles.h2,
        displaySmall: AppTextStyles.h3,
        headlineMedium: AppTextStyles.h4,
        bodyLarge: AppTextStyles.bodyLarge,
        bodyMedium: AppTextStyles.bodyMedium,
        bodySmall: AppTextStyles.bodySmall,
        labelLarge: AppTextStyles.labelLarge,
        labelMedium: AppTextStyles.labelMedium,
        labelSmall: AppTextStyles.labelSmall,
      ),

      // App Bar Theme - Yellow Header
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.primaryYellow,
        foregroundColor: AppColors.primaryWhite,
        elevation: 0,
        scrolledUnderElevation: 4,
        shadowColor: AppColors.shadowLight,
        surfaceTintColor: AppColors.primaryYellow,
        titleTextStyle: AppTextStyles.h4.copyWith(color: AppColors.primaryWhite),
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.primaryWhite),
      ),

      // Button Themes - Yellow/Gold
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryYellow,
          foregroundColor: AppColors.primaryWhite,
          elevation: 2,
          shadowColor: AppColors.shadowMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: AppTextStyles.buttonText,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryYellow,
          side: const BorderSide(color: AppColors.amber300, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: AppTextStyles.buttonText.copyWith(
            color: AppColors.primaryYellow,
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryBlack,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          textStyle: AppTextStyles.labelLarge,
        ),
      ),

      // Card Theme
      cardTheme: CardTheme(
        color: AppColors.cardWhite,
        elevation: 2,
        shadowColor: AppColors.shadowLight,
        surfaceTintColor: AppColors.primaryWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(8),
      ),

      // Input Decoration Theme - Yellow/Gold accents
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.amber50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.amber300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.amber300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primaryYellow, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.gray500),
        labelStyle:
            AppTextStyles.labelMedium.copyWith(color: AppColors.amber700),
      ),

      // Bottom Sheet Theme
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.primaryWhite,
        surfaceTintColor: AppColors.primaryWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        clipBehavior: Clip.antiAlias,
      ),

      // Dialog Theme
      dialogTheme: DialogTheme(
        backgroundColor: AppColors.primaryWhite,
        surfaceTintColor: AppColors.primaryWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        titleTextStyle: AppTextStyles.h4,
        contentTextStyle: AppTextStyles.bodyMedium,
      ),

      // Floating Action Button Theme - Yellow/Gold
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryYellow,
        foregroundColor: AppColors.primaryWhite,
        elevation: 4,
        shape: CircleBorder(),
      ),

      // Progress Indicator Theme - Yellow/Gold
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.primaryYellow,
        circularTrackColor: AppColors.amber200,
        linearTrackColor: AppColors.amber200,
      ),

      // Navigation Theme - Yellow/Gold
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.primaryWhite,
        surfaceTintColor: AppColors.primaryWhite,
        elevation: 8,
        shadowColor: AppColors.shadowLight,
        indicatorColor: AppColors.amber100,
        labelTextStyle: MaterialStateProperty.all(
          AppTextStyles.labelSmall.copyWith(color: AppColors.primaryBlack),
        ),
        iconTheme: MaterialStateProperty.resolveWith((states) {
          return IconThemeData(
            color: states.contains(MaterialState.selected)
                ? AppColors.primaryYellow
                : AppColors.gray500,
            size: 24,
          );
        }),
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: AppColors.gray200,
        thickness: 1,
        space: 1,
      ),

      // List Tile Theme
      listTileTheme: ListTileThemeData(
        tileColor: AppColors.primaryWhite,
        textColor: AppColors.primaryBlack,
        iconColor: AppColors.gray600,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: AppColors.primaryBlack,
        size: 24,
      ),

      // Scaffold Background
      scaffoldBackgroundColor: AppColors.background,

      // Visual Density (Optimized for touch)
      visualDensity: VisualDensity.adaptivePlatformDensity,
    );
  }
}

/// Theme Extensions for Custom Components
class AppShadows {
  static List<BoxShadow> get light => [
        BoxShadow(
          color: AppColors.shadowLight,
          blurRadius: 6,
          offset: const Offset(0, 1),
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get soft => [
        BoxShadow(
          color: AppColors.shadowLight,
          blurRadius: 8,
          offset: const Offset(0, 2),
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get medium => [
        BoxShadow(
          color: AppColors.shadowMedium,
          blurRadius: 12,
          offset: const Offset(0, 4),
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get strong => [
        BoxShadow(
          color: AppColors.shadowStrong,
          blurRadius: 20,
          offset: const Offset(0, 8),
          spreadRadius: 0,
        ),
      ];

  static List<BoxShadow> get card => [
        BoxShadow(
          color: AppColors.shadowLight,
          blurRadius: 8,
          offset: const Offset(0, 2),
          spreadRadius: 0,
        ),
      ];
}

class AppBorders {
  static BorderRadius get small => BorderRadius.circular(8);
  static BorderRadius get medium => BorderRadius.circular(12);
  static BorderRadius get large => BorderRadius.circular(16);
  static BorderRadius get extraLarge => BorderRadius.circular(24);

  static Border get thin => Border.all(color: AppColors.gray300, width: 1);
  static Border get mediumBorder => Border.all(color: AppColors.gray400, width: 1.5);
}

class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}
