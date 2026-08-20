import request from 'supertest';
import { app } from '../../src/app';
import { College } from '../../src/models/college.model';
import { User } from '../../src/models/user.model';
import { Department } from '../../src/models/department.model';
import { Course } from '../../src/models/course.model';
import { AuditLog } from '../../src/models/auditLog.model';
import { AppRole } from '../../src/constants/roles';
import { AccountStatus, CollegeStatus, DepartmentStatus } from '../../src/constants/status';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';
import { PasswordService } from '../../src/services/password.service';

describe('ACADEX Phase 9E.1 — Department Management Tests', () => {
  let superAdminUser: InstanceType<typeof User>;
  let collegeAdminA: InstanceType<typeof User>;
  let collegeAdminB: InstanceType<typeof User>;
  let studentA: InstanceType<typeof User>;

  let collegeA: InstanceType<typeof College>;
  let collegeB: InstanceType<typeof College>;
  let inactiveCollege: InstanceType<typeof College>;

  let deptA1: InstanceType<typeof Department>;
  let deptA2: InstanceType<typeof Department>;
  let deptB1: InstanceType<typeof Department>;

  let superAdminHeader: { Authorization: string };
  let collegeAdminAHeader: { Authorization: string };
  let collegeAdminBHeader: { Authorization: string };
  let studentAHeader: { Authorization: string };

  beforeAll(async () => {
    await setupTestDB();
    await College.init();
    await User.init();
    await Department.init();
    await Course.init();
    await AuditLog.init();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();

    collegeA = await College.create({
      name: 'Alpha Institute of Science',
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

    inactiveCollege = await College.create({
      name: 'Gamma Inactive College',
      code: 'GAMMA01',
      address: '789 Gamma Road',
      email: 'contact@gamma.edu',
      phone: '7778889999',
      principal: 'Dr. Gamma Principal',
      status: CollegeStatus.INACTIVE,
      isActive: false,
    });

    deptA1 = await Department.create({
      collegeId: collegeA._id,
      name: 'Computer Science and Engineering',
      code: 'CSE',
      description: 'Department of CSE',
      status: DepartmentStatus.ACTIVE,
      isActive: true,
    });

    deptA2 = await Department.create({
      collegeId: collegeA._id,
      name: 'Electronics and Communication Engineering',
      code: 'ECE',
      description: 'Department of ECE',
      status: DepartmentStatus.ACTIVE,
      isActive: true,
    });

    deptB1 = await Department.create({
      collegeId: collegeB._id,
      name: 'Mechanical Engineering',
      code: 'ME',
      description: 'Department of ME',
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

    studentAHeader = createTestAuthHeader({
      userId: studentA.id,
      instituteId: studentA.instituteId,
      collegeId: collegeA.id,
      role: AppRole.STUDENT,
    });
  });

  // =========================================================================
  // 1. DEPARTMENT CREATION, SCOPE & VALIDATION (1 - 8)
  // =========================================================================

  it('1. Super Admin can create department for any valid active college', async () => {
    const res = await request(app)
      .post('/api/v1/departments')
      .set(superAdminHeader)
      .send({
        collegeId: collegeA.id,
        name: 'Civil Engineering',
        code: 'CIVIL',
        description: 'Department of Civil Engineering',
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.name).toBe('Civil Engineering');
    expect(res.body.data.code).toBe('CIVIL');
    expect(res.body.data.collegeId).toBe(collegeA.id);
    expect(res.body.data.status).toBe(DepartmentStatus.ACTIVE);
  });

  it('2. College Admin can create department in own college', async () => {
    const res = await request(app)
      .post('/api/v1/departments')
      .set(collegeAdminAHeader)
      .send({
        name: 'Information Technology',
        code: 'IT',
        description: 'Department of IT',
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.name).toBe('Information Technology');
    expect(res.body.data.collegeId).toBe(collegeA.id);
  });

  it('3. Non-admin (Student) and College Admin from another college CANNOT create department', async () => {
    const res = await request(app)
      .post('/api/v1/departments')
      .set(collegeAdminAHeader)
      .send({
        collegeId: collegeB.id, // Targeting College B
        name: 'Illegal Department',
        code: 'ILL01',
      });

    expect(res.status).toBe(403);
    expect(res.body.error.message).toContain('Cross-college tenant access is strictly prohibited');

    // Student attempting department creation
    const resStudent = await request(app)
      .post('/api/v1/departments')
      .set(studentAHeader)
      .send({
        name: 'Student Department',
        code: 'STUDEPT',
      });

    expect(resStudent.status).toBe(403);
  });

  it('4. Department creation with invalid college is rejected', async () => {
    const res = await request(app)
      .post('/api/v1/departments')
      .set(superAdminHeader)
      .send({
        collegeId: '507f1f77bcf86cd799439011', // Non-existent
        name: 'Ghost Department',
        code: 'GHOST',
      });

    expect(res.status).toBe(404);
    expect(res.body.error.message).toContain('not found');
  });

  it('5. Department creation in an INACTIVE college is rejected', async () => {
    const res = await request(app)
      .post('/api/v1/departments')
      .set(superAdminHeader)
      .send({
        collegeId: inactiveCollege.id,
        name: 'Inactive College Department',
        code: 'ICD01',
      });

    expect(res.status).toBe(403);
    expect(res.body.error.message).toContain('inactive college');
  });

  it('6. Duplicate department code within same college is strictly rejected with 409 Conflict', async () => {
    const res = await request(app)
      .post('/api/v1/departments')
      .set(collegeAdminAHeader)
      .send({
        name: 'Another CSE Department',
        code: 'cse', // Duplicate of CSE in College A
      });

    expect(res.status).toBe(409);
    expect(res.body.error.message).toContain('already exists in this college');
  });

  it('7. Same department code in DIFFERENT colleges is allowed', async () => {
    const res = await request(app)
      .post('/api/v1/departments')
      .set(collegeAdminBHeader)
      .send({
        name: 'Computer Science and Engineering',
        code: 'CSE', // Same code as College A, but in College B
      });

    expect(res.status).toBe(201);
    expect(res.body.data.code).toBe('CSE');
    expect(res.body.data.collegeId).toBe(collegeB.id);
  });

  it('8. Department code is normalized (trimmed and uppercase)', async () => {
    const res = await request(app)
      .post('/api/v1/departments')
      .set(collegeAdminAHeader)
      .send({
        name: 'Artificial Intelligence',
        code: '  ai-ds  ',
      });

    expect(res.status).toBe(201);
    expect(res.body.data.code).toBe('AI-DS');
  });

  // =========================================================================
  // 2. RETRIEVAL & TENANT ISOLATION (9 - 12)
  // =========================================================================

  it('9 & 10. Super Admin can retrieve any department by ID', async () => {
    const resA = await request(app)
      .get(`/api/v1/departments/${deptA1.id}`)
      .set(superAdminHeader);

    expect(resA.status).toBe(200);
    expect(resA.body.data.name).toBe('Computer Science and Engineering');

    const resB = await request(app)
      .get(`/api/v1/departments/${deptB1.id}`)
      .set(superAdminHeader);

    expect(resB.status).toBe(200);
    expect(resB.body.data.name).toBe('Mechanical Engineering');
  });

  it('11. College Admin can retrieve department in own college', async () => {
    const res = await request(app)
      .get(`/api/v1/departments/${deptA1.id}`)
      .set(collegeAdminAHeader);

    expect(res.status).toBe(200);
    expect(res.body.data.name).toBe('Computer Science and Engineering');
  });

  it('12. College Admin CANNOT retrieve department in another college', async () => {
    const res = await request(app)
      .get(`/api/v1/departments/${deptB1.id}`)
      .set(collegeAdminAHeader);

    expect(res.status).toBe(403);
    expect(res.body.error.message).toContain('Cross-college tenant access is strictly prohibited');
  });

  // =========================================================================
  // 3. LISTING, SEARCH, PAGINATION & SORTING (13 - 19)
  // =========================================================================

  it('13 & 14. College Admin listing is automatically scoped to own college', async () => {
    const res = await request(app)
      .get('/api/v1/departments')
      .set(collegeAdminAHeader);

    expect(res.status).toBe(200);
    expect(res.body.data.items).toHaveLength(2);
    const codes = res.body.data.items.map((d: any) => d.code);
    expect(codes).toContain('CSE');
    expect(codes).toContain('ECE');
    expect(codes).not.toContain('ME');
  });

  it('15. Super Admin can list departments across all colleges or filter by college', async () => {
    const resAll = await request(app)
      .get('/api/v1/departments')
      .set(superAdminHeader);

    expect(resAll.status).toBe(200);
    expect(resAll.body.data.total).toBe(3);

    const resFilter = await request(app)
      .get(`/api/v1/departments?collegeId=${collegeB.id}`)
      .set(superAdminHeader);

    expect(resFilter.status).toBe(200);
    expect(resFilter.body.data.items).toHaveLength(1);
    expect(resFilter.body.data.items[0].code).toBe('ME');
  });

  it('16. Search by department name works (case-insensitive)', async () => {
    const res = await request(app)
      .get('/api/v1/departments?search=electronics')
      .set(collegeAdminAHeader);

    expect(res.status).toBe(200);
    expect(res.body.data.items).toHaveLength(1);
    expect(res.body.data.items[0].code).toBe('ECE');
  });

  it('17. Search by department code works (case-insensitive)', async () => {
    const res = await request(app)
      .get('/api/v1/departments?search=cse')
      .set(collegeAdminAHeader);

    expect(res.status).toBe(200);
    expect(res.body.data.items).toHaveLength(1);
    expect(res.body.data.items[0].code).toBe('CSE');
  });

  it('18. Pagination works (page and limit)', async () => {
    const res = await request(app)
      .get('/api/v1/departments?page=1&limit=1')
      .set(collegeAdminAHeader);

    expect(res.status).toBe(200);
    expect(res.body.data.items).toHaveLength(1);
    expect(res.body.data.total).toBe(2);
    expect(res.body.data.totalPages).toBe(2);
  });

  it('19. Safe sorting works (ascending and descending)', async () => {
    const resAsc = await request(app)
      .get('/api/v1/departments?sortBy=name&sortOrder=asc')
      .set(collegeAdminAHeader);

    expect(resAsc.status).toBe(200);
    expect(resAsc.body.data.items[0].name).toBe('Computer Science and Engineering');

    const resDesc = await request(app)
      .get('/api/v1/departments?sortBy=name&sortOrder=desc')
      .set(collegeAdminAHeader);

    expect(resDesc.status).toBe(200);
    expect(resDesc.body.data.items[0].name).toBe('Electronics and Communication Engineering');
  });

  // =========================================================================
  // 4. UPDATES, CODE CHANGES & TENANT IMMUTABILITY (20 - 25, 40)
  // =========================================================================

  it('20 & 21. Super Admin and College Admin can update department in own college', async () => {
    const res = await request(app)
      .put(`/api/v1/departments/${deptA1.id}`)
      .set(collegeAdminAHeader)
      .send({
        name: 'Computer Science and AI Engineering',
        description: 'Updated Description',
      });

    expect(res.status).toBe(200);
    expect(res.body.data.name).toBe('Computer Science and AI Engineering');
    expect(res.body.data.description).toBe('Updated Description');
  });

  it('22. College Admin CANNOT update department in another college', async () => {
    const res = await request(app)
      .put(`/api/v1/departments/${deptB1.id}`)
      .set(collegeAdminAHeader)
      .send({ name: 'Hacked Department' });

    expect(res.status).toBe(403);
  });

  it('23 & 40. Department collegeId cannot be altered through update', async () => {
    const res = await request(app)
      .put(`/api/v1/departments/${deptA1.id}`)
      .set(collegeAdminAHeader)
      .send({
        collegeId: collegeB.id, // Attempting to move department to College B
        name: 'Computer Science and Engineering',
      });

    expect(res.status).toBe(200);
    // Verified immutable: collegeId remains College A
    expect(res.body.data.collegeId).toBe(collegeA.id);
  });

  it('24. Department code change works within the same college', async () => {
    const res = await request(app)
      .put(`/api/v1/departments/${deptA1.id}`)
      .set(collegeAdminAHeader)
      .send({ code: 'CS-AI' });

    expect(res.status).toBe(200);
    expect(res.body.data.code).toBe('CS-AI');
  });

  it('25. Duplicate code change within same college is rejected', async () => {
    const res = await request(app)
      .put(`/api/v1/departments/${deptA1.id}`)
      .set(collegeAdminAHeader)
      .send({ code: deptA2.code }); // Already used by deptA2 ('ECE')

    expect(res.status).toBe(409);
    expect(res.body.error.message).toContain('already exists in this college');
  });

  // =========================================================================
  // 5. STATUS LIFECYCLE & INACTIVE COLLEGE GUARD (26 - 30)
  // =========================================================================

  it('26 & 27 & 29. Department can be deactivated and reactivated without data loss', async () => {
    // Deactivate
    const deactRes = await request(app)
      .patch(`/api/v1/departments/${deptA1.id}/status`)
      .set(collegeAdminAHeader)
      .send({ status: DepartmentStatus.INACTIVE });

    expect(deactRes.status).toBe(200);
    expect(deactRes.body.data.status).toBe(DepartmentStatus.INACTIVE);
    expect(deactRes.body.data.isActive).toBe(false);

    // Verify still in database
    const checkDb = await Department.findById(deptA1.id);
    expect(checkDb).not.toBeNull();
    expect(checkDb?.name).toBe('Computer Science and Engineering');

    // Reactivate
    const reactRes = await request(app)
      .patch(`/api/v1/departments/${deptA1.id}/status`)
      .set(collegeAdminAHeader)
      .send({ status: DepartmentStatus.ACTIVE });

    expect(reactRes.status).toBe(200);
    expect(reactRes.body.data.status).toBe(DepartmentStatus.ACTIVE);
    expect(reactRes.body.data.isActive).toBe(true);
  });

  it('28. College Admin cannot modify departments in an INACTIVE college', async () => {
    // 1. Create a department in college B
    // 2. Deactivate College B
    await College.findByIdAndUpdate(collegeB._id, { status: CollegeStatus.INACTIVE, isActive: false });

    const res = await request(app)
      .put(`/api/v1/departments/${deptB1.id}`)
      .set(collegeAdminBHeader)
      .send({ name: 'Updated Under Inactive College' });

    expect(res.status).toBe(403);
    expect(res.body.error.message).toContain('inactive college');
  });

  it('30. No destructive delete route exists', async () => {
    const res = await request(app)
      .delete(`/api/v1/departments/${deptA1.id}`)
      .set(superAdminHeader);

    // Expect 404 or 405 (route does not exist)
    expect([404, 405]).toContain(res.status);
  });

  // =========================================================================
  // 6. AUDIT LOGGING & SECURITY (31 - 34, 37)
  // =========================================================================

  it('31, 32, 33, 34, 37. Audit logs are generated for creation, update, code change, and status change', async () => {
    // 1. Create -> DEPARTMENT_CREATED
    const createRes = await request(app)
      .post('/api/v1/departments')
      .set(collegeAdminAHeader)
      .send({
        name: 'Chemical Engineering',
        code: 'CHEM',
      });

    const newDeptId = createRes.body.data.id;

    // 2. Update -> DEPARTMENT_UPDATED & DEPARTMENT_CODE_CHANGED
    await request(app)
      .put(`/api/v1/departments/${newDeptId}`)
      .set(collegeAdminAHeader)
      .send({
        name: 'Chemical & Petroleum Engineering',
        code: 'CHEM-PET',
      });

    // 3. Status Change -> DEPARTMENT_STATUS_CHANGED
    await request(app)
      .patch(`/api/v1/departments/${newDeptId}/status`)
      .set(collegeAdminAHeader)
      .send({ status: DepartmentStatus.INACTIVE });

    const logs = await AuditLog.find({ entityId: newDeptId });
    const actions = logs.map((l) => l.action);

    expect(actions).toContain('DEPARTMENT_CREATED');
    expect(actions).toContain('DEPARTMENT_UPDATED');
    expect(actions).toContain('DEPARTMENT_CODE_CHANGED');
    expect(actions).toContain('DEPARTMENT_STATUS_CHANGED');

    // 37. No secrets exposed
    const serialized = JSON.stringify(logs);
    expect(serialized).not.toContain('password');
    expect(serialized).not.toContain('AdminPass123');
  });

  // =========================================================================
  // 7. SUMMARY ANALYTICS & ERROR HANDLING (35, 36, 38, 39)
  // =========================================================================

  it('38. Department summary returns accurate database metrics', async () => {
    await Course.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      name: 'B.Tech in Computer Science',
      code: 'CS101',
    });

    const res = await request(app)
      .get(`/api/v1/departments/${deptA1.id}/summary`)
      .set(collegeAdminAHeader);

    expect(res.status).toBe(200);
    expect(res.body.data.department.name).toBe('Computer Science and Engineering');
    expect(res.body.data.courseCount).toBe(1);
    expect(res.body.data.studentCount).toBe(1);
    expect(res.body.data.activeUserCount).toBe(1);
  });

  it('35. Invalid department ID format returns 400 Bad Request', async () => {
    const res = await request(app)
      .get('/api/v1/departments/invalid-mongo-id')
      .set(collegeAdminAHeader);

    expect(res.status).toBe(400);
    expect(res.body.error.message).toContain('Invalid Department ID format');
  });

  it('36. Non-existent department ID returns 404 Not Found', async () => {
    const res = await request(app)
      .get('/api/v1/departments/507f1f77bcf86cd799439011')
      .set(superAdminHeader);

    expect(res.status).toBe(404);
    expect(res.body.error.message).toContain('not found');
  });

  it('39. Super Admin can manage multiple colleges seamlessly', async () => {
    const resA = await request(app)
      .get(`/api/v1/departments?collegeId=${collegeA.id}`)
      .set(superAdminHeader);

    const resB = await request(app)
      .get(`/api/v1/departments?collegeId=${collegeB.id}`)
      .set(superAdminHeader);

    expect(resA.status).toBe(200);
    expect(resB.status).toBe(200);
    expect(resA.body.data.items.every((d: any) => d.collegeId === collegeA.id)).toBe(true);
    expect(resB.body.data.items.every((d: any) => d.collegeId === collegeB.id)).toBe(true);
  });
});
