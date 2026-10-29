import '../bank/bank_account_view.dart';
import '../kyc/kyc_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/navigation_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/custom_app_bar.dart';

class ProfileView extends StatelessWidget {
  final bool isTab;

  const ProfileView({super.key, this.isTab = true});

  void _showBankDetailsDialog(
    BuildContext context,
    ProfileController controller,
  ) {
    final user = controller.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.defaultDialog(
      title: 'bankDetails'.tr,
      titleStyle: const TextStyle(fontWeight: FontWeight.bold),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceDarkElevated
                    : const Color(0xFFF3F8F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _buildBankRow('Bank Name', user.bankName),
                  const Divider(height: 16),
                  _buildBankRow('Account Number', user.accountNumber),
                  const Divider(height: 16),
                  _buildBankRow('IFSC Code', user.ifscCode),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Status',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.verified_rounded,
                              size: 16,
                              color: AppColors.success,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                user.isBankVerified ? 'Verified' : 'Unverified',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.success,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      textConfirm: 'Done',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.primary,
      onConfirm: () => Get.back(),
    );
  }

  static Widget _buildBankRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  void _showHelpSupportDialog(BuildContext context) {
    Get.defaultDialog(
      title: 'helpSupport'.tr,
      titleStyle: const TextStyle(fontWeight: FontWeight.bold),
      content: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          children: [
            ListTile(
              dense: true,
              leading: Icon(Icons.email_outlined, color: AppColors.primary),
              title: Text('Email Support'),
              subtitle: Text('support@investpro.app'),
            ),
            ListTile(
              dense: true,
              leading: Icon(Icons.phone_outlined, color: AppColors.primary),
              title: Text('Toll Free Support'),
              subtitle: Text('+91 1800-482-900'),
            ),
            ListTile(
              dense: true,
              leading: Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.primary,
              ),
              title: Text('Live Concierge'),
              subtitle: Text('Available Mon–Sat (9 AM – 7 PM)'),
            ),
          ],
        ),
      ),
      textConfirm: 'Close',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.primary,
      onConfirm: () => Get.back(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileCtrl = Get.find<ProfileController>();
    final authCtrl = Get.find<AuthController>();
    final navCtrl = Get.find<NavigationController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: CustomAppBar(title: 'profile'.tr, showBackButton: !isTab),
      body: SafeArea(
        child: ResponsiveHelper.responsiveContainer(
          context: context,
          maxWidth: 600,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            child: Column(
              children: [
                // User Avatar & Name Header
                Center(
                  child: Column(
                    children: [
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: AppColors.primaryDark,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.accent, width: 3),
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 44,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Obx(() {
                        return Text(
                          profileCtrl.user.fullName,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                          ),
                        );
                      }),
                      const SizedBox(height: 3),
                      Obx(() {
                        return Text(
                          'Investor ID: ${profileCtrl.user.id}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 26),

                ListTile(leading: const Icon(Icons.verified_user_outlined), title: const Text('KYC Documents'), onTap: () => Get.to(() => const KycView())),
                ListTile(leading: const Icon(Icons.add_card), title: const Text('Add Bank Account'), onTap: () => Get.to(() => const BankAccountView())),
                // Menu Items Container
                Container(
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
                      _buildMenuItem(
                        context: context,
                        icon: Icons.person_outline_rounded,
                        label: 'personalInformation'.tr,
                        onTap: () {
                          profileCtrl.populateFields();
                          Get.toNamed(AppRoutes.editProfile);
                        },
                      ),
                      _buildDivider(isDark),
                      _buildMenuItem(
                        context: context,
                        icon: Icons.account_balance_outlined,
                        label: 'bankDetails'.tr,
                        onTap: () =>
                            _showBankDetailsDialog(context, profileCtrl),
                      ),
                      _buildDivider(isDark),
                      _buildMenuItem(
                        context: context,
                        icon: Icons.history_rounded,
                        label: 'investmentHistory'.tr,
                        onTap: () {
                          if (isTab) {
                            navCtrl.goToInvestments();
                          } else {
                            Get.toNamed(AppRoutes.myInvestments);
                          }
                        },
                      ),
                      _buildDivider(isDark),
                      _buildMenuItem(
                        context: context,
                        icon: Icons.account_balance_wallet_outlined,
                        label: 'withdrawalHistory'.tr,
                        onTap: () => Get.toNamed(AppRoutes.withdrawals),
                      ),
                      _buildDivider(isDark),
                      _buildMenuItem(
                        context: context,
                        icon: Icons.settings_outlined,
                        label: 'settings'.tr,
                        onTap: () => Get.toNamed(AppRoutes.settings),
                      ),
                      _buildDivider(isDark),
                      _buildMenuItem(
                        context: context,
                        icon: Icons.help_outline_rounded,
                        label: 'helpSupport'.tr,
                        onTap: () => _showHelpSupportDialog(context),
                      ),
                      _buildDivider(isDark),
                      _buildMenuItem(
                        context: context,
                        icon: Icons.logout_rounded,
                        label: 'logout'.tr,
                        iconColor: AppColors.error,
                        textColor: AppColors.error,
                        showChevron: false,
                        onTap: authCtrl.logout,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
    bool showChevron = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      onTap: onTap,
      dense: true,
      leading: Icon(icon, color: iconColor ?? AppColors.primary, size: 22),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color:
              textColor ??
              (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
        ),
      ),
      trailing: showChevron
          ? Icon(
              Icons.chevron_right_rounded,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
              size: 20,
            )
          : null,
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
