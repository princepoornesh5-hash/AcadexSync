import request from 'supertest';
import crypto from 'crypto';
import { app } from '../../src/app';
import {
  User,
  College,
  Department,
  AuthSession,
  WorkspaceMembership,
  WorkspaceRoleAssignment,
  Notification,
  AuditLog,
} from '../../src/models';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { PasswordService } from '../../src/services/password.service';
import { AppRole } from '../../src/constants/roles';
import {
  AccountStatus,
  MembershipStatus,
  RoleAssignmentStatus,
  CollegeStatus,
} from '../../src/constants/status';
import { signAccessToken } from '../../src/utils/token';
import {
  NotificationType,
  NotificationCategory,
  NotificationPriority,
  NotificationStatus,
} from '../../src/constants/notification.constants';

describe('Prompt 4 of 5: Workspace Flow, Available Workspaces, and Cross-Workspace Notifications', () => {
  let collegeA: InstanceType<typeof College>;
  let collegeB: InstanceType<typeof College>;
  let collegeC: InstanceType<typeof College>;
  let deptA: InstanceType<typeof Department>;
  let deptB: InstanceType<typeof Department>;

  beforeAll(async () => {
    await setupTestDB();
    await User.init();
    await College.init();
    await WorkspaceMembership.init();
    await WorkspaceRoleAssignment.init();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();

    collegeA = await College.create({
      name: 'Alpha Engineering College',
      code: 'AEC',
      address: '100 Alpha Road',
      email: 'admin@alpha.edu',
      phone: '1112223333',
      principal: 'Dr. Alpha Principal',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });

    collegeB = await College.create({
      name: 'Beta Technology Institute',
      code: 'BTI',
      address: '200 Beta Road',
      email: 'admin@beta.edu',
      phone: '4445556666',
      principal: 'Dr. Beta Principal',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });

    collegeC = await College.create({
      name: 'Gamma Science Academy',
      code: 'GSA',
      address: '300 Gamma Road',
      email: 'admin@gamma.edu',
      phone: '7778889999',
      principal: 'Dr. Gamma Principal',
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
      name: 'Information Technology',
      code: 'IT',
      status: 'active',
      isActive: true,
    });
  });

  describe('Group 1: Available Workspaces API (GET /api/v1/workspaces/my-memberships)', () => {
    it('1. Returns only the authenticated user eligible active memberships', async () => {
      const passwordHash = await PasswordService.hashPassword('Pass1234');
      const user = await User.create({
        instituteId: 'USR-P4-01',
        name: 'Multi Workspace User',
        email: 'multi01@alpha.edu',
        passwordHash,
        role: AppRole.FACULTY,
        accountStatus: AccountStatus.ACTIVE,
      });

      // Membership in College A (ACTIVE)
      const memA = await WorkspaceMembership.create({
        userId: user._id,
        collegeId: collegeA._id,
        status: MembershipStatus.ACTIVE,
        isDefault: true,
      });

      await WorkspaceRoleAssignment.create({
        membershipId: memA._id,
        userId: user._id,
        collegeId: collegeA._id,
        role: AppRole.FACULTY,
        departmentId: deptA._id,
        status: RoleAssignmentStatus.ACTIVE,
      });

      // Membership in College B (ACTIVE)
      const memB = await WorkspaceMembership.create({
        userId: user._id,
        collegeId: collegeB._id,
        status: MembershipStatus.ACTIVE,
        isDefault: false,
      });

      await WorkspaceRoleAssignment.create({
        membershipId: memB._id,
        userId: user._id,
        collegeId: collegeB._id,
        role: AppRole.HOD,
        departmentId: deptB._id,
        status: RoleAssignmentStatus.ACTIVE,
      });

      const sessionId = crypto.randomUUID();
      await AuthSession.create({
        userId: user._id,
        sessionId,
        refreshTokenHash: 'hash_p4_01',
        expiresAt: new Date(Date.now() + 3600000),
      });

      const token = signAccessToken({
        userId: user.id,
        role: AppRole.FACULTY,
        sessionId,
      });

      const res = await request(app)
        .get('/api/v1/workspaces/my-memberships')
        .set('Authorization', `Bearer ${token}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toHaveLength(2);

      const codes = res.body.data.map((d: any) => d.collegeCode);
      expect(codes).toContain('AEC');
      expect(codes).toContain('BTI');

      // AEC has FACULTY, BTI has HOD
      const itemA = res.body.data.find((d: any) => d.collegeCode === 'AEC');
      expect(itemA.roles).toContain(AppRole.FACULTY);
      expect(itemA.isDefault).toBe(true);

      const itemB = res.body.data.find((d: any) => d.collegeCode === 'BTI');
      expect(itemB.roles).toContain(AppRole.HOD);
      expect(itemB.isDefault).toBe(false);
    });

    it('2. Excludes invalid/suspended/revoked memberships from available workspaces', async () => {
      const passwordHash = await PasswordService.hashPassword('Pass1234');
      const user = await User.create({
        instituteId: 'USR-P4-02',
        name: 'Partially Suspended User',
        email: 'suspended_part@alpha.edu',
        passwordHash,
        role: AppRole.STUDENT,
        accountStatus: AccountStatus.ACTIVE,
      });

      // College A: ACTIVE
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

      // College B: SUSPENDED
      const memB = await WorkspaceMembership.create({
        userId: user._id,
        collegeId: collegeB._id,
        status: MembershipStatus.SUSPENDED,
      });

      await WorkspaceRoleAssignment.create({
        membershipId: memB._id,
        userId: user._id,
        collegeId: collegeB._id,
        role: AppRole.STUDENT,
        status: RoleAssignmentStatus.ACTIVE,
      });

      // College C: REVOKED
      await WorkspaceMembership.create({
        userId: user._id,
        collegeId: collegeC._id,
        status: MembershipStatus.REVOKED,
      });

      const sessionId = crypto.randomUUID();
      await AuthSession.create({
        userId: user._id,
        sessionId,
        refreshTokenHash: 'hash_p4_02',
        expiresAt: new Date(Date.now() + 3600000),
      });

      const token = signAccessToken({
        userId: user.id,
        role: AppRole.STUDENT,
        sessionId,
      });

      const res = await request(app)
        .get('/api/v1/workspaces/my-memberships')
        .set('Authorization', `Bearer ${token}`);

      expect(res.status).toBe(200);
      expect(res.body.data).toHaveLength(1);
      expect(res.body.data[0].collegeCode).toBe('AEC');
    });

    it('3. Ignores client-supplied userId and derives identity strictly from authenticated token', async () => {
      const passwordHash = await PasswordService.hashPassword('Pass1234');
      const victim = await User.create({
        instituteId: 'VIC-01',
        name: 'Victim User',
        email: 'victim@alpha.edu',
        passwordHash,
        role: AppRole.COLLEGE_ADMIN,
        accountStatus: AccountStatus.ACTIVE,
      });

      const attacker = await User.create({
        instituteId: 'ATT-01',
        name: 'Attacker User',
        email: 'attacker@alpha.edu',
        passwordHash,
        role: AppRole.STUDENT,
        accountStatus: AccountStatus.ACTIVE,
      });

      // Victim has College A
      const memVictim = await WorkspaceMembership.create({
        userId: victim._id,
        collegeId: collegeA._id,
        status: MembershipStatus.ACTIVE,
      });
      await WorkspaceRoleAssignment.create({
        membershipId: memVictim._id,
        userId: victim._id,
        collegeId: collegeA._id,
        role: AppRole.COLLEGE_ADMIN,
        status: RoleAssignmentStatus.ACTIVE,
      });

      // Attacker has College B only
      const memAttacker = await WorkspaceMembership.create({
        userId: attacker._id,
        collegeId: collegeB._id,
        status: MembershipStatus.ACTIVE,
      });
      await WorkspaceRoleAssignment.create({
        membershipId: memAttacker._id,
        userId: attacker._id,
        collegeId: collegeB._id,
        role: AppRole.STUDENT,
        status: RoleAssignmentStatus.ACTIVE,
      });

      const sessionId = crypto.randomUUID();
      await AuthSession.create({
        userId: attacker._id,
        sessionId,
        refreshTokenHash: 'hash_att_01',
        expiresAt: new Date(Date.now() + 3600000),
      });

      const attackerToken = signAccessToken({
        userId: attacker.id,
        role: AppRole.STUDENT,
        sessionId,
      });

      // Attacker tries to pass victim's userId in query and body
      const res = await request(app)
        .get(`/api/v1/workspaces/my-memberships?userId=${victim.id}`)
        .send({ userId: victim.id })
        .set('Authorization', `Bearer ${attackerToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data).toHaveLength(1);
      // Must only return Attacker's College B, NOT victim's College A
      expect(res.body.data[0].collegeCode).toBe('BTI');
    });

    it('4. Rejects unauthenticated requests to /workspaces/my-memberships', async () => {
      const res = await request(app).get('/api/v1/workspaces/my-memberships');
      expect(res.status).toBe(401);
    });
  });

  describe('Group 2: Workspace Switching Contract (POST /api/v1/workspaces/switch)', () => {
    it('5. Successfully switches workspace from College A to College B for user with active memberships', async () => {
      const passwordHash = await PasswordService.hashPassword('Pass1234');
      const user = await User.create({
        instituteId: 'USR-SW-01',
        name: 'Switching User',
        email: 'switcher@alpha.edu',
        passwordHash,
        role: AppRole.FACULTY,
        accountStatus: AccountStatus.ACTIVE,
      });

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
        departmentId: deptA._id,
        status: RoleAssignmentStatus.ACTIVE,
      });

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
        departmentId: deptB._id,
        status: RoleAssignmentStatus.ACTIVE,
      });

      const sessionId = crypto.randomUUID();
      await AuthSession.create({
        userId: user._id,
        sessionId,
        refreshTokenHash: 'hash_sw_01',
        expiresAt: new Date(Date.now() + 3600000),
      });

      // Starting in College A
      const initialToken = signAccessToken({
        userId: user.id,
        collegeId: collegeA.id,
        role: AppRole.FACULTY,
        sessionId,
      });

      // Execute switch to College B
      const switchRes = await request(app)
        .post('/api/v1/workspaces/switch')
        .set('Authorization', `Bearer ${initialToken}`)
        .send({ targetCollegeId: collegeB.id });

      expect(switchRes.status).toBe(200);
      expect(switchRes.body.success).toBe(true);
      expect(switchRes.body.data.activeWorkspace.workspaceId).toBe(collegeB.id);
      expect(switchRes.body.data.activeWorkspace.collegeCode).toBe('BTI');
      expect(switchRes.body.data.activeWorkspace.roles).toContain(AppRole.HOD);
      expect(switchRes.body.data.user.role).toBe(AppRole.HOD);
      expect(switchRes.body.data.accessToken).toBeDefined();

      const newToken = switchRes.body.data.accessToken;

      // Verify that new token now authorizes operations in College B
      const meRes = await request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', `Bearer ${newToken}`)
        .set('X-Workspace-Id', collegeB.id);

      expect(meRes.status).toBe(200);
      expect(meRes.body.data.collegeId).toBe(collegeB.id);
      expect(meRes.body.data.role).toBe(AppRole.HOD);

      // Verify audit trail captured the switch
      const auditLog = await AuditLog.findOne({
        action: 'WORKSPACE_SWITCHED',
        actorUserId: user.id,
      });
      expect(auditLog).not.toBeNull();
      expect(auditLog?.collegeId?.toString()).toBe(collegeB.id);
    });

    it('6. Rejects switching to an unauthorized college where user has no membership', async () => {
      const passwordHash = await PasswordService.hashPassword('Pass1234');
      const user = await User.create({
        instituteId: 'USR-SW-02',
        name: 'Single College User',
        email: 'single@alpha.edu',
        passwordHash,
        role: AppRole.STUDENT,
        accountStatus: AccountStatus.ACTIVE,
      });

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
        refreshTokenHash: 'hash_sw_02',
        expiresAt: new Date(Date.now() + 3600000),
      });

      const token = signAccessToken({
        userId: user.id,
        role: AppRole.STUDENT,
        collegeId: collegeA.id,
        sessionId,
      });

      // User tries to switch to College B without membership
      const res = await request(app)
        .post('/api/v1/workspaces/switch')
        .set('Authorization', `Bearer ${token}`)
        .send({ targetCollegeId: collegeB.id });

      expect(res.status).toBe(403);
      expect(res.body.error.message).toContain('User does not hold an active membership');
    });

    it('7. Rejects switching to a suspended membership', async () => {
      const passwordHash = await PasswordService.hashPassword('Pass1234');
      const user = await User.create({
        instituteId: 'USR-SW-03',
        name: 'User With Suspended Membership',
        email: 'suspended_ws@alpha.edu',
        passwordHash,
        role: AppRole.STUDENT,
        accountStatus: AccountStatus.ACTIVE,
      });

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

      // Suspended in College B
      await WorkspaceMembership.create({
        userId: user._id,
        collegeId: collegeB._id,
        status: MembershipStatus.SUSPENDED,
      });

      const sessionId = crypto.randomUUID();
      await AuthSession.create({
        userId: user._id,
        sessionId,
        refreshTokenHash: 'hash_sw_03',
        expiresAt: new Date(Date.now() + 3600000),
      });

      const token = signAccessToken({
        userId: user.id,
        role: AppRole.STUDENT,
        collegeId: collegeA.id,
        sessionId,
      });

      const res = await request(app)
        .post('/api/v1/workspaces/switch')
        .set('Authorization', `Bearer ${token}`)
        .send({ targetCollegeId: collegeB.id });

      expect(res.status).toBe(403);
      expect(res.body.error.message).toContain('membership is suspended');
    });

    it('8. SUPER_ADMIN can switch into any valid active college without institutional membership', async () => {
      const passwordHash = await PasswordService.hashPassword('Pass1234');
      const superAdmin = await User.create({
        instituteId: 'SA-SW-01',
        name: 'Platform Super Admin',
        email: 'superadmin_sw@platform.gov',
        passwordHash,
        role: AppRole.SUPER_ADMIN,
        accountStatus: AccountStatus.ACTIVE,
      });

      const sessionId = crypto.randomUUID();
      await AuthSession.create({
        userId: superAdmin._id,
        sessionId,
        refreshTokenHash: 'hash_sa_sw',
        expiresAt: new Date(Date.now() + 3600000),
      });

      const token = signAccessToken({
        userId: superAdmin.id,
        role: AppRole.SUPER_ADMIN,
        sessionId,
      });

      const res = await request(app)
        .post('/api/v1/workspaces/switch')
        .set('Authorization', `Bearer ${token}`)
        .send({ targetCollegeId: collegeB.id });

      expect(res.status).toBe(200);
      expect(res.body.data.activeWorkspace.workspaceId).toBe(collegeB.id);
      expect(res.body.data.activeWorkspace.isPlatform).toBe(true);
      expect(res.body.data.user.role).toBe(AppRole.SUPER_ADMIN);
    });

    it('9. Session revocation blocks workspace switching', async () => {
      const passwordHash = await PasswordService.hashPassword('Pass1234');
      const user = await User.create({
        instituteId: 'USR-SW-04',
        name: 'Revoked Session User',
        email: 'revoked_sw@alpha.edu',
        passwordHash,
        role: AppRole.STUDENT,
        accountStatus: AccountStatus.ACTIVE,
      });

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
      const session = await AuthSession.create({
        userId: user._id,
        sessionId,
        refreshTokenHash: 'hash_sw_rev',
        expiresAt: new Date(Date.now() + 3600000),
      });

      const token = signAccessToken({
        userId: user.id,
        role: AppRole.STUDENT,
        collegeId: collegeA.id,
        sessionId,
      });

      // Revoke session
      session.isRevoked = () => true;
      session.revokedAt = new Date();
      await session.save();

      const res = await request(app)
        .post('/api/v1/workspaces/switch')
        .set('Authorization', `Bearer ${token}`)
        .send({ targetCollegeId: collegeA.id });

      expect(res.status).toBe(401);
      expect(res.body.error.message).toContain('session has been revoked');
    });
  });

  describe('Group 3: Global and Cross-Workspace Notifications', () => {
    it('10. Global notification query (scope=all) returns notifications across colleges for the recipient only', async () => {
      const passwordHash = await PasswordService.hashPassword('Pass1234');
      const user = await User.create({
        instituteId: 'USR-NOTIF-01',
        name: 'Notified User',
        email: 'notif01@alpha.edu',
        passwordHash,
        role: AppRole.STUDENT,
        accountStatus: AccountStatus.ACTIVE,
      });

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

      // Notification 1 from College A
      await Notification.create({
        recipientUserId: user._id,
        collegeId: collegeA._id,
        title: 'Assignment Posted in AEC',
        body: 'Data Structures assignment #1 is live',
        notificationType: NotificationType.ASSIGNMENT_PUBLISHED,
        category: NotificationCategory.ASSIGNMENT,
        priority: NotificationPriority.NORMAL,
        status: NotificationStatus.UNREAD,
        isRead: false,
        idempotencyKey: 'key_p4_notif_1',
      });

      // Notification 2 from College B
      await Notification.create({
        recipientUserId: user._id,
        collegeId: collegeB._id,
        title: 'Attendance Alert in BTI',
        body: 'Low attendance in Operating Systems',
        notificationType: NotificationType.ATTENDANCE_ALERT,
        category: NotificationCategory.ATTENDANCE,
        priority: NotificationPriority.HIGH,
        status: NotificationStatus.UNREAD,
        isRead: false,
        idempotencyKey: 'key_p4_notif_2',
      });

      const sessionId = crypto.randomUUID();
      await AuthSession.create({
        userId: user._id,
        sessionId,
        refreshTokenHash: 'hash_notif_01',
        expiresAt: new Date(Date.now() + 3600000),
      });

      const token = signAccessToken({
        userId: user.id,
        role: AppRole.STUDENT,
        collegeId: collegeA.id,
        sessionId,
      });

      // Query active workspace notifications only (defaults to AEC)
      const resA = await request(app)
        .get('/api/v1/notifications')
        .set('Authorization', `Bearer ${token}`)
        .set('X-Workspace-Id', collegeA.id);

      expect(resA.status).toBe(200);
      expect(resA.body.data.items).toHaveLength(1);
      expect(resA.body.data.items[0].title).toBe('Assignment Posted in AEC');

      // Query global / all notifications across workspaces
      const resAll = await request(app)
        .get('/api/v1/notifications?scope=all')
        .set('Authorization', `Bearer ${token}`)
        .set('X-Workspace-Id', collegeA.id);

      expect(resAll.status).toBe(200);
      expect(resAll.body.data.items).toHaveLength(2);
      const titles = resAll.body.data.items.map((i: any) => i.title);
      expect(titles).toContain('Assignment Posted in AEC');
      expect(titles).toContain('Attendance Alert in BTI');
    });

    it('11. Global notification query cannot expose another user notifications', async () => {
      const passwordHash = await PasswordService.hashPassword('Pass1234');
      const userAlice = await User.create({
        instituteId: 'ALICE-01',
        name: 'Alice User',
        email: 'alice@alpha.edu',
        passwordHash,
        role: AppRole.STUDENT,
        accountStatus: AccountStatus.ACTIVE,
      });

      const userBob = await User.create({
        instituteId: 'BOB-01',
        name: 'Bob User',
        email: 'bob@alpha.edu',
        passwordHash,
        role: AppRole.STUDENT,
        accountStatus: AccountStatus.ACTIVE,
      });

      const memAlice = await WorkspaceMembership.create({
        userId: userAlice._id,
        collegeId: collegeA._id,
        status: MembershipStatus.ACTIVE,
      });
      await WorkspaceRoleAssignment.create({
        membershipId: memAlice._id,
        userId: userAlice._id,
        collegeId: collegeA._id,
        role: AppRole.STUDENT,
        status: RoleAssignmentStatus.ACTIVE,
      });

      // Bob's private notification
      await Notification.create({
        recipientUserId: userBob._id,
        collegeId: collegeA._id,
        title: 'Bob Private Disciplinary Notice',
        body: 'Confidential hearing details',
        notificationType: NotificationType.SYSTEM,
        category: NotificationCategory.SYSTEM,
        priority: NotificationPriority.CRITICAL,
        status: NotificationStatus.UNREAD,
        isRead: false,
      });

      const sessionId = crypto.randomUUID();
      await AuthSession.create({
        userId: userAlice._id,
        sessionId,
        refreshTokenHash: 'hash_alice_01',
        expiresAt: new Date(Date.now() + 3600000),
      });

      const tokenAlice = signAccessToken({
        userId: userAlice.id,
        role: AppRole.STUDENT,
        collegeId: collegeA.id,
        sessionId,
      });

      // Alice queries scope=all
      const res = await request(app)
        .get('/api/v1/notifications?scope=all')
        .set('Authorization', `Bearer ${tokenAlice}`)
        .set('X-Workspace-Id', collegeA.id);

      expect(res.status).toBe(200);
      expect(res.body.data.items).toHaveLength(0); // Cannot see Bob's notice
    });

    it('12. Mark-as-read checks notification ownership and works across workspaces', async () => {
      const passwordHash = await PasswordService.hashPassword('Pass1234');
      const user = await User.create({
        instituteId: 'USR-MARK-01',
        name: 'Read Marker User',
        email: 'marker@alpha.edu',
        passwordHash,
        role: AppRole.STUDENT,
        accountStatus: AccountStatus.ACTIVE,
      });

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

      // Notification originated in College B
      const notifB = await Notification.create({
        recipientUserId: user._id,
        collegeId: collegeB._id,
        title: 'Cross Workspace Alert',
        body: 'Alert from other college',
        notificationType: NotificationType.ANNOUNCEMENT,
        category: NotificationCategory.GENERAL,
        priority: NotificationPriority.NORMAL,
        status: NotificationStatus.UNREAD,
        isRead: false,
      });

      const sessionId = crypto.randomUUID();
      await AuthSession.create({
        userId: user._id,
        sessionId,
        refreshTokenHash: 'hash_marker_01',
        expiresAt: new Date(Date.now() + 3600000),
      });

      // User is currently authenticated in College A
      const token = signAccessToken({
        userId: user.id,
        role: AppRole.STUDENT,
        collegeId: collegeA.id,
        sessionId,
      });

      // User marks notifB (from College B) as read while in College A
      const readRes = await request(app)
        .patch(`/api/v1/notifications/${notifB.id}/read`)
        .set('Authorization', `Bearer ${token}`)
        .set('X-Workspace-Id', collegeA.id);

      expect(readRes.status).toBe(200);
      expect(readRes.body.success).toBe(true);

      const updatedNotif = await Notification.findById(notifB.id);
      expect(updatedNotif?.isRead).toBe(true);
      expect(updatedNotif?.status).toBe(NotificationStatus.READ);
    });

    it('13. User cannot mark another user notification as read', async () => {
      const passwordHash = await PasswordService.hashPassword('Pass1234');
      const userOwner = await User.create({
        instituteId: 'OWNER-01',
        name: 'Owner User',
        email: 'owner@alpha.edu',
        passwordHash,
        role: AppRole.STUDENT,
        accountStatus: AccountStatus.ACTIVE,
      });

      const userAttacker = await User.create({
        instituteId: 'ATTACKER-02',
        name: 'Attacker 02',
        email: 'attacker02@alpha.edu',
        passwordHash,
        role: AppRole.STUDENT,
        accountStatus: AccountStatus.ACTIVE,
      });

      const memOwner = await WorkspaceMembership.create({
        userId: userOwner._id,
        collegeId: collegeA._id,
        status: MembershipStatus.ACTIVE,
      });
      await WorkspaceRoleAssignment.create({
        membershipId: memOwner._id,
        userId: userOwner._id,
        collegeId: collegeA._id,
        role: AppRole.STUDENT,
        status: RoleAssignmentStatus.ACTIVE,
      });

      const memAttacker = await WorkspaceMembership.create({
        userId: userAttacker._id,
        collegeId: collegeA._id,
        status: MembershipStatus.ACTIVE,
      });
      await WorkspaceRoleAssignment.create({
        membershipId: memAttacker._id,
        userId: userAttacker._id,
        collegeId: collegeA._id,
        role: AppRole.STUDENT,
        status: RoleAssignmentStatus.ACTIVE,
      });

      const ownerNotif = await Notification.create({
        recipientUserId: userOwner._id,
        collegeId: collegeA._id,
        title: 'Confidential Notice',
        body: 'Body text',
        notificationType: NotificationType.ANNOUNCEMENT,
        category: NotificationCategory.GENERAL,
        priority: NotificationPriority.NORMAL,
        status: NotificationStatus.UNREAD,
        isRead: false,
      });

      const sessionId = crypto.randomUUID();
      await AuthSession.create({
        userId: userAttacker._id,
        sessionId,
        refreshTokenHash: 'hash_att_02',
        expiresAt: new Date(Date.now() + 3600000),
      });

      const tokenAttacker = signAccessToken({
        userId: userAttacker.id,
        role: AppRole.STUDENT,
        collegeId: collegeA.id,
        sessionId,
      });

      // Attacker tries to mark ownerNotif as read
      const res = await request(app)
        .patch(`/api/v1/notifications/${ownerNotif.id}/read`)
        .set('Authorization', `Bearer ${tokenAttacker}`)
        .set('X-Workspace-Id', collegeA.id);

      expect(res.status).toBe(404);
      expect(res.body.error.message).toContain('Notification not found or access denied');
    });

    it('14. Cross-tenant enumeration of notifications is rejected when filtering by collegeId without membership', async () => {
      const passwordHash = await PasswordService.hashPassword('Pass1234');
      const user = await User.create({
        instituteId: 'USR-ENUM-01',
        name: 'Enumerating User',
        email: 'enum@alpha.edu',
        passwordHash,
        role: AppRole.STUDENT,
        accountStatus: AccountStatus.ACTIVE,
      });

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
        refreshTokenHash: 'hash_enum_01',
        expiresAt: new Date(Date.now() + 3600000),
      });

      const token = signAccessToken({
        userId: user.id,
        role: AppRole.STUDENT,
        collegeId: collegeA.id,
        sessionId,
      });

      // User tries to query notifications specifically targeting College B (where user has NO membership)
      const res = await request(app)
        .get(`/api/v1/notifications?collegeId=${collegeB.id}`)
        .set('Authorization', `Bearer ${token}`)
        .set('X-Workspace-Id', collegeA.id);

      expect(res.status).toBe(403);
      expect(res.body.error.message).toContain('Cross-college tenant access is strictly prohibited');
    });
  });
});
