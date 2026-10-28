import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../routes/app_routes.dart';
import '../../services/local_storage_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _identityController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final storage = Get.find<LocalStorageService>();
    if (storage.rememberMe && storage.userEmail != null) {
      _identityController.text = storage.userEmail!;
    }
  }

  @override
  void dispose() {
    _identityController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authCtrl = Get.find<AuthController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        child: ResponsiveHelper.responsiveContainer(
          context: context,
          maxWidth: 480,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 24),
                  // App Logo
                  const AppLogo(size: 60, fontSize: 26),
                  const SizedBox(height: 28),

                  // Heading
                  Text(
                    'welcomeBack'.tr,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'loginSubtitle'.tr,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Email or Mobile Field
                  CustomTextField(
                    controller: _identityController,
                    label: 'emailOrMobile'.tr,
                    hintText: 'enterEmailOrMobile'.tr,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.person_outline_rounded, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 18),

                  // Password Field
                  Obx(() {
                    return CustomTextField(
                      controller: _passwordController,
                      label: 'password'.tr,
                      hintText: 'enterPassword'.tr,
                      obscureText: !authCtrl.isPasswordVisible.value,
                      prefixIcon: const Icon(Icons.lock_outline_rounded, color: AppColors.textSecondary),
                      suffixIcon: IconButton(
                        icon: Icon(
                          authCtrl.isPasswordVisible.value
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: AppColors.textSecondary,
                          size: 20,
                        ),
                        onPressed: authCtrl.togglePasswordVisibility,
                      ),
                    );
                  }),
                  const SizedBox(height: 12),

                  // Remember me & Forgot Password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Obx(() {
                            return SizedBox(
                              height: 24,
                              width: 24,
                              child: Checkbox(
                                value: authCtrl.rememberMe.value,
                                activeColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                onChanged: authCtrl.toggleRememberMe,
                              ),
                            );
                          }),
                          const SizedBox(width: 8),
                          Text(
                            'rememberMe'.tr,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () => authCtrl.forgotPassword(_identityController.text),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text(
                          'forgotPassword'.tr,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),

                  const Padding(padding: EdgeInsets.symmetric(vertical:12), child: Text('LOCAL DEMO: use any valid email/mobile and a password with 8+ characters, letters and numbers. No real authentication.')),
                  // Login Button
                  Obx(() {
                    return CustomButton(
                      text: 'login'.tr,
                      isLoading: authCtrl.isLoading.value,
                      onPressed: () {
                        authCtrl.login(
                          _identityController.text.trim(),
                          _passwordController.text,
                        );
                      },
                    );
                  }),
                  const SizedBox(height: 14),

                  // Create New Account Outlined Button
                  CustomButton(
                    text: 'createNewAccount'.tr,
                    isOutlined: true,
                    onPressed: () => Get.toNamed(AppRoutes.register),
                  ),
                  const SizedBox(height: 40),

                  // Footer: Secure & Trusted
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shield_outlined, size: 16, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        'secureAndTrusted'.tr,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
