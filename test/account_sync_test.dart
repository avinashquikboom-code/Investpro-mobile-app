import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:investpro/app/widgets/account_sync.dart';

void main() {
  testWidgets('polls only authenticated foreground accounts and deduplicates requests', (tester) async {
    var calls = 0;
    Future<void> refresh() async { calls++; }
    Widget app(bool authenticated) => MaterialApp(home: AccountSync(authenticated: authenticated, refresh: refresh, child: const SizedBox()));
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
  });
}
