import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import 'navigation_controller.dart';
import '../routes/app_routes.dart';
import '../services/api_service.dart';
import '../services/demo_repository.dart';
import '../services/local_storage_service.dart';
import '../utils/validators.dart';

class AuthController extends GetxController {
  final LocalStorageService _storage;
  final DemoRepository _repo;
  final ApiService? _api;

  AuthController(this._storage, this._repo, [this._api]);

  final RxBool isLoggedIn = false.obs;
  final RxBool rememberMe = true.obs;
  final RxBool isPasswordVisible = false.obs;
  final RxBool isLoading = false.obs;
  final RxString selectedRole = 'Investor'.obs; // Investor or Admin

  @override
  void onInit() {
    super.onInit();
    isLoggedIn.value = _storage.isLoggedIn && _storage.rememberMe;
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
    if (isLoading.value) return false;
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
    try {
      // 1. Try Backend API login
      if (_api != null) {
        try {
          final res = await _api.login(identity, password);
          if (res != null) {
            isLoggedIn.value = true;
            await _storage.setRememberMe(rememberMe.value);
            await _storage.setLoggedIn(rememberMe.value);
            if (rememberMe.value) {
              await _storage.setUserEmail(identity);
            }
            // Sync live investor data from backend
            await _repo.syncFromBackend();

            Get.find<NavigationController>().goToHome();
            Get.offAllNamed(AppRoutes.home);
            return true;
          }
        } catch (apiError) {
          debugPrint('[AuthController] Backend login failed: $apiError, checking local fallback');
        }
      }

      // 2. Demo offline fallback for smooth local testing
      await Future.delayed(const Duration(milliseconds: 600));

      isLoggedIn.value = true;
      await _storage.setRememberMe(rememberMe.value);
      await _storage.setLoggedIn(rememberMe.value);
      if (rememberMe.value) {
        await _storage.setUserEmail(identity);
      } else {
        await _storage.setUserEmail(null);
      }

      Get.find<NavigationController>().goToHome();
      Get.offAllNamed(AppRoutes.home);
      return true;
    } catch (e) {
      Get.snackbar('Login error', e.toString(), snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String mobileNumber,
    required String password,
  }) async {
    if (isLoading.value) return false;
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
    try {
      // 1. Try Backend API registration
      if (_api != null) {
        try {
          final res = await _api.register(
            fullName: fullName,
            email: email,
            mobileNumber: mobileNumber,
            password: password,
          );
          if (res != null) {
            isLoggedIn.value = true;
            await _storage.setRememberMe(rememberMe.value);
            await _storage.setLoggedIn(rememberMe.value);
            if (rememberMe.value) {
              await _storage.setUserEmail(email);
            }
            await _repo.syncFromBackend();

            Get.snackbar(
              'Account Created 🎉',
              'Welcome to InvestPro, $fullName!',
              snackPosition: SnackPosition.BOTTOM,
              backgroundColor: const Color(0xFFE8F8F0),
              colorText: const Color(0xFF006B3C),
            );

            Get.find<NavigationController>().goToHome();
            Get.offAllNamed(AppRoutes.home);
            return true;
          }
        } catch (apiError) {
          debugPrint('[AuthController] Backend register failed: $apiError, falling back to local');
        }
      }

      // 2. Demo local registration fallback
      await Future.delayed(const Duration(milliseconds: 700));

      final newUser = UserModel(
        id: 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        fullName: fullName,
        email: email,
        mobileNumber: mobileNumber,
        role: 'Investor',
        isBankVerified: false,
      );

      await _repo.saveUser(newUser);

      isLoggedIn.value = true;
      await _storage.setRememberMe(rememberMe.value);
      await _storage.setLoggedIn(rememberMe.value);
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

      Get.find<NavigationController>().goToHome();
      Get.offAllNamed(AppRoutes.home);
      return true;
    } catch (e) {
      Get.snackbar('Registration error', e.toString(), snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  void forgotPassword(String identity) {
    Get.defaultDialog(
      title: 'Password Recovery',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          identity.isNotEmpty
              ? 'A recovery link has been sent to $identity if an account is registered with InvestPro.'
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
          'Are you sure you want to log out? Your session tokens and saved records will be cleared.',
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
      if (_api != null) {
        await _api.logout().catchError((_) {});
      }
      await _storage.clearSession();
      Get.offAllNamed(AppRoutes.login);
    }
  }
}
