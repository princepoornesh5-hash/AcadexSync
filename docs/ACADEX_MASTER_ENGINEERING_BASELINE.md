# ACADEX MASTER SYSTEM AUDIT & ENGINEERING BASELINE
**Authoritative Architectural Baseline for Future Vertical Slices**
*Generated: September 2026 | Environment: Node.js/TypeScript + MongoDB Atlas + Flutter/Riverpod*

---

## EXECUTIVE SUMMARY

This audit establishes the definitive, permanent engineering baseline for **ACADEX** prior to module-by-module development. The ACADEX platform has evolved into an enterprise multi-tenant institutional operating system spanning:
- **Backend**: Node.js + TypeScript + Express + Mongoose (MongoDB Atlas) with 37 database models, 21 versioned REST route controllers, 31 services, 51 integration tests, and Firebase Admin SDK / ImageKit integration.
- **Frontend**: Flutter (3.x) with 22 feature domains, Riverpod state management, Dio networking with automated JWT 401 refresh interceptors, 131 GoRouter paths, 138 widget and integration tests, and a mobile-first responsive design system.
- **AI Microservice**: Python FastAPI microservice dedicated to RAG chatbot and timetable constraint solving.

---

## 1. MASTER DOMAIN INVENTORY

The ACADEX domain model consists of 37 canonical entities in MongoDB Atlas. Each entity possesses a technical MongoDB ObjectId (`_id`) and tenant isolation via `collegeId`.

| # | Entity | Purpose | Canonical ID | Owning Tenant | Owning Role | Key Relations & Dependencies | Downstream Consumers |
|---|---|---|---|---|---|---|---|
| 1 | **College** | Tenant root for institution | `_id` | Self | `SUPER_ADMIN` | Root tenant | All modules |
| 2 | **Department** | Academic division within college | `_id` | `collegeId` | `COLLEGE_ADMIN` | College, optional HOD User | Courses, Faculty, Students |
| 3 | **Course / Program** | Degree program (e.g. B.Tech CSE) | `_id` | `collegeId` | `COLLEGE_ADMIN`, `HOD` | Department, College | Semesters, Enrollments |
| 4 | **AcademicYear** | College-wide calendar operational interval | `_id` | `collegeId` | `COLLEGE_ADMIN` | College | Semesters, Enrollments, Timetables |
| 5 | **Semester / Term** | Academic period of study | `_id` | `collegeId` | `COLLEGE_ADMIN`, `HOD` | Course, AcademicYear, Dept | Sections, Subjects, Timetable |
| 6 | **Section / Class** | Cohort division / roster container | `_id` | `collegeId` | `COLLEGE_ADMIN`, `HOD` | Semester, Course, Dept, AY | Enrollments, Assignments, Timetable |
| 7 | **Subject** | Academic curricular unit / course paper | `_id` | `collegeId` | `COLLEGE_ADMIN`, `HOD` | Semester, Dept, optional Course | FacultyAssignment, Timetable, Notes |
| 8 | **Faculty** | Institutional teaching staff profile | `_id` | `collegeId` | `COLLEGE_ADMIN`, `HOD` | User (userId), Department | FacultyAssignment, Timetable, Sessions |
| 9 | **Student** | Institutional student profile | `_id` | `collegeId` | `COLLEGE_ADMIN`, `HOD` | User (userId), Department, Section | Enrollments, Attendance, Submissions |
| 10 | **StudentEnrollment** | Term participation record binding student to section | `_id` | `collegeId` | `COLLEGE_ADMIN`, `HOD` | Student, Section, Sem, Course, AY | Attendance roll call, Student Timetable |
| 11 | **FacultyAssignment** | Authorized teaching context binding faculty to subject & section | `_id` | `collegeId` | `COLLEGE_ADMIN`, `HOD` | Faculty, Subject, Section, Sem, AY | Attendance, Timetable, Assignments, Marks |
| 12 | **Room** | Physical space / lecture hall / lab | `_id` | `collegeId` | `COLLEGE_ADMIN` | College, optional Dept | Timetable entries |
| 13 | **Timetable** | Weekly schedule container for a section | `_id` | `collegeId` | `COLLEGE_ADMIN`, `HOD` | Section, Sem, Course, AY | Faculty schedule, Student schedule |
| 14 | **TimetableGridEntry** | Individual timeslot entry in timetable | Embedded `_id` | Via Timetable | `HOD` | Subject, Faculty, FA, Room | Next class card, Attendance pre-fill |
| 15 | **TeacherSubstitution** | Temporary replacement of faculty for class | `_id` | `collegeId` | `HOD` | Timetable, Entry, Sub Faculty | Attendance auth, Daily schedule |
| 16 | **CalendarOverride** | Holiday or class cancellation on calendar | `_id` | `collegeId` | `COLLEGE_ADMIN`, `HOD` | Section, Dept, TimetableEntry | Attendance blocks, Daily schedule |
| 17 | **AttendanceSession** | Teaching session instance for roll call | `_id` | `collegeId` | `FACULTY`, `HOD` | Section, Subject, Faculty, FA, TT | Attendance analytics, Student portal |
| 18 | **AttendanceRecord** | Individual student attendance log | `_id` | `collegeId` | `FACULTY`, `HOD` | Session, Student, Section, Subject | Student history, Warning alerts, Reports |
| 19 | **Assignment** | Coursework task published to section | `_id` | `collegeId` | `FACULTY` | Subject, Section, FA, Faculty User | Submissions, Calendar deadlines |
| 20 | **AssignmentSubmission** | Student task response / review log | `_id` | `collegeId` | `STUDENT`, `FACULTY` | Assignment, Student User, Reviewer | Gradebook, Student tasks, Deadlines |
| 21 | **InternalAssessment** | Term mark ledger for subject & section | `_id` | `collegeId` | `FACULTY`, `HOD` | Subject, Section, Sem, AY, FA | Report cards, Student marks portal |
| 22 | **LabExperiment** | Practical syllabus experiment | `_id` | `collegeId` | `FACULTY` | Subject, Section, Sem, AY, FA | Lab submissions, Record books |
| 23 | **CalendarEvent** | Institutional/departmental/class calendar item | `_id` | `collegeId` | `ADMIN`, `HOD`, `FACULTY` | College, Dept, Section, User | Academic Calendar, Day timeline |
| 24 | **Announcement** | Broadcast notice with audience filtering | `_id` | `collegeId` | `ADMIN`, `HOD` | College, Dept, Target Role/Section | Notification feed, Dashboard banner |
| 25 | **Notification** | Direct per-user notification item | `_id` | `collegeId` | System / Triggers | Recipient User, Target Entity | Notification Center, FCM pushes |
| 26 | **NotificationPreference**| Granular user alert toggles | `_id` | `collegeId` | `User` (Self) | User | FCM & email dispatch logic |
| 27 | **Request** | Formal workflow application (Leave, OD, etc.) | `_id` | `collegeId` | Requester / Approver | Requester User, Target Role/User | Request Center, Approvals |
| 28 | **Note** | Academic study material with ImageKit storage | `_id` | `collegeId` | `FACULTY`, `HOD` | Subject, Semester, Course, User | Notes library, Student study portal |
| 29 | **User** | Authentication & identity entity | `_id` | `collegeId` | System / Admins | College, optional Dept/Sec | Login, RBAC, Sessions, Auditing |
| 30 | **AuthSession** | Active JWT refresh session & device tracking | `_id` | User-scoped | User (Self) | User | JWT refresh, Revocation |
| 31 | **Invitation** | 8-character token for user onboarding | `_id` | `collegeId` | `ADMIN`, `HOD` | College, Provisioned User | Activation screen, Password set |
| 32 | **Otp** | 6-digit verification code | `_id` | Platform | System | Target Email / Phone | Password recovery, Verification |
| 33 | **DeviceToken** | FCM push token registration | `_id` | `collegeId` | User (Self) | User | FCM multicast delivery |
| 34 | **AuditLog** | Immutable administrative change record | `_id` | `collegeId` | System | Actor User, Entity | Compliance, Audit screens |
| 35 | **InstitutionConfiguration** | College-specific structural & terminology rules | `_id` | `collegeId` | `COLLEGE_ADMIN` | College | Academic tree, UI terminology |

---

## 2. CANONICAL DATA DICTIONARY

```yaml
ENTITY: College
Purpose: Root institutional tenant container ensuring strict multi-tenant data boundaries.
Canonical identifier: College._id (ObjectId)
Human-facing identifier: code (e.g. "KIT", "GCT"), name
Required relationships: None (root tenant)
Optional relationships: logoUrl, address, settings
Owner: SUPER_ADMIN
Allowed mutations: Create (SuperAdmin), Update details/status (SuperAdmin, CollegeAdmin)
Lifecycle: active -> inactive
Historical behavior: Permanent root. Deactivation suspends college operations.
Used by: All modules, Middleware (requireCollegeScope)

ENTITY: Department
Purpose: Academic division governing subjects, faculty, courses, and students.
Canonical identifier: Department._id (ObjectId)
Human-facing identifier: code (e.g. "CSE", "MECH"), name
Required relationships: collegeId
Optional relationships: hodId (User)
Owner: COLLEGE_ADMIN
Allowed mutations: Create (CollegeAdmin), Update/Assign HOD (CollegeAdmin, SuperAdmin)
Lifecycle: active -> inactive
Historical behavior: Historical courses/faculty retain department link even if inactive.
Used by: Courses, Faculty, HOD Dashboard, Analytics, Requests

ENTITY: Course (Program)
Purpose: Academic degree specification (e.g., B.Tech Computer Science).
Canonical identifier: Course._id (ObjectId)
Human-facing identifier: code (e.g. "BTECH-CSE"), name
Required relationships: collegeId, departmentId
Optional relationships: progressionType (YEAR_SEMESTER, YEAR_ONLY, etc.)
Owner: COLLEGE_ADMIN, HOD
Allowed mutations: Create/Update (CollegeAdmin, HOD within dept)
Lifecycle: active -> inactive
Historical behavior: Referenced by past enrollments; duration dictates max semester count.
Used by: Semesters, Student Enrollments, Curriculum reports

ENTITY: AcademicYear
Purpose: Institutional calendar cycle governing an academic period.
Canonical identifier: AcademicYear._id (ObjectId)
Human-facing identifier: name (e.g. "2025–2026")
Required relationships: collegeId, startDate, endDate
Optional relationships: None
Owner: COLLEGE_ADMIN, SUPER_ADMIN
Allowed mutations: Create/Update (CollegeAdmin), Set Current (CollegeAdmin)
Lifecycle: upcoming -> active -> completed -> archived
Historical behavior: Historical enrollments and timetables remain immutable under past AY.
Used by: Semesters, Enrollments, Timetables, Attendance, Assessments

ENTITY: Semester (Term)
Purpose: Specific chronological term of study within a course and academic year.
Canonical identifier: Semester._id (ObjectId)
Human-facing identifier: name (e.g. "Semester 5", "Term 1"), number (1-12)
Required relationships: collegeId, departmentId, courseId, academicYearId
Optional relationships: startDate, endDate
Owner: COLLEGE_ADMIN, HOD
Allowed mutations: Create/Update (CollegeAdmin, HOD)
Lifecycle: upcoming -> active -> completed -> archived
Historical behavior: Once completed, attendance and internal assessments are frozen.
Used by: Sections, Subjects, Timetables, Assessments

ENTITY: Section (Class)
Purpose: Practical student grouping / class cohort container for timetable and attendance.
Canonical identifier: Section._id (ObjectId)
Human-facing identifier: name (e.g. "Section A", "CSE-3A")
Required relationships: collegeId, departmentId, courseId, semesterId
Optional relationships: academicYearId, capacity
Owner: COLLEGE_ADMIN, HOD
Allowed mutations: Create/Update (CollegeAdmin, HOD)
Lifecycle: active -> inactive -> archived
Historical behavior: Students belong to one section per semester enrollment.
Used by: StudentEnrollment, FacultyAssignment, Timetable, Attendance, Assignments

ENTITY: Subject
Purpose: Individual curriculum course/unit taught during a semester.
Canonical identifier: Subject._id (ObjectId)
Human-facing identifier: code (e.g. "CS8501"), name
Required relationships: collegeId, departmentId, semesterId
Optional relationships: courseId, credits, type ('Theory', 'Practical')
Owner: COLLEGE_ADMIN, HOD
Allowed mutations: Create/Update (CollegeAdmin, HOD)
Lifecycle: active -> inactive
Historical behavior: Referenced historically by marks, attendance, notes, and timetables.
Used by: FacultyAssignment, TimetableEntry, AttendanceSession, Notes, Assessments

ENTITY: FacultyAssignment
Purpose: Canonical operational authorization binding a faculty member to teach a subject in a section.
Canonical identifier: FacultyAssignment._id (ObjectId)
Human-facing identifier: None (Compound composite: Faculty + Subject + Section + Semester)
Required relationships: collegeId, departmentId, facultyId, courseId, semesterId, sectionId, subjectId, academicYearId
Optional relationships: cohort, academicStage, roomId, maxStudents, assignmentType
Owner: COLLEGE_ADMIN, HOD
Allowed mutations: Create/Deactivate (CollegeAdmin, HOD)
Lifecycle: active -> inactive
Historical behavior: Historical assignments identify faculty author of past marks & attendance.
Used by: TeachingAuthorizationService, Timetable, Attendance, Assignments, Assessments

ENTITY: StudentEnrollment
Purpose: Canonical record of a student actively enrolled in a specific class section for a semester.
Canonical identifier: StudentEnrollment._id (ObjectId)
Human-facing identifier: None (Unique index: collegeId + studentId + semesterId + sectionId)
Required relationships: collegeId, studentId, departmentId, courseId, academicYearId, semesterId, sectionId
Optional relationships: cohort, academicStage, enrollmentDate
Owner: COLLEGE_ADMIN, HOD, FACULTY
Allowed mutations: Create (Staff/Admin), Status change (Admin, HOD)
Lifecycle: active -> completed -> transferred -> withdrawn
Historical behavior: Historical enrollments preserve complete student academic progression.
Used by: Attendance roster verification, Student Timetable, Student Marks, Reports

ENTITY: Timetable
Purpose: Authoritative weekly schedule matrix for a section.
Canonical identifier: Timetable._id (ObjectId)
Human-facing identifier: name (e.g. "CSE-3A Fall 2026 Timetable"), version
Required relationships: collegeId, departmentId, courseId, academicYearId, semesterId, sectionId
Optional relationships: timingMode, periods, breaks, entries
Owner: HOD, COLLEGE_ADMIN
Allowed mutations: Edit entries (Draft state), Publish/Archive (HOD, CollegeAdmin)
Lifecycle: draft -> published -> archived
Historical behavior: Past versions archived upon publishing new revisions.
Used by: Attendance session launcher, NextClass cards, Student & Faculty weekly views

ENTITY: AttendanceSession
Purpose: Operational instance of a single class roll call.
Canonical identifier: AttendanceSession._id (ObjectId)
Human-facing identifier: None (Identified by sectionName + subjectName + date + timeSlot)
Required relationships: collegeId, departmentId, courseId, semesterId, sectionId, subjectId, facultyId, date, timeSlot
Optional relationships: timetableId, timetableEntryId, facultyAssignmentId, roomNumber, records (snapshot)
Owner: FACULTY (assigned or substitute), HOD, COLLEGE_ADMIN
Allowed mutations: Submit records (Open), Lock (Faculty, HOD, Admin), Close/Cancel (HOD, Admin)
Lifecycle: open -> locked -> closed | cancelled
Historical behavior: Immutable once closed. Modifications require AuditLog correction.
Used by: Attendance records, Attendance analytics, Student attendance portal, Defaulter lists

ENTITY: InternalAssessment
Purpose: Official institutional internal examination and continuous evaluation mark ledger.
Canonical identifier: InternalAssessment._id (ObjectId)
Human-facing identifier: title (e.g. "Internal Assessment 1 - Operating Systems")
Required relationships: collegeId, departmentId, courseId, academicYearId, semesterId, sectionId, subjectId
Optional relationships: facultyAssignmentId, facultyId, components, entries, auditLog
Owner: FACULTY (assigned), HOD
Allowed mutations: Enter marks (Draft: Faculty), Review (HOD), Publish (HOD, Admin)
Lifecycle: DRAFT -> REVIEWED -> PUBLISHED
Historical behavior: Immutable once published. Visible to students only post-publication.
Used by: Student marks portal, Faculty grading, Semester grade calculation

ENTITY: Request
Purpose: Multi-role operational application & approval mechanism (Leave, On-Duty, Attendance dispute).
Canonical identifier: Request._id (ObjectId)
Human-facing identifier: requestId (e.g. "REQ-2026-00412")
Required relationships: collegeId, requesterUserId, requesterRole, targetRole, requestType, title, description
Optional relationships: departmentId, targetUserId, academicContext, details, history
Owner: Requester (author), Target Role/User (approver)
Allowed mutations: Create (Requester), Respond/Approve/Reject (Target Role), Cancel (Requester)
Lifecycle: submitted -> in_review -> approved | rejected | cancelled
Historical behavior: Complete immutable audit log retained in history array.
Used by: Request Center, HOD approvals, Admin dashboard, Notification triggers
```

---

## 3. SOURCE-OF-TRUTH MAP

To prevent data drift and competing states, canonical authority is assigned as follows:

| Business Domain | Canonical Source of Truth | Secondary / Denormalized Consumers | Redundancy Status & Protection Rule |
|---|---|---|---|
| **User Identity & Auth** | `User` collection (`_id`, `instituteId`, `role`, `accountStatus`) | `Faculty.userId`, `Student.userId`, Auth Tokens | Canonical `User` is truth. `instituteId` is human ID. Token carries cached snapshot. |
| **Faculty Teaching Profile** | `Faculty` collection (`_id`, `employeeId`, `departmentId`) | `User.departmentId`, `Faculty.subjectIds` | `Faculty.subjectIds` is an unversioned denormalized array and should NEVER override `FacultyAssignment`. |
| **Student Academic Standing** | `StudentEnrollment` (`sectionId`, `semesterId`, `status: 'active'`) | `Student.sectionId`, `Student.semesterId`, `User.sectionId` | `StudentEnrollment` is the ONLY valid source of enrollment truth. `Student.sectionId` is a convenience pointer. |
| **Teaching Authorization** | `FacultyAssignment` (`facultyId`, `subjectId`, `sectionId`, `isActive`) | `TimetableGridEntry.facultyAssignmentId`, `Assignment.facultyAssignmentId` | Handled authoritatively via `TeachingAuthorizationService`. Client IDs ignored. |
| **Scheduled Class Grid** | `Timetable.entries` (where `Timetable.status = 'published'`) | Mobile Dashboard `NextClassCard`, Daily timeline | `Timetable` is truth. Daily instances merge `TeacherSubstitution` & `CalendarOverride`. |
| **Operational Class Adjustments** | `TeacherSubstitution` & `CalendarOverride` | Attendance validation, Daily schedule views | Overrides live published timetable entry without altering underlying template. |
| **Attendance Records** | `AttendanceRecord` documents (individual) + `AttendanceSession.records` (snapshot) | Student summaries, Defaulter alerts, Reports | Dual-write on submission. `AttendanceRecord` is truth for aggregates; session is truth for roll call audit. |
| **Assignment Deadlines** | `Assignment.dueDateTime` | Calendar views, Student task dashboard | Calendar does NOT duplicate deadlines in DB; derived dynamically on query. |
| **Continuous Evaluation Marks** | `InternalAssessment.entries` | Report cards, Student performance charts | Embedded entries with audit log are truth. Once published, visible to students. |
| **Broadcast Notices** | `Announcement` | Role dashboards, Mobile announcement feeds | Canonical announcement source. Feeds filter by audienceScope. |
| **Personal Alerts** | `Notification` | NotificationCenter inbox, Unread counters | Canonical personal alert truth. Unread count computed directly via index. |
| **Document Storage** | ImageKit Storage Metadata + `Note` / `Assignment.attachments` | Flutter cached file downloaders | Secure signed upload token issued by backend; download URL verified on demand. |
| **College Configuration & Terms** | `InstitutionConfiguration` | `TerminologyHelper`, Screen labels, Structure guards | All UI labels & structure switches derive from `institutionConfigProvider`. |

---

## 4. ACADEMIC HIERARCHY MAP

### Implemented Academic Hierarchy
```
College (Tenant Root)
  └── Department (CSE, ECE, MECH)
        ├── Course / Program (B.Tech CSE, M.Tech AI)
        │     └── Semester / Term (Semester 1 to 8)
        │           ├── Section / Class (Section A, Section B) [Optional via Config]
        │           │     ├── StudentEnrollment (Student ↔ Section)
        │           │     └── FacultyAssignment (Faculty ↔ Subject ↔ Section)
        │           │           ├── Timetable (Weekly Grid Template)
        │           │           ├── AttendanceSession & AttendanceRecords
        │           │           ├── Assignments & Submissions
        │           │           └── InternalAssessment (Ledger)
        │           └── Subject (Operating Systems, Data Structures)
        └── AcademicYear (2025–2026) [College-wide Calendar Anchor]
```

### Deviations & Nuance Analysis
1. **Academic Year vs Cohort/Batch**:
   - `AcademicYear` is college-scoped calendar time (e.g. June 2025 – May 2026), NOT a student cohort.
   - `Cohort` (e.g. "2023–27") is currently modeled as an optional string attribute on `Student`, `StudentEnrollment`, and `FacultyAssignment`. There is no separate `Cohort` collection in MongoDB.
   - *Status*: Intentional lightweight design, but UI occasionally uses "Batch" when referring to Section.
2. **Optional Sections**:
   - `InstitutionConfiguration.academicStructure.section` can be set to `false` (e.g., in Polytechnic institutions).
   - *Architectural Defect*: Mongoose schemas for `FacultyAssignment`, `StudentEnrollment`, and `Timetable` require `sectionId: { required: true }`. In institutions where sections are disabled, creation fails unless a dummy/default section is provisioned.
3. **Academic Stage**:
   - Derived mathematically on enrollment: `Math.ceil(semester.number / 2)` (e.g. Semester 5 → "3rd Year").

---

## 5. ROLE & AUTHORIZATION MATRIX

ACADEX enforces a 5-tier role hierarchy: `SUPER_ADMIN` (100) > `COLLEGE_ADMIN` (80) > `HOD` (60) > `FACULTY` (40) > `STUDENT` (20).

| Module / Operation | Super Admin | College Admin | HOD (Dept Scoped) | Faculty | Student |
|---|---|---|---|---|---|
| **Colleges**: Create / Edit | Full | Forbidden | Forbidden | Forbidden | Forbidden |
| **Departments**: Create / Assign HOD | Full | Own College | Forbidden | Forbidden | Forbidden |
| **Courses & Academic Years**: Manage | Full | Own College | View / Create (Course) | View | View Enrolled |
| **Semesters & Sections**: Manage | Full | Own College | Own Department | View | View Enrolled |
| **Subjects**: Create / Edit | Full | Own College | Own Department | View Assigned | View Enrolled |
| **Faculty Assignments**: Allocate | Full | Own College | Own Department | View Own Classes | Forbidden |
| **Student Enrollment**: Allocate | Full | Own College | Own Department | Section Roster | View Own |
| **Users / Directory**: Provision / Status | Platform-wide | Own College | View Dept Users | Forbidden | Forbidden |
| **Rooms**: Create / Edit | Full | Own College | View | View | View |
| **Timetable**: Create / Edit / Publish | Full | Own College | Own Department | View Own / Classes | View Enrolled |
| **Teacher Substitution**: Assign | Full | Own College | Own Department | View Own | View Class TT |
| **Calendar Overrides**: Declare Holiday | Full | Own College | Own Department | View | View |
| **Attendance**: Mark / Submit Session | Full | Override | Override (Dept) | Assigned Class Only | Forbidden |
| **Attendance**: Lock / Close Session | Full | Own College | Own Department | Lock Own Only | Forbidden |
| **Attendance**: Correct Past Record | Full | Own College | Own Department | Forbidden | Forbidden |
| **Assignments**: Create / Publish | Full | View | View / Dept | Assigned FA Only | Forbidden |
| **Assignments**: Submit Response | Forbidden | Forbidden | Forbidden | Forbidden | Enrolled Only |
| **Assignments**: Review & Grade | Full | View | View Dept | Creator FA Only | View Own |
| **Internal Assessment**: Entry | Full | View | Review / Dept | Assigned FA Only | Forbidden |
| **Internal Assessment**: Publish | Full | Own College | Own Department | Forbidden | View Published |
| **Notes / Materials**: Upload | Full | View | Own Department | Assigned Subject | View Enrolled |
| **Announcements**: Broadcast | Platform | College-wide | Department-wide | Forbidden | Forbidden |
| **Request Center**: Submit | Forbidden | Forbidden | To Admin | To HOD / Admin | To Faculty/HOD |
| **Request Center**: Approve / Reject | Full | Own College | Department Requests | Student Requests | Forbidden |
| **Audit Logs**: Inspect | Platform-wide | Own College | Forbidden | Forbidden | Forbidden |
| **Institutional Config**: Edit | Full | Own College | Forbidden | Forbidden | Forbidden |

---

## 6. FACULTY OWNERSHIP RULE AUDIT

The rule mandates: *A faculty member is authorized to mark attendance, author assignments, grade submissions, and enter internal marks ONLY within teaching contexts where they hold an active `FacultyAssignment` or active `TeacherSubstitution`.*

### Current Verification & Gap Report
1. **Assignment Center**: ✅ Authoritative enforcement via `TeachingAuthorizationService.assertFacultyAssignmentAccess()` and `assertAssignmentAccess()`. Cross-faculty mutation is rejected with `403 Forbidden`.
2. **Internal Assessment**: ✅ Authoritative enforcement via `TeachingAuthorizationService.assertSubjectSectionAccess()`.
3. **Lab Experiments**: ✅ Authoritative enforcement via `TeachingAuthorizationService.assertSubjectSectionAccess()`.
4. **Attendance Marking**: ⚠️ Partial implementation:
   - `attendance.service.ts` validates `FacultyAssignment` and `TeacherSubstitution`, but duplicates logic rather than reusing `TeachingAuthorizationService`.
   - When an unassigned faculty submits attendance for an unallocated timeslot, rejection occurs, but fallback matching logic is complex.
5. **Notes Management**: ❌ GAP:
   - `note.service.ts` only verifies `authorUserId === requester.id`. It does NOT verify whether the faculty actually teaches that subject. Any faculty in a college can upload or edit notes for any department's subjects.
6. **Security Hazard in `TeachingAuthorizationService`**: ⚠️
   - Lines 65-70 contain: `if (user.name.trim().toLowerCase() === fa.facultyName.trim().toLowerCase()) return true;`
   - *Risk*: Matching ownership by loose name string enables authorization spoofing if two staff share similar names.

---

## 7. CONFIGURATION MAP

The College Admin configuration lives in `InstitutionConfiguration`:
- **Institution Presets**: `ENGINEERING`, `POLYTECHNIC`, `ARTS_AND_SCIENCE`, `UNIVERSITY`, `CUSTOM`.
- **Academic Structure Switches**:
  - `program` (default: true)
  - `academicYear` (default: true)
  - `semester` (default: true)
  - `section` (default: true; disabled in Polytechnic)
  - `subject` (default: true)
  - `building` (default: true)
  - `room` (default: true)
- **Custom Terminology Dictionary**: Singular and plural names for each academic concept.
- **Attendance Alerts Configuration**: Warning threshold (75%), Critical threshold (65%), Absence notifications enabled.
- **Assessment Configuration**: Max total marks (50), Allow decimals (false), Require HOD approval (false), Components list.

### Configuration Consumers & UI Gaps
- **Adherent Modules**: Academic Structure screens, ContextProgramSelector, Timetable setup, TimetableClassEditorDialog, HOD Dashboard, Navigation titles.
- **Defective / Non-Adherent Modules**:
  - **Attendance Screens**: Hardcode "Section", "Subject", "Semester".
  - **Notes Library**: Hardcodes "Subject", "Semester".
  - **Assessments**: Hardcodes "Internal Test", "Semester".
  - **User Management**: Hardcodes "Department", "Section".
  - **Backend Mongoose Schemas**: Require `sectionId` as mandatory even when `academicStructure.section = false`.

---

## 8. REQUIRED VS OPTIONAL DEPENDENCY GRAPH

```
[College] (Tenant Root)
   │
   ├─► [User] (College Admin / Staff)
   │     │
   │     ├─► [Department] (Core Required)
   │     │     │
   │     │     ├─► [Course] (Core Required)
   │     │     │     │
   │     │     │     └─► [AcademicYear] (Core Required)
   │     │     │           │
   │     │     │           └─► [Semester] (Core Required)
   │     │     │                 │
   │     │     │                 ├─► [Subject] (Core Required)
   │     │     │                 │
   │     │     │                 └─► [Section] (Contextual Required: if section=true)
   │     │     │                       │
   │     │     │                       ├─► [FacultyAssignment] (Core Operational)
   │     │     │                       │     │
   │     │     │                       │     ├─► [Timetable] (Recommended)
   │     │     │                       │     │     └─► [Room] (Optional)
   │     │     │                       │     │
   │     │     │                       │     ├─► [AttendanceSession] (Core Operational)
   │     │     │                       │     │
   │     │     │                       │     ├─► [Assignment] (Optional Module)
   │     │     │                       │     │
   │     │     │                       │     └─► [InternalAssessment] (Optional Module)
   │     │     │                       │
   │     │     │                       └─► [StudentEnrollment] (Core Operational)
   │     │     │
   │     │     └─► [Notes] (Optional Curricular Resource)
   │     │
   │     └─► [Requests] & [Announcements] (Optional Institutional Operations)
```

---

## 9. LIFECYCLE & STATE INVENTORY

| Entity | Supported Lifecycle States | Transition Rules & Allowed Actors | Visibility Rules |
|---|---|---|---|
| **User Account** | `pending_activation` → `active` → `deactivated` | Admin provisions → User activates with OTP → Admin deactivates | Pending accounts cannot access API |
| **Invitation** | `pending` → `used` \| `expired` \| `revoked` | Admin issues → User redeems on activation → Admin revokes | Secret code one-time use |
| **Academic Year** | `upcoming` → `active` → `completed` → `archived` | CollegeAdmin transitions; only 1 can be `isCurrent` | Past years view-only |
| **Semester** | `upcoming` → `active` → `completed` → `archived` | Admin/HOD transitions | Inactive semesters hide active roll call |
| **Section** | `active` → `inactive` → `archived` | Admin/HOD toggle | Inactive sections reject attendance creation |
| **Timetable** | `draft` → `published` → `archived` | HOD drafts → HOD publishes → Superseded on next publish | Students & Faculty only see `published` |
| **Attendance Session** | `open` → `locked` → `closed` \| `cancelled` | Faculty marks → Faculty locks → Admin/HOD closes | Records visible immediately to enrolled students |
| **Attendance Record** | `present`, `absent`, `late`, `excused`, `medicalLeave`, `onDuty`, `holiday` | Marked in session; corrected only by HOD/Admin with audit reason | Visible in student history |
| **Assignment** | `draft` → `published` → `closed` → `archived` | Faculty authors → Faculty publishes → Deadline closes | Students only see `published` |
| **Assignment Submission** | `pending` → `completed` → `reviewed` | Student completes task → Faculty grades with marks & feedback | Students see marks once reviewed |
| **Internal Assessment** | `DRAFT` → `REVIEWED` → `PUBLISHED` | Faculty enters marks → HOD reviews → HOD/Admin publishes | Students only see `PUBLISHED` |
| **Lab Experiment** | `pending` → `submitted` → `verified` → `graded` | Student submits → Faculty verifies observation, record, viva | Student sees running lab grade |
| **Note** | `PENDING_UPLOAD` → `UPLOADED` → `READY` → `PUBLISHED` | ImageKit upload completes → Faculty publishes | Students view only `READY` + `PUBLISHED` |
| **Request** | `submitted` → `in_review` → `approved` \| `rejected` \| `cancelled` | Requester submits → Approver acts → Requester can cancel before response | Requester and target approvers only |
| **Announcement** | `draft` → `published` \| `expired` \| `archived` | Admin/HOD schedules/publishes | Visible to targeted audience |

---

## 10. CROSS-MODULE DEPENDENCY GRAPH

```
[College Setup & Config]
        │
        ▼
[Academic Foundation] (Dept, Course, AY, Semester)
        │
        ▼
[Academic Structure] (Section, Subject, Room)
        │
        ▼
[People & Allocation] (Faculty, Student, FacultyAssignment, StudentEnrollment)
        │
        ├──► [Timetable Engine] (Generates weekly grid & class slots)
        │          │
        │          ▼
        ├──► [Attendance Engine] (Consumes FA, Enrollment, Timetable, Overrides, Substitutions)
        │
        ├──► [Assignment Center] (Consumes FA, Section roster; outputs Submissions)
        │
        ├──► [Internal Assessment] (Consumes FA, Subject, Section, AssessmentConfig)
        │
        ├──► [Academic Notes] (Consumes Subject, Section, ImageKit storage)
        │
        └─► [Academic Calendar] (Dynamically aggregates Overrides, TT slots, Assignment deadlines)
```

---

## 11. UI / INFORMATION ARCHITECTURE INVENTORY

### Navigation Architecture
- **Mobile Navigation**: Role-adaptive 5-destination bottom navigation bar:
  - 4 primary tabs (e.g. Home, Academics, Attendance, Notes) + 1 'More' tab opening a modal drawer.
- **Tablet Navigation**: Left vertical `AcadexNavRail`.
- **Desktop Navigation**: Persistent grouped sidebar drawer (`AcadexDrawer`) organized into `WORKSPACE`, `ACADEMICS`, `OPERATIONS`, `INSIGHTS`, `SYSTEM`.

### Primary Route Catalog (131 Registered Routes)
- **Auth**: `/login`, `/activate`, `/forgot-password`, `/otp-verification`, `/reset-password`, `/change-password`, `/access-restricted`.
- **Dashboards**: `/dashboard/super_admin`, `/dashboard/college_admin`, `/dashboard/hod`, `/dashboard/faculty`, `/dashboard/student`.
- **Academic Structure**:
  - `/academics`, `/academics/setup`, `/academics/colleges`, `/academics/departments`, `/academics/courses`, `/academics/academic_years`, `/academics/semesters`, `/academics/sections`, `/academics/subjects`, `/academics/rooms`, `/academics/hods`, `/academics/faculty`, `/academics/students`, `/faculty-assignments`, `/my-assignments`, `/faculty-workload`.
- **Attendance**:
  - `/attendance`, `/attendance/mark`, `/attendance/sessions`, `/attendance/analytics`, `/attendance/reports`, `/attendance/sessions/:id`.
- **Timetable**:
  - `/timetable`, `/timetable/manage`, `/timetable/designer`, `/timetable/setup`.
- **Assessments & Assignments**:
  - `/assignments`, `/assignments/new`, `/assignments/:id`, `/assignments/:id/review`, `/assessments`, `/assessments/entry`, `/assessments/my-marks`.
- **Notes & Library**:
  - `/notes`, `/notes/new`, `/notes/:id`, `/notes/edit/:id`.
- **Operations & Communications**:
  - `/requests`, `/announcements`, `/notifications`, `/calendar`, `/analytics`, `/users`, `/profile`, `/settings`, `/institution-config`, `/ai-assistant`.

---

## 12. REDUNDANCY REGISTER

| Priority | Category | Redundancy Description | Existing Files / Schemas | Recommended Engineering Action |
|---|---|---|---|---|
| **P1** | **Data** | `Faculty.subjectIds` & `Faculty.sectionIds` duplicate `FacultyAssignment` records | `faculty.model.ts`, `academic.service.ts` | Deprecate array; derive subject assignments solely via `FacultyAssignment`. |
| **P1** | **Data** | Current academic pointers on `Student` (`sectionId`, `semesterId`) duplicate `StudentEnrollment` | `student.model.ts`, `studentEnrollment.model.ts` | Treat `StudentEnrollment` as sole authoritative truth; synchronize pointers via hook. |
| **P1** | **UI** | 131 individual `GoRoute` entries manually wrap screens in `ShellWrapper` | `app_router.dart` | Refactor to standard `StatefulShellRoute.indexedStack` to preserve state. |
| **P2** | **Data** | Embedded `AttendanceSession.records` duplicates `AttendanceRecord` collection | `attendanceSession.model.ts`, `attendanceRecord.model.ts` | Maintain dual-write as intentional read-cache, but document session as audit log. |
| **P2** | **UI** | Duplicate breakpoints definition in two files | `acadex_breakpoints.dart`, `app_theme.dart` | Export unified breakpoints from design system. |
| **P2** | **UI** | Duplicate legacy widget bridges (`AppButton`, `AppBadge`, `AppCard`, etc.) | `core/presentation/widgets/app_*.dart` | Migrate remaining references to `acadex_*` and remove legacy bridges. |
| **P2** | **Terminology** | Hardcoded terms in Attendance, Notes, Reports bypassing `TerminologyHelper` | Multiple feature presentation screens | Adopt `ref.watch(terminologyProvider).label(concept)`. |
| **P3** | **Codebase** | Dormant Python FastAPI backend files (`campus.db`, `Backend/app`, `alembic.ini`) | Root `Backend/` directory | Archive or segregate into `legacy_python_prototype/` to avoid confusion. |

---

## 13. DATA INTEGRITY RISK REGISTER

| Risk ID | Source | Affected Entities | Potential Consequence | Current Protection | Missing Protection | Priority |
|---|---|---|---|---|---|---|
| **DIR-01** | Missing Foreign Key Cascades in MongoDB | `FacultyAssignment`, `TimetableEntry`, `StudentEnrollment` | Orphaned records pointing to deleted Faculty, Student, or Section | `IntegrityService.runForensicAudit()` repair script | Pre-delete integrity hooks or soft-delete blocks | **P1** |
| **DIR-02** | Name matching in Faculty Auth | `FacultyAssignment`, `TeachingAuthorizationService` | Impersonation or wrong faculty editing marks if names match | Primary match is by `userId` / `_id` | Eliminate fallback string name matching completely | **P1** |
| **DIR-03** | Mandatory Section schema vs Configurable Section | `Section`, `FacultyAssignment`, `Timetable`, `InstitutionConfiguration` | Inability to allocate faculty or timetables in colleges with sections disabled | None (schema fails validation) | Make `sectionId` optional in Mongoose schemas when config disables section | **P1** |
| **DIR-04** | Subject removal `$pull` side-effect | `Faculty.subjectIds`, `academic.service.ts` | Deleting assignment for Section A removes subject for Section B | None | Derive assignment count from `FacultyAssignment` queries | **P2** |
| **DIR-05** | Stale User Academic Context | `User.sectionId`, `User.semesterId` | Stale tenant context in JWT tokens upon promotion | `authenticateRequest` fetches db User | Clear or update User academic pointers during semester promotion | **P2** |

---

## 14. SECURITY BASELINE

1. **Authentication Boundary**: Cryptographically signed HMAC-SHA256 JWT tokens with active DB user account validation (`authenticateRequest`). Revocation via `AuthSession`.
2. **Multi-Tenancy & Tenant Isolation**: `requireCollegeScope` enforces `collegeId` isolation on all requests. Non-SuperAdmins cannot target another institution.
3. **Role-Based Access Control**: `requireRoles` and `requireMinRole` enforce hierarchical permissions.
4. **Teaching Authorization**: `TeachingAuthorizationService` enforces teaching context boundaries for Assignments, Internal Marks, and Labs.
5. **Security Gaps Identified**:
   - ⚠️ `TeachingAuthorizationService` name-fallback matching vulnerability.
   - ⚠️ `NoteService` lacks teaching context authorization (faculty can upload to any subject).
   - ⚠️ Development CORS allows any localhost port pattern.

---

## 15. PERFORMANCE BASELINE

1. **Flutter Widget Tree**:
   - `ShellWrapper` is currently recreated on every route change, causing unnecessary unmounting and rebuild of the App Bar, Drawer, and Bottom Nav.
   - *Target*: Migrate to GoRouter `StatefulShellRoute`.
2. **Database Queries**:
   - Compound indexes exist for common queries (`collegeId + status`, `collegeId + sectionId + date`).
   - *Target*: Large attendance aggregations in `report.service.ts` should utilize pre-aggregated buckets for colleges with >10,000 students.
3. **Asset & Image Performance**:
   - ImageKit integration handles image transformations, resizing, and caching effectively.

---

## 16. REALTIME BASELINE

| Technology | Status | Implementation Details |
|---|---|---|
| **WebSockets** | ❌ Not Live | No custom WebSocket server active. |
| **Socket.IO** | ❌ Not Live | Not installed in dependencies. |
| **MongoDB Change Streams** | ❌ Not Live | No `.watch()` pipeline triggers active. |
| **FCM Push Notifications** | ✅ **Live** | Backend `FcmService` sends multicast via Firebase Admin; Flutter listens in foreground/background. |
| **Foreground Cache Invalidation**| ✅ **Live** | FCM message arrival triggers `ref.invalidate(...)` on notification and announcement providers. |
| **Manual / Pull Refresh** | ✅ **Live** | `RefreshIndicator` and `AcadexPageContainer(onRefresh: ...)` implemented across screens. |
| **Token Refresh on 401** | ✅ **Live** | Dio interceptor retries failed requests after refreshing JWT token. |

---

## 17. TECHNICAL DEBT REGISTER

1. **Router Shell Architecture**: 131 GoRoute items wrap pages in individual `ShellWrapper` instances rather than using GoRouter's declarative `StatefulShellRoute`.
2. **Hardcoded UI Terminology**: Hardcoded labels ("Semester", "Section", "Course") persist in Attendance, Notes, and Reports, ignoring `TerminologyHelper`.
3. **Duplicate Bridge Widgets**: Legacy `app_button.dart`, `app_badge.dart`, `app_empty_state.dart`, `app_card.dart` still exist alongside modern `acadex_*` design system components.
4. **Dormant Python Prototype Files**: Old SQLite database `campus.db` and Python backend files remain in `Backend/` directory alongside the active Node.js TypeScript server.
5. **Dual Breakpoint Classes**: `AcadexBreakpoints` duplicated in `app_theme.dart` and `acadex_breakpoints.dart`.

---

## 18. AUDIT PRIORITIES & ACTION PLAN

### P0 (System-Breaking / Security / Data Integrity)
- **SEC-01**: Remove name-based authorization fallback in `TeachingAuthorizationService`.
- **INT-01**: Make `sectionId` optional in `FacultyAssignment`, `Timetable`, and `StudentEnrollment` when `academicStructure.section = false`.
- **SEC-02**: Enforce teaching context authorization on `NoteService` endpoints.

### P1 (Major Workflow / Architecture Defects)
- **ARC-01**: Refactor `app_router.dart` from per-route `ShellWrapper` to `StatefulShellRoute` to eliminate shell flickering and unnecessary rebuilds.
- **DAT-01**: Deprecate `Faculty.subjectIds` and `Faculty.sectionIds` in favor of direct queries on `FacultyAssignment`.
- **DAT-02**: Synchronize `Student` academic pointers via automated hooks upon `StudentEnrollment` changes.

### P2 (Significant UX & Maintainability Problems)
- **UX-01**: Bind `terminologyProvider` dynamically across Attendance, Notes, Assessments, and Reports.
- **CLEAN-01**: Consolidate `AcadexBreakpoints` into design system and remove redundant definition in `app_theme.dart`.
- **CLEAN-02**: Remove legacy `app_*` bridge widgets once remaining test references are migrated.

### P3 (Visual Polish & Minor Cleanup)
- **CLEAN-03**: Move dormant Python FastAPI backend prototype files into a distinct `legacy/` directory to prevent developer confusion with the Node.js backend.

---

## 19. RECOMMENDED MODULE IMPLEMENTATION ORDER

Future vertical slices should proceed in strict foundational dependency order:

```
Phase 1: Institutional Core & Configuration Hardening
  ├── Enforce optionality rules on Mongoose schemas (sectionId optional when section=false)
  └── Clean up TeachingAuthorizationService name matching

Phase 2: Router & Shell Modernization
  └── Convert app_router.dart to StatefulShellRoute (preserves state, stops rebuilds)

Phase 3: Academic Terminology Unification
  └── Wire TerminologyHelper across Attendance, Notes, Assessments, and Reports

Phase 4: Academic Structure & Enrollment Vertical Slice
  └── Complete dynamic cohort management and automated semester promotion

Phase 5: Timetable & Operations Engine
  └── Harden timetable conflict resolution, teacher substitutions, and room booking

Phase 6: Attendance & Alerts System
  └── Streamline attendance marking, automated notification alerts, and correction audit workflows

Phase 7: Assessment & Examination Ledger
  └── Finalize Internal Assessments, grade calculation, and report cards

Phase 8: Campus Communications & Materials
  └── Notes ImageKit pipeline, Request Center workflows, and Announcement broadcasting
```

---

## 20. FUTURE PROMPT CONTRACT

Every future ACADEX implementation prompt must follow this standard engineering contract:

```
DISCOVER
  └── Inspect existing files, models, routes, and tests before writing code.
UNDERSTAND
  └── Understand role scopes, tenant boundaries, and configuration rules.
MAP
  └── Identify related entities and downstream consumers.
CHECK SOURCE OF TRUTH
  └── Do not duplicate data across collections or state stores.
CHECK HIERARCHY
  └── Respect College → Department → Course → AY → Semester → Section → Subject.
CHECK DEPENDENCIES
  └── Do not turn optional configuration concepts into global requirements.
CHECK AUTHORIZATION
  └── Verify backend middleware and TeachingAuthorizationService; frontend visibility is not security.
CHECK CONFIGURATION
  └── Use TerminologyHelper; respect enabled/disabled concept flags.
CHECK CURRENT/HISTORY
  └── Distinguish Academic Year from Cohort; protect historical data integrity.
CHECK REDUNDANCY
  └── Reuse existing design tokens and services; avoid duplicate endpoints or screens.
CHECK UX COMPLEXITY
  └── Keep workflows mobile-first, carry context forward, and avoid unnecessary user clicks.
IMPLEMENT
  └── Implement focused vertical slices cleanly without breaking existing tests.
VERIFY
  └── Verify with targeted tests; confirm compile-time and runtime integrity.
REPORT
  └── Provide structured summary with files modified, tests run, and verification results.
```
