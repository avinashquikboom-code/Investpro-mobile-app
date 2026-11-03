import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:investpro/app/controllers/home_controller.dart';
import 'package:investpro/app/models/user_model.dart';
import 'package:investpro/app/services/api_service.dart';
import 'package:investpro/app/services/demo_repository.dart';
import 'package:investpro/app/services/local_storage_service.dart';
import 'package:investpro/app/services/notification_service.dart';
import 'package:investpro/app/widgets/next_hourly_payout_card.dart';

import 'returns_workspace_test.dart' show Store;

class PayoutApi extends ApiService {
  Map<String, dynamic> data = {'upcoming': []};
  Completer<Map<String, dynamic>>? pending;
  bool fail = false;
  int calls = 0;
  @override
  Future<Map<String, dynamic>> getHourlyReturnsWorkspace(DateTime day) async {
    calls++;
    if (fail) throw StateError('offline');
    return pending?.future ?? data;
  }
}

void main() {
  late HomeController controller;
  late DemoRepository repo;
  late PayoutApi api;
  setUp(() {
    Get.testMode = true;
    final storage = LocalStorageService(backend: Store());
    final notifications = NotificationService(storage);
    api = Get.put<ApiService>(PayoutApi()) as PayoutApi;
    repo = DemoRepository(storage, notifications, api);
    controller = Get.put(HomeController(repo, notifications));
  });
  tearDown(() => Get.reset());

  test(
    'loads earliest server payout and clears stale data on error/sign-out',
    () async {
      api.data = {
        'upcoming': [
          {
            'dueDate': '2030-01-01T02:00:00Z',
            'status': 'SCHEDULED',
            'expectedAmount': '0.70',
          },
          {
            'dueDate': '2030-01-01T01:00:00Z',
            'status': 'SCHEDULED',
            'expectedAmount': '0.69',
          },
          {'dueDate': '2029-01-01T01:00:00Z', 'status': 'PAID'},
          {'dueDate': '2020-01-01T01:00:00Z', 'status': 'SCHEDULED'},
        ],
      };
      repo.currentUser.value = const UserModel(
        id: 'investor',
        fullName: '',
        email: '',
        mobileNumber: '',
      );
      await controller.loadNextHourlyPayout();
      expect(controller.nextHourlyPayout.value?['expectedAmount'], '0.69');
      api.fail = true;
      await controller.loadNextHourlyPayout();
      expect(controller.hourlyPayoutError.value, isTrue);
      expect(controller.nextHourlyPayout.value, isNull);
      repo.currentUser.value = const UserModel(
        id: '',
        fullName: '',
        email: '',
        mobileNumber: '',
      );
      expect(controller.hourlyPayoutError.value, isFalse);
      expect(controller.nextHourlyPayout.value, isNull);
    },
  );

  test('old account response cannot populate a signed-out home', () async {
    api.pending = Completer();
    repo.currentUser.value = const UserModel(
      id: 'old',
      fullName: '',
      email: '',
      mobileNumber: '',
    );
    final request = controller.loadNextHourlyPayout();
    repo.currentUser.value = const UserModel(
      id: '',
      fullName: '',
      email: '',
      mobileNumber: '',
    );
    api.pending!.complete({
      'upcoming': [
        {
          'dueDate': '2030-01-01',
          'status': 'SCHEDULED',
          'expectedAmount': '99.99',
        },
      ],
    });
    await request;
    expect(controller.nextHourlyPayout.value, isNull);
  });

  testWidgets(
    'one-shot intro reveals API details and remains non-clickable on rebuild',
    (t) async {
      final payout = {
        'projectName': 'Website development',
        'expectedAmount': '0.70',
        'dueDate': DateTime.now()
            .add(const Duration(hours: 2))
            .toUtc()
            .toIso8601String(),
      };
      Future<void> mount({
        bool loading = false,
        bool error = false,
        Map<String, dynamic>? data,
      }) => t.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NextHourlyPayoutCard(
              payout: data ?? payout,
              isLoading: loading,
              hasError: error,
            ),
          ),
        ),
      );
      await mount();
      expect(find.text('Calculating next payout...'), findsOneWidget);
      expect(find.text('₹0.70'), findsNothing);
      await t.pumpAndSettle();
      expect(find.text('₹0.70'), findsOneWidget);
      expect(find.text('Website development'), findsOneWidget);
      expect(find.textContaining(RegExp(r'Time until payout · [0-9]{2,}:[0-9]{2}:[0-9]{2}')), findsOneWidget);
      final local = DateTime.parse(payout['dueDate']!).toLocal();
      expect(find.text(DateFormat('dd MMM yyyy').format(local)), findsOneWidget);
      expect(find.text(DateFormat('hh:mm a').format(local)), findsOneWidget);
      final card = find.byType(NextHourlyPayoutCard);
      expect(
        find.descendant(of: card, matching: find.byType(InkWell)),
        findsNothing,
      );
      expect(
        find.descendant(of: card, matching: find.byType(GestureDetector)),
        findsNothing,
      );
      await t.tap(find.text('Next Hourly Payout'));
      expect(repo.availableBalance.value, 0);
      expect(repo.transactions, isEmpty);
      await mount();
      expect(find.text('Calculating next payout...'), findsNothing);
      await mount(loading: true);
      await t.pumpAndSettle();
      expect(find.text('Calculating next payout...'), findsOneWidget);
      await mount(error: true);
      await t.pumpAndSettle();
      expect(
        find.text('Payout details are temporarily unavailable'),
        findsOneWidget,
      );
      expect(find.text('₹0.70'), findsNothing);
      await mount(data: {...payout, 'dueDate': '2020-01-01T00:00:00Z'});
      await t.pumpAndSettle();
      expect(find.text('Awaiting wallet credit'), findsOneWidget);
      expect(find.byKey(const ValueKey('payout-time-remaining')), findsNothing);
      expect(find.text('₹0.70'), findsNothing);
      await t.pumpWidget(const SizedBox());
    },
  );

  testWidgets('preloaded tabs wait until visible before the one-shot intro', (t) async {
    Future<void> mount(bool active) => t.pumpWidget(MaterialApp(home: Scaffold(
      body: NextHourlyPayoutCard(isActive: active, payout: {
        'dueDate': DateTime.now().add(const Duration(hours: 2)).toIso8601String(),
        'expectedAmount': '1.23',
      }))));
    await mount(false);
    await t.pump(const Duration(seconds: 2));
    expect(find.text('₹1.23'), findsNothing);
    await mount(true);
    expect(find.text('Calculating next payout...'), findsOneWidget);
    await t.pumpAndSettle();
    expect(find.text('₹1.23'), findsOneWidget);
    expect(t.binding.hasScheduledFrame, isFalse);
    await mount(true);
    expect(find.text('Calculating next payout...'), findsNothing);
    await t.pumpWidget(const SizedBox());
  });

  testWidgets('empty and error information fit large text on narrow screens', (
    t,
  ) async {
    t.view.physicalSize = const Size(320, 640);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    Future<void> mount(bool error) => t.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            textScaler: TextScaler.linear(1.5),
            disableAnimations: true,
          ),
          child: Scaffold(
            body: NextHourlyPayoutCard(payout: null, hasError: error),
          ),
        ),
      ),
    );
    await mount(false);
    await t.pumpAndSettle();
    expect(find.text('No upcoming hourly payout'), findsOneWidget);
    await mount(true);
    await t.pumpAndSettle();
    expect(
      find.text('Payout details are temporarily unavailable'),
      findsOneWidget,
    );
    expect(t.takeException(), isNull);
    await t.pumpWidget(const SizedBox());
  });
  testWidgets('clock hands move only on an active screen with motion enabled', (t) async {
    final payout = {'expectedAmount': '0.69', 'dueDate': DateTime.now().add(const Duration(hours: 2)).toIso8601String()};
    Future<void> mount({bool active = true, bool reduced = false}) => t.pumpWidget(MaterialApp(
      home: MediaQuery(data: MediaQueryData(disableAnimations: reduced),
        child: Scaffold(body: NextHourlyPayoutCard(payout: payout, isActive: active)))));
    double turns() => t.widget<TweenAnimationBuilder<double>>(find.byKey(const ValueKey('payout-clock-hand-motion'))).tween.end!;
    await mount();
    final before = turns();
    await t.pump(const Duration(seconds: 2));
    await t.pump(const Duration(milliseconds: 500));
    expect(turns(), greaterThan(before));
    await mount(active: false);
    final paused = turns();
    await t.pump(const Duration(seconds: 2));
    expect(turns(), paused);
    await mount(reduced: true);
    await t.pump(const Duration(seconds: 2));
    expect(turns(), paused);
    await t.pumpWidget(const SizedBox());
  });

}
