import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/local_storage_service.dart';

/// Investor branding always uses light surfaces, including on dark devices.
class ThemeController extends GetxController {
  final LocalStorageService _storage;
  ThemeController(this._storage);
  final RxString themeModeString = 'light'.obs;

  @override
  void onInit() {
    super.onInit();
    _storage.setThemeMode('light');
  }

  ThemeMode get currentThemeMode {
    // Keep the existing reactive app root subscribed.
    themeModeString.value;
    return ThemeMode.light;
  }

  bool get isDarkMode => false;

  void setThemeMode(String mode) {
    themeModeString.value = 'light';
    _storage.setThemeMode('light');
    Get.changeThemeMode(ThemeMode.light);
  }
}
