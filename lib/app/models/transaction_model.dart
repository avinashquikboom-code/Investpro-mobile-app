enum TransactionType { investment, returnReceived, withdrawal, deposit }

class TransactionModel {
  final String id;
  final TransactionType type;
  final String title;
  final String subtitle;
  final double amount;
  final DateTime date;
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
      projectId: json['projectId'] as String?,
      projectName: json['projectName'] as String?,
      referenceId:
          json['referenceId'] as String? ??
          'TXN-${DateTime.now().millisecondsSinceEpoch}',
    );
  }
}
