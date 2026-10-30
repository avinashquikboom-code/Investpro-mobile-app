import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

import '../models/return_model.dart';
import '../services/demo_repository.dart';
import '../services/api_service.dart';

class ReturnChartPoint {
  final String label;
  final double amount;
  final DateTime date;
  final bool isCurrent;

  const ReturnChartPoint({
    required this.label,
    required this.amount,
    required this.date,
    this.isCurrent = false,
  });
}

class ReturnsController extends GetxController {
  final DemoRepository _repo;

  ReturnsController(this._repo);

  bool get isLive => _repo.isLive;
  final workspace = Rxn<Map<String, dynamic>>();
  final workspaceError = ''.obs;
  int _workspaceRequest = 0;
  Future<void> loadWorkspace() async {
    if (!isLive || !Get.isRegistered<ApiService>()) return;
    final version = ++_workspaceRequest;
    try {
      final result = await Get.find<ApiService>().getReturnsWorkspace(selectedPeriod.value);
      if (version != _workspaceRequest || isClosed) return;
      workspace.value = result; workspaceError.value = '';
    } catch (_) {
      if (version == _workspaceRequest && !isClosed) workspaceError.value = 'Unable to refresh returns. Please retry.';
    }
  }

  final RxString selectedPeriod =
      'Monthly'.obs; // 'Monthly', 'Quarterly', 'Yearly'
  final RxBool isRefreshing = false.obs;

  double get totalReturns => _repo.totalReturns;
  double get totalInvested => _repo.totalInvested;

  String get growthPercentage {
    if (totalInvested <= 0) return '+0%';
    final pct = (totalReturns / totalInvested) * 100;
    return '+${pct.toStringAsFixed(0)}%';
  }

  final investmentFilter = RxnString();
  List<ReturnPayoutModel> get records => _repo.returns
      .where(
        (r) =>
            investmentFilter.value == null ||
            r.investmentId == investmentFilter.value,
      )
      .toList();

  List<ReturnPayoutModel> get filteredReturns {
    final grouped = <String, List<ReturnPayoutModel>>{};
    for (final r in records) {
      final month = selectedPeriod.value == 'Yearly'
          ? 1
          : selectedPeriod.value == 'Quarterly'
          ? (r.payoutDate.month - 1) ~/ 3 * 3 + 1
          : r.payoutDate.month;
      final key = '${r.payoutDate.year}-$month-${r.status}';
      (grouped[key] ??= []).add(r);
    }
    return grouped.entries.map((e) {
      final first = e.value.first;
      final month = selectedPeriod.value == 'Yearly'
          ? 1
          : selectedPeriod.value == 'Quarterly'
          ? (first.payoutDate.month - 1) ~/ 3 * 3 + 1
          : first.payoutDate.month;
      final date = DateTime(first.payoutDate.year, month);
      final label = selectedPeriod.value == 'Yearly'
          ? '${date.year}'
          : selectedPeriod.value == 'Quarterly'
          ? 'Q${(month - 1) ~/ 3 + 1} ${date.year}'
          : DateFormat('MMM yyyy').format(date);
      return ReturnPayoutModel(
        id: e.key,
        investmentId: 'summary',
        projectName: 'Return summary',
        monthYear: label,
        payoutDate: date,
        amount:
            e.value.fold<int>(0, (s, r) => s + (r.amount * 100).round()) / 100,
        status: first.status,
      );
    }).toList()..sort((a, b) => b.payoutDate.compareTo(a.payoutDate));
  }

  List<ReturnPayoutModel> get payoutHistory =>
      List<ReturnPayoutModel>.from(records)
        ..sort((a, b) => b.payoutDate.compareTo(a.payoutDate));

  String get nextReturnDate {
    final pending =
        records
            .where(
              (r) =>
                  (r.status == 'Pending' || r.status == 'Scheduled') &&
                  !r.payoutDate.isBefore(DateTime.now()),
            )
            .toList()
          ..sort((a, b) => a.payoutDate.compareTo(b.payoutDate));
    return pending.isEmpty
        ? 'No future payouts'
        : DateFormat('dd MMM yyyy').format(pending.first.payoutDate);
  }

  ReturnPayoutModel? get nextReturnSchedule {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final pending = records
        .where(
          (r) =>
              (r.status == 'Pending' || r.status == 'Scheduled') &&
              !r.payoutDate.isBefore(today),
        )
        .toList()
      ..sort((a, b) => a.payoutDate.compareTo(b.payoutDate));
    return pending.isEmpty ? null : pending.first;
  }

  List<ReturnChartPoint> get chartPoints {
    final now = DateTime.now();
    final received = records
        .where((r) => r.status == 'Received' || r.status == 'Completed')
        .toList();

    DateTime anchor = DateTime(now.year, now.month, 1);
    if (received.isNotEmpty) {
      final latest = received.map((r) => r.payoutDate).reduce((a, b) => a.isAfter(b) ? a : b);
      if (latest.isAfter(anchor) || now.difference(latest).inDays > 180) {
        anchor = DateTime(latest.year, latest.month, 1);
      }
    }

    if (selectedPeriod.value == 'Yearly') {
      final points = <ReturnChartPoint>[];
      for (int i = 3; i >= 0; i--) {
        final year = anchor.year - i;
        final sum = received
            .where((r) => r.payoutDate.year == year)
            .fold<double>(0.0, (s, r) => s + r.amount);
        points.add(
          ReturnChartPoint(
            label: '$year',
            amount: sum,
            date: DateTime(year, 1, 1),
            isCurrent: i == 0,
          ),
        );
      }
      return points;
    }

    if (selectedPeriod.value == 'Quarterly') {
      final points = <ReturnChartPoint>[];
      final year = anchor.year;
      for (int q = 1; q <= 4; q++) {
        final startMonth = (q - 1) * 3 + 1;
        final endMonth = startMonth + 2;
        final sum = received
            .where((r) =>
                r.payoutDate.year == year &&
                r.payoutDate.month >= startMonth &&
                r.payoutDate.month <= endMonth)
            .fold<double>(0.0, (s, r) => s + r.amount);
        points.add(
          ReturnChartPoint(
            label: 'Q$q',
            amount: sum,
            date: DateTime(year, startMonth, 1),
            isCurrent: (anchor.month - 1) ~/ 3 + 1 == q,
          ),
        );
      }
      return points;
    }

    // Default: 'Monthly' (6 consecutive months)
    final points = <ReturnChartPoint>[];
    for (int i = 5; i >= 0; i--) {
      final d = DateTime(anchor.year, anchor.month - i, 1);
      final sum = received
          .where((r) =>
              r.payoutDate.year == d.year &&
              r.payoutDate.month == d.month)
          .fold<double>(0.0, (s, r) => s + r.amount);
      points.add(
        ReturnChartPoint(
          label: DateFormat('MMM').format(d),
          amount: sum,
          date: d,
          isCurrent: i == 0,
        ),
      );
    }
    return points;
  }

  String? get periodComparison {
    final points = chartPoints;
    if (points.length < 2) return null;
    final current = points.last.amount;
    final previous = points[points.length - 2].amount;
    if (previous > 0) {
      final diff = ((current - previous) / previous) * 100;
      final sign = diff >= 0 ? '+' : '';
      return '$sign${diff.toStringAsFixed(1)}%';
    }
    return null;
  }

  Future<void> refreshData() async {
    isRefreshing.value = true;
    try {
      await Future.wait([_repo.loadData(), loadWorkspace()]);
    } catch (_) {
      // Retain valid state safely
    } finally {
      isRefreshing.value = false;
    }
  }

  void inspect(ReturnPayoutModel group) {
    final items = records
        .where(
          (r) =>
              r.status == group.status &&
              r.payoutDate.year == group.payoutDate.year &&
              (selectedPeriod.value == 'Yearly' ||
                  (selectedPeriod.value == 'Quarterly'
                      ? (r.payoutDate.month - 1) ~/ 3 ==
                            (group.payoutDate.month - 1) ~/ 3
                      : r.payoutDate.month == group.payoutDate.month)),
        )
        .toList();
    Get.dialog(
      AlertDialog(
        title: Text('${group.monthYear} • ${group.status}'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: items
                .map(
                  (r) => ListTile(
                    title: Text(r.projectName),
                    subtitle: Text(
                      '${DateFormat('dd MMM yyyy').format(r.payoutDate)} • ${r.status}',
                    ),
                    trailing: Text('₹${r.amount.toStringAsFixed(2)}'),
                    onTap: () {
                      final txn = _repo.transactions
                          .where((t) => t.id == r.id)
                          .firstOrNull;
                      Get.dialog(
                        AlertDialog(
                          title: Text(
                            txn == null
                                ? 'Projected payout'
                                : 'Received transaction',
                          ),
                          content: Text(
                            'Reference: ${txn?.referenceId ?? r.id}\n${txn?.status ?? 'Pending • not yet received'}',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Close')),
        ],
      ),
    );
  }

  void setPeriod(String period) {
    selectedPeriod.value = period;
    loadWorkspace();
  }
}
