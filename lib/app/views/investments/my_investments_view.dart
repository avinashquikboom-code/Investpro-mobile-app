import 'package:remixicon/remixicon.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../controllers/investment_controller.dart';
import '../../models/investment_model.dart';
import '../../routes/app_routes.dart';
import '../../services/demo_repository.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';
import '../../utils/responsive_helper.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/status_badge.dart';

class MyInvestmentsView extends StatefulWidget {
  final bool isTab;

  const MyInvestmentsView({super.key, this.isTab = true});

  @override
  State<MyInvestmentsView> createState() => _MyInvestmentsViewState();
}

class _MyInvestmentsViewState extends State<MyInvestmentsView> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      setState(() {
        _searchQuery = _searchCtrl.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _isRefreshing = true);
    try {
      await Get.find<DemoRepository>().syncFromBackend();
    } finally {
      if (mounted) setState(() => _isRefreshing = false);
    }
  }

  IconData _getCategoryIcon(String iconType) {
    switch (iconType.toLowerCase()) {
      case 'code':
      case 'technology':
        return Remix.code_s_slash_line;
      case 'mobile':
      case 'telecom':
        return Remix.smartphone_line;
      case 'real estate':
      case 'infrastructure':
        return Remix.building_4_line;
      case 'energy':
      case 'clean energy':
        return Remix.sun_line;
      case 'agriculture':
        return Remix.leaf_line;
      default:
        return Remix.briefcase_line;
    }
  }

  @override
  Widget build(BuildContext context) {
    final invCtrl = Get.find<InvestmentController>();
    final repo = Get.find<DemoRepository>();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filterTabs = ['All', 'Active', 'Completed', 'Pending'];

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: CustomAppBar(
        title: widget.isTab ? 'myInvestments'.tr : 'investmentHistory'.tr,
        showBackButton: !widget.isTab,
        actions: [
          if (repo.isLive) IconButton(tooltip: 'Offline Payment Requests', icon: const Icon(Remix.bank_line), onPressed: () => Get.toNamed(AppRoutes.offlinePayments)),
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                  )
                : const Icon(Remix.refresh_line, color: AppColors.primary),
            tooltip: 'Refresh Investments',
            onPressed: _isRefreshing ? null : _refresh,
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveHelper.responsiveContainer(
          context: context,
          maxWidth: 600,
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.primary,
            child: Obx(() {
              final allInvestments = repo.investments;

              // Portfolio KPIs
              double totalInvested = 0;
              double totalReturns = 0;
              int activeCount = 0;
              int completedCount = 0;

              for (final inv in allInvestments) {
                if (['active', 'completed'].contains(inv.status.toLowerCase())) {
                  totalInvested += inv.investedAmount;
                  totalReturns += inv.expectedReturn;
                }
                if (inv.status.toLowerCase() == 'active') activeCount++;
                if (inv.status.toLowerCase() == 'completed') completedCount++;
              }

              // Apply status and search filter
              final filtered = allInvestments.where((inv) {
                final matchesFilter = invCtrl.myInvestmentsFilter.value == 'All' ||
                    inv.status.toLowerCase() == invCtrl.myInvestmentsFilter.value.toLowerCase();
                final matchesSearch = _searchQuery.isEmpty ||
                    inv.projectName.toLowerCase().contains(_searchQuery) ||
                    inv.reference.toLowerCase().contains(_searchQuery) ||
                    inv.id.toLowerCase().contains(_searchQuery);
                return matchesFilter && matchesSearch;
              }).toList();

              return CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // 1. KPI Portfolio Metrics
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                      child: _buildPortfolioKpiCard(
                        totalInvested: totalInvested,
                        totalReturns: totalReturns,
                        activeCount: activeCount,
                        completedCount: completedCount,
                        isDark: isDark,
                      ),
                    ),
                  ),

                  // 2. Search Field
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: TextField(
                        controller: _searchCtrl,
                        style: GoogleFonts.poppins(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Search by project name or ID...',
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 12.5,
                            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                          ),
                          prefixIcon: const Icon(Remix.search_line, size: 20, color: AppColors.primary),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Remix.close_line, size: 18),
                                  onPressed: () => _searchCtrl.clear(),
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          filled: true,
                          fillColor: isDark ? AppColors.surfaceDark : Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 3. Status Tabs
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: filterTabs.map((filter) {
                            final isSelected = invCtrl.myInvestmentsFilter.value.toLowerCase() == filter.toLowerCase();

                            final count = filter == 'All'
                                ? allInvestments.length
                                : allInvestments
                                    .where((i) => i.status.toLowerCase() == filter.toLowerCase())
                                    .length;

                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () => invCtrl.setMyInvestmentsFilter(filter),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColors.primary
                                        : (isDark ? AppColors.surfaceDark : Colors.white),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected
                                          ? AppColors.primary
                                          : (isDark ? AppColors.borderDark : AppColors.border),
                                      width: 1,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: AppColors.primary.withValues(alpha: 0.25),
                                              blurRadius: 6,
                                              offset: const Offset(0, 2),
                                            ),
                                          ]
                                        : null,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        filter,
                                        style: GoogleFonts.poppins(
                                          fontSize: 12.5,
                                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                          color: isSelected
                                              ? Colors.white
                                              : (isDark ? AppColors.textSecondaryDark : AppColors.textPrimary),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? Colors.white.withValues(alpha: 0.25)
                                              : (isDark
                                                  ? AppColors.surfaceDarkElevated
                                                  : const Color(0xFFE8F2EC)),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: Text(
                                          '$count',
                                          style: GoogleFonts.poppins(
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                            color: isSelected ? Colors.white : AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ),

                  // 4. Investment Cards List
                  if (filtered.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyStateWidget(
                        icon: Remix.safe_2_line,
                        title: _searchQuery.isNotEmpty
                            ? 'No Matching Investments'
                            : 'No ${invCtrl.myInvestmentsFilter.value} Investments',
                        message: _searchQuery.isNotEmpty
                            ? 'No records match "$_searchQuery". Check spelling or clear filters.'
                            : 'You have no investments recorded under this category.',
                        buttonText: 'Explore Projects',
                        onButtonPressed: () {
                          if (widget.isTab) {
                            Get.toNamed(AppRoutes.projects);
                          } else {
                            Get.toNamed(AppRoutes.projects);
                          }
                        },
                      ),
                    )
                  else
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final inv = filtered[index];
                            return _buildInvestmentCard(
                              context: context,
                              inv: inv,
                              isDark: isDark,
                              onTap: () {
                                invCtrl.selectInvestment(inv);
                                Get.toNamed(
                                  AppRoutes.investmentDetails,
                                  arguments: {'investmentId': inv.id},
                                );
                              },
                            );
                          },
                          childCount: filtered.length,
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

  Widget _buildPortfolioKpiCard({
    required double totalInvested,
    required double totalReturns,
    required int activeCount,
    required int completedCount,
    required bool isDark,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B4D3E), Color(0xFF0F3026)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B4D3E).withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PORTFOLIO VALUE',
                style: GoogleFonts.poppins(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: const Color(0xFFB4E0CA),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Remix.stock_line, color: Color(0xFF4ADE80), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Live Tracking',
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyFormatter.format(totalInvested),
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMetricCol('Expected Returns', CurrencyFormatter.format(totalReturns), const Color(0xFF4ADE80)),
                Container(width: 1, height: 28, color: Colors.white.withValues(alpha: 0.2)),
                _buildMetricCol('Active Projects', '$activeCount', Colors.white),
                Container(width: 1, height: 28, color: Colors.white.withValues(alpha: 0.2)),
                _buildMetricCol('Completed', '$completedCount', const Color(0xFFB4E0CA)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCol(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10,
            color: const Color(0xFFB4E0CA),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildInvestmentCard({
    required BuildContext context,
    required InvestmentModel inv,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    final progress = inv.durationMonths > 0
        ? (DateTime.now().difference(inv.startDate).inDays / (inv.durationMonths * 30)).clamp(0.0, 1.0)
        : 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: isDark ? AppColors.borderDark : AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashColor: AppColors.primary.withValues(alpha: 0.08),
          highlightColor: AppColors.primary.withValues(alpha: 0.04),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Icon, Project Name & Status Badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(_getCategoryIcon(inv.iconType), color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            inv.projectName,
                            style: GoogleFonts.poppins(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            inv.reference.isNotEmpty ? inv.reference : 'N/A',
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(status: inv.status),
                  ],
                ),
                const SizedBox(height: 14),

                // Financial Overview Grid
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDarkElevated : const Color(0xFFF7FAF8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInvestmentDetail(
                        label: 'Invested',
                        value: CurrencyFormatter.format(inv.investedAmount),
                        isDark: isDark,
                        isBold: true,
                      ),
                      _buildInvestmentDetail(
                        label: 'Return Rate',
                        value: '${inv.returnRatePercent.toStringAsFixed(1)}% p.a.',
                        isDark: isDark,
                        valueColor: AppColors.success,
                      ),
                      _buildInvestmentDetail(
                        label: 'Tenure',
                        value: '${inv.durationMonths} Mos',
                        isDark: isDark,
                      ),
                      _buildInvestmentDetail(
                        label: 'Est. Return',
                        value: CurrencyFormatter.format(inv.expectedReturn),
                        isDark: isDark,
                        valueColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Maturity Progress Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Started ${DateFormatter.formatDate(inv.startDate)}',
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      'Matures ${DateFormatter.formatDate(inv.maturityDate)}',
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 5,
                    backgroundColor: isDark ? AppColors.borderDark : const Color(0xFFE2EBE6),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      inv.status.toLowerCase() == 'completed'
                          ? AppColors.primary
                          : const Color(0xFF38A169),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInvestmentDetail({
    required String label,
    required String value,
    required bool isDark,
    Color? valueColor,
    bool isBold = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 10.5,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 12.5,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            color: valueColor ?? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary),
          ),
        ),
      ],
    );
  }
}
