import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:investpro/app/controllers/investment_controller.dart';
import 'package:investpro/app/models/project_model.dart';
import 'package:investpro/app/services/api_service.dart';
import 'package:investpro/app/services/local_storage_service.dart';
import 'package:investpro/app/services/notification_service.dart';
import 'package:investpro/app/constants/app_strings.dart';
import 'package:investpro/app/utils/currency_formatter.dart';
import 'package:investpro/app/views/investments/payment_confirmation_view.dart';

import 'razorpay_payment_test.dart' as fixture;

class MockOfflineSettingsApi extends fixture.PaymentApi {
  @override
  Future<Map<String, dynamic>> object(String path) async {
    if (path.contains('offline-payment/settings')) {
      return {
        'enabled': true,
        'accountHolderName': 'InvestPro Capital PVT LTD',
        'bankName': 'HDFC Bank',
        'accountNumber': '50200012345678',
        'ifscCode': 'HDFC0001234',
        'upiId': 'investpro@hdfcbank',
        'maxBytes': 5242880,
      };
    }
    return super.object(path);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testProject = ProjectModel(
    id: 'proj-solar-001',
    name: 'Solar Green Energy Alpha',
    category: 'Renewable',
    iconType: 'leaf',
    targetAmount: 5000000,
    raisedAmount: 2500000,
    returnRatePercent: 18.0,
    durationMonths: 12,
    description: 'Commercial solar power plant investment.',
    createdAt: DateTime(2026, 1, 1),
    minInvestment: 5000,
  );

  setUp(() {
    Get.testMode = true;
    GoogleFonts.config.allowRuntimeFetching = false;
  });

  tearDown(() => Get.reset());

  testWidgets(
    'Redesigned Confirm Payment screen renders dynamic summary and responds to method toggle',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final api = Get.put<ApiService>(MockOfflineSettingsApi());
      final storage = LocalStorageService(backend: fixture.MemoryStore());
      final repo = fixture.PaymentRepo(
        storage,
        NotificationService(storage),
        api,
      );
      final controller = Get.put(
        InvestmentController(repo, checkoutFactory: fixture.Checkout.new),
      );

      controller.currentProject.value = testProject;
      controller.investmentAmount.value = 10000;
      controller.amountTextController.text = '10000';
      controller.selectedPaymentMethod.value = 'Razorpay Checkout';

      await tester.pumpWidget(
        GetMaterialApp(
          translations: AppTranslations(),
          locale: const Locale('en', 'US'),
          home: const PaymentConfirmationView(),
        ),
      );
      await tester.pumpAndSettle();

      final formattedAmount = CurrencyFormatter.format(10000);

      // 1. Verify dynamic Investment Summary Card values
      expect(find.text('Confirm Payment'), findsOneWidget);
      expect(find.text('Solar Green Energy Alpha'), findsOneWidget);
      expect(find.text(formattedAmount), findsNWidgets(2)); // Amount Invested and Total Payable
      expect(find.text('12 Months'), findsOneWidget);
      expect(find.text('Total Payable'), findsOneWidget);

      // 2. Verify Payment Method Selection cards
      expect(find.text('Select Payment Method'), findsOneWidget);
      expect(find.text('Razorpay Checkout'), findsOneWidget);
      expect(find.text('Offline Payment'), findsOneWidget);

      // In Razorpay mode, bottom button shows "Proceed to Pay ₹ 10,000"
      expect(find.text('Proceed to Pay $formattedAmount'), findsOneWidget);
      // Terms are unchecked by default, so button is disabled
      final initialButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Proceed to Pay $formattedAmount'),
      );
      expect(initialButton.onPressed, isNull);

      // 3. Switch to Offline Payment
      await tester.tap(find.text('Offline Payment'));
      await tester.pumpAndSettle();

      // Verify Offline Payment Instructions card rendered with dynamic settings
      expect(find.text('Offline Payment Instructions'), findsOneWidget);
      expect(find.text('InvestPro Capital PVT LTD'), findsOneWidget);
      expect(find.text('HDFC Bank'), findsOneWidget);
      expect(find.text('50200012345678'), findsOneWidget);
      expect(find.text('HDFC0001234'), findsOneWidget);
      expect(find.text('investpro@hdfcbank'), findsOneWidget);

      // Verify UTR field and Upload container appear
      expect(find.text('Payment Reference / UTR Number'), findsOneWidget);
      expect(find.text('Upload Payment Proof'), findsNWidgets(2)); // Label + Container text
      expect(find.text('JPG, PNG or PDF (Max 5 MB)'), findsOneWidget);

      // Verify Submit Payment Details button is disabled without proof & terms
      final offlineButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Submit Payment Details'),
      );
      expect(offlineButton.onPressed, isNull);

      // 4. Verify Terms dialog can be opened
      await tester.ensureVisible(find.text('Investment Terms & Risk Disclosures'));
      await tester.tap(find.text('Investment Terms & Risk Disclosures'));
      await tester.pumpAndSettle();
      expect(find.text('Terms & Risk Disclosures'), findsOneWidget);
      // Close dialog
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      // 5. Toggle terms checkbox
      expect(controller.agreeToTerms.value, isFalse);
      await tester.tap(find.byType(Checkbox));
      await tester.pumpAndSettle();
      expect(controller.agreeToTerms.value, isTrue);

      // In offline mode, button is STILL disabled because UTR and proof are missing
      final stillDisabledButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Submit Payment Details'),
      );
      expect(stillDisabledButton.onPressed, isNull);

      // 6. Switch back to Razorpay Checkout
      await tester.ensureVisible(find.text('Razorpay Checkout'));
      await tester.tap(find.text('Razorpay Checkout'));
      await tester.pumpAndSettle();

      // Now with terms agreed, Razorpay button is enabled!
      final enabledRazorpayButton = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Proceed to Pay $formattedAmount'),
      );
      expect(enabledRazorpayButton.onPressed, isNotNull);

      expect(tester.takeException(), isNull);
    },
  );

  for (final size in [
    const Size(320, 568),   // iPhone SE / small Android
    const Size(390, 844),   // Standard iPhone
    const Size(844, 390),   // Landscape
    const Size(1024, 1366), // iPad / Tablet
  ]) {
    testWidgets(
      'Redesigned Confirm Payment screen renders without overflow on $size',
      (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final api = Get.put<ApiService>(MockOfflineSettingsApi());
        final storage = LocalStorageService(backend: fixture.MemoryStore());
        final repo = fixture.PaymentRepo(
          storage,
          NotificationService(storage),
          api,
        );
        final controller = Get.put(
          InvestmentController(repo, checkoutFactory: fixture.Checkout.new),
        );

        controller.currentProject.value = testProject;
        controller.investmentAmount.value = 10000;
        controller.amountTextController.text = '10000';
        controller.selectedPaymentMethod.value = 'Offline Payment';

        await tester.pumpWidget(
          GetMaterialApp(
            translations: AppTranslations(),
            locale: const Locale('en', 'US'),
            home: const PaymentConfirmationView(),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Confirm Payment'), findsOneWidget);
        expect(find.text('Solar Green Energy Alpha'), findsOneWidget);
        expect(find.text('Offline Payment Instructions'), findsOneWidget);
        expect(tester.takeException(), isNull);

        await tester.pumpWidget(const SizedBox.shrink());
      },
    );
  }
}
