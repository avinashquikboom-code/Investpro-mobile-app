import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remixicon/remixicon.dart';

import '../../constants/app_constants.dart';
import '../../controllers/investment_controller.dart';
import '../../models/project_model.dart';
import '../../services/investment_calculator.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/unsaved_changes_guard.dart';

/// Screen 1 – Invest Now
/// Implements live investment calculation, presets, return breakdown,
/// selectable schedule tabs, dynamic monthly amortization table, and secure CTA.
class InvestNowView extends StatefulWidget {
  const InvestNowView({super.key});

  @override
  State<InvestNowView> createState() => _InvestNowViewState();
}

class _InvestNowViewState extends State<InvestNowView> {
  // Return schedule tab: 'Daily', 'Hourly', 'Monthly', 'Total'
  String _selectedScheduleTab = 'Monthly';

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
    final invCtrl = Get.find<InvestmentController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return UnsavedChangesGuard(
      controllers: [invCtrl.amountTextController],
      changes: [invCtrl.investmentAmount.stream],
      snapshot: () => invCtrl.investmentAmount.value,
      child: Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.background,
        appBar: const CustomAppBar(title: 'Invest Now'),
        body: SafeArea(
          child: ResponsiveHelper.responsiveContainer(
            context: context,
            maxWidth: 640,
            child: Obx(() {
              final project = invCtrl.currentProject.value;
              if (project == null) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Remix.folder_warning_line,
                        size: 48,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Please select a project to invest',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => Get.back(),
                        child: const Text('Back to Projects'),
                      ),
                    ],
                  ),
                );
              }

              final calc = invCtrl.calculationResult;

              return SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Project Information Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.border,
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
                        children: [
                          // Project Icon / Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: project.imageUrl != null &&
                                    project.imageUrl!.isNotEmpty
                                ? Image.network(
                                    project.imageUrl!,
                                    width: 48,
                                    height: 48,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, stack) =>
                                        _buildIconPlaceholder(project.iconType),
                                  )
                                : _buildIconPlaceholder(project.iconType),
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
                                const SizedBox(height: 4),
                                Row(
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
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        '${project.returnRatePercent.toStringAsFixed(2)}% Return',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '|  ${calc.investmentDuration ?? calc.durationMonths} ${calc.durationUnit.toLowerCase()}',
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
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),

                    // 2. Investment Amount Section
                    Text(
                      'enterInvestmentAmount'.tr,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Amount Input with ₹ and Wallet Icon
                    TextField(
                      controller: invCtrl.amountTextController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: GoogleFonts.poppins(
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
                        suffixIcon: const Padding(
                          padding: EdgeInsets.only(right: 14),
                          child: Icon(
                            Remix.wallet_3_line,
                            color: AppColors.primary,
                            size: 22,
                          ),
                        ),
                        hintText: '5000',
                        filled: true,
                        fillColor:
                            isDark ? AppColors.surfaceDark : Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.border,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: isDark
                                ? AppColors.borderDark
                                : AppColors.border,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Preset quick amounts use compact labels; financial summaries retain decimals.
                    Wrap(
                      runSpacing: 8,
                      children: AppConstants.quickInvestAmounts.map((amt) {
                          final isSelected =
                              (invCtrl.investmentAmount.value - amt).abs() <
                                  0.01;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(
                                amt == 100000 ? '₹1L' : '₹${(amt / 1000).toStringAsFixed(0)}K',
                                style: GoogleFonts.poppins(
                                  fontSize: 12.5,
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
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              side: BorderSide(
                                color: isSelected
                                    ? AppColors.primaryDark
                                    : (isDark
                                        ? AppColors.borderDark
                                        : AppColors.border),
                              ),
                              onSelected: (_) =>
                                  invCtrl.selectQuickAmount(amt),
                            ),
                          );
                        }).toList(),
                    ),
                    const SizedBox(height: 22),

                    // 3. Investment Summary Card
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : AppColors.border,
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
                          Text(
                            'Investment Summary',
                            style: GoogleFonts.poppins(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 14),

                          if (invCtrl.isLive && invCtrl.backendProjection.value == null) ...[
                            Text(invCtrl.projectionError.value.isEmpty ? 'Loading latest project projection…' : invCtrl.projectionError.value),
                            if (invCtrl.projectionError.value.isNotEmpty) TextButton(onPressed: invCtrl.fetchBackendProjection, child: const Text('Retry projection')),
                          ],
                          // Investment Amount
                          _buildSummaryRow(
                            label: 'Investment Amount',
                            value: CurrencyFormatter.format(calc.principal),
                            isDark: isDark,
                          ),
                          const Divider(
                            height: 20,
                            color: AppColors.border,
                          ),

                          // Projected Return (Total)
                          _buildSummaryRow(
                            label:
                                'Total Projected Return',
                            value: CurrencyFormatter.format(
                              calc.expectedTotalReturn,
                              showDecimals: true,
                            ),
                            valueColor: AppColors.primary,
                            isBold: true,
                            isDark: isDark,
                          ),
                          const Divider(
                            height: 20,
                            color: AppColors.border,
                          ),

                          // Monthly Projected Return
                          _buildSummaryRow(
                            label: 'Monthly Return (${calc.returnRatePercent.toStringAsFixed(2)}%)',
                            value: CurrencyFormatter.formatPrecise(
                              calc.monthlyProjectedReturn,
                              decimalDigits: 2,
                            ),
                            valueColor: AppColors.primary,
                            isDark: isDark,
                          ),
                          const Divider(
                            height: 20,
                            color: AppColors.border,
                          ),

                          // Daily Projected Return
                          _buildSummaryRow(
                            label: 'Daily Projected Return',
                            value: CurrencyFormatter.formatPrecise(
                              calc.dailyProjectedReturn,
                              decimalDigits: 4,
                            ),
                            isDark: isDark,
                          ),
                          const Divider(
                            height: 20,
                            color: AppColors.border,
                          ),

                          // Hourly Projected Return
                          _buildSummaryRow(
                            label: 'Hourly Projected Return',
                            value: CurrencyFormatter.formatPrecise(
                              calc.hourlyProjectedReturn,
                              decimalDigits: 4,
                            ),
                            isDark: isDark,
                          ),
                          const Divider(
                            height: 20,
                            color: AppColors.border,
                          ),

                          // Investment Period
                          _buildSummaryRow(
                            label: 'Investment Period',
                            value: '${calc.investmentDuration ?? calc.durationMonths} ${calc.durationUnit.toLowerCase()}',
                            isDark: isDark,
                          ),
                          _buildSummaryRow(label: 'Previous Monthly Interest Payouts', value: CurrencyFormatter.format(calc.previousMonthlyInterestPayouts, showDecimals: true), isDark: isDark),
                          _buildSummaryRow(label: 'Final Month Interest', value: CurrencyFormatter.format(calc.finalMonthInterest, showDecimals: true), isDark: isDark),
                          _buildSummaryRow(label: 'Principal Repayment at Maturity', value: CurrencyFormatter.format(calc.principalRepaymentAtMaturity, showDecimals: true), isDark: isDark),
                          _buildSummaryRow(label: 'Total Received Over Investment Period', value: CurrencyFormatter.format(calc.totalReceivedOverInvestmentPeriod, showDecimals: true), isDark: isDark),
                          _buildSummaryRow(label: 'Project End Date', value: calc.projectEndDate ?? project.endDate?.toIso8601String().split('T').first ?? '—', isDark: isDark),
                          _buildSummaryRow(label: 'Final Eligible Date', value: calc.finalEligibleDate ?? '—', isDark: isDark),
                          const SizedBox(height: 16),

                          // Dark Green Highlight Bar for Projected Maturity Amount
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF003B2D), Color(0xFF004B38)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Projected Maturity Amount',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFB4E0CA),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    CurrencyFormatter.format(
                                      calc.finalMonthPayment,
                                      showDecimals: true,
                                    ),
                                    style: GoogleFonts.poppins(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 4. Return Schedule Section with Selectable Tabs
                    Text(
                      'Return Schedule',
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Schedule Tabs: Daily, Hourly, Monthly, Total
                    Row(
                      children: ['Daily', 'Hourly', 'Monthly', 'Total']
                          .map((tab) {
                        final isTabSelected = _selectedScheduleTab == tab;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: GestureDetector(
                              onTap: () =>
                                  setState(() => _selectedScheduleTab = tab),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 9),
                                decoration: BoxDecoration(
                                  color: isTabSelected
                                      ? AppColors.primary
                                      : (isDark
                                          ? AppColors.surfaceDark
                                          : const Color(0xFFF1FAF4)),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isTabSelected
                                        ? AppColors.primary
                                        : (isDark
                                            ? AppColors.borderDark
                                            : AppColors.border),
                                  ),
                                ),
                                child: Text(
                                  tab,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: isTabSelected
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isTabSelected
                                        ? Colors.white
                                        : (isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textPrimary),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    // Selected Tab Value Display Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceDark
                            : const Color(0xFFF1FAF4),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : const Color(0xFFD3EADB),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(
                                  Remix.time_line,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '$_selectedScheduleTab Return Rate:',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                _getTabReturnValue(calc, _selectedScheduleTab),
                                style: GoogleFonts.poppins(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 5. Dynamic Return Schedule Table
                    Text(
                      'Monthly Return Schedule',
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),

                    _buildDynamicScheduleTable(calc, project, isDark),
                    const SizedBox(height: 28),

                    // 6. Primary Action: Proceed to Pay Button
                    CustomButton(
                      text: 'proceedToPay'.tr,
                      onPressed: invCtrl.amountError == null
                          ? invCtrl.proceedToPaymentConfirmation
                          : null,
                    ),
                    const SizedBox(height: 12),

                    // Amount Error Notice
                    if (invCtrl.amountError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          invCtrl.amountError!,
                          style: GoogleFonts.poppins(
                            color: AppColors.error,
                            fontSize: 12,
                          ),
                        ),
                      ),

                    // Full-term projections disclaimer
                    Center(
                      child: Text(
                        'Full-term projections only. Returns are not guaranteed.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Secure & Encrypted Payment Footer
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Remix.lock_2_line,
                            size: 15,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'secureEncryptedPayment'.tr,
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
                    const SizedBox(height: 24),
                  ],
                ),
              );
            }),
          ),
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

  String _getTabReturnValue(
    dynamic calc,
    String tab,
  ) {
    switch (tab) {
      case 'Daily':
        return '${CurrencyFormatter.formatPrecise(calc.dailyProjectedReturn, decimalDigits: 2)} / day';
      case 'Hourly':
        return '${CurrencyFormatter.formatPrecise(calc.hourlyProjectedReturn, decimalDigits: 2)} / hr';
      case 'Monthly':
        return '${CurrencyFormatter.formatPrecise(calc.monthlyProjectedReturn, decimalDigits: 2)} / mo';
      case 'Total':
      default:
        return CurrencyFormatter.format(calc.expectedTotalReturn,
            showDecimals: true);
    }
  }

  Widget _buildDynamicScheduleTable(
    InvestmentCalculationResult calc,
    ProjectModel project,
    bool isDark,
  ) {
    if (_selectedScheduleTab == 'Monthly' && calc.payoutSchedule.isNotEmpty) {
      String amount(dynamic value) => CurrencyFormatter.format((value as num).toDouble(), showDecimals: true);
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(columns: const [
          DataColumn(label: Text('Month / Date')), DataColumn(label: Text('Interest')),
          DataColumn(label: Text('Principal')), DataColumn(label: Text('Total Payout')),
          DataColumn(label: Text('Status')),
        ], rows: calc.payoutSchedule.map((p) => DataRow(cells: [
          DataCell(Text('${p['payoutType'] == 'MATURITY' ? 'Final maturity' : 'Month ${p['payoutNumber']}'}\n${p['payoutDate'].toString().split('T').first}')),
          DataCell(Text(amount(p['interestAmount']))), DataCell(Text(amount(p['principalAmount']))),
          DataCell(Text(amount(p['totalPayoutAmount']))), DataCell(Text(p['payoutStatus'] == 'UPCOMING' ? 'Upcoming' : p['payoutStatus'].toString())),
        ])).toList()),
      );
    }
    final String col1Header;
    final String col2Header;
    final String col3Header;
    final String footerLabel;
    final String footerValue;
    final List<Map<String, String>> rows = [];

    switch (_selectedScheduleTab) {
      case 'Daily':
        col1Header = 'Day';
        col2Header = 'Daily Return';
        col3Header = 'Cumulative';
        footerLabel = 'Total Eligible Accrual';
        footerValue = CurrencyFormatter.format(
          calc.dailySchedule.isNotEmpty
              ? calc.dailySchedule.last.cumulativeReturn
              : 0.0,
          showDecimals: true,
        );
        for (final item in calc.dailySchedule) {
          rows.add({
            'col1': item.label,
            'col2': CurrencyFormatter.format(item.returnAmount, showDecimals: true),
            'col3': CurrencyFormatter.format(item.cumulativeReturn, showDecimals: true),
          });
        }
        break;
      case 'Hourly':
        col1Header = 'Hour';
        col2Header = 'Hourly Accrual';
        col3Header = 'Cumulative';
        footerLabel = '24-Hour Total (1 Day)';
        footerValue = CurrencyFormatter.format(
          calc.dailyProjectedReturn,
          showDecimals: true,
        );
        for (final item in calc.hourlySchedule) {
          rows.add({
            'col1': item.label,
            'col2': CurrencyFormatter.formatPrecise(item.returnAmount, decimalDigits: 2),
            'col3': CurrencyFormatter.format(item.cumulativeReturn, showDecimals: true),
          });
        }
        break;
      case 'Total':
        col1Header = 'Milestone';
        col2Header = 'Period Return';
        col3Header = 'Cumulative';
        footerLabel = 'Total Received Over Investment Period';
        footerValue = CurrencyFormatter.format(
          calc.projectedMaturityAmount,
          showDecimals: true,
        );
        for (final item in calc.totalSchedule) {
          rows.add({
            'col1': item.label,
            'col2': CurrencyFormatter.format(item.returnAmount, showDecimals: true),
            'col3': CurrencyFormatter.format(item.cumulativeReturn, showDecimals: true),
          });
        }
        break;
      case 'Monthly':
      default:
        col1Header = 'Month';
        col2Header = 'Monthly Return';
        col3Header = 'Cumulative Return';
        footerLabel = 'Total Eligible Return';
        footerValue = CurrencyFormatter.format(
          calc.expectedTotalReturn,
          showDecimals: true,
        );
        for (final item in calc.monthlySchedule) {
          rows.add({
            'col1': 'Month ${item.month}',
            'col2': CurrencyFormatter.format(item.monthlyReturn, showDecimals: true),
            'col3': CurrencyFormatter.format(item.cumulativeReturn, showDecimals: true),
          });
        }
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceDarkElevated
                  : const Color(0xFFF7FAF8),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    col1Header,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    col2Header,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    col3Header,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.border),

          // Table Rows
          ...rows.asMap().entries.map((entry) {
            final idx = entry.key;
            final item = entry.value;
            final isEven = idx % 2 == 1;
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10,
              ),
              color: isEven && !isDark
                  ? const Color(0xFFFAFCFA)
                  : Colors.transparent,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      item['col1'] ?? '',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      item['col2'] ?? '',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 3,
                    child: Text(
                      item['col3'] ?? '',
                      textAlign: TextAlign.right,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),

          const Divider(height: 1, color: AppColors.border),

          // Total Footer Row
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.surfaceDarkElevated
                  : const Color(0xFFF1FAF4),
              borderRadius: const BorderRadius.vertical(
                bottom: Radius.circular(15),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    footerLabel,
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      footerValue,
                      textAlign: TextAlign.right,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow({
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
              fontWeight: FontWeight.w400,
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
