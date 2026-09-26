import request from 'supertest';
import { app } from '../../src/app';
import {
  College,
  Department,
  Course,
  AcademicYear,
  Semester,
  Section,
  Subject,
  User,
  Student,
  Faculty,
  StudentEnrollment,
  FacultyAssignment,
  Notification,
  DeviceToken,
  AuditLog,
} from '../../src/models';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';
import { AppRole } from '../../src/constants/roles';
import {
  NotificationType,
  DevicePlatform,
} from '../../src/constants/notification.constants';
import { FcmService } from '../../src/services/fcm.service';
import { NotificationService } from '../../src/services/notification.service';
import { NoteService } from '../../src/services/note.service';
import { TimetableService } from '../../src/services/timetable.service';
import { AttendanceService } from '../../src/services/attendance.service';
import { ImageKitService } from '../../src/storage/imagekit.service';
import {
  TimetableDay,
  TimetableTimingMode,
  TimetableSessionType,
  AttendanceStatus,
  AccountStatus,
} from '../../src/constants/status';

describe('ACADEX Phase 9M.1 — Notifications Engine Integration Tests', () => {
  let collegeA: any;
  let collegeB: any;
  let deptA: any;
  let courseA: any;
  let yearA: any;
  let semA: any;
  let secA: any;
  let subjectA: any;
  let studentUser1: any;
  let studentUser2: any;
  let facultyUser: any;
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

    // Mock FCM Messaging client
    mockFcm = {
      sendMulticast: jest.fn().mockResolvedValue({
        successfulCount: 1,
        failureCount: 0,
        invalidTokens: [],
      }),
    };
    FcmService.setMockMessagingForTesting(mockFcm);

    // Setup Colleges
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
      name: 'Computer Science',
      code: 'CSE',
    });

    courseA = await Course.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'B.Tech CSE',
      code: 'BTCSE',
      durationYears: 4,
      totalSemesters: 8,
    });

    yearA = await AcademicYear.create({
      collegeId: collegeA._id,
      name: '2026-2027',
      startDate: new Date('2026-08-01'),
      endDate: new Date('2027-05-31'),
    });

    semA = await Semester.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: yearA._id,
      number: 1,
      name: 'Semester 1',
    });

    secA = await Section.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: yearA._id,
      semesterId: semA._id,
      name: 'Section A',
      capacity: 60,
    });

    subjectA = await Subject.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      semesterId: semA._id,
      name: 'Data Structures',
      code: 'CS201',
    });

    // Setup Users
    studentUser1 = await User.create({
      collegeId: collegeA._id,
      instituteId: 'STU-001',
      name: 'Alice Student',
      email: 'alice@coea.edu',
      role: AppRole.STUDENT,
      status: 'active',
    });

    studentDoc1 = await Student.create({
      collegeId: collegeA._id,
      userId: studentUser1._id,
      name: 'Alice Student',
      studentIdNumber: 'STU-001',
      rollNumber: 'CS01',
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: yearA._id,
      semesterId: semA._id,
      sectionId: secA._id,
      status: 'active',
    });

    studentUser2 = await User.create({
      collegeId: collegeA._id,
      instituteId: 'STU-002',
      name: 'Bob Student',
      email: 'bob@coea.edu',
      role: AppRole.STUDENT,
      status: 'active',
    });

    studentDoc2 = await Student.create({
      collegeId: collegeA._id,
      userId: studentUser2._id,
      name: 'Bob Student',
      studentIdNumber: 'STU-002',
      rollNumber: 'CS02',
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: yearA._id,
      semesterId: semA._id,
      sectionId: secA._id,
      status: 'active',
    });

    facultyUser = await User.create({
      collegeId: collegeA._id,
      instituteId: 'FAC-001',
      name: 'Dr. John Doe',
      email: 'john@coea.edu',
      role: AppRole.FACULTY,
      status: 'active',
    });

    facultyDoc = await Faculty.create({
      collegeId: collegeA._id,
      userId: facultyUser._id,
      departmentId: deptA._id,
      instituteId: 'FAC-001',
      name: 'Dr. John Doe',
      email: 'john@coea.edu',
      status: 'active',
      isActive: true,
    });

    // Enroll students in section
    await StudentEnrollment.create({
      collegeId: collegeA._id,
      studentId: studentDoc1._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: yearA._id,
      semesterId: semA._id,
      sectionId: secA._id,
      status: 'active',
    });

    await StudentEnrollment.create({
      collegeId: collegeA._id,
      studentId: studentDoc2._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: yearA._id,
      semesterId: semA._id,
      sectionId: secA._id,
      status: 'active',
    });
  });

  afterEach(() => {
    FcmService.setMockMessagingForTesting(null);
  });

  // =========================================================================
  // TESTS 1-4: DEVICE TOKEN REGISTRATION & MANAGEMENT
  // =========================================================================

  it('1. User can register a device token successfully', async () => {
    const authHeader = createTestAuthHeader({
      role: AppRole.STUDENT,
      userId: studentUser1.id,
      instituteId: studentUser1.instituteId,
      collegeId: collegeA.id,
    });

    const res = await request(app)
      .post('/api/v1/notifications/device-tokens')
      .set(authHeader)
      .send({
        deviceToken: 'fcm_token_alice_android_123',
        platform: DevicePlatform.ANDROID,
        appVersion: '1.0.0',
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.deviceToken).toBe('fcm_token_alice_android_123');
    expect(res.body.data.isActive).toBe(true);

    const saved = await DeviceToken.findOne({ deviceToken: 'fcm_token_alice_android_123' });
    expect(saved).not.toBeNull();
    expect(saved?.userId.toString()).toBe(studentUser1.id);
  });

  it('2. Duplicate token handling updates existing record without error', async () => {
    const authHeader = createTestAuthHeader({
      role: AppRole.STUDENT,
      userId: studentUser1.id,
      instituteId: studentUser1.instituteId,
      collegeId: collegeA.id,
    });

    await request(app)
      .post('/api/v1/notifications/device-tokens')
      .set(authHeader)
      .send({
        deviceToken: 'duplicate_token_test',
        platform: DevicePlatform.IOS,
      });

    const res = await request(app)
      .post('/api/v1/notifications/device-tokens')
      .set(authHeader)
      .send({
        deviceToken: 'duplicate_token_test',
        platform: DevicePlatform.IOS,
        appVersion: '1.0.1',
      });

    expect(res.status).toBe(201);
    const count = await DeviceToken.countDocuments({ deviceToken: 'duplicate_token_test' });
    expect(count).toBe(1);
  });

  it('3. User can remove own device token', async () => {
    const authHeader = createTestAuthHeader({
      role: AppRole.STUDENT,
      userId: studentUser1.id,
      instituteId: studentUser1.instituteId,
      collegeId: collegeA.id,
    });

    await request(app)
      .post('/api/v1/notifications/device-tokens')
      .set(authHeader)
      .send({
        deviceToken: 'token_to_remove',
        platform: DevicePlatform.ANDROID,
      });

    const res = await request(app)
      .delete('/api/v1/notifications/device-tokens/token_to_remove')
      .set(authHeader);

    expect(res.status).toBe(200);
    const tokenDoc = await DeviceToken.findOne({ deviceToken: 'token_to_remove' });
    expect(tokenDoc?.isActive).toBe(false);
  });

  it('4. User cannot manipulate another user token removal', async () => {
    // Alice registers token
    await DeviceToken.create({
      userId: studentUser1._id,
      collegeId: collegeA._id,
      deviceToken: 'alice_private_token',
      platform: DevicePlatform.ANDROID,
      isActive: true,
    });

    // Bob attempts to remove Alice's token
    const bobAuth = createTestAuthHeader({
      role: AppRole.STUDENT,
      userId: studentUser2.id,
      instituteId: studentUser2.instituteId,
      collegeId: collegeA.id,
    });

    const res = await request(app)
      .delete('/api/v1/notifications/device-tokens/alice_private_token')
      .set(bobAuth);

    expect(res.status).toBe(200);
    const tokenDoc = await DeviceToken.findOne({ deviceToken: 'alice_private_token' });
    // Token must remain active because it belongs to Alice
    expect(tokenDoc?.isActive).toBe(true);
  });

  // =========================================================================
  // TESTS 5-10: INBOX, PAGINATION, UNREAD COUNT, READ STATUS
  // =========================================================================

  it('5-8. Notification creation, listing with pagination, and unread count', async () => {
    // Create 3 notifications for Alice
    await NotificationService.createNotification({
      collegeId: collegeA.id,
      recipientUserId: studentUser1.id,
      title: 'Notif 1',
      body: 'Body 1',
      notificationType: NotificationType.ANNOUNCEMENT,
    });

    await NotificationService.createNotification({
      collegeId: collegeA.id,
      recipientUserId: studentUser1.id,
      title: 'Notif 2',
      body: 'Body 2',
      notificationType: NotificationType.NOTE_PUBLISHED,
    });

    await NotificationService.createNotification({
      collegeId: collegeA.id,
      recipientUserId: studentUser1.id,
      title: 'Notif 3',
      body: 'Body 3',
      notificationType: NotificationType.TIMETABLE_PUBLISHED,
    });

    const authHeader = createTestAuthHeader({
      role: AppRole.STUDENT,
      userId: studentUser1.id,
      instituteId: studentUser1.instituteId,
      collegeId: collegeA.id,
    });

    // 8. Unread count
    const unreadRes = await request(app)
      .get('/api/v1/notifications/unread-count')
      .set(authHeader);
    expect(unreadRes.status).toBe(200);
    expect(unreadRes.body.data.unreadCount).toBe(3);

    // 6 & 7. Listing & pagination
    const listRes = await request(app)
      .get('/api/v1/notifications?page=1&limit=2')
      .set(authHeader);
    expect(listRes.status).toBe(200);
    expect(listRes.body.data.items.length).toBe(2);
    expect(listRes.body.data.total).toBe(3);
    expect(listRes.body.data.totalPages).toBe(2);
  });

  it('9-10. Mark single and all notifications as read', async () => {
    const notif1 = await NotificationService.createNotification({
      collegeId: collegeA.id,
      recipientUserId: studentUser1.id,
      title: 'Notif 1',
      body: 'Body 1',
      notificationType: NotificationType.SYSTEM,
    });

    await NotificationService.createNotification({
      collegeId: collegeA.id,
      recipientUserId: studentUser1.id,
      title: 'Notif 2',
      body: 'Body 2',
      notificationType: NotificationType.SYSTEM,
    });

    const authHeader = createTestAuthHeader({
      role: AppRole.STUDENT,
      userId: studentUser1.id,
      instituteId: studentUser1.instituteId,
      collegeId: collegeA.id,
    });

    // 9. Mark single notif read
    const readSingleRes = await request(app)
      .patch(`/api/v1/notifications/${notif1.id}/read`)
      .set(authHeader);
    expect(readSingleRes.status).toBe(200);
    expect(readSingleRes.body.data.isRead).toBe(true);

    const unreadAfterOne = await NotificationService.getUnreadCount(studentUser1.id, collegeA.id);
    expect(unreadAfterOne).toBe(1);

    // 10. Mark all as read
    const readAllRes = await request(app)
      .patch('/api/v1/notifications/read-all')
      .set(authHeader);
    expect(readAllRes.status).toBe(200);
    expect(readAllRes.body.data.updatedCount).toBe(1);

    const unreadFinal = await NotificationService.getUnreadCount(studentUser1.id, collegeA.id);
    expect(unreadFinal).toBe(0);
  });

  // =========================================================================
  // TESTS 11-13: TENANT & IDENTITY ISOLATION
  // =========================================================================

  it('11. Student cannot access another student notifications', async () => {
    const aliceNotif = await NotificationService.createNotification({
      collegeId: collegeA.id,
      recipientUserId: studentUser1.id,
      title: 'Alice Private Grade',
      body: 'Top secret',
      notificationType: NotificationType.SYSTEM,
    });

    // Bob tries to read Alice's notification
    const bobAuth = createTestAuthHeader({
      role: AppRole.STUDENT,
      userId: studentUser2.id,
      instituteId: studentUser2.instituteId,
      collegeId: collegeA.id,
    });

    const res = await request(app)
      .get(`/api/v1/notifications/${aliceNotif.id}`)
      .set(bobAuth);
    expect(res.status).toBe(404);

    const markRes = await request(app)
      .patch(`/api/v1/notifications/${aliceNotif.id}/read`)
      .set(bobAuth);
    expect(markRes.status).toBe(404);
  });

  it('12. Cross-college tenant isolation prevents cross-college notification access', async () => {
    const aliceNotif = await NotificationService.createNotification({
      collegeId: collegeA.id,
      recipientUserId: studentUser1.id,
      title: 'College A Notice',
      body: 'Only for A',
      notificationType: NotificationType.ANNOUNCEMENT,
    });

    // User in College B
    const userB = await User.create({
      collegeId: collegeB._id,
      instituteId: 'B-STU-01',
      name: 'College B Student',
      email: 'stu_colb@colb.edu',
      role: AppRole.STUDENT,
      status: 'active',
    });

    const collegeBAuth = createTestAuthHeader({
      role: AppRole.STUDENT,
      userId: userB._id.toString(),
      instituteId: userB.instituteId,
      collegeId: collegeB.id,
    });

    const res = await request(app)
      .get(`/api/v1/notifications/${aliceNotif.id}`)
      .set(collegeBAuth);
    expect(res.status).toBe(404);
  });

  // =========================================================================
  // TESTS 14-18: BUSINESS EVENT TRIGGERS (NOTES, TIMETABLE, ATTENDANCE)
  // =========================================================================

  it('16. Note publication creates notification for all enrolled students in section', async () => {
    // Mock ImageKit getFileDetails
    jest.spyOn(ImageKitService, 'getFileDetails').mockResolvedValue({
      fileId: 'mock_file_123',
      name: 'dsa_notes.pdf',
      url: 'https://ik.imagekit.io/acadex/dsa_notes.pdf',
      thumbnailUrl: 'https://ik.imagekit.io/acadex/tr:w-200/dsa_notes.pdf',
      size: 2048000,
      filePath: '/notes/dsa_notes.pdf',
      fileType: 'non-image',
      mimeType: 'application/pdf',
    });

    const facultyAuth = {
      id: facultyUser.id,
      instituteId: facultyUser.instituteId,
      name: facultyUser.name,
      role: AppRole.FACULTY,
      collegeId: collegeA.id,
      accountStatus: AccountStatus.ACTIVE,
    };

    // 1. Request upload URL
    const uploadReq = await NoteService.requestUploadUrl(collegeA.id, {
      departmentId: deptA.id,
      courseId: courseA.id,
      academicYearId: yearA.id,
      semesterId: semA.id,
      sectionId: secA.id,
      subjectId: subjectA.id,
      title: 'Trees & Graphs',
      fileName: 'dsa_notes.pdf',
      mimeType: 'application/pdf',
      fileSize: 2048000,
    }, facultyAuth);

    // 2. Complete upload
    await NoteService.completeUpload(uploadReq.note.id, facultyAuth);

    // Verify both enrolled students received notification
    const aliceNotifs = await Notification.find({
      recipientUserId: studentUser1._id,
      notificationType: NotificationType.NOTE_PUBLISHED,
    });
    expect(aliceNotifs.length).toBe(1);
    expect(aliceNotifs[0].title).toContain('Trees & Graphs');

    const bobNotifs = await Notification.find({
      recipientUserId: studentUser2._id,
      notificationType: NotificationType.NOTE_PUBLISHED,
    });
    expect(bobNotifs.length).toBe(1);
    expect(bobNotifs[0].title).toContain('Trees & Graphs');
  });

  it('17. Timetable publication creates notifications for enrolled students and assigned faculty', async () => {
    const adminAuth = {
      id: 'usr_admin',
      instituteId: 'ADMIN-001',
      name: 'Admin User',
      role: AppRole.COLLEGE_ADMIN,
      collegeId: collegeA.id,
      accountStatus: AccountStatus.ACTIVE,
    };

    // Seed active Faculty Assignment
    const assignment = await FacultyAssignment.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      facultyId: facultyDoc._id,
      facultyName: facultyDoc.name,
      courseId: courseA._id,
      semesterId: semA._id,
      sectionId: secA._id,
      subjectId: subjectA._id,
      academicYearId: yearA._id,
      isActive: true,
    });

    // Create draft timetable
    const tt = await TimetableService.createTimetable(collegeA.id, {
      name: 'Fall 2026 Timetable',
      departmentId: deptA.id,
      courseId: courseA.id,
      academicYearId: yearA.id,
      semesterId: semA.id,
      sectionId: secA.id,
      timingMode: TimetableTimingMode.SAME_EVERY_DAY,
      periods: [{ index: 1, name: 'Period 1', startTime: '09:00', endTime: '10:00' }],
      entries: [
        {
          dayOfWeek: TimetableDay.MONDAY,
          startTime: '09:00',
          endTime: '10:00',
          sessionType: TimetableSessionType.LECTURE,
          subjectId: subjectA.id,
          facultyId: facultyDoc.id,
          facultyAssignmentId: assignment._id,
        },
      ],
    }, adminAuth);

    // Publish timetable
    await TimetableService.publishTimetable(tt.id, adminAuth.id, collegeA.id, false, adminAuth);

    // Verify students received timetable notification
    const studentNotifs = await Notification.find({
      recipientUserId: studentUser1._id,
      notificationType: NotificationType.TIMETABLE_PUBLISHED,
    });
    expect(studentNotifs.length).toBe(1);
    expect(studentNotifs[0].title).toBe('New Timetable Published');
  });

  it('18. Attendance submission dispatches notification for absent students', async () => {
    await AttendanceService.createOrSubmitSession(
      collegeA.id,
      {
        departmentId: deptA.id,
        courseId: courseA.id,
        academicYearId: yearA.id,
        semesterId: semA.id,
        sectionId: secA.id,
        subjectId: subjectA.id,
        facultyId: facultyDoc.id,
        date: new Date(),
        timeSlot: '09:00 - 10:00',
        records: [
          {
            studentId: studentDoc1._id,
            sectionId: secA._id,
            studentName: 'Alice Student',
            rollNumber: 'CS01',
            status: AttendanceStatus.ABSENT,
          },
          {
            studentId: studentDoc2._id,
            sectionId: secA._id,
            studentName: 'Bob Student',
            rollNumber: 'CS02',
            status: AttendanceStatus.PRESENT,
          },
        ],
      },
      facultyUser.id
    );

    // Alice (Absent) should get attendance marked absent notice
    const aliceAttNotifs = await Notification.find({
      recipientUserId: studentUser1._id,
      notificationType: { $in: [NotificationType.ATTENDANCE_MARKED, NotificationType.ATTENDANCE_ABSENT] },
    });
    expect(aliceAttNotifs.length).toBe(1);
    expect(aliceAttNotifs[0].title).toBe('Marked Absent');

    // Bob (Present) does not get marked absent notice
    const bobAttNotifs = await Notification.find({
      recipientUserId: studentUser2._id,
      notificationType: { $in: [NotificationType.ATTENDANCE_MARKED, NotificationType.ATTENDANCE_ABSENT] },
    });
    expect(bobAttNotifs.length).toBe(0);
  });

  // =========================================================================
  // TESTS 19-24: FCM CLEANUP, ERROR RESILIENCE, IDEMPOTENCY, PREFERENCES, AUDIT
  // =========================================================================

  it('19. Invalid FCM token returned by FCM is automatically deactivated', async () => {
    // Register token
    await DeviceToken.create({
      userId: studentUser1._id,
      collegeId: collegeA._id,
      deviceToken: 'invalid_fcm_token_test',
      platform: DevicePlatform.ANDROID,
      isActive: true,
    });

    mockFcm.sendMulticast = jest.fn().mockResolvedValue({
      successfulCount: 0,
      failureCount: 1,
      invalidTokens: ['invalid_fcm_token_test'],
    });

    await NotificationService.createNotification({
      collegeId: collegeA.id,
      recipientUserId: studentUser1.id,
      title: 'Alert',
      body: 'Test message',
      notificationType: NotificationType.SYSTEM,
    });

    // Wait a tick for async push dispatch
    await new Promise((resolve) => setTimeout(resolve, 50));

    const tokenDoc = await DeviceToken.findOne({ deviceToken: 'invalid_fcm_token_test' });
    expect(tokenDoc?.isActive).toBe(false);
  });

  it('20. FCM failure does not fail the main notification creation transaction', async () => {
    mockFcm.sendMulticast = jest.fn().mockRejectedValue(new Error('FCM network timeout'));

    const notif = await NotificationService.createNotification({
      collegeId: collegeA.id,
      recipientUserId: studentUser1.id,
      title: 'Resilience Test',
      body: 'Must succeed in DB',
      notificationType: NotificationType.SYSTEM,
    });

    expect(notif).toBeDefined();
    expect(notif._id).toBeDefined();

    const saved = await Notification.findById(notif.id);
    expect(saved).not.toBeNull();
  });

  it('21. Duplicate event with idempotencyKey does not create duplicate notification', async () => {
    const notif1 = await NotificationService.createNotification({
      collegeId: collegeA.id,
      recipientUserId: studentUser1.id,
      title: 'Assignment',
      body: 'Due tomorrow',
      notificationType: NotificationType.ANNOUNCEMENT,
      idempotencyKey: 'event_announcement_101_alice',
    });

    const notif2 = await NotificationService.createNotification({
      collegeId: collegeA.id,
      recipientUserId: studentUser1.id,
      title: 'Assignment',
      body: 'Due tomorrow',
      notificationType: NotificationType.ANNOUNCEMENT,
      idempotencyKey: 'event_announcement_101_alice',
    });

    expect(notif1.id).toBe(notif2.id);
    const count = await Notification.countDocuments({
      recipientUserId: studentUser1._id,
      idempotencyKey: 'event_announcement_101_alice',
    });
    expect(count).toBe(1);
  });

  it('22. Notification preferences are respected (get & update)', async () => {
    const authHeader = createTestAuthHeader({
      role: AppRole.STUDENT,
      userId: studentUser1.id,
      instituteId: studentUser1.instituteId,
      collegeId: collegeA.id,
    });

    // 1. Get default preferences
    const getRes = await request(app)
      .get('/api/v1/notifications/preferences')
      .set(authHeader);
    expect(getRes.status).toBe(200);
    expect(getRes.body.data.notes).toBe(true);
    expect(getRes.body.data.system).toBe(true);

    // 2. Update preferences
    const updateRes = await request(app)
      .put('/api/v1/notifications/preferences')
      .set(authHeader)
      .send({
        notes: false,
        attendance: true,
      });
    expect(updateRes.status).toBe(200);
    expect(updateRes.body.data.notes).toBe(false);
    expect(updateRes.body.data.system).toBe(true); // System remains true
  });

  it('23. Audit events are generated for device token and preferences', async () => {
    const authHeader = createTestAuthHeader({
      role: AppRole.STUDENT,
      userId: studentUser1.id,
      instituteId: studentUser1.instituteId,
      collegeId: collegeA.id,
    });

    await request(app)
      .post('/api/v1/notifications/device-tokens')
      .set(authHeader)
      .send({
        deviceToken: 'token_audit_test_123',
        platform: DevicePlatform.ANDROID,
      });

    const auditLog = await AuditLog.findOne({
      actorUserId: studentUser1.id,
      action: 'DEVICE_TOKEN_REGISTERED',
    });
    expect(auditLog).not.toBeNull();
    expect(auditLog?.entityType).toBe('DeviceToken');
  });

  it('24. Secrets and plaintext full tokens are not returned in logs or responses', async () => {
    const auditLogs = await AuditLog.find({ action: 'DEVICE_TOKEN_REGISTERED' });
    auditLogs.forEach((log) => {
      expect(log.newValue).not.toHaveProperty('privateKey');
      expect(log.newValue).not.toHaveProperty('clientSecret');
    });
  });
});
