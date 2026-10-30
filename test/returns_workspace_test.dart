import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:investpro/app/controllers/returns_controller.dart';
import 'package:investpro/app/services/api_service.dart';
import 'package:investpro/app/services/demo_repository.dart';
import 'package:investpro/app/services/local_storage_service.dart';
import 'package:investpro/app/services/notification_service.dart';
import 'package:investpro/app/models/user_model.dart';
import 'package:investpro/app/theme/app_theme.dart';
import 'package:investpro/app/views/returns/returns_view.dart';
import 'package:investpro/app/views/returns/returns_withdrawal_view.dart';

class Store implements LocalStore {
  final values = <String, dynamic>{};
  @override
  dynamic read(String k) => values[k];
  @override
  Future<void> write(String k, dynamic v) async {
    values[k] = v;
  }
}

Map<String, dynamic> snapshot([String period = 'monthly']) => {
  'summary': {
    'totalExpectedReturns': '300.00',
    'totalEarnedReturns': '100.01',
    'totalPaidReturns': '100.01',
    'totalWithdrawable': '100.01',
    'totalWithdrawn': '0',
    'pendingWithdrawal': '0',
    'upcomingReturns': '199.99',
    'earningsRule': 'Credited profit only',
  },
  'projects': [
    {
      'projectId': 'p',
      'projectName':
          'Long project name that wraps on a small phone without overflowing',
      'projectStatus': 'ACTIVE',
      'investmentIds': ['i', 'j'],
      'investedAmount': '1000',
      'expectedRoi': '12',
      'tenureMonths': [12],
      'expectedReturns': '300',
      'earnedReturns': '100.01',
      'paidReturns': '100.01',
      'upcomingReturns': '199.99',
      'availableToWithdraw': '100.01',
      'pendingWithdrawal': '0',
      'nextReturnDate': '2030-01-01',
    },
  ],
  'analytics': [
    {'date': '2026-01-01', 'label': 'Jan 2026', 'amount': '100.01'},
  ],
  'upcoming': [
    {
      'projectName': 'Future project',
      'dueDate': '2030-01-01',
      'profitAmount': '199.99',
      'principalAmount': '1000',
      'status': 'SCHEDULED',
      'overdue': false,
    },
  ],
  'payouts': [
    {
      'projectName': 'Paid project',
      'date': '2026-01-01',
      'profitAmount': '100.01',
      'principalAmount': '1000',
      'totalAmount': '1100.01',
      'reference': 'paid-reference',
    },
  ],
  'withdrawals': [],
  'asOf': '2026-10-31',
  'period': period,
};

class FakeApi extends ApiService {
  bool fail = false;
  final keys = <String?>[], amounts = <String?>[], modes = <bool>[];
  final pending = <String, Completer<Map<String, dynamic>>>{};
  @override
  Future<Map<String, dynamic>> getReturnsWorkspace(String period) async =>
      pending[period]?.future ?? snapshot(period.toLowerCase());
  @override
  Future<Map<String, dynamic>> getWallet() async => {
    'availableBalance': '1100.01',
    'minimumWithdrawal': '100',
    'maximumWithdrawal': null,
    'withdrawalFee': '0',
    'banks': [
      {
        'id': 'bank',
        'bankName': 'Verified Bank',
        'accountNumber': '•••• 1234',
        'isVerified': true,
        'isPrimary': true,
      },
      {'id': 'unverified', 'bankName': 'Unverified Bank', 'isVerified': false},
    ],
  };
  @override
  Future<Map<String, dynamic>?> createWithdrawal({
    required double amount,
    String? exactAmount,
    String? projectId,
    bool returnsOnly = false,
    String? bankAccountId,
    String? notes,
    String? idempotencyKey,
  }) async {
    keys.add(idempotencyKey);
    amounts.add(exactAmount);
    modes.add(returnsOnly);
    throw StateError('Simulated uncertain network response');
  }
}

void main() {
  late FakeApi api;
  late ReturnsController controller;
  late DemoRepository repo;
  late LocalStorageService storage;
  setUp(() {
    Get.testMode = true;
    GoogleFonts.config.allowRuntimeFetching = false;
    storage = LocalStorageService(backend: Store());
    Get.put(storage);
    api = FakeApi();
    Get.put<ApiService>(api);
    repo = DemoRepository(storage, NotificationService(storage), api);
    Get.put(repo);
    repo.currentUser.value = const UserModel(
      id: 'investor',
      fullName: 'Investor',
      email: 'fixture@example.test',
      mobileNumber: '',
    );
    controller = Get.put(ReturnsController(repo));
  });
  tearDown(() {
    Get.reset();
  });
  Future<void> mount(WidgetTester tester, Widget view, Size size, {TargetPlatform platform = TargetPlatform.android}) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    tester.view.padding = const FakeViewPadding(top: 44, bottom: 34);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    await tester.pumpWidget(
      GetMaterialApp(theme: AppTheme.lightTheme.copyWith(platform: platform), home: view),
    );
    await tester.pumpAndSettle();
  }

  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    for (final size in [
      const Size(320, 640),
      const Size(390, 844),
      const Size(768, 1024),
      const Size(1024, 768),
    ]) {
      testWidgets(
        'live returns scroll without overflow on $platform at $size',
        (tester) async {
          await mount(tester, const ReturnsView(), size, platform: platform);
          expect(find.text('Earned returns'), findsOneWidget);
          expect(find.text('₹ 100.01'), findsWidgets);
          for (var i = 0; i < 14; i++) {
            await tester.drag(
              find.byType(ListView).first,
              const Offset(0, -400),
            );
            await tester.pumpAndSettle();
            expect(tester.takeException(), isNull);
          }
          expect(find.text('Withdrawal History'), findsOneWidget);
        },
      );
    }
  }
  testWidgets(
    'withdrawal excludes unverified bank, sends exact money and reuses durable retry key across restart',
    (tester) async {
      await mount(
        tester,
        const ReturnsWithdrawalView(projectId: 'p'),
        const Size(390, 844),
      );
      await tester.enterText(find.byType(TextField), '100.01');
      final submit = find.text('Submit Withdrawal Request');
      await tester.ensureVisible(submit);
      await tester.tap(submit);
      await tester.pumpAndSettle();
      expect(api.amounts, ['100.01']);
      expect(api.modes, [true]);
      expect(api.keys.single, isNotEmpty);
      final first = api.keys.single;
      await tester.pumpWidget(const SizedBox());
      await tester.pumpAndSettle();
      await mount(
        tester,
        const ReturnsWithdrawalView(projectId: 'p'),
        const Size(390, 844),
      );
      await tester.enterText(find.byType(TextField), '100.01');
      await tester.ensureVisible(find.text('Submit Withdrawal Request'));
      await tester.tap(find.text('Submit Withdrawal Request'));
      await tester.pumpAndSettle();
      expect(api.keys, [first, first]);
      expect(find.textContaining('Unverified Bank'), findsNothing);
    },
  );
  test(
    'a slow old period response cannot overwrite the selected period',
    () async {
      api.pending['Monthly'] = Completer();
      api.pending['Yearly'] = Completer();
      final first = controller.loadWorkspace();
      controller.setPeriod('Yearly');
      api.pending['Yearly']!.complete(snapshot('yearly'));
      await Future<void>.delayed(Duration.zero);
      api.pending['Monthly']!.complete(snapshot('monthly'));
      await first;
      expect(controller.workspace.value?['period'], 'yearly');
    },
  );
  test('sign-out clears previous investor financial snapshot', () async {
    await controller.loadWorkspace();
    expect(controller.workspace.value, isNotNull);
    repo.currentUser.value = const UserModel(
      id: '',
      fullName: '',
      email: '',
      mobileNumber: '',
    );
    expect(controller.workspace.value, isNull);
  });
}
