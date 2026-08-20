# ACADEX — COMPLETE FLUTTER FEATURE INVENTORY

This document catalogs every repository interface, API repository, Riverpod provider, notifier, domain model, screen, and router configuration across the Flutter codebase.

---

## 1. Authentication & Account Lifecycle (`features/auth`)

| Layer | Component | Path | Description |
| :--- | :--- | :--- | :--- |
| **Domain Model** | `UserModel` | `lib/features/auth/domain/models/user_model.dart` | User model with role, status, profileImage, metadata |
| **Domain Model** | `AuthState` | `lib/features/auth/domain/models/auth_state.dart` | Sealed class: `AuthInitial`, `AuthLoading`, `AuthAuthenticated`, `AuthUnauthenticated`, `AuthError` |
| **Domain Model** | `AppRole` | `lib/features/auth/domain/models/role_enum.dart` | 5 Roles: `superAdmin`, `collegeAdmin`, `hod`, `faculty`, `student` |
| **Repository** | `AuthRepository` | `lib/features/auth/repositories/auth_repository.dart` | Contract for login, activate, OTP, password recovery |
| **API Repository** | `ApiAuthRepository` | `lib/features/auth/data/repositories/api_auth_repository.dart` | Live Dio client calling `/api/v1/auth/*` |
| **Provider** | `authProvider` | `lib/features/auth/presentation/providers/auth_provider.dart` | `StateNotifierProvider<AuthNotifier, AuthState>` |
| **Provider** | `currentUserProvider` | `lib/features/auth/presentation/providers/auth_provider.dart` | Returns active `UserModel?` |
| **Screens** | `LoginScreen` | `lib/features/auth/presentation/screens/login_screen.dart` | ACADEX styled login with role-based routing |
| **Screens** | `ActivationScreen` | `lib/features/auth/presentation/screens/activation_screen.dart` | 8-character activation code validation and password set |
| **Screens** | `ForgotPasswordScreen` | `lib/features/auth/presentation/screens/forgot_password_screen.dart` | Email OTP request |
| **Screens** | `OtpVerificationScreen` | `lib/features/auth/presentation/screens/otp_verification_screen.dart` | 6-digit OTP verification |
| **Screens** | `ResetPasswordScreen` | `lib/features/auth/presentation/screens/reset_password_screen.dart` | Reset password execution with reset token |
| **Screens** | `ChangePasswordScreen` | `lib/features/auth/presentation/screens/change_password_screen.dart` | Authenticated old/new password change |

---

## 2. Users & Roles Management (`features/users`)

| Layer | Component | Path | Description |
| :--- | :--- | :--- | :--- |
| **Domain Model** | `UserProfile` | `lib/features/users/domain/models/user_profile_model.dart` | User details, contact info, departmental affiliation |
| **Repository** | `UserRepository` | `lib/features/users/domain/repositories/user_repository.dart` | Interface for user provisioning, listing, status toggle |
| **API Repository** | `ApiUserRepository` | `lib/features/users/data/repositories/api_user_repository.dart` | Calling `/api/v1/users` and `/api/v1/academics/faculty|hods|students` |
| **Provider** | `usersProvider` | `lib/features/users/presentation/providers/user_providers.dart` | AsyncNotifier for list of users with search/filter |
| **Screens** | `UserDirectoryScreen` | `lib/features/users/presentation/screens/user_directory_screen.dart` | Paginated user management table with role badges |
| **Screens** | `UserDetailScreen` | `lib/features/users/presentation/screens/user_detail_screen.dart` | User detail, activation status, role reassignment |
| **Screens** | `UserFormScreen` | `lib/features/users/presentation/screens/user_form_screen.dart` | Provision new user modal/form |

---

## 3. Academic Structure (`features/academic_structure`)

| Layer | Component | Path | Description |
| :--- | :--- | :--- | :--- |
| **Domain Model** | `Department`, `Course`, `AcademicYear`, `Semester`, `Section`, `Subject` | `lib/features/academic_structure/domain/models/academic_models.dart` | Full academic entity tree models |
| **Repository** | `AcademicRepository` | `lib/features/academic_structure/domain/repositories/academic_repository.dart` | Contract for academic tree and entity CRUD |
| **API Repository** | `ApiAcademicRepository` | `lib/features/academic_structure/data/repositories/api_academic_repository.dart` | Calling `/api/v1/academics/*` |
| **Provider** | `academicTreeProvider` | `lib/features/academic_structure/presentation/providers/academic_providers.dart` | Riverpod provider for full hierarchical tree |
| **Screens** | `AcademicStructureHomeScreen` | `lib/features/academic_structure/presentation/screens/academic_structure_home_screen.dart` | Multi-tab hierarchy manager (Depts, Courses, Sections, Subjects) |

---

## 4. Attendance System (`features/attendance`)

| Layer | Component | Path | Description |
| :--- | :--- | :--- | :--- |
| **Domain Model** | `AttendanceSession`, `AttendanceRecord`, `AttendanceSummary` | `lib/features/attendance/domain/models/attendance_models.dart` | Complete attendance lifecycle models |
| **Repository** | `AttendanceRepository` | `lib/features/attendance/domain/repositories/attendance_repository.dart` | Contract for marking, viewing, and analytics |
| **API Repository** | `ApiAttendanceRepository`| `lib/features/attendance/data/repositories/api_attendance_repository.dart` | Live Dio client calling `/api/v1/attendance/*` |
| **Provider** | `studentAttendanceProvider` | `lib/features/attendance/presentation/providers/attendance_providers.dart` | Student summary and history provider |
| **Provider** | `facultySessionsProvider` | `lib/features/attendance/presentation/providers/attendance_providers.dart` | Faculty active and recent sessions provider |
| **Screens** | `StudentAttendancePortalScreen` | `lib/features/attendance/presentation/screens/student_attendance_portal_screen.dart` | Student metrics, subject breakdown, history logs |
| **Screens** | `AssignedClassesScreen` | `lib/features/attendance/presentation/screens/faculty_attendance_screen.dart` | Faculty class roster & session launcher |
| **Screens** | `MarkAttendanceScreen` | `lib/features/attendance/presentation/screens/mark_attendance_screen.dart` | Roll call marking interface with review summary |
| **Screens** | `HodAttendanceDashboardScreen` | `lib/features/attendance/presentation/screens/hod_attendance_dashboard_screen.dart` | HOD department overview & low attendance alerts |
| **Screens** | `CollegeAttendanceDashboardScreen` | `lib/features/attendance/presentation/screens/college_attendance_dashboard_screen.dart` | College-wide analytics and audit reports |

---

## 5. Timetable System (`features/timetable`)

| Layer | Component | Path | Description |
| :--- | :--- | :--- | :--- |
| **Domain Model** | `TimetableModel`, `TimetableEntry`, `RoomModel` | `lib/features/timetable/domain/models/timetable_models.dart` | Timetable grid and slot models |
| **Repository** | `TimetableRepository` | `lib/features/timetable/domain/repositories/timetable_repository.dart` | Contract for timetable CRUD, draft/publish/archive |
| **API Repository** | `ApiTimetableRepository` | `lib/features/timetable/data/repositories/api_timetable_repository.dart` | Live Dio client calling `/api/v1/timetables/*` |
| **Provider** | `studentTimetableProvider` | `lib/features/timetable/presentation/providers/timetable_lookup_providers.dart` | Student active weekly timetable provider |
| **Provider** | `facultyTimetableProvider` | `lib/features/timetable/presentation/providers/timetable_lookup_providers.dart` | Faculty active weekly timetable provider |
| **Screens** | `TimetableDashboardScreen` | `lib/features/timetable/presentation/screens/timetable_dashboard_screen.dart` | Responsive view: NextClassCard, Day timeline, Weekly grid |
| **Screens** | `TimetableManagementScreen` | `lib/features/timetable/presentation/screens/timetable_management_screen.dart` | Draft/Publish/Archive container manager |
| **Screens** | `TimetableDesignerScreen` | `lib/features/timetable/presentation/screens/timetable_designer_screen.dart` | Interactive spreadsheet grid designer |

---

## 6. Notes & Academic Materials (`features/notes`)

| Layer | Component | Path | Description |
| :--- | :--- | :--- | :--- |
| **Domain Model** | `NoteModel` | `lib/features/notes/domain/models/note_model.dart` | Subject notes, ImageKit file metadata, chapters |
| **Repository** | `NotesRepository` | `lib/features/notes/domain/repositories/notes_repository.dart` | Contract for upload authorization, listing, download |
| **API Repository** | `ApiNotesRepository` | `lib/features/notes/data/repositories/api_notes_repository.dart` | Calling `/api/v1/notes/*` and `/api/v1/academics/subjects/:id/notes` |
| **Provider** | `notesProvider` | `lib/features/notes/presentation/providers/notes_providers.dart` | Filtered and searched notes stream |
| **Screens** | `NotesDashboardScreen` | `lib/features/notes/presentation/screens/notes_dashboard_screen.dart` | Role-aware notes library with search and filters |
| **Screens** | `NoteDetailScreen` | `lib/features/notes/presentation/screens/note_detail_screen.dart` | Document detail view with direct signed download |
| **Screens** | `NoteFormScreen` | `lib/features/notes/presentation/screens/note_form_screen.dart` | Two-phase ImageKit direct upload & publish form |

---

## 7. Notifications & Alerts (`features/notifications`)

| Layer | Component | Path | Description |
| :--- | :--- | :--- | :--- |
| **Domain Model** | `NotificationModel` | `lib/features/notifications/domain/models/notification_models.dart` | Notification payload, category, priority, deep link |
| **Repository** | `NotificationRepository` | `lib/features/notifications/data/repositories/notification_repository.dart` | Contract for notifications and unread count |
| **API Repository** | `ApiNotificationRepository` | `lib/features/notifications/data/repositories/api_notification_repository.dart` | Calling `/api/v1/notifications/*` |
| **Provider** | `notificationsProvider` | `lib/features/notifications/presentation/providers/notification_providers.dart` | Time-grouped notifications stream |
| **Provider** | `unreadNotificationCountProvider`| `lib/features/notifications/presentation/providers/notification_providers.dart`| Unread notification counter |
| **Screens** | `NotificationCenterScreen` | `lib/features/notifications/presentation/screens/notification_center_screen.dart` | Grouped inbox (Today/Yesterday/Earlier) |
| **Screens** | `NotificationPreferencesScreen` | `lib/features/notifications/presentation/screens/notification_preferences_screen.dart` | Granular toggles & mandatory security banner |
| **Screens** | `CreateAnnouncementScreen` | `lib/features/notifications/presentation/screens/create_announcement_screen.dart` | Admin broadcast creation |

---

## 8. Role Dashboards & Reports (`features/dashboard` & `features/reports`)

| Layer | Component | Path | Description |
| :--- | :--- | :--- | :--- |
| **Domain Model** | `DashboardMetrics`, `ReportData` | `lib/features/reports/domain/models/report_models.dart` | Analytics and report metrics models |
| **API Repository** | `ApiReportsRepository` | `lib/features/reports/data/repositories/api_reports_repository.dart` | Calling `/api/v1/reports/*` |
| **Provider** | `dashboardMetricsProvider` | `lib/features/reports/presentation/providers/reports_providers.dart` | Role-aware dashboard summary provider |
| **Screens** | `RoleDashboardScreen` | `lib/features/dashboard/presentation/screens/role_dashboard_screen.dart` | 5 Role adaptive dashboard with live stats & quick actions |
| **Screens** | `AnalyticsDashboardScreen` | `lib/features/analytics/presentation/screens/analytics_dashboard_screen.dart` | Institutional metrics & trend charts |
| **Screens** | `ReportsListScreen` | `lib/features/analytics/presentation/screens/reports_list_screen.dart` | Exportable report center |
