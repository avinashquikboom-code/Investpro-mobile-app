# Adaptive AppBar implementation

## Shared API

AppAppBar remains the single navigation-bar implementation. Existing AdminAppBar/CustomAppBar wrappers delegate to it for compatibility.

Parameters: title, subtitle, titleWidget, leading, showBackButton, showMenuButton, onBackPressed, actions, centerTitle, automaticallyImplyLeading, backgroundColor, foregroundColor, elevation, scrolledUnderElevation, bottom, leadingWidth, toolbarHeight, titleTextStyle, systemOverlayStyle and platform. It implements PreferredSizeWidget; a subtitle adds 16 logical pixels, and bottom contributes its preferred height.

Theme.of(context).platform provides the target platform; platform is an optional test override. Android defaults to left alignment and Icons.arrow_back with Material feedback. iOS defaults to centered alignment and CupertinoIcons.back with CupertinoButton feedback. Explicit alignment/leading overrides remain possible. Text uses the theme navigation typography, one line and ellipsis. Back targets remain at least 48x48.

AppBackButton uses the current Navigator.maybePop and never falls through to an unrelated Get navigator. Root tabs explicitly suppress back; admin drawer controls find an ancestor that actually owns a drawer. The desktop sidebar layout is retained. Admin pushed settings/reports/transactions now show back instead of a nonfunctional menu. Small admin toolbar actions collapse to tooltip-labeled icons; wide layouts retain labels.

AppSystemUi centralizes fallback overlays for auth, custom headers and splash. AppAppBar supplies its own contrast-aware overlay; no per-screen SystemChrome mutations remain. Transparent system bars preserve edge-to-edge insets, with status and navigation icon brightness based on the actual surface/theme. Branded green home/splash/success headers request their surface through the shared component. No fake status bar or extra safe-area padding was added.

The application root now consumes the existing ThemeController/AdminThemeController with both AppTheme.lightTheme and darkTheme. System and manual theme modes are no longer forced to light. Unrelated screen body styling is preserved; this task does not restyle every existing content card.

GetMaterialApp uses Transition.native and popGesture for platform navigation; investor named rightToLeft routes now use Transition.native. Auth/splash/success fade transitions and route arguments/middleware remain intact. Existing GetX duplicate-route prevention remains in effect; the admin drawer additionally avoids pushing the active route and closes only an actually open drawer. Both shells preserve IndexedStack tab state and return to the first tab on system back before exiting. Existing offAllNamed login/logout history clearing is unchanged.

UnsavedChangesGuard uses PopScope, text controllers and optional selection streams/snapshots. Toolbar and system back request the same discard dialog; Keep Editing retains content and Discard pops only the current route. Restoring original values restores clean pop/swipe capability. Successful programmatic save completion retains the existing explicit pop. Form Cancel buttons use maybePop. Password recovery's onBackWithinPage hook preserves the OTP step-to-identity transition for both toolbar and system back. The investor withdrawal sheet disables barrier/drag dismissal and offers a guarded Cancel action.

## Files touched

- `lib/main.dart` — theme controller, native transition and system overlay integration.
- `lib/app/theme/app_theme.dart` — delegate title alignment to the platform; navigation surface colors.
- `lib/app/widgets/custom_app_bar.dart` — shared adaptive controls / overlay / discard policy.
- `lib/app/widgets/app_back_button.dart` — shared adaptive controls / overlay / discard policy.
- `lib/app/widgets/app_system_ui.dart` — shared adaptive controls / overlay / discard policy.
- `lib/app/widgets/app_app_bar.dart` — shared adaptive controls / overlay / discard policy.
- `lib/app/widgets/unsaved_changes_guard.dart` — shared adaptive controls / overlay / discard policy.
- `lib/app/views/home/home_view.dart` — adaptive navigation integration.
- `lib/app/views/splash/splash_view.dart` — adaptive navigation integration.
- `lib/app/views/auth/forgot_password_view.dart` — adaptive navigation integration.
- `lib/app/views/auth/register_view.dart` — adaptive navigation integration.
- `lib/app/views/profile/edit_profile_view.dart` — adaptive navigation integration.
- `lib/app/views/withdrawals/withdrawal_view.dart` — adaptive navigation integration.
- `lib/app/views/investments/payment_confirmation_view.dart` — adaptive navigation integration.
- `lib/app/views/investments/investment_success_view.dart` — adaptive navigation integration.
- `lib/app/views/investments/invest_now_view.dart` — adaptive navigation integration.
- `lib/app/routes/app_pages.dart` — native platform transitions; original arguments and guards preserved.
- `test/adaptive_navigation_test.dart` — permanent regression coverage / updated platform expectations.
- `test/widget_test.dart` — permanent regression coverage / updated platform expectations.

- `docs/APPBAR_PLATFORM_AUDIT.md` — complete screen inventory and findings.
- `docs/ADAPTIVE_APPBAR_IMPLEMENTATION.md` — API and file-by-file implementation record.
- `docs/NAVIGATION_BACK_BUTTON_TESTS.md` — executed checks and device-test limits.

Prisma schema and migrations: unchanged; no migration generated or applied. Backend/API/business logic/authentication: unchanged. Protected deployment, Docker and CI/CD files: untouched. No agent Git write, commit, push, merge or deployment was performed. Some source changes entered HEAD externally while this work was active; the file list records the task scope regardless of the current diff.

Temporary authoring scripts lived only in /private/tmp and are removed at completion. Build output is normal ignored Flutter output. To inspect manually, run `git diff --check`, `git diff --stat` and `git diff` from this repository. Stage/commit manually after review if desired.
