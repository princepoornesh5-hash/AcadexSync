# ACADEX Bug Fix Engineering Report: Navigation, Search, Active States & Selection Errors

## 1. Executive Summary

This engineering report documents the diagnosis, root-cause analysis, architectural solutions, and verification for five critical navigation, search, and selection defects in ACADEX Web:
1. **Academic Structure Navigation**: Inconsistent interaction patterns where clicking structure items opened detached listing views rather than canonical detail routes (`/academics/departments/:id`, `/academics/courses/:id`, `/academics/semesters/:id`, `/academics/sections/:id`), with non-interactive overview KPI cards.
2. **HOD Sidebar Double-Selection Bug**: Navigating to `/academics/students` caused both "Students" and "Academics" sidebar items to appear simultaneously selected due to substring route prefix checking (`activeRoute.startsWith('/academics')`) and overly broad prefix configurations.
3. **Unwanted Directory Checkboxes**: The Students Directory table displayed a bulk-action checkbox column and a select-all header checkbox despite no bulk operations being supported in this view.
4. **Global Search Full-Screen Route & Permission-Denied Failure**: Pressing Enter on the global search input navigated to a detached full-screen view without the standard navigation shell. Searching for terms like `students` triggered Firestore `permission-denied` exceptions caused by un-scoped note queries violating security rules, accompanied by non-functional dummy routes (`/module/*`).
5. **Dashboard Quick-Operation Active Border & Selection Persistence**: Only "Department Timetable" had a primary blue border due to a hardcoded property. Other quick-operation cards lacked active state indicators, and returning from a destination did not preserve or reflect the active card.

All 5 defects have been fixed in the frontend codebase, validated with 27 automated regression tests (0 failures), and verified with `flutter analyze` (0 errors, 0 warnings).

---

## 2. Bug 1: Academic Structure Navigation Patterns

### Root Cause
- In `Frontend/lib/features/academic_structure/presentation/screens/academic_structure_home_screen.dart`, clicking a course, semester, or section invoked listing navigations or nested sub-screens (`/academics/courses`, `/academics/semesters`) rather than canonical detail routes.
- The overview KPI summary cards (`_buildSummaryTile`) rendered static informational tiles with no interaction or tab-switching logic, frustrating users who expected clicking "Courses (12)" to switch to the Courses tab.

### Architecture & Navigation Decisions
- **Canonical Detail Routing**: Standardized entity interactions on canonical detail paths matching `app_router.dart`:
  - Department card: `context.go('/academics/departments/${dept.id}')`
  - Course card: `context.go('/academics/courses/${course.id}')`
  - Semester card: `context.go('/academics/semesters/${sem.id}')`
  - Section card: `context.go('/academics/sections/${sec.id}')`
- **Predictable Interaction Rules**:
  - **Clicking an Entity Card**: Navigates directly to the canonical detail screen for that specific entity.
  - **Clicking "Edit" Action**: Opens the dedicated edit dialog or modal form in-place without disruptive route shifts.
  - **Clicking "Create / Add" Action**: Opens the standardized entity creation dialog.
  - **Clicking KPI Metric Tiles**: Switches the active tab controller to the corresponding category (`_tabController.animateTo(tabIndex)`) with immediate visual feedback.

### Files Changed
- `Frontend/lib/features/academic_structure/presentation/screens/academic_structure_home_screen.dart`:
  - Updated `_buildSummaryTile` to accept an `onTap` callback and wrapped the tile in `AcadexPressable` / `Material(InkWell)`.
  - Updated overview KPI tiles to switch tabs (`_tabController.animateTo(1)` for Departments, `2` for Courses, `3` for Semesters, `4` for Sections).
  - Updated card `onTap` handlers across all tabs to navigate to canonical `:id` detail routes.

---

## 3. Bug 2: Sidebar Active Navigation Item Selection (HOD & All Roles)

### Root Cause
- In `Frontend/lib/core/presentation/navigation/acadex_nav_item.dart`, `AcadexNavItem.matchesRoute(String currentRoute)` evaluated:
  ```dart
  if (route != '/' && currentRoute.startsWith(route)) return true;
  ```
- Because the Academics menu item was configured with route `/academics`, visiting `/academics/students` satisfied `startsWith('/academics')`. Furthermore, `matchingPrefixes` on `academics` included `/academics`, which matched any child path regardless of whether a more specific sibling route (like `students` at `/academics/students`) was available.
- In `Frontend/lib/features/dashboard/presentation/widgets/acadex_drawer.dart`, `acadex_nav_rail.dart`, and `acadex_bottom_nav.dart`, each navigation item evaluated `item.matchesRoute(activeRoute)` independently. When two items matched, both rendered with active background, bold typography, and blue accent borders.

### Architecture: Route Specificity Scoring & Canonical Ancestry
1. **URI Path Normalization**:
   - Strips query parameters (`?dept=cs`) and URI fragments (`#section-a`) prior to route evaluation.
2. **Explicit Matching & Boundary Checking**:
   - Prohibited naive string prefix matching. Sibling routes must either match exact route path or match an authorized prefix ending on path delimiter (`/`).
3. **Deterministic Ancestry Resolution (`resolveActiveItem`)**:
   - Introduced `AcadexNavigationService.resolveActiveItem(activeRoute, role, candidates:)` using route specificity scoring:
     - **Exact Match** (`candidate.route == cleanPath`): `2000 + pathSegments.length`
     - **Explicit Matching Prefix** (matching specific authorized sub-path): `1000 + prefix.length`
     - **Subroute Path Hierarchy** (nested detail under item route, provided no more specific item matches): `100 + candidate.route.length`
   - If multiple items match, the item with the highest specificity score is selected, guaranteeing **exactly one active navigation destination**.
4. **Scoped Matching Prefixes**:
   - `academics` prefixes restricted to academic submodules (`/academics/departments`, `/academics/courses`, `/academics/semesters`, `/academics/sections`, `/academics/batches`, `/academics/regulations`), strictly excluding `/academics/students`.
   - `people` prefixes scoped strictly to `/users`.
5. **Universal Application**:
   - Integrated across Drawer, Navigation Rail, and Bottom Navigation bar for College Admin, HOD, Faculty, Student, and Super Admin roles.

### Files Changed
- `Frontend/lib/core/presentation/navigation/acadex_nav_item.dart`:
  - Refactored `matchesRoute` and `matchingPrefixes`.
  - Added `AcadexNavigationService.resolveActiveItem`.
- `Frontend/lib/features/dashboard/presentation/widgets/acadex_drawer.dart`:
  - Updated selection check to `final activeItem = AcadexNavigationService.resolveActiveItem(...)` and `isSelected: activeItem?.id == item.id`.
- `Frontend/lib/features/dashboard/presentation/widgets/acadex_nav_rail.dart`:
  - Updated active item resolution using `resolveActiveItem`.
- `Frontend/lib/features/dashboard/presentation/widgets/acadex_bottom_nav.dart`:
  - Updated active item resolution using `resolveActiveItem`.

---

## 4. Bug 3: Elimination of Unwanted Directory Checkboxes

### Root Cause
- In `Frontend/lib/features/academic_structure/presentation/screens/student_screens.dart`, `_buildDesktopTable` initialized `AcadexDataTable` without `showCheckboxColumn: false` and passed an `onSelectChanged: (selected) {}` callback to `DataRow`.
- This caused Flutter's `DataTable` to generate a checkbox column on every row as well as a select-all checkbox in the table header, misleading users into expecting bulk operations (export, delete, promote) that were not implemented in this view.

### Design Decision & Audit
- **Read-Only Directory View**: The Students Directory in this screen is a search-and-inspect catalog. Clicking a student navigates to their profile or opens their details dialog.
- **Preservation of Legitimate Checkboxes**:
  - Preserved bulk column selection in `Frontend/lib/features/academic_structure/presentation/widgets/import_data_dialog.dart` (required for CSV field mapping).
  - Preserved student selection checkboxes in `Frontend/lib/features/academic_structure/presentation/widgets/student_promotion_stepper_dialog.dart` (required to select candidates for batch promotion).
  - Preserved form checkboxes for boolean preferences and permissions.

### Files Changed
- `Frontend/lib/features/academic_structure/presentation/screens/student_screens.dart`:
  - Added `showCheckboxColumn: false` to `AcadexDataTable`.
  - Removed `onSelectChanged` callback from `DataRow`.

---

## 5. Bug 4: Global Search Inappropriate Route & Permission-Denied Error

### Root Cause
1. **Detached Full-Screen Route**:
   - In `Frontend/lib/app/router/app_router.dart`, the `/search` route was placed directly at the top level without being wrapped in `ShellWrapper`. When submitted, users were dumped into a naked scaffold missing the sidebar, header, and role context.
2. **Firestore `permission-denied` Violation**:
   - In `Frontend/lib/features/search/data/repositories/firebase_search_repository.dart`, searching queries the `notes` collection. According to `firestore.rules`:
     ```javascript
     match /notes/{noteId} {
       allow read: if isSuperAdmin() || isCollegeAdmin() ||
         (isHOD() && resource.data.departmentId == currentUser().departmentId) ||
         ((isFaculty() || isStudent()) && resource.data.status == 'published');
     }
     ```
   - When an HOD searched for `students`, the notes collection was queried without a `where('departmentId', isEqualTo: currentUser.departmentId)` filter clause, violating Firestore rules and causing the query to fail with `permission-denied`.
   - Similarly, student and faculty queries lacked the `where('status', isEqualTo: 'published')` filter.
   - Students querying `users` directly also failed security rules since students are not permitted to list arbitrary user profiles.
3. **Non-Functional Dummy Navigation Routes**:
   - Search results for modules directed users to dummy routes like `/module/students` or `/module/departments`, which resolved to 404/not-found.

### Architecture & Security Decisions
1. **Responsive Shell Preservation**:
   - Wrapped `/search` in `ShellWrapper` in `app_router.dart`. Global search remains embedded within the standard navigation layout.
2. **Navigation Destination Searching**:
   - Added `SearchResultType.navigation` to search domain models.
   - Integrated `AcadexNavigationService.searchNavigationDestinations(query, role)` into search repositories. Queries like `students` or `timetable` immediately surface the authorized destination (`/academics/students` or `/timetable`) as a top-ranked navigation result with a distinct "Navigation" tag.
3. **Strict Role & Tenant-Scoped Backend Queries**:
   - Scoped notes query in `FirebaseSearchRepository`:
     - **Super Admin / College Admin**: Scoped by `tenantId`.
     - **HOD**: Scoped by `tenantId` AND `departmentId: currentUser.departmentId`.
     - **Faculty / Student**: Scoped by `tenantId` AND `status: 'published'`.
   - Prevented students from querying the restricted `users` collection.
   - Replaced all `/module/*` URLs with canonical, working application routes.
4. **Resilient Error & Exception Handling**:
   - Wrapped individual entity searches in try-catch handlers so if one collection is restricted or empty, authorized results (such as navigation destinations and course records) still render cleanly rather than failing the entire screen.

### Files Changed
- `Frontend/lib/app/router/app_router.dart`:
  - Wrapped `/search` in `ShellWrapper`.
- `Frontend/lib/features/search/domain/models/search_models.dart`:
  - Added `SearchResultType.navigation`.
- `Frontend/lib/features/search/presentation/widgets/search_result_card.dart`:
  - Added navigation result icon (`LucideIcons.compass`) and "Navigation" badge.
- `Frontend/lib/core/presentation/navigation/acadex_nav_item.dart`:
  - Added `searchNavigationDestinations` filtering by role permissions.
- `Frontend/lib/features/search/data/repositories/mock_search_repository.dart`:
  - Added navigation destination results and updated destination routes.
- `Frontend/lib/features/search/data/repositories/firebase_search_repository.dart`:
  - Added navigation destination results, enforced role/tenant query scoping for notes and users, and replaced dummy URLs.
- `Frontend/lib/features/search/presentation/screens/global_search_screen.dart`:
  - Supported initial query parameter, added Modules filter chip, and improved error/retry handling.

---

## 6. Bug 5: Dashboard Action Active Styling & Selection Persistence

### Root Cause
- In `Frontend/lib/features/dashboard/presentation/widgets/home_dashboard_widgets.dart`, the Department Timetable card had a prominent blue border solely because of a hardcoded parameter `isPrimary: true`.
- Other quick operation cards were plain `AcadexCard` elements with static borders. Clicking a card triggered navigation, but the card did not retain any active or selected state upon return.
- No global or shared state tracked the active dashboard action across URL transitions or browser history navigation.

### Architecture: State-Driven Action Selection & Micro-Interactions
1. **Navigation Provider State Tracking**:
   - Added `lastSelectedActionRoute` (String?) and `lastSelectedActionId` (String?) to `GlobalNavigationState`.
   - Added `selectDashboardAction({required String route, String? id})` to `NavigationNotifier`.
   - In `updateRoute(route)`:
     - When navigating to non-dashboard destinations (e.g. `/timetable`), `lastSelectedActionRoute` is automatically updated to the current route.
     - When navigating to unrelated sections, stale `lastSelectedActionId` is cleared using an explicit `clearActionId: true` guard to prevent Dart null-coalescing retention.
2. **Deterministic Selection Predicate**:
   - Added `DashboardActionSelectionX.isActionActive(targetRoute, targetId)` extension. An action is considered selected if:
     - Its specific `actionId` matches `lastSelectedActionId`, OR
     - Its `targetRoute` matches `lastSelectedActionRoute` or `currentRoute`.
3. **Dedicated `DashboardActionCard` Component**:
   - Supports 4 visually distinct states:
     - **Resting**: Clean neutral border (`AcadexColors.border`).
     - **Hover**: Subtle lift with elevated border (`AcadexColors.inkMuted`).
     - **Keyboard Focus**: Focus ring indicator (`AcadexColors.primary`).
     - **Selected / Active**: High-contrast primary border (`AcadexColors.primary` at 1.8px width), primary tinted background (`primary.withValues(alpha: 0.08)`), and bolded label.
4. **Universal Integration**:
   - Replaced ad-hoc action tiles in `HODDashboard` and `CollegeAdminDashboard` with `DashboardActionCard` utilizing `isActionActive(...)`.

### Files Changed
- `Frontend/lib/core/presentation/providers/navigation_provider.dart`:
  - Added action selection properties and methods to `GlobalNavigationState` and `NavigationNotifier`.
- `Frontend/lib/features/dashboard/presentation/widgets/home_dashboard_widgets.dart`:
  - Created `DashboardActionCard`.
  - Updated `DashboardQuickActionsGrid` to consume `navigationProvider`.
  - Added `FittedBox` and compact padding in `DashboardCompactTile` to eliminate RenderFlex overflows under narrow widths and 1.5x font scale.
- `Frontend/lib/features/dashboard/presentation/screens/hod_dashboard.dart`:
  - Integrated `DashboardActionCard` with dynamic `isActionActive` matching.
- `Frontend/lib/features/dashboard/presentation/screens/college_admin_dashboard.dart`:
  - Integrated `DashboardActionCard` with dynamic `isActionActive` matching.

---

## 7. Automated Test Verification & Results

### Automated Regression Tests
A comprehensive test suite was created in `Frontend/test/navigation_search_selection_test.dart` covering all 5 bug areas:
1. **Bug 1: Academic Structure Navigation Patterns**
   - Verified academic detail route URLs match canonical `/academics/departments/:id`, `/academics/courses/:id`, `/academics/semesters/:id`, `/academics/sections/:id`.
2. **Bug 2: Sidebar Active Navigation Item Selection (HOD & All Roles)**
   - Verified navigating to `/academics/students` activates **only** Students, not Academics or People.
   - Verified navigating to `/academics` activates **only** Academics, not Students.
   - Verified direct URL entry with query parameters (`/academics/students?batch=2024`) resolves correctly.
   - Verified single-selection behavior across College Admin, Faculty, Student, and Super Admin roles.
3. **Bug 3: Students Directory Table Checkbox Removal**
   - Verified `AcadexDataTable` renders with `showCheckboxColumn: false` and no `Checkbox` widgets present in the table.
4. **Bug 4: Global Search Navigation Destinations & Scoped Queries**
   - Verified querying `students` returns navigation destination with route `/academics/students` and `SearchResultType.navigation`.
   - Verified search destination URLs point to canonical paths instead of dummy `/module/*`.
5. **Bug 5: Dashboard Action Selection State & Persistence**
   - Verified `DashboardActionCard` renders distinct active styling when selected vs unselected.
   - Verified `NavigationNotifier` updates `lastSelectedActionRoute` on navigation and preserves active selection state upon return.

### Test Execution Summary
Executed commands:
```bash
flutter test test/navigation_search_selection_test.dart test/search_workflow_test.dart test/admin_hod_dashboard_redesign_test.dart
```
**Results**:
- `test/navigation_search_selection_test.dart`: 12/12 passed.
- `test/search_workflow_test.dart`: 4/4 passed.
- `test/admin_hod_dashboard_redesign_test.dart`: 11/11 passed (including 320px narrow viewport and 1.5x font scale).
- **Total: 27/27 tests passed (0 failures).**

### Static Code Analysis
Executed command:
```bash
flutter analyze
```
**Result**:
- `No issues found! (ran in 6.2s)`

---

## 8. Manual Verification & User Testing Checklist

To verify the changes interactively in the running web application (`http://localhost:port`):

1. **Academic Structure Navigation**:
   - Log in as HOD or College Admin.
   - Navigate to `/academics`.
   - Click on the "Courses" summary KPI tile in the overview tab $\rightarrow$ verify it smoothly animates to the Courses tab.
   - Click any Course card in the list $\rightarrow$ verify it navigates to `/academics/courses/:id` showing the canonical detail view.
   - Click "Add Course" $\rightarrow$ verify the modal creation dialog opens without leaving the screen.

2. **HOD Sidebar Active Selection**:
   - In the HOD dashboard, click "Students" in the sidebar $\rightarrow$ verify **only** "Students" has the active blue indicator; "Academics" must remain unselected.
   - Refresh the browser on `/academics/students` $\rightarrow$ verify only "Students" remains active.
   - Use browser Back to return to `/academics` $\rightarrow$ verify "Academics" becomes active and "Students" is unselected.
   - Repeat for College Admin, Faculty, and Student accounts.

3. **Students Directory Table**:
   - Navigate to `/academics/students`.
   - Inspect the desktop data table $\rightarrow$ verify there are no row checkboxes and no header select-all checkbox.
   - Open the "Import CSV" dialog $\rightarrow$ verify legitimate field mapping checkboxes remain functional.

4. **Global Search**:
   - In the top bar search input, type `students` and press `Enter`.
   - Verify the search screen opens inside the standard shell layout (sidebar and header visible).
   - Verify the top result is "Students Directory" tagged with "Navigation".
   - Click the result $\rightarrow$ verify it navigates directly to `/academics/students`.
   - Verify no Firestore `permission-denied` errors appear in the console or UI.

5. **Dashboard Quick-Operation Active Border**:
   - On the HOD dashboard, click "Department Timetable" $\rightarrow$ notice it navigates to `/timetable`.
   - Click the browser Back button to return to the HOD dashboard $\rightarrow$ verify "Department Timetable" retains the active blue border.
   - Click "Student Directory" $\rightarrow$ return to dashboard $\rightarrow$ verify "Student Directory" now has the active blue border and "Department Timetable" has reverted to normal resting border.
