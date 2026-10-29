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
  List<Map<String, dynamic>> catalog = [{'id': 'type-1', 'name': 'Backend category', 'isActive': true, 'projectsCount': 0}];
  List<Map<String, dynamic>> records = [];
  @override
  Future<List<Map<String, dynamic>>> getProjectCategories() async { if (fail) throw Exception('offline'); return catalog; }
  @override
  Future<List<Map<String, dynamic>>> getEligibleProjects({String? projectTypeId, String? search}) async { requestedId = projectTypeId; return records; }
  @override
  Future<Map<String, dynamic>?> getProject(String id) async => null;
}
ProjectController controller(CategoryApi api) {
  final storage = LocalStorageService();
  return ProjectController(DemoRepository(storage, NotificationService(storage)), api);
}
void main() {
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
  test('network errors clear stale results and expose retry state', () async {
    final api = CategoryApi()..records = [{'id': 'p1', 'title': 'Real project', 'status': 'ACTIVE', 'projectType': {'id': 'type-1', 'name': 'Backend category'}}];
    final c = controller(api);
    await c.refreshProjects();
    expect(c.filteredProjects.single.id, 'p1');
    api.fail = true;
    await c.refreshProjects();
    expect(c.errorMessage.value, isNotEmpty);
    expect(c.filteredProjects, isEmpty);
    expect(c.isLoading.value, false);
    c.onClose();
  });
  test('ineligible detail response cannot retain a previously selected record', () async {
    final c = controller(CategoryApi());
    c.selectProject(ProjectModel.fromBackend({'id': 'old', 'title': 'Old', 'status': 'ACTIVE'}));
    await c.loadDetails('hidden');
    expect(c.selectedProject.value, isNull);
    expect(c.detailError.value, isNotEmpty);
    c.onClose();
  });
  test('decimal server values and stable category ID survive serialization', () {
    final model = ProjectModel.fromBackend({'id': 'p1', 'title': 'Project', 'status': 'ACTIVE', 'projectTypeId': 'type-1', 'projectType': {'id': 'type-1', 'name': 'Renamed'}, 'targetAmount': '123456.78', 'expectedRoi': '12.50'});
    expect(model.targetAmount, 123456.78);
    expect(model.returnRatePercent, 12.5);
    expect(ProjectModel.fromJson(model.toJson()).categoryId, 'type-1');
  });
}
