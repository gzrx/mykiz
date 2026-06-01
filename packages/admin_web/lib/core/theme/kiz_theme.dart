import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// KIZ Design System color tokens.
abstract final class KizColors {
  /// Primary brand color (Lime Green).
  static const Color primary = Color(0xFFC3DC52);

  /// Secondary accent color (Cobalt Blue).
  static const Color secondary = Color(0xFF3B82F6);

  /// Background color (White).
  static const Color background = Color(0xFFFFFFFF);

  /// Surface color for cards and sections.
  static const Color surface = Color(0xFFF9FAFB);

  /// On-surface text color (Charcoal).
  static const Color onSurface = Color(0xFF374151);

  /// On-background text color (Navy).
  static const Color onBackground = Color(0xFF111827);

  /// Error state color.
  static const Color error = Color(0xFFEF4444);

  /// Navigation bar background color.
  static const Color navigationBar = Color(0xFF759600);

  /// Border and divider color.
  static const Color border = Color(0xFFD1D5DB);

  /// Card border color.
  static const Color cardBorder = Color(0xFFE5E7EB);

  /// Focus ring color for inputs.
  static const Color focusRing = Color(0x193B82F6); // rgba(59, 130, 246, 0.1)
}

/// KIZ Design System spacing based on 4px grid.
abstract final class KizSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double base = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
}

/// KIZ Design System theme configuration.
class KizTheme {
  KizTheme._();

  /// Minimum touch target size (44x44px).
  static const double minTouchTarget = 44.0;

  /// Creates the KIZ [ThemeData] for the Admin Web application.
  static ThemeData get lightTheme {
    final poppinsTextTheme = GoogleFonts.poppinsTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: KizColors.primary,
        secondary: KizColors.secondary,
        surface: KizColors.surface,
        error: KizColors.error,
        onPrimary: KizColors.onBackground,
        onSecondary: KizColors.background,
        onSurface: KizColors.onSurface,
        onError: KizColors.background,
      ),
      scaffoldBackgroundColor: KizColors.background,
      textTheme: poppinsTextTheme.copyWith(
        displayLarge: GoogleFonts.leagueSpartan(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: KizColors.onBackground,
        ),
        displayMedium: GoogleFonts.leagueSpartan(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: KizColors.onBackground,
        ),
        displaySmall: GoogleFonts.leagueSpartan(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: KizColors.onBackground,
        ),
        headlineLarge: GoogleFonts.leagueSpartan(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: KizColors.onBackground,
        ),
        headlineMedium: GoogleFonts.leagueSpartan(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: KizColors.onBackground,
        ),
        headlineSmall: GoogleFonts.leagueSpartan(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: KizColors.onBackground,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w400,
          color: KizColors.onSurface,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: KizColors.onSurface,
        ),
        bodySmall: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: KizColors.onSurface,
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: KizColors.onBackground,
        ),
        labelMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: KizColors.onBackground,
        ),
        labelSmall: GoogleFonts.poppins(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: KizColors.onSurface,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: KizColors.navigationBar,
        foregroundColor: KizColors.background,
        elevation: 0,
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: KizColors.background,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: KizColors.primary,
          foregroundColor: KizColors.onBackground,
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          minimumSize: const Size(minTouchTarget, minTouchTarget),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: KizColors.secondary,
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(5),
          ),
          side: const BorderSide(color: KizColors.secondary),
          minimumSize: const Size(minTouchTarget, minTouchTarget),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: KizColors.secondary,
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          minimumSize: const Size(minTouchTarget, minTouchTarget),
        ),
      ),
      cardTheme: CardThemeData(
        color: KizColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: KizColors.cardBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 12,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: KizColors.border, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: KizColors.border, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: KizColors.secondary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: KizColors.error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: KizColors.error, width: 2),
        ),
        labelStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: KizColors.onSurface,
        ),
        hintStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: KizColors.border,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: KizColors.border,
        thickness: 1,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: KizColors.navigationBar,
        selectedIconTheme: const IconThemeData(color: KizColors.background),
        unselectedIconTheme:
            IconThemeData(color: KizColors.background.withValues(alpha: 0.7)),
      ),
    );
  }
}
