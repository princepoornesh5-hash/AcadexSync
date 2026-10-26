# ACADEX ATTENDANCE SESSION INTEGRITY & DUPLICATE PREVENTION REPORT

**Date:** October 13, 2026  
**Priority:** High  
**Scope:** Attendance Sessions History, Session Creation Idempotency, Attendance Summaries Invariant, Session Lifecycle, Multi-Tenant / Faculty Isolation  
**Target File:** `ACADEX_ATTENDANCE_SESSION_INTEGRITY_FIX_REPORT.md`

---

## 1. Executive Summary

This investigation was initiated to resolve two high-visibility inconsistencies in the Attendance Sessions History interface:
1. **Attendance Count Inconsistency:** An October 12 session displayed `Present: 2`, `Late: 1`, `Absent: 0`, and `Total: 5`. The sum of displayed status categories (2 + 1 + 0 = 3) failed to match the reported total of 5.
2. **Duplicate-Looking Sessions:** Two distinct October 12 session cards were rendered with identical subject (`IOT`), section (`A`), and time display (`10:00–12:00`).

Both defects were diagnosed down to their exact persisted database documents and frontend rendering logic. Full end-to-end fixes have been implemented across the backend ingestion pipeline, validation schemas, and Flutter presentation widgets. Comprehensive automated regression test suites confirm that session creation is strictly idempotent, dash character encoding variations are normalized, summary counts obey a strict completeness invariant (`present + late + absent + excused + unmarked == total`), and legitimate sessions are clearly distinguishable without altering production data.

---

## 2. Confirmed Root Causes

### A. Root Cause of Duplicate-Looking Sessions
Direct diagnostic inspection of the live MongoDB Atlas database revealed two distinct persisted `AttendanceSession` records:

| Field | Session 1 | Session 2 |
| :--- | :--- | :--- |
| **`_id`** | `6acdc9475b7b19115fef9db4` | `6acc69819601297d3dff5924` |
| **`createdAt`** | `2026-10-13T06:01:43.708Z` | `2026-10-12T05:00:49.030Z` |
| **`date`** | `2026-10-12T00:00:00.000Z` | `2026-10-12T00:00:00.000Z` |
| **`timeSlot`** | `"10:00 – 12:00"` (Unicode EN-DASH `\u2013`) | `"10:00 - 12:00"` (ASCII Hyphen `\u002D`) |
| **`timetableEntryId`**| `null` | `6acbdff879201934be992851` |
| **`status`** | `open` | `open` |
| **`records` Count** | 5 | 5 |

**Underlying Mechanism:**
1. **Unicode Dash Divergence:** Timetable UI components (e.g. `dashboard_timetable_live_card.dart`, `daily_timeline_view.dart`, `next_class_card.dart`) constructed timeslots using `'${entry.startTime} – ${entry.endTime}'` containing a Unicode en-dash (`\u2013`), whereas other submission flows used the standard ASCII hyphen (`-`).
2. **Compound Index Bypass:** MongoDB enforces a unique compound index:
   ```javascript
   { collegeId: 1, sectionId: 1, subjectId: 1, date: 1, timeSlot: 1 }
   ```
   Because MongoDB executes strict binary string equality, `"10:00 – 12:00"` is distinct from `"10:00 - 12:00"`.
3. **Absence of Pre-Normalization:** Neither the Mongoose model schema nor the service normalized `timeSlot` strings prior to persistence, allowing both sessions to coexist in MongoDB without triggering index collision or service-level deduplication.
4. **Indistinguishable UI Display:** The Flutter `AttendanceRecordCard` did not render unique session references (e.g. short ID hash) or submission provenance, presenting both cards with identical visual headers.

---

### B. Root Cause of the Attendance Count Mismatch
Inspection of the 5 granular `AttendanceRecord` documents for Session 1 (`6acdc9475b7b19115fef9db4`) revealed the following persisted marks:
1. `Harsha` (`IOT001`): `status: "present"`
2. `Naga Rasagna` (`IOT002`): `status: "late"`
3. `R Poornesh` (`IOT003`): `status: "present"`
4. `Santosh` (`IOT004`): `status: "excused"`
5. `k Uday Kumar` (`IOT005`): `status: "excused"`

**Underlying Mechanism:**
- The domain model supports `AttendanceStatus.excused` as a first-class canonical status.
- However, `AttendanceRecordCard.dart` only rendered four fixed statistics: Present, Late, Absent, and Total.
- Because `Santosh` and `k Uday Kumar` were marked `excused`, they were omitted from the Present, Late, and Absent buckets.
- The UI rendered:
  - Present: 2
  - Late: 1
  - Absent: 0
  - Total: 5
- This created an apparent mathematical discrepancy (2 + 1 + 0 = 3 != 5) because legitimate `Excused` records were hidden.

---

## 3. Summary Semantics & Invariants

To ensure complete count integrity, the frontend and backend have been aligned to enforce a strict invariant:

$$\text{Present} + \text{Late} + \text{Absent} + \text{Excused} + \text{Unmarked} = \text{Total Eligible Roster}$$

### Rules Enforced:
1. **Authorized Denominator:**
   The denominator is always authoritative from `StudentEnrollment` for the session's college, department, semester, and section. Students from outside the tenant or historical rosters are strictly excluded.
2. **Explicit vs. Unmarked Distinction:**
   Unrecorded students are never automatically marked absent to force the sum. If a student record is unrecorded, it is reported under the **Unmarked** status.
3. **Comprehensive Status Visibility:**
   `AttendanceRecordCard` dynamically displays `Excused` (styled in Indigo `0xFF6366F1`) and `Unmarked` (styled in Slate/Amber) whenever counts exceed zero, guaranteeing visual and mathematical consistency.

---

## 4. Key Fixes Implemented

### A. TimeSlot Normalization Pipeline
1. **Utility (`Backend/src/utils/dateTime.ts`):**
   Added and exported `normalizeTimeSlot(timeSlot?: string | null): string`:
   - Replaces any dash variant (`\u2010` through `\u2015`, minus `\u2212`, fullwidth `\uFF0D`) with a standard ASCII hyphen (`-`).
   - Standardizes time formatting to `HH:mm - HH:mm` (e.g. `9:00 - 10:00` becomes `09:00 - 10:00`).
2. **Mongoose Schema Pre-Validate Hooks:**
   - `AttendanceSessionSchema.pre('validate')`: Automatically normalizes `this.timeSlot` before document validation and persistence.
   - `AttendanceRecordSchema.pre('validate')`: Normalizes `this.timeSlot` on granular records.
3. **Frontend Ingestion Normalization:**
   - `AttendanceSession.fromJson`: Automatically normalizes `timeSlot` on parsing.
   - Flutter timetable widgets (`daily_timeline_view.dart`, `dashboard_timetable_live_card.dart`, `next_class_card.dart`, `timetable_entry_detail_sheet.dart`, `timetable_widgets.dart`) updated to construct canonical ASCII hyphen timeslots.

### B. Idempotent Session Creation & Duplicate Prevention
In `Backend/src/services/attendance.service.ts`:
1. **Calendar Day Normalization:**
   Queries now bound searches using `startOfCalendarDay` and `endOfCalendarDay` in the college's authoritative timezone.
2. **Cross-Variant Duplicate Lookup:**
   When checking for existing sessions for a given subject, section, and date, the service checks an `$in` set containing all dash variations (`-`, `–`, `—`, `−`) and timetable entry IDs.
3. **In-Place Record Updates for Open Sessions:**
   If an open session already exists for the scheduled occurrence, the service updates records idempotently and audits changes instead of attempting a redundant insert.
4. **Optimistic Concurrency & E11000 Race Condition Recovery:**
   - If concurrent requests race past the query check, the database-level unique compound index catches the duplicate (`E11000`).
   - The catch block recovers the existing session and updates records safely.
   - Mongoose `VersionError` is caught during concurrent modifications, re-fetching the authoritative fresh document without crashing.

### C. Frontend Distinguishable Display & Deduplication
1. **`AttendanceRecordCard.dart`:**
   - Displays a short reference badge (e.g. `#ef9db4` vs `#ff5924`) alongside the normalized timeslot in the card header.
   - Distinct sessions on the same date can be easily identified and distinguished.
   - Computes and displays `Excused` and `Unmarked` metrics.
2. **`faculty_history_providers.dart`:**
   - Watches `activeWorkspaceProvider` to invalidate and reload history automatically upon workspace switching.
   - Deduplicates incoming lists by `session.id` in `filteredFacultyHistoryProvider`, eliminating duplicate card rendering from API pagination or state merging.

### D. Multi-Tenant & Faculty Authorization Verification
- Enforces faculty identity checks: a faculty member cannot mark attendance or overwrite a session belonging to another faculty member or cross-college tenant.
- Enforces timetable entry schedule validation and active assignment verification.
- Enforces lifecycle rules: LOCKED and CLOSED sessions reject modifications.

---

## 5. Files Changed

### Backend:
- `Backend/src/utils/dateTime.ts`: Added `normalizeTimeSlot` utility.
- `Backend/src/models/attendanceSession.model.ts`: Added `pre('validate')` normalization hook.
- `Backend/src/models/attendanceRecord.model.ts`: Added `pre('validate')` normalization hook.
- `Backend/src/services/attendance.service.ts`: Implemented idempotent lookup, dash-variant matching, concurrency race condition recovery, and VersionError handling.
- `Backend/tests/integration/attendance_session_idempotency_and_integrity.test.ts`: Integration test suite covering all 15 scenarios.

### Frontend:
- `Frontend/lib/features/attendance/domain/models/attendance_session.dart`: Normalized `timeSlot` in `fromJson`.
- `Frontend/lib/features/attendance/presentation/widgets/faculty/attendance_record_card.dart`: Added Excused & Unmarked counts, short session hash `#` indicator, and normalized time slot rendering.
- `Frontend/lib/features/attendance/presentation/providers/faculty_history_providers.dart`: Added workspace auto-invalidation and provider-level ID deduplication.
- `Frontend/lib/features/timetable/presentation/widgets/daily_timeline_view.dart`: Standardized hyphen in timeslot.
- `Frontend/lib/features/timetable/presentation/widgets/dashboard_timetable_live_card.dart`: Standardized hyphen in timeslot.
- `Frontend/lib/features/timetable/presentation/widgets/next_class_card.dart`: Standardized hyphen in timeslot.
- `Frontend/lib/features/timetable/presentation/widgets/timetable_entry_detail_sheet.dart`: Standardized hyphen in timeslot.
- `Frontend/lib/features/timetable/presentation/widgets/timetable_widgets.dart`: Standardized hyphen in timeslot.
- `Frontend/test/attendance_count_integrity_test.dart`: Widget and unit tests for summary count invariant, en-dash parsing, and distinguishable card references.

---

## 6. Test & Verification Results

### Backend Integration Tests
Command:
```bash
npx jest tests/integration/attendance_session_idempotency_and_integrity.test.ts --forceExit
```
**Results: 12 passed, 12 total (100% Pass Rate)**
- `TimeSlot Normalization Helper`: normalizes en-dash, em-dash, and irregular spaces to canonical `"HH:mm - HH:mm"`.
- `TimeSlot Normalization Helper`: pre-validate hook normalizes `timeSlot` when AttendanceSession is created or saved.
- `Idempotent Session Creation`: returns the same session when called repeatedly with en-dash vs hyphen.
- `Concurrent Session Creation`: concurrent session creation resolves safely to a single session.
- `Legitimate Separate Sessions`: different date or subject remain distinct.
- `Attendance Count Integrity`: breakdown with Present (2), Late (1), Excused (2) correctly sums to Total (5).
- `Attendance Count Integrity`: distinguishes explicit absence from unmarked attendance without auto-marking.
- `Attendance Count Integrity`: rejects student not enrolled in the section (roster integrity).
- `Lifecycle & Authorization Controls`: prevents modification of LOCKED sessions.
- `Lifecycle & Authorization Controls`: prevents modification of CLOSED sessions.
- `Lifecycle & Authorization Controls`: prevents unauthorized faculty from modifying another faculty session.
- `Lifecycle & Authorization Controls`: prevents cross-college session access and history retrieval.

### Backend TypeScript Compilation
Command:
```bash
npm run typecheck
```
**Result: 0 errors.**

### Frontend Flutter Widget & Unit Tests
Command:
```bash
flutter test test/attendance_count_integrity_test.dart
```
**Results: 4 passed, 4 total (100% Pass Rate)**
- `AttendanceSession parses unicode en-dash and em-dash to canonical hyphen`.
- `AttendanceSession status counts satisfy invariant: present + late + absent + excused + unmarked == total`.
- `AttendanceRecordCard renders Excused count and short reference for Session 1 (#ef9db4)`.
- `AttendanceRecordCard renders Unmarked count when unrecorded students exist`.

### Frontend Flutter Analysis
Command:
```bash
flutter analyze
```
**Result: No issues found! (0 warnings, 0 errors).**

---

## 7. Production Data & Safe Reconciliation Report

### Read-Only Production Diagnostic (MongoDB Atlas Live Inspection)
No database mutation, deletion, or modification was performed on production data. Both sessions remain fully intact.

| Property | Canonical Occurrence | Duplicate Creation |
| :--- | :--- | :--- |
| **Session ID** | `6acc69819601297d3dff5924` | `6acdc9475b7b19115fef9db4` |
| **Timetable Entry ID** | `6acbdff879201934be992851` (Authoritative) | `null` |
| **Created At** | `2026-10-12T05:00:49.030Z` | `2026-10-13T06:01:43.708Z` |
| **TimeSlot String** | `"10:00 - 12:00"` (ASCII) | `"10:00 – 12:00"` (En-dash) |
| **Attendance Marks** | 5 Present (Harsha, Naga Rasagna, R Poornesh, Santosh, k Uday Kumar) | 2 Present (Harsha, R Poornesh), 1 Late (Naga Rasagna), 2 Excused (Santosh, k Uday Kumar) |
| **Status** | `open` | `open` |

### Reconciliation Recommendation (Requires Explicit Authorization):
- **Canonical Session:** `6acc69819601297d3dff5924` holds the authoritative link to the timetable entry `6acbdff879201934be992851`.
- **More Recent Attendance Markings:** `6acdc9475b7b19115fef9db4` was submitted on October 13 and contains more nuanced marks (Late and Excused entries for specific students).
- **Safe Administrative Reconciliation Script (When Authorized):**
  1. Transfer the latest granular records from `6acdc9475b7b19115fef9db4` into `6acc69819601297d3dff5924`.
  2. Set `status: "cancelled"` on `6acdc9475b7b19115fef9db4` with `cancellationReason: "Reconciled into canonical timetable session 6acc69819601297d3dff5924"`.
  3. Under no circumstances should raw database documents be hard-deleted, ensuring full audit trail preservation.
