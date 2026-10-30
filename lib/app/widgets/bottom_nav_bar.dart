import 'package:remixicon/remixicon.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controllers/navigation_controller.dart';
import '../theme/app_colors.dart';

class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({super.key});

  @override
  Widget build(BuildContext context) {
    final navCtrl = Get.find<NavigationController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Obx(() {
      return Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark ? AppColors.borderDark : AppColors.border,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              offset: const Offset(0, -3),
              blurRadius: 10,
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context: context,
                  index: 0,
                  icon: Remix.home_4_line,
                  activeIcon: Remix.home_4_fill,
                  label: 'homeTab'.tr,
                  isSelected: navCtrl.currentIndex.value == 0,
                  onTap: () => navCtrl.changeTab(0),
                ),
                _buildNavItem(
                  context: context,
                  index: 1,
                  icon: Remix.apps_line,
                  activeIcon: Remix.apps_fill,
                  label: 'projectsTab'.tr,
                  isSelected: navCtrl.currentIndex.value == 1,
                  onTap: () => navCtrl.changeTab(1),
                ),
                _buildNavItem(
                  context: context,
                  index: 2,
                  icon: Remix.wallet_3_line,
                  activeIcon: Remix.wallet_3_fill,
                  label: 'investmentsTab'.tr,
                  isSelected: navCtrl.currentIndex.value == 2,
                  onTap: () => navCtrl.changeTab(2),
                ),
                _buildNavItem(
                  context: context,
                  index: 3,
                  icon: Remix.exchange_line,
                  activeIcon: Remix.exchange_fill,
                  label: 'returnsTab'.tr,
                  isSelected: navCtrl.currentIndex.value == 3,
                  onTap: () => navCtrl.changeTab(3),
                ),
                _buildNavItem(
                  context: context,
                  index: 4,
                  icon: Remix.user_3_line,
                  activeIcon: Remix.user_3_fill,
                  label: 'profileTab'.tr,
                  isSelected: navCtrl.currentIndex.value == 4,
                  onTap: () => navCtrl.changeTab(4),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final activeColor = AppColors.primary;
    final inactiveColor = AppColors.textSecondary;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: Colors.transparent,
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: 24,
              color: isSelected ? activeColor : inactiveColor,
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? activeColor : inactiveColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
