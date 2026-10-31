import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';

import '../../controllers/returns_controller.dart';
import '../../routes/app_routes.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/custom_app_bar.dart';
import 'returns_withdrawal_view.dart';
import 'returns_overview.dart';
import '../../theme/app_colors.dart';

/// Live returns use one consistent server snapshot; schedules never become earnings.
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
    return d == null ? '—' : DateFormat('dd MMM yyyy').format(d.toLocal());
  }

  List<Map<String, dynamic>> rows(Map<String, dynamic> w, String field) =>
      (w[field] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
  Widget section(String title) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 14),
    child: Text(title, style: Theme.of(context).textTheme.titleLarge),
  );
  Widget card(Widget child) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(padding: const EdgeInsets.all(16), child: child),
  );
  Widget values(List<(String, String)> data) => LayoutBuilder(
    builder: (context, constraints) => Wrap(
      spacing: 12,
      runSpacing: 14,
      children: data
          .map(
            (d) => SizedBox(
              width: constraints.maxWidth < 300
                  ? constraints.maxWidth
                  : (constraints.maxWidth - 12) / 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(d.$1, style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 4),
                  Text(d.$2, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
          )
          .toList(),
    ),
  );
  void withdraw([String? projectId]) async {
    await Get.to(() => ReturnsWithdrawalView(projectId: projectId));
    if (mounted) controller.loadWorkspace();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Theme.of(context).brightness == Brightness.dark
        ? AppColors.backgroundDark
        : Colors.white,
    appBar: widget.isTab
        ? null
        : const CustomAppBar(title: 'Returns', showBackButton: true),
    body: SafeArea(
      top: widget.isTab,
      child: RefreshIndicator(
        onRefresh: controller.refreshData,
        child: Obx(() {
          final w = controller.workspace.value;
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  if (widget.isTab)
                    Text(
                      'Returns',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -.7,
                          ),
                    ),
                  const SizedBox(height: 6),
                  const Text('Track your investment returns and payouts'),
                  const SizedBox(height: 16),
                  if (controller.workspaceError.value.isNotEmpty)
                    card(
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(controller.workspaceError.value),
                          TextButton(
                            onPressed: controller.loadWorkspace,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  if (controller.workspaceLoading.value && w != null)
                    const LinearProgressIndicator(),
                  if (w == null && controller.workspaceError.value.isEmpty)
                    const _ReturnsSkeleton(),
                  if (w != null) ...content(w),
                ],
              ),
            ),
          );
        }),
      ),
    ),
  );
  List<Widget> content(Map<String, dynamic> w) => [
    ReturnsOverview(
      snapshot: w,
      period: controller.selectedPeriod.value,
      onPeriod: controller.setPeriod,
    ),
    const SizedBox(height: 20),
    card(
      ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: const Text('Balances & withdrawals'),
        subtitle: const Text(
          'Project returns, withdrawal requests and history',
        ),
        children: ledgerContent(w),
      ),
    ),
  ];

  List<Widget> ledgerContent(Map<String, dynamic> w) {
    final s = Map<String, dynamic>.from(w['summary'] as Map);
    return [
      card(
        values([
          ('Expected returns', money(s['totalExpectedReturns'])),
          ('Earned returns', money(s['totalEarnedReturns'])),
          ('Completed withdrawals', money(s['totalWithdrawn'])),
          ('Pending withdrawals', money(s['pendingWithdrawal'])),
          ('Upcoming profit', money(s['upcomingReturns'])),
          ('Profit credited to wallet', money(s['totalPaidReturns'])),
        ]),
      ),
      card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Available to withdraw',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              money(s['totalWithdrawable']),
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Settled profit only. Pending requests are already reserved.',
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: number(s['totalWithdrawable']) > 0
                  ? () => withdraw()
                  : null,
              icon: const Icon(Remix.bank_line),
              label: const Text('Request Withdrawal'),
            ),
          ],
        ),
      ),
      section('Project-wise Returns'),
      if (rows(w, 'projects').isEmpty)
        card(const Text('No funded projects yet.')),
      ...rows(w, 'projects').map(
        (p) => card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${p['projectName']}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${p['projectStatus']} · ${(p['investmentIds'] as List).length} investment(s)',
              ),
              const SizedBox(height: 14),
              values([
                ('Invested', money(p['investedAmount'])),
                ('Expected ROI (weighted)', '${p['expectedRoi']}%'),
                ('Tenure (months)', (p['tenureMonths'] as List).join(', ')),
                ('Expected returns', money(p['expectedReturns'])),
                ('Earned returns', money(p['earnedReturns'])),
                ('Paid to wallet', money(p['paidReturns'])),
                ('Upcoming profit', money(p['upcomingReturns'])),
                ('Available', money(p['availableToWithdraw'])),
                ('Pending returns withdrawal', money(p['pendingWithdrawal'])),
                ('Next return', date(p['nextReturnDate'])),
              ]),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => Get.toNamed(
                      AppRoutes.projectDetails,
                      arguments: '${p['projectId']}',
                    ),
                    icon: const Icon(Remix.eye_line),
                    label: const Text('View Details'),
                  ),
                  FilledButton(
                    onPressed: number(p['availableToWithdraw']) > 0
                        ? () => withdraw('${p['projectId']}')
                        : null,
                    child: const Text('Request Withdrawal'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      section('Upcoming Payouts'),
      if (rows(w, 'upcoming').isEmpty) card(const Text('No upcoming payouts.')),
      ...rows(w, 'upcoming').map(
        (p) => card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${p['projectName']}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${date(p['dueDate'])} · ${p['overdue'] == true ? 'Awaiting credit' : p['status']}',
              ),
              Text('Expected profit: ${money(p['profitAmount'])}'),
              if (number(p['principalAmount']) > 0)
                Text(
                  'Principal scheduled separately: ${money(p['principalAmount'])}',
                ),
              const Text('Not yet earned or withdrawable.'),
            ],
          ),
        ),
      ),
      section('Payout History'),
      if (rows(w, 'payouts').isEmpty)
        card(
          const Text('No profit credited yet. Future schedules appear above.'),
        ),
      ...rows(w, 'payouts').map(
        (p) => card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${p['projectName']}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text('${date(p['date'])} · Credited'),
              Text('Earned profit: ${money(p['profitAmount'])}'),
              if (number(p['principalAmount']) > 0)
                Text('Principal returned: ${money(p['principalAmount'])}'),
              Text('Wallet credit: ${money(p['totalAmount'])}'),
              SelectableText('${p['reference']}'),
            ],
          ),
        ),
      ),
      section('Withdrawal History'),
      if (rows(w, 'withdrawals').isEmpty)
        card(const Text('No withdrawal requests yet.')),
      ...rows(w, 'withdrawals').map(
        (r) => card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${money(r['amount'])} · ${r['status']}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(date(r['requestedAt'])),
              ...(r['allocations'] as List? ?? []).map(
                (a) => Text(
                  '${a['projectName'] ?? 'Other wallet credit'} · ${a['component'].toString().replaceAll('_', ' ').toLowerCase()} · ${money(a['amount'])}${a['reconstructed'] == true ? ' (FIFO reconstructed)' : ''}',
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 8),
      Text(
        '${s['earningsRule']}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      Text(
        'Updated ${date(w['asOf'])}',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ];
  }
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
