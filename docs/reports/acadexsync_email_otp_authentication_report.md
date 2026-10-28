# ACADEXSYNC Phase 2: Secure Email OTP, Registration, and Institutional Activation Report

## Executive Summary
Phase 2 builds directly upon the Phase 1 Resend transactional email foundation to deliver a cryptographically secure, rate-limited email OTP authentication, self-registration, and institutional account activation system for ACADEXSYNC.

The implementation preserves existing data schemas, multi-tenant workspace memberships, role-based access control, PIN Numbers (`instituteId`), and backward-compatible password login flows, while introducing secure email OTP challenge handling and strict invitation-to-verified-email binding.

---

## Architecture & Security Decisions

### 1. Dedicated OTP Engine (`OtpService`)
- **Cryptographic Random Generation**: Generates 6-digit numeric OTPs via `crypto.randomInt(100000, 1000000)`.
- **Hashed Storage**: OTPs are NEVER stored or logged in plaintext. They are hashed using HMAC-SHA256 (`crypto.createHmac('sha256', env.JWT_RESET_SECRET)`).
- **Constant-Time Verification**: Uses `crypto.timingSafeEqual` over hex buffer digests to prevent timing attacks.
- **Configurable Expiry & Defaults**: Default expiration is 5 minutes (`OTP_EXPIRES_IN=300`).
- **Resend Cooldown**: Enforces a strict 60-second database-backed cooldown (`OTP_RESEND_COOLDOWN=60`) between dispatch requests to the same destination/purpose.
- **Brute-Force Protection**: Limits invalid attempts to 5 (`OTP_MAX_ATTEMPTS=5`). Exceeding the threshold permanently invalidates the OTP.
- **Purpose Binding**: Each OTP challenge is strictly indexed and bound to its purpose (`login`, `registration`, `account_activation`, `password_reset`). An OTP generated for login cannot be used for registration or activation.
- **Single-Use Invalidation**: Consumed OTPs are atomically stamped with `consumedAt = new Date()`, preventing reuse or replay attacks.
- **Enumeration Defense**: Endpoints return generic responses (`"If an active account exists with this email, a verification code has been sent."`) so attackers cannot probe for registered emails.
- **Zero False Claims**: If Resend fails to deliver an email, the OTP record is purged, an operational error is logged, and a 500 error is returned.

### 2. Multi-Workspace & Global Identity Architecture (`AuthService`)
- **Session Issuance (`issueSessionForUser`)**:
  - Unified session and token creation logic for password login, OTP login, and self-registration.
  - Automatically queries and populates `activeWorkspace` and `availableWorkspaces` based on `WorkspaceMembership` and `WorkspaceRoleAssignment`.
  - Supports self-registered global users: `collegeId: null`, `activeWorkspace: null`, `availableWorkspaces: []`, base role `STUDENT`.
  - Enforces tenant isolation: All institutional routes require an active institutional membership; global accounts without membership cannot access college data.

### 3. Self-Registration Flow
1. `POST /api/v1/auth/register/request-otp`:
   - Checks if email already exists (returns generic response if present).
   - Generates and dispatches `REGISTRATION` OTP.
2. `POST /api/v1/auth/register/verify-otp`:
   - Verifies OTP.
   - Issues short-lived `registrationToken` signed with `ACTIVATION_CODE_SECRET`.
3. `POST /api/v1/auth/register/complete`:
   - Validates `registrationToken` and password policy.
   - Checks for duplicate account creation.
   - Creates `User` with `role: STUDENT`, `collegeId: null`, `accountStatus: ACTIVE`.
   - Returns authenticated JWT session (`accessToken`, `refreshToken`, `activeWorkspace: null`).

### 4. Institutional Account Activation Flow
1. `POST /api/v1/auth/institutional-activate/request-otp`:
   - User enters registered invitation email.
   - Verifies eligible pending invitation exists for that email's user.
   - Dispatches `ACCOUNT_ACTIVATION` OTP.
2. `POST /api/v1/auth/institutional-activate/verify-otp`:
   - Verifies OTP.
   - Issues signed `emailVerificationToken` with payload `{ email, purpose: 'email_verification' }`.
3. `POST /api/v1/auth/institutional-activate/complete`:
   - Verifies `emailVerificationToken`.
   - Validates activation code (`XXXX-XXXX-XXXX`), code hash, and pending invitation state.
   - **STRICT BINDING**: Enforces `normalizeEmail(user.email) === normalizeEmail(verifiedEmail)`. A different verified email CANNOT activate another person's invitation.
   - Atomically transitions invitation to `USED`.
   - **Existing Global Accounts**: If the user already has an active account, password is preserved unchanged and the new `WorkspaceMembership` + `WorkspaceRoleAssignment` are attached without creating duplicate users.
   - **New Users**: Validates password, hashes with PBKDF2/bcrypt, sets `accountStatus: ACTIVE`, and activates membership.
   - Returns activation success confirmation. User logs in via standard login endpoints.

---

## API Contracts Summary

| Method | Endpoint | Description | Rate Limit |
|---|---|---|---|
| `POST` | `/api/v1/auth/login` | Existing password login (PIN, email, or phone) | `loginRateLimiter` |
| `POST` | `/api/v1/auth/login/request-otp` | Request email OTP for login | `forgotPasswordRateLimiter` |
| `POST` | `/api/v1/auth/login/verify-otp` | Verify login OTP & receive tokens | `otpVerifyRateLimiter` |
| `POST` | `/api/v1/auth/register/request-otp` | Request OTP for self-registration | `forgotPasswordRateLimiter` |
| `POST` | `/api/v1/auth/register/verify-otp` | Verify registration OTP & get `registrationToken` | `otpVerifyRateLimiter` |
| `POST` | `/api/v1/auth/register/complete` | Complete registration & establish session | `loginRateLimiter` |
| `POST` | `/api/v1/auth/institutional-activate/request-otp` | Request activation OTP for invitation email | `forgotPasswordRateLimiter` |
| `POST` | `/api/v1/auth/institutional-activate/verify-otp` | Verify OTP & get `emailVerificationToken` | `otpVerifyRateLimiter` |
| `POST` | `/api/v1/auth/institutional-activate/complete` | Complete institutional activation with code | `activationRateLimiter` |
| `POST` | `/api/v1/auth/activate/*` | Backward-compatible code-first activation routes | Existing limiters |

---

## Verification & Test Results

### 1. Backend Typecheck
```bash
npm run typecheck
# Result: 0 errors (tsc --noEmit passed)
```

### 2. Integration Test Suite (`tests/integration/email_otp_auth_flow.test.ts`)
```bash
npx jest tests/integration/email_otp_auth_flow.test.ts --forceExit
# Result: 22 passed, 22 total (100% PASS)
```
- **Section A (OTP Security)**:
  - Valid OTP verification & hash verification in DB.
  - Incorrect OTP rejection & attempt counter increment.
  - Max failed attempts (5) permanent invalidation.
  - Expired OTP rejection.
  - Reused OTP rejection (single-use constraint).
  - Wrong-purpose OTP rejection.
  - 60-second resend cooldown enforcement (429 Too Many Requests).
  - Provider failure safe handling without false claims.
- **Section B (Existing Account Login)**:
  - Password login regression test.
  - Email OTP login with full session issuance.
  - Generic enumeration defense for non-existent accounts.
  - Unactivated (`PENDING_ACTIVATION`) login block.
- **Section C (Create Account)**:
  - 3-step self-registration with base role (`STUDENT`) and zero college access (`activeWorkspace: null`).
  - Duplicate account prevention.
  - Password mismatch validation.
- **Section D (Activate Institutional Account)**:
  - Full email-first activation flow.
  - Strict email mismatch rejection (403 Forbidden).
  - Invalid activation code rejection.
  - Expired activation code rejection.
  - Reused activation code rejection.
  - Multi-workspace attachment for existing global user without identity duplication.
- **Section E (Tenant Isolation)**:
  - College-scoped access enforcement and tenant boundaries.

### 3. Unit Test Suites
```bash
npx jest tests/unit/otp.test.ts tests/unit/email_service.test.ts
# Result: 25 passed, 25 total (100% PASS)
```

### 4. Production Build
```bash
npm run build
# Result: tsc -p tsconfig.build.json succeeded with exit code 0
```
