import 'package:investpro/app/controllers/auth_controller.dart';
import 'package:investpro/app/services/demo_repository.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:investpro/app/routes/app_routes.dart';
import 'package:investpro/app/services/api_service.dart';
import 'package:investpro/app/services/firebase_notification_service.dart';
import 'package:investpro/app/services/local_storage_service.dart';
import 'package:investpro/app/services/notification_service.dart';

class TestMemoryStore implements LocalStore {
  final values = <String, dynamic>{};
  @override
  dynamic read(String key) => values[key];
  @override
  Future<void> write(String key, dynamic value) async {
    values[key] = value;
  }
}

class FakeMessaging implements FirebaseMessaging {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeLocalNotifications implements FlutterLocalNotificationsPlugin {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class TestMockApi extends ApiService {
  int tokenRegistrations = 0;
  String? registeredToken;
  String? registeredPlatform;

  @override
  Future<String?> getAccessToken() async => 'test-valid-access-token';

  @override
  Future<bool> registerDeviceToken({
    required String token,
    String platform = 'android',
    String? deviceId,
  }) async {
    tokenRegistrations++;
    registeredToken = token;
    registeredPlatform = platform;
    return true;
  }

  @override
  Future<bool> deleteDeviceToken(String token) async {
    return true;
  }

  @override
  Future<List<dynamic>?> getNotifications() async => [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Campaign Push Notification Tests', () {
    late LocalStorageService storage;
    late TestMockApi api;
    late NotificationService notificationService;
    late FirebaseNotificationService pushService;

    setUp(() {
      Get.reset();
      storage = LocalStorageService(backend: TestMemoryStore());
      api = TestMockApi();
      notificationService = NotificationService(storage, api);
      final auth = Get.put(AuthController(storage, DemoRepository(storage, notificationService)));
      auth.isLoggedIn.value = true;
      pushService = FirebaseNotificationService(
        storage,
        api,
        notificationService,
        messaging: FakeMessaging(),
        localNotifications: FakeLocalNotifications(),
      );
    });

    test('Campaign channel constants match backend configuration', () {
      expect(
        FirebaseNotificationService.campaignChannelId,
        equals('investpro_campaigns'),
      );
      expect(
        FirebaseNotificationService.campaignChannelName,
        equals('InvestPro Campaigns & Promotions'),
      );
      expect(
        FirebaseNotificationService.channelId,
        equals('investpro_high_importance_channel'),
      );
    });

    test('Token synchronization registers active token with backend', () async {
      await pushService.syncToken('fcm-device-test-token-12345');
      expect(api.tokenRegistrations, equals(1));
      expect(api.registeredToken, equals('fcm-device-test-token-12345'));
      expect(storage.read('fcm_device_token'), equals('fcm-device-test-token-12345'));
    });

    testWidgets('Deep link parser routes to correct app routes', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '/',
          getPages: [
            GetPage(name: '/', page: () => const SizedBox()),
            GetPage(name: AppRoutes.projects, page: () => const SizedBox()),
            GetPage(name: AppRoutes.projectDetails, page: () => const SizedBox()),
            GetPage(name: AppRoutes.notifications, page: () => const SizedBox()),
          ],
        ),
      );

      final dataProject = {
        'type': 'CAMPAIGN',
        'campaignId': '101',
        'deepLink': '/projects/42',
      };

      pushService.handleNotificationRouting(dataProject);
      await tester.pumpAndSettle();
      expect(Get.currentRoute, equals(AppRoutes.projectDetails));
    });

    testWidgets('Campaign payload routes to project details when targetId or projectId present', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '/',
          getPages: [
            GetPage(name: '/', page: () => const SizedBox()),
            GetPage(name: AppRoutes.projectDetails, page: () => const SizedBox()),
            GetPage(name: AppRoutes.notifications, page: () => const SizedBox()),
          ],
        ),
      );

      final data = {
        'type': 'CAMPAIGN',
        'campaignId': '202',
        'projectId': 'project-99',
      };

      pushService.handleNotificationRouting(data);
      await tester.pumpAndSettle();
      expect(Get.currentRoute, equals(AppRoutes.projectDetails));
    });

    testWidgets('General campaign payload falls back to notifications view', (tester) async {
      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: '/',
          getPages: [
            GetPage(name: '/', page: () => const SizedBox()),
            GetPage(name: AppRoutes.notifications, page: () => const SizedBox()),
          ],
        ),
      );

      final data = {
        'type': 'CAMPAIGN',
        'campaignId': '303',
      };

      pushService.handleNotificationRouting(data);
      await tester.pumpAndSettle();
      expect(Get.currentRoute, equals(AppRoutes.notifications));
    });
  });
}
