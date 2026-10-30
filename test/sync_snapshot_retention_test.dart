import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investpro/app/services/api_service.dart';
import 'package:investpro/app/services/demo_repository.dart';
import 'package:investpro/app/services/local_storage_service.dart';
import 'package:investpro/app/services/notification_service.dart';

class SnapshotApi extends ApiService {
  bool fail = false, empty = false, malformed = false;
  String balance = '20.00';
  Completer<Map<String, dynamic>>? pendingProfile;
  static final profile = {
    'id': 'investor',
    'fullName': 'Investor',
    'user': {
      'id': 'user',
      'status': 'ACTIVE',
      'email': 'investor@example.test',
    },
  };
  @override
  Future<String?> getAccessToken() async => 'fixture-token';
  @override
  Future<Map<String, dynamic>> object(String path) async => {
    'status': 'ACTIVE',
  };
  @override
  Future<Map<String, dynamic>?> getProfile() async =>
      pendingProfile == null ? profile : await pendingProfile!.future;
  @override
  Future<Map<String, dynamic>?> getDashboard() async => {
    'portfolio': {
      'availableBalance': balance,
      'totalInvested': '100',
      'totalReturns': '3',
    },
  };
  @override
  Future<List<Map<String, dynamic>>> getEligibleProjects({
    String? projectTypeId,
    String? search,
  }) async => empty
      ? []
      : [
          {
            'id': 'project',
            'title': 'Cached Project',
            'status': 'ACTIVE',
            'targetAmount': 10000,
            'fundedAmount': 1000,
            'minInvestment': 100,
            'expectedRoi': 12,
            'tenureMonths': 12,
          },
        ];
  @override
  Future<List<dynamic>?> getInvestments() async => malformed ? [null] : [];
  @override
  Future<List<dynamic>?> getWithdrawals() async => [];
  @override
  Future<List<dynamic>?> getTransactions() async => [];
  @override
  Future<List<dynamic>?> getReturns() async {
    if (fail) {
      final options = RequestOptions(path: '/mobile/returns');
      throw DioException(
        requestOptions: options,
        response: Response(
          requestOptions: options,
          statusCode: 500,
          data: {'message': 'Server unavailable'},
        ),
        type: DioExceptionType.badResponse,
      );
    }
    return [];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  DemoRepository repo(SnapshotApi api) {
    final storage = LocalStorageService();
    return DemoRepository(storage, NotificationService(storage), api);
  }

  test('temporary endpoint failure preserves coherent account content and successful retry clears the error', () async {
    final api = SnapshotApi();
    final live = repo(api);
    await live.syncFromBackend();
    expect(live.availableBalance.value, 20);
    expect(live.projects.single.name, 'Cached Project');
    api.fail = true;
    api.balance = '99';
    await expectLater(live.syncFromBackend(), throwsA(isA<DioException>()));
    expect(live.availableBalance.value, 20);
    expect(live.projects.single.name, 'Cached Project');
    expect(live.currentUser.value.fullName, 'Investor');
    api.fail = false;
    await live.syncFromBackend();
    expect(live.availableBalance.value, 99);
    expect(live.syncError.value, isEmpty);
  });
  test(
    'successful empty server collection replaces old cached projects',
    () async {
      final api = SnapshotApi();
      final live = repo(api);
      await live.syncFromBackend();
      api.empty = true;
      await live.syncFromBackend();
      expect(live.projects, isEmpty);
    },
  );
  test('late snapshot after session clear cannot restore old data or error banner state', () async {
    final api = SnapshotApi();
    final live = repo(api);
    await live.syncFromBackend();
    api.pendingProfile = Completer<Map<String, dynamic>>();
    final refresh = live.syncFromBackend();
    await Future<void>.delayed(Duration.zero);
    live.clearLiveData();
    api.pendingProfile!.complete(SnapshotApi.profile);
    await expectLater(refresh, throwsStateError);
    expect(live.currentUser.value.id, isEmpty);
    expect(live.projects, isEmpty);
    expect(live.syncError.value, isEmpty);
    expect(live.isSyncing.value, false);
  });  test('malformed snapshot records cannot partially replace valid account totals',()async{
    final api=SnapshotApi();final live=repo(api);await live.syncFromBackend();api.balance='99';api.malformed=true;
    await expectLater(live.syncFromBackend(),throwsA(isA<TypeError>()));expect(live.availableBalance.value,20);expect(live.projects.single.name,'Cached Project');
  });

}
