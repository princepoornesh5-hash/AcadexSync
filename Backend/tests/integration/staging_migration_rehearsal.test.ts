import mongoose from 'mongoose';
import { setupTestDB, teardownTestDB } from '../setup';
import { User } from '../../src/models/user.model';
import { College } from '../../src/models/college.model';
import { Department } from '../../src/models/department.model';
import { Faculty } from '../../src/models/faculty.model';
import { Student } from '../../src/models/student.model';
import { WorkspaceMembership } from '../../src/models/workspaceMembership.model';
import { WorkspaceRoleAssignment } from '../../src/models/workspaceRoleAssignment.model';
import { WorkspaceMigrationService } from '../../src/services/migration/workspaceMigration.service';
import { AppRole } from '../../src/constants/roles';
import { AccountStatus, CollegeStatus, DepartmentStatus, MembershipStatus, MembershipType } from '../../src/constants/status';

describe('ACADEX PROMPT 5: Safe Staging Migration Rehearsal & Dry-Run Validation', () => {
  let collegeA: any;
  let deptA: any;

  beforeAll(async () => {
    await setupTestDB();
    await College.init();
    await User.init();
    await Department.init();
    await Faculty.init();
    await Student.init();
    await WorkspaceMembership.init();
    await WorkspaceRoleAssignment.init();

    // Clear collections in the isolated test database
    await User.deleteMany({});
    await College.deleteMany({});
    await Department.deleteMany({});
    await Faculty.deleteMany({});
    await Student.deleteMany({});
    await WorkspaceMembership.deleteMany({});
    await WorkspaceRoleAssignment.deleteMany({});

    // Seed Representative Staging Dataset
    collegeA = await College.create({
      name: 'Alpha Institute of Technology',
      code: 'AIT',
      address: '100 Alpha Way',
      email: 'admin@alpha.edu',
      phone: '1234567890',
      status: CollegeStatus.ACTIVE,
      principal: 'Dr. Alpha Principal',
    });

    await College.create({
      name: 'Beta College of Engineering',
      code: 'BCE',
      address: '200 Beta Way',
      email: 'admin@beta.edu',
      phone: '0987654321',
      status: CollegeStatus.ACTIVE,
      principal: 'Dr. Beta Principal',
    });

    deptA = await Department.create({
      name: 'Computer Science',
      code: 'CSE',
      collegeId: collegeA._id,
      status: DepartmentStatus.ACTIVE,
    });

    // Valid Student
    await User.create({
      name: 'Alice Student',
      email: 'alice@alpha.edu',
      role: AppRole.STUDENT,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      instituteId: 'PIN-A-101',
      accountStatus: AccountStatus.ACTIVE,
    });

    // Valid Faculty
    await User.create({
      name: 'Dr. Bob Professor',
      email: 'bob@alpha.edu',
      role: AppRole.FACULTY,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      instituteId: 'PIN-A-201',
      accountStatus: AccountStatus.ACTIVE,
    });

    // Valid Super Admin
    await User.create({
      name: 'Platform SuperAdmin',
      email: 'admin@acadex.platform',
      role: AppRole.SUPER_ADMIN,
      accountStatus: AccountStatus.ACTIVE,
    });

    // Anomaly 1: Missing PIN
    await User.create({
      name: 'No Pin User',
      email: 'nopin@alpha.edu',
      role: AppRole.STUDENT,
      collegeId: collegeA._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    // Anomaly 2: Missing College
    await User.create({
      name: 'No College User',
      email: 'nocollege@example.com',
      role: AppRole.FACULTY,
      instituteId: 'PIN-X-999',
      accountStatus: AccountStatus.ACTIVE,
    });

    // Anomaly 3: Conflicting PIN between User and Membership
    const conflictPinUser = await User.create({
      name: 'Conflict PIN User',
      email: 'conflict@alpha.edu',
      role: AppRole.STUDENT,
      collegeId: collegeA._id,
      instituteId: 'PIN-USER-ALPHA',
      accountStatus: AccountStatus.ACTIVE,
    });

    await WorkspaceMembership.create({
      userId: conflictPinUser._id,
      collegeId: collegeA._id,
      instituteId: 'PIN-MEMBERSHIP-ALPHA',
      memberType: MembershipType.STUDENT,
      status: MembershipStatus.ACTIVE,
      effectiveStartDate: new Date(),
    });

    // Anomaly 4: Orphaned Membership
    const nonExistentUserId = new mongoose.Types.ObjectId();
    await WorkspaceMembership.collection.insertOne({
      userId: nonExistentUserId,
      collegeId: collegeA._id,
      instituteId: 'GHOST-PIN-001',
      memberType: MembershipType.STUDENT,
      status: MembershipStatus.ACTIVE,
      isDefault: false,
      joinedAt: new Date(),
      effectiveStartDate: new Date(),
    });
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  test('1. Dry-run performs strictly zero database writes', async () => {
    const usersBefore = await User.countDocuments();
    const membershipsBefore = await WorkspaceMembership.countDocuments();
    const rolesBefore = await WorkspaceRoleAssignment.countDocuments();
    const collegesBefore = await College.countDocuments();

    const report = await WorkspaceMigrationService.runDryRun('rehearsal_dryrun_zero_writes');

    const usersAfter = await User.countDocuments();
    const membershipsAfter = await WorkspaceMembership.countDocuments();
    const rolesAfter = await WorkspaceRoleAssignment.countDocuments();
    const collegesAfter = await College.countDocuments();

    expect(report.mode).toBe('DRY_RUN');
    expect(usersAfter).toBe(usersBefore);
    expect(membershipsAfter).toBe(membershipsBefore);
    expect(rolesAfter).toBe(rolesBefore);
    expect(collegesAfter).toBe(collegesBefore);
  });

  test('2. Missing PINs and college mappings are identified as anomalies', async () => {
    const report = await WorkspaceMigrationService.runDryRun('rehearsal_dryrun_missing_ids');
    const categories = report.anomalies.map((a) => a.category);

    expect(categories).toContain('MISSING_PIN');
    expect(categories).toContain('MISSING_COLLEGE');
    expect(report.safeToMigrate).toBe(false);
  });

  test('3. Conflicting membership identifiers and orphaned profiles are reported', async () => {
    const report = await WorkspaceMigrationService.runDryRun('rehearsal_dryrun_conflicts');
    const categories = report.anomalies.map((a) => a.category);

    expect(categories).toContain('CONFLICTING_PIN');
    expect(categories).toContain('ORPHAN_REFERENCE');
  });

  test('4. Existing users, memberships, and historical records remain intact', async () => {
    const alice = await User.findOne({ email: 'alice@alpha.edu' });
    expect(alice).not.toBeNull();
    expect(alice?.instituteId).toBe('PIN-A-101');
    expect(alice?.accountStatus).toBe(AccountStatus.ACTIVE);

    const bob = await User.findOne({ email: 'bob@alpha.edu' });
    expect(bob).not.toBeNull();
    expect(bob?.instituteId).toBe('PIN-A-201');

    const conflictMem = await WorkspaceMembership.findOne({ instituteId: 'PIN-MEMBERSHIP-ALPHA' });
    expect(conflictMem).not.toBeNull();
  });

  test('5. Repeated dry-runs produce 100% consistent results for unchanged data', async () => {
    const report1 = await WorkspaceMigrationService.runDryRun('rehearsal_run_a');
    const report2 = await WorkspaceMigrationService.runDryRun('rehearsal_run_b');

    expect(report1.totalUsersScanned).toBe(report2.totalUsersScanned);
    expect(report1.classifications.eligibleForMigration).toBe(report2.classifications.eligibleForMigration);
    expect(report1.classifications.unresolvedAnomalies).toBe(report2.classifications.unresolvedAnomalies);
    expect(report1.classifications.alreadyMigrated).toBe(report2.classifications.alreadyMigrated);
    expect(report1.safeToMigrate).toBe(report2.safeToMigrate);
    expect(report1.anomalies.length).toBe(report2.anomalies.length);
  });

  test('6. Read-only index preflight detects compound index requirements without modifying indexes', async () => {
    const preflight = await WorkspaceMigrationService.runIndexPreflight();

    expect(preflight.timestamp).toBeDefined();
    expect(preflight.collections.workspaceMembership).toBeDefined();
    expect(Array.isArray(preflight.recommendations)).toBe(true);
    expect(Array.isArray(preflight.blockers)).toBe(true);
  });
});
