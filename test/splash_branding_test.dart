import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:investpro/app/views/splash/splash_branding.dart';
void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  for (final size in [const Size(320, 568), const Size(844, 390), const Size(768, 1024)]) {
    testWidgets('splash fits $size with large text', (tester) async {
      tester.view.physicalSize = size; tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(home: MediaQuery(data: MediaQueryData(size: size, textScaler: TextScaler.linear(1.6)), child: const Scaffold(body: SplashBranding(scale: AlwaysStoppedAnimation(1), error: Text('Connection unavailable. Retry.'))))));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.textContaining('INVESTPRO  /'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
