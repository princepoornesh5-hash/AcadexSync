# ACADEX — PHASE AUTHENTICATION LOGIN VERTICAL SLICE REPORT

## 1. Backend Login Contract

- **Endpoint**: `POST /api/v1/auth/login`
- **Request Body**:
  ```json
  {
    "identifier": "user@acadex.edu",
    "password": "password123"
  }
  ```
- **Identifier Handling**: Server normalizes identifier via `normalizeIdentifier` supporting both Email and Phone number formats.
- **Verification Chain**:
  1. Look up user by normalized email or phone.
  2. Verify account status (`ACTIVE` required).
  3. Verify college status (`ACTIVE` required for tenant users).
  4. Verify bcrypt password hash via `PasswordService.verifyPassword`.
  5. Generate UUID `sessionId` and create persistent `AuthSession` in MongoDB.
  6. Sign JWT Access Token and Refresh Token with payload context.
- **Success Response (200 OK)**:
  ```json
  {
    "success": true,
    "message": "Login successful",
    "data": {
      "accessToken": "eyJhbGciOi...",
      "refreshToken": "eyJhbGciOi...",
      "user": {
        "id": "65b...",
        "instituteId": "STU2026001",
        "name": "Jane Doe",
        "email": "jane@acadex.edu",
        "role": "STUDENT",
        "accountStatus": "active"
      }
    }
  }
  ```
- **Error Responses**:
  - `401 Unauthorized`: `"Invalid credentials"`
  - `403 Forbidden`: `"Account is pending activation. Please activate your account first."`
  - `403 Forbidden`: `"Account has been deactivated. Please contact your administrator."`
  - `403 Forbidden`: `"Account is currently not active."`
  - `429 Too Many Requests`: Rate limit exceeded

---

## 2. Flutter Login Binding

- **Screen**: [`LoginScreen`](file:///Users/poornesh/Campus%20Management%20Main/Frontend/lib/features/auth/presentation/screens/login_screen.dart)
- **Notifier**: [`AuthNotifier`](file:///Users/poornesh/Campus%20Management%20Main/Frontend/lib/features/auth/presentation/providers/auth_provider.dart#L42-L160)
- **Repository**: [`ApiAuthRepository`](file:///Users/poornesh/Campus%20Management%20Main/Frontend/lib/features/auth/data/repositories/api_auth_repository.dart#L13-L38)
- **Network Client**: [`ApiClient`](file:///Users/poornesh/Campus%20Management%20Main/Frontend/lib/core/network/api_client.dart)
- **Router**: [`app_router.dart`](file:///Users/poornesh/Campus%20Management%20Main/Frontend/lib/app/router/app_router.dart)

---

## 3. Token Lifecycle & Storage

- **Storage Engine**: `FlutterSecureStorage` exclusively.
- **Keys**: `access_token` and `refresh_token`.
- **Zero Insecure Storage**: SharedPreferences is never used for security tokens.

---

## 4. Session Restoration & Auto-Refresh

- **Session Restoration**: On app startup, `_loadProfile(uid)` executes `GET /api/v1/auth/me`. If valid, the session is restored and the user is routed to their role-specific dashboard.
- **401 Auto-Refresh**: If an access token expires during an API request, `ApiClient` interceptor intercepts `401 Unauthorized`, issues `POST /api/v1/auth/refresh` on an isolated Dio client, updates stored tokens, and retries the original request seamlessly.

---

## 5. Account Status Handling

- **`active`**: Authenticated session created, tokens saved, navigated to role dashboard.
- **`pending_activation`**: Display warning SnackBar with action button **"Activate Now"** routing to `/activate`.
- **`deactivated` / `suspended`**: Display danger banner explaining account deactivation.

---

## 6. Role Routing Verification

| Authenticated Role | Canonical Dashboard Route | Guard Enforcement |
| :--- | :--- | :--- |
| **SUPER_ADMIN** | `/dashboard/super_admin` | Protected by `app_router.dart` |
| **COLLEGE_ADMIN**| `/dashboard/college_admin` | Protected by `app_router.dart` |
| **HOD** | `/dashboard/hod` | Protected by `app_router.dart` |
| **FACULTY** | `/dashboard/faculty` | Protected by `app_router.dart` |
| **STUDENT** | `/dashboard/student` | Protected by `app_router.dart` |

---

## 7. Security Audit

- **Hardcoded Production Credentials**: 0 found.
- **Private ImageKit / Firebase Admin keys in Flutter**: 0 found.
- **Passwords logged to console**: 0 found.

---

## 8. Test Verification

- **`flutter analyze`**: **0 issues found**
- **`test/auth_login_vertical_slice_test.dart`**: **16/16 tests passed (100%)**
- **All Flutter test suites**: **55/55 tests passed (100%)**

---

## 9. Production Files Modified

1. [`Frontend/lib/features/auth/presentation/screens/login_screen.dart`](file:///Users/poornesh/Campus%20Management%20Main/Frontend/lib/features/auth/presentation/screens/login_screen.dart)
2. [`Frontend/lib/features/auth/presentation/providers/auth_provider.dart`](file:///Users/poornesh/Campus%20Management%20Main/Frontend/lib/features/auth/presentation/providers/auth_provider.dart)
3. [`Frontend/test/auth_login_vertical_slice_test.dart`](file:///Users/poornesh/Campus%20Management%20Main/Frontend/test/auth_login_vertical_slice_test.dart)

---

## 10. Status

🟢 **VERIFIED — FULL VERTICAL SLICE COMPLETE**
