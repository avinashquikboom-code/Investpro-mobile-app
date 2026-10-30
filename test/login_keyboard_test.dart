import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:investpro/app/constants/app_strings.dart';
import 'package:investpro/app/controllers/auth_controller.dart';
import 'package:investpro/app/services/demo_repository.dart';
import 'package:investpro/app/services/local_storage_service.dart';
import 'package:investpro/app/services/notification_service.dart';
import 'package:investpro/app/theme/app_theme.dart';
import 'package:investpro/app/views/auth/login_view.dart';

class KeyboardStore implements LocalStore {
  final data = <String, dynamic>{};
  @override
  dynamic read(String key) => data[key];
  @override
  Future<void> write(String key, dynamic value) async {
    data[key] = value;
  }
}

void main() {
  setUp(() {
    Get.testMode = true;
    GoogleFonts.config.allowRuntimeFetching = false;
    final storage = LocalStorageService(backend: KeyboardStore());
    Get.put<AuthController>(
      AuthController(
        storage,
        DemoRepository(storage, NotificationService(storage)),
      ),
    );
  });
  tearDown(() => Get.reset());
  Future<void> mount(WidgetTester tester, TargetPlatform platform) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(375, 667);
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 20);
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      GetMaterialApp(
        theme: AppTheme.lightTheme.copyWith(platform: platform),
        translations: AppTranslations(),
        locale: const Locale('en', 'US'),
        home: const LoginView(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder editable(String field) => find.descendant(
    of: find.byKey(ValueKey('login-$field')),
    matching: find.byType(EditableText),
  );
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    for (final field in ['identity', 'password']) {
      testWidgets(
        '$platform $field tap retains input connection through keyboard resize',
        (tester) async {
          await mount(tester, platform);
          await tester.tap(find.byKey(ValueKey('login-$field')));
          await tester.pump();
          final before = tester.state<EditableTextState>(editable(field));
          expect(before.widget.focusNode.hasFocus, true);
          expect(tester.testTextInput.isVisible, true);
          tester.view.viewInsets = const FakeViewPadding(bottom: 300);
          await tester.pumpAndSettle();
          final after = tester.state<EditableTextState>(editable(field));
          final shows = tester.testTextInput.log
              .where((call) => call.method == 'TextInput.show')
              .length;
          expect(shows, greaterThanOrEqualTo(1));
          expect(
            identical(before, after),
            true,
            reason: 'Keyboard resize must not replace the active EditableText',
          );
          expect(after.widget.focusNode.hasFocus, true);
          expect(tester.testTextInput.hasAnyClients, true);
        },
      );
    }
  }
  for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
    testWidgets(
      '$platform typing next eye outside and failed login keep input usable',
      (tester) async {
        await mount(tester, platform);
        await tester.tap(find.byKey(const ValueKey('login-identity')));
        await tester.pump();
        tester.testTextInput.enterText('investor@example.test');
        await tester.pump();
        await tester.testTextInput.receiveAction(TextInputAction.next);
        await tester.pump();
        expect(
          tester
              .state<EditableTextState>(editable('password'))
              .widget
              .focusNode
              .hasFocus,
          true,
        );
        tester.testTextInput.enterText('Password123');
        await tester.pump();
        final state = tester.state<EditableTextState>(editable('password'));
        expect(state.widget.obscureText, true);
        await tester.tap(find.byTooltip('Show or hide password'));
        await tester.pump();
        expect(
          tester.state<EditableTextState>(editable('password')),
          same(state),
        );
        expect(state.widget.focusNode.hasFocus, true);
        expect(state.widget.obscureText, false);
        expect(tester.testTextInput.isVisible, true);
        await tester.tap(find.byKey(const ValueKey('login-identity')));
        await tester.pump();
        expect(
          tester
              .state<EditableTextState>(editable('identity'))
              .widget
              .controller
              .text,
          'investor@example.test',
        );
        await tester.tapAt(const Offset(8, 40));
        await tester.pump();
        expect(
          tester
              .state<EditableTextState>(editable('identity'))
              .widget
              .focusNode
              .hasFocus,
          false,
        );
        await tester.tap(find.byKey(const ValueKey('login-password')));
        await tester.pump();
        expect(tester.testTextInput.isVisible, true);
        await tester.tap(find.byType(ElevatedButton));
        await tester.pumpAndSettle();
        expect(Get.find<AuthController>().isLoading.value, false);
        Get.closeAllSnackbars();
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('login-identity')));
        await tester.pump();
        expect(
          tester
              .state<EditableTextState>(editable('identity'))
              .widget
              .focusNode
              .hasFocus,
          true,
        );
        tester.testTextInput.enterText('updated@example.test');
        await tester.pump();
        expect(
          tester
              .state<EditableTextState>(editable('identity'))
              .widget
              .controller
              .text,
          'updated@example.test',
        );
        expect(tester.takeException(), isNull);
      },
    );
  }
}
