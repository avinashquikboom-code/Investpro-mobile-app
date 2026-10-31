import 'package:get/get.dart';

import '../models/notification_model.dart';
import '../routes/app_routes.dart';
import '../services/notification_service.dart';
import 'project_controller.dart';

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

  Future<void> refreshNotifications() async {
    await _service.refreshFromBackend();
  }

  void handleNotificationTap(NotificationModel notif) {
    markAsRead(notif.id);
    if (notif.targetType == 'SUBSCRIPTION' ||
        notif.type == NotificationType.subscriptionActivated ||
        notif.type == NotificationType.subscriptionExpiring ||
        notif.type == NotificationType.subscriptionExpired) {
      if (Get.isRegistered<ProjectController>()) {
        Get.find<ProjectController>().loadSubscriptionEligibility();
        Get.find<ProjectController>().refreshProjects();
      }
      Get.toNamed(AppRoutes.subscriptionPlans);
      return;
    }
    if (notif.targetType == 'OFFLINE_PAYMENT') { Get.toNamed(AppRoutes.offlinePayments, arguments: notif.relatedId); return; }
    final relatedId = notif.relatedId;

    switch (notif.type) {
      case NotificationType.subscriptionActivated:
      case NotificationType.subscriptionExpiring:
      case NotificationType.subscriptionExpired:
        if (Get.isRegistered<ProjectController>()) {
          Get.find<ProjectController>().loadSubscriptionEligibility();
          Get.find<ProjectController>().refreshProjects();
        }
        Get.toNamed(AppRoutes.subscriptionPlans);
        break;
      case NotificationType.requestUpdate:
        Get.toNamed(AppRoutes.requests,arguments:notif.relatedId);
        break;
      case NotificationType.investorWelcome:
      case NotificationType.kyc:
        Get.toNamed(AppRoutes.kyc);
        break;
      case NotificationType.investmentSuccess:
        if (relatedId != null && relatedId.isNotEmpty) {
          Get.toNamed(
            AppRoutes.investmentDetails,
            arguments: {'investmentId': relatedId},
          );
        } else {
          Get.toNamed(AppRoutes.myInvestments);
        }
        break;
      case NotificationType.returnReceived:
        Get.toNamed(AppRoutes.returns);
        break;
      case NotificationType.withdrawalApproved:
        Get.toNamed(AppRoutes.withdrawals);
        break;
      case NotificationType.projectUpdate:
      case NotificationType.newProject:
        if (relatedId != null && relatedId.isNotEmpty) {
          Get.toNamed(
            AppRoutes.projectDetails,
            arguments: {'projectId': relatedId},
          );
        } else {
          Get.toNamed(AppRoutes.projects);
        }
        break;
    }
  }
}
