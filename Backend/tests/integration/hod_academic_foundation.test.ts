import request from 'supertest';
import mongoose from 'mongoose';
import { app } from '../../src/app';
import { College } from '../../src/models/college.model';
import { User } from '../../src/models/user.model';
import { Department } from '../../src/models/department.model';
import { Course } from '../../src/models/course.model';
import { AcademicYear } from '../../src/models/academicYear.model';
import { Semester } from '../../src/models/semester.model';
import { AuditLog } from '../../src/models/auditLog.model';
import { AppRole } from '../../src/constants/roles';
import { AccountStatus, CollegeStatus, DepartmentStatus } from '../../src/constants/status';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';

describe('ACADEX — HOD Academic Foundation Integration Tests (Prompt 1 of 6)', () => {
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

  const defaultPasswordHash = '$2b$10$FakeHashForTestingOnlyValue1234567890';

  beforeAll(async () => {
    await setupTestDB();
    await College.init();
    await User.init();
    await Department.init();
    await Course.init();
    await AcademicYear.init();
    await Semester.init();
    await AuditLog.init();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();

    // Setup College A & B
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

    // Departments
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

    // Users
    collegeAdminA = await User.create({
      instituteId: 'ADMIN-A-01',
      name: 'Admin Alpha',
      email: 'admin@college-a.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.COLLEGE_ADMIN,
      collegeId: collegeA._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    hodA1 = await User.create({
      instituteId: 'HOD-CME-01',
      name: 'Dr. Turing',
      email: 'hod.cme@college-a.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.HOD,
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    facultyA1 = await User.create({
      instituteId: 'FAC-CME-01',
      name: 'Prof. Knuth',
      email: 'knuth@college-a.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.FACULTY,
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    studentA1 = await User.create({
      instituteId: 'STU-CME-01',
      name: 'Student Ada',
      email: 'ada@college-a.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.STUDENT,
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    // Auth headers
    collegeAdminAHeader = createTestAuthHeader({
      userId: collegeAdminA.id,
      instituteId: collegeAdminA.instituteId,
      collegeId: collegeA.id,
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

    studentA1Header = createTestAuthHeader({
      userId: studentA1.id,
      instituteId: studentA1.instituteId,
      collegeId: collegeA.id,
      departmentId: deptA1.id,
      role: AppRole.STUDENT,
    });
  });

  // =========================================================================
  // SCENARIO 1: HOD creates valid Course in own department
  // =========================================================================
  it('1. HOD creates valid Course in own department', async () => {
    const res = await request(app)
      .post('/api/v1/academics/courses')
      .set(hodA1Header)
      .send({
        name: 'Diploma in Computer Engineering',
        code: 'DCME',
        duration: 3,
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.name).toBe('Diploma in Computer Engineering');
    expect(res.body.data.code).toBe('DCME');
    expect(res.body.data.departmentId).toBe(deptA1.id);
    expect(res.body.data.collegeId).toBe(collegeA.id);
    expect(res.body.data.isActive).toBe(true);

    const saved = await Course.findById(res.body.data.id);
    expect(saved).not.toBeNull();
    expect(saved?.departmentId.toString()).toBe(deptA1.id);
  });

  // =========================================================================
  // SCENARIO 2: HOD cannot create Course in another department
  // =========================================================================
  it('2. HOD cannot create Course in another department', async () => {
    const res = await request(app)
      .post('/api/v1/academics/courses')
      .set(hodA1Header)
      .send({
        departmentId: deptA2.id, // Electrical Dept, while HOD is in CME
        name: 'Diploma in Electrical Engineering',
        code: 'DEEE',
        duration: 3,
      });

    expect(res.status).toBe(403);
    expect(res.body.success).toBe(false);

    // Verify course was not created
    const course = await Course.findOne({ code: 'DEEE' });
    expect(course).toBeNull();
  });

  // =========================================================================
  // SCENARIO 3: HOD cannot modify another department\'s Course
  // =========================================================================
  it('3. HOD cannot modify another department\'s Course', async () => {
    // Admin creates course in Department A2 (Electrical)
    const courseA2 = await Course.create({
      collegeId: collegeA._id,
      departmentId: deptA2._id,
      name: 'Electrical Engineering',
      code: 'EEE-DIP',
      duration: 3,
      isActive: true,
    });

    // HOD A1 (Computer Dept) tries to update Course A2
    const res = await request(app)
      .put(`/api/v1/academics/courses/${courseA2.id}`)
      .set(hodA1Header)
      .send({
        name: 'Hacked Electrical Course',
      });

    expect(res.status).toBe(403);

    // Verify course was not changed
    const unchanged = await Course.findById(courseA2.id);
    expect(unchanged?.name).toBe('Electrical Engineering');
  });

  // =========================================================================
  // SCENARIO 4: Duplicate Course is rejected according to uniqueness rules
  // =========================================================================
  it('4. Duplicate Course is rejected according to current uniqueness rules', async () => {
    await Course.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      name: 'Diploma in Computer Engineering',
      code: 'DCME',
      duration: 3,
      isActive: true,
    });

    const res = await request(app)
      .post('/api/v1/academics/courses')
      .set(hodA1Header)
      .send({
        name: 'Another Diploma in Computer Engineering',
        code: 'DCME', // Same code
        duration: 3,
      });

    expect(res.status).toBe(409);
    expect(res.body.success).toBe(false);
  });

  // =========================================================================
  // SCENARIO 5: Valid Academic Year behavior works
  // =========================================================================
  it('5. Valid Academic Year behavior works and can be listed by HOD', async () => {
    // College Admin creates global academic session
    const resCreate = await request(app)
      .post('/api/v1/academics/academic-years')
      .set(collegeAdminAHeader)
      .send({
        name: '2026–27',
        startDate: '2026-06-01T00:00:00.000Z',
        endDate: '2027-05-31T23:59:59.000Z',
        isCurrent: true,
      });

    expect(resCreate.status).toBe(201);
    expect(resCreate.body.data.name).toBe('2026–27');
    expect(resCreate.body.data.isCurrent).toBe(true);

    // HOD can list and consume academic years within the college
    const resList = await request(app)
      .get('/api/v1/academics/academic-years')
      .set(hodA1Header);

    expect(resList.status).toBe(200);
    expect(resList.body.data.items.length).toBeGreaterThanOrEqual(1);
    expect(resList.body.data.items[0].name).toBe('2026–27');
  });

  it('5b. HOD can create and update Academic Year within own college', async () => {
    const resHodCreate = await request(app)
      .post('/api/v1/academics/academic-years')
      .set(hodA1Header)
      .send({
        name: '2027–28',
        startDate: '2027-06-01T00:00:00.000Z',
        endDate: '2028-05-31T23:59:59.000Z',
        isCurrent: false,
      });

    expect(resHodCreate.status).toBe(201);
    expect(resHodCreate.body.data.name).toBe('2027–28');
    const createdYearId = resHodCreate.body.data.id;

    // HOD can update the academic year (e.g. set current or update name)
    const resHodUpdate = await request(app)
      .put(`/api/v1/academics/academic-years/${createdYearId}`)
      .set(hodA1Header)
      .send({
        isCurrent: true,
      });

    expect(resHodUpdate.status).toBe(200);
    expect(resHodUpdate.body.data.isCurrent).toBe(true);
  });

  // =========================================================================
  // SCENARIO 6: Invalid/duplicate Academic Year behavior follows domain rules
  // =========================================================================
  it('6. Invalid/duplicate Academic Year behavior follows domain rules', async () => {
    await AcademicYear.create({
      collegeId: collegeA._id,
      name: '2026–27',
      startDate: new Date('2026-06-01'),
      endDate: new Date('2027-05-31'),
      isCurrent: true,
      isActive: true,
    });

    // Duplicate name rejected
    const resDup = await request(app)
      .post('/api/v1/academics/academic-years')
      .set(collegeAdminAHeader)
      .send({
        name: '2026–27',
        startDate: '2026-07-01T00:00:00.000Z',
        endDate: '2027-06-30T23:59:59.000Z',
      });
    expect(resDup.status).toBe(409);

    // Invalid date order (startDate >= endDate) rejected
    const resInvalidDates = await request(app)
      .post('/api/v1/academics/academic-years')
      .set(collegeAdminAHeader)
      .send({
        name: '2028–29',
        startDate: '2029-01-01T00:00:00.000Z',
        endDate: '2028-01-01T00:00:00.000Z',
      });
    expect([400, 422]).toContain(resInvalidDates.status);
  });

  // =========================================================================
  // SCENARIO 7: HOD creates valid Semester for own Course + Academic Year
  // =========================================================================
  it('7. HOD creates valid Semester for own Course + Academic Year', async () => {
    const course = await Course.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      name: 'Diploma in Computer Engineering',
      code: 'DCME',
      duration: 3,
      isActive: true,
    });

    const academicYear = await AcademicYear.create({
      collegeId: collegeA._id,
      name: '2026–27',
      startDate: new Date('2026-06-01'),
      endDate: new Date('2027-05-31'),
      isCurrent: true,
      isActive: true,
    });

    const res = await request(app)
      .post('/api/v1/academics/semesters')
      .set(hodA1Header)
      .send({
        courseId: course.id,
        academicYearId: academicYear.id,
        name: 'Semester 1',
        number: 1,
        isCurrent: true,
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.number).toBe(1);
    expect(res.body.data.departmentId).toBe(deptA1.id);
    expect(res.body.data.courseId).toBe(course.id);
    expect(res.body.data.academicYearId).toBe(academicYear.id);
  });

  // =========================================================================
  // SCENARIO 8: HOD cannot create Semester for another department\'s Course
  // =========================================================================
  it('8. HOD cannot create Semester for another department\'s Course', async () => {
    // Course in Dept A2 (Electrical)
    const courseDeptA2 = await Course.create({
      collegeId: collegeA._id,
      departmentId: deptA2._id,
      name: 'Electrical Course',
      code: 'EE-DIP',
      duration: 3,
      isActive: true,
    });

    const academicYear = await AcademicYear.create({
      collegeId: collegeA._id,
      name: '2026–27',
      startDate: new Date('2026-06-01'),
      endDate: new Date('2027-05-31'),
      isCurrent: true,
      isActive: true,
    });

    // HOD A1 (Computer) tries to create semester for Electrical course
    const res = await request(app)
      .post('/api/v1/academics/semesters')
      .set(hodA1Header)
      .send({
        courseId: courseDeptA2.id,
        academicYearId: academicYear.id,
        name: 'Semester 1',
        number: 1,
      });

    expect(res.status).toBe(403);
    expect(res.body.error.message).toMatch(/HOD can only create semesters for courses in their own department/);
  });

  // =========================================================================
  // SCENARIO 9: Invalid academic context is rejected
  // =========================================================================
  it('9. Invalid academic context is rejected (non-existent or mismatched)', async () => {
    const course = await Course.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      name: 'Computer Course',
      code: 'CS-DIP',
      duration: 3,
      isActive: true,
    });

    const fakeAcademicYearId = new mongoose.Types.ObjectId().toString();

    const res = await request(app)
      .post('/api/v1/academics/semesters')
      .set(hodA1Header)
      .send({
        courseId: course.id,
        academicYearId: fakeAcademicYearId,
        name: 'Semester 1',
        number: 1,
      });

    expect(res.status).toBe(404);
  });

  // =========================================================================
  // SCENARIO 10: Duplicate Semester is rejected
  // =========================================================================
  it('10. Duplicate Semester is rejected for same Course + Academic Year + Number', async () => {
    const course = await Course.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      name: 'Computer Course',
      code: 'CS-DIP',
      duration: 3,
      isActive: true,
    });

    const academicYear = await AcademicYear.create({
      collegeId: collegeA._id,
      name: '2026–27',
      startDate: new Date('2026-06-01'),
      endDate: new Date('2027-05-31'),
      isCurrent: true,
      isActive: true,
    });

    // First Semester 1
    await request(app)
      .post('/api/v1/academics/semesters')
      .set(hodA1Header)
      .send({
        courseId: course.id,
        academicYearId: academicYear.id,
        name: 'Semester 1',
        number: 1,
      });

    // Duplicate Semester 1
    const resDup = await request(app)
      .post('/api/v1/academics/semesters')
      .set(hodA1Header)
      .send({
        courseId: course.id,
        academicYearId: academicYear.id,
        name: 'Semester 1 Duplicate',
        number: 1,
      });

    expect(resDup.status).toBe(409);
    expect(resDup.body.error.message).toMatch(/already exists for this course and academic year/);
  });

  // =========================================================================
  // SCENARIO 11: Student cannot mutate these academic structures
  // =========================================================================
  it('11. Student cannot mutate these academic structures', async () => {
    // Student tries to create course
    const resCourse = await request(app)
      .post('/api/v1/academics/courses')
      .set(studentA1Header)
      .send({
        departmentId: deptA1.id,
        name: 'Student Course',
        code: 'STU101',
      });
    expect(resCourse.status).toBe(403);

    // Student tries to create academic year
    const resYear = await request(app)
      .post('/api/v1/academics/academic-years')
      .set(studentA1Header)
      .send({
        name: '2030-2031',
        startDate: '2030-06-01T00:00:00.000Z',
        endDate: '2031-05-31T23:59:59.000Z',
      });
    expect(resYear.status).toBe(403);

    // Student tries to create semester
    const resSem = await request(app)
      .post('/api/v1/academics/semesters')
      .set(studentA1Header)
      .send({
        courseId: new mongoose.Types.ObjectId().toString(),
        academicYearId: new mongoose.Types.ObjectId().toString(),
        name: 'Student Term',
        number: 1,
      });
    expect(resSem.status).toBe(403);
  });

  // =========================================================================
  // SCENARIO 12: Faculty cannot mutate these academic structures
  // =========================================================================
  it('12. Faculty cannot mutate these academic structures', async () => {
    const resCourse = await request(app)
      .post('/api/v1/academics/courses')
      .set(facultyA1Header)
      .send({
        departmentId: deptA1.id,
        name: 'Faculty Course',
        code: 'FAC101',
      });
    expect(resCourse.status).toBe(403);

    const resYear = await request(app)
      .post('/api/v1/academics/academic-years')
      .set(facultyA1Header)
      .send({
        name: '2030-2031',
        startDate: '2030-06-01T00:00:00.000Z',
        endDate: '2031-05-31T23:59:59.000Z',
      });
    expect(resYear.status).toBe(403);

    const resSem = await request(app)
      .post('/api/v1/academics/semesters')
      .set(facultyA1Header)
      .send({
        courseId: new mongoose.Types.ObjectId().toString(),
        academicYearId: new mongoose.Types.ObjectId().toString(),
        name: 'Faculty Term',
        number: 1,
      });
    expect(resSem.status).toBe(403);
  });

  // =========================================================================
  // SCENARIO 13: Cross-college access is rejected
  // =========================================================================
  it('13. Cross-college access is rejected', async () => {
    // Course in College B
    const courseB = await Course.create({
      collegeId: collegeB._id,
      departmentId: deptB1._id,
      name: 'College B Course',
      code: 'CB-101',
      duration: 4,
      isActive: true,
    });

    // Academic Year in College A
    const yearA = await AcademicYear.create({
      collegeId: collegeA._id,
      name: '2026–27',
      startDate: new Date('2026-06-01'),
      endDate: new Date('2027-05-31'),
      isCurrent: true,
      isActive: true,
    });

    // Try to create semester mixing College B Course with College A Academic Year
    const res = await request(app)
      .post('/api/v1/academics/semesters')
      .set(collegeAdminAHeader)
      .send({
        courseId: courseB.id,
        academicYearId: yearA.id,
        name: 'Cross Term',
        number: 1,
      });

    expect(res.status).toBe(400);
    expect(res.body.error.message).toMatch(/must belong to the specified college/);

    // HOD A1 trying to fetch College B course directly
    const resGetCourse = await request(app)
      .get(`/api/v1/academics/courses/${courseB.id}`)
      .set(hodA1Header);

    expect(resGetCourse.status).toBe(403);
  });

  // =========================================================================
  // SCENARIO 14: Failed mutations leave no partial/invalid academic records
  // =========================================================================
  it('14. Failed mutations leave no partial/invalid academic records', async () => {
    const preCount = await Semester.countDocuments();

    // Intentionally send invalid payload (bad number format / out of range)
    const resFail = await request(app)
      .post('/api/v1/academics/semesters')
      .set(hodA1Header)
      .send({
        courseId: new mongoose.Types.ObjectId().toString(),
        academicYearId: new mongoose.Types.ObjectId().toString(),
        name: 'Invalid Semester',
        number: 999, // exceeds max 12
      });

    expect(resFail.status).toBe(422);

    const postCount = await Semester.countDocuments();
    expect(postCount).toBe(preCount);
  });
});
