import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../routes/app_routes.dart';
import '../services/demo_repository.dart';
import '../services/local_storage_service.dart';
import '../utils/validators.dart';

class AuthController extends GetxController {
  final LocalStorageService _storage;
  final DemoRepository _repo;

  AuthController(this._storage, this._repo);

  final RxBool isLoggedIn = false.obs;
  final RxBool rememberMe = true.obs;
  final RxBool isPasswordVisible = false.obs;
  final RxBool isLoading = false.obs;
  final RxString selectedRole = 'Investor'.obs; // Investor or Admin

  @override
  void onInit() {
    super.onInit();
    isLoggedIn.value = _storage.isLoggedIn;
    rememberMe.value = _storage.rememberMe;
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleRememberMe(bool? value) {
    rememberMe.value = value ?? false;
    _storage.setRememberMe(rememberMe.value);
  }

  void setRole(String role) {
    selectedRole.value = role;
  }

  Future<bool> login(String identity, String password) async {
    final identityError = Validators.validateEmailOrMobile(identity);
    if (identityError != null) {
      Get.snackbar('Validation Error', identityError, snackPosition: SnackPosition.BOTTOM);
      return false;
    }

    final passwordError = Validators.validatePassword(password);
    if (passwordError != null) {
      Get.snackbar('Validation Error', passwordError, snackPosition: SnackPosition.BOTTOM);
      return false;
    }

    isLoading.value = true;
    await Future.delayed(const Duration(milliseconds: 800)); // Smooth UX transition
    isLoading.value = false;

    isLoggedIn.value = true;
    await _storage.setLoggedIn(true);
    if (rememberMe.value) {
      await _storage.setUserEmail(identity);
    } else {
      await _storage.setUserEmail(null);
    }

    Get.offAllNamed(AppRoutes.home);
    return true;
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String mobileNumber,
    required String password,
  }) async {
    final nameError = Validators.validateName(fullName);
    if (nameError != null) {
      Get.snackbar('Validation Error', nameError, snackPosition: SnackPosition.BOTTOM);
      return false;
    }

    final emailError = Validators.validateEmail(email);
    if (emailError != null) {
      Get.snackbar('Validation Error', emailError, snackPosition: SnackPosition.BOTTOM);
      return false;
    }

    final mobileError = Validators.validateMobile(mobileNumber);
    if (mobileError != null) {
      Get.snackbar('Validation Error', mobileError, snackPosition: SnackPosition.BOTTOM);
      return false;
    }

    final passwordError = Validators.validatePassword(password);
    if (passwordError != null) {
      Get.snackbar('Validation Error', passwordError, snackPosition: SnackPosition.BOTTOM);
      return false;
    }

    isLoading.value = true;
    await Future.delayed(const Duration(milliseconds: 900));
    isLoading.value = false;

    final newUser = UserModel(
      id: 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      fullName: fullName,
      email: email,
      mobileNumber: mobileNumber,
      role: selectedRole.value,
    );

    _repo.currentUser.value = newUser;
    _storage.writeMap('user_data', newUser.toJson());

    isLoggedIn.value = true;
    await _storage.setLoggedIn(true);
    if (rememberMe.value) {
      await _storage.setUserEmail(email);
    }

    Get.snackbar(
      'Account Created',
      'Welcome to InvestPro, $fullName!',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFE8F8F0),
      colorText: const Color(0xFF006B3C),
    );

    Get.offAllNamed(AppRoutes.home);
    return true;
  }

  void forgotPassword(String identity) {
    Get.defaultDialog(
      title: 'Password Recovery',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          identity.isNotEmpty
              ? 'Password reset instructions have been sent to $identity.'
              : 'Please enter your registered email or phone to reset your password.',
          textAlign: TextAlign.center,
        ),
      ),
      textConfirm: 'Okay',
      confirmTextColor: Colors.white,
      buttonColor: const Color(0xFF006B3C),
      onConfirm: () => Get.back(),
    );
  }

  Future<void> logout() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout Confirmation'),
        content: const Text(
          'Are you sure you want to log out? Your demo investments and transactions will remain saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF71847D))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Get.back(result: true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      isLoggedIn.value = false;
      await _storage.clearSession();
      Get.offAllNamed(AppRoutes.login);
    }
  }
}
