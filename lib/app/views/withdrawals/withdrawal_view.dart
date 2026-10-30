import '../../widgets/unsaved_changes_guard.dart';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/withdrawal_controller.dart';
import '../../services/demo_repository.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/transaction_tile.dart';

class WithdrawalView extends StatelessWidget {
  const WithdrawalView({super.key});

  void _showWithdrawModal(
    BuildContext context,
    WithdrawalController controller,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Reset amount
    controller.amountController.clear();
    controller.bankSelected.value = true;

    Get.bottomSheet(
      UnsavedChangesGuard(
        controllers: [controller.amountController],
        changes: [controller.bankSelected.stream],
        snapshot: () => controller.bankSelected.value,
        child: Container(
          padding: EdgeInsets.fromLTRB(
            24,
            20,
            24,
            24 + MediaQuery.viewInsetsOf(Get.context!).bottom,
          ),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
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
                  const SizedBox(height: 18),
                  Text(
                    'Withdraw Funds',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Obx(() {
                    return Text(
                      'Available balance: ${CurrencyFormatter.format(controller.availableBalance)}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  }),
                  const SizedBox(height: 18),

                  // Amount Field
                  CustomTextField(
                    controller: controller.amountController,
                    label: 'Withdrawal Amount',
                    hintText: 'Enter amount (e.g. 5000)',
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    prefixIcon: const Padding(
                      padding: EdgeInsets.only(left: 14, right: 8),
                      child: Text(
                        '₹',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Quick Percentage Chips
                  Obx(() {
                    final balance = controller.availableBalance;
                    if (balance <= 0) return const SizedBox.shrink();
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _quickChip(controller, '25%', balance * 0.25),
                        _quickChip(controller, '50%', balance * 0.50),
                        _quickChip(controller, '75%', balance * 0.75),
                        _quickChip(controller, 'MAX', balance),
                      ],
                    );
                  }),
                  const SizedBox(height: 16),

                  // Verified Bank Account Section
                  Text(
                    'Target Bank Account',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(() {
                    final hasBank = controller.hasVerifiedBank;
                    final bankName = controller.linkedBankName;
                    final accountNumber = controller.linkedAccountNumber;

                    if (!hasBank) {
                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.surfaceDarkElevated
                              : const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.warning,
                            width: 1,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: AppColors.warning,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Verified bank account required',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Please link and verify a bank account in your Profile before withdrawing.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceDarkElevated
                            : const Color(0xFFF3F8F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : const Color(0xFFD1EBDD),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.account_balance_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  bankName.isNotEmpty ? bankName : 'Primary Bank',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  accountNumber.isNotEmpty
                                      ? accountNumber
                                      : '•••• ••••',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE7F7EE),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF00854B),
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Verified',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF00854B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),

                  // Limits & Net Payout Summary Card
                  Obx(() {
                    final minAmt = controller.minimumWithdrawal.value;
                    final maxAmt = controller.maximumWithdrawal.value;
                    final fee = controller.withdrawalFee.value;
                    final net = controller.netPayoutAmount.value;

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : const Color(0xFFF9FBFA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : const Color(0xFFE1ECE5),
                        ),
                      ),
                      child: Column(
                        children: [
                          _summaryRow(
                            'Minimum limit',
                            '₹ ${minAmt.toStringAsFixed(minAmt.truncateToDouble() == minAmt ? 0 : 2)}',
                            isDark,
                          ),
                          const SizedBox(height: 6),
                          _summaryRow(
                            'Maximum limit',
                            maxAmt != null
                                ? '₹ ${maxAmt.toStringAsFixed(maxAmt.truncateToDouble() == maxAmt ? 0 : 2)}'
                                : 'No ceiling',
                            isDark,
                          ),
                          const SizedBox(height: 6),
                          _summaryRow(
                            'Applicable fee',
                            fee > 0 ? CurrencyFormatter.format(fee) : '₹ 0.00 (Zero fee)',
                            isDark,
                          ),
                          const Divider(height: 16, color: Color(0xFFE1ECE5)),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Net payout amount',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                CurrencyFormatter.format(net),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 20),

                  // Submit Button
                  Obx(() {
                    final canSubmit =
                        controller.availableBalance > 0 && controller.hasVerifiedBank;
                    return CustomButton(
                      text: 'Confirm Withdrawal',
                      isLoading: controller.isSubmitting.value,
                      onPressed: canSubmit
                          ? () async {
                              final ok = await controller.submitWithdrawal();
                              if (ok && Navigator.of(Get.context!).canPop()) {
                                Navigator.of(Get.context!).pop();
                              }
                            }
                          : null,
                    );
                  }),
                  const SizedBox(height: 10),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        if (Navigator.of(Get.context!).canPop()) {
                          Navigator.of(Get.context!).pop();
                        }
                      },
                      child: const Text('Cancel'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      isScrollControlled: true,
      isDismissible: true,
      enableDrag: true,
    );
  }

  Widget _quickChip(WithdrawalController ctrl, String label, double amount) {
    return InkWell(
      onTap: () {
        ctrl.amountController.text = amount.toStringAsFixed(0);
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F5F2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFD1EBDD)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Color(0xFF00854B),
          ),
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final withCtrl = Get.find<WithdrawalController>();
    final demoRepo = Get.find<DemoRepository>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filterTabs = ['All', 'Withdrawals', 'Deposits'];

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: CustomAppBar(title: 'withdrawalRequest'.tr),
      body: SafeArea(
        child: ResponsiveHelper.responsiveContainer(
          context: context,
          maxWidth: 600,
          child: RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              await Future.wait([
                withCtrl.loadWalletData(),
                demoRepo.syncFromBackend().catchError((_) {}),
              ]);
            },
            child: Column(
              children: [
                // Available Balance Card
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
                  child: Container(
                    width: double.infinity,
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
                          color: Colors.black.withValues(alpha: 0.02),
                          offset: const Offset(0, 2),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'availableBalance'.tr,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Obx(() {
                                return FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    CurrencyFormatter.format(
                                      withCtrl.availableBalance,
                                    ),
                                    style: TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimary,
                                    ),
                                  ),
                                );
                              }),
                              Obx(() {
                                if (withCtrl.reservedBalance > 0) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(
                                      '${CurrencyFormatter.format(withCtrl.reservedBalance)} reserved',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.warning,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  );
                                }
                                return const SizedBox.shrink();
                              }),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Withdraw Button
                        Obx(() {
                          final hasBalance = withCtrl.availableBalance > 0;
                          return ElevatedButton(
                            onPressed: () {
                              if (!hasBalance) {
                                Get.snackbar(
                                  'Zero Balance',
                                  'Available balance is ₹ 0.00. Returns and deposits must be credited before requesting a withdrawal.',
                                  snackPosition: SnackPosition.BOTTOM,
                                );
                                return;
                              }
                              _showWithdrawModal(context, withCtrl);
                            },
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                              backgroundColor:
                                  hasBalance ? AppColors.primary : Colors.grey.shade400,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 22,
                                vertical: 10,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(
                              'withdraw'.tr,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),

                // Withdrawal Information Notice Banner
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5FAF7),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE1ECE5)),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: Color(0xFF00854B),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Withdrawal requests reserve funds atomically. Admin approvals and bank settlements are processed securely by the accounts team.',
                            style: TextStyle(
                              fontSize: 11,
                              color: Color(0xFF2C5E47),
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Transaction History Section Header & Filter Pills
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'transactionHistory'.tr,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Obx(() {
                        return Row(
                          children: filterTabs.map((filter) {
                            final isSelected =
                                withCtrl.selectedFilter.value == filter;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(
                                  filter == 'All'
                                      ? 'all'.tr
                                      : filter == 'Withdrawals'
                                          ? 'withdrawals'.tr
                                          : 'deposits'.tr,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                    color: isSelected
                                        ? Colors.white
                                        : (isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondary),
                                  ),
                                ),
                                selected: isSelected,
                                selectedColor: AppColors.primary,
                                backgroundColor: isDark
                                    ? AppColors.surfaceDark
                                    : const Color(0xFFF3F4F6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isSelected
                                        ? AppColors.primary
                                        : (isDark
                                            ? AppColors.borderDark
                                            : Colors.transparent),
                                  ),
                                ),
                                onSelected: (_) => withCtrl.setFilter(filter),
                              ),
                            );
                          }).toList(),
                        );
                      }),
                    ],
                  ),
                ),

                // Transactions List
                Expanded(
                  child: Obx(() {
                    final txns = withCtrl.filteredTransactions;

                    if (txns.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          const SizedBox(height: 60),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.receipt_long_outlined,
                                  size: 48,
                                  color: isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'noTransactions'.tr,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: txns.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        return TransactionTile(transaction: txns[index]);
                      },
                    );
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
