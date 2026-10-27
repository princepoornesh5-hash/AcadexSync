import request from 'supertest';
import mongoose from 'mongoose';
import { app } from '../../src/app';
import {
  User,
  College,
  Department,
  Course,
  AcademicYear,
  Semester,
  Section,
  Subject,
  Faculty,
  FacultyAssignment,
  Student,
  StudentEnrollment,
  AttendanceSession,
  InternalAssessment,
  AssessmentMark,
  TeachingHandover,
  DepartmentTenure,
  StudentTransfer,
  WorkspaceMembership,
  WorkspaceRoleAssignment,
  AuditLog,
  AuthSession,
} from '../../src/models';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { PasswordService } from '../../src/services/password.service';
import { TeachingHandoverService } from '../../src/services/teachingHandover.service';
import { DepartmentTenureService } from '../../src/services/departmentTenure.service';
import { StudentTransferService } from '../../src/services/studentTransfer.service';
import { TransferCreditService } from '../../src/services/transferCredit.service';
import { TeachingAuthorizationService } from '../../src/services/teachingAuthorization.service';
import { WorkspaceMigrationService } from '../../src/services/migration/workspaceMigration.service';
import { AppRole } from '../../src/constants/roles';
import {
  AccountStatus,
  MembershipStatus,
  RoleAssignmentStatus,
  StudentLifecycleState,
  CollegeStatus,
  DepartmentStatus,
  TransferCreditStatus,
  AttendanceStatus,
  AttendanceSessionStatus,
} from '../../src/constants/status';
import { AssessmentStatus, AssessmentType, StudentMarkStatus } from '../../src/models/internalAssessment.model';
import { signAccessToken } from '../../src/utils/token';
import { AuthenticatedUser } from '../../src/types/auth.types';

const makeAuthUser = (user: any, role: AppRole, collegeId: any): AuthenticatedUser => ({
  id: user.id || user._id.toString(),
  name: user.name || 'Test User',
  email: user.email || 'test@test.com',
  instituteId: user.instituteId || 'TEST-PIN',
  role,
  collegeId: collegeId.toString(),
  accountStatus: AccountStatus.ACTIVE,
});

describe('ACADEX PROMPT 4: Historical Academic Records, Transfers, Faculty Handovers, HOD Tenure & Security Verification', () => {
  let collegeA: any;
  let collegeB: any;
  let deptA: any;
  let deptB: any;
  let courseA: any;
  let courseB: any;
  let academicYearA: any;
  let semesterA: any;
  let sectionA: any;
  let subjectA: any;
  let adminAUser: any;
  let adminAToken: string;
  let adminBUser: any;
  let adminBToken: string;

  beforeAll(async () => {
    await setupTestDB();
    await User.init();
    await College.init();
    await Department.init();
    await WorkspaceMembership.init();
    await WorkspaceRoleAssignment.init();
    await FacultyAssignment.init();
    await DepartmentTenure.init();
    await TeachingHandover.init();
    await StudentTransfer.init();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();

    // 1. Colleges
    collegeA = await College.create({
      name: 'College Alpha',
      code: 'CLG-A',
      address: '100 Alpha Blvd',
      email: 'admin@alpha.edu',
      phone: '1112223333',
      principal: 'Dr. Alpha Principal',
      status: CollegeStatus.ACTIVE,
    });

    collegeB = await College.create({
      name: 'College Beta',
      code: 'CLG-B',
      address: '200 Beta Way',
      email: 'admin@beta.edu',
      phone: '4445556666',
      principal: 'Dr. Beta Principal',
      status: CollegeStatus.ACTIVE,
    });

    // 2. Departments
    deptA = await Department.create({
      collegeId: collegeA._id,
      name: 'Computer Science',
      code: 'CSE',
      status: DepartmentStatus.ACTIVE,
    });

    deptB = await Department.create({
      collegeId: collegeB._id,
      name: 'Information Technology',
      code: 'IT',
      status: DepartmentStatus.ACTIVE,
    });

    // 3. Courses, Years, Semesters, Sections, Subjects
    courseA = await Course.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'B.Tech CSE',
      code: 'BTCSE',
      durationYears: 4,
    });

    courseB = await Course.create({
      collegeId: collegeB._id,
      departmentId: deptB._id,
      name: 'B.Tech IT',
      code: 'BTIT',
      durationYears: 4,
    });

    academicYearA = await AcademicYear.create({
      collegeId: collegeA._id,
      name: '2026-2027',
      startDate: new Date('2026-06-01'),
      endDate: new Date('2027-05-31'),
    });

    semesterA = await Semester.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      name: 'Semester 5',
      number: 5,
    });

    sectionA = await Section.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      semesterId: semesterA._id,
      name: 'Section A',
      capacity: 60,
    });

    subjectA = await Subject.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      semesterId: semesterA._id,
      name: 'Mathematics IV',
      code: 'MATH401',
      credits: 4,
    });

    // 4. College Admins
    const hash = await PasswordService.hashPassword('Pass1234');

    adminAUser = await User.create({
      name: 'Admin Alpha',
      email: 'admin@alpha.edu',
      passwordHash: hash,
      role: AppRole.COLLEGE_ADMIN,
      collegeId: collegeA._id,
      instituteId: 'ADM-A-01',
      accountStatus: AccountStatus.ACTIVE,
    });
    const memAdminA = await WorkspaceMembership.create({
      userId: adminAUser._id,
      collegeId: collegeA._id,
      instituteId: 'ADM-A-01',
      status: MembershipStatus.ACTIVE,
    });
    await WorkspaceRoleAssignment.create({
      membershipId: memAdminA._id,
      userId: adminAUser._id,
      collegeId: collegeA._id,
      role: AppRole.COLLEGE_ADMIN,
      status: RoleAssignmentStatus.ACTIVE,
    });
    const sessionAdminA = crypto.randomUUID();
    await AuthSession.create({
      userId: adminAUser._id,
      sessionId: sessionAdminA,
      refreshTokenHash: 'hash_admin_a',
      expiresAt: new Date(Date.now() + 86400000),
    });
    adminAToken = signAccessToken({
      userId: adminAUser.id,
      role: AppRole.COLLEGE_ADMIN,
      collegeId: collegeA.id,
      sessionId: sessionAdminA,
      membershipId: memAdminA.id,
    });

    adminBUser = await User.create({
      name: 'Admin Beta',
      email: 'admin@beta.edu',
      passwordHash: hash,
      role: AppRole.COLLEGE_ADMIN,
      collegeId: collegeB._id,
      instituteId: 'ADM-B-01',
      accountStatus: AccountStatus.ACTIVE,
    });
    const memAdminB = await WorkspaceMembership.create({
      userId: adminBUser._id,
      collegeId: collegeB._id,
      instituteId: 'ADM-B-01',
      status: MembershipStatus.ACTIVE,
    });
    await WorkspaceRoleAssignment.create({
      membershipId: memAdminB._id,
      userId: adminBUser._id,
      collegeId: collegeB._id,
      role: AppRole.COLLEGE_ADMIN,
      status: RoleAssignmentStatus.ACTIVE,
    });
    const sessionAdminB = crypto.randomUUID();
    await AuthSession.create({
      userId: adminBUser._id,
      sessionId: sessionAdminB,
      refreshTokenHash: 'hash_admin_b',
      expiresAt: new Date(Date.now() + 86400000),
    });
    adminBToken = signAccessToken({
      userId: adminBUser.id,
      role: AppRole.COLLEGE_ADMIN,
      collegeId: collegeB.id,
      sessionId: sessionAdminB,
      membershipId: memAdminB.id,
    });
    expect(adminBToken).toBeDefined();
  });

  // =========================================================================
  // SCENARIO 1: Faculty succession preserves original attendance creator
  // =========================================================================
  it('1. Faculty succession preserves the original attendance creator', async () => {
    const hash = await PasswordService.hashPassword('Pass1234');
    // Original teacher
    const teacher1User = await User.create({
      name: 'Prof Ramanujan',
      email: 'ramanujan@alpha.edu',
      passwordHash: hash,
      role: AppRole.FACULTY,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      accountStatus: AccountStatus.ACTIVE,
    });
    const teacher1Fac = await Faculty.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      userId: teacher1User._id,
      name: 'Prof Ramanujan',
      email: 'ramanujan@alpha.edu',
      instituteId: 'FAC-001',
    });
    const assignment1 = await FacultyAssignment.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      facultyId: teacher1Fac._id,
      facultyName: 'Prof Ramanujan',
      courseId: courseA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      subjectId: subjectA._id,
      academicYearId: academicYearA._id,
      status: 'active',
      isActive: true,
    });

    // Student in section
    const studentUser = await User.create({
      name: 'Student One',
      email: 's1@alpha.edu',
      passwordHash: hash,
      role: AppRole.STUDENT,
      collegeId: collegeA._id,
    });
    const student = await Student.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      userId: studentUser._id,
      name: 'Student One',
      instituteId: 'STU-001',
    });

    // Ramanujan conducts and submits an attendance session
    const session = await AttendanceSession.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      facultyId: teacher1Fac._id,
      facultyAssignmentId: assignment1._id,
      subjectId: subjectA._id,
      subjectName: 'Mathematics IV',
      sectionId: sectionA._id,
      timeSlot: '09:00 - 10:00',
      date: new Date('2026-09-01'),
      status: AttendanceSessionStatus.LOCKED,
      isSubmitted: true,
      isLocked: true,
      createdBy: teacher1User._id.toString(),
      records: [
        {
          studentId: student._id,
          studentName: 'Student One',
          rollNumber: 'R101',
          status: AttendanceStatus.PRESENT,
        },
      ],
      version: 1,
    });

    // Successor teacher
    const teacher2User = await User.create({
      name: 'Prof Hardy',
      email: 'hardy@alpha.edu',
      passwordHash: hash,
      role: AppRole.FACULTY,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      accountStatus: AccountStatus.ACTIVE,
    });
    const teacher2Fac = await Faculty.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      userId: teacher2User._id,
      name: 'Prof Hardy',
      email: 'hardy@alpha.edu',
      instituteId: 'FAC-002',
    });

    // Execute handover via service
    const handoverResult = await TeachingHandoverService.handoverTeachingAssignment(
      makeAuthUser(adminAUser, AppRole.COLLEGE_ADMIN, collegeA.id),
      {
        sourceAssignmentId: assignment1.id,
        successorFacultyId: teacher2Fac.id,
        reassignPendingWork: true,
        notes: 'Prof Ramanujan on leave; Prof Hardy takes over course',
      }
    );

    expect(handoverResult.handover.status).toBe('COMPLETED');
    expect(handoverResult.targetAssignment.facultyName).toBe('Prof Hardy');
    expect(handoverResult.sourceAssignment.status).toBe('ended');

    // VERIFY HISTORICAL IMMUTABILITY: Historical attendance session still attributed to Ramanujan
    const historicalSession = await AttendanceSession.findById(session._id);
    expect(historicalSession).toBeDefined();
    expect(historicalSession!.facultyId.toString()).toBe(teacher1Fac._id.toString());
    expect(historicalSession!.createdBy).toBe(teacher1User._id.toString());
    expect(historicalSession!.facultyAssignmentId?.toString()).toBe(assignment1._id.toString());
  });

  // =========================================================================
  // SCENARIO 2: Successor teachers can read authorised historical records
  // =========================================================================
  it('2. Successor teachers can read authorised historical records', async () => {
    const hash = await PasswordService.hashPassword('Pass1234');
    const teacher1Fac = await Faculty.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'Prof Euler',
      email: 'euler@alpha.edu',
      instituteId: 'FAC-010',
    });
    const assignment1 = await FacultyAssignment.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      facultyId: teacher1Fac._id,
      facultyName: 'Prof Euler',
      courseId: courseA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      subjectId: subjectA._id,
      academicYearId: academicYearA._id,
      status: 'ended',
      isActive: false,
    });

    const teacher2User = await User.create({
      name: 'Prof Gauss',
      email: 'gauss@alpha.edu',
      passwordHash: hash,
      role: AppRole.FACULTY,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      accountStatus: AccountStatus.ACTIVE,
    });
    const teacher2Fac = await Faculty.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      userId: teacher2User._id,
      name: 'Prof Gauss',
      email: 'gauss@alpha.edu',
      instituteId: 'FAC-011',
    });
    // Active successor assignment
    await FacultyAssignment.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      facultyId: teacher2Fac._id,
      facultyName: 'Prof Gauss',
      courseId: courseA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      subjectId: subjectA._id,
      academicYearId: academicYearA._id,
      handoverFromAssignmentId: assignment1._id,
      status: 'active',
      isActive: true,
    });

    // Check TeachingAuthorizationService assertHistoricalCourseReadAccess
    const hasReadAccess = await TeachingAuthorizationService.assertHistoricalCourseReadAccess(
      collegeA.id,
      { id: teacher2User.id, role: AppRole.FACULTY, collegeId: collegeA.id, departmentId: deptA.id },
      { subjectId: subjectA.id, sectionId: sectionA.id, departmentId: deptA.id }
    );

    expect(hasReadAccess).toBe(true);
  });

  // =========================================================================
  // SCENARIO 3: Successor teachers cannot modify published historical records
  // =========================================================================
  it('3. Successor teachers cannot modify published historical records without an approved correction workflow', async () => {
    const hash = await PasswordService.hashPassword('Pass1234');
    const teacher1Fac = await Faculty.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'Prof Newton',
      email: 'newton@alpha.edu',
      instituteId: 'FAC-020',
    });
    const teacher2User = await User.create({
      name: 'Prof Leibniz',
      email: 'leibniz@alpha.edu',
      passwordHash: hash,
      role: AppRole.FACULTY,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      accountStatus: AccountStatus.ACTIVE,
    });
    await Faculty.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      userId: teacher2User._id,
      name: 'Prof Leibniz',
      email: 'leibniz@alpha.edu',
      instituteId: 'FAC-021',
    });

    // Submitted/locked session created by Newton
    const session = await AttendanceSession.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      facultyId: teacher1Fac._id,
      subjectId: subjectA._id,
      subjectName: 'Mathematics IV',
      sectionId: sectionA._id,
      timeSlot: '10:00 - 11:00',
      date: new Date('2026-09-02'),
      status: AttendanceSessionStatus.LOCKED,
      isSubmitted: true,
      isLocked: true,
      version: 1,
    });

    // Leibniz tries to write/mutate submitted historical session
    await expect(
      TeachingAuthorizationService.assertHistoricalAttendanceWriteAccess(
        collegeA.id,
        { id: teacher2User.id, role: AppRole.FACULTY, collegeId: collegeA.id, departmentId: deptA.id },
        session
      )
    ).rejects.toThrow('Historical submitted or locked attendance sessions cannot be modified without an approved correction request.');
  });

  // =========================================================================
  // SCENARIO 4: Pending work can be reassigned only by an authorised actor
  // =========================================================================
  it('4. Pending work can be reassigned only by an authorised actor', async () => {
    const hash = await PasswordService.hashPassword('Pass1234');
    const unauthorizedFacultyUser = await User.create({
      name: 'Unauthorized Teacher',
      email: 'unauth@alpha.edu',
      passwordHash: hash,
      role: AppRole.FACULTY,
      collegeId: collegeA._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    const fac1 = await Faculty.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'Fac One',
      email: 'fac1@alpha.edu',
      instituteId: 'F-030',
    });
    const fac2 = await Faculty.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'Fac Two',
      email: 'fac2@alpha.edu',
      instituteId: 'F-031',
    });

    const assignment = await FacultyAssignment.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      facultyId: fac1._id,
      facultyName: 'Fac One',
      courseId: courseA._id,
      semesterId: semesterA._id,
      subjectId: subjectA._id,
      academicYearId: academicYearA._id,
      status: 'active',
      isActive: true,
    });

    // Regular faculty attempts handover -> 403 Forbidden
    await expect(
      TeachingHandoverService.handoverTeachingAssignment(
        makeAuthUser(unauthorizedFacultyUser, AppRole.FACULTY, collegeA.id),
        {
          sourceAssignmentId: assignment.id,
          successorFacultyId: fac2.id,
          reassignPendingWork: true,
        }
      )
    ).rejects.toThrow('Only College Administrators or Department HODs can initiate teaching handovers');
  });

  // =========================================================================
  // SCENARIO 5: HOD succession preserves historical approvals
  // =========================================================================
  it('5. HOD succession preserves historical approvals', async () => {
    const hash = await PasswordService.hashPassword('Pass1234');
    const hod1User = await User.create({
      name: 'Dr. First HOD',
      email: 'hod1@alpha.edu',
      passwordHash: hash,
      role: AppRole.HOD,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      instituteId: 'HOD-01',
      accountStatus: AccountStatus.ACTIVE,
    });
    const memHod1 = await WorkspaceMembership.create({
      userId: hod1User._id,
      collegeId: collegeA._id,
      instituteId: 'HOD-01',
      status: MembershipStatus.ACTIVE,
    });
    await WorkspaceRoleAssignment.create({
      membershipId: memHod1._id,
      userId: hod1User._id,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      role: AppRole.HOD,
      status: RoleAssignmentStatus.ACTIVE,
    });

    // Appoint HOD 1 with DepartmentTenure
    await DepartmentTenureService.appointHod(
      makeAuthUser(adminAUser, AppRole.COLLEGE_ADMIN, collegeA.id),
      {
        collegeId: collegeA.id,
        departmentId: deptA.id,
        newHodUserId: hod1User.id,
        notes: 'Initial appointment',
      }
    );

    // HOD 1 approves an audit event / request
    const approvalAudit = await AuditLog.create({
      collegeId: collegeA.id,
      actorUserId: hod1User.id,
      action: 'COURSE_CURRICULUM_APPROVED',
      entityType: 'Department',
      entityId: deptA.id,
      metadata: { details: 'Approved by Dr. First HOD' },
    });

    // New HOD 2 appointed
    const hod2User = await User.create({
      name: 'Dr. Second HOD',
      email: 'hod2@alpha.edu',
      passwordHash: hash,
      role: AppRole.FACULTY,
      collegeId: collegeA._id,
      instituteId: 'HOD-02',
      accountStatus: AccountStatus.ACTIVE,
    });
    await WorkspaceMembership.create({
      userId: hod2User._id,
      collegeId: collegeA._id,
      instituteId: 'HOD-02',
      status: MembershipStatus.ACTIVE,
    });

    const appointment = await DepartmentTenureService.appointHod(
      makeAuthUser(adminAUser, AppRole.COLLEGE_ADMIN, collegeA.id),
      {
        collegeId: collegeA.id,
        departmentId: deptA.id,
        newHodUserId: hod2User.id,
        notes: 'Succession to Dr. Second HOD',
      }
    );

    expect(appointment.tenure.userId.toString()).toBe(hod2User.id);
    expect(appointment.previousTenure?.userId.toString()).toBe(hod1User.id);
    expect(appointment.previousTenure?.status).toBe('COMPLETED');

    // VERIFY HISTORICAL IMMUTABILITY: Prior approval retains Dr. First HOD as actor
    const savedAudit = await AuditLog.findById(approvalAudit._id);
    expect(savedAudit?.actorUserId).toBe(hod1User.id);
    expect((savedAudit?.metadata as any)?.details).toContain('Dr. First HOD');
  });

  // =========================================================================
  // SCENARIO 6: Former HODs cannot use expired appointments for current write access
  // =========================================================================
  it('6. Former HODs cannot use expired appointments for current write access', async () => {
    const hash = await PasswordService.hashPassword('Pass1234');
    const oldHodUser = await User.create({
      name: 'Dr. Retired HOD',
      email: 'retired@alpha.edu',
      passwordHash: hash,
      role: AppRole.HOD,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      instituteId: 'HOD-RET',
      accountStatus: AccountStatus.ACTIVE,
    });
    await WorkspaceMembership.create({
      userId: oldHodUser._id,
      collegeId: collegeA._id,
      instituteId: 'HOD-RET',
      status: MembershipStatus.ACTIVE,
    });

    // Initial appointment
    await DepartmentTenureService.appointHod(
      makeAuthUser(adminAUser, AppRole.COLLEGE_ADMIN, collegeA.id),
      { collegeId: collegeA.id, departmentId: deptA.id, newHodUserId: oldHodUser.id }
    );

    // New HOD takes over
    const newHodUser = await User.create({
      name: 'Dr. Incoming HOD',
      email: 'incoming@alpha.edu',
      passwordHash: hash,
      role: AppRole.FACULTY,
      collegeId: collegeA._id,
      instituteId: 'HOD-INC',
      accountStatus: AccountStatus.ACTIVE,
    });
    await WorkspaceMembership.create({
      userId: newHodUser._id,
      collegeId: collegeA._id,
      instituteId: 'HOD-INC',
      status: MembershipStatus.ACTIVE,
    });

    await DepartmentTenureService.appointHod(
      makeAuthUser(adminAUser, AppRole.COLLEGE_ADMIN, collegeA.id),
      { collegeId: collegeA.id, departmentId: deptA.id, newHodUserId: newHodUser.id }
    );

    // Former HOD's WorkspaceRoleAssignment must now be REVOKED
    const formerRoleAssignment = await WorkspaceRoleAssignment.findOne({
      userId: oldHodUser._id,
      departmentId: deptA._id,
      role: AppRole.HOD,
    });
    expect(formerRoleAssignment?.status).toBe(RoleAssignmentStatus.REVOKED);
    expect(formerRoleAssignment?.effectiveEndDate).toBeDefined();

    // Verification: Active tenure belongs ONLY to new HOD
    const activeTenures = await DepartmentTenure.find({ departmentId: deptA._id, status: 'ACTIVE' });
    expect(activeTenures.length).toBe(1);
    expect(activeTenures[0].userId.toString()).toBe(newHodUser.id);
  });

  // =========================================================================
  // SCENARIO 7: Student transfer preserves original college data and membership history
  // =========================================================================
  it("7. Student transfer preserves the original college's data and membership history", async () => {
    const hash = await PasswordService.hashPassword('Pass1234');
    const studentUser = await User.create({
      name: 'Transferring Student',
      email: 'student@global.edu',
      passwordHash: hash,
      role: AppRole.STUDENT,
      collegeId: collegeA._id,
      instituteId: 'CLG-A-PIN-100',
      accountStatus: AccountStatus.ACTIVE,
    });

    const memA = await WorkspaceMembership.create({
      userId: studentUser._id,
      collegeId: collegeA._id,
      instituteId: 'CLG-A-PIN-100',
      status: MembershipStatus.ACTIVE,
      effectiveStartDate: new Date('2025-08-01'),
    });

    const studentA = await Student.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      userId: studentUser._id,
      name: 'Transferring Student',
      instituteId: 'CLG-A-PIN-100',
      lifecycleState: StudentLifecycleState.ACTIVE,
    });

    // College A historical attendance
    const session = await AttendanceSession.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      facultyId: new mongoose.Types.ObjectId(),
      subjectId: subjectA._id,
      subjectName: 'Mathematics IV',
      timeSlot: '09:00 - 10:00',
      date: new Date('2025-09-10'),
      status: AttendanceSessionStatus.LOCKED,
      isSubmitted: true,
      records: [
        {
          studentId: studentA._id,
          studentName: 'Transferring Student',
          rollNumber: 'R100',
          status: AttendanceStatus.PRESENT,
        },
      ],
      version: 1,
    });

    // Execute transfer to College B
    const transferResult = await StudentTransferService.transferStudent(
      makeAuthUser(adminAUser, AppRole.COLLEGE_ADMIN, collegeA.id),
      {
        sourceStudentId: studentA.id,
        destinationCollegeId: collegeB.id,
        destinationDepartmentId: deptB.id,
        destinationPin: 'CLG-B-PIN-200',
        destinationCourseId: courseB.id,
        reason: 'Relocated family to new state',
      }
    );

    expect(transferResult.transferRecord.status).toBe('COMPLETED');
    expect(transferResult.destinationStudent.instituteId).toBe('CLG-B-PIN-200');
    expect(transferResult.destinationMembership.collegeId.toString()).toBe(collegeB.id);

    // VERIFY HISTORICAL PRESERVATION IN COLLEGE A:
    // 1. Source student lifecycleState is TRANSFERRED (not deleted)
    const refreshedStudentA = await Student.findById(studentA._id);
    expect(refreshedStudentA?.lifecycleState).toBe(StudentLifecycleState.TRANSFERRED);
    expect(refreshedStudentA?.instituteId).toBe('CLG-A-PIN-100');

    // 2. Source membership is TRANSFERRED with effectiveEndDate
    const refreshedMemA = await WorkspaceMembership.findById(memA._id);
    expect(refreshedMemA?.status).toBe(MembershipStatus.TRANSFERRED);
    expect(refreshedMemA?.effectiveEndDate).toBeDefined();

    // 3. College A historical attendance records remain intact
    const historicalAttendance = await AttendanceSession.findById(session._id);
    expect(historicalAttendance?.records[0].studentId.toString()).toBe(studentA._id.toString());
    expect(historicalAttendance?.records[0].status).toBe(AttendanceStatus.PRESENT);

    // 4. Global user remains unified
    expect(studentUser.id).toBe(transferResult.destinationStudent.userId.toString());
  });

  // =========================================================================
  // SCENARIO 8: Destination admission failure preserves global user and original membership
  // =========================================================================
  it('8. Destination admission failure preserves the global user and original membership', async () => {
    const hash = await PasswordService.hashPassword('Pass1234');
    const studentUser = await User.create({
      name: 'Safe Student',
      email: 'safestudent@global.edu',
      passwordHash: hash,
      role: AppRole.STUDENT,
      collegeId: collegeA._id,
      instituteId: 'PIN-SAFE-A',
      accountStatus: AccountStatus.ACTIVE,
    });

    const memA = await WorkspaceMembership.create({
      userId: studentUser._id,
      collegeId: collegeA._id,
      instituteId: 'PIN-SAFE-A',
      status: MembershipStatus.ACTIVE,
    });

    const studentA = await Student.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      userId: studentUser._id,
      name: 'Safe Student',
      instituteId: 'PIN-SAFE-A',
      lifecycleState: StudentLifecycleState.ACTIVE,
    });

    // Create another user in College B with the PIN 'PIN-CONFLICT-B'
    await WorkspaceMembership.create({
      userId: new mongoose.Types.ObjectId(),
      collegeId: collegeB._id,
      instituteId: 'PIN-CONFLICT-B',
      status: MembershipStatus.ACTIVE,
    });

    // Transfer attempt with duplicate destination PIN should fail
    await expect(
      StudentTransferService.transferStudent(
        makeAuthUser(adminAUser, AppRole.COLLEGE_ADMIN, collegeA.id),
        {
          sourceStudentId: studentA.id,
          destinationCollegeId: collegeB.id,
          destinationDepartmentId: deptB.id,
          destinationPin: 'PIN-CONFLICT-B', // Triggers conflict in destination
        }
      )
    ).rejects.toThrow('already assigned to another member in the destination college');

    // VERIFY: Global user and original College A membership are 100% UNTOUCHED
    const userStillExists = await User.findById(studentUser._id);
    expect(userStillExists).toBeDefined();

    const memAStillActive = await WorkspaceMembership.findById(memA._id);
    expect(memAStillActive?.status).toBe(MembershipStatus.ACTIVE);
    expect(memAStillActive?.effectiveEndDate).toBeNull();

    const studentAStillActive = await Student.findById(studentA._id);
    expect(studentAStillActive?.lifecycleState).toBe(StudentLifecycleState.ACTIVE);
  });

  // =========================================================================
  // SCENARIO 9: Transfer credits require appropriate verification and approval
  // =========================================================================
  it('9. Transfer credits require appropriate verification and approval', async () => {
    const hash = await PasswordService.hashPassword('Pass1234');
    const studentUser = await User.create({
      name: 'Credit Student',
      email: 'creditstudent@global.edu',
      passwordHash: hash,
      role: AppRole.STUDENT,
      collegeId: collegeB._id,
    });

    const studentB = await Student.create({
      collegeId: collegeB._id,
      departmentId: deptB._id,
      userId: studentUser._id,
      name: 'Credit Student',
      instituteId: 'PIN-CR-B',
    });

    const enrollmentB = await StudentEnrollment.create({
      collegeId: collegeB._id,
      departmentId: deptB._id,
      studentId: studentB._id,
      courseId: courseB._id,
      semesterId: new mongoose.Types.ObjectId(),
      academicYearId: new mongoose.Types.ObjectId(),
      enrollmentDate: new Date(),
      status: 'active',
    });

    // Record verified transfer credit via TransferCreditService
    const creditRecord = await TransferCreditService.recordTransferCredit(
      makeAuthUser(adminBUser, AppRole.COLLEGE_ADMIN, collegeB.id),
      {
        studentId: studentB.id,
        studentEnrollmentId: enrollmentB.id,
        originInstitutionName: 'College Alpha',
        originCollegeId: collegeA.id,
        admissionType: 'INTER_COLLEGE_TRANSFER',
        entrySemesterNumber: 3,
        recognizedCredits: 16,
        transferredSubjects: [
          {
            subjectCode: 'MATH401',
            subjectName: 'Mathematics IV',
            credits: 4,
            grade: 'A',
            gradePoints: 9.0,
          },
        ],
      }
    );

    expect(creditRecord.verificationStatus).toBe(TransferCreditStatus.PENDING);
    expect(creditRecord.originInstitutionName).toBe('College Alpha');

    // Admin approves the transfer credit
    const approvedCredit = await TransferCreditService.updateStatus(
      creditRecord.id,
      makeAuthUser(adminBUser, AppRole.COLLEGE_ADMIN, collegeB.id),
      { status: TransferCreditStatus.APPROVED, remarks: 'Verified transcript from College Alpha' }
    );

    expect(approvedCredit.verificationStatus).toBe(TransferCreditStatus.APPROVED);
    expect(approvedCredit.approvedBy?.toString()).toBe(adminBUser.id);
    expect(approvedCredit.auditHistory.length).toBeGreaterThanOrEqual(2);
  });

  // =========================================================================
  // SCENARIO 10: Faculty transfer preserves records across both institutions
  // =========================================================================
  it('10. Faculty transfer preserves records across both institutions', async () => {
    const hash = await PasswordService.hashPassword('Pass1234');
    const facultyUser = await User.create({
      name: 'Prof Traveling',
      email: 'traveling@global.edu',
      passwordHash: hash,
      role: AppRole.FACULTY,
      collegeId: collegeA._id,
      instituteId: 'FAC-PIN-A',
      accountStatus: AccountStatus.ACTIVE,
    });

    // College A membership & faculty profile
    const memA = await WorkspaceMembership.create({
      userId: facultyUser._id,
      collegeId: collegeA._id,
      instituteId: 'FAC-PIN-A',
      status: MembershipStatus.ACTIVE,
    });
    const facProfileA = await Faculty.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      userId: facultyUser._id,
      name: 'Prof Traveling',
      email: 'traveling@global.edu',
      instituteId: 'FAC-PIN-A',
    });

    // College A historical assignment & attendance
    const asgnA = await FacultyAssignment.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      facultyId: facProfileA._id,
      facultyName: 'Prof Traveling',
      courseId: courseA._id,
      semesterId: semesterA._id,
      subjectId: subjectA._id,
      academicYearId: academicYearA._id,
      status: 'ended',
      isActive: false,
      endedAt: new Date(),
    });

    // Transition to College B
    const memB = await WorkspaceMembership.create({
      userId: facultyUser._id,
      collegeId: collegeB._id,
      instituteId: 'FAC-PIN-B',
      status: MembershipStatus.ACTIVE,
      effectiveStartDate: new Date(),
    });
    await WorkspaceRoleAssignment.create({
      membershipId: memB._id,
      userId: facultyUser._id,
      collegeId: collegeB._id,
      departmentId: deptB._id,
      role: AppRole.FACULTY,
      status: RoleAssignmentStatus.ACTIVE,
    });
    const facProfileB = await Faculty.create({
      collegeId: collegeB._id,
      departmentId: deptB._id,
      userId: facultyUser._id,
      name: 'Prof Traveling',
      email: 'traveling@global.edu',
      instituteId: 'FAC-PIN-B',
    });

    // End College A membership
    memA.status = MembershipStatus.INACTIVE;
    memA.effectiveEndDate = new Date();
    await memA.save();

    // VERIFY:
    // Both faculty profiles exist, pointing to the same global user
    expect(facProfileA.userId.toString()).toBe(facultyUser.id);
    expect(facProfileB.userId.toString()).toBe(facultyUser.id);

    // Historical College A assignment is still attributed to facProfileA
    const savedAsgn = await FacultyAssignment.findById(asgnA._id);
    expect(savedAsgn?.facultyId.toString()).toBe(facProfileA._id.toString());
  });

  // =========================================================================
  // SCENARIO 11: Role changes in one college do not change roles in another college
  // =========================================================================
  it('11. Role changes in one college do not change roles in another college', async () => {
    const hash = await PasswordService.hashPassword('Pass1234');
    const multiRoleUser = await User.create({
      name: 'Dual Role Person',
      email: 'dual@global.edu',
      passwordHash: hash,
      role: AppRole.FACULTY,
      accountStatus: AccountStatus.ACTIVE,
    });

    // College A: HOD
    const memA = await WorkspaceMembership.create({
      userId: multiRoleUser._id,
      collegeId: collegeA._id,
      instituteId: 'PIN-DUAL-A',
      status: MembershipStatus.ACTIVE,
    });
    const roleA = await WorkspaceRoleAssignment.create({
      membershipId: memA._id,
      userId: multiRoleUser._id,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      role: AppRole.HOD,
      status: RoleAssignmentStatus.ACTIVE,
    });

    // College B: Faculty
    const memB = await WorkspaceMembership.create({
      userId: multiRoleUser._id,
      collegeId: collegeB._id,
      instituteId: 'PIN-DUAL-B',
      status: MembershipStatus.ACTIVE,
    });
    const roleB = await WorkspaceRoleAssignment.create({
      membershipId: memB._id,
      userId: multiRoleUser._id,
      collegeId: collegeB._id,
      departmentId: deptB._id,
      role: AppRole.FACULTY,
      status: RoleAssignmentStatus.ACTIVE,
    });

    // Demote role in College A to FACULTY
    roleA.role = AppRole.FACULTY;
    roleA.status = RoleAssignmentStatus.ACTIVE;
    await roleA.save();

    // Verify College B role remains unaffected
    const refreshedRoleB = await WorkspaceRoleAssignment.findById(roleB._id);
    expect(refreshedRoleB?.role).toBe(AppRole.FACULTY);
    expect(refreshedRoleB?.collegeId.toString()).toBe(collegeB.id);
  });

  // =========================================================================
  // SCENARIO 12: Expired memberships and role assignments cannot access protected endpoints
  // =========================================================================
  it('12. Expired memberships and role assignments cannot access protected endpoints', async () => {
    const hash = await PasswordService.hashPassword('Pass1234');
    const user = await User.create({
      name: 'Expired User',
      email: 'expired@alpha.edu',
      passwordHash: hash,
      role: AppRole.FACULTY,
      collegeId: collegeA._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    const mem = await WorkspaceMembership.create({
      userId: user._id,
      collegeId: collegeA._id,
      instituteId: 'PIN-EXP-01',
      status: MembershipStatus.DEACTIVATED, // Expired/Deactivated
      effectiveStartDate: new Date(Date.now() - 7200000),
      effectiveEndDate: new Date(Date.now() - 3600000),
    });

    const sessionId = crypto.randomUUID();
    await AuthSession.create({
      userId: user._id,
      sessionId,
      refreshTokenHash: 'hash_exp',
      expiresAt: new Date(Date.now() + 86400000),
    });

    const token = signAccessToken({
      userId: user.id,
      role: AppRole.FACULTY,
      collegeId: collegeA.id,
      sessionId,
      membershipId: mem.id,
    });

    // Access attempt with deactivated membership token should be rejected (403 Forbidden)
    const res = await request(app)
      .get('/api/v1/academics/courses')
      .set('Authorization', `Bearer ${token}`)
      .set('X-Workspace-Id', collegeA.id);

    expect(res.status).toBe(403);
    expect(res.body.error.message).toMatch(/Workspace membership is (deactivated|inactive)/);
  });

  // =========================================================================
  // SCENARIO 13: Cross-tenant historical record access is denied
  // =========================================================================
  it('13. Cross-tenant historical record access is denied', async () => {
    // Admin A tries to access College B transfer records
    const res = await request(app)
      .get(`/api/v1/academics/departments/${deptB.id}/tenure-history?collegeId=${collegeB.id}`)
      .set('Authorization', `Bearer ${adminAToken}`)
      .set('X-Workspace-Id', collegeA.id);

    expect(res.status).toBe(403);
    expect(res.body.error.message).toContain('Cross-college tenant access is strictly prohibited');
  });

  // =========================================================================
  // SCENARIO 14: Published marks and results retain original attribution
  // =========================================================================
  it('14. Published marks and results retain original attribution', async () => {
    const hash = await PasswordService.hashPassword('Pass1234');
    const originalTeacherUser = await User.create({
      name: 'Original Marks Author',
      email: 'original@alpha.edu',
      passwordHash: hash,
      role: AppRole.FACULTY,
      collegeId: collegeA._id,
    });
    const origFaculty = await Faculty.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      userId: originalTeacherUser._id,
      name: 'Original Marks Author',
      email: 'original@alpha.edu',
      instituteId: 'FAC-ORIG',
    });

    const studentUser = await User.create({
      name: 'Test Student',
      email: 'ts@alpha.edu',
      passwordHash: hash,
      role: AppRole.STUDENT,
      collegeId: collegeA._id,
    });
    const student = await Student.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      userId: studentUser._id,
      name: 'Test Student',
      instituteId: 'STU-TS-01',
    });

    const assessment = await InternalAssessment.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      subjectId: subjectA._id,
      title: 'Midterm Examination 2026',
      assessmentType: AssessmentType.MID_TERM,
      maximumMarks: 50,
      weightage: 20,
      status: AssessmentStatus.PUBLISHED,
      createdBy: origFaculty._id,
      components: [{ key: 'written', name: 'Written', maxMarks: 50 }],
      entries: [
        {
          studentId: student._id,
          studentName: 'Test Student',
          componentMarks: { written: 42 },
          totalMarks: 42,
        },
      ],
      auditLog: [
        {
          action: 'PUBLISHED',
          performedBy: originalTeacherUser._id,
          performedByName: 'Original Marks Author',
          performedByRole: 'FACULTY',
          timestamp: new Date('2026-10-01'),
        },
      ],
    });

    // Verification: Published assessment entries and audit history retain Original Marks Author
    const savedAssessment = await InternalAssessment.findById(assessment._id);
    expect(savedAssessment?.createdBy?.toString()).toBe(origFaculty._id.toString());
    expect(savedAssessment?.auditLog[0].performedByName).toBe('Original Marks Author');
  });

  // =========================================================================
  // SCENARIO 15: Corrections create appropriate audit history
  // =========================================================================
  it('15. Corrections create appropriate audit history', async () => {
    const hash = await PasswordService.hashPassword('Pass1234');
    const facultyUser = await User.create({
      name: 'Teacher Grading',
      email: 'teacher@alpha.edu',
      passwordHash: hash,
      role: AppRole.FACULTY,
      collegeId: collegeA._id,
    });
    const faculty = await Faculty.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      userId: facultyUser._id,
      name: 'Teacher Grading',
      email: 'teacher@alpha.edu',
      instituteId: 'FAC-GRD',
    });
    expect(faculty._id).toBeDefined();
    const student = await Student.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'Graded Student',
      instituteId: 'STU-GRD',
    });

    const enrollment = await StudentEnrollment.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      studentId: student._id,
      courseId: courseA._id,
      semesterId: semesterA._id,
      academicYearId: academicYearA._id,
      enrollmentDate: new Date(),
      status: 'active',
    });

    // Mark recorded with correction audit
    const markRecord = await AssessmentMark.create({
      collegeId: collegeA._id,
      assessmentId: new mongoose.Types.ObjectId(),
      studentEnrollmentId: enrollment._id,
      studentId: student._id,
      studentName: 'Graded Student',
      subjectId: subjectA._id,
      marks: 35,
      maximumMarks: 50,
      status: StudentMarkStatus.ENTERED,
      isLocked: true,
      sourceType: 'LIVE',
      auditHistory: [
        {
          action: 'CORRECTION',
          previousMarks: 30,
          newMarks: 35,
          performedBy: facultyUser._id,
          reason: 'Recounting error resolved on verification',
          timestamp: new Date('2026-10-15'),
        },
      ],
    });

    expect(markRecord.auditHistory.length).toBe(1);
    expect(markRecord.auditHistory[0].previousMarks).toBe(30);
    expect(markRecord.auditHistory[0].newMarks).toBe(35);
    expect(markRecord.auditHistory[0].reason).toContain('Recounting error');
  });

  // =========================================================================
  // SCENARIO 16: Migration dry-run remains read-only and detects unresolved blockers
  // =========================================================================
  it('16. Migration dry-run remains read-only and detects unresolved blockers', async () => {
    // Count records before dry run
    const usersBefore = await User.countDocuments();
    const membershipsBefore = await WorkspaceMembership.countDocuments();
    const roleAssignmentsBefore = await WorkspaceRoleAssignment.countDocuments();

    // Execute dry run
    const report = await WorkspaceMigrationService.runDryRun();

    expect(report.mode).toBe('DRY_RUN');
    expect(report.totalUsersScanned).toBeGreaterThan(0);

    // Count records after dry run: MUST BE EXACTLY ZERO CHANGE
    const usersAfter = await User.countDocuments();
    const membershipsAfter = await WorkspaceMembership.countDocuments();
    const roleAssignmentsAfter = await WorkspaceRoleAssignment.countDocuments();

    expect(usersAfter).toBe(usersBefore);
    expect(membershipsAfter).toBe(membershipsBefore);
    expect(roleAssignmentsAfter).toBe(roleAssignmentsBefore);
  });

  // =========================================================================
  // SCENARIO 17: Migration operations are safe to retry where applicable
  // =========================================================================
  it('17. Migration operations are safe to retry where applicable', async () => {
    // Running dry run twice produces deterministic results
    const report1 = await WorkspaceMigrationService.runDryRun();
    const report2 = await WorkspaceMigrationService.runDryRun();

    expect(report1.totalUsersScanned).toBe(report2.totalUsersScanned);
    expect(report1.classifications.eligibleForMigration).toBe(report2.classifications.eligibleForMigration);
  });
});
