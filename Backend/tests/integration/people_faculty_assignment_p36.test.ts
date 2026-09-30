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
import { Faculty } from '../../src/models/faculty.model';
import { Student } from '../../src/models/student.model';
import { FacultyAssignment } from '../../src/models/facultyAssignment.model';
import { AttendanceSession } from '../../src/models/attendanceSession.model';
import { Timetable } from '../../src/models/timetable.model';
import { InstitutionConfiguration } from '../../src/models/institutionConfiguration.model';
import { AppRole } from '../../src/constants/roles';
import { AccountStatus, CollegeStatus, DepartmentStatus, AttendanceSessionStatus } from '../../src/constants/status';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';
import { PasswordService } from '../../src/services/password.service';

describe('PROMPT 36 — ACADEX Faculty Assignment & Teaching Context Hardening Tests', () => {
  let collegeA: InstanceType<typeof College>;
  let collegeB: InstanceType<typeof College>;

  let deptA1: InstanceType<typeof Department>;
  let deptA2: InstanceType<typeof Department>;
  let deptB: InstanceType<typeof Department>;

  let courseA1: InstanceType<typeof Course>;
  let courseB: InstanceType<typeof Course>;

  let ayA: InstanceType<typeof AcademicYear>;
  let ayB: InstanceType<typeof AcademicYear>;

  let semA1: InstanceType<typeof Semester>;
  let semA2: InstanceType<typeof Semester>;

  let secA1: InstanceType<typeof Section>;
  let secA2: InstanceType<typeof Section>;

  let subjectA1: InstanceType<typeof Subject>;
  let subjectA2: InstanceType<typeof Subject>;
  let subjectB: InstanceType<typeof Subject>;

  let adminUserA: InstanceType<typeof User>;
  let adminHeaderA: { Authorization: string };

  let hodUserA1: InstanceType<typeof User>;
  let hodHeaderA1: { Authorization: string };

  let hodUserA2: InstanceType<typeof User>;
  let hodHeaderA2: { Authorization: string };

  let facultyUserA1: InstanceType<typeof User>;
  let facultyDocA1: InstanceType<typeof Faculty>;
  let facultyHeaderA1: { Authorization: string };

  let facultyUserA2: InstanceType<typeof User>;
  let facultyHeaderA2: { Authorization: string };

  let facultyDocInactiveA: InstanceType<typeof Faculty>;
  let facultyDocB: InstanceType<typeof Faculty>;

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
    await AttendanceSession.init();
    await Timetable.init();
    await InstitutionConfiguration.init();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();

    const passwordHash = await PasswordService.hashPassword('Pass123456');

    // 1. Colleges
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

    // 2. Institution Configurations
    await InstitutionConfiguration.create({
      collegeId: collegeA._id,
      academicStructure: {
        department: true,
        course: true,
        academicYear: true,
        semester: true,
        section: true,
        subject: true,
      },
    });

    // 3. Departments
    deptA1 = await Department.create({
      collegeId: collegeA._id,
      name: 'Computer Engineering',
      code: 'CSE',
      status: DepartmentStatus.ACTIVE,
    });

    deptA2 = await Department.create({
      collegeId: collegeA._id,
      name: 'Electrical Engineering',
      code: 'EEE',
      status: DepartmentStatus.ACTIVE,
    });

    deptB = await Department.create({
      collegeId: collegeB._id,
      name: 'Mechanical Engineering',
      code: 'MECH',
      status: DepartmentStatus.ACTIVE,
    });

    // 4. Courses
    courseA1 = await Course.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      name: 'B.Tech CSE',
      code: 'BTCSE',
      durationYears: 4,
      totalSemesters: 8,
      status: 'active',
      isActive: true,
    });

    courseB = await Course.create({
      collegeId: collegeB._id,
      departmentId: deptB._id,
      name: 'B.Tech MECH',
      code: 'BTMECH',
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
      name: 'Semester 5',
      number: 5,
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
      name: 'Semester 6',
      number: 6,
      startDate: new Date('2026-12-01'),
      endDate: new Date('2027-05-31'),
      status: 'active',
      isActive: true,
    });

    const semB = await Semester.create({
      collegeId: collegeB._id,
      departmentId: deptB._id,
      courseId: courseB._id,
      academicYearId: ayB._id,
      name: 'Semester 5',
      number: 5,
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
      name: 'Section A',
      capacity: 60,
      status: 'active',
      isActive: true,
    });

    secA2 = await Section.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      courseId: courseA1._id,
      academicYearId: ayA._id,
      semesterId: semA2._id,
      name: 'Section B (Sem 6)',
      capacity: 60,
      status: 'active',
      isActive: true,
    });

    // 8. Subjects
    subjectA1 = await Subject.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      courseId: courseA1._id,
      academicYearId: ayA._id,
      semesterId: semA1._id,
      name: 'Database Management Systems',
      code: 'CS501',
      credits: 4,
      status: 'active',
      isActive: true,
    });

    subjectA2 = await Subject.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      courseId: courseA1._id,
      academicYearId: ayA._id,
      semesterId: semA2._id,
      name: 'Compiler Design',
      code: 'CS601',
      credits: 4,
      status: 'active',
      isActive: true,
    });

    subjectB = await Subject.create({
      collegeId: collegeB._id,
      departmentId: deptB._id,
      courseId: courseB._id,
      academicYearId: ayB._id,
      semesterId: semB._id,
      name: 'Thermodynamics',
      code: 'ME501',
      credits: 4,
      status: 'active',
      isActive: true,
    });

    // 9. Users & Faculty
    adminUserA = await User.create({
      instituteId: 'ADMIN-A-01',
      name: 'Admin Alpha',
      email: 'admin.a@alpha.edu',
      passwordHash,
      role: AppRole.COLLEGE_ADMIN,
      collegeId: collegeA._id,
      accountStatus: AccountStatus.ACTIVE,
      isActive: true,
    });
    adminHeaderA = createTestAuthHeader({
      userId: adminUserA._id.toString(),
      role: AppRole.COLLEGE_ADMIN,
      collegeId: collegeA._id.toString(),
    });

    hodUserA1 = await User.create({
      instituteId: 'HOD-A-CSE-01',
      name: 'Dr. Turing (HOD CSE)',
      email: 'hod.cse@alpha.edu',
      passwordHash,
      role: AppRole.HOD,
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      accountStatus: AccountStatus.ACTIVE,
      isActive: true,
    });
    hodHeaderA1 = createTestAuthHeader({
      userId: hodUserA1._id.toString(),
      role: AppRole.HOD,
      collegeId: collegeA._id.toString(),
      departmentId: deptA1._id.toString(),
    });

    hodUserA2 = await User.create({
      instituteId: 'HOD-A-EEE-01',
      name: 'Dr. Tesla (HOD EEE)',
      email: 'hod.eee@alpha.edu',
      passwordHash,
      role: AppRole.HOD,
      collegeId: collegeA._id,
      departmentId: deptA2._id,
      accountStatus: AccountStatus.ACTIVE,
      isActive: true,
    });
    hodHeaderA2 = createTestAuthHeader({
      userId: hodUserA2._id.toString(),
      role: AppRole.HOD,
      collegeId: collegeA._id.toString(),
      departmentId: deptA2._id.toString(),
    });

    // Faculty A1
    facultyUserA1 = await User.create({
      instituteId: 'FAC-A-01',
      name: 'Dr. Same Name',
      email: 'faculty1@alpha.edu',
      passwordHash,
      role: AppRole.FACULTY,
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      accountStatus: AccountStatus.ACTIVE,
      isActive: true,
    });
    facultyHeaderA1 = createTestAuthHeader({
      userId: facultyUserA1._id.toString(),
      role: AppRole.FACULTY,
      collegeId: collegeA._id.toString(),
      departmentId: deptA1._id.toString(),
    });

    facultyDocA1 = await Faculty.create({
      userId: facultyUserA1._id,
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      name: 'Dr. Same Name',
      email: 'faculty1@alpha.edu',
      employeeId: 'FAC001',
      designation: 'Associate Professor',
      status: 'active',
      isActive: true,
    });

    // Faculty A2 (Identical name for Prompt 36 canonical identity test)
    facultyUserA2 = await User.create({
      instituteId: 'FAC-A-02',
      name: 'Dr. Same Name',
      email: 'faculty2@alpha.edu',
      passwordHash,
      role: AppRole.FACULTY,
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      accountStatus: AccountStatus.ACTIVE,
      isActive: true,
    });
    facultyHeaderA2 = createTestAuthHeader({
      userId: facultyUserA2._id.toString(),
      role: AppRole.FACULTY,
      collegeId: collegeA._id.toString(),
      departmentId: deptA1._id.toString(),
    });

    await Faculty.create({
      userId: facultyUserA2._id,
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      name: 'Dr. Same Name',
      email: 'faculty2@alpha.edu',
      employeeId: 'FAC002',
      designation: 'Assistant Professor',
      status: 'active',
      isActive: true,
    });

    // Inactive Faculty
    facultyDocInactiveA = await Faculty.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      name: 'Dr. Inactive',
      email: 'faculty.inactive@alpha.edu',
      employeeId: 'FAC_INACTIVE',
      designation: 'Professor',
      status: 'inactive',
      isActive: false,
    });

    // Faculty from College B
    facultyDocB = await Faculty.create({
      collegeId: collegeB._id,
      departmentId: deptB._id,
      name: 'Dr. Beta Faculty',
      email: 'faculty.beta@beta.edu',
      employeeId: 'FAC_B001',
      designation: 'Professor',
      status: 'active',
      isActive: true,
    });
  });

  describe('Security & Authorization Test Matrix (Section 44)', () => {
    it('TEST A: Valid Assignment creation succeeds with 201', async () => {
      const payload = {
        facultyId: facultyDocA1._id.toString(),
        departmentId: deptA1._id.toString(),
        courseId: courseA1._id.toString(),
        academicYearId: ayA._id.toString(),
        semesterId: semA1._id.toString(),
        sectionId: secA1._id.toString(),
        subjectId: subjectA1._id.toString(),
      };

      const res = await request(app)
        .post('/api/v1/academics/faculty-assignments')
        .set(hodHeaderA1)
        .send(payload);

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toBeDefined();
      expect(res.body.data.facultyId).toBe(facultyDocA1._id.toString());
      expect(res.body.data.subjectId).toBe(subjectA1._id.toString());
      expect(res.body.data.status).toBe('active');
      expect(res.body.data.isActive).toBe(true);
    });

    it('TEST B: Cross-college Faculty assignment is safely rejected', async () => {
      const payload = {
        facultyId: facultyDocB._id.toString(), // From College B!
        departmentId: deptA1._id.toString(),
        courseId: courseA1._id.toString(),
        academicYearId: ayA._id.toString(),
        semesterId: semA1._id.toString(),
        sectionId: secA1._id.toString(),
        subjectId: subjectA1._id.toString(),
      };

      const res = await request(app)
        .post('/api/v1/academics/faculty-assignments')
        .set(adminHeaderA)
        .send(payload);

      expect(res.status).toBe(400);
      expect(res.body.error?.message || res.body.message).toMatch(/Faculty.*not belong.*college|Faculty.*not found/i);
    });

    it('TEST C: Cross-college Subject assignment is safely rejected', async () => {
      const payload = {
        facultyId: facultyDocA1._id.toString(),
        departmentId: deptA1._id.toString(),
        courseId: courseA1._id.toString(),
        academicYearId: ayA._id.toString(),
        semesterId: semA1._id.toString(),
        sectionId: secA1._id.toString(),
        subjectId: subjectB._id.toString(), // From College B!
      };

      const res = await request(app)
        .post('/api/v1/academics/faculty-assignments')
        .set(adminHeaderA)
        .send(payload);

      expect(res.status).toBe(400);
      expect(res.body.error?.message || res.body.message).toMatch(/Subject.*not belong.*college|Subject.*not found/i);
    });

    it('TEST D: Cross-department HOD cannot assign faculty to another department', async () => {
      const payload = {
        facultyId: facultyDocA1._id.toString(),
        departmentId: deptA1._id.toString(), // Dept A1 (CSE)
        courseId: courseA1._id.toString(),
        academicYearId: ayA._id.toString(),
        semesterId: semA1._id.toString(),
        sectionId: secA1._id.toString(),
        subjectId: subjectA1._id.toString(),
      };

      // HOD A2 belongs to EEE, not CSE
      const res = await request(app)
        .post('/api/v1/academics/faculty-assignments')
        .set(hodHeaderA2)
        .send(payload);

      expect(res.status).toBe(403);
      expect(res.body.error?.message || res.body.message).toMatch(/HOD can only assign faculty within their (assigned|own) department/i);
    });

    it('TEST E: Inactive Faculty cannot receive new active assignments', async () => {
      const payload = {
        facultyId: facultyDocInactiveA._id.toString(), // Inactive!
        departmentId: deptA1._id.toString(),
        courseId: courseA1._id.toString(),
        academicYearId: ayA._id.toString(),
        semesterId: semA1._id.toString(),
        sectionId: secA1._id.toString(),
        subjectId: subjectA1._id.toString(),
      };

      const res = await request(app)
        .post('/api/v1/academics/faculty-assignments')
        .set(adminHeaderA)
        .send(payload);

      expect(res.status).toBe(400);
      expect(res.body.error?.message || res.body.message).toMatch(/Cannot assign an inactive faculty member|inactive/i);
    });

    it('TEST F: Duplicate active assignment is safely rejected with 409 Conflict', async () => {
      const payload = {
        facultyId: facultyDocA1._id.toString(),
        departmentId: deptA1._id.toString(),
        courseId: courseA1._id.toString(),
        academicYearId: ayA._id.toString(),
        semesterId: semA1._id.toString(),
        sectionId: secA1._id.toString(),
        subjectId: subjectA1._id.toString(),
      };

      // First creation
      const res1 = await request(app)
        .post('/api/v1/academics/faculty-assignments')
        .set(adminHeaderA)
        .send(payload);
      expect(res1.status).toBe(201);

      // Duplicate submission
      const res2 = await request(app)
        .post('/api/v1/academics/faculty-assignments')
        .set(adminHeaderA)
        .send(payload);

      expect(res2.status).toBe(409);
      expect(res2.body.error?.message || res2.body.message).toMatch(/already assigned|already exists/i);
    });

    it('TEST G: Subject belonging to another semester/course is rejected', async () => {
      const payload = {
        facultyId: facultyDocA1._id.toString(),
        departmentId: deptA1._id.toString(),
        courseId: courseA1._id.toString(),
        academicYearId: ayA._id.toString(),
        semesterId: semA1._id.toString(), // Sem 5
        sectionId: secA1._id.toString(),
        subjectId: subjectA2._id.toString(), // Belongs to Sem 6!
      };

      const res = await request(app)
        .post('/api/v1/academics/faculty-assignments')
        .set(adminHeaderA)
        .send(payload);

      expect(res.status).toBe(400);
      expect(res.body.error?.message || res.body.message).toMatch(/Subject does not belong to the specified semester|course/i);
    });

    it('TEST H: Section belonging to another semester is rejected', async () => {
      const payload = {
        facultyId: facultyDocA1._id.toString(),
        departmentId: deptA1._id.toString(),
        courseId: courseA1._id.toString(),
        academicYearId: ayA._id.toString(),
        semesterId: semA1._id.toString(), // Sem 5
        sectionId: secA2._id.toString(), // Belongs to Sem 6!
        subjectId: subjectA1._id.toString(),
      };

      const res = await request(app)
        .post('/api/v1/academics/faculty-assignments')
        .set(adminHeaderA)
        .send(payload);

      expect(res.status).toBe(400);
      expect(res.body.error?.message || res.body.message).toMatch(/Section semester does not match selected semester|belong/i);
    });

    it('TEST I: Section disabled allows valid assignment without sectionId', async () => {
      // Configure college to disable sections
      await InstitutionConfiguration.updateOne(
        { collegeId: collegeA._id },
        { $set: { 'academicStructure.section': false } }
      );

      const payload = {
        facultyId: facultyDocA1._id.toString(),
        departmentId: deptA1._id.toString(),
        courseId: courseA1._id.toString(),
        academicYearId: ayA._id.toString(),
        semesterId: semA1._id.toString(),
        subjectId: subjectA1._id.toString(),
        // No sectionId!
      };

      const res = await request(app)
        .post('/api/v1/academics/faculty-assignments')
        .set(adminHeaderA)
        .send(payload);

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.sectionId).toBeFalsy();
    });

    it('TEST J: Canonical Faculty Identity fails closed without name-based bypass', async () => {
      // Both facultyDocA1 and facultyDocA2 have name "Dr. Same Name"
      // Create assignment for Faculty 1 only
      await FacultyAssignment.create({
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        courseId: courseA1._id,
        academicYearId: ayA._id,
        semesterId: semA1._id,
        sectionId: secA1._id,
        subjectId: subjectA1._id,
        facultyId: facultyDocA1._id,
        facultyName: facultyDocA1.name,
        status: 'active',
        isActive: true,
      });

      // Faculty 1 requests /my
      const res1 = await request(app)
        .get('/api/v1/academics/faculty-assignments/my')
        .set(facultyHeaderA1);

      expect(res1.status).toBe(200);
      expect(res1.body.data.length).toBe(1);
      expect(res1.body.data[0].facultyId.toString()).toBe(facultyDocA1._id.toString());

      // Faculty 2 (same name!) requests /my
      const res2 = await request(app)
        .get('/api/v1/academics/faculty-assignments/my')
        .set(facultyHeaderA2);

      expect(res2.status).toBe(200);
      expect(res2.body.data.length).toBe(0); // Cannot see Faculty 1's assignment merely because they share a name!
    });
  });

  describe('Lifecycle & Historical Safety Test Matrix (Section 45)', () => {
    it('1 & 2. Active assignment update revalidates full context and updates lifecycle', async () => {
      const assignment = await FacultyAssignment.create({
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        courseId: courseA1._id,
        academicYearId: ayA._id,
        semesterId: semA1._id,
        sectionId: secA1._id,
        subjectId: subjectA1._id,
        facultyId: facultyDocA1._id,
        facultyName: facultyDocA1.name,
        status: 'active',
        isActive: true,
      });

      // Attempt to update with invalid cross-context subject
      const badUpdate = await request(app)
        .put(`/api/v1/academics/faculty-assignments/${assignment._id}`)
        .set(adminHeaderA)
        .send({ subjectId: subjectA2._id.toString() }); // Subject A2 belongs to Sem 6!

      expect(badUpdate.status).toBe(400);

      // Valid update: end assignment lifecycle
      const validUpdate = await request(app)
        .put(`/api/v1/academics/faculty-assignments/${assignment._id}`)
        .set(adminHeaderA)
        .send({ status: 'ended' });

      expect(validUpdate.status).toBe(200);
      expect(validUpdate.body.data.status).toBe('ended');
      expect(validUpdate.body.data.isActive).toBe(false);
      expect(validUpdate.body.data.endedAt).toBeDefined();
    });

    it('3, 4, 6 & 8. Assignment referenced by historical Attendance is archived, not hard-deleted', async () => {
      const assignment = await FacultyAssignment.create({
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        courseId: courseA1._id,
        academicYearId: ayA._id,
        semesterId: semA1._id,
        sectionId: secA1._id,
        subjectId: subjectA1._id,
        facultyId: facultyDocA1._id,
        facultyName: facultyDocA1.name,
        status: 'active',
        isActive: true,
      });

      // Create historical AttendanceSession referencing this assignment
      await AttendanceSession.create({
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        courseId: courseA1._id,
        academicYearId: ayA._id,
        semesterId: semA1._id,
        sectionId: secA1._id,
        sectionName: 'Section A',
        facultyId: facultyDocA1._id,
        facultyAssignmentId: assignment._id,
        subjectId: subjectA1._id,
        subjectName: 'Database Management Systems',
        timeSlot: '09:00 - 10:00',
        date: new Date(),
        records: [],
        status: AttendanceSessionStatus.LOCKED,
        isSubmitted: true,
        isLocked: true,
      });

      // Request delete
      const delRes = await request(app)
        .delete(`/api/v1/academics/faculty-assignments/${assignment._id}`)
        .set(adminHeaderA);

      expect(delRes.status).toBe(200);
      expect(delRes.body.message).toMatch(/archived to preserve historical records/i);

      // Verify assignment document still exists with archived status
      const archivedDoc = await FacultyAssignment.findById(assignment._id);
      expect(archivedDoc).not.toBeNull();
      expect(archivedDoc?.status).toBe('archived');
      expect(archivedDoc?.isActive).toBe(false);

      // Historical attendance remains intact
      const attendance = await AttendanceSession.findOne({ facultyAssignmentId: assignment._id });
      expect(attendance).not.toBeNull();
    });

    it('7. Unreferenced assignment is safely hard-deleted', async () => {
      const assignment = await FacultyAssignment.create({
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        courseId: courseA1._id,
        academicYearId: ayA._id,
        semesterId: semA1._id,
        sectionId: secA1._id,
        subjectId: subjectA1._id,
        facultyId: facultyDocA1._id,
        facultyName: facultyDocA1.name,
        status: 'active',
        isActive: true,
      });

      const delRes = await request(app)
        .delete(`/api/v1/academics/faculty-assignments/${assignment._id}`)
        .set(adminHeaderA);

      expect(delRes.status).toBe(200);
      expect(delRes.body.message).toMatch(/deleted successfully/i);

      const deletedDoc = await FacultyAssignment.findById(assignment._id);
      expect(deletedDoc).toBeNull();
    });
  });

  describe('Downstream Workload Derivation (Section 46)', () => {
    it('Derives workload accurately from active FacultyAssignment records', async () => {
      // Create 2 active assignments for facultyDocA1
      await FacultyAssignment.create({
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        courseId: courseA1._id,
        academicYearId: ayA._id,
        semesterId: semA1._id,
        sectionId: secA1._id,
        subjectId: subjectA1._id,
        facultyId: facultyDocA1._id,
        facultyName: facultyDocA1.name,
        status: 'active',
        isActive: true,
      });

      // Second assignment for facultyDocA1 on a different section or subject
      const secA1B = await Section.create({
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        courseId: courseA1._id,
        academicYearId: ayA._id,
        semesterId: semA1._id,
        name: 'Section B (Sem 5)',
        capacity: 60,
        status: 'active',
        isActive: true,
      });

      await FacultyAssignment.create({
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        courseId: courseA1._id,
        academicYearId: ayA._id,
        semesterId: semA1._id,
        sectionId: secA1B._id,
        subjectId: subjectA1._id,
        facultyId: facultyDocA1._id,
        facultyName: facultyDocA1.name,
        status: 'active',
        isActive: true,
      });

      // Query workload
      const res = await request(app)
        .get('/api/v1/academics/faculty-assignments/workload')
        .set(adminHeaderA);

      expect(res.status).toBe(200);
      const facultyWorkload = res.body.data.find((f: any) => f.facultyId === facultyDocA1._id.toString());
      expect(facultyWorkload).toBeDefined();
      expect(facultyWorkload.subjectsAssigned).toBe(1); // 1 unique subject
      expect(facultyWorkload.sectionsAssigned).toBe(2); // 2 unique sections
      expect(facultyWorkload.hasAttendanceResponsibility).toBe(true);
    });
  });
});
