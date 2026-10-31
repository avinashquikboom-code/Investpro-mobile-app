import '../utils/display_value.dart';
class ReturnPayoutModel {
  final Map<String, String> recordIds;
  final String id;
  final String investmentId;
  final String projectName;
  final String monthYear; // e.g. "Apr 2026"
  final DateTime payoutDate;
  final double amount; // e.g. 1500
  final String status; // 'Received', 'Pending'
  final String periodType; // 'Monthly', 'Quarterly', 'Yearly'

  const ReturnPayoutModel({
    required this.id,
    this.recordIds = const {},
    required this.investmentId,
    required this.projectName,
    required this.monthYear,
    required this.payoutDate,
    required this.amount,
    required this.status,
    this.periodType = 'Monthly',
  });

  DateTime get date => payoutDate;
  bool get received => status == 'Received';
  int get minorAmount => (amount * 100).round();
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'recordIds': recordIds,
      'investmentId': investmentId,
      'projectName': projectName,
      'monthYear': monthYear,
      'payoutDate': payoutDate.toIso8601String(),
      'amount': amount,
      'status': status,
      'periodType': periodType,
    };
  }

  factory ReturnPayoutModel.fromJson(Map<String, dynamic> json) {
    return ReturnPayoutModel(
      recordIds: DisplayValue.ids(json),
      id: json['id'] as String,
      investmentId: json['investmentId'] as String,
      projectName: json['projectName'] as String,
      monthYear: json['monthYear'] as String,
      payoutDate: DateTime.parse(json['payoutDate'] as String),
      amount: (json['amount'] as num).toDouble(),
      status: json['status'] as String,
      periodType: json['periodType'] as String? ?? 'Monthly',
    );
  }
}
