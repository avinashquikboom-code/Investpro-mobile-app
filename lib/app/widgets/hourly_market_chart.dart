import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../controllers/returns_controller.dart';
import '../theme/app_colors.dart';
import '../utils/currency_formatter.dart';

/// Interactive market-style chart for the actual hourly wallet-credit buckets.
class HourlyMarketChart extends StatefulWidget {
  final List<ReturnChartPoint> points;
  final bool isDark;

  const HourlyMarketChart({
    super.key,
    required this.points,
    required this.isDark,
  });

  @override
  State<HourlyMarketChart> createState() => _HourlyMarketChartState();
}

class _HourlyMarketChartState extends State<HourlyMarketChart>
    with SingleTickerProviderStateMixin {
  static const _ranges = <(String, int)>[
    ('1H', 1),
    ('6H', 6),
    ('12H', 12),
    ('24H', 24),
  ];

  late final AnimationController _draw = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 850),
  )..forward();
  int? _selectedIndex;
  int _rangeHours = 24;

  @override
  void initState() {
    super.initState();
    if (widget.points.length < _rangeHours && widget.points.isNotEmpty) {
      _rangeHours = _bestRange(widget.points.length);
    }
  }

  int _bestRange(int count) {
    for (final range in _ranges.reversed) {
      if (range.$2 <= count) return range.$2;
    }
    return 24;
  }

  List<ReturnChartPoint> get _orderedPoints {
    final result =
        widget.points.where((point) => point.amount.isFinite).toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    return result;
  }

  List<ReturnChartPoint> get _visiblePoints {
    final points = _orderedPoints;
    final count = math.min(_rangeHours, points.length);
    return count == 0 ? const [] : points.sublist(points.length - count);
  }

  @override
  void didUpdateWidget(covariant HourlyMarketChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldPoints = oldWidget.points;
    final newPoints = widget.points;
    final changed =
        oldPoints.length != newPoints.length ||
        List.generate(
          math.min(oldPoints.length, newPoints.length),
          (index) =>
              oldPoints[index].date != newPoints[index].date ||
              oldPoints[index].amount != newPoints[index].amount,
        ).any((value) => value);
    if (changed) {
      _selectedIndex = null;
      _draw.forward(from: 0);
    }
    if (widget.points.length < _rangeHours && widget.points.isNotEmpty) {
      _rangeHours = _bestRange(widget.points.length);
    }
  }

  @override
  void dispose() {
    _draw.dispose();
    super.dispose();
  }

  void _selectAt(Offset localPosition, Size size) {
    final points = _visiblePoints;
    if (points.isEmpty) return;
    const left = _HourlyChartPainter.leftInset;
    const right = _HourlyChartPainter.rightInset;
    final plotWidth = math.max(1.0, size.width - left - right);
    final progress = ((localPosition.dx - left) / plotWidth).clamp(0.0, 1.0);
    final index = points.length == 1
        ? 0
        : (progress * (points.length - 1)).round();
    if (_selectedIndex != index) setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final points = _visiblePoints;
    final dark = widget.isDark;
    final ink = dark ? AppColors.textPrimaryDark : AppColors.textPrimary;
    final muted = dark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    final chartSurface = dark
        ? AppColors.surfaceDarkElevated
        : const Color(0xFFF6FBF8);
    final total = points.fold<double>(0, (sum, point) => sum + point.amount);
    final latest = points.isEmpty ? null : points.last;
    final peak = points.isEmpty
        ? null
        : points.reduce((a, b) => a.amount >= b.amount ? a : b);
    final selected = _selectedIndex != null && _selectedIndex! < points.length
        ? points[_selectedIndex!]
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Completed wallet credits · actual amounts',
                style: TextStyle(color: muted, fontSize: 11),
              ),
            ),
            if (points.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: dark
                      ? const Color(0xFF18382B)
                      : const Color(0xFFE5F7EC),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.circle, size: 6, color: AppColors.accent),
                    const SizedBox(width: 5),
                    Text(
                      '${points.length} hours',
                      style: TextStyle(
                        color: ink,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        if (points.isNotEmpty) ...[
          const SizedBox(height: 14),
          Row(
            children: [
              _Metric(
                key: const ValueKey('hourly-period-total'),
                label: 'Period total',
                value: CurrencyFormatter.format(total),
                ink: ink,
                muted: muted,
              ),
              _Metric(
                label: 'Latest hour',
                value: CurrencyFormatter.format(latest!.amount),
                ink: ink,
                muted: muted,
              ),
              _Metric(
                label: 'Peak hour',
                value: CurrencyFormatter.format(peak!.amount),
                ink: ink,
                muted: muted,
                trailing: peak.label,
              ),
            ],
          ),
          const SizedBox(height: 14),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final (label, hours) in _ranges)
                  if (widget.points.length >= hours)
                    Padding(
                      padding: const EdgeInsets.only(right: 7),
                      child: _RangeChip(
                        key: ValueKey('hour-range-$label'),
                        label: label,
                        selected: _rangeHours == hours,
                        isDark: dark,
                        onTap: () => setState(() {
                          _rangeHours = hours;
                          _selectedIndex = null;
                          _draw.forward(from: 0);
                        }),
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final size = Size(constraints.maxWidth, 218);
              final selectedX = selected == null || points.length < 2
                  ? constraints.maxWidth / 2
                  : _HourlyChartPainter.leftInset +
                        (_selectedIndex! / (points.length - 1)) *
                            (constraints.maxWidth -
                                _HourlyChartPainter.leftInset -
                                _HourlyChartPainter.rightInset);
              final tooltipWidth = math.min(constraints.maxWidth, 190.0);
              return Container(
                height: size.height,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: chartSurface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: dark
                        ? AppColors.borderDark
                        : const Color(0xFFE5F0E9),
                  ),
                ),
                child: Stack(
                  children: [
                    GestureDetector(
                      key: const ValueKey('hourly-market-chart-interaction'),
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (details) =>
                          _selectAt(details.localPosition, size),
                      onPanStart: (details) =>
                          _selectAt(details.localPosition, size),
                      onPanUpdate: (details) =>
                          _selectAt(details.localPosition, size),
                      child: AnimatedBuilder(
                        animation: _draw,
                        builder: (context, _) => CustomPaint(
                          size: size,
                          painter: _HourlyChartPainter(
                            points: points,
                            selectedIndex: _selectedIndex,
                            animation: _draw.value,
                            isDark: dark,
                            muted: muted,
                          ),
                        ),
                      ),
                    ),
                    if (selected != null)
                      Positioned(
                        top: 1,
                        left: (selectedX - tooltipWidth / 2).clamp(
                          0.0,
                          math.max(0.0, constraints.maxWidth - tooltipWidth),
                        ),
                        width: tooltipWidth,
                        child: IgnorePointer(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            child: Container(
                              key: const ValueKey('return-chart-tooltip'),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: dark
                                    ? const Color(0xFF15392B)
                                    : AppColors.primaryDark,
                                borderRadius: BorderRadius.circular(9),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: .2,
                                    ),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: Text(
                                '${selected.label} · ${CurrencyFormatter.format(selected.amount)}',
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
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
              );
            },
          ),
        ] else
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No hourly wallet credits available for this date',
                textAlign: TextAlign.center,
                style: TextStyle(color: muted, fontSize: 12),
              ),
            ),
          ),
        if (selected != null) ...[
          const SizedBox(height: 2),
          Text(
            'Selected hour: ${selected.label}  ·  ${CurrencyFormatter.format(selected.amount)}',
            key: const ValueKey('hourly-selected-value'),
            style: TextStyle(
              color: ink,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color ink;
  final Color muted;
  final String? trailing;

  const _Metric({
    super.key,
    required this.label,
    required this.value,
    required this.ink,
    required this.muted,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: muted, fontSize: 9.5),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: ink,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (trailing != null)
            Text(
              trailing!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: muted, fontSize: 9),
            ),
        ],
      ),
    ),
  );
}

class _RangeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  const _RangeChip({
    super.key,
    required this.label,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary
            : (isDark
                  ? AppColors.surfaceDarkElevated
                  : const Color(0xFFF3F7F5)),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: selected
              ? AppColors.primary
              : (isDark ? AppColors.borderDark : const Color(0xFFE0EAE4)),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected
              ? Colors.white
              : (isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
  );
}

class _HourlyChartPainter extends CustomPainter {
  static const leftInset = 62.0;
  static const rightInset = 8.0;

  final List<ReturnChartPoint> points;
  final int? selectedIndex;
  final double animation;
  final bool isDark;
  final Color muted;

  const _HourlyChartPainter({
    required this.points,
    required this.selectedIndex,
    required this.animation,
    required this.isDark,
    required this.muted,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    const top = 42.0;
    const bottom = 27.0;
    final plot = Rect.fromLTRB(
      leftInset,
      top,
      size.width - rightInset,
      size.height - bottom,
    );
    if (plot.width <= 0 || plot.height <= 0) return;
    final maxAmount = points.fold<double>(
      0,
      (value, point) => math.max(value, point.amount),
    );
    final ceiling = maxAmount > 0 ? maxAmount * 1.15 : 1.0;
    final positions = <Offset>[
      for (var i = 0; i < points.length; i++)
        Offset(
          points.length == 1
              ? plot.center.dx
              : plot.left + i * plot.width / (points.length - 1),
          plot.bottom - (points[i].amount / ceiling * plot.height),
        ),
    ];
    final gridColor = isDark ? AppColors.borderDark : const Color(0xFFE3ECE7);
    final grid = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    final labelStyle = TextStyle(color: muted, fontSize: 8.5);
    for (var line = 0; line < 4; line++) {
      final y = plot.top + line * plot.height / 3;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
      final amount = maxAmount > 0 ? ceiling * (1 - line / 3) : 0.0;
      _drawLabel(
        canvas,
        CurrencyFormatter.format(amount),
        Offset(0, y - 6),
        56,
        labelStyle,
        TextAlign.right,
      );
    }

    final linePath = _smoothPath(positions);
    final area = Path.from(linePath)
      ..lineTo(positions.last.dx, plot.bottom)
      ..lineTo(positions.first.dx, plot.bottom)
      ..close();
    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          AppColors.accent.withValues(alpha: .32 * animation),
          AppColors.primary.withValues(alpha: .02 * animation),
        ],
      ).createShader(plot);
    canvas.drawPath(area, areaPaint);

    final metrics = linePath.computeMetrics().toList();
    final metric = metrics.isEmpty ? null : metrics.first;
    if (metric != null) {
      final revealed = metric.extractPath(0, metric.length * animation);
      canvas.drawPath(
        revealed,
        Paint()
          ..color = const Color(0xFF20B978)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.7
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round,
      );
    }

    _drawPoint(
      canvas,
      positions.last,
      selected: false,
      pulse: 1.4 * math.sin(math.pi * animation),
    );
    if (selectedIndex != null && selectedIndex! < positions.length) {
      final selected = positions[selectedIndex!];
      final crosshair = Paint()
        ..color = AppColors.accent.withValues(alpha: .48)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      _drawDashedLine(
        canvas,
        Offset(selected.dx, plot.top),
        Offset(selected.dx, plot.bottom),
        crosshair,
      );
      _drawPoint(canvas, selected, selected: true);
    }

    final labelIndices =
        points.length == 1
              ? <int>[0]
              : <int>{0, points.length ~/ 2, points.length - 1}.toList()
          ..sort();
    for (final index in labelIndices) {
      final label = points[index].label;
      final x = positions[index].dx;
      _drawLabel(
        canvas,
        label,
        Offset(x - 35, plot.bottom + 8),
        70,
        labelStyle,
        TextAlign.center,
      );
    }
  }

  Path _smoothPath(List<Offset> points) {
    final path = Path()..moveTo(points.first.dx, points.first.dy);
    if (points.length == 1) {
      path.lineTo(points.first.dx + .1, points.first.dy);
      return path;
    }
    for (var i = 0; i < points.length - 1; i++) {
      final current = points[i];
      final next = points[i + 1];
      final midpoint = Offset(
        (current.dx + next.dx) / 2,
        (current.dy + next.dy) / 2,
      );
      path.quadraticBezierTo(current.dx, current.dy, midpoint.dx, midpoint.dy);
      if (i == points.length - 2) {
        path.quadraticBezierTo(next.dx, next.dy, next.dx, next.dy);
      }
    }
    return path;
  }

  void _drawPoint(
    Canvas canvas,
    Offset point, {
    required bool selected,
    double pulse = 0,
  }) {
    canvas.drawCircle(
      point,
      selected ? 9 : 11 + pulse,
      Paint()..color = AppColors.accent.withValues(alpha: selected ? .22 : .13),
    );
    canvas.drawCircle(
      point,
      selected ? 4.5 : 4,
      Paint()..color = const Color(0xFF20B978),
    );
    canvas.drawCircle(point, selected ? 2 : 1.7, Paint()..color = Colors.white);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dash = 4.0;
    const gap = 4.0;
    var y = start.dy;
    while (y < end.dy) {
      canvas.drawLine(
        Offset(start.dx, y),
        Offset(start.dx, math.min(y + dash, end.dy)),
        paint,
      );
      y += dash + gap;
    }
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset offset,
    double width,
    TextStyle style,
    TextAlign align,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: align,
      maxLines: 1,
      ellipsis: '…',
    )..layout(maxWidth: width);
    painter.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _HourlyChartPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.selectedIndex != selectedIndex ||
      oldDelegate.animation != animation ||
      oldDelegate.isDark != isDark;
}
