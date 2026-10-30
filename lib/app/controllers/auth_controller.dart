import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'navigation_controller.dart';
import 'project_controller.dart';
import '../constants/app_constants.dart';
import '../routes/app_routes.dart';
import '../services/api_service.dart';
import '../services/backend_snapshot.dart';
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
    isLoggedIn.value = _storage.isLoggedIn;
    rememberMe.value = _storage.rememberMe;
    if (_api != null) _api.onSessionExpired = _sessionExpired;
  }

  void _sessionExpired() {
    isLoggedIn.value = false;
    _repo.clearLiveData();
    if (Get.isRegistered<ProjectController>()) {
      Get.find<ProjectController>().clearForSession();
    }
    if (Get.isRegistered<NotificationService>()) {
      Get.find<NotificationService>().clear();
    }
    _storage.setLoggedIn(false).catchError((_) {});
    if (Get.key.currentState != null && Get.currentRoute != AppRoutes.login) {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  void onClose() {
    if (_api?.onSessionExpired == _sessionExpired) {
      _api?.onSessionExpired = null;
    }
    super.onClose();
  }

  void togglePasswordVisibility() {
    isPasswordVisible.value = !isPasswordVisible.value;
  }

  void toggleRememberMe(bool? value) {
    rememberMe.value = value ?? true;
    _storage.setRememberMe(rememberMe.value);
  }

  Future<bool> _finish(Map<String, dynamic>? result) async {
    if (result == null || result['user']?['role'] != 'INVESTOR') {
      await _api?.logout();
      throw StateError('An investor account is required');
    }
    _repo.clearLiveData();
    if (Get.isRegistered<ProjectController>()) {
      Get.find<ProjectController>().clearForSession();
    }
    if (Get.isRegistered<NotificationService>()) {
      Get.find<NotificationService>().clear();
    }

    if (result['user'] != null) {
      final user =
          BackendSnapshot.user(result['user'] as Map<String, dynamic>);
      _repo.currentUser.value = user;
      await _storage.writeMap(AppConstants.keyUserData, user.toJson());
    }

    try {
      await _repo.syncFromBackend();
    } catch (_) {
      // Temporary sync delay will retry via AccountSync
    }

    await _storage.setRememberMe(rememberMe.value);
    await _storage.setLoggedIn(true);
    await _storage.setUserEmail(null);
    isLoggedIn.value = true;

    if (Get.isRegistered<FirebaseNotificationService>()) {
      Get.find<FirebaseNotificationService>().syncToken().catchError((_) {});
    }
    if (Get.isRegistered<NotificationService>()) {
      Get.find<NotificationService>().refreshFromBackend().catchError((_) {});
    }
    Get.find<NavigationController>().goToHome();
    Get.offAllNamed(AppRoutes.home);
    return true;
  }

  Future<bool> restoreSession() async {
    if (_api == null) {
      if (_storage.isLoggedIn) {
        isLoggedIn.value = true;
        return true;
      }
      isLoggedIn.value = false;
      return false;
    }

    final refreshToken = await _api.getRefreshToken();
    final accessToken = await _api.getAccessToken();

    // If both tokens are absent, user has no stored credentials
    if ((refreshToken == null || refreshToken.isEmpty) &&
        (accessToken == null || accessToken.isEmpty)) {
      isLoggedIn.value = false;
      _repo.clearLiveData();
      if (Get.isRegistered<ProjectController>()) {
        Get.find<ProjectController>().clearForSession();
      }
      if (Get.isRegistered<NotificationService>()) {
        Get.find<NotificationService>().clear();
      }
      return false;
    }

    try {
      // Verify session with the backend (will auto-refresh access token via interceptor if expired)
      final me = await _api.getMe();
      if (me != null) {
        final status = me['status'] as String?;
        if (status != null && status != 'ACTIVE') {
          // Account suspended or inactive
          await _api.logout().catchError((_) {});
          await _storage.clearSession();
          _repo.clearLiveData();
          isLoggedIn.value = false;
          return false;
        }

        // Active authenticated session verified
        isLoggedIn.value = true;
        await _storage.setLoggedIn(true);

        final user = BackendSnapshot.user(me);
        _repo.currentUser.value = user;
        await _storage.writeMap(AppConstants.keyUserData, user.toJson());

        // Background synchronization
        _repo.syncFromBackend().catchError((_) {});
        if (Get.isRegistered<NotificationService>()) {
          Get.find<NotificationService>().refreshFromBackend().catchError((_) {});
        }
        if (Get.isRegistered<FirebaseNotificationService>()) {
          Get.find<FirebaseNotificationService>().syncToken().catchError((_) {});
        }
        return true;
      }
    } on DioException catch (dioErr) {
      final status = dioErr.response?.statusCode;
      if (status == 401 || status == 403) {
        // Confirmed unrecoverable authentication failure (refresh token expired or revoked)
        await _api.clearTokens();
        await _storage.setLoggedIn(false);
        _repo.clearLiveData();
        isLoggedIn.value = false;
        return false;
      }
      // Temporary network error / offline / timeout / 500 / 429
      // Preserve session if user was previously authenticated!
      if (_storage.isLoggedIn) {
        isLoggedIn.value = true;
        _repo.syncFromBackend().catchError((_) {});
        return true;
      }
      isLoggedIn.value = false;
      return false;
    } catch (_) {
      // Offline / socket exception
      if (_storage.isLoggedIn) {
        isLoggedIn.value = true;
        _repo.syncFromBackend().catchError((_) {});
        return true;
      }
      isLoggedIn.value = false;
      return false;
    }

    // Check if refresh failure cleared tokens during verify
    final remainingToken = await _api.getRefreshToken();
    if (remainingToken == null || remainingToken.isEmpty) {
      _repo.clearLiveData();
      await _storage.setLoggedIn(false);
      isLoggedIn.value = false;
      return false;
    }

    if (_storage.isLoggedIn) {
      isLoggedIn.value = true;
      return true;
    }

    isLoggedIn.value = false;
    return false;
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
    if(Get.isRegistered<ProjectController>())Get.find<ProjectController>().clearForSession();
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
