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
import { Room } from '../../src/models/room.model';
import { Timetable } from '../../src/models/timetable.model';
import { AppRole } from '../../src/constants/roles';
import {
  CollegeStatus,
  DepartmentStatus,
  TimetableDay,
  TimetableStatus,
  TimetableSessionType,
  AccountStatus,
} from '../../src/constants/status';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';
import { PasswordService } from '../../src/services/password.service';

describe('HOD Dashboard, Role-Aware Data Sourcing & Metric Integrity (Prompt 1 Regression)', () => {
  let collegeA: InstanceType<typeof College>;
  let collegeB: InstanceType<typeof College>;
  let deptA: InstanceType<typeof Department>;
  let deptB: InstanceType<typeof Department>;
  let deptInCollegeB: InstanceType<typeof Department>;
  let courseA: InstanceType<typeof Course>;
  let academicYearA: InstanceType<typeof AcademicYear>;
  let semesterA: InstanceType<typeof Semester>;
  let sectionA: InstanceType<typeof Section>;
  let subjectMath: InstanceType<typeof Subject>;
  let facultyUserA: InstanceType<typeof User>;
  let facultyProfileA: InstanceType<typeof Faculty>;
  let hodUserA: InstanceType<typeof User>;
  let studentUser: InstanceType<typeof User>;

  let hodAHeader: { Authorization: string };
  let facultyAHeader: { Authorization: string };
  let studentHeader: { Authorization: string };

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
    await Room.init();
    await Timetable.init();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();
    const defaultPasswordHash = await PasswordService.hashPassword('Password123');

    // 1. Colleges
    collegeA = await College.create({
      name: 'Alpha Engineering College',
      code: 'ALPHA',
      address: 'Main St',
      email: 'contact@alpha.edu',
      phone: '+919900000001',
      principal: 'Dr. Principal Alpha',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });

    collegeB = await College.create({
      name: 'Beta Engineering College',
      code: 'BETA',
      address: 'North St',
      email: 'contact@beta.edu',
      phone: '+919900000002',
      principal: 'Dr. Principal Beta',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });

    // 2. Departments
    deptA = await Department.create({
      collegeId: collegeA._id,
      name: 'Computer Science and Engineering',
      code: 'CSE',
      status: DepartmentStatus.ACTIVE,
      isActive: true,
    });

    deptB = await Department.create({
      collegeId: collegeA._id,
      name: 'Electronics and Communication',
      code: 'ECE',
      status: DepartmentStatus.ACTIVE,
      isActive: true,
    });

    deptInCollegeB = await Department.create({
      collegeId: collegeB._id,
      name: 'Mechanical Engineering',
      code: 'MECH',
      status: DepartmentStatus.ACTIVE,
      isActive: true,
    });

    // 3. Academic Structure in Dept A
    courseA = await Course.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'Computer Science',
      code: 'CS',
      durationYears: 4,
      totalSemesters: 8,
      isActive: true,
    });

    academicYearA = await AcademicYear.create({
      collegeId: collegeA._id,
      name: '2026-2027',
      startDate: new Date('2026-08-01'),
      endDate: new Date('2027-05-31'),
      isCurrent: true,
      isActive: true,
    });

    semesterA = await Semester.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      number: 1,
      name: 'Semester 1',
      isActive: true,
    });

    sectionA = await Section.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      name: 'Section A',
      capacity: 60,
      isActive: true,
    });

    subjectMath = await Subject.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      semesterId: semesterA._id,
      name: 'Discrete Mathematics',
      code: 'CS101',
      credits: 4,
      isActive: true,
    });

    // 4. Users & Auth Headers
    hodUserA = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      instituteId: 'INST-HOD-A',
      email: 'hod.cse@alpha.edu',
      name: 'Dr. Alan Turing',
      role: AppRole.HOD,
      passwordHash: defaultPasswordHash,
      accountStatus: AccountStatus.ACTIVE,
    });
    hodAHeader = createTestAuthHeader({
      userId: hodUserA._id.toString(),
      role: AppRole.HOD,
      collegeId: collegeA._id.toString(),
      departmentId: deptA._id.toString(),
      instituteId: 'INST-HOD-A',
      email: hodUserA.email,
    });

    facultyUserA = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      instituteId: 'INST-FAC-A',
      email: 'faculty.turing@alpha.edu',
      name: 'Prof. Donald Knuth',
      role: AppRole.FACULTY,
      passwordHash: defaultPasswordHash,
      accountStatus: AccountStatus.ACTIVE,
    });
    facultyAHeader = createTestAuthHeader({
      userId: facultyUserA._id.toString(),
      role: AppRole.FACULTY,
      collegeId: collegeA._id.toString(),
      departmentId: deptA._id.toString(),
      instituteId: 'INST-FAC-A',
      email: facultyUserA.email,
    });

    facultyProfileA = await Faculty.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      userId: facultyUserA._id,
      name: 'Prof. Donald Knuth',
      email: 'faculty.turing@alpha.edu',
      employeeId: 'EMP-001',
      isActive: true,
    });

    studentUser = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      instituteId: 'INST-STU-A',
      email: 'student.ada@alpha.edu',
      name: 'Ada Lovelace',
      role: AppRole.STUDENT,
      sectionId: sectionA._id,
      passwordHash: defaultPasswordHash,
      accountStatus: AccountStatus.ACTIVE,
    });
    studentHeader = createTestAuthHeader({
      userId: studentUser._id.toString(),
      role: AppRole.STUDENT,
      collegeId: collegeA._id.toString(),
      departmentId: deptA._id.toString(),
      sectionId: sectionA._id.toString(),
      instituteId: 'INST-STU-A',
      email: studentUser.email,
    });

    await Student.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      userId: studentUser._id,
      name: 'Ada Lovelace',
      email: 'student.ada@alpha.edu',
      sectionId: sectionA._id,
      enrollmentNumber: 'STU-001',
      status: 'active',
      isActive: true,
    });
  });

  describe('1. HOD Dashboard Timetable Retrieval & Scoping', () => {
    it('returns empty timetable list when no timetable is published yet (200 OK, not error)', async () => {
      const res = await request(app)
        .get(`/api/v1/timetables/departments/${deptA.id}`)
        .set(hodAHeader);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data)).toBe(true);
      expect(res.body.data.length).toBe(0);
    });

    it('allows HOD to fetch department timetable via /departments/me', async () => {
      const res = await request(app)
        .get('/api/v1/timetables/departments/me')
        .set(hodAHeader);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data)).toBe(true);
    });

    it('returns published timetable entries for HOD department with full entry decoration', async () => {
      // Create and publish a timetable
      await Timetable.create({
        name: 'CSE Semester 1 Timetable',
        collegeId: collegeA._id,
        departmentId: deptA._id,
        courseId: courseA._id,
        academicYearId: academicYearA._id,
        semesterId: semesterA._id,
        sectionId: sectionA._id,
        status: TimetableStatus.PUBLISHED,
        version: 1,
        entries: [
          {
            dayOfWeek: TimetableDay.MONDAY,
            startTime: '09:00',
            endTime: '10:00',
            subjectId: subjectMath._id,
            facultyId: facultyProfileA._id,
            roomNumber: '101',
            building: 'Tech Block',
            sessionType: TimetableSessionType.LECTURE,
          },
          {
            dayOfWeek: TimetableDay.MONDAY,
            startTime: '10:00',
            endTime: '11:00',
            subjectId: subjectMath._id,
            facultyId: facultyProfileA._id,
            roomNumber: '102',
            building: 'Tech Block',
            sessionType: TimetableSessionType.LAB,
          },
        ],
      });

      const res = await request(app)
        .get(`/api/v1/timetables/departments/${deptA.id}?day=monday`)
        .set(hodAHeader);

      expect(res.status).toBe(200);
      expect(res.body.data.length).toBe(2);
      expect(res.body.data[0].startTime).toBe('09:00');
      expect(res.body.data[0].sectionId.toString()).toBe(sectionA.id);
      expect(res.body.data[0].departmentId.toString()).toBe(deptA.id);
      expect(res.body.data[1].startTime).toBe('10:00');
    });

    it('strictly forbids HOD from querying another department timetable (Cross-department denial)', async () => {
      const res = await request(app)
        .get(`/api/v1/timetables/departments/${deptB.id}`)
        .set(hodAHeader);

      expect(res.status).toBe(403);
      expect(res.body.error.message).toContain('HOD cannot access timetables outside their assigned department');
    });

    it('strictly forbids HOD from querying department in another college (Cross-college denial)', async () => {
      const res = await request(app)
        .get(`/api/v1/timetables/departments/${deptInCollegeB.id}`)
        .set(hodAHeader);

      expect(res.status).toBe(403);
      expect(res.body.error.message).toContain('Cross-college tenant access is strictly prohibited');
    });

    it('forbids Students from querying department timetable endpoint (403 Forbidden)', async () => {
      const res = await request(app)
        .get(`/api/v1/timetables/departments/${deptA.id}`)
        .set(studentHeader);

      expect(res.status).toBe(403);
    });

    it('forbids Faculty from querying department timetable endpoint (403 Forbidden)', async () => {
      const res = await request(app)
        .get(`/api/v1/timetables/departments/${deptA.id}`)
        .set(facultyAHeader);

      expect(res.status).toBe(403);
    });

    it('maintains student-only protection on /timetables/students/me (rejects HOD with 403)', async () => {
      const res = await request(app)
        .get('/api/v1/timetables/students/me')
        .set(hodAHeader);

      expect(res.status).toBe(403);
      expect(res.body.error.message).toContain('Only students can access this endpoint');
    });
  });

  describe('2. Department Metrics & Faculty Count Integrity', () => {
    it('returns exact active faculty count matching Faculty Management in department summary', async () => {
      // Create another active faculty in deptA
      const secondFacUser = await User.create({
        collegeId: collegeA._id,
        departmentId: deptA._id,
        instituteId: 'INST-FAC-2',
        email: 'faculty.lovelace@alpha.edu',
        name: 'Prof. Grace Hopper',
        role: AppRole.FACULTY,
        passwordHash: await PasswordService.hashPassword('Password123'),
        accountStatus: AccountStatus.ACTIVE,
      });
      await Faculty.create({
        collegeId: collegeA._id,
        departmentId: deptA._id,
        userId: secondFacUser._id,
        name: 'Prof. Grace Hopper',
        email: 'faculty.lovelace@alpha.edu',
        employeeId: 'EMP-002',
        isActive: true,
      });

      // And an inactive/pending faculty in deptA that should NOT be counted in active count
      await User.create({
        collegeId: collegeA._id,
        departmentId: deptA._id,
        instituteId: 'INST-FAC-PENDING',
        email: 'pending.faculty@alpha.edu',
        name: 'Pending Faculty',
        role: AppRole.FACULTY,
        passwordHash: await PasswordService.hashPassword('Password123'),
        accountStatus: AccountStatus.PENDING_ACTIVATION,
      });

      // Check /api/v1/departments/:id/summary
      const summaryRes = await request(app)
        .get(`/api/v1/departments/${deptA.id}/summary`)
        .set(hodAHeader);

      expect(summaryRes.status).toBe(200);
      expect(summaryRes.body.data.facultyCount).toBe(2);

      // Check /api/v1/reports/attendance/department/:id summary
      const reportRes = await request(app)
        .get(`/api/v1/reports/attendance/department/${deptA.id}`)
        .set(hodAHeader);

      expect(reportRes.status).toBe(200);
      expect(reportRes.body.data.summary.totalFaculty).toBe(2);
      expect(reportRes.body.data.summary.totalStudents).toBe(1);
    });

    it('enforces HOD isolation on department summary endpoint', async () => {
      const res = await request(app)
        .get(`/api/v1/departments/${deptB.id}/summary`)
        .set(hodAHeader);

      expect(res.status).toBe(403);
      expect(res.body.error.message).toContain('HOD cannot access summary of another department');
    });
  });
});
