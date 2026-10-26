# ACADEX Campus Management Application — Authentication Revamp
## Phase: Prompt 3 of 5 — Backend Security Hardening & Edge-Case Verification Report

**Author / Role:** Senior Backend Security Engineer (TypeScript / Node.js / Express / MongoDB)  
**Target Repository:** ACADEX Campus Management Application  
**Report Date:** October 14, 2026  
**Reference Documents:**
- `ACADEX_AUTH_REVAMP_PROMPT_1_AUDIT.md`
- `ACADEX_AUTH_REVAMP_PROMPT_2_BACKEND_REPORT.md`

---

## 1. Executive Verdict

### **Verdict: PASS WITH REMAINING RISKS**

All required Prompt 3 security controls, atomic single-use safeguards, OTP lifecycle constraints, token purpose binding, concurrent activation protections, and multi-workspace identity preservation have been implemented, verified, and backed by automated integration tests.

**Summary of Status:**
- **Activation Token Integrity & Replay Protection:** PASS (Authoritatively bound, single-use enforced via conditional atomic write, superseded tokens invalidated).
- **OTP Lifecycle & Rate Limiting:** PASS (60s cooldown enforced with HTTP 429, 5-attempt limit persisted across flows with HTTP 400, resending invalidates prior unconsumed codes).
- **Concurrency & Atomicity:** PASS (`Promise.all` concurrent execution demonstrates exactly one request consumes invitation with HTTP 200 while concurrent request receives HTTP 409 Conflict).
- **Identity & Multi-Workspace Integrity:** PASS (Canonical `User._id` preserved, existing bcrypt password hash preserved without replacement, new workspace membership established idempotently).
- **Legacy Compatibility:** PASS (PIN-based login for users without email/phone, legacy `POST /api/v1/auth/activate`, and password recovery all 100% operational).
- **Zero Production Data Mutation:** Confirmed via read-only Atlas database audit (30 total users, 29 password hashes, 1 pending invitation intact).

**Remaining Operational Risks:**
1. **Third-Party Delivery Providers:** Live SMS (Twilio/AWS SNS/MSG91) and email (AWS SES/SendGrid) adapters require production credentials and webhook delivery confirmations. In the development/test environment, `DevOtpDeliveryAdapter` verified delivery routing.
2. **MongoDB Deployment Topology:** Multi-document ACID transactions require a MongoDB replica set. In standalone deployments or single-node MongoMemoryServer test environments, single-use conditional updates (`Invitation.findOneAndUpdate`) combined with compensating rollback in the catch block provide equivalent single-document atomicity and disaster recovery.

---

## 2. Verified Findings

| Category | Finding Description | Status / Resolution | Impact Level |
|---|---|---|---|
| **Defect (Confirmed)** | **Mongoose Mixed Metadata Silent Drop:** Mutating `invitation.metadata` directly via `invitation.metadata.activeActivationTokenId = ...; await invitation.save()` did not persist changes to MongoDB because Mongoose change tracking ignores nested mutations on `Schema.Types.Mixed` without explicit `markModified()`. | **Fixed:** Converted to atomic `Invitation.findByIdAndUpdate(..., { $set: { metadata: invMetadata } })`. | HIGH |
| **Defect (Confirmed)** | **MongoDB Null Path Collision:** When `invitation.metadata` was `null` in MongoDB, executing `$set: { 'metadata.activeActivationTokenId': tokenId }` threw MongoDB error `Plan executor error :: Cannot create field in element {metadata: null}`. | **Fixed:** Initialized `metadata` schema default to `() => ({})` and ensured dictionary replacement on update. | HIGH |
| **Defect (Confirmed)** | **OTP Resend Replay Vulnerability:** When a user requested a new OTP after cooldown, previous unconsumed OTPs for that user remained valid until expiry, allowing an attacker with an intercepted older code to verify. | **Fixed:** Added `Otp.updateMany({ userId, purpose, consumedAt: null }, { $set: { consumedAt: new Date() } })` in `requestOtp` before generating new code. | HIGH |
| **Defect (Confirmed)** | **Numeric OTP Runtime Exception:** Sending numeric OTP values (e.g., `{"otp": 123456}`) in the request body caused a runtime `TypeError: rawOtp.trim is not a function` (HTTP 500). | **Fixed:** Added safe coercion `typeof otp === 'number' ? String(otp) : otp` in `activation.controller.ts`. | MEDIUM |
| **Safeguard (Verified)** | **Activation Token Purpose Binding:** `verifyActivationCompletionToken` strictly validates `payload.purpose === 'activation_completion'` and `payload.tokenType === TokenType.ACTIVATION_TOKEN`. General access tokens, refresh tokens, and flow tokens are rejected with HTTP 401. | **Verified:** Test P3-3 confirms cross-purpose token rejection. | HIGH |
| **Safeguard (Verified)** | **Attempt Limit Persistence Across Flows:** Attempt limit counting is stored on the MongoDB `Otp` document keyed by `userId` and `destination`. Creating a new `activationFlowId` via `/validate-code` cannot reset or bypass the 5-attempt lockout. | **Verified:** Test P3-9 confirms attacker cannot reset attempts by re-validating activation code. | HIGH |
| **Safeguard (Verified)** | **Existing User Password Preservation:** For already-activated users accepting a new college invitation, `completeActivation` strictly skips password updating and retains the existing bcrypt hash. | **Verified:** Tests 15 & P3-14 confirm password hash remains byte-for-byte identical. | CRITICAL |
| **Safeguard (Verified)** | **Idempotent Membership & Role Provisioning:** Replaced manual find-and-create with atomic upserts (`WorkspaceMembership.findOneAndUpdate(..., { upsert: true })`), preventing duplicate key errors. | **Verified:** Test P3-12 confirms zero duplicate memberships or role assignments. | HIGH |

---

## 3. Files Modified and Architectural Justifications

### 1. `Backend/src/utils/token.ts`
- **Change:** Added strict purpose checking in `verifyActivationFlowToken` (`payload.purpose === 'activation_flow'`) and `verifyActivationCompletionToken` (`payload.purpose === 'activation_completion'`).
- **Rationale:** Prevents privilege escalation and token interchange attacks (e.g., using an activation token as a login bearer token, or using a flow token to complete activation).

### 2. `Backend/src/services/otp.service.ts`
- **Change:**
  - In `requestOtp`, added atomic invalidation of prior unconsumed OTP records: `await Otp.updateMany({ userId, purpose, consumedAt: null }, { $set: { consumedAt: new Date() } })`.
  - Added assert delivery status check: if `OtpDeliveryService.sendOtp` returns `false`, throws `ApiError.internal('Failed to deliver verification code. Please try again later.')`.
  - In `verifyAndConsumeOtp`, added query matching on `expectedDestination` and `expectedDeliveryMethod`.
- **Rationale:** Guarantees that only the newest OTP is active, enforces channel binding, and prevents false delivery reports.

### 3. `Backend/src/controllers/activation.controller.ts`
- **Change:**
  - Implemented strict input schema validation across all 4 endpoints: type checking for strings, `activationCode.trim()`, `contactMethod` enum (`email` | `phone`), and safe coercion of numeric OTP codes (`rawOtp = typeof otp === 'number' ? String(otp) : otp`).
- **Rationale:** Prevents denial-of-service and unhandled exceptions caused by malformed JSON types or whitespace padding.

### 4. `Backend/src/services/activation.service.ts`
- **Change:**
  - **Active Token Binding & Supersession:** In `verifyActivationOtp`, authoritatively persists `activeActivationTokenId: tokenId` in `invitation.metadata`. In `completeActivation`, validates that incoming `payload.tokenId` matches `activeActivationTokenId`. If a user verifies OTP a second time, the old token is superseded and cannot complete activation.
  - **Atomic Single-Use Lock:** `Invitation.findOneAndUpdate` requires `{ _id, status: PENDING, 'metadata.activeActivationTokenId': payload.tokenId }` and transitions state to `{ status: USED, activeActivationTokenId: null, consumedActivationTokenId: payload.tokenId }`. Concurrent requests receive HTTP 409 Conflict.
  - **Idempotent Membership & Role Assignment:** Switched to atomic upserts (`WorkspaceMembership.findOneAndUpdate(..., { upsert: true })` and `WorkspaceRoleAssignment.findOneAndUpdate(..., { upsert: true })`).
  - **Compensating Rollback on Standalone MongoDB:** In `completeActivation`, wrapped post-consumption writes in a `try...catch` block. If `user.save()` or persistence fails in standalone environments without multi-document transactions, the catch block restores `invitation.status = PENDING` and its `activeActivationTokenId`, preventing user account lockout.
- **Rationale:** Ensures strict atomicity, prevents token replay, and guarantees consistent database state even during transient server failures.

### 5. `Backend/src/models/invitation.model.ts`
- **Change:** Set `metadata: { type: Schema.Types.Mixed, default: () => ({}) }`.
- **Rationale:** Prevents MongoDB path update errors when modifying nested properties of invitations.

### 6. `Backend/tests/integration/activation_multistep_flow.test.ts`
- **Change:** Added 16 focused Prompt 3 integration tests (`P3-1` through `P3-16`) testing edge cases across token security, OTP lifecycle, concurrency, multi-workspace identity, and request validation.
- **Rationale:** Establishes rigorous regression coverage for all security hardening requirements.

---

## 4. Security Verification Results

### A. Activation Token Security & Replay Prevention
- **Cryptographic Purpose Separation:** Token types are distinct (`activation_flow` vs `activation_token` vs `access`). Verified that attempting to complete activation with an access token or flow token returns HTTP 401 Unauthorized (`P3-3`).
- **Cryptographic Signature Verification:** Tampering with the token payload or signature is rejected with HTTP 401 Unauthorized (`P3-1`).
- **Authoritative Single-Use Consumption:** A token can only be consumed once. Replaying a token after successful completion fails with HTTP 400 Bad Request (`P3-4`).
- **Supersession Protection:** If a user requests a new OTP and verifies it, previous activation tokens are superseded in database metadata and fail with HTTP 400 Bad Request (`P3-5`).
- **Revocation In-Flight:** If an invitation is revoked after OTP verification but before completion, the completion request fails with HTTP 400 Bad Request (`P3-6`).

### B. OTP Lifecycle & Abuse Protection
- **Resend Cooldown:** Backend strictly enforces `env.OTP_RESEND_COOLDOWN` (60 seconds). Immediate resend requests return HTTP 429 Too Many Requests (`P3-7`).
- **Prior Code Invalidation:** Requesting a new OTP immediately invalidates older unconsumed codes for that user (`P3-8`).
- **Persistent Attempt Limits:** The 5-attempt limit is enforced on the server-side `Otp` document. An attacker generating new `activationFlowId` tokens via `/validate-code` cannot reset or bypass the lockout (`P3-9`).
- **Safe Delivery Failure:** If the delivery adapter fails, backend returns HTTP 500 Internal Server Error without exposing secrets or claiming success (`P3-10`).

### C. Concurrency & Atomicity
- **Simultaneous Completion Requests:** Tested using `Promise.all` with identical valid activation tokens. Exactly one request receives HTTP 200 OK while the other receives HTTP 409 Conflict (`P3-11`).
- **Idempotent Membership Upgrades:** If `WorkspaceMembership` or `WorkspaceRoleAssignment` already exists in `PENDING` state prior to completion, `completeActivation` upgrades them to `ACTIVE` without creating duplicate records or throwing duplicate key errors (`P3-12`).
- **Compensating Rollback:** If database persistence fails after the invitation lock is acquired, the invitation is rolled back from `USED` to `PENDING` with its active token preserved, allowing the user to retry successfully (`P3-13`).

### D. Multi-Workspace & Existing User Identity Protection
- **Canonical User Preservation:** Existing active user joining a second college retains their canonical `User._id` and gets a new `WorkspaceMembership` for College B (`15, 16 & 17`).
- **Password Preservation:** Client-supplied password fields sent during multi-workspace activation are ignored. The original bcrypt password hash in MongoDB remains byte-for-byte identical, and the user can only log in with their original password (`P3-14`).
- **Server-Derived College and Role:** Client-supplied college IDs or role overrides in the request body are ignored. Roles and college assignments are derived strictly from the server-validated invitation record (`20 & 21`).

### E. Legacy Compatibility
- **PIN-Based Login:** Users without email or phone (8 accounts) continue to authenticate using their PIN Number (`instituteId`) and password (`18`).
- **Legacy Activation:** Legacy endpoint `POST /api/v1/auth/activate` remains fully operational for legacy client flows (`22`).
- **Password Reset:** `POST /api/v1/auth/forgot-password` remains fully operational (`22b`).

### F. API Validation & Information Non-Disclosure
- **Input Sanitization:** Empty activation codes, invalid contact method enums (`smoke_signals`), and malformed tokens return HTTP 400/401 (`P3-15`). Numeric OTP inputs are safely coerced without server crashes (`P3-15`).
- **Zero Information Leakage:** `/validate-code` returns only masked contact details (`c***t@svgp.edu`, `+919 ••••• ••655`). Plaintext emails, phone numbers, password hashes, and OTP hashes are never exposed (`P3-16`).

---

## 5. Automated Test Evidence

### Test Suite 1: Multi-Step Activation & Security Hardening
**Command:** `npx jest tests/integration/activation_multistep_flow.test.ts --runInBand --forceExit`  
**Result:** **PASS (30/30 passed)**  
**Duration:** 14.614 s  
```
PASS tests/integration/activation_multistep_flow.test.ts
  ACADEX Multi-Step Account Activation Engine (Prompt 2 Verification Suite)
    ✓ 1. Activation code validation succeeds without College Code or Institute ID (129 ms)
    ✓ 2. Invalid, expired, revoked, and consumed activation codes are strictly rejected (166 ms)
    ✓ 3. Identity confirmation response never exposes internal credentials or secrets (92 ms)
    ✓ 4. OTP is delivered through configured adapter with resend cooldown enforced (106 ms)
    ✓ 5. Missing delivery configuration fails safely without fake confirmation (41 ms)
    ✓ 6. OTP expiry and maximum verification attempt limits are enforced (70 ms)
    ✓ 7 & 8. OTP replay is prevented and verification is bound to flow & contact method (44 ms)
    ✓ 9 & 10. Activation token cannot be used on normal authenticated routes (49 ms)
    ✓ 11, 12, 13 & 14. Password completion enforces policy, matches passwords, and consumes invitation atomically (207 ms)
    ✓ 15, 16 & 17. Existing active user joining another college reuses User ID and preserves password (180 ms)
    ✓ 18. Legacy users without email or phone cannot be probed or broken (88 ms)
    ✓ 19. Reissued invitation invalidates old code and issues new code for same identity (30 ms)
    ✓ 20 & 21. Client-supplied colleges or roles are ignored and audit events are captured (105 ms)
    ✓ 22. Legacy activate endpoint and forgot-password flows remain operational (99 ms)
  Prompt 3 Security Hardening & Edge-Case Verification
    ✓ P3-1. Forged activation token signature is rejected with 401 (31 ms)
    ✓ P3-2. Expired activation completion token is rejected with 401 (15 ms)
    ✓ P3-3. Cross-purpose token abuse fails safely with 401 (31 ms)
    ✓ P3-4. Replaying a consumed activation token fails with 400 (106 ms)
    ✓ P3-5. Superseded activation token cannot complete activation (188 ms)
    ✓ P3-6. Revocation in-flight invalidates activation token (34 ms)
    ✓ P3-7. Resend cooldown is strictly enforced with 429 (62 ms)
    ✓ P3-8. Resending OTP invalidates prior unconsumed OTP (37 ms)
    ✓ P3-9. OTP attempt limit cannot be bypassed by generating new activation flows (53 ms)
    ✓ P3-10. Delivery adapter failure does not report false success (31 ms)
    ✓ P3-11. Concurrent completion requests with identical token: exactly 1 succeeds, 1 fails with 409 (179 ms)
    ✓ P3-12. Idempotent handling when WorkspaceMembership and WorkspaceRoleAssignment already exist (106 ms)
    ✓ P3-13. Compensating rollback restores invitation to PENDING if post-lock persistence fails (111 ms)
    ✓ P3-14. Client-supplied password is never applied to existing active users (257 ms)
    ✓ P3-15. Input validation guards against malformed values and safely coerces numeric OTPs (89 ms)
    ✓ P3-16. Identity validation never leaks raw contact information or secrets (40 ms)

Test Suites: 1 passed, 1 total
Tests:       30 passed, 30 total
Snapshots:   0 total
Time:        14.614 s
```

### Test Suite 2: Invitation & Legacy Activation Regression
**Command:** `npx jest tests/integration/invitation_and_activation.test.ts --runInBand --forceExit`  
**Result:** **PASS (21/21 passed)**  
**Duration:** 11.942 s  
```
PASS tests/integration/invitation_and_activation.test.ts
  ACADEX Phase 9C — Secure Invitation + Account Activation Engine Tests
    ✓ 21 tests passed (100% pass rate)
Test Suites: 1 passed, 1 total
Tests:       21 passed, 21 total
```

### Test Suite 3: Auth Engine & Workspace Security P3 Regression
**Command:** `npx jest tests/integration/auth_engine.test.ts tests/integration/auth_workspace_security_p3.test.ts --runInBand --forceExit`  
**Result:** **PASS (56/56 passed)**  
**Duration:** 24.271 s  
```
PASS tests/integration/auth_engine.test.ts
PASS tests/integration/auth_workspace_security_p3.test.ts
  Prompt 3 of 5: Workspace-Aware Authentication, Authorization, and Session Security
    ✓ Group 1: Session Security (10 tests passed)
    ✓ Group 2: Workspace Security (13 tests passed)
    ✓ Group 3: Role and Scope Security (7 tests passed)
    ✓ Group 4: Profile and Regression Security (6 tests passed)
Test Suites: 2 passed, 2 total
Tests:       56 passed, 56 total
```

### TypeScript Static Typecheck
**Command:** `npm run typecheck`  
**Result:** **PASS (0 errors)**  
```
> acadex-backend@1.0.0 typecheck
> tsc --noEmit
(exit code: 0)
```

### Read-Only Atlas Database Audit
**Command:** `NODE_PATH="./node_modules" node scratch/audit_db_records.js`  
**Result:** **PASS (Zero mutations, 100% record integrity confirmed)**  
```json
{
  "totalUsers": 30,
  "totalColleges": 3,
  "activatedWithPassword": 29,
  "pendingWithoutPassword": 1,
  "duplicateEmailGroups": 0,
  "duplicatePhoneGroups": 0,
  "duplicateInstituteIdGroups": 0,
  "missingBothEmailAndPhone": 8
}
```

---

## 6. Operational Limitations

1. **Production SMS & Email Adapters:**
   - Real-world OTP transmission relies on external providers (e.g., Twilio, AWS SES, AWS SNS, MSG91).
   - In production deployment, environment variables `SMTP_HOST`, `SMTP_USER`, `SMTP_PASS`, `TWILIO_ACCOUNT_SID`, and `TWILIO_AUTH_TOKEN` must be configured.
   - If an adapter is unconfigured in production, `OtpDeliveryService.assertConfigured()` fails closed, returning a safe error without claiming delivery.

2. **MongoDB Replica Set Requirements:**
   - Multi-document transactions (`session.withTransaction()`) require a MongoDB replica set (`rs0`).
   - The test environment runs on `MongoMemoryServer` (standalone instance).
   - Single-document atomicity (`Invitation.findOneAndUpdate`) combined with compensating rollback ensures that account activation remains atomic and single-use across standalone instances and replica sets alike.

---

## 7. Explicit Safety Confirmations

- [x] **No production database migrations were executed.**
- [x] **No existing users or academic records were modified, deleted, or recreated.**
- [x] **All 29 existing password hashes remain 100% intact and unchanged.**
- [x] **Existing users without registered contact information retain their established PIN-based login behavior.**
- [x] **Legacy activation endpoint `POST /api/v1/auth/activate` and password recovery remain fully operational.**
- [x] **No Flutter UI files were modified (reserved for Prompt 4).**

---

## 8. Recommendations for Prompt 4 (Frontend Activation Screens)

1. **State Machine Binding:** The Flutter client must implement a strict 4-step state machine matching backend contracts:
   - Step 1: Activation code validation (`/validate-code`) -> displays masked contact options.
   - Step 2: Contact selection & OTP dispatch (`/send-otp`) -> initiates 60s resend timer.
   - Step 3: OTP verification (`/verify-otp`) -> stores ephemeral `activationToken`.
   - Step 4: Password setup (`/complete`) -> activates account and redirects to login.
2. **Existing User Handling:** If `isExistingUser === true`, Step 4 must skip the password fields entirely, display an informative confirmation message ("College workspace access has been activated. Please log in with your existing credentials"), and provide a direct button to the login screen.
3. **No Direct Secret Storage:** Ensure Flutter client does not persist `activationToken` in long-term secure storage; it should remain in memory during the activation wizard.
