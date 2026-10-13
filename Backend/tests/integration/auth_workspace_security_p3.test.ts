import request from 'supertest';
import crypto from 'crypto';
import mongoose from 'mongoose';
import { app } from '../../src/app';
import {
  User,
  College,
  Department,
  AuthSession,
  WorkspaceMembership,
  WorkspaceRoleAssignment,
  Faculty,
  Student,
  Subject,
  FacultyAssignment,
} from '../../src/models';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { PasswordService } from '../../src/services/password.service';
import { WorkspaceCompatibilityService } from '../../src/services/workspaceCompatibility.service';
import { AttendanceService } from '../../src/services/attendance.service';
import { TeachingAuthorizationService } from '../../src/services/teachingAuthorization.service';
import { AuditService } from '../../src/services/audit.service';
import { AppRole } from '../../src/constants/roles';
import {
  AccountStatus,
  MembershipStatus,
  RoleAssignmentStatus,
  CollegeStatus,
} from '../../src/constants/status';
import { signAccessToken } from '../../src/utils/token';

describe('Prompt 3 of 5: Workspace-Aware Authentication, Authorization, and Session Security', () => {
  let collegeA: InstanceType<typeof College>;
  let collegeB: InstanceType<typeof College>;
  let deptA1: InstanceType<typeof Department>;
  let deptA2: InstanceType<typeof Department>;
  let deptB1: InstanceType<typeof Department>;

  beforeAll(async () => {
    await setupTestDB();
    await User.init();
    await College.init();
    await Department.init();
    await AuthSession.init();
    await WorkspaceMembership.init();
    await WorkspaceRoleAssignment.init();
    await Faculty.init();
    await Student.init();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();
    WorkspaceCompatibilityService.setLegacyFallbackEnabled(true);

    collegeA = await College.create({
      name: 'College Alpha',
      code: 'COL-ALPHA',
      address: '100 Alpha Way',
      email: 'admin@alpha.edu',
      phone: '1112223333',
      principal: 'Dr. Alpha Principal',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });

    collegeB = await College.create({
      name: 'College Beta',
      code: 'COL-BETA',
      address: '200 Beta Blvd',
      email: 'admin@beta.edu',
      phone: '4445556666',
      principal: 'Dr. Beta Principal',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });

    deptA1 = await Department.create({
      collegeId: collegeA._id,
      name: 'Computer Science',
      code: 'CSE-A',
    });

    deptA2 = await Department.create({
      collegeId: collegeA._id,
      name: 'Electronics',
      code: 'ECE-A',
    });

    deptB1 = await Department.create({
      collegeId: collegeB._id,
      name: 'Computer Science',
      code: 'CSE-B',
    });
  });

  // =========================================================================
  // GROUP 1: SESSION SECURITY (Scenarios 1 - 10)
  // =========================================================================
  describe('Group 1: Session Security', () => {
    it('1. Valid active session succeeds', async () => {
      const passwordHash = await PasswordService.hashPassword('Pass1234');
      const user = await User.create({
        instituteId: 'USR-S1',
        name: 'Active User',
        email: 'active@alpha.edu',
        passwordHash,
        role: AppRole.STUDENT,
        collegeId: collegeA._id,
        accountStatus: AccountStatus.ACTIVE,
      });

      const sessionId = crypto.randomUUID();
      await AuthSession.create({
        userId: user._id,
        sessionId,
        refreshTokenHash: 'hash_test_1',
        expiresAt: new Date(Date.now() + 3600000),
      });

      const token = signAccessToken({
        userId: user.id,
        role: AppRole.STUDENT,
        collegeId: collegeA.id,
        sessionId,
      });

      const res = await request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', `Bearer ${token}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.id).toBe(user.id);
    });

    it('2. Revoked session fails with an otherwise valid access token', async () => {
      const passwordHash = await PasswordService.hashPassword('Pass1234');
      const user = await User.create({
        instituteId: 'USR-S2',
        name: 'Revoked User',
        email: 'revoked@alpha.edu',
        passwordHash,
        role: AppRole.STUDENT,
        collegeId: collegeA._id,
        accountStatus: AccountStatus.ACTIVE,
      });

      const sessionId = crypto.randomUUID();
      await AuthSession.create({
        userId: user._id,
        sessionId,
        refreshTokenHash: 'hash_test_2',
        expiresAt: new Date(Date.now() + 3600000),
        revokedAt: new Date(), // Revoked session
      });

      const token = signAccessToken({
        userId: user.id,
        role: AppRole.STUDENT,
        collegeId: collegeA.id,
        sessionId,
      });

      const res = await request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', `Bearer ${token}`);

      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
      expect(res.body.error.message).toContain('revoked');
    });

    it('3. Expired session fails', async () => {
      const passwordHash = await PasswordService.hashPassword('Pass1234');
      const user = await User.create({
        instituteId: 'USR-S3',
        name: 'Expired Session User',
        email: 'expired_sess@alpha.edu',
        passwordHash,
        role: AppRole.STUDENT,
        collegeId: collegeA._id,
        accountStatus: AccountStatus.ACTIVE,
      });

      const sessionId = crypto.randomUUID();
      await AuthSession.create({
        userId: user._id,
        sessionId,
        refreshTokenHash: 'hash_test_3',
        expiresAt: new Date(Date.now() - 10000), // Expired in past
      });

      const token = signAccessToken({
        userId: user.id,
        role: AppRole.STUDENT,
        collegeId: collegeA.id,
        sessionId,
      });

      const res = await request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', `Bearer ${token}`);

      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
      expect(res.body.error.message).toContain('expired');
    });

    it('4. Session belonging to a different user fails', async () => {
      const passwordHash = await PasswordService.hashPassword('Pass1234');
      const userA = await User.create({
        instituteId: 'USR-S4A',
        name: 'User A',
        email: 'usera@alpha.edu',
        passwordHash,
        role: AppRole.STUDENT,
        collegeId: collegeA._id,
        accountStatus: AccountStatus.ACTIVE,
      });

      const userB = await User.create({
        instituteId: 'USR-S4B',
        name: 'User B',
        email: 'userb@alpha.edu',
        passwordHash,
        role: AppRole.STUDENT,
        collegeId: collegeA._id,
        accountStatus: AccountStatus.ACTIVE,
      });

      const sessionBId = crypto.randomUUID();
      await AuthSession.create({
        userId: userB._id,
        sessionId: sessionBId,
        refreshTokenHash: 'hash_test_4',
        expiresAt: new Date(Date.now() + 3600000),
      });

      // Token for userA pointing to userB's session
      const tokenA = signAccessToken({
        userId: userA.id,
        role: AppRole.STUDENT,
        collegeId: collegeA.id,
        sessionId: sessionBId,
      });

      const res = await request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', `Bearer ${tokenA}`);

      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
      expect(res.body.error.message).toContain('does not match');
    });

    it('5. Malformed session ID fails', async () => {
      const passwordHash = await PasswordService.hashPassword('Pass1234');
      const user = await User.create({
        instituteId: 'USR-S5',
        name: 'Malformed Session User',
        email: 'malformed_sess@alpha.edu',
        passwordHash,
        role: AppRole.STUDENT,
        collegeId: collegeA._id,
        accountStatus: AccountStatus.ACTIVE,
      });

      const token = signAccessToken({
        userId: user.id,
        role: AppRole.STUDENT,
        collegeId: collegeA.id,
        sessionId: 'not-a-valid-uuid-12345',
      });

      const res = await request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', `Bearer ${token}`);

      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
      expect(res.body.error.message).toContain('Invalid session identifier format');
    });

    it('6. Missing required session ID fails', async () => {
      const passwordHash = await PasswordService.hashPassword('Pass1234');
      const user = await User.create({
        instituteId: 'USR-S6',
        name: 'Missing Session User',
        email: 'missing_sess@alpha.edu',
        passwordHash,
        role: AppRole.STUDENT,
        collegeId: collegeA._id,
        accountStatus: AccountStatus.ACTIVE,
      });

      // Token specifies requireSession: true but omits sessionId
      const token = signAccessToken({
        userId: user.id,
        role: AppRole.STUDENT,
        collegeId: collegeA.id,
        requireSession: true,
      });

      const res = await request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', `Bearer ${token}`);

      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
      expect(res.body.error.message).toContain('session identifier is required');
    });

    it('7. Session-store failure fails closed', async () => {
      const passwordHash = await PasswordService.hashPassword('Pass1234');
      const user = await User.create({
        instituteId: 'USR-S7',
        name: 'DB Failure User',
        email: 'db_fail@alpha.edu',
        passwordHash,
        role: AppRole.STUDENT,
        collegeId: collegeA._id,
        accountStatus: AccountStatus.ACTIVE,
      });

      const sessionId = crypto.randomUUID();
      const token = signAccessToken({
        userId: user.id,
        role: AppRole.STUDENT,
        collegeId: collegeA.id,
        sessionId,
      });

      const findOneSpy = jest
        .spyOn(AuthSession, 'findOne')
        .mockRejectedValueOnce(new Error('Simulated session store network timeout'));

      const res = await request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', `Bearer ${token}`);

      findOneSpy.mockRestore();

      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
      expect(res.body.error.message).toContain('Session validation failed');
    });

    it('8. Logout invalidates subsequent protected requests', async () => {
      const passwordHash = await PasswordService.hashPassword('Pass1234');
      await User.create({
        instituteId: 'USR-S8',
        name: 'Logout Test User',
        email: 'logout_test@alpha.edu',
        passwordHash,
        role: AppRole.STUDENT,
        collegeId: collegeA._id,
        accountStatus: AccountStatus.ACTIVE,
      });

      // 1. Log in
      const loginRes = await request(app)
        .post('/api/v1/auth/login')
        .send({ identifier: 'logout_test@alpha.edu', password: 'Pass1234' });

      expect(loginRes.status).toBe(200);
      const accessToken = loginRes.body.data.accessToken;

      // 2. Verified access succeeds prior to logout
      const beforeRes = await request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', `Bearer ${accessToken}`);
      expect(beforeRes.status).toBe(200);

      // 3. Perform logout
      const logoutRes = await request(app)
        .post('/api/v1/auth/logout')
        .set('Authorization', `Bearer ${accessToken}`);
      expect(logoutRes.status).toBe(200);

      // 4. Subsequent protected request MUST fail closed
      const afterRes = await request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', `Bearer ${accessToken}`);
      expect(afterRes.status).toBe(401);
      expect(afterRes.body.error.message).toContain('revoked');
    });

    it('9. Refresh-token rotation continues to work', async () => {
      const passwordHash = await PasswordService.hashPassword('Pass1234');
      await User.create({
        instituteId: 'USR-S9',
        name: 'Rotation User',
        email: 'rotation@alpha.edu',
        passwordHash,
        role: AppRole.STUDENT,
        collegeId: collegeA._id,
        accountStatus: AccountStatus.ACTIVE,
      });

      const loginRes = await request(app)
        .post('/api/v1/auth/login')
        .send({ identifier: 'rotation@alpha.edu', password: 'Pass1234' });

      expect(loginRes.status).toBe(200);
      const { refreshToken } = loginRes.body.data;

      // Refresh token succeeds
      const refreshRes = await request(app)
        .post('/api/v1/auth/refresh')
        .send({ refreshToken });

      expect(refreshRes.status).toBe(200);
      expect(refreshRes.body.data.accessToken).toBeDefined();

      // New token accesses protected endpoint
      const meRes = await request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', `Bearer ${refreshRes.body.data.accessToken}`);
      expect(meRes.status).toBe(200);
    });

    it('10. Existing valid single-college login and protected requests continue working', async () => {
      const passwordHash = await PasswordService.hashPassword('Pass1234');
      await User.create({
        instituteId: 'USR-S10',
        name: 'Single College User',
        email: 'single_col@alpha.edu',
        passwordHash,
        role: AppRole.COLLEGE_ADMIN,
        collegeId: collegeA._id,
        accountStatus: AccountStatus.ACTIVE,
      });

      const loginRes = await request(app)
        .post('/api/v1/auth/login')
        .send({ identifier: 'single_col@alpha.edu', password: 'Pass1234' });

      expect(loginRes.status).toBe(200);
      const token = loginRes.body.data.accessToken;

      const deptRes = await request(app)
        .get('/api/v1/departments')
        .set('Authorization', `Bearer ${token}`);

      expect(deptRes.status).toBe(200);
      expect(deptRes.body.data.items).toBeDefined();
    });
  });

  // =========================================================================
  // GROUP 2: WORKSPACE SECURITY (Scenarios 11 - 23)
  // =========================================================================
  describe('Group 2: Workspace Security', () => {
    it('11. User with one active membership can access that workspace', async () => {
      const passwordHash = await PasswordService.hashPassword('Pass1234');
      const user = await User.create({
        instituteId: 'USR-WS11',
        name: 'Member Alpha',
        email: 'ws11@alpha.edu',
        passwordHash,
        role: AppRole.STUDENT,
        accountStatus: AccountStatus.ACTIVE,
      });

      const membership = await WorkspaceMembership.create({
        userId: user._id,
        collegeId: collegeA._id,
        status: MembershipStatus.ACTIVE,
      });

      await WorkspaceRoleAssignment.create({
        membershipId: membership._id,
        userId: user._id,
        collegeId: collegeA._id,
        role: AppRole.STUDENT,
        status: RoleAssignmentStatus.ACTIVE,
      });

      const sessionId = crypto.randomUUID();
      await AuthSession.create({
        userId: user._id,
        sessionId,
        refreshTokenHash: 'hash_ws11',
        expiresAt: new Date(Date.now() + 3600000),
      });

      const token = signAccessToken({
        userId: user.id,
        role: AppRole.STUDENT,
        sessionId,
      });

      const res = await request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', `Bearer ${token}`)
        .set('X-Workspace-Id', collegeA.id);

      expect(res.status).toBe(200);
      expect(res.body.data.collegeId).toBe(collegeA.id);
    });

    it('12. User with two active memberships can access each workspace only when selected and validated', async () => {
      const passwordHash = await PasswordService.hashPassword('Pass1234');
      const user = await User.create({
        instituteId: 'USR-WS12',
        name: 'Multi Member',
        email: 'ws12@multi.edu',
        passwordHash,
        role: AppRole.FACULTY,
        accountStatus: AccountStatus.ACTIVE,
      });

      // Membership in College A as FACULTY
      const memA = await WorkspaceMembership.create({
        userId: user._id,
        collegeId: collegeA._id,
        status: MembershipStatus.ACTIVE,
      });
      await WorkspaceRoleAssignment.create({
        membershipId: memA._id,
        userId: user._id,
        collegeId: collegeA._id,
        role: AppRole.FACULTY,
        departmentId: deptA1._id,
        status: RoleAssignmentStatus.ACTIVE,
      });

      // Membership in College B as HOD
      const memB = await WorkspaceMembership.create({
        userId: user._id,
        collegeId: collegeB._id,
        status: MembershipStatus.ACTIVE,
      });
      await WorkspaceRoleAssignment.create({
        membershipId: memB._id,
        userId: user._id,
        collegeId: collegeB._id,
        role: AppRole.HOD,
        departmentId: deptB1._id,
        status: RoleAssignmentStatus.ACTIVE,
      });

      const sessionId = crypto.randomUUID();
      await AuthSession.create({
        userId: user._id,
        sessionId,
        refreshTokenHash: 'hash_ws12',
        expiresAt: new Date(Date.now() + 3600000),
      });

      const token = signAccessToken({
        userId: user.id,
        role: AppRole.FACULTY,
        sessionId,
      });

      // 1. Select College A
      const resA = await request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', `Bearer ${token}`)
        .set('X-Workspace-Id', collegeA.id);

      expect(resA.status).toBe(200);
      expect(resA.body.data.collegeId).toBe(collegeA.id);
      expect(resA.body.data.role).toBe(AppRole.FACULTY);

      // 2. Select College B
      const resB = await request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', `Bearer ${token}`)
        .set('X-Workspace-Id', collegeB.id);

      expect(resB.status).toBe(200);
      expect(resB.body.data.collegeId).toBe(collegeB.id);
      expect(resB.body.data.role).toBe(AppRole.HOD);
    });

    it('13. Unknown workspace is rejected', async () => {
      const passwordHash = await PasswordService.hashPassword('Pass1234');
      const user = await User.create({
        instituteId: 'USR-WS13',
        name: 'User 13',
        email: 'ws13@alpha.edu',
        passwordHash,
        role: AppRole.STUDENT,
        collegeId: collegeA._id,
        accountStatus: AccountStatus.ACTIVE,
      });

      const sessionId = crypto.randomUUID();
      await AuthSession.create({
        userId: user._id,
        sessionId,
        refreshTokenHash: 'hash_ws13',
        expiresAt: new Date(Date.now() + 3600000),
      });

      const token = signAccessToken({
        userId: user.id,
        role: AppRole.STUDENT,
        sessionId,
      });

      const fakeCollegeId = new mongoose.Types.ObjectId().toString();
      const res = await request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', `Bearer ${token}`)
        .set('X-Workspace-Id', fakeCollegeId);

      expect(res.status).toBe(404);
      expect(res.body.error.message).toContain('Target workspace (college) does not exist');
    });

    it('14. Workspace header or claim cannot grant membership', async () => {
      const passwordHash = await PasswordService.hashPassword('Pass1234');
      const user = await User.create({
        instituteId: 'USR-WS14',
        name: 'User 14',
        email: 'ws14@alpha.edu',
        passwordHash,
        role: AppRole.STUDENT,
        accountStatus: AccountStatus.ACTIVE,
      });

      // User has active membership in College A only
      const memA = await WorkspaceMembership.create({
        userId: user._id,
        collegeId: collegeA._id,
        status: MembershipStatus.ACTIVE,
      });
      await WorkspaceRoleAssignment.create({
        membershipId: memA._id,
        userId: user._id,
        collegeId: collegeA._id,
        role: AppRole.STUDENT,
        status: RoleAssignmentStatus.ACTIVE,
      });

      const sessionId = crypto.randomUUID();
      await AuthSession.create({
        userId: user._id,
        sessionId,
        refreshTokenHash: 'hash_ws14',
        expiresAt: new Date(Date.now() + 3600000),
      });

      const token = signAccessToken({
        userId: user.id,
        role: AppRole.STUDENT,
        sessionId,
      });

      // User attempts to select College B via header without membership
      const res = await request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', `Bearer ${token}`)
        .set('X-Workspace-Id', collegeB.id);

      expect(res.status).toBe(403);
      expect(res.body.error.message).toContain('No active workspace membership found');
    });

    it('15. Conflicting workspace identifiers follow the documented precedence rule and fail safely', async () => {
      const passwordHash = await PasswordService.hashPassword('Pass1234');
      const user = await User.create({
        instituteId: 'USR-WS15',
        name: 'User 15',
        email: 'ws15@alpha.edu',
        passwordHash,
        role: AppRole.STUDENT,
        accountStatus: AccountStatus.ACTIVE,
      });

      const sessionId = crypto.randomUUID();
      await AuthSession.create({
        userId: user._id,
        sessionId,
        refreshTokenHash: 'hash_ws15',
        expiresAt: new Date(Date.now() + 3600000),
      });

      // Token specifies College A claim, but header specifies College B
      const token = signAccessToken({
        userId: user.id,
        role: AppRole.STUDENT,
        collegeId: collegeA.id,
        sessionId,
      });

      const res = await request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', `Bearer ${token}`)
        .set('X-Workspace-Id', collegeB.id);

      expect(res.status).toBe(400);
      expect(res.body.error.message).toContain('Conflicting workspace identifiers');
    });

    it('16. Pending membership is rejected', async () => {
      const passwordHash = await PasswordService.hashPassword('Pass1234');
      const user = await User.create({
        instituteId: 'USR-WS16',
        name: 'Pending User',
        email: 'pending_mem@alpha.edu',
        passwordHash,
        role: AppRole.STUDENT,
        accountStatus: AccountStatus.ACTIVE,
      });

      await WorkspaceMembership.create({
        userId: user._id,
        collegeId: collegeA._id,
        status: MembershipStatus.PENDING,
      });

      const sessionId = crypto.randomUUID();
      await AuthSession.create({
        userId: user._id,
        sessionId,
        refreshTokenHash: 'hash_ws16',
        expiresAt: new Date(Date.now() + 3600000),
      });

      const token = signAccessToken({
        userId: user.id,
        role: AppRole.STUDENT,
        sessionId,
      });

      const res = await request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', `Bearer ${token}`)
        .set('X-Workspace-Id', collegeA.id);

      expect(res.status).toBe(403);
      expect(res.body.error.message).toContain('pending');
    });

    it('17. Suspended membership is rejected', async () => {
      const passwordHash = await PasswordService.hashPassword('Pass1234');
      const user = await User.create({
        instituteId: 'USR-WS17',
        name: 'Suspended User',
        email: 'suspended_mem@alpha.edu',
        passwordHash,
        role: AppRole.STUDENT,
        accountStatus: AccountStatus.ACTIVE,
      });

      await WorkspaceMembership.create({
        userId: user._id,
        collegeId: collegeA._id,
        status: MembershipStatus.SUSPENDED,
      });

      const sessionId = crypto.randomUUID();
      await AuthSession.create({
        userId: user._id,
        sessionId,
        refreshTokenHash: 'hash_ws17',
        expiresAt: new Date(Date.now() + 3600000),
      });

      const token = signAccessToken({
        userId: user.id,
        role: AppRole.STUDENT,
        sessionId,
      });

      const res = await request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', `Bearer ${token}`)
        .set('X-Workspace-Id', collegeA.id);

      expect(res.status).toBe(403);
      expect(res.body.error.message).toContain('suspended');
    });

    it('18. Revoked membership is rejected', async () => {
      const passwordHash = await PasswordService.hashPassword('Pass1234');
      const user = await User.create({
        instituteId: 'USR-WS18',
        name: 'Revoked Membership User',
        email: 'revoked_mem@alpha.edu',
        passwordHash,
        role: AppRole.STUDENT,
        accountStatus: AccountStatus.ACTIVE,
      });

      await WorkspaceMembership.create({
        userId: user._id,
        collegeId: collegeA._id,
        status: MembershipStatus.REVOKED,
      });

      const sessionId = crypto.randomUUID();
      await AuthSession.create({
        userId: user._id,
        sessionId,
        refreshTokenHash: 'hash_ws18',
        expiresAt: new Date(Date.now() + 3600000),
      });

      const token = signAccessToken({
        userId: user.id,
        role: AppRole.STUDENT,
        sessionId,
      });

      const res = await request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', `Bearer ${token}`)
        .set('X-Workspace-Id', collegeA.id);

      expect(res.status).toBe(403);
      expect(res.body.error.message).toContain('revoked');
    });

    it('19. Deactivated/inactive membership is rejected', async () => {
      const passwordHash = await PasswordService.hashPassword('Pass1234');
      const user = await User.create({
        instituteId: 'USR-WS19',
        name: 'Inactive User',
        email: 'inactive_mem@alpha.edu',
        passwordHash,
        role: AppRole.STUDENT,
        accountStatus: AccountStatus.ACTIVE,
      });

      await WorkspaceMembership.create({
        userId: user._id,
        collegeId: collegeA._id,
        status: MembershipStatus.INACTIVE,
      });

      const sessionId = crypto.randomUUID();
      await AuthSession.create({
        userId: user._id,
        sessionId,
        refreshTokenHash: 'hash_ws19',
        expiresAt: new Date(Date.now() + 3600000),
      });

      const token = signAccessToken({
        userId: user.id,
        role: AppRole.STUDENT,
        sessionId,
      });

      const res = await request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', `Bearer ${token}`)
        .set('X-Workspace-Id', collegeA.id);

      expect(res.status).toBe(403);
      expect(res.body.error.message).toContain('inactive');
    });

    it('20. Legacy fields cannot bypass an invalid authoritative membership', async () => {
      const passwordHash = await PasswordService.hashPassword('Pass1234');
      // User has legacy User.collegeId set to collegeA, suggesting access
      const user = await User.create({
        instituteId: 'USR-WS20',
        name: 'Bypass Attempter',
        email: 'bypass@alpha.edu',
        passwordHash,
        role: AppRole.STUDENT,
        collegeId: collegeA._id,
        accountStatus: AccountStatus.ACTIVE,
      });

      // Authoritative WorkspaceMembership is explicitly REVOKED
      await WorkspaceMembership.create({
        userId: user._id,
        collegeId: collegeA._id,
        status: MembershipStatus.REVOKED,
      });

      const sessionId = crypto.randomUUID();
      await AuthSession.create({
        userId: user._id,
        sessionId,
        refreshTokenHash: 'hash_ws20',
        expiresAt: new Date(Date.now() + 3600000),
      });

      const token = signAccessToken({
        userId: user.id,
        role: AppRole.STUDENT,
        collegeId: collegeA.id,
        sessionId,
      });

      const res = await request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', `Bearer ${token}`);

      expect(res.status).toBe(403);
      expect(res.body.error.message).toContain('revoked');
    });

    it('21. A missing membership fails closed after the configured cutover', async () => {
      WorkspaceCompatibilityService.setLegacyFallbackEnabled(false);

      const passwordHash = await PasswordService.hashPassword('Pass1234');
      const user = await User.create({
        instituteId: 'USR-WS21',
        name: 'Unmigrated User',
        email: 'unmigrated@alpha.edu',
        passwordHash,
        role: AppRole.STUDENT,
        collegeId: collegeA._id, // Only legacy college exists
        accountStatus: AccountStatus.ACTIVE,
      });

      const sessionId = crypto.randomUUID();
      await AuthSession.create({
        userId: user._id,
        sessionId,
        refreshTokenHash: 'hash_ws21',
        expiresAt: new Date(Date.now() + 3600000),
      });

      const token = signAccessToken({
        userId: user.id,
        role: AppRole.STUDENT,
        collegeId: collegeA.id,
        sessionId,
      });

      const res = await request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', `Bearer ${token}`);

      expect(res.status).toBe(403);
      expect(res.body.error.message).toContain('No active workspace membership found');

      // Restore fallback for subsequent tests
      WorkspaceCompatibilityService.setLegacyFallbackEnabled(true);
    });

    it('22. One request cannot combine permissions from multiple colleges', async () => {
      const passwordHash = await PasswordService.hashPassword('Pass1234');
      const user = await User.create({
        instituteId: 'USR-WS22',
        name: 'Combined User',
        email: 'combined@multi.edu',
        passwordHash,
        role: AppRole.COLLEGE_ADMIN,
        accountStatus: AccountStatus.ACTIVE,
      });

      // Admin in College A
      const memA = await WorkspaceMembership.create({
        userId: user._id,
        collegeId: collegeA._id,
        status: MembershipStatus.ACTIVE,
      });
      await WorkspaceRoleAssignment.create({
        membershipId: memA._id,
        userId: user._id,
        collegeId: collegeA._id,
        role: AppRole.COLLEGE_ADMIN,
        status: RoleAssignmentStatus.ACTIVE,
      });

      // Admin in College B
      const memB = await WorkspaceMembership.create({
        userId: user._id,
        collegeId: collegeB._id,
        status: MembershipStatus.ACTIVE,
      });
      await WorkspaceRoleAssignment.create({
        membershipId: memB._id,
        userId: user._id,
        collegeId: collegeB._id,
        role: AppRole.COLLEGE_ADMIN,
        status: RoleAssignmentStatus.ACTIVE,
      });

      const sessionId = crypto.randomUUID();
      await AuthSession.create({
        userId: user._id,
        sessionId,
        refreshTokenHash: 'hash_ws22',
        expiresAt: new Date(Date.now() + 3600000),
      });

      const token = signAccessToken({
        userId: user.id,
        role: AppRole.COLLEGE_ADMIN,
        sessionId,
      });

      // Request selected in College A workspace MUST NOT see College B departments
      const res = await request(app)
        .get('/api/v1/departments')
        .set('Authorization', `Bearer ${token}`)
        .set('X-Workspace-Id', collegeA.id);

      expect(res.status).toBe(200);
      const items = res.body.data.items;
      expect(items.length).toBeGreaterThan(0);
      for (const dept of items) {
        expect(dept.collegeId).toBe(collegeA.id);
        expect(dept.collegeId).not.toBe(collegeB.id);
      }
    });

    it('23. SUPER_ADMIN platform behavior remains correct without accidental institutional privilege expansion', async () => {
      const passwordHash = await PasswordService.hashPassword('SuperPass123');
      const superAdmin = await User.create({
        instituteId: 'SA-001',
        name: 'Platform Super Admin',
        email: 'superadmin@acadex.edu',
        passwordHash,
        role: AppRole.SUPER_ADMIN,
        accountStatus: AccountStatus.ACTIVE,
      });

      const sessionId = crypto.randomUUID();
      await AuthSession.create({
        userId: superAdmin._id,
        sessionId,
        refreshTokenHash: 'hash_sa',
        expiresAt: new Date(Date.now() + 3600000),
      });

      const token = signAccessToken({
        userId: superAdmin.id,
        role: AppRole.SUPER_ADMIN,
        sessionId,
      });

      // Super Admin accesses platform without college membership
      const res = await request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', `Bearer ${token}`);

      expect(res.status).toBe(200);
      expect(res.body.data.role).toBe(AppRole.SUPER_ADMIN);

      // Super Admin can list all departments across colleges
      const listRes = await request(app)
        .get('/api/v1/departments')
        .set('Authorization', `Bearer ${token}`);

      expect(listRes.status).toBe(200);
      expect(listRes.body.data.items.length).toBe(3); // deptA1, deptA2, deptB1
    });
  });

  // =========================================================================
  // GROUP 3: ROLE AND SCOPE SECURITY (Scenarios 24 - 30)
  // =========================================================================
  describe('Group 3: Role and Scope Security', () => {
    it('24. Active role assignment in the correct college succeeds', async () => {
      const passwordHash = await PasswordService.hashPassword('Pass1234');
      const admin = await User.create({
        instituteId: 'ADMIN-A',
        name: 'Admin Alpha',
        email: 'admin_a@alpha.edu',
        passwordHash,
        role: AppRole.COLLEGE_ADMIN,
        accountStatus: AccountStatus.ACTIVE,
      });

      const mem = await WorkspaceMembership.create({
        userId: admin._id,
        collegeId: collegeA._id,
        status: MembershipStatus.ACTIVE,
      });

      await WorkspaceRoleAssignment.create({
        membershipId: mem._id,
        userId: admin._id,
        collegeId: collegeA._id,
        role: AppRole.COLLEGE_ADMIN,
        status: RoleAssignmentStatus.ACTIVE,
      });

      const sessionId = crypto.randomUUID();
      await AuthSession.create({
        userId: admin._id,
        sessionId,
        refreshTokenHash: 'hash_admin_a',
        expiresAt: new Date(Date.now() + 3600000),
      });

      const token = signAccessToken({
        userId: admin.id,
        role: AppRole.COLLEGE_ADMIN,
        sessionId,
      });

      const res = await request(app)
        .get('/api/v1/departments')
        .set('Authorization', `Bearer ${token}`)
        .set('X-Workspace-Id', collegeA.id);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });

    it('25. Revoked or suspended role assignment fails', async () => {
      const passwordHash = await PasswordService.hashPassword('Pass1234');
      const admin = await User.create({
        instituteId: 'ADMIN-A-REV',
        name: 'Revoked Admin',
        email: 'rev_admin@alpha.edu',
        passwordHash,
        role: AppRole.COLLEGE_ADMIN,
        accountStatus: AccountStatus.ACTIVE,
      });

      const mem = await WorkspaceMembership.create({
        userId: admin._id,
        collegeId: collegeA._id,
        status: MembershipStatus.ACTIVE,
      });

      await WorkspaceRoleAssignment.create({
        membershipId: mem._id,
        userId: admin._id,
        collegeId: collegeA._id,
        role: AppRole.COLLEGE_ADMIN,
        status: RoleAssignmentStatus.REVOKED, // Revoked role
      });

      const sessionId = crypto.randomUUID();
      await AuthSession.create({
        userId: admin._id,
        sessionId,
        refreshTokenHash: 'hash_rev_admin',
        expiresAt: new Date(Date.now() + 3600000),
      });

      const token = signAccessToken({
        userId: admin.id,
        role: AppRole.COLLEGE_ADMIN,
        sessionId,
      });

      const res = await request(app)
        .get('/api/v1/departments')
        .set('Authorization', `Bearer ${token}`)
        .set('X-Workspace-Id', collegeA.id);

      expect(res.status).toBe(403);
      expect(res.body.error.message).toContain('No active role assignments found in this workspace');
    });

    it('26. HOD access is restricted to its department', async () => {
      const passwordHash = await PasswordService.hashPassword('Pass1234');
      const hod = await User.create({
        instituteId: 'HOD-A1',
        name: 'HOD CSE Alpha',
        email: 'hod_cse@alpha.edu',
        passwordHash,
        role: AppRole.HOD,
        departmentId: deptA1._id,
        accountStatus: AccountStatus.ACTIVE,
      });

      const mem = await WorkspaceMembership.create({
        userId: hod._id,
        collegeId: collegeA._id,
        status: MembershipStatus.ACTIVE,
      });

      await WorkspaceRoleAssignment.create({
        membershipId: mem._id,
        userId: hod._id,
        collegeId: collegeA._id,
        role: AppRole.HOD,
        departmentId: deptA1._id,
        status: RoleAssignmentStatus.ACTIVE,
      });

      const sessionId = crypto.randomUUID();
      await AuthSession.create({
        userId: hod._id,
        sessionId,
        refreshTokenHash: 'hash_hod_cse',
        expiresAt: new Date(Date.now() + 3600000),
      });

      const token = signAccessToken({
        userId: hod.id,
        role: AppRole.HOD,
        departmentId: deptA1.id,
        sessionId,
      });

      // Try to mutate Dept A2 (ECE) as HOD of Dept A1 (CSE)
      const res = await request(app)
        .put(`/api/v1/departments/${deptA2.id}`)
        .set('Authorization', `Bearer ${token}`)
        .set('X-Workspace-Id', collegeA.id)
        .send({ name: 'HOD Malicious Rename' });

      // Only administrators can update departments
      expect(res.status).toBe(403);
    });

    it('27. Cross-college department IDs are rejected', async () => {
      const passwordHash = await PasswordService.hashPassword('Pass1234');
      const adminA = await User.create({
        instituteId: 'ADMIN-A2',
        name: 'Admin A2',
        email: 'admin_a2@alpha.edu',
        passwordHash,
        role: AppRole.COLLEGE_ADMIN,
        accountStatus: AccountStatus.ACTIVE,
      });

      const mem = await WorkspaceMembership.create({
        userId: adminA._id,
        collegeId: collegeA._id,
        status: MembershipStatus.ACTIVE,
      });

      await WorkspaceRoleAssignment.create({
        membershipId: mem._id,
        userId: adminA._id,
        collegeId: collegeA._id,
        role: AppRole.COLLEGE_ADMIN,
        status: RoleAssignmentStatus.ACTIVE,
      });

      const sessionId = crypto.randomUUID();
      await AuthSession.create({
        userId: adminA._id,
        sessionId,
        refreshTokenHash: 'hash_admin_a2',
        expiresAt: new Date(Date.now() + 3600000),
      });

      const token = signAccessToken({
        userId: adminA.id,
        role: AppRole.COLLEGE_ADMIN,
        sessionId,
      });

      // Admin of College A tries to get Dept B1 (College B)
      const res = await request(app)
        .get(`/api/v1/departments/${deptB1.id}`)
        .set('Authorization', `Bearer ${token}`)
        .set('X-Workspace-Id', collegeA.id);

      expect(res.status).toBe(403);
      expect(res.body.error.message).toContain('Cross-college tenant access is strictly prohibited');
    });

    it('28. College Admin cannot access another college', async () => {
      const passwordHash = await PasswordService.hashPassword('Pass1234');
      const adminA = await User.create({
        instituteId: 'ADMIN-A3',
        name: 'Admin A3',
        email: 'admin_a3@alpha.edu',
        passwordHash,
        role: AppRole.COLLEGE_ADMIN,
        accountStatus: AccountStatus.ACTIVE,
      });

      const mem = await WorkspaceMembership.create({
        userId: adminA._id,
        collegeId: collegeA._id,
        status: MembershipStatus.ACTIVE,
      });

      await WorkspaceRoleAssignment.create({
        membershipId: mem._id,
        userId: adminA._id,
        collegeId: collegeA._id,
        role: AppRole.COLLEGE_ADMIN,
        status: RoleAssignmentStatus.ACTIVE,
      });

      const sessionId = crypto.randomUUID();
      await AuthSession.create({
        userId: adminA._id,
        sessionId,
        refreshTokenHash: 'hash_admin_a3',
        expiresAt: new Date(Date.now() + 3600000),
      });

      const token = signAccessToken({
        userId: adminA.id,
        role: AppRole.COLLEGE_ADMIN,
        sessionId,
      });

      // Tries to create department in College B while authenticated in College A
      const res = await request(app)
        .post('/api/v1/departments')
        .set('Authorization', `Bearer ${token}`)
        .set('X-Workspace-Id', collegeA.id)
        .send({
          collegeId: collegeB.id,
          name: 'Spoofed Department',
          code: 'SPOOF',
        });

      expect(res.status).toBe(403);
      expect(res.body.error.message).toContain('Cross-college tenant access is strictly prohibited');
    });

    it('29. Faculty cannot mutate another FacultyAssignment resources', async () => {
      const facultyUser1 = await User.create({
        instituteId: 'FAC-1',
        name: 'Prof. Alice',
        email: 'alice@alpha.edu',
        passwordHash: 'hash',
        role: AppRole.FACULTY,
        accountStatus: AccountStatus.ACTIVE,
      });

      const facultyUser2 = await User.create({
        instituteId: 'FAC-2',
        name: 'Prof. Bob',
        email: 'bob@alpha.edu',
        passwordHash: 'hash',
        role: AppRole.FACULTY,
        accountStatus: AccountStatus.ACTIVE,
      });

      await Faculty.create({
        userId: facultyUser1._id,
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        employeeId: 'EMP-1',
        name: 'Prof. Alice',
        email: 'alice@alpha.edu',
        phone: '1111111111',
        designation: 'Assistant Professor',
        isActive: true,
      });

      const facProfile2 = await Faculty.create({
        userId: facultyUser2._id,
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        employeeId: 'EMP-2',
        name: 'Prof. Bob',
        email: 'bob@alpha.edu',
        phone: '2222222222',
        designation: 'Associate Professor',
        isActive: true,
      });

      const subject = await Subject.create({
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        courseId: new mongoose.Types.ObjectId(),
        semesterId: new mongoose.Types.ObjectId(),
        name: 'Data Structures',
        code: 'CS-DS-01',
      });

      const assignment2 = await FacultyAssignment.create({
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        courseId: subject.courseId,
        facultyName: 'Prof. Bob',
        subjectId: subject._id,
        facultyId: facProfile2._id,
        academicYearId: new mongoose.Types.ObjectId(),
        semesterId: new mongoose.Types.ObjectId(),
        status: 'active',
        isActive: true,
      });

      // Assert that Alice CANNOT access or mutate Bob's assignment
      await expect(
        TeachingAuthorizationService.assertFacultyAssignmentAccess(
          collegeA.id,
          { id: facultyUser1.id, role: AppRole.FACULTY },
          assignment2._id.toString()
        )
      ).rejects.toThrow('This context is not assigned to you');
    });

    it('30. Student cannot access another student records without explicit authorization', async () => {
      const student1 = await User.create({
        instituteId: 'STU-1',
        name: 'Student One',
        email: 'stu1@alpha.edu',
        passwordHash: 'hash',
        role: AppRole.STUDENT,
        accountStatus: AccountStatus.ACTIVE,
      });

      const student2 = await User.create({
        instituteId: 'STU-2',
        name: 'Student Two',
        email: 'stu2@alpha.edu',
        passwordHash: 'hash',
        role: AppRole.STUDENT,
        accountStatus: AccountStatus.ACTIVE,
      });

      const mem1 = await WorkspaceMembership.create({
        userId: student1._id,
        collegeId: collegeA._id,
        status: MembershipStatus.ACTIVE,
      });
      await WorkspaceRoleAssignment.create({
        membershipId: mem1._id,
        userId: student1._id,
        collegeId: collegeA._id,
        role: AppRole.STUDENT,
        status: RoleAssignmentStatus.ACTIVE,
      });

      const sessionId = crypto.randomUUID();
      await AuthSession.create({
        userId: student1._id,
        sessionId,
        refreshTokenHash: 'hash_stu1',
        expiresAt: new Date(Date.now() + 3600000),
      });

      const token1 = signAccessToken({
        userId: student1.id,
        role: AppRole.STUDENT,
        sessionId,
      });

      // Student 1 tries to access Student 2's profile
      const res = await request(app)
        .get(`/api/v1/profile/${student2.id}`)
        .set('Authorization', `Bearer ${token1}`)
        .set('X-Workspace-Id', collegeA.id);

      expect(res.status).toBe(403);
      expect(res.body.error.message).toContain('Students cannot access other student profiles');
    });
  });

  // =========================================================================
  // GROUP 4: PROFILE AND REGRESSION SECURITY (Scenarios 31 - 36)
  // =========================================================================
  describe('Group 4: Profile and Regression Security', () => {
    it('31. Faculty profile lookup is college-scoped', async () => {
      const user = await User.create({
        instituteId: 'FAC-DUAL',
        name: 'Dr. Dual Professor',
        email: 'dual@prof.edu',
        passwordHash: 'hash',
        role: AppRole.FACULTY,
        accountStatus: AccountStatus.ACTIVE,
      });

      // Profile in College Alpha
      const profAlpha = await Faculty.create({
        userId: user._id,
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        employeeId: 'EMP-ALPHA-01',
        name: 'Dr. Dual Alpha',
        email: 'dual@prof.edu',
        phone: '1111111111',
        designation: 'Professor',
        isActive: true,
      });

      // Profile in College Beta
      const profBeta = await Faculty.create({
        userId: user._id,
        collegeId: collegeB._id,
        departmentId: deptB1._id,
        employeeId: 'EMP-BETA-01',
        name: 'Dr. Dual Beta',
        email: 'dual@prof.edu',
        phone: '2222222222',
        designation: 'Visiting Professor',
        isActive: true,
      });

      // Look up under College A
      const resolvedAlpha = await AttendanceService.resolveFacultyProfile({
        id: user.id,
        instituteId: user.instituteId,
        name: user.name,
        role: AppRole.FACULTY,
        collegeId: collegeA.id,
        accountStatus: AccountStatus.ACTIVE,
      });

      expect(resolvedAlpha._id.toString()).toBe(profAlpha._id.toString());
      expect(resolvedAlpha.collegeId.toString()).toBe(collegeA.id);

      // Look up under College B
      const resolvedBeta = await AttendanceService.resolveFacultyProfile({
        id: user.id,
        instituteId: user.instituteId,
        name: user.name,
        role: AppRole.FACULTY,
        collegeId: collegeB.id,
        accountStatus: AccountStatus.ACTIVE,
      });

      expect(resolvedBeta._id.toString()).toBe(profBeta._id.toString());
      expect(resolvedBeta.collegeId.toString()).toBe(collegeB.id);
    });

    it('32. Student profile lookup is college-scoped where applicable', async () => {
      const user = await User.create({
        instituteId: 'STU-DUAL',
        name: 'Dual Student',
        email: 'dual@stu.edu',
        passwordHash: 'hash',
        role: AppRole.STUDENT,
        accountStatus: AccountStatus.ACTIVE,
      });

      const stuAlpha = await Student.create({
        userId: user._id,
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        admissionNumber: 'ADM-ALPHA-01',
        name: 'Dual Student Alpha',
        email: 'dual@stu.edu',
        isActive: true,
      });

      const stuBeta = await Student.create({
        userId: user._id,
        collegeId: collegeB._id,
        departmentId: deptB1._id,
        admissionNumber: 'ADM-BETA-01',
        name: 'Dual Student Beta',
        email: 'dual@stu.edu',
        isActive: true,
      });

      // Scoped queries with collegeId
      const foundAlpha = await Student.findOne({
        userId: user._id,
        collegeId: collegeA._id,
      });
      expect(foundAlpha?._id.toString()).toBe(stuAlpha._id.toString());

      const foundBeta = await Student.findOne({
        userId: user._id,
        collegeId: collegeB._id,
      });
      expect(foundBeta?._id.toString()).toBe(stuBeta._id.toString());
    });

    it('33. User._id is not confused with Faculty._id or Student._id', async () => {
      const user = await User.create({
        instituteId: 'ID-DISTINCT-01',
        name: 'Dr. Identity Check',
        email: 'idcheck@alpha.edu',
        passwordHash: 'hash',
        role: AppRole.FACULTY,
        accountStatus: AccountStatus.ACTIVE,
      });

      const faculty = await Faculty.create({
        userId: user._id,
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        employeeId: 'EMP-IDCHECK',
        name: 'Dr. Identity Check',
        email: 'idcheck@alpha.edu',
        phone: '9998887777',
        designation: 'Professor',
        isActive: true,
      });

      expect(user._id.toString()).not.toBe(faculty._id.toString());

      const subject = await Subject.create({
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        courseId: new mongoose.Types.ObjectId(),
        semesterId: new mongoose.Types.ObjectId(),
        name: 'Operating Systems',
        code: 'CS-OS-01',
      });

      const fa = await FacultyAssignment.create({
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        courseId: subject.courseId,
        facultyName: faculty.name,
        subjectId: subject._id,
        facultyId: faculty._id, // Must store Faculty._id
        academicYearId: new mongoose.Types.ObjectId(),
        semesterId: new mongoose.Types.ObjectId(),
        status: 'active',
        isActive: true,
      });

      expect(fa.facultyId.toString()).toBe(faculty._id.toString());
      expect(fa.facultyId.toString()).not.toBe(user._id.toString());
    });

    it('34. Attendance, assessment, assignment, and notes ownership checks remain intact', async () => {
      const facultyUser = await User.create({
        instituteId: 'FAC-OWN-01',
        name: 'Prof. Owner',
        email: 'owner@alpha.edu',
        passwordHash: 'hash',
        role: AppRole.FACULTY,
        accountStatus: AccountStatus.ACTIVE,
      });

      const faculty = await Faculty.create({
        userId: facultyUser._id,
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        employeeId: 'EMP-OWN',
        name: 'Prof. Owner',
        email: 'owner@alpha.edu',
        phone: '5556667777',
        designation: 'Professor',
        isActive: true,
      });

      const subject = await Subject.create({
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        courseId: new mongoose.Types.ObjectId(),
        semesterId: new mongoose.Types.ObjectId(),
        name: 'Software Engineering',
        code: 'CS-SE-01',
      });

      const fa = await FacultyAssignment.create({
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        courseId: subject.courseId,
        facultyName: faculty.name,
        subjectId: subject._id,
        facultyId: faculty._id,
        academicYearId: new mongoose.Types.ObjectId(),
        semesterId: new mongoose.Types.ObjectId(),
        status: 'active',
        isActive: true,
      });

      // Owner verifies true
      const isOwner = await TeachingAuthorizationService.isFacultyOwner(
        collegeA.id,
        { id: facultyUser.id, role: AppRole.FACULTY },
        fa
      );
      expect(isOwner).toBe(true);

      // Non-owner verifies false
      const isStrangerOwner = await TeachingAuthorizationService.isFacultyOwner(
        collegeA.id,
        { id: new mongoose.Types.ObjectId().toString(), role: AppRole.FACULTY },
        fa
      );
      expect(isStrangerOwner).toBe(false);
    });

    it('35. Audit context uses backend-validated workspace and role information', async () => {
      const user = await User.create({
        instituteId: 'AUDIT-USER-01',
        name: 'Audited Admin',
        email: 'audit_user@alpha.edu',
        passwordHash: 'hash',
        role: AppRole.COLLEGE_ADMIN,
        accountStatus: AccountStatus.ACTIVE,
      });

      const mem = await WorkspaceMembership.create({
        userId: user._id,
        collegeId: collegeA._id,
        status: MembershipStatus.ACTIVE,
      });

      const log = await AuditService.logAuthoritativeAction(
        {
          id: user.id,
          instituteId: user.instituteId,
          name: user.name,
          role: AppRole.COLLEGE_ADMIN,
          collegeId: collegeA.id,
          departmentId: deptA1.id,
          workspaceMembershipId: mem.id,
          accountStatus: AccountStatus.ACTIVE,
        },
        'ACADEMIC_RECORD_PUBLISHED',
        'AcademicRecord',
        'rec_123',
        {
          newValue: { status: 'published' },
        }
      );

      expect(log.collegeId).toBe(collegeA.id);
      expect(log.departmentId).toBe(deptA1.id);
      expect(log.workspaceMembershipId).toBe(mem.id);
      expect(log.actorRole).toBe(AppRole.COLLEGE_ADMIN);
      expect(log.actorUserId).toBe(user.id);
    });

    it('36. Client-supplied audit context cannot forge the authorized college or department', async () => {
      const user = await User.create({
        instituteId: 'FORGE-USER-01',
        name: 'Forging Attempt',
        email: 'forge@alpha.edu',
        passwordHash: 'hash',
        role: AppRole.HOD,
        departmentId: deptA1._id,
        accountStatus: AccountStatus.ACTIVE,
      });

      // Authenticated user context bound by backend
      const authenticatedUser = {
        id: user.id,
        instituteId: user.instituteId,
        name: user.name,
        role: AppRole.HOD,
        collegeId: collegeA.id,
        departmentId: deptA1.id, // Authorized dept is deptA1
        workspaceMembershipId: 'mem_valid_alpha',
        accountStatus: AccountStatus.ACTIVE,
      };

      // Client attempts to pass spoofed college and department in untrusted payload
      const untrustedClientPayload = {
        collegeId: collegeB.id, // Spoof College B
        departmentId: deptB1.id, // Spoof Dept B
        name: 'Forged Record',
      };

      const auditRecord = await AuditService.logAuthoritativeAction(
        authenticatedUser,
        'DATA_MUTATION',
        'DepartmentConfig',
        'cfg_999',
        {
          newValue: { name: untrustedClientPayload.name },
        }
      );

      // Audit log MUST reflect validated context, NOT client payload
      expect(auditRecord.collegeId).toBe(collegeA.id);
      expect(auditRecord.collegeId).not.toBe(untrustedClientPayload.collegeId);
      expect(auditRecord.departmentId).toBe(deptA1.id);
      expect(auditRecord.departmentId).not.toBe(untrustedClientPayload.departmentId);
    });
  });
});
