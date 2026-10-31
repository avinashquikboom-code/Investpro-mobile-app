import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:investpro/app/controllers/navigation_controller.dart';
import 'package:investpro/app/widgets/bottom_nav_bar.dart';
import 'package:investpro/app/constants/app_strings.dart';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:investpro/app/controllers/returns_controller.dart';
import 'package:investpro/app/models/user_model.dart';
import 'package:investpro/app/services/api_service.dart';
import 'package:investpro/app/services/demo_repository.dart';
import 'package:investpro/app/services/local_storage_service.dart';
import 'package:investpro/app/services/notification_service.dart';
import 'package:investpro/app/theme/app_theme.dart';
import 'package:investpro/app/views/returns/returns_view.dart';
import 'package:investpro/app/views/returns/returns_overview.dart';
import 'package:investpro/app/widgets/returns_bar_chart.dart';

import 'returns_workspace_test.dart' as fixture;

class LiveApi extends fixture.FakeApi {
  Map<String, dynamic> data = fixture.snapshot();
  bool error = false;
  int calls = 0;
  Completer<Map<String, dynamic>>? waiting;
  @override
  Future<Map<String, dynamic>> getReturnsWorkspace(String period) async {
    calls++;
    if (waiting != null) return waiting!.future;
    if (error) throw StateError('Network unavailable');
    return {...data, 'period': period.toLowerCase()};
  }
}

class ReturnsTestRepository extends DemoRepository {
  ReturnsTestRepository(super.storage, super.notifications, super.api);
  @override
  Future<void> loadData() async {
    isSyncing.value = true;
    isSyncing.value = false;
  }
}

void main() {
  late LiveApi api;
  late ReturnsController controller;
  late ReturnsTestRepository repo;
  setUpAll(() async {
    final loader = FontLoader('packages/remixicon/remix')
      ..addFont(rootBundle.load('packages/remixicon/fonts/remix.ttf'));
    await loader.load();
  });
  setUp(() {
    Get.testMode = true;
    GoogleFonts.config.allowRuntimeFetching = false;
    final storage = Get.put(LocalStorageService(backend: fixture.Store()));
    api = LiveApi();
    Get.put<ApiService>(api);
    repo = Get.put(
      ReturnsTestRepository(storage, NotificationService(storage), api),
    );
    repo.currentUser.value = const UserModel(
      id: 'investor',
      fullName: 'Investor',
      email: 'test@example.test',
      mobileNumber: '',
    );
    controller = Get.put(ReturnsController(repo));
    api.data['analytics'] = [
      {'date': '2026-09-01', 'label': 'Sep 2026', 'amount': '80.00'},
      {'date': '2026-10-01', 'label': 'Oct 2026', 'amount': '100.00'},
    ];
    api.data['payouts'][0].addAll({
      'id': 'paid',
      'investmentReference': 'INV-real',
      'dueDate': '2025-12-30',
      'status': 'SUCCESS',
    });
  });
  tearDown(() => Get.reset());
  Future<void> mount(
    WidgetTester t, {
    Size size = const Size(390, 844),
    double scale = 1,
    bool settle = true,
  }) async {
    t.view.devicePixelRatio = 1;
    t.view.physicalSize = size;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: const RepaintBoundary(
          key: ValueKey('returns-preview'),
          child: ReturnsView(),
        ),
      ),
    );
    if (settle) {
      await t.pumpAndSettle();
    } else {
      await t.pump();
    }
  }

  testWidgets(
    'live summary excludes principal; filters and comparison reflect server buckets',
    (t) async {
      await mount(t);
      final previewPath = Platform.environment['RETURNS_PREVIEW_PATH'];
      if (previewPath != null) {
        await t.runAsync(() async {
          final boundary = t.renderObject<RenderRepaintBoundary>(
            find.byKey(const ValueKey('returns-preview')),
          );
          final image = await boundary.toImage(pixelRatio: 2);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await File(previewPath).writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      expect(
        find.text('Track your investment returns and payouts'),
        findsOneWidget,
      );
      expect(
        t.widget<Text>(find.byKey(const ValueKey('total-earned-returns'))).data,
        '₹ 100.01',
      );
      expect(find.text('+25.0%'), findsOneWidget);
      for (final period in ['Quarterly', 'Yearly', 'Monthly']) {
        await t.tap(find.text(period));
        await t.pumpAndSettle();
        expect(controller.selectedPeriod.value, period);
        expect(find.text('$period breakdown'), findsOneWidget);
      }
      final calls = api.calls;
      await t.tap(find.text('Monthly'));
      await t.pumpAndSettle();
      expect(api.calls, calls);
    },
  );
  testWidgets('bar tooltip shows exact amount and resets across filters', (
    t,
  ) async {
    await mount(t);
    await t.ensureVisible(find.byKey(const ValueKey('return-bar-1')));
    await t.tap(find.byKey(const ValueKey('return-bar-1')));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('return-chart-tooltip')), findsOneWidget);
    expect(
      t
          .widget<Text>(
            find.descendant(
              of: find.byKey(const ValueKey('return-chart-tooltip')),
              matching: find.byType(Text),
            ),
          )
          .data,
      'Oct · ₹ 100',
    );
    await t.ensureVisible(find.text('Quarterly'));
    await t.tap(find.text('Quarterly'));
    await t.pumpAndSettle();
    expect(find.byKey(const ValueKey('return-chart-tooltip')), findsNothing);
  });
  testWidgets(
    'history opens real payout details and preserves separate principal',
    (t) async {
      await mount(t);
      await t.ensureVisible(find.byKey(const ValueKey('payout-paid')));
      expect(find.text('Completed'), findsOneWidget);
      await t.tap(find.byKey(const ValueKey('payout-paid')));
      await t.pumpAndSettle();
      expect(find.text('Return Details'), findsOneWidget);
      expect(find.text('INV-real'), findsOneWidget);
      expect(find.text('paid-reference'), findsOneWidget);
      expect(find.text('Principal returned separately'), findsOneWidget);
    },
  );
  test('next return ignores overdue and paid schedules, keeps authoritative profit amount', () {
    api.data['upcoming'].addAll([
      {'dueDate': '2020-01-01', 'profitAmount': '999', 'status': 'PENDING'},
      {'dueDate': '2029-01-01', 'profitAmount': '555', 'status': 'PAID'},
      {'dueDate': '2028-01-01', 'profitAmount': '11.01', 'status': 'SCHEDULED'},
    ]);
    expect(ReturnsOverview.nextReturn(api.data)?['profitAmount'], '11.01');
    expect(ReturnsOverview.payoutStatus({'status': 'PENDING'}), 'Pending');
    expect(
      ReturnsOverview.payoutStatus({'status': 'PROCESSING'}),
      'Processing',
    );
    expect(ReturnsOverview.payoutStatus({'status': 'FAILED'}), 'Failed');
    api.data['analytics'][0]['amount'] = '0';
    expect(ReturnsOverview.comparison(api.data), isNull);
  });
  testWidgets(
    'empty snapshot shows honest zero, neutral growth, no upcoming schedule',
    (t) async {
      api.data = {
        ...fixture.snapshot(),
        'summary': {'totalEarnedReturns': '0'},
        'projects': [],
        'analytics': [],
        'payouts': [],
        'upcoming': [],
      };
      await mount(t);
      expect(find.text('₹ 0'), findsOneWidget);
      expect(find.text('No returns yet'), findsOneWidget);
      await t.ensureVisible(find.text('No upcoming returns scheduled'));
      expect(find.text('No upcoming returns scheduled'), findsOneWidget);
      expect(find.text('No previous period comparison'), findsOneWidget);
    },
  );
  testWidgets('initial skeleton, retained data on error, and retry', (t) async {
    api.waiting = Completer();
    await mount(t, settle: false);
    expect(find.bySemanticsLabel('Loading returns'), findsOneWidget);
    api.waiting!.complete(api.data);
    api.waiting = null;
    await t.pumpAndSettle();
    api.error = true;
    await controller.loadWorkspace();
    await t.pumpAndSettle();
    expect(find.textContaining('Unable to refresh returns'), findsOneWidget);
    expect(find.byKey(const ValueKey('total-earned-returns')), findsOneWidget);
    api.error = false;
    await t.tap(find.text('Retry'));
    await t.pumpAndSettle();
    expect(find.text('Retry'), findsNothing);
  });
  testWidgets('pull to refresh invokes the existing refresh action', (t) async {
    await mount(t);
    final before = api.calls;
    await t.drag(find.byType(ListView).first, const Offset(0, 400));
    await t.pumpAndSettle();
    expect(api.calls, greaterThan(before));
  });
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(844, 390),
    const Size(768, 1024),
    const Size(1024, 768),
  ]) {
    testWidgets('responsive live returns at $size with large text', (t) async {
      api.data['summary']['totalEarnedReturns'] = '987654321.99';
      api.data['payouts'][0]['profitAmount'] = '12345678.99';
      await mount(t, size: size, scale: 2);
      expect(t.takeException(), isNull);
      for (var i = 0; i < 7; i++) {
        await t.drag(find.byType(ListView).first, const Offset(0, -350));
        await t.pumpAndSettle();
        expect(t.takeException(), isNull);
      }
      expect(find.byType(ReturnsBarChart), findsOneWidget);
    });
  }
  testWidgets(
    'dense buckets, zero values and very large tooltips stay scrollable',
    (t) async {
      api.data['analytics'] = [
        for (var i = 1; i <= 12; i++)
          {
            'date': '2026-${i.toString().padLeft(2, '0')}-01T00:00:00Z',
            'label': 'Month $i',
            'amount': i == 1 ? '0' : '999999999999.99',
          },
      ];
      await mount(t, size: const Size(320, 568), scale: 2);
      final chart = t.widget<ReturnsBarChart>(find.byType(ReturnsBarChart));
      expect(chart.points.length, 12);
      expect(chart.points.first.amount, 0);
      await t.ensureVisible(find.byKey(const ValueKey('return-bar-11')));
      await t.pumpAndSettle();
      await t.tap(find.byKey(const ValueKey('return-bar-11')));
      await t.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('return-chart-tooltip')),
        findsOneWidget,
      );
      expect(t.takeException(), isNull);
    },
  );
  testWidgets('uses one existing bottom navigation and keeps Returns active', (
    t,
  ) async {
    final nav = Get.put(NavigationController())..goToReturns();
    await t.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme,
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const Scaffold(
          body: ReturnsView(),
          bottomNavigationBar: CustomBottomNavBar(),
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.byType(CustomBottomNavBar), findsOneWidget);
    expect(nav.currentIndex.value, 3);
    await t.tap(find.text('Home'));
    await t.pumpAndSettle();
    expect(nav.currentIndex.value, 0);
    await t.tap(find.text('Returns').last);
    await t.pumpAndSettle();
    expect(nav.currentIndex.value, 3);
  });
  test('a new session for the same account cannot reuse its old in-flight snapshot', () async {
    final old = Completer<Map<String, dynamic>>();
    api.waiting = old;
    final task = controller.loadWorkspace();
    repo.currentUser.value = const UserModel(
      id: '',
      fullName: '',
      email: '',
      mobileNumber: '',
    );
    final current = Completer<Map<String, dynamic>>();
    api.waiting = current;
    final calls = api.calls;
    repo.currentUser.value = const UserModel(
      id: 'investor',
      fullName: 'Investor',
      email: 'test@example.test',
      mobileNumber: '',
    );
    expect(api.calls, calls + 1);
    old.complete({
      ...api.data,
      'summary': {'totalEarnedReturns': '999'},
    });
    await task;
    expect(controller.workspace.value, isNull);
    current.complete(api.data);
    await Future<void>.delayed(Duration.zero);
    expect(
      controller.workspace.value?['summary']['totalEarnedReturns'],
      '100.01',
    );
  });
  test('same-period simultaneous reads share one API request', () async {
    api.waiting = Completer();
    final before = api.calls;
    final a = controller.loadWorkspace();
    final b = controller.loadWorkspace();
    expect(api.calls, before + 1);
    api.waiting!.complete(api.data);
    await Future.wait([a, b]);
  });
}
