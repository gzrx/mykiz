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

  /// Input focus ring color.
  static const Color focusRing = Color(0x193B82F6); // rgba(59, 130, 246, 0.1)
}

/// KIZ Design System spacing tokens (4px base unit grid).
abstract final class KizSpacing {
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double base = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xxl = 32.0;
}

/// KIZ Design System border radius tokens.
abstract final class KizRadius {
  static const double button = 5.0;
  static const double input = 6.0;
  static const double card = 8.0;
}

/// Minimum touch target size for accessibility.
const double kMinTouchTarget = 44.0;

/// KIZ Design System theme configuration.
class KizTheme {
  KizTheme._();

  /// Creates the KIZ Material theme for the Student App.
  static ThemeData get lightTheme {
    final poppins = GoogleFonts.poppinsTextTheme();
    final leagueSpartan = GoogleFonts.leagueSpartanTextTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: const ColorScheme.light(
        primary: KizColors.primary,
        secondary: KizColors.secondary,
        surface: KizColors.surface,
        error: KizColors.error,
        onPrimary: KizColors.onBackground,
        onSecondary: Colors.white,
        onSurface: KizColors.onSurface,
        onError: Colors.white,
      ),
      scaffoldBackgroundColor: KizColors.background,
      appBarTheme: const AppBarTheme(
        backgroundColor: KizColors.navigationBar,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: poppins.copyWith(
        displayLarge: leagueSpartan.displayLarge?.copyWith(
          color: KizColors.onBackground,
        ),
        displayMedium: leagueSpartan.displayMedium?.copyWith(
          color: KizColors.onBackground,
        ),
        displaySmall: leagueSpartan.displaySmall?.copyWith(
          color: KizColors.onBackground,
        ),
        headlineLarge: leagueSpartan.headlineLarge?.copyWith(
          color: KizColors.onBackground,
        ),
        headlineMedium: leagueSpartan.headlineMedium?.copyWith(
          color: KizColors.onBackground,
        ),
        headlineSmall: leagueSpartan.headlineSmall?.copyWith(
          color: KizColors.onBackground,
        ),
        bodyLarge: poppins.bodyLarge?.copyWith(
          fontSize: 16,
          color: KizColors.onSurface,
        ),
        bodyMedium: poppins.bodyMedium?.copyWith(
          fontSize: 16,
          color: KizColors.onSurface,
        ),
        labelLarge: poppins.labelLarge?.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: KizColors.onSurface,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: KizColors.primary,
          foregroundColor: KizColors.onBackground,
          padding: const EdgeInsets.symmetric(
            vertical: KizSpacing.md,
            horizontal: KizSpacing.xl,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KizRadius.button),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          minimumSize: const Size(kMinTouchTarget, kMinTouchTarget),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: KizColors.secondary,
          padding: const EdgeInsets.symmetric(
            vertical: KizSpacing.md,
            horizontal: KizSpacing.xl,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KizRadius.button),
          ),
          side: const BorderSide(color: KizColors.secondary),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          minimumSize: const Size(kMinTouchTarget, kMinTouchTarget),
        ),
      ),
      cardTheme: CardThemeData(
        color: KizColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KizRadius.card),
          side: const BorderSide(color: KizColors.cardBorder),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        contentPadding: const EdgeInsets.symmetric(
          vertical: KizSpacing.md,
          horizontal: KizSpacing.base,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KizRadius.input),
          borderSide: const BorderSide(color: KizColors.border, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KizRadius.input),
          borderSide: const BorderSide(color: KizColors.border, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KizRadius.input),
          borderSide: const BorderSide(color: KizColors.secondary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KizRadius.input),
          borderSide: const BorderSide(color: KizColors.error, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(KizRadius.input),
          borderSide: const BorderSide(color: KizColors.error, width: 2),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: KizColors.border,
        thickness: 1,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: KizColors.background,
        selectedItemColor: KizColors.navigationBar,
        unselectedItemColor: KizColors.onSurface,
      ),
    );
  }
}
