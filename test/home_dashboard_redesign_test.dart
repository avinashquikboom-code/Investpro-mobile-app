import 'package:remixicon/remixicon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:investpro/app/constants/app_strings.dart';
import 'package:investpro/app/controllers/auth_controller.dart';
import 'package:investpro/app/controllers/home_controller.dart';
import 'package:investpro/app/controllers/navigation_controller.dart';
import 'package:investpro/app/controllers/project_controller.dart';
import 'package:investpro/app/controllers/theme_controller.dart';
import 'package:investpro/app/models/investment_model.dart';
import 'package:investpro/app/models/transaction_model.dart';
import 'package:investpro/app/models/user_model.dart';
import 'package:investpro/app/services/demo_repository.dart';
import 'package:investpro/app/services/local_storage_service.dart';
import 'package:investpro/app/services/notification_service.dart';
import 'package:investpro/app/theme/app_theme.dart';
import 'package:investpro/app/views/home/home_view.dart';
import 'package:investpro/app/widgets/project_card.dart';
import 'package:investpro/app/widgets/recent_activity_item.dart';
import 'package:investpro/app/widgets/summary_card.dart';

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

  setUp(() {
    Get.testMode = true;
    GoogleFonts.config.allowRuntimeFetching = false;
    storage = LocalStorageService(backend: MemoryStore());
    Get.put(storage);
    notificationService = NotificationService(storage);
    Get.put(notificationService);
    repo = DemoRepository(storage, notificationService);
    Get.put(repo);
    Get.put(AuthController(storage, repo));
    Get.put(HomeController(repo, notificationService));
    Get.put(ThemeController(storage));
    Get.put(NavigationController());
    Get.put(ProjectController(repo));
  });

  tearDown(() {
    Get.reset();
  });

  Future<void> mount(WidgetTester tester, {Size size = const Size(390, 844)}) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = size;
    tester.view.padding = const FakeViewPadding(top: 44, bottom: 34);

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme,
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const HomeView(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Renders complete redesigned Home Dashboard with live data', (tester) async {
    repo.currentUser.value = const UserModel(
      id: 'inv-rohit',
      fullName: 'Rohit Sharma',
      email: 'rohit@example.com',
      mobileNumber: '+91 9876543210',
      accountStatus: 'ACTIVE',
      kycStatus: 'VERIFIED',
    );
    repo.serverTotalInvested.value = 100000.0;
    repo.serverTotalReturns.value = 18000.0;
    repo.availableBalance.value = 7000.0;

    repo.investments.assignAll([
      InvestmentModel(
        id: 'inv-1',
        projectId: 'proj-solar',
        projectName: 'Solar Park Phase 1',
        iconType: 'solar',
        investedAmount: 100000.0,
        returnRatePercent: 18.0,
        durationMonths: 12,
        expectedReturn: 18000.0,
        maturityAmount: 118000.0,
        startDate: DateTime(2026, 1, 1),
        maturityDate: DateTime(2027, 1, 1),
        progressPercent: 25.0,
        status: 'Active',
      ),
    ]);

    repo.transactions.assignAll([
      TransactionModel(
        id: 'tx-1',
        type: TransactionType.returnReceived,
        title: 'Return Credited',
        subtitle: 'Monthly return for Solar Park Phase 1',
        amount: 1500.0,
        date: DateTime(2026, 3, 1, 10, 30),
        status: 'Completed',
        direction: 'CREDIT',
        referenceId: 'TXN-1001',
      ),
      TransactionModel(
        id: 'tx-2',
        type: TransactionType.investment,
        title: 'Investment Verified',
        subtitle: 'Invested in Solar Park Phase 1',
        amount: 100000.0,
        date: DateTime(2026, 1, 1, 14, 0),
        status: 'Completed',
        direction: 'DEBIT',
        referenceId: 'TXN-1002',
      ),
    ]);

    await mount(tester);

    // 1. Header checks
    expect(find.text('Hello, Rohit Sharma'), findsOneWidget);
    expect(find.text('Welcome to InvestPro'), findsOneWidget);
    expect(find.byIcon(Remix.notification_line), findsOneWidget);

    // 2. Portfolio Summary Card
    expect(find.text('Total Portfolio Value'), findsOneWidget);
    expect(find.text('Across 1 active project'), findsOneWidget);
    expect(find.byType(PortfolioSummaryCard), findsOneWidget);

    // 3. Four Metric Cards
    expect(find.text('Total Invested'), findsOneWidget);
    expect(find.text('Total Returns'), findsOneWidget);
    expect(find.text('Total Projects'), findsOneWidget);
    expect(find.text('Active Projects'), findsOneWidget);
    expect(find.byType(DashboardMetricCard), findsNWidgets(4));

    // 4. My Projects Section
    expect(find.text('My Projects'), findsOneWidget);
    expect(find.text('Solar Park Phase 1'), findsOneWidget);
    expect(find.byType(MyProjectCard), findsOneWidget);

    // 5. Recent Activity Section
    expect(find.text('Recent Activity'), findsOneWidget);
    expect(find.text('Return Credited'), findsOneWidget);
    expect(find.text('Investment Verified'), findsOneWidget);
    expect(find.byType(RecentActivityItem), findsNWidgets(2));
  });

  testWidgets('Balance visibility toggle conceals and reveals total portfolio value', (tester) async {
    repo.serverTotalInvested.value = 50000.0;
    repo.availableBalance.value = 10000.0;

    await mount(tester);

    // By default, visibility is on
    expect(find.byIcon(Remix.eye_line), findsOneWidget);
    expect(find.text('••••••••'), findsNothing);

    // Tap eye icon to hide balance
    await tester.tap(find.byIcon(Remix.eye_line));
    await tester.pumpAndSettle();

    expect(find.byIcon(Remix.eye_off_line), findsOneWidget);
    expect(find.text('••••••••'), findsOneWidget);

    // Tap again to restore balance
    await tester.tap(find.byIcon(Remix.eye_off_line));
    await tester.pumpAndSettle();

    expect(find.byIcon(Remix.eye_line), findsOneWidget);
    expect(find.text('••••••••'), findsNothing);
  });

  testWidgets('Renders proper empty states when investor has no investments or activity', (tester) async {
    repo.investments.clear();
    repo.transactions.clear();
    repo.serverTotalInvested.value = 0.0;
    repo.serverTotalReturns.value = 0.0;
    repo.availableBalance.value = 0.0;

    await mount(tester);

    // Empty state for My Projects
    expect(find.text('No investments yet'), findsOneWidget);
    expect(find.text('Explore available investment opportunities to get started.'), findsOneWidget);
    expect(find.text('Explore Projects'), findsOneWidget);

    // Empty state for Recent Activity
    expect(find.text('No recent activity'), findsOneWidget);
    expect(find.text('Your latest investments and returns will appear here.'), findsOneWidget);

    // Portfolio Summary shows neutral active count
    expect(find.text('No active investments yet'), findsOneWidget);
  });

  testWidgets('Responsive across diverse phone and tablet viewports without overflow', (tester) async {
    repo.serverTotalInvested.value = 75000.0;
    repo.availableBalance.value = 12000.0;

    final viewports = [
      const Size(320, 568),   // iPhone SE
      const Size(375, 667),   // iPhone 8
      const Size(390, 844),   // iPhone 14
      const Size(430, 932),   // iPhone 14 Pro Max
      const Size(800, 1280),  // Tablet (switches to 4-column metric grid)
      const Size(1024, 1366), // iPad Pro
    ];

    for (final size in viewports) {
      await mount(tester, size: size);
      expect(tester.takeException(), isNull);
    }
  });
}
