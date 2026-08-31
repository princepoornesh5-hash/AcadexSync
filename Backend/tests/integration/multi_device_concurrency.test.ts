import request from 'supertest';
import { app } from '../../src/app';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { College } from '../../src/models/college.model';
import { Department } from '../../src/models/department.model';
import { User } from '../../src/models/user.model';
import { AppRole } from '../../src/constants/roles';
import { AccountStatus } from '../../src/constants/status';
import { signAccessToken } from '../../src/utils/token';
import mongoose from 'mongoose';

describe('ACADEX Multi-Device 5-Role Concurrent Staging Simulation', () => {
  let collegeAId: string;
  let collegeBId: string;
  let deptAId: string;

  let superAdminId: string;
  let collegeAdminId: string;
  let hodId: string;
  let facultyId: string;
  let studentId: string;

  let phone1Token: string; // Super Admin
  let phone2Token: string; // College Admin (College A)
  let phone3Token: string; // HOD (College A, Dept A)
  let phone4Token: string; // Faculty (College A, Dept A)
  let phone5Token: string; // Student (College A, Dept A)

  beforeAll(async () => {
    await setupTestDB();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();

    // 1. Seed Multi-Tenant Hierarchy
    const collegeA = await College.create({
      name: 'Alpha Institute of Technology',
      code: 'AIT',
      address: 'Alpha Campus, 1st Ave',
      email: 'admin@alpha.edu',
      phone: '+1-555-0100',
      principal: 'Dr. Alpha Principal',
      status: 'active',
      isActive: true,
    });
    collegeAId = collegeA.id;

    const collegeB = await College.create({
      name: 'Beta State University',
      code: 'BSU',
      address: 'Beta Campus, 2nd Blvd',
      email: 'admin@beta.edu',
      phone: '+1-555-0200',
      principal: 'Dr. Beta Principal',
      status: 'active',
      isActive: true,
    });
    collegeBId = collegeB.id;

    const deptA = await Department.create({
      name: 'Computer Science & Engineering',
      code: 'CSE',
      collegeId: collegeAId,
      status: 'active',
      isActive: true,
    });
    deptAId = deptA.id;

    // 2. Seed 5 Distinct Role Users
    const superAdmin = await User.create({
      name: 'Global Super Admin',
      email: 'superadmin@acadex.com',
      instituteId: 'ADM-001',
      role: AppRole.SUPER_ADMIN,
      accountStatus: AccountStatus.ACTIVE,
      activationStatus: 'activated',
      passwordHash: 'hashed_password_placeholder',
    });
    superAdminId = superAdmin.id;

    const collegeAdmin = await User.create({
      name: 'Alpha College Admin',
      email: 'admin@alpha.edu',
      instituteId: 'AIT-ADM-01',
      role: AppRole.COLLEGE_ADMIN,
      collegeId: new mongoose.Types.ObjectId(collegeAId),
      accountStatus: AccountStatus.ACTIVE,
      activationStatus: 'activated',
      passwordHash: 'hashed_password_placeholder',
    });
    collegeAdminId = collegeAdmin.id;

    const hod = await User.create({
      name: 'Dr. Turing (HOD)',
      email: 'hod.cse@alpha.edu',
      instituteId: 'AIT-HOD-CSE',
      role: AppRole.HOD,
      collegeId: new mongoose.Types.ObjectId(collegeAId),
      departmentId: new mongoose.Types.ObjectId(deptAId),
      accountStatus: AccountStatus.ACTIVE,
      activationStatus: 'activated',
      passwordHash: 'hashed_password_placeholder',
    });
    hodId = hod.id;

    const faculty = await User.create({
      name: 'Prof. Hopper',
      email: 'faculty.hopper@alpha.edu',
      instituteId: 'AIT-FAC-042',
      role: AppRole.FACULTY,
      collegeId: new mongoose.Types.ObjectId(collegeAId),
      departmentId: new mongoose.Types.ObjectId(deptAId),
      accountStatus: AccountStatus.ACTIVE,
      activationStatus: 'activated',
      passwordHash: 'hashed_password_placeholder',
    });
    facultyId = faculty.id;

    const student = await User.create({
      name: 'Alice Student',
      email: 'alice@alpha.edu',
      instituteId: 'AIT-STU-2026-001',
      role: AppRole.STUDENT,
      collegeId: new mongoose.Types.ObjectId(collegeAId),
      departmentId: new mongoose.Types.ObjectId(deptAId),
      accountStatus: AccountStatus.ACTIVE,
      activationStatus: 'activated',
      passwordHash: 'hashed_password_placeholder',
    });
    studentId = student.id;

    // 3. Generate Cryptographic Bearer Tokens for 5 Physical Phone Devices
    phone1Token = signAccessToken({
      userId: superAdminId,
      instituteId: 'ADM-001',
      role: AppRole.SUPER_ADMIN,
      sessionId: 'session-phone-1',
    });

    phone2Token = signAccessToken({
      userId: collegeAdminId,
      instituteId: 'AIT-ADM-01',
      role: AppRole.COLLEGE_ADMIN,
      collegeId: collegeAId,
      sessionId: 'session-phone-2',
    });

    phone3Token = signAccessToken({
      userId: hodId,
      instituteId: 'AIT-HOD-CSE',
      role: AppRole.HOD,
      collegeId: collegeAId,
      departmentId: deptAId,
      sessionId: 'session-phone-3',
    });

    phone4Token = signAccessToken({
      userId: facultyId,
      instituteId: 'AIT-FAC-042',
      role: AppRole.FACULTY,
      collegeId: collegeAId,
      departmentId: deptAId,
      sessionId: 'session-phone-4',
    });

    phone5Token = signAccessToken({
      userId: studentId,
      instituteId: 'AIT-STU-2026-001',
      role: AppRole.STUDENT,
      collegeId: collegeAId,
      departmentId: deptAId,
      sessionId: 'session-phone-5',
    });
  });

  test('TEST 1: Token Isolation across 5 Physical Devices (Unique tokens, independent sessions)', () => {
    const tokens = [phone1Token, phone2Token, phone3Token, phone4Token, phone5Token];
    const uniqueTokens = new Set(tokens);
    expect(uniqueTokens.size).toBe(5);
  });

  test('TEST 2: Health Endpoint returns 200 OK and connected database status for online staging', async () => {
    const resRoot = await request(app).get('/health');
    expect(resRoot.status).toBe(200);
    expect(resRoot.body.status).toBe('ok');
    expect(resRoot.body.service).toBe('acadex-backend');
    expect(resRoot.body.database).toBe('connected');

    const resV1 = await request(app).get('/api/v1/health');
    expect(resV1.status).toBe(200);
    expect(resV1.body.status).toBe('ok');
    expect(resV1.body.database).toBe('connected');
  });

  test('TEST 3: Simultaneous 5-Device Concurrent Requests (Super Admin, College Admin, HOD, Faculty, Student)', async () => {
    // Execute 5 simultaneous requests in parallel
    const [res1, res2, res3, res4, res5] = await Promise.all([
      // Phone 1: Super Admin reading platform colleges
      request(app)
        .get('/api/v1/colleges')
        .set('Authorization', `Bearer ${phone1Token}`),

      // Phone 2: College Admin reading college departments
      request(app)
        .get('/api/v1/departments')
        .set('Authorization', `Bearer ${phone2Token}`),

      // Phone 3: HOD reading department courses
      request(app)
        .get('/api/v1/academics/courses')
        .set('Authorization', `Bearer ${phone3Token}`),

      // Phone 4: Faculty reading user profile / assignments
      request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', `Bearer ${phone4Token}`),

      // Phone 5: Student reading own profile
      request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', `Bearer ${phone5Token}`),
    ]);

    // Verify all 5 received authorized 200 responses with correct identities
    expect(res1.status).toBe(200);
    expect(res1.body.success).toBe(true);

    expect(res2.status).toBe(200);
    expect(res2.body.success).toBe(true);

    expect(res3.status).toBe(200);
    expect(res3.body.success).toBe(true);

    expect(res4.status).toBe(200);
    expect(res4.body.data.role).toBe(AppRole.FACULTY);
    expect(res4.body.data.instituteId).toBe('AIT-FAC-042');

    expect(res5.status).toBe(200);
    expect(res5.body.data.role).toBe(AppRole.STUDENT);
    expect(res5.body.data.instituteId).toBe('AIT-STU-2026-001');
  });

  test('TEST 4: Multi-Tenant Boundary Enforcement across Devices (College Admin cannot access College B)', async () => {
    // Phone 2 (College Admin for College A) attempts to access College B data
    const crossTenantRes = await request(app)
      .post('/api/v1/departments')
      .set('Authorization', `Bearer ${phone2Token}`)
      .send({
        name: 'Mechanical Engineering',
        code: 'MECH',
        collegeId: collegeBId, // Unauthorized target!
      });

    expect(crossTenantRes.status).toBe(403);
    expect(crossTenantRes.body.success).toBe(false);
  });

  test('TEST 5: RBAC Boundary Enforcement across Devices (Student cannot create Department)', async () => {
    // Phone 5 (Student) attempts to create a department
    const studentRes = await request(app)
      .post('/api/v1/departments')
      .set('Authorization', `Bearer ${phone5Token}`)
      .send({
        name: 'Hacked Department',
        code: 'HACK',
        collegeId: collegeAId,
      });

    expect(studentRes.status).toBe(403);
    expect(studentRes.body.success).toBe(false);
  });

  test('TEST 6: Independent Device Logout & Session Isolation (Phone 4 logs out, Phone 1, 2, 3, 5 remain active)', async () => {
    // Phone 4 (Faculty) calls logout
    const logoutRes = await request(app)
      .post('/api/v1/auth/logout')
      .set('Authorization', `Bearer ${phone4Token}`);

    expect(logoutRes.status).toBe(200);

    // Other 4 devices make subsequent simultaneous requests and remain 100% authenticated
    const [subsequentRes1, subsequentRes2, subsequentRes3, subsequentRes5] = await Promise.all([
      request(app).get('/api/v1/auth/me').set('Authorization', `Bearer ${phone1Token}`),
      request(app).get('/api/v1/auth/me').set('Authorization', `Bearer ${phone2Token}`),
      request(app).get('/api/v1/auth/me').set('Authorization', `Bearer ${phone3Token}`),
      request(app).get('/api/v1/auth/me').set('Authorization', `Bearer ${phone5Token}`),
    ]);

    expect(subsequentRes1.status).toBe(200);
    expect(subsequentRes1.body.data.role).toBe(AppRole.SUPER_ADMIN);

    expect(subsequentRes2.status).toBe(200);
    expect(subsequentRes2.body.data.role).toBe(AppRole.COLLEGE_ADMIN);

    expect(subsequentRes3.status).toBe(200);
    expect(subsequentRes3.body.data.role).toBe(AppRole.HOD);

    expect(subsequentRes5.status).toBe(200);
    expect(subsequentRes5.body.data.role).toBe(AppRole.STUDENT);
  });
});
