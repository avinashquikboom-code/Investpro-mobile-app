import '../utils/display_value.dart';

enum TransactionType {
  investment,
  returnReceived,
  withdrawal,
  deposit,
  refund,
  fee,
}

class TransactionModel {
  final String id;
  final TransactionType type;
  final String title;
  final String subtitle;
  final double amount;
  final DateTime date;
  final String direction;
  final String status; // 'Completed', 'Processing', 'Failed'
  final String? projectId;
  final String? projectName;
  final String referenceId;

  const TransactionModel({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.date,
    this.status = 'Completed',
    this.direction = '',
    this.projectId,
    this.projectName,
    required this.referenceId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'subtitle': subtitle,
      'amount': amount,
      'date': date.toIso8601String(),
      'status': status,
      'direction': direction,
      'projectId': projectId,
      'projectName': projectName,
      'referenceId': referenceId,
    };
  }

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    return TransactionModel(
      id: json['id'] as String,
      type: TransactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => TransactionType.investment,
      ),
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      status: json['status'] as String? ?? 'Completed',
      direction: json['direction'] as String? ?? '',
      projectId: json['projectId'] as String?,
      projectName: DisplayValue.text(json['projectName']),
      referenceId: DisplayValue.reference(
        json['transactionNumber'] ??
            json['transactionReference'] ??
            json['referenceId'] ??
            json['reference'],
        internalId: json['id'],
      ),
    );
  }
}
