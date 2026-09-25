import request from 'supertest';
import mongoose from 'mongoose';
import { app } from '../../src/app';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { User } from '../../src/models/user.model';
import { College } from '../../src/models/college.model';
import { Department } from '../../src/models/department.model';
import { Course } from '../../src/models/course.model';
import { AcademicYear } from '../../src/models/academicYear.model';
import { Semester } from '../../src/models/semester.model';
import { Section } from '../../src/models/section.model';
import { Subject } from '../../src/models/subject.model';
import { Faculty } from '../../src/models/faculty.model';
import { FacultyAssignment } from '../../src/models/facultyAssignment.model';
import { Timetable } from '../../src/models/timetable.model';
import { TeacherSubstitution, TeacherSubstitutionStatus } from '../../src/models/teacherSubstitution.model';
import { AttendanceSession } from '../../src/models/attendanceSession.model';
import { AttendanceRecord } from '../../src/models/attendanceRecord.model';
import { AuthSession } from '../../src/models/authSession.model';
import { signAccessToken } from '../../src/utils/token';
import { PasswordService } from '../../src/services/password.service';
import { AppRole } from '../../src/constants/roles';
import {
  AccountStatus,
  CollegeStatus,
  DepartmentStatus,
  TimetableStatus,
  TimetableDay,
  TimetableSessionType,
  AttendanceStatus,
  AttendanceSessionStatus,
} from '../../src/constants/status';

describe('Admin Relationship Integrity & User Lifecycle Maintenance Tests', () => {
  let superAdminUser: any;
  let superAdminToken: string;
  let collegeAdminUserA: any;
  let collegeAdminTokenA: string;
  let collegeAdminUserB: any;
  let collegeAdminTokenB: string;

  let collegeA: any;
  let collegeB: any;
  let deptA: any;
  let deptB: any;
  let courseA: any;
  let acadYearA: any;
  let semesterA: any;
  let sectionA: any;
  let subjectA: any;

  beforeAll(async () => {
    await setupTestDB();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();

    const passwordHash = await PasswordService.hashPassword('Password@123');

    // 1. Super Admin
    superAdminUser = await User.create({
      name: 'Global Super Admin',
      email: 'superadmin@acadex.com',
      instituteId: 'SA-001',
      role: AppRole.SUPER_ADMIN,
      passwordHash,
      accountStatus: AccountStatus.ACTIVE,
      activationStatus: 'activated',
      collegeId: null,
    });
    superAdminToken = signAccessToken({
      userId: superAdminUser.id,
      email: superAdminUser.email,
      role: superAdminUser.role,
    });

    // 2. Colleges A & B
    collegeA = await College.create({
      name: 'College of Engineering A',
      code: 'COEA',
      address: '100 North Rd',
      email: 'contact@coea.edu',
      phone: '9988776655',
      principal: 'Dr. Alpha',
      status: CollegeStatus.ACTIVE,
      isActive: true,
      createdBy: superAdminUser.id,
      updatedBy: superAdminUser.id,
    });

    collegeB = await College.create({
      name: 'College of Technology B',
      code: 'COTB',
      address: '200 South Rd',
      email: 'contact@cotb.edu',
      phone: '8877665544',
      principal: 'Dr. Beta',
      status: CollegeStatus.ACTIVE,
      isActive: true,
      createdBy: superAdminUser.id,
      updatedBy: superAdminUser.id,
    });

    // 3. College Admins
    collegeAdminUserA = await User.create({
      name: 'Admin College A',
      email: 'admin@coea.edu',
      instituteId: 'COEA-ADM-01',
      role: AppRole.COLLEGE_ADMIN,
      passwordHash,
      accountStatus: AccountStatus.ACTIVE,
      activationStatus: 'activated',
      collegeId: collegeA._id,
    });
    collegeAdminTokenA = signAccessToken({
      userId: collegeAdminUserA.id,
      email: collegeAdminUserA.email,
      role: collegeAdminUserA.role,
      collegeId: collegeA._id.toString(),
    });

    collegeAdminUserB = await User.create({
      name: 'Admin College B',
      email: 'admin@cotb.edu',
      instituteId: 'COTB-ADM-01',
      role: AppRole.COLLEGE_ADMIN,
      passwordHash,
      accountStatus: AccountStatus.ACTIVE,
      activationStatus: 'activated',
      collegeId: collegeB._id,
    });
    collegeAdminTokenB = signAccessToken({
      userId: collegeAdminUserB.id,
      email: collegeAdminUserB.email,
      role: collegeAdminUserB.role,
      collegeId: collegeB._id.toString(),
    });

    // 4. Departments
    deptA = await Department.create({
      name: 'Computer Science & Engineering',
      code: 'CSE',
      collegeId: collegeA._id,
      status: DepartmentStatus.ACTIVE,
      isActive: true,
      createdBy: superAdminUser.id,
      updatedBy: superAdminUser.id,
    });

    deptB = await Department.create({
      name: 'Mechanical Engineering',
      code: 'MECH',
      collegeId: collegeB._id,
      status: DepartmentStatus.ACTIVE,
      isActive: true,
      createdBy: superAdminUser.id,
      updatedBy: superAdminUser.id,
    });

    // 5. Course, Academic Year, Semester, Section, Subject
    courseA = await Course.create({
      name: 'B.Tech Computer Science',
      code: 'BT-CS',
      collegeId: collegeA._id,
      departmentId: deptA._id,
      durationYears: 4,
      totalSemesters: 8,
      status: 'ACTIVE',
      isActive: true,
    });

    acadYearA = await AcademicYear.create({
      name: '2026-2027',
      code: 'AY-2026-27',
      collegeId: collegeA._id,
      startDate: new Date('2026-06-01'),
      endDate: new Date('2027-05-31'),
      isCurrent: true,
      isActive: true,
    });

    semesterA = await Semester.create({
      name: 'Semester 5',
      number: 5,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: acadYearA._id,
      isCurrent: true,
      isActive: true,
    });

    sectionA = await Section.create({
      name: 'Section A',
      code: 'SEC-A',
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      semesterId: semesterA._id,
      capacity: 60,
      isActive: true,
    });

    subjectA = await Subject.create({
      name: 'Distributed Systems',
      code: 'CS501',
      collegeId: collegeA._id,
      courseId: courseA._id,
      semesterId: semesterA._id,
      departmentId: deptA._id,
      credits: 4,
      type: 'THEORY',
      isActive: true,
    });
  });

  describe('Part 2 - Part 6: HOD Management & Integrity', () => {
    it('allows Super Admin and College Admin to provision HOD with valid User and Department', async () => {
      const res = await request(app)
        .post('/api/v1/academics/hods')
        .set('Authorization', `Bearer ${collegeAdminTokenA}`)
        .send({
          departmentId: deptA._id.toString(),
          name: 'Dr. Alan Turing',
          instituteId: 'HOD-CSE-01',
          email: 'turing@coea.edu',
          phone: '9988776600',
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.user.role).toBe(AppRole.HOD);
      expect(res.body.data.user.departmentId).toBe(deptA._id.toString());
      expect(res.body.data.activationCode).toBeDefined();

      // Verify department now references the HOD
      const updatedDept = await Department.findById(deptA._id);
      expect(updatedDept?.hodId?.toString()).toBe(res.body.data.user._id.toString());
    });

    it('prevents College Admin from provisioning or assigning HOD outside their own college', async () => {
      // College Admin A attempts to assign HOD in College B's department
      const res = await request(app)
        .post('/api/v1/academics/hods')
        .set('Authorization', `Bearer ${collegeAdminTokenA}`)
        .send({
          departmentId: deptB._id.toString(),
          name: 'Intruder HOD',
          instituteId: 'HOD-INT-01',
          email: 'intruder@cotb.edu',
        });

      expect(res.status).toBe(403);
      const errorMsg = res.body.message || res.body.error?.message;
      expect(errorMsg).toMatch(/Cross-college tenant access is strictly prohibited/i);
    });

    it('prevents College Admin B from provisioning or managing HOD in College A', async () => {
      const res = await request(app)
        .post('/api/v1/academics/hods')
        .set('Authorization', `Bearer ${collegeAdminTokenB}`)
        .send({
          departmentId: deptA._id.toString(),
          name: 'College B Admin Attempt',
          instituteId: 'HOD-FAIL-01',
          email: 'b_admin@cotb.edu',
        });

      expect(res.status).toBe(403);
      const errorMsg = res.body.message || res.body.error?.message;
      expect(errorMsg).toMatch(/Cross-college tenant access is strictly prohibited/i);
    });

    it('allows assigning an existing Faculty member to HOD safely without creating a duplicate user', async () => {
      const passwordHash = await PasswordService.hashPassword('Password@123');
      const facultyUser = await User.create({
        name: 'Prof. Grace Hopper',
        email: 'grace@coea.edu',
        instituteId: 'FAC-CSE-02',
        role: AppRole.FACULTY,
        passwordHash,
        accountStatus: AccountStatus.ACTIVE,
        activationStatus: 'activated',
        collegeId: collegeA._id,
        departmentId: deptA._id,
      });

      const res = await request(app)
        .post('/api/v1/academics/hods/assign-existing')
        .set('Authorization', `Bearer ${collegeAdminTokenA}`)
        .send({
          userId: facultyUser._id.toString(),
          departmentId: deptA._id.toString(),
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.user.role).toBe(AppRole.HOD);
      expect(res.body.data.user._id.toString()).toBe(facultyUser._id.toString());

      const updatedDept = await Department.findById(deptA._id);
      expect(updatedDept?.hodId?.toString()).toBe(facultyUser._id.toString());
    });

    it('rejects HOD assignment when another user already holds the active HOD role for that department', async () => {
      const passwordHash = await PasswordService.hashPassword('Password@123');
      const existingHod = await User.create({
        name: 'Existing HOD',
        email: 'existhod@coea.edu',
        instituteId: 'HOD-EX-01',
        role: AppRole.HOD,
        passwordHash,
        accountStatus: AccountStatus.ACTIVE,
        activationStatus: 'activated',
        collegeId: collegeA._id,
        departmentId: deptA._id,
      });

      deptA.hodId = existingHod._id;
      await deptA.save();

      const candidate = await User.create({
        name: 'Candidate User',
        email: 'candidate@coea.edu',
        instituteId: 'FAC-CAND-01',
        role: AppRole.FACULTY,
        passwordHash,
        accountStatus: AccountStatus.ACTIVE,
        activationStatus: 'activated',
        collegeId: collegeA._id,
        departmentId: deptA._id,
      });

      const res = await request(app)
        .post('/api/v1/academics/hods/assign-existing')
        .set('Authorization', `Bearer ${collegeAdminTokenA}`)
        .send({
          userId: candidate._id.toString(),
          departmentId: deptA._id.toString(),
        });

      expect([400, 409]).toContain(res.status);
      const errorMsg = res.body.message || res.body.error?.message;
      expect(errorMsg).toMatch(/already has an active or pending HOD/i);
    });

    it('allows unassigning HOD role and reassigning to FACULTY while preserving history', async () => {
      const passwordHash = await PasswordService.hashPassword('Password@123');
      const hodUser = await User.create({
        name: 'Retiring HOD',
        email: 'retirehod@coea.edu',
        instituteId: 'HOD-RET-01',
        role: AppRole.HOD,
        passwordHash,
        accountStatus: AccountStatus.ACTIVE,
        activationStatus: 'activated',
        collegeId: collegeA._id,
        departmentId: deptA._id,
      });

      deptA.hodId = hodUser._id;
      await deptA.save();

      const res = await request(app)
        .post(`/api/v1/academics/hods/${hodUser._id}/unassign`)
        .set('Authorization', `Bearer ${collegeAdminTokenA}`)
        .send({ newRole: 'FACULTY' });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);

      const refreshedUser = await User.findById(hodUser._id);
      expect(refreshedUser?.role).toBe(AppRole.FACULTY);

      const refreshedDept = await Department.findById(deptA._id);
      expect(refreshedDept?.hodId).toBeNull();
    });

    it('allows updating HOD account status to DEACTIVATED and clears department hodId safely', async () => {
      const passwordHash = await PasswordService.hashPassword('Password@123');
      const hodUser = await User.create({
        name: 'Deactivatable HOD',
        email: 'deacthod@coea.edu',
        instituteId: 'HOD-DA-01',
        role: AppRole.HOD,
        passwordHash,
        accountStatus: AccountStatus.ACTIVE,
        activationStatus: 'activated',
        collegeId: collegeA._id,
        departmentId: deptA._id,
      });

      deptA.hodId = hodUser._id;
      await deptA.save();

      const res = await request(app)
        .patch(`/api/v1/academics/hods/${hodUser._id}/status`)
        .set('Authorization', `Bearer ${collegeAdminTokenA}`)
        .send({ status: 'DEACTIVATED', reason: 'Administrative leave' });

      expect(res.status).toBe(200);
      expect(res.body.data.accountStatus).toBe(AccountStatus.DEACTIVATED);

      const refreshedDept = await Department.findById(deptA._id);
      expect(refreshedDept?.hodId).toBeNull();
    });
  });

  describe('Part 10 - Part 17: Faculty Deactivation & MOHAN Bug Resolution', () => {
    it('demonstrates exact MOHAN bug resolution: deactivation cleans active assignments, vacates timetable entries, cancels substitutions, revokes sessions, and preserves historical attendance', async () => {
      const passwordHash = await PasswordService.hashPassword('Password@123');

      // 1. Create Faculty User MOHAN
      const mohanUser = await User.create({
        name: 'Mohan Kumar',
        email: 'mohan@coea.edu',
        instituteId: 'FAC-MOHAN-01',
        role: AppRole.FACULTY,
        passwordHash,
        accountStatus: AccountStatus.ACTIVE,
        activationStatus: 'activated',
        collegeId: collegeA._id,
        departmentId: deptA._id,
      });

      // 2. Create Faculty Profile
      const mohanFaculty = await Faculty.create({
        userId: mohanUser._id,
        collegeId: collegeA._id,
        departmentId: deptA._id,
        name: mohanUser.name,
        employeeId: 'EMP-MOHAN',
        instituteId: mohanUser.instituteId,
        email: mohanUser.email,
        phone: '9988112233',
        isActive: true,
        status: 'active',
      });

      // 3. Create active FacultyAssignment referencing MOHAN
      const assignment = await FacultyAssignment.create({
        collegeId: collegeA._id,
        departmentId: deptA._id,
        academicYearId: acadYearA._id,
        courseId: courseA._id,
        semesterId: semesterA._id,
        sectionId: sectionA._id,
        subjectId: subjectA._id,
        facultyId: mohanFaculty._id,
        facultyName: mohanUser.name,
        role: 'PRIMARY',
        status: 'ACTIVE',
        isActive: true,
      });

      // 4. Create Timetable referencing MOHAN
      const timetable = await Timetable.create({
        name: 'CSE Sec A Timetable',
        collegeId: collegeA._id,
        departmentId: deptA._id,
        courseId: courseA._id,
        academicYearId: acadYearA._id,
        semesterId: semesterA._id,
        sectionId: sectionA._id,
        status: TimetableStatus.PUBLISHED,
        effectiveStartDate: new Date('2026-06-01'),
        entries: [
          {
            dayOfWeek: TimetableDay.MONDAY,
            startTime: '09:00',
            endTime: '10:00',
            subjectId: subjectA._id,
            facultyAssignmentId: assignment._id,
            facultyId: mohanFaculty._id,
            sessionType: TimetableSessionType.LECTURE,
          },
        ],
      });

      // 5. Create Future TeacherSubstitution
      const futureDate = new Date();
      futureDate.setDate(futureDate.getDate() + 7);
      const futureDateStr = futureDate.toISOString().slice(0, 10);
      const substitution = await TeacherSubstitution.create({
        collegeId: collegeA._id,
        departmentId: deptA._id,
        sectionId: sectionA._id,
        timetableId: timetable._id,
        timetableEntryId: timetable.entries[0]._id,
        date: futureDateStr,
        originalFacultyId: mohanFaculty._id,
        substituteFacultyId: mohanFaculty._id,
        reason: 'Faculty Conference',
        status: TeacherSubstitutionStatus.ACTIVE,
        createdBy: collegeAdminUserA._id,
      });

      // 6. Create Historical Attendance (Must be preserved!)
      const pastDate = new Date();
      pastDate.setDate(pastDate.getDate() - 10);
      const testStudentId = new mongoose.Types.ObjectId();
      const histSession = await AttendanceSession.create({
        collegeId: collegeA._id,
        departmentId: deptA._id,
        academicYearId: acadYearA._id,
        semesterId: semesterA._id,
        sectionId: sectionA._id,
        sectionName: 'Section A',
        subjectId: subjectA._id,
        subjectName: 'Distributed Systems',
        facultyId: mohanFaculty._id,
        facultyAssignmentId: assignment._id,
        timeSlot: '09:00 - 10:00',
        date: pastDate,
        status: AttendanceSessionStatus.LOCKED,
        records: [
          {
            studentId: testStudentId,
            studentName: 'Test Student',
            rollNumber: 'ROLL-01',
            sectionId: sectionA._id,
            status: AttendanceStatus.PRESENT,
          },
        ],
      });

      const histRecord = await AttendanceRecord.create({
        collegeId: collegeA._id,
        departmentId: deptA._id,
        sessionId: histSession._id,
        studentId: testStudentId,
        studentName: 'Test Student',
        rollNumber: 'ROLL-01',
        sectionId: sectionA._id,
        subjectId: subjectA._id,
        facultyId: mohanFaculty._id,
        date: pastDate,
        timeSlot: '09:00 - 10:00',
        status: AttendanceStatus.PRESENT,
      });

      // 7. Create Active AuthSession for MOHAN
      const activeSession = await AuthSession.create({
        sessionId: 'sess_mohan_123',
        userId: mohanUser._id,
        refreshTokenHash: 'hash_123',
        expiresAt: new Date(Date.now() + 86400000),
      });

      // --- BEFORE CHECK ---
      // MOHAN appears in active faculty listing
      const beforeListRes = await request(app)
        .get('/api/v1/academics/faculty')
        .set('Authorization', `Bearer ${collegeAdminTokenA}`);
      expect(beforeListRes.status).toBe(200);
      const beforeItems = beforeListRes.body.data.items || beforeListRes.body.data;
      const beforeMohan = beforeItems.find((item: any) =>
        (item.user?.id || item.user?._id) === mohanUser._id.toString() ||
        (item.faculty?.id || item.faculty?._id) === mohanFaculty._id.toString()
      );
      expect(beforeMohan).toBeDefined();

      // --- DEACTIVATE MOHAN SAFELY ---
      const deactivateRes = await request(app)
        .post(`/api/v1/users/${mohanUser._id}/deactivate`)
        .set('Authorization', `Bearer ${collegeAdminTokenA}`)
        .send({ reason: 'Faculty resigned' });

      expect(deactivateRes.status).toBe(200);
      expect(deactivateRes.body.success).toBe(true);

      // --- AFTER CHECKS ---
      // 1. User accountStatus is DEACTIVATED
      const refreshedMohanUser = await User.findById(mohanUser._id);
      expect(refreshedMohanUser?.accountStatus).toBe(AccountStatus.DEACTIVATED);

      // 2. Faculty profile is deactivated
      const refreshedMohanFaculty = await Faculty.findById(mohanFaculty._id);
      expect(refreshedMohanFaculty?.isActive).toBe(false);
      expect(refreshedMohanFaculty?.status).toBe('inactive');

      // 3. FacultyAssignment is deactivated
      const refreshedAssignment = await FacultyAssignment.findById(assignment._id);
      expect(refreshedAssignment?.isActive).toBe(false);

      // 4. Timetable entries referencing MOHAN are removed/vacated
      const refreshedTimetable = await Timetable.findById(timetable._id);
      expect(refreshedTimetable?.entries.some((e: any) => e.facultyId?.toString() === mohanFaculty._id.toString())).toBe(false);

      // 5. Future substitution is cancelled
      const refreshedSub = await TeacherSubstitution.findById(substitution._id);
      expect(refreshedSub?.status).toBe('CANCELLED');

      // 6. Active AuthSession is revoked
      const refreshedAuthSession = await AuthSession.findById(activeSession._id);
      expect(refreshedAuthSession?.revokedAt).toBeDefined();

      // 7. MOHAN is excluded from active faculty selectors
      const afterListRes = await request(app)
        .get('/api/v1/academics/faculty')
        .set('Authorization', `Bearer ${collegeAdminTokenA}`);
      expect(afterListRes.status).toBe(200);
      const afterItems = afterListRes.body.data.items || afterListRes.body.data;
      const afterMohan = afterItems.find((item: any) =>
        (item.user?.id || item.user?._id) === mohanUser._id.toString() ||
        (item.faculty?.id || item.faculty?._id) === mohanFaculty._id.toString()
      );
      expect(afterMohan).toBeUndefined();

      // 8. Historical attendance session & record are completely preserved!
      const preservedSession = await AttendanceSession.findById(histSession._id);
      expect(preservedSession).toBeDefined();
      expect(preservedSession?.facultyId?.toString()).toBe(mohanFaculty._id.toString());

      const preservedRecord = await AttendanceRecord.findById(histRecord._id);
      expect(preservedRecord).toBeDefined();

      // 9. Hard deletion of MOHAN is safely rejected because historical attendance exists
      const deleteRes = await request(app)
        .delete(`/api/v1/users/${mohanUser._id}`)
        .set('Authorization', `Bearer ${superAdminToken}`);

      expect(deleteRes.status).toBe(400);
      const deleteErrorMsg = deleteRes.body.message || deleteRes.body.error?.message;
      expect(deleteErrorMsg).toMatch(/You cannot delete this faculty because historical attendance exists/i);
    });
  });

  describe('Part 19: Forensic Orphan Detection & Integrity Audit', () => {
    it('returns zero orphans on clean test fixtures and detects active counts correctly', async () => {
      const res = await request(app)
        .get('/api/v1/academics/integrity/audit')
        .set('Authorization', `Bearer ${superAdminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.totalOrphansDetected).toBe(0);
      expect(res.body.data.counts.activeCourses).toBeGreaterThanOrEqual(1);
      expect(res.body.data.counts.activeSemesters).toBeGreaterThanOrEqual(1);
      expect(res.body.data.counts.activeSubjects).toBeGreaterThanOrEqual(1);
    });

    it('detects orphaned records if an academic entity references a nonexistent parent', async () => {
      // Intentionally insert an orphaned subject pointing to a non-existent semester
      const nonExistentSemesterId = new mongoose.Types.ObjectId();
      await Subject.create({
        name: 'Orphan Subject',
        code: 'ORPH101',
        collegeId: collegeA._id,
        courseId: courseA._id,
        semesterId: nonExistentSemesterId,
        departmentId: deptA._id,
        credits: 3,
        type: 'THEORY',
        isActive: true,
      });

      const res = await request(app)
        .get('/api/v1/academics/integrity/audit')
        .set('Authorization', `Bearer ${superAdminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.data.totalOrphansDetected).toBeGreaterThanOrEqual(1);
      expect(res.body.data.orphans.subjectsWithoutSemester.length).toBeGreaterThanOrEqual(1);
      expect(res.body.data.orphans.subjectsWithoutSemester[0].subjectId).toBeDefined();

      // Test repair endpoint
      const repairRes = await request(app)
        .post('/api/v1/academics/integrity/repair')
        .set('Authorization', `Bearer ${superAdminToken}`)
        .send({ safeRepair: true });

      expect(repairRes.status).toBe(200);
      expect(repairRes.body.data.repairedCount).toBeGreaterThanOrEqual(1);

      // Verify the orphan subject was deactivated safely
      const checkSubject = await Subject.findOne({ code: 'ORPH101' });
      expect(checkSubject?.isActive).toBe(false);
    });
  });
});
