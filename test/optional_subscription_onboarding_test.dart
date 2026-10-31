import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:investpro/app/controllers/auth_controller.dart';
import 'package:investpro/app/controllers/navigation_controller.dart';
import 'package:investpro/app/controllers/subscription_controller.dart';
import 'package:investpro/app/models/subscription_plan_model.dart';
import 'package:investpro/app/routes/app_routes.dart';
import 'package:investpro/app/services/api_service.dart';
import 'package:investpro/app/services/demo_repository.dart';
import 'package:investpro/app/services/local_storage_service.dart';
import 'package:investpro/app/services/notification_service.dart';
import 'package:investpro/app/views/auth/registration_otp_view.dart';
import 'package:investpro/app/views/subscriptions/subscription_plans_view.dart';

class OnboardingStore implements LocalStore {
  final data = <String, dynamic>{};
  @override dynamic read(String key) => data[key];
  @override Future<void> write(String key, dynamic value) async { data[key] = value; }
}
class OnboardingApi extends ApiService {
  bool pending = true, skipOffline = false, noPlans = false, active = false;
  int sends = 0, registrations = 0, purchases = 0, verifications = 0, skips = 0;
  String? access, refresh;
  final keys = <String?>[];
  final planJson = {'id': 'configured-plan', 'name': 'Configured Investment Membership With A Long Name', 'slug': 'configured', 'price': 299, 'minInvestment': 1000, 'maxInvestment': 25000, 'durationMonths': 1, 'isActive': true, 'benefits': ['Configured investment benefits with long responsive text'], 'accessRules': {'recommended': true, 'features': ['Configured support feature']}};
  @override Future<Map<String, dynamic>> sendRegistrationOtp({required String mobileNumber, String? email, String? fullName}) async { sends++; return {'data': {'cooldownSeconds': 60}}; }
  @override Future<Map<String, dynamic>> verifyRegistrationOtp({required String fullName, required String email, required String mobileNumber, required String password, required String otp}) async { registrations++; access = 'secure-access'; refresh = 'secure-refresh'; return {'user': {'id': 'user', 'role': 'INVESTOR', 'isMobileVerified': true, 'fullName': fullName}}; }
  @override Future<Map<String, dynamic>> getOnboarding() async => {'requiresPlanSelection': pending};
  @override Future<void> skipSubscriptionOnboarding() async { skips++; if (skipOffline) throw DioException(requestOptions: RequestOptions(path: '/mobile/onboarding'), type: DioExceptionType.connectionTimeout); pending = false; }
  @override Future<Map<String, dynamic>?> getMe() async => {'id': 'user', 'role': 'INVESTOR', 'status': 'ACTIVE', 'fullName': 'Test Investor'};
  @override Future<String?> getAccessToken() async => access;
  @override Future<String?> getRefreshToken() async => refresh;
  @override Future<List<Map<String, dynamic>>> getSubscriptionPlans() async => noPlans ? [] : [planJson, {...planJson, 'id': 'configured-yearly', 'name': 'Configured Yearly Plan', 'durationMonths': 12, 'accessRules': {'features': ['Yearly feature']}}];
  @override Future<Map<String, dynamic>?> getCurrentSubscription() async => active ? {'id': 'subscription', 'status': 'ACTIVE', 'endDate': DateTime.now().add(const Duration(days: 30)).toIso8601String(), 'plan': planJson} : null;
  @override Future<Map<String, dynamic>> purchaseSubscription({required String planId, String paymentMethod = 'UPI', String? idempotencyKey}) async { purchases++; keys.add(idempotencyKey); return {'subscription': {'id': 'subscription'}, 'gateway': {'orderId': 'order_plan', 'keyId': 'rzp_test_fixture', 'amount': 29900, 'currency': 'INR'}}; }
  @override Future<Map<String, dynamic>> verifySubscriptionPayment(Map<String, dynamic> paymentData) async { verifications++; active = true; pending = false; return {'subscription': await getCurrentSubscription()}; }
}
class OnboardingRepo extends DemoRepository {
  OnboardingRepo(super.storage, super.notifications, super.api);
  @override Future<void> syncFromBackend() async {}
}
class SubscriptionCheckout extends Razorpay {
  final handlers = <String, Function>{};
  Map<String, dynamic>? options;
  @override void on(String event, Function callback, {bool rawMap = false}) { handlers[event] = callback; }
  @override void open(Map<String, dynamic> value) { options = value; }
  @override void clear() { handlers.clear(); }
}
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() { Get.testMode = true; GoogleFonts.config.allowRuntimeFetching = false; });
  tearDown(() => Get.reset());
  (AuthController, SubscriptionController) setup(OnboardingApi api, LocalStorageService storage, {SubscriptionCheckout? checkout}) {
    Get.put<NavigationController>(NavigationController());
    final repo = OnboardingRepo(storage, NotificationService(storage), api);
    final subscription = Get.put(SubscriptionController(api, checkoutFactory: () => checkout ?? SubscriptionCheckout(), readIntent: (key) async => storage.read(key) as String?, writeIntent: (key, value) => storage.write(key, value)));
    final auth = Get.put(AuthController(storage, repo, api)); Get.put<ApiService>(api);
    return (auth, subscription);
  }
  Widget routes({bool realPlans = false}) => GetMaterialApp(home: const Scaffold(body: Text('Register')), getPages: [GetPage(name: AppRoutes.home, page: () => const Scaffold(body: Text('Dashboard'))), GetPage(name: AppRoutes.subscriptionOnboarding, page: () => realPlans ? const SubscriptionPlansView(onboarding: true) : const Scaffold(body: Text('Onboarding Plans')))]);
  testWidgets('registration waits for OTP, then Skip persists session and does not purchase', (tester) async {
    final api = OnboardingApi(); final storage = LocalStorageService(backend: OnboardingStore()); final (auth, _) = setup(api, storage);
    await tester.pumpWidget(routes());
    await auth.register(fullName: 'New Investor', email: 'new@example.test', mobileNumber: '9876543210', password: 'ValidPass123!'); await tester.pumpAndSettle();
    expect(api.sends, 1); expect(api.registrations, 0); expect(auth.isLoggedIn.value, isFalse); expect(find.byType(RegistrationOtpView), findsOneWidget);
    await auth.verifyRegistration(fullName: 'New Investor', email: 'new@example.test', mobileNumber: '9876543210', password: 'ValidPass123!', otp: '123456'); await tester.pumpAndSettle();
    expect(find.text('Onboarding Plans'), findsOneWidget); expect(find.byType(RegistrationOtpView), findsNothing); expect(Get.key.currentState!.canPop(), isFalse); expect(auth.isLoggedIn.value, isTrue); expect(api.access, 'secure-access');
    await auth.finishSubscriptionOnboarding(skipped: true); await tester.pumpAndSettle(); expect(find.text('Dashboard'), findsOneWidget); expect(api.purchases, 0); expect(api.verifications, 0); expect(api.access, 'secure-access');
    expect(await auth.restoreSession(), isTrue); expect(auth.authenticatedRoute, AppRoutes.home);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('verified checkout from onboarding activates the plan and replaces registration with dashboard', (tester) async {
    final api = OnboardingApi(); final checkout = SubscriptionCheckout(); final (auth, _) = setup(api, LocalStorageService(backend: OnboardingStore()), checkout: checkout);
    await tester.pumpWidget(routes(realPlans: true));
    await auth.verifyRegistration(fullName: 'New Investor', email: 'new@example.test', mobileNumber: '9876543210', password: 'ValidPass123!', otp: '123456'); await tester.pumpAndSettle();
    final choose = find.widgetWithText(FilledButton, 'Choose Plan').first;
    await tester.ensureVisible(choose); await tester.tap(choose); await tester.pumpAndSettle(); expect(checkout.options, isNotNull);
    await checkout.handlers[Razorpay.EVENT_PAYMENT_SUCCESS]!(PaymentSuccessResponse('pay_verified', 'order_plan', 'signature', null)); await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsOneWidget); expect(auth.isLoggedIn.value, isTrue); expect(auth.onboardingPending.value, isFalse); expect(api.purchases, 1); expect(api.verifications, 1); expect(api.access, 'secure-access'); expect(Get.key.currentState!.canPop(), isFalse);
    await tester.pump(const Duration(seconds: 4)); await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox.shrink());
  });
  testWidgets('offline Skip is remembered and retries server completion on restart without losing session', (tester) async {
    final api = OnboardingApi()..skipOffline = true; final storage = LocalStorageService(backend: OnboardingStore()); final (auth, _) = setup(api, storage);
    await tester.pumpWidget(routes()); await auth.verifyRegistration(fullName: 'New Investor', email: 'new@example.test', mobileNumber: '9876543210', password: 'ValidPass123!', otp: '123456'); await tester.pumpAndSettle();
    await auth.finishSubscriptionOnboarding(skipped: true); await tester.pumpAndSettle(); expect(auth.authenticatedRoute, AppRoutes.home); expect(api.pending, isTrue); expect(auth.isLoggedIn.value, isTrue);
    api.skipOffline = false; expect(await auth.restoreSession(), isTrue); expect(api.pending, isFalse); expect(auth.authenticatedRoute, AppRoutes.home); expect(api.purchases, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });
  test('existing accounts restore to dashboard and unfinished new accounts resume plans', () async {
    final api = OnboardingApi()..access = 'secure-access'..refresh = 'secure-refresh'..pending = false;
    final (auth, _) = setup(api, LocalStorageService(backend: OnboardingStore())); expect(await auth.restoreSession(), isTrue); expect(auth.authenticatedRoute, AppRoutes.home);
    api.pending = true; await auth.refreshOnboarding(); expect(auth.authenticatedRoute, AppRoutes.subscriptionOnboarding);
  });
  test('checkout cancellation retains the session and reuses the same pending intent on retry', () async {
    final api = OnboardingApi()..access = 'secure-access'; final checkout = SubscriptionCheckout(); final (_, controller) = setup(api, LocalStorageService(backend: OnboardingStore()), checkout: checkout);
    final plan = SubscriptionPlanModel.fromJson(api.planJson);
    final first = controller.purchase(plan); while (checkout.options == null) { await Future<void>.delayed(Duration.zero); }
    await checkout.handlers[Razorpay.EVENT_PAYMENT_ERROR]!(PaymentFailureResponse(0, 'Cancelled', null)); expect(await first, isFalse); expect(api.access, 'secure-access'); expect(api.verifications, 0);
    checkout.options = null; final second = controller.purchase(plan); while (checkout.options == null) { await Future<void>.delayed(Duration.zero); }
    await checkout.handlers[Razorpay.EVENT_PAYMENT_SUCCESS]!(PaymentSuccessResponse('pay_verified', 'order_plan', 'signature', null)); expect(await second, isTrue); expect(api.keys[0], api.keys[1]); expect(api.verifications, 1); expect(controller.hasActivePlan, isTrue);
    api.active = false; controller.current.value = null; checkout.options = null; final renewal = controller.purchase(plan); while (checkout.options == null) { await Future<void>.delayed(Duration.zero); } expect(api.keys[2], isNot(api.keys[0])); await checkout.handlers[Razorpay.EVENT_PAYMENT_ERROR]!(PaymentFailureResponse(0, 'Cancelled', null)); expect(await renewal, isFalse);
  });
  for (final size in [const Size(320, 640), const Size(844, 390), const Size(768, 1024), const Size(1024, 1366)]) {
    testWidgets('plans and persistent Skip fit $size with configured content', (tester) async {
      tester.view.physicalSize = size; tester.view.devicePixelRatio = 1; addTearDown(tester.view.resetPhysicalSize); addTearDown(tester.view.resetDevicePixelRatio);
      final api = OnboardingApi(); final (_, controller) = setup(api, LocalStorageService(backend: OnboardingStore()));
      await tester.pumpWidget(const GetMaterialApp(home: SubscriptionPlansView(onboarding: true))); await tester.pumpAndSettle();
      expect(find.text('Skip for Now'), findsOneWidget); expect(find.text('Choose Your Investment Plan'), findsOneWidget); expect(controller.plans.length, 2); expect(find.text('Recommended'), findsOneWidget); expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets('no active plans still leaves Skip available without payment', (tester) async {
    final api = OnboardingApi()..noPlans = true; setup(api, LocalStorageService(backend: OnboardingStore()));
    await tester.pumpWidget(const GetMaterialApp(home: SubscriptionPlansView(onboarding: true))); await tester.pumpAndSettle(); expect(find.text('Skip for Now'), findsOneWidget); expect(find.textContaining('No subscription plans are available'), findsOneWidget); expect(api.purchases, 0);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
