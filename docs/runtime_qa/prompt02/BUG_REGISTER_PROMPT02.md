# ACADEX Bug Register — Prompt 02 of 12

**Audit Session:** Prompt 02 Recursive Runtime Stabilization  
**Device:** Motorola Edge 60 Fusion (Android 14)  
**Total Bugs Addressed:** 5  
**Total Bugs Fixed & Runtime Verified:** 5  

---

### Bug Record: BUG-P1-01

- **ID:** `BUG-P1-01`
- **Severity:** P1 (High)
- **Role:** All Roles (Super Admin, College Admin, HOD, Faculty, Student)
- **Screen:** Navigation Drawer (`AcadexDrawer`)
- **Reproduction:** 
  1. Open app drawer from top-left hamburger icon.
  2. Tap "Logout" at bottom of drawer list.
  3. Modal confirmation appears.
  4. Attempting to confirm or cancel resulted in unmounted context crash because `Navigator.of(context).pop()` was called prematurely before the dialog resolved.
- **Expected:** Drawer remains stable; confirmation dialog renders over drawer; upon user clicking "Logout", drawer closes, auth state clears, and app cleanly navigates to `/login`.
- **Actual:** Premature drawer pop invalidated `BuildContext`, aborting the logout redirect and throwing unmounted Flutter framework exceptions.
- **Root Cause:** In `Frontend/lib/features/dashboard/presentation/widgets/acadex_drawer.dart`, `Navigator.of(context).pop()` was invoked synchronously *before* awaiting `AcadexConfirmationDialog.show`.
- **Frontend/Backend/Both:** Frontend
- **Fix:** Re-ordered dialog execution. `await AcadexConfirmationDialog.show` is called first while the context is valid. If user confirms, the drawer is popped and `ref.read(authProvider.notifier).logout()` executes cleanly.
- **Files Changed:** `Frontend/lib/features/dashboard/presentation/widgets/acadex_drawer.dart`
- **Test:** Manual physical device test & widget test in `test/prompt2_mobile_shell_navigation_dashboard_test.dart`
- **Before Evidence:** `docs/runtime_qa/prompt02/before/drawer__logout__unmount_bug__before.png`
- **After Evidence:** `docs/runtime_qa/prompt02/after/drawer__logout__dialog__after.png`, `docs/runtime_qa/prompt02/after/drawer__logout__success__after.png`
- **Regression Result:** Zero unmounted context exceptions in logcat; logout cleanly drops to `/login`.
- **Status:** **FIXED & RUNTIME VERIFIED**

---

### Bug Record: BUG-P1-02

- **ID:** `BUG-P1-02`
- **Severity:** P1 (High)
- **Role:** All Roles
- **Screen:** Global Shell (`ShellWrapper`) & All Child Routes
- **Reproduction:** 
  1. Launch app on physical device.
  2. Navigate to `/analytics`, `/notes`, or any screen using default page container without manual padding compensation.
  3. Header elements, search inputs, and metric tiles render behind the `AcadexAppBar`.
- **Expected:** All route body content should originate cleanly below the 56dp `AcadexAppBar`.
- **Actual:** Content began at Y=0 (behind status bar and AppBar). Screens without artificial padding suffered top clipping.
- **Root Cause:** In `Frontend/lib/app/router/app_router.dart` line 273, `ShellWrapper` Scaffold was declared with `extendBodyBehindAppBar: true`. Simultaneously, `AcadexPageContainer` was adding ad-hoc `kAppBarHeight` and `mediaTop` offsets to compensate, creating inconsistent positioning across screens.
- **Frontend/Backend/Both:** Frontend
- **Fix:** Set `extendBodyBehindAppBar: false` in `ShellWrapper`. In `Frontend/lib/core/presentation/widgets/acadex_page_container.dart`, removed `kAppBarHeight` and `kBottomNavHeight` manual offsets, setting `effectiveTop = baseTop`.
- **Files Changed:** 
  - `Frontend/lib/app/router/app_router.dart`
  - `Frontend/lib/core/presentation/widgets/acadex_page_container.dart`
- **Test:** `flutter analyze`, `test/prompt2_mobile_shell_navigation_dashboard_test.dart`, physical device inspection on 1220x2712 viewport.
- **Before Evidence:** `docs/runtime_qa/prompt02/before/college_admin__reports__clipped__before.png`, `docs/runtime_qa/prompt02/before/student__notes__clipped__before.png`
- **After Evidence:** `docs/runtime_qa/prompt02/after/super_admin__reports__after.png`, `docs/runtime_qa/prompt02/after/student__notes__after.png`
- **Regression Result:** Zero clipping across 12 screens tested.
- **Status:** **FIXED & RUNTIME VERIFIED**

---

### Bug Record: BUG-P1-03

- **ID:** `BUG-P1-03`
- **Severity:** P1 (High)
- **Role:** All Roles
- **Screen:** Profile Screen (`/profile`) and Edit Profile Screen (`/profile/edit`)
- **Reproduction:** 
  1. Open Profile from drawer.
  2. Observe two stacked AppBars on screen (outer `AcadexAppBar` + inner `AppBar`).
  3. Tap "Edit Profile" → double stacked AppBars again.
- **Expected:** Single authoritative AppBar provided by the app shell.
- **Actual:** Double AppBars consuming excessive vertical screen real estate (~112dp) and distorting layout.
- **Root Cause:** `ProfileScreen` and `EditProfileScreen` each instantiated an inner `Scaffold` with its own `AppBar`, nested inside `ShellWrapper`'s outer `Scaffold`.
- **Frontend/Backend/Both:** Frontend
- **Fix:** Removed nested `Scaffold` and `AppBar` from both `profile_screen.dart` and `edit_profile_screen.dart`. Added title mapping `'Edit Profile'` in `app_router.dart` and assigned `activeRoute: '/profile/edit'`.
- **Files Changed:**
  - `Frontend/lib/features/profile/presentation/screens/profile_screen.dart`
  - `Frontend/lib/features/profile/presentation/screens/edit_profile_screen.dart`
  - `Frontend/lib/app/router/app_router.dart`
- **Test:** Widget test `route_lifecycle_inherited_widget_stability_test.dart`, physical device inspection.
- **Before Evidence:** `docs/runtime_qa/prompt02/before/college_admin__profile__double_appbar__before.png`
- **After Evidence:** Verified single AppBar on real device.
- **Regression Result:** Single unified AppBar across all profile workflows.
- **Status:** **FIXED & RUNTIME VERIFIED**

---

### Bug Record: BUG-P2-01

- **ID:** `BUG-P2-01`
- **Severity:** P2 (Medium)
- **Role:** Super Admin, College Admin
- **Screen:** Analytics / Reports (`/analytics`)
- **Reproduction:** Navigate to Reports tab. Title text and top metric cards ("Total Students", "Attendance Rate") clipped beneath the AppBar.
- **Expected:** Entire analytics view visible with proper spacing below the top AppBar.
- **Actual:** Top 40-50dp of the page was hidden under the transparent/solid AppBar.
- **Root Cause:** Consequence of `BUG-P1-02` (`extendBodyBehindAppBar: true`).
- **Frontend/Backend/Both:** Frontend
- **Fix:** Fixed at root cause via shell contract unification (`extendBodyBehindAppBar: false`).
- **Files Changed:** `Frontend/lib/app/router/app_router.dart`
- **Test:** Physical device verification on Super Admin and College Admin roles.
- **Before Evidence:** `docs/runtime_qa/prompt02/before/college_admin__reports__clipped__before.png`
- **After Evidence:** `docs/runtime_qa/prompt02/after/super_admin__reports__after.png` and `college_admin__reports__after.png`
- **Regression Result:** All metric cards, charts, and date filters fully legible.
- **Status:** **FIXED & RUNTIME VERIFIED**

---

### Bug Record: BUG-P2-02

- **ID:** `BUG-P2-02`
- **Severity:** P2 (Medium)
- **Role:** Student, Faculty
- **Screen:** Study Notes & Materials (`/notes`)
- **Reproduction:** Navigate to Notes tab. Top search bar input field cut off horizontally by the AppBar.
- **Expected:** Search bar fully visible with comfortable touch target.
- **Actual:** Top half of search input field obscured behind AppBar.
- **Root Cause:** Consequence of `BUG-P1-02` (`extendBodyBehindAppBar: true`).
- **Frontend/Backend/Both:** Frontend
- **Fix:** Fixed at root cause via shell contract unification.
- **Files Changed:** `Frontend/lib/app/router/app_router.dart`
- **Test:** Physical device interaction with search field on Student role.
- **Before Evidence:** `docs/runtime_qa/prompt02/before/student__notes__clipped__before.png`
- **After Evidence:** `docs/runtime_qa/prompt02/after/student__notes__after.png`
- **Regression Result:** Search bar clearly visible, focusable, and reactive to touch input.
- **Status:** **FIXED & RUNTIME VERIFIED**
