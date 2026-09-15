import request from 'supertest';
import { app } from '../../src/app';
import { College } from '../../src/models/college.model';
import { User } from '../../src/models/user.model';
import { Department } from '../../src/models/department.model';
import { Course } from '../../src/models/course.model';
import { AcademicYear } from '../../src/models/academicYear.model';
import { Semester } from '../../src/models/semester.model';
import { Section } from '../../src/models/section.model';
import { Subject } from '../../src/models/subject.model';
import { AuditLog } from '../../src/models/auditLog.model';
import { AppRole } from '../../src/constants/roles';
import { AccountStatus, CollegeStatus, DepartmentStatus } from '../../src/constants/status';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';

describe('ACADEX — HOD Academic Structure: Sections & Subjects (Prompt 2 of 6)', () => {
  let collegeA: InstanceType<typeof College>;
  let collegeB: InstanceType<typeof College>;

  let deptA1: InstanceType<typeof Department>; // HOD A1's department (e.g. Computer Engineering)
  let deptA2: InstanceType<typeof Department>; // Another department in College A (e.g. Electrical)
  let deptB1: InstanceType<typeof Department>; // Department in College B

  let hodA1: InstanceType<typeof User>;
  let collegeAdminA: InstanceType<typeof User>;
  let facultyA1: InstanceType<typeof User>;
  let studentA1: InstanceType<typeof User>;

  let hodA1Header: { Authorization: string };
  let collegeAdminAHeader: { Authorization: string };
  let facultyA1Header: { Authorization: string };
  let studentA1Header: { Authorization: string };

  let courseA1: InstanceType<typeof Course>;
  let courseA2: InstanceType<typeof Course>;
  let courseB1: InstanceType<typeof Course>;

  let ayA: InstanceType<typeof AcademicYear>;
  let ayB: InstanceType<typeof AcademicYear>;

  let semesterA1: InstanceType<typeof Semester>;
  let semesterA2: InstanceType<typeof Semester>;
  let semesterB1: InstanceType<typeof Semester>;

  const defaultPasswordHash = '$2b$10$FakeHashForTestingOnlyValue1234567890';

  beforeAll(async () => {
    await setupTestDB();
    await College.init();
    await User.init();
    await Department.init();
    await Course.init();
    await AcademicYear.init();
    await Semester.init();
    await Section.init();
    await Subject.init();
    await AuditLog.init();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();

    collegeA = await College.create({
      name: 'College of Engineering A',
      code: 'COEA',
      address: 'Campus A, Tech City',
      email: 'admin@college-a.edu',
      phone: '+919876543210',
      principal: 'Dr. Principal A',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });

    collegeB = await College.create({
      name: 'College of Technology B',
      code: 'COTB',
      address: 'Campus B, Tech City',
      email: 'admin@college-b.edu',
      phone: '+919876543211',
      principal: 'Dr. Principal B',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });

    deptA1 = await Department.create({
      collegeId: collegeA._id,
      name: 'Computer Engineering',
      code: 'CME',
      description: 'Department of Computer Engineering',
      status: DepartmentStatus.ACTIVE,
      isActive: true,
    });

    deptA2 = await Department.create({
      collegeId: collegeA._id,
      name: 'Electrical Engineering',
      code: 'EEE',
      description: 'Department of Electrical Engineering',
      status: DepartmentStatus.ACTIVE,
      isActive: true,
    });

    deptB1 = await Department.create({
      collegeId: collegeB._id,
      name: 'Mechanical Engineering',
      code: 'MEC',
      description: 'Department of Mechanical Engineering',
      status: DepartmentStatus.ACTIVE,
      isActive: true,
    });

    hodA1 = await User.create({
      instituteId: 'HOD-CME-01',
      name: 'Alan Turing',
      email: 'hod.cme@college-a.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.HOD,
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    collegeAdminA = await User.create({
      instituteId: 'ADMIN-A-01',
      name: 'Admin Alpha',
      email: 'admin@college-a.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.COLLEGE_ADMIN,
      collegeId: collegeA._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    facultyA1 = await User.create({
      instituteId: 'FAC-CME-01',
      name: 'Grace Hopper',
      email: 'faculty.cme@college-a.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.FACULTY,
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    studentA1 = await User.create({
      instituteId: 'STU-CME-01',
      name: 'Ada Lovelace',
      email: 'student.cme@college-a.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.STUDENT,
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    hodA1Header = createTestAuthHeader({
      userId: hodA1.id,
      instituteId: hodA1.instituteId,
      collegeId: collegeA.id,
      departmentId: deptA1.id,
      role: AppRole.HOD,
    });

    collegeAdminAHeader = createTestAuthHeader({
      userId: collegeAdminA.id,
      instituteId: collegeAdminA.instituteId,
      collegeId: collegeA.id,
      role: AppRole.COLLEGE_ADMIN,
    });

    facultyA1Header = createTestAuthHeader({
      userId: facultyA1.id,
      instituteId: facultyA1.instituteId,
      collegeId: collegeA.id,
      departmentId: deptA1.id,
      role: AppRole.FACULTY,
    });

    studentA1Header = createTestAuthHeader({
      userId: studentA1.id,
      instituteId: studentA1.instituteId,
      collegeId: collegeA.id,
      departmentId: deptA1.id,
      role: AppRole.STUDENT,
    });

    // Foundation setup (Prompt 1)
    courseA1 = await Course.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      name: 'Diploma in Computer Engineering',
      code: 'DCME',
      durationYears: 3,
      totalSemesters: 6,
      isActive: true,
    });

    courseA2 = await Course.create({
      collegeId: collegeA._id,
      departmentId: deptA2._id,
      name: 'Diploma in Electrical Engineering',
      code: 'DEEE',
      durationYears: 3,
      totalSemesters: 6,
      isActive: true,
    });

    courseB1 = await Course.create({
      collegeId: collegeB._id,
      departmentId: deptB1._id,
      name: 'Diploma in Mechanical Engineering',
      code: 'DMEC',
      durationYears: 3,
      totalSemesters: 6,
      isActive: true,
    });

    ayA = await AcademicYear.create({
      collegeId: collegeA._id,
      name: '2026-2027',
      startDate: new Date('2026-06-01T00:00:00.000Z'),
      endDate: new Date('2027-05-31T23:59:59.000Z'),
      isCurrent: true,
      isActive: true,
    });

    ayB = await AcademicYear.create({
      collegeId: collegeB._id,
      name: '2026-2027',
      startDate: new Date('2026-06-01T00:00:00.000Z'),
      endDate: new Date('2027-05-31T23:59:59.000Z'),
      isCurrent: true,
      isActive: true,
    });

    semesterA1 = await Semester.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      courseId: courseA1._id,
      academicYearId: ayA._id,
      name: 'Semester 1',
      number: 1,
      startDate: new Date('2026-06-01T00:00:00.000Z'),
      endDate: new Date('2026-11-30T23:59:59.000Z'),
      isCurrent: true,
      isActive: true,
    });

    semesterA2 = await Semester.create({
      collegeId: collegeA._id,
      departmentId: deptA2._id,
      courseId: courseA2._id,
      academicYearId: ayA._id,
      name: 'Semester 1',
      number: 1,
      startDate: new Date('2026-06-01T00:00:00.000Z'),
      endDate: new Date('2026-11-30T23:59:59.000Z'),
      isCurrent: true,
      isActive: true,
    });

    semesterB1 = await Semester.create({
      collegeId: collegeB._id,
      departmentId: deptB1._id,
      courseId: courseB1._id,
      academicYearId: ayB._id,
      name: 'Semester 1',
      number: 1,
      startDate: new Date('2026-06-01T00:00:00.000Z'),
      endDate: new Date('2026-11-30T23:59:59.000Z'),
      isCurrent: true,
      isActive: true,
    });
  });

  // =========================================================================
  // SECTIONS
  // =========================================================================

  test('1. HOD creates valid Section within own department and semester context', async () => {
    const res = await request(app)
      .post('/api/v1/academics/sections')
      .set(hodA1Header)
      .send({
        courseId: courseA1.id,
        academicYearId: ayA.id,
        semesterId: semesterA1.id,
        name: 'Section A',
        capacity: 60,
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.name).toBe('SECTION A');
    expect(res.body.data.capacity).toBe(60);
    expect(res.body.data.departmentId).toBe(deptA1.id);
    expect(res.body.data.courseId).toBe(courseA1.id);
    expect(res.body.data.semesterId).toBe(semesterA1.id);
    expect(res.body.data.academicYearId).toBe(ayA.id);
  });

  test('2. HOD cannot create Section outside own department', async () => {
    // Attempting to create section in courseA2 (deptA2, Electrical)
    const res = await request(app)
      .post('/api/v1/academics/sections')
      .set(hodA1Header)
      .send({
        courseId: courseA2.id,
        academicYearId: ayA.id,
        semesterId: semesterA2.id,
        name: 'Section A',
      });

    expect(res.status).toBe(403);
    expect(res.body.error.message).toMatch(/assigned department/i);
  });

  test('3. HOD cannot create Section using mismatched Course/Semester context', async () => {
    // Attempting to create section with courseA1 but semesterA2 (belongs to courseA2)
    const res = await request(app)
      .post('/api/v1/academics/sections')
      .set(hodA1Header)
      .send({
        courseId: courseA1.id,
        academicYearId: ayA.id,
        semesterId: semesterA2.id,
        name: 'Section A',
      });

    expect(res.status).toBe(400);
    expect(res.body.error.message).toMatch(/does not match the provided course/i);
  });

  test('4. Duplicate Section name in the same semester is rejected (409 Conflict)', async () => {
    // Create Section A
    await request(app)
      .post('/api/v1/academics/sections')
      .set(hodA1Header)
      .send({
        courseId: courseA1.id,
        academicYearId: ayA.id,
        semesterId: semesterA1.id,
        name: 'Section A',
      });

    // Attempt duplicate Section A in same semester
    const res = await request(app)
      .post('/api/v1/academics/sections')
      .set(hodA1Header)
      .send({
        courseId: courseA1.id,
        academicYearId: ayA.id,
        semesterId: semesterA1.id,
        name: 'SECTION A',
      });

    expect(res.status).toBe(409);
    expect(res.body.error.message).toMatch(/already exists/i);
  });

  test('5. Updating Section to duplicate name in the same semester is rejected', async () => {
    // Create Section A and Section B
    await request(app)
      .post('/api/v1/academics/sections')
      .set(hodA1Header)
      .send({
        courseId: courseA1.id,
        semesterId: semesterA1.id,
        name: 'Section A',
      });
    const secBRes = await request(app)
      .post('/api/v1/academics/sections')
      .set(hodA1Header)
      .send({
        courseId: courseA1.id,
        semesterId: semesterA1.id,
        name: 'Section B',
      });

    const secBId = secBRes.body.data.id;

    // Try renaming Section B to Section A
    const res = await request(app)
      .put(`/api/v1/academics/sections/${secBId}`)
      .set(hodA1Header)
      .send({ name: 'Section A' });

    expect(res.status).toBe(409);
    expect(res.body.error.message).toMatch(/already exists/i);
  });

  test('6. Cross-college Section creation/access is strictly rejected', async () => {
    // HOD A1 tries to create section in College B course/semester
    const createRes = await request(app)
      .post('/api/v1/academics/sections')
      .set(hodA1Header)
      .send({
        collegeId: collegeB.id,
        courseId: courseB1.id,
        semesterId: semesterB1.id,
        name: 'Section B1',
      });

    expect([400, 403]).toContain(createRes.status);

    // Create a section in College B directly
    const secB = await Section.create({
      collegeId: collegeB._id,
      departmentId: deptB1._id,
      courseId: courseB1._id,
      academicYearId: ayB._id,
      semesterId: semesterB1._id,
      name: 'SECTION B1',
      capacity: 50,
      isActive: true,
    });

    // HOD A1 tries to access College B section
    const getRes = await request(app)
      .get(`/api/v1/academics/sections/${secB.id}`)
      .set(hodA1Header);

    expect(getRes.status).toBe(403);
    expect(getRes.body.error.message).toMatch(/strictly prohibited/i);
  });

  test('7. Unauthorized roles (Faculty, Student) cannot create or update Sections, while College Admin can', async () => {
    // College Admin creates section
    const adminRes = await request(app)
      .post('/api/v1/academics/sections')
      .set(collegeAdminAHeader)
      .send({
        courseId: courseA1.id,
        semesterId: semesterA1.id,
        name: 'Section Admin',
      });
    expect(adminRes.status).toBe(201);

    // Faculty tries to create section
    const facRes = await request(app)
      .post('/api/v1/academics/sections')
      .set(facultyA1Header)
      .send({
        courseId: courseA1.id,
        semesterId: semesterA1.id,
        name: 'Section F',
      });
    expect(facRes.status).toBe(403);

    // Student tries to create section
    const stuRes = await request(app)
      .post('/api/v1/academics/sections')
      .set(studentA1Header)
      .send({
        courseId: courseA1.id,
        semesterId: semesterA1.id,
        name: 'Section S',
      });
    expect(stuRes.status).toBe(403);
  });

  // =========================================================================
  // SUBJECTS
  // =========================================================================

  test('8. HOD creates valid Subject within own department and semester context', async () => {
    const res = await request(app)
      .post('/api/v1/academics/subjects')
      .set(hodA1Header)
      .send({
        courseId: courseA1.id,
        semesterId: semesterA1.id,
        academicYearId: ayA.id,
        name: 'Database Management Systems',
        code: 'CE501',
        credits: 4,
        type: 'Theory',
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.name).toBe('Database Management Systems');
    expect(res.body.data.code).toBe('CE501');
    expect(res.body.data.credits).toBe(4);
    expect(res.body.data.type).toBe('Theory');
    expect(res.body.data.departmentId).toBe(deptA1.id);
    expect(res.body.data.courseId).toBe(courseA1.id);
    expect(res.body.data.semesterId).toBe(semesterA1.id);
  });

  test('9. HOD cannot create Subject outside own department', async () => {
    // Attempting to create subject in courseA2 (Electrical)
    const res = await request(app)
      .post('/api/v1/academics/subjects')
      .set(hodA1Header)
      .send({
        courseId: courseA2.id,
        semesterId: semesterA2.id,
        name: 'Power Systems',
        code: 'EE501',
      });

    expect(res.status).toBe(403);
    expect(res.body.error.message).toMatch(/assigned department/i);
  });

  test('10. Subject with invalid academic context is rejected', async () => {
    // Mismatched course and semester
    const res = await request(app)
      .post('/api/v1/academics/subjects')
      .set(hodA1Header)
      .send({
        courseId: courseA1.id,
        semesterId: semesterA2.id, // belongs to courseA2
        name: 'Operating Systems',
        code: 'CE502',
      });

    expect(res.status).toBe(400);
    expect(res.body.error.message).toMatch(/does not belong to the specified course/i);
  });

  test('11. Duplicate Subject code in the same semester is rejected (409 Conflict)', async () => {
    // Create CE501
    await request(app)
      .post('/api/v1/academics/subjects')
      .set(hodA1Header)
      .send({
        courseId: courseA1.id,
        semesterId: semesterA1.id,
        name: 'Database Systems',
        code: 'CE501',
      });

    // Try creating CE501 again in the same semester
    const res = await request(app)
      .post('/api/v1/academics/subjects')
      .set(hodA1Header)
      .send({
        courseId: courseA1.id,
        semesterId: semesterA1.id,
        name: 'Advanced Databases',
        code: 'CE501',
      });

    expect(res.status).toBe(409);
    expect(res.body.error.message).toMatch(/already exists/i);
  });

  test('12. Updating Subject to duplicate code in the same semester is rejected', async () => {
    // Create CE501 and CE502
    await request(app)
      .post('/api/v1/academics/subjects')
      .set(hodA1Header)
      .send({
        courseId: courseA1.id,
        semesterId: semesterA1.id,
        name: 'Database Systems',
        code: 'CE501',
      });

    const sub2Res = await request(app)
      .post('/api/v1/academics/subjects')
      .set(hodA1Header)
      .send({
        courseId: courseA1.id,
        semesterId: semesterA1.id,
        name: 'Operating Systems',
        code: 'CE502',
      });

    const sub2Id = sub2Res.body.data.id;

    // Try renaming CE502 code to CE501
    const res = await request(app)
      .put(`/api/v1/academics/subjects/${sub2Id}`)
      .set(hodA1Header)
      .send({ code: 'CE501' });

    expect(res.status).toBe(409);
    expect(res.body.error.message).toMatch(/already exists/i);
  });

  test('13. Cross-college Subject creation/access is blocked', async () => {
    // HOD A1 tries to create subject in College B course
    const createRes = await request(app)
      .post('/api/v1/academics/subjects')
      .set(hodA1Header)
      .send({
        collegeId: collegeB.id,
        courseId: courseB1.id,
        semesterId: semesterB1.id,
        name: 'Thermodynamics',
        code: 'ME501',
      });

    expect([400, 403]).toContain(createRes.status);

    // Create a subject in College B directly
    const subB = await Subject.create({
      collegeId: collegeB._id,
      departmentId: deptB1._id,
      courseId: courseB1._id,
      semesterId: semesterB1._id,
      name: 'Thermodynamics',
      code: 'ME501',
      credits: 4,
      isActive: true,
    });

    // HOD A1 tries to get College B subject
    const getRes = await request(app)
      .get(`/api/v1/academics/subjects/${subB.id}`)
      .set(hodA1Header);

    expect(getRes.status).toBe(403);
    expect(getRes.body.error.message).toMatch(/strictly prohibited/i);
  });

  test('14. Unauthorized roles cannot mutate Subjects', async () => {
    // Faculty tries to create subject
    const facRes = await request(app)
      .post('/api/v1/academics/subjects')
      .set(facultyA1Header)
      .send({
        courseId: courseA1.id,
        semesterId: semesterA1.id,
        name: 'Algorithms',
        code: 'CE503',
      });
    expect(facRes.status).toBe(403);

    // Student tries to create subject
    const stuRes = await request(app)
      .post('/api/v1/academics/subjects')
      .set(studentA1Header)
      .send({
        courseId: courseA1.id,
        semesterId: semesterA1.id,
        name: 'Algorithms',
        code: 'CE503',
      });
    expect(stuRes.status).toBe(403);
  });

  // =========================================================================
  // INTEGRITY & SAFE LIFECYCLE
  // =========================================================================

  test('15. Section correctly resolves through Semester -> Course -> Department', async () => {
    const res = await request(app)
      .post('/api/v1/academics/sections')
      .set(hodA1Header)
      .send({
        courseId: courseA1.id,
        semesterId: semesterA1.id,
        name: 'Section A',
        capacity: 45,
      });

    expect(res.status).toBe(201);
    const sec = await Section.findById(res.body.data.id);
    expect(sec).toBeDefined();
    expect(sec!.semesterId.toString()).toBe(semesterA1.id);
    expect(sec!.courseId.toString()).toBe(courseA1.id);
    expect(sec!.departmentId.toString()).toBe(deptA1.id);
    expect(sec!.academicYearId?.toString()).toBe(ayA.id);
  });

  test('16. Subject correctly resolves through Semester -> Course -> Department', async () => {
    const res = await request(app)
      .post('/api/v1/academics/subjects')
      .set(hodA1Header)
      .send({
        courseId: courseA1.id,
        semesterId: semesterA1.id,
        name: 'Computer Networks',
        code: 'CE504',
        credits: 3,
      });

    expect(res.status).toBe(201);
    const sub = await Subject.findById(res.body.data.id);
    expect(sub).toBeDefined();
    expect(sub!.semesterId.toString()).toBe(semesterA1.id);
    expect(sub!.courseId?.toString()).toBe(courseA1.id);
    expect(sub!.departmentId.toString()).toBe(deptA1.id);
  });

  test('17. Safe deactivation preserves Section and Subject without deletion', async () => {
    const secRes = await request(app)
      .post('/api/v1/academics/sections')
      .set(hodA1Header)
      .send({
        courseId: courseA1.id,
        semesterId: semesterA1.id,
        name: 'Section Deact',
      });
    const subRes = await request(app)
      .post('/api/v1/academics/subjects')
      .set(hodA1Header)
      .send({
        courseId: courseA1.id,
        semesterId: semesterA1.id,
        name: 'Subject Deact',
        code: 'CE999',
      });

    const secId = secRes.body.data.id;
    const subId = subRes.body.data.id;

    // Deactivate section
    const deactSecRes = await request(app)
      .put(`/api/v1/academics/sections/${secId}`)
      .set(hodA1Header)
      .send({ isActive: false });
    expect(deactSecRes.status).toBe(200);
    expect(deactSecRes.body.data.isActive).toBe(false);

    // Deactivate subject
    const deactSubRes = await request(app)
      .put(`/api/v1/academics/subjects/${subId}`)
      .set(hodA1Header)
      .send({ isActive: false });
    expect(deactSubRes.status).toBe(200);
    expect(deactSubRes.body.data.isActive).toBe(false);

    // Verify records still exist in database
    const secDb = await Section.findById(secId);
    const subDb = await Subject.findById(subId);
    expect(secDb).not.toBeNull();
    expect(secDb!.isActive).toBe(false);
    expect(subDb).not.toBeNull();
    expect(subDb!.isActive).toBe(false);
  });
});
