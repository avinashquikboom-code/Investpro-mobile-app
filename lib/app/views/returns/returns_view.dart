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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final periodTabs = ['Monthly', 'Quarterly', 'Yearly'];

    return AppSystemUi(
      statusSurface: isDark ? AppColors.backgroundDark : AppColors.background,
      child: Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
        appBar: !isTab
            ? CustomAppBar(
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

                    // 3. Returns Period Filters (Monthly, Quarterly, Yearly)
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
}
