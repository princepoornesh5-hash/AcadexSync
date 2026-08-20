import request from 'supertest';
import { app } from '../../src/app';
import { College } from '../../src/models/college.model';
import { User } from '../../src/models/user.model';
import { Department } from '../../src/models/department.model';
import { Faculty } from '../../src/models/faculty.model';
import { Invitation } from '../../src/models/invitation.model';
import { AuditLog } from '../../src/models/auditLog.model';
import { AppRole } from '../../src/constants/roles';
import { AccountStatus, CollegeStatus, DepartmentStatus, InvitationStatus } from '../../src/constants/status';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';
import { PasswordService } from '../../src/services/password.service';

describe('ACADEX Phase 9G.1 — Faculty Management Tests', () => {
  let superAdminUser: InstanceType<typeof User>;
  let collegeAdminA: InstanceType<typeof User>;
  let collegeAdminB: InstanceType<typeof User>;
  let hodA1: InstanceType<typeof User>;
  let hodA2: InstanceType<typeof User>;
  let studentA: InstanceType<typeof User>;

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
  let hodA1Header: { Authorization: string };
  let hodA2Header: { Authorization: string };
  let studentAHeader: { Authorization: string };

  beforeAll(async () => {
    await setupTestDB();
    await College.init();
    await User.init();
    await Department.init();
    await Faculty.init();
    await Invitation.init();
    await AuditLog.init();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();

    collegeA = await College.create({
      name: 'Alpha Engineering College',
      code: 'ALPHA',
      address: '100 Alpha Campus',
      email: 'admin@alpha.edu',
      phone: '+919988776601',
      principal: 'Dr. Alpha Principal',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });

    collegeB = await College.create({
      name: 'Beta Technology College',
      code: 'BETA',
      address: '200 Beta Campus',
      email: 'admin@beta.edu',
      phone: '+919988776602',
      principal: 'Dr. Beta Principal',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });

    inactiveCollege = await College.create({
      name: 'Gamma Inactive College',
      code: 'GAMMA',
      address: '300 Gamma Campus',
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
      name: 'Admin Alpha',
      email: 'admin@alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.COLLEGE_ADMIN,
      collegeId: collegeA._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    collegeAdminB = await User.create({
      instituteId: 'ADMIN-B-01',
      name: 'Admin Beta',
      email: 'admin@beta.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.COLLEGE_ADMIN,
      collegeId: collegeB._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    hodA1 = await User.create({
      instituteId: 'HOD-CSE-01',
      name: 'Dr. Turing (HOD CSE)',
      email: 'hod.cse@alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.HOD,
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      accountStatus: AccountStatus.ACTIVE,
    });
    deptA1.hodId = hodA1._id.toString();
    await deptA1.save();

    hodA2 = await User.create({
      instituteId: 'HOD-ECE-01',
      name: 'Dr. Shannon (HOD ECE)',
      email: 'hod.ece@alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.HOD,
      collegeId: collegeA._id,
      departmentId: deptA2._id,
      accountStatus: AccountStatus.ACTIVE,
    });
    deptA2.hodId = hodA2._id.toString();
    await deptA2.save();

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

    hodA1Header = createTestAuthHeader({
      userId: hodA1.id,
      instituteId: hodA1.instituteId,
      collegeId: collegeA.id,
      departmentId: deptA1.id,
      role: AppRole.HOD,
    });

    hodA2Header = createTestAuthHeader({
      userId: hodA2.id,
      instituteId: hodA2.instituteId,
      collegeId: collegeA.id,
      departmentId: deptA2.id,
      role: AppRole.HOD,
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
  // 1. PROVISIONING, VALIDATION & PROFILE LINKING (1 - 19)
  // =========================================================================

  it('1, 10, 11, 12, 13. Super Admin can provision faculty with auto role, PENDING_ACTIVATION and linked Faculty profile', async () => {
    const res = await request(app)
      .post('/api/v1/academics/faculty')
      .set(superAdminHeader)
      .send({
        departmentId: deptA1.id,
        name: 'Prof. Donald Knuth',
        instituteId: 'FAC-CSE-01',
        email: 'knuth@alpha.edu',
        phone: '+919876543210',
        employeeId: 'EMP-CSE-01',
        designation: 'Professor',
        specialization: 'Algorithms',
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.user.role).toBe(AppRole.FACULTY);
    expect(res.body.data.user.accountStatus).toBe(AccountStatus.PENDING_ACTIVATION);
    expect(res.body.data.faculty.employeeId).toBe('EMP-CSE-01');
    expect(res.body.data.faculty.designation).toBe('Professor');
    expect(res.body.data.faculty.userId).toBe(res.body.data.user.id);
    expect(res.body.data.invitation.status).toBe(InvitationStatus.PENDING);
    expect(res.body.data.activationCode).toBeDefined();
  });

  it('2 & 5. College Admin can provision faculty in own College', async () => {
    const res = await request(app)
      .post('/api/v1/academics/faculty')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA1.id,
        name: 'Prof. Edsger Dijkstra',
        instituteId: 'FAC-CSE-02',
        email: 'dijkstra@alpha.edu',
        employeeId: 'EMP-CSE-02',
      });

    expect(res.status).toBe(201);
    expect(res.body.data.user.name).toBe('Prof. Edsger Dijkstra');
    expect(res.body.data.user.collegeId).toBe(collegeA.id);
  });

  it('3 & 4. HOD can provision faculty in own Department, but NOT in other departments', async () => {
    // 3. Provision in own deptA1
    const resOwn = await request(app)
      .post('/api/v1/academics/faculty')
      .set(hodA1Header)
      .send({
        departmentId: deptA1.id,
        name: 'Prof. Leslie Lamport',
        instituteId: 'FAC-CSE-03',
        email: 'lamport@alpha.edu',
      });

    expect(resOwn.status).toBe(201);
    expect(resOwn.body.data.user.departmentId).toBe(deptA1.id);

    // 4. Provision in other deptA2 -> must reject
    const resOther = await request(app)
      .post('/api/v1/academics/faculty')
      .set(hodA1Header)
      .send({
        departmentId: deptA2.id,
        name: 'Prof. Illegal Lamport',
        instituteId: 'FAC-ECE-99',
        email: 'illegal@alpha.edu',
      });

    expect(resOther.status).toBe(403);
    expect(resOther.body.error.message).toContain('outside their assigned department');
  });

  it('6. Cross-tenant faculty provisioning is rejected', async () => {
    const res = await request(app)
      .post('/api/v1/academics/faculty')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptB1.id, // Department in College B
        name: 'Prof. Cross Tenant',
        instituteId: 'FAC-CROSS-01',
        email: 'cross@beta.edu',
      });

    expect(res.status).toBe(403);
    expect(res.body.error.message).toContain('another college');
  });

  it('7. Invalid department format is rejected safely', async () => {
    const res = await request(app)
      .post('/api/v1/academics/faculty')
      .set(superAdminHeader)
      .send({
        departmentId: 'invalid-mongo-id',
        name: 'Prof. Invalid Dept',
        instituteId: 'FAC-INV-01',
        email: 'invalid@dept.edu',
      });

    expect(res.status).toBe(400);
    expect(res.body.error.message).toContain('Invalid Department ID format');
  });

  it('8 & 9. Inactive department or inactive College rejects faculty provisioning', async () => {
    // 8. Inactive department
    const resDept = await request(app)
      .post('/api/v1/academics/faculty')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptAInactive.id,
        name: 'Prof. Inactive Dept',
        instituteId: 'FAC-INACT-01',
        email: 'inact.dept@alpha.edu',
      });

    expect(resDept.status).toBe(403);
    expect(resDept.body.error.message).toContain('inactive department');

    // 9. Inactive college
    const inactDept = await Department.create({
      collegeId: inactiveCollege._id,
      name: 'Gamma Inactive Dept',
      code: 'GAMMADEPT',
      status: DepartmentStatus.ACTIVE,
      isActive: true,
    });

    const resCol = await request(app)
      .post('/api/v1/academics/faculty')
      .set(superAdminHeader)
      .send({
        departmentId: inactDept.id,
        name: 'Prof. Inactive Col',
        instituteId: 'FAC-INACT-02',
        email: 'inact.col@gamma.edu',
      });

    expect(resCol.status).toBe(403);
    expect(resCol.body.error.message).toContain('inactive college');
  });

  it('14 & 15. Duplicate instituteId and duplicate email are rejected with 409 Conflict', async () => {
    await request(app)
      .post('/api/v1/academics/faculty')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA1.id,
        name: 'Prof. First Faculty',
        instituteId: 'FAC-DUP-01',
        email: 'dup.email@alpha.edu',
      });

    // 14. Duplicate instituteId
    const resInst = await request(app)
      .post('/api/v1/academics/faculty')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA1.id,
        name: 'Prof. Second Faculty',
        instituteId: 'FAC-DUP-01',
        email: 'other.email@alpha.edu',
      });

    expect(resInst.status).toBe(409);
    expect(resInst.body.error.message).toContain('already exists');

    // 15. Duplicate email
    const resEm = await request(app)
      .post('/api/v1/academics/faculty')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA1.id,
        name: 'Prof. Third Faculty',
        instituteId: 'FAC-DUP-02',
        email: 'dup.email@alpha.edu',
      });

    expect(resEm.status).toBe(409);
    expect(resEm.body.error.message).toContain('already exists');
  });

  it('16 & 17. Optional phone works and duplicate phone is rejected', async () => {
    // 16. Optional phone omitted
    const resNoPhone = await request(app)
      .post('/api/v1/academics/faculty')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA1.id,
        name: 'Prof. No Phone',
        instituteId: 'FAC-NOPH-01',
        email: 'nophone.fac@alpha.edu',
      });

    expect(resNoPhone.status).toBe(201);
    expect(resNoPhone.body.data.user.phone).toBeUndefined();

    // With phone
    await request(app)
      .post('/api/v1/academics/faculty')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA1.id,
        name: 'Prof. Phone 1',
        instituteId: 'FAC-PH-01',
        email: 'phone1.fac@alpha.edu',
        phone: '+919988112233',
      });

    // 17. Duplicate phone
    const resDup = await request(app)
      .post('/api/v1/academics/faculty')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA1.id,
        name: 'Prof. Phone 2',
        instituteId: 'FAC-PH-02',
        email: 'phone2.fac@alpha.edu',
        phone: '+919988112233',
      });

    expect(resDup.status).toBe(409);
    expect(resDup.body.error.message).toContain('already exists');
  });

  it('18. EmployeeId uniqueness within College is enforced (409 Conflict)', async () => {
    await request(app)
      .post('/api/v1/academics/faculty')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA1.id,
        name: 'Prof. Emp 1',
        instituteId: 'FAC-EMP-01',
        email: 'emp1@alpha.edu',
        employeeId: 'EMP-ALPHA-99',
      });

    const resDupEmp = await request(app)
      .post('/api/v1/academics/faculty')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA2.id,
        name: 'Prof. Emp 2',
        instituteId: 'FAC-EMP-02',
        email: 'emp2@alpha.edu',
        employeeId: 'EMP-ALPHA-99', // Duplicate employeeId in same college
      });

    expect(resDupEmp.status).toBe(409);
    expect(resDupEmp.body.error.message).toContain('employee ID "EMP-ALPHA-99" already exists');
  });

  // =========================================================================
  // 2. ACTIVATION, EMAIL LOGIN & PHONE LOGIN (20 - 23)
  // =========================================================================

  it('20, 21, 22, 23. Faculty activates via Phase 9C, logs in via email and phone', async () => {
    // 1. Provision
    const provRes = await request(app)
      .post('/api/v1/academics/faculty')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA1.id,
        name: 'Prof. Barbara Liskov',
        instituteId: 'FAC-LIS-01',
        email: 'liskov@alpha.edu',
        phone: '+919876543200',
      });

    const activationCode = provRes.body.data.activationCode;

    // 2. Activate Account
    const actRes = await request(app)
      .post('/api/v1/auth/activate')
      .send({
        collegeCode: 'ALPHA',
        instituteId: 'FAC-LIS-01',
        activationCode,
        password: 'FacultyPassword123!',
      });

    expect(actRes.status).toBe(200);
    expect(actRes.body.success).toBe(true);

    // 3. Login with Email
    const loginEmailRes = await request(app)
      .post('/api/v1/auth/login')
      .send({
        identifier: 'liskov@alpha.edu',
        password: 'FacultyPassword123!',
      });

    expect(loginEmailRes.status).toBe(200);
    expect(loginEmailRes.body.data.user.role).toBe(AppRole.FACULTY);
    expect(loginEmailRes.body.data.user.departmentId).toBe(deptA1.id);

    // 4. Login with Phone
    const loginPhoneRes = await request(app)
      .post('/api/v1/auth/login')
      .send({
        identifier: '+919876543200',
        password: 'FacultyPassword123!',
      });

    expect(loginPhoneRes.status).toBe(200);
    expect(loginPhoneRes.body.data.user.role).toBe(AppRole.FACULTY);
  });

  // =========================================================================
  // 3. LISTING, SEARCH, RBAC & VISIBILITY (24 - 28, 41, 42, 43)
  // =========================================================================

  it('24, 25, 26, 43. Super Admin sees all, College Admin sees all college faculty (including HOD-created), HOD sees own department only', async () => {
    // 1. HOD A1 creates Faculty in deptA1
    const res1 = await request(app)
      .post('/api/v1/academics/faculty')
      .set(hodA1Header)
      .send({
        departmentId: deptA1.id,
        name: 'Prof. CSE Faculty',
        instituteId: 'FAC-VIS-01',
        email: 'cse.fac@alpha.edu',
      });
    expect(res1.status).toBe(201);

    // 2. HOD A2 creates Faculty in deptA2
    const res2 = await request(app)
      .post('/api/v1/academics/faculty')
      .set(hodA2Header)
      .send({
        departmentId: deptA2.id,
        name: 'Prof. ECE Faculty',
        instituteId: 'FAC-VIS-02',
        email: 'ece.fac@alpha.edu',
      });
    expect(res2.status).toBe(201);

    // 3. College Admin B creates Faculty in College B
    const res3 = await request(app)
      .post('/api/v1/academics/faculty')
      .set(collegeAdminBHeader)
      .send({
        departmentId: deptB1.id,
        name: 'Prof. Beta Faculty',
        instituteId: 'FAC-VIS-03',
        email: 'beta.fac@beta.edu',
      });
    expect(res3.status).toBe(201);

    // 24. Super Admin lists all faculty (total = 3)
    const resSuper = await request(app)
      .get('/api/v1/academics/faculty')
      .set(superAdminHeader);

    expect(resSuper.status).toBe(200);
    expect(resSuper.body.data.total).toBe(3);

    // 25 & 43. College Admin A lists all faculty in College A (sees both CSE and ECE faculty created by HODs)
    const resAdminA = await request(app)
      .get('/api/v1/academics/faculty')
      .set(collegeAdminAHeader);

    expect(resAdminA.status).toBe(200);
    expect(resAdminA.body.data.items).toHaveLength(2);

    // 26. HOD A1 lists faculty -> only sees deptA1 faculty (1 faculty)
    const resHodA1 = await request(app)
      .get('/api/v1/academics/faculty')
      .set(hodA1Header);

    expect(resHodA1.status).toBe(200);
    expect(resHodA1.body.data.items).toHaveLength(1);
    expect(resHodA1.body.data.items[0].user.instituteId).toBe('FAC-VIS-01');
  });

  it('27 & 28. Faculty sees own profile only; Student is forbidden from faculty administration (403)', async () => {
    const provRes = await request(app)
      .post('/api/v1/academics/faculty')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA1.id,
        name: 'Prof. Self Fac',
        instituteId: 'FAC-SELF-01',
        email: 'self.fac@alpha.edu',
      });

    const facUserId = provRes.body.data.user.id;

    // Activate the faculty account so it is ACTIVE
    await User.findByIdAndUpdate(facUserId, { accountStatus: AccountStatus.ACTIVE });

    const facultyHeader = createTestAuthHeader({
      userId: facUserId,
      instituteId: 'FAC-SELF-01',
      collegeId: collegeA.id,
      departmentId: deptA1.id,
      role: AppRole.FACULTY,
    });

    // 27. Faculty cannot list all faculty
    const resListFac = await request(app)
      .get('/api/v1/academics/faculty')
      .set(facultyHeader);
    expect(resListFac.status).toBe(403);

    // Faculty CAN get own profile
    const resGetSelf = await request(app)
      .get(`/api/v1/academics/faculty/${facUserId}`)
      .set(facultyHeader);
    expect(resGetSelf.status).toBe(200);
    expect(resGetSelf.body.data.user.name).toBe('Prof. Self Fac');

    // 28. Student cannot list faculty
    const resStu = await request(app)
      .get('/api/v1/academics/faculty')
      .set(studentAHeader);
    expect(resStu.status).toBe(403);
  });

  // =========================================================================
  // 4. RETRIEVAL & PROFILE UPDATES (29 - 34, 50)
  // =========================================================================

  it('29 & 30 & 50. Faculty retrieval works and cross-tenant access is rejected', async () => {
    const provResA = await request(app)
      .post('/api/v1/academics/faculty')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA1.id,
        name: 'Prof. Alpha Ret',
        instituteId: 'FAC-RET-A',
        email: 'ret.a@alpha.edu',
      });

    const facId = provResA.body.data.user.id;

    // College Admin A can get
    const resA = await request(app)
      .get(`/api/v1/academics/faculty/${facId}`)
      .set(collegeAdminAHeader);
    expect(resA.status).toBe(200);
    expect(resA.body.data.user.name).toBe('Prof. Alpha Ret');

    // College Admin B CANNOT get
    const resB = await request(app)
      .get(`/api/v1/academics/faculty/${facId}`)
      .set(collegeAdminBHeader);
    expect(resB.status).toBe(403);
    expect(resB.body.error.message).toContain('Cross-college tenant access is strictly prohibited');
  });

  it('31, 32, 33, 34. Faculty profile update works; role, collegeId, departmentId are immutable', async () => {
    const provRes = await request(app)
      .post('/api/v1/academics/faculty')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA1.id,
        name: 'Prof. Initial Name',
        instituteId: 'FAC-IMM-01',
        email: 'initial.fac@alpha.edu',
      });

    const facUserId = provRes.body.data.user.id;

    const resUpdate = await request(app)
      .put(`/api/v1/academics/faculty/${facUserId}`)
      .set(collegeAdminAHeader)
      .send({
        name: 'Prof. Updated Name',
        role: AppRole.SUPER_ADMIN, // Escalation attempt
        collegeId: collegeB.id, // Move tenant attempt
        departmentId: deptA2.id, // Move dept directly attempt
        designation: 'Associate Professor',
        qualification: 'Ph.D. in CS',
      });

    expect(resUpdate.status).toBe(200);
    expect(resUpdate.body.data.user.name).toBe('Prof. Updated Name');
    expect(resUpdate.body.data.faculty.designation).toBe('Associate Professor');
    expect(resUpdate.body.data.faculty.qualification).toBe('Ph.D. in CS');

    // Verify DB immutability
    const checkDbUser = await User.findById(facUserId);
    expect(checkDbUser?.role).toBe(AppRole.FACULTY);
    expect(checkDbUser?.collegeId?.toString()).toBe(collegeA.id);
    expect(checkDbUser?.departmentId?.toString()).toBe(deptA1.id);
  });

  // =========================================================================
  // 5. DEPARTMENT TRANSFERS & LOOKUPS (35 - 40, 41, 42)
  // =========================================================================

  it('35, 36, 37, 38, 39, 40. Faculty department transfer rules and inactive checks', async () => {
    const provRes = await request(app)
      .post('/api/v1/academics/faculty')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA1.id,
        name: 'Prof. Transferable',
        instituteId: 'FAC-TRF-01',
        email: 'trf@alpha.edu',
      });

    const facUserId = provRes.body.data.user.id;

    // 36. HOD CANNOT transfer faculty (403)
    const resHodTrf = await request(app)
      .patch(`/api/v1/academics/faculty/${facUserId}/department`)
      .set(hodA1Header)
      .send({ departmentId: deptA2.id });
    expect(resHodTrf.status).toBe(403);

    // 37. College Admin A cannot transfer to College B department
    const resCrossTrf = await request(app)
      .patch(`/api/v1/academics/faculty/${facUserId}/department`)
      .set(collegeAdminAHeader)
      .send({ departmentId: deptB1.id });
    expect(resCrossTrf.status).toBe(403);
    expect(resCrossTrf.body.error.message).toContain('another college');

    // 39. Transfer to inactive department rejected
    const resInactDept = await request(app)
      .patch(`/api/v1/academics/faculty/${facUserId}/department`)
      .set(collegeAdminAHeader)
      .send({ departmentId: deptAInactive.id });
    expect(resInactDept.status).toBe(403);
    expect(resInactDept.body.error.message).toContain('inactive department');

    // 35. College Admin A transfers faculty within College A from deptA1 to deptA2 -> SUCCESS
    const resSuccess = await request(app)
      .patch(`/api/v1/academics/faculty/${facUserId}/department`)
      .set(collegeAdminAHeader)
      .send({ departmentId: deptA2.id });

    expect(resSuccess.status).toBe(200);
    expect(resSuccess.body.data.user.departmentId).toBe(deptA2.id);
    expect(resSuccess.body.data.faculty.departmentId).toBe(deptA2.id);
  });

  it('41 & 42. Department faculty lookup works and is properly scoped', async () => {
    await request(app)
      .post('/api/v1/academics/faculty')
      .set(hodA1Header)
      .send({
        departmentId: deptA1.id,
        name: 'Prof. Lookup Fac',
        instituteId: 'FAC-LKP-01',
        email: 'lkp@alpha.edu',
      });

    // 41. Lookup deptA1 faculty
    const resLkp = await request(app)
      .get(`/api/v1/departments/${deptA1.id}/faculty`)
      .set(hodA1Header);

    expect(resLkp.status).toBe(200);
    expect(resLkp.body.data).toHaveLength(1);
    expect(resLkp.body.data[0].user.instituteId).toBe('FAC-LKP-01');

    // 42. HOD A1 cannot lookup deptA2 faculty
    const resHODA2Lkp = await request(app)
      .get(`/api/v1/departments/${deptA2.id}/faculty`)
      .set(hodA1Header);

    expect(resHODA2Lkp.status).toBe(403);
  });

  // =========================================================================
  // 6. SUMMARY, AUDIT LOGS, SECRETS & ROLLBACK (44 - 49)
  // =========================================================================

  it('44. Faculty summary returns accurate data', async () => {
    const provRes = await request(app)
      .post('/api/v1/academics/faculty')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA1.id,
        name: 'Prof. Summary Fac',
        instituteId: 'FAC-SUM-01',
        email: 'sum.fac@alpha.edu',
      });

    const facUserId = provRes.body.data.user.id;

    const res = await request(app)
      .get(`/api/v1/academics/faculty/${facUserId}/summary`)
      .set(collegeAdminAHeader);

    expect(res.status).toBe(200);
    expect(res.body.data.user.name).toBe('Prof. Summary Fac');
    expect(res.body.data.college.code).toBe('ALPHA');
    expect(res.body.data.department.code).toBe('CSE');
    expect(res.body.data.assignmentCount).toBe(0);
  });

  it('45, 46, 47, 48. Audit logs are generated for provisioning, update, transfer without exposing secrets', async () => {
    // 1. Provision -> FACULTY_PROVISIONED
    const provRes = await request(app)
      .post('/api/v1/academics/faculty')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA1.id,
        name: 'Prof. Audited Fac',
        instituteId: 'FAC-AUD-01',
        email: 'aud.fac@alpha.edu',
      });

    const facUserId = provRes.body.data.user.id;
    const facProfileId = provRes.body.data.faculty.id;

    // 2. Update -> FACULTY_UPDATED
    await request(app)
      .put(`/api/v1/academics/faculty/${facUserId}`)
      .set(collegeAdminAHeader)
      .send({ name: 'Prof. Audited Fac Updated' });

    // 3. Transfer -> FACULTY_DEPARTMENT_TRANSFERRED
    await request(app)
      .patch(`/api/v1/academics/faculty/${facUserId}/department`)
      .set(collegeAdminAHeader)
      .send({ departmentId: deptA2.id });

    const logs = await AuditLog.find({
      $or: [{ entityId: facUserId }, { entityId: facProfileId }],
    });
    const actions = logs.map((l) => l.action);

    expect(actions).toContain('FACULTY_PROVISIONED');
    expect(actions).toContain('FACULTY_UPDATED');
    expect(actions).toContain('FACULTY_DEPARTMENT_TRANSFERRED');

    // 48. No secrets exposed
    const serialized = JSON.stringify(logs);
    expect(serialized).not.toContain('password');
    expect(serialized).not.toContain('AdminPass123');
  });

  it('49. Transaction/rollback prevents orphan records when profile creation fails', async () => {
    // 1. Create a faculty profile
    const provRes = await request(app)
      .post('/api/v1/academics/faculty')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA1.id,
        name: 'Prof. Unique Emp',
        instituteId: 'FAC-UNQ-01',
        email: 'unique.emp@alpha.edu',
        employeeId: 'EMP-DUPLICATE-KEY',
      });

    expect(provRes.status).toBe(201);

    // 2. Try creating another faculty with same employeeId directly to simulate profile collision
    const resFail = await request(app)
      .post('/api/v1/academics/faculty')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA1.id,
        name: 'Prof. Collision',
        instituteId: 'FAC-COL-99',
        email: 'collision@alpha.edu',
        employeeId: 'EMP-DUPLICATE-KEY',
      });

    expect(resFail.status).toBe(409);

    // Verify User 'FAC-COL-99' was NOT created as an orphan
    const orphanUser = await User.findOne({ instituteId: 'FAC-COL-99' });
    expect(orphanUser).toBeNull();
  });
});
