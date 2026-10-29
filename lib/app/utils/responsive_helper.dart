import 'package:flutter/material.dart';

/// Responsive design utility matching the InvestPro breakpoint specifications:
/// - Phone: below 600dp
/// - Tablet: 600dp to 899dp
/// - Large tablet: 900dp and above
class ResponsiveHelper {
  ResponsiveHelper._();

  static const double phoneBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;
  static const double maxContentWidth = 1100.0;

  static double screenWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.sizeOf(context).height;

  static bool isPhone(BuildContext context) =>
      screenWidth(context) < phoneBreakpoint;

  static bool isTablet(BuildContext context) {
    final w = screenWidth(context);
    return w >= phoneBreakpoint && w < tabletBreakpoint;
  }

  static bool isLargeTablet(BuildContext context) =>
      screenWidth(context) >= tabletBreakpoint;

  static bool isPhoneWidth(double width) => width < phoneBreakpoint;

  static bool isTabletWidth(double width) =>
      width >= phoneBreakpoint && width < tabletBreakpoint;

  static bool isLargeTabletWidth(double width) => width >= tabletBreakpoint;

  /// Returns responsive column count for grids based on available width
  static int gridColumns(
    double width, {
    int phone = 1,
    int tablet = 2,
    int largeTablet = 3,
  }) {
    if (width >= tabletBreakpoint) return largeTablet;
    if (width >= phoneBreakpoint) return tablet;
    return phone;
  }

  /// Calculates safe aspect ratio for cards so content never clips or overflows
  static double cardAspectRatio(double width) {
    if (width >= tabletBreakpoint) return 1.45;
    if (width >= phoneBreakpoint) return 1.35;
    if (width <= 340) return 1.15;
    return 1.30;
  }

  /// Standardized responsive page padding
  static EdgeInsets pagePadding(BuildContext context) {
    final width = screenWidth(context);
    if (width >= tabletBreakpoint) {
      return const EdgeInsets.symmetric(horizontal: 36, vertical: 24);
    } else if (width >= phoneBreakpoint) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 20);
    }
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  }

  /// Responsive dialog width constrained between 280 and 520
  static double dialogWidth(BuildContext context) {
    final width = screenWidth(context);
    return (width * 0.85).clamp(280.0, 520.0);
  }

  /// Constrains content to an adaptive maxWidth
  static Widget responsiveContainer({
    required BuildContext context,
    required Widget child,
    double? maxWidth,
  }) {
    final width = screenWidth(context);
    final effectiveMax = maxWidth ??
        (width >= tabletBreakpoint
            ? maxContentWidth
            : (width >= phoneBreakpoint ? 800.0 : double.infinity));

    if (effectiveMax.isInfinite) return child;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMax),
        child: child,
      ),
    );
  }
}
