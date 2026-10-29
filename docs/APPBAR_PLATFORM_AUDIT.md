# Platform AppBar audit

Scope: this Flutter application only. Backend, Prisma and Next.js were not changed. Audited 29 October 2026.

Before this task the existing AppAppBar forced centered titles and an iOS chevron on all platforms. Its back fallback could target the root navigator after a local navigator declined a pop. Theme controllers existed but both application roots forced light mode. Most investor views already delegated through CustomAppBar; named pushes explicitly used rightToLeft transitions. Password recovery had different toolbar/system step-back behavior.

## Screen-by-screen result

| Screen/file | Header implementation | Navigation policy |
| --- | --- | --- |
| `lib/app/views/auth/forgot_password_view.dart` (ForgotPasswordView) | AppAppBar | Adaptive back; safe no-op when route has no predecessor; discard guard |
| `lib/app/views/auth/login_view.dart` (LoginView) | Preserved custom header / shell | Initial login: no AppBar/back |
| `lib/app/views/auth/register_view.dart` (RegisterView) | AppAppBar | Adaptive back; safe no-op when route has no predecessor; discard guard |
| `lib/app/views/home/home_view.dart` (HomeView) | Preserved custom header / shell | Root greeting header; no back; branded overlay contrast |
| `lib/app/views/home/main_navigation_shell.dart` (main_navigation_shell) | Preserved custom header / shell | Preserved tab state; system back returns to first tab |
| `lib/app/views/investments/invest_now_view.dart` (InvestNowView) | CustomAppBar → AppAppBar | Adaptive back; safe no-op when route has no predecessor; discard guard |
| `lib/app/views/investments/investment_details_view.dart` (InvestmentDetailsView) | CustomAppBar → AppAppBar | Adaptive back; safe no-op when route has no predecessor |
| `lib/app/views/investments/investment_success_view.dart` (InvestmentSuccessView) | Preserved custom header / shell | Preserved completion route and home redirect; no AppBar |
| `lib/app/views/investments/my_investments_view.dart` (MyInvestmentsView) | CustomAppBar → AppAppBar | No back in tabs; adaptive back on pushed route |
| `lib/app/views/investments/payment_confirmation_view.dart` (PaymentConfirmationView) | CustomAppBar → AppAppBar | Adaptive back; safe no-op when route has no predecessor; discard guard |
| `lib/app/views/notifications/notifications_view.dart` (NotificationsView) | CustomAppBar → AppAppBar | Adaptive back; safe no-op when route has no predecessor |
| `lib/app/views/profile/edit_profile_view.dart` (EditProfileView) | CustomAppBar → AppAppBar | Adaptive back; safe no-op when route has no predecessor; discard guard |
| `lib/app/views/profile/profile_view.dart` (ProfileView) | CustomAppBar → AppAppBar | No back in tabs; adaptive back on pushed route |
| `lib/app/views/projects/project_details_view.dart` (ProjectDetailsView) | CustomAppBar → AppAppBar | Adaptive back; safe no-op when route has no predecessor |
| `lib/app/views/projects/projects_view.dart` (ProjectsView) | CustomAppBar → AppAppBar | No back in tabs; adaptive back on pushed route |
| `lib/app/views/returns/returns_view.dart` (ReturnsView) | CustomAppBar → AppAppBar | No back in tabs; adaptive back on pushed route |
| `lib/app/views/settings/settings_view.dart` (SettingsView) | CustomAppBar → AppAppBar | Adaptive back; safe no-op when route has no predecessor |
| `lib/app/views/splash/splash_view.dart` (SplashView) | Preserved custom header / shell | No AppBar/back; branded overlay contrast |
| `lib/app/views/transactions/transaction_history_view.dart` (TransactionHistoryView) | CustomAppBar → AppAppBar | Adaptive back; safe no-op when route has no predecessor |
| `lib/app/views/withdrawals/withdrawal_view.dart` (WithdrawalView) | CustomAppBar → AppAppBar | Adaptive back; safe no-op when route has no predecessor; discard guard |

Existing search, notification, refresh, export, compose and add actions are preserved. No nonexistent detail screens were added. Error/fallback AppBars use the same title as the corresponding loaded screen. Admin detail titles were normalized to Investment Details and Investor Details; add screens use Add Project/Add Investor. Existing translated investor labels remain translated. Registration and password recovery retain the designed in-content headings without adding a duplicate toolbar title.

## Limits

Dirty iOS forms intentionally disable interactive swipe-back because PopScope cannot show a confirmation from a gesture that Cupertino suppresses when canPop is false. The visible back control asks for discard confirmation. Clean routes support interactive swipe-back. Generic deep-link routes without a predecessor keep the screen instead of fabricating a fallback route. Existing authentication guards and API logic remain unchanged; this is not a new authorization system.
