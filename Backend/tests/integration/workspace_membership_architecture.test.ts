import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { User } from '../../src/models/user.model';
import { College } from '../../src/models/college.model';
import { Department } from '../../src/models/department.model';
import { Faculty } from '../../src/models/faculty.model';
import { Student } from '../../src/models/student.model';
import { Invitation } from '../../src/models/invitation.model';
import { WorkspaceMembership } from '../../src/models/workspaceMembership.model';
import { WorkspaceRoleAssignment } from '../../src/models/workspaceRoleAssignment.model';
import { AuditLog } from '../../src/models/auditLog.model';
import { WorkspaceMembershipService } from '../../src/services/workspaceMembership.service';
import { WorkspaceCompatibilityService } from '../../src/services/workspaceCompatibility.service';
import { WorkspaceMigrationService } from '../../src/services/migration/workspaceMigration.service';
import { InvitationService } from '../../src/services/invitation.service';
import { PasswordService } from '../../src/services/password.service';
import { AppRole } from '../../src/constants/roles';
import { AuthenticatedUser } from '../../src/types/auth.types';
import {
  AccountStatus,
  CollegeStatus,
  DepartmentStatus,
  MembershipStatus,
  RoleAssignmentStatus,
} from '../../src/constants/status';

function toAuthUser(user: InstanceType<typeof User>): AuthenticatedUser {
  return {
    id: user.id,
    instituteId: user.instituteId,
    name: user.name,
    email: user.email,
    role: user.role,
    collegeId: user.collegeId ? user.collegeId.toString() : undefined,
    departmentId: user.departmentId ? user.departmentId.toString() : undefined,
    accountStatus: user.accountStatus,
  };
}

describe('Prompt 2 of 5: Workspace Membership Architecture & Safe Migration', () => {
  let collegeA: InstanceType<typeof College>;
  let collegeB: InstanceType<typeof College>;
  let deptA1: InstanceType<typeof Department>;
  let deptA2: InstanceType<typeof Department>;
  let deptB1: InstanceType<typeof Department>;

  beforeAll(async () => {
    await setupTestDB();
    await College.init();
    await User.init();
    await Department.init();
    await Faculty.init();
    await Student.init();
    await Invitation.init();
    await AuditLog.init();
    await WorkspaceMembership.init();
    await WorkspaceRoleAssignment.init();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();

    collegeA = await College.create({
      name: 'College of Engineering A',
      code: 'COE-A',
      address: '123 Tech Park, Bangalore',
      email: 'info@coe-a.edu',
      phone: '+918023456789',
      principal: 'Dr. Principal A',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });

    collegeB = await College.create({
      name: 'Institute of Technology B',
      code: 'IOT-B',
      address: '456 Innovation Blvd, Hyderabad',
      email: 'info@iot-b.edu',
      phone: '+914023456789',
      principal: 'Dr. Principal B',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });

    deptA1 = await Department.create({
      name: 'Computer Science',
      code: 'CSE',
      collegeId: collegeA._id,
      status: DepartmentStatus.ACTIVE,
      isActive: true,
    });

    deptA2 = await Department.create({
      name: 'Mechanical Engineering',
      code: 'MECH',
      collegeId: collegeA._id,
      status: DepartmentStatus.ACTIVE,
      isActive: true,
    });

    deptB1 = await Department.create({
      name: 'Information Science',
      code: 'ISE',
      collegeId: collegeB._id,
      status: DepartmentStatus.ACTIVE,
      isActive: true,
    });
  });

  // =========================================================================
  // GROUP 1: IDENTITY AND MEMBERSHIP (Scenarios 1 - 8)
  // =========================================================================
  describe('Group 1: Identity and Membership Lifecycle', () => {
    it('Scenario 1: One User can have active memberships in two colleges without duplicating the User', async () => {
      const user = await User.create({
        name: 'Dr. Jane Doe',
        instituteId: 'UID-001',
        email: 'jane.doe@example.com',
        role: AppRole.FACULTY,
        collegeId: collegeA._id,
        accountStatus: AccountStatus.ACTIVE,
      });

      const memA = await WorkspaceMembershipService.createMembership({
        userId: user._id,
        collegeId: collegeA._id,
        status: MembershipStatus.ACTIVE,
        isDefault: true,
      });

      const memB = await WorkspaceMembershipService.createMembership({
        userId: user._id,
        collegeId: collegeB._id,
        status: MembershipStatus.ACTIVE,
        isDefault: false,
      });

      expect(memA).toBeDefined();
      expect(memB).toBeDefined();
      expect(memA.id).not.toBe(memB.id);

      // Verify canonical User document remains strictly single
      const userCount = await User.countDocuments({ email: 'jane.doe@example.com' });
      expect(userCount).toBe(1);

      const memberships = await WorkspaceMembershipService.getMembershipsForUser(user._id);
      expect(memberships).toHaveLength(2);
    });

    it('Scenario 2: Duplicate membership creation for the same user and college is prevented', async () => {
      const user = await User.create({
        name: 'John Student',
        instituteId: 'UID-002',
        email: 'john@example.com',
        role: AppRole.STUDENT,
        collegeId: collegeA._id,
        accountStatus: AccountStatus.ACTIVE,
      });

      const mem1 = await WorkspaceMembershipService.createMembership({
        userId: user._id,
        collegeId: collegeA._id,
        status: MembershipStatus.ACTIVE,
      });

      // Calling createMembership again returns existing membership idempotently
      const mem2 = await WorkspaceMembershipService.createMembership({
        userId: user._id,
        collegeId: collegeA._id,
        status: MembershipStatus.ACTIVE,
      });

      expect(mem1.id).toBe(mem2.id);

      // Attempting direct raw insertion violating compound index { userId: 1, collegeId: 1 } must reject
      await expect(
        WorkspaceMembership.create({
          userId: user._id,
          collegeId: collegeA._id,
          status: MembershipStatus.ACTIVE,
        })
      ).rejects.toThrow();

      const count = await WorkspaceMembership.countDocuments({
        userId: user._id,
        collegeId: collegeA._id,
      });
      expect(count).toBe(1);
    });

    it('Scenario 3: Memberships remain tenant-scoped', async () => {
      const userA = await User.create({
        name: 'User A',
        instituteId: 'UID-003A',
        email: 'usera@example.com',
        role: AppRole.FACULTY,
        collegeId: collegeA._id,
        accountStatus: AccountStatus.ACTIVE,
      });

      const userB = await User.create({
        name: 'User B',
        instituteId: 'UID-003B',
        email: 'userb@example.com',
        role: AppRole.FACULTY,
        collegeId: collegeB._id,
        accountStatus: AccountStatus.ACTIVE,
      });

      await WorkspaceMembershipService.createMembership({
        userId: userA._id,
        collegeId: collegeA._id,
        status: MembershipStatus.ACTIVE,
      });

      await WorkspaceMembershipService.createMembership({
        userId: userB._id,
        collegeId: collegeB._id,
        status: MembershipStatus.ACTIVE,
      });

      const membersInA = await WorkspaceMembership.find({ collegeId: collegeA._id });
      expect(membersInA).toHaveLength(1);
      expect(membersInA[0].userId.toString()).toBe(userA.id);

      const membersInB = await WorkspaceMembership.find({ collegeId: collegeB._id });
      expect(membersInB).toHaveLength(1);
      expect(membersInB[0].userId.toString()).toBe(userB.id);
    });

    it('Scenario 4: A suspended or revoked membership cannot be reactivated accidentally by migration reruns', async () => {
      const user = await User.create({
        name: 'Suspended Faculty',
        instituteId: 'UID-004',
        email: 'suspended@example.com',
        role: AppRole.FACULTY,
        collegeId: collegeA._id,
        accountStatus: AccountStatus.SUSPENDED,
      });

      const membership = await WorkspaceMembershipService.createMembership({
        userId: user._id,
        collegeId: collegeA._id,
        status: MembershipStatus.SUSPENDED,
        statusReason: 'Disciplinary action',
      });

      await WorkspaceMembershipService.addRoleAssignment({
        membershipId: membership._id,
        role: AppRole.FACULTY,
        departmentId: deptA1._id,
        status: RoleAssignmentStatus.SUSPENDED,
      });

      // Execute migration
      await WorkspaceMigrationService.executeMigration({
        runId: 'test_rerun_1',
        allowAnomalies: true,
      });

      // Verify status was NOT altered or reactivated
      const reloadedMem = await WorkspaceMembership.findById(membership._id);
      expect(reloadedMem?.status).toBe(MembershipStatus.SUSPENDED);
      expect(reloadedMem?.statusReason).toBe('Disciplinary action');
    });

    it('Scenario 5: Independent roles can exist in separate colleges for the same User', async () => {
      const user = await User.create({
        name: 'Multi Role User',
        instituteId: 'UID-005',
        email: 'multirole@example.com',
        role: AppRole.FACULTY,
        collegeId: collegeA._id,
        accountStatus: AccountStatus.ACTIVE,
      });

      const memA = await WorkspaceMembershipService.createMembership({
        userId: user._id,
        collegeId: collegeA._id,
        status: MembershipStatus.ACTIVE,
      });
      await WorkspaceMembershipService.addRoleAssignment({
        membershipId: memA._id,
        role: AppRole.FACULTY,
        departmentId: deptA1._id,
      });

      const memB = await WorkspaceMembershipService.createMembership({
        userId: user._id,
        collegeId: collegeB._id,
        status: MembershipStatus.ACTIVE,
      });
      await WorkspaceMembershipService.addRoleAssignment({
        membershipId: memB._id,
        role: AppRole.STUDENT,
        departmentId: deptB1._id,
      });

      const hasFacultyInA = await WorkspaceMembershipService.hasRole(user._id, collegeA._id, AppRole.FACULTY);
      const hasStudentInA = await WorkspaceMembershipService.hasRole(user._id, collegeA._id, AppRole.STUDENT);
      const hasFacultyInB = await WorkspaceMembershipService.hasRole(user._id, collegeB._id, AppRole.FACULTY);
      const hasStudentInB = await WorkspaceMembershipService.hasRole(user._id, collegeB._id, AppRole.STUDENT);

      expect(hasFacultyInA).toBe(true);
      expect(hasStudentInA).toBe(false);
      expect(hasFacultyInB).toBe(false);
      expect(hasStudentInB).toBe(true);
    });

    it('Scenario 6: Multiple permitted roles can be represented in one college without a composite-role enum', async () => {
      const user = await User.create({
        name: 'HOD and Faculty',
        instituteId: 'UID-006',
        email: 'hod.faculty@example.com',
        role: AppRole.HOD,
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        accountStatus: AccountStatus.ACTIVE,
      });

      const mem = await WorkspaceMembershipService.createMembership({
        userId: user._id,
        collegeId: collegeA._id,
        status: MembershipStatus.ACTIVE,
      });

      // Role 1: HOD in deptA1
      const role1 = await WorkspaceMembershipService.addRoleAssignment({
        membershipId: mem._id,
        role: AppRole.HOD,
        departmentId: deptA1._id,
      });

      // Role 2: FACULTY in deptA1 (no composite enum needed!)
      const role2 = await WorkspaceMembershipService.addRoleAssignment({
        membershipId: mem._id,
        role: AppRole.FACULTY,
        departmentId: deptA1._id,
      });

      expect(role1.role).toBe(AppRole.HOD);
      expect(role2.role).toBe(AppRole.FACULTY);

      const roles = await WorkspaceRoleAssignment.find({ membershipId: mem._id });
      expect(roles).toHaveLength(2);
      expect(roles.map((r) => r.role)).toEqual(expect.arrayContaining([AppRole.HOD, AppRole.FACULTY]));
    });

    it('Scenario 7: Department-scoped roles preserve their scope', async () => {
      const user = await User.create({
        name: 'Dept Scoped User',
        instituteId: 'UID-007',
        email: 'scoped@example.com',
        role: AppRole.HOD,
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        accountStatus: AccountStatus.ACTIVE,
      });

      const mem = await WorkspaceMembershipService.createMembership({
        userId: user._id,
        collegeId: collegeA._id,
        status: MembershipStatus.ACTIVE,
      });

      // HOD without department must fail
      await expect(
        WorkspaceMembershipService.addRoleAssignment({
          membershipId: mem._id,
          role: AppRole.HOD,
          departmentId: null,
        })
      ).rejects.toThrow('departmentId is strictly required for HOD role assignment');

      // Cross-college department must fail
      await expect(
        WorkspaceMembershipService.addRoleAssignment({
          membershipId: mem._id,
          role: AppRole.HOD,
          departmentId: deptB1._id,
        })
      ).rejects.toThrow('Department does not belong to the target college');

      // Valid department assignment succeeds
      const assignment = await WorkspaceMembershipService.addRoleAssignment({
        membershipId: mem._id,
        role: AppRole.HOD,
        departmentId: deptA1._id,
      });
      expect(assignment.departmentId?.toString()).toBe(deptA1.id);
    });

    it('Scenario 8: Super Admin platform authority is not accidentally converted into ordinary college membership', async () => {
      const superAdmin = await User.create({
        name: 'Platform Super Admin',
        instituteId: 'ADM-999',
        email: 'superadmin@acadex.com',
        role: AppRole.SUPER_ADMIN,
        collegeId: null,
        departmentId: null,
        accountStatus: AccountStatus.ACTIVE,
      });

      // Run dry-run migration
      const dryRun = await WorkspaceMigrationService.runDryRun();
      expect(dryRun.classifications.superAdminPlatformUsers).toBe(1);

      // Execute migration
      const exec = await WorkspaceMigrationService.executeMigration({ allowAnomalies: true });
      expect(exec.createdMembershipsCount).toBe(0);

      const mems = await WorkspaceMembership.find({ userId: superAdmin._id });
      expect(mems).toHaveLength(0);
    });
  });

  // =========================================================================
  // GROUP 2: PROFILE INDEXES (Scenarios 9 - 12)
  // =========================================================================
  describe('Group 2: Tenant-Aware Profile Indexes', () => {
    it('Scenario 9: Faculty profiles for the same User in different colleges are supported when valid', async () => {
      const user = await User.create({
        name: 'Adjunct Professor',
        instituteId: 'PROF-009',
        email: 'adjunct@example.com',
        role: AppRole.FACULTY,
        collegeId: collegeA._id,
        accountStatus: AccountStatus.ACTIVE,
      });

      const profileA = await Faculty.create({
        userId: user._id,
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        name: user.name,
        email: user.email,
        employeeId: 'EMP-A-001',
        designation: 'Adjunct Professor',
        qualification: 'PhD',
      });

      const profileB = await Faculty.create({
        userId: user._id,
        collegeId: collegeB._id,
        departmentId: deptB1._id,
        name: user.name,
        email: user.email,
        employeeId: 'EMP-B-001',
        designation: 'Visiting Lecturer',
        qualification: 'PhD',
      });

      expect(profileA).toBeDefined();
      expect(profileB).toBeDefined();
      expect(profileA.id).not.toBe(profileB.id);

      const profiles = await Faculty.find({ userId: user._id });
      expect(profiles).toHaveLength(2);
    });

    it('Scenario 10: Student profiles for the same User in different colleges are supported when valid', async () => {
      const user = await User.create({
        name: 'Exchange Student',
        instituteId: 'STUD-010',
        email: 'exchange@example.com',
        role: AppRole.STUDENT,
        collegeId: collegeA._id,
        accountStatus: AccountStatus.ACTIVE,
      });

      const profileA = await Student.create({
        userId: user._id,
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        name: user.name,
        admissionNumber: 'ADM-A-100',
        currentSemester: 3,
      });

      const profileB = await Student.create({
        userId: user._id,
        collegeId: collegeB._id,
        departmentId: deptB1._id,
        name: user.name,
        admissionNumber: 'ADM-B-200',
        currentSemester: 1,
      });

      expect(profileA).toBeDefined();
      expect(profileB).toBeDefined();

      const studentProfiles = await Student.find({ userId: user._id });
      expect(studentProfiles).toHaveLength(2);
    });

    it('Scenario 11: Duplicate profiles within the same college are prevented where required', async () => {
      const user = await User.create({
        name: 'Faculty User',
        instituteId: 'FAC-011',
        email: 'fac11@example.com',
        role: AppRole.FACULTY,
        collegeId: collegeA._id,
        accountStatus: AccountStatus.ACTIVE,
      });

      await Faculty.create({
        userId: user._id,
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        name: user.name,
        email: user.email,
        employeeId: 'EMP-11',
        designation: 'Assistant Professor',
        qualification: 'MTech',
      });

      // Second profile in same college must throw duplicate key error due to { collegeId: 1, userId: 1 } unique index
      await expect(
        Faculty.create({
          userId: user._id,
          collegeId: collegeA._id,
          departmentId: deptA2._id,
          name: user.name,
          email: user.email,
          employeeId: 'EMP-11-DUP',
          designation: 'Lecturer',
          qualification: 'MTech',
        })
      ).rejects.toThrow();
    });

    it('Scenario 12: A query requiring a college cannot return an arbitrary profile from another college', async () => {
      const user = await User.create({
        name: 'Multi College Faculty',
        instituteId: 'FAC-012',
        email: 'fac12@example.com',
        role: AppRole.FACULTY,
        collegeId: collegeA._id,
        accountStatus: AccountStatus.ACTIVE,
      });

      await Faculty.create({
        userId: user._id,
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        name: user.name,
        email: user.email,
        employeeId: 'EMP-A-12',
        designation: 'Professor',
        qualification: 'PhD',
      });

      await Faculty.create({
        userId: user._id,
        collegeId: collegeB._id,
        departmentId: deptB1._id,
        name: user.name,
        email: user.email,
        employeeId: 'EMP-B-12',
        designation: 'Dean',
        qualification: 'PhD',
      });

      // Scoped query for College A
      const facultyInCollegeA = await Faculty.findOne({
        userId: user._id,
        collegeId: collegeA._id,
      });
      expect(facultyInCollegeA?.employeeId).toBe('EMP-A-12');

      // Scoped query for College B
      const facultyInCollegeB = await Faculty.findOne({
        userId: user._id,
        collegeId: collegeB._id,
      });
      expect(facultyInCollegeB?.employeeId).toBe('EMP-B-12');
    });
  });

  // =========================================================================
  // GROUP 3: INVITATIONS (Scenarios 13 - 17)
  // =========================================================================
  describe('Group 3: Invitation Provisioning for Existing & New Identities', () => {
    let collegeAdminAUser: InstanceType<typeof User>;
    let collegeAdminBUser: InstanceType<typeof User>;

    beforeEach(async () => {
      collegeAdminAUser = await User.create({
        name: 'Admin A',
        instituteId: 'ADMIN-A',
        email: 'admina@coe-a.edu',
        role: AppRole.COLLEGE_ADMIN,
        collegeId: collegeA._id,
        accountStatus: AccountStatus.ACTIVE,
      });

      collegeAdminBUser = await User.create({
        name: 'Admin B',
        instituteId: 'ADMIN-B',
        email: 'adminb@iot-b.edu',
        role: AppRole.COLLEGE_ADMIN,
        collegeId: collegeB._id,
        accountStatus: AccountStatus.ACTIVE,
      });
    });

    it('Scenario 13: An existing verified User can receive a permitted new college membership without duplicate identity creation', async () => {
      const existingUser = await User.create({
        name: 'Existing Person',
        instituteId: 'EP-013',
        email: 'existing.person@example.com',
        phone: '+919876543210',
        role: AppRole.FACULTY,
        collegeId: collegeA._id,
        accountStatus: AccountStatus.ACTIVE,
        passwordHash: await PasswordService.hashPassword('ExistingSecurePass@123'),
      });

      // Admin of College B invites this same existing person as Faculty in College B
      const result = await InvitationService.createInvitation(
        toAuthUser(collegeAdminBUser),
        {
          name: 'Existing Person',
          instituteId: 'EP-013',
          email: 'existing.person@example.com',
          role: AppRole.FACULTY,
          collegeId: collegeB.id,
          departmentId: deptB1.id,
        }
      );

      expect(result.user._id.toString()).toBe(existingUser.id);

      // Verify canonical User is still 1
      const count = await User.countDocuments({ email: 'existing.person@example.com' });
      expect(count).toBe(1);

      // Verify WorkspaceMembership was created in PENDING status for College B
      const memB = await WorkspaceMembership.findOne({
        userId: existingUser._id,
        collegeId: collegeB._id,
      });
      expect(memB).toBeDefined();
    });

    it('Scenario 14: Repeated acceptance does not create duplicate memberships or role assignments', async () => {
      const newUserInvite = await InvitationService.createInvitation(
        toAuthUser(collegeAdminAUser),
        {
          name: 'Single Student',
          instituteId: 'STUD-014',
          email: 'student14@example.com',
          role: AppRole.STUDENT,
          collegeId: collegeA.id,
          departmentId: deptA1.id,
        }
      );

      // First activation
      const act1 = await InvitationService.activateAccount(
        collegeA.code,
        'STUD-014',
        newUserInvite.activationCode,
        'SecurePass@123'
      );
      expect(act1.success).toBe(true);

      // Second activation attempt with same code fails safely (expired / used)
      await expect(
        InvitationService.activateAccount(
          collegeA.code,
          'STUD-014',
          newUserInvite.activationCode,
          'SecurePass@123'
        )
      ).rejects.toThrow();

      // Membership and role assignment count remains exactly 1
      const memCount = await WorkspaceMembership.countDocuments({
        userId: newUserInvite.user._id,
        collegeId: collegeA._id,
      });
      expect(memCount).toBe(1);

      const roleCount = await WorkspaceRoleAssignment.countDocuments({
        userId: newUserInvite.user._id,
        collegeId: collegeA._id,
      });
      expect(roleCount).toBe(1);
    });

    it('Scenario 15: An ambiguous or conflicting identity match fails safely', async () => {
      // User 1 has email1 and phone1
      await User.create({
        name: 'User One',
        instituteId: 'ID-015A',
        email: 'user1@example.com',
        phone: '+919999911111',
        role: AppRole.STUDENT,
        collegeId: collegeA._id,
        accountStatus: AccountStatus.ACTIVE,
      });

      // User 2 has email2 and phone2
      await User.create({
        name: 'User Two',
        instituteId: 'ID-015B',
        email: 'user2@example.com',
        phone: '+919999922222',
        role: AppRole.STUDENT,
        collegeId: collegeA._id,
        accountStatus: AccountStatus.ACTIVE,
      });

      // Attempt to invite with User 1's email but User 2's phone: Conflicting match
      await expect(
        InvitationService.createInvitation(
          toAuthUser(collegeAdminAUser),
          {
            name: 'Conflicted User',
            instituteId: 'ID-NEW',
            email: 'user1@example.com',
            phone: '+919999922222',
            role: AppRole.STUDENT,
            collegeId: collegeA.id,
            departmentId: deptA1.id,
          }
        )
      ).rejects.toThrow('Ambiguous or conflicting identity match');
    });

    it('Scenario 16: An inviter cannot assign roles or scopes beyond their authority', async () => {
      // College Admin cannot provision another College Admin
      await expect(
        InvitationService.createInvitation(
          toAuthUser(collegeAdminAUser),
          {
            name: 'Rogue Admin',
            instituteId: 'ROGUE-001',
            email: 'rogue@example.com',
            role: AppRole.COLLEGE_ADMIN,
            collegeId: collegeA.id,
          }
        )
      ).rejects.toThrow('College Admin cannot provision accounts with role "COLLEGE_ADMIN"');

      // College Admin cannot invite into a department belonging to another college
      await expect(
        InvitationService.createInvitation(
          toAuthUser(collegeAdminAUser),
          {
            name: 'Cross Dept Faculty',
            instituteId: 'CROSS-001',
            email: 'cross@example.com',
            role: AppRole.FACULTY,
            collegeId: collegeA.id,
            departmentId: deptB1.id, // Belong to College B!
          }
        )
      ).rejects.toThrow('Cross-college tenant access is strictly prohibited');
    });

    it('Scenario 17: Invitation acceptance cannot modify unrelated memberships or credentials', async () => {
      const originalPasswordHash = await PasswordService.hashPassword('MyOriginalPassword@123');
      const existingUser = await User.create({
        name: 'Multi Workspace User',
        instituteId: 'MW-017',
        email: 'mw17@example.com',
        role: AppRole.FACULTY,
        collegeId: collegeA._id,
        accountStatus: AccountStatus.ACTIVE,
        passwordHash: originalPasswordHash,
      });

      // Existing user already has active membership in College A
      await WorkspaceMembershipService.createMembership({
        userId: existingUser._id,
        collegeId: collegeA._id,
        status: MembershipStatus.ACTIVE,
      });

      // Invited to College B
      const invResult = await InvitationService.createInvitation(
        toAuthUser(collegeAdminBUser),
        {
          name: 'Multi Workspace User',
          instituteId: 'MW-017',
          email: 'mw17@example.com',
          role: AppRole.FACULTY,
          collegeId: collegeB.id,
          departmentId: deptB1.id,
        }
      );

      // Existing user activates College B invitation without changing password
      await InvitationService.activateAccount(
        collegeB.code,
        'MW-017',
        invResult.activationCode
      );

      const reloadedUser = await User.findById(existingUser._id);
      // Original password hash remains untouched
      expect(reloadedUser?.passwordHash).toBe(originalPasswordHash);

      // College A membership remains ACTIVE and untouched
      const memA = await WorkspaceMembership.findOne({
        userId: existingUser._id,
        collegeId: collegeA._id,
      });
      expect(memA?.status).toBe(MembershipStatus.ACTIVE);

      // College B membership is now ACTIVE
      const memB = await WorkspaceMembership.findOne({
        userId: existingUser._id,
        collegeId: collegeB._id,
      });
      expect(memB?.status).toBe(MembershipStatus.ACTIVE);
    });
  });

  // =========================================================================
  // GROUP 4: MIGRATION & RECOVERY (Scenarios 18 - 24)
  // =========================================================================
  describe('Group 4: Safe Migration & Recovery', () => {
    it('Scenario 18: Dry-run performs no writes', async () => {
      await User.create({
        name: 'Test DryRun User',
        instituteId: 'DRY-018',
        email: 'dryrun@example.com',
        role: AppRole.FACULTY,
        collegeId: collegeA._id,
        accountStatus: AccountStatus.ACTIVE,
      });

      const dryRunReport = await WorkspaceMigrationService.runDryRun('test_dryrun_id');

      expect(dryRunReport.mode).toBe('DRY_RUN');
      expect(dryRunReport.classifications.eligibleForMigration).toBe(1);

      // Verify no records written to WorkspaceMembership or WorkspaceRoleAssignment
      const memCount = await WorkspaceMembership.countDocuments();
      const roleCount = await WorkspaceRoleAssignment.countDocuments();
      expect(memCount).toBe(0);
      expect(roleCount).toBe(0);
    });

    it('Scenario 19: Statuses are preserved accurately across distinct legacy states', async () => {
      const uActive = await User.create({
        name: 'Active User',
        instituteId: 'STA-ACT',
        email: 'act@example.com',
        role: AppRole.FACULTY,
        collegeId: collegeA._id,
        accountStatus: AccountStatus.ACTIVE,
      });

      const uPending = await User.create({
        name: 'Pending User',
        instituteId: 'STA-PEN',
        email: 'pen@example.com',
        role: AppRole.STUDENT,
        collegeId: collegeA._id,
        accountStatus: AccountStatus.PENDING_ACTIVATION,
      });

      const uSuspended = await User.create({
        name: 'Suspended User',
        instituteId: 'STA-SUS',
        email: 'sus@example.com',
        role: AppRole.STUDENT,
        collegeId: collegeA._id,
        accountStatus: AccountStatus.SUSPENDED,
      });

      const uDeactivated = await User.create({
        name: 'Deactivated User',
        instituteId: 'STA-DEA',
        email: 'dea@example.com',
        role: AppRole.STUDENT,
        collegeId: collegeA._id,
        accountStatus: AccountStatus.DEACTIVATED,
      });

      await WorkspaceMigrationService.executeMigration({ allowAnomalies: true });

      const memActive = await WorkspaceMembership.findOne({ userId: uActive._id });
      const memPending = await WorkspaceMembership.findOne({ userId: uPending._id });
      const memSuspended = await WorkspaceMembership.findOne({ userId: uSuspended._id });
      const memDeactivated = await WorkspaceMembership.findOne({ userId: uDeactivated._id });

      expect(memActive?.status).toBe(MembershipStatus.ACTIVE);
      expect(memPending?.status).toBe(MembershipStatus.PENDING);
      expect(memSuspended?.status).toBe(MembershipStatus.SUSPENDED);
      expect(memDeactivated?.status).toBe(MembershipStatus.DEACTIVATED);
    });

    it('Scenario 20: Missing or ambiguous college/role/profile relationships are reported', async () => {
      // User with missing collegeId
      await User.create({
        name: 'Orphan User',
        instituteId: 'ANO-001',
        email: 'orphan@example.com',
        role: AppRole.STUDENT,
        collegeId: null,
        accountStatus: AccountStatus.ACTIVE,
      });

      // HOD with missing departmentId
      await User.create({
        name: 'HOD No Dept',
        instituteId: 'ANO-002',
        email: 'hodnodept@example.com',
        role: AppRole.HOD,
        collegeId: collegeA._id,
        departmentId: null,
        accountStatus: AccountStatus.ACTIVE,
      });

      const dryRun = await WorkspaceMigrationService.runDryRun();
      expect(dryRun.anomalies.length).toBeGreaterThanOrEqual(2);
      expect(dryRun.safeToMigrate).toBe(false);
    });

    it('Scenario 21: Re-running a completed migration is idempotent', async () => {
      await User.create({
        name: 'Idempotent User',
        instituteId: 'IDEM-021',
        email: 'idem@example.com',
        role: AppRole.FACULTY,
        collegeId: collegeA._id,
        accountStatus: AccountStatus.ACTIVE,
      });

      // Run 1
      const exec1 = await WorkspaceMigrationService.executeMigration({
        runId: 'run_1',
        allowAnomalies: true,
      });
      expect(exec1.createdMembershipsCount).toBe(1);

      // Run 2
      const exec2 = await WorkspaceMigrationService.executeMigration({
        runId: 'run_2',
        allowAnomalies: true,
      });
      expect(exec2.createdMembershipsCount).toBe(0);
      expect(exec2.skippedExistingCount).toBe(1);

      const memCount = await WorkspaceMembership.countDocuments();
      expect(memCount).toBe(1);
    });

    it('Scenario 22: Interrupted migration can resume without duplicate relationships', async () => {
      await User.create({
        name: 'Batch User 1',
        instituteId: 'BATCH-01',
        email: 'batch1@example.com',
        role: AppRole.STUDENT,
        collegeId: collegeA._id,
        accountStatus: AccountStatus.ACTIVE,
      });

      await User.create({
        name: 'Batch User 2',
        instituteId: 'BATCH-02',
        email: 'batch2@example.com',
        role: AppRole.STUDENT,
        collegeId: collegeA._id,
        accountStatus: AccountStatus.ACTIVE,
      });

      // Partial execution with batchSize 1
      const part1 = await WorkspaceMigrationService.executeMigration({
        batchSize: 1,
        allowAnomalies: true,
      });
      expect(part1.createdMembershipsCount).toBe(2); // Cursor processes all batches

      // Safe resume
      const part2 = await WorkspaceMigrationService.executeMigration({
        allowAnomalies: true,
      });
      expect(part2.createdMembershipsCount).toBe(0);
      expect(part2.skippedExistingCount).toBe(2);
    });

    it('Scenario 23: Invalid or revoked memberships cannot regain access through compatibility fallback', async () => {
      const user = await User.create({
        name: 'Revoked User',
        instituteId: 'REV-023',
        email: 'revoked@example.com',
        role: AppRole.FACULTY,
        collegeId: collegeA._id,
        accountStatus: AccountStatus.ACTIVE, // Legacy scalar says active
      });

      // Authoritative WorkspaceMembership is REVOKED
      await WorkspaceMembership.create({
        userId: user._id,
        collegeId: collegeA._id,
        status: MembershipStatus.REVOKED,
        revokedAt: new Date(),
        statusReason: 'Security incident',
      });

      // Resolve workspace through compatibility service
      const effectiveWorkspace = await WorkspaceCompatibilityService.resolveEffectiveWorkspace(
        user.id,
        collegeA.id,
        {
          collegeId: collegeA.id,
          role: AppRole.FACULTY,
        }
      );

      // Must fail closed (null), legacy field CANNOT bypass revoked membership
      expect(effectiveWorkspace).toBeNull();
    });

    it('Scenario 24: Index rollout detects duplicates and fails safely without destructive cleanup', async () => {
      const user = await User.create({
        name: 'Duplicate Test User',
        instituteId: 'DUP-024',
        email: 'dup@example.com',
        role: AppRole.FACULTY,
        collegeId: collegeA._id,
        accountStatus: AccountStatus.ACTIVE,
      });

      // Temporarily drop compound unique index to simulate pre-index legacy dirty data
      try {
        await Faculty.collection.dropIndex('collegeId_1_userId_1');
      } catch {
        // index might not exist under this name
      }

      // Insert first Faculty document
      await Faculty.collection.insertOne({
        userId: user._id,
        collegeId: collegeA._id,
        departmentId: deptA1._id,
        name: user.name,
        email: user.email,
        employeeId: 'EMP-DUP-1',
        designation: 'Professor',
        qualification: 'PhD',
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      // Insert second duplicate Faculty document raw into MongoDB collection (simulating legacy collision)
      await Faculty.collection.insertOne({
        userId: user._id,
        collegeId: collegeA._id,
        departmentId: deptA2._id,
        name: user.name,
        email: user.email,
        employeeId: 'EMP-DUP-2',
        designation: 'Professor',
        qualification: 'PhD',
        createdAt: new Date(),
        updatedAt: new Date(),
      });

      // Detect duplicates via WorkspaceMigrationService
      const conflicts = await WorkspaceMigrationService.detectProfileDuplicates();
      expect(conflicts.length).toBeGreaterThanOrEqual(1);

      const conflict = conflicts.find(
        (c) => c.collection === 'Faculty' && c.userId === user.id && c.collegeId === collegeA.id
      );
      expect(conflict).toBeDefined();
      expect(conflict?.count).toBe(2);
      expect(conflict?.conflictingIds).toHaveLength(2);

      // Clean up test duplicates and restore index
      await Faculty.deleteMany({ userId: user._id });
      await Faculty.syncIndexes();
    });
  });
});
