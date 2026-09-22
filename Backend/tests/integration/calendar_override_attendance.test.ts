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
import { FacultyAssignment } from '../../src/models/facultyAssignment.model';
import { Room } from '../../src/models/room.model';
import { Timetable } from '../../src/models/timetable.model';
import { Student } from '../../src/models/student.model';
import { StudentEnrollment } from '../../src/models/studentEnrollment.model';
import { AttendanceSession } from '../../src/models/attendanceSession.model';
import { CalendarOverride, CalendarOverrideType, CalendarOverrideScope } from '../../src/models/calendarOverride.model';
import { AppRole } from '../../src/constants/roles';
import {
  CollegeStatus,
  DepartmentStatus,
  TimetableDay,
  TimetableStatus,
  TimetableBreakType,
  AccountStatus,
} from '../../src/constants/status';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';
import { PasswordService } from '../../src/services/password.service';

describe('ACADEX Timetable Module — Prompt 4 Calendar-Aware Execution & Holiday Overrides Tests', () => {
  let collegeA: InstanceType<typeof College>;
  let collegeB: InstanceType<typeof College>;
  let deptA: InstanceType<typeof Department>;
  let deptB: InstanceType<typeof Department>;
  let courseA: InstanceType<typeof Course>;
  let academicYearA: InstanceType<typeof AcademicYear>;
  let semesterA: InstanceType<typeof Semester>;
  let sectionA: InstanceType<typeof Section>;
  let subjectMath: InstanceType<typeof Subject>;
  let subjectPhysics: InstanceType<typeof Subject>;
  let facultyA: InstanceType<typeof Faculty>;
  let studentProfile: InstanceType<typeof Student>;
  let assignmentMathA: InstanceType<typeof FacultyAssignment>;
  let assignmentPhysicsA: InstanceType<typeof FacultyAssignment>;
  let publishedTimetableA: InstanceType<typeof Timetable>;
  let mondayEntryId: string;
  let tuesdayEntryId: string;
  let collegeAdminAUser: InstanceType<typeof User>;

  let superAdminHeader: { Authorization: string };
  let collegeAdminAHeader: { Authorization: string };
  let hodAHeader: { Authorization: string };
  let hodBHeader: { Authorization: string };
  let facultyAHeader: { Authorization: string };
  let studentHeader: { Authorization: string };

  const getErrorMessage = (res: any): string => {
    return res.body?.error?.message || res.body?.message || '';
  };

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
    await FacultyAssignment.init();
    await Room.init();
    await Timetable.init();
    await AttendanceSession.init();
    await CalendarOverride.init();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();

    const defaultPasswordHash = await PasswordService.hashPassword('Password123');

    // 1. Setup Colleges (College A configured with Asia/Kolkata)
    collegeA = await College.create({
      name: 'Alpha Institute of Technology',
      code: 'ALPHA',
      address: 'Alpha Campus, Bangalore',
      email: 'admin@alpha.edu',
      phone: '+919900000001',
      principal: 'Dr. Alpha Principal',
      timezone: 'Asia/Kolkata',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });

    collegeB = await College.create({
      name: 'Beta Institute of Technology',
      code: 'BETA',
      address: 'Beta Campus, Mysore',
      email: 'admin@beta.edu',
      phone: '+919900000002',
      principal: 'Dr. Beta Principal',
      timezone: 'Asia/Kolkata',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });

    // 2. Setup Departments
    deptA = await Department.create({
      collegeId: collegeA._id,
      name: 'Computer Science Department',
      code: 'CSE',
      status: DepartmentStatus.ACTIVE,
      isActive: true,
    });

    deptB = await Department.create({
      collegeId: collegeA._id,
      name: 'Mechanical Engineering Department',
      code: 'MECH',
      status: DepartmentStatus.ACTIVE,
      isActive: true,
    });

    // 3. Academic Structure
    courseA = await Course.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'B.Tech CSE',
      code: 'BTCSE',
      durationYears: 4,
      totalSemesters: 8,
      status: 'active',
      isActive: true,
    });

    academicYearA = await AcademicYear.create({
      collegeId: collegeA._id,
      name: '2026-2027',
      startDate: new Date('2026-06-01T00:00:00.000Z'),
      endDate: new Date('2027-05-31T23:59:59.999Z'),
      isCurrent: true,
      status: 'active',
      isActive: true,
    });

    semesterA = await Semester.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      number: 5,
      name: 'Semester 5',
      startDate: new Date('2026-07-01T00:00:00.000Z'),
      endDate: new Date('2026-12-31T23:59:59.999Z'),
      status: 'active',
      isActive: true,
    });

    sectionA = await Section.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      semesterId: semesterA._id,
      academicYearId: academicYearA._id,
      name: 'Section A',
      capacity: 60,
      status: 'active',
      isActive: true,
    });

    subjectMath = await Subject.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      semesterId: semesterA._id,
      name: 'Discrete Mathematics',
      code: 'CS501',
      credits: 4,
      type: 'theory',
      status: 'active',
      isActive: true,
    });

    subjectPhysics = await Subject.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      semesterId: semesterA._id,
      name: 'Applied Physics',
      code: 'CS502',
      credits: 4,
      type: 'theory',
      status: 'active',
      isActive: true,
    });

    // 4. Users & Auth
    const superAdminUser = await User.create({
      instituteId: 'SUP-01',
      name: 'Global SuperAdmin',
      email: 'superadmin@acadex.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.SUPER_ADMIN,
      accountStatus: AccountStatus.ACTIVE,
      isEmailVerified: true,
    });
    superAdminHeader = createTestAuthHeader({
      userId: superAdminUser.id,
      instituteId: superAdminUser.instituteId,
      role: AppRole.SUPER_ADMIN,
      collegeId: collegeA.id,
    });

    collegeAdminAUser = await User.create({
      instituteId: 'ADM-A-01',
      collegeId: collegeA._id,
      name: 'Admin College A',
      email: 'admin@alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.COLLEGE_ADMIN,
      accountStatus: AccountStatus.ACTIVE,
      isEmailVerified: true,
    });
    collegeAdminAHeader = createTestAuthHeader({
      userId: collegeAdminAUser.id,
      instituteId: collegeAdminAUser.instituteId,
      role: AppRole.COLLEGE_ADMIN,
      collegeId: collegeA.id,
    });

    const hodAUser = await User.create({
      instituteId: 'HOD-A-01',
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'HOD CSE',
      email: 'hod.cse@alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.HOD,
      accountStatus: AccountStatus.ACTIVE,
      isEmailVerified: true,
    });
    hodAHeader = createTestAuthHeader({
      userId: hodAUser.id,
      instituteId: hodAUser.instituteId,
      role: AppRole.HOD,
      collegeId: collegeA.id,
      departmentId: deptA.id,
    });

    const hodBUser = await User.create({
      instituteId: 'HOD-B-01',
      collegeId: collegeA._id,
      departmentId: deptB._id,
      name: 'HOD Mech',
      email: 'hod.mech@alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.HOD,
      accountStatus: AccountStatus.ACTIVE,
      isEmailVerified: true,
    });
    hodBHeader = createTestAuthHeader({
      userId: hodBUser.id,
      instituteId: hodBUser.instituteId,
      role: AppRole.HOD,
      collegeId: collegeA.id,
      departmentId: deptB.id,
    });

    const facultyAUser = await User.create({
      instituteId: 'FAC-A-01',
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'Prof. Alan Turing',
      email: 'turing@alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.FACULTY,
      accountStatus: AccountStatus.ACTIVE,
      isEmailVerified: true,
    });
    facultyA = await Faculty.create({
      userId: facultyAUser._id,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'Prof. Alan Turing',
      email: 'turing@alpha.edu',
      employeeId: 'FAC-ALPHA-001',
      status: 'active',
      isActive: true,
    });
    facultyAHeader = createTestAuthHeader({
      userId: facultyAUser.id,
      instituteId: facultyAUser.instituteId,
      role: AppRole.FACULTY,
      collegeId: collegeA.id,
      departmentId: deptA.id,
    });

    const studentUser = await User.create({
      instituteId: 'STU-01',
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'Student John Doe',
      email: 'john@student.alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.STUDENT,
      accountStatus: AccountStatus.ACTIVE,
      isEmailVerified: true,
    });
    studentProfile = await Student.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      userId: studentUser._id,
      instituteId: studentUser.instituteId,
      name: studentUser.name,
      email: studentUser.email,
      rollNumber: 'CSE-2026-001',
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      status: 'active',
      isActive: true,
    });
    await StudentEnrollment.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      studentId: studentProfile._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      status: 'active',
    });
    studentHeader = createTestAuthHeader({
      userId: studentUser.id,
      instituteId: studentUser.instituteId,
      role: AppRole.STUDENT,
      collegeId: collegeA.id,
    });

    // 5. Faculty Assignments
    assignmentMathA = await FacultyAssignment.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      facultyId: facultyA._id,
      facultyName: facultyA.name,
      subjectId: subjectMath._id,
      courseId: courseA._id,
      semesterId: semesterA._id,
      academicYearId: academicYearA._id,
      sectionId: sectionA._id,
      status: 'active',
      isActive: true,
    });

    assignmentPhysicsA = await FacultyAssignment.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      facultyId: facultyA._id,
      facultyName: facultyA.name,
      subjectId: subjectPhysics._id,
      courseId: courseA._id,
      semesterId: semesterA._id,
      academicYearId: academicYearA._id,
      sectionId: sectionA._id,
      status: 'active',
      isActive: true,
    });

    // 6. Master Published Timetable with Monday & Tuesday entries
    mondayEntryId = new mongoose.Types.ObjectId().toString();
    tuesdayEntryId = new mongoose.Types.ObjectId().toString();

    publishedTimetableA = await Timetable.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      semesterId: semesterA._id,
      academicYearId: academicYearA._id,
      sectionId: sectionA._id,
      name: 'CSE Section A Published Timetable',
      status: TimetableStatus.PUBLISHED,
      version: 1,
      periods: [
        { index: 1, name: 'P1', startTime: '10:00', endTime: '11:00' },
        { index: 2, name: 'P2', startTime: '11:00', endTime: '12:00' },
      ],
      breaks: [
        {
          name: 'Lunch Break',
          startTime: '13:00',
          endTime: '14:00',
          appliesToDays: [TimetableDay.MONDAY, TimetableDay.TUESDAY],
          breakType: TimetableBreakType.LUNCH,
        },
      ],
      entries: [
        {
          _id: new mongoose.Types.ObjectId(mondayEntryId),
          dayOfWeek: TimetableDay.MONDAY,
          startTime: '10:00',
          endTime: '11:00',
          subjectId: subjectMath._id,
          facultyId: facultyA._id,
          facultyAssignmentId: assignmentMathA._id,
          roomNumber: 'LHC-101',
          building: 'Main Block',
        },
        {
          _id: new mongoose.Types.ObjectId(tuesdayEntryId),
          dayOfWeek: TimetableDay.TUESDAY,
          startTime: '11:00',
          endTime: '12:00',
          subjectId: subjectPhysics._id,
          facultyId: facultyA._id,
          facultyAssignmentId: assignmentPhysicsA._id,
          roomNumber: 'LHC-102',
          building: 'Main Block',
        },
      ],
      createdBy: hodAUser._id,
    });
  });

  describe('Calendar Overrides & Attendance Integration Scenarios', () => {
    // 2026-09-28 is a Monday in the civil calendar
    const normalMondayStr = '2026-09-28';
    // 2026-09-29 is a Tuesday
    const normalTuesdayStr = '2026-09-29';
    // 2026-10-05 is a Monday
    const holidayMondayStr = '2026-10-05';
    // 2026-10-12 is a Monday
    const cancelledMondayStr = '2026-10-12';

    it('A. normal recurring class works on matching weekday', async () => {
      const res = await request(app)
        .post('/api/v1/attendance/sessions')
        .set(facultyAHeader)
        .send({
          timetableId: publishedTimetableA._id.toString(),
          timetableEntryId: mondayEntryId,
          date: normalMondayStr,
          timeSlot: '10:00 - 11:00',
          records: [
            { studentId: studentProfile._id.toString(), status: 'present' },
          ],
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.timetableId).toBe(publishedTimetableA._id.toString());
    });

    it('B. wrong weekday remains rejected', async () => {
      // Trying to take Monday's class on Tuesday date
      const res = await request(app)
        .post('/api/v1/attendance/sessions')
        .set(facultyAHeader)
        .send({
          timetableId: publishedTimetableA._id.toString(),
          timetableEntryId: mondayEntryId,
          date: normalTuesdayStr,
          timeSlot: '10:00 - 11:00',
        });

      expect(res.status).toBe(400);
      expect(getErrorMessage(res)).toContain('Scheduled day mismatch');
    });

    it('C. holiday blocks attendance creation with domain error', async () => {
      // 1. Declare college-wide holiday on 2026-10-05
      const createOverrideRes = await request(app)
        .post('/api/v1/calendar-overrides')
        .set(collegeAdminAHeader)
        .send({
          collegeId: collegeA._id.toString(),
          date: holidayMondayStr,
          type: CalendarOverrideType.HOLIDAY,
          scope: CalendarOverrideScope.COLLEGE,
          reason: 'Mahatma Gandhi Jayanti Observed',
        });

      expect(createOverrideRes.status).toBe(201);

      // 2. Faculty attempts to mark attendance for recurring Monday class on 2026-10-05
      const attRes = await request(app)
        .post('/api/v1/attendance/sessions')
        .set(facultyAHeader)
        .send({
          timetableId: publishedTimetableA._id.toString(),
          timetableEntryId: mondayEntryId,
          date: holidayMondayStr,
          timeSlot: '10:00 - 11:00',
        });

      expect(attRes.status).toBe(400);
      expect(getErrorMessage(attRes)).toContain('declared holiday');
      expect(getErrorMessage(attRes)).toContain('Mahatma Gandhi Jayanti Observed');
    });

    it('D. cancelled date blocks attendance creation with domain error', async () => {
      // 1. HOD declares department cancellation on 2026-10-12
      const createOverrideRes = await request(app)
        .post('/api/v1/calendar-overrides')
        .set(hodAHeader)
        .send({
          departmentId: deptA._id.toString(),
          date: cancelledMondayStr,
          type: CalendarOverrideType.CANCELLED,
          scope: CalendarOverrideScope.DEPARTMENT,
          reason: 'Annual Computer Science Symposium 2026',
        });

      expect(createOverrideRes.status).toBe(201);

      // 2. Faculty attempts to mark attendance on 2026-10-12
      const attRes = await request(app)
        .post('/api/v1/attendance/sessions')
        .set(facultyAHeader)
        .send({
          timetableId: publishedTimetableA._id.toString(),
          timetableEntryId: mondayEntryId,
          date: cancelledMondayStr,
          timeSlot: '10:00 - 11:00',
        });

      expect(attRes.status).toBe(400);
      expect(getErrorMessage(attRes)).toContain('cancelled for this date');
      expect(getErrorMessage(attRes)).toContain('Annual Computer Science Symposium 2026');
    });

    it('E. master timetable remains unchanged after override', async () => {
      // Create holiday override
      await CalendarOverride.create({
        collegeId: collegeA._id,
        date: holidayMondayStr,
        type: CalendarOverrideType.HOLIDAY,
        scope: CalendarOverrideScope.COLLEGE,
        reason: 'National Holiday',
        createdBy: collegeAdminAUser._id,
      });

      // Verify master recurring timetable document
      const currentTt = await Timetable.findById(publishedTimetableA._id);
      expect(currentTt).not.toBeNull();
      expect(currentTt!.status).toBe(TimetableStatus.PUBLISHED);
      expect(currentTt!.entries.length).toBe(2);
      expect(currentTt!.version).toBe(1);
      expect(currentTt!.entries[0].dayOfWeek).toBe(TimetableDay.MONDAY);
      expect(currentTt!.entries[1].dayOfWeek).toBe(TimetableDay.TUESDAY);
    });

    it('F. past attendance remains intact when future override is created', async () => {
      // 1. Create session on 2026-09-28
      const createRes = await request(app)
        .post('/api/v1/attendance/sessions')
        .set(facultyAHeader)
        .send({
          timetableId: publishedTimetableA._id.toString(),
          timetableEntryId: mondayEntryId,
          date: normalMondayStr,
          timeSlot: '10:00 - 11:00',
          records: [
            { studentId: studentProfile._id.toString(), status: 'present' },
          ],
        });
      expect(createRes.status).toBe(201);
      const sessionId = createRes.body.data.id;

      // 2. Create future holiday override on 2026-10-05
      await CalendarOverride.create({
        collegeId: collegeA._id,
        date: holidayMondayStr,
        type: CalendarOverrideType.HOLIDAY,
        scope: CalendarOverrideScope.COLLEGE,
        reason: 'Future Holiday',
        createdBy: collegeAdminAUser._id,
      });

      // 3. Verify past session is completely intact
      const pastSession = await AttendanceSession.findById(sessionId);
      expect(pastSession).not.toBeNull();
      expect(pastSession!.records.length).toBe(1);
    });

    it('G. future override does not affect other dates', async () => {
      // 1. Declare holiday on 2026-10-05
      await CalendarOverride.create({
        collegeId: collegeA._id,
        date: holidayMondayStr,
        type: CalendarOverrideType.HOLIDAY,
        scope: CalendarOverrideScope.COLLEGE,
        reason: 'Gandhi Jayanti',
        createdBy: collegeAdminAUser._id,
      });

      // 2. Class on next Monday (2026-10-19) operates normally
      const nextMondayStr = '2026-10-19';
      const attRes = await request(app)
        .post('/api/v1/attendance/sessions')
        .set(facultyAHeader)
        .send({
          timetableId: publishedTimetableA._id.toString(),
          timetableEntryId: mondayEntryId,
          date: nextMondayStr,
          timeSlot: '10:00 - 11:00',
        });

      expect(attRes.status).toBe(201);
      expect(attRes.body.success).toBe(true);
    });

    it('H. duplicate override is rejected with 409 Conflict', async () => {
      // 1. First declaration
      const res1 = await request(app)
        .post('/api/v1/calendar-overrides')
        .set(collegeAdminAHeader)
        .send({
          collegeId: collegeA._id.toString(),
          date: '2026-11-01',
          type: CalendarOverrideType.HOLIDAY,
          scope: CalendarOverrideScope.COLLEGE,
          reason: 'Kannada Rajyotsava',
        });
      expect(res1.status).toBe(201);

      // 2. Duplicate declaration for the exact same scope & date
      const res2 = await request(app)
        .post('/api/v1/calendar-overrides')
        .set(collegeAdminAHeader)
        .send({
          collegeId: collegeA._id.toString(),
          date: '2026-11-01',
          type: CalendarOverrideType.HOLIDAY,
          scope: CalendarOverrideScope.COLLEGE,
          reason: 'Duplicate State Festival',
        });
      expect(res2.status).toBe(409);
      expect(getErrorMessage(res2)).toContain('already exists for this date and scope');

      // 3. Attempting department override on date with existing college-wide holiday is also rejected
      const res3 = await request(app)
        .post('/api/v1/calendar-overrides')
        .set(hodAHeader)
        .send({
          departmentId: deptA._id.toString(),
          date: '2026-11-01',
          type: CalendarOverrideType.CANCELLED,
          reason: 'Department meeting on holiday',
        });
      expect(res3.status).toBe(409);
      expect(getErrorMessage(res3)).toContain('college-wide holiday');
    });

    it('I. HOD cannot create another department’s override (403 Forbidden)', async () => {
      // HOD A attempts to declare an override for Department B
      const res = await request(app)
        .post('/api/v1/calendar-overrides')
        .set(hodAHeader)
        .send({
          departmentId: deptB._id.toString(),
          date: '2026-11-10',
          type: CalendarOverrideType.CANCELLED,
          reason: 'Illegal Mech department cancellation by CSE HOD',
        });

      expect(res.status).toBe(403);
      expect(getErrorMessage(res)).toContain('HOD can only create calendar overrides for their own department');

      // But HOD B CAN create override for Department B
      const resB = await request(app)
        .post('/api/v1/calendar-overrides')
        .set(hodBHeader)
        .send({
          departmentId: deptB._id.toString(),
          date: '2026-11-10',
          type: CalendarOverrideType.CANCELLED,
          reason: 'Legitimate Mech department cancellation by Mech HOD',
        });
      expect(resB.status).toBe(201);
    });

    it('J. HOD cannot create another college’s override or college-wide override (403 Forbidden)', async () => {
      // 1. HOD A attempts college-wide scope
      const res1 = await request(app)
        .post('/api/v1/calendar-overrides')
        .set(hodAHeader)
        .send({
          date: '2026-11-15',
          type: CalendarOverrideType.HOLIDAY,
          scope: CalendarOverrideScope.COLLEGE,
          reason: 'HOD trying to declare institute holiday',
        });
      expect(res1.status).toBe(403);
      expect(getErrorMessage(res1)).toContain('HOD is not permitted to declare college-wide overrides');

      // 2. HOD A attempts foreign collegeId
      const res2 = await request(app)
        .post('/api/v1/calendar-overrides')
        .set(hodAHeader)
        .send({
          collegeId: collegeB._id.toString(),
          date: '2026-11-15',
          type: CalendarOverrideType.CANCELLED,
          reason: 'Foreign college tampering',
        });
      expect(res2.status).toBe(403);
      expect(getErrorMessage(res2)).toContain('Cross-college access is strictly prohibited');

      // 3. But SuperAdmin CAN create override for any college
      const resSuper = await request(app)
        .post('/api/v1/calendar-overrides')
        .set(superAdminHeader)
        .send({
          collegeId: collegeB._id.toString(),
          date: '2026-11-15',
          type: CalendarOverrideType.HOLIDAY,
          scope: CalendarOverrideScope.COLLEGE,
          reason: 'SuperAdmin College B Holiday',
        });
      expect(resSuper.status).toBe(201);
    });

    it('K. Faculty cannot mutate overrides (403 Forbidden)', async () => {
      // Faculty attempts POST
      const resPost = await request(app)
        .post('/api/v1/calendar-overrides')
        .set(facultyAHeader)
        .send({
          date: '2026-11-20',
          type: CalendarOverrideType.CANCELLED,
          reason: 'Faculty cancelling class via override',
        });
      expect(resPost.status).toBe(403);

      // Create an override as Admin
      const override = await CalendarOverride.create({
        collegeId: collegeA._id,
        date: '2026-11-20',
        type: CalendarOverrideType.HOLIDAY,
        scope: CalendarOverrideScope.COLLEGE,
        reason: 'Admin Holiday',
        createdBy: collegeAdminAUser._id,
      });

      // Faculty attempts DELETE
      const resDelete = await request(app)
        .delete(`/api/v1/calendar-overrides/${override._id}`)
        .set(facultyAHeader);
      expect(resDelete.status).toBe(403);
    });

    it('L. Student cannot mutate overrides (403 Forbidden)', async () => {
      const resPost = await request(app)
        .post('/api/v1/calendar-overrides')
        .set(studentHeader)
        .send({
          date: '2026-11-25',
          type: CalendarOverrideType.HOLIDAY,
          reason: 'Student declaring holiday',
        });
      expect(resPost.status).toBe(403);
    });

    it('M. timezone boundary date remains correct (Indian Standard Time)', async () => {
      // In Asia/Kolkata (UTC+5:30):
      // 2026-09-21T19:00:00.000Z is 2026-09-22T00:30:00+05:30 (Tuesday early morning).
      // On UTC server, Date.getUTCDay() is 1 (Monday).
      // But in Asia/Kolkata, the academic calendar date is Tuesday (2026-09-22).
      const istEarlyTuesdayTimestamp = '2026-09-21T19:00:00.000Z';

      // Attempting to match Monday's class with this timestamp should fail because in India it's Tuesday!
      const resMonday = await request(app)
        .post('/api/v1/attendance/sessions')
        .set(facultyAHeader)
        .send({
          timetableId: publishedTimetableA._id.toString(),
          timetableEntryId: mondayEntryId,
          date: istEarlyTuesdayTimestamp,
          timeSlot: '10:00 - 11:00',
        });
      expect(resMonday.status).toBe(400);
      expect(getErrorMessage(resMonday)).toContain('Scheduled day mismatch');

      // Attempting to match Tuesday's class with this timestamp should succeed!
      const resTuesday = await request(app)
        .post('/api/v1/attendance/sessions')
        .set(facultyAHeader)
        .send({
          timetableId: publishedTimetableA._id.toString(),
          timetableEntryId: tuesdayEntryId,
          date: istEarlyTuesdayTimestamp,
          timeSlot: '11:00 - 12:00',
        });
      expect(resTuesday.status).toBe(201);
    });

    it('N. adjacent normal dates remain operational', async () => {
      // Declare holiday on Monday 2026-10-05
      await CalendarOverride.create({
        collegeId: collegeA._id,
        date: holidayMondayStr,
        type: CalendarOverrideType.HOLIDAY,
        scope: CalendarOverrideScope.COLLEGE,
        reason: 'Gandhi Jayanti',
        createdBy: collegeAdminAUser._id,
      });

      // Adjacent Tuesday 2026-10-06 operates normally
      const adjacentTuesdayStr = '2026-10-06';
      const resTuesday = await request(app)
        .post('/api/v1/attendance/sessions')
        .set(facultyAHeader)
        .send({
          timetableId: publishedTimetableA._id.toString(),
          timetableEntryId: tuesdayEntryId,
          date: adjacentTuesdayStr,
          timeSlot: '11:00 - 12:00',
        });

      expect(resTuesday.status).toBe(201);
      expect(resTuesday.body.success).toBe(true);
    });

    it('Full E2E: Recurring timetable -> calendar date -> override resolution -> attendance authorization', async () => {
      // 1. Declare holiday on Monday 2026-10-05
      await request(app)
        .post('/api/v1/calendar-overrides')
        .set(collegeAdminAHeader)
        .send({
          date: holidayMondayStr,
          type: CalendarOverrideType.HOLIDAY,
          scope: CalendarOverrideScope.COLLEGE,
          reason: 'Gandhi Jayanti Public Holiday',
        });

      // 2. Query faculty timetable for 2026-10-05 (Holiday)
      const holidayFacultyView = await request(app)
        .get(`/api/v1/timetables/faculty/me?date=${holidayMondayStr}`)
        .set(facultyAHeader);
      expect(holidayFacultyView.status).toBe(200);
      // Holiday date returns 0 operational classes
      expect(holidayFacultyView.body.data.length).toBe(0);

      // 3. Query faculty timetable for normal Monday 2026-09-28
      const normalFacultyView = await request(app)
        .get(`/api/v1/timetables/faculty/me?date=${normalMondayStr}`)
        .set(facultyAHeader);
      expect(normalFacultyView.status).toBe(200);
      expect(normalFacultyView.body.data.length).toBe(1);
      expect(normalFacultyView.body.data[0].dayOfWeek).toBe(TimetableDay.MONDAY);

      // 4. Query student timetable for 2026-10-05 (Holiday)
      const holidayStudentView = await request(app)
        .get(`/api/v1/timetables/students/me?date=${holidayMondayStr}`)
        .set(studentHeader);
      expect(holidayStudentView.status).toBe(200);
      expect(holidayStudentView.body.data.length).toBe(0);

      // 5. Query student timetable for normal Monday 2026-09-28
      const normalStudentView = await request(app)
        .get(`/api/v1/timetables/students/me?date=${normalMondayStr}`)
        .set(studentHeader);
      expect(normalStudentView.status).toBe(200);
      expect(normalStudentView.body.data.length).toBe(1);

      // 6. Attempt attendance creation on Holiday: rejected
      const blockedAtt = await request(app)
        .post('/api/v1/attendance/sessions')
        .set(facultyAHeader)
        .send({
          timetableId: publishedTimetableA._id.toString(),
          timetableEntryId: mondayEntryId,
          date: holidayMondayStr,
          timeSlot: '10:00 - 11:00',
        });
      expect(blockedAtt.status).toBe(400);
      expect(getErrorMessage(blockedAtt)).toContain('Gandhi Jayanti Public Holiday');

      // 7. Authorize and create attendance on normal date: authorized and created!
      const allowedAtt = await request(app)
        .post('/api/v1/attendance/sessions')
        .set(facultyAHeader)
        .send({
          timetableId: publishedTimetableA._id.toString(),
          timetableEntryId: mondayEntryId,
          date: normalMondayStr,
          timeSlot: '10:00 - 11:00',
          records: [
            { studentId: studentProfile._id.toString(), status: 'present' },
          ],
        });
      expect(allowedAtt.status).toBe(201);
      expect(allowedAtt.body.success).toBe(true);
    });
  });
});
