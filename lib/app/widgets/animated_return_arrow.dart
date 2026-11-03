import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

import '../theme/app_colors.dart';

/// A reusable animated widget that renders a floating upward arrow (↑)
/// for Return Payout transactions.
///
/// Features:
/// - Smooth continuous vertical floating animation (4-6px distance, ease-in-out).
/// - Duration between 900-1200ms with reverse repeat.
/// - Centered inside circular container.
/// - Respects reduced-motion accessibility settings.
/// - Avoids blocking `tester.pumpAndSettle` in automated test environments unless [animateInTest] is true.
class AnimatedReturnArrow extends StatefulWidget {
  final Color color;
  final double size;
  final IconData icon;
  final double distance;
  final Duration duration;
  final bool animateInTest;

  const AnimatedReturnArrow({
    super.key,
    this.color = AppColors.success,
    this.size = 20.0,
    this.icon = Remix.arrow_up_line,
    this.distance = 5.0,
    this.duration = const Duration(milliseconds: 1050),
    this.animateInTest = false,
  });

  @override
  State<AnimatedReturnArrow> createState() => _AnimatedReturnArrowState();
}

class _AnimatedReturnArrowState extends State<AnimatedReturnArrow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _animation = Tween<double>(
      begin: widget.distance / 2,
      end: -widget.distance / 2,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    final isTesting = WidgetsBinding.instance is! WidgetsFlutterBinding;
    if (!isTesting || widget.animateInTest) {
      _controller.repeat(reverse: true);
    } else {
      _controller.value = 0.5;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final isTesting = WidgetsBinding.instance is! WidgetsFlutterBinding;

    if (reduceMotion || (isTesting && !widget.animateInTest)) {
      if (_controller.isAnimating) {
        _controller.stop();
        _controller.value = 0.5;
      }
    } else {
      if (!_controller.isAnimating) {
        _controller.repeat(reverse: true);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _animation.value),
            child: child,
          );
        },
        child: Icon(
          widget.icon,
          color: widget.color,
          size: widget.size,
        ),
      ),
    );
  }
}
