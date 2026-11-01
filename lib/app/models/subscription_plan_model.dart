import '../utils/display_value.dart';
import '../utils/currency_formatter.dart';

class SubscriptionPlanModel {
  final Map<String, String> recordIds;
  final String id;
  final String name;
  final String slug;
  final String? description;
  final double price;
  final double? originalPrice;
  final double? discount;
  final String currency;
  final double minInvestment;
  final double maxInvestment;
  final int durationMonths;
  final String durationUnit;
  final int displayOrder;
  final bool isActive;
  final List<String> benefits;
  final Map<String, dynamic>? accessRules;

  const SubscriptionPlanModel({
    required this.id,
    this.recordIds = const {},
    required this.name,
    required this.slug,
    this.description,
    required this.price,
    this.originalPrice,
    this.discount,
    this.currency = 'INR',
    required this.minInvestment,
    required this.maxInvestment,
    required this.durationMonths,
    this.durationUnit = 'months',
    this.displayOrder = 1,
    this.isActive = true,
    this.benefits = const [],
    this.accessRules,
  });

  String get formattedPrice => CurrencyFormatter.format(price, showDecimals: true);
  String get formattedMinInvestment => CurrencyFormatter.format(minInvestment);
  String get formattedMaxInvestment => CurrencyFormatter.format(maxInvestment);
  String get formattedRange =>
      '$formattedMinInvestment – $formattedMaxInvestment';
  String get formattedDuration => '$durationMonths ${durationMonths == 1 ? 'Month' : 'Months'}';

  factory SubscriptionPlanModel.fromJson(Map<String, dynamic> json) {
    List<String> parsedBenefits = [];
    if (json['benefits'] is List) {
      parsedBenefits = (json['benefits'] as List)
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (json['features'] is List) {
      parsedBenefits = (json['features'] as List)
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    final int duration = (json['durationMonths'] as num?)?.toInt() ??
        (json['duration'] as num?)?.toInt() ??
        12;

    return SubscriptionPlanModel(
      recordIds: DisplayValue.ids(json),
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      description: json['description']?.toString(),
      price: CurrencyFormatter.number(json['price']),
      originalPrice: json['originalPrice'] == null ? null : CurrencyFormatter.number(json['originalPrice']),
      discount: json['discount'] == null ? null : CurrencyFormatter.number(json['discount']),
      currency: json['currency']?.toString() ?? 'INR',
      minInvestment: CurrencyFormatter.number(json['minInvestment']),
      maxInvestment: CurrencyFormatter.number(json['maxInvestment']),
      durationMonths: duration,
      durationUnit: json['durationUnit']?.toString() ?? 'months',
      displayOrder: (json['displayOrder'] as num?)?.toInt() ?? 1,
      isActive: json['isActive'] == true || json['status'] == 'ACTIVE',
      benefits: parsedBenefits,
      accessRules: json['accessRules'] is Map<String, dynamic>
          ? json['accessRules'] as Map<String, dynamic>
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
      'recordIds': recordIds,
        'name': name,
        'slug': slug,
        'description': description,
        'price': price,
        'originalPrice': originalPrice,
        'discount': discount,
        'currency': currency,
        'minInvestment': minInvestment,
        'maxInvestment': maxInvestment,
        'durationMonths': durationMonths,
        'durationUnit': durationUnit,
        'displayOrder': displayOrder,
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

    final minInv = CurrencyFormatter.number(json['minInvestment'] ?? plan?['minInvestment']);
    final maxInv = CurrencyFormatter.number(json['maxInvestment'] ?? plan?['maxInvestment']);

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

