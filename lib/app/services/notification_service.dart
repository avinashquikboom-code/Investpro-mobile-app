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

  final hasMore = false.obs;
  final loadingMore = false.obs;
  final paginationError = ''.obs;
  int _page = 1;
  int _historyVersion = 0;

  final RxnInt _serverUnreadCount = RxnInt();
  int get unreadCount => _serverUnreadCount.value ?? notifications.where((n) => !n.isRead).length;

  void clear() {
    notifications.clear();
    _historyVersion++;
    _page = 1;
    hasMore.value = false;
    paginationError.value = '';
    _serverUnreadCount.value = null;
  }

  Future<NotificationService> init() async {
    if (_api == null) { loadNotifications(); } else { notifications.clear(); }
    return this;
  }

  Future<void> refreshFromBackend() async {
    if (_api == null) return;
    try {
      final version = ++_historyVersion;
      final session = _api.sessionVersion;
      final token = await _api.getAccessToken();
      if (token == null || token.isEmpty) { clear(); return; }
      final list = await _api.getNotifications();
      final count = await _api.getUnreadNotificationCount();
      if (session != _api.sessionVersion || version != _historyVersion) return;
      if (list != null) {
        final parsed = list
            .map(
              (e) => NotificationModel.fromJson(
                Map<String, dynamic>.from(e as Map),
              ),
            )
            .toList();
        _page = 1;
        hasMore.value = list.length == 50;
        paginationError.value = '';
        notifications.value = parsed;
        _serverUnreadCount.value = count;
        _saveToStorage();
      }
    } catch (_) { rethrow; }
  }

  Future<void> loadMore() async {
    if (_api == null || !hasMore.value || loadingMore.value) return;
    loadingMore.value = true;
    final version = _historyVersion;
    final session = _api.sessionVersion;
    try {
      final result = await _api.getNotificationsPage(_page + 1);
      if (version != _historyVersion || session != _api.sessionVersion) return;
      final rows = (result['notifications'] as List).map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e as Map)));
      final ids = notifications.map((n) => n.id).toSet();
      notifications.addAll(rows.where((n) => ids.add(n.id)));
      _page++;
      hasMore.value = result['hasMore'] == true;
      paginationError.value = '';
      _saveToStorage();
    } catch (_) {
      if (version == _historyVersion && session == _api.sessionVersion) paginationError.value = 'Unable to load older notifications. Tap to retry.';
    } finally { loadingMore.value = false; }
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
      if (!notifications[idx].isRead && _serverUnreadCount.value != null && _serverUnreadCount.value! > 0) _serverUnreadCount.value = _serverUnreadCount.value! - 1;
      notifications[idx] = notifications[idx].copyWith(isRead: true);
      _saveToStorage();
    }
    _api?.markNotificationRead(id).catchError((_) => false);
  }

  void markAllAsRead() {
    _serverUnreadCount.value = _api == null ? null : 0;
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
    if (_serverUnreadCount.value != null) _serverUnreadCount.value = _serverUnreadCount.value! + 1;
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
