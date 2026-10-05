# ACADEX PROFESSIONAL RECOVERY PROGRAM
## PROMPT 01 OF 12: RUNTIME FORENSIC ENVIRONMENT & REAL DEVICE OBSERVABILITY
### BASELINE REPORT

**Status:** `RUNTIME VERIFIED`  
**Execution Timestamp:** 2026-10-05T00:45:00+05:30  
**Target Environment:** Physical Android Device (Motorola Edge 60 Fusion / Android 16 / API 36)  
**Backend:** Node.js / TypeScript Express on port 5050 (MongoDB Atlas live database)  
**Methodology:** `OBSERVE → MEASURE → TRACE → ROOT CAUSE → MINIMAL FIX → BUILD → RUNTIME TEST → SCREENSHOT → COMPARE → REGRESSION`  

---

### EXECUTIVE SUMMARY

In strict adherence to Prompt 01 guidelines:
1. **Zero speculative code changes** were made to production frontend or backend logic.
2. A **real Android physical hardware runtime** (`Motorola Edge 60 Fusion`, device id: `ZN4223NKHX`) was established as the primary forensic observation target via adb reverse networking.
3. All **five core roles** (Super Admin, College Admin, HOD, Faculty, Student) were authenticated against the live backend and MongoDB database, with their live rendered states, drawers, navigation tabs, and sub-screens visually captured and verified.
4. The **Activity Screen & Top-Clipping Root Cause** was forensically diagnosed down to the exact widget tree and routing structure (`ShellWrapper` padding contract vs. `AcadexPageContainer`).
5. A comprehensive **Global UI Bug Inventory** was documented with strict P0–P3 classification, including a critical drawer logout lifecycle bug.
6. Static analysis and test baselines were recorded (`flutter analyze`: 0 issues, backend unit tests: 230/230 passed, legacy widget test failures isolated and cataloged).
7. The development loop is formally established and verified on physical hardware.

---

### SECTION A: ENVIRONMENT CONFIGURATION

| Component | Specification / Configuration | Verification Status |
| :--- | :--- | :--- |
| **Host OS** | macOS Darwin 24.3.0 (Apple Silicon arm64) | Active |
| **Node.js** | v20.18.0 / npm 10.8.2 | Verified |
| **Database** | MongoDB Atlas (Cluster `acadex`) | Connected & Healthy |
| **Backend Service** | Express / TypeScript on `http://localhost:5050` | Active (PID daemon `task-241`) |
| **Health Endpoint** | `GET /health` → `{"status":"ok","database":"connected","timestamp":...}` | Verified (200 OK) |
| **Network Forwarding** | `adb -s ZN4223NKHX reverse tcp:5050 tcp:5050` | Active & Tested |
| **WebSocket** | `ws://localhost:5050/ws` | Verified configured |
| **App Build Type** | Flutter Debug APK (`--dart-define=API_BASE_URL=http://localhost:5050/api/v1`) | Installed & Running |

---

### SECTION B: FLUTTER & DART TOOLCHAIN

| Tool / Dependency | Version / Path |
| :--- | :--- |
| **Flutter SDK** | `3.47.2` (Channel stable, `git: 4fa2be0eb1`) |
| **Dart SDK** | `3.13.2` |
| **Android SDK** | Android SDK 36.0.0 (`/Users/poornesh/Library/Android/sdk`) |
| **Java / JDK** | OpenJDK 17.0.12 (JetBrains Runtime) |
| **Gradle** | `Gradle 9.1.0` (Gradle Wrapper) |
| **Android Gradle Plugin (AGP)** | `9.0.1` |
| **Kotlin** | `2.3.20` |
| **compileSdk** | `36` |
| **targetSdk** | `36` |
| **minSdk** | `21` |

---

### SECTION C: ANDROID RUNTIME FORENSIC PROFILE

Testing was conducted exclusively on **physical Android hardware**, fulfilling Section 3 requirements:

* **Device Manufacturer & Model:** Motorola Edge 60 Fusion (`motorola`)
* **Hardware Identifier / Serial:** `ZN4223NKHX`
* **Android OS Version:** Android 16 (VanillaIceCream / Baklava preview runtime)
* **API Level:** `36`
* **Physical Display Resolution:** `1220 x 2712` pixels
* **Display Density:** `450 dpi`
* **Device Pixel Ratio (DPR):** `2.8125` (calculated as `450 / 160`)
* **Orientation:** Portrait (primary)

---

### SECTION D: RUNTIME DIMENSIONS & INSETS

Extracted directly from device window manager (`dumpsys window` and Flutter `MediaQuery`):

```
+-----------------------------------------------------------+
| Status Bar (Physical: 128 px  | Logical: 45.51 dp)        |
| [Camera Cutout: 565..655, 0..128 px]                      |
+-----------------------------------------------------------+
| Shell AppBar (Fixed: 56.0 dp)                             |
+-----------------------------------------------------------+
|                                                           |
| Usable Content Area                                       |
| Width:  1220 px physical -> 433.77 dp logical             |
| Height: 2516 px physical -> 894.57 dp logical             |
|                                                           |
+-----------------------------------------------------------+
| Bottom Navigation Bar (Fixed: 64.0 dp)                    |
+-----------------------------------------------------------+
| Gesture Inset (Physical: 68 px | Logical: 24.18 dp)       |
+-----------------------------------------------------------+
```

* **Total Screen Height:** `2712 px` / `964.26 dp`
* **Status Bar Top Inset:** `128 px` / `45.51 dp`
* **Navigation Gesture Bar Inset:** `68 px` / `24.18 dp`
* **Camera Cutout (Punch hole):** Centered at `X: 565 to 655 px`, `Y: 0 to 128 px`
* **Total Top Chrome Height (Status + Shell AppBar):** `45.51 dp + 56.0 dp = 101.51 dp`
* **Breakpoints:** Evaluates to `compact / mobile` (`width = 433.77 dp < 600 dp`)

---

### SECTION E: FIVE-ROLE LOGIN RUNTIME VERIFICATION MATRIX

All five system roles were authenticated against the live database using development credentials. Authentication tokens, tenant context, and institutional role scoping were verified:

| Role | Test Identity | Tenant / Institution | Dashboard Verification | Navigation Shell | Baseline Screenshot |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Super Admin** | `princepoornesh5@gmail.com` | System Wide | Multi-tenant overview, institution cards, global audit logs | Dashboard, Drawer, Global Management | `02_super_admin_dashboard.png`<br>`02_super_admin_drawer.png` |
| **College Admin** | `admin@acadex-pilot.edu` | Acadex Engineering College (`INST-DEMO-001`) | Academic structure, departments, faculty rosters, reports | Academics, People, Reports, Settings | `03_college_admin_dashboard.png`<br>`03_college_admin_academics.png`<br>`03_college_admin_people.png` |
| **HOD** | `hod.cse@acadex-pilot.edu`<br>(Prof. Suresh Verma) | Acadex Engineering College / Dept of CSE | Department metrics, class schedules, faculty workload, attendance guards | Department Dashboard, Classes, Faculty Workload, Approvals | `04_hod_dashboard.png` |
| **Faculty** | `faculty.dbms@acadex-pilot.edu`<br>(Prof. Rajesh Kumar) | Acadex Engineering College / Dept of CSE | Assigned classes (DBMS, OS), attendance marking, assignment center | Today's Classes, Attendance, Assignments, Timetable | `05_faculty_dashboard.png` |
| **Student** | `student.a@acadex-pilot.edu`<br>(Aarav Sharma) | Acadex Engineering College / CE Sem 5 Sec A | Attendance summary (82%), upcoming classes, pending assignments | Attendance, Timetable, Notes, Coursework | `06_student_dashboard.png`<br>`06_student_attendance.png`<br>`06_student_timetable.png` |

---

### SECTION F: SCREEN INVENTORY ACROSS ROLES

| Screen Name | Route | Observed Roles | Primary APIs | Controller / Service | Realtime WS | Visual / Layout Issues |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Login Screen** | `/login` | Public / Unauth | `POST /api/v1/auth/login` | `auth.controller.ts` | No | Clean rendered state; quick-fill buttons operational. |
| **Super Admin Home** | `/super-admin` | Super Admin | `GET /api/v1/institutions`, `/analytics/global` | `institution.controller.ts` | No | Cards scale correctly on 434dp viewport; metrics render. |
| **College Admin Home** | `/college-admin` | College Admin | `GET /api/v1/dashboard/metrics` | `dashboard.controller.ts` | Yes | Layout well-proportioned; KPI metric cards rendered. |
| **Academic Structure** | `/academic-structure` | College Admin, HOD | `GET /api/v1/academic-structure/departments` | `academic.controller.ts` | No | Department and section trees expand properly. |
| **User Directory** | `/people` | College Admin | `GET /api/v1/users` | `user.controller.ts` | No | Search bar and user cards rendered cleanly. |
| **Analytics & Reports** | `/analytics` | College Admin, HOD | `GET /api/v1/analytics/reports` | `analytics.controller.ts` | No | **P2 Visual Defect:** Top cards clip behind `AcadexAppBar` (lacks `AcadexPageContainer`). |
| **Admin Settings** | `/settings` | College Admin, All | Local state + `GET /api/v1/users/me` | `user.controller.ts` | No | Scrollable; sign-out button functioning. |
| **Profile Screen** | `/profile` | All Roles | `GET /api/v1/auth/me`, `/profile` | `profile.controller.ts` | No | **P2 Visual Defect:** Double AppBar rendered (Outer Shell AppBar + Inner Scaffold AppBar). |
| **HOD Dashboard** | `/hod` | HOD | `GET /api/v1/dashboard/hod` | `dashboard.controller.ts` | Yes | Workload distribution and approval queues display properly. |
| **Faculty Dashboard** | `/faculty` | Faculty | `GET /api/v1/attendance/assigned-classes` | `attendance.controller.ts` | Yes | Class cards render; active period indicator displays. |
| **Student Dashboard** | `/student` | Student | `GET /api/v1/dashboard/student` | `dashboard.controller.ts` | Yes | Metrics (82% attendance, 3 assignments) visible. |
| **Student Attendance** | `/attendance` | Student | `GET /api/v1/attendance/portal` | `attendance.controller.ts` | No | Subject-wise breakdown cards render correctly. |
| **Student Timetable** | `/timetable` | Student, Faculty | `GET /api/v1/timetable/today` | `timetable.controller.ts` | No | Period cards, day selector, and timing slots display. |
| **Student Notes** | `/notes` | Student | `GET /api/v1/notes` | `notes.controller.ts` | No | **P2 Visual Defect:** Search field clips behind top AppBar (lacks `AcadexPageContainer`). |
| **Student Assignments**| `/assignments` | Student | `GET /api/v1/assignments` | `assignments.controller.ts` | No | Empty/active assignment list rendered. |

---

### SECTION G: API & BACKEND ROUTE OBSERVATIONS

1. **Authentication Flow:**
   - `POST /api/v1/auth/login`: Validated against live MongoDB. Returns standard payload containing `accessToken`, `refreshToken`, and sanitized user entity with role and tenant keys.
   - Strict security check: Passwords and sensitive bearer headers are sanitized and never logged or exposed.
2. **Multi-Tenant Context Enforcement:**
   - Tenant isolation verified on backend: `tenantId` is extracted from verified JWT claims by `tenant.middleware.ts`. Queries are strictly partitioned by `institutionId`.
3. **Network Transport Observation:**
   - Due to physical device USB networking, `10.0.2.2` does not route. Reverse TCP forwarding (`adb reverse tcp:5050 tcp:5050`) coupled with `--dart-define=API_BASE_URL=http://localhost:5050/api/v1` routes all network traffic cleanly over USB at high speed.
   - Note on device storage clear: Executing `adb shell pm clear` severs `adb reverse` rules. Re-executing `adb reverse` must be part of any automated reset procedure.

---

### SECTION H: ACTIVITY SCREEN & TOP-CLIPPING FORENSIC ROOT CAUSE ANALYSIS

A core objective of Prompt 01 is diagnosing why screens like Activity, Analytics, and Notes appear top-clipped or misaligned under the AppBar.

#### 1. Traced Widget Hierarchy
```
MaterialApp.router (GoRouter)
  └── ShellRoute
        └── ShellWrapper (Frontend/lib/app/router/app_router.dart:273)
              └── Scaffold(
                    extendBodyBehindAppBar: true,       <-- CRITICAL ROOT FACTOR 1
                    appBar: AcadexAppBar(height: 56dp),  <-- CRITICAL ROOT FACTOR 2
                    body: [Child Route Screen],
                    bottomNavigationBar: AcadexBottomNav()
                  )
```

#### 2. Root Cause Breakdown
1. **`extendBodyBehindAppBar: true` in `ShellWrapper`:**
   - In `app_router.dart` (line 273), `ShellWrapper` explicitly sets `extendBodyBehindAppBar: true`.
   - This causes Flutter's render pipeline to place the origin point `(0, 0)` of every child screen's body at the very top edge of the physical display (behind the status bar and the 56dp `AcadexAppBar`).
   - The total occluded vertical space is `Status Bar (45.51 dp) + AppBar (56.0 dp) = 101.51 dp`.

2. **The Inconsistent Padding Contract:**
   - Screens that wrap their content in `AcadexPageContainer` (e.g. `CollegeAdminDashboard`, `StudentDashboard`) correctly compensate for this occlusion via:
     ```dart
     final topPadding = baseTop + mediaTop + kAppBarHeight; // ~101.5 dp
     ```
   - However, screens that do NOT use `AcadexPageContainer` (such as `AnalyticsDashboardScreen` line 33, `NotesDashboardScreen` line 64) apply fixed local padding (e.g., `EdgeInsets.all(16.0)` or `EdgeInsets.only(top: 8.0)`).
   - **Result:** The top 85.51 dp of content (headers, search input fields, metric cards) renders directly underneath the opaque/blur AppBar background, causing complete visual clipping on the physical screen.

3. **The Double AppBar Root Cause on Profile / Nested Screens:**
   - In `ProfileScreen` (`Frontend/lib/features/profile/presentation/screens/profile_screen.dart:92`), the screen instantiates its own `Scaffold` with its own `AppBar(title: Text('Profile'))`.
   - Because `ProfileScreen` is served inside `ShellWrapper`, Flutter renders two stacked AppBars:
     - Outer `AcadexAppBar` (from `ShellWrapper`)
     - Inner `AppBar` (from `ProfileScreen`)
   - **Result:** ~157.5 dp of top screen real estate is consumed by two conflicting headers before user content begins.

4. **Assignment Activity Screen TabBar Stacking:**
   - In `AssignmentActivityScreen`, the screen introduces a nested `TabBar` and custom header without resetting or consuming the parent `ShellWrapper` padding.
   - The tab headers either clash with the top AppBar or create an unintended 100+ dp vertical blank gap depending on whether `SafeArea` is applied twice.

---

### SECTION I: GLOBAL UI BUG INVENTORY

#### P0: CRITICAL (Crashes, Security, Tenant Bleed)
*None detected during real physical device runtime.* Multi-tenant isolation and database session security operate as designed.

#### P1: BLOCKING (Functional Blockers, Navigation Dead-ends)
* **BUG-P1-01: Modal Drawer Logout Lifecycle Context Destruction**
  - **File:** `Frontend/lib/features/dashboard/presentation/widgets/acadex_drawer.dart:278-293`
  - **Behavior:** The drawer's logout `ListTile` calls `Navigator.of(context).pop()` *before* awaiting `AcadexConfirmationDialog.show(context: context, ...)`.
  - **Root Cause:** Popping the modal drawer unmounts the drawer's `BuildContext`. When the user confirms the dialog, `if (context.mounted)` evaluates to `false`, silently cancelling `ref.read(authProvider.notifier).logout()`. The user remains logged in with no feedback.
  - **Workaround used during QA:** Signing out via Settings screen (`/settings`) or clearing app cache.

#### P2: MAJOR UX (Visual Clipping, Positioning, Double AppBars)
* **BUG-P2-01: Analytics Screen Top Header Clipped behind Shell AppBar**
  - **File:** `Frontend/lib/features/analytics/presentation/screens/analytics_dashboard_screen.dart`
  - **Root Cause:** Content does not use `AcadexPageContainer`; fixed top padding of 16dp places the title and date picker behind the 101.5dp AppBar.
  - **Evidence:** `03_college_admin_reports.png`
* **BUG-P2-02: Notes Screen Search Bar Clipped behind Shell AppBar**
  - **File:** `Frontend/lib/features/notes/presentation/screens/notes_dashboard_screen.dart`
  - **Root Cause:** Fixed top padding of 8dp; search bar input field is rendered behind the AppBar.
  - **Evidence:** `06_student_notes.png`
* **BUG-P2-03: Double Stacked AppBar on Profile Screen**
  - **File:** `Frontend/lib/features/profile/presentation/screens/profile_screen.dart`
  - **Root Cause:** Screen creates internal `Scaffold` and `AppBar` while hosted inside `ShellWrapper`.
  - **Evidence:** `03_college_admin_profile_double_appbar.png`
* **BUG-P2-04: Card Horizontal Padding Disparity**
  - **Files:** `student_dashboard.dart`, `faculty_dashboard.dart`
  - **Root Cause:** Inconsistent horizontal margins (16dp on cards vs 24dp on section headers) creates jagged vertical scanlines on 434dp display.

#### P3: POLISH (Typography, Alignment, Micro-interactions)
* **BUG-P3-01: Status Indicator Badge Vertical Misalignment**
  - Notification badges and status pill chips on dense class timetable cards exhibit a 1-2dp vertical drift relative to baseline typography on 450dpi display.
* **BUG-P3-02: Drawer Header Bottom Border Contrast**
  - In dark mode, the dividing line below the user identity block in `AcadexDrawer` has insufficient contrast ratio (< 2:1 against background).

---

### SECTION J: RESPONSIVE LAYOUT OBSERVATIONS

* **Adaptive Model Evaluation:**
  - Standard: `MEASURE → ABSTRACT → BRANCH`.
  - The Motorola Edge 60 Fusion presents a logical width of `433.77 dp`.
  - This exceeds standard phone viewports (`360–390 dp`), exposing UI components that use hardcoded widths or fixed aspect ratios.
  - **Finding:** In `timetable_dashboard_screen.dart` and `home_dashboard_widgets.dart`, certain cards calculate item dimensions assuming `< 390 dp`, resulting in excessive trailing whitespace on 434dp screens.
  - **Remedy for upcoming prompts:** Abstract grid layouts to `LayoutBuilder` with dynamic column/card width budgeting instead of fixed cross-axis counts.

---

### SECTION K: EXISTING DESIGN SYSTEM FINDINGS

* **Design Tokens (`Frontend/lib/core/presentation/design_system/`):**
  - `acadex_colors.dart`: Clean palette with semantic dark/light tokens.
  - `acadex_typography.dart`: Well-structured scale utilizing Google Fonts Inter.
  - `acadex_spacing.dart`: Consistent 4dp baseline grid (`xs: 4`, `sm: 8`, `md: 16`, `lg: 24`, `xl: 32`).
  - `acadex_breakpoints.dart`: Mobile (< 600), Tablet (600–1024), Desktop (> 1024).
* **Core Shared Widgets (`Frontend/lib/core/presentation/widgets/`):**
  - `AcadexPageContainer` is the design system's intended layout wrapper. It handles system insets, shell AppBar offsets, and scroll physics.
  - **Key Finding:** The primary source of UI fragmentation across the application is **developer non-compliance**—several feature screens bypassed `AcadexPageContainer` and created raw `Scaffold` / `Padding` layouts, violating the design system's layout contract.

---

### SECTION L: EXISTING TEST STATUS

1. **Flutter Static Analysis (`flutter analyze`):**
   - **Result:** **0 issues found** (Clean analysis in 5.8s).
2. **Flutter Test Suite (`flutter test`):**
   - Total Tests: 1,517
   - **Passed:** 1,436
   - **Skipped:** 5
   - **Failed:** 76
   - **Classification:** **PRE-EXISTING LEGACY FAILURES**.
   - **Analysis:** All 76 failures are pre-existing widget tests written for older screen contracts, obsolete mock state signatures, or removed mock providers. No new failures were introduced.
3. **Backend Typecheck (`npm run typecheck`):**
   - **Result:** **0 errors**.
4. **Backend Unit Tests (`npm test -- tests/unit/`):**
   - **Result:** **21 suites passed, 230 tests passed (100% pass rate)**.

---

### SECTION M: EXISTING BUILD STATUS

* **Flutter APK:** Built successfully in debug mode (`app-debug.apk`, 84.9 MB).
* **Installation:** Verified on physical device `ZN4223NKHX`.
* **Execution:** App launches, initializes Riverpod state, connects to live backend, and maintains smooth 60/120Hz rendering.
* **Backend Build:** TypeScript transpiles cleanly via `ts-node-dev` on port 5050.

---

### SECTION N: FILES INSPECTED

#### Frontend
- `Frontend/lib/main.dart`
- `Frontend/lib/app/router/app_router.dart`
- `Frontend/lib/app/theme/app_theme.dart`
- `Frontend/lib/core/presentation/design_system/acadex_colors.dart`
- `Frontend/lib/core/presentation/design_system/acadex_typography.dart`
- `Frontend/lib/core/presentation/design_system/acadex_spacing.dart`
- `Frontend/lib/core/presentation/design_system/acadex_breakpoints.dart`
- `Frontend/lib/core/presentation/widgets/acadex_page_container.dart`
- `Frontend/lib/core/presentation/widgets/acadex_page_header.dart`
- `Frontend/lib/core/presentation/widgets/acadex_card.dart`
- `Frontend/lib/features/auth/presentation/providers/auth_provider.dart`
- `Frontend/lib/features/auth/presentation/screens/login_screen.dart`
- `Frontend/lib/features/dashboard/presentation/screens/role_dashboard_screen.dart`
- `Frontend/lib/features/dashboard/presentation/screens/super_admin_dashboard.dart`
- `Frontend/lib/features/dashboard/presentation/screens/college_admin_dashboard.dart`
- `Frontend/lib/features/dashboard/presentation/screens/hod_dashboard.dart`
- `Frontend/lib/features/dashboard/presentation/screens/faculty_dashboard.dart`
- `Frontend/lib/features/dashboard/presentation/screens/student_dashboard.dart`
- `Frontend/lib/features/dashboard/presentation/widgets/acadex_app_bar.dart`
- `Frontend/lib/features/dashboard/presentation/widgets/acadex_bottom_nav.dart`
- `Frontend/lib/features/dashboard/presentation/widgets/acadex_drawer.dart`
- `Frontend/lib/features/analytics/presentation/screens/analytics_dashboard_screen.dart`
- `Frontend/lib/features/notes/presentation/screens/notes_dashboard_screen.dart`
- `Frontend/lib/features/profile/presentation/screens/profile_screen.dart`
- `Frontend/lib/features/attendance/presentation/screens/student_attendance_portal_screen.dart`
- `Frontend/lib/features/timetable/presentation/screens/timetable_dashboard_screen.dart`
- `Frontend/lib/features/assignments/presentation/screens/student_assignments_screen.dart`

#### Backend
- `Backend/src/index.ts`
- `Backend/src/app.ts`
- `Backend/src/routes/auth.routes.ts`
- `Backend/src/routes/academic.routes.ts`
- `Backend/src/routes/attendance.routes.ts`
- `Backend/src/routes/timetable.routes.ts`
- `Backend/src/routes/analytics.routes.ts`
- `Backend/src/controllers/auth.controller.ts`
- `Backend/src/controllers/attendance.controller.ts`
- `Backend/src/controllers/academic.controller.ts`
- `Backend/src/controllers/timetable.controller.ts`
- `Backend/src/controllers/analytics.controller.ts`
- `Backend/src/middleware/auth.middleware.ts`
- `Backend/src/middleware/tenant.middleware.ts`

---

### SECTION O: FILES MODIFIED IN THIS PROMPT

**Zero (0) production or test source code files modified.**  
In accordance with Section 14 negative constraints, this prompt was strictly dedicated to environment establishment, physical hardware verification, and factual baseline reporting.

*Only project documentation and `.gitignore` rule for binary evidence were touched:*
- `docs/runtime_qa/reports/BASELINE_REPORT_PROMPT01.md` (Created)
- `.gitignore` (Configured ignore rule for `docs/runtime_qa/**/*.png`)

---

### SECTION P: RUNTIME EVIDENCE LOCATIONS

All 41 physical runtime screenshots are cataloged and organized in:
`docs/runtime_qa/baseline/`

Key role and screen evidence files:
1. `01_launch_screen.png`: Launch & login interface
2. `02_super_admin_dashboard.png`: Super Admin multi-institution dashboard
3. `02_super_admin_drawer.png`: Super Admin drawer navigation
4. `03_college_admin_dashboard.png`: College Admin home dashboard
5. `03_college_admin_academics.png`: Academic structure management
6. `03_college_admin_people.png`: User directory
7. `03_college_admin_reports.png`: Reports screen (illustrating top-clipping defect)
8. `03_college_admin_more.png`: Settings navigation
9. `03_college_admin_profile_double_appbar.png`: Profile screen (illustrating double AppBar defect)
10. `04_hod_dashboard.png`: HOD department dashboard
11. `05_faculty_dashboard.png`: Faculty class schedule and attendance screen
12. `06_student_dashboard.png`: Student home dashboard
13. `06_student_attendance.png`: Student attendance breakdown portal
14. `06_student_timetable.png`: Student daily and weekly timetable
15. `06_student_notes.png`: Student notes repository (illustrating search bar clipping)
16. `06_student_assignments.png`: Student coursework assignment screen

Daemon Backend Logs:
- `.system_generated/tasks/task-241.log`

---

### SECTION Q: RECOMMENDED REPAIR ORDER (PROMPTS 02 THROUGH 12)

Based on our forensic runtime observations, the recommended execution plan for subsequent recovery prompts is:

1. **Prompt 02: Navigation Shell & Padding Contract Normalization**
   - Resolve `ShellWrapper` `extendBodyBehindAppBar` contract.
   - Enforce `AcadexPageContainer` across all primary and secondary routes.
   - Eliminate nested inner `Scaffold`/`AppBar` on `ProfileScreen` and detail views.
2. **Prompt 03: Drawer Lifecycle & Authentication Session Hardening**
   - Repair `BUG-P1-01` in `acadex_drawer.dart` by keeping context alive until confirmation dialog resolves.
   - Standardize sign-out flow across drawer, settings, and token-expiry interceptors.
3. **Prompt 04: Academic Structure & Department Management Verification**
   - Fix card horizontal alignment and hierarchy trees in Academic Structure.
   - Test section transfers and faculty assignments on physical runtime.
4. **Prompt 05: Attendance Smart Guard & Faculty/Student Portals**
   - Verify attendance lock rules, geo/smart guard validations, and percentage meters.
5. **Prompt 06: Timetable & Calendar Adaptive Layouts**
   - Implement dynamic column budgeting with `LayoutBuilder` for 434dp+ display viewports.
6. **Prompt 07: Assignments & Activity Screen Overhauls**
   - Fix nested TabBar and AppBar heights in Activity and submission views.
7. **Prompt 08: Notes & Resource Repository**
   - Re-anchor search bar below AppBar using `AcadexPageContainer` and repair filter chip scrolling.
8. **Prompt 09: Analytics & Reporting Dashboards**
   - Eliminate top clipping on metric filters and export buttons.
9. **Prompt 10: Profile & Tenant Settings**
   - Single clean AppBar architecture, avatar upload preview, and tenant info cards.
10. **Prompt 11: Cross-Breakpoint & Adaptive Tablet/Foldable Testing**
    - Verify responsiveness across compact, medium, and expanded viewports.
11. **Prompt 12: Regression Sign-Off & Legacy Test Suite Repair**
    - Update outdated widget test mocks and verify 100% pass across all unit and widget tests.

---

### FINAL STATUS
**`RUNTIME VERIFIED`**
