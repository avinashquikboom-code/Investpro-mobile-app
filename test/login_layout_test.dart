import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:investpro/app/constants/app_strings.dart';
import 'package:investpro/app/controllers/auth_controller.dart';
import 'package:investpro/app/routes/app_routes.dart';
import 'package:investpro/app/controllers/theme_controller.dart';
import 'package:investpro/app/services/local_storage_service.dart';
import 'package:investpro/app/services/demo_repository.dart';
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

void main() {
  late AuthController auth;
  setUp(() {
    Get.testMode = true;
    GoogleFonts.config.allowRuntimeFetching = false;
    final storage = LocalStorageService(backend: MemoryStore());
    Get.put(storage);
    auth = Get.put(
      AuthController(
        storage,
        DemoRepository(storage, NotificationService(storage)),
      ),
    );
  });
  tearDown(() => Get.reset());

  Future<void> mount(
    WidgetTester tester,
    Size size, {
    double scale = 1,
    double keyboard = 0,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 20);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme,
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        getPages: [
          GetPage(
            name: AppRoutes.forgotPassword,
            page: () => const Scaffold(body: Text('Recovery destination')),
          ),
          GetPage(
            name: AppRoutes.register,
            page: () => const Scaffold(body: Text('Registration destination')),
          ),
        ],
        home: const LoginView(),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final size in [
    const Size(320, 568),
    const Size(375, 667),
    const Size(390, 844),
    const Size(430, 932),
    const Size(800, 1280),
    const Size(1024, 1366),
  ]) {
    for (final keyboard in [0.0, 300.0]) {
      testWidgets('Non-scroll layout $size keyboard $keyboard', (tester) async {
        await mount(tester, size, keyboard: keyboard);
        expect(tester.takeException(), isNull);
        expect(find.byType(SingleChildScrollView), findsNothing);
        expect(find.byType(TextFormField), findsWidgets);
        if (find.text('Next').evaluate().isNotEmpty) {
          await tester.enterText(
            find.byType(TextFormField),
            'investor@example.com',
          );
          await tester.tap(find.text('Next'));
          await tester.pumpAndSettle();
          expect(find.byKey(const ValueKey('login-password')), findsOneWidget);
          expect(tester.takeException(), isNull);
        }
      });
    }
  }
  testWidgets('Accessibility scaling and loading', (tester) async {
    await mount(tester, const Size(320, 568), scale: 2);
    expect(tester.takeException(), isNull);
    auth.isLoading.value = true;
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
      isNull,
    );
  });
  testWidgets(
    'Controller validation and unavailable API errors stay functional',
    (tester) async {
      await mount(tester, const Size(390, 844));
      expect(await auth.login('bad', ''), isFalse);
      await tester.pumpAndSettle();
      expect(find.text('Validation Error'), findsOneWidget);
      Get.closeAllSnackbars();
      await tester.pumpAndSettle();
      expect(await auth.login('investor@example.com', 'Password123'), isFalse);
      await tester.pumpAndSettle();
      expect(auth.isLoading.value, isFalse);
      expect(auth.isLoggedIn.value, isFalse);
      expect(tester.takeException(), isNull);
      Get.closeAllSnackbars();
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'Keyboard transition preserves password, visibility and options',
    (tester) async {
      await mount(tester, const Size(375, 667));
      await tester.enterText(
        find.byKey(const ValueKey('login-identity')),
        'investor@example.com',
      );
      await tester.enterText(
        find.byKey(const ValueKey('login-password')),
        'Password123',
      );
      tester.view.viewInsets = const FakeViewPadding(bottom: 300);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('login-password')), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byTooltip('Show or hide password'));
      await tester.pump();
      expect(auth.isPasswordVisible.value, isTrue);
      await tester.tap(find.text('More options'));
      await tester.pumpAndSettle();
      expect(find.text('Forgot Password?'), findsOneWidget);
      final previous = auth.rememberMe.value;
      await tester.tap(find.byType(Checkbox));
      await tester.pump();
      expect(auth.rememberMe.value, !previous);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
    },
  );
  testWidgets('Large text with keyboard uses compact fields', (tester) async {
    await mount(tester, const Size(320, 568), scale: 2, keyboard: 280);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('login-password')), findsOneWidget);
  });
  testWidgets('Long validation feedback fits the small screen', (tester) async {
    await mount(tester, const Size(320, 568));
    Get.snackbar(
      'Validation Error',
      'Please enter your registered email address or a valid ten digit mobile number before continuing. Check the value and try again.',
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Please enter your registered'), findsOneWidget);
    expect(tester.takeException(), isNull);
    Get.closeAllSnackbars();
    await tester.pumpAndSettle();
  });
  testWidgets('Forgot password and registration retain their routes', (
    tester,
  ) async {
    await mount(tester, const Size(390, 844));
    await tester.tap(find.widgetWithText(TextButton, 'Forgot Password?'));
    await tester.pumpAndSettle();
    expect(find.text('Recovery destination'), findsOneWidget);
    Get.back();
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Create New Account'));
    await tester.pumpAndSettle();
    expect(find.text('Registration destination'), findsOneWidget);
  });
  test('Light theme ignores legacy dark preference', () {
    final controller = ThemeController(Get.find<LocalStorageService>());
    controller.themeModeString.value = 'dark';
    expect(controller.currentThemeMode, ThemeMode.light);
    expect(controller.isDarkMode, isFalse);
    expect(AppTheme.darkTheme.brightness, Brightness.light);
    expect(
      AppTheme.lightTheme.textTheme.bodyMedium?.fontFamily,
      contains('Poppins'),
    );
  });
}
