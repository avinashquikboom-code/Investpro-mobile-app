import '../services/investment_calculator.dart';

class ProjectModel {
  final String id;
  final String name;
  final String category;
  final String? categoryId;
  final String iconType; // 'code', 'mobile', 'gear'
  final double targetAmount;
  final double raisedAmount;
  final double returnRatePercent;
  final int durationMonths;
  final String status; // 'Active', 'Completed'
  final String description;
  final String riskLevel; // 'Low', 'Moderate', 'High'
  final DateTime createdAt;

  const ProjectModel({
    required this.id,
    required this.name,
    required this.category,
    this.categoryId,
    required this.iconType,
    required this.targetAmount,
    required this.raisedAmount,
    required this.returnRatePercent,
    required this.durationMonths,
    this.status = 'Active',
    required this.description,
    this.riskLevel = 'Moderate',
    required this.createdAt,
  });

  int get rate => returnRatePercent.round();
  int get months => durationMonths;
  int get target => (targetAmount * 100).round();
  int get baseRaised => (raisedAmount * 100).round();
  bool get completed => status == 'Completed';
  double get progressPercentage {
    if (targetAmount <= 0) return 0;
    final pct = (raisedAmount / targetAmount) * 100;
    return pct > 100 ? 100 : pct;
  }

  double calculateExpectedReturn(double amount) {
    return InvestmentCalculator.calculate(
      principal: amount,
      returnRatePercent: returnRatePercent,
      durationMonths: durationMonths,
    ).expectedTotalReturn;
  }

  double calculateMonthlyReturn(double amount) {
    if (durationMonths <= 0) return 0;
    return calculateExpectedReturn(amount) / durationMonths;
  }

  ProjectModel copyWith({
    String? id,
    String? name,
    String? category,
    String? categoryId,
    String? iconType,
    double? targetAmount,
    double? raisedAmount,
    double? returnRatePercent,
    int? durationMonths,
    String? status,
    String? description,
    String? riskLevel,
    DateTime? createdAt,
  }) {
    return ProjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      categoryId: categoryId ?? this.categoryId,
      iconType: iconType ?? this.iconType,
      targetAmount: targetAmount ?? this.targetAmount,
      raisedAmount: raisedAmount ?? this.raisedAmount,
      returnRatePercent: returnRatePercent ?? this.returnRatePercent,
      durationMonths: durationMonths ?? this.durationMonths,
      status: status ?? this.status,
      description: description ?? this.description,
      riskLevel: riskLevel ?? this.riskLevel,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category,
      'categoryId': categoryId,
      'iconType': iconType,
      'targetAmount': targetAmount,
      'raisedAmount': raisedAmount,
      'returnRatePercent': returnRatePercent,
      'durationMonths': durationMonths,
      'status': status,
      'description': description,
      'riskLevel': riskLevel,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ProjectModel.fromBackend(Map<String, dynamic> json) {
    final type = json['projectType'] as Map?;
    double number(String key) => num.tryParse('${json[key]}')?.toDouble() ?? 0;
    return ProjectModel(id: json['id'] as String, name: json['title'] as String? ?? '',
      category: type?['name'] as String? ?? '', categoryId: json['projectTypeId'] as String? ?? type?['id'] as String?,
      iconType: type?['icon'] as String? ?? 'folder', targetAmount: number('targetAmount'), raisedAmount: number('fundedAmount'),
      returnRatePercent: number('expectedRoi'), durationMonths: (json['tenureMonths'] as num?)?.toInt() ?? 0,
      status: json['status'] == 'ACTIVE' ? 'Active' : '${json['status']}', description: json['description'] as String? ?? '',
      riskLevel: json['riskLevel'] as String? ?? '', createdAt: DateTime.tryParse('${json['createdAt']}') ?? DateTime.fromMillisecondsSinceEpoch(0));
  }

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['id'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      categoryId: json['categoryId'] as String?,
      iconType: json['iconType'] as String,
      targetAmount: (json['targetAmount'] as num).toDouble(),
      raisedAmount: (json['raisedAmount'] as num).toDouble(),
      returnRatePercent: (json['returnRatePercent'] as num).toDouble(),
      durationMonths: json['durationMonths'] as int,
      status: json['status'] as String? ?? 'Active',
      description: json['description'] as String? ?? '',
      riskLevel: json['riskLevel'] as String? ?? 'Moderate',
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
