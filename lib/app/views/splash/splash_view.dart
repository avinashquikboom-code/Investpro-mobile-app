import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../routes/app_routes.dart';
import '../../services/local_storage_service.dart';
import '../../widgets/app_logo.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();
    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;

    final storage = Get.find<LocalStorageService>();
    final authCtrl = Get.find<AuthController>();

    if (storage.isLoggedIn || authCtrl.isLoggedIn.value) {
      Get.offAllNamed(AppRoutes.home);
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient matching screenshot
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF024626),
                  Color(0xFF01361D),
                  Color(0xFF002413),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Sprouting Plant & Layered Hills at the bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: screenSize.height * 0.38,
            child: CustomPaint(
              painter: _SplashPlantLandscapePainter(),
            ),
          ),

          // Upper-Center Branding matching screenshot
          Positioned(
            top: topPadding + screenSize.height * 0.16,
            left: 24,
            right: 24,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Properly fitting InvestPro logo
                    const AppLogo(
                      size: 86,
                      isWhite: true,
                      showText: false,
                    ),
                    const SizedBox(height: 18),

                    // App Title
                    const Text(
                      'InvestPro',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tagline
                    Text(
                      'Grow Your Wealth\nWith Trusted Investments',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.90),
                        fontSize: 16,
                        fontWeight: FontWeight.w400,
                        height: 1.45,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashPlantLandscapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // --- Soft ambient glow behind plant ---
    final glowPaint = Paint()
      ..color = const Color(0xFF35C76F).withValues(alpha: 0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 36);
    canvas.drawCircle(Offset(w * 0.50, h * 0.45), 65, glowPaint);

    // --- Layer 1: Back Deep Hill Wave ---
    final hillPaint1 = Paint()
      ..color = const Color(0xFF0C5D33).withValues(alpha: 0.45)
      ..style = PaintingStyle.fill;
    final hill1 = Path()
      ..moveTo(0, h * 0.60)
      ..quadraticBezierTo(w * 0.28, h * 0.48, w * 0.65, h * 0.68)
      ..quadraticBezierTo(w * 0.85, h * 0.78, w, h * 0.65)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(hill1, hillPaint1);

    // --- Layer 2: Middle Vibrant Wave ---
    final hillPaint2 = Paint()
      ..color = const Color(0xFF138549).withValues(alpha: 0.55)
      ..style = PaintingStyle.fill;
    final hill2 = Path()
      ..moveTo(0, h * 0.76)
      ..quadraticBezierTo(w * 0.35, h * 0.60, w * 0.72, h * 0.70)
      ..quadraticBezierTo(w * 0.88, h * 0.75, w, h * 0.72)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(hill2, hillPaint2);

    // --- Layer 3: Central Sprout Plant ---
    // Curved Central Stem
    final stemPaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;

    final stem = Path()
      ..moveTo(w * 0.48, h * 0.85)
      ..quadraticBezierTo(w * 0.47, h * 0.50, w * 0.50, h * 0.28);
    canvas.drawPath(stem, stemPaint);

    // Top Right Leaf (Main vibrant lime leaf)
    final leafTopPaint = Paint()
      ..color = const Color(0xFF76C860)
      ..style = PaintingStyle.fill;
    final leafTop = Path()
      ..moveTo(w * 0.495, h * 0.34)
      ..cubicTo(
        w * 0.48, h * 0.22,
        w * 0.58, h * 0.12,
        w * 0.64, h * 0.13,
      )
      ..cubicTo(
        w * 0.65, h * 0.22,
        w * 0.56, h * 0.32,
        w * 0.505, h * 0.27,
      )
      ..close();
    canvas.drawPath(leafTop, leafTopPaint);

    // Leaf top highlight / vein
    final leafTopVein = Paint()
      ..color = const Color(0xFF98E87F).withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawLine(Offset(w * 0.51, h * 0.31), Offset(w * 0.62, h * 0.15), leafTopVein);

    // Left Arched Leaf
    final leafLeftPaint = Paint()
      ..color = const Color(0xFF5AB75C)
      ..style = PaintingStyle.fill;
    final leafLeft = Path()
      ..moveTo(w * 0.48, h * 0.50)
      ..cubicTo(
        w * 0.40, h * 0.48,
        w * 0.33, h * 0.36,
        w * 0.35, h * 0.30,
      )
      ..cubicTo(
        w * 0.41, h * 0.33,
        w * 0.46, h * 0.40,
        w * 0.48, h * 0.44,
      )
      ..close();
    canvas.drawPath(leafLeft, leafLeftPaint);

    // Right Lower Leaf
    final leafRightPaint = Paint()
      ..color = const Color(0xFF45A54B)
      ..style = PaintingStyle.fill;
    final leafRight = Path()
      ..moveTo(w * 0.49, h * 0.60)
      ..cubicTo(
        w * 0.55, h * 0.56,
        w * 0.63, h * 0.48,
        w * 0.62, h * 0.43,
      )
      ..cubicTo(
        w * 0.57, h * 0.47,
        w * 0.52, h * 0.51,
        w * 0.49, h * 0.54,
      )
      ..close();
    canvas.drawPath(leafRight, leafRightPaint);

    // --- Layer 4: Foreground Mound over stem base ---
    final hillPaint3 = Paint()
      ..color = const Color(0xFF1E9B56).withValues(alpha: 0.70)
      ..style = PaintingStyle.fill;
    final hill3 = Path()
      ..moveTo(0, h * 0.88)
      ..quadraticBezierTo(w * 0.45, h * 0.80, w, h * 0.86)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(hill3, hillPaint3);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
