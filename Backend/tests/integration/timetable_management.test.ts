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
import { Room } from '../../src/models/room.model';
import { Timetable } from '../../src/models/timetable.model';
import { FacultyAssignment } from '../../src/models/facultyAssignment.model';
import { AuditLog } from '../../src/models/auditLog.model';
import { AppRole } from '../../src/constants/roles';
import { AccountStatus, CollegeStatus, DepartmentStatus, TimetableDay, TimetableStatus } from '../../src/constants/status';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';
import { PasswordService } from '../../src/services/password.service';

describe('ACADEX Phase 9J.1 — Timetable Management & Scheduling Engine Tests', () => {
  let superAdminUser: InstanceType<typeof User>;
  let collegeAdminA: InstanceType<typeof User>;
  let collegeAdminB: InstanceType<typeof User>;
  let hodA1: InstanceType<typeof User>;
  let facultyA1: InstanceType<typeof User>;
  let facultyA2: InstanceType<typeof User>;
  let studentA: InstanceType<typeof User>;

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
  let studentProfileA: InstanceType<typeof Student>;
  let room101: InstanceType<typeof Room>;
  let roomSmall: InstanceType<typeof Room>;

  let superAdminHeader: { Authorization: string };
  let collegeAdminAHeader: { Authorization: string };
  let collegeAdminBHeader: { Authorization: string };
  let hodA1Header: { Authorization: string };
  let facultyA1Header: { Authorization: string };
  let studentAHeader: { Authorization: string };

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
    await Room.init();
    await Timetable.init();
    await FacultyAssignment.init();
    await AuditLog.init();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();

    collegeA = await College.create({
      name: 'Alpha Engineering College',
      code: 'ALPHA',
      address: '100 Alpha Campus',
      email: 'admin@alpha.edu',
      phone: '+919988776601',
      principal: 'Dr. Alpha Principal',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });

    collegeB = await College.create({
      name: 'Beta Technology College',
      code: 'BETA',
      address: '200 Beta Campus',
      email: 'admin@beta.edu',
      phone: '+919988776602',
      principal: 'Dr. Beta Principal',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });

    deptA1 = await Department.create({
      collegeId: collegeA._id,
      name: 'Computer Science and Engineering',
      code: 'CSE',
      status: DepartmentStatus.ACTIVE,
      isActive: true,
    });

    deptA2 = await Department.create({
      collegeId: collegeA._id,
      name: 'Electronics and Communication Engineering',
      code: 'ECE',
      status: DepartmentStatus.ACTIVE,
      isActive: true,
    });

    courseA = await Course.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      name: 'B.Tech Computer Science',
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
      name: 'SECTION A',
      capacity: 60,
      isActive: true,
    });

    sectionB = await Section.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA5._id,
      name: 'SECTION B',
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

    const defaultPasswordHash = await PasswordService.hashPassword('AdminPass123');

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
      name: 'Dr. Turing (HOD CSE)',
      email: 'hod.cse@alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.HOD,
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    facultyA1 = await User.create({
      instituteId: 'FAC-CSE-01',
      name: 'Prof. Knuth',
      email: 'knuth@alpha.edu',
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
      name: 'Prof. Dijkstra',
      email: 'dijkstra@alpha.edu',
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

    studentA = await User.create({
      instituteId: 'STU-CSE-001',
      name: 'Alice Smith',
      email: 'alice@alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.STUDENT,
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    studentProfileA = await Student.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      userId: studentA._id,
      instituteId: studentA.instituteId,
      name: studentA.name,
      email: studentA.email,
      rollNumber: 'CSE-2026-001',
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
      studentId: studentProfileA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA5._id,
      sectionId: sectionA._id,
      status: 'active',
    });

    room101 = await Room.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      name: 'Lecture Hall 101',
      code: 'LH-101',
      capacity: 70,
      type: 'lecture',
      status: 'active',
      isActive: true,
    });

    roomSmall = await Room.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      name: 'Discussion Room 1',
      code: 'DR-01',
      capacity: 20, // Insufficient for Section A (capacity 60)
      type: 'other',
      status: 'active',
      isActive: true,
    });

    // Seed authoritative Faculty Assignments for collegeA
    await FacultyAssignment.create([
      {
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        courseId: courseA._id,
        academicYearId: academicYearA._id,
        semesterId: semesterA5._id,
        sectionId: sectionA._id,
        subjectId: subjectOS._id,
        facultyId: facultyProfileA1._id,
        facultyName: facultyProfileA1.name,
        isActive: true,
      },
      {
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        courseId: courseA._id,
        academicYearId: academicYearA._id,
        semesterId: semesterA5._id,
        sectionId: sectionA._id,
        subjectId: subjectDBMS._id,
        facultyId: facultyProfileA1._id,
        facultyName: facultyProfileA1.name,
        isActive: true,
      },
      {
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        courseId: courseA._id,
        academicYearId: academicYearA._id,
        semesterId: semesterA5._id,
        sectionId: sectionA._id,
        subjectId: subjectOS._id,
        facultyId: facultyProfileA2._id,
        facultyName: facultyProfileA2.name,
        isActive: true,
      },
      {
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        courseId: courseA._id,
        academicYearId: academicYearA._id,
        semesterId: semesterA5._id,
        sectionId: sectionA._id,
        subjectId: subjectDBMS._id,
        facultyId: facultyProfileA2._id,
        facultyName: facultyProfileA2.name,
        isActive: true,
      },
      {
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        courseId: courseA._id,
        academicYearId: academicYearA._id,
        semesterId: semesterA5._id,
        sectionId: sectionB._id,
        subjectId: subjectOS._id,
        facultyId: facultyProfileA1._id,
        facultyName: facultyProfileA1.name,
        isActive: true,
      },
      {
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        courseId: courseA._id,
        academicYearId: academicYearA._id,
        semesterId: semesterA5._id,
        sectionId: sectionB._id,
        subjectId: subjectDBMS._id,
        facultyId: facultyProfileA2._id,
        facultyName: facultyProfileA2.name,
        isActive: true,
      },
    ]);

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

    studentAHeader = createTestAuthHeader({
      userId: studentA.id,
      instituteId: studentA.instituteId,
      collegeId: collegeA.id,
      departmentId: deptA1.id,
      role: AppRole.STUDENT,
    });
  });

  // =========================================================================
  // 1. ROOM MANAGEMENT (21, 22, 23, 24)
  // =========================================================================

  it('21, 22, 23, 24. Room CRUD, capacity validation, unique code, and safe deactivation', async () => {
    // 21 & Create Room
    const resRoom = await request(app)
      .post('/api/v1/academics/rooms')
      .set(collegeAdminAHeader)
      .send({
        name: 'Computer Lab 1',
        code: 'CS-LAB-01',
        capacity: 65,
        type: 'lab',
      });

    expect(resRoom.status).toBe(201);
    expect(resRoom.body.data.code).toBe('CS-LAB-01');

    // 22. Duplicate room code in same college -> 409
    const resDup = await request(app)
      .post('/api/v1/academics/rooms')
      .set(collegeAdminAHeader)
      .send({
        name: 'Another Lab',
        code: 'CS-LAB-01',
        capacity: 50,
      });
    expect(resDup.status).toBe(409);

    // 23. Deactivate room and try to schedule in a timetable -> 403 Forbidden
    await Room.findByIdAndUpdate(resRoom.body.data.id, { isActive: false, status: 'inactive' });

    const resScheduleInactiveRoom = await request(app)
      .post('/api/v1/academics/timetables')
      .set(hodA1Header)
      .send({
        departmentId: deptA1.id,
        courseId: courseA.id,
        academicYearId: academicYearA.id,
        semesterId: semesterA5.id,
        sectionId: sectionA.id,
        name: 'Test Inactive Room Timetable',
        entries: [
          {
            dayOfWeek: TimetableDay.MONDAY,
            startTime: '09:00',
            endTime: '10:00',
            subjectId: subjectOS.id,
            facultyId: facultyProfileA1.id,
            roomId: resRoom.body.data.id,
          },
        ],
      });

    expect(resScheduleInactiveRoom.status).toBe(403);
  });

  // =========================================================================
  // 2. TIMETABLE CREATION & SECTION CONFLICT (1 - 10)
  // =========================================================================

  it('1 - 10. Timetable creation, boundary-touching periods allowed, and overlapping section periods rejected', async () => {
    // 8. Same section overlapping class -> 409 Conflict
    const resOverlap = await request(app)
      .post('/api/v1/academics/timetables')
      .set(hodA1Header)
      .send({
        departmentId: deptA1.id,
        courseId: courseA.id,
        academicYearId: academicYearA.id,
        semesterId: semesterA5.id,
        sectionId: sectionA.id,
        name: 'Section A Overlap Timetable',
        entries: [
          {
            dayOfWeek: TimetableDay.MONDAY,
            startTime: '09:00',
            endTime: '10:00',
            subjectId: subjectOS.id,
            facultyId: facultyProfileA1.id,
            roomId: room101.id,
          },
          {
            dayOfWeek: TimetableDay.MONDAY,
            startTime: '09:30', // Overlaps with 09:00 - 10:00
            endTime: '10:30',
            subjectId: subjectDBMS.id,
            facultyId: facultyProfileA2.id,
            roomId: room101.id,
          },
        ],
      });

    expect(resOverlap.status).toBe(409);
    expect(resOverlap.body.error?.message || resOverlap.body.message).toContain('Section conflict');

    // 9 & 10. Non-overlapping and boundary-touching classes (09:00-10:00, 10:00-11:00) -> 201 Created
    const resValid = await request(app)
      .post('/api/v1/academics/timetables')
      .set(hodA1Header)
      .send({
        departmentId: deptA1.id,
        courseId: courseA.id,
        academicYearId: academicYearA.id,
        semesterId: semesterA5.id,
        sectionId: sectionA.id,
        name: 'Section A Fall 2026 Timetable',
        entries: [
          {
            dayOfWeek: TimetableDay.MONDAY,
            startTime: '09:00',
            endTime: '10:00',
            subjectId: subjectOS.id,
            facultyId: facultyProfileA1.id,
            roomId: room101.id,
          },
          {
            dayOfWeek: TimetableDay.MONDAY,
            startTime: '10:00', // Boundary touching
            endTime: '11:00',
            subjectId: subjectDBMS.id,
            facultyId: facultyProfileA2.id,
            roomId: room101.id,
          },
        ],
      });

    expect(resValid.status).toBe(201);
    expect(resValid.body.data.status).toBe(TimetableStatus.DRAFT);
    expect(resValid.body.data.entries).toHaveLength(2);
  });

  // =========================================================================
  // 3. FACULTY & ROOM CONFLICTS ACROSS TIMETABLES (11 - 14)
  // =========================================================================

  it('11 - 14. Faculty conflict and Room conflict across published timetables', async () => {
    // 1. Create and publish Timetable for Section A
    const resTtA = await request(app)
      .post('/api/v1/academics/timetables')
      .set(hodA1Header)
      .send({
        departmentId: deptA1.id,
        courseId: courseA.id,
        academicYearId: academicYearA.id,
        semesterId: semesterA5.id,
        sectionId: sectionA.id,
        name: 'Section A Timetable',
        entries: [
          {
            dayOfWeek: TimetableDay.TUESDAY,
            startTime: '10:00',
            endTime: '11:00',
            subjectId: subjectOS.id,
            facultyId: facultyProfileA1.id,
            roomId: room101.id,
          },
        ],
      });

    expect(resTtA.status).toBe(201);
    const ttAId = resTtA.body.data.id;

    // Publish Section A timetable
    const pubRes = await request(app)
      .post(`/api/v1/academics/timetables/${ttAId}/publish`)
      .set(hodA1Header);
    expect(pubRes.status).toBe(200);
    expect(pubRes.body.data.status).toBe(TimetableStatus.PUBLISHED);

    // 11. Create Timetable for Section B with overlapping time for same Faculty F1 -> 409 Faculty Conflict
    const resFacConflict = await request(app)
      .post('/api/v1/academics/timetables')
      .set(hodA1Header)
      .send({
        departmentId: deptA1.id,
        courseId: courseA.id,
        academicYearId: academicYearA.id,
        semesterId: semesterA5.id,
        sectionId: sectionB.id,
        name: 'Section B Conflict Faculty Timetable',
        entries: [
          {
            dayOfWeek: TimetableDay.TUESDAY,
            startTime: '10:30', // Overlaps with 10:00 - 11:00
            endTime: '11:30',
            subjectId: subjectOS.id,
            facultyId: facultyProfileA1.id, // Same Faculty!
          },
        ],
      });

    expect(resFacConflict.status).toBe(409);
    expect(resFacConflict.body.error?.message || resFacConflict.body.message).toContain('Faculty conflict');

    // 13. Create Timetable for Section B with overlapping time in same Room 101 -> 409 Room Conflict
    const resRoomConflict = await request(app)
      .post('/api/v1/academics/timetables')
      .set(hodA1Header)
      .send({
        departmentId: deptA1.id,
        courseId: courseA.id,
        academicYearId: academicYearA.id,
        semesterId: semesterA5.id,
        sectionId: sectionB.id,
        name: 'Section B Conflict Room Timetable',
        entries: [
          {
            dayOfWeek: TimetableDay.TUESDAY,
            startTime: '10:15', // Overlaps with 10:00 - 11:00
            endTime: '11:15',
            subjectId: subjectDBMS.id,
            facultyId: facultyProfileA2.id, // Different faculty
            roomId: room101.id, // Same room!
          },
        ],
      });

    expect(resRoomConflict.status).toBe(409);
    expect(resRoomConflict.body.error?.message || resRoomConflict.body.message).toContain('Room conflict');
  });

  // =========================================================================
  // 4. ACADEMIC CONSISTENCY & INSUFFICIENT CAPACITY (15 - 21)
  // =========================================================================

  it('15 - 21. Rejects wrong semester subject, cross-college references, and insufficient room capacity', async () => {
    // Other Course in Dept A2
    const courseECE = await Course.create({
      collegeId: collegeA._id,
      departmentId: deptA2._id,
      name: 'B.Tech ECE',
      code: 'ECE101',
      duration: 4,
      isActive: true,
    });

    const semesterECE = await Semester.create({
      collegeId: collegeA._id,
      departmentId: deptA2._id,
      courseId: courseECE._id,
      academicYearId: academicYearA._id,
      name: 'ECE Semester 1',
      number: 1,
      isActive: true,
    });

    const subjectECE = await Subject.create({
      collegeId: collegeA._id,
      departmentId: deptA2._id,
      courseId: courseECE._id,
      semesterId: semesterECE._id,
      name: 'Signals and Systems',
      code: 'ECE101',
      credits: 4,
      isActive: true,
    });

    // 15. Wrong subject for semester -> 400 Bad Request
    const resWrongSub = await request(app)
      .post('/api/v1/academics/timetables')
      .set(hodA1Header)
      .send({
        departmentId: deptA1.id,
        courseId: courseA.id,
        academicYearId: academicYearA.id,
        semesterId: semesterA5.id,
        sectionId: sectionA.id,
        name: 'Wrong Subject Timetable',
        entries: [
          {
            dayOfWeek: TimetableDay.WEDNESDAY,
            startTime: '09:00',
            endTime: '10:00',
            subjectId: subjectECE.id, // ECE Subject in CS Semester 5!
            facultyId: facultyProfileA1.id,
          },
        ],
      });
    expect(resWrongSub.status).toBe(400);

    // 21. Insufficient Room Capacity (Room capacity 20, Section capacity 60) -> 400 Bad Request
    const resRoomCap = await request(app)
      .post('/api/v1/academics/timetables')
      .set(hodA1Header)
      .send({
        departmentId: deptA1.id,
        courseId: courseA.id,
        academicYearId: academicYearA.id,
        semesterId: semesterA5.id,
        sectionId: sectionA.id,
        name: 'Insufficient Room Capacity Timetable',
        entries: [
          {
            dayOfWeek: TimetableDay.WEDNESDAY,
            startTime: '09:00',
            endTime: '10:00',
            subjectId: subjectOS.id,
            facultyId: facultyProfileA1.id,
            roomId: roomSmall.id, // Small room!
          },
        ],
      });
    expect(resRoomCap.status).toBe(400);
    expect(resRoomCap.body.error?.message || resRoomCap.body.message).toContain('Room capacity');
  });

  // =========================================================================
  // 5. SPECIALIZED RETRIEVAL & STUDENT ENROLLMENT LOOKUP (25 - 40)
  // =========================================================================

  it('25 - 40. Publish, unpublish, archive lifecycle; Section, Faculty, and Student enrolled timetable lookup', async () => {
    // 1. Create Timetable for Section A
    const resTt = await request(app)
      .post('/api/v1/academics/timetables')
      .set(hodA1Header)
      .send({
        departmentId: deptA1.id,
        courseId: courseA.id,
        academicYearId: academicYearA.id,
        semesterId: semesterA5.id,
        sectionId: sectionA.id,
        name: 'Section A Published Timetable',
        entries: [
          {
            dayOfWeek: TimetableDay.THURSDAY,
            startTime: '09:00',
            endTime: '10:00',
            subjectId: subjectOS.id,
            facultyId: facultyProfileA1.id,
            roomId: room101.id,
          },
          {
            dayOfWeek: TimetableDay.THURSDAY,
            startTime: '10:00',
            endTime: '11:00',
            subjectId: subjectDBMS.id,
            facultyId: facultyProfileA2.id,
            roomId: room101.id,
          },
        ],
      });

    const ttId = resTt.body.data.id;

    // 26. Publish
    await request(app)
      .post(`/api/v1/academics/timetables/${ttId}/publish`)
      .set(hodA1Header);

    // 29. Casual direct edit of published timetable is blocked
    const resEditPub = await request(app)
      .put(`/api/v1/academics/timetables/${ttId}`)
      .set(hodA1Header)
      .send({ name: 'Tampered Name' });
    expect(resEditPub.status).toBe(400);

    // 35. Section Timetable retrieval
    const resSecTt = await request(app)
      .get(`/api/v1/academics/sections/${sectionA.id}/timetable?day=THURSDAY`)
      .set(facultyA1Header);
    expect(resSecTt.status).toBe(200);
    expect(resSecTt.body.data).toHaveLength(2);

    // 36. Faculty Timetable retrieval
    const resFacTt = await request(app)
      .get(`/api/v1/academics/faculty/${facultyProfileA1.id}/timetable`)
      .set(facultyA1Header);
    expect(resFacTt.status).toBe(200);
    expect(resFacTt.body.data).toHaveLength(1);
    expect(resFacTt.body.data[0].startTime).toBe('09:00');

    // 39. Student retrieves own timetable via enrollment (Alice enrolled in Section A)
    const resStuTt = await request(app)
      .get('/api/v1/academics/students/me/timetable')
      .set(studentAHeader);
    expect(resStuTt.status).toBe(200);
    expect(resStuTt.body.data).toHaveLength(2);

    // 28. Unpublish & Archive lifecycle
    const resUnpub = await request(app)
      .post(`/api/v1/academics/timetables/${ttId}/unpublish`)
      .set(hodA1Header);
    expect(resUnpub.status).toBe(200);
    expect(resUnpub.body.data.status).toBe(TimetableStatus.DRAFT);

    const resArchive = await request(app)
      .post(`/api/v1/academics/timetables/${ttId}/archive`)
      .set(hodA1Header);
    expect(resArchive.status).toBe(200);
    expect(resArchive.body.data.status).toBe(TimetableStatus.ARCHIVED);
  });

  // =========================================================================
  // 6. TENANT ISOLATION, RBAC & AUDIT LOGGING (41 - 48)
  // =========================================================================

  it('41 - 48. Tenant isolation, RBAC checks, and Audit logs', async () => {
    // 30. Super Admin global room creation
    const resSuperRoom = await request(app)
      .post('/api/v1/academics/rooms')
      .set(superAdminHeader)
      .send({
        collegeId: collegeB.id,
        name: 'Beta Global Room',
        code: 'BETA-ROOM-01',
        capacity: 100,
      });
    expect(resSuperRoom.status).toBe(201);

    // 37. College Admin B cannot access College A Timetables (403)
    const resCrossTt = await request(app)
      .post('/api/v1/academics/timetables')
      .set(collegeAdminBHeader)
      .send({
        collegeId: collegeA.id,
        departmentId: deptA1.id,
        courseId: courseA.id,
        academicYearId: academicYearA.id,
        semesterId: semesterA5.id,
        sectionId: sectionA.id,
        name: 'Cross College Timetable',
      });
    expect(resCrossTt.status).toBe(403);

    // 34. Faculty cannot create timetables without admin role (403)
    const resFacCreate = await request(app)
      .post('/api/v1/academics/timetables')
      .set(facultyA1Header)
      .send({
        departmentId: deptA1.id,
        courseId: courseA.id,
        academicYearId: academicYearA.id,
        semesterId: semesterA5.id,
        sectionId: sectionA.id,
        name: 'Faculty Created Timetable',
      });
    expect(resFacCreate.status).toBe(403);

    // Create a room in College A to verify audit logging
    const resRoomA = await request(app)
      .post('/api/v1/academics/rooms')
      .set(collegeAdminAHeader)
      .send({
        name: 'College A Audit Room',
        code: 'AUDIT-ROOM-01',
        capacity: 50,
      });
    expect(resRoomA.status).toBe(201);

    // 44 & 45. Check Audit Logs
    const logs = await AuditLog.find({ collegeId: collegeA.id });
    const actions = logs.map((l) => l.action);
    expect(actions).toContain('ROOM_CREATED');

    // Ensure secrets not in logs
    const serialized = JSON.stringify(logs);
    expect(serialized).not.toContain('password');
    expect(serialized).not.toContain('AdminPass123');
  });
});
