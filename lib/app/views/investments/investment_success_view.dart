import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remixicon/remixicon.dart';

import '../../controllers/investment_controller.dart';
import '../../controllers/navigation_controller.dart';
import '../../routes/app_routes.dart';
import '../../services/investment_calculator.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/app_system_ui.dart';
import '../../widgets/custom_button.dart';

/// Screen 4 – Investment Success
/// Displays circular checkmark, confirmed investment details, projected maturity amount,
/// monthly and daily return breakdown, real backend investment reference, disclaimer,
/// and navigation to My Investments or Home.
class InvestmentSuccessView extends StatelessWidget {
  const InvestmentSuccessView({super.key});

  @override
  Widget build(BuildContext context) {
    final invCtrl = Get.find<InvestmentController>();
    final navCtrl = Get.find<NavigationController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final investment = invCtrl.lastSuccessfulInvestment.value ??
        (invCtrl.filteredInvestments.isNotEmpty
            ? invCtrl.filteredInvestments.first
            : null);

    final calc = investment != null
        ? InvestmentCalculator.calculate(
            principal: investment.investedAmount,
            returnRatePercent: investment.returnRatePercent,
            durationMonths: investment.durationMonths,
          )
        : null;

    final maturityAmount = investment != null
        ? (calc?.projectedMaturityAmount ??
            (investment.investedAmount + investment.expectedReturn))
        : 0.0;
    final monthlyReturn = investment != null && investment.durationMonths > 0
        ? (calc?.monthlyProjectedReturn ??
            (investment.expectedReturn / investment.durationMonths))
        : 0.0;
    final dailyEquivalent = monthlyReturn / 30.0;

    return AppSystemUi(
      statusSurface: isDark ? AppColors.backgroundDark : AppColors.background,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          navCtrl.goToHome();
          Get.offAllNamed(AppRoutes.home);
        },
        child: Scaffold(
          backgroundColor:
              isDark ? AppColors.backgroundDark : const Color(0xFFF7FAF8),
          body: SafeArea(
            child: ResponsiveHelper.responsiveContainer(
              context: context,
              maxWidth: 540,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 24,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    // Large Circular Checkmark Badge
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.2),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                        border: Border.all(
                          color: const Color(0xFFD1EBE0),
                          width: 2,
                        ),
                      ),
                      child: const Center(
                        child: Icon(
                          Remix.check_line,
                          size: 48,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Title
                    Text(
                      'investmentSuccessful'.tr,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'investmentSuccessSubtitle'.tr,
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 26),

                    // Investment Details Card
                    if (investment != null)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.border,
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(
                                alpha: isDark ? 0.2 : 0.04,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            _buildSummaryItem(
                              'projectName'.tr,
                              investment.projectName,
                              isHighlight: true,
                              isDark: isDark,
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
                              isDark: isDark,
                            ),
                            const Divider(
                              height: 20,
                              color: AppColors.border,
                            ),
                            _buildSummaryItem(
                              'expectedReturnTotal'.tr,
                              CurrencyFormatter.format(
                                investment.expectedReturn,
                                showDecimals: true,
                              ),
                              valueColor: AppColors.primary,
                              isDark: isDark,
                            ),
                            const Divider(
                              height: 20,
                              color: AppColors.border,
                            ),
                            _buildSummaryItem(
                              'maturityAmount'.tr,
                              CurrencyFormatter.format(
                                maturityAmount,
                                showDecimals: true,
                              ),
                              isBold: true,
                              isDark: isDark,
                            ),
                            const Divider(
                              height: 20,
                              color: AppColors.border,
                            ),
                            _buildSummaryItem(
                              'investmentPeriod'.tr,
                              '${investment.durationMonths} Months',
                              isDark: isDark,
                            ),
                            const Divider(
                              height: 20,
                              color: AppColors.border,
                            ),
                            _buildSummaryItem(
                              'Monthly Projected Return',
                              CurrencyFormatter.formatPrecise(
                                monthlyReturn,
                                decimalDigits: 2,
                              ),
                              valueColor: AppColors.primary,
                              isDark: isDark,
                            ),
                            const Divider(
                              height: 20,
                              color: AppColors.border,
                            ),
                            _buildSummaryItem(
                              'Daily Equivalent',
                              CurrencyFormatter.formatPrecise(
                                dailyEquivalent,
                                decimalDigits: 2,
                              ),
                              isDark: isDark,
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
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),

                    // Disclaimer
                    Text(
                      'Projected returns are estimates and are not guaranteed.',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 26),

                    // Navigation Buttons: View My Investments & Go to Home
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
    );
  }

  Widget _buildSummaryItem(
    String label,
    String value, {
    bool isHighlight = false,
    bool isBold = false,
    bool isCode = false,
    Color? valueColor,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            color:
                isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: isCode
                ? TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: valueColor ??
                        (isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary),
                  )
                : GoogleFonts.poppins(
                    fontSize: isHighlight || isBold ? 14 : 13,
                    fontWeight: isHighlight || isBold
                        ? FontWeight.w700
                        : FontWeight.w600,
                    color: valueColor ??
                        (isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary),
                  ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
