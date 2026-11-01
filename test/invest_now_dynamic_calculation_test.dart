import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:investpro/app/constants/app_constants.dart';
import 'package:investpro/app/controllers/investment_controller.dart';
import 'package:investpro/app/models/project_model.dart';
import 'package:investpro/app/services/demo_repository.dart';
import 'package:investpro/app/services/investment_calculator.dart';
import 'package:investpro/app/services/local_storage_service.dart';
import 'package:investpro/app/services/notification_service.dart';
import 'package:investpro/app/theme/app_theme.dart';
import 'package:investpro/app/views/investments/invest_now_view.dart';

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

  group('Dynamic Investment Calculation Engine Tests', () {
    test('Calculates exact annual return, monthly, daily, hourly for 12-month tenure', () {
      final res = InvestmentCalculator.calculate(
        principal: 100000,
        returnRatePercent: 24.0,
        durationMonths: 12,
        convention: DayCountConvention.thirty360,
      );

      // Principal: ₹1,00,000 | 24% p.a. for 12 months
      // Expected Total Return: ₹24,000.00
      // Projected Maturity: ₹1,24,000.00
      // Monthly Return: ₹2,000.00
      // Daily Return: ₹66.67
      // Hourly Return: ~₹2.7778
      expect(res.principal, 100000.0);
      expect(res.returnRatePercent, 24.0);
      expect(res.durationMonths, 12);
      expect(res.expectedTotalReturn, 24000.0);
      expect(res.projectedMaturityAmount, 124000.0);
      expect(res.monthlyProjectedReturn, 2000.0);
      expect(res.dailyProjectedReturn, closeTo(66.67, 0.01));
      expect(res.hourlyProjectedReturn, closeTo(2.7778, 0.0001));

      // Monthly schedule integrity
      expect(res.monthlySchedule.length, 12);
      expect(res.monthlySchedule.last.cumulativeReturn, 24000.0);

      // Daily schedule integrity (first 30 days)
      expect(res.dailySchedule.length, 30);
      expect(res.dailySchedule.first.label, 'Day 1');
      expect(res.dailySchedule.last.label, 'Day 30');

      // Hourly schedule integrity (24 hours)
      expect(res.hourlySchedule.length, 24);
      expect(res.hourlySchedule.first.label, '01:00');
      expect(res.hourlySchedule.last.label, '24:00');

      // Total schedule milestones
      expect(res.totalSchedule.isNotEmpty, isTrue);
      expect(res.totalSchedule.last.cumulativeReturn, 24000.0);
    });

    test('Reconciles sum of scheduled returns with total interest for 6-month term', () {
      final res = InvestmentCalculator.calculate(
        principal: 50000,
        returnRatePercent: 18.0,
        durationMonths: 6,
        convention: DayCountConvention.thirty360,
      );

      // 50,000 * 18% * (6/12) = 4,500.00
      expect(res.expectedTotalReturn, 4500.0);
      expect(res.projectedMaturityAmount, 54500.0);
      expect(res.monthlyProjectedReturn, 750.0);

      // Check sum of monthly returns equals expectedTotalReturn exactly
      final sumMonthly = res.monthlySchedule.fold<double>(
        0.0,
        (sum, item) => sum + item.monthlyReturn,
      );
      expect(sumMonthly, closeTo(res.expectedTotalReturn, 0.01));
      expect(res.monthlySchedule.last.cumulativeReturn, res.expectedTotalReturn);
    });

    test('Supports Actual/365 convention with exact day-count calculation', () {
      final res365 = InvestmentCalculator.calculate(
        principal: 73000,
        returnRatePercent: 10.0,
        durationMonths: 12,
        convention: DayCountConvention.actual365,
      );

      // 73000 * 10% = 7300 annual. Daily = 7300 / 365 = 20.0 per day.
      expect(res365.dailyProjectedReturn, closeTo(20.0, 0.01));
      expect(res365.hourlyProjectedReturn, closeTo(20.0 / 24.0, 0.0001));
      expect(res365.expectedTotalReturn, closeTo(7300.0, 1.0));
      expect(res365.projectedMaturityAmount, closeTo(80300.0, 1.0));
    });
  });

  group('Dynamic Quick Amount Chips & Funding Validation Tests', () {
    late LocalStorageService storage;
    late NotificationService notificationService;
    late DemoRepository repo;
    late InvestmentController invCtrl;

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
      invCtrl = Get.put(InvestmentController(repo));
    });

    tearDown(() {
      Get.reset();
    });

    test('Standard project adapts quick chips within funding limits', () {
      final project = ProjectModel(
        id: 'proj_standard',
        name: 'Standard Clean Tech Project',
        category: 'Clean Energy',
        iconType: 'gear',
        targetAmount: 500000,
        raisedAmount: 100000, // 400k remaining
        minInvestment: 10000,
        maxInvestment: 100000,
        returnRatePercent: 20.0,
        durationMonths: 12,
        status: 'Active',
        description: 'Green energy installation.',
        createdAt: DateTime.now(),
      );

      invCtrl.setProject(project);

      expect(invCtrl.remainingFunding, 400000.0);
      expect(AppConstants.quickInvestAmounts, containsAll([10000.0, 25000.0, 50000.0, 75000.0, 100000.0]));
      expect(invCtrl.amountError, isNull);
    });

    test('Project with high minInvestment clamps chips and initial selection dynamically', () {
      final project = ProjectModel(
        id: 'proj_high_min',
        name: 'Enterprise Commercial Complex',
        category: 'Real Estate',
        iconType: 'building',
        targetAmount: 1000000,
        raisedAmount: 200000,
        minInvestment: 50000, // Min is 50k
        maxInvestment: 200000,
        returnRatePercent: 15.0,
        durationMonths: 24,
        status: 'Active',
        description: 'Commercial real estate bond.',
        createdAt: DateTime.now(),
      );

      invCtrl.setProject(project);

      invCtrl.selectQuickAmount(50000);
      expect(invCtrl.investmentAmount.value, 50000.0);
      expect(invCtrl.amountTextController.text, '50000.0');
      expect(invCtrl.amountError, isNull);
    });

    test('Validation restricts amounts exceeding remaining project funding', () {
      final project = ProjectModel(
        id: 'proj_almost_funded',
        name: 'Almost Fully Funded Campaign',
        category: 'AgriTech',
        iconType: 'leaf',
        targetAmount: 100000,
        raisedAmount: 85000, // Only 15,000 remaining
        minInvestment: 5000,
        maxInvestment: 50000,
        returnRatePercent: 16.0,
        durationMonths: 6,
        status: 'Active',
        description: 'Organic farming campaign.',
        createdAt: DateTime.now(),
      );

      invCtrl.setProject(project);

      expect(invCtrl.remainingFunding, 15000.0);

      // 10,000 is valid (< 15,000 remaining)
      invCtrl.selectQuickAmount(10000);
      expect(invCtrl.amountError, isNull);

      // 20,000 exceeds remaining funding (15,000)
      invCtrl.selectQuickAmount(20000);
      expect(invCtrl.amountError, contains('exceeds remaining project funding'));
    });
  });

  group('Invest Now Screen Tab Switching & Table View Tests', () {
    late LocalStorageService storage;
    late NotificationService notificationService;
    late DemoRepository repo;
    late InvestmentController invCtrl;
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
      invCtrl = Get.put(InvestmentController(repo));

      testProject = ProjectModel(
        id: 'proj_dynamic',
        name: 'Dynamic Solar Farm Project',
        category: 'Energy',
        iconType: 'sun',
        targetAmount: 1000000,
        raisedAmount: 500000,
        minInvestment: 5000,
        maxInvestment: 100000,
        returnRatePercent: 18.0,
        durationMonths: 12,
        status: 'Active',
        description: 'Solar farm energy project.',
        createdAt: DateTime.now(),
      );

      repo.projects.assignAll([testProject]);
      invCtrl.setProject(testProject);
      invCtrl.selectQuickAmount(50000);
    });

    tearDown(() {
      Get.reset();
    });

    Widget createTestApp(Widget child) {
      return GetMaterialApp(
        locale: const Locale('en', 'US'),
        theme: AppTheme.lightTheme,
        home: child,
      );
    }

    testWidgets('Tapping all 4 tabs updates banner and dynamic schedule rows without error', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 1200));
      await tester.pumpWidget(createTestApp(const InvestNowView()));
      await tester.pumpAndSettle();

      // 1. Initial Monthly Schedule
      expect(find.text('Return Schedule'), findsOneWidget);
      expect(find.text('Monthly Return Schedule'), findsOneWidget);
      expect(find.text('Monthly Return Rate:'), findsOneWidget);
      expect(find.text('Month 1'), findsOneWidget);

      // 2. Switch to Daily
      await tester.tap(find.text('Daily'));
      await tester.pumpAndSettle();
      expect(find.text('Daily Return Rate:'), findsOneWidget);
      expect(find.text('Day 1'), findsOneWidget);
      expect(find.text('30-Day Accrual'), findsOneWidget);

      // 3. Switch to Hourly
      await tester.tap(find.text('Hourly'));
      await tester.pumpAndSettle();
      expect(find.text('Hourly Return Rate:'), findsOneWidget);
      expect(find.text('01:00'), findsOneWidget);
      expect(find.text('24-Hour Total (1 Day)'), findsOneWidget);

      // 4. Switch to Total
      await tester.tap(find.text('Total'));
      await tester.pumpAndSettle();
      expect(find.text('Total Return Rate:'), findsOneWidget);
      expect(find.text('Projected Maturity Amount'), findsWidgets);

      // 5. Switch back to Monthly
      await tester.tap(find.text('Monthly'));
      await tester.pumpAndSettle();
      expect(find.text('Monthly Return Rate:'), findsOneWidget);
      expect(find.text('Month 1'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  });
}
