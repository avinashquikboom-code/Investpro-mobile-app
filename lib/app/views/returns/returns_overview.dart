import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';

import '../../controllers/returns_controller.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/returns_bar_chart.dart';
import '../../widgets/status_badge.dart';

/// Presentation of the existing, authorized server snapshot. Never adds principal to profit.
class ReturnsOverview extends StatelessWidget {
  final Map<String, dynamic> snapshot;
  final String period;
  final ValueChanged<String> onPeriod;
  const ReturnsOverview({
    super.key,
    required this.snapshot,
    required this.period,
    required this.onPeriod,
  });
  static double number(dynamic value) => double.tryParse('$value') ?? 0;
  static String money(dynamic value) =>
      CurrencyFormatter.format(number(value), showDecimals: true);
  static List<Map<String, dynamic>> rows(
    Map<String, dynamic> data,
    String key,
  ) => (data[key] as List? ?? [])
      .whereType<Map>()
      .map((v) => Map<String, dynamic>.from(v))
      .toList();
  static String date(dynamic value) {
    final parsed = DateTime.tryParse('$value');
    return parsed == null
        ? 'Not available'
        : DateFormat('dd MMM yyyy').format(parsed.toLocal());
  }

  static String payoutStatus(Map<String, dynamic> row) {
    // The existing /returns overview only includes successful PAID wallet credits.
    return switch ('${row['status'] ?? 'SUCCESS'}'.toUpperCase()) {
      'SUCCESS' || 'PAID' || 'COMPLETED' => 'Completed',
      'PROCESSING' => 'Processing',
      'FAILED' || 'REJECTED' => 'Failed',
      _ => 'Pending',
    };
  }

  static String? comparison(Map<String, dynamic> data) {
    final list = rows(data, 'analytics');
    if (list.length < 2) return null;
    final previous = number(list[list.length - 2]['amount']);
    if (previous <= 0) return null;
    final change = (number(list.last['amount']) - previous) / previous * 100;
    return '${change >= 0 ? '+' : ''}${change.toStringAsFixed(1)}%';
  }

  static Map<String, dynamic>? nextReturn(Map<String, dynamic> data) {
    final now = DateTime.tryParse('${data['asOf']}') ?? DateTime.now();
    final upcoming =
        rows(data, 'upcoming').where((r) {
          final due = DateTime.tryParse('${r['dueDate']}');
          return due != null &&
              due.isAfter(now) &&
              ['SCHEDULED', 'PENDING'].contains('${r['status']}'.toUpperCase());
        }).toList()..sort(
          (a, b) =>
              DateTime.parse('${a['dueDate']}')
                  .compareTo(DateTime.parse('${b['dueDate']}')),
        );
    return upcoming.firstOrNull;
  }

  void details(Map<String, dynamic> payout) {
    Get.dialog(
      AlertDialog(
        title: const Text('Return Details'),
        content: SizedBox(
          width: 440,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final entry in <(String, String)>[
                  ('Project', '${payout['projectName'] ?? 'Not available'}'),
                  (
                    'Investment reference',
                    '${payout['investmentReference'] ?? 'Not provided by server'}',
                  ),
                  ('Return amount', money(payout['profitAmount'])),
                  ('Scheduled date', date(payout['dueDate'])),
                  ('Payment date', date(payout['date'])),
                  ('Payment status', payoutStatus(payout)),
                  if (payout['reference'] != null)
                    ('Transaction reference', '${payout['reference']}'),
                  if (number(payout['principalAmount']) > 0)
                    (
                      'Principal returned separately',
                      money(payout['principalAmount']),
                    ),
                ])
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.$1,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        SelectableText(entry.$2),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final summary = Map<String, dynamic>.from(
      snapshot['summary'] as Map? ?? {},
    );
    final growth = comparison(snapshot);
    final next = nextReturn(snapshot);
    final payouts = rows(snapshot, 'payouts');
    final points = rows(snapshot, 'analytics')
        .where((r) => DateTime.tryParse('${r['date']}') != null)
        .map((r) {
          final rawDate = '${r['date']}';
          final d = DateTime.parse(
            rawDate.length == 10 ? '${rawDate}T00:00:00Z' : rawDate,
          ).toUtc();
          return ReturnChartPoint(
            label: period == 'Monthly'
                ? DateFormat('MMM').format(d)
                : '${r['label']}',
            amount: number(r['amount']),
            date: d,
          );
        })
        .toList();
    final surface = dark ? AppColors.surfaceDark : Colors.white;
    final ink = dark ? AppColors.textPrimaryDark : const Color(0xFF14271F);
    Widget card(Widget child, {bool mint = false}) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: mint ? null : surface,
        gradient: mint
            ? LinearGradient(
                colors: dark
                    ? [surface, AppColors.surfaceDarkElevated]
                    : [Colors.white, const Color(0xFFF0FBF4)],
              )
            : null,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: dark ? AppColors.borderDark : const Color(0xFFE8F0EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .035),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
    Widget circle(IconData icon) => Container(
      padding: const EdgeInsets.all(11),
      decoration: const BoxDecoration(
        color: AppColors.lightMint,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: AppColors.primary, size: 22),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        card(
          LayoutBuilder(
            builder: (context, c) {
              final graphic =
                  c.maxWidth > 290 &&
                  MediaQuery.textScalerOf(context).scale(1) < 1.5;
              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Returns',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          money(summary['totalEarnedReturns']),
                          key: const ValueKey('total-earned-returns'),
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.8,
                            color: ink,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 7,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: growth == null
                                    ? (dark
                                          ? AppColors.surfaceDarkElevated
                                          : const Color(0xFFF0F3F1))
                                    : AppColors.lightMint,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                growth ?? '—',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: growth?.startsWith('-') == true
                                      ? AppColors.error
                                      : AppColors.primary,
                                ),
                              ),
                            ),
                            Text(
                              growth == null
                                  ? 'No previous period comparison'
                                  : 'vs last period',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (graphic)
                    const Padding(
                      padding: EdgeInsets.only(left: 12),
                      child: _GrowthGraphic(),
                    ),
                ],
              );
            },
          ),
          mint: true,
        ),
        const SizedBox(height: 22),
        Row(
          children: [
            for (final p in ['Monthly', 'Quarterly', 'Yearly'])
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: p == 'Yearly' ? 0 : 8),
                  child: Semantics(
                    selected: period == p,
                    button: true,
                    child: InkWell(
                      onTap: () => onPeriod(p),
                      borderRadius: BorderRadius.circular(28),
                      child: Container(
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(
                          vertical: 13,
                          horizontal: 3,
                        ),
                        decoration: BoxDecoration(
                          color: period == p ? null : surface,
                          gradient: period == p
                              ? AppColors.primaryGradient
                              : null,
                          borderRadius: BorderRadius.circular(28),
                          border: Border.all(
                            color: period == p
                                ? Colors.transparent
                                : (dark
                                      ? AppColors.borderDark
                                      : AppColors.border),
                          ),
                          boxShadow: period == p
                              ? [
                                  BoxShadow(
                                    color: AppColors.primary.withValues(
                                      alpha: .15,
                                    ),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : null,
                        ),
                        child: Text(
                          p,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: period == p ? Colors.white : ink,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 20),
        ReturnsBarChart(
          points: points,
          period: '${snapshot['period'] ?? period}'.capitalizeFirst ?? period,
          isDark: dark,
        ),
        const SizedBox(height: 20),
        card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Payout History',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: ink,
                ),
              ),
              const SizedBox(height: 12),
              if (payouts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text('No returns yet')),
                ),
              for (var i = 0; i < payouts.length; i++) ...[
                if (i > 0) const Divider(height: 24, color: AppColors.divider),
                InkWell(
                  key: ValueKey('payout-${payouts[i]['id'] ?? i}'),
                  onTap: () => details(payouts[i]),
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final compact =
                            c.maxWidth < 310 ||
                            MediaQuery.textScalerOf(context).scale(1) > 1.4;
                        final p = payouts[i];
                        final amount = Text(
                          '${payoutStatus(p) == 'Completed' ? '+ ' : ''}${money(p['profitAmount'])}',
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        );
                        return Row(
                          children: [
                            circle(Remix.money_rupee_circle_line),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    date(p['date']),
                                    style: TextStyle(
                                      color: ink,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  StatusBadge(status: payoutStatus(p)),
                                  if (compact)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8),
                                      child: amount,
                                    ),
                                ],
                              ),
                            ),
                            if (!compact) ...[
                              const SizedBox(width: 8),
                              Flexible(child: amount),
                            ],
                            const Icon(
                              Remix.arrow_right_s_line,
                              size: 19,
                              color: AppColors.textSecondary,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        card(
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              circle(Remix.calendar_2_line),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Next Return Date',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      next == null
                          ? 'No upcoming returns scheduled'
                          : date(next['dueDate']),
                      style: TextStyle(
                        color: ink,
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (next != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Expected Amount: ${money(next['profitAmount'])}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GrowthGraphic extends StatelessWidget {
  const _GrowthGraphic();
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: 88,
      height: 100,
      decoration: BoxDecoration(
        color: AppColors.lightMint.withValues(alpha: .8),
        borderRadius: BorderRadius.circular(34),
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
      child: Stack(
        children: [
          const Positioned(
            top: 0,
            right: 0,
            child: Icon(
              Remix.arrow_right_up_line,
              color: AppColors.primary,
              size: 27,
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                for (final h in [25.0, 40.0, 56.0])
                  Container(
                    width: 14,
                    height: h,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [AppColors.primary, AppColors.accent],
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
