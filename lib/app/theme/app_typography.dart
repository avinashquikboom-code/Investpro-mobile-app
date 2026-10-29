import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Centralized Typography system for InvestPro Investor Mobile App.
/// Exactly matches InvestPro Admin Mobile App hierarchy, font family,
/// font weights, and sizing specifications.
class AppTypography {
  AppTypography._();

  static const String fontFamily = 'Poppins';

  // --- RAW POppins TEXT STYLES (MATCHING ADMIN APP EXACTLY) ---

  /// Display Large (28px Bold) - Splash, Big Numbers, Major Totals
  static TextStyle displayLarge({Color? color}) => GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.textPrimary,
      );

  /// Display Medium (24px Bold) - Dashboard Headers, Portfolio Value
  static TextStyle displayMedium({Color? color}) => GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.textPrimary,
      );

  /// Title Large / Screen & Section Headings (20px SemiBold)
  static TextStyle titleLarge({Color? color}) => GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.textPrimary,
      );

  /// AppBar Title (18px SemiBold) - AppBars & Primary Dialog Titles
  static TextStyle appBarTitle({Color? color}) => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.textPrimary,
      );

  /// Title Medium / Card Titles & Subheadings (16px SemiBold)
  static TextStyle titleMedium({Color? color}) => GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.textPrimary,
      );

  /// Title Small / Item Headings & Table Headers (14px SemiBold)
  static TextStyle titleSmall({Color? color}) => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.textPrimary,
      );

  /// Body Large / Primary Descriptions & Prominent Text (15px Regular)
  static TextStyle bodyLarge({Color? color}) => GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.textPrimary,
      );

  /// Body Medium / Standard Paragraphs & Key-Value Pairs (13px Regular)
  static TextStyle bodyMedium({Color? color}) => GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.textSecondary,
      );

  /// Body Small / Secondary Metadata, Timestamps, Captions (11px Regular)
  static TextStyle bodySmall({Color? color}) => GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.textSecondary,
      );

  /// Button Text / Action Labels (15px SemiBold)
  static TextStyle buttonText({Color? color}) => GoogleFonts.poppins(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: color ?? Colors.white,
      );

  /// Label Large (14px SemiBold)
  static TextStyle labelLarge({Color? color}) => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: color ?? Colors.white,
      );

  /// Form Field Label (13px SemiBold) - Identical to Admin App CustomTextField
  static TextStyle formLabel({Color? color}) => GoogleFonts.poppins(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.textPrimary,
      );

  /// Form Field Input Text (14px Regular)
  static TextStyle input({Color? color}) => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.textPrimary,
      );

  /// Form Field Hint Text (14px Regular)
  static TextStyle hint({Color? color}) => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.textSecondary,
      );

  /// Status Badge Label (11px Bold, 0.3 letterSpacing)
  static TextStyle statusBadge({required Color color}) => GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
        color: color,
      );

  /// Bottom Navigation Label (12px Medium)
  static TextStyle bottomNav({Color? color}) => GoogleFonts.poppins(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: color ?? AppColors.textSecondary,
      );

  /// Dialog Title (18px SemiBold)
  static TextStyle dialogTitle({Color? color}) => GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.textPrimary,
      );

  /// Dialog Body (14px Regular)
  static TextStyle dialogBody({Color? color}) => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.textSecondary,
      );

  /// Snackbar / Toast Text (14px Medium)
  static TextStyle snackbar({Color? color}) => GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color ?? Colors.white,
      );

  /// Monospace / Reference Code (13px Medium)
  static TextStyle code({Color? color, double fontSize = 13}) =>
      TextStyle(
        fontFamily: 'monospace',
        fontSize: fontSize,
        fontWeight: FontWeight.w500,
        color: color ?? AppColors.textPrimary,
      );

  // --- THEME-AWARE HELPERS (AUTOMATIC LIGHT / DARK COLOR RESOLUTION) ---

  static bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static TextStyle screenHeading(BuildContext context) =>
      titleLarge(color: _isDark(context) ? AppColors.textPrimaryDark : AppColors.textPrimary);

  static TextStyle sectionHeading(BuildContext context) =>
      titleMedium(color: _isDark(context) ? AppColors.textPrimaryDark : AppColors.textPrimary);

  static TextStyle cardTitle(BuildContext context) =>
      titleMedium(color: _isDark(context) ? AppColors.textPrimaryDark : AppColors.textPrimary);

  static TextStyle body(BuildContext context) =>
      bodyMedium(color: _isDark(context) ? AppColors.textSecondaryDark : AppColors.textSecondary);

  static TextStyle caption(BuildContext context) =>
      bodySmall(color: _isDark(context) ? AppColors.textSecondaryDark : AppColors.textSecondary);
}
