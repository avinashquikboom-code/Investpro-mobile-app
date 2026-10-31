import '../utils/display_value.dart';
class WithdrawalModel {
  final String id;
  final double amount;
  final String bankName;
  final String accountNumber;
  final DateTime requestDate;
  final String status; // 'Processing', 'Completed', 'Rejected'
  final String referenceId;

  const WithdrawalModel({
    required this.id,
    required this.amount,
    required this.bankName,
    required this.accountNumber,
    required this.requestDate,
    this.status = 'Processing',
    required this.referenceId,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'bankName': bankName,
      'accountNumber': accountNumber,
      'requestDate': requestDate.toIso8601String(),
      'status': status,
      'referenceId': referenceId,
    };
  }

  factory WithdrawalModel.fromJson(Map<String, dynamic> json) {
    return WithdrawalModel(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      bankName: json['bankName'] as String,
      accountNumber: json['accountNumber'] as String,
      requestDate: DateTime.parse(json['requestDate'] as String),
      status: json['status'] as String? ?? 'Processing',
      referenceId: DisplayValue.reference(json['referenceId'], internalId: json['id']),
    );
  }
}
