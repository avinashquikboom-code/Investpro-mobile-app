import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investpro/app/widgets/app_logo.dart';
import 'package:investpro/app/widgets/custom_button.dart';
import 'package:investpro/app/widgets/status_badge.dart';

void main() {
  testWidgets('AppLogo renders properly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AppLogo(showText: true))),
    );

    expect(find.text('InvestPro'), findsOneWidget);
  });

  testWidgets('CustomButton renders text and triggers callback', (
    WidgetTester tester,
  ) async {
    bool tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CustomButton(
            text: 'Invest Now',
            onPressed: () {
              tapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Invest Now'), findsOneWidget);
    await tester.tap(find.text('Invest Now'));
    await tester.pump();

    expect(tapped, isTrue);
  });

  testWidgets('StatusBadge displays status label and styles', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: StatusBadge(status: 'Active', showDot: true)),
      ),
    );

    expect(find.text('Active'), findsOneWidget);
  });
}
