import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/local_storage_service.dart';

class SettingsController extends GetxController {
  final LocalStorageService _storage;

  SettingsController(this._storage);

  final RxString selectedLanguage = 'en_US'.obs;
  final RxBool notificationsEnabled = true.obs;
  final RxBool biometricsEnabled = false.obs;

  @override
  void onInit() {
    super.onInit();
    selectedLanguage.value = _storage.language;
    notificationsEnabled.value = _storage.notificationsEnabled;
    biometricsEnabled.value = _storage.biometricsEnabled;
  }

  void setLanguage(String langCode) {
    selectedLanguage.value = langCode;
    _storage.setLanguage(langCode);

    final parts = langCode.split('_');
    final locale = Locale(parts[0], parts.length > 1 ? parts[1] : null);
    Get.updateLocale(locale);

    Get.snackbar(
      'Language Changed',
      'App language updated to ${getLanguageName(langCode)}',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: const Color(0xFFE8F8F0),
      colorText: const Color(0xFF006B3C),
    );
  }

  String getLanguageName(String code) {
    switch (code) {
      case 'hi_IN':
        return 'हिन्दी (Hindi)';
      case 'mr_IN':
        return 'मराठी (Marathi)';
      default:
        return 'English';
    }
  }

  void toggleNotifications(bool val) {
    notificationsEnabled.value = val;
    _storage.setNotificationsEnabled(val);
  }

  void toggleBiometrics(bool val) {
    biometricsEnabled.value = val;
    _storage.setBiometricsEnabled(val);
    Get.snackbar(
      val ? 'Biometrics Enabled' : 'Biometrics Disabled',
      val
          ? 'Fingerprint / Face ID authentication is active for demo.'
          : 'Biometric login has been deactivated.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }

  void showChangePasswordDialog() {
    final oldPass = TextEditingController();
    final newPass = TextEditingController();
    final confirmPass = TextEditingController();

    Get.defaultDialog(
      title: 'Change Password',
      titleStyle: const TextStyle(fontWeight: FontWeight.bold),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPass,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current Password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPass,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPass,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm New Password'),
            ),
          ],
        ),
      ),
      textConfirm: 'Update',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: const Color(0xFF006B3C),
      onConfirm: () {
        if (newPass.text.length < 6) {
          Get.snackbar('Error', 'Password must be at least 6 characters.',
              snackPosition: SnackPosition.BOTTOM);
          return;
        }
        if (newPass.text != confirmPass.text) {
          Get.snackbar('Error', 'New passwords do not match.',
              snackPosition: SnackPosition.BOTTOM);
          return;
        }
        Get.back();
        Get.snackbar(
          'Password Changed',
          'Your password has been changed successfully.',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: const Color(0xFFE8F8F0),
          colorText: const Color(0xFF006B3C),
        );
      },
    );
  }
}
