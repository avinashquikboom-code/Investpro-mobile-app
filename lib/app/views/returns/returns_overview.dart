import '../../widgets/next_hourly_payout_card.dart';
import '../../utils/display_value.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
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
  final bool payoutLoading, payoutError;
  final bool payoutActive;
  final Key? payoutIndicatorKey;
  final ValueChanged<String> onPeriod;
  final DateTime? selectedDate;
  final ValueChanged<DateTime>? onDate;
  const ReturnsOverview({
    super.key,
    required this.snapshot,
    required this.period,
    this.payoutLoading = false,
    this.payoutError = false,
    this.payoutActive = true,
    this.payoutIndicatorKey,
    required this.onPeriod,
    this.selectedDate,
    this.onDate,
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
    return switch ('${row['status'] ?? ''}'.toUpperCase()) {
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

  static String time(dynamic value) {
    final parsed = DateTime.tryParse('$value');
    return parsed == null ? 'Not available' : DateFormat('dd MMM yyyy, hh:mm a').format(parsed.toLocal());
  }

  static String shortTime(dynamic value) {
    final parsed = DateTime.tryParse('$value');
    if (parsed == null) return '—';
    final local = parsed.toLocal();
    final now = DateTime.now();
    final isToday = local.year == now.year && local.month == now.month && local.day == now.day;
    if (isToday) {
      return DateFormat('hh:mm a').format(local);
    }
    return DateFormat('dd MMM, hh:mm a').format(local);
  }

  static Map<String, dynamic>? nextReturn(Map<String, dynamic> data) {
    final now = DateTime.tryParse('${data['asOf']}') ?? DateTime.now();
    final upcoming =
        rows(data, 'upcoming').where((r) {
          final due = DateTime.tryParse('${r['dueDate']}');
          return due != null &&
              due.isAfter(data['period'] == 'hourly' ? DateTime.now() : now) &&
              ['SCHEDULED', 'PENDING', 'OVERDUE'].contains('${r['status']}'.toUpperCase());
        }).toList()..sort(
          (a, b) =>
              DateTime.parse('${a['dueDate']}')
                  .compareTo(DateTime.parse('${b['dueDate']}')),
        );
    return upcoming.firstOrNull;
  }

  void _showAllHourlyQueueModal(
    BuildContext context,
    List<Map<String, dynamic>> upcoming,
  ) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? AppColors.surfaceDark : Colors.white;
    final ink = dark ? AppColors.textPrimaryDark : const Color(0xFF14271F);

    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Upcoming Hourly Payouts',
                        style: GoogleFonts.poppins(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: ink,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${upcoming.length} payouts scheduled in queue',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Remix.close_line),
                  onPressed: () => Get.back(),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Flexible(
              child: upcoming.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          'No upcoming hourly payouts',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: upcoming.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final item = upcoming[index];
                        final isFirst = index == 0;
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isFirst
                                ? (dark
                                    ? AppColors.primary.withValues(alpha: 0.12)
                                    : const Color(0xFFF0FDF4))
                                : (dark
                                    ? AppColors.surfaceDarkElevated
                                    : const Color(0xFFF8FAF9)),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isFirst
                                  ? AppColors.primary.withValues(alpha: 0.3)
                                  : (dark
                                      ? AppColors.borderDark
                                      : const Color(0xFFE2EBE5)),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isFirst
                                      ? AppColors.primary
                                      : AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  time(item['dueDate']),
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: isFirst ? Colors.white : AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${item['projectName'] ?? 'Investment'}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: ink,
                                      ),
                                    ),
                                    if (isFirst)
                                      Text(
                                        'Next in queue',
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                money(
                                  item['expectedAmount'] ?? item['profitAmount'],
                                ),
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      isScrollControlled: true,
    );
  }

  void details(Map<String, dynamic> payout) {
    Get.dialog(
      AlertDialog(
        title: Text(period == 'Hourly' ? 'Hourly Payout Details' : 'Return Details'),
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
                    DisplayValue.reference(payout['invoiceNumber'] ?? payout['investmentReference']),
                  ),
                  ('Payout amount', money(payout['profitAmount'])),
                  ('Payout time', time(payout['date'])),
                  if (payout['dueDate'] != null) ('Scheduled date', date(payout['dueDate'])),
                  ('Payment date', date(payout['date'])),
                  ('Payment status', payoutStatus(payout)),
                  if (payout['reference'] != null)
                    ('Transaction reference', DisplayValue.reference(payout['reference'])),
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
    final rawAnalytics = rows(snapshot, 'analytics')
        .where((r) => DateTime.tryParse('${r['date']}') != null)
        .toList();
    final points = rawAnalytics.map((r) {
      final rawDate = '${r['date']}';
      final d = DateTime.parse(
        rawDate.length == 10 ? '${rawDate}T00:00:00Z' : rawDate,
      ).toUtc();
      return ReturnChartPoint(
        label: '${r['label']}',
        amount: number(r['amount']),
        date: d,
      );
    }).toList()..sort((a, b) => a.date.compareTo(b.date));
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
        if (period == 'Hourly') ...[
          card(Wrap(spacing: 24, runSpacing: 12, children: [
            for (final entry in <(String, String)>[
              ("Today's Total Earnings", money(summary['todayEarnings'])),
              ('Hourly Return Rate', snapshot['hourly']?['hourlyEarningRate'] == null
                  ? 'Not available'
                  : '${CurrencyFormatter.formatHourlyRate(snapshot['hourly']?['hourlyEarningRate'])}/hr'),
              ('Total Returns Credited', money(snapshot['hourly']?['totalCreditedReturns'])),
              ('Last Payout Time', time(snapshot['hourly']?['lastPayoutTime'])),
              ('Next Expected Payout Time', time(snapshot['hourly']?['nextExpectedPayoutTime'])),
              ('Accrued, not credited', money(snapshot['hourly']?['accruedNotCredited'])),
            ]) Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
              Text(entry.$1, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              Text(entry.$2, style: TextStyle(fontWeight: FontWeight.w600, color: ink)),
            ]),
          ])),
          const SizedBox(height: 12),
          TextButton.icon(
            key: const ValueKey('hourly-date-picker'),
            icon: const Icon(Remix.calendar_2_line),
            label: Text('Hourly Returns · ${snapshot['selectedDate'] ?? date(selectedDate)}'),
            onPressed: onDate == null ? null : () async {
              final chosen = await showDatePicker(context: context, initialDate: selectedDate ?? DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime.now());
              if (chosen != null) onDate!(chosen);
            },
          ),
        ] else
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
        _PayoutHistoryCard(
          payouts: payouts,
          period: period,
          dark: dark,
          ink: ink,
          onDetails: details,
          money: money,
          time: time,
          date: date,
          payoutStatus: payoutStatus,
        ),
        const SizedBox(height: 20),
        if (period == 'Hourly')
          NextHourlyPayoutCard(key: payoutIndicatorKey, payout: nextReturn({...snapshot, 'period': 'hourly'}), isLoading: payoutLoading, hasError: payoutError, isActive: payoutActive)
        else
        card(
          LayoutBuilder(
            builder: (context, constraints) {
              final isHourly = period == 'Hourly';
              final isCompact = constraints.maxWidth < 310;
              final textScale = MediaQuery.textScalerOf(context).scale(1);
              final isLargeText = textScale > 1.3;
              final isOverdue = next != null && next['status'] == 'OVERDUE';
              final upcomingQueue = isHourly ? rows(snapshot, 'upcoming').skip(1).toList() : const <Map<String, dynamic>>[];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- Header Row ---
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isHourly ? Remix.timer_flash_line : Remix.calendar_2_line,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isHourly ? 'Next Hourly Payout' : 'Next Return Date',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: dark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const SizedBox(height: 1),
                            Text(
                              isHourly ? 'Auto-credited to wallet' : 'Scheduled investment return',
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isHourly ? AppColors.primary : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Status Badge on Header Right
                      if (next == null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: dark ? AppColors.surfaceDarkElevated : const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'No Schedule',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        )
                      else if (isOverdue)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFEF3C7),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFFDE68A)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Remix.time_line, size: 11, color: Color(0xFFD97706)),
                              const SizedBox(width: 3),
                              Text(
                                'Awaiting credit',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFD97706),
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isHourly ? 'Live Queue' : 'Scheduled',
                                style: GoogleFonts.poppins(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),

                  // --- Main Content Box ---
                  if (next == null) ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: dark ? AppColors.surfaceDarkElevated : const Color(0xFFF8FAF9),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: dark ? AppColors.borderDark : const Color(0xFFE5EDE8),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Remix.information_line,
                            size: 18,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'No upcoming returns scheduled',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: ink,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: dark ? AppColors.surfaceDarkElevated : const Color(0xFFF6FAF8),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: dark ? AppColors.borderDark : const Color(0xFFE2EBE5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isCompact || isLargeText) ...[
                            // Stacked for compact view
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isHourly ? 'Payout Time' : 'Due Date',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  isHourly ? time(next['dueDate']) : date(next['dueDate']),
                                  style: GoogleFonts.poppins(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: ink,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Expected Amount',
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  money(next['profitAmount']),
                                  style: GoogleFonts.poppins(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            // Side-by-side for regular view
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        isHourly ? 'Payout Time' : 'Due Date',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        isHourly ? time(next['dueDate']) : date(next['dueDate']),
                                        style: GoogleFonts.poppins(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: ink,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Expected Amount',
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      money(next['profitAmount']),
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),
                          Container(
                            height: 1,
                            color: dark ? AppColors.borderDark : const Color(0xFFE5EDE8),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              const Icon(
                                Remix.building_2_line,
                                size: 14,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '${next['projectName'] ?? 'Investment'}${isOverdue ? ' · Awaiting backend credit' : ''}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: isOverdue ? const Color(0xFFD97706) : ink,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  // --- Upcoming Hourly Queue List (when in Hourly mode) ---
                  if (isHourly && upcomingQueue.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Remix.time_line, size: 14, color: AppColors.primary),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'Upcoming Hourly Queue (${upcomingQueue.length})',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: dark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        InkWell(
                          onTap: () => _showAllHourlyQueueModal(context, rows(snapshot, 'upcoming')),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'View all',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Remix.arrow_right_s_line, size: 14, color: AppColors.primary),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: dark ? AppColors.surfaceDarkElevated.withValues(alpha: 0.5) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: dark ? AppColors.borderDark : const Color(0xFFEAEFEA),
                        ),
                      ),
                      child: Column(
                        children: [
                          for (var i = 0; i < upcomingQueue.length && i < 4; i++) ...[
                            if (i > 0)
                              Divider(
                                height: 1,
                                indent: 12,
                                endIndent: 12,
                                color: dark ? AppColors.borderDark : const Color(0xFFF0F4F1),
                              ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                              child: Row(
                                children: [
                                  Flexible(
                                    flex: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withValues(alpha: 0.08),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        shortTime(upcomingQueue[i]['dueDate']),
                                        style: GoogleFonts.poppins(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      '${upcomingQueue[i]['projectName'] ?? ''}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: ink,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    flex: 0,
                                    child: Text(
                                      money(upcomingQueue[i]['expectedAmount'] ?? upcomingQueue[i]['profitAmount']),
                                      style: GoogleFonts.poppins(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          if (upcomingQueue.length > 4)
                            InkWell(
                              onTap: () => _showAllHourlyQueueModal(context, rows(snapshot, 'upcoming')),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 10, top: 6),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        'View all (+${upcomingQueue.length - 4} more)',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 2),
                                      const Icon(Remix.arrow_right_s_line, size: 14, color: AppColors.primary),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
          mint: period == 'Hourly',
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

class _PayoutHistoryCard extends StatefulWidget {
  final List<Map<String, dynamic>> payouts;
  final String period;
  final bool dark;
  final Color ink;
  final void Function(Map<String, dynamic> payout) onDetails;
  final String Function(dynamic value) money;
  final String Function(dynamic value) time;
  final String Function(dynamic value) date;
  final String Function(Map<String, dynamic> row) payoutStatus;

  const _PayoutHistoryCard({
    required this.payouts,
    required this.period,
    required this.dark,
    required this.ink,
    required this.onDetails,
    required this.money,
    required this.time,
    required this.date,
    required this.payoutStatus,
  });

  @override
  State<_PayoutHistoryCard> createState() => _PayoutHistoryCardState();
}

class _PayoutHistoryCardState extends State<_PayoutHistoryCard> {
  bool _expanded = false;
  static const int _initialLimit = 4;

  @override
  Widget build(BuildContext context) {
    final isHourly = widget.period == 'Hourly';
    final total = widget.payouts.length;
    final displayItems = (_expanded || total <= _initialLimit)
        ? widget.payouts
        : widget.payouts.take(_initialLimit).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: widget.dark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: widget.dark ? AppColors.borderDark : const Color(0xFFE8F0EB),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isHourly ? Remix.timer_flash_line : Remix.history_line,
                        color: AppColors.primary,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isHourly ? 'Hourly Payout History' : 'Payout History',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: widget.ink,
                            ),
                          ),
                          Text(
                            isHourly ? 'Credited directly to wallet' : 'Recent return credits',
                            style: GoogleFonts.poppins(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              if (total > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: widget.dark ? AppColors.surfaceDarkElevated : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$total ${total == 1 ? 'entry' : 'entries'}',
                    style: GoogleFonts.poppins(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),

          // Empty state
          if (total == 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Remix.inbox_line,
                      size: 28,
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'No returns yet',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Payout Items list (Medium Height & No IDs!)
          for (var i = 0; i < displayItems.length; i++) ...[
            if (i > 0)
              Divider(
                height: 16,
                thickness: 0.8,
                color: widget.dark ? AppColors.borderDark : const Color(0xFFF1F5F2),
              ),
            InkWell(
              key: ValueKey('payout-${displayItems[i]['id'] ?? i}'),
              onTap: () => widget.onDetails(displayItems[i]),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
                child: LayoutBuilder(
                  builder: (context, c) {
                    final compact =
                        c.maxWidth < 310 ||
                        MediaQuery.textScalerOf(context).scale(1) > 1.4;
                    final p = displayItems[i];
                    final investmentReference = DisplayValue.reference(
                      p['investmentReference'] ?? p['investmentId'],
                      internalId: p['investmentId'],
                    );
                    final amount = Text(
                      '${widget.payoutStatus(p) == 'Completed' ? '+ ' : ''}${widget.money(p['profitAmount'])}',
                      style: GoogleFonts.poppins(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5,
                      ),
                    );
                    return Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isHourly
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : AppColors.lightMint,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isHourly ? Remix.timer_line : Remix.money_rupee_circle_line,
                            color: AppColors.primary,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${p['projectName'] ?? (isHourly ? 'Hourly Profit Payout' : 'Return Payout')}',
                                style: GoogleFonts.poppins(
                                  color: widget.ink,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12.5,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (isHourly && investmentReference != 'N/A')
                                Text(
                                  'Investment $investmentReference',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.poppins(
                                    color: AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              const SizedBox(height: 2),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  Text(
                                    isHourly
                                        ? '${widget.time(p['date'])} · ${widget.date(p['date'])}'
                                        : widget.date(p['date']),
                                    style: GoogleFonts.poppins(
                                      color: AppColors.textSecondary,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  StatusBadge(status: widget.payoutStatus(p)),
                                ],
                              ),
                              if (compact)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: amount,
                                ),
                            ],
                          ),
                        ),
                        if (!compact) ...[
                          const SizedBox(width: 8),
                          Flexible(child: amount),
                        ],
                        const SizedBox(width: 4),
                        const Icon(
                          Remix.arrow_right_s_line,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],

          // Expand / Collapse button for medium height control
          if (total > _initialLimit) ...[
            const SizedBox(height: 8),
            Center(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _expanded = !_expanded;
                  });
                },
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _expanded ? 'Show less' : 'View all $total payouts',
                        style: GoogleFonts.poppins(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _expanded ? Remix.arrow_up_s_line : Remix.arrow_down_s_line,
                        size: 15,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
