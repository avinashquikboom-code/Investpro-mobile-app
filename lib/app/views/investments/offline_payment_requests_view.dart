import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_service.dart';
import '../../controllers/investment_controller.dart';
import 'offline_payment_form.dart';
import '../../services/demo_repository.dart';
import '../../theme/app_colors.dart';

class OfflinePaymentRequestsView extends StatefulWidget {
  const OfflinePaymentRequestsView({super.key});
  @override
  State<OfflinePaymentRequestsView> createState() =>
      _OfflinePaymentRequestsViewState();
}

class _OfflinePaymentRequestsViewState
    extends State<OfflinePaymentRequestsView> {
  final api = Get.find<ApiService>();
  List<dynamic> rows = [];
  String? error;
  int page = 1, pages = 1;
  bool loading = false;
  @override
  void initState() {
    super.initState();
    final target = Get.arguments;
    load().then((_) {
      if (mounted && target is String) detail(target);
    });
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final response = await api.object(
        '/mobile/investments/offline-payment?page=$page&limit=20',
      );
      if (mounted) {
        setState(() {
          rows = response['requests'] as List;
          pages = response['meta']['totalPages'] as int;
        });
      }
      try {
        await Get.find<DemoRepository>().syncFromBackend();
      } catch (_) {}
    } catch (_) {
      if (mounted) {
        setState(
          () => error = 'Unable to load payment requests. Pull to retry.',
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> detail(String id) async {
    try {
      final row = await api.object('/mobile/investments/offline-payment/$id');
      if (!mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (context) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.8,
          builder: (context, scroll) => ListView(
            controller: scroll,
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                row['investment']['project']['title'].toString(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              SelectableText(
                'Request: ${row['id']}\n₹${row['investment']['amount']}\nUTR: ${row['utrNumber']}\nStatus: ${row['status']}\nSubmitted: ${row['submittedAt']}',
              ),
              if (row['rejectionReason'] != null)
                Text('Rejection reason: ${row['rejectionReason']}'),
              if (row['status'] == 'REJECTED')
                const Text(
                  'You can resubmit corrected proof for this same transfer. Contact support if the reference is incorrect. Do not pay again or reuse this transfer for another investment.',
                ),
              if (row['status'] == 'REJECTED')
                FilledButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await Get.to(
                      () => Scaffold(
                        appBar: AppBar(
                          title: const Text('Resubmit Payment Proof'),
                        ),
                        body: SafeArea(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: OfflinePaymentForm(
                              settings: Map<String, dynamic>.from(
                                row['destination'] as Map,
                              ),
                              controller: Get.find<InvestmentController>(),
                              resubmission: row,
                            ),
                          ),
                        ),
                      ),
                    );
                    if (mounted) load();
                  },
                  child: const Text('Resubmit Corrected Proof'),
                ),
              if (row['status'] == 'PENDING_VERIFICATION')
                const Text(
                  'Awaiting verification of actual bank receipt. Your investment is not active yet.',
                ),
              TextButton(
                onPressed: () async {
                  try {
                    final result = await api.object(
                      '/mobile/investments/offline-payment/$id/proof',
                    );
                    if (!await launchUrl(
                      Uri.parse(result['url']),
                      mode: LaunchMode.externalApplication,
                    )) {
                      throw Exception();
                    }
                  } catch (_) {
                    Get.snackbar(
                      'Payment proof',
                      'Unable to open proof. Please retry.',
                    );
                  }
                },
                child: const Text('View submitted proof'),
              ),
              const Text(
                'History',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              for (final event in row['history'] as List? ?? [])
                Text('${event['createdAt']} · ${event['action']}'),
            ],
          ),
        ),
      );
    } catch (_) {
      if (mounted) setState(() => error = 'Unable to load request details.');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Offline Payment Requests'),
      actions: [
        IconButton(
          onPressed: loading ? null : load,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 700),
          child: Column(
            children: [
              if (loading) const LinearProgressIndicator(),
              if (error != null) Text(error!),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (rows.isEmpty && !loading)
                        const Text('No offline payment requests.'),
                      for (final row in rows)
                        Card(
                          child: InkWell(
                            onTap: () => detail(row['id'].toString()),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${row['investment']['project']['title']}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '₹${row['investment']['amount']} · ${row['utrNumber']}',
                                  ),
                                  Text(
                                    '${row['status']}',
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                    ),
                                  ),
                                  if (row['rejectionReason'] != null)
                                    Text('Reason: ${row['rejectionReason']}'),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: loading || page <= 1
                        ? null
                        : () {
                            page--;
                            load();
                          },
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('Page $page of ${pages < 1 ? 1 : pages}'),
                  IconButton(
                    onPressed: loading || page >= pages
                        ? null
                        : () {
                            page++;
                            load();
                          },
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
