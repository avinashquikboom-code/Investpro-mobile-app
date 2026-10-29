# Navigation and back-button validation

Executed 29 October 2026 in `mobile-app`.

| Command | Actual result |
| --- | --- |
| `flutter pub get` | Passed; existing dependency constraints retained. |
| `flutter analyze` | Passed, no issues in final run. |
| `flutter test` | Passed, 55 total tests. |
| `flutter test test/adaptive_navigation_test.dart` | Passed before the final full suite; the full suite includes all 19 final navigation tests. |
| `flutter run --no-resident -d emulator-5554` | Built debug APK, installed and launched on sdk gphone16k arm64, Android 17/API 37. Startup smoke test only. |
| `git diff --check` | Passed at completion. |

## Coverage

Permanent adaptive navigation tests exercise Android/iOS title alignment, platform overrides, Material/Cupertino icons, 48-pixel back targets, actions, nested drawer opening, root screens without back arrows, pushed route back, no-predecessor safety, theme/overlay contrast, long title/subtitle truncation, text scale 2.0 and widths 320/375/844/1024. Admin additionally checks narrow labeled-action collapse and callback preservation.

Back tests cover Keep Editing, Discard, Android system back via handlePopRoute, restoring original field values, multi-step system/toolbar consistency, clean iOS CupertinoPageRoute swipe-back, dirty iOS swipe prevention plus toolbar confirmation, and actual GetX Transition.native route arguments/swipe-back. Existing tests were preserved; obsolete all-platform chevron expectations were updated.

## Device and verification limits

Both apps built, installed and launched on the connected Android emulator. No full authenticated screen-by-screen emulator workflow, backend mutations, live financial submissions or physical-device test was performed. Widget tests use simulated platforms/sizes; they do not establish physical iPhone/notch behavior. `flutter devices` found no usable iOS device/simulator; the configured wireless iPhone was unavailable (Developer Mode/connectivity error -27). iOS gesture behavior was exercised in Flutter/GetX widget tests.

Builds emitted existing firebase_core/Kotlin Gradle plugin migration notices and Android SDK deprecation/startup notices. No package, Android build, deployment or infrastructure changes were made to address those unrelated warnings. Final Dart analysis is clean.

The same discard policy applies to toolbar and Android back. Flutter disables native iOS interactive pop when PopScope.canPop is false; dirty forms deliberately use toolbar confirmation, while clean forms retain swipe-back. Bottom-sheet drag/barrier dismissal is disabled for the investor withdrawal form to prevent bypassing confirmation.

Prisma and migrations unchanged; no migration was needed or applied. APIs/auth/business logic and unrelated page content were preserved. Protected files were not modified. Temporary authoring files were kept outside the repositories and cleaned up. No agent commit, push, merge, deployment or database reset occurred. No approval blocker remains for this navigation task; real iOS/device acceptance remains manual validation.
