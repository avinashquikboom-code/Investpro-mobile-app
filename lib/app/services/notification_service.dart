import 'package:get/get.dart';

import '../models/notification_model.dart';
import 'api_service.dart';
import 'local_storage_service.dart';
import '../constants/app_constants.dart';

class NotificationService extends GetxService {
  final LocalStorageService _storage;
  final ApiService? _api;
  RxList<NotificationModel> notifications = <NotificationModel>[].obs;

  NotificationService(this._storage, [this._api]);

  int get unreadCount => notifications.where((n) => !n.isRead).length;

  Future<NotificationService> init() async {
    loadNotifications();
    refreshFromBackend();
    return this;
  }

  Future<void> refreshFromBackend() async {
    if (_api == null) return;
    try {
      final list = await _api.getNotifications();
      if (list != null && list.isNotEmpty) {
        final parsed = list
            .map(
              (e) => NotificationModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();
        notifications.value = parsed;
        _saveToStorage();
      }
    } catch (_) {}
  }

  void loadNotifications() {
    final raw = _storage.readList(AppConstants.keyNotificationsData);
    if (raw != null && raw.isNotEmpty) {
      notifications.value = raw
          .map(
            (e) =>
                NotificationModel.fromJson(Map<String, dynamic>.from(e as Map)),
          )
          .toList();
    } else {
      _seedInitialNotifications();
    }
  }

  void _seedInitialNotifications() {
    final initial = [
      NotificationModel(
        id: 'NOTIF-001',
        type: NotificationType.investmentSuccess,
        title: 'Investment Successful',
        description: 'Your investment of ₹ 50,000 has been placed.',
        timestamp: DateTime(2026, 4, 12, 10, 30),
        isRead: false,
      ),
      NotificationModel(
        id: 'NOTIF-002',
        type: NotificationType.returnReceived,
        title: 'Return Received',
        description: '₹ 1,500 credited to your account.',
        timestamp: DateTime(2026, 4, 5, 10, 25),
        isRead: false,
      ),
      NotificationModel(
        id: 'NOTIF-003',
        type: NotificationType.withdrawalApproved,
        title: 'Withdrawal Request Approved',
        description: 'Your withdrawal request of ₹ 5,000 has been approved.',
        timestamp: DateTime(2026, 3, 28, 16, 12),
        isRead: true,
      ),
      NotificationModel(
        id: 'NOTIF-004',
        type: NotificationType.projectUpdate,
        title: 'Project Update',
        description: 'Software Development Platform reached 50% development.',
        timestamp: DateTime(2026, 3, 20, 11, 20),
        isRead: true,
      ),
      NotificationModel(
        id: 'NOTIF-005',
        type: NotificationType.newProject,
        title: 'New Project Available',
        description: 'AI Automation Tool is now live.',
        timestamp: DateTime(2026, 3, 15, 9, 45),
        isRead: true,
      ),
    ];
    notifications.value = initial;
    _saveToStorage();
  }

  void markAsRead(String id) {
    final idx = notifications.indexWhere((n) => n.id == id);
    if (idx != -1) {
      notifications[idx] = notifications[idx].copyWith(isRead: true);
      _saveToStorage();
    }
    _api?.markNotificationRead(id).catchError((_) => false);
  }

  void markAllAsRead() {
    notifications.value = notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    _saveToStorage();
    _api?.markAllNotificationsRead().catchError((_) => false);
  }

  void addNotification({
    required NotificationType type,
    required String title,
    required String description,
    String? relatedId,
  }) {
    if (!_storage.notificationsEnabled) return;

    final newNotif = NotificationModel(
      id: 'NOTIF-${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      title: title,
      description: description,
      timestamp: DateTime.now(),
      isRead: false,
      relatedId: relatedId,
    );
    notifications.insert(0, newNotif);
    _saveToStorage();
  }

  void _saveToStorage() {
    _storage.writeList(
      AppConstants.keyNotificationsData,
      notifications.map((n) => n.toJson()).toList(),
    );
  }
}
