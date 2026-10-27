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
  Faculty,
  Student,
  Subject,
} from '../../src/models';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { PasswordService } from '../../src/services/password.service';
import { WorkspaceCompatibilityService } from '../../src/services/workspaceCompatibility.service';
import { WorkspaceMigrationService } from '../../src/services/migration/workspaceMigration.service';
import { AppRole } from '../../src/constants/roles';
import {
  AccountStatus,
  MembershipStatus,
  RoleAssignmentStatus,
  CollegeStatus,
  TokenType,
} from '../../src/constants/status';
import { signAccessToken, verifyJwtToken } from '../../src/utils/token';
import { env } from '../../src/config/env';

describe('ACADEX PROMPT 3: Membership-Aware Login, JWT Claims & Workspace Switching Regression Suite', () => {
  let collegeA: InstanceType<typeof College>;
  let collegeB: InstanceType<typeof College>;
  let deptA: InstanceType<typeof Department>;
  let deptB: InstanceType<typeof Department>;

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
    await Subject.init();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();
    WorkspaceCompatibilityService.setLegacyFallbackEnabled(true);

    collegeA = await College.create({
      name: 'College Alpha',
      code: 'CLA',
      status: CollegeStatus.ACTIVE,
      isActive: true,
      email: 'contact@collegea.edu',
      phone: '+919876543210',
      address: '123 College St, Alpha City',
      principal: 'Dr. Principal Alpha',
    });

    collegeB = await College.create({
      name: 'College Beta',
      code: 'CLB',
      status: CollegeStatus.ACTIVE,
      isActive: true,
      email: 'contact@collegeb.edu',
      phone: '+919876543211',
      address: '456 Campus Ave, Beta City',
      principal: 'Dr. Principal Beta',
    });

    deptA = await Department.create({
      name: 'Computer Science A',
      code: 'CSA',
      collegeId: collegeA._id,
      isActive: true,
    });

    deptB = await Department.create({
      name: 'Electronics Engineering B',
      code: 'EEB',
      collegeId: collegeB._id,
      isActive: true,
    });
  });

  // ---------------------------------------------------------------------------
  // SCENARIO 1: Legacy Single-Workspace User Login
  // ---------------------------------------------------------------------------
  it('1. A legacy single-workspace user can still log in and access protected routes', async () => {
    const passwordHash = await PasswordService.hashPassword('LegacyPass123');
    const legacyUser = await User.create({
      instituteId: 'LEGACY-001',
      name: 'Legacy User',
      email: 'legacy@alpha.edu',
      passwordHash,
      role: AppRole.FACULTY,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: 'legacy@alpha.edu', password: 'LegacyPass123' });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.accessToken).toBeDefined();
    expect(res.body.data.user.id).toBe(legacyUser.id);
    expect(res.body.data.user.instituteId).toBe('LEGACY-001');
    expect(res.body.data.user.collegeId).toBe(collegeA.id);

    const token = res.body.data.accessToken;
    const meRes = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${token}`);

    expect(meRes.status).toBe(200);
    expect(meRes.body.data.instituteId).toBe('LEGACY-001');
    expect(meRes.body.data.collegeId).toBe(collegeA.id);
    expect(meRes.body.data.role).toBe(AppRole.FACULTY);
  });

  // ---------------------------------------------------------------------------
  // SCENARIO 2: User with Two Valid Memberships Can Select Either Workspace
  // ---------------------------------------------------------------------------
  it('2. A user with two valid memberships can select either workspace at login', async () => {
    const passwordHash = await PasswordService.hashPassword('MultiPass123');
    const multiUser = await User.create({
      instituteId: 'GLOBAL-PIN-002',
      name: 'Multi User',
      email: 'multi@institutions.edu',
      passwordHash,
      role: AppRole.STUDENT,
      accountStatus: AccountStatus.ACTIVE,
    });

    const memA = await WorkspaceMembership.create({
      userId: multiUser._id,
      collegeId: collegeA._id,
      status: MembershipStatus.ACTIVE,
      instituteId: 'PIN-COL-A',
    });
    await WorkspaceRoleAssignment.create({
      membershipId: memA._id,
      userId: multiUser._id,
      collegeId: collegeA._id,
      role: AppRole.STUDENT,
      status: RoleAssignmentStatus.ACTIVE,
    });

    const memB = await WorkspaceMembership.create({
      userId: multiUser._id,
      collegeId: collegeB._id,
      status: MembershipStatus.ACTIVE,
      instituteId: 'PIN-COL-B',
    });
    await WorkspaceRoleAssignment.create({
      membershipId: memB._id,
      userId: multiUser._id,
      collegeId: collegeB._id,
      role: AppRole.FACULTY,
      departmentId: deptB._id,
      status: RoleAssignmentStatus.ACTIVE,
    });

    // Login with preference for College B
    const loginBRes = await request(app)
      .post('/api/v1/auth/login')
      .send({
        identifier: 'multi@institutions.edu',
        password: 'MultiPass123',
        preferredWorkspaceId: collegeB.id,
      });

    expect(loginBRes.status).toBe(200);
    expect(loginBRes.body.data.activeWorkspace.collegeId).toBe(collegeB.id);
    expect(loginBRes.body.data.activeWorkspace.instituteId).toBe('PIN-COL-B');
    expect(loginBRes.body.data.activeWorkspace.role).toBe(AppRole.FACULTY);

    // Login with preference for College A
    const loginARes = await request(app)
      .post('/api/v1/auth/login')
      .send({
        identifier: 'multi@institutions.edu',
        password: 'MultiPass123',
        preferredWorkspaceId: collegeA.id,
      });

    expect(loginARes.status).toBe(200);
    expect(loginARes.body.data.activeWorkspace.collegeId).toBe(collegeA.id);
    expect(loginARes.body.data.activeWorkspace.instituteId).toBe('PIN-COL-A');
    expect(loginARes.body.data.activeWorkspace.role).toBe(AppRole.STUDENT);
  });

  // ---------------------------------------------------------------------------
  // SCENARIO 3: Each Workspace Uses Its Own Institutional PIN Number
  // ---------------------------------------------------------------------------
  it('3. Each workspace uses its own institutional PIN Number in tokens and responses', async () => {
    const passwordHash = await PasswordService.hashPassword('PinPass123');
    const user = await User.create({
      instituteId: 'GLOBAL-PIN-DEFAULT',
      name: 'PIN Verification User',
      email: 'pinuser@test.edu',
      passwordHash,
      role: AppRole.STUDENT,
      accountStatus: AccountStatus.ACTIVE,
    });

    const memA = await WorkspaceMembership.create({
      userId: user._id,
      collegeId: collegeA._id,
      status: MembershipStatus.ACTIVE,
      instituteId: 'ALPHA-PIN-888',
    });
    await WorkspaceRoleAssignment.create({
      membershipId: memA._id,
      userId: user._id,
      collegeId: collegeA._id,
      role: AppRole.STUDENT,
      status: RoleAssignmentStatus.ACTIVE,
    });

    const memB = await WorkspaceMembership.create({
      userId: user._id,
      collegeId: collegeB._id,
      status: MembershipStatus.ACTIVE,
      instituteId: 'BETA-PIN-999',
    });
    await WorkspaceRoleAssignment.create({
      membershipId: memB._id,
      userId: user._id,
      collegeId: collegeB._id,
      role: AppRole.STUDENT,
      status: RoleAssignmentStatus.ACTIVE,
    });

    // Check login into College A resolves ALPHA-PIN-888
    const loginResA = await request(app)
      .post('/api/v1/auth/login')
      .send({
        identifier: 'pinuser@test.edu',
        password: 'PinPass123',
        preferredWorkspaceId: collegeA.id,
      });

    expect(loginResA.status).toBe(200);
    expect(loginResA.body.data.user.instituteId).toBe('ALPHA-PIN-888');

    const tokenClaimsA = verifyJwtToken(loginResA.body.data.accessToken, TokenType.ACCESS, env.JWT_ACCESS_SECRET);
    expect(tokenClaimsA.instituteId).toBe('ALPHA-PIN-888');

    // Switch to College B and verify BETA-PIN-999
    const switchRes = await request(app)
      .post('/api/v1/workspaces/switch')
      .set('Authorization', `Bearer ${loginResA.body.data.accessToken}`)
      .send({ targetCollegeId: collegeB.id });

    expect(switchRes.status).toBe(200);
    expect(switchRes.body.data.activeWorkspace.instituteId).toBe('BETA-PIN-999');
    expect(switchRes.body.data.user.instituteId).toBe('BETA-PIN-999');

    const tokenClaimsB = verifyJwtToken(switchRes.body.data.accessToken, TokenType.ACCESS, env.JWT_ACCESS_SECRET);
    expect(tokenClaimsB.instituteId).toBe('BETA-PIN-999');
  });

  // ---------------------------------------------------------------------------
  // SCENARIO 4: HOD in College A and Faculty in College B Role Scoping
  // ---------------------------------------------------------------------------
  it('4. HOD in College A and Faculty in College B receives the correct role in each workspace', async () => {
    const passwordHash = await PasswordService.hashPassword('HodFacPass123');
    const user = await User.create({
      instituteId: 'HOD-FAC-004',
      name: 'Dual Role Person',
      email: 'dualer@test.edu',
      passwordHash,
      role: AppRole.FACULTY,
      accountStatus: AccountStatus.ACTIVE,
    });

    const memA = await WorkspaceMembership.create({
      userId: user._id,
      collegeId: collegeA._id,
      status: MembershipStatus.ACTIVE,
      instituteId: 'HOD-PIN-A',
    });
    await WorkspaceRoleAssignment.create({
      membershipId: memA._id,
      userId: user._id,
      collegeId: collegeA._id,
      role: AppRole.HOD,
      departmentId: deptA._id,
      status: RoleAssignmentStatus.ACTIVE,
    });

    const memB = await WorkspaceMembership.create({
      userId: user._id,
      collegeId: collegeB._id,
      status: MembershipStatus.ACTIVE,
      instituteId: 'FAC-PIN-B',
    });
    await WorkspaceRoleAssignment.create({
      membershipId: memB._id,
      userId: user._id,
      collegeId: collegeB._id,
      role: AppRole.FACULTY,
      departmentId: deptB._id,
      status: RoleAssignmentStatus.ACTIVE,
    });

    // 1. In College A context: must be HOD
    const resA = await request(app)
      .post('/api/v1/auth/login')
      .send({
        identifier: 'dualer@test.edu',
        password: 'HodFacPass123',
        preferredWorkspaceId: collegeA.id,
      });

    expect(resA.body.data.activeWorkspace.role).toBe(AppRole.HOD);
    expect(resA.body.data.user.role).toBe(AppRole.HOD);

    // 2. Switch to College B: must be FACULTY (not HOD)
    const switchRes = await request(app)
      .post('/api/v1/workspaces/switch')
      .set('Authorization', `Bearer ${resA.body.data.accessToken}`)
      .send({ targetCollegeId: collegeB.id });

    expect(switchRes.status).toBe(200);
    expect(switchRes.body.data.activeWorkspace.role).toBe(AppRole.FACULTY);
    expect(switchRes.body.data.user.role).toBe(AppRole.FACULTY);
  });

  // ---------------------------------------------------------------------------
  // SCENARIO 5: A User Cannot Switch to Another Person's Membership
  // ---------------------------------------------------------------------------
  it("5. A user cannot switch to another person's membership", async () => {
    const passwordHash = await PasswordService.hashPassword('Pass1234');
    const attacker = await User.create({
      instituteId: 'ATTACKER-005',
      name: 'Attacker User',
      email: 'attacker@test.edu',
      passwordHash,
      role: AppRole.STUDENT,
      accountStatus: AccountStatus.ACTIVE,
    });

    const victim = await User.create({
      instituteId: 'VICTIM-005',
      name: 'Victim User',
      email: 'victim@test.edu',
      passwordHash,
      role: AppRole.COLLEGE_ADMIN,
      accountStatus: AccountStatus.ACTIVE,
    });

    const attackerMem = await WorkspaceMembership.create({
      userId: attacker._id,
      collegeId: collegeA._id,
      status: MembershipStatus.ACTIVE,
    });
    await WorkspaceRoleAssignment.create({
      membershipId: attackerMem._id,
      userId: attacker._id,
      collegeId: collegeA._id,
      role: AppRole.STUDENT,
      status: RoleAssignmentStatus.ACTIVE,
    });

    const victimMem = await WorkspaceMembership.create({
      userId: victim._id,
      collegeId: collegeB._id,
      status: MembershipStatus.ACTIVE,
    });
    await WorkspaceRoleAssignment.create({
      membershipId: victimMem._id,
      userId: victim._id,
      collegeId: collegeB._id,
      role: AppRole.COLLEGE_ADMIN,
      status: RoleAssignmentStatus.ACTIVE,
    });

    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: 'attacker@test.edu', password: 'Pass1234' });

    const attackerToken = loginRes.body.data.accessToken;

    // Attacker attempts to switch using targetMembershipId of Victim
    const switchRes = await request(app)
      .post('/api/v1/workspaces/switch')
      .set('Authorization', `Bearer ${attackerToken}`)
      .send({ targetMembershipId: victimMem.id });

    expect(switchRes.status).toBe(403);
    expect(switchRes.body.error.message).toMatch(/Unauthorized access to requested workspace membership/i);
  });

  // ---------------------------------------------------------------------------
  // SCENARIO 6: Inactive or Expired Memberships Cannot Be Selected
  // ---------------------------------------------------------------------------
  it('6. Inactive or expired memberships cannot be selected', async () => {
    const passwordHash = await PasswordService.hashPassword('Pass1234');
    const user = await User.create({
      instituteId: 'INACTIVE-MEM-006',
      name: 'Expired Mem User',
      email: 'expired@test.edu',
      passwordHash,
      role: AppRole.STUDENT,
      accountStatus: AccountStatus.ACTIVE,
    });

    // Active membership in College A
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

    // Expired membership in College B (effectiveEndDate was yesterday)
    const yesterday = new Date(Date.now() - 86400000);
    const twoMonthsAgo = new Date(Date.now() - 60 * 86400000);
    const expiredMemB = await WorkspaceMembership.create({
      userId: user._id,
      collegeId: collegeB._id,
      status: MembershipStatus.ACTIVE,
      effectiveStartDate: twoMonthsAgo,
      effectiveEndDate: yesterday,
    });
    await WorkspaceRoleAssignment.create({
      membershipId: expiredMemB._id,
      userId: user._id,
      collegeId: collegeB._id,
      role: AppRole.FACULTY,
      departmentId: deptB._id,
      status: RoleAssignmentStatus.ACTIVE,
    });

    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: 'expired@test.edu', password: 'Pass1234' });

    const token = loginRes.body.data.accessToken;

    // Attempting to switch to expired membership in College B
    const switchRes = await request(app)
      .post('/api/v1/workspaces/switch')
      .set('Authorization', `Bearer ${token}`)
      .send({ targetCollegeId: collegeB.id });

    expect(switchRes.status).toBe(403);
    expect(switchRes.body.error.message).toMatch(/expired|inactive/i);
  });

  // ---------------------------------------------------------------------------
  // SCENARIO 7: A College A Token Cannot Access College B Data
  // ---------------------------------------------------------------------------
  it('7. A College A token cannot access College B data', async () => {
    const passwordHash = await PasswordService.hashPassword('Pass1234');
    const userA = await User.create({
      instituteId: 'USER-A-007',
      name: 'College A User',
      email: 'usera@collegea.edu',
      passwordHash,
      role: AppRole.COLLEGE_ADMIN,
      collegeId: collegeA._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    const memA = await WorkspaceMembership.create({
      userId: userA._id,
      collegeId: collegeA._id,
      status: MembershipStatus.ACTIVE,
    });
    await WorkspaceRoleAssignment.create({
      membershipId: memA._id,
      userId: userA._id,
      collegeId: collegeA._id,
      role: AppRole.COLLEGE_ADMIN,
      status: RoleAssignmentStatus.ACTIVE,
    });

    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: 'usera@collegea.edu', password: 'Pass1234' });

    const tokenA = loginRes.body.data.accessToken;

    // Attempt to create a department in College B using College A's token
    const crossRes = await request(app)
      .post('/api/v1/departments')
      .set('Authorization', `Bearer ${tokenA}`)
      .send({
        name: 'Infiltrated Department',
        code: 'INF',
        collegeId: collegeB.id,
      });

    expect(crossRes.status).toBe(403);
    expect(crossRes.body.error.message).toMatch(/Cross-college tenant access is strictly prohibited/i);
  });

  // ---------------------------------------------------------------------------
  // SCENARIO 8: Workspace Switching Invalidates / Replaces Context
  // ---------------------------------------------------------------------------
  it('8. Workspace switching replaces the old client workspace context cleanly', async () => {
    const passwordHash = await PasswordService.hashPassword('Pass1234');
    const user = await User.create({
      instituteId: 'SWITCH-CTX-008',
      name: 'Switcher Context User',
      email: 'switchctx@test.edu',
      passwordHash,
      role: AppRole.FACULTY,
      accountStatus: AccountStatus.ACTIVE,
    });

    const memA = await WorkspaceMembership.create({
      userId: user._id,
      collegeId: collegeA._id,
      status: MembershipStatus.ACTIVE,
      instituteId: 'PIN-SW-A',
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
      instituteId: 'PIN-SW-B',
    });
    await WorkspaceRoleAssignment.create({
      membershipId: memB._id,
      userId: user._id,
      collegeId: collegeB._id,
      role: AppRole.HOD,
      departmentId: deptB._id,
      status: RoleAssignmentStatus.ACTIVE,
    });

    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({
        identifier: 'switchctx@test.edu',
        password: 'Pass1234',
        preferredWorkspaceId: collegeA.id,
      });

    const tokenA = loginRes.body.data.accessToken;

    const switchRes = await request(app)
      .post('/api/v1/workspaces/switch')
      .set('Authorization', `Bearer ${tokenA}`)
      .send({ targetCollegeId: collegeB.id });

    expect(switchRes.status).toBe(200);
    const tokenB = switchRes.body.data.accessToken;

    // Verify token B reflects College B and HOD
    const meResB = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${tokenB}`);

    expect(meResB.status).toBe(200);
    expect(meResB.body.data.collegeId).toBe(collegeB.id);
    expect(meResB.body.data.role).toBe(AppRole.HOD);
    expect(meResB.body.data.instituteId).toBe('PIN-SW-B');
  });

  // ---------------------------------------------------------------------------
  // SCENARIO 9: Workspace Data Isolation Across Switches
  // ---------------------------------------------------------------------------
  it('9. Workspace-scoped data does not leak across switches', async () => {
    // Create students in College A and College B
    const studentUserA = await User.create({
      instituteId: 'STU-A-009',
      name: 'Alice Alpha',
      email: 'alice@alpha.edu',
      role: AppRole.STUDENT,
      collegeId: collegeA._id,
      accountStatus: AccountStatus.ACTIVE,
    });
    await Student.create({
      userId: studentUserA._id,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      instituteId: 'STU-A-009',
      name: 'Alice Alpha',
      enrollmentNumber: 'EN-A-001',
    });

    const studentUserB = await User.create({
      instituteId: 'STU-B-009',
      name: 'Bob Beta',
      email: 'bob@beta.edu',
      role: AppRole.STUDENT,
      collegeId: collegeB._id,
      accountStatus: AccountStatus.ACTIVE,
    });
    await Student.create({
      userId: studentUserB._id,
      collegeId: collegeB._id,
      departmentId: deptB._id,
      instituteId: 'STU-B-009',
      name: 'Bob Beta',
      enrollmentNumber: 'EN-B-001',
    });

    const passwordHash = await PasswordService.hashPassword('Pass1234');
    const admin = await User.create({
      instituteId: 'DUAL-ADMIN-009',
      name: 'Dual Admin',
      email: 'dualadmin@test.edu',
      passwordHash,
      role: AppRole.COLLEGE_ADMIN,
      accountStatus: AccountStatus.ACTIVE,
    });

    const memA = await WorkspaceMembership.create({
      userId: admin._id,
      collegeId: collegeA._id,
      status: MembershipStatus.ACTIVE,
    });
    await WorkspaceRoleAssignment.create({
      membershipId: memA._id,
      userId: admin._id,
      collegeId: collegeA._id,
      role: AppRole.COLLEGE_ADMIN,
      status: RoleAssignmentStatus.ACTIVE,
    });

    const memB = await WorkspaceMembership.create({
      userId: admin._id,
      collegeId: collegeB._id,
      status: MembershipStatus.ACTIVE,
    });
    await WorkspaceRoleAssignment.create({
      membershipId: memB._id,
      userId: admin._id,
      collegeId: collegeB._id,
      role: AppRole.COLLEGE_ADMIN,
      status: RoleAssignmentStatus.ACTIVE,
    });

    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({
        identifier: 'dualadmin@test.edu',
        password: 'Pass1234',
        preferredWorkspaceId: collegeA.id,
      });

    const tokenA = loginRes.body.data.accessToken;

    // In College A: querying students returns only Alice, not Bob
    const listResA = await request(app)
      .get('/api/v1/academics/students')
      .set('Authorization', `Bearer ${tokenA}`);

    expect(listResA.status).toBe(200);
    const namesA = listResA.body.data.items.map((i: any) => i.user.name);
    expect(namesA).toContain('Alice Alpha');
    expect(namesA).not.toContain('Bob Beta');

    // Switch to College B
    const switchRes = await request(app)
      .post('/api/v1/workspaces/switch')
      .set('Authorization', `Bearer ${tokenA}`)
      .send({ targetCollegeId: collegeB.id });

    const tokenB = switchRes.body.data.accessToken;

    // In College B: querying students returns only Bob, not Alice
    const listResB = await request(app)
      .get('/api/v1/academics/students')
      .set('Authorization', `Bearer ${tokenB}`);

    expect(listResB.status).toBe(200);
    const namesB = listResB.body.data.items.map((i: any) => i.user.name);
    expect(namesB).toContain('Bob Beta');
    expect(namesB).not.toContain('Alice Alpha');
  });

  // ---------------------------------------------------------------------------
  // SCENARIO 10: Global Super Admin and Institutional Roles Remain Separated
  // ---------------------------------------------------------------------------
  it('10. Global Super Admin and institutional roles remain properly separated', async () => {
    const passwordHash = await PasswordService.hashPassword('SuperAdmin123');
    const superAdmin = await User.create({
      instituteId: 'SUPER-ADMIN-010',
      name: 'Global Super Admin',
      email: 'super@acadex.com',
      passwordHash,
      role: AppRole.SUPER_ADMIN,
      accountStatus: AccountStatus.ACTIVE,
    });

    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: 'super@acadex.com', password: 'SuperAdmin123' });

    expect(loginRes.status).toBe(200);
    expect(loginRes.body.data.user.id).toBe(superAdmin.id);
    expect(loginRes.body.data.user.role).toBe(AppRole.SUPER_ADMIN);
    expect(loginRes.body.data.activeWorkspace).toBeNull();

    const token = loginRes.body.data.accessToken;

    // Super Admin can access colleges without institutional membership
    const collegesRes = await request(app)
      .get('/api/v1/colleges')
      .set('Authorization', `Bearer ${token}`);

    expect(collegesRes.status).toBe(200);
  });

  // ---------------------------------------------------------------------------
  // SCENARIO 11: Legacy Token Handling Follows Documented Compatibility Policy
  // ---------------------------------------------------------------------------
  it('11. Legacy token handling follows the documented compatibility policy', async () => {
    const passwordHash = await PasswordService.hashPassword('Pass1234');
    const legacyUser = await User.create({
      instituteId: 'LEGACY-011',
      name: 'Legacy Compatibility User',
      email: 'legacy11@test.edu',
      passwordHash,
      role: AppRole.FACULTY,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    const sessionId = crypto.randomUUID();
    await AuthSession.create({
      userId: legacyUser._id,
      sessionId,
      refreshTokenHash: 'hash_legacy_011',
      expiresAt: new Date(Date.now() + 3600000),
    });

    // Token minted before membership ID was added
    const legacyToken = signAccessToken({
      userId: legacyUser.id,
      collegeId: collegeA.id,
      role: AppRole.FACULTY,
      sessionId,
    });

    const meRes = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${legacyToken}`);

    expect(meRes.status).toBe(200);
    expect(meRes.body.data.collegeId).toBe(collegeA.id);
    expect(meRes.body.data.role).toBe(AppRole.FACULTY);
  });

  // ---------------------------------------------------------------------------
  // SCENARIO 12: Membership Changes Invalidate Stale Authorisation
  // ---------------------------------------------------------------------------
  it('12. Membership revocation invalidates access token verification', async () => {
    const passwordHash = await PasswordService.hashPassword('Pass1234');
    const user = await User.create({
      instituteId: 'REVOKE-012',
      name: 'Revoked Member User',
      email: 'revoked@test.edu',
      passwordHash,
      role: AppRole.FACULTY,
      accountStatus: AccountStatus.ACTIVE,
    });

    const mem = await WorkspaceMembership.create({
      userId: user._id,
      collegeId: collegeA._id,
      status: MembershipStatus.ACTIVE,
    });
    await WorkspaceRoleAssignment.create({
      membershipId: mem._id,
      userId: user._id,
      collegeId: collegeA._id,
      role: AppRole.FACULTY,
      departmentId: deptA._id,
      status: RoleAssignmentStatus.ACTIVE,
    });

    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: 'revoked@test.edu', password: 'Pass1234' });

    const token = loginRes.body.data.accessToken;

    // Verify token works
    const test1 = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${token}`);
    expect(test1.status).toBe(200);

    // Revoke membership
    mem.status = MembershipStatus.REVOKED;
    await mem.save();

    // Stale token now immediately fails with 403 Forbidden
    const test2 = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${token}`);
    expect(test2.status).toBe(403);
    expect(test2.body.error.message).toMatch(/Workspace membership is revoked/i);
  });

  // ---------------------------------------------------------------------------
  // SCENARIO 13: Refresh Token Workflow with Membership Scoping
  // ---------------------------------------------------------------------------
  it('13. Refresh token preserves membership context and validates membership status', async () => {
    const passwordHash = await PasswordService.hashPassword('Pass1234');
    const user = await User.create({
      instituteId: 'REFRESH-013',
      name: 'Refresh Member User',
      email: 'refresh@test.edu',
      passwordHash,
      role: AppRole.STUDENT,
      accountStatus: AccountStatus.ACTIVE,
    });

    const mem = await WorkspaceMembership.create({
      userId: user._id,
      collegeId: collegeA._id,
      status: MembershipStatus.ACTIVE,
      instituteId: 'PIN-REFRESH-A',
    });
    await WorkspaceRoleAssignment.create({
      membershipId: mem._id,
      userId: user._id,
      collegeId: collegeA._id,
      role: AppRole.STUDENT,
      status: RoleAssignmentStatus.ACTIVE,
    });

    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: 'refresh@test.edu', password: 'Pass1234' });

    const rawRefreshToken = loginRes.body.data.refreshToken;

    const refreshRes = await request(app)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: rawRefreshToken });

    expect(refreshRes.status).toBe(200);
    expect(refreshRes.body.data.accessToken).toBeDefined();
    expect(refreshRes.body.data.user.instituteId).toBe('PIN-REFRESH-A');

    const newAccessToken = refreshRes.body.data.accessToken;
    const meRes = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${newAccessToken}`);

    expect(meRes.status).toBe(200);
    expect(meRes.body.data.instituteId).toBe('PIN-REFRESH-A');
  });

  // ---------------------------------------------------------------------------
  // SCENARIO 14: Tenant Isolation Tests Continue Passing
  // ---------------------------------------------------------------------------
  it('14. Cross-tenant mutation is strictly prohibited', async () => {
    const passwordHash = await PasswordService.hashPassword('Pass1234');
    const adminA = await User.create({
      instituteId: 'ADMIN-A-014',
      name: 'Admin A',
      email: 'admina14@test.edu',
      passwordHash,
      role: AppRole.COLLEGE_ADMIN,
      accountStatus: AccountStatus.ACTIVE,
    });

    const memA = await WorkspaceMembership.create({
      userId: adminA._id,
      collegeId: collegeA._id,
      status: MembershipStatus.ACTIVE,
    });
    await WorkspaceRoleAssignment.create({
      membershipId: memA._id,
      userId: adminA._id,
      collegeId: collegeA._id,
      role: AppRole.COLLEGE_ADMIN,
      status: RoleAssignmentStatus.ACTIVE,
    });

    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: 'admina14@test.edu', password: 'Pass1234' });

    const tokenA = loginRes.body.data.accessToken;

    // Attempting to mutate College B department with College A's admin credentials
    const putRes = await request(app)
      .put(`/api/v1/departments/${deptB.id}`)
      .set('Authorization', `Bearer ${tokenA}`)
      .send({ name: 'Tampered Department Name' });

    expect(putRes.status).toBe(403);
  });

  // ---------------------------------------------------------------------------
  // SCENARIO 15: Migration Dry-Run Remains Read-Only
  // ---------------------------------------------------------------------------
  it('15. Migration dry-run validation remains read-only without modifying database records', async () => {
    const initialUserCount = await User.countDocuments();
    const initialMemCount = await WorkspaceMembership.countDocuments();

    const result = await WorkspaceMigrationService.runDryRun();

    expect(result).toBeDefined();
    expect(result.runId).toBeDefined();
    expect(result.mode).toBe('DRY_RUN');
    expect(result.classifications).toBeDefined();

    // Verify database counts have not changed
    const afterUserCount = await User.countDocuments();
    const afterMemCount = await WorkspaceMembership.countDocuments();
    expect(afterUserCount).toBe(initialUserCount);
    expect(afterMemCount).toBe(initialMemCount);
  });

  // ---------------------------------------------------------------------------
  // SCENARIO 16: Existing Routes Continue Functioning Under Request Context
  // ---------------------------------------------------------------------------
  it('16. Department and course routes continue functioning under the updated request context', async () => {
    const passwordHash = await PasswordService.hashPassword('Pass1234');
    const user = await User.create({
      instituteId: 'FAC-016',
      name: 'Faculty User 16',
      email: 'fac16@alpha.edu',
      passwordHash,
      role: AppRole.FACULTY,
      accountStatus: AccountStatus.ACTIVE,
    });

    const mem = await WorkspaceMembership.create({
      userId: user._id,
      collegeId: collegeA._id,
      status: MembershipStatus.ACTIVE,
      instituteId: 'PIN-FAC-016',
    });
    await WorkspaceRoleAssignment.create({
      membershipId: mem._id,
      userId: user._id,
      collegeId: collegeA._id,
      role: AppRole.FACULTY,
      departmentId: deptA._id,
      status: RoleAssignmentStatus.ACTIVE,
    });

    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: 'fac16@alpha.edu', password: 'Pass1234' });

    const token = loginRes.body.data.accessToken;

    const deptRes = await request(app)
      .get('/api/v1/departments')
      .set('Authorization', `Bearer ${token}`);

    expect(deptRes.status).toBe(200);
    expect(deptRes.body.success).toBe(true);
    expect(Array.isArray(deptRes.body.data.items)).toBe(true);
  });
});
