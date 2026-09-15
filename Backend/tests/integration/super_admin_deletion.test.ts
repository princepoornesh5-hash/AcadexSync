import request from 'supertest';
import { app } from '../../src/app';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { User } from '../../src/models/user.model';
import { College } from '../../src/models/college.model';
import { Department } from '../../src/models/department.model';
import { AuthSession } from '../../src/models/authSession.model';
import { AuditLog } from '../../src/models/auditLog.model';
import { signAccessToken } from '../../src/utils/token';
import { PasswordService } from '../../src/services/password.service';
import { AppRole } from '../../src/constants/roles';
import { AccountStatus, CollegeStatus } from '../../src/constants/status';

describe('Super Admin Permanent Deletion Integration Tests', () => {
  let superAdminUser: any;
  let superAdminToken: string;
  let collegeAdminUser: any;
  let collegeAdminToken: string;
  let testCollege: any;
  let targetUser: any;

  beforeAll(async () => {
    await setupTestDB();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();

    const passwordHash = await PasswordService.hashPassword('Password@123');

    // Create Super Admin
    superAdminUser = await User.create({
      name: 'Super Admin',
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

    // Create Test College
    testCollege = await College.create({
      name: 'Engineering Tech College',
      code: 'ETC',
      address: '100 University Ave',
      email: 'admin@etc.edu',
      phone: '1234567890',
      principal: 'Dr. Smith',
      status: CollegeStatus.ACTIVE,
      isActive: true,
      createdBy: superAdminUser.id,
      updatedBy: superAdminUser.id,
    });

    // Create College Admin
    collegeAdminUser = await User.create({
      name: 'College Admin',
      email: 'admin@etc.edu',
      instituteId: 'ETC-ADM-01',
      role: AppRole.COLLEGE_ADMIN,
      passwordHash,
      accountStatus: AccountStatus.ACTIVE,
      activationStatus: 'activated',
      collegeId: testCollege.id,
    });
    collegeAdminToken = signAccessToken({
      userId: collegeAdminUser.id,
      email: collegeAdminUser.email,
      role: collegeAdminUser.role,
      collegeId: testCollege.id.toString(),
    });

    // Create Target User
    targetUser = await User.create({
      name: 'John Student',
      email: 'john@etc.edu',
      instituteId: 'ETC-STU-01',
      role: AppRole.STUDENT,
      passwordHash,
      accountStatus: AccountStatus.ACTIVE,
      activationStatus: 'activated',
      collegeId: testCollege.id,
    });

    // Create a dummy session for targetUser
    await AuthSession.create({
      sessionId: 'sess_123',
      userId: targetUser.id,
      refreshTokenHash: 'dummy_hash',
      expiresAt: new Date(Date.now() + 86400000),
      ipAddress: '127.0.0.1',
      userAgent: 'JestTest',
    });
  });

  describe('User Permanent Deletion (DELETE /api/v1/users/:id)', () => {
    it('1. Super Admin can permanently delete a user and their sessions', async () => {
      const res = await request(app)
        .delete(`/api/v1/users/${targetUser.id}`)
        .set('Authorization', `Bearer ${superAdminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.message).toContain('User permanently deleted successfully');

      // Check DB: user removed
      const foundUser = await User.findById(targetUser.id);
      expect(foundUser).toBeNull();

      // Check DB: sessions removed
      const sessions = await AuthSession.find({ userId: targetUser.id });
      expect(sessions.length).toBe(0);

      // Check DB: audit log created
      const audit = await AuditLog.findOne({
        action: 'USER_PERMANENTLY_DELETED',
        entityId: targetUser.id,
      });
      expect(audit).not.toBeNull();
      expect(audit?.actorUserId.toString()).toBe(superAdminUser.id);
    });

    it('2. Super Admin cannot delete their own account (self-deletion protection)', async () => {
      const res = await request(app)
        .delete(`/api/v1/users/${superAdminUser.id}`)
        .set('Authorization', `Bearer ${superAdminToken}`);

      expect(res.status).toBe(400);
      expect(res.body.error.message).toContain('cannot delete their own account');
    });

    it('3. Non-Super Admin receives 403 Forbidden when attempting to delete a user', async () => {
      const res = await request(app)
        .delete(`/api/v1/users/${targetUser.id}`)
        .set('Authorization', `Bearer ${collegeAdminToken}`);

      expect(res.status).toBe(403);
      const foundUser = await User.findById(targetUser.id);
      expect(foundUser).not.toBeNull();
    });
  });

  describe('College Permanent Deletion (DELETE /api/v1/colleges/:id)', () => {
    it('4. Super Admin can permanently delete a college and cascade delete departments and users', async () => {
      // Create a department under the college
      const dept = await Department.create({
        name: 'Computer Science',
        code: 'CS',
        collegeId: testCollege.id,
      });

      const res = await request(app)
        .delete(`/api/v1/colleges/${testCollege.id}`)
        .set('Authorization', `Bearer ${superAdminToken}`);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.message).toContain('College permanently deleted successfully');

      // Check DB: college removed
      const foundCollege = await College.findById(testCollege.id);
      expect(foundCollege).toBeNull();

      // Check DB: department removed
      const foundDept = await Department.findById(dept.id);
      expect(foundDept).toBeNull();

      // Check DB: college users removed
      const foundTargetUser = await User.findById(targetUser.id);
      expect(foundTargetUser).toBeNull();

      // Check DB: audit log created
      const audit = await AuditLog.findOne({
        action: 'COLLEGE_PERMANENTLY_DELETED',
        entityId: testCollege.id,
      });
      expect(audit).not.toBeNull();
      expect(audit?.actorUserId.toString()).toBe(superAdminUser.id);
    });

    it('5. Non-Super Admin receives 403 Forbidden when attempting to delete a college', async () => {
      const res = await request(app)
        .delete(`/api/v1/colleges/${testCollege.id}`)
        .set('Authorization', `Bearer ${collegeAdminToken}`);

      expect(res.status).toBe(403);
      const foundCollege = await College.findById(testCollege.id);
      expect(foundCollege).not.toBeNull();
    });
  });
});
