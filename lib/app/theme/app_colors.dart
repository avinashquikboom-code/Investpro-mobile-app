import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Palette
  static const Color primary = Color(0xFF00854B);
  static const Color primaryDark = Color(0xFF003B2D);
  static const Color primaryLight = Color(0xFF0E9F53);

  // Accent & Backgrounds
  static const Color accent = Color(0xFF35C76F);
  static const Color background = Color(0xFFFFFFFF);
  static const Color secondaryBackground = Color(0xFFF5FAF7);
  static const Color lightMint = Color(0xFFE7F7EE);
  static const Color surface = Color(0xFFFFFFFF);

  // Dark Theme Palette
  static const Color backgroundDark = Color(0xFF0D1813);
  static const Color surfaceDark = Color(0xFF14241C);
  static const Color surfaceDarkElevated = Color(0xFF1C3127);
  static const Color borderDark = Color(0xFF243B2F);

  // Typography
  static const Color textPrimary = Color(0xFF153B2E);
  static const Color textSecondary = Color(0xFF71847B);
  static const Color textPrimaryDark = Color(0xFFF1F7F4);
  static const Color textSecondaryDark = Color(0xFF8DA39A);

  // Status & Utility Colors
  static const Color border = Color(0xFFE1ECE5);
  static const Color divider = Color(0xFFE8EFEA);
  static const Color success = Color(0xFF16A34A);
  static const Color successLight = Color(0xFFE7F7EE);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFEFF6FF);

  // Status Pill Colors
  static const Color badgeGreenBg = Color(0xFFE7F7EE);
  static const Color badgeGreenText = Color(0xFF16A34A);
  static const Color badgeAmberBg = Color(0xFFFFFBEB);
  static const Color badgeAmberText = Color(0xFFD97706);
  static const Color badgeBlueBg = Color(0xFFEFF6FF);
  static const Color badgeBlueText = Color(0xFF2563EB);
  static const Color badgeRedBg = Color(0xFFFEE2E2);
  static const Color badgeRedText = Color(0xFFDC2626);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF003B2D), Color(0xFF00854B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGreenGradient = LinearGradient(
    colors: [Color(0xFF005A32), Color(0xFF007542)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFF003820), Color(0xFF003B2D), Color(0xFF00854B)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
