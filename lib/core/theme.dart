import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Pediacare Design System Colors
class AppColors {
  AppColors._();

  // Primary Brand Colors (#3478ED)
  static const primary = Color(0xFF3478ED);
  static const primaryDark = Color(0xFF2460D0);
  static const primaryLight = Color(0xFF5991F2);
  static const primarySoft = Color(0xFFEFF5FF);

  // Mint Green (#36C6B0)
  static const mint = Color(0xFF36C6B0);
  static const mintSoft = Color(0xFFE8F9F6);

  // Soft Lavender (#E9EDFF)
  static const lavender = Color(0xFFE9EDFF);
  static const lavenderDark = Color(0xFF7A8CD9);

  // Clean White Surfaces (#FFFFFF) & Base
  static const bg = Color(0xFFFFFFFF);
  static const cardBg = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1E293B);
  static const muted = Color(0xFF64748B);
  static const line = Color(0xFFE2E8F0);

  // Backward-compatibility aliases
  static const orange = primary;
  static const orangeSoft = lavender;
  static const navy = primary;
  static const navyLight = primaryLight;

  // Accents & Department Colors
  static const success = mint;
  static const successSoft = mintSoft;
  static const warning = Color(0xFFF59E0B);
  static const warningSoft = Color(0xFFFEF3C7);
  static const danger = Color(0xFFEF4444);
  static const dangerSoft = Color(0xFFFEE2E2);
  static const info = primary;
  static const infoSoft = lavender;

  static const cyan = Color(0xFF0EA5E9);
  static const cyanSoft = Color(0xFFE0F2FE);
  static const pink = Color(0xFFEC4899);
  static const pinkSoft = Color(0xFFFCE7F3);
  static const purple = Color(0xFF8B5CF6);
  static const purpleSoft = lavender;
  static const amber = Color(0xFFF59E0B);
  static const amberSoft = Color(0xFFFEF3C7);
  static const green = mint;
  static const greenSoft = mintSoft;
}

/// Typography: Poppins (Headers & Display) + Inter (Body & Muted)
class AppText {
  AppText._();

  static TextStyle display = GoogleFonts.poppins(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    height: 1.2,
  );
  static TextStyle h1 = GoogleFonts.poppins(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    height: 1.25,
  );
  static TextStyle h2 = GoogleFonts.poppins(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    height: 1.3,
  );
  static TextStyle h3 = GoogleFonts.poppins(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
    height: 1.35,
  );
  static TextStyle body = GoogleFonts.inter(
    fontSize: 14,
    color: AppColors.ink,
    height: 1.45,
  );
  static TextStyle bodyBold = GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
    height: 1.45,
  );
  static TextStyle muted = GoogleFonts.inter(
    fontSize: 13,
    color: AppColors.muted,
    height: 1.4,
  );
  static TextStyle small = GoogleFonts.inter(
    fontSize: 12,
    color: AppColors.muted,
    height: 1.35,
  );
  static TextStyle label = GoogleFonts.poppins(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    letterSpacing: 0.8,
  );
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    secondary: AppColors.mint,
    onSecondary: Colors.white,
    surface: Colors.white,
    onSurface: AppColors.ink,
    error: AppColors.danger,
    outline: AppColors.line,
  );

  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: c, width: w),
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    textTheme: GoogleFonts.interTextTheme().apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: AppText.h2,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: AppText.muted,
      hintStyle: AppText.muted,
      border: border(AppColors.line),
      enabledBorder: border(AppColors.line),
      focusedBorder: border(AppColors.primary, 1.8),
      errorBorder: border(AppColors.danger),
      focusedErrorBorder: border(AppColors.danger, 1.8),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      height: 68,
      indicatorColor: AppColors.lavender,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return GoogleFonts.inter(
          fontSize: 11.5,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.primary : AppColors.muted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
          color: selected ? AppColors.primary : AppColors.muted,
          size: 24,
        );
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.primary,
      contentTextStyle: GoogleFonts.inter(
        color: Colors.white,
        fontSize: 14,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.line, space: 1, thickness: 1),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
      linearTrackColor: AppColors.line,
    ),
  );
}
