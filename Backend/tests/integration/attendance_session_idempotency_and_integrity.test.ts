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
import { FacultyAssignment } from '../../src/models/facultyAssignment.model';
import { AttendanceSession } from '../../src/models/attendanceSession.model';
import { AttendanceRecord } from '../../src/models/attendanceRecord.model';
import { normalizeTimeSlot } from '../../src/utils/dateTime';
import { AppRole } from '../../src/constants/roles';
import {
  AccountStatus,
  CollegeStatus,
  DepartmentStatus,
  TimetableDay,
  TimetableStatus,
  AttendanceStatus,
  AttendanceSessionStatus,
  TimetableSessionType,
} from '../../src/constants/status';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';

describe('Attendance Session Idempotency & Count Integrity Integration Tests', () => {
  let collegeA: InstanceType<typeof College>;
  let collegeB: InstanceType<typeof College>;
  let deptA: InstanceType<typeof Department>;
  let courseA: InstanceType<typeof Course>;
  let ayA: InstanceType<typeof AcademicYear>;
  let semA: InstanceType<typeof Semester>;
  let secA: InstanceType<typeof Section>;
  let subjectIot: InstanceType<typeof Subject>;

  let userFaculty1: InstanceType<typeof User>;
  let facultyDoc1: InstanceType<typeof Faculty>;
  let headerFaculty1: { Authorization: string };

  let userFaculty2: InstanceType<typeof User>;
  let headerFaculty2: { Authorization: string };

  let student1: InstanceType<typeof Student>;
  let student2: InstanceType<typeof Student>;
  let student3: InstanceType<typeof Student>;
  let student4: InstanceType<typeof Student>;
  let student5: InstanceType<typeof Student>;

  let assignmentIot: InstanceType<typeof FacultyAssignment>;
  let timetablePublished: InstanceType<typeof Timetable>;
  let ttEntryId: string;

  beforeAll(async () => {
    await setupTestDB();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();

    collegeA = await College.create({
      name: 'College of Technology',
      code: 'COT',
      address: '100 Tech Campus',
      email: 'admin@cot.edu',
      phone: '+919988776601',
      principal: 'Dr. Principal COT',
      status: CollegeStatus.ACTIVE,
      timezone: 'Asia/Kolkata',
    });

    collegeB = await College.create({
      name: 'Other College',
      code: 'OTH',
      address: '200 Other Campus',
      email: 'admin@oth.edu',
      phone: '+919988776602',
      principal: 'Dr. Principal OTH',
      status: CollegeStatus.ACTIVE,
      timezone: 'Asia/Kolkata',
    });

    deptA = await Department.create({
      collegeId: collegeA._id,
      name: 'Computer Science',
      code: 'CSE',
      status: DepartmentStatus.ACTIVE,
    });

    courseA = await Course.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'B.Tech CSE',
      code: 'BT-CSE',
      isActive: true,
    });

    ayA = await AcademicYear.create({
      collegeId: collegeA._id,
      year: '2026-2027',
      name: '2026-2027',
      startDate: new Date('2026-06-01'),
      endDate: new Date('2027-05-31'),
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
      name: 'A',
      capacity: 60,
      isActive: true,
    });

    subjectIot = await Subject.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      semesterId: semA._id,
      name: 'Internet of Things',
      code: 'IOT-501',
      credits: 4,
      type: 'Theory',
      isActive: true,
    });

    userFaculty1 = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      email: 'mani@college.edu',
      name: 'T Masila Mani',
      role: AppRole.FACULTY,
      status: AccountStatus.ACTIVE,
    });

    facultyDoc1 = await Faculty.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      userId: userFaculty1._id,
      name: 'T Masila Mani',
      employeeId: 'EMP-MANI-01',
      email: 'mani@college.edu',
      designation: 'Assistant Professor',
      isActive: true,
      status: 'active',
    });

    headerFaculty1 = createTestAuthHeader({
      userId: userFaculty1._id.toString(),
      collegeId: collegeA._id.toString(),
      role: AppRole.FACULTY,
      email: userFaculty1.email,
    });

    userFaculty2 = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      email: 'other@college.edu',
      name: 'Other Faculty',
      role: AppRole.FACULTY,
      status: AccountStatus.ACTIVE,
    });

    await Faculty.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      userId: userFaculty2._id,
      name: 'Other Faculty',
      employeeId: 'EMP-OTH-02',
      email: 'other@college.edu',
      designation: 'Associate Professor',
      isActive: true,
      status: 'active',
    });

    headerFaculty2 = createTestAuthHeader({
      userId: userFaculty2._id.toString(),
      collegeId: collegeA._id.toString(),
      role: AppRole.FACULTY,
      email: userFaculty2.email,
    });

    // Create 5 students enrolled in Section A
    const makeStudent = async (name: string, roll: string) => {
      const u = await User.create({
        collegeId: collegeA._id,
        email: `${roll.toLowerCase()}@student.edu`,
        name,
        role: AppRole.STUDENT,
        status: AccountStatus.ACTIVE,
      });
      const s = await Student.create({
        collegeId: collegeA._id,
        departmentId: deptA._id,
        courseId: courseA._id,
        academicYearId: ayA._id,
        semesterId: semA._id,
        sectionId: secA._id,
        userId: u._id,
        name,
        rollNumber: roll,
        admissionNumber: `ADM-${roll}`,
        status: 'active',
      });
      await StudentEnrollment.create({
        collegeId: collegeA._id,
        departmentId: deptA._id,
        studentId: s._id,
        academicYearId: ayA._id,
        semesterId: semA._id,
        sectionId: secA._id,
        courseId: courseA._id,
        status: 'active',
      });
      return s;
    };

    student1 = await makeStudent('Harsha', 'IOT001');
    student2 = await makeStudent('Naga Rasagna', 'IOT002');
    student3 = await makeStudent('R Poornesh', 'IOT003');
    student4 = await makeStudent('Santosh', 'IOT004');
    student5 = await makeStudent('k Uday Kumar', 'IOT005');

    assignmentIot = await FacultyAssignment.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      facultyId: facultyDoc1._id,
      facultyName: facultyDoc1.name,
      subjectId: subjectIot._id,
      sectionId: secA._id,
      courseId: courseA._id,
      academicYearId: ayA._id,
      semesterId: semA._id,
      status: 'active',
      isActive: true,
    });

    timetablePublished = await Timetable.create({
      name: 'Section A Timetable',
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: ayA._id,
      semesterId: semA._id,
      sectionId: secA._id,
      status: TimetableStatus.PUBLISHED,
      entries: [
        {
          dayOfWeek: TimetableDay.MONDAY,
          startTime: '10:00',
          endTime: '12:00',
          subjectId: subjectIot._id,
          facultyId: facultyDoc1._id,
          facultyAssignmentId: assignmentIot._id,
          sessionType: TimetableSessionType.LECTURE,
        },
      ],
    });
    ttEntryId = timetablePublished.entries[0]._id!.toString();
  });

  // -------------------------------------------------------------------------
  // 1. TimeSlot Normalization Helper
  // -------------------------------------------------------------------------
  describe('1. TimeSlot Normalization Helper', () => {
    it('normalizes en-dash, em-dash, and irregular spaces to canonical "HH:mm - HH:mm"', () => {
      expect(normalizeTimeSlot('10:00 – 12:00')).toBe('10:00 - 12:00'); // en-dash \u2013
      expect(normalizeTimeSlot('10:00 — 12:00')).toBe('10:00 - 12:00'); // em-dash \u2014
      expect(normalizeTimeSlot('10:00-12:00')).toBe('10:00 - 12:00');
      expect(normalizeTimeSlot(' 10:00   –   12:00 ')).toBe('10:00 - 12:00');
      expect(normalizeTimeSlot('9:00 - 10:00')).toBe('09:00 - 10:00');
      expect(normalizeTimeSlot('09:00 - 10:00')).toBe('09:00 - 10:00');
    });

    it('pre-validate hook normalizes timeSlot when AttendanceSession is created or saved', async () => {
      const sess = await AttendanceSession.create({
        collegeId: collegeA._id,
        departmentId: deptA._id,
        facultyId: facultyDoc1._id,
        subjectId: subjectIot._id,
        subjectName: subjectIot.name,
        sectionId: secA._id,
        date: new Date('2026-10-12T00:00:00.000Z'),
        timeSlot: '10:00 – 12:00', // en-dash
        records: [],
      });
      expect(sess.timeSlot).toBe('10:00 - 12:00');
    });
  });

  // -------------------------------------------------------------------------
  // 2. Duplicate Session Prevention across En-Dash and ASCII Hyphen
  // -------------------------------------------------------------------------
  describe('2. Idempotent Session Creation & Duplicate Prevention', () => {
    it('returns the same session when called repeatedly with en-dash vs hyphen', async () => {
      const payload1 = {
        sectionId: secA._id.toString(),
        subjectId: subjectIot._id.toString(),
        timetableId: timetablePublished._id.toString(),
        timetableEntryId: ttEntryId,
        date: '2026-10-12',
        timeSlot: '10:00 - 12:00', // ASCII hyphen
        records: [
          { studentId: student1._id.toString(), status: AttendanceStatus.PRESENT },
          { studentId: student2._id.toString(), status: AttendanceStatus.PRESENT },
        ],
      };

      const res1 = await request(app)
        .post('/api/v1/attendance/sessions')
        .set(headerFaculty1)
        .send(payload1);

      expect(res1.status).toBe(201);
      const sessionId1 = res1.body.data.id || res1.body.data._id;

      // Second request passes unicode EN-DASH '10:00 – 12:00' with updated records
      const payload2 = {
        sectionId: secA._id.toString(),
        subjectId: subjectIot._id.toString(),
        timetableId: timetablePublished._id.toString(),
        timetableEntryId: ttEntryId,
        date: '2026-10-12',
        timeSlot: '10:00 – 12:00', // EN-DASH \u2013
        records: [
          { studentId: student1._id.toString(), status: AttendanceStatus.PRESENT },
          { studentId: student2._id.toString(), status: AttendanceStatus.LATE },
          { studentId: student3._id.toString(), status: AttendanceStatus.PRESENT },
          { studentId: student4._id.toString(), status: AttendanceStatus.EXCUSED },
          { studentId: student5._id.toString(), status: AttendanceStatus.EXCUSED },
        ],
      };

      const res2 = await request(app)
        .post('/api/v1/attendance/sessions')
        .set(headerFaculty1)
        .send(payload2);

      // Must be idempotent: returns the same session ID without creating a duplicate record
      expect([200, 201]).toContain(res2.status);
      const sessionId2 = res2.body.data.id || res2.body.data._id;
      expect(sessionId2).toBe(sessionId1);

      // Database verification: Exactly 1 session exists in database for this date & slot
      const count = await AttendanceSession.countDocuments({
        collegeId: collegeA._id,
        sectionId: secA._id,
        subjectId: subjectIot._id,
        status: { $ne: AttendanceSessionStatus.CANCELLED },
      });
      expect(count).toBe(1);

      // Granular AttendanceRecord count equals 5 records, not 2 + 5 = 7
      const recordCount = await AttendanceRecord.countDocuments({ sessionId: sessionId1 });
      expect(recordCount).toBe(5);
    });

    it('concurrent session creation resolves safely to a single session', async () => {
      const payload = {
        sectionId: secA._id.toString(),
        subjectId: subjectIot._id.toString(),
        timetableId: timetablePublished._id.toString(),
        timetableEntryId: ttEntryId,
        date: '2026-10-12',
        timeSlot: '10:00 - 12:00',
        records: [
          { studentId: student1._id.toString(), status: AttendanceStatus.PRESENT },
        ],
      };

      // Send 3 concurrent requests simultaneously
      const [r1, r2, r3] = await Promise.all([
        request(app).post('/api/v1/attendance/sessions').set(headerFaculty1).send(payload),
        request(app).post('/api/v1/attendance/sessions').set(headerFaculty1).send(payload),
        request(app).post('/api/v1/attendance/sessions').set(headerFaculty1).send(payload),
      ]);

      console.log('r1, r2, r3:', r1.status, r2.status, r3.status);
      if (r2.status === 500) console.log('r2 err:', r2.body);
      if (r3.status === 500) console.log('r3 err:', r3.body);
      expect([200, 201]).toContain(r1.status);
      expect([200, 201]).toContain(r2.status);
      expect([200, 201]).toContain(r3.status);

      const id1 = r1.body.data.id || r1.body.data._id;
      const id2 = r2.body.data.id || r2.body.data._id;
      const id3 = r3.body.data.id || r3.body.data._id;

      expect(id1).toBe(id2);
      expect(id2).toBe(id3);

      const count = await AttendanceSession.countDocuments({
        collegeId: collegeA._id,
        sectionId: secA._id,
        subjectId: subjectIot._id,
      });
      expect(count).toBe(1);
    });

    it('legitimate separate sessions (different date or subject) remain distinct', async () => {
      // Session for Oct 12
      const res1 = await request(app)
        .post('/api/v1/attendance/sessions')
        .set(headerFaculty1)
        .send({
          sectionId: secA._id.toString(),
          subjectId: subjectIot._id.toString(),
          timetableId: timetablePublished._id.toString(),
          timetableEntryId: ttEntryId,
          date: '2026-10-12',
          timeSlot: '10:00 - 12:00',
          records: [{ studentId: student1._id.toString(), status: AttendanceStatus.PRESENT }],
        });

      // Session for Oct 5 (prior week)
      const res2 = await request(app)
        .post('/api/v1/attendance/sessions')
        .set(headerFaculty1)
        .send({
          sectionId: secA._id.toString(),
          subjectId: subjectIot._id.toString(),
          timetableId: timetablePublished._id.toString(),
          timetableEntryId: ttEntryId,
          date: '2026-10-05',
          timeSlot: '10:00 - 12:00',
          records: [{ studentId: student1._id.toString(), status: AttendanceStatus.PRESENT }],
        });

      expect(res1.status).toBe(201);
      expect(res2.status).toBe(201);

      const id1 = res1.body.data.id || res1.body.data._id;
      const id2 = res2.body.data.id || res2.body.data._id;
      expect(id1).not.toBe(id2);

      const count = await AttendanceSession.countDocuments({
        collegeId: collegeA._id,
        sectionId: secA._id,
        subjectId: subjectIot._id,
      });
      expect(count).toBe(2);
    });
  });

  // -------------------------------------------------------------------------
  // 3. Attendance Count Integrity & Invariant Enforcement
  // -------------------------------------------------------------------------
  describe('3. Attendance Count Integrity & Status Breakdown', () => {
    it('breakdown with Present (2), Late (1), Excused (2) correctly sums to Total (5)', async () => {
      const res = await request(app)
        .post('/api/v1/attendance/sessions')
        .set(headerFaculty1)
        .send({
          sectionId: secA._id.toString(),
          subjectId: subjectIot._id.toString(),
          timetableId: timetablePublished._id.toString(),
          timetableEntryId: ttEntryId,
          date: '2026-10-12',
          timeSlot: '10:00 - 12:00',
          records: [
            { studentId: student1._id.toString(), status: AttendanceStatus.PRESENT },
            { studentId: student2._id.toString(), status: AttendanceStatus.LATE },
            { studentId: student3._id.toString(), status: AttendanceStatus.PRESENT },
            { studentId: student4._id.toString(), status: AttendanceStatus.EXCUSED },
            { studentId: student5._id.toString(), status: AttendanceStatus.EXCUSED },
          ],
        });

      expect(res.status).toBe(201);
      const session = res.body.data;
      expect(session.records.length).toBe(5);

      const present = session.records.filter((r: any) => r.status === AttendanceStatus.PRESENT).length;
      const late = session.records.filter((r: any) => r.status === AttendanceStatus.LATE).length;
      const excused = session.records.filter((r: any) => r.status === AttendanceStatus.EXCUSED).length;
      const absent = session.records.filter((r: any) => r.status === AttendanceStatus.ABSENT).length;

      expect(present).toBe(2);
      expect(late).toBe(1);
      expect(excused).toBe(2);
      expect(absent).toBe(0);

      // Invariant: present + late + absent + excused = total
      expect(present + late + absent + excused).toBe(5);
    });

    it('distinguishes explicit absence from unmarked attendance without auto-marking', async () => {
      // Submit attendance for only 3 students: 1 present, 1 late, 1 absent
      const res = await request(app)
        .post('/api/v1/attendance/sessions')
        .set(headerFaculty1)
        .send({
          sectionId: secA._id.toString(),
          subjectId: subjectIot._id.toString(),
          timetableId: timetablePublished._id.toString(),
          timetableEntryId: ttEntryId,
          date: '2026-10-12',
          timeSlot: '10:00 - 12:00',
          records: [
            { studentId: student1._id.toString(), status: AttendanceStatus.PRESENT },
            { studentId: student2._id.toString(), status: AttendanceStatus.LATE },
            { studentId: student3._id.toString(), status: AttendanceStatus.ABSENT },
          ],
        });

      expect(res.status).toBe(201);
      const session = res.body.data;
      expect(session.records.length).toBe(3);

      const absentCount = session.records.filter((r: any) => r.status === AttendanceStatus.ABSENT).length;
      expect(absentCount).toBe(1); // Exactly 1 explicitly marked absent, unrecorded students (student4, student5) are not auto-marked absent
    });

    it('rejects student not enrolled in the section (roster integrity)', async () => {
      // Create student not enrolled in secA
      const otherUser = await User.create({
        collegeId: collegeA._id,
        email: 'otherstd@student.edu',
        name: 'Other Student',
        role: AppRole.STUDENT,
        status: AccountStatus.ACTIVE,
      });
      const otherStudent = await Student.create({
        collegeId: collegeA._id,
        departmentId: deptA._id,
        courseId: courseA._id,
        academicYearId: ayA._id,
        semesterId: semA._id,
        userId: otherUser._id,
        name: 'Other Student',
        rollNumber: 'OTH999',
        admissionNumber: 'ADM-OTH999',
        status: 'active',
      });

      const res = await request(app)
        .post('/api/v1/attendance/sessions')
        .set(headerFaculty1)
        .send({
          sectionId: secA._id.toString(),
          subjectId: subjectIot._id.toString(),
          timetableId: timetablePublished._id.toString(),
          timetableEntryId: ttEntryId,
          date: '2026-10-12',
          timeSlot: '10:00 - 12:00',
          records: [
            { studentId: otherStudent._id.toString(), status: AttendanceStatus.PRESENT },
          ],
        });

      expect(res.status).toBe(400);
      expect(res.body.error?.message || res.body.message).toMatch(/is not enrolled/i);
    });
  });

  // -------------------------------------------------------------------------
  // 4. Lifecycle & Authorization Controls
  // -------------------------------------------------------------------------
  describe('4. Lifecycle & Authorization Controls', () => {
    it('prevents modification of LOCKED sessions', async () => {
      await AttendanceSession.create({
        collegeId: collegeA._id,
        departmentId: deptA._id,
        facultyId: facultyDoc1._id,
        subjectId: subjectIot._id,
        subjectName: subjectIot.name,
        sectionId: secA._id,
        date: new Date('2026-10-12T00:00:00.000Z'),
        timeSlot: '10:00 - 12:00',
        status: AttendanceSessionStatus.LOCKED,
        isLocked: true,
        records: [],
      });

      const res = await request(app)
        .post('/api/v1/attendance/sessions')
        .set(headerFaculty1)
        .send({
          sectionId: secA._id.toString(),
          subjectId: subjectIot._id.toString(),
          date: '2026-10-12',
          timeSlot: '10:00 - 12:00',
          records: [{ studentId: student1._id.toString(), status: AttendanceStatus.PRESENT }],
        });

      expect(res.status).toBe(400);
      expect(res.body.error?.message || res.body.message).toMatch(/session is locked/i);
    });

    it('prevents modification of CLOSED sessions', async () => {
      await AttendanceSession.create({
        collegeId: collegeA._id,
        departmentId: deptA._id,
        facultyId: facultyDoc1._id,
        subjectId: subjectIot._id,
        subjectName: subjectIot.name,
        sectionId: secA._id,
        date: new Date('2026-10-12T00:00:00.000Z'),
        timeSlot: '10:00 - 12:00',
        status: AttendanceSessionStatus.CLOSED,
        records: [],
      });

      const res = await request(app)
        .post('/api/v1/attendance/sessions')
        .set(headerFaculty1)
        .send({
          sectionId: secA._id.toString(),
          subjectId: subjectIot._id.toString(),
          date: '2026-10-12',
          timeSlot: '10:00 - 12:00',
          records: [{ studentId: student1._id.toString(), status: AttendanceStatus.PRESENT }],
        });

      expect(res.status).toBe(400);
      expect(res.body.error?.message || res.body.message).toMatch(/session is closed/i);
    });

    it('prevents unauthorized faculty from modifying another faculty session', async () => {
      await AttendanceSession.create({
        collegeId: collegeA._id,
        departmentId: deptA._id,
        facultyId: facultyDoc1._id, // Mani
        subjectId: subjectIot._id,
        subjectName: subjectIot.name,
        sectionId: secA._id,
        date: new Date('2026-10-12T00:00:00.000Z'),
        timeSlot: '10:00 - 12:00',
        status: AttendanceSessionStatus.OPEN,
        records: [],
      });

      // Faculty 2 attempts to submit attendance for Faculty 1's occurrence
      const res = await request(app)
        .post('/api/v1/attendance/sessions')
        .set(headerFaculty2)
        .send({
          sectionId: secA._id.toString(),
          subjectId: subjectIot._id.toString(),
          date: '2026-10-12',
          timeSlot: '10:00 - 12:00',
          records: [{ studentId: student1._id.toString(), status: AttendanceStatus.PRESENT }],
        });

      expect(res.status).toBe(403);
      expect(res.body.error?.message || res.body.message).toMatch(/assigned to another faculty|not authorized|does not match/i);
    });

    it('prevents cross-college session access and history retrieval', async () => {
      const deptB = await Department.create({
        collegeId: collegeB._id,
        name: 'Beta Department',
        code: 'BETADEPT',
        status: DepartmentStatus.ACTIVE,
      });
      const userCollegeB = await User.create({
        collegeId: collegeB._id,
        departmentId: deptB._id,
        email: 'faculty@collegeb.edu',
        name: 'Faculty Beta',
        role: AppRole.FACULTY,
        status: AccountStatus.ACTIVE,
      });
      await Faculty.create({
        collegeId: collegeB._id,
        departmentId: deptB._id,
        userId: userCollegeB._id,
        name: 'Faculty Beta',
        employeeId: 'EMP-BETA-01',
        email: 'faculty@collegeb.edu',
        designation: 'Professor',
        status: 'active',
        isActive: true,
      });
      const headerCollegeB = createTestAuthHeader({
        userId: userCollegeB._id.toString(),
        collegeId: collegeB._id.toString(),
        role: AppRole.FACULTY,
        email: userCollegeB.email,
      });

      const res = await request(app)
        .get('/api/v1/attendance/faculty/me')
        .set(headerCollegeB);

      // Faculty in College B cannot see College A sessions
      expect([200, 404]).toContain(res.status);
      if (res.status === 200) {
        expect(res.body.data.length).toBe(0);
      }
    });
  });
});
