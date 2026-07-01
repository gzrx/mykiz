import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// KIZ Design System color tokens.
///
/// Palette is built around the college's institutional lime/olive and a warm,
/// paper-and-cork "notice board" neutral family — everything but [error]
/// shares an olive-green undertone so accents read as one consistent world.
abstract final class KizColors {
  /// Primary brand color (Lime Green) — used sparingly as a pop/highlight,
  /// and as the "new / submitted" status color.
  static const Color primary = Color(0xFFC3DC52);

  /// Secondary structural color (deepened Olive) — links, focus states,
  /// outlined actions.
  static const Color secondary = Color(0xFF6B8500);

  /// Background color — warm paper, not stark white.
  static const Color background = Color(0xFFF6F5EF);

  /// Surface color for cards and sections — a lighter warm tone than
  /// [background] so elevated content reads as "lifted paper".
  static const Color surface = Color(0xFFFCFBF6);

  /// On-surface text color — body copy. A lighter olive-ink than
  /// [onBackground] for secondary emphasis.
  static const Color onSurface = Color(0xFF565A47);

  /// On-background text color — headings and high-emphasis text. Warm
  /// near-black with an olive undertone rather than neutral grey.
  static const Color onBackground = Color(0xFF22261A);

  /// Error / rejected / cancelled state color (Rust) — the one deliberate
  /// outlier hue, reserved for things that need attention.
  static const Color error = Color(0xFFB5482E);

  /// Navigation bar background color (deepened Olive).
  static const Color navigationBar = Color(0xFF6B8500);

  /// Border and divider color — light cork tint.
  static const Color border = Color(0xFFDDD3B8);

  /// Card border color — lighter cork tint.
  static const Color cardBorder = Color(0xFFE6DEC8);

  /// Focus ring color for inputs — derived from [secondary] (olive).
  static const Color focusRing = Color(0x1F6B8500); // olive @ ~12%

  /// Tan/wood neutral accent — tag backgrounds, dividers, code chips.
  static const Color cork = Color(0xFFC9A876);

  /// Lime/Olive blend — "active / in progress / approved" status color.
  static const Color moss = Color(0xFF8FAE3D);
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

/// KIZ Design System border radius tokens.
abstract final class KizRadius {
  static const double button = 8.0;
  static const double input = 8.0;
  static const double card = 12.0;
}

/// KIZ Design System typography roles.
///
/// Three faces, each with one job: [display] carries personality (page
/// titles, empty states), [body]/Poppins stays quiet and readable, [mono]
/// marks anything that is literally a code — booking references, room/bed/
/// block identifiers, application IDs, ledger-style table data.
abstract final class KizFonts {
  static TextStyle display({
    double fontSize = 24,
    FontWeight fontWeight = FontWeight.w600,
    Color? color,
  }) =>
      GoogleFonts.fraunces(
        fontSize: fontSize,
        fontWeight: fontWeight,
        color: color ?? KizColors.onBackground,
      );

  static TextStyle mono({
    double fontSize = 13,
    FontWeight fontWeight = FontWeight.w500,
    Color? color,
    double letterSpacing = 0.2,
  }) =>
      GoogleFonts.ibmPlexMono(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        color: color ?? KizColors.onSurface,
      );
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
        displayLarge: GoogleFonts.fraunces(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: KizColors.onBackground,
        ),
        displayMedium: GoogleFonts.fraunces(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: KizColors.onBackground,
        ),
        displaySmall: GoogleFonts.fraunces(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: KizColors.onBackground,
        ),
        headlineLarge: GoogleFonts.fraunces(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: KizColors.onBackground,
        ),
        headlineMedium: GoogleFonts.fraunces(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: KizColors.onBackground,
        ),
        headlineSmall: GoogleFonts.fraunces(
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
        titleTextStyle: GoogleFonts.fraunces(
          fontSize: 20,
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
            borderRadius: BorderRadius.circular(KizRadius.button),
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
            borderRadius: BorderRadius.circular(KizRadius.button),
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
          borderRadius: BorderRadius.circular(KizRadius.card),
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
      dataTableTheme: DataTableThemeData(
        headingTextStyle: GoogleFonts.ibmPlexMono(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: KizColors.onSurface,
        ),
        dataTextStyle: GoogleFonts.poppins(
          fontSize: 14,
          color: KizColors.onBackground,
        ),
        dividerThickness: 1,
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return KizColors.primary.withValues(alpha: 0.08);
          }
          return Colors.transparent;
        }),
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
