import request from 'supertest';
import { app } from '../../src/app';
import { User } from '../../src/models/user.model';
import { College } from '../../src/models/college.model';
import { Department } from '../../src/models/department.model';
import { AuthSession } from '../../src/models/authSession.model';
import { PasswordService } from '../../src/services/password.service';
import { OtpDeliveryService, DevOtpDeliveryAdapter } from '../../src/services/otpDelivery.service';
import { AppRole } from '../../src/constants/roles';
import { AccountStatus } from '../../src/constants/status';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { signAccessToken } from '../../src/utils/token';

describe('ACADEX Phase 9B — Authentication Engine Integration Tests', () => {
  const devAdapter = new DevOtpDeliveryAdapter();
  let collegeA: InstanceType<typeof College>;
  let collegeB: InstanceType<typeof College>;
  let departmentA: InstanceType<typeof Department>;

  beforeAll(async () => {
    await setupTestDB();
    await User.init();
    await College.init();
    await Department.init();
    await AuthSession.init();
    OtpDeliveryService.setAdapter(devAdapter);
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();
    devAdapter.clear();

    collegeA = await College.create({
      name: 'College Alpha',
      code: 'COL-A',
      address: 'Alpha St',
      email: 'admin@alpha.edu',
      phone: '1112223333',
      principal: 'Dr. Alpha',
    });

    collegeB = await College.create({
      name: 'College Beta',
      code: 'COL-B',
      address: 'Beta Blvd',
      email: 'admin@beta.edu',
      phone: '4445556666',
      principal: 'Dr. Beta',
    });

    departmentA = await Department.create({
      collegeId: collegeA._id,
      name: 'Computer Science',
      code: 'CSE',
    });
  });

  // =========================================================================
  // 1. AUTHENTICATION & LOGIN TESTS
  // =========================================================================

  it('1. Successful login with email', async () => {
    const passwordHash = await PasswordService.hashPassword('SecretPass123');
    await User.create({
      instituteId: 'CSE-2026-001',
      name: 'John Doe',
      email: 'john.doe@alpha.edu',
      passwordHash,
      role: AppRole.STUDENT,
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({
        identifier: 'JOHN.DOE@alpha.edu', // testing lowercase normalization
        password: 'SecretPass123',
      });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.accessToken).toBeDefined();
    expect(res.body.data.refreshToken).toBeDefined();
    expect(res.body.data.user.instituteId).toBe('CSE-2026-001');
    expect(res.body.data.user.passwordHash).toBeUndefined();
  });

  it('2. Successful login with phone', async () => {
    const passwordHash = await PasswordService.hashPassword('PhonePass123');
    await User.create({
      instituteId: 'CSE-2026-002',
      name: 'Jane Smith',
      phone: '+15551234567',
      passwordHash,
      role: AppRole.FACULTY,
      collegeId: collegeA._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({
        identifier: '+1 (555) 123-4567', // testing phone formatting normalization
        password: 'PhonePass123',
      });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.accessToken).toBeDefined();
    expect(res.body.data.user.instituteId).toBe('CSE-2026-002');
  });

  it('3. Wrong password fails with 401 Unauthorized', async () => {
    const passwordHash = await PasswordService.hashPassword('CorrectPass123');
    await User.create({
      instituteId: 'CSE-2026-003',
      name: 'Bob Jones',
      email: 'bob@alpha.edu',
      passwordHash,
      role: AppRole.STUDENT,
      collegeId: collegeA._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({
        identifier: 'bob@alpha.edu',
        password: 'WrongPassword456',
      });

    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
    expect(res.body.error.message).toBe('Invalid credentials');
  });

  it('4. Unknown identifier fails with 401 Unauthorized (generic error prevents enumeration)', async () => {
    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({
        identifier: 'nonexistent@alpha.edu',
        password: 'AnyPassword123',
      });

    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
    expect(res.body.error.message).toBe('Invalid credentials');
  });

  it('5. Pending activation account CANNOT authenticate normally', async () => {
    const passwordHash = await PasswordService.hashPassword('PendingPass123');
    await User.create({
      instituteId: 'CSE-2026-005',
      name: 'Pending Student',
      email: 'pending@alpha.edu',
      passwordHash,
      role: AppRole.STUDENT,
      collegeId: collegeA._id,
      accountStatus: AccountStatus.PENDING_ACTIVATION,
    });

    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({
        identifier: 'pending@alpha.edu',
        password: 'PendingPass123',
      });

    expect(res.status).toBe(403);
    expect(res.body.success).toBe(false);
    expect(res.body.error.message).toContain('Account is pending activation');
  });

  it('6. Deactivated account CANNOT authenticate', async () => {
    const passwordHash = await PasswordService.hashPassword('DeactivatedPass123');
    await User.create({
      instituteId: 'CSE-2026-006',
      name: 'Deactivated User',
      email: 'deactivated@alpha.edu',
      passwordHash,
      role: AppRole.STUDENT,
      collegeId: collegeA._id,
      accountStatus: AccountStatus.DEACTIVATED,
    });

    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({
        identifier: 'deactivated@alpha.edu',
        password: 'DeactivatedPass123',
      });

    expect(res.status).toBe(403);
    expect(res.body.success).toBe(false);
    expect(res.body.error.message).toContain('Account has been deactivated');
  });

  it('7. Access token is accepted on protected routes', async () => {
    const passwordHash = await PasswordService.hashPassword('LoginPass123');
    const user = await User.create({
      instituteId: 'ADMIN-001',
      name: 'Admin User',
      email: 'admin@alpha.edu',
      passwordHash,
      role: AppRole.COLLEGE_ADMIN,
      collegeId: collegeA._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({
        identifier: 'admin@alpha.edu',
        password: 'LoginPass123',
      });

    const accessToken = loginRes.body.data.accessToken;

    const meRes = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${accessToken}`);

    expect(meRes.status).toBe(200);
    expect(meRes.body.success).toBe(true);
    expect(meRes.body.data.instituteId).toBe('ADMIN-001');
    expect(meRes.body.data.id).toBe(user.id);
  });

  it('8. Expired access token is rejected with 401 Unauthorized', async () => {
    // Generate token with -10 seconds expiry
    const expiredToken = signAccessToken(
      {
        userId: 'usr_expired',
        role: AppRole.STUDENT,
      },
      -10
    );

    const res = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${expiredToken}`);

    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
    expect(res.body.error.message).toContain('Token has expired');
  });

  it('9. Invalid token is rejected with 401 Unauthorized', async () => {
    const res = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', 'Bearer totally-invalid-token');

    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
  });

  it('10. Missing Authorization header is rejected with 401 Unauthorized', async () => {
    const res = await request(app).get('/api/v1/auth/me');

    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
    expect(res.body.error.message).toContain('Authentication token is required');
  });

  // =========================================================================
  // 2. SESSIONS & REFRESH TOKEN TESTS
  // =========================================================================

  it('11. Refresh token successfully refreshes access token', async () => {
    const passwordHash = await PasswordService.hashPassword('SessionPass123');
    await User.create({
      instituteId: 'CSE-2026-011',
      name: 'Session User',
      email: 'session@alpha.edu',
      passwordHash,
      role: AppRole.STUDENT,
      collegeId: collegeA._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({
        identifier: 'session@alpha.edu',
        password: 'SessionPass123',
      });

    const refreshToken = loginRes.body.data.refreshToken;

    const refreshRes = await request(app)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken });

    expect(refreshRes.status).toBe(200);
    expect(refreshRes.body.success).toBe(true);
    expect(refreshRes.body.data.accessToken).toBeDefined();

    // Verify newly issued access token works
    const meRes = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${refreshRes.body.data.accessToken}`);

    expect(meRes.status).toBe(200);
    expect(meRes.body.data.instituteId).toBe('CSE-2026-011');
  });

  it('12. Invalid refresh token is rejected with 401 Unauthorized', async () => {
    const res = await request(app)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: 'invalid.refresh.token' });

    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
  });

  it('13. Logout revokes the current session', async () => {
    const passwordHash = await PasswordService.hashPassword('LogoutPass123');
    await User.create({
      instituteId: 'CSE-2026-013',
      name: 'Logout User',
      email: 'logout@alpha.edu',
      passwordHash,
      role: AppRole.STUDENT,
      collegeId: collegeA._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({
        identifier: 'logout@alpha.edu',
        password: 'LogoutPass123',
      });

    const { accessToken, refreshToken } = loginRes.body.data;

    // Logout
    const logoutRes = await request(app)
      .post('/api/v1/auth/logout')
      .set('Authorization', `Bearer ${accessToken}`);

    expect(logoutRes.status).toBe(200);
    expect(logoutRes.body.success).toBe(true);

    // 15. Revoked session cannot refresh
    const refreshRes = await request(app)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken });

    expect(refreshRes.status).toBe(401);
    expect(refreshRes.body.error.message).toContain('Session has been revoked');
  });

  it('14. Logout-all revokes all sessions for the user', async () => {
    const passwordHash = await PasswordService.hashPassword('MultiSessionPass123');
    await User.create({
      instituteId: 'CSE-2026-014',
      name: 'Multi User',
      email: 'multi@alpha.edu',
      passwordHash,
      role: AppRole.STUDENT,
      collegeId: collegeA._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    // Session 1 (e.g. Device 1)
    const login1 = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: 'multi@alpha.edu', password: 'MultiSessionPass123' });

    // Session 2 (e.g. Device 2)
    const login2 = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: 'multi@alpha.edu', password: 'MultiSessionPass123' });

    // Logout-all from Device 1
    const logoutAllRes = await request(app)
      .post('/api/v1/auth/logout-all')
      .set('Authorization', `Bearer ${login1.body.data.accessToken}`);

    expect(logoutAllRes.status).toBe(200);

    // Both refresh tokens should now fail
    const refresh1 = await request(app)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: login1.body.data.refreshToken });
    expect(refresh1.status).toBe(401);

    const refresh2 = await request(app)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: login2.body.data.refreshToken });
    expect(refresh2.status).toBe(401);
  });

  // =========================================================================
  // 3. PASSWORD RESET & OTP FLOW TESTS
  // =========================================================================

  it('20, 21, 30, 34. Complete Forgot Password -> Verify OTP -> Reset Password Flow', async () => {
    const oldPasswordHash = await PasswordService.hashPassword('OldPassword123');
    await User.create({
      instituteId: 'ACA-STU-000184',
      name: 'Diana Prince',
      email: 'diana.prince@alpha.edu',
      passwordHash: oldPasswordHash,
      role: AppRole.STUDENT,
      collegeId: collegeA._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    // Existing session before reset
    const loginBeforeReset = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: 'diana.prince@alpha.edu', password: 'OldPassword123' });

    const activeRefreshTokenBefore = loginBeforeReset.body.data.refreshToken;

    // Step 1: Forgot Password (34. Response does not reveal account existence)
    const forgotRes = await request(app)
      .post('/api/v1/auth/forgot-password')
      .send({ identifier: 'diana.prince@alpha.edu' });

    expect(forgotRes.status).toBe(200);
    expect(forgotRes.body.message).toContain('If the account exists, a verification code has been sent.');

    // Retrieve sent OTP from dev delivery adapter
    const sentOtp = devAdapter.getLastOtp('diana.prince@alpha.edu');
    expect(sentOtp).toBeDefined();

    // Step 2: Verify OTP -> Receive short-lived reset token
    const verifyRes = await request(app)
      .post('/api/v1/auth/verify-password-reset-otp')
      .send({
        identifier: 'diana.prince@alpha.edu',
        otp: sentOtp,
      });

    expect(verifyRes.status).toBe(200);
    expect(verifyRes.body.data.resetToken).toBeDefined();
    const resetToken = verifyRes.body.data.resetToken;

    // Step 3: Reset Password with new password
    const resetRes = await request(app)
      .post('/api/v1/auth/reset-password')
      .send({
        resetToken,
        newPassword: 'BrandNewPassword999',
      });

    expect(resetRes.status).toBe(200);
    expect(resetRes.body.message).toContain('Password has been reset successfully');

    // 20. Old password NO LONGER works
    const oldLoginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: 'diana.prince@alpha.edu', password: 'OldPassword123' });
    expect(oldLoginRes.status).toBe(401);

    // New password DOES work
    const newLoginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: 'diana.prince@alpha.edu', password: 'BrandNewPassword999' });
    expect(newLoginRes.status).toBe(200);

    // 21. Previous sessions were completely revoked
    const refreshOldSession = await request(app)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: activeRefreshTokenBefore });
    expect(refreshOldSession.status).toBe(401);
  });

  // =========================================================================
  // 4. PRIVACY & SECURITY TESTS
  // =========================================================================

  it('31. Password hash NEVER appears in API responses', async () => {
    const passwordHash = await PasswordService.hashPassword('SecretPrivacy123');
    await User.create({
      instituteId: 'CSE-2026-031',
      name: 'Privacy User',
      email: 'privacy@alpha.edu',
      passwordHash,
      role: AppRole.STUDENT,
      collegeId: collegeA._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: 'privacy@alpha.edu', password: 'SecretPrivacy123' });

    expect(loginRes.body.data.user.passwordHash).toBeUndefined();

    const meRes = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${loginRes.body.data.accessToken}`);

    expect(meRes.body.data.passwordHash).toBeUndefined();
  });

  it('35. User from College A CANNOT use authenticated context to access College B data', async () => {
    const passwordHash = await PasswordService.hashPassword('CollegeAdminPass123');
    await User.create({
      instituteId: 'ADMIN-COL-A',
      name: 'College A Admin',
      email: 'admin.a@alpha.edu',
      passwordHash,
      role: AppRole.COLLEGE_ADMIN,
      collegeId: collegeA._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    // Login as College A Admin
    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: 'admin.a@alpha.edu', password: 'CollegeAdminPass123' });

    const tokenA = loginRes.body.data.accessToken;

    // Attempt to create department in College B using College A token -> Must be FORBIDDEN
    const crossTenantRes = await request(app)
      .post('/api/v1/departments')
      .set('Authorization', `Bearer ${tokenA}`)
      .send({
        collegeId: collegeB.id,
        name: 'Hacked Department',
        code: 'HACK',
      });

    expect(crossTenantRes.status).toBe(403);
    expect(crossTenantRes.body.error.message).toContain('Cross-college tenant access is strictly prohibited');
  });

  it('36. Authenticated user can change password and successfully log in with new password', async () => {
    const passwordHash = await PasswordService.hashPassword('InitialPass123');
    await User.create({
      instituteId: 'STUD-CHANGE-PASS',
      name: 'Change Pass Student',
      email: 'change.pass@alpha.edu',
      passwordHash,
      role: AppRole.STUDENT,
      collegeId: collegeA._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    // 1. Login with initial password
    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: 'change.pass@alpha.edu', password: 'InitialPass123' });
    expect(loginRes.status).toBe(200);
    const token = loginRes.body.data.accessToken;

    // 2. Change password
    const changeRes = await request(app)
      .post('/api/v1/auth/change-password')
      .set('Authorization', `Bearer ${token}`)
      .send({
        currentPassword: 'InitialPass123',
        newPassword: 'BrandNewSecurePass456',
      });
    expect(changeRes.status).toBe(200);
    expect(changeRes.body.message).toContain('Password changed successfully');

    // 3. Old password fails
    const oldLoginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: 'change.pass@alpha.edu', password: 'InitialPass123' });
    expect(oldLoginRes.status).toBe(401);

    // 4. New password succeeds
    const newLoginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: 'change.pass@alpha.edu', password: 'BrandNewSecurePass456' });
    expect(newLoginRes.status).toBe(200);
    expect(newLoginRes.body.data.user.email).toBe('change.pass@alpha.edu');
  });

  it('37. Change password fails when current password is incorrect', async () => {
    const passwordHash = await PasswordService.hashPassword('InitialPass123');
    await User.create({
      instituteId: 'STUD-WRONG-CURR',
      name: 'Wrong Curr Student',
      email: 'wrong.curr@alpha.edu',
      passwordHash,
      role: AppRole.STUDENT,
      collegeId: collegeA._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: 'wrong.curr@alpha.edu', password: 'InitialPass123' });
    const token = loginRes.body.data.accessToken;

    const changeRes = await request(app)
      .post('/api/v1/auth/change-password')
      .set('Authorization', `Bearer ${token}`)
      .send({
        currentPassword: 'WrongPassword999',
        newPassword: 'BrandNewSecurePass456',
      });
    expect(changeRes.status).toBe(401);
    expect(changeRes.body.error.message).toContain('Current password is incorrect');
  });

  it('38. Change password fails when new password violates policy or is identical to current password', async () => {
    const passwordHash = await PasswordService.hashPassword('InitialPass123');
    await User.create({
      instituteId: 'STUD-POLICY-TEST',
      name: 'Policy Test Student',
      email: 'policy.test@alpha.edu',
      passwordHash,
      role: AppRole.STUDENT,
      collegeId: collegeA._id,
      accountStatus: AccountStatus.ACTIVE,
    });

    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({ identifier: 'policy.test@alpha.edu', password: 'InitialPass123' });
    const token = loginRes.body.data.accessToken;

    // Identical password
    const sameRes = await request(app)
      .post('/api/v1/auth/change-password')
      .set('Authorization', `Bearer ${token}`)
      .send({
        currentPassword: 'InitialPass123',
        newPassword: 'InitialPass123',
      });
    expect(sameRes.status).toBe(400);
    expect(sameRes.body.error.message).toContain('New password must be different');

    // Too short (< 8 chars)
    const shortRes = await request(app)
      .post('/api/v1/auth/change-password')
      .set('Authorization', `Bearer ${token}`)
      .send({
        currentPassword: 'InitialPass123',
        newPassword: 'Pass1',
      });
    expect(shortRes.status).toBe(400);

    // No numbers
    const noDigitRes = await request(app)
      .post('/api/v1/auth/change-password')
      .set('Authorization', `Bearer ${token}`)
      .send({
        currentPassword: 'InitialPass123',
        newPassword: 'PasswordWithoutDigits',
      });
    expect(noDigitRes.status).toBe(400);
  });
});
