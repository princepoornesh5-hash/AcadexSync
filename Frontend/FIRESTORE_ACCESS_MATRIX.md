# FIRESTORE ACCESS MATRIX

This matrix maps every Firestore-backed feature to its collection, query, and security rule context. It identifies exactly where the schema mismatches the rules.

| Feature | Collection | Operation | Role Constraints | Tenant Scope (Rules) | Rule Check | Query Constraints | Status |
|---|---|---|---|---|---|---|---|
| User Profile | `users` | Read | Own Profile / Admin / College / Dept | `collegeId` | Direct `resource.data.collegeId` | None (reads by `uid`) | **PASS** |
| Colleges | `colleges` | Read | Admin / Own College | `collegeId` | Direct `collegeId` | `.where('id', '==', collegeId)` | **PASS** |
| Departments | `departments` | Read | Admin / College | `collegeId` | Direct `collegeId` | `.where('collegeId', '==', collegeId)` | **PASS** |
| Courses | `courses` | Read | Admin / College | `collegeId` | Nested `get()` via `departmentId` | No filter | **FAIL** (Rules reject unbounded query) |
| Academic Years | `academicYears` | Read | Admin / College | `collegeId` | Direct `collegeId` | `.where('collegeId', '==', collegeId)` | **PASS** |
| Semesters | `semesters` | Read | Admin / College | `collegeId` | Nested `get()` via `courseId` | No filter | **FAIL** (Rules reject unbounded query) |
| Sections | `sections` | Read | Admin / College | `collegeId` | Nested `get()` via `semesterId` | No filter | **FAIL** (Rules reject unbounded query) |
| Subjects | `subjects` | Read | Admin / College | `collegeId` | Nested `get()` via `courseId` | No filter | **FAIL** (Rules reject unbounded query) |
| Attendance | `attendance` | Read | Admin / College / HOD / Faculty | `collegeId` / `deptId` | Nested `get()` via `sectionId` | `.where('facultyId', '==', uid)` etc. | **FAIL** (Query filters insufficient for tenant isolation rules) |
| Notes | `notes` | Read | Admin / College / Dept / Faculty | `collegeId` | Direct `collegeId` | `.where('collegeId', '==', ...)` | **PASS/FAIL** (Query must strictly use tenant filters) |
| Timetable | `timetable` | Read | Admin / College / Dept / Faculty | `collegeId` | Direct `collegeId` | `.where('collegeId', '==', ...)` | **PASS/FAIL** (Depends on query implementation) |
| Notifications | `notifications` | Read | Recipient / Admin / College | `collegeId` | Direct `collegeId` | `.where('recipientUserId', '==', ...)` | **PASS** |

## Conclusion
The fundamental, shared failure is that the NoSQL data model for academic structure (`Course`, `Semester`, `Section`, `Subject`) and `AttendanceSession` lacks the `collegeId` and `departmentId` fields. 

Because they lack these fields:
1. The Flutter client repositories perform collection-level `.get()` queries WITHOUT tenant filters.
2. The Firestore Security Rules attempt to enforce tenant isolation by performing recursive `get()` checks (e.g., fetching the department to check the college). 
3. **Firestore statically rejects the client queries** because the query itself does not guarantee that the returned documents will satisfy the security rules (Firestore rules are not filters).

## Resolution
To fix this system-wide architecture problem, we must denormalize the schema by adding `collegeId` and `departmentId` directly to all tenant-scoped documents, updating the repositories to filter by them, and updating the security rules to use the fields directly without nested `get()` calls.
