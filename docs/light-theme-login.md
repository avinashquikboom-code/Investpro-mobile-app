# Investor light theme and responsive login

The Investor app uses the requested green palette on white surfaces. ThemeController normalizes legacy dark/system preferences to light; AppTheme.darkTheme is a compatibility alias for lightTheme. Admin Mobile's actual AppTheme uses GoogleFonts.poppins; Investor already bundles Poppins regular, medium, semibold and bold, and retains that family. No Admin files or font dependencies changed.

Global component themes cover AppBars, forms, buttons, dialogs, bottom sheets, SnackBars and bottom navigation. Splash and investment confirmation backgrounds now use light surfaces with readable green text. Green brand artwork and dashboard accent panels remain.

Login uses Scaffold keyboard resizing, SafeArea and LayoutBuilder with a centered form constrained to 480 logical pixels. There is no scrolling container. Spacing responds to available height and the layout respects text scaling. Decorative branding disappears first as height decreases. When available height falls below 440 times the text scale, the form shows one field at a time: Next opens Password; the edit icon returns to Email/Mobile. Controllers retain both values. The focused password stays visible during keyboard transitions. More options exposes Remember Me, Forgot Password and Create New Account after dismissing the keyboard. The login action retains controller validation, real API integration, loading, error handling and session storage. The obsolete local-demo notice was removed.

## Physical limits

The compact form is tested at 320×568 with a 280-pixel keyboard and 200% text scaling. Arbitrarily small windows, very large accessibility fonts, or keyboards leaving less height than one accessible field and its actions cannot be guaranteed to fit. Dismiss the keyboard or enlarge/rotate the window in that situation; universal no-scroll support is not claimed. Physical iOS/Android keyboard, autofill and device-cutout behavior still require device QA. Widget tests simulate safe areas and keyboard insets, rather than running device emulators. Live-server credential rejection and successful token/session integration were not exercised in this UI task; their existing controller and service code is unchanged.

## Changed files

- `lib/app/theme/app_colors.dart`: requested palette and mint/secondary surface tokens.
- `lib/app/theme/app_theme.dart`: shared light component themes and compatibility alias.
- `lib/app/controllers/theme_controller.dart`: always activate/persist light mode.
- `lib/app/views/auth/login_view.dart`: responsive non-scroll form and compact keyboard flow, existing controller calls preserved.
- `lib/app/views/splash/splash_view.dart`: light background, text and status-bar contrast.
- `lib/app/views/investments/investment_success_view.dart`: light confirmation surface and readable text/actions.
- `test/login_layout_test.dart`: layout matrix, keyboard transitions, accessibility, visibility, options, loading and errors.
- `test/ledger_test.dart`: update the existing theme-persistence regression for light-only behavior.
- `docs/light-theme-login.md`: behavior, verification and limits.

No Prisma schema or migrations are involved. No backend, Admin, Docker, deployment or CI/CD files changed. No temporary files, commits, pushes, merges or deployments were created. Review manually from the Investor directory with `git diff --check`, `git diff`, and `git status --short`.

## Verification results

- `flutter pub get`: passed; dependencies resolved without upgrades.
- `flutter analyze`: passed, no issues found.
- `flutter test`: passed, 94 tests. The initial run exposed the old dark-mode expectation; that regression was updated to the requested light-only behavior.
- `flutter test test/login_layout_test.dart`: final run passed, 19 tests, including actual named-route callback navigation after strengthening that assertion.
- `git diff --check`: passed.

The size matrix covers 320×568, 375×667, 390×844, 430×932, 800×1280 and 1024×1366, with simulated keyboard closed/open. Additional checks cover 200% text, 200% text combined with keyboard, loading/disabled login, password visibility, Remember Me, field retention, long feedback, invalid input and unavailable API handling. Test doubles are confined to test fixtures. No blockers require approval.
