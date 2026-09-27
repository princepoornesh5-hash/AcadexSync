import request from 'supertest';
import mongoose from 'mongoose';
import { app } from '../../src/app';
import { College } from '../../src/models/college.model';
import { Department } from '../../src/models/department.model';
import { Course } from '../../src/models/course.model';
import { AcademicYear } from '../../src/models/academicYear.model';
import { Semester } from '../../src/models/semester.model';
import { Section } from '../../src/models/section.model';
import { Subject } from '../../src/models/subject.model';
import { Faculty } from '../../src/models/faculty.model';
import { FacultyAssignment } from '../../src/models/facultyAssignment.model';
import { Student } from '../../src/models/student.model';
import { StudentEnrollment } from '../../src/models/studentEnrollment.model';
import { Timetable } from '../../src/models/timetable.model';
import { AttendanceSession } from '../../src/models/attendanceSession.model';
import { Assignment } from '../../src/models/assignment.model';
import { RequestModel } from '../../src/models/request.model';
import { User } from '../../src/models/user.model';
import { Notification } from '../../src/models/notification.model';
import { AppRole } from '../../src/constants/roles';
import {
  AcademicYearStatus,
  AccountStatus,
  StudentLifecycleState,
  TimetableStatus,
  TimetableDay,
  TimetableSessionType,
  TimetableTimingMode,
  AttendanceStatus,
} from '../../src/constants/status';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';

describe('Prompt 25: End-to-End Campus Workflow & 5-Mobile Acceptance Path', () => {
  let college: any;
  let adminUser: any;
  let adminHeader: { Authorization: string };

  beforeAll(async () => {
    await setupTestDB();
    await College.init();
    await Department.init();
    await Course.init();
    await AcademicYear.init();
    await Semester.init();
    await Section.init();
    await Subject.init();
    await Faculty.init();
    await FacultyAssignment.init();
    await Student.init();
    await StudentEnrollment.init();
    await Timetable.init();
    await AttendanceSession.init();
    await Assignment.init();
    await RequestModel.init();
    await User.init();
    await Notification.init();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();

    college = await College.create({
      name: 'Acadex Polytechnic Institute',
      code: 'API-001',
      address: 'Central Campus',
      email: 'admin@acadex-pilot.edu',
      phone: '9876543210',
      principal: 'Dr. Ramesh Gupta',
    });

    adminUser = await User.create({
      collegeId: college._id,
      name: 'College Admin',
      email: 'admin@acadex-pilot.edu',
      instituteId: 'INST-ADMIN-001',
      passwordHash: 'hash123',
      role: AppRole.COLLEGE_ADMIN,
      accountStatus: AccountStatus.ACTIVE,
    });

    adminHeader = createTestAuthHeader({
      role: AppRole.COLLEGE_ADMIN,
      collegeId: college._id.toString(),
      userId: adminUser.id,
    });
  });

  it('executes the full 20-step golden campus path cleanly with real persistence', async () => {
    // -------------------------------------------------------------------------
    // STEP 1: College Admin creates current Academic Year: 2026–27
    // -------------------------------------------------------------------------
    const ayRes = await request(app)
      .post('/api/v1/academics/academic-years')
      .set(adminHeader)
      .send({
        name: '2026–27',
        startDate: '2026-06-01T00:00:00.000Z',
        endDate: '2027-05-31T23:59:59.000Z',
        status: AcademicYearStatus.ACTIVE,
        isCurrent: true,
      });

    expect(ayRes.status).toBe(201);
    expect(ayRes.body.success).toBe(true);
    const academicYearId = ayRes.body.data.id;
    expect(ayRes.body.data.name).toBe('2026–27');
    expect(ayRes.body.data.isCurrent).toBe(true);

    // -------------------------------------------------------------------------
    // STEP 2: College Admin creates Department: Computer Engineering
    // -------------------------------------------------------------------------
    const deptRes = await request(app)
      .post('/api/v1/departments')
      .set(adminHeader)
      .send({
        name: 'Computer Engineering',
        code: 'CSE',
        description: 'Department of Computer Engineering',
      });

    expect(deptRes.status).toBe(201);
    const departmentId = deptRes.body.data.id;
    expect(deptRes.body.data.code).toBe('CSE');

    // -------------------------------------------------------------------------
    // STEP 3: College Admin provisions / assigns HOD to Computer Engineering
    // -------------------------------------------------------------------------
    const hodProvisionRes = await request(app)
      .post('/api/v1/academics/hods')
      .set(adminHeader)
      .send({
        departmentId,
        name: 'Prof. Suresh Verma',
        instituteId: 'INST-HOD-001',
        email: 'hod.cse@acadex-pilot.edu',
      });

    expect(hodProvisionRes.status).toBe(201);
    const hodUser = hodProvisionRes.body.data.user;

    // Activate HOD account (simulating invitation acceptance)
    await User.findByIdAndUpdate(hodUser.id, { accountStatus: AccountStatus.ACTIVE });

    // -------------------------------------------------------------------------
    // STEP 4 & 5: HOD enters department and configures current academic context
    // -------------------------------------------------------------------------
    const hodHeader = createTestAuthHeader({
      role: AppRole.HOD,
      collegeId: college._id.toString(),
      departmentId,
      userId: hodUser.id,
    });

    // HOD creates Course (Diploma in Computer Engineering)
    const courseRes = await request(app)
      .post('/api/v1/academics/courses')
      .set(hodHeader)
      .send({
        name: 'Diploma in Computer Engineering',
        code: 'DCSE',
        duration: 3,
        progressionType: 'YEAR_SEMESTER',
        departmentId,
      });

    expect(courseRes.status).toBe(201);
    const courseId = courseRes.body.data.id;

    // HOD creates Semester 5 (3rd Year)
    const semRes = await request(app)
      .post('/api/v1/academics/semesters')
      .set(hodHeader)
      .send({
        courseId,
        academicYearId,
        departmentId,
        name: 'Semester 5',
        number: 5,
        isCurrent: true,
      });

    expect(semRes.status).toBe(201);
    const semesterId = semRes.body.data.id;

    // -------------------------------------------------------------------------
    // STEP 6: HOD creates Section A and Subject DBMS
    // -------------------------------------------------------------------------
    const secRes = await request(app)
      .post('/api/v1/academics/sections')
      .set(hodHeader)
      .send({
        courseId,
        academicYearId,
        semesterId,
        departmentId,
        name: 'A',
        capacity: 60,
      });

    expect(secRes.status).toBe(201);
    const sectionId = secRes.body.data.id;

    const subRes = await request(app)
      .post('/api/v1/academics/subjects')
      .set(hodHeader)
      .send({
        courseId,
        semesterId,
        departmentId,
        name: 'Database Management Systems',
        code: 'CS501',
        type: 'THEORY',
        credits: 4,
      });

    expect(subRes.status).toBe(201);
    const subjectId = subRes.body.data.id;

    // -------------------------------------------------------------------------
    // STEP 7: HOD assigns Faculty to DBMS (FacultyAssignment)
    // -------------------------------------------------------------------------
    const facultyUser = await User.create({
      collegeId: college._id,
      departmentId: new mongoose.Types.ObjectId(departmentId),
      name: 'Prof. Rajesh Kumar',
      email: 'faculty.dbms@acadex-pilot.edu',
      instituteId: 'INST-FAC-001',
      passwordHash: 'hash123',
      role: AppRole.FACULTY,
      accountStatus: AccountStatus.ACTIVE,
    });

    const facultyProfile = await Faculty.create({
      collegeId: college._id,
      departmentId: new mongoose.Types.ObjectId(departmentId),
      userId: facultyUser._id,
      name: 'Prof. Rajesh Kumar',
      email: facultyUser.email,
      employeeId: 'FAC-CSE-001',
      status: 'active',
      isActive: true,
    });

    const faRes = await request(app)
      .post('/api/v1/academics/faculty-assignments')
      .set(hodHeader)
      .send({
        facultyId: facultyProfile.id,
        subjectId,
        sectionId,
        semesterId,
        courseId,
        academicYearId,
        departmentId,
        cohort: '2024–27',
        academicStage: '3rd Year',
      });

    expect(faRes.status).toBe(201);
    const facultyAssignmentId = faRes.body.data.id;
    expect(faRes.body.data.cohort).toBe('2024–27');
    expect(faRes.body.data.academicStage).toBe('3rd Year');

    // -------------------------------------------------------------------------
    // STEP 8: HOD enrolls exactly 3 test students (Student A, Student B, Student C)
    // -------------------------------------------------------------------------
    const studentUsers = [];
    const studentDocs = [];
    const studentNames = ['Aarav Sharma', 'Bhavya Patel', 'Chirag Verma'];
    const studentEmails = ['student.a@acadex-pilot.edu', 'student.b@acadex-pilot.edu', 'student.c@acadex-pilot.edu'];
    const rollNumbers = ['CSE-24-001', 'CSE-24-002', 'CSE-24-003'];

    for (let i = 0; i < 3; i++) {
      const u = await User.create({
        collegeId: college._id,
        departmentId: new mongoose.Types.ObjectId(departmentId),
        name: studentNames[i],
        email: studentEmails[i],
        instituteId: `INST-STU-00${i + 1}`,
        passwordHash: 'hash123',
        role: AppRole.STUDENT,
        accountStatus: AccountStatus.ACTIVE,
      });
      studentUsers.push(u);

      const s = await Student.create({
        collegeId: college._id,
        departmentId: new mongoose.Types.ObjectId(departmentId),
        userId: u._id,
        name: studentNames[i],
        rollNumber: rollNumbers[i],
        email: studentEmails[i],
        courseId: new mongoose.Types.ObjectId(courseId),
        semesterId: new mongoose.Types.ObjectId(semesterId),
        sectionId: new mongoose.Types.ObjectId(sectionId),
        cohort: '2024–27',
        academicStage: '3rd Year',
        lifecycleState: StudentLifecycleState.ACTIVE,
        status: 'active',
        isActive: true,
      });
      studentDocs.push(s);

      const enrollRes = await request(app)
        .post('/api/v1/academics/enrollments')
        .set(hodHeader)
        .send({
          studentId: s.id,
          sectionId,
          semesterId,
          courseId,
          departmentId,
          academicYearId,
          cohort: '2024–27',
          academicStage: '3rd Year',
        });

      expect(enrollRes.status).toBe(201);
    }

    // -------------------------------------------------------------------------
    // STEP 9 & 10: HOD creates and publishes Timetable for Section A
    // -------------------------------------------------------------------------
    const timetable = await Timetable.create({
      collegeId: college._id,
      departmentId: new mongoose.Types.ObjectId(departmentId),
      courseId: new mongoose.Types.ObjectId(courseId),
      academicYearId: new mongoose.Types.ObjectId(academicYearId),
      semesterId: new mongoose.Types.ObjectId(semesterId),
      sectionId: new mongoose.Types.ObjectId(sectionId),
      name: 'Class A Timetable',
      status: TimetableStatus.DRAFT,
      version: 1,
      activeDays: [TimetableDay.MONDAY, TimetableDay.TUESDAY, TimetableDay.WEDNESDAY, TimetableDay.THURSDAY, TimetableDay.FRIDAY],
      timingMode: TimetableTimingMode.SAME_EVERY_DAY,
      periods: [],
      breaks: [],
      entries: [
        {
          dayOfWeek: TimetableDay.MONDAY,
          startTime: '10:00',
          endTime: '11:00',
          subjectId: new mongoose.Types.ObjectId(subjectId),
          facultyId: facultyProfile._id,
          facultyAssignmentId: new mongoose.Types.ObjectId(facultyAssignmentId),
          roomNumber: 'Lab 2',
          building: 'Main Block',
          sessionType: TimetableSessionType.LECTURE,
        },
      ],
    });

    const pubRes = await request(app)
      .post(`/api/v1/timetables/${timetable._id}/publish`)
      .set(hodHeader);

    expect(pubRes.status).toBe(200);
    expect(pubRes.body.data.status).toBe(TimetableStatus.PUBLISHED);

    // -------------------------------------------------------------------------
    // STEP 11: Faculty logs in and queries their timetable / assigned classes
    // -------------------------------------------------------------------------
    const facultyHeader = createTestAuthHeader({
      role: AppRole.FACULTY,
      collegeId: college._id.toString(),
      departmentId,
      userId: facultyUser.id,
    });

    const facTimetableRes = await request(app)
      .get(`/api/v1/timetables/faculty/me?day=monday`)
      .set(facultyHeader);

    expect(facTimetableRes.status).toBe(200);
    expect(facTimetableRes.body.data.length).toBe(1);

    const facultyClass = facTimetableRes.body.data[0];
    expect(facultyClass.subjectName).toBe('Database Management Systems');
    expect(facultyClass.sectionName).toBe('A');
    expect(facultyClass.cohort).toBe('2024–27');
    expect(facultyClass.academicStage).toBe('3rd Year');
    expect(facultyClass.contextualDescription).toContain('2024–27 · 3rd Year · Semester 5 · Class A');

    // -------------------------------------------------------------------------
    // STEP 12: Verify Roster of exactly 3 active students loaded
    // -------------------------------------------------------------------------
    const rosterRes = await request(app)
      .get(`/api/v1/academics/enrollments?sectionId=${sectionId}&status=active`)
      .set(facultyHeader);

    expect(rosterRes.status).toBe(200);
    expect(rosterRes.body.data.items.length).toBe(3);
    const enrolledNames = rosterRes.body.data.items.map((i: any) => i.student.name);
    expect(enrolledNames).toEqual(expect.arrayContaining(['Aarav Sharma', 'Bhavya Patel', 'Chirag Verma']));

    // -------------------------------------------------------------------------
    // STEP 13 & 14: Faculty submits attendance: Student A & B Present, Student C Absent
    // -------------------------------------------------------------------------
    const attendanceSubmission = {
      sectionId,
      subjectId,
      facultyId: facultyProfile.id,
      facultyAssignmentId,
      timetableId: timetable.id,
      timetableEntryId: facultyClass._id,
      date: '2026-09-28T04:30:00.000Z',
      timeSlot: '10:00 - 11:00 AM',
      records: [
        { studentId: studentDocs[0].id, status: AttendanceStatus.PRESENT },
        { studentId: studentDocs[1].id, status: AttendanceStatus.PRESENT },
        { studentId: studentDocs[2].id, status: AttendanceStatus.ABSENT },
      ],
    };

    const submitRes = await request(app)
      .post('/api/v1/attendance/sessions')
      .set(facultyHeader)
      .send(attendanceSubmission);

    expect(submitRes.status).toBe(201);
    expect(submitRes.body.data.isSubmitted).toBe(true);
    expect(submitRes.body.data.records.length).toBe(3);

    // -------------------------------------------------------------------------
    // STEP 15: Student C receives attendance absence notification
    // -------------------------------------------------------------------------
    const studentCNotifs = await Notification.find({
      recipientUserId: studentUsers[2]._id,
    });
    expect(studentCNotifs.length).toBeGreaterThan(0);
    const absentNotif = studentCNotifs.find((n) => n.body.toLowerCase().includes('absent') || n.title.toLowerCase().includes('attendance'));
    expect(absentNotif).toBeDefined();

    // Student A (present) did not receive an absence notification
    const studentANotifs = await Notification.find({
      recipientUserId: studentUsers[0]._id,
    });
    const studentAAbsentNotif = studentANotifs.find((n) => n.body.toLowerCase().includes('absent'));
    expect(studentAAbsentNotif).toBeUndefined();

    // -------------------------------------------------------------------------
    // STEP 16: Students can see their attendance
    // -------------------------------------------------------------------------
    const studentCHeader = createTestAuthHeader({
      role: AppRole.STUDENT,
      collegeId: college._id.toString(),
      departmentId,
      userId: studentUsers[2].id,
    });

    const studentSummaryRes = await request(app)
      .get('/api/v1/attendance/students/me/summary')
      .set(studentCHeader);

    expect(studentSummaryRes.status).toBe(200);
    expect(studentSummaryRes.body.data.totalClasses).toBe(1);
    expect(studentSummaryRes.body.data.absentCount).toBe(1);

    // -------------------------------------------------------------------------
    // STEP 17: HOD can see department attendance information
    // -------------------------------------------------------------------------
    const hodSessionsRes = await request(app)
      .get(`/api/v1/attendance/sessions?departmentId=${departmentId}`)
      .set(hodHeader);

    expect(hodSessionsRes.status).toBe(200);
    expect(hodSessionsRes.body.data.items.length).toBe(1);
    expect(hodSessionsRes.body.data.items[0].records.length).toBe(3);

    // -------------------------------------------------------------------------
    // STEP 18: Faculty publishes Assignment -> Student sees assignment & calendar deadline
    // -------------------------------------------------------------------------
    const assignmentRes = await request(app)
      .post('/api/v1/assignments')
      .set(facultyHeader)
      .send({
        facultyAssignmentId,
        title: 'SQL Normalization Assignment',
        description: 'Complete 1NF, 2NF, and 3NF normalization exercises.',
        dueDate: '2026-10-15',
        dueTime: '11:59 PM',
        maximumMarks: 20,
        status: 'PUBLISHED',
      });

    expect(assignmentRes.status).toBe(201);
    expect(assignmentRes.body.data.title).toBe('SQL Normalization Assignment');

    // Student A checks assignments
    const studentAHeader = createTestAuthHeader({
      role: AppRole.STUDENT,
      collegeId: college._id.toString(),
      departmentId,
      userId: studentUsers[0].id,
    });

    const studentAssignmentsRes = await request(app)
      .get('/api/v1/assignments/my')
      .set(studentAHeader);

    expect(studentAssignmentsRes.status).toBe(200);
    expect(studentAssignmentsRes.body.data.length).toBeGreaterThan(0);
    expect(studentAssignmentsRes.body.data[0].title).toBe('SQL Normalization Assignment');

    // Student A checks Calendar -> Assignment deadline appears automatically
    const calendarRes = await request(app)
      .get('/api/v1/calendar?startDate=2026-10-01&endDate=2026-10-31')
      .set(studentAHeader);

    expect(calendarRes.status).toBe(200);
    expect(Array.isArray(calendarRes.body.data)).toBe(true);
    const deadlineEvent = calendarRes.body.data.find(
      (ev: any) => ev.title.includes('SQL Normalization Assignment')
    );
    expect(deadlineEvent).toBeDefined();
    expect(deadlineEvent.sourceType).toBe('DERIVED');
    expect(deadlineEvent.eventType).toBe('DEADLINE');

    // -------------------------------------------------------------------------
    // STEP 19: Student submits Leave Request -> Routes cleanly to HOD
    // -------------------------------------------------------------------------
    const leaveRes = await request(app)
      .post('/api/v1/requests')
      .set(studentAHeader)
      .send({
        requestType: 'LEAVE',
        description: 'Need leave for 2 days due to fever',
        details: {
          startDate: '2026-10-01T00:00:00.000Z',
          endDate: '2026-10-02T23:59:59.000Z',
          reason: 'Medical fever',
        },
      });

    expect(leaveRes.status).toBe(201);
    expect(leaveRes.body.data.targetRole).toBe(AppRole.HOD);
    expect(leaveRes.body.data.targetUserId).toBe(hodUser.id);
    expect(leaveRes.body.data.targetName).toContain('Computer Engineering HOD');

    // Wait a brief moment for the asynchronous REQUEST_CREATED notification listener to complete
    await new Promise((r) => setTimeout(r, 100));

    // -------------------------------------------------------------------------
    // STEP 20: Cross-tenant isolation verification
    // -------------------------------------------------------------------------
    const otherCollege = await College.create({
      name: 'Other College',
      code: 'OTHER-001',
      address: 'West Campus',
      email: 'admin@other.edu',
      phone: '9000000000',
      principal: 'Dr. Other Principal',
    });
    const otherAdminUser = await User.create({
      collegeId: otherCollege._id,
      name: 'Other Admin',
      email: 'admin@other.edu',
      instituteId: 'INST-OTHER-001',
      passwordHash: 'hash123',
      role: AppRole.COLLEGE_ADMIN,
      accountStatus: AccountStatus.ACTIVE,
    });
    const otherAdminHeader = createTestAuthHeader({
      role: AppRole.COLLEGE_ADMIN,
      collegeId: otherCollege._id.toString(),
      userId: otherAdminUser.id,
    });

    const crossRes = await request(app)
      .get(`/api/v1/attendance/sessions?departmentId=${departmentId}`)
      .set(otherAdminHeader);

    // Filter enforces tenant boundary, so other college receives empty items
    expect(crossRes.status).toBe(200);
    expect(crossRes.body.data.items.length).toBe(0);
  });
});
