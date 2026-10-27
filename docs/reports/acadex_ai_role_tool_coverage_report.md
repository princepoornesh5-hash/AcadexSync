# ACADEX AI ASSISTANT: COMPLETE ROLE-AWARE TOOL COVERAGE, MODULE ACCESS, AND END-TO-END ACTION EXECUTION REPORT

**Date:** 2026-10-27  
**Status:** Verified & Complete  
**Engine:** Gemini 3.5 Flash / Flash Lite  
**Repository:** AcadexSync (`Campus Management Main`)  

---

## 1. Executive Summary & Root Cause Analysis

### 1.1 The Reported Failure
Users observed that the ACADEX AI Assistant consistently responded that it could not create requests because it lacked the required tools when:
- A **Student** asked the AI to create a request (e.g. sick leave).
- A **Faculty** member asked the AI to raise a sick-leave request for tomorrow.

### 1.2 Deep Forensic Root Causes Identified
Inspection of the backend architecture revealed three interconnected architectural deficiencies:
1. **Tool Declaration Gap in Registry:**
   - In [aiTools.registry.ts](file:///Users/poornesh/Campus%20Management%20Main/Backend/src/services/aiTools.registry.ts), the master declaration catalog previously contained only 6 functions: `get_my_timetable`, `get_my_assignments`, `get_calendar_events`, `get_my_requests`, `propose_create_assignment`, and `propose_create_calendar_event`.
   - There was **no function declaration** for creating requests (`propose_create_request`) or responding to requests (`propose_respond_request`). When users requested to raise a leave or change request, Gemini inspected the schema declarations, saw no matching tool, and truthfully stated that it did not have tools to create requests.
2. **Missing `PendingAction` Action Types & Execution Handlers:**
   - [pendingAction.model.ts](file:///Users/poornesh/Campus%20Management%20Main/Backend/src/models/pendingAction.model.ts) and [pendingAction.service.ts](file:///Users/poornesh/Campus%20Management%20Main/Backend/src/services/pendingAction.service.ts) only supported `'CREATE_ASSIGNMENT' | 'CREATE_CALENDAR_EVENT'`.
   - `CREATE_REQUEST` and `RESPOND_REQUEST` were completely unrecognized by the confirmation engine, preventing any proposed request from transitioning from draft to persistent database record.
3. **Static System Prompt & Lack of Dynamic Role-Filtering:**
   - [ai.service.ts](file:///Users/poornesh/Campus%20Management%20Main/Backend/src/services/ai.service.ts) presented a hardcoded system prompt that only enumerated assignment and calendar workflows, and fed the exact same static declarations to all users regardless of whether they were a Student, Faculty, HOD, College Admin, or Super Admin.

---

## 2. Complete ACADEX Capability Matrix

| Module | Operation | Authorized Roles | Authoritative Backend Service & Route | AI Tool Status | Requires Confirmation | Scoping Boundaries | Test Verification |
|---|---|---|---|---|---|---|---|
| **Identity & Profile** | Read Profile & Academic Stage | `STUDENT`, `FACULTY`, `HOD`, `COLLEGE_ADMIN`, `SUPER_ADMIN` | [ProfileService.getComposedProfile](file:///Users/poornesh/Campus%20Management%20Main/Backend/src/services/profile.service.ts)<br>`GET /api/v1/profile/me` | Implemented<br>`get_my_profile` | No (Read-only) | User session + tenant isolation | Integration Test PASS |
| **Timetable** | Read Schedule & Class Slots | `STUDENT`, `FACULTY`, `HOD`, `COLLEGE_ADMIN` | `TimetableService.getMyTimetable`<br>`GET /api/v1/timetables/me` | Implemented<br>`get_my_timetable` | No (Read-only) | Student section / Faculty teaching assignment | Integration Test PASS |
| **Coursework & Assignments** | Read Assignments & Deadlines | `STUDENT`, `FACULTY`, `HOD`, `COLLEGE_ADMIN` | [AssignmentService.getAssignmentsForUser](file:///Users/poornesh/Campus%20Management%20Main/Backend/src/services/assignment.service.ts)<br>`GET /api/v1/assignments` | Implemented<br>`get_my_assignments` | No (Read-only) | Student enrolled section / Faculty teaching assignments / Dept scope | Integration Test PASS |
| **Coursework & Assignments** | Create & Publish Assignment Draft | `FACULTY`, `HOD` | [AssignmentService.createAssignment](file:///Users/poornesh/Campus%20Management%20Main/Backend/src/services/assignment.service.ts)<br>`POST /api/v1/assignments` | Implemented<br>`propose_create_assignment` | **Yes (PendingAction)** | Strict FacultyAssignment validation; Student blocked with 403 | Integration Test PASS |
| **Academic Calendar** | Read Events, Holidays, Deadlines | `STUDENT`, `FACULTY`, `HOD`, `COLLEGE_ADMIN`, `SUPER_ADMIN` | [AcademicCalendarService.getCalendarForUser](file:///Users/poornesh/Campus%20Management%20Main/Backend/src/services/academicCalendar.service.ts)<br>`GET /api/v1/calendar` | Implemented<br>`get_calendar_events` | No (Read-only) | College-wide, department, course, section derived hierarchy | Integration Test PASS |
| **Academic Calendar** | Schedule Calendar Event | `FACULTY`, `HOD`, `COLLEGE_ADMIN`, `SUPER_ADMIN` | [AcademicCalendarService.createEvent](file:///Users/poornesh/Campus%20Management%20Main/Backend/src/services/academicCalendar.service.ts)<br>`POST /api/v1/calendar/events` | Implemented<br>`propose_create_calendar_event` | **Yes (PendingAction)** | Room conflict check + role scope check | Integration Test PASS |
| **Attendance** | Read Personal Attendance Metrics | `STUDENT`, `FACULTY`, `HOD`, `COLLEGE_ADMIN` | `AttendanceAggregationService`<br>`GET /api/v1/attendance/my-summary` | Implemented<br>`get_my_attendance` | No (Read-only) | Student self / Faculty assigned sections | Integration Test PASS |
| **Study Materials & Notes** | View Published Notes | `STUDENT`, `FACULTY`, `HOD`, `COLLEGE_ADMIN` | [NoteService.listNotes](file:///Users/poornesh/Campus%20Management%20Main/Backend/src/services/note.service.ts)<br>`GET /api/v1/notes` | Implemented<br>`get_published_notes` | No (Read-only) | Section & subject enrollment | Integration Test PASS |
| **Requests & Approvals** | View Personal Outgoing Requests | `STUDENT`, `FACULTY`, `HOD`, `COLLEGE_ADMIN`, `SUPER_ADMIN` | [RequestService.listMyRequests](file:///Users/poornesh/Campus%20Management%20Main/Backend/src/services/request.service.ts)<br>`GET /api/v1/requests/my` | Implemented<br>`get_my_requests` | No (Read-only) | User session + tenant isolation | Integration Test PASS |
| **Requests & Approvals** | View Incoming Requests for Review | `FACULTY`, `HOD`, `COLLEGE_ADMIN`, `SUPER_ADMIN` | [RequestService.listIncomingRequests](file:///Users/poornesh/Campus%20Management%20Main/Backend/src/services/request.service.ts)<br>`GET /api/v1/requests/incoming` | Implemented<br>`get_incoming_requests` | No (Read-only) | Targeted authority / Department / College Admin scope | Integration Test PASS |
| **Requests & Approvals** | Create Leave / Operational Request Draft | `STUDENT`, `FACULTY`, `HOD`, `COLLEGE_ADMIN`, `SUPER_ADMIN` | [RequestService.createRequest](file:///Users/poornesh/Campus%20Management%20Main/Backend/src/services/request.service.ts)<br>`POST /api/v1/requests` | Implemented<br>`propose_create_request` | **Yes (PendingAction)** | Authoritative target routing via `RequestService.resolveTarget` | Integration Test PASS |
| **Requests & Approvals** | Review & Respond to Request (Approve/Reject) | `FACULTY` (if targeted), `HOD`, `COLLEGE_ADMIN`, `SUPER_ADMIN` | [RequestService.respondToRequest](file:///Users/poornesh/Campus%20Management%20Main/Backend/src/services/request.service.ts)<br>`POST /api/v1/requests/:id/respond` | Implemented<br>`propose_respond_request` | **Yes (PendingAction)** | Non-self responder check, valid status transitions | Integration Test PASS |
| **Announcements** | Read Institutional Bulletins | `STUDENT`, `FACULTY`, `HOD`, `COLLEGE_ADMIN`, `SUPER_ADMIN` | [AnnouncementService.listAnnouncements](file:///Users/poornesh/Campus%20Management%20Main/Backend/src/services/announcement.service.ts)<br>`GET /api/v1/announcements` | Implemented<br>`get_announcements` | No (Read-only) | College isolation + target audiences | Integration Test PASS |
| **Reports & Dashboards** | View Institutional Analytics & Metrics | `FACULTY`, `HOD`, `COLLEGE_ADMIN`, `SUPER_ADMIN` | [ReportService.getDashboard](file:///Users/poornesh/Campus%20Management%20Main/Backend/src/services/report.service.ts)<br>`GET /api/v1/reports/dashboard` | Implemented<br>`get_reports_dashboard` | No (Read-only) | Faculty teaching / Dept / College level; Denied to Student | Integration Test PASS |

---

## 3. Final Role-to-Tool Registry

Declarations delivered to Gemini are deterministically filtered by `getFunctionDeclarationsForRole(role)` and enforced at execution time by `AiToolsRegistry.roleAllowedTools[role]`:

### 3.1 STUDENT (9 Tools)
- `get_my_profile`: View personal academic record, roll number, admission number, cohort, and active enrollment.
- `get_my_timetable`: View weekly class timetable, period targets (first, last, next), and room locations.
- `get_my_assignments`: View coursework, homework, submissions, and deadlines.
- `get_calendar_events`: View college events, holidays, examinations, and derived assignment deadlines.
- `get_my_attendance`: View personal subject-wise and overall attendance percentage and session metrics.
- `get_published_notes`: Retrieve published study materials and lecture notes.
- `get_my_requests`: View status and audit timeline of personal submitted requests.
- `get_announcements`: View active campus announcements and circulars.
- `propose_create_request`: Draft authorized student requests (`LEAVE`, `ATTENDANCE_CORRECTION`, `ACADEMIC_ISSUE`, `GENERAL_REQUEST`, `DOCUMENT_REQUEST`).
- **Forbidden / Stripped:** Assignment creation, calendar event creation, request review/response, incoming requests, institutional report dashboards.

### 3.2 FACULTY (14 Tools)
- `get_my_profile`: View faculty profile, designation, qualifications, and active teaching assignments.
- `get_my_timetable`: View teaching timetable, assigned rooms, subjects, and periods.
- `get_my_assignments`: View assignments published by the faculty member across assigned classes.
- `get_calendar_events`: View academic schedule and college calendar.
- `get_my_attendance`: View teaching session attendance stats.
- `get_published_notes`: View published notes.
- `get_my_requests`: View own leave / on-duty / permission requests.
- `get_incoming_requests`: View incoming requests directed to the faculty member.
- `get_announcements`: View campus announcements.
- `get_reports_dashboard`: View faculty analytics, student performance, and submission rates.
- `propose_create_request`: Draft faculty requests (`LEAVE`, `ON_DUTY`, `PERMISSION`, `TIMETABLE_CHANGE`, `RESOURCE_REQUEST`).
- `propose_create_assignment`: Draft and configure assignments for assigned subjects and sections.
- `propose_create_calendar_event`: Draft academic calendar events within faculty scope.
- `propose_respond_request`: Draft review decisions for requests assigned to the faculty member.

### 3.3 HOD (Department Head - 14 Tools)
- Includes all Faculty read and write tools scoped to the department.
- Authoritatively acts as reviewer for department faculty requests and student departmental leave requests.
- `propose_respond_request`: Decision proposals (`APPROVED`, `REJECTED`, `RESOLVED`) with mandatory rejection reasons and remarks.
- `get_reports_dashboard`: Department-wide attendance, faculty activity, and coursework progress.

### 3.4 COLLEGE_ADMIN (Principal / Administrator - 13 Tools)
- College-wide academic intelligence across all departments, courses, and sections.
- College calendar event creation and administrative broadcast announcements.
- Final approval workflows for college-level requests.
- `get_reports_dashboard`: Institutional executive dashboard.

### 3.5 SUPER_ADMIN (Platform Administrator - 9 Tools)
- Multi-tenant oversight without bypassing college tenant boundaries.
- Platform analytics, system announcements, and governance requests.

---

## 4. Request Creation Architecture: Student & Faculty

### 4.1 Resolution of "Tomorrow" in India Standard Time (IST)
Indian academic institutions operate under IST (`UTC+05:30` / `Asia/Kolkata`).
- Relative dates like `"tomorrow"`, `"today"`, and `"yesterday"` are resolved using `Intl.DateTimeFormat('en-CA', { timeZone: 'Asia/Kolkata' })`.
- This avoids timezone drift bugs where evening requests (e.g., 10:00 PM IST) might resolve to the wrong calendar date in UTC.

### 4.2 Authoritative Target Routing
Neither the client nor the AI model selects the approval destination:
- In `RequestService.resolveTarget(user, input)`, routing rules are strictly enforced:
  - **Student Leave Requests** route directly to the HOD of the student's enrolled department (`dept.hodId`). If no HOD is assigned, they route to College Administration.
  - **Faculty Leave & On-Duty Requests** route to their department's HOD.
  - **HOD Requests** route to College Administration / Principal.
  - **Document & Administrative Requests** route to College Administration.

### 4.3 Two-Phase Confirmed Writes
1. **Draft Proposal Phase (`propose_create_request`):**
   - AI validates request type permissions against `ALLOWED_REQUEST_TYPES_BY_ROLE`.
   - Date bounds and mandatory reasons are inspected.
   - Authoritative routing resolves `targetRole`, `targetUserId`, and `targetName`.
   - Creates an immutable record in `PendingAction` with `status: 'PENDING'` and a 10-minute expiry (`expiresAt`).
   - Generates a preview payload returned to the UI.
   - **Crucially, zero records are inserted into `RequestModel` at this stage.**
2. **Execution Confirmation Phase (`/api/v1/ai/action/confirm`):**
   - Replays are rejected via `idempotencyKey`.
   - Action ownership (`userId`) and tenant context (`collegeId`) are checked.
   - Authoritative `RequestService.createRequest` persists the document into MongoDB with status `SUBMITTED`.
   - An immutable audit trail entry is logged in `AuditLog` (`AI_CREATE_REQUEST_CONFIRMED`).

---

## 5. Frontend UI/UX Integration (Flutter)

1. **Proposal Card Component:**
   - In [ai_proposal_card.dart](file:///Users/poornesh/Campus%20Management%20Main/Frontend/lib/features/ai_assistant/presentation/widgets/ai_proposal_card.dart):
     - Added specialized card visuals for `CREATE_REQUEST` (Teal `#0D9488` ribbon, `LucideIcons.fileText`, metadata rows for Request Category, Target Authority, Requested Dates, Reason, and Details).
     - Added specialized card visuals for `RESPOND_REQUEST` (Amber `#D97706` ribbon, `LucideIcons.checkSquare`, Request ID, Decision, and Remarks).
2. **State Management & Action Lifecycle:**
   - In [ai_providers.dart](file:///Users/poornesh/Campus%20Management%20Main/Frontend/lib/features/ai_assistant/presentation/providers/ai_providers.dart):
     - Handled `CREATE_REQUEST` and `RESPOND_REQUEST` confirmation flows, transitioning cards from `PENDING` to `EXECUTED`.
     - Integrated network timeout reconciliation (`reconcileActionStatus`) that queries server status without creating duplicates.

---

## 6. Verification & Test Evidence

### 6.1 Backend Integration Tests
```bash
npx jest tests/integration/ai_chat.test.ts --runInBand --forceExit
```
**Results:**
- **Test Suites:** 1 passed, 1 total
- **Tests:** 44 passed, 44 total (100% pass rate)
- **Execution Time:** ~11.2s
- **Exit Code:** 0

**Key Verified Scenarios:**
- Student requesting timetable, assignments, calendar, notes, profile, attendance, and announcements.
- Student creating sick-leave request for "tomorrow" -> proposed draft -> verified 0 records before confirmation -> confirmed -> persisted in MongoDB `RequestModel` with status `SUBMITTED` and routed to HOD.
- Faculty creating sick-leave / on-duty request for "tomorrow" -> proposed draft -> confirmed -> persisted in MongoDB `RequestModel` routed to HOD.
- HOD reviewing student leave request -> proposed `RESPOND_REQUEST` -> confirmed -> updated status `APPROVED` with response remarks.
- Role boundary enforcement: Student attempting to invoke `propose_create_assignment` or `get_reports_dashboard` is rejected with access-denied error; no proposal generated.
- Cross-tenant rejection: Users from another college attempting to confirm pending actions or chat are blocked with 403 Forbidden.
- Idempotency & replay protection: Duplicate confirmation attempts return cached results without double-persisting.

### 6.2 Backend TypeScript Typecheck
```bash
npm run typecheck
```
- **Result:** `tsc --noEmit` exited with code 0 (Zero errors across all files).

### 6.3 Real Gemini API Smoke Test
```bash
npm run test:gemini-smoke
```
- **Configured Model:** `gemini-3.5-flash-lite`
- **Result:** PASSED - Real Gemini API connectivity verified! (`Model Output: "ACADEX Gemini Live Connection Verified"`, exit code 0).

### 6.4 Flutter Analysis & Tests
```bash
flutter analyze lib/features/ai_assistant
flutter test test/ai_proposal_and_startup_test.dart test/ai_assistant_workflow_test.dart
```
- **Analysis Result:** `No issues found! (ran in 2.3s)`
- **Test Result:** `All 17 tests passed! (exit code 0)`

---

## 7. Unsupported / Restricted Operations by Design

To maintain institutional compliance and data security, certain operations are intentionally restricted:
1. **Student Coursework Mutation:** Students cannot create assignments, grade submissions, or modify marks. Attempts result in explicit access-denied messages.
2. **Direct Attendance Mutation:** Attendance sessions require physical/QR/biometric verification under period restrictions; the AI assistant provides attendance viewing and analytics, while attendance correction goes through formal `ATTENDANCE_CORRECTION` requests.
3. **Cross-College Data Queries:** The AI assistant enforces strict multi-tenant isolation; requests never query across college boundaries even if an attacker manipulates headers.
4. **Self-Review Prevention:** Requesters cannot approve or reject their own requests.

---

## 8. Summary of Files Changed

- [Backend/src/services/aiTools.registry.ts](file:///Users/poornesh/Campus%20Management%20Main/Backend/src/services/aiTools.registry.ts): Added function declarations for requests, notes, reports, and attendance; added `getFunctionDeclarationsForRole`; implemented tool execution with IST date resolution and role checks.
- [Backend/src/services/ai.service.ts](file:///Users/poornesh/Campus%20Management%20Main/Backend/src/services/ai.service.ts): Dynamic role-aware declarations in `generateChatResponse` and `streamChatResponse`; updated system prompt instructions.
- [Backend/src/models/pendingAction.model.ts](file:///Users/poornesh/Campus%20Management%20Main/Backend/src/models/pendingAction.model.ts): Expanded schema enum to support `CREATE_REQUEST` and `RESPOND_REQUEST`.
- [Backend/src/services/pendingAction.service.ts](file:///Users/poornesh/Campus%20Management%20Main/Backend/src/services/pendingAction.service.ts): Added execution branches for request creation and response.
- [Backend/src/services/request.service.ts](file:///Users/poornesh/Campus%20Management%20Main/Backend/src/services/request.service.ts): Exposed `resolveTarget` method for authoritative AI tool target routing.
- [Backend/src/scripts/gemini-smoke-test.ts](file:///Users/poornesh/Campus%20Management%20Main/Backend/src/scripts/gemini-smoke-test.ts): Fixed error handling variable scope.
- [Backend/tests/integration/ai_chat.test.ts](file:///Users/poornesh/Campus%20Management%20Main/Backend/tests/integration/ai_chat.test.ts): Added 9 comprehensive role-aware integration tests.
- [Frontend/lib/features/ai_assistant/presentation/widgets/ai_proposal_card.dart](file:///Users/poornesh/Campus%20Management%20Main/Frontend/lib/features/ai_assistant/presentation/widgets/ai_proposal_card.dart): Integrated proposal cards for requests and decisions.
- [Frontend/lib/features/ai_assistant/presentation/providers/ai_providers.dart](file:///Users/poornesh/Campus%20Management%20Main/Frontend/lib/features/ai_assistant/presentation/providers/ai_providers.dart): Added action lifecycle and confirmation reconciliation for request workflows.
