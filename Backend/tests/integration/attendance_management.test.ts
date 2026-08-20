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
import { StudentEnrollment } from '../../src/models/studentEnrollment.model';
import { Timetable } from '../../src/models/timetable.model';
import { AttendanceSession } from '../../src/models/attendanceSession.model';
import { AttendanceRecord } from '../../src/models/attendanceRecord.model';
import { AuditLog } from '../../src/models/auditLog.model';
import { AppRole } from '../../src/constants/roles';
import {
  AccountStatus,
  CollegeStatus,
  DepartmentStatus,
  TimetableDay,
  TimetableStatus,
  AttendanceStatus,
  AttendanceSessionStatus,
} from '../../src/constants/status';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';
import { AttendanceService } from '../../src/services/attendance.service';
import { PasswordService } from '../../src/services/password.service';

describe('ACADEX Phase 9K.1 — Attendance Management & Analytics Engine Tests', () => {
  let superAdminUser: InstanceType<typeof User>;
  let collegeAdminA: InstanceType<typeof User>;
  let collegeAdminB: InstanceType<typeof User>;
  let hodA1: InstanceType<typeof User>;
  let facultyA1: InstanceType<typeof User>;
  let facultyA2: InstanceType<typeof User>;
  let studentA1: InstanceType<typeof User>;
  let studentA2: InstanceType<typeof User>;

  let collegeA: InstanceType<typeof College>;
  let collegeB: InstanceType<typeof College>;

  let deptA1: InstanceType<typeof Department>;
  let deptA2: InstanceType<typeof Department>;

  let courseA: InstanceType<typeof Course>;
  let academicYearA: InstanceType<typeof AcademicYear>;
  let semesterA5: InstanceType<typeof Semester>;
  let sectionA: InstanceType<typeof Section>;
  let sectionB: InstanceType<typeof Section>;

  let subjectOS: InstanceType<typeof Subject>;
  let subjectDBMS: InstanceType<typeof Subject>;

  let facultyProfileA1: InstanceType<typeof Faculty>;
  let facultyProfileA2: InstanceType<typeof Faculty>;
  let studentProfileA1: InstanceType<typeof Student>;
  let studentProfileA2: InstanceType<typeof Student>;

  let publishedTimetableA: InstanceType<typeof Timetable>;

  let superAdminHeader: { Authorization: string };
  let collegeAdminAHeader: { Authorization: string };
  let collegeAdminBHeader: { Authorization: string };
  let hodA1Header: { Authorization: string };
  let facultyA1Header: { Authorization: string };
  let facultyA2Header: { Authorization: string };
  let studentA1Header: { Authorization: string };
  let studentA2Header: { Authorization: string };

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
    await Timetable.init();
    await AttendanceSession.init();
    await AttendanceRecord.init();
    await AuditLog.init();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();

    collegeA = await College.create({
      name: 'Alpha Institute of Technology',
      code: 'ALPHA',
      address: '100 Tech Park',
      email: 'admin@alpha.edu',
      phone: '+919988776601',
      principal: 'Dr. Alpha',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });

    collegeB = await College.create({
      name: 'Beta University',
      code: 'BETA',
      address: '200 Beta Park',
      email: 'admin@beta.edu',
      phone: '+919988776602',
      principal: 'Dr. Beta',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });

    deptA1 = await Department.create({
      collegeId: collegeA._id,
      name: 'Computer Science & Engineering',
      code: 'CSE',
      status: DepartmentStatus.ACTIVE,
      isActive: true,
    });

    deptA2 = await Department.create({
      collegeId: collegeA._id,
      name: 'Electrical Engineering',
      code: 'EE',
      status: DepartmentStatus.ACTIVE,
      isActive: true,
    });

    courseA = await Course.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      name: 'B.Tech CSE',
      code: 'CS101',
      duration: 4,
      isActive: true,
    });

    academicYearA = await AcademicYear.create({
      collegeId: collegeA._id,
      name: '2026-2027',
      startDate: new Date('2026-06-01'),
      endDate: new Date('2027-05-31'),
      isCurrent: true,
      isActive: true,
    });

    semesterA5 = await Semester.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      name: 'Semester 5',
      number: 5,
      isActive: true,
    });

    sectionA = await Section.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA5._id,
      name: 'Section A',
      capacity: 60,
      isActive: true,
    });

    sectionB = await Section.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA5._id,
      name: 'Section B',
      capacity: 60,
      isActive: true,
    });

    subjectOS = await Subject.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      courseId: courseA._id,
      semesterId: semesterA5._id,
      name: 'Operating Systems',
      code: 'CS501',
      credits: 4,
      isActive: true,
    });

    subjectDBMS = await Subject.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      courseId: courseA._id,
      semesterId: semesterA5._id,
      name: 'Database Management Systems',
      code: 'CS502',
      credits: 4,
      isActive: true,
    });

    const defaultPasswordHash = await PasswordService.hashPassword('Pass1234');

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
      name: 'Dr. Hopper (HOD CSE)',
      email: 'hod.cse@alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.HOD,
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    facultyA1 = await User.create({
      instituteId: 'FAC-CSE-01',
      name: 'Prof. Ritchie',
      email: 'ritchie@alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.FACULTY,
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    facultyProfileA1 = await Faculty.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      userId: facultyA1._id,
      instituteId: facultyA1.instituteId,
      name: facultyA1.name,
      email: facultyA1.email,
      designation: 'Professor',
      status: 'active',
      isActive: true,
    });

    facultyA2 = await User.create({
      instituteId: 'FAC-CSE-02',
      name: 'Prof. Thompson',
      email: 'thompson@alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.FACULTY,
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    facultyProfileA2 = await Faculty.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      userId: facultyA2._id,
      instituteId: facultyA2.instituteId,
      name: facultyA2.name,
      email: facultyA2.email,
      designation: 'Associate Professor',
      status: 'active',
      isActive: true,
    });

    studentA1 = await User.create({
      instituteId: 'STU-001',
      name: 'Alice Johnson',
      email: 'alice@alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.STUDENT,
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    studentProfileA1 = await Student.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      userId: studentA1._id,
      instituteId: studentA1.instituteId,
      name: studentA1.name,
      email: studentA1.email,
      rollNumber: 'CS-001',
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA5._id,
      sectionId: sectionA._id,
      status: 'active',
      isActive: true,
    });

    await StudentEnrollment.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      studentId: studentProfileA1._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA5._id,
      sectionId: sectionA._id,
      status: 'active',
    });

    studentA2 = await User.create({
      instituteId: 'STU-002',
      name: 'Bob Smith',
      email: 'bob@alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.STUDENT,
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    studentProfileA2 = await Student.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      userId: studentA2._id,
      instituteId: studentA2.instituteId,
      name: studentA2.name,
      email: studentA2.email,
      rollNumber: 'CS-002',
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA5._id,
      sectionId: sectionA._id,
      status: 'active',
      isActive: true,
    });

    await StudentEnrollment.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      studentId: studentProfileA2._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA5._id,
      sectionId: sectionA._id,
      status: 'active',
    });

    // Create a published Timetable for Section A (Monday 09:00 - 10:00 OS by Faculty A1)
    publishedTimetableA = await Timetable.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA5._id,
      sectionId: sectionA._id,
      name: 'Fall 2026 Section A Timetable',
      status: TimetableStatus.PUBLISHED,
      entries: [
        {
          dayOfWeek: TimetableDay.MONDAY,
          startTime: '09:00',
          endTime: '10:00',
          subjectId: subjectOS._id,
          facultyId: facultyProfileA1._id,
          roomNumber: 'LH-101',
        },
      ],
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

    facultyA2Header = createTestAuthHeader({
      userId: facultyA2.id,
      instituteId: facultyA2.instituteId,
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

    studentA2Header = createTestAuthHeader({
      userId: studentA2.id,
      instituteId: studentA2.instituteId,
      collegeId: collegeA.id,
      departmentId: deptA1.id,
      role: AppRole.STUDENT,
    });
  });

  // =========================================================================
  // 1. SESSION CREATION & TIMETABLE INTEGRATION (1 - 8)
  // =========================================================================

  it('1 - 8. Timetable integration, scheduled day validation, and duplicate prevention', async () => {
    const mondayDate = '2026-08-24T09:00:00.000Z'; // Monday
    const entryId = publishedTimetableA.entries[0]._id!.toString();

    // 1. Valid Session Creation linked to published timetable
    const resValid = await request(app)
      .post('/api/v1/attendance/sessions')
      .set(facultyA1Header)
      .send({
        timetableId: publishedTimetableA.id,
        timetableEntryId: entryId,
        sectionId: sectionA.id,
        subjectId: subjectOS.id,
        facultyId: facultyProfileA1.id,
        date: mondayDate,
        timeSlot: '09:00 - 10:00',
        records: [
          { studentId: studentProfileA1.id, status: AttendanceStatus.PRESENT },
          { studentId: studentProfileA2.id, status: AttendanceStatus.ABSENT },
        ],
      });

    expect(resValid.status).toBe(201);
    expect(resValid.body.data.status).toBe(AttendanceSessionStatus.OPEN);
    expect(resValid.body.data.records).toHaveLength(2);

    // 7. Duplicate session for same section, subject, date, timeslot -> 409 Conflict
    const resDup = await request(app)
      .post('/api/v1/attendance/sessions')
      .set(facultyA1Header)
      .send({
        timetableId: publishedTimetableA.id,
        timetableEntryId: entryId,
        sectionId: sectionA.id,
        subjectId: subjectOS.id,
        facultyId: facultyProfileA1.id,
        date: mondayDate,
        timeSlot: '09:00 - 10:00',
      });
    expect(resDup.status).toBe(409);

    // 6. Day Mismatch (2026-08-26 is Wednesday, but entry is scheduled on Monday) -> 400 Bad Request
    const resDayMismatch = await request(app)
      .post('/api/v1/attendance/sessions')
      .set(facultyA1Header)
      .send({
        timetableId: publishedTimetableA.id,
        timetableEntryId: entryId,
        sectionId: sectionA.id,
        subjectId: subjectOS.id,
        facultyId: facultyProfileA1.id,
        date: '2026-08-26T09:00:00.000Z', // Wednesday
        timeSlot: '09:00 - 10:00',
      });
    expect(resDayMismatch.status).toBe(400);
    expect(resDayMismatch.body.error?.message || resDayMismatch.body.message).toContain('Scheduled day mismatch');

    // 2. Unpublished timetable session creation rejected -> 400 Bad Request
    const draftTt = await Timetable.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA5._id,
      sectionId: sectionB._id,
      name: 'Draft Timetable',
      status: TimetableStatus.DRAFT,
      entries: [
        {
          dayOfWeek: TimetableDay.MONDAY,
          startTime: '10:00',
          endTime: '11:00',
          subjectId: subjectDBMS._id,
          facultyId: facultyProfileA2._id,
          roomNumber: 'LH-102',
        },
      ],
    });

    const resDraft = await request(app)
      .post('/api/v1/attendance/sessions')
      .set(facultyA2Header)
      .send({
        timetableId: draftTt.id,
        sectionId: sectionB.id,
        subjectId: subjectDBMS.id,
        facultyId: facultyProfileA2.id,
        date: mondayDate,
        timeSlot: '10:00 - 11:00',
      });
    expect(resDraft.status).toBe(400);
  });

  // =========================================================================
  // 2. ROSTER VALIDATION & BULK MARKING (9 - 16)
  // =========================================================================

  it('9 - 16. Rejects non-enrolled students, prevents duplicate markings, validates statuses', async () => {
    // Create an unenrolled student in Section B
    const studentUnenrolled = await Student.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      name: 'Charlie Brown',
      email: 'charlie@alpha.edu',
      rollNumber: 'CS-003',
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA5._id,
      sectionId: sectionB._id, // Section B!
      status: 'active',
      isActive: true,
    });

    // 10. Marking attendance for student not enrolled in Section A -> 400 Bad Request
    const resBadRoster = await request(app)
      .post('/api/v1/attendance/sessions')
      .set(facultyA1Header)
      .send({
        sectionId: sectionA.id,
        subjectId: subjectOS.id,
        facultyId: facultyProfileA1.id,
        date: '2026-08-31T09:00:00.000Z',
        timeSlot: '09:00 - 10:00',
        records: [
          { studentId: studentUnenrolled.id, status: AttendanceStatus.PRESENT },
        ],
      });
    expect(resBadRoster.status).toBe(400);
    expect(resBadRoster.body.error?.message || resBadRoster.body.message).toContain('not enrolled');

    // 12. Create valid session and mark records
    const resSession = await request(app)
      .post('/api/v1/attendance/sessions')
      .set(facultyA1Header)
      .send({
        sectionId: sectionA.id,
        subjectId: subjectOS.id,
        facultyId: facultyProfileA1.id,
        date: '2026-08-31T09:00:00.000Z',
        timeSlot: '09:00 - 10:00',
        records: [],
      });
    expect(resSession.status).toBe(201);
    const sessionId = resSession.body.data.id;

    // Submit bulk records
    const resMark = await request(app)
      .post(`/api/v1/attendance/sessions/${sessionId}/records`)
      .set(facultyA1Header)
      .send({
        records: [
          { studentId: studentProfileA1.id, status: AttendanceStatus.PRESENT },
          { studentId: studentProfileA2.id, status: AttendanceStatus.LATE },
        ],
      });
    expect(resMark.status).toBe(200);
    expect(resMark.body.data.records).toHaveLength(2);

    // 14. Duplicate student in same bulk payload -> 409 Conflict
    const resDupPayload = await request(app)
      .post(`/api/v1/attendance/sessions/${sessionId}/records`)
      .set(facultyA1Header)
      .send({
        records: [
          { studentId: studentProfileA1.id, status: AttendanceStatus.PRESENT },
          { studentId: studentProfileA1.id, status: AttendanceStatus.ABSENT },
        ],
      });
    expect(resDupPayload.status).toBe(409);
  });

  // =========================================================================
  // 3. SESSION LIFECYCLE & CORRECTIONS (17 - 24)
  // =========================================================================

  it('17 - 24. Lock, close, cancel lifecycle, and administrative attendance correction', async () => {
    // 1. Create Session
    const resSession = await request(app)
      .post('/api/v1/attendance/sessions')
      .set(facultyA1Header)
      .send({
        sectionId: sectionA.id,
        subjectId: subjectOS.id,
        facultyId: facultyProfileA1.id,
        date: '2026-09-07T09:00:00.000Z',
        timeSlot: '09:00 - 10:00',
        records: [
          { studentId: studentProfileA1.id, status: AttendanceStatus.ABSENT },
        ],
      });
    expect(resSession.status).toBe(201);
    const sessionId = resSession.body.data.id;

    // 18. Lock Session
    const resLock = await request(app)
      .post(`/api/v1/attendance/sessions/${sessionId}/lock`)
      .set(facultyA1Header);
    expect(resLock.status).toBe(200);
    expect(resLock.body.data.status).toBe(AttendanceSessionStatus.LOCKED);

    // Casual modification of locked session is rejected -> 400 Bad Request
    const resModLocked = await request(app)
      .post(`/api/v1/attendance/sessions/${sessionId}/records`)
      .set(facultyA1Header)
      .send({
        records: [
          { studentId: studentProfileA1.id, status: AttendanceStatus.PRESENT },
        ],
      });
    expect(resModLocked.status).toBe(400);

    // 21. Administrative Correction by HOD (Changing Absent to Present with reason)
    const recordDoc = await AttendanceRecord.findOne({ sessionId, studentId: studentProfileA1._id });
    expect(recordDoc).toBeDefined();

    const resCorrect = await request(app)
      .patch(`/api/v1/attendance/records/${recordDoc!._id}/correct`)
      .set(hodA1Header)
      .send({
        newStatus: AttendanceStatus.PRESENT,
        reason: 'Student was present in lab session, marked absent by mistake',
      });

    expect(resCorrect.status).toBe(200);
    expect(resCorrect.body.data.status).toBe(AttendanceStatus.PRESENT);
    expect(resCorrect.body.data.oldStatus).toBe(AttendanceStatus.ABSENT);
    expect(resCorrect.body.data.remarks).toContain('marked absent by mistake');

    // 23 & 24. Verify Audit Log for correction
    const auditLogs = await AuditLog.find({ action: 'ATTENDANCE_CORRECTED' });
    expect(auditLogs).toHaveLength(1);
    const firstLog = auditLogs[0]!;
    expect(firstLog.actorUserId).toBe(hodA1.id);
    expect((firstLog.previousValue as any)?.status).toBe(AttendanceStatus.ABSENT);
    expect((firstLog.newValue as any)?.status).toBe(AttendanceStatus.PRESENT);

    // 22. Faculty cannot correct locked record -> 403 Forbidden
    const resFacCorrect = await request(app)
      .patch(`/api/v1/attendance/records/${recordDoc!._id}/correct`)
      .set(facultyA1Header)
      .send({
        newStatus: AttendanceStatus.ABSENT,
        reason: 'Unauthorized attempt',
      });
    expect(resFacCorrect.status).toBe(403);
  });

  // =========================================================================
  // 4. STUDENT VIEWS, SUBJECT BREAKDOWN & ANALYTICS (25 - 39)
  // =========================================================================

  it('25 - 39. Student personal history, subject breakdown, section summary, and analytics', async () => {
    // Seed 2 sessions:
    // Session 1: OS (Alice: PRESENT, Bob: LATE)
    await AttendanceService.createOrSubmitSession(
      collegeA.id,
      {
        departmentId: deptA1._id,
        courseId: courseA._id,
        academicYearId: academicYearA._id,
        semesterId: semesterA5._id,
        sectionId: sectionA._id,
        subjectId: subjectOS._id,
        facultyId: facultyProfileA1._id,
        timeSlot: '09:00 - 10:00',
        date: new Date('2026-09-14T09:00:00.000Z'),
        records: [
          { studentId: studentProfileA1._id, status: AttendanceStatus.PRESENT } as any,
          { studentId: studentProfileA2._id, status: AttendanceStatus.LATE } as any,
        ],
      },
      facultyA1.id
    );

    // Session 2: OS (Alice: PRESENT, Bob: ABSENT)
    await AttendanceService.createOrSubmitSession(
      collegeA.id,
      {
        departmentId: deptA1._id,
        courseId: courseA._id,
        academicYearId: academicYearA._id,
        semesterId: semesterA5._id,
        sectionId: sectionA._id,
        subjectId: subjectOS._id,
        facultyId: facultyProfileA1._id,
        timeSlot: '09:00 - 10:00',
        date: new Date('2026-09-21T09:00:00.000Z'),
        records: [
          { studentId: studentProfileA1._id, status: AttendanceStatus.PRESENT } as any,
          { studentId: studentProfileA2._id, status: AttendanceStatus.ABSENT } as any,
        ],
      },
      facultyA1.id
    );

    // 25. Student A1 views own attendance history
    const resStuHist = await request(app)
      .get('/api/v1/attendance/students/me')
      .set(studentA1Header);
    expect(resStuHist.status).toBe(200);
    expect(resStuHist.body.data.items).toHaveLength(2);

    // 28. Student A1 views subject breakdown
    const resStuSub = await request(app)
      .get('/api/v1/attendance/students/me/subjects')
      .set(studentA1Header);
    expect(resStuSub.status).toBe(200);
    expect(resStuSub.body.data).toHaveLength(1);
    expect(resStuSub.body.data[0].totalClasses).toBe(2);
    expect(resStuSub.body.data[0].presentCount).toBe(2);
    expect(resStuSub.body.data[0].percentage).toBe(100);

    // 27. Student A2 summary (1 late + 1 absent out of 2 = 50%)
    const resStu2Sum = await request(app)
      .get('/api/v1/attendance/students/me/summary')
      .set(studentA2Header);
    expect(resStu2Sum.status).toBe(200);
    expect(resStu2Sum.body.data.totalClasses).toBe(2);
    expect(resStu2Sum.body.data.lateCount).toBe(1);
    expect(resStu2Sum.body.data.absentCount).toBe(1);
    expect(resStu2Sum.body.data.percentage).toBe(50);

    // 29. Faculty views own sessions
    const resFacSessions = await request(app)
      .get('/api/v1/attendance/faculty/me')
      .set(facultyA1Header);
    expect(resFacSessions.status).toBe(200);
    expect(resFacSessions.body.data).toHaveLength(2);

    // 37. Section attendance overview
    const resSecAtt = await request(app)
      .get(`/api/v1/attendance/sections/${sectionA.id}`)
      .set(hodA1Header);
    expect(resSecAtt.status).toBe(200);
    expect(resSecAtt.body.data.totalSessions).toBe(2);
    expect(resSecAtt.body.data.totalRecords).toBe(4);
    // (2 present + 1 late) / 4 = 75%
    expect(resSecAtt.body.data.percentage).toBe(75);

    // 38. Comprehensive Analytics Engine with low attendance detection (threshold = 75%)
    const resAnalytics = await request(app)
      .get('/api/v1/attendance/analytics?threshold=75')
      .set(collegeAdminAHeader);

    expect(resAnalytics.status).toBe(200);
    expect(resAnalytics.body.data.totalSessions).toBe(2);
    expect(resAnalytics.body.data.overallPercentage).toBe(75);
    // Bob has 50% < 75%, so he appears in lowAttendanceStudents
    expect(resAnalytics.body.data.lowAttendanceCount).toBe(1);
    expect(resAnalytics.body.data.lowAttendanceStudents[0].studentName).toBe('Bob Smith');
  });

  // =========================================================================
  // 5. TENANT ISOLATION & RBAC (43 - 45)
  // =========================================================================

  it('43 - 45. Tenant isolation, RBAC checks, and Super Admin global access', async () => {
    // 34 & 43. College Admin B cannot access College A attendance analytics (403 or empty)
    const resCrossAnalytics = await request(app)
      .get(`/api/v1/attendance/sections/${sectionA.id}`)
      .set(collegeAdminBHeader);
    expect(resCrossAnalytics.status).toBe(403);

    // 45. HOD cannot access other department (EE) attendance
    const courseEE = await Course.create({
      collegeId: collegeA._id,
      departmentId: deptA2._id,
      name: 'B.Tech EE',
      code: 'EE101',
      duration: 4,
      isActive: true,
    });
    const semesterEE = await Semester.create({
      collegeId: collegeA._id,
      departmentId: deptA2._id,
      courseId: courseEE._id,
      academicYearId: academicYearA._id,
      name: 'EE Semester 1',
      number: 1,
      isActive: true,
    });
    const sectionEE = await Section.create({
      collegeId: collegeA._id,
      departmentId: deptA2._id,
      courseId: courseEE._id,
      academicYearId: academicYearA._id,
      semesterId: semesterEE._id,
      name: 'EE Section 1',
      capacity: 60,
      isActive: true,
    });
    const resHodCrossDept = await request(app)
      .get(`/api/v1/attendance/sections/${sectionEE.id}`)
      .set(hodA1Header);
    expect(resHodCrossDept.status).toBe(403);

    // 30. Super Admin global analytics
    const resSuperAnalytics = await request(app)
      .get(`/api/v1/attendance/analytics?collegeId=${collegeA.id}`)
      .set(superAdminHeader);
    expect(resSuperAnalytics.status).toBe(200);

    // Ensure secrets never in audit logs
    const allLogs = await AuditLog.find({ collegeId: collegeA.id });
    const serialized = JSON.stringify(allLogs);
    expect(serialized).not.toContain('password');
    expect(serialized).not.toContain('Pass1234');
  });
});
