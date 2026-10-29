import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:investpro/app/widgets/app_app_bar.dart';
import 'package:investpro/app/widgets/app_back_button.dart';
import 'package:investpro/app/widgets/unsaved_changes_guard.dart';

void main() {
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets(
      '$platform aligns titles and selects the correct back control',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: ThemeData(platform: platform),
            home: Scaffold(
              appBar: AppAppBar(
                title: 'Project Details',
                showBackButton: true,
                onBackPressed: () {},
                actions: [
                  IconButton(
                    tooltip: 'Refresh',
                    icon: const Icon(Icons.refresh),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        );
        final bar = tester.widget<AppBar>(find.byType(AppBar));
        expect(bar.centerTitle, platform == TargetPlatform.iOS);
        expect(
          find.byIcon(
            platform == TargetPlatform.iOS
                ? CupertinoIcons.back
                : Icons.arrow_back,
          ),
          findsOneWidget,
        );
        expect(find.byTooltip('Refresh'), findsOneWidget);
        expect(
          tester.getSize(find.byType(AppBackButton)).width,
          greaterThanOrEqualTo(48),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'root has no back and root drawer opens safely through nested Scaffolds',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            drawer: const Drawer(child: Text('Drawer content')),
            body: Scaffold(
              appBar: const AppAppBar(
                title: 'Dashboard',
                showBackButton: false,
                showMenuButton: true,
              ),
            ),
          ),
        ),
      );
      expect(find.byType(AppBackButton), findsNothing);
      await tester.tap(find.byIcon(Icons.menu));
      await tester.pumpAndSettle();
      expect(find.text('Drawer content'), findsOneWidget);
    },
  );

  testWidgets('no previous route never opens a blank screen', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          appBar: AppAppBar(title: 'Deep Link', showBackButton: true),
        ),
      ),
    );
    await tester.tap(find.byType(AppBackButton));
    await tester.pumpAndSettle();
    expect(find.text('Deep Link'), findsOneWidget);
  });

  for (final brightness in [Brightness.light, Brightness.dark]) {
    testWidgets('$brightness updates AppBar and overlay contrast', (
      tester,
    ) async {
      final theme = ThemeData(brightness: brightness);
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Scaffold(appBar: const AppAppBar(title: 'My Profile')),
        ),
      );
      final bar = tester.widget<AppBar>(find.byType(AppBar));
      expect(bar.backgroundColor, theme.colorScheme.surface);
      expect(
        bar.systemOverlayStyle!.statusBarIconBrightness,
        brightness == Brightness.dark ? Brightness.light : Brightness.dark,
      );
      expect(
        bar.systemOverlayStyle!.systemNavigationBarColor,
        Colors.transparent,
      );
    });
  }

  for (final width in [320.0, 375.0, 844.0, 1024.0]) {
    testWidgets('long title, subtitle, actions and scaled text at $width', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(2),
              padding: EdgeInsets.only(top: 44),
            ),
            child: Scaffold(
              appBar: AppAppBar(
                title: 'Very long title ' * 8,
                subtitle: 'Manage your account information',
                showBackButton: true,
                actions: [
                  IconButton(icon: const Icon(Icons.refresh), onPressed: () {}),
                ],
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.widget<Text>(find.text('Very long title ' * 8)).overflow,
        TextOverflow.ellipsis,
      );
    });
  }

  testWidgets('platform override and explicit alignment remain available', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: TargetPlatform.android),
        home: Scaffold(
          appBar: AppAppBar(
            title: 'Override',
            platform: TargetPlatform.iOS,
            centerTitle: false,
            showBackButton: true,
            onBackPressed: () {},
          ),
        ),
      ),
    );
    expect(tester.widget<AppBar>(find.byType(AppBar)).centerTitle, false);
    expect(find.byIcon(CupertinoIcons.back), findsOneWidget);
  });

  testWidgets('GetX native route preserves arguments and iOS swipe back', (
    tester,
  ) async {
    Get.testMode = true;
    addTearDown(() => Get.reset());
    await tester.pumpWidget(
      GetMaterialApp(
        theme: ThemeData(platform: TargetPlatform.iOS),
        defaultTransition: Transition.native,
        popGesture: true,
        initialRoute: '/',
        getPages: [
          GetPage(
            name: '/',
            page: () => Scaffold(
              body: TextButton(
                onPressed: () => Get.toNamed('/details', arguments: 'record-7'),
                child: const Text('Open record'),
              ),
            ),
          ),
          GetPage(
            name: '/details',
            page: () =>
                Scaffold(appBar: AppAppBar(title: Get.arguments as String)),
          ),
        ],
      ),
    );
    await tester.tap(find.text('Open record'));
    await tester.pumpAndSettle();
    expect(find.text('record-7'), findsOneWidget);
    await tester.dragFrom(const Offset(2, 250), const Offset(650, 0));
    await tester.pumpAndSettle();
    expect(find.text('record-7'), findsNothing);
    expect(find.text('Open record'), findsOneWidget);
  });

  testWidgets(
    'multi-step forms use the same toolbar and system step-back policy',
    (tester) async {
      var step = 1;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => StatefulBuilder(
                      builder: (context, update) => UnsavedChangesGuard(
                        onBackWithinPage: step == 1
                            ? () => update(() => step = 0)
                            : null,
                        child: Scaffold(appBar: AppAppBar(title: 'Step $step')),
                      ),
                    ),
                  ),
                ),
                child: const Text('Begin'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Begin'));
      await tester.pumpAndSettle();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.text('Step 0'), findsOneWidget);
      await tester.tap(find.byType(AppBackButton));
      await tester.pumpAndSettle();
      expect(find.text('Begin'), findsOneWidget);
    },
  );

  Future<void> openForm(
    WidgetTester tester, {
    TargetPlatform platform = TargetPlatform.android,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(platform: platform),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                platform == TargetPlatform.iOS
                    ? CupertinoPageRoute<void>(builder: (_) => const _Form())
                    : MaterialPageRoute<void>(builder: (_) => const _Form()),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  testWidgets('detail toolbar pops the actual route', (tester) async {
    await openForm(tester);
    await tester.tap(find.byType(AppBackButton));
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Discard changes?'), findsNothing);
  });

  testWidgets('dirty form toolbar keeps editing or confirms discard', (
    tester,
  ) async {
    await openForm(tester);
    await tester.enterText(find.byType(TextField), 'changed');
    await tester.pump();
    await tester.tap(find.byType(AppBackButton));
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Keep Editing'));
    await tester.pumpAndSettle();
    expect(find.text('changed'), findsOneWidget);
    await tester.tap(find.byType(AppBackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('Android system back follows the discard policy', (tester) async {
    await openForm(tester);
    await tester.enterText(find.byType(TextField), 'changed');
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('reverting edits restores clean native pop capability', (
    tester,
  ) async {
    await openForm(tester);
    await tester.enterText(find.byType(TextField), 'changed');
    await tester.enterText(find.byType(TextField), 'original');
    await tester.pump();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsNothing);
    expect(find.text('Open'), findsOneWidget);
  });

  testWidgets('iOS clean route supports interactive swipe back', (
    tester,
  ) async {
    await openForm(tester, platform: TargetPlatform.iOS);
    await tester.dragFrom(const Offset(2, 250), const Offset(650, 0));
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Edit Profile'), findsNothing);
  });

  testWidgets('iOS dirty swipe cannot discard edits; toolbar asks', (
    tester,
  ) async {
    await openForm(tester, platform: TargetPlatform.iOS);
    await tester.enterText(find.byType(TextField), 'changed');
    await tester.pump();
    await tester.dragFrom(const Offset(2, 250), const Offset(650, 0));
    await tester.pumpAndSettle();
    expect(find.text('Edit Profile'), findsOneWidget);
    await tester.tap(find.byType(AppBackButton));
    await tester.pumpAndSettle();
    expect(find.text('Discard changes?'), findsOneWidget);
  });
}

class _Form extends StatefulWidget {
  const _Form();
  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  final controller = TextEditingController(text: 'original');
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => UnsavedChangesGuard(
    controllers: [controller],
    child: Scaffold(
      appBar: const AppAppBar(title: 'Edit Profile'),
      body: TextField(controller: controller),
    ),
  );
}
