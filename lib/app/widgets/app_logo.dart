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
      ..style = PaintingStyle.fill;

    final barWidth = size.width * 0.18;
    final r = Radius.circular(barWidth * 0.4);

    // Bar 1 (Short)
    final bar1Height = size.height * 0.38;
    final rrect1 = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.12, size.height - bar1Height, barWidth, bar1Height),
      r,
    );
    canvas.drawRRect(rrect1, paint);

    // Bar 2 (Medium)
    final bar2Height = size.height * 0.58;
    final rrect2 = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.40, size.height - bar2Height, barWidth, bar2Height),
      r,
    );
    canvas.drawRRect(rrect2, paint);

    // Bar 3 (Tall)
    final bar3Height = size.height * 0.80;
    final rrect3 = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.68, size.height - bar3Height, barWidth, bar3Height),
      r,
    );
    canvas.drawRRect(rrect3, paint);

    // Upward arrow over the 3rd bar
    final path = Path();
    final arrowTopX = size.width * 0.77;
    final arrowTopY = size.height * 0.05;
    path.moveTo(arrowTopX, arrowTopY);
    path.lineTo(arrowTopX - size.width * 0.12, arrowTopY + size.height * 0.12);
    path.lineTo(arrowTopX - size.width * 0.04, arrowTopY + size.height * 0.12);
    path.lineTo(arrowTopX - size.width * 0.04, arrowTopY + size.height * 0.18);
    path.lineTo(arrowTopX + size.width * 0.04, arrowTopY + size.height * 0.18);
    path.lineTo(arrowTopX + size.width * 0.04, arrowTopY + size.height * 0.12);
    path.lineTo(arrowTopX + size.width * 0.12, arrowTopY + size.height * 0.12);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _InvestProLogoPainter oldDelegate) =>
      oldDelegate.color != color;
}
