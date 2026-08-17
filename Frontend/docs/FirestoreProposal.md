# Firestore Collections Proposal

To support integration with a Firebase backend, the current memory models must map to Firestore Collections.

```
colleges (root collection)
 ├── id: string (document id)
 └── name: string

users (root collection)
 ├── id: string (document id matching Firebase Auth UID)
 ├── email: string
 ├── name: string
 ├── role: string (student, faculty, hod, collegeAdmin, superAdmin)
 ├── collegeId: string (reference)
 └── departmentId: string (reference, optional)

departments (root collection)
 ├── id: string
 ├── name: string
 ├── code: string
 └── collegeId: string

courses (root collection)
 ├── id: string
 ├── name: string
 ├── code: string
 └── departmentId: string

semesters (subcollection of courses or root)
 └── semesters (root collection)
      ├── id: string
      ├── name: string
      └── courseId: string

sections (root collection)
 ├── id: string
 ├── name: string
 └── semesterId: string

subjects (root collection)
 ├── id: string
 ├── name: string
 ├── code: string
 ├── sectionId: string
 └── facultyId: string

attendance_sessions (root collection)
 ├── id: string
 ├── subjectId: string
 ├── facultyId: string
 ├── sectionId: string
 ├── dateTime: timestamp
 └── isLocked: boolean

attendance_records (subcollection of attendance_sessions)
 └── /attendance_sessions/{sessionId}/records/{recordId}
      ├── id: string
      ├── studentId: string
      └── status: string (present, absent)

notifications (root collection)
 ├── id: string
 ├── userId: string (recipient UID)
 ├── title: string
 ├── message: string
 ├── category: string
 ├── priority: string
 ├── timestamp: timestamp
 ├── isRead: boolean
 └── relatedEntityId: string
```

## Recommended Indexes
- `/attendance_sessions` composite index: `sectionId` ASC + `dateTime` DESC (for rapid class list queries).
- `/notifications` composite index: `userId` ASC + `timestamp` DESC (for displaying inbox by date).
- `/attendance_records` composite index: `studentId` ASC + `status` ASC (for generating stats).
