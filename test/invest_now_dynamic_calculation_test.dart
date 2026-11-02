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
import 'package:investpro/app/utils/currency_formatter.dart';
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
    test('Calculates exact monthly return, daily, hourly for 12-month tenure', () {
      final res = InvestmentCalculator.calculate(
        principal: 100000,
        returnRatePercent: 2.0, // 2% per month
        durationMonths: 12,
        convention: DayCountConvention.thirty360,
      );

      // Principal: ₹1,00,000 | 2% per month for 12 months
      // Monthly Return: ₹2,000.00 (100,000 * 2%)
      // Expected Total Return: ₹24,000.00 (2,000 * 12)
      // Projected Maturity: ₹1,24,000.00
      // Daily Return: ₹66.67 (2,000 / 30)
      // Hourly Return: ~₹2.7778
      expect(res.principal, 100000.0);
      expect(res.returnRatePercent, 2.0);
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

    test('Calculates ₹10,000 at 18% monthly for 6 months (confirmed business rule)', () {
      final res = InvestmentCalculator.calculate(
        principal: 10000,
        returnRatePercent: 18.0,
        durationMonths: 6,
        convention: DayCountConvention.thirty360,
      );

      // 10,000 * 18% = 1,800 monthly interest
      // 6 months * 1,800 = 10,800 total interest
      // Maturity = 10,000 + 10,800 = 20,800
      expect(res.principal, 10000.0);
      expect(res.returnRatePercent, 18.0);
      expect(res.durationMonths, 6);
      expect(res.monthlyProjectedReturn, 1800.0);
      expect(res.expectedTotalReturn, 10800.0);
      expect(res.projectedMaturityAmount, 20800.0);
      expect(res.dailyProjectedReturn, 60.0); // 1800 / 30
      expect(res.hourlyProjectedReturn, 2.5); // 60 / 24
      expect(res.previousMonthlyInterestPayouts, 9000.0); // 1800 * 5
      expect(res.finalMonthInterest, 1800.0);
      expect(res.principalRepaymentAtMaturity, 10000.0);
      expect(res.finalMonthPayment, 11800.0);
      expect(res.totalReceivedOverInvestmentPeriod, 20800.0);

      // Check sum of monthly returns equals expectedTotalReturn exactly
      final sumMonthly = res.monthlySchedule.fold<double>(
        0.0,
        (sum, item) => sum + item.monthlyReturn,
      );
      expect(sumMonthly, closeTo(res.expectedTotalReturn, 0.01));
      expect(res.monthlySchedule.last.cumulativeReturn, res.expectedTotalReturn);
    });

    test('Calculates ₹10,000 at 10% monthly for 12 months', () {
      final res = InvestmentCalculator.calculate(
        principal: 10000,
        returnRatePercent: 10.0,
        durationMonths: 12,
        convention: DayCountConvention.thirty360,
      );

      // 10,000 * 10% = 1,000 monthly. Total = 12,000. Maturity = 22,000.
      expect(res.monthlyProjectedReturn, 1000.0);
      expect(res.expectedTotalReturn, 12000.0);
      expect(res.projectedMaturityAmount, 22000.0);
    });

    test('Calculates ₹25,000 at 12% monthly for 3 months', () {
      final res = InvestmentCalculator.calculate(
        principal: 25000,
        returnRatePercent: 12.0,
        durationMonths: 3,
        convention: DayCountConvention.thirty360,
      );

      // 25,000 * 12% = 3,000 monthly. Total = 9,000. Maturity = 34,000.
      expect(res.monthlyProjectedReturn, 3000.0);
      expect(res.expectedTotalReturn, 9000.0);
      expect(res.projectedMaturityAmount, 34000.0);
    });

    test('Supports monthly convention with exact day-count calculation', () {
      final res = InvestmentCalculator.calculate(
        principal: 73000,
        returnRatePercent: 10.0,
        durationMonths: 12,
        convention: DayCountConvention.thirty360,
      );

      // 73000 * 10% = 7300 monthly. Daily = 7300 / 30 = 243.33 per day. Total = 87600.
      expect(res.monthlyProjectedReturn, 7300.0);
      expect(res.dailyProjectedReturn, closeTo(243.33, 0.01));
      expect(res.expectedTotalReturn, 87600.0);
      expect(res.projectedMaturityAmount, 160600.0);
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

    Widget createTestApp(Widget child, {double textScale = 1}) {
      return GetMaterialApp(
        locale: const Locale('en', 'US'),
        theme: AppTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child ?? const SizedBox.shrink(),
        ),
        home: child,
      );
    }

    testWidgets('maturity card shows lifetime total rather than final month payment', (tester) async {
      invCtrl.setProject(ProjectModel(id:'three-month',name:'Three Month Project',category:'Energy',iconType:'folder',targetAmount:100000,raisedAmount:0,minInvestment:10000,returnRatePercent:18,durationMonths:3,description:'',createdAt:DateTime(2026)));
      invCtrl.selectQuickAmount(10000);
      await tester.binding.setSurfaceSize(const Size(400, 1200));
      await tester.pumpWidget(createTestApp(const InvestNowView()));
      await tester.pumpAndSettle();
      final cardRow=find.ancestor(of:find.text('Projected Maturity Amount'),matching:find.byType(Row)).first;
      expect(find.descendant(of:cardRow,matching:find.text('₹15,400.00')),findsOneWidget);
      expect(find.descendant(of:cardRow,matching:find.text('₹11,800.00')),findsNothing);
      expect(invCtrl.calculationResult.finalMonthPayment,11800);
      expect(invCtrl.calculationResult.previousMonthlyInterestPayouts,3600);
    });

    for (final months in [1, 3, 6, 12]) {
      testWidgets('Monthly payout table separates interest and principal for $months months', (tester) async {
        invCtrl.setProject(ProjectModel(
          id: 'monthly-$months',
          name: 'Monthly Schedule Test',
          category: 'Test',
          iconType: 'folder',
          targetAmount: 100000,
          raisedAmount: 0,
          minInvestment: 1000,
          returnRatePercent: 5,
          durationMonths: months,
          description: '',
          createdAt: DateTime(2026, 1, 1),
        ));
        invCtrl.selectQuickAmount(10000);
        final width = months == 1 ? 320.0 : 400.0;
        final textScale = months == 1 ? 1.0 : 1.3;
        await tester.binding.setSurfaceSize(Size(width, 720));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(createTestApp(const InvestNowView(), textScale: textScale));
        await tester.pumpAndSettle();

        expect(find.text('Monthly Return Schedule'), findsOneWidget);
        expect(find.text('Month'), findsOneWidget);
        expect(find.text('Interest'), findsOneWidget);
        expect(find.text('Principal'), findsOneWidget);
        expect(find.text('Total payout'), findsOneWidget);
        expect(find.text('Status'), findsNothing);
        expect(find.text('Final Month'), findsOneWidget);
        expect(find.text(CurrencyFormatter.format(10000, showDecimals: true)), findsWidgets);
        expect(find.text(CurrencyFormatter.format(10500, showDecimals: true)), findsWidgets);
        expect(find.text(CurrencyFormatter.format(500 * months, showDecimals: true)), findsWidgets);
        expect(find.text(CurrencyFormatter.format(10000 + 500 * months, showDecimals: true)), findsWidgets);
        expect(find.text('Total interest ='), findsOneWidget);
        expect(find.text('Total received ='), findsOneWidget);
        if (months > 1) {
          expect(find.text('₹0.00'), findsAtLeastNWidgets(months - 1));
        }
        for (var month = 1; month < months; month++) {
          expect(find.text('Month $month'), findsOneWidget);
        }

        await tester.ensureVisible(find.text('Month'));
        await tester.pumpAndSettle();
        final monthHeaderX = tester.getTopLeft(find.text('Month')).dx;
        final interestHeader = find.text('Interest');
        final horizontalViewport = find.ancestor(
          of: interestHeader,
          matching: find.byWidgetPredicate(
            (widget) => widget is SingleChildScrollView &&
                widget.scrollDirection == Axis.horizontal,
          ),
        ).first;
        await tester.drag(horizontalViewport, const Offset(-180, 0));
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(find.text('Month')).dx, monthHeaderX);
        expect(tester.takeException(), isNull);
      });
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
      expect(find.text('Total Eligible Accrual'), findsOneWidget);

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
      expect(find.text('Total Received Over Investment Period'), findsWidgets);

      // 5. Switch back to Monthly
      await tester.tap(find.text('Monthly'));
      await tester.pumpAndSettle();
      expect(find.text('Monthly Return Rate:'), findsOneWidget);
      expect(find.text('Month 1'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  });
}
