import request from 'supertest';
import { app } from '../../src/app';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { User } from '../../src/models/user.model';
import { PasswordService } from '../../src/services/password.service';
import { AppRole } from '../../src/constants/roles';
import { AccountStatus } from '../../src/constants/status';

describe('Super Admin Safe Recovery & Authentication Validation', () => {
  const superAdminEmail = 'recovery.superadmin@acadex.com';
  const superAdminPassword = 'StrongPassword@123';
  const superAdminPin = 'ADM-999';

  beforeAll(async () => {
    await setupTestDB();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();
  });

  it('1. Should successfully bootstrap Super Admin with bcrypt hash, ACTIVE status, and no college requirement', async () => {
    const passwordHash = await PasswordService.hashPassword(superAdminPassword);

    const superAdmin = await User.create({
      name: 'Recovery Super Admin',
      email: superAdminEmail,
      instituteId: superAdminPin,
      role: AppRole.SUPER_ADMIN,
      passwordHash,
      accountStatus: AccountStatus.ACTIVE,
      activationStatus: 'activated',
      collegeId: null,
      departmentId: null,
    });

    expect(superAdmin).toBeDefined();
    expect(superAdmin.role).toBe(AppRole.SUPER_ADMIN);
    expect(superAdmin.accountStatus).toBe(AccountStatus.ACTIVE);
    expect(superAdmin.collegeId).toBeNull();
  });

  it('2. Should log in via Email + Password without requiring any College in database', async () => {
    const passwordHash = await PasswordService.hashPassword(superAdminPassword);
    await User.create({
      name: 'Recovery Super Admin',
      email: superAdminEmail,
      instituteId: superAdminPin,
      role: AppRole.SUPER_ADMIN,
      passwordHash,
      accountStatus: AccountStatus.ACTIVE,
      activationStatus: 'activated',
    });

    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({
        identifier: superAdminEmail,
        password: superAdminPassword,
      });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.accessToken).toBeDefined();
    expect(res.body.data.refreshToken).toBeDefined();
    expect(res.body.data.user.role).toBe(AppRole.SUPER_ADMIN);
    expect(res.body.data.user.email).toBe(superAdminEmail);
  });

  it('3. Should log in via PIN/instituteId + Password', async () => {
    const passwordHash = await PasswordService.hashPassword(superAdminPassword);
    await User.create({
      name: 'Recovery Super Admin',
      email: superAdminEmail,
      instituteId: superAdminPin,
      role: AppRole.SUPER_ADMIN,
      passwordHash,
      accountStatus: AccountStatus.ACTIVE,
      activationStatus: 'activated',
    });

    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({
        identifier: superAdminPin,
        password: superAdminPassword,
      });

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.accessToken).toBeDefined();
    expect(res.body.data.user.role).toBe(AppRole.SUPER_ADMIN);
  });

  it('4. Should authenticate /auth/me and have unrestricted global access', async () => {
    const passwordHash = await PasswordService.hashPassword(superAdminPassword);
    await User.create({
      name: 'Recovery Super Admin',
      email: superAdminEmail,
      instituteId: superAdminPin,
      role: AppRole.SUPER_ADMIN,
      passwordHash,
      accountStatus: AccountStatus.ACTIVE,
      activationStatus: 'activated',
    });

    const loginRes = await request(app)
      .post('/api/v1/auth/login')
      .send({
        identifier: superAdminEmail,
        password: superAdminPassword,
      });

    const token = loginRes.body.data.accessToken;

    const meRes = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${token}`);

    expect(meRes.status).toBe(200);
    expect(meRes.body.data.role).toBe(AppRole.SUPER_ADMIN);
    expect(meRes.body.data.email).toBe(superAdminEmail);
  });

  it('5. Should reject wrong password on Super Admin account with 401 Unauthorized', async () => {
    const passwordHash = await PasswordService.hashPassword(superAdminPassword);
    await User.create({
      name: 'Recovery Super Admin',
      email: superAdminEmail,
      instituteId: superAdminPin,
      role: AppRole.SUPER_ADMIN,
      passwordHash,
      accountStatus: AccountStatus.ACTIVE,
      activationStatus: 'activated',
    });

    const res = await request(app)
      .post('/api/v1/auth/login')
      .send({
        identifier: superAdminEmail,
        password: 'WrongPassword@999',
      });

    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
  });
});
