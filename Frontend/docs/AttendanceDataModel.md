# Acadex Attendance Data Model (`Prompt 24`)

## Firestore Collections & Schemas

### 1. Collection: `attendanceSessions/{sessionId}`
Stores full class session records marked by faculty.

- **Document ID**: `${sectionId}_${subjectId}_YYYYMMDD` (e.g. `sec1_sub1_20260809`)

```json
{
  "id": "sec1_sub1_20260809",
  "facultyId": "faculty1",
  "subjectId": "sub1",
  "subjectName": "Java Programming",
  "sectionId": "sec1",
  "sectionName": "DCME 3-A",
  "timeSlot": "08:30 - 09:20",
  "date": "2026-08-09T00:00:00.000Z",
  "records": [
    {
      "id": "rec_1",
      "studentId": "s1",
      "studentName": "John Doe",
      "rollNumber": "CS2025001",
      "sectionId": "sec1",
      "status": "present",
      "lastModified": "2026-08-09T08:50:00.000Z",
      "modifiedBy": "faculty1"
    }
  ],
  "isSubmitted": true,
  "isLocked": false,
  "createdAt": "2026-08-09T08:50:00.000Z",
  "createdBy": "faculty1",
  "lastModifiedAt": "2026-08-09T08:50:00.000Z",
  "lastModifiedBy": "faculty1",
  "version": 1
}
```

---

### 2. Collection: `attendance/{attendanceId}`
Flat per-student attendance records for fast student and department query indexing.

- **Document ID**: `${sessionId}_${studentId}` (e.g. `sec1_sub1_20260809_s1`)

```json
{
  "attendanceId": "sec1_sub1_20260809_s1",
  "sessionId": "sec1_sub1_20260809",
  "studentId": "s1",
  "studentName": "John Doe",
  "rollNumber": "CS2025001",
  "sectionId": "sec1",
  "subjectId": "sub1",
  "facultyId": "faculty1",
  "date": "2026-08-09",
  "status": "present",
  "markedAt": "2026-08-09T08:50:00.000Z",
  "markedBy": "faculty1"
}
```

---

## Strongly Typed Status Enum (`AttendanceStatus`)
- `present`
- `absent`
- `late`
- `medicalLeave`
- `onDuty`
- `holiday`
