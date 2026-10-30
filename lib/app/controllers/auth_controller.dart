import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'navigation_controller.dart';
import '../routes/app_routes.dart';
import '../services/api_service.dart';
import '../services/demo_repository.dart';
import '../services/local_storage_service.dart';
import '../services/notification_service.dart';
import '../services/firebase_notification_service.dart';
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

  @override
  void onInit() {
    super.onInit();
    isLoggedIn.value = false;
    rememberMe.value = _storage.rememberMe;
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleRememberMe(bool? value) {
    rememberMe.value = value ?? false;
    _storage.setRememberMe(rememberMe.value);
  }

  Future<bool> _finish(Map<String, dynamic>? result) async {
    if (result == null || result['user']?['role'] != 'INVESTOR') {
      await _api?.logout();
      throw StateError('An investor account is required');
    }
    _repo.clearLiveData();
    if (Get.isRegistered<NotificationService>()) Get.find<NotificationService>().clear();
    await _repo.syncFromBackend();
    await _storage.setRememberMe(rememberMe.value);
    await _storage.setLoggedIn(rememberMe.value);
    await _storage.setUserEmail(null);
    isLoggedIn.value = true;
    if (Get.isRegistered<FirebaseNotificationService>()) Get.find<FirebaseNotificationService>().syncToken().catchError((_) {});
    if (Get.isRegistered<NotificationService>()) Get.find<NotificationService>().refreshFromBackend().catchError((_) {});
    Get.find<NavigationController>().goToHome();
    Get.offAllNamed(AppRoutes.home);
    return true;
  }
  Future<bool> restoreSession() async {
    isLoggedIn.value = false;
    if (_api == null || !_storage.rememberMe || (await _api.getAccessToken())?.isNotEmpty != true) {
      _repo.clearLiveData();
    if (Get.isRegistered<NotificationService>()) Get.find<NotificationService>().clear(); return false;
    }
    try { await _repo.syncFromBackend(); isLoggedIn.value = _repo.currentUser.value.accountStatus == 'ACTIVE'; return isLoggedIn.value; }
    catch (_) { _repo.clearLiveData();
    if (Get.isRegistered<NotificationService>()) Get.find<NotificationService>().clear(); return false; }
  }
  Future<bool> login(String identity, String password) async {
    if (isLoading.value) return false;
    final validation = Validators.validateEmailOrMobile(identity) ?? Validators.validatePassword(password);
    if (validation != null) { Get.snackbar('Validation Error', validation); return false; }
    isLoading.value = true;
    try {
      if (_api == null) throw StateError('Account service is unavailable');
      return await _finish(await _api.login(identity.trim(), password));
    } catch (_) {
      isLoggedIn.value = false;
      Get.snackbar('Unable to sign in', 'Check your credentials and connection. No offline login was created.');
      return false;
    } finally {
      isLoading.value = false;
      isPasswordVisible.value = false;
    }
  }
  Future<bool> register({required String fullName, required String email, required String mobileNumber, required String password}) async {
    if (isLoading.value) return false;
    final validation = Validators.validateName(fullName) ?? Validators.validateEmail(email) ?? Validators.validateMobile(mobileNumber) ?? (password.length < 8 ? 'Use a password of at least 8 characters' : null);
    if (validation != null) { Get.snackbar('Validation Error', validation); return false; }
    isLoading.value = true;
    try {
      if (_api == null) throw StateError('Account service is unavailable');
      return await _finish(await _api.register(fullName: fullName.trim(), email: email.trim(), mobileNumber: mobileNumber.trim(), password: password));
    } catch (_) {
      isLoggedIn.value = false;
      Get.snackbar('Unable to complete registration', 'Check your connection and account details. If registration succeeded, sign in to load the account.');
      return false;
    } finally { isLoading.value = false; }
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
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF71847D)),
            ),
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
      isPasswordVisible.value = false;
      _repo.clearLiveData();
    if (Get.isRegistered<NotificationService>()) Get.find<NotificationService>().clear();
      try {
        if (Get.isRegistered<FirebaseNotificationService>()) {
          await Get.find<FirebaseNotificationService>().deleteToken();
        }
      } catch (_) {}
      if (_api != null) {
        await _api.logout().catchError((_) {});
      }
      await _storage.clearSession();
      Get.offAllNamed(AppRoutes.login);
    }
  }
}
