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
import { Student } from '../../src/models/student.model';
import { Faculty } from '../../src/models/faculty.model';
import { FacultyAssignment } from '../../src/models/facultyAssignment.model';
import { StudentEnrollment } from '../../src/models/studentEnrollment.model';
import { InstitutionConfiguration } from '../../src/models/institutionConfiguration.model';
import { AppRole } from '../../src/constants/roles';
import { AccountStatus, CollegeStatus, DepartmentStatus, StudentLifecycleState } from '../../src/constants/status';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';
import { PasswordService } from '../../src/services/password.service';
import { AcademicService } from '../../src/services/academic.service';

describe('PROMPT 35 — People, Student Enrollment & Academic Context Hardening Tests', () => {
  let collegeA: InstanceType<typeof College>;
  let collegeB: InstanceType<typeof College>;

  let deptA1: InstanceType<typeof Department>;
  let deptA2: InstanceType<typeof Department>;
  let deptB: InstanceType<typeof Department>;

  let courseA1: InstanceType<typeof Course>;
  let courseA2: InstanceType<typeof Course>;
  let courseB: InstanceType<typeof Course>;

  let ayA: InstanceType<typeof AcademicYear>;
  let ayArchivedA: InstanceType<typeof AcademicYear>;
  let ayB: InstanceType<typeof AcademicYear>;

  let semA1: InstanceType<typeof Semester>;
  let semA2: InstanceType<typeof Semester>;
  let semArchivedA: InstanceType<typeof Semester>;
  let semB: InstanceType<typeof Semester>;

  let secA1: InstanceType<typeof Section>;
  let secA2: InstanceType<typeof Section>;

  let subjectA1: InstanceType<typeof Subject>;

  let adminUserA: InstanceType<typeof User>;
  let adminHeaderA: { Authorization: string };

  let adminUserB: InstanceType<typeof User>;
  let adminHeaderB: { Authorization: string };

  let hodUserA1: InstanceType<typeof User>;
  let hodHeaderA1: { Authorization: string };

  let facultyUserA: InstanceType<typeof User>;
  let facultyDocA: InstanceType<typeof Faculty>;
  let facultyHeaderA: { Authorization: string };

  let studentUserA1: InstanceType<typeof User>;
  let studentDocA1: InstanceType<typeof Student>;
  let studentHeaderA1: { Authorization: string };

  let studentUserA2: InstanceType<typeof User>;
  let studentDocA2: InstanceType<typeof Student>;

  let studentDocB: InstanceType<typeof Student>;

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
    await Faculty.init();
    await FacultyAssignment.init();
    await StudentEnrollment.init();
    await InstitutionConfiguration.init();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();

    const passwordHash = await PasswordService.hashPassword('Pass123456');

    // 1. Setup College A & College B
    collegeA = await College.create({
      name: 'College Alpha',
      code: 'CLG-A',
      address: '100 Alpha Boulevard',
      email: 'admin@collegea.edu',
      phone: '+919876543210',
      principal: 'Dr. Alpha Principal',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });

    collegeB = await College.create({
      name: 'College Beta',
      code: 'CLG-B',
      address: '200 Beta Way',
      email: 'admin@collegeb.edu',
      phone: '+919876543211',
      principal: 'Dr. Beta Principal',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });

    // 2. Setup College A InstitutionConfiguration
    await InstitutionConfiguration.create({
      collegeId: collegeA._id,
      institutionType: 'ENGINEERING',
      academicStructure: {
        program: true,
        academicYear: true,
        semester: true,
        section: true,
        subject: true,
        building: false,
        room: false,
      },
    });

    // 3. Departments
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

    deptB = await Department.create({
      collegeId: collegeB._id,
      name: 'Civil Engineering',
      code: 'CIV',
      status: DepartmentStatus.ACTIVE,
      isActive: true,
    });

    // 4. Courses / Programs
    courseA1 = await Course.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      name: 'B.Tech Computer Science',
      code: 'BTCSE',
      durationYears: 4,
      totalSemesters: 8,
      status: 'active',
      isActive: true,
    });

    courseA2 = await Course.create({
      collegeId: collegeA._id,
      departmentId: deptA2._id,
      name: 'B.Tech Electronics',
      code: 'BTECE',
      durationYears: 4,
      totalSemesters: 8,
      status: 'active',
      isActive: true,
    });

    courseB = await Course.create({
      collegeId: collegeB._id,
      departmentId: deptB._id,
      name: 'B.Tech Civil',
      code: 'BTCIV',
      durationYears: 4,
      totalSemesters: 8,
      status: 'active',
      isActive: true,
    });

    // 5. Academic Years
    ayA = await AcademicYear.create({
      collegeId: collegeA._id,
      name: '2026-27',
      startDate: new Date('2026-06-01'),
      endDate: new Date('2027-05-31'),
      isCurrent: true,
      status: 'active',
      isActive: true,
    });

    ayArchivedA = await AcademicYear.create({
      collegeId: collegeA._id,
      name: '2024-25',
      startDate: new Date('2024-06-01'),
      endDate: new Date('2025-05-31'),
      isCurrent: false,
      status: 'archived',
      isActive: false,
    });

    ayB = await AcademicYear.create({
      collegeId: collegeB._id,
      name: '2026-27',
      startDate: new Date('2026-06-01'),
      endDate: new Date('2027-05-31'),
      isCurrent: true,
      status: 'active',
      isActive: true,
    });

    // 6. Semesters
    semA1 = await Semester.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      courseId: courseA1._id,
      academicYearId: ayA._id,
      name: 'Semester 1',
      number: 1,
      startDate: new Date('2026-06-01'),
      endDate: new Date('2026-11-30'),
      status: 'active',
      isActive: true,
    });

    semA2 = await Semester.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      courseId: courseA1._id,
      academicYearId: ayA._id,
      name: 'Semester 2',
      number: 2,
      startDate: new Date('2026-12-01'),
      endDate: new Date('2027-05-31'),
      status: 'active',
      isActive: true,
    });

    semArchivedA = await Semester.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      courseId: courseA1._id,
      academicYearId: ayArchivedA._id,
      name: 'Semester 1 (Archived)',
      number: 1,
      startDate: new Date('2024-06-01'),
      endDate: new Date('2024-11-30'),
      status: 'archived',
      isActive: false,
    });

    semB = await Semester.create({
      collegeId: collegeB._id,
      departmentId: deptB._id,
      courseId: courseB._id,
      academicYearId: ayB._id,
      name: 'Semester 1 Beta',
      number: 1,
      startDate: new Date('2026-06-01'),
      endDate: new Date('2026-11-30'),
      status: 'active',
      isActive: true,
    });

    // 7. Sections
    secA1 = await Section.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      courseId: courseA1._id,
      academicYearId: ayA._id,
      semesterId: semA1._id,
      name: 'A',
      capacity: 60,
      status: 'active',
      isActive: true,
    });

    secA2 = await Section.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      courseId: courseA1._id,
      academicYearId: ayA._id,
      semesterId: semA1._id,
      name: 'B',
      capacity: 60,
      status: 'active',
      isActive: true,
    });

    // 8. Subject
    subjectA1 = await Subject.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      courseId: courseA1._id,
      academicYearId: ayA._id,
      semesterId: semA1._id,
      name: 'Data Structures and Algorithms',
      code: 'CS101',
      credits: 4,
      type: 'theory',
      status: 'active',
      isActive: true,
    });

    // 9. Users & Profiles
    // Admin A
    adminUserA = await User.create({
      instituteId: 'ADMIN-A-01',
      collegeId: collegeA._id,
      name: 'Admin Alpha',
      email: 'admin@collegea.edu',
      passwordHash,
      role: AppRole.COLLEGE_ADMIN,
      accountStatus: AccountStatus.ACTIVE,
      isActive: true,
    });
    adminHeaderA = createTestAuthHeader({
      userId: adminUserA._id.toString(),
      role: AppRole.COLLEGE_ADMIN,
      collegeId: collegeA._id.toString(),
    });

    // Admin B
    adminUserB = await User.create({
      instituteId: 'ADMIN-B-01',
      collegeId: collegeB._id,
      name: 'Admin Beta',
      email: 'admin@collegeb.edu',
      passwordHash,
      role: AppRole.COLLEGE_ADMIN,
      accountStatus: AccountStatus.ACTIVE,
      isActive: true,
    });
    adminHeaderB = createTestAuthHeader({
      userId: adminUserB._id.toString(),
      role: AppRole.COLLEGE_ADMIN,
      collegeId: collegeB._id.toString(),
    });

    // HOD A1 (CSE Department)
    hodUserA1 = await User.create({
      instituteId: 'HOD-A-CSE-01',
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      name: 'Dr. Turing (HOD CSE)',
      email: 'hod.cse@collegea.edu',
      passwordHash,
      role: AppRole.HOD,
      accountStatus: AccountStatus.ACTIVE,
      isActive: true,
    });
    hodHeaderA1 = createTestAuthHeader({
      userId: hodUserA1._id.toString(),
      role: AppRole.HOD,
      collegeId: collegeA._id.toString(),
      departmentId: deptA1._id.toString(),
    });

    // Faculty A
    facultyUserA = await User.create({
      instituteId: 'FAC-A-01',
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      name: 'Prof. Grace Hopper',
      email: 'hopper@collegea.edu',
      passwordHash,
      role: AppRole.FACULTY,
      accountStatus: AccountStatus.ACTIVE,
      isActive: true,
    });
    facultyDocA = await Faculty.create({
      userId: facultyUserA._id,
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      name: 'Prof. Grace Hopper',
      email: 'hopper@collegea.edu',
      employeeId: 'EMP-GH-01',
      designation: 'Associate Professor',
      status: 'active',
      isActive: true,
    });
    facultyHeaderA = createTestAuthHeader({
      userId: facultyUserA._id.toString(),
      role: AppRole.FACULTY,
      collegeId: collegeA._id.toString(),
      departmentId: deptA1._id.toString(),
    });

    // Student A1
    studentUserA1 = await User.create({
      instituteId: 'STU-A-01',
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      name: 'Alice Student',
      email: 'alice@collegea.edu',
      passwordHash,
      role: AppRole.STUDENT,
      accountStatus: AccountStatus.ACTIVE,
      isActive: true,
    });
    studentDocA1 = await Student.create({
      userId: studentUserA1._id,
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      name: 'Alice Student',
      rollNumber: '26CSE001',
      admissionNumber: 'ADM-26-001',
      email: 'alice@collegea.edu',
      status: 'active',
      isActive: true,
      lifecycleState: StudentLifecycleState.ACTIVE,
    });
    studentHeaderA1 = createTestAuthHeader({
      userId: studentUserA1._id.toString(),
      role: AppRole.STUDENT,
      collegeId: collegeA._id.toString(),
      departmentId: deptA1._id.toString(),
    });

    // Student A2
    studentUserA2 = await User.create({
      instituteId: 'STU-A-02',
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      name: 'Bob Student',
      email: 'bob@collegea.edu',
      passwordHash,
      role: AppRole.STUDENT,
      accountStatus: AccountStatus.ACTIVE,
      isActive: true,
    });
    studentDocA2 = await Student.create({
      userId: studentUserA2._id,
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      name: 'Bob Student',
      rollNumber: '26CSE002',
      admissionNumber: 'ADM-26-002',
      email: 'bob@collegea.edu',
      status: 'active',
      isActive: true,
      lifecycleState: StudentLifecycleState.ACTIVE,
    });

    // Student B
    const studentUserB = await User.create({
      instituteId: 'STU-B-01',
      collegeId: collegeB._id,
      departmentId: deptB._id,
      name: 'Charlie Beta',
      email: 'charlie@collegeb.edu',
      passwordHash,
      role: AppRole.STUDENT,
      accountStatus: AccountStatus.ACTIVE,
      isActive: true,
    });
    studentDocB = await Student.create({
      userId: studentUserB._id,
      collegeId: collegeB._id,
      departmentId: deptB._id,
      name: 'Charlie Beta',
      rollNumber: '26CIV001',
      admissionNumber: 'ADM-26-B001',
      email: 'charlie@collegeb.edu',
      status: 'active',
      isActive: true,
      lifecycleState: StudentLifecycleState.ACTIVE,
    });
  });

  // =========================================================================
  // TEST A: College Admin A can manage StudentEnrollment in College A
  // =========================================================================
  describe('TEST A: College Admin A Enrollment Management', () => {
    it('successfully enrolls student into canonical academic context and syncs caches', async () => {
      const res = await request(app)
        .post('/api/v1/academics/enrollments')
        .set(adminHeaderA)
        .send({
          studentId: studentDocA1._id.toString(),
          courseId: courseA1._id.toString(),
          academicYearId: ayA._id.toString(),
          semesterId: semA1._id.toString(),
          sectionId: secA1._id.toString(),
          cohort: '2026-30',
          academicStage: 'Year 1',
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.status).toBe('active');
      expect(res.body.data.studentId.toString()).toBe(studentDocA1._id.toString());
      expect(res.body.data.sectionId.toString()).toBe(secA1._id.toString());

      // Canonical current enrollment resolver check
      const currentRes = await request(app)
        .get(`/api/v1/academics/students/${studentDocA1._id}/current-enrollment`)
        .set(adminHeaderA);

      expect(currentRes.status).toBe(200);
      expect(currentRes.body.data.academicContext).toBeDefined();
      expect(currentRes.body.data.academicContext.courseCode).toBe('BTCSE');
      expect(currentRes.body.data.academicContext.sectionName).toBe('A');
      expect(currentRes.body.data.academicContext.formattedContext).toContain('BTCSE');

      // Verify Student model derived cache was safely updated
      const updatedStudent = await Student.findById(studentDocA1._id);
      expect(updatedStudent?.sectionId?.toString()).toBe(secA1._id.toString());
      expect(updatedStudent?.semesterId?.toString()).toBe(semA1._id.toString());
    });
  });

  // =========================================================================
  // TEST B: College Admin A cannot manage College B enrollment (Tenant Isolation)
  // =========================================================================
  describe('TEST B: Tenant Isolation', () => {
    it('rejects attempt by College Admin A to enroll a student from College B', async () => {
      const res = await request(app)
        .post('/api/v1/academics/enrollments')
        .set(adminHeaderA)
        .send({
          studentId: studentDocB._id.toString(),
          courseId: courseA1._id.toString(),
          academicYearId: ayA._id.toString(),
          semesterId: semA1._id.toString(),
          sectionId: secA1._id.toString(),
        });

      expect(res.status).toBe(400);
      expect(res.body.message || res.body.error?.message).toMatch(/belong to the specified college/i);
    });

    it('rejects attempt by College Admin A to access College B student current enrollment', async () => {
      const res = await request(app)
        .get(`/api/v1/academics/students/${studentDocB._id}/current-enrollment`)
        .set(adminHeaderA);

      expect(res.status).toBe(403);
      expect(res.body.message || res.body.error?.message).toMatch(/cross-college/i);
    });

    it('rejects attempt by College Admin B to enroll a student from College A into College B', async () => {
      const secB = await Section.create({
        collegeId: collegeB._id,
        departmentId: deptB._id,
        courseId: courseB._id,
        academicYearId: ayB._id,
        semesterId: semB._id,
        name: 'A',
        capacity: 60,
        status: 'active',
        isActive: true,
      });

      const res = await request(app)
        .post('/api/v1/academics/enrollments')
        .set(adminHeaderB)
        .send({
          studentId: studentDocA1._id.toString(),
          courseId: courseB._id.toString(),
          academicYearId: ayB._id.toString(),
          semesterId: semB._id.toString(),
          sectionId: secB._id.toString(),
        });

      expect(res.status).toBe(400);
      expect(res.body.message || res.body.error?.message).toMatch(/belong to the specified college/i);
    });
  });

  // =========================================================================
  // TEST C: HOD A1 Department Scoping
  // =========================================================================
  describe('TEST C: HOD Department Scope Hardening', () => {
    it('prevents HOD A1 (CSE) from enrolling a student into another department (ECE)', async () => {
      // Create student belonging to ECE
      const eceStudent = await Student.create({
        collegeId: collegeA._id,
        departmentId: deptA2._id,
        name: 'Eve ECE Student',
        rollNumber: '26ECE001',
        admissionNumber: 'ADM-26-E001',
        email: 'eve@collegea.edu',
        status: 'active',
        isActive: true,
        lifecycleState: StudentLifecycleState.ACTIVE,
      });

      const res = await request(app)
        .post('/api/v1/academics/enrollments')
        .set(hodHeaderA1)
        .send({
          studentId: eceStudent._id.toString(),
          courseId: courseA2._id.toString(),
          academicYearId: ayA._id.toString(),
          semesterId: semA1._id.toString(),
        });

      expect(res.status).toBe(403);
      expect(res.body.message || res.body.error?.message).toMatch(/assigned department/i);
    });

    it('allows HOD A1 to enroll a student belonging to their own department (CSE)', async () => {
      const res = await request(app)
        .post('/api/v1/academics/enrollments')
        .set(hodHeaderA1)
        .send({
          studentId: studentDocA2._id.toString(),
          courseId: courseA1._id.toString(),
          academicYearId: ayA._id.toString(),
          semesterId: semA1._id.toString(),
          sectionId: secA1._id.toString(),
        });

      expect(res.status).toBe(201);
      expect(res.body.data.status).toBe('active');
    });
  });

  // =========================================================================
  // TEST D: Faculty Cannot Administer Enrollment
  // =========================================================================
  describe('TEST D: Faculty Role Isolation', () => {
    it('strictly forbids Faculty from creating an enrollment record (403 Forbidden)', async () => {
      const res = await request(app)
        .post('/api/v1/academics/enrollments')
        .set(facultyHeaderA)
        .send({
          studentId: studentDocA1._id.toString(),
          courseId: courseA1._id.toString(),
          academicYearId: ayA._id.toString(),
          semesterId: semA1._id.toString(),
          sectionId: secA1._id.toString(),
        });

      expect(res.status).toBe(403);
    });
  });

  // =========================================================================
  // TEST E: Student Self-Scope Enforcement
  // =========================================================================
  describe('TEST E: Student Self-Scope Hardening', () => {
    it('strictly forbids Student from creating or modifying their own enrollment (403 Forbidden)', async () => {
      const res = await request(app)
        .post('/api/v1/academics/enrollments')
        .set(studentHeaderA1)
        .send({
          studentId: studentDocA1._id.toString(),
          courseId: courseA1._id.toString(),
          academicYearId: ayA._id.toString(),
          semesterId: semA1._id.toString(),
          sectionId: secA1._id.toString(),
        });

      expect(res.status).toBe(403);
    });

    it('allows Student to read their own current enrollment via /students/me/current-enrollment', async () => {
      // First enroll studentDocA1 via Admin
      await StudentEnrollment.create({
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        courseId: courseA1._id,
        academicYearId: ayA._id,
        semesterId: semA1._id,
        sectionId: secA1._id,
        studentId: studentDocA1._id,
        status: 'active',
        enrollmentDate: new Date(),
        cohort: '2026-30',
        academicStage: 'Year 1',
      });

      const res = await request(app)
        .get('/api/v1/academics/students/me/current-enrollment')
        .set(studentHeaderA1);

      expect(res.status).toBe(200);
      expect(res.body.data.academicContext).toBeDefined();
      expect(res.body.data.academicContext.courseCode).toBe('BTCSE');
    });

    it('forbids Student from accessing another student current enrollment', async () => {
      const res = await request(app)
        .get(`/api/v1/academics/students/${studentDocA2._id}/current-enrollment`)
        .set(studentHeaderA1);

      expect(res.status).toBe(403);
      expect(res.body.message || res.body.error?.message).toMatch(/view their own enrollment/i);
    });
  });

  // =========================================================================
  // TEST F: Faculty Student Visibility follows Teaching Context
  // =========================================================================
  describe('TEST F: Faculty Teaching Context Roster Visibility', () => {
    it('limits Faculty roster visibility strictly to sections assigned via FacultyAssignment', async () => {
      // Enroll Student 1 in Section A
      await StudentEnrollment.create({
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        courseId: courseA1._id,
        academicYearId: ayA._id,
        semesterId: semA1._id,
        sectionId: secA1._id,
        studentId: studentDocA1._id,
        status: 'active',
        enrollmentDate: new Date(),
      });

      // Enroll Student 2 in Section B
      await StudentEnrollment.create({
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        courseId: courseA1._id,
        academicYearId: ayA._id,
        semesterId: semA1._id,
        sectionId: secA2._id,
        studentId: studentDocA2._id,
        status: 'active',
        enrollmentDate: new Date(),
      });

      // Assign Faculty Hopper ONLY to Section A
      await FacultyAssignment.create({
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        courseId: courseA1._id,
        academicYearId: ayA._id,
        semesterId: semA1._id,
        sectionId: secA1._id,
        subjectId: subjectA1._id,
        facultyId: facultyDocA._id,
        facultyName: 'Prof. Grace Hopper',
        hoursPerWeek: 4,
        role: 'primary',
        status: 'active',
        isActive: true,
      });

      // Faculty requests teaching roster
      const rosterRes = await request(app)
        .get('/api/v1/academics/faculty-roster/students')
        .set(facultyHeaderA);

      expect(rosterRes.status).toBe(200);
      expect(rosterRes.body.data.items).toHaveLength(1);
      expect(rosterRes.body.data.items[0].student._id.toString()).toBe(studentDocA1._id.toString());
      expect(rosterRes.body.data.items[0].student.rollNumber).toBe('26CSE001');

      // Student 2 in Section B must NOT appear in Faculty Hopper's roster
      const idsInRoster = rosterRes.body.data.items.map((i: any) => i.student._id.toString());
      expect(idsInRoster).not.toContain(studentDocA2._id.toString());
    });
  });

  // =========================================================================
  // TEST G: Section Optionality
  // =========================================================================
  describe('TEST G: Section Optionality in Student Enrollment', () => {
    it('succeeds without sectionId when institution disables Section', async () => {
      // Disable section in InstitutionConfiguration
      await InstitutionConfiguration.findOneAndUpdate(
        { collegeId: collegeA._id },
        { 'academicStructure.section': false }
      );

      const res = await request(app)
        .post('/api/v1/academics/enrollments')
        .set(adminHeaderA)
        .send({
          studentId: studentDocA1._id.toString(),
          courseId: courseA1._id.toString(),
          academicYearId: ayA._id.toString(),
          semesterId: semA1._id.toString(),
          sectionId: null, // Omitted / null section
        });

      expect(res.status).toBe(201);
      expect(res.body.data.status).toBe('active');
      expect(res.body.data.sectionId).toBeUndefined();

      // Resolver should handle sectionless enrollment without errors
      const currentRes = await request(app)
        .get(`/api/v1/academics/students/${studentDocA1._id}/current-enrollment`)
        .set(adminHeaderA);

      expect(currentRes.status).toBe(200);
      expect(currentRes.body.data.academicContext.sectionId).toBeNull();
      expect(currentRes.body.data.academicContext.formattedContext).not.toContain('Section');
    });
  });

  // =========================================================================
  // DATA INTEGRITY & LIFECYCLE TESTS
  // =========================================================================
  describe('DATA INTEGRITY & LIFECYCLE', () => {
    it('prevents duplicate active enrollments for the same student in the same semester (409 Conflict)', async () => {
      // Initial active enrollment
      await request(app)
        .post('/api/v1/academics/enrollments')
        .set(adminHeaderA)
        .send({
          studentId: studentDocA1._id.toString(),
          courseId: courseA1._id.toString(),
          academicYearId: ayA._id.toString(),
          semesterId: semA1._id.toString(),
          sectionId: secA1._id.toString(),
        });

      // Second attempt to enroll student into the same active semester
      const duplicateRes = await request(app)
        .post('/api/v1/academics/enrollments')
        .set(adminHeaderA)
        .send({
          studentId: studentDocA1._id.toString(),
          courseId: courseA1._id.toString(),
          academicYearId: ayA._id.toString(),
          semesterId: semA1._id.toString(),
          sectionId: secA2._id.toString(),
        });

      expect(duplicateRes.status).toBe(409);
      expect(duplicateRes.body.message || duplicateRes.body.error?.message).toMatch(/already actively enrolled/i);
    });

    it('allows coexistence of historical completed enrollments and a new active enrollment', async () => {
      // 1. Create completed historical enrollment for Semester 1
      await StudentEnrollment.create({
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        courseId: courseA1._id,
        academicYearId: ayA._id,
        semesterId: semA1._id,
        sectionId: secA1._id,
        studentId: studentDocA1._id,
        status: 'completed',
        enrollmentDate: new Date('2026-06-01'),
      });

      // Create a section belonging to Semester 2
      const secSem2 = await Section.create({
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        courseId: courseA1._id,
        academicYearId: ayA._id,
        semesterId: semA2._id,
        name: 'A',
        capacity: 60,
        status: 'active',
        isActive: true,
      });

      // 2. Create new active enrollment for Semester 2
      const activeRes = await request(app)
        .post('/api/v1/academics/enrollments')
        .set(adminHeaderA)
        .send({
          studentId: studentDocA1._id.toString(),
          courseId: courseA1._id.toString(),
          academicYearId: ayA._id.toString(),
          semesterId: semA2._id.toString(),
          sectionId: secSem2._id.toString(),
        });

      expect(activeRes.status).toBe(201);
      expect(activeRes.body.data.status).toBe('active');

      // Both records exist in the database
      const count = await StudentEnrollment.countDocuments({ studentId: studentDocA1._id });
      expect(count).toBe(2);

      // Current resolver correctly returns the ACTIVE Semester 2 enrollment
      const resolverResult = await AcademicService.getStudentCurrentEnrollment(studentDocA1._id.toString(), {
        id: adminUserA._id.toString(),
        role: AppRole.COLLEGE_ADMIN,
        collegeId: collegeA._id.toString(),
      } as any);

      expect(resolverResult.academicContext?.semesterId).toBe(semA2._id.toString());
      expect(resolverResult.academicContext?.semesterNumber).toBe(2);
    });

    it('rejects cross-department hierarchy mismatch (student CSE + course ECE)', async () => {
      const res = await request(app)
        .post('/api/v1/academics/enrollments')
        .set(adminHeaderA)
        .send({
          studentId: studentDocA1._id.toString(), // CSE student
          courseId: courseA2._id.toString(),      // ECE course
          academicYearId: ayA._id.toString(),
          semesterId: semA1._id.toString(),
          sectionId: secA1._id.toString(),
        });

      expect(res.status).toBe(400);
      expect(res.body.message || res.body.error?.message).toMatch(/same department/i);
    });

    it('rejects enrollment into an archived/inactive academic year or semester', async () => {
      const res = await request(app)
        .post('/api/v1/academics/enrollments')
        .set(adminHeaderA)
        .send({
          studentId: studentDocA1._id.toString(),
          courseId: courseA1._id.toString(),
          academicYearId: ayArchivedA._id.toString(), // Archived AY
          semesterId: semArchivedA._id.toString(),    // Archived Semester
          sectionId: secA1._id.toString(),
        });

      expect(res.status).toBe(400);
      expect(res.body.message || res.body.error?.message).toMatch(/inactive or archived/i);
    });
  });

  // =========================================================================
  // LEGACY POINTER ISOLATION TEST
  // =========================================================================
  describe('LEGACY POINTER ISOLATION', () => {
    it('ensures downstream current context resolution relies on StudentEnrollment even if Student legacy cache is empty or stale', async () => {
      // Intentionally leave legacy fields on Student pointing to different ObjectIds
      const dummySemesterId = new mongoose.Types.ObjectId();
      const dummySectionId = new mongoose.Types.ObjectId();
      await Student.findByIdAndUpdate(studentDocA1._id, {
        semesterId: dummySemesterId,
        sectionId: dummySectionId,
      });

      // Authoritative StudentEnrollment
      await StudentEnrollment.create({
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        courseId: courseA1._id,
        academicYearId: ayA._id,
        semesterId: semA1._id,
        sectionId: secA1._id,
        studentId: studentDocA1._id,
        status: 'active',
        enrollmentDate: new Date(),
      });

      const currentContext = await AcademicService.getStudentCurrentEnrollment(studentDocA1._id.toString(), {
        id: adminUserA._id.toString(),
        role: AppRole.COLLEGE_ADMIN,
        collegeId: collegeA._id.toString(),
      } as any);

      // Must be authoritative values from StudentEnrollment, NOT stale legacy values
      expect(currentContext.academicContext?.semesterId).toBe(semA1._id.toString());
      expect(currentContext.academicContext?.sectionId).toBe(secA1._id.toString());
    });
  });
});
