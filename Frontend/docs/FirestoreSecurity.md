# Acadex Firestore Security & Role-Based Authorization (`Prompt 25`)

## Overview
This document specifies the production Firestore Security Rules architecture (`firestore.rules`), helper functions, role policies, account status enforcement, and field immutability constraints.

---

## 1. Primary Security Architecture

```
Client Requests (Flutter Web / Android / iOS)
       │
       ▼
Cloud Firestore Security Rules (firestore.rules)
       │
       ├── 1. Authentication Check: request.auth != null
       ├── 2. Account Status Check: userProfile().accountStatus == 'active'
       ├── 3. Role Policy Check: userRole() in [superAdmin, collegeAdmin, hod, faculty, student]
       ├── 4. Field Immutability Check: diff().affectedKeys().hasAny([...])
       └── 5. Valid Status Check: status in ['present', 'absent', 'late', ...]
```

---

## 2. Security Helper Functions (`firestore.rules`)
- `isSignedIn()`: Checks `request.auth != null`.
- `isOwnUser(uid)`: Checks `request.auth.uid == uid`.
- `userProfile()`: Retrieves `users/{request.auth.uid}` document data.
- `userRole()`: Returns `userProfile().role`.
- `isActiveUser()`: Returns `userProfile().accountStatus == 'active'`.
- `isSuperAdmin()`: Checks if role is `superAdmin` or `super_admin`.
- `isCollegeAdmin()`: Checks if role is `collegeAdmin` or `college_admin`.
- `isHOD()`: Checks if role is `hod`.
- `isFaculty()`: Checks if role is `faculty`.
- `isStudent()`: Checks if role is `student`.
- `sameCollege(collegeId)`: Verifies user belongs to target college or is Super Admin.

---

## 3. Mandatory Security Matrix

| Scenario | Super Admin | College Admin | HOD | Faculty | Student | Unauthenticated / Inactive |
| :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| **Read Own Profile** | ALLOWED | ALLOWED | ALLOWED | ALLOWED | ALLOWED | DENIED |
| **Self-Elevate Role** | DENIED | DENIED | DENIED | DENIED | DENIED | DENIED |
| **Write Attendance** | ALLOWED | ALLOWED | ALLOWED | ALLOWED | DENIED | DENIED |
| **Read Own Attendance** | ALLOWED | ALLOWED | ALLOWED | ALLOWED | ALLOWED | DENIED |
| **Read Other Student Attendance** | ALLOWED | ALLOWED | ALLOWED | ALLOWED | DENIED | DENIED |
| **Academic Structure Write** | ALLOWED | ALLOWED | DENIED | DENIED | DENIED | DENIED |
| **Cross-College Access** | ALLOWED | DENIED | DENIED | DENIED | DENIED | DENIED |

---

## 4. Account Status Policy
- Only accounts with `accountStatus == 'active'` are granted read/write permissions to application resources.
- `inactive`, `suspended`, or `pending` status documents trigger explicit denial in `firestore.rules`.
