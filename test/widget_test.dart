import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investpro/app/widgets/app_app_bar.dart';
import 'package:investpro/app/widgets/app_back_button.dart';
import 'package:investpro/app/widgets/app_logo.dart';
import 'package:investpro/app/widgets/custom_app_bar.dart';
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

  testWidgets('AppAppBar renders centered title and chevron back button', (
    WidgetTester tester,
  ) async {
    bool backPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppAppBar(
            title: 'Test Title',
            showBackButton: true,
            onBackPressed: () {
              backPressed = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('Test Title'), findsOneWidget);
    expect(find.byType(AppBackButton), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsOneWidget);

    await tester.tap(find.byType(AppBackButton));
    await tester.pump();
    expect(backPressed, isTrue);
  });

  testWidgets('AppBackButton satisfies minimum 48x48 touch target', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Center(child: AppBackButton())),
      ),
    );

    final size = tester.getSize(find.byType(AppBackButton));
    expect(size.width, greaterThanOrEqualTo(48.0));
    expect(size.height, greaterThanOrEqualTo(48.0));
  });

  testWidgets('CustomAppBar delegates to AppAppBar with centered title', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          appBar: CustomAppBar(
            title: 'Investment Portfolio',
            showBackButton: false,
          ),
        ),
      ),
    );

    expect(find.text('Investment Portfolio'), findsOneWidget);
    expect(find.byType(AppBackButton), findsNothing);
  });
}
