import 'app/widgets/app_system_ui.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'firebase_options.dart';
import 'app/constants/app_constants.dart';
import 'app/constants/app_strings.dart';
import 'app/controllers/auth_controller.dart';
import 'app/controllers/home_controller.dart';
import 'app/controllers/investment_controller.dart';
import 'app/controllers/navigation_controller.dart';
import 'app/controllers/notification_controller.dart';
import 'app/controllers/profile_controller.dart';
import 'app/controllers/project_controller.dart';
import 'app/controllers/returns_controller.dart';
import 'app/controllers/settings_controller.dart';
import 'app/controllers/theme_controller.dart';
import 'app/controllers/transaction_controller.dart';
import 'app/controllers/withdrawal_controller.dart';
import 'app/routes/app_pages.dart';
import 'app/services/api_service.dart';
import 'app/services/demo_repository.dart';
import 'app/services/local_storage_service.dart';
import 'app/services/notification_service.dart';
import 'app/services/firebase_notification_service.dart';
import 'app/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // 1. Initialize Storage & Core Services
  final storageService = await LocalStorageService().init();
  Get.put<LocalStorageService>(storageService, permanent: true);

  final apiService = await ApiService().init();
  Get.put<ApiService>(apiService, permanent: true);

  final notificationService = await NotificationService(
    storageService,
    apiService,
  ).init();
  Get.put<NotificationService>(notificationService, permanent: true);

  final demoRepo = await DemoRepository(
    storageService,
    notificationService,
    apiService,
  ).init();
  Get.put<DemoRepository>(demoRepo, permanent: true);

  final firebaseNotifService = await FirebaseNotificationService(
    storageService,
    apiService,
    notificationService,
  ).init();
  Get.put<FirebaseNotificationService>(firebaseNotifService, permanent: true);

  // 2. Register Controllers via Get.put() (No GetX Bindings per instructions)
  final themeController = Get.put<ThemeController>(
    ThemeController(storageService),
    permanent: true,
  );
  Get.put<AuthController>(
    AuthController(storageService, demoRepo, apiService),
    permanent: true,
  );
  Get.put<NavigationController>(NavigationController(), permanent: true);
  Get.put<HomeController>(
    HomeController(demoRepo, notificationService),
    permanent: true,
  );
  Get.put<ProjectController>(
    ProjectController(demoRepo, apiService),
    permanent: true,
  );
  Get.put<InvestmentController>(
    InvestmentController(demoRepo),
    permanent: true,
  );
  Get.put<ReturnsController>(ReturnsController(demoRepo), permanent: true);
  Get.put<WithdrawalController>(
    WithdrawalController(demoRepo),
    permanent: true,
  );
  Get.put<TransactionController>(
    TransactionController(demoRepo),
    permanent: true,
  );
  Get.put<ProfileController>(ProfileController(demoRepo), permanent: true);
  Get.put<NotificationController>(
    NotificationController(notificationService),
    permanent: true,
  );
  Get.put<SettingsController>(
    SettingsController(storageService),
    permanent: true,
  );

  // Language Locale Init
  final savedLang = storageService.language;
  final parts = savedLang.split('_');
  final initialLocale = Locale(parts[0], parts.length > 1 ? parts[1] : null);

  runApp(
    InvestProApp(
      themeController: themeController,
      initialLocale: initialLocale,
    ),
  );
}

class InvestProApp extends StatelessWidget {
  final ThemeController themeController;
  final Locale initialLocale;

  const InvestProApp({
    super.key,
    required this.themeController,
    required this.initialLocale,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => GetMaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeController.currentThemeMode,
        defaultTransition: Transition.native,
        popGesture: true,
        builder: (context, child) =>
            AppSystemUi(child: child ?? const SizedBox.shrink()),
        translations: AppTranslations(),
        locale: initialLocale,
        fallbackLocale: const Locale('en', 'US'),
        initialRoute: AppPages.initial,
        getPages: AppPages.routes,
      ),
    );
  }
}
