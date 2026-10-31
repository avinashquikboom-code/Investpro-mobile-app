import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:investpro/app/controllers/auth_controller.dart';
import 'package:investpro/app/controllers/navigation_controller.dart';
import 'package:investpro/app/controllers/subscription_controller.dart';
import 'package:investpro/app/services/api_service.dart';
import 'package:investpro/app/services/demo_repository.dart';
import 'package:investpro/app/services/local_storage_service.dart';
import 'package:investpro/app/services/notification_service.dart';
import 'package:investpro/app/views/subscriptions/subscription_plans_view.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

class MockPlanStore implements LocalStore {
  final Map<String, dynamic> _map = {};
  @override
  dynamic read(String key) => _map[key];
  @override
  Future<void> write(String key, dynamic value) async {
    _map[key] = value;
  }
}

class MockPlanApi extends ApiService {
  Map<String, dynamic>? activeSubscription;
  List<Map<String, dynamic>> historyList = [];
  List<Map<String, dynamic>> planList = [
    {
      'id': 'plan-starter',
      'name': 'Starter Plan',
      'slug': 'starter',
      'price': 499,
      'minInvestment': 1000,
      'maxInvestment': 25000,
      'durationMonths': 1,
      'isActive': true,
      'benefits': ['Standard Investor Support', 'Direct ROI Payouts'],
      'accessRules': {
        'features': ['Basic Market Analytics'],
      },
    },
    {
      'id': 'plan-growth',
      'name': 'Growth Tier',
      'slug': 'growth',
      'price': 1999,
      'minInvestment': 25000,
      'maxInvestment': 150000,
      'durationMonths': 12,
      'isActive': true,
      'benefits': ['Priority Support 24/7', 'Higher Payout Limits'],
      'accessRules': {
        'features': ['Dedicated Relationship Manager', 'Early Access Deals'],
      },
    },
  ];

  @override
  Future<Map<String, dynamic>?> getMe() async => {
        'id': 'inv-user-1',
        'role': 'INVESTOR',
        'status': 'ACTIVE',
        'fullName': 'Rahul Sharma',
      };

  @override
  Future<String?> getAccessToken() async => 'test-token';

  @override
  Future<List<Map<String, dynamic>>> getSubscriptionPlans() async => planList;

  @override
  Future<Map<String, dynamic>?> getCurrentSubscription() async => activeSubscription;

  @override
  Future<List<Map<String, dynamic>>> getSubscriptionHistory() async => historyList;

  @override
  Future<Map<String, dynamic>> getOnboarding() async => {'requiresPlanSelection': false};
}

class MockCheckout extends Razorpay {
  @override
  void on(String event, Function callback, {bool rawMap = false}) {}
  @override
  void open(Map<String, dynamic> options) {}
  @override
  void clear() {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Get.testMode = true;
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  tearDown(() {
    Get.reset();
  });

  void setupControllers(MockPlanApi api) {
    Get.put<NavigationController>(NavigationController(), permanent: true);
    final storage = LocalStorageService(backend: MockPlanStore());
    final notifs = NotificationService(storage);
    final repo = DemoRepository(storage, notifs, api);
    Get.put<AuthController>(
      AuthController(storage, repo, api),
      permanent: true,
    );
    Get.put<SubscriptionController>(
      SubscriptionController(
        api,
        checkoutFactory: () => MockCheckout(),
        readIntent: (k) async => storage.read(k) as String?,
        writeIntent: (k, v) => storage.write(k, v),
      ),
      permanent: true,
    );
  }

  Widget createTestWidget() {
    return const GetMaterialApp(
      home: SubscriptionPlansView(onboarding: false),
    );
  }

  testWidgets('Renders header with My Plan and subtitle', (tester) async {
    final api = MockPlanApi();
    setupControllers(api);

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('My Plan'), findsOneWidget);
    expect(find.text('Manage your investment subscription'), findsOneWidget);
    expect(find.text('Choose Your Investment Plan'), findsOneWidget);
  });

  testWidgets('Renders active plan card with real progress, dates, and benefits', (tester) async {
    final now = DateTime.now();
    final api = MockPlanApi()
      ..activeSubscription = {
        'id': 'sub-active-1',
        'status': 'ACTIVE',
        'startDate': now.subtract(const Duration(days: 10)).toIso8601String(),
        'endDate': now.add(const Duration(days: 20)).toIso8601String(),
        'amountPaid': 1999,
        'plan': {
          'id': 'plan-growth',
          'name': 'Growth Tier',
          'slug': 'growth',
          'price': 1999,
          'minInvestment': 25000,
          'maxInvestment': 150000,
          'durationMonths': 12,
          'isActive': true,
          'benefits': ['Priority Support 24/7', 'Higher Payout Limits'],
          'accessRules': {
            'features': ['Dedicated Relationship Manager'],
          },
        },
      };

    setupControllers(api);

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Active Card
    expect(find.text('Growth Tier'), findsWidgets);
    expect(find.text('Active'), findsWidgets);
    expect(find.text('CURRENT PLAN'), findsOneWidget);
    expect(find.textContaining('days remaining'), findsOneWidget);
    expect(find.textContaining('% elapsed'), findsOneWidget);

    // Plan Summary Cards
    expect(find.text('Investment Range'), findsOneWidget);
    expect(find.text('Billing Cycle'), findsOneWidget);

    // Plan Benefits Card
    expect(find.text('Your Plan Benefits'), findsOneWidget);
    expect(find.text('Priority Support 24/7'), findsWidgets);
    expect(find.text('Dedicated Relationship Manager'), findsWidgets);

    // Actions
    expect(find.text('Upgrade Plan'), findsOneWidget);
    expect(find.text('Subscription History'), findsOneWidget);
  });

  testWidgets('Renders expiring soon state when remaining days <= 3', (tester) async {
    final now = DateTime.now();
    final api = MockPlanApi()
      ..activeSubscription = {
        'id': 'sub-expiring-1',
        'status': 'ACTIVE',
        'startDate': now.subtract(const Duration(days: 28)).toIso8601String(),
        'endDate': now.add(const Duration(days: 2)).toIso8601String(),
        'amountPaid': 499,
        'plan': {
          'id': 'plan-starter',
          'name': 'Starter Plan',
          'slug': 'starter',
          'price': 499,
          'minInvestment': 1000,
          'maxInvestment': 25000,
          'durationMonths': 1,
          'isActive': true,
          'benefits': ['Standard Investor Support'],
          'accessRules': {},
        },
      };

    setupControllers(api);

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Expiring soon banner
    expect(find.text('Subscription Expiring Soon'), findsOneWidget);
    expect(find.text('Expiring Soon'), findsWidgets);
    expect(find.text('Renew Plan'), findsOneWidget);
  });

  testWidgets('Renders expired state with renewal CTA', (tester) async {
    final now = DateTime.now();
    final api = MockPlanApi()
      ..activeSubscription = {
        'id': 'sub-expired-1',
        'status': 'EXPIRED',
        'startDate': now.subtract(const Duration(days: 60)).toIso8601String(),
        'endDate': now.subtract(const Duration(days: 5)).toIso8601String(),
        'amountPaid': 499,
        'plan': {
          'id': 'plan-starter',
          'name': 'Starter Plan',
          'slug': 'starter',
          'price': 499,
          'minInvestment': 1000,
          'maxInvestment': 25000,
          'durationMonths': 1,
          'isActive': true,
          'benefits': ['Standard Investor Support'],
          'accessRules': {},
        },
      };

    setupControllers(api);

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Subscription Expired'), findsOneWidget);
    expect(find.text('Expired'), findsWidgets);
    expect(find.text('Renew Subscription'), findsOneWidget);
  });

  testWidgets('Renders No Active Plan card when investor has no subscription', (tester) async {
    final api = MockPlanApi()..activeSubscription = null;

    setupControllers(api);

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('No Active Plan'), findsOneWidget);
    expect(
      find.text("You haven't purchased a subscription yet. Choose a plan to explore eligible investment opportunities."),
      findsOneWidget,
    );
    expect(find.text('Explore Plans'), findsOneWidget);
  });

  testWidgets('Opens Subscription History sheet showing past records', (tester) async {
    final now = DateTime.now();
    final api = MockPlanApi()
      ..activeSubscription = {
        'id': 'sub-active-1',
        'status': 'ACTIVE',
        'startDate': now.subtract(const Duration(days: 10)).toIso8601String(),
        'endDate': now.add(const Duration(days: 20)).toIso8601String(),
        'amountPaid': 1999,
        'plan': {
          'id': 'plan-growth',
          'name': 'Growth Tier',
          'slug': 'growth',
          'price': 1999,
          'minInvestment': 25000,
          'maxInvestment': 150000,
          'durationMonths': 12,
          'isActive': true,
          'benefits': ['Priority Support 24/7'],
          'accessRules': {},
        },
      }
      ..historyList = [
        {
          'id': 'sub-old-1',
          'status': 'EXPIRED',
          'startDate': '2025-01-01T00:00:00.000Z',
          'endDate': '2025-02-01T00:00:00.000Z',
          'amountPaid': 499,
          'billingCycle': 'MONTHLY',
          'plan': {
            'name': 'Starter Plan',
            'price': 499,
          },
        },
      ];

    setupControllers(api);

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    // Tap subscription history action
    final historyBtn = find.text('Subscription History');
    expect(historyBtn, findsOneWidget);
    await tester.ensureVisible(historyBtn);
    await tester.tap(historyBtn);
    await tester.pumpAndSettle();

    // History sheet open
    expect(find.text('Starter Plan'), findsWidgets);
    expect(find.text('Expired'), findsOneWidget);
  });

  for (final size in [
    const Size(320, 640),
    const Size(390, 844),
    const Size(768, 1024),
    const Size(1024, 1366),
  ]) {
    testWidgets('Responsive check at size $size without RenderFlex overflow', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final now = DateTime.now();
      final api = MockPlanApi()
        ..activeSubscription = {
          'id': 'sub-active-1',
          'status': 'ACTIVE',
          'startDate': now.subtract(const Duration(days: 5)).toIso8601String(),
          'endDate': now.add(const Duration(days: 25)).toIso8601String(),
          'amountPaid': 1999,
          'plan': {
            'id': 'plan-growth',
            'name': 'Growth Tier With Very Long Name For Responsive Testing',
            'slug': 'growth',
            'price': 1999,
            'minInvestment': 25000,
            'maxInvestment': 150000,
            'durationMonths': 12,
            'isActive': true,
            'benefits': [
              'Extremely long description of an investment benefit to ensure it wraps cleanly on compact screens without breaking bounds',
            ],
            'accessRules': {},
          },
        };

      setupControllers(api);

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('My Plan'), findsOneWidget);
    });
  }
}
