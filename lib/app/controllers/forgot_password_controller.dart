import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../routes/app_routes.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../utils/validators.dart';

/// Controller for InvestPro Forgot Password & Password Reset flow.
/// Adheres strictly to GetX architecture without GetX Bindings.
class ForgotPasswordController extends GetxController {
  final ApiService? _api;

  ForgotPasswordController([this._api]);

  /// Steps:
  /// 0: Request Verification Code (Email / Mobile)
  /// 1: Enter Verification Code
  /// 2: Create New Password & Confirm
  /// 3: Password Reset Successful
  final currentStep = 0.obs;

  final isLoading = false.obs;
  final identifier = ''.obs;
  final otp = ''.obs;
  final newPassword = ''.obs;
  final confirmPassword = ''.obs;

  final validationError = ''.obs;
  final apiError = ''.obs;

  final resendCooldown = 0.obs;
  Timer? _cooldownTimer;

  final isPasswordVisible = false.obs;
  final isConfirmVisible = false.obs;

  @override
  void onClose() {
    _cooldownTimer?.cancel();
    super.onClose();
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleConfirmVisibility() {
    isConfirmVisible.value = !isConfirmVisible.value;
  }

  String? validateIdentifier(String val) {
    final trimmed = val.trim();
    if (trimmed.isEmpty) {
      return 'Please enter your registered email or mobile number';
    }
    if (trimmed.contains('@')) {
      final emailErr = Validators.validateEmail(trimmed);
      if (emailErr != null) return 'Please enter a valid email address';
      return null;
    }
    final cleanPhone = trimmed.replaceAll(RegExp(r'[^0-9]'), '');
    if (cleanPhone.length < 10) {
      return 'Please enter a valid 10-digit mobile number';
    }
    return null;
  }

  String? validateOtp(String val) {
    final trimmed = val.trim();
    if (trimmed.isEmpty) {
      return 'Please enter the verification code';
    }
    if (trimmed.length < 4) {
      return 'Verification code must be at least 4 digits';
    }
    return null;
  }

  String? validatePasswords(String newPass, String confirmPass) {
    if (newPass.length < 8) {
      return 'Password must be at least 8 characters long';
    }
    if (newPass != confirmPass) {
      return 'Passwords do not match';
    }
    return null;
  }

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();
    resendCooldown.value = seconds;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (resendCooldown.value > 0) {
        resendCooldown.value--;
      } else {
        timer.cancel();
      }
    });
  }

  String _extractErrorMessage(dynamic error, String fallback) {
    if (error is DioException) {
      final msg = error.response?.data?['message'];
      if (msg is String && msg.isNotEmpty) {
        return msg;
      }
    }
    return fallback;
  }

  void _showSnackbar(String title, String message, {bool isError = false}) {
    if (Get.context == null || Get.overlayContext == null) return;
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: (isError ? AppColors.error : AppColors.success)
          .withValues(alpha: 0.15),
      colorText: isError ? AppColors.error : AppColors.success,
      margin: const EdgeInsets.all(16),
    );
  }

  Future<bool> sendResetCode() async {
    if (isLoading.value) return false;

    final err = validateIdentifier(identifier.value);
    if (err != null) {
      validationError.value = err;
      _showSnackbar('Validation Error', err, isError: true);
      return false;
    }

    validationError.value = '';
    apiError.value = '';
    isLoading.value = true;

    try {
      if (_api == null) {
        throw StateError('API Service unavailable');
      }

      final res = await _api.forgotPassword(identifier.value.trim());
      final cooldown = (res?['cooldownSeconds'] as num?)?.toInt() ?? 60;
      _startCooldown(cooldown);

      currentStep.value = 1;

      _showSnackbar(
        'Code Dispatched',
        'A verification code has been dispatched to your credential.',
      );
      return true;
    } catch (e) {
      final msg = _extractErrorMessage(
        e,
        'Unable to send verification code. Please check your network.',
      );
      apiError.value = msg;
      _showSnackbar('Request Failed', msg, isError: true);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> resendCode() async {
    if (resendCooldown.value > 0 || isLoading.value) return false;
    return await sendResetCode();
  }

  Future<bool> verifyResetCode() async {
    if (isLoading.value) return false;

    final err = validateOtp(otp.value);
    if (err != null) {
      validationError.value = err;
      _showSnackbar('Validation Error', err, isError: true);
      return false;
    }

    validationError.value = '';
    apiError.value = '';
    isLoading.value = true;

    try {
      if (_api == null) {
        throw StateError('API Service unavailable');
      }

      await _api.verifyResetCode(
        identifier: identifier.value.trim(),
        otp: otp.value.trim(),
      );

      currentStep.value = 2;
      return true;
    } catch (e) {
      final msg = _extractErrorMessage(
        e,
        'Invalid or expired verification code. Please try again.',
      );
      apiError.value = msg;
      _showSnackbar('Verification Failed', msg, isError: true);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> resetPassword() async {
    if (isLoading.value) return false;

    final err = validatePasswords(newPassword.value, confirmPassword.value);
    if (err != null) {
      validationError.value = err;
      _showSnackbar('Validation Error', err, isError: true);
      return false;
    }

    validationError.value = '';
    apiError.value = '';
    isLoading.value = true;

    try {
      if (_api == null) {
        throw StateError('API Service unavailable');
      }

      await _api.resetPassword(
        identifier: identifier.value.trim(),
        otp: otp.value.trim(),
        newPassword: newPassword.value,
      );

      _cooldownTimer?.cancel();
      currentStep.value = 3;
      return true;
    } catch (e) {
      final msg = _extractErrorMessage(
        e,
        'Failed to reset password. Please request a new code.',
      );
      apiError.value = msg;
      _showSnackbar('Reset Failed', msg, isError: true);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void previousStep() {
    if (currentStep.value > 0 && currentStep.value < 3) {
      currentStep.value--;
      validationError.value = '';
      apiError.value = '';
    }
  }

  void goToLogin() {
    Get.offAllNamed(AppRoutes.login);
  }
}
