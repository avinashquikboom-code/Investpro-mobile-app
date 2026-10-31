import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:investpro/app/controllers/investment_controller.dart';
import 'package:investpro/app/services/api_service.dart';
import 'package:investpro/app/services/local_storage_service.dart';
import 'package:investpro/app/services/notification_service.dart';
import 'package:investpro/app/views/investments/payment_confirmation_view.dart';
import 'package:investpro/app/models/notification_model.dart';

import 'razorpay_payment_test.dart' as fixture;

class OfflineSettingsApi extends fixture.PaymentApi {
  @override
  Future<Map<String, dynamic>> object(String path) async => {
    'enabled': true,
    'accountHolderName': 'Configured Account Holder',
    'bankName': 'Configured Bank',
    'accountNumber': '9876543210',
    'ifscCode': 'TEST0000001',
    'upiId': 'configured@example',
    'maxBytes': 5242880,
  };
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() {
    Get.testMode = true;
    GoogleFonts.config.allowRuntimeFetching = false;
  });
  tearDown(() => Get.reset());
  for (final size in [
    const Size(320, 640),
    const Size(844, 390),
    const Size(1024, 1366),
  ]) {
    testWidgets(
      'configured offline instructions fit $size and block submission without proof',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final api = Get.put<ApiService>(OfflineSettingsApi());
        final storage = LocalStorageService(backend: fixture.MemoryStore());
        final repo = fixture.PaymentRepo(
          storage,
          NotificationService(storage),
          api,
        );
        final controller = Get.put(
          InvestmentController(repo, checkoutFactory: fixture.Checkout.new),
        );
        controller.currentProject.value = fixture.project;
        controller.investmentAmount.value = 25000;
        controller.amountTextController.text = '25000';
        controller.selectedPaymentMethod.value = 'Razorpay Checkout';
        await tester.pumpWidget(
          const GetMaterialApp(home: PaymentConfirmationView()),
        );
        await tester.pumpAndSettle();
        await tester.ensureVisible(find.text('Offline Payment'));
        await tester.tap(find.text('Offline Payment'));
        await tester.pumpAndSettle();
        expect(find.text('Configured Account Holder'), findsOneWidget);
        expect(find.text('Configured Bank'), findsOneWidget);
        expect(find.text('9876543210'), findsOneWidget);
        await tester.ensureVisible(find.text('Submit Payment Details'));
        await tester.pump();
        final button = tester.widget<FilledButton>(
          find.widgetWithText(FilledButton, 'Submit Payment Details'),
        );
        expect(button.onPressed, isNull);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
  test('offline notification target survives storage and mark-read', () {
    final notification = NotificationModel.fromJson({
      'id': 'n1',
      'targetType': 'OFFLINE_PAYMENT',
      'targetId': 'request1',
      'type': 'INVESTMENT',
      'title': 'Payment Verification Rejected',
      'message': 'Review the reason',
      'createdAt': '2026-10-31T00:00:00Z',
    });
    expect(
      NotificationModel.fromJson(notification.markRead().toJson()).targetType,
      'OFFLINE_PAYMENT',
    );
  });
}
