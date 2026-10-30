import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';

import '../../controllers/returns_controller.dart';
import '../../services/api_service.dart';
import '../../services/demo_repository.dart';
import '../../services/local_storage_service.dart';
import '../../utils/currency_formatter.dart';
import '../../widgets/custom_app_bar.dart';

class ReturnsWithdrawalView extends StatefulWidget {
  final String? projectId;
  const ReturnsWithdrawalView({super.key, this.projectId});
  @override
  State<ReturnsWithdrawalView> createState() => _ReturnsWithdrawalViewState();
}

class _ReturnsWithdrawalViewState extends State<ReturnsWithdrawalView> {
  final amount = TextEditingController();
  Map<String, dynamic>? wallet, workspace;
  String? projectId, bankId, error;
  bool loading = true, submitting = false;
  String? retryKey, retryFingerprint;
  List<Map<String, dynamic>> get projects =>
      (workspace?['projects'] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
  List<Map<String, dynamic>> get banks => (wallet?['banks'] as List? ?? [])
      .where((e) => e['isVerified'] == true)
      .map((e) => Map<String, dynamic>.from(e))
      .toList();
  String get available => projectId == null
      ? '${workspace?['summary']?['totalWithdrawable'] ?? '0.00'}'
      : '${projects.firstWhereOrNull((p) => p['projectId'] == projectId)?['availableToWithdraw'] ?? '0.00'}';
  double number(dynamic value) => double.tryParse('$value') ?? 0;
  String money(dynamic value) =>
      CurrencyFormatter.format(number(value), showDecimals: true);
  @override
  void initState() {
    super.initState();
    projectId = widget.projectId;
    load();
  }

  @override
  void dispose() {
    amount.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() => loading = true);
    try {
      final api = Get.find<ApiService>();
      final data = await Future.wait([
        api.getWallet(),
        api.getReturnsWorkspace('monthly'),
      ]);
      if (!mounted) return;
      setState(() {
        wallet = data[0];
        workspace = data[1];
        error = null;
        bankId =
            banks.firstWhereOrNull((b) => b['isPrimary'] == true)?['id'] ??
            banks.firstOrNull?['id'];
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => error = 'Unable to load eligible returns and verified banks. Please retry.',
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  BigInt? cents(String text) {
    if (!RegExp(r'^\d{1,16}(\.\d{1,2})?$').hasMatch(text)) return null;
    final parts = text.split('.');
    return BigInt.parse(parts[0]) * BigInt.from(100) +
        BigInt.parse(parts.length == 1 ? '0' : parts[1].padRight(2, '0'));
  }

  Future<void> submit() async {
    if (submitting) return;
    final raw = amount.text.trim(), value = cents(amount.text.trim());
    final minimum = cents('${wallet?['minimumWithdrawal'] ?? '100'}');
    final maximum = wallet?['maximumWithdrawal'] == null
        ? null
        : cents('${wallet!['maximumWithdrawal']}');
    if (value == null ||
        value <= BigInt.zero ||
        value > (cents(available) ?? BigInt.zero) ||
        (minimum != null && value < minimum) ||
        (maximum != null && value > maximum) ||
        bankId == null) {
      setState(
        () => error = 'Enter an amount within your eligible balance and configured limits, and select a verified bank.',
      );
      return;
    }
    setState(() {
      submitting = true;
      error = null;
    });
    try {
      final userId = Get.find<DemoRepository>().currentUser.value.id;
      final storage = Get.isRegistered<LocalStorageService>()
          ? Get.find<LocalStorageService>()
          : null;
      final storeKey = 'returns-withdrawal-pending-$userId';
      final fingerprint = '$value|${projectId ?? 'all'}|$bankId';
      final previous = storage?.read(storeKey);
      if (previous is Map && previous['fingerprint'] == fingerprint) {
        retryKey = previous['key'] as String?;
      } else if (retryFingerprint != fingerprint) {
        retryKey = null;
      }
      retryFingerprint = fingerprint;
      retryKey ??=
          'returns-${DateTime.now().microsecondsSinceEpoch}-${Random.secure().nextInt(1 << 32)}';
      await storage?.write(storeKey, {
        'fingerprint': fingerprint,
        'key': retryKey,
      });
      final result = await Get.find<ApiService>().createWithdrawal(
        amount: 0,
        exactAmount: raw,
        bankAccountId: bankId,
        projectId: projectId,
        returnsOnly: true,
        idempotencyKey: retryKey,
      );
      if (result == null) throw StateError('Missing withdrawal response');
      await storage?.remove(storeKey);
      await Get.find<ReturnsController>().refreshData();
      if (mounted) {
        Get.back();
        Get.snackbar(
          'Withdrawal requested',
          'Funds are reserved pending review. This is not a completed bank payout.',
        );
      }
    } catch (e) {
      final message = e is DioException ? e.response?.data : null;
      if (mounted) {
        setState(
          () => error = message is Map && message['message'] is String
              ? message['message']
              : 'Request could not be confirmed. Retry with the same amount to safely recover it.',
        );
      }
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: const CustomAppBar(title: 'Withdraw returns', showBackButton: true),
    body: SafeArea(
      child: loading
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (error != null) ...[
                      Text(
                        error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                      TextButton(
                        onPressed: submitting ? null : load,
                        child: const Text('Refresh balances'),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (workspace != null && wallet != null) ...[
                      Text(
                        'Available settled profit',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        money(available),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Future schedules and investment principal are excluded. Verified KYC and bank review are required.',
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        initialValue: projectId ?? 'all',
                        isExpanded: true,
                        decoration: const InputDecoration(labelText: 'Project'),
                        items: [
                          const DropdownMenuItem(
                            value: 'all',
                            child: Text('All Projects'),
                          ),
                          ...projects.map(
                            (p) => DropdownMenuItem(
                              value: '${p['projectId']}',
                              child: Text(
                                '${p['projectName']}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                        onChanged: submitting
                            ? null
                            : (v) => setState(
                                () => projectId = v == 'all' ? null : v,
                              ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: amount,
                        enabled: !submitting,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Withdrawal amount',
                          prefixText: '₹ ',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Minimum ${money(wallet!['minimumWithdrawal'])}${wallet!['maximumWithdrawal'] == null ? '' : ' · Maximum ${money(wallet!['maximumWithdrawal'])}'}',
                      ),
                      const SizedBox(height: 16),
                      if (banks.isEmpty)
                        const Text(
                          'No verified bank account. Add an account in Profile and wait for review.',
                        )
                      else
                        DropdownButtonFormField<String>(
                          initialValue: bankId,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Verified bank account',
                          ),
                          items: banks
                              .map(
                                (b) => DropdownMenuItem(
                                  value: '${b['id']}',
                                  child: Text(
                                    '${b['bankName']} ${b['accountNumber']}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: submitting
                              ? null
                              : (v) => setState(() => bankId = v),
                        ),
                      const SizedBox(height: 20),
                      Text('Fee: ${money(wallet!['withdrawalFee'])}'),
                      Text(
                        'Net payout: ${money(max(0, number(amount.text) - number(wallet!['withdrawalFee'])))}',
                      ),
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: submitting || banks.isEmpty ? null : submit,
                        icon: submitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Remix.bank_line),
                        label: Text(
                          submitting
                              ? 'Submitting…'
                              : 'Submit Withdrawal Request',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
    ),
  );
}
