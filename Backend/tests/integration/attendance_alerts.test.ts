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
import { AttendanceRecord } from '../../src/models/attendanceRecord.model';
import { Notification } from '../../src/models/notification.model';
import { InstitutionConfiguration } from '../../src/models/institutionConfiguration.model';
import { AppRole } from '../../src/constants/roles';
import {
  AttendanceStatus,
  AccountStatus,
} from '../../src/constants/status';
import { NotificationType, NotificationPriority } from '../../src/constants/notification.constants';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { AttendanceService } from '../../src/services/attendance.service';
import { NotificationService } from '../../src/services/notification.service';
import { AuthenticatedUser } from '../../src/types/auth.types';

describe('Prompt 22 — Attendance Alerts Integration Tests', () => {
  let collegeA: InstanceType<typeof College>;
  let collegeB: InstanceType<typeof College>;

  let facultyUserA: InstanceType<typeof User>;
  let studentUserA1: InstanceType<typeof User>;
  let studentUserA2: InstanceType<typeof User>;
  let studentUserB: InstanceType<typeof User>;

  let deptA: InstanceType<typeof Department>;
  let courseA: InstanceType<typeof Course>;
  let academicYearA: InstanceType<typeof AcademicYear>;
  let semesterA: InstanceType<typeof Semester>;
  let sectionA: InstanceType<typeof Section>;
  let subjectDBMS: InstanceType<typeof Subject>;

  let facultyProfileA: InstanceType<typeof Faculty>;
  let studentProfileA1: InstanceType<typeof Student>;
  let studentProfileA2: InstanceType<typeof Student>;

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

    // 2. Default Institution Configuration for College A
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
        building: { singular: 'Building', plural: 'Buildings' },
        room: { singular: 'Room', plural: 'Rooms' },
      },
      attendanceAlerts: {
        enabled: true,
        warningPercentage: 75,
        criticalPercentage: 65,
        absenceAlertsEnabled: true,
      },
      isConfigured: true,
    });

    // 3. Academic Structure for College A
    deptA = await Department.create({
      collegeId: collegeA._id,
      name: 'Computer Science',
      code: 'CSE',
    });

    courseA = await Course.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'B.Tech Computer Science',
      code: 'BT-CSE',
    });

    academicYearA = await AcademicYear.create({
      collegeId: collegeA._id,
      name: '2025-2026',
      startDate: new Date('2025-08-01'),
      endDate: new Date('2026-05-31'),
    });

    semesterA = await Semester.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      name: 'Semester 3',
      number: 3,
    });

    // 4. Create Users
    facultyUserA = await User.create({
      collegeId: collegeA._id,
      instituteId: 'COE-A-FAC1',
      name: 'Prof. Alan Turing',
      email: 'alan@coea.edu',
      role: AppRole.FACULTY,
      password: 'Password123!',
    });

    studentUserA1 = await User.create({
      collegeId: collegeA._id,
      instituteId: 'COE-A-STU1',
      name: 'Student Alice',
      email: 'alice@coea.edu',
      role: AppRole.STUDENT,
      password: 'Password123!',
    });

    studentUserA2 = await User.create({
      collegeId: collegeA._id,
      instituteId: 'COE-A-STU2',
      name: 'Student Bob',
      email: 'bob@coea.edu',
      role: AppRole.STUDENT,
      password: 'Password123!',
    });

    studentUserB = await User.create({
      collegeId: collegeB._id,
      instituteId: 'POLY-B-STU1',
      name: 'Student Charlie B',
      email: 'charlie@polyb.edu',
      role: AppRole.STUDENT,
      password: 'Password123!',
    });

    sectionA = await Section.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      semesterId: semesterA._id,
      name: 'Section A',
      capacity: 60,
    });

    subjectDBMS = await Subject.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      semesterId: semesterA._id,
      name: 'Database Management Systems',
      code: 'CS301',
    });

    const deptB = await Department.create({
      collegeId: collegeB._id,
      name: 'Mechanical Engineering',
      code: 'MECH',
    });

    facultyProfileA = await Faculty.create({
      collegeId: collegeA._id,
      userId: facultyUserA._id,
      departmentId: deptA._id,
      name: 'Prof. Alan Turing',
      email: 'alan@coea.edu',
      designation: 'Associate Professor',
    });

    studentProfileA1 = await Student.create({
      collegeId: collegeA._id,
      userId: studentUserA1._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      name: 'Student Alice',
      email: 'alice@coea.edu',
      instituteId: 'COE-A-STU1',
      rollNumber: 'CSE-001',
      registrationNumber: 'REG-001',
      admissionYear: 2024,
    });

    studentProfileA2 = await Student.create({
      collegeId: collegeA._id,
      userId: studentUserA2._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      name: 'Student Bob',
      email: 'bob@coea.edu',
      instituteId: 'COE-A-STU2',
      rollNumber: 'CSE-002',
      registrationNumber: 'REG-002',
      admissionYear: 2024,
    });

    await Student.create({
      collegeId: collegeB._id,
      departmentId: deptB._id,
      userId: studentUserB._id,
      name: 'Student Charlie B',
      email: 'charlie@polyb.edu',
      instituteId: 'POLY-B-STU1',
      rollNumber: 'POLY-001',
      registrationNumber: 'POLY-REG-001',
      admissionYear: 2024,
    });

    await StudentEnrollment.create([
      {
        collegeId: collegeA._id,
        departmentId: deptA._id,
        studentId: studentProfileA1._id,
        courseId: courseA._id,
        academicYearId: academicYearA._id,
        semesterId: semesterA._id,
        sectionId: sectionA._id,
        status: 'active',
      },
      {
        collegeId: collegeA._id,
        departmentId: deptA._id,
        studentId: studentProfileA2._id,
        courseId: courseA._id,
        academicYearId: academicYearA._id,
        semesterId: semesterA._id,
        sectionId: sectionA._id,
        status: 'active',
      },
    ]);

    await FacultyAssignment.create({
      collegeId: collegeA._id,
      facultyId: facultyProfileA._id,
      facultyName: 'Prof. Alan Turing',
      departmentId: deptA._id,
      courseId: courseA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      subjectId: subjectDBMS._id,
      academicYearId: academicYearA._id,
      isPrimary: true,
      status: 'ACTIVE',
    });
  });

  const facultyRequester: AuthenticatedUser = {
    id: '',
    instituteId: 'COE-A',
    name: 'Prof. Alan Turing',
    accountStatus: AccountStatus.ACTIVE,
    role: AppRole.FACULTY,
    collegeId: '',
    departmentId: '',
    email: 'alan@coea.edu',
  };

  beforeEach(() => {
    facultyRequester.id = facultyUserA._id.toString();
    facultyRequester.collegeId = collegeA._id.toString();
    facultyRequester.departmentId = deptA._id.toString();
  });

  function markSession(records: Array<{ studentId: string; status: AttendanceStatus }>, date: Date = new Date('2026-09-01')) {
    return AttendanceService.createOrSubmitSession(
      collegeA._id.toString(),
      {
        facultyId: facultyProfileA._id,
        subjectId: subjectDBMS._id,
        subjectName: subjectDBMS.name,
        sectionId: sectionA._id,
        sectionName: sectionA.name,
        date,
        timeSlot: '09:00 - 10:00',
        records: records as any,
      } as any,
      facultyRequester.id,
      facultyRequester
    );
  }

  test('1. Absence notification is created for the correct student', async () => {
    const session = await markSession([
      { studentId: studentProfileA1._id.toString(), status: AttendanceStatus.ABSENT },
      { studentId: studentProfileA2._id.toString(), status: AttendanceStatus.PRESENT },
    ]);

    expect(session).toBeDefined();

    // Check notifications for student A1
    const notifsAlice = await Notification.find({
      recipientUserId: studentUserA1._id,
      notificationType: NotificationType.ATTENDANCE_ABSENT,
    });
    expect(notifsAlice.length).toBe(1);
    expect(notifsAlice[0].title).toBe('Attendance Update');
    expect(notifsAlice[0].body).toContain('marked absent for Database Management Systems • Section A today');
    expect(notifsAlice[0].deepLink).toBe(`/attendance/student/subject/${subjectDBMS._id.toString()}`);
  });

  test('2. Other students do not receive that absence notification', async () => {
    await markSession([
      { studentId: studentProfileA1._id.toString(), status: AttendanceStatus.ABSENT },
      { studentId: studentProfileA2._id.toString(), status: AttendanceStatus.PRESENT },
    ]);

    // Bob was PRESENT, so Bob should NOT receive an absence notification
    const notifsBob = await Notification.find({
      recipientUserId: studentUserA2._id,
      notificationType: NotificationType.ATTENDANCE_ABSENT,
    });
    expect(notifsBob.length).toBe(0);
  });

  test('3. Tenant isolation is enforced: students in another college receive nothing', async () => {
    await markSession([
      { studentId: studentProfileA1._id.toString(), status: AttendanceStatus.ABSENT },
      { studentId: studentProfileA2._id.toString(), status: AttendanceStatus.ABSENT },
    ]);

    const notifsCharlie = await Notification.find({
      recipientUserId: studentUserB._id,
    });
    expect(notifsCharlie.length).toBe(0);
  });

  test('4. Warning notification is created when crossing the configured warning threshold', async () => {
    // Setup history: 5 sessions attended (5/5 = 100%)
    for (let i = 1; i <= 5; i++) {
      await markSession(
        [{ studentId: studentProfileA1._id.toString(), status: AttendanceStatus.PRESENT }],
        new Date(`2026-09-0${i}`)
      );
    }

    // Clear notifications from initial setup
    await Notification.deleteMany({});

    // 6th session: Student is absent -> 5/6 = 83.33% (prior >= 75%, new >= 75% -> no warning)
    await markSession(
      [{ studentId: studentProfileA1._id.toString(), status: AttendanceStatus.ABSENT }],
      new Date('2026-09-06')
    );

    let warnNotif = await Notification.findOne({
      recipientUserId: studentUserA1._id,
      notificationType: NotificationType.ATTENDANCE_LOW,
    });
    expect(warnNotif).toBeNull(); // 83.33% is above 75%

    // 7th session: Student is absent -> 5/7 = 71.43% (prior 83.33% >= 75%, new 71.43% < 75%)
    // Crossing warning threshold!
    await markSession(
      [{ studentId: studentProfileA1._id.toString(), status: AttendanceStatus.ABSENT }],
      new Date('2026-09-07')
    );

    warnNotif = await Notification.findOne({
      recipientUserId: studentUserA1._id,
      notificationType: NotificationType.ATTENDANCE_LOW,
    });
    expect(warnNotif).not.toBeNull();
    expect(warnNotif!.title).toBe('Attendance Warning');
    expect(warnNotif!.body).toContain('71.43%');
    expect(warnNotif!.priority).toBe(NotificationPriority.HIGH);
  });

  test('5. Warning is NOT repeatedly generated while remaining below the threshold', async () => {
    // Set critical threshold to 50% so Alice doesn't trigger critical
    await InstitutionConfiguration.findOneAndUpdate(
      { collegeId: collegeA._id },
      { $set: { 'attendanceAlerts.criticalPercentage': 50 } }
    );

    // Setup history: 5 present, 2 absent -> 5/7 = 71.43% (crossed 75%)
    for (let i = 1; i <= 5; i++) {
      await markSession(
        [{ studentId: studentProfileA1._id.toString(), status: AttendanceStatus.PRESENT }],
        new Date(`2026-09-0${i}`)
      );
    }
    for (let i = 6; i <= 7; i++) {
      await markSession(
        [{ studentId: studentProfileA1._id.toString(), status: AttendanceStatus.ABSENT }],
        new Date(`2026-09-0${i}`)
      );
    }

    const initialWarnCount = await Notification.countDocuments({
      recipientUserId: studentUserA1._id,
      notificationType: NotificationType.ATTENDANCE_LOW,
    });
    expect(initialWarnCount).toBe(1);

    // Alice is at 5/7 = 71.43%.
    // Session 8: absent -> 5/8 = 62.5% (prior 71.43% was already < 75%, new is 62.5% < 75%).
    // No new warning crossing!
    await markSession(
      [{ studentId: studentProfileA1._id.toString(), status: AttendanceStatus.ABSENT }],
      new Date('2026-09-08')
    );

    const postWarnCount = await Notification.countDocuments({
      recipientUserId: studentUserA1._id,
      notificationType: NotificationType.ATTENDANCE_LOW,
    });
    expect(postWarnCount).toBe(1);
  });

  test('6. Critical notification is created when crossing the critical threshold', async () => {
    // Re-set critical threshold to 65%
    await InstitutionConfiguration.findOneAndUpdate(
      { collegeId: collegeA._id },
      { $set: { 'attendanceAlerts.criticalPercentage': 65 } }
    );

    // Setup fresh attendance for Bob (Student A2)
    // 7 classes attended out of 10: 7/10 = 70% (>= 65%)
    for (let i = 1; i <= 7; i++) {
      await markSession(
        [{ studentId: studentProfileA2._id.toString(), status: AttendanceStatus.PRESENT }],
        new Date(`2026-10-0${i}`)
      );
    }
    for (let i = 8; i <= 10; i++) {
      await markSession(
        [{ studentId: studentProfileA2._id.toString(), status: AttendanceStatus.ABSENT }],
        new Date(`2026-10-${i}`)
      );
    }

    // Now Bob has 10 classes: 7 present, 3 absent -> 70% (>= 65% critical).
    // Clear Bob's notifications
    await Notification.deleteMany({ recipientUserId: studentUserA2._id });

    // 11th class: Bob is absent -> 7/11 = 63.64% (< 65% critical).
    // Prior was 70% (>= 65%), new is 63.64% (< 65%). Meaningful critical crossing!
    await markSession(
      [{ studentId: studentProfileA2._id.toString(), status: AttendanceStatus.ABSENT }],
      new Date('2026-10-11')
    );

    const critNotif = await Notification.findOne({
      recipientUserId: studentUserA2._id,
      notificationType: NotificationType.ATTENDANCE_ALERT,
    });
    expect(critNotif).not.toBeNull();
    expect(critNotif!.title).toBe('Attendance Alert');
    expect(critNotif!.body).toContain('63.64%');
    expect(critNotif!.priority).toBe(NotificationPriority.CRITICAL);
  });

  test('7. Critical is NOT repeatedly generated while remaining below the threshold', async () => {
    // Re-set critical threshold to 65%
    await InstitutionConfiguration.findOneAndUpdate(
      { collegeId: collegeA._id },
      { $set: { 'attendanceAlerts.criticalPercentage': 65 } }
    );

    // Setup Bob: 7 present, 4 absent -> 7/11 = 63.64% (already crossed 65% critical in class 11)
    for (let i = 1; i <= 7; i++) {
      await markSession(
        [{ studentId: studentProfileA2._id.toString(), status: AttendanceStatus.PRESENT }],
        new Date(`2026-10-0${i}`)
      );
    }
    for (let i = 8; i <= 11; i++) {
      await markSession(
        [{ studentId: studentProfileA2._id.toString(), status: AttendanceStatus.ABSENT }],
        new Date(`2026-10-${i}`)
      );
    }

    const initialCritCount = await Notification.countDocuments({
      recipientUserId: studentUserA2._id,
      notificationType: NotificationType.ATTENDANCE_ALERT,
    });
    expect(initialCritCount).toBe(1);

    // 12th class: Bob is absent again -> 7/12 = 58.33% (< 65%).
    // Prior was 63.64% (< 65%), so prior was ALREADY below critical!
    await markSession(
      [{ studentId: studentProfileA2._id.toString(), status: AttendanceStatus.ABSENT }],
      new Date('2026-10-12')
    );

    const postCritCount = await Notification.countDocuments({
      recipientUserId: studentUserA2._id,
      notificationType: NotificationType.ATTENDANCE_ALERT,
    });
    expect(postCritCount).toBe(1);
  });

  test('8. Duplicate / retry attendance processing does not create duplicate notifications', async () => {
    // Clear notifications
    await Notification.deleteMany({});

    // Submit session for Bob as Absent
    const session = await markSession(
      [{ studentId: studentProfileA2._id.toString(), status: AttendanceStatus.ABSENT }],
      new Date('2026-10-13')
    );

    const notifsAfterFirst = await Notification.find({
      recipientUserId: studentUserA2._id,
      notificationType: NotificationType.ATTENDANCE_ABSENT,
    });
    expect(notifsAfterFirst.length).toBe(1);

    // Call submitRecords for the exact same session (retry / re-submission scenario)
    await AttendanceService.submitRecords(
      session._id.toString(),
      [
        { studentId: studentProfileA2._id.toString(), status: AttendanceStatus.ABSENT },
      ],
      facultyRequester
    );

    const notifsAfterRetry = await Notification.find({
      recipientUserId: studentUserA2._id,
      notificationType: NotificationType.ATTENDANCE_ABSENT,
    });
    expect(notifsAfterRetry.length).toBe(1); // Idempotency preserved!
  });

  test('9. Disabled alert configuration prevents future alert generation', async () => {
    // Disable attendance alerts in college config
    await InstitutionConfiguration.findOneAndUpdate(
      { collegeId: collegeA._id },
      { $set: { 'attendanceAlerts.enabled': false } }
    );

    await Notification.deleteMany({});

    // Submit session with absent student
    await markSession(
      [{ studentId: studentProfileA1._id.toString(), status: AttendanceStatus.ABSENT }],
      new Date('2026-10-14')
    );

    const notifs = await Notification.find({
      recipientUserId: studentUserA1._id,
    });
    expect(notifs.length).toBe(0);

    // Now re-enable global alerts but disable absence alerts
    await InstitutionConfiguration.findOneAndUpdate(
      { collegeId: collegeA._id },
      {
        $set: {
          'attendanceAlerts.enabled': true,
          'attendanceAlerts.absenceAlertsEnabled': false,
        },
      }
    );

    await markSession(
      [{ studentId: studentProfileA1._id.toString(), status: AttendanceStatus.ABSENT }],
      new Date('2026-10-15')
    );

    const absenceNotifs = await Notification.find({
      recipientUserId: studentUserA1._id,
      notificationType: NotificationType.ATTENDANCE_ABSENT,
    });
    expect(absenceNotifs.length).toBe(0);
  });

  test('10. Existing attendance data remains valid when notification creation fails', async () => {
    // Re-enable alerts
    await InstitutionConfiguration.findOneAndUpdate(
      { collegeId: collegeA._id },
      { $set: { 'attendanceAlerts.enabled': true, 'attendanceAlerts.absenceAlertsEnabled': true } }
    );

    // Mock NotificationService.createBatchNotifications to throw
    const originalBatch = NotificationService.createBatchNotifications;
    jest.spyOn(NotificationService, 'createBatchNotifications').mockImplementation(async () => {
      throw new Error('FCM or MongoDB connection drop during notification dispatch');
    });

    try {
      const session = await markSession(
        [{ studentId: studentProfileA1._id.toString(), status: AttendanceStatus.ABSENT }],
        new Date('2026-10-16')
      );

      // Verify attendance session and records were saved successfully despite notification failure
      expect(session).toBeDefined();
      expect(session._id).toBeDefined();

      const savedRecords = await AttendanceRecord.find({ sessionId: session._id });
      expect(savedRecords.length).toBe(1);
      expect(savedRecords[0].status).toBe(AttendanceStatus.ABSENT);
    } finally {
      NotificationService.createBatchNotifications = originalBatch;
    }
  });

  test('11. Disabled section concept does not leak section name into notification copy', async () => {
    // Disable section in academic structure
    await InstitutionConfiguration.findOneAndUpdate(
      { collegeId: collegeA._id },
      {
        $set: {
          'academicStructure.section': false,
          'attendanceAlerts.enabled': true,
          'attendanceAlerts.absenceAlertsEnabled': true,
        },
      }
    );

    await Notification.deleteMany({});

    await markSession(
      [{ studentId: studentProfileA1._id.toString(), status: AttendanceStatus.ABSENT }],
      new Date('2026-10-17')
    );

    const notif = await Notification.findOne({
      recipientUserId: studentUserA1._id,
      notificationType: NotificationType.ATTENDANCE_ABSENT,
    });
    expect(notif).not.toBeNull();
    // Section is disabled, so it must say "marked absent for Database Management Systems today." without mentioning Section
    expect(notif!.body).toBe('You were marked absent for Database Management Systems today.');
    expect(notif!.body).not.toContain('Section');
  });
});
