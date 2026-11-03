import '../utils/currency_formatter.dart';
import '../utils/display_value.dart';
import '../services/investment_calculator.dart';

class InvestmentModel {
  final Map<String, String> recordIds;
  final Map<String, dynamic> financials;
  double get totalInterestCredited => CurrencyFormatter.number(financials['totalInterestCredited']);
  double get actualHourlyInterestCredited => CurrencyFormatter.number(financials['actualHourlyInterestCredited']);
  double get accruedNotCredited => CurrencyFormatter.number(financials['accruedNotCredited']);
  double get remainingProjectedInterest => CurrencyFormatter.number(financials['remainingProjectedInterest']);
  double get outstandingPrincipal => CurrencyFormatter.number(financials['outstandingPrincipal']);
  double get finalSettlementAmount => CurrencyFormatter.number(financials['finalSettlementAmount']);
  bool get principalRepaymentCompleted => financials['principalRepaymentCompleted'] == true;
  final String id;
  final String reference;
  final String projectId;
  final String projectName;
  final String? projectCity;
  final String? projectImageUrl;
  final DateTime? projectUpdatedAt;
  String get projectCityLabel => projectCity?.trim().isNotEmpty == true ? projectCity!.trim() : 'Location not specified';
  final String iconType;
  final double investedAmount;
  final double returnRatePercent;
  final int durationMonths;
  final double expectedReturn;
  final double maturityAmount;
  double get monthlyProjectedReturn => financials['monthlyProjectedReturn'] != null
      ? CurrencyFormatter.number(financials['monthlyProjectedReturn'])
      : durationMonths > 0 ? expectedReturn / durationMonths : 0;
  double get dailyProjectedReturn => financials['dailyProjectedReturn'] != null
      ? CurrencyFormatter.number(financials['dailyProjectedReturn'])
      : monthlyProjectedReturn / 30;
  double get hourlyProjectedReturn => financials['hourlyProjectedReturn'] != null
      ? CurrencyFormatter.number(financials['hourlyProjectedReturn'])
      : 0; // Live hourly credits are supplied by the backend payout policy.
  final DateTime startDate;
  final DateTime maturityDate;
  double get progressPercent =>
      InvestmentCalculator.progress(startDate, durationMonths, DateTime.now()) *
      100;
  final String status; // 'Active', 'Completed', 'Withdrawn'
  final String paymentMethod;

  const InvestmentModel({
    required this.id,
    this.recordIds = const {},
    this.financials = const {},
    this.reference = '',
    required this.projectId,
    required this.projectName,
    this.projectCity,
    this.projectImageUrl,
    this.projectUpdatedAt,
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
      recordIds: recordIds,
      financials: financials,
      id: id ?? this.id,
      reference: reference ?? this.reference,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      projectCity: projectCity,
      projectImageUrl: projectImageUrl,
      projectUpdatedAt: projectUpdatedAt,
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
      'recordIds': recordIds,
      'financials': financials,
      'reference': reference,
      'projectId': projectId,
      'projectName': projectName,
      'projectCity': projectCity,
      'projectImageUrl': projectImageUrl,
      'projectUpdatedAt': projectUpdatedAt?.toIso8601String(),
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
    DisplayValue.ids(json);
    return InvestmentModel(
      recordIds: DisplayValue.ids(json),
      financials: Map<String, dynamic>.from(json['financials'] as Map? ?? {}),
      id: json['id'] as String,
      reference: DisplayValue.reference(
        json['invoiceNumber'] ??
            json['investmentReference'] ??
            json['reference'],
        internalId: json['id'],
      ),
      projectId: json['projectId'] as String,
      projectName: DisplayValue.text(json['projectName']),
      projectCity: json['projectCity'] as String?,
      projectImageUrl: json['projectImageUrl'] as String?,
      projectUpdatedAt: DateTime.tryParse('${json['projectUpdatedAt']}'),
      iconType: json['iconType'] as String? ?? 'code',
      investedAmount: CurrencyFormatter.number(json['investedAmount']),
      returnRatePercent: CurrencyFormatter.number(json['returnRatePercent']),
      durationMonths: json['durationMonths'] as int,
      expectedReturn: CurrencyFormatter.number(json['expectedReturn']),
      maturityAmount: CurrencyFormatter.number(json['maturityAmount']),
      startDate: DateTime.parse(json['startDate'] as String),
      maturityDate: DateTime.parse(json['maturityDate'] as String),
      progressPercent: (json['progressPercent'] as num).toDouble(),
      status: json['status'] as String? ?? 'Active',
      paymentMethod: json['paymentMethod'] as String? ?? 'UPI',
    );
  }
}
