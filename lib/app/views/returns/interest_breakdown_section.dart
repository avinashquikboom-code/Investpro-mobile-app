import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';

import '../../theme/app_colors.dart';
import '../../utils/currency_formatter.dart';

/// Calculation model for single or aggregate investment interest breakdown.
class InvestmentInterestBreakdown {
  final String investmentId;
  final String projectId;
  final String projectName;
  final double principal;
  final double monthlyRate; // in %
  final double monthlyInterest;
  final double dailyInterest;
  final double hourlyInterest;
  final double minuteInterest;
  final String status;

  const InvestmentInterestBreakdown({
    required this.investmentId,
    required this.projectId,
    required this.projectName,
    required this.principal,
    required this.monthlyRate,
    required this.monthlyInterest,
    required this.dailyInterest,
    required this.hourlyInterest,
    required this.minuteInterest,
    this.status = 'ACTIVE',
  });

  /// Dynamic calculation strictly following financial formula:
  /// Monthly Interest = Principal × Monthly Rate / 100
  /// Daily Interest = Monthly Interest / 30
  /// Hourly Interest = Daily Interest / 24
  /// Minute Interest = Hourly Interest / 60
  /// Never rounds intermediate calculations before deriving smaller time intervals.
  factory InvestmentInterestBreakdown.calculate({
    required String investmentId,
    required String projectId,
    required String projectName,
    required double principal,
    required double monthlyRate,
    double? knownMonthlyInterest,
    String status = 'ACTIVE',
  }) {
    final monthly = knownMonthlyInterest != null && knownMonthlyInterest > 0
        ? knownMonthlyInterest
        : (principal * monthlyRate / 100.0);

    // Exact unrounded intermediate divisions
    final daily = monthly / 30.0;
    final hourly = daily / 24.0;
    final minute = hourly / 60.0;

    return InvestmentInterestBreakdown(
      investmentId: investmentId,
      projectId: projectId,
      projectName: projectName,
      principal: principal,
      monthlyRate: monthlyRate,
      monthlyInterest: monthly,
      dailyInterest: daily,
      hourlyInterest: hourly,
      minuteInterest: minute,
      status: status,
    );
  }

  factory InvestmentInterestBreakdown.fromJson(Map<String, dynamic> json) {
    final principal = (json['principal'] as num?)?.toDouble() ?? 0.0;
    final monthlyRate = (json['monthlyRate'] as num?)?.toDouble() ?? 0.0;
    final monthly = (json['monthlyInterest'] as num?)?.toDouble();
    final daily = (json['dailyInterest'] as num?)?.toDouble();
    final hourly = (json['hourlyInterest'] as num?)?.toDouble();
    final minute = (json['minuteInterest'] as num?)?.toDouble();

    if (monthly != null && daily != null && hourly != null && minute != null) {
      return InvestmentInterestBreakdown(
        investmentId: json['investmentId']?.toString() ?? json['id']?.toString() ?? '—',
        projectId: json['projectId']?.toString() ?? '',
        projectName: json['projectName']?.toString() ?? 'Investment',
        principal: principal,
        monthlyRate: monthlyRate,
        monthlyInterest: monthly,
        dailyInterest: daily,
        hourlyInterest: hourly,
        minuteInterest: minute,
        status: json['status']?.toString() ?? 'ACTIVE',
      );
    }

    return InvestmentInterestBreakdown.calculate(
      investmentId: json['investmentId']?.toString() ?? json['id']?.toString() ?? '—',
      projectId: json['projectId']?.toString() ?? '',
      projectName: json['projectName']?.toString() ?? 'Investment',
      principal: principal,
      monthlyRate: monthlyRate,
      status: json['status']?.toString() ?? 'ACTIVE',
    );
  }
}

/// Formatter with specified precision:
/// Monthly: 2 decimal places
/// Daily: 2 decimal places
/// Hourly: 2-4 decimal places
/// Minute: 4-6 decimal places
class InterestFormatter {
  static String formatMonthly(double amount) {
    if (amount == amount.roundToDouble()) {
      return '₹${NumberFormat('#,##0', 'en_IN').format(amount)}';
    }
    return '₹${NumberFormat('#,##0.00', 'en_IN').format(amount)}';
  }

  static String formatDaily(double amount) {
    if (amount == amount.roundToDouble()) {
      return '₹${NumberFormat('#,##0', 'en_IN').format(amount)}';
    }
    return '₹${NumberFormat('#,##0.00', 'en_IN').format(amount)}';
  }

  static String formatHourly(double amount) {
    final formatted = NumberFormat('#,##0.00##', 'en_IN').format(amount);
    return '₹$formatted';
  }

  static String formatMinute(double amount) {
    final formatted = NumberFormat('#,##0.0000#', 'en_IN').format(amount);
    return '₹$formatted';
  }
}

/// Standalone & embedded widget rendering the Daily, Hourly & Minute Interest breakdown table.
class InterestBreakdownSection extends StatefulWidget {
  final Map<String, dynamic> snapshot;
  final bool isDark;

  const InterestBreakdownSection({
    super.key,
    required this.snapshot,
    required this.isDark,
  });

  @override
  State<InterestBreakdownSection> createState() => _InterestBreakdownSectionState();
}

class _InterestBreakdownSectionState extends State<InterestBreakdownSection> {
  int _selectedInvestmentIndex = 0; // 0 = Combined Portfolio, 1..N = specific investment

  List<InvestmentInterestBreakdown> _extractInvestments() {
    final List<InvestmentInterestBreakdown> list = [];

    // 1. Try from top-level interestBreakdown if supplied by backend
    final topLevel = widget.snapshot['interestBreakdown'];
    if (topLevel is Map && topLevel['investments'] is List) {
      for (final raw in (topLevel['investments'] as List)) {
        if (raw is Map) {
          list.add(InvestmentInterestBreakdown.fromJson(Map<String, dynamic>.from(raw)));
        }
      }
    }

    // 2. If empty, extract from projects
    if (list.isEmpty) {
      final projects = (widget.snapshot['projects'] as List? ?? []).whereType<Map>();
      for (final p in projects) {
        final invList = p['investments'] as List?;
        if (invList != null && invList.isNotEmpty) {
          for (final raw in invList.whereType<Map>()) {
            list.add(InvestmentInterestBreakdown.fromJson(Map<String, dynamic>.from(raw)));
          }
        } else {
          // Fall back to project-level metrics
          final principal = double.tryParse('${p['investedAmount']}') ?? 0.0;
          final rate = double.tryParse('${p['interestRate'] ?? p['expectedRoi']}') ?? 0.0;
          final isProjectActive = '${p['investmentStatus'] ?? p['projectStatus']}'.toUpperCase() == 'ACTIVE';
          if (principal > 0 && isProjectActive) {
            // Check if rate is annual or monthly
            final monthlyRate = rate > 20 ? (rate / 12.0) : rate;
            list.add(
              InvestmentInterestBreakdown.calculate(
                investmentId: (p['investmentIds'] as List?)?.firstOrNull?.toString() ?? 'PRJ-${p['projectId']}',
                projectId: '${p['projectId']}',
                projectName: '${p['projectName']}',
                principal: principal,
                monthlyRate: monthlyRate,
              ),
            );
          }
        }
      }
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final investments = _extractInvestments();

    // Combined calculations across all active investments
    final hasInvestments = investments.isNotEmpty;
    final totalPrincipal = investments.fold<double>(0.0, (acc, item) => acc + item.principal);
    final combinedMonthly = investments.fold<double>(0.0, (acc, item) => acc + item.monthlyInterest);
    final combinedDaily = combinedMonthly / 30.0;
    final combinedHourly = combinedDaily / 24.0;
    final combinedMinute = combinedHourly / 60.0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE4EDE8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header with small chart icon
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDarkElevated : AppColors.lightMint,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : const Color(0xFFD0E6DC),
                    width: 1,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Remix.bar_chart_box_line,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📊 Daily, Hourly and Minute Interest',
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Exact interest breakdown based on actual principal and interest rate',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // 2. Distinction / Notice Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF13271F) : const Color(0xFFF0FDF4),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? const Color(0xFF1F4A39) : const Color(0xFFBBF7D0),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Remix.information_line,
                  size: 15,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Estimated interest based on terms. Hourly accruals are credited to your wallet.',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 3. Combined Hourly Rate Highlight Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF003B2D), Color(0xFF00523C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Combined Hourly Rate',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF86EFAC),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasInvestments
                            ? '${InterestFormatter.formatHourly(combinedHourly)} / hr'
                            : '₹ 0.00 / hr',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    hasInvestments
                        ? '${investments.length} Active Investment${investments.length == 1 ? '' : 's'}'
                        : '0 Active',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 4. Selector for Multiple Investments (if more than 1)
          if (investments.length > 1) ...[
            Text(
              'Select Investment',
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTabChip(
                    label: 'Combined Portfolio',
                    isSelected: _selectedInvestmentIndex == 0,
                    isDark: isDark,
                    onTap: () => setState(() => _selectedInvestmentIndex = 0),
                  ),
                  for (int i = 0; i < investments.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _buildTabChip(
                        label: investments[i].projectName,
                        isSelected: _selectedInvestmentIndex == i + 1,
                        isDark: isDark,
                        onTap: () => setState(() => _selectedInvestmentIndex = i + 1),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // 5. Selected Breakdown Details (Project info if single investment selected)
          if (_selectedInvestmentIndex > 0 && _selectedInvestmentIndex <= investments.length) ...[
            _buildInvestmentSummaryPill(
              investments[_selectedInvestmentIndex - 1],
              isDark,
            ),
            const SizedBox(height: 14),
          ] else if (hasInvestments) ...[
            _buildCombinedSummaryPill(
              totalPrincipal: totalPrincipal,
              count: investments.length,
              isDark: isDark,
            ),
            const SizedBox(height: 14),
          ],

          // 6. Two-Column Table: Duration | Interest
          if (hasInvestments) ...[
            if (_selectedInvestmentIndex == 0)
              _buildBreakdownTable(
                monthly: combinedMonthly,
                daily: combinedDaily,
                hourly: combinedHourly,
                minute: combinedMinute,
                isDark: isDark,
              )
            else
              _buildBreakdownTable(
                monthly: investments[_selectedInvestmentIndex - 1].monthlyInterest,
                daily: investments[_selectedInvestmentIndex - 1].dailyInterest,
                hourly: investments[_selectedInvestmentIndex - 1].hourlyInterest,
                minute: investments[_selectedInvestmentIndex - 1].minuteInterest,
                isDark: isDark,
              ),
          ] else ...[
            // Example fallback table if no active investments exist yet
            _buildExampleTableNotice(isDark),
            const SizedBox(height: 10),
            _buildBreakdownTable(
              monthly: 1200.0,
              daily: 40.0,
              hourly: 1.6667,
              minute: 0.02778,
              isDark: isDark,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabChip({
    required String label,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : (isDark ? AppColors.surfaceDarkElevated : const Color(0xFFF3F6F4)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : const Color(0xFFE2ECE6)),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
          ),
        ),
      ),
    );
  }

  Widget _buildInvestmentSummaryPill(InvestmentInterestBreakdown inv, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDarkElevated : const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE5EDE8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  inv.projectName,
                  style: GoogleFonts.poppins(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  inv.investmentId,
                  style: GoogleFonts.poppins(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Principal: ${CurrencyFormatter.format(inv.principal)}',
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
              ),
              Text(
                'Monthly Rate: ${inv.monthlyRate.toStringAsFixed(2)}%',
                style: GoogleFonts.poppins(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedSummaryPill({
    required double totalPrincipal,
    required int count,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDarkElevated : const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE5EDE8),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Total Active Principal',
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            CurrencyFormatter.format(totalPrincipal),
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExampleTableNotice(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDarkElevated : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Icon(Remix.lightbulb_line, size: 14, color: Color(0xFFD97706)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Sample calculation for ₹10,000 at 12% monthly interest:',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? const Color(0xFFFDE68A) : const Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Two-Column Table: Duration | Interest
  Widget _buildBreakdownTable({
    required double monthly,
    required double daily,
    required double hourly,
    required double minute,
    required bool isDark,
  }) {
    final rows = [
      ('1 Month (30 days)', InterestFormatter.formatMonthly(monthly)),
      ('1 Day', InterestFormatter.formatDaily(daily)),
      ('1 Hour', InterestFormatter.formatHourly(hourly)),
      ('1 Minute', InterestFormatter.formatMinute(minute)),
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE6EFEA),
          width: 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header Row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            color: isDark ? AppColors.surfaceDarkElevated : const Color(0xFFF4F8F6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Duration',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
                Text(
                  'Interest',
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE4EDE8)),

          // Table Rows
          for (int i = 0; i < rows.length; i++) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: i % 2 == 1
                  ? (isDark ? AppColors.surfaceDarkElevated.withValues(alpha: 0.3) : const Color(0xFFFAFCFA))
                  : (isDark ? AppColors.surfaceDark : Colors.white),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        _getIconForDuration(i),
                        size: 14,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        rows[i].$1,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    rows[i].$2,
                    textAlign: TextAlign.right,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF059669), // InvestPro deep emerald accent
                    ),
                  ),
                ],
              ),
            ),
            if (i < rows.length - 1)
              Divider(
                height: 1,
                thickness: 0.8,
                color: isDark ? AppColors.borderDark.withValues(alpha: 0.5) : const Color(0xFFEEF4F1),
              ),
          ],
        ],
      ),
    );
  }

  IconData _getIconForDuration(int index) {
    switch (index) {
      case 0:
        return Remix.calendar_line;
      case 1:
        return Remix.sun_line;
      case 2:
        return Remix.time_line;
      case 3:
      default:
        return Remix.timer_line;
    }
  }
}
