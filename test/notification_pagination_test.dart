import 'package:flutter_test/flutter_test.dart';
import 'package:investpro/app/services/api_service.dart';
import 'package:investpro/app/services/local_storage_service.dart';
import 'package:investpro/app/services/notification_service.dart';

class MemoryStore implements LocalStore {
  final values = <String, dynamic>{};
  @override
  dynamic read(String key) => values[key];
  @override
  Future<void> write(String key, dynamic value) async { values[key] = value; }
}
Map<String, dynamic> row(int id) => {'id': '$id', 'type': 'RETURN', 'title': 'Return', 'message': 'Credited', 'createdAt': '2026-10-31T10:00:00Z', 'isRead': false};
class PageApi extends ApiService {
  bool fail = false;
  bool switchAccount = false;
  final pages = <int>[];
  @override
  Future<String?> getAccessToken() async => 'session';
  @override
  Future<List<dynamic>?> getNotifications() async => List.generate(50, row);
  @override
  Future<int?> getUnreadNotificationCount() async => 55;
  @override
  Future<Map<String, dynamic>> getNotificationsPage(int page) async {
    pages.add(page);
    if (fail) throw StateError('offline');
    if (switchAccount) sessionVersion++;
    return {'notifications': [row(49), row(50)], 'hasMore': false};
  }
}
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('loads older server history without duplicates or changing authoritative unread count', () async {
    final api = PageApi();
    final service = await NotificationService(LocalStorageService(backend: MemoryStore()), api).init();
    await service.refreshFromBackend();
    expect(service.hasMore.value, true);
    await service.loadMore();
    expect(api.pages, [2]);
    expect(service.notifications.length, 51);
    expect(service.unreadCount, 55);
    expect(service.hasMore.value, false);
  });
  test('pagination failure preserves cached history and retries the same page', () async {
    final api = PageApi()..fail = true;
    final service = await NotificationService(LocalStorageService(backend: MemoryStore()), api).init();
    await service.refreshFromBackend();
    await service.loadMore();
    expect(service.notifications.length, 50);
    expect(service.paginationError.value, isNotEmpty);
    api.fail = false;
    await service.loadMore();
    expect(api.pages, [2, 2]);
    expect(service.paginationError.value, isEmpty);
  });
  test('account switching discards an older account page response', () async {
    final api = PageApi()..switchAccount = true;
    final service = await NotificationService(LocalStorageService(backend: MemoryStore()), api).init();
    await service.refreshFromBackend();
    await service.loadMore();
    expect(service.notifications.length, 50);
  });
}
