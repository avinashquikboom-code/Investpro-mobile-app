import 'package:get/get.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';

class NotificationController extends GetxController {
  final NotificationService _service;

  NotificationController(this._service);

  List<NotificationModel> get notifications => _service.notifications;
  int get unreadCount => _service.unreadCount;

  void markAsRead(String id) {
    _service.markAsRead(id);
  }

  void markAllAsRead() {
    _service.markAllAsRead();
  }
}
