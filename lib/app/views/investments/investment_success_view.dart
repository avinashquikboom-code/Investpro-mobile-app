import 'package:remixicon/remixicon.dart';
import '../../widgets/app_system_ui.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/investment_controller.dart';
import '../../controllers/navigation_controller.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/custom_button.dart';

class InvestmentSuccessView extends StatelessWidget {
  const InvestmentSuccessView({super.key});

  @override
  Widget build(BuildContext context) {
    final invCtrl = Get.find<InvestmentController>();
    final navCtrl = Get.find<NavigationController>();

    final investment =
        invCtrl.lastSuccessfulInvestment.value ??
        (invCtrl.filteredInvestments.isNotEmpty
            ? invCtrl.filteredInvestments.first
            : null);

    return AppSystemUi(
      statusSurface: AppColors.background,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          navCtrl.goToHome();
          Get.offAllNamed(AppRoutes.home);
        },
        child: Scaffold(
          body: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.secondaryBackground,
            ),
            child: SafeArea(
              child: ResponsiveHelper.responsiveContainer(
                context: context,
                maxWidth: 500,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 20,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),
                      // Large White Circle with Green Checkmark
                      Container(
                        width: 90,
                        height: 90,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 20,
                              offset: Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Remix.check_line,
                            size: 52,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),

                      // Heading
                      Text(
                        'investmentSuccessful'.tr,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'investmentSuccessSubtitle'.tr,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),

                      // White Summary Card
                      if (investment != null)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 15,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              _buildSummaryItem(
                                'projectName'.tr,
                                investment.projectName,
                                isHighlight: true,
                              ),
                              const Divider(
                                height: 20,
                                color: AppColors.border,
                              ),
                              _buildSummaryItem(
                                'amountInvested'.tr,
                                CurrencyFormatter.format(
                                  investment.investedAmount,
                                ),
                              ),
                              const Divider(
                                height: 20,
                                color: AppColors.border,
                              ),
                              _buildSummaryItem(
                                'expectedReturnTotal'.tr,
                                CurrencyFormatter.format(
                                  investment.expectedReturn,
                                ),
                                valueColor: AppColors.primary,
                              ),
                              const Divider(
                                height: 20,
                                color: AppColors.border,
                              ),
                              _buildSummaryItem(
                                'investmentPeriod'.tr,
                                '${investment.durationMonths} Months',
                              ),
                              const Divider(
                                height: 20,
                                color: AppColors.border,
                              ),
                              _buildSummaryItem(
                                'investmentReference'.tr,
                                investment.reference.isNotEmpty
                                    ? investment.reference
                                    : 'N/A',
                                isCode: true,
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 34),

                      // View My Investments Button
                      CustomButton(
                        text: 'viewMyInvestments'.tr,
                        backgroundColor: AppColors.primary,
                        textColor: Colors.white,
                        onPressed: () {
                          navCtrl.goToInvestments();
                          Get.offAllNamed(AppRoutes.home);
                        },
                      ),
                      const SizedBox(height: 12),

                      // Go to Home Button
                      CustomButton(
                        text: 'goToHome'.tr,
                        isOutlined: true,
                        backgroundColor: AppColors.primary,
                        textColor: AppColors.primary,
                        onPressed: () {
                          navCtrl.goToHome();
                          Get.offAllNamed(AppRoutes.home);
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value, {
    bool isHighlight = false,
    bool isCode = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: isHighlight ? 14 : 13,
              fontWeight: isHighlight || isCode
                  ? FontWeight.w700
                  : FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
              fontFamily: isCode ? 'monospace' : null,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
