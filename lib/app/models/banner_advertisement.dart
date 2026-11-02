class BannerAdvertisement {
  const BannerAdvertisement({
    required this.id,
    required this.imageUrl,
    required this.placement,
    this.name,
    this.title,
    this.description,
    this.buttonText,
    this.targetUrl,
    this.targetScreen,
    this.displayOrder,
    this.startDate,
    this.endDate,
    this.isActive = false,
  });

  final String id;
  final String imageUrl;
  final String placement;
  final String? name;
  final String? title;
  final String? description;
  final String? buttonText;
  final String? targetUrl;
  final String? targetScreen;
  final int? displayOrder;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool isActive;

  factory BannerAdvertisement.fromJson(Map<String, dynamic> json) {
    String? optional(String key) {
      final value = json[key];
      if (value is! String || value.trim().isEmpty) return null;
      return value.trim();
    }

    return BannerAdvertisement(
      id: (json['id'] ?? json['displayId'] ?? '').toString(),
      imageUrl: optional('imageUrl') ?? '',
      placement: optional('placement') ?? '',
      name: optional('name'),
      title: optional('title'),
      description: optional('description'),
      buttonText: optional('buttonText'),
      targetUrl: optional('targetUrl'),
      targetScreen: optional('targetScreen'),
      displayOrder: (json['displayOrder'] as num?)?.toInt(),
      startDate: DateTime.tryParse(optional('startDate') ?? ''),
      endDate: DateTime.tryParse(optional('endDate') ?? ''),
      isActive: json['isActive'] == true,
    );
  }
}
