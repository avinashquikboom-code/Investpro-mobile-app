import '../../widgets/app_system_ui.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/home_controller.dart';
import '../../controllers/investment_controller.dart';
import '../../controllers/navigation_controller.dart';
import '../../controllers/project_controller.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/project_card.dart';
import '../../widgets/summary_card.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final homeCtrl = Get.find<HomeController>();
    final projCtrl = Get.find<ProjectController>();
    final navCtrl = Get.find<NavigationController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppSystemUi(statusSurface: AppColors.primaryDark, child: Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: homeCtrl.refreshDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Green Curved Header
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    top: MediaQuery.of(context).padding.top + 16,
                    left: 20,
                    right: 20,
                    bottom: 24,
                  ),
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(28),
                    ),
                  ),
                  child: Column(
                    children: [
                      // User Greeting & Notification Bell
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withValues(alpha: 0.15),
                                    border: Border.all(
                                      color: AppColors.accent,
                                      width: 2,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    color: Colors.white,
                                    size: 26,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Obx(() {
                                        return Text(
                                          'Hello, ${homeCtrl.user.fullName}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        );
                                      }),
                                      const SizedBox(height: 2),
                                      Text(
                                        'welcomeToApp'.tr,
                                        style: TextStyle(
                                          color: Colors.white.withValues(
                                            alpha: 0.8,
                                          ),
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Notification Bell with Badge
                          GestureDetector(
                            onTap: () => Get.toNamed(AppRoutes.notifications),
                            child: Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  const Icon(
                                    Icons.notifications_outlined,
                                    color: Colors.white,
                                    size: 22,
                                  ),
                                  Obx(() {
                                    final count =
                                        homeCtrl.unreadNotificationCount;
                                    if (count <= 0) {
                                      return const SizedBox.shrink();
                                    }
                                    return Positioned(
                                      top: 8,
                                      right: 8,
                                      child: Container(
                                        width: 8,
                                        height: 8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.error,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Portfolio Summary Card inside header
                      Obx(() {
                        return PortfolioSummaryCard(
                          totalValue: homeCtrl.totalPortfolioValue,
                          growth:
                              '+${homeCtrl.growthPercent.toStringAsFixed(1)}%',
                          activeProjectsCount: homeCtrl.totalActiveProjects,
                        );
                      }),
                    ],
                  ),
                ),

                // Main Content Body
                Padding(
                  padding: ResponsiveHelper.pagePadding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 12),

                      // 3 Stat Cards in a row
                      Obx(() {
                        return Row(
                          children: [
                            Expanded(
                              child: StatItemCard(
                                title: 'totalInvested'.tr,
                                value: CurrencyFormatter.format(
                                  homeCtrl.totalInvested,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: StatItemCard(
                                title: 'totalReturns'.tr,
                                value: CurrencyFormatter.format(
                                  homeCtrl.totalReturns,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: StatItemCard(
                                title: 'totalProjects'.tr,
                                value: '${homeCtrl.totalActiveProjects}',
                              ),
                            ),
                          ],
                        );
                      }),
                      const SizedBox(height: 24),

                      // My Projects Section Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'myProjects'.tr,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                            ),
                          ),
                          GestureDetector(
                            onTap: () =>
                                navCtrl.changeTab(1), // Go to Projects Tab
                            child: Text(
                              'viewAll'.tr,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // Featured Projects List
                      Obx(() {
                        final list = homeCtrl.featuredProjects;
                        if (list.isEmpty) {
                          return const Center(
                            child: Text('No projects available'),
                          );
                        }
                        return LayoutBuilder(
                          builder: (context, constraints) {
                            final cols = ResponsiveHelper.gridColumns(
                              constraints.maxWidth,
                              phone: 1,
                              tablet: 2,
                              largeTablet: 3,
                            );

                            if (cols > 1) {
                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: cols,
                                  crossAxisSpacing: 14,
                                  mainAxisSpacing: 12,
                                  mainAxisExtent: 96,
                                ),
                                itemCount: list.length,
                                itemBuilder: (context, index) {
                                  final project = list[index];
                                  return ProjectCard(
                                    project: project,
                                    isDashboardVariant: true,
                                    onTap: () {
                                      projCtrl.selectProject(project);
                                      final invCtrl =
                                          Get.find<InvestmentController>();
                                      invCtrl.setProject(project);
                                      Get.toNamed(AppRoutes.projectDetails);
                                    },
                                  );
                                },
                              );
                            }

                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: list.length,
                              itemBuilder: (context, index) {
                                final project = list[index];
                                return ProjectCard(
                                  project: project,
                                  isDashboardVariant: true,
                                  onTap: () {
                                    projCtrl.selectProject(project);
                                    final invCtrl =
                                        Get.find<InvestmentController>();
                                    invCtrl.setProject(project);
                                    Get.toNamed(AppRoutes.projectDetails);
                                  },
                                );
                              },
                            );
                          },
                        );
                      }),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}
