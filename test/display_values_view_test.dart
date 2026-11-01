import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:investpro/app/controllers/investment_controller.dart';
import 'package:investpro/app/controllers/returns_controller.dart';
import 'package:investpro/app/services/api_service.dart';
import 'package:investpro/app/services/backend_snapshot.dart';
import 'package:investpro/app/services/demo_repository.dart';
import 'package:investpro/app/services/local_storage_service.dart';
import 'package:investpro/app/services/notification_service.dart';
import 'package:investpro/app/views/investments/investment_details_view.dart';
import 'package:investpro/app/widgets/record_id.dart';

import 'razorpay_payment_test.dart' as fixture;

void main() {
  const id = '21d1f53f-37c5-402a-ae81-a35bc466f4d8';
  setUp(() {
    Get.testMode = true;
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  tearDown(() => Get.reset());
  for (final legacy in [false, true]) {
    testWidgets(
      'investment detail hides all IDs, preserves real invoices and keeps return navigation ($legacy)',
      (tester) async {
        final api = Get.put<ApiService>(fixture.PaymentApi());
        final storage = LocalStorageService(backend: fixture.MemoryStore());
        final repo = Get.put<DemoRepository>(
          fixture.PaymentRepo(storage, NotificationService(storage), api),
        );
        final record = BackendSnapshot.investment({
          'id': id,
          'displayId': 103,
          'projectDisplayId': 102,
          'projectId': '5beffe56-c013-4828-9e12-0caf83a648f6',
          'investmentReference': legacy ? 'INV-$id' : 'INV-001',
          'project': {'title': 'Actual Project Name'},
          'status': 'PENDING_PAYMENT',
          'amount': 1000,
          'agreedRoi': 12,
          'tenureMonths': 12,
          'totalExpectedReturns': 120,
          'startDate': '2026-01-01',
          'maturityDate': '2027-01-01',
        });
        repo.investments.assignAll([record]);
        final controller = Get.put(
          InvestmentController(repo, checkoutFactory: fixture.Checkout.new),
        );
        controller.selectedInvestment.value = record;
        final returns = Get.put(ReturnsController(repo));
        await tester.pumpWidget(
          GetMaterialApp(
            home: const InvestmentDetailsView(),
            getPages: [
              GetPage(
                name: '/returns',
                page: () => const Scaffold(body: Text('Returns destination')),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Actual Project Name'), findsOneWidget);
        expect(find.text('Invoice Number'), legacy ? findsNothing : findsOneWidget);
        expect(find.text('INV-001'), legacy ? findsNothing : findsOneWidget);
        expect(find.text('103'), findsNothing);
        expect(find.byType(RecordId), findsNothing);
        expect(find.byType(RecordIds), findsNothing);
        expect(find.text('Investment ID: 103'), findsNothing);
        expect(find.text('Project ID: 102'), findsNothing);
        expect(find.byTooltip('Copy Investment ID'), findsNothing);
        expect(find.byTooltip('Copy Project ID'), findsNothing);
        expect(find.text(id), findsNothing);
        await tester.ensureVisible(find.text('View Return Schedule'));
        await tester.tap(find.text('View Return Schedule'));
        await tester.pumpAndSettle();
        expect(returns.investmentFilter.value, id);
        expect(find.text('Returns destination'), findsOneWidget);
      },
    );
  }
}
