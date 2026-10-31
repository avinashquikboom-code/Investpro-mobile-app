import '../../widgets/record_id.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/transaction_controller.dart';
import '../../models/transaction_model.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/transaction_tile.dart';

class TransactionHistoryView extends StatelessWidget {
  const TransactionHistoryView({super.key});

  void _showTransactionDetails(BuildContext context, TransactionModel txn) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RecordId(label: 'Transaction ID', value: txn.id),
              RecordIds(values: Map.of(txn.recordIds)..remove('id')),
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
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      txn.title,
                      style: TextStyle(
                        fontSize: 18,
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
              ),
              const Divider(height: 20, color: AppColors.border),
              _buildDetailItem(
                'Date & Time',
                DateFormatter.formatDateTime(txn.date),
              ),
              const Divider(height: 20, color: AppColors.border),
              if (txn.projectName != null && txn.projectName!.isNotEmpty) ...[
                _buildDetailItem('Project', txn.projectName!),
                const Divider(height: 20, color: AppColors.border),
              ],
              _buildDetailItem('Category', txn.subtitle),
              const Divider(height: 20, color: AppColors.border),
              _buildDetailItem(
                'Transaction Reference',
                txn.referenceId,
                isCode: true,
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
    );
  }

  Widget _buildDetailItem(
    String label,
    String value, {
    bool isBold = false,
    bool isCode = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        const SizedBox(width: 16),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
              fontFamily: isCode ? 'monospace' : null,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final txnCtrl = Get.find<TransactionController>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filterTabs = ['All', 'Investment', 'Return', 'Withdrawal'];

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: CustomAppBar(title: 'transactionHistory'.tr),
      body: SafeArea(
        child: ResponsiveHelper.responsiveContainer(
          context: context,
          maxWidth: 600,
          child: Column(
            children: [
              // Filter Tabs (All, Investment, Return, Withdrawal)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Obx(() {
                  return SingleChildScrollView(
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
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primaryDark
                                    : (isDark
                                          ? AppColors.surfaceDark
                                          : Colors.white),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primaryDark
                                      : (isDark
                                            ? AppColors.borderDark
                                            : AppColors.border),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                filter,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
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
                  );
                }),
              ),

              // Transactions List
              Expanded(
                child: Obx(() {
                  final list = txnCtrl.filteredTransactions;
                  if (list.isEmpty) {
                    return const Center(child: Text('No transactions found'));
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: list.length,
                    itemBuilder: (context, index) {
                      final txn = list[index];
                      return TransactionTile(
                        transaction: txn,
                        onTap: () => _showTransactionDetails(context, txn),
                      );
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
