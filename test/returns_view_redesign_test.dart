import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:investpro/app/constants/app_strings.dart';
import 'package:investpro/app/controllers/returns_controller.dart';
import 'package:investpro/app/models/return_model.dart';
import 'package:investpro/app/models/user_model.dart';
import 'package:investpro/app/services/demo_repository.dart';
import 'package:investpro/app/services/local_storage_service.dart';
import 'package:investpro/app/services/notification_service.dart';
import 'package:investpro/app/theme/app_theme.dart';
import 'package:investpro/app/views/returns/returns_view.dart';
import 'package:investpro/app/widgets/returns_bar_chart.dart';
import 'package:investpro/app/widgets/status_badge.dart';
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
  late LocalStorageService storage;
  late DemoRepository repo;
  late NotificationService notificationService;
  late ReturnsController returnsCtrl;

  setUp(() {
    Get.testMode = true;
    GoogleFonts.config.allowRuntimeFetching = false;
    storage = LocalStorageService(backend: MemoryStore());
    Get.put(storage);
    notificationService = NotificationService(storage);
    Get.put(notificationService);
    repo = DemoRepository(storage, notificationService);
    Get.put(repo);
    returnsCtrl = ReturnsController(repo);
    Get.put(returnsCtrl);
  });

  tearDown(() {
    Get.reset();
  });

  Future<void> mount(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    bool isTab = true,
  }) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = size;
    tester.view.padding = const FakeViewPadding(top: 44, bottom: 34);

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme,
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: ReturnsView(isTab: isTab),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Renders complete redesigned Returns Screen with real API values', (tester) async {
    repo.currentUser.value = const UserModel(
      id: 'inv-test',
      fullName: 'Vikram Malhotra',
      email: 'vikram@example.com',
      mobileNumber: '+91 9988776655',
    );
    repo.serverTotalInvested.value = 150000.0;
    repo.serverTotalReturns.value = 25000.0;

    repo.returns.assignAll([
      ReturnPayoutModel(
        id: 'ret-1',
        investmentId: 'inv-1',
        projectName: 'Commercial Solar Hub',
        monthYear: 'Mar 2026',
        payoutDate: DateTime(2026, 3, 15),
        amount: 15000.0,
        status: 'Received',
      ),
      ReturnPayoutModel(
        id: 'ret-2',
        investmentId: 'inv-1',
        projectName: 'Commercial Solar Hub',
        monthYear: 'Apr 2026',
        payoutDate: DateTime(2026, 4, 15),
        amount: 10000.0,
        status: 'Received',
      ),
      ReturnPayoutModel(
        id: 'ret-3',
        investmentId: 'inv-1',
        projectName: 'Commercial Solar Hub',
        monthYear: 'Nov 2026',
        payoutDate: DateTime(2026, 11, 15),
        amount: 5000.0,
        status: 'Pending',
      ),
    ]);

    await mount(tester);

    // 1. Header checks
    expect(find.text('Returns'), findsOneWidget);
    expect(find.text('Track your investment returns and payouts'), findsOneWidget);

    // 2. Total Returns Card
    expect(find.text('Total Returns'), findsOneWidget);
    expect(find.text('₹ 25,000'), findsOneWidget);
    expect(find.byIcon(Remix.funds_line), findsWidgets);

    // 3. Period Filter Pills
    expect(find.text('Monthly'), findsOneWidget);
    expect(find.text('Quarterly'), findsOneWidget);
    expect(find.text('Yearly'), findsOneWidget);

    // 4. Interactive Bar Chart
    expect(find.byType(ReturnsBarChart), findsOneWidget);
    expect(find.text('Returns Analytics'), findsOneWidget);
    expect(find.text('Monthly breakdown'), findsOneWidget);

    // 5. Payout History Card
    expect(find.text('Payout History'), findsOneWidget);
    expect(find.text('Commercial Solar Hub'), findsNWidgets(3));
    expect(find.byType(StatusBadge), findsWidgets);
    expect(find.byIcon(Remix.money_rupee_circle_line), findsWidgets);

    // 6. Next Return Date Card
    expect(find.text('Next Return Date'), findsOneWidget);
    expect(find.text('15 Nov 2026'), findsNWidgets(2));
    expect(find.text('Expected: ₹ 5,000'), findsOneWidget);
  });

  testWidgets('Filter selection updates selected period, active tab styling and chart', (tester) async {
    repo.serverTotalReturns.value = 10000.0;
    repo.returns.assignAll([
      ReturnPayoutModel(
        id: 'ret-1',
        investmentId: 'inv-1',
        projectName: 'Solar Park',
        monthYear: 'Jan 2026',
        payoutDate: DateTime(2026, 1, 15),
        amount: 2500.0,
        status: 'Received',
      ),
      ReturnPayoutModel(
        id: 'ret-2',
        investmentId: 'inv-1',
        projectName: 'Solar Park',
        monthYear: 'Feb 2026',
        payoutDate: DateTime(2026, 2, 15),
        amount: 2500.0,
        status: 'Received',
      ),
    ]);

    await mount(tester);

    expect(returnsCtrl.selectedPeriod.value, equals('Monthly'));
    expect(find.text('Monthly breakdown'), findsOneWidget);

    // Tap Quarterly
    await tester.tap(find.text('Quarterly'));
    await tester.pumpAndSettle();

    expect(returnsCtrl.selectedPeriod.value, equals('Quarterly'));
    expect(find.text('Quarterly breakdown'), findsOneWidget);

    // Tap Yearly
    await tester.tap(find.text('Yearly'));
    await tester.pumpAndSettle();

    expect(returnsCtrl.selectedPeriod.value, equals('Yearly'));
    expect(find.text('Yearly breakdown'), findsOneWidget);

    // Tap Monthly back
    await tester.tap(find.text('Monthly'));
    await tester.pumpAndSettle();

    expect(returnsCtrl.selectedPeriod.value, equals('Monthly'));
    expect(find.text('Monthly breakdown'), findsOneWidget);
  });

  testWidgets('Renders empty states correctly when no returns are recorded', (tester) async {
    repo.serverTotalReturns.value = 0.0;
    repo.returns.clear();

    await mount(tester);

    expect(find.text('₹ 0'), findsWidgets);
    expect(find.text('No return payouts found'), findsOneWidget);
    expect(find.text('No upcoming returns scheduled.'), findsOneWidget);
  });

  testWidgets('Responsive across diverse phone and tablet viewports without overflow', (tester) async {
    repo.serverTotalReturns.value = 45000.0;
    repo.returns.assignAll([
      ReturnPayoutModel(
        id: 'ret-1',
        investmentId: 'inv-1',
        projectName: 'Green Hydrogen Plant',
        monthYear: 'Mar 2026',
        payoutDate: DateTime(2026, 3, 10),
        amount: 15000.0,
        status: 'Received',
      ),
      ReturnPayoutModel(
        id: 'ret-2',
        investmentId: 'inv-2',
        projectName: 'IoT Agritech Grid',
        monthYear: 'Dec 2026',
        payoutDate: DateTime(2026, 12, 10),
        amount: 12000.0,
        status: 'Pending',
      ),
    ]);

    final viewports = [
      const Size(320, 568),   // iPhone SE
      const Size(375, 667),   // iPhone 8
      const Size(390, 844),   // iPhone 14
      const Size(430, 932),   // iPhone 14 Pro Max
      const Size(768, 1024),  // iPad
      const Size(800, 1280),  // Android Tablet
      const Size(1024, 1366), // iPad Pro
    ];

    for (final size in viewports) {
      await mount(tester, size: size);
      expect(tester.takeException(), isNull);
    }
  });
}
