# Investor Mobile synchronization banner and API resilience

## Root causes found

The red message was built by `AccountSync` in `lib/app/widgets/account_sync.dart`. Its `_error` field was set whenever the application-level refresh callback threw. `lib/main.dart` wraps every route in this widget, so an account-data failure appeared above Home, Projects, Investments, Returns, Profile and other routes as an error-colored ListTile/SafeArea. The wrapper's Column/Expanded layout also inserted the banner's height.

Background polling started immediately and repeated every 15 seconds. The callback fetched the complete account snapshot, then Projects/categories and notifications sequentially. A snapshot failure prevented the later refreshes from running; screen/controller initial loads could overlap with another global startup refresh. Projects unconditionally cleared valid cards when refresh failed. Authentication refresh cleared credentials for all exceptions, including transient connectivity/server failures. Concurrent stale 401 responses could also refresh again after another request had already rotated the token. Retry-After was not respected.

No production network trace was supplied or generated. These source defects are verified; a particular production HTTP status or failed endpoint cannot be inferred from the old generic banner. No backend defect was verified, so backend code was not changed.

## Implemented behavior

- AccountSync renders its child directly: no error banner, replacement global alert, hidden height, Column or Expanded around the route.
- Polling remains enabled for authenticated foreground accounts. The application delays the first global poll because controllers/login already perform initial loading. Normal interval is 60 seconds; failures back off to 120/240/300 seconds. Only one refresh runs at once. Logout/background/dispose cancels scheduling; resume refreshes without overlapping in-flight work.
- The application refreshes repository, Projects and notifications independently via Future.wait; one source failure no longer prevents the other refresh functions from starting. Projects background refresh skips existing loading work. Projects mounting does not duplicate an already-attempted initial controller request.
- Dio records HTTP 429 Retry-After (delta seconds or HTTP date, 60-second fallback). A conservative shared read cooldown prevents additional GET requests from reaching the transport until that deadline; polling also honors it. No automatic 429 retry loop, backend limit change, or authentication bypass.
- Token refresh remains single-flight. Late stale 401s replay using an already-rotated token. Temporary network/429/5xx refresh failures retain credentials and propagate the real failure. Definitive refresh rejection clears credentials and invokes a once-only session-expiry callback, clears account/project caches and returns to login when navigation is available. Remembered refresh-only sessions can restore through existing server authentication.
- Projects keeps valid cards during failed background or pull refresh, with no full-screen replacement while data is available. Initial/no-matching-data failures retain the section-local Retry UI. Successful empty results still clear stale records. Pagination state is preserved after refresh failure.
- Project detail cache survives transient background errors, but authoritative 401/403/404 or an unavailable response removes it. Request generations prevent old details from reappearing after session changes. Lists also invalidate authoritative denied/missing responses.
- Repository snapshots parse all collections before committing cached state. A failed request or malformed record cannot partially replace valid account balances/profile/lists. Session-generation checks keep stale data/errors from returning after logout. Home gets a contextual retry message only when no account data exists; cached Home content is not interrupted.
- Debug-only diagnostics record sanitized method, endpoint, status and bounded message. Query values, headers, tokens, long identifiers and email values are not logged. Existing legitimate form, KYC, transaction and payment error handling remains.

Financial calculations, API paths/contracts, published project eligibility, backend authorization/rate limits, theme, fonts, icons, search, filters, navigation and bottom navigation were preserved. No GetX Bindings or dependencies added.

## Endpoints inspected and diagnostics verified

Account snapshot: `/mobile/account-status`, `/mobile/profile`, `/mobile/dashboard`, `/mobile/projects`, `/mobile/investments`, `/mobile/withdrawals`, `/mobile/transactions`, `/mobile/returns`. Project sections also use `/mobile/project-categories` and `/mobile/projects/:id`. Authentication uses existing `/auth/refresh`; notification routes remain unchanged.

Observed local test diagnostics, **not production incident logs**:

- GET `/mobile/account-status`: 401, `Expired`; five concurrent requests recovered with one shared refresh.
- POST `/auth/refresh`: connectionError; tokens retained.
- POST `/auth/refresh`: 401, `Session rejected`; one expiry notification, no refresh loop.
- GET `/mobile/projects`: 429, `Too many requests`; Retry-After 120 seconds, repeated read did not reach the transport or extend the deadline.
- GET `/mobile/returns`: 500, `Server unavailable`; prior coherent snapshot retained.
- Project details: simulated 503 retained cached detail; simulated 404 invalidated it.

The application now captures the affected endpoint when a real synchronization failure occurs rather than turning every source into the same global banner. Physical-device/live-server behavior has not been claimed verified.

## Exact task files

Paths relative to `/Users/avinashsanjaymagar/Flutter Project/investpro/mobile-app`:

- `lib/app/widgets/account_sync.dart`: remove banner layout; one-shot silent polling, lifecycle and backoff.
- `lib/main.dart`: delayed initial poll, Retry-After deadline, independent refresh calls.
- `lib/app/services/api_diagnostics.dart`: safe diagnostics and Retry-After parsing.
- `lib/app/services/api_service.dart`: read cooldown, shared refresh resilience and meaningful propagation of project detail failures.
- `lib/app/services/demo_repository.dart`: preserve coherent snapshots and fence stale session results.
- `lib/app/controllers/auth_controller.dart`: session-expiry handling and account-scoped project cache invalidation.
- `lib/app/controllers/project_controller.dart`: safe cached refresh/detail handling and duplicate-load guards.
- `lib/app/views/projects/projects_view.dart`: preserve cards, contextual initial error and avoid duplicate mount loading.
- `lib/app/views/projects/project_details_view.dart`: display retained detail during transient background failure.
- `lib/app/views/home/home_view.dart`: contextual retry only for initial account-data failure.
- `test/account_sync_test.dart`: silent/full-size wrapper, lifecycle, backoff, cooldown and overlap regressions.
- `test/sync_api_resilience_test.dart`: refresh concurrency, transient/definitive failures, 429 cooldown and HTTP-date parsing.
- `test/sync_snapshot_retention_test.dart`: cached values, successful empty responses, malformed snapshot and late-session safety.
- `test/project_category_test.dart`: update old cache-clearing expectation to the requested cache-retention behavior.
- `test/projects_redesign_test.dart`: retained cards, denied/missing detail invalidation and no duplicate initial page request.
- `docs/synchronization-resilience.md`: this report.

## Verification and preservation

Passed final checks:

```sh
flutter analyze
flutter test --reporter compact
```

Analysis: no issues. Full Flutter suite: all 191 tests passed. Project layout tests include Android/iOS, compact phone, portrait/landscape/tablet and large text. Silent wrapper test verifies the child retains its complete viewport size without a ListTile/banner. Existing tests continue to cover pull-to-refresh, filters, routes, forms and payment behavior. Read-only `git diff --check` passed.

Earlier failures were corrected: the old category test expected clearing cards, timer tests exposed immediate refresh scheduling, and a new test needed its Dio Response import disambiguated from GetX. A concurrently-created unrelated scratch test briefly produced full-analysis infos; it was not edited/deleted by this task and was absent for the final clean run.

No live account/API/financial mutations, physical-device checks, production log capture or provider calls were performed. Tests use controlled adapters and fixture data only; no application data was replaced with fixtures.

Backend, Prisma schema and migrations unchanged; no migration generated/applied. Admin Mobile/Web, Docker, deployment, CI/CD, environment files and secrets were not modified. No Git write commands, automatic commit, push, merge or deployment. Concurrent unrelated workspace changes were retained. No task debugging scripts remain; full final test output is `/tmp/investpro-sync-final-result.log`. No approval blockers.

Suggested manual review from the Investor Mobile directory:

```sh
git status --short
git diff --check
git diff --stat
```
