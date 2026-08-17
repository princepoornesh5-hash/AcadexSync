# Firestore Planned Collection Structure

Below is the collection and document model planned for full migration.

## Root Collections

### 1. `users`
- `/users/{uid}`
```json
{
  "name": "Alex Johnson",
  "email": "alex@acadex.com",
  "role": "student",
  "collegeId": "col_1",
  "departmentId": "dept_1"
}
```

### 2. `colleges`
- `/colleges/{collegeId}`
```json
{
  "name": "Global Engineering Institute",
  "location": "New York, USA"
}
```

### 3. `attendance_sessions`
- `/attendance_sessions/{sessionId}`
```json
{
  "subjectId": "sub_cs101",
  "facultyId": "fac_4",
  "sectionId": "sec_cse_a",
  "dateTime": "2026-08-08T10:00:00Z",
  "isLocked": false
}
```

### 4. `attendance_records` (Subcollection of session)
- `/attendance_sessions/{sessionId}/records/{recordId}`
```json
{
  "studentId": "student_12",
  "status": "present"
}
```

### 5. `notifications`
- `/notifications/{notificationId}`
```json
{
  "userId": "student_12",
  "title": "Attendance warning",
  "message": "Your attendance is below 75%",
  "category": "attendance",
  "priority": "critical",
  "timestamp": "2026-08-08T12:00:00Z",
  "isRead": false
}
```
