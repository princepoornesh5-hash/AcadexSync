# ACADEXSYNC: Global UI Restoration, Academics-Style Scrolling, Navigation Repair & Brand Migration Report

**Date:** October 28, 2026  
**Project:** ACADEXSYNC (formerly ACADEX)  
**Target Platform:** Flutter Multi-Platform (Android, iOS, Web, Desktop) & Node.js/TypeScript Backend  
**Artifact Generated:** `Frontend/build/app/outputs/flutter-apk/app-debug.apk` (277MB)

---

## 1. Reference Implementation Details: Academic Structure Screen

The canonical single source of truth for the scrolling-header layout and dynamic header collapse animation is the **Academics Structure screen** located at:
`Frontend/lib/features/academic_structure/presentation/screens/academic_structure_home_screen.dart`.

### Layout, Animation, and Aesthetic Architecture:
- **Expanded Height (`expandedHeight`):** Exactly `140.0` logical pixels.
- **Collapsed / Toolbar Height (`toolbarHeight`):** Exactly `64.0` logical pixels (`kToolbarHeight + 8`).
- **Scroll Physics:** `AlwaysScrollableScrollPhysics` with a bounce curve (`BouncingScrollPhysics` on iOS/macOS, clamped stretch on Android/Web).
- **Header State:**
  - `pinned: true` — The header smoothly collapses into an anchored, glassmorphic top navigation bar and never scrolls off-screen.
  - `floating: false` — Does not snap back down on slight reverse scrolling; expands predictably only when scrolled to the very top.
- **Collapse Animation Behavior:**
  - Implemented via a custom `SliverPersistentHeaderDelegate` (`_AcadexTransformingHeaderDelegate`).
  - Progress parameter $t \in [0.0, 1.0]$ is computed as:
    $$t = \frac{\text{maxExtent} - \text{currentExtent}}{\text{maxExtent} - \text{minExtent}}$$
  - **Expanded State ($t = 0.0$):**
    - Large typography title (`AcadexTypography.heading1` / `headlineMedium`, 26–28sp bold).
    - Descriptive subtitle underneath (`AcadexTypography.body` / `bodyMedium`, muted ink).
    - Left-aligned title with leading avatar or back button and trailing action icons.
  - **Collapsed State ($t = 1.0$):**
    - Smoothly transitions title to compact app-bar title (`AcadexTypography.heading3` / `titleMedium`, 18sp semi-bold).
    - Subtitle fades out to zero opacity ($\text{opacity} = (1.0 - t \times 2.0).clamp(0.0, 1.0)$).
    - Actions maintain anchored placement on the top-right.
    - Background morphs from transparent page canvas into an elevated, blur-filtered surface with `AcadexColors.surface(isDark)` and subtle bottom border `AcadexColors.border(isDark)`.
- **Inner Padding & Spacing:**
  - Horizontal margin/padding: `AcadexSpacing.pagePadding(context)` (16px on mobile, 24px on tablet, 32px on desktop).
  - Vertical spacing between header and sliver list items: 16px.
- **Card & Surface Architecture:**
  - Cards use `AcadexColors.cardBackground(isDark)` with 16px corner radius (`AcadexRadius.card`).
  - Subtle borders: 1px width with `AcadexColors.border(isDark)`.
  - Zero heavy drop shadows; clean elevation with low opacity dark tint.

---

## 2. Responsible Core Widgets and Classes

The scrolling-header paradigm is implemented by the shared design system widgets in `Frontend/lib/core/presentation/widgets/`:

1. **`AcadexSliverPageContainer`** (`acadex_sliver_page_container.dart`):
   - Scaffold wrapper managing `CustomScrollView`, safe-area insets, pull-to-refresh (`RefreshIndicator`), floating action buttons, and bottom navigation padding.
   - Accepts both sliver lists (`slivers: [...]`) and boxed body content (`sliverBody`).
2. **`AcadexSliverPageHeader`** (`acadex_sliver_page_container.dart`):
   - A declarative wrapper around Flutter's `SliverPersistentHeader`.
   - Exposes parameters: `title`, `subtitle`, `expandedHeight`, `collapsedHeight`, `leading`, `actions`, and optional custom `expandedContent`.
3. **`_AcadexTransformingHeaderDelegate`** (`acadex_sliver_page_container.dart`):
   - The underlying `SliverPersistentHeaderDelegate` performing the matrix transformations, opacity fades, font-size interpolations, and dark/light mode surface switching.

---

## 3. Shared Implementation Reused

Rather than duplicating custom `NestedScrollView` or `CustomScrollView` implementations with inconsistent scroll controllers, all repaired modules were refactored to standardise on `AcadexSliverPageContainer` and `AcadexSliverPageHeader`:
- Timetable Module (`TimetableDashboardScreen`)
- Notes Module (`NotesDashboardScreen` & `NoteDetailScreen`)
- Notifications Module (`NotificationCenterScreen`)
- Profile Module (`ProfileScreen` & `EditProfileScreen`)

This guaranteed unified deceleration curves, matching status-bar insets, and cohesive visual collapse transitions across the entire application.

---

## 4. Repaired Modules and Modified Files

### Core Design System & Navigation:
- `Frontend/lib/core/presentation/design_system/acadex_colors.dart` — Added primary, secondary, and attention accent tokens (`accentBlue`, `accentPink`, `accentYellow` with light/dark variants).
- `Frontend/lib/app/theme/app_theme.dart` — Integrated new accent tokens into the global ThemeData extension.
- `Frontend/lib/core/presentation/navigation/acadex_nav_item.dart` — Restructured role navigation access, separated timetable viewer from admin authoring, and updated HOD primary tabs.
- `Frontend/lib/core/presentation/navigation/acadex_bottom_nav_bar.dart` — Added Requests icon mapping and role-aware bottom tab generation.

### Timetable Module:
- `Frontend/lib/features/timetable/presentation/screens/timetable_dashboard_screen.dart` — Migrated to `AcadexSliverPageContainer` + `AcadexSliverPageHeader`, added role subtitles and direct HOD authoring action.
- `Frontend/lib/features/timetable/presentation/widgets/next_class_card.dart` — Fixed time-range formatting dash to standard en-dash (`–`).

### Notes Module:
- `Frontend/lib/features/notes/presentation/screens/notes_dashboard_screen.dart` — Removed redundant header-level create button; consolidated creation strictly to the primary bottom-right FAB when populated, and single action button in empty state.
- `Frontend/lib/features/notes/presentation/screens/note_detail_screen.dart` — Converted to `AcadexSliverPageContainer`, fixed white-on-white text contrast bugs in note cards and metadata badges.

### Notifications Module:
- `Frontend/lib/features/notifications/presentation/screens/notification_center_screen.dart` — Migrated to `AcadexSliverPageContainer`, corrected background contrast in dark mode.
- `Frontend/lib/features/notifications/presentation/widgets/notification_card.dart` — Restored unread indicator dot and fixed low-contrast text.

### Profile Module:
- `Frontend/lib/features/profile/presentation/screens/profile_screen.dart` — Migrated to `AcadexSliverPageContainer`, wrapped in `Material` scaffold, and added role-scoped metadata sections.
- `Frontend/lib/features/profile/presentation/screens/edit_profile_screen.dart` — Migrated to `AcadexSliverPageContainer`, cleaned up bottom overflow with safe-area spacing.

### Attendance & Role Dashboards:
- `Frontend/lib/features/attendance/presentation/screens/attendance_dashboard_router.dart` — Corrected HOD routing directly to `HodAttendanceDashboardScreen`.
- `Frontend/lib/features/attendance/presentation/screens/hod_attendance_dashboard_screen.dart` — Replaced infinite repeating character animation with `AcadexLoadingState.spinner`.
- `Frontend/lib/features/attendance/data/repositories/api_attendance_repository.dart` — Added safe offline fallback on connection drops.
- `Frontend/lib/features/dashboard/presentation/screens/college_admin_dashboard.dart` — Switched to `AcadexLoadingState.spinner`.
- `Frontend/lib/features/dashboard/presentation/screens/super_admin_dashboard.dart` — Switched to `AcadexLoadingState.spinner`.
- `Frontend/lib/features/dashboard/presentation/screens/hod_dashboard.dart` — Switched to `AcadexLoadingState.spinner`.

### Rebranding (ACADEX $\to$ ACADEXSYNC):
- `Frontend/android/app/src/main/AndroidManifest.xml` — Changed `android:label` to `ACADEXSYNC`.
- `Frontend/web/index.html` — Updated document `<title>` and `<meta name="description">` to `ACADEXSYNC`.
- `Frontend/web/manifest.json` — Updated `name` and `short_name` to `ACADEXSYNC`.
- `Frontend/lib/main.dart` — Updated root `MaterialApp.router` title to `ACADEXSYNC`.
- `Frontend/lib/features/dashboard/presentation/widgets/acadex_app_bar.dart` — App bar brand title set to `ACADEXSYNC`.
- `Frontend/lib/features/dashboard/presentation/widgets/acadex_drawer.dart` — Drawer header and logout dialog text set to `ACADEXSYNC`.
- `Frontend/lib/features/dashboard/presentation/screens/role_dashboard_screen.dart` — Dashboard title and subtitle set to `ACADEXSYNC`.
- `Frontend/lib/features/dashboard/presentation/screens/coming_soon_screen.dart` — Notice message updated to `ACADEXSYNC`.
- `Frontend/lib/features/auth/presentation/screens/splash_screen.dart` — Splash title updated to `ACADEXSYNC`.
- `Frontend/lib/features/auth/presentation/screens/login_screen.dart` — Desktop and mobile headers and copyright footer updated to `ACADEXSYNC`.
- `Frontend/lib/features/settings/presentation/screens/settings_home_screen.dart` — Sign-out dialog and About screen updated to `ACADEXSYNC`.
- `Frontend/lib/features/settings/presentation/screens/misc_settings_screens.dart` — About and legal descriptions updated to `ACADEXSYNC`.
- `Frontend/lib/core/presentation/screens/firebase_error_screen.dart` — Error screen title and instructions updated to `ACADEXSYNC`.
- `Frontend/lib/core/network/network_error_diagnostic.dart` — User-facing 404/500 diagnostic errors updated to `ACADEXSYNC`.
- `Frontend/lib/core/presentation/assistant/acadex_assistant.dart` & `acadex_assistant_showcase_screen.dart` — Assistant studio titles and accessibility labels updated to `ACADEXSYNC`.
- `Frontend/lib/features/ai_assistant/presentation/widgets/` & repositories — AI chat composer, disclaimer, and exception text updated to `ACADEXSYNC`.
- `Backend/src/services/ai.service.ts` & `Backend/src/controllers/ai.controller.ts` — System prompt persona and unauthorized error message updated to `ACADEXSYNC`.

---

## 5. Role-by-Role Navigation Verification

| Role | Before | After | Bottom Navigation Tabs | Primary Drawer Items |
| :--- | :--- | :--- | :--- | :--- |
| **College Admin** | Drawer contained management links mixed with normal views; missing unified Timetable entry. | Clean hierarchy. Normal views separated from administrative authoring. | 1. Dashboard (`/`)<br>2. Structure (`/academic-structure`)<br>3. Timetable (`/timetable`)<br>4. Notifications (`/notifications`)<br>5. Profile (`/profile`) | - Dashboard<br>- Academic Structure<br>- Timetable Viewer<br>- Attendance Analytics<br>- Manage Timetables<br>- Users & Roles<br>- Institution Config<br>- Settings |
| **HOD** | Drawer Timetable clicked directly into `/timetable/manage` (authoring spreadsheet), confusing viewing with editing. Bottom nav included Notes instead of Requests. | Clicking Timetable navigates to personal/department schedule `/timetable` with an embedded "Manage & Create" action. Bottom nav replaced Notes with Requests. | 1. Dashboard (`/`)<br>2. Structure (`/academic-structure`)<br>3. Timetable (`/timetable`)<br>4. Requests (`/requests`)<br>5. Profile (`/profile`) | - Dashboard<br>- Academic Structure<br>- Department Timetable<br>- Department Attendance<br>- Requests & Approvals<br>- Notes & Resources<br>- Notifications<br>- Settings |
| **Faculty** | Unchanged structure; verified schedule and teaching assignments. | Retained high-frequency faculty flows with improved scrolling headers. | 1. Dashboard (`/`)<br>2. Timetable (`/timetable`)<br>3. Attendance (`/attendance`)<br>4. Notes (`/notes`)<br>5. Profile (`/profile`) | - Dashboard<br>- My Timetable<br>- Mark Attendance<br>- Notes & Resources<br>- Student Requests<br>- Notifications<br>- Settings |
| **Student** | Unchanged structure; verified personal classes and notes. | Retained student-centric flows with fixed typography contrast. | 1. Dashboard (`/`)<br>2. Timetable (`/timetable`)<br>3. Attendance (`/attendance`)<br>4. Notes (`/notes`)<br>5. Profile (`/profile`) | - Dashboard<br>- Class Schedule<br>- My Attendance<br>- Study Notes<br>- Submit Request<br>- Notifications<br>- Settings |

---

## 6. HOD Timetable Routing Fix

### Previous Defect:
In `Frontend/lib/core/presentation/navigation/acadex_nav_item.dart`, `AcadexNavItem.timetable` mapped directly to route `/timetable/manage` with title `'Manage Timetable'`, while `AcadexNavItem.timetableUser` was hidden or inaccessible to HODs. When an HOD selected Timetable in the sidebar or bottom bar, the app launched directly into the matrix authoring/structure spreadsheet editor instead of showing the department's day/week timetable.

### Resolved Behavior:
1. `AcadexNavItem.timetableUser` (`/timetable`) was granted to `collegeAdmin`, `hod`, `faculty`, and `student`.
2. `AcadexNavItem.timetable` (`/timetable/manage`) was marked as `isInDrawer: false` so the sidebar and bottom bar route directly to `/timetable`.
3. Inside `TimetableDashboardScreen`, role-based detection adds an authoritative **"Manage & Create"** button for HOD and College Admin in the top-right of the header and within empty states, linking directly to `/timetable/manage`.
4. HODs can now effortlessly review daily classes first, and smoothly open the authoring suite when edits are required.

---

## 7. Notes Creation UX Consolidation

### Previous Defect:
`NotesDashboardScreen` presented two simultaneous, competing create actions:
1. An action button embedded in the search/filter header bar.
2. A floating action button (FAB) in the lower-right corner.
Furthermore, on empty lists, redundant buttons caused layout jitter and duplicate form triggers.

### Resolved Behavior:
1. **Header Action Removed:** The header action button was completely removed from the filter bar.
2. **Populated State:** When notes are present, creation is exclusively handled by the single, prominent bottom-right `FloatingActionButton` with icon `LucideIcons.plus`.
3. **Empty State:** When no notes match the active filter or the repository is empty, the FAB is suppressed and a single primary action button (**"Create Note"**) is rendered inside the centered `AcadexEmptyState` widget.

---

## 8. Screen Restorations & Edge-to-Edge Fixes

### Notification Center:
- Replaced standard Scaffold with `AcadexSliverPageContainer` and `AcadexSliverPageHeader(title: 'Notifications', subtitle: 'Stay updated on college alerts and announcements')`.
- Fixed dark mode background where cards blended into the page background.
- Restored unread dot indicator in `NotificationCard` with `AcadexColors.accentBlue`.

### Profile & Edit Profile:
- Converted `ProfileScreen` to `AcadexSliverPageContainer` with sliver avatar header.
- Added explicit `Material` ancestor to prevent test runner assertions on missing theme context.
- Fixed `EditProfileScreen` bottom text overflow by wrapping form fields in safe-area-padded sliver content.

### Text Contrast (Elimination of White-on-White Bugs):
- In `NoteDetailScreen`, metadata chips and tags were previously using hardcoded white text on light surfaces. Replaced all occurrences with `AcadexColors.ink(isDark)` and `AcadexColors.inkSecondary(isDark)`.
- In `notification_card.dart`, timestamps and sender subtitles now dynamically reference semantic theme tokens.

---

## 9. Color Token System Additions

In `Frontend/lib/core/presentation/design_system/acadex_colors.dart` and `Frontend/lib/app/theme/app_theme.dart`:

```dart
// Primary Accent — Vibrant Modern Blue
static const Color accentBlue = Color(0xFF2563EB); // Light Mode
static const Color darkAccentBlue = Color(0xFF3B82F6); // Dark Mode

// Secondary Subtle Accent — Modern Rose / Pink
static const Color accentPink = Color(0xFFEC4899); // Light Mode
static const Color darkAccentPink = Color(0xFFF472B6); // Dark Mode

// Attention / Warning Accent — Warm Amber / Yellow
static const Color accentYellow = Color(0xFFF59E0B); // Light Mode
static const Color darkAccentYellow = Color(0xFFFBBF24); // Dark Mode
```

### Purpose & Usages:
- **`accentBlue` / `darkAccentBlue`:** Used for active navigation tabs, unread notifications, primary CTAs, and interactive timeline indicators.
- **`accentPink` / `darkAccentPink`:** Used for category tags (e.g., "Event", "Urgent Announcement"), resource badges, and highlight pills.
- **`accentYellow` / `darkAccentYellow`:** Used for pending review status, warnings, timetable conflict indicators, and system maintenance alerts.

---

## 10. Branding Audit & Intentional Preservations

### All User-Visible Locations Migrated to `ACADEXSYNC`:
- App Launcher Title: `AndroidManifest.xml` (`android:label="ACADEXSYNC"`), `web/index.html`, `web/manifest.json`.
- Root Application Title: `Frontend/lib/main.dart` (`MaterialApp(title: 'ACADEXSYNC')`).
- Navigation Bars: `AcadexAppBar` default title `'ACADEXSYNC'`, `AcadexDrawer` header `'ACADEXSYNC'`.
- Authentication Screens: `SplashScreen` logo title, `LoginScreen` desktop & mobile titles, footer `'© 2026 ACADEXSYNC Platform'`.
- Dashboard Titles: `RoleDashboardScreen` `'ACADEXSYNC Dashboard'`, Coming Soon notices.
- Settings & About Screens: About dialog, legal disclosures, terms notice `'ACADEXSYNC Campus Management System'`.
- Error Dialogs & Diagnostics: Firebase connection error screen, network diagnostic 404/500 messages.
- AI Assistant: Assistant Studio title, composer hints, response disclaimers, backend AI system prompt instruction persona.

### Technical Identifiers Intentionally Preserved:
In strict compliance with Prompt Section 11 & 13, the following internal contracts were **strictly preserved** to guarantee zero disruption to backend databases, routes, and tests:
- **Application Package / Bundle ID:** `com.acadex.campus_management` / `campus_management`.
- **Backend API Endpoints:** All `/api/v1/...` routes intact.
- **Database Collections & Schemas:** MongoDB collections (`users`, `academic_periods`, `timetables`, `notes`, `attendance`, etc.) and Firestore collection names.
- **JWT & Role Claims:** Authentication tokens, claim names (`workspaceId`, `role`), and internal RBAC enums (`Role.COLLEGE_ADMIN`, `Role.HOD`, etc.).
- **Dart Symbols & Token Classes:** `AcadexColors`, `AcadexSpacing`, `AcadexTypography`, `acadex_local_app_settings`, logger names (`Acadex.Auth`, `Acadex.Timetable`).
- **Export File Formats:** CSV export header `ACADEX STUDENT ATTENDANCE REPORT` in `attendance_report_exporter.dart` (asserted by automated integration tests).
- **Test Compatibility:** Legacy test assertion strings (e.g. `'ACADEX Platform Administration'`).

---

## 11. Technical Compatibility Verification

- **Zero Breaking API Changes:** All REST endpoints and payload serialization schemas were untouched.
- **Cross-Tenant Isolation:** Maintained strict tenant-scoping across College Admin, HOD, and Student/Faculty data layers.
- **State Management:** All Riverpod providers (`homeDashboardProvider`, `timetableProvider`, `notesProvider`, `profileProvider`) function seamlessly with the new sliver containers.
- **Realtime Dispatcher:** Invalidation events (`dashboard.refreshed`, `note.published`, `profile.updated`) successfully trigger background refetches.

---

## 12. Verification Commands & Execution Results

### 1. Static Code Analysis:
```bash
flutter analyze
```
- **Result:** **0 Errors.** 414 pre-existing informational hints (legacy control flow curly-brace formatting in untouched files).

### 2. Automated Test Suite (103/103 Passed):
```bash
flutter test \
  test/navigation_information_architecture_test.dart \
  test/academic_structure_ui_test.dart \
  test/timetable_ui_vertical_slice_test.dart \
  test/notes_ui_vertical_slice_test.dart \
  test/notes_ui_test.dart \
  test/notifications_ui_vertical_slice_test.dart \
  test/profile_prompt48_test.dart \
  test/dashboard_prompt49_test.dart \
  test/faculty_student_compact_dashboard_test.dart \
  test/attendance_ui_vertical_slice_test.dart
```
- **Result:** **`All tests passed!` (103 out of 103 tests passed with 0 failures).**
  - Navigation Information Architecture: 17/17 passed
  - Academic Structure UI: 6/6 passed
  - Timetable Vertical Slice: 9/9 passed
  - Notes UI & Vertical Slice: 15/15 passed
  - Notifications Vertical Slice: 6/6 passed
  - Profile Management: 12/12 passed
  - Role Dashboards (College Admin, Super Admin, HOD, Faculty, Student): 14/14 passed
  - Multi-breakpoint Responsive Layouts: 8/8 passed
  - Attendance Router & Marking Flow: 9/9 passed
  - Realtime Invalidation Dispatcher: 7/7 passed

### 3. Backend AI Integration Tests:
```bash
npm test -- -t "AI" --bail
```
- **Result:** **9/9 Passed.** AI system prompts, tool declarations, and persona scoping verified.

### 4. Android Debug APK Build:
```bash
flutter build apk --debug
```
- **Result:** **`✓ Built build/app/outputs/flutter-apk/app-debug.apk` in 33.6s.**
- **Artifact Path:** `/Users/poornesh/Campus Management Main/Frontend/build/app/outputs/flutter-apk/app-debug.apk`
- **Artifact Size:** 277 MB (complete debug binary).

---

## 13. Limitations & Manual Verification Steps

> [!NOTE]
> Per automated execution requirements, tests were completed using headless Flutter test environments and the Gradle build toolchain. No physical device or Android emulator was booted.

### Step-by-Step Manual Verification Guide:

1. **Brand & Header Inspection:**
   - Launch the application:
     ```bash
     cd Frontend && flutter run -d chrome # or connect an Android device
     ```
   - Observe the launcher/app bar: Verify the brand displays **ACADEXSYNC**.
   - Log in with any demo credentials (e.g. HOD or College Admin).
   - Verify the top navigation bar displays **ACADEXSYNC**. Open the drawer and confirm header reads **ACADEXSYNC**.

2. **Scrolling-Header Test (Academics-Style Parity):**
   - Navigate to **Timetable** (`/timetable`).
   - Scroll downward: Verify that the header shrinks from 140px to 64px, the subtitle fades out smoothly, the title transitions to compact size, and the background shifts into an anchored glassmorphic blur bar.
   - Scroll back to the top: Verify the header gracefully expands back to its full height.
   - Repeat on **Notes**, **Notifications**, and **Profile**.

3. **HOD Navigation Test:**
   - Log in as an **HOD**.
   - Check the bottom navigation bar: Confirm the tabs are **Dashboard**, **Structure**, **Timetable**, **Requests**, and **Profile**.
   - Tap **Timetable**: Confirm it opens the day/week timetable view first (not the authoring grid).
   - In the top right, tap **"Manage & Create"**: Confirm it opens the authoring spreadsheet (`/timetable/manage`).

4. **Notes Single-Create UX Test:**
   - Tap **Notes** in the drawer or bottom navigation.
   - Observe the interface: Confirm there is **no create button** in the search filter bar.
   - Confirm exactly one floating action button (+) appears in the bottom right.
   - Filter to a query that has no notes: Confirm the FAB disappears and a single "Create Note" button appears inside the empty state.

5. **Theme & Contrast Test:**
   - Open **Settings** $\to$ Toggle between **Dark Mode** and **Light Mode**.
   - Navigate to **Note Details**: Confirm note content, metadata tags, and author badges are crisp and legible with zero white-on-white text.
   - Navigate to **Notifications**: Confirm unread cards show the vibrant blue dot indicator and distinct border contrast.
