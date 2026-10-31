import 'package:flutter_test/flutter_test.dart';
import 'package:investpro/app/models/notification_model.dart';
import 'package:investpro/app/controllers/subscription_controller.dart';
import 'package:investpro/app/services/api_service.dart';

class MockApiService extends ApiService {
  MockApiService() : super();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Subscription Lifecycle Notifications and Status Tests', () {
    test('NotificationModel parses SUBSCRIPTION_ACTIVATED correctly', () {
      final json = {
        'id': 'notif-1',
        'type': 'SUBSCRIPTION_ACTIVATED',
        'targetType': 'SUBSCRIPTION',
        'title': 'Subscription Activated',
        'body': 'Your Growth Tier subscription is now active until 15 Nov 2026.',
        'createdAt': '2026-10-31T10:00:00.000Z',
      };

      final notif = NotificationModel.fromJson(json);
      expect(notif.type, NotificationType.subscriptionActivated);
      expect(notif.title, 'Subscription Activated');
      expect(notif.description, contains('Growth Tier'));
    });

    test('NotificationModel parses SUBSCRIPTION_EXPIRING correctly', () {
      final json = {
        'id': 'notif-2',
        'type': 'SUBSCRIPTION_EXPIRING',
        'targetType': 'SUBSCRIPTION',
        'title': 'Subscription Expiring Soon',
        'body': 'Your Growth Tier subscription expires in 3 days on 03 Nov 2026.',
        'createdAt': '2026-10-31T10:00:00.000Z',
      };

      final notif = NotificationModel.fromJson(json);
      expect(notif.type, NotificationType.subscriptionExpiring);
      expect(notif.title, 'Subscription Expiring Soon');
      expect(notif.description, contains('expires in 3 days'));
    });

    test('NotificationModel parses SUBSCRIPTION_EXPIRED correctly', () {
      final json = {
        'id': 'notif-3',
        'type': 'SUBSCRIPTION_EXPIRED',
        'targetType': 'SUBSCRIPTION',
        'title': 'Subscription Expired',
        'body': 'Your Growth Tier subscription has expired.',
        'createdAt': '2026-10-31T10:00:00.000Z',
      };

      final notif = NotificationModel.fromJson(json);
      expect(notif.type, NotificationType.subscriptionExpired);
      expect(notif.title, 'Subscription Expired');
    });

    test('SubscriptionController correctly calculates active and expiring soon', () {
      final controller = SubscriptionController(
        MockApiService(),
        readIntent: (_) async => null,
        writeIntent: (_, _) async {},
      );

      final now = DateTime.now();
      final expiringDate = now.add(const Duration(days: 2));

      controller.current.value = {
        'id': 'sub-1',
        'status': 'ACTIVE',
        'startDate': now.subtract(const Duration(days: 28)).toIso8601String(),
        'endDate': expiringDate.toIso8601String(),
        'remainingDays': 2,
        'isExpiringSoon': true,
        'plan': {
          'id': 'plan-1',
          'name': 'Growth Tier',
          'price': 1499,
        },
      };

      expect(controller.hasActivePlan, isTrue);
      expect(controller.isExpiringSoon, isTrue);
      expect(controller.isExpired, isFalse);
      expect(controller.remainingDays, 2);
      expect(controller.currentPlanName, 'Growth Tier');
    });

    test('SubscriptionController correctly detects expired status', () {
      final controller = SubscriptionController(
        MockApiService(),
        readIntent: (_) async => null,
        writeIntent: (_, _) async {},
      );

      final now = DateTime.now();
      final expiredDate = now.subtract(const Duration(days: 1));

      controller.current.value = {
        'id': 'sub-2',
        'status': 'EXPIRED',
        'lifecycleStatus': 'EXPIRED',
        'startDate': now.subtract(const Duration(days: 31)).toIso8601String(),
        'endDate': expiredDate.toIso8601String(),
        'remainingDays': 0,
        'isExpiringSoon': false,
        'plan': {
          'id': 'plan-1',
          'name': 'Growth Tier',
          'price': 1499,
        },
      };

      expect(controller.hasActivePlan, isFalse);
      expect(controller.isExpiringSoon, isFalse);
      expect(controller.isExpired, isTrue);
      expect(controller.remainingDays, 0);
    });
  });
}
