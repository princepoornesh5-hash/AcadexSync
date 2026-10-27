import mongoose from 'mongoose';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { User } from '../../src/models/user.model';
import { College } from '../../src/models/college.model';
import { Department } from '../../src/models/department.model';
import { Faculty } from '../../src/models/faculty.model';
import { Student } from '../../src/models/student.model';
import { Course } from '../../src/models/course.model';
import { AcademicYear } from '../../src/models/academicYear.model';
import { Semester } from '../../src/models/semester.model';
import { StudentEnrollment } from '../../src/models/studentEnrollment.model';
import { Invitation } from '../../src/models/invitation.model';
import { WorkspaceMembership } from '../../src/models/workspaceMembership.model';
import { WorkspaceRoleAssignment } from '../../src/models/workspaceRoleAssignment.model';
import { TransferCredit } from '../../src/models/transferCredit.model';
import { AuditLog } from '../../src/models/auditLog.model';
import { StudentService } from '../../src/services/student.service';
import { FacultyService } from '../../src/services/faculty.service';
import { InvitationService } from '../../src/services/invitation.service';
import { TransferCreditService } from '../../src/services/transferCredit.service';
import { WorkspaceMigrationService } from '../../src/services/migration/workspaceMigration.service';
import { AppRole } from '../../src/constants/roles';
import {
  AccountStatus,
  CollegeStatus,
  DepartmentStatus,
  MembershipStatus,
  MembershipType,
  TransferCreditStatus,
} from '../../src/constants/status';
import { AuthenticatedUser } from '../../src/types/auth.types';

function makeAuthUser(
  user: InstanceType<typeof User>,
  collegeId?: mongoose.Types.ObjectId,
  departmentId?: mongoose.Types.ObjectId
): AuthenticatedUser {
  return {
    id: user._id.toString(),
    instituteId: user.instituteId,
    name: user.name,
    email: user.email,
    role: user.role,
    collegeId: collegeId ? collegeId.toString() : user.collegeId?.toString(),
    departmentId: departmentId ? departmentId.toString() : user.departmentId?.toString(),
    accountStatus: user.accountStatus,
  };
}

describe('ACADEX PROMPT 2: Safe Identity Schema Expansion, PIN Numbers & Migration Foundation', () => {
  let collegeA: InstanceType<typeof College>;
  let collegeB: InstanceType<typeof College>;
  let deptA: InstanceType<typeof Department>;
  let deptB: InstanceType<typeof Department>;
  let adminUserA: InstanceType<typeof User>;
  let adminUserB: InstanceType<typeof User>;
  let authAdminA: AuthenticatedUser;
  let authAdminB: AuthenticatedUser;

  beforeAll(async () => {
    await setupTestDB();
    // Ensure all schema indexes (including compound unique constraints) are built
    await College.init();
    await User.init();
    await Department.init();
    await Faculty.init();
    await Student.init();
    await StudentEnrollment.init();
    await Course.init();
    await AcademicYear.init();
    await Semester.init();
    await Invitation.init();
    await AuditLog.init();
    await WorkspaceMembership.init();
    await WorkspaceRoleAssignment.init();
    await TransferCredit.init();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();

    collegeA = await College.create({
      name: 'College Alpha',
      code: 'CLG-A',
      address: '100 Alpha Blvd',
      email: 'admin@alpha.edu',
      phone: '1234567890',
      principal: 'Dr. Principal Alpha',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });

    collegeB = await College.create({
      name: 'College Beta',
      code: 'CLG-B',
      address: '200 Beta Way',
      email: 'admin@beta.edu',
      phone: '0987654321',
      principal: 'Dr. Principal Beta',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });

    deptA = await Department.create({
      name: 'Computer Science Alpha',
      code: 'CS-A',
      collegeId: collegeA._id,
      status: DepartmentStatus.ACTIVE,
      isActive: true,
    });

    deptB = await Department.create({
      name: 'Computer Science Beta',
      code: 'CS-B',
      collegeId: collegeB._id,
      status: DepartmentStatus.ACTIVE,
      isActive: true,
    });

    adminUserA = await User.create({
      name: 'Admin Alpha',
      email: 'admin@alpha.edu',
      role: AppRole.COLLEGE_ADMIN,
      collegeId: collegeA._id,
      instituteId: 'ADMIN-A-001',
      accountStatus: AccountStatus.ACTIVE,
    });
    authAdminA = makeAuthUser(adminUserA, collegeA._id);

    adminUserB = await User.create({
      name: 'Admin Beta',
      email: 'admin@beta.edu',
      role: AppRole.COLLEGE_ADMIN,
      collegeId: collegeB._id,
      instituteId: 'ADMIN-B-001',
      accountStatus: AccountStatus.ACTIVE,
    });
    authAdminB = makeAuthUser(adminUserB, collegeB._id);
  });

  // --------------------------------------------------------------------------
  // Scenario 1: One global user having memberships in two different colleges
  // --------------------------------------------------------------------------
  test('1. One global user can have active memberships in two different colleges', async () => {
    const globalUser = await User.create({
      name: 'Alice Scholar',
      email: 'alice.scholar@example.com',
      role: AppRole.STUDENT,
      collegeId: collegeA._id,
      instituteId: 'ALICE-01',
      accountStatus: AccountStatus.ACTIVE,
    });

    await WorkspaceMembership.create({
      userId: globalUser._id,
      collegeId: collegeA._id,
      instituteId: 'ALPHA-STU-101',
      memberType: MembershipType.STUDENT,
      status: MembershipStatus.ACTIVE,
      isDefault: true,
      effectiveStartDate: new Date('2025-08-01'),
    });

    await WorkspaceMembership.create({
      userId: globalUser._id,
      collegeId: collegeB._id,
      instituteId: 'BETA-STU-202',
      memberType: MembershipType.STUDENT,
      status: MembershipStatus.ACTIVE,
      isDefault: false,
      effectiveStartDate: new Date('2026-01-15'),
    });

    const memberships = await WorkspaceMembership.find({ userId: globalUser._id }).sort({ collegeId: 1 });
    expect(memberships).toHaveLength(2);
    expect(memberships[0].userId.toString()).toBe(globalUser._id.toString());
    expect(memberships[1].userId.toString()).toBe(globalUser._id.toString());
    expect(memberships[0].collegeId.toString()).not.toBe(memberships[1].collegeId.toString());
  });

  // --------------------------------------------------------------------------
  // Scenario 2: Different PIN Numbers for the same user in different colleges
  // --------------------------------------------------------------------------
  test('2. Same user retains distinct institutional PIN Numbers across different colleges', async () => {
    const globalUser = await User.create({
      name: 'Dr. Bob Researcher',
      email: 'bob.researcher@example.com',
      role: AppRole.FACULTY,
      collegeId: collegeA._id,
      instituteId: 'BOB-GLOBAL',
      accountStatus: AccountStatus.ACTIVE,
    });

    const memA = await WorkspaceMembership.create({
      userId: globalUser._id,
      collegeId: collegeA._id,
      instituteId: 'FAC-A-999',
      memberType: MembershipType.FACULTY,
      status: MembershipStatus.ACTIVE,
      isDefault: true,
      effectiveStartDate: new Date(),
    });

    const memB = await WorkspaceMembership.create({
      userId: globalUser._id,
      collegeId: collegeB._id,
      instituteId: 'FAC-B-111',
      memberType: MembershipType.FACULTY,
      status: MembershipStatus.ACTIVE,
      isDefault: false,
      effectiveStartDate: new Date(),
    });

    expect(memA.instituteId).toBe('FAC-A-999');
    expect(memB.instituteId).toBe('FAC-B-111');
    expect(memA.instituteId).not.toBe(memB.instituteId);
  });

  // --------------------------------------------------------------------------
  // Scenario 3: Identical PIN Number formats being allowed across different colleges
  // --------------------------------------------------------------------------
  test('3. Identical PIN Numbers are permitted across different colleges without conflict', async () => {
    const userA = await User.create({
      name: 'Student Alpha One',
      email: 'stu.a1@example.com',
      role: AppRole.STUDENT,
      collegeId: collegeA._id,
      instituteId: 'CSE-2026-001',
      accountStatus: AccountStatus.ACTIVE,
    });

    const userB = await User.create({
      name: 'Student Beta One',
      email: 'stu.b1@example.com',
      role: AppRole.STUDENT,
      collegeId: collegeB._id,
      instituteId: 'CSE-2026-001-B', // legacy scalar user
      accountStatus: AccountStatus.ACTIVE,
    });

    // Both colleges issue the exact same institutional PIN: "CSE-2026-001"
    const memA = await WorkspaceMembership.create({
      userId: userA._id,
      collegeId: collegeA._id,
      instituteId: 'CSE-2026-001',
      memberType: MembershipType.STUDENT,
      status: MembershipStatus.ACTIVE,
      effectiveStartDate: new Date(),
    });

    const memB = await WorkspaceMembership.create({
      userId: userB._id,
      collegeId: collegeB._id,
      instituteId: 'CSE-2026-001',
      memberType: MembershipType.STUDENT,
      status: MembershipStatus.ACTIVE,
      effectiveStartDate: new Date(),
    });

    expect(memA.instituteId).toBe('CSE-2026-001');
    expect(memB.instituteId).toBe('CSE-2026-001');

    const countA = await WorkspaceMembership.countDocuments({
      collegeId: collegeA._id,
      instituteId: 'CSE-2026-001',
    });
    const countB = await WorkspaceMembership.countDocuments({
      collegeId: collegeB._id,
      instituteId: 'CSE-2026-001',
    });

    expect(countA).toBe(1);
    expect(countB).toBe(1);
  });

  // --------------------------------------------------------------------------
  // Scenario 4: Duplicate PIN Numbers being rejected within the same college
  // --------------------------------------------------------------------------
  test('4. Duplicate PIN Numbers are rejected within the same college by compound unique index', async () => {
    const userOne = await User.create({
      name: 'User One',
      email: 'u1@alpha.edu',
      role: AppRole.STUDENT,
      collegeId: collegeA._id,
      instituteId: 'U1-PIN',
      accountStatus: AccountStatus.ACTIVE,
    });

    const userTwo = await User.create({
      name: 'User Two',
      email: 'u2@alpha.edu',
      role: AppRole.STUDENT,
      collegeId: collegeA._id,
      instituteId: 'U2-PIN',
      accountStatus: AccountStatus.ACTIVE,
    });

    await WorkspaceMembership.create({
      userId: userOne._id,
      collegeId: collegeA._id,
      instituteId: 'ALPHA-PIN-DUPLICATE',
      memberType: MembershipType.STUDENT,
      status: MembershipStatus.ACTIVE,
      effectiveStartDate: new Date(),
    });

    // Attempting to assign the same institutional PIN in the same college must fail with E11000
    let duplicateError: any = null;
    try {
      await WorkspaceMembership.create({
        userId: userTwo._id,
        collegeId: collegeA._id,
        instituteId: 'ALPHA-PIN-DUPLICATE',
        memberType: MembershipType.STUDENT,
        status: MembershipStatus.ACTIVE,
        effectiveStartDate: new Date(),
      });
    } catch (err: any) {
      duplicateError = err;
    }

    expect(duplicateError).not.toBeNull();
    expect(duplicateError.code).toBe(11000);
  });

  // --------------------------------------------------------------------------
  // Scenario 5: Failed student provisioning preserving pre-existing global user
  // --------------------------------------------------------------------------
  test('5. Failed student provisioning preserves pre-existing global user and College A records', async () => {
    // 1. Establish pre-existing user in College A with membership and profile
    const existingGlobalUser = await User.create({
      name: 'Charlie Senior',
      email: 'charlie.senior@example.com',
      role: AppRole.STUDENT,
      collegeId: collegeA._id,
      instituteId: 'CHARLIE-A-PIN',
      accountStatus: AccountStatus.ACTIVE,
    });

    const origMembershipA = await WorkspaceMembership.create({
      userId: existingGlobalUser._id,
      collegeId: collegeA._id,
      instituteId: 'ALPHA-PIN-ORIGINAL',
      memberType: MembershipType.STUDENT,
      status: MembershipStatus.ACTIVE,
      isDefault: true,
      effectiveStartDate: new Date(),
    });

    const origStudentProfileA = await Student.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      userId: existingGlobalUser._id,
      instituteId: 'ALPHA-PIN-ORIGINAL',
      name: 'Charlie Senior',
      email: 'charlie.senior@example.com',
      rollNumber: 'ROLL-A-100',
      status: 'active',
      isActive: true,
    });

    // 2. Mock Student.create to simulate unexpected failure during College B profile insertion
    const createSpy = jest.spyOn(Student, 'create').mockImplementationOnce(async () => {
      throw new Error('Database disk error during student profile creation');
    });

    // 3. Attempt to provision Charlie into College B
    let provisioningError: any = null;
    try {
      await StudentService.provisionStudent(
        {
          departmentId: deptB._id.toString(),
          name: 'Charlie Senior',
          instituteId: 'BETA-PIN-NEW',
          email: 'charlie.senior@example.com',
          rollNumber: 'ROLL-B-200',
        },
        authAdminB
      );
    } catch (err: any) {
      provisioningError = err;
    }

    createSpy.mockRestore();

    expect(provisioningError).not.toBeNull();
    expect(provisioningError.message).toContain('Database disk error');

    // 4. CRITICAL VERIFICATION:
    // Pre-existing user MUST NOT have been deleted!
    const userAfter = await User.findById(existingGlobalUser._id);
    expect(userAfter).not.toBeNull();
    expect(userAfter?.email).toBe('charlie.senior@example.com');

    // College A membership MUST NOT have been deleted!
    const memAAfter = await WorkspaceMembership.findById(origMembershipA._id);
    expect(memAAfter).not.toBeNull();
    expect(memAAfter?.status).toBe(MembershipStatus.ACTIVE);

    // College A profile MUST be intact!
    const profileAAfter = await Student.findById(origStudentProfileA._id);
    expect(profileAAfter).not.toBeNull();

    // Any temporary College B membership should have been cleanly rolled back
    const memBAfter = await WorkspaceMembership.findOne({
      userId: existingGlobalUser._id,
      collegeId: collegeB._id,
    });
    expect(memBAfter).toBeNull();
  });

  // --------------------------------------------------------------------------
  // Scenario 6: Failed faculty provisioning preserving pre-existing global user
  // --------------------------------------------------------------------------
  test('6. Failed faculty provisioning preserves pre-existing global user and College A records', async () => {
    // 1. Establish pre-existing faculty in College A
    const existingFacultyUser = await User.create({
      name: 'Prof. Diana Expert',
      email: 'diana.expert@example.com',
      role: AppRole.FACULTY,
      collegeId: collegeA._id,
      instituteId: 'DIANA-A-PIN',
      accountStatus: AccountStatus.ACTIVE,
    });

    const origMembershipA = await WorkspaceMembership.create({
      userId: existingFacultyUser._id,
      collegeId: collegeA._id,
      instituteId: 'FAC-ALPHA-PIN',
      memberType: MembershipType.FACULTY,
      status: MembershipStatus.ACTIVE,
      isDefault: true,
      effectiveStartDate: new Date(),
    });

    const origFacultyProfileA = await Faculty.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      userId: existingFacultyUser._id,
      instituteId: 'FAC-ALPHA-PIN',
      name: 'Prof. Diana Expert',
      email: 'diana.expert@example.com',
      employeeId: 'EMP-A-100',
      status: 'active',
      isActive: true,
    });

    // 2. Mock Faculty.create to simulate failure during profile insertion in College B
    const facultySpy = jest.spyOn(Faculty, 'create').mockImplementationOnce(async () => {
      throw new Error('Simulation: Network error during faculty profile creation');
    });

    // 3. Attempt to provision Prof Diana into College B
    let provisioningError: any = null;
    try {
      await FacultyService.provisionFaculty(
        {
          departmentId: deptB._id.toString(),
          name: 'Prof. Diana Expert',
          instituteId: 'FAC-BETA-PIN',
          email: 'diana.expert@example.com',
          employeeId: 'EMP-B-200',
        },
        authAdminB
      );
    } catch (err: any) {
      provisioningError = err;
    }

    facultySpy.mockRestore();

    expect(provisioningError).not.toBeNull();
    expect(provisioningError.message).toContain('Network error');

    // 4. CRITICAL VERIFICATION:
    // Global user remains untouched
    const userAfter = await User.findById(existingFacultyUser._id);
    expect(userAfter).not.toBeNull();
    expect(userAfter?.email).toBe('diana.expert@example.com');

    // College A membership and profile remain untouched
    const memAAfter = await WorkspaceMembership.findById(origMembershipA._id);
    expect(memAAfter).not.toBeNull();

    const profileAAfter = await Faculty.findById(origFacultyProfileA._id);
    expect(profileAAfter).not.toBeNull();

    // College B membership was safely rolled back
    const memBAfter = await WorkspaceMembership.findOne({
      userId: existingFacultyUser._id,
      collegeId: collegeB._id,
    });
    expect(memBAfter).toBeNull();
  });

  // --------------------------------------------------------------------------
  // Scenario 7: TransferCredit validation and tenant isolation
  // --------------------------------------------------------------------------
  test('7. TransferCredit enforces tenant isolation and valid student association without fabricating marks', async () => {
    const studentUser = await User.create({
      name: 'Lateral Entry Student',
      email: 'lateral.student@example.com',
      role: AppRole.STUDENT,
      collegeId: collegeB._id,
      instituteId: 'LATERAL-B-001',
      accountStatus: AccountStatus.ACTIVE,
    });

    await WorkspaceMembership.create({
      userId: studentUser._id,
      collegeId: collegeB._id,
      instituteId: 'LATERAL-B-001',
      memberType: MembershipType.STUDENT,
      status: MembershipStatus.ACTIVE,
      effectiveStartDate: new Date(),
    });

    const studentProfile = await Student.create({
      collegeId: collegeB._id,
      departmentId: deptB._id,
      userId: studentUser._id,
      instituteId: 'LATERAL-B-001',
      name: 'Lateral Entry Student',
      email: 'lateral.student@example.com',
      rollNumber: 'ROLL-LATERAL-001',
      status: 'active',
      isActive: true,
    });

    const course = await Course.create({
      collegeId: collegeB._id,
      departmentId: deptB._id,
      name: 'B.Tech CSE',
      code: 'BTCSE',
      durationYears: 4,
    });

    const academicYear = await AcademicYear.create({
      collegeId: collegeB._id,
      name: '2026-2027',
      startDate: new Date('2026-07-01'),
      endDate: new Date('2027-06-30'),
      isCurrent: true,
    });

    const semester = await Semester.create({
      collegeId: collegeB._id,
      departmentId: deptB._id,
      courseId: course._id,
      academicYearId: academicYear._id,
      number: 3,
      name: 'Semester 3',
      startDate: new Date('2026-07-01'),
      endDate: new Date('2026-12-31'),
    });

    const enrollment = await StudentEnrollment.create({
      collegeId: collegeB._id,
      studentId: studentProfile._id,
      departmentId: deptB._id,
      courseId: course._id,
      academicYearId: academicYear._id,
      semesterId: semester._id,
      enrollmentDate: new Date(),
      status: 'active',
    });

    // A. Authorized recording by College Admin B for destination college B
    const creditRecord = await TransferCreditService.recordTransferCredit(
      authAdminB,
      {
        studentId: studentProfile._id.toString(),
        studentEnrollmentId: enrollment._id.toString(),
        originCollegeId: collegeA._id.toString(),
        originInstitutionName: 'Polytechnic State Institute',
        priorProgramOrDegree: 'Diploma in Computer Engineering (State Board)',
        admissionType: 'LATERAL_ENTRY',
        entrySemesterNumber: 3,
        recognizedCredits: 7,
        transferredSubjects: [
          {
            subjectCode: 'MATH-201',
            subjectName: 'Applied Mathematics II',
            credits: 4,
            grade: 'A',
          },
          {
            subjectCode: 'EC-101',
            subjectName: 'Basic Electronics',
            credits: 3,
            grade: 'B+',
          },
        ],
        remarks: 'Recognised lateral entry transfer credits verified against official transcript.',
      }
    );

    expect(creditRecord).toBeDefined();
    expect(creditRecord.recognizedCredits).toBe(7);
    expect(creditRecord.verificationStatus).toBe(TransferCreditStatus.PENDING);
    expect(creditRecord.transferredSubjects).toHaveLength(2);

    // B. Tenant Isolation: Admin A cannot record transfer credits for destination College B
    await expect(
      TransferCreditService.recordTransferCredit(
        authAdminA, // Unauthorized: Admin of College A attempting to modify College B
        {
          studentId: studentProfile._id.toString(),
          studentEnrollmentId: enrollment._id.toString(),
          originInstitutionName: 'State Poly',
          admissionType: 'LATERAL_ENTRY',
          entrySemesterNumber: 3,
          recognizedCredits: 0,
          transferredSubjects: [],
        }
      )
    ).rejects.toThrow(/Student profile not found in this college/);

    // C. Nonexistent student should be rejected
    const fakeId = new mongoose.Types.ObjectId().toString();
    await expect(
      TransferCreditService.recordTransferCredit(
        authAdminB,
        {
          studentId: fakeId,
          studentEnrollmentId: enrollment._id.toString(),
          originInstitutionName: 'Polytechnic',
          admissionType: 'LATERAL_ENTRY',
          entrySemesterNumber: 3,
          recognizedCredits: 0,
          transferredSubjects: [],
        }
      )
    ).rejects.toThrow(/Student profile not found in this college/);

    // D. Approving the credit record by destination College Admin B
    const approved = await TransferCreditService.updateStatus(
      creditRecord._id.toString(),
      authAdminB,
      {
        status: TransferCreditStatus.APPROVED,
        remarks: 'Dean approved verified transcript',
      }
    );
    expect(approved.verificationStatus).toBe(TransferCreditStatus.APPROVED);
    expect(approved.approvedBy?.toString()).toBe(authAdminB.id);
  });

  // --------------------------------------------------------------------------
  // Scenario 8: Dry-run migration making no database changes
  // --------------------------------------------------------------------------
  test('8. Dry-run migration is strictly read-only and performs zero database writes', async () => {
    // Populate realistic legacy users
    await User.create([
      {
        name: 'Legacy User 1',
        email: 'legacy1@alpha.edu',
        role: AppRole.STUDENT,
        collegeId: collegeA._id,
        instituteId: 'LEG-A-001',
        accountStatus: AccountStatus.ACTIVE,
      },
      {
        name: 'Legacy User 2',
        email: 'legacy2@alpha.edu',
        role: AppRole.FACULTY,
        collegeId: collegeA._id,
        instituteId: 'LEG-A-002',
        accountStatus: AccountStatus.ACTIVE,
      },
    ]);

    // Snapshot counts before dry run
    const beforeUserCount = await User.countDocuments();
    const beforeCollegeCount = await College.countDocuments();
    const beforeMembershipCount = await WorkspaceMembership.countDocuments();
    const beforeRoleCount = await WorkspaceRoleAssignment.countDocuments();
    const beforeAuditCount = await AuditLog.countDocuments();

    // Run dry run
    const dryRunReport = await WorkspaceMigrationService.runDryRun('test_dryrun_readonly');

    // Snapshot counts after dry run
    const afterUserCount = await User.countDocuments();
    const afterCollegeCount = await College.countDocuments();
    const afterMembershipCount = await WorkspaceMembership.countDocuments();
    const afterRoleCount = await WorkspaceRoleAssignment.countDocuments();
    const afterAuditCount = await AuditLog.countDocuments();

    expect(dryRunReport.mode).toBe('DRY_RUN');
    expect(afterUserCount).toBe(beforeUserCount);
    expect(afterCollegeCount).toBe(beforeCollegeCount);
    expect(afterMembershipCount).toBe(beforeMembershipCount);
    expect(afterRoleCount).toBe(beforeRoleCount);
    expect(afterAuditCount).toBe(beforeAuditCount);
  });

  // --------------------------------------------------------------------------
  // Scenario 9: Dry-run detection of duplicate and unmappable identities
  // --------------------------------------------------------------------------
  test('9. Dry-run reliably flags duplicate PINs, missing colleges, and unmappable identities with safeToMigrate=false', async () => {
    // 1. User missing collegeId
    await User.create({
      name: 'No College User',
      email: 'no.college@example.com',
      role: AppRole.STUDENT,
      instituteId: 'NO-CLG-001',
      accountStatus: AccountStatus.ACTIVE,
    });

    // 2. User with non-existent collegeId
    const missingCollegeId = new mongoose.Types.ObjectId();
    await User.create({
      name: 'Orphaned College User',
      email: 'orphan.clg@example.com',
      role: AppRole.STUDENT,
      collegeId: missingCollegeId,
      instituteId: 'ORPHAN-001',
      accountStatus: AccountStatus.ACTIVE,
    });

    // 3. User with conflicting PIN between User and WorkspaceMembership
    const conflictUser = await User.create({
      name: 'Conflict PIN User',
      email: 'conflict@alpha.edu',
      role: AppRole.STUDENT,
      collegeId: collegeA._id,
      instituteId: 'PIN-USER-ALPHA',
      accountStatus: AccountStatus.ACTIVE,
    });

    await WorkspaceMembership.create({
      userId: conflictUser._id,
      collegeId: collegeA._id,
      instituteId: 'PIN-MEMBERSHIP-ALPHA', // Conflicting PIN with User
      memberType: MembershipType.STUDENT,
      status: MembershipStatus.ACTIVE,
      effectiveStartDate: new Date(),
    });

    // 4. Duplicate PINs in WorkspaceMembership (simulating pre-index legacy dirty data)
    try {
      await WorkspaceMembership.collection.dropIndex('collegeId_1_instituteId_1');
    } catch {
      // index may already not exist or be named differently
    }

    const dupUser1 = await User.create({
      name: 'Dup User 1',
      email: 'dup1@alpha.edu',
      role: AppRole.STUDENT,
      collegeId: collegeA._id,
      instituteId: 'DUP-USER-1',
      accountStatus: AccountStatus.ACTIVE,
    });
    const dupUser2 = await User.create({
      name: 'Dup User 2',
      email: 'dup2@alpha.edu',
      role: AppRole.STUDENT,
      collegeId: collegeA._id,
      instituteId: 'DUP-USER-2',
      accountStatus: AccountStatus.ACTIVE,
    });

    await WorkspaceMembership.collection.insertMany([
      {
        userId: dupUser1._id,
        collegeId: collegeA._id,
        instituteId: 'COLLISION-PIN',
        memberType: MembershipType.STUDENT,
        status: MembershipStatus.ACTIVE,
        isDefault: false,
        joinedAt: new Date(),
        effectiveStartDate: new Date(),
      },
      {
        userId: dupUser2._id,
        collegeId: collegeA._id,
        instituteId: 'COLLISION-PIN', // Duplicate PIN within College A!
        memberType: MembershipType.STUDENT,
        status: MembershipStatus.ACTIVE,
        isDefault: false,
        joinedAt: new Date(),
        effectiveStartDate: new Date(),
      },
    ]);

    // 5. Orphaned membership referencing non-existent user
    const nonexistentUserId = new mongoose.Types.ObjectId();
    await WorkspaceMembership.collection.insertOne({
      userId: nonexistentUserId,
      collegeId: collegeA._id,
      instituteId: 'GHOST-001',
      memberType: MembershipType.STUDENT,
      status: MembershipStatus.ACTIVE,
      isDefault: false,
      joinedAt: new Date(),
      effectiveStartDate: new Date(),
    });

    const report = await WorkspaceMigrationService.runDryRun('test_dryrun_anomalies');

    expect(report.safeToMigrate).toBe(false);
    expect(report.classifications.unresolvedAnomalies).toBeGreaterThan(0);

    const categories = report.anomalies.map((a) => a.category);
    expect(categories).toContain('MISSING_COLLEGE');
    expect(categories).toContain('ORPHAN_REFERENCE');
    expect(categories).toContain('CONFLICTING_PIN');

    const indexConflicts = report.indexConflicts.filter((c) => c.instituteId === 'COLLISION-PIN');
    expect(indexConflicts.length).toBeGreaterThan(0);

    // Rebuild index
    await WorkspaceMembership.init();
  });

  // --------------------------------------------------------------------------
  // Scenario 10: Backward compatibility with existing authentication and invitations
  // --------------------------------------------------------------------------
  test('10. Backward compatibility: User scalar fields and Invitation provisioning populate both User and WorkspaceMembership', async () => {
    // 1. Verify User scalar field instituteId is preserved and accessible
    const user = await User.create({
      name: 'Compatibility User',
      email: 'compat@alpha.edu',
      role: AppRole.FACULTY,
      collegeId: collegeA._id,
      instituteId: 'COMPAT-PIN-001',
      accountStatus: AccountStatus.ACTIVE,
    });

    const fetched = await User.findById(user._id);
    expect(fetched?.instituteId).toBe('COMPAT-PIN-001');

    // 2. Verify InvitationService provisions both User.instituteId and WorkspaceMembership.instituteId
    const invitationResult = await InvitationService.createInvitation(authAdminA, {
      name: 'Invited Teacher',
      instituteId: 'TEACH-A-777',
      email: 'teacher.invited@alpha.edu',
      role: AppRole.FACULTY,
      departmentId: deptA._id.toString(),
    });

    expect(invitationResult.isNewUser).toBe(true);
    expect(invitationResult.user.instituteId).toBe('TEACH-A-777');

    const membership = await WorkspaceMembership.findOne({
      userId: invitationResult.user._id,
      collegeId: collegeA._id,
    });

    expect(membership).not.toBeNull();
    expect(membership?.instituteId).toBe('TEACH-A-777');
    expect(membership?.memberType).toBe(MembershipType.FACULTY);
    expect(membership?.effectiveStartDate).toBeDefined();
  });
});
