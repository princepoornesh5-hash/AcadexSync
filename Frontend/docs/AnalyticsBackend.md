# Acadex Analytics Backend Migration Specification

## 1. Overview & Architecture
The Analytics module calculates all summaries, trends, insights, and comparison data directly from real attendance records in Cloud Firestore.

```
Analytics UI (Charts / Metrics / Insights)
       │
       ▼
Riverpod Providers (e.g. analyticsSummaryProvider)
       │
       ▼
AnalyticsRepository (Abstract Interface)
       │
       ├── Mock Mode ──────► MockAnalyticsRepository (Pre-loaded data)
       └── Firebase Mode ──► FirebaseAnalyticsRepository
                                   │
                                   ▼
                             Cloud Firestore (attendance, users, students)
```

---

## 2. Data Source
Analytics operates on a **read-only** basis and queries these collections:
- `attendance`: Individual record mappings (`status`, `studentId`, `subjectId`, `sectionId`, `date`).
- `students`: Student profile associations (`collegeId`, `departmentId`).
- `users`: User profiles containing authorized college/department scopes.

---

## 3. Scoped Calculation Metrics

### Overall Attendance Percentage
```
Attendance % = (Present Sessions / Eligible Sessions) * 100
```
- **Eligible Sessions**: Sessions where `status != 'holiday'`.
- **Present/Attended Sessions**: Sessions marked as `present`, `late`, `onDuty`, or `medicalLeave`.

### Student Scoping
- Query: `attendance.where('studentId', '==', currentStudentId)`.
- Calculated values: Subject-wise percentages, monthly trends, and projection values (`AttendanceProjection.calculate`).

### Faculty Scoping
- Query: `attendance.where('facultyId', '==', currentFacultyId)`.
- Calculates average class attendance and counts unique active sessions conducted.

### HOD Scoping
- Filters all department student IDs. Queries matching records in `attendance`.

### College Admin Scoping
- Filters all college student IDs. Queries matching records in `attendance`.

---

## 4. Empty & Error States
- If no attendance records are found, the repository returns empty chart lists and safe default metrics (`0 / 0` sessions) rather than generic `0%` placeholders.
- Real Firebase failures display user-friendly error views with manual retry hooks.
