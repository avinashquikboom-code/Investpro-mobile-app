import 'package:remixicon/remixicon.dart';
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
import '../subscriptions/subscription_plans_sheet.dart';

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
      if (mounted && !Get.find<ProjectController>().isLoading.value && !Get.find<ProjectController>().hasAttempted) {
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

  Widget _statusChips(ProjectController projects) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Row(
      children: projects.statusFilters
          .map(
            (id) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(id),
                selected: projects.selectedFilter.value == id,
                onSelected: (_) => projects.setFilter(id),
                showCheckmark: false,
                selectedColor: AppColors.primaryDark,
                backgroundColor: AppColors.surface,
                side: BorderSide(
                  color: projects.selectedFilter.value == id
                      ? AppColors.primaryDark
                      : AppColors.border,
                ),
                labelStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: projects.selectedFilter.value == id
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
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Discover investment opportunities',
                            style: Theme.of(context).textTheme.bodyLarge
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _search,
                            onChanged: projects.setSearchQuery,
                            textInputAction: TextInputAction.search,
                            onSubmitted: (_) =>
                                projects.refreshProjects(),
                            decoration: InputDecoration(
                              hintText: 'Search projects by name or location...',
                              prefixIcon: const Icon(
                                Remix.search_line,
                                color: AppColors.textSecondary,
                              ),
                              suffixIcon: Obx(
                                () => projects.searchQuery.value.isEmpty
                                    ? const SizedBox.shrink()
                                    : IconButton(
                                        tooltip: 'Clear search',
                                        icon: const Icon(
                                          Remix.close_line,
                                        ),
                                        onPressed: () {
                                          _search.clear();
                                          projects.setSearchQuery('');
                                        },
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Obx(
                      () => _statusChips(projects),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 12)),
                  SliverToBoxAdapter(
                    child: Obx(() {
                      final elig = projects.eligibility.value;
                      if (elig == null || !elig.hasActiveSubscription) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.lightMint,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Remix.shield_check_line,
                                color: AppColors.primary,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Active Plan: ${elig.planName ?? "Member"} (${elig.formattedRange})',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primaryDark,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () =>
                                    SubscriptionPlansSheet.show(context),
                                child: const Text(
                                  'Upgrade',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                  Obx(() {
                    if (projects.isLoading.value && projects.filteredProjects.isEmpty) {
                      return const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (projects.errorMessage.value.isNotEmpty && projects.filteredProjects.isEmpty) {
                      return SliverFillRemaining(
                        hasScrollBody: false,
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Remix.cloud_off_line,
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
                    if (projects.subscriptionRequired.value && list.isEmpty) {
                      return SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 24,
                          ),
                          child: Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: AppColors.border,
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 16,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: const BoxDecoration(
                                    color: AppColors.lightMint,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Remix.vip_crown_line,
                                    color: AppColors.primary,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(height: 18),
                                Text(
                                  'Subscription Plan Required',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Subscribe to an investment membership tier to unlock curated investment opportunities tailored to your preferred investment range.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(
                                        color: AppColors.textSecondary,
                                        height: 1.5,
                                      ),
                                ),
                                const SizedBox(height: 20),
                                SizedBox(
                                  width: double.infinity,
                                  height: 46,
                                  child: ElevatedButton.icon(
                                    onPressed: () =>
                                        SubscriptionPlansSheet.show(context),
                                    icon: const Icon(
                                      Remix.vip_crown_fill,
                                      size: 18,
                                    ),
                                    label: const Text(
                                      'Purchase Plan to Invest',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      elevation: 0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    if (list.isEmpty) {
                      return SliverToBoxAdapter(
                        child: EmptyStateWidget(
                          icon: Remix.folder_open_line,
                          title: 'No Projects Found',
                          message:
                              'No matching projects are currently visible to investors. Only published, active opportunities are available from the current catalog.',
                          buttonText: 'Show All Projects',
                          onButtonPressed: () {
                            _search.clear();
                            projects.setSearchQuery('');
                            projects.setFilter('All Projects');
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
