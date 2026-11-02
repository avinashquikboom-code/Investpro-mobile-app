import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investpro/app/controllers/returns_controller.dart';
import 'package:investpro/app/widgets/hourly_market_chart.dart';

void main() {
  List<ReturnChartPoint> points({
    int count = 24,
    double Function(int)? amount,
  }) => [
    for (var hour = 0; hour < count; hour++)
      ReturnChartPoint(
        label:
            '${hour % 12 == 0 ? 12 : hour % 12}:00 ${hour < 12 ? 'AM' : 'PM'}',
        amount: amount?.call(hour) ?? (hour + 1).toDouble(),
        date: DateTime.utc(2026, 11, 2, hour),
      ),
  ];

  Future<void> mount(WidgetTester tester, List<ReturnChartPoint> data) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 700);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: HourlyMarketChart(points: data, isDark: false),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));
  }

  testWidgets(
    'shows only ranges supported by actual hourly points and updates totals',
    (tester) async {
      await mount(tester, points());
      expect(find.byKey(const ValueKey('hour-range-1H')), findsOneWidget);
      expect(find.byKey(const ValueKey('hour-range-6H')), findsOneWidget);
      expect(find.byKey(const ValueKey('hour-range-12H')), findsOneWidget);
      expect(find.byKey(const ValueKey('hour-range-24H')), findsOneWidget);
      expect(find.text('₹300.00'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('hour-range-6H')));
      await tester.pumpAndSettle();
      expect(find.text('₹129.00'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'selecting and dragging across points shows the exact API hour and amount',
    (tester) async {
      await mount(tester, points());
      final chart = find.byKey(
        const ValueKey('hourly-market-chart-interaction'),
      );
      final rect = tester.getRect(chart);
      final gesture = await tester.startGesture(
        Offset(rect.left + 62, rect.center.dy),
      );
      await gesture.moveTo(Offset(rect.right - 4, rect.center.dy));
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('11:00 PM · ₹24.00'), findsOneWidget);
      expect(
        find.textContaining('Selected hour: 11:00 PM · ₹24.00'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('does not invent earnings when the API has no hourly records', (
    tester,
  ) async {
    await mount(tester, const []);
    expect(
      find.text('No hourly wallet credits available for this date'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('hour-range-24H')), findsNothing);
  });

  testWidgets('zero-earning buckets remain zero', (tester) async {
    await mount(tester, points(amount: (_) => 0));
    expect(find.text('₹0.00'), findsWidgets);
    expect(
      find.text('No hourly wallet credits available for this date'),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
