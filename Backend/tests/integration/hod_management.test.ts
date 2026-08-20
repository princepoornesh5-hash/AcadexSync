import request from 'supertest';
import { app } from '../../src/app';
import { College } from '../../src/models/college.model';
import { User } from '../../src/models/user.model';
import { Department } from '../../src/models/department.model';
import { Course } from '../../src/models/course.model';
import { Invitation } from '../../src/models/invitation.model';
import { AuditLog } from '../../src/models/auditLog.model';
import { AppRole } from '../../src/constants/roles';
import { AccountStatus, CollegeStatus, DepartmentStatus, InvitationStatus } from '../../src/constants/status';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';
import { PasswordService } from '../../src/services/password.service';

describe('ACADEX Phase 9F.1 — HOD Management Tests', () => {
  let superAdminUser: InstanceType<typeof User>;
  let collegeAdminA: InstanceType<typeof User>;
  let collegeAdminB: InstanceType<typeof User>;
  let studentA: InstanceType<typeof User>;
  let facultyA: InstanceType<typeof User>;

  let collegeA: InstanceType<typeof College>;
  let collegeB: InstanceType<typeof College>;
  let inactiveCollege: InstanceType<typeof College>;

  let deptA1: InstanceType<typeof Department>;
  let deptA2: InstanceType<typeof Department>;
  let deptAInactive: InstanceType<typeof Department>;
  let deptB1: InstanceType<typeof Department>;

  let superAdminHeader: { Authorization: string };
  let collegeAdminAHeader: { Authorization: string };
  let collegeAdminBHeader: { Authorization: string };
  let studentAHeader: { Authorization: string };
  let facultyAHeader: { Authorization: string };

  beforeAll(async () => {
    await setupTestDB();
    await College.init();
    await User.init();
    await Department.init();
    await Course.init();
    await Invitation.init();
    await AuditLog.init();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();

    collegeA = await College.create({
      name: 'Alpha Institute of Technology',
      code: 'ALPHA',
      address: '100 Alpha Road',
      email: 'admin@alpha.edu',
      phone: '+919988776601',
      principal: 'Dr. Alpha Principal',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });

    collegeB = await College.create({
      name: 'Beta Institute of Science',
      code: 'BETA',
      address: '200 Beta Road',
      email: 'admin@beta.edu',
      phone: '+919988776602',
      principal: 'Dr. Beta Principal',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });

    inactiveCollege = await College.create({
      name: 'Gamma Inactive College',
      code: 'GAMMA',
      address: '300 Gamma Road',
      email: 'admin@gamma.edu',
      phone: '+919988776603',
      principal: 'Dr. Gamma Principal',
      status: CollegeStatus.INACTIVE,
      isActive: false,
    });

    deptA1 = await Department.create({
      collegeId: collegeA._id,
      name: 'Computer Science and Engineering',
      code: 'CSE',
      status: DepartmentStatus.ACTIVE,
      isActive: true,
    });

    deptA2 = await Department.create({
      collegeId: collegeA._id,
      name: 'Electronics and Communication Engineering',
      code: 'ECE',
      status: DepartmentStatus.ACTIVE,
      isActive: true,
    });

    deptAInactive = await Department.create({
      collegeId: collegeA._id,
      name: 'Civil Engineering Inactive',
      code: 'CIVIL',
      status: DepartmentStatus.INACTIVE,
      isActive: false,
    });

    deptB1 = await Department.create({
      collegeId: collegeB._id,
      name: 'Mechanical Engineering',
      code: 'ME',
      status: DepartmentStatus.ACTIVE,
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
      instituteId: 'ADMIN-A-01',
      name: 'Admin College A',
      email: 'admin@alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.COLLEGE_ADMIN,
      collegeId: collegeA._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    collegeAdminB = await User.create({
      instituteId: 'ADMIN-B-01',
      name: 'Admin College B',
      email: 'admin@beta.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.COLLEGE_ADMIN,
      collegeId: collegeB._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    facultyA = await User.create({
      instituteId: 'FAC-A-01',
      name: 'Faculty Alpha',
      email: 'faculty@alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.FACULTY,
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    studentA = await User.create({
      instituteId: 'STU-A-01',
      name: 'Student Alpha',
      email: 'student@alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.STUDENT,
      collegeId: collegeA._id,
      departmentId: deptA1._id,
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

    facultyAHeader = createTestAuthHeader({
      userId: facultyA.id,
      instituteId: facultyA.instituteId,
      collegeId: collegeA.id,
      departmentId: deptA1.id,
      role: AppRole.FACULTY,
    });

    studentAHeader = createTestAuthHeader({
      userId: studentA.id,
      instituteId: studentA.instituteId,
      collegeId: collegeA.id,
      departmentId: deptA1.id,
      role: AppRole.STUDENT,
    });
  });

  // =========================================================================
  // 1. HOD PROVISIONING, VALIDATION & ONE-HOD RULE (1 - 15)
  // =========================================================================

  it('1, 8, 9, 10. Super Admin can provision HOD with automatic role, PENDING_ACTIVATION and invitation', async () => {
    const res = await request(app)
      .post('/api/v1/academics/hods')
      .set(superAdminHeader)
      .send({
        departmentId: deptA1.id,
        name: 'Dr. Alan Turing',
        instituteId: 'HOD-CSE-01',
        email: 'alan.turing@alpha.edu',
        phone: '+919876543210',
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.user.role).toBe(AppRole.HOD);
    expect(res.body.data.user.accountStatus).toBe(AccountStatus.PENDING_ACTIVATION);
    expect(res.body.data.user.departmentId).toBe(deptA1.id);
    expect(res.body.data.user.collegeId).toBe(collegeA.id);
    expect(res.body.data.activationCode).toBeDefined();
    expect(res.body.data.invitation.status).toBe(InvitationStatus.PENDING);
  });

  it('2. College Admin can provision HOD in own College', async () => {
    const res = await request(app)
      .post('/api/v1/academics/hods')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA1.id,
        name: 'Dr. Grace Hopper',
        instituteId: 'HOD-CSE-02',
        email: 'grace.hopper@alpha.edu',
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.user.name).toBe('Dr. Grace Hopper');
    expect(res.body.data.user.collegeId).toBe(collegeA.id);
  });

  it('3 & 4. College Admin CANNOT provision HOD in another college', async () => {
    const res = await request(app)
      .post('/api/v1/academics/hods')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptB1.id, // Department in College B
        name: 'Dr. Cross Tenant',
        instituteId: 'HOD-CROSS-01',
        email: 'cross@beta.edu',
      });

    expect(res.status).toBe(400);
    expect(res.body.error.message).toContain('does not belong to your college');
  });

  it('5. Invalid department ID format is rejected safely', async () => {
    const res = await request(app)
      .post('/api/v1/academics/hods')
      .set(superAdminHeader)
      .send({
        departmentId: 'invalid-id-format',
        name: 'Dr. Invalid Dept',
        instituteId: 'HOD-INV-01',
        email: 'invalid@dept.edu',
      });

    expect(res.status).toBe(400);
    expect(res.body.error.message).toContain('Invalid Department ID format');
  });

  it('6. Inactive department rejects HOD provisioning', async () => {
    const res = await request(app)
      .post('/api/v1/academics/hods')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptAInactive.id,
        name: 'Dr. Inactive Dept HOD',
        instituteId: 'HOD-INACT-01',
        email: 'inactive.hod@alpha.edu',
      });

    expect(res.status).toBe(403);
    expect(res.body.error.message).toContain('inactive department');
  });

  it('7. Inactive College rejects HOD provisioning', async () => {
    const inactiveDept = await Department.create({
      collegeId: inactiveCollege._id,
      name: 'Inactive Department',
      code: 'INACTDEPT',
      status: DepartmentStatus.ACTIVE,
      isActive: true,
    });

    const res = await request(app)
      .post('/api/v1/academics/hods')
      .set(superAdminHeader)
      .send({
        departmentId: inactiveDept.id,
        name: 'Dr. Inactive College HOD',
        instituteId: 'HOD-GAMMA-01',
        email: 'gamma.hod@gamma.edu',
      });

    expect(res.status).toBe(403);
    expect(res.body.error.message).toContain('inactive college');
  });

  it('11. Duplicate instituteId is rejected with 409 Conflict', async () => {
    await request(app)
      .post('/api/v1/academics/hods')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA1.id,
        name: 'Dr. First HOD',
        instituteId: 'HOD-DUP-01',
        email: 'first.hod@alpha.edu',
      });

    const res = await request(app)
      .post('/api/v1/academics/hods')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA2.id,
        name: 'Dr. Second HOD',
        instituteId: 'HOD-DUP-01', // Duplicate
        email: 'second.hod@alpha.edu',
      });

    expect(res.status).toBe(409);
    expect(res.body.error.message).toContain('already exists');
  });

  it('12. Duplicate email is rejected with 409 Conflict', async () => {
    await request(app)
      .post('/api/v1/academics/hods')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA1.id,
        name: 'Dr. First HOD',
        instituteId: 'HOD-EM-01',
        email: 'duplicate.email@alpha.edu',
      });

    const res = await request(app)
      .post('/api/v1/academics/hods')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA2.id,
        name: 'Dr. Second HOD',
        instituteId: 'HOD-EM-02',
        email: 'duplicate.email@alpha.edu', // Duplicate
      });

    expect(res.status).toBe(409);
    expect(res.body.error.message).toContain('already exists');
  });

  it('13 & 14. Optional phone works and duplicate phone is rejected', async () => {
    // 13. Optional phone omitted works
    const resNoPhone = await request(app)
      .post('/api/v1/academics/hods')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA1.id,
        name: 'Dr. No Phone HOD',
        instituteId: 'HOD-NOPH-01',
        email: 'nophone@alpha.edu',
      });

    expect(resNoPhone.status).toBe(201);
    expect(resNoPhone.body.data.user.phone).toBeUndefined();

    // With phone
    await request(app)
      .post('/api/v1/academics/hods')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA2.id,
        name: 'Dr. Phone HOD 1',
        instituteId: 'HOD-PH-01',
        email: 'phone1@alpha.edu',
        phone: '+919876500001',
      });

    // 14. Duplicate phone rejected
    const resDupPhone = await request(app)
      .post('/api/v1/academics/hods')
      .set(collegeAdminBHeader)
      .send({
        departmentId: deptB1.id,
        name: 'Dr. Phone HOD 2',
        instituteId: 'HOD-PH-02',
        email: 'phone2@beta.edu',
        phone: '+919876500001', // Duplicate phone
      });

    expect(resDupPhone.status).toBe(409);
    expect(resDupPhone.body.error.message).toContain('already exists');
  });

  it('15. One active HOD per department is strictly enforced (409 Conflict)', async () => {
    // 1st HOD in deptA1
    await request(app)
      .post('/api/v1/academics/hods')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA1.id,
        name: 'Dr. Active HOD 1',
        instituteId: 'HOD-ONE-01',
        email: 'active1@alpha.edu',
      });

    // 2nd HOD in same deptA1 -> must reject
    const res = await request(app)
      .post('/api/v1/academics/hods')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA1.id,
        name: 'Dr. Active HOD 2',
        instituteId: 'HOD-ONE-02',
        email: 'active2@alpha.edu',
      });

    expect(res.status).toBe(409);
    expect(res.body.error.message).toContain('Department already has an active or pending HOD');
  });

  // =========================================================================
  // 2. ACTIVATION & LOGIN FLOW (16 - 19)
  // =========================================================================

  it('16, 17, 18, 19. HOD activates via Phase 9C, logs in, receives role HOD JWT and correct department scope', async () => {
    // 1. Provision
    const provRes = await request(app)
      .post('/api/v1/academics/hods')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA1.id,
        name: 'Dr. Ada Lovelace',
        instituteId: 'HOD-ADA-01',
        email: 'ada.lovelace@alpha.edu',
      });

    const activationCode = provRes.body.data.activationCode;

    // 2. Activate Account
    const actRes = await request(app)
      .post('/api/v1/auth/activate')
      .send({
        collegeCode: 'ALPHA',
        instituteId: 'HOD-ADA-01',
        activationCode,
        password: 'SecureHodPassword123!',
      });

    expect(actRes.status).toBe(200);
    expect(actRes.body.success).toBe(true);

    // 3. Login
    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({
        identifier: 'ada.lovelace@alpha.edu',
        password: 'SecureHodPassword123!',
      });

    expect(loginRes.status).toBe(200);
    expect(loginRes.body.data.user.role).toBe(AppRole.HOD);
    expect(loginRes.body.data.user.departmentId).toBe(deptA1.id);
    expect(loginRes.body.data.accessToken).toBeDefined();

    // Verify Department model has hodId updated
    const updatedDept = await Department.findById(deptA1.id);
    expect(updatedDept?.hodId).toBe(provRes.body.data.user.id);
  });

  // =========================================================================
  // 3. LISTING, SEARCH, RBAC & TENANT SCOPING (20 - 24)
  // =========================================================================

  it('20 & 21. Super Admin lists all HODs; College Admin sees only own College HODs', async () => {
    // Create HOD in College A
    await request(app)
      .post('/api/v1/academics/hods')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA1.id,
        name: 'Dr. College A HOD',
        instituteId: 'HOD-LST-A1',
        email: 'hod.a1@alpha.edu',
      });

    // Create HOD in College B
    await request(app)
      .post('/api/v1/academics/hods')
      .set(collegeAdminBHeader)
      .send({
        departmentId: deptB1.id,
        name: 'Dr. College B HOD',
        instituteId: 'HOD-LST-B1',
        email: 'hod.b1@beta.edu',
      });

    // Super Admin lists all
    const resSuper = await request(app)
      .get('/api/v1/academics/hods')
      .set(superAdminHeader);

    expect(resSuper.status).toBe(200);
    expect(resSuper.body.data.total).toBe(2);

    // College Admin A lists
    const resAdminA = await request(app)
      .get('/api/v1/academics/hods')
      .set(collegeAdminAHeader);

    expect(resAdminA.status).toBe(200);
    expect(resAdminA.body.data.items).toHaveLength(1);
    expect(resAdminA.body.data.items[0].instituteId).toBe('HOD-LST-A1');
  });

  it('22, 23, 24. HOD, Faculty, Student CANNOT access HOD administration list (403 Forbidden)', async () => {
    const provRes = await request(app)
      .post('/api/v1/academics/hods')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA1.id,
        name: 'Dr. Self HOD',
        instituteId: 'HOD-SELF-01',
        email: 'self.hod@alpha.edu',
      });

    const hodAuthHeader = createTestAuthHeader({
      userId: provRes.body.data.user.id,
      instituteId: 'HOD-SELF-01',
      collegeId: collegeA.id,
      departmentId: deptA1.id,
      role: AppRole.HOD,
    });

    // 22. HOD cannot access HOD administration list
    const resHod = await request(app)
      .get('/api/v1/academics/hods')
      .set(hodAuthHeader);
    expect(resHod.status).toBe(403);

    // 23. Faculty cannot access HOD administration list
    const resFac = await request(app)
      .get('/api/v1/academics/hods')
      .set(facultyAHeader);
    expect(resFac.status).toBe(403);

    // 24. Student cannot access HOD administration list
    const resStu = await request(app)
      .get('/api/v1/academics/hods')
      .set(studentAHeader);
    expect(resStu.status).toBe(403);
  });

  // =========================================================================
  // 4. RETRIEVAL & PROFILE UPDATES (25 - 29, 40)
  // =========================================================================

  it('25 & 26 & 40. Get HOD works and cross-tenant retrieval is strictly rejected', async () => {
    const provResA = await request(app)
      .post('/api/v1/academics/hods')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA1.id,
        name: 'Dr. Alpha HOD',
        instituteId: 'HOD-GET-A',
        email: 'get.a@alpha.edu',
      });

    const hodAId = provResA.body.data.user.id;

    // College Admin A can get HOD A
    const resA = await request(app)
      .get(`/api/v1/academics/hods/${hodAId}`)
      .set(collegeAdminAHeader);
    expect(resA.status).toBe(200);
    expect(resA.body.data.name).toBe('Dr. Alpha HOD');

    // College Admin B CANNOT get HOD A
    const resB = await request(app)
      .get(`/api/v1/academics/hods/${hodAId}`)
      .set(collegeAdminBHeader);
    expect(resB.status).toBe(403);
    expect(resB.body.error.message).toContain('Cross-college tenant access is strictly prohibited');
  });

  it('27, 28, 29. HOD profile update works; role, instituteId, departmentId are immutable', async () => {
    const provRes = await request(app)
      .post('/api/v1/academics/hods')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA1.id,
        name: 'Dr. Prof Name',
        instituteId: 'HOD-IMM-01',
        email: 'prof.name@alpha.edu',
      });

    const hodId = provRes.body.data.user.id;

    const updateRes = await request(app)
      .put(`/api/v1/academics/hods/${hodId}`)
      .set(collegeAdminAHeader)
      .send({
        name: 'Dr. Prof Name Updated',
        role: AppRole.SUPER_ADMIN, // Attempt escalation
        instituteId: 'HOD-HACKED-99', // Attempt changing institute ID
        departmentId: deptA2.id, // Attempt changing department directly
        phone: '+919988776655',
      });

    expect(updateRes.status).toBe(200);
    expect(updateRes.body.data.name).toBe('Dr. Prof Name Updated');
    expect(updateRes.body.data.phone).toBe('+919988776655');

    // Verify immutability
    const checkDb = await User.findById(hodId);
    expect(checkDb?.role).toBe(AppRole.HOD);
    expect(checkDb?.instituteId).toBe('HOD-IMM-01');
    expect(checkDb?.departmentId?.toString()).toBe(deptA1.id);
  });

  // =========================================================================
  // 5. DEPARTMENT HOD LOOKUP & TRANSFERS (30 - 34)
  // =========================================================================

  it('30 & 31. Department HOD lookup works for active and empty departments', async () => {
    // 31. Empty department returns 200 with null
    const resEmpty = await request(app)
      .get(`/api/v1/departments/${deptA1.id}/hod`)
      .set(collegeAdminAHeader);

    expect(resEmpty.status).toBe(200);
    expect(resEmpty.body.data).toBeNull();

    // 30. Provision HOD and lookup again
    await request(app)
      .post('/api/v1/academics/hods')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA1.id,
        name: 'Dr. Found HOD',
        instituteId: 'HOD-FND-01',
        email: 'found.hod@alpha.edu',
      });

    const resFound = await request(app)
      .get(`/api/v1/departments/${deptA1.id}/hod`)
      .set(collegeAdminAHeader);

    expect(resFound.status).toBe(200);
    expect(resFound.body.data.instituteId).toBe('HOD-FND-01');
  });

  it('32, 33, 34. HOD transfer works, cross-tenant transfer is rejected, transfer to occupied department is rejected', async () => {
    // 1. Provision HOD in deptA1
    const provRes = await request(app)
      .post('/api/v1/academics/hods')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA1.id,
        name: 'Dr. Transferable HOD',
        instituteId: 'HOD-TRF-01',
        email: 'transferable@alpha.edu',
      });

    const hodId = provRes.body.data.user.id;

    // 33. College Admin A attempts transfer to College B department -> must reject
    const resCross = await request(app)
      .patch(`/api/v1/academics/hods/${hodId}/department`)
      .set(collegeAdminAHeader)
      .send({ departmentId: deptB1.id });

    expect(resCross.status).toBe(403);
    expect(resCross.body.error.message).toContain('another college');

    // 34. Provision another HOD in deptA2
    await request(app)
      .post('/api/v1/academics/hods')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA2.id,
        name: 'Dr. Existing HOD In ECE',
        instituteId: 'HOD-ECE-01',
        email: 'ece.hod@alpha.edu',
      });

    // Transfer HOD 1 to occupied deptA2 -> must reject
    const resOccupied = await request(app)
      .patch(`/api/v1/academics/hods/${hodId}/department`)
      .set(collegeAdminAHeader)
      .send({ departmentId: deptA2.id });

    expect(resOccupied.status).toBe(409);
    expect(resOccupied.body.error.message).toContain('Target department already has an active or pending HOD');

    // Create an empty 3rd department in College A
    const deptA3 = await Department.create({
      collegeId: collegeA._id,
      name: 'Mechanical Engineering Alpha',
      code: 'MECH-A',
      status: DepartmentStatus.ACTIVE,
      isActive: true,
    });

    // 32. Transfer HOD 1 to empty deptA3 -> SUCCESS
    const resSuccess = await request(app)
      .patch(`/api/v1/academics/hods/${hodId}/department`)
      .set(collegeAdminAHeader)
      .send({ departmentId: deptA3.id });

    expect(resSuccess.status).toBe(200);
    expect(resSuccess.body.data.departmentId).toBe(deptA3.id);

    // Verify in database
    const checkDb = await User.findById(hodId);
    expect(checkDb?.departmentId?.toString()).toBe(deptA3.id);

    const checkOldDept = await Department.findById(deptA1.id);
    expect(checkOldDept?.hodId).toBeNull();

    const checkNewDept = await Department.findById(deptA3.id);
    expect(checkNewDept?.hodId).toBe(hodId);
  });

  // =========================================================================
  // 6. SUMMARY ANALYTICS, AUDIT LOGS & SECRETS (35 - 39)
  // =========================================================================

  it('35. HOD summary returns accurate data', async () => {
    const provRes = await request(app)
      .post('/api/v1/academics/hods')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA1.id,
        name: 'Dr. Summary HOD',
        instituteId: 'HOD-SUM-01',
        email: 'summary.hod@alpha.edu',
      });

    const hodId = provRes.body.data.user.id;

    const res = await request(app)
      .get(`/api/v1/academics/hods/${hodId}/summary`)
      .set(collegeAdminAHeader);

    expect(res.status).toBe(200);
    expect(res.body.data.hod.name).toBe('Dr. Summary HOD');
    expect(res.body.data.college.code).toBe('ALPHA');
    expect(res.body.data.department.code).toBe('CSE');
    expect(res.body.data.facultyCount).toBe(1); // facultyA is in deptA1
    expect(res.body.data.studentCount).toBe(1); // studentA is in deptA1
  });

  it('36, 37, 38, 39. Audit logs are generated for HOD provisioning, update, and transfer without exposing secrets', async () => {
    // 1. Provision -> HOD_PROVISIONED
    const provRes = await request(app)
      .post('/api/v1/academics/hods')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA1.id,
        name: 'Dr. Audited HOD',
        instituteId: 'HOD-AUD-01',
        email: 'audited.hod@alpha.edu',
      });

    const hodId = provRes.body.data.user.id;

    // 2. Update -> HOD_UPDATED
    await request(app)
      .put(`/api/v1/academics/hods/${hodId}`)
      .set(collegeAdminAHeader)
      .send({ name: 'Dr. Audited HOD Updated' });

    // 3. Transfer -> HOD_DEPARTMENT_TRANSFERRED
    await request(app)
      .patch(`/api/v1/academics/hods/${hodId}/department`)
      .set(collegeAdminAHeader)
      .send({ departmentId: deptA2.id });

    const logs = await AuditLog.find({ entityId: hodId });
    const actions = logs.map((l) => l.action);

    expect(actions).toContain('HOD_PROVISIONED');
    expect(actions).toContain('HOD_UPDATED');
    expect(actions).toContain('HOD_DEPARTMENT_TRANSFERRED');

    // 39. No secrets exposed
    const serialized = JSON.stringify(logs);
    expect(serialized).not.toContain('password');
    expect(serialized).not.toContain('AdminPass123');
  });
});
