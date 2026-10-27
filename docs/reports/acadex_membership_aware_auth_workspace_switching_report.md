# ACADEX Architecture & Engineering Report: Prompt 3
## Membership-Aware Login, JWT Claims, PIN Number Scoping & Workspace Switching

**Date:** 2026-10-27  
**Author:** Staff Authentication & Multi-Tenant Systems Architect  
**Status:** Implementation Complete & Fully Verified  
**Workstream:** Global Identity & Institutional Multi-Tenancy (Prompt 3 of 5)  

---

## 1. Executive Summary

This report documents the architectural design and full implementation of **Prompt 3: Membership-Aware Login, JWT Claims & Workspace Switching** in the ACADEX platform.

Prompt 1 established the global identity boundary audit, and Prompt 2 established the data schema expansions (including membership-scoped institutional PIN numbers via `WorkspaceMembership.instituteId`, non-destructive multi-tenant rollback mechanics, and read-only dry-run migrations). Prompt 3 achieves the critical runtime milestone: **authentication, JWT token claims, request-context lifecycle, and workspace switching now resolve from authoritative institutional memberships and role assignments rather than universally treating one global user's role, college, and PIN number as single-tenant constants.**

### Key Achievements
1. **Multi-Institutional Identity & Role Decoupling:** One global `User` account can securely hold active memberships across multiple colleges (e.g., College A and College B). The user authenticates once with verified credentials, selects their target workspace (or seamlessly enters when only one eligible workspace exists), and receives an authoritative token bound strictly to that institution.
2. **Institutional PIN Number Scoping:** Tokens, profile endpoints (`/auth/me`), workspace switching, and session refreshments now mint and return `membership.instituteId || user.instituteId`, preventing College A PINs from leaking into College B contexts.
3. **Institutional Role & Scope Enforcement:** A user holding HOD privileges in College A and Faculty status in College B receives strictly the role assignment authorized for their active workspace. Switching into College B strips HOD privileges and confines permissions to College B's faculty tier.
4. **Lifecycle & Date-Range Validity Guards:** Both `WorkspaceMembership` and `WorkspaceRoleAssignment` effective dates (`effectiveStartDate <= now <= effectiveEndDate`) are strictly enforced during login, workspace switching, token validation in `auth.middleware.ts`, and token refresh in `auth.service.ts`.
5. **Zero Tenant Leakage on Switching:** Switching workspaces transitions session tokens atomically, rejects cross-user membership hijacking attempts, audits the switch with actor details, and ensures subsequent protected queries (such as `/academics/students` and `/departments`) only see the active college's records.
6. **Populated Object Serialization Bug Resolution:** Resolved a subtle Mongoose transform flaw where populated `collegeId` and `userId` documents were being serialized into `"[object Object]"` strings during `.toObject()` and `.toJSON()`, protecting compound key operations and downstream API consumers.
7. **Comprehensive Test Verification:** All 16 explicit Prompt 3 regression scenarios, all 36 Prompt 3 security integration tests, and all 10 Prompt 2 schema tests pass with 100% success (62 total integration tests passing).

---

## 2. Identity Boundaries Architecture

ACADEX enforces three cleanly decoupled identity boundaries:

```
+-------------------------------------------------------------------------+
|                              GLOBAL USER                                |
|  - Human Account (User._id)                                             |
|  - Verified Authentication Credentials (passwordHash, salt)            |
|  - Global Contact Info (email, phone, name)                             |
|  - Universal Account Status (active, pending_activation, deactivated)   |
|  - Fallback / Legacy Fields (instituteId, collegeId, role)              |
+-------------------------------------------------------------------------+
                                    |
          +-------------------------+-------------------------+
          | 1:N Memberships                                   | 1:N Memberships
          v                                                   v
+------------------------------------+   +------------------------------------+
|     INSTITUTIONAL MEMBERSHIP       |   |     INSTITUTIONAL MEMBERSHIP       |
|            (College A)             |   |            (College B)             |
| - Membership._id                   |   | - Membership._id                   |
| - collegeId: College A             |   | - collegeId: College B             |
| - instituteId: "ALPHA-HOD-01"      |   | - instituteId: "BETA-FAC-99"       |
| - status: ACTIVE                   |   | - status: ACTIVE                   |
| - effectiveStartDate / EndDate     |   | - effectiveStartDate / EndDate     |
+------------------------------------+   +------------------------------------+
          |                                                   |
          | 1:N Roles                                         | 1:N Roles
          v                                                   v
+------------------------------------+   +------------------------------------+
|      ROLE ASSIGNMENT (A)           |   |      ROLE ASSIGNMENT (B)           |
| - role: HOD                        |   | - role: FACULTY                    |
| - departmentId: Computer Science   |   | - departmentId: Electrical Eng     |
| - scope: DEPARTMENT                |   | - scope: DEPARTMENT                |
| - status: ACTIVE                   |   | - status: ACTIVE                   |
+------------------------------------+   +------------------------------------+
```

### 1. Global User (`User`)
- Represents the authenticated human identity.
- Owns password hashes, phone numbers, email addresses, and platform-level account status.
- Exempt from institutional college requirements when holding platform-level `SUPER_ADMIN`.
- Retains legacy scalar fields (`instituteId`, `collegeId`, `role`) for unmigrated single-college accounts.

### 2. Institutional Membership (`WorkspaceMembership`)
- Represents the user's formal affiliation with an institution (`collegeId`).
- Authoritative owner of the institution-specific institutional PIN Number (`instituteId`).
- Governed by an explicit lifecycle state (`ACTIVE`, `PENDING`, `SUSPENDED`, `REVOKED`, `TRANSFERRED`).
- Contains temporal validity windows (`effectiveStartDate`, `effectiveEndDate`).

### 3. Institutional Role Assignment (`WorkspaceRoleAssignment`)
- Represents the specific duties and scopes granted within an institutional membership.
- Decouples role (`COLLEGE_ADMIN`, `HOD`, `FACULTY`, `STUDENT`) from the global user.
- Scoped to specific departments (`departmentId`) with its own temporal validity and status (`ACTIVE`, `REVOKED`).

---

## 3. Request-Context & JWT Claims Design

### Authenticated Token Claims (`JwtPayload`)
JWT claims carry authoritative workspace identifiers without exposing unverified client claims:

```typescript
export interface JwtPayload {
  userId: string;
  instituteId: string;              // Resolved institutional PIN Number
  email?: string;
  phone?: string;
  name?: string;
  role: string;                     // Institutional active role
  collegeId?: string;               // Active college identifier
  departmentId?: string;            // Active authorized department
  sessionId: string;                // Active cryptographic session ID
  workspaceMembershipId?: string | null; // Authoritative membership ID
  membershipId?: string | null;     // Backward-compatible alias
}
```

### Request Context (`req.user`, `req.tenant`, `req.workspace`)
In `auth.middleware.ts`, token verification maps directly into unified Express request contexts:

```typescript
req.user = {
  id: dbUser.id,
  instituteId: activeInstituteId, // membership.instituteId || dbUser.instituteId
  role: activeRole,               // primaryRole from active WorkspaceRoleAssignment
  collegeId: targetCollege.id,
  departmentId: activeDepartmentId,
  workspaceMembershipId: membership.id,
  workspaceMembershipStatus: membership.status,
  activeRoles,                    // All active roles in this workspace
  authorizedDepartmentIds,        // All authorized departments
  isAuthoritativeWorkspace: true,
};

req.tenant = {
  collegeId: targetCollege.id,
  isSuperAdmin: false,
  userRole: activeRole,
  userId: dbUser.id,
  workspaceMembershipId: membership.id,
  membershipStatus: membership.status,
  departmentId: activeDepartmentId,
};

req.workspace = {
  collegeId: targetCollege.id,
  membershipId: membership.id,
  membershipStatus: membership.status,
  roles: activeRoles,
  roleAssignments: roleAssignments.map((a) => ({
    role: a.role,
    departmentId: a.departmentId?.toString() || null,
    scope: a.scope,
  })),
  departmentId: activeDepartmentId,
  authorizedDepartmentIds,
  isAuthoritative: true,
  isSuperAdmin: false,
};
```

---

## 4. Login & Workspace Switching Workflow

### Membership-Aware Login (`POST /api/v1/auth/login`)
1. **Identifier Resolution:** Normalizes identifier (email, phone, or PIN). Checks `User` table; if not found, checks `WorkspaceMembership.findOne({ instituteId })` to identify the global account without disclosing user existence.
2. **Account Validation:** Verifies global account is `ACTIVE` and password hash is valid.
3. **Super Admin Bypass:** If `role === AppRole.SUPER_ADMIN`, issues platform tokens with unrestricted oversight and `activeWorkspace: null`.
4. **Eligible Membership Discovery:** Queries `WorkspaceMembershipService.getEligibleMembershipsForUser(user.id)`:
   - Filters only `MembershipStatus.ACTIVE`.
   - Filters memberships where `effectiveStartDate <= now <= effectiveEndDate`.
   - Verifies target `College` is active and not suspended.
   - Verifies membership has at least one active, date-valid `WorkspaceRoleAssignment`.
   - Resolves `primaryRole` via role hierarchy.
5. **Workspace Resolution:**
   - If client passed `preferredWorkspaceId`, matches against eligible memberships.
   - If no preference: picks `isDefault: true`, or first eligible workspace.
   - Sets `requiresWorkspaceSelection: true` when multiple eligible memberships exist without an explicit preference or default.
6. **Token Minting:** Issues Access and Refresh tokens carrying `workspaceMembershipId` and `activeInstituteId`.
7. **Response Payload:** Returns `activeWorkspace`, `availableWorkspaces` list, and `requiresWorkspaceSelection` flag.

### Workspace Switching (`POST /api/v1/workspaces/switch`)
1. **Authentication:** Authenticates requester session.
2. **Membership Validation:**
   - Accepts either `targetCollegeId` or `targetMembershipId`.
   - Verifies membership belongs to the authenticated `dbUser.id` (rejects cross-user switches with 403 Forbidden).
   - Verifies `membership.status === MembershipStatus.ACTIVE` (rejects revoked, suspended, or inactive memberships).
   - Verifies membership effective date range (`effectiveStartDate <= now <= effectiveEndDate`).
   - Verifies active role assignments exist and are currently effective.
3. **Atomic Context Switch:**
   - Resolves `activeInstituteId = membership.instituteId || dbUser.instituteId`.
   - Mints a fresh Access Token carrying the new workspace's college ID, membership ID, and role.
   - Logs authoritative audit entry `SWITCH_WORKSPACE` recording actor, previous context, and new context.
4. **Client Response:** Returns new `accessToken`, `activeWorkspace` details, and updated `user` object.

---

## 5. Legacy Compatibility Strategy

The platform provides a backward-compatibility layer:
- **Legacy Single-Workspace Accounts:** If a user has no records in `WorkspaceMembership` yet, the system checks `WorkspaceCompatibilityService.isLegacyFallbackEnabled() && user.collegeId`.
- **Pre-Prompt 3 JWTs:** Tokens minted before `workspaceMembershipId` was introduced continue working through the synthetic payload fallback and database resolution path.
- **PIN Number Fallback:** If `WorkspaceMembership.instituteId` is null, the platform falls back safely to `User.instituteId`.
- **Documented Compatibility Phase:** Scalar fields on `User` (`instituteId`, `collegeId`, `role`, `departmentId`) remain populated during provisioning and updates until Prompt 5 final cutover.

---

## 6. Mongoose Serialization Fix

### Bug Identification
In `WorkspaceMembership.model.ts` and `WorkspaceRoleAssignment.model.ts`, Mongoose `toJSON` and `toObject` transforms had:
```typescript
ret.collegeId = ret.collegeId?.toString();
```
When `collegeId` was populated with a College document object (`{ _id: ObjectId("..."), name: "..." }`), calling `.toString()` on the plain JavaScript object produced `"[object Object]"`. Consequently, tokens minted with populated memberships received `collegeId: "[object Object]"`, causing downstream ObjectId validations in Express routes and middleware to fail with `Invalid workspace identifier format`.

### Architectural Fix
Transforms were updated in both models to inspect `_id` before stringifying:
```typescript
ret.collegeId = ret.collegeId?._id ? ret.collegeId._id.toString() : ret.collegeId?.toString();
ret.userId = ret.userId?._id ? ret.userId._id.toString() : ret.userId?.toString();
```
This guarantees that regardless of whether a relationship field is an unpopulated `ObjectId` or a populated document, clean 24-character hexadecimal IDs are returned.

---

## 7. Frontend Flutter Workspace Selector Integration

1. **`WorkspaceMembershipModel` Update:**
   - Added `final String? instituteId;` to `WorkspaceMembershipModel`.
   - Updated constructor, `fromJson`, `toJson`, and `copyWith`.
2. **`WorkspaceSelectorDialog` Update:**
   - Modified `_WorkspaceItemTile` to render an institutional PIN badge (`PIN: <instituteId>`) alongside the role badge for each workspace card.
   - Preserves active workspace indicator, clean dark/light mode theming, and multi-tenant isolation status.
3. **Flutter Static Analysis:**
   - Ran `flutter analyze lib/features/auth/`: **0 issues found**.

---

## 8. Index Migration Decisions & Safety Guarantees

Prompt 2 created the compound unique index on `{ collegeId: 1, instituteId: 1 }` for `WorkspaceMembership`, while deliberately preserving the legacy unique index on `User.instituteId`.

### Decision for Prompt 3
- The global unique index on `User.instituteId` **remains intact** for Prompt 3.
- All institutional PIN lookups are evaluated against `WorkspaceMembership.instituteId` while preserving `User.instituteId` fallback.
- **Rollback Guarantee:** No destructive schema migrations were run against production database collections.
- `WorkspaceMigrationService.runDryRun()` remains strictly read-only and passed verification.

---

## 9. Test Results & Verification

All automated test suites were executed sequentially against the codebase:

### Test Execution Commands & Results
```bash
# 1. Prompt 3 Integration Regression Suite (16 Scenarios)
npx jest --runInBand --forceExit tests/integration/membership_aware_auth_prompt3.test.ts
Result: PASS (16 passed, 16 total, 13.252 s)

# 2. Existing Prompt 3 Security & Session Suite (36 Scenarios)
npx jest --runInBand --forceExit tests/integration/auth_workspace_security_p3.test.ts
Result: PASS (36 passed, 36 total, 13.393 s)

# 3. Prompt 2 Schema & Migration Suite (10 Scenarios)
npx jest --runInBand --forceExit tests/integration/safe_identity_schema_prompt2.test.ts
Result: PASS (10 passed, 10 total, 10.406 s)

# 4. Backend TypeScript Typecheck
npm run typecheck (tsc --noEmit)
Result: SUCCESS (0 errors)

# 5. Frontend Flutter Static Analysis
flutter analyze lib/features/auth/
Result: SUCCESS (No issues found)
```

### Prompt 3 Test Scenarios Matrix
| # | Scenario Description | Status |
|---|----------------------|--------|
| 1 | Legacy single-workspace user can log in | **PASS** |
| 2 | User with two valid memberships can select either workspace | **PASS** |
| 3 | Each workspace uses its own institutional PIN Number | **PASS** |
| 4 | HOD in College A and Faculty in College B receives correct role | **PASS** |
| 5 | User cannot switch to another person's membership | **PASS** |
| 6 | Inactive or expired memberships cannot be selected | **PASS** |
| 7 | College A token cannot access College B data | **PASS** |
| 8 | Workspace switching replaces client workspace context | **PASS** |
| 9 | Workspace-scoped data does not leak across switches | **PASS** |
| 10 | Global Super Admin and institutional roles remain separated | **PASS** |
| 11 | Legacy token handling follows compatibility policy | **PASS** |
| 12 | Membership changes invalidate stale authorisation | **PASS** |
| 13 | Refresh token preserves membership context and validates status | **PASS** |
| 14 | Cross-tenant mutation is strictly prohibited | **PASS** |
| 15 | Migration dry-run validation remains read-only | **PASS** |
| 16 | Existing department and course routes continue functioning | **PASS** |

---

## 10. Files Changed

### Backend Files
- `Backend/src/types/auth.types.ts`: Added `workspaceMembershipId` and `membershipId` to `JwtPayload`.
- `Backend/src/services/workspaceMembership.service.ts`: Added `getEligibleMembershipsForUser` with date validity, college status checks, role assignment resolution, and `instituteId` propagation.
- `Backend/src/controllers/workspace.controller.ts`: Refactored `switchWorkspace` to support `targetMembershipId` and `targetCollegeId`, enforce date validity, return scoped institutional PIN numbers, and include `role` in `activeWorkspace`.
- `Backend/src/middleware/auth.middleware.ts`: Implemented authoritative membership lookup with `workspaceMembershipId`, enforced membership and role date validity, scoped `req.user.instituteId` to the active membership.
- `Backend/src/controllers/auth.controller.ts`: Extracted workspace preferences in login and updated `getMe` to return `req.user.instituteId`.
- `Backend/src/services/auth.service.ts`: Integrated multi-workspace resolution into `login`, `refreshToken`, and `devLogin`. Added institutional PIN lookup fallback.
- `Backend/src/models/workspaceMembership.model.ts`: Fixed populated `collegeId` and `userId` serialization in `toJSON` and `toObject`.
- `Backend/src/models/workspaceRoleAssignment.model.ts`: Fixed populated field serialization in `toJSON` and `toObject`.
- `Backend/tests/integration/membership_aware_auth_prompt3.test.ts`: Created new comprehensive 16-scenario test suite.

### Frontend Files
- `Frontend/lib/features/auth/domain/models/workspace_model.dart`: Added `instituteId` field to `WorkspaceMembershipModel`.
- `Frontend/lib/features/auth/presentation/widgets/workspace_selector_dialog.dart`: Displayed institutional PIN badge on workspace cards.

---

## 11. Remaining Dependencies for Prompt 4

Prompt 3 has established the multi-tenant membership-aware authentication and workspace-switching foundation. The following dependencies are queued for **Prompt 4: Historical Academic Continuity, Subject Handover & Tenure Tracking**:
1. **Academic History & Attendance Continuity:** Ensuring that when a faculty member or student transitions from College A to College B, historical attendance, assessment marks, and logs in College A remain immutably archived and accessible only to College A administrators.
2. **Tenure & Subject Handover:** Implementing structured subject reassignment workflows when an HOD or Faculty membership expires or is transferred to a new institution.
3. **Historical Marks Transcript Consolidation:** Utilizing the `TransferCredit` model foundations laid in Prompt 2 for official inter-institutional credit recognition.
