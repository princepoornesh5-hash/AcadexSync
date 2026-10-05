# ACADEX Canonical Runtime Screen Coverage Matrix (Prompt 02.1)

## Summary of Screen Inventory Reconciliation

Prompt 02 reported:
- 17 unique screens discovered
- 6 child/subscreens discovered
- Claimed "RUNTIME VERIFIED WITH REMAINING DEFECTS"

Prompt 02.1 audit findings:
- Prompt 02 contained **invalid duplicate screenshots** (e.g. `super_admin__reports` and `college_admin__reports` were identical; `student__assignments` and `student__timetable__day` were identical).
- Only Super Admin credentials (`princepoornesh5@gmail.com`) are supplied in the authorized context. In strict compliance with Prompt 02.1 authentication security rules (prohibiting password guessing, password derivation, database hash checks, and pilot substitution), the other 4 roles (`College Admin`, `HOD`, `Faculty`, `Student`) are truthfully classified as **BLOCKED**.
- Every reachable screen and child/subscreen for Super Admin was genuinely exercised on real hardware (`motorola edge 60 fusion`, Android 16 / SDK 36), resulting in 13 fresh, authentic screenshot captures and verified interaction flows.

---

## Canonical Screen Coverage Matrix

| Role | Parent Screen | Screen Name | Route | Child/ Subscreen? | How Discovered | Runtime Tested? | Fresh Screenshot? | API Tested? | Result | Evidence Path | Defect ID | Notes |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| **Super Admin** | Root | Super Admin Dashboard | `/dashboard/super_admin` | No | Primary route after login | Yes | Yes | Yes | **PASS** | `screenshots/super_admin__dashboard.png` | - | Verified live metrics: 3 colleges, 20 users, operational status. |
| **Super Admin** | Dashboard | Colleges Directory | `/academics/colleges` | No | Bottom Nav Tab 2 & Dashboard Quick Op | Yes | Yes | Yes | **PASS** | `screenshots/super_admin__colleges.png` | - | Displays active institutions (API-001, SBCE, SVGP) with search and filters. |
| **Super Admin** | Colleges | College Detail (Institution Overview) | `/academics/colleges/:id` | **Yes** | Tap College Card on Colleges screen | Yes | Yes | Yes | **PASS** | `screenshots/super_admin__college_detail.png` | - | Verified child screen. Stats grid, campus info, admin roster. |
| **Super Admin** | Dashboard | Users Directory | `/users` | No | Bottom Nav Tab 3 & Drawer Menu Item | Yes | Yes | Yes | **PASS** | `screenshots/super_admin__users.png` | - | Displays 20 user records, role filter chips, status/department dropdowns. |
| **Super Admin** | Dashboard | Campus Analytics & Reports | `/analytics` | No | Bottom Nav Tab 4 & Drawer Menu Item | Yes | Yes | Yes | **PASS** | `screenshots/super_admin__reports.png` | - | Fresh physical hardware capture replacing Prompt 02 duplicate. |
| **Super Admin** | Drawer Menu | User Profile Screen | `/profile` | No | Drawer Profile link / user card tap | Yes | Yes | Yes | **PASS** | `screenshots/super_admin__profile.png` | - | Verified single AppBar fix on hardware; no nested AppBar exists. |
| **Super Admin** | Profile | Edit Profile Screen | `/profile/edit` | **Yes** | Tap Edit button on Profile screen | Yes | Yes | Yes | **PASS** | `screenshots/super_admin__edit_profile.png` | - | Verified child screen. Form inputs, locked institutional fields, Cancel/Save. |
| **Super Admin** | Drawer Menu | Platform Settings | `/settings` | No | Drawer Settings link & Dashboard Quick Op | Yes | Yes | Yes | **PASS** | `screenshots/super_admin__settings.png` | - | Complete settings: Academic Config, Profile, Password, Theme, Security. |
| **Super Admin** | Drawer Menu | Academic Calendar | `/calendar` | No | Drawer Academics section | Yes | Yes | Yes | **PASS** | `screenshots/super_admin__calendar.png` | - | Interactive calendar grid with date selection, event categories, Add Event FAB. |
| **Super Admin** | Drawer Menu | AI Assistant | `/ai-assistant` | No | Drawer System section | Yes | Yes | Yes | **PASS** | `screenshots/super_admin__ai_assistant.png` | - | Conversational interface with suggestion cards and message input. |
| **Super Admin** | AppBar | Notification Center | `/notifications` | No | Bell icon on AppBar | Yes | Yes | Yes | **PASS** | `screenshots/super_admin__notifications.png` | - | Notification center with empty state card, mark all as read, category chips. |
| **Super Admin** | Dashboard | Audit Logs Route | `/audit` | No | Dashboard Quick Operations -> Audit Logs | Yes | Yes | No | **FAIL** | `screenshots/super_admin__audit_logs.png` | `DEF-P021-01` | Quick action links to `/audit` which is not registered in router; renders 404 page. |
| **Super Admin** | Drawer Menu | Logout Confirmation Modal | Dialog | **Yes** | Drawer Logout button tap | Yes | Yes | Yes | **PASS** | `screenshots/logout__confirmation_dialog.png` | - | Tested Cancel (remains authenticated) and Sign Out (clears session and redirects). |
| **Unauthenticated** | Root | Login Screen | `/login` | No | App boot / post-logout redirect | Yes | Yes | Yes | **PASS** | `screenshots/logout__redirect_to_login.png` | - | Back-press tested; correctly prevents re-entry into protected shell. |
| **College Admin** | Root | College Admin Dashboard | `/dashboard/college_admin` | No | Router role mapping | No | No | No | **BLOCKED** | None | `BLK-P021-01` | Exact credentials for `sbce-001` not supplied. Password guessing prohibited. |
| **HOD** | Root | HOD Dashboard | `/dashboard/hod` | No | Router role mapping | No | No | No | **BLOCKED** | None | `BLK-P021-02` | Exact credentials for `Sbce-cs-001` not supplied. Password guessing prohibited. |
| **Faculty** | Root | Faculty Dashboard | `/dashboard/faculty` | No | Router role mapping | No | No | No | **BLOCKED** | None | `BLK-P021-03` | Exact credentials for `sbce-cs-002` not supplied. Password guessing prohibited. |
| **Student** | Root | Student Dashboard | `/dashboard/student` | No | Router role mapping | No | No | No | **BLOCKED** | None | `BLK-P021-04` | Exact credentials for `24018-cm-001` not supplied. Password guessing prohibited. |

---

## Metric Breakdown

- **Total Discovered Screens in Inventory**: 18
- **Runtime Verified (PASS)**: 13
- **Runtime Tested with Failure (FAIL)**: 1 (`/audit` unmapped route -> 404 page)
- **Blocked Due to Unsupplied Authorized Credentials (BLOCKED)**: 4 (`College Admin`, `HOD`, `Faculty`, `Student`)
- **Unreachable Screens**: 0
