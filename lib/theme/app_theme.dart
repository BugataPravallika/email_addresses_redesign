import 'package:flutter/material.dart';

/// Restrained palette: neutral surfaces, navy text, and blue/green/amber states.
class AppColors {
  const AppColors._();

  static const background = Color(0xFFF6F8FB);
  static const ink = Color(0xFF17324D);
  static const inkMuted = Color(0xFF586D83);
  static const outline = Color(0xFFD9E2EC);

  static const brand = Color(0xFF1263A8);
  static const brandTint = Color(0xFFEAF2FA);

  static const accent = brand;
  static const accentTint = brandTint;
  static const accentBorder = outline;

  static const success = Color(0xFF08764E);
  static const successTint = Color(0xFFE7F4ED);

  static const warning = Color(0xFF8A5600);
  static const warningTint = Color(0xFFFFF3DE);

  static const danger = brand;
}

class AppTheme {
  const AppTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(seedColor: AppColors.brand).copyWith(
      primary: AppColors.brand,
      onPrimary: Colors.white,
      secondary: AppColors.brand,
      onSecondary: Colors.white,
      secondaryContainer: AppColors.brandTint,
      onSecondaryContainer: AppColors.ink,
      surface: AppColors.background,
      onSurface: AppColors.ink,
      error: AppColors.danger,
      outline: AppColors.outline,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);

    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
    const label = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);

    return base.copyWith(
      scaffoldBackgroundColor: AppColors.background,
      textTheme: base.textTheme.apply(
        bodyColor: AppColors.ink,
        displayColor: AppColors.ink,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(88, 52),
          shape: shape,
          textStyle: label,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(88, 52),
          shape: shape,
          textStyle: label,
          foregroundColor: AppColors.brand,
          side: const BorderSide(color: AppColors.brand, width: 1.4),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: AppColors.accent,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.ink,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
