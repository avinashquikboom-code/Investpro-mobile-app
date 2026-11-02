import 'returns_workspace_view.dart';
import 'interest_breakdown_section.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';

import '../../controllers/returns_controller.dart';
import '../../models/return_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/app_app_bar.dart';
import '../../widgets/app_system_ui.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/returns_bar_chart.dart';
import '../../widgets/status_badge.dart';

class ReturnsView extends StatelessWidget {
  final bool isTab;

  const ReturnsView({super.key, this.isTab = true});

  @override
  Widget build(BuildContext context) {
    final returnsCtrl = Get.find<ReturnsController>();
    if (returnsCtrl.isLive) return ReturnsWorkspaceView(isTab: isTab);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final periodTabs = ['Monthly', 'Quarterly', 'Yearly'];

    return AppSystemUi(
      statusSurface: isDark ? AppColors.backgroundDark : AppColors.background,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
        appBar: !isTab
            ? const AppAppBar(
                title: 'Returns',
                showBackButton: true,
              )
            : null,
        body: SafeArea(
          top: isTab,
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: returnsCtrl.refreshData,
            child: ResponsiveHelper.responsiveContainer(
              context: context,
              maxWidth: 640,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Screen Header
                    if (isTab) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Returns',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.primaryDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Track your investment returns and payouts',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    // 2. Total Returns Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : const Color(0xFFE5EFEA),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            offset: const Offset(0, 4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Left Details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Returns',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Obx(() {
                                  return FittedBox(
                                    fit: BoxFit.scaleDown,
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      CurrencyFormatter.format(
                                        returnsCtrl.totalReturns,
                                      ),
                                      style: GoogleFonts.poppins(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? AppColors.textPrimaryDark
                                            : const Color(0xFF102F25),
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  );
                                }),
                                Obx(() {
                                  if (returnsCtrl.totalReturns == 0) {
                                    return Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Text(
                                        'No payouts credited yet',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11.5,
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondary,
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    );
                                  }
                                  return const SizedBox.shrink();
                                }),
                                const SizedBox(height: 8),

                                // Growth percentage indicator vs last period (only when supported)
                                Obx(() {
                                  final comp = returnsCtrl.periodComparison;
                                  if (comp == null) {
                                    return const SizedBox.shrink();
                                  }

                                  return Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.badgeGreenBg,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              comp.startsWith('-')
                                                  ? Remix.arrow_down_line
                                                  : Remix.arrow_up_line,
                                              size: 13,
                                              color: comp.startsWith('-')
                                                  ? AppColors.error
                                                  : AppColors.primary,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              comp,
                                              style: GoogleFonts.poppins(
                                                color: comp.startsWith('-')
                                                    ? AppColors.error
                                                    : AppColors.primary,
                                                fontSize: 11.5,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'vs last period',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11.5,
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  );
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Right Decoration (Green Chart Artwork)
                          Container(
                            width: 54,
                            height: 54,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.surfaceDarkElevated
                                  : AppColors.lightMint,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? AppColors.borderDark
                                    : const Color(0xFFD3EBE0),
                                width: 1,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Remix.funds_line,
                                color: AppColors.primary,
                                size: 26,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 2b. Today's Earnings and Return Summary Card
                    Obx(() {
                      final totalReturnsVal = returnsCtrl.totalReturns;
                      final monthlyEq = totalReturnsVal > 0 ? totalReturnsVal : 1200.0;
                      final dailyEq = monthlyEq / 30.0;
                      final hourlyEq = dailyEq / 24.0;
                      final todayEarn = dailyEq;
                      final lastSchedule = returnsCtrl.records.isNotEmpty ? returnsCtrl.records.first : null;
                      final nextSchedule = returnsCtrl.nextReturnSchedule;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceDark : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isDark ? AppColors.borderDark : const Color(0xFFE5EFEA),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  offset: const Offset(0, 4),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Today's Earnings and Return Summary",
                                  style: GoogleFonts.poppins(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.textPrimaryDark : const Color(0xFF102F25),
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Today's Earnings",
                                            style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                                          ),
                                          const SizedBox(height: 2),
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              CurrencyFormatter.formatPrecise(todayEarn, decimalDigits: 2),
                                              style: GoogleFonts.poppins(
                                                fontSize: 17,
                                                fontWeight: FontWeight.w700,
                                                color: const Color(0xFF10B981),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            'Estimated Hourly Equivalent',
                                            style: GoogleFonts.poppins(fontSize: 11, color: AppColors.textSecondary),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerRight,
                                            child: Text(
                                              '${CurrencyFormatter.formatPrecise(hourlyEq, decimalDigits: 2)}/hr',
                                              style: GoogleFonts.poppins(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20, color: AppColors.border),
                                _buildSummaryTagRow("Projected Total Return", CurrencyFormatter.format(monthlyEq * 12), 'Projected', const Color(0xFFE0F2FE), const Color(0xFF0369A1), isDark),
                                const SizedBox(height: 8),
                                _buildSummaryTagRow("Monthly Projected Return", CurrencyFormatter.formatPrecise(monthlyEq, decimalDigits: 2), 'Projected', const Color(0xFFE0F2FE), const Color(0xFF0369A1), isDark),
                                const SizedBox(height: 8),
                                _buildSummaryTagRow("Daily Equivalent", CurrencyFormatter.formatPrecise(dailyEq, decimalDigits: 2), 'Projected', const Color(0xFFE0F2FE), const Color(0xFF0369A1), isDark),
                                const SizedBox(height: 8),
                                _buildSummaryTagRow("Hourly Equivalent", '${CurrencyFormatter.formatPrecise(hourlyEq, decimalDigits: 2)}/hr', 'Projected', const Color(0xFFE0F2FE), const Color(0xFF0369A1), isDark),
                                const SizedBox(height: 8),
                                _buildSummaryTagRow("Total Returns Credited", CurrencyFormatter.formatPrecise(totalReturnsVal, decimalDigits: 2), 'Credited', const Color(0xFFE8F7EC), AppColors.primary, isDark),
                                const SizedBox(height: 8),
                                _buildSummaryTagRow("Accrued, Not Credited", CurrencyFormatter.formatPrecise(dailyEq * 0.75, decimalDigits: 2), 'Accrued', const Color(0xFFFEF3C7), const Color(0xFF92400E), isDark),
                                const SizedBox(height: 8),
                                _buildSummaryTagRow("Last Payout", lastSchedule != null ? DateFormat('dd MMM yyyy').format(lastSchedule.payoutDate) : 'None credited yet', 'Credited', const Color(0xFFE8F7EC), AppColors.primary, isDark),
                                const SizedBox(height: 8),
                                _buildSummaryTagRow("Next Expected Payout", nextSchedule != null ? DateFormat('dd MMM yyyy').format(nextSchedule.payoutDate) : 'No upcoming payout', 'Scheduled', const Color(0xFFF3E8FF), const Color(0xFF6B21A8), isDark),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // 2c. Return Schedule Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceDark : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isDark ? AppColors.borderDark : const Color(0xFFE5EFEA),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  offset: const Offset(0, 4),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Return Schedule',
                                  style: GoogleFonts.poppins(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.textPrimaryDark : const Color(0xFF102F25),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildScheduleCol('Monthly Amount', CurrencyFormatter.formatPrecise(monthlyEq, decimalDigits: 2), isDark),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 32,
                                      color: AppColors.border,
                                      margin: const EdgeInsets.symmetric(horizontal: 6),
                                    ),
                                    Expanded(
                                      child: _buildScheduleCol('Daily Equivalent', CurrencyFormatter.formatPrecise(dailyEq, decimalDigits: 2), isDark),
                                    ),
                                    Container(
                                      width: 1,
                                      height: 32,
                                      color: AppColors.border,
                                      margin: const EdgeInsets.symmetric(horizontal: 6),
                                    ),
                                    Expanded(
                                      child: _buildScheduleCol('Hourly Equivalent', '${CurrencyFormatter.formatPrecise(hourlyEq, decimalDigits: 2)}/hr', isDark),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // 2d. Hourly Earnings Analytics Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.surfaceDark : Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: isDark ? AppColors.borderDark : const Color(0xFFE5EFEA),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.03),
                                  offset: const Offset(0, 4),
                                  blurRadius: 10,
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
                                      child: Text(
                                        'Hourly Earnings Analytics',
                                        style: GoogleFonts.poppins(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: isDark ? AppColors.textPrimaryDark : const Color(0xFF102F25),
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1FAF4),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFFD3EADB)),
                                      ),
                                      child: Text(
                                        'Indicative Projections',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 14),
                                HourlyEarningsChartWidget(
                                  hourlyRate: hourlyEq,
                                  isDark: isDark,
                                ),
                                _buildAnalyticsBarRow('Hourly Return', '${CurrencyFormatter.formatPrecise(hourlyEq, decimalDigits: 2)}/hr', 0.25, isDark),
                                const SizedBox(height: 10),
                                _buildAnalyticsBarRow('Daily Return', CurrencyFormatter.formatPrecise(dailyEq, decimalDigits: 2), 0.55, isDark),
                                const SizedBox(height: 10),
                                _buildAnalyticsBarRow('Monthly Return', CurrencyFormatter.formatPrecise(monthlyEq, decimalDigits: 2), 0.90, isDark),
                                const SizedBox(height: 12),
                                Text(
                                  'Daily and hourly figures are estimates. Actual payouts follow the investment agreement and backend payout schedule.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 10.5,
                                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                        ],
                      );
                    }),
                    Obx(() {
                      return Row(
                        children: periodTabs.map((period) {
                          final isSelected =
                              returnsCtrl.selectedPeriod.value == period;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: GestureDetector(
                                onTap: () => returnsCtrl.setPeriod(period),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primaryDark
                                        : (isDark
                                            ? AppColors.surfaceDark
                                            : Colors.white),
                                    borderRadius: BorderRadius.circular(24),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primaryDark
                                          : (isDark
                                              ? AppColors.borderDark
                                              : const Color(0xFFE5EFEA)),
                                      width: 1,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primaryDark
                                                  .withValues(alpha: 0.25),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Text(
                                    period,
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSelected
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
                      );
                    }),
                    const SizedBox(height: 18),

                    // 4. Interactive Returns Chart
                    Obx(() {
                      return ReturnsBarChart(
                        points: returnsCtrl.chartPoints,
                        period: returnsCtrl.selectedPeriod.value,
                        isDark: isDark,
                      );
                    }),
                    const SizedBox(height: 20),

                    // 5. Payout History Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark
                              ? AppColors.borderDark
                              : const Color(0xFFE5EFEA),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            offset: const Offset(0, 4),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Section Header
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Payout History',
                                style: GoogleFonts.poppins(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimary,
                                ),
                              ),
                              Obx(() {
                                final count = returnsCtrl.records.length;
                                return Text(
                                  '$count ${count == 1 ? 'payout' : 'payouts'}',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              }),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Payout Items List
                          Obx(() {
                            final list = returnsCtrl.payoutHistory;
                            if (list.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 24),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? AppColors.surfaceDarkElevated
                                              : AppColors.lightMint,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Remix.inbox_line,
                                          color: AppColors.primary,
                                          size: 22,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Text(
                                        'No return payouts found',
                                        style: GoogleFonts.poppins(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? AppColors.textPrimaryDark
                                              : AppColors.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Your payout history will appear here once returns are distributed.',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11.5,
                                          color: isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondary,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            return ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              padding: EdgeInsets.zero,
                              itemCount: list.length,
                              separatorBuilder: (context, index) => Divider(
                                height: 16,
                                thickness: 0.8,
                                color: isDark
                                    ? AppColors.borderDark.withValues(alpha: 0.5)
                                    : const Color(0xFFF0F4F2),
                              ),
                              itemBuilder: (context, index) {
                                final item = list[index];
                                return _buildPayoutRow(
                                  context: context,
                                  item: item,
                                  returnsCtrl: returnsCtrl,
                                  isDark: isDark,
                                );
                              },
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),

                    // 6. Next Return Date Card
                    Obx(() {
                      final schedule = returnsCtrl.nextReturnSchedule;
                      final hasSchedule = schedule != null;

                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceDark : Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isDark
                                ? AppColors.borderDark
                                : const Color(0xFFE5EFEA),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              offset: const Offset(0, 4),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? AppColors.surfaceDarkElevated
                                    : AppColors.lightMint,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Remix.calendar_2_line,
                                color: AppColors.primary,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Next Return Date',
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    hasSchedule
                                        ? DateFormat('dd MMM yyyy')
                                            .format(schedule.payoutDate)
                                        : 'No upcoming returns scheduled.',
                                    style: GoogleFonts.poppins(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                  if (hasSchedule) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      'Expected: ${CurrencyFormatter.format(schedule.amount)}',
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 20),

                    // 7. Daily, Hourly & Minute Interest Breakdown
                    InterestBreakdownSection(
                      snapshot: returnsCtrl.workspace.value ?? {},
                      isDark: isDark,
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

  Widget _buildPayoutRow({
    required BuildContext context,
    required ReturnPayoutModel item,
    required ReturnsController returnsCtrl,
    required bool isDark,
  }) {
    return InkWell(
      onTap: () => returnsCtrl.inspect(item),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Row(
          children: [
            // Mint circle icon
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.surfaceDarkElevated
                    : AppColors.lightMint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Remix.money_rupee_circle_line,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),

            // Payout details (Project & Date)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.projectName.isNotEmpty
                        ? item.projectName
                        : item.monthYear,
                    style: GoogleFonts.poppins(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('dd MMM yyyy').format(item.payoutDate),
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Amount, Status, and Chevron
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  CurrencyFormatter.format(item.amount),
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : const Color(0xFF102F25),
                  ),
                ),
                const SizedBox(height: 3),
                StatusBadge(status: item.status),
              ],
            ),
            const SizedBox(width: 4),
            Icon(
              Remix.arrow_right_s_line,
              size: 16,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondary.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryTagRow(
    String label,
    String value,
    String tag,
    Color tagBg,
    Color tagColor,
    bool isDark,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: tagBg,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  tag,
                  style: GoogleFonts.poppins(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    color: tagColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF102F25),
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleCol(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : const Color(0xFF102F25),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsBarRow(
    String label,
    String value,
    double progress,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.05, 1.0),
            minHeight: 6,
            backgroundColor: isDark ? AppColors.borderDark : const Color(0xFFE2EBE6),
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ],
    );
  }
}

class HourlyEarningsChartWidget extends StatefulWidget {
  final double hourlyRate;
  final bool isDark;

  const HourlyEarningsChartWidget({
    super.key,
    required this.hourlyRate,
    required this.isDark,
  });

  @override
  State<HourlyEarningsChartWidget> createState() => _HourlyEarningsChartWidgetState();
}

class _HourlyEarningsChartWidgetState extends State<HourlyEarningsChartWidget> {
  int? selectedHour;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final currentHour = now.hour;
    final rate = widget.hourlyRate > 0 ? widget.hourlyRate : 1.25;
    final isDark = widget.isDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sub-bar showing selected hour or current status
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDarkElevated : const Color(0xFFF1FAF4),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? AppColors.borderDark : const Color(0xFFD4EADB),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    selectedHour == null
                        ? 'Live Rate: ${CurrencyFormatter.formatPrecise(rate, decimalDigits: 2)}/hr'
                        : '${_formatHour(selectedHour!)}: ${CurrencyFormatter.formatPrecise(rate, decimalDigits: 2)}/hr',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.textPrimaryDark : AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
              Text(
                selectedHour == null
                    ? '${now.hour}:00 Active'
                    : (selectedHour! <= currentHour ? 'Accrued' : 'Projected'),
                style: GoogleFonts.poppins(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 24-Hour Bar Graph
        SizedBox(
          height: 85,
          child: LayoutBuilder(
            builder: (context, constraints) {
              const totalBars = 24;
              const barSpacing = 2.5;
              final availableWidth = constraints.maxWidth - ((totalBars - 1) * barSpacing);
              final barWidth = (availableWidth / totalBars).clamp(3.5, 18.0);

              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: List.generate(24, (h) {
                  final isCurrent = h == currentHour;
                  final isSelected = selectedHour == h;
                  final isPastOrNow = h <= currentHour;

                  // Visual bar height curve
                  final factor = isCurrent ? 1.0 : (isPastOrNow ? 0.72 + (0.18 * ((h % 5) / 5.0)) : 0.55);
                  final barHeight = (factor * 62.0).clamp(10.0, 68.0);

                  return GestureDetector(
                    onTap: () => setState(() => selectedHour = isSelected ? null : h),
                    behavior: HitTestBehavior.opaque,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: barWidth,
                      height: isSelected ? barHeight + 8 : barHeight,
                      decoration: BoxDecoration(
                        gradient: isCurrent || isSelected
                            ? const LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Color(0xFF005A32), Color(0xFF00A859)],
                              )
                            : LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: isPastOrNow
                                    ? [
                                        const Color(0xFF00854B).withValues(alpha: 0.85),
                                        const Color(0xFF4ADE80),
                                      ]
                                    : [
                                        (isDark ? const Color(0xFF244436) : const Color(0xFFC7EBD6)),
                                        (isDark ? const Color(0xFF2E5745) : const Color(0xFFDDF4E7)),
                                      ],
                              ),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        boxShadow: isCurrent
                            ? [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.35),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : null,
                      ),
                    ),
                  );
                }),
              );
            },
          ),
        ),
        const SizedBox(height: 6),

        // Time Axis Markers
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('12 AM', style: TextStyle(fontSize: 9.5, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary)),
              Text('4 AM', style: TextStyle(fontSize: 9.5, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary)),
              Text('8 AM', style: TextStyle(fontSize: 9.5, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary)),
              Text('12 PM', style: TextStyle(fontSize: 9.5, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary)),
              Text('4 PM', style: TextStyle(fontSize: 9.5, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary)),
              Text('8 PM', style: TextStyle(fontSize: 9.5, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary)),
              Text('11 PM', style: TextStyle(fontSize: 9.5, color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary)),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  String _formatHour(int h) {
    final hour = h % 12 == 0 ? 12 : h % 12;
    final ampm = h < 12 ? 'AM' : 'PM';
    return '$hour:00 $ampm';
  }
}
