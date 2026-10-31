import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/returns_controller.dart';
import '../theme/app_colors.dart';
import '../utils/currency_formatter.dart';

/// Scrolls dense periods instead of squeezing labels or losing reporting buckets.
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
  int? selected;
  @override
  void didUpdateWidget(covariant ReturnsBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.period != widget.period ||
        oldWidget.points.length != widget.points.length ||
        (selected != null &&
            oldWidget.points[selected!].date !=
                widget.points[selected!].date)) {
      selected = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = widget.isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimary;
    final muted = widget.isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondary;
    final points = widget.points;
    final maximum = points.fold<double>(
      0,
      (a, p) => math.max(a, p.amount.isFinite ? p.amount : 0),
    );
    final scale = maximum > 0 ? maximum * 1.12 : 1.0;
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: widget.isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: widget.isDark ? AppColors.borderDark : const Color(0xFFE8F0EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .035),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Returns Analytics',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: text,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${widget.period} breakdown',
            style: TextStyle(fontSize: 12, color: muted),
          ),
          const SizedBox(height: 12),
          if (points.isEmpty || maximum == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No returns for this period',
                style: TextStyle(color: muted),
              ),
            ),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = math.max(
                constraints.maxWidth,
                points.length * 60.0 * math.min(textScale, 1.5),
              );
              final slot = points.isEmpty ? width : width / points.length;
              const plotHeight = 145.0;
              final tooltipHeight = 44.0 * textScale;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: width,
                  child: Column(
                    children: [
                      SizedBox(
                        height: plotHeight + tooltipHeight,
                        child: Stack(
                          children: [
                            for (var i = 0; i < 4; i++)
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: i * plotHeight / 3,
                                child: Divider(
                                  height: 1,
                                  color: widget.isDark
                                      ? AppColors.borderDark
                                      : const Color(0xFFEDF3EF),
                                ),
                              ),
                            for (var i = 0; i < points.length; i++)
                              Positioned(
                                left: i * slot,
                                width: slot,
                                bottom: 0,
                                height: plotHeight,
                                child: Semantics(
                                  button: true,
                                  selected: selected == i,
                                  label:
                                      '${points[i].label}, ${CurrencyFormatter.format(points[i].amount, showDecimals: true)}',
                                  child: InkWell(
                                    key: ValueKey('return-bar-$i'),
                                    onTap: () => setState(
                                      () => selected = selected == i ? null : i,
                                    ),
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: AnimatedContainer(
                                        duration: const Duration(
                                          milliseconds: 180,
                                        ),
                                        width: math.min(30, slot * .48),
                                        height: points[i].amount > 0
                                            ? math.max(
                                                3,
                                                points[i].amount /
                                                    scale *
                                                    plotHeight,
                                              )
                                            : 0,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.bottomCenter,
                                            end: Alignment.topCenter,
                                            colors: selected == i
                                                ? [
                                                    AppColors.primaryDark,
                                                    AppColors.accent,
                                                  ]
                                                : [
                                                    AppColors.primary,
                                                    const Color(0xFF8CE3AD),
                                                  ],
                                          ),
                                          borderRadius:
                                              const BorderRadius.vertical(
                                                top: Radius.circular(7),
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            if (selected != null)
                              Positioned(
                                top: 0,
                                left:
                                    ((selected! + .5) * slot -
                                            math.min(width, 210 * textScale) /
                                                2)
                                        .clamp(
                                          0,
                                          math.max(
                                            0,
                                            width -
                                                math.min(
                                                  width,
                                                  210 * textScale,
                                                ),
                                          ),
                                        ),
                                width: math.min(width, 210 * textScale),
                                child: IgnorePointer(
                                  child: Center(
                                    child: Container(
                                      key: const ValueKey(
                                        'return-chart-tooltip',
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryDark,
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                      child: Text(
                                        '${points[selected!].label} · ${CurrencyFormatter.format(points[selected!].amount, showDecimals: true)}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          for (var i = 0; i < points.length; i++)
                            SizedBox(
                              width: slot,
                              child: Text(
                                points[i].label,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: selected == i
                                      ? AppColors.primary
                                      : muted,
                                  fontWeight: selected == i
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
