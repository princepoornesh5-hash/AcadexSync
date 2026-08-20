import request from 'supertest';
import { app } from '../../src/app';
import { College } from '../../src/models/college.model';
import { User } from '../../src/models/user.model';
import { Department } from '../../src/models/department.model';
import { Invitation } from '../../src/models/invitation.model';
import { AuthSession } from '../../src/models/authSession.model';
import { AuditLog } from '../../src/models/auditLog.model';
import { AppRole } from '../../src/constants/roles';
import { AccountStatus, CollegeStatus } from '../../src/constants/status';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';
import { PasswordService } from '../../src/services/password.service';

describe('ACADEX Phase 9D — Super Admin + College Management Tests', () => {
  let superAdminUser: InstanceType<typeof User>;
  let collegeAdminA: InstanceType<typeof User>;
  let collegeAdminB: InstanceType<typeof User>;
  let studentA: InstanceType<typeof User>;

  let collegeA: InstanceType<typeof College>;
  let collegeB: InstanceType<typeof College>;

  let superAdminHeader: { Authorization: string };
  let collegeAdminAHeader: { Authorization: string };
  let collegeAdminBHeader: { Authorization: string };
  let studentAHeader: { Authorization: string };

  beforeAll(async () => {
    await setupTestDB();
    await College.init();
    await User.init();
    await Department.init();
    await Invitation.init();
    await AuthSession.init();
    await AuditLog.init();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();

    collegeA = await College.create({
      name: 'Alpha Engineering College',
      code: 'SVGP',
      address: '123 Alpha Way',
      email: 'contact@alpha.edu',
      phone: '1112223333',
      principal: 'Dr. Alpha Principal',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });

    collegeB = await College.create({
      name: 'Beta Technology College',
      code: 'BETA01',
      address: '456 Beta Blvd',
      email: 'contact@beta.edu',
      phone: '4445556666',
      principal: 'Dr. Beta Principal',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });

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

    studentA = await User.create({
      instituteId: 'STU-SVGP-01',
      name: 'Student Alpha',
      email: 'student@svgp.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.STUDENT,
      collegeId: collegeA._id,
      accountStatus: AccountStatus.ACTIVE,
    });

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

    studentAHeader = createTestAuthHeader({
      userId: studentA.id,
      instituteId: studentA.instituteId,
      collegeId: collegeA.id,
      role: AppRole.STUDENT,
    });
  });

  // =========================================================================
  // 1. COLLEGE CREATION & VALIDATION (1 - 4)
  // =========================================================================

  it('1 & 4. Super Admin can create college with normalized code', async () => {
    const res = await request(app)
      .post('/api/v1/colleges')
      .set(superAdminHeader)
      .send({
        name: 'Gamma Institute of Science',
        code: '  gamma-01  ', // testing normalization
        address: '789 Gamma Road',
        email: 'info@gamma.edu',
        phone: '7778889999',
        principal: 'Dr. Gamma Principal',
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.code).toBe('GAMMA-01');
    expect(res.body.data.status).toBe(CollegeStatus.ACTIVE);
    expect(res.body.data.isActive).toBe(true);
  });

  it('2. Non-Super Admin (College Admin / Student) CANNOT create college', async () => {
    const resAdmin = await request(app)
      .post('/api/v1/colleges')
      .set(collegeAdminAHeader)
      .send({
        name: 'Rogue College',
        code: 'ROGUE01',
        address: 'Unknown Street',
        email: 'rogue@rogue.edu',
        phone: '1234567890',
        principal: 'Dr. Rogue',
      });

    expect(resAdmin.status).toBe(403);

    const resStudent = await request(app)
      .post('/api/v1/colleges')
      .set(studentAHeader)
      .send({
        name: 'Rogue College 2',
        code: 'ROGUE02',
        address: 'Unknown Street',
        email: 'rogue2@rogue.edu',
        phone: '1234567890',
        principal: 'Dr. Rogue',
      });

    expect(resStudent.status).toBe(403);
  });

  it('3. Duplicate college code is strictly rejected with 409 Conflict', async () => {
    const res = await request(app)
      .post('/api/v1/colleges')
      .set(superAdminHeader)
      .send({
        name: 'Another SVGP College',
        code: 'svgp', // duplicate of SVGP
        address: 'Duplicate Lane',
        email: 'duplicate@svgp.edu',
        phone: '9990001111',
        principal: 'Dr. Duplicate',
      });

    expect(res.status).toBe(409);
    expect(res.body.error.message).toContain('already exists');
  });

  // =========================================================================
  // 2. COLLEGE RETRIEVAL, SEARCH, PAGINATION & SORTING (5 - 10)
  // =========================================================================

  it('5. College can be retrieved by ID for authorized caller', async () => {
    const res = await request(app)
      .get(`/api/v1/colleges/${collegeA.id}`)
      .set(collegeAdminAHeader);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.name).toBe('Alpha Engineering College');
  });

  it('6 & 7. Super Admin can list colleges with pagination', async () => {
    const res = await request(app)
      .get('/api/v1/colleges?page=1&limit=1')
      .set(superAdminHeader);

    expect(res.status).toBe(200);
    expect(res.body.data.items).toHaveLength(1);
    expect(res.body.data.page).toBe(1);
    expect(res.body.data.limit).toBe(1);
    expect(res.body.data.total).toBeGreaterThanOrEqual(2);
    expect(res.body.data.totalPages).toBeGreaterThanOrEqual(2);
  });

  it('8. Search by college name works (case-insensitive)', async () => {
    const res = await request(app)
      .get('/api/v1/colleges?search=alpha')
      .set(superAdminHeader);

    expect(res.status).toBe(200);
    expect(res.body.data.items).toHaveLength(1);
    expect(res.body.data.items[0].code).toBe('SVGP');
  });

  it('9. Search by college code works (case-insensitive)', async () => {
    const res = await request(app)
      .get('/api/v1/colleges?search=beta01')
      .set(superAdminHeader);

    expect(res.status).toBe(200);
    expect(res.body.data.items).toHaveLength(1);
    expect(res.body.data.items[0].name).toBe('Beta Technology College');
  });

  it('10. Safe sorting works (ascending and descending)', async () => {
    const resAsc = await request(app)
      .get('/api/v1/colleges?sortBy=name&sortOrder=asc')
      .set(superAdminHeader);

    expect(resAsc.status).toBe(200);
    expect(resAsc.body.data.items[0].name).toBe('Alpha Engineering College');

    const resDesc = await request(app)
      .get('/api/v1/colleges?sortBy=name&sortOrder=desc')
      .set(superAdminHeader);

    expect(resDesc.status).toBe(200);
    expect(resDesc.body.data.items[0].name).toBe('Beta Technology College');
  });

  // =========================================================================
  // 3. COLLEGE UPDATE & CODE CHANGE (11 - 12)
  // =========================================================================

  it('11. Super Admin can update college details', async () => {
    const res = await request(app)
      .put(`/api/v1/colleges/${collegeA.id}`)
      .set(superAdminHeader)
      .send({
        name: 'Alpha Institute of Advanced Technology',
        principal: 'Dr. New Principal',
      });

    expect(res.status).toBe(200);
    expect(res.body.data.name).toBe('Alpha Institute of Advanced Technology');
    expect(res.body.data.principal).toBe('Dr. New Principal');
  });

  it('12. Non-Super Admin cannot globally update college details', async () => {
    const res = await request(app)
      .put(`/api/v1/colleges/${collegeA.id}`)
      .set(collegeAdminAHeader)
      .send({
        name: 'Hacked College Name',
      });

    expect(res.status).toBe(403);
  });

  // =========================================================================
  // 4. DEACTIVATION, REACTIVATION & SESSION REVOCATION (13 - 16, 29 - 31)
  // =========================================================================

  it('13, 14, 15, 16, 29, 30, 31. Super Admin deactivates/reactivates college and active sessions are revoked', async () => {
    // 1. Normal user logs in when college is ACTIVE
    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({
        identifier: 'student@svgp.edu',
        password: 'AdminPass123',
      });

    expect(loginRes.status).toBe(200);
    const userRefreshToken = loginRes.body.data.refreshToken;

    // 2. Super Admin deactivates college
    const deactRes = await request(app)
      .patch(`/api/v1/colleges/${collegeA.id}/status`)
      .set(superAdminHeader)
      .send({ status: CollegeStatus.INACTIVE });

    expect(deactRes.status).toBe(200);
    expect(deactRes.body.data.status).toBe(CollegeStatus.INACTIVE);
    expect(deactRes.body.data.isActive).toBe(false);

    // 31. Existing user refresh session is revoked
    const refreshRes = await request(app)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: userRefreshToken });

    expect(refreshRes.status).toBe(401);

    // 15. Inactive college rejects normal user login
    const inactiveLoginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({
        identifier: 'student@svgp.edu',
        password: 'AdminPass123',
      });

    expect(inactiveLoginRes.status).toBe(403);
    expect(inactiveLoginRes.body.error.message).toContain('institution is currently inactive');

    // 16. Super Admin can still log in and manage the inactive college
    const superAdminLoginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({
        identifier: 'superadmin@acadex.edu',
        password: 'AdminPass123',
      });

    expect(superAdminLoginRes.status).toBe(200);

    // 29 & 30. Reactivate College
    const reactRes = await request(app)
      .patch(`/api/v1/colleges/${collegeA.id}/status`)
      .set(superAdminHeader)
      .send({ status: CollegeStatus.ACTIVE });

    expect(reactRes.status).toBe(200);
    expect(reactRes.body.data.status).toBe(CollegeStatus.ACTIVE);

    // After reactivation, user can log in normally again
    const postReactivationLogin = await request(app)
      .post('/api/v1/auth/login')
      .send({
        identifier: 'student@svgp.edu',
        password: 'AdminPass123',
      });

    expect(postReactivationLogin.status).toBe(200);
  });

  // =========================================================================
  // 5. TENANT ISOLATION & CROSS-TENANT SECURITY (17 - 18, 25 - 26)
  // =========================================================================

  it('17 & 18. College Admin A CANNOT view or access College B details', async () => {
    const res = await request(app)
      .get(`/api/v1/colleges/${collegeB.id}`)
      .set(collegeAdminAHeader);

    expect(res.status).toBe(403);
    expect(res.body.error.message).toContain('Cross-college access is strictly prohibited');
  });

  it('25 & 26. College Admin cannot create another college or modify their collegeId', async () => {
    const res = await request(app)
      .post('/api/v1/colleges')
      .set(collegeAdminAHeader)
      .send({
        name: 'Unauthorized College',
        code: 'UNAUTH01',
        address: 'Illegal Road',
        email: 'unauth@test.edu',
        phone: '1112223333',
        principal: 'Dr. Illegal',
      });

    expect(res.status).toBe(403);

    // Attempting to access or update College B using College Admin A context
    const crossRes = await request(app)
      .put(`/api/v1/colleges/${collegeB.id}`)
      .set(collegeAdminAHeader)
      .send({ name: 'Hacked Beta College' });

    expect(crossRes.status).toBe(403);

    // Attempting to access or update College A using College Admin B context
    const crossResB = await request(app)
      .put(`/api/v1/colleges/${collegeA.id}`)
      .set(collegeAdminBHeader)
      .send({ name: 'Hacked Alpha College' });

    expect(crossResB.status).toBe(403);
  });

  // =========================================================================
  // 6. COLLEGE ADMIN PROVISIONING & ACTIVATION (19 - 24, 27)
  // =========================================================================

  it('19, 20, 21, 22, 23, 24, 27. Super Admin provisions College Admin, activates, logs in, and lists admins', async () => {
    // 19 & 20 & 21. Super Admin provisions College Admin
    const provRes = await request(app)
      .post(`/api/v1/colleges/${collegeA.id}/admins`)
      .set(superAdminHeader)
      .send({
        name: 'New Administrator',
        instituteId: 'ADM-PROV-01',
        email: 'newadmin@svgp.edu',
      });

    expect(provRes.status).toBe(201);
    expect(provRes.body.success).toBe(true);
    expect(provRes.body.data.user.role).toBe(AppRole.COLLEGE_ADMIN);
    expect(provRes.body.data.user.collegeId).toBe(collegeA.id);

    // 22. Starts as PENDING_ACTIVATION
    expect(provRes.body.data.user.accountStatus).toBe(AccountStatus.PENDING_ACTIVATION);
    const rawActivationCode = provRes.body.data.activationCode;

    // 23. College Admin activates using Phase 9C activation endpoint
    const actRes = await request(app)
      .post('/api/v1/auth/activate')
      .send({
        collegeCode: 'SVGP',
        instituteId: 'ADM-PROV-01',
        activationCode: rawActivationCode,
        password: 'AdminPassword999',
      });

    expect(actRes.status).toBe(200);
    expect(actRes.body.data.user.accountStatus).toBe(AccountStatus.ACTIVE);

    // 24. Activated College Admin logs in
    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({
        identifier: 'newadmin@svgp.edu',
        password: 'AdminPassword999',
      });

    expect(loginRes.status).toBe(200);
    expect(loginRes.body.data.accessToken).toBeDefined();

    // 27. List College Admins for collegeA
    const adminsRes = await request(app)
      .get(`/api/v1/colleges/${collegeA.id}/admins`)
      .set(superAdminHeader);

    expect(adminsRes.status).toBe(200);
    expect(adminsRes.body.data.length).toBeGreaterThanOrEqual(2);

    // Inactive college rejects provisioning new College Admin
    await College.findByIdAndUpdate(collegeA._id, { status: CollegeStatus.INACTIVE, isActive: false });
    const inactiveProvRes = await request(app)
      .post(`/api/v1/colleges/${collegeA.id}/admins`)
      .set(superAdminHeader)
      .send({
        name: 'Blocked Admin',
        instituteId: 'ADM-BLOCKED-01',
        email: 'blocked@svgp.edu',
      });

    expect(inactiveProvRes.status).toBe(403);
    expect(inactiveProvRes.body.error.message).toContain('inactive college');
  });

  // =========================================================================
  // 7. COLLEGE SUMMARY ANALYTICS (28)
  // =========================================================================

  it('28. College summary returns accurate database counts', async () => {
    // Create department in College A
    await Department.create({
      collegeId: collegeA._id,
      name: 'Computer Science',
      code: 'CSE',
    });

    const res = await request(app)
      .get(`/api/v1/colleges/${collegeA.id}/summary`)
      .set(collegeAdminAHeader);

    expect(res.status).toBe(200);
    expect(res.body.data.departmentCount).toBe(1);
    expect(res.body.data.collegeAdminCount).toBe(1);
    expect(res.body.data.studentCount).toBe(1);
    expect(res.body.data.activeUserCount).toBe(2);
  });

  // =========================================================================
  // 8. AUDIT LOGGING & SECURITY (32 - 37)
  // =========================================================================

  it('32, 33, 34, 35, 36, 37. Audit logs are generated and contain zero sensitive secrets', async () => {
    // 1. Create college via API -> COLLEGE_CREATED
    const createRes = await request(app)
      .post('/api/v1/colleges')
      .set(superAdminHeader)
      .send({
        name: 'Delta Institute',
        code: 'DELTA01',
        address: 'Delta Blvd',
        email: 'delta@delta.edu',
        phone: '1234567890',
        principal: 'Dr. Delta',
      });

    const newCollegeId = createRes.body.data.id;

    // 2. Update college via API -> COLLEGE_UPDATED
    await request(app)
      .put(`/api/v1/colleges/${newCollegeId}`)
      .set(superAdminHeader)
      .send({ principal: 'Dr. Updated Delta' });

    // 3. Provision College Admin -> INVITATION_CREATED & COLLEGE_ADMIN_PROVISIONED
    await request(app)
      .post(`/api/v1/colleges/${newCollegeId}/admins`)
      .set(superAdminHeader)
      .send({
        name: 'Delta Admin',
        instituteId: 'ADM-DELTA-01',
        email: 'admin@delta.edu',
      });

    // 4. Update status via API -> COLLEGE_STATUS_CHANGED
    await request(app)
      .patch(`/api/v1/colleges/${newCollegeId}/status`)
      .set(superAdminHeader)
      .send({ status: CollegeStatus.INACTIVE });

    const logs = await AuditLog.find({ collegeId: newCollegeId });
    const actions = logs.map((l) => l.action);

    expect(actions).toContain('COLLEGE_CREATED');
    expect(actions).toContain('COLLEGE_UPDATED');
    expect(actions).toContain('INVITATION_CREATED');
    expect(actions).toContain('COLLEGE_ADMIN_PROVISIONED');
    expect(actions).toContain('COLLEGE_STATUS_CHANGED');

    const serialized = JSON.stringify(logs);
    expect(serialized).not.toContain('password');
    expect(serialized).not.toContain('AdminPass123');
    expect(serialized).not.toContain('AdminPassword999');
  });

  // =========================================================================
  // 9. ERROR HANDLING & EDGE CASES (38 - 40)
  // =========================================================================

  it('38. Invalid College ID format is rejected safely with 400 Bad Request', async () => {
    const res = await request(app)
      .get('/api/v1/colleges/invalid-mongo-id')
      .set(superAdminHeader);

    expect(res.status).toBe(400);
    expect(res.body.error.message).toContain('Invalid College ID format');
  });

  it('39. Unauthenticated request is rejected with 401 Unauthorized', async () => {
    const res = await request(app).get('/api/v1/colleges');
    expect(res.status).toBe(401);
  });
});
