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
  });

  test('keeps presigned S3 URL and signature unchanged', () {
    const signed = 'https://example-bucket.s3.ap-south-1.amazonaws.com/banner-ads/a.webp?X-Amz-Signature=secret&X-Amz-Expires=3600';
    expect(resolveBannerImageUrl(signed, 'https://api.example.com/api/v1'), signed);
  });
}
