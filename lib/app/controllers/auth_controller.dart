import 'subscription_controller.dart';
import 'dart:async';
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

  final onboardingPending = false.obs;
  String? _onboardingUserId;
  String get authenticatedRoute => onboardingPending.value ? AppRoutes.subscriptionOnboarding : AppRoutes.home;
  final RxBool isLoggedIn = false.obs;
  final RxBool rememberMe = true.obs;
  final RxBool isPasswordVisible = false.obs;
  final RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    isLoggedIn.value = _storage.isLoggedIn;
    _onboardingUserId = _storage.read('onboarding_account_id') as String?;
    if (_onboardingUserId != null) onboardingPending.value = _storage.read('subscription_onboarding_$_onboardingUserId') == true;
    rememberMe.value = _storage.rememberMe;
    if (_api != null) _api.onSessionExpired = _sessionExpired;
  }

  void _sessionExpired() {
    isLoggedIn.value = false;
    _repo.clearLiveData();
    if (Get.isRegistered<SubscriptionController>()) Get.find<SubscriptionController>().clearForSession();
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

  Future<bool> _finish(Map<String, dynamic>? result, {bool registration = false}) async {
    if (result == null || result['user']?['role'] != 'INVESTOR') {
      await _api?.logout();
      throw StateError('An investor account is required');
    }
    _repo.clearLiveData();
    if (Get.isRegistered<SubscriptionController>()) Get.find<SubscriptionController>().clearForSession();
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
    _onboardingUserId = result['user']['id'].toString();
    await _storage.write('onboarding_account_id', _onboardingUserId);
    if (registration) { onboardingPending.value = true; await _storage.write('subscription_onboarding_$_onboardingUserId', true); }
    await refreshOnboarding();
    Get.find<NavigationController>().goToHome();
    Get.offAllNamed(authenticatedRoute);
    return true;
  }

  Future<void> refreshOnboarding() async {
    if (_api == null || _onboardingUserId == null) return;
    final owner = _onboardingUserId;
    final queued = _storage.read('subscription_skip_pending_$owner') == true;
    try {
      if (queued) { await _api.skipSubscriptionOnboarding(); await _storage.write('subscription_skip_pending_$owner', false); }
      final result = await _api.getOnboarding();
      if (_onboardingUserId != owner || !isLoggedIn.value) return;
      onboardingPending.value = result['requiresPlanSelection'] == true;
      await _storage.write('subscription_onboarding_$owner', onboardingPending.value);
    } catch (_) {
      if (_onboardingUserId == owner) onboardingPending.value = queued ? false : _storage.read('subscription_onboarding_$owner') == true;
    }
  }
  Future<bool> finishSubscriptionOnboarding({bool skipped = false}) async {
    final owner = _onboardingUserId;
    if (owner == null || !isLoggedIn.value) return false;
    if (skipped && _api != null) {
      try { await _api.skipSubscriptionOnboarding(); await _storage.write('subscription_skip_pending_$owner', false); }
      catch (_) { if (!isLoggedIn.value) return false; await _storage.write('subscription_skip_pending_$owner', true); }
    }
    if (!isLoggedIn.value || owner != _onboardingUserId) return false;
    onboardingPending.value = false;
    await _storage.write('subscription_onboarding_$owner', false);
    Get.find<NavigationController>().goToHome();
    Get.offAllNamed(AppRoutes.home);
    return true;
  }
  Future<bool> verifyRegistration({required String fullName, required String email, required String mobileNumber, required String password, String? otp}) async {
    if (isLoading.value || _api == null) return false;
    isLoading.value = true;
    try {
      final result = await _api.register(fullName: fullName, email: email, mobileNumber: mobileNumber, password: password);
      return await _finish(result, registration: true);
    } catch (_) { Get.snackbar('Unable to complete registration', 'Check your details and connection.'); return false; }
    finally { isLoading.value = false; }
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

        _onboardingUserId = me['id'].toString();
        await _storage.write('onboarding_account_id', _onboardingUserId);
        onboardingPending.value = _storage.read('subscription_onboarding_$_onboardingUserId') == true;
        await refreshOnboarding();

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
      final result = await _api.register(
        fullName: fullName.trim(),
        email: email.trim(),
        mobileNumber: mobileNumber.trim(),
        password: password,
      );
      if (result != null) {
        Get.snackbar(
          'Registration Successful',
          'Account created successfully. Please sign in to continue.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFF00854B),
          colorText: Colors.white,
        );
        Get.offAllNamed(AppRoutes.login);
        return true;
      }
      return false;
    } catch (e) {
      isLoggedIn.value = false;
      final msg = e.toString().replaceFirst('Exception: ', '').replaceFirst('StateError: ', '');
      Get.snackbar(
        'Unable to complete registration',
        msg.contains('already exists')
            ? msg
            : 'Check your connection and account details. If registration succeeded, sign in to load the account.',
      );
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
      if (Get.isRegistered<SubscriptionController>()) Get.find<SubscriptionController>().clearForSession();
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
