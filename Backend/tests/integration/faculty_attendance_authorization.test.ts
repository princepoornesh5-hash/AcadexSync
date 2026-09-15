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
import { Room } from '../../src/models/room.model';
import { Timetable } from '../../src/models/timetable.model';
import { FacultyAssignment } from '../../src/models/facultyAssignment.model';
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
import { PasswordService } from '../../src/services/password.service';

describe('ACADEX — Faculty-Scoped Timetable & Strict Attendance Authorization Integration Tests', () => {
  let collegeA: InstanceType<typeof College>;
  let collegeB: InstanceType<typeof College>;

  let deptA1: InstanceType<typeof Department>;
  let deptB1: InstanceType<typeof Department>;

  let courseA: InstanceType<typeof Course>;
  let academicYearA: InstanceType<typeof AcademicYear>;
  let semesterA5: InstanceType<typeof Semester>;
  let sectionA: InstanceType<typeof Section>;
  let sectionA2: InstanceType<typeof Section>;

  let courseB: InstanceType<typeof Course>;
  let academicYearB: InstanceType<typeof AcademicYear>;
  let semesterB5: InstanceType<typeof Semester>;

  let subjectMath: InstanceType<typeof Subject>;
  let subjectChem: InstanceType<typeof Subject>;

  let facultyUserA: InstanceType<typeof User>;
  let facultyProfileA: InstanceType<typeof Faculty>;
  let facultyUserB: InstanceType<typeof User>;
  let facultyProfileB: InstanceType<typeof Faculty>;

  let facultyUserCollegeB: InstanceType<typeof User>;

  let studentUser1: InstanceType<typeof User>;
  let studentProfile1: InstanceType<typeof Student>;
  let studentUser2: InstanceType<typeof User>;
  let studentProfile2: InstanceType<typeof Student>;

  let assignmentA: InstanceType<typeof FacultyAssignment>;
  let assignmentB: InstanceType<typeof FacultyAssignment>;

  let publishedTimetableA: InstanceType<typeof Timetable>;

  let facultyAHeader: { Authorization: string };
  let facultyBHeader: { Authorization: string };
  let facultyCollegeBHeader: { Authorization: string };
  let studentHeader: { Authorization: string };

  let defaultPasswordHash: string;

  beforeAll(async () => {
    defaultPasswordHash = await PasswordService.hashPassword('Pass1234!');
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
    await Room.init();
    await Timetable.init();
    await FacultyAssignment.init();
    await AttendanceSession.init();
    await AttendanceRecord.init();
    await AuditLog.init();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();

    // 1. Colleges
    collegeA = await College.create({
      name: 'College Alpha',
      code: 'ALPHA',
      address: '100 Alpha Campus',
      email: 'admin@alpha.edu',
      phone: '+919988776601',
      principal: 'Dr. Alpha Principal',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });

    collegeB = await College.create({
      name: 'College Beta',
      code: 'BETA',
      address: '200 Beta Campus',
      email: 'admin@beta.edu',
      phone: '+919988776602',
      principal: 'Dr. Beta Principal',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });

    // 2. Departments
    deptA1 = await Department.create({
      collegeId: collegeA._id,
      name: 'Dept of Science',
      code: 'SCI',
      status: DepartmentStatus.ACTIVE,
      isActive: true,
    });

    deptB1 = await Department.create({
      collegeId: collegeB._id,
      name: 'Beta Science',
      code: 'BSCI',
      status: DepartmentStatus.ACTIVE,
      isActive: true,
    });

    // 3. Academic Structure College A
    courseA = await Course.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      name: 'B.Sc Computer Science',
      code: 'BSCCS',
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
      semesterId: semesterA5._id,
      academicYearId: academicYearA._id,
      name: 'Section Alpha',
      capacity: 60,
      isActive: true,
    });

    sectionA2 = await Section.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      courseId: courseA._id,
      semesterId: semesterA5._id,
      academicYearId: academicYearA._id,
      name: 'Section Alpha 2',
      capacity: 60,
      isActive: true,
    });

    // Academic Structure College B
    courseB = await Course.create({
      collegeId: collegeB._id,
      departmentId: deptB1._id,
      name: 'Beta Engineering',
      code: 'BENG',
      duration: 4,
      isActive: true,
    });

    academicYearB = await AcademicYear.create({
      collegeId: collegeB._id,
      name: '2026-2027',
      startDate: new Date('2026-06-01'),
      endDate: new Date('2027-05-31'),
      isCurrent: true,
      isActive: true,
    });

    semesterB5 = await Semester.create({
      collegeId: collegeB._id,
      departmentId: deptB1._id,
      courseId: courseB._id,
      academicYearId: academicYearB._id,
      name: 'Semester 5',
      number: 5,
      isActive: true,
    });

    await Section.create({
      collegeId: collegeB._id,
      departmentId: deptB1._id,
      courseId: courseB._id,
      semesterId: semesterB5._id,
      academicYearId: academicYearB._id,
      name: 'Section Beta',
      capacity: 50,
      isActive: true,
    });

    // 4. Subjects
    subjectMath = await Subject.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      courseId: courseA._id,
      semesterId: semesterA5._id,
      name: 'Mathematics',
      code: 'MATH-301',
      credits: 4,
      status: 'active',
      isActive: true,
    });

    subjectChem = await Subject.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      courseId: courseA._id,
      semesterId: semesterA5._id,
      name: 'Chemistry',
      code: 'CHEM-301',
      credits: 3,
      status: 'active',
      isActive: true,
    });

    // 5. Faculty Users & Profiles
    facultyUserA = await User.create({
      instituteId: 'FAC-MATH-01',
      name: 'Dr. Math Specialist (Faculty A)',
      email: 'fac.a@alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.FACULTY,
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    facultyProfileA = await Faculty.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      userId: facultyUserA._id,
      instituteId: facultyUserA.instituteId,
      name: facultyUserA.name,
      email: facultyUserA.email,
      designation: 'Professor',
      status: 'active',
      isActive: true,
    });

    facultyUserB = await User.create({
      instituteId: 'FAC-CHEM-02',
      name: 'Dr. Chem Specialist (Faculty B)',
      email: 'fac.b@alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.FACULTY,
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    facultyProfileB = await Faculty.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      userId: facultyUserB._id,
      instituteId: facultyUserB.instituteId,
      name: facultyUserB.name,
      email: facultyUserB.email,
      designation: 'Associate Professor',
      status: 'active',
      isActive: true,
    });

    // College B Faculty
    facultyUserCollegeB = await User.create({
      instituteId: 'FAC-COL-B-01',
      name: 'Dr. Beta Professor',
      email: 'prof@beta.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.FACULTY,
      collegeId: collegeB._id,
      departmentId: deptB1._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    await Faculty.create({
      collegeId: collegeB._id,
      departmentId: deptB1._id,
      userId: facultyUserCollegeB._id,
      instituteId: facultyUserCollegeB.instituteId,
      name: facultyUserCollegeB.name,
      email: facultyUserCollegeB.email,
      designation: 'Professor',
      status: 'active',
      isActive: true,
    });

    // 6. Students
    studentUser1 = await User.create({
      instituteId: 'STU-ALPHA-01',
      name: 'Student One',
      email: 's1@alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.STUDENT,
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    studentProfile1 = await Student.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      userId: studentUser1._id,
      instituteId: studentUser1.instituteId,
      name: studentUser1.name,
      email: studentUser1.email,
      rollNumber: 'SEC-A-01',
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
      studentId: studentProfile1._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA5._id,
      sectionId: sectionA._id,
      status: 'active',
    });

    studentUser2 = await User.create({
      instituteId: 'STU-ALPHA-02',
      name: 'Student Two',
      email: 's2@alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.STUDENT,
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    studentProfile2 = await Student.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      userId: studentUser2._id,
      instituteId: studentUser2.instituteId,
      name: studentUser2.name,
      email: studentUser2.email,
      rollNumber: 'SEC-A-02',
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
      studentId: studentProfile2._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA5._id,
      sectionId: sectionA._id,
      status: 'active',
    });

    // 7. Authoritative Faculty Assignments
    assignmentA = await FacultyAssignment.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      facultyId: facultyProfileA._id,
      facultyName: facultyProfileA.name,
      courseId: courseA._id,
      semesterId: semesterA5._id,
      sectionId: sectionA._id,
      subjectId: subjectMath._id,
      academicYearId: academicYearA._id,
      isActive: true,
    });

    assignmentB = await FacultyAssignment.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      facultyId: facultyProfileB._id,
      facultyName: facultyProfileB.name,
      courseId: courseA._id,
      semesterId: semesterA5._id,
      sectionId: sectionA._id,
      subjectId: subjectChem._id,
      academicYearId: academicYearA._id,
      isActive: true,
    });

    // 8. Published Timetable for Section A
    // Period 1 (09:00 - 10:00): Math -> Faculty A
    // Period 2 (10:00 - 11:00): Chem -> Faculty B
    publishedTimetableA = await Timetable.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA5._id,
      sectionId: sectionA._id,
      name: 'Fall 2026 Mathematics & Chemistry Schedule',
      status: TimetableStatus.PUBLISHED,
      entries: [
        {
          dayOfWeek: TimetableDay.MONDAY,
          startTime: '09:00',
          endTime: '10:00',
          subjectId: subjectMath._id,
          facultyId: facultyProfileA._id,
          facultyAssignmentId: assignmentA._id,
          roomNumber: 'LH-101',
        },
        {
          dayOfWeek: TimetableDay.MONDAY,
          startTime: '10:00',
          endTime: '11:00',
          subjectId: subjectChem._id,
          facultyId: facultyProfileB._id,
          facultyAssignmentId: assignmentB._id,
          roomNumber: 'LH-102',
        },
      ],
    });

    // 9. Auth Headers
    facultyAHeader = createTestAuthHeader({
      userId: facultyUserA.id,
      instituteId: facultyUserA.instituteId,
      collegeId: collegeA.id,
      departmentId: deptA1.id,
      role: AppRole.FACULTY,
    });

    facultyBHeader = createTestAuthHeader({
      userId: facultyUserB.id,
      instituteId: facultyUserB.instituteId,
      collegeId: collegeA.id,
      departmentId: deptA1.id,
      role: AppRole.FACULTY,
    });

    facultyCollegeBHeader = createTestAuthHeader({
      userId: facultyUserCollegeB.id,
      instituteId: facultyUserCollegeB.instituteId,
      collegeId: collegeB.id,
      departmentId: deptB1.id,
      role: AppRole.FACULTY,
    });

    studentHeader = createTestAuthHeader({
      userId: studentUser1.id,
      instituteId: studentUser1.instituteId,
      collegeId: collegeA.id,
      departmentId: deptA1.id,
      role: AppRole.STUDENT,
    });
  });

  const getMsg = (res: any) => res.body.error?.message || res.body.message || '';

  // =========================================================================
  // POSITIVE TESTS (1 - 5)
  // =========================================================================

  it('1. FACULTY can retrieve own timetable via /timetables/faculty/me and /timetables/faculty/:id', async () => {
    // Via /faculty/me
    const resMe = await request(app)
      .get('/api/v1/timetables/faculty/me')
      .set(facultyAHeader);

    expect(resMe.status).toBe(200);
    expect(resMe.body.success).toBe(true);
    expect(resMe.body.data).toBeInstanceOf(Array);
    // Should have 1 entry (Math)
    expect(resMe.body.data).toHaveLength(1);
    expect(resMe.body.data[0].subjectId).toBe(subjectMath.id);

    // Via /faculty/:id with own faculty profile ID
    const resOwnId = await request(app)
      .get(`/api/v1/timetables/faculty/${facultyProfileA.id}`)
      .set(facultyAHeader);

    expect(resOwnId.status).toBe(200);
    expect(resOwnId.body.data).toHaveLength(1);
    expect(resOwnId.body.data[0].subjectId).toBe(subjectMath.id);
  });

  it('2. FACULTY sees only own classes when querying schedule', async () => {
    const resFacultyB = await request(app)
      .get('/api/v1/timetables/faculty/me')
      .set(facultyBHeader);

    expect(resFacultyB.status).toBe(200);
    expect(resFacultyB.body.data).toHaveLength(1);
    expect(resFacultyB.body.data[0].subjectId).toBe(subjectChem.id);
    expect(resFacultyB.body.data[0].startTime).toBe('10:00');
    // Math period (09:00 - 10:00) assigned to Faculty A is NOT returned
    const mathEntry = resFacultyB.body.data.find((e: any) => e.subjectId === subjectMath.id);
    expect(mathEntry).toBeUndefined();
  });

  it('3. FACULTY can open own authorized attendance session', async () => {
    const mondayDate = '2026-08-24T09:00:00.000Z'; // Monday
    const mathEntryId = publishedTimetableA.entries[0]._id!.toString();

    const resOpen = await request(app)
      .post('/api/v1/attendance/sessions')
      .set(facultyAHeader)
      .send({
        timetableId: publishedTimetableA.id,
        timetableEntryId: mathEntryId,
        sectionId: sectionA.id,
        subjectId: subjectMath.id,
        date: mondayDate,
        timeSlot: '09:00 - 10:00',
        records: [],
      });

    expect(resOpen.status).toBe(201);
    expect(resOpen.body.data.status).toBe(AttendanceSessionStatus.OPEN);
    expect(resOpen.body.data.subjectId).toBe(subjectMath.id);
    expect(resOpen.body.data.facultyId).toBe(facultyProfileA.id);
    expect(resOpen.body.data.facultyAssignmentId).toBe(assignmentA.id);

    // Verify session persisted in DB
    const saved = await AttendanceSession.findById(resOpen.body.data.id);
    expect(saved).not.toBeNull();
    expect(saved!.facultyId.toString()).toBe(facultyProfileA.id);
  });

  it('4. FACULTY can submit attendance for own authorized class', async () => {
    const mondayDate = '2026-08-24T09:00:00.000Z';
    const mathEntryId = publishedTimetableA.entries[0]._id!.toString();

    const resSubmit = await request(app)
      .post('/api/v1/attendance/sessions')
      .set(facultyAHeader)
      .send({
        timetableId: publishedTimetableA.id,
        timetableEntryId: mathEntryId,
        sectionId: sectionA.id,
        subjectId: subjectMath.id,
        date: mondayDate,
        timeSlot: '09:00 - 10:00',
        records: [
          { studentId: studentProfile1.id, status: AttendanceStatus.PRESENT },
          { studentId: studentProfile2.id, status: AttendanceStatus.ABSENT },
        ],
      });

    expect(resSubmit.status).toBe(201);
    expect(resSubmit.body.data.records).toHaveLength(2);

    const dbRecords = await AttendanceRecord.find({ sessionId: resSubmit.body.data.id });
    expect(dbRecords).toHaveLength(2);
  });

  it('5. FACULTY can update attendance where business rules allow it', async () => {
    const mondayDate = '2026-08-24T09:00:00.000Z';
    const mathEntryId = publishedTimetableA.entries[0]._id!.toString();

    // 1. Create open session
    const resCreate = await request(app)
      .post('/api/v1/attendance/sessions')
      .set(facultyAHeader)
      .send({
        timetableId: publishedTimetableA.id,
        timetableEntryId: mathEntryId,
        sectionId: sectionA.id,
        subjectId: subjectMath.id,
        date: mondayDate,
        timeSlot: '09:00 - 10:00',
        records: [
          { studentId: studentProfile1.id, status: AttendanceStatus.ABSENT },
        ],
      });
    expect(resCreate.status).toBe(201);
    const sessionId = resCreate.body.data.id;

    // 2. Update attendance records while session is OPEN
    const resUpdate = await request(app)
      .post(`/api/v1/attendance/sessions/${sessionId}/records`)
      .set(facultyAHeader)
      .send({
        records: [
          { studentId: studentProfile1.id, status: AttendanceStatus.PRESENT },
          { studentId: studentProfile2.id, status: AttendanceStatus.LATE },
        ],
      });

    expect(resUpdate.status).toBe(200);
    const updatedRecord = await AttendanceRecord.findOne({
      sessionId,
      studentId: studentProfile1._id,
    });
    expect(updatedRecord!.status).toBe(AttendanceStatus.PRESENT);
  });

  // =========================================================================
  // NEGATIVE & SECURITY AUTHORIZATION TESTS (6 - 20)
  // =========================================================================

  it('6. FACULTY cannot retrieve another faculty\'s restricted timetable (403 Forbidden)', async () => {
    const resForbidden = await request(app)
      .get(`/api/v1/timetables/faculty/${facultyProfileA.id}`)
      .set(facultyBHeader);

    expect(resForbidden.status).toBe(403);
    expect(getMsg(resForbidden)).toContain('Faculty members can only access their own timetable schedule');
  });

  it('7. FACULTY cannot open another faculty\'s attendance session (403 Forbidden)', async () => {
    const mondayDate = '2026-08-24T09:00:00.000Z';
    const mathEntryId = publishedTimetableA.entries[0]._id!.toString();

    // Faculty A creates session
    const sessionRes = await request(app)
      .post('/api/v1/attendance/sessions')
      .set(facultyAHeader)
      .send({
        timetableId: publishedTimetableA.id,
        timetableEntryId: mathEntryId,
        sectionId: sectionA.id,
        subjectId: subjectMath.id,
        date: mondayDate,
        timeSlot: '09:00 - 10:00',
        records: [{ studentId: studentProfile1.id, status: AttendanceStatus.PRESENT }],
      });
    expect(sessionRes.status).toBe(201);
    const sessionId = sessionRes.body.data.id;

    // Faculty B attempts to view/open Faculty A's session
    const resOtherFaculty = await request(app)
      .get(`/api/v1/attendance/sessions/${sessionId}`)
      .set(facultyBHeader);

    expect(resOtherFaculty.status).toBe(403);
    expect(getMsg(resOtherFaculty)).toContain('not authorized');
  });

  it('8. FACULTY cannot create attendance for another faculty\'s timetable entry (403 Forbidden)', async () => {
    const mondayDate = '2026-08-24T09:00:00.000Z';
    const mathEntryId = publishedTimetableA.entries[0]._id!.toString(); // Math belongs to Faculty A

    const preSessionCount = await AttendanceSession.countDocuments();
    const preRecordCount = await AttendanceRecord.countDocuments();

    // Faculty B attempts to mark attendance for Faculty A's period
    const resForbidden = await request(app)
      .post('/api/v1/attendance/sessions')
      .set(facultyBHeader)
      .send({
        timetableId: publishedTimetableA.id,
        timetableEntryId: mathEntryId,
        sectionId: sectionA.id,
        subjectId: subjectMath.id,
        date: mondayDate,
        timeSlot: '09:00 - 10:00',
        records: [{ studentId: studentProfile1.id, status: AttendanceStatus.PRESENT }],
      });

    expect(resForbidden.status).toBe(403);
    expect(getMsg(resForbidden)).toContain('Faculty is not authorized to mark attendance for this class');

    // State assertion: DB must remain completely unmodified
    const postSessionCount = await AttendanceSession.countDocuments();
    const postRecordCount = await AttendanceRecord.countDocuments();
    expect(postSessionCount).toBe(preSessionCount);
    expect(postRecordCount).toBe(preRecordCount);
  });

  it('9. FACULTY cannot modify another faculty\'s attendance records (403 Forbidden)', async () => {
    const mondayDate = '2026-08-24T09:00:00.000Z';
    const mathEntryId = publishedTimetableA.entries[0]._id!.toString();

    // Faculty A creates valid session
    const sessionRes = await request(app)
      .post('/api/v1/attendance/sessions')
      .set(facultyAHeader)
      .send({
        timetableId: publishedTimetableA.id,
        timetableEntryId: mathEntryId,
        sectionId: sectionA.id,
        subjectId: subjectMath.id,
        date: mondayDate,
        timeSlot: '09:00 - 10:00',
        records: [{ studentId: studentProfile1.id, status: AttendanceStatus.PRESENT }],
      });
    expect(sessionRes.status).toBe(201);
    const sessionId = sessionRes.body.data.id;

    // Faculty B attempts to modify records of Faculty A's session
    const resTamper = await request(app)
      .post(`/api/v1/attendance/sessions/${sessionId}/records`)
      .set(facultyBHeader)
      .send({
        records: [{ studentId: studentProfile1.id, status: AttendanceStatus.ABSENT }],
      });

    expect(resTamper.status).toBe(403);
    expect(getMsg(resTamper)).toContain('not authorized');

    // Assert student 1 record is still PRESENT
    const record = await AttendanceRecord.findOne({ sessionId, studentId: studentProfile1._id });
    expect(record!.status).toBe(AttendanceStatus.PRESENT);
  });

  it('10. facultyId tampering fails (attempting to supply another facultyId in body)', async () => {
    const mondayDate = '2026-08-24T09:00:00.000Z';
    const mathEntryId = publishedTimetableA.entries[0]._id!.toString();

    const preSessionCount = await AttendanceSession.countDocuments();

    // Faculty B sends authenticated token, but supplies facultyId of Faculty A in request body
    const resTamper = await request(app)
      .post('/api/v1/attendance/sessions')
      .set(facultyBHeader)
      .send({
        timetableId: publishedTimetableA.id,
        timetableEntryId: mathEntryId,
        sectionId: sectionA.id,
        subjectId: subjectMath.id,
        facultyId: facultyProfileA.id, // TAMPERING: claiming to be Faculty A
        date: mondayDate,
        timeSlot: '09:00 - 10:00',
        records: [{ studentId: studentProfile1.id, status: AttendanceStatus.PRESENT }],
      });

    expect(resTamper.status).toBe(403);
    expect(getMsg(resTamper)).toContain('not authorized');

    const postSessionCount = await AttendanceSession.countDocuments();
    expect(postSessionCount).toBe(preSessionCount);
  });

  it('11. facultyAssignmentId tampering fails (Faculty B supplies Faculty A assignmentId)', async () => {
    const mondayDate = '2026-08-24T09:00:00.000Z';
    const mathEntryId = publishedTimetableA.entries[0]._id!.toString();

    const preSessionCount = await AttendanceSession.countDocuments();

    const resTamper = await request(app)
      .post('/api/v1/attendance/sessions')
      .set(facultyBHeader)
      .send({
        timetableId: publishedTimetableA.id,
        timetableEntryId: mathEntryId,
        sectionId: sectionA.id,
        subjectId: subjectMath.id,
        facultyAssignmentId: assignmentA.id, // TAMPERING: passing Faculty A assignment
        date: mondayDate,
        timeSlot: '09:00 - 10:00',
        records: [{ studentId: studentProfile1.id, status: AttendanceStatus.PRESENT }],
      });

    expect(resTamper.status).toBe(403);

    const postSessionCount = await AttendanceSession.countDocuments();
    expect(postSessionCount).toBe(preSessionCount);
  });

  it('12. timetableId tampering fails (tampering timetableId with invalid/mismatched id)', async () => {
    const mondayDate = '2026-08-24T09:00:00.000Z';
    const fakeTimetableId = new mongoose.Types.ObjectId().toString();
    const fakeEntryId = new mongoose.Types.ObjectId().toString();

    const resTamper = await request(app)
      .post('/api/v1/attendance/sessions')
      .set(facultyAHeader)
      .send({
        timetableId: fakeTimetableId,
        timetableEntryId: fakeEntryId,
        sectionId: sectionA.id,
        subjectId: subjectMath.id,
        date: mondayDate,
        timeSlot: '09:00 - 10:00',
      });

    expect(resTamper.status).toBe(404);
  });

  it('13. subjectId tampering fails (subject does not match timetable entry)', async () => {
    const mondayDate = '2026-08-24T09:00:00.000Z';
    const mathEntryId = publishedTimetableA.entries[0]._id!.toString();

    // Faculty A tampers with subjectId, sending Chemistry subjectId for Math entry
    const resTamper = await request(app)
      .post('/api/v1/attendance/sessions')
      .set(facultyAHeader)
      .send({
        timetableId: publishedTimetableA.id,
        timetableEntryId: mathEntryId,
        sectionId: sectionA.id,
        subjectId: subjectChem.id, // TAMPERING: does not match Math entry
        date: mondayDate,
        timeSlot: '09:00 - 10:00',
      });

    expect(resTamper.status).toBe(400);
    expect(getMsg(resTamper)).toContain('Subject mismatch with timetable entry');
  });

  it('14. sectionId tampering fails (section does not match timetable section)', async () => {
    const mondayDate = '2026-08-24T09:00:00.000Z';
    const mathEntryId = publishedTimetableA.entries[0]._id!.toString();

    // Tampering sectionId with Section Alpha 2 from same college
    const resTamper = await request(app)
      .post('/api/v1/attendance/sessions')
      .set(facultyAHeader)
      .send({
        timetableId: publishedTimetableA.id,
        timetableEntryId: mathEntryId,
        sectionId: sectionA2.id, // TAMPERING: section mismatch
        subjectId: subjectMath.id,
        date: mondayDate,
        timeSlot: '09:00 - 10:00',
      });

    expect(resTamper.status).toBe(400);
    expect(getMsg(resTamper)).toContain('Section mismatch with timetable entry');
  });

  it('15. attendanceSessionId tampering fails (Faculty B mutates Faculty A session lifecycle)', async () => {
    const mondayDate = '2026-08-24T09:00:00.000Z';
    const mathEntryId = publishedTimetableA.entries[0]._id!.toString();

    // Faculty A creates session
    const sessionRes = await request(app)
      .post('/api/v1/attendance/sessions')
      .set(facultyAHeader)
      .send({
        timetableId: publishedTimetableA.id,
        timetableEntryId: mathEntryId,
        sectionId: sectionA.id,
        subjectId: subjectMath.id,
        date: mondayDate,
        timeSlot: '09:00 - 10:00',
      });
    expect(sessionRes.status).toBe(201);
    const sessionId = sessionRes.body.data.id;

    // Faculty B attempts to lock Faculty A's session
    const resLock = await request(app)
      .post(`/api/v1/attendance/sessions/${sessionId}/lock`)
      .set(facultyBHeader);

    expect(resLock.status).toBe(403);
    expect(getMsg(resLock)).toContain('not authorized');

    // Assert session status is still OPEN, not locked
    const sessionInDb = await AttendanceSession.findById(sessionId);
    expect(sessionInDb!.status).toBe(AttendanceSessionStatus.OPEN);
  });

  it('16. date tampering fails (session date day of week does not match timetable scheduled day)', async () => {
    // 2026-08-25 is Tuesday, but timetable period is scheduled on Monday
    const tuesdayDate = '2026-08-25T09:00:00.000Z';
    const mathEntryId = publishedTimetableA.entries[0]._id!.toString();

    const preSessionCount = await AttendanceSession.countDocuments();

    const resDayMismatch = await request(app)
      .post('/api/v1/attendance/sessions')
      .set(facultyAHeader)
      .send({
        timetableId: publishedTimetableA.id,
        timetableEntryId: mathEntryId,
        sectionId: sectionA.id,
        subjectId: subjectMath.id,
        date: tuesdayDate,
        timeSlot: '09:00 - 10:00',
      });

    expect(resDayMismatch.status).toBe(400);
    expect(getMsg(resDayMismatch)).toContain('Scheduled day mismatch');

    const postSessionCount = await AttendanceSession.countDocuments();
    expect(postSessionCount).toBe(preSessionCount);
  });

  it('17. academic-context tampering fails (unassigned subject/section without timetable)', async () => {
    const mondayDate = '2026-08-24T09:00:00.000Z';

    // Faculty A tries to create session directly for subjectChem which is assigned to Faculty B
    const resTamper = await request(app)
      .post('/api/v1/attendance/sessions')
      .set(facultyAHeader)
      .send({
        sectionId: sectionA.id,
        subjectId: subjectChem.id, // Chemistry is assigned to Faculty B
        date: mondayDate,
        timeSlot: '10:00 - 11:00',
      });

    expect(resTamper.status).toBe(403);
    expect(getMsg(resTamper)).toContain('Faculty assignment does not match this subject and section');
  });

  it('18. STUDENT cannot mutate attendance (POST session / POST records / POST lock rejected with 403)', async () => {
    const mondayDate = '2026-08-24T09:00:00.000Z';
    const mathEntryId = publishedTimetableA.entries[0]._id!.toString();

    // 1. Student attempts to create session
    const resCreate = await request(app)
      .post('/api/v1/attendance/sessions')
      .set(studentHeader)
      .send({
        timetableId: publishedTimetableA.id,
        timetableEntryId: mathEntryId,
        sectionId: sectionA.id,
        subjectId: subjectMath.id,
        date: mondayDate,
        timeSlot: '09:00 - 10:00',
      });
    expect(resCreate.status).toBe(403);

    // Create a legitimate session by Faculty A
    const facultySession = await request(app)
      .post('/api/v1/attendance/sessions')
      .set(facultyAHeader)
      .send({
        timetableId: publishedTimetableA.id,
        timetableEntryId: mathEntryId,
        sectionId: sectionA.id,
        subjectId: subjectMath.id,
        date: mondayDate,
        timeSlot: '09:00 - 10:00',
      });
    const sessionId = facultySession.body.data.id;

    // 2. Student attempts to add records
    const resRecords = await request(app)
      .post(`/api/v1/attendance/sessions/${sessionId}/records`)
      .set(studentHeader)
      .send({
        records: [{ studentId: studentProfile1.id, status: AttendanceStatus.PRESENT }],
      });
    expect(resRecords.status).toBe(403);

    // 3. Student attempts to lock session
    const resLock = await request(app)
      .post(`/api/v1/attendance/sessions/${sessionId}/lock`)
      .set(studentHeader);
    expect(resLock.status).toBe(403);
  });

  it('19. cross-college access fails (Faculty from College B cannot access College A schedule or session)', async () => {
    // 1. Faculty College B attempts to query College A's timetable
    const resTt = await request(app)
      .get(`/api/v1/timetables/${publishedTimetableA.id}`)
      .set(facultyCollegeBHeader);
    expect([403, 404]).toContain(resTt.status);

    // 2. Faculty College B attempts to create attendance for College A timetable
    const mondayDate = '2026-08-24T09:00:00.000Z';
    const mathEntryId = publishedTimetableA.entries[0]._id!.toString();
    const resAtt = await request(app)
      .post('/api/v1/attendance/sessions')
      .set(facultyCollegeBHeader)
      .send({
        timetableId: publishedTimetableA.id,
        timetableEntryId: mathEntryId,
        sectionId: sectionA.id,
        subjectId: subjectMath.id,
        date: mondayDate,
        timeSlot: '09:00 - 10:00',
      });
    expect([400, 403]).toContain(resAtt.status);
  });

  it('20. unauthorized concurrency fails (concurrent authorized + unauthorized requests: zero corruption)', async () => {
    const mondayDate = '2026-08-24T09:00:00.000Z';
    const mathEntryId = publishedTimetableA.entries[0]._id!.toString();

    // Faculty A (Authorized) and Faculty B (Unauthorized) concurrently attempt to create/submit session
    const [resAuth, resUnauth] = await Promise.all([
      request(app)
        .post('/api/v1/attendance/sessions')
        .set(facultyAHeader)
        .send({
          timetableId: publishedTimetableA.id,
          timetableEntryId: mathEntryId,
          sectionId: sectionA.id,
          subjectId: subjectMath.id,
          date: mondayDate,
          timeSlot: '09:00 - 10:00',
          records: [{ studentId: studentProfile1.id, status: AttendanceStatus.PRESENT }],
        }),
      request(app)
        .post('/api/v1/attendance/sessions')
        .set(facultyBHeader)
        .send({
          timetableId: publishedTimetableA.id,
          timetableEntryId: mathEntryId,
          sectionId: sectionA.id,
          subjectId: subjectMath.id,
          date: mondayDate,
          timeSlot: '09:00 - 10:00',
          records: [{ studentId: studentProfile1.id, status: AttendanceStatus.ABSENT }],
        }),
    ]);

    // Authorized request succeeds
    expect(resAuth.status).toBe(201);
    // Unauthorized request strictly rejected
    expect(resUnauth.status).toBe(403);

    // Only 1 session in DB, owned by Faculty A
    const sessions = await AttendanceSession.find({});
    expect(sessions).toHaveLength(1);
    expect(sessions[0].facultyId.toString()).toBe(facultyProfileA.id);

    // Records reflect only Authorized Faculty A's submission
    const records = await AttendanceRecord.find({ sessionId: sessions[0]._id });
    expect(records).toHaveLength(1);
    expect(records[0].status).toBe(AttendanceStatus.PRESENT);
  });
});
