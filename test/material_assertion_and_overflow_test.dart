import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:investpro/app/constants/app_strings.dart';
import 'package:investpro/app/controllers/auth_controller.dart';
import 'package:investpro/app/controllers/investment_controller.dart';
import 'package:investpro/app/controllers/kyc_controller.dart';
import 'package:investpro/app/controllers/navigation_controller.dart';
import 'package:investpro/app/controllers/notification_controller.dart';
import 'package:investpro/app/controllers/profile_controller.dart';
import 'package:investpro/app/controllers/settings_controller.dart';
import 'package:investpro/app/controllers/theme_controller.dart';
import 'package:investpro/app/controllers/transaction_controller.dart';
import 'package:investpro/app/models/investment_model.dart';
import 'package:investpro/app/models/transaction_model.dart';
import 'package:investpro/app/services/api_service.dart';
import 'package:investpro/app/services/demo_repository.dart';
import 'package:investpro/app/services/local_storage_service.dart';
import 'package:investpro/app/services/notification_service.dart';
import 'package:investpro/app/theme/app_theme.dart';
import 'package:investpro/app/views/bank/bank_account_view.dart';
import 'package:investpro/app/views/help/help_support_view.dart';
import 'package:investpro/app/views/investments/my_investments_view.dart';
import 'package:investpro/app/views/kyc/kyc_view.dart';
import 'package:investpro/app/views/notifications/notifications_view.dart';
import 'package:investpro/app/views/settings/settings_view.dart';
import 'package:investpro/app/views/transactions/transaction_history_view.dart';
import 'package:investpro/app/widgets/transaction_tile.dart';

class MemoryStore implements LocalStore {
  final values = <String, dynamic>{};
  @override
  dynamic read(String key) => values[key];
  @override
  Future<void> write(String key, dynamic value) async {
    values[key] = value;
  }
}

class FakeApi extends ApiService {
  @override
  Future<List<Map<String, dynamic>>> getBankAccounts() async => [
    {
      'id': 'b1',
      'bankName': 'State Bank of India Corporate',
      'accountHolderName': 'Avinash Sanjay Magar',
      'accountNumber': '987654321098',
      'ifscCode': 'SBIN0001234',
      'accountType': 'SAVINGS',
      'isPrimary': true,
      'isVerified': true,
    },
    {
      'id': 'b2',
      'bankName': 'HDFC Bank',
      'accountHolderName': 'Avinash Sanjay Magar',
      'accountNumber': '123456789012',
      'ifscCode': 'HDFC0005678',
      'accountType': 'CURRENT',
      'isPrimary': false,
      'isVerified': false,
    },
  ];

  @override
  Future<Map<String, dynamic>> kycConfig() async => {
    'maxBytes': 5000000,
    'documentTypes': ['PAN_CARD', 'AADHAAR_FRONT', 'PASSPORT'],
  };

  @override
  Future<Map<String, dynamic>> kycStatus() async => {'status': 'PENDING'};

  @override
  Future<List<dynamic>> kyc() async => [
    {
      'id': 'k1',
      'documentType': 'PAN_CARD',
      'status': 'PENDING',
      'createdAt': '2026-10-30T10:00:00Z',
    },
    {
      'id': 'k2',
      'documentType': 'PASSPORT',
      'status': 'VERIFIED',
      'createdAt': '2026-10-29T10:00:00Z',
    },
  ];
}

void main() {
  late LocalStorageService storage;
  late DemoRepository repo;
  late FakeApi api;

  setUp(() {
    Get.testMode = true;
    GoogleFonts.config.allowRuntimeFetching = false;
    storage = LocalStorageService(backend: MemoryStore());
    Get.put(storage);
    repo = DemoRepository(storage, NotificationService(storage));
    Get.put(repo);
    api = FakeApi();
    Get.put<ApiService>(api);
    Get.put(AuthController(storage, repo));
    Get.put(ProfileController(repo));
    Get.put(ThemeController(storage));
    Get.put(SettingsController(storage));
    Get.put(InvestmentController(repo));
    Get.put(TransactionController(repo));
    Get.put(KycController(api));
    Get.put(NotificationController(NotificationService(storage)));
    Get.put(NavigationController());
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('MyInvestmentsView renders investment cards without Material assertion', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final invCtrl = Get.find<InvestmentController>();
    invCtrl.myInvestmentsFilter.value = 'All';

    repo.investments.assignAll([
      InvestmentModel(
        id: 'inv-1',
        projectId: 'proj-1',
        projectName: 'Commercial Solar Hub',
        investedAmount: 25000,
        returnRatePercent: 14.5,
        durationMonths: 18,
        expectedReturn: 3625,
        maturityAmount: 28625,
        startDate: DateTime.now().subtract(const Duration(days: 30)),
        maturityDate: DateTime.now().add(const Duration(days: 500)),
        progressPercent: 20.0,
        status: 'Active',
        iconType: 'solar',
      ),
      InvestmentModel(
        id: 'inv-2',
        projectId: 'proj-2',
        projectName: 'Smart Logistics Warehouse',
        investedAmount: 50000,
        returnRatePercent: 16.0,
        durationMonths: 24,
        expectedReturn: 8000,
        maturityAmount: 58000,
        startDate: DateTime.now().subtract(const Duration(days: 90)),
        maturityDate: DateTime.now().add(const Duration(days: 600)),
        progressPercent: 35.0,
        status: 'Completed',
        iconType: 'warehouse',
      ),
    ]);

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme,
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const MyInvestmentsView(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Commercial Solar Hub'), findsOneWidget);
    expect(find.text('Smart Logistics Warehouse'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('SettingsView renders card groups and language options without Material assertion', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme,
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const SettingsView(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SettingsView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('HelpSupportView renders quick action cards without Material assertion', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme,
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const HelpSupportView(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(HelpSupportView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('KycView renders document cards without Material assertion', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme,
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const KycView(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(KycView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('NotificationsView renders notification tiles without Material assertion', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme,
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const NotificationsView(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NotificationsView), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('BankAccountView renders on narrow 320px screen without RenderFlex overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme,
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const BankAccountView(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Linked Bank Accounts'), findsOneWidget);
    expect(find.text('Add Account'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('BankAccountView renders with large text scaling without RenderFlex overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme,
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: MediaQuery(
          data: const MediaQueryData(
            textScaler: TextScaler.linear(1.3),
            size: Size(320, 568),
          ),
          child: const BankAccountView(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Linked Bank Accounts'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TransactionHistoryView renders transaction tiles without Material assertion', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    repo.transactions.assignAll([
      TransactionModel(
        id: 'txn-1',
        title: 'Investment in Commercial Solar Hub',
        subtitle: 'Investment Principal',
        amount: 25000,
        date: DateTime.now().subtract(const Duration(hours: 2)),
        type: TransactionType.investment,
        status: 'Completed',
        direction: 'DEBIT',
        referenceId: 'TXN-INV-98124',
      ),
      TransactionModel(
        id: 'txn-2',
        title: 'Return Payout from Warehousing',
        subtitle: 'Quarterly Return',
        amount: 3250,
        date: DateTime.now().subtract(const Duration(days: 2)),
        type: TransactionType.returnReceived,
        status: 'Completed',
        direction: 'CREDIT',
        referenceId: 'TXN-RET-12345',
      ),
      TransactionModel(
        id: 'txn-3',
        title: 'Wallet Withdrawal to HDFC Bank',
        subtitle: 'Bank Settlement',
        amount: 5000,
        date: DateTime.now().subtract(const Duration(days: 5)),
        type: TransactionType.withdrawal,
        status: 'Pending',
        direction: 'DEBIT',
        referenceId: 'TXN-WDL-67890',
      ),
    ]);

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme,
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const TransactionHistoryView(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TransactionTile), findsNWidgets(3));
    expect(find.text('Investment in Commercial Solar Hub'), findsOneWidget);
    expect(find.text('Return Payout from Warehousing'), findsOneWidget);
    expect(find.text('Wallet Withdrawal to HDFC Bank'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Tap first tile to verify bottomsheet details also open without assertion
    await tester.tap(find.text('Investment in Commercial Solar Hub'));
    await tester.pumpAndSettle();
    expect(find.text('Transaction Reference'), findsOneWidget);
    expect(find.text('TXN-INV-98124'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('TransactionTile in dark theme renders cleanly without Material assertion', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final txn = TransactionModel(
      id: 'txn-dark',
      title: 'Solar Yield Return',
      subtitle: 'Monthly Dividend',
      amount: 1450,
      date: DateTime.now(),
      type: TransactionType.returnReceived,
      status: 'Completed',
      direction: 'CREDIT',
      referenceId: 'TXN-RET-99999',
    );

    await tester.pumpWidget(
      GetMaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: TransactionTile(transaction: txn),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Solar Yield Return'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Transaction details bottomsheet scrolls and avoids overflow on small screens', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    repo.transactions.assignAll([
      TransactionModel(
        id: 'txn-1',
        title: 'Investment in Commercial Solar Hub',
        projectName: 'Commercial Solar Hub',
        subtitle: 'Investment Principal',
        amount: 25000,
        date: DateTime.now().subtract(const Duration(hours: 2)),
        type: TransactionType.investment,
        status: 'Completed',
        direction: 'DEBIT',
        referenceId: 'TXN-INV-98124',
        recordIds: const {
          'id': 'txn-1',
          'investmentId': 'inv-123',
          'projectId': 'proj-456',
        },
      ),
    ]);

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme,
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const TransactionHistoryView(),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Investment in Commercial Solar Hub'));
    await tester.pumpAndSettle();

    expect(find.text('Transaction Reference'), findsOneWidget);
    expect(find.text('TXN-INV-98124'), findsOneWidget);
    expect(find.text('Close'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // Verify close works
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Transaction Reference'), findsNothing);
  });
}
