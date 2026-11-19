import 'package:flutter/material.dart';

/// Professional Pure Medical Blue & White Healthcare Theme
class AppColors {
  AppColors._();

  // Vibrant Medical Blue (Pure Healthcare Royal Blue)
  static const navy = Color(0xFF1565C0); // Vibrant Medical Blue
  static const navyLight = Color(0xFF1976D2); // Crisp Medical Blue Surface

  // Unified Primary Accent (Medical Blue - Zero Third Color)
  static const orange = Color(0xFF1565C0); // Unified Medical Blue
  static const orangeSoft = Color(0xFFEFF6FF); // Soft Ice-Blue Tint

  // Clean White Surfaces
  static const bg = Color(0xFFF8FAFC); // Clean Clinical Slate-White
  static const cardBg = Color(0xFFFFFFFF); // Pure White Cards
  static const ink = Color(0xFF0F172A); // High Contrast Slate Dark
  static const muted = Color(0xFF64748B); // Slate Muted Text
  static const line = Color(0xFFE2E8F0); // Crisp Clean Border

  // Status Tones (Exclusively Medical Blue & Ice White - Zero Third Color)
  static const success = Color(0xFF1565C0); // Medical Blue
  static const successSoft = Color(0xFFEFF6FF); // Soft Ice-Blue Pill
  static const warning = Color(0xFF1565C0); // Medical Blue
  static const warningSoft = Color(0xFFEFF6FF);
  static const danger = Color(0xFF1565C0); // Medical Blue (No red)
  static const dangerSoft = Color(0xFFEFF6FF);
  static const info = Color(0xFF1565C0); // Medical Blue
  static const infoSoft = Color(0xFFEFF6FF);
}

class AppText {
  AppText._();

  static const List<String> _fontFamilyFallback = [
    'Segoe UI',
    'Roboto',
    'Helvetica Neue',
    'Arial',
    'sans-serif',
  ];

  static const TextStyle display = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    height: 1.15,
    fontFamilyFallback: _fontFamilyFallback,
  );
  static const TextStyle h1 = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    height: 1.2,
    fontFamilyFallback: _fontFamilyFallback,
  );
  static const TextStyle h2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.ink,
    height: 1.25,
    fontFamilyFallback: _fontFamilyFallback,
  );
  static const TextStyle h3 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
    height: 1.3,
    fontFamilyFallback: _fontFamilyFallback,
  );
  static const TextStyle body = TextStyle(
    fontSize: 14,
    color: AppColors.ink,
    height: 1.4,
    fontFamilyFallback: _fontFamilyFallback,
  );
  static const TextStyle bodyBold = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.ink,
    height: 1.4,
    fontFamilyFallback: _fontFamilyFallback,
  );
  static const TextStyle muted = TextStyle(
    fontSize: 13,
    color: AppColors.muted,
    height: 1.4,
    fontFamilyFallback: _fontFamilyFallback,
  );
  static const TextStyle small = TextStyle(
    fontSize: 12,
    color: AppColors.muted,
    height: 1.3,
    fontFamilyFallback: _fontFamilyFallback,
  );
  static const TextStyle label = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    color: AppColors.orange,
    letterSpacing: 0.8,
    fontFamilyFallback: _fontFamilyFallback,
  );
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.navy,
    brightness: Brightness.light,
  ).copyWith(
    primary: AppColors.navy,
    onPrimary: Colors.white,
    secondary: AppColors.orange,
    onSecondary: Colors.white,
    surface: Colors.white,
    onSurface: AppColors.ink,
    error: AppColors.danger,
    outline: AppColors.line,
  );

  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: c, width: w),
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.bg,
    textTheme: const TextTheme()
        .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.bg,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
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
      focusedBorder: border(AppColors.orange, 1.6),
      errorBorder: border(AppColors.danger),
      focusedErrorBorder: border(AppColors.danger, 1.6),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      height: 68,
      indicatorColor: AppColors.orangeSoft,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 11.5,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? AppColors.navy : AppColors.muted,
          fontFamilyFallback: AppText._fontFamilyFallback,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return IconThemeData(
            color: selected ? AppColors.navy : AppColors.muted, size: 24);
      }),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.navy,
      contentTextStyle: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontFamilyFallback: AppText._fontFamilyFallback,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: const DividerThemeData(color: AppColors.line, space: 1, thickness: 1),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.orange, linearTrackColor: AppColors.line),
  );
}
