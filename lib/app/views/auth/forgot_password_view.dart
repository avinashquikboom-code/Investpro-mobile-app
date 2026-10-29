import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/forgot_password_controller.dart';
import '../../services/api_service.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_app_bar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/unsaved_changes_guard.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  late final ForgotPasswordController _controller;

  final _identityController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = Get.isRegistered<ForgotPasswordController>()
        ? Get.find<ForgotPasswordController>()
        : Get.put(
            ForgotPasswordController(
              Get.isRegistered<ApiService>() ? Get.find<ApiService>() : null,
            ),
          );
  }

  @override
  void dispose() {
    _identityController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      final step = _controller.currentStep.value;

      return UnsavedChangesGuard(
        onBackWithinPage: step > 0 && step < 3
            ? () {
                _controller.previousStep();
              }
            : null,
        controllers: [
          _identityController,
          _otpController,
          _newPasswordController,
          _confirmPasswordController,
        ],
        child: Scaffold(
          backgroundColor:
              isDark ? AppColors.backgroundDark : AppColors.background,
          appBar: AppAppBar(
            backgroundColor: Colors.transparent,
            showBackButton: true,
            onBackPressed: () {
              if (step > 0 && step < 3) {
                _controller.previousStep();
              } else if (step == 3) {
                _controller.goToLogin();
              } else {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                } else {
                  _controller.goToLogin();
                }
              }
            },
          ),
          body: SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: _buildStepContent(context, isDark, step),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildStepContent(BuildContext context, bool isDark, int step) {
    switch (step) {
      case 0:
        return _buildRequestStep(context, isDark);
      case 1:
        return _buildVerifyStep(context, isDark);
      case 2:
        return _buildNewPasswordStep(context, isDark);
      case 3:
        return _buildSuccessStep(context, isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildRequestStep(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon Badge
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFE7F7EE),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFD1EBDD), width: 1),
          ),
          child: const Center(
            child: Icon(
              Icons.lock_reset_rounded,
              color: Color(0xFF00854B),
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Title & Description
        Text(
          'Forgot Password?',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF003B2D),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Enter your registered email address or mobile number. We'll send a verification code to reset your password.",
          style: GoogleFonts.poppins(
            fontSize: 13,
            height: 1.5,
            color:
                isDark ? AppColors.textSecondaryDark : const Color(0xFF71847B),
          ),
        ),
        const SizedBox(height: 24),

        // Email / Mobile Input
        CustomTextField(
          controller: _identityController,
          label: 'Email or Mobile Number',
          hintText: 'e.g. investor@example.com or 9876543210',
          prefixIcon: const Icon(
            Icons.person_outline_rounded,
            size: 20,
            color: Color(0xFF00854B),
          ),
          keyboardType: TextInputType.emailAddress,
          onChanged: (val) => _controller.identifier.value = val,
        ),
        const SizedBox(height: 24),

        // Send OTP Button
        Obx(() {
          return CustomButton(
            text: 'Send Verification Code',
            isLoading: _controller.isLoading.value,
            onPressed: _controller.isLoading.value
                ? null
                : () {
                    _controller.identifier.value =
                        _identityController.text.trim();
                    _controller.sendResetCode();
                  },
          );
        }),
        const SizedBox(height: 20),

        // Back to Login link
        Center(
          child: TextButton.icon(
            onPressed: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                _controller.goToLogin();
              }
            },
            icon: const Icon(
              Icons.arrow_back_rounded,
              size: 16,
              color: Color(0xFF00854B),
            ),
            label: Text(
              'Back to Login',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF00854B),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyStep(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon Badge
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFE7F7EE),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFD1EBDD), width: 1),
          ),
          child: const Center(
            child: Icon(
              Icons.shield_outlined,
              color: Color(0xFF00854B),
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 16),

        Text(
          'Verify Code',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF003B2D),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Obx(() {
          return Text(
            'Enter the verification code sent to ${_controller.identifier.value.isNotEmpty ? _controller.identifier.value : _identityController.text}.',
            style: GoogleFonts.poppins(
              fontSize: 13,
              height: 1.5,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : const Color(0xFF71847B),
            ),
          );
        }),
        const SizedBox(height: 24),

        // Verification Code Field
        CustomTextField(
          controller: _otpController,
          label: 'Verification Code',
          hintText: 'Enter code',
          prefixIcon: const Icon(
            Icons.pin_rounded,
            size: 20,
            color: Color(0xFF00854B),
          ),
          keyboardType: TextInputType.number,
          onChanged: (val) => _controller.otp.value = val,
          suffixIcon: Obx(() {
            final cooldown = _controller.resendCooldown.value;
            return TextButton(
              onPressed: cooldown == 0 && !_controller.isLoading.value
                  ? () => _controller.resendCode()
                  : null,
              child: Text(
                cooldown > 0 ? '${cooldown}s' : 'Resend',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cooldown > 0
                      ? AppColors.textSecondary
                      : const Color(0xFF00854B),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 24),

        // Verify Code Button
        Obx(() {
          return CustomButton(
            text: 'Verify Code',
            isLoading: _controller.isLoading.value,
            onPressed: _controller.isLoading.value
                ? null
                : () {
                    _controller.otp.value = _otpController.text.trim();
                    _controller.verifyResetCode();
                  },
          );
        }),
        const SizedBox(height: 16),

        // Edit Identifier link
        Center(
          child: TextButton(
            onPressed: _controller.previousStep,
            child: Text(
              'Change Email or Mobile Number',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF00854B),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNewPasswordStep(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Icon Badge
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFE7F7EE),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFD1EBDD), width: 1),
          ),
          child: const Center(
            child: Icon(
              Icons.lock_outline_rounded,
              color: Color(0xFF00854B),
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 16),

        Text(
          'Create New Password',
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF003B2D),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Create a strong password with at least 8 characters.',
          style: GoogleFonts.poppins(
            fontSize: 13,
            height: 1.5,
            color:
                isDark ? AppColors.textSecondaryDark : const Color(0xFF71847B),
          ),
        ),
        const SizedBox(height: 24),

        // New Password Field
        Obx(() {
          return CustomTextField(
            controller: _newPasswordController,
            label: 'New Password',
            hintText: 'Enter at least 8 characters',
            obscureText: !_controller.isPasswordVisible.value,
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              size: 20,
              color: Color(0xFF00854B),
            ),
            onChanged: (val) => _controller.newPassword.value = val,
            suffixIcon: IconButton(
              icon: Icon(
                _controller.isPasswordVisible.value
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
              onPressed: _controller.togglePasswordVisibility,
            ),
          );
        }),
        const SizedBox(height: 18),

        // Confirm Password Field
        Obx(() {
          return CustomTextField(
            controller: _confirmPasswordController,
            label: 'Confirm New Password',
            hintText: 'Re-enter your new password',
            obscureText: !_controller.isConfirmVisible.value,
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              size: 20,
              color: Color(0xFF00854B),
            ),
            onChanged: (val) => _controller.confirmPassword.value = val,
            suffixIcon: IconButton(
              icon: Icon(
                _controller.isConfirmVisible.value
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                size: 20,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
              onPressed: _controller.toggleConfirmVisibility,
            ),
          );
        }),
        const SizedBox(height: 24),

        // Reset Password Button
        Obx(() {
          return CustomButton(
            text: 'Reset Password',
            isLoading: _controller.isLoading.value,
            onPressed: _controller.isLoading.value
                ? null
                : () {
                    _controller.newPassword.value = _newPasswordController.text;
                    _controller.confirmPassword.value =
                        _confirmPasswordController.text;
                    _controller.resetPassword();
                  },
          );
        }),
      ],
    );
  }

  Widget _buildSuccessStep(BuildContext context, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: const BoxDecoration(
                color: Color(0xFFE7F7EE),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF00854B),
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Password Reset Successful!',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color:
                    isDark ? AppColors.textPrimaryDark : const Color(0xFF003B2D),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your password has been reset successfully. You can now log into InvestPro with your new password.',
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 13,
                height: 1.5,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : const Color(0xFF71847B),
              ),
            ),
            const SizedBox(height: 28),
            CustomButton(
              text: 'Back to Login',
              onPressed: _controller.goToLogin,
            ),
          ],
        ),
      ),
    );
  }
}
