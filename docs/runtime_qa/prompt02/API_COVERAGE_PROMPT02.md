# ACADEX Backend & API Forensic Coverage — Prompt 02 of 12

**Device:** Motorola Edge 60 Fusion  
**Host & Port:** `http://localhost:5050/api/v1` (via `adb reverse tcp:5050 tcp:5050`)  
**Backend:** Node.js Express + TypeScript (`Backend/src/server.ts`)  
**Database:** MongoDB Atlas (Live Cluster)  

---

## 1. Forensic API Request Traces

### Trace 1: Super Admin Authentication & Dashboard
- **Flutter Screen:** `LoginScreen` (`Frontend/lib/features/auth/presentation/screens/login_screen.dart`)
- **Riverpod Provider:** `authProvider` (`auth_notifier.dart`)
- **Repository / Service:** `AuthRepository` (`auth_repository.dart`)
- **HTTP Method & Route:** `POST /api/v1/auth/login`
- **Request Payload:** `{ "email": "princepoornesh5@gmail.com", "password": "[REDACTED]" }`
- **Backend Controller:** `AuthController.login` (`Backend/src/controllers/auth.controller.ts`)
- **Backend Service:** `AuthService.login` (`Backend/src/services/auth.service.ts`)
- **MongoDB Query:** `User.findOne({ email: "princepoornesh5@gmail.com" })`
- **Backend Response:** `200 OK` `{ "status": "success", "data": { "token": "jwt...", "user": { "role": "SUPER_ADMIN", ... } } }`
- **Frontend Parsing:** `UserModel.fromJson(res.data['data']['user'])`
- **UI State:** Router redirects to `/dashboard`, ShellWrapper loads Super Admin navigation bar.

---

### Trace 2: Institutions Directory Retrieval
- **Flutter Screen:** `CollegesManagementScreen` (`super_admin_dashboard.dart`)
- **Riverpod Provider:** `institutionsProvider`
- **Repository / Service:** `InstitutionRepository`
- **HTTP Method & Route:** `GET /api/v1/institutions`
- **Authorization:** `Bearer <JWT>` with role `SUPER_ADMIN`
- **Backend Controller:** `InstitutionController.getInstitutions`
- **Backend Service:** `InstitutionService.getAllInstitutions`
- **MongoDB Query:** `Institution.find({ status: { $ne: 'deleted' } }).sort({ name: 1 })`
- **Backend Response:** `200 OK` (Returns array of institution documents: SBCE, SVGP, API-001)
- **Frontend Parsing:** `List<InstitutionModel>.from(data.map(InstitutionModel.fromJson))`
- **UI State:** Rendered in `ListView.builder` with `AcadexCard` elements and status chips.

---

### Trace 3: Institution Detail Subscreen Retrieval
- **Flutter Screen:** `CollegeDetailScreen` (`Frontend/lib/features/dashboard/presentation/screens/college_detail_screen.dart`)
- **Riverpod Provider:** `institutionDetailProvider(collegeId)`
- **Repository / Service:** `InstitutionRepository.getById`
- **HTTP Method & Route:** `GET /api/v1/institutions/666...`
- **Authorization:** `Bearer <JWT>` with role `SUPER_ADMIN`
- **Backend Controller:** `InstitutionController.getInstitutionById`
- **Backend Service:** `InstitutionService.getInstitutionDetails`
- **MongoDB Query:** `Institution.findById(id).populate('departments').populate('admins')`
- **Backend Response:** `200 OK` `{ "status": "success", "data": { "institution": { "_id": "...", "name": "SBCE", "departments": [...] } } }`
- **UI State:** Traversed via child route, renders department chips, admin count cards, back navigation arrow.

---

### Trace 4: User Directory Retrieval
- **Flutter Screen:** `UsersDirectoryScreen` (`super_admin_dashboard.dart`)
- **Riverpod Provider:** `usersListProvider`
- **Repository / Service:** `UserRepository`
- **HTTP Method & Route:** `GET /api/v1/users`
- **Authorization:** `Bearer <JWT>` with role `SUPER_ADMIN`
- **Backend Controller:** `UserController.getUsers`
- **Backend Service:** `UserService.listUsers`
- **MongoDB Query:** `User.find().limit(20).lean()`
- **Backend Response:** `200 OK` (20 user records including student, faculty, HOD, and admin profiles)
- **Frontend Parsing:** `List<UserModel>`
- **UI State:** Unclipped list of cards with user initials, names, email, and role badges.

---

### Trace 5: Student Notes & Materials Retrieval
- **Flutter Screen:** `NotesScreen` (`Frontend/lib/features/resources/presentation/screens/notes_screen.dart`)
- **Riverpod Provider:** `notesProvider`
- **Repository / Service:** `ResourceRepository`
- **HTTP Method & Route:** `GET /api/v1/resources/notes`
- **Authorization:** `Bearer <JWT>` with role `STUDENT`
- **Backend Controller:** `ResourceController.getNotes`
- **Backend Service:** `ResourceService.listResources`
- **MongoDB Query:** `Resource.find({ collegeId: tenantId, resourceType: 'NOTE' })`
- **Backend Response:** `200 OK`
- **UI State:** Search input box completely visible below the AppBar (resolved clipping), subject chips reactive.

---

### Trace 6: Drawer Logout & Session Invalidation
- **Flutter Screen:** `AcadexDrawer` (`Frontend/lib/features/dashboard/presentation/widgets/acadex_drawer.dart`)
- **Riverpod Provider:** `authProvider.notifier.logout()`
- **Repository / Service:** `AuthRepository.logout()`
- **HTTP Method & Route:** `POST /api/v1/auth/logout`
- **Authorization:** `Bearer <JWT>`
- **Backend Controller:** `AuthController.logout`
- **Backend Service:** Session token blacklisted / invalidated in Redis/DB
- **Frontend Cleanup:** Secure storage tokens wiped, `ref.invalidate(authProvider)`, realtime socket disconnected
- **UI State:** Router redirect to clean `/login` screen.

---

## 2. Authorization Security Audit

| Role | Permitted Endpoints Tested | Blocked Cross-Role Endpoints Tested | Result |
|---|---|---|---|
| **SUPER_ADMIN** | `/api/v1/institutions`, `/api/v1/users`, `/api/v1/analytics/overview` | Scoped to global platform | **PASS** (Authoritative) |
| **COLLEGE_ADMIN** | `/api/v1/college-admin/*`, `/api/v1/analytics/overview` | Rejects cross-college tenant queries (HTTP 403) | **PASS** (Authoritative) |
| **HOD** | `/api/v1/academics/faculty-assignments`, `/api/v1/timetable` | Rejects cross-department faculty assignments (HTTP 403) | **PASS** (Authoritative) |
| **FACULTY** | `/api/v1/attendance/sessions`, `/api/v1/assignments` | Rejects attendance marking for unassigned sections (HTTP 403) | **PASS** (Authoritative) |
| **STUDENT** | `/api/v1/attendance/student-portal`, `/api/v1/timetable/my-section` | Read-only enforcement; rejected on mutation APIs (HTTP 403) | **PASS** (Authoritative) |
