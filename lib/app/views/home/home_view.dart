import 'package:remixicon/remixicon.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/home_controller.dart';
import '../../controllers/navigation_controller.dart';
import '../../controllers/project_controller.dart';
import '../../routes/app_routes.dart';
import '../../services/demo_repository.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/app_system_ui.dart';
import '../../widgets/project_card.dart';
import '../../widgets/recent_activity_item.dart';
import '../../widgets/summary_card.dart';

class HomeView extends StatelessWidget {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final homeCtrl = Get.isRegistered<HomeController>()
        ? Get.find<HomeController>()
        : Get.put(
            HomeController(
              Get.find<DemoRepository>(),
              Get.find<NotificationService>(),
            ),
          );
    final navCtrl = Get.isRegistered<NavigationController>()
        ? Get.find<NavigationController>()
        : null;
    final projCtrl = Get.isRegistered<ProjectController>()
        ? Get.find<ProjectController>()
        : null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppSystemUi(
      statusSurface: AppColors.primaryDark,
      child: Scaffold(
        backgroundColor: isDark
            ? AppColors.backgroundDark
            : AppColors.background,
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
                  // 1. Curved Green Header with User Avatar, Greeting, and Notification Bell
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
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Top Greeting Row
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  // Investor Avatar (taps to Profile)
                                  GestureDetector(
                                    onTap: () {
                                      if (navCtrl != null) {
                                        navCtrl.changeTab(4);
                                      } else {
                                        Get.toNamed(AppRoutes.profile);
                                      }
                                    },
                                    child: Obx(() {
                                      final user = homeCtrl.user;
                                      return Container(
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
                                        child: ClipOval(
                                          child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                                              ? Image.network(
                                                  user.avatarUrl!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (context, error, stackTrace) => const Icon(
                                                    Remix.user_3_line,
                                                    color: Colors.white,
                                                    size: 26,
                                                  ),
                                                )
                                              : const Icon(
                                                  Remix.user_3_line,
                                                  color: Colors.white,
                                                  size: 26,
                                                ),
                                        ),
                                      );
                                    }),
                                  ),
                                  const SizedBox(width: 12),
                                  // Greeting text
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Obx(() {
                                          final name = homeCtrl.user.fullName;
                                          return Text(
                                            'Hello, ${name.isNotEmpty ? name : 'Investor'}',
                                            style: GoogleFonts.poppins(
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
                                          style: GoogleFonts.poppins(
                                            color: Colors.white.withValues(alpha: 0.85),
                                            fontSize: 12,
                                            fontWeight: FontWeight.w400,
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
                            // Notification Bell with dynamic badge
                            GestureDetector(
                              onTap: () => Get.toNamed(AppRoutes.notifications),
                              behavior: HitTestBehavior.opaque,
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
                                      Remix.notification_line,
                                      color: Colors.white,
                                      size: 22,
                                    ),
                                    Obx(() {
                                      final count = homeCtrl.unreadNotificationCount;
                                      if (count <= 0) return const SizedBox.shrink();
                                      return Positioned(
                                        top: 9,
                                        right: 9,
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

                        // 2. Portfolio Summary Card
                        Obx(() {
                          final growth = homeCtrl.growthPercent;
                          return PortfolioSummaryCard(
                            totalValue: homeCtrl.totalPortfolioValue,
                            growth: growth != null ? '+${growth.toStringAsFixed(1)}%' : null,
                            activeProjectsCount: homeCtrl.totalActiveProjects,
                            isHideBalance: homeCtrl.isHideBalance.value,
                            onToggleVisibility: homeCtrl.toggleBalanceVisibility,
                          );
                        }),
                      ],
                    ),
                  ),

                  // 3. Main Dashboard Body
                  Padding(
                    padding: ResponsiveHelper.pagePadding(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 16),

                        // 4 Responsive Metric Cards (2x2 on phone, 4x1 on tablet)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isTablet = constraints.maxWidth >= 600;
                            final cols = isTablet ? 4 : 2;

                            return Obx(() {
                              final cards = [
                                DashboardMetricCard(
                                  icon: Remix.stock_line,
                                  iconColor: AppColors.primary,
                                  iconBg: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
                                  title: 'totalInvested'.tr,
                                  value: CurrencyFormatter.format(homeCtrl.totalInvested),
                                  isDark: isDark,
                                ),
                                DashboardMetricCard(
                                  icon: Remix.secure_payment_line,
                                  iconColor: AppColors.success,
                                  iconBg: AppColors.success.withValues(alpha: isDark ? 0.2 : 0.1),
                                  title: 'totalReturns'.tr,
                                  value: CurrencyFormatter.format(homeCtrl.totalReturns),
                                  isDark: isDark,
                                ),
                                DashboardMetricCard(
                                  icon: Remix.folder_line,
                                  iconColor: AppColors.info,
                                  iconBg: AppColors.info.withValues(alpha: isDark ? 0.2 : 0.1),
                                  title: 'totalProjects'.tr,
                                  value: '${homeCtrl.totalProjects}',
                                  isDark: isDark,
                                ),
                                DashboardMetricCard(
                                  icon: Remix.checkbox_circle_line,
                                  iconColor: AppColors.accent,
                                  iconBg: AppColors.accent.withValues(alpha: isDark ? 0.2 : 0.1),
                                  title: 'Active Projects',
                                  value: '${homeCtrl.totalActiveProjects}',
                                  isDark: isDark,
                                ),
                              ];

                              return GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: cols,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  mainAxisExtent: 114,
                                ),
                                itemCount: cards.length,
                                itemBuilder: (context, index) => cards[index],
                              );
                            });
                          },
                        ),
                        const SizedBox(height: 28),

                        // 4. My Projects Section Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'myProjects'.tr,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary,
                              ),
                            ),
                            GestureDetector(
                              onTap: () {
                                if (navCtrl != null) {
                                  navCtrl.goToInvestments();
                                } else {
                                  Get.toNamed(AppRoutes.myInvestments);
                                }
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Text(
                                'viewAll'.tr,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // My Projects Content (Only Authenticated Investor-Owned Projects)
                        Obx(() {
                          final investments = homeCtrl.myInvestments;
                          if (investments.isEmpty) {
                            return _buildNoInvestmentsEmptyState(context, navCtrl, isDark);
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: investments.length > 3 ? 3 : investments.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final inv = investments[index];
                              return MyProjectCard(
                                investment: inv,
                                onTap: () {
                                  if (projCtrl != null) {
                                    projCtrl.loadDetails(inv.projectId);
                                  }
                                  Get.toNamed(
                                    AppRoutes.projectDetails,
                                    arguments: inv.projectId,
                                  );
                                },
                              );
                            },
                          );
                        }),
                        const SizedBox(height: 28),

                        // 5. Recent Activity Section Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Recent Activity',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => Get.toNamed(AppRoutes.transactions),
                              behavior: HitTestBehavior.opaque,
                              child: Text(
                                'viewAll'.tr,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Recent Activity Content
                        Obx(() {
                          final activities = homeCtrl.recentActivity;
                          if (activities.isEmpty) {
                            return _buildNoActivityEmptyState(isDark);
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: activities.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = activities[index];
                              return RecentActivityItem(
                                transaction: item,
                                onTap: () => Get.toNamed(AppRoutes.transactions),
                              );
                            },
                          );
                        }),
                        const SizedBox(height: 32),
                      ],
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

  static Widget _buildNoInvestmentsEmptyState(
    BuildContext context,
    NavigationController? navCtrl,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Remix.folder_open_line,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No investments yet',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Explore available investment opportunities to get started.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              if (navCtrl != null) {
                navCtrl.changeTab(1); // Projects Tab
              } else {
                Get.toNamed(AppRoutes.projects);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Explore Projects',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildNoActivityEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: isDark ? 0.2 : 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Remix.receipt_line,
              color: AppColors.textSecondary,
              size: 28,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No recent activity',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your latest investments and returns will appear here.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
