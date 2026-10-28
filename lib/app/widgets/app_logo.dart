import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class AppLogo extends StatelessWidget {
  final double size;
  final bool isWhite;
  final bool showText;
  final double fontSize;

  const AppLogo({
    super.key,
    this.size = 54,
    this.isWhite = false,
    this.showText = true,
    this.fontSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    final color = isWhite ? Colors.white : AppColors.primary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _InvestProLogoPainter(color: color),
          ),
        ),
        if (showText) ...[
          const SizedBox(height: 10),
          Text(
            'InvestPro',
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
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

  _InvestProLogoPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final barWidth = size.width * 0.19;
    final r = Radius.circular(barWidth * 0.5);
    final bottomY = size.height * 0.94;

    // Bar 1 (Short Rounded Capsule)
    final bar1Height = size.height * 0.38;
    final rrect1 = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.12, bottomY - bar1Height, barWidth, bar1Height),
      r,
    );
    canvas.drawRRect(rrect1, paint);

    // Bar 2 (Medium Rounded Capsule)
    final bar2Height = size.height * 0.56;
    final rrect2 = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.39, bottomY - bar2Height, barWidth, bar2Height),
      r,
    );
    canvas.drawRRect(rrect2, paint);

    // Bar 3 (Tall Rounded Capsule with Arrowhead)
    final path = Path();
    final apexX = size.width * 0.755;
    final apexY = size.height * 0.06;
    final wingY = size.height * 0.19;

    path.moveTo(apexX, apexY);
    path.lineTo(size.width * 0.625, wingY);
    path.lineTo(size.width * 0.66, wingY);
    path.lineTo(size.width * 0.66, bottomY - barWidth * 0.5);
    path.arcToPoint(
      Offset(size.width * 0.85, bottomY - barWidth * 0.5),
      radius: r,
      clockwise: false,
    );
    path.lineTo(size.width * 0.85, wingY);
    path.lineTo(size.width * 0.885, wingY);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _InvestProLogoPainter oldDelegate) =>
      oldDelegate.color != color;
}
