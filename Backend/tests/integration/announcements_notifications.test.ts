import request from 'supertest';
import { app } from '../../src/app';
import {
  College,
  Department,
  Course,
  AcademicYear,
  Semester,
  Section,
  User,
  Student,
  Faculty,
  StudentEnrollment,
  Notification,
  Announcement,
  DeviceToken,
} from '../../src/models';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';
import { AppRole } from '../../src/constants/roles';
import {
  NotificationType,
  AudienceScope,
  AnnouncementStatus,
  DevicePlatform,
} from '../../src/constants/notification.constants';
import { FcmService } from '../../src/services/fcm.service';
import { CalendarOverrideService } from '../../src/services/calendarOverride.service';
import { CalendarOverrideType } from '../../src/models/calendarOverride.model';

describe('ACADEX Prompt 12 — End-to-End Announcements & Notifications Integration Tests', () => {
  let collegeA: any;
  let collegeB: any;
  let deptA: any;
  let deptA2: any;
  let courseA: any;
  let yearA: any;
  let semA: any;
  let secA1: any;
  let secA2: any;

  let superAdminUser: any;
  let collegeAdminUser: any;
  let hodUser: any;
  let facultyUser: any;
  let studentUser1: any;
  let studentUser2: any;
  let collegeBAdminUser: any;

  let studentDoc1: any;
  let studentDoc2: any;
  let facultyDoc: any;
  let mockFcm: any;

  beforeAll(async () => {
    await setupTestDB();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();

    mockFcm = {
      sendMulticast: jest.fn().mockResolvedValue({
        successfulCount: 1,
        failureCount: 0,
        invalidTokens: [],
      }),
    };
    FcmService.setMockMessagingForTesting(mockFcm);

    // Setup College A & B
    collegeA = await College.create({
      name: 'College of Engineering A',
      code: 'COE-A',
      address: '100 Tech Blvd',
      email: 'admin@coea.edu',
      phone: '+1-555-0100',
      principal: 'Dr. Principal A',
    });

    collegeB = await College.create({
      name: 'College of Science B',
      code: 'COS-B',
      address: '200 Science Ave',
      email: 'admin@cosb.edu',
      phone: '+1-555-0200',
      principal: 'Dr. Principal B',
    });

    deptA = await Department.create({
      collegeId: collegeA._id,
      name: 'Computer Science Department',
      code: 'CS',
      status: 'active',
    });

    deptA2 = await Department.create({
      collegeId: collegeA._id,
      name: 'Electrical Engineering Department',
      code: 'EE',
      status: 'active',
    });

    courseA = await Course.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'B.Tech Computer Science',
      code: 'CS-BTECH',
      durationYears: 4,
      status: 'active',
    });

    yearA = await AcademicYear.create({
      collegeId: collegeA._id,
      name: '2026-2027',
      startDate: new Date('2026-08-01'),
      endDate: new Date('2027-05-31'),
      status: 'active',
    });

    semA = await Semester.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: yearA._id,
      number: 1,
      name: 'Semester 1',
      status: 'active',
    });

    secA1 = await Section.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      semesterId: semA._id,
      name: 'Section A',
      capacity: 60,
      status: 'active',
    });

    secA2 = await Section.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      semesterId: semA._id,
      name: 'Section B',
      capacity: 60,
      status: 'active',
    });

    // Users
    superAdminUser = await User.create({
      collegeId: collegeA._id,
      instituteId: 'SUPER-001',
      name: 'Super Admin',
      email: 'superadmin@acadex.edu',
      password: 'HashedPassword123!',
      role: AppRole.SUPER_ADMIN,
      status: 'active',
    });

    collegeAdminUser = await User.create({
      collegeId: collegeA._id,
      instituteId: 'ADMIN-A-001',
      name: 'College Admin A',
      email: 'collegeadmin@coea.edu',
      password: 'HashedPassword123!',
      role: AppRole.COLLEGE_ADMIN,
      status: 'active',
    });

    hodUser = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      instituteId: 'HOD-CS-001',
      name: 'HOD Computer Science',
      email: 'hodcs@coea.edu',
      password: 'HashedPassword123!',
      role: AppRole.HOD,
      status: 'active',
    });

    facultyUser = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      instituteId: 'FAC-001',
      name: 'Faculty CS',
      email: 'faculty@coea.edu',
      password: 'HashedPassword123!',
      role: AppRole.FACULTY,
      status: 'active',
    });

    facultyDoc = await Faculty.create({
      userId: facultyUser._id,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'Faculty CS',
      email: 'faculty@coea.edu',
      employeeId: 'FAC-001',
      designation: 'Assistant Professor',
      qualification: 'M.Tech',
      isActive: true,
      status: 'active',
    });

    studentUser1 = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      instituteId: 'STU-001',
      name: 'Student One',
      email: 'student1@coea.edu',
      password: 'HashedPassword123!',
      role: AppRole.STUDENT,
      status: 'active',
    });

    studentDoc1 = await Student.create({
      userId: studentUser1._id,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'Student One',
      enrollmentNumber: 'STU-001',
      admissionYear: 2026,
      currentSemester: 1,
      status: 'active',
    });

    // Student 1 enrolled in Section A
    await StudentEnrollment.create({
      studentId: studentDoc1._id,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: yearA._id,
      semesterId: semA._id,
      sectionId: secA1._id,
      rollNumber: 'CS-001',
      status: 'active',
    });

    studentUser2 = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      instituteId: 'STU-002',
      name: 'Student Two',
      email: 'student2@coea.edu',
      password: 'HashedPassword123!',
      role: AppRole.STUDENT,
      status: 'active',
    });

    studentDoc2 = await Student.create({
      userId: studentUser2._id,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'Student Two',
      enrollmentNumber: 'STU-002',
      admissionYear: 2026,
      currentSemester: 1,
      status: 'active',
    });

    // Student 2 enrolled in Section B
    await StudentEnrollment.create({
      studentId: studentDoc2._id,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: yearA._id,
      semesterId: semA._id,
      sectionId: secA2._id,
      rollNumber: 'CS-002',
      status: 'active',
    });

    collegeBAdminUser = await User.create({
      collegeId: collegeB._id,
      instituteId: 'ADMIN-B-001',
      name: 'College Admin B',
      email: 'admin@cosb.edu',
      password: 'HashedPassword123!',
      role: AppRole.COLLEGE_ADMIN,
      status: 'active',
    });
  });

  function auth(user: any) {
    return createTestAuthHeader({
      role: user.role,
      userId: user.id || user._id?.toString(),
      collegeId: user.collegeId?.toString() || collegeA.id,
      departmentId: user.departmentId?.toString(),
    });
  }

  describe('1. Authorization & Tenant Security Matrix', () => {
    it('College Admin creates a college-wide announcement successfully', async () => {
      const res = await request(app)
        .post('/api/v1/announcements')
        .set(auth(collegeAdminUser))
        .send({
          title: 'Campus Spring Fest 2026',
          body: 'All students and faculty are invited to the annual festival.',
          audienceScope: AudienceScope.COLLEGE,
          publishNow: true,
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.status).toBe(AnnouncementStatus.PUBLISHED);
      expect(res.body.data.recipientCount).toBeGreaterThan(0);
    });

    it('HOD creates department announcement successfully', async () => {
      const res = await request(app)
        .post('/api/v1/announcements')
        .set(auth(hodUser))
        .send({
          title: 'CS Dept Lab Maintenance',
          body: 'Lab 3 will be closed for maintenance tomorrow.',
          audienceScope: AudienceScope.DEPARTMENT,
          departmentId: deptA._id.toString(),
          publishNow: true,
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.departmentId).toBe(deptA._id.toString());
    });

    it('HOD cannot target college-wide audience (403 Forbidden)', async () => {
      const res = await request(app)
        .post('/api/v1/announcements')
        .set(auth(hodUser))
        .send({
          title: 'College Wide Notice from HOD',
          body: 'This should be blocked.',
          audienceScope: AudienceScope.COLLEGE,
        });

      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
    });

    it('HOD cannot target another department (403 Forbidden)', async () => {
      const res = await request(app)
        .post('/api/v1/announcements')
        .set(auth(hodUser))
        .send({
          title: 'Notice for EE',
          body: 'HOD of CS targeting EE department.',
          audienceScope: AudienceScope.DEPARTMENT,
          departmentId: deptA2._id.toString(),
        });

      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
    });

    it('Super Admin can create announcements', async () => {
      const res = await request(app)
        .post('/api/v1/announcements')
        .set(auth(superAdminUser))
        .send({
          title: 'System Wide Maintenance Notice',
          body: 'Maintenance scheduled this weekend.',
          audienceScope: AudienceScope.COLLEGE,
          publishNow: true,
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
    });

    it('College Admin cannot target another college (403 Forbidden)', async () => {
      const res = await request(app)
        .post('/api/v1/announcements')
        .set(auth(collegeBAdminUser))
        .send({
          title: 'Cross College Announcement',
          body: 'College B trying to target College A department.',
          audienceScope: AudienceScope.DEPARTMENT,
          departmentId: deptA._id.toString(),
        });

      expect(res.status).toBe(403);
    });

    it('Faculty cannot create announcements (403 Forbidden)', async () => {
      expect(facultyDoc).toBeDefined();
      const res = await request(app)
        .post('/api/v1/announcements')
        .set(auth(facultyUser))
        .send({
          title: 'Faculty Announcement',
          body: 'Should be rejected.',
          audienceScope: AudienceScope.DEPARTMENT,
          departmentId: deptA._id.toString(),
        });

      expect(res.status).toBe(403);
    });

    it('Student cannot create announcements (403 Forbidden)', async () => {
      const res = await request(app)
        .post('/api/v1/announcements')
        .set(auth(studentUser1))
        .send({
          title: 'Student Announcement',
          body: 'Should be rejected.',
          audienceScope: AudienceScope.COLLEGE,
        });

      expect(res.status).toBe(403);
    });
  });

  describe('2. Recipient Resolution & Section Scoping', () => {
    it('Section announcement notifies only enrolled students of that section', async () => {
      const res = await request(app)
        .post('/api/v1/announcements')
        .set(auth(hodUser))
        .send({
          title: 'Section A Special Quiz',
          body: 'Quiz will be held at 9 AM for Section A only.',
          audienceScope: AudienceScope.SECTION,
          targetSectionId: secA1._id.toString(),
          publishNow: true,
        });

      expect(res.status).toBe(201);
      const announcementId = res.body.data.id;

      // Student 1 (in Section A) must have received notification
      const notif1 = await Notification.findOne({
        recipientUserId: studentUser1._id,
        entityId: announcementId,
      });
      expect(notif1).not.toBeNull();
      expect(notif1!.title).toBe('Section A Special Quiz');

      // Student 2 (in Section B) must NOT have received notification
      const notif2 = await Notification.findOne({
        recipientUserId: studentUser2._id,
        entityId: announcementId,
      });
      expect(notif2).toBeNull();
    });

    it('Wrong college users do not receive notifications', async () => {
      await request(app)
        .post('/api/v1/announcements')
        .set(auth(collegeAdminUser))
        .send({
          title: 'College A Internal Notice',
          body: 'Strictly for College A.',
          audienceScope: AudienceScope.COLLEGE,
          publishNow: true,
        });

      const notifsCollegeB = await Notification.find({
        collegeId: collegeB._id,
      });
      expect(notifsCollegeB.length).toBe(0);
    });

    it('Duplicate publication does not create duplicate notification records (idempotency)', async () => {
      const res = await request(app)
        .post('/api/v1/announcements')
        .set(auth(hodUser))
        .send({
          title: 'Notice for Section A',
          body: 'Testing idempotency on publish retry.',
          audienceScope: AudienceScope.SECTION,
          targetSectionId: secA1._id.toString(),
          publishNow: false,
        });

      const announcementId = res.body.data.id;

      // Publish 1st time
      const pub1 = await request(app)
        .post(`/api/v1/announcements/${announcementId}/publish`)
        .set(auth(hodUser));
      expect(pub1.status).toBe(200);

      // Publish 2nd time (retry)
      const pub2 = await request(app)
        .post(`/api/v1/announcements/${announcementId}/publish`)
        .set(auth(hodUser));
      expect(pub2.status).toBe(200);

      const notifCount = await Notification.countDocuments({
        recipientUserId: studentUser1._id,
        entityId: announcementId,
      });
      expect(notifCount).toBe(1);
    });
  });

  describe('3. Inbox, Read State, and Unread Count', () => {
    let testNotif: any;

    beforeEach(async () => {
      testNotif = await Notification.create({
        collegeId: collegeA._id,
        departmentId: deptA._id,
        recipientUserId: studentUser1._id,
        title: 'Exam Schedule Out',
        body: 'Final exam schedule has been released.',
        notificationType: NotificationType.ANNOUNCEMENT,
        isRead: false,
      });
    });

    it('Unread count endpoint returns accurate count', async () => {
      const res = await request(app)
        .get('/api/v1/notifications/unread-count')
        .set(auth(studentUser1));

      expect(res.status).toBe(200);
      expect(res.body.data.unreadCount).toBe(1);
    });

    it('Marking notification read persists isRead and readAt', async () => {
      const res = await request(app)
        .post(`/api/v1/notifications/${testNotif._id}/read`)
        .set(auth(studentUser1));

      expect(res.status).toBe(200);
      expect(res.body.data.isRead).toBe(true);
      expect(res.body.data.readAt).toBeDefined();

      // Verify unread count is now 0
      const countRes = await request(app)
        .get('/api/v1/notifications/unread-count')
        .set(auth(studentUser1));
      expect(countRes.body.data.unreadCount).toBe(0);
    });

    it('Read-all marks all unread notifications read', async () => {
      // Create a second unread notification
      await Notification.create({
        collegeId: collegeA._id,
        recipientUserId: studentUser1._id,
        title: 'Library Reminder',
        body: 'Return books before Friday.',
        notificationType: NotificationType.SYSTEM,
        isRead: false,
      });

      const res = await request(app)
        .post('/api/v1/notifications/read-all')
        .set(auth(studentUser1));

      expect(res.status).toBe(200);
      expect(res.body.data.updatedCount).toBe(2);

      const unreadCount = await Notification.countDocuments({
        recipientUserId: studentUser1._id,
        isRead: false,
      });
      expect(unreadCount).toBe(0);
    });

    it('A student cannot read another student notifications (404/Access Denied)', async () => {
      const res = await request(app)
        .post(`/api/v1/notifications/${testNotif._id}/read`)
        .set(auth(studentUser2));

      expect(res.status).toBe(404);
    });
  });

  describe('4. Lifecycle & Expiry Handling', () => {
    it('Archive announcement sets status to ARCHIVED', async () => {
      const ann = await Announcement.create({
        collegeId: collegeA._id,
        departmentId: deptA._id,
        title: 'Old Circular',
        body: 'To be archived.',
        audienceScope: AudienceScope.COLLEGE,
        status: AnnouncementStatus.PUBLISHED,
        createdBy: collegeAdminUser._id,
      });

      const res = await request(app)
        .post(`/api/v1/announcements/${ann._id}/archive`)
        .set(auth(collegeAdminUser));

      expect(res.status).toBe(200);
      expect(res.body.data.status).toBe(AnnouncementStatus.ARCHIVED);
    });

    it('Expired announcements are omitted from active user feed', async () => {
      const pastDate = new Date(Date.now() - 3600 * 1000); // 1 hour ago
      await Announcement.create({
        collegeId: collegeA._id,
        title: 'Expired Announcement',
        body: 'This should not appear in user feed.',
        audienceScope: AudienceScope.COLLEGE,
        status: AnnouncementStatus.PUBLISHED,
        publishAt: new Date(Date.now() - 7200 * 1000),
        expiresAt: pastDate,
        createdBy: collegeAdminUser._id,
      });

      const res = await request(app)
        .get('/api/v1/announcements')
        .set(auth(studentUser1));

      expect(res.status).toBe(200);
      const items = res.body.data.items as any[];
      const found = items.find((a) => a.title === 'Expired Announcement');
      expect(found).toBeUndefined();
    });
  });

  describe('5. Device Token Management', () => {
    it('Registers device token and updates on subsequent calls', async () => {
      const res = await request(app)
        .post('/api/v1/notifications/device-tokens')
        .set(auth(studentUser1))
        .send({
          deviceToken: 'fcm_token_sample_12345',
          platform: DevicePlatform.ANDROID,
          appVersion: '1.0.0',
        });

      expect(res.status).toBe(201);
      expect(res.body.data.deviceToken).toBe('fcm_token_sample_12345');

      const tokenDoc = await DeviceToken.findOne({ deviceToken: 'fcm_token_sample_12345' });
      expect(tokenDoc).not.toBeNull();
      expect(tokenDoc!.isActive).toBe(true);
    });

    it('Unregisters device token marks isActive false', async () => {
      await request(app)
        .post('/api/v1/notifications/device-tokens')
        .set(auth(studentUser1))
        .send({
          deviceToken: 'fcm_token_sample_remove',
          platform: DevicePlatform.IOS,
        });

      const delRes = await request(app)
        .delete('/api/v1/notifications/device-tokens/fcm_token_sample_remove')
        .set(auth(studentUser1));

      expect(delRes.status).toBe(200);

      const tokenDoc = await DeviceToken.findOne({ deviceToken: 'fcm_token_sample_remove' });
      expect(tokenDoc!.isActive).toBe(false);
    });
  });

  describe('6. System Events Notification Dispatch', () => {
    it('Calendar Override creates CALENDAR_OVERRIDE notification', async () => {
      const override = await CalendarOverrideService.createOverride(
        {
          collegeId: collegeA._id.toString(),
          departmentId: deptA._id.toString(),
          date: '2026-10-15',
          type: CalendarOverrideType.HOLIDAY,
          reason: 'National Holiday',
        },
        {
          id: hodUser._id.toString(),
          role: AppRole.HOD,
          collegeId: collegeA._id.toString(),
          departmentId: deptA._id.toString(),
        } as any
      );

      expect(override).toBeDefined();

      const notif = await Notification.findOne({
        entityId: override.id,
        notificationType: NotificationType.CALENDAR_OVERRIDE,
      });

      expect(notif).not.toBeNull();
      expect(notif!.title).toBe('Holiday Declared');
      expect(notif!.deepLink).toBe('/timetable');
    });
  });
});
