import 'package:get/get.dart';

import '../models/project_model.dart';
import '../services/demo_repository.dart';

class ProjectController extends GetxController {
  final DemoRepository _repo;

  ProjectController(this._repo);

  final RxString selectedFilter =
      'All Projects'.obs; // 'All Projects', 'Active', 'Completed'
  final RxString searchQuery = ''.obs;
  final Rxn<ProjectModel> selectedProject = Rxn<ProjectModel>();

  List<ProjectModel> get filteredProjects {
    return _repo.projects.where((p) {
      final matchesFilter =
          selectedFilter.value == 'All Projects' ||
          p.status.toLowerCase() == selectedFilter.value.toLowerCase();
      final matchesSearch =
          searchQuery.value.isEmpty ||
          p.name.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          p.category.toLowerCase().contains(searchQuery.value.toLowerCase());
      return matchesFilter && matchesSearch;
    }).toList();
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  void selectProject(ProjectModel project) {
    selectedProject.value = project;
  }
}
