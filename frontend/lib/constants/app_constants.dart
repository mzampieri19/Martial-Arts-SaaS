import 'package:flutter/material.dart';

/// App-wide constants for consistent design and theming
class AppConstants {
  AppConstants._();

  // COLORS
  // Can be customized
  static const Color primaryColor = Color(0xFF6B46C1); // Purple
  static const Color primaryColorLight = Color(0xFF8B5CF6);
  static const Color primaryColorDark = Color(0xFF553C9A);
  
  static const Color secondaryColor = Color(0xFF10B981); // Emerald
  static const Color secondaryColorLight = Color(0xFF34D399);
  static const Color secondaryColorDark = Color(0xFF059669);
  
  static const Color accentColor = Color(0xFFDD836C); // Orange accent
  static const Color accentColorLight = Color(0xFFE69A87);
  static const Color accentColorDark = Color(0xFFD16B51);
  
  // Background Colors
  static const Color backgroundColor = Color(0xFFFFFDE2); // Warm yellow background
  static const Color surfaceColor = Color(0xFFFFFFFF);
  static const Color cardColor = Color(0xFFFFFFFF);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF1F2937);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textTertiary = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  
  // Status Colors
  static const Color successColor = Color(0xFF10B981);
  static const Color warningColor = Color(0xFFF59E0B);
  static const Color errorColor = Color(0xFFEF4444);
  static const Color infoColor = Color(0xFF3B82F6);
  
  // Neutral Colors
  static const Color grey50 = Color(0xFFF9FAFB);
  static const Color grey100 = Color(0xFFF3F4F6);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey400 = Color(0xFF9CA3AF);
  static const Color grey500 = Color(0xFF6B7280);
  static const Color grey600 = Color(0xFF4B5563);
  static const Color grey700 = Color(0xFF374151);
  static const Color grey800 = Color(0xFF1F2937);
  static const Color grey900 = Color(0xFF111827);

  // SPACING
  static const double spaceXs = 4.0;
  static const double spaceSm = 8.0;
  static const double spaceMd = 16.0;
  static const double spaceLg = 24.0;
  static const double spaceXl = 32.0;
  static const double space2xl = 48.0;
  static const double space3xl = 64.0;

  // BORDER RADIUS
  static const double radiusXs = 4.0;
  static const double radiusSm = 6.0;
  static const double radiusMd = 8.0;
  static const double radiusLg = 12.0;
  static const double radiusXl = 16.0;
  static const double radius2xl = 24.0;
  static const double radiusFull = 9999.0;

  // ELEVATIONS
  static const double elevationXs = 1.0;
  static const double elevationSm = 2.0;
  static const double elevationMd = 4.0;
  static const double elevationLg = 8.0;
  static const double elevationXl = 12.0;

  // ICON SIZES
  static const double iconXs = 12.0;
  static const double iconSm = 16.0;
  static const double iconMd = 20.0;
  static const double iconLg = 24.0;
  static const double iconXl = 32.0;
  static const double icon2xl = 48.0;

  // BUTTON SIZES
  static const double buttonHeightSm = 32.0;
  static const double buttonHeightMd = 40.0;
  static const double buttonHeightLg = 48.0;
  static const double buttonHeightXl = 56.0;

  // TEXT STYLES
  static const TextStyle headingXl = TextStyle(
    fontSize: 36.0,
    fontWeight: FontWeight.w800,
    color: textPrimary,
    height: 1.2,
  );

  static const TextStyle headingLg = TextStyle(
    fontSize: 30.0,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    height: 1.2,
  );

  static const TextStyle headingMd = TextStyle(
    fontSize: 24.0,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.3,
  );

  static const TextStyle headingSm = TextStyle(
    fontSize: 20.0,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.3,
  );

  static const TextStyle headingXs = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.4,
  );

  static const TextStyle bodyLg = TextStyle(
    fontSize: 18.0,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    height: 1.6,
  );

  static const TextStyle bodyMd = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle bodySm = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle bodyXs = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.4,
  );

  static const TextStyle labelLg = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w500,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle labelMd = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w500,
    color: textPrimary,
    height: 1.5,
  );

  static const TextStyle labelSm = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w500,
    color: textPrimary,
    height: 1.4,
  );

  static const TextStyle labelXs = TextStyle(
    fontSize: 11.0,
    fontWeight: FontWeight.w500,
    color: textSecondary,
    height: 1.4,
  );

  // BUTTON TEXT STYLES
  static const TextStyle buttonTextLg = TextStyle(
    fontSize: 16.0,
    fontWeight: FontWeight.w600,
    color: textOnPrimary,
    height: 1.0,
  );

  static const TextStyle buttonTextMd = TextStyle(
    fontSize: 14.0,
    fontWeight: FontWeight.w600,
    color: textOnPrimary,
    height: 1.0,
  );

  static const TextStyle buttonTextSm = TextStyle(
    fontSize: 12.0,
    fontWeight: FontWeight.w600,
    color: textOnPrimary,
    height: 1.0,
  );

  // COMMON DURATIONS
  static const Duration animationFast = Duration(milliseconds: 150);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);

  // BREAKPOINTS (for responsive design)
  static const double mobileBreakpoint = 640.0;
  static const double tabletBreakpoint = 768.0;
  static const double desktopBreakpoint = 1024.0;
}

/// Martial Arts specific constants
class MartialArtsConstants {
  MartialArtsConstants._();

  // Belt colors for martial arts
  static const Map<String, Color> beltColors = {
    'white': Color(0xFFFFFFFF),
    'yellow': Color(0xFFFEF08A),
    'orange': Color(0xFFFED7AA),
    'green': Color(0xFFBBF7D0),
    'blue': Color(0xFFBFDBFE),
    'purple': Color(0xFFE9D5FF),
    'brown': Color(0xFFD2B48C),
    'black': Color(0xFF1F2937),
    'red': Color(0xFFFECACA),
  };

  // Can add more martial arts specific constants here
  // Such as classes types, difficulty levels, etc.
  // Mapping from numeric class type IDs to human-friendly names.
  // Update these values to match the backend enums/codes.
  static const Map<int, String> classTypeNames = {
    1: 'Karate',
    2: 'BJJ',
    3: 'Muay Thai',
    4: 'Conditioning',
    5: 'Yoga',
    6: 'Open Mat',
  };

  /// Helper to resolve a class type code or string to a display name.
  /// Accepts int or numeric string; falls back to the original string if not found.
  static String resolveClassType(dynamic codeOrString) {
    if (codeOrString == null) return '';
    if (codeOrString is int) {
      return classTypeNames[codeOrString] ?? codeOrString.toString();
    }
    if (codeOrString is String) {
      final trimmed = codeOrString.trim();
      // If the string contains only digits, try to parse and lookup
      final digitsOnly = RegExp(r'^\d+\$');
      if (digitsOnly.hasMatch(trimmed)) {
        try {
          final val = int.parse(trimmed);
          return classTypeNames[val] ?? trimmed;
        } catch (_) {
          return trimmed;
        }
      }
      // Otherwise return the string as-is
      return trimmed;
    }
    // Fallback to toString
    return codeOrString.toString();
  }

}