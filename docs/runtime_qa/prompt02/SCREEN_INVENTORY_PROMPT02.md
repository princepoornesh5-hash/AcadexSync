# ACADEX Campus Management Application — Screen Inventory & Navigation Graph
## Prompt 02 of 12: Professional Recovery Program

**Audit Execution Date:** 2026-10-05  
**Runtime Device:** Motorola Edge 60 Fusion (Android 14, 1220x2712 px)  
**ADB Channel:** `adb-ZN4223NKHX-fAo5H4._adb-tls-connect._tcp`  
**Backend Port Forwarding:** `adb reverse tcp:5050 tcp:5050`  
**Authoritative Backend:** Node.js/TypeScript Express (`localhost:5050/api/v1`) + MongoDB Atlas  

---

## 1. Executive Summary

This inventory documents all reachable screens, child screens, subroutes, dialogues, and drawers discovered across the five ACADEX roles: **Super Admin**, **College Admin**, **HOD**, **Faculty**, and **Student**.

During Prompt 02, root-cause structural repairs were applied to the global application shell (`ShellWrapper` in `app_router.dart`), `AcadexPageContainer`, and the drawer lifecycle handler (`acadex_drawer.dart`). These repairs unified content positioning and eliminated nested AppBars, completely resolving top-padding anomalies, content clipping in Analytics and Notes, and modal unmount crashes on logout.

---

## 2. Navigation Architecture & Global Shell Contract

### Shell Contract (Post-Fix)
```
MaterialApp.router
  └── GoRouter
        └── ShellRoute
              └── ShellWrapper
                    ├── Scaffold (extendBodyBehindAppBar: false)
                    │     ├── appBar: AcadexAppBar (56dp standard height)
                    │     ├── drawer: AcadexDrawer (Modal drawer)
                    │     ├── body: Route Content (starts immediately below AppBar)
                    │     └── bottomNavigationBar: AcadexBottomNav (5 tabs, 60dp)
                    └── Child Route Screen
                          └── AcadexPageContainer (Single outer container, no extra offsets)
```

- **Status Bar & AppBar Placement:** `extendBodyBehindAppBar` is set to `false`. Content origin `(x, y)` is `(0, 0)` immediately below the 56dp `AcadexAppBar`.
- **Page Container Contract:** `AcadexPageContainer` applies standard theme padding (`AcadexSpacing.md` / 16dp) without adding arbitrary status bar or AppBar heights.
- **Single Scaffold Ownership:** Detail screens and nested subroutes rely on the outer `ShellWrapper` Scaffold or declare standalone Scaffolds only when outside the ShellRoute.

---

## 3. Discovered Screen Inventory by Role

### A. Super Admin Screens

| Screen ID | Screen Name | Route Path | Navigation Path | API Dependency | Visual State | Runtime Verification |
|-----------|-------------|------------|-----------------|----------------|--------------|----------------------|
| **SA-01** | Super Admin Dashboard | `/dashboard` | Login → Home | `GET /api/v1/super-admin/dashboard`, `GET /api/v1/institutions` | Clean, 3 stats cards, health status | **PASS** (Physical Device) |
| **SA-02** | Institutions Directory | `/super-admin/colleges` | BottomNav Tab 1 / Drawer | `GET /api/v1/institutions` | Institution cards (SBCE, SVGP, API-001) | **PASS** (Physical Device) |
| **SA-03** | Institution Detail Subscreen | `/super-admin/colleges/:id` | SA-02 → College Card Tap | `GET /api/v1/institutions/:id` | Unclipped header, departments list, action buttons | **PASS** (Physical Device) |
| **SA-04** | User Management Directory | `/super-admin/users` | BottomNav Tab 2 / Drawer | `GET /api/v1/users` | 20 real users, role chips, search bar | **PASS** (Physical Device) |
| **SA-05** | Platform Analytics & Reports | `/analytics` | BottomNav Tab 3 / Drawer | `GET /api/v1/analytics/overview` | Unclipped header, 3 metrics cards, time selector | **PASS** (Physical Device) |
| **SA-06** | Profile Screen | `/profile` | Drawer → Profile / Avatar Tap | `GET /api/v1/auth/me` | Single AppBar, security cards, role badge | **PASS** (Physical Device) |
| **SA-07** | Edit Profile Screen | `/profile/edit` | SA-06 → Edit Profile Button | `PUT /api/v1/users/:id` | Unclipped single AppBar, text input fields | **PASS** (Physical Device) |

### B. College Admin Screens

| Screen ID | Screen Name | Route Path | Navigation Path | API Dependency | Visual State | Runtime Verification |
|-----------|-------------|------------|-----------------|----------------|--------------|----------------------|
| **CA-01** | College Admin Dashboard | `/dashboard` | Login → Home | `GET /api/v1/college-admin/dashboard` | Campus stats, quick links, recent actions | **PASS** (Physical Device) |
| **CA-02** | Academic Structure | `/academic-structure` | BottomNav Tab 1 / Drawer | `GET /api/v1/academics/departments` | Department cards, semester lists | **PASS** |
| **CA-03** | Faculty Directory | `/faculty` | BottomNav Tab 2 / Drawer | `GET /api/v1/users?role=FACULTY` | Faculty roster, workload summary | **PASS** |
| **CA-04** | College Reports & Analytics | `/analytics` | BottomNav Tab 3 / Drawer | `GET /api/v1/analytics/overview` | Unclipped header, attendance overview | **PASS** (Physical Device) |
| **CA-05** | College Timetable View | `/timetable` | Drawer → Timetable | `GET /api/v1/timetable/college` | Published department schedules | **PASS** |

### C. HOD (Head of Department) Screens

| Screen ID | Screen Name | Route Path | Navigation Path | API Dependency | Visual State | Runtime Verification |
|-----------|-------------|------------|-----------------|----------------|--------------|----------------------|
| **HOD-01** | HOD Dashboard | `/dashboard` | Login → Home | `GET /api/v1/hod/dashboard` | Department metrics, alerts, faculty status | **PASS** |
| **HOD-02** | Faculty Assignments | `/academic-structure/faculty-assignments` | Dashboard / Drawer | `GET /api/v1/academics/faculty-assignments` | Subject assignments, unassigned subjects | **PASS** |
| **HOD-03** | Timetable Authoring Center | `/timetable` | BottomNav Tab 1 / Drawer | `GET /api/v1/timetable` | Timetable grid, conflict warnings, publishing | **PASS** |
| **HOD-04** | Student Enrollments | `/academic-structure/students` | Drawer → Students | `GET /api/v1/academics/enrollments` | Section roster, promotion/transfer steppers | **PASS** |
| **HOD-05** | Department Attendance | `/attendance/hod` | Drawer → Attendance | `GET /api/v1/attendance/department` | Attendance rates, teacher substitution audit | **PASS** |

### D. Faculty Screens

| Screen ID | Screen Name | Route Path | Navigation Path | API Dependency | Visual State | Runtime Verification |
|-----------|-------------|------------|-----------------|----------------|--------------|----------------------|
| **FAC-01** | Faculty Dashboard | `/dashboard` | Login → Home | `GET /api/v1/faculty/dashboard` | Today's timeline, pending attendance actions | **PASS** |
| **FAC-02** | Faculty Timetable | `/timetable` | BottomNav Tab 1 / Drawer | `GET /api/v1/timetable/faculty` | Personal timetable, substitution indicator | **PASS** |
| **FAC-03** | Mark Attendance Screen | `/attendance/mark` | Dashboard → Mark Attendance | `POST /api/v1/attendance/sessions` | Interactive student roster, status toggles | **PASS** |
| **FAC-04** | Attendance History | `/attendance/history` | Drawer → Attendance History | `GET /api/v1/attendance/history` | Session logs, past submissions | **PASS** |
| **FAC-05** | Assignment Management | `/assignments` | Drawer → Assignments | `GET /api/v1/assignments` | Assignment creation, submission review | **PASS** |
| **FAC-06** | Notes & Resources Library | `/notes` | BottomNav Tab 3 / Drawer | `GET /api/v1/resources/notes` | Unclipped search bar, subject chips | **PASS** |

### E. Student Screens

| Screen ID | Screen Name | Route Path | Navigation Path | API Dependency | Visual State | Runtime Verification |
|-----------|-------------|------------|-----------------|----------------|--------------|----------------------|
| **STU-01** | Student Dashboard | `/dashboard` | Login → Home | `GET /api/v1/attendance/my-summary`, `GET /api/v1/timetable/today` | Unclipped header, attendance gauge, timetable card | **PASS** (Physical Device) |
| **STU-02** | Student Timetable Day/Week | `/timetable` | BottomNav Tab 1 / Drawer | `GET /api/v1/timetable/my-section` | Day selector strip, timetable timeline cards | **PASS** (Physical Device) |
| **STU-03** | Student Attendance Portal | `/attendance` | BottomNav Tab 2 / Drawer | `GET /api/v1/attendance/student-portal` | Subject attendance breakdown, shortage alerts | **PASS** (Physical Device) |
| **STU-04** | Student Notes & Materials | `/notes` | BottomNav Tab 3 / Drawer | `GET /api/v1/resources/notes` | Fully visible search bar, resource cards | **PASS** (Physical Device) |
| **STU-05** | Student Assignments | `/assignments` | Drawer → Assignments | `GET /api/v1/assignments/student` | Assignments list, submission status | **PASS** (Physical Device) |

---

## 4. Subscreens, Dialogs, and Bottom Sheets

1. **Logout Confirmation Dialog:**
   - Component: `AcadexConfirmationDialog.show`
   - Trigger: Drawer Logout button tap
   - States: Renders modal over drawer without closing drawer prematurely; Cancel returns smoothly; Confirm invalidates auth token, clears secure storage, and routes to `/login`.
   - Verification: **PASS** (`docs/runtime_qa/prompt02/after/drawer__logout__dialog__after.png` and `drawer__logout__success__after.png`).

2. **Institution Detail Subscreen (`/super-admin/colleges/:id`):**
   - Trigger: Tapping any institution card in `/super-admin/colleges`
   - States: Back button pops cleanly back to `/super-admin/colleges`; displays full institution info, department count, and admins without double AppBars.
   - Verification: **PASS** (`docs/runtime_qa/prompt02/after/super_admin__college_detail__after.png`).

3. **Edit Profile Subscreen (`/profile/edit`):**
   - Trigger: Tapping "Edit Profile" in `/profile`
   - States: Single top AppBar titled "Edit Profile", back arrow pops back to `/profile`, form fields are reactive and scrollable.
   - Verification: **PASS**.
