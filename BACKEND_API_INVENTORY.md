# ACADEX — COMPLETE BACKEND API INVENTORY

This document catalogs every endpoint defined across `backend/src/routes/v1/`, detailing authentication, role authorization, tenant scoping, parameters, database models, and current Flutter binding status.

---

## 1. Authentication & Account Lifecycle (`/api/v1/auth`)

| Method | Endpoint | Auth Required | Allowed Roles | Tenant Scope | Models Touched | Service Method | Flutter Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `POST` | `/auth/login` | Public (Rate Limited) | All | Global / Tenant | `User`, `College` | `AuthService.login` | **CONNECTED** |
| `POST` | `/auth/refresh` | Public | All | Global | `User` | `AuthService.refresh` | **CONNECTED** |
| `POST` | `/auth/activate` | Public (Rate Limited) | All | Global / Tenant | `Invitation`, `User` | `InvitationService.activate` | **CONNECTED** |
| `POST` | `/auth/forgot-password` | Public (Rate Limited) | All | Global | `User`, `Otp` | `AuthService.forgotPassword` | **CONNECTED** |
| `POST` | `/auth/verify-password-reset-otp` | Public (Rate Limited) | All | Global | `User`, `Otp` | `AuthService.verifyOtp` | **CONNECTED** |
| `POST` | `/auth/reset-password` | Public (Rate Limited) | All | Global | `User`, `Otp` | `AuthService.resetPassword` | **CONNECTED** |
| `GET` | `/auth/me` | Authenticated | All | User Context | `User`, `College` | `AuthService.getMe` | **CONNECTED** |
| `POST` | `/auth/logout` | Authenticated | All | User Context | `User` | `AuthService.logout` | **CONNECTED** |
| `POST` | `/auth/logout-all` | Authenticated | All | User Context | `User` | `AuthService.logoutAll` | **CONNECTED** |
| `POST` | `/auth/change-password` | Authenticated | All | User Context | `User` | `AuthService.changePassword` | **CONNECTED** |
| `POST` | `/auth/invitations` | Authenticated | Admin, HOD | College Scoped | `Invitation` | `InvitationService.create` | **CONNECTED** |
| `GET` | `/auth/invitations` | Authenticated | Admin, HOD | College Scoped | `Invitation` | `InvitationService.list` | **CONNECTED** |
| `GET` | `/auth/invitations/:id` | Authenticated | Admin, HOD | College Scoped | `Invitation` | `InvitationService.getById` | **CONNECTED** |
| `POST` | `/auth/invitations/:id/reissue` | Authenticated | Admin, HOD | College Scoped | `Invitation` | `InvitationService.reissue` | **CONNECTED** |
| `POST` | `/auth/invitations/:id/revoke` | Authenticated | Admin, HOD | College Scoped | `Invitation` | `InvitationService.revoke` | **CONNECTED** |

---

## 2. Colleges & Multi-Tenancy (`/api/v1/colleges`)

| Method | Endpoint | Auth Required | Allowed Roles | Tenant Scope | Models Touched | Service Method | Flutter Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `GET` | `/colleges` | Authenticated | All | Global / Scoped | `College` | `CollegeService.list` | **CONNECTED** |
| `GET` | `/colleges/:id` | Authenticated | All | Scoped | `College` | `CollegeService.getById` | **CONNECTED** |
| `GET` | `/colleges/:id/admins` | Authenticated | SuperAdmin, CollegeAdmin | College Scoped | `User` | `CollegeService.getAdmins` | **CONNECTED** |
| `GET` | `/colleges/:id/summary` | Authenticated | SuperAdmin, CollegeAdmin | College Scoped | `College`, `Department`, `User` | `CollegeService.getSummary` | **CONNECTED** |
| `POST` | `/colleges` | Authenticated | SuperAdmin | Global | `College` | `CollegeService.create` | **CONNECTED** |
| `PUT` | `/colleges/:id` | Authenticated | SuperAdmin | Global | `College` | `CollegeService.update` | **CONNECTED** |
| `PATCH` | `/colleges/:id/status` | Authenticated | SuperAdmin | Global | `College` | `CollegeService.updateStatus` | **CONNECTED** |
| `POST` | `/colleges/:id/admins` | Authenticated | SuperAdmin | Global | `User`, `Invitation` | `CollegeService.provisionAdmin` | **CONNECTED** |

---

## 3. Departments (`/api/v1/departments`)

| Method | Endpoint | Auth Required | Allowed Roles | Tenant Scope | Models Touched | Service Method | Flutter Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `GET` | `/departments` | Authenticated | All | College Scoped | `Department` | `DepartmentService.list` | **CONNECTED** |
| `GET` | `/departments/:id` | Authenticated | All | College Scoped | `Department` | `DepartmentService.getById` | **CONNECTED** |
| `GET` | `/departments/:id/summary` | Authenticated | Admin, HOD | Department Scoped | `Department`, `User`, `Course` | `DepartmentService.getSummary` | **CONNECTED** |
| `GET` | `/departments/:departmentId/hod` | Authenticated | All | Department Scoped | `User`, `Hod` | `HodService.getByDepartmentId` | **CONNECTED** |
| `GET` | `/departments/:departmentId/faculty`| Authenticated | All | Department Scoped | `User`, `Faculty` | `FacultyService.getByDepartmentId` | **CONNECTED** |
| `GET` | `/departments/:departmentId/students`| Authenticated | All | Department Scoped | `User`, `Student` | `StudentService.getByDepartmentId` | **CONNECTED** |
| `GET` | `/departments/:departmentId/courses`| Authenticated | All | Department Scoped | `Course` | `AcademicService.listCourses` | **CONNECTED** |
| `POST` | `/departments` | Authenticated | Admin, SuperAdmin | College Scoped | `Department` | `DepartmentService.create` | **CONNECTED** |
| `PUT` | `/departments/:id` | Authenticated | Admin, SuperAdmin | College Scoped | `Department` | `DepartmentService.update` | **CONNECTED** |
| `PATCH` | `/departments/:id/status` | Authenticated | Admin, SuperAdmin | College Scoped | `Department` | `DepartmentService.updateStatus` | **CONNECTED** |

---

## 4. Academic Structure & Hierarchy (`/api/v1/academics`)

| Method | Endpoint | Auth Required | Allowed Roles | Tenant Scope | Models Touched | Service Method | Flutter Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `GET` | `/academics/tree` | Authenticated | All | College Scoped | `Department`, `Course`, `Semester`, `Section` | `AcademicService.getAcademicTree` | **CONNECTED** |
| `GET` | `/academics/courses` | Authenticated | All | College Scoped | `Course` | `AcademicService.listCourses` | **CONNECTED** |
| `POST` | `/academics/courses` | Authenticated | Admin, HOD | Department Scoped | `Course` | `AcademicService.createCourse` | **CONNECTED** |
| `GET` | `/academics/courses/:id` | Authenticated | All | Department Scoped | `Course` | `AcademicService.getCourseById` | **CONNECTED** |
| `PUT` | `/academics/courses/:id` | Authenticated | Admin, HOD | Department Scoped | `Course` | `AcademicService.updateCourse` | **CONNECTED** |
| `GET` | `/academics/academic-years` | Authenticated | All | College Scoped | `AcademicYear` | `AcademicService.listAcademicYears` | **CONNECTED** |
| `POST` | `/academics/academic-years` | Authenticated | Admin, SuperAdmin | College Scoped | `AcademicYear` | `AcademicService.createAcademicYear`| **CONNECTED** |
| `GET` | `/academics/semesters` | Authenticated | All | College Scoped | `Semester` | `AcademicService.listSemesters` | **CONNECTED** |
| `POST` | `/academics/semesters` | Authenticated | Admin, HOD | Course Scoped | `Semester` | `AcademicService.createSemester` | **CONNECTED** |
| `GET` | `/academics/sections` | Authenticated | All | College Scoped | `Section` | `AcademicService.listSections` | **CONNECTED** |
| `POST` | `/academics/sections` | Authenticated | Admin, HOD | Semester Scoped | `Section` | `AcademicService.createSection` | **CONNECTED** |
| `GET` | `/academics/subjects` | Authenticated | All | College Scoped | `Subject` | `AcademicService.listSubjects` | **CONNECTED** |
| `POST` | `/academics/subjects` | Authenticated | Admin, HOD | Semester Scoped | `Subject` | `AcademicService.createSubject` | **CONNECTED** |
| `GET` | `/academics/enrollments` | Authenticated | All | College Scoped | `Enrollment` | `AcademicService.listEnrollments` | **CONNECTED** |
| `POST` | `/academics/enrollments` | Authenticated | Admin, HOD, Faculty | Section Scoped | `Enrollment` | `AcademicService.enrollStudent` | **CONNECTED** |

---

## 5. Users & Roles Management (`/api/v1/users` & `/api/v1/academics/faculty|hods|students`)

| Method | Endpoint | Auth Required | Allowed Roles | Tenant Scope | Models Touched | Service Method | Flutter Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `GET` | `/users` | Authenticated | CollegeAdmin, SuperAdmin | College Scoped | `User` | `UserService.list` | **CONNECTED** |
| `GET` | `/users/:id` | Authenticated | All | College Scoped | `User` | `UserService.getById` | **CONNECTED** |
| `GET` | `/users/institute/:instituteId` | Authenticated | All | College Scoped | `User` | `UserService.getByInstituteId` | **CONNECTED** |
| `POST` | `/users` | Authenticated | CollegeAdmin, SuperAdmin | College Scoped | `User`, `Invitation` | `UserService.create` | **CONNECTED** |
| `PUT` | `/users/:id` | Authenticated | Admin, Self | College Scoped | `User` | `UserService.update` | **CONNECTED** |
| `POST` | `/users/me/profile-image/upload-url` | Authenticated | All | User Context | ImageKit | `UserService.requestUploadUrl` | **CONNECTED** |
| `POST` | `/users/me/profile-image/complete` | Authenticated | All | User Context | `User`, ImageKit | `UserService.completeUpload` | **CONNECTED** |
| `POST` | `/academics/hods` | Authenticated | CollegeAdmin, SuperAdmin | College Scoped | `User`, `Hod` | `HodService.provision` | **CONNECTED** |
| `POST` | `/academics/faculty` | Authenticated | Admin, HOD | Department Scoped | `User`, `Faculty` | `FacultyService.provision` | **CONNECTED** |
| `POST` | `/academics/students` | Authenticated | Admin, HOD, Faculty | Department Scoped | `User`, `Student` | `StudentService.provision` | **CONNECTED** |

---

## 6. Attendance Engine (`/api/v1/attendance`)

| Method | Endpoint | Auth Required | Allowed Roles | Tenant Scope | Models Touched | Service Method | Flutter Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `GET` | `/attendance/students/me` | Authenticated | Student | Student Identity | `AttendanceRecord`, `AttendanceSession` | `AttendanceService.getStudentHistory` | **CONNECTED** |
| `GET` | `/attendance/students/me/subjects` | Authenticated | Student | Student Identity | `AttendanceRecord` | `AttendanceService.getStudentSubjects` | **CONNECTED** |
| `GET` | `/attendance/students/me/summary` | Authenticated | Student | Student Identity | `AttendanceRecord` | `AttendanceService.getStudentSummary` | **CONNECTED** |
| `GET` | `/attendance/sections/:sectionId` | Authenticated | Faculty, HOD, Admin | Section Scoped | `AttendanceRecord`, `AttendanceSession` | `AttendanceService.getSectionAttendance` | **CONNECTED** |
| `GET` | `/attendance/faculty/me` | Authenticated | Faculty | Faculty Identity | `AttendanceSession` | `AttendanceService.getFacultySessions` | **CONNECTED** |
| `GET` | `/attendance/analytics` | Authenticated | Admin, HOD, Faculty | College Scoped | `AttendanceRecord` | `AttendanceService.getAnalytics` | **CONNECTED** |
| `PATCH` | `/attendance/records/:id/correct` | Authenticated | Admin, HOD | College Scoped | `AttendanceRecord`, `AttendanceAudit` | `AttendanceService.correctRecord` | **CONNECTED** |
| `POST` | `/attendance/sessions` | Authenticated | Faculty, HOD, Admin | College Scoped | `AttendanceSession` | `AttendanceService.createSession` | **CONNECTED** |
| `GET` | `/attendance/sessions` | Authenticated | All | College Scoped | `AttendanceSession` | `AttendanceService.list` | **CONNECTED** |
| `GET` | `/attendance/sessions/:id` | Authenticated | All | College Scoped | `AttendanceSession`, `AttendanceRecord` | `AttendanceService.getById` | **CONNECTED** |
| `POST` | `/attendance/sessions/:id/records`| Authenticated | Faculty, HOD, Admin | College Scoped | `AttendanceRecord` | `AttendanceService.submitRecords` | **CONNECTED** |
| `POST` | `/attendance/sessions/:id/lock` | Authenticated | Faculty, HOD, Admin | College Scoped | `AttendanceSession` | `AttendanceService.lockSession` | **CONNECTED** |
| `POST` | `/attendance/sessions/:id/close` | Authenticated | Faculty, HOD, Admin | College Scoped | `AttendanceSession` | `AttendanceService.closeSession` | **CONNECTED** |
| `POST` | `/attendance/sessions/:id/cancel` | Authenticated | Admin, HOD | College Scoped | `AttendanceSession` | `AttendanceService.cancelSession` | **CONNECTED** |

---

## 7. Timetable Engine (`/api/v1/timetables`)

| Method | Endpoint | Auth Required | Allowed Roles | Tenant Scope | Models Touched | Service Method | Flutter Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `GET` | `/timetables/students/me` | Authenticated | Student | Student Identity | `Timetable`, `TimetableEntry` | `TimetableService.getStudentTimetable` | **CONNECTED** |
| `GET` | `/timetables/sections/:sectionId` | Authenticated | All | Section Scoped | `Timetable`, `TimetableEntry` | `TimetableService.getSectionTimetable` | **CONNECTED** |
| `GET` | `/timetables/faculty/:facultyId` | Authenticated | All | Faculty Scoped | `Timetable`, `TimetableEntry` | `TimetableService.getFacultyTimetable` | **CONNECTED** |
| `GET` | `/timetables` | Authenticated | All | College Scoped | `Timetable` | `TimetableService.list` | **CONNECTED** |
| `GET` | `/timetables/:id` | Authenticated | All | College Scoped | `Timetable`, `TimetableEntry` | `TimetableService.getById` | **CONNECTED** |
| `POST` | `/timetables` | Authenticated | Admin, HOD | Department Scoped | `Timetable` | `TimetableService.create` | **CONNECTED** |
| `PUT` | `/timetables/:id` | Authenticated | Admin, HOD | Department Scoped | `Timetable` | `TimetableService.update` | **CONNECTED** |
| `POST` | `/timetables/:id/publish` | Authenticated | Admin, HOD | Department Scoped | `Timetable` | `TimetableService.publish` | **CONNECTED** |
| `POST` | `/timetables/:id/unpublish` | Authenticated | Admin, HOD | Department Scoped | `Timetable` | `TimetableService.unpublish` | **CONNECTED** |
| `POST` | `/timetables/:id/archive` | Authenticated | Admin, HOD | Department Scoped | `Timetable` | `TimetableService.archive` | **CONNECTED** |
| `POST` | `/timetables/rooms` | Authenticated | CollegeAdmin, SuperAdmin | College Scoped | `Room` | `TimetableService.createRoom` | **CONNECTED** |
| `GET` | `/timetables/rooms` | Authenticated | All | College Scoped | `Room` | `TimetableService.listRooms` | **CONNECTED** |
| `GET` | `/timetables/rooms/:id` | Authenticated | All | College Scoped | `Room` | `TimetableService.getRoomById` | **CONNECTED** |
| `PUT` | `/timetables/rooms/:id` | Authenticated | CollegeAdmin, SuperAdmin | College Scoped | `Room` | `TimetableService.updateRoom` | **CONNECTED** |

---

## 8. Notes & Academic Materials (`/api/v1/notes`)

| Method | Endpoint | Auth Required | Allowed Roles | Tenant Scope | Models Touched | Service Method | Flutter Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `GET` | `/notes/students/me` | Authenticated | Student | Student Identity | `Note`, `Enrollment` | `NoteService.getStudentNotes` | **CONNECTED** |
| `POST` | `/notes/upload-url` | Authenticated | Faculty, HOD, Admin | College Scoped | ImageKit | `NoteService.requestUploadUrl` | **CONNECTED** |
| `POST` | `/notes/:id/complete` | Authenticated | Faculty, HOD, Admin | College Scoped | `Note`, ImageKit | `NoteService.completeUpload` | **CONNECTED** |
| `GET` | `/notes/:id/download` | Authenticated | All | College Scoped | `Note`, ImageKit | `NoteService.getDownloadUrl` | **CONNECTED** |
| `POST` | `/notes/:id/replace-url` | Authenticated | Faculty, HOD, Admin | College Scoped | ImageKit | `NoteService.requestReplaceUrl` | **CONNECTED** |
| `POST` | `/notes/:id/replace-complete`| Authenticated | Faculty, HOD, Admin | College Scoped | `Note`, ImageKit | `NoteService.completeReplace` | **CONNECTED** |
| `GET` | `/notes` | Authenticated | All | College Scoped | `Note` | `NoteService.listNotes` | **CONNECTED** |
| `GET` | `/notes/:id` | Authenticated | All | College Scoped | `Note` | `NoteService.getNoteById` | **CONNECTED** |
| `PUT` | `/notes/:id` | Authenticated | Faculty, HOD, Admin | College Scoped | `Note` | `NoteService.updateNote` | **CONNECTED** |
| `PATCH` | `/notes/:id` | Authenticated | Faculty, HOD, Admin | College Scoped | `Note` | `NoteService.updateNote` | **CONNECTED** |
| `DELETE`| `/notes/:id` | Authenticated | Faculty, HOD, Admin | College Scoped | `Note`, ImageKit | `NoteService.deleteNote` | **CONNECTED** |

---

## 9. Notification Engine (`/api/v1/notifications`)

| Method | Endpoint | Auth Required | Allowed Roles | Tenant Scope | Models Touched | Service Method | Flutter Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `GET` | `/notifications/unread-count` | Authenticated | All | User Identity | `Notification` | `NotificationService.getUnreadCount` | **CONNECTED** |
| `GET` | `/notifications/preferences` | Authenticated | All | User Identity | `NotificationPreference` | `NotificationService.getPreferences` | **CONNECTED** |
| `PUT` | `/notifications/preferences` | Authenticated | All | User Identity | `NotificationPreference` | `NotificationService.updatePreferences`| **CONNECTED** |
| `POST` | `/notifications/device-tokens` | Authenticated | All | User Identity | `DeviceToken` | `NotificationService.registerDeviceToken`| **CONNECTED** |
| `DELETE`| `/notifications/device-tokens/:token`| Authenticated| All | User Identity | `DeviceToken` | `NotificationService.removeDeviceToken`| **CONNECTED** |
| `PATCH` | `/notifications/read-all` | Authenticated | All | User Identity | `Notification` | `NotificationService.markAllAsRead` | **CONNECTED** |
| `PATCH` | `/notifications/:id/read` | Authenticated | All | User Identity | `Notification` | `NotificationService.markAsRead` | **CONNECTED** |
| `GET` | `/notifications/:id` | Authenticated | All | User Identity | `Notification` | `NotificationService.getById` | **CONNECTED** |
| `GET` | `/notifications` | Authenticated | All | User Identity | `Notification` | `NotificationService.listNotifications` | **CONNECTED** |

---

## 10. Reports & Analytics Engine (`/api/v1/reports`)

| Method | Endpoint | Auth Required | Allowed Roles | Tenant Scope | Models Touched | Service Method | Flutter Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `GET` | `/reports/dashboard` | Authenticated | All | Role-Aware Context | Multi-model aggregation | `ReportService.getDashboard` | **CONNECTED** |
| `GET` | `/reports/attendance/me` | Authenticated | Student | Student Identity | `AttendanceRecord` | `ReportService.getMyAttendanceReport` | **CONNECTED** |
| `GET` | `/reports/attendance/student/:studentId` | Authenticated | Admin, Faculty, HOD, Student | Scoped | `AttendanceRecord` | `ReportService.getStudentAttendanceReport` | **CONNECTED** |
| `GET` | `/reports/attendance/section/:sectionId` | Authenticated | Faculty, HOD, Admin | Section Scoped | `AttendanceRecord` | `ReportService.getSectionAttendanceReport` | **CONNECTED** |
| `GET` | `/reports/attendance/department/:departmentId`| Authenticated| HOD, Admin | Department Scoped | `AttendanceRecord` | `ReportService.getDepartmentAttendanceReport`| **CONNECTED** |
| `GET` | `/reports/attendance/college/:collegeId` | Authenticated | Admin | College Scoped | `AttendanceRecord` | `ReportService.getCollegeAttendanceReport` | **CONNECTED** |
| `GET` | `/reports/attendance/subject/:subjectId` | Authenticated | Faculty, HOD, Admin | Subject Scoped | `AttendanceRecord` | `ReportService.getSubjectAttendanceReport` | **CONNECTED** |
| `GET` | `/reports/faculty/:facultyId` | Authenticated | All | Faculty Scoped | Multi-model aggregation | `ReportService.getFacultyReport` | **CONNECTED** |
| `GET` | `/reports/academic` | Authenticated | HOD, Admin | Department/College | Multi-model aggregation | `ReportService.getAcademicReport` | **CONNECTED** |
| `GET` | `/reports/notes` | Authenticated | All | Scoped | `Note` | `ReportService.getNotesReport` | **CONNECTED** |

---

## 11. Audit Logging (`/api/v1/audit`)

| Method | Endpoint | Auth Required | Allowed Roles | Tenant Scope | Models Touched | Service Method | Flutter Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `GET` | `/audit` | Authenticated | CollegeAdmin, SuperAdmin | College Scoped | `AuditLog` | `AuditService.list` | **CONNECTED** |
