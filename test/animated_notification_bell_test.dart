import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investpro/app/widgets/animated_notification_bell.dart';
import 'package:remixicon/remixicon.dart';

void main() {
  group('AnimatedNotificationBell Widget Tests', () {
    testWidgets('renders static bell when hasNotification is false', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AnimatedNotificationBell(
                hasNotification: false,
                unreadCount: 0,
              ),
            ),
          ),
        ),
      );

      // Verify Remix.notification_line is present
      expect(find.byIcon(Remix.notification_line), findsOneWidget);

      // No red badge circle is rendered when hasNotification is false
      // In AnimatedNotificationBell, the Positioned badge only exists if hasNotification is true
      expect(find.byType(Positioned), findsNothing);
    });

    testWidgets('renders badge and animates when hasNotification is true', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: AnimatedNotificationBell(
                hasNotification: true,
                unreadCount: 3,
                onTap: () {
                  tapped = true;
                },
              ),
            ),
          ),
        ),
      );

      // Verify Remix.notification_line is present
      expect(find.byIcon(Remix.notification_line), findsOneWidget);

      // Badge is present
      expect(find.byType(Positioned), findsOneWidget);

      // Advance animation slightly
      await tester.pump(const Duration(milliseconds: 200));

      // Test tap callback
      await tester.tap(find.byType(AnimatedNotificationBell));
      expect(tapped, isTrue);
    });

    testWidgets('dynamically toggles animation when hasNotification updates', (tester) async {
      final valueNotifier = ValueNotifier<bool>(false);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ValueListenableBuilder<bool>(
                valueListenable: valueNotifier,
                builder: (context, hasNotif, _) {
                  return AnimatedNotificationBell(
                    hasNotification: hasNotif,
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.byType(Positioned), findsNothing);

      // Update to true
      valueNotifier.value = true;
      await tester.pump();
      expect(find.byType(Positioned), findsOneWidget);

      // Update back to false
      valueNotifier.value = false;
      await tester.pump();
      expect(find.byType(Positioned), findsNothing);
    });

    testWidgets('badge is correctly positioned at top-right corner of bell in circular container', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: AnimatedNotificationBell(
                hasNotification: true,
                unreadCount: 1,
                size: 22,
                containerSize: 42,
              ),
            ),
          ),
        ),
      );

      final iconRect = tester.getRect(find.byIcon(Remix.notification_line));
      final badgeWidget = tester.widget<Positioned>(find.byType(Positioned));

      // Badge must be positioned at the top-right corner of the bell icon (-2.0, -2.0 relative to 22x22 icon)
      expect(badgeWidget.top, equals(-2.0));
      expect(badgeWidget.right, equals(-2.0));
      expect(iconRect.width, equals(22.0));
      expect(iconRect.height, equals(22.0));
    });
  });
}
