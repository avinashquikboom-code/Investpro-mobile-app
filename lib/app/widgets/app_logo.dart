import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool isWhite;
  final bool showText;
  final double fontSize;
  final double? spacing;

  const AppLogo({
    super.key,
    this.size = 54,
    this.isWhite = false,
    this.showText = true,
    this.fontSize = 24,
    this.spacing,
  });

  @override
  Widget build(BuildContext context) {
    final color = isWhite ? Colors.white : AppColors.primary;
    final effectiveSpacing = spacing ?? (size * 0.16).clamp(6.0, 16.0);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: 100,
              height: 100,
              child: CustomPaint(painter: _InvestProLogoPainter(color: color)),
            ),
          ),
        ),
        if (showText) ...[
          SizedBox(height: effectiveSpacing),
          Text(
            'InvestPro',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ],
    );
  }
}

class _InvestProLogoPainter extends CustomPainter {
  final Color color;

  const _InvestProLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.save();
    // Scale standard 100x100 logo coordinate space to actual canvas size
    canvas.scale(size.width / 100.0, size.height / 100.0);

    const cornerRadius = Radius.circular(9.5);

    // Bar 1 (Short Rounded Capsule) - X: 12..31, Y: 56..94
    final bar1 = RRect.fromRectAndRadius(
      const Rect.fromLTWH(12, 56, 19, 38),
      cornerRadius,
    );
    canvas.drawRRect(bar1, paint);

    // Bar 2 (Medium Rounded Capsule) - X: 39..58, Y: 38..94
    final bar2 = RRect.fromRectAndRadius(
      const Rect.fromLTWH(39, 38, 19, 56),
      cornerRadius,
    );
    canvas.drawRRect(bar2, paint);

    // Bar 3 Body (Tall Capsule with rounded bottom) - X: 66..85, Y: 19.5..94
    final bar3 = RRect.fromRectAndCorners(
      const Rect.fromLTWH(66, 19.5, 19, 74.5),
      bottomLeft: cornerRadius,
      bottomRight: cornerRadius,
    );
    canvas.drawRRect(bar3, paint);

    // Bar 3 Arrowhead on top - Apex: (75.5, 6), Left: (62.5, 20.5), Right: (88.5, 20.5)
    final arrow = Path()
      ..moveTo(75.5, 6)
      ..lineTo(62.5, 20.5)
      ..lineTo(88.5, 20.5)
      ..close();
    canvas.drawPath(arrow, paint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _InvestProLogoPainter oldDelegate) =>
      oldDelegate.color != color;
}
