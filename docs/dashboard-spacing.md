# Investor Dashboard vertical spacing

Fixed only the Dashboard layout; existing cards, colors, fonts, Remix icons, data/calculations, API integration, authentication and navigation remain unchanged.

## Cause and changes

The portfolio-to-statistics gap combined header bottom padding, responsive body vertical padding, an extra SizedBox and GridView's inherited MediaQuery padding. Nested project/activity ListViews also inherited safe-area padding despite being inside the Dashboard's outer scroll view. Statistics used a fixed 114px row height, which reserved space and limited scaled-text responsiveness. Major sections additionally had 28px separators.

The Dashboard now uses horizontal-only body padding, explicit 20px portfolio-to-statistics spacing (16px header inset plus 4px body gap), content-driven metric rows via Wrap, 22px major section gaps, 14px heading-to-list gaps and 10px card separators. Nested lists explicitly use zero padding and are not primary scroll views; the outer Dashboard remains the scroll owner. No negative margins, transforms, screen-height positioning or card-style changes.

MyProjectCard (the card used here) has no bottom margin. The separate ProjectCard widget's margin was not involved and was not changed. SafeArea/status-bar handling and the navigation shell were preserved.

## Task files

Relative to `/Users/avinashsanjaymagar/Flutter Project/investpro/mobile-app`:

- `lib/app/views/home/home_view.dart`: Dashboard-only spacing, content-driven metric layout and explicit nested-list padding.
- `test/home_dashboard_redesign_test.dart`: measure rendered section/card gaps on Android/iOS, 320×568, 844×390 and 1024×1366, at 1.0 and 1.5 text scales; retains existing Dashboard content/empty-state/balance-toggle checks.
- `docs/dashboard-spacing.md`: this report.

## Verification

Passed:

```sh
flutter analyze
flutter test --reporter expanded test/home_dashboard_redesign_test.dart
flutter test --reporter expanded test/adaptive_navigation_test.dart test/remix_navigation_test.dart
```

Analysis: no issues. Dashboard: all 16 tests passed. Navigation: all 23 tests passed. Geometry assertions confirm 20/22/14/10px gaps, correct section order, status-bar clearance, and scrolling to the final activity without overflow. Existing Android/iOS navigation tests pass; bottom-navigation implementation/positioning was not modified. Read-only `git diff --check` passed.

No screenshots were present in this request; the written spacing requirements were used. Physical-device visual checks were not performed; responsive verification uses Flutter widget tests.

Prisma/schema unchanged; no migration needed/generated/applied. Backend, Admin applications, Docker, deployment, CI/CD and credentials untouched. No temporary debugging scripts or artifacts created. No Git write, automatic commit, push, merge or deployment. No blockers.

Manual review from the Investor Mobile directory: `git diff -- lib/app/views/home/home_view.dart test/home_dashboard_redesign_test.dart` and `git status --short`.
