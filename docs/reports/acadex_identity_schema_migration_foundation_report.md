# ACADEX Architectural Implementation Report: Safe Identity Schema Expansion, Membership PIN Numbers & Migration Foundation

**File Location:** `docs/reports/acadex_identity_schema_migration_foundation_report.md`  
**Phase:** Acadex Global Identity Architecture — Implementation Phase (Prompt 2 of 5)  
**Status:** COMPLETED & VERIFIED  
**Date:** October 27, 2026  
**Audience:** Technical Leadership, Database Administrators, Engineering Architects  

---

## 1. Executive Summary

Following the global identity architecture audit in [`acadex_global_identity_architecture_audit.md`](file:///Users/poornesh/Campus%20Management%20Main/docs/reports/acadex_global_identity_architecture_audit.md), this implementation delivers the data-integrity and schema foundation required for one global user account to hold multiple institutional identities and memberships across different colleges without breaking existing authentication, data access, or academic records.

### Key Milestones Achieved:
1. **Institutional Identity Expansion on `WorkspaceMembership`:**
   - Decoupled institutional PIN Numbers (`instituteId`) from the global `User` document and established them as institution-scoped fields on `WorkspaceMembership`.
   - Implemented compound unique indexing `{ collegeId: 1, instituteId: 1 }` with partial filtering on string types, allowing identical PIN formats across different colleges while strictly forbidding duplicates within a single college.
   - Enforced effective date validation (`effectiveStartDate <= effectiveEndDate`) and expanded lifecycle statuses (`TRANSFERRED`, `COMPLETED`).
2. **Elimination of the Destructive Rollback Bug:**
   - Refactored `StudentService.provisionStudent` and `FacultyService.provisionFaculty` to track account provenance (`isNewUser`).
   - If profile creation fails, pre-existing global accounts and memberships in other colleges are strictly preserved. Only newly provisioned records created by the failed operation are cleaned up.
3. **Academic Transfer-Credit Foundation:**
   - Created the `TransferCredit` model, validation schema, and tenant-isolated service (`TransferCreditService`).
   - Lateral entry and credit transfers explicitly capture recognized prior qualifications, evaluated subjects, and dean-level approval timestamps without fabricating fictitious marks or attendance.
4. **Read-Only Dry-Run Migration & Non-Zero Blocker Exit:**
   - Upgraded `WorkspaceMigrationService.runDryRun()` and `src/scripts/migrate-workspaces.ts` to detect duplicate PINs, missing college references, cross-tenant violations, orphaned memberships/roles, and date range mismatches without modifying a single database record.
   - Supported a strict validation mode (`--strict`) returning non-zero process exit codes when blockers are detected.
5. **Full Backward Compatibility:**
   - Preserved legacy scalar fields and global indexes (`User.instituteId`, `User.collegeId`, `User.role`) so current login and session token flows remain uninterrupted until Prompt 3.

---

## 2. Files Modified & Created

### Schema & Models:
- [`Backend/src/constants/status.ts`](file:///Users/poornesh/Campus%20Management%20Main/Backend/src/constants/status.ts):
  - Added `TRANSFERRED = 'transferred'` and `COMPLETED = 'completed'` to `MembershipStatus`.
  - Added `MembershipType` enum (`STUDENT`, `FACULTY`, `STAFF`, `ADMINISTRATOR`).
  - Added `TransferCreditStatus` enum (`PENDING`, `VERIFIED`, `APPROVED`, `REJECTED`).
- [`Backend/src/models/workspaceMembership.model.ts`](file:///Users/poornesh/Campus%20Management%20Main/Backend/src/models/workspaceMembership.model.ts):
  - Added fields: `instituteId`, `memberType`, `effectiveStartDate`, `effectiveEndDate`, `admissionNumber`, `employeeId`.
  - Added compound unique index: `{ collegeId: 1, instituteId: 1 }` with partial filter `{ instituteId: { $type: 'string' } }`.
  - Added date range pre-validate validation hook (`effectiveStartDate <= effectiveEndDate`).
- [`Backend/src/models/workspaceRoleAssignment.model.ts`](file:///Users/poornesh/Campus%20Management%20Main/Backend/src/models/workspaceRoleAssignment.model.ts):
  - Added `effectiveStartDate` and `effectiveEndDate` with date range validation guard.
- [`Backend/src/models/transferCredit.model.ts`](file:///Users/poornesh/Campus%20Management%20Main/Backend/src/models/transferCredit.model.ts):
  - New model for formal transfer credit and lateral entry recording.
- [`Backend/src/models/index.ts`](file:///Users/poornesh/Campus%20Management%20Main/Backend/src/models/index.ts):
  - Exported `TransferCredit` and `ITransferCredit`.

### Validation & Services:
- [`Backend/src/validations/transferCredit.validation.ts`](file:///Users/poornesh/Campus%20Management%20Main/Backend/src/validations/transferCredit.validation.ts):
  - Zod schemas for transfer credit creation and verification/approval status transitions.
- [`Backend/src/services/transferCredit.service.ts`](file:///Users/poornesh/Campus%20Management%20Main/Backend/src/services/transferCredit.service.ts):
  - Authoritative transfer credit service enforcing destination college authority, student tenancy validation, and audit logging.
- [`Backend/src/services/invitation.service.ts`](file:///Users/poornesh/Campus%20Management%20Main/Backend/src/services/invitation.service.ts):
  - Extended `CreateInvitationResult` to return `isNewUser: boolean`, `isNewMembership: boolean`, and `membershipId?: string`.
  - Populated institutional identity (`instituteId`, `memberType`, `effectiveStartDate`) upon creating workspace memberships.
- [`Backend/src/services/student.service.ts`](file:///Users/poornesh/Campus%20Management%20Main/Backend/src/services/student.service.ts):
  - Fixed destructive rollback bug: only deletes `User` if `invitationResult.isNewUser === true`.
- [`Backend/src/services/faculty.service.ts`](file:///Users/poornesh/Campus%20Management%20Main/Backend/src/services/faculty.service.ts):
  - Fixed destructive rollback bug: preserves existing global user accounts and memberships upon profile insertion failures.
- [`Backend/src/services/migration/workspaceMigration.service.ts`](file:///Users/poornesh/Campus%20Management%20Main/Backend/src/services/migration/workspaceMigration.service.ts):
  - Implemented comprehensive dry-run anomaly checks: duplicate PINs, conflicting PINs, orphaned memberships/roles, invalid date ranges, and unmappable profiles.
  - Upgraded idempotent migration execute and rollback routines.
- [`Backend/src/scripts/migrate-workspaces.ts`](file:///Users/poornesh/Campus%20Management%20Main/Backend/src/scripts/migrate-workspaces.ts):
  - Added `--strict` CLI flag to enforce exit code 1 on unresolved blockers.
  - Sanitized log output to prevent credential, token, or OTP leakage.
- [`Backend/src/services/internalAssessment.service.ts`](file:///Users/poornesh/Campus%20Management%20Main/Backend/src/services/internalAssessment.service.ts):
  - Resolved unused imports and enum type assertion to ensure 100% clean typecheck.

### Test Suites:
- [`Backend/tests/integration/safe_identity_schema_prompt2.test.ts`](file:///Users/poornesh/Campus%20Management%20Main/Backend/tests/integration/safe_identity_schema_prompt2.test.ts):
  - Created 10 integration tests validating all Prompt 2 requirements.

---

## 3. Detailed Schema & Index Changes

### 3.1 `WorkspaceMembership` Schema Expansion

```typescript
// Compound unique index: prevents duplicate PIN Numbers within the same college
WorkspaceMembershipSchema.index(
  { collegeId: 1, instituteId: 1 },
  {
    unique: true,
    partialFilterExpression: { instituteId: { $type: 'string' } },
  }
);

// Compound unique index: guarantees exactly one membership per user per college
WorkspaceMembershipSchema.index(
  { collegeId: 1, userId: 1 },
  { unique: true }
);

// Query optimization indexes
WorkspaceMembershipSchema.index({ userId: 1, isDefault: 1, status: 1 });
WorkspaceMembershipSchema.index({ collegeId: 1, memberType: 1, status: 1 });
WorkspaceMembershipSchema.index({ collegeId: 1, status: 1 });
```

#### Invariant Guarantees:
- **Tenant Scope:** A PIN Number (`instituteId`) like `CSE-2026-001` can exist in College A and simultaneously in College B without collision.
- **Single College Uniqueness:** Two different users cannot be assigned the same `instituteId` within College A.
- **Date Range Sanity:**
  ```typescript
  WorkspaceMembershipSchema.pre('validate', function (next) {
    if (this.effectiveStartDate && this.effectiveEndDate) {
      if (new Date(this.effectiveEndDate).getTime() < new Date(this.effectiveStartDate).getTime()) {
        return next(new Error('effectiveEndDate cannot be earlier than effectiveStartDate'));
      }
    }
    next();
  });
  ```

---

## 4. How Safe Rollback Works

### The Previous Vulnerability
In the legacy codebase, `StudentService.provisionStudent` and `FacultyService.provisionFaculty` caught profile creation errors (e.g. duplicate roll numbers or disk errors) and executed:
```typescript
// DANGEROUS LEGACY CODE:
await Promise.all([
  User.findByIdAndDelete(user._id),
  Invitation.findByIdAndDelete(invitation.id)
]);
```
If an existing student or faculty member from College A was being invited into College B and profile creation failed, this wiped out their entire global `User` document, permanently deleting their College A login and orphaning College A academic records.

### The Compensating Rollback Implementation
`InvitationService.createInvitation` now returns:
```typescript
export interface CreateInvitationResult {
  invitation: IInvitation;
  user: IUser;
  activationCode: string;
  isNewUser: boolean;       // TRUE only if User.create() was invoked in this call
  isNewMembership: boolean;  // TRUE only if a new WorkspaceMembership was inserted
  membershipId?: string;     // The newly inserted membership ID
}
```

In `StudentService` and `FacultyService`:
```typescript
} catch (err: any) {
  const rollbackPromises: Promise<any>[] = [];

  // 1. Only delete User if it was created exclusively during this failed attempt
  if (invitationResult.isNewUser) {
    rollbackPromises.push(User.findByIdAndDelete(user._id).catch(() => {}));
  }

  // 2. Clean up invitation created for this specific college attempt
  if (invitationResult.invitation?.id) {
    rollbackPromises.push(Invitation.findByIdAndDelete(invitationResult.invitation.id).catch(() => {}));
  }

  // 3. Roll back only the membership created for this college
  if (invitationResult.isNewMembership && invitationResult.membershipId) {
    rollbackPromises.push(WorkspaceMembership.findByIdAndDelete(invitationResult.membershipId).catch(() => {}));
    rollbackPromises.push(WorkspaceRoleAssignment.deleteMany({ membershipId: invitationResult.membershipId }).catch(() => {}));
  }

  await Promise.all(rollbackPromises);

  logger.warn(`Safe compensating rollback completed for provisioning failure: ${err?.message}`, {
    userId: user._id?.toString(),
    collegeId: dept.collegeId?.toString(),
    isNewUser: invitationResult.isNewUser,
  });

  throw err;
}
```

**Verification:** Regressions tests (Scenarios 5 and 6) proved that when provisioning into College B fails for a user with pre-existing College A records:
1. Global `User` remains in MongoDB.
2. College A `WorkspaceMembership` and `Student`/`Faculty` profiles remain active and intact.
3. College B partial records are cleaned up cleanly.

---

## 5. TransferCredit Design

`TransferCredit` models legitimate advanced standing (such as polytechnic diploma lateral entry into semester 3) or inter-institutional credit transfers without synthesizing fake attendance or fabricated examination marks.

### Data Model Structure
- `studentId`: Reference to `Student` profile within the destination tenant.
- `studentEnrollmentId`: Reference to active `StudentEnrollment` in the destination tenant.
- `collegeId`: Destination College ID (tenant boundary).
- `originCollegeId`: Optional reference to source College (if an ACADEX campus).
- `originInstitutionName`: String name of external college or diploma board.
- `admissionType`: `LATERAL_ENTRY` | `INTER_COLLEGE_TRANSFER` | `CREDIT_EXCHANGE` | `REGULAR_ADMISSION_CREDIT`.
- `recognizedCredits`: Total number of verified credits accepted.
- `transferredSubjects`: Array of individual accepted subjects with source code, source name, destination equivalent code, and credits.
- `verificationStatus`: `PENDING` -> `VERIFIED` -> `APPROVED` / `REJECTED`.
- `approvedBy`: Reference to authorizing administrator.
- `auditHistory`: Embedded audit trail tracking actor name, role, timestamp, and status diffs.

### Tenant Protection & Validation
`TransferCreditService.recordTransferCredit` ensures:
1. Only `COLLEGE_ADMIN` of the destination college (or `SUPER_ADMIN`) can record transfer credits.
2. The referenced `Student` and `StudentEnrollment` must belong to the destination college.
3. Client-supplied arbitrary college IDs cannot cross tenant boundaries.

---

## 6. Workspace Migration Dry-Run Behavior & Sample Summary

The dry-run mode in `WorkspaceMigrationService.runDryRun()` performs an extensive read-only scan across all collections without executing any database mutations.

### What Dry-Run Inspects:
1. **Missing College References:** Flags non-superadmin users lacking `collegeId` or pointing to nonexistent colleges.
2. **Missing PIN Numbers:** Flags users lacking institutional `instituteId`.
3. **Conflicting PIN Numbers:** Flags discrepancies between `User.instituteId` and `WorkspaceMembership.instituteId`.
4. **Duplicate PIN Numbers:** Aggregates PINs per college to detect compound key collisions before index creation.
5. **Orphaned Memberships & Roles:** Checks for memberships or role assignments pointing to deleted users or colleges.
6. **Cross-Tenant Violations:** Detects profiles or HOD departments mapped to colleges that conflict with the user's primary association.
7. **Date Range Errors:** Detects records where start date is after end date.

### Live Dry-Run Output Sample
Executing `npx ts-node src/scripts/migrate-workspaces.ts` against the live dev database produced:

```text
=================================================================
ACADEX WORKSPACE MEMBERSHIP MIGRATION RUNNER
=================================================================
[INFO] Connecting to MongoDB database "acadex"...
[INFO] MongoDB connected to database "acadex"
[MODE] DRY RUN (No writes will be performed)
Scanning users, colleges, departments, and indexes...

-----------------------------------------------------------------
Dry Run Identifier: dryrun_1793114730755
Total Users Scanned: 86
Eligible For Migration: 29
Already Migrated: 55
Super Admin Platform Users: 2
Unresolved Anomalies: 0
Profile Index Conflicts: 0
Safe to Migrate: YES
-----------------------------------------------------------------

Status Breakdown: { active: 85, pending_activation: 1 }
Role Breakdown: { SUPER_ADMIN: 2, COLLEGE_ADMIN: 4, HOD: 11, FACULTY: 23, STUDENT: 46 }

Index Preflight Status:
- Faculty compound index: Present
- Student compound index: Present
- Membership PIN compound index: Present
- Preflight Index Blockers: 0
  * Legacy unique index on Faculty.userId exists. In production, drop after compound {collegeId: 1, userId: 1} is validated.
  * Legacy unique index on Student.userId exists. In production, drop after compound {collegeId: 1, userId: 1} is validated.

To execute migration, re-run with:
  npx ts-node src/scripts/migrate-workspaces.ts --execute

[INFO] Closing MongoDB connection...
[INFO] MongoDB disconnected
```

---

## 7. Backward Compatibility Strategy

During this staged transition (Prompt 2):
1. **Scalar Fields Maintained:** `User.instituteId`, `User.collegeId`, `User.role`, and `User.departmentId` remain intact on the `User` schema and are synchronized whenever invitations are issued.
2. **Global Index Retention:** The legacy unique index on `User.instituteId` has **not** been dropped yet. Existing single-institution login flows and JWT payload structures continue to work without modification.
3. **Safe Transition Path:**
   - Prompt 2: Establishes membership-level PINs and verifies data consistency via dry run.
   - Prompt 3: Will update login, token issuance, and workspace selection to consume `WorkspaceMembership`.
   - Prompt 4/5: Once all logins run via memberships, the legacy global unique index on `User.instituteId` can be dropped in favor of `{ collegeId: 1, instituteId: 1 }`.

---

## 8. Verification Commands & Results

All tests and validation commands were executed directly in the repository:

### 1. New Prompt 2 Integration Test Suite
```bash
npx jest --runInBand --forceExit tests/integration/safe_identity_schema_prompt2.test.ts
```
**Result:** **10 passed, 10 total (100% PASS)**
- `✓ 1. One global user can have active memberships in two different colleges`
- `✓ 2. Same user retains distinct institutional PIN Numbers across different colleges`
- `✓ 3. Identical PIN Numbers are permitted across different colleges without conflict`
- `✓ 4. Duplicate PIN Numbers are rejected within the same college by compound unique index`
- `✓ 5. Failed student provisioning preserves pre-existing global user and College A records`
- `✓ 6. Failed faculty provisioning preserves pre-existing global user and College A records`
- `✓ 7. TransferCredit enforces tenant isolation and valid student association without fabricating marks`
- `✓ 8. Dry-run migration is strictly read-only and performs zero database writes`
- `✓ 9. Dry-run reliably flags duplicate PINs, missing colleges, and unmappable identities with safeToMigrate=false`
- `✓ 10. Backward compatibility: User scalar fields and Invitation provisioning populate both User and WorkspaceMembership`

### 2. Existing Workspace Architecture Suite
```bash
npx jest --runInBand --forceExit tests/integration/workspace_membership_architecture.test.ts
```
**Result:** **24 passed, 24 total (100% PASS)**

### 3. Authentication & Invitation Regression Suite
```bash
npx jest --runInBand --forceExit tests/integration/auth_engine.test.ts tests/integration/invitation_and_activation.test.ts
```
**Result:** **41 passed, 41 total (100% PASS)**

### 4. Full TypeScript Typecheck
```bash
npm run typecheck
```
**Result:** **Exit code 0 (0 errors)**

### 5. Migration CLI Dry Run
```bash
npx ts-node src/scripts/migrate-workspaces.ts
```
**Result:** **Exit code 0, 86 users scanned, Safe to Migrate: YES, 0 writes performed**

---

## 9. Limitations & Boundary Scope for Subsequent Prompts

As specified in the Prompt 2 boundaries, the following items are intentionally deferred:
- **Login & JWT Token Refactoring:** Login endpoints still issue tokens with scalar `collegeId` and `role`. Decoupling auth tokens to support multi-membership switching is scheduled for **Prompt 3**.
- **Workspace-Switching UI & API:** The interactive switching endpoints belong to Prompt 3.
- **Full Historical Attendance & Marks Handover:** Transfer workflows for historical records belong to Prompt 4.
- **HOD Tenure Lifecycle Tracking:** Scheduled for Prompt 4.

The identity schema expansion, membership PIN number modeling, safe compensating rollback, transfer-credit foundation, and dry-run migration capabilities are fully operational, tested, and ready for production staging.
