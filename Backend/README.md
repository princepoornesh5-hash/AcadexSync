# ACADEX Backend API (Node.js + TypeScript + MongoDB Atlas)

## Overview
The ACADEX Backend provides a robust, multi-tenant REST API foundation built on Node.js, TypeScript, Express.js, and MongoDB Atlas. It supports institutional identity management, college tenant isolation, role-based access control (RBAC), timetabling with spreadsheet-like period/break structures, granular attendance management, notes, notifications, and administrative audit logging.

---

## 1. Primary Identity Architecture (`instituteId`)

ACADEX implements a decoupled identity model:
- **MongoDB `_id`**: Technical MongoDB document identifier (ObjectId) used for all internal references, foreign keys, relationships, and joins.
- **`instituteId`**: Primary ACADEX institutional / business identity assigned by the college/institution (e.g. `DCME-25-041`, `CSE-2026-014`, `ACA-STU-000184`).
  - Required and uniquely indexed on the `User` collection.
  - Can be administratively modified by authorized institutional admins / HODs.
  - Changing `instituteId` **does not** create a new user document, **does not** modify the MongoDB `_id`, and **never** disconnects attendance history, timetable entries, subject assignments, or academic records.
- **`firebaseUid`**: Demoted to an optional legacy migration reference field (`sparse: true`) and is no longer treated as the core identity authority.

---

## 2. Multi-Tenancy & College Isolation

- Every tenant-scoped entity (`Department`, `Course`, `AcademicYear`, `Semester`, `Section`, `Subject`, `Faculty`, `Student`, `Timetable`, `AttendanceSession`, etc.) references an indexed `collegeId`.
- Access to cross-tenant data is strictly prohibited at both the middleware (`requireCollegeScope`) and service layers.
- Platform `SUPER_ADMIN` possesses overarching system-wide scope.

---

## 3. Role-Based Access Control (RBAC)

Hierarchical permissions matrix:
- `SUPER_ADMIN` (Level 100) — Platform-wide administration
- `COLLEGE_ADMIN` (Level 80) — Own college operations
- `HOD` (Level 60) — Own department & academic allocation
- `FACULTY` (Level 40) — Class sessions, attendance marking, notes authoring
- `STUDENT` (Level 20) — Enrolled academic context & attendance history

---

## 4. Authentication Boundary

- `authenticateRequest` middleware verifies standard cryptographically signed Bearer tokens using HMAC-SHA256.
- Fake/mock credentials in headers have been removed from the runtime path.
- Unauthenticated requests to protected endpoints are strictly rejected with `401 Unauthorized`.
- Full authentication flows (password hashing, login, OTP, email activation) will be implemented in subsequent phases.

---

## Directory Structure

```
backend/
├── package.json               # Dependencies and npm scripts
├── tsconfig.json              # Strict TypeScript compiler options
├── jest.config.js             # Jest testing configuration
├── .env.example               # Sanitized environment template
├── .gitignore                 # Excludes secrets, dist, coverage
├── src/
│   ├── app.ts                 # Express app assembly & global middleware
│   ├── server.ts              # Server lifecycle & graceful shutdown
│   ├── config/
│   │   └── env.ts             # Zod-validated environment configuration
│   ├── constants/
│   │   ├── roles.ts           # AppRole enums, hierarchy, and normalization
│   │   └── status.ts          # Academic, Timetable, & Attendance status enums
│   ├── db/
│   │   └── connection.ts      # Reusable Mongoose connection pool manager
│   ├── models/                # 18 Mongoose models with typed schemas and indexes
│   │   ├── college.model.ts
│   │   ├── department.model.ts
│   │   ├── course.model.ts
│   │   ├── academicYear.model.ts
│   │   ├── semester.model.ts
│   │   ├── section.model.ts
│   │   ├── subject.model.ts
│   │   ├── user.model.ts      # Refactored with instituteId & activationStatus
│   │   ├── faculty.model.ts
│   │   ├── student.model.ts
│   │   ├── facultyAssignment.model.ts
│   │   ├── studentEnrollment.model.ts
│   │   ├── timetable.model.ts
│   │   ├── attendanceSession.model.ts
│   │   ├── attendanceRecord.model.ts
│   │   ├── note.model.ts
│   │   ├── notification.model.ts
│   │   ├── auditLog.model.ts
│   │   └── index.ts
│   ├── middleware/
│   │   ├── auth.middleware.ts     # Bearer token verification boundary
│   │   ├── tenant.middleware.ts   # College isolation enforcement
│   │   ├── role.middleware.ts     # RBAC verification
│   │   ├── validate.middleware.ts # Zod request validation
│   │   ├── error.middleware.ts    # Global error handler
│   │   └── notFound.middleware.ts # 404 handler
│   ├── services/                  # Business logic and cross-entity operations
│   ├── controllers/               # Express request/response handlers
│   ├── routes/
│   │   ├── health.routes.ts       # Health endpoint (/health)
│   │   └── v1/                    # Versioned API routes (/api/v1/*)
│   ├── utils/
│   │   ├── apiError.ts            # Standardized API error hierarchy
│   │   ├── apiResponse.ts         # Consistent JSON response envelope
│   │   ├── asyncHandler.ts        # Async controller error catcher
│   │   ├── logger.ts              # Sanitized logger
│   │   └── token.ts               # Cryptographic HMAC-SHA256 token utility
│   └── types/
│       ├── auth.types.ts
│       ├── tenant.types.ts
│       └── express.d.ts
└── tests/
    ├── setup.ts                   # In-memory MongoDB test environment
    ├── helpers/
    │   └── auth.helper.ts         # Isolated signed token generator for tests
    ├── unit/                      # Config, Roles, Error utility unit tests
    └── integration/               # API, Database, Multi-tenant, Identity, Models tests
```

---

## Environment Configuration

Create a `.env` file in `backend/` based on `.env.example`:

```env
# MongoDB Atlas Connection
MONGODB_URI=mongodb+srv://acadex_backend:<password>@acadexsync.xxxxx.mongodb.net/acadex?retryWrites=true&w=majority
MONGODB_DATABASE=acadex

# Server Settings
PORT=5000
NODE_ENV=development

# JWT & Security
JWT_SECRET=your_super_secret_jwt_key_at_least_32_chars_long
JWT_EXPIRES_IN=1d
CORS_ORIGIN=*
```

---

## Running & Testing

```bash
# Typecheck & Build
npm run typecheck
npm run build

# Run Automated Test Suite
npm test

# Run Development Server
npm run dev
```

---

## Core API Endpoints

| Method | Endpoint | Description | Access |
|---|---|---|---|
| `GET` | `/health` | Service and database connectivity health check | Public |
| `GET` | `/api/v1/health` | Versioned service and database health check | Public |
| `GET` | `/api/v1/auth/me` | Current authenticated user context & tenant scope | Authenticated |
| `GET` | `/api/v1/users/institute/:instituteId` | Lookup user by institutional business ID | Authenticated (Scoped) |
| `GET` | `/api/v1/colleges` | List colleges | Authenticated |
| `POST` | `/api/v1/colleges` | Register new college tenant | `SUPER_ADMIN` |
| `GET` | `/api/v1/departments` | List college-scoped departments | Authenticated (Scoped) |
| `POST` | `/api/v1/departments` | Create department in college | `COLLEGE_ADMIN` |
| `GET` | `/api/v1/timetables` | List timetables | Authenticated (Scoped) |
| `POST` | `/api/v1/timetables` | Create draft timetable | `HOD`, `COLLEGE_ADMIN` |
| `POST` | `/api/v1/timetables/:id/publish` | Publish timetable | `HOD`, `COLLEGE_ADMIN` |
| `GET` | `/api/v1/attendance` | List attendance sessions | Authenticated (Scoped) |
| `POST` | `/api/v1/attendance/submit` | Submit attendance session & records | `FACULTY`, `HOD`, `COLLEGE_ADMIN` |
| `GET` | `/api/v1/attendance/student/:id/summary` | Compute student attendance metrics | Authenticated (Scoped) |
| `GET` | `/api/v1/audit` | List administrative audit logs | `COLLEGE_ADMIN`, `SUPER_ADMIN` |
