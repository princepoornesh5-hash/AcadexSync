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
import { FacultyAssignment } from '../../src/models/facultyAssignment.model';
import { Room } from '../../src/models/room.model';
import { Timetable } from '../../src/models/timetable.model';
import { AttendanceSession } from '../../src/models/attendanceSession.model';
import { InstitutionConfiguration } from '../../src/models/institutionConfiguration.model';
import { AppRole } from '../../src/constants/roles';
import { AccountStatus, CollegeStatus, DepartmentStatus, AttendanceSessionStatus, TimetableStatus } from '../../src/constants/status';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';
import { PasswordService } from '../../src/services/password.service';

describe('PROMPT 37 — Rooms, Timetable & Attendance Core Operational Hardening', () => {
  let collegeA: any;
  let collegeB: any;

  let deptA: any;
  let deptB: any;

  let courseA: any;
  let ayA: any;
  let semA: any;
  let secA: any;

  let subjectA1: any;
  let subjectA2: any;

  let adminUserA: any;
  let adminHeaderA: { Authorization: string };

  let hodUserA: any;
  let hodHeaderA: { Authorization: string };

  let facultyUserA1: any;
  let facultyDocA1: any;
  let facultyHeaderA1: { Authorization: string };

  let facultyUserA2: any;
  let facultyDocA2: any;
  let facultyHeaderA2: { Authorization: string };

  let studentUserA1: any;
  let studentDocA1: any;
  let studentHeaderA1: { Authorization: string };

  let studentDocA2: any; // unenrolled student

  let assignmentA1: any;
  let assignmentA2: any;

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
    await FacultyAssignment.init();
    await Room.init();
    await Timetable.init();
    await AttendanceSession.init();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();

    collegeA = await College.create({
      name: 'Engineering Tech College',
      code: 'ETC',
      address: '100 Tech Way',
      email: 'info@etc.edu',
      phone: '+919876543210',
      principal: 'Dr. Principal',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });

    collegeB = await College.create({
      name: 'Arts College',
      code: 'ART',
      address: '200 Arts Blvd',
      email: 'info@art.edu',
      phone: '+919876543211',
      principal: 'Dr. Arts Principal',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });

    // Default InstitutionConfiguration for College A with sections enabled
    await InstitutionConfiguration.create({
      collegeId: collegeA._id,
      academicStructure: {
        academicYear: true,
        department: true,
        program: true,
        semester: true,
        section: true,
        attendanceUnits: 'hours',
      },
      timetableModel: 'standard',
    });

    deptA = await Department.create({
      name: 'Computer Science',
      code: 'CSE',
      collegeId: collegeA._id,
      status: DepartmentStatus.ACTIVE,
    });

    deptB = await Department.create({
      name: 'History',
      code: 'HIST',
      collegeId: collegeB._id,
      status: DepartmentStatus.ACTIVE,
    });

    courseA = await Course.create({
      name: 'B.Tech CSE',
      code: 'BCSE',
      departmentId: deptA._id,
      collegeId: collegeA._id,
      durationYears: 4,
      totalSemesters: 8,
    });

    ayA = await AcademicYear.create({
      name: '2026-2027',
      year: '2026-2027',
      startDate: new Date('2026-08-01'),
      endDate: new Date('2027-05-31'),
      collegeId: collegeA._id,
      isCurrent: true,
    });

    semA = await Semester.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: ayA._id,
      name: 'Semester 1',
      number: 1,
      startDate: new Date('2026-08-01'),
      endDate: new Date('2026-12-31'),
      status: 'active',
      isActive: true,
    });

    secA = await Section.create({
      name: 'A',
      semesterId: semA._id,
      courseId: courseA._id,
      departmentId: deptA._id,
      academicYearId: ayA._id,
      collegeId: collegeA._id,
      capacity: 60,
      status: 'active',
      isActive: true,
    });

    subjectA1 = await Subject.create({
      name: 'Data Structures',
      code: 'CS101',
      departmentId: deptA._id,
      courseId: courseA._id,
      semesterId: semA._id,
      academicYearId: ayA._id,
      collegeId: collegeA._id,
      credits: 4,
      status: 'active',
      isActive: true,
    });

    subjectA2 = await Subject.create({
      name: 'Algorithms',
      code: 'CS102',
      departmentId: deptA._id,
      courseId: courseA._id,
      semesterId: semA._id,
      academicYearId: ayA._id,
      collegeId: collegeA._id,
      credits: 4,
      status: 'active',
      isActive: true,
    });

    const hashedPassword = await PasswordService.hashPassword('Password@123');

    // Admin
    adminUserA = await User.create({
      instituteId: 'ADMIN-A-01',
      email: 'admin.a@etc.edu',
      password: hashedPassword,
      name: 'Admin A',
      role: AppRole.COLLEGE_ADMIN,
      collegeId: collegeA._id,
      accountStatus: AccountStatus.ACTIVE,
      isActive: true,
    });
    adminHeaderA = createTestAuthHeader({
      userId: adminUserA._id.toString(),
      role: AppRole.COLLEGE_ADMIN,
      collegeId: collegeA._id.toString(),
    });

    // HOD
    hodUserA = await User.create({
      instituteId: 'HOD-A-01',
      email: 'hod.cse@etc.edu',
      password: hashedPassword,
      name: 'HOD CSE',
      role: AppRole.HOD,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      accountStatus: AccountStatus.ACTIVE,
      isActive: true,
    });
    hodHeaderA = createTestAuthHeader({
      userId: hodUserA._id.toString(),
      role: AppRole.HOD,
      collegeId: collegeA._id.toString(),
      departmentId: deptA._id.toString(),
    });

    // Faculty 1
    facultyUserA1 = await User.create({
      instituteId: 'FAC-A-01',
      email: 'faculty1@etc.edu',
      password: hashedPassword,
      name: 'Dr. Faculty One',
      role: AppRole.FACULTY,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      accountStatus: AccountStatus.ACTIVE,
      isActive: true,
    });
    facultyDocA1 = await Faculty.create({
      userId: facultyUserA1._id,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      facultyId: 'FAC001',
      name: 'Dr. Faculty One',
      email: 'faculty1@etc.edu',
      designation: 'Associate Professor',
      status: 'active',
      isActive: true,
    });
    facultyHeaderA1 = createTestAuthHeader({
      userId: facultyUserA1._id.toString(),
      role: AppRole.FACULTY,
      collegeId: collegeA._id.toString(),
      departmentId: deptA._id.toString(),
    });

    // Faculty 2
    facultyUserA2 = await User.create({
      instituteId: 'FAC-A-02',
      email: 'faculty2@etc.edu',
      password: hashedPassword,
      name: 'Dr. Faculty Two',
      role: AppRole.FACULTY,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      accountStatus: AccountStatus.ACTIVE,
      isActive: true,
    });
    facultyDocA2 = await Faculty.create({
      userId: facultyUserA2._id,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      facultyId: 'FAC002',
      name: 'Dr. Faculty Two',
      email: 'faculty2@etc.edu',
      designation: 'Assistant Professor',
      status: 'active',
      isActive: true,
    });
    facultyHeaderA2 = createTestAuthHeader({
      userId: facultyUserA2._id.toString(),
      role: AppRole.FACULTY,
      collegeId: collegeA._id.toString(),
      departmentId: deptA._id.toString(),
    });

    // Student 1 (Enrolled)
    studentUserA1 = await User.create({
      instituteId: 'STU-A-01',
      email: 'student1@etc.edu',
      password: hashedPassword,
      name: 'Alice Student',
      role: AppRole.STUDENT,
      collegeId: collegeA._id,
      accountStatus: AccountStatus.ACTIVE,
      isActive: true,
    });
    studentDocA1 = await Student.create({
      userId: studentUserA1._id,
      collegeId: collegeA._id,
      name: 'Alice Student',
      email: 'student1@etc.edu',
      rollNumber: 'ETC001',
      sectionId: secA._id,
      courseId: courseA._id,
      departmentId: deptA._id,
      academicYearId: ayA._id,
      semesterId: semA._id,
      status: 'active',
    });
    await StudentEnrollment.create({
      studentId: studentDocA1._id,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: ayA._id,
      semesterId: semA._id,
      sectionId: secA._id,
      status: 'active',
    });
    studentHeaderA1 = createTestAuthHeader({
      userId: studentUserA1._id.toString(),
      role: AppRole.STUDENT,
      collegeId: collegeA._id.toString(),
    });

    // Student 2 (Unenrolled)
    studentDocA2 = await Student.create({
      collegeId: collegeA._id,
      name: 'Bob Unenrolled',
      email: 'bob@etc.edu',
      rollNumber: 'ETC002',
      sectionId: new mongoose.Types.ObjectId(), // stale section
      courseId: courseA._id,
      departmentId: deptA._id,
      academicYearId: ayA._id,
      semesterId: semA._id,
      status: 'active',
    });

    // Authoritative Faculty Assignments
    assignmentA1 = await FacultyAssignment.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      facultyId: facultyDocA1._id,
      facultyName: facultyDocA1.name,
      courseId: courseA._id,
      academicYearId: ayA._id,
      semesterId: semA._id,
      sectionId: secA._id,
      subjectId: subjectA1._id,
      hoursPerWeek: 4,
      isActive: true,
      status: 'active',
    });

    assignmentA2 = await FacultyAssignment.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      facultyId: facultyDocA2._id,
      facultyName: facultyDocA2.name,
      courseId: courseA._id,
      academicYearId: ayA._id,
      semesterId: semA._id,
      sectionId: secA._id,
      subjectId: subjectA2._id,
      hoursPerWeek: 3,
      isActive: true,
      status: 'active',
    });
  });

  // =========================================================================
  // 1. ROOM MANAGEMENT & RETIREMENT SAFETY MATRIX
  // =========================================================================
  describe('Room Management Matrix (R1 to R6)', () => {
    it('R1: creates a standalone room independently without timetable or faculty', async () => {
      const res = await request(app)
        .post('/api/v1/academics/rooms')
        .set(adminHeaderA)
        .send({
          name: 'Hall 101',
          code: 'H101',
          capacity: 80,
          type: 'lecture',
          building: 'Science Block',
          departmentId: deptA._id.toString(),
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.name).toBe('Hall 101');
      expect(res.body.data.code).toBe('H101');
      expect(res.body.data.status).toBe('active');
      expect(res.body.data.isActive).toBe(true);
      expect(res.body.data.building).toBe('Science Block');
    });

    it('R2: enforces cross-college isolation on room management', async () => {
      const roomB = await Room.create({
        collegeId: collegeB._id,
        name: 'Room B1',
        code: 'RB1',
        capacity: 40,
        type: 'lecture',
        status: 'active',
        isActive: true,
      });

      const res = await request(app)
        .get(`/api/v1/academics/rooms/${roomB._id}`)
        .set(adminHeaderA);

      expect(res.status).toBe(403);
    });

    it('R3: allows HOD to create room for their department, but prohibits Faculty and Students', async () => {
      const hodRes = await request(app)
        .post('/api/v1/academics/rooms')
        .set(hodHeaderA)
        .send({
          name: 'HOD Lab',
          code: 'HODLAB',
          capacity: 45,
          type: 'lab',
          departmentId: deptA._id.toString(),
        });
      expect(hodRes.status).toBe(201);

      const crossDeptRes = await request(app)
        .post('/api/v1/academics/rooms')
        .set(hodHeaderA)
        .send({
          name: 'History Room',
          code: 'HIST_RM',
          capacity: 30,
          departmentId: deptB._id.toString(),
        });
      expect(crossDeptRes.status).toBe(403);

      const facultyRes = await request(app)
        .post('/api/v1/academics/rooms')
        .set(facultyHeaderA1)
        .send({
          name: 'Unauthorized Room',
          code: 'UNAUTH',
          capacity: 50,
          type: 'lecture',
        });
      expect(facultyRes.status).toBe(403);

      const studentRes = await request(app)
        .post('/api/v1/academics/rooms')
        .set(studentHeaderA1)
        .send({
          name: 'Unauthorized Student Room',
          code: 'STU_ROOM',
          capacity: 50,
          type: 'lecture',
        });
      expect(studentRes.status).toBe(403);
    });

    it('R4: safely retires (does not delete) a room referenced by a timetable', async () => {
      const room = await Room.create({
        collegeId: collegeA._id,
        departmentId: deptA._id,
        name: 'Lab 201',
        code: 'L201',
        capacity: 60,
        type: 'lab',
        status: 'active',
        isActive: true,
      });

      // Create timetable referencing room
      await Timetable.create({
        collegeId: collegeA._id,
        departmentId: deptA._id,
        courseId: courseA._id,
        academicYearId: ayA._id,
        semesterId: semA._id,
        sectionId: secA._id,
        name: 'Lab Timetable',
        status: TimetableStatus.DRAFT,
        academicYear: '2026-2027',
        semester: 1,
        entries: [
          {
            dayOfWeek: 'monday',
            startTime: '09:00',
            endTime: '10:00',
            subjectId: subjectA1._id,
            facultyId: facultyDocA1._id,
            facultyAssignmentId: assignmentA1._id,
            roomId: room._id,
            roomNumber: room.code,
            isBreak: false,
          },
        ],
      });

      // Delete room request
      const delRes = await request(app)
        .delete(`/api/v1/academics/rooms/${room._id}`)
        .set(adminHeaderA);

      expect(delRes.status).toBe(200);
      expect(delRes.body.success).toBe(true);
      expect(delRes.body.message).toContain('retired');

      // Verify room was retired and preserved
      const retiredRoom = await Room.findById(room._id);
      expect(retiredRoom).not.toBeNull();
      expect(retiredRoom?.isActive).toBe(false);
      expect(retiredRoom?.status).toBe('retired');
    });

    it('R5: safely retires a room referenced by an attendance session', async () => {
      const room = await Room.create({
        collegeId: collegeA._id,
        departmentId: deptA._id,
        name: 'Seminar Hall',
        code: 'SEM01',
        capacity: 100,
        type: 'seminar',
        status: 'active',
        isActive: true,
      });

      await AttendanceSession.create({
        collegeId: collegeA._id,
        departmentId: deptA._id,
        courseId: courseA._id,
        academicYearId: ayA._id,
        semesterId: semA._id,
        sectionId: secA._id,
        subjectId: subjectA1._id,
        subjectName: subjectA1.name,
        facultyId: facultyDocA1._id,
        facultyAssignmentId: assignmentA1._id,
        date: new Date('2026-09-01'),
        timeSlot: '09:00 - 10:00',
        roomNumber: 'SEM01',
        records: [],
        status: AttendanceSessionStatus.OPEN,
      });

      const delRes = await request(app)
        .delete(`/api/v1/academics/rooms/${room._id}`)
        .set(adminHeaderA);

      expect(delRes.status).toBe(200);
      expect(delRes.body.message).toContain('retired');

      const retired = await Room.findById(room._id);
      expect(retired?.isActive).toBe(false);
      expect(retired?.status).toBe('retired');
    });

    it('R6: hard-deletes an unreferenced room cleanly', async () => {
      const room = await Room.create({
        collegeId: collegeA._id,
        departmentId: deptA._id,
        name: 'Temp Room',
        code: 'TEMP99',
        capacity: 30,
        type: 'lecture',
        status: 'active',
        isActive: true,
      });

      const delRes = await request(app)
        .delete(`/api/v1/academics/rooms/${room._id}`)
        .set(adminHeaderA);

      expect(delRes.status).toBe(200);
      expect(delRes.body.message).toContain('deleted');

      const deleted = await Room.findById(room._id);
      expect(deleted).toBeNull();
    });
  });

  // =========================================================================
  // 2. TIMETABLE CANONICAL BINDING & CONFLICT ENGINE MATRIX
  // =========================================================================
  describe('Timetable Canonical Binding & Conflict Matrix (T1 to T6)', () => {
    let activeRoom: any;

    beforeEach(async () => {
      activeRoom = await Room.create({
        collegeId: collegeA._id,
        departmentId: deptA._id,
        name: 'Lecture Hall 1',
        code: 'LH1',
        capacity: 70,
        type: 'lecture',
        status: 'active',
        isActive: true,
      });
    });

    it('T1: creates timetable bound to canonical FacultyAssignment successfully', async () => {
      const res = await request(app)
        .post('/api/v1/timetables')
        .set(adminHeaderA)
        .send({
          name: 'CSE Sem 1 Sec A Timetable',
          departmentId: deptA._id.toString(),
          courseId: courseA._id.toString(),
          academicYearId: ayA._id.toString(),
          semesterId: semA._id.toString(),
          sectionId: secA._id.toString(),
          academicYear: '2026-2027',
          semester: 1,
          entries: [
            {
              dayOfWeek: 'monday',
              startTime: '09:00',
              endTime: '10:00',
              facultyAssignmentId: assignmentA1._id.toString(),
              roomId: activeRoom._id.toString(),
              isBreak: false,
            },
          ],
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.entries[0].subjectId.toString()).toBe(subjectA1._id.toString());
      expect(res.body.data.entries[0].facultyId.toString()).toBe(facultyDocA1._id.toString());
      expect(res.body.data.entries[0].facultyAssignmentId.toString()).toBe(assignmentA1._id.toString());
      expect(res.body.data.entries[0].roomNumber).toBe('LH1');
    });

    it('T2: rejects timetable entry referencing retired or inactive room', async () => {
      const retiredRoom = await Room.create({
        collegeId: collegeA._id,
        name: 'Old Shed',
        code: 'SHED',
        capacity: 30,
        type: 'lecture',
        status: 'retired',
        isActive: false,
      });

      const res = await request(app)
        .post('/api/v1/timetables')
        .set(adminHeaderA)
        .send({
          name: 'CSE Sem 1 Sec A Timetable',
          departmentId: deptA._id.toString(),
          courseId: courseA._id.toString(),
          academicYearId: ayA._id.toString(),
          semesterId: semA._id.toString(),
          sectionId: secA._id.toString(),
          academicYear: '2026-2027',
          semester: 1,
          entries: [
            {
              dayOfWeek: 'monday',
              startTime: '09:00',
              endTime: '10:00',
              facultyAssignmentId: assignmentA1._id.toString(),
              roomId: retiredRoom._id.toString(),
              isBreak: false,
            },
          ],
        });

      expect(res.status).toBe(403);
      expect(res.body.error?.message || res.body.message).toContain('retired');
    });

    it('T3: rejects timetable entry referencing suspended or inactive faculty', async () => {
      const inactiveFacultyDoc = await Faculty.create({
        userId: new mongoose.Types.ObjectId(),
        collegeId: collegeA._id,
        departmentId: deptA._id,
        facultyId: 'FAC_INACTIVE',
        name: 'Inactive Prof',
        email: 'inactive@etc.edu',
        designation: 'Professor',
        status: 'inactive',
        isActive: false,
      });

      const invalidAssignment = await FacultyAssignment.create({
        collegeId: collegeA._id,
        departmentId: deptA._id,
        facultyId: inactiveFacultyDoc._id,
        facultyName: inactiveFacultyDoc.name,
        courseId: courseA._id,
        academicYearId: ayA._id,
        semesterId: semA._id,
        sectionId: secA._id,
        subjectId: subjectA1._id,
        hoursPerWeek: 3,
        isActive: true,
        status: 'active',
      });

      const res = await request(app)
        .post('/api/v1/timetables')
        .set(adminHeaderA)
        .send({
          name: 'CSE Sem 1 Sec A Timetable',
          departmentId: deptA._id.toString(),
          courseId: courseA._id.toString(),
          academicYearId: ayA._id.toString(),
          semesterId: semA._id.toString(),
          sectionId: secA._id.toString(),
          academicYear: '2026-2027',
          semester: 1,
          entries: [
            {
              dayOfWeek: 'monday',
              startTime: '09:00',
              endTime: '10:00',
              facultyAssignmentId: invalidAssignment._id.toString(),
              roomId: activeRoom._id.toString(),
              isBreak: false,
            },
          ],
        });

      expect(res.status).toBe(403);
      expect(res.body.error?.message || res.body.message).toContain('inactive/suspended');
    });

    it('T4: rejects cross-academic mismatch between container and assignment', async () => {
      // Assignment for another section
      const secA2 = await Section.create({
        name: 'B',
        semesterId: semA._id,
        courseId: courseA._id,
        departmentId: deptA._id,
        academicYearId: ayA._id,
        collegeId: collegeA._id,
        capacity: 60,
        status: 'active',
        isActive: true,
      });

      const mismatchAssignment = await FacultyAssignment.create({
        collegeId: collegeA._id,
        departmentId: deptA._id,
        facultyId: facultyDocA1._id,
        facultyName: facultyDocA1.name,
        courseId: courseA._id,
        academicYearId: ayA._id,
        semesterId: semA._id,
        sectionId: secA2._id, // Section B
        subjectId: subjectA1._id,
        hoursPerWeek: 4,
        isActive: true,
        status: 'active',
      });

      // Attempting to use Section B assignment in Section A timetable
      const res = await request(app)
        .post('/api/v1/timetables')
        .set(adminHeaderA)
        .send({
          name: 'CSE Sem 1 Sec A Timetable',
          departmentId: deptA._id.toString(),
          courseId: courseA._id.toString(),
          academicYearId: ayA._id.toString(),
          semesterId: semA._id.toString(),
          sectionId: secA._id.toString(), // Section A
          academicYear: '2026-2027',
          semester: 1,
          entries: [
            {
              dayOfWeek: 'monday',
              startTime: '09:00',
              endTime: '10:00',
              facultyAssignmentId: mismatchAssignment._id.toString(),
              roomId: activeRoom._id.toString(),
              isBreak: false,
            },
          ],
        });

      expect(res.status).toBe(400);
      expect(res.body.error?.message || res.body.message).toContain('does not match this section');
    });

    it('T5: detects internal schedule conflicts (same room or same section overlap)', async () => {
      const res = await request(app)
        .post('/api/v1/timetables')
        .set(adminHeaderA)
        .send({
          name: 'CSE Sem 1 Sec A Timetable',
          departmentId: deptA._id.toString(),
          courseId: courseA._id.toString(),
          academicYearId: ayA._id.toString(),
          semesterId: semA._id.toString(),
          sectionId: secA._id.toString(),
          academicYear: '2026-2027',
          semester: 1,
          entries: [
            {
              dayOfWeek: 'tuesday',
              startTime: '09:00',
              endTime: '10:00',
              facultyAssignmentId: assignmentA1._id.toString(),
              roomId: activeRoom._id.toString(),
              isBreak: false,
            },
            {
              dayOfWeek: 'tuesday',
              startTime: '09:30', // Overlaps 09:00-10:00!
              endTime: '10:30',
              facultyAssignmentId: assignmentA2._id.toString(),
              roomId: activeRoom._id.toString(),
              isBreak: false,
            },
          ],
        });

      expect(res.status).toBe(409);
      expect((res.body.error?.message || res.body.message).toLowerCase()).toContain('conflict');
    });

    it('T6: handles Section Optionality when Section is disabled in InstitutionConfiguration', async () => {
      // Disable sections for college A
      await InstitutionConfiguration.findOneAndUpdate(
        { collegeId: collegeA._id },
        { 'academicStructure.section': false }
      );

      // Assignment without section
      const noSecAssignment = await FacultyAssignment.create({
        collegeId: collegeA._id,
        departmentId: deptA._id,
        facultyId: facultyDocA1._id,
        facultyName: facultyDocA1.name,
        courseId: courseA._id,
        academicYearId: ayA._id,
        semesterId: semA._id,
        sectionId: null,
        subjectId: subjectA1._id,
        hoursPerWeek: 4,
        isActive: true,
        status: 'active',
      });

      const res = await request(app)
        .post('/api/v1/timetables')
        .set(adminHeaderA)
        .send({
          name: 'CSE Sem 1 Timetable (No Sec)',
          departmentId: deptA._id.toString(),
          courseId: courseA._id.toString(),
          academicYearId: ayA._id.toString(),
          semesterId: semA._id.toString(),
          academicYear: '2026-2027',
          semester: 1,
          entries: [
            {
              dayOfWeek: 'wednesday',
              startTime: '10:00',
              endTime: '11:00',
              facultyAssignmentId: noSecAssignment._id.toString(),
              roomId: activeRoom._id.toString(),
              isBreak: false,
            },
          ],
        });

      expect(res.status).toBe(201);
      expect(res.body.data.sectionId == null).toBe(true);

      // Publish the section-disabled timetable
      const pubRes = await request(app)
        .post(`/api/v1/timetables/${res.body.data._id}/publish`)
        .set(adminHeaderA);

      expect(pubRes.status).toBe(200);
      expect(pubRes.body.data.status).toBe('published');
    });
  });

  // =========================================================================
  // 3. ATTENDANCE OPERATIONAL CHAIN & STUDENT ENROLLMENT ROSTER MATRIX
  // =========================================================================
  describe('Attendance Operational Chain Matrix (A1 to A6)', () => {
    it('A1: allows authorized faculty to create attendance session referencing FacultyAssignment', async () => {
      const res = await request(app)
        .post('/api/v1/attendance/sessions')
        .set(facultyHeaderA1)
        .send({
          subjectId: subjectA1._id.toString(),
          subjectName: subjectA1.name,
          sectionId: secA._id.toString(),
          sectionName: 'A',
          facultyAssignmentId: assignmentA1._id.toString(),
          timeSlot: '09:00 - 10:00',
          date: '2026-09-02',
          records: [
            {
              studentId: studentDocA1._id.toString(),
              status: 'present',
            },
          ],
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.facultyId.toString()).toBe(facultyDocA1._id.toString());
      expect(res.body.data.facultyAssignmentId.toString()).toBe(assignmentA1._id.toString());
      expect(res.body.data.records.length).toBe(1);
    });

    it('A2: rejects teacher class spoofing (faculty cannot mark attendance for another faculty assignment)', async () => {
      // Faculty 2 tries to mark attendance for Faculty 1's assignment
      const res = await request(app)
        .post('/api/v1/attendance/sessions')
        .set(facultyHeaderA2)
        .send({
          subjectId: subjectA1._id.toString(),
          subjectName: subjectA1.name,
          sectionId: secA._id.toString(),
          facultyAssignmentId: assignmentA1._id.toString(), // belongs to Faculty 1
          timeSlot: '09:00 - 10:00',
          date: '2026-09-03',
          records: [
            {
              studentId: studentDocA1._id.toString(),
              status: 'present',
            },
          ],
        });

      expect(res.status).toBe(403);
      expect(res.body.error?.message || res.body.message).toContain('belongs to another faculty member');
    });

    it('A3: strictly enforces StudentEnrollment roster authority (rejects unenrolled student)', async () => {
      // Student 2 is NOT in StudentEnrollment for Section A
      const res = await request(app)
        .post('/api/v1/attendance/sessions')
        .set(facultyHeaderA1)
        .send({
          subjectId: subjectA1._id.toString(),
          subjectName: subjectA1.name,
          sectionId: secA._id.toString(),
          facultyAssignmentId: assignmentA1._id.toString(),
          timeSlot: '10:00 - 11:00',
          date: '2026-09-04',
          records: [
            {
              studentId: studentDocA2._id.toString(), // Unenrolled!
              status: 'present',
            },
          ],
        });

      expect(res.status).toBe(400);
      expect(res.body.error?.message || res.body.message).toContain('not enrolled');
    });

    it('A4: supports section-disabled attendance session creation with semester-level enrollment', async () => {
      // Student enrolled at semester level
      const semStudentDoc = await Student.create({
        collegeId: collegeA._id,
        name: 'Charlie Sem Enrolled',
        email: 'charlie@etc.edu',
        rollNumber: 'ETC003',
        courseId: courseA._id,
        departmentId: deptA._id,
        academicYearId: ayA._id,
        semesterId: semA._id,
        status: 'active',
      });
      await StudentEnrollment.create({
        studentId: semStudentDoc._id,
        collegeId: collegeA._id,
        departmentId: deptA._id,
        courseId: courseA._id,
        academicYearId: ayA._id,
        semesterId: semA._id,
        sectionId: null,
        status: 'active',
      });

      const res = await request(app)
        .post('/api/v1/attendance/sessions')
        .set(facultyHeaderA1)
        .send({
          courseId: courseA._id.toString(),
          academicYearId: ayA._id.toString(),
          semesterId: semA._id.toString(),
          departmentId: deptA._id.toString(),
          subjectId: subjectA1._id.toString(),
          subjectName: subjectA1.name,
          timeSlot: '11:00 - 12:00',
          date: '2026-09-05',
          records: [
            {
              studentId: semStudentDoc._id.toString(),
              status: 'present',
            },
          ],
        });

      expect(res.status).toBe(201);
      expect(res.body.data.sectionId).toBeNull();
      expect(res.body.data.records[0].studentId.toString()).toBe(semStudentDoc._id.toString());
    });

    it('A5: prevents modification of locked attendance sessions', async () => {
      const session = await AttendanceSession.create({
        collegeId: collegeA._id,
        departmentId: deptA._id,
        courseId: courseA._id,
        academicYearId: ayA._id,
        semesterId: semA._id,
        sectionId: secA._id,
        subjectId: subjectA1._id,
        subjectName: subjectA1.name,
        facultyId: facultyDocA1._id,
        facultyAssignmentId: assignmentA1._id,
        date: new Date('2026-09-06'),
        timeSlot: '14:00 - 15:00',
        status: AttendanceSessionStatus.LOCKED,
        isLocked: true,
        records: [
          {
            studentId: studentDocA1._id,
            studentName: studentDocA1.name,
            rollNumber: studentDocA1.rollNumber,
            status: 'present',
          },
        ],
      });

      const res = await request(app)
        .post(`/api/v1/attendance/sessions/${session._id}/records`)
        .set(facultyHeaderA1)
        .send({
          records: [
            {
              studentId: studentDocA1._id.toString(),
              status: 'absent',
            },
          ],
        });

      expect(res.status).toBe(400);
      expect(res.body.error?.message || res.body.message).toContain('LOCKED');
    });

    it('A6: prevents students from submitting attendance', async () => {
      const session = await AttendanceSession.create({
        collegeId: collegeA._id,
        departmentId: deptA._id,
        courseId: courseA._id,
        academicYearId: ayA._id,
        semesterId: semA._id,
        sectionId: secA._id,
        subjectId: subjectA1._id,
        subjectName: subjectA1.name,
        facultyId: facultyDocA1._id,
        facultyAssignmentId: assignmentA1._id,
        date: new Date('2026-09-07'),
        timeSlot: '15:00 - 16:00',
        status: AttendanceSessionStatus.OPEN,
        records: [],
      });

      const res = await request(app)
        .post(`/api/v1/attendance/sessions/${session._id}/records`)
        .set(studentHeaderA1)
        .send({
          records: [
            {
              studentId: studentDocA1._id.toString(),
              status: 'present',
            },
          ],
        });

      expect(res.status).toBe(403);
      expect(res.body.error?.message || res.body.message).toContain('Access denied');
    });
  });
});
