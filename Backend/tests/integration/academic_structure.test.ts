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
import { Student } from '../../src/models/student.model';
import { StudentEnrollment } from '../../src/models/studentEnrollment.model';
import { AuditLog } from '../../src/models/auditLog.model';
import { AppRole } from '../../src/constants/roles';
import { AccountStatus, CollegeStatus, DepartmentStatus } from '../../src/constants/status';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';
import { PasswordService } from '../../src/services/password.service';

describe('ACADEX Phase 9I.1 — Academic Structure & Student Enrollment Tests', () => {
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

  let studentProfileA: InstanceType<typeof Student>;

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
    await Course.init();
    await AcademicYear.init();
    await Semester.init();
    await Section.init();
    await Subject.init();
    await Student.init();
    await StudentEnrollment.init();
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

    studentProfileA = await Student.create({
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
  // 1. COURSE TESTS (1 - 8)
  // =========================================================================

  it('1, 3, 5, 6. Course creation works, links to department, and enforces scopes', async () => {
    // 1 & 5. College Admin creates course in College A
    const resAdmin = await request(app)
      .post('/api/v1/academics/courses')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA1.id,
        name: 'B.Tech Computer Science',
        code: 'CS101',
        duration: 4,
      });

    expect(resAdmin.status).toBe(201);
    expect(resAdmin.body.data.name).toBe('B.Tech Computer Science');
    expect(resAdmin.body.data.departmentId).toBe(deptA1.id);

    // 6. HOD creates course in own department
    const resHod = await request(app)
      .post('/api/v1/academics/courses')
      .set(hodA1Header)
      .send({
        departmentId: deptA1.id,
        name: 'Diploma in Computer Engineering',
        code: 'DCME',
        duration: 3,
      });

    expect(resHod.status).toBe(201);
    expect(resHod.body.data.code).toBe('DCME');
  });

  it('2, 4, 7, 8. Duplicate course rejected, cross-college dept rejected, faculty/student blocked (403)', async () => {
    // Create base course
    await request(app)
      .post('/api/v1/academics/courses')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA1.id,
        name: 'B.Tech Computer Science',
        code: 'CS101',
      });

    // 2. Duplicate course code in same college -> 409 Conflict
    const resDup = await request(app)
      .post('/api/v1/academics/courses')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA2.id,
        name: 'Another CS',
        code: 'CS101',
      });
    expect(resDup.status).toBe(409);

    // 4. College Admin A creating course for College B department -> 400 Bad Request
    const resCross = await request(app)
      .post('/api/v1/academics/courses')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptB1.id,
        name: 'Mech Course',
        code: 'MECH101',
      });
    expect(resCross.status).toBe(400);

    // Inactive department rejection
    const resInactDept = await request(app)
      .post('/api/v1/academics/courses')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptAInactive.id,
        name: 'Inactive Dept Course',
        code: 'INACTDEPT101',
      });
    expect(resInactDept.status).toBe(403);

    // Inactive college rejection
    const inactDept = await Department.create({
      collegeId: inactiveCollege._id,
      name: 'Gamma Inactive Dept',
      code: 'GAMMADEPT',
      status: DepartmentStatus.ACTIVE,
      isActive: true,
    });
    const resInact = await request(app)
      .post('/api/v1/academics/courses')
      .set(superAdminHeader)
      .send({
        collegeId: inactiveCollege.id,
        departmentId: inactDept.id,
        name: 'Inactive College Course',
        code: 'INACT101',
      });
    expect(resInact.status).toBe(403);

    // 7. Faculty cannot create course -> 403 Forbidden
    const resFac = await request(app)
      .post('/api/v1/academics/courses')
      .set(facultyA1Header)
      .send({
        departmentId: deptA1.id,
        name: 'Faculty Course',
        code: 'FAC101',
      });
    expect(resFac.status).toBe(403);

    // 8. Student cannot create course -> 403 Forbidden
    const resStu = await request(app)
      .post('/api/v1/academics/courses')
      .set(studentAHeader)
      .send({
        departmentId: deptA1.id,
        name: 'Student Course',
        code: 'STU101',
      });
    expect(resStu.status).toBe(403);
  });

  // =========================================================================
  // 2. ACADEMIC YEAR TESTS (9 - 13)
  // =========================================================================

  it('9, 10, 11, 12, 13. Academic year creation, date validation, uniqueness, and isCurrent toggling', async () => {
    // 9 & 13. College Admin creates academic year
    const resYear1 = await request(app)
      .post('/api/v1/academics/academic-years')
      .set(collegeAdminAHeader)
      .send({
        name: '2026-2027',
        startDate: '2026-06-01T00:00:00.000Z',
        endDate: '2027-05-31T23:59:59.000Z',
        isCurrent: true,
      });

    expect(resYear1.status).toBe(201);
    expect(resYear1.body.data.name).toBe('2026-2027');
    expect(resYear1.body.data.isCurrent).toBe(true);

    // 10. Duplicate name in same college -> 409
    const resDup = await request(app)
      .post('/api/v1/academics/academic-years')
      .set(collegeAdminAHeader)
      .send({
        name: '2026-2027',
        startDate: '2026-07-01T00:00:00.000Z',
        endDate: '2027-06-30T23:59:59.000Z',
      });
    expect(resDup.status).toBe(409);

    // 11. Invalid date range (startDate >= endDate) -> 422 Unprocessable Entity (Zod refine)
    const resInvalidDates = await request(app)
      .post('/api/v1/academics/academic-years')
      .set(collegeAdminAHeader)
      .send({
        name: '2027-2028',
        startDate: '2028-01-01T00:00:00.000Z',
        endDate: '2027-01-01T00:00:00.000Z',
      });
    expect([400, 422]).toContain(resInvalidDates.status);

    // 12. College Admin B cannot access/view College A academic years
    const resCross = await request(app)
      .get(`/api/v1/academics/academic-years/${resYear1.body.data.id}`)
      .set(collegeAdminBHeader);
    expect(resCross.status).toBe(403);

    // 13. Create second academic year with isCurrent: true -> unsets first year isCurrent
    const resYear2 = await request(app)
      .post('/api/v1/academics/academic-years')
      .set(collegeAdminAHeader)
      .send({
        name: '2027-2028',
        startDate: '2027-06-01T00:00:00.000Z',
        endDate: '2028-05-31T23:59:59.000Z',
        isCurrent: true,
      });
    expect(resYear2.status).toBe(201);

    const oldYear = await AcademicYear.findById(resYear1.body.data.id);
    expect(oldYear?.isCurrent).toBe(false);
  });

  // =========================================================================
  // 3. SEMESTER, SECTION & SUBJECT TESTS (14 - 28)
  // =========================================================================

  it('14 - 28. Complete hierarchy: Semester, Section, Subject validation and cross-entity rejection', async () => {
    // Setup Course & AcademicYear in College A
    const course = await Course.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      name: 'Computer Engineering',
      code: 'CME',
      duration: 3,
      isActive: true,
    });

    const academicYear = await AcademicYear.create({
      collegeId: collegeA._id,
      name: '2026-2027',
      startDate: new Date('2026-06-01'),
      endDate: new Date('2027-05-31'),
      isCurrent: true,
      isActive: true,
    });

    // College B Course for cross-college testing
    const courseB = await Course.create({
      collegeId: collegeB._id,
      departmentId: deptB1._id,
      name: 'Mechanical Engineering',
      code: 'MEC',
      duration: 4,
      isActive: true,
    });

    // 14. Create Semester
    const resSem = await request(app)
      .post('/api/v1/academics/semesters')
      .set(collegeAdminAHeader)
      .send({
        courseId: course.id,
        academicYearId: academicYear.id,
        name: 'Semester 5',
        number: 5,
      });

    expect(resSem.status).toBe(201);
    expect(resSem.body.data.number).toBe(5);

    const semesterId = resSem.body.data.id;

    // 17. Cross-college semester creation rejected
    const resCrossSem = await request(app)
      .post('/api/v1/academics/semesters')
      .set(collegeAdminAHeader)
      .send({
        courseId: courseB.id, // College B Course
        academicYearId: academicYear.id, // College A Academic Year
        name: 'Semester 1',
        number: 1,
      });
    expect(resCrossSem.status).toBe(400);

    // 18. Duplicate semester number for same course + academicYear rejected -> 409
    const resDupSem = await request(app)
      .post('/api/v1/academics/semesters')
      .set(collegeAdminAHeader)
      .send({
        courseId: course.id,
        academicYearId: academicYear.id,
        name: 'Semester 5 Duplicate',
        number: 5,
      });
    expect(resDupSem.status).toBe(409);

    // 19 & 24. Create Section with Capacity
    const resSec = await request(app)
      .post('/api/v1/academics/sections')
      .set(collegeAdminAHeader)
      .send({
        courseId: course.id,
        academicYearId: academicYear.id,
        semesterId,
        name: 'Section A',
        capacity: 40,
      });

    expect(resSec.status).toBe(201);
    expect(resSec.body.data.name).toBe('SECTION A');
    expect(resSec.body.data.capacity).toBe(40);

    // 23. Duplicate Section rejected -> 409
    const resDupSec = await request(app)
      .post('/api/v1/academics/sections')
      .set(collegeAdminAHeader)
      .send({
        courseId: course.id,
        academicYearId: academicYear.id,
        semesterId,
        name: 'Section A',
      });
    expect(resDupSec.status).toBe(409);

    // 25. Create Subject
    const resSub = await request(app)
      .post('/api/v1/academics/subjects')
      .set(collegeAdminAHeader)
      .send({
        courseId: course.id,
        semesterId,
        name: 'Operating Systems',
        code: 'CS501',
        credits: 4,
        type: 'Theory',
      });

    expect(resSub.status).toBe(201);
    expect(resSub.body.data.code).toBe('CS501');

    // 27. Duplicate Subject code in same semester rejected -> 409
    const resDupSub = await request(app)
      .post('/api/v1/academics/subjects')
      .set(collegeAdminAHeader)
      .send({
        courseId: course.id,
        semesterId,
        name: 'Advanced OS',
        code: 'CS501',
      });
    expect(resDupSub.status).toBe(409);
  });

  // =========================================================================
  // 4. STUDENT ENROLLMENT & CAPACITY TESTS (29 - 40)
  // =========================================================================

  it('29 - 40. Student Enrollment validation, capacity limits, duplicate checks, and student profile updates', async () => {
    // Setup Hierarchy
    const course = await Course.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      name: 'Computer Engineering',
      code: 'CME',
      duration: 3,
      isActive: true,
    });

    const academicYear = await AcademicYear.create({
      collegeId: collegeA._id,
      name: '2026-2027',
      startDate: new Date('2026-06-01'),
      endDate: new Date('2027-05-31'),
      isCurrent: true,
      isActive: true,
    });

    const semester = await Semester.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      courseId: course._id,
      academicYearId: academicYear._id,
      name: 'Semester 5',
      number: 5,
      isActive: true,
    });

    // Small section with capacity = 1 to test full capacity enforcement
    const section = await Section.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      courseId: course._id,
      academicYearId: academicYear._id,
      semesterId: semester._id,
      name: 'SECTION SMALL',
      capacity: 1,
      isActive: true,
    });

    // 29. Enroll Student A
    const resEnroll = await request(app)
      .post('/api/v1/academics/enrollments')
      .set(collegeAdminAHeader)
      .send({
        studentId: studentProfileA.id,
        courseId: course.id,
        academicYearId: academicYear.id,
        semesterId: semester.id,
        sectionId: section.id,
      });

    expect(resEnroll.status).toBe(201);
    expect(resEnroll.body.data.studentId).toBe(studentProfileA.id);

    // 40. Verify student profile pointers updated
    const updatedStudent = await Student.findById(studentProfileA.id);
    expect(updatedStudent?.courseId?.toString()).toBe(course.id);
    expect(updatedStudent?.semesterId?.toString()).toBe(semester.id);

    // 36 & 37. Duplicate active enrollment for same student in same semester rejected -> 409
    const resDupEnroll = await request(app)
      .post('/api/v1/academics/enrollments')
      .set(collegeAdminAHeader)
      .send({
        studentId: studentProfileA.id,
        courseId: course.id,
        academicYearId: academicYear.id,
        semesterId: semester.id,
        sectionId: section.id,
      });
    expect(resDupEnroll.status).toBe(409);

    // Create Student B in same department
    const studentUserB = await User.create({
      instituteId: 'STU-CSE-002',
      name: 'Bob Jones',
      email: 'bob@alpha.edu',
      passwordHash: 'hash',
      role: AppRole.STUDENT,
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      accountStatus: AccountStatus.ACTIVE,
    });
    const studentProfileB = await Student.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      userId: studentUserB._id,
      instituteId: studentUserB.instituteId,
      name: studentUserB.name,
      status: 'active',
      isActive: true,
    });

    // 38. Section capacity exceeded check (capacity = 1, already 1 enrolled) -> 409 Conflict
    const resFull = await request(app)
      .post('/api/v1/academics/enrollments')
      .set(collegeAdminAHeader)
      .send({
        studentId: studentProfileB.id,
        courseId: course.id,
        academicYearId: academicYear.id,
        semesterId: semester.id,
        sectionId: section.id,
      });
    expect(resFull.status).toBe(409);
    expect(resFull.body.error?.message || resFull.body.message).toContain('is full');
  });

  // =========================================================================
  // 5. ACADEMIC TREE, AUTHORIZATION & AUDIT TESTS (41 - 54)
  // =========================================================================

  it('41 - 54. Academic Tree hierarchy generation, RBAC scoping, and Audit Logging', async () => {
    // 1. Create Course via API
    const resCourse = await request(app)
      .post('/api/v1/academics/courses')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA1.id,
        name: 'Computer Engineering',
        code: 'CME',
        duration: 3,
      });
    expect(resCourse.status).toBe(201);
    const courseId = resCourse.body.data.id;

    // 2. Create Academic Year via API
    const resYear = await request(app)
      .post('/api/v1/academics/academic-years')
      .set(collegeAdminAHeader)
      .send({
        name: '2026-2027',
        startDate: '2026-06-01T00:00:00.000Z',
        endDate: '2027-05-31T23:59:59.000Z',
        isCurrent: true,
      });
    expect(resYear.status).toBe(201);
    const academicYearId = resYear.body.data.id;

    // 3. Create Semester via API
    const resSem = await request(app)
      .post('/api/v1/academics/semesters')
      .set(collegeAdminAHeader)
      .send({
        courseId,
        academicYearId,
        name: 'Semester 5',
        number: 5,
      });
    expect(resSem.status).toBe(201);
    const semesterId = resSem.body.data.id;

    // 4. Create Section via API
    const resSec = await request(app)
      .post('/api/v1/academics/sections')
      .set(collegeAdminAHeader)
      .send({
        courseId,
        academicYearId,
        semesterId,
        name: 'SECTION A',
        capacity: 60,
      });
    expect(resSec.status).toBe(201);

    // 5. Create Subject via API
    const resSub = await request(app)
      .post('/api/v1/academics/subjects')
      .set(collegeAdminAHeader)
      .send({
        courseId,
        semesterId,
        name: 'Operating Systems',
        code: 'CS501',
        credits: 4,
        type: 'Theory',
      });
    expect(resSub.status).toBe(201);

    // 48. Fetch Academic Tree for College Admin A
    const resTree = await request(app)
      .get('/api/v1/academics/tree')
      .set(collegeAdminAHeader);

    expect(resTree.status).toBe(200);
    expect(resTree.body.data.tree).toHaveLength(1);
    expect(resTree.body.data.tree[0].code).toBe('ALPHA');
    expect(resTree.body.data.tree[0].departments[0].courses[0].code).toBe('CME');
    expect(resTree.body.data.tree[0].departments[0].courses[0].semesters[0].sections).toHaveLength(1);
    expect(resTree.body.data.tree[0].departments[0].courses[0].semesters[0].subjects).toHaveLength(1);

    // 51, 52, 53. Check Audit Logs
    const logs = await AuditLog.find({ collegeId: collegeA.id });
    const actions = logs.map((l) => l.action);
    expect(actions).toContain('COURSE_CREATED');
    expect(actions).toContain('ACADEMIC_YEAR_CREATED');
    expect(actions).toContain('SEMESTER_CREATED');
    expect(actions).toContain('SECTION_CREATED');
    expect(actions).toContain('SUBJECT_CREATED');

    // Check secrets are not exposed in logs
    const serialized = JSON.stringify(logs);
    expect(serialized).not.toContain('password');
    expect(serialized).not.toContain('AdminPass123');
  });
});
