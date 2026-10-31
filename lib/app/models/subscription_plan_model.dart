import '../utils/currency_formatter.dart';

class SubscriptionPlanModel {
  final String id;
  final String name;
  final String slug;
  final double price;
  final double minInvestment;
  final double maxInvestment;
  final int durationMonths;
  final bool isActive;
  final List<String> benefits;
  final Map<String, dynamic>? accessRules;

  const SubscriptionPlanModel({
    required this.id,
    required this.name,
    required this.slug,
    required this.price,
    required this.minInvestment,
    required this.maxInvestment,
    required this.durationMonths,
    this.isActive = true,
    this.benefits = const [],
    this.accessRules,
  });

  String get formattedPrice => CurrencyFormatter.format(price);
  String get formattedMinInvestment => CurrencyFormatter.format(minInvestment);
  String get formattedMaxInvestment => CurrencyFormatter.format(maxInvestment);
  String get formattedRange =>
      '$formattedMinInvestment – $formattedMaxInvestment';
  String get formattedDuration => '$durationMonths Months';

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedBenefits = [];
    if (json['benefits'] is List) {
      parsedBenefits = (json['benefits'] as List)
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return SubscriptionPlanModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      minInvestment: (json['minInvestment'] as num?)?.toDouble() ?? 0.0,
      maxInvestment: (json['maxInvestment'] as num?)?.toDouble() ?? 0.0,
      durationMonths: (json['durationMonths'] as num?)?.toInt() ?? 12,
      isActive: json['isActive'] == true || json['status'] == 'ACTIVE',
      benefits: parsedBenefits,
      accessRules: json['accessRules'] is Map<String, dynamic>
          ? json['accessRules'] as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'slug': slug,
        'price': price,
        'minInvestment': minInvestment,
        'maxInvestment': maxInvestment,
        'durationMonths': durationMonths,
        'isActive': isActive,
        'benefits': benefits,
        'accessRules': accessRules,
      };
}

class SubscriptionEligibilityModel {
  final bool hasActiveSubscription;
  final bool isExpired;
  final bool subscriptionRequired;
  final double minInvestment;
  final double maxInvestment;
  final String? planName;
  final String? planSlug;
  final DateTime? expiresAt;
  final String status;

  const SubscriptionEligibilityModel({
    required this.hasActiveSubscription,
    required this.isExpired,
    this.subscriptionRequired = true,
    required this.minInvestment,
    required this.maxInvestment,
    this.planName,
    this.planSlug,
    this.expiresAt,
    this.status = 'NONE',
  });

  String get formattedRange =>
      '${CurrencyFormatter.format(minInvestment)} – ${CurrencyFormatter.format(maxInvestment)}';

  bool isEligibleForProject(double projectMinInvestment) {
    if (!hasActiveSubscription || isExpired) return false;
    return projectMinInvestment >= minInvestment &&
        projectMinInvestment <= maxInvestment;
  }

  factory SubscriptionEligibilityModel.fromJson(Map<String, dynamic> json) {
    final expires = json['expiresAt'] != null
        ? DateTime.tryParse(json['expiresAt'].toString())
        : null;

    final plan = json['plan'] is Map<String, dynamic>
        ? json['plan'] as Map<String, dynamic>
        : null;

    final name = json['planName']?.toString() ?? plan?['name']?.toString();
    final slug = json['planSlug']?.toString() ?? plan?['slug']?.toString();

    final minInv = (json['minInvestment'] as num?)?.toDouble() ??
        (plan?['minInvestment'] as num?)?.toDouble() ??
        0.0;
    final maxInv = (json['maxInvestment'] as num?)?.toDouble() ??
        (plan?['maxInvestment'] as num?)?.toDouble() ??
        0.0;

    return SubscriptionEligibilityModel(
      hasActiveSubscription: json['hasActiveSubscription'] == true ||
          json['status'] == 'ACTIVE',
      isExpired: json['isExpired'] == true || json['status'] == 'EXPIRED',
      minInvestment: minInv,
      maxInvestment: maxInv,
      planName: name,
      planSlug: slug,
      expiresAt: expires,
      status: json['status']?.toString() ?? 'NONE',
      subscriptionRequired: json['subscriptionRequired'] != false,
    );
  }

  Map<String, dynamic> toJson() => {
        'hasActiveSubscription': hasActiveSubscription,
        'isExpired': isExpired,
        'minInvestment': minInvestment,
        'maxInvestment': maxInvestment,
        'planName': planName,
        'planSlug': planSlug,
        'expiresAt': expiresAt?.toIso8601String(),
        'status': status,
      };
}

