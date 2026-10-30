import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:investpro/app/services/api_service.dart';
import 'package:investpro/app/views/help/investor_requests_view.dart';
import 'package:investpro/app/models/notification_model.dart';

class RequestsApi extends ApiService {
  final rows = <Map<String, dynamic>>[];
  String? receivedKey;
  int sends = 0;
  @override
  Future<List<dynamic>> requestHistory({int page = 1}) async => rows;
  @override
  Future<Map<String, dynamic>> submitRequest({
    required String kind,
    required String title,
    required String message,
    required String key,
  }) async {
    receivedKey = key;
    sends++;
    final row = {
      'id': 'stored-request',
      'title': title,
      'message': message,
      'kind': kind,
      'status': 'PENDING',
      'createdAt': '2026-10-30',
    };
    rows.add(row);
    return row;
  }
}

void main() {
  tearDown(Get.reset);
  test(
    'support and bank response notifications retain private request routing',
    () {
      expect(
        NotificationModel.fromJson({
          'id': 'n',
          'type': 'SYSTEM',
          'targetType': 'REQUEST',
          'targetId': 'stored-request',
          'message': 'Request reviewed',
        }).type,
        NotificationType.requestUpdate,
      );
    },
  );
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    for (final width in [375.0, 1024.0]) {
      testWidgets(
        '$platform saves real support requests and shows pending history at $width',
        (tester) async {
          tester.view.physicalSize = Size(width, 1100);
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.reset);
          final api = RequestsApi();
          Get.put<ApiService>(api);
          await tester.pumpWidget(
            GetMaterialApp(
              theme: ThemeData(platform: platform),
              home: const InvestorRequestsView(),
            ),
          );
          await tester.pumpAndSettle();
          final fields = find.byType(TextField);
          await tester.enterText(fields.at(0), 'Account question');
          await tester.enterText(
            fields.at(1),
            'Please help with this account question.',
          );
          await tester.tap(find.text('Submit request'));
          await tester.pumpAndSettle();
          expect(api.sends, 1);
          expect(api.receivedKey!.length, greaterThanOrEqualTo(8));
          expect(find.text('Account question'), findsOneWidget);
          expect(find.text('SUPPORT · PENDING'), findsOneWidget);
          expect(tester.takeException(), isNull);
        },
      );
    }
  }
}
