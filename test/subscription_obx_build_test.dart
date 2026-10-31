import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:investpro/app/controllers/auth_controller.dart';
import 'package:investpro/app/controllers/navigation_controller.dart';
import 'package:investpro/app/controllers/subscription_controller.dart';
import 'package:investpro/app/services/api_service.dart';
import 'package:investpro/app/services/demo_repository.dart';
import 'package:investpro/app/services/local_storage_service.dart';
import 'package:investpro/app/services/notification_service.dart';
import 'package:investpro/app/views/subscriptions/subscription_plans_view.dart';

class TestLocalStore implements LocalStore {
  final Map<String, dynamic> data = {};
  @override
  dynamic read(String key) => data[key];
  @override
  Future<void> write(String key, dynamic value) async => data[key] = value;
}

class TestSubApi extends ApiService {
  int plansCallCount = 0;
  int currentCallCount = 0;
  bool shouldFail = false;

  final samplePlan = {
    'id': 'plan-growth',
    'name': 'Growth Tier',
    'slug': 'growth-tier',
    'price': 999,
    'minInvestment': 1000,
    'maxInvestment': 50000,
    'durationMonths': 1,
    'isActive': true,
    'benefits': ['Feature A'],
  };

  @override
  Future<List<Map<String, dynamic>>> getSubscriptionPlans() async {
    plansCallCount++;
    if (shouldFail) throw Exception('Network timeout');
    return [samplePlan];
  }

  @override
  Future<Map<String, dynamic>?> getCurrentSubscription() async {
    currentCallCount++;
    if (shouldFail) throw Exception('Network timeout');
    return {
      'id': 'sub-active',
      'status': 'ACTIVE',
      'startDate': DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
      'endDate': DateTime.now().add(const Duration(days: 20)).toIso8601String(),
      'remainingDays': 20,
      'isExpiringSoon': false,
      'lifecycleStatus': 'ACTIVE',
      'plan': samplePlan,
    };
  }

  @override
  Future<Map<String, dynamic>?> getMe() async => {
        'id': 'user-1',
        'role': 'INVESTOR',
        'status': 'ACTIVE',
        'fullName': 'Test User',
      };

  @override
  Future<Map<String, dynamic>> getOnboarding() async => {'requiresPlanSelection': false};

  @override
  Future<String?> getAccessToken() async => 'test-token';
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TestSubApi api;
  late SubscriptionController controller;
  late AuthController auth;

  setUp(() {
    Get.reset();
    final store = TestLocalStore();
    final storage = LocalStorageService(backend: store);
    final notifs = NotificationService(storage);
    api = TestSubApi();
    final repo = DemoRepository(storage, notifs, api);
    final nav = NavigationController();
    Get.put(storage);
    Get.put(notifs);
    Get.put(repo);
    Get.put(nav);

    auth = AuthController(storage, repo, api);
    Get.put(auth);

    controller = SubscriptionController(
      api,
      readIntent: (_) async => null,
      writeIntent: (_, _) async {},
    );
    Get.put<SubscriptionController>(controller, permanent: true);
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('Mounting SubscriptionProfileCard inside Obx does not throw setState during build', (tester) async {
    final reactiveFlag = false.obs;

    await tester.pumpWidget(
      GetMaterialApp(
        home: Scaffold(
          body: Obx(() {
            // Read reactive state
            final _ = reactiveFlag.value;
            return Column(
              children: const [
                Text('Profile Header'),
                SubscriptionProfileCard(),
              ],
            );
          }),
        ),
      ),
    );

    // Initial frame builds cleanly without exception
    expect(tester.takeException(), isNull);
    expect(find.text('Profile Header'), findsOneWidget);
    expect(find.text('Subscription Plan'), findsOneWidget);

    // Let post-frame callbacks execute and complete
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Data should now be loaded and rendered reactively
    expect(find.text('Growth Tier'), findsOneWidget);
    expect(find.text('Active'), findsOneWidget);
  });

  testWidgets('Mounting SubscriptionPlansView does not throw and displays plan data reactively', (tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(
        home: SubscriptionPlansView(),
      ),
    );

    expect(tester.takeException(), isNull);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    expect(find.text('Choose Your Investment Plan'), findsOneWidget);
    expect(find.text('Growth Tier'), findsWidgets);
  });

  testWidgets('Concurrent subscription widgets reuse in-flight load request without duplicating API calls', (tester) async {
    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              SubscriptionProfileCard(),
              Expanded(child: SubscriptionPlansView()),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Because in-flight request was reused, each API endpoint is only called once
    expect(api.plansCallCount, equals(1));
    expect(api.currentCallCount, equals(1));
  });

  testWidgets('Network failure updates error state without hanging in loading', (tester) async {
    api.shouldFail = true;

    await tester.pumpWidget(
      const GetMaterialApp(
        home: SubscriptionPlansView(),
      ),
    );

    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    // Loading indicator must be dismissed and error shown
    expect(controller.loading.value, isFalse);
    expect(controller.error.isNotEmpty, isTrue);
    expect(find.text('Retry'), findsOneWidget);
  });
}
