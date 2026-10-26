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
import { Room } from '../../src/models/room.model';
import { Timetable } from '../../src/models/timetable.model';
import { FacultyAssignment } from '../../src/models/facultyAssignment.model';
import { AttendanceSession } from '../../src/models/attendanceSession.model';
import { Note } from '../../src/models/note.model';
import { AppRole } from '../../src/constants/roles';
import {
  AccountStatus,
  CollegeStatus,
  DepartmentStatus,
  TimetableDay,
  TimetableStatus,
  AttendanceStatus,
  NoteType,
  NoteVisibility,
} from '../../src/constants/status';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';
import { PasswordService } from '../../src/services/password.service';

describe('Faculty Assignment Consistency & Teaching Context Integration Tests', () => {
  let collegeA: InstanceType<typeof College>;
  let collegeB: InstanceType<typeof College>;
  let deptA: InstanceType<typeof Department>;
  let courseA: InstanceType<typeof Course>;
  let ayA: InstanceType<typeof AcademicYear>;
  let semA: InstanceType<typeof Semester>;
  let secA: InstanceType<typeof Section>;
  let subjectIot: InstanceType<typeof Subject>;

  let userMani: InstanceType<typeof User>;
  let facultyMani: InstanceType<typeof Faculty>;
  let headerMani: { Authorization: string };

  let userOtherFaculty: InstanceType<typeof User>;
  let headerOtherFaculty: { Authorization: string };

  let userCollegeB: InstanceType<typeof User>;
  let headerCollegeB: { Authorization: string };

  let studentUser1: InstanceType<typeof User>;
  let studentProfile1: InstanceType<typeof Student>;

  let iotAssignment: InstanceType<typeof FacultyAssignment>;
  let timetablePublished: InstanceType<typeof Timetable>;

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
    await StudentEnrollment.init();
    await Room.init();
    await Timetable.init();
    await FacultyAssignment.init();
    await AttendanceSession.init();
    await Note.init();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();
    const defaultPassword = await PasswordService.hashPassword('Pass1234!');

    // 1. Colleges
    collegeA = await College.create({
      name: 'College Alpha',
      code: 'ALPHA',
      address: '100 Alpha Campus',
      email: 'admin@alpha.edu',
      phone: '+919988776601',
      principal: 'Dr. Principal Alpha',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });

    collegeB = await College.create({
      name: 'College Beta',
      code: 'BETA',
      address: '200 Beta Campus',
      email: 'admin@beta.edu',
      phone: '+919988776602',
      principal: 'Dr. Principal Beta',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });

    // 2. Department & Academic Hierarchy
    deptA = await Department.create({
      collegeId: collegeA._id,
      name: 'Computer Engineering',
      code: 'CME',
      status: DepartmentStatus.ACTIVE,
      isActive: true,
    });

    courseA = await Course.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'Diploma in Computer Engineering',
      code: 'DCME',
      durationYears: 3,
      totalSemesters: 6,
      isActive: true,
    });

    ayA = await AcademicYear.create({
      collegeId: collegeA._id,
      name: '2026-2027',
      startDate: new Date('2026-06-01'),
      endDate: new Date('2027-05-31'),
      isCurrent: true,
      isActive: true,
    });

    semA = await Semester.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: ayA._id,
      name: 'Semester 5',
      number: 5,
      isCurrent: true,
      isActive: true,
    });

    secA = await Section.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: ayA._id,
      semesterId: semA._id,
      name: 'Section A',
      capacity: 60,
      isActive: true,
    });

    subjectIot = await Subject.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      semesterId: semA._id,
      name: 'Internet of Things',
      code: 'CM-504',
      type: 'theory',
      credits: 4,
      isActive: true,
    });

    // 3. Faculty 1: T Masila Mani (User._id != Faculty._id)
    userMani = await User.create({
      name: 'T Masila Mani',
      email: 'mani@alpha.edu',
      password: defaultPassword,
      role: AppRole.FACULTY,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      status: AccountStatus.ACTIVE,
      isEmailVerified: true,
    });

    facultyMani = await Faculty.create({
      userId: userMani._id,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'T Masila Mani',
      email: 'mani@alpha.edu',
      designation: 'Assistant Professor',
      facultyType: 'permanent',
      status: 'active',
      isActive: true,
    });

    headerMani = createTestAuthHeader({
      userId: userMani._id.toString(),
      role: AppRole.FACULTY,
      collegeId: collegeA._id.toString(),
      departmentId: deptA._id.toString(),
      email: userMani.email,
      name: userMani.name,
    });

    // 4. Faculty 2: Other Faculty in same college
    userOtherFaculty = await User.create({
      name: 'Prof. Other',
      email: 'other@alpha.edu',
      password: defaultPassword,
      role: AppRole.FACULTY,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      status: AccountStatus.ACTIVE,
      isEmailVerified: true,
    });

    await Faculty.create({
      userId: userOtherFaculty._id,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'Prof. Other',
      email: 'other@alpha.edu',
      designation: 'Associate Professor',
      facultyType: 'permanent',
      status: 'active',
      isActive: true,
    });

    headerOtherFaculty = createTestAuthHeader({
      userId: userOtherFaculty._id.toString(),
      role: AppRole.FACULTY,
      collegeId: collegeA._id.toString(),
      departmentId: deptA._id.toString(),
      email: userOtherFaculty.email,
      name: userOtherFaculty.name,
    });

    // 5. Faculty in College Beta
    const deptB = await Department.create({
      collegeId: collegeB._id,
      name: 'Beta Science',
      code: 'BSCI',
      status: DepartmentStatus.ACTIVE,
      isActive: true,
    });

    userCollegeB = await User.create({
      name: 'Dr. Beta Faculty',
      email: 'faculty@beta.edu',
      password: defaultPassword,
      role: AppRole.FACULTY,
      collegeId: collegeB._id,
      departmentId: deptB._id,
      status: AccountStatus.ACTIVE,
      isEmailVerified: true,
    });

    await Faculty.create({
      userId: userCollegeB._id,
      collegeId: collegeB._id,
      departmentId: deptB._id,
      name: 'Dr. Beta Faculty',
      email: 'faculty@beta.edu',
      designation: 'Professor',
      facultyType: 'permanent',
      status: 'active',
      isActive: true,
    });

    headerCollegeB = createTestAuthHeader({
      userId: userCollegeB._id.toString(),
      role: AppRole.FACULTY,
      collegeId: collegeB._id.toString(),
      departmentId: deptB._id.toString(),
      email: userCollegeB.email,
      name: userCollegeB.name,
    });

    // 6. Student & Enrollment
    studentUser1 = await User.create({
      name: 'Student One',
      email: 's1@alpha.edu',
      password: defaultPassword,
      role: AppRole.STUDENT,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      status: AccountStatus.ACTIVE,
      isEmailVerified: true,
    });

    studentProfile1 = await Student.create({
      userId: studentUser1._id,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: ayA._id,
      semesterId: semA._id,
      sectionId: secA._id,
      name: 'Student One',
      rollNumber: 'ROLL-001',
      registrationNumber: 'REG-001',
      status: 'active',
      isActive: true,
    });

    await StudentEnrollment.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: ayA._id,
      semesterId: semA._id,
      sectionId: secA._id,
      studentId: studentProfile1._id,
      userId: studentUser1._id,
      rollNumber: 'ROLL-001',
      status: 'active',
      isActive: true,
    });

    // 7. Canonical FacultyAssignment: Linked to facultyMani._id (Faculty._id, NOT User._id)
    iotAssignment = await FacultyAssignment.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: ayA._id,
      semesterId: semA._id,
      sectionId: secA._id,
      subjectId: subjectIot._id,
      facultyId: facultyMani._id, // References Faculty._id!
      facultyName: facultyMani.name,
      status: 'active',
      isActive: true,
    });

    // 8. Timetable with IoT Entry on Tuesday 11:00 - 13:00
    timetablePublished = await Timetable.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: ayA._id,
      semesterId: semA._id,
      sectionId: secA._id,
      name: 'Section A - 5th Sem Timetable',
      status: TimetableStatus.PUBLISHED,
      isActive: true,
      entries: [
        {
          _id: new mongoose.Types.ObjectId(),
          dayOfWeek: TimetableDay.TUESDAY,
          startTime: '11:00',
          endTime: '13:00',
          subjectId: subjectIot._id,
          facultyId: facultyMani._id,
          facultyAssignmentId: iotAssignment._id,
          roomNumber: 'LAB-3',
          sessionType: 'lab',
        },
      ],
    });
  });

  describe('1. Canonical Endpoint: GET /api/v1/academics/faculty-assignments/my', () => {
    it('returns authorized teaching assignment resolving Faculty._id from authenticated User._id', async () => {
      expect(userMani._id.toString()).not.toBe(facultyMani._id.toString());

      const res = await request(app)
        .get('/api/v1/academics/faculty-assignments/my')
        .set(headerMani);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(Array.isArray(res.body.data)).toBe(true);
      expect(res.body.data.length).toBe(1);

      const returned = res.body.data[0];
      expect(returned.id).toBe(iotAssignment._id.toString());
      expect(returned.subjectId.toString()).toBe(subjectIot._id.toString());
      expect(returned.sectionId.toString()).toBe(secA._id.toString());
      expect(returned.facultyId.toString()).toBe(facultyMani._id.toString());
      expect(returned.isActive).toBe(true);
    });

    it('prevents a faculty member from seeing another faculty member assignments', async () => {
      const res = await request(app)
        .get('/api/v1/academics/faculty-assignments/my')
        .set(headerOtherFaculty);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.length).toBe(0);
    });

    it('prevents cross-college assignment exposure', async () => {
      const res = await request(app)
        .get('/api/v1/academics/faculty-assignments/my')
        .set(headerCollegeB);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.length).toBe(0);
    });
  });

  describe('2. Timetable Entry Ownership & Canonical Assignment Association', () => {
    it('resolves published timetable entry with canonical facultyAssignmentId for authenticated faculty', async () => {
      const res = await request(app)
        .get('/api/v1/timetables/faculty/me')
        .set(headerMani);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.length).toBeGreaterThanOrEqual(1);

      const entry = res.body.data[0];
      expect(entry.subjectId.toString()).toBe(subjectIot._id.toString());
      expect(entry.facultyAssignmentId.toString()).toBe(iotAssignment._id.toString());
      expect(entry.dayOfWeek).toBe(TimetableDay.TUESDAY);
      expect(entry.startTime).toBe('11:00');
      expect(entry.endTime).toBe('13:00');
    });
  });

  describe('3. Attendance Session Authorization Enforcement', () => {
    it('authorizes attendance session creation when timetable entry resolves to valid assignment', async () => {
      const entryId = (timetablePublished.entries![0] as any)._id.toString();

      const res = await request(app)
        .post('/api/v1/attendance/sessions')
        .set(headerMani)
        .send({
          collegeId: collegeA._id.toString(),
          departmentId: deptA._id.toString(),
          courseId: courseA._id.toString(),
          academicYearId: ayA._id.toString(),
          semesterId: semA._id.toString(),
          sectionId: secA._id.toString(),
          subjectId: subjectIot._id.toString(),
          timetableId: timetablePublished._id.toString(),
          timetableEntryId: entryId,
          facultyAssignmentId: iotAssignment._id.toString(),
          date: '2026-10-13',
          timeSlot: '11:00 - 13:00',
          startTime: '11:00',
          endTime: '13:00',
          type: 'lecture',
          records: [
            {
              studentId: studentProfile1._id.toString(),
              status: AttendanceStatus.PRESENT,
            },
          ],
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data).toBeDefined();
    });

    it('rejects attendance session when timetable entry is orphaned or assignment is unauthorized', async () => {
      const fakeAssignmentId = new mongoose.Types.ObjectId().toString();
      const fakeEntryId = new mongoose.Types.ObjectId().toString();

      const res = await request(app)
        .post('/api/v1/attendance/sessions')
        .set(headerMani)
        .send({
          collegeId: collegeA._id.toString(),
          departmentId: deptA._id.toString(),
          courseId: courseA._id.toString(),
          academicYearId: ayA._id.toString(),
          semesterId: semA._id.toString(),
          sectionId: secA._id.toString(),
          subjectId: subjectIot._id.toString(),
          timetableId: timetablePublished._id.toString(),
          timetableEntryId: fakeEntryId,
          facultyAssignmentId: fakeAssignmentId,
          date: '2026-10-13',
          timeSlot: '11:00 - 13:00',
          startTime: '11:00',
          endTime: '13:00',
          type: 'lecture',
          records: [],
        });

      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
    });

    it('rejects attendance marking by unauthorized faculty member for another faculty assignment', async () => {
      const entryId = (timetablePublished.entries![0] as any)._id.toString();

      const res = await request(app)
        .post('/api/v1/attendance/sessions')
        .set(headerOtherFaculty) // Prof. Other attempting to mark T Masila Mani's class
        .send({
          collegeId: collegeA._id.toString(),
          departmentId: deptA._id.toString(),
          courseId: courseA._id.toString(),
          academicYearId: ayA._id.toString(),
          semesterId: semA._id.toString(),
          sectionId: secA._id.toString(),
          subjectId: subjectIot._id.toString(),
          timetableId: timetablePublished._id.toString(),
          timetableEntryId: entryId,
          facultyAssignmentId: iotAssignment._id.toString(),
          date: '2026-10-13',
          timeSlot: '11:00 - 13:00',
          startTime: '11:00',
          endTime: '13:00',
          type: 'lecture',
          records: [],
        });

      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
    });
  });

  describe('4. Note Management Scope Enforcement', () => {
    it('authorizes note creation within faculty member authorized subject & section', async () => {
      const res = await request(app)
        .post('/api/v1/academics/notes/upload-url')
        .set(headerMani)
        .send({
          title: 'IoT Week 1 Lab Intro',
          subjectId: subjectIot._id.toString(),
          sectionId: secA._id.toString(),
          semesterId: semA._id.toString(),
          courseId: courseA._id.toString(),
          noteType: NoteType.CHAPTER,
          fileName: 'iot-week1.pdf',
          fileSize: 1024 * 50,
          mimeType: 'application/pdf',
          visibility: NoteVisibility.PUBLIC,
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.note.subjectId.toString()).toBe(subjectIot._id.toString());
    });

    it('rejects note publishing against an unauthorized cross-college or unauthorized scope', async () => {
      const res = await request(app)
        .post('/api/v1/academics/notes/upload-url')
        .set(headerCollegeB) // Faculty in Beta trying to publish note for College Alpha subject
        .send({
          title: 'Unauthorized Cross-College Note',
          subjectId: subjectIot._id.toString(),
          fileName: 'cross-college.pdf',
          fileSize: 1024 * 50,
          mimeType: 'application/pdf',
        });

      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
    });
  });
});
