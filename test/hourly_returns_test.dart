import 'package:investpro/app/utils/display_value.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:investpro/app/controllers/returns_controller.dart';
import 'package:investpro/app/models/user_model.dart';
import 'package:investpro/app/services/api_service.dart';
import 'package:investpro/app/services/demo_repository.dart';
import 'package:investpro/app/services/local_storage_service.dart';
import 'package:investpro/app/services/notification_service.dart';
import 'package:investpro/app/views/returns/returns_overview.dart';
import 'package:investpro/app/widgets/returns_bar_chart.dart';
import 'returns_workspace_test.dart' as fixture;

class CaptureApi extends ApiService {
  String? path;
  @override
  Future<Map<String, dynamic>> object(String path) async { this.path = path; return {}; }
}
class DayApi extends fixture.FakeApi {
  final waits = <Completer<Map<String, dynamic>>>[];
  final days = <DateTime>[];
  @override
  Future<Map<String, dynamic>> getHourlyReturnsWorkspace(DateTime day) {
    days.add(day);
    final wait = Completer<Map<String, dynamic>>(); waits.add(wait); return wait.future;
  }
}
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => Get.reset());
  test('API requests the chosen calendar day and its UTC offset', () async {
    final api = CaptureApi(), day = DateTime(2026, 10, 30);
    await api.getHourlyReturnsWorkspace(day);
    final uri = Uri.parse(api.path!);
    expect(uri.queryParameters, {'period': 'hourly', 'date': '2026-10-30', 'utcOffsetMinutes': '${day.timeZoneOffset.inMinutes}'});
  });
  test('a changed day loads new data and discards a slow earlier day', () async {
    Get.testMode = true;
    final storage = LocalStorageService(backend: fixture.Store());
    Get.put(storage);
    final api = DayApi(); Get.put<ApiService>(api);
    final repo = DemoRepository(storage, NotificationService(storage), api);
    repo.currentUser.value = const UserModel(id: 'owner', fullName: 'Test', email: '', mobileNumber: '');
    final controller = Get.put(ReturnsController(repo));
    controller.selectedPeriod.value = 'Hourly';
    final first = controller.loadWorkspace();
    controller.setDate(DateTime(2026, 10, 30));
    expect(api.days.last, DateTime(2026, 10, 30));
    api.waits.last.complete({'period': 'hourly', 'selectedDate': '2026-10-30'});
    await Future<void>.delayed(Duration.zero);
    api.waits.first.complete({'period': 'hourly', 'selectedDate': 'old-day'});
    await first;
    expect(controller.workspace.value?['selectedDate'], '2026-10-30');
  });
  testWidgets('hourly overview renders 24 time buckets and confirmed payout identifiers without monthly controls', (tester) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    tester.view.physicalSize = const Size(320, 640); tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    DisplayValue.register({'displayIds': {'project':102,'investment':103,'transaction':105}});
    final snapshot = <String, dynamic>{
      'period': 'hourly', 'selectedDate': '2026-10-30', 'asOf': '2026-10-30T12:00:00Z',
      'summary': {'totalEarnedReturns': '0.70', 'todayEarnings': '0.70'},
      'hourly': {'hourlyEarningRate': '0.3000', 'totalCreditedReturns': '0.70', 'accruedNotCredited': '0.00', 'lastPayoutTime': '2026-10-30T11:00:00Z', 'nextExpectedPayoutTime': '2026-10-30T12:30:00Z'},
      'analytics': [for (var h = 0; h < 24; h++) {'date': DateTime.utc(2026, 10, 30, h).toIso8601String(), 'label': '${(h % 12 == 0 ? 12 : h % 12).toString().padLeft(2, '0')}:00 ${h < 12 ? 'AM' : 'PM'}', 'amount': h == 11 ? '0.70' : '0.00'}],
      'payouts': [{'id': 'accrual', 'transactionId': 'transaction', 'investmentId': 'investment', 'investmentReference': 'INV-103', 'projectId': 'project', 'projectName': 'Actual Project', 'date': '2026-10-30T11:00:00Z', 'profitAmount': '0.70', 'status': 'COMPLETED'}],
      'upcoming': [{'projectName': 'Actual Project', 'dueDate': '2026-10-30T12:30:00Z', 'expectedAmount': '0.10', 'profitAmount': '0.10', 'status': 'SCHEDULED'}],
    };
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SingleChildScrollView(child: ReturnsOverview(snapshot: snapshot, period: 'Hourly', onPeriod: (_) {})))));
    final chart = tester.widget<ReturnsBarChart>(find.byType(ReturnsBarChart));
    expect(chart.points.length, 24); expect(chart.points[1].label, '01:00 AM'); expect(chart.points.last.label, '11:00 PM');
    expect(find.text('Monthly'), findsNothing);
    expect(find.text('Hourly Payout History'), findsOneWidget);
    expect(find.text('Investment INV-103'), findsOneWidget);
    expect(find.text('Next Hourly Payout'), findsOneWidget);
    expect(find.textContaining('Transaction ID:'), findsNothing);
    expect(find.textContaining('Project ID:'), findsNothing);
    expect(find.textContaining('Investment ID:'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  for (final width in [320.0, 360.0]) {
    testWidgets('informational hourly indicator fits $width with a large schedule list', (tester) async {
      GoogleFonts.config.allowRuntimeFetching = false;
      tester.view.physicalSize = Size(width, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final snapshot = <String, dynamic>{
        'period': 'hourly',
        'asOf': '2026-11-02T00:00:00Z',
        'summary': <String, dynamic>{},
        'upcoming': [
          for (var i = 0; i < 120; i++)
            {
              'id': 'queue-$i',
              'projectName': 'Hourly project',
              'dueDate': DateTime.utc(2026, 11, 3, i).toIso8601String(),
              'expectedAmount': '0.10',
              'profitAmount': '0.10',
              'status': 'SCHEDULED',
            },
        ],
      };
      await tester.pumpWidget(GetMaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(1.3)),
          child: child!,
        ),
        home: Scaffold(body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ReturnsOverview(snapshot: snapshot, period: 'Hourly', onPeriod: (_) {}),
          ),
        )),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Next Hourly Payout'), findsOneWidget);
      expect(find.text('View all'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

}
