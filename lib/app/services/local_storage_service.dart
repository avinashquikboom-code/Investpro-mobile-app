import 'package:get_storage/get_storage.dart';
import '../constants/app_constants.dart';

abstract class LocalStore {
  dynamic read(String key);
  Future<void> write(String key, dynamic value);
}
class LocalStorageService implements LocalStore {
  late final GetStorage _box;
  final LocalStore? backend;
  LocalStorageService({this.backend});
  @override
  dynamic read(String key) => backend != null ? backend!.read(key) : _box.read(key);
  @override
  Future<void> write(String key, dynamic value) => backend != null ? backend!.write(key,value) : _box.write(key,value);
  Future<void> remove(String key) => write(key, null);

  Future<LocalStorageService> init() async {
    if (backend != null) return this;
    await GetStorage.init();
    _box = GetStorage();
    return this;
  }

  // Auth & Session
  bool get isLoggedIn => read(AppConstants.keyIsLoggedIn) ?? false;
  Future<void> setLoggedIn(bool value) => write(AppConstants.keyIsLoggedIn, value);

  bool get rememberMe => read(AppConstants.keyRememberMe) ?? false;
  Future<void> setRememberMe(bool value) => write(AppConstants.keyRememberMe, value);

  String? get userEmail => read(AppConstants.keyUserEmail);
  Future<void> setUserEmail(String? email) => write(AppConstants.keyUserEmail, email);

  // Theme & Settings
  String get themeMode => read(AppConstants.keyThemeMode) ?? 'system';
  Future<void> setThemeMode(String mode) => write(AppConstants.keyThemeMode, mode);

  String get language => read(AppConstants.keyLanguage) ?? 'en_US';
  Future<void> setLanguage(String lang) => write(AppConstants.keyLanguage, lang);

  bool get notificationsEnabled => read(AppConstants.keyNotificationsEnabled) ?? true;
  Future<void> setNotificationsEnabled(bool value) =>
      write(AppConstants.keyNotificationsEnabled, value);

  bool get biometricsEnabled => read(AppConstants.keyBiometricsEnabled) ?? false;
  Future<void> setBiometricsEnabled(bool value) =>
      write(AppConstants.keyBiometricsEnabled, value);

  // Available Balance
  double get availableBalance =>
      (read(AppConstants.keyAvailableBalance) ?? 12480.0).toDouble();
  Future<void> setAvailableBalance(double amount) =>
      write(AppConstants.keyAvailableBalance, amount);

  // Generic JSON List storage
  List<dynamic>? readList(String key) => read(key) as List<dynamic>?;
  Future<void> writeList(String key, List<dynamic> list) => write(key, list);

  // User Data JSON
  Map<String, dynamic>? readMap(String key) => read(key) as Map<String, dynamic>?;
  Future<void> writeMap(String key, Map<String, dynamic> map) => write(key, map);

  // Clear Session
  Future<void> clearSession() async {
    await setLoggedIn(false);
    if (!rememberMe) {
      await setUserEmail(null);
    }
  }

  Future<void> clearAll() => _box.erase();
}
