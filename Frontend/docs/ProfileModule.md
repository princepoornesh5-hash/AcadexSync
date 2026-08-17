# Acadex User Profile & Profile Editing Specification

## 1. Overview & Architecture
This module implements the role-aware profile screen, field immutability rules, academic info resolution, and integration with Firestore `users/{uid}` collection.

```
Profile UI (ProfileScreen)
       │
       ▼
Riverpod Providers (authProvider, collegesProvider, etc.)
       │
       ▼
UserProfileRepository (Abstract Interface)
       │
       ├── Mock Mode ──────► MockUserProfileRepository (In-Memory DevRegistry)
       └── Firebase Mode ──► FirebaseUserProfileRepository
                                   │
                                   ▼
                             Cloud Firestore (users/{uid})
```

---

## 2. Field Permissions
Security settings and role updates are strictly protected at both client and database level:
- **Editable Fields**: `name`, `phone`
- **Protected Fields**: `role`, `collegeId`, `departmentId`, `profileId`, `accountStatus`, `firebaseUid`

---

## 3. Academic Details Resolution
To prevent data duplication and consistency issues, academic names are resolved dynamically via the `AcademicRepository` using stored relational IDs:
- `collegeId` -> Resolved from `collegesProvider`
- `departmentId` -> Resolved from `departmentsProvider`
- `courseId` -> Resolved from `coursesProvider` (Students only)
- `semesterId` -> Resolved from `semestersProvider` (Students only)
- `sectionId` -> Resolved from `sectionsProvider` (Students only)
