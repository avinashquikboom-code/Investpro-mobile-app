import 'dart:convert';
import 'dart:io';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import '../models/notification_model.dart';
import '../controllers/auth_controller.dart';
import '../routes/app_routes.dart';
import 'api_service.dart';
import 'local_storage_service.dart';
import 'notification_service.dart';

/// Top-level background message handler required by Firebase Messaging
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kDebugMode) {
    print('[FCM] Handling background push: ${message.messageId}');
  }
}

class FirebaseNotificationService extends GetxService {
  final LocalStorageService _storage;
  final ApiService _api;
  final NotificationService _notificationService;

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String channelId = 'investpro_high_importance_channel';
  static const String channelName = 'InvestPro Push Notifications';
  static const String channelDescription =
      'High-priority transaction, investment and update notifications';

  bool _pendingKyc = false;
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  FirebaseNotificationService(
    this._storage,
    this._api,
    this._notificationService,
  );

  Future<FirebaseNotificationService> init() async {
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await _setupLocalNotifications();
      await requestPermissions();
      _setupMessageListeners();
      // Listen for token registration & refresh events
      _messaging.onRegistered.listen((newToken) {
        if (kDebugMode) {
          print('[FCM] Device token refreshed');
        }
        _fcmToken = newToken;
        syncToken(newToken);
      });

      await syncToken();
    } catch (e) {
      if (kDebugMode) {
        print('[FCM] Initialization warning: $e');
      }
    }
    return this;
  }

  Future<void> _setupLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          try {
            final data = jsonDecode(response.payload!) as Map<String, dynamic>;
            handleNotificationRouting(data);
          } catch (_) {
            Get.toNamed(AppRoutes.notifications);
          }
        } else {
          Get.toNamed(AppRoutes.notifications);
        }
      },
    );

    // Create high importance notification channel on Android
    const androidChannel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.max,
      playSound: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);
  }

  Future<void> requestPermissions() async {
    try {
      final current = await _messaging.getNotificationSettings();
      final requested = _storage.read('push_permission_requested') == true;
      if (requested ||
          (current.authorizationStatus != AuthorizationStatus.notDetermined &&
              !(Platform.isAndroid &&
                  current.authorizationStatus == AuthorizationStatus.denied))) {
        return;
      }
      await _storage.write('push_permission_requested', true);
      final settings = await _messaging.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      if (kDebugMode) {
        print('[FCM] User granted permission: ${settings.authorizationStatus}');
      }

      // Android 13+ permission request
      await _localNotifications
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } catch (e) {
      if (kDebugMode) {
        print('[FCM] requestPermissions error: $e');
      }
    }
  }

  void _setupMessageListeners() {
    // 1. Foreground message listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('[FCM] Foreground push received: ${message.data}');
      }

      final notification = message.notification;
      final title =
          notification?.title ?? message.data['title'] ?? 'InvestPro Notice';
      final body =
          notification?.body ??
          message.data['body'] ??
          message.data['message'] ??
          '';
      final typeStr = (message.data['type'] ?? 'SYSTEM').toString();

      // Show local heads-up notification
      _showLocalNotification(
        id: message.hashCode,
        title: title,
        body: body,
        payload: jsonEncode(message.data),
      );

      // Add to in-app notification list
      _notificationService.addNotification(
        type: message.data['resource'] == 'KYC'
            ? NotificationType.kyc
            : _mapType(typeStr),
        title: title,
        description: body,
        relatedId: message.data['referenceId'] ?? message.data['targetId'],
      );

      // Also trigger a background sync with backend
      _notificationService.refreshFromBackend();
    });

    // 2. Notification opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('[FCM] Notification opened from background: ${message.data}');
      }
      handleNotificationRouting(message.data);
    });

    // 3. App launched from terminated state via notification click
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        if (kDebugMode) {
          print(
            '[FCM] App opened from terminated state via push: ${message.data}',
          );
        }
        handleNotificationRouting(message.data);
      }
    });
  }

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  Future<void> syncToken([String? explicitToken]) async {
    try {
      String? token = explicitToken ?? _fcmToken;
      if (token == null || token.isEmpty) {
        try {
          await _messaging.register();
        } catch (_) {}
        // Fallback to legacy getToken for broad compatibility
        // ignore: deprecated_member_use
        token = _fcmToken ?? await _messaging.getToken();
      }
      if (token == null || token.isEmpty) return;

      _fcmToken = token;
      _storage.write('fcm_device_token', token);

      final platform = Platform.isIOS ? 'ios' : 'android';
      await _api.registerDeviceToken(token: token, platform: platform);

      if (kDebugMode) {
        print('[FCM] Device token registered successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[FCM] Device token registration error: $e');
      }
    }
  }

  Future<void> deleteToken() async {
    try {
      final token = _fcmToken ?? (_storage.read('fcm_device_token') as String?);
      if (token != null && token.isNotEmpty) {
        await _api.deleteDeviceToken(token);
        await _storage.remove('fcm_device_token');
        _fcmToken = null;
        if (kDebugMode) {
          print('[FCM] Device token deleted from backend');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[FCM] deleteToken error: $e');
      }
    }
  }

  void handleNotificationRouting(Map<String, dynamic> data) {
    final type = (data['type'] ?? '').toString().toUpperCase();
    final relatedId = (data['referenceId'] ?? data['targetId'] ?? data['id'])
        ?.toString();

    if (data['resource'] == 'KYC' || data['targetType'] == 'KYC') {
      _pendingKyc = true;
      flushKyc();
    } else if (type.contains('PROJECT')) {
      if (relatedId != null && relatedId.isNotEmpty) {
        Get.toNamed(
          AppRoutes.projectDetails,
          arguments: {'projectId': relatedId},
        );
      } else {
        Get.toNamed(AppRoutes.projects);
      }
    } else if (type.contains('INVESTMENT')) {
      if (relatedId != null && relatedId.isNotEmpty) {
        Get.toNamed(
          AppRoutes.investmentDetails,
          arguments: {'investmentId': relatedId},
        );
      } else {
        Get.toNamed(AppRoutes.myInvestments);
      }
    } else if (type.contains('RETURN')) {
      Get.toNamed(AppRoutes.returns);
    } else if (type.contains('WITHDRAWAL')) {
      Get.toNamed(AppRoutes.withdrawals);
    } else {
      Get.toNamed(AppRoutes.notifications);
    }
  }

  void flushKyc() {
    if (!_pendingKyc ||
        Get.context == null ||
        !Get.isRegistered<AuthController>() ||
        !Get.find<AuthController>().isLoggedIn.value ||
        Get.currentRoute == AppRoutes.splash ||
        Get.currentRoute == AppRoutes.login) {
      return;
    }
    _pendingKyc = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.find<AuthController>().isLoggedIn.value) {
        Get.toNamed(AppRoutes.kyc);
      }
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  NotificationType _mapType(String typeStr) {
    final upper = typeStr.toUpperCase();
    if (upper.contains('KYC')) return NotificationType.kyc;
    if (upper.contains('INVESTMENT')) return NotificationType.investmentSuccess;
    if (upper.contains('RETURN')) return NotificationType.returnReceived;
    if (upper.contains('WITHDRAWAL')) {
      return NotificationType.withdrawalApproved;
    }
    if (upper.contains('PROJECT_UPDATE')) return NotificationType.projectUpdate;
    return NotificationType.newProject;
  }
}
