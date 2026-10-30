import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:investpro/app/controllers/navigation_controller.dart';
import 'package:investpro/app/widgets/bottom_nav_bar.dart';

void main() {
  tearDown(Get.reset);
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    for (final width in [375.0, 768.0]) {
      testWidgets('$platform navigation variants and taps at $width', (
        tester,
      ) async {
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final controller = Get.put(NavigationController());
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(platform: platform),
            home: const Scaffold(bottomNavigationBar: CustomBottomNavBar()),
          ),
        );
        expect(find.byIcon(Remix.home_4_fill), findsOneWidget);
        expect(find.byIcon(Remix.apps_line), findsOneWidget);
        await tester.tap(find.byIcon(Remix.apps_line));
        await tester.pump();
        expect(controller.currentIndex.value, 1);
        expect(find.byIcon(Remix.apps_fill), findsOneWidget);
        expect(find.byIcon(Remix.home_4_line), findsOneWidget);
        for (final icon in tester.widgetList<Icon>(find.byType(Icon))) {
          expect(icon.size, 24);
          expect(icon.icon!.fontPackage, 'remixicon');
        }
        expect(tester.takeException(), isNull);
      });
    }
  }
}
