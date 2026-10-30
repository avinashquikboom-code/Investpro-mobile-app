import '../../widgets/unsaved_changes_guard.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/app_app_bar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _mobileController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _mobileController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authCtrl = Get.find<AuthController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return UnsavedChangesGuard(
      controllers: [
        _fullNameController,
        _emailController,
        _mobileController,
        _passwordController,
      ],
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.background,
        appBar: const AppAppBar(
          backgroundColor: Colors.transparent,
          showBackButton: true,
        ),
        body: SafeArea(
          child: ResponsiveHelper.responsiveContainer(
            context: context,
            maxWidth: 480,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Heading
                  Text(
                    'createAccount'.tr,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'createAccountSubtitle'.tr,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Full Name
                  CustomTextField(
                    controller: _fullNameController,
                    label: 'fullName'.tr,
                    hintText: 'enterFullName'.tr,
                    prefixIcon: const Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Email
                  CustomTextField(
                    controller: _emailController,
                    label: 'email'.tr,
                    hintText: 'enterEmail'.tr,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(
                      Icons.mail_outline_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Mobile Number
                  CustomTextField(
                    controller: _mobileController,
                    label: 'mobileNumber'.tr,
                    hintText: 'enterMobileNumber'.tr,
                    keyboardType: TextInputType.phone,
                    prefixIcon: const Icon(
                      Icons.phone_outlined,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Password
                  Obx(() {
                    return CustomTextField(
                      controller: _passwordController,
                      label: 'password'.tr,
                      hintText: 'enterPassword'.tr,
                      obscureText: !authCtrl.isPasswordVisible.value,
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                        color: AppColors.textSecondary,
                      ),
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
                  const SizedBox(height: 28),

                  // Register Button
                  Obx(() {
                    return CustomButton(
                      text: 'register'.tr,
                      isLoading: authCtrl.isLoading.value,
                      onPressed: () {
                        authCtrl.register(
                          fullName: _fullNameController.text.trim(),
                          email: _emailController.text.trim(),
                          mobileNumber: _mobileController.text.trim(),
                          password: _passwordController.text,
                        );
                      },
                    );
                  }),
                  const SizedBox(height: 18),

                  // Already have an account? Login
                  Center(
                    child: TextButton(
                      onPressed: () => Get.offNamed(AppRoutes.login),
                      child: Text.rich(
                        TextSpan(
                          text: '${'alreadyHaveAccount'.tr.split('?').first}? ',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                          ),
                          children: [
                            TextSpan(
                              text: 'login'.tr,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
