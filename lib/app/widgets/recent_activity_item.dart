import 'package:remixicon/remixicon.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../models/transaction_model.dart';
import '../theme/app_colors.dart';
import '../utils/currency_formatter.dart';
import 'status_badge.dart';

class RecentActivityItem extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;

  const RecentActivityItem({
    super.key,
    required this.transaction,
    this.onTap,
  });

  IconData _getIcon() {
    switch (transaction.type) {
      case TransactionType.returnReceived:
      case TransactionType.deposit:
        return Remix.arrow_down_line;
      case TransactionType.withdrawal:
        return Remix.wallet_3_line;
      case TransactionType.investment:
        return Remix.arrow_up_line;
      case TransactionType.refund:
        return Remix.restart_line;
      case TransactionType.fee:
        return Remix.receipt_line;
    }
  }

  Color _getIconColor() {
    switch (transaction.type) {
      case TransactionType.returnReceived:
      case TransactionType.deposit:
      case TransactionType.refund:
        return AppColors.success;
      case TransactionType.withdrawal:
        return AppColors.warning;
      case TransactionType.investment:
      case TransactionType.fee:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCredit = transaction.direction.toUpperCase() == 'CREDIT' ||
        transaction.type == TransactionType.returnReceived ||
        transaction.type == TransactionType.deposit ||
        transaction.type == TransactionType.refund;

    final dateString = DateFormat('dd MMM yyyy, hh:mm a').format(transaction.date);
    final iconColor = _getIconColor();

    return Material(
      color: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 1,
        ),
      ),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.primary.withValues(alpha: 0.08),
        highlightColor: AppColors.primary.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              // Circular icon
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: isDark ? 0.2 : 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getIcon(),
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Title & Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction.title,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      dateString,
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Amount & Status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isCredit ? '+' : '-'} ${CurrencyFormatter.format(transaction.amount)}',
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isCredit
                          ? AppColors.success
                          : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 4),
                  StatusBadge(status: transaction.status),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

