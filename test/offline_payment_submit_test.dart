import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart'
    show FlutterSecureStorage;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide FormData, Response, MultipartFile;
import 'package:google_fonts/google_fonts.dart';
import 'package:investpro/app/controllers/investment_controller.dart';
import 'package:investpro/app/services/api_service.dart';
import 'package:investpro/app/services/local_storage_service.dart';
import 'package:investpro/app/services/notification_service.dart';
import 'package:investpro/app/services/offline_payment_config.dart';
import 'package:investpro/app/services/payment_error.dart';
import 'package:investpro/app/views/investments/payment_confirmation_view.dart';

import 'razorpay_payment_test.dart' as fixture;

final class ProofFile extends PlatformFile {
  final Uint8List bytes;
  ProofFile(this.bytes);
  @override
  String get name => 'proof.pdf';
  @override
  Future<int?> length() async => bytes.length;
  @override
  Future<Uint8List> readAsBytes() async => bytes;
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

class Picker extends FilePickerPlatform {
  Uint8List bytes = Uint8List.fromList(
    utf8.encode('%PDF-1.4\nsynthetic fixture'),
  );
  @override
  Future<List<PlatformFile>> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async => [ProofFile(bytes)];
}

class Adapter implements HttpClientAdapter {
  final requests = <RequestOptions>[];
  final payloads = <Map<String, String>>[];
  int status = 200;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final form = options.data as FormData;
    payloads.add(Map.fromEntries(form.fields));
    expect(form.files.single.key, 'paymentProof');
    expect(form.files.single.value.contentType.toString(), 'application/pdf');
    expect(form.files.single.value.filename, 'proof.pdf');
    expect(
      form.fields.any(
        (e) => e.value.contains('/Users/') || e.value.startsWith('file://'),
      ),
      isFalse,
    );
    return ResponseBody.fromString(
      jsonEncode(
        status == 200
            ? {
                'success': true,
                'data': {
                  'id': 'request',
                  'status': 'PENDING_VERIFICATION',
                  'investment': {'amount': '25000'},
                },
              }
            : {'success': false, 'message': 'Offline fixture error $status'},
      ),
      status,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class Api extends fixture.PaymentApi {
  int reads = 0;
  Object? failure;
  Completer<Map<String, dynamic>>? waiting;
  Map<String, dynamic> config = {
    'enabled': true,
    'accountHolderName': 'Configured holder',
    'bankName': 'Configured bank',
    'accountNumber': 'test-account',
    'ifscCode': 'TEST0000001',
    'upiId': 'test@example',
    'maxBytes': 5242880,
  };
  @override
  Future<Map<String, dynamic>> object(String path) async {
    reads++;
    if (failure != null) throw failure!;
    return waiting?.future ?? Map.of(config);
  }
}

void main() {
  late Api api;
  late Adapter adapter;
  late InvestmentController controller;
  late Picker picker;
  late FilePickerPlatform original;
  setUp(() {
    Get.testMode = true;
    GoogleFonts.config.allowRuntimeFetching = false;
    FlutterSecureStorage.setMockInitialValues({});
    original = FilePickerPlatform.instance;
    picker = Picker();
    FilePickerPlatform.instance = picker;
    api = Api()
      ..dio = Dio(
        BaseOptions(
          baseUrl: 'https://fixture.test/api/v1',
          headers: {'Authorization': 'Bearer test-session'},
        ),
      );
    adapter = Adapter();
    api.dio.httpClientAdapter = adapter;
    Get.put<ApiService>(api);
    final storage = LocalStorageService(backend: fixture.MemoryStore());
    final repo = fixture.PaymentRepo(
      storage,
      NotificationService(storage),
      api,
    );
    controller = Get.put(
      InvestmentController(repo, checkoutFactory: fixture.Checkout.new),
    );
    controller.currentProject.value = fixture.project;
    controller.amountTextController.text = '25000';
    controller.investmentAmount.value = 25000;
    controller.selectedPaymentMethod.value = 'Offline Payment';
  });
  tearDown(() {
    FilePickerPlatform.instance = original;
    Get.reset();
  });
  Future<void> mount(WidgetTester t) async {
    await t.pumpWidget(const GetMaterialApp(home: PaymentConfirmationView()));
    await t.pumpAndSettle();
  }

  Future<void> show(WidgetTester t, Finder finder) async {
    await t.ensureVisible(finder);
    await t.pumpAndSettle();
  }

  FilledButton submit(WidgetTester t) => t.widget<FilledButton>(
    find.widgetWithText(FilledButton, 'Submit Payment Details'),
  );
  Future<void> ready(WidgetTester t, {bool utrLast = false}) async {
    if (!utrLast) {
      await t.enterText(
        find.byKey(const ValueKey('offline-utr')),
        'ABC-123/456',
      );
    }
    await show(t, find.text('Upload Payment Proof').last);
    await t.tap(find.text('Upload Payment Proof').last);
    await t.pumpAndSettle();
    await show(t, find.byType(Checkbox));
    await t.tap(find.byType(Checkbox));
    await t.pumpAndSettle();
    if (utrLast) {
      await t.enterText(
        find.byKey(const ValueKey('offline-utr')),
        'ABC-123/456',
      );
    }
    await show(t, find.text('Submit Payment Details'));
  }

  testWidgets(
    'valid UTR entered last rebuilds eligibility, sends authenticated multipart and confirms pending only',
    (t) async {
      await mount(t);
      await ready(t, utrLast: true);
      expect(submit(t).onPressed, isNotNull);
      expect(find.textContaining('Selected, not uploaded yet'), findsOneWidget);
      await t.tap(find.text('Submit Payment Details'));
      await t.pumpAndSettle();
      expect(adapter.requests.length, 1);
      expect(
        adapter.requests.single.headers['Authorization'],
        'Bearer test-session',
      );
      expect(adapter.payloads.single['amount'], '25000.0');
      expect(adapter.payloads.single['transferMethod'], 'BANK_TRANSFER');
      expect(adapter.payloads.single['utrNumber'], 'ABC-123/456');
      expect(adapter.payloads.single['idempotencyKey'], isNotEmpty);
      expect(find.textContaining('PENDING_VERIFICATION'), findsWidgets);
      expect(controller.lastSuccessfulInvestment.value, isNull);
    },
  );
  testWidgets(
    'disabled or failed settings hide the payment form and can refresh to enabled',
    (t) async {
      api.config['enabled'] = false;
      await mount(t);
      expect(find.byKey(const ValueKey('offline-utr')), findsNothing);
      expect(submit(t).onPressed, isNull);
      expect(find.text('Use Razorpay Checkout'), findsOneWidget);
      api.config['enabled'] = true;
      await show(t, find.text('Refresh payment settings'));
      await t.tap(find.text('Refresh payment settings'));
      await t.pumpAndSettle();
      expect(find.byKey(const ValueKey('offline-utr')), findsOneWidget);
    },
  );
  testWidgets('settings failure is distinct from disabled and retry works', (
    t,
  ) async {
    api.failure = const PaymentFailure('Settings service unavailable');
    await mount(t);
    expect(find.text('Settings service unavailable'), findsWidgets);
    expect(find.byKey(const ValueKey('offline-utr')), findsNothing);
    api.failure = null;
    await show(t, find.text('Refresh payment settings'));
    await t.tap(find.text('Refresh payment settings'));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('offline-utr')), findsOneWidget);
  });
  testWidgets('disable after form completion is rechecked before upload', (
    t,
  ) async {
    await mount(t);
    await ready(t);
    api.config['enabled'] = false;
    await t.tap(find.text('Submit Payment Details'));
    await t.pumpAndSettle();
    expect(adapter.requests, isEmpty);
    expect(find.byKey(const ValueKey('offline-utr')), findsNothing);
  });
  testWidgets('invalid proof does not enable submit', (t) async {
    await mount(t);
    picker.bytes = Uint8List.fromList([1, 2, 3]);
    await show(t, find.text('Upload Payment Proof').last);
    await t.tap(find.text('Upload Payment Proof').last);
    await t.pumpAndSettle();
    expect(submit(t).onPressed, isNull);
    expect(adapter.requests, isEmpty);
  });
  testWidgets(
    'failed upload shows server reason and retry reuses the idempotency key',
    (t) async {
      await mount(t);
      await ready(t);
      adapter.status = 500;
      await t.tap(find.text('Submit Payment Details'));
      await t.pumpAndSettle();
      expect(find.text('Offline fixture error 500'), findsOneWidget);
      final key = adapter.payloads.single['idempotencyKey'];
      adapter.status = 200;
      await show(t, find.text('Submit Payment Details'));
      await t.tap(find.text('Submit Payment Details'));
      await t.pumpAndSettle();
      expect(adapter.payloads.last['idempotencyKey'], key);
    },
  );
  test('strict settings and UTR compatibility never enables missing flags', () {
    expect(OfflinePaymentConfig.parse({'enabled': 'false'})['enabled'], false);
    expect(
      OfflinePaymentConfig.parse({
        'offlinePaymentEnabled': 'true',
        'upiId': 'test@example',
      })['enabled'],
      true,
    );
    expect(() => OfflinePaymentConfig.parse({}), throwsFormatException);
    expect(OfflinePaymentConfig.validReference('AB---1'), false);
    expect(OfflinePaymentConfig.validReference('ABC-123/456'), true);
    expect(OfflinePaymentConfig.parse({'enabled': true})['configured'], false);
  });
  for (final status in [400, 401, 403, 404, 409, 422, 500]) {
    test('API $status is surfaced usefully without swallowing errors', () {
      final options = RequestOptions(path: '/offline');
      final error = DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: status,
          data: {'message': 'Reason $status'},
        ),
        type: DioExceptionType.badResponse,
      );
      expect(
        PaymentError.message(error),
        status == 401 ? contains('session has expired') : 'Reason $status',
      );
    });
  }
}
