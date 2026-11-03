import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';

import '../theme/app_colors.dart';
import '../utils/currency_formatter.dart';

/// Informational server schedule. Never calculates interest or posts a credit.
class NextHourlyPayoutCard extends StatefulWidget {
  final Map<String, dynamic>? payout;
  final bool hasError;
  final bool isLoading;
  final bool isActive;
  const NextHourlyPayoutCard({
    super.key,
    required this.payout,
    this.hasError = false,
    this.isLoading = false,
    this.isActive = true,
  });

  @override
  State<NextHourlyPayoutCard> createState() => _NextHourlyPayoutCardState();
}

class _NextHourlyPayoutCardState extends State<NextHourlyPayoutCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _intro;
  Timer? _expiry;
  bool _started = false;

  @override
  void initState() {
    super.initState();
    _intro =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 1400),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed && mounted) setState(() {});
        });
    _watchExpiry();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _startIntro();
  }

  void _startIntro() {
    if (!_started && widget.isActive) {
      _started = true;
      if (MediaQuery.disableAnimationsOf(context)) {
        _intro.value = 1;
      } else {
        _intro.forward();
      }
    }
  }

  @override
  void didUpdateWidget(covariant NextHourlyPayoutCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    _startIntro();
    if (oldWidget.payout?['dueDate'] != widget.payout?['dueDate']) {
      _watchExpiry();
    }
    // Rebuilds and refreshes never restart the entrance animation.
  }

  void _watchExpiry() {
    _expiry?.cancel();
    final due = DateTime.tryParse('${widget.payout?['dueDate']}');
    if (due != null && due.isAfter(DateTime.now())) {
      _expiry = Timer(due.difference(DateTime.now()), () {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _expiry?.cancel();
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final due = DateTime.tryParse('${widget.payout?['dueDate']}');
    final amount =
        widget.payout?['expectedAmount'] ?? widget.payout?['profitAmount'];
    final parsedAmount = num.tryParse('$amount');
    final invalid =
        widget.payout != null &&
        (due == null ||
            parsedAmount == null ||
            !parsedAmount.isFinite ||
            parsedAmount < 0);
    final calculating = !_intro.isCompleted || widget.isLoading;
    final error = widget.hasError || invalid;
    final upcoming = !error && due != null && due.isAfter(DateTime.now());
    final ink = dark ? AppColors.textPrimaryDark : AppColors.primaryDark;
    Widget content;
    if (calculating) {
      content = AnimatedBuilder(
        animation: _intro,
        builder: (context, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Calculating next payout...',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                final pulse =
                    (math.sin(_intro.value * math.pi * 4 - index * 1.2) + 1) /
                    2;
                return Container(
                  width: 7,
                  height: 7,
                  margin: const EdgeInsets.only(right: 7),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary.withValues(
                      alpha: .25 + .75 * pulse,
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      );
    } else if (error || !upcoming) {
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            error
                ? 'Payout details are temporarily unavailable'
                : due != null && !due.isAfter(DateTime.now())
                ? 'Awaiting wallet credit'
                : 'No upcoming hourly payout',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          if (error)
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Text(
                'Pull down to refresh',
                style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ),
        ],
      );
    } else {
      final local = due.toLocal();
      content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: Duration(milliseconds: reduceMotion ? 0 : 700),
            builder: (context, value, child) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 3),
              decoration: BoxDecoration(
                color: dark
                    ? AppColors.primary.withValues(alpha: .2)
                    : const Color(0xFFD3F6E0),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(
                      alpha: (1 - value) * .16,
                    ),
                    blurRadius: 14,
                  ),
                ],
              ),
              child: child,
            ),
            child: Semantics(
              label: 'Next payout amount',
              child: Text(
                CurrencyFormatter.format(amount),
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 9),
          _PayoutCountdown(due: due, isActive: widget.isActive),
          const SizedBox(height: 6),
          LayoutBuilder(
            builder: (context, constraints) => Wrap(
              spacing: 10,
              runSpacing: 5,
              children: [
                for (final item in [
                  (
                    Remix.calendar_line,
                    DateFormat('dd MMM yyyy').format(local),
                  ),
                  (Remix.time_line, DateFormat('hh:mm a').format(local)),
                ])
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: constraints.maxWidth),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(item.$1, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            item.$2,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: dark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          if (widget.payout?['projectName'] != null)
            Padding(
              padding: const EdgeInsets.only(top: 5),
              child: Text(
                '${widget.payout!['projectName']}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
        ],
      );
    }
    return Semantics(
      container: true,
      child: Container(
        key: const ValueKey('home-next-hourly-payout'),
        width: double.infinity,
        margin: const EdgeInsets.only(top: 16, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: dark
                ? [AppColors.surfaceDark, const Color(0xFF152E23)]
                : [const Color(0xFFF8FDF9), const Color(0xFFEBFAF0)],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withValues(alpha: .2)),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: dark ? .04 : .06),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final clockSize = constraints.maxWidth < 290 ? 46.0 : 58.0;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AnimatedBuilder(
                  animation: _intro,
                  builder: (context, _) {
                    final pulse = calculating
                        ? math.sin(_intro.value * math.pi * 2).abs()
                        : 0.0;
                    return Container(
                      width: clockSize,
                      height: clockSize,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: .06),
                            AppColors.primary.withValues(alpha: .11),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(
                              alpha: pulse * .16,
                            ),
                            blurRadius: 12,
                            spreadRadius: pulse * 2,
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          if (calculating)
                            Transform.rotate(
                              angle: _intro.value * math.pi * 2,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  SizedBox(
                                    width: clockSize - 4,
                                    height: clockSize - 4,
                                    child: CircularProgressIndicator(
                                      value: .72,
                                      strokeWidth: 3,
                                      strokeCap: StrokeCap.round,
                                      color: AppColors.primary,
                                      backgroundColor: AppColors.primary
                                          .withValues(alpha: .06),
                                    ),
                                  ),
                                  Positioned(
                                    top: 0,
                                    child: Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF40DD80),
                                        boxShadow: [
                                          BoxShadow(
                                            color: AppColors.primary.withValues(
                                              alpha: .25,
                                            ),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          _PayoutClockHands(
                            size: calculating
                                ? clockSize * .48
                                : clockSize * .6,
                            isActive:
                                widget.isActive && (calculating || upcoming),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.only(left: 14),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(
                          color: AppColors.primary.withValues(alpha: .17),
                        ),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Next Hourly Payout',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: ink,
                          ),
                        ),
                        const SizedBox(height: 10),
                        AnimatedSwitcher(
                          duration: Duration(
                            milliseconds: reduceMotion ? 0 : 400,
                          ),
                          layoutBuilder: (current, previous) => Stack(
                            alignment: Alignment.centerLeft,
                            children: [...previous, ?current],
                          ),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position:
                                      Tween<Offset>(
                                        begin: const Offset(0, .12),
                                        end: Offset.zero,
                                      ).animate(
                                        CurvedAnimation(
                                          parent: animation,
                                          curve: Curves.easeOutCubic,
                                        ),
                                      ),
                                  child: child,
                                ),
                              ),
                          child: KeyedSubtree(
                            key: ValueKey(
                              calculating
                                  ? 'calculating'
                                  : error
                                  ? 'error'
                                  : upcoming
                                  ? 'details'
                                  : 'empty',
                            ),
                            child: content,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A one-second hand tick with a short easing window; no permanent frame ticker.
class _PayoutClockHands extends StatefulWidget {
  final double size;
  final bool isActive;
  const _PayoutClockHands({required this.size, required this.isActive});
  @override
  State<_PayoutClockHands> createState() => _PayoutClockHandsState();
}

class _PayoutClockHandsState extends State<_PayoutClockHands>
    with WidgetsBindingObserver {
  Timer? _tick;
  double _turns = 0;
  bool _foreground = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateTick();
  }

  @override
  void didUpdateWidget(covariant _PayoutClockHands oldWidget) {
    super.didUpdateWidget(oldWidget);
    _updateTick();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _updateTick();
  }

  void _updateTick() {
    final animate =
        widget.isActive &&
        _foreground &&
        !MediaQuery.disableAnimationsOf(context);
    if (!animate) {
      _tick?.cancel();
      _tick = null;
    } else {
      _tick ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _turns += 1 / 60);
      });
    }
  }

  @override
  void dispose() {
    _tick?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: TweenAnimationBuilder<double>(
      key: const ValueKey('payout-clock-hand-motion'),
      tween: Tween(begin: 0, end: _turns),
      duration: Duration(
        milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 450,
      ),
      curve: Curves.easeInOut,
      builder: (context, turns, _) => CustomPaint(
        size: Size.square(widget.size),
        painter: _PayoutClockPainter(turns),
      ),
    ),
  );
}

class _PayoutClockPainter extends CustomPainter {
  final double turns;
  _PayoutClockPainter(this.turns);
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * .43;
    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.shortestSide * .085
      ..strokeCap = StrokeCap.round;
    canvas.drawCircle(center, radius, paint);
    void hand(double angle, double length) => canvas.drawLine(
      center,
      center + Offset(math.cos(angle), math.sin(angle)) * radius * length,
      paint,
    );
    hand(-math.pi / 2 + turns * math.pi * 2, .63);
    hand(turns * math.pi * 2 / 12, .46);
    canvas.drawCircle(
      center,
      size.shortestSide * .045,
      Paint()..color = AppColors.primary,
    );
  }

  @override
  bool shouldRepaint(covariant _PayoutClockPainter oldDelegate) =>
      oldDelegate.turns != turns;
}

/// Display-only wall-clock countdown. Reaching zero does not confirm settlement.
class _PayoutCountdown extends StatefulWidget {
  final DateTime due;
  final bool isActive;
  const _PayoutCountdown({required this.due, required this.isActive});
  @override
  State<_PayoutCountdown> createState() => _PayoutCountdownState();
}

class _PayoutCountdownState extends State<_PayoutCountdown>
    with WidgetsBindingObserver {
  Timer? _timer;
  bool _foreground = true;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _updateTimer();
  }

  void _updateTimer() {
    _timer?.cancel();
    if (widget.isActive && _foreground && widget.due.isAfter(DateTime.now())) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() {});
        if (!widget.due.isAfter(DateTime.now())) _timer?.cancel();
      });
    }
  }

  @override
  void didUpdateWidget(covariant _PayoutCountdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.due != widget.due || oldWidget.isActive != widget.isActive) {
      _updateTimer();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _updateTimer();
    if (_foreground && mounted) setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final remaining =
        (widget.due.difference(DateTime.now()).inMilliseconds / 1000).ceil();
    final seconds = math.max(0, remaining);
    final value =
        '${(seconds ~/ 3600).toString().padLeft(2, '0')}:${(seconds ~/ 60 % 60).toString().padLeft(2, '0')}:${(seconds % 60).toString().padLeft(2, '0')}';
    return Text(
      seconds == 0 ? 'Awaiting wallet credit' : 'Time until payout · $value',
      key: const ValueKey('payout-time-remaining'),
      style: const TextStyle(
        fontSize: 11,
        color: AppColors.primary,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
