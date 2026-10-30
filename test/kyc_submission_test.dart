import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;
import 'package:google_fonts/google_fonts.dart';
import 'package:investpro/app/controllers/kyc_controller.dart';
import 'package:investpro/app/services/api_service.dart';
import 'package:investpro/app/theme/app_theme.dart';
import 'package:investpro/app/views/kyc/kyc_view.dart';

final pdf = Uint8List.fromList(utf8.encode('%PDF-1.7\nfixture'));

class KycApi extends ApiService {
  int sent = 0;
  bool fail = false;
  List<dynamic> records = [];
  @override
  Future<Map<String, dynamic>> kycConfig() async => {
    'maxBytes': 5242880,
    'documentTypes': ['PAN_CARD', 'AADHAR_CARD', 'PASSPORT', 'BANK_STATEMENT'],
  };
  @override
  Future<Map<String, dynamic>> kycStatus() async => {
    'status': records.isEmpty ? 'NOT_SUBMITTED' : records.first['status'],
  };
  @override
  Future<List<dynamic>> kyc() async => records;
  @override
  Future<Map<String, dynamic>> submitKyc(
    String type,
    List<int> bytes,
    String name, {
    void Function(int, int)? onSendProgress,
  }) async {
    sent++;
    if (fail) {
      throw DioException(
        requestOptions: RequestOptions(),
        response: Response(
          requestOptions: RequestOptions(),
          statusCode: 503,
          data: {'message': 'Private KYC storage is not configured'},
        ),
      );
    }
    onSendProgress?.call(bytes.length, bytes.length);
    records = [
      {
        'id': 'saved-id',
        'documentType': type,
        'status': 'PENDING',
        'createdAt': '2026-10-30',
      },
    ];
    return records.first;
  }
}

class MultipartAdapter implements HttpClientAdapter {
  String? body, contentType;
  Map<String, dynamic>? headers;
  bool accepted = true;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    headers = options.headers;
    contentType = options.contentType;
    final data = await requestStream!.expand((chunk) => chunk).toList();
    body = utf8.decode(data);
    return ResponseBody.fromString(
      jsonEncode({
        'success': accepted,
        'data': accepted ? {'id': 'stored', 'status': 'PENDING'} : null,
      }),
      200,
      headers: {
        Headers.contentTypeHeader: ['application/json'],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class RefreshableApi extends ApiService {
  String token = 'expired';
  @override
  Future<String?> getAccessToken() async => token;
  @override
  Future<String?> getRefreshToken() async => 'refresh-fixture';
  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    token = accessToken;
  }
}

class ExpiredUploadAdapter extends MultipartAdapter {
  int uploads = 0;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (options.path == '/auth/refresh') {
      return ResponseBody.fromString(
        jsonEncode({
          'success': true,
          'data': {'accessToken': 'rotated', 'refreshToken': 'rotated-refresh'},
        }),
        200,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    uploads++;
    final success = await super.fetch(options, requestStream, cancelFuture);
    if (uploads == 1) {
      return ResponseBody.fromString(
        '{"success":false,"message":"Expired token"}',
        401,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
        },
      );
    }
    return success;
  }
}

void main() {
  late KycApi api;
  late KycController controller;
  setUp(() {
    Get.testMode = true;
    GoogleFonts.config.allowRuntimeFetching = false;
    api = KycApi();
    Get.put<ApiService>(api);
    controller = Get.put(KycController(api));
  });
  tearDown(() => Get.reset());
  test(
    'selection, duplicate prevention and successful persistence status refresh',
    () async {
      await controller.load();
      controller.selectFile('file.pdf', pdf);
      expect(controller.selectionError, isNull);
      expect(await controller.submit(), isTrue);
      expect(api.sent, 1);
      expect(controller.status.value, 'PENDING');
      expect(controller.bytes.value, isNull);
      controller.selectFile('again.pdf', pdf);
      expect(await controller.submit(), isFalse);
      expect(api.sent, 1);
    },
  );
  test('rejected documents can be replaced and resubmitted; safe backend error remains visible', () async {
    api.records = [
      {
        'id': 'old',
        'documentType': 'PAN_CARD',
        'status': 'REJECTED',
        'rejectionReason': 'Replace unreadable page',
      },
    ];
    await controller.load();
    controller.selectFile('new.pdf', pdf);
    api.fail = true;
    expect(await controller.submit(), isFalse);
    expect(controller.error.value, 'Private KYC storage is not configured');
    expect(controller.bytes.value, isNotNull);
    api.fail = false;
    expect(await controller.submit(), isTrue);
  });
  test('validates configured file size and actual file content and supports removal', () async {
    await controller.load();
    controller.selectFile(
      'fake.pdf',
      Uint8List.fromList(utf8.encode('executablefixture')),
    );
    expect(controller.bytes.value, isNull);
    expect(controller.error.value, contains('Unsupported'));
    controller.selectFile('large.pdf', Uint8List(5242881));
    expect(controller.bytes.value, isNull);
    controller.selectFile('file.pdf', pdf);
    controller.removeFile();
    expect(controller.bytes.value, isNull);
  });
  test(
    'Dio sends real multipart bytes, exact fields and an automatic boundary',
    () async {
      final service = ApiService();
      service.dio = Dio(
        BaseOptions(
          baseUrl: 'https://example.test',
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer fixture-token',
          },
        ),
      );
      final adapter = MultipartAdapter();
      service.dio.httpClientAdapter = adapter;
      expect(
        (await service.submitKyc('PAN_CARD', pdf, 'identity.pdf'))['id'],
        'stored',
      );
      expect(adapter.contentType, contains('multipart/form-data; boundary='));
      expect(adapter.body, contains('name="documentType"'));
      expect(adapter.body, contains('PAN_CARD'));
      expect(
        adapter.body,
        contains('name="document"; filename="identity.pdf"'),
      );
      expect(adapter.body, contains('%PDF-1.7'));
      expect(adapter.headers?['Authorization'], 'Bearer fixture-token');
      adapter.accepted = false;
      await expectLater(
        service.submitKyc('PAN_CARD', pdf, 'identity.pdf'),
        throwsStateError,
      );
    },
  );
  test('expired access token retries a fresh multipart stream after authenticated refresh', () async {
    final service = await RefreshableApi().init(
      baseUrl: 'https://example.test',
    ) as RefreshableApi;
    final adapter = ExpiredUploadAdapter();
    service.dio.httpClientAdapter = adapter;
    expect(
      (await service.submitKyc('PAN_CARD', pdf, 'document.pdf'))['id'],
      'stored',
    );
    expect(adapter.uploads, 2);
    expect(adapter.headers?['Authorization'], 'Bearer rotated');
    expect(adapter.body, contains('%PDF-1.7'));
  });
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(1024, 1366),
  ]) {
    testWidgets('KYC form and selected file fit $size at accessibility scale', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await controller.load();
      controller.selectFile(
        'Selected identity document with a long filename.pdf',
        pdf,
      );
      await tester.pumpWidget(
        GetMaterialApp(
          theme: AppTheme.lightTheme,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: const KycView(),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Submit documents'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Submit documents'));
      await tester.pumpAndSettle();
      expect(api.sent, 1);
      expect(
        find.text(
          'KYC documents submitted successfully. Your verification is pending admin review.',
        ),
        findsOneWidget,
      );
    });
  }
}
