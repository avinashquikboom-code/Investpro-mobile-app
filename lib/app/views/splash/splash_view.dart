import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../routes/app_routes.dart';
import '../../services/local_storage_service.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
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

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    _scaleAnimation = Tween<double>(
      begin: 0.90,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));

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
          // Background Gradient matching exact reference screenshot
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF005C36),
                  Color(0xFF004828),
                  Color(0xFF002E19),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Sprouting Plant & Layered Rolling Hills at the bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: screenSize.height * 0.44,
            child: Image.asset(
              'assets/images/splash_plant_hills.png',
              fit: BoxFit.cover,
              alignment: Alignment.bottomCenter,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) {
                // Graceful fallback painter if asset is unavailable
                return CustomPaint(painter: _SplashPlantLandscapePainter());
              },
            ),
          ),

          // Upper-Center Branding matching reference screenshot
          Positioned(
            top: topPadding + (screenSize.height * 0.11),
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
                    // Glowing 3D InvestPro Chart Logo
                    Image.asset(
                      'assets/images/splash_logo_3d.png',
                      width: 96,
                      height: 104,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (context, error, stackTrace) {
                        return const _Fallback3DLogo();
                      },
                    ),
                    const SizedBox(height: 16),

                    // App Title: "Invest" in White, "Pro" in Lime Green
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: 'Invest',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          TextSpan(
                            text: 'Pro',
                            style: TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF4ADE80),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Tagline
                    Text(
                      'Grow Your Wealth\nWith Trusted Investments',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.95),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
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

/// Fallback vector logo painter in case asset image cannot be loaded
class _Fallback3DLogo extends StatelessWidget {
  const _Fallback3DLogo();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 104,
      child: CustomPaint(painter: _InvestPro3DLogoPainter()),
    );
  }
}

class _InvestPro3DLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Glowing drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawCircle(Offset(w * 0.5, h * 0.6), 34, shadowPaint);

    final gradientPaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF8CE35E), Color(0xFF2CB457), Color(0xFF15833B)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    // Bar 1 (Left)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.12, h * 0.52, w * 0.20, h * 0.40),
        const Radius.circular(10),
      ),
      gradientPaint,
    );

    // Bar 2 (Middle)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.40, h * 0.32, w * 0.20, h * 0.60),
        const Radius.circular(10),
      ),
      gradientPaint,
    );

    // Bar 3 (Right with arrow)
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.68, h * 0.22, w * 0.20, h * 0.70),
        const Radius.circular(10),
      ),
      gradientPaint,
    );

    final arrow = Path()
      ..moveTo(w * 0.78, h * 0.04)
      ..lineTo(w * 0.62, h * 0.22)
      ..lineTo(w * 0.94, h * 0.22)
      ..close();
    canvas.drawPath(arrow, gradientPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Fallback plant landscape painter
class _SplashPlantLandscapePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Layer 1: Back Hill Wave
    final hillPaint1 = Paint()
      ..color = const Color(0xFF0C5D33).withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;
    final hill1 = Path()
      ..moveTo(0, h * 0.60)
      ..quadraticBezierTo(w * 0.28, h * 0.48, w * 0.65, h * 0.68)
      ..quadraticBezierTo(w * 0.85, h * 0.78, w, h * 0.65)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(hill1, hillPaint1);

    // Layer 2: Middle Vibrant Wave
    final hillPaint2 = Paint()
      ..color = const Color(0xFF138549).withValues(alpha: 0.75)
      ..style = PaintingStyle.fill;
    final hill2 = Path()
      ..moveTo(0, h * 0.76)
      ..quadraticBezierTo(w * 0.35, h * 0.60, w * 0.72, h * 0.70)
      ..quadraticBezierTo(w * 0.88, h * 0.75, w, h * 0.72)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(hill2, hillPaint2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
