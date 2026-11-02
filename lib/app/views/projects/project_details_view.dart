import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remixicon/remixicon.dart';

import '../../controllers/investment_controller.dart';
import '../../controllers/project_controller.dart';
import '../../routes/app_routes.dart';
import '../../services/investment_calculator.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/project_image.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/progress_indicator.dart';
import '../../widgets/record_id.dart';
import '../../widgets/status_badge.dart';

/// Screen 2 – Project Details
/// Renders project image/icon, status badge, live funding progress card with percentage,
/// centralized Investment Details card (Total, Monthly, Daily, Hourly returns),
/// risk information card, and Invest Now CTA.
class ProjectDetailsView extends StatefulWidget {
  const ProjectDetailsView({super.key});

  @override
  State<ProjectDetailsView> createState() => _ProjectDetailsViewState();
}

class _ProjectDetailsViewState extends State<ProjectDetailsView> {
  String? projectId;

  @override
  void initState() {
    super.initState();
    final controller = Get.find<ProjectController>();
    final argument = Get.arguments;
    projectId = argument is String
        ? argument
        : argument is Map && argument['projectId'] is String
            ? argument['projectId'] as String
            : controller.selectedProject.value?.id;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && projectId != null) controller.loadDetails(projectId!);
    });
  }

  IconData _getIcon(String iconType) {
    switch (iconType.toLowerCase()) {
      case 'code':
        return Remix.code_s_slash_line;
      case 'mobile':
        return Remix.smartphone_line;
      case 'gear':
      case 'ai':
        return Remix.settings_5_line;
      case 'real estate':
        return Remix.building_4_line;
      case 'energy':
        return Remix.sun_line;
      default:
        return Remix.briefcase_line;
    }
  }

  @override
  Widget build(BuildContext context) {
    final projCtrl = Get.find<ProjectController>();
    final invCtrl = Get.find<InvestmentController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: CustomAppBar(title: 'projectDetails'.tr),
      body: SafeArea(
        child: ResponsiveHelper.responsiveContainer(
          context: context,
          maxWidth: 640,
          child: Obx(() {
            if (projCtrl.isDetailLoading.value) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }
            if (projCtrl.detailError.value.isNotEmpty &&
                projCtrl.selectedProject.value == null) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Remix.error_warning_line,
                        size: 40,
                        color: AppColors.error,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        projCtrl.detailError.value,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: projectId == null
                            ? null
                            : () => projCtrl.loadDetails(projectId!),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final project = projCtrl.selectedProject.value;
            if (project == null) {
              return Center(
                child: Text(
                  'No project selected',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
                  ),
                ),
              );
            }

            final selectedAmount = invCtrl.investmentAmount.value;
            final selectedPrincipal = invCtrl.currentProject.value?.id == project.id &&
                    selectedAmount.isFinite && selectedAmount > 0
                ? selectedAmount
                : null;
            final calcBasis = selectedPrincipal;
            final backend = invCtrl.backendProjection.value;
            final calc = calcBasis == null
                ? null
                : selectedPrincipal != null && backend != null &&
                        backend.principal == calcBasis &&
                        backend.returnRatePercent == project.returnRatePercent &&
                        backend.durationMonths == project.durationMonths
                    ? backend
                    : InvestmentCalculator.calculate(
                        principal: calcBasis,
                        returnRatePercent: project.returnRatePercent,
                        durationMonths: project.durationMonths,
                      );
            final basisLabel = calcBasis == null
                ? 'Select an investment amount'
                : 'Selected amount: ${CurrencyFormatter.format(calcBasis)}';

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (project.category.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        project.category.toUpperCase(),
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: AppColors.primary,
                        ),
                      ),
                    ),

                  RecordId(label: 'Project ID', value: project.recordIds['id']),

                  // 0. Hero Project Image Banner
                  if (project.imageUrl != null && project.imageUrl!.trim().isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 180,
                        width: double.infinity,
                        child: ProjectImage(
                          project: project,
                          height: 180,
                          width: double.infinity,
                          placeholder: _buildIconPlaceholder(project.iconType),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // 1. Top Project Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.border,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.2 : 0.03,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: ProjectImage(
                              project: project,
                              width: 48,
                              height: 48,
                              placeholder: _buildIconPlaceholder(project.iconType),
                            ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                project.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimary,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(project.cityLabel, maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(fontSize: 12, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary)),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? AppColors.surfaceDarkElevated
                                          : const Color(0xFFE8F7EC),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${project.returnRatePercent.toStringAsFixed(2)}% / month',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '|  ${project.durationMonths} Mos',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        StatusBadge(status: project.status),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 2. Funding Progress Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.border,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.2 : 0.03,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'totalInvestmentRequired'.tr,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    CurrencyFormatter.format(
                                      project.targetAmount,
                                    ),
                                    style: GoogleFonts.poppins(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'alreadyRaised'.tr,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    CurrencyFormatter.format(
                                      project.raisedAmount,
                                    ),
                                    style: GoogleFonts.poppins(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Funding Progress Bar with Percentage
                        Row(
                          children: [
                            Expanded(
                              child: CustomProgressBar(
                                value: project.progressPercentage,
                                height: 8,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '${project.progressPercentage.toStringAsFixed(2)}% Funded',
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 3. Investment Details Card (Projected Return Total, Monthly, Daily, Hourly)
                  Text(
                    '${'investmentDetails'.tr} · $basisLabel',
                    style: GoogleFonts.poppins(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.border,
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.2 : 0.03,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildDetailRow(
                          label:
                              '${'expectedReturnTotal'.tr} (${project.returnRatePercent.toStringAsFixed(2)}% / mo)',
                          value: calc == null ? '—' : CurrencyFormatter.format(
                            calc.expectedTotalReturn,
                            showDecimals: true,
                          ),
                          valueColor: AppColors.primary,
                          isBold: true,
                          isDark: isDark,
                        ),
                        const Divider(height: 22, color: AppColors.border),
                        _buildDetailRow(
                          label: 'monthlyReturn'.tr,
                          value: calc == null ? '—' : CurrencyFormatter.formatPrecise(
                            calc.monthlyProjectedReturn,
                            decimalDigits: 2,
                          ),
                          isDark: isDark,
                        ),
                        const Divider(height: 22, color: AppColors.border),
                        _buildDetailRow(
                          label: 'Daily Return',
                          value: calc == null ? '—' : CurrencyFormatter.formatPrecise(
                            calc.dailyProjectedReturn,
                            decimalDigits: 2,
                          ),
                          isDark: isDark,
                        ),
                        const Divider(height: 22, color: AppColors.border),
                        _buildDetailRow(
                          label: 'Hourly Return',
                          value: calc == null ? '—' : CurrencyFormatter.formatPrecise(
                            calc.hourlyProjectedReturn,
                            decimalDigits: 2,
                          ),
                          isDark: isDark,
                        ),
                        const Divider(height: 22, color: AppColors.border),
                        _buildDetailRow(
                          label: 'investmentPeriod'.tr,
                          value: '${project.durationMonths} Months',
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 4. Risk Information Card & Description
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.surfaceDark
                          : const Color(0xFFF7FAF8),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? AppColors.borderDark
                            : const Color(0xFFE4EFE8),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Remix.shield_check_line,
                              size: 18,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                project.name,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                'Risk: ${project.riskLevel.isNotEmpty ? project.riskLevel : "Moderate"}',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF92400E),
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (project.description.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            project.description,
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              color: isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textPrimary,
                              height: 1.45,
                            ),
                          ),
                        ],
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Remix.information_line,
                              size: 15,
                              color: AppColors.textSecondary,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                'Projections and return estimates are indicative and subject to underlying project terms.',
                                style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 5. Bottom CTA: Invest Now
                  CustomButton(
                    text: 'investNow'.tr,
                    onPressed: project.status.toLowerCase() == 'active'
                        ? () {
                            invCtrl.setProject(project);
                            if (selectedPrincipal != null && !invCtrl.isProcessingPayment.value) {
                              invCtrl.selectQuickAmount(selectedPrincipal);
                            }
                            Get.toNamed(AppRoutes.investNow);
                          }
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // Subtitle Security Note
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Remix.checkbox_circle_line,
                          size: 15,
                          color: AppColors.success,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'safeAndSecureNote'.tr,
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildIconPlaceholder(String iconType) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        _getIcon(iconType),
        color: Colors.white,
        size: 24,
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 13,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              color: valueColor ??
                  (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
            ),
          ),
        ),
      ],
    );
  }
}
