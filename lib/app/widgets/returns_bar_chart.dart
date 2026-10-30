import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/returns_controller.dart';
import '../theme/app_colors.dart';
import '../utils/currency_formatter.dart';

class ReturnsBarChart extends StatefulWidget {
  final List<ReturnChartPoint> points;
  final String period;
  final bool isDark;

  const ReturnsBarChart({
    super.key,
    required this.points,
    required this.period,
    required this.isDark,
  });

  @override
  State<ReturnsBarChart> createState() => _ReturnsBarChartState();
}

class _ReturnsBarChartState extends State<ReturnsBarChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final points = widget.points;

    // Calculate maximum amount for Y-axis scaling
    double maxRaw = 0.0;
    for (final p in points) {
      if (p.amount > maxRaw) maxRaw = p.amount;
    }
    final double maxAmount = maxRaw > 0 ? _calculateCeiling(maxRaw) : 10000.0;
    const double yAxisWidth = 48.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE5EFEA),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            offset: const Offset(0, 4),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Returns Analytics',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${widget.period} breakdown',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDarkElevated : AppColors.lightMint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '₹ INR',
                  style: GoogleFonts.poppins(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Main Chart Box
          SizedBox(
            height: 200,
            child: Column(
              children: [
                // 1. Chart Body (Y-Axis + Grid Lines + Bars)
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final double chartHeight = constraints.maxHeight;
                      final double maxBarHeight = chartHeight - 36.0; // Reserve for tooltip
                      final double barsAreaWidth = constraints.maxWidth - yAxisWidth;

                      return Stack(
                        children: [
                          // Grid Lines and Y-Axis
                          Positioned.fill(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                _buildGridRow(maxAmount, yAxisWidth, isDark),
                                _buildGridRow(maxAmount * 0.66, yAxisWidth, isDark),
                                _buildGridRow(maxAmount * 0.33, yAxisWidth, isDark),
                                _buildGridRow(0.0, yAxisWidth, isDark),
                              ],
                            ),
                          ),

                          // Bars Area
                          Positioned(
                            left: yAxisWidth,
                            right: 0,
                            top: 0,
                            bottom: 0,
                            child: points.isEmpty
                                ? Center(
                                    child: Text(
                                      'No return records for this period',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondary,
                                      ),
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: List.generate(points.length, (index) {
                                      final point = points[index];
                                      final isSelected = _selectedIndex == index;
                                      final double ratio = maxAmount > 0
                                          ? (point.amount / maxAmount).clamp(0.0, 1.0)
                                          : 0.0;
                                      final double barHeight = point.amount > 0
                                          ? max(8.0, ratio * maxBarHeight)
                                          : 4.0;
                                      final double barWidth = min(
                                        32.0,
                                        max(16.0, (barsAreaWidth / points.length) * 0.55),
                                      );

                                      return GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            _selectedIndex =
                                                _selectedIndex == index ? null : index;
                                          });
                                        },
                                        behavior: HitTestBehavior.opaque,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            // Tooltip bubble above selected bar
                                            SizedBox(
                                              height: 26,
                                              child: isSelected
                                                  ? AnimatedOpacity(
                                                      opacity: 1.0,
                                                      duration: const Duration(milliseconds: 150),
                                                      child: Container(
                                                        padding: const EdgeInsets.symmetric(
                                                          horizontal: 6,
                                                          vertical: 2,
                                                        ),
                                                        decoration: BoxDecoration(
                                                          color: AppColors.primaryDark,
                                                          borderRadius: BorderRadius.circular(6),
                                                          boxShadow: [
                                                            BoxShadow(
                                                              color: Colors.black
                                                                  .withValues(alpha: 0.15),
                                                              blurRadius: 4,
                                                              offset: const Offset(0, 2),
                                                            ),
                                                          ],
                                                        ),
                                                        child: Text(
                                                          CurrencyFormatter.format(point.amount),
                                                          style: GoogleFonts.poppins(
                                                            color: Colors.white,
                                                            fontSize: 9.5,
                                                            fontWeight: FontWeight.w700,
                                                          ),
                                                        ),
                                                      ),
                                                    )
                                                  : const SizedBox.shrink(),
                                            ),

                                            // Bar body
                                            AnimatedContainer(
                                              duration: const Duration(milliseconds: 250),
                                              width: barWidth,
                                              height: barHeight,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: isSelected
                                                      ? [AppColors.accent, AppColors.primaryDark]
                                                      : point.amount > 0
                                                          ? [
                                                              AppColors.primary,
                                                              AppColors.primaryLight,
                                                            ]
                                                          : [
                                                              isDark
                                                                  ? AppColors.borderDark
                                                                  : const Color(0xFFD4E6DC),
                                                              isDark
                                                                  ? AppColors.borderDark
                                                                  : const Color(0xFFE2EFE7),
                                                            ],
                                                  begin: Alignment.bottomCenter,
                                                  end: Alignment.topCenter,
                                                ),
                                                borderRadius: const BorderRadius.vertical(
                                                  top: Radius.circular(6),
                                                ),
                                                boxShadow: isSelected
                                                    ? [
                                                        BoxShadow(
                                                          color: AppColors.primary
                                                              .withValues(alpha: 0.35),
                                                          blurRadius: 8,
                                                          offset: const Offset(0, -2),
                                                        ),
                                                      ]
                                                    : null,
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 6),

                // 2. X-Axis Labels Row
                SizedBox(
                  height: 20,
                  child: Row(
                    children: [
                      const SizedBox(width: yAxisWidth),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: List.generate(points.length, (index) {
                            final point = points[index];
                            final isSelected = _selectedIndex == index;

                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedIndex =
                                        _selectedIndex == index ? null : index;
                                  });
                                },
                                child: Text(
                                  point.label,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: isSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSelected
                                        ? AppColors.primary
                                        : (isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondary),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridRow(double amount, double yAxisWidth, bool isDark) {
    return Row(
      children: [
        SizedBox(
          width: yAxisWidth,
          child: Text(
            amount == 0 ? '₹ 0' : CurrencyFormatter.formatCompact(amount),
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            height: 1,
            thickness: 0.8,
            color: isDark
                ? AppColors.borderDark.withValues(alpha: 0.5)
                : const Color(0xFFEFF4F1),
          ),
        ),
      ],
    );
  }

  double _calculateCeiling(double value) {
    if (value <= 1000) return 1000;
    if (value <= 5000) return 5000;
    if (value <= 10000) return 10000;
    if (value <= 25000) return 25000;
    if (value <= 50000) return 50000;
    if (value <= 100000) return 100000;
    final magnitude = pow(10, (log(value) / ln10).floor()).toDouble();
    return (value / magnitude).ceil() * magnitude;
  }
}
