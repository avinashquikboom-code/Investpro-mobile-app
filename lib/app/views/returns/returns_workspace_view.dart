import '../../utils/display_value.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';

import '../../controllers/returns_controller.dart';
import '../../routes/app_routes.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/app_app_bar.dart';
import 'returns_withdrawal_view.dart';
import 'returns_overview.dart';
import '../../theme/app_colors.dart';

/// Live returns use authoritative server snapshot from the backend.
class ReturnsWorkspaceView extends StatefulWidget {
  final bool isTab;
  const ReturnsWorkspaceView({super.key, required this.isTab});
  @override
  State<ReturnsWorkspaceView> createState() => _ReturnsWorkspaceViewState();
}

class _ReturnsWorkspaceViewState extends State<ReturnsWorkspaceView>
    with WidgetsBindingObserver {
  final controller = Get.find<ReturnsController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controller.loadWorkspace();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) controller.loadWorkspace();
  }

  double number(dynamic v) => double.tryParse('$v') ?? 0;
  String money(dynamic v) =>
      CurrencyFormatter.format(number(v), showDecimals: true);
  String date(dynamic v) {
    final d = DateTime.tryParse('$v');
    return d == null ? '—' : DateFormat('dd MMM yyyy, hh:mm a').format(d.toLocal());
  }

  String shortDate(dynamic v) {
    final d = DateTime.tryParse('$v');
    return d == null ? '—' : DateFormat('dd MMM yyyy').format(d.toLocal());
  }

  List<Map<String, dynamic>> rows(Map<String, dynamic> w, String field) =>
      (w[field] as List? ?? [])
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();

  void withdraw([String? projectId]) async {
    await Get.to(() => ReturnsWithdrawalView(projectId: projectId));
    if (mounted) controller.loadWorkspace();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: widget.isTab
          ? null
          : const AppAppBar(title: 'Returns', showBackButton: true),
      body: SafeArea(
        top: widget.isTab,
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: controller.refreshData,
          child: Obx(() {
            final w = controller.workspace.value;
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
                  children: [
                    if (widget.isTab) ...[
                      Text(
                        'Returns',
                        style: GoogleFonts.poppins(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimaryDark : AppColors.primaryDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Track your investment returns and payouts',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 18),
                    ],

                    if (controller.workspaceError.value.isNotEmpty)
                      _buildErrorCard(isDark),

                    if (controller.workspaceLoading.value && w != null)
                      const Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: LinearProgressIndicator(color: AppColors.primary),
                      ),

                    if (w == null && controller.workspaceError.value.isEmpty)
                      const _ReturnsSkeleton(),

                    if (w != null) ..._buildContent(w, isDark),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildErrorCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorLight.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Remix.error_warning_line, color: AppColors.error, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              controller.workspaceError.value,
              style: const TextStyle(fontSize: 13, color: AppColors.error),
            ),
          ),
          TextButton(
            onPressed: controller.loadWorkspace,
            child: const Text('Retry', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildContent(Map<String, dynamic> w, bool isDark) {
    return [
      // 1. Performance Analytics & Period Chart (at top for live returns overview)
      ReturnsOverview(
        snapshot: w,
        period: controller.selectedPeriod.value,
        onPeriod: controller.setPeriod,
      ),
      const SizedBox(height: 20),

      // 2. Balances, Projects, Hourly Accruals & Withdrawals
      Card(
        margin: const EdgeInsets.only(bottom: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16),
          childrenPadding: const EdgeInsets.all(16),
          title: const Text('Balances & withdrawals'),
          subtitle: const Text('Project returns, withdrawal requests and history'),
          children: [
            _buildSummaryCards(w, isDark),
            const SizedBox(height: 20),
            _buildHourlyReturnCard(w, isDark),
            const SizedBox(height: 24),
            _buildProjectReturnsSection(rows(w, 'projects'), isDark),
            const SizedBox(height: 24),
            _buildEarningsHistorySection(w, isDark),
            const SizedBox(height: 20),
            ...ledgerContent(w),
          ],
        ),
      ),
    ];
  }

  /// 6 Summary Cards for Overall Returns Dashboard
  Widget _buildSummaryCards(Map<String, dynamic> w, bool isDark) {
    final s = Map<String, dynamic>.from(w['summary'] as Map? ?? {});
    final availableBal = number(s['availableToWithdraw'] ?? s['totalWithdrawable']);

    final cards = [
      _SummaryMetric(
        title: 'Total Invested',
        value: money(s['totalInvested']),
        icon: Remix.wallet_3_line,
        iconColor: AppColors.primary,
        bgColor: AppColors.primary.withValues(alpha: 0.1),
      ),
      _SummaryMetric(
        title: 'Total Returns Earned',
        value: money(s['totalReturnsEarned'] ?? s['totalEarnedReturns']),
        icon: Remix.funds_line,
        iconColor: const Color(0xFF10B981),
        bgColor: const Color(0xFF10B981).withValues(alpha: 0.12),
        isPositive: true,
      ),
      _SummaryMetric(
        title: "Today's Earnings",
        value: money(s['todayEarnings']),
        icon: Remix.flashlight_line,
        iconColor: const Color(0xFF10B981),
        bgColor: const Color(0xFF10B981).withValues(alpha: 0.12),
        isPositive: true,
      ),
      _SummaryMetric(
        title: 'Available to Withdraw',
        value: money(availableBal),
        icon: Remix.bank_card_line,
        iconColor: AppColors.primary,
        bgColor: AppColors.primary.withValues(alpha: 0.1),
        actionLabel: availableBal > 0 ? 'Withdraw' : null,
        onAction: availableBal > 0 ? () => withdraw() : null,
      ),
      _SummaryMetric(
        title: 'Pending Withdrawals',
        value: money(s['pendingWithdrawals'] ?? s['pendingWithdrawal']),
        icon: Remix.time_line,
        iconColor: AppColors.warning,
        bgColor: AppColors.warning.withValues(alpha: 0.12),
      ),
      _SummaryMetric(
        title: 'Total Withdrawn',
        value: money(s['totalWithdrawn']),
        icon: Remix.arrow_right_up_line,
        iconColor: AppColors.textSecondary,
        bgColor: Colors.grey.withValues(alpha: 0.12),
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 520;
        final crossAxisCount = isWide ? 3 : 2;
        final itemWidth = (constraints.maxWidth - (crossAxisCount - 1) * 10) / crossAxisCount;

        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: cards.map((m) {
            return SizedBox(
              width: itemWidth,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : const Color(0xFFE8EEEC),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(5),
                          decoration: BoxDecoration(
                            color: m.bgColor,
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Icon(m.icon, size: 15, color: m.iconColor),
                        ),
                        if (m.actionLabel != null)
                          InkWell(
                            onTap: m.onAction,
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                m.actionLabel!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      m.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 3),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        m.value,
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: m.isPositive
                              ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                              : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  /// Hourly Return Information Section
  Widget _buildHourlyReturnCard(Map<String, dynamic> w, bool isDark) {
    final hourly = Map<String, dynamic>.from(w['hourly'] as Map? ?? {});
    final hourlyRate = hourly['hourlyEarningRate'] ?? '0.0000';
    final totalAccrued = money(hourly['totalAccruedReturns']);
    final totalCredited = money(hourly['totalCreditedReturns'] ?? w['summary']?['totalReturnsEarned']);
    final lastAccrual = shortDate(hourly['lastAccrualTimestamp']);
    final nextAccrual = shortDate(hourly['nextExpectedAccrualTime']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFD7E8E0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Remix.timer_flash_line, color: AppColors.primary, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hourly Return Accrual',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Automated real-time backend accruals',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(radius: 3, backgroundColor: Color(0xFF10B981)),
                    SizedBox(width: 4),
                    Text(
                      'Live',
                      style: TextStyle(
                        fontSize: 10,
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem('Hourly Rate', '₹ $hourlyRate/hr', isDark, isHighlight: true),
              ),
              Expanded(
                child: _buildMetricItem('Accrued', totalAccrued, isDark),
              ),
              Expanded(
                child: _buildMetricItem('Credited', totalCredited, isDark),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.backgroundDark : const Color(0xFFF6FAF8),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Last Accrual',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      lastAccrual,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        'Next Expected',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      nextAccrual,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> ledgerContent(Map<String, dynamic> w) {
    final s = Map<String, dynamic>.from(w['summary'] as Map? ?? {});
    return [
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? AppColors.surfaceDark : const Color(0xFFF7FBF9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            _buildLedgerRow('Expected returns', money(s['totalExpectedReturns'])),
            _buildLedgerRow('Earned returns', money(s['totalEarnedReturns'])),
            _buildLedgerRow('Completed withdrawals', money(s['totalWithdrawn'])),
            _buildLedgerRow('Pending withdrawals', money(s['pendingWithdrawal'])),
            _buildLedgerRow('Upcoming profit', money(s['upcomingReturns'])),
            _buildLedgerRow('Profit credited to wallet', money(s['totalPaidReturns'])),
          ],
        ),
      ),
      const SizedBox(height: 10),
      Text('Withdrawal History', style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      if (rows(w, 'withdrawals').isEmpty)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text('No withdrawal requests yet.'),
        ),
      ...rows(w, 'withdrawals').map(
        (r) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${money(r['amount'])} · ${r['status']}', style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(date(r['requestedAt']), style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
      ),
    ];
  }

  Widget _buildLedgerRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildMetricItem(String label, String value, bool isDark, {bool isHighlight = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isHighlight
                ? AppColors.primary
                : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
          ),
        ),
      ],
    );
  }

  /// Project-wise Returns Section
  Widget _buildProjectReturnsSection(List<Map<String, dynamic>> projects, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Project-wise Returns',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${projects.length} Project(s)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (projects.isEmpty)
          _buildEmptyState(isDark)
        else
          ...projects.map((p) => _buildProjectCard(p, isDark)),
      ],
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> p, bool isDark) {
    final availableToWithdraw = number(p['availableToWithdraw']);
    final imageUrl = p['projectImage'] as String?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE4EDE8),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Project Header
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 48,
                  height: 48,
                  color: AppColors.primary.withValues(alpha: 0.1),
                  child: imageUrl != null && imageUrl.isNotEmpty
                      ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const Icon(
                            Remix.community_line,
                            color: AppColors.primary,
                          ),
                        )
                      : const Icon(Remix.community_line, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${p['projectName']}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: '${p['investmentStatus']}'.toUpperCase() == 'ACTIVE'
                                ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                : Colors.grey.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${p['investmentStatus'] ?? p['projectStatus']}'.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: '${p['investmentStatus']}'.toUpperCase() == 'ACTIVE'
                                  ? const Color(0xFF10B981)
                                  : Colors.grey,
                            ),
                          ),
                        ),
                        Text(
                          '${p['interestRate']}% ROI • ${p['investmentDuration']} Mos',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 14),

          // Financial metrics grid
          _buildProjectMetricsGrid(p, isDark),
          const SizedBox(height: 16),

          // Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Get.toNamed(
                    AppRoutes.projectDetails,
                    arguments: '${p['projectId']}',
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Remix.eye_line, size: 16),
                  label: const Text('View Details', style: TextStyle(fontSize: 13)),
                ),
              ),
              if (availableToWithdraw > 0) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => withdraw('${p['projectId']}'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Remix.bank_line, size: 16),
                    label: const Text('Withdraw', style: TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProjectMetricsGrid(Map<String, dynamic> p, bool isDark) {
    final metrics = [
      ('Invested', money(p['investedAmount'])),
      ('Returns Earned', money(p['totalReturnsEarned'] ?? p['earnedReturns'])),
      ('Hourly Rate', '₹ ${p['hourlyReturnRate'] ?? '0.0000'}/hr'),
      ('Accrued', money(p['accruedReturns'])),
      ('Start Date', shortDate(p['startDate'])),
      ('Maturity Date', shortDate(p['maturityDate'])),
      ('Available to Withdraw', money(p['availableToWithdraw'])),
      ('Pending Withdrawal', money(p['pendingWithdrawal'])),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 10,
      children: metrics.map((m) {
        final isGreen = m.$1 == 'Returns Earned';
        return SizedBox(
          width: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                m.$1,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                m.$2,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isGreen
                      ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                      : (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Earnings History Section with Filters
  Widget _buildEarningsHistorySection(Map<String, dynamic> w, bool isDark) {
    final filters = ['All', 'Today', 'This Week', 'This Month'];

    return Obx(() {
      final txns = controller.filteredTransactions(w);

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Earnings History',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${txns.length} Transaction(s)',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Filter pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: filters.map((f) {
                final isSelected = controller.selectedHistoryFilter.value == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f),
                    selected: isSelected,
                    onSelected: (_) => controller.setHistoryFilter(f),
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                    ),
                    backgroundColor: isDark ? AppColors.surfaceDark : const Color(0xFFF0F4F2),
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          if (txns.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : const Color(0xFFE8EEEC),
                ),
              ),
              child: Center(
                child: Text(
                  'No return transactions found for this period.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            ...txns.map((t) => _buildTransactionCard(t, isDark)),
        ],
      );
    });
  }

  Widget _buildTransactionCard(Map<String, dynamic> t, bool isDark) {
    final ref = t['transactionNumber'] ?? t['reference'] ?? t['id'];
    final project = t['projectName'] ?? 'Return Payout';
    final amount = money(t['profitAmount'] ?? t['amount']);
    final dateStr = date(t['createdAt'] ?? t['date']);
    final status = '${t['status'] ?? 'COMPLETED'}'.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE8EEEC),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Remix.arrow_left_down_line, color: Color(0xFF10B981), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  project,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ref: ${DisplayValue.reference(ref)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                ),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+ ₹ $amount',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (status == 'COMPLETED' || status == 'SUCCESS' || status == 'PAID')
                      ? const Color(0xFF10B981).withValues(alpha: 0.12)
                      : Colors.orange.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status == 'COMPLETED' || status == 'SUCCESS' || status == 'PAID'
                      ? 'Completed'
                      : status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: (status == 'COMPLETED' || status == 'SUCCESS' || status == 'PAID')
                        ? const Color(0xFF10B981)
                        : Colors.orange,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Empty State when user has no investments or returns
  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE4EDE8),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Remix.funds_line, size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text(
            'No Investments or Returns Yet',
            style: GoogleFonts.poppins(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Start investing in verified projects to earn hourly returns and regular monthly payouts directly to your wallet.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => Get.toNamed(AppRoutes.projects),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Remix.compass_3_line, size: 18),
            label: const Text('Explore Projects', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final bool isPositive;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SummaryMetric({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    this.isPositive = false,
    this.actionLabel,
    this.onAction,
  });
}

class _ReturnsSkeleton extends StatelessWidget {
  const _ReturnsSkeleton();
  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading returns',
    child: Column(
      children: [
        for (final height in [146.0, 240.0, 160.0])
          Container(
            height: height,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.surfaceDarkElevated
                  : const Color(0xFFF0F7F3),
              borderRadius: BorderRadius.circular(24),
            ),
          ),
      ],
    ),
  );
}
