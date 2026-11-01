import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android 12 launch hides the app icon in light and dark mode', () {
    const res = 'android/app/src/main/res';
    for (final folder in ['values-v31', 'values-night-v31']) {
      final theme = File('$res/$folder/styles.xml').readAsStringSync();
      expect(theme, contains('name="android:windowSplashScreenAnimatedIcon">@drawable/launch_placeholder'));
      expect(theme, contains('name="android:windowSplashScreenBackground">#F8FAF5'));
      expect(theme, isNot(contains('@mipmap/ic_launcher')));
    }
    final icon = File('$res/drawable/launch_placeholder.xml').readAsStringSync();
    expect(icon, contains('android:fillColor="@android:color/transparent"'));
    expect(icon, isNot(contains('#C4ED93')));
  });
}
