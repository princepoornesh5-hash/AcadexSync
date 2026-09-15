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
import { StudentEnrollment } from '../../src/models/studentEnrollment.model';
import { FacultyAssignment } from '../../src/models/facultyAssignment.model';
import { AttendanceSession } from '../../src/models/attendanceSession.model';
import { AttendanceRecord } from '../../src/models/attendanceRecord.model';
import { AppRole } from '../../src/constants/roles';
import {
  CollegeStatus,
  DepartmentStatus,
  SemesterStatus,
  AttendanceStatus,
  AttendanceSessionStatus,
} from '../../src/constants/status';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';
import { PasswordService } from '../../src/services/password.service';

describe('ACADEX — Department Analytics Integration (Prompt 6 of 6)', () => {
  let collegeA: InstanceType<typeof College>;
  let collegeB: InstanceType<typeof College>;

  let deptCSE: InstanceType<typeof Department>;
  let deptECE: InstanceType<typeof Department>;
  let deptB: InstanceType<typeof Department>;

  let courseCSE: InstanceType<typeof Course>;
  let courseIT: InstanceType<typeof Course>;
  let courseECE: InstanceType<typeof Course>;

  let yearA: InstanceType<typeof AcademicYear>;
  let sem1: InstanceType<typeof Semester>;
  let sem2: InstanceType<typeof Semester>;

  let secA: InstanceType<typeof Section>;
  let secB: InstanceType<typeof Section>;

  let subAlgo: InstanceType<typeof Subject>;
  let subOS: InstanceType<typeof Subject>;

  let hodUserCSE: InstanceType<typeof User>;
  let hodUserECE: InstanceType<typeof User>;
  let facultyUser: InstanceType<typeof User>;
  let studentUser: InstanceType<typeof User>;

  let facDoc: InstanceType<typeof Faculty>;
  let student1: InstanceType<typeof Student>;
  let student2: InstanceType<typeof Student>;
  let student3: InstanceType<typeof Student>;
  let studentInactive: InstanceType<typeof Student>;

  let authHeaderHodCSE: { Authorization: string };
  let authHeaderHodECE: { Authorization: string };
  let authHeaderFac: { Authorization: string };
  let authHeaderStu: { Authorization: string };

  beforeAll(async () => {
    await setupTestDB();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();
    const hashedPassword = await PasswordService.hashPassword('Password@123');

    // 1. Setup Colleges
    collegeA = await College.create({
      name: 'Alpha Engineering College',
      code: 'AEC-01',
      address: 'Alpha Campus',
      email: 'admin@alpha.edu',
      phone: '+919988771101',
      principal: 'Dr. Alpha',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });

    collegeB = await College.create({
      name: 'Beta Tech Institute',
      code: 'BTI-02',
      address: 'Beta Campus',
      email: 'admin@beta.edu',
      phone: '+919988771102',
      principal: 'Dr. Beta',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });

    // 2. Setup Departments
    deptCSE = await Department.create({
      collegeId: collegeA._id,
      name: 'Computer Science and Engineering',
      code: 'CSE',
      status: DepartmentStatus.ACTIVE,
    });

    deptECE = await Department.create({
      collegeId: collegeA._id,
      name: 'Electronics and Communication',
      code: 'ECE',
      status: DepartmentStatus.ACTIVE,
    });

    deptB = await Department.create({
      collegeId: collegeB._id,
      name: 'Beta Department',
      code: 'B-CSE',
      status: DepartmentStatus.ACTIVE,
    });

    // 3. Setup Academic Hierarchy in CSE
    courseCSE = await Course.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      name: 'B.Tech Computer Science',
      code: 'BT-CSE',
    });

    courseIT = await Course.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      name: 'B.Tech Information Tech',
      code: 'BT-IT',
    });

    courseECE = await Course.create({
      collegeId: collegeA._id,
      departmentId: deptECE._id,
      name: 'B.Tech ECE',
      code: 'BT-ECE',
    });

    yearA = await AcademicYear.create({
      collegeId: collegeA._id,
      name: '2026-2027',
      startDate: new Date('2026-07-01'),
      endDate: new Date('2027-06-30'),
      isCurrent: true,
    });

    sem1 = await Semester.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      courseId: courseCSE._id,
      academicYearId: yearA._id,
      name: 'Semester 5',
      number: 5,
      status: SemesterStatus.ACTIVE,
    });

    sem2 = await Semester.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      courseId: courseCSE._id,
      academicYearId: yearA._id,
      name: 'Semester 6',
      number: 6,
      status: SemesterStatus.UPCOMING,
    });

    secA = await Section.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      courseId: courseCSE._id,
      academicYearId: yearA._id,
      semesterId: sem1._id,
      name: 'Section A',
      capacity: 60,
    });

    secB = await Section.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      courseId: courseCSE._id,
      academicYearId: yearA._id,
      semesterId: sem1._id,
      name: 'Section B',
      capacity: 60,
    });

    subAlgo = await Subject.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      courseId: courseCSE._id,
      academicYearId: yearA._id,
      semesterId: sem1._id,
      name: 'Algorithms',
      code: 'CS501',
    });

    subOS = await Subject.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      courseId: courseCSE._id,
      academicYearId: yearA._id,
      semesterId: sem1._id,
      name: 'Operating Systems',
      code: 'CS502',
    });

    // 4. Users
    hodUserCSE = await User.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      email: 'hod.cse@aec.edu',
      passwordHash: hashedPassword,
      instituteId: 'HOD-CSE-01',
      name: 'Dr. Turing (HOD CSE)',
      role: AppRole.HOD,
      isActive: true,
    });

    hodUserECE = await User.create({
      collegeId: collegeA._id,
      departmentId: deptECE._id,
      email: 'hod.ece@aec.edu',
      passwordHash: hashedPassword,
      instituteId: 'HOD-ECE-01',
      name: 'Dr. Shannon (HOD ECE)',
      role: AppRole.HOD,
      isActive: true,
    });

    facultyUser = await User.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      email: 'fac.algo@aec.edu',
      passwordHash: hashedPassword,
      instituteId: 'FAC-ALGO-01',
      name: 'Prof. Knuth',
      role: AppRole.FACULTY,
      isActive: true,
    });

    facDoc = await Faculty.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      userId: facultyUser._id,
      name: facultyUser.name,
      email: facultyUser.email,
    });

    studentUser = await User.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      email: 'student.alice@aec.edu',
      passwordHash: hashedPassword,
      instituteId: 'STU-ALICE-01',
      name: 'Alice Turing',
      role: AppRole.STUDENT,
      isActive: true,
    });

    // 5. Students & Enrollments
    student1 = await Student.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      userId: studentUser._id,
      name: 'Alice Turing',
      rollNumber: 'CS-01',
      admissionNumber: 'ADM-001',
      status: 'active',
    });

    student2 = await Student.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      name: 'Bob Lovelace',
      rollNumber: 'CS-02',
      admissionNumber: 'ADM-002',
      status: 'active',
    });

    student3 = await Student.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      name: 'Charlie Babbage',
      rollNumber: 'CS-03',
      admissionNumber: 'ADM-003',
      status: 'active',
    });

    studentInactive = await Student.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      name: 'Inactive Student',
      rollNumber: 'CS-99',
      admissionNumber: 'ADM-099',
      status: 'inactive',
    });

    // Active enrollments for Alice, Bob, Charlie in Sec A
    await StudentEnrollment.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      studentId: student1._id,
      courseId: courseCSE._id,
      academicYearId: yearA._id,
      semesterId: sem1._id,
      sectionId: secA._id,
      status: 'active',
    });

    await StudentEnrollment.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      studentId: student2._id,
      courseId: courseCSE._id,
      academicYearId: yearA._id,
      semesterId: sem1._id,
      sectionId: secA._id,
      status: 'active',
    });

    await StudentEnrollment.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      studentId: student3._id,
      courseId: courseCSE._id,
      academicYearId: yearA._id,
      semesterId: sem1._id,
      sectionId: secA._id,
      status: 'active',
    });

    // Inactive enrollment
    await StudentEnrollment.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      studentId: studentInactive._id,
      courseId: courseCSE._id,
      academicYearId: yearA._id,
      semesterId: sem1._id,
      sectionId: secA._id,
      status: 'inactive',
    });

    // Faculty Assignment
    await FacultyAssignment.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      facultyId: facDoc._id,
      facultyName: facDoc.name,
      courseId: courseCSE._id,
      academicYearId: yearA._id,
      semesterId: sem1._id,
      sectionId: secA._id,
      subjectId: subAlgo._id,
      status: 'active',
      isActive: true,
    });

    // 6. Tokens
    authHeaderHodCSE = createTestAuthHeader({
      userId: hodUserCSE._id.toString(),
      collegeId: collegeA._id.toString(),
      departmentId: deptCSE._id.toString(),
      role: AppRole.HOD,
    });

    authHeaderHodECE = createTestAuthHeader({
      userId: hodUserECE._id.toString(),
      collegeId: collegeA._id.toString(),
      departmentId: deptECE._id.toString(),
      role: AppRole.HOD,
    });

    authHeaderFac = createTestAuthHeader({
      userId: facultyUser._id.toString(),
      collegeId: collegeA._id.toString(),
      departmentId: deptCSE._id.toString(),
      role: AppRole.FACULTY,
    });

    authHeaderStu = createTestAuthHeader({
      userId: studentUser._id.toString(),
      collegeId: collegeA._id.toString(),
      departmentId: deptCSE._id.toString(),
      role: AppRole.STUDENT,
    });
  });

  describe('1. Security & Role Isolation', () => {
    it('1. Authorized HOD accesses own department analytics overview successfully', async () => {
      const res = await request(app)
        .get('/api/v1/analytics/department/overview')
        .set(authHeaderHodCSE);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.departmentId).toBe(deptCSE._id.toString());
      expect(res.body.data.collegeId).toBe(collegeA._id.toString());
      expect(res.body.data.totalStudents).toBe(3); // active only
    });

    it('2. HOD cannot access another department in same college (returns 403)', async () => {
      const res = await request(app)
        .get(`/api/v1/analytics/department/overview?departmentId=${deptECE._id}`)
        .set(authHeaderHodCSE);

      expect(res.status).toBe(403);
      const msg = res.body.error?.message || res.body.message;
      expect(msg).toMatch(/cannot access analytics of another department/i);
    });

    it('3. HOD cannot access another college (returns 403)', async () => {
      const res = await request(app)
        .get(`/api/v1/analytics/department/overview?collegeId=${collegeB._id}`)
        .set(authHeaderHodCSE);

      expect(res.status).toBe(403);
      const msg = res.body.error?.message || res.body.message;
      expect(msg).toMatch(/Cross-college/i);
    });

    it('4. Faculty cannot access HOD department analytics (returns 403)', async () => {
      const res = await request(app)
        .get('/api/v1/analytics/department/overview')
        .set(authHeaderFac);

      expect(res.status).toBe(403);
    });

    it('5. Student cannot access HOD department analytics (returns 403)', async () => {
      const res = await request(app)
        .get('/api/v1/analytics/department/overview')
        .set(authHeaderStu);

      expect(res.status).toBe(403);
    });

    it('6. Client cannot override departmentId authorization', async () => {
      const res = await request(app)
        .get(`/api/v1/analytics/department/overview?departmentId=${deptB._id}`)
        .set(authHeaderHodCSE);

      expect(res.status).toBe(403);
    });

    it('7. Client cannot override collegeId authorization', async () => {
      const res = await request(app)
        .get(`/api/v1/analytics/department/courses?collegeId=${collegeB._id}`)
        .set(authHeaderHodCSE);

      expect(res.status).toBe(403);
    });

    it('8. Invalid course filter rejected (400)', async () => {
      const fakeId = new mongoose.Types.ObjectId().toString();
      const res = await request(app)
        .get(`/api/v1/analytics/department/overview?courseId=${fakeId}`)
        .set(authHeaderHodCSE);

      expect(res.status).toBe(400);
      const msg = res.body.error?.message || res.body.message;
      expect(msg).toMatch(/Invalid courseId/i);
    });

    it('9. Invalid semester filter rejected (400)', async () => {
      const fakeId = new mongoose.Types.ObjectId().toString();
      const res = await request(app)
        .get(`/api/v1/analytics/department/overview?semesterId=${fakeId}`)
        .set(authHeaderHodCSE);

      expect(res.status).toBe(400);
      const msg = res.body.error?.message || res.body.message;
      expect(msg).toMatch(/Invalid semesterId/i);
    });

    it('10. Invalid section filter rejected (400)', async () => {
      const fakeId = new mongoose.Types.ObjectId().toString();
      const res = await request(app)
        .get(`/api/v1/analytics/department/overview?sectionId=${fakeId}`)
        .set(authHeaderHodCSE);

      expect(res.status).toBe(400);
      const msg = res.body.error?.message || res.body.message;
      expect(msg).toMatch(/Invalid sectionId/i);
    });

    it('11. Invalid subject filter rejected (400)', async () => {
      const fakeId = new mongoose.Types.ObjectId().toString();
      const res = await request(app)
        .get(`/api/v1/analytics/department/overview?subjectId=${fakeId}`)
        .set(authHeaderHodCSE);

      expect(res.status).toBe(400);
      const msg = res.body.error?.message || res.body.message;
      expect(msg).toMatch(/Invalid subjectId/i);
    });

    it('12. Only active enrollments are used for student context', async () => {
      const res = await request(app)
        .get('/api/v1/analytics/department/students')
        .set(authHeaderHodCSE);

      expect(res.status).toBe(200);
      expect(res.body.data.total).toBe(3);
      const studentIds = res.body.data.students.map((s: any) => s.studentId);
      expect(studentIds).not.toContain(studentInactive._id.toString());
    });
  });

  describe('2. Data Correctness & Truthful Empty States', () => {
    it('15 & 16. Empty department returns truthful empty analytics with 0.0% and no NaN/Infinity', async () => {
      const res = await request(app)
        .get('/api/v1/analytics/department/overview')
        .set(authHeaderHodECE); // ECE has no students or sessions

      expect(res.status).toBe(200);
      expect(res.body.data.overallAttendancePercentage).toBe(0.0);
      expect(res.body.data.totalSessions).toBe(0);
      expect(res.body.data.totalRecords).toBe(0);
      expect(res.body.data.presentCount).toBe(0);
      expect(res.body.data.absentCount).toBe(0);
      expect(res.body.data.atRiskCount).toBe(0);
      expect(isNaN(res.body.data.overallAttendancePercentage)).toBe(false);
    });

    it('22. Numerical calculation accuracy with real sessions and records', async () => {
      // Create Session 1 for Algorithms (Sec A) on 2026-09-01
      // Alice: Present, Bob: Present, Charlie: Absent
      const session1 = await AttendanceSession.create({
        collegeId: collegeA._id,
        departmentId: deptCSE._id,
        courseId: courseCSE._id,
        academicYearId: yearA._id,
        semesterId: sem1._id,
        sectionId: secA._id,
        subjectId: subAlgo._id,
        facultyId: facDoc._id,
        sectionName: 'Section A',
        subjectName: 'Algorithms',
        timeSlot: '09:00 - 10:00',
        date: new Date('2026-09-01T09:00:00Z'),
        status: AttendanceSessionStatus.CLOSED,
        isSubmitted: true,
        records: [
          { studentId: student1._id, studentName: student1.name, rollNumber: student1.rollNumber!, sectionId: secA._id, status: AttendanceStatus.PRESENT },
          { studentId: student2._id, studentName: student2.name, rollNumber: student2.rollNumber!, sectionId: secA._id, status: AttendanceStatus.PRESENT },
          { studentId: student3._id, studentName: student3.name, rollNumber: student3.rollNumber!, sectionId: secA._id, status: AttendanceStatus.ABSENT },
        ],
      });

      await AttendanceRecord.insertMany([
        { collegeId: collegeA._id, departmentId: deptCSE._id, sessionId: session1._id, studentId: student1._id, studentName: student1.name, rollNumber: student1.rollNumber, sectionId: secA._id, subjectId: subAlgo._id, courseId: courseCSE._id, academicYearId: yearA._id, semesterId: sem1._id, facultyId: facDoc._id, timeSlot: '09:00 - 10:00', date: session1.date, status: AttendanceStatus.PRESENT },
        { collegeId: collegeA._id, departmentId: deptCSE._id, sessionId: session1._id, studentId: student2._id, studentName: student2.name, rollNumber: student2.rollNumber, sectionId: secA._id, subjectId: subAlgo._id, courseId: courseCSE._id, academicYearId: yearA._id, semesterId: sem1._id, facultyId: facDoc._id, timeSlot: '09:00 - 10:00', date: session1.date, status: AttendanceStatus.PRESENT },
        { collegeId: collegeA._id, departmentId: deptCSE._id, sessionId: session1._id, studentId: student3._id, studentName: student3.name, rollNumber: student3.rollNumber, sectionId: secA._id, subjectId: subAlgo._id, courseId: courseCSE._id, academicYearId: yearA._id, semesterId: sem1._id, facultyId: facDoc._id, timeSlot: '09:00 - 10:00', date: session1.date, status: AttendanceStatus.ABSENT },
      ]);

      // Create Session 2 for Algorithms (Sec A) on 2026-09-02
      // Alice: Late (counted as attended), Bob: Absent, Charlie: Absent
      const session2 = await AttendanceSession.create({
        collegeId: collegeA._id,
        departmentId: deptCSE._id,
        courseId: courseCSE._id,
        academicYearId: yearA._id,
        semesterId: sem1._id,
        sectionId: secA._id,
        subjectId: subAlgo._id,
        facultyId: facDoc._id,
        sectionName: 'Section A',
        subjectName: 'Algorithms',
        timeSlot: '10:00 - 11:00',
        date: new Date('2026-09-02T10:00:00Z'),
        status: AttendanceSessionStatus.CLOSED,
        isSubmitted: true,
        records: [
          { studentId: student1._id, studentName: student1.name, rollNumber: student1.rollNumber!, sectionId: secA._id, status: AttendanceStatus.LATE },
          { studentId: student2._id, studentName: student2.name, rollNumber: student2.rollNumber!, sectionId: secA._id, status: AttendanceStatus.ABSENT },
          { studentId: student3._id, studentName: student3.name, rollNumber: student3.rollNumber!, sectionId: secA._id, status: AttendanceStatus.ABSENT },
        ],
      });

      await AttendanceRecord.insertMany([
        { collegeId: collegeA._id, departmentId: deptCSE._id, sessionId: session2._id, studentId: student1._id, studentName: student1.name, rollNumber: student1.rollNumber, sectionId: secA._id, subjectId: subAlgo._id, courseId: courseCSE._id, academicYearId: yearA._id, semesterId: sem1._id, facultyId: facDoc._id, timeSlot: '10:00 - 11:00', date: session2.date, status: AttendanceStatus.LATE },
        { collegeId: collegeA._id, departmentId: deptCSE._id, sessionId: session2._id, studentId: student2._id, studentName: student2.name, rollNumber: student2.rollNumber, sectionId: secA._id, subjectId: subAlgo._id, courseId: courseCSE._id, academicYearId: yearA._id, semesterId: sem1._id, facultyId: facDoc._id, timeSlot: '10:00 - 11:00', date: session2.date, status: AttendanceStatus.ABSENT },
        { collegeId: collegeA._id, departmentId: deptCSE._id, sessionId: session2._id, studentId: student3._id, studentName: student3.name, rollNumber: student3.rollNumber, sectionId: secA._id, subjectId: subAlgo._id, courseId: courseCSE._id, academicYearId: yearA._id, semesterId: sem1._id, facultyId: facDoc._id, timeSlot: '10:00 - 11:00', date: session2.date, status: AttendanceStatus.ABSENT },
      ]);

      // Totals:
      // Total sessions: 2
      // Total records: 6
      // Present: 2, Late: 1, Absent: 3.
      // Attended: 3 / 6 = 50.0%
      // Student 1 (Alice): 2 / 2 = 100.0%
      // Student 2 (Bob): 1 / 2 = 50.0% (At-risk since < 75%)
      // Student 3 (Charlie): 0 / 2 = 0.0% (At-risk since < 75%)
      // Total At-Risk: 2 students

      const res = await request(app)
        .get('/api/v1/analytics/department/overview')
        .set(authHeaderHodCSE);

      expect(res.status).toBe(200);
      expect(res.body.data.totalSessions).toBe(2);
      expect(res.body.data.totalRecords).toBe(6);
      expect(res.body.data.presentCount).toBe(2);
      expect(res.body.data.lateCount).toBe(1);
      expect(res.body.data.overallAttendancePercentage).toBe(50.0);
      expect(res.body.data.atRiskCount).toBe(2);

      // Verify courseBreakdown contains both courseCSE and courseIT
      const cseCourse = res.body.data.courseBreakdown.find((c: any) => c.courseId === courseCSE._id.toString());
      const itCourse = res.body.data.courseBreakdown.find((c: any) => c.courseId === courseIT._id.toString());
      expect(cseCourse).toBeDefined();
      expect(itCourse).toBeDefined();
      expect(cseCourse.attendancePercentage).toBe(50.0);
      expect(itCourse.sessionCount).toBe(0);

      // Verify semesterBreakdown contains sem1 and sem2
      const s1 = res.body.data.semesterBreakdown.find((s: any) => s.semesterId === sem1._id.toString());
      const s2 = res.body.data.semesterBreakdown.find((s: any) => s.semesterId === sem2._id.toString());
      expect(s1).toBeDefined();
      expect(s2).toBeDefined();

      // Verify sectionBreakdown contains secA and secB
      const sa = res.body.data.sectionBreakdown.find((s: any) => s.sectionId === secA._id.toString());
      const sb = res.body.data.sectionBreakdown.find((s: any) => s.sectionId === secB._id.toString());
      expect(sa).toBeDefined();
      expect(sb).toBeDefined();

      // Verify subjectBreakdown contains subAlgo and subOS
      const saSub = res.body.data.subjectBreakdown.find((s: any) => s.subjectId === subAlgo._id.toString());
      const soSub = res.body.data.subjectBreakdown.find((s: any) => s.subjectId === subOS._id.toString());
      expect(saSub).toBeDefined();
      expect(soSub).toBeDefined();

      // 17. Check student level analytics
      const stuRes = await request(app)
        .get('/api/v1/analytics/department/students')
        .set(authHeaderHodCSE);

      expect(stuRes.status).toBe(200);
      const alice = stuRes.body.data.students.find((s: any) => s.studentId === student1._id.toString());
      const bob = stuRes.body.data.students.find((s: any) => s.studentId === student2._id.toString());
      const charlie = stuRes.body.data.students.find((s: any) => s.studentId === student3._id.toString());

      expect(alice.overallAttendancePercentage).toBe(100.0);
      expect(alice.isAtRisk).toBe(false);

      expect(bob.overallAttendancePercentage).toBe(50.0);
      expect(bob.isAtRisk).toBe(true);

      expect(charlie.overallAttendancePercentage).toBe(0.0);
      expect(charlie.isAtRisk).toBe(true);

      // Test atRiskOnly query filter
      const atRiskOnlyRes = await request(app)
        .get('/api/v1/analytics/department/students?atRiskOnly=true')
        .set(authHeaderHodCSE);

      expect(atRiskOnlyRes.status).toBe(200);
      expect(atRiskOnlyRes.body.data.total).toBe(2);
      const atRiskIds = atRiskOnlyRes.body.data.students.map((s: any) => s.studentId);
      expect(atRiskIds).toContain(student2._id.toString());
      expect(atRiskIds).toContain(student3._id.toString());
      expect(atRiskIds).not.toContain(student1._id.toString());
    });

    it('13 & 14. Attendance records from another department/college are excluded', async () => {
      // Create session in ECE with 10 records
      const eceSession = await AttendanceSession.create({
        collegeId: collegeA._id,
        departmentId: deptECE._id,
        courseId: courseECE._id,
        facultyId: facDoc._id,
        sectionId: secA._id,
        subjectId: subAlgo._id,
        sectionName: 'ECE Sec',
        subjectName: 'Circuits',
        timeSlot: '11:00 - 12:00',
        date: new Date('2026-09-03'),
        status: AttendanceSessionStatus.CLOSED,
        isSubmitted: true,
      });

      await AttendanceRecord.create({
        collegeId: collegeA._id,
        departmentId: deptECE._id,
        sessionId: eceSession._id,
        studentId: student1._id,
        studentName: 'Alice',
        rollNumber: 'CS-01',
        sectionId: secA._id,
        subjectId: subAlgo._id,
        courseId: courseECE._id,
        facultyId: facDoc._id,
        timeSlot: '11:00 - 12:00',
        date: eceSession.date,
        status: AttendanceStatus.PRESENT,
      });

      // Query CSE HOD overview - should NOT count ECE session or record
      const res = await request(app)
        .get('/api/v1/analytics/department/overview')
        .set(authHeaderHodCSE);

      expect(res.status).toBe(200);
      // ECE session not counted in CSE
      expect(res.body.data.totalSessions).toBe(0);
      expect(res.body.data.totalRecords).toBe(0);
    });

    it('18. Date-range filtering works correctly', async () => {
      // Create sessions on Sept 10 and Sept 20
      const s1 = await AttendanceSession.create({
        collegeId: collegeA._id,
        departmentId: deptCSE._id,
        courseId: courseCSE._id,
        academicYearId: yearA._id,
        semesterId: sem1._id,
        sectionId: secA._id,
        subjectId: subAlgo._id,
        facultyId: facDoc._id,
        sectionName: 'Section A',
        subjectName: 'Algorithms',
        timeSlot: '09:00 - 10:00',
        date: new Date('2026-09-10T09:00:00Z'),
        status: AttendanceSessionStatus.CLOSED,
        isSubmitted: true,
      });
      await AttendanceRecord.create({
        collegeId: collegeA._id,
        departmentId: deptCSE._id,
        sessionId: s1._id,
        studentId: student1._id,
        studentName: 'Alice',
        rollNumber: 'CS-01',
        sectionId: secA._id,
        subjectId: subAlgo._id,
        courseId: courseCSE._id,
        academicYearId: yearA._id,
        semesterId: sem1._id,
        facultyId: facDoc._id,
        timeSlot: '09:00 - 10:00',
        date: s1.date,
        status: AttendanceStatus.PRESENT,
      });

      const s2 = await AttendanceSession.create({
        collegeId: collegeA._id,
        departmentId: deptCSE._id,
        courseId: courseCSE._id,
        academicYearId: yearA._id,
        semesterId: sem1._id,
        sectionId: secA._id,
        subjectId: subAlgo._id,
        facultyId: facDoc._id,
        sectionName: 'Section A',
        subjectName: 'Algorithms',
        timeSlot: '09:00 - 10:00',
        date: new Date('2026-09-20T09:00:00Z'),
        status: AttendanceSessionStatus.CLOSED,
        isSubmitted: true,
      });
      await AttendanceRecord.create({
        collegeId: collegeA._id,
        departmentId: deptCSE._id,
        sessionId: s2._id,
        studentId: student1._id,
        studentName: 'Alice',
        rollNumber: 'CS-01',
        sectionId: secA._id,
        subjectId: subAlgo._id,
        courseId: courseCSE._id,
        academicYearId: yearA._id,
        semesterId: sem1._id,
        facultyId: facDoc._id,
        timeSlot: '09:00 - 10:00',
        date: s2.date,
        status: AttendanceStatus.ABSENT,
      });

      // Query only 2026-09-05 to 2026-09-15
      const res = await request(app)
        .get('/api/v1/analytics/department/overview?startDate=2026-09-05&endDate=2026-09-15')
        .set(authHeaderHodCSE);

      expect(res.status).toBe(200);
      expect(res.body.data.totalSessions).toBe(1);
      expect(res.body.data.presentCount).toBe(1);
      expect(res.body.data.absentCount).toBe(0);
      expect(res.body.data.overallAttendancePercentage).toBe(100.0);
    });

    it('19. Course, section, subject drilldown endpoints work and remain tenant safe', async () => {
      const coursesRes = await request(app)
        .get('/api/v1/analytics/department/courses')
        .set(authHeaderHodCSE);
      expect(coursesRes.status).toBe(200);
      expect(Array.isArray(coursesRes.body.data)).toBe(true);

      const sectionsRes = await request(app)
        .get('/api/v1/analytics/department/sections')
        .set(authHeaderHodCSE);
      expect(sectionsRes.status).toBe(200);
      expect(Array.isArray(sectionsRes.body.data)).toBe(true);

      const subjectsRes = await request(app)
        .get('/api/v1/analytics/department/subjects')
        .set(authHeaderHodCSE);
      expect(subjectsRes.status).toBe(200);
      expect(Array.isArray(subjectsRes.body.data)).toBe(true);

      const trendsRes = await request(app)
        .get('/api/v1/analytics/department/trends')
        .set(authHeaderHodCSE);
      expect(trendsRes.status).toBe(200);
      expect(Array.isArray(trendsRes.body.data.trends)).toBe(true);
    });

    it('23. Real attendance reflection test: altering session records immediately updates analytics', async () => {
      // Create session: 1 record, student1 is ABSENT
      const session = await AttendanceSession.create({
        collegeId: collegeA._id,
        departmentId: deptCSE._id,
        courseId: courseCSE._id,
        academicYearId: yearA._id,
        semesterId: sem1._id,
        sectionId: secA._id,
        subjectId: subAlgo._id,
        facultyId: facDoc._id,
        sectionName: 'Section A',
        subjectName: 'Algorithms',
        timeSlot: '09:00 - 10:00',
        date: new Date('2026-09-08T09:00:00Z'),
        status: AttendanceSessionStatus.CLOSED,
        isSubmitted: true,
        records: [
          { studentId: student1._id, studentName: student1.name, rollNumber: student1.rollNumber!, sectionId: secA._id, status: AttendanceStatus.ABSENT },
        ],
      });

      const record = await AttendanceRecord.create({
        collegeId: collegeA._id,
        departmentId: deptCSE._id,
        sessionId: session._id,
        studentId: student1._id,
        studentName: student1.name,
        rollNumber: student1.rollNumber,
        sectionId: secA._id,
        subjectId: subAlgo._id,
        courseId: courseCSE._id,
        academicYearId: yearA._id,
        semesterId: sem1._id,
        facultyId: facDoc._id,
        timeSlot: '09:00 - 10:00',
        date: session.date,
        status: AttendanceStatus.ABSENT,
      });

      // Analytics: 0% attendance
      let res = await request(app)
        .get('/api/v1/analytics/department/overview')
        .set(authHeaderHodCSE);

      expect(res.status).toBe(200);
      expect(res.body.data.overallAttendancePercentage).toBe(0.0);
      expect(res.body.data.absentCount).toBe(1);
      expect(res.body.data.presentCount).toBe(0);

      // Now faculty updates record to PRESENT
      await AttendanceRecord.updateOne({ _id: record._id }, { status: AttendanceStatus.PRESENT });
      await AttendanceSession.updateOne(
        { _id: session._id, 'records.studentId': student1._id },
        { $set: { 'records.$.status': AttendanceStatus.PRESENT } }
      );

      // Analytics immediately reflects this change: 100% attendance!
      res = await request(app)
        .get('/api/v1/analytics/department/overview')
        .set(authHeaderHodCSE);

      expect(res.status).toBe(200);
      expect(res.body.data.overallAttendancePercentage).toBe(100.0);
      expect(res.body.data.absentCount).toBe(0);
      expect(res.body.data.presentCount).toBe(1);
    });

    it('24. Regression coverage: Faculty attendance marking works seamlessly alongside analytics', async () => {
      // Faculty creates session
      const createRes = await request(app)
        .post('/api/v1/attendance/sessions')
        .set(authHeaderFac)
        .send({
          collegeId: collegeA._id.toString(),
          departmentId: deptCSE._id.toString(),
          courseId: courseCSE._id.toString(),
          academicYearId: yearA._id.toString(),
          semesterId: sem1._id.toString(),
          sectionId: secA._id.toString(),
          subjectId: subAlgo._id.toString(),
          timeSlot: '14:00 - 15:00',
          date: new Date('2026-09-09T14:00:00Z').toISOString(),
          records: [
            { studentId: student1._id.toString(), status: AttendanceStatus.PRESENT },
            { studentId: student2._id.toString(), status: AttendanceStatus.PRESENT },
          ],
        });

      expect([200, 201]).toContain(createRes.status);
      const sessionId = createRes.body.data?.id || createRes.body.data?._id;
      expect(sessionId).toBeDefined();

      // Check that department analytics immediately reflects newly marked session
      const analyticsRes = await request(app)
        .get('/api/v1/analytics/department/overview')
        .set(authHeaderHodCSE);

      expect(analyticsRes.status).toBe(200);
      expect(analyticsRes.body.data.totalSessions).toBeGreaterThan(0);
      expect(analyticsRes.body.data.presentCount).toBeGreaterThanOrEqual(2);
    });
  });
});
