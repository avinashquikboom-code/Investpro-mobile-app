import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:investpro/app/controllers/investment_controller.dart';
import 'package:investpro/app/models/investment_model.dart';
import 'package:investpro/app/models/project_model.dart';
import 'package:investpro/app/routes/app_routes.dart';
import 'package:investpro/app/services/api_service.dart';
import 'package:investpro/app/services/backend_snapshot.dart';
import 'package:investpro/app/services/demo_repository.dart';
import 'package:investpro/app/services/local_storage_service.dart';
import 'package:investpro/app/services/notification_service.dart';
import 'package:investpro/app/services/payment_error.dart';

class MemoryStore implements LocalStore {
  final values = <String, dynamic>{};
  @override
  dynamic read(String key) => values[key];
  @override
  Future<void> write(String key, dynamic value) async {
    values[key] = value;
  }
}

final project = ProjectModel(
  id: 'project-id',
  name: 'Project',
  category: 'Category',
  iconType: 'folder',
  targetAmount: 100000,
  raisedAmount: 0,
  returnRatePercent: 18,
  durationMonths: 12,
  description: '',
  createdAt: DateTime(2026),
  minInvestment: 1000,
);
Map<String, dynamic> investment({bool captured = false}) => {
  'id': 'investment-id',
  'projectId': project.id,
  'project': {'title': project.name},
  'amount': 25000,
  'agreedRoi': 18,
  'tenureMonths': 12,
  'totalExpectedReturns': 4500,
  'status': captured ? 'ACTIVE' : 'PENDING_PAYMENT',
  'paymentVerified': captured,
  'startDate': '2026-10-30T00:00:00Z',
  'maturityDate': '2027-10-30T00:00:00Z',
};

class PaymentApi extends ApiService {
  int orders = 0, verifications = 0;
  bool captured = false, failOrder = false;
  int amount = 2500000;
  Completer<void>? orderGate;
  @override
  Future<Map<String, dynamic>> object(String path) async =>
      investment(captured: captured);
  @override
  Future<Map<String, dynamic>> paymentOrder(String id) async {
    orders++;
    if(orderGate!=null) await orderGate!.future;
    if (failOrder) {
      throw const PaymentFailure('Amount exceeds remaining project funding');
    }
    return {
      'investmentId': id,
      'orderId': 'order_test',
      'keyId': 'rzp_test_fixture',
      'amount': amount,
      'currency': 'INR',
    };
  }

  @override
  Future<Map<String, dynamic>> verifyPayment(Map<String, dynamic> data) async {
    verifications++;
    captured = true;
    return investment(captured: true);
  }
}

class PaymentRepo extends DemoRepository {
  PaymentRepo(super.storage, super.notifications, super.api);
  int creates = 0;
  bool refreshFails = false;
  @override
  Future<InvestmentModel> createInvestment({
    required ProjectModel project,
    required double amount,
    required String paymentMethod,
    String? requestId,
  }) async {
    creates++;
    return BackendSnapshot.investment(investment());
  }

  @override
  Future<void> syncFromBackend() async {
    if (refreshFails) throw StateError('temporary refresh failure');
  }
}

class Checkout extends Razorpay {
  final handlers = <String, Function>{};
  Map<String, dynamic>? options;
  int clears = 0;
  bool openFails = false;
  @override
  void on(String event, Function handler, {bool rawMap = false}) {
    handlers[event] = handler;
  }

  @override
  void open(Map<String, dynamic> options) async {
    if (openFails) throw StateError('Native checkout unavailable');
    this.options = options;
  }

  @override
  void clear() {
    clears++;
    handlers.clear();
  }
}

class RejectAdapter implements HttpClientAdapter {
  RequestOptions? options;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? data,
    Future<void>? cancel,
  ) async {
    this.options = options;
    return ResponseBody.fromString(
      jsonEncode({
        'success': false,
        'message': 'Validation failed',
        'errors': [
          {'field': 'projectId', 'message': 'Invalid project ID'},
        ],
      }),
      400,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => Get.reset());
  test('failed investment API identifies endpoint/status and returns meaningful validation without raw Dio error', () async {
    final api = ApiService()
      ..dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'));
    final adapter = RejectAdapter();
    api.dio.httpClientAdapter = adapter;
    await expectLater(
      api.createInvestment(
        projectId: 'bad-id',
        amount: 25000,
        idempotencyKey: 'stable-retry',
      ),
      throwsA(
        isA<PaymentFailure>().having(
          (e) => e.message,
          'message',
          'Invalid project ID',
        ),
      ),
    );
    expect(adapter.options!.path, '/mobile/investments');
    expect(adapter.options!.method, 'POST');
    expect(adapter.options!.data['amount'], 25000);
    expect(adapter.options!.headers['Idempotency-Key'], 'stable-retry');
  });
  test(
    'retry keys survive repository recreation and remain scoped by amount',
    () async {
      final memory = MemoryStore(), api = PaymentApi();
      final storage = LocalStorageService(backend: memory);
      final first = DemoRepository(storage, NotificationService(storage), api),
          second = DemoRepository(storage, NotificationService(storage), api);
      final key = await first.paymentRequestId(project, 25000);
      expect(await second.paymentRequestId(project, 25000), key);
      expect(await second.paymentRequestId(project, 29500), isNot(key));
      await second.clearPaymentRequest(project, 25000);
      expect(await first.paymentRequestId(project, 25000), isNot(key));
    },
  );
  test(
    'sanitizes diagnostic credentials and network interruption messages',
    () {
      expect(
        PaymentError.diagnostic(
          'Bearer secret-token investor@example.test 1234567890123456',
        ),
        isNot(contains('secret-token')),
      );
      final error = DioException(
        requestOptions: RequestOptions(path: '/payments/orders'),
        type: DioExceptionType.connectionTimeout,
      );
      expect(PaymentError.message(error), contains('retry safely'));
      expect(PaymentError.message(error), isNot(contains('DioException')));
    },
  );
  Future<(InvestmentController, PaymentApi, PaymentRepo, Checkout)> setup(
    WidgetTester tester,
  ) async {
    Get.testMode = true;
    await tester.pumpWidget(
      GetMaterialApp(
        initialRoute: AppRoutes.home,
        getPages: [
          GetPage(
            name: AppRoutes.home,
            page: () => const Scaffold(body: Text('Home')),
          ),
          GetPage(
            name: AppRoutes.investmentSuccess,
            page: () => const Scaffold(body: Text('Verified success')),
          ),
        ],
      ),
    );
    await tester.pumpAndSettle();
    final api = Get.put<ApiService>(PaymentApi()) as PaymentApi;
    final storage = LocalStorageService(backend: MemoryStore());
    final repo = PaymentRepo(storage, NotificationService(storage), api);
    final checkout = Checkout();
    final controller = Get.put(
      InvestmentController(repo, checkoutFactory: () => checkout),
    );
    controller.setProject(project);
    controller.selectQuickAmount(25000);
    controller.agreeToTerms.value = true;
    return (controller, api, repo, checkout);
  }

  testWidgets(
    'order rejection preserves confirmation state and retries the same pending investment',
    (tester) async {
      final (c, api, repo, sdk) = await setup(tester);
      api.failOrder = true;
      expect(await c.confirmAndPay(), false);
      expect(c.paymentError.value, 'Amount exceeds remaining project funding');
      expect(c.currentProject.value, project);
      expect(c.isProcessingPayment.value, false);
      expect(sdk.options, isNull);
      api.failOrder = false;
      final result = c.confirmAndPay();
      await tester.pumpAndSettle();
      expect(repo.creates, 1);
      sdk.handlers[Razorpay.EVENT_PAYMENT_ERROR]!(
        PaymentFailureResponse(2, 'cancelled', null),
      );
      expect(await result, false);
    },
  );
  testWidgets(
    'duplicate taps create one checkout using validated principal paise',
    (tester) async {
      final (c, api, repo, sdk) = await setup(tester);
      final result = c.confirmAndPay();
      expect(await c.confirmAndPay(), false);
      await tester.pumpAndSettle();
      expect(api.orders, 1);
      expect(repo.creates, 1);
      expect(sdk.options!['amount'], 2500000);
      expect(sdk.options!['amount'], isNot(2950000));
      expect(sdk.handlers.containsKey(Razorpay.EVENT_EXTERNAL_WALLET), true);
      sdk.handlers[Razorpay.EVENT_PAYMENT_ERROR]!(
        PaymentFailureResponse(2, 'cancelled', null),
      );
      expect(await result, false);
      expect(c.isProcessingPayment.value, false);
      expect(sdk.clears, greaterThan(0));
    },
  );
  testWidgets(
    'maturity amount returned as payable is rejected before checkout',
    (tester) async {
      final (c, api, repo, sdk) = await setup(tester);
      api.amount = 2950000;
      expect(await c.confirmAndPay(), false);
      expect(sdk.options, isNull);
      expect(c.paymentError.value, contains('order is invalid'));
    },
  );
  testWidgets(
    'incomplete success callback never verifies or activates the investment',
    (tester) async {
      final (c, api, repo, sdk) = await setup(tester);
      final result = c.confirmAndPay();
      await tester.pumpAndSettle();
      await sdk.handlers[Razorpay.EVENT_PAYMENT_SUCCESS]!(
        PaymentSuccessResponse('pay_test', null, null, null),
      );
      expect(await result, false);
      expect(api.verifications, 0);
      expect(c.lastSuccessfulInvestment.value, isNull);
    },
  );
  testWidgets(
    'duplicate success callbacks verify once and refresh failure cannot undo captured success',
    (tester) async {
      final (c, api, repo, sdk) = await setup(tester);
      repo.refreshFails = true;
      final result = c.confirmAndPay();
      await tester.pumpAndSettle();
      final callback = sdk.handlers[Razorpay.EVENT_PAYMENT_SUCCESS]!;
      final response = PaymentSuccessResponse(
        'pay_test',
        'order_test',
        'a' * 64,
        null,
      );
      await Future.wait([
        Future.sync(() => callback(response)),
        Future.sync(() => callback(response)),
      ]);
      expect(await result, true);
      expect(api.verifications, 1);
      expect(c.lastSuccessfulInvestment.value!.investedAmount, 25000);
      await tester.pumpAndSettle();
    },
  );
  testWidgets(
    'resume trusts only confirmed backend capture and disposes listeners',
    (tester) async {
      final (c, api, repo, sdk) = await setup(tester);
      final result = c.confirmAndPay();
      await tester.pumpAndSettle();
      api.captured = true;
      c.didChangeAppLifecycleState(AppLifecycleState.resumed);
      await tester.pumpAndSettle();
      expect(await result, true);
      expect(api.verifications, 0);
      expect(c.lastSuccessfulInvestment.value, isNotNull);
      expect(sdk.handlers, isEmpty);
    },
  );
  testWidgets(
    'native asynchronous checkout errors are contained and permit retry',
    (tester) async {
      final (c, api, repo, sdk) = await setup(tester);
      sdk.openFails = true;
      final result = c.confirmAndPay();
      await tester.pumpAndSettle();
      expect(await result, false);
      expect(
        c.paymentError.value,
        'Unable to open secure checkout. Please retry.',
      );
      expect(c.isProcessingPayment.value, false);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('leaving while order request is in flight does not open checkout later', (tester) async {
    final (c,api,repo,sdk)=await setup(tester);api.orderGate=Completer<void>();final result=c.confirmAndPay();await tester.pumpAndSettle();Get.delete<InvestmentController>();api.orderGate!.complete();await tester.pumpAndSettle();expect(await result,false);expect(sdk.options,isNull);
  });
  testWidgets(
    'closing the controller clears listeners and completes pending checkout safely',
    (tester) async {
      final (c, api, repo, sdk) = await setup(tester);
      final result = c.confirmAndPay();
      await tester.pumpAndSettle();
      Get.delete<InvestmentController>();
      expect(await result, false);
      expect(sdk.handlers, isEmpty);
    },
  );
}
