# Acadex Data Models Documentation

This document describes the primary domain models used across the Acadex client application.

## Core Models

### 1. User
- Located in: `lib/features/auth/domain/models/user_model.dart`
- Structure:
  - `id`: unique string id (matches auth UID).
  - `email`: user's institutional email address.
  - `name`: full display name.
  - `role`: enum representing roles (`student`, `faculty`, `hod`, `collegeAdmin`, `superAdmin`).
  - `collegeId`: reference to the institution.
  - `departmentId`: reference to the department (optional).

### 2. Academic Entities
- Located in: `lib/features/academic_structure/domain/models/academic_models.dart`
- Structure:
  - `Department`: `id`, `name`, `code`, `hodId`, `collegeId`.
  - `Course`: `id`, `name`, `code`, `departmentId`, `credits`.
  - `Semester`: `id`, `name`, `courseId`, `startDate`, `endDate`.
  - `Section`: `id`, `name`, `semesterId`.
  - `Subject`: `id`, `name`, `code`, `sectionId`, `facultyId`.

### 3. Attendance Records
- Located in: `lib/features/attendance/domain/models/`
- Structure:
  - `AttendanceSession`: `id`, `subjectId`, `facultyId`, `sectionId`, `dateTime`, `isLocked`.
  - `AttendanceRecord`: `id`, `sessionId`, `studentId`, `status` (Present/Absent), `remarks`.
  - `StudentAttendanceOverview`: Aggregated stats (`totalClasses`, `attendedClasses`, `percentage`).

### 4. Notifications
- Located in: `lib/features/notifications/domain/models/notification_models.dart`
- Structure:
  - `NotificationModel`: `id`, `title`, `message`, `category`, `priority`, `timestamp`, `isRead`, `navigationTarget`, `relatedEntityId`.
