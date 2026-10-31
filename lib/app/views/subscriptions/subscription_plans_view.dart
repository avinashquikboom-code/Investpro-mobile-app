import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:remixicon/remixicon.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/subscription_controller.dart';
import '../../models/subscription_plan_model.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';

class SubscriptionPlansView extends StatefulWidget {
  final bool onboarding;
  const SubscriptionPlansView({super.key, this.onboarding = false});

  @override
  State<SubscriptionPlansView> createState() => _SubscriptionPlansViewState();
}

class _SubscriptionPlansViewState extends State<SubscriptionPlansView> {
  final controller = Get.find<SubscriptionController>();
  final _scrollController = ScrollController();
  final GlobalKey _plansKey = GlobalKey();
  int period = 0;
  bool skipping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        controller.load();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToPlans() {
    final targetContext = _plansKey.currentContext;
    if (targetContext != null) {
      Scrollable.ensureVisible(
        targetContext,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else if (_scrollController.hasClients) {
      _scrollController.animateTo(
        380,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> skip() async {
    if (skipping || controller.purchasing.value) return;
    setState(() => skipping = true);
    await Get.find<AuthController>().finishSubscriptionOnboarding(skipped: true);
    if (mounted) setState(() => skipping = false);
  }

  Future<void> choose(SubscriptionPlanModel plan) async {
    if (!await controller.purchase(plan) || !mounted) return;
    await Get.find<AuthController>().finishSubscriptionOnboarding();
    if (!widget.onboarding) {
      Get.snackbar(
        'Subscription Activated',
        'Your ${plan.name} plan is now active. Eligible investment opportunities are unlocked.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: AppColors.primary,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        margin: const EdgeInsets.all(16),
        borderRadius: 10,
      );
    }
  }

  void _renewCurrentPlan() {
    final current = controller.currentPlan;
    if (current != null) {
      final matching = controller.plans.firstWhereOrNull(
        (p) => p.id == current.id || p.slug == current.slug,
      );
      if (matching != null) {
        choose(matching);
        return;
      }
    }
    _scrollToPlans();
  }

  void _showSubscriptionHistorySheet() {
    controller.loadHistory();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetCtx).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Remix.history_line, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Subscription History',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(sheetCtx),
                    icon: const Icon(Remix.close_line, size: 20),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.border),
            Expanded(
              child: Obx(() {
                final list = controller.history;
                if (list.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Remix.calendar_todo_line, size: 40, color: AppColors.textSecondary),
                          const SizedBox(height: 12),
                          Text(
                            'No Subscription History',
                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your past subscriptions and renewals will appear here.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(fontSize: 12.5, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (_, index) {
                    final item = list[index];
                    final plan = item['plan'] as Map<String, dynamic>?;
                    final name = plan?['name']?.toString() ?? 'Plan';
                    final amount = (item['amountPaid'] as num?)?.toDouble() ?? (plan?['price'] as num?)?.toDouble() ?? 0.0;
                    final status = item['status']?.toString().toUpperCase() ?? 'ACTIVE';
                    final start = DateTime.tryParse('${item['startDate']}');
                    final end = DateTime.tryParse('${item['endDate']}');
                    final startStr = start != null ? DateFormatter.formatDate(start) : '—';
                    final endStr = end != null ? DateFormatter.formatDate(end) : '—';
                    final cycle = item['billingCycle']?.toString() ??
                        ((item['durationMonths'] == 1) ? 'MONTHLY' : 'YEARLY');

                    return InkWell(
                      onTap: () => _showHistoryDetailsDialog(item),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FBFA),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border, width: 0.8),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.lightMint,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Remix.vip_crown_line, size: 18, color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        name,
                                        style: GoogleFonts.poppins(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      _buildStatusBadge(status),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '$cycle · $startStr to $endStr',
                                    style: GoogleFonts.poppins(
                                      fontSize: 11.5,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    CurrencyFormatter.format(amount, showDecimals: true),
                                    style: GoogleFonts.poppins(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Remix.arrow_right_s_line, size: 18, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _showHistoryDetailsDialog(Map<String, dynamic> item) {
    final plan = item['plan'] as Map<String, dynamic>?;
    final name = plan?['name']?.toString() ?? 'Plan';
    final amount = (item['amountPaid'] as num?)?.toDouble() ?? 0.0;
    final status = item['status']?.toString().toUpperCase() ?? 'ACTIVE';
    final start = DateTime.tryParse('${item['startDate']}');
    final end = DateTime.tryParse('${item['endDate']}');
    final startStr = start != null ? DateFormatter.formatDate(start) : '—';
    final endStr = end != null ? DateFormatter.formatDate(end) : '—';
    final ref = item['subscriptionReference']?.toString() ?? 'N/A';
    final cycle = item['billingCycle']?.toString() ?? 'YEARLY';
    final paymentMethod = item['paymentMethod']?.toString() ?? 'Razorpay';

    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Remix.file_list_3_line, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Subscription Details',
              style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDialogDetailRow('Plan', name),
            _buildDialogDetailRow('Reference', ref),
            _buildDialogDetailRow('Status', status),
            _buildDialogDetailRow('Amount Paid', CurrencyFormatter.format(amount, showDecimals: true)),
            _buildDialogDetailRow('Billing Cycle', cycle),
            _buildDialogDetailRow('Start Date', startStr),
            _buildDialogDetailRow('Expiry Date', endStr),
            _buildDialogDetailRow('Payment Method', paymentMethod),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDialogDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: GoogleFonts.poppins(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color text;
    String label = status;

    if (status == 'ACTIVE') {
      bg = AppColors.badgeGreenBg;
      text = AppColors.badgeGreenText;
      label = 'Active';
    } else if (status == 'EXPIRING_SOON') {
      bg = AppColors.badgeAmberBg;
      text = AppColors.badgeAmberText;
      label = 'Expiring Soon';
    } else if (status == 'EXPIRED') {
      bg = AppColors.badgeRedBg;
      text = AppColors.badgeRedText;
      label = 'Expired';
    } else {
      bg = const Color(0xFFF3F4F6);
      text = const Color(0xFF4B5563);
      label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: GoogleFonts.poppins(fontSize: 10.5, fontWeight: FontWeight.w700, color: text),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Obx(() {
        final buying = controller.purchasing.value;
        final plans = controller.plans;
        final periodToggle =
            plans.any((p) => p.durationMonths == 1) &&
            plans.any((p) => p.durationMonths == 12);
        final visible = plans
            .where((p) =>
                !periodToggle || period == 0 || p.durationMonths == period)
            .toList();

        final hasActive = controller.hasActivePlan;
        final isExpiring = controller.isExpiringSoon;
        final isExpired = controller.isExpired;

        return PopScope(
          canPop: !widget.onboarding && !buying && !skipping,
          child: Scaffold(
            backgroundColor: const Color(0xFFF8FAF9),
            appBar: AppBar(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              automaticallyImplyLeading: false,
              leading: !widget.onboarding
                  ? IconButton(
                      icon: const Icon(Remix.arrow_left_s_line, color: AppColors.textPrimary, size: 24),
                      onPressed: () => Navigator.maybePop(context),
                    )
                  : null,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.onboarding ? 'Investment Plans' : 'My Plan',
                    style: GoogleFonts.poppins(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  if (!widget.onboarding)
                    Text(
                      'Manage your investment subscription',
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'Refresh plans',
                  onPressed: buying || skipping ? null : () => controller.load(force: true),
                  icon: const Icon(Remix.refresh_line, color: AppColors.textPrimary, size: 20),
                ),
              ],
            ),
            body: SafeArea(
              child: Column(
                children: [
                  if (controller.loading.value) const LinearProgressIndicator(color: AppColors.primary),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: LayoutBuilder(
                          builder: (context, bounds) => SingleChildScrollView(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // 1. Expiring Soon or Expired Alert Banner
                                if (hasActive && isExpiring)
                                  _buildExpiringSoonBanner()
                                else if (isExpired)
                                  _buildExpiredBanner(),

                                // 2. Main Subscription Card Section
                                if (hasActive) ...[
                                  _buildActivePlanCard(),
                                  const SizedBox(height: 14),
                                  _buildSummaryCards(),
                                  const SizedBox(height: 14),
                                  _buildPlanBenefitsCard(),
                                  const SizedBox(height: 16),
                                  _buildPlanActionsRow(),
                                  const SizedBox(height: 28),
                                ] else if (isExpired) ...[
                                  _buildExpiredPlanCard(),
                                  const SizedBox(height: 14),
                                  _buildSummaryCards(),
                                  const SizedBox(height: 14),
                                  _buildPlanBenefitsCard(),
                                  const SizedBox(height: 16),
                                  _buildPlanActionsRow(),
                                  const SizedBox(height: 28),
                                ] else if (!widget.onboarding) ...[
                                  _buildNoPlanCard(),
                                  const SizedBox(height: 28),
                                ],

                                // Error display if any
                                if (controller.error.isNotEmpty)
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.badgeRedBg,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: const Color(0x66EF4444)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Remix.error_warning_line, color: AppColors.error, size: 18),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            controller.error.value,
                                            style: GoogleFonts.poppins(fontSize: 12.5, color: const Color(0xFF7F1D1D)),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                // 3. Available Plans Catalog Section
                                Container(key: _plansKey),
                                Text(
                                  'Choose Your Investment Plan',
                                  style: GoogleFonts.poppins(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Select a subscription plan to unlock eligible investment opportunities.',
                                  style: GoogleFonts.poppins(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Period Toggle (All / Monthly / Yearly)
                                if (periodToggle)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: Wrap(
                                      spacing: 8,
                                      children: [
                                        for (final entry in {
                                          0: 'All Plans',
                                          1: 'Monthly',
                                          12: 'Yearly',
                                        }.entries)
                                          ChoiceChip(
                                            label: Text(
                                              entry.value,
                                              style: GoogleFonts.poppins(
                                                fontSize: 12,
                                                fontWeight: period == entry.key ? FontWeight.w600 : FontWeight.normal,
                                              ),
                                            ),
                                            selected: period == entry.key,
                                            selectedColor: AppColors.lightMint,
                                            side: BorderSide(
                                              color: period == entry.key ? AppColors.primary : AppColors.border,
                                            ),
                                            onSelected: buying
                                                ? null
                                                : (_) => setState(
                                                      () => period = entry.key,
                                                    ),
                                          ),
                                      ],
                                    ),
                                  ),

                                // Empty plans fallback
                                if (plans.isEmpty && !controller.loading.value) ...[
                                  Container(
                                    padding: const EdgeInsets.all(24),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: AppColors.border),
                                    ),
                                    child: Column(
                                      children: [
                                        const Icon(
                                          Remix.file_list_3_line,
                                          size: 40,
                                          color: AppColors.primary,
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          'No subscription plans are available right now. You can continue and choose a plan later.',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(fontSize: 13, color: AppColors.textSecondary),
                                        ),
                                        const SizedBox(height: 8),
                                        TextButton.icon(
                                          onPressed: buying ? null : () => controller.load(force: true),
                                          icon: const Icon(Remix.refresh_line, size: 16),
                                          label: const Text('Retry'),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],

                                // Plan Cards Grid / List
                                for (final plan in visible) ...[
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 14),
                                    child: SubscriptionPlanCard(
                                      plan: plan,
                                      disabled: buying || skipping,
                                      onChoose: () => choose(plan),
                                    ),
                                  ),
                                ],

                                if (buying)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: Center(
                                      child: Text(
                                        'Processing purchase...',
                                        style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 20),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Persistent Skip button for Onboarding mode
                  if (widget.onboarding)
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 720),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 13),
                                  side: const BorderSide(color: AppColors.border),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: buying || skipping ? null : skip,
                                child: Text(
                                  skipping ? 'Continuing…' : 'Skip for Now',
                                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'You can purchase a subscription anytime from your profile.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.poppins(fontSize: 11.5, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      });

  // ----------------------------------------------------
  // ACTIVE PLAN CARD
  // ----------------------------------------------------
  Widget _buildActivePlanCard() {
    final planName = controller.currentPlanName;
    final isExpiring = controller.isExpiringSoon;
    final startDate = controller.currentStartDate;
    final endDate = controller.currentEndDate;
    final startStr = startDate != null ? DateFormatter.formatDate(startDate) : '—';
    final endStr = endDate != null ? DateFormatter.formatDate(endDate) : '—';
    final remaining = controller.remainingDays;
    final price = controller.currentPrice;
    final cycle = controller.currentBillingCycle;
    final progress = controller.validityProgress;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF003B2D),
            Color(0xFF00523C),
            Color(0xFF00684D),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF003B2D).withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Plan Name + Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CURRENT PLAN',
                      style: GoogleFonts.poppins(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                        color: const Color(0xFF86EFAC),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      planName,
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: isExpiring ? const Color(0xFFFEF3C7) : const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isExpiring ? Remix.time_line : Remix.checkbox_circle_fill,
                      size: 13,
                      color: isExpiring ? const Color(0xFFB45309) : const Color(0xFF047857),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isExpiring ? 'Expiring Soon' : 'Active',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: isExpiring ? const Color(0xFFB45309) : const Color(0xFF047857),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Price & Cycle
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                CurrencyFormatter.format(price, showDecimals: true),
                style: GoogleFonts.poppins(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '/ $cycle',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Divider
          Container(height: 1, color: Colors.white.withValues(alpha: 0.15)),
          const SizedBox(height: 14),

          // Start & End dates
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Activated',
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.white60),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    startStr,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Expires',
                    style: GoogleFonts.poppins(fontSize: 11, color: Colors.white60),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    endStr,
                    style: GoogleFonts.poppins(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Validity Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 7,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              valueColor: AlwaysStoppedAnimation<Color>(
                isExpiring ? const Color(0xFFFBBF24) : const Color(0xFF34D399),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Progress text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toInt()}% elapsed',
                style: GoogleFonts.poppins(fontSize: 11, color: Colors.white60),
              ),
              Text(
                '$remaining day${remaining == 1 ? '' : 's'} remaining',
                style: GoogleFonts.poppins(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isExpiring ? const Color(0xFFFDE68A) : const Color(0xFF86EFAC),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // SUMMARY CARDS (Investment Range & Billing Cycle)
  // ----------------------------------------------------
  Widget _buildSummaryCards() {
    final currentPlan = controller.currentPlan;
    final minInv = currentPlan?.formattedMinInvestment ?? '₹ 0';
    final maxInv = currentPlan?.formattedMaxInvestment ?? '₹ 0';
    final cycle = controller.currentBillingCycle;
    final endDate = controller.currentEndDate;
    final nextRenewal = endDate != null ? DateFormatter.formatDate(endDate) : '—';

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 360;
        final card1 = _buildCompactSummaryCard(
          icon: Remix.wallet_3_line,
          title: 'Investment Range',
          primary: '$minInv – $maxInv',
          secondary: 'Allowed project tier',
        );
        final card2 = _buildCompactSummaryCard(
          icon: Remix.repeat_line,
          title: 'Billing Cycle',
          primary: cycle,
          secondary: 'Renewal: $nextRenewal',
        );

        if (isNarrow) {
          return Column(
            children: [
              card1,
              const SizedBox(height: 10),
              card2,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: card1),
            const SizedBox(width: 12),
            Expanded(child: card2),
          ],
        );
      },
    );
  }

  Widget _buildCompactSummaryCard({
    required IconData icon,
    required String title,
    required String primary,
    required String secondary,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: AppColors.lightMint,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(icon, size: 15, color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            primary,
            style: GoogleFonts.poppins(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            secondary,
            style: GoogleFonts.poppins(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // PLAN BENEFITS CARD
  // ----------------------------------------------------
  Widget _buildPlanBenefitsCard() {
    final currentPlan = controller.currentPlan;
    final benefits = currentPlan?.benefits ?? [];
    final rules = currentPlan?.accessRules ?? {};
    final features = rules['features'] is List
        ? (rules['features'] as List).map((v) => v.toString()).toList()
        : <String>[];
    final allBenefits = {...benefits, ...features}.toList();

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.lightMint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Remix.shield_check_line,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Your Plan Benefits',
                style: GoogleFonts.poppins(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (allBenefits.isEmpty)
            Text(
              'All standard investor tier privileges and project eligibility are active for this plan.',
              style: GoogleFonts.poppins(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            )
          else
            ...allBenefits.map(
              (benefit) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Remix.checkbox_circle_fill,
                      size: 16,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        benefit,
                        style: GoogleFonts.poppins(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // PLAN ACTIONS ROW
  // ----------------------------------------------------
  Widget _buildPlanActionsRow() {
    final isExpiring = controller.isExpiringSoon;
    final isExpired = controller.isExpired;
    final buying = controller.purchasing.value;

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        if (isExpiring || isExpired)
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: isExpiring ? const Color(0xFFD97706) : AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: buying ? null : _renewCurrentPlan,
            icon: const Icon(Remix.refresh_line, size: 16),
            label: Text(
              isExpiring ? 'Renew Plan' : 'Renew Subscription',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: buying ? null : _scrollToPlans,
          icon: const Icon(Remix.arrow_up_circle_line, size: 16),
          label: Text(
            controller.hasActivePlan ? 'Upgrade Plan' : 'Explore Other Plans',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ),
        TextButton.icon(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          onPressed: _showSubscriptionHistorySheet,
          icon: const Icon(Remix.history_line, size: 16),
          label: Text(
            'Subscription History',
            style: GoogleFonts.poppins(fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ),
      ],
    );
  }

  // ----------------------------------------------------
  // BANNERS (Expiring Soon & Expired)
  // ----------------------------------------------------
  Widget _buildExpiringSoonBanner() {
    final remaining = controller.remainingDays;
    final endDate = controller.currentEndDate;
    final expiryFormatted = endDate != null ? DateFormatter.formatDate(endDate) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.badgeAmberBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x7FF59E0B)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Remix.time_line, color: AppColors.badgeAmberText, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Subscription Expiring Soon',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    color: AppColors.badgeAmberText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your ${controller.currentPlanName} subscription expires in $remaining day${remaining == 1 ? '' : 's'} on $expiryFormatted. Renew now to maintain uninterrupted access to eligible investment opportunities.',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: const Color(0xFF78350F),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiredBanner() {
    final endDate = controller.currentEndDate;
    final expiryFormatted = endDate != null ? DateFormatter.formatDate(endDate) : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.badgeRedBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x66EF4444)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Remix.error_warning_line, color: AppColors.error, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Subscription Expired',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your ${controller.currentPlanName} subscription has expired${expiryFormatted.isNotEmpty ? ' on $expiryFormatted' : ''}. Renew your plan now to continue accessing eligible investment opportunities.',
                  style: GoogleFonts.poppins(
                    fontSize: 12.5,
                    color: const Color(0xFF7F1D1D),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExpiredPlanCard() {
    final endDate = controller.currentEndDate;
    final endStr = endDate != null ? DateFormatter.formatDate(endDate) : '—';
    final price = controller.currentPrice;
    final cycle = controller.currentBillingCycle;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFCA5A5), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  controller.currentPlanName,
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.badgeRedBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Remix.error_warning_line, size: 13, color: AppColors.badgeRedText),
                    const SizedBox(width: 4),
                    Text(
                      'Expired',
                      style: GoogleFonts.poppins(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.badgeRedText,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${CurrencyFormatter.format(price, showDecimals: true)} / $cycle',
            style: GoogleFonts.poppins(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Remix.calendar_close_line, size: 16, color: AppColors.error),
              const SizedBox(width: 6),
              Text(
                'Expired on: $endStr',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your access to eligible investment opportunities has expired. Renew your plan now to continue investing.',
            style: GoogleFonts.poppins(fontSize: 12, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------
  // NO ACTIVE PLAN STATE
  // ----------------------------------------------------
  Widget _buildNoPlanCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.lightMint,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Remix.vip_crown_line,
              size: 28,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'No Active Plan',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "You haven't purchased a subscription yet. Choose a plan to explore eligible investment opportunities.",
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 12.5,
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: _scrollToPlans,
            icon: const Icon(Remix.compass_3_line, size: 16),
            label: Text(
              'Explore Plans',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// SUBSCRIPTION PLAN CARD (Catalog Item)
// ----------------------------------------------------
class SubscriptionPlanCard extends StatelessWidget {
  final SubscriptionPlanModel plan;
  final bool disabled;
  final VoidCallback onChoose;

  const SubscriptionPlanCard({
    super.key,
    required this.plan,
    required this.disabled,
    required this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    final rules = plan.accessRules ?? {};
    final isRecommended = rules['recommended'] == true || rules['isRecommended'] == true;
    final features = rules['features'] is List
        ? (rules['features'] as List).map((v) => v.toString()).toList()
        : <String>[];
    final allBenefits = {...plan.benefits, ...features}.toList();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isRecommended ? AppColors.primary : AppColors.border,
          width: isRecommended ? 1.8 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isRecommended
                ? AppColors.primary.withValues(alpha: 0.08)
                : AppColors.textPrimary.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Name + Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  plan.name,
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (isRecommended)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.lightMint,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Remix.star_fill, size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Recommended',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),

          // Price & Duration
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                plan.formattedPrice,
                style: GoogleFonts.poppins(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '/ ${plan.durationMonths} ${plan.durationMonths == 1 ? 'month' : 'months'}',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Allowed Investment Range Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F6F4),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Remix.money_rupee_circle_line, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Allowed: ${plan.formattedRange}',
                    style: GoogleFonts.poppins(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Benefits checklist
          for (final benefit in allBenefits)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Remix.check_line, size: 16, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      benefit,
                      style: GoogleFonts.poppins(
                        fontSize: 12.5,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 14),

          // CTA Button
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: disabled ? null : onChoose,
            child: Text(
              'Choose Plan',
              style: GoogleFonts.poppins(fontWeight: FontWeight.w600, fontSize: 13.5),
            ),
          ),
        ],
      ),
    );
  }
}

// ----------------------------------------------------
// SUBSCRIPTION PROFILE CARD (Used inside Profile View)
// ----------------------------------------------------
class SubscriptionProfileCard extends StatefulWidget {
  const SubscriptionProfileCard({super.key});

  @override
  State<SubscriptionProfileCard> createState() => _SubscriptionProfileCardState();
}

class _SubscriptionProfileCardState extends State<SubscriptionProfileCard> {
  final controller = Get.find<SubscriptionController>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        controller.load();
      }
    });
  }

  @override
  Widget build(BuildContext context) => Obx(() {
        final hasActive = controller.hasActivePlan;
        final isExpiring = controller.isExpiringSoon;
        final isExpired = controller.isExpired;
        final planName = controller.currentPlanName;
        final endDate = controller.currentEndDate;
        final expiryStr = endDate != null ? DateFormatter.formatDate(endDate) : '';

        return Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Subscription Plan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (hasActive && isExpiring)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.badgeAmberBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Expiring (${controller.remainingDays}d)',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.badgeAmberText,
                          ),
                        ),
                      )
                    else if (hasActive)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.badgeGreenBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Active',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.badgeGreenText,
                          ),
                        ),
                      )
                    else if (isExpired)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.badgeRedBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Expired',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.badgeRedText,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 10),
                if (controller.loading.value)
                  const LinearProgressIndicator()
                else if (hasActive) ...[
                  Text(
                    planName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Expires: $expiryStr (${controller.remainingDays} days remaining)',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ] else if (isExpired) ...[
                  Text(
                    planName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Expired on: $expiryStr',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ] else ...[
                  const Text(
                    'No Active Subscription',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Choose a plan to access eligible investment projects.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                FilledButton.tonalIcon(
                  style: FilledButton.styleFrom(
                    backgroundColor: isExpiring || isExpired
                        ? AppColors.badgeAmberBg
                        : AppColors.lightMint,
                    foregroundColor: isExpiring || isExpired
                        ? AppColors.badgeAmberText
                        : AppColors.primary,
                  ),
                  onPressed: () => Get.toNamed(AppRoutes.subscriptionPlans),
                  icon: const Icon(Remix.vip_crown_line, size: 18),
                  label: Text(
                    isExpiring || isExpired
                        ? 'Renew Subscription'
                        : (hasActive ? 'Upgrade or Change Plan' : 'Explore Subscription Plans'),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
        );
      });
}
