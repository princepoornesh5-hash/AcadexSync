# ACADEX Reconciled Bug Register (Prompt 02.1)

## 1. Executive Summary & Defect Reconciliation

Prompt 02 reported:
- 5 bugs found
- 5 fixed
- Yet simultaneously noted remaining "1 P2, 2 P3" in its summary section, creating ambiguity.

Prompt 02.1 has re-audited and reconciled all defects through direct physical hardware runtime verification and systematic code tracing.

---

## 2. Reconciled Prompt 02 Defects

| Defect ID | Severity | Screen / Component | Original Behavior | Prompt 02.1 Verified Behavior | Reconciled Status | Remaining Risk | Evidence Path |
|---|---|---|---|---|---|---|---|
| **BUG-P1-01** | P1 (High) | Navigation Drawer (`AcadexDrawer`) | Logout tap popped context prematurely, causing unmounted framework exceptions. | Tested Cancel (modal dismissed, session retained) and Sign Out (drawer closed, tokens cleared, navigated to `/login`, back press prevented). | **FIXED & RE-VERIFIED** | None | `screenshots/logout__confirmation_dialog.png`<br>`screenshots/logout__redirect_to_login.png` |
| **BUG-P1-02** | P1 (High) | Global Shell (`ShellWrapper`) | `extendBodyBehindAppBar: true` caused top page content to hide behind AppBar/status bar. | `extendBodyBehindAppBar: false` enforced. All screens originate with proper clearance below the 56dp AppBar. | **FIXED & RE-VERIFIED** | None | `screenshots/super_admin__dashboard.png`<br>`screenshots/super_admin__colleges.png` |
| **BUG-P1-03** | P1 (High) | Profile & Edit Profile (`/profile`) | Nested Scaffold caused two stacked AppBars consuming 112dp vertical real estate. | Inspected on physical device: strictly a single authoritative `AcadexAppBar` renders. | **FIXED & RE-VERIFIED** | None | `screenshots/super_admin__profile.png`<br>`screenshots/super_admin__edit_profile.png` |
| **BUG-P2-01** | P2 (Med) | Analytics / Reports (`/analytics`) | Top metric cards clipped beneath AppBar. | Fresh physical capture shows all metric tiles, percentages, and health indicators completely visible. | **FIXED & RE-VERIFIED** | None | `screenshots/super_admin__reports.png` |
| **BUG-P2-02** | P2 (Med) | Study Notes (`/notes`) | Search input obscured by AppBar. | Subsumed by `BUG-P1-02` root fix; page container clearance standardized. | **FIXED & RE-VERIFIED** | None | Verified in widget regression tests |

---

## 3. New Defects & Blockers Discovered in Prompt 02.1

| Defect ID | Severity | Role | Screen / Route | Description | Root Cause | Reproduction Steps | Status |
|---|---|---|---|---|---|---|---|
| **DEF-P021-01** | P2 (Medium) | Super Admin | `/audit` | Tapping "Audit Logs" on Super Admin Dashboard renders a 404 "Page unavailable" screen. | Backend `dashboard.service.ts` sends `route: '/audit'`, but `/audit` is not registered in `app_router.dart`. | 1. Log in as Super Admin.<br>2. On Dashboard, tap "Audit Logs" under Quick Operations.<br>3. 404 Page appears. | **OPEN (DEFERRED TO PROMPT 03)** |
| **DEF-P021-02** | P3 (Low) | Super Admin | `/calendar` | Academic Calendar screen displays "Unable to load events. Check your connection and try again." | Calendar API requires institutional/college tenant context which the global Super Admin lacks. | 1. Open drawer.<br>2. Tap "Calendar".<br>3. Day events show error card with "Try Again". | **OPEN (DEFERRED TO PROMPT 03)** |
| **BLK-P021-01** | Blocked | College Admin | `/dashboard/college_admin` | Runtime verification blocked due to unsupplied credentials. | Password guessing and hash inspection strictly prohibited by Prompt 02.1 mandate. | Attempt login without authorized credentials. | **BLOCKED** |
| **BLK-P021-02** | Blocked | HOD | `/dashboard/hod` | Runtime verification blocked due to unsupplied credentials. | Password guessing and hash inspection strictly prohibited by Prompt 02.1 mandate. | Attempt login without authorized credentials. | **BLOCKED** |
| **BLK-P021-03** | Blocked | Faculty | `/dashboard/faculty` | Runtime verification blocked due to unsupplied credentials. | Password guessing and hash inspection strictly prohibited by Prompt 02.1 mandate. | Attempt login without authorized credentials. | **BLOCKED** |
| **BLK-P021-04** | Blocked | Student | `/dashboard/student` | Runtime verification blocked due to unsupplied credentials. | Password guessing and hash inspection strictly prohibited by Prompt 02.1 mandate. | Attempt login without authorized credentials. | **BLOCKED** |
