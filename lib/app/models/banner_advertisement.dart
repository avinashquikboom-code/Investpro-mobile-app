class BannerAdvertisement {
  const BannerAdvertisement({
    required this.id,
    required this.imageUrl,
    required this.placement,
    this.placements = const [],
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
  final List<String> placements;
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

  bool matchesPlacement(String target) {
    final cleanTarget = target.trim();
    if (placements.contains(cleanTarget) || placement == cleanTarget) return true;
    if (cleanTarget == 'PROJECT_DETAILS_BELOW_INVESTMENT' || cleanTarget == 'PROJECT_DETAILS_AFTER_INVESTMENT') {
      return placements.contains('PROJECT_DETAILS_BELOW_INVESTMENT') ||
          placements.contains('PROJECT_DETAILS_AFTER_INVESTMENT') ||
          placement == 'PROJECT_DETAILS_BELOW_INVESTMENT' ||
          placement == 'PROJECT_DETAILS_AFTER_INVESTMENT';
    }
    return false;
  }

  factory BannerAdvertisement.fromJson(Map<String, dynamic> json) {
    String? optional(String key) {
      final value = json[key];
      if (value is! String || value.trim().isEmpty) return null;
      return value.trim();
    }

    final rawPlacements = json['placements'];
    final List<String> placementsList = [];
    if (rawPlacements is List) {
      for (final p in rawPlacements) {
        if (p != null && p.toString().trim().isNotEmpty) {
          placementsList.add(p.toString().trim());
        }
      }
    }
    final singlePlacement = optional('placement') ?? (placementsList.isNotEmpty ? placementsList.first : '');
    if (placementsList.isEmpty && singlePlacement.isNotEmpty) {
      placementsList.add(singlePlacement);
    }

    return BannerAdvertisement(
      id: (json['id'] ?? json['displayId'] ?? '').toString(),
      imageUrl: optional('imageUrl') ?? '',
      placement: singlePlacement,
      placements: List.unmodifiable(placementsList),
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

  Map<String, dynamic> toJson() => {
    'id': id,
    'imageUrl': imageUrl,
    'placement': placement,
    'placements': placements,
    'name': name,
    'title': title,
    'description': description,
    'buttonText': buttonText,
    'targetUrl': targetUrl,
    'targetScreen': targetScreen,
    'displayOrder': displayOrder,
    'startDate': startDate?.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'isActive': isActive,
  };
}

/// Keeps presigned S3/CloudFront URLs intact, including their signature query.
/// Relative local URLs are resolved against the backend origin for sandbox data.
String resolveBannerImageUrl(String imageUrl, String mediaApiBaseUrl) {
  final uri = Uri.tryParse(imageUrl);
  if (uri?.hasScheme == true) return imageUrl;
  final origin = mediaApiBaseUrl.replaceFirst(RegExp(r'/api/v\d+/?$'), '').replaceFirst(RegExp(r'/$'), '');
  final path = imageUrl.startsWith('/') ? imageUrl : '/$imageUrl';
  return '$origin$path';
}
