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
import 'package:investpro/app/views/auth/register_view.dart';

class MockRegistrationApi extends ApiService {
  int registerCallCount = 0;
  Map<String, dynamic>? lastPayload;

  @override
  Future<Map<String, dynamic>?> register({
    required String fullName,
    required String email,
    required String mobileNumber,
    required String password,
  }) async {
    registerCallCount++;
    lastPayload = {
      'fullName': fullName,
      'email': email,
      'mobileNumber': mobileNumber,
      'password': password,
    };
    return {
      'user': {
        'id': 'user_new_123',
        'email': email,
        'fullName': fullName,
        'role': 'INVESTOR',
        'isMobileVerified': true,
      },
      'accessToken': 'test_access_token',
      'refreshToken': 'test_refresh_token',
    };
  }

  @override
  Future<Map<String, dynamic>> sendRegistrationOtp({
    required String mobileNumber,
    String? email,
    String? fullName,
  }) async {
    throw UnsupportedError('sendRegistrationOtp must not be called during OTP-free registration');
  }
}

class MockStorageBackend implements LocalStore {
  final Map<String, dynamic> _store = {};

  @override
  dynamic read(String key) => _store[key];

  @override
  Future<void> write(String key, dynamic value) async {
    _store[key] = value;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('Investor App Registration completes without OTP and navigates to login', (tester) async {
    final api = MockRegistrationApi();
    final storage = LocalStorageService(backend: MockStorageBackend());
    final notifService = NotificationService(storage);
    final repo = DemoRepository(storage, notifService, api);

    Get.put<NavigationController>(NavigationController());
    Get.put<LocalStorageService>(storage);
    Get.put<DemoRepository>(repo);
    Get.put<AuthController>(AuthController(storage, repo, api));

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        initialRoute: AppRoutes.register,
        getPages: [
          GetPage(name: AppRoutes.register, page: () => const RegisterView()),
          GetPage(name: AppRoutes.login, page: () => const Scaffold(body: Text('Login Screen'))),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify RegisterView is rendered
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Mobile Number'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);

    // 2. Verify NO OTP fields, timers or OTP buttons exist
    expect(find.text('Verify OTP'), findsNothing);
    expect(find.text('Send OTP'), findsNothing);
    expect(find.text('Enter OTP'), findsNothing);

    // 3. Enter registration details
    final textFields = find.byType(TextField);
    expect(textFields, findsNWidgets(4));

    await tester.enterText(textFields.at(0), 'Jane Doe');
    await tester.enterText(textFields.at(1), 'jane.doe@example.com');
    await tester.enterText(textFields.at(2), '9876543210');
    await tester.enterText(textFields.at(3), 'Password@123');
    await tester.pumpAndSettle();

    // 4. Tap Register Button
    await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
    await tester.pumpAndSettle();

    // 5. Verify direct API registration was called without OTP
    expect(api.registerCallCount, 1);
    expect(api.lastPayload?['fullName'], 'Jane Doe');
    expect(api.lastPayload?['email'], 'jane.doe@example.com');
    expect(api.lastPayload?['mobileNumber'], '9876543210');
    expect(api.lastPayload?['password'], 'Password@123');

    // 6. Verify navigation directly to Login Screen (no OTP screen appeared)
    expect(find.text('Login Screen'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Validation blocks registration if required fields are missing', (tester) async {
    final api = MockRegistrationApi();
    final storage = LocalStorageService(backend: MockStorageBackend());
    final notifService = NotificationService(storage);
    final repo = DemoRepository(storage, notifService, api);

    Get.put<NavigationController>(NavigationController());
    Get.put<LocalStorageService>(storage);
    Get.put<DemoRepository>(repo);
    Get.put<AuthController>(AuthController(storage, repo, api));

    await tester.pumpWidget(
      GetMaterialApp(
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        initialRoute: AppRoutes.register,
        getPages: [
          GetPage(name: AppRoutes.register, page: () => const RegisterView()),
          GetPage(name: AppRoutes.login, page: () => const Scaffold(body: Text('Login Screen'))),
        ],
      ),
    );
    await tester.pumpAndSettle();

    // Tap Register without filling form
    await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
    await tester.pumpAndSettle();

    // API should NOT be called
    expect(api.registerCallCount, 0);
    // Should still be on Register screen
    expect(find.text('Create Account'), findsOneWidget);

    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
