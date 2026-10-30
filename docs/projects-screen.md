# Investor Projects screen

The Projects catalog uses the existing light AppTheme, AppColors, Poppins typography, card shape, borders and button themes. No theme tokens, fonts, colors or gradients were added or changed. The request referred to a new reference image, but no image was supplied with this task; the implementation follows its written layout requirements.

## Presentation

- Existing adaptive AppBar and root-tab behavior: a pushed page can show the platform back control, while the bottom-navigation tab does not force one.
- Subtitle, rounded search field with clear action, filter-sheet shortcut, and horizontally scrollable status/category chips.
- Catalog-only expanded cards display the actual project/category icon, optional backend banner image, title, status and location, ROI, tenure, minimum investment, target funding and optional backend investor count. Failed banner images fall back to the icon already present on the card.
- Funding bars and raised amounts require finite, non-negative backend funding values and a positive target. Percentages derive from fundedAmount/targetAmount and clamp to 100%. Missing investor counts and funding data are omitted. Missing category counts are omitted; no default zero counts are invented.
- Metrics wrap into columns, action buttons stack at narrow widths or larger text scales, and the catalog width is constrained on tablets. Dashboard ProjectCard remains unchanged.

## Data and actions

Search is debounced for 350 ms and calls the existing `/mobile/projects` endpoint, which searches title and location (and other backend-supported fields). Responses are not re-filtered in a way that could remove valid server search matches. Category requests use backend IDs, with names loaded from `/mobile/project-categories`; real names such as abc and test are never replaced by a frontend list.

Initial loading, refresh, API failure/retry, empty results and incremental server paging are supported. Load more requests the next page (12 records per page), preserves existing cards if that request fails, and offers retry. Request generations discard stale responses after a new category or search. The existing exhaustive getEligibleProjects helper still gathers all pages for existing callers.

The current backend deliberately publishes only ACTIVE projects with active categories to investors. Status chips include All Projects, Active, Upcoming, Completed and the additional API statuses Funded, Cancelled and Draft; they filter only actual returned records. No hidden project is fetched through an admin endpoint. Non-active filters may therefore be empty. The backend visibility contract is unchanged.

View Details passes the actual project ID to the existing details route. Invest Now requires a signed-in investor, active account, VERIFIED KYC, active project, known funding room and valid minimum/maximum limits. A fresh detail lookup revalidates project visibility before selecting the server record and opening the existing investment route. Existing payment, token storage, authentication, terms and backend transaction checks remain unchanged. The button is disabled during payment processing. No mock data was added to application code.

## Changed files

- `lib/app/views/projects/projects_view.dart`: Projects screen layout, search/filter controls, paged list, refresh/retry and existing-route actions.
- `lib/app/widgets/project_listing_card.dart`: catalog-specific expanded card; existing dashboard card is untouched.
- `lib/app/controllers/project_controller.dart`: debounce, request isolation, paged state, accurate category labels and investment entry checks.
- `lib/app/models/project_model.dart`: preserve optional location/banner/investor fields, investment limits and funding availability through serialization.
- `lib/app/services/api_service.dart`: paged access to the existing mobile projects endpoint, with the exhaustive helper preserved.
- `test/project_category_test.dart`: adapt existing category API fixture to the paged method.
- `test/projects_redesign_test.dart`: transport/controller/widget regression coverage.
- `docs/projects-screen.md`: this feature and verification report.

No Prisma schema changes or migrations were needed or generated. Backend, Admin, Docker, infrastructure and CI/CD files were not modified by this task. No temporary artifacts, commits, pushes, merges or deployments were created. Unrelated Profile changes present in the shared checkout were left untouched. Manual review from `mobile-app`: `git diff --check`, `git diff -- lib/app/views/projects/projects_view.dart lib/app/controllers/project_controller.dart lib/app/models/project_model.dart lib/app/services/api_service.dart`, and `git status --short`.

## Validation and limits

Widget tests simulate Android/iOS platform conventions, phone portrait/landscape, iPad size, safe areas and 200% text scaling. Tests also cover server page/query parameters, search debounce, category IDs/counts, all status mappings, pagination retry/deduplication, stale responses, eligibility, funding math, optional fields, actual details/investment navigation, search clear, filter controls and pull-to-refresh. Test fixtures do not replace production data.

Physical-device rendering, live-server data and real payments were not exercised. A reference-image comparison could not be performed because no reference image was provided.

### Actual command results

- `flutter pub get`: passed; dependencies resolved without package upgrades.
- `flutter analyze`: failed with one warning in unrelated `test/profile_view_test.dart` (`unused_local_variable`). No Projects diagnostics remained after the targeted fixes.
- `flutter test`: the full run finished with 109 passing tests and 5 failures, all in the concurrent `test/profile_view_test.dart`. The first Profile build failed because Material supplied both `shape` and `borderRadius`. Those unrelated files were not changed by this task.
- `flutter analyze lib/app/controllers/project_controller.dart lib/app/models/project_model.dart lib/app/services/api_service.dart lib/app/views/projects/projects_view.dart lib/app/widgets/project_listing_card.dart test/projects_redesign_test.dart test/project_category_test.dart`: final run passed with no issues.
- `flutter test test/projects_redesign_test.dart test/project_category_test.dart`: final run passed, 26 tests, including the final pagination/pull-to-refresh checks and optional ROI handling.
- Scoped `git diff --check` passed. `git diff --exit-code -- lib/app/theme lib/app/controllers/theme_controller.dart` passed, confirming theme and palette files are unchanged.

No work in this Projects scope requires user approval. The unrelated Profile failures prevent reporting a green whole-workspace test suite. Missing ROI/terms show Not available rather than fabricated numeric placeholders.
