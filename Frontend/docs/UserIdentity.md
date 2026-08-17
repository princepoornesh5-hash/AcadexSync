# Acadex User Identity Architecture (`Prompt 22.1`)

## Overview
This document specifies the minimal Firebase User Profile & Role Identity architecture connecting Firebase Authentication with Cloud Firestore user profiles (`users/{firebaseUid}`).

---

## Identity Resolution Architecture

```
Firebase Authentication (Email/Password)
       │
       ▼
FirebaseAuth.instance.currentUser.uid (Firebase UID)
       │
       ▼
Cloud Firestore Document: users/{firebaseUid}
       │
       ▼
Read Profile (role, accountStatus, collegeId, departmentId)
       │
       ├── accountStatus != 'active' ──► Access Denied ("Account is [status]")
       └── accountStatus == 'active'
               │
               ▼
       UserModel initialized in Riverpod AuthNotifier
               │
               ▼
       AppRouter Guard ──► Redirects to Role Dashboard
```

---

## Firestore Schema: `users/{firebaseUid}`

Each authenticated user profile document is keyed **strictly by their Firebase UID**:

### Path
`users/{firebaseUid}` (e.g., `users/aB3x9Yz8kL2m1P4q5R6s7T8u9V0`)

> [!IMPORTANT]
> **Document ID Requirement**: The document key **MUST** match the authenticated user's `firebaseUid`. Never use email addresses or incremental integer IDs as document keys.

### Document Fields
```json
{
  "id": "aB3x9Yz8kL2m1P4q5R6s7T8u9V0",
  "firebaseUid": "aB3x9Yz8kL2m1P4q5R6s7T8u9V0",
  "name": "Prof. Alan Turing",
  "email": "faculty.test@acadex.com",
  "role": "faculty",
  "collegeId": "college-001",
  "departmentId": "dept-cs",
  "profileId": "prof-101",
  "accountStatus": "active",
  "createdAt": "2026-08-08T00:00:00.000Z",
  "updatedAt": "2026-08-08T00:00:00.000Z",
  "lastLoginAt": "2026-08-08T18:30:00.000Z"
}
```

---

## Supported Roles & Account Statuses

### Strongly Typed Roles (`AppRole`)
- `superAdmin` ➔ `/dashboard/super_admin`
- `collegeAdmin` ➔ `/dashboard/college_admin`
- `hod` ➔ `/dashboard/hod`
- `faculty` ➔ `/dashboard/faculty`
- `student` ➔ `/dashboard/student`

### Account Statuses (`AccountStatus`)
- `active`: Account is authorized to access the application.
- `inactive`: Account disabled by administration.
- `suspended`: Account temporarily locked due to policy violation.
- `pending`: Account creation pending administrator approval.

---

## Step-by-Step Development & Testing Setup

### 1. Create User in Firebase Console
1. Open [Firebase Console](https://console.firebase.google.com/).
2. Go to **Authentication** ➔ **Users** ➔ **Add user**.
3. Create a test account (e.g. `faculty.test@acadex.com` with password `Password123!`).
4. Copy the generated **User UID** (e.g., `wX9yZ...`).

### 2. Create Profile Document in Cloud Firestore
1. In Firebase Console, go to **Firestore Database** ➔ **Data**.
2. Click **Start collection** ➔ Collection ID: `users`.
3. Set **Document ID** to the exact copied **User UID** (`wX9yZ...`).
4. Add fields:
   - `firebaseUid` (string): `wX9yZ...`
   - `id` (string): `wX9yZ...`
   - `name` (string): `Dr. Ada Lovelace`
   - `email` (string): `faculty.test@acadex.com`
   - `role` (string): `faculty`
   - `accountStatus` (string): `active`
5. Save the document.

### 3. Log In to Acadex
1. Open the Acadex Login Screen.
2. Enter `faculty.test@acadex.com` and `Password123!`.
3. Firebase Auth authenticates the user, retrieves the profile from `users/{uid}`, parses `role = faculty`, and routes automatically to the Faculty Dashboard (`/dashboard/faculty`).

---

## Security Policy Summary

1. **No Client-Side Role Determination**: Client dropdowns or selection buttons cannot mutate or specify the user's role during login.
2. **No Default Student Fallback**: If an authenticated Firebase user lacks a document in `users/{firebaseUid}`, the system throws a `BackendPermissionException` displaying:
   `"Your Acadex profile has not been configured yet."`
3. **Session Clearing on Logout**: Logging out executes `auth.signOut()`, clears local Riverpod state, and wipes `SessionManager` storage.
