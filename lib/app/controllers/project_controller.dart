import 'package:get/get.dart';
import '../models/project_model.dart';
import '../services/demo_repository.dart';
import '../services/api_service.dart';

class ProjectController extends GetxController {
  final DemoRepository _repo;
  final ApiService? _api;
  ProjectController(this._repo, [this._api]);
  final selectedFilter = 'All Projects'.obs;
  final selectedCategory = 'All Categories'.obs;
  final searchQuery = ''.obs;
  final selectedProject = Rxn<ProjectModel>();
  final categories = <Map<String, dynamic>>[].obs;
  final remoteProjects = <ProjectModel>[].obs;
  final isLoading = false.obs;
  final isDetailLoading = false.obs;
  final errorMessage = ''.obs;
  final detailError = ''.obs;
  int _request = 0;
  @override
  void onInit() { super.onInit(); if (_api != null) refreshProjects(); }
  List<String> get availableCategories => ['All Categories', ...categories.map((c) => c['id'] as String)];
  String categoryLabel(String id) {
    if (id == 'All Categories') return id;
    final category = categories.firstWhereOrNull((c) => c['id'] == id);
    return category == null ? '' : '${category['name']} (${category['projectsCount'] ?? 0})';
  }
  List<ProjectModel> get filteredProjects => (_api == null ? _repo.projects : remoteProjects).where((p) {
    final status = selectedFilter.value == 'All Projects' || p.status.toLowerCase() == selectedFilter.value.toLowerCase();
    final category = selectedCategory.value == 'All Categories' || p.categoryId == selectedCategory.value;
    final search = searchQuery.value.isEmpty || p.name.toLowerCase().contains(searchQuery.value.toLowerCase()) || p.category.toLowerCase().contains(searchQuery.value.toLowerCase());
    return status && category && search;
  }).toList();
  Future<void> refreshProjects() async {
    if (_api == null) return;
    final request = ++_request;
    isLoading.value = true;
    errorMessage.value = '';
    remoteProjects.clear();
    try {
      final catalog = await _api.getProjectCategories();
      if (request != _request || isClosed) return;
      categories.assignAll(catalog.where((c) => c['isActive'] == true));
      if (selectedCategory.value != 'All Categories' && !categories.any((c) => c['id'] == selectedCategory.value)) selectedCategory.value = 'All Categories';
      final projects = await _api.getEligibleProjects(projectTypeId: selectedCategory.value == 'All Categories' ? null : selectedCategory.value, search: searchQuery.value);
      if (request != _request || isClosed) return;
      remoteProjects.assignAll(projects.map(ProjectModel.fromBackend));
    } catch (_) {
      if (request == _request && !isClosed) errorMessage.value = 'Unable to load projects and categories. Please retry.';
    } finally { if (request == _request && !isClosed) isLoading.value = false; }
  }
  void setFilter(String filter) { selectedFilter.value = filter; }
  void setCategory(String id) { selectedCategory.value = id; refreshProjects(); }
  void setSearchQuery(String query) { searchQuery.value = query; }
  void selectProject(ProjectModel project) { selectedProject.value = project; detailError.value = ''; }
  Future<void> loadDetails(String id) async {
    if (_api == null) return;
    isDetailLoading.value = true;
    detailError.value = '';
    selectedProject.value = null;
    try {
      final data = await _api.getProject(id);
      if (data == null) throw Exception('Unavailable');
      selectedProject.value = ProjectModel.fromBackend(data);
    } catch (_) { detailError.value = 'This project is unavailable or could not be loaded.'; }
    finally { if (!isClosed) isDetailLoading.value = false; }
  }
}
