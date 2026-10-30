import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/auth_controller.dart';
import '../../controllers/navigation_controller.dart';
import '../../controllers/profile_controller.dart';
import '../../routes/app_routes.dart';
import '../../services/demo_repository.dart';
import '../../services/local_storage_service.dart';
import '../../theme/app_colors.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/app_app_bar.dart';

class ProfileView extends StatelessWidget {
  final bool isTab;

  const ProfileView({super.key, this.isTab = true});

  void _copyToClipboard(BuildContext context, String text, String label) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'Copied to Clipboard',
      '$label: $text',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.primaryDark,
      colorText: Colors.white,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(16),
      borderRadius: 12,
      icon: const Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 20),
    );
  }

  void _showBankDetailsDialog(
    BuildContext context,
    ProfileController controller,
  ) {
    final user = controller.user;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.defaultDialog(
      title: 'bankDetails'.tr,
      titleStyle: GoogleFonts.poppins(
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
      ),
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
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                ),
              ),
              child: Column(
                children: [
                  _buildBankRow('Bank Name', user.bankName.isNotEmpty ? user.bankName : 'Not linked'),
                  const Divider(height: 16),
                  _buildBankRow('Account Number', user.accountNumber.isNotEmpty ? user.accountNumber : 'Not linked'),
                  const Divider(height: 16),
                  _buildBankRow('IFSC Code', user.ifscCode.isNotEmpty ? user.ifscCode : 'Not linked'),
                  const Divider(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Status',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Flexible(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              user.isBankVerified
                                  ? Icons.verified_rounded
                                  : Icons.info_outline_rounded,
                              size: 16,
                              color: user.isBankVerified
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                user.isBankVerified ? 'Verified' : 'Unverified',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: user.isBankVerified
                                      ? AppColors.success
                                      : AppColors.warning,
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
      textConfirm: 'Close',
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
            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.poppins(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  void _showHelpSupportDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Get.defaultDialog(
      title: 'helpSupport'.tr,
      titleStyle: GoogleFonts.poppins(
        fontWeight: FontWeight.w700,
        fontSize: 18,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
      ),
      content: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          children: [
            _buildSupportItem(
              icon: Icons.email_outlined,
              title: 'Email Support',
              subtitle: 'support@investpro.app',
              isDark: isDark,
            ),
            _buildSupportItem(
              icon: Icons.phone_outlined,
              title: 'Toll Free Support',
              subtitle: '+91 1800-482-900',
              isDark: isDark,
            ),
            _buildSupportItem(
              icon: Icons.chat_bubble_outline_rounded,
              title: 'Live Concierge',
              subtitle: 'Mon–Sat (9 AM – 7 PM)',
              isDark: isDark,
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

  static Widget _buildSupportItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: isDark ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileCtrl = Get.isRegistered<ProfileController>()
        ? Get.find<ProfileController>()
        : Get.put(ProfileController(Get.find<DemoRepository>()));
    final authCtrl = Get.isRegistered<AuthController>()
        ? Get.find<AuthController>()
        : Get.put(AuthController(
            Get.find<LocalStorageService>(),
            Get.find<DemoRepository>(),
          ));
    final navCtrl = Get.isRegistered<NavigationController>()
        ? Get.find<NavigationController>()
        : null;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.secondaryBackground,
      appBar: AppAppBar(
        title: 'profile'.tr,
        subtitle: 'Manage your account information',
        showBackButton: !isTab,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await profileCtrl.refreshProfile();
          },
          child: ResponsiveHelper.responsiveContainer(
            context: context,
            maxWidth: 600,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // 1. Profile Information Card
                  _buildProfileCard(context, profileCtrl, isDark),
                  const SizedBox(height: 16),

                  // 2. Quick Action Cards (KYC Documents & Add Bank Account)
                  _buildQuickActionCards(context, profileCtrl, isDark),
                  const SizedBox(height: 22),

                  // 3. Account Management Header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                    child: Text(
                      'Account Management',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 4. Account Management Menu Card
                  _buildAccountManagementCard(context, profileCtrl, navCtrl, authCtrl, isDark),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(
    BuildContext context,
    ProfileController profileCtrl,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Obx(() {
        final user = profileCtrl.user;
        final hasName = user.fullName.isNotEmpty;
        final displayName = hasName ? user.fullName : (user.email.isNotEmpty ? user.email.split('@')[0] : 'Investor');
        final rawId = user.id.isNotEmpty ? user.id : 'Pending';

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Circular Avatar with edit badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppColors.lightMint,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary,
                      width: 2,
                    ),
                  ),
                  child: ClipOval(
                    child: user.avatarUrl != null && user.avatarUrl!.isNotEmpty
                        ? Image.network(
                            user.avatarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => const Icon(
                              Icons.person_rounded,
                              size: 38,
                              color: AppColors.primary,
                            ),
                          )
                        : const Icon(
                            Icons.person_rounded,
                            size: 38,
                            color: AppColors.primary,
                          ),
                  ),
                ),
                Positioned(
                  bottom: -2,
                  right: -2,
                  child: InkWell(
                    onTap: () {
                      profileCtrl.populateFields();
                      Get.toNamed(AppRoutes.editProfile)?.then((_) => profileCtrl.refreshProfile());
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),

            // User Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),

                  // Investor ID with Copy Button
                  InkWell(
                    onTap: () => _copyToClipboard(context, rawId, 'Investor ID'),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDarkElevated : const Color(0xFFF3F8F5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.border.withValues(alpha: 0.6),
                          width: 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              'ID: $rawId',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.copy_rounded,
                            size: 12,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Status Badges (Account & KYC)
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      _buildStatusPill(
                        label: 'Account: ${_formatAccountStatus(user.accountStatus)}',
                        isSuccess: user.accountStatus.toUpperCase() == 'ACTIVE',
                        isDark: isDark,
                      ),
                      _buildStatusPill(
                        label: 'KYC: ${_formatKycStatus(user.kycStatus)}',
                        isSuccess: user.kycStatus.toUpperCase() == 'VERIFIED' || user.kycStatus.toUpperCase() == 'APPROVED',
                        isWarning: user.kycStatus.toUpperCase() == 'PENDING',
                        isDark: isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  static String _formatAccountStatus(String raw) {
    if (raw.isEmpty) return 'Active';
    final upper = raw.toUpperCase();
    if (upper == 'ACTIVE') return 'Active';
    if (upper == 'SUSPENDED') return 'Suspended';
    if (upper == 'DEACTIVATED') return 'Inactive';
    return raw;
  }

  static String _formatKycStatus(String raw) {
    if (raw.isEmpty) return 'Not Submitted';
    final upper = raw.toUpperCase();
    if (upper == 'VERIFIED' || upper == 'APPROVED') return 'Verified';
    if (upper == 'PENDING') return 'Pending';
    if (upper == 'REJECTED') return 'Rejected';
    if (upper == 'NOT_SUBMITTED') return 'Not Submitted';
    return raw;
  }

  Widget _buildStatusPill({
    required String label,
    required bool isDark,
    bool isSuccess = false,
    bool isWarning = false,
  }) {
    Color bg;
    Color text;

    if (isSuccess) {
      bg = AppColors.badgeGreenBg;
      text = AppColors.badgeGreenText;
    } else if (isWarning) {
      bg = AppColors.badgeAmberBg;
      text = AppColors.badgeAmberText;
    } else {
      bg = isDark ? AppColors.surfaceDarkElevated : const Color(0xFFF1F5F3);
      text = isDark ? AppColors.textSecondaryDark : AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(
          fontSize: 10.5,
          fontWeight: FontWeight.w600,
          color: text,
        ),
      ),
    );
  }

  Widget _buildQuickActionCards(
    BuildContext context,
    ProfileController profileCtrl,
    bool isDark,
  ) {
    return Row(
      children: [
        // Card 1: KYC Documents
        Expanded(
          child: _buildActionCard(
            context: context,
            icon: Icons.shield_outlined,
            iconColor: AppColors.primary,
            iconBg: AppColors.lightMint,
            title: 'KYC Documents',
            subtitle: 'Verify your identity',
            isDark: isDark,
            onTap: () {
              Get.toNamed(AppRoutes.kyc)?.then((_) => profileCtrl.refreshProfile());
            },
          ),
        ),
        const SizedBox(width: 12),

        // Card 2: Add Bank Account
        Expanded(
          child: _buildActionCard(
            context: context,
            icon: Icons.add_card_outlined,
            iconColor: AppColors.primary,
            iconBg: AppColors.lightMint,
            title: 'Bank Accounts',
            subtitle: 'Manage withdrawals',
            isDark: isDark,
            onTap: () {
              Get.toNamed(AppRoutes.bankDetails)?.then((_) => profileCtrl.refreshProfile());
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Material(
      color: isDark ? AppColors.surfaceDark : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.primary.withValues(alpha: 0.08),
        highlightColor: AppColors.primary.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
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
      ),
    );
  }

  Widget _buildAccountManagementCard(
    BuildContext context,
    ProfileController profileCtrl,
    NavigationController? navCtrl,
    AuthController authCtrl,
    bool isDark,
  ) {
    return Material(
      color: isDark ? AppColors.surfaceDark : Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // 1. Personal Information
          _buildMenuRow(
            icon: Icons.person_outline_rounded,
            title: 'personalInformation'.tr,
            subtitle: 'View and update your details',
            isDark: isDark,
            onTap: () {
              profileCtrl.populateFields();
              Get.toNamed(AppRoutes.editProfile)?.then((_) => profileCtrl.refreshProfile());
            },
          ),
          _buildDivider(isDark),

          // 2. Bank Details
          _buildMenuRow(
            icon: Icons.account_balance_outlined,
            title: 'bankDetails'.tr,
            subtitle: 'Manage your bank accounts',
            isDark: isDark,
            onTap: () => Get.toNamed(AppRoutes.bankDetails)?.then((_) => profileCtrl.refreshProfile()),
          ),
          _buildDivider(isDark),

          // 3. Investment History
          _buildMenuRow(
            icon: Icons.history_rounded,
            title: 'investmentHistory'.tr,
            subtitle: 'View your investments',
            isDark: isDark,
            onTap: () {
              if (isTab && navCtrl != null) {
                navCtrl.goToInvestments();
              } else {
                Get.toNamed(AppRoutes.myInvestments);
              }
            },
          ),
          _buildDivider(isDark),

          // 4. Withdrawal History
          _buildMenuRow(
            icon: Icons.account_balance_wallet_outlined,
            title: 'withdrawalHistory'.tr,
            subtitle: 'Track your withdrawal requests',
            isDark: isDark,
            onTap: () => Get.toNamed(AppRoutes.withdrawals),
          ),
          _buildDivider(isDark),

          // 5. Settings
          _buildMenuRow(
            icon: Icons.settings_outlined,
            title: 'settings'.tr,
            subtitle: 'App preferences and security',
            isDark: isDark,
            onTap: () => Get.toNamed(AppRoutes.settings),
          ),
          _buildDivider(isDark),

          // 6. Help & Support
          _buildMenuRow(
            icon: Icons.help_outline_rounded,
            title: 'helpSupport'.tr,
            subtitle: 'Get help and contact support',
            isDark: isDark,
            onTap: () => Get.toNamed(AppRoutes.helpSupport),
          ),
          _buildDivider(isDark),

          // 7. Logout
          _buildMenuRow(
            icon: Icons.logout_rounded,
            title: 'logout'.tr,
            subtitle: 'Sign out of your account',
            isDark: isDark,
            iconColor: AppColors.error,
            titleColor: AppColors.error,
            showChevron: false,
            onTap: authCtrl.logout,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
    bool showChevron = true,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primary).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(
          icon,
          color: iconColor ?? AppColors.primary,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 13.5,
          fontWeight: FontWeight.w600,
          color: titleColor ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.poppins(
          fontSize: 11,
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
        ),
      ),
      trailing: showChevron
          ? Icon(
              Icons.chevron_right_rounded,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
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
      indent: 68,
      endIndent: 16,
    );
  }
}
