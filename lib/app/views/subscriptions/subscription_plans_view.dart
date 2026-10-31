import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/subscription_controller.dart';
import '../../models/subscription_plan_model.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_colors.dart';

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
    controller.load();
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
    Get.snackbar(
      'Subscription Activated',
      'Your plan is active. Eligible investment opportunities are now available.',
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

        return PopScope(
          canPop: !widget.onboarding && !buying && !skipping,
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: !widget.onboarding,
              title: Text(widget.onboarding ? 'Investment Plans' : 'My Plan'),
              actions: [
                IconButton(
                  tooltip: 'Refresh plans',
                  onPressed: buying || skipping ? null : controller.load,
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
                                if (controller.hasActivePlan)
                                  Card(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Current plan: ${controller.current.value!['plan']?['name'] ?? 'Active Plan'}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'Expires: ${controller.current.value!['endDate'].toString().split('T').first}',
                                          ),
                                          const Text(
                                            'You can renew your plan or choose another available plan.',
                                          ),
                                        ],
                                      ),
                                    ),
                                  )
                                else if (!widget.onboarding)
                                  const Card(
                                    child: Padding(
                                      padding: EdgeInsets.all(16),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'No Active Subscription',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'Choose a plan to access eligible investment projects.',
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
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
                                        buying ? null : controller.load,
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
    controller.load();
  }

  @override
  Widget build(BuildContext context) => Obx(() => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Subscription / My Plan',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (controller.loading.value)
                const LinearProgressIndicator()
              else if (controller.hasActivePlan) ...[
                Text(
                  '${controller.current.value!['plan']?['name'] ?? 'Active Plan'}',
                ),
                Text(
                  'Expires: ${controller.current.value!['endDate'].toString().split('T').first}',
                ),
              ] else ...[
                const Text('No Active Plan'),
                const Text('No Active Subscription'),
                const Text(
                  'Choose a plan to access eligible investment projects.',
                ),
              ],
              TextButton.icon(
                onPressed: () => Get.toNamed(AppRoutes.subscriptionPlans),
                icon: const Icon(Remix.vip_crown_line),
                label: Text(
                  controller.hasActivePlan
                      ? 'Renew or Upgrade Subscription'
                      : 'Explore Subscription Plans',
                ),
              ),
            ],
          ),
        ),
      ));
}
