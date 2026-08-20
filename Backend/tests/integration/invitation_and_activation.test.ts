import request from 'supertest';
import { app } from '../../src/app';
import { User } from '../../src/models/user.model';
import { College } from '../../src/models/college.model';
import { Department } from '../../src/models/department.model';
import { Invitation } from '../../src/models/invitation.model';
import { AuditLog } from '../../src/models/auditLog.model';
import { AppRole } from '../../src/constants/roles';
import { AccountStatus, InvitationStatus } from '../../src/constants/status';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';
import { PasswordService } from '../../src/services/password.service';

describe('ACADEX Phase 9C — Secure Invitation + Account Activation Engine Tests', () => {
  let collegeA: InstanceType<typeof College>;
  let collegeB: InstanceType<typeof College>;
  let deptA1: InstanceType<typeof Department>;
  let deptA2: InstanceType<typeof Department>;
  let deptB1: InstanceType<typeof Department>;

  let superAdminUser: InstanceType<typeof User>;
  let collegeAdminA: InstanceType<typeof User>;
  let collegeAdminB: InstanceType<typeof User>;
  let hodA1: InstanceType<typeof User>;
  let studentUser: InstanceType<typeof User>;

  let superAdminHeader: { Authorization: string };
  let collegeAdminAHeader: { Authorization: string };
  let collegeAdminBHeader: { Authorization: string };
  let hodA1Header: { Authorization: string };
  let studentHeader: { Authorization: string };

  beforeAll(async () => {
    await setupTestDB();
    await User.init();
    await College.init();
    await Department.init();
    await Invitation.init();
    await AuditLog.init();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();

    // 1. Create Colleges
    collegeA = await College.create({
      name: 'Alpha Engineering College',
      code: 'SVGP',
      address: '123 Alpha Way',
      email: 'contact@alpha.edu',
      phone: '1112223333',
      principal: 'Dr. Alpha Principal',
    });

    collegeB = await College.create({
      name: 'Beta Technology College',
      code: 'BETA01',
      address: '456 Beta Blvd',
      email: 'contact@beta.edu',
      phone: '4445556666',
      principal: 'Dr. Beta Principal',
    });

    // 2. Create Departments
    deptA1 = await Department.create({
      collegeId: collegeA._id,
      name: 'Computer Science & Engineering',
      code: 'CSE',
    });

    deptA2 = await Department.create({
      collegeId: collegeA._id,
      name: 'Electronics & Communication',
      code: 'ECE',
    });

    deptB1 = await Department.create({
      collegeId: collegeB._id,
      name: 'Mechanical Engineering',
      code: 'MECH',
    });

    // 3. Create Users
    const defaultPasswordHash = await PasswordService.hashPassword('AdminPass123');

    superAdminUser = await User.create({
      instituteId: 'SUP-001',
      name: 'Super Admin',
      email: 'superadmin@acadex.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.SUPER_ADMIN,
      accountStatus: AccountStatus.ACTIVE,
    });

    collegeAdminA = await User.create({
      instituteId: 'ADMIN-SVGP-01',
      name: 'Admin SVGP',
      email: 'admin@svgp.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.COLLEGE_ADMIN,
      collegeId: collegeA._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    collegeAdminB = await User.create({
      instituteId: 'ADMIN-BETA-01',
      name: 'Admin Beta',
      email: 'admin@beta.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.COLLEGE_ADMIN,
      collegeId: collegeB._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    hodA1 = await User.create({
      instituteId: 'HOD-CSE-01',
      name: 'HOD CSE',
      email: 'hod.cse@svgp.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.HOD,
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    studentUser = await User.create({
      instituteId: 'STU-001',
      name: 'Existing Student',
      email: 'student@svgp.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.STUDENT,
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    // Auth headers
    superAdminHeader = createTestAuthHeader({
      userId: superAdminUser.id,
      instituteId: superAdminUser.instituteId,
      role: AppRole.SUPER_ADMIN,
    });

    collegeAdminAHeader = createTestAuthHeader({
      userId: collegeAdminA.id,
      instituteId: collegeAdminA.instituteId,
      collegeId: collegeA.id,
      role: AppRole.COLLEGE_ADMIN,
    });

    collegeAdminBHeader = createTestAuthHeader({
      userId: collegeAdminB.id,
      instituteId: collegeAdminB.instituteId,
      collegeId: collegeB.id,
      role: AppRole.COLLEGE_ADMIN,
    });

    hodA1Header = createTestAuthHeader({
      userId: hodA1.id,
      instituteId: hodA1.instituteId,
      collegeId: collegeA.id,
      departmentId: deptA1.id,
      role: AppRole.HOD,
    });

    studentHeader = createTestAuthHeader({
      userId: studentUser.id,
      instituteId: studentUser.instituteId,
      collegeId: collegeA.id,
      role: AppRole.STUDENT,
    });
  });

  // =========================================================================
  // 1. INVITATION CREATION TESTS (1 - 10)
  // =========================================================================

  it('1. Authorized Super Admin can create College Admin invitation', async () => {
    const res = await request(app)
      .post('/api/v1/auth/invitations')
      .set(superAdminHeader)
      .send({
        name: 'New College Admin',
        instituteId: 'ADM-COL-009',
        email: 'newadmin@alpha.edu',
        role: AppRole.COLLEGE_ADMIN,
        collegeId: collegeA.id,
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.activationCode).toMatch(/^[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$/);
    expect(res.body.data.invitation.status).toBe(InvitationStatus.PENDING);
    expect(res.body.data.user.accountStatus).toBe(AccountStatus.PENDING_ACTIVATION);
    expect(res.body.data.user.instituteId).toBe('ADM-COL-009');
  });

  it('2. Authorized College Admin can create HOD invitation', async () => {
    const res = await request(app)
      .post('/api/v1/auth/invitations')
      .set(collegeAdminAHeader)
      .send({
        name: 'Prof. ECE HOD',
        instituteId: 'HOD-ECE-01',
        email: 'hod.ece@svgp.edu',
        role: AppRole.HOD,
        departmentId: deptA2.id,
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.invitation.collegeId).toBe(collegeA.id);
    expect(res.body.data.invitation.departmentId).toBe(deptA2.id);
  });

  it('3. Unauthorized role (STUDENT) CANNOT create invitation', async () => {
    const res = await request(app)
      .post('/api/v1/auth/invitations')
      .set(studentHeader)
      .send({
        name: 'Rogue Account',
        instituteId: 'ROGUE-001',
        email: 'rogue@svgp.edu',
        role: AppRole.STUDENT,
      });

    expect(res.status).toBe(403);
    expect(res.body.success).toBe(false);
  });

  it('4. College Admin cannot create HOD for another college', async () => {
    const res = await request(app)
      .post('/api/v1/auth/invitations')
      .set(collegeAdminAHeader)
      .send({
        name: 'Cross College HOD',
        instituteId: 'HOD-BETA-02',
        email: 'hod.beta@beta.edu',
        role: AppRole.HOD,
        collegeId: collegeB.id, // trying to provision into College B
        departmentId: deptB1.id,
      });

    expect(res.status).toBe(403);
    expect(res.body.error.message).toContain('College Admin cannot create invitations for another college');
  });

  it('5. HOD cannot create account outside their department scope', async () => {
    const res = await request(app)
      .post('/api/v1/auth/invitations')
      .set(hodA1Header)
      .send({
        name: 'Faculty In ECE',
        instituteId: 'FAC-ECE-99',
        email: 'fac.ece@svgp.edu',
        role: AppRole.FACULTY,
        departmentId: deptA2.id, // HOD A1 belongs to deptA1 (CSE), not deptA2 (ECE)
      });

    expect(res.status).toBe(403);
    expect(res.body.error.message).toContain('HOD cannot create invitations outside their assigned department');
  });

  it('6. Duplicate instituteId is strictly rejected', async () => {
    const res = await request(app)
      .post('/api/v1/auth/invitations')
      .set(collegeAdminAHeader)
      .send({
        name: 'Duplicate Institute ID',
        instituteId: 'HOD-CSE-01', // already exists for hodA1
        email: 'different.email@svgp.edu',
        role: AppRole.FACULTY,
        departmentId: deptA1.id,
      });

    expect(res.status).toBe(409);
    expect(res.body.error.message).toContain('already exists');
  });

  it('7. Duplicate email is strictly rejected', async () => {
    const res = await request(app)
      .post('/api/v1/auth/invitations')
      .set(collegeAdminAHeader)
      .send({
        name: 'Duplicate Email User',
        instituteId: 'NEW-FAC-01',
        email: 'hod.cse@svgp.edu', // already belongs to hodA1
        role: AppRole.FACULTY,
        departmentId: deptA1.id,
      });

    expect(res.status).toBe(409);
    expect(res.body.error.message).toContain('already exists');
  });

  it('8. Optional phone works correctly (student without phone created successfully)', async () => {
    const res = await request(app)
      .post('/api/v1/auth/invitations')
      .set(hodA1Header)
      .send({
        name: 'Student Without Phone',
        instituteId: 'STU-NO-PHONE-01',
        email: 'nophone@svgp.edu',
        phone: null,
        role: AppRole.STUDENT,
        departmentId: deptA1.id,
      });

    expect(res.status).toBe(201);
    expect(res.body.data.user.phone).toBeFalsy();
  });

  it('9 & 10. Raw activation code is NOT stored in MongoDB and invitation is PENDING', async () => {
    const res = await request(app)
      .post('/api/v1/auth/invitations')
      .set(collegeAdminAHeader)
      .send({
        name: 'Hash Verification User',
        instituteId: 'FAC-VERIFY-01',
        email: 'verify@svgp.edu',
        role: AppRole.FACULTY,
        departmentId: deptA1.id,
      });

    const returnedCode = res.body.data.activationCode;
    const invitationId = res.body.data.invitation.id;

    const dbInvitation = await Invitation.findById(invitationId);
    expect(dbInvitation).toBeDefined();
    expect(dbInvitation!.status).toBe(InvitationStatus.PENDING);
    expect(dbInvitation!.codeHash).toBeDefined();
    expect(dbInvitation!.codeHash).not.toBe(returnedCode);
    expect(JSON.stringify(dbInvitation!.toJSON())).not.toContain(returnedCode);
  });

  // =========================================================================
  // 2. ACCOUNT ACTIVATION TESTS (11 - 24)
  // =========================================================================

  it('11, 18, 19, 20, 21, 22, 23, 24. Valid invitation activates account and allows normal login', async () => {
    // 1. Create invitation for new student
    const inviteRes = await request(app)
      .post('/api/v1/auth/invitations')
      .set(hodA1Header)
      .send({
        name: 'Alice Wonder',
        instituteId: 'STU-ALICE-01',
        email: 'alice@svgp.edu',
        role: AppRole.STUDENT,
        departmentId: deptA1.id,
      });

    const rawActivationCode = inviteRes.body.data.activationCode;
    const initialUserId = inviteRes.body.data.user.id;

    // 2. Activate Account
    const activateRes = await request(app)
      .post('/api/v1/auth/activate')
      .send({
        collegeCode: 'SVGP',
        instituteId: 'STU-ALICE-01',
        activationCode: rawActivationCode,
        password: 'AliceStrongPassword123',
      });

    expect(activateRes.status).toBe(200);
    expect(activateRes.body.success).toBe(true);
    expect(activateRes.body.data.user.accountStatus).toBe(AccountStatus.ACTIVE);

    // 21, 22, 23. Preserves same User document, _id, and instituteId (no duplicate user created)
    const activeUser = await User.findOne({ instituteId: 'STU-ALICE-01' });
    expect(activeUser).toBeDefined();
    expect(activeUser!.id).toBe(initialUserId);
    expect(activeUser!.instituteId).toBe('STU-ALICE-01');
    expect(activeUser!.accountStatus).toBe(AccountStatus.ACTIVE);

    // 19. Password is securely hashed with bcrypt
    expect(activeUser!.passwordHash).not.toBe('AliceStrongPassword123');
    expect(activeUser!.passwordHash!.startsWith('$2a$') || activeUser!.passwordHash!.startsWith('$2b$')).toBe(true);

    // 20. User can log in normally after activation
    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({
        identifier: 'alice@svgp.edu',
        password: 'AliceStrongPassword123',
      });

    expect(loginRes.status).toBe(200);
    expect(loginRes.body.data.accessToken).toBeDefined();

    // 24. Activation code CANNOT be reused
    const reuseRes = await request(app)
      .post('/api/v1/auth/activate')
      .send({
        collegeCode: 'SVGP',
        instituteId: 'STU-ALICE-01',
        activationCode: rawActivationCode,
        password: 'AnotherPassword999',
      });

    expect(reuseRes.status).toBe(400);
    expect(reuseRes.body.error.message).toContain('already been activated');
  });

  it('12. Activation fails if wrong college code is provided', async () => {
    const inviteRes = await request(app)
      .post('/api/v1/auth/invitations')
      .set(collegeAdminAHeader)
      .send({
        name: 'Wrong College Student',
        instituteId: 'STU-WRONG-COL-01',
        email: 'wrongcol@svgp.edu',
        role: AppRole.STUDENT,
        departmentId: deptA1.id,
      });

    const rawActivationCode = inviteRes.body.data.activationCode;

    const activateRes = await request(app)
      .post('/api/v1/auth/activate')
      .send({
        collegeCode: 'BETA01', // wrong college code (College B instead of SVGP)
        instituteId: 'STU-WRONG-COL-01',
        activationCode: rawActivationCode,
        password: 'ValidPassword123',
      });

    expect(activateRes.status).toBe(400);
    expect(activateRes.body.error.message).toBe('Invalid activation details');
  });

  it('13. Activation fails if wrong instituteId is provided', async () => {
    const inviteRes = await request(app)
      .post('/api/v1/auth/invitations')
      .set(collegeAdminAHeader)
      .send({
        name: 'Wrong ID Student',
        instituteId: 'STU-RIGHT-ID-01',
        email: 'rightid@svgp.edu',
        role: AppRole.STUDENT,
        departmentId: deptA1.id,
      });

    const rawActivationCode = inviteRes.body.data.activationCode;

    const activateRes = await request(app)
      .post('/api/v1/auth/activate')
      .send({
        collegeCode: 'SVGP',
        instituteId: 'STU-WRONG-ID-99',
        activationCode: rawActivationCode,
        password: 'ValidPassword123',
      });

    expect(activateRes.status).toBe(400);
    expect(activateRes.body.error.message).toBe('Invalid activation details');
  });

  it('14. Invalid activation code is rejected', async () => {
    await request(app)
      .post('/api/v1/auth/invitations')
      .set(collegeAdminAHeader)
      .send({
        name: 'Invalid Code Test User',
        instituteId: 'STU-INV-CODE-01',
        email: 'invcode@svgp.edu',
        role: AppRole.STUDENT,
        departmentId: deptA1.id,
      });

    const activateRes = await request(app)
      .post('/api/v1/auth/activate')
      .send({
        collegeCode: 'SVGP',
        instituteId: 'STU-INV-CODE-01',
        activationCode: 'WRNG-CODE-9999',
        password: 'ValidPassword123',
      });

    expect(activateRes.status).toBe(400);
    expect(activateRes.body.error.message).toBe('Invalid activation code');
  });

  it('15. Expired invitation is rejected', async () => {
    const inviteRes = await request(app)
      .post('/api/v1/auth/invitations')
      .set(collegeAdminAHeader)
      .send({
        name: 'Expired Test User',
        instituteId: 'STU-EXPIRED-01',
        email: 'expired@svgp.edu',
        role: AppRole.STUDENT,
        departmentId: deptA1.id,
      });

    const invitationId = inviteRes.body.data.invitation.id;
    const rawActivationCode = inviteRes.body.data.activationCode;

    // Artificially expire invitation in DB
    await Invitation.findByIdAndUpdate(invitationId, {
      expiresAt: new Date(Date.now() - 60000), // expired 1 minute ago
    });

    const activateRes = await request(app)
      .post('/api/v1/auth/activate')
      .send({
        collegeCode: 'SVGP',
        instituteId: 'STU-EXPIRED-01',
        activationCode: rawActivationCode,
        password: 'ValidPassword123',
      });

    expect(activateRes.status).toBe(400);
    expect(activateRes.body.error.message).toContain('Invitation has expired');
  });

  it('16. Revoked invitation is rejected', async () => {
    const inviteRes = await request(app)
      .post('/api/v1/auth/invitations')
      .set(collegeAdminAHeader)
      .send({
        name: 'Revoked Test User',
        instituteId: 'STU-REVOKED-01',
        email: 'revoked@svgp.edu',
        role: AppRole.STUDENT,
        departmentId: deptA1.id,
      });

    const invitationId = inviteRes.body.data.invitation.id;
    const rawActivationCode = inviteRes.body.data.activationCode;

    // Revoke invitation
    await request(app)
      .post(`/api/v1/auth/invitations/${invitationId}/revoke`)
      .set(collegeAdminAHeader);

    const activateRes = await request(app)
      .post('/api/v1/auth/activate')
      .send({
        collegeCode: 'SVGP',
        instituteId: 'STU-REVOKED-01',
        activationCode: rawActivationCode,
        password: 'ValidPassword123',
      });

    expect(activateRes.status).toBe(400);
    expect(activateRes.body.error.message).toContain('No pending invitation found');
  });

  // =========================================================================
  // 3. REISSUE TESTS (25 - 29)
  // =========================================================================

  it('25, 26, 27, 28. Reissuing invitation invalidates old code and issues new code for same user', async () => {
    const inviteRes = await request(app)
      .post('/api/v1/auth/invitations')
      .set(collegeAdminAHeader)
      .send({
        name: 'Reissue Test User',
        instituteId: 'STU-REISSUE-01',
        email: 'reissue@svgp.edu',
        role: AppRole.STUDENT,
        departmentId: deptA1.id,
      });

    const oldInvitationId = inviteRes.body.data.invitation.id;
    const oldActivationCode = inviteRes.body.data.activationCode;
    const userId = inviteRes.body.data.user.id;

    // Reissue invitation
    const reissueRes = await request(app)
      .post(`/api/v1/auth/invitations/${oldInvitationId}/reissue`)
      .set(collegeAdminAHeader);

    expect(reissueRes.status).toBe(200);
    expect(reissueRes.body.success).toBe(true);
    const newActivationCode = reissueRes.body.data.activationCode;
    expect(newActivationCode).not.toBe(oldActivationCode);

    // 25. Old code fails
    const oldCodeAttempt = await request(app)
      .post('/api/v1/auth/activate')
      .send({
        collegeCode: 'SVGP',
        instituteId: 'STU-REISSUE-01',
        activationCode: oldActivationCode,
        password: 'NewStrongPassword123',
      });
    expect(oldCodeAttempt.status).toBe(400);

    // 26. New code works
    const newCodeAttempt = await request(app)
      .post('/api/v1/auth/activate')
      .send({
        collegeCode: 'SVGP',
        instituteId: 'STU-REISSUE-01',
        activationCode: newActivationCode,
        password: 'NewStrongPassword123',
      });
    expect(newCodeAttempt.status).toBe(200);

    // 27 & 28. Preserved same user, no duplicate created
    const count = await User.countDocuments({ instituteId: 'STU-REISSUE-01' });
    expect(count).toBe(1);
    const dbUser = await User.findOne({ instituteId: 'STU-REISSUE-01' });
    expect(dbUser!.id).toBe(userId);
    expect(dbUser!.accountStatus).toBe(AccountStatus.ACTIVE);
  });

  // =========================================================================
  // 4. REVOCATION TESTS (30 - 32)
  // =========================================================================

  it('30 & 31. Authorized user can revoke, unauthorized user cannot revoke', async () => {
    const inviteRes = await request(app)
      .post('/api/v1/auth/invitations')
      .set(collegeAdminAHeader)
      .send({
        name: 'Revoke Security User',
        instituteId: 'STU-REV-SEC-01',
        email: 'revsec@svgp.edu',
        role: AppRole.STUDENT,
        departmentId: deptA1.id,
      });

    const invitationId = inviteRes.body.data.invitation.id;

    // 31. Unauthorized user (Student) cannot revoke
    const unauthRes = await request(app)
      .post(`/api/v1/auth/invitations/${invitationId}/revoke`)
      .set(studentHeader);
    expect(unauthRes.status).toBe(403);

    // 30. Authorized admin can revoke
    const authRes = await request(app)
      .post(`/api/v1/auth/invitations/${invitationId}/revoke`)
      .set(collegeAdminAHeader);
    expect(authRes.status).toBe(200);

    const revokedDoc = await Invitation.findById(invitationId);
    expect(revokedDoc!.status).toBe(InvitationStatus.REVOKED);
  });

  // =========================================================================
  // 5. TENANT SECURITY TESTS (33 - 35)
  // =========================================================================

  it('33. College A cannot activate College B invitation using College A code', async () => {
    // Create invitation in College B
    const inviteRes = await request(app)
      .post('/api/v1/auth/invitations')
      .set(collegeAdminBHeader)
      .send({
        name: 'College B Student',
        instituteId: 'STU-BETA-001',
        email: 'betastudent@beta.edu',
        role: AppRole.STUDENT,
        departmentId: deptB1.id,
      });

    const rawActivationCode = inviteRes.body.data.activationCode;

    // Attempt activation with College A code -> Must fail
    const crossActivate = await request(app)
      .post('/api/v1/auth/activate')
      .send({
        collegeCode: 'SVGP', // wrong college code for College B student
        instituteId: 'STU-BETA-001',
        activationCode: rawActivationCode,
        password: 'ValidPassword123',
      });

    expect(crossActivate.status).toBe(400);
  });

  it('34. College A admin cannot manage College B invitations', async () => {
    const inviteRes = await request(app)
      .post('/api/v1/auth/invitations')
      .set(collegeAdminBHeader)
      .send({
        name: 'College B Faculty',
        instituteId: 'FAC-BETA-001',
        email: 'facbeta@beta.edu',
        role: AppRole.FACULTY,
        departmentId: deptB1.id,
      });

    const invitationId = inviteRes.body.data.invitation.id;

    // College A admin tries to revoke College B's invitation
    const crossRevoke = await request(app)
      .post(`/api/v1/auth/invitations/${invitationId}/revoke`)
      .set(collegeAdminAHeader);

    expect(crossRevoke.status).toBe(403);
    expect(crossRevoke.body.error.message).toContain('Cannot manage invitations for another college');
  });

  it('35. HOD cannot manage another department invitations', async () => {
    // College Admin creates invitation for Dept A2 (ECE)
    const inviteRes = await request(app)
      .post('/api/v1/auth/invitations')
      .set(collegeAdminAHeader)
      .send({
        name: 'ECE Student',
        instituteId: 'STU-ECE-001',
        email: 'stuece@svgp.edu',
        role: AppRole.STUDENT,
        departmentId: deptA2.id,
      });

    const invitationId = inviteRes.body.data.invitation.id;

    // HOD A1 (CSE) attempts to reissue Dept A2 (ECE) invitation
    const crossDeptReissue = await request(app)
      .post(`/api/v1/auth/invitations/${invitationId}/reissue`)
      .set(hodA1Header);

    expect(crossDeptReissue.status).toBe(403);
    expect(crossDeptReissue.body.error.message).toContain('HOD cannot manage invitations outside their department');
  });

  // =========================================================================
  // 6. AUDIT LOGGING TESTS (36 - 40)
  // =========================================================================

  it('36, 37, 38, 39, 40. Invitation lifecycle events are audited without exposing secrets', async () => {
    // 1. Create invitation -> triggers INVITATION_CREATED
    const createRes = await request(app)
      .post('/api/v1/auth/invitations')
      .set(collegeAdminAHeader)
      .send({
        name: 'Audit Flow User',
        instituteId: 'STU-AUDIT-01',
        email: 'audit@svgp.edu',
        role: AppRole.STUDENT,
        departmentId: deptA1.id,
      });

    const invitationId = createRes.body.data.invitation.id;
    const rawActivationCode = createRes.body.data.activationCode;

    // 2. Reissue invitation -> triggers INVITATION_REISSUED
    const reissueRes = await request(app)
      .post(`/api/v1/auth/invitations/${invitationId}/reissue`)
      .set(collegeAdminAHeader);
    const newInvitationId = reissueRes.body.data.invitation.id;
    const newActivationCode = reissueRes.body.data.activationCode;

    // 3. Revoke invitation -> triggers INVITATION_REVOKED
    await request(app)
      .post(`/api/v1/auth/invitations/${newInvitationId}/revoke`)
      .set(collegeAdminAHeader);

    // 4. Create another invitation for activation
    const forActivate = await request(app)
      .post('/api/v1/auth/invitations')
      .set(collegeAdminAHeader)
      .send({
        name: 'Audit Activate User',
        instituteId: 'STU-AUDIT-02',
        email: 'audit2@svgp.edu',
        role: AppRole.STUDENT,
        departmentId: deptA1.id,
      });

    const activateCode = forActivate.body.data.activationCode;

    // 5. Activate -> triggers ACCOUNT_ACTIVATED
    await request(app)
      .post('/api/v1/auth/activate')
      .send({
        collegeCode: 'SVGP',
        instituteId: 'STU-AUDIT-02',
        activationCode: activateCode,
        password: 'SuperSecureAudit123',
      });

    // Check Audit Logs
    const auditLogs = await AuditLog.find({
      collegeId: collegeA.id,
    });

    const actions = auditLogs.map((l) => l.action);
    expect(actions).toContain('INVITATION_CREATED');
    expect(actions).toContain('INVITATION_REISSUED');
    expect(actions).toContain('INVITATION_REVOKED');
    expect(actions).toContain('ACCOUNT_ACTIVATED');

    // 40. Verify sensitive secrets are NOT present anywhere in audit logs
    const serializedLogs = JSON.stringify(auditLogs);
    expect(serializedLogs).not.toContain(rawActivationCode);
    expect(serializedLogs).not.toContain(newActivationCode);
    expect(serializedLogs).not.toContain(activateCode);
    expect(serializedLogs).not.toContain('SuperSecureAudit123');
  });
});
