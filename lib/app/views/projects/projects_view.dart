import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/investment_controller.dart';
import '../../controllers/project_controller.dart';
import '../../models/project_model.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../widgets/app_app_bar.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/project_listing_card.dart';

class ProjectsView extends StatefulWidget {
  final bool isTab;
  const ProjectsView({super.key, this.isTab = true});
  @override
  State<ProjectsView> createState() => _ProjectsViewState();
}

class _ProjectsViewState extends State<ProjectsView> {
  final _search = TextEditingController();
  bool _openingInvestment = false;

  @override
  void initState() {
    super.initState();
    _search.text = Get.find<ProjectController>().searchQuery.value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !Get.find<ProjectController>().isLoading.value) {
        Get.find<ProjectController>().refreshProjects();
      }
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool get _authenticated =>
      Get.isRegistered<AuthController>() &&
      Get.find<AuthController>().isLoggedIn.value;

  Future<void> _invest(ProjectModel project) async {
    if (_openingInvestment) return;
    final projects = Get.find<ProjectController>();
    final investments = Get.find<InvestmentController>();
    if (investments.isProcessingPayment.value ||
        projects.investmentUnavailableReason(
              project,
              authenticated: _authenticated,
            ) !=
            null) {
      return;
    }
    setState(() => _openingInvestment = true);
    try {
      // Revalidate visibility using the actual selected ID before entering the existing flow.
      await projects.loadDetails(project.id);
      if (!mounted) return;
      final current = projects.selectedProject.value;
      final reason = current == null
          ? projects.detailError.value
          : projects.investmentUnavailableReason(
              current,
              authenticated: _authenticated,
            );
      if (current == null || reason != null) {
        Get.snackbar(
          'Unable to invest',
          reason ?? 'This project is unavailable',
        );
        return;
      }
      if (investments.isProcessingPayment.value) return;
      investments.setProject(current);
      Get.toNamed(AppRoutes.investNow, arguments: current.id);
    } finally {
      if (mounted) setState(() => _openingInvestment = false);
    }
  }

  Widget _chips(
    List<String> ids,
    String selected,
    String Function(String) label,
    void Function(String) onSelected,
  ) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(
      children: ids
          .map(
            (id) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(label(id)),
                selected: selected == id,
                onSelected: (_) => onSelected(id),
                showCheckmark: false,
                selectedColor: AppColors.primaryDark,
                backgroundColor: AppColors.surface,
                side: BorderSide(
                  color: selected == id
                      ? AppColors.primaryDark
                      : AppColors.border,
                ),
                labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: selected == id
                      ? Theme.of(context).colorScheme.onPrimary
                      : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          )
          .toList(),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final projects = Get.find<ProjectController>();
    final investments = Get.find<InvestmentController>();
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppAppBar(
        title: 'projects'.tr,
        showBackButton: widget.isTab ? false : null,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: RefreshIndicator(
              onRefresh: projects.refreshProjects,
              child: CustomScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Discover investment opportunities',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _search,
                                  onChanged: projects.setSearchQuery,
                                  textInputAction: TextInputAction.search,
                                  onSubmitted: (_) =>
                                      projects.refreshProjects(),
                                  decoration: InputDecoration(
                                    hintText: 'Search projects by name or location...',
                                    prefixIcon: const Icon(
                                      Icons.search_rounded,
                                      color: AppColors.textSecondary,
                                    ),
                                    suffixIcon: Obx(
                                      () => projects.searchQuery.value.isEmpty
                                          ? const SizedBox.shrink()
                                          : IconButton(
                                              tooltip: 'Clear search',
                                              icon: const Icon(
                                                Icons.close_rounded,
                                              ),
                                              onPressed: () {
                                                _search.clear();
                                                projects.setSearchQuery('');
                                              },
                                            ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton.outlined(
                                tooltip: 'Filter projects',
                                icon: const Icon(
                                  Icons.tune_rounded,
                                  color: AppColors.primary,
                                ),
                                onPressed: () {
                                  FocusManager.instance.primaryFocus?.unfocus();
                                  showModalBottomSheet<void>(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (_) => SafeArea(
                                      child: SingleChildScrollView(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 24,
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Filter projects',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge,
                                            ),
                                            const SizedBox(height: 16),
                                            Obx(
                                              () => _chips(
                                                projects.statusFilters,
                                                projects.selectedFilter.value,
                                                (id) => id,
                                                projects.setFilter,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Obx(
                                              () => _chips(
                                                projects.availableCategories,
                                                projects.selectedCategory.value,
                                                projects.categoryLabel,
                                                projects.setCategory,
                                              ),
                                            ),
                                            const SizedBox(height: 16),
                                            TextButton(
                                              onPressed: () => Get.back(),
                                              child: const Text('Done'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Obx(
                      () => _chips(
                        projects.statusFilters,
                        projects.selectedFilter.value,
                        (id) => id,
                        projects.setFilter,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 6)),
                  SliverToBoxAdapter(
                    child: Obx(
                      () => _chips(
                        projects.availableCategories,
                        projects.selectedCategory.value,
                        projects.categoryLabel,
                        projects.setCategory,
                      ),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 16)),
                  Obx(() {
                    if (projects.isLoading.value) {
                      return const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (projects.errorMessage.value.isNotEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.cloud_off_rounded,
                                color: AppColors.textSecondary,
                                size: 36,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                projects.errorMessage.value,
                                textAlign: TextAlign.center,
                              ),
                              TextButton(
                                onPressed: projects.refreshProjects,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    final list = projects.filteredProjects;
                    if (list.isEmpty) {
                      return SliverToBoxAdapter(
                        child: EmptyStateWidget(
                          icon: Icons.folder_open_rounded,
                          title: 'No Projects Found',
                          message: 'No matching projects are currently visible to investors. Only published, active opportunities are available from the current catalog.',
                          buttonText: 'Show All Projects',
                          onButtonPressed: () {
                            _search.clear();
                            projects.setSearchQuery('');
                            projects.setFilter('All Projects');
                            projects.setCategory('All Categories');
                          },
                        ),
                      );
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverList.builder(
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final project = list[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Obx(() {
                              final reason = projects
                                  .investmentUnavailableReason(
                                    project,
                                    authenticated: _authenticated,
                                  );
                              final busy =
                                  _openingInvestment ||
                                  investments.isProcessingPayment.value;
                              return ProjectListingCard(
                                key: ValueKey(project.id),
                                project: project,
                                onDetails: () {
                                  projects.selectProject(project);
                                  // The details route loads this ID from the backend again.
                                  Get.toNamed(
                                    AppRoutes.projectDetails,
                                    arguments: project.id,
                                  );
                                },
                                onInvest: reason == null && !busy
                                    ? () => _invest(project)
                                    : null,
                                investmentHint: reason,
                              );
                            }),
                          );
                        },
                      ),
                    );
                  }),
                  SliverToBoxAdapter(
                    child: Obx(
                      () => Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        child: Column(
                          children: [
                            if (projects.pageError.value.isNotEmpty)
                              Text(
                                projects.pageError.value,
                                textAlign: TextAlign.center,
                              ),
                            if (projects.isLoadingMore.value)
                              const CircularProgressIndicator()
                            else if (projects.hasMore.value)
                              OutlinedButton(
                                onPressed: projects.loadMore,
                                child: Text(
                                  projects.pageError.value.isEmpty
                                      ? 'Load more projects'
                                      : 'Retry loading more',
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
