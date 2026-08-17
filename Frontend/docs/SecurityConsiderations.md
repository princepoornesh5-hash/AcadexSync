# Acadex Security Considerations

Since the project is mock-driven, security constraints are currently applied at the application/presentation layer. However, frontend checks are not sufficient for a production environment. 

## Key Areas to Secure

1. **User Identity Isolation**:
   - Students must only query database paths matching their own UID (e.g. `/attendance/records/{studentId}`).
   - Faculty must only write to classes and sessions to which they are assigned.
2. **Institution/College Isolation**:
   - Every document must carry a `collegeId`. All queries from College Admins, HODs, Faculty, and Students must filter by their authorized `collegeId`.
   - Security Rules must block any cross-tenant database reads or writes.
3. **Department Isolation (HOD)**:
   - Head of Departments should be locked down to query data specific to their assigned `departmentId`.
4. **Attendance Edit Locking**:
   - Timetable configurations and session constraints must check that attendance updates are only allowed within a specified grace period (e.g., 24 hours).
   - This must be enforced by Cloud Functions or Firestore write-rules checking timestamps.

## Firestore Security Rule Blueprint (Future Enforcements)

- **/users/{uid}**: Read by anyone (public directory for searches), write only by the owner or College/Super Admins.
- **/attendance/{recordId}**: Read by student (if `studentId == request.auth.uid`), written only by the assigned faculty member.
- **/colleges/{collegeId}**: Write only by Super Admins.
