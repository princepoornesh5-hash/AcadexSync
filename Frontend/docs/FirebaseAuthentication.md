# Acadex Firebase Authentication Documentation

This document details the Firebase Authentication, User Identity, and Role Resolution architecture for Acadex.

## 1. Authentication Architecture & Flow

```
Application Start
       │
       ▼
WidgetsFlutterBinding.ensureInitialized()
       │
       ▼
FirebaseInitializer.initialize() (DefaultFirebaseOptions)
       │
       ▼
Check FirebaseAuth.instance.currentUser / authStateChanges()
       ├── Unauthenticated ──► Login Screen (/login)
       └── Authenticated
               │
               ▼
       Get Firebase UID
               │
               ▼
       Load Acadex User Profile (users/{uid})
               │
               ├── Profile Not Found ──► Display Error (No default role)
               └── Profile Loaded
                       │
                       ▼
               Read Trusted AppRole
                       │
                       ▼
               Validate AccountStatus (active / inactive / suspended)
                       │
                       ▼
               Riverpod AuthState (AuthAuthenticated)
                       │
                       ▼
               AppRouter Guard ──► Navigate to Role Dashboard
```

## 2. User Identity Model

The application identity model (`UserModel`) bridges Firebase Authentication with Acadex application data:

| Property | Type | Source | Description |
| :--- | :--- | :--- | :--- |
| `id` | `String` | Acadex DB / Firebase | Primary application identifier |
| `firebaseUid` | `String` | Firebase Auth | Immutable Firebase UID |
| `email` | `String` | Firebase Auth | Authenticated user email |
| `name` | `String` | Profile / Auth | User display name |
| `role` | `AppRole` | Acadex Profile | Trusted role enum (`superAdmin`, `collegeAdmin`, `hod`, `faculty`, `student`) |
| `accountStatus` | `AccountStatus` | Acadex Profile | `active`, `inactive`, `suspended`, `pending` |
| `collegeId` | `String?` | Acadex Profile | Scoped college identifier |
| `departmentId` | `String?` | Acadex Profile | Scoped department identifier |
| `createdAt` | `DateTime?` | System | Account creation timestamp |
| `lastLoginAt` | `DateTime?` | System | Last login timestamp |

## 3. Role Resolution & Security Assumptions

> [!IMPORTANT]
> **No Client-Side Role Selection:**
> The Login Screen accepts only `email` and `password`. The client has zero ability to specify or select a role during login. Roles are retrieved solely from trusted backend identity data.

> [!WARNING]
> **No Default Fallbacks:**
> If a user's role cannot be determined or if an account has no profile document, the system does **not** fall back to `student`. It displays a development error (`"Authentication successful, but your Acadex profile could not be found."`) and halts navigation.

### Supported Roles & Dashboards

| Role | Enum | Route |
| :--- | :--- | :--- |
| Super Admin | `AppRole.superAdmin` | `/dashboard/super_admin` |
| College Admin | `AppRole.collegeAdmin` | `/dashboard/college_admin` |
| HOD | `AppRole.hod` | `/dashboard/hod` |
| Faculty | `AppRole.faculty` | `/dashboard/faculty` |
| Student | `AppRole.student` | `/dashboard/student` |

## 4. Development Test User Setup

To test each role in your Firebase Console, create test users in **Firebase Console > Authentication > Users** using the following email naming conventions:

| Role | Suggested Test Email | Password |
| :--- | :--- | :--- |
| **Super Admin** | `superadmin.test@acadex.com` | Set in Console (e.g. `acadex123`) |
| **College Admin** | `admin.test@acadex.com` | Set in Console (e.g. `acadex123`) |
| **HOD** | `hod.test@acadex.com` | Set in Console (e.g. `acadex123`) |
| **Faculty** | `faculty.test@acadex.com` | Set in Console (e.g. `acadex123`) |
| **Student** | `student.test@acadex.com` | Set in Console (e.g. `acadex123`) |

## 5. Transition to Firestore in Prompt 23

Currently, temporary development profiles are mapped based on UID lookups in `FirestoreService.getDocument('users', uid)`.

In **Prompt 23**, this temporary mapping will be seamlessly replaced by real Firestore document reads under the `users/{uid}` collection:

```json
// Firestore: users/{uid}
{
  "firebaseUid": "aB3x9Yz...",
  "email": "faculty.test@acadex.com",
  "name": "Prof. Alan Turing",
  "role": "FACULTY",
  "accountStatus": "active",
  "collegeId": "col_1",
  "departmentId": "dept_cs",
  "createdAt": "2026-08-08T00:00:00.000Z"
}
```

Because `FirebaseAuthRepository` relies on `FirestoreService.getDocument()`, migrating to full Firestore in Prompt 23 requires zero changes to the UI or provider layers.
