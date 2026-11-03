import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remixicon/remixicon.dart';

import '../../controllers/transaction_controller.dart';
import '../../models/transaction_model.dart';
import '../../services/demo_repository.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/transaction_tile.dart';

/// Screen 6 – Transaction History
/// Displays filter tabs (All, Investment, Return, Withdrawal),
/// summary KPI card (Total Invested, Returns Received, Pending Return),
/// and transaction list with signed amounts, real statuses, and detail sheet.
class TransactionHistoryView extends StatelessWidget {
  const TransactionHistoryView({super.key});

  void _showTransactionDetails(BuildContext context, TransactionModel txn) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.bottomSheet(
      SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.borderDark
                          : const Color(0xFFD4E0D9),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        txn.title,
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    StatusBadge(status: txn.status),
                  ],
                ),
                const SizedBox(height: 16),
                _buildDetailItem(
                  'Amount',
                  CurrencyFormatter.format(txn.amount),
                  isBold: true,
                  isDark: isDark,
                ),
                const Divider(height: 20, color: AppColors.border),
                _buildDetailItem(
                  'Date & Time',
                  DateFormatter.formatDateTime(txn.date),
                  isDark: isDark,
                ),
                const Divider(height: 20, color: AppColors.border),
                if (txn.projectName != null && txn.projectName!.isNotEmpty) ...[
                  _buildDetailItem('Project', txn.projectName!, isDark: isDark),
                  const Divider(height: 20, color: AppColors.border),
                ],
                _buildDetailItem('Category', txn.subtitle, isDark: isDark),
                const Divider(height: 20, color: AppColors.border),
                _buildDetailItem(
                  'Transaction Reference',
                  txn.referenceId,
                  isCode: true,
                  isDark: isDark,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => Get.back(),
                    child: const Text('Close'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
    );
  }

  Widget _buildDetailItem(
    String label,
    String value, {
    bool isBold = false,
    bool isCode = false,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            color:
                isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: isCode
                ? TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  )
                : GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
                    color: isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
                  ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final txnCtrl = Get.find<TransactionController>();
    final repo = Get.find<DemoRepository>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filterTabs = ['All', 'Investment', 'Return', 'Withdrawal'];

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: CustomAppBar(title: 'transactionHistory'.tr),
      body: SafeArea(
        child: ResponsiveHelper.responsiveContainer(
          context: context,
          maxWidth: 640,
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: repo.syncFromBackend,
            child: Obx(() {
              // Derive summary metrics from real repository data
              double totalInvested = 0;
              double returnsReceived = 0;
              double pendingReturns = 0;

              for (final inv in repo.investments) {
                if (['active', 'completed'].contains(inv.status.toLowerCase())) {
                  totalInvested += inv.investedAmount;
                  if (inv.status.toLowerCase() == 'active') {
                    pendingReturns += inv.expectedReturn;
                  }
                }
              }

              for (final txn in repo.transactions) {
                if (txn.type == TransactionType.returnReceived &&
                    txn.status.toLowerCase() == 'completed') {
                  returnsReceived += txn.amount;
                }
              }

              // Net pending return calculation
              if (returnsReceived < pendingReturns) {
                pendingReturns = pendingReturns - returnsReceived;
              } else if (returnsReceived > 0 && pendingReturns > 0) {
                pendingReturns = 0;
              }

              final list = txnCtrl.filteredTransactions;

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // 1. Transaction Summary KPI Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF003B2D), Color(0xFF005A3E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF003B2D)
                                  .withValues(alpha: 0.25),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TRANSACTION SUMMARY',
                              style: GoogleFonts.poppins(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.9,
                                color: const Color(0xFFB4E0CA),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                _buildSummaryKpiColumn(
                                  label: 'Total Invested',
                                  value:
                                      CurrencyFormatter.format(totalInvested),
                                  valueColor: Colors.white,
                                ),
                                Container(
                                  width: 1,
                                  height: 32,
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                                _buildSummaryKpiColumn(
                                  label: 'Returns Received',
                                  value:
                                      CurrencyFormatter.format(returnsReceived),
                                  valueColor: const Color(0xFF4ADE80),
                                ),
                                Container(
                                  width: 1,
                                  height: 32,
                                  color: Colors.white.withValues(alpha: 0.2),
                                ),
                                _buildSummaryKpiColumn(
                                  label: 'Pending Return',
                                  value:
                                      CurrencyFormatter.format(pendingReturns),
                                  valueColor: const Color(0xFFB4E0CA),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 2. Filter Tabs (All, Investment, Return, Withdrawal)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: filterTabs.map((filter) {
                            final isSelected =
                                txnCtrl.selectedFilter.value == filter;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => txnCtrl.setFilter(filter),
                                child: AnimatedContainer(
                                  duration:
                                      const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 18,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : (isDark
                                            ? AppColors.surfaceDark
                                            : Colors.white),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : (isDark
                                              ? AppColors.borderDark
                                              : AppColors.border),
                                      width: 1,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.25),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Text(
                                    filter,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.5,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
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
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),

                  // 3. Transactions List
                  if (list.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyStateWidget(
                        icon: Remix.file_list_3_line,
                        title: 'No Transactions Found',
                        message: txnCtrl.selectedFilter.value == 'All'
                            ? 'You have no recorded transactions yet.'
                            : 'No ${txnCtrl.selectedFilter.value.toLowerCase()} transactions found in this category.',
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final txn = list[index];
                            return TransactionTile(
                              transaction: txn,
                              onTap: () =>
                                  _showTransactionDetails(context, txn),
                            );
                          },
                          childCount: list.length,
                        ),
                      ),
                    ),
                  const SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryKpiColumn({
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: const Color(0xFFB4E0CA),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
