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
import 'package:investpro/app/models/project_model.dart';
import 'package:investpro/app/models/transaction_model.dart';
import 'package:investpro/app/models/user_model.dart';
import 'package:investpro/app/services/demo_repository.dart';
import 'package:investpro/app/services/local_storage_service.dart';
import 'package:investpro/app/services/notification_service.dart';
import 'package:investpro/app/theme/app_theme.dart';
import 'package:investpro/app/views/home/home_view.dart';
import 'package:investpro/app/widgets/explore_project_card.dart';
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

  Future<void> mount(WidgetTester tester, {Size size = const Size(390, 844), TargetPlatform platform = TargetPlatform.android, double scale = 1}) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = size;
    tester.view.padding = const FakeViewPadding(top: 44, bottom: 34);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme.copyWith(platform: platform),
        builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(scale)), child: child!),
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

    // 4. Explore Projects Section
    expect(find.text('Explore Projects'), findsOneWidget);
    expect(find.text('Discover high-potential investment opportunities'), findsOneWidget);
    expect(find.byIcon(Remix.compass_3_line), findsOneWidget);

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

    // Empty state for Explore Projects when empty
    expect(find.text('No projects available'), findsOneWidget);
    expect(find.text('Check back soon for new high-potential investment opportunities.'), findsOneWidget);

    // Empty state for Recent Activity
    expect(find.text('No recent activity'), findsOneWidget);
    expect(find.text('Your latest investments and returns will appear here.'), findsOneWidget);

    // Portfolio Summary shows neutral active count
    expect(find.text('No active investments yet'), findsOneWidget);
  });

  testWidgets('Renders Explore Projects section with project cards and real API data', (tester) async {
    repo.projects.assignAll([
      ProjectModel(
        id: 'proj-1',
        name: 'Eco Solar Energy Park',
        category: 'Clean Energy',
        iconType: 'solar',
        targetAmount: 5000000.0,
        raisedAmount: 3250000.0,
        returnRatePercent: 16.0,
        durationMonths: 24,
        status: 'Active',
        description: 'Large scale commercial solar installation in Gujarat.',
        minInvestment: 25000.0,
        createdAt: DateTime(2026, 1, 1),
      ),
      ProjectModel(
        id: 'proj-2',
        name: 'Fintech Cloud Platform',
        category: 'Technology',
        iconType: 'code',
        targetAmount: 2000000.0,
        raisedAmount: 1600000.0,
        returnRatePercent: 20.0,
        durationMonths: 18,
        status: 'Active',
        description: 'Next-gen payment gateway and analytics for MSMEs.',
        minInvestment: 10000.0,
        createdAt: DateTime(2026, 2, 1),
      ),
    ]);

    await mount(tester);

    // Section header elements
    expect(find.text('Explore Projects'), findsOneWidget);
    expect(find.text('Discover high-potential investment opportunities'), findsOneWidget);
    expect(find.byIcon(Remix.compass_3_line), findsOneWidget);

    // Project cards
    expect(find.byType(ExploreProjectCard), findsNWidgets(2));
    expect(find.text('Eco Solar Energy Park'), findsOneWidget);
    expect(find.text('Fintech Cloud Platform'), findsOneWidget);
    expect(find.text('Clean Energy'), findsOneWidget);
    expect(find.text('Technology'), findsOneWidget);
    expect(find.text('65% funded'), findsOneWidget);
    expect(find.text('80% funded'), findsOneWidget);
    expect(find.text('₹ 25,000'), findsOneWidget);
    expect(find.text('16% p.a.'), findsOneWidget);
    expect(find.text('20% p.a.'), findsOneWidget);
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
  for(final platform in [TargetPlatform.android,TargetPlatform.iOS]) {
    for(final size in [const Size(320,568),const Size(844,390),const Size(1024,1366)]) {
      for(final scale in [1.0,1.5]) {
        testWidgets('Dashboard gaps are compact on $platform $size scale $scale',(tester)async {
          repo.currentUser.value=const UserModel(id:'fixture',fullName:'Investor',email:'investor@example.test',mobileNumber:'9876543210');
          repo.investments.assignAll(List.generate(2,(index)=>InvestmentModel(id:'inv-$index',projectId:'project-$index',projectName:'Project $index',iconType:'solar',investedAmount:25000,returnRatePercent:18,durationMonths:12,expectedReturn:4500,maturityAmount:29500,startDate:DateTime(2026,1),maturityDate:DateTime(2027,1),progressPercent:25,status:'Active')));
          repo.transactions.assignAll(List.generate(2,(index)=>TransactionModel(id:'tx-$index',type:TransactionType.returnReceived,title:'Return credited',subtitle:'Project return',amount:1500,date:DateTime(2026,10),status:'Completed',direction:'CREDIT',referenceId:'REF-$index')));
          await mount(tester,size:size,platform:platform,scale:scale);
          final metrics=List.generate(4,(i)=>tester.getRect(find.byType(DashboardMetricCard).at(i)));
          final top=metrics.map((r)=>r.top).reduce((a,b)=>a<b?a:b),bottom=metrics.map((r)=>r.bottom).reduce((a,b)=>a>b?a:b);
          final portfolio=tester.getRect(find.byType(PortfolioSummaryCard));
          final explore=tester.getRect(find.text('Explore Projects'));
          final activity=tester.getRect(find.text('Recent Activity'));
          final firstActivity=tester.getRect(find.byType(RecentActivityItem).first),lastActivity=tester.getRect(find.byType(RecentActivityItem).last);
          expect(top-portfolio.bottom,closeTo(20,.1));
          expect(explore.top-bottom,closeTo(22,.1));
          expect(activity.top,greaterThan(explore.bottom));
          expect(firstActivity.top-activity.bottom,closeTo(14,.1));
          expect(lastActivity.top-firstActivity.bottom,closeTo(10,.1));
          expect(portfolio.top,greaterThanOrEqualTo(44));
          await tester.ensureVisible(find.byType(RecentActivityItem).last);await tester.pumpAndSettle();
          expect(tester.takeException(),isNull);
        });
      }
    }
  }

}
