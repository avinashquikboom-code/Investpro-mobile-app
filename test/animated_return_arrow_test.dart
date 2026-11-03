import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investpro/app/models/transaction_model.dart';
import 'package:investpro/app/theme/app_colors.dart';
import 'package:investpro/app/widgets/animated_return_arrow.dart';
import 'package:investpro/app/widgets/recent_activity_item.dart';
import 'package:investpro/app/widgets/transaction_tile.dart';
import 'package:remixicon/remixicon.dart';

void main() {
  group('AnimatedReturnArrow Tests', () {
    testWidgets('renders upward arrow with success green color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AnimatedReturnArrow(),
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedReturnArrow), findsOneWidget);
      final iconFinder = find.byIcon(Remix.arrow_up_line);
      expect(iconFinder, findsOneWidget);

      final Icon iconWidget = tester.widget<Icon>(iconFinder);
      expect(iconWidget.color, AppColors.success);
      expect(iconWidget.size, 20.0);
    });

    testWidgets('floats vertically over time', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AnimatedReturnArrow(
                distance: 6.0,
                duration: Duration(milliseconds: 1000),
                animateInTest: true,
              ),
            ),
          ),
        ),
      );

      final transformFinder = find.descendant(
        of: find.byType(AnimatedReturnArrow),
        matching: find.byType(Transform),
      );
      final initialTranslate = tester.widget<Transform>(transformFinder);
      final initialOffset = (initialTranslate.transform.getTranslation().y);

      // Advance animation halfway
      await tester.pump(const Duration(milliseconds: 500));
      final midTranslate = tester.widget<Transform>(transformFinder);
      final midOffset = (midTranslate.transform.getTranslation().y);

      // Offset changes during animation
      expect(initialOffset != midOffset, isTrue);
    });

    testWidgets('RecentActivityItem displays AnimatedReturnArrow only for returnReceived', (tester) async {
      final returnTxn = TransactionModel(
        id: '1',
        type: TransactionType.returnReceived,
        title: 'Return payout',
        subtitle: 'Website development',
        amount: 0.69,
        date: DateTime.now(),
        referenceId: '723',
      );

      final investTxn = TransactionModel(
        id: '2',
        type: TransactionType.investment,
        title: 'Investment',
        subtitle: 'Tech Park',
        amount: 5000.0,
        date: DateTime.now(),
        referenceId: '724',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                RecentActivityItem(transaction: returnTxn),
                RecentActivityItem(transaction: investTxn),
              ],
            ),
          ),
        ),
      );

      // Return payout has AnimatedReturnArrow
      expect(find.byType(AnimatedReturnArrow), findsOneWidget);
      // Both render upward arrow, but only return payout is AnimatedReturnArrow
      expect(find.byIcon(Remix.arrow_up_line), findsNWidgets(2));
    });

    testWidgets('TransactionTile displays AnimatedReturnArrow only for returnReceived', (tester) async {
      final returnTxn = TransactionModel(
        id: '1',
        type: TransactionType.returnReceived,
        title: 'Return payout',
        subtitle: 'Website development',
        amount: 0.69,
        date: DateTime.now(),
        referenceId: '723',
      );

      final withdrawTxn = TransactionModel(
        id: '3',
        type: TransactionType.withdrawal,
        title: 'Withdrawal',
        subtitle: 'Bank Transfer',
        amount: 100.0,
        date: DateTime.now(),
        referenceId: '725',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TransactionTile(transaction: returnTxn),
                TransactionTile(transaction: withdrawTxn),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(AnimatedReturnArrow), findsOneWidget);
      expect(find.byIcon(Remix.arrow_down_line), findsOneWidget);
    });
  });
}
