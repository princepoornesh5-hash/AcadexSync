import request from 'supertest';
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
  Student,
  Faculty,
  AttendanceSession,
  AttendanceRecord,
  Timetable,
  Note,
  AuditLog,
} from '../../src/models';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';
import { AppRole } from '../../src/constants/roles';
import {
  AttendanceStatus,
  AttendanceSessionStatus,
  TimetableStatus,
  NoteStatus,
  NoteType,
  NoteVisibility,
  NoteLifecycleState,
  ResourceType,
} from '../../src/constants/status';

describe('ACADEX Phase 9N.1 — Reports & Analytics Engine Integration Tests', () => {
  let collegeA: any;
  let collegeB: any;
  let deptA1: any;
  let deptA2: any;
  let courseA: any;
  let yearA: any;
  let semA: any;
  let secA1: any;
  let subjectA1: any;
  let subjectA2: any;

  let superAdminUser: any;
  let collegeAdminUserA: any;
  let collegeAdminUserB: any;
  let hodUserA1: any;
  let hodUserA2: any;
  let facultyUserA: any;
  let facultyDocA: any;
  let studentUserA1: any;
  let studentDocA1: any;
  let studentUserA2: any;
  let studentDocA2: any;

  beforeAll(async () => {
    await setupTestDB();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();

    // 1. Setup Colleges
    collegeA = await College.create({
      name: 'College of Engineering A',
      code: 'COEA',
      address: '123 Tech Lane',
      email: 'admin@coea.edu',
      phone: '+1-555-0100',
      principal: 'Dr. Principal A',
      status: 'active',
      isActive: true,
    });

    collegeB = await College.create({
      name: 'College of Arts B',
      code: 'COAB',
      address: '456 Arts Blvd',
      email: 'admin@coab.edu',
      phone: '+1-555-0200',
      principal: 'Dr. Principal B',
      status: 'active',
      isActive: true,
    });

    // 2. Setup Departments in College A
    deptA1 = await Department.create({
      collegeId: collegeA._id,
      name: 'Computer Science',
      code: 'CSE',
      isActive: true,
    });

    deptA2 = await Department.create({
      collegeId: collegeA._id,
      name: 'Mechanical Engineering',
      code: 'MECH',
      isActive: true,
    });

    // Department in College B
    await Department.create({
      collegeId: collegeB._id,
      name: 'Fine Arts',
      code: 'FA',
      isActive: true,
    });

    // 3. Academic Hierarchy
    courseA = await Course.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      name: 'B.Tech CSE',
      code: 'BTCSE',
      durationYears: 4,
      totalSemesters: 8,
      isActive: true,
    });

    yearA = await AcademicYear.create({
      collegeId: collegeA._id,
      name: '2026-2027',
      startDate: new Date('2026-08-01'),
      endDate: new Date('2027-05-31'),
      isCurrent: true,
    });

    semA = await Semester.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      courseId: courseA._id,
      academicYearId: yearA._id,
      number: 5,
      name: 'Semester 5',
      startDate: new Date('2026-08-01'),
      endDate: new Date('2026-12-31'),
      isActive: true,
    });

    secA1 = await Section.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      courseId: courseA._id,
      semesterId: semA._id,
      name: 'Section A',
      capacity: 60,
      isActive: true,
    });

    await Section.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      courseId: courseA._id,
      semesterId: semA._id,
      name: 'Section B',
      capacity: 60,
      isActive: true,
    });

    subjectA1 = await Subject.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      courseId: courseA._id,
      semesterId: semA._id,
      name: 'Operating Systems',
      code: 'CS501',
      credits: 4,
      isActive: true,
    });

    subjectA2 = await Subject.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      courseId: courseA._id,
      semesterId: semA._id,
      name: 'Database Management',
      code: 'CS502',
      credits: 4,
      isActive: true,
    });

    // 4. Users & Profiles
    superAdminUser = await User.create({
      instituteId: 'SUPER-001',
      name: 'Global Super Admin',
      email: 'superadmin@acadex.edu',
      role: AppRole.SUPER_ADMIN,
      status: 'active',
    });

    collegeAdminUserA = await User.create({
      collegeId: collegeA._id,
      instituteId: 'ADMIN-COEA-001',
      name: 'College Admin A',
      email: 'admin@coea.edu',
      role: AppRole.COLLEGE_ADMIN,
      status: 'active',
    });

    collegeAdminUserB = await User.create({
      collegeId: collegeB._id,
      instituteId: 'ADMIN-COAB-001',
      name: 'College Admin B',
      email: 'admin@coab.edu',
      role: AppRole.COLLEGE_ADMIN,
      status: 'active',
    });

    hodUserA1 = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      instituteId: 'HOD-CSE-001',
      name: 'HOD CSE',
      email: 'hod.cse@coea.edu',
      role: AppRole.HOD,
      status: 'active',
    });

    hodUserA2 = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA2._id,
      instituteId: 'HOD-MECH-001',
      name: 'HOD MECH',
      email: 'hod.mech@coea.edu',
      role: AppRole.HOD,
      status: 'active',
    });

    facultyUserA = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      instituteId: 'FAC-CSE-001',
      name: 'Prof. Alan Turing',
      email: 'alan@coea.edu',
      role: AppRole.FACULTY,
      status: 'active',
    });

    facultyDocA = await Faculty.create({
      userId: facultyUserA._id,
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      name: 'Prof. Alan Turing',
      email: 'alan@coea.edu',
      instituteId: 'FAC-CSE-001',
      designation: 'Professor',
      subjectIds: [subjectA1._id, subjectA2._id],
      sectionIds: [secA1._id],
      status: 'active',
      isActive: true,
    });

    studentUserA1 = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      instituteId: 'STU-001',
      name: 'Alice Student',
      email: 'alice@coea.edu',
      role: AppRole.STUDENT,
      status: 'active',
    });

    studentDocA1 = await Student.create({
      userId: studentUserA1._id,
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      courseId: courseA._id,
      academicYearId: yearA._id,
      semesterId: semA._id,
      sectionId: secA1._id,
      name: 'Alice Student',
      email: 'alice@coea.edu',
      studentIdNumber: 'STU-001',
      rollNumber: 'CSE-01',
      status: 'active',
      isActive: true,
    });

    studentUserA2 = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      instituteId: 'STU-002',
      name: 'Bob Student',
      email: 'bob@coea.edu',
      role: AppRole.STUDENT,
      status: 'active',
    });

    studentDocA2 = await Student.create({
      userId: studentUserA2._id,
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      courseId: courseA._id,
      academicYearId: yearA._id,
      semesterId: semA._id,
      sectionId: secA1._id,
      name: 'Bob Student',
      email: 'bob@coea.edu',
      studentIdNumber: 'STU-002',
      rollNumber: 'CSE-02',
      status: 'active',
      isActive: true,
    });

    // 5. Populate Sample Attendance Sessions & Records
    // Session 1: OS (Alice Present, Bob Absent)
    const session1 = await AttendanceSession.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      courseId: courseA._id,
      semesterId: semA._id,
      sectionId: secA1._id,
      sectionName: 'Section A',
      subjectId: subjectA1._id,
      subjectName: 'Operating Systems',
      facultyId: facultyDocA._id,
      timeSlot: '09:00 - 10:00',
      date: new Date(),
      status: AttendanceSessionStatus.CLOSED,
      isLocked: true,
      records: [],
      recordsCount: 2,
    });

    await AttendanceRecord.create([
      {
        sessionId: session1._id,
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        courseId: courseA._id,
        semesterId: semA._id,
        sectionId: secA1._id,
        subjectId: subjectA1._id,
        facultyId: facultyDocA._id,
        studentId: studentDocA1._id,
        studentName: studentDocA1.name,
        rollNumber: studentDocA1.rollNumber,
        date: new Date(),
        timeSlot: '09:00 - 10:00',
        status: AttendanceStatus.PRESENT,
      },
      {
        sessionId: session1._id,
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        courseId: courseA._id,
        semesterId: semA._id,
        sectionId: secA1._id,
        subjectId: subjectA1._id,
        facultyId: facultyDocA._id,
        studentId: studentDocA2._id,
        studentName: studentDocA2.name,
        rollNumber: studentDocA2.rollNumber,
        date: new Date(),
        timeSlot: '09:00 - 10:00',
        status: AttendanceStatus.ABSENT,
      },
    ]);

    // Session 2: OS (Alice Late, Bob Present)
    const session2 = await AttendanceSession.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      courseId: courseA._id,
      semesterId: semA._id,
      sectionId: secA1._id,
      sectionName: 'Section A',
      subjectId: subjectA1._id,
      subjectName: 'Operating Systems',
      facultyId: facultyDocA._id,
      timeSlot: '10:00 - 11:00',
      date: new Date(),
      status: AttendanceSessionStatus.CLOSED,
      isLocked: true,
      records: [],
      recordsCount: 2,
    });

    await AttendanceRecord.create([
      {
        sessionId: session2._id,
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        courseId: courseA._id,
        semesterId: semA._id,
        sectionId: secA1._id,
        subjectId: subjectA1._id,
        facultyId: facultyDocA._id,
        studentId: studentDocA1._id,
        studentName: studentDocA1.name,
        rollNumber: studentDocA1.rollNumber,
        date: new Date(),
        timeSlot: '10:00 - 11:00',
        status: AttendanceStatus.LATE,
      },
      {
        sessionId: session2._id,
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        courseId: courseA._id,
        semesterId: semA._id,
        sectionId: secA1._id,
        subjectId: subjectA1._id,
        facultyId: facultyDocA._id,
        studentId: studentDocA2._id,
        studentName: studentDocA2.name,
        rollNumber: studentDocA2.rollNumber,
        date: new Date(),
        timeSlot: '10:00 - 11:00',
        status: AttendanceStatus.PRESENT,
      },
    ]);

    // Session 3: Cancelled session (should be excluded from attendance percentages)
    const session3 = await AttendanceSession.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      courseId: courseA._id,
      semesterId: semA._id,
      sectionId: secA1._id,
      sectionName: 'Section A',
      subjectId: subjectA1._id,
      subjectName: 'Operating Systems',
      facultyId: facultyDocA._id,
      timeSlot: '11:00 - 12:00',
      date: new Date(),
      status: AttendanceSessionStatus.CANCELLED,
      isLocked: true,
      records: [],
      recordsCount: 2,
    });

    await AttendanceRecord.create([
      {
        sessionId: session3._id,
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        courseId: courseA._id,
        semesterId: semA._id,
        sectionId: secA1._id,
        subjectId: subjectA1._id,
        facultyId: facultyDocA._id,
        studentId: studentDocA1._id,
        studentName: studentDocA1.name,
        rollNumber: studentDocA1.rollNumber,
        date: new Date(),
        timeSlot: '11:00 - 12:00',
        status: AttendanceStatus.ABSENT,
        isCancelled: true,
      },
    ]);

    // 6. Notes & Timetable
    await Note.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      courseId: courseA._id,
      semesterId: semA._id,
      sectionId: secA1._id,
      subjectId: subjectA1._id,
      facultyId: facultyDocA._id,
      authorUserId: facultyUserA._id,
      title: 'OS Lecture Notes 1',
      description: 'Introduction to Processes',
      noteType: NoteType.CHAPTER,
      visibility: NoteVisibility.SECTION_ONLY,
      lifecycleState: NoteLifecycleState.READY,
      resourceType: ResourceType.FILE_ATTACHMENT,
      storageProvider: 'imagekit',
      originalFileName: 'os1.pdf',
      storageKey: 'notes/collegeA/os1.pdf',
      fileExtension: 'pdf',
      fileUrl: 'https://ik.imagekit.io/AcadexAi/notes/os1.pdf',
      fileId: 'ik_os_1',
      fileSize: 1024 * 1024 * 2, // 2MB
      mimeType: 'application/pdf',
      status: NoteStatus.PUBLISHED,
    });

    await Timetable.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      courseId: courseA._id,
      semesterId: semA._id,
      sectionId: secA1._id,
      academicYearId: yearA._id,
      name: 'CSE Section A Timetable',
      status: TimetableStatus.PUBLISHED,
    });
  });

  // =========================================================================
  // 1. DASHBOARD ANALYTICS TESTS
  // =========================================================================

  test('1. Super Admin retrieves global dashboard with cross-college comparison', async () => {
    const authHeader = createTestAuthHeader({
      role: AppRole.SUPER_ADMIN,
      userId: superAdminUser.id,
      collegeId: 'global',
    });

    const res = await request(app)
      .get('/api/v1/reports/dashboard')
      .set(authHeader);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.role).toBe(AppRole.SUPER_ADMIN);
    expect(res.body.data.metrics.totalColleges).toBe(2);
    expect(res.body.data.metrics.totalStudents).toBe(2);
    expect(res.body.data.metrics.totalFaculty).toBe(1);
    expect(res.body.data.metrics.totalHODs).toBe(2);
    expect(res.body.data.metrics.systemAttendancePercentage).toBe(75); // 3 attended out of 4 non-cancelled records
    expect(res.body.data.recentActivity).toHaveLength(2); // College A and College B comparison
  });

  test('2. College Admin retrieves college-scoped dashboard with department breakdown', async () => {
    const authHeader = createTestAuthHeader({
      role: AppRole.COLLEGE_ADMIN,
      userId: collegeAdminUserA.id,
      collegeId: collegeA.id,
    });

    const res = await request(app)
      .get('/api/v1/reports/dashboard')
      .set(authHeader);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.role).toBe(AppRole.COLLEGE_ADMIN);
    expect(res.body.data.metrics.departmentsCount).toBe(2);
    expect(res.body.data.metrics.studentsCount).toBe(2);
    expect(res.body.data.metrics.collegeAttendancePercentage).toBe(75);
    expect(res.body.data.recentActivity).toHaveLength(2); // CSE and MECH departments
  });

  test('3. HOD retrieves department-scoped dashboard with section breakdown', async () => {
    const authHeader = createTestAuthHeader({
      role: AppRole.HOD,
      userId: hodUserA1.id,
      collegeId: collegeA.id,
      departmentId: deptA1.id,
    });

    const res = await request(app)
      .get('/api/v1/reports/dashboard')
      .set(authHeader);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.role).toBe(AppRole.HOD);
    expect(res.body.data.metrics.studentsCount).toBe(2);
    expect(res.body.data.metrics.sectionsCount).toBe(2);
    expect(res.body.data.metrics.departmentAttendancePercentage).toBe(75);
  });

  test('4. Faculty retrieves personal dashboard with conducted sessions & attendance rate', async () => {
    const authHeader = createTestAuthHeader({
      role: AppRole.FACULTY,
      userId: facultyUserA.id,
      collegeId: collegeA.id,
      departmentId: deptA1.id,
    });

    const res = await request(app)
      .get('/api/v1/reports/dashboard')
      .set(authHeader);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.role).toBe(AppRole.FACULTY);
    expect(res.body.data.metrics.conductedSessionsCount).toBe(2); // Excludes cancelled session
    expect(res.body.data.metrics.overallAttendanceRate).toBe(75);
    expect(res.body.data.metrics.notesPublishedCount).toBe(1);
  });

  test('5. Student retrieves personal dashboard with personal attendance rate', async () => {
    const authHeader = createTestAuthHeader({
      role: AppRole.STUDENT,
      userId: studentUserA1.id,
      collegeId: collegeA.id,
      departmentId: deptA1.id,
    });

    const res = await request(app)
      .get('/api/v1/reports/dashboard')
      .set(authHeader);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.role).toBe(AppRole.STUDENT);
    // Alice had 1 Present + 1 Late = 2/2 = 100%
    expect(res.body.data.metrics.totalClasses).toBe(2);
    expect(res.body.data.metrics.present).toBe(1);
    expect(res.body.data.metrics.late).toBe(1);
    expect(res.body.data.metrics.percentage).toBe(100);
    expect(res.body.data.metrics.availableNotesCount).toBe(1);
  });

  // =========================================================================
  // 2. ATTENDANCE REPORT & CALCULATION TESTS
  // =========================================================================

  test('6. Student retrieves personal attendance report via /attendance/me', async () => {
    const authHeader = createTestAuthHeader({
      role: AppRole.STUDENT,
      userId: studentUserA1.id,
      collegeId: collegeA.id,
      departmentId: deptA1.id,
    });

    const res = await request(app)
      .get('/api/v1/reports/attendance/me')
      .set(authHeader);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.student.name).toBe('Alice Student');
    expect(res.body.data.summary.totalClasses).toBe(2);
    expect(res.body.data.summary.percentage).toBe(100);
    expect(res.body.data.lowAttendanceAlert).toBe(false);
    expect(res.body.data.subjectsBreakdown).toHaveLength(1);
    expect(res.body.data.subjectsBreakdown[0].subjectName).toBe('Operating Systems');
    expect(res.body.data.subjectsBreakdown[0].percentage).toBe(100);
  });

  test('7. Bob Student has 50% attendance and receives low attendance alert (<75%)', async () => {
    const authHeader = createTestAuthHeader({
      role: AppRole.STUDENT,
      userId: studentUserA2.id,
      collegeId: collegeA.id,
      departmentId: deptA1.id,
    });

    const res = await request(app)
      .get('/api/v1/reports/attendance/me')
      .set(authHeader);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    // Bob had 1 Absent + 1 Present = 1/2 = 50%
    expect(res.body.data.summary.totalClasses).toBe(2);
    expect(res.body.data.summary.present).toBe(1);
    expect(res.body.data.summary.absent).toBe(1);
    expect(res.body.data.summary.percentage).toBe(50);
    expect(res.body.data.lowAttendanceAlert).toBe(true);
  });

  test('8. Date range filters correctly bound report results', async () => {
    const authHeader = createTestAuthHeader({
      role: AppRole.STUDENT,
      userId: studentUserA1.id,
      collegeId: collegeA.id,
      departmentId: deptA1.id,
    });

    const res = await request(app)
      .get('/api/v1/reports/attendance/me?preset=today')
      .set(authHeader);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.summary.totalClasses).toBe(2);
  });

  test('9. Section attendance report ranks students and identifies low-attendance count', async () => {
    const authHeader = createTestAuthHeader({
      role: AppRole.HOD,
      userId: hodUserA1.id,
      collegeId: collegeA.id,
      departmentId: deptA1.id,
    });

    const res = await request(app)
      .get(`/api/v1/reports/attendance/section/${secA1.id}`)
      .set(authHeader);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.summary.totalSessions).toBe(2);
    expect(res.body.data.summary.percentage).toBe(75);
    expect(res.body.data.students).toHaveLength(2);
    // Alice (100%) ranked before Bob (50%)
    expect(res.body.data.students[0].name).toBe('Alice Student');
    expect(res.body.data.students[0].percentage).toBe(100);
    expect(res.body.data.students[1].name).toBe('Bob Student');
    expect(res.body.data.students[1].percentage).toBe(50);
    expect(res.body.data.lowAttendanceCount).toBe(1); // Bob is <75%
  });

  test('10. Department attendance report aggregates sections and subjects comparison', async () => {
    const authHeader = createTestAuthHeader({
      role: AppRole.HOD,
      userId: hodUserA1.id,
      collegeId: collegeA.id,
      departmentId: deptA1.id,
    });

    const res = await request(app)
      .get(`/api/v1/reports/attendance/department/${deptA1.id}`)
      .set(authHeader);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.department.name).toBe('Computer Science');
    expect(res.body.data.summary.percentage).toBe(75);
    expect(res.body.data.sectionsComparison).toHaveLength(2);
    expect(res.body.data.subjectsComparison).toHaveLength(2);
    expect(res.body.data.lowAttendanceStudentsCount).toBe(1);
  });

  test('11. College attendance report compares all departments', async () => {
    const authHeader = createTestAuthHeader({
      role: AppRole.COLLEGE_ADMIN,
      userId: collegeAdminUserA.id,
      collegeId: collegeA.id,
    });

    const res = await request(app)
      .get(`/api/v1/reports/attendance/college/${collegeA.id}`)
      .set(authHeader);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.college.name).toBe('College of Engineering A');
    expect(res.body.data.departmentComparison).toHaveLength(2);
    expect(res.body.data.totalSessionsConducted).toBe(2);
  });

  test('12. Subject attendance report returns section-wise attendance breakdown', async () => {
    const authHeader = createTestAuthHeader({
      role: AppRole.HOD,
      userId: hodUserA1.id,
      collegeId: collegeA.id,
      departmentId: deptA1.id,
    });

    const res = await request(app)
      .get(`/api/v1/reports/attendance/subject/${subjectA1.id}`)
      .set(authHeader);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.subject.name).toBe('Operating Systems');
    expect(res.body.data.summary.percentage).toBe(75);
    expect(res.body.data.sectionsBreakdown).toHaveLength(1);
    expect(res.body.data.sectionsBreakdown[0].attendancePercentage).toBe(75);
  });

  // =========================================================================
  // 3. FACULTY & ACADEMIC & NOTES REPORT TESTS
  // =========================================================================

  test('13. Faculty activity report provides conducted classes and students taught', async () => {
    const authHeader = createTestAuthHeader({
      role: AppRole.FACULTY,
      userId: facultyUserA.id,
      collegeId: collegeA.id,
      departmentId: deptA1.id,
    });

    const res = await request(app)
      .get(`/api/v1/reports/faculty/${facultyDocA.id}`)
      .set(authHeader);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.faculty.name).toBe('Prof. Alan Turing');
    expect(res.body.data.conductedSessionsCount).toBe(2);
    expect(res.body.data.overallAttendanceRate).toBe(75);
    expect(res.body.data.uniqueStudentsTaught).toBe(2);
    expect(res.body.data.subjectsBreakdown).toHaveLength(1);
    expect(res.body.data.sectionsBreakdown).toHaveLength(1);
  });

  test('14. Academic hierarchy report provides enrollment capacity and timetable coverage', async () => {
    const authHeader = createTestAuthHeader({
      role: AppRole.COLLEGE_ADMIN,
      userId: collegeAdminUserA.id,
      collegeId: collegeA.id,
    });

    const res = await request(app)
      .get('/api/v1/reports/academic')
      .set(authHeader);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.summary.totalDepartments).toBe(2);
    expect(res.body.data.summary.totalSections).toBe(2);
    expect(res.body.data.summary.totalStudents).toBe(2);
    expect(res.body.data.enrollmentCapacity.totalCapacity).toBe(120); // 2 sections * 60 capacity
    expect(res.body.data.enrollmentCapacity.totalEnrolled).toBe(2);
    expect(res.body.data.timetableCoverage.publishedTimetables).toBe(1);
    expect(res.body.data.timetableCoverage.totalSections).toBe(2);
    expect(res.body.data.timetableCoverage.coveragePercentage).toBe(50); // 1 out of 2 sections published
  });

  test('15. Notes analytics report provides note volume, storage bytes, and subject distribution', async () => {
    const authHeader = createTestAuthHeader({
      role: AppRole.COLLEGE_ADMIN,
      userId: collegeAdminUserA.id,
      collegeId: collegeA.id,
    });

    const res = await request(app)
      .get('/api/v1/reports/notes')
      .set(authHeader);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.summary.totalNotes).toBe(1);
    expect(res.body.data.summary.publishedNotes).toBe(1);
    expect(res.body.data.summary.totalStorageBytes).toBe(1024 * 1024 * 2);
    expect(res.body.data.bySubject).toHaveLength(1);
    expect(res.body.data.bySubject[0].subjectName).toBe('Operating Systems');
    expect(res.body.data.recentNotes).toHaveLength(1);
  });

  // =========================================================================
  // 4. SECURITY & TENANT ISOLATION TESTS
  // =========================================================================

  test('16. Cross-college access is rejected (College Admin B cannot access College A reports)', async () => {
    const authHeaderB = createTestAuthHeader({
      role: AppRole.COLLEGE_ADMIN,
      userId: collegeAdminUserB.id,
      collegeId: collegeB.id,
    });

    const res = await request(app)
      .get(`/api/v1/reports/attendance/college/${collegeA.id}`)
      .set(authHeaderB);

    expect(res.status).toBe(403);
    expect(res.body.success).toBe(false);
  });

  test('17. Cross-department access is rejected (HOD MECH cannot access CSE department report)', async () => {
    const authHeaderMech = createTestAuthHeader({
      role: AppRole.HOD,
      userId: hodUserA2.id,
      collegeId: collegeA.id,
      departmentId: deptA2.id,
    });

    const res = await request(app)
      .get(`/api/v1/reports/attendance/department/${deptA1.id}`)
      .set(authHeaderMech);

    expect(res.status).toBe(403);
    expect(res.body.success).toBe(false);
  });

  test('18. Cross-student access is rejected (Student Alice cannot view Student Bob report)', async () => {
    const authHeaderAlice = createTestAuthHeader({
      role: AppRole.STUDENT,
      userId: studentUserA1.id,
      collegeId: collegeA.id,
      departmentId: deptA1.id,
    });

    const res = await request(app)
      .get(`/api/v1/reports/attendance/student/${studentDocA2.id}`)
      .set(authHeaderAlice);

    expect(res.status).toBe(403);
    expect(res.body.success).toBe(false);
  });

  test('19. Students cannot access administrative section reports', async () => {
    const authHeaderAlice = createTestAuthHeader({
      role: AppRole.STUDENT,
      userId: studentUserA1.id,
      collegeId: collegeA.id,
      departmentId: deptA1.id,
    });

    const res = await request(app)
      .get(`/api/v1/reports/attendance/section/${secA1.id}`)
      .set(authHeaderAlice);

    expect(res.status).toBe(403);
    expect(res.body.success).toBe(false);
  });

  test('20. Audit log is created for report generation without sensitive credentials', async () => {
    const authHeader = createTestAuthHeader({
      role: AppRole.SUPER_ADMIN,
      userId: superAdminUser.id,
      collegeId: 'global',
    });

    await request(app)
      .get('/api/v1/reports/academic')
      .set(authHeader);

    const logs = await AuditLog.find({ action: 'REPORT_GENERATED' });
    expect(logs.length).toBeGreaterThan(0);
    const lastLog = logs[logs.length - 1];
    expect(lastLog.actorUserId.toString()).toBe(superAdminUser.id);
    expect(lastLog.entityType).toBe('Report');
    // Ensure no passwords or private keys logged
    const logStr = JSON.stringify(lastLog);
    expect(logStr).not.toContain('password');
    expect(logStr).not.toContain('privateKey');
  });
});
