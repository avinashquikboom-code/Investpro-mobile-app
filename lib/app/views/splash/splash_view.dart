import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../routes/app_routes.dart';
import 'splash_branding.dart';
import '../../widgets/app_system_ui.dart';

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
    final authCtrl = Get.find<AuthController>();
    final sessionFuture = authCtrl.restoreSession();
    final delayFuture = Future.delayed(const Duration(seconds: 3));

    final results = await Future.wait([sessionFuture, delayFuture]);
    final isAuthenticated = results[0] as bool;

    if (!mounted) return;

    if (isAuthenticated) {
      Get.offAllNamed(authCtrl.authenticatedRoute);
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
    return AppSystemUi(
      statusSurface: const Color(0xFFF3F8F2),
      child: Scaffold(
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SplashBranding(
            scale: _scaleAnimation,
          ),
        ),
      ),
    );
  }
}
