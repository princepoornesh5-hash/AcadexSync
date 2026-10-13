import request from 'supertest';
import { WebSocket } from 'ws';
import mongoose from 'mongoose';
import crypto from 'crypto';
import { app } from '../../src/app';
import {
  User,
  College,
  Department,
  AuthSession,
  WorkspaceMembership,
  WorkspaceRoleAssignment,
  Note,
  AttendanceSession,
} from '../../src/models';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { PasswordService } from '../../src/services/password.service';
import { AppRole } from '../../src/constants/roles';
import {
  AccountStatus,
  MembershipStatus,
  RoleAssignmentStatus,
  CollegeStatus,
  AttendanceSessionStatus,
  NoteStatus,
} from '../../src/constants/status';
import { signAccessToken } from '../../src/utils/token';
import { RoomManager, ConnectionIdentity } from '../../src/realtime/roomManager';
import { RealtimeServer } from '../../src/realtime/realtime.server';
import { WorkspaceMembershipService } from '../../src/services/workspaceMembership.service';
import { WorkspaceMigrationService } from '../../src/services/migration/workspaceMigration.service';
import { AcadexEventType } from '../../src/realtime/contracts/eventRegistry';
import { RealtimeEventEnvelope } from '../../src/realtime/contracts/eventEnvelope';

describe('Big Boss Prompt 5: Final Security Hardening, Multi-Workspace Regression, Migration Readiness', () => {
  let collegeA: InstanceType<typeof College>;
  let collegeB: InstanceType<typeof College>;
  let deptA: InstanceType<typeof Department>;
  let deptB: InstanceType<typeof Department>;

  let userAdminA: InstanceType<typeof User>;
  let userFacultyA: InstanceType<typeof User>;
  let userFacultyB: InstanceType<typeof User>;
  let userSuperAdmin: InstanceType<typeof User>;

  let roomManager: RoomManager;

  const createMockSocket = () => {
    return {
      readyState: WebSocket.OPEN,
      send: jest.fn(),
      close: jest.fn(),
      isAlive: true,
      on: jest.fn(),
      ping: jest.fn(),
      terminate: jest.fn(),
    } as unknown as any;
  };

  beforeAll(async () => {
    await setupTestDB();
    await User.init();
    await College.init();
    await Department.init();
    await WorkspaceMembership.init();
    await WorkspaceRoleAssignment.init();
    await AuthSession.init();
    await Note.init();
    await AttendanceSession.init();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();
    roomManager = RoomManager.getInstance();
    roomManager.clear();

    // 1. Setup Colleges
    collegeA = await College.create({
      name: 'College Alpha',
      code: 'ALPHA',
      address: '100 Alpha St',
      email: 'admin@alpha.edu',
      phone: '1234567890',
      principal: 'Dr. Alpha Principal',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });

    collegeB = await College.create({
      name: 'College Beta',
      code: 'BETA',
      address: '200 Beta St',
      email: 'admin@beta.edu',
      phone: '0987654321',
      principal: 'Dr. Beta Principal',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });

    deptA = await Department.create({
      collegeId: collegeA._id,
      name: 'Computer Science',
      code: 'CS',
      status: 'active',
      isActive: true,
    });

    deptB = await Department.create({
      collegeId: collegeB._id,
      name: 'Electrical Engineering',
      code: 'EE',
      status: 'active',
      isActive: true,
    });

    const hashedPassword = await PasswordService.hashPassword('Password123!');

    // 2. Setup Users
    userSuperAdmin = await User.create({
      name: 'Global Super Admin',
      email: 'superadmin@acadex.edu',
      password: hashedPassword,
      role: AppRole.SUPER_ADMIN,
      roles: [AppRole.SUPER_ADMIN],
      collegeId: null,
      accountStatus: AccountStatus.ACTIVE,
      isEmailVerified: true,
    });

    userAdminA = await User.create({
      name: 'Admin Alpha',
      email: 'admin@alpha.edu',
      password: hashedPassword,
      role: AppRole.COLLEGE_ADMIN,
      roles: [AppRole.COLLEGE_ADMIN],
      collegeId: collegeA._id,
      accountStatus: AccountStatus.ACTIVE,
      isEmailVerified: true,
    });

    userFacultyA = await User.create({
      name: 'Prof. Alice Alpha',
      email: 'alice@alpha.edu',
      password: hashedPassword,
      role: AppRole.FACULTY,
      roles: [AppRole.FACULTY],
      collegeId: collegeA._id,
      departmentId: deptA._id,
      accountStatus: AccountStatus.ACTIVE,
      isEmailVerified: true,
    });

    userFacultyB = await User.create({
      name: 'Prof. Bob Beta',
      email: 'bob@beta.edu',
      password: hashedPassword,
      role: AppRole.FACULTY,
      roles: [AppRole.FACULTY],
      collegeId: collegeB._id,
      departmentId: deptB._id,
      accountStatus: AccountStatus.ACTIVE,
      isEmailVerified: true,
    });
  });

  // =========================================================================
  // SECTION 3: CRITICAL FIX - IMMEDIATE REALTIME ACCESS REVOCATION
  // =========================================================================
  describe('3. Critical Fix: Immediate Realtime Access Revocation', () => {
    it('3.1: Revoking membership immediately removes institutional and role rooms from active socket', async () => {
      // Create active membership for Faculty A
      const membership = await WorkspaceMembership.create({
        userId: userFacultyA._id,
        collegeId: collegeA._id,
        status: MembershipStatus.ACTIVE,
        isDefault: true,
      });

      await WorkspaceRoleAssignment.create({
        membershipId: membership._id,
        userId: userFacultyA._id,
        collegeId: collegeA._id,
        role: AppRole.FACULTY,
        departmentId: deptA._id,
        status: RoleAssignmentStatus.ACTIVE,
      });

      // Register connection with active identity
      const mockWs = createMockSocket();
      const identity: ConnectionIdentity = {
        userId: String(userFacultyA._id),
        collegeId: String(collegeA._id),
        role: AppRole.FACULTY,
        departmentId: String(deptA._id),
        connectedAt: new Date(),
      };

      roomManager.registerAuthenticatedSocket(mockWs, identity);

      // Verify initial rooms
      const initialRooms = roomManager.getRoomsForSocket(mockWs);
      expect(initialRooms).toContain(`college:${collegeA._id}`);
      expect(initialRooms).toContain(`department:${collegeA._id}:${deptA._id}`);
      expect(initialRooms).toContain(`role:${collegeA._id}:${AppRole.FACULTY}`);
      expect(initialRooms).toContain(`user:${userFacultyA._id}`);

      // Perform membership status update to REVOKED via authoritative service
      await WorkspaceMembershipService.updateMembershipStatus(
        String(membership._id),
        MembershipStatus.REVOKED,
        String(userAdminA._id)
      );

      // Room manager must have immediately stripped all institutional rooms
      const updatedRooms = roomManager.getRoomsForSocket(mockWs);
      expect(updatedRooms).not.toContain(`college:${collegeA._id}`);
      expect(updatedRooms).not.toContain(`department:${collegeA._id}:${deptA._id}`);
      expect(updatedRooms).not.toContain(`role:${collegeA._id}:${AppRole.FACULTY}`);
      // Personal room is preserved
      expect(updatedRooms).toContain(`user:${userFacultyA._id}`);

      // Sockets should have received the 'workspace_revoked' outbound frame
      expect(mockWs.send).toHaveBeenCalled();
      const lastPayload = JSON.parse((mockWs.send as jest.Mock).mock.calls[0][0]);
      expect(lastPayload.type).toBe('workspace_revoked');
    });

    it('3.2: Connecting with old token after revocation fails closed to personal room only', async () => {
      // Create membership initially in REVOKED state
      await WorkspaceMembership.create({
        userId: userFacultyA._id,
        collegeId: collegeA._id,
        status: MembershipStatus.REVOKED,
        isDefault: true,
      });

      // Old token generated before revocation containing collegeA claim
      const oldToken = signAccessToken({
        userId: String(userFacultyA._id),
        role: AppRole.FACULTY,
        collegeId: String(collegeA._id),
      });

      const server = RealtimeServer.getInstance();
      const mockWs = createMockSocket();

      // Attempt authenticateSocket with the old token
      await server.authenticateSocket(mockWs, oldToken);

      // Sockets authenticated with revoked membership must NOT be granted collegeA rooms
      const currentIdentity = roomManager.getIdentity(mockWs);
      expect(currentIdentity).toBeDefined();
      expect(currentIdentity?.collegeId).toBe('unassigned');

      const rooms = roomManager.getRoomsForSocket(mockWs);
      expect(rooms).not.toContain(`college:${collegeA._id}`);
      expect(rooms).toContain(`user:${userFacultyA._id}`);
    });

    it('3.3: Suspending membership has identical fail-closed effect', async () => {
      const membership = await WorkspaceMembership.create({
        userId: userFacultyA._id,
        collegeId: collegeA._id,
        status: MembershipStatus.ACTIVE,
        isDefault: true,
      });

      const mockWs = createMockSocket();
      roomManager.registerAuthenticatedSocket(mockWs, {
        userId: String(userFacultyA._id),
        collegeId: String(collegeA._id),
        role: AppRole.FACULTY,
        connectedAt: new Date(),
      });

      expect(roomManager.getRoomsForSocket(mockWs)).toContain(`college:${collegeA._id}`);

      // Suspend membership
      await WorkspaceMembershipService.updateMembershipStatus(
        String(membership._id),
        MembershipStatus.SUSPENDED,
        String(userAdminA._id)
      );

      // Institutional rooms stripped immediately
      expect(roomManager.getRoomsForSocket(mockWs)).not.toContain(`college:${collegeA._id}`);
    });

    it('3.4: Revoking one role removes only affected role/department while preserving other valid roles', async () => {
      const membership = await WorkspaceMembership.create({
        userId: userFacultyA._id,
        collegeId: collegeA._id,
        status: MembershipStatus.ACTIVE,
        isDefault: true,
      });

      await WorkspaceRoleAssignment.create({
        membershipId: membership._id,
        userId: userFacultyA._id,
        collegeId: collegeA._id,
        role: AppRole.FACULTY,
        status: RoleAssignmentStatus.ACTIVE,
      });

      const hodRole = await WorkspaceRoleAssignment.create({
        membershipId: membership._id,
        userId: userFacultyA._id,
        collegeId: collegeA._id,
        role: AppRole.HOD,
        departmentId: deptA._id,
        status: RoleAssignmentStatus.ACTIVE,
      });

      const mockWs = createMockSocket();
      roomManager.registerAuthenticatedSocket(mockWs, {
        userId: String(userFacultyA._id),
        collegeId: String(collegeA._id),
        role: AppRole.HOD,
        departmentId: String(deptA._id),
        connectedAt: new Date(),
      });

      // Revoke the HOD role assignment
      await WorkspaceMembershipService.updateRoleAssignmentStatus(
        String(hodRole._id),
        RoleAssignmentStatus.REVOKED,
        String(userAdminA._id)
      );

      const rooms = roomManager.getRoomsForSocket(mockWs);
      // HOD and Dept rooms removed
      expect(rooms).not.toContain(`role:${collegeA._id}:${AppRole.HOD}`);
      expect(rooms).not.toContain(`department:${collegeA._id}:${deptA._id}`);
      // College and Faculty role rooms preserved!
      expect(rooms).toContain(`college:${collegeA._id}`);
      expect(rooms).toContain(`role:${collegeA._id}:${AppRole.FACULTY}`);
      expect(rooms).toContain(`user:${userFacultyA._id}`);
    });

    it('3.5: Disconnection and session logout closes only the affected session socket', async () => {
      const session1Id = 'sess_device_mobile';
      const session2Id = 'sess_device_web';

      const mockWs1 = createMockSocket();
      const mockWs2 = createMockSocket();

      roomManager.registerAuthenticatedSocket(mockWs1, {
        userId: String(userFacultyA._id),
        sessionId: session1Id,
        collegeId: String(collegeA._id),
        role: AppRole.FACULTY,
        connectedAt: new Date(),
      });

      roomManager.registerAuthenticatedSocket(mockWs2, {
        userId: String(userFacultyA._id),
        sessionId: session2Id,
        collegeId: String(collegeA._id),
        role: AppRole.FACULTY,
        connectedAt: new Date(),
      });

      expect(roomManager.isAuthenticated(mockWs1)).toBe(true);
      expect(roomManager.isAuthenticated(mockWs2)).toBe(true);

      // Revoke only Session 1
      roomManager.revokeSession(session1Id);

      expect(roomManager.isAuthenticated(mockWs1)).toBe(false);
      expect((mockWs1.close as jest.Mock)).toHaveBeenCalled();
      // Session 2 remains open and authenticated
      expect(roomManager.isAuthenticated(mockWs2)).toBe(true);
      expect((mockWs2.close as jest.Mock)).not.toHaveBeenCalled();
    });
  });

  // =========================================================================
  // SECTION 4: SUPER_ADMIN PLATFORM CONTEXT & WORKSPACE SWITCHING
  // =========================================================================
  describe('4. SUPER_ADMIN Platform Context & Bidirectional Switching', () => {
    it('4.1: Super Admin can switch into a college workspace and obtain workspace-bound token', async () => {
      const sessionId = crypto.randomUUID();
      await AuthSession.create({
        userId: userSuperAdmin._id,
        sessionId,
        refreshTokenHash: 'hash123',
        expiresAt: new Date(Date.now() + 86400000),
      });

      const initialToken = signAccessToken({
        userId: String(userSuperAdmin._id),
        role: AppRole.SUPER_ADMIN,
        collegeId: undefined,
        sessionId,
      });

      // Switch into College A
      const res = await request(app)
        .post('/api/v1/workspaces/switch')
        .set('Authorization', `Bearer ${initialToken}`)
        .send({ targetCollegeId: String(collegeA._id) });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.activeWorkspace.workspaceId).toBe(String(collegeA._id));
      expect(res.body.data.accessToken).toBeDefined();
      expect(res.body.data.user.collegeId).toBe(String(collegeA._id));
    });

    it('4.2: Super Admin can switch BACK to platform context without retaining college permissions', async () => {
      const sessionId = crypto.randomUUID();
      await AuthSession.create({
        userId: userSuperAdmin._id,
        sessionId,
        refreshTokenHash: 'hash123',
        expiresAt: new Date(Date.now() + 86400000),
      });

      const collegeToken = signAccessToken({
        userId: String(userSuperAdmin._id),
        role: AppRole.SUPER_ADMIN,
        collegeId: String(collegeA._id),
        sessionId,
      });

      // Switch back to 'platform'
      const res = await request(app)
        .post('/api/v1/workspaces/switch')
        .set('Authorization', `Bearer ${collegeToken}`)
        .send({ targetCollegeId: 'platform' });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.activeWorkspace.isPlatform).toBe(true);
      expect(res.body.data.activeWorkspace.workspaceId).toBe('platform');
      expect(res.body.data.user.collegeId).toBeNull();

      // The new platform token without college context cannot perform college-scoped upload mutation without collegeId
      const platformToken = res.body.data.accessToken;
      const uploadRes = await request(app)
        .post('/api/v1/notes/upload-url')
        .set('Authorization', `Bearer ${platformToken}`)
        .send({
          title: 'Attempt Note Upload Without College Context',
          description: 'Testing tenant isolation',
        });

      // Must be rejected with 400 or 422 because collegeId is missing
      expect([400, 422]).toContain(uploadRes.status);
    });

    it('4.3: Non-Super Admin cannot switch into a college without active membership', async () => {
      const sessionId = crypto.randomUUID();
      await AuthSession.create({
        userId: userFacultyA._id,
        sessionId,
        refreshTokenHash: 'hash123',
        expiresAt: new Date(Date.now() + 86400000),
      });

      const tokenA = signAccessToken({
        userId: String(userFacultyA._id),
        role: AppRole.FACULTY,
        collegeId: String(collegeA._id),
        sessionId,
      });

      // Faculty A attempts to switch to College B without membership
      const res = await request(app)
        .post('/api/v1/workspaces/switch')
        .set('Authorization', `Bearer ${tokenA}`)
        .send({ targetCollegeId: String(collegeB._id) });

      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
      const errMsg = res.body.message || res.body.error?.message;
      expect(errMsg).toMatch(/membership/i);
    });

    it('4.4: Concurrent sessions for same user maintain independent workspace state', async () => {
      // Create membership and role assignment for user in both colleges
      const memA = await WorkspaceMembership.create({
        userId: userFacultyA._id,
        collegeId: collegeA._id,
        status: MembershipStatus.ACTIVE,
      });
      const memB = await WorkspaceMembership.create({
        userId: userFacultyA._id,
        collegeId: collegeB._id,
        status: MembershipStatus.ACTIVE,
      });

      await WorkspaceRoleAssignment.create([
        {
          membershipId: memA._id,
          userId: userFacultyA._id,
          collegeId: collegeA._id,
          role: AppRole.FACULTY,
          status: RoleAssignmentStatus.ACTIVE,
        },
        {
          membershipId: memB._id,
          userId: userFacultyA._id,
          collegeId: collegeB._id,
          role: AppRole.FACULTY,
          status: RoleAssignmentStatus.ACTIVE,
        },
      ]);

      const sessionMobileId = crypto.randomUUID();
      const sessionWebId = crypto.randomUUID();

      await AuthSession.create([
        {
          userId: userFacultyA._id,
          sessionId: sessionMobileId,
          refreshTokenHash: 'hash_mob',
          expiresAt: new Date(Date.now() + 86400000),
        },
        {
          userId: userFacultyA._id,
          sessionId: sessionWebId,
          refreshTokenHash: 'hash_web',
          expiresAt: new Date(Date.now() + 86400000),
        },
      ]);

      const mobileToken = signAccessToken({
        userId: String(userFacultyA._id),
        role: AppRole.FACULTY,
        collegeId: String(collegeA._id),
        sessionId: sessionMobileId,
      });

      const webToken = signAccessToken({
        userId: String(userFacultyA._id),
        role: AppRole.FACULTY,
        collegeId: String(collegeA._id),
        sessionId: sessionWebId,
      });

      // Mobile session switches to College B
      const switchRes = await request(app)
        .post('/api/v1/workspaces/switch')
        .set('Authorization', `Bearer ${mobileToken}`)
        .send({ targetCollegeId: String(collegeB._id) });

      expect(switchRes.status).toBe(200);
      const switchedMobileToken = switchRes.body.data.accessToken;

      // Create Note in College A with full schema
      const courseId = new mongoose.Types.ObjectId();
      const semesterId = new mongoose.Types.ObjectId();
      const subjectId = new mongoose.Types.ObjectId();

      const noteA = await Note.create({
        title: 'Alpha Notes',
        collegeId: collegeA._id,
        departmentId: deptA._id,
        courseId,
        semesterId,
        subjectId,
        authorUserId: userFacultyA._id,
        description: 'Lecture notes for Alpha',
        fileSize: 1024,
        fileExtension: 'pdf',
        mimeType: 'application/pdf',
        fileId: 'file-alpha-123',
        storageKey: 'notes/file-alpha-123.pdf',
        originalFileName: 'alpha_notes.pdf',
        fileUrl: 'https://example.com/a.pdf',
        status: NoteStatus.PUBLISHED,
      });

      // Web token (still in College A) can access noteA
      const webRes = await request(app)
        .get(`/api/v1/notes/${noteA._id}`)
        .set('Authorization', `Bearer ${webToken}`)
        .set('X-Workspace-Id', String(collegeA._id));
      expect([200, 304]).toContain(webRes.status);

      // Switched mobile token operating in College B cannot access Note A
      const mobRes = await request(app)
        .get(`/api/v1/notes/${noteA._id}`)
        .set('Authorization', `Bearer ${switchedMobileToken}`)
        .set('X-Workspace-Id', String(collegeB._id));
      expect([403, 404]).toContain(mobRes.status);
    });
  });

  // =========================================================================
  // SECTION 5: MIGRATION & INDEX SAFETY PREFLIGHT
  // =========================================================================
  describe('5. Migration & Read-Only Index Preflight Safety', () => {
    it('5.1: runIndexPreflight executes without mutations and reports current index status', async () => {
      const preflight = await WorkspaceMigrationService.runIndexPreflight();

      expect(preflight).toBeDefined();
      expect(preflight.collections.faculty).toBeDefined();
      expect(preflight.collections.student).toBeDefined();
      expect(preflight.collections.workspaceMembership).toBeDefined();
      expect(preflight.collections.workspaceRoleAssignment).toBeDefined();

      // Clean test database should have 0 duplicate violations
      expect(preflight.collections.faculty.duplicateCount).toBe(0);
      expect(preflight.collections.student.duplicateCount).toBe(0);
      expect(preflight.canSafelyApplyIndexes).toBe(true);
    });

    it('5.2: Dry-run migration performs 0 writes', async () => {
      // Create user without membership
      await User.create({
        name: 'Unmigrated User',
        email: 'unmigrated@alpha.edu',
        password: 'hashedpassword',
        role: AppRole.FACULTY,
        collegeId: collegeA._id,
        accountStatus: AccountStatus.ACTIVE,
      });

      const countBefore = await WorkspaceMembership.countDocuments();
      const dryRunReport = await WorkspaceMigrationService.runDryRun('test_dryrun_safemode');

      expect(dryRunReport).toBeDefined();
      expect(dryRunReport.totalUsersScanned).toBeGreaterThan(0);

      const countAfter = await WorkspaceMembership.countDocuments();
      expect(countAfter).toBe(countBefore); // Absolutely zero writes!
    });
  });

  // =========================================================================
  // SECTION 7 & 8: MULTI-TENANT ISOLATION & ACTIVE WORKFLOW REGRESSION
  // =========================================================================
  describe('7 & 8. Multi-Tenant Isolation & Active Workflow Protection', () => {
    let tokenA: string;

    beforeEach(async () => {
      await WorkspaceMembership.create([
        { userId: userFacultyA._id, collegeId: collegeA._id, status: MembershipStatus.ACTIVE, isDefault: true },
        { userId: userFacultyB._id, collegeId: collegeB._id, status: MembershipStatus.ACTIVE, isDefault: true },
      ]);

      await WorkspaceRoleAssignment.create([
        {
          membershipId: (await WorkspaceMembership.findOne({ userId: userFacultyA._id }))!._id,
          userId: userFacultyA._id,
          collegeId: collegeA._id,
          role: AppRole.FACULTY,
          status: RoleAssignmentStatus.ACTIVE,
        },
        {
          membershipId: (await WorkspaceMembership.findOne({ userId: userFacultyB._id }))!._id,
          userId: userFacultyB._id,
          collegeId: collegeB._id,
          role: AppRole.FACULTY,
          status: RoleAssignmentStatus.ACTIVE,
        },
      ]);

      tokenA = signAccessToken({
        userId: String(userFacultyA._id),
        role: AppRole.FACULTY,
        collegeId: String(collegeA._id),
      });
    });

    it('7.1: User in College A cannot access or list Notes belonging to College B', async () => {
      // Create note in College B with full schema
      const courseId = new mongoose.Types.ObjectId();
      const semesterId = new mongoose.Types.ObjectId();
      const subjectId = new mongoose.Types.ObjectId();

      const noteB = await Note.create({
        title: 'Confidential Beta Research',
        description: 'Internal exam materials',
        collegeId: collegeB._id,
        departmentId: deptB._id,
        courseId,
        semesterId,
        subjectId,
        authorUserId: userFacultyB._id,
        fileSize: 1024,
        fileExtension: 'pdf',
        mimeType: 'application/pdf',
        fileId: 'file-beta-123',
        storageKey: 'notes/file-beta-123.pdf',
        originalFileName: 'lecture1.pdf',
        fileUrl: 'https://storage.acadex.edu/notes/beta123.pdf',
        status: NoteStatus.PUBLISHED,
      });

      // User A lists notes with College A token
      const listRes = await request(app)
        .get('/api/v1/notes')
        .set('Authorization', `Bearer ${tokenA}`)
        .set('X-Workspace-Id', String(collegeA._id));

      if (listRes.status === 200) {
        const notes = listRes.body.data.items || listRes.body.data.notes || listRes.body.data || [];
        const found = notes.some((n: any) => String(n._id) === String(noteB._id));
        expect(found).toBe(false);
      }

      // User A directly tries to get Note B
      const singleRes = await request(app)
        .get(`/api/v1/notes/${noteB._id}`)
        .set('Authorization', `Bearer ${tokenA}`)
        .set('X-Workspace-Id', String(collegeA._id));

      expect([403, 404]).toContain(singleRes.status);
    });

    it('7.2: Mismatched X-Workspace-Id header and token is strictly rejected', async () => {
      // User A presents token for College A, but tampers header to College B
      const res = await request(app)
        .get('/api/v1/notes')
        .set('Authorization', `Bearer ${tokenA}`)
        .set('X-Workspace-Id', String(collegeB._id));

      expect([400, 403]).toContain(res.status);
      expect(res.body.success).toBe(false);
      const errMsg = res.body.message || res.body.error?.message;
      expect(errMsg).toMatch(/workspace|conflict/i);
    });

    it('8.1: Attendance mutation with mismatched workspace header is rejected fail-closed', async () => {
      // Create session in College A with full schema
      const attSessionA = await AttendanceSession.create({
        collegeId: collegeA._id,
        departmentId: deptA._id,
        courseId: new mongoose.Types.ObjectId(),
        semesterId: new mongoose.Types.ObjectId(),
        sectionId: new mongoose.Types.ObjectId(),
        subjectId: new mongoose.Types.ObjectId(),
        subjectName: 'Computer Architecture',
        facultyId: userFacultyA._id,
        date: new Date(),
        timeSlot: '09:00 - 10:00',
        records: [],
        status: AttendanceSessionStatus.OPEN,
        isSubmitted: false,
        isLocked: false,
        version: 1,
      });

      // Attempt to close or submit attendance using College B header
      const res = await request(app)
        .put(`/api/v1/attendance/sessions/${attSessionA._id}/close`)
        .set('Authorization', `Bearer ${tokenA}`)
        .set('X-Workspace-Id', String(collegeB._id));

      expect([400, 403]).toContain(res.status);
      const errMsg = res.body.message || res.body.error?.message;
      expect(errMsg).toMatch(/workspace|conflict/i);

      // Verify the session remained untouched
      const refreshed = await AttendanceSession.findById(attSessionA._id);
      expect(refreshed?.status).toBe(AttendanceSessionStatus.OPEN);
    });

    it('7.3: Realtime event bus does not cross-broadcast between colleges', async () => {
      const mockWsA = createMockSocket();
      const mockWsB = createMockSocket();

      roomManager.registerAuthenticatedSocket(mockWsA, {
        userId: String(userFacultyA._id),
        collegeId: String(collegeA._id),
        role: AppRole.FACULTY,
        connectedAt: new Date(),
      });

      roomManager.registerAuthenticatedSocket(mockWsB, {
        userId: String(userFacultyB._id),
        collegeId: String(collegeB._id),
        role: AppRole.FACULTY,
        connectedAt: new Date(),
      });

      // Broadcast event strictly scoped to College A
      const envelope: RealtimeEventEnvelope = {
        eventId: 'evt_test_sec_1',
        eventVersion: 1,
        eventType: AcadexEventType.ANNOUNCEMENT_PUBLISHED,
        aggregateType: 'Announcement',
        aggregateId: 'anc_123',
        action: 'PUBLISHED',
        occurredAt: new Date().toISOString(),
        collegeId: String(collegeA._id),
        scope: {
          type: 'college',
          collegeId: String(collegeA._id),
        },
        payload: { title: 'Alpha Only Announcement' },
      };

      const delivered = roomManager.broadcastToRoom(`college:${collegeA._id}`, envelope);

      expect(delivered).toBe(1);
      expect(mockWsA.send).toHaveBeenCalled();
      expect(mockWsB.send).not.toHaveBeenCalled();
    });
  });
});
