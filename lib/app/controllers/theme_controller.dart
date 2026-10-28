import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../services/local_storage_service.dart';

class ThemeController extends GetxController {
  final LocalStorageService _storage;

  ThemeController(this._storage);

  final RxString themeModeString = 'system'.obs;

  @override
  void onInit() {
    super.onInit();
    themeModeString.value = _storage.themeMode;
  }

  ThemeMode get currentThemeMode {
    switch (themeModeString.value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  bool get isDarkMode {
    if (themeModeString.value == 'system') {
      return Get.isPlatformDarkMode;
    }
    return themeModeString.value == 'dark';
  }

  void setThemeMode(String mode) {
    themeModeString.value = mode;
    _storage.setThemeMode(mode);
    switch (mode) {
      case 'light':
        Get.changeThemeMode(ThemeMode.light);
        break;
      case 'dark':
        Get.changeThemeMode(ThemeMode.dark);
        break;
      default:
        Get.changeThemeMode(ThemeMode.system);
        break;
    }
  }
}
