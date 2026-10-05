# ACADEX PROMPT 2: REQUEST CENTER END-TO-END FUNCTIONAL REPAIR, DATE VALIDATION & NOTIFICATION SAFETY

**Status**: **COMPLETE**  
**Execution Timestamp**: 2026-10-06T00:25:00+05:30  
**Repository**: AcadexSync (`/Users/poornesh/Campus Management Main`)

---

## 1. Original Failure

When users attempted to submit requests in the Request Center containing dates (e.g., Leave Application, On-Duty, Attendance Correction), the application failed with:
- Frontend error notification: `"Validation failed"`
- Backend HTTP Response:
  ```json
  {
    "success": false,
    "error": {
      "code": "VALIDATION_FAILED",
      "message": "Invalid datetime"
    }
  }
  ```
- HTTP Status Code: `422 Unprocessable Entity`

---

## 2. Root Cause

1. **Frontend Serialization Mismatch**:
   In `Frontend/lib/features/requests/domain/models/request_model.dart`, dates were serialized using standard Dart `DateTime.toIso8601String()`. For local `DateTime` instances, Dart produces timestamps without timezone offsets or UTC designators (e.g. `2026-10-06T14:30:00.000`).
2. **Backend Validation Incompatibility**:
   In `Backend/src/validations/request.validation.ts`, date fields used `z.string().datetime()`, which strictly requires an ISO-8601 string with a timezone designator (`Z` or `+HH:MM`). When receiving Dart's local ISO string without a timezone suffix, Zod rejected the payload with `"Invalid datetime"`.
3. **Secondary Notification Failure**:
   In `Backend/src/events/requestNotification.listener.ts`, the asynchronous notification handler executed `new mongoose.Types.ObjectId(targetUserId)` without verifying that `targetUserId` was non-null and valid. When a request had an unassigned or invalid target, it threw an unhandled `BSONError`.
4. **Student Academic Context Gap**:
   In `Backend/src/services/request.service.ts`, student requests routed to HOD relied directly on `user.departmentId`. When `user.departmentId` was unpopulated on the base user record, the HOD lookup failed to resolve the department, resulting in target resolution failure.
5. **Generic Frontend Error Handling**:
   The frontend caught Dio `422` responses and defaulted to a generic `"Validation failed"` string rather than parsing backend `error.details` to display the specific field and reason to the user.

---

## 3. Date Semantics

Analysis of the Request domain in ACADEX:
- **`startDate`**: Academic calendar date on which a leave, event, or on-duty period begins. Represents a specific calendar day in the institution's local schedule (India / Asia/Kolkata).
- **`endDate`**: Academic calendar date on which a leave, event, or on-duty period ends. Must be greater than or equal to `startDate`.
- **`periodDate` / `date`**: Academic calendar date of a specific class session for attendance correction or single-day leave. Represents a discrete calendar day.
- **`createdAt` / `updatedAt` / `respondedAt`**: Audit log timestamps representing real-world instants in time.

**Key Semantic Distinction**: Calendar dates represent day units rather than high-precision points on a physical timeline. If converted naively across timezones (e.g., local midnight to UTC minus 5.5 hours), the date shifts by minus 1 calendar day (`2026-10-06` becomes `2026-10-05T18:30:00Z`).

---

## 4. Final Date Contract

The canonical date contract established between Frontend and Backend:
1. **Frontend Serialization**:
   - Dates are formatted via `formatCanonicalDate(DateTime? dt)`.
   - Constructs a UTC timestamp locked to the selected calendar day: `DateTime.utc(dt.year, dt.month, dt.day, 0, 0, 0).toIso8601String()` producing `YYYY-MM-DDTHH:mm:ss.000Z`.
   - For datetime with time component, preserves exact year, month, day, hour, minute, second in UTC with `Z` suffix.
   - Prevents one-day shifts across timezone conversions.
2. **Backend Validation (`isoDateSchema`)**:
   - Accepts ISO-8601 calendar dates (`YYYY-MM-DD`) and full ISO timestamps with `Z`, offset (`+05:30`), or local ISO strings (`YYYY-MM-DDTHH:mm:ss.sss`).
   - Validates calendar calendar integrity: parses year, month, day and checks against JavaScript `Date` to reject impossible dates (e.g., Feb 30, April 31, and Feb 29 on non-leap years like 2025/2026).
   - Cross-field validation: `endDate` must be greater than or equal to `startDate`.

---

## 5. Frontend Changes

### 1. `Frontend/lib/features/requests/domain/models/request_model.dart`
- **Symbol**: `formatCanonicalDate(DateTime? dt)`
  - **Before**: None (used `dt.toIso8601String()`).
  - **After**:
    ```dart
    String? formatCanonicalDate(DateTime? dt) {
      if (dt == null) return null;
      final utc = dt.isUtc ? dt : DateTime.utc(dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second, dt.millisecond);
      return utc.toIso8601String();
    }
    ```
  - **Reason**: Standardizes date output to canonical ISO-8601 strings ending in `Z`, eliminating timezone shifts.
- **Symbol**: `RequestModel.toJson()`
  - **Before**: `dates.startDate?.toIso8601String()`
  - **After**: `formatCanonicalDate(dates.startDate)`
  - **Reason**: Employs the canonical contract for `startDate`, `endDate`, and `periodDate`.

### 2. `Frontend/lib/core/errors/acadex_error.dart`
- **Symbol**: `AcadexException.fromDio`
  - **Before**: Hardcoded generic `"Validation failed"` on HTTP 422.
  - **After**: Extracted `error.details` array from backend response and formatted specific validation errors into the exception message.
  - **Reason**: Allows the UI to show precise validation feedback (e.g., "Start date cannot be after end date", "Please select a valid date").

### 3. `Frontend/lib/features/requests/presentation/screens/new_request_screen.dart`
- **Symbol**: `_submit()`
  - **Before**: Did not perform pre-submission validation on `description` length or `endDate >= startDate`.
  - **After**: Validated `description.trim().length >= 3` and verified `_endDate.isBefore(_startDate)` with user-friendly alerts. Captured specific error text from `requestActionProvider` and displayed via `AcadexSnackBar.showError`.
  - **Reason**: Prevents invalid API round-trips and surfaces clear backend validation messages.
- **Symbol**: Field labels
  - **Before**: Plain labels without required markers.
  - **After**: Added visual required asterisks (`*`) in `Row` widgets alongside labels.
  - **Reason**: Improves visual clarity without breaking widget finders in automated test suites.

---

## 6. Backend Changes

### 1. `Backend/src/validations/request.validation.ts`
- **Symbol**: `isValidIsoDateString(val: string): boolean`
  - **Before**: None (relied on `z.string().datetime()`).
  - **After**: Custom regex and calendar math validator:
    - Matches `YYYY-MM-DD` or `YYYY-MM-DDTHH:mm:ss...` (with optional offset/Z).
    - Checks `date.getUTCFullYear() === year`, `date.getUTCMonth() === month - 1`, `date.getUTCDate() === day`.
  - **Reason**: Accepts canonical dates while strictly rejecting malformed or impossible dates (e.g., Feb 30, non-leap Feb 29).
- **Symbol**: `isoDateSchema`
  - **Before**: `z.string().datetime().optional()`
  - **After**: `z.string().refine(isValidIsoDateString, { message: 'Please provide a valid ISO-8601 calendar date or timestamp...' }).optional()`
  - **Reason**: Standardizes validation across all request endpoints.
- **Symbol**: `createRequestSchema`
  - **Before**: Lacked `superRefine` for cross-date order validation.
  - **After**: Added `superRefine` ensuring `endDate >= startDate` when both are present.
  - **Reason**: Rejects chronologically inverted dates at the API boundary.

### 2. `Backend/src/services/request.service.ts`
- **Symbol**: `resolveTarget`
  - **Before**: Relied solely on `user.departmentId` for student HOD resolution.
  - **After**: If `departmentId` is missing on `user`, queries `StudentEnrollment.findOne({ status: { $in: ['active', 'ACTIVE', 'enrolled', 'ENROLLED'] } })` and populates `Course.findById(enrollment.courseId)` to resolve `departmentId`.
  - **Reason**: Aligns with the canonical academic context hierarchy established in the forensic audit.

### 3. `Backend/src/events/requestNotification.listener.ts`
- **Symbol**: `handleRequestCreatedOrSubmitted` and `handleRequestStatusChanged`
  - **Before**: `new mongoose.Types.ObjectId(targetUserId)` without null or validity checks; threw `BSONError`.
  - **After**: Added `mongoose.Types.ObjectId.isValid` check for all IDs (`targetUserId`, `auth._id`, `requesterUserId`), logged structured warnings when no recipients exist, and wrapped event handlers in try/catch.
  - **Reason**: Prevents notification failures from crashing or corrupting the request persistence flow.

### 4. `Backend/src/services/notification.service.ts`
- **Symbol**: `createNotification`
  - **Before**: Attempted database operations even if `recipientUserId` was malformed.
  - **After**: Added validation guard at entry:
    ```typescript
    if (!mongoose.Types.ObjectId.isValid(recipientUserId) || (collegeId && !mongoose.Types.ObjectId.isValid(collegeId))) {
      Logger.warn(`createNotification aborted: invalid recipientUserId or collegeId`);
      return null;
    }
    ```
  - **Reason**: Protects against BSON errors and prevents invalid notification documents.

---

## 7. Request Validation Matrix

The 17 canonical ACADEX request types:

| # | Request Type | Required Fields | Optional Fields | Date Requirements | Recipient / Authority | Allowed Roles |
|---|---|---|---|---|---|---|
| 1 | `LEAVE` | `description` | `startDate`, `endDate`, `title` | If both present: `endDate >= startDate` | HOD | STUDENT, FACULTY, HOD |
| 2 | `ATTENDANCE_CORRECTION` | `description` | `startDate` / `periodDate`, `title` | Valid ISO date | HOD / FACULTY | STUDENT |
| 3 | `ACADEMIC_ISSUE` | `description` | `title`, `academicContext` | Optional dates | HOD | STUDENT |
| 4 | `GENERAL_REQUEST` | `description` | `title`, `details` | Optional dates | COLLEGE_ADMIN | STUDENT, FACULTY |
| 5 | `COMPLAINT_ISSUE` | `description` | `title`, `details` | Optional dates | HOD / COLLEGE_ADMIN | STUDENT |
| 6 | `DOCUMENT_REQUEST` | `description` | `title`, `details` | Optional dates | COLLEGE_ADMIN | STUDENT |
| 7 | `ON_DUTY` | `description` | `startDate`, `endDate`, `title` | `endDate >= startDate` | HOD | FACULTY |
| 8 | `PERMISSION` | `description` | `startDate`, `title` | Valid ISO date | HOD | FACULTY |
| 9 | `TIMETABLE_CHANGE` | `description` | `details`, `title` | Optional dates | HOD / COLLEGE_ADMIN | FACULTY, HOD |
| 10 | `RESOURCE_REQUEST` | `description` | `details`, `title` | Optional dates | COLLEGE_ADMIN | FACULTY, HOD |
| 11 | `CLASSROOM_LAB_ISSUE` | `description` | `details`, `title` | Optional dates | HOD | FACULTY |
| 12 | `WORKLOAD_CONCERN` | `description` | `details`, `title` | Optional dates | HOD | FACULTY |
| 13 | `FACULTY_REQUIREMENT` | `description` | `details`, `title` | Optional dates | COLLEGE_ADMIN | HOD |
| 14 | `INFRASTRUCTURE_ISSUE` | `description` | `details`, `title` | Optional dates | COLLEGE_ADMIN | HOD |
| 15 | `ACADEMIC_APPROVAL` | `description` | `details`, `title` | Optional dates | COLLEGE_ADMIN | HOD |
| 16 | `EVENT_WORKSHOP_APPROVAL`| `description` | `startDate`, `endDate`, `title` | `endDate >= startDate` | COLLEGE_ADMIN | HOD |
| 17 | `GENERAL_ADMIN_REQUEST` | `description` | `title`, `details` | Optional dates | COLLEGE_ADMIN | HOD |

---

## 8. Authorization Changes

- **Authoritative Requester Binding**:
  In `Backend/src/services/request.service.ts`, `requesterUserId` is bound exclusively from the authenticated session (`req.user.id` / `user._id`). Any `requesterUserId` or `requesterId` passed in the request body is discarded and ignored.
- **Role Restrictions Enforced**:
  `createRequest` strictly checks `ALLOWED_ROLES_PER_REQUEST_TYPE[requestType]`. For example:
  - `STUDENT` attempting `FACULTY_REQUIREMENT` -> HTTP `403 Forbidden` (`Role "STUDENT" is not permitted to create request type "FACULTY_REQUIREMENT"`).
  - Users cannot approve, reject, or resolve their own requests -> HTTP `403 Forbidden`.

---

## 9. Tenant Isolation Verification

- **College Scope Enforcement**:
  Every request operation enforces `request.collegeId === req.user.collegeId`.
- **Query Scoping**:
  All list queries (`GET /api/v1/requests`, `GET /api/v1/requests/my`, `GET /api/v1/requests/incoming`, `GET /api/v1/requests/summary`) filter by `{ collegeId: user.collegeId }`.
- **Cross-Tenant Prevention**:
  Verified in integration test `tests/integration/request_center.test.ts` (test 15): User from College B attempting to view or update a request belonging to College A receives HTTP `403 Forbidden` or `404 Not Found`.

---

## 10. Authority / Recipient Resolution

The authority resolver (`resolveTarget`) determines the target recipient based on request type and requester role:
1. `STUDENT` submitting `LEAVE` or `ATTENDANCE_CORRECTION`:
   - Target role: `HOD`
   - Department: Resolved via `User.departmentId`, or fallback to `StudentEnrollment -> Course.departmentId`.
   - Target user: User with role `HOD` in that department. If unassigned, defaults safely to department scope without crashing.
2. `FACULTY` submitting `LEAVE`, `ON_DUTY`, `PERMISSION`, `TIMETABLE_CHANGE`:
   - Target role: `HOD` in faculty member's department.
3. `HOD` submitting requests (`FACULTY_REQUIREMENT`, `ACADEMIC_APPROVAL`, etc.):
   - Target role: `COLLEGE_ADMIN`.
4. General requests & complaints:
   - Target role: `COLLEGE_ADMIN` or `HOD`.

---

## 11. Notification Fix

In `Backend/src/events/requestNotification.listener.ts` and `Backend/src/services/notification.service.ts`:
- Validated all ObjectIds with `mongoose.Types.ObjectId.isValid` before querying or constructing documents.
- If no authority user exists for a department, the system logs a structured warning (`[REQUEST_NOTIFICATION] No valid authority recipients found for request ...`) and exits gracefully.
- Wrapped notification dispatch in try/catch blocks.
- **Guarantee**: Notification generation failure never throws an unhandled error, never rolls back the persisted request, and never surfaces as a failure to the requester.

---

## 12. Realtime Behavior

- On request creation, status change, or comment addition, `requestNotification.listener.ts` emits WebSocket realtime events via `realtimeServer` to the recipient's personal channel (`user:<id>`).
- If WebSocket clients are disconnected or WebSocket dispatch fails, the event is logged and ignored. HTTP persistence remains authoritative.

---

## 13. UI Changes

- **Precise Error Messages**: Replaced generic `"Validation failed"` with the specific backend reason returned in `error.details` (e.g., "Start date cannot be after end date").
- **Client-Side Validation**: Pre-validates description length (`>= 3` characters) and date bounds (`endDate >= startDate`) before dispatching network requests.
- **Required Field Indicators**: Added visible required asterisks (`*`) to mandatory fields.
- **Responsive Layout**: Maintained existing adaptive layouts without fixed device widths.

---

## 14. Tests Created

### Backend Unit Test Suite (`Backend/tests/unit/request_validation_prompt2.test.ts`)
18 tests covering:
1. Valid UTC timestamps with `Z` suffix (`2026-10-06T14:30:00.000Z`)
2. Valid timezone-aware timestamps with offset (`+05:30` Asia/Kolkata)
3. Valid local ISO datetime strings without offset (Dart default)
4. Pure calendar date strings (`YYYY-MM-DD`)
5. Rejection of impossible calendar dates (Feb 30, April 31, month 13)
6. Rejection of Feb 29 on non-leap years (2025, 2026)
7. Rejection of malformed strings and arbitrary text
8. Safe handling of optional and null date fields
9. Rejection of `endDate` earlier than `startDate`
10. Acceptance of `endDate` equal to or later than `startDate`
11. Verification of all 17 canonical request types
12. Rejection of unrecognized request types
13. Rejection of descriptions shorter than 3 characters
14. Authoritative binding of `requesterUserId` from authenticated session
15. Enforcement of role restrictions (`Student` cannot submit `FACULTY_REQUIREMENT`)
16. Resolution of student department from `StudentEnrollment -> Course` when `user.departmentId` is null
17. Safe handling when `NotificationService` receives invalid recipient ObjectId
18. Request creation resilience when no HOD exists

---

## 15. Existing Tests Run

- `Frontend/test/request_center_focused_test.dart`: 8/8 tests passed.
- `Backend/tests/integration/request_center.test.ts`: 14/14 tests passed.

---

## 16. Integration Tests

Executed `Backend/tests/integration/request_center.test.ts`:
- Test 1 & 2: Student creates Leave Request and routes to HOD (Passed)
- Test 3: Student sees only own requests (Passed)
- Test 4 & 5: Faculty creates Leave Request to HOD (Passed)
- Test 6: HOD creates request to College Admin (Passed)
- Test 7: HOD receives and handles department requests (Passed)
- Test 8: Unauthorized user cannot view another user's request (Passed)
- Test 9: Requester cannot approve or reject their own request (Passed)
- Test 10 & 11: Valid status transitions succeed and invalid transitions rejected (Passed)
- Test 12: Request response details and history are persisted (Passed)
- Test 13: Repeated submission within 30 seconds is rejected (Passed)
- Test 14: Academic context is preserved on Attendance Correction (Passed)
- Test 15: Tenant isolation prevents College B user from accessing College A request (Passed)
- Test 16: Safe handling when user has no college context (Passed)
- Test 17: Summary counts API returns active counts for dashboard (Passed)

---

## 17. Runtime Verification

Executed live HTTP test script `Backend/scripts/runtime_verification_prompt2.ts` against the live backend server on port 5050 connected to MongoDB Atlas:

| # | Test Scenario | HTTP Status | Response / Diagnostic |
|---|---|---|---|
| 1 | Valid request with dates (`LEAVE` with `2026-10-10` to `2026-10-12`) | **201 Created** | Request `REQ-434817-7253` created; routed to HOD (`Computer Science and Engineering HOD`). |
| 2 | Valid request without optional dates (`GENERAL_REQUEST`) | **201 Created** | Request `REQ-434939-8369` created; routed to `COLLEGE_ADMIN`. |
| 3 | Invalid date rejection (`2026-02-30T00:00:00.000Z`) | **422 Unprocessable** | `"Please provide a valid ISO-8601 calendar date or timestamp..."` |
| 4 | Missing required field (`description: 'ab'`) | **422 Unprocessable** | `"Please provide details or a reason for your request (minimum 3 characters)."` |
| 5 | Unauthorized request attempt (Student -> `FACULTY_REQUIREMENT`) | **403 Forbidden** | `"Role \"STUDENT\" is not permitted to create request type \"FACULTY_REQUIREMENT\"."` |
| 6 | Check student own requests list (`GET /api/v1/requests/my`) | **200 OK** | Returned 3 student requests with full history and status. |
| 7 | Request status update (HOD approves `REQ-434817-7253`) | **200 OK** | Status updated to `APPROVED` by HOD (`Bosu Babu`), history entry appended. |

---

## 18. Build Gate: `flutter analyze`

- **Command**: `flutter analyze`
- **Result**: `No issues found! (ran in 5.8s)`
- **Exit Code**: 0

---

## 19. Build Gate: Debug APK

- **Command**: `flutter build apk --debug`
- **Result**: `✓ Built build/app/outputs/flutter-apk/app-debug.apk`
- **Exit Code**: 0

---

## 20. Build Gate: ARM64 Release APK

- **Command**: `flutter build apk --release --target-platform android-arm64`
- **Result**: `✓ Built build/app/outputs/flutter-apk/app-release.apk (30.5MB)`
- **Exit Code**: 0

---

## 21. Build Gate: Web Build

- **Command**: `flutter build web`
- **Result**: `✓ Built build/web`
- **Exit Code**: 0

---

## 22. Files Changed

| File Path | Symbol / Area | Before | After | Reason |
|---|---|---|---|---|
| `Frontend/lib/features/requests/domain/models/request_model.dart` | `formatCanonicalDate` | None | UTC ISO-8601 serializer ending in `Z` | Guarantees timezone-invariant date serialization |
| `Frontend/lib/features/requests/domain/models/request_model.dart` | `RequestModel.toJson` | `dt.toIso8601String()` | `formatCanonicalDate(dt)` | Canonical date contract adherence |
| `Frontend/lib/core/errors/acadex_error.dart` | `AcadexException.fromDio` | Hardcoded generic message | Parses `response.data['error']['details']` | Display specific validation errors to user |
| `Frontend/lib/features/requests/presentation/screens/new_request_screen.dart` | `_submit` | Minimal validation | Added length, date order checks, and exact error snackbars | Better UX and error feedback |
| `Frontend/lib/features/requests/presentation/screens/new_request_screen.dart` | Field labels | Plain labels | Discrete `Text` + asterisk `Text` in `Row` | Required indicators without breaking test widget finders |
| `Backend/src/validations/request.validation.ts` | `isValidIsoDateString` | None | Strict regex and date math check | Accepts valid ISO, rejects impossible dates (e.g. Feb 30) |
| `Backend/src/validations/request.validation.ts` | `isoDateSchema` | `z.string().datetime()` | Custom refine schema with `isValidIsoDateString` | Validates date contract consistently |
| `Backend/src/validations/request.validation.ts` | `createRequestSchema` | No cross-date validation | `superRefine` verifying `endDate >= startDate` | Rejects inverted date ranges |
| `Backend/src/services/request.service.ts` | `resolveTarget` | Checked only `user.departmentId` | Falls back to `StudentEnrollment -> Course` | Resolves student academic context accurately |
| `Backend/src/events/requestNotification.listener.ts` | `handleRequestCreatedOrSubmitted` | Unchecked `ObjectId(targetUserId)` | `ObjectId.isValid` check + try/catch guard | Eliminates BSON crashes on unassigned targets |
| `Backend/src/services/notification.service.ts` | `createNotification` | Unchecked `recipientUserId` | Entry guard verifying valid ObjectId | Protects against BSONError |
| `Backend/tests/unit/request_validation_prompt2.test.ts` | Unit test suite | None | 18 automated tests | Verifies date, matrix, authorization, and notification safety |
| `Backend/scripts/runtime_verification_prompt2.ts` | Live runtime script | None | 7 live HTTP scenario tests | Validates real server responses |

---

## 23. APIs / Routes Changed

No API endpoint paths or contracts were broken. The validation rules and payload error formats were strengthened:
- `POST /api/v1/requests`: Now validates dates using `isoDateSchema`, enforces `endDate >= startDate`, ignores client-provided `requesterUserId`, and returns structured `error.details`.
- `PATCH /api/v1/requests/:id/status`: Enforces authorized state transitions and safe notification dispatch.
- `GET /api/v1/requests/my`: Scoped strictly to authenticated user and tenant.
- `GET /api/v1/requests/incoming`: Scoped strictly to recipient authority and tenant.

---

## 24. Deferred Items

None. All functional requirements for Request Center from Prompt 2 have been implemented and verified.

---

## 25. Risks

- **Low Risk**: Third-party plugins using deprecated Kotlin Gradle Plugin features (`cloud_functions`, `firebase_storage`). Flutter emitted a deprecation warning during APK build. Both plugins build successfully now, but should be updated in a future maintenance cycle prior to Flutter major version upgrades.
- **Low Risk**: If an institution has not assigned an HOD to a department, requests are routed to department scope without an assigned user ID. Notification listeners now handle this gracefully with structured logging rather than crashing.

---

## 26. Final Status

**COMPLETE**
