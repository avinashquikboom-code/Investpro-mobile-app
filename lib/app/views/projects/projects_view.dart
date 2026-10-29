import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/investment_controller.dart';
import '../../controllers/project_controller.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/project_card.dart';

class ProjectsView extends StatelessWidget {
  final bool isTab;

  const ProjectsView({super.key, this.isTab = true});

  @override
  Widget build(BuildContext context) {
    final projCtrl = Get.find<ProjectController>();
    final invCtrl = Get.find<InvestmentController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: CustomAppBar(title: 'projects'.tr, showBackButton: !isTab),
      body: SafeArea(
        child: ResponsiveHelper.responsiveContainer(
          context: context,
          maxWidth: 600,
          child: Column(
            children: [
              // Filter Tabs (All Projects, Active, Completed)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Obx(() {
                  final filters = ['All Projects', 'Active', 'Completed'];
                  return SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: filters.map((filter) {
                        final isSelected =
                            projCtrl.selectedFilter.value == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => projCtrl.setFilter(filter),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryDark
                                    : (isDark
                                          ? AppColors.surfaceDark
                                          : Colors.white),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryDark
                                      : (isDark
                                            ? AppColors.borderDark
                                            : AppColors.border),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                filter,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textPrimary),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }),
              ),

              // Category Filter Chips
              Obx(() {
                final cats = projCtrl.availableCategories;
                if (cats.length <= 1) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: cats.map((cat) {
                        final isSelected =
                            projCtrl.selectedCategory.value == cat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: () => projCtrl.setCategory(cat),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryLight
                                    : (isDark
                                          ? AppColors.surfaceDark
                                          : Colors.white),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryDark
                                      : (isDark
                                            ? AppColors.borderDark
                                            : AppColors.border),
                                ),
                              ),
                              child: Text(
                                cat,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.primaryDark
                                      : (isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondary),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              }),

              // Projects List
              Expanded(
                child: Obx(() {
                  final list = projCtrl.filteredProjects;
                  if (list.isEmpty) {
                    return EmptyStateWidget(
                      icon: Icons.folder_open_rounded,
                      title: 'No Projects Found',
                      message: 'There are no projects matching this category right now.',
                      buttonText: 'Show All Projects',
                      onButtonPressed: () => projCtrl.setFilter('All Projects'),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final project = list[index];
                      return ProjectCard(
                        project: project,
                        isDashboardVariant: false,
                        onTap: () {
                          projCtrl.selectProject(project);
                          invCtrl.setProject(project);
                          Get.toNamed(AppRoutes.projectDetails);
                        },
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
