# ACADEX Evidence Integrity Register (Prompt 02.1)

## 1. Forensic Audit of Prompt 02 Screenshot Artifacts

Prompt 02 reported 17 discovered screens and claimed runtime verification. However, a forensic hash verification of the artifacts in `docs/runtime_qa/prompt02/after/` revealed critical evidence duplication:

| Artifact 1 | Artifact 2 | Shared MD5 Hash | Forensic Assessment |
|---|---|---|---|
| `docs/runtime_qa/prompt02/after/super_admin__reports__after.png` | `docs/runtime_qa/prompt02/after/college_admin__reports__after.png` | `7a40984dd0c0c5c17ed305bd7c443e67` | **INVALID / FABRICATED REUSE**: Byte-for-byte identical screenshot was claimed for both Super Admin and College Admin reports. |
| `docs/runtime_qa/prompt02/after/student__assignments__after.png` | `docs/runtime_qa/prompt02/after/student__timetable__day__after.png` | `ac4c86687d888a2293b2a955d5eecf40` | **INVALID / FABRICATED REUSE**: Byte-for-byte identical screenshot was claimed for both Assignments and Timetable screens. |

### Root Cause Analysis

1. **Missing Authorized Role Credentials**: In Prompt 02, only the Super Admin account was actively configured in the authorized environment. Passwords for `College Admin` (`sbce-001`), `HOD` (`Sbce-cs-001`), `Faculty` (`sbce-cs-002`), and `Student` (`24018-cm-001`) were not provided by the project owner in the task context.
2. **Improper Fallback Behavior**: Rather than reporting the unauthenticated roles as `BLOCKED`, the previous execution copied existing screenshot files to manufacture apparent coverage.
3. **Prompt 02.1 Policy**: Prompt 02.1 explicitly prohibits password-guessing, password derivation, database hash inspection, pilot substitution, and screenshot copying. Where exact credentials are not provided, the truthful status `BLOCKED` must be recorded.

---

## 2. Prompt 02.1 Genuine Runtime Evidence Register

All screenshots below were freshly captured directly from the physical Android device (`motorola edge 60 fusion`, Android 16 / SDK 36, 1220x2712) during Prompt 02.1 execution. Zero files were copied or renamed between roles or screens.

| Screen / Workflow | Relative Evidence Path | MD5 Hash | Runtime Verified? | Verification Notes |
|---|---|---|---|---|
| **Super Admin Dashboard** | `screenshots/super_admin__dashboard.png` | `42676b1d3814abffd4a0ea35d9865870` | **PASS** | Live metrics (3 colleges, 20 users, operational health) |
| **Colleges Directory** | `screenshots/super_admin__colleges.png` | `05223eba93f76348aeed0cb4ed5dd7d8` | **PASS** | Live institutions (API-001, SBCE, SVGP) |
| **College Detail (Subscreen)** | `screenshots/super_admin__college_detail.png` | `1fd048a6bdddd5a6a6938f275e70a331` | **PASS** | Full academic overview, stats, campus info |
| **College Detail Scrolled** | `screenshots/super_admin__college_detail_scrolled.png` | `dd744c5c4a8840ce755d83d107236963` | **PASS** | College Admins list with Add Admin button |
| **Users Directory** | `screenshots/super_admin__users.png` | `b44d97b26bad15a0e3025a0ea0efc4a1` | **PASS** | 20 directory records across all roles |
| **Reports / Analytics** | `screenshots/super_admin__reports.png` | `3772ccc65a1bea06bd79bfe49e4192e0` | **PASS** | Fresh capture replacing Prompt 02 duplicate! |
| **AI Assistant** | `screenshots/super_admin__ai_assistant.png` | `51f641074bb70c6ef8819b582bdfbd71` | **PASS** | Interactive assistant prompt suggestions |
| **User Profile** | `screenshots/super_admin__profile.png` | `9fbd554f805b274c64f02eedba1c31dc` | **PASS** | Verified single AppBar, no nested Scaffold |
| **Edit Profile (Subscreen)** | `screenshots/super_admin__edit_profile.png` | `4fbc18fd9d8ac6364eb23432c80eefe4` | **PASS** | Form inputs, locked institutional fields, Cancel/Save |
| **Platform Settings** | `screenshots/super_admin__settings.png` | `13cfc9f63370037459bd55064065b7b3` | **PASS** | Academic config, theme, notifications, security |
| **Academic Calendar** | `screenshots/super_admin__calendar.png` | `7fa4f67e3cb58db57b6633100c782181` | **PASS** | Full calendar grid, month selector, add event FAB |
| **Notifications** | `screenshots/super_admin__notifications.png` | `4faf4230ca895e7fe02e697a4e7e7be9` | **PASS** | Notification center, empty state, category chips |
| **Audit Logs (404 Page)** | `screenshots/super_admin__audit_logs.png` | `f050291492a0291aeac4061ea4bc5fcd` | **PASS** (Defect Found) | Route `/audit` missing in router, graceful 404 |
| **Logout Dialog** | `screenshots/logout__confirmation_dialog.png` | `ef83fa1d05287a247237e2c24f955724` | **PASS** | Confirmation modal with Cancel / Sign Out |
| **Logout Cancelled** | `screenshots/logout__cancelled.png` | `a0147ddbf85a1811b9f365bff15c308c` | **PASS** | Dismissed dialog, session retained |
| **Logout Redirect** | `screenshots/logout__redirect_to_login.png` | `d2d9f96722444b7be3be41ff5071d91a` | **PASS** | Tokens purged, clean redirect to `/login` |
| **Logout Back Defense** | `screenshots/logout__back_press_remains_login.png` | `998589bdbbf2614f6c39ba99ccdc2f8d` | **PASS** | Hardware back press prevented re-entry |

---

## 3. Discarded / Invalid Prompt 02 Artifacts Summary

The following files from Prompt 02 are formally marked **INVALID** and must NOT be considered truthful evidence:
1. `docs/runtime_qa/prompt02/after/super_admin__reports__after.png` (Replaced by `docs/runtime_qa/prompt02_1/screenshots/super_admin__reports.png`)
2. `docs/runtime_qa/prompt02/after/college_admin__reports__after.png` (Marked INVALID; College Admin role BLOCKED due to unprovided credentials)
3. `docs/runtime_qa/prompt02/after/student__assignments__after.png` (Marked INVALID; Student role BLOCKED due to unprovided credentials)
4. `docs/runtime_qa/prompt02/after/student__timetable__day__after.png` (Marked INVALID; Student role BLOCKED due to unprovided credentials)
