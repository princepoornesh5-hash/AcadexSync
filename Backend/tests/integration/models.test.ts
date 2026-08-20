import { College } from '../../src/models/college.model';
import { Department } from '../../src/models/department.model';
import { User } from '../../src/models/user.model';
import { AuditLog } from '../../src/models/auditLog.model';
import { AppRole } from '../../src/constants/roles';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import mongoose from 'mongoose';

describe('Domain Models & Schema Validation', () => {
  beforeAll(async () => {
    await setupTestDB();
    await College.init();
    await Department.init();
    await User.init();
    await AuditLog.init();
  });
 
  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();
  });
  
  it('should enforce unique college code constraint', async () => {
    await College.create({
      name: 'College One',
      code: 'COL1',
      address: 'Addr 1',
      email: 'c1@test.edu',
      phone: '1234567890',
      principal: 'Principal 1',
    });

    await expect(
      College.create({
        name: 'College Two',
        code: 'COL1', // Duplicate code
        address: 'Addr 2',
        email: 'c2@test.edu',
        phone: '0987654321',
        principal: 'Principal 2',
      })
    ).rejects.toThrow();
  });

  it('should enforce unique user email and instituteId constraint', async () => {
    await User.create({
      instituteId: 'STU-001',
      name: 'Alice User',
      email: 'alice@acadex.edu',
      role: AppRole.STUDENT,
    });

    // Duplicate email
    await expect(
      User.create({
        instituteId: 'STU-002',
        name: 'Alice Clone',
        email: 'alice@acadex.edu',
        role: AppRole.STUDENT,
      })
    ).rejects.toThrow();

    // Duplicate instituteId
    await expect(
      User.create({
        instituteId: 'STU-001',
        name: 'Bob User',
        email: 'bob@acadex.edu',
        role: AppRole.STUDENT,
      })
    ).rejects.toThrow();
  });

  it('should enforce compound unique index on department (collegeId + code)', async () => {
    const collegeId1 = new mongoose.Types.ObjectId();
    const collegeId2 = new mongoose.Types.ObjectId();

    // CSE in College 1
    await Department.create({
      collegeId: collegeId1,
      name: 'Computer Science',
      code: 'CSE',
    });

    // CSE in College 2 should SUCCEED (different tenant)
    const dept2 = await Department.create({
      collegeId: collegeId2,
      name: 'Computer Science',
      code: 'CSE',
    });
    expect(dept2.code).toBe('CSE');

    // Duplicate CSE in College 1 should FAIL
    await expect(
      Department.create({
        collegeId: collegeId1,
        name: 'Computer Science 2',
        code: 'CSE',
      })
    ).rejects.toThrow();
  });

  it('should create and retrieve audit logs accurately', async () => {
    const actorId = new mongoose.Types.ObjectId().toString();
    const collegeId = new mongoose.Types.ObjectId().toString();

    const log = await AuditLog.create({
      collegeId,
      actorUserId: actorId,
      action: 'UPDATE_ROLE',
      entityType: 'User',
      entityId: 'usr_target_123',
      previousValue: { role: 'STUDENT' },
      newValue: { role: 'FACULTY' },
      metadata: { ip: '127.0.0.1' },
    });

    expect(log.action).toBe('UPDATE_ROLE');
    expect(log.entityType).toBe('User');
    expect(log.previousValue).toEqual({ role: 'STUDENT' });
    expect(log.newValue).toEqual({ role: 'FACULTY' });
    expect(log.timestamp).toBeDefined();
  });
});
