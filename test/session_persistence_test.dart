import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:google_fonts/google_fonts.dart';
import 'package:investpro/app/controllers/auth_controller.dart';
import 'package:investpro/app/controllers/navigation_controller.dart';
import 'package:investpro/app/services/api_service.dart';
import 'package:investpro/app/services/demo_repository.dart';
import 'package:investpro/app/services/local_storage_service.dart';
import 'package:investpro/app/services/notification_service.dart';

class TestMemoryStore implements LocalStore {
  final Map<String, dynamic> values = <String, dynamic>{};
  @override
  dynamic read(String key) => values[key];
  @override
  Future<void> write(String key, dynamic value) async {
    values[key] = value;
  }
}

class FakeApiService extends ApiService {
  String? currentAccessToken;
  String? currentRefreshToken;
  bool shouldThrowNetworkErrorOnGetMe = false;
  bool shouldThrow401OnGetMe = false;
  bool shouldThrow403OnGetMe = false;
  bool shouldThrow500OnGetMe = false;
  bool shouldFailRefresh = false;
  int refreshCallCount = 0;
  int getMeCallCount = 0;

  FakeApiService({this.currentAccessToken, this.currentRefreshToken});

  @override
  Future<String?> getAccessToken() async => currentAccessToken;

  @override
  Future<String?> getRefreshToken() async => currentRefreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    currentAccessToken = accessToken;
    currentRefreshToken = refreshToken;
  }

  @override
  Future<void> clearTokens() async {
    currentAccessToken = null;
    currentRefreshToken = null;
  }

  @override
  Future<Map<String, dynamic>?> getMe() async {
    getMeCallCount++;
    if (shouldThrowNetworkErrorOnGetMe) {
      throw DioException(
        requestOptions: RequestOptions(path: '/auth/me'),
        type: DioExceptionType.connectionTimeout,
        error: 'Connection timed out',
      );
    }
    if (shouldThrow500OnGetMe) {
      throw DioException(
        requestOptions: RequestOptions(path: '/auth/me'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/me'),
          statusCode: 500,
        ),
        type: DioExceptionType.badResponse,
      );
    }
    if (shouldThrow401OnGetMe) {
      // Simulate expired token: attempt refresh
      if (currentRefreshToken != null && !shouldFailRefresh) {
        refreshCallCount++;
        currentAccessToken = 'refreshed-access-token';
        currentRefreshToken = 'rotated-refresh-token';
        shouldThrow401OnGetMe = false; // Next retry succeeds
        return {
          'id': 'investor-uuid-1',
          'email': 'investor@example.com',
          'role': 'INVESTOR',
          'status': 'ACTIVE',
          'fullName': 'Test Investor',
        };
      }
      throw DioException(
        requestOptions: RequestOptions(path: '/auth/me'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/me'),
          statusCode: 401,
        ),
        type: DioExceptionType.badResponse,
      );
    }
    if (shouldThrow403OnGetMe) {
      throw DioException(
        requestOptions: RequestOptions(path: '/auth/me'),
        response: Response(
          requestOptions: RequestOptions(path: '/auth/me'),
          statusCode: 403,
        ),
        type: DioExceptionType.badResponse,
      );
    }

    return {
      'id': 'investor-uuid-1',
      'email': 'investor@example.com',
      'role': 'INVESTOR',
      'status': 'ACTIVE',
      'fullName': 'Test Investor',
    };
  }

  @override
  Future<Map<String, dynamic>?> login(String emailOrMobile, String password) async {
    currentAccessToken = 'fresh-access-token';
    currentRefreshToken = 'fresh-refresh-token';
    return {
      'user': {
        'id': 'investor-uuid-1',
        'email': emailOrMobile,
        'role': 'INVESTOR',
        'status': 'ACTIVE',
        'fullName': 'Test Investor',
      },
      'accessToken': currentAccessToken,
      'refreshToken': currentRefreshToken,
    };
  }

  @override
  Future<void> logout() async {
    await clearTokens();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestMemoryStore store;
  late LocalStorageService storage;
  late FakeApiService api;
  late DemoRepository repo;
  late NotificationService notifService;
  late AuthController authCtrl;

  setUp(() async {
    Get.testMode = true;
    GoogleFonts.config.allowRuntimeFetching = false;
    store = TestMemoryStore();
    storage = LocalStorageService(backend: store);
    api = FakeApiService();
    notifService = NotificationService(storage, api);
    repo = DemoRepository(storage, notifService, api);
    if (!Get.isRegistered<NavigationController>()) {
      Get.put<NavigationController>(NavigationController(), permanent: true);
    }
    authCtrl = AuthController(storage, repo, api);
    Get.put<AuthController>(authCtrl, permanent: true);
  });

  tearDown(() {
    Get.reset();
  });

  test('1. User logs in successfully and session is persisted in storage and memory', () async {
    expect(authCtrl.isLoggedIn.value, isFalse);
    expect(storage.isLoggedIn, isFalse);

    final success = await authCtrl.login('investor@example.com', 'ValidPassword123');
    expect(success, isTrue);
    expect(authCtrl.isLoggedIn.value, isTrue);
    expect(storage.isLoggedIn, isTrue);
    expect(api.currentAccessToken, 'fresh-access-token');
    expect(api.currentRefreshToken, 'fresh-refresh-token');
  });

  test('2. Reopening app with valid credentials restores session without showing login', () async {
    api.currentAccessToken = 'stored-access-token';
    api.currentRefreshToken = 'stored-refresh-token';
    await storage.setLoggedIn(true);

    final restored = await authCtrl.restoreSession();
    expect(restored, isTrue);
    expect(authCtrl.isLoggedIn.value, isTrue);
    expect(api.getMeCallCount, 1);
  });

  test('3. Reopening app offline (network error) preserves stored session without logout', () async {
    api.currentAccessToken = 'stored-access-token';
    api.currentRefreshToken = 'stored-refresh-token';
    api.shouldThrowNetworkErrorOnGetMe = true;
    await storage.setLoggedIn(true);

    final restored = await authCtrl.restoreSession();
    // Must preserve session and remain logged in despite timeout/offline
    expect(restored, isTrue);
    expect(authCtrl.isLoggedIn.value, isTrue);
    expect(storage.isLoggedIn, isTrue);
    // Tokens must NOT be erased
    expect(api.currentAccessToken, 'stored-access-token');
    expect(api.currentRefreshToken, 'stored-refresh-token');
  });

  test('4. Server 500 error preserves stored session without logging out', () async {
    api.currentAccessToken = 'stored-access-token';
    api.currentRefreshToken = 'stored-refresh-token';
    api.shouldThrow500OnGetMe = true;
    await storage.setLoggedIn(true);

    final restored = await authCtrl.restoreSession();
    expect(restored, isTrue);
    expect(authCtrl.isLoggedIn.value, isTrue);
    expect(api.currentAccessToken, isNotNull);
  });

  test('5. Expired access token is automatically refreshed using valid refresh token', () async {
    api.currentAccessToken = 'expired-access-token';
    api.currentRefreshToken = 'valid-refresh-token';
    api.shouldThrow401OnGetMe = true; // Triggers refresh
    await storage.setLoggedIn(true);

    final restored = await authCtrl.restoreSession();
    expect(restored, isTrue);
    expect(authCtrl.isLoggedIn.value, isTrue);
    expect(api.refreshCallCount, 1);
    expect(api.currentAccessToken, 'refreshed-access-token');
    expect(api.currentRefreshToken, 'rotated-refresh-token');
  });

  test('6. Definitively expired or revoked refresh token (401) clears session and rejects restore', () async {
    api.currentAccessToken = 'expired-access-token';
    api.currentRefreshToken = 'revoked-refresh-token';
    api.shouldThrow401OnGetMe = true;
    api.shouldFailRefresh = true; // Refresh itself returns 401
    await storage.setLoggedIn(true);

    final restored = await authCtrl.restoreSession();
    expect(restored, isFalse);
    expect(authCtrl.isLoggedIn.value, isFalse);
    expect(storage.isLoggedIn, isFalse);
    expect(api.currentAccessToken, isNull);
    expect(api.currentRefreshToken, isNull);
  });

  test('7. App launch with no credentials cleanly returns false for Login presentation', () async {
    api.currentAccessToken = null;
    api.currentRefreshToken = null;
    await storage.setLoggedIn(false);

    final restored = await authCtrl.restoreSession();
    expect(restored, isFalse);
    expect(authCtrl.isLoggedIn.value, isFalse);
  });

  test('8. Suspended account (status != ACTIVE) is logged out and rejected', () async {
    api.currentAccessToken = 'valid-token';
    api.currentRefreshToken = 'valid-refresh';
    await storage.setLoggedIn(true);
    // User profile status is SUSPENDED
    api.shouldThrow403OnGetMe = true;

    final restored = await authCtrl.restoreSession();
    expect(restored, isFalse);
    expect(authCtrl.isLoggedIn.value, isFalse);
    expect(storage.isLoggedIn, isFalse);
  });
}
