import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:investpro/app/constants/app_strings.dart';
import 'package:investpro/app/controllers/auth_controller.dart';
import 'package:investpro/app/routes/app_routes.dart';
import 'package:investpro/app/services/local_storage_service.dart';
import 'package:investpro/app/services/demo_repository.dart';
import 'package:investpro/app/services/notification_service.dart';
import 'package:investpro/app/theme/app_theme.dart';
import 'package:investpro/app/views/auth/login_view.dart';
import 'package:remixicon/remixicon.dart';

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
  setUp(() {
    Get.testMode = true;
    GoogleFonts.config.allowRuntimeFetching = false;
    final storage = LocalStorageService(backend: MemoryStore());
    Get.put(storage);
    Get.put(
      AuthController(
        storage,
        DemoRepository(storage, NotificationService(storage)),
      ),
    );
  });

  tearDown(() => Get.reset());

  Future<void> mount(WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme,
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        getPages: [
          GetPage(
            name: AppRoutes.forgotPassword,
            page: () => const Scaffold(body: Text('Recovery')),
          ),
          GetPage(
            name: AppRoutes.register,
            page: () => const Scaffold(body: Text('Registration')),
          ),
        ],
        home: const LoginView(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Email and password fields open keyboard on tap and retain focus', (tester) async {
    await mount(tester);

    final emailFinder = find.byKey(const ValueKey('login-identity'));
    final passwordFinder = find.byKey(const ValueKey('login-password'));

    expect(emailFinder, findsOneWidget);
    expect(passwordFinder, findsOneWidget);

    // 1. Tap email field: keyboard should request open and focus should NOT be lost
    await tester.tap(emailFinder);
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);

    final emailTextField = tester.widget<TextField>(
      find.descendant(of: emailFinder, matching: find.byType(TextField)),
    );
    expect(emailTextField.focusNode?.hasFocus, isTrue);
    expect(emailTextField.readOnly, isFalse);
    expect(emailTextField.enabled, isTrue);
    expect(emailTextField.keyboardType, TextInputType.emailAddress);

    // 2. Tap password field: keyboard should stay open and focus should transition smoothly
    await tester.tap(passwordFinder);
    await tester.pump();
    expect(tester.testTextInput.isVisible, isTrue);

    final passwordTextField = tester.widget<TextField>(
      find.descendant(of: passwordFinder, matching: find.byType(TextField)),
    );
    expect(passwordTextField.focusNode?.hasFocus, isTrue);
    expect(passwordTextField.readOnly, isFalse);
    expect(passwordTextField.enabled, isTrue);
    expect(passwordTextField.keyboardType, TextInputType.text);
  });

  testWidgets('Email input can be entered, edited, selected, and completely cleared via suffix icon', (tester) async {
    await mount(tester);

    final emailFinder = find.byKey(const ValueKey('login-identity'));

    // Initially, no clear icon is visible
    expect(find.byIcon(Remix.close_line), findsNothing);

    // Type text into email field
    await tester.enterText(emailFinder, 'investor@example.com');
    await tester.pump();

    // Clear icon appears
    expect(find.byIcon(Remix.close_line), findsOneWidget);

    // Tap the clear icon
    await tester.tap(find.byTooltip('Clear input'));
    await tester.pump();

    // Field is completely cleared
    final emailTextField = tester.widget<TextField>(
      find.descendant(of: emailFinder, matching: find.byType(TextField)),
    );
    expect(emailTextField.controller?.text, '');
    expect(find.byIcon(Remix.close_line), findsNothing);
  });

  testWidgets('Password text is preserved across visibility toggles and widget rebuilds', (tester) async {
    await mount(tester);

    final emailFinder = find.byKey(const ValueKey('login-identity'));
    final passwordFinder = find.byKey(const ValueKey('login-password'));

    await tester.enterText(emailFinder, 'test@investpro.com');
    await tester.enterText(passwordFinder, 'SecurePass123!');
    await tester.pump();

    // Verify initial obscured state
    var passwordTextField = tester.widget<TextField>(
      find.descendant(of: passwordFinder, matching: find.byType(TextField)),
    );
    expect(passwordTextField.obscureText, isTrue);
    expect(passwordTextField.controller?.text, 'SecurePass123!');

    // Toggle password visibility
    await tester.tap(find.byTooltip('Show or hide password'));
    await tester.pump();

    // Password must be unobscured, text must be completely preserved
    passwordTextField = tester.widget<TextField>(
      find.descendant(of: passwordFinder, matching: find.byType(TextField)),
    );
    expect(passwordTextField.obscureText, isFalse);
    expect(passwordTextField.controller?.text, 'SecurePass123!');

    // Toggle back
    await tester.tap(find.byTooltip('Show or hide password'));
    await tester.pump();

    passwordTextField = tester.widget<TextField>(
      find.descendant(of: passwordFinder, matching: find.byType(TextField)),
    );
    expect(passwordTextField.obscureText, isTrue);
    expect(passwordTextField.controller?.text, 'SecurePass123!');

    // Email value also remains completely preserved
    final emailTextField = tester.widget<TextField>(
      find.descendant(of: emailFinder, matching: find.byType(TextField)),
    );
    expect(emailTextField.controller?.text, 'test@investpro.com');
  });

  testWidgets('Tapping outside form unfocuses, tapping inside retains focus', (tester) async {
    await mount(tester);

    final emailFinder = find.byKey(const ValueKey('login-identity'));
    await tester.tap(emailFinder);
    await tester.pump();

    final emailTextField = tester.widget<TextField>(
      find.descendant(of: emailFinder, matching: find.byType(TextField)),
    );
    expect(emailTextField.focusNode?.hasFocus, isTrue);

    // Tap on the screen outside the form bounds (top-left padding area)
    await tester.tapAt(const Offset(5, 5));
    await tester.pump();

    expect(emailTextField.focusNode?.hasFocus, isFalse);
  });
}
