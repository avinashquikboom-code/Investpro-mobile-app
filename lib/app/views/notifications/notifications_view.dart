import 'package:remixicon/remixicon.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/notification_controller.dart';
import '../../models/notification_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/date_formatter.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/custom_app_bar.dart';

class NotificationsView extends StatelessWidget {
  const NotificationsView({super.key});

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.investorWelcome:
        return Remix.gift_line;
      case NotificationType.investmentSuccess:
        return Remix.briefcase_line;
      case NotificationType.returnReceived:
        return Remix.arrow_up_line;
      case NotificationType.withdrawalApproved:
        return Remix.checkbox_circle_line;
      case NotificationType.projectUpdate:
        return Remix.history_line;
      case NotificationType.newProject:
        return Remix.rocket_line;
      case NotificationType.requestUpdate:
      case NotificationType.kyc:
        return Remix.shield_line;
      case NotificationType.subscriptionActivated:
        return Remix.vip_crown_line;
      case NotificationType.subscriptionExpiring:
        return Remix.time_line;
      case NotificationType.subscriptionExpired:
        return Remix.error_warning_line;
    }
  }

  Color _getIconBgColor(NotificationType type) {
    switch (type) {
      case NotificationType.investmentSuccess:
      case NotificationType.returnReceived:
      case NotificationType.subscriptionActivated:
        return AppColors.badgeGreenBg;
      case NotificationType.withdrawalApproved:
        return AppColors.badgeBlueBg;
      case NotificationType.projectUpdate:
        return const Color(0xFFF3E8FF);
      case NotificationType.newProject:
      case NotificationType.subscriptionExpiring:
        return AppColors.badgeAmberBg;
      case NotificationType.subscriptionExpired:
        return AppColors.badgeRedBg;
      case NotificationType.investorWelcome:
      case NotificationType.requestUpdate:
      case NotificationType.kyc:
        return AppColors.badgeGreenBg;
    }
  }

  Color _getIconColor(NotificationType type) {
    switch (type) {
      case NotificationType.investmentSuccess:
      case NotificationType.returnReceived:
      case NotificationType.subscriptionActivated:
        return AppColors.primary;
      case NotificationType.withdrawalApproved:
        return AppColors.badgeBlueText;
      case NotificationType.projectUpdate:
        return const Color(0xFF9333EA);
      case NotificationType.newProject:
      case NotificationType.subscriptionExpiring:
        return AppColors.badgeAmberText;
      case NotificationType.subscriptionExpired:
        return AppColors.badgeRedText;
      case NotificationType.investorWelcome:
      case NotificationType.requestUpdate:
      case NotificationType.kyc:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifCtrl = Get.find<NotificationController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: CustomAppBar(
        title: 'notifications'.tr,
        actions: [
          TextButton(
            onPressed: notifCtrl.markAllAsRead,
            child: Text(
              'markAllAsRead'.tr,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveHelper.responsiveContainer(
          context: context,
          maxWidth: 600,
          child: Obx(() {
            final list = notifCtrl.notifications;
            if (list.isEmpty) {
              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: notifCtrl.refreshNotifications,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(height: 120),
                    Center(child: Text('No notifications yet')),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: notifCtrl.refreshNotifications,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                itemCount: list.length + (notifCtrl.hasMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == list.length) {
                    return TextButton(
                      onPressed: notifCtrl.loadingMore ? null : notifCtrl.loadMore,
                      child: Text(notifCtrl.loadingMore ? 'Loading…' : notifCtrl.paginationError.isNotEmpty ? notifCtrl.paginationError : 'Load older notifications'),
                    );
                  }
                  final notif = list[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isDark ? AppColors.borderDark : AppColors.border,
                          width: 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        onTap: () => notifCtrl.handleNotificationTap(notif),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
                        leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _getIconBgColor(notif.type),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _getNotificationIcon(notif.type),
                          color: _getIconColor(notif.type),
                          size: 22,
                        ),
                      ),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notif.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: notif.isRead
                                    ? FontWeight.w500
                                    : FontWeight.w700,
                                color: isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (!notif.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 3),
                          Text(
                            notif.description,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary,
                            ),
                          ),
                          if (notif.relatedId != null) Text('Related ID: ${notif.relatedId}', style: Theme.of(context).textTheme.bodySmall),
                          const SizedBox(height: 4),
                          Text(
                            DateFormatter.formatDateTime(notif.timestamp),
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : const Color(0xFF9AA8A1),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              ),
            );
          }),
        ),
      ),
    );
  }
}
