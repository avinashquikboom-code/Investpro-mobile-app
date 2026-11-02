import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remixicon/remixicon.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';

class MonthlyPayoutScheduleCard extends StatelessWidget {
  final List<Map<String, dynamic>> schedules;
  const MonthlyPayoutScheduleCard({super.key, required this.schedules});

  String money(dynamic value) => CurrencyFormatter.format(
    num.tryParse('$value') ?? 0,
    showDecimals: true,
  );

  String date(dynamic value) {
    final parsed = DateTime.tryParse('$value');
    return parsed == null ? '—' : DateFormatter.formatDate(parsed.toUtc());
  }

  String status(Map<String, dynamic> item) {
    switch (item['status']) {
      case 'PAID':
        return 'Paid';
      case 'FAILED':
        return 'Failed';
      case 'PROCESSING':
        return 'Processing';
      case 'SCHEDULED':
        final due = DateTime.tryParse('${item['dueDate']}');
        return due != null && due.isAfter(DateTime.now()) ? 'Upcoming' : 'Pending';
      case 'PENDING':
        return 'Pending';
      default:
        return '${item['status']}';
    }
  }

  Color statusColor(String st, bool isDark) {
    switch (st) {
      case 'Paid':
        return isDark ? const Color(0xFF34D399) : const Color(0xFF059669);
      case 'Upcoming':
        return AppColors.primary;
      case 'Processing':
        return const Color(0xFFF59E0B);
      case 'Failed':
        return const Color(0xFFEF4444);
      case 'Pending':
      default:
        return const Color(0xFFD97706);
    }
  }

  Color statusBgColor(String st, bool isDark) {
    switch (st) {
      case 'Paid':
        return const Color(0xFF10B981).withValues(alpha: 0.12);
      case 'Upcoming':
        return AppColors.primary.withValues(alpha: 0.12);
      case 'Processing':
        return const Color(0xFFF59E0B).withValues(alpha: 0.12);
      case 'Failed':
        return const Color(0xFFEF4444).withValues(alpha: 0.12);
      case 'Pending':
      default:
        return const Color(0xFFFEF3C7);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.surfaceDark : Colors.white;
    final ink = isDark ? AppColors.textPrimaryDark : const Color(0xFF14271F);

    return Material(
      color: surface,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.borderDark : const Color(0xFFE8F0EB),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.035),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: false,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            leading: Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Remix.calendar_event_line,
                color: AppColors.primary,
                size: 20,
              ),
            ),
            title: Text(
              'Monthly payout schedule',
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w700,
                fontSize: 14.5,
                color: ink,
              ),
            ),
            subtitle: Text(
              'Interest each month; principal in the final payment',
              style: GoogleFonts.poppins(
                fontSize: 11.5,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (schedules.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '${schedules.length} payouts',
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                const SizedBox(width: 4),
                Icon(
                  Remix.arrow_down_s_line,
                  size: 20,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
              ],
            ),
            children: [
              const Divider(height: 1),
              const SizedBox(height: 14),
              if (schedules.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDarkElevated : const Color(0xFFF8FAF9),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Remix.information_line, size: 18, color: AppColors.textSecondary),
                      const SizedBox(width: 8),
                      Text(
                        'No monthly payouts scheduled',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              for (final item in schedules) ...[
                _buildScheduleCard(item, isDark, ink),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDarkElevated : const Color(0xFFF8FAF9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : const Color(0xFFE5EDE8),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Remix.shield_check_line,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Scheduled payouts are projections. Only successfully confirmed payouts are credited and available to withdraw.',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleCard(Map<String, dynamic> item, bool isDark, Color ink) {
    final st = status(item);
    final principalNum = num.tryParse("${item['principalAmount']}") ?? 0;
    final isFinalMaturity = principalNum > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDarkElevated : const Color(0xFFF7FAF8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isFinalMaturity
              ? (isDark ? const Color(0xFFF59E0B).withValues(alpha: 0.4) : const Color(0xFFFCD34D))
              : (isDark ? AppColors.borderDark : const Color(0xFFE2EBE5)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Installment / Maturity Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isFinalMaturity
                      ? const Color(0xFFFEF3C7)
                      : AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isFinalMaturity) ...[
                      const Icon(Remix.vip_crown_line, size: 12, color: Color(0xFFD97706)),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      '${item['projectName']} • ${isFinalMaturity ? 'Final maturity payout' : 'Month ${item['installmentNumber']}'}',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: isFinalMaturity ? const Color(0xFFD97706) : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBgColor(st, isDark),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  st,
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: statusColor(st, isDark),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Remix.calendar_line, size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 5),
              Text(
                date(item['dueDate']),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.borderDark : const Color(0xFFE8EEEC),
              ),
            ),
            child: Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                Text(
                  'Interest: ${money(item['profitAmount'])}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: ink,
                  ),
                ),
                Text(
                  'Principal: ${money(item['principalAmount'])}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isFinalMaturity ? const Color(0xFFD97706) : ink,
                  ),
                ),
                Text(
                  'Total payment: ${money(item['totalAmount'])}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
