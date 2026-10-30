import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investpro/app/services/api_service.dart';
import 'package:investpro/app/services/api_diagnostics.dart';

class SessionApi extends ApiService {
  String? access = 'old', refresh = 'refresh';
  int cleared = 0;
  @override
  Future<String?> getAccessToken() async => access;
  @override
  Future<String?> getRefreshToken() async => refresh;
  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    access = accessToken;
    refresh = refreshToken;
  }

  @override
  Future<void> clearTokens() async {
    cleared++;
    sessionVersion++;
    access = null;
    refresh = null;
  }
}

class SessionAdapter implements HttpClientAdapter {
  int refreshes = 0, reads = 0;
  int? refreshStatus;
  bool networkFailure = false, limited = false;
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? stream,
    Future<void>? cancel,
  ) async {
    if (options.path == '/auth/refresh') {
      refreshes++;
      await Future<void>.delayed(Duration.zero);
      if (networkFailure) {
        throw DioException(
          requestOptions: options,
          type: DioExceptionType.connectionError,
        );
      }
      return json(
        refreshStatus ?? 200,
        refreshStatus == null
            ? {
                'success': true,
                'data': {'accessToken': 'new', 'refreshToken': 'rotated'},
              }
            : {'message': 'Session rejected'},
      );
    }
    reads++;
    if (limited) {
      return ResponseBody.fromString(
        '{"message":"Too many requests"}',
        429,
        headers: {
          Headers.contentTypeHeader: ['application/json'],
          'retry-after': ['120'],
        },
      );
    }
    return options.headers['Authorization'] == 'Bearer new'
        ? json(200, {
            'success': true,
            'data': {'status': 'ACTIVE'},
          })
        : json(401, {'message': 'Expired'});
  }

  ResponseBody json(int status, Object data) => ResponseBody.fromString(
    jsonEncode(data),
    status,
    headers: {
      Headers.contentTypeHeader: ['application/json'],
    },
  );
  @override
  void close({bool force = false}) {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<(SessionApi, SessionAdapter)> setup() async {
    final api = SessionApi();
    await api.init(baseUrl: 'https://example.test');
    final adapter = SessionAdapter();
    api.dio.httpClientAdapter = adapter;
    return (api, adapter);
  }

  test('concurrent expired requests share one refresh and replay with rotated access token', () async {
    final (api, adapter) = await setup();
    final results = await Future.wait(
      List.generate(5, (_) => api.object('/mobile/account-status')),
    );
    expect(results.every((r) => r['status'] == 'ACTIVE'), true);
    expect(adapter.refreshes, 1);
    expect(api.cleared, 0);
    expect(api.access, 'new');
  });
  test('temporary refresh connectivity failure preserves tokens and original failure type', () async {
    final (api, adapter) = await setup();
    adapter.networkFailure = true;
    await expectLater(
      api.object('/mobile/account-status'),
      throwsA(
        isA<DioException>().having(
          (e) => e.type,
          'type',
          DioExceptionType.connectionError,
        ),
      ),
    );
    expect(api.access, 'old');
    expect(api.refresh, 'refresh');
    expect(api.cleared, 0);
    expect(adapter.refreshes, 1);
  });
  test('rejected refresh expires the session once instead of retrying indefinitely', () async {
    final (api, adapter) = await setup();
    adapter.refreshStatus = 401;
    var expired = 0;
    api.onSessionExpired = () => expired++;
    await expectLater(
      api.object('/mobile/account-status'),
      throwsA(isA<DioException>()),
    );
    expect(expired, 1);
    expect(adapter.refreshes, 1);
    expect(api.access, isNull);
  });
  test('429 respects Retry-After and prevents another read from reaching transport', () async {
    final (api, adapter) = await setup();
    adapter.limited = true;
    await expectLater(
      api.object('/mobile/projects'),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          429,
        ),
      ),
    );
    final deadline = api.nextReadAt!;
    expect(
      deadline.isAfter(DateTime.now().add(const Duration(seconds: 115))),
      true,
    );
    await expectLater(
      api.object('/mobile/projects'),
      throwsA(
        isA<DioException>().having(
          (e) => e.response?.statusCode,
          'status',
          429,
        ),
      ),
    );
    expect(adapter.reads, 1);
    expect(adapter.refreshes, 0);
    expect(api.nextReadAt, deadline);
  });
  test(
    'Retry-After accepts delta seconds and HTTP date with a safe fallback',
    () {
      final now = DateTime.utc(2026, 10, 30, 10);
      expect(
        ApiDiagnostics.retryAt('120', now),
        now.add(const Duration(seconds: 120)),
      );
      expect(
        ApiDiagnostics.retryAt('Fri, 30 Oct 2026 10:05:00 GMT', now),
        DateTime.utc(2026, 10, 30, 10, 5),
      );
      expect(
        ApiDiagnostics.retryAt('invalid', now),
        now.add(const Duration(seconds: 60)),
      );
    },
  );
}
