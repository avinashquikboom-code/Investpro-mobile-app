import 'package:flutter/material.dart';

import '../models/transaction_model.dart';
import '../theme/app_colors.dart';
import '../utils/currency_formatter.dart';
import '../utils/date_formatter.dart';
import 'status_badge.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;

  const TransactionTile({super.key, required this.transaction, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    IconData icon;
    Color iconColor;
    Color iconBg;
    bool isCredit = false;

    switch (transaction.type) {
      case TransactionType.returnReceived:
        icon = Icons.arrow_upward_rounded;
        iconColor = AppColors.success;
        iconBg = AppColors.successLight;
        isCredit = true;
        break;
      case TransactionType.deposit:
        icon = Icons.add_rounded;
        iconColor = AppColors.success;
        iconBg = AppColors.successLight;
        isCredit = true;
        break;
      case TransactionType.withdrawal:
        icon = Icons.arrow_downward_rounded;
        iconColor = AppColors.error;
        iconBg = AppColors.errorLight;
        break;
      case TransactionType.investment:
        icon = Icons.business_center_rounded;
        iconColor = AppColors.primary;
        iconBg = const Color(0xFFE8F2EC);
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 1,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        title: Text(
          transaction.title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(
              '${DateFormatter.formatDate(transaction.date)}  •  ${transaction.subtitle}',
              style: TextStyle(
                fontSize: 12,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${isCredit ? "+ " : ""}${CurrencyFormatter.format(transaction.amount)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isCredit
                    ? AppColors.success
                    : (transaction.type == TransactionType.withdrawal
                          ? AppColors.error
                          : (isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary)),
              ),
            ),
            const SizedBox(height: 3),
            StatusBadge(status: transaction.status),
          ],
        ),
      ),
    );
  }
}
