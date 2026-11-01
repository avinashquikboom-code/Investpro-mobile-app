import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investpro/app/views/returns/monthly_payout_schedule_card.dart';

void main() {
  testWidgets('monthly schedule separates interest and principal without claiming future credits', (tester) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: MonthlyPayoutScheduleCard(schedules: [
      {'projectName': 'Project', 'installmentNumber': 1, 'dueDate': '2027-01-31', 'profitAmount': '1000.00', 'principalAmount': '0.00', 'totalAmount': '1000.00', 'status': 'SCHEDULED'},
      {'projectName': 'Project', 'installmentNumber': 12, 'dueDate': '2027-12-31', 'profitAmount': '1000.00', 'principalAmount': '10000.00', 'totalAmount': '11000.00', 'status': 'SCHEDULED'},
    ])))));
    await tester.tap(find.text('Monthly payout schedule'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Interest: '), findsNWidgets(2));
    expect(find.textContaining('Principal: '), findsNWidgets(2));
    expect(find.textContaining('Total payment: '), findsNWidgets(2));
    expect(find.textContaining('Upcoming'), findsNWidgets(2));
    expect(find.textContaining('Only successfully confirmed payouts'), findsOneWidget);
    expect(find.textContaining('Final maturity payout'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
