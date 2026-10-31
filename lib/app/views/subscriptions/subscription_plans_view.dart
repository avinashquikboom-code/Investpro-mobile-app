import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/subscription_controller.dart';
import '../../models/subscription_plan_model.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../utils/date_formatter.dart';

class SubscriptionPlansView extends StatefulWidget {
  final bool onboarding;
  const SubscriptionPlansView({super.key, this.onboarding = false});

  @override
  State<SubscriptionPlansView> createState() => _SubscriptionPlansViewState();
}

class _SubscriptionPlansViewState extends State<SubscriptionPlansView> {
  final controller = Get.find<SubscriptionController>();
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
        'Your plan is active. Eligible investment opportunities are now available.',
      );
    }
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

        return PopScope(
          canPop: !widget.onboarding && !buying && !skipping,
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: !widget.onboarding,
              title: Text(widget.onboarding ? 'Investment Plans' : 'My Plan'),
              actions: [
                IconButton(
                  tooltip: 'Refresh plans',
                  onPressed: buying || skipping ? null : () => controller.load(force: true),
                  icon: const Icon(Remix.refresh_line),
                ),
              ],
            ),
            body: SafeArea(
              child: Column(
                children: [
                  if (controller.loading.value) const LinearProgressIndicator(),
                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 960),
                        child: LayoutBuilder(
                          builder: (context, bounds) => SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Choose Your Investment Plan',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  'Select a subscription plan to unlock eligible investment opportunities.',
                                ),
                                const SizedBox(height: 18),
                                if (controller.hasActivePlan && controller.isExpiringSoon)
                                  _buildExpiringSoonBanner()
                                else if (controller.isExpired)
                                  _buildExpiredBanner(),
                                if (controller.hasActivePlan)
                                  _buildCurrentPlanCard()
                                else if (controller.isExpired)
                                  _buildExpiredPlanCard()
                                else if (!widget.onboarding)
                                  _buildNoPlanCard(),
                                if (controller.error.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12,
                                    ),
                                    child: Text(
                                      controller.error.value,
                                      style: const TextStyle(
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ),
                                if (periodToggle)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Wrap(
                                      spacing: 8,
                                      children: [
                                        for (final entry in {
                                          0: 'All Plans',
                                          1: 'Monthly',
                                          12: 'Yearly',
                                        }.entries)
                                          ChoiceChip(
                                            label: Text(entry.value),
                                            selected: period == entry.key,
                                            onSelected: buying
                                                ? null
                                                : (_) => setState(
                                                      () => period = entry.key,
                                                    ),
                                          ),
                                      ],
                                    ),
                                  ),
                                if (plans.isEmpty &&
                                    !controller.loading.value) ...[
                                  const Icon(
                                    Remix.file_list_3_line,
                                    size: 40,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'No subscription plans are available right now. You can continue and choose a plan later.',
                                    textAlign: TextAlign.center,
                                  ),
                                  TextButton(
                                    onPressed:
                                        buying ? null : () => controller.load(force: true),
                                    child: const Text('Retry'),
                                  ),
                                ],
                                Wrap(
                                  spacing: 16,
                                  runSpacing: 16,
                                  children: [
                                    for (final plan in visible)
                                      SizedBox(
                                        width: bounds.maxWidth >= 720
                                            ? (bounds.maxWidth - 56) / 2
                                            : bounds.maxWidth - 40,
                                        child: SubscriptionPlanCard(
                                          plan: plan,
                                          disabled: buying || skipping,
                                          onChoose: () => choose(plan),
                                        ),
                                      ),
                                  ],
                                ),
                                if (buying)
                                  const Padding(
                                    padding: EdgeInsets.all(16),
                                    child: Text(
                                      'Complete secure Razorpay Checkout. If you cancelled, you can try again or skip.',
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
                  if (widget.onboarding)
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 960),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              OutlinedButton(
                                onPressed: buying || skipping ? null : skip,
                                child: Text(
                                  skipping ? 'Continuing…' : 'Skip for Now',
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'You can purchase a subscription anytime from your profile.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 12),
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

  Widget _buildExpiringSoonBanner() {
    final remaining = controller.remainingDays;
    final endDate = controller.currentEndDate;
    final expiryFormatted = endDate != null ? DateFormatter.formatDate(endDate) : '';
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.badgeAmberBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x7FF59E0B)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Remix.time_line, color: AppColors.badgeAmberText, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Subscription Expiring Soon',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.badgeAmberText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your ${controller.currentPlanName} subscription expires in $remaining day${remaining == 1 ? '' : 's'} on $expiryFormatted. Renew now to maintain uninterrupted access to eligible investment projects.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF78350F),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x66EF4444)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Remix.error_warning_line, color: AppColors.error, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Subscription Expired',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: AppColors.error,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your ${controller.currentPlanName} subscription has expired${expiryFormatted.isNotEmpty ? ' on $expiryFormatted' : ''}. Renew your plan now to continue accessing eligible investment projects.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF7F1D1D),
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

  Widget _buildCurrentPlanCard() {
    final isExpiring = controller.isExpiringSoon;
    final startDate = controller.currentStartDate;
    final endDate = controller.currentEndDate;
    final startStr = startDate != null ? DateFormatter.formatDate(startDate) : null;
    final endStr = endDate != null ? DateFormatter.formatDate(endDate) : null;
    final remaining = controller.remainingDays;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isExpiring ? AppColors.warning : const Color(0x4D00854B),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    controller.currentPlanName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isExpiring ? AppColors.badgeAmberBg : AppColors.badgeGreenBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isExpiring ? Remix.time_line : Remix.checkbox_circle_line,
                        size: 14,
                        color: isExpiring ? AppColors.badgeAmberText : AppColors.badgeGreenText,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isExpiring ? 'Expiring Soon' : 'Active',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isExpiring ? AppColors.badgeAmberText : AppColors.badgeGreenText,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (startStr != null) ...[
              Row(
                children: [
                  const Icon(Remix.calendar_line, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'Started: $startStr',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            if (endStr != null) ...[
              Row(
                children: [
                  const Icon(Remix.time_line, size: 16, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text(
                    'Expires: $endStr ($remaining day${remaining == 1 ? '' : 's'} remaining)',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isExpiring ? FontWeight.w600 : FontWeight.normal,
                      color: isExpiring ? AppColors.badgeAmberText : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
            ],
            const SizedBox(height: 8),
            Text(
              isExpiring
                  ? 'Renew your subscription below to ensure uninterrupted access.'
                  : 'You have full access to eligible investment opportunities for this tier.',
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiredPlanCard() {
    final endDate = controller.currentEndDate;
    final endStr = endDate != null ? DateFormatter.formatDate(endDate) : null;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.badgeRedBg, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    controller.currentPlanName,
                    style: const TextStyle(
                      fontSize: 18,
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
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Remix.error_warning_line, size: 14, color: AppColors.badgeRedText),
                      SizedBox(width: 4),
                      Text(
                        'Expired',
                        style: TextStyle(
                          fontSize: 12,
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
            if (endStr != null) ...[
              Row(
                children: [
                  const Icon(Remix.calendar_close_line, size: 16, color: AppColors.error),
                  const SizedBox(width: 6),
                  Text(
                    'Expired on: $endStr',
                    style: const TextStyle(fontSize: 13, color: AppColors.error, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            const Text(
              'Your access to eligible investment projects has ended. Choose a plan below to renew.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoPlanCard() {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.border),
      ),
      child: const Padding(
        padding: EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'No Active Subscription',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Choose a subscription plan below to unlock eligible investment opportunities.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

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
    final features = rules['features'] is List
        ? (rules['features'] as List).map((v) => v.toString()).toList()
        : <String>[];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  plan.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (rules['recommended'] == true ||
                    rules['isRecommended'] == true)
                  const Chip(
                    label: Text('Recommended'),
                    avatar: Icon(
                      Remix.star_fill,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              plan.formattedPrice,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            Text(
              'Duration: ${plan.durationMonths} ${plan.durationMonths == 1 ? 'month' : 'months'}',
            ),
            const SizedBox(height: 12),
            Text(
              'Investment eligibility: ${plan.formattedRange}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            for (final benefit in {...plan.benefits, ...features})
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Remix.check_line,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(benefit)),
                  ],
                ),
              ),
            const SizedBox(height: 18),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              onPressed: disabled ? null : onChoose,
              child: const Text('Choose Plan'),
            ),
          ],
        ),
      ),
    );
  }
}

class SubscriptionProfileCard extends StatefulWidget {
  const SubscriptionProfileCard({super.key});

  @override
  State<SubscriptionProfileCard> createState() =>
      _SubscriptionProfileCardState();
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
