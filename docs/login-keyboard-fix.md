# Investor Login keyboard fix

## Exact root cause reproduced

LoginView already used enabled, editable TextFormFields with State-owned TextEditingControllers and FocusNodes; the shared CustomTextField was not used by this screen. No app-wide text-input hiding or pointer-blocking overlay was found.

The defect was the keyboard-dependent compact layout. Opening the keyboard reduced LayoutBuilder height, switched the form into a one-field step layout, removed header/field siblings and rebuilt unkeyed Obx parents at different Column positions. This disposed/recreated the focused EditableText even though its FocusNode and TextEditingController still existed. The ValueKey on the nested TextFormField could not preserve state across replacement of its Obx parent. Both fields reproduced this on Android and iOS widget variants.

Temporary test diagnostics before the fix:

```text
identity focusAfterResize=true sameEditable=false showRequests=1
password focusAfterResize=true sameEditable=false showRequests=1
```

All four Android/iOS resize regression cases failed before the change. Afterward all reported `sameEditable=true`; focus and an attached text input client survived. Temporary diagnostic output was removed after verification; no credentials were logged.

A separate native emulator configuration problem was also confirmed: Android `show_ime_with_hard_keyboard` was 0 and native `mInputShown=false` with a served Flutter input view. Enabled the emulator's software keyboard (`show_ime_with_hard_keyboard=1`). This is an emulator preference, not application/native project configuration. No physical mobile device was connected.

## Fix

- Stable keys belong to each field's Obx parent as well as its existing TextFormField.
- Both inputs remain mounted; removed keyboard-triggered one-field/Next step switching.
- Existing centered login content, logo, labels, buttons, Remember Me, Forgot Password, Create New Account, footer, colors, fonts and Remix icons are retained on the normal screen. Small/keyboard-constrained layouts scroll the same form instead of replacing the fields. Existing responsive brand/footer visibility remains.
- SingleChildScrollView plus content-driven minimum viewport height keeps controls reachable; resizeToAvoidBottomInset stays enabled.
- Existing FocusNodes/controllers initialize once in State and dispose once. Email keyboard action moves to password; password uses visiblePassword input type and existing masking/visibility state.
- Gesture-based outside dismissal yields to field/button tap recognizers; actual field taps do not unfocus the form. Only explicit Login, outside tap, or drag dismissal hides input.
- Existing AuthController/API, validation, loading guard, credential handling and navigation are unchanged. No shared input widget, backend or database changes.

## Modified files

Relative to `/Users/avinashsanjaymagar/Flutter Project/investpro/mobile-app`:

- `lib/app/views/auth/login_view.dart`: stable editable state, keyboard-aware scrolling, two persistent fields and outside-tap handling.
- `test/login_keyboard_test.dart`: new Android/iOS tap/resize/client-state and typing/Next/eye/outside/failed-login regressions.
- `test/login_layout_test.dart`: adapt obsolete non-scroll/single-step expectations to the requested scrollable two-field behavior; retain small/large viewport, loading, validation and route checks.
- `test/login_input_keyboard_test.dart`: update expected password keyboard type from text to visiblePassword.
- `docs/login-keyboard-fix.md`: this report.

## Actual verification

- Before fix: four keyboard resize regressions failed because EditableText was recreated.
- After fix: all four pass with identical active EditableText, retained focus/client and TextInput.show request.
- Additional Android/iOS interaction tests pass: tap/type both inputs, Next, password masking, eye toggle without losing focus/state, return to email, outside dismissal, and reopening/typing after failed login.
- `flutter test --reporter compact`: all 215 tests passed after the password keyboard-type expectation was updated.
- `flutter analyze lib/app/views/auth/login_view.dart test/login_keyboard_test.dart test/login_layout_test.dart test/login_input_keyboard_test.dart`: no issues.
- Full `flutter analyze` ran and reported two unrelated `use_null_aware_elements` infos in `lib/app/widgets/animated_notification_bell.dart` (lines 206/217 at that time). Left outside this task; no login analysis issues.
- `flutter run -d emulator-5554 --debug --no-pub`: Android debug APK built/installed and app launched successfully. Native UI bounds were re-read before taps. Android input-method state confirmed:

```text
identity focused=true masked=false IME shown=true
password focused=true masked=true IME shown=true
```

- Test-only emulator input values were cleared without submitting an authentication request. Temporary host screenshots/UI dumps and device UI dump removed. Emulator software-keyboard setting remains enabled.
- Read-only `git diff --check` passed.

Physical Android/iPhone testing was unavailable: discovery showed an Android emulator, macOS and Chrome, with no physical Android or iPhone device. iOS verification is widget testing, not native/physical iOS. Successful authentication remains covered by existing mocked app regressions; no real credentials were used or real login attempted during the native keyboard check.

## Preservation

Prisma/schema unchanged; no migration generated/applied. No backend, Admin apps, Docker, CI/CD, deployment files or secrets modified. No automatic Git add/commit/push/merge/deployment. Concurrent unrelated workspace changes were retained. No task debug scripts remain; test output is `/tmp/investpro-login-keyboard-tests.log`. No approval blockers.

Manual review from Investor Mobile:

```sh
git diff -- lib/app/views/auth/login_view.dart test/login_keyboard_test.dart test/login_layout_test.dart test/login_input_keyboard_test.dart
git status --short
```
