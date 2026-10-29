import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../services/investment_calculator.dart';
import '../../controllers/returns_controller.dart';
import '../../utils/date_formatter.dart';
import '../../controllers/investment_controller.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/progress_indicator.dart';
import '../../widgets/status_badge.dart';

class InvestmentDetailsView extends StatelessWidget {
  const InvestmentDetailsView({super.key});

  IconData _getIcon(String iconType) {
    switch (iconType.toLowerCase()) {
      case 'code':
        return Icons.code_rounded;
      case 'mobile':
        return Icons.phone_android_rounded;
      case 'gear':
      case 'ai':
        return Icons.settings_suggest_rounded;
      default:
        return Icons.business_center_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final invCtrl = Get.find<InvestmentController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: const CustomAppBar(title: 'Investment Details'),
      body: SafeArea(
        child: ResponsiveHelper.responsiveContainer(
          context: context,
          maxWidth: 600,
          child: Obx(() {
            final investment =
                invCtrl.selectedInvestment.value ??
                (invCtrl.filteredInvestments.isNotEmpty
                    ? invCtrl.filteredInvestments.first
                    : null);

            if (investment == null) {
              return const Center(child: Text('No investment selected'));
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Project Header Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.border,
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.primaryDark,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getIcon(investment.iconType),
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                investment.projectName,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${investment.returnRatePercent.toInt()}% Return  |  ${investment.durationMonths} Months',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        StatusBadge(status: investment.status),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),

                  // Investment Summary Card
                  Text(
                    'investmentSummary'.tr,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(18),
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
                        _buildSummaryRow(
                          context: context,
                          label: 'amountInvested'.tr,
                          value: CurrencyFormatter.format(
                            investment.investedAmount,
                          ),
                        ),
                        const Divider(height: 22, color: AppColors.border),
                        _buildSummaryRow(
                          context: context,
                          label: 'expectedReturnTotal'.tr,
                          value: CurrencyFormatter.format(
                            investment.expectedReturn,
                          ),
                          valueColor: AppColors.primary,
                        ),
                        const Divider(height: 22, color: AppColors.border),
                        _buildSummaryRow(
                          context: context,
                          label: 'maturityAmount'.tr,
                          value: CurrencyFormatter.format(
                            investment.maturityAmount,
                          ),
                          isBold: true,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 26),

                  // Timeline Section
                  Text(
                    'timeline'.tr,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark ? AppColors.borderDark : AppColors.border,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: List.generate(5, (n) {
                        const titles = [
                          'Investment Start',
                          'Development Phase',
                          'Product Launch',
                          'Return Period',
                          'Maturity Date',
                        ];
                        final offsets = [
                          0,
                          (investment.durationMonths / 4).round(),
                          (investment.durationMonths / 2).round(),
                          investment.durationMonths - 1,
                          investment.durationMonths,
                        ];
                        final date = InvestmentCalculator.addMonths(
                          investment.startDate,
                          offsets[n],
                        );
                        return TimelineStepWidget(
                          title: titles[n],
                          date: DateFormatter.formatDate(date),
                          isCompleted: !date.isAfter(DateTime.now()),
                          isActive:
                              date.isAfter(DateTime.now()) &&
                              (n == 0 ||
                                  !InvestmentCalculator.addMonths(
                                    investment.startDate,
                                    offsets[n - 1],
                                  ).isAfter(DateTime.now())),
                          isLast: n == 4,
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Return Schedule Action
                  CustomButton(
                    text: 'View Return Schedule',
                    isOutlined: true,
                    onPressed: () {
                      Get.find<ReturnsController>().investmentFilter.value =
                          investment.id;
                      Get.toNamed(AppRoutes.returns);
                    },
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

  Widget _buildSummaryRow({
    required BuildContext context,
    required String label,
    required String value,
    Color? valueColor,
    bool isBold = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Text(
            label,
            style: TextStyle(
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
            style: TextStyle(
              fontSize: 14,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              color:
                  valueColor ??
                  (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
            ),
          ),
        ),
      ],
    );
  }
}
