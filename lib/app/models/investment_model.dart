import '../utils/display_value.dart';
import '../services/investment_calculator.dart';

class InvestmentModel {
  final String id;
  final String reference;
  final String projectId;
  final String projectName;
  final String iconType;
  final double investedAmount;
  final double returnRatePercent;
  final int durationMonths;
  final double expectedReturn;
  final double maturityAmount;
  final DateTime startDate;
  final DateTime maturityDate;
  double get progressPercent =>
      InvestmentCalculator.progress(startDate, durationMonths, DateTime.now()) *
      100;
  final String status; // 'Active', 'Completed', 'Withdrawn'
  final String paymentMethod;

  const InvestmentModel({
    required this.id,
    this.reference = '',
    required this.projectId,
    required this.projectName,
    required this.iconType,
    required this.investedAmount,
    required this.returnRatePercent,
    required this.durationMonths,
    required this.expectedReturn,
    required this.maturityAmount,
    required this.startDate,
    required this.maturityDate,
    required double progressPercent,
    this.status = 'Active',
    this.paymentMethod = 'UPI',
  });

  int get principal => (investedAmount * 100).round();
  DateTime get start => startDate;
  InvestmentModel copyWith({
    String? id,
    String? reference,
    String? projectId,
    String? projectName,
    String? iconType,
    double? investedAmount,
    double? returnRatePercent,
    int? durationMonths,
    double? expectedReturn,
    double? maturityAmount,
    DateTime? startDate,
    DateTime? maturityDate,
    double? progressPercent,
    String? status,
    String? paymentMethod,
  }) {
    return InvestmentModel(
      id: id ?? this.id,
      reference: reference ?? this.reference,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      iconType: iconType ?? this.iconType,
      investedAmount: investedAmount ?? this.investedAmount,
      returnRatePercent: returnRatePercent ?? this.returnRatePercent,
      durationMonths: durationMonths ?? this.durationMonths,
      expectedReturn: expectedReturn ?? this.expectedReturn,
      maturityAmount: maturityAmount ?? this.maturityAmount,
      startDate: startDate ?? this.startDate,
      maturityDate: maturityDate ?? this.maturityDate,
      progressPercent: progressPercent ?? this.progressPercent,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reference': reference,
      'projectId': projectId,
      'projectName': projectName,
      'iconType': iconType,
      'investedAmount': investedAmount,
      'returnRatePercent': returnRatePercent,
      'durationMonths': durationMonths,
      'expectedReturn': expectedReturn,
      'maturityAmount': maturityAmount,
      'startDate': startDate.toIso8601String(),
      'maturityDate': maturityDate.toIso8601String(),
      'progressPercent': progressPercent,
      'status': status,
      'paymentMethod': paymentMethod,
    };
  }

  factory InvestmentModel.fromJson(Map<String, dynamic> json) {
    return InvestmentModel(
      id: json['id'] as String,
      reference: DisplayValue.reference(json['invoiceNumber'] ?? json['investmentReference'] ?? json['reference'], internalId: json['id']),
      projectId: json['projectId'] as String,
      projectName: json['projectName'] as String,
      iconType: json['iconType'] as String? ?? 'code',
      investedAmount: (json['investedAmount'] as num).toDouble(),
      returnRatePercent: (json['returnRatePercent'] as num).toDouble(),
      durationMonths: json['durationMonths'] as int,
      expectedReturn: (json['expectedReturn'] as num).toDouble(),
      maturityAmount: (json['maturityAmount'] as num).toDouble(),
      startDate: DateTime.parse(json['startDate'] as String),
      maturityDate: DateTime.parse(json['maturityDate'] as String),
      progressPercent: (json['progressPercent'] as num).toDouble(),
      status: json['status'] as String? ?? 'Active',
      paymentMethod: json['paymentMethod'] as String? ?? 'UPI',
    );
  }
}
