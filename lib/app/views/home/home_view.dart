import 'package:remixicon/remixicon.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/home_controller.dart';
import '../../controllers/navigation_controller.dart';
import '../../controllers/project_controller.dart';
import '../../controllers/subscription_controller.dart';
import '../../routes/app_routes.dart';
import '../../services/demo_repository.dart';
import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/app_system_ui.dart';
import '../../widgets/animated_notification_bell.dart';
import '../../widgets/explore_project_card.dart';
import '../../widgets/kyc_verified_badge.dart';
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
                      bottom: 16,
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
                                          color: Colors.white.withValues(
                                            alpha: 0.15,
                                          ),
                                          border: Border.all(
                                            color: AppColors.accent,
                                            width: 2,
                                          ),
                                        ),
                                        child: ClipOval(
                                          child:
                                              user.avatarUrl != null &&
                                                  user.avatarUrl!.isNotEmpty
                                              ? Image.network(
                                                  user.avatarUrl!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) => const Icon(
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Obx(() {
                                          final name = homeCtrl.user.fullName;
                                          final isVerified = homeCtrl.user.isKycVerified;
                                          return Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Flexible(
                                                child: Text(
                                                  'Hello, ${name.isNotEmpty ? name : 'Investor'}',
                                                  style: GoogleFonts.poppins(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (isVerified)
                                                const KycVerifiedBadge(
                                                  size: 16,
                                                  padding: EdgeInsets.only(left: 4.0),
                                                ),
                                            ],
                                          );
                                        }),
                                        const SizedBox(height: 2),
                                        Text(
                                          'welcomeToApp'.tr,
                                          style: GoogleFonts.poppins(
                                            color: Colors.white.withValues(
                                              alpha: 0.85,
                                            ),
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
                            // Notification Bell with dynamic animated chime & badge
                            Obx(() {
                              final count = homeCtrl.unreadNotificationCount;
                              return AnimatedNotificationBell(
                                hasNotification: count > 0,
                                unreadCount: count,
                                onTap: () =>
                                    Get.toNamed(AppRoutes.notifications),
                                color: Colors.white,
                                size: 22,
                                badgeColor: AppColors.error,
                                badgeBorderColor: const Color(0xFF0D4734),
                                backgroundColor: Colors.white.withValues(
                                  alpha: 0.15,
                                ),
                                containerSize: 42,
                              );
                            }),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // 2. Portfolio Summary Card
                        Obx(() {
                          final growth = homeCtrl.growthPercent;
                          return PortfolioSummaryCard(
                            totalValue: homeCtrl.totalPortfolioValue,
                            growth: growth != null
                                ? '+${growth.toStringAsFixed(1)}%'
                                : null,
                            activeProjectsCount: homeCtrl.totalActiveProjects,
                            isHideBalance: homeCtrl.isHideBalance.value,
                            onToggleVisibility:
                                homeCtrl.toggleBalanceVisibility,
                          );
                        }),
                      ],
                    ),
                  ),

                  // 3. Main Dashboard Body
                  Padding(
                    padding: ResponsiveHelper.pagePadding(context)
                        .copyWith(top: 0, bottom: 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),

                        Obx(() {
                          if (homeCtrl.user.id.isNotEmpty ||
                              homeCtrl.syncError.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Unable to load your account data. Please retry.',
                                ),
                                TextButton(
                                  onPressed: homeCtrl.refreshDashboard,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          );
                        }),
                        // 4 Responsive Metric Cards (2x2 on phone, 4x1 on tablet)
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final isTablet = constraints.maxWidth >= 600;
                            final cols = isTablet ? 4 : 2;

                            return Obx(() {
                              final cards = [
                                DashboardMetricCard(
                                  icon: Remix.coins_line,
                                  iconColor: AppColors.primary,
                                  iconBg: isDark
                                      ? AppColors.primary.withValues(alpha: 0.2)
                                      : AppColors.lightMint,
                                  title: 'totalInvested'.tr,
                                  value: CurrencyFormatter.format(
                                    homeCtrl.totalInvested,
                                  ),
                                  isDark: isDark,
                                ),
                                DashboardMetricCard(
                                  icon: Remix.funds_line,
                                  iconColor: AppColors.success,
                                  iconBg: isDark
                                      ? AppColors.success.withValues(alpha: 0.2)
                                      : AppColors.successLight,
                                  title: 'totalReturns'.tr,
                                  value: CurrencyFormatter.format(
                                    homeCtrl.totalReturns,
                                  ),
                                  isDark: isDark,
                                ),
                                DashboardMetricCard(
                                  icon: Remix.folder_3_line,
                                  iconColor: const Color(0xFF2563EB),
                                  iconBg: isDark
                                      ? const Color(0xFF2563EB)
                                            .withValues(alpha: 0.2)
                                      : AppColors.infoLight,
                                  title: 'totalProjects'.tr,
                                  value: '${homeCtrl.totalProjects}',
                                  isDark: isDark,
                                ),
                                DashboardMetricCard(
                                  icon: Remix.checkbox_circle_line,
                                  iconColor: const Color(0xFF0D9488),
                                  iconBg: isDark
                                      ? const Color(0xFF0D9488)
                                            .withValues(alpha: 0.2)
                                      : const Color(0xFFF0FDFA),
                                  title: 'Active Projects',
                                  value: '${homeCtrl.totalActiveProjects}',
                                  isDark: isDark,
                                ),
                              ];

                              final width =
                                  (constraints.maxWidth - 12 * (cols - 1)) /
                                  cols;
                              return Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: cards
                                    .map(
                                      (card) =>
                                          SizedBox(width: width, child: card),
                                    )
                                    .toList(),
                              );
                            });
                          },
                        ),
                        const SizedBox(height: 16),

                        // Subscription Membership Status Banner
                        if (Get.isRegistered<SubscriptionController>())
                          _HomeSubscriptionBanner(isDark: isDark),

                        const SizedBox(height: 6),

                        // Explore Projects Section Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.primary.withValues(
                                              alpha: 0.2,
                                            )
                                          : AppColors.lightMint,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Remix.compass_3_line,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Explore Projects',
                                          style: GoogleFonts.poppins(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w700,
                                            color: isDark
                                                ? AppColors.textPrimaryDark
                                                : AppColors.textPrimary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Discover high-potential investment opportunities',
                                          style: GoogleFonts.poppins(
                                            fontSize: 12,
                                            color: isDark
                                                ? AppColors.textSecondaryDark
                                                : AppColors.textSecondary,
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
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () {
                                if (navCtrl != null) {
                                  navCtrl.changeTab(1);
                                } else {
                                  Get.toNamed(AppRoutes.projects);
                                }
                              },
                              behavior: HitTestBehavior.opaque,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 4,
                                  horizontal: 4,
                                ),
                                child: Text(
                                  'viewAll'.tr,
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Explore Projects Content
                        Obx(() {
                          final projects = homeCtrl.featuredProjects;
                          if (projects.isEmpty) {
                            return _buildNoExploreProjectsEmptyState(isDark);
                          }

                          final displayProjects = projects.take(3).toList();
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              final availableWidth = constraints.maxWidth;
                              final double cardWidth;
                              if (displayProjects.length == 1 || availableWidth < 360) {
                                cardWidth = availableWidth.clamp(0.0, 400.0);
                              } else if (availableWidth >= 1000) {
                                cardWidth = ((availableWidth - 32) / 3).clamp(0.0, 400.0);
                              } else if (availableWidth >= 600) {
                                cardWidth = (availableWidth - 16) / 2.15;
                              } else {
                                cardWidth = availableWidth * 0.9;
                              }
                              return SingleChildScrollView(
                                key: const ValueKey('explore-projects-slider'),
                                scrollDirection: Axis.horizontal,
                                primary: false,
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (var i = 0; i < displayProjects.length; i++) ...[
                                      if (i > 0) const SizedBox(width: 16),
                                      SizedBox(
                                        width: cardWidth,
                                        child: ExploreProjectCard(
                                          project: displayProjects[i],
                                          onTap: () {
                                            final project = displayProjects[i];
                                            projCtrl?.loadDetails(project.id);
                                            Get.toNamed(
                                              AppRoutes.projectDetails,
                                              arguments: project.id,
                                            );
                                          },
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
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
                            padding: EdgeInsets.zero,
                            primary: false,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: activities.length,
                            separatorBuilder: (context, index) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final item = activities[index];
                              return RecentActivityItem(
                                transaction: item,
                                onTap: () =>
                                    Get.toNamed(AppRoutes.transactions),
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

  static Widget _buildNoExploreProjectsEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE5EFEA),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : AppColors.lightMint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Remix.compass_discover_line,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'No projects available',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Check back soon for new high-potential investment opportunities.',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
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
              color: AppColors.textSecondary.withValues(
                alpha: isDark ? 0.2 : 0.1,
              ),
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
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _HomeSubscriptionBanner extends StatelessWidget {
  final bool isDark;
  const _HomeSubscriptionBanner({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final subCtrl = Get.find<SubscriptionController>();
    return Obx(() {
      final hasActive = subCtrl.hasActivePlan;
      final planName = subCtrl.currentPlanName;
      final isExpiring = subCtrl.isExpiringSoon;
      final remaining = subCtrl.remainingDays;

      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDarkElevated : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasActive
                ? (isExpiring ? const Color(0xFFF59E0B) : AppColors.primary.withValues(alpha: 0.3))
                : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: hasActive
                    ? (isExpiring ? AppColors.badgeAmberBg : AppColors.lightMint)
                    : const Color(0xFFF3F4F6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Remix.vip_crown_line,
                size: 19,
                color: hasActive
                    ? (isExpiring ? const Color(0xFFB45309) : AppColors.primary)
                    : AppColors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          hasActive ? '$planName Membership' : 'Subscription Plans',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasActive) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isExpiring ? AppColors.badgeAmberBg : AppColors.badgeGreenBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isExpiring ? '${remaining}d left' : 'Active',
                            style: GoogleFonts.poppins(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: isExpiring ? AppColors.badgeAmberText : AppColors.badgeGreenText,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hasActive
                        ? 'Explore tier investments & benefits'
                        : 'Unlock exclusive investment opportunities',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () => Get.toNamed(AppRoutes.subscriptionPlans),
              child: Text(
                hasActive ? 'Manage' : 'Explore',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w700, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    });
  }
}
