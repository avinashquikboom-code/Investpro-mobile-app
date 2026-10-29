import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../constants/app_constants.dart';
import '../../controllers/investment_controller.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_button.dart';

class InvestNowView extends StatelessWidget {
  const InvestNowView({super.key});

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
      appBar: const CustomAppBar(title: 'Invest Now'),
      body: SafeArea(
        child: ResponsiveHelper.responsiveContainer(
          context: context,
          maxWidth: 600,
          child: Obx(() {
            final project = invCtrl.currentProject.value;
            if (project == null) {
              return const Center(child: Text('Please select a project'));
            }

            final calc = invCtrl.calculationResult;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selected Project Summary Card
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
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppColors.primaryDark,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _getIcon(project.iconType),
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
                                project.name,
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
                                '${project.returnRatePercent.toInt()}% Return  |  ${project.durationMonths} Months',
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Enter Investment Amount Label
                  Text(
                    'enterInvestmentAmount'.tr,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Amount Input Field with Rupee Icon
                  TextField(
                    controller: invCtrl.amountTextController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                    decoration: InputDecoration(
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(left: 16, right: 8),
                        child: Text(
                          '₹',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 0,
                        minHeight: 0,
                      ),
                      suffixIcon: const Icon(
                        Icons.account_balance_wallet_outlined,
                        color: AppColors.primary,
                      ),
                      filled: true,
                      fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Quick Chips: ₹ 10K, ₹ 25K, ₹ 50K, ₹ 1L
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: AppConstants.quickInvestAmounts.map((amt) {
                        final isSelected =
                            invCtrl.investmentAmount.value == amt;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(
                              CurrencyFormatter.formatCompact(amt),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimary),
                              ),
                            ),
                            selected: isSelected,
                            selectedColor: AppColors.primaryDark,
                            backgroundColor: isDark
                                ? AppColors.surfaceDark
                                : Colors.white,
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primaryDark
                                  : (isDark
                                        ? AppColors.borderDark
                                        : AppColors.border),
                            ),
                            onSelected: (_) => invCtrl.selectQuickAmount(amt),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Summary Details Card
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
                          label:
                              'Expected Return (${project.returnRatePercent.toInt()}%)',
                          value: CurrencyFormatter.format(
                            calc.expectedTotalReturn,
                          ),
                          valueColor: AppColors.primary,
                        ),
                        const Divider(height: 22, color: AppColors.border),
                        _buildSummaryRow(
                          context: context,
                          label: 'maturityAmount'.tr,
                          value: CurrencyFormatter.format(
                            calc.projectedMaturityAmount,
                          ),
                          isBold: true,
                        ),
                        const Divider(height: 22, color: AppColors.border),
                        _buildSummaryRow(
                          context: context,
                          label: 'investmentPeriod'.tr,
                          value: '${project.durationMonths} Months',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Primary Button: Proceed to Pay
                  CustomButton(
                    text: 'proceedToPay'.tr,
                    onPressed: invCtrl.amountError == null
                        ? invCtrl.proceedToPaymentConfirmation
                        : null,
                  ),
                  const SizedBox(height: 14),

                  if (invCtrl.amountError != null)
                    Text(
                      invCtrl.amountError!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  const Text(
                    'Full-term projections only. Returns are not guaranteed. Demo payment only.',
                  ),
                  // Security Footer
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.lock_outline_rounded,
                          size: 16,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'secureEncryptedPayment'.tr,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
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
