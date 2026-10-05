import mongoose, { Types } from 'mongoose';
import { MongoMemoryServer } from 'mongodb-memory-server';
import { isValidIsoDateString, createRequestSchema } from '../../src/validations/request.validation';
import { RequestService } from '../../src/services/request.service';
import { NotificationService } from '../../src/services/notification.service';
import { initRequestNotificationListener } from '../../src/events/requestNotification.listener';
import {
  College,
  Department,
  Course,
  Student,
  StudentEnrollment,
  Faculty,
  User,
  RequestModel,
  Notification,
} from '../../src/models';
import { AppRole } from '../../src/constants/roles';
import { AccountStatus } from '../../src/constants/status';
import { ALL_REQUEST_TYPES, RequestStatus } from '../../src/constants/request.constants';
import { AuthenticatedUser } from '../../src/types/auth.types';

describe('PROMPT 2: Request Center Date Validation, Authorization & Notification Safety', () => {
  let mongoServer: MongoMemoryServer;

  beforeAll(async () => {
    mongoServer = await MongoMemoryServer.create();
    await mongoose.connect(mongoServer.getUri());
    initRequestNotificationListener();
  });

  afterAll(async () => {
    await mongoose.disconnect();
    await mongoServer.stop();
  });

  beforeEach(async () => {
    await Promise.all([
      College.deleteMany({}),
      Department.deleteMany({}),
      Course.deleteMany({}),
      Student.deleteMany({}),
      StudentEnrollment.deleteMany({}),
      Faculty.deleteMany({}),
      User.deleteMany({}),
      RequestModel.deleteMany({}),
      Notification.deleteMany({}),
    ]);
  });

  // =========================================================================
  // 1. DATE SEMANTICS & VALIDATION TESTS
  // =========================================================================
  describe('Date Validation & Contract', () => {
    it('accepts valid UTC timestamps with Z suffix', () => {
      expect(isValidIsoDateString('2026-10-06T00:00:00.000Z')).toBe(true);
      expect(isValidIsoDateString('2026-10-06T14:30:00Z')).toBe(true);
    });

    it('accepts valid timezone-aware timestamps with offset (e.g. Asia/Kolkata +05:30)', () => {
      expect(isValidIsoDateString('2026-10-06T14:30:00.000+05:30')).toBe(true);
      expect(isValidIsoDateString('2026-10-06T09:00:00+05:30')).toBe(true);
    });

    it('accepts local ISO datetime strings without offset (Dart default)', () => {
      expect(isValidIsoDateString('2026-10-06T14:30:00.000')).toBe(true);
      expect(isValidIsoDateString('2026-10-06T00:00:00')).toBe(true);
    });

    it('accepts pure calendar date strings (YYYY-MM-DD)', () => {
      expect(isValidIsoDateString('2026-10-06')).toBe(true);
      expect(isValidIsoDateString('2026-01-01')).toBe(true);
      expect(isValidIsoDateString('2026-12-31')).toBe(true);
    });

    it('rejects impossible calendar dates (Feb 30, April 31, month 13)', () => {
      expect(isValidIsoDateString('2026-02-30')).toBe(false);
      expect(isValidIsoDateString('2026-04-31')).toBe(false);
      expect(isValidIsoDateString('2026-06-31')).toBe(false);
      expect(isValidIsoDateString('2026-09-31')).toBe(false);
      expect(isValidIsoDateString('2026-11-31')).toBe(false);
      expect(isValidIsoDateString('2026-13-01')).toBe(false);
      expect(isValidIsoDateString('2026-00-10')).toBe(false);
      expect(isValidIsoDateString('2026-10-32')).toBe(false);
    });

    it('rejects Feb 29 on non-leap years', () => {
      // 2026 is not a leap year
      expect(isValidIsoDateString('2026-02-29')).toBe(false);
      expect(isValidIsoDateString('2026-02-29T00:00:00.000Z')).toBe(false);

      // 2024 is a leap year
      expect(isValidIsoDateString('2024-02-29')).toBe(true);
      expect(isValidIsoDateString('2024-02-29T00:00:00.000Z')).toBe(true);
    });

    it('rejects malformed strings and arbitrary text', () => {
      expect(isValidIsoDateString('not-a-date')).toBe(false);
      expect(isValidIsoDateString('10/06/2026')).toBe(false);
      expect(isValidIsoDateString('2026.10.06')).toBe(false);
      expect(isValidIsoDateString('')).toBe(false);
    });

    it('validates schema handles optional and null date fields safely', () => {
      const res1 = createRequestSchema.safeParse({
        requestType: 'GENERAL_REQUEST',
        description: 'Need general assistance with portal access',
      });
      expect(res1.success).toBe(true);

      const res2 = createRequestSchema.safeParse({
        requestType: 'LEAVE',
        description: 'Requesting sick leave',
        details: {
          startDate: null,
          endDate: null,
          date: null,
        },
      });
      expect(res2.success).toBe(true);
    });

    it('rejects endDate earlier than startDate', () => {
      const res = createRequestSchema.safeParse({
        requestType: 'LEAVE',
        description: 'Leave request with invalid date range',
        details: {
          startDate: '2026-10-10T00:00:00.000Z',
          endDate: '2026-10-05T00:00:00.000Z',
        },
      });
      expect(res.success).toBe(false);
      if (!res.success) {
        expect(res.error.errors[0].message).toBe('End date cannot be earlier than start date.');
      }
    });

    it('accepts endDate equal to or later than startDate', () => {
      const resEqual = createRequestSchema.safeParse({
        requestType: 'LEAVE',
        description: 'Single day leave request',
        details: {
          startDate: '2026-10-10T00:00:00.000Z',
          endDate: '2026-10-10T00:00:00.000Z',
        },
      });
      expect(resEqual.success).toBe(true);

      const resLater = createRequestSchema.safeParse({
        requestType: 'LEAVE',
        description: 'Multi-day leave request',
        details: {
          startDate: '2026-10-10T00:00:00.000Z',
          endDate: '2026-10-14T00:00:00.000Z',
        },
      });
      expect(resLater.success).toBe(true);
    });
  });

  // =========================================================================
  // 2. REQUEST TYPE VALIDATION MATRIX TESTS
  // =========================================================================
  describe('Request Type Validation Matrix', () => {
    it('verifies all 17 canonical request types are recognized in schema', () => {
      for (const rType of ALL_REQUEST_TYPES) {
        const res = createRequestSchema.safeParse({
          requestType: rType,
          description: `Valid description for request type ${rType}`,
        });
        expect(res.success).toBe(true);
      }
    });

    it('rejects unrecognized request type', () => {
      const res = createRequestSchema.safeParse({
        requestType: 'UNRECOGNIZED_TYPE',
        description: 'Some description',
      });
      expect(res.success).toBe(false);
    });

    it('rejects description shorter than 3 characters', () => {
      const res = createRequestSchema.safeParse({
        requestType: 'LEAVE',
        description: 'No',
      });
      expect(res.success).toBe(false);
      if (!res.success) {
        expect(res.error.errors[0].message).toContain('minimum 3 characters');
      }
    });
  });

  // =========================================================================
  // 3. AUTHORIZATION & TENANT CONTEXT TESTS
  // =========================================================================
  describe('Authorization & Tenant Isolation', () => {
    let college: InstanceType<typeof College>;
    let studentUser: AuthenticatedUser;

    beforeEach(async () => {
      college = await College.create({
        name: 'Engineering College',
        code: 'ENG',
        email: 'eng@college.edu',
        address: 'Main St',
        phone: '1234567890',
        principal: 'Dr. Principal',
      });

      studentUser = {
        id: new Types.ObjectId().toString(),
        instituteId: 'ENG-001',
        name: 'Student One',
        email: 'student@college.edu',
        role: AppRole.STUDENT,
        collegeId: college._id.toString(),
        accountStatus: AccountStatus.ACTIVE,
      };
    });

    it('always binds requesterUserId from authenticated session, not payload', async () => {
      const spoofedUserId = new Types.ObjectId().toString();

      const created = await RequestService.createRequest(
        {
          requestType: 'GENERAL_REQUEST',
          description: 'Need library card renewal',
          // Even if spoofed ID is provided in payload (cast as any)
          ...({ requesterUserId: spoofedUserId } as any),
        },
        studentUser
      );

      expect(created.requesterUserId.toString()).toBe(studentUser.id);
      expect(created.requesterUserId.toString()).not.toBe(spoofedUserId);
      expect(created.collegeId.toString()).toBe(college._id.toString());
    });

    it('enforces role restrictions (Student cannot submit FACULTY_REQUIREMENT)', async () => {
      await expect(
        RequestService.createRequest(
          {
            requestType: 'FACULTY_REQUIREMENT',
            description: 'We need more teachers',
          },
          studentUser
        )
      ).rejects.toThrow(/not permitted to create request type/);
    });
  });

  // =========================================================================
  // 4. STUDENT ACADEMIC CONTEXT RESOLUTION TESTS
  // =========================================================================
  describe('Student Academic Context & Department Resolution', () => {
    let college: InstanceType<typeof College>;
    let dept: InstanceType<typeof Department>;
    let course: InstanceType<typeof Course>;
    let hodUser: InstanceType<typeof User>;
    let studentUserDoc: InstanceType<typeof User>;
    let studentProfile: InstanceType<typeof Student>;

    beforeEach(async () => {
      college = await College.create({
        name: 'Apex Institute of Technology',
        code: 'AIT',
        email: 'admin@ait.edu',
        address: '100 Tech Park',
        phone: '9998887770',
        principal: 'Dr. Apex',
      });

      hodUser = await User.create({
        name: 'Dr. Alan Turing',
        email: 'hod.cs@ait.edu',
        role: AppRole.HOD,
        collegeId: college._id,
        isEmailVerified: true,
      });

      dept = await Department.create({
        collegeId: college._id,
        name: 'Computer Science and Engineering',
        code: 'CSE',
        hodId: hodUser._id,
      });

      course = await Course.create({
        collegeId: college._id,
        departmentId: dept._id,
        name: 'B.Tech Computer Science',
        code: 'BT-CS',
        durationYears: 4,
      });

      studentUserDoc = await User.create({
        name: 'Aarav Sharma',
        email: 'aarav@ait.edu',
        role: AppRole.STUDENT,
        collegeId: college._id,
        // Notice: user.departmentId is intentionally null!
        departmentId: null,
        isEmailVerified: true,
      });

      studentProfile = await Student.create({
        userId: studentUserDoc._id,
        collegeId: college._id,
        departmentId: dept._id,
        name: 'Aarav Sharma',
        enrollmentNumber: 'ENR-2026-001',
      });

      await StudentEnrollment.create({
        collegeId: college._id,
        departmentId: dept._id,
        studentId: studentProfile._id,
        courseId: course._id,
        academicYearId: new Types.ObjectId(),
        semesterId: new Types.ObjectId(),
        status: 'ENROLLED',
        isActive: true,
      });
    });

    it('resolves student department from StudentEnrollment -> Course when user.departmentId is null', async () => {
      const studentAuthUser: AuthenticatedUser = {
        id: studentUserDoc._id.toString(),
        instituteId: 'AIT-001',
        name: studentUserDoc.name,
        email: studentUserDoc.email,
        role: AppRole.STUDENT,
        collegeId: college._id.toString(),
        departmentId: undefined, // user has no department directly
        accountStatus: AccountStatus.ACTIVE,
      };

      const created = await RequestService.createRequest(
        {
          requestType: 'LEAVE',
          description: 'Requesting 3 days leave due to viral fever',
          details: {
            startDate: '2026-10-12T00:00:00.000Z',
            endDate: '2026-10-14T00:00:00.000Z',
          },
        },
        studentAuthUser
      );

      // Verifications
      expect(created).toBeDefined();
      expect(created.departmentId).toBeDefined();
      expect(created.departmentId!.toString()).toBe(dept._id.toString());
      expect(created.targetRole).toBe(AppRole.HOD);
      expect(created.targetUserId!.toString()).toBe(hodUser._id.toString());
      expect(created.targetName).toContain('HOD');
      expect(created.academicContext?.courseId?.toString()).toBe(course._id.toString());
    });
  });

  // =========================================================================
  // 5. NOTIFICATION SAFETY & RESILIENCE TESTS
  // =========================================================================
  describe('Notification Safety & Non-blocking Resilience', () => {
    let college: InstanceType<typeof College>;

    beforeEach(async () => {
      college = await College.create({
        name: 'Safety College',
        code: 'SAFE',
        email: 'safe@college.edu',
        address: 'Safety Road',
        phone: '1231231234',
        principal: 'Dr. Safety',
      });
    });

    it('safe handling when NotificationService receives invalid recipientUserId ObjectId', async () => {
      const invalidRecipient = 'not-an-object-id';

      // Should not throw BSONError
      const res = await NotificationService.createNotification({
        collegeId: college._id.toString(),
        recipientUserId: invalidRecipient,
        title: 'Test Notification',
        body: 'Testing notification resilience',
        notificationType: 'REQUEST_RECEIVED' as any,
      });

      expect(res).toBeDefined();
      expect(res.id).toBe('invalid_id');
    });

    it('creates request successfully even if recipient has no HOD and routes safely to College Admin', async () => {
      const deptWithoutHod = await Department.create({
        collegeId: college._id,
        name: 'Mechanical Engineering',
        code: 'MECH',
        hodId: null,
      });

      const userWithoutHod: AuthenticatedUser = {
        id: new Types.ObjectId().toString(),
        instituteId: 'SAFE-001',
        name: 'Mech Student',
        email: 'mech@college.edu',
        role: AppRole.STUDENT,
        collegeId: college._id.toString(),
        departmentId: deptWithoutHod._id.toString(),
        accountStatus: AccountStatus.ACTIVE,
      };

      const request = await RequestService.createRequest(
        {
          requestType: 'LEAVE',
          description: 'Need leave for family emergency',
          details: {
            startDate: '2026-10-15T00:00:00.000Z',
          },
        },
        userWithoutHod
      );

      expect(request).toBeDefined();
      expect(request.status).toBe(RequestStatus.SUBMITTED);
      expect(request.targetRole).toBe(AppRole.COLLEGE_ADMIN);
      expect(request.targetUserId).toBeNull();
    });
  });
});
