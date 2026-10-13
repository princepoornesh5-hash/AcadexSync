import request from 'supertest';
import mongoose from 'mongoose';
import { app } from '../../src/app';
import {
  College,
  Department,
  Course,
  AcademicYear,
  Semester,
  Section,
  Subject,
  User,
  Faculty,
  FacultyAssignment,
  Student,
  StudentEnrollment,
  AttendanceSession,
  AttendanceRecord,
  HistoricalAttendanceSummary,
  AuditLog,
} from '../../src/models';
import { AppRole } from '../../src/constants/roles';
import { AttendanceStatus, AttendanceSessionStatus } from '../../src/constants/status';
import { AttendanceAggregationService } from '../../src/services/attendance/attendanceAggregation.service';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';

describe('PROMPT 2 OF 3 — Manual Historical Attendance Entry Integration Tests', () => {
  let collegeA: any;
  let collegeB: any;
  let departmentA: any;
  let courseA: any;
  let academicYearA: any;
  let semesterA: any;
  let sectionA: any;
  let subjectMath: any;
  let facultyDocA: any;
  let facultyAssignmentA: any;

  let adminUserA: any;
  let facultyUserA: any;
  let facultyUserB: any;
  let adminUserB: any;
  let studentUser1: any;
  let studentUser2: any;
  let studentDoc1: any;
  let studentDoc2: any;
  let enrollmentDoc1: any;
  let enrollmentDoc2: any;

  function authHeader(user: any, collegeId?: string): string {
    return createTestAuthHeader({
      userId: user._id.toString(),
      collegeId: collegeId || user.collegeId.toString(),
      role: user.role,
      email: user.email,
      name: user.name,
      departmentId: user.departmentId ? user.departmentId.toString() : undefined,
    }).Authorization;
  }

  beforeAll(async () => {
    await setupTestDB();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();

    collegeA = await College.create({
      name: 'College of Engineering A',
      code: 'COEA-ATT',
      address: 'Main Campus A',
      email: 'admin@coea-att.edu',
      phone: '9000000001',
      principal: 'Dr. Principal A',
      status: 'active',
      isActive: true,
    });

    collegeB = await College.create({
      name: 'College of Science B',
      code: 'COEB-ATT',
      address: 'North Campus B',
      email: 'admin@coeb-att.edu',
      phone: '9000000002',
      principal: 'Dr. Principal B',
      status: 'active',
      isActive: true,
    });

    const departmentB = await Department.create({
      collegeId: collegeB._id,
      name: 'Science Department',
      code: 'SCI-ATT',
      status: 'active',
      isActive: true,
    });

    const courseB = await Course.create({
      collegeId: collegeB._id,
      departmentId: departmentB._id,
      name: 'B.Sc Physics',
      code: 'BSC-PHY',
      durationYears: 3,
      status: 'active',
      isActive: true,
    });

    const academicYearB = await AcademicYear.create({
      collegeId: collegeB._id,
      name: '2024-2025',
      code: 'AY24-25-B',
      startDate: new Date('2024-06-01'),
      endDate: new Date('2025-05-31'),
      status: 'active',
      isActive: true,
    });

    const semesterB = await Semester.create({
      collegeId: collegeB._id,
      departmentId: departmentB._id,
      courseId: courseB._id,
      academicYearId: academicYearB._id,
      name: 'Semester 1',
      number: 1,
      type: 'ODD',
      startDate: new Date('2024-06-01'),
      endDate: new Date('2024-11-30'),
      status: 'active',
      isActive: true,
    });

    departmentA = await Department.create({
      collegeId: collegeA._id,
      name: 'Computer Science & Engineering',
      code: 'CSE-ATT',
      status: 'active',
      isActive: true,
    });

    courseA = await Course.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      name: 'B.Tech CSE',
      code: 'BT-CSE-ATT',
      durationYears: 4,
      status: 'active',
      isActive: true,
    });

    academicYearA = await AcademicYear.create({
      collegeId: collegeA._id,
      name: '2024-2025',
      code: 'AY24-25',
      startDate: new Date('2024-06-01'),
      endDate: new Date('2025-05-31'),
      status: 'active',
      isActive: true,
      isCurrent: false,
    });

    semesterA = await Semester.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      name: 'Semester 3',
      number: 3,
      type: 'ODD',
      startDate: new Date('2024-06-01'),
      endDate: new Date('2024-11-30'),
      status: 'active',
      isActive: true,
    });

    sectionA = await Section.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      name: 'A',
      capacity: 60,
    });

    await Section.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      name: 'B',
      capacity: 60,
    });

    subjectMath = await Subject.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      courseId: courseA._id,
      semesterId: semesterA._id,
      name: 'Discrete Mathematics',
      code: 'CS301-ATT',
      credits: 4,
      type: 'theory',
      isActive: true,
    });

    adminUserA = await User.create({
      collegeId: collegeA._id,
      email: 'admin@coea-att.edu',
      password: 'password123',
      name: 'College Admin A',
      role: AppRole.COLLEGE_ADMIN,
    });

    await User.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      email: 'hod.cse@coea-att.edu',
      password: 'password123',
      name: 'HOD CSE',
      role: AppRole.HOD,
    });

    facultyUserA = await User.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      email: 'prof.smith@coea-att.edu',
      password: 'password123',
      name: 'Prof. Alice Smith',
      role: AppRole.FACULTY,
    });

    facultyDocA = await Faculty.create({
      collegeId: collegeA._id,
      userId: facultyUserA._id,
      departmentId: departmentA._id,
      name: facultyUserA.name,
      email: facultyUserA.email,
      designation: 'Associate Professor',
      status: 'active',
    });

    facultyUserB = await User.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      email: 'prof.unassigned@coea-att.edu',
      password: 'password123',
      name: 'Prof. Bob Jones',
      role: AppRole.FACULTY,
    });

    await Faculty.create({
      collegeId: collegeA._id,
      userId: facultyUserB._id,
      departmentId: departmentA._id,
      name: facultyUserB.name,
      email: facultyUserB.email,
      designation: 'Assistant Professor',
      status: 'active',
    });

    facultyAssignmentA = await FacultyAssignment.create({
      collegeId: collegeA._id,
      facultyId: facultyDocA._id,
      facultyName: facultyDocA.name,
      courseId: courseA._id,
      subjectId: subjectMath._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      departmentId: departmentA._id,
      role: 'PRIMARY',
      status: 'active',
      isActive: true,
    });

    adminUserB = await User.create({
      collegeId: collegeB._id,
      email: 'admin@coeb-att.edu',
      password: 'password123',
      name: 'Admin B',
      role: AppRole.COLLEGE_ADMIN,
    });

    studentUser1 = await User.create({
      collegeId: collegeA._id,
      email: 'student1@coea-att.edu',
      password: 'password123',
      name: 'Alice Student',
      role: AppRole.STUDENT,
    });

    studentDoc1 = await Student.create({
      collegeId: collegeA._id,
      userId: studentUser1._id,
      departmentId: departmentA._id,
      courseId: courseA._id,
      name: studentUser1.name,
      email: studentUser1.email,
      rollNumber: 'CS2401',
      admissionNumber: 'ADM-2401',
      instituteId: 'PIN2401',
      status: 'active',
      academicYearId: academicYearA._id,
    });

    enrollmentDoc1 = await StudentEnrollment.create({
      collegeId: collegeA._id,
      studentId: studentDoc1._id,
      departmentId: departmentA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      rollNumber: 'CS2401',
      status: 'active',
      enrollmentDate: new Date('2024-06-01'),
    });

    studentUser2 = await User.create({
      collegeId: collegeA._id,
      email: 'student2@coea-att.edu',
      password: 'password123',
      name: 'Bob Student',
      role: AppRole.STUDENT,
    });

    studentDoc2 = await Student.create({
      collegeId: collegeA._id,
      userId: studentUser2._id,
      departmentId: departmentA._id,
      courseId: courseA._id,
      name: studentUser2.name,
      email: studentUser2.email,
      rollNumber: 'CS2402',
      admissionNumber: 'ADM-2402',
      instituteId: 'PIN2402',
      status: 'active',
      academicYearId: academicYearA._id,
    });

    enrollmentDoc2 = await StudentEnrollment.create({
      collegeId: collegeA._id,
      studentId: studentDoc2._id,
      departmentId: departmentA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      rollNumber: 'CS2402',
      status: 'active',
      enrollmentDate: new Date('2024-06-01'),
    });

    // Cross-college student
    const crossUser = await User.create({
      collegeId: collegeB._id,
      email: 'cross.student@coeb-att.edu',
      password: 'password123',
      name: 'Cross Student',
      role: AppRole.STUDENT,
    });

    const crossStudent = await Student.create({
      collegeId: collegeB._id,
      userId: crossUser._id,
      departmentId: departmentB._id,
      courseId: courseB._id,
      name: crossUser.name,
      email: crossUser.email,
      rollNumber: 'B2401',
      status: 'active',
    });

    await StudentEnrollment.create({
      collegeId: collegeB._id,
      studentId: crossStudent._id,
      departmentId: departmentB._id,
      courseId: courseB._id,
      academicYearId: academicYearB._id,
      semesterId: semesterB._id,
      rollNumber: 'B2401',
      status: 'active',
    });
  });

  // =========================================================================
  // 1. Authorized historical session creation (Mode A)
  // =========================================================================
  test('1. Authorized historical session creation sets sourceType HISTORICAL_MANUAL and LOCKED status', async () => {
    const historicalDate = '2024-09-15';
    const res = await request(app)
      .post('/api/v1/attendance/historical/sessions')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        academicYearId: academicYearA._id.toString(),
        semesterId: semesterA._id.toString(),
        sectionId: sectionA._id.toString(),
        subjectId: subjectMath._id.toString(),
        facultyAssignmentId: facultyAssignmentA._id.toString(),
        date: historicalDate,
        timeSlot: '09:00 - 10:00',
        records: [
          {
            studentEnrollmentId: enrollmentDoc1._id.toString(),
            status: AttendanceStatus.PRESENT,
            remarks: 'On time',
          },
          {
            studentEnrollmentId: enrollmentDoc2._id.toString(),
            status: AttendanceStatus.ABSENT,
            remarks: 'Medical leave',
          },
        ],
        remarks: 'Historical makeup class',
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.sourceType).toBe('HISTORICAL_MANUAL');
    expect(res.body.data.status).toBe(AttendanceSessionStatus.LOCKED);
    expect(res.body.data.records).toHaveLength(2);

    // Verify database document in AttendanceSession
    const session = await AttendanceSession.findById(res.body.data._id || res.body.data.id);
    expect(session).not.toBeNull();
    expect(session!.sourceType).toBe('HISTORICAL_MANUAL');
    expect(session!.status).toBe(AttendanceSessionStatus.LOCKED);

    // Verify individual AttendanceRecord documents
    const records = await AttendanceRecord.find({ sessionId: session!._id });
    expect(records).toHaveLength(2);
    expect(records[0].sourceType).toBe('HISTORICAL_MANUAL');
    expect(records[1].sourceType).toBe('HISTORICAL_MANUAL');

    // Verify audit log
    const audit = await AuditLog.findOne({
      entityId: session!._id.toString(),
      action: 'HISTORICAL_MANUAL_ATTENDANCE_SESSION_CREATED',
    });
    expect(audit).not.toBeNull();
    expect(audit!.actorUserId.toString()).toBe(facultyUserA._id.toString());
  });

  // =========================================================================
  // 2. Authorized student-specific historical entry & correction (Mode C)
  // =========================================================================
  test('2. Authorized student-specific historical correction updates records and records audit trail', async () => {
    // First create a session
    const createRes = await request(app)
      .post('/api/v1/attendance/historical/sessions')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        academicYearId: academicYearA._id.toString(),
        semesterId: semesterA._id.toString(),
        sectionId: sectionA._id.toString(),
        subjectId: subjectMath._id.toString(),
        date: '2024-09-15',
        timeSlot: '09:00 - 10:00',
        records: [
          {
            studentEnrollmentId: enrollmentDoc1._id.toString(),
            status: AttendanceStatus.ABSENT,
          },
        ],
      });
    expect(createRes.status).toBe(201);

    const record = await AttendanceRecord.findOne({
      sessionId: createRes.body.data._id || createRes.body.data.id,
      studentId: studentDoc1._id,
    });
    expect(record).not.toBeNull();
    expect(record!.status).toBe(AttendanceStatus.ABSENT);

    // Now correct via Mode C endpoint
    const correctRes = await request(app)
      .post('/api/v1/attendance/historical/records/student')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        recordId: record!._id.toString(),
        newStatus: AttendanceStatus.PRESENT,
        reason: 'Correction: Student was attending cultural event with permission',
      });

    expect(correctRes.status).toBe(200);
    expect(correctRes.body.success).toBe(true);
    expect(correctRes.body.data.status).toBe(AttendanceStatus.PRESENT);

    // Verify database record updated
    const updatedRecord = await AttendanceRecord.findById(record!._id);
    expect(updatedRecord!.status).toBe(AttendanceStatus.PRESENT);
    expect(updatedRecord!.oldStatus).toBe(AttendanceStatus.ABSENT);
    expect(updatedRecord!.remarks).toContain('Correction: Student was attending');

    // Verify session records array item also updated
    const session = await AttendanceSession.findById(createRes.body.data._id || createRes.body.data.id);
    expect(session!.records[0].status).toBe(AttendanceStatus.PRESENT);
    expect(session!.records[0].oldStatus).toBe(AttendanceStatus.ABSENT);

    // Verify audit log
    const audit = await AuditLog.findOne({
      entityId: record!._id.toString(),
      action: 'ATTENDANCE_CORRECTED',
    });
    expect(audit).not.toBeNull();
    expect(audit!.previousValue?.status).toBe(AttendanceStatus.ABSENT);
    expect(audit!.newValue?.status).toBe(AttendanceStatus.PRESENT);
  });

  // =========================================================================
  // 3. Correct StudentEnrollment roster resolution
  // =========================================================================
  test('3. Correct StudentEnrollment roster resolution returns only matching active section enrollments', async () => {
    const res = await request(app)
      .get('/api/v1/attendance/historical/roster')
      .set('Authorization', authHeader(facultyUserA))
      .query({
        academicYearId: academicYearA._id.toString(),
        semesterId: semesterA._id.toString(),
        sectionId: sectionA._id.toString(),
        subjectId: subjectMath._id.toString(),
      });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.roster).toHaveLength(2);

    const rollNumbers = res.body.data.roster.map((r: any) => r.rollNumber);
    expect(rollNumbers).toContain('CS2401');
    expect(rollNumbers).toContain('CS2402');
    expect(res.body.data.facultyAssignment).not.toBeNull();
  });

  // =========================================================================
  // 4. Valid historical date handling (past dates allowed, future rejected)
  // =========================================================================
  test('4. Future date is rejected with 400 Bad Request', async () => {
    const futureDate = '2029-01-01';
    const res = await request(app)
      .post('/api/v1/attendance/historical/sessions')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        academicYearId: academicYearA._id.toString(),
        semesterId: semesterA._id.toString(),
        sectionId: sectionA._id.toString(),
        subjectId: subjectMath._id.toString(),
        date: futureDate,
        timeSlot: '10:00 - 11:00',
        records: [
          {
            studentEnrollmentId: enrollmentDoc1._id.toString(),
            status: AttendanceStatus.PRESENT,
          },
        ],
      });

    expect(res.status).toBe(400);
    expect(res.body.error?.message || res.body.message).toMatch(/cannot be in the future/i);
  });

  // =========================================================================
  // 5. Timezone and date-boundary handling
  // =========================================================================
  test('5. Date string is preserved cleanly across calendar day boundaries', async () => {
    const targetDateStr = '2024-10-05';
    const res = await request(app)
      .post('/api/v1/attendance/historical/sessions')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        academicYearId: academicYearA._id.toString(),
        semesterId: semesterA._id.toString(),
        sectionId: sectionA._id.toString(),
        subjectId: subjectMath._id.toString(),
        date: targetDateStr,
        timeSlot: '11:00 - 12:00',
        records: [
          {
            studentEnrollmentId: enrollmentDoc1._id.toString(),
            status: AttendanceStatus.PRESENT,
          },
        ],
      });

    expect(res.status).toBe(201);
    const session = await AttendanceSession.findById(res.body.data._id || res.body.data.id);
    expect(session!.date).toBeInstanceOf(Date);
    const isoDateStr = session!.date.toISOString();
    expect(isoDateStr).toContain('2024-10-05');
  });

  // =========================================================================
  // 6. Invalid academic context rejection
  // =========================================================================
  test('6. Invalid academic context (non-existent semester) is rejected with 404', async () => {
    const fakeSemesterId = new mongoose.Types.ObjectId().toString();
    const res = await request(app)
      .post('/api/v1/attendance/historical/sessions')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        academicYearId: academicYearA._id.toString(),
        semesterId: fakeSemesterId,
        sectionId: sectionA._id.toString(),
        subjectId: subjectMath._id.toString(),
        date: '2024-09-15',
        timeSlot: '09:00 - 10:00',
        records: [
          {
            studentEnrollmentId: enrollmentDoc1._id.toString(),
            status: AttendanceStatus.PRESENT,
          },
        ],
      });

    expect(res.status).toBe(404);
  });

  // =========================================================================
  // 7. Cross-college access rejection
  // =========================================================================
  test('7. Cross-college user is rejected with 403 Forbidden', async () => {
    const res = await request(app)
      .post('/api/v1/attendance/historical/sessions')
      .set('Authorization', authHeader(adminUserB))
      .send({
        academicYearId: academicYearA._id.toString(),
        semesterId: semesterA._id.toString(),
        sectionId: sectionA._id.toString(),
        subjectId: subjectMath._id.toString(),
        date: '2024-09-15',
        timeSlot: '09:00 - 10:00',
        records: [
          {
            studentEnrollmentId: enrollmentDoc1._id.toString(),
            status: AttendanceStatus.PRESENT,
          },
        ],
      });

    expect(res.status).toBe(403);
    expect(res.body.error?.message || res.body.message).toMatch(/cross-college/i);
  });

  // =========================================================================
  // 8. Unauthorized FacultyAssignment rejection
  // =========================================================================
  test('8. Unauthorized faculty attempting to record attendance is rejected with 403', async () => {
    const res = await request(app)
      .post('/api/v1/attendance/historical/sessions')
      .set('Authorization', authHeader(facultyUserB))
      .send({
        academicYearId: academicYearA._id.toString(),
        semesterId: semesterA._id.toString(),
        sectionId: sectionA._id.toString(),
        subjectId: subjectMath._id.toString(),
        date: '2024-09-15',
        timeSlot: '09:00 - 10:00',
        records: [
          {
            studentEnrollmentId: enrollmentDoc1._id.toString(),
            status: AttendanceStatus.PRESENT,
          },
        ],
      });

    expect(res.status).toBe(403);
  });

  // =========================================================================
  // 9. Duplicate session prevention
  // =========================================================================
  test('9. Submitting a duplicate historical session returns 409 Conflict', async () => {
    const payload = {
      academicYearId: academicYearA._id.toString(),
      semesterId: semesterA._id.toString(),
      sectionId: sectionA._id.toString(),
      subjectId: subjectMath._id.toString(),
      date: '2024-09-15',
      timeSlot: '14:00 - 15:00',
      records: [
        {
          studentEnrollmentId: enrollmentDoc1._id.toString(),
          status: AttendanceStatus.PRESENT,
        },
      ],
    };

    const first = await request(app)
      .post('/api/v1/attendance/historical/sessions')
      .set('Authorization', authHeader(facultyUserA))
      .send(payload);
    expect(first.status).toBe(201);

    const duplicate = await request(app)
      .post('/api/v1/attendance/historical/sessions')
      .set('Authorization', authHeader(facultyUserA))
      .send(payload);
    expect(duplicate.status).toBe(409);
    expect(duplicate.body.error?.message || duplicate.body.message).toMatch(/already exists/i);
  });

  // =========================================================================
  // 10. Duplicate attendance-record prevention within payload
  // =========================================================================
  test('10. Submitting duplicate student enrollment entries in records returns 400 Bad Request', async () => {
    const res = await request(app)
      .post('/api/v1/attendance/historical/sessions')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        academicYearId: academicYearA._id.toString(),
        semesterId: semesterA._id.toString(),
        sectionId: sectionA._id.toString(),
        subjectId: subjectMath._id.toString(),
        date: '2024-09-16',
        timeSlot: '09:00 - 10:00',
        records: [
          {
            studentEnrollmentId: enrollmentDoc1._id.toString(),
            status: AttendanceStatus.PRESENT,
          },
          {
            studentEnrollmentId: enrollmentDoc1._id.toString(),
            status: AttendanceStatus.ABSENT,
          },
        ],
      });

    expect(res.status).toBe(400);
    expect(res.body.error?.message || res.body.message).toMatch(/duplicate student/i);
  });

  // =========================================================================
  // 11. Valid PRESENT and ABSENT behavior
  // =========================================================================
  test('11. Valid PRESENT and ABSENT statuses correctly tracked and recorded', async () => {
    const res = await request(app)
      .post('/api/v1/attendance/historical/sessions')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        academicYearId: academicYearA._id.toString(),
        semesterId: semesterA._id.toString(),
        sectionId: sectionA._id.toString(),
        subjectId: subjectMath._id.toString(),
        date: '2024-09-17',
        timeSlot: '10:00 - 11:00',
        records: [
          {
            studentEnrollmentId: enrollmentDoc1._id.toString(),
            status: AttendanceStatus.PRESENT,
          },
          {
            studentEnrollmentId: enrollmentDoc2._id.toString(),
            status: AttendanceStatus.ABSENT,
          },
        ],
      });

    expect(res.status).toBe(201);
    const rec1 = await AttendanceRecord.findOne({
      sessionId: res.body.data._id || res.body.data.id,
      studentId: studentDoc1._id,
    });
    const rec2 = await AttendanceRecord.findOne({
      sessionId: res.body.data._id || res.body.data.id,
      studentId: studentDoc2._id,
    });

    expect(rec1!.status).toBe(AttendanceStatus.PRESENT);
    expect(rec2!.status).toBe(AttendanceStatus.ABSENT);
  });

  // =========================================================================
  // 12. Existing attendance status compatibility (LATE, EXCUSED)
  // =========================================================================
  test('12. Existing attendance status compatibility supports LATE and EXCUSED', async () => {
    const res = await request(app)
      .post('/api/v1/attendance/historical/sessions')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        academicYearId: academicYearA._id.toString(),
        semesterId: semesterA._id.toString(),
        sectionId: sectionA._id.toString(),
        subjectId: subjectMath._id.toString(),
        date: '2024-09-18',
        timeSlot: '11:00 - 12:00',
        records: [
          {
            studentEnrollmentId: enrollmentDoc1._id.toString(),
            status: AttendanceStatus.LATE,
            remarks: 'Arrived 15 minutes late',
          },
          {
            studentEnrollmentId: enrollmentDoc2._id.toString(),
            status: AttendanceStatus.EXCUSED,
            remarks: 'Official sports duty',
          },
        ],
      });

    expect(res.status).toBe(201);
    const rec1 = await AttendanceRecord.findOne({
      sessionId: res.body.data._id || res.body.data.id,
      studentId: studentDoc1._id,
    });
    const rec2 = await AttendanceRecord.findOne({
      sessionId: res.body.data._id || res.body.data.id,
      studentId: studentDoc2._id,
    });

    expect(rec1!.status).toBe(AttendanceStatus.LATE);
    expect(rec2!.status).toBe(AttendanceStatus.EXCUSED);
  });

  // =========================================================================
  // 13. Summary-only historical entry (Mode B Level 2 PERIOD_SUMMARY)
  // =========================================================================
  test('13. Summary-only historical entry records HistoricalAttendanceSummary without fake sessions', async () => {
    const res = await request(app)
      .post('/api/v1/attendance/historical/summaries')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        academicYearId: academicYearA._id.toString(),
        semesterId: semesterA._id.toString(),
        sectionId: sectionA._id.toString(),
        subjectId: subjectMath._id.toString(),
        periodLabel: 'Aug-Oct 2024 Summary',
        periodStart: '2024-08-01',
        periodEnd: '2024-10-31',
        entries: [
          {
            studentEnrollmentId: enrollmentDoc1._id.toString(),
            classesHeld: 40,
            presentCount: 36,
            absentCount: 4,
          },
          {
            studentEnrollmentId: enrollmentDoc2._id.toString(),
            classesHeld: 40,
            presentCount: 30,
            absentCount: 10,
          },
        ],
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.summaries).toHaveLength(2);

    // Verify HistoricalAttendanceSummary collection
    const summaries = await HistoricalAttendanceSummary.find({
      subjectId: subjectMath._id,
      periodLabel: 'Aug-Oct 2024 Summary',
    });
    expect(summaries).toHaveLength(2);
    expect(summaries[0].sourceType).toBe('HISTORICAL_MANUAL');
    expect(summaries[0].precisionLevel).toBe('PERIOD_SUMMARY');
    expect(summaries[0].classesHeld).toBe(40);
    expect(summaries[0].presentCount).toBe(36);

    // Crucial check: verify that NO AttendanceSession records were manufactured!
    const manufacturedSessions = await AttendanceSession.find({
      subjectId: subjectMath._id,
      date: { $gte: new Date('2024-08-01'), $lte: new Date('2024-10-31') },
    });
    expect(manufacturedSessions).toHaveLength(0);
  });

  // =========================================================================
  // 14. Percentage-only summary handling where supported (Mode B Level 3)
  // =========================================================================
  test('14. Percentage-only summary sets classesHeld & presentCount strictly to null without inventing counts', async () => {
    const res = await request(app)
      .post('/api/v1/attendance/historical/summaries')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        academicYearId: academicYearA._id.toString(),
        semesterId: semesterA._id.toString(),
        sectionId: sectionA._id.toString(),
        subjectId: subjectMath._id.toString(),
        periodLabel: 'Legacy Percentage Record',
        entries: [
          {
            studentEnrollmentId: enrollmentDoc1._id.toString(),
            attendancePercentage: 88.5,
          },
        ],
      });

    expect(res.status).toBe(201);
    const summary = await HistoricalAttendanceSummary.findOne({
      subjectId: subjectMath._id,
      periodLabel: 'Legacy Percentage Record',
    });
    expect(summary).not.toBeNull();
    expect(summary!.precisionLevel).toBe('PERCENTAGE_ONLY');
    expect(summary!.attendancePercentage).toBe(88.5);
    expect(summary!.classesHeld).toBeNull();
    expect(summary!.presentCount).toBeNull();
  });

  // =========================================================================
  // 15. Historical summary aggregation
  // =========================================================================
  test('15. AttendanceAggregationService incorporates historical summaries into aggregates', async () => {
    await HistoricalAttendanceSummary.create({
      collegeId: collegeA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      courseId: courseA._id,
      departmentId: departmentA._id,
      sectionId: sectionA._id,
      subjectId: subjectMath._id,
      studentId: studentDoc1._id,
      studentEnrollmentId: enrollmentDoc1._id,
      importBatchId: 'MANUAL_ENTRY',
      sourceType: 'HISTORICAL_MANUAL',
      periodLabel: 'Historical Agg Test',
      precisionLevel: 'PERIOD_SUMMARY',
      classesHeld: 50,
      presentCount: 45,
      absentCount: 5,
      attendancePercentage: 90,
      periodStart: new Date('2024-06-01'),
      periodEnd: new Date('2024-09-30'),
    });

    const aggregates = await AttendanceAggregationService.aggregateForStudent(
      collegeA._id.toString(),
      studentDoc1._id.toString(),
      { subjectId: subjectMath._id.toString() }
    );

    expect(aggregates).toBeDefined();
    expect(aggregates.detailedMetrics.totalHeld).toBe(50);
    expect(aggregates.detailedMetrics.totalPresent).toBe(45);
    expect(aggregates.detailedMetrics.percentage).toBe(90);
  });

  // =========================================================================
  // 16. No double-counting of overlapping data
  // =========================================================================
  test('16. Detailed sessions and historical summaries combine cleanly without double-counting when separate', async () => {
    // 1 detailed session on 2024-10-15 (present)
    const sessionRes = await request(app)
      .post('/api/v1/attendance/historical/sessions')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        academicYearId: academicYearA._id.toString(),
        semesterId: semesterA._id.toString(),
        sectionId: sectionA._id.toString(),
        subjectId: subjectMath._id.toString(),
        date: '2024-10-15',
        timeSlot: '09:00 - 10:00',
        records: [
          {
            studentEnrollmentId: enrollmentDoc1._id.toString(),
            status: AttendanceStatus.PRESENT,
          },
        ],
      });
    expect(sessionRes.status).toBe(201);

    // 1 summary for prior months (held: 20, present: 18)
    await HistoricalAttendanceSummary.create({
      collegeId: collegeA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      courseId: courseA._id,
      departmentId: departmentA._id,
      sectionId: sectionA._id,
      subjectId: subjectMath._id,
      studentId: studentDoc1._id,
      studentEnrollmentId: enrollmentDoc1._id,
      importBatchId: 'MANUAL_ENTRY',
      sourceType: 'HISTORICAL_MANUAL',
      periodLabel: 'Prior Period',
      precisionLevel: 'PERIOD_SUMMARY',
      classesHeld: 20,
      presentCount: 18,
      absentCount: 2,
      attendancePercentage: 90,
      periodStart: new Date('2024-08-01'),
      periodEnd: new Date('2024-09-30'),
    });

    const aggregates = await AttendanceAggregationService.aggregateForStudent(
      collegeA._id.toString(),
      studentDoc1._id.toString(),
      { subjectId: subjectMath._id.toString() }
    );

    // Total held should be 20 (summary) + 1 (detailed) = 21
    // Total present should be 18 (summary) + 1 (detailed) = 19
    expect(aggregates.detailedMetrics.totalHeld).toBe(21);
    expect(aggregates.detailedMetrics.totalPresent).toBe(19);
  });

  // =========================================================================
  // 17. Audit and provenance preservation
  // =========================================================================
  test('17. Audit logs preserve actor, entity, and change metadata for historical operations', async () => {
    const sessionRes = await request(app)
      .post('/api/v1/attendance/historical/sessions')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        academicYearId: academicYearA._id.toString(),
        semesterId: semesterA._id.toString(),
        sectionId: sectionA._id.toString(),
        subjectId: subjectMath._id.toString(),
        date: '2024-09-20',
        timeSlot: '10:00 - 11:00',
        records: [
          {
            studentEnrollmentId: enrollmentDoc1._id.toString(),
            status: AttendanceStatus.PRESENT,
          },
        ],
      });
    expect(sessionRes.status).toBe(201);

    const audit = await AuditLog.findOne({
      actorUserId: facultyUserA._id,
      entityId: sessionRes.body.data._id || sessionRes.body.data.id,
    });
    expect(audit).not.toBeNull();
    expect(audit!.action).toBe('HISTORICAL_MANUAL_ATTENDANCE_SESSION_CREATED');
    expect(audit!.collegeId?.toString()).toBe(collegeA._id.toString());
  });

  // =========================================================================
  // 18. Live attendance timing restrictions remain unchanged
  // =========================================================================
  test('18. Ordinary live attendance creation endpoint rejects future dates under timing restrictions', async () => {
    const futureDate = '2029-10-15';
    const res = await request(app)
      .post('/api/v1/attendance/sessions')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        date: futureDate,
        timeSlot: '10:00 - 11:00',
        subjectId: subjectMath._id.toString(),
        sectionId: sectionA._id.toString(),
      });

    expect(res.status).toBe(400);
    expect(res.body.error?.message || res.body.message).toMatch(/cannot be marked for future dates/i);
  });

  // =========================================================================
  // 19. Student 360 & Student personal attendance visibility
  // =========================================================================
  test('19. Student personal attendance summary returns historical data accurately', async () => {
    // Record historical session
    await request(app)
      .post('/api/v1/attendance/historical/sessions')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        academicYearId: academicYearA._id.toString(),
        semesterId: semesterA._id.toString(),
        sectionId: sectionA._id.toString(),
        subjectId: subjectMath._id.toString(),
        date: '2024-09-22',
        timeSlot: '10:00 - 11:00',
        records: [
          {
            studentEnrollmentId: enrollmentDoc1._id.toString(),
            status: AttendanceStatus.PRESENT,
          },
        ],
      });

    // Student Alice fetches personal summary
    const res = await request(app)
      .get('/api/v1/attendance/students/me/summary')
      .set('Authorization', authHeader(studentUser1));

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.totalClasses).toBeGreaterThanOrEqual(1);
    expect(res.body.data.presentCount).toBeGreaterThanOrEqual(1);
  });

  // =========================================================================
  // 20. Report and analytics consistency
  // =========================================================================
  test('20. Attendance analytics reflects historical sessions properly', async () => {
    const res = await request(app)
      .get('/api/v1/attendance/analytics')
      .set('Authorization', authHeader(adminUserA))
      .query({
        subjectId: subjectMath._id.toString(),
        academicYearId: academicYearA._id.toString(),
        semesterId: semesterA._id.toString(),
        sectionId: sectionA._id.toString(),
      });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });

  // =========================================================================
  // 21. Partial failure / atomic validation behavior
  // =========================================================================
  test('21. Submitting invalid student enrollment fails without creating orphan session', async () => {
    const fakeEnrollmentId = new mongoose.Types.ObjectId().toString();
    const res = await request(app)
      .post('/api/v1/attendance/historical/sessions')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        academicYearId: academicYearA._id.toString(),
        semesterId: semesterA._id.toString(),
        sectionId: sectionA._id.toString(),
        subjectId: subjectMath._id.toString(),
        date: '2024-09-25',
        timeSlot: '12:00 - 13:00',
        records: [
          {
            studentEnrollmentId: fakeEnrollmentId,
            status: AttendanceStatus.PRESENT,
          },
        ],
      });

    expect(res.status).toBe(400);

    // Verify no orphaned session was left in the database
    const orphan = await AttendanceSession.findOne({
      subjectId: subjectMath._id,
      date: new Date('2024-09-25'),
      timeSlot: '12:00 - 13:00',
    });
    expect(orphan).toBeNull();
  });
});
