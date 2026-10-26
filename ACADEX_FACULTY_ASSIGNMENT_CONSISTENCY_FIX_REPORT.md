# ACADEX BUG FIX REPORT: Faculty Assignment Consistency

**Priority**: HIGH  
**Scope**: My Classes, Timetable, Attendance Entry, Create Note  
**Date**: October 13, 2026  

---

## 1. Confirmed Root Cause

The inconsistency where faculty member **T Masila Mani** could see the scheduled **IoT (CM-504) Tuesday 11:00–13:00** class on their Timetable with a "Mark Attendance" button, but observed:
1. *"No Active Teaching Assignments"* on **My Classes**, and
2. *"No active teaching assignments are available for your account."* on **Create Note**

was caused by a fundamental discrepancy in client-side assignment resolution:

1. **RBAC Endpoint Privilege Mismatch**:
   - `myFacultyAssignmentsProvider` previously attempted to discover the faculty profile by calling `ref.watch(facultyProvider(null))`, which executes `GET /api/v1/academics/faculty`.
   - The backend route `/academics/faculty` strictly enforces `requireHodOrAbove`. When authenticated as a `FACULTY` user, this request receives HTTP 403 Forbidden.
   - Consequently, the faculty list returned `[]`, `myFaculty` resolved to `null`, and `myFacultyAssignmentsProvider` evaluated to an empty list `[]`.
   - The client never invoked the canonical personal teaching authorization contract: `GET /api/v1/academics/faculty-assignments/my`.

2. **Asymmetric Data Flow in Timetable vs My Classes / Create Note**:
   - Timetable used `GET /api/v1/timetables/faculty/me`, which on the backend directly resolved `Faculty` by `userId: req.user.id` and returned published entries with `entry.facultyId == facultyProfile._id`.
   - However, My Classes and Create Note relied on the broken client-side provider, failing to resolve the assignment despite it existing and being fully active in MongoDB.

3. **User ID vs Faculty ID Isolation**:
   - The ACADEX architecture distinguishes `User` (authenticated identity, `_id: 6ac3ce580d1cfe82de0cb598`) from `Faculty` (faculty profile, `_id: 6ac3ce590d1cfe82de0cb59f`).
   - Teaching assignments (`FacultyAssignment`) authoritatively store `facultyId` referencing `Faculty._id`.
   - Attempting to filter assignments using `a.facultyId == user.id` on the client failed because `user.id != faculty._id`.

---

## 2. Relevant Data Relationships & Authoritative Database Integrity

Direct inspection of MongoDB Atlas confirmed that the stored relationships for T Masila Mani's IoT teaching assignment were **100% valid, canonical, and fully linked**:

- **Authenticated User**:
  - `_id`: `6ac3ce580d1cfe82de0cb598`
  - `name`: `"T Masila Mani"`
  - `role`: `"FACULTY"`
  - `collegeId`: `6ac3c8910d1cfe82de0caf94`
  - `departmentId`: `6ac3c9d60d1cfe82de0cb0fe`
- **Faculty Profile**:
  - `_id`: `6ac3ce590d1cfe82de0cb59f`
  - `userId`: `6ac3ce580d1cfe82de0cb598` (Points to User)
  - `collegeId`: `6ac3c8910d1cfe82de0caf94`
  - `status`: `"active"`, `isActive: true`
- **Canonical FacultyAssignment**:
  - `_id`: `6ac4d5370b578d1982cbd598`
  - `facultyId`: `6ac3ce590d1cfe82de0cb59f` (Matches Faculty profile `_id`)
  - `subjectId`: `6ac3cd9b0d1cfe82de0cb448` ("Internet of Things", `CM-504`)
  - `sectionId`: `6ac3cd290d1cfe82de0cb3b3` ("Section A")
  - `collegeId`: `6ac3c8910d1cfe82de0caf94`
  - `status`: `"active"`, `isActive: true`
- **Published Timetable**:
  - `_id`: `6ac52fd261eb6dd116698984` (Section A, 5th Sem)
  - Entry on Tuesday 11:00–13:00 has `facultyId: 6ac3ce590d1cfe82de0cb59f` and `facultyAssignmentId: 6ac4d5370b578d1982cbd598`.

**Conclusion**: Stored data was valid; **no database tampering, record re-creation, or synthetic data invention was required or performed**.

---

## 3. Files Changed

### Backend (`Backend/src/`):
1. [academic.service.ts](file:///Users/poornesh/Campus%20Management%20Main/Backend/src/services/academic.service.ts)
   - Added canonical `getMyFacultyAssignments(requester: AuthenticatedUser)`:
     - Resolves the canonical `Faculty` profile for the authenticated `requester` within their active workspace (`requester.collegeId`).
     - Queries active `FacultyAssignment` records matching `facultyId` (or `userId`).
     - Populates `cohort`, `academicStage`, and hierarchy contexts.
     - Enforces cross-college and tenant isolation.
2. [academic.controller.ts](file:///Users/poornesh/Campus%20Management%20Main/Backend/src/controllers/academic.controller.ts)
   - Routed `getMyFacultyAssignments` to `AcademicService.getMyFacultyAssignments(req.user)`.
3. [timetable.service.ts](file:///Users/poornesh/Campus%20Management%20Main/Backend/src/services/timetable.service.ts)
   - In `enrichTimetableEntries`, dynamically verifies canonical `FacultyAssignment` association and validates that timetable entries are linked to active, authorized teaching assignments.
4. [attendance.service.ts](file:///Users/poornesh/Campus%20Management%20Main/Backend/src/services/attendance.service.ts)
   - Verified and hardened session creation: validates that `facultyAssignmentId` belongs to the authenticated faculty member, matches college and section scope, and fails closed for orphaned entries.

### Frontend (`Frontend/lib/`):
1. [academic_repository.dart](file:///Users/poornesh/Campus%20Management%20Main/Frontend/lib/features/academic_structure/domain/repositories/academic_repository.dart)
   - Added `Future<List<FacultyAssignment>> getMyFacultyAssignments();` to repository interface.
2. [api_academic_repository.dart](file:///Users/poornesh/Campus%20Management%20Main/Frontend/lib/features/academic_structure/data/repositories/api_academic_repository.dart)
   - Implemented `getMyFacultyAssignments` calling canonical `GET /academics/faculty-assignments/my`.
3. [mock_academic_repository.dart](file:///Users/poornesh/Campus%20Management%20Main/Frontend/lib/features/academic_structure/data/repositories/mock_academic_repository.dart) & [firebase_academic_repository.dart](file:///Users/poornesh/Campus%20Management%20Main/Frontend/lib/features/academic_structure/data/repositories/firebase_academic_repository.dart)
   - Implemented `getMyFacultyAssignments` with role and user scope filtering.
4. [academic_providers.dart](file:///Users/poornesh/Campus%20Management%20Main/Frontend/lib/features/academic_structure/presentation/providers/academic_providers.dart)
   - Added `myFacultyAssignmentsAsyncProvider = FutureProvider.autoDispose<List<FacultyAssignment>>` executing `repo.getMyFacultyAssignments()`.
   - Wired `myFacultyAssignmentsProvider` to consume `myFacultyAssignmentsAsyncProvider` with fallback for mock test harnesses.
   - Added provider invalidation on auth changes, workspace switches, dialog save, and realtime events.
5. [my_assignments_screen.dart](file:///Users/poornesh/Campus%20Management%20Main/Frontend/lib/features/academic_structure/presentation/screens/my_assignments_screen.dart)
   - Watches `myFacultyAssignmentsAsyncProvider`.
   - Distinguishes loading (`CircularProgressIndicator`), error (retry button), empty ("No Active Teaching Assignments"), and populated states.
   - De-duplicates assignments.
6. [note_form_screen.dart](file:///Users/poornesh/Campus%20Management%20Main/Frontend/lib/features/notes/presentation/screens/note_form_screen.dart)
   - Watches `myFacultyAssignmentsAsyncProvider`.
   - Distinguishes loading, error, empty, and populated states.
   - Auto-populates `subjectId`, `sectionId`, `semesterId`, and `courseId` from the selected authoritative assignment.
   - Fixed `isExpanded: true` to prevent horizontal dropdown overflows.
7. [timetable_entry_detail_sheet.dart](file:///Users/poornesh/Campus%20Management%20Main/Frontend/lib/features/timetable/presentation/widgets/timetable_entry_detail_sheet.dart), [daily_timeline_view.dart](file:///Users/poornesh/Campus%20Management%20Main/Frontend/lib/features/timetable/presentation/widgets/daily_timeline_view.dart), & [dashboard_timetable_live_card.dart](file:///Users/poornesh/Campus%20Management%20Main/Frontend/lib/features/timetable/presentation/widgets/dashboard_timetable_live_card.dart)
   - In `_onMarkAttendance`, resolves `facultyAssignmentId` from entry or matches active personal assignments.
   - Rejects orphaned entries safely by displaying an error SnackBar: *"Cannot mark attendance: This timetable entry is not associated with an authorized teaching assignment."*

### Tests Created / Updated:
1. [faculty_assignment_consistency_authoritative.test.ts](file:///Users/poornesh/Campus%20Management%20Main/Backend/tests/integration/faculty_assignment_consistency_authoritative.test.ts)
2. [faculty_assignment_consistency_authoritative_test.dart](file:///Users/poornesh/Campus%20Management%20Main/Frontend/test/faculty_assignment_consistency_authoritative_test.dart)

---

## 4. How My Classes Resolves Assignments After the Fix

1. `MyAssignmentsScreen` listens to `myFacultyAssignmentsAsyncProvider`.
2. The provider invokes `ApiAcademicRepository.getMyFacultyAssignments()`, making a `GET` request to `/api/v1/academics/faculty-assignments/my`.
3. The backend resolves the authenticated session `req.user.id`, finds the `Faculty` profile in the active college (`req.user.collegeId`), and queries `FacultyAssignment` records where `facultyId == facultyProfile._id`.
4. The client receives the JSON list of active teaching assignments without requiring HOD privileges or querying `/academics/faculty`.
5. The UI displays the operational snapshot cards and class list. If the request fails, it renders an explicit error state with a "Retry" button rather than falsely presenting an empty state.

---

## 5. How Timetable Resolves the Corresponding Assignment

1. Timetable fetch (`/timetables/faculty/me`) fetches published entries for the faculty member.
2. In `timetable.service.ts` (`enrichTimetableEntries`), every entry is mapped and enriched with its canonical `facultyAssignmentId`.
3. When the faculty member clicks "Mark Attendance" on the Timetable UI (detail bottom sheet, daily timeline, or dashboard live card), the app verifies that `facultyAssignmentId` is present and valid in `myFacultyAssignmentsProvider`.
4. If valid, the app constructs an `AssignedClass` with the canonical `facultyAssignmentId` and routes to `/attendance/mark`.
5. If the entry is orphaned (no corresponding assignment exists), attendance creation is blocked on the client with a clear error notification and rejected with HTTP 403 on the backend.

---

## 6. How Create Note Loads Authorized Academic Context

1. `NoteFormScreen` watches `myFacultyAssignmentsAsyncProvider`.
2. For faculty users, the screen presents a single authoritative **"Teaching Assignment / Class"** dropdown populated directly from the faculty member's authorized assignments.
3. When the faculty member selects an assignment (e.g., IoT Section A), the form automatically binds `subjectId`, `sectionId`, `semesterId`, and `courseId`.
4. If no assignments exist, it displays an informative warning ("No active teaching assignments are available for your account.") and disables class selection.
5. If the request encounters a network failure, a dedicated error message with a "Retry" button is displayed.
6. The backend independently enforces academic authorization on note upload URL creation (`POST /api/v1/academics/notes/upload-url`), blocking cross-college or unauthorized scope attempts with HTTP 403.

---

## 7. Attendance Authorization Verification

Attendance creation enforces the authoritative relationship end-to-end:
- **Authentication & Role**: Request must have a valid JWT with `role === FACULTY` or HOD/Admin.
- **Tenant & Workspace Scope**: `collegeId` must match the active workspace.
- **Assignment Ownership**: Backend queries `FacultyAssignment.findOne({ _id: facultyAssignmentId, collegeId, isActive: true, status: 'active' })`. If the assignment belongs to another faculty member or is inactive, it throws HTTP 403 Forbidden (*"Faculty assignment belongs to another faculty member"*).
- **Orphan Guard**: If `timetableEntryId` does not resolve to an active assignment, the request is rejected with HTTP 403 Forbidden (*"Specified faculty assignment is invalid or inactive"*).

---

## 8. Focused Test Results

### Backend Integration Tests
Command:
```bash
npx jest tests/integration/faculty_assignment_consistency_authoritative.test.ts --forceExit
```
Results:
- **Test Suites**: 1 passed, 1 total
- **Tests**: 9 passed, 9 total
  1. `GET /api/v1/academics/faculty-assignments/my` returns authorized teaching assignment resolving `Faculty._id` from authenticated `User._id`.
  2. Prevents a faculty member from seeing another faculty member's assignments.
  3. Prevents cross-college assignment exposure.
  4. Resolves published timetable entry with canonical `facultyAssignmentId` for authenticated faculty.
  5. Authorizes attendance session creation when timetable entry resolves to valid assignment.
  6. Rejects attendance session when timetable entry is orphaned or assignment is unauthorized (403 Forbidden).
  7. Rejects attendance marking by unauthorized faculty member for another faculty assignment (403 Forbidden).
  8. Authorizes note creation within faculty member's authorized subject & section.
  9. Rejects note publishing against an unauthorized cross-college or unauthorized scope (403 Forbidden).

Existing Hardening Suite:
```bash
npx jest tests/integration/people_faculty_assignment_p36.test.ts --forceExit
```
- **Test Suites**: 1 passed, 1 total
- **Tests**: 14 passed, 14 total

Backend Typecheck:
```bash
npm run typecheck
```
- **Output**: `tsc --noEmit` exited 0 (clean).

### Frontend Flutter Tests
Command:
```bash
flutter test test/faculty_assignment_consistency_authoritative_test.dart
```
Results:
- **Tests**: 8 passed, 8 total
  1. My Classes displays valid IoT teaching assignment resolved via canonical contract.
  2. My Classes displays distinct empty state when no assignments exist.
  3. My Classes displays distinct error state with retry on API failure.
  4. Create Note displays authoritative IoT class when eligible assignment exists.
  5. Create Note displays warning message when no teaching assignments are available.
  6. Timetable entry detail sheet rejects orphaned entry without valid assignment.
  7. Timetable entry detail sheet resolves valid IoT entry to canonical assignment.
  8. Workspace switching invalidates personal assignments provider.

Related Flutter Regression Suites:
```bash
flutter test test/prompt3_academic_structure_faculty_assignment_test.dart test/prompt36_faculty_assignment_test.dart test/notes_ui_test.dart
```
- **Tests**: 25 passed, 25 total

Static Analysis:
```bash
flutter analyze lib/features/academic_structure/ lib/features/notes/ lib/features/timetable/ test/faculty_assignment_consistency_authoritative_test.dart
```
- **Output**: `Analyzing 4 items... No issues found! (ran in 3.1s)`

---

## 9. Remaining Data-Integrity or Deployment Issues

- **None**. The database in MongoDB Atlas was verified to be structurally integral and correct.
- Client workspace switching and real-time dispatcher invalidations ensure that cached assignments do not bleed across active workspaces or logins.
- All backend routes and frontend providers strictly adhere to the authoritative `FacultyAssignment` architecture.
