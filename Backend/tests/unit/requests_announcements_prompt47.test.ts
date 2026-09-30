import mongoose, { Types } from 'mongoose';
import { MongoMemoryServer } from 'mongodb-memory-server';
import {
  RequestModel,
  Announcement,
  College,
  Department,
  User,
  Student,
  StudentEnrollment,
  Faculty,
  FacultyAssignment,
  Section,
  AttendanceSession,
  Notification,
} from '../../src/models';
import { RequestStatus } from '../../src/constants/request.constants';
import {
  AudienceScope,
  AnnouncementStatus,
  NotificationCategory,
  NotificationPriority,
} from '../../src/constants/notification.constants';
import { AppRole } from '../../src/constants/roles';
import { RequestService } from '../../src/services/request.service';
import { AnnouncementService } from '../../src/services/announcement.service';
import { initRequestNotificationListener } from '../../src/events/requestNotification.listener';
import { realtimeEventBus } from '../../src/realtime';

describe('PROMPT 47 — Requests, Approval Workflow & Announcements Tests', () => {
  let mongoServer: MongoMemoryServer;

  let collegeAId: Types.ObjectId;
  let collegeBId: Types.ObjectId;
  let departmentAId: Types.ObjectId;
  let departmentBId: Types.ObjectId;

  let studentAId: Types.ObjectId;
  let facultyAId: Types.ObjectId;
  let hodAId: Types.ObjectId;
  let adminAId: Types.ObjectId;
  let studentBId: Types.ObjectId;

  let studentProfileAId: Types.ObjectId;
  let facultyProfileAId: Types.ObjectId;

  let courseAId: Types.ObjectId;
  let sectionAId: Types.ObjectId;
  let semesterAId: Types.ObjectId;

  const publishedRealtimeEvents: any[] = [];
  let eventHandler: any;

  beforeAll(async () => {
    mongoServer = await MongoMemoryServer.create();
    await mongoose.connect(mongoServer.getUri());

    initRequestNotificationListener();

    eventHandler = (event: any) => {
      publishedRealtimeEvents.push(event);
    };
    realtimeEventBus.on('*', eventHandler);

    collegeAId = new Types.ObjectId();
    collegeBId = new Types.ObjectId();
    departmentAId = new Types.ObjectId();
    departmentBId = new Types.ObjectId();

    studentAId = new Types.ObjectId();
    facultyAId = new Types.ObjectId();
    hodAId = new Types.ObjectId();
    adminAId = new Types.ObjectId();
    studentBId = new Types.ObjectId();

    studentProfileAId = new Types.ObjectId();
    facultyProfileAId = new Types.ObjectId();

    courseAId = new Types.ObjectId();
    sectionAId = new Types.ObjectId();
    semesterAId = new Types.ObjectId();

    await College.create([
      {
        _id: collegeAId,
        name: 'College Alpha',
        code: 'CALPHA',
        principal: 'Dr. Alpha',
        phone: '1111111111',
        email: 'alpha@acadex.edu',
        address: '1 Alpha Road',
      },
      {
        _id: collegeBId,
        name: 'College Beta',
        code: 'CBETA',
        principal: 'Dr. Beta',
        phone: '2222222222',
        email: 'beta@acadex.edu',
        address: '2 Beta Road',
      },
    ]);

    await Department.create([
      {
        _id: departmentAId,
        collegeId: collegeAId,
        name: 'Computer Science',
        code: 'CS',
        hodId: hodAId,
      },
      {
        _id: departmentBId,
        collegeId: collegeBId,
        name: 'Mechanical Engineering',
        code: 'ME',
      },
    ]);

    await User.create([
      {
        _id: studentAId,
        instituteId: 'INST_STU_A',
        collegeId: collegeAId,
        departmentId: departmentAId,
        email: 'studentA@acadex.edu',
        name: 'Student Alpha',
        role: AppRole.STUDENT,
      },
      {
        _id: facultyAId,
        instituteId: 'INST_FAC_A',
        collegeId: collegeAId,
        departmentId: departmentAId,
        email: 'facultyA@acadex.edu',
        name: 'Prof. Alpha',
        role: AppRole.FACULTY,
      },
      {
        _id: hodAId,
        instituteId: 'INST_HOD_A',
        collegeId: collegeAId,
        departmentId: departmentAId,
        email: 'hodA@acadex.edu',
        name: 'HOD Alpha',
        role: AppRole.HOD,
      },
      {
        _id: adminAId,
        instituteId: 'INST_ADM_A',
        collegeId: collegeAId,
        email: 'adminA@acadex.edu',
        name: 'Admin Alpha',
        role: AppRole.COLLEGE_ADMIN,
      },
      {
        _id: studentBId,
        instituteId: 'INST_STU_B',
        collegeId: collegeBId,
        departmentId: departmentBId,
        email: 'studentB@acadex.edu',
        name: 'Student Beta',
        role: AppRole.STUDENT,
      },
    ]);

    await Student.create({
      _id: studentProfileAId,
      userId: studentAId,
      name: 'Student Alpha',
      collegeId: collegeAId,
      departmentId: departmentAId,
      rollNumber: 'CS001',
      admissionNumber: 'ADM001',
      admissionYear: 2024,
    });

    await Faculty.create({
      _id: facultyProfileAId,
      userId: facultyAId,
      name: 'Prof. Alpha',
      email: 'facultyA@acadex.edu',
      collegeId: collegeAId,
      departmentId: departmentAId,
      employeeId: 'FAC001',
      designation: 'Assistant Professor',
    });

    await StudentEnrollment.create({
      collegeId: collegeAId,
      departmentId: departmentAId,
      studentId: studentProfileAId,
      courseId: courseAId,
      semesterId: semesterAId,
      sectionId: sectionAId,
      academicYearId: new Types.ObjectId(),
      status: 'active',
      enrollmentDate: new Date(),
    });

    await FacultyAssignment.create({
      collegeId: collegeAId,
      departmentId: departmentAId,
      facultyId: facultyProfileAId,
      facultyName: 'Prof. Alpha',
      courseId: courseAId,
      semesterId: semesterAId,
      sectionId: sectionAId,
      subjectId: new Types.ObjectId(),
      academicYearId: new Types.ObjectId(),
      status: 'active',
      isActive: true,
      assignedAt: new Date(),
    });

    await Section.create({
      _id: sectionAId,
      collegeId: collegeAId,
      departmentId: departmentAId,
      courseId: courseAId,
      semesterId: semesterAId,
      name: 'CS-A',
    });
  });

  afterAll(async () => {
    realtimeEventBus.off('*', eventHandler);
    await mongoose.disconnect();
    await mongoServer.stop();
  });

  beforeEach(async () => {
    publishedRealtimeEvents.length = 0;
    await RequestModel.deleteMany({});
    await Notification.deleteMany({});
  });

  // =========================================================================
  // PART 1: REQUESTS MODULE TESTS
  // =========================================================================
  describe('1. Requests Creation & Lifecycle', () => {
    it('1.1 allows Student to save a request as DRAFT without emitting authority notification', async () => {
      const draft = await RequestService.createRequest(
        {
          requestType: 'LEAVE',
          title: 'Medical Leave',
          description: 'Feeling unwell with fever',
          status: RequestStatus.DRAFT,
        },
        {
          id: studentAId.toString(),
          collegeId: collegeAId.toString(),
          role: AppRole.STUDENT,
          name: 'Student Alpha',
          departmentId: departmentAId.toString(),
        } as any
      );

      expect(draft.status).toBe(RequestStatus.DRAFT);
      expect(draft.requesterUserId.toString()).toBe(studentAId.toString());
      expect(draft.history.length).toBe(1);
      expect(draft.history[0].status).toBe(RequestStatus.DRAFT);

      // Verify no notification was created for HOD yet
      const notifs = await Notification.find({ recipientUserId: hodAId });
      expect(notifs.length).toBe(0);
    });

    it('1.2 allows Student to submit a draft request and triggers authority notification', async () => {
      const draft = await RequestService.createRequest(
        {
          requestType: 'LEAVE',
          title: 'Draft to Submit',
          description: 'Family emergency leave',
          status: RequestStatus.DRAFT,
        },
        {
          id: studentAId.toString(),
          collegeId: collegeAId.toString(),
          role: AppRole.STUDENT,
          name: 'Student Alpha',
          departmentId: departmentAId.toString(),
        } as any
      );

      const submitted = await RequestService.submitRequest(draft.id, {
        id: studentAId.toString(),
        collegeId: collegeAId.toString(),
        role: AppRole.STUDENT,
        name: 'Student Alpha',
      } as any);

      expect(submitted.status).toBe(RequestStatus.SUBMITTED);
      expect(submitted.history.length).toBe(2);
      expect(submitted.history[1].status).toBe(RequestStatus.SUBMITTED);

      // Give async notification listener a tick to persist notification
      await new Promise((r) => setTimeout(r, 60));

      // Verify notification was sent to HOD
      const notif = await Notification.findOne({
        recipientUserId: hodAId,
        notificationType: 'REQUEST_RECEIVED',
      });
      expect(notif).toBeDefined();
      expect(notif?.title).toContain('Leave Request');
    });

    it('1.3 rejects another user attempting to submit someone else draft', async () => {
      const draft = await RequestService.createRequest(
        {
          requestType: 'GENERAL_REQUEST',
          title: 'Student A Draft',
          description: 'Requesting permission',
          status: RequestStatus.DRAFT,
        },
        {
          id: studentAId.toString(),
          collegeId: collegeAId.toString(),
          role: AppRole.STUDENT,
          name: 'Student Alpha',
        } as any
      );

      await expect(
        RequestService.submitRequest(draft.id, {
          id: facultyAId.toString(),
          collegeId: collegeAId.toString(),
          role: AppRole.FACULTY,
          name: 'Prof Alpha',
        } as any)
      ).rejects.toThrow('Only the requester can submit their draft request');
    });

    it('1.4 allows Student to cancel their submitted request', async () => {
      const req = await RequestService.createRequest(
        {
          requestType: 'LEAVE',
          title: 'Leave to Cancel',
          description: 'Will cancel this request',
        },
        {
          id: studentAId.toString(),
          collegeId: collegeAId.toString(),
          role: AppRole.STUDENT,
          name: 'Student Alpha',
          departmentId: departmentAId.toString(),
        } as any
      );

      const cancelled = await RequestService.cancelRequest(req.id, 'Plans changed', {
        id: studentAId.toString(),
        collegeId: collegeAId.toString(),
        role: AppRole.STUDENT,
        name: 'Student Alpha',
      } as any);

      expect(cancelled.status).toBe(RequestStatus.CANCELLED);
      expect(cancelled.history[cancelled.history.length - 1].note).toBe('Plans changed');
    });

    it('1.5 prevents Student from approving their own request', async () => {
      const req = await RequestService.createRequest(
        {
          requestType: 'LEAVE',
          title: 'Self-approval Attempt',
          description: 'Testing self approval rejection',
        },
        {
          id: studentAId.toString(),
          collegeId: collegeAId.toString(),
          role: AppRole.STUDENT,
          name: 'Student Alpha',
          departmentId: departmentAId.toString(),
        } as any
      );

      await expect(
        RequestService.respondToRequest(
          req.id,
          { action: 'APPROVED', message: 'I approve myself' },
          {
            id: studentAId.toString(),
            collegeId: collegeAId.toString(),
            role: AppRole.STUDENT,
            name: 'Student Alpha',
          } as any
        )
      ).rejects.toThrow('Requesters cannot respond to or resolve their own request');
    });

    it('1.6 enforces mandatory meaningful rejection reason (>= 5 chars)', async () => {
      const req = await RequestService.createRequest(
        {
          requestType: 'LEAVE',
          title: 'Leave to Reject',
          description: 'Leave request for testing rejection validation',
        },
        {
          id: studentAId.toString(),
          collegeId: collegeAId.toString(),
          role: AppRole.STUDENT,
          name: 'Student Alpha',
          departmentId: departmentAId.toString(),
        } as any
      );

      // Short / empty rejection reason must fail
      await expect(
        RequestService.respondToRequest(
          req.id,
          { action: 'REJECTED', message: 'No' },
          {
            id: hodAId.toString(),
            collegeId: collegeAId.toString(),
            role: AppRole.HOD,
            name: 'HOD Alpha',
            departmentId: departmentAId.toString(),
          } as any
        )
      ).rejects.toThrow('A meaningful rejection reason (at least 5 characters) is required');

      // Meaningful rejection reason succeeds
      const rejected = await RequestService.respondToRequest(
        req.id,
        { action: 'REJECTED', message: 'Exam scheduled on the requested date' },
        {
          id: hodAId.toString(),
          collegeId: collegeAId.toString(),
          role: AppRole.HOD,
          name: 'HOD Alpha',
          departmentId: departmentAId.toString(),
        } as any
      );

      expect(rejected.status).toBe(RequestStatus.REJECTED);
      expect(rejected.responseMessage).toBe('Exam scheduled on the requested date');
    });

    it('1.7 allows authorized HOD to approve request and protects against double review', async () => {
      const req = await RequestService.createRequest(
        {
          requestType: 'LEAVE',
          title: 'Leave for Approval',
          description: 'Valid leave request',
        },
        {
          id: studentAId.toString(),
          collegeId: collegeAId.toString(),
          role: AppRole.STUDENT,
          name: 'Student Alpha',
          departmentId: departmentAId.toString(),
        } as any
      );

      const approved = await RequestService.respondToRequest(
        req.id,
        { action: 'APPROVED', message: 'Leave granted' },
        {
          id: hodAId.toString(),
          collegeId: collegeAId.toString(),
          role: AppRole.HOD,
          name: 'HOD Alpha',
          departmentId: departmentAId.toString(),
        } as any
      );

      expect(approved.status).toBe(RequestStatus.APPROVED);

      // Attempting to re-approve an already approved request must fail
      await expect(
        RequestService.respondToRequest(
          req.id,
          { action: 'APPROVED', message: 'Trying again' },
          {
            id: hodAId.toString(),
            collegeId: collegeAId.toString(),
            role: AppRole.HOD,
            name: 'HOD Alpha',
            departmentId: departmentAId.toString(),
          } as any
        )
      ).rejects.toThrow('Invalid status transition');
    });

    it('1.8 rejects cross-tenant linked entity reference', async () => {
      // Create an attendance session in College B
      const sessionB = await AttendanceSession.create({
        collegeId: collegeBId,
        departmentId: departmentBId,
        facultyId: new Types.ObjectId(),
        subjectId: new Types.ObjectId(),
        subjectName: 'Thermodynamics',
        timeSlot: '09:00 - 10:00',
        date: new Date(),
        records: [],
      });

      // Student in College A references College B session
      await expect(
        RequestService.createRequest(
          {
            requestType: 'ATTENDANCE_CORRECTION',
            title: 'Cross-tenant reference',
            description: 'Trying to reference session in College B',
            relatedEntityType: 'ATTENDANCE_SESSION',
            relatedEntityId: sessionB.id,
          },
          {
            id: studentAId.toString(),
            collegeId: collegeAId.toString(),
            role: AppRole.STUDENT,
            name: 'Student Alpha',
            departmentId: departmentAId.toString(),
          } as any
        )
      ).rejects.toThrow('Referenced attendance session does not exist in your college');
    });

    it('1.9 enforces tenant isolation: College B student cannot access College A request', async () => {
      const req = await RequestService.createRequest(
        {
          requestType: 'GENERAL_REQUEST',
          title: 'College A Private Request',
          description: 'Private to College A',
        },
        {
          id: studentAId.toString(),
          collegeId: collegeAId.toString(),
          role: AppRole.STUDENT,
          name: 'Student Alpha',
        } as any
      );

      await expect(
        RequestService.getRequestById(req.id, {
          id: studentBId.toString(),
          collegeId: collegeBId.toString(),
          role: AppRole.STUDENT,
          name: 'Student Beta',
        } as any)
      ).rejects.toThrow('You no longer have access to this request');
    });

    it('1.10 provides accurate summary counts for student and reviewer', async () => {
      const counts = await RequestService.getSummaryCounts({
        id: studentAId.toString(),
        collegeId: collegeAId.toString(),
        role: AppRole.STUDENT,
      } as any);

      expect(typeof counts.myPendingCount).toBe('number');
      expect(counts.incomingCount).toBe(0); // Students have 0 incoming requests
    });
  });

  // =========================================================================
  // PART 2: ANNOUNCEMENTS MODULE TESTS
  // =========================================================================
  describe('2. Announcements Authoring & Audience Delivery', () => {
    it('2.1 strictly prevents Student from creating announcements', async () => {
      await expect(
        AnnouncementService.createAnnouncement(
          {
            title: 'Student Announcement Attempt',
            body: 'Students should not be allowed to post',
            audienceScope: AudienceScope.COLLEGE,
          },
          {
            id: studentAId.toString(),
            collegeId: collegeAId.toString(),
            role: AppRole.STUDENT,
            name: 'Student Alpha',
          } as any
        )
      ).rejects.toThrow('Students are not authorized to create announcements');
    });

    it('2.2 strictly prevents Faculty from publishing college-wide announcements', async () => {
      await expect(
        AnnouncementService.createAnnouncement(
          {
            title: 'Faculty College Announcement',
            body: 'Trying to broadcast college-wide',
            audienceScope: AudienceScope.COLLEGE,
          },
          {
            id: facultyAId.toString(),
            collegeId: collegeAId.toString(),
            role: AppRole.FACULTY,
            name: 'Prof Alpha',
            departmentId: departmentAId.toString(),
          } as any
        )
      ).rejects.toThrow('Faculty are not authorized to publish college-wide or department-wide announcements');
    });

    it('2.3 allows Faculty to create announcement for their assigned Section', async () => {
      const announcement = await AnnouncementService.createAnnouncement(
        {
          title: 'Class Project Instructions',
          body: 'Submission guidelines for CS Section A',
          audienceScope: AudienceScope.SECTION,
          targetSectionId: sectionAId.toString(),
          departmentId: departmentAId.toString(),
        },
        {
          id: facultyAId.toString(),
          collegeId: collegeAId.toString(),
          role: AppRole.FACULTY,
          name: 'Prof Alpha',
          departmentId: departmentAId.toString(),
        } as any
      );

      expect(announcement).toBeDefined();
      expect(announcement.audienceScope).toBe(AudienceScope.SECTION);
      expect(announcement.status).toBe(AnnouncementStatus.DRAFT);
    });

    it('2.4 allows College Admin to create and publish a college-wide announcement', async () => {
      const announcement = await AnnouncementService.createAnnouncement(
        {
          title: 'Campus Founder Day Holiday',
          body: 'College will remain closed on Friday for Founder Day celebration.',
          audienceScope: AudienceScope.COLLEGE,
          publishNow: true,
          priority: NotificationPriority.HIGH,
        },
        {
          id: adminAId.toString(),
          collegeId: collegeAId.toString(),
          role: AppRole.COLLEGE_ADMIN,
          name: 'Admin Alpha',
        } as any
      );

      expect(announcement.status).toBe(AnnouncementStatus.PUBLISHED);
      expect(announcement.publishedAt).toBeDefined();

      // Check notification created for enrolled students in College A
      const notif = await Notification.findOne({
        recipientUserId: studentAId,
        category: NotificationCategory.ANNOUNCEMENT,
      });
      expect(notif).toBeDefined();
      expect(notif?.title).toContain('Campus Founder Day Holiday');
    });

    it('2.5 publishing announcement is idempotent and does not duplicate notifications', async () => {
      const draft = await AnnouncementService.createAnnouncement(
        {
          title: 'Idempotency Test Notice',
          body: 'Testing repeated publish idempotency',
          audienceScope: AudienceScope.DEPARTMENT,
          departmentId: departmentAId.toString(),
        },
        {
          id: hodAId.toString(),
          collegeId: collegeAId.toString(),
          role: AppRole.HOD,
          name: 'HOD Alpha',
          departmentId: departmentAId.toString(),
        } as any
      );

      const pub1 = await AnnouncementService.publishAnnouncement(draft.id, {
        id: hodAId.toString(),
        collegeId: collegeAId.toString(),
        role: AppRole.HOD,
        name: 'HOD Alpha',
        departmentId: departmentAId.toString(),
      } as any);

      const count1 = await Notification.countDocuments({
        'metadata.announcementId': draft.id,
      });

      // Second publish must be idempotent
      const pub2 = await AnnouncementService.publishAnnouncement(draft.id, {
        id: hodAId.toString(),
        collegeId: collegeAId.toString(),
        role: AppRole.HOD,
        name: 'HOD Alpha',
        departmentId: departmentAId.toString(),
      } as any);

      expect(pub1.id).toBe(pub2.id);

      const count2 = await Notification.countDocuments({
        'metadata.announcementId': draft.id,
      });
      expect(count2).toBe(count1); // Zero duplicate notifications created
    });

    it('2.6 allows authorized user to cancel an announcement', async () => {
      const announcement = await AnnouncementService.createAnnouncement(
        {
          title: 'Event to Cancel',
          body: 'This event will be cancelled',
          audienceScope: AudienceScope.COLLEGE,
        },
        {
          id: adminAId.toString(),
          collegeId: collegeAId.toString(),
          role: AppRole.COLLEGE_ADMIN,
          name: 'Admin Alpha',
        } as any
      );

      const cancelled = await AnnouncementService.cancelAnnouncement(announcement.id, {
        id: adminAId.toString(),
        collegeId: collegeAId.toString(),
        role: AppRole.COLLEGE_ADMIN,
        name: 'Admin Alpha',
      } as any);

      expect(cancelled.status).toBe(AnnouncementStatus.CANCELLED);
    });

    it('2.7 filters out expired announcements from user recipient feed', async () => {
      const yesterday = new Date(Date.now() - 24 * 3600 * 1000);
      const twoDaysAgo = new Date(Date.now() - 48 * 3600 * 1000);

      // Create an expired announcement directly in DB
      await Announcement.create({
        collegeId: collegeAId,
        title: 'Old Expired Notice',
        body: 'This notice expired yesterday',
        category: NotificationCategory.ANNOUNCEMENT,
        audienceScope: AudienceScope.COLLEGE,
        status: AnnouncementStatus.PUBLISHED,
        publishAt: twoDaysAgo,
        expiresAt: yesterday,
        createdBy: adminAId,
        publishedAt: twoDaysAgo,
      });

      const feed = await AnnouncementService.listAnnouncements(
        { manage: false },
        {
          id: studentAId.toString(),
          collegeId: collegeAId.toString(),
          role: AppRole.STUDENT,
          departmentId: departmentAId.toString(),
        } as any
      );

      const foundExpired = feed.items.find((a) => a.title === 'Old Expired Notice');
      expect(foundExpired).toBeUndefined(); // Expired announcement must be hidden from feed
    });

    it('2.8 filters audience: Student B in College B cannot see College A announcements', async () => {
      const feedB = await AnnouncementService.listAnnouncements(
        { manage: false },
        {
          id: studentBId.toString(),
          collegeId: collegeBId.toString(),
          role: AppRole.STUDENT,
          departmentId: departmentBId.toString(),
        } as any
      );

      const foundAlpha = feedB.items.find((a) => a.title.includes('Founder Day'));
      expect(foundAlpha).toBeUndefined(); // College B student never sees College A announcements
    });
  });
});
