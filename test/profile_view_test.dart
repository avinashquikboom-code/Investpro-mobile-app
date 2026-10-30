import 'package:remixicon/remixicon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:investpro/app/constants/app_strings.dart';
import 'package:investpro/app/controllers/auth_controller.dart';
import 'package:investpro/app/controllers/navigation_controller.dart';
import 'package:investpro/app/controllers/profile_controller.dart';
import 'package:investpro/app/controllers/theme_controller.dart';
import 'package:investpro/app/models/user_model.dart';
import 'package:investpro/app/services/demo_repository.dart';
import 'package:investpro/app/services/local_storage_service.dart';
import 'package:investpro/app/services/notification_service.dart';
import 'package:investpro/app/theme/app_theme.dart';
import 'package:investpro/app/views/profile/profile_view.dart';

class MemoryStore implements LocalStore {
  final values = <String, dynamic>{};
  @override
  dynamic read(String key) => values[key];
  @override
  Future<void> write(String key, dynamic value) async {
    values[key] = value;
  }
}

void main() {
  late LocalStorageService storage;
  late DemoRepository repo;

  setUp(() {
    Get.testMode = true;
    GoogleFonts.config.allowRuntimeFetching = false;
    storage = LocalStorageService(backend: MemoryStore());
    Get.put(storage);
    repo = DemoRepository(storage, NotificationService(storage));
    Get.put(repo);
    Get.put(AuthController(storage, repo));
    Get.put(ProfileController(repo));
    Get.put(ThemeController(storage));
    Get.put(NavigationController());
  });

  tearDown(() {
    Get.reset();
  });

  Future<void> mount(WidgetTester tester, {Size size = const Size(390, 844)}) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = size;
    tester.view.padding = const FakeViewPadding(top: 44, bottom: 34);

    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme,
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const ProfileView(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Renders complete redesigned Profile UI elements', (tester) async {
    // Set a known user state
    repo.currentUser.value = const UserModel(
      id: 'inv-usr-12345678-abcd',
      fullName: 'John Investor',
      email: 'john@investpro.com',
      mobileNumber: '+91 9876543210',
      accountStatus: 'ACTIVE',
      kycStatus: 'NOT_SUBMITTED',
    );

    await mount(tester);

    // 1. Header checks
    expect(find.text('Profile'), findsWidgets);
    expect(find.text('Manage your account information'), findsOneWidget);
    expect(find.byIcon(Remix.settings_3_line), findsOneWidget); // Menu list row only (removed from header)

    // 2. Profile Card checks
    expect(find.text('John Investor'), findsOneWidget);
    expect(find.textContaining('inv-usr-12345678-abcd'), findsOneWidget);
    expect(find.byIcon(Remix.file_copy_line), findsOneWidget);
    expect(find.text('Account: Active'), findsOneWidget);
    expect(find.text('KYC: Not Submitted'), findsOneWidget);

    // 3. Quick Action Cards
    expect(find.text('KYC Documents'), findsOneWidget);
    expect(find.text('Verify your identity'), findsOneWidget);
    expect(find.text('Add Bank Account'), findsOneWidget);
    expect(find.text('Manage withdrawals'), findsOneWidget);

    // 4. Account Management Section
    expect(find.text('Account Management'), findsOneWidget);
    expect(find.text('Personal Information'), findsOneWidget);
    expect(find.text('Bank Details'), findsOneWidget);
    expect(find.text('Investment History'), findsOneWidget);
    expect(find.text('Withdrawal History'), findsOneWidget);
    expect(find.text('Settings'), findsWidgets);
    expect(find.text('Help & Support'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);
  });

  testWidgets('Shows verified KYC status correctly', (tester) async {
    repo.currentUser.value = const UserModel(
      id: 'inv-usr-verified-999',
      fullName: 'Verified User',
      email: 'verified@investpro.com',
      mobileNumber: '+91 9999999999',
      accountStatus: 'ACTIVE',
      kycStatus: 'VERIFIED',
    );

    await mount(tester);

    expect(find.text('Verified User'), findsOneWidget);
    expect(find.text('KYC: Verified'), findsOneWidget);
  });

  testWidgets('Opens Bank Details dialog upon tap', (tester) async {
    repo.currentUser.value = const UserModel(
      id: 'inv-usr-bank-test',
      fullName: 'Bank Tester',
      email: 'bank@investpro.com',
      mobileNumber: '+91 8888888888',
      bankName: 'HDFC Bank',
      accountNumber: '987654321098',
      ifscCode: 'HDFC0001234',
    );

    await mount(tester);

    final bankDetailsTile = find.text('Bank Details');
    await tester.ensureVisible(bankDetailsTile);
    await tester.tap(bankDetailsTile);
    await tester.pumpAndSettle();

    expect(find.text('HDFC Bank'), findsOneWidget);
    expect(find.text('HDFC0001234'), findsOneWidget);

    // Close dialog
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
  });

  testWidgets('Opens Help & Support dialog upon tap', (tester) async {
    repo.currentUser.value = const UserModel(
      id: 'inv-usr-support-test',
      fullName: 'Support Tester',
      email: 'support_tester@investpro.com',
      mobileNumber: '+91 7777777777',
    );

    await mount(tester);

    final helpTile = find.text('Help & Support');
    await tester.ensureVisible(helpTile);
    await tester.tap(helpTile);
    await tester.pumpAndSettle();

    expect(find.text('Email Support'), findsOneWidget);
    expect(find.text('support@investpro.app'), findsOneWidget);

    // Close dialog
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('Email Support'), findsNothing);
  });

  testWidgets('No layout overflow across diverse screen sizes', (tester) async {
    final sizes = [
      const Size(320, 568),  // iPhone SE 1st gen
      const Size(375, 667),  // iPhone 8
      const Size(390, 844),  // iPhone 14
      const Size(430, 932),  // iPhone 14 Pro Max
      const Size(800, 1280), // Android Tablet
      const Size(1024, 1366),// iPad Pro
    ];

    for (final size in sizes) {
      await mount(tester, size: size);
      expect(tester.takeException(), isNull);
    }
  });
}
