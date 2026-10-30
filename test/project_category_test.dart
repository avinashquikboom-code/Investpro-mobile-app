import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:investpro/app/controllers/investment_controller.dart';
import 'package:investpro/app/views/projects/projects_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investpro/app/controllers/project_controller.dart';
import 'package:investpro/app/models/project_model.dart';
import 'package:investpro/app/services/api_service.dart';
import 'package:investpro/app/services/demo_repository.dart';
import 'package:investpro/app/services/local_storage_service.dart';
import 'package:investpro/app/services/notification_service.dart';

class CategoryApi extends ApiService {
  bool fail = false;
  String? requestedId;
  List<Map<String, dynamic>> catalog = [
    {
      'id': 'type-1',
      'name': 'Backend category',
      'isActive': true,
      'projectsCount': 0,
    },
  ];
  List<Map<String, dynamic>> records = [];
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
    requestedId = projectTypeId;
    return ProjectPage(records, page: page, totalPages: 1);
  }

  @override
  Future<Map<String, dynamic>?> getProject(String id) async => null;
}

ProjectController controller(CategoryApi api) {
  final storage = LocalStorageService();
  return ProjectController(
    DemoRepository(storage, NotificationService(storage)),
    api,
  );
}

void main() {
  tearDown(() => Get.reset());
  for (final size in [
    const Size(320, 568),
    const Size(844, 390),
    const Size(1024, 1366),
  ]) {
    testWidgets('category chips are removed and status tabs are displayed at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = CategoryApi();
      final storage = LocalStorageService();
      final repo = DemoRepository(storage, NotificationService(storage));
      Get.put(ProjectController(repo, api));
      Get.put(InvestmentController(repo));
      await tester.pumpWidget(const GetMaterialApp(home: ProjectsView()));
      await tester.pumpAndSettle();
      expect(find.text('Backend category (0)'), findsNothing);
      expect(find.text('All Categories'), findsNothing);
      expect(find.text('All Projects'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('Completed'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  test('catalog categories do not depend on current project records', () async {
    final api = CategoryApi();
    final c = controller(api);
    await c.refreshProjects();
    expect(c.availableCategories, ['All Categories', 'type-1']);
    expect(c.categoryLabel('type-1'), 'Backend category (0)');
    expect(c.filteredProjects, isEmpty);
    c.onClose();
  });
  test('category selection sends ID, rename preserves selected ID, deactivation clears it', () async {
    final api = CategoryApi();
    final c = controller(api);
    c.selectedCategory.value = 'type-1';
    await c.refreshProjects();
    expect(api.requestedId, 'type-1');
    api.catalog[0]['name'] = 'Renamed category';
    await c.refreshProjects();
    expect(c.selectedCategory.value, 'type-1');
    expect(c.categoryLabel('type-1'), contains('Renamed category'));
    api.catalog[0]['isActive'] = false;
    await c.refreshProjects();
    expect(c.selectedCategory.value, 'All Categories');
    expect(api.requestedId, isNull);
    c.onClose();
  });
  test('network errors retain valid cached results and expose retry state', () async {
    final api = CategoryApi()
      ..records = [
        {
          'id': 'p1',
          'title': 'Real project',
          'status': 'ACTIVE',
          'projectType': {'id': 'type-1', 'name': 'Backend category'},
        },
      ];
    final c = controller(api);
    await c.refreshProjects();
    expect(c.filteredProjects.single.id, 'p1');
    api.fail = true;
    await c.refreshProjects();
    expect(c.errorMessage.value, isNotEmpty);
    expect(c.filteredProjects.single.id, 'p1');
    expect(c.isLoading.value, false);
    c.onClose();
  });
  test(
    'ineligible detail response cannot retain a previously selected record',
    () async {
      final c = controller(CategoryApi());
      c.selectProject(
        ProjectModel.fromBackend({
          'id': 'old',
          'title': 'Old',
          'status': 'ACTIVE',
        }),
      );
      await c.loadDetails('hidden');
      expect(c.selectedProject.value, isNull);
      expect(c.detailError.value, isNotEmpty);
      c.onClose();
    },
  );
  test(
    'decimal server values and stable category ID survive serialization',
    () {
      final model = ProjectModel.fromBackend({
        'id': 'p1',
        'title': 'Project',
        'status': 'ACTIVE',
        'projectTypeId': 'type-1',
        'projectType': {'id': 'type-1', 'name': 'Renamed'},
        'targetAmount': '123456.78',
        'expectedRoi': '12.50',
      });
      expect(model.targetAmount, 123456.78);
      expect(model.returnRatePercent, 12.5);
      expect(ProjectModel.fromJson(model.toJson()).categoryId, 'type-1');
    },
  );
}
