import request from 'supertest';
import mongoose from 'mongoose';
import { app } from '../../src/app';
import { College } from '../../src/models/college.model';
import { Department } from '../../src/models/department.model';
import { Notification } from '../../src/models/notification.model';
import { User } from '../../src/models/user.model';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';
import { AppRole } from '../../src/constants/roles';
import { NotificationType } from '../../src/constants/notification.constants';
import { RequestStatus } from '../../src/constants/request.constants';
import { requestEvents } from '../../src/events/request.events';

describe('Notification Center Core Integration Tests', () => {
  let collegeA: InstanceType<typeof College>;
  let collegeB: InstanceType<typeof College>;
  let deptCSE: InstanceType<typeof Department>;

  const studentUserAId = new mongoose.Types.ObjectId().toString();
  const studentUserBId = new mongoose.Types.ObjectId().toString();
  const hodUserAId = new mongoose.Types.ObjectId().toString();

  beforeAll(async () => {
    await setupTestDB();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();

    collegeA = await College.create({
      name: 'College of Engineering A',
      code: 'COE-A',
      email: 'admin@coea.edu',
      address: '123 Campus Road, City A',
      phone: '+1-555-0101',
      principal: 'Dr. Principal A',
    });

    collegeB = await College.create({
      name: 'Institute of Tech B',
      code: 'IOT-B',
      email: 'admin@iotb.edu',
      address: '456 Tech Ave, City B',
      phone: '+1-555-0202',
      principal: 'Dr. Principal B',
    });

    deptCSE = await Department.create({
      collegeId: collegeA._id,
      name: 'Computer Science & Engineering',
      code: 'CSE',
      hodId: hodUserAId,
    });

    // Create HOD User in DB for event-based recipient resolution
    await User.create({
      _id: new mongoose.Types.ObjectId(hodUserAId),
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      instituteId: 'HOD-CSE-001',
      name: 'Dr. Alan Turing',
      email: 'hod.cse@coea.edu',
      role: AppRole.HOD,
      status: 'active',
    });

    // Create Student User in DB
    await User.create({
      _id: new mongoose.Types.ObjectId(studentUserAId),
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      instituteId: 'STU-001',
      name: 'Student Alice',
      email: 'alice@coea.edu',
      role: AppRole.STUDENT,
      status: 'active',
    });
  });

  // 1. Authenticated user can retrieve own notifications
  test('1. Authenticated user can retrieve own notifications', async () => {
    await Notification.create({
      collegeId: collegeA._id,
      recipientUserId: new mongoose.Types.ObjectId(studentUserAId),
      title: 'Welcome Alice',
      body: 'Your account is active.',
      notificationType: NotificationType.SYSTEM,
      isRead: false,
    });

    const res = await request(app)
      .get('/api/v1/notifications')
      .set(
        createTestAuthHeader({
          userId: studentUserAId,
          collegeId: collegeA._id.toString(),
          role: AppRole.STUDENT,
        })
      );

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.items.length).toBe(1);
    expect(res.body.data.items[0].title).toBe('Welcome Alice');
    expect(res.body.data.unreadCount).toBe(1);
  });

  // 2. User cannot retrieve another user's notifications (recipient isolation)
  test("2. User cannot retrieve another user's notifications", async () => {
    await Notification.create({
      collegeId: collegeA._id,
      recipientUserId: new mongoose.Types.ObjectId(studentUserBId),
      title: 'Confidential to Student B',
      body: 'Private information.',
      notificationType: NotificationType.SYSTEM,
      isRead: false,
    });

    const res = await request(app)
      .get('/api/v1/notifications')
      .set(
        createTestAuthHeader({
          userId: studentUserAId,
          collegeId: collegeA._id.toString(),
          role: AppRole.STUDENT,
        })
      );

    expect(res.status).toBe(200);
    expect(res.body.data.items.length).toBe(0);
    expect(res.body.data.unreadCount).toBe(0);
  });

  // 3. Tenant isolation is enforced
  test('3. Tenant isolation is enforced: College B user cannot see College A notifications', async () => {
    const crossTenantUserId = new mongoose.Types.ObjectId().toString();

    // Create User in College B
    await User.create({
      _id: new mongoose.Types.ObjectId(crossTenantUserId),
      collegeId: collegeB._id,
      instituteId: 'STU-B-001',
      name: 'Bob Student B',
      email: 'bob@iotb.edu',
      role: AppRole.STUDENT,
      status: 'active',
    });

    // Create notification in College A for this user ID
    await Notification.create({
      collegeId: collegeA._id,
      recipientUserId: new mongoose.Types.ObjectId(crossTenantUserId),
      title: 'Notice College A',
      body: 'College A text',
      notificationType: NotificationType.SYSTEM,
    });

    // Query with College B token
    const res = await request(app)
      .get('/api/v1/notifications')
      .set(
        createTestAuthHeader({
          userId: crossTenantUserId,
          collegeId: collegeB._id.toString(),
          role: AppRole.STUDENT,
        })
      );

    expect(res.status).toBe(200);
    expect(res.body.data.items.length).toBe(0);
  });

  // 4. Request-created event creates notification for correct recipient
  test('4. REQUEST_CREATED event creates notification for responsible authority (HOD)', async () => {
    const mockRequest = {
      _id: new mongoose.Types.ObjectId(),
      id: 'req_123',
      requestId: 'REQ-2026-0001',
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      requesterUserId: new mongoose.Types.ObjectId(studentUserAId),
      requesterName: 'Alice',
      requesterRole: AppRole.STUDENT,
      targetRole: AppRole.HOD,
      requestType: 'LEAVE',
      title: 'Sick Leave',
      description: 'Need leave for 2 days',
      status: RequestStatus.SUBMITTED,
      history: [],
    };

    // Emit event
    requestEvents.emitCreated(mockRequest as any);

    // Give listener async cycle to persist
    await new Promise((r) => setTimeout(r, 100));

    const notifs = await Notification.find({
      recipientUserId: new mongoose.Types.ObjectId(hodUserAId),
    });

    expect(notifs.length).toBe(1);
    expect(notifs[0].notificationType).toBe(NotificationType.REQUEST_RECEIVED);
    expect(notifs[0].title).toBe('New Leave Request');
    expect(notifs[0].body).toContain('Alice submitted a Leave Request');
    expect(notifs[0].entityType).toBe('REQUEST');
    expect(notifs[0].entityId).toBe('REQ-2026-0001');
  });

  // 5. Request-response / status change creates notification for requester
  test('5. REQUEST_RESPONDED event creates notification for requester', async () => {
    const mockRequest = {
      _id: new mongoose.Types.ObjectId(),
      id: 'req_123',
      requestId: 'REQ-2026-0001',
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      requesterUserId: new mongoose.Types.ObjectId(studentUserAId),
      requesterName: 'Alice',
      requesterRole: AppRole.STUDENT,
      targetRole: AppRole.HOD,
      requestType: 'LEAVE',
      title: 'Sick Leave',
      description: 'Need leave for 2 days',
      status: RequestStatus.APPROVED,
      responseMessage: 'Leave approved for 2 days.',
      history: [{ action: 'STATUS_CHANGED', newStatus: RequestStatus.APPROVED }],
    };

    requestEvents.emitResponded(mockRequest as any);

    await new Promise((r) => setTimeout(r, 100));

    const notifs = await Notification.find({
      recipientUserId: new mongoose.Types.ObjectId(studentUserAId),
    });

    expect(notifs.length).toBe(1);
    expect(notifs[0].notificationType).toBe(NotificationType.REQUEST_APPROVED);
    expect(notifs[0].title).toBe('Leave Request Approved');
    expect(notifs[0].body).toBe('Leave approved for 2 days.');
    expect(notifs[0].entityId).toBe('REQ-2026-0001');
  });

  // 6. Duplicate event does not create duplicate notification
  test('6. Duplicate event does not create duplicate notification (Idempotent)', async () => {
    const mockRequest = {
      _id: new mongoose.Types.ObjectId(),
      id: 'req_999',
      requestId: 'REQ-2026-0999',
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      requesterUserId: new mongoose.Types.ObjectId(studentUserAId),
      requesterName: 'Alice',
      requesterRole: AppRole.STUDENT,
      targetRole: AppRole.HOD,
      requestType: 'LEAVE',
      title: 'Duplicate Event Test',
      description: 'Testing idempotency',
      status: RequestStatus.SUBMITTED,
      history: [],
    };

    // Emit twice
    requestEvents.emitCreated(mockRequest as any);
    requestEvents.emitCreated(mockRequest as any);

    await new Promise((r) => setTimeout(r, 150));

    const notifs = await Notification.find({
      entityId: 'REQ-2026-0999',
      recipientUserId: new mongoose.Types.ObjectId(hodUserAId),
    });

    // Exactly one notification exists despite multiple event emissions
    expect(notifs.length).toBe(1);
  });

  // 7. Mark notification read persists
  test('7. Mark single notification read persists and updates readAt', async () => {
    const notif = await Notification.create({
      collegeId: collegeA._id,
      recipientUserId: new mongoose.Types.ObjectId(studentUserAId),
      title: 'Action Required',
      body: 'Please verify profile',
      notificationType: NotificationType.SYSTEM,
      isRead: false,
    });

    const res = await request(app)
      .patch(`/api/v1/notifications/${notif._id}/read`)
      .set(
        createTestAuthHeader({
          userId: studentUserAId,
          collegeId: collegeA._id.toString(),
          role: AppRole.STUDENT,
        })
      );

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.isRead).toBe(true);

    const updated = await Notification.findById(notif._id);
    expect(updated?.isRead).toBe(true);
    expect(updated?.readAt).toBeDefined();
  });

  // 8. Mark all read works
  test('8. Mark all read batch operation marks all user notifications as read', async () => {
    await Notification.create([
      {
        collegeId: collegeA._id,
        recipientUserId: new mongoose.Types.ObjectId(studentUserAId),
        title: 'Notice 1',
        body: 'Body 1',
        notificationType: NotificationType.SYSTEM,
        isRead: false,
      },
      {
        collegeId: collegeA._id,
        recipientUserId: new mongoose.Types.ObjectId(studentUserAId),
        title: 'Notice 2',
        body: 'Body 2',
        notificationType: NotificationType.SYSTEM,
        isRead: false,
      },
    ]);

    const res = await request(app)
      .patch('/api/v1/notifications/mark-all-read')
      .set(
        createTestAuthHeader({
          userId: studentUserAId,
          collegeId: collegeA._id.toString(),
          role: AppRole.STUDENT,
        })
      );

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.updatedCount).toBe(2);

    const unreadCount = await Notification.countDocuments({
      recipientUserId: new mongoose.Types.ObjectId(studentUserAId),
      isRead: false,
    });
    expect(unreadCount).toBe(0);
  });

  // 9. Unauthorized notification mutation is rejected
  test('9. Unauthorized notification mutation is rejected (User A cannot mark User B notif read)', async () => {
    const notifForB = await Notification.create({
      collegeId: collegeA._id,
      recipientUserId: new mongoose.Types.ObjectId(studentUserBId),
      title: 'Private to B',
      body: 'Do not touch',
      notificationType: NotificationType.SYSTEM,
      isRead: false,
    });

    const res = await request(app)
      .patch(`/api/v1/notifications/${notifForB._id}/read`)
      .set(
        createTestAuthHeader({
          userId: studentUserAId,
          collegeId: collegeA._id.toString(),
          role: AppRole.STUDENT,
        })
      );

    expect(res.status).toBe(404); // Scoped not-found error prevents leaking existence

    const notifStillUnread = await Notification.findById(notifForB._id);
    expect(notifStillUnread?.isRead).toBe(false);
  });
});
