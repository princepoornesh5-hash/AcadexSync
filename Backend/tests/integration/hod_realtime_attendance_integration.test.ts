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
import { Room } from '../../src/models/room.model';
import { Timetable } from '../../src/models/timetable.model';
import { AttendanceSession } from '../../src/models/attendanceSession.model';
import { AttendanceRecord } from '../../src/models/attendanceRecord.model';
import { AppRole } from '../../src/constants/roles';
import {
  CollegeStatus,
  DepartmentStatus,
  TimetableDay,
  TimetableStatus,
  TimetableSessionType,
  TimetableTimingMode,
  AttendanceStatus,
  AttendanceSessionStatus,
} from '../../src/constants/status';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';
import { PasswordService } from '../../src/services/password.service';

describe('ACADEX — Real-Time Attendance Integration (Prompt 5 of 6)', () => {
  let collegeA: InstanceType<typeof College>;
  let collegeB: InstanceType<typeof College>;

  let deptA: InstanceType<typeof Department>;
  let deptB: InstanceType<typeof Department>;

  let courseA: InstanceType<typeof Course>;
  let yearA: InstanceType<typeof AcademicYear>;
  let semA: InstanceType<typeof Semester>;
  let sectionA1: InstanceType<typeof Section>;
  let sectionA2: InstanceType<typeof Section>;

  let courseB: InstanceType<typeof Course>;
  let yearB: InstanceType<typeof AcademicYear>;
  let semB: InstanceType<typeof Semester>;
  let sectionB1: InstanceType<typeof Section>;

  let subDBMS: InstanceType<typeof Subject>;
  let subOS: InstanceType<typeof Subject>;

  let userFacA: InstanceType<typeof User>;
  let facDocA: InstanceType<typeof Faculty>;

  let userFacB: InstanceType<typeof User>;
  let facDocB: InstanceType<typeof Faculty>;

  let userStudent1: InstanceType<typeof User>;
  let studentDoc1: InstanceType<typeof Student>;

  let userStudent2: InstanceType<typeof User>;
  let studentDoc2: InstanceType<typeof Student>;

  let userStudentOtherSec: InstanceType<typeof User>;
  let studentDocOtherSec: InstanceType<typeof Student>;

  let userStudentCollegeB: InstanceType<typeof User>;
  let studentDocCollegeB: InstanceType<typeof Student>;

  let enrollWithdrawn: InstanceType<typeof StudentEnrollment>;

  let assignA: InstanceType<typeof FacultyAssignment>;
  let assignB: InstanceType<typeof FacultyAssignment>;

  let publishedTimetableA: InstanceType<typeof Timetable>;

  let facAHeader: { Authorization: string };
  let facBHeader: { Authorization: string };
  let student1Header: { Authorization: string };

  const mondayDateStr = '2026-08-24T09:00:00.000Z'; // August 24, 2026 is Monday
  const wednesdayDateStr = '2026-08-26T09:00:00.000Z'; // August 26, 2026 is Wednesday

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
    await FacultyAssignment.init();
    await Room.init();
    await Timetable.init();
    await AttendanceSession.init();
    await AttendanceRecord.init();
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
      code: 'AEC',
      address: 'Alpha Campus',
      email: 'admin@alpha.edu',
      phone: '+919988771101',
      principal: 'Dr. Alpha',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });

    collegeB = await College.create({
      name: 'Beta Institute of Tech',
      code: 'BIT',
      address: 'Beta Campus',
      email: 'admin@beta.edu',
      phone: '+919988771102',
      principal: 'Dr. Beta',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });

    // 2. Departments
    deptA = await Department.create({
      collegeId: collegeA._id,
      name: 'Computer Science & Engineering',
      code: 'CSE',
      status: DepartmentStatus.ACTIVE,
      isActive: true,
    });

    deptB = await Department.create({
      collegeId: collegeB._id,
      name: 'CSE Beta',
      code: 'CSE-B',
      status: DepartmentStatus.ACTIVE,
      isActive: true,
    });

    // 3. Academic Hierarchy College A
    courseA = await Course.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'B.Tech CSE',
      code: 'BTCSE',
      durationYears: 4,
      totalSemesters: 8,
      isActive: true,
    });

    yearA = await AcademicYear.create({
      collegeId: collegeA._id,
      courseId: courseA._id,
      year: 3,
      name: 'Third Year',
      startDate: new Date('2026-07-01'),
      endDate: new Date('2027-06-30'),
      isActive: true,
    });

    semA = await Semester.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: yearA._id,
      number: 5,
      name: 'Semester 5',
      startDate: new Date('2026-07-01'),
      endDate: new Date('2026-12-31'),
      isActive: true,
    });

    sectionA1 = await Section.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: yearA._id,
      semesterId: semA._id,
      name: 'Section 5A',
      capacity: 60,
      isActive: true,
    });

    sectionA2 = await Section.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: yearA._id,
      semesterId: semA._id,
      name: 'Section 5B',
      capacity: 60,
      isActive: true,
    });

    // College B Hierarchy
    courseB = await Course.create({
      collegeId: collegeB._id,
      departmentId: deptB._id,
      name: 'B.Tech CSE Beta',
      code: 'BTCSE-B',
      durationYears: 4,
      totalSemesters: 8,
      isActive: true,
    });

    yearB = await AcademicYear.create({
      collegeId: collegeB._id,
      courseId: courseB._id,
      year: 3,
      name: 'Third Year Beta',
      startDate: new Date('2026-07-01'),
      endDate: new Date('2027-06-30'),
      isActive: true,
    });

    semB = await Semester.create({
      collegeId: collegeB._id,
      departmentId: deptB._id,
      courseId: courseB._id,
      academicYearId: yearB._id,
      number: 5,
      name: 'Semester 5 Beta',
      startDate: new Date('2026-07-01'),
      endDate: new Date('2026-12-31'),
      isActive: true,
    });

    sectionB1 = await Section.create({
      collegeId: collegeB._id,
      departmentId: deptB._id,
      courseId: courseB._id,
      academicYearId: yearB._id,
      semesterId: semB._id,
      name: 'Section 5B-Beta',
      capacity: 60,
      isActive: true,
    });

    // 4. Subjects
    subDBMS = await Subject.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      semesterId: semA._id,
      name: 'Database Management Systems',
      code: 'CS501',
      credits: 4,
      isActive: true,
    });

    subOS = await Subject.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      semesterId: semA._id,
      name: 'Operating Systems',
      code: 'CS502',
      credits: 4,
      isActive: true,
    });

    // 5. Faculty Members
    userFacA = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'Prof. Alan Turing',
      email: 'turing@alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.FACULTY,
      instituteId: 'EMP-TURING',
      isActive: true,
    });

    facDocA = await Faculty.create({
      userId: userFacA._id,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'Prof. Alan Turing',
      email: 'turing@alpha.edu',
      employeeId: 'EMP-TURING',
      designation: 'Professor',
      isActive: true,
    });

    userFacB = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'Prof. Grace Hopper',
      email: 'hopper@alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.FACULTY,
      instituteId: 'EMP-HOPPER',
      isActive: true,
    });

    facDocB = await Faculty.create({
      userId: userFacB._id,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'Prof. Grace Hopper',
      email: 'hopper@alpha.edu',
      employeeId: 'EMP-HOPPER',
      designation: 'Associate Professor',
      isActive: true,
    });

    // 6. Students
    userStudent1 = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'Ravi Kumar',
      email: 'ravi@alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.STUDENT,
      instituteId: 'STU-ALPHA-01',
      isActive: true,
    });

    studentDoc1 = await Student.create({
      userId: userStudent1._id,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'Ravi Kumar',
      email: 'ravi@alpha.edu',
      rollNumber: 'CS2601',
      admissionNumber: 'ADM-001',
      sectionId: sectionA1._id,
      isActive: true,
    });

    userStudent2 = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'Anitha Sharma',
      email: 'anitha@alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.STUDENT,
      instituteId: 'STU-ALPHA-02',
      isActive: true,
    });

    studentDoc2 = await Student.create({
      userId: userStudent2._id,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'Anitha Sharma',
      email: 'anitha@alpha.edu',
      rollNumber: 'CS2602',
      admissionNumber: 'ADM-002',
      sectionId: sectionA1._id,
      isActive: true,
    });

    // Withdrawn Student in Section A1
    const userWithdrawn = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'Withdrawn Student',
      email: 'withdrawn@alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.STUDENT,
      instituteId: 'STU-ALPHA-99',
      isActive: true,
    });

    const studentDocWithdrawn = await Student.create({
      userId: userWithdrawn._id,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'Withdrawn Student',
      email: 'withdrawn@alpha.edu',
      rollNumber: 'CS2699',
      admissionNumber: 'ADM-099',
      sectionId: sectionA1._id,
      isActive: false,
    });

    // Student in Section A2
    userStudentOtherSec = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'Suresh Section B',
      email: 'suresh@alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.STUDENT,
      instituteId: 'STU-ALPHA-03',
      isActive: true,
    });

    studentDocOtherSec = await Student.create({
      userId: userStudentOtherSec._id,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'Suresh Section B',
      email: 'suresh@alpha.edu',
      rollNumber: 'CS2603',
      admissionNumber: 'ADM-003',
      sectionId: sectionA2._id,
      isActive: true,
    });

    // Student in College B
    userStudentCollegeB = await User.create({
      collegeId: collegeB._id,
      departmentId: deptB._id,
      name: 'College B Student',
      email: 'student@beta.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.STUDENT,
      instituteId: 'STU-BETA-01',
      isActive: true,
    });

    studentDocCollegeB = await Student.create({
      userId: userStudentCollegeB._id,
      collegeId: collegeB._id,
      departmentId: deptB._id,
      name: 'College B Student',
      email: 'student@beta.edu',
      rollNumber: 'BETACS01',
      admissionNumber: 'ADM-B-001',
      sectionId: sectionB1._id,
      isActive: true,
    });

    // 7. Enrollments
    await StudentEnrollment.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: yearA._id,
      semesterId: semA._id,
      sectionId: sectionA1._id,
      studentId: studentDoc1._id,
      status: 'active',
      enrollmentDate: new Date('2026-07-01'),
    });

    await StudentEnrollment.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: yearA._id,
      semesterId: semA._id,
      sectionId: sectionA1._id,
      studentId: studentDoc2._id,
      status: 'active',
      enrollmentDate: new Date('2026-07-01'),
    });

    enrollWithdrawn = await StudentEnrollment.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: yearA._id,
      semesterId: semA._id,
      sectionId: sectionA1._id,
      studentId: studentDocWithdrawn._id,
      status: 'withdrawn',
      enrollmentDate: new Date('2026-07-01'),
    });

    await StudentEnrollment.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: yearA._id,
      semesterId: semA._id,
      sectionId: sectionA2._id,
      studentId: studentDocOtherSec._id,
      status: 'active',
      enrollmentDate: new Date('2026-07-01'),
    });

    // 8. FacultyAssignments
    assignA = await FacultyAssignment.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: yearA._id,
      semesterId: semA._id,
      sectionId: sectionA1._id,
      subjectId: subDBMS._id,
      facultyId: facDocA._id,
      facultyName: facDocA.name,
      isActive: true,
    });

    assignB = await FacultyAssignment.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: yearA._id,
      semesterId: semA._id,
      sectionId: sectionA1._id,
      subjectId: subOS._id,
      facultyId: facDocB._id,
      facultyName: facDocB.name,
      isActive: true,
    });

    // 9. Published Timetable for Section A1
    publishedTimetableA = await Timetable.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: yearA._id,
      semesterId: semA._id,
      sectionId: sectionA1._id,
      name: 'Timetable 5A Published',
      status: TimetableStatus.PUBLISHED,
      version: 1,
      activeDays: [TimetableDay.MONDAY, TimetableDay.TUESDAY, TimetableDay.WEDNESDAY],
      timingMode: TimetableTimingMode.SAME_EVERY_DAY,
      periods: [
        { index: 0, name: 'P1', startTime: '09:00', endTime: '10:00' },
        { index: 1, name: 'P2', startTime: '10:00', endTime: '11:00' },
      ],
      breaks: [],
      entries: [
        {
          _id: new mongoose.Types.ObjectId(),
          dayOfWeek: TimetableDay.MONDAY,
          startTime: '09:00',
          endTime: '10:00',
          subjectId: subDBMS._id,
          facultyId: facDocA._id,
          facultyAssignmentId: assignA._id,
          roomNumber: 'Room 301',
          building: 'Main Block',
          sessionType: TimetableSessionType.LECTURE,
        },
        {
          _id: new mongoose.Types.ObjectId(),
          dayOfWeek: TimetableDay.MONDAY,
          startTime: '10:00',
          endTime: '11:00',
          subjectId: subOS._id,
          facultyId: facDocB._id,
          facultyAssignmentId: assignB._id,
          roomNumber: 'Room 301',
          building: 'Main Block',
          sessionType: TimetableSessionType.LECTURE,
        },
      ],
      publishedAt: new Date(),
    });

    // 10. Auth Headers
    facAHeader = createTestAuthHeader({
      userId: userFacA.id,
      role: AppRole.FACULTY,
      collegeId: collegeA.id,
      departmentId: deptA.id,
    });

    facBHeader = createTestAuthHeader({
      userId: userFacB.id,
      role: AppRole.FACULTY,
      collegeId: collegeA.id,
      departmentId: deptA.id,
    });

    student1Header = createTestAuthHeader({
      userId: userStudent1.id,
      role: AppRole.STUDENT,
      collegeId: collegeA.id,
      departmentId: deptA.id,
    });
  });

  // =========================================================================
  // SCENARIOS 1 - 18
  // =========================================================================

  it('1. Authorized faculty opens own published class', async () => {
    const entryId = publishedTimetableA.entries[0]._id!.toString();

    const res = await request(app)
      .post('/api/v1/attendance/sessions')
      .set(facAHeader)
      .send({
        timetableId: publishedTimetableA.id,
        timetableEntryId: entryId,
        sectionId: sectionA1.id,
        subjectId: subDBMS.id,
        date: mondayDateStr,
        timeSlot: '09:00 - 10:00',
        records: [],
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.facultyId).toBe(facDocA.id);
    expect(res.body.data.subjectId).toBe(subDBMS.id);
    expect(res.body.data.sectionId).toBe(sectionA1.id);
    expect(res.body.data.facultyAssignmentId).toBe(assignA.id);
    expect(res.body.data.timetableEntryId).toBe(entryId);
    expect(res.body.data.status).toBe(AttendanceSessionStatus.OPEN);
  });

  it('2. Unauthorized faculty cannot open another faculty class (403 Forbidden)', async () => {
    const entryId = publishedTimetableA.entries[0]._id!.toString(); // Assigned to Faculty A

    const res = await request(app)
      .post('/api/v1/attendance/sessions')
      .set(facBHeader) // Faculty B
      .send({
        timetableId: publishedTimetableA.id,
        timetableEntryId: entryId,
        sectionId: sectionA1.id,
        subjectId: subDBMS.id,
        date: mondayDateStr,
        timeSlot: '09:00 - 10:00',
        records: [],
      });

    expect(res.status).toBe(403);
    expect(res.body.success).toBe(false);
  });

  it('3. Student cannot open mutation session (403 Forbidden)', async () => {
    const entryId = publishedTimetableA.entries[0]._id!.toString();

    const res = await request(app)
      .post('/api/v1/attendance/sessions')
      .set(student1Header)
      .send({
        timetableId: publishedTimetableA.id,
        timetableEntryId: entryId,
        sectionId: sectionA1.id,
        subjectId: subDBMS.id,
        date: mondayDateStr,
        timeSlot: '09:00 - 10:00',
        records: [],
      });

    expect(res.status).toBe(403);
  });

  it('4. Real section roster is resolved from active StudentEnrollment', async () => {
    // Calling academics enrollments for Section A1 as authenticated faculty
    const res = await request(app)
      .get(`/api/v1/academics/enrollments?sectionId=${sectionA1.id}&status=active`)
      .set(facAHeader);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.items).toHaveLength(2); // Student 1 and Student 2 (StudentWithdrawn is excluded)

    const names = res.body.data.items.map((i: any) => i.student.name);
    expect(names).toContain('Ravi Kumar');
    expect(names).toContain('Anitha Sharma');
    expect(names).not.toContain('Withdrawn Student');
  });

  it('5. Only active/current enrollments appear (withdrawn/transferred excluded)', async () => {
    const res = await request(app)
      .get(`/api/v1/academics/enrollments?sectionId=${sectionA1.id}&status=active`)
      .set(facAHeader);

    const activeIds = res.body.data.items.map((i: any) => i.student._id || i.student.id);
    expect(activeIds).toContain(studentDoc1.id);
    expect(activeIds).toContain(studentDoc2.id);
    expect(activeIds).not.toContain(enrollWithdrawn.studentId.toString());
  });

  it('6. Student from another section is rejected (400 Bad Request)', async () => {
    const entryId = publishedTimetableA.entries[0]._id!.toString();

    const res = await request(app)
      .post('/api/v1/attendance/sessions')
      .set(facAHeader)
      .send({
        timetableId: publishedTimetableA.id,
        timetableEntryId: entryId,
        sectionId: sectionA1.id,
        subjectId: subDBMS.id,
        date: mondayDateStr,
        timeSlot: '09:00 - 10:00',
        records: [
          { studentId: studentDoc1.id, status: AttendanceStatus.PRESENT },
          { studentId: studentDocOtherSec.id, status: AttendanceStatus.PRESENT }, // Section 5B student!
        ],
      });

    expect(res.status).toBe(400);
    expect(res.body.error.message).toContain('not enrolled in section');

    // Atomic: no session created
    const sessions = await AttendanceSession.find({});
    expect(sessions).toHaveLength(0);
  });

  it('7. Student from another college is rejected (403 Forbidden)', async () => {
    const entryId = publishedTimetableA.entries[0]._id!.toString();

    const res = await request(app)
      .post('/api/v1/attendance/sessions')
      .set(facAHeader)
      .send({
        timetableId: publishedTimetableA.id,
        timetableEntryId: entryId,
        sectionId: sectionA1.id,
        subjectId: subDBMS.id,
        date: mondayDateStr,
        timeSlot: '09:00 - 10:00',
        records: [
          { studentId: studentDocCollegeB.id, status: AttendanceStatus.PRESENT }, // College B student!
        ],
      });

    expect([400, 403]).toContain(res.status);

    // Atomic: no session created
    const sessions = await AttendanceSession.find({});
    expect(sessions).toHaveLength(0);
  });

  it('8. Duplicate session creation is prevented (409 Conflict)', async () => {
    const entryId = publishedTimetableA.entries[0]._id!.toString();

    // 1st Creation
    const res1 = await request(app)
      .post('/api/v1/attendance/sessions')
      .set(facAHeader)
      .send({
        timetableId: publishedTimetableA.id,
        timetableEntryId: entryId,
        sectionId: sectionA1.id,
        subjectId: subDBMS.id,
        date: mondayDateStr,
        timeSlot: '09:00 - 10:00',
        records: [{ studentId: studentDoc1.id, status: AttendanceStatus.PRESENT }],
      });
    expect(res1.status).toBe(201);

    // 2nd Creation attempt for same period and date
    const res2 = await request(app)
      .post('/api/v1/attendance/sessions')
      .set(facAHeader)
      .send({
        timetableId: publishedTimetableA.id,
        timetableEntryId: entryId,
        sectionId: sectionA1.id,
        subjectId: subDBMS.id,
        date: mondayDateStr,
        timeSlot: '09:00 - 10:00',
        records: [{ studentId: studentDoc1.id, status: AttendanceStatus.PRESENT }],
      });
    expect(res2.status).toBe(409);
    expect(res2.body.error.message).toContain('already exists');
  });

  it('9. Duplicate attendance record in same payload is prevented (409 Conflict)', async () => {
    const entryId = publishedTimetableA.entries[0]._id!.toString();

    const res = await request(app)
      .post('/api/v1/attendance/sessions')
      .set(facAHeader)
      .send({
        timetableId: publishedTimetableA.id,
        timetableEntryId: entryId,
        sectionId: sectionA1.id,
        subjectId: subDBMS.id,
        date: mondayDateStr,
        timeSlot: '09:00 - 10:00',
        records: [
          { studentId: studentDoc1.id, status: AttendanceStatus.PRESENT },
          { studentId: studentDoc1.id, status: AttendanceStatus.ABSENT }, // Duplicate studentId
        ],
      });

    expect(res.status).toBe(409);
    expect(res.body.error.message).toContain('Duplicate attendance record');
  });

  it('10. Valid attendance submission succeeds', async () => {
    const entryId = publishedTimetableA.entries[0]._id!.toString();

    const res = await request(app)
      .post('/api/v1/attendance/sessions')
      .set(facAHeader)
      .send({
        timetableId: publishedTimetableA.id,
        timetableEntryId: entryId,
        sectionId: sectionA1.id,
        subjectId: subDBMS.id,
        date: mondayDateStr,
        timeSlot: '09:00 - 10:00',
        records: [
          { studentId: studentDoc1.id, status: AttendanceStatus.PRESENT },
          { studentId: studentDoc2.id, status: AttendanceStatus.LATE, remarks: 'Bus delay' },
        ],
      });

    expect(res.status).toBe(201);
    expect(res.body.data.records).toHaveLength(2);

    const dbRecords = await AttendanceRecord.find({ sessionId: res.body.data.id });
    expect(dbRecords).toHaveLength(2);
    expect(dbRecords.find((r) => r.studentId.toString() === studentDoc1.id)!.status).toBe(AttendanceStatus.PRESENT);
    expect(dbRecords.find((r) => r.studentId.toString() === studentDoc2.id)!.status).toBe(AttendanceStatus.LATE);
  });

  it('11. Invalid student submission fails atomically (zero partial writes)', async () => {
    const entryId = publishedTimetableA.entries[0]._id!.toString();

    const res = await request(app)
      .post('/api/v1/attendance/sessions')
      .set(facAHeader)
      .send({
        timetableId: publishedTimetableA.id,
        timetableEntryId: entryId,
        sectionId: sectionA1.id,
        subjectId: subDBMS.id,
        date: mondayDateStr,
        timeSlot: '09:00 - 10:00',
        records: [
          { studentId: studentDoc1.id, status: AttendanceStatus.PRESENT },
          { studentId: new mongoose.Types.ObjectId().toString(), status: AttendanceStatus.ABSENT }, // Non-existent student
        ],
      });

    expect([400, 404]).toContain(res.status);

    // Verify ZERO records or sessions written
    const sessions = await AttendanceSession.find({});
    const records = await AttendanceRecord.find({});
    expect(sessions).toHaveLength(0);
    expect(records).toHaveLength(0);
  });

  it('12. Unauthorized attendance update fails (403 Forbidden)', async () => {
    const entryId = publishedTimetableA.entries[0]._id!.toString();

    // Faculty A creates session
    const resCreate = await request(app)
      .post('/api/v1/attendance/sessions')
      .set(facAHeader)
      .send({
        timetableId: publishedTimetableA.id,
        timetableEntryId: entryId,
        sectionId: sectionA1.id,
        subjectId: subDBMS.id,
        date: mondayDateStr,
        timeSlot: '09:00 - 10:00',
        records: [{ studentId: studentDoc1.id, status: AttendanceStatus.PRESENT }],
      });
    expect(resCreate.status).toBe(201);
    const sessionId = resCreate.body.data.id;

    // Faculty B attempts to modify Faculty A's records
    const resUpdate = await request(app)
      .post(`/api/v1/attendance/sessions/${sessionId}/records`)
      .set(facBHeader)
      .send({
        records: [{ studentId: studentDoc1.id, status: AttendanceStatus.ABSENT }],
      });
    expect(resUpdate.status).toBe(403);

    // Records untouched
    const rec = await AttendanceRecord.findOne({ sessionId });
    expect(rec!.status).toBe(AttendanceStatus.PRESENT);
  });

  it('13. FacultyAssignment deactivation is handled correctly (rejected on new session)', async () => {
    const entryId = publishedTimetableA.entries[0]._id!.toString();

    // Deactivate FacultyAssignment post-publish
    await FacultyAssignment.findByIdAndUpdate(assignA._id, { isActive: false });

    const res = await request(app)
      .post('/api/v1/attendance/sessions')
      .set(facAHeader)
      .send({
        timetableId: publishedTimetableA.id,
        timetableEntryId: entryId,
        sectionId: sectionA1.id,
        subjectId: subDBMS.id,
        date: mondayDateStr,
        timeSlot: '09:00 - 10:00',
        records: [],
      });

    expect(res.status).toBe(403);
    expect(res.body.error.message).toContain('inactive');
  });

  it('14. Closed/locked session behavior is enforced (cannot mutate closed/locked session)', async () => {
    const entryId = publishedTimetableA.entries[0]._id!.toString();

    // Create session
    const resCreate = await request(app)
      .post('/api/v1/attendance/sessions')
      .set(facAHeader)
      .send({
        timetableId: publishedTimetableA.id,
        timetableEntryId: entryId,
        sectionId: sectionA1.id,
        subjectId: subDBMS.id,
        date: mondayDateStr,
        timeSlot: '09:00 - 10:00',
        records: [{ studentId: studentDoc1.id, status: AttendanceStatus.PRESENT }],
      });
    expect(resCreate.status).toBe(201);
    const sessionId = resCreate.body.data.id;

    // Lock session
    const resLock = await request(app)
      .post(`/api/v1/attendance/sessions/${sessionId}/lock`)
      .set(facAHeader);
    expect(resLock.status).toBe(200);

    // Mutation attempt after lock
    const resMutate = await request(app)
      .post(`/api/v1/attendance/sessions/${sessionId}/records`)
      .set(facAHeader)
      .send({
        records: [{ studentId: studentDoc1.id, status: AttendanceStatus.ABSENT }],
      });
    expect(resMutate.status).toBe(400);
    expect(resMutate.body.error.message).toContain('LOCKED');
  });

  it('15. Attendance window / day-of-week validation is enforced (Wednesday vs Monday entry)', async () => {
    const entryId = publishedTimetableA.entries[0]._id!.toString(); // Scheduled for Monday

    const res = await request(app)
      .post('/api/v1/attendance/sessions')
      .set(facAHeader)
      .send({
        timetableId: publishedTimetableA.id,
        timetableEntryId: entryId,
        sectionId: sectionA1.id,
        subjectId: subDBMS.id,
        date: wednesdayDateStr, // Wednesday!
        timeSlot: '09:00 - 10:00',
        records: [],
      });

    expect(res.status).toBe(400);
    expect(res.body.error.message).toContain('Scheduled day mismatch');
  });

  it('16. Cross-tenant session access fails (403 Forbidden)', async () => {
    // College B Faculty attempts to open College A session
    const userFacCollegeB = await User.create({
      collegeId: collegeB._id,
      departmentId: deptB._id,
      name: 'Beta Faculty',
      email: 'fac@beta.edu',
      passwordHash: await PasswordService.hashPassword('Password123'),
      role: AppRole.FACULTY,
      instituteId: 'EMP-BETA-01',
      isActive: true,
    });
    await Faculty.create({
      userId: userFacCollegeB._id,
      collegeId: collegeB._id,
      departmentId: deptB._id,
      name: 'Beta Faculty',
      email: 'fac@beta.edu',
      employeeId: 'EMP-BETA-01',
      designation: 'Professor',
      isActive: true,
    });

    const betaFacHeader = createTestAuthHeader({
      userId: userFacCollegeB.id,
      role: AppRole.FACULTY,
      collegeId: collegeB.id,
      departmentId: deptB.id,
    });

    const entryId = publishedTimetableA.entries[0]._id!.toString();

    const res = await request(app)
      .post('/api/v1/attendance/sessions')
      .set(betaFacHeader)
      .send({
        timetableId: publishedTimetableA.id,
        timetableEntryId: entryId,
        sectionId: sectionA1.id,
        subjectId: subDBMS.id,
        date: mondayDateStr,
        timeSlot: '09:00 - 10:00',
        records: [],
      });

    expect(res.status).toBe(403);
  });

  it('17. Deep-link tampering fails (Faculty B tampering with Faculty A timetableEntryId)', async () => {
    const entryId = publishedTimetableA.entries[0]._id!.toString(); // Faculty A's entry

    // Faculty B sends request with Faculty A's entryId but own identity
    const res = await request(app)
      .post('/api/v1/attendance/sessions')
      .set(facBHeader)
      .send({
        timetableId: publishedTimetableA.id,
        timetableEntryId: entryId,
        sectionId: sectionA1.id,
        subjectId: subDBMS.id,
        date: mondayDateStr,
        timeSlot: '09:00 - 10:00',
        records: [{ studentId: studentDoc1.id, status: AttendanceStatus.PRESENT }],
      });

    expect(res.status).toBe(403);
    expect(res.body.error.message).toContain('Faculty is not authorized');
  });

  it('18. Concurrent session creation behaves safely', async () => {
    const entryId = publishedTimetableA.entries[0]._id!.toString();

    // Faculty A (Authorized) vs Faculty B (Unauthorized) fire requests simultaneously
    const [resAuth, resUnauth] = await Promise.all([
      request(app)
        .post('/api/v1/attendance/sessions')
        .set(facAHeader)
        .send({
          timetableId: publishedTimetableA.id,
          timetableEntryId: entryId,
          sectionId: sectionA1.id,
          subjectId: subDBMS.id,
          date: mondayDateStr,
          timeSlot: '09:00 - 10:00',
          records: [{ studentId: studentDoc1.id, status: AttendanceStatus.PRESENT }],
        }),
      request(app)
        .post('/api/v1/attendance/sessions')
        .set(facBHeader)
        .send({
          timetableId: publishedTimetableA.id,
          timetableEntryId: entryId,
          sectionId: sectionA1.id,
          subjectId: subDBMS.id,
          date: mondayDateStr,
          timeSlot: '09:00 - 10:00',
          records: [{ studentId: studentDoc1.id, status: AttendanceStatus.ABSENT }],
        }),
    ]);

    expect(resAuth.status).toBe(201);
    expect(resUnauth.status).toBe(403);

    const sessions = await AttendanceSession.find({});
    expect(sessions).toHaveLength(1);
    expect(sessions[0].facultyId.toString()).toBe(facDocA.id);

    const records = await AttendanceRecord.find({ sessionId: sessions[0]._id });
    expect(records).toHaveLength(1);
    expect(records[0].status).toBe(AttendanceStatus.PRESENT);
  });

  it('19. Student views updated personal attendance history reflecting saved session', async () => {
    const entryId = publishedTimetableA.entries[0]._id!.toString();

    // Faculty marks attendance: Student 1 = PRESENT
    await request(app)
      .post('/api/v1/attendance/sessions')
      .set(facAHeader)
      .send({
        timetableId: publishedTimetableA.id,
        timetableEntryId: entryId,
        sectionId: sectionA1.id,
        subjectId: subDBMS.id,
        date: mondayDateStr,
        timeSlot: '09:00 - 10:00',
        records: [
          { studentId: studentDoc1.id, status: AttendanceStatus.PRESENT },
          { studentId: studentDoc2.id, status: AttendanceStatus.ABSENT },
        ],
      });

    // Student 1 queries personal attendance history
    const resStu = await request(app)
      .get('/api/v1/attendance/students/me')
      .set(student1Header);

    expect(resStu.status).toBe(200);
    expect(resStu.body.success).toBe(true);
    expect(resStu.body.data.items).toHaveLength(1);
    expect(resStu.body.data.items[0].status).toBe(AttendanceStatus.PRESENT);

    // Student 1 queries subject breakdown
    const resSub = await request(app)
      .get('/api/v1/attendance/students/me/subjects')
      .set(student1Header);

    expect(resSub.status).toBe(200);
    expect(resSub.body.data).toHaveLength(1);
    expect(resSub.body.data[0].presentCount).toBe(1);
    expect(resSub.body.data[0].percentage).toBe(100);
  });
});
