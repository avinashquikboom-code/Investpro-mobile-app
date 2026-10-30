import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:investpro/app/constants/app_strings.dart';
import 'package:investpro/app/controllers/auth_controller.dart';
import 'package:investpro/app/controllers/navigation_controller.dart';
import 'package:investpro/app/routes/app_routes.dart';
import 'package:investpro/app/services/api_service.dart';
import 'package:investpro/app/services/demo_repository.dart';
import 'package:investpro/app/services/local_storage_service.dart';
import 'package:investpro/app/services/notification_service.dart';
import 'package:investpro/app/theme/app_theme.dart';
import 'package:investpro/app/views/auth/login_view.dart';

class MemoryStore implements LocalStore {
  final values = <String, dynamic>{};
  @override
  dynamic read(String key) => values[key];
  @override
  Future<void> write(String key, dynamic value) async {
    values[key] = value;
  }
}

class MockApiService extends ApiService {
  String? mockToken;
  Map<String, dynamic>? mockProfile;

  @override
  Future<String?> getAccessToken() async => mockToken;

  @override
  Future<Map<String, dynamic>> login(String identity, String password) async {
    mockToken = 'test-investor-token';
    return {
      'user': {
        'id': 'user-123',
        'email': identity,
        'role': 'INVESTOR',
        'accountStatus': 'ACTIVE',
      },
      'tokens': {
        'accessToken': 'test-investor-token',
        'refreshToken': 'test-investor-refresh',
      },
    };
  }
}

void main() {
  late LocalStorageService storage;
  late MockApiService mockApi;
  late DemoRepository repo;
  late AuthController authCtrl;

  setUp(() {
    Get.testMode = true;
    GoogleFonts.config.allowRuntimeFetching = false;
    final store = MemoryStore();
    storage = LocalStorageService(backend: store);
    Get.put<LocalStorageService>(storage);
    mockApi = MockApiService();
    Get.put<ApiService>(mockApi);
    repo = DemoRepository(storage, NotificationService(storage));
    Get.put(repo);
    Get.put(NavigationController());
    authCtrl = Get.put(AuthController(storage, repo, mockApi));
  });

  tearDown(() => Get.reset());

  Widget buildApp() {
    return GetMaterialApp(
      theme: AppTheme.lightTheme,
      translations: AppTranslations(),
      locale: const Locale('en', 'US'),
      initialRoute: AppRoutes.login,
      getPages: [
        GetPage(name: AppRoutes.login, page: () => const LoginView()),
        GetPage(
          name: AppRoutes.home,
          page: () => const Scaffold(body: Text('Home Destination')),
        ),
      ],
    );
  }

  testWidgets('login fields are strictly empty by default on open even if storage had saved email', (tester) async {
    // Pre-seed storage with a saved email and rememberMe true
    await storage.setRememberMe(true);
    await storage.setUserEmail('investor@saved.com');

    await tester.binding.setSurfaceSize(const Size(800, 1000));
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    final textFields = tester.widgetList<TextField>(find.byType(TextField)).toList();
    expect(textFields.length, 2);

    // Identity field controller must be empty
    expect(textFields[0].controller?.text, isEmpty);
    expect(textFields[0].autofillHints, isNull);
    expect(textFields[0].enableSuggestions, isFalse);
    expect(textFields[0].autocorrect, isFalse);

    // Password field controller must be empty and obscured
    expect(textFields[1].controller?.text, isEmpty);
    expect(textFields[1].obscureText, isTrue);
    expect(textFields[1].autofillHints, isNull);
    expect(textFields[1].enableSuggestions, isFalse);
    expect(textFields[1].autocorrect, isFalse);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('password field toggles visibility and clears on submit', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1000));
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    // Toggle show password
    final toggleButton = find.byTooltip('Show or hide password');
    expect(toggleButton, findsOneWidget);
    expect(authCtrl.isPasswordVisible.value, isFalse);

    await tester.tap(toggleButton);
    await tester.pumpAndSettle();
    expect(authCtrl.isPasswordVisible.value, isTrue);

    // Enter credentials
    final textFormFieldFinders = find.byType(TextFormField);
    await tester.enterText(textFormFieldFinders.at(0), 'investor@example.com');
    await tester.enterText(textFormFieldFinders.at(1), 'SecurePass123!');
    await tester.pumpAndSettle();

    // Submit
    final loginBtn = find.widgetWithText(ElevatedButton, 'Login');
    expect(loginBtn, findsOneWidget);
    await tester.tap(loginBtn);
    await tester.pumpAndSettle();

    // Password visibility must be reset to false after submission
    expect(authCtrl.isPasswordVisible.value, isFalse);

    await tester.binding.setSurfaceSize(null);
  });

  testWidgets('session restoration works without requiring userEmail', (tester) async {
    // Valid token and rememberMe true
    mockApi.mockToken = 'valid-jwt-token';
    repo.currentUser.value = repo.currentUser.value.copyWith(accountStatus: 'ACTIVE');
    await storage.setRememberMe(true);
    // Explicitly verify userEmail is null
    expect(storage.userEmail, isNull);

    final restored = await authCtrl.restoreSession();
    expect(restored, isTrue);
    expect(authCtrl.isLoggedIn.value, isTrue);
  });

  testWidgets('clearSession removes userEmail', (tester) async {
    await storage.setUserEmail('temporary@investpro.com');
    expect(storage.userEmail, 'temporary@investpro.com');

    await storage.clearSession();
    expect(storage.userEmail, isNull);
  });
}
