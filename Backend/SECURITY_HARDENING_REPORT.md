# ACADEX — Production Hardening & Security Audit Report (Phase 9O.1)

## 1. Security Issues Discovered & Evaluated

| Component | Area | Risk / Finding | Status | Fix Applied |
|---|---|---|---|---|
| **HTTP Headers** | Global Express Pipeline | Default Express headers exposed `X-Powered-By: Express` and lacked strict CSP, HSTS, and Frameguard configurations. | Fixed | Hardened `helmet` configuration with custom CSP, HSTS (production), `frameguard: { action: 'deny' }`, `noSniff: true`. |
| **CORS** | Browser API Access | Wildcard `*` CORS in production could expose cookies/sessions or permit unauthorized web origins to interact with APIs. | Fixed | Implemented origin verification callback. Wildcard origin warns/rejects in production; enforces environment-configured allowed origin whitelist while allowing non-browser mobile app requests. |
| **Rate Limiting** | Authentication, Uploads, Reports | Lack of dedicated throttling on sensitive endpoints could expose the system to brute-force auth or resource exhaustion via heavy MongoDB aggregation reports. | Fixed | Added configurable sliding-window limiters with standard `X-RateLimit-*` and `Retry-After` headers on `/api/v1` general, auth, file uploads, reports, and device tokens. |
| **User Serialization** | Password Hash Privacy | While `toJSON` stripped `passwordHash`, `toObject` previously did not have an explicit transform, risking accidental exposure if `toObject()` was logged. | Fixed | Added matching `toObject` transform on `UserSchema` to ensure `passwordHash` and `__v` are stripped under all object conversions. |
| **Log Sanitization** | Diagnostic Output | Logger sanitization matched colon `:` patterns but missed equals `=` query parameter style credentials or PEM private key blocks. | Fixed | Extended regexes in `Logger.sanitize` to mask PEM private keys, JWTs, Bearer tokens, passwords, secrets, OTPs, and device tokens under both `:` and `=` syntax. |
| **ImageKit & Media** | Upload & Download | Client requesting unauthorized MIME types or mismatched extensions could lead to file upload abuse. | Verified & Hardened | Enforced strict whitelist for Notes (PDF, DOC, DOCX, PPT, PPTX) and Profile pictures (JPG, JPEG, PNG, WEBP), MIME/extension consistency validation, size limits (25MB notes, 5MB profile), and short-lived signed URLs. |

---

## 2. Security Fixes Implemented

1. **Helmet Security Headers**:
   - `Content-Security-Policy`: Default `'self'`, trusted CDNs for ImageKit (`https://ik.imagekit.io`) and Firebase FCM (`https://fcm.googleapis.com`), `frameAncestors: ["'none'"]`.
   - `Strict-Transport-Security`: Enforced in production (`maxAge: 31536000`, `includeSubDomains: true`, `preload: true`).
   - `X-Frame-Options`: `DENY` (clickjacking prevention).
   - `X-Content-Type-Options`: `nosniff` (MIME sniffing prevention).
   - `Referrer-Policy`: `strict-origin-when-cross-origin`.
   - `DNS-Prefetch-Control`: Disabled.
   - `X-Powered-By`: Removed.

2. **CORS Policy Hardening**:
   - Environment-driven whitelist parsing (`CORS_ORIGIN`).
   - Non-browser mobile (Flutter) and health check requests without `Origin` headers allowed safely.
   - Unauthorized browser origins rejected with structured error.

3. **Rate Limiting Engine**:
   - In-memory sliding window limiter with automatic memory cleanup.
   - Standard headers: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `X-RateLimit-Reset`, and `Retry-After`.
   - Return standard ACADEX error JSON: `429 Too Many Requests` (`code: 'TOO_MANY_REQUESTS'`).

4. **Credential & Log Masking**:
   - MongoDB URIs with credentials (`mongodb+srv://user:pass@host` &rarr; `mongodb+srv://***:***@host`).
   - Bearer and raw JWT tokens (`Bearer eyJ...` &rarr; `Bearer ***`).
   - PEM private keys (`-----BEGIN PRIVATE KEY----- ... -----END PRIVATE KEY-----` &rarr; `***PRIVATE_KEY***`).
   - Passwords, secrets, and OTPs automatically masked in all log levels.

---

## 3. Rate-Limiting Configuration

| Limiter | Target Routes | Default Window | Default Max Requests | Config Env Variable |
|---|---|---|---|---|
| **General API** | `/api/v1/*` | 15 minutes (`900000ms`) | 1000 requests | `RATE_LIMIT_MAX` |
| **Authentication** | `/login`, `/activate`, `/verify-password-reset-otp` | 5 minutes (`300000ms`) | 15 requests | `AUTH_RATE_LIMIT_MAX` |
| **Password Recovery**| `/forgot-password`, `/reset-password` | 10 minutes (`600000ms`) | 10 requests | `AUTH_RATE_LIMIT_MAX` |
| **Upload Auth** | `/notes/upload-url`, `/notes/:id/replace-url`, `/users/*/profile-image/upload-url` | 5 minutes (`300000ms`) | 30 requests | `UPLOAD_RATE_LIMIT_MAX` |
| **Reports Engine** | `/reports/*` | 5 minutes (`300000ms`) | 60 requests | `REPORT_RATE_LIMIT_MAX` |
| **Invitations** | `/auth/invitations` (create & reissue) | 5 minutes (`300000ms`) | 30 requests | `INVITATION_RATE_LIMIT_MAX` |
| **Device Tokens** | `/notifications/device-tokens` | 5 minutes (`300000ms`) | 30 requests | `DEVICE_TOKEN_RATE_LIMIT_MAX` |

---

## 4. Authentication Lifecycle Hardening

- **Access Tokens**: Short-lived (15 minutes default via `ACCESS_TOKEN_EXPIRES_IN=900`).
- **Refresh Tokens**: Long-lived (7 days default via `REFRESH_TOKEN_EXPIRES_IN=604800`), stored only as SHA-256 hashes in `AuthSession` collection.
- **Session Revocation**:
  - `POST /api/v1/auth/logout`: Revokes current active session.
  - `POST /api/v1/auth/logout-all`: Revokes all active sessions for the user.
  - Password Reset: Automatically revokes all active sessions upon successful reset.
  - Revoked sessions are immediately blocked from refreshing tokens.
- **Account Status Enforcements**: Users in `DEACTIVATED` or `PENDING_ACTIVATION` states are rejected across all authenticated endpoints.
- **Constant-Time Verification**: Activation codes and JWT token signatures use constant-time buffer equality (`crypto.timingSafeEqual`) to prevent timing side-channel attacks.

---

## 5. Secret-Management Audit

- **Search Scope**: Entire repository searched for hardcoded API keys, private keys, passwords, and tokens.
- **Results**:
  - `0` hardcoded production secrets found.
  - `0` private keys committed to Git.
  - Cloudflare R2 / AWS S3 variables: **0 references**.
  - ImageKit private key: Exclusively server-side (`backend/src/storage/imagekit.service.ts`).
  - Firebase private key: Exclusively server-side (`backend/src/notifications/fcm.service.ts`).
  - Frontend client: Completely free of backend secrets, database connection strings, and private keys.

---

## 6. ImageKit Media Security Audit

- **Two-Phase Upload**: Clients never receive write access to ImageKit directly without server-issued authorization.
- **MIME & Extension Validation**:
  - Allowed Notes: `application/pdf` (`.pdf`), `application/msword` (`.doc`), `application/vnd.openxmlformats-officedocument.wordprocessingml.document` (`.docx`), `application/vnd.ms-powerpoint` (`.ppt`), `application/vnd.openxmlformats-officedocument.presentationml.presentation` (`.pptx`).
  - Allowed Profile Pictures: `image/jpeg` (`.jpg`, `.jpeg`), `image/png` (`.png`), `image/webp` (`.webp`).
  - Mismatched MIME/extensions (e.g. `.exe` with `application/pdf`) strictly rejected with 400/422.
- **Tenant Isolation**: Folders structured deterministically (`/acadex/colleges/<collegeId>/notes/...`). Users cannot upload outside their tenant namespace.
- **Expiry**: Signed upload signatures and download URLs expire automatically (`SIGNED_URL_EXPIRY_SECONDS=300`).
- **Deleted Content**: Soft-deleted notes return 404 and cannot be downloaded.

---

## 7. MongoDB Tenant-Isolation & Query Audit

- **Tenant Isolation Middleware** (`requireCollegeScope`):
  - Injects authenticated user's `collegeId` into request context.
  - Non-Super Admin users cannot query or mutate cross-college resources.
  - Client-supplied `collegeId` overrides in body/query/params are rejected with `403 Forbidden` if they do not match the JWT.
- **Safe ObjectIds**:
  - Invalid MongoDB ObjectIds in URL parameters return clean `400 Bad Request` (`INVALID_IDENTIFIER`) without leaking Mongoose internal stack traces.
- **Safe Aggregations**:
  - All report pipelines scope queries by tenant college and section IDs at the `$match` stage.

---

## 8. Role-Based Access Control (RBAC) Matrix

| Resource / Endpoint | SUPER_ADMIN | COLLEGE_ADMIN | HOD | FACULTY | STUDENT |
|---|:---:|:---:|:---:|:---:|:---:|
| **Colleges CRUD** | Full Global | View Own | Forbidden (403) | Forbidden (403) | Forbidden (403) |
| **Departments CRUD** | Full Global | Own College | View Own | Forbidden (403) | Forbidden (403) |
| **Faculty Management** | Full Global | Own College | Own Department | View Self | Forbidden (403) |
| **Student Management** | Full Global | Own College | Own Department | Assigned Sections | View Self |
| **Academic Hierarchy** | Full Global | Own College | Own Department | View Assigned | View Enrolled |
| **Timetables Authoring** | Full Global | Own College | Own Department | View Assigned | View Enrolled |
| **Attendance Submission** | Full Global | Own College | Own Department | Assigned Sessions | Forbidden (403) |
| **Notes Upload** | Full Global | Own College | Own Department | Assigned Subjects | Forbidden (403) |
| **Reports (Admin/Dept)**| Full Global | Own College | Own Department | Forbidden (403) | Forbidden (403) |
| **Reports (Personal)** | Full Global | Own College | Own Department | Own Classes | View Self Only |
| **Notification Center** | View Self | View Self | View Self | View Self | View Self |

---

## 9. Firebase FCM Push Notification Security Audit

- FCM server credentials remain strictly server-side.
- Device tokens are registered under the authenticated user's ID (`req.user.id`).
- Token deletion requires authenticated ownership.
- Invalid FCM tokens returned during dispatch are automatically marked inactive in MongoDB.
- Push dispatch failure never breaks core database transactions.

---

## 10. Report & Analytics Security Audit

- Report generation runs role-scoped aggregation pipelines with date-range filters (`today`, `this_week`, `this_month`, `current_semester`, `custom`).
- Students attempting to view other students' reports or section attendance receive `403 Forbidden`.
- Faculty querying unauthorized departments receive `403 Forbidden`.
- Report generation creates secure audit log entries without sensitive credentials.

---

## 11. Security Test Suite Summary

- **File**: `backend/tests/integration/security_hardening.test.ts`
- **Total Security Tests**: 18
- **Coverage**:
  1. Helmet security headers presence.
  2. CORS origin validation.
  3. Sliding-window rate limiter & 429 Retry-After headers.
  4. Expired JWT rejection.
  5. Forged/tampered JWT signature rejection.
  6. Malformed token structure rejection.
  7. Revoked session refresh rejection.
  8. Password hash serialization prevention in `toJSON` and `toObject`.
  9. Malformed JSON handling without internal stack trace leakage.
  10. Invalid MongoDB ObjectId error formatting.
  11. Cross-college tenant isolation enforcement.
  12. Cross-department HOD isolation enforcement.
  13. Cross-student report privacy enforcement.
  14. ImageKit unsupported MIME & extension mismatch rejection.
  15. Student note upload authorization prevention.
  16. Deleted note download prevention.
  17. Cross-user notification inbox isolation.
  18. Logger credential, private key, and JWT sanitization.

---

## 12. Full Test Results

| Test Suite | Total Suites | Total Tests | Result | Execution Time |
|---|:---:|:---:|:---:|:---:|
| **Backend Full Test Suite** | 30 passed, 30 total | 296 passed, 296 total | **100% PASS** | ~99s |
| **Security Hardening Suite**| 1 passed, 1 total | 18 passed, 18 total | **100% PASS** | ~7.3s |
| **Frontend Test Suite** | All suites passed | 747 passed, 747 total | **100% PASS** | ~43s |
| **TypeScript Typecheck** | Backend | 0 errors | **100% PASS** | ~2.5s |
| **Backend Build** | Production `tsc` | 0 errors | **100% PASS** | ~3.1s |
| **Flutter Analyze** | Frontend | 0 issues | **100% PASS** | ~4.1s |

---

## 13. Remaining Risks & Mitigations

1. **Distributed Rate Limiting (Multi-Instance Scaling)**:
   - *Current*: In-memory sliding-window limiter is ideal for single-node / initial production deployments.
   - *Mitigation*: The `createRateLimiter` abstraction is designed to easily plug in a Redis store (e.g. `rate-limit-redis` / `ioredis`) when clustering across multiple horizontal containers.
2. **Reverse Proxy TLS Termination**:
   - *Requirement*: In production behind AWS ALB / Cloudflare / Nginx, set `app.set('trust proxy', 1)` so client IP detection accurately reflects `X-Forwarded-For`.

---

## 14. Production Deployment Checklist

- [x] Configure production environment variables in `.env` (copy from `.env.example`).
- [x] Set `NODE_ENV=production`.
- [x] Generate cryptographically random 32+ character secrets for `JWT_SECRET`, `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET`, `JWT_RESET_SECRET`, and `ACTIVATION_CODE_SECRET`.
- [x] Set explicit domain origins in `CORS_ORIGIN` (e.g. `https://acadex.edu,https://admin.acadex.edu`).
- [x] Configure valid ImageKit credentials (`IMAGEKIT_PUBLIC_KEY`, `IMAGEKIT_PRIVATE_KEY`, `IMAGEKIT_URL_ENDPOINT`).
- [x] Configure valid Firebase Admin SDK credentials (`FIREBASE_PROJECT_ID`, `FIREBASE_CLIENT_EMAIL`, `FIREBASE_PRIVATE_KEY`).
- [x] Ensure MongoDB Atlas IP whitelist allows backend production server IPs only.
- [x] Run `npm run build` and launch via `node dist/server.js`.
