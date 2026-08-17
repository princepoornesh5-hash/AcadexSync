# Acadex Role & Permissions Matrix

Acadex features a role-based authorization system that restricts data access and UI functionality depending on the authenticated user's role.

## Supported Roles

1. **Student**: Can view personal analytics, attendance status, submit notifications settings, and search their own subjects.
2. **Faculty**: Can log attendance for assigned classes, edit attendance records within the lock window, view classroom stats, and manage preferences.
3. **HOD (Head of Department)**: Can monitor department-wide attendance, check student risk alerts, review faculty completion, and preview reports.
4. **College Admin**: Can manage institution-wide departments, courses, faculty, students, review all college-level stats, and run reports.
5. **Super Admin**: Can manage colleges, college admins, and system-wide settings.

## Permission Mapping

| Module / Action | Student | Faculty | HOD | College Admin | Super Admin |
|---|---|---|---|---|---|
| **View Personal Dashboard** | Yes | Yes | Yes | Yes | Yes |
| **Log Attendance** | No | Yes | No | No | No |
| **Manage Department Struct** | No | No | No | Yes | Yes |
| **View Department Analytics** | No | No | Yes | Yes | Yes |
| **Manage College Admin Accounts** | No | No | No | No | Yes |
| **Global Search Scope** | Personal | Classroom | Dept-wide | College-wide | System-wide |
| **Export College Reports** | No | No | No | Yes | Yes |
