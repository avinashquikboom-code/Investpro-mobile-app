import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/custom_app_bar.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  void _showLanguageDialog(
    BuildContext context,
    SettingsController controller,
  ) {
    Get.defaultDialog(
      title: 'language'.tr,
      titleStyle: const TextStyle(fontWeight: FontWeight.bold),
      content: Column(
        children: [
          _buildLanguageOption(controller, 'en_US', 'English'),
          _buildLanguageOption(controller, 'hi_IN', 'हिन्दी (Hindi)'),
          _buildLanguageOption(controller, 'mr_IN', 'मराठी (Marathi)'),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(
    SettingsController controller,
    String code,
    String name,
  ) {
    return Obx(() {
      final isSelected = controller.selectedLanguage.value == code;
      return ListTile(
        title: Text(name),
        trailing: isSelected
            ? const Icon(Icons.check_rounded, color: AppColors.primary)
            : null,
        onTap: () {
          controller.setLanguage(code);
          Get.back();
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final settingsCtrl = Get.find<SettingsController>();
    final authCtrl = Get.find<AuthController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: CustomAppBar(title: 'settings'.tr),
      body: SafeArea(
        child: ResponsiveHelper.responsiveContainer(
          context: context,
          maxWidth: 600,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  // Profile Settings
                  ListTile(
                    leading: const Icon(
                      Icons.person_outline_rounded,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      'profileSettings'.tr,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSecondary,
                    ),
                    onTap: () => Get.toNamed(AppRoutes.editProfile),
                  ),
                  _buildDivider(isDark),

                  // Language
                  Obx(() {
                    return ListTile(
                      leading: const Icon(
                        Icons.language_rounded,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        'language'.tr,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            settingsCtrl.getLanguageName(
                              settingsCtrl.selectedLanguage.value,
                            ),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.chevron_right_rounded,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                      onTap: () => _showLanguageDialog(context, settingsCtrl),
                    );
                  }),
                  _buildDivider(isDark),

                  // Notifications Toggle
                  Obx(() {
                    return SwitchListTile(
                      secondary: const Icon(
                        Icons.notifications_none_rounded,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        'notifications'.tr,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                        ),
                      ),
                      activeThumbColor: AppColors.primary,
                      value: settingsCtrl.notificationsEnabled.value,
                      onChanged: settingsCtrl.toggleNotifications,
                    );
                  }),
                  _buildDivider(isDark),

                  // Biometric Login Toggle
                  Obx(() {
                    return SwitchListTile(
                      secondary: const Icon(
                        Icons.fingerprint_rounded,
                        color: AppColors.primary,
                      ),
                      title: Text(
                        'biometricLogin'.tr,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                        ),
                      ),
                      activeThumbColor: AppColors.primary,
                      value: settingsCtrl.biometricsEnabled.value,
                      subtitle: const Text(
                        'Unavailable • device authentication is not configured',
                      ),
                      onChanged: null,
                    );
                  }),
                  _buildDivider(isDark),

                  // Change Password
                  ListTile(
                    leading: const Icon(
                      Icons.vpn_key_outlined,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      'changePassword'.tr,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                      ),
                    ),
                    trailing: const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSecondary,
                    ),
                    onTap: settingsCtrl.showChangePasswordDialog,
                  ),
                  _buildDivider(isDark),

                  // App Version
                  ListTile(
                    leading: const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primary,
                    ),
                    title: Text(
                      'appVersion'.tr,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                      ),
                    ),
                    trailing: const Text(
                      '1.0.0',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  _buildDivider(isDark),

                  // Logout
                  ListTile(
                    leading: const Icon(
                      Icons.logout_rounded,
                      color: AppColors.error,
                    ),
                    title: Text(
                      'logout'.tr,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.error,
                      ),
                    ),
                    onTap: authCtrl.logout,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? AppColors.borderDark : AppColors.divider,
      indent: 52,
    );
  }
}
