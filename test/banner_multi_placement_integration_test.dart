import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:investpro/app/models/banner_advertisement.dart';
import 'package:investpro/app/services/api_service.dart';
import 'package:investpro/app/widgets/banner_ad_placement.dart';

class FakeApiService extends GetxService implements ApiService {
  final Map<String, List<Map<String, dynamic>>> placementResponses = {};

  @override
  String get mediaApiBaseUrl => 'https://api.example.com/api/v1';

  @override
  Future<List<dynamic>> bannerAds({String? placement}) async {
    if (placement == null) {
      return placementResponses.values.expand((list) => list).toList();
    }
    return placementResponses[placement] ?? [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeApiService fakeApi;

  setUp(() {
    fakeApi = FakeApiService();
    Get.reset();
    Get.put<ApiService>(fakeApi);
  });

  tearDown(() {
    Get.reset();
  });

  test('multi-placement banner matches all configured sections and rejects unselected', () {
    final banner = BannerAdvertisement.fromJson({
      'id': 'promo-banner-1',
      'imageUrl': 'https://s3.example.com/banner1.webp',
      'title': 'Grow Your Wealth',
      'description': 'Exclusive returns',
      'placements': ['HOME_TOP', 'PROJECTS_BETWEEN_LIST', 'RETURNS_BOTTOM'],
      'isActive': true,
    });

    expect(banner.matchesPlacement('HOME_TOP'), isTrue);
    expect(banner.matchesPlacement('PROJECTS_BETWEEN_LIST'), isTrue);
    expect(banner.matchesPlacement('RETURNS_BOTTOM'), isTrue);

    // Unselected sections
    expect(banner.matchesPlacement('HOME_DASHBOARD_BOTTOM'), isFalse);
    expect(banner.matchesPlacement('HOME_BETWEEN_SECTIONS'), isFalse);
    expect(
      banner.matchesPlacement('PROJECT_DETAILS_BELOW_INVESTMENT'),
      isFalse,
    );
  });

  testWidgets(
    'renders the same multi-placement banner across selected locations and hides on unselected',
    (tester) async {
      final sharedBannerData = {
        'id': 'shared-banner-42',
        'imageUrl': 'https://s3.example.com/shared.png',
        'title': 'Universal Opportunity',
        'placements': ['HOME_TOP', 'PROJECTS_BETWEEN_LIST', 'RETURNS_BOTTOM'],
        'isActive': true,
      };

      fakeApi.placementResponses['HOME_TOP'] = [sharedBannerData];
      fakeApi.placementResponses['PROJECTS_BETWEEN_LIST'] = [sharedBannerData];
      fakeApi.placementResponses['RETURNS_BOTTOM'] = [sharedBannerData];
      fakeApi.placementResponses['HOME_DASHBOARD_BOTTOM'] = [];

      // 1. Test HOME_TOP
      await tester.pumpWidget(
        const GetMaterialApp(
          home: Scaffold(body: BannerAdPlacement(placement: 'HOME_TOP')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Universal Opportunity'), findsOneWidget);

      // 2. Test PROJECTS_BETWEEN_LIST
      await tester.pumpWidget(
        const GetMaterialApp(
          home: Scaffold(
            body: BannerAdPlacement(placement: 'PROJECTS_BETWEEN_LIST'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Universal Opportunity'), findsOneWidget);

      // 3. Test RETURNS_BOTTOM
      await tester.pumpWidget(
        const GetMaterialApp(
          home: Scaffold(body: BannerAdPlacement(placement: 'RETURNS_BOTTOM')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Universal Opportunity'), findsOneWidget);

      // 4. Test unselected HOME_DASHBOARD_BOTTOM
      await tester.pumpWidget(
        const GetMaterialApp(
          home: Scaffold(
            body: BannerAdPlacement(placement: 'HOME_DASHBOARD_BOTTOM'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Universal Opportunity'), findsNothing);
    },
  );

  testWidgets('supports multiple banners sharing the same placement', (
    tester,
  ) async {
    fakeApi.placementResponses['HOME_TOP'] = [
      {
        'id': 'banner-1',
        'imageUrl': 'https://s3.example.com/b1.png',
        'title': 'First Banner',
        'placements': ['HOME_TOP'],
        'isActive': true,
      },
      {
        'id': 'banner-2',
        'imageUrl': 'https://s3.example.com/b2.png',
        'title': 'Second Banner',
        'placements': ['HOME_TOP', 'RETURNS_BOTTOM'],
        'isActive': true,
      },
    ];

    await tester.pumpWidget(
      const GetMaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: BannerAdPlacement(placement: 'HOME_TOP'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('First Banner'), findsOneWidget);
    expect(find.text('Second Banner'), findsOneWidget);
  });

  testWidgets('shows sponsored badges at each supported banner placement', (
    tester,
  ) async {
    const placements = [
      'HOME_TOP',
      'HOME_DASHBOARD_BOTTOM',
      'HOME_BETWEEN_SECTIONS',
      'PROJECTS_BETWEEN_LIST',
      'PROJECT_DETAILS_BELOW_INVESTMENT',
      'RETURNS_BOTTOM',
    ];
    final sponsoredData = {
      'id': 'sponsored-banner',
      'imageUrl': 'https://s3.example.com/sponsored.gif',
      'placements': placements,
      'isSponsored': true,
    };
    for (final placement in placements) {
      fakeApi.placementResponses[placement] = [sponsoredData];
      await tester.pumpWidget(
        GetMaterialApp(
          home: Scaffold(body: BannerAdPlacement(placement: placement)),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Sponsored'),
        findsOneWidget,
        reason: 'Badge missing at $placement',
      );
    }
  });

  testWidgets(
    'hides sponsored badge when disabled or missing from legacy API data',
    (tester) async {
      fakeApi.placementResponses['HOME_TOP'] = [
        {
          'id': 'off',
          'imageUrl': 'https://s3.example.com/off.gif',
          'placement': 'HOME_TOP',
          'isSponsored': false,
        },
      ];
      await tester.pumpWidget(
        const GetMaterialApp(
          home: Scaffold(body: BannerAdPlacement(placement: 'HOME_TOP')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sponsored'), findsNothing);

      fakeApi.placementResponses['HOME_TOP'] = [
        {
          'id': 'legacy',
          'imageUrl': 'https://s3.example.com/legacy.webp',
          'placement': 'HOME_TOP',
        },
      ];
      await tester.pumpWidget(
        const GetMaterialApp(
          home: Scaffold(body: BannerAdPlacement(placement: 'HOME_TOP')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Sponsored'), findsNothing);
    },
  );

  test(
    'supports backward compatibility for legacy single placement records',
    () {
      final legacy = BannerAdvertisement.fromJson({
        'id': 'legacy-99',
        'imageUrl': 'https://s3.example.com/legacy.webp',
        'placement': 'PROJECT_DETAILS_AFTER_INVESTMENT',
        'isActive': true,
      });

      expect(legacy.placement, 'PROJECT_DETAILS_AFTER_INVESTMENT');
      expect(legacy.placements, ['PROJECT_DETAILS_AFTER_INVESTMENT']);
      expect(
        legacy.matchesPlacement('PROJECT_DETAILS_BELOW_INVESTMENT'),
        isTrue,
      );
      expect(
        legacy.matchesPlacement('PROJECT_DETAILS_AFTER_INVESTMENT'),
        isTrue,
      );
      expect(legacy.matchesPlacement('HOME_TOP'), isFalse);
    },
  );
}
