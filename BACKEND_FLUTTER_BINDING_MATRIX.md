# ACADEX — BACKEND ↔ FLUTTER BINDING MATRIX

This matrix tracks the complete end-to-end chain for every backend capability in ACADEX.

---

| Feature | Backend Endpoint | Flutter Repository | Provider | Screen | Action | Real API | Status |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Login** | `POST /auth/login` | `ApiAuthRepository` | `authProvider` | `LoginScreen` | Submit credentials | Yes | **CONNECTED** |
| **Token Refresh** | `POST /auth/refresh` | `ApiClient` | `authProvider` | App Background | Auto-refresh on 401 | Yes | **CONNECTED** |
| **Account Activation**| `POST /auth/activate` | `ApiAuthRepository` | `authProvider` | `ActivationScreen` | Submit code & password | Yes | **CONNECTED** |
| **Forgot Password** | `POST /auth/forgot-password` | `ApiAuthRepository` | `authProvider` | `ForgotPasswordScreen` | Request OTP | Yes | **CONNECTED** |
| **Verify OTP** | `POST /auth/verify-password-reset-otp` | `ApiAuthRepository` | `authProvider` | `OtpVerificationScreen`| Verify OTP code | Yes | **CONNECTED** |
| **Reset Password** | `POST /auth/reset-password` | `ApiAuthRepository` | `authProvider` | `ResetPasswordScreen` | Set new password | Yes | **CONNECTED** |
| **Get Current User** | `GET /auth/me` | `ApiAuthRepository` | `currentUserProvider` | App Shell / All | Session initialization | Yes | **CONNECTED** |
| **Logout** | `POST /auth/logout` | `ApiAuthRepository` | `authProvider` | App Top Bar / Settings| User logout | Yes | **CONNECTED** |
| **Logout All** | `POST /auth/logout-all` | `ApiAuthRepository` | `authProvider` | Security Settings | Invalidate all sessions| Yes | **CONNECTED** |
| **Change Password** | `POST /auth/change-password` | `ApiAuthRepository` | `authProvider` | `ChangePasswordScreen` | Submit old & new pass | Yes | **CONNECTED** |
| **Colleges List** | `GET /colleges` | `ApiAcademicRepository`| `collegesProvider` | `AcademicStructureHomeScreen` | View institutions | Yes | **CONNECTED** |
| **College Detail** | `GET /colleges/:id` | `ApiAcademicRepository`| `collegeDetailProvider`| `AcademicStructureHomeScreen` | View college info | Yes | **CONNECTED** |
| **Create College** | `POST /colleges` | `ApiAcademicRepository`| `collegesProvider` | College Provision Modal | Super Admin create | Yes | **CONNECTED** |
| **Departments List** | `GET /departments` | `ApiAcademicRepository`| `departmentsProvider` | `AcademicStructureHomeScreen` | View department tab | Yes | **CONNECTED** |
| **Create Department** | `POST /departments` | `ApiAcademicRepository`| `departmentsProvider` | Add Department Modal | Admin add department | Yes | **CONNECTED** |
| **Academic Tree** | `GET /academics/tree` | `ApiAcademicRepository`| `academicTreeProvider` | `AcademicStructureHomeScreen` | Browse hierarchy | Yes | **CONNECTED** |
| **Courses List** | `GET /academics/courses`| `ApiAcademicRepository`| `coursesProvider` | `AcademicStructureHomeScreen` | Browse courses | Yes | **CONNECTED** |
| **Create Course** | `POST /academics/courses`| `ApiAcademicRepository`| `coursesProvider` | Add Course Modal | Admin/HOD add course | Yes | **CONNECTED** |
| **Sections List** | `GET /academics/sections`| `ApiAcademicRepository`| `sectionsProvider` | `AcademicStructureHomeScreen` | Browse sections | Yes | **CONNECTED** |
| **Create Section** | `POST /academics/sections`| `ApiAcademicRepository`| `sectionsProvider` | Add Section Modal | Admin/HOD add section | Yes | **CONNECTED** |
| **Subjects List** | `GET /academics/subjects`| `ApiAcademicRepository`| `subjectsProvider` | `AcademicStructureHomeScreen` | Browse subjects | Yes | **CONNECTED** |
| **Create Subject** | `POST /academics/subjects`| `ApiAcademicRepository`| `subjectsProvider` | Add Subject Modal | Admin/HOD add subject | Yes | **CONNECTED** |
| **Users List** | `GET /users` | `ApiUserRepository` | `usersProvider` | `UserDirectoryScreen` | Search/filter users | Yes | **CONNECTED** |
| **Provision User** | `POST /users` | `ApiUserRepository` | `usersProvider` | `UserFormScreen` | Create user & invite | Yes | **CONNECTED** |
| **User Profile Upload**| `POST /users/me/profile-image/*`| `ApiUserRepository`| `userProfileProvider` | `ProfileScreen` | Direct ImageKit upload | Yes | **CONNECTED** |
| **Student Attendance**| `GET /attendance/students/me`| `ApiAttendanceRepository`| `studentAttendanceProvider`| `StudentAttendancePortalScreen`| View attendance history | Yes | **CONNECTED** |
| **Faculty Sessions** | `GET /attendance/faculty/me`| `ApiAttendanceRepository`| `facultySessionsProvider`| `AssignedClassesScreen` | View assigned classes | Yes | **CONNECTED** |
| **Create Session** | `POST /attendance/sessions` | `ApiAttendanceRepository`| `facultySessionsProvider`| `MarkAttendanceScreen` | Open attendance roll | Yes | **CONNECTED** |
| **Submit Attendance** | `POST /attendance/sessions/:id/records`| `ApiAttendanceRepository`| `facultySessionsProvider`| `MarkAttendanceScreen` | Submit marked roster | Yes | **CONNECTED** |
| **Lock Session** | `POST /attendance/sessions/:id/lock` | `ApiAttendanceRepository`| `facultySessionsProvider`| `MarkAttendanceScreen` | Finalize roll call | Yes | **CONNECTED** |
| **Student Timetable** | `GET /timetables/students/me`| `ApiTimetableRepository`| `studentTimetableProvider`| `TimetableDashboardScreen`| View weekly schedule | Yes | **CONNECTED** |
| **Faculty Timetable** | `GET /timetables/faculty/:id`| `ApiTimetableRepository`| `facultyTimetableProvider`| `TimetableDashboardScreen`| View teaching schedule | Yes | **CONNECTED** |
| **Timetable Admin** | `GET /timetables` | `ApiTimetableRepository`| `timetablesProvider` | `TimetableManagementScreen`| Manage containers | Yes | **CONNECTED** |
| **Publish Timetable** | `POST /timetables/:id/publish`| `ApiTimetableRepository`| `timetablesProvider` | `TimetableManagementScreen`| Publish draft timetable| Yes | **CONNECTED** |
| **Student Notes Feed**| `GET /notes/students/me` | `ApiNotesRepository` | `notesProvider` | `NotesDashboardScreen` | Browse subject notes | Yes | **CONNECTED** |
| **Upload Notes URL** | `POST /notes/upload-url` | `ApiNotesRepository` | `notesProvider` | `NoteFormScreen` | Authorize ImageKit | Yes | **CONNECTED** |
| **Complete Upload** | `POST /notes/:id/complete`| `ApiNotesRepository` | `notesProvider` | `NoteFormScreen` | Finalize upload | Yes | **CONNECTED** |
| **Download Note** | `GET /notes/:id/download` | `ApiNotesRepository` | `notesProvider` | `NoteDetailScreen` | Signed ImageKit download| Yes | **CONNECTED** |
| **Unread Count** | `GET /notifications/unread-count`| `ApiNotificationRepository`| `unreadNotificationCountProvider`| `AppTopBar` / Header | Live badge counter | Yes | **CONNECTED** |
| **List Notifications**| `GET /notifications` | `ApiNotificationRepository`| `notificationsProvider` | `NotificationCenterScreen` | Grouped inbox feed | Yes | **CONNECTED** |
| **Mark Single Read** | `PATCH /notifications/:id/read`| `ApiNotificationRepository`| `notificationsProvider` | `NotificationCenterScreen` | Mark individual read | Yes | **CONNECTED** |
| **Mark All Read** | `PATCH /notifications/read-all`| `ApiNotificationRepository`| `notificationsProvider` | `NotificationCenterScreen` | Clear unread status | Yes | **CONNECTED** |
| **Notification Prefs**| `GET /notifications/preferences`| `ApiNotificationRepository`| `notificationPreferencesProvider`| `NotificationPreferencesScreen`| View & toggle preferences| Yes | **CONNECTED** |
| **Update Prefs** | `PUT /notifications/preferences`| `ApiNotificationRepository`| `notificationPreferencesProvider`| `NotificationPreferencesScreen`| Save preference toggles| Yes | **CONNECTED** |
| **Device Tokens** | `POST /notifications/device-tokens`| `ApiNotificationRepository`| `authProvider` | App Background Lifecycle | Register FCM token | Yes | **CONNECTED** |
| **Dashboard Reports** | `GET /reports/dashboard` | `ApiReportsRepository` | `dashboardMetricsProvider` | `RoleDashboardScreen` | Role analytics stats | Yes | **CONNECTED** |
