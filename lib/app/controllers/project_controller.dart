import 'package:get/get.dart';

import '../models/project_model.dart';
import '../services/demo_repository.dart';

class ProjectController extends GetxController {
  final DemoRepository _repo;

  ProjectController(this._repo);

  final RxString selectedFilter =
      'All Projects'.obs; // 'All Projects', 'Active', 'Completed'
  final RxString selectedCategory = 'All Categories'.obs;
  final RxString searchQuery = ''.obs;
  final Rxn<ProjectModel> selectedProject = Rxn<ProjectModel>();

  List<String> get availableCategories {
    final set = <String>{'All Categories'};
    for (final p in _repo.projects) {
      if (p.category.isNotEmpty) set.add(p.category);
    }
    return set.toList();
  }

  List<ProjectModel> get filteredProjects {
    return _repo.projects.where((p) {
      final matchesFilter =
          selectedFilter.value == 'All Projects' ||
          p.status.toLowerCase() == selectedFilter.value.toLowerCase();
      final matchesCategory =
          selectedCategory.value == 'All Categories' ||
          p.category.toLowerCase() == selectedCategory.value.toLowerCase();
      final matchesSearch =
          searchQuery.value.isEmpty ||
          p.name.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          p.category.toLowerCase().contains(searchQuery.value.toLowerCase());
      return matchesFilter && matchesCategory && matchesSearch;
    }).toList();
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
  }

  void setCategory(String category) {
    selectedCategory.value = category;
  }

  void setSearchQuery(String query) {
    searchQuery.value = query;
  }

  void selectProject(ProjectModel project) {
    selectedProject.value = project;
  }
}
