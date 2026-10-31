import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remixicon/remixicon.dart';
import 'package:investpro/app/controllers/auth_controller.dart';
import 'package:investpro/app/controllers/investment_controller.dart';
import 'package:investpro/app/controllers/project_controller.dart';
import 'package:investpro/app/models/project_model.dart';
import 'package:investpro/app/models/subscription_plan_model.dart';
import 'package:investpro/app/models/user_model.dart';
import 'package:investpro/app/services/api_service.dart';
import 'package:investpro/app/services/demo_repository.dart';
import 'package:investpro/app/services/local_storage_service.dart';
import 'package:investpro/app/services/notification_service.dart';
import 'package:investpro/app/theme/app_theme.dart';
import 'package:investpro/app/views/projects/projects_view.dart';
import 'package:investpro/app/views/subscriptions/subscription_plans_sheet.dart';

class TestStore implements LocalStore {
  final data = <String, dynamic>{};
  @override
  dynamic read(String key) => data[key];
  @override
  Future<void> write(String key, dynamic value) async => data[key] = value;
}

class FakeSubscriptionApi extends ApiService {
  bool subscriptionRequired = false;
  Map<String, dynamic>? eligibilityData;
  List<Map<String, dynamic>> testProjects = [];
  List<Map<String, dynamic>> testPlans = [
    {
      'id': 'plan-basic',
      'name': 'Basic',
      'slug': 'basic',
      'price': 999,
      'minInvestment': 1000,
      'maxInvestment': 25000,
      'durationMonths': 12,
      'isActive': true,
      'benefits': ['Invest up to ₹25,000', 'Basic support'],
    },
    {
      'id': 'plan-silver',
      'name': 'Silver',
      'slug': 'silver',
      'price': 2499,
      'minInvestment': 25000,
      'maxInvestment': 100000,
      'durationMonths': 12,
      'isActive': true,
      'benefits': ['Invest up to ₹1,00,000', 'Priority support'],
    },
  ];

  @override
  Future<List<Map<String, dynamic>>> getProjectCategories() async => [
        {'id': 'cat-1', 'name': 'Tech', 'isActive': true},
      ];

  @override
  Future<ProjectPage> getEligibleProjectPage({
    int page = 1,
    int limit = 12,
    String? projectTypeId,
    String? search,
  }) async {
    return ProjectPage(
      testProjects,
      page: 1,
      totalPages: 1,
      subscriptionRequired: subscriptionRequired,
      eligibility: eligibilityData,
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getSubscriptionPlans() async {
    return testPlans;
  }

  @override
  Future<Map<String, dynamic>?> getCurrentSubscription() async {
    if (eligibilityData == null) return null;
    return {
      'id': 'sub-active',
      'status': eligibilityData!['status'],
      'plan': testPlans.first,
    };
  }

  @override
  Future<Map<String, dynamic>> getSubscriptionEligibility() async {
    return eligibilityData ??
        {
          'hasActiveSubscription': false,
          'isExpired': false,
          'minInvestment': 0,
          'maxInvestment': 0,
          'status': 'NONE',
        };
  }

  @override
  Future<Map<String, dynamic>> purchaseSubscription({
    required String planId,
    String paymentMethod = 'UPI',
  }) async {
    return {
      'subscriptionId': 'sub-new-123',
      'orderId': 'order_test_123',
      'amount': 999,
      'currency': 'INR',
    };
  }

  @override
  Future<Map<String, dynamic>> verifySubscriptionPayment(
    Map<String, dynamic> paymentData,
  ) async {
    subscriptionRequired = false;
    eligibilityData = {
      'hasActiveSubscription': true,
      'isExpired': false,
      'minInvestment': 1000,
      'maxInvestment': 25000,
      'planName': 'Basic',
      'status': 'ACTIVE',
    };
    return {
      'activated': true,
      'subscription': {'id': paymentData['subscriptionId'], 'status': 'ACTIVE'},
    };
  }
}

ProjectModel dummyProject({
  String id = 'proj-1',
  String name = 'Fintech Pro',
  double minInvestment = 5000,
  double targetAmount = 100000,
  double raisedAmount = 20000,
  String status = 'Active',
}) {
  return ProjectModel(
    id: id,
    name: name,
    category: 'Fintech',
    iconType: 'code',
    targetAmount: targetAmount,
    raisedAmount: raisedAmount,
    returnRatePercent: 12.5,
    durationMonths: 12,
    status: status,
    description: 'Test description',
    riskLevel: 'Moderate',
    minInvestment: minInvestment,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  group('Subscription Models Test', () {
    test('SubscriptionPlanModel correctly parses and formats json', () {
      final json = {
        'id': 'plan-gold',
        'name': 'Gold Tier',
        'slug': 'gold',
        'price': 4999,
        'minInvestment': 100000,
        'maxInvestment': 500000,
        'durationMonths': 12,
        'isActive': true,
        'benefits': ['Priority access', 'Direct manager'],
      };

      final plan = SubscriptionPlanModel.fromJson(json);
      expect(plan.id, 'plan-gold');
      expect(plan.name, 'Gold Tier');
      expect(plan.price, 4999.0);
      expect(plan.minInvestment, 100000.0);
      expect(plan.maxInvestment, 500000.0);
      expect(plan.durationMonths, 12);
      expect(plan.benefits.length, 2);
      expect(plan.formattedDuration, '12 Months');
      expect(plan.formattedRange, contains('1,00,000'));
      expect(plan.formattedRange, contains('5,00,000'));
    });

    test('SubscriptionEligibilityModel evaluates investment project limits', () {
      final active = SubscriptionEligibilityModel.fromJson({
        'hasActiveSubscription': true,
        'isExpired': false,
        'minInvestment': 25000,
        'maxInvestment': 100000,
        'planName': 'Silver',
        'status': 'ACTIVE',
      });

      expect(active.hasActiveSubscription, isTrue);
      expect(active.isExpired, isFalse);
      expect(active.isEligibleForProject(50000), isTrue);
      expect(active.isEligibleForProject(10000), isFalse);
      expect(active.isEligibleForProject(150000), isFalse);

      final expired = SubscriptionEligibilityModel.fromJson({
        'hasActiveSubscription': false,
        'isExpired': true,
        'minInvestment': 25000,
        'maxInvestment': 100000,
        'status': 'EXPIRED',
      });
      expect(expired.isEligibleForProject(50000), isFalse);
    });
  });

  group('ProjectController Subscription Eligibility Tests', () {
    late DemoRepository repo;
    late FakeSubscriptionApi api;
    late ProjectController controller;

    setUp(() {
      Get.testMode = true;
      final storage = LocalStorageService(backend: TestStore());
      api = FakeSubscriptionApi();
      repo = DemoRepository(storage, NotificationService(storage), api);
      repo.currentUser.value = const UserModel(
        id: 'usr-1',
        fullName: 'Active Investor',
        email: 'investor@test.com',
        mobileNumber: '9876543210',
        accountStatus: 'ACTIVE',
        kycStatus: 'VERIFIED',
      );
      controller = ProjectController(repo, api);
    });

    tearDown(() {
      Get.reset();
    });

    test('Requires subscription when subscriptionRequired is true', () {
      controller.subscriptionRequired.value = true;
      final proj = dummyProject(minInvestment: 5000);
      final reason = controller.investmentUnavailableReason(
        proj,
        authenticated: true,
      );
      expect(reason, 'Active subscription plan required to invest');
    });

    test('Validates project bounds against active subscription plan', () {
      controller.subscriptionRequired.value = false;
      controller.eligibility.value = const SubscriptionEligibilityModel(
        hasActiveSubscription: true,
        isExpired: false,
        minInvestment: 25000,
        maxInvestment: 100000,
        planName: 'Silver',
        status: 'ACTIVE',
      );

      // Within range (₹50,000)
      final eligibleProj = dummyProject(minInvestment: 50000);
      expect(
        controller.investmentUnavailableReason(eligibleProj, authenticated: true),
        isNull,
      );

      // Below range (₹5,000)
      final belowProj = dummyProject(minInvestment: 5000);
      expect(
        controller.investmentUnavailableReason(belowProj, authenticated: true),
        'Project requires a higher subscription plan',
      );

      // Above range (₹2,00,000)
      final aboveProj = dummyProject(minInvestment: 200000);
      expect(
        controller.investmentUnavailableReason(aboveProj, authenticated: true),
        'Project requires a higher subscription plan',
      );
    });

    test('Purchasing a subscription activates eligibility and refreshes projects', () async {
      final plan = SubscriptionPlanModel.fromJson({
        'id': 'plan-basic',
        'name': 'Basic',
        'price': 999,
        'minInvestment': 1000,
        'maxInvestment': 25000,
        'durationMonths': 12,
      });

      controller.subscriptionRequired.value = true;
      final success = await controller.purchasePlan(plan);
      expect(success, isTrue);
      expect(controller.subscriptionRequired.value, isFalse);
      expect(controller.eligibility.value?.hasActiveSubscription, isTrue);
    });
  });

  group('ProjectsView Subscription UI & Sheet Tests', () {
    late DemoRepository repo;
    late FakeSubscriptionApi api;
    late ProjectController projCtrl;
    late AuthController authCtrl;

    setUp(() {
      Get.testMode = true;
      final storage = LocalStorageService(backend: TestStore());
      api = FakeSubscriptionApi();
      repo = DemoRepository(storage, NotificationService(storage), api);
      repo.currentUser.value = const UserModel(
        id: 'usr-1',
        fullName: 'Active Investor',
        email: 'investor@test.com',
        mobileNumber: '9876543210',
        accountStatus: 'ACTIVE',
        kycStatus: 'VERIFIED',
      );
      Get.put<ApiService>(api);
      Get.put(storage);
      Get.put(repo);
      authCtrl = Get.put(AuthController(storage, repo, api));
      authCtrl.isLoggedIn.value = true;
      Get.put(InvestmentController(repo));
      projCtrl = Get.put(ProjectController(repo, api));
    });

    tearDown(() {
      Get.reset();
    });

    testWidgets('Renders Subscription Plan Required empty state when unsubscribed', (tester) async {
      projCtrl.subscriptionRequired.value = true;
      projCtrl.remoteProjects.clear();

      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: const Scaffold(body: ProjectsView()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Subscription Plan Required'), findsOneWidget);
      expect(find.text('View Subscription Plans'), findsOneWidget);
      expect(find.byIcon(Remix.vip_crown_line), findsOneWidget);
    });

    testWidgets('Opens SubscriptionPlansSheet and displays plans with allowed investment ranges', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () => SubscriptionPlansSheet.show(context),
                child: const Text('Open Plans'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Plans'));
      await tester.pumpAndSettle();

      expect(find.text('Subscription Plans'), findsOneWidget);
      expect(find.text('Basic'), findsOneWidget);
      expect(find.text('Silver'), findsOneWidget);
      expect(find.text('Allowed Investment Range'), findsWidgets);
      expect(find.text('Subscribe Now'), findsWidgets);
    });
  });
}
