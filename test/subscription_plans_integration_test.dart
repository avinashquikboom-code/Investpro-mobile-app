import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:investpro/app/controllers/auth_controller.dart';
import 'package:investpro/app/controllers/subscription_controller.dart';
import 'package:investpro/app/services/api_service.dart';
import 'package:investpro/app/services/demo_repository.dart';
import 'package:investpro/app/services/local_storage_service.dart';
import 'package:investpro/app/services/notification_service.dart';
import 'package:investpro/app/theme/app_theme.dart';
import 'package:investpro/app/views/subscriptions/subscription_plans_view.dart';

class FakeStore implements LocalStore {
  final Map<String, dynamic> data = {};
  @override
  dynamic read(String key) => data[key];
  @override
  Future<void> write(String key, dynamic value) async => data[key] = value;
}

class FakeRazorpayCheckout {
  Map<String, dynamic>? options;
  final handlers = <String, Function>{};

  Razorpay create() {
    final razorpay = Razorpay();
    return razorpay;
  }
}

class FakeIntegrationApi extends ApiService {
  List<Map<String, dynamic>> plans = [
    {
      'id': 'plan-starter',
      'name': 'Starter Tier',
      'slug': 'starter-tier',
      'description': 'Designed for new investors starting small with curated portfolios.',
      'price': 499.0,
      'originalPrice': 999.0,
      'discount': 50.0,
      'currency': 'INR',
      'duration': 12,
      'durationMonths': 12,
      'durationUnit': 'months',
      'minInvestment': 1000.0,
      'maxInvestment': 25000.0,
      'isActive': true,
      'status': 'ACTIVE',
      'displayOrder': 1,
      'benefits': ['Access to starter projects', 'Standard return payouts', 'Email support'],
    },
    {
      'id': 'plan-pro',
      'name': 'Pro Growth Tier',
      'slug': 'pro-growth-tier',
      'description': 'Tailored for intermediate investors seeking balanced wealth creation.',
      'price': 1999.0,
      'originalPrice': 2499.0,
      'discount': 20.0,
      'currency': 'INR',
      'duration': 12,
      'durationMonths': 12,
      'durationUnit': 'months',
      'minInvestment': 25000.0,
      'maxInvestment': 150000.0,
      'isActive': true,
      'status': 'ACTIVE',
      'displayOrder': 2,
      'benefits': ['Growth project access', 'Priority payouts', 'Dedicated WhatsApp support'],
    },
  ];

  Map<String, dynamic>? currentSub;
  List<Map<String, dynamic>> history = [];
  int purchasesCount = 0;
  int verificationsCount = 0;

  @override
  Future<Map<String, dynamic>?> getMe() async => {
        'id': 'inv-test-123',
        'role': 'INVESTOR',
        'email': 'investor@test.com',
      };

  @override
  Future<List<Map<String, dynamic>>> getSubscriptionPlans() async {
    return plans.where((p) => p['isActive'] == true).toList();
  }

  @override
  Future<Map<String, dynamic>?> getCurrentSubscription() async {
    return currentSub;
  }

  @override
  Future<List<Map<String, dynamic>>> getSubscriptionHistory() async {
    return history;
  }

  @override
  Future<Map<String, dynamic>> purchaseSubscription({
    required String planId,
    String paymentMethod = 'UPI',
    String? idempotencyKey,
  }) async {
    purchasesCount++;
    final plan = plans.firstWhere((p) => p['id'] == planId);
    return {
      'subscription': {
        'id': 'sub-pending-456',
        'subscriptionReference': 'SUB-REF-456',
        'status': 'PENDING_PAYMENT',
        'durationMonths': plan['durationMonths'],
      },
      'gateway': {
        'orderId': 'order_test_987654',
        'keyId': 'rzp_test_integrationKey',
        'amount': (plan['price'] * 100).round(),
        'currency': 'INR',
      },
    };
  }

  @override
  Future<Map<String, dynamic>> verifySubscriptionPayment(
    Map<String, dynamic> paymentData,
  ) async {
    verificationsCount++;
    final activatedSub = {
      'id': 'sub-pending-456',
      'subscriptionReference': 'SUB-REF-456',
      'status': 'ACTIVE',
      'startDate': DateTime.now().toIso8601String(),
      'endDate': DateTime.now().add(const Duration(days: 365)).toIso8601String(),
      'createdAt': DateTime.now().toIso8601String(),
      'amountPaid': 499.0,
      'paymentReference': paymentData['gatewayPaymentId'] ?? 'pay_test_999',
      'gatewayPaymentId': paymentData['gatewayPaymentId'] ?? 'pay_test_999',
      'paymentMethod': 'UPI',
      'plan': plans.firstWhere((p) => p['id'] == 'plan-starter'),
      'remainingDays': 365,
      'isExpiringSoon': false,
      'lifecycleStatus': 'ACTIVE',
    };
    currentSub = activatedSub;
    history.add(activatedSub);
    return {'subscription': activatedSub};
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeIntegrationApi api;
  late SubscriptionController controller;
  late LocalStorageService storage;
  late DemoRepository repo;

  setUp(() {
    Get.reset();
    GoogleFonts.config.allowRuntimeFetching = false;
    api = FakeIntegrationApi();
    storage = LocalStorageService(backend: FakeStore());
    final notif = NotificationService(storage);
    repo = DemoRepository(storage, notif, api);
    Get.put<ApiService>(api);
    Get.put<LocalStorageService>(storage);
    Get.put<NotificationService>(notif);
    Get.put<DemoRepository>(repo);
    Get.put<AuthController>(AuthController(storage, repo, api));

    controller = SubscriptionController(
      api,
      readIntent: (key) async => storage.read(key)?.toString(),
      writeIntent: (key, val) async => storage.write(key, val),
    );
    Get.put<SubscriptionController>(controller);
  });

  tearDown(() {
    Get.reset();
  });

  Widget buildTestApp() {
    return GetMaterialApp(
      theme: AppTheme.lightTheme,
      home: const SubscriptionPlansView(),
    );
  }

  testWidgets('Subscription Plans Screen renders actual active plans configured from backend with descriptions, discounts and Subscribe Now button', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    // Verify plans appear
    expect(find.text('Starter Tier'), findsOneWidget);
    expect(find.text('Pro Growth Tier'), findsOneWidget);

    // Verify descriptions appear
    expect(
      find.text('Designed for new investors starting small with curated portfolios.'),
      findsOneWidget,
    );
    expect(
      find.text('Tailored for intermediate investors seeking balanced wealth creation.'),
      findsOneWidget,
    );

    // Verify prices and discounts appear
    expect(find.text('50% OFF'), findsOneWidget);
    expect(find.text('20% OFF'), findsOneWidget);
    expect(find.text('₹999.00'), findsOneWidget); // strikethrough original price

    // Verify "Subscribe Now" buttons are rendered
    expect(find.text('Subscribe Now'), findsNWidgets(2));
  });

  testWidgets('Admin updates plan price and deactivates a plan - Investor Mobile App reflects changes', (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('Pro Growth Tier'), findsOneWidget);

    // 1. Admin updates Pro plan price to 2199
    api.plans[1]['price'] = 2199.0;
    // 2. Admin deactivates Starter plan
    api.plans[0]['isActive'] = false;

    // Investor refreshes plans
    await controller.load(force: true);
    await tester.pumpAndSettle();

    // Starter plan is now inactive and no longer visible
    expect(find.text('Starter Tier'), findsNothing);
    // Pro plan is updated with new price
    expect(find.text('Pro Growth Tier'), findsOneWidget);
    expect(controller.plans.length, 1);
    expect(controller.plans.first.price, 2199.0);

    // 3. Admin reactivates Starter plan
    api.plans[0]['isActive'] = true;
    await controller.load(force: true);
    await tester.pumpAndSettle();

    expect(find.text('Starter Tier'), findsOneWidget);
    expect(controller.plans.length, 2);
  });

  testWidgets('My Subscription displays complete details: plan name, price, purchase/activation/expiry dates, transaction ID and status', (tester) async {
    // Set active subscription on backend
    final now = DateTime.now();
    api.currentSub = {
      'id': 'sub-active-101',
      'subscriptionReference': 'SUB-REF-ACTIVE-101',
      'status': 'ACTIVE',
      'startDate': now.toIso8601String(),
      'endDate': now.add(const Duration(days: 365)).toIso8601String(),
      'createdAt': now.toIso8601String(),
      'amountPaid': 499.0,
      'paymentReference': 'pay_razorpay_tx_101',
      'gatewayPaymentId': 'pay_razorpay_tx_101',
      'paymentMethod': 'UPI',
      'plan': api.plans[0],
      'remainingDays': 365,
      'isExpiringSoon': false,
      'lifecycleStatus': 'ACTIVE',
    };

    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    // Verify Active Plan Card
    expect(find.text('CURRENT PLAN'), findsOneWidget);
    expect(find.text('Starter Tier'), findsWidgets); // In active card and catalog
    expect(find.text('Active'), findsWidgets);
    expect(find.text('Purchased'), findsOneWidget);
    expect(find.text('Activated'), findsOneWidget);
    expect(find.text('Expires'), findsOneWidget);
    expect(find.textContaining('Tx / Ref ID: pay_razorpay_tx_101'), findsOneWidget);
    expect(find.text('Current Active Plan'), findsOneWidget);
  });
}
