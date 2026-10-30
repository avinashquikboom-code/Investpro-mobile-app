import 'package:investpro/app/controllers/auth_controller.dart';
import 'package:investpro/app/services/demo_repository.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:investpro/app/services/firebase_notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:investpro/app/controllers/notification_controller.dart';
import 'package:investpro/app/models/notification_model.dart';
import 'package:investpro/app/routes/app_routes.dart';
import 'package:investpro/app/services/api_service.dart';
import 'package:investpro/app/services/local_storage_service.dart';
import 'package:investpro/app/services/notification_service.dart';
import 'package:investpro/app/views/notifications/notifications_view.dart';

class MemoryStore implements LocalStore {
  final values = <String, dynamic>{};
  @override
  dynamic read(String key) => values[key];
  @override
  Future<void> write(String key, dynamic value) async {
    values[key] = value;
  }
}

final welcome = <String, dynamic>{
  'id': 'welcome-id',
  'type': 'INVESTOR_WELCOME',
  'title': 'Welcome to InvestPro! 🎉',
  'message': 'Hi Asha, welcome to InvestPro! Your account has been created successfully. Complete your KYC verification to get started with investing.',
  'createdAt': '2026-10-30T10:00:00Z',
  'isRead': false,
  'data': {'event': 'INVESTOR_WELCOME', 'route': '/kyc'},
};

class WelcomeApi extends ApiService {
  bool offline = false;
  bool authenticated = true;
  int tokenRegistrations = 0;
  int count = 60;
  final reads = <String>[];
  @override
  Future<String?> getAccessToken() async =>
      authenticated ? 'authenticated' : null;
  @override
  Future<bool> registerDeviceToken({
    required String token,
    String platform = 'android',
    String? deviceId,
  }) async {
    tokenRegistrations++;
    return true;
  }

  @override
  Future<List<dynamic>?> getNotifications() async {
    if (offline) throw StateError('offline');
    return [welcome];
  }

  @override
  Future<int?> getUnreadNotificationCount() async => count;
  @override
  Future<bool> markNotificationRead(String id) async {
    reads.add(id);
    return true;
  }

  @override
  Future<bool> markAllNotificationsRead() async => true;
}

class FakeMessaging implements FirebaseMessaging {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeLocalNotifications implements FlutterLocalNotificationsPlugin {
  int shows = 0;
  @override
  Future<void> show({
    required int id,
    String? title,
    String? body,
    NotificationDetails? notificationDetails,
    String? payload,
  }) async {
    shows++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  tearDown(Get.reset);
  test('welcome parses API type, metadata, and cached local type', () {
    for (final raw in [
      welcome,
      {...welcome, 'type': 'SYSTEM'},
      {...welcome, 'type': 'investorWelcome', 'data': null},
    ]) {
      final item = NotificationModel.fromJson(raw);
      expect(item.type, NotificationType.investorWelcome);
      expect(
        NotificationModel.fromJson(item.toJson()).type,
        NotificationType.investorWelcome,
      );
      expect(item.description, contains('Hi Asha'));
    }
  });
  test('history survives disabled notifications/offline refresh and uses server unread count', () async {
    final storage = LocalStorageService(backend: MemoryStore());
    await storage.setNotificationsEnabled(false);
    final api = WelcomeApi();
    final service = await NotificationService(storage, api).init();
    await service.refreshFromBackend();
    expect(service.notifications.single.type, NotificationType.investorWelcome);
    expect(service.unreadCount, 60);
    service.markAsRead('welcome-id');
    expect(service.unreadCount, 59);
    expect(api.reads, ['welcome-id']);
    api.offline = true;
    await expectLater(service.refreshFromBackend(), throwsStateError);
    expect(service.notifications.single.isRead, isTrue);
    service.clear();
    expect(service.unreadCount, 0);
  });
  test('foreground welcome is presented once, keeps server history identity, and token sync waits for authentication', () async {
    final storage = LocalStorageService(backend: MemoryStore());
    final api = WelcomeApi()..count = 1;
    final service = await NotificationService(storage, api).init();
    final local = FakeLocalNotifications();
    final push = FirebaseNotificationService(
      storage,
      api,
      service,
      messaging: FakeMessaging(),
      localNotifications: local,
    );
    const message = RemoteMessage(
      messageId: 'fcm-id',
      data: {
        'type': 'INVESTOR_WELCOME',
        'notificationId': 'welcome-id',
        'route': '/kyc',
      },
      notification: RemoteNotification(
        title: 'Welcome to InvestPro! 🎉',
        body: 'Hi Asha',
      ),
    );
    await Future.wait([
      push.handleForegroundMessage(message),
      push.handleForegroundMessage(message),
    ]);
    await Future<void>.delayed(Duration.zero);
    expect(local.shows, 1);
    expect(service.notifications.length, 1);
    expect(service.notifications.single.id, 'welcome-id');
    final restarted = FirebaseNotificationService(
      storage,
      api,
      service,
      messaging: FakeMessaging(),
      localNotifications: local,
    );
    await restarted.handleForegroundMessage(message);
    expect(local.shows, 1);
    api.authenticated = false;
    await push.syncToken('device-token');
    expect(api.tokenRegistrations, 0);
    api.authenticated = true;
    await push.syncToken('device-token');
    expect(api.tokenRegistrations, 1);
  });
  testWidgets(
    'welcome push taps wait for authentication and route to KYC after cold start',
    (tester) async {
      final storage = LocalStorageService(backend: MemoryStore());
      final api = WelcomeApi();
      final service = await NotificationService(storage, api).init();
      final push = FirebaseNotificationService(
        storage,
        api,
        service,
        messaging: FakeMessaging(),
        localNotifications: FakeLocalNotifications(),
      );
      push.handleNotificationRouting({
        'type': 'INVESTOR_WELCOME',
        'targetId': 'owner',
      });
      final auth = Get.put(
        AuthController(storage, DemoRepository(storage, service)),
      );
      auth.isLoggedIn.value = true;
      await tester.pumpWidget(
        GetMaterialApp(
          initialRoute: AppRoutes.home,
          getPages: [
            GetPage(
              name: AppRoutes.home,
              page: () => const Scaffold(body: Text('Home destination')),
            ),
            GetPage(
              name: AppRoutes.kyc,
              page: () => const Scaffold(body: Text('KYC destination')),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();
      push.flushKyc();
      await tester.pumpAndSettle();
      expect(find.text('KYC destination'), findsOneWidget);
      push.flushKyc();
      await tester.pumpAndSettle();
      expect(find.text('KYC destination'), findsOneWidget);
    },
  );
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    for (final width in [375.0, 768.0, 1024.0]) {
      testWidgets('$platform welcome history and KYC tap at $width', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 1000);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);
        final api = WelcomeApi()..count = 1;
        final service = await NotificationService(
          LocalStorageService(backend: MemoryStore()),
          api,
        ).init();
        await service.refreshFromBackend();
        Get.put(NotificationController(service));
        await tester.pumpWidget(
          GetMaterialApp(
            theme: ThemeData(platform: platform),
            home: const NotificationsView(),
            getPages: [
              GetPage(
                name: AppRoutes.kyc,
                page: () => const Scaffold(body: Text('KYC destination')),
              ),
            ],
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Welcome to InvestPro! 🎉'), findsOneWidget);
        expect(find.textContaining('Hi Asha'), findsOneWidget);
        expect(find.byIcon(Remix.gift_line), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.tap(find.text('Welcome to InvestPro! 🎉'));
        await tester.pumpAndSettle();
        expect(find.text('KYC destination'), findsOneWidget);
        expect(api.reads, ['welcome-id']);
        expect(service.unreadCount, 0);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
