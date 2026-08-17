# Acadex Attendance Backend Architecture (`Prompt 24`)

## Overview
This document specifies the Firestore Attendance Management backend architecture, data flow, batch operations, and security role access policies.

---

## Repository Architecture

```
Attendance UI (Faculty / Student / HOD / Admin)
       │
       ▼
Riverpod Providers (attendanceRepoProvider)
       │
       ▼
AttendanceRepository (Abstract Domain Interface)
       │
       ├── Mock Mode ──────► MockAttendanceRepository (Local State)
       └── Firebase Mode ──► FirebaseAttendanceRepository
                                   │
                                   ▼
                             Cloud Firestore
```

---

## Key Features

1. **Deterministic Session & Record Identity**:
   - `attendanceSessions`: `${sectionId}_${subjectId}_YYYYMMDD`
   - `attendance`: `${sessionId}_${studentId}`
2. **Duplicate Attendance Prevention**:
   - Re-submitting attendance for the same section/subject/date updates the existing session document instead of generating duplicate entries.
3. **Atomic Batch Writes**:
   - When attendance is saved, both the `attendanceSessions` metadata and individual `attendance/{recordId}` entries are committed via Firestore batch operations.
4. **Calculated Source of Truth**:
   - Percentage metrics (`Present / Total * 100`) are computed dynamically from actual attendance records rather than mutating raw counts.
