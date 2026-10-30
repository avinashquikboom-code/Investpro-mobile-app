import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investpro/app/widgets/account_sync.dart';

void main() {
  testWidgets(
    'polls only authenticated foreground accounts and deduplicates requests',
    (tester) async {
      var calls = 0;
      Future<void> refresh() async {
        calls++;
      }

      Widget app(bool authenticated) => MaterialApp(
        home: AccountSync(
          authenticated: authenticated,
          refresh: refresh,
          interval: const Duration(seconds: 15),
          child: const SizedBox(),
        ),
      );
      await tester.pumpWidget(app(false));
      await tester.pump(const Duration(seconds: 20));
      expect(calls, 0);
      await tester.pumpWidget(app(true));
      await tester.pump();
      expect(calls, 1);
      await tester.pump(const Duration(seconds: 15));
      expect(calls, 2);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 30));
      expect(calls, 2);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(calls, 3);
      await tester.pumpWidget(app(false));
      await tester.pump(const Duration(seconds: 30));
      expect(calls, 3);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'silent failures keep child full size and back off instead of repeating banners',
    (tester) async {
      var calls = 0;
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: AccountSync(
            authenticated: true,
            refresh: () async {
              calls++;
              throw StateError('offline');
            },
            child: SizedBox.expand(
              key: key,
              child: const Text('Cached projects'),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(calls, 1);
      expect(find.text('Cached projects'), findsOneWidget);
      expect(find.textContaining('Synchronization unavailable'), findsNothing);
      expect(tester.getSize(find.byKey(key)), const Size(800, 600));
      await tester.pump(const Duration(seconds: 60));
      expect(calls, 1);
      await tester.pump(const Duration(seconds: 60));
      expect(calls, 2);
      expect(find.byType(ListTile), findsNothing);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets(
    'startup reuses initial screen loads and honors server retry deadline',
    (tester) async {
      var calls = 0;
      final deadline = DateTime.now().add(const Duration(minutes: 3));
      await tester.pumpWidget(
        MaterialApp(
          home: AccountSync(
            authenticated: true,
            initialRefresh: false,
            nextRetryAt: () => deadline,
            refresh: () async {
              calls++;
            },
            child: const Text('Projects'),
          ),
        ),
      );
      await tester.pump(const Duration(minutes: 2));
      expect(calls, 0);
      await tester.pumpWidget(const SizedBox());
    },
  );
  testWidgets('in-flight refresh cannot overlap polling or resume', (
    tester,
  ) async {
    var calls = 0;
    final pending = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: AccountSync(
          authenticated: true,
          refresh: () {
            calls++;
            return pending.future;
          },
          child: const SizedBox(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(minutes: 2));
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    expect(calls, 1);
    pending.complete();
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
  });
}
