import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:investpro/app/controllers/forgot_password_controller.dart';
import 'package:investpro/app/services/api_service.dart';
import 'package:investpro/app/views/auth/forgot_password_view.dart';
import 'package:investpro/app/widgets/app_app_bar.dart';
import 'package:investpro/app/widgets/custom_button.dart';
import 'package:investpro/app/widgets/custom_text_field.dart';

class MockPasswordResetApi extends ApiService {
  bool failNext = false;
  String? sentIdentifier;
  String? verifiedOtp;
  String? resetNewPass;

  @override
  Future<Map<String, dynamic>?> forgotPassword(String identifier) async {
    if (failNext) throw Exception('Network error');
    sentIdentifier = identifier;
    return {'cooldownSeconds': 60, 'debugOtp': '123456'};
  }

  @override
  Future<Map<String, dynamic>?> verifyResetCode({
    required String identifier,
    required String otp,
  }) async {
    if (failNext) throw Exception('Invalid code');
    sentIdentifier = identifier;
    verifiedOtp = otp;
    return {'success': true};
  }

  @override
  Future<Map<String, dynamic>?> resetPassword({
    required String identifier,
    required String otp,
    required String newPassword,
  }) async {
    if (failNext) throw Exception('Reset failed');
    sentIdentifier = identifier;
    verifiedOtp = otp;
    resetNewPass = newPassword;
    return {'success': true};
  }
}

void main() {
  setUp(() {
    Get.reset();
  });

  tearDown(() {
    Get.reset();
  });

  group('ForgotPasswordController Unit Tests', () {
    test('Validates empty, email, phone, and invalid identifiers', () {
      final controller = ForgotPasswordController();

      // Empty
      expect(
        controller.validateIdentifier(''),
        contains('Please enter your registered email or mobile number'),
      );
      expect(
        controller.validateIdentifier('   '),
        contains('Please enter your registered email or mobile number'),
      );

      // Invalid email
      expect(
        controller.validateIdentifier('notanemail@'),
        contains('valid email address'),
      );

      // Valid email
      expect(controller.validateIdentifier('investor@investpro.com'), isNull);

      // Short phone
      expect(
        controller.validateIdentifier('12345'),
        contains('valid 10-digit mobile number'),
      );

      // Valid 10-digit phone
      expect(controller.validateIdentifier('9876543210'), isNull);
      expect(controller.validateIdentifier('+91 98765 43210'), isNull);
    });

    test('Validates OTP length and empty input', () {
      final controller = ForgotPasswordController();
      expect(
        controller.validateOtp(''),
        contains('Please enter the verification code'),
      );
      expect(
        controller.validateOtp('12'),
        contains('at least 4 digits'),
      );
      expect(controller.validateOtp('123456'), isNull);
    });

    test('Validates password length and matching passwords', () {
      final controller = ForgotPasswordController();
      expect(
        controller.validatePasswords('short', 'short'),
        contains('at least 8 characters'),
      );
      expect(
        controller.validatePasswords('password123', 'different123'),
        contains('Passwords do not match'),
      );
      expect(
        controller.validatePasswords('validPass@2026', 'validPass@2026'),
        isNull,
      );
    });

    test('Complete step progression with Mock API', () async {
      final mockApi = MockPasswordResetApi();
      final controller = ForgotPasswordController(mockApi);

      expect(controller.currentStep.value, 0);

      // 1. Send Reset Code
      controller.identifier.value = 'investor@example.com';
      final sent = await controller.sendResetCode();
      expect(sent, isTrue);
      expect(controller.currentStep.value, 1);
      expect(mockApi.sentIdentifier, 'investor@example.com');
      expect(controller.resendCooldown.value, 60);

      // 2. Verify Code
      controller.otp.value = '123456';
      final verified = await controller.verifyResetCode();
      expect(verified, isTrue);
      expect(controller.currentStep.value, 2);
      expect(mockApi.verifiedOtp, '123456');

      // 3. Reset Password
      controller.newPassword.value = 'NewSecurePassword@123';
      controller.confirmPassword.value = 'NewSecurePassword@123';
      final reset = await controller.resetPassword();
      expect(reset, isTrue);
      expect(controller.currentStep.value, 3);
      expect(mockApi.resetNewPass, 'NewSecurePassword@123');

      // Step-back navigation
      controller.previousStep();
      expect(controller.currentStep.value, 3); // step 3 is success; cannot step back

      controller.onClose();
    });
  });

  group('ForgotPasswordView UI & Layout Tests', () {
    testWidgets('Renders top-aligned layout without vertical centering gap', (
      WidgetTester tester,
    ) async {
      final mockApi = MockPasswordResetApi();
      Get.put<ApiService>(mockApi);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: Scaffold(body: ForgotPasswordView()),
        ),
      );
      await tester.pumpAndSettle();

      // Verify AppAppBar exists
      expect(find.byType(AppAppBar), findsOneWidget);

      // Verify Align with Alignment.topCenter exists
      final alignFinder = find.byWidgetPredicate(
        (widget) => widget is Align && widget.alignment == Alignment.topCenter,
      );
      expect(alignFinder, findsWidgets);

      // Verify ConstrainedBox with maxWidth: 480 exists
      final constraintFinder = find.byWidgetPredicate(
        (widget) =>
            widget is ConstrainedBox &&
            widget.constraints.maxWidth == 480.0,
      );
      expect(constraintFinder, findsWidgets);

      // Verify content is positioned naturally near top below the AppBar
      final titlePosition = tester.getTopLeft(find.text('Forgot Password?'));
      expect(titlePosition.dy, lessThan(250.0));

      // Verify form elements exist
      expect(find.text('Send Verification Code'), findsOneWidget);
      expect(find.text('Back to Login'), findsOneWidget);
      expect(find.byType(CustomTextField), findsOneWidget);
    });

    testWidgets('Full UI progression from Step 0 to Step 3', (
      WidgetTester tester,
    ) async {
      final mockApi = MockPasswordResetApi();
      Get.put<ApiService>(mockApi);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: Scaffold(body: ForgotPasswordView()),
        ),
      );
      await tester.pumpAndSettle();

      // Step 0: Request Code
      expect(find.text('Forgot Password?'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), 'test@investpro.com');
      await tester.tap(find.widgetWithText(CustomButton, 'Send Verification Code'));
      await tester.pumpAndSettle();

      // Step 1: Verify Code
      expect(find.widgetWithText(CustomButton, 'Verify Code'), findsOneWidget);
      expect(find.text('Verification Code'), findsOneWidget);
      await tester.enterText(find.byType(TextFormField), '654321');
      await tester.tap(find.widgetWithText(CustomButton, 'Verify Code'));
      await tester.pumpAndSettle();

      // Step 2: New Password
      expect(find.text('Create New Password'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm New Password'), findsOneWidget);

      final textFields = find.byType(TextFormField);
      expect(textFields, findsNWidgets(2));
      await tester.enterText(textFields.at(0), 'UpdatedSecret@999');
      await tester.enterText(textFields.at(1), 'UpdatedSecret@999');
      await tester.tap(find.widgetWithText(CustomButton, 'Reset Password'));
      await tester.pumpAndSettle();

      // Step 3: Success
      expect(find.text('Password Reset Successful!'), findsOneWidget);
      expect(find.widgetWithText(CustomButton, 'Back to Login'), findsOneWidget);

      await tester.pumpAndSettle(const Duration(seconds: 4));
    });

    testWidgets('Responsive constraint on tablet screen sizes', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1024, 1366);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final mockApi = MockPasswordResetApi();
      Get.put<ApiService>(mockApi);

      await tester.pumpWidget(
        const GetMaterialApp(
          home: Scaffold(body: ForgotPasswordView()),
        ),
      );
      await tester.pumpAndSettle();

      final boxFinder = find.byWidgetPredicate(
        (w) => w is ConstrainedBox && w.constraints.maxWidth == 480.0,
      );
      expect(boxFinder, findsWidgets);

      // Verify form width is constrained to 480 and does not stretch to full 1024
      final renderBox = tester.renderObject(boxFinder.first) as RenderBox;
      expect(renderBox.size.width, lessThanOrEqualTo(480.0));
    });
  });
}
