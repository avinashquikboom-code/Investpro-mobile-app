import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';

import '../models/return_model.dart';
import '../services/demo_repository.dart';

class ReturnsController extends GetxController {
  final DemoRepository _repo;

  ReturnsController(this._repo);

  final RxString selectedPeriod =
      'Monthly'.obs; // 'Monthly', 'Quarterly', 'Yearly'

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
  }
}
