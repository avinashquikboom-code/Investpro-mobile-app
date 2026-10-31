import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';

import '../controllers/auth_controller.dart';
import '../controllers/project_controller.dart';
import '../routes/app_routes.dart';
import 'api_service.dart';
import 'local_storage_service.dart';
import 'notification_service.dart';
import 'demo_repository.dart';

/// Top-level background message handler required by Firebase Messaging
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  if (kDebugMode) {
    print('[FCM] Handling background push: ${message.messageId}');
  }
}

class FirebaseNotificationService extends GetxService with WidgetsBindingObserver {
  final LocalStorageService _storage;
  final ApiService _api;
  final NotificationService _notificationService;

  final FirebaseMessaging _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final Set<String> _welcomeShown = {};

  static const String channelId = 'investpro_high_importance_channel';
  static const String channelName = 'InvestPro Push Notifications';
  static const String channelDescription =
      'High-priority transaction, investment and update notifications';

  static const String campaignChannelId = 'investpro_campaigns';
  static const String campaignChannelName = 'InvestPro Campaigns & Promotions';
  static const String campaignChannelDescription =
      'Special investment campaigns, project launches, promotions and announcements';

  final _subscriptions = <StreamSubscription<dynamic>>[];
  Map<String, dynamic>? _pendingNavigation;
  bool _pendingKyc = false;
  String? _pendingRequest;
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  FirebaseNotificationService(
    this._storage,
    this._api,
    this._notificationService, {
    FirebaseMessaging? messaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  }) : _messaging = messaging ?? FirebaseMessaging.instance,
       _localNotifications = localNotifications ?? FlutterLocalNotificationsPlugin();

  Future<FirebaseNotificationService> init() async {
    WidgetsBinding.instance.addObserver(this);
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await _setupLocalNotifications();
      await requestPermissions();
      // Foreground presentation is owned by the local plugin, avoiding two iOS alerts.
      await _messaging.setForegroundNotificationPresentationOptions(alert: false, badge: false, sound: false);
      _setupMessageListeners();
      // Listen for token registration & refresh events
      _subscriptions.add(_messaging.onRegistered.listen((newToken) {
        if (kDebugMode) {
          print('[FCM] Device token refreshed');
        }
        _fcmToken = newToken;
        syncToken(newToken);
      }));

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

    final launch = await _localNotifications.getNotificationAppLaunchDetails();
    final payload = launch?.notificationResponse?.payload;
    if (launch?.didNotificationLaunchApp == true && payload != null) {
      try { handleNotificationRouting(Map<String, dynamic>.from(jsonDecode(payload) as Map)); } catch (_) {}
    }

    // Create high importance notification channels on Android
    const defaultChannel = AndroidNotificationChannel(
      channelId,
      channelName,
      description: channelDescription,
      importance: Importance.max,
      playSound: true,
    );

    const campaignChannel = AndroidNotificationChannel(
      campaignChannelId,
      campaignChannelName,
      description: campaignChannelDescription,
      importance: Importance.max,
      playSound: true,
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidPlugin?.createNotificationChannel(defaultChannel);
    await androidPlugin?.createNotificationChannel(campaignChannel);
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
    _subscriptions.add(FirebaseMessaging.onMessage.listen(handleForegroundMessage));

    // 2. Notification opened from background
    _subscriptions.add(FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('[FCM] Notification opened from background: ${message.messageId}');
      }
      handleNotificationRouting(message.data);
    }));

    // 3. App launched from terminated state via notification click
    _messaging.getInitialMessage().then((RemoteMessage? message) {
      if (message != null) {
        if (kDebugMode) {
          print(
            '[FCM] App opened from terminated state via push: ${message.messageId}',
          );
        }
        handleNotificationRouting(message.data);
      }
    });
  }

  Future<void> handleForegroundMessage(RemoteMessage message) async {
    if (kDebugMode) {
      print('[FCM] Foreground push received: ${message.messageId}');
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
    final isCampaign = typeStr.toUpperCase() == 'CAMPAIGN' ||
        message.data['type']?.toString().toUpperCase() == 'CAMPAIGN' ||
        message.data['campaignId'] != null;

    final targetChannelId = isCampaign ? campaignChannelId : channelId;
    final targetChannelName = isCampaign ? campaignChannelName : channelName;
    final targetChannelDesc = isCampaign ? campaignChannelDescription : channelDescription;

    final welcome = typeStr.toUpperCase() == 'INVESTOR_WELCOME' || message.data['event'] == 'INVESTOR_WELCOME';
    if (welcome || message.data['resource']=='REQUEST') {
      // The server record is authoritative: never insert a second synthetic history row.
      _notificationService.refreshFromBackend().catchError((_) {});
      final id = message.data['notificationId']?.toString() ?? message.messageId;
      if (id == null || (_welcomeShown.add(id) && _storage.read('welcome_push_seen_$id') != true)) {
        if (id != null) await _storage.write('welcome_push_seen_$id', true);
        await _showLocalNotification(
          id: message.hashCode,
          title: title,
          body: body,
          payload: jsonEncode(message.data),
          channel: targetChannelId,
          channelName: targetChannelName,
          channelDesc: targetChannelDesc,
        ).catchError((_) {});
      }
      return;
    }

    // Show local heads-up notification
    _showLocalNotification(
      id: message.hashCode,
      title: title,
      body: body,
      payload: jsonEncode(message.data),
      channel: targetChannelId,
      channelName: targetChannelName,
      channelDesc: targetChannelDesc,
    );

    // Server history owns notification IDs, unread counts and pagination.
    await _notificationService.refreshFromBackend();
    if ((typeStr.toUpperCase().contains('INVESTMENT') || message.data['resource'] == 'OFFLINE_PAYMENT' || message.data['event']?.startsWith('OFFLINE_PAYMENT_') == true) && Get.isRegistered<DemoRepository>()) {
      Get.find<DemoRepository>().syncFromBackend().catchError((Object _) {});
    }
  }

  Future<void> _showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
    String? channel,
    String? channelName,
    String? channelDesc,
  }) async {
    final effectiveChannelId = channel ?? channelId;
    final effectiveChannelName = channelName ?? FirebaseNotificationService.channelName;
    final effectiveChannelDesc = channelDesc ?? channelDescription;

    final androidDetails = AndroidNotificationDetails(
      effectiveChannelId,
      effectiveChannelName,
      channelDescription: effectiveChannelDesc,
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

    final details = NotificationDetails(
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
      final accessToken = await _api.getAccessToken();
      if (accessToken == null || accessToken.isEmpty) return;
      await requestPermissions();
      if (Platform.isIOS && await _messaging.getAPNSToken() == null) {
        debugPrint('[FCM] APNs registration pending; retry on resume');
        return;
      }
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
      var deviceId = _storage.read('push_device_id') as String?;
      deviceId ??= base64UrlEncode(List.generate(24, (_) => Random.secure().nextInt(256)));
      await _storage.write('push_device_id', deviceId);
      final registered = await _api.registerDeviceToken(token: token, platform: platform, deviceId: deviceId);
      if (!registered) return;

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
        await _messaging.unregister();
        _pendingNavigation = null;
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
    if (data['appType'] == 'ADMIN' || data['audience'] == 'ADMIN') return;
    if (Get.context == null || !Get.isRegistered<AuthController>() ||
        !Get.find<AuthController>().isLoggedIn.value ||
        Get.currentRoute == AppRoutes.splash || Get.currentRoute == AppRoutes.login) {
      _pendingNavigation = Map<String, dynamic>.from(data);
      return;
    }
    final type = (data['type'] ?? '').toString().toUpperCase();
    final relatedId = (data['referenceId'] ?? data['targetId'] ?? data['id'])
        ?.toString();

    // 1. Process custom deep link if present
    final deepLink = (data['deepLink'] ?? '').toString();
    if (deepLink.isNotEmpty && _handleDeepLinkRouting(deepLink, data)) {
      return;
    }

    // 2. Campaign routing
    if (type == 'CAMPAIGN' || data['campaignId'] != null) {
      final projectId = (data['projectId'] ?? data['targetId'])?.toString();
      if (projectId != null && projectId.isNotEmpty) {
        Get.toNamed(
          AppRoutes.projectDetails,
          arguments: {'projectId': projectId},
        );
        return;
      }
      Get.toNamed(AppRoutes.notifications);
      return;
    }

    if (data['resource'] == 'SUBSCRIPTION' || data['targetType'] == 'SUBSCRIPTION' || type.contains('SUBSCRIPTION')) {
      if (Get.isRegistered<ProjectController>()) {
        Get.find<ProjectController>().loadSubscriptionEligibility();
        Get.find<ProjectController>().refreshProjects();
      }
      Get.toNamed(AppRoutes.subscriptionPlans);
      return;
    }
    if (data['resource'] == 'OFFLINE_PAYMENT' || data['targetType'] == 'OFFLINE_PAYMENT') {
      Get.toNamed(AppRoutes.offlinePayments, arguments: relatedId);
    } else if (type == 'INVESTOR_WELCOME' || data['event'] == 'INVESTOR_WELCOME' || data['resource'] == 'KYC' || data['targetType'] == 'KYC') {
      _pendingKyc = true;
      flushKyc();
    } else if (data['resource'] == 'REQUEST' || type == 'REQUEST_UPDATED') {
      _pendingRequest = relatedId ?? '';
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
    } else if (type.contains('INVESTMENT') || data['resource'] == 'INVESTMENT') {
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

  bool _handleDeepLinkRouting(String deepLink, Map<String, dynamic> data) {
    var path = deepLink.trim();
    if (path.isEmpty) return false;

    if (path.contains('://')) {
      final uri = Uri.tryParse(path);
      if (uri != null) {
        path = uri.path;
      }
    }
    if (path.startsWith('/')) {
      path = path.substring(1);
    }

    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return false;

    final first = segments[0].toLowerCase();
    if (first == 'projects' || first == 'project') {
      if (segments.length > 1) {
        final projectId = segments[1];
        Get.toNamed(AppRoutes.projectDetails, arguments: {'projectId': projectId});
      } else {
        Get.toNamed(AppRoutes.projects);
      }
      return true;
    } else if (first == 'investments' || first == 'investment') {
      if (segments.length > 1) {
        Get.toNamed(AppRoutes.investmentDetails, arguments: {'investmentId': segments[1]});
      } else {
        Get.toNamed(AppRoutes.myInvestments);
      }
      return true;
    } else if (first == 'returns' || first == 'return') {
      Get.toNamed(AppRoutes.returns);
      return true;
    } else if (first == 'withdrawals' || first == 'withdrawal') {
      Get.toNamed(AppRoutes.withdrawals);
      return true;
    } else if (first == 'kyc') {
      Get.toNamed(AppRoutes.kyc);
      return true;
    } else if (first == 'notifications' || first == 'notification') {
      Get.toNamed(AppRoutes.notifications);
      return true;
    } else if (first == 'offline-payments' || first == 'offline_payments') {
      Get.toNamed(AppRoutes.offlinePayments);
      return true;
    } else if (first == 'subscriptions' || first == 'subscription') {
      if (Get.isRegistered<ProjectController>()) {
        Get.find<ProjectController>().loadSubscriptionEligibility();
        Get.find<ProjectController>().refreshProjects();
      }
      Get.toNamed(AppRoutes.subscriptionPlans);
      return true;
    }

    return false;
  }

  void flushKyc() {
    if (_pendingNavigation != null && Get.context != null &&
        Get.isRegistered<AuthController>() && Get.find<AuthController>().isLoggedIn.value &&
        Get.currentRoute != AppRoutes.splash && Get.currentRoute != AppRoutes.login) {
      final data = _pendingNavigation!;
      _pendingNavigation = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => handleNotificationRouting(data));
      WidgetsBinding.instance.scheduleFrame();
    }
    if ((!_pendingKyc && _pendingRequest == null) ||
        Get.context == null ||
        !Get.isRegistered<AuthController>() ||
        !Get.find<AuthController>().isLoggedIn.value ||
        Get.currentRoute == AppRoutes.splash ||
        Get.currentRoute == AppRoutes.login) {
      return;
    }
    final request = _pendingRequest;
    _pendingRequest = null;
    _pendingKyc = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (Get.find<AuthController>().isLoggedIn.value) {
        if(request!=null) { Get.toNamed(AppRoutes.requests,arguments:request.isEmpty?null:request); } else { Get.toNamed(AppRoutes.kyc); }
      }
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) { syncToken(); flushKyc(); }
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    for (final subscription in _subscriptions) { subscription.cancel(); }
    super.onClose();
  }
}
