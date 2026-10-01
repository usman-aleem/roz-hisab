import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ROZ HISAB — Design System
///
/// Palette: Refined Emerald + Coral + a subtle Gold accent for
/// premium highlights. Warm, trustworthy, not cold/corporate.
///
/// Typography: Poppins for headings (personality) + Inter for
/// body/numbers (maximum readability for Rs. amounts and lists).
class AppColors {
  // Brand — deep navy (trust, finance-grade seriousness)
  static const primary = Color(0xFF1E3A5F);
  static const primaryDark = Color(0xFF142943);
  static const primaryLight = Color(0xFFE4EAF2);

  // Accent / CTA — richer teal (clear call-to-action, distinct from
  // brand navy, more saturated than before for better visual pop)
  static const accent = Color(0xFF0D9488);
  static const accentDark = Color(0xFF0A7367);
  static const accentLight = Color(0xFFDCF4F1);

  // Secondary highlight (used sparingly)
  static const gold = Color(0xFFC9A227);
  static const goldLight = Color(0xFFFBF3DC);

  // Status — standard traffic-light semantics, unambiguous
  static const amber = Color(0xFFD97706); // due soon
  static const amberLight = Color(0xFFFCEDD7);
  static const danger = Color(0xFFDC2626); // overdue / you owe
  static const dangerLight = Color(0xFFFCE4E4);
  static const success = Color(0xFF15803D); // you'll receive / paid

  // Neutrals — cool grays (clean, professional, not "warm/casual")
  static const background = Color(0xFFF4F6F9);
  static const cardBackground = Color(0xFFFFFFFF);
  static const border = Color(0xFFE2E6EC);
  static const textPrimary = Color(0xFF101828);
  static const textSecondary = Color(0xFF5B6472);
  static const textMuted = Color(0xFF98A2B3);
}

/// Consistent spacing/radius values used across the app.
class AppTokens {
  static const radiusSm = 10.0;
  static const radiusMd = 14.0;
  static const radiusLg = 18.0;

  static const spaceXs = 4.0;
  static const spaceSm = 8.0;
  static const spaceMd = 16.0;
  static const spaceLg = 24.0;

  /// Subtle elevation — a soft shadow instead of a hard Material
  /// shadow, used on key cards (summary cards, receipt, balance card).
  static List<BoxShadow> get softShadow => [
        BoxShadow(
          color: AppColors.textPrimary.withValues(alpha: 0.05),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];
}

class AppTheme {
  static ThemeData get light {
    final baseText = GoogleFonts.interTextTheme();

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.accent,
        background: AppColors.background,
      ),
      textTheme: baseText.copyWith(
        // Headings -> Poppins (personality)
        headlineLarge: GoogleFonts.poppins(
          fontSize: 26,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 21,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
        // Body/numbers -> Inter (clarity)
        bodyLarge: GoogleFonts.inter(
          fontSize: 15,
          color: AppColors.textPrimary,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 13.5,
          color: AppColors.textSecondary,
        ),
        labelLarge: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.poppins(
          color: AppColors.textPrimary,
          fontSize: 21,
          fontWeight: FontWeight.w700,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: GoogleFonts.inter(
          color: AppColors.textMuted,
          fontSize: 14.5,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.4),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
          ),
          elevation: 0,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.border, width: 1.2),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTokens.radiusMd),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          textStyle: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        selectedLabelStyle: GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 11.5),
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, space: 1),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        elevation: 2,
        extendedTextStyle: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}
