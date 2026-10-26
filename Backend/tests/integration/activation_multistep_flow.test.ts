import request from 'supertest';
import { app } from '../../src/app';
import { User } from '../../src/models/user.model';
import { College } from '../../src/models/college.model';
import { Department } from '../../src/models/department.model';
import { Invitation } from '../../src/models/invitation.model';
import { Otp } from '../../src/models/otp.model';
import { WorkspaceMembership } from '../../src/models/workspaceMembership.model';
import { WorkspaceRoleAssignment } from '../../src/models/workspaceRoleAssignment.model';
import { AuditLog } from '../../src/models/auditLog.model';
import { AppRole } from '../../src/constants/roles';
import {
  AccountStatus,
  InvitationStatus,
  MembershipStatus,
  RoleAssignmentStatus,
} from '../../src/constants/status';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';
import { PasswordService } from '../../src/services/password.service';
import {
  OtpDeliveryService,
  DevOtpDeliveryAdapter,
  IOtpDeliveryAdapter,
  SendOtpOptions,
} from '../../src/services/otpDelivery.service';
import {
  verifyActivationCompletionToken,
  signActivationCompletionToken,
  signAccessToken,
} from '../../src/utils/token';

describe('ACADEX Multi-Step Account Activation Engine (Prompt 2 Verification Suite)', () => {
  let collegeA: InstanceType<typeof College>;
  let collegeB: InstanceType<typeof College>;
  let deptA1: InstanceType<typeof Department>;
  let superAdminUser: InstanceType<typeof User>;
  let collegeAdminA: InstanceType<typeof User>;
  let superAdminHeader: { Authorization: string };
  let collegeAdminAHeader: { Authorization: string };

  const defaultPassword = 'DefaultTestPassword123';
  let defaultPasswordHash: string;

  beforeAll(async () => {
    await setupTestDB();
    await User.init();
    await College.init();
    await Department.init();
    await Invitation.init();
    await Otp.init();
    await WorkspaceMembership.init();
    await WorkspaceRoleAssignment.init();
    await AuditLog.init();

    defaultPasswordHash = await PasswordService.hashPassword(defaultPassword);
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();
    (OtpDeliveryService.getAdapter() as DevOtpDeliveryAdapter).clear();

    // 1. Setup Colleges
    collegeA = await College.create({
      name: 'SVGP Engineering College',
      code: 'SVGP',
      address: '123 Alpha Way',
      email: 'contact@svgp.edu',
      phone: '1112223333',
      principal: 'Dr. Alpha Principal',
      status: 'active',
    });

    collegeB = await College.create({
      name: 'Beta Institute of Technology',
      code: 'BETA',
      address: '456 Beta Blvd',
      email: 'contact@beta.edu',
      phone: '4445556666',
      principal: 'Dr. Beta Principal',
      status: 'active',
    });

    // 2. Setup Department
    deptA1 = await Department.create({
      name: 'Computer Science and Engineering',
      code: 'CSE',
      collegeId: collegeA._id,
      status: 'active',
    });

    // 3. Setup Super Admin
    superAdminUser = await User.create({
      instituteId: 'SA-001',
      name: 'Super Admin',
      email: 'superadmin@acadex.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.SUPER_ADMIN,
      accountStatus: AccountStatus.ACTIVE,
    });

    // 4. Setup College Admin for College A
    collegeAdminA = await User.create({
      instituteId: 'ADM-SVGP-01',
      name: 'Admin SVGP',
      email: 'admin@svgp.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.COLLEGE_ADMIN,
      collegeId: collegeA._id,
      accountStatus: AccountStatus.ACTIVE,
    });

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
  });

  // Helper: Create invitation through authoritative endpoint
  async function createTestInvitation(overrides: Record<string, unknown> = {}) {
    const payload = {
      name: 'John Doe',
      instituteId: 'STU-2026-001',
      email: 'johndoe@svgp.edu',
      phone: '+919876543210',
      role: AppRole.STUDENT,
      departmentId: deptA1.id,
      collegeId: collegeA.id,
      ...overrides,
    };

    const res = await request(app)
      .post('/api/v1/auth/invitations')
      .set(collegeAdminAHeader)
      .send(payload);

    return {
      response: res,
      activationCode: res.body.data.activationCode as string,
      invitation: res.body.data.invitation,
      user: res.body.data.user,
    };
  }

  // =========================================================================
  // 1 & 2. ACTIVATION CODE VALIDATION ENDPOINT
  // =========================================================================

  it('1. Activation code validation succeeds without College Code or Institute ID', async () => {
    const { activationCode } = await createTestInvitation();

    // Call validate-code with only activationCode
    const res = await request(app)
      .post('/api/v1/auth/activate/validate-code')
      .send({ activationCode });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.activationFlowId).toBeDefined();
    expect(res.body.data.displayName).toBe('John Doe');
    expect(res.body.data.institutionName).toBe('SVGP Engineering College');
    expect(res.body.data.role).toBe(AppRole.STUDENT);
    expect(res.body.data.contactOptions).toHaveLength(2);
    expect(res.body.data.contactOptions).toContainEqual({
      method: 'email',
      maskedValue: expect.stringMatching(/^j\*{3}e@svgp\.edu$/),
    });
    expect(res.body.data.contactOptions).toContainEqual({
      method: 'phone',
      maskedValue: expect.stringMatching(/^\+91.*210$/),
    });
    expect(res.body.data.isExistingUser).toBe(false);
  });

  it('2. Invalid, expired, revoked, and consumed activation codes are strictly rejected', async () => {
    const { activationCode, invitation } = await createTestInvitation();

    // 2a. Arbitrary non-existent code
    const invalidRes = await request(app)
      .post('/api/v1/auth/activate/validate-code')
      .send({ activationCode: 'XXXX-YYYY-ZZZZ' });
    expect(invalidRes.status).toBe(400);
    expect(invalidRes.body.error.message).toContain('Invalid or unknown activation code');

    // 2b. Malformed code format
    const malformedRes = await request(app)
      .post('/api/v1/auth/activate/validate-code')
      .send({ activationCode: 'short' });
    expect(malformedRes.status).toBe(400);
    expect(malformedRes.body.error.message).toContain('Activation code must be formatted');

    // 2c. Expired invitation
    await Invitation.findByIdAndUpdate(invitation.id, {
      expiresAt: new Date(Date.now() - 3600000), // 1 hour ago
    });
    const expiredRes = await request(app)
      .post('/api/v1/auth/activate/validate-code')
      .send({ activationCode });
    expect(expiredRes.status).toBe(400);
    expect(expiredRes.body.error.message).toContain('has expired');

    // 2d. Revoked invitation
    await Invitation.findByIdAndUpdate(invitation.id, {
      status: InvitationStatus.REVOKED,
      expiresAt: new Date(Date.now() + 86400000),
    });
    const revokedRes = await request(app)
      .post('/api/v1/auth/activate/validate-code')
      .send({ activationCode });
    expect(revokedRes.status).toBe(400);
    expect(revokedRes.body.error.message).toContain('has been revoked');

    // 2e. Consumed invitation
    await Invitation.findByIdAndUpdate(invitation.id, {
      status: InvitationStatus.USED,
      usedAt: new Date(),
    });
    const consumedRes = await request(app)
      .post('/api/v1/auth/activate/validate-code')
      .send({ activationCode });
    expect(consumedRes.status).toBe(400);
    expect(consumedRes.body.error.message).toContain('already been used');
  });

  // =========================================================================
  // 3. IDENTITY CONFIRMATION RESPONSE MINIMIZATION
  // =========================================================================

  it('3. Identity confirmation response never exposes internal credentials or secrets', async () => {
    const { activationCode } = await createTestInvitation();

    const res = await request(app)
      .post('/api/v1/auth/activate/validate-code')
      .send({ activationCode });

    expect(res.status).toBe(200);
    const data = res.body.data;

    // Explicitly verify sensitive fields are ABSENT
    expect(data.passwordHash).toBeUndefined();
    expect(data.password).toBeUndefined();
    expect(data.codeHash).toBeUndefined();
    expect(data.rawActivationCode).toBeUndefined();
    expect(data.otp).toBeUndefined();
    expect(data.secret).toBeUndefined();
    expect(data.accessToken).toBeUndefined();
    expect(data.refreshToken).toBeUndefined();

    // Verify raw unmasked email/phone are never returned
    expect(JSON.stringify(data)).not.toContain('johndoe@svgp.edu');
    expect(JSON.stringify(data)).not.toContain('+919876543210');
  });

  // =========================================================================
  // 4 & 5. CONTACT SELECTION AND OTP DISPATCH
  // =========================================================================

  it('4. OTP is delivered through configured adapter with resend cooldown enforced', async () => {
    const { activationCode } = await createTestInvitation();

    const valRes = await request(app)
      .post('/api/v1/auth/activate/validate-code')
      .send({ activationCode });

    const flowId = valRes.body.data.activationFlowId;

    // Dispatch OTP via email
    const otpRes = await request(app)
      .post('/api/v1/auth/activate/send-otp')
      .send({
        activationFlowId: flowId,
        contactMethod: 'email',
      });

    expect(otpRes.status).toBe(200);
    expect(otpRes.body.success).toBe(true);
    expect(otpRes.body.data.maskedDestination).toMatch(/^j\*{3}e@svgp\.edu$/);

    // Verify adapter received OTP
    const adapter = OtpDeliveryService.getAdapter() as DevOtpDeliveryAdapter;
    const deliveredOtp = adapter.getLastOtp('johndoe@svgp.edu');
    expect(deliveredOtp).toBeDefined();
    expect(deliveredOtp).toMatch(/^\d{6}$/);

    // Resend cooldown enforcement (within 60s)
    const immediateResend = await request(app)
      .post('/api/v1/auth/activate/send-otp')
      .send({
        activationFlowId: flowId,
        contactMethod: 'email',
      });

    expect(immediateResend.status).toBe(429);
    expect(immediateResend.body.error.message).toContain('Please wait');
  });

  it('5. Missing delivery configuration fails safely without fake confirmation', async () => {
    const { activationCode } = await createTestInvitation();

    const valRes = await request(app)
      .post('/api/v1/auth/activate/validate-code')
      .send({ activationCode });
    const flowId = valRes.body.data.activationFlowId;

    // Mock a failing delivery adapter
    const originalAdapter = OtpDeliveryService.getAdapter();
    const failingAdapter: IOtpDeliveryAdapter = {
      async sendOtp(_options: SendOtpOptions): Promise<boolean> {
        return false; // Delivery rejected by provider
      },
    };
    OtpDeliveryService.setAdapter(failingAdapter);

    try {
      const otpRes = await request(app)
        .post('/api/v1/auth/activate/send-otp')
        .send({
          activationFlowId: flowId,
          contactMethod: 'email',
        });

      expect(otpRes.status).toBe(500);
      expect(otpRes.body.error.message).toContain('Failed to deliver verification code');
    } finally {
      OtpDeliveryService.setAdapter(originalAdapter);
    }
  });

  // =========================================================================
  // 6, 7 & 8. OTP VERIFICATION ENDPOINT
  // =========================================================================

  it('6. OTP expiry and maximum verification attempt limits are enforced', async () => {
    const { activationCode } = await createTestInvitation();

    const valRes = await request(app)
      .post('/api/v1/auth/activate/validate-code')
      .send({ activationCode });
    const flowId = valRes.body.data.activationFlowId;

    await request(app)
      .post('/api/v1/auth/activate/send-otp')
      .send({ activationFlowId: flowId, contactMethod: 'email' });

    // 6a. Attempt limits: submit wrong OTP until limit is reached
    for (let i = 0; i < 4; i++) {
      const wrongRes = await request(app)
        .post('/api/v1/auth/activate/verify-otp')
        .send({
          activationFlowId: flowId,
          contactMethod: 'email',
          otp: '000000',
        });
      expect(wrongRes.status).toBe(400);
    }

    // 5th attempt exceeds max attempts
    const lockedRes = await request(app)
      .post('/api/v1/auth/activate/verify-otp')
      .send({
        activationFlowId: flowId,
        contactMethod: 'email',
        otp: '000000',
      });
    expect(lockedRes.status).toBe(400);
    expect(lockedRes.body.error.message).toContain('Maximum verification attempts exceeded');

    // 6b. Expiry check on a fresh OTP
    const { activationCode: code2 } = await createTestInvitation({
      instituteId: 'STU-EXP-001',
      email: 'exp@svgp.edu',
      phone: '+919876543299',
    });
    const valRes2 = await request(app)
      .post('/api/v1/auth/activate/validate-code')
      .send({ activationCode: code2 });
    const flowId2 = valRes2.body.data.activationFlowId;

    await request(app)
      .post('/api/v1/auth/activate/send-otp')
      .send({ activationFlowId: flowId2, contactMethod: 'email' });

    // Expire the OTP record in MongoDB
    await Otp.updateMany(
      { destination: 'exp@svgp.edu' },
      { $set: { expiresAt: new Date(Date.now() - 1000) } }
    );

    const adapter = OtpDeliveryService.getAdapter() as DevOtpDeliveryAdapter;
    const otpExp = adapter.getLastOtp('exp@svgp.edu');

    const expRes = await request(app)
      .post('/api/v1/auth/activate/verify-otp')
      .send({
        activationFlowId: flowId2,
        contactMethod: 'email',
        otp: otpExp,
      });
    expect(expRes.status).toBe(400);
    expect(expRes.body.error.message).toContain('has expired');
  });

  it('7 & 8. OTP replay is prevented and verification is bound to flow & contact method', async () => {
    const { activationCode } = await createTestInvitation();

    const valRes = await request(app)
      .post('/api/v1/auth/activate/validate-code')
      .send({ activationCode });
    const flowId = valRes.body.data.activationFlowId;

    await request(app)
      .post('/api/v1/auth/activate/send-otp')
      .send({ activationFlowId: flowId, contactMethod: 'email' });

    const adapter = OtpDeliveryService.getAdapter() as DevOtpDeliveryAdapter;
    const otp = adapter.getLastOtp('johndoe@svgp.edu')!;

    // 8a. Mismatched contact method (sent to email, verifying as phone)
    const mismatchRes = await request(app)
      .post('/api/v1/auth/activate/verify-otp')
      .send({
        activationFlowId: flowId,
        contactMethod: 'phone',
        otp,
      });
    expect(mismatchRes.status).toBe(400);

    // 8b. Correct verification succeeds and returns activationToken
    const verifyRes = await request(app)
      .post('/api/v1/auth/activate/verify-otp')
      .send({
        activationFlowId: flowId,
        contactMethod: 'email',
        otp,
      });

    expect(verifyRes.status).toBe(200);
    expect(verifyRes.body.success).toBe(true);
    expect(verifyRes.body.data.activationToken).toBeDefined();

    // 7a. Replay prevention: reusing same OTP fails
    const replayRes = await request(app)
      .post('/api/v1/auth/activate/verify-otp')
      .send({
        activationFlowId: flowId,
        contactMethod: 'email',
        otp,
      });
    expect(replayRes.status).toBe(400);
  });

  // =========================================================================
  // 9 & 10. ACTIVATION TOKEN PURPOSE & SECURITY
  // =========================================================================

  it('9 & 10. Activation token cannot be used on normal authenticated routes', async () => {
    const { activationCode } = await createTestInvitation();

    const valRes = await request(app)
      .post('/api/v1/auth/activate/validate-code')
      .send({ activationCode });
    const flowId = valRes.body.data.activationFlowId;

    await request(app)
      .post('/api/v1/auth/activate/send-otp')
      .send({ activationFlowId: flowId, contactMethod: 'email' });

    const adapter = OtpDeliveryService.getAdapter() as DevOtpDeliveryAdapter;
    const otp = adapter.getLastOtp('johndoe@svgp.edu')!;

    const verifyRes = await request(app)
      .post('/api/v1/auth/activate/verify-otp')
      .send({ activationFlowId: flowId, contactMethod: 'email', otp });

    const activationToken = verifyRes.body.data.activationToken;

    // Cryptographic validation of the token payload
    const decoded = verifyActivationCompletionToken(activationToken);
    expect(decoded.purpose).toBe('activation_completion');
    expect(decoded.tokenId).toBeDefined();
    expect(decoded.invitationId).toBeDefined();

    // Attempting to access protected route /api/v1/auth/me with activation token
    const authMeRes = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${activationToken}`);

    expect(authMeRes.status).toBe(401);
  });

  // =========================================================================
  // 11, 12, 13 & 14. PASSWORD COMPLETION AND ATOMIC CONSUMPTION
  // =========================================================================

  it('11, 12, 13 & 14. Password completion enforces policy, matches passwords, and consumes invitation atomically', async () => {
    const { activationCode, user } = await createTestInvitation();

    const valRes = await request(app)
      .post('/api/v1/auth/activate/validate-code')
      .send({ activationCode });
    const flowId = valRes.body.data.activationFlowId;

    await request(app)
      .post('/api/v1/auth/activate/send-otp')
      .send({ activationFlowId: flowId, contactMethod: 'email' });

    const adapter = OtpDeliveryService.getAdapter() as DevOtpDeliveryAdapter;
    const otp = adapter.getLastOtp('johndoe@svgp.edu')!;

    const verifyRes = await request(app)
      .post('/api/v1/auth/activate/verify-otp')
      .send({ activationFlowId: flowId, contactMethod: 'email', otp });
    const activationToken = verifyRes.body.data.activationToken;

    // 12a. Password mismatch
    const mismatchRes = await request(app)
      .post('/api/v1/auth/activate/complete')
      .send({
        activationToken,
        password: 'StrongPassword123!',
        confirmPassword: 'DifferentPassword123!',
      });
    expect(mismatchRes.status).toBe(400);
    expect(mismatchRes.body.error.message).toContain('Passwords do not match');

    // 12b. Weak password
    const weakRes = await request(app)
      .post('/api/v1/auth/activate/complete')
      .send({
        activationToken,
        password: 'short',
        confirmPassword: 'short',
      });
    expect(weakRes.status).toBe(400);
    expect(weakRes.body.error.message).toContain('at least 8 characters');

    // 11. Successful completion
    const completeRes = await request(app)
      .post('/api/v1/auth/activate/complete')
      .send({
        activationToken,
        password: 'ValidActivationPass123!',
        confirmPassword: 'ValidActivationPass123!',
      });

    expect(completeRes.status).toBe(200);
    expect(completeRes.body.success).toBe(true);
    expect(completeRes.body.data.user.accountStatus).toBe(AccountStatus.ACTIVE);

    // 14. Verify invitation is USED and cannot be consumed again
    const updatedUser = await User.findById(user._id);
    expect(updatedUser!.accountStatus).toBe(AccountStatus.ACTIVE);
    expect(updatedUser!.passwordHash).toBeDefined();

    // Verify workspace membership is ACTIVE
    const membership = await WorkspaceMembership.findOne({
      userId: user._id,
      collegeId: collegeA._id,
    });
    expect(membership).toBeDefined();
    expect(membership!.status).toBe(MembershipStatus.ACTIVE);

    // Verify role assignment is ACTIVE
    const roleAssignment = await WorkspaceRoleAssignment.findOne({
      membershipId: membership!._id,
      role: AppRole.STUDENT,
    });
    expect(roleAssignment).toBeDefined();
    expect(roleAssignment!.status).toBe(RoleAssignmentStatus.ACTIVE);

    // 13. Second attempt with the same token fails (token/invitation already consumed)
    const reuseRes = await request(app)
      .post('/api/v1/auth/activate/complete')
      .send({
        activationToken,
        password: 'ValidActivationPass123!',
        confirmPassword: 'ValidActivationPass123!',
      });
    expect(reuseRes.status).toBe(400);

    // User can immediately log in with their credentials at common login screen
    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({
        identifier: 'johndoe@svgp.edu',
        password: 'ValidActivationPass123!',
      });
    expect(loginRes.status).toBe(200);
    expect(loginRes.body.data.accessToken).toBeDefined();
  });

  // =========================================================================
  // 15, 16 & 17. EXISTING USER JOINING ANOTHER COLLEGE
  // =========================================================================

  it('15, 16 & 17. Existing active user joining another college reuses User ID and preserves password', async () => {
    // Setup existing active user in College A
    const originalPassword = 'OriginalSecurePassword999!';
    const originalPasswordHash = await PasswordService.hashPassword(originalPassword);

    const existingUser = await User.create({
      instituteId: 'FAC-ALREADY-ACTIVE-01',
      name: 'Dr. Jane Existing',
      email: 'jane.existing@acadex.edu',
      phone: '+919988776655',
      passwordHash: originalPasswordHash,
      role: AppRole.FACULTY,
      collegeId: collegeA._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    const originalUserId = existingUser._id.toString();

    const deptB1 = await Department.create({
      name: 'Information Science',
      code: 'ISE',
      collegeId: collegeB._id,
      status: 'active',
    });

    // Super Admin invites Dr. Jane to College B as HOD
    const inviteRes = await request(app)
      .post('/api/v1/auth/invitations')
      .set(superAdminHeader)
      .send({
        name: 'Dr. Jane Existing',
        instituteId: 'FAC-COL-B-001',
        email: 'jane.existing@acadex.edu',
        role: AppRole.HOD,
        collegeId: collegeB.id,
        departmentId: deptB1.id,
      });

    expect(inviteRes.status).toBe(201);
    const activationCode = inviteRes.body.data.activationCode;

    // Validate code
    const valRes = await request(app)
      .post('/api/v1/auth/activate/validate-code')
      .send({ activationCode });

    expect(valRes.status).toBe(200);
    expect(valRes.body.data.isExistingUser).toBe(true);
    expect(valRes.body.data.institutionName).toBe('Beta Institute of Technology');
    const flowId = valRes.body.data.activationFlowId;

    // Send and verify OTP
    await request(app)
      .post('/api/v1/auth/activate/send-otp')
      .send({ activationFlowId: flowId, contactMethod: 'email' });

    const adapter = OtpDeliveryService.getAdapter() as DevOtpDeliveryAdapter;
    const otp = adapter.getLastOtp('jane.existing@acadex.edu')!;

    const verifyRes = await request(app)
      .post('/api/v1/auth/activate/verify-otp')
      .send({ activationFlowId: flowId, contactMethod: 'email', otp });

    const activationToken = verifyRes.body.data.activationToken;

    // Complete activation
    const completeRes = await request(app)
      .post('/api/v1/auth/activate/complete')
      .send({ activationToken });

    expect(completeRes.status).toBe(200);
    expect(completeRes.body.success).toBe(true);
    expect(completeRes.body.data.message).toContain('workspace access has been activated');

    // 17. Verify canonical User._id was PRESERVED
    const preservedUser = await User.findById(originalUserId);
    expect(preservedUser).toBeDefined();
    expect(preservedUser!._id.toString()).toBe(originalUserId);

    // 15. Verify original password hash was UNCHANGED
    expect(preservedUser!.passwordHash).toBe(originalPasswordHash);

    // Verify existing user can still log in with original password
    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({
        identifier: 'jane.existing@acadex.edu',
        password: originalPassword,
      });
    expect(loginRes.status).toBe(200);

    // 16. Verify Dr. Jane now has an active WorkspaceMembership in College B
    const bMembership = await WorkspaceMembership.findOne({
      userId: existingUser._id,
      collegeId: collegeB._id,
    });
    expect(bMembership).toBeDefined();
    expect(bMembership!.status).toBe(MembershipStatus.ACTIVE);

    const bRoleAssignment = await WorkspaceRoleAssignment.findOne({
      membershipId: bMembership!._id,
      role: AppRole.HOD,
    });
    expect(bRoleAssignment).toBeDefined();
    expect(bRoleAssignment!.status).toBe(RoleAssignmentStatus.ACTIVE);
  });

  // =========================================================================
  // 18. LEGACY USERS WITHOUT CONTACT INFORMATION
  // =========================================================================

  it('18. Legacy users without email or phone cannot be probed or broken', async () => {
    // Setup legacy user without email or phone
    await User.create({
      instituteId: 'LEGACY-PIN-999',
      name: 'Legacy Teacher',
      passwordHash: defaultPasswordHash,
      role: AppRole.FACULTY,
      collegeId: collegeA._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    // 18a. Legacy user can still log in normally using PIN + password
    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({
        identifier: 'LEGACY-PIN-999',
        password: defaultPassword,
      });
    expect(loginRes.status).toBe(200);
    expect(loginRes.body.data.user.instituteId).toBe('LEGACY-PIN-999');

    // 18b. Creating an invitation without contact method is rejected
    const invalidInviteRes = await request(app)
      .post('/api/v1/auth/invitations')
      .set(collegeAdminAHeader)
      .send({
        name: 'No Contact Student',
        instituteId: 'STU-NOCONTACT-01',
        role: AppRole.STUDENT,
        departmentId: deptA1.id,
      });
    expect(invalidInviteRes.status).toBe(400);
    expect(invalidInviteRes.body.error.message).toContain('At least one contact method');
  });

  // =========================================================================
  // 19. EXPIRED INVITATION RENEWAL RULES
  // =========================================================================

  it('19. Reissued invitation invalidates old code and issues new code for same identity', async () => {
    const { activationCode: oldCode, invitation } = await createTestInvitation();

    // College Admin reissues invitation
    const reissueRes = await request(app)
      .post(`/api/v1/auth/invitations/${invitation.id}/reissue`)
      .set(collegeAdminAHeader);

    expect(reissueRes.status).toBe(200);
    const newCode = reissueRes.body.data.activationCode;
    expect(newCode).not.toBe(oldCode);

    // Old code fails validation
    const oldValidate = await request(app)
      .post('/api/v1/auth/activate/validate-code')
      .send({ activationCode: oldCode });
    expect(oldValidate.status).toBe(400);

    // New code succeeds validation
    const newValidate = await request(app)
      .post('/api/v1/auth/activate/validate-code')
      .send({ activationCode: newCode });
    expect(newValidate.status).toBe(200);
    expect(newValidate.body.data.displayName).toBe('John Doe');
  });

  // =========================================================================
  // 20 & 21. AUTHORIZATION, SECURITY & AUDIT TRAIL
  // =========================================================================

  it('20 & 21. Client-supplied colleges or roles are ignored and audit events are captured', async () => {
    const { activationCode, invitation } = await createTestInvitation();

    const valRes = await request(app)
      .post('/api/v1/auth/activate/validate-code')
      .send({ activationCode });
    const flowId = valRes.body.data.activationFlowId;

    await request(app)
      .post('/api/v1/auth/activate/send-otp')
      .send({ activationFlowId: flowId, contactMethod: 'email' });

    const adapter = OtpDeliveryService.getAdapter() as DevOtpDeliveryAdapter;
    const otp = adapter.getLastOtp('johndoe@svgp.edu')!;

    const verifyRes = await request(app)
      .post('/api/v1/auth/activate/verify-otp')
      .send({ activationFlowId: flowId, contactMethod: 'email', otp });
    const activationToken = verifyRes.body.data.activationToken;

    // Tampering attempt: malicious client injects collegeId and role in complete body
    const completeRes = await request(app)
      .post('/api/v1/auth/activate/complete')
      .send({
        activationToken,
        password: 'ValidActivationPass123!',
        confirmPassword: 'ValidActivationPass123!',
        collegeId: collegeB.id, // Forged college
        role: AppRole.SUPER_ADMIN, // Forged role
      });

    expect(completeRes.status).toBe(200);

    // Verify assigned role is strictly STUDENT in College A, not forged SUPER_ADMIN or College B
    const membership = await WorkspaceMembership.findOne({
      userId: invitation.userId,
      collegeId: collegeA._id,
    });
    expect(membership).toBeDefined();

    const forgedMembership = await WorkspaceMembership.findOne({
      userId: invitation.userId,
      collegeId: collegeB._id,
    });
    expect(forgedMembership).toBeNull();

    const roleAssignment = await WorkspaceRoleAssignment.findOne({
      membershipId: membership!._id,
    });
    expect(roleAssignment!.role).toBe(AppRole.STUDENT);

    // 21. Audit trail checks
    const auditLogs = await AuditLog.find({
      entityId: invitation.userId.toString(),
    });
    const actions = auditLogs.map((l) => l.action);
    expect(actions).toContain('ACTIVATION_OTP_VERIFIED');
    expect(actions).toContain('ACCOUNT_ACTIVATED');
  });

  // =========================================================================
  // 22. BACKWARD COMPATIBILITY
  // =========================================================================

  it('22. Legacy activate endpoint and forgot-password flows remain operational', async () => {
    const { activationCode, user } = await createTestInvitation({
      instituteId: 'STU-LEGACY-ACT-01',
      email: 'legacyact@svgp.edu',
    });

    // 22a. Legacy activate endpoint POST /api/v1/auth/activate works
    const legacyRes = await request(app)
      .post('/api/v1/auth/activate')
      .send({
        collegeCode: 'SVGP',
        instituteId: 'STU-LEGACY-ACT-01',
        activationCode,
        password: 'LegacyPassword123!',
      });

    expect(legacyRes.status).toBe(200);
    expect(legacyRes.body.success).toBe(true);

    const activatedUser = await User.findById(user._id);
    expect(activatedUser!.accountStatus).toBe(AccountStatus.ACTIVE);

    // 22b. Forgot password flow remains operational
    const forgotRes = await request(app)
      .post('/api/v1/auth/forgot-password')
      .send({
        identifier: 'legacyact@svgp.edu',
      });
    expect(forgotRes.status).toBe(200);
  });

  // =========================================================================
  // PROMPT 3: BACKEND SECURITY HARDENING & EDGE-CASE VERIFICATION
  // =========================================================================

  describe('Prompt 3 Security Hardening & Edge-Case Verification', () => {
    // -----------------------------------------------------------------------
    // Category 1: Activation Token Security & Lifecycle
    // -----------------------------------------------------------------------

    it('P3-1. Forged activation token signature is rejected with 401', async () => {
      const { activationCode } = await createTestInvitation({
        instituteId: 'P3-SEC-001',
        email: 'p3sec1@svgp.edu',
      });
      const valRes = await request(app)
        .post('/api/v1/auth/activate/validate-code')
        .send({ activationCode });
      const flowId = valRes.body.data.activationFlowId;

      await request(app)
        .post('/api/v1/auth/activate/send-otp')
        .send({ activationFlowId: flowId, contactMethod: 'email' });

      const adapter = OtpDeliveryService.getAdapter() as DevOtpDeliveryAdapter;
      const otp = adapter.getLastOtp('p3sec1@svgp.edu')!;

      const verifyRes = await request(app)
        .post('/api/v1/auth/activate/verify-otp')
        .send({ activationFlowId: flowId, contactMethod: 'email', otp });
      const validToken = verifyRes.body.data.activationToken;

      // Tamper with the token signature
      const tamperedToken = validToken.slice(0, -6) + 'abcdef';

      const res = await request(app)
        .post('/api/v1/auth/activate/complete')
        .send({
          activationToken: tamperedToken,
          password: 'ValidActivationPass123!',
          confirmPassword: 'ValidActivationPass123!',
        });

      expect(res.status).toBe(401);
      expect(res.body.error.message).toContain('Invalid token signature');
    });

    it('P3-2. Expired activation completion token is rejected with 401', async () => {
      const expiredToken = signActivationCompletionToken(
        {
          tokenId: 'expired-token-id',
          invitationId: '600000000000000000000001',
          userId: '600000000000000000000002',
          collegeId: collegeA.id,
          contactMethod: 'email',
        },
        -10 // Expired 10 seconds ago
      );

      const res = await request(app)
        .post('/api/v1/auth/activate/complete')
        .send({
          activationToken: expiredToken,
          password: 'ValidActivationPass123!',
          confirmPassword: 'ValidActivationPass123!',
        });

      expect(res.status).toBe(401);
      expect(res.body.error.message).toContain('Token has expired');
    });

    it('P3-3. Cross-purpose token abuse fails safely with 401', async () => {
      const { activationCode } = await createTestInvitation({
        instituteId: 'P3-SEC-003',
        email: 'p3sec3@svgp.edu',
      });
      const valRes = await request(app)
        .post('/api/v1/auth/activate/validate-code')
        .send({ activationCode });
      const flowToken = valRes.body.data.activationFlowId;

      // Attempt 3a: Use activation_flow token on /complete endpoint
      const resFlowOnComplete = await request(app)
        .post('/api/v1/auth/activate/complete')
        .send({
          activationToken: flowToken,
          password: 'ValidActivationPass123!',
          confirmPassword: 'ValidActivationPass123!',
        });
      expect(resFlowOnComplete.status).toBe(401);
      expect(resFlowOnComplete.body.error.message).toContain('Invalid token');

      // Attempt 3b: Use general access token on /complete endpoint
      const accessToken = signAccessToken({
        userId: '600000000000000000000003',
        role: AppRole.STUDENT,
      });
      const resAccessOnComplete = await request(app)
        .post('/api/v1/auth/activate/complete')
        .send({
          activationToken: accessToken,
          password: 'ValidActivationPass123!',
          confirmPassword: 'ValidActivationPass123!',
        });
      expect(resAccessOnComplete.status).toBe(401);

      // Attempt 3c: Use activation_completion token on /send-otp endpoint
      const completionToken = signActivationCompletionToken({
        tokenId: 'fake-token-id',
        invitationId: '600000000000000000000001',
        userId: '600000000000000000000002',
        collegeId: collegeA.id,
        contactMethod: 'email',
      });
      const resCompletionOnSendOtp = await request(app)
        .post('/api/v1/auth/activate/send-otp')
        .send({
          activationFlowId: completionToken,
          contactMethod: 'email',
        });
      expect(resCompletionOnSendOtp.status).toBe(401);
    });

    it('P3-4. Replaying a consumed activation token fails with 400', async () => {
      const { activationCode } = await createTestInvitation({
        instituteId: 'P3-SEC-004',
        email: 'p3sec4@svgp.edu',
      });
      const valRes = await request(app)
        .post('/api/v1/auth/activate/validate-code')
        .send({ activationCode });
      const flowId = valRes.body.data.activationFlowId;

      await request(app)
        .post('/api/v1/auth/activate/send-otp')
        .send({ activationFlowId: flowId, contactMethod: 'email' });

      const adapter = OtpDeliveryService.getAdapter() as DevOtpDeliveryAdapter;
      const otp = adapter.getLastOtp('p3sec4@svgp.edu')!;

      const verifyRes = await request(app)
        .post('/api/v1/auth/activate/verify-otp')
        .send({ activationFlowId: flowId, contactMethod: 'email', otp });
      const token = verifyRes.body.data.activationToken;

      // First completion succeeds
      const firstRes = await request(app)
        .post('/api/v1/auth/activate/complete')
        .send({
          activationToken: token,
          password: 'ValidActivationPass123!',
          confirmPassword: 'ValidActivationPass123!',
        });
      expect(firstRes.status).toBe(200);

      // Replay attempt fails
      const replayRes = await request(app)
        .post('/api/v1/auth/activate/complete')
        .send({
          activationToken: token,
          password: 'ValidActivationPass123!',
          confirmPassword: 'ValidActivationPass123!',
        });
      expect(replayRes.status).toBe(400);
      expect(replayRes.body.error.message).toContain('already been consumed');
    });

    it('P3-5. Superseded activation token cannot complete activation', async () => {
      const { activationCode } = await createTestInvitation({
        instituteId: 'P3-SEC-005',
        email: 'p3sec5@svgp.edu',
      });
      const valRes = await request(app)
        .post('/api/v1/auth/activate/validate-code')
        .send({ activationCode });
      const flowId = valRes.body.data.activationFlowId;

      // 1. Send OTP 1 & Verify -> Token 1
      await request(app)
        .post('/api/v1/auth/activate/send-otp')
        .send({ activationFlowId: flowId, contactMethod: 'email' });
      const adapter = OtpDeliveryService.getAdapter() as DevOtpDeliveryAdapter;
      const otp1 = adapter.getLastOtp('p3sec5@svgp.edu')!;

      const verify1Res = await request(app)
        .post('/api/v1/auth/activate/verify-otp')
        .send({ activationFlowId: flowId, contactMethod: 'email', otp: otp1 });
      const token1 = verify1Res.body.data.activationToken;

      // 2. Simulate user re-verifying: fast forward cooldown on DB
      await Otp.collection.updateMany({}, { $set: { createdAt: new Date(Date.now() - 120000) } });

      // Request and verify OTP 2 -> Token 2
      const send2Res = await request(app)
        .post('/api/v1/auth/activate/send-otp')
        .send({ activationFlowId: flowId, contactMethod: 'email' });
      expect(send2Res.status).toBe(200);

      const otp2 = adapter.getLastOtp('p3sec5@svgp.edu')!;

      const verify2Res = await request(app)
        .post('/api/v1/auth/activate/verify-otp')
        .send({ activationFlowId: flowId, contactMethod: 'email', otp: otp2 });
      expect(verify2Res.status).toBe(200);
      const token2 = verify2Res.body.data.activationToken;

      // Token 1 is now superseded and must fail
      const supersededRes = await request(app)
        .post('/api/v1/auth/activate/complete')
        .send({
          activationToken: token1,
          password: 'ValidActivationPass123!',
          confirmPassword: 'ValidActivationPass123!',
        });
      expect(supersededRes.status).toBe(400);
      expect(supersededRes.body.error.message).toContain('superseded');

      // Token 2 completes successfully
      const activeRes = await request(app)
        .post('/api/v1/auth/activate/complete')
        .send({
          activationToken: token2,
          password: 'ValidActivationPass123!',
          confirmPassword: 'ValidActivationPass123!',
        });
      expect(activeRes.status).toBe(200);
    });

    it('P3-6. Revocation in-flight invalidates activation token', async () => {
      const { activationCode, invitation } = await createTestInvitation({
        instituteId: 'P3-SEC-006',
        email: 'p3sec6@svgp.edu',
      });
      const valRes = await request(app)
        .post('/api/v1/auth/activate/validate-code')
        .send({ activationCode });
      const flowId = valRes.body.data.activationFlowId;

      await request(app)
        .post('/api/v1/auth/activate/send-otp')
        .send({ activationFlowId: flowId, contactMethod: 'email' });
      const adapter = OtpDeliveryService.getAdapter() as DevOtpDeliveryAdapter;
      const otp = adapter.getLastOtp('p3sec6@svgp.edu')!;

      const verifyRes = await request(app)
        .post('/api/v1/auth/activate/verify-otp')
        .send({ activationFlowId: flowId, contactMethod: 'email', otp });
      const token = verifyRes.body.data.activationToken;

      // College Admin revokes invitation before user completes
      await Invitation.findByIdAndUpdate(invitation.id, {
        $set: { status: InvitationStatus.REVOKED },
      });

      const res = await request(app)
        .post('/api/v1/auth/activate/complete')
        .send({
          activationToken: token,
          password: 'ValidActivationPass123!',
          confirmPassword: 'ValidActivationPass123!',
        });
      expect(res.status).toBe(400);
      expect(res.body.error.message).toContain('revoked');
    });

    // -----------------------------------------------------------------------
    // Category 2: OTP Lifecycle & Abuse Protection
    // -----------------------------------------------------------------------

    it('P3-7. Resend cooldown is strictly enforced with 429', async () => {
      const { activationCode } = await createTestInvitation({
        instituteId: 'P3-SEC-007',
        email: 'p3sec7@svgp.edu',
      });
      const valRes = await request(app)
        .post('/api/v1/auth/activate/validate-code')
        .send({ activationCode });
      const flowId = valRes.body.data.activationFlowId;

      // First send succeeds
      const send1 = await request(app)
        .post('/api/v1/auth/activate/send-otp')
        .send({ activationFlowId: flowId, contactMethod: 'email' });
      expect(send1.status).toBe(200);

      // Immediate resend triggers cooldown 429
      const send2 = await request(app)
        .post('/api/v1/auth/activate/send-otp')
        .send({ activationFlowId: flowId, contactMethod: 'email' });
      expect(send2.status).toBe(429);
      expect(send2.body.error.message).toContain('seconds before requesting another code');
    });

    it('P3-8. Resending OTP invalidates prior unconsumed OTP', async () => {
      const { activationCode } = await createTestInvitation({
        instituteId: 'P3-SEC-008',
        email: 'p3sec8@svgp.edu',
      });
      const valRes = await request(app)
        .post('/api/v1/auth/activate/validate-code')
        .send({ activationCode });
      const flowId = valRes.body.data.activationFlowId;

      await request(app)
        .post('/api/v1/auth/activate/send-otp')
        .send({ activationFlowId: flowId, contactMethod: 'email' });
      const adapter = OtpDeliveryService.getAdapter() as DevOtpDeliveryAdapter;
      const otp1 = adapter.getLastOtp('p3sec8@svgp.edu')!;

      // Simulate cooldown passed
      await Otp.collection.updateMany({}, { $set: { createdAt: new Date(Date.now() - 120000) } });

      const send2Res = await request(app)
        .post('/api/v1/auth/activate/send-otp')
        .send({ activationFlowId: flowId, contactMethod: 'email' });
      expect(send2Res.status).toBe(200);

      const otp2 = adapter.getLastOtp('p3sec8@svgp.edu')!;

      expect(otp1).not.toBe(otp2);

      // Verifying with OTP1 fails because it was invalidated by the resend
      const verifyOtp1 = await request(app)
        .post('/api/v1/auth/activate/verify-otp')
        .send({ activationFlowId: flowId, contactMethod: 'email', otp: otp1 });
      expect(verifyOtp1.status).toBe(400);

      // Verifying with OTP2 succeeds
      const verifyOtp2 = await request(app)
        .post('/api/v1/auth/activate/verify-otp')
        .send({ activationFlowId: flowId, contactMethod: 'email', otp: otp2 });
      expect(verifyOtp2.status).toBe(200);
      expect(verifyOtp2.body.data.activationToken).toBeDefined();
    });

    it('P3-9. OTP attempt limit cannot be bypassed by generating new activation flows', async () => {
      const { activationCode } = await createTestInvitation({
        instituteId: 'P3-SEC-009',
        email: 'p3sec9@svgp.edu',
      });

      // Flow 1
      const val1 = await request(app)
        .post('/api/v1/auth/activate/validate-code')
        .send({ activationCode });
      const flowId1 = val1.body.data.activationFlowId;

      await request(app)
        .post('/api/v1/auth/activate/send-otp')
        .send({ activationFlowId: flowId1, contactMethod: 'email' });

      // Enter 4 wrong attempts on Flow 1
      for (let i = 0; i < 4; i++) {
        const wrongRes = await request(app)
          .post('/api/v1/auth/activate/verify-otp')
          .send({ activationFlowId: flowId1, contactMethod: 'email', otp: '000000' });
        expect(wrongRes.status).toBe(400);
      }

      // Attacker attempts to bypass limits by creating a new Flow 2
      const val2 = await request(app)
        .post('/api/v1/auth/activate/validate-code')
        .send({ activationCode });
      const flowId2 = val2.body.data.activationFlowId;
      expect(flowId2).not.toBe(flowId1);

      // Attempt 5 on Flow 2 triggers lockout
      const lockRes = await request(app)
        .post('/api/v1/auth/activate/verify-otp')
        .send({ activationFlowId: flowId2, contactMethod: 'email', otp: '000000' });
      expect(lockRes.status).toBe(400);
      expect(lockRes.body.error.message).toContain('Maximum verification attempts exceeded');

      // Even correct OTP is rejected once locked out
      const adapter = OtpDeliveryService.getAdapter() as DevOtpDeliveryAdapter;
      const correctOtp = adapter.getLastOtp('p3sec9@svgp.edu')!;
      const correctRes = await request(app)
        .post('/api/v1/auth/activate/verify-otp')
        .send({ activationFlowId: flowId2, contactMethod: 'email', otp: correctOtp });
      expect(correctRes.status).toBe(400);
      expect(correctRes.body.error.message).toContain('Maximum verification attempts exceeded');
    });

    it('P3-10. Delivery adapter failure does not report false success', async () => {
      const { activationCode } = await createTestInvitation({
        instituteId: 'P3-SEC-010',
        email: 'p3sec10@svgp.edu',
      });
      const valRes = await request(app)
        .post('/api/v1/auth/activate/validate-code')
        .send({ activationCode });
      const flowId = valRes.body.data.activationFlowId;

      // Mock delivery failure
      const sendOtpSpy = jest.spyOn(OtpDeliveryService, 'sendOtp').mockResolvedValueOnce(false);

      const res = await request(app)
        .post('/api/v1/auth/activate/send-otp')
        .send({ activationFlowId: flowId, contactMethod: 'email' });

      expect(res.status).toBe(500);
      expect(res.body.error.message).toContain('Failed to deliver verification code');

      sendOtpSpy.mockRestore();
    });

    // -----------------------------------------------------------------------
    // Category 3: Concurrency, Idempotency & Rollback
    // -----------------------------------------------------------------------

    it('P3-11. Concurrent completion requests with identical token: exactly 1 succeeds, 1 fails with 409', async () => {
      const { activationCode } = await createTestInvitation({
        instituteId: 'P3-SEC-011',
        email: 'p3sec11@svgp.edu',
      });
      const valRes = await request(app)
        .post('/api/v1/auth/activate/validate-code')
        .send({ activationCode });
      const flowId = valRes.body.data.activationFlowId;

      await request(app)
        .post('/api/v1/auth/activate/send-otp')
        .send({ activationFlowId: flowId, contactMethod: 'email' });

      const adapter = OtpDeliveryService.getAdapter() as DevOtpDeliveryAdapter;
      const otp = adapter.getLastOtp('p3sec11@svgp.edu')!;

      const verifyRes = await request(app)
        .post('/api/v1/auth/activate/verify-otp')
        .send({ activationFlowId: flowId, contactMethod: 'email', otp });
      const activationToken = verifyRes.body.data.activationToken;

      // Fire 2 simultaneous completion requests
      const [req1, req2] = await Promise.all([
        request(app).post('/api/v1/auth/activate/complete').send({
          activationToken,
          password: 'ValidActivationPass123!',
          confirmPassword: 'ValidActivationPass123!',
        }),
        request(app).post('/api/v1/auth/activate/complete').send({
          activationToken,
          password: 'ValidActivationPass123!',
          confirmPassword: 'ValidActivationPass123!',
        }),
      ]);

      const statuses = [req1.status, req2.status].sort();
      expect(statuses).toEqual([200, 409]);

      const conflictRes = req1.status === 409 ? req1 : req2;
      expect(conflictRes.body.error.message).toContain('already been consumed');
    });

    it('P3-12. Idempotent handling when WorkspaceMembership and WorkspaceRoleAssignment already exist', async () => {
      const { activationCode, user } = await createTestInvitation({
        instituteId: 'P3-SEC-012',
        email: 'p3sec12@svgp.edu',
      });

      // Confirm membership and role assignment were provisioned as PENDING during invitation
      const existingMembership = await WorkspaceMembership.findOne({
        userId: user._id,
        collegeId: collegeA._id,
      });
      expect(existingMembership).toBeDefined();
      expect(existingMembership!.status).toBe(MembershipStatus.PENDING);

      const existingRoleAssignment = await WorkspaceRoleAssignment.findOne({
        membershipId: existingMembership!._id,
        role: AppRole.STUDENT,
      });
      expect(existingRoleAssignment).toBeDefined();
      expect(existingRoleAssignment!.status).toBe(RoleAssignmentStatus.PENDING);

      const valRes = await request(app)
        .post('/api/v1/auth/activate/validate-code')
        .send({ activationCode });
      const flowId = valRes.body.data.activationFlowId;

      await request(app)
        .post('/api/v1/auth/activate/send-otp')
        .send({ activationFlowId: flowId, contactMethod: 'email' });

      const adapter = OtpDeliveryService.getAdapter() as DevOtpDeliveryAdapter;
      const otp = adapter.getLastOtp('p3sec12@svgp.edu')!;

      const verifyRes = await request(app)
        .post('/api/v1/auth/activate/verify-otp')
        .send({ activationFlowId: flowId, contactMethod: 'email', otp });
      const activationToken = verifyRes.body.data.activationToken;

      const completeRes = await request(app)
        .post('/api/v1/auth/activate/complete')
        .send({
          activationToken,
          password: 'ValidActivationPass123!',
          confirmPassword: 'ValidActivationPass123!',
        });

      expect(completeRes.status).toBe(200);

      // Verify no duplicates were created and records were updated idempotently to ACTIVE
      const memberships = await WorkspaceMembership.find({
        userId: user._id,
        collegeId: collegeA._id,
      });
      expect(memberships.length).toBe(1);
      expect(memberships[0].status).toBe(MembershipStatus.ACTIVE);

      const roles = await WorkspaceRoleAssignment.find({
        membershipId: existingMembership!._id,
        role: AppRole.STUDENT,
      });
      expect(roles.length).toBe(1);
      expect(roles[0].status).toBe(RoleAssignmentStatus.ACTIVE);
    });

    it('P3-13. Compensating rollback restores invitation to PENDING if post-lock persistence fails', async () => {
      const { activationCode, invitation } = await createTestInvitation({
        instituteId: 'P3-SEC-013',
        email: 'p3sec13@svgp.edu',
      });

      const valRes = await request(app)
        .post('/api/v1/auth/activate/validate-code')
        .send({ activationCode });
      const flowId = valRes.body.data.activationFlowId;

      await request(app)
        .post('/api/v1/auth/activate/send-otp')
        .send({ activationFlowId: flowId, contactMethod: 'email' });

      const adapter = OtpDeliveryService.getAdapter() as DevOtpDeliveryAdapter;
      const otp = adapter.getLastOtp('p3sec13@svgp.edu')!;

      const verifyRes = await request(app)
        .post('/api/v1/auth/activate/verify-otp')
        .send({ activationFlowId: flowId, contactMethod: 'email', otp });
      const activationToken = verifyRes.body.data.activationToken;

      // Mock database error during membership creation
      const membershipSpy = jest
        .spyOn(WorkspaceMembership, 'findOneAndUpdate')
        .mockRejectedValueOnce(new Error('Simulated transient MongoDB failure'));

      const failRes = await request(app)
        .post('/api/v1/auth/activate/complete')
        .send({
          activationToken,
          password: 'ValidActivationPass123!',
          confirmPassword: 'ValidActivationPass123!',
        });
      expect(failRes.status).toBe(500);

      // Verify invitation was rolled back to PENDING and activeActivationTokenId preserved
      const restoredInv = await Invitation.findById(invitation.id);
      expect(restoredInv!.status).toBe(InvitationStatus.PENDING);
      expect(restoredInv!.usedAt).toBeNull();

      membershipSpy.mockRestore();

      // Retry completes successfully with the same token!
      const retryRes = await request(app)
        .post('/api/v1/auth/activate/complete')
        .send({
          activationToken,
          password: 'ValidActivationPass123!',
          confirmPassword: 'ValidActivationPass123!',
        });
      expect(retryRes.status).toBe(200);
    });

    // -----------------------------------------------------------------------
    // Category 4: Multi-Workspace & Existing User Identity Protection
    // -----------------------------------------------------------------------

    it('P3-14. Client-supplied password is never applied to existing active users', async () => {
      const originalPassword = 'OriginalSecretPassword123!';
      const originalPasswordHash = await PasswordService.hashPassword(originalPassword);

      const existingActiveUser = await User.create({
        instituteId: 'FAC-ORIG-001',
        name: 'Dr. Original',
        email: 'dr.orig@acadex.edu',
        phone: '+919876543201',
        passwordHash: originalPasswordHash,
        role: AppRole.FACULTY,
        collegeId: collegeA._id,
        accountStatus: AccountStatus.ACTIVE,
      });

      const deptB1 = await Department.create({
        name: 'Mechanical Engineering',
        code: 'MECH',
        collegeId: collegeB._id,
        status: 'active',
      });

      // Invited to College B
      const inviteRes = await request(app)
        .post('/api/v1/auth/invitations')
        .set(superAdminHeader)
        .send({
          name: 'Dr. Original',
          instituteId: 'FAC-COL-B-099',
          email: 'dr.orig@acadex.edu',
          role: AppRole.FACULTY,
          collegeId: collegeB.id,
          departmentId: deptB1.id,
        });

      const activationCode = inviteRes.body.data.activationCode;
      const valRes = await request(app)
        .post('/api/v1/auth/activate/validate-code')
        .send({ activationCode });
      const flowId = valRes.body.data.activationFlowId;

      await request(app)
        .post('/api/v1/auth/activate/send-otp')
        .send({ activationFlowId: flowId, contactMethod: 'email' });

      const adapter = OtpDeliveryService.getAdapter() as DevOtpDeliveryAdapter;
      const otp = adapter.getLastOtp('dr.orig@acadex.edu')!;

      const verifyRes = await request(app)
        .post('/api/v1/auth/activate/verify-otp')
        .send({ activationFlowId: flowId, contactMethod: 'email', otp });
      const activationToken = verifyRes.body.data.activationToken;

      // Malicious or accidental request sends password fields
      const completeRes = await request(app)
        .post('/api/v1/auth/activate/complete')
        .send({
          activationToken,
          password: 'MaliciousAttackerPassword999!',
          confirmPassword: 'MaliciousAttackerPassword999!',
        });
      expect(completeRes.status).toBe(200);

      // Verify password hash in database remains byte-for-byte identical
      const reloadedUser = await User.findById(existingActiveUser._id);
      expect(reloadedUser!.passwordHash).toBe(originalPasswordHash);

      // Original password works; malicious password fails
      const successLogin = await request(app)
        .post('/api/v1/auth/login')
        .send({
          identifier: 'dr.orig@acadex.edu',
          password: originalPassword,
        });
      expect(successLogin.status).toBe(200);

      const failLogin = await request(app)
        .post('/api/v1/auth/login')
        .send({
          identifier: 'dr.orig@acadex.edu',
          password: 'MaliciousAttackerPassword999!',
        });
      expect(failLogin.status).toBe(401);
    });

    // -----------------------------------------------------------------------
    // Category 5: Request Schema Validation & Secret Non-Disclosure
    // -----------------------------------------------------------------------

    it('P3-15. Input validation guards against malformed values and safely coerces numeric OTPs', async () => {
      // 1. Empty or whitespace activation code
      const emptyCodeRes = await request(app)
        .post('/api/v1/auth/activate/validate-code')
        .send({ activationCode: '   ' });
      expect(emptyCodeRes.status).toBe(400);

      // 2. Invalid contact method enum
      const invalidMethodRes = await request(app)
        .post('/api/v1/auth/activate/send-otp')
        .send({
          activationFlowId: 'some.fake.token',
          contactMethod: 'smoke_signals',
        });
      expect(invalidMethodRes.status).toBe(400);

      // 3. Numeric OTP safely coerced without server crash
      const { activationCode } = await createTestInvitation({
        instituteId: 'P3-SEC-015',
        email: 'p3sec15@svgp.edu',
      });
      const valRes = await request(app)
        .post('/api/v1/auth/activate/validate-code')
        .send({ activationCode });
      const flowId = valRes.body.data.activationFlowId;

      await request(app)
        .post('/api/v1/auth/activate/send-otp')
        .send({ activationFlowId: flowId, contactMethod: 'email' });

      // Send numeric OTP instead of string (e.g. 123456)
      const numericOtpRes = await request(app)
        .post('/api/v1/auth/activate/verify-otp')
        .send({
          activationFlowId: flowId,
          contactMethod: 'email',
          otp: 123456, // Numeric
        });
      // Should not crash with 500 TypeError (e.g. rawOtp.trim is not a function)
      expect(numericOtpRes.status).toBe(400);
      expect(numericOtpRes.body.error.message).toContain('Invalid verification code');
    });

    it('P3-16. Identity validation never leaks raw contact information or secrets', async () => {
      const { activationCode } = await createTestInvitation({
        instituteId: 'P3-SEC-016',
        email: 'confidential.student@svgp.edu',
        phone: '+919988776655',
      });

      const res = await request(app)
        .post('/api/v1/auth/activate/validate-code')
        .send({ activationCode });

      expect(res.status).toBe(200);

      // Confirm raw email and phone are NOT present in response body
      const bodyStr = JSON.stringify(res.body);
      expect(bodyStr).not.toContain('confidential.student@svgp.edu');
      expect(bodyStr).not.toContain('+919988776655');

      // Confirm masked values are present
      expect(bodyStr).toContain('c***t@svgp.edu');
      expect(bodyStr).toContain('••••');

      // Confirm no internal secrets are disclosed
      expect(bodyStr).not.toContain('passwordHash');
      expect(bodyStr).not.toContain('otpHash');
      expect(bodyStr).not.toContain('activationCode');
    });
  });
});

