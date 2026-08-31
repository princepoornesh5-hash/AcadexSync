import request from 'supertest';
import { app } from '../../src/app';
import { User } from '../../src/models/user.model';
import { College } from '../../src/models/college.model';
import { Department } from '../../src/models/department.model';
import { Invitation } from '../../src/models/invitation.model';
import { AppRole } from '../../src/constants/roles';
import { AccountStatus } from '../../src/constants/status';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { signAccessToken } from '../../src/utils/token';
import { PasswordService } from '../../src/services/password.service';

describe('ACADEX Activation Deep Diagnosis & Multi-Account Isolation Suite', () => {
  let collegeA: any;
  let collegeB: any;
  let deptA1: any;

  let superAdminUser: any;
  let superAdminToken: string;

  beforeAll(async () => {
    await setupTestDB();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();

    // 1. Seed Colleges
    collegeA = await College.create({
      name: 'Alpha Institute of Technology',
      code: 'AIT',
      address: '123 Tech Lane',
      email: 'contact@ait.edu',
      phone: '+1-555-0101',
      principal: 'Dr. Alpha Principal',
      status: 'active',
      isActive: true,
    });

    collegeB = await College.create({
      name: 'Beta State University',
      code: 'BSU',
      address: '456 Uni Blvd',
      email: 'contact@bsu.edu',
      phone: '+1-555-0102',
      principal: 'Dr. Beta Principal',
      status: 'active',
      isActive: true,
    });

    // 2. Seed Departments
    deptA1 = await Department.create({
      name: 'Computer Science & Engineering',
      code: 'CSE',
      collegeId: collegeA.id,
      status: 'active',
      isActive: true,
    });

    await Department.create({
      name: 'Mechanical Engineering',
      code: 'MECH',
      collegeId: collegeB.id,
      status: 'active',
      isActive: true,
    });

    // 3. Seed Super Admin
    const superAdminPasswordHash = await PasswordService.hashPassword('SuperAdminSecret123!');
    superAdminUser = await User.create({
      name: 'Platform Super Admin',
      email: 'superadmin@acadex.com',
      instituteId: 'SUP-001',
      role: AppRole.SUPER_ADMIN,
      accountStatus: AccountStatus.ACTIVE,
      activationStatus: 'activated',
      passwordHash: superAdminPasswordHash,
    });

    superAdminToken = signAccessToken({
      userId: superAdminUser.id,
      instituteId: 'SUP-001',
      role: AppRole.SUPER_ADMIN,
      sessionId: 'test-sa-session',
    });
  });

  test('TEST 1 & TEST 2: Provision & Activate College Admin A then College Admin B (Payload Includes College Code, Zero Collision)', async () => {
    // 1. Super Admin provisions College Admin A for College A (via /colleges/:id/admins)
    const provisionResA = await request(app)
      .post(`/api/v1/colleges/${collegeA.id}/admins`)
      .set('Authorization', `Bearer ${superAdminToken}`)
      .send({
        name: 'Admin Alice',
        instituteId: 'AIT-ADM-01',
        email: 'alice.admin@ait.edu',
        phone: '+155510001',
      });

    expect(provisionResA.status).toBe(201);
    expect(provisionResA.body.success).toBe(true);
    expect(provisionResA.body.data.collegeCode).toBe('AIT');
    expect(provisionResA.body.data.collegeName).toBe('Alpha Institute of Technology');

    const codeA = provisionResA.body.data.activationCode;
    const userA = provisionResA.body.data.user;
    expect(codeA).toBeDefined();
    expect(codeA).toMatch(/^[2-9A-HJ-NP-Z]{4}-[2-9A-HJ-NP-Z]{4}-[2-9A-HJ-NP-Z]{4}$/);
    expect(userA.accountStatus).toBe(AccountStatus.PENDING_ACTIVATION);

    // 2. Super Admin provisions College Admin B for College B (via /colleges/:id/admins)
    const provisionResB = await request(app)
      .post(`/api/v1/colleges/${collegeB.id}/admins`)
      .set('Authorization', `Bearer ${superAdminToken}`)
      .send({
        name: 'Admin Bob',
        instituteId: 'BSU-ADM-01',
        email: 'bob.admin@bsu.edu',
        phone: '+155510002',
      });

    expect(provisionResB.status).toBe(201);
    expect(provisionResB.body.success).toBe(true);
    expect(provisionResB.body.data.collegeCode).toBe('BSU');
    const codeB = provisionResB.body.data.activationCode;
    const userB = provisionResB.body.data.user;
    expect(codeB).toBeDefined();
    expect(codeB).not.toBe(codeA); // Distinct codes
    expect(userB.accountStatus).toBe(AccountStatus.PENDING_ACTIVATION);

    // 3. Activate Account A using College Code 'AIT', PIN 'AIT-ADM-01', Code A
    const activateResA = await request(app)
      .post('/api/v1/auth/activate')
      .send({
        collegeCode: 'AIT',
        instituteId: 'AIT-ADM-01',
        activationCode: codeA,
        password: 'AliceStrongPassword123!',
      });

    expect(activateResA.status).toBe(200);
    expect(activateResA.body.success).toBe(true);
    expect(activateResA.body.data.user.accountStatus).toBe(AccountStatus.ACTIVE);

    // Verify Account B is STILL pending activation (A did not affect B)
    const dbUserB = await User.findOne({ instituteId: 'BSU-ADM-01' });
    expect(dbUserB?.accountStatus).toBe(AccountStatus.PENDING_ACTIVATION);

    // 4. Activate Account B using College Code 'BSU', PIN 'BSU-ADM-01', Code B
    const activateResB = await request(app)
      .post('/api/v1/auth/activate')
      .send({
        collegeCode: 'BSU',
        instituteId: 'BSU-ADM-01',
        activationCode: codeB,
        password: 'BobStrongPassword123!',
      });

    expect(activateResB.status).toBe(200);
    expect(activateResB.body.success).toBe(true);
    expect(activateResB.body.data.user.accountStatus).toBe(AccountStatus.ACTIVE);
  });

  test('TEST 3: Wrong Activation Code is Rejected with 400', async () => {
    // Provision Account
    const provisionRes = await request(app)
      .post(`/api/v1/colleges/${collegeA.id}/admins`)
      .set('Authorization', `Bearer ${superAdminToken}`)
      .send({
        name: 'Admin Charlie',
        instituteId: 'AIT-ADM-03',
        email: 'charlie@ait.edu',
      });

    expect(provisionRes.status).toBe(201);

    // Attempt activation with wrong code
    const activateRes = await request(app)
      .post('/api/v1/auth/activate')
      .send({
        collegeCode: 'AIT',
        instituteId: 'AIT-ADM-03',
        activationCode: 'WRON-GCOD-E999',
        password: 'CharliePassword123!',
      });

    expect(activateRes.status).toBe(400);
    expect(activateRes.body.success).toBe(false);
    expect(activateRes.body.error.message).toContain('Invalid activation code');

    // Account remains pending
    const user = await User.findOne({ instituteId: 'AIT-ADM-03' });
    expect(user?.accountStatus).toBe(AccountStatus.PENDING_ACTIVATION);
  });

  test('TEST 4: Activation Code from Another Account Fails (Code A cannot activate Account B)', async () => {
    // Provision Account A
    const resA = await request(app)
      .post(`/api/v1/colleges/${collegeA.id}/admins`)
      .set('Authorization', `Bearer ${superAdminToken}`)
      .send({ name: 'Admin A', instituteId: 'AIT-ADM-A', email: 'a@ait.edu' });
    const codeA = resA.body.data.activationCode;

    // Provision Account B
    const resB = await request(app)
      .post(`/api/v1/colleges/${collegeA.id}/admins`)
      .set('Authorization', `Bearer ${superAdminToken}`)
      .send({ name: 'Admin B', instituteId: 'AIT-ADM-B', email: 'b@ait.edu' });
    const codeB = resB.body.data.activationCode;

    // Attempt to activate Account B using Code A
    const activateBWithCodeA = await request(app)
      .post('/api/v1/auth/activate')
      .send({
        collegeCode: 'AIT',
        instituteId: 'AIT-ADM-B',
        activationCode: codeA, // WRONG CODE!
        password: 'ValidPassword123!',
      });

    expect(activateBWithCodeA.status).toBe(400);
    expect(activateBWithCodeA.body.error.message).toContain('Invalid activation code');

    // Now activate Account B with Code B -> MUST SUCCEED
    const activateBWithCodeB = await request(app)
      .post('/api/v1/auth/activate')
      .send({
        collegeCode: 'AIT',
        instituteId: 'AIT-ADM-B',
        activationCode: codeB,
        password: 'ValidPassword123!',
      });

    expect(activateBWithCodeB.status).toBe(200);
  });

  test('TEST 5: Reused Activation Code Fails', async () => {
    const res = await request(app)
      .post(`/api/v1/colleges/${collegeA.id}/admins`)
      .set('Authorization', `Bearer ${superAdminToken}`)
      .send({ name: 'Admin Dave', instituteId: 'AIT-ADM-04', email: 'dave@ait.edu' });
    const code = res.body.data.activationCode;

    // First activation succeeds
    const act1 = await request(app).post('/api/v1/auth/activate').send({
      collegeCode: 'AIT',
      instituteId: 'AIT-ADM-04',
      activationCode: code,
      password: 'DavePassword123!',
    });
    expect(act1.status).toBe(200);

    // Second activation with same code fails
    const act2 = await request(app).post('/api/v1/auth/activate').send({
      collegeCode: 'AIT',
      instituteId: 'AIT-ADM-04',
      activationCode: code,
      password: 'AnotherPassword456!',
    });
    expect(act2.status).toBe(400);
    expect(act2.body.error.message).toContain('already been activated');
  });

  test('TEST 6: Wrong College Code Fails', async () => {
    const res = await request(app)
      .post(`/api/v1/colleges/${collegeA.id}/admins`)
      .set('Authorization', `Bearer ${superAdminToken}`)
      .send({ name: 'Admin Eve', instituteId: 'AIT-ADM-05', email: 'eve@ait.edu' });
    const code = res.body.data.activationCode;

    const act = await request(app).post('/api/v1/auth/activate').send({
      collegeCode: 'NONEXISTENT_COLLEGE',
      instituteId: 'AIT-ADM-05',
      activationCode: code,
      password: 'EvePassword123!',
    });
    expect(act.status).toBe(400);
    expect(act.body.error.message).toContain('Invalid activation details');
  });

  test('TEST 7: Wrong PIN Number / instituteId Fails', async () => {
    const res = await request(app)
      .post(`/api/v1/colleges/${collegeA.id}/admins`)
      .set('Authorization', `Bearer ${superAdminToken}`)
      .send({ name: 'Admin Frank', instituteId: 'AIT-ADM-06', email: 'frank@ait.edu' });
    const code = res.body.data.activationCode;

    const act = await request(app).post('/api/v1/auth/activate').send({
      collegeCode: 'AIT',
      instituteId: 'WRONG-PIN-999',
      activationCode: code,
      password: 'FrankPassword123!',
    });
    expect(act.status).toBe(400);
    expect(act.body.error.message).toContain('Invalid activation details');
  });

  test('TEST 8: Expired Invitation Fails', async () => {
    const res = await request(app)
      .post(`/api/v1/colleges/${collegeA.id}/admins`)
      .set('Authorization', `Bearer ${superAdminToken}`)
      .send({ name: 'Admin Grace', instituteId: 'AIT-ADM-07', email: 'grace@ait.edu' });
    const code = res.body.data.activationCode;
    const invId = res.body.data.invitation.id;

    // Manually expire the invitation in DB
    await Invitation.findByIdAndUpdate(invId, { expiresAt: new Date(Date.now() - 1000) });

    const act = await request(app).post('/api/v1/auth/activate').send({
      collegeCode: 'AIT',
      instituteId: 'AIT-ADM-07',
      activationCode: code,
      password: 'GracePassword123!',
    });
    expect(act.status).toBe(400);
    expect(act.body.error.message).toContain('expired');
  });

  test('TEST 9 & 10: Successful Activation followed by Login with PIN Number & with Email', async () => {
    const res = await request(app)
      .post(`/api/v1/colleges/${collegeA.id}/admins`)
      .set('Authorization', `Bearer ${superAdminToken}`)
      .send({ name: 'Admin Heidi', instituteId: 'AIT-ADM-08', email: 'heidi@ait.edu' });
    const code = res.body.data.activationCode;

    // Activate
    const act = await request(app).post('/api/v1/auth/activate').send({
      collegeCode: 'AIT',
      instituteId: 'AIT-ADM-08',
      activationCode: code,
      password: 'HeidiPassword123!',
    });
    expect(act.status).toBe(200);

    // Login using Email
    const loginEmail = await request(app).post('/api/v1/auth/login').send({
      identifier: 'heidi@ait.edu',
      password: 'HeidiPassword123!',
    });
    expect(loginEmail.status).toBe(200);
    expect(loginEmail.body.data.accessToken).toBeDefined();

    // Login using PIN Number (instituteId)
    const loginPin = await request(app).post('/api/v1/auth/login').send({
      identifier: 'AIT-ADM-08',
      password: 'HeidiPassword123!',
    });
    expect(loginPin.status).toBe(200);
    expect(loginPin.body.data.accessToken).toBeDefined();
  });

  test('TEST 11: Case-Insensitive, Dashed/Undashed, and Whitespace Resilient Activation', async () => {
    const res = await request(app)
      .post(`/api/v1/colleges/${collegeA.id}/admins`)
      .set('Authorization', `Bearer ${superAdminToken}`)
      .send({ name: 'Admin Ivan', instituteId: 'AIT-ADM-09', email: 'ivan@ait.edu' });
    const code = res.body.data.activationCode; // e.g. "XXXX-XXXX-XXXX"

    // Convert code to lowercase and remove dashes: "xxxxxxxxxxxx"
    const strippedCode = code.replace(/-/g, '').toLowerCase();

    // Activate using lowercase college code, lowercase email as PIN, stripped lowercase code
    const act = await request(app).post('/api/v1/auth/activate').send({
      collegeCode: 'ait', // lowercase
      instituteId: 'ivan@ait.edu', // email instead of instituteId
      activationCode: `  ${strippedCode}  `, // spaces and stripped
      password: 'IvanPassword123!',
    });
    expect(act.status).toBe(200);
    expect(act.body.success).toBe(true);
    expect(act.body.data.user.accountStatus).toBe(AccountStatus.ACTIVE);
  });

  test('TEST 12: Multi-Role Chain Provisioning & Activation (SuperAdmin -> CollegeAdmin -> HOD -> Faculty -> Student)', async () => {
    // 1. Super Admin provisions College Admin
    const admRes = await request(app)
      .post(`/api/v1/colleges/${collegeA.id}/admins`)
      .set('Authorization', `Bearer ${superAdminToken}`)
      .send({ name: 'Admin Jack', instituteId: 'AIT-ADM-10', email: 'jack@ait.edu' });
    expect(admRes.status).toBe(201);
    const admCode = admRes.body.data.activationCode;

    // Activate College Admin
    const actAdm = await request(app).post('/api/v1/auth/activate').send({
      collegeCode: 'AIT',
      instituteId: 'AIT-ADM-10',
      activationCode: admCode,
      password: 'JackPassword123!',
    });
    expect(actAdm.status).toBe(200);

    // Login College Admin to get token
    const admLogin = await request(app).post('/api/v1/auth/login').send({
      identifier: 'jack@ait.edu',
      password: 'JackPassword123!',
    });
    const admToken = admLogin.body.data.accessToken;

    // 2. College Admin provisions HOD for Department CSE
    const hodRes = await request(app)
      .post('/api/v1/auth/invitations')
      .set('Authorization', `Bearer ${admToken}`)
      .send({
        name: 'Dr. Karen HOD',
        instituteId: 'AIT-HOD-CSE',
        email: 'karen.hod@ait.edu',
        role: AppRole.HOD,
        departmentId: deptA1.id,
      });
    expect(hodRes.status).toBe(201);
    expect(hodRes.body.data.collegeCode).toBe('AIT');
    const hodCode = hodRes.body.data.activationCode;

    // Activate HOD
    const actHod = await request(app).post('/api/v1/auth/activate').send({
      collegeCode: 'AIT',
      instituteId: 'AIT-HOD-CSE',
      activationCode: hodCode,
      password: 'KarenPassword123!',
    });
    expect(actHod.status).toBe(200);

    // Login HOD to get token
    const hodLogin = await request(app).post('/api/v1/auth/login').send({
      identifier: 'karen.hod@ait.edu',
      password: 'KarenPassword123!',
    });
    const hodToken = hodLogin.body.data.accessToken;

    // 3. HOD provisions Faculty
    const facRes = await request(app)
      .post('/api/v1/auth/invitations')
      .set('Authorization', `Bearer ${hodToken}`)
      .send({
        name: 'Prof. Leo Faculty',
        instituteId: 'AIT-FAC-01',
        email: 'leo.fac@ait.edu',
        role: AppRole.FACULTY,
        departmentId: deptA1.id,
      });
    expect(facRes.status).toBe(201);
    const facCode = facRes.body.data.activationCode;

    // Activate Faculty
    const actFac = await request(app).post('/api/v1/auth/activate').send({
      collegeCode: 'AIT',
      instituteId: 'AIT-FAC-01',
      activationCode: facCode,
      password: 'LeoPassword123!',
    });
    expect(actFac.status).toBe(200);

    // Login Faculty to get token
    const facLogin = await request(app).post('/api/v1/auth/login').send({
      identifier: 'leo.fac@ait.edu',
      password: 'LeoPassword123!',
    });
    const facToken = facLogin.body.data.accessToken;

    // 4. Faculty provisions Student
    const stuRes = await request(app)
      .post('/api/v1/auth/invitations')
      .set('Authorization', `Bearer ${facToken}`)
      .send({
        name: 'Mia Student',
        instituteId: 'AIT-STU-01',
        email: 'mia.student@ait.edu',
        role: AppRole.STUDENT,
        departmentId: deptA1.id,
      });
    expect(stuRes.status).toBe(201);
    const stuCode = stuRes.body.data.activationCode;

    // Activate Student
    const actStu = await request(app).post('/api/v1/auth/activate').send({
      collegeCode: 'AIT',
      instituteId: 'AIT-STU-01',
      activationCode: stuCode,
      password: 'MiaPassword123!',
    });
    expect(actStu.status).toBe(200);
  });

  test('TEST 13: Reissue Invitation Returns Authoritative New Code and Revokes Old Code', async () => {
    // 1. Provision user
    const initRes = await request(app)
      .post(`/api/v1/colleges/${collegeA.id}/admins`)
      .set('Authorization', `Bearer ${superAdminToken}`)
      .send({ name: 'Admin Noah', instituteId: 'AIT-ADM-11', email: 'noah@ait.edu' });
    const oldCode = initRes.body.data.activationCode;
    const invId = initRes.body.data.invitation.id;

    // 2. Reissue invitation
    const reissueRes = await request(app)
      .post(`/api/v1/auth/invitations/${invId}/reissue`)
      .set('Authorization', `Bearer ${superAdminToken}`);

    expect(reissueRes.status).toBe(200);
    expect(reissueRes.body.data.collegeCode).toBe('AIT');
    const newCode = reissueRes.body.data.activationCode;
    expect(newCode).not.toBe(oldCode);

    // 3. Old code fails
    const actOld = await request(app).post('/api/v1/auth/activate').send({
      collegeCode: 'AIT',
      instituteId: 'AIT-ADM-11',
      activationCode: oldCode,
      password: 'NoahPassword123!',
    });
    expect(actOld.status).toBe(400);
    expect(actOld.body.error.message).toContain('Invalid activation code');

    // 4. New code succeeds
    const actNew = await request(app).post('/api/v1/auth/activate').send({
      collegeCode: 'AIT',
      instituteId: 'AIT-ADM-11',
      activationCode: newCode,
      password: 'NoahPassword123!',
    });
    expect(actNew.status).toBe(200);
  });
});
