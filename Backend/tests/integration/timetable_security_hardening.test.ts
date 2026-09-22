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
import { FacultyAssignment } from '../../src/models/facultyAssignment.model';
import { Room } from '../../src/models/room.model';
import { Timetable } from '../../src/models/timetable.model';
import { AttendanceSession } from '../../src/models/attendanceSession.model';
import { AppRole } from '../../src/constants/roles';
import { CollegeStatus, DepartmentStatus, TimetableDay, TimetableStatus, TimetableBreakType, AttendanceSessionStatus, AccountStatus } from '../../src/constants/status';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';
import { PasswordService } from '../../src/services/password.service';

describe('ACADEX Timetable Module — Prompt 3 Backend Safety & Security Hardening Tests', () => {
  let collegeA: InstanceType<typeof College>;
  let collegeB: InstanceType<typeof College>;
  let deptA: InstanceType<typeof Department>;
  let deptB: InstanceType<typeof Department>;
  let courseA: InstanceType<typeof Course>;
  let academicYearA: InstanceType<typeof AcademicYear>;
  let semesterA: InstanceType<typeof Semester>;
  let sectionA: InstanceType<typeof Section>;
  let subjectMath: InstanceType<typeof Subject>;
  let facultyA: InstanceType<typeof Faculty>;
  let validAssignmentMathA: InstanceType<typeof FacultyAssignment>;

  let superAdminHeader: { Authorization: string };
  let collegeAdminAHeader: { Authorization: string };
  let collegeAdminBHeader: { Authorization: string };
  let hodAHeader: { Authorization: string };
  let hodBHeader: { Authorization: string };
  let facultyAHeader: { Authorization: string };
  let studentHeader: { Authorization: string };

  const defaultLunchBreak = {
    name: 'Lunch Break',
    startTime: '13:00',
    endTime: '14:00',
    appliesToDays: [TimetableDay.MONDAY, TimetableDay.TUESDAY, TimetableDay.WEDNESDAY, TimetableDay.THURSDAY, TimetableDay.FRIDAY],
    isVerticalSpan: true,
    breakType: TimetableBreakType.LUNCH,
  };

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
    await AttendanceSession.init();
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

    // Departments in College A
    deptA = await Department.create({
      collegeId: collegeA._id,
      name: 'CSE Department',
      code: 'CSE',
      status: DepartmentStatus.ACTIVE,
      isActive: true,
    });

    deptB = await Department.create({
      collegeId: collegeA._id,
      name: 'ECE Department',
      code: 'ECE',
      status: DepartmentStatus.ACTIVE,
      isActive: true,
    });

    // Academic Structure for College A, Dept A
    courseA = await Course.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'Computer Science',
      code: 'CS',
      durationYears: 4,
      totalSemesters: 8,
      isActive: true,
    });

    academicYearA = await AcademicYear.create({
      collegeId: collegeA._id,
      name: '2026-2027',
      startDate: new Date('2026-08-01'),
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
      semesterId: semesterA._id,
      name: 'Section A',
      capacity: 60,
      isActive: true,
    });

    subjectMath = await Subject.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      semesterId: semesterA._id,
      name: 'Engineering Mathematics',
      code: 'MATH101',
      credits: 4,
      type: 'Theory',
      isActive: true,
    });

    facultyA = await Faculty.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'Dr. Alan Turing',
      employeeId: 'EMP_TURING',
      email: 'turing@alpha.edu',
      phone: '+919876543210',
      isActive: true,
    });

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
      role: 'primary',
      isActive: true,
    });

    // Users & Auth Headers
    const superAdminUser = await User.create({
      instituteId: 'SUP-01',
      collegeId: collegeA._id,
      name: 'Super Admin',
      email: 'superadmin@acadex.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.SUPER_ADMIN,
      accountStatus: AccountStatus.ACTIVE,
    });
    superAdminHeader = createTestAuthHeader({
      userId: superAdminUser.id,
      instituteId: superAdminUser.instituteId,
      role: AppRole.SUPER_ADMIN,
      collegeId: collegeA.id,
    });

    const collegeAdminAUser = await User.create({
      instituteId: 'ADM-A-01',
      collegeId: collegeA._id,
      name: 'Admin Alpha',
      email: 'admin@alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.COLLEGE_ADMIN,
      accountStatus: AccountStatus.ACTIVE,
    });
    collegeAdminAHeader = createTestAuthHeader({
      userId: collegeAdminAUser.id,
      instituteId: collegeAdminAUser.instituteId,
      role: AppRole.COLLEGE_ADMIN,
      collegeId: collegeA.id,
    });

    const collegeAdminBUser = await User.create({
      instituteId: 'ADM-B-01',
      collegeId: collegeB._id,
      name: 'Admin Beta',
      email: 'admin@beta.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.COLLEGE_ADMIN,
      accountStatus: AccountStatus.ACTIVE,
    });
    collegeAdminBHeader = createTestAuthHeader({
      userId: collegeAdminBUser.id,
      instituteId: collegeAdminBUser.instituteId,
      role: AppRole.COLLEGE_ADMIN,
      collegeId: collegeB.id,
    });

    const hodAUser = await User.create({
      instituteId: 'HOD-A-01',
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'HOD CSE',
      email: 'hod.cse@alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.HOD,
      accountStatus: AccountStatus.ACTIVE,
    });
    hodAHeader = createTestAuthHeader({
      userId: hodAUser.id,
      instituteId: hodAUser.instituteId,
      role: AppRole.HOD,
      collegeId: collegeA.id,
      departmentId: deptA.id,
    });

    const hodBUser = await User.create({
      instituteId: 'HOD-B-01',
      collegeId: collegeA._id,
      departmentId: deptB._id,
      name: 'HOD ECE',
      email: 'hod.ece@alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.HOD,
      accountStatus: AccountStatus.ACTIVE,
    });
    hodBHeader = createTestAuthHeader({
      userId: hodBUser.id,
      instituteId: hodBUser.instituteId,
      role: AppRole.HOD,
      collegeId: collegeA.id,
      departmentId: deptB.id,
    });

    const facultyAUser = await User.create({
      instituteId: 'FAC-A-01',
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'Faculty Turing User',
      email: 'turing.user@alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.FACULTY,
      accountStatus: AccountStatus.ACTIVE,
    });
    facultyAHeader = createTestAuthHeader({
      userId: facultyAUser.id,
      instituteId: facultyAUser.instituteId,
      role: AppRole.FACULTY,
      collegeId: collegeA.id,
      departmentId: deptA.id,
    });

    const studentUser = await User.create({
      instituteId: 'STU-01',
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'Student Bob',
      email: 'bob@alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.STUDENT,
      accountStatus: AccountStatus.ACTIVE,
    });
    studentHeader = createTestAuthHeader({
      userId: studentUser.id,
      instituteId: studentUser.instituteId,
      role: AppRole.STUDENT,
      collegeId: collegeA.id,
    });
  });

  const getErrorMessage = (res: any) => res.body.error?.message || res.body.message || '';

  // ===========================================================================
  // 1. BREAK CONFLICT VALIDATION (A, B, C, D, E)
  // ===========================================================================
  describe('1. Break Conflict Validation', () => {
    it('A. rejects class exactly overlapping configured break on the same day', async () => {
      const res = await request(app)
        .post('/api/v1/timetables')
        .set(hodAHeader)
        .send({
          departmentId: deptA.id,
          courseId: courseA.id,
          academicYearId: academicYearA.id,
          semesterId: semesterA.id,
          sectionId: sectionA.id,
          name: 'Break Conflict Timetable',
          breaks: [defaultLunchBreak],
          entries: [
            {
              dayOfWeek: TimetableDay.MONDAY,
              startTime: '13:00',
              endTime: '14:00',
              subjectId: subjectMath.id,
              facultyId: facultyA.id,
              facultyAssignmentId: validAssignmentMathA.id,
            },
          ],
        });

      expect(res.status).toBe(409);
      expect(getErrorMessage(res)).toContain('Break conflict');
      expect(getErrorMessage(res)).toContain('Lunch Break');
    });

    it('B. rejects class partially overlapping configured break (e.g. 12:30-13:30 vs 13:00-14:00)', async () => {
      const res = await request(app)
        .post('/api/v1/timetables')
        .set(hodAHeader)
        .send({
          departmentId: deptA.id,
          courseId: courseA.id,
          academicYearId: academicYearA.id,
          semesterId: semesterA.id,
          sectionId: sectionA.id,
          name: 'Partial Break Conflict Timetable',
          breaks: [defaultLunchBreak],
          entries: [
            {
              dayOfWeek: TimetableDay.MONDAY,
              startTime: '12:30',
              endTime: '13:30',
              subjectId: subjectMath.id,
              facultyId: facultyA.id,
              facultyAssignmentId: validAssignmentMathA.id,
            },
          ],
        });

      expect(res.status).toBe(409);
      expect(getErrorMessage(res)).toContain('Break conflict');
    });

    it('C. rejects class completely inside configured break (e.g. 13:15-13:45 vs 13:00-14:00)', async () => {
      const res = await request(app)
        .post('/api/v1/timetables')
        .set(hodAHeader)
        .send({
          departmentId: deptA.id,
          courseId: courseA.id,
          academicYearId: academicYearA.id,
          semesterId: semesterA.id,
          sectionId: sectionA.id,
          name: 'Inside Break Conflict Timetable',
          breaks: [defaultLunchBreak],
          entries: [
            {
              dayOfWeek: TimetableDay.MONDAY,
              startTime: '13:15',
              endTime: '13:45',
              subjectId: subjectMath.id,
              facultyId: facultyA.id,
              facultyAssignmentId: validAssignmentMathA.id,
            },
          ],
        });

      expect(res.status).toBe(409);
      expect(getErrorMessage(res)).toContain('Break conflict');
    });

    it('D. rejects class fully enclosing configured break (e.g. 12:00-15:00 vs 13:00-14:00)', async () => {
      const res = await request(app)
        .post('/api/v1/timetables')
        .set(hodAHeader)
        .send({
          departmentId: deptA.id,
          courseId: courseA.id,
          academicYearId: academicYearA.id,
          semesterId: semesterA.id,
          sectionId: sectionA.id,
          name: 'Enclosing Break Conflict Timetable',
          breaks: [defaultLunchBreak],
          entries: [
            {
              dayOfWeek: TimetableDay.MONDAY,
              startTime: '12:00',
              endTime: '15:00',
              subjectId: subjectMath.id,
              facultyId: facultyA.id,
              facultyAssignmentId: validAssignmentMathA.id,
            },
          ],
        });

      expect(res.status).toBe(409);
      expect(getErrorMessage(res)).toContain('Break conflict');
    });

    it('E. accepts mathematically adjacent non-overlapping class and break boundaries (12:00-13:00 and 14:00-15:00)', async () => {
      const res = await request(app)
        .post('/api/v1/timetables')
        .set(hodAHeader)
        .send({
          departmentId: deptA.id,
          courseId: courseA.id,
          academicYearId: academicYearA.id,
          semesterId: semesterA.id,
          sectionId: sectionA.id,
          name: 'Adjacent Valid Timetable',
          breaks: [defaultLunchBreak],
          entries: [
            {
              dayOfWeek: TimetableDay.MONDAY,
              startTime: '12:00',
              endTime: '13:00',
              subjectId: subjectMath.id,
              facultyId: facultyA.id,
              facultyAssignmentId: validAssignmentMathA.id,
            },
            {
              dayOfWeek: TimetableDay.MONDAY,
              startTime: '14:00',
              endTime: '15:00',
              subjectId: subjectMath.id,
              facultyId: facultyA.id,
              facultyAssignmentId: validAssignmentMathA.id,
            },
          ],
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.entries.length).toBe(2);
    });

    it('allows class during break hours if break applies to a different day', async () => {
      const tuesdayOnlyBreak = {
        name: 'Tuesday Break',
        startTime: '10:00',
        endTime: '11:00',
        appliesToDays: [TimetableDay.TUESDAY],
        isVerticalSpan: true,
        breakType: TimetableBreakType.TEA,
      };

      const res = await request(app)
        .post('/api/v1/timetables')
        .set(hodAHeader)
        .send({
          departmentId: deptA.id,
          courseId: courseA.id,
          academicYearId: academicYearA.id,
          semesterId: semesterA.id,
          sectionId: sectionA.id,
          name: 'Different Day Timetable',
          breaks: [tuesdayOnlyBreak],
          entries: [
            {
              dayOfWeek: TimetableDay.MONDAY, // Monday class vs Tuesday break -> Valid
              startTime: '10:00',
              endTime: '11:00',
              subjectId: subjectMath.id,
              facultyId: facultyA.id,
              facultyAssignmentId: validAssignmentMathA.id,
            },
          ],
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
    });

    it('validates break conflict when updating breaks on an existing draft', async () => {
      const draft = await Timetable.create({
        collegeId: collegeA._id,
        departmentId: deptA._id,
        courseId: courseA._id,
        academicYearId: academicYearA._id,
        semesterId: semesterA._id,
        sectionId: sectionA._id,
        name: 'Draft Without Breaks',
        status: TimetableStatus.DRAFT,
        breaks: [],
        entries: [
          {
            dayOfWeek: TimetableDay.MONDAY,
            startTime: '13:00',
            endTime: '14:00',
            subjectId: subjectMath._id,
            facultyId: facultyA._id,
            facultyAssignmentId: validAssignmentMathA._id,
          },
        ],
      });

      // Update with a break that collides with the existing Monday 13:00-14:00 entry
      const res = await request(app)
        .put(`/api/v1/timetables/${draft.id}`)
        .set(hodAHeader)
        .send({
          breaks: [defaultLunchBreak],
        });

      expect(res.status).toBe(409);
      expect(getErrorMessage(res)).toContain('Break conflict');
    });

    it('validates break conflict when publishing a draft', async () => {
      const draftWithConflict = await Timetable.create({
        collegeId: collegeA._id,
        departmentId: deptA._id,
        courseId: courseA._id,
        academicYearId: academicYearA._id,
        semesterId: semesterA._id,
        sectionId: sectionA._id,
        name: 'Draft Stored Before Validation',
        status: TimetableStatus.DRAFT,
        breaks: [defaultLunchBreak],
        entries: [
          {
            dayOfWeek: TimetableDay.MONDAY,
            startTime: '13:30',
            endTime: '14:30',
            subjectId: subjectMath._id,
            facultyId: facultyA._id,
            facultyAssignmentId: validAssignmentMathA._id,
          },
        ],
      });

      const res = await request(app)
        .post(`/api/v1/timetables/${draftWithConflict.id}/publish`)
        .set(hodAHeader);

      expect(res.status).toBe(409);
      expect(getErrorMessage(res)).toContain('Break conflict');
    });
  });

  // ===========================================================================
  // 2. TIMETABLE DELETE SAFETY (F, G, H)
  // ===========================================================================
  describe('2. Timetable Delete Safety', () => {
    it('F. timetable without attendance sessions can be hard-deleted successfully', async () => {
      const timetable = await Timetable.create({
        collegeId: collegeA._id,
        departmentId: deptA._id,
        courseId: courseA._id,
        academicYearId: academicYearA._id,
        semesterId: semesterA._id,
        sectionId: sectionA._id,
        name: 'Timetable To Delete',
        status: TimetableStatus.DRAFT,
        entries: [],
      });

      const res = await request(app)
        .delete(`/api/v1/timetables/${timetable.id}`)
        .set(hodAHeader);

      expect(res.status).toBe(204);

      const found = await Timetable.findById(timetable.id);
      expect(found).toBeNull();
    });

    it('G & H. timetable with AttendanceSession cannot be hard-deleted, returns 409 and leaves attendance records intact', async () => {
      const timetable = await Timetable.create({
        collegeId: collegeA._id,
        departmentId: deptA._id,
        courseId: courseA._id,
        academicYearId: academicYearA._id,
        semesterId: semesterA._id,
        sectionId: sectionA._id,
        name: 'Timetable With Attendance',
        status: TimetableStatus.PUBLISHED,
        entries: [
          {
            dayOfWeek: TimetableDay.MONDAY,
            startTime: '09:00',
            endTime: '10:00',
            subjectId: subjectMath._id,
            facultyId: facultyA._id,
            facultyAssignmentId: validAssignmentMathA._id,
          },
        ],
      });

      // Create historical attendance session linked to this timetable
      const attendanceSession = await AttendanceSession.create({
        collegeId: collegeA._id,
        departmentId: deptA._id,
        facultyId: facultyA._id,
        subjectId: subjectMath._id,
        subjectName: 'Mathematics',
        sectionId: sectionA._id,
        sectionName: 'Section A',
        timeSlot: '09:00 - 10:00',
        date: new Date('2026-08-24'),
        timetableId: timetable._id,
        timetableEntryId: timetable.entries[0]._id!.toString(),
        facultyAssignmentId: validAssignmentMathA._id,
        status: AttendanceSessionStatus.CLOSED,
        records: [],
      });

      // Attempt hard deletion
      const res = await request(app)
        .delete(`/api/v1/timetables/${timetable.id}`)
        .set(hodAHeader);

      // G: Rejected with 409 Conflict instructing to archive
      expect(res.status).toBe(409);
      expect(getErrorMessage(res)).toContain('Cannot delete timetable with existing attendance sessions');
      expect(getErrorMessage(res)).toContain('archive');

      // H: AttendanceSession and Timetable remain untouched in DB
      const sessionInDb = await AttendanceSession.findById(attendanceSession.id);
      expect(sessionInDb).not.toBeNull();
      expect(sessionInDb!.timetableId?.toString()).toBe(timetable.id);

      const timetableInDb = await Timetable.findById(timetable.id);
      expect(timetableInDb).not.toBeNull();
    });
  });

  // ===========================================================================
  // 3. GET /timetables/:id DEPARTMENT & ROLE SECURITY (I, J, K, L, M)
  // ===========================================================================
  describe('3. GET /timetables/:id Department & Role Security', () => {
    let deptATimetable: InstanceType<typeof Timetable>;

    beforeEach(async () => {
      deptATimetable = await Timetable.create({
        collegeId: collegeA._id,
        departmentId: deptA._id,
        courseId: courseA._id,
        academicYearId: academicYearA._id,
        semesterId: semesterA._id,
        sectionId: sectionA._id,
        name: 'Dept A Master Timetable',
        status: TimetableStatus.DRAFT,
        entries: [],
      });
    });

    it('I. HOD can GET own department timetable', async () => {
      const res = await request(app)
        .get(`/api/v1/timetables/${deptATimetable.id}`)
        .set(hodAHeader);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.id).toBe(deptATimetable.id);
    });

    it('J. HOD cannot GET another department timetable (403 Forbidden)', async () => {
      const res = await request(app)
        .get(`/api/v1/timetables/${deptATimetable.id}`)
        .set(hodBHeader); // HOD of Department B attempts to read Dept A timetable

      expect(res.status).toBe(403);
      expect(getErrorMessage(res)).toContain('Cross-department timetable access is prohibited');
    });

    it('K. Faculty cannot use generic GET /timetables/:id to inspect arbitrary timetable (403 Forbidden)', async () => {
      const res = await request(app)
        .get(`/api/v1/timetables/${deptATimetable.id}`)
        .set(facultyAHeader);

      expect(res.status).toBe(403);
      expect(getErrorMessage(res)).toContain('Access denied');
    });

    it('L. Student cannot use generic GET /timetables/:id to inspect arbitrary timetable (403 Forbidden)', async () => {
      const res = await request(app)
        .get(`/api/v1/timetables/${deptATimetable.id}`)
        .set(studentHeader);

      expect(res.status).toBe(403);
      expect(getErrorMessage(res)).toContain('Access denied');
    });

    it('M. Legitimate admin access (College Admin & Super Admin) remains valid', async () => {
      // College Admin of College A
      const adminRes = await request(app)
        .get(`/api/v1/timetables/${deptATimetable.id}`)
        .set(collegeAdminAHeader);
      expect(adminRes.status).toBe(200);
      expect(adminRes.body.data.id).toBe(deptATimetable.id);

      // Super Admin
      const superRes = await request(app)
        .get(`/api/v1/timetables/${deptATimetable.id}`)
        .set(superAdminHeader);
      expect(superRes.status).toBe(200);
      expect(superRes.body.data.id).toBe(deptATimetable.id);
    });
  });

  // ===========================================================================
  // 4. ID TAMPERING PROTECTIONS (N, O, P)
  // ===========================================================================
  describe('4. ID Tampering Protections', () => {
    it('N. foreign/non-existent timetable ID returns 404', async () => {
      const nonExistentId = new mongoose.Types.ObjectId().toString();
      const res = await request(app)
        .get(`/api/v1/timetables/${nonExistentId}`)
        .set(hodAHeader);

      expect(res.status).toBe(404);
      expect(getErrorMessage(res)).toContain('not found');
    });

    it('O. HOD cannot tamper with departmentId in create or list to access another department', async () => {
      // HOD A attempts to create timetable claiming Department B
      const createRes = await request(app)
        .post('/api/v1/timetables')
        .set(hodAHeader)
        .send({
          departmentId: deptB.id,
          courseId: courseA.id,
          academicYearId: academicYearA.id,
          semesterId: semesterA.id,
          sectionId: sectionA.id,
          name: 'Tampered Dept Timetable',
          entries: [],
        });

      expect(createRes.status).toBe(403);
      expect(getErrorMessage(createRes)).toContain('HOD can only create timetables within their assigned department');

      // HOD A attempts to list timetables passing departmentId of Dept B in query param
      const listRes = await request(app)
        .get(`/api/v1/timetables?departmentId=${deptB.id}`)
        .set(hodAHeader);

      expect(listRes.status).toBe(403);
      expect(getErrorMessage(listRes)).toContain('HOD can only query timetables for their own department');
    });

    it('P. College Admin cannot access or delete foreign college timetable (Cross-College)', async () => {
      const collegeATimetable = await Timetable.create({
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
        .get(`/api/v1/timetables/${collegeATimetable.id}`)
        .set(collegeAdminBHeader);
      expect([403, 404]).toContain(readRes.status);

      // College Admin B attempts to delete College A timetable
      const delRes = await request(app)
        .delete(`/api/v1/timetables/${collegeATimetable.id}`)
        .set(collegeAdminBHeader);
      expect([403, 404]).toContain(delRes.status);
    });
  });
});
