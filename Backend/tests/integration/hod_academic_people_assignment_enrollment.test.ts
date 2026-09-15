import request from 'supertest';
import mongoose from 'mongoose';
import { app } from '../../src/app';
import { College } from '../../src/models/college.model';
import { User } from '../../src/models/user.model';
import { Department } from '../../src/models/department.model';
import { Course } from '../../src/models/course.model';
import { AcademicYear } from '../../src/models/academicYear.model';
import { Semester } from '../../src/models/semester.model';
import { Section } from '../../src/models/section.model';
import { Subject } from '../../src/models/subject.model';
import { Faculty } from '../../src/models/faculty.model';
import { Student } from '../../src/models/student.model';
import { FacultyAssignment } from '../../src/models/facultyAssignment.model';
import { StudentEnrollment } from '../../src/models/studentEnrollment.model';
import { AuditLog } from '../../src/models/auditLog.model';
import { AppRole } from '../../src/constants/roles';
import { AccountStatus, CollegeStatus, DepartmentStatus } from '../../src/constants/status';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';

describe('ACADEX — HOD Academic Structure: Faculty Assignment & Student Enrollment (Prompt 3 of 6)', () => {
  let collegeA: InstanceType<typeof College>;
  let collegeB: InstanceType<typeof College>;

  let deptA1: InstanceType<typeof Department>; // HOD A1's department (Computer Engineering)
  let deptA2: InstanceType<typeof Department>; // Another department in College A (Electrical)
  let deptB1: InstanceType<typeof Department>; // Department in College B

  let hodA1: InstanceType<typeof User>;
  let collegeAdminA: InstanceType<typeof User>;
  let facultyUserA1: InstanceType<typeof User>;
  let facultyUserA2: InstanceType<typeof User>;
  let studentUserA1: InstanceType<typeof User>;

  let facultyDocA1: InstanceType<typeof Faculty>;
  let facultyDocA2: InstanceType<typeof Faculty>;
  let studentDocA1: InstanceType<typeof Student>;

  let hodA1Header: { Authorization: string };
  let collegeAdminAHeader: { Authorization: string };
  let facultyA1Header: { Authorization: string };
  let studentA1Header: { Authorization: string };

  let courseA1: InstanceType<typeof Course>;
  let courseA2: InstanceType<typeof Course>;

  let ayA: InstanceType<typeof AcademicYear>;

  let semesterA1: InstanceType<typeof Semester>;
  let semesterA2: InstanceType<typeof Semester>;

  let sectionA1: InstanceType<typeof Section>;
  let sectionA2: InstanceType<typeof Section>;

  let subjectA1: InstanceType<typeof Subject>;
  let subjectA2: InstanceType<typeof Subject>;

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
    await Faculty.init();
    await Student.init();
    await FacultyAssignment.init();
    await StudentEnrollment.init();
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
      name: 'Civil Engineering',
      code: 'CIV',
      description: 'Department of Civil Engineering in College B',
      status: DepartmentStatus.ACTIVE,
      isActive: true,
    });

    // Users
    hodA1 = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      instituteId: 'HOD-CME-01',
      name: 'Dr. Turing (HOD)',
      email: 'hod.cme@college-a.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.HOD,
      accountStatus: AccountStatus.ACTIVE,
      isActive: true,
    });

    collegeAdminA = await User.create({
      collegeId: collegeA._id,
      instituteId: 'ADMIN-A-01',
      name: 'Dean Alpha (Admin)',
      email: 'dean@college-a.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.COLLEGE_ADMIN,
      accountStatus: AccountStatus.ACTIVE,
      isActive: true,
    });

    facultyUserA1 = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      instituteId: 'FAC-CME-01',
      name: 'Prof. Donald Knuth',
      email: 'knuth@college-a.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.FACULTY,
      accountStatus: AccountStatus.ACTIVE,
      isActive: true,
    });

    facultyDocA1 = await Faculty.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      userId: facultyUserA1._id,
      name: 'Prof. Donald Knuth',
      email: 'knuth@college-a.edu',
      status: 'active',
      isActive: true,
      subjectIds: [],
      sectionIds: [],
    });

    facultyUserA2 = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA2._id, // Electrical
      instituteId: 'FAC-EEE-01',
      name: 'Prof. Nikola Tesla',
      email: 'tesla@college-a.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.FACULTY,
      accountStatus: AccountStatus.ACTIVE,
      isActive: true,
    });

    facultyDocA2 = await Faculty.create({
      collegeId: collegeA._id,
      departmentId: deptA2._id, // Electrical
      userId: facultyUserA2._id,
      name: 'Prof. Nikola Tesla',
      email: 'tesla@college-a.edu',
      status: 'active',
      isActive: true,
      subjectIds: [],
      sectionIds: [],
    });

    studentUserA1 = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      instituteId: 'STU-CME-01',
      name: 'Alice Student',
      email: 'alice@student.college-a.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.STUDENT,
      accountStatus: AccountStatus.ACTIVE,
      isActive: true,
    });

    studentDocA1 = await Student.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      userId: studentUserA1._id,
      name: 'Alice Student',
      rollNumber: 'CME-2026-001',
      admissionNumber: 'ADM-001',
      email: 'alice@student.college-a.edu',
      status: 'active',
      isActive: true,
    });

    hodA1Header = createTestAuthHeader({
      userId: hodA1._id.toString(),
      collegeId: collegeA._id.toString(),
      role: AppRole.HOD,
      departmentId: deptA1._id.toString(),
    });
    collegeAdminAHeader = createTestAuthHeader({
      userId: collegeAdminA._id.toString(),
      collegeId: collegeA._id.toString(),
      role: AppRole.COLLEGE_ADMIN,
    });
    facultyA1Header = createTestAuthHeader({
      userId: facultyUserA1._id.toString(),
      collegeId: collegeA._id.toString(),
      role: AppRole.FACULTY,
      departmentId: deptA1._id.toString(),
    });
    studentA1Header = createTestAuthHeader({
      userId: studentUserA1._id.toString(),
      collegeId: collegeA._id.toString(),
      role: AppRole.STUDENT,
      departmentId: deptA1._id.toString(),
    });

    ayA = await AcademicYear.create({
      collegeId: collegeA._id,
      name: '2026–2027',
      startDate: new Date('2026-06-01'),
      endDate: new Date('2027-05-31'),
      isCurrent: true,
      isActive: true,
    });

    courseA1 = await Course.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      name: 'Computer Engineering',
      code: 'DCME',
      duration: 3,
      isActive: true,
    });

    courseA2 = await Course.create({
      collegeId: collegeA._id,
      departmentId: deptA2._id,
      name: 'Electrical Engineering',
      code: 'DEEE',
      duration: 3,
      isActive: true,
    });

    semesterA1 = await Semester.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      courseId: courseA1._id,
      academicYearId: ayA._id,
      name: 'Semester 5',
      number: 5,
      isCurrent: true,
      isActive: true,
    });

    semesterA2 = await Semester.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      courseId: courseA1._id,
      academicYearId: ayA._id,
      name: 'Semester 6',
      number: 6,
      isCurrent: false,
      isActive: true,
    });

    sectionA1 = await Section.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      courseId: courseA1._id,
      academicYearId: ayA._id,
      semesterId: semesterA1._id,
      name: 'Section A',
      capacity: 60,
      status: 'active',
      isActive: true,
    });

    sectionA2 = await Section.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      courseId: courseA1._id,
      academicYearId: ayA._id,
      semesterId: semesterA1._id,
      name: 'Section B',
      capacity: 60,
      status: 'active',
      isActive: true,
    });

    subjectA1 = await Subject.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      courseId: courseA1._id,
      semesterId: semesterA1._id,
      name: 'Database Management Systems',
      code: 'CE501',
      credits: 4,
      type: 'Theory',
      status: 'active',
      isActive: true,
    });

    subjectA2 = await Subject.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      courseId: courseA1._id,
      semesterId: semesterA1._id,
      name: 'Operating Systems',
      code: 'CE502',
      credits: 4,
      type: 'Theory',
      status: 'active',
      isActive: true,
    });
  });

  // =========================================================================
  // 1. FACULTY ASSIGNMENT TESTS (Section 36)
  // =========================================================================
  describe('Faculty Assignment Implementation & Validation', () => {
    it('1. HOD creates valid FacultyAssignment in own department', async () => {
      const res = await request(app)
        .post('/api/v1/academics/faculty-assignments')
        .set(hodA1Header)
        .send({
          facultyId: facultyDocA1.id,
          subjectId: subjectA1.id,
          sectionId: sectionA1.id,
          courseId: courseA1.id,
          semesterId: semesterA1.id,
          academicYearId: ayA.id,
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.facultyName).toBe(facultyDocA1.name);
      expect(res.body.data.subjectId).toBe(subjectA1.id);
      expect(res.body.data.sectionId).toBe(sectionA1.id);
      expect(res.body.data.isActive).toBe(true);

      // Verify DB record
      const dbAssignment = await FacultyAssignment.findById(res.body.data.id);
      expect(dbAssignment).not.toBeNull();
      expect(dbAssignment!.departmentId.toString()).toBe(deptA1.id);
    });

    it('2. Invalid Subject/Section combination rejected (mismatched semester)', async () => {
      // Create section in Semester 6
      const sectionSem6 = await Section.create({
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        courseId: courseA1._id,
        academicYearId: ayA._id,
        semesterId: semesterA2._id, // Semester 6
        name: 'Section A',
        capacity: 60,
        status: 'active',
        isActive: true,
      });

      // Try assigning Semester 5 subject to Semester 6 section
      const res = await request(app)
        .post('/api/v1/academics/faculty-assignments')
        .set(hodA1Header)
        .send({
          facultyId: facultyDocA1.id,
          subjectId: subjectA1.id, // Semester 5
          sectionId: sectionSem6.id, // Semester 6
        });

      expect(res.status).toBe(400);
      expect(res.body.error.message).toMatch(/Subject semester does not match Section semester/i);
    });

    it('3. Invalid academic context rejected (mismatched course)', async () => {
      const res = await request(app)
        .post('/api/v1/academics/faculty-assignments')
        .set(hodA1Header)
        .send({
          facultyId: facultyDocA1.id,
          subjectId: subjectA1.id,
          sectionId: sectionA1.id,
          courseId: courseA2.id, // Mismatched course (Electrical)
        });

      expect(res.status).toBe(400);
      expect(res.body.error.message).toMatch(/Course does not match section course/i);
    });

    it('4. Faculty from another department rejected where department matching is required', async () => {
      // facultyDocA2 belongs to Electrical Engineering (deptA2)
      const res = await request(app)
        .post('/api/v1/academics/faculty-assignments')
        .set(hodA1Header) // HOD of CME
        .send({
          facultyId: facultyDocA2.id, // EEE faculty
          subjectId: subjectA1.id, // CME subject
          sectionId: sectionA1.id, // CME section
        });

      expect(res.status).toBe(403);
      expect(res.body.error.message).toMatch(/HOD can only assign faculty within their assigned department/i);
    });

    it('5. Cross-college assignment rejected', async () => {
      // Create faculty in College B
      const userB = await User.create({
        collegeId: collegeB._id,
        departmentId: deptB1._id,
        instituteId: 'PROF-B-01',
        name: 'Prof. College B',
        email: 'prof.b@college-b.edu',
        passwordHash: defaultPasswordHash,
        role: AppRole.FACULTY,
        accountStatus: AccountStatus.ACTIVE,
        isActive: true,
      });
      const facultyB = await Faculty.create({
        collegeId: collegeB._id,
        departmentId: deptB1._id,
        userId: userB._id,
        name: 'Prof. College B',
        email: 'prof.b@college-b.edu',
        status: 'active',
        isActive: true,
        subjectIds: [],
        sectionIds: [],
      });

      const res = await request(app)
        .post('/api/v1/academics/faculty-assignments')
        .set(hodA1Header)
        .send({
          facultyId: facultyB.id,
          subjectId: subjectA1.id,
          sectionId: sectionA1.id,
        });

      expect(res.status).toBe(400);
      expect(res.body.error.message).toMatch(/must all belong to the specified college/i);
    });

    it('6. Duplicate assignment rejected', async () => {
      // First assignment
      await request(app)
        .post('/api/v1/academics/faculty-assignments')
        .set(hodA1Header)
        .send({
          facultyId: facultyDocA1.id,
          subjectId: subjectA1.id,
          sectionId: sectionA1.id,
        });

      // Duplicate assignment attempt
      const res = await request(app)
        .post('/api/v1/academics/faculty-assignments')
        .set(hodA1Header)
        .send({
          facultyId: facultyDocA1.id,
          subjectId: subjectA1.id,
          sectionId: sectionA1.id,
        });

      expect(res.status).toBe(409);
      expect(res.body.error.message).toMatch(/already assigned/i);
    });

    it('7. HOD cannot modify another department\'s assignment', async () => {
      // Create assignment in deptA2 (Electrical) via College Admin
      const subjEEE = await Subject.create({
        collegeId: collegeA._id,
        departmentId: deptA2._id,
        courseId: courseA2._id,
        semesterId: semesterA1._id,
        name: 'Circuit Theory',
        code: 'EE501',
        credits: 4,
        type: 'Theory',
        status: 'active',
        isActive: true,
      });

      const secEEE = await Section.create({
        collegeId: collegeA._id,
        departmentId: deptA2._id,
        courseId: courseA2._id,
        academicYearId: ayA._id,
        semesterId: semesterA1._id,
        name: 'Section A',
        capacity: 60,
        status: 'active',
        isActive: true,
      });

      const assignmentEEE = await FacultyAssignment.create({
        collegeId: collegeA._id,
        departmentId: deptA2._id,
        facultyId: facultyDocA2._id,
        facultyName: facultyDocA2.name,
        courseId: courseA2._id,
        semesterId: semesterA1._id,
        sectionId: secEEE._id,
        subjectId: subjEEE._id,
        academicYearId: ayA._id,
        isActive: true,
      });

      // HOD A1 (CME) attempts to modify assignment in EEE
      const res = await request(app)
        .put(`/api/v1/academics/faculty-assignments/${assignmentEEE.id}`)
        .set(hodA1Header)
        .send({ roomId: 'Room 101' });

      expect(res.status).toBe(403);
      expect(res.body.error.message).toMatch(/Cross-department access is strictly prohibited/i);
    });

    it('8. Faculty and student cannot mutate assignments', async () => {
      const resFaculty = await request(app)
        .post('/api/v1/academics/faculty-assignments')
        .set(facultyA1Header)
        .send({
          facultyId: facultyDocA1.id,
          subjectId: subjectA1.id,
          sectionId: sectionA1.id,
        });
      expect(resFaculty.status).toBe(403);

      const resStudent = await request(app)
        .post('/api/v1/academics/faculty-assignments')
        .set(studentA1Header)
        .send({
          facultyId: facultyDocA1.id,
          subjectId: subjectA1.id,
          sectionId: sectionA1.id,
        });
      expect(resStudent.status).toBe(403);
    });

    it('9. Assignment deactivation works safely without breaking records', async () => {
      const assignment = await FacultyAssignment.create({
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        facultyId: facultyDocA1._id,
        facultyName: facultyDocA1.name,
        courseId: courseA1._id,
        semesterId: semesterA1._id,
        sectionId: sectionA1._id,
        subjectId: subjectA1._id,
        academicYearId: ayA._id,
        isActive: true,
      });

      const res = await request(app)
        .put(`/api/v1/academics/faculty-assignments/${assignment.id}`)
        .set(hodA1Header)
        .send({ isActive: false });

      expect(res.status).toBe(200);
      expect(res.body.data.isActive).toBe(false);

      const checkDb = await FacultyAssignment.findById(assignment.id);
      expect(checkDb).not.toBeNull();
      expect(checkDb!.isActive).toBe(false);
    });

    it('10. Failed assignment creation causes no partial record', async () => {
      const initialCount = await FacultyAssignment.countDocuments();

      await request(app)
        .post('/api/v1/academics/faculty-assignments')
        .set(hodA1Header)
        .send({
          facultyId: facultyDocA1.id,
          subjectId: new mongoose.Types.ObjectId().toString(), // Non-existent subject
          sectionId: sectionA1.id,
        });

      const finalCount = await FacultyAssignment.countDocuments();
      expect(finalCount).toBe(initialCount);
    });

    it('10b. College Admin has college-wide visibility across departments', async () => {
      await FacultyAssignment.create({
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        facultyId: facultyDocA1._id,
        facultyName: facultyDocA1.name,
        courseId: courseA1._id,
        semesterId: semesterA1._id,
        sectionId: sectionA1._id,
        subjectId: subjectA1._id,
        academicYearId: ayA._id,
        isActive: true,
      });

      const res = await request(app)
        .get('/api/v1/academics/faculty-assignments')
        .set(collegeAdminAHeader);

      expect(res.status).toBe(200);
      expect(res.body.data.items.length).toBeGreaterThanOrEqual(1);
    });

    it('10c. Unassigned subjects can be identified for a section', async () => {
      // Create assignment for subjectA1 in sectionA1
      await FacultyAssignment.create({
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        facultyId: facultyDocA1._id,
        facultyName: facultyDocA1.name,
        courseId: courseA1._id,
        semesterId: semesterA1._id,
        sectionId: sectionA1._id,
        subjectId: subjectA1._id,
        academicYearId: ayA._id,
        isActive: true,
      });

      // subjectA1 has assignment in sectionA1, subjectA2 has none
      const res = await request(app)
        .get(`/api/v1/academics/faculty-assignments?sectionId=${sectionA1.id}&isActive=true`)
        .set(hodA1Header);

      expect(res.status).toBe(200);
      const assignedSubjectIds = res.body.data.items.map((item: any) => item.subjectId);
      expect(assignedSubjectIds).toContain(subjectA1.id);
      expect(assignedSubjectIds).not.toContain(subjectA2.id);
    });
  });

  // =========================================================================
  // 2. STUDENT ENROLLMENT TESTS (Section 37)
  // =========================================================================
  describe('Student Enrollment Implementation & Validation', () => {
    it('11. HOD enrolls valid Student in own department section', async () => {
      const res = await request(app)
        .post('/api/v1/academics/enrollments')
        .set(hodA1Header)
        .send({
          studentId: studentDocA1.id,
          sectionId: sectionA1.id,
          courseId: courseA1.id,
          semesterId: semesterA1.id,
          academicYearId: ayA.id,
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.studentId).toBe(studentDocA1.id);
      expect(res.body.data.sectionId).toBe(sectionA1.id);
      expect(res.body.data.status).toBe('active');

      // Verify student profile pointer updated
      const studentUpdated = await Student.findById(studentDocA1.id);
      expect(studentUpdated!.sectionId?.toString()).toBe(sectionA1.id);
      expect(studentUpdated!.semesterId?.toString()).toBe(semesterA1.id);
    });

    it('12. Invalid Course/Semester/Section combination rejected', async () => {
      const sectionSem6 = await Section.create({
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        courseId: courseA1._id,
        academicYearId: ayA._id,
        semesterId: semesterA2._id, // Semester 6
        name: 'Section Sem6 A',
        capacity: 60,
        status: 'active',
        isActive: true,
      });

      const res = await request(app)
        .post('/api/v1/academics/enrollments')
        .set(hodA1Header)
        .send({
          studentId: studentDocA1.id,
          sectionId: sectionSem6.id,
          semesterId: semesterA1.id, // Mismatched semester (Sem 5 vs Sem 6)
        });

      expect(res.status).toBe(400);
      expect(res.body.error.message).toMatch(/Section does not match the semester or course/i);
    });

    it('13. Cross-department enrollment rejected', async () => {
      // Create student in deptA2 (Electrical)
      const userEEE = await User.create({
        collegeId: collegeA._id,
        departmentId: deptA2._id,
        instituteId: 'STU-EEE-01',
        name: 'Bob Student',
        email: 'bob@student.college-a.edu',
        passwordHash: defaultPasswordHash,
        role: AppRole.STUDENT,
        accountStatus: AccountStatus.ACTIVE,
        isActive: true,
      });
      const studentEEE = await Student.create({
        collegeId: collegeA._id,
        departmentId: deptA2._id,
        userId: userEEE._id,
        name: 'Bob Student',
        rollNumber: 'EEE-2026-001',
        admissionNumber: 'ADM-002',
        email: 'bob@student.college-a.edu',
        status: 'active',
        isActive: true,
      });

      // HOD CME tries to enroll EEE student into CME section
      const res = await request(app)
        .post('/api/v1/academics/enrollments')
        .set(hodA1Header)
        .send({
          studentId: studentEEE.id,
          sectionId: sectionA1.id,
        });

      expect(res.status).toBe(400);
      expect(res.body.error.message).toMatch(/must belong to the same department/i);
    });

    it('14. Cross-college enrollment rejected', async () => {
      // Create student in College B
      const userB = await User.create({
        collegeId: collegeB._id,
        departmentId: deptB1._id,
        instituteId: 'STU-B-01',
        name: 'Charlie Student B',
        email: 'charlie@student.college-b.edu',
        passwordHash: defaultPasswordHash,
        role: AppRole.STUDENT,
        accountStatus: AccountStatus.ACTIVE,
        isActive: true,
      });
      const studentB = await Student.create({
        collegeId: collegeB._id,
        departmentId: deptB1._id,
        userId: userB._id,
        name: 'Charlie Student B',
        rollNumber: 'CIV-2026-001',
        admissionNumber: 'ADM-003',
        email: 'charlie@student.college-b.edu',
        status: 'active',
        isActive: true,
      });

      const res = await request(app)
        .post('/api/v1/academics/enrollments')
        .set(hodA1Header)
        .send({
          studentId: studentB.id,
          sectionId: sectionA1.id,
        });

      expect(res.status).toBe(400);
      expect(res.body.error.message).toMatch(/All entities must belong to the specified college/i);
    });

    it('15. Duplicate active enrollment rejected', async () => {
      // First enrollment
      await request(app)
        .post('/api/v1/academics/enrollments')
        .set(hodA1Header)
        .send({
          studentId: studentDocA1.id,
          sectionId: sectionA1.id,
        });

      // Second enrollment attempt in the same semester
      const res = await request(app)
        .post('/api/v1/academics/enrollments')
        .set(hodA1Header)
        .send({
          studentId: studentDocA1.id,
          sectionId: sectionA2.id, // Section B in same semester
        });

      expect(res.status).toBe(409);
      expect(res.body.error.message).toMatch(/already actively enrolled/i);
    });

    it('16. HOD cannot modify another department\'s enrollment', async () => {
      // Create enrollment in deptA2
      const secEEE = await Section.create({
        collegeId: collegeA._id,
        departmentId: deptA2._id,
        courseId: courseA2._id,
        academicYearId: ayA._id,
        semesterId: semesterA1._id,
        name: 'Section A',
        capacity: 60,
        status: 'active',
        isActive: true,
      });

      const userEEE = await User.create({
        collegeId: collegeA._id,
        departmentId: deptA2._id,
        instituteId: 'STU-EEE-02',
        name: 'EEE Student',
        email: 'eee@student.college-a.edu',
        passwordHash: defaultPasswordHash,
        role: AppRole.STUDENT,
        accountStatus: AccountStatus.ACTIVE,
        isActive: true,
      });
      const studentEEE = await Student.create({
        collegeId: collegeA._id,
        departmentId: deptA2._id,
        userId: userEEE._id,
        name: 'EEE Student',
        rollNumber: 'EEE-2026-002',
        admissionNumber: 'ADM-004',
        email: 'eee@student.college-a.edu',
        status: 'active',
        isActive: true,
      });

      const enrollmentEEE = await StudentEnrollment.create({
        collegeId: collegeA._id,
        departmentId: deptA2._id,
        studentId: studentEEE._id,
        courseId: courseA2._id,
        academicYearId: ayA._id,
        semesterId: semesterA1._id,
        sectionId: secEEE._id,
        status: 'active',
      });

      // HOD A1 (CME) attempts to update enrollment in EEE
      const res = await request(app)
        .patch(`/api/v1/academics/enrollments/${enrollmentEEE.id}`)
        .set(hodA1Header)
        .send({ status: 'completed' });

      expect(res.status).toBe(403);
      expect(res.body.error.message).toMatch(/Cross-department access is strictly prohibited/i);
    });

    it('17. Student cannot mutate enrollment', async () => {
      const res = await request(app)
        .post('/api/v1/academics/enrollments')
        .set(studentA1Header)
        .send({
          studentId: studentDocA1.id,
          sectionId: sectionA1.id,
        });

      expect(res.status).toBe(403);
    });

    it('18. Deactivation behaves safely (withdrawn status)', async () => {
      const enrollment = await StudentEnrollment.create({
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        studentId: studentDocA1._id,
        courseId: courseA1._id,
        academicYearId: ayA._id,
        semesterId: semesterA1._id,
        sectionId: sectionA1._id,
        status: 'active',
      });

      const res = await request(app)
        .delete(`/api/v1/academics/enrollments/${enrollment.id}`)
        .set(hodA1Header);

      expect(res.status).toBe(200);

      const checkDb = await StudentEnrollment.findById(enrollment.id);
      expect(checkDb).not.toBeNull();
      expect(checkDb!.status).toBe('withdrawn');
    });

    it('19. Invalid enrollment causes no partial record', async () => {
      const initialCount = await StudentEnrollment.countDocuments();

      await request(app)
        .post('/api/v1/academics/enrollments')
        .set(hodA1Header)
        .send({
          studentId: new mongoose.Types.ObjectId().toString(), // Non-existent student
          sectionId: sectionA1.id,
        });

      const finalCount = await StudentEnrollment.countDocuments();
      expect(finalCount).toBe(initialCount);
    });
  });

  // =========================================================================
  // 3. CROSS-MODULE INTEGRITY & FUTURE CONTRACT TESTS (Sections 38, 40, 41)
  // =========================================================================
  describe('Cross-Module Integrity & Future Contracts', () => {
    it('20-22. FacultyAssignment references real Subject, Section, and matching academic context', async () => {
      const assignment = await FacultyAssignment.create({
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        facultyId: facultyDocA1._id,
        facultyName: facultyDocA1.name,
        courseId: courseA1._id,
        semesterId: semesterA1._id,
        sectionId: sectionA1._id,
        subjectId: subjectA1._id,
        academicYearId: ayA._id,
        isActive: true,
      });

      const res = await request(app)
        .get(`/api/v1/academics/faculty-assignments/${assignment.id}`)
        .set(hodA1Header);

      expect(res.status).toBe(200);
      expect(res.body.data.subjectId).toBe(subjectA1.id);
      expect(res.body.data.sectionId).toBe(sectionA1.id);
      expect(res.body.data.courseId).toBe(courseA1.id);
      expect(res.body.data.semesterId).toBe(semesterA1.id);
    });

    it('23-25. StudentEnrollment references real Student, Section, and matching context', async () => {
      const enrollment = await StudentEnrollment.create({
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        studentId: studentDocA1._id,
        courseId: courseA1._id,
        academicYearId: ayA._id,
        semesterId: semesterA1._id,
        sectionId: sectionA1._id,
        status: 'active',
      });

      const res = await request(app)
        .get(`/api/v1/academics/enrollments/${enrollment.id}`)
        .set(hodA1Header);

      expect(res.status).toBe(200);
      expect(res.body.data.studentId).toBe(studentDocA1.id);
      expect(res.body.data.sectionId).toBe(sectionA1.id);
      expect(res.body.data.semesterId).toBe(semesterA1.id);
    });

    it('26. A valid Section can have multiple enrolled students', async () => {
      // Create a second student in deptA1
      const studentDoc2 = await Student.create({
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        name: 'Student Two',
        rollNumber: 'CME-2026-002',
        admissionNumber: 'ADM-005',
        status: 'active',
        isActive: true,
      });

      await request(app)
        .post('/api/v1/academics/enrollments')
        .set(hodA1Header)
        .send({ studentId: studentDocA1.id, sectionId: sectionA1.id });

      await request(app)
        .post('/api/v1/academics/enrollments')
        .set(hodA1Header)
        .send({ studentId: studentDoc2.id, sectionId: sectionA1.id });

      const count = await StudentEnrollment.countDocuments({ sectionId: sectionA1._id, status: 'active' });
      expect(count).toBe(2);
    });

    it('27. A subject can have different assignments for different sections', async () => {
      // Assign Prof Knuth to Section A for DBMS
      const resA = await request(app)
        .post('/api/v1/academics/faculty-assignments')
        .set(hodA1Header)
        .send({
          facultyId: facultyDocA1.id,
          subjectId: subjectA1.id,
          sectionId: sectionA1.id,
        });
      expect(resA.status).toBe(201);

      // Create second faculty in CME
      const facultyDocA3 = await Faculty.create({
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        name: 'Prof. Ada Lovelace',
        email: 'lovelace@college-a.edu',
        status: 'active',
        isActive: true,
        subjectIds: [],
        sectionIds: [],
      });

      // Assign Prof Lovelace to Section B for DBMS
      const resB = await request(app)
        .post('/api/v1/academics/faculty-assignments')
        .set(hodA1Header)
        .send({
          facultyId: facultyDocA3.id,
          subjectId: subjectA1.id,
          sectionId: sectionA2.id,
        });
      expect(resB.status).toBe(201);

      // Both active assignments exist for same subject CE501
      const assignments = await FacultyAssignment.find({ subjectId: subjectA1._id });
      expect(assignments.length).toBe(2);
    });

    it('28. Section capacity enforcement rejects enrollment beyond capacity', async () => {
      // Create section with capacity of 1
      const smallSection = await Section.create({
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        courseId: courseA1._id,
        academicYearId: ayA._id,
        semesterId: semesterA1._id,
        name: 'Small Section',
        capacity: 1,
        status: 'active',
        isActive: true,
      });

      // Enroll first student
      const res1 = await request(app)
        .post('/api/v1/academics/enrollments')
        .set(hodA1Header)
        .send({ studentId: studentDocA1.id, sectionId: smallSection.id });
      expect(res1.status).toBe(201);

      // Create second student
      const student2 = await Student.create({
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        name: 'Extra Student',
        rollNumber: 'CME-2026-999',
        admissionNumber: 'ADM-999',
        status: 'active',
        isActive: true,
      });

      // Second enrollment should fail due to capacity
      const res2 = await request(app)
        .post('/api/v1/academics/enrollments')
        .set(hodA1Header)
        .send({ studentId: student2.id, sectionId: smallSection.id });
      expect(res2.status).toBe(409);
      expect(res2.body.error.message).toMatch(/is full/i);
    });

    it('29. Future Attendance Contract Test: Given Section A + 42 valid active StudentEnrollment records, resolves 42 real students', async () => {
      // Bulk create 42 students and active enrollments
      const studentDocs = [];
      for (let i = 1; i <= 42; i++) {
        studentDocs.push({
          collegeId: collegeA._id,
          departmentId: deptA1._id,
          name: `Roster Student ${i}`,
          rollNumber: `RST-${i.toString().padStart(3, '0')}`,
          admissionNumber: `ADM-RST-${i.toString().padStart(3, '0')}`,
          email: `student${i}@college-a.edu`,
          status: 'active',
          isActive: true,
        });
      }
      const createdStudents = await Student.insertMany(studentDocs);

      const enrollments = createdStudents.map((s) => ({
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        studentId: s._id,
        courseId: courseA1._id,
        academicYearId: ayA._id,
        semesterId: semesterA1._id,
        sectionId: sectionA1._id,
        status: 'active',
        enrollmentDate: new Date(),
      }));
      await StudentEnrollment.insertMany(enrollments);

      // Query section enrollments through API
      const res = await request(app)
        .get(`/api/v1/academics/enrollments?sectionId=${sectionA1.id}&status=active&limit=100`)
        .set(hodA1Header);

      expect(res.status).toBe(200);
      expect(res.body.data.total).toBe(42);
      expect(res.body.data.items.length).toBe(42);

      // Verify each item has populated student identity with name and rollNumber
      for (const item of res.body.data.items) {
        expect(item.student).toBeDefined();
        expect(item.student.name).toMatch(/^Roster Student \d+$/);
        expect(item.student.rollNumber).toMatch(/^RST-\d{3}$/);
      }
    });

    it('30. Future Timetable Contract Test: FacultyAssignment contains all necessary references for Timetable Entry', async () => {
      const assignment = await FacultyAssignment.create({
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        facultyId: facultyDocA1._id,
        facultyName: facultyDocA1.name,
        courseId: courseA1._id,
        semesterId: semesterA1._id,
        sectionId: sectionA1._id,
        subjectId: subjectA1._id,
        academicYearId: ayA._id,
        roomId: 'Lab 301',
        maxStudents: 60,
        assignmentType: 'practical',
        isActive: true,
      });

      const res = await request(app)
        .get(`/api/v1/academics/faculty-assignments/${assignment.id}`)
        .set(hodA1Header);

      expect(res.status).toBe(200);
      const data = res.body.data;
      expect(data.id).toBeDefined();
      expect(data.collegeId).toBe(collegeA.id);
      expect(data.departmentId).toBe(deptA1.id);
      expect(data.courseId).toBe(courseA1.id);
      expect(data.semesterId).toBe(semesterA1.id);
      expect(data.sectionId).toBe(sectionA1.id);
      expect(data.subjectId).toBe(subjectA1.id);
      expect(data.facultyId).toBe(facultyDocA1.id);
      expect(data.facultyName).toBe('Prof. Donald Knuth');
      expect(data.academicYearId).toBe(ayA.id);
      expect(data.isActive).toBe(true);
    });
  });
});
