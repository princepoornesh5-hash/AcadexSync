import request from 'supertest';
import { app } from '../../src/app';
import { College } from '../../src/models/college.model';
import { Department } from '../../src/models/department.model';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';
import { AppRole } from '../../src/constants/roles';

describe('Multi-Tenant College Isolation Security Tests', () => {
  let collegeA: InstanceType<typeof College>;
  let collegeB: InstanceType<typeof College>;

  beforeAll(async () => {
    await setupTestDB();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();

    collegeA = await College.create({
      name: 'Alpha Engineering College',
      code: 'AEC',
      address: 'Alpha Campus, 1st Ave',
      email: 'admin@alpha.edu',
      phone: '+1-555-0100',
      principal: 'Dr. Alpha Principal',
    });

    collegeB = await College.create({
      name: 'Beta Technology Institute',
      code: 'BTI',
      address: 'Beta Campus, 2nd Blvd',
      email: 'admin@beta.edu',
      phone: '+1-555-0200',
      principal: 'Dr. Beta Principal',
    });
  });

  it('College Admin should successfully create and read department in own college', async () => {
    const authHeader = createTestAuthHeader({
      role: AppRole.COLLEGE_ADMIN,
      userId: 'usr_admin_a',
      instituteId: 'ADMIN-A-001',
      collegeId: collegeA.id,
    });

    const res = await request(app)
      .post('/api/v1/departments')
      .set(authHeader)
      .send({
        name: 'Computer Science & Engineering',
        code: 'CSE',
        description: 'Department of Computer Science',
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.code).toBe('CSE');
    expect(res.body.data.collegeId).toBe(collegeA.id);

    // List departments for College A
    const listRes = await request(app)
      .get('/api/v1/departments')
      .set(authHeader);

    expect(listRes.status).toBe(200);
    expect(listRes.body.data.items).toHaveLength(1);
    expect(listRes.body.data.items[0].code).toBe('CSE');
  });

  it('College B user CANNOT access College A departments (Tenant Isolation)', async () => {
    // Create department in College A
    await Department.create({
      collegeId: collegeA._id,
      name: 'Mechanical Engineering',
      code: 'MECH',
    });

    const authHeaderB = createTestAuthHeader({
      role: AppRole.COLLEGE_ADMIN,
      userId: 'usr_admin_b',
      instituteId: 'ADMIN-B-001',
      collegeId: collegeB.id,
    });

    // College B Admin lists departments -> must get empty list (0 departments)
    const listResB = await request(app)
      .get('/api/v1/departments')
      .set(authHeaderB);

    expect(listResB.status).toBe(200);
    expect(listResB.body.data.items).toHaveLength(0);
  });

  it('College B user is FORBIDDEN when explicitly requesting College A target in URL/body', async () => {
    const authHeaderB = createTestAuthHeader({
      role: AppRole.COLLEGE_ADMIN,
      userId: 'usr_admin_b',
      instituteId: 'ADMIN-B-001',
      collegeId: collegeB.id,
    });

    const res = await request(app)
      .post('/api/v1/departments')
      .set(authHeaderB)
      .send({
        collegeId: collegeA.id, // spoofing College A ID
        name: 'Illegal Department',
        code: 'ILL',
      });

    expect(res.status).toBe(403);
    expect(res.body.success).toBe(false);
    expect(res.body.error.message).toContain('Cross-college tenant access is strictly prohibited');
  });

  it('Super Admin can access all colleges and specify target college filter', async () => {
    await Department.create({
      collegeId: collegeA._id,
      name: 'Electrical Engineering',
      code: 'EEE',
    });
    await Department.create({
      collegeId: collegeB._id,
      name: 'Civil Engineering',
      code: 'CIVIL',
    });

    const superAdminHeader = createTestAuthHeader({
      role: AppRole.SUPER_ADMIN,
      userId: 'usr_super',
      instituteId: 'SUPER-001',
    });

    // Super Admin lists all departments
    const resAll = await request(app)
      .get('/api/v1/departments')
      .set(superAdminHeader);

    expect(resAll.status).toBe(200);
    expect(resAll.body.data.items).toHaveLength(2);

    // Super Admin scopes specifically to College A
    const resA = await request(app)
      .get(`/api/v1/departments?collegeId=${collegeA.id}`)
      .set(superAdminHeader);

    expect(resA.status).toBe(200);
    expect(resA.body.data.items).toHaveLength(1);
    expect(resA.body.data.items[0].code).toBe('EEE');
  });
});
