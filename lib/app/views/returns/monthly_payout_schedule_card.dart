import 'package:flutter/material.dart';
import '../../utils/currency_formatter.dart';
import '../../utils/date_formatter.dart';

class MonthlyPayoutScheduleCard extends StatelessWidget {
  final List<Map<String, dynamic>> schedules;
  const MonthlyPayoutScheduleCard({super.key, required this.schedules});

  String money(dynamic value) => CurrencyFormatter.format(
    num.tryParse('$value') ?? 0, showDecimals: true,
  );
  String date(dynamic value) {
    final parsed = DateTime.tryParse('$value');
    return parsed == null ? '—' : DateFormatter.formatDate(parsed.toLocal());
  }

  @override
  Widget build(BuildContext context) => Card(
    child: ExpansionTile(
      title: const Text('Monthly payout schedule'),
      subtitle: const Text('Interest each month; principal in the final payment'),
      children: [
        if (schedules.isEmpty)
          const Padding(padding: EdgeInsets.all(16), child: Text('No monthly payouts scheduled')),
        for (final item in schedules)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${item['projectName']} • Month ${item['installmentNumber']}'),
                Text('${date(item['dueDate'])} • ${item['status']}'),
                Wrap(spacing: 16, runSpacing: 4, children: [
                  Text('Interest: ${money(item['profitAmount'])}'),
                  Text('Principal: ${money(item['principalAmount'])}'),
                  Text('Total payment: ${money(item['totalAmount'])}'),
                ]),
                const Divider(),
              ],
            ),
          ),
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text('Scheduled payouts are projections. Only successfully confirmed payouts are credited and available to withdraw.'),
        ),
      ],
    ),
  );
}
