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
import { FacultyAssignment } from '../../src/models/facultyAssignment.model';
import { Room } from '../../src/models/room.model';
import { Timetable } from '../../src/models/timetable.model';
import { AppRole } from '../../src/constants/roles';
import { CollegeStatus, DepartmentStatus, TimetableDay, TimetableStatus, AccountStatus } from '../../src/constants/status';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';
import { PasswordService } from '../../src/services/password.service';

describe('ACADEX Timetable Module — Prompt 1 Authoritative Foundation Tests', () => {
  let collegeA: InstanceType<typeof College>;
  let collegeB: InstanceType<typeof College>;
  let deptA: InstanceType<typeof Department>;
  let courseA: InstanceType<typeof Course>;
  let academicYearA: InstanceType<typeof AcademicYear>;
  let semesterA: InstanceType<typeof Semester>;
  let sectionA: InstanceType<typeof Section>;
  let sectionB: InstanceType<typeof Section>;
  let subjectMath: InstanceType<typeof Subject>;
  let subjectChem: InstanceType<typeof Subject>;

  let facultyA: InstanceType<typeof Faculty>;
  let facultyB: InstanceType<typeof Faculty>;
  let room1: InstanceType<typeof Room>;
  let room2: InstanceType<typeof Room>;

  let validAssignmentMathA: InstanceType<typeof FacultyAssignment>;
  let validAssignmentChemB: InstanceType<typeof FacultyAssignment>;

  let superAdminHeader: { Authorization: string };
  let collegeAdminAHeader: { Authorization: string };
  let collegeAdminBHeader: { Authorization: string };
  let hodAHeader: { Authorization: string };
  let facultyAHeader: { Authorization: string };
  let studentHeader: { Authorization: string };

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
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();

    const defaultPasswordHash = await PasswordService.hashPassword('Password123');

    // Colleges
    collegeA = await College.create({
      name: 'Alpha Institute',
      code: 'ALPHA',
      address: 'Alpha St',
      email: 'admin@alpha.edu',
      phone: '+919900000001',
      principal: 'Dr. Alpha',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });

    collegeB = await College.create({
      name: 'Beta Institute',
      code: 'BETA',
      address: 'Beta St',
      email: 'admin@beta.edu',
      phone: '+919900000002',
      principal: 'Dr. Beta',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });

    // Departments
    deptA = await Department.create({
      collegeId: collegeA._id,
      name: 'CSE Department',
      code: 'CSE',
      status: DepartmentStatus.ACTIVE,
      isActive: true,
    });

    // Academic Structure for College A
    courseA = await Course.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'Computer Science',
      code: 'CS',
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

    semesterA = await Semester.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      name: 'Semester 1',
      number: 1,
      isActive: true,
    });

    sectionA = await Section.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      name: 'Section A',
      capacity: 60,
      isActive: true,
    });

    sectionB = await Section.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      name: 'Section B',
      capacity: 60,
      isActive: true,
    });

    // Subjects
    subjectMath = await Subject.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      semesterId: semesterA._id,
      name: 'Mathematics',
      code: 'MATH101',
      credits: 4,
      isActive: true,
    });

    subjectChem = await Subject.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      semesterId: semesterA._id,
      name: 'Chemistry',
      code: 'CHEM101',
      credits: 4,
      isActive: true,
    });

    // Users & Profiles
    const userSuper = await User.create({
      instituteId: 'SUP-01',
      name: 'Super Admin',
      email: 'super@acadex.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.SUPER_ADMIN,
      accountStatus: AccountStatus.ACTIVE,
    });

    const userAdminA = await User.create({
      instituteId: 'ADM-A-01',
      name: 'Admin Alpha',
      email: 'admin@alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.COLLEGE_ADMIN,
      collegeId: collegeA._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    const userAdminB = await User.create({
      instituteId: 'ADM-B-01',
      name: 'Admin Beta',
      email: 'admin@beta.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.COLLEGE_ADMIN,
      collegeId: collegeB._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    const userHodA = await User.create({
      instituteId: 'HOD-A-01',
      name: 'Dr. HOD',
      email: 'hod@alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.HOD,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    const userFacultyA = await User.create({
      instituteId: 'FAC-A-01',
      name: 'Prof. Faculty A',
      email: 'fac.a@alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.FACULTY,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    facultyA = await Faculty.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      userId: userFacultyA._id,
      instituteId: userFacultyA.instituteId,
      name: userFacultyA.name,
      email: userFacultyA.email,
      designation: 'Professor',
      isActive: true,
    });

    const userFacultyB = await User.create({
      instituteId: 'FAC-B-01',
      name: 'Prof. Faculty B',
      email: 'fac.b@alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.FACULTY,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    facultyB = await Faculty.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      userId: userFacultyB._id,
      instituteId: userFacultyB.instituteId,
      name: userFacultyB.name,
      email: userFacultyB.email,
      designation: 'Assistant Professor',
      isActive: true,
    });

    const userStudent = await User.create({
      instituteId: 'STU-01',
      name: 'Student One',
      email: 'student@alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.STUDENT,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    // Rooms
    room1 = await Room.create({
      collegeId: collegeA._id,
      name: 'Room 101',
      code: 'R101',
      capacity: 70,
      type: 'lecture',
      isActive: true,
    });

    room2 = await Room.create({
      collegeId: collegeA._id,
      name: 'Room 102',
      code: 'R102',
      capacity: 70,
      type: 'lecture',
      isActive: true,
    });

    // Faculty Assignments:
    // Faculty A -> Mathematics -> Section A
    validAssignmentMathA = await FacultyAssignment.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      subjectId: subjectMath._id,
      facultyId: facultyA._id,
      facultyName: facultyA.name,
      isActive: true,
    });

    // Faculty B -> Chemistry -> Section B
    validAssignmentChemB = await FacultyAssignment.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionB._id,
      subjectId: subjectChem._id,
      facultyId: facultyB._id,
      facultyName: facultyB.name,
      isActive: true,
    });

    // Auth Headers
    superAdminHeader = createTestAuthHeader({ userId: userSuper.id, instituteId: userSuper.instituteId, role: AppRole.SUPER_ADMIN });
    collegeAdminAHeader = createTestAuthHeader({ userId: userAdminA.id, instituteId: userAdminA.instituteId, role: AppRole.COLLEGE_ADMIN, collegeId: collegeA.id });
    collegeAdminBHeader = createTestAuthHeader({ userId: userAdminB.id, instituteId: userAdminB.instituteId, role: AppRole.COLLEGE_ADMIN, collegeId: collegeB.id });
    hodAHeader = createTestAuthHeader({ userId: userHodA.id, instituteId: userHodA.instituteId, role: AppRole.HOD, collegeId: collegeA.id, departmentId: deptA.id });
    facultyAHeader = createTestAuthHeader({ userId: userFacultyA.id, instituteId: userFacultyA.instituteId, role: AppRole.FACULTY, collegeId: collegeA.id, departmentId: deptA.id });
    studentHeader = createTestAuthHeader({ userId: userStudent.id, instituteId: userStudent.instituteId, role: AppRole.STUDENT, collegeId: collegeA.id });
  });

  // =========================================================================
  // SCENARIO 1: Valid Timetable Creation
  // =========================================================================
  it('1. should create a valid draft timetable linked to an active FacultyAssignment', async () => {
    const res = await request(app)
      .post('/api/v1/timetables')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA.id,
        courseId: courseA.id,
        academicYearId: academicYearA.id,
        semesterId: semesterA.id,
        sectionId: sectionA.id,
        name: 'Section A Term 1',
        entries: [
          {
            dayOfWeek: TimetableDay.MONDAY,
            startTime: '09:00',
            endTime: '10:00',
            subjectId: subjectMath.id,
            facultyId: facultyA.id,
            facultyAssignmentId: validAssignmentMathA.id,
            roomId: room1.id,
            roomNumber: 'R101',
          },
        ],
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.status).toBe(TimetableStatus.DRAFT);
    expect(res.body.data.entries[0].facultyAssignmentId).toBe(validAssignmentMathA.id);
  });

  // =========================================================================
  // SCENARIO 2: Invalid Faculty Assignment Rejection
  // =========================================================================
  it('2. should reject timetable entry when faculty is NOT assigned to the subject & section', async () => {
    // Faculty A is assigned to Mathematics for Section A, NOT Chemistry
    const res = await request(app)
      .post('/api/v1/timetables')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA.id,
        courseId: courseA.id,
        academicYearId: academicYearA.id,
        semesterId: semesterA.id,
        sectionId: sectionA.id,
        name: 'Section A Invalid Assignment',
        entries: [
          {
            dayOfWeek: TimetableDay.MONDAY,
            startTime: '09:00',
            endTime: '10:00',
            subjectId: subjectChem.id, // Chem not assigned to Faculty A
            facultyId: facultyA.id,
            roomId: room1.id,
            roomNumber: 'R101',
          },
        ],
      });

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.error.message).toMatch(/Faculty assignment does not match this subject and section/i);
  });

  // =========================================================================
  // SCENARIO 3: Cross-College Timetable Rejection (Tenant Isolation)
  // =========================================================================
  it('3. should reject cross-college timetable operations by College Admin B on College A', async () => {
    // Create draft in College A
    const created = await Timetable.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      name: 'College A Timetable',
      status: TimetableStatus.DRAFT,
      entries: [],
    });

    // College Admin B attempts to read College A timetable
    const readRes = await request(app)
      .get(`/api/v1/timetables/${created.id}`)
      .set(collegeAdminBHeader);
    expect(readRes.status).toBe(404);

    // College Admin B attempts to update College A timetable
    const updateRes = await request(app)
      .put(`/api/v1/timetables/${created.id}`)
      .set(collegeAdminBHeader)
      .send({ name: 'Hacked Timetable' });
    expect([403, 404]).toContain(updateRes.status);

    // College Admin B attempts to publish College A timetable
    const pubRes = await request(app)
      .post(`/api/v1/timetables/${created.id}/publish`)
      .set(collegeAdminBHeader);
    expect([403, 404]).toContain(pubRes.status);

    // College Admin B attempts to delete College A timetable
    const delRes = await request(app)
      .delete(`/api/v1/timetables/${created.id}`)
      .set(collegeAdminBHeader);
    expect([403, 404]).toContain(delRes.status);
  });

  // =========================================================================
  // SCENARIO 4: Faculty Conflict Rejection
  // =========================================================================
  it('4. should reject timetable entry when the same faculty has overlapping classes', async () => {
    // Publish first timetable where Faculty A teaches Monday 09:00-10:00 in Section A
    await Timetable.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      name: 'Published Section A',
      status: TimetableStatus.PUBLISHED,
      entries: [
        {
          dayOfWeek: TimetableDay.MONDAY,
          startTime: '09:00',
          endTime: '10:00',
          subjectId: subjectMath._id,
          facultyId: facultyA._id,
          facultyAssignmentId: validAssignmentMathA._id,
          roomId: room1._id,
          roomNumber: 'R101',
          sessionType: 'lecture',
        },
      ],
    });

    // Create Faculty Assignment for Faculty A in Section B as well
    const assignB = await FacultyAssignment.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionB._id,
      subjectId: subjectMath._id,
      facultyId: facultyA._id,
      facultyName: facultyA.name,
      isActive: true,
    });

    // Attempt to schedule Faculty A on Monday 09:30-10:30 in Section B
    const res = await request(app)
      .post('/api/v1/timetables')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA.id,
        courseId: courseA.id,
        academicYearId: academicYearA.id,
        semesterId: semesterA.id,
        sectionId: sectionB.id,
        name: 'Section B Conflict',
        entries: [
          {
            dayOfWeek: TimetableDay.MONDAY,
            startTime: '09:30',
            endTime: '10:30',
            subjectId: subjectMath.id,
            facultyId: facultyA.id,
            facultyAssignmentId: assignB.id,
            roomId: room2.id,
            roomNumber: 'R102',
          },
        ],
      });

    expect(res.status).toBe(409);
    expect(res.body.error.message).toMatch(/Faculty conflict/i);
  });

  // =========================================================================
  // SCENARIO 5: Section Conflict Rejection
  // =========================================================================
  it('5. should reject timetable with internally overlapping periods for the same section', async () => {
    // Also create Faculty Assignment for Faculty B in Section A
    await FacultyAssignment.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      subjectId: subjectChem._id,
      facultyId: facultyB._id,
      facultyName: facultyB.name,
      isActive: true,
    });

    const res = await request(app)
      .post('/api/v1/timetables')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA.id,
        courseId: courseA.id,
        academicYearId: academicYearA.id,
        semesterId: semesterA.id,
        sectionId: sectionA.id,
        name: 'Section A Internal Overlap',
        entries: [
          {
            dayOfWeek: TimetableDay.MONDAY,
            startTime: '09:00',
            endTime: '10:00',
            subjectId: subjectMath.id,
            facultyId: facultyA.id,
            roomId: room1.id,
            roomNumber: 'R101',
          },
          {
            dayOfWeek: TimetableDay.MONDAY,
            startTime: '09:30', // Overlaps with 09:00-10:00!
            endTime: '10:30',
            subjectId: subjectChem.id,
            facultyId: facultyB.id,
            roomId: room2.id,
            roomNumber: 'R102',
          },
        ],
      });

    expect(res.status).toBe(409);
    expect(res.body.error.message).toMatch(/Section conflict/i);
  });

  // =========================================================================
  // SCENARIO 6: Room Conflict Rejection
  // =========================================================================
  it('6. should reject timetable entry when the specified room is already double-booked', async () => {
    // Section A published in Room 101 on Monday 09:00-10:00
    await Timetable.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      name: 'Section A Published',
      status: TimetableStatus.PUBLISHED,
      entries: [
        {
          dayOfWeek: TimetableDay.MONDAY,
          startTime: '09:00',
          endTime: '10:00',
          subjectId: subjectMath._id,
          facultyId: facultyA._id,
          facultyAssignmentId: validAssignmentMathA._id,
          roomId: room1._id,
          roomNumber: 'R101',
          sessionType: 'lecture',
        },
      ],
    });

    // Section B tries to schedule Monday 09:30-10:30 in Room 101
    const res = await request(app)
      .post('/api/v1/timetables')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA.id,
        courseId: courseA.id,
        academicYearId: academicYearA.id,
        semesterId: semesterA.id,
        sectionId: sectionB.id,
        name: 'Section B Room Overlap',
        entries: [
          {
            dayOfWeek: TimetableDay.MONDAY,
            startTime: '09:30',
            endTime: '10:30',
            subjectId: subjectChem.id,
            facultyId: facultyB.id,
            facultyAssignmentId: validAssignmentChemB.id,
            roomId: room1.id,
            roomNumber: 'R101', // Same room!
          },
        ],
      });

    expect(res.status).toBe(409);
    expect(res.body.error.message).toMatch(/Room conflict/i);
  });

  // =========================================================================
  // SCENARIO 7: Invalid Time Rejection
  // =========================================================================
  it('7. should reject timetable entries with zero duration or invalid time range (start >= end)', async () => {
    const res = await request(app)
      .post('/api/v1/timetables')
      .set(collegeAdminAHeader)
      .send({
        departmentId: deptA.id,
        courseId: courseA.id,
        academicYearId: academicYearA.id,
        semesterId: semesterA.id,
        sectionId: sectionA.id,
        name: 'Invalid Time Entry',
        entries: [
          {
            dayOfWeek: TimetableDay.MONDAY,
            startTime: '10:00',
            endTime: '10:00', // Zero duration
            subjectId: subjectMath.id,
            facultyId: facultyA.id,
            roomId: room1.id,
            roomNumber: 'R101',
          },
        ],
      });

    expect([400, 422]).toContain(res.status);
  });

  // =========================================================================
  // SCENARIO 8: Successful Publish Lifecycle
  // =========================================================================
  it('8. should successfully publish a clean draft timetable with full validation', async () => {
    const draft = await Timetable.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      name: 'Clean Draft to Publish',
      status: TimetableStatus.DRAFT,
      entries: [
        {
          dayOfWeek: TimetableDay.MONDAY,
          startTime: '09:00',
          endTime: '10:00',
          subjectId: subjectMath._id,
          facultyId: facultyA._id,
          facultyAssignmentId: validAssignmentMathA._id,
          roomId: room1._id,
          roomNumber: 'R101',
          sessionType: 'lecture',
        },
      ],
    });

    const res = await request(app)
      .post(`/api/v1/timetables/${draft.id}/publish`)
      .set(collegeAdminAHeader);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.status).toBe(TimetableStatus.PUBLISHED);
    expect(res.body.data.publishedAt).toBeDefined();
  });

  // =========================================================================
  // SCENARIO 9: Invalid Timetable Cannot Publish (Atomic Preservation)
  // =========================================================================
  it('9. should reject publishing a timetable containing conflicts, preserving previous state', async () => {
    // 1. Publish timetable X in Section B with Faculty B on Monday 09:00-10:00 in Room 102
    await Timetable.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionB._id,
      name: 'Section B Stable',
      status: TimetableStatus.PUBLISHED,
      entries: [
        {
          dayOfWeek: TimetableDay.MONDAY,
          startTime: '09:00',
          endTime: '10:00',
          subjectId: subjectChem._id,
          facultyId: facultyB._id,
          facultyAssignmentId: validAssignmentChemB._id,
          roomId: room2._id,
          roomNumber: 'R102',
          sessionType: 'lecture',
        },
      ],
    });

    // 2. Draft in Section A that has a Room Conflict with Room 102
    const conflictedDraft = await Timetable.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      name: 'Conflicted Draft',
      status: TimetableStatus.DRAFT,
      entries: [
        {
          dayOfWeek: TimetableDay.MONDAY,
          startTime: '09:00',
          endTime: '10:00',
          subjectId: subjectMath._id,
          facultyId: facultyA._id,
          facultyAssignmentId: validAssignmentMathA._id,
          roomId: room2._id, // Room 102 conflict!
          roomNumber: 'R102',
          sessionType: 'lecture',
        },
      ],
    });

    // 3. Attempt publish
    const res = await request(app)
      .post(`/api/v1/timetables/${conflictedDraft.id}/publish`)
      .set(collegeAdminAHeader);

    expect(res.status).toBe(409);
    expect(res.body.error.message).toMatch(/Room conflict/i);

    // Verify draft remains untouched as DRAFT in DB
    const persisted = await Timetable.findById(conflictedDraft.id);
    expect(persisted?.status).toBe(TimetableStatus.DRAFT);
    expect(persisted?.publishedAt).toBeNull();
  });

  // =========================================================================
  // SCENARIO 10: Unpublish Behavior
  // =========================================================================
  it('10. should successfully unpublish a published timetable back to DRAFT', async () => {
    const published = await Timetable.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      name: 'To Unpublish',
      status: TimetableStatus.PUBLISHED,
      entries: [],
    });

    const res = await request(app)
      .post(`/api/v1/timetables/${published.id}/unpublish`)
      .set(collegeAdminAHeader);

    expect(res.status).toBe(200);
    expect(res.body.data.status).toBe(TimetableStatus.DRAFT);

    const doc = await Timetable.findById(published.id);
    expect(doc?.status).toBe(TimetableStatus.DRAFT);
  });

  // =========================================================================
  // SCENARIO 11: Unauthorized Role Rejection
  // =========================================================================
  it('11. should reject students and ordinary faculty while allowing HOD and SuperAdmin', async () => {
    const createResStudent = await request(app)
      .post('/api/v1/timetables')
      .set(studentHeader)
      .send({ name: 'Student Hack' });
    expect(createResStudent.status).toBe(403);

    const createResFaculty = await request(app)
      .post('/api/v1/timetables')
      .set(facultyAHeader)
      .send({ name: 'Faculty Hack' });
    expect(createResFaculty.status).toBe(403);

    // HOD is permitted to create for their department
    const hodCreateRes = await request(app)
      .post('/api/v1/timetables')
      .set(hodAHeader)
      .send({
        departmentId: deptA.id,
        courseId: courseA.id,
        academicYearId: academicYearA.id,
        semesterId: semesterA.id,
        sectionId: sectionA.id,
        name: 'HOD Created Timetable',
        entries: [],
      });
    expect(hodCreateRes.status).toBe(201);

    // Super Admin is permitted to create with collegeId
    const superCreateRes = await request(app)
      .post('/api/v1/timetables')
      .set(superAdminHeader)
      .send({
        collegeId: collegeA.id,
        departmentId: deptA.id,
        courseId: courseA.id,
        academicYearId: academicYearA.id,
        semesterId: semesterA.id,
        sectionId: sectionA.id,
        name: 'SuperAdmin Created Timetable',
        entries: [],
      });
    expect(superCreateRes.status).toBe(201);
  });

  // =========================================================================
  // SCENARIO 12: Update Behavior & Entry Re-validation
  // =========================================================================
  it('12. should update draft timetable and re-validate newly added entries', async () => {
    const draft = await Timetable.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      name: 'Original Draft',
      status: TimetableStatus.DRAFT,
      entries: [],
    });

    // Valid update
    const updateRes = await request(app)
      .put(`/api/v1/timetables/${draft.id}`)
      .set(collegeAdminAHeader)
      .send({
        name: 'Renamed Draft',
        entries: [
          {
            dayOfWeek: TimetableDay.TUESDAY,
            startTime: '10:00',
            endTime: '11:00',
            subjectId: subjectMath.id,
            facultyId: facultyA.id,
            roomId: room1.id,
            roomNumber: 'R101',
          },
        ],
      });

    expect(updateRes.status).toBe(200);
    expect(updateRes.body.data.name).toBe('Renamed Draft');
    expect(updateRes.body.data.entries[0].dayOfWeek).toBe(TimetableDay.TUESDAY);
  });

  // =========================================================================
  // SCENARIO 13: Archive and Delete Behavior
  // =========================================================================
  it('13. should support both archive (soft-archive) and delete (removal) operations', async () => {
    const tt = await Timetable.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      name: 'To Archive and Delete',
      status: TimetableStatus.DRAFT,
      entries: [],
    });

    // Archive
    const archiveRes = await request(app)
      .post(`/api/v1/timetables/${tt.id}/archive`)
      .set(collegeAdminAHeader);
    expect(archiveRes.status).toBe(200);
    expect(archiveRes.body.data.status).toBe(TimetableStatus.ARCHIVED);

    // Delete
    const deleteRes = await request(app)
      .delete(`/api/v1/timetables/${tt.id}`)
      .set(collegeAdminAHeader);
    expect(deleteRes.status).toBe(204);

    const doc = await Timetable.findById(tt.id);
    expect(doc).toBeNull();
  });

  // =========================================================================
  // SCENARIO 14: No Partial Mutation after Validation Failure
  // =========================================================================
  it('14. should not partially mutate timetable if entry validation fails during update', async () => {
    const draft = await Timetable.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      name: 'Intact Name',
      status: TimetableStatus.DRAFT,
      entries: [],
    });

    const failedUpdateRes = await request(app)
      .put(`/api/v1/timetables/${draft.id}`)
      .set(collegeAdminAHeader)
      .send({
        name: 'Should Not Mutate',
        entries: [
          {
            dayOfWeek: TimetableDay.WEDNESDAY,
            startTime: '11:00',
            endTime: '12:00',
            subjectId: subjectChem.id, // Not assigned to Faculty A!
            facultyId: facultyA.id,
            roomId: room1.id,
            roomNumber: 'R101',
          },
        ],
      });

    expect(failedUpdateRes.status).toBe(400);

    const checkDoc = await Timetable.findById(draft.id);
    expect(checkDoc?.name).toBe('Intact Name');
    expect(checkDoc?.entries.length).toBe(0);
  });
});
