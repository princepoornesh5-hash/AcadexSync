import mongoose, { Types } from 'mongoose';
import { MongoMemoryServer } from 'mongodb-memory-server';
import {
  CalendarOverride,
  Timetable,
  PracticalSession,
  InternalAssessment,
  AcademicResult,
  Assignment,
  StudentEnrollment,
  Student,
  Subject,
  Course,
  Semester,
  AcademicYear,
  Department,
  College,
  User,
  Section,
} from '../../src/models';
import { TeacherSubstitution, TeacherSubstitutionStatus } from '../../src/models/teacherSubstitution.model';
import {
  AcademicCalendarStatus,
  CalendarEventType,
  CalendarEventScope,
  CalendarEventStatus,
  CalendarSourceType,
} from '../../src/constants/calendar.constants';
import {
  CalendarOverrideType,
  CalendarOverrideScope,
} from '../../src/models/calendarOverride.model';
import { TimetableDay, TimetableStatus, TimetableTimingMode, TimetableSessionType, AccountStatus } from '../../src/constants/status';
import { AppRole } from '../../src/constants/roles';
import { AssignmentStatus, AssignmentType } from '../../src/constants/assignment.constants';
import { PracticalSessionStatus } from '../../src/constants/practical.constants';
import { AssessmentStatus, AssessmentType } from '../../src/models/internalAssessment.model';
import { ResultLifecycleStatus, OverallResultStatus } from '../../src/constants/academicResult.constants';
import { AcademicCalendarService } from '../../src/services/academicCalendar.service';
import { AuthenticatedUser } from '../../src/types/auth.types';

describe('PROMPT 45 — Academic Calendar, Events & Date-Aware Operations Tests', () => {
  let mongoServer: MongoMemoryServer;
  let collegeId: Types.ObjectId;
  let departmentId: Types.ObjectId;
  let otherDepartmentId: Types.ObjectId;
  let courseId: Types.ObjectId;
  let academicYearId: Types.ObjectId;
  let semesterId: Types.ObjectId;
  let sectionId: Types.ObjectId;
  let subjectId: Types.ObjectId;

  let adminUser: AuthenticatedUser;
  let hodUser: AuthenticatedUser;
  let facultyUser: AuthenticatedUser;
  let studentUser: AuthenticatedUser;
  let studentDoc: any;

  beforeAll(async () => {
    mongoServer = await MongoMemoryServer.create();
    const uri = mongoServer.getUri();
    await mongoose.connect(uri);

    collegeId = new Types.ObjectId();
    departmentId = new Types.ObjectId();
    otherDepartmentId = new Types.ObjectId();
    courseId = new Types.ObjectId();
    academicYearId = new Types.ObjectId();
    semesterId = new Types.ObjectId();
    sectionId = new Types.ObjectId();
    subjectId = new Types.ObjectId();

    await College.create({
      _id: collegeId,
      name: 'Acadex Institute of Technology',
      code: 'AIT',
      principal: 'Dr. John Principal',
      phone: '9876543210',
      email: 'principal@ait.edu',
      address: '100 University Ave',
    });

    await Department.create({ _id: departmentId, collegeId, name: 'Computer Science', code: 'CSE' });
    await Department.create({ _id: otherDepartmentId, collegeId, name: 'Mechanical', code: 'ME' });
    await Course.create({ _id: courseId, collegeId, departmentId, name: 'B.Tech CSE', code: 'CS', duration: 4 });
    await AcademicYear.create({
      _id: academicYearId,
      collegeId,
      name: '2026-2027',
      startDate: new Date('2026-08-01'),
      endDate: new Date('2027-05-31'),
    });
    await Semester.create({
      _id: semesterId,
      collegeId,
      departmentId,
      courseId,
      academicYearId,
      name: 'Semester 4',
      number: 4,
    });
    await Section.create({
      _id: sectionId,
      collegeId,
      departmentId,
      courseId,
      academicYearId,
      semesterId,
      name: 'Section A',
    });
    await Subject.create({
      _id: subjectId,
      collegeId,
      departmentId,
      courseId,
      semesterId,
      name: 'Operating Systems',
      code: 'CS402',
      credits: 4,
      status: 'active',
    });

    const adminUserId = new Types.ObjectId();
    adminUser = {
      id: adminUserId.toString(),
      instituteId: collegeId.toString(),
      email: 'admin@ait.edu',
      role: AppRole.COLLEGE_ADMIN,
      collegeId: collegeId.toString(),
      name: 'College Admin',
      accountStatus: AccountStatus.ACTIVE,
    };

    const hodUserId = new Types.ObjectId();
    await Department.findByIdAndUpdate(departmentId, { hodId: hodUserId });
    hodUser = {
      id: hodUserId.toString(),
      instituteId: collegeId.toString(),
      email: 'hod@ait.edu',
      role: AppRole.HOD,
      collegeId: collegeId.toString(),
      departmentId: departmentId.toString(),
      name: 'Prof. Turing (HOD)',
      accountStatus: AccountStatus.ACTIVE,
    };

    const facultyUserId = new Types.ObjectId();
    facultyUser = {
      id: facultyUserId.toString(),
      instituteId: collegeId.toString(),
      email: 'faculty@ait.edu',
      role: AppRole.FACULTY,
      collegeId: collegeId.toString(),
      departmentId: departmentId.toString(),
      name: 'Prof. Hopper',
      accountStatus: AccountStatus.ACTIVE,
    };

    const studentUserId = new Types.ObjectId();
    studentDoc = await Student.create({
      collegeId,
      userId: studentUserId,
      name: 'Dennis Ritchie',
      firstName: 'Dennis',
      lastName: 'Ritchie',
      email: 'dennis@ait.edu',
      rollNumber: 'CS2026-042',
      departmentId,
      courseId,
      academicYearId,
      semesterId,
      sectionId,
      status: 'active',
    });

    await StudentEnrollment.create({
      collegeId,
      studentId: studentDoc._id,
      departmentId,
      courseId,
      academicYearId,
      semesterId,
      sectionId,
      status: 'active',
    });

    studentUser = {
      id: studentUserId.toString(),
      instituteId: collegeId.toString(),
      email: 'dennis@ait.edu',
      role: AppRole.STUDENT,
      collegeId: collegeId.toString(),
      departmentId: departmentId.toString(),
      name: 'Dennis Ritchie',
      accountStatus: AccountStatus.ACTIVE,
    };
  });

  afterAll(async () => {
    await mongoose.disconnect();
    await mongoServer.stop();
  });

  // ══════════════════════════════════════════════════════════
  // 1. ACADEMIC CALENDAR LIFECYCLE & TENANT ISOLATION
  // ══════════════════════════════════════════════════════════
  describe('1. Academic Calendar Lifecycle & Tenant Isolation', () => {
    let createdCalendarId: string;

    it('1.1 Allows College Admin to create AcademicCalendar', async () => {
      const calendar = await AcademicCalendarService.createAcademicCalendar(
        {
          academicYearId: academicYearId.toString(),
          title: 'Academic Year 2026-27 Odd Semester Calendar',
          startDate: '2026-08-01',
          endDate: '2026-12-31',
          workingDays: [1, 2, 3, 4, 5],
          holidays: [
            {
              date: '2026-08-15',
              name: 'Independence Day',
              description: 'National Holiday',
              isFullDay: true,
            },
          ],
        },
        adminUser
      );

      expect(calendar).toBeDefined();
      expect(calendar.title).toBe('Academic Year 2026-27 Odd Semester Calendar');
      expect(calendar.status).toBe(AcademicCalendarStatus.DRAFT);
      expect(calendar.workingDays).toEqual([1, 2, 3, 4, 5]);
      expect(calendar.holidays.length).toBe(1);
      createdCalendarId = calendar._id.toString();
    });

    it('1.2 Rejects Student attempting to create an AcademicCalendar', async () => {
      await expect(
        AcademicCalendarService.createAcademicCalendar(
          {
            academicYearId: academicYearId.toString(),
            title: 'Unauthorized Calendar',
            startDate: '2026-08-01',
            endDate: '2026-12-31',
          },
          studentUser
        )
      ).rejects.toThrow('Only administrators and HODs may create academic calendars');
    });

    it('1.3 Rejects calendar with startDate after endDate', async () => {
      await expect(
        AcademicCalendarService.createAcademicCalendar(
          {
            academicYearId: academicYearId.toString(),
            title: 'Invalid Dates Calendar',
            startDate: '2026-12-31',
            endDate: '2026-08-01',
          },
          adminUser
        )
      ).rejects.toThrow('startDate must be before or equal to endDate');
    });

    it('1.4 Allows activating and listing academic calendars', async () => {
      const activated = await AcademicCalendarService.activateAcademicCalendar(createdCalendarId, adminUser);
      expect(activated.status).toBe(AcademicCalendarStatus.ACTIVE);

      const list = await AcademicCalendarService.listAcademicCalendars(adminUser, {
        academicYearId: academicYearId.toString(),
      });
      expect(list.total).toBeGreaterThanOrEqual(1);
      expect(list.calendars.some((c) => c._id.toString() === createdCalendarId)).toBe(true);
    });
  });

  // ══════════════════════════════════════════════════════════
  // 2. HOLIDAY DECLARATION & WORKING-DAY RESOLUTION
  // ══════════════════════════════════════════════════════════
  describe('2. Holiday Declaration & Working-Day Resolution', () => {
    it('2.1 Declares a holiday and creates both CalendarOverride and CalendarEvent', async () => {
      const holidayDate = '2026-10-02';
      const result = await AcademicCalendarService.declareHoliday(
        {
          date: holidayDate,
          name: 'Gandhi Jayanti',
          description: 'National public holiday',
          scope: CalendarEventScope.COLLEGE,
        },
        adminUser
      );

      expect(result.override).toBeDefined();
      expect(result.override.type).toBe(CalendarOverrideType.HOLIDAY);
      expect(result.override.date).toBe(holidayDate);

      expect(result.event).toBeDefined();
      expect(result.event.eventType).toBe(CalendarEventType.HOLIDAY);
      expect(result.event.startDate).toBe(holidayDate);
    });

    it('2.2 resolveWorkingDay correctly identifies declared holiday', async () => {
      const status = await AcademicCalendarService.resolveWorkingDay(collegeId.toString(), '2026-10-02');
      expect(status.isWorkingDay).toBe(false);
      expect(status.type).toBe('HOLIDAY');
      expect(status.reason).toBe('Gandhi Jayanti');
    });

    it('2.3 resolveWorkingDay recognizes embedded calendar holidays', async () => {
      const status = await AcademicCalendarService.resolveWorkingDay(collegeId.toString(), '2026-08-15');
      expect(status.isWorkingDay).toBe(false);
      expect(status.type).toBe('HOLIDAY');
      expect(status.reason).toBe('Independence Day');
    });

    it('2.4 resolveWorkingDay recognizes standard weekdays as working days', async () => {
      // 2026-09-02 is Wednesday
      const status = await AcademicCalendarService.resolveWorkingDay(collegeId.toString(), '2026-09-02');
      expect(status.isWorkingDay).toBe(true);
      expect(status.type).toBe('WORKING_DAY');
    });

    it('2.5 resolveWorkingDay recognizes weekends as weekly off', async () => {
      // 2026-09-06 is Sunday
      const status = await AcademicCalendarService.resolveWorkingDay(collegeId.toString(), '2026-09-06');
      expect(status.isWorkingDay).toBe(false);
      expect(status.type).toBe('WEEKLY_OFF');
    });
  });

  // ══════════════════════════════════════════════════════════
  // 3. EVENT CREATION, ROLE SCOPING & CANCELLATION
  // ══════════════════════════════════════════════════════════
  describe('3. Event Creation, Scoping & Cancellation', () => {
    let eventId: string;

    it('3.1 HOD can create event for their own department', async () => {
      const event = await AcademicCalendarService.createEvent(
        {
          title: 'CSE Department Orientation',
          description: 'Welcoming new batch to computer science department',
          eventType: CalendarEventType.ACADEMIC_EVENT,
          scope: CalendarEventScope.DEPARTMENT,
          startDate: '2026-09-10',
          endDate: '2026-09-10',
          departmentId: departmentId.toString(),
        },
        hodUser
      );

      expect(event).toBeDefined();
      expect(event.departmentId?.toString()).toBe(departmentId.toString());
      eventId = event._id.toString();
    });

    it('3.2 Rejects HOD creating event for another department', async () => {
      await expect(
        AcademicCalendarService.createEvent(
          {
            title: 'Mechanical Lab Inauguration',
            eventType: CalendarEventType.ACADEMIC_EVENT,
            scope: CalendarEventScope.DEPARTMENT,
            startDate: '2026-09-12',
            departmentId: otherDepartmentId.toString(),
          },
          hodUser
        )
      ).rejects.toThrow('HOD can only create events for their own department');
    });

    it('3.3 Cancels event with mandatory reason', async () => {
      const cancelled = await AcademicCalendarService.cancelEvent(
        eventId,
        'Postponed due to university inspection',
        hodUser
      );
      expect(cancelled.status).toBe(CalendarEventStatus.CANCELLED);
      expect(cancelled.metadata?.cancellationReason).toBe('Postponed due to university inspection');
    });
  });

  // ══════════════════════════════════════════════════════════
  // 4. MULTI-SOURCE CALENDAR AGGREGATION
  // ══════════════════════════════════════════════════════════
  describe('4. Multi-Source Calendar Aggregation (getCalendarForUser)', () => {
    beforeAll(async () => {
      // 1. Create published Assignment (Prompt 39)
      await Assignment.create({
        collegeId,
        departmentId,
        courseId,
        academicYearId,
        semesterId,
        sectionId,
        subjectId,
        facultyId: new Types.ObjectId(facultyUser.id),
        facultyName: facultyUser.name,
        title: 'OS Process Scheduling Assignment',
        description: 'Implement Round Robin and Shortest Job First scheduling algorithms.',
        assignmentType: AssignmentType.HOMEWORK,
        status: AssignmentStatus.PUBLISHED,
        dueDate: '2026-09-15',
        dueTime: '17:00',
        dueDateTime: new Date('2026-09-15T17:00:00Z'),
        maximumMarks: 100,
        publishedAt: new Date('2026-09-01'),
      });

      // 2. Create published Timetable with weekly schedule (Prompt 37)
      const timetableEntryId = new Types.ObjectId();
      await Timetable.create({
        collegeId,
        departmentId,
        courseId,
        academicYearId,
        semesterId,
        sectionId,
        name: 'CSE Sem 4 Timetable',
        status: TimetableStatus.PUBLISHED,
        version: 1,
        timingMode: TimetableTimingMode.SAME_EVERY_DAY,
        activeDays: [TimetableDay.MONDAY, TimetableDay.TUESDAY, TimetableDay.WEDNESDAY],
        periods: [
          { index: 1, name: 'Period 1', startTime: '09:00', endTime: '10:00' },
        ],
        breaks: [],
        entries: [
          {
            _id: timetableEntryId,
            dayOfWeek: TimetableDay.MONDAY,
            startTime: '09:00',
            endTime: '10:00',
            subjectId,
            subjectName: 'Operating Systems',
            facultyId: new Types.ObjectId(facultyUser.id),
            roomNumber: 'Room 301',
            sessionType: TimetableSessionType.LECTURE,
          },
        ],
      });

      // 3. Create TeacherSubstitution on 2026-09-14 (Monday)
      const substituteFacultyUser = await User.create({
        collegeId,
        name: 'Dr. Substitute Linus',
        email: 'linus@ait.edu',
        role: AppRole.FACULTY,
        status: 'active',
      });

      await TeacherSubstitution.create({
        collegeId,
        departmentId,
        sectionId,
        timetableId: new Types.ObjectId(),
        timetableEntryId,
        date: '2026-09-14',
        originalFacultyId: new Types.ObjectId(facultyUser.id),
        substituteFacultyId: substituteFacultyUser._id,
        reason: 'Attending IEEE conference',
        status: TeacherSubstitutionStatus.ACTIVE,
        createdBy: new Types.ObjectId(adminUser.id),
      });

      // 4. Create PracticalSession on 2026-09-16 (Prompt 41)
      await PracticalSession.create({
        collegeId,
        departmentId,
        courseId,
        academicYearId,
        semesterId,
        sectionId,
        subjectId,
        facultyAssignmentId: new Types.ObjectId(),
        facultyId: new Types.ObjectId(facultyUser.id),
        sessionNumber: 1,
        topic: 'Multi-threading POSIX Lab',
        scheduledDate: new Date('2026-09-16T10:00:00Z'),
        startTime: '10:00',
        endTime: '12:00',
        status: PracticalSessionStatus.PLANNED,
        totalEnrolled: 40,
        completedCount: 0,
        inProgressCount: 0,
        absentCount: 0,
      });

      // 5. Create InternalAssessment on 2026-09-18 (Prompt 43)
      await InternalAssessment.create({
        collegeId,
        departmentId,
        courseId,
        academicYearId,
        semesterId,
        sectionId,
        subjectId,
        title: 'OS Midterm Assessment 1',
        assessmentType: AssessmentType.INTERNAL_EXAM,
        maximumMarks: 50,
        assessmentDate: new Date('2026-09-18T09:00:00Z'),
        status: AssessmentStatus.PUBLISHED,
        components: [{ key: 'theory', name: 'Theory Exam', maxMarks: 50 }],
        entries: [],
        auditLog: [],
      });

      // 6. Create AcademicResult publication event on 2026-09-20 (Prompt 44)
      await AcademicResult.create({
        collegeId,
        studentId: studentDoc._id,
        studentEnrollmentId: new Types.ObjectId(),
        academicRecordId: new Types.ObjectId(),
        departmentId,
        courseId,
        academicYearId,
        semesterId,
        sectionId,
        status: ResultLifecycleStatus.PUBLISHED,
        version: 1,
        summary: {
          totalMaxMarks: 500,
          totalObtainedMarks: 440,
          percentage: 88.0,
          overallResult: OverallResultStatus.PASS,
        },
        subjectResults: [],
        calculatedAt: new Date(),
        publishedAt: new Date('2026-09-20T12:00:00Z'),
        publicationSnapshots: [],
        reopenHistory: [],
      });
    });

    it('4.1 Aggregates unified calendar for student combining all operational sources', async () => {
      const events = await AcademicCalendarService.getCalendarForUser(studentUser, {
        startDate: '2026-09-01',
        endDate: '2026-09-30',
      });

      expect(events).toBeDefined();
      expect(events.length).toBeGreaterThanOrEqual(5);

      // Verify Assignment Deadline derived event
      const assignmentEv = events.find((e) => e.sourceType === CalendarSourceType.ASSIGNMENT);
      expect(assignmentEv).toBeDefined();
      expect(assignmentEv?.title).toBe('OS Process Scheduling Assignment');
      expect(assignmentEv?.startDate).toBe('2026-09-15');

      // Verify Timetable class expansion on Monday 2026-09-14
      const timetableEv = events.find(
        (e) => e.sourceType === CalendarSourceType.TIMETABLE && e.startDate === '2026-09-14'
      );
      expect(timetableEv).toBeDefined();
      expect(timetableEv?.title).toBe('Operating Systems');
      expect(timetableEv?.description).toContain('Substituted');

      // Verify Practical Session derived event on 2026-09-16
      const practicalEv = events.find((e) => e.sourceType === CalendarSourceType.PRACTICAL);
      expect(practicalEv).toBeDefined();
      expect(practicalEv?.title).toBe('Practical: Multi-threading POSIX Lab');
      expect(practicalEv?.startDate).toBe('2026-09-16');

      // Verify Internal Assessment derived event on 2026-09-18
      const assessmentEv = events.find((e) => e.sourceType === CalendarSourceType.ASSESSMENT);
      expect(assessmentEv).toBeDefined();
      expect(assessmentEv?.title).toBe('Assessment: OS Midterm Assessment 1');
      expect(assessmentEv?.startDate).toBe('2026-09-18');

      // Verify Academic Result publication event on 2026-09-20
      const resultEv = events.find((e) => e.sourceType === CalendarSourceType.ACADEMIC_RESULT);
      expect(resultEv).toBeDefined();
      expect(resultEv?.title).toContain('Official Result Published');
      expect(resultEv?.startDate).toBe('2026-09-20');
    });

    it('4.2 Honors calendar override when holiday is declared on a timetable day', async () => {
      // Declare holiday on 2026-09-21 (Monday)
      await CalendarOverride.create({
        collegeId,
        date: '2026-09-21',
        type: CalendarOverrideType.HOLIDAY,
        scope: CalendarOverrideScope.COLLEGE,
        reason: 'Special College Founder Day',
        createdBy: new Types.ObjectId(adminUser.id),
      });

      const events = await AcademicCalendarService.getCalendarForUser(studentUser, {
        startDate: '2026-09-21',
        endDate: '2026-09-21',
      });

      // Timetable class should NOT run on a declared holiday
      const timetableOnHoliday = events.find(
        (e) => e.sourceType === CalendarSourceType.TIMETABLE && e.startDate === '2026-09-21'
      );
      expect(timetableOnHoliday).toBeUndefined();
    });

    it('4.3 Retrieves single event detail by ID for derived assignment', async () => {
      const assignment = await Assignment.findOne({ collegeId, title: 'OS Process Scheduling Assignment' });
      expect(assignment).toBeDefined();

      const detail = await AcademicCalendarService.getEventById(
        `derived_assignment_${assignment!._id.toString()}`,
        studentUser
      );
      expect(detail).toBeDefined();
      expect(detail.title).toBe('OS Process Scheduling Assignment');
      expect(detail.sourceType).toBe(CalendarSourceType.ASSIGNMENT);
      expect(detail.canEdit).toBe(false);
      expect(detail.canCancel).toBe(false);
    });
  });
});
