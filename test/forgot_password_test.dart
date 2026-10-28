import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:investpro/app/views/auth/forgot_password_view.dart';

void main() {
  testWidgets('ForgotPasswordView renders input and request button', (WidgetTester tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(
        home: ForgotPasswordView(),
      ),
    );

    expect(find.text('Forgot Password?'), findsOneWidget);
    expect(find.text('Send Verification Code'), findsOneWidget);
    expect(find.byType(TextFormField), findsOneWidget);
  });
}
