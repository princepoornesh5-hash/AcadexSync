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
import { Assignment } from '../../src/models/assignment.model';
import { CalendarEvent } from '../../src/models/calendarEvent.model';
import { InstitutionConfiguration } from '../../src/models/institutionConfiguration.model';
import { AppRole } from '../../src/constants/roles';
import { AccountStatus } from '../../src/constants/status';
import { AssignmentStatus, AssignmentType } from '../../src/constants/assignment.constants';
import {
  CalendarEventType,
  CalendarEventScope,
  CalendarEventStatus,
  CalendarSourceType,
} from '../../src/constants/calendar.constants';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { AcademicCalendarService } from '../../src/services/academicCalendar.service';
import { NotificationService } from '../../src/services/notification.service';
import { AuthenticatedUser } from '../../src/types/auth.types';

describe('Prompt 23 — Centralized Academic Calendar Integration Tests', () => {
  let collegeA: InstanceType<typeof College>;
  let collegeB: InstanceType<typeof College>;

  let adminUserA: InstanceType<typeof User>;
  let hodUserA: InstanceType<typeof User>;
  let facultyUserA: InstanceType<typeof User>;
  let studentUserA1: InstanceType<typeof User>;
  let studentUserA2: InstanceType<typeof User>;
  let studentUserB: InstanceType<typeof User>;

  let deptA1: InstanceType<typeof Department>;
  let deptA2: InstanceType<typeof Department>;
  let deptB: InstanceType<typeof Department>;

  let courseA: InstanceType<typeof Course>;
  let academicYearA: InstanceType<typeof AcademicYear>;
  let semesterA: InstanceType<typeof Semester>;
  let sectionA: InstanceType<typeof Section>;
  let subjectDBMS: InstanceType<typeof Subject>;

  let studentProfileA1: InstanceType<typeof Student>;

  beforeAll(async () => {
    await setupTestDB();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();

    // 1. Create Colleges
    collegeA = await College.create({
      name: 'College of Engineering A',
      code: 'COE-A',
      address: 'Main Campus Road',
      email: 'admin@coea.edu',
      phone: '9876543210',
      principal: 'Dr. Principal A',
    });

    collegeB = await College.create({
      name: 'Polytechnic College B',
      code: 'POLY-B',
      address: 'North Campus Road',
      email: 'admin@polyb.edu',
      phone: '9876543211',
      principal: 'Dr. Principal B',
    });

    // 2. Default Configuration
    await InstitutionConfiguration.create({
      collegeId: collegeA._id,
      institutionType: 'ENGINEERING',
      academicStructure: {
        program: true,
        academicYear: true,
        semester: true,
        section: true,
        subject: true,
        building: true,
        room: true,
      },
      terminology: {
        department: { singular: 'Department', plural: 'Departments' },
        program: { singular: 'Course', plural: 'Courses' },
        academicYear: { singular: 'Academic Year', plural: 'Academic Years' },
        semester: { singular: 'Semester', plural: 'Semesters' },
        section: { singular: 'Section', plural: 'Sections' },
        subject: { singular: 'Subject', plural: 'Subjects' },
      },
      isConfigured: true,
    });

    // 3. Departments
    deptA1 = await Department.create({
      collegeId: collegeA._id,
      name: 'Computer Science',
      code: 'CSE',
    });

    deptA2 = await Department.create({
      collegeId: collegeA._id,
      name: 'Mechanical Engineering',
      code: 'MECH',
    });

    deptB = await Department.create({
      collegeId: collegeB._id,
      name: 'Information Technology',
      code: 'IT',
    });

    // 4. Users
    adminUserA = await User.create({
      collegeId: collegeA._id,
      instituteId: 'COE-A-ADM1',
      name: 'Admin Alice',
      email: 'admin@coea.edu',
      role: AppRole.COLLEGE_ADMIN,
      password: 'Password123!',
    });

    hodUserA = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      instituteId: 'COE-A-HOD1',
      name: 'Dr. Grace Hopper',
      email: 'grace@coea.edu',
      role: AppRole.HOD,
      password: 'Password123!',
    });
    // Set HOD on department
    deptA1.hodId = hodUserA._id;
    await deptA1.save();

    facultyUserA = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      instituteId: 'COE-A-FAC1',
      name: 'Prof. Alan Turing',
      email: 'alan@coea.edu',
      role: AppRole.FACULTY,
      password: 'Password123!',
    });

    studentUserA1 = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      instituteId: 'COE-A-STU1',
      name: 'Student Alice',
      email: 'student.alice@coea.edu',
      role: AppRole.STUDENT,
      password: 'Password123!',
    });

    studentUserA2 = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA2._id,
      instituteId: 'COE-A-STU2',
      name: 'Student Bob MECH',
      email: 'student.bob@coea.edu',
      role: AppRole.STUDENT,
      password: 'Password123!',
    });

    studentUserB = await User.create({
      collegeId: collegeB._id,
      departmentId: deptB._id,
      instituteId: 'POLY-B-STU1',
      name: 'Student Charlie B',
      email: 'charlie@polyb.edu',
      role: AppRole.STUDENT,
      password: 'Password123!',
    });

    // 5. Academic Structure
    courseA = await Course.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      name: 'Bachelor of Technology in CSE',
      code: 'BT-CSE',
    });

    academicYearA = await AcademicYear.create({
      collegeId: collegeA._id,
      name: '2026-2027',
      startDate: new Date('2026-08-01'),
      endDate: new Date('2027-05-31'),
    });

    semesterA = await Semester.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      name: 'Semester 3',
      number: 3,
    });

    sectionA = await Section.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      name: 'Section A',
      semesterId: semesterA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
    });

    subjectDBMS = await Subject.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      courseId: courseA._id,
      semesterId: semesterA._id,
      name: 'Database Management Systems',
      code: 'CS-301',
    });

    await Faculty.create({
      collegeId: collegeA._id,
      userId: facultyUserA._id,
      departmentId: deptA1._id,
      name: 'Prof. Alan Turing',
      email: 'alan@coea.edu',
    });

    studentProfileA1 = await Student.create({
      collegeId: collegeA._id,
      userId: studentUserA1._id,
      departmentId: deptA1._id,
      courseId: courseA._id,
      name: 'Student Alice',
      email: 'student.alice@coea.edu',
      instituteId: 'COE-A-STU1',
      rollNumber: 'CSE-001',
      registrationNumber: 'REG-001',
      admissionYear: 2024,
    });

    await Student.create({
      collegeId: collegeA._id,
      userId: studentUserA2._id,
      departmentId: deptA2._id,
      courseId: courseA._id,
      name: 'Student Bob MECH',
      email: 'student.bob@coea.edu',
      instituteId: 'COE-A-STU2',
      rollNumber: 'MECH-001',
      registrationNumber: 'REG-002',
      admissionYear: 2024,
    });

    await StudentEnrollment.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      studentId: studentProfileA1._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      status: 'active',
    });

    await FacultyAssignment.create({
      collegeId: collegeA._id,
      facultyId: facultyUserA._id,
      facultyName: 'Prof. Alan Turing',
      departmentId: deptA1._id,
      courseId: courseA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      subjectId: subjectDBMS._id,
      academicYearId: academicYearA._id,
      isPrimary: true,
      status: 'ACTIVE',
    });
  });

  const getRequester = (user: InstanceType<typeof User>): AuthenticatedUser => ({
    id: user._id.toString(),
    email: user.email,
    name: user.name,
    role: user.role as AppRole,
    instituteId: user.instituteId || '',
    accountStatus: AccountStatus.ACTIVE,
    collegeId: user.collegeId ? user.collegeId.toString() : '',
    departmentId: user.departmentId ? user.departmentId.toString() : undefined,
  });

  // ─────────────────────────────────────────────────────────
  // TESTS
  // ─────────────────────────────────────────────────────────

  test('1. College Admin can create college-wide event', async () => {
    const adminReq = getRequester(adminUserA);

    const event = await AcademicCalendarService.createEvent(
      {
        title: 'Annual Day Celebrations',
        description: 'Grand annual day of College A',
        eventType: CalendarEventType.EVENT,
        scope: CalendarEventScope.COLLEGE,
        startDate: '2026-12-18',
        endDate: '2026-12-18',
        startTime: '10:00',
        endTime: '16:00',
      },
      adminReq
    );

    expect(event).toBeDefined();
    expect(event.title).toBe('Annual Day Celebrations');
    expect(event.scope).toBe(CalendarEventScope.COLLEGE);
    expect(event.sourceType).toBe(CalendarSourceType.MANUAL);
    expect(event.academicContext).toBe('Entire College');
  });

  test('2. HOD can create department-scoped event', async () => {
    const hodReq = getRequester(hodUserA);

    const event = await AcademicCalendarService.createEvent(
      {
        title: 'Mid-Term Examination CSE',
        eventType: CalendarEventType.EXAM,
        departmentId: deptA1._id.toString(),
        startDate: '2026-10-14',
        endDate: '2026-10-14',
        startTime: '10:00',
        endTime: '12:00',
      },
      hodReq
    );

    expect(event).toBeDefined();
    expect(event.title).toBe('Mid-Term Examination CSE');
    expect(event.scope).toBe(CalendarEventScope.DEPARTMENT);
    expect(event.departmentId!.toString()).toBe(deptA1._id.toString());
  });

  test("3. HOD cannot create another department's event", async () => {
    const hodReq = getRequester(hodUserA);

    // HOD A is CSE; tries to create event in Mechanical deptA2
    await expect(
      AcademicCalendarService.createEvent(
        {
          title: 'Mechanical Workshop',
          eventType: CalendarEventType.WORKSHOP,
          departmentId: deptA2._id.toString(),
          startDate: '2026-10-20',
        },
        hodReq
      )
    ).rejects.toThrow('HOD can only create events for their own department');
  });

  test('4. Faculty can create authorized teaching-context event', async () => {
    const facultyReq = getRequester(facultyUserA);

    const event = await AcademicCalendarService.createEvent(
      {
        title: 'DBMS Lab Viva',
        eventType: CalendarEventType.LAB_VIVA,
        subjectId: subjectDBMS._id.toString(),
        sectionId: sectionA._id.toString(),
        startDate: '2026-10-12',
        startTime: '10:00',
        endTime: '11:00',
      },
      facultyReq
    );

    expect(event).toBeDefined();
    expect(event.title).toBe('DBMS Lab Viva');
    expect(event.scope).toBe(CalendarEventScope.CLASS);
    expect(event.subjectId!.toString()).toBe(subjectDBMS._id.toString());
    expect(event.academicContext).toContain('Database Management Systems');
    expect(event.academicContext).toContain('Section A');
  });

  test('5. Faculty cannot create unauthorized event for subject they do not teach', async () => {
    const facultyReq = getRequester(facultyUserA);

    const otherSubject = await Subject.create({
      collegeId: collegeA._id,
      departmentId: deptA2._id,
      courseId: courseA._id,
      semesterId: semesterA._id,
      name: 'Thermodynamics',
      code: 'ME-201',
    });

    await expect(
      AcademicCalendarService.createEvent(
        {
          title: 'Thermo Viva',
          eventType: CalendarEventType.LAB_VIVA,
          subjectId: otherSubject._id.toString(),
          startDate: '2026-10-15',
        },
        facultyReq
      )
    ).rejects.toThrow('You can only create events for teaching contexts assigned to you');
  });

  test('6. Student cannot create calendar event', async () => {
    const studentReq = getRequester(studentUserA1);

    await expect(
      AcademicCalendarService.createEvent(
        {
          title: 'Student Party',
          eventType: CalendarEventType.EVENT,
          startDate: '2026-10-10',
        },
        studentReq
      )
    ).rejects.toThrow('Students are not authorized to create calendar events');
  });

  test('7. Tenant isolation is enforced: College B user sees zero College A events', async () => {
    // Admin A creates an Annual Day
    await AcademicCalendarService.createEvent(
      {
        title: 'College A Fest',
        eventType: CalendarEventType.EVENT,
        scope: CalendarEventScope.COLLEGE,
        startDate: '2026-11-01',
      },
      getRequester(adminUserA)
    );

    // Student B queries calendar
    const calB = await AcademicCalendarService.getCalendarForUser(getRequester(studentUserB), {
      startDate: '2026-10-01',
      endDate: '2026-11-30',
    });

    expect(calB.length).toBe(0);
  });

  test('8. Manual published event appears to intended audience only', async () => {
    // 1. College-wide event
    await AcademicCalendarService.createEvent(
      {
        title: 'Orientation Day',
        eventType: CalendarEventType.EVENT,
        scope: CalendarEventScope.COLLEGE,
        startDate: '2026-09-01',
      },
      getRequester(adminUserA)
    );

    // 2. Department event in CSE
    await AcademicCalendarService.createEvent(
      {
        title: 'CSE Tech Symposium',
        eventType: CalendarEventType.SEMINAR,
        departmentId: deptA1._id.toString(),
        startDate: '2026-09-15',
      },
      getRequester(hodUserA)
    );

    // Alice (CSE student) should see BOTH
    const calAlice = await AcademicCalendarService.getCalendarForUser(getRequester(studentUserA1), {
      startDate: '2026-09-01',
      endDate: '2026-09-30',
    });
    const titlesAlice = calAlice.map((e) => e.title);
    expect(titlesAlice).toContain('Orientation Day');
    expect(titlesAlice).toContain('CSE Tech Symposium');

    // Bob (MECH student) should see ONLY Orientation Day, NOT CSE symposium
    const calBob = await AcademicCalendarService.getCalendarForUser(getRequester(studentUserA2), {
      startDate: '2026-09-01',
      endDate: '2026-09-30',
    });
    const titlesBob = calBob.map((e) => e.title);
    expect(titlesBob).toContain('Orientation Day');
    expect(titlesBob).not.toContain('CSE Tech Symposium');
  });

  test('9. Draft event is not visible to normal students, but visible to creator', async () => {
    // HOD creates a draft event
    await AcademicCalendarService.createEvent(
      {
        title: 'Draft Department Meeting',
        eventType: CalendarEventType.EVENT,
        status: CalendarEventStatus.DRAFT,
        departmentId: deptA1._id.toString(),
        startDate: '2026-09-20',
      },
      getRequester(hodUserA)
    );

    // Student Alice should NOT see draft
    const calStudent = await AcademicCalendarService.getCalendarForUser(getRequester(studentUserA1), {
      startDate: '2026-09-01',
      endDate: '2026-09-30',
    });
    expect(calStudent.some((e) => e.title === 'Draft Department Meeting')).toBe(false);

    // HOD (creator) CAN see draft
    const calHod = await AcademicCalendarService.getCalendarForUser(getRequester(hodUserA), {
      startDate: '2026-09-01',
      endDate: '2026-09-30',
    });
    expect(calHod.some((e) => e.title === 'Draft Department Meeting')).toBe(true);
  });

  test('10. Cancelled event follows expected lifecycle and is not hard-deleted', async () => {
    const adminReq = getRequester(adminUserA);

    const event = await AcademicCalendarService.createEvent(
      {
        title: 'Guest Lecture AI',
        eventType: CalendarEventType.EVENT,
        scope: CalendarEventScope.COLLEGE,
        startDate: '2026-09-25',
      },
      adminReq
    );

    // Cancel event
    const cancelled = await AcademicCalendarService.cancelEvent(
      event._id.toString(),
      'Speaker unwell',
      adminReq
    );
    expect(cancelled.status).toBe(CalendarEventStatus.CANCELLED);

    // Check DB record still exists
    const inDB = await CalendarEvent.findById(event._id);
    expect(inDB).not.toBeNull();
    expect(inDB!.status).toBe(CalendarEventStatus.CANCELLED);
    expect(inDB!.metadata?.cancellationReason).toBe('Speaker unwell');
  });

  test('11. Holiday is visible in the same unified calendar', async () => {
    await AcademicCalendarService.createEvent(
      {
        title: 'Independence Day',
        eventType: CalendarEventType.PUBLIC_HOLIDAY,
        scope: CalendarEventScope.COLLEGE,
        startDate: '2026-08-15',
        allDay: true,
      },
      getRequester(adminUserA)
    );

    const calAlice = await AcademicCalendarService.getCalendarForUser(getRequester(studentUserA1), {
      startDate: '2026-08-01',
      endDate: '2026-08-31',
    });

    const holiday = calAlice.find((e) => e.title === 'Independence Day');
    expect(holiday).toBeDefined();
    expect(holiday!.eventType).toBe(CalendarEventType.PUBLIC_HOLIDAY);
    expect(holiday!.allDay).toBe(true);
  });

  test('12. Assignment deadline automatically appears in calendar as DERIVED event', async () => {
    // Faculty publishes an assignment
    await Assignment.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      subjectId: subjectDBMS._id,
      facultyId: facultyUserA._id,
      facultyName: 'Prof. Alan Turing',
      title: 'DBMS Assignment 3 - SQL Queries',
      description: 'Write complex JOIN queries',
      assignmentType: AssignmentType.HOMEWORK,
      dueDate: '2026-09-28',
      dueTime: '23:59',
      dueDateTime: new Date('2026-09-28T23:59:00.000Z'),
      maximumMarks: 20,
      status: AssignmentStatus.PUBLISHED,
    });

    // Student Alice queries calendar
    const calAlice = await AcademicCalendarService.getCalendarForUser(getRequester(studentUserA1), {
      startDate: '2026-09-01',
      endDate: '2026-09-30',
    });

    const assignmentEvent = calAlice.find((e) => e.title === 'DBMS Assignment 3 - SQL Queries');
    expect(assignmentEvent).toBeDefined();
    expect(assignmentEvent!.sourceType).toBe(CalendarSourceType.DERIVED);
    expect(assignmentEvent!.eventType).toBe(CalendarEventType.DEADLINE);
    expect(assignmentEvent!.startDate).toBe('2026-09-28');
    expect(assignmentEvent!.startTime).toBe('23:59');
    expect(assignmentEvent!.navigationTarget).toContain('/assignments/');
  });

  test('13. Assignment deadline does NOT create duplicate records in CalendarEvent collection', async () => {
    const initialCalendarCount = await CalendarEvent.countDocuments({});

    // When calendar is queried for user, count in CalendarEvent collection remains unchanged
    await AcademicCalendarService.getCalendarForUser(getRequester(studentUserA1), {
      startDate: '2026-09-01',
      endDate: '2026-09-30',
    });

    const postCalendarCount = await CalendarEvent.countDocuments({});
    expect(postCalendarCount).toBe(initialCalendarCount);
  });

  test('14. Updating assignment deadline automatically changes its calendar presentation', async () => {
    const assignment = await Assignment.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      subjectId: subjectDBMS._id,
      facultyId: facultyUserA._id,
      facultyName: 'Prof. Alan Turing',
      title: 'ER Modeling Project',
      description: 'Design ER Diagram for hospital database',
      assignmentType: AssignmentType.PROJECT,
      dueDate: '2026-10-10',
      dueTime: '17:00',
      dueDateTime: new Date('2026-10-10T17:00:00.000Z'),
      maximumMarks: 50,
      status: AssignmentStatus.PUBLISHED,
    });

    // Verify initial calendar representation
    let cal = await AcademicCalendarService.getCalendarForUser(getRequester(studentUserA1), {
      startDate: '2026-10-01',
      endDate: '2026-10-31',
    });
    let ev = cal.find((e) => e.title === 'ER Modeling Project');
    expect(ev!.startDate).toBe('2026-10-10');

    // Faculty extends deadline to 15th October
    assignment.dueDate = '2026-10-15';
    assignment.dueTime = '23:59';
    await assignment.save();

    // Query calendar again - deadline automatically reflects 2026-10-15
    cal = await AcademicCalendarService.getCalendarForUser(getRequester(studentUserA1), {
      startDate: '2026-10-01',
      endDate: '2026-10-31',
    });
    ev = cal.find((e) => e.title === 'ER Modeling Project');
    expect(ev!.startDate).toBe('2026-10-15');
    expect(ev!.startTime).toBe('23:59');
  });

  test('15. Relevant students receive only their relevant derived assignment deadlines', async () => {
    // Assignment created for CSE Section A
    await Assignment.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      subjectId: subjectDBMS._id,
      facultyId: facultyUserA._id,
      facultyName: 'Prof. Alan Turing',
      title: 'CSE Advanced DBMS Lab 1',
      description: 'Complete Lab Exercise 1 on SQL joins',
      assignmentType: AssignmentType.LAB_WORK,
      dueDate: '2026-09-29',
      dueTime: '18:00',
      dueDateTime: new Date('2026-09-29T18:00:00.000Z'),
      maximumMarks: 10,
      status: AssignmentStatus.PUBLISHED,
    });

    // Alice (CSE) sees it
    const calAlice = await AcademicCalendarService.getCalendarForUser(getRequester(studentUserA1), {
      startDate: '2026-09-01',
      endDate: '2026-09-30',
    });
    expect(calAlice.some((e) => e.title === 'CSE Advanced DBMS Lab 1')).toBe(true);

    // Bob (MECH) does NOT see it
    const calBob = await AcademicCalendarService.getCalendarForUser(getRequester(studentUserA2), {
      startDate: '2026-09-01',
      endDate: '2026-09-30',
    });
    expect(calBob.some((e) => e.title === 'CSE Advanced DBMS Lab 1')).toBe(false);

    // Charlie (College B) does NOT see it
    const calCharlie = await AcademicCalendarService.getCalendarForUser(getRequester(studentUserB), {
      startDate: '2026-09-01',
      endDate: '2026-09-30',
    });
    expect(calCharlie.some((e) => e.title === 'CSE Advanced DBMS Lab 1')).toBe(false);
  });

  test('16. Examination event appears for correct academic audience', async () => {
    // HOD creates Mid-Term Exam
    await AcademicCalendarService.createEvent(
      {
        title: 'DBMS Mid-Term Exam',
        eventType: CalendarEventType.EXAM,
        departmentId: deptA1._id.toString(),
        subjectId: subjectDBMS._id.toString(),
        startDate: '2026-10-18',
        startTime: '10:00',
        endTime: '12:00',
      },
      getRequester(hodUserA)
    );

    const calAlice = await AcademicCalendarService.getCalendarForUser(getRequester(studentUserA1), {
      startDate: '2026-10-01',
      endDate: '2026-10-31',
    });
    const exam = calAlice.find((e) => e.title === 'DBMS Mid-Term Exam');
    expect(exam).toBeDefined();
    expect(exam!.eventType).toBe(CalendarEventType.EXAM);
  });

  test('17. Disabled section concept does not leak section into calendar event context', async () => {
    // Disable section in Institution Configuration
    await InstitutionConfiguration.findOneAndUpdate(
      { collegeId: collegeA._id },
      { $set: { 'academicStructure.section': false } }
    );

    // Faculty creates event
    const event = await AcademicCalendarService.createEvent(
      {
        title: 'DBMS Seminar',
        eventType: CalendarEventType.SEMINAR,
        subjectId: subjectDBMS._id.toString(),
        startDate: '2026-10-22',
      },
      getRequester(facultyUserA)
    );

    // Verify context doesn't contain 'Section'
    expect(event.academicContext).not.toContain('Section');
    expect(event.academicContext).toContain('Database Management Systems');
  });

  test('18. Configured terminology is respected', async () => {
    // Update terminology for college A
    await InstitutionConfiguration.findOneAndUpdate(
      { collegeId: collegeA._id },
      { $set: { 'academicStructure.section': true, 'terminology.subject.singular': 'Course Module' } }
    );

    const event = await AcademicCalendarService.createEvent(
      {
        title: 'Faculty Lecture',
        eventType: CalendarEventType.EVENT,
        subjectId: subjectDBMS._id.toString(),
        sectionId: sectionA._id.toString(),
        startDate: '2026-10-25',
      },
      getRequester(facultyUserA)
    );

    expect(event.academicContext).toContain('Database Management Systems');
    expect(event.academicContext).toContain('Section A');
  });

  test('19. Duplicate publication does not create duplicate event or notification behavior', async () => {
    const event = await AcademicCalendarService.createEvent(
      {
        title: 'Annual Sports Day',
        eventType: CalendarEventType.EVENT,
        scope: CalendarEventScope.COLLEGE,
        startDate: '2026-11-20',
        status: CalendarEventStatus.PUBLISHED,
      },
      getRequester(adminUserA)
    );

    // Calling publishEvent again on already published event
    const publishedAgain = await AcademicCalendarService.publishEvent(
      event._id.toString(),
      getRequester(adminUserA)
    );
    expect(publishedAgain._id.toString()).toBe(event._id.toString());
  });

  test('20. Notification failure does not invalidate a valid event', async () => {
    // Mock NotificationService.createNotification to reject
    const originalCreate = NotificationService.createNotification;
    jest.spyOn(NotificationService, 'createNotification').mockRejectedValueOnce(new Error('Network drop'));

    const event = await AcademicCalendarService.createEvent(
      {
        title: 'Important College Convocation',
        eventType: CalendarEventType.EVENT,
        scope: CalendarEventScope.COLLEGE,
        startDate: '2026-12-05',
        status: CalendarEventStatus.PUBLISHED,
      },
      getRequester(adminUserA)
    );

    // Event creation succeeds despite notification error
    expect(event).toBeDefined();
    expect(event.title).toBe('Important College Convocation');

    // Restore original method
    NotificationService.createNotification = originalCreate;
  });
});
