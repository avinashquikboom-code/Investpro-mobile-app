import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:investpro/app/constants/app_strings.dart';
import 'package:investpro/app/controllers/auth_controller.dart';
import 'package:investpro/app/controllers/investment_controller.dart';
import 'package:investpro/app/controllers/navigation_controller.dart';
import 'package:investpro/app/controllers/project_controller.dart';
import 'package:investpro/app/controllers/returns_controller.dart';
import 'package:investpro/app/controllers/theme_controller.dart';
import 'package:investpro/app/controllers/transaction_controller.dart';
import 'package:investpro/app/models/investment_model.dart';
import 'package:investpro/app/models/project_model.dart';
import 'package:investpro/app/models/transaction_model.dart';
import 'package:investpro/app/services/demo_repository.dart';
import 'package:investpro/app/services/investment_calculator.dart';
import 'package:investpro/app/services/local_storage_service.dart';
import 'package:investpro/app/services/notification_service.dart';
import 'package:investpro/app/theme/app_theme.dart';
import 'package:investpro/app/views/investments/invest_now_view.dart';
import 'package:investpro/app/views/investments/investment_success_view.dart';
import 'package:investpro/app/views/investments/my_investments_view.dart';
import 'package:investpro/app/views/investments/payment_confirmation_view.dart';
import 'package:investpro/app/views/projects/project_details_view.dart';
import 'package:investpro/app/views/returns/returns_view.dart';
import 'package:investpro/app/views/transactions/transaction_history_view.dart';

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
  TestWidgetsFlutterBinding.ensureInitialized();

  group('1. Centralized Investment Calculator Tests', () {
    test('Calculates exact returns for ₹10,000 at 18% for 12 months', () {
      final res = InvestmentCalculator.calculate(
        principal: 10000,
        returnRatePercent: 18,
        durationMonths: 12,
      );

      expect(res.principal, 10000.0);
      expect(res.returnRatePercent, 18.0);
      expect(res.durationMonths, 12);
      expect(res.expectedTotalReturn, 1800.0);
      expect(res.projectedMaturityAmount, 11800.0);
      expect(res.monthlyProjectedReturn, 150.0);
      expect(res.dailyProjectedReturn, 5.0);
      expect(res.hourlyProjectedReturn, closeTo(0.2083, 0.0001));
      expect(res.monthlySchedule.length, 12);
      expect(res.monthlySchedule.first.month, 1);
      expect(res.monthlySchedule.first.monthlyReturn, 150.0);
      expect(res.monthlySchedule.last.cumulativeReturn, 1800.0);
    });

    test('Calculates exact returns for ₹50,000 at 18% for 12 months', () {
      final res = InvestmentCalculator.calculate(
        principal: 50000,
        returnRatePercent: 18,
        durationMonths: 12,
      );

      expect(res.expectedTotalReturn, 9000.0);
      expect(res.projectedMaturityAmount, 59000.0);
      expect(res.monthlyProjectedReturn, 750.0);
      expect(res.dailyProjectedReturn, 25.0);
      expect(res.hourlyProjectedReturn, closeTo(1.0417, 0.0001));
      expect(res.monthlySchedule.length, 12);
      expect(res.monthlySchedule.last.cumulativeReturn, 9000.0);
    });

    test('Zero or invalid input safely yields zero returns', () {
      final res = InvestmentCalculator.calculate(
        principal: 0,
        returnRatePercent: 18,
        durationMonths: 12,
      );
      expect(res.expectedTotalReturn, 0.0);
      expect(res.monthlySchedule, isEmpty);
    });
  });

  group('2. Seven Redesigned Screens Integration Tests', () {
    late LocalStorageService storage;
    late NotificationService notificationService;
    late DemoRepository repo;
    late InvestmentController invCtrl;
    late ProjectController projCtrl;
    late ProjectModel testProject;

    setUp(() {
      Get.reset();
      Get.testMode = true;
      GoogleFonts.config.allowRuntimeFetching = false;

      storage = LocalStorageService(backend: MemoryStore());
      Get.put(storage);
      notificationService = NotificationService(storage);
      Get.put(notificationService);
      repo = DemoRepository(storage, notificationService);
      Get.put(repo);

      testProject = ProjectModel(
        id: 'proj_1',
        name: 'Software Development Platform',
        category: 'Technology',
        iconType: 'code',
        targetAmount: 500000,
        raisedAmount: 250000,
        returnRatePercent: 18.0,
        durationMonths: 12,
        status: 'Active',
        description: 'Next generation cloud enterprise platform.',
        riskLevel: 'Moderate',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      );

      repo.projects.assignAll([testProject]);

      final testInvestment = InvestmentModel(
        id: 'inv_1',
        projectId: testProject.id,
        projectName: testProject.name,
        iconType: testProject.iconType,
        investedAmount: 50000,
        returnRatePercent: 18.0,
        durationMonths: 12,
        expectedReturn: 9000,
        maturityAmount: 59000,
        progressPercent: 20.0,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        maturityDate: DateTime.now().add(const Duration(days: 330)),
        status: 'Active',
        reference: 'INV-2026-0001',
      );
      repo.investments.assignAll([testInvestment]);

      final testTxn = TransactionModel(
        id: 'txn_1',
        type: TransactionType.investment,
        title: 'Investment in Software Development Platform',
        subtitle: 'INV-2026-0001',
        amount: 50000,
        date: DateTime.now().subtract(const Duration(days: 30)),
        status: 'Completed',
        referenceId: 'TXN-REF-1001',
      );
      repo.transactions.assignAll([testTxn]);

      Get.put(ThemeController(storage));
      Get.put(AuthController(storage, repo));
      Get.put(NavigationController());
      invCtrl = Get.put(InvestmentController(repo));
      projCtrl = Get.put(ProjectController(repo));
      Get.put(TransactionController(repo));
      Get.put(ReturnsController(repo));

      invCtrl.setProject(testProject);
      projCtrl.selectedProject.value = testProject;
    });

    tearDown(() {
      Get.reset();
    });

    Widget createTestApp(Widget child, {Size size = const Size(390, 844)}) {
      return MediaQuery(
        data: MediaQueryData(size: size),
        child: GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          theme: AppTheme.lightTheme,
          home: child,
        ),
      );
    }

    testWidgets('Screen 1 – Invest Now renders project card, presets, tabs & table without overflow', (tester) async {
      final screenSizes = [
        const Size(320, 568),
        const Size(375, 667),
        const Size(390, 844),
        const Size(768, 1024),
      ];

      for (final size in screenSizes) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(createTestApp(const InvestNowView(), size: size));
        await tester.pumpAndSettle();

        expect(find.text('Invest Now'), findsOneWidget);
        expect(find.text('Software Development Platform'), findsOneWidget);
        expect(find.text('18% Return'), findsOneWidget);
        expect(find.text('Enter Investment Amount'), findsOneWidget);
        expect(find.text('₹ 10K'), findsOneWidget);
        expect(find.text('₹ 25K'), findsOneWidget);
        expect(find.text('₹ 50K'), findsOneWidget);
        expect(find.text('₹ 1L'), findsOneWidget);
        expect(find.text('Investment Summary'), findsOneWidget);
        expect(find.text('Projected Maturity Amount'), findsOneWidget);
        expect(find.text('Return Schedule'), findsOneWidget);
        expect(find.text('Monthly Return Schedule'), findsOneWidget);
        expect(find.text('Proceed to Pay'), findsOneWidget);

        // Test tab switching
        await tester.ensureVisible(find.text('Daily'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Daily'));
        await tester.pumpAndSettle();
        expect(find.text('Daily Return Rate:'), findsOneWidget);

        await tester.ensureVisible(find.text('Hourly'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Hourly'));
        await tester.pumpAndSettle();
        expect(find.text('Hourly Return Rate:'), findsOneWidget);

        // Ensure no overflow
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('Screen 2 – Project Details renders funding progress & investment breakdown without overflow', (tester) async {
      final screenSizes = [
        const Size(320, 568),
        const Size(390, 844),
        const Size(768, 1024),
      ];

      for (final size in screenSizes) {
        await tester.binding.setSurfaceSize(size);
        await tester.pumpWidget(createTestApp(const ProjectDetailsView(), size: size));
        await tester.pumpAndSettle();

        expect(find.text('Project Details'), findsOneWidget);
        expect(find.text('Software Development Platform'), findsAtLeastNWidgets(1));
        expect(find.text('Total Investment Required'), findsOneWidget);
        expect(find.text('Already Raised'), findsOneWidget);
        expect(find.text('50% Funded'), findsOneWidget);
        expect(find.text('Investment Details'), findsOneWidget);
        expect(find.text('Monthly Return'), findsOneWidget);
        expect(find.text('Daily Return'), findsOneWidget);
        expect(find.text('Hourly Return'), findsOneWidget);
        expect(find.text('Invest Now'), findsOneWidget);

        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('Screen 3 – Confirm Payment renders return breakdown & payment options without overflow', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(createTestApp(const PaymentConfirmationView()));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Payment'), findsOneWidget);
      expect(find.text('Software Development Platform'), findsOneWidget);
      expect(find.text('Amount Invested'), findsOneWidget);
      expect(find.text('Projected Return Breakdown'), findsOneWidget);
      expect(find.text('Select Payment Method'), findsOneWidget);
      expect(find.text('Razorpay Checkout'), findsOneWidget);
      expect(find.text('Offline Payment'), findsOneWidget);
      expect(find.text('Investment Terms & Risk Disclosures'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('Screen 4 – Investment Success renders checkmark, maturity & real reference', (tester) async {
      invCtrl.lastSuccessfulInvestment.value = repo.investments.first;

      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(createTestApp(const InvestmentSuccessView()));
      await tester.pumpAndSettle();

      expect(find.text('Investment Successful!'), findsOneWidget);
      expect(find.text('Software Development Platform'), findsOneWidget);
      expect(find.text('INV-2026-0001'), findsOneWidget);
      expect(find.text('View My Investments'), findsOneWidget);
      expect(find.text('Go to Home'), findsOneWidget);
      expect(find.text('Projected returns are estimates and are not guaranteed.'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('Screen 5 – My Investments renders portfolio KPI, search & return schedule on cards', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(createTestApp(const MyInvestmentsView(isTab: false)));
      await tester.pumpAndSettle();

      expect(find.text('PORTFOLIO VALUE'), findsOneWidget);
      expect(find.text('Live Tracking'), findsOneWidget);
      expect(find.text('Expected Returns'), findsOneWidget);
      expect(find.text('Active Projects'), findsOneWidget);
      expect(find.text('Software Development Platform'), findsOneWidget);
      expect(find.text('INV-2026-0001'), findsOneWidget);
      expect(find.text('Monthly Return'), findsOneWidget);
      expect(find.text('Daily Return'), findsOneWidget);
      expect(find.text('Hourly Return'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('Screen 6 – Transaction History renders summary KPI card & signed amounts', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(createTestApp(const TransactionHistoryView()));
      await tester.pumpAndSettle();

      expect(find.text('Transaction History'), findsOneWidget);
      expect(find.text('TRANSACTION SUMMARY'), findsOneWidget);
      expect(find.text('Total Invested'), findsOneWidget);
      expect(find.text('Returns Received'), findsOneWidget);
      expect(find.text('Pending Return'), findsOneWidget);
      expect(find.text('Investment in Software Development Platform'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('Screen 7 – Returns renders Total Returns Credited, Schedule & Hourly Analytics', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      await tester.pumpWidget(createTestApp(const ReturnsView(isTab: true)));
      await tester.pumpAndSettle();

      expect(find.text('Returns'), findsOneWidget);
      expect(find.text('Track your investment returns and payouts'), findsOneWidget);
      expect(find.text("Today's Earnings and Return Summary"), findsOneWidget);
      expect(find.text('Return Schedule'), findsOneWidget);
      expect(find.text('Hourly Earnings Analytics'), findsOneWidget);
      expect(find.text('Indicative Projections'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  });
}
