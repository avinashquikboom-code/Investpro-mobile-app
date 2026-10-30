import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';

/// An animated notification bell icon that chimes and pulses
/// when unread notifications are available.
class AnimatedNotificationBell extends StatefulWidget {
  final bool hasNotification;
  final int unreadCount;
  final VoidCallback? onTap;
  final Color color;
  final double size;
  final Color badgeColor;
  final double badgeSize;
  final Color? badgeBorderColor;
  final Color? backgroundColor;
  final double? containerSize;
  final double? badgeTop;
  final double? badgeRight;
  final String? tooltip;
  final IconData icon;

  const AnimatedNotificationBell({
    super.key,
    required this.hasNotification,
    this.unreadCount = 0,
    this.onTap,
    this.color = Colors.white,
    this.size = 22.0,
    this.badgeColor = const Color(0xFFE53935),
    this.badgeSize = 8.0,
    this.badgeBorderColor,
    this.backgroundColor,
    this.containerSize,
    this.badgeTop,
    this.badgeRight,
    this.tooltip,
    this.icon = Remix.notification_line,
  });

  @override
  State<AnimatedNotificationBell> createState() => _AnimatedNotificationBellState();
}

class _AnimatedNotificationBellState extends State<AnimatedNotificationBell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _rotationAnimation;
  late final Animation<double> _badgeScaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // Natural bell swing sequence followed by rest period
    _rotationAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: -0.22)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 4,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.22, end: 0.22)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 6,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.22, end: -0.16)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 6,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.16, end: 0.16)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 6,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.16, end: -0.08)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 5,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: -0.08, end: 0.08)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 5,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.08, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 4,
      ),
      // Rest period
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: 65,
      ),
    ]).animate(_controller);

    // Badge scale pulse synced with bell chime
    _badgeScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.35)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.35, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 16,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 69,
      ),
    ]).animate(_controller);

    if (widget.hasNotification) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant AnimatedNotificationBell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.hasNotification != oldWidget.hasNotification) {
      if (widget.hasNotification) {
        if (!_controller.isAnimating) {
          _controller.repeat();
        }
      } else {
        if (_controller.isAnimating) {
          _controller.reset();
          _controller.stop();
        }
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
    const double defaultBadgeTop = -2.0;
    const double defaultBadgeRight = -2.0;

    final double effectiveTop = widget.badgeTop ?? defaultBadgeTop;
    final double effectiveRight = widget.badgeRight ?? defaultBadgeRight;

    Widget content = AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final bellIcon = Transform.rotate(
          angle: widget.hasNotification ? _rotationAnimation.value : 0.0,
          alignment: Alignment.topCenter,
          child: Icon(
            widget.icon,
            color: widget.color,
            size: widget.size,
          ),
        );

        final badge = widget.hasNotification
            ? Positioned(
                top: effectiveTop,
                right: effectiveRight,
                child: Transform.scale(
                  scale: _badgeScaleAnimation.value,
                  child: Container(
                    width: widget.badgeSize,
                    height: widget.badgeSize,
                    decoration: BoxDecoration(
                      color: widget.badgeColor,
                      shape: BoxShape.circle,
                      border: widget.badgeBorderColor != null
                          ? Border.all(color: widget.badgeBorderColor!, width: 1.5)
                          : null,
                    ),
                  ),
                ),
              )
            : null;

        final bellWithBadge = SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              bellIcon,
              ?badge,
            ],
          ),
        );

        if (widget.containerSize != null) {
          return Container(
            width: widget.containerSize,
            height: widget.containerSize,
            decoration: BoxDecoration(
              color: widget.backgroundColor,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: bellWithBadge,
          );
        }

        return bellWithBadge;
      },
    );

    Widget clickable = GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: content,
    );

    if (widget.tooltip != null && widget.tooltip!.isNotEmpty) {
      clickable = Tooltip(
        message: widget.tooltip!,
        child: clickable,
      );
    }

    return clickable;
  }
}

