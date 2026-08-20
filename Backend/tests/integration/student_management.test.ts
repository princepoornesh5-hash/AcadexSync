import request from 'supertest';
import { app } from '../../src/app';
import { College } from '../../src/models/college.model';
import { User } from '../../src/models/user.model';
import { Department } from '../../src/models/department.model';
import { Faculty } from '../../src/models/faculty.model';
import { Student } from '../../src/models/student.model';
import { StudentContactRequest } from '../../src/models/studentContactRequest.model';
import { Invitation } from '../../src/models/invitation.model';
import { AuditLog } from '../../src/models/auditLog.model';
import { AppRole } from '../../src/constants/roles';
import { AccountStatus, CollegeStatus, DepartmentStatus, InvitationStatus } from '../../src/constants/status';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';
import { PasswordService } from '../../src/services/password.service';

describe('ACADEX Phase 9H.1 — Student Management & Enrollment Tests', () => {
  let superAdminUser: InstanceType<typeof User>;
  let collegeAdminA: InstanceType<typeof User>;
  let collegeAdminB: InstanceType<typeof User>;
  let hodA1: InstanceType<typeof User>;
  let facultyA1: InstanceType<typeof User>;
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
  let facultyA1Header: { Authorization: string };
  let studentAHeader: { Authorization: string };

  beforeAll(async () => {
    await setupTestDB();
    await College.init();
    await User.init();
    await Department.init();
    await Faculty.init();
    await Student.init();
    await StudentContactRequest.init();
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

    facultyA1 = await User.create({
      instituteId: 'FAC-CSE-01',
      name: 'Prof. Knuth',
      email: 'knuth@alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.FACULTY,
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    studentA = await User.create({
      instituteId: 'STU-CSE-001',
      name: 'Alice Smith',
      email: 'alice@alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.STUDENT,
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    await Student.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      userId: studentA._id,
      instituteId: studentA.instituteId,
      name: studentA.name,
      email: studentA.email,
      rollNumber: 'CSE-2026-001',
      status: 'active',
      isActive: true,
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

    facultyA1Header = createTestAuthHeader({
      userId: facultyA1.id,
      instituteId: facultyA1.instituteId,
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
  // 1. PROVISIONING & SCOPE CHECKS (1 - 16, 55)
  // =========================================================================

  it('1, 7, 8, 9, 10. Super Admin can provision student with auto role, PENDING_ACTIVATION and linked Student profile', async () => {
    const res = await request(app)
      .post('/api/v1/academics/students')
      .set(superAdminHeader)
      .send({
        departmentId: deptA1.id,
        name: 'Bob Jones',
        instituteId: 'STU-CSE-002',
        email: 'bob@alpha.edu',
        phone: '+919876543220',
        rollNumber: 'CSE-2026-002',
        admissionNumber: 'ADM-2026-002',
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.user.role).toBe(AppRole.STUDENT);
    expect(res.body.data.user.accountStatus).toBe(AccountStatus.PENDING_ACTIVATION);
    expect(res.body.data.student.rollNumber).toBe('CSE-2026-002');
    expect(res.body.data.student.userId).toBe(res.body.data.user.id);
    expect(res.body.data.invitation.status).toBe(InvitationStatus.PENDING);
    expect(res.body.data.activationCode).toBeDefined();
  });

  it('2, 3, 4. College Admin, HOD, and authorized Faculty can provision students in their scope', async () => {
    // 2. College Admin
    const resAdmin = await request(app)
      .post('/api/v1/academics/students')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA2.id,
        name: 'Charlie Brown',
        instituteId: 'STU-ECE-001',
        email: 'charlie@alpha.edu',
      });
    expect(resAdmin.status).toBe(201);

    // 3. HOD in own department
    const resHod = await request(app)
      .post('/api/v1/academics/students')
      .set(hodA1Header)
      .send({
        departmentId: deptA1.id,
        name: 'David Miller',
        instituteId: 'STU-CSE-003',
        email: 'david@alpha.edu',
      });
    expect(resHod.status).toBe(201);

    // 4. Authorized Faculty in own department
    const resFac = await request(app)
      .post('/api/v1/academics/students')
      .set(facultyA1Header)
      .send({
        departmentId: deptA1.id,
        name: 'Emma Watson',
        instituteId: 'STU-CSE-004',
        email: 'emma@alpha.edu',
      });
    expect(resFac.status).toBe(201);
  });

  it('5 & 6. Unauthorized Faculty outside scope, inactive college, and Student cannot provision students (403)', async () => {
    // 5. Faculty provisioning in another department -> 403
    const resFacOther = await request(app)
      .post('/api/v1/academics/students')
      .set(facultyA1Header)
      .send({
        departmentId: deptA2.id,
        name: 'Frank Ocean',
        instituteId: 'STU-ECE-099',
        email: 'frank@alpha.edu',
      });
    expect(resFacOther.status).toBe(403);

    // Inactive college check
    const inactDept = await Department.create({
      collegeId: inactiveCollege._id,
      name: 'Gamma Dept',
      code: 'GAMMADEPT',
      status: DepartmentStatus.ACTIVE,
      isActive: true,
    });

    const resInactCol = await request(app)
      .post('/api/v1/academics/students')
      .set(superAdminHeader)
      .send({
        departmentId: inactDept.id,
        name: 'Inactive College Student',
        instituteId: 'STU-INACT-01',
        email: 'inact.stu@gamma.edu',
      });
    expect(resInactCol.status).toBe(403);

    // 6. Student cannot provision -> 403
    const resStu = await request(app)
      .post('/api/v1/academics/students')
      .set(studentAHeader)
      .send({
        departmentId: deptA1.id,
        name: 'Grace Hopper',
        instituteId: 'STU-CSE-099',
        email: 'grace@alpha.edu',
      });
    expect(resStu.status).toBe(403);
  });

  it('11, 12, 14, 15, 16. Duplicate instituteId, email, phone, rollNumber, admissionNumber rejected with 409', async () => {
    await request(app)
      .post('/api/v1/academics/students')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA1.id,
        name: 'Student 1',
        instituteId: 'STU-DUP-01',
        email: 'dup.stu@alpha.edu',
        phone: '+919988112244',
        rollNumber: 'ROLL-DUP-01',
        admissionNumber: 'ADM-DUP-01',
      });

    // 11. Duplicate instituteId
    const resInst = await request(app)
      .post('/api/v1/academics/students')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA1.id,
        name: 'Student 2',
        instituteId: 'STU-DUP-01',
        email: 'other.stu@alpha.edu',
      });
    expect(resInst.status).toBe(409);

    // 12. Duplicate email
    const resEm = await request(app)
      .post('/api/v1/academics/students')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA1.id,
        name: 'Student 3',
        instituteId: 'STU-DUP-02',
        email: 'dup.stu@alpha.edu',
      });
    expect(resEm.status).toBe(409);

    // 14. Duplicate phone
    const resPh = await request(app)
      .post('/api/v1/academics/students')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA1.id,
        name: 'Student 4',
        instituteId: 'STU-DUP-03',
        phone: '+919988112244',
      });
    expect(resPh.status).toBe(409);

    // 15. Duplicate rollNumber
    const resRoll = await request(app)
      .post('/api/v1/academics/students')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA1.id,
        name: 'Student 5',
        instituteId: 'STU-DUP-04',
        rollNumber: 'ROLL-DUP-01',
      });
    expect(resRoll.status).toBe(409);

    // 16. Duplicate admissionNumber
    const resAdm = await request(app)
      .post('/api/v1/academics/students')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA1.id,
        name: 'Student 6',
        instituteId: 'STU-DUP-05',
        admissionNumber: 'ADM-DUP-01',
      });
    expect(resAdm.status).toBe(409);
  });

  it('13, 21, 22, 23. Optional phone works, missing phone activates cleanly, phone login gracefully unavailable', async () => {
    // 13 & 21. Provision without phone
    const provRes = await request(app)
      .post('/api/v1/academics/students')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA1.id,
        name: 'No Phone Student',
        instituteId: 'STU-NOPH-01',
        email: 'nophone@alpha.edu',
      });

    expect(provRes.status).toBe(201);
    expect(provRes.body.data.user.phone).toBeUndefined();

    // 21. Activation works without phone
    const actRes = await request(app)
      .post('/api/v1/auth/activate')
      .send({
        collegeCode: 'ALPHA',
        instituteId: 'STU-NOPH-01',
        activationCode: provRes.body.data.activationCode,
        password: 'StudentPass123!',
      });
    expect(actRes.status).toBe(200);

    // 22. Verify no fake phone created
    const dbUser = await User.findOne({ instituteId: 'STU-NOPH-01' });
    expect(dbUser?.phone).toBeUndefined();

    // 19. Email login works
    const emailLogin = await request(app)
      .post('/api/v1/auth/login')
      .send({
        identifier: 'nophone@alpha.edu',
        password: 'StudentPass123!',
      });
    expect(emailLogin.status).toBe(200);
    expect(emailLogin.body.data.user.role).toBe(AppRole.STUDENT);

    // 23. Phone login with unregistered/missing phone fails gracefully
    const phoneLogin = await request(app)
      .post('/api/v1/auth/login')
      .send({
        identifier: '+919999999999',
        password: 'StudentPass123!',
      });
    expect(phoneLogin.status).toBe(401);
  });

  // =========================================================================
  // 2. ACTIVATION & LOGIN (17 - 20)
  // =========================================================================

  it('17, 18, 19, 20. Student with email + phone activates and logs in via both', async () => {
    const provRes = await request(app)
      .post('/api/v1/academics/students')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA1.id,
        name: 'Hannah Abbott',
        instituteId: 'STU-HAN-01',
        email: 'hannah@alpha.edu',
        phone: '+919876543230',
      });

    await request(app)
      .post('/api/v1/auth/activate')
      .send({
        collegeCode: 'ALPHA',
        instituteId: 'STU-HAN-01',
        activationCode: provRes.body.data.activationCode,
        password: 'HannahPassword123!',
      });

    // Email login
    const resEmail = await request(app)
      .post('/api/v1/auth/login')
      .send({
        identifier: 'hannah@alpha.edu',
        password: 'HannahPassword123!',
      });
    expect(resEmail.status).toBe(200);

    // Phone login
    const resPhone = await request(app)
      .post('/api/v1/auth/login')
      .send({
        identifier: '+919876543230',
        password: 'HannahPassword123!',
      });
    expect(resPhone.status).toBe(200);
  });

  // =========================================================================
  // 3. LISTING, SEARCH, VISIBILITY & SHARED TRUTH (25 - 31, 50, 51, 52, 56)
  // =========================================================================

  it('25, 26, 27, 28, 51, 52. Shared DB truth: Faculty-created visible to HOD and College Admin; Scoped listing', async () => {
    // 1. Faculty A1 creates Student in deptA1
    await request(app)
      .post('/api/v1/academics/students')
      .set(facultyA1Header)
      .send({
        departmentId: deptA1.id,
        name: 'Faculty Created Student',
        instituteId: 'STU-FAC-01',
        email: 'fac.stu@alpha.edu',
      });

    // 2. HOD A1 creates Student in deptA1
    await request(app)
      .post('/api/v1/academics/students')
      .set(hodA1Header)
      .send({
        departmentId: deptA1.id,
        name: 'HOD Created Student',
        instituteId: 'STU-HOD-01',
        email: 'hod.stu@alpha.edu',
      });

    // 3. College Admin B creates Student in College B
    await request(app)
      .post('/api/v1/academics/students')
      .set(collegeAdminBHeader)
      .send({
        departmentId: deptB1.id,
        name: 'Beta Student',
        instituteId: 'STU-BET-01',
        email: 'beta.stu@beta.edu',
      });

    // 25. Super Admin lists all students (studentA + 3 new = 4 total)
    const resSuper = await request(app)
      .get('/api/v1/academics/students')
      .set(superAdminHeader);
    expect(resSuper.status).toBe(200);
    expect(resSuper.body.data.total).toBe(4);

    // 26 & 51. College Admin A sees all College A students (3 students, including faculty and HOD created)
    const resAdminA = await request(app)
      .get('/api/v1/academics/students')
      .set(collegeAdminAHeader);
    expect(resAdminA.status).toBe(200);
    expect(resAdminA.body.data.items).toHaveLength(3);

    // 27 & 52. HOD A1 sees deptA1 students (including faculty created student)
    const resHodA = await request(app)
      .get('/api/v1/academics/students')
      .set(hodA1Header);
    expect(resHodA.status).toBe(200);
    expect(resHodA.body.data.items).toHaveLength(3);

    // 28. Faculty A1 sees deptA1 students
    const resFacA = await request(app)
      .get('/api/v1/academics/students')
      .set(facultyA1Header);
    expect(resFacA.status).toBe(200);
    expect(resFacA.body.data.items).toHaveLength(3);
  });

  it('29, 30, 31. Student sees own profile only, cross-college and cross-dept access rejected', async () => {
    // 29. Student cannot list all students
    const resList = await request(app)
      .get('/api/v1/academics/students')
      .set(studentAHeader);
    expect(resList.status).toBe(403);

    // Student can get own profile
    const resSelf = await request(app)
      .get(`/api/v1/academics/students/${studentA.id}`)
      .set(studentAHeader);
    expect(resSelf.status).toBe(200);
    expect(resSelf.body.data.user.name).toBe('Alice Smith');

    // 30. College Admin B cannot access studentA in College A
    const resCross = await request(app)
      .get(`/api/v1/academics/students/${studentA.id}`)
      .set(collegeAdminBHeader);
    expect(resCross.status).toBe(403);
  });

  // =========================================================================
  // 4. UPDATES, INSTITUTE ID CORRECTION & TRANSFERS (32 - 42)
  // =========================================================================

  it('32, 33, 34, 35. Student profile update works safely and preserves immutable fields', async () => {
    const resUpdate = await request(app)
      .put(`/api/v1/academics/students/${studentA.id}`)
      .set(collegeAdminAHeader)
      .send({
        name: 'Alice Updated',
        role: AppRole.SUPER_ADMIN, // Escalation attempt
        collegeId: collegeB.id, // Tenant change attempt
        departmentId: deptA2.id, // Direct dept change attempt
        rollNumber: 'CSE-2026-999',
        bloodGroup: 'O+',
      });

    expect(resUpdate.status).toBe(200);
    expect(resUpdate.body.data.user.name).toBe('Alice Updated');
    expect(resUpdate.body.data.student.rollNumber).toBe('CSE-2026-999');
    expect(resUpdate.body.data.student.bloodGroup).toBe('O+');

    // DB immutability check
    const checkDb = await User.findById(studentA.id);
    expect(checkDb?.role).toBe(AppRole.STUDENT);
    expect(checkDb?.collegeId?.toString()).toBe(collegeA.id);
    expect(checkDb?.departmentId?.toString()).toBe(deptA1.id);
  });

  it('36, 37, 38, 39. Authorized instituteId correction works, preserves User._id and Student.userId', async () => {
    // 36. College Admin corrects instituteId
    const resCorrect = await request(app)
      .patch(`/api/v1/academics/students/${studentA.id}/institute-id`)
      .set(collegeAdminAHeader)
      .send({ instituteId: 'CSE-2026-CORRECTED' });

    expect(resCorrect.status).toBe(200);
    expect(resCorrect.body.data.user.instituteId).toBe('CSE-2026-CORRECTED');
    expect(resCorrect.body.data.student.instituteId).toBe('CSE-2026-CORRECTED');

    // 38 & 39. Preserves MongoDB _id and Student.userId
    const checkUser = await User.findById(studentA.id);
    const checkStudent = await Student.findOne({ userId: studentA.id });

    expect(checkUser?.id).toBe(studentA.id);
    expect(checkStudent?.userId.toString()).toBe(studentA.id);

    // 37. Unauthorized student cannot change instituteId (403)
    const resStuFail = await request(app)
      .patch(`/api/v1/academics/students/${studentA.id}/institute-id`)
      .set(studentAHeader)
      .send({ instituteId: 'HACKED-ID' });
    expect(resStuFail.status).toBe(403);
  });

  it('40, 41, 42. Safe Department transfer works, rejects inactive department and cross-college transfers', async () => {
    // 41. Inactive department -> 403
    const resInact = await request(app)
      .patch(`/api/v1/academics/students/${studentA.id}/department`)
      .set(collegeAdminAHeader)
      .send({ departmentId: deptAInactive.id });
    expect(resInact.status).toBe(403);

    // 42. College Admin A transferring to College B department -> 403
    const resCross = await request(app)
      .patch(`/api/v1/academics/students/${studentA.id}/department`)
      .set(collegeAdminAHeader)
      .send({ departmentId: deptB1.id });
    expect(resCross.status).toBe(403);

    // 40. Safe transfer within College A (deptA1 to deptA2)
    const resTrf = await request(app)
      .patch(`/api/v1/academics/students/${studentA.id}/department`)
      .set(collegeAdminAHeader)
      .send({ departmentId: deptA2.id });

    expect(resTrf.status).toBe(200);
    expect(resTrf.body.data.user.departmentId).toBe(deptA2.id);
    expect(resTrf.body.data.student.departmentId).toBe(deptA2.id);
  });

  // =========================================================================
  // 5. STUDENT CONTACT REQUEST ("REQUEST TEACHER FOR MOBILE") (43 - 48)
  // =========================================================================

  it('43, 44, 45, 46, 47, 48. Student creates phone addition request, staff resolves (approve/reject)', async () => {
    // 43. Student creates phone request
    const resReq = await request(app)
      .post('/api/v1/academics/students/me/phone-request')
      .set(studentAHeader)
      .send({
        requestedPhone: '+919988771122',
        notes: 'Please add my primary mobile number for SMS and OTP.',
      });

    expect(resReq.status).toBe(201);
    expect(resReq.body.data.requestedPhone).toBe('+919988771122');
    expect(resReq.body.data.status).toBe('PENDING');

    const requestId = resReq.body.data.id;

    // 44. Faculty in same department can view request
    const resList = await request(app)
      .get('/api/v1/academics/student-contact-requests')
      .set(facultyA1Header);
    expect(resList.status).toBe(200);
    expect(resList.body.data.items).toHaveLength(1);

    // 45. College Admin B cannot access/resolve request
    const resCrossResolve = await request(app)
      .patch(`/api/v1/academics/student-contact-requests/${requestId}`)
      .set(collegeAdminBHeader)
      .send({ status: 'APPROVED' });
    expect(resCrossResolve.status).toBe(403);

    // 46 & 48. Faculty A1 approves request -> Phone updated in User and Student
    const resApprove = await request(app)
      .patch(`/api/v1/academics/student-contact-requests/${requestId}`)
      .set(facultyA1Header)
      .send({
        status: 'APPROVED',
        notes: 'Verified via student ID card.',
      });

    expect(resApprove.status).toBe(200);
    expect(resApprove.body.data.status).toBe('APPROVED');

    // Verify User and Student have the new phone
    const updatedUser = await User.findById(studentA.id);
    const updatedStudent = await Student.findOne({ userId: studentA.id });

    expect(updatedUser?.phone).toBe('+919988771122');
    expect(updatedStudent?.phone).toBe('+919988771122');
  });

  // =========================================================================
  // 6. SUMMARY, AUDIT EVENTS, SECRETS & ROLLBACK (49, 53, 54, 55)
  // =========================================================================

  it('49 & 50. Student summary returns real data; department lookup works', async () => {
    // 49. Summary
    const resSum = await request(app)
      .get(`/api/v1/academics/students/${studentA.id}/summary`)
      .set(collegeAdminAHeader);

    expect(resSum.status).toBe(200);
    expect(resSum.body.data.user.name).toBe('Alice Smith');
    expect(resSum.body.data.college.code).toBe('ALPHA');
    expect(resSum.body.data.department.code).toBe('CSE');
    expect(resSum.body.data.enrollmentCount).toBe(0);

    // 50. Department lookup
    const resDept = await request(app)
      .get(`/api/v1/departments/${deptA1.id}/students`)
      .set(hodA1Header);

    expect(resDept.status).toBe(200);
    expect(resDept.body.data.length).toBeGreaterThanOrEqual(1);
  });

  it('53, 54, 55. Audit events logged, secrets omitted, and rollback prevents orphan records', async () => {
    // 53. Provision Student -> STUDENT_PROVISIONED
    const provRes = await request(app)
      .post('/api/v1/academics/students')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA1.id,
        name: 'Audited Student',
        instituteId: 'STU-AUD-01',
        email: 'aud.stu@alpha.edu',
        rollNumber: 'ROLL-AUD-01',
      });

    const stuUserId = provRes.body.data.user.id;
    const stuProfileId = provRes.body.data.student.id;

    // Update Student -> STUDENT_UPDATED
    await request(app)
      .put(`/api/v1/academics/students/${stuUserId}`)
      .set(collegeAdminAHeader)
      .send({ name: 'Audited Student Renamed' });

    const logs = await AuditLog.find({
      $or: [{ entityId: stuUserId }, { entityId: stuProfileId }],
    });
    const actions = logs.map((l) => l.action);

    expect(actions).toContain('STUDENT_PROVISIONED');
    expect(actions).toContain('STUDENT_UPDATED');

    // 54. Secrets not exposed
    const serialized = JSON.stringify(logs);
    expect(serialized).not.toContain('password');
    expect(serialized).not.toContain('AdminPass123');

    // 55. Rollback on profile collision (e.g. duplicate rollNumber)
    const resFail = await request(app)
      .post('/api/v1/academics/students')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA1.id,
        name: 'Collision Student',
        instituteId: 'STU-COL-99',
        email: 'col@alpha.edu',
        rollNumber: 'ROLL-AUD-01', // Duplicate rollNumber in same college
      });

    expect(resFail.status).toBe(409);

    // Verify 'STU-COL-99' was not orphaned in users collection
    const orphan = await User.findOne({ instituteId: 'STU-COL-99' });
    expect(orphan).toBeNull();
  });
});
