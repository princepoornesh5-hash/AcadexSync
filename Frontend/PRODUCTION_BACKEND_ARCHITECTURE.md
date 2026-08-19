# Acadex Production Backend Architecture

This document describes the final security and architectural boundaries of the Acadex production backend on Firebase.

## 1. Firebase Initialization Boundary
Acadex supports dual execution modes:
- **Development Mode (Mock):** Running in `kDebugMode` without a valid `firebase_options.dart` will gracefully fall back to an entirely offline memory store (`MockRepositories`) using `DevIdentityRegistry`.
- **Production Mode (Release):** Running `flutter build --release` strictly disables all Mock environments. `FirebaseInitializer` requires valid Firebase configuration credentials. If they are missing, the initialization immediately fails, completely preventing local mock fallback.

## 2. Authentication Flow
Acadex uses **Firebase Authentication** as the absolute source of truth for identity.

1. **Login Request:** Sent via `FirebaseAuthRepository` to Firebase.
2. **Firebase Token:** Firebase validates the email/password.
3. **Firestore Profile:** The `uid` returned by Firebase is used to fetch the user profile from `users/{uid}`.
4. **Validation Check:** If the profile does not exist or the account is suspended (`status != active`), the system immediately calls `signOut()` on Firebase Auth to prevent a dangling unconfigured session.

## 3. Activation Security
Account activation (specifically for Students) relies on an out-of-band Activation Code.
Since students do not have an account until they activate:
1. The `activationCodes` collection is readable without authentication (`allow get: if true;`). List enumeration is blocked.
2. The user validates the code, creating a `FirebaseAuth` user.
3. Once the auth context exists, a Firestore transaction atomically marks the activation code as `used` and creates the associated `users/{uid}` document.

## 4. Multi-Tenant Isolation
Acadex implements **Platform -> College -> Department -> Data** tenancy.

### Firestore Rules Enforcement
`firestore.rules` enforces the boundary securely at the backend. Even if a modified client sends a request to edit another college's data, the rules engine enforces:
```javascript
  allow update: if isSignedIn() && isActiveUser() && (
    isSuperAdmin() || 
    (isCollegeAdmin() && userProfile().collegeId == resource.data.collegeId && request.resource.data.collegeId == userProfile().collegeId)
  );
```
- **SuperAdmin** has global platform visibility.
- **CollegeAdmin** can only read/write documents where `collegeId` strictly matches their own profile's `collegeId`.

### Frontend Validation
`AcademicRepository` also validates context on the frontend (`_validateScope`), preventing developers from accidentally writing cross-tenant requests.

## 5. Deployment Readiness
The current configuration is verified to compile using:
`flutter build web --release`

Before deploying to Firebase Hosting, run `flutterfire configure` to generate the final `firebase_options.dart` file containing the production keys.
