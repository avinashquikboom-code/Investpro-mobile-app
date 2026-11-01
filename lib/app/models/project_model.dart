import '../utils/display_value.dart';
import '../services/investment_calculator.dart';

class ProjectModel {
  final Map<String, String> recordIds;
  final String? location;
  final String? imageUrl;
  final int? investorCount;
  final bool hasFundingData;
  final bool hasReturnData;
  final double minInvestment;
  final double? maxInvestment;
  final double? fundingProgress;
  final String? city;
  String get cityLabel => city?.trim().isNotEmpty == true ? city!.trim() : 'Location not specified';
  String get locationLabel {
    final parts = [city?.trim(), location?.trim()]
        .whereType<String>()
        .where((value) => value.isNotEmpty);
    return parts.isEmpty ? 'Location not specified' : parts.join(' · ');
  }
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
  final DateTime? startDate, endDate, updatedAt;
  final DateTime createdAt;

  const ProjectModel({
    this.fundingProgress,
    this.city,
    this.startDate, this.endDate, this.updatedAt,
    this.location,
    this.imageUrl,
    this.investorCount,
    this.hasFundingData = true,
    this.hasReturnData = true,
    this.minInvestment = 0,
    this.maxInvestment,
    required this.id,
    this.recordIds = const {},
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

  String get statusLabel => status.isEmpty
      ? 'Unknown'
      : status[0].toUpperCase() + status.substring(1).toLowerCase();

  int get rate => returnRatePercent.round();
  int get months => durationMonths;
  int get target => (targetAmount * 100).round();
  int get baseRaised => (raisedAmount * 100).round();
  bool get completed => status == 'Completed';
  double get progressPercentage {
    final progress = fundingProgress ?? (targetAmount > 0 ? raisedAmount / targetAmount * 100 : 0);
    return progress.isFinite ? (progress.clamp(0, 100) * 100).round() / 100 : 0;
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
      fundingProgress: fundingProgress,
      city: city,
      startDate: startDate, endDate: endDate, updatedAt: updatedAt,
      location: location,
      imageUrl: imageUrl,
      investorCount: investorCount,
      hasFundingData: hasFundingData,
      hasReturnData: hasReturnData,
      minInvestment: minInvestment,
      maxInvestment: maxInvestment,
      recordIds: recordIds,
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
      'fundingProgress': fundingProgress,
      'city': city,
      'startDate': startDate?.toIso8601String(), 'endDate': endDate?.toIso8601String(), 'updatedAt': updatedAt?.toIso8601String(),
      'location': location,
      'imageUrl': imageUrl,
      'investorCount': investorCount,
      'hasFundingData': hasFundingData,
      'hasReturnData': hasReturnData,
      'minInvestment': minInvestment,
      'maxInvestment': maxInvestment,
      'id': id,
      'recordIds': recordIds,
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
    return ProjectModel(
      fundingProgress: json['fundingProgress'] == null
          ? null
          : num.tryParse('${json['fundingProgress']}')?.toDouble(),
      city: json['city'] as String?,
      startDate: DateTime.tryParse('${json['startDate']}'),
      endDate: DateTime.tryParse('${json['endDate']}'),
      updatedAt: DateTime.tryParse('${json['updatedAt']}'),
      location: json['location'] as String?,
      imageUrl: json['bannerUrl'] as String?,
      investorCount: (json['investorsCount'] as num?)?.toInt(),
      hasFundingData:
          num.tryParse('${json['targetAmount']}')?.isFinite == true &&
          num.tryParse('${json['fundedAmount']}')?.isFinite == true &&
          number('targetAmount') > 0 &&
          number('fundedAmount') >= 0,
      hasReturnData: num.tryParse('${json['expectedRoi']}')?.isFinite == true,
      minInvestment: number('minInvestment'),
      maxInvestment: json['maxInvestment'] == null
          ? null
          : number('maxInvestment'),
      recordIds: DisplayValue.ids(json),
      id: json['id'] as String,
      name: json['title'] as String? ?? '',
      category: type?['name'] as String? ?? '',
      categoryId: json['projectTypeId'] as String? ?? type?['id'] as String?,
      iconType: type?['icon'] as String? ?? 'folder',
      targetAmount: number('targetAmount'),
      raisedAmount: number('fundedAmount'),
      returnRatePercent: number('expectedRoi'),
      durationMonths: (json['tenureMonths'] as num?)?.toInt() ?? 0,
      status: json['status'] == 'ACTIVE' ? 'Active' : '${json['status']}',
      description: json['description'] as String? ?? '',
      riskLevel: json['riskLevel'] as String? ?? '',
      createdAt:
          DateTime.tryParse('${json['createdAt']}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      fundingProgress: json['fundingProgress'] == null
          ? null
          : num.tryParse('${json['fundingProgress']}')?.toDouble(),
      city: json['city'] as String?,
      startDate: DateTime.tryParse('${json['startDate']}'),
      endDate: DateTime.tryParse('${json['endDate']}'),
      updatedAt: DateTime.tryParse('${json['updatedAt']}'),
      location: json['location'] as String?,
      imageUrl: json['imageUrl'] as String?,
      investorCount: (json['investorCount'] as num?)?.toInt(),
      hasFundingData: json['hasFundingData'] as bool? ?? true,
      hasReturnData: json['hasReturnData'] as bool? ?? true,
      minInvestment: (json['minInvestment'] as num?)?.toDouble() ?? 0,
      maxInvestment: (json['maxInvestment'] as num?)?.toDouble(),
      recordIds: DisplayValue.ids(json),
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
