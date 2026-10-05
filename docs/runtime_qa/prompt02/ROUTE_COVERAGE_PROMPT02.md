# ACADEX Route Coverage Matrix — Prompt 02 of 12

**Device:** Motorola Edge 60 Fusion (Android 14)  
**ADB Target:** `adb-ZN4223NKHX-fAo5H4._adb-tls-connect._tcp`  
**Execution Timestamp:** 2026-10-05T01:31:00Z  

## Authoritative Coverage Matrix

| Role | Menu | Screen | Child Screen | Interaction | API | Auth | Before | Fix | After | Status |
|---|---|---|---|---|---|---|---|---|---|---|
| **SUPER_ADMIN** | Home | Dashboard (`/dashboard`) | None | Card tap, Drawer toggle | `GET /api/v1/super-admin/dashboard` | Super Admin JWT | Content pushed up / overlap | `extendBodyBehindAppBar: false` in `ShellWrapper` | `super_admin__dashboard__after.png` | **PASS** |
| **SUPER_ADMIN** | BottomNav Tab 1 | Colleges (`/super-admin/colleges`) | Institution Detail (`/super-admin/colleges/:id`) | College Card Tap | `GET /api/v1/institutions` | Super Admin JWT | Standard list | Unified PageContainer | `super_admin__colleges__after.png` | **PASS** |
| **SUPER_ADMIN** | Subscreen | Institution Detail (`/super-admin/colleges/:id`) | None | Back button, Manage tabs | `GET /api/v1/institutions/:id` | Super Admin JWT | Nested header clutter | Shell header mapping | `super_admin__college_detail__after.png` | **PASS** |
| **SUPER_ADMIN** | BottomNav Tab 2 | Users Directory (`/super-admin/users`) | None | Search, Role filter | `GET /api/v1/users` | Super Admin JWT | Search bar partially clipped | Shell contract unified | `super_admin__users__after.png` | **PASS** |
| **SUPER_ADMIN** | BottomNav Tab 3 | Analytics / Reports (`/analytics`) | None | Time selector pills (7D, 30D) | `GET /api/v1/analytics/overview` | Super Admin JWT | Header & top metrics clipped under AppBar (`college_admin__reports__clipped__before.png`) | Unified shell positioning | `super_admin__reports__after.png` | **PASS** |
| **COLLEGE_ADMIN** | Home | Dashboard (`/dashboard`) | None | Quick cards | `GET /api/v1/college-admin/dashboard` | College Admin JWT | Shell margin gap | Shell contract unified | `college_admin__dashboard__after.png` | **PASS** |
| **COLLEGE_ADMIN** | BottomNav Tab 3 | Reports (`/analytics`) | None | Metric cards tap | `GET /api/v1/analytics/overview` | College Admin JWT | Clipped under AppBar (`college_admin__reports__clipped__before.png`) | `extendBodyBehindAppBar: false` | `college_admin__reports__after.png` | **PASS** |
| **STUDENT** | Home | Dashboard (`/dashboard`) | None | Attendance card tap, Timeline | `GET /api/v1/attendance/my-summary` | Student JWT | Top padding offset | Standardized `effectiveTop` | `student__dashboard__after.png` | **PASS** |
| **STUDENT** | BottomNav Tab 1 | Timetable (`/timetable`) | None | Day strip selector | `GET /api/v1/timetable/my-section` | Student JWT | Offset anomaly | PageContainer standardized | `student__timetable__day__after.png` | **PASS** |
| **STUDENT** | BottomNav Tab 2 | Attendance (`/attendance`) | None | Subject card expansion | `GET /api/v1/attendance/student-portal` | Student JWT | Spacing irregularity | Unified padding contract | `student__attendance__dashboard__after.png` | **PASS** |
| **STUDENT** | BottomNav Tab 3 | Notes (`/notes`) | None | Search input, Category chips | `GET /api/v1/resources/notes` | Student JWT | Search bar clipped behind AppBar (`student__notes__clipped__before.png`) | Global shell fix | `student__notes__after.png` | **PASS** |
| **STUDENT** | Drawer | Assignments (`/assignments`) | None | Card tap, Filter | `GET /api/v1/assignments/student` | Student JWT | Standard list | Shell contract unified | `student__assignments__after.png` | **PASS** |
| **ALL** | Drawer | Profile (`/profile`) | Edit Profile (`/profile/edit`) | Edit Profile button | `GET /api/v1/auth/me` | Authenticated JWT | Double AppBars (`college_admin__profile__double_appbar__before.png`) | Removed inner Scaffold/AppBar | `profile__after.png` | **PASS** |
| **ALL** | Subscreen | Edit Profile (`/profile/edit`) | None | Form input, Save button, Back arrow | `PUT /api/v1/users/:id` | Authenticated JWT | Double AppBars | Removed inner Scaffold/AppBar | Single AppBar verified | **PASS** |
| **ALL** | Drawer | Drawer Logout Flow | Modal Dialog (`AcadexConfirmationDialog`) | Logout tap → Cancel / Confirm | `POST /api/v1/auth/logout` | Token Invalidation | Unmounted context crash (`drawer__logout__unmount_bug__before.png`) | Reordered modal await before drawer dismiss in `acadex_drawer.dart` | `drawer__logout__dialog__after.png` & `drawer__logout__success__after.png` | **PASS** |
