import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investpro/app/views/returns/interest_breakdown_section.dart';

void main() {
  group('Interest Breakdown Calculations', () {
    test('Calculates exact monthly, daily, hourly and minute interest for ₹10,000 at 12%', () {
      final breakdown = InvestmentInterestBreakdown.calculate(
        investmentId: 'INV-TEST-001',
        projectId: 'PRJ-001',
        projectName: 'Solar Park Phase 1',
        principal: 10000.0,
        monthlyRate: 12.0,
      );

      // Expected calculation:
      // Monthly: ₹1,200
      expect(breakdown.monthlyInterest, equals(1200.0));
      expect(InterestFormatter.formatMonthly(breakdown.monthlyInterest), equals('₹1,200.00'));

      // Daily: ₹40
      expect(breakdown.dailyInterest, equals(40.0));
      expect(InterestFormatter.formatDaily(breakdown.dailyInterest), equals('₹40.00'));

      // Hourly: 40 / 24 = 1.666666...
      expect(breakdown.hourlyInterest, closeTo(1.6667, 0.0001));
      expect(InterestFormatter.formatHourly(breakdown.hourlyInterest), equals('₹1.67'));

      // Minute: 1.666666... / 60 = 0.027777...
      expect(breakdown.minuteInterest, closeTo(0.02778, 0.00001));
      expect(InterestFormatter.formatMinute(breakdown.minuteInterest), equals('₹0.03'));
    });

    test('Does not round intermediate calculations before deriving smaller time intervals', () {
      final breakdown = InvestmentInterestBreakdown.calculate(
        investmentId: 'INV-TEST-002',
        projectId: 'PRJ-002',
        projectName: 'Hydroponics Farm',
        principal: 25000.0,
        monthlyRate: 1.5,
      );

      // Monthly: 25000 * 1.5 / 100 = 375
      expect(breakdown.monthlyInterest, equals(375.0));
      // Daily: 375 / 30 = 12.5
      expect(breakdown.dailyInterest, equals(12.5));
      // Hourly: 12.5 / 24 = 0.5208333...
      expect(breakdown.hourlyInterest, closeTo(0.5208, 0.0001));
      // Minute: 0.5208333... / 60 = 0.00868055...
      expect(breakdown.minuteInterest, closeTo(0.008681, 0.00001));
    });

    test('Sum of individual active hourly interest equals combined hourly rate', () {
      final inv1 = InvestmentInterestBreakdown.calculate(
        investmentId: 'INV-1',
        projectId: 'PRJ-1',
        projectName: 'Project A',
        principal: 10000.0,
        monthlyRate: 12.0,
      );
      final inv2 = InvestmentInterestBreakdown.calculate(
        investmentId: 'INV-2',
        projectId: 'PRJ-2',
        projectName: 'Project B',
        principal: 20000.0,
        monthlyRate: 10.0, // 20000 * 10 / 100 = 2000 monthly
      );

      final combinedHourly = inv1.hourlyInterest + inv2.hourlyInterest;
      // inv1: 1200 / 720 = 1.6666667
      // inv2: 2000 / 720 = 2.7777778
      // sum = 3200 / 720 = 4.4444444
      expect(combinedHourly, closeTo(3200.0 / 720.0, 0.0001));
    });
  });

  group('InterestBreakdownSection Widget Test', () {
    testWidgets('Renders table with Duration and Interest columns and calculated amounts', (tester) async {
      final snapshot = {
        'interestBreakdown': {
          'activeInvestmentsCount': 1,
          'totalPrincipal': 10000.0,
          'investments': [
            {
              'investmentId': 'INV-100',
              'id': 'uuid-100',
              'projectId': 'prj-100',
              'projectName': 'Solar Park Phase 1',
              'principal': 10000.0,
              'monthlyRate': 12.0,
              'monthlyInterest': 1200.0,
              'dailyInterest': 40.0,
              'hourlyInterest': 1.6667,
              'minuteInterest': 0.02778,
              'status': 'ACTIVE',
            }
          ]
        }
      };

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: InterestBreakdownSection(
                snapshot: snapshot,
                isDark: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check section header
      expect(find.text('📊 Daily, Hourly and Minute Interest'), findsOneWidget);

      // Check table column headers
      expect(find.text('Duration'), findsOneWidget);
      expect(find.text('Interest'), findsOneWidget);

      // Check table rows
      expect(find.text('1 Month (30 days)'), findsOneWidget);
      expect(find.text('₹1,200.00'), findsOneWidget);

      expect(find.text('1 Day'), findsOneWidget);
      expect(find.text('₹40.00'), findsOneWidget);

      expect(find.text('1 Hour'), findsOneWidget);
      expect(find.text('₹1.67'), findsOneWidget);

      expect(find.text('1 Minute'), findsOneWidget);
      expect(find.text('₹0.03'), findsOneWidget);
    });
  });
}

