import 'package:flutter_test/flutter_test.dart';
import 'package:investpro/app/models/banner_advertisement.dart';

void main() {
  test('parses image-only banner payload without inventing labels', () {
    final banner = BannerAdvertisement.fromJson({
      'id': 'banner-1',
      'imageUrl': '/uploads/ad.webp',
      'placement': 'HOME_TOP',
      'name': null,
      'title': '',
      'description': null,
      'buttonText': null,
      'targetUrl': null,
      'targetScreen': 'HOME',
      'displayOrder': 3,
      'startDate': '2026-11-01T00:00:00.000Z',
      'endDate': null,
      'isActive': true,
    });

    expect(banner.imageUrl, '/uploads/ad.webp');
    expect(banner.placement, 'HOME_TOP');
    expect(banner.title, isNull);
    expect(banner.description, isNull);
    expect(banner.buttonText, isNull);
    expect(banner.targetUrl, isNull);
    expect(banner.targetScreen, 'HOME');
    expect(banner.displayOrder, 3);
    expect(banner.startDate, DateTime.utc(2026, 11));
    expect(banner.endDate, isNull);
    expect(banner.isActive, isTrue);
    expect(banner.isSponsored, isFalse);
  });

  test('parses and serializes optional sponsored state with a false legacy default', () {
    final legacy = BannerAdvertisement.fromJson({
      'id': 'legacy-banner',
      'imageUrl': '/ad.webp',
      'placement': 'HOME_TOP',
    });
    final sponsored = BannerAdvertisement.fromJson({
      'id': 'sponsored-banner',
      'imageUrl': '/ad.gif',
      'placement': 'HOME_TOP',
      'isSponsored': true,
    });

    expect(legacy.isSponsored, isFalse);
    expect(sponsored.isSponsored, isTrue);
    expect(sponsored.toJson()['isSponsored'], isTrue);
  });

  test('keeps presigned S3 URL and signature unchanged', () {
    const signed =
        'https://example-bucket.s3.ap-south-1.amazonaws.com/banner-ads/a.webp?X-Amz-Signature=secret&X-Amz-Expires=3600';
    expect(
      resolveBannerImageUrl(signed, 'https://api.example.com/api/v1'),
      signed,
    );
  });

  test('preserves animated GIF image URL and supports animated GIF banners', () {
    const gifUrl =
        'https://example-bucket.s3.ap-south-1.amazonaws.com/investpro-uploads/banner-ads/animated_banner.gif?X-Amz-Signature=sig123&X-Amz-Expires=3600';
    expect(
      resolveBannerImageUrl(gifUrl, 'https://api.example.com/api/v1'),
      gifUrl,
    );

    final gifBanner = BannerAdvertisement.fromJson({
      'id': 'gif-banner-1',
      'imageUrl': gifUrl,
      'title': 'Limited Time Offer',
      'placements': ['HOME_TOP', 'RETURNS_BOTTOM'],
      'isActive': true,
    });

    expect(gifBanner.imageUrl, gifUrl);
    expect(
      gifBanner.imageUrl.endsWith('.gif') ||
          gifBanner.imageUrl.contains('.gif?'),
      isTrue,
    );
    expect(gifBanner.matchesPlacement('HOME_TOP'), isTrue);
    expect(gifBanner.matchesPlacement('RETURNS_BOTTOM'), isTrue);
  });

  test(
    'parses multi-placement banner payload and matches all selected placements',
    () {
      final banner = BannerAdvertisement.fromJson({
        'id': 'banner-multi-1',
        'imageUrl': 'https://example-bucket.s3.ap-south-1.amazonaws.com/banner-ads/promo.webp',
        'title': 'Grow Your Wealth',
        'placements': ['HOME_TOP', 'PROJECTS_BETWEEN_LIST', 'RETURNS_BOTTOM'],
        'isActive': true,
      });

      expect(banner.id, 'banner-multi-1');
      expect(banner.placements, [
        'HOME_TOP',
        'PROJECTS_BETWEEN_LIST',
        'RETURNS_BOTTOM',
      ]);
      expect(banner.placement, 'HOME_TOP');
      expect(banner.matchesPlacement('HOME_TOP'), isTrue);
      expect(banner.matchesPlacement('PROJECTS_BETWEEN_LIST'), isTrue);
      expect(banner.matchesPlacement('RETURNS_BOTTOM'), isTrue);
      expect(banner.matchesPlacement('HOME_DASHBOARD_BOTTOM'), isFalse);
      expect(banner.matchesPlacement('HOME_BETWEEN_SECTIONS'), isFalse);
    },
  );

  test('supports project details alias between BELOW_INVESTMENT and AFTER_INVESTMENT', () {
    final banner1 = BannerAdvertisement.fromJson({
      'id': 'banner-pd-1',
      'imageUrl': '/ad.png',
      'placements': ['PROJECT_DETAILS_BELOW_INVESTMENT'],
      'isActive': true,
    });
    expect(
      banner1.matchesPlacement('PROJECT_DETAILS_BELOW_INVESTMENT'),
      isTrue,
    );
    expect(
      banner1.matchesPlacement('PROJECT_DETAILS_AFTER_INVESTMENT'),
      isTrue,
    );

    final banner2 = BannerAdvertisement.fromJson({
      'id': 'banner-pd-2',
      'imageUrl': '/ad.png',
      'placement': 'PROJECT_DETAILS_AFTER_INVESTMENT',
      'isActive': true,
    });
    expect(
      banner2.matchesPlacement('PROJECT_DETAILS_BELOW_INVESTMENT'),
      isTrue,
    );
    expect(
      banner2.matchesPlacement('PROJECT_DETAILS_AFTER_INVESTMENT'),
      isTrue,
    );
  });

  test('maintains backward compatibility when only single placement string is provided', () {
    final banner = BannerAdvertisement.fromJson({
      'id': 'legacy-banner',
      'imageUrl': '/uploads/legacy.webp',
      'placement': 'HOME_DASHBOARD_BOTTOM',
      'isActive': true,
    });

    expect(banner.placement, 'HOME_DASHBOARD_BOTTOM');
    expect(banner.placements, ['HOME_DASHBOARD_BOTTOM']);
    expect(banner.matchesPlacement('HOME_DASHBOARD_BOTTOM'), isTrue);
    expect(banner.matchesPlacement('HOME_TOP'), isFalse);
  });
}
