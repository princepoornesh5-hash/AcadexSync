# ACADEX — HARDCODED BUSINESS DATA AUDIT

## 1. Audit Scope & Methodology
Every production Flutter directory under `Frontend/lib/` was inspected for hardcoded identifiers, synthetic test accounts, hardcoded college tenant IDs, static business lists, and unauthenticated mock endpoints.

---

## 2. Findings by Feature Area

| Feature Area | Hardcoded Business Data Found | Status | Resolution |
| :--- | :--- | :--- | :--- |
| **Authentication** | None | Clean | Endpoints use live `ApiAuthRepository` and session tokens stored in `FlutterSecureStorage`. |
| **Academic Structure** | None | Clean | Hierarchical tree is loaded dynamically via `ApiAcademicRepository.getAcademicTree()`. |
| **Users & Roles** | None | Clean | Roster loaded from MongoDB via `/api/v1/users` with real tenant filtering. |
| **Attendance** | None | Clean | Roster and sessions populated dynamically from backend `/api/v1/attendance/*`. |
| **Timetable** | None | Clean | Schedules parsed dynamically from `/api/v1/timetables/*`. |
| **Notes** | None | Clean | Direct ImageKit signed upload URLs generated server-side; feed fetched dynamically. |
| **Notifications** | None | Clean | Time-grouped notifications stream dynamically from `/api/v1/notifications`. |
| **Reports & Analytics**| None | Clean | Aggregated metrics computed by backend `ReportService` and consumed by `ApiReportsRepository`. |

---

## 3. Mock Repositories vs. Production Repositories
Mock repositories in `Frontend/lib/**/mock_*_repository.dart` are isolated strictly to local preview and testing flows gated by `FirebaseInitializer.shouldUseMock`. All production runtime branches use `Api*Repository` connecting to the authoritative Node.js/Express/MongoDB backend.
