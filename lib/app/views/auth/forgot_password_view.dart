import '../../widgets/unsaved_changes_guard.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/app_app_bar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final _formKey = GlobalKey<FormState>();
  final _identityController = TextEditingController(
    text: 'rohit.sharma@example.com',
  );
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  int _currentStep =
      0; // 0: Request OTP, 1: Enter OTP & New Password, 2: Success
  bool _isLoading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  int _resendCountdown = 30;
  Timer? _timer;

  @override
  void dispose() {
    _identityController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startResendTimer() {
    _resendCountdown = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _handleSendOtp() async {
    final identity = _identityController.text.trim();
    if (identity.isEmpty) {
      Get.snackbar(
        'Required',
        'Please enter your email or registered mobile number',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withValues(alpha: 0.15),
        colorText: AppColors.error,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 600));
    setState(() {
      _isLoading = false;
      _currentStep = 1;
      _otpController.text = '4829'; // demo prefill
    });
    _startResendTimer();

    Get.snackbar(
      'Verification Code Sent',
      'A 4-digit code has been sent to $identity',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.success.withValues(alpha: 0.15),
      colorText: AppColors.success,
      margin: const EdgeInsets.all(16),
    );
  }

  Future<void> _handleResetPassword() async {
    final otp = _otpController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (otp.length < 4) {
      Get.snackbar(
        'Invalid Code',
        'Please enter a valid 4-digit verification code',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withValues(alpha: 0.15),
        colorText: AppColors.error,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    if (newPass.length < 6) {
      Get.snackbar(
        'Password Too Short',
        'New password must be at least 6 characters',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withValues(alpha: 0.15),
        colorText: AppColors.error,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    if (newPass != confirmPass) {
      Get.snackbar(
        'Mismatch',
        'Passwords do not match',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.error.withValues(alpha: 0.15),
        colorText: AppColors.error,
        margin: const EdgeInsets.all(16),
      );
      return;
    }

    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 700));
    setState(() {
      _isLoading = false;
      _currentStep = 2; // Success
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return UnsavedChangesGuard(
      controllers: [
        _identityController,
        _otpController,
        _newPasswordController,
        _confirmPasswordController,
      ],
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.background,
        appBar: AppAppBar(
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
              child: Form(key: _formKey, child: _buildCurrentStep(isDark)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep(bool isDark) {
    switch (_currentStep) {
      case 0:
        return _buildRequestStep(isDark);
      case 1:
        return _buildVerifyStep(isDark);
      case 2:
        return _buildSuccessStep(isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildRequestStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        // Icon Badge
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFFE7F7EE),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD1EBDD)),
          ),
          child: const Center(
            child: Icon(
              Icons.lock_reset_rounded,
              color: Color(0xFF00854B),
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Title & Description
        Text(
          'Forgot Password?',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Enter your registered email address or mobile number. We'll send a 4-digit verification code to reset your password.",
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 32),

        // Email / Mobile Input
        CustomTextField(
          controller: _identityController,
          label: 'Email or Mobile Number',
          hintText: 'Enter your email or phone',
          prefixIcon: const Icon(
            Icons.person_outline_rounded,
            size: 20,
            color: Color(0xFF00854B),
          ),
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 28),

        // Send OTP Button
        CustomButton(
          text: 'Send Verification Code',
          onPressed: _handleSendOtp,
          isLoading: _isLoading,
        ),
        const SizedBox(height: 24),

        // Back to Login link
        Center(
          child: TextButton.icon(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(
              Icons.arrow_back_rounded,
              size: 16,
              color: Color(0xFF00854B),
            ),
            label: const Text(
              'Back to Login',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF00854B),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildVerifyStep(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        // Icon Badge
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFFE7F7EE),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD1EBDD)),
          ),
          child: const Center(
            child: Icon(
              Icons.shield_outlined,
              color: Color(0xFF00854B),
              size: 28,
            ),
          ),
        ),
        const SizedBox(height: 20),

        Text(
          'Reset Password',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Enter the verification code sent to ${_identityController.text} and create a new secure password.',
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 28),

        // OTP Code Field
        CustomTextField(
          controller: _otpController,
          label: '4-Digit Verification Code',
          hintText: 'Enter 4-digit code',
          prefixIcon: const Icon(
            Icons.pin_rounded,
            size: 20,
            color: Color(0xFF00854B),
          ),
          keyboardType: TextInputType.number,
          suffixIcon: TextButton(
            onPressed: _resendCountdown == 0 ? _startResendTimer : null,
            child: Text(
              _resendCountdown > 0 ? '${_resendCountdown}s' : 'Resend',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _resendCountdown > 0
                    ? AppColors.textSecondary
                    : const Color(0xFF00854B),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),

        // New Password Field
        CustomTextField(
          controller: _newPasswordController,
          label: 'New Password',
          hintText: 'Enter at least 6 characters',
          obscureText: _obscureNew,
          prefixIcon: const Icon(
            Icons.lock_outline_rounded,
            size: 20,
            color: Color(0xFF00854B),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureNew
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 20,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
            onPressed: () => setState(() => _obscureNew = !_obscureNew),
          ),
        ),
        const SizedBox(height: 18),

        // Confirm Password Field
        CustomTextField(
          controller: _confirmPasswordController,
          label: 'Confirm New Password',
          hintText: 'Re-enter your new password',
          obscureText: _obscureConfirm,
          prefixIcon: const Icon(
            Icons.lock_outline_rounded,
            size: 20,
            color: Color(0xFF00854B),
          ),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirm
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              size: 20,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
            onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
          ),
        ),
        const SizedBox(height: 28),

        // Reset Password Button
        CustomButton(
          text: 'Reset Password',
          onPressed: _handleResetPassword,
          isLoading: _isLoading,
        ),
      ],
    );
  }

  Widget _buildSuccessStep(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
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
            const SizedBox(height: 24),
            Text(
              'Password Reset Successful!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your password has been reset successfully. You can now log into InvestPro with your new password.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 36),
            CustomButton(
              text: 'Back to Login',
              onPressed: () => Get.offAllNamed(AppRoutes.login),
            ),
          ],
        ),
      ),
    );
  }
}
