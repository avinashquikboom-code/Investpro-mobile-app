import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:investpro/app/controllers/auth_controller.dart';
import 'package:investpro/app/controllers/investment_controller.dart';
import 'package:investpro/app/controllers/project_controller.dart';
import 'package:investpro/app/models/project_model.dart';
import 'package:investpro/app/routes/app_routes.dart';
import 'package:investpro/app/services/api_service.dart';
import 'package:investpro/app/services/demo_repository.dart';
import 'package:investpro/app/services/local_storage_service.dart';
import 'package:investpro/app/services/notification_service.dart';
import 'package:investpro/app/theme/app_colors.dart';
import 'package:investpro/app/theme/app_theme.dart';
import 'package:investpro/app/views/projects/projects_view.dart';
import 'package:investpro/app/widgets/app_back_button.dart';
import 'package:investpro/app/widgets/project_listing_card.dart';

Map<String, dynamic> record(String id, {String status = 'ACTIVE'}) => {
  'id': id,
  'title': 'Backend opportunity $id',
  'status': status,
  'projectTypeId': 'category-id',
  'projectType': {'id': 'category-id', 'name': 'abc', 'icon': 'code'},
  'location': 'Pune',
  'expectedRoi': '12.75',
  'tenureMonths': 18,
  'minInvestment': 5000,
  'targetAmount': 100000,
  'fundedAmount': 25000,
  'investorsCount': 3,
};

class Store implements LocalStore {
  final data = <String, dynamic>{};
  @override
  dynamic read(String key) => data[key];
  @override
  Future<void> write(String key, dynamic value) async {
    data[key] = value;
  }
}

class ProjectsApi extends ApiService {
  final requests = <({int page, String? category, String? search})>[];
  bool fail = false;
  bool failPage = false;
  int totalPages = 1;
  List<Map<String, dynamic>> catalog = [
    {'id': 'category-id', 'name': 'abc', 'isActive': true},
    {'id': 'other-id', 'name': 'test', 'isActive': true, 'projectsCount': 2},
  ];
  final pages = <int, List<Map<String, dynamic>>>{
    1: [record('p1')],
    2: [record('p2')],
  };
  Completer<ProjectPage>? pending;
  String? detailId;
  Map<String, dynamic>? detail = record('p1');

  @override
  Future<List<Map<String, dynamic>>> getProjectCategories() async {
    if (fail) throw Exception('offline');
    return catalog;
  }

  @override
  Future<ProjectPage> getEligibleProjectPage({
    int page = 1,
    int limit = 12,
    String? projectTypeId,
    String? search,
  }) async {
    requests.add((page: page, category: projectTypeId, search: search));
    if (fail || failPage && page > 1) throw Exception('offline');
    if (pending != null) return pending!.future;
    return ProjectPage(pages[page] ?? [], page: page, totalPages: totalPages);
  }

  @override
  Future<Map<String, dynamic>?> getProject(String id) async {
    detailId = id;
    return detail;
  }
}

class PageAdapter implements HttpClientAdapter {
  final queries = <Map<String, dynamic>>[];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    queries.add(options.queryParameters);
    final page = options.queryParameters['page'] as int;
    return ResponseBody.fromString(
      jsonEncode({
        'success': true,
        'data': [record('p$page')],
        'meta': {'totalPages': 2},
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

void main() {
  late ProjectsApi api;
  late DemoRepository repo;
  late ProjectController controller;
  late AuthController auth;
  late InvestmentController investments;
  setUp(() {
    Get.testMode = true;
    GoogleFonts.config.allowRuntimeFetching = false;
    final storage = LocalStorageService(backend: Store());
    repo = DemoRepository(storage, NotificationService(storage));
    repo.currentUser.value = repo.currentUser.value.copyWith(
      accountStatus: 'ACTIVE',
      kycStatus: 'VERIFIED',
    );
    api = ProjectsApi();
    controller = ProjectController(repo, api);
    auth = AuthController(storage, repo);
    investments = InvestmentController(repo);
  });
  tearDown(() {
    if (!controller.isClosed) controller.onClose();
    Get.reset();
  });

  test('API page transport preserves category/search and exhaustive caller pagination', () async {
    final service = ApiService();
    service.dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    final adapter = PageAdapter();
    service.dio.httpClientAdapter = adapter;
    final first = await service.getEligibleProjectPage(
      projectTypeId: 'category-id',
      search: 'Pune',
    );
    expect(first.totalPages, 2);
    expect(adapter.queries.single, {
      'page': 1,
      'limit': 12,
      'projectTypeId': 'category-id',
      'search': 'Pune',
    });
    final all = await service.getEligibleProjects(search: 'Pune');
    expect(all.map((p) => p['id']), ['p1', 'p2']);
  });

  testWidgets(
    'search debounces backend requests and accepts backend location matches',
    (tester) async {
      await controller.refreshProjects();
      controller.setSearchQuery('Pu');
      await tester.pump(const Duration(milliseconds: 200));
      controller.setSearchQuery('Pune');
      await tester.pump(const Duration(milliseconds: 349));
      expect(api.requests.length, 1);
      await tester.pump(const Duration(milliseconds: 1));
      await tester.pump();
      expect(api.requests.length, 2);
      expect(api.requests.last.search, 'Pune');
      expect(controller.filteredProjects.single.location, 'Pune');
      controller.setSearchQuery('');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pump();
      expect(api.requests.last.search, '');
    },
  );

  test('pagination preserves current records on error and retries without duplicate IDs', () async {
    api.totalPages = 2;
    await controller.refreshProjects();
    api.failPage = true;
    await controller.loadMore();
    expect(controller.remoteProjects.single.id, 'p1');
    expect(controller.pageError.value, isNotEmpty);
    expect(controller.hasMore.value, isTrue);
    api.failPage = false;
    api.pages[2] = [record('p1'), record('p2')];
    await controller.loadMore();
    expect(controller.remoteProjects.map((p) => p.id), ['p1', 'p2']);
    expect(controller.hasMore.value, isFalse);
    expect(api.requests.last.page, 2);
  });

  test('late page results cannot overwrite a new category request', () async {
    api.totalPages = 2;
    await controller.refreshProjects();
    final pending = Completer<ProjectPage>();
    api.pending = pending;
    final more = controller.loadMore();
    api.pending = null;
    controller.setCategory('other-id');
    await Future<void>.delayed(Duration.zero);
    pending.complete(ProjectPage([record('stale')], page: 2, totalPages: 2));
    await more;
    expect(controller.remoteProjects.any((p) => p.id == 'stale'), isFalse);
    expect(api.requests.last.category, 'other-id');
  });

  test(
    'status mapping and categories preserve API values without invented counts',
    () async {
      api.pages[1] = [
        for (final status in [
          'ACTIVE',
          'UPCOMING',
          'COMPLETED',
          'FUNDED',
          'CANCELLED',
          'DRAFT',
        ])
          record(status, status: status),
      ];
      await controller.refreshProjects();
      for (final status in [
        'Active',
        'Upcoming',
        'Completed',
        'Funded',
        'Cancelled',
        'Draft',
      ]) {
        controller.setFilter(status);
        expect(controller.filteredProjects.single.statusLabel, status);
      }
      expect(controller.categoryLabel('category-id'), 'abc');
      expect(controller.categoryLabel('other-id'), 'test (2)');
    },
  );

  test('eligibility requires authentication, active account, verified KYC and funding room', () {
    final project = ProjectModel.fromBackend(record('p1'));
    expect(
      controller.investmentUnavailableReason(project, authenticated: true),
      isNull,
    );
    expect(
      controller.investmentUnavailableReason(project, authenticated: false),
      isNotNull,
    );
    repo.currentUser.value = repo.currentUser.value.copyWith(
      kycStatus: 'PENDING',
    );
    expect(
      controller.investmentUnavailableReason(project, authenticated: true),
      contains('KYC'),
    );
    repo.currentUser.value = repo.currentUser.value.copyWith(
      kycStatus: 'VERIFIED',
      accountStatus: 'SUSPENDED',
    );
    expect(
      controller.investmentUnavailableReason(project, authenticated: true),
      isNotNull,
    );
    repo.currentUser.value = repo.currentUser.value.copyWith(
      accountStatus: 'ACTIVE',
    );
    expect(
      controller.investmentUnavailableReason(
        project.copyWith(raisedAmount: 99000),
        authenticated: true,
      ),
      isNotNull,
    );
    expect(
      controller.investmentUnavailableReason(
        project.copyWith(status: 'UPCOMING'),
        authenticated: true,
      ),
      isNotNull,
    );
  });

  test('optional backend presentation fields and precise funding data survive serialization', () {
    final project = ProjectModel.fromBackend({
      ...record('p1'),
      'bannerUrl': 'https://example.test/image.png',
    });
    final restored = ProjectModel.fromJson(project.toJson());
    expect(restored.location, 'Pune');
    expect(restored.imageUrl, project.imageUrl);
    expect(restored.investorCount, 3);
    expect(restored.returnRatePercent, 12.75);
    expect(restored.minInvestment, 5000);
    expect(restored.progressPercentage, 25);
    expect(restored.hasFundingData, isTrue);
    final missing = ProjectModel.fromBackend({
      'id': 'p1',
      'title': 'No funding information',
    });
    expect(missing.hasFundingData, isFalse);
    expect(missing.investorCount, isNull);
  });

  Future<void> mount(
    WidgetTester tester,
    Size size, {
    double scale = 1,
    TargetPlatform platform = TargetPlatform.android,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    tester.view.padding = const FakeViewPadding(top: 44, bottom: 24);
    addTearDown(tester.view.reset);
    Get.put(controller);
    Get.put(auth);
    auth.isLoggedIn.value = true;
    Get.put(investments);
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme.copyWith(platform: platform),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        getPages: [
          GetPage(
            name: AppRoutes.projectDetails,
            page: () => Scaffold(body: Text('Details ${Get.arguments}')),
          ),
          GetPage(
            name: AppRoutes.investNow,
            page: () => Scaffold(body: Text('Investment ${Get.arguments}')),
          ),
        ],
        home: const ProjectsView(),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final config in [
    (const Size(320, 568), 1.0, TargetPlatform.android),
    (const Size(390, 844), 1.0, TargetPlatform.iOS),
    (const Size(844, 390), 1.0, TargetPlatform.iOS),
    (const Size(1024, 1366), 1.0, TargetPlatform.iOS),
    (const Size(320, 568), 2.0, TargetPlatform.android),
  ]) {
    testWidgets('catalog card fits ${config.$1} scale ${config.$2}', (
      tester,
    ) async {
      api.pages[1] = [
        {
          ...record('p1'),
          'title': 'A long opportunity title that wraps on a small screen',
          'location': 'A long backend location across several words',
        },
      ];
      await mount(tester, config.$1, scale: config.$2, platform: config.$3);
      expect(find.byType(AppBackButton), findsNothing);
      expect(find.text('abc'), findsWidgets);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Invest Now'),
        160,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Invest Now'),
      );
      expect(button.onPressed, isNotNull);
      expect(
        Theme.of(tester.element(find.byType(ProjectListingCard)))
            .colorScheme
            .primary,
        AppColors.primary,
      );
    });
  }

  testWidgets(
    'details and investment actions use the actual ID and selected server record',
    (tester) async {
      await mount(tester, const Size(430, 932));
      await tester.ensureVisible(find.text('View Details'));
      await tester.tap(find.text('View Details'));
      await tester.pumpAndSettle();
      expect(find.text('Details p1'), findsOneWidget);
      Get.back();
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Invest Now'));
      await tester.tap(find.text('Invest Now'));
      await tester.pumpAndSettle();
      expect(api.detailId, 'p1');
      expect(find.text('Investment p1'), findsOneWidget);
      expect(investments.currentProject.value?.id, 'p1');
    },
  );

  testWidgets(
    'failed initial request offers retry and loads dynamic categories',
    (tester) async {
      api.fail = true;
      await mount(tester, const Size(390, 844));
      expect(find.text('Retry'), findsOneWidget);
      api.fail = false;
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();
      expect(find.byType(ProjectListingCard), findsOneWidget);
      expect(find.text('abc'), findsWidgets);
      expect(find.text('test (2)'), findsOneWidget);
    },
  );

  testWidgets('missing funding and investor data are omitted, not fabricated', (
    tester,
  ) async {
    api.pages[1] = [
      {'id': 'p1', 'title': 'Unavailable funding', 'status': 'ACTIVE'},
    ];
    await mount(tester, const Size(390, 844));
    expect(find.text('Funding progress'), findsNothing);
    expect(find.text('Investors'), findsNothing);
    expect(find.text('0.0% p.a.'), findsNothing);
    expect(
      tester
          .widget<ElevatedButton>(
            find.widgetWithText(ElevatedButton, 'Invest Now'),
          )
          .onPressed,
      isNull,
    );
  });
  testWidgets(
    'search clear, category IDs and status chips stay connected to the catalog',
    (tester) async {
      await mount(tester, const Size(430, 932));
      await tester.enterText(find.byType(TextField), 'Pune');
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(api.requests.last.search, 'Pune');
      await tester.tap(find.byTooltip('Clear search'));
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller?.text,
        '',
      );
      await tester.tap(find.text('test (2)'));
      await tester.pumpAndSettle();
      expect(api.requests.last.category, 'other-id');
      await tester.tap(find.text('All Categories'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Upcoming'));
      await tester.pumpAndSettle();
      expect(find.text('No Projects Found'), findsOneWidget);
      await tester.tap(find.text('Active'));
      await tester.pumpAndSettle();
      expect(find.byType(ProjectListingCard), findsOneWidget);
      await tester.tap(find.byTooltip('Filter projects'));
      await tester.pumpAndSettle();
      expect(find.text('Done'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('load more and pull-to-refresh use server pages', (tester) async {
    api.totalPages = 2;
    await mount(tester, const Size(430, 932));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Load more projects'));
    await tester.pumpAndSettle();
    expect(api.requests.last.page, 2);
    expect(controller.remoteProjects.length, 2);
    final scroll = tester.state<ScrollableState>(find.byType(Scrollable).first);
    scroll.position.jumpTo(0);
    await tester.pump();
    final before = api.requests.length;
    await tester.drag(find.byType(CustomScrollView), const Offset(0, 400));
    await tester.pumpAndSettle();
    expect(api.requests.length, greaterThan(before));
    expect(api.requests.last.page, 1);
    expect(controller.remoteProjects.length, 1);
  });

  testWidgets('pushed Projects uses the existing adaptive back control', (
    tester,
  ) async {
    await mount(tester, const Size(390, 844), platform: TargetPlatform.iOS);
    Get.to(() => const ProjectsView(isTab: false));
    await tester.pumpAndSettle();
    expect(find.byType(AppBackButton), findsOneWidget);
    await tester.tap(find.byType(AppBackButton));
    await tester.pumpAndSettle();
    expect(find.byType(AppBackButton), findsNothing);
  });
}
