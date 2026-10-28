import 'package:get_storage/get_storage.dart';
import '../constants/app_constants.dart';

abstract class LocalStore {
  dynamic read(String key);
  Future<void> write(String key, dynamic value);
}
class LocalStorageService implements LocalStore {
  late final GetStorage _box;
  @override
  dynamic read(String key) => _box.read(key);
  @override
  Future<void> write(String key, dynamic value) => _box.write(key, value);

  Future<LocalStorageService> init() async {
    await GetStorage.init();
    _box = GetStorage();
    return this;
  }

  // Auth & Session
  bool get isLoggedIn => _box.read<bool>(AppConstants.keyIsLoggedIn) ?? false;
  Future<void> setLoggedIn(bool value) => _box.write(AppConstants.keyIsLoggedIn, value);

  bool get rememberMe => _box.read<bool>(AppConstants.keyRememberMe) ?? false;
  Future<void> setRememberMe(bool value) => _box.write(AppConstants.keyRememberMe, value);

  String? get userEmail => _box.read<String>(AppConstants.keyUserEmail);
  Future<void> setUserEmail(String? email) => _box.write(AppConstants.keyUserEmail, email);

  // Theme & Settings
  String get themeMode => _box.read<String>(AppConstants.keyThemeMode) ?? 'system';
  Future<void> setThemeMode(String mode) => _box.write(AppConstants.keyThemeMode, mode);

  String get language => _box.read<String>(AppConstants.keyLanguage) ?? 'en_US';
  Future<void> setLanguage(String lang) => _box.write(AppConstants.keyLanguage, lang);

  bool get notificationsEnabled => _box.read<bool>(AppConstants.keyNotificationsEnabled) ?? true;
  Future<void> setNotificationsEnabled(bool value) =>
      _box.write(AppConstants.keyNotificationsEnabled, value);

  bool get biometricsEnabled => _box.read<bool>(AppConstants.keyBiometricsEnabled) ?? false;
  Future<void> setBiometricsEnabled(bool value) =>
      _box.write(AppConstants.keyBiometricsEnabled, value);

  // Available Balance
  double get availableBalance =>
      (_box.read<num>(AppConstants.keyAvailableBalance) ?? 12480.0).toDouble();
  Future<void> setAvailableBalance(double amount) =>
      _box.write(AppConstants.keyAvailableBalance, amount);

  // Generic JSON List storage
  List<dynamic>? readList(String key) => _box.read<List<dynamic>>(key);
  Future<void> writeList(String key, List<dynamic> list) => _box.write(key, list);

  // User Data JSON
  Map<String, dynamic>? readMap(String key) => _box.read<Map<String, dynamic>>(key);
  Future<void> writeMap(String key, Map<String, dynamic> map) => _box.write(key, map);

  // Clear Session
  Future<void> clearSession() async {
    await setLoggedIn(false);
    if (!rememberMe) {
      await setUserEmail(null);
    }
  }

  Future<void> clearAll() => _box.erase();
}
