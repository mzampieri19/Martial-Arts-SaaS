import 'package:flutter/material.dart';
import 'app_constants.dart';

/// App-wide theme configuration
class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme {
    return ThemeData(
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppConstants.primaryColor,
        brightness: Brightness.light,
        primary: AppConstants.primaryColor,
        secondary: AppConstants.secondaryColor,
        surface: AppConstants.surfaceColor,
        background: AppConstants.backgroundColor,
        error: AppConstants.errorColor,
      ),
      scaffoldBackgroundColor: AppConstants.backgroundColor,
      useMaterial3: true,
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: AppConstants.backgroundColor,
        foregroundColor: AppConstants.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppConstants.headingXs,
        iconTheme: IconThemeData(
          color: AppConstants.textPrimary,
          size: AppConstants.iconLg,
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppConstants.primaryColor,
          foregroundColor: AppConstants.textOnPrimary,
          elevation: AppConstants.elevationSm,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppConstants.spaceLg,
            vertical: AppConstants.spaceMd,
          ),
          textStyle: AppConstants.buttonTextMd,
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppConstants.primaryColor,
          textStyle: AppConstants.labelMd,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          ),
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppConstants.primaryColor,
          side: BorderSide(
            color: AppConstants.primaryColor,
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: AppConstants.spaceLg,
            vertical: AppConstants.spaceMd,
          ),
          textStyle: AppConstants.buttonTextMd,
        ),
      ),
      
      // Card Theme
      cardTheme: CardThemeData(
        color: AppConstants.cardColor,
        elevation: AppConstants.elevationMd,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusLg),
        ),
        margin: EdgeInsets.all(AppConstants.spaceMd),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppConstants.surfaceColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          borderSide: BorderSide(color: AppConstants.grey300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          borderSide: BorderSide(color: AppConstants.grey300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          borderSide: BorderSide(
            color: AppConstants.primaryColor,
            width: 2.0,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          borderSide: BorderSide(color: AppConstants.errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
          borderSide: BorderSide(
            color: AppConstants.errorColor,
            width: 2.0,
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: AppConstants.spaceMd,
          vertical: AppConstants.spaceMd,
        ),
        labelStyle: AppConstants.labelMd,
        hintStyle: AppConstants.bodyMd.copyWith(
          color: AppConstants.textTertiary,
        ),
        errorStyle: AppConstants.bodyXs.copyWith(
          color: AppConstants.errorColor,
        ),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppConstants.surfaceColor,
        selectedItemColor: AppConstants.primaryColor,
        unselectedItemColor: AppConstants.textTertiary,
        selectedLabelStyle: AppConstants.labelXs.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppConstants.labelXs,
        type: BottomNavigationBarType.fixed,
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: AppConstants.textOnPrimary,
        elevation: AppConstants.elevationMd,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusFull),
        ),
      ),
      
      // Icon Theme
      iconTheme: IconThemeData(
        color: AppConstants.textSecondary,
        size: AppConstants.iconMd,
      ),
      
      // Primary Icon Theme
      primaryIconTheme: IconThemeData(
        color: AppConstants.textOnPrimary,
        size: AppConstants.iconMd,
      ),
      
      // Text Theme
      textTheme: const TextTheme(
        headlineLarge: AppConstants.headingXl,
        headlineMedium: AppConstants.headingLg,
        headlineSmall: AppConstants.headingMd,
        titleLarge: AppConstants.headingSm,
        titleMedium: AppConstants.headingXs,
        bodyLarge: AppConstants.bodyLg,
        bodyMedium: AppConstants.bodyMd,
        bodySmall: AppConstants.bodySm,
        labelLarge: AppConstants.labelLg,
        labelMedium: AppConstants.labelMd,
        labelSmall: AppConstants.labelSm,
      ),
      
      // Divider Theme
      dividerTheme: DividerThemeData(
        color: AppConstants.grey200,
        thickness: 1,
        space: AppConstants.spaceLg,
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppConstants.primaryColor,
        linearTrackColor: AppConstants.grey200,
        circularTrackColor: AppConstants.grey200,
      ),
      
      // Snackbar Theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppConstants.grey800,
        contentTextStyle: AppConstants.bodyMd.copyWith(
          color: AppConstants.textOnPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.radiusMd),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  // Can add a dark theme here in the future
  static ThemeData get darkTheme {
    return lightTheme;
  }
}