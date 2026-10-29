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
  CollegeStatus,
  DepartmentStatus,
  InvitationStatus,
  MembershipStatus,
  RoleAssignmentStatus,
  OtpPurpose,
  OtpDeliveryMethod,
} from '../../src/constants/status';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { PasswordService } from '../../src/services/password.service';
import { EmailService } from '../../src/services/email.service';
import {
  OtpDeliveryService,
  EmailDeliveryAdapter,
  DevOtpDeliveryAdapter,
} from '../../src/services/otpDelivery.service';
import { env } from '../../src/config/env';
import { OtpService } from '../../src/services/otp.service';
import { hashActivationCode, generateActivationCode } from '../../src/utils/activationCode';
import { signEmailVerificationToken } from '../../src/utils/token';

describe('ACADEXSYNC Phase 2: Email OTP, Registration and Institutional Activation Integration Tests', () => {
  let mockResendSend: jest.Mock;
  let collegeA: InstanceType<typeof College>;
  let collegeB: InstanceType<typeof College>;
  let deptA: InstanceType<typeof Department>;

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
  });

  afterAll(async () => {
    (env as any).RESEND_API_KEY = undefined;
    OtpDeliveryService.setAdapter(new DevOtpDeliveryAdapter());
    EmailService.setClient(null);
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();

    (env as any).RESEND_API_KEY = 're_test_mock_123';
    OtpDeliveryService.setAdapter(new EmailDeliveryAdapter());

    // Set up mock Resend email client
    mockResendSend = jest.fn().mockImplementation(async () => ({
      data: { id: `resend_msg_${Date.now()}` },
      error: null,
    }));

    EmailService.setClient({
      emails: {
        send: mockResendSend,
      },
    } as any);

    // Seed test colleges and departments
    collegeA = await College.create({
      code: 'COLLEGE-A',
      name: 'College of Engineering A',
      status: CollegeStatus.ACTIVE,
      isActive: true,
      address: '123 College St',
      email: 'admin@collegea.edu',
      phone: '+1234567890',
      principal: 'Dr. Principal A',
    });

    collegeB = await College.create({
      code: 'COLLEGE-B',
      name: 'College of Arts B',
      status: CollegeStatus.ACTIVE,
      isActive: true,
      address: '456 College Ave',
      email: 'admin@collegeb.edu',
      phone: '+1987654321',
      principal: 'Dr. Principal B',
    });

    deptA = await Department.create({
      collegeId: collegeA._id,
      name: 'Computer Science & Engineering',
      code: 'CSE',
      status: DepartmentStatus.ACTIVE,
      isActive: true,
    });
  });

  // Helper to extract the 6-digit numeric OTP sent in mock email
  function getLatestOtpFromMock(): string {
    expect(mockResendSend).toHaveBeenCalled();
    const lastCall = mockResendSend.mock.calls[mockResendSend.mock.calls.length - 1][0];
    const text: string = lastCall.text || '';
    const textMatch = text.match(/YOUR VERIFICATION CODE:\s*(\d{6})/);
    if (textMatch) return textMatch[1];

    const html: string = lastCall.html || '';
    const htmlMatch = html.match(/class="otp-code"[^>]*>(\d{6})</);
    if (htmlMatch) return htmlMatch[1];

    throw new Error(`Failed to extract 6-digit OTP from email body: ${text || html}`);
  }

  // ===========================================================================
  // SECTION A: DEDICATED OTP SERVICE SECURITY TESTS
  // ===========================================================================
  describe('A. Dedicated OTP Service Security', () => {
    it('A1. Valid OTP verification succeeds, hashes in DB, and invalidates on consumption', async () => {
      const email = 'verify.test@acadex.edu';

      // Request OTP
      await OtpService.requestOtp({
        destination: email,
        purpose: OtpPurpose.LOGIN,
        deliveryMethod: OtpDeliveryMethod.EMAIL,
        expiresInSeconds: 300,
      });

      const otpCode = getLatestOtpFromMock();

      // Ensure OTP stored in DB is hashed, NOT plaintext
      const storedOtp = await Otp.findOne({ destination: email, purpose: OtpPurpose.LOGIN });
      expect(storedOtp).toBeDefined();
      expect(storedOtp!.otpHash).toBeDefined();
      expect(storedOtp!.otpHash).not.toEqual(otpCode);
      expect((storedOtp as any).otp).toBeUndefined();

      // Verify and consume OTP
      const verifyResult = await OtpService.verifyAndConsumeOtp({
        destination: email,
        purpose: OtpPurpose.LOGIN,
        otp: otpCode,
      });

      expect(verifyResult).toBeDefined();

      // Verify OTP is marked consumed (single-use)
      const afterConsume = await Otp.findOne({ destination: email, purpose: OtpPurpose.LOGIN });
      expect(afterConsume).toBeDefined();
      expect(afterConsume!.isConsumed()).toBe(true);
    });

    it('A2. Incorrect OTP is rejected and increments attempt count', async () => {
      const email = 'attempts.test@acadex.edu';

      await OtpService.requestOtp({
        destination: email,
        purpose: OtpPurpose.LOGIN,
        deliveryMethod: OtpDeliveryMethod.EMAIL,
      });

      // Provide wrong OTP
      await expect(
        OtpService.verifyAndConsumeOtp({
          destination: email,
          purpose: OtpPurpose.LOGIN,
          otp: '000000',
        })
      ).rejects.toThrow('Invalid verification code');

      const storedOtp = await Otp.findOne({ destination: email, purpose: OtpPurpose.LOGIN });
      expect(storedOtp!.attempts).toBe(1);
    });

    it('A3. Max failed attempts (5) permanently invalidates the OTP challenge', async () => {
      const email = 'bruteforce.test@acadex.edu';

      await OtpService.requestOtp({
        destination: email,
        purpose: OtpPurpose.REGISTRATION,
        deliveryMethod: OtpDeliveryMethod.EMAIL,
      });

      const realOtp = getLatestOtpFromMock();

      // Fail 4 times
      for (let i = 0; i < 4; i++) {
        await expect(
          OtpService.verifyAndConsumeOtp({
            destination: email,
            purpose: OtpPurpose.REGISTRATION,
            otp: '999999',
          })
        ).rejects.toThrow('Invalid verification code');
      }

      // 5th failed attempt should invalidate the OTP
      await expect(
        OtpService.verifyAndConsumeOtp({
          destination: email,
          purpose: OtpPurpose.REGISTRATION,
          otp: '999999',
        })
      ).rejects.toThrow(/Maximum verification attempts exceeded/);

      // Even the real OTP must now be rejected
      await expect(
        OtpService.verifyAndConsumeOtp({
          destination: email,
          purpose: OtpPurpose.REGISTRATION,
          otp: realOtp,
        })
      ).rejects.toThrow();
    });

    it('A4. Expired OTP is rejected', async () => {
      const email = 'expired.test@acadex.edu';

      await OtpService.requestOtp({
        destination: email,
        purpose: OtpPurpose.LOGIN,
        expiresInSeconds: 1, // 1 second expiry
      });

      const realOtp = getLatestOtpFromMock();

      // Manually wind back expiresAt in database to simulate passage of time
      await Otp.updateOne(
        { destination: email },
        { $set: { expiresAt: new Date(Date.now() - 5000) } }
      );

      await expect(
        OtpService.verifyAndConsumeOtp({
          destination: email,
          purpose: OtpPurpose.LOGIN,
          otp: realOtp,
        })
      ).rejects.toThrow(/This verification code has expired|Verification code has expired/);
    });

    it('A5. Reused OTP cannot be verified twice', async () => {
      const email = 'reuse.test@acadex.edu';

      await OtpService.requestOtp({
        destination: email,
        purpose: OtpPurpose.REGISTRATION,
      });

      const realOtp = getLatestOtpFromMock();

      // First verification succeeds
      const firstResult = await OtpService.verifyAndConsumeOtp({
        destination: email,
        purpose: OtpPurpose.REGISTRATION,
        otp: realOtp,
      });
      expect(firstResult).toBeDefined();

      // Second verification fails
      await expect(
        OtpService.verifyAndConsumeOtp({
          destination: email,
          purpose: OtpPurpose.REGISTRATION,
          otp: realOtp,
        })
      ).rejects.toThrow();
    });

    it('A6. Wrong-purpose OTP challenge is rejected', async () => {
      const email = 'purpose.test@acadex.edu';

      // Request an OTP for LOGIN
      await OtpService.requestOtp({
        destination: email,
        purpose: OtpPurpose.LOGIN,
      });

      const realOtp = getLatestOtpFromMock();

      // Attempt to verify with REGISTRATION purpose
      await expect(
        OtpService.verifyAndConsumeOtp({
          destination: email,
          purpose: OtpPurpose.REGISTRATION,
          otp: realOtp,
        })
      ).rejects.toThrow();

      // Attempt to verify with ACCOUNT_ACTIVATION purpose
      await expect(
        OtpService.verifyAndConsumeOtp({
          destination: email,
          purpose: OtpPurpose.ACCOUNT_ACTIVATION,
          otp: realOtp,
        })
      ).rejects.toThrow();
    });

    it('A7. Resend cooldown (60 seconds) prevents rapid spam requests', async () => {
      const email = 'cooldown.test@acadex.edu';

      await OtpService.requestOtp({
        destination: email,
        purpose: OtpPurpose.LOGIN,
      });

      // Immediate second request within 60s cooldown must throw 429
      await expect(
        OtpService.requestOtp({
          destination: email,
          purpose: OtpPurpose.LOGIN,
        })
      ).rejects.toThrow(/Please wait \d+ seconds before requesting (another code|a new verification code)/);
    });

    it('A8. Provider failure throws error and does not falsely claim email sent', async () => {
      const email = 'fail.provider@acadex.edu';

      // Mock Resend to return an operational error
      mockResendSend.mockResolvedValueOnce({
        data: null,
        error: { message: 'Resend rate limit exceeded', name: 'rate_limit_exceeded' },
      });

      await expect(
        OtpService.requestOtp({
          destination: email,
          purpose: OtpPurpose.REGISTRATION,
        })
      ).rejects.toThrow();

      // Verify no active OTP record was left in DB
      const storedOtp = await Otp.findOne({ destination: email });
      expect(storedOtp).toBeNull();
    });
  });

  // ===========================================================================
  // SECTION B: EXISTING ACCOUNT LOGIN (PASSWORD & OTP)
  // ===========================================================================
  describe('B. Existing Account Login (Password & OTP)', () => {
    let testPasswordUser: InstanceType<typeof User>;
    const rawPassword = 'SecurePassword123!';

    beforeEach(async () => {
      const passwordHash = await PasswordService.hashPassword(rawPassword);

      testPasswordUser = await User.create({
        instituteId: 'STUDENT-001',
        name: 'Existing Active Student',
        email: 'active.student@acadex.edu',
        passwordHash,
        role: AppRole.STUDENT,
        collegeId: collegeA._id,
        departmentId: deptA._id,
        accountStatus: AccountStatus.ACTIVE,
        activationStatus: 'activated',
      });

      const membership = await WorkspaceMembership.create({
        userId: testPasswordUser._id,
        collegeId: collegeA._id,
        instituteId: 'STUDENT-001',
        status: MembershipStatus.ACTIVE,
        isDefault: true,
        joinedAt: new Date(),
      });

      await WorkspaceRoleAssignment.create({
        membershipId: membership._id,
        userId: testPasswordUser._id,
        collegeId: collegeA._id,
        role: AppRole.STUDENT,
        departmentId: deptA._id,
        status: RoleAssignmentStatus.ACTIVE,
      });
    });

    it('B1. Existing password login continues to work without regression', async () => {
      const res = await request(app)
        .post('/api/v1/auth/login')
        .send({
          identifier: 'active.student@acadex.edu',
          password: rawPassword,
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.accessToken).toBeDefined();
      expect(res.body.data.refreshToken).toBeDefined();
      expect(res.body.data.user.email).toBe('active.student@acadex.edu');
      expect(res.body.data.activeWorkspace.collegeId).toBe(collegeA.id);
      expect(res.body.data.activeWorkspace.role).toBe(AppRole.STUDENT);
    });

    it('B2. Login with Email OTP: Request challenge and complete login', async () => {
      // 1. Request login OTP
      const reqRes = await request(app)
        .post('/api/v1/auth/login/request-otp')
        .send({ email: 'active.student@acadex.edu' });

      expect(reqRes.status).toBe(200);
      expect(reqRes.body.success).toBe(true);

      const otp = getLatestOtpFromMock();

      // 2. Verify login OTP and receive authenticated session
      const verifyRes = await request(app)
        .post('/api/v1/auth/login/verify-otp')
        .send({
          email: 'active.student@acadex.edu',
          otp,
        });

      expect(verifyRes.status).toBe(200);
      expect(verifyRes.body.success).toBe(true);
      expect(verifyRes.body.data.accessToken).toBeDefined();
      expect(verifyRes.body.data.refreshToken).toBeDefined();
      expect(verifyRes.body.data.user.email).toBe('active.student@acadex.edu');
      expect(verifyRes.body.data.activeWorkspace.collegeId).toBe(collegeA.id);
      expect(verifyRes.body.data.activeWorkspace.role).toBe(AppRole.STUDENT);
    });

    it('B3. Requesting login OTP for non-existent email returns generic message (enumeration defense)', async () => {
      const res = await request(app)
        .post('/api/v1/auth/login/request-otp')
        .send({ email: 'nonexistent.user@random.com' });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.message).toContain('If an active account exists');
      // No email should have been sent
      expect(mockResendSend).not.toHaveBeenCalled();
    });

    it('B4. Unactivated (PENDING_ACTIVATION) account cannot log in via OTP or password', async () => {
      await User.create({
        instituteId: 'PENDING-001',
        name: 'Pending User',
        email: 'pending.user@acadex.edu',
        passwordHash: await PasswordService.hashPassword('TempPass123!'),
        role: AppRole.STUDENT,
        collegeId: collegeA._id,
        accountStatus: AccountStatus.PENDING_ACTIVATION,
      });

      // Attempt password login
      const passRes = await request(app)
        .post('/api/v1/auth/login')
        .send({
          identifier: 'pending.user@acadex.edu',
          password: 'TempPass123!',
        });

      expect(passRes.status).toBe(403);
      const msg = passRes.body.error?.message || passRes.body.message;
      expect(msg).toContain('Account is pending activation');

      // Attempt OTP login request
      const otpReqRes = await request(app)
        .post('/api/v1/auth/login/request-otp')
        .send({ email: 'pending.user@acadex.edu' });

      expect(otpReqRes.status).toBe(200);
      // Mock email should NOT be called for non-active accounts
      expect(mockResendSend).not.toHaveBeenCalled();
    });
  });

  // ===========================================================================
  // SECTION C: CREATE ACCOUNT (SELF-REGISTRATION)
  // ===========================================================================
  describe('C. Create Account (Self-Registration)', () => {
    it('C1. Full self-registration flow creates user with base student role and no institutional access', async () => {
      const newEmail = 'new.student@acadex.edu';

      // Step 1: Request OTP
      const reqRes = await request(app)
        .post('/api/v1/auth/register/request-otp')
        .send({ email: newEmail });

      expect(reqRes.status).toBe(200);
      expect(reqRes.body.success).toBe(true);

      const otp = getLatestOtpFromMock();

      // Step 2: Verify OTP
      const verifyRes = await request(app)
        .post('/api/v1/auth/register/verify-otp')
        .send({ email: newEmail, otp });

      expect(verifyRes.status).toBe(200);
      expect(verifyRes.body.success).toBe(true);
      expect(verifyRes.body.data.registrationToken).toBeDefined();

      const { registrationToken } = verifyRes.body.data;

      // Step 3: Complete registration
      const completeRes = await request(app)
        .post('/api/v1/auth/register/complete')
        .send({
          registrationToken,
          password: 'SecureStudentPass123!',
          confirmPassword: 'SecureStudentPass123!',
          name: 'New Registered Student',
          termsAccepted: true,
        });

      expect(completeRes.status).toBe(200);
      expect(completeRes.body.success).toBe(true);
      expect(completeRes.body.data.accessToken).toBeDefined();
      expect(completeRes.body.data.refreshToken).toBeDefined();

      // Verify user document in DB
      const createdUser = await User.findOne({ email: newEmail });
      expect(createdUser).toBeDefined();
      expect(createdUser!.role).toBe(AppRole.STUDENT);
      expect(createdUser!.collegeId).toBeNull(); // Must NOT grant college access!
      expect(createdUser!.accountStatus).toBe(AccountStatus.ACTIVE);

      // Verify session returns null activeWorkspace
      expect(completeRes.body.data.activeWorkspace).toBeNull();
      expect(completeRes.body.data.availableWorkspaces).toEqual([]);
    });

    it('C2. Duplicate account creation is prevented', async () => {
      // Create an existing user
      await User.create({
        name: 'Existing Person',
        email: 'duplicate.check@acadex.edu',
        passwordHash: await PasswordService.hashPassword('Pass123456!'),
        role: AppRole.STUDENT,
        accountStatus: AccountStatus.ACTIVE,
      });

      // Requesting registration OTP returns generic message
      const reqRes = await request(app)
        .post('/api/v1/auth/register/request-otp')
        .send({ email: 'duplicate.check@acadex.edu' });

      expect(reqRes.status).toBe(200);
      expect(mockResendSend).not.toHaveBeenCalled(); // No email sent
    });

    it('C3. Registration with mismatched passwords fails validation', async () => {
      const email = 'mismatch.pass@acadex.edu';

      await request(app)
        .post('/api/v1/auth/register/request-otp')
        .send({ email });

      const otp = getLatestOtpFromMock();

      const verifyRes = await request(app)
        .post('/api/v1/auth/register/verify-otp')
        .send({ email, otp });

      const { registrationToken } = verifyRes.body.data;

      const completeRes = await request(app)
        .post('/api/v1/auth/register/complete')
        .send({
          registrationToken,
          password: 'Password123!',
          confirmPassword: 'DifferentPassword123!',
          termsAccepted: true,
        });

      expect(completeRes.status).toBe(400);
      const msg = completeRes.body.error?.message || completeRes.body.message;
      expect(msg).toContain('Passwords do not match');
    });
  });

  // ===========================================================================
  // SECTION D: ACTIVATE INSTITUTIONAL ACCOUNT
  // ===========================================================================
  describe('D. Activate Institutional Account', () => {
    let invitationCodeRaw: string;
    let invitationUser: InstanceType<typeof User>;
    let invitation: InstanceType<typeof Invitation>;

    beforeEach(async () => {
      invitationCodeRaw = generateActivationCode();
      const codeHash = hashActivationCode(invitationCodeRaw);

      invitationUser = await User.create({
        instituteId: 'PIN-FACULTY-99',
        name: 'Dr. Jane Faculty',
        email: 'jane.faculty@collegea.edu',
        role: AppRole.FACULTY,
        collegeId: collegeA._id,
        departmentId: deptA._id,
        accountStatus: AccountStatus.PENDING_ACTIVATION,
        activationStatus: 'pending',
      });

      invitation = await Invitation.create({
        userId: invitationUser._id,
        collegeId: collegeA._id,
        departmentId: deptA._id,
        role: AppRole.FACULTY,
        codeHash,
        status: InvitationStatus.PENDING,
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days
        createdBy: 'ADMIN-SYS',
      });
    });

    it('D1. Full institutional activation flow with verified email and code', async () => {
      // Step 1: Request OTP for registered invitation email
      const reqRes = await request(app)
        .post('/api/v1/auth/institutional-activate/request-otp')
        .send({ email: 'jane.faculty@collegea.edu' });

      expect(reqRes.status).toBe(200);
      expect(reqRes.body.success).toBe(true);

      const otp = getLatestOtpFromMock();

      // Step 2: Verify email ownership and obtain emailVerificationToken
      const verifyRes = await request(app)
        .post('/api/v1/auth/institutional-activate/verify-otp')
        .send({ email: 'jane.faculty@collegea.edu', otp });

      expect(verifyRes.status).toBe(200);
      expect(verifyRes.body.success).toBe(true);
      expect(verifyRes.body.data.emailVerificationToken).toBeDefined();

      const { emailVerificationToken } = verifyRes.body.data;

      // Step 3: Complete activation with activation code and set password
      const completeRes = await request(app)
        .post('/api/v1/auth/institutional-activate/complete')
        .send({
          emailVerificationToken,
          activationCode: invitationCodeRaw,
          password: 'FacultyPassword123!',
          confirmPassword: 'FacultyPassword123!',
          termsAccepted: true,
        });

      expect(completeRes.status).toBe(200);
      expect(completeRes.body.success).toBe(true);
      expect(completeRes.body.data.user.instituteId).toBe('PIN-FACULTY-99');
      expect(completeRes.body.data.user.accountStatus).toBe(AccountStatus.ACTIVE);

      // Verify invitation is consumed
      const updatedInv = await Invitation.findById(invitation._id);
      expect(updatedInv!.status).toBe(InvitationStatus.USED);

      // Verify WorkspaceMembership and WorkspaceRoleAssignment were created and activated
      const membership = await WorkspaceMembership.findOne({
        userId: invitationUser._id,
        collegeId: collegeA._id,
      });
      expect(membership).toBeDefined();
      expect(membership!.status).toBe(MembershipStatus.ACTIVE);
      expect(membership!.instituteId).toBe('PIN-FACULTY-99');

      const roleAssignment = await WorkspaceRoleAssignment.findOne({
        membershipId: membership!._id,
        role: AppRole.FACULTY,
      });
      expect(roleAssignment).toBeDefined();
      expect(roleAssignment!.status).toBe(RoleAssignmentStatus.ACTIVE);

      // Step 4: User can now log in
      const loginRes = await request(app)
        .post('/api/v1/auth/login')
        .send({
          identifier: 'jane.faculty@collegea.edu',
          password: 'FacultyPassword123!',
        });

      expect(loginRes.status).toBe(200);
      expect(loginRes.body.data.activeWorkspace.collegeId).toBe(collegeA.id);
      expect(loginRes.body.data.activeWorkspace.role).toBe(AppRole.FACULTY);
    });

    it('D2. Email mismatch is strictly rejected with 403 Forbidden', async () => {
      // Bob verifies his email bob@random.com
      const bobsToken = signEmailVerificationToken({ email: 'bob@random.com' });

      // Bob tries to activate Jane's invitation code using his own emailVerificationToken
      const completeRes = await request(app)
        .post('/api/v1/auth/institutional-activate/complete')
        .send({
          emailVerificationToken: bobsToken,
          activationCode: invitationCodeRaw,
          password: 'PassWord123!',
          confirmPassword: 'PassWord123!',
          termsAccepted: true,
        });

      expect(completeRes.status).toBe(403);
      const msg = completeRes.body.error?.message || completeRes.body.message;
      expect(msg).toContain('The verified email does not match the invitation email');
    });

    it('D3. Invalid activation code is rejected', async () => {
      // Verify Jane's email
      await request(app)
        .post('/api/v1/auth/institutional-activate/request-otp')
        .send({ email: 'jane.faculty@collegea.edu' });

      const otp = getLatestOtpFromMock();

      const verifyRes = await request(app)
        .post('/api/v1/auth/institutional-activate/verify-otp')
        .send({ email: 'jane.faculty@collegea.edu', otp });

      const { emailVerificationToken } = verifyRes.body.data;

      // Provide invalid activation code
      const completeRes = await request(app)
        .post('/api/v1/auth/institutional-activate/complete')
        .send({
          emailVerificationToken,
          activationCode: 'XXXX-9999-0000',
          password: 'Password123!',
          confirmPassword: 'Password123!',
          termsAccepted: true,
        });

      expect(completeRes.status).toBe(400);
      const msg = completeRes.body.error?.message || completeRes.body.message;
      expect(msg).toContain('Invalid or unknown activation code');
    });

    it('D4. Expired activation code is rejected', async () => {
      // Expire invitation
      await Invitation.findByIdAndUpdate(invitation._id, {
        $set: { expiresAt: new Date(Date.now() - 10000) },
      });

      await request(app)
        .post('/api/v1/auth/institutional-activate/request-otp')
        .send({ email: 'jane.faculty@collegea.edu' });

      // Expired invitation prevents sending OTP
      expect(mockResendSend).not.toHaveBeenCalled();
    });

    it('D5. Reusing a consumed activation code is rejected', async () => {
      // Consume invitation
      await Invitation.findByIdAndUpdate(invitation._id, {
        $set: { status: InvitationStatus.USED },
      });

      await request(app)
        .post('/api/v1/auth/institutional-activate/request-otp')
        .send({ email: 'jane.faculty@collegea.edu' });

      expect(mockResendSend).not.toHaveBeenCalled();
    });

    it('D6. Existing global user activates institutional invite without duplicate identity', async () => {
      // 1. User initially registers globally
      const existingUser = await User.create({
        name: 'Carlos Student',
        email: 'carlos@uni.edu',
        passwordHash: await PasswordService.hashPassword('CarlosExistingPass123!'),
        role: AppRole.STUDENT,
        accountStatus: AccountStatus.ACTIVE,
        activationStatus: 'activated',
      });

      // 2. Admin invites Carlos to College B as HOD
      const carlosCodeRaw = generateActivationCode();
      const codeHash = hashActivationCode(carlosCodeRaw);

      await Invitation.create({
        userId: existingUser._id,
        collegeId: collegeB._id,
        role: AppRole.HOD,
        codeHash,
        status: InvitationStatus.PENDING,
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
        createdBy: 'SUPER_ADMIN',
      });

      // 3. Carlos requests and verifies institutional activation OTP
      await request(app)
        .post('/api/v1/auth/institutional-activate/request-otp')
        .send({ email: 'carlos@uni.edu' });

      const otp = getLatestOtpFromMock();

      const verifyRes = await request(app)
        .post('/api/v1/auth/institutional-activate/verify-otp')
        .send({ email: 'carlos@uni.edu', otp });

      const { emailVerificationToken } = verifyRes.body.data;

      // 4. Carlos completes activation (as existing user, password is NOT modified)
      const completeRes = await request(app)
        .post('/api/v1/auth/institutional-activate/complete')
        .send({
          emailVerificationToken,
          activationCode: carlosCodeRaw,
          termsAccepted: true,
        });

      expect(completeRes.status).toBe(200);
      expect(completeRes.body.success).toBe(true);

      // Verify no duplicate user was created
      const userCount = await User.countDocuments({ email: 'carlos@uni.edu' });
      expect(userCount).toBe(1);

      // Verify membership attached to existing identity
      const membership = await WorkspaceMembership.findOne({
        userId: existingUser._id,
        collegeId: collegeB._id,
      });
      expect(membership).toBeDefined();
      expect(membership!.status).toBe(MembershipStatus.ACTIVE);

      // 5. Carlos can log in with his original password and now has College B access!
      const loginRes = await request(app)
        .post('/api/v1/auth/login')
        .send({
          identifier: 'carlos@uni.edu',
          password: 'CarlosExistingPass123!',
        });

      expect(loginRes.status).toBe(200);
      expect(loginRes.body.data.activeWorkspace.collegeId).toBe(collegeB.id);
      expect(loginRes.body.data.activeWorkspace.role).toBe(AppRole.HOD);
    });
  });

  // ===========================================================================
  // SECTION E: CROSS-TENANT ISOLATION
  // ===========================================================================
  describe('E. Cross-Tenant Isolation', () => {
    it('E1. User in College A cannot access College B resources', async () => {
      // Create user in College A
      const userA = await User.create({
        instituteId: 'STUDENT-A1',
        name: 'Student College A',
        email: 'student.a@collegea.edu',
        passwordHash: await PasswordService.hashPassword('Password123!'),
        role: AppRole.STUDENT,
        collegeId: collegeA._id,
        accountStatus: AccountStatus.ACTIVE,
      });

      const membershipA = await WorkspaceMembership.create({
        userId: userA._id,
        collegeId: collegeA._id,
        status: MembershipStatus.ACTIVE,
        isDefault: true,
      });

      await WorkspaceRoleAssignment.create({
        membershipId: membershipA._id,
        userId: userA._id,
        collegeId: collegeA._id,
        role: AppRole.STUDENT,
        status: RoleAssignmentStatus.ACTIVE,
      });

      // Login to get token for User A
      const loginRes = await request(app)
        .post('/api/v1/auth/login')
        .send({
          identifier: 'student.a@collegea.edu',
          password: 'Password123!',
        });

      const tokenA = loginRes.body.data.accessToken;

      // User A attempts to list invitations or access College B admin scope
      const accessRes = await request(app)
        .get('/api/v1/auth/invitations')
        .set('Authorization', `Bearer ${tokenA}`)
        .set('x-workspace-id', collegeB.id);

      // Student has no authority to view invitations (forbidden or bad workspace)
      expect([400, 403]).toContain(accessRes.status);
    });
  });
});
