import 'package:remixicon/remixicon.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../routes/app_routes.dart';
import '../../services/demo_repository.dart';
import '../../theme/app_colors.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/custom_app_bar.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  void _showLanguageBottomSheet(
    BuildContext context,
    SettingsController controller,
    bool isDark,
  ) {
    final languages = [
      {'code': 'en_US', 'name': 'English', 'native': 'English', 'flag': '🇺🇸'},
      {'code': 'hi_IN', 'name': 'Hindi', 'native': 'हिन्दी', 'flag': '🇮🇳'},
      {'code': 'mr_IN', 'name': 'Marathi', 'native': 'मराठी', 'flag': '🇮🇳'},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.borderDark : const Color(0xFFD4E0D9),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Select App Language',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Choose your preferred language for the InvestPro interface.',
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              ...languages.map((lang) {
                return Obx(() {
                  final isSelected = controller.selectedLanguage.value == lang['code'];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.08)
                          : (isDark ? AppColors.surfaceDarkElevated : const Color(0xFFF7FAF8)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.borderDark : AppColors.border),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        leading: Text(
                          lang['flag']!,
                          style: const TextStyle(fontSize: 24),
                        ),
                        title: Text(
                          lang['name']!,
                          style: GoogleFonts.poppins(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          lang['native']!,
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(Remix.checkbox_circle_line, color: AppColors.primary, size: 22)
                            : null,
                        onTap: () {
                          controller.setLanguage(lang['code']!);
                          Navigator.of(context).pop();
                        },
                      ),
                    ),
                  );
                });
              }),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showLegalDialog(BuildContext context, String title, String content, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.borderDark : const Color(0xFFD4E0D9),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Remix.close_line),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                content,
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('I Understand', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showLogoutConfirmation(BuildContext context, AuthController authCtrl, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Remix.logout_box_r_line, color: AppColors.error, size: 28),
              ),
              const SizedBox(height: 16),
              Text(
                'Log Out of InvestPro?',
                style: GoogleFonts.poppins(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You will need to sign in again to access your portfolio and execute withdrawals.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Cancel', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        authCtrl.logout();
                      },
                      child: Text(
                        'Log Out',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsCtrl = Get.find<SettingsController>();
    final authCtrl = Get.find<AuthController>();
    final repo = Get.find<DemoRepository>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: CustomAppBar(title: 'settings'.tr, showBackButton: true),
      body: SafeArea(
        child: ResponsiveHelper.responsiveContainer(
          context: context,
          maxWidth: 600,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Investor Profile Header Card
                Obx(() {
                  final user = repo.currentUser.value;
                  return _buildUserCard(user, isDark);
                }),
                const SizedBox(height: 20),

                // 2. Account & Identity
                _buildSectionHeader('Account & Verification', isDark),
                const SizedBox(height: 8),
                _buildCardGroup(
                  isDark: isDark,
                  children: [
                    _buildSettingsTile(
                      icon: Remix.user_3_line,
                      title: 'Personal Information',
                      subtitle: 'Name, email, contact & residential address',
                      isDark: isDark,
                      onTap: () => Get.toNamed(AppRoutes.editProfile),
                    ),
                    _buildDivider(isDark),
                    _buildSettingsTile(
                      icon: Remix.shield_line,
                      title: 'KYC Documents',
                      subtitle: 'Government ID verification for investments',
                      trailing: Obx(() {
                        final isKycVerified = repo.currentUser.value.isKycVerified == true;
                        return _buildBadge(
                          isKycVerified ? 'Verified' : 'Pending',
                          isKycVerified ? AppColors.success : AppColors.warning,
                        );
                      }),
                      isDark: isDark,
                      onTap: () => Get.toNamed(AppRoutes.kyc),
                    ),
                    _buildDivider(isDark),
                    _buildSettingsTile(
                      icon: Remix.bank_line,
                      title: 'Bank Accounts',
                      subtitle: 'Manage linked accounts for returns & withdrawals',
                      trailing: Obx(() {
                        final isBank = repo.currentUser.value.isBankVerified == true;
                        return _buildBadge(
                          isBank ? 'Linked' : 'Not Linked',
                          isBank ? AppColors.success : AppColors.textSecondary,
                        );
                      }),
                      isDark: isDark,
                      onTap: () => Get.toNamed(AppRoutes.bankDetails),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 3. Security & Credentials
                _buildSectionHeader('Security & Credentials', isDark),
                const SizedBox(height: 8),
                _buildCardGroup(
                  isDark: isDark,
                  children: [
                    _buildSettingsTile(
                      icon: Remix.key_2_line,
                      title: 'changePassword'.tr,
                      subtitle: 'Update your account login password',
                      isDark: isDark,
                      onTap: settingsCtrl.showChangePasswordDialog,
                    ),
                    _buildDivider(isDark),
                    Obx(() {
                      return SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        secondary: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Remix.fingerprint_line, color: AppColors.primary, size: 20),
                        ),
                        title: Text(
                          'biometricLogin'.tr,
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'Unlock app quickly using Face ID or Fingerprint',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                          ),
                        ),
                        activeThumbColor: AppColors.primary,
                        value: settingsCtrl.biometricsEnabled.value,
                        onChanged: settingsCtrl.toggleBiometrics,
                      );
                    }),
                    _buildDivider(isDark),
                    _buildSettingsTile(
                      icon: Remix.shield_check_line,
                      title: 'Two-Factor Authentication',
                      subtitle: 'Mandatory OTP on logins and withdrawals',
                      trailing: _buildBadge('Active', AppColors.success),
                      isDark: isDark,
                      onTap: () {
                        Get.snackbar(
                          'Security Status',
                          'Two-factor OTP protection is actively enforced on all financial transactions.',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // 4. Preferences
                _buildSectionHeader('Preferences', isDark),
                const SizedBox(height: 8),
                _buildCardGroup(
                  isDark: isDark,
                  children: [
                    Obx(() {
                      final currentLang = settingsCtrl.selectedLanguage.value;
                      return _buildSettingsTile(
                        icon: Remix.translate_2,
                        title: 'language'.tr,
                        subtitle: 'Change interface display language',
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              settingsCtrl.getLanguageName(currentLang),
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Remix.arrow_right_s_line,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                              size: 18,
                            ),
                          ],
                        ),
                        isDark: isDark,
                        onTap: () => _showLanguageBottomSheet(context, settingsCtrl, isDark),
                      );
                    }),
                    _buildDivider(isDark),
                    Obx(() {
                      return SwitchListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                        secondary: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Remix.notification_line, color: AppColors.primary, size: 20),
                        ),
                        title: Text(
                          'notifications'.tr,
                          style: GoogleFonts.poppins(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'Project updates, return credits & security alerts',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                          ),
                        ),
                        activeThumbColor: AppColors.primary,
                        value: settingsCtrl.notificationsEnabled.value,
                        onChanged: settingsCtrl.toggleNotifications,
                      );
                    }),
                  ],
                ),
                const SizedBox(height: 20),

                // 5. Support & Legal
                _buildSectionHeader('Support & Legal', isDark),
                const SizedBox(height: 8),
                _buildCardGroup(
                  isDark: isDark,
                  children: [
                    _buildSettingsTile(
                      icon: Remix.question_line,
                      title: 'helpSupport'.tr,
                      subtitle: 'FAQs, concierge assistance & ticket status',
                      isDark: isDark,
                      onTap: () => Get.toNamed(AppRoutes.helpSupport),
                    ),
                    _buildDivider(isDark),
                    _buildSettingsTile(
                      icon: Remix.file_text_line,
                      title: 'Terms of Service',
                      subtitle: 'Investor terms, platform usage & agreements',
                      isDark: isDark,
                      onTap: () => _showLegalDialog(
                        context,
                        'Terms of Service',
                        'By using InvestPro, you agree to our investor agreement, dispute resolution policies, and platform terms of service. All investments carry risk, and investors should review project disclosures before investing.',
                        isDark,
                      ),
                    ),
                    _buildDivider(isDark),
                    _buildSettingsTile(
                      icon: Remix.shield_keyhole_line,
                      title: 'Privacy Policy',
                      subtitle: 'How we protect your financial & KYC data',
                      isDark: isDark,
                      onTap: () => _showLegalDialog(
                        context,
                        'Privacy Policy',
                        'InvestPro strictly complies with national financial data privacy standards. Your KYC records and bank accounts are encrypted in transit and at rest and are never sold to third parties.',
                        isDark,
                      ),
                    ),
                    _buildDivider(isDark),
                    _buildSettingsTile(
                      icon: Remix.information_line,
                      title: 'appVersion'.tr,
                      subtitle: 'Production release channel',
                      trailing: Text(
                        '1.0.0 (Build 42)',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        ),
                      ),
                      isDark: isDark,
                      onTap: () {
                        Get.snackbar(
                          'InvestPro System',
                          'Your app is running the latest production build 1.0.0.',
                          snackPosition: SnackPosition.BOTTOM,
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 6. Logout Button
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _showLogoutConfirmation(context, authCtrl, isDark),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Remix.logout_box_r_line, color: AppColors.error, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'logout'.tr,
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard(dynamic user, bool isDark) {
    final name = user?.fullName ?? 'Investor';
    final email = user?.email ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.primary.withValues(alpha: 0.12),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'I',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Remix.edit_line, size: 20, color: AppColors.primary),
            tooltip: 'Edit Profile',
            onPressed: () => Get.toNamed(AppRoutes.editProfile),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 12.5,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildCardGroup({required List<Widget> children, required bool isDark}) {
    return Material(
      color: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 11,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
        ),
      ),
      trailing: trailing ??
          Icon(
            Remix.arrow_right_s_line,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            size: 20,
          ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      thickness: 1,
      color: isDark ? AppColors.borderDark : AppColors.divider,
      indent: 68,
      endIndent: 16,
    );
  }
}
