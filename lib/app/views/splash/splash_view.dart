import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../routes/app_routes.dart';
import '../../services/local_storage_service.dart';
import '../../theme/app_colors.dart';
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

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _controller.forward();

    _navigateNext();
  }

  Future<void> _navigateNext() async {
    await Future.delayed(const Duration(milliseconds: 2200));
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
    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.splashGradient,
            ),
          ),

          // Decorative curved plant waves at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 240,
            child: CustomPaint(
              painter: _SplashWavesPainter(),
            ),
          ),

          // Centered Logo & Tagline
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const AppLogo(
                        size: 72,
                        isWhite: true,
                        fontSize: 34,
                      ),
                      const SizedBox(height: 14),
                      Text(
                        'Grow Your Wealth\nWith Trusted Investments',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.88),
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashWavesPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint1 = Paint()
      ..color = const Color(0xFF0E9F53).withValues(alpha: 0.16)
      ..style = PaintingStyle.fill;

    final paint2 = Paint()
      ..color = const Color(0xFF35C76F).withValues(alpha: 0.22)
      ..style = PaintingStyle.fill;

    // Outer subtle wave
    final path1 = Path();
    path1.moveTo(0, size.height * 0.4);
    path1.quadraticBezierTo(
      size.width * 0.4,
      size.height * 0.1,
      size.width,
      size.height * 0.5,
    );
    path1.lineTo(size.width, size.height);
    path1.lineTo(0, size.height);
    path1.close();
    canvas.drawPath(path1, paint1);

    // Inner bright wave
    final path2 = Path();
    path2.moveTo(0, size.height * 0.65);
    path2.quadraticBezierTo(
      size.width * 0.6,
      size.height * 0.45,
      size.width,
      size.height * 0.75,
    );
    path2.lineTo(size.width, size.height);
    path2.lineTo(0, size.height);
    path2.close();
    canvas.drawPath(path2, paint2);

    // Decorative leaf stem on the bottom left
    final leafPaint = Paint()
      ..color = const Color(0xFF35C76F).withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    final stem = Path();
    stem.moveTo(size.width * 0.15, size.height);
    stem.quadraticBezierTo(size.width * 0.12, size.height * 0.4, size.width * 0.18, size.height * 0.2);
    canvas.drawPath(stem, leafPaint);

    final leafFill = Paint()
      ..color = const Color(0xFF35C76F).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;

    // Left leaf
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width * 0.11, size.height * 0.38), width: 32, height: 18),
      leafFill,
    );
    // Right leaf
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width * 0.19, size.height * 0.32), width: 34, height: 18),
      leafFill,
    );
    // Top leaf
    canvas.drawOval(
      Rect.fromCenter(center: Offset(size.width * 0.18, size.height * 0.18), width: 22, height: 36),
      leafFill,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
