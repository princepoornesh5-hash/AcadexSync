# Acadex Firestore Academic Structure (`Prompt 23`)

## Architecture & Overview
This document specifies the Firestore Academic Structure backend architecture, document schemas, relationship hierarchies, and provider wiring.

```
Academic UI (Colleges / Departments / Courses / Semesters / Sections / Subjects / Students / Faculty)
       │
       ▼
Riverpod Providers (academicRepositoryProvider)
       │
       ▼
AcademicRepository (Abstract Domain Interface)
       │
       ├── Mock Mode ──────► MockAcademicRepository (In-Memory Data)
       └── Firebase Mode ──► FirebaseAcademicRepository
                                   │
                                   ▼
                             Cloud Firestore
```

---

## Firestore Collections

1. **`colleges`**: `{ id, name, code, address, email, phone, principal, isActive, logoUrl }`
2. **`departments`**: `{ id, collegeId, name, code, hodId, description, isActive }`
3. **`courses`**: `{ id, departmentId, name, code, isActive }`
4. **`academicYears`**: `{ id, collegeId, name, startDate, endDate, isActive }`
5. **`semesters`**: `{ id, courseId, academicYearId, name, number, isActive }`
6. **`sections`**: `{ id, semesterId, name, isActive }`
7. **`subjects`**: `{ id, departmentId, semesterId, name, code, credits, type, isActive }`
8. **`faculty`**: `{ id, departmentId, name, employeeId, email, phone, isActive, subjectIds, sectionIds }`
9. **`students`**: `{ id, collegeId, departmentId, courseId, semesterId, sectionId, name, rollNumber, email, phone, isActive, history }`

---

## Provider Architecture
- `academicRepositoryProvider`: Supplies `FirebaseAcademicRepository` when Firebase is active, falling back to `MockAcademicRepository` when offline/mock mode is active.
- All presentation screen providers (`collegesProvider`, `departmentsProvider`, `studentsProvider`, etc.) subscribe directly to `academicRepositoryProvider`.
