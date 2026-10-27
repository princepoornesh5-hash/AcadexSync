import request from 'supertest';
import mongoose from 'mongoose';
import { app } from '../../src/app';
import { College } from '../../src/models/college.model';
import { Department } from '../../src/models/department.model';
import { Course } from '../../src/models/course.model';
import { AcademicYear } from '../../src/models/academicYear.model';
import { Semester } from '../../src/models/semester.model';
import { Section } from '../../src/models/section.model';
import { Subject } from '../../src/models/subject.model';
import { Faculty } from '../../src/models/faculty.model';
import { FacultyAssignment } from '../../src/models/facultyAssignment.model';
import { Assignment } from '../../src/models/assignment.model';
import { CalendarEvent } from '../../src/models/calendarEvent.model';
import { PendingAction } from '../../src/models/pendingAction.model';
import { AuditLog } from '../../src/models/auditLog.model';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';
import { User } from '../../src/models/user.model';
import { AccountStatus } from '../../src/constants/status';
import { AppRole } from '../../src/constants/roles';
import { AssignmentStatus, AssignmentType } from '../../src/constants/assignment.constants';
import { CalendarEventType, CalendarEventScope, CalendarSourceType, CalendarEventStatus } from '../../src/constants/calendar.constants';
import { AssignmentService } from '../../src/services/assignment.service';
import { AcademicCalendarService } from '../../src/services/academicCalendar.service';
import { AiService } from '../../src/services/ai.service';
import { env } from '../../src/config/env';

describe('AI Chat & Confirmed Actions Integration Tests', () => {
  let testCollege: InstanceType<typeof College>;
  let testDept: InstanceType<typeof Department>;
  let testCourse: InstanceType<typeof Course>;
  let testYear: InstanceType<typeof AcademicYear>;
  let testSem: InstanceType<typeof Semester>;
  let testSec: InstanceType<typeof Section>;
  let testSub: InstanceType<typeof Subject>;
  let testFaculty: InstanceType<typeof Faculty>;
  let testFa: InstanceType<typeof FacultyAssignment>;
  let testFacultyUser: InstanceType<typeof User>;
  let testStudentUser: InstanceType<typeof User>;
  let testHodUser: InstanceType<typeof User>;
  let testImposterUser: InstanceType<typeof User>;

  beforeAll(async () => {
    await setupTestDB();
  });

  afterAll(async () => {
    await teardownTestDB();
    AiService.clearMockClient();
  });

  beforeEach(async () => {
    await clearTestDB();
    AiService.clearMockClient();

    testCollege = await College.create({
      name: 'ACADEX Institute of Technology',
      code: 'AIT',
      address: '100 University Avenue',
      email: 'contact@ait.edu',
      phone: '+1-555-0199',
      principal: 'Dr. Jane Academic',
    });

    testDept = await Department.create({
      collegeId: testCollege._id,
      name: 'Computer Science',
      code: 'CSE',
    });

    testFacultyUser = await User.create({
      _id: new mongoose.Types.ObjectId('65a123456789abcdef123456'),
      instituteId: 'FAC-IOT-01',
      name: 'Prof. Alan Turing',
      email: 'alan.turing@ait.edu',
      role: AppRole.FACULTY,
      collegeId: testCollege._id,
      departmentId: testDept._id,
      accountStatus: AccountStatus.ACTIVE,
      activationStatus: 'activated',
    });

    testStudentUser = await User.create({
      _id: new mongoose.Types.ObjectId('65a123456789abcdef123457'),
      instituteId: 'STU-CSE-01',
      name: 'Ada Lovelace',
      email: 'ada.lovelace@ait.edu',
      role: AppRole.STUDENT,
      collegeId: testCollege._id,
      departmentId: testDept._id,
      accountStatus: AccountStatus.ACTIVE,
      activationStatus: 'activated',
    });

    testHodUser = await User.create({
      _id: new mongoose.Types.ObjectId('65a123456789abcdef123458'),
      instituteId: 'HOD-CSE-01',
      name: 'Dr. Claude Shannon',
      email: 'claude.shannon@ait.edu',
      role: AppRole.HOD,
      collegeId: testCollege._id,
      departmentId: testDept._id,
      accountStatus: AccountStatus.ACTIVE,
      activationStatus: 'activated',
    });

    testImposterUser = await User.create({
      _id: new mongoose.Types.ObjectId('65a123456789abcdef123459'),
      instituteId: 'FAC-IMP-01',
      name: 'Prof. Imposter',
      email: 'imposter@ait.edu',
      role: AppRole.FACULTY,
      collegeId: testCollege._id,
      departmentId: testDept._id,
      accountStatus: AccountStatus.ACTIVE,
      activationStatus: 'activated',
    });

    testDept.hodId = testHodUser._id as any;
    await testDept.save();

    testCourse = await Course.create({
      collegeId: testCollege._id,
      departmentId: testDept._id,
      name: 'B.Tech CSE',
      code: 'BTCSE',
      durationYears: 4,
    });

    testYear = await AcademicYear.create({
      collegeId: testCollege._id,
      name: '2026-2027',
      code: 'AY26',
      startDate: new Date('2026-06-01'),
      endDate: new Date('2027-05-31'),
    });

    testSem = await Semester.create({
      collegeId: testCollege._id,
      departmentId: testDept._id,
      courseId: testCourse._id,
      academicYearId: testYear._id,
      name: 'Semester 5',
      number: 5,
      startDate: new Date('2026-06-01'),
      endDate: new Date('2026-12-31'),
    });

    testSec = await Section.create({
      collegeId: testCollege._id,
      departmentId: testDept._id,
      courseId: testCourse._id,
      semesterId: testSem._id,
      name: 'Section A',
    });

    testSub = await Subject.create({
      collegeId: testCollege._id,
      departmentId: testDept._id,
      courseId: testCourse._id,
      semesterId: testSem._id,
      name: 'Internet of Things',
      code: 'IOT501',
      type: 'theory',
    });

    testFaculty = await Faculty.create({
      collegeId: testCollege._id,
      departmentId: testDept._id,
      userId: testFacultyUser._id,
      instituteId: 'FAC-IOT-01',
      name: 'Prof. Alan Turing',
      email: 'alan.turing@ait.edu',
      status: 'active',
      isActive: true,
      subjectIds: [testSub._id],
      sectionIds: [testSec._id],
    });

    testFa = await FacultyAssignment.create({
      collegeId: testCollege._id,
      departmentId: testDept._id,
      facultyId: testFaculty._id,
      facultyName: testFaculty.name,
      courseId: testCourse._id,
      semesterId: testSem._id,
      sectionId: testSec._id,
      subjectId: testSub._id,
      academicYearId: testYear._id,
      status: 'active',
      isActive: true,
    });
  });

  describe('Phase 1 Baseline & Security Bounds', () => {
    it('should reject unauthenticated request with 401 Unauthorized', async () => {
      const res = await request(app)
        .post('/api/v1/ai/chat')
        .send({ message: 'What is my schedule for today?' });

      expect(res.status).toBe(401);
      expect(res.body.success).toBe(false);
      expect(res.body.error.code).toBe('UNAUTHORIZED');
    });

    it('should reject cross-college tenant request with 403 Forbidden', async () => {
      const authHeader = createTestAuthHeader({
        role: AppRole.STUDENT,
        userId: 'usr_student_1',
        collegeId: testCollege.id,
      });

      const res = await request(app)
        .post('/api/v1/ai/chat')
        .set(authHeader)
        .send({
          message: 'Hello',
          collegeId: '60c72b2f9b1d8b001f8e4a99',
        });

      expect(res.status).toBe(403);
      expect(res.body.error.code).toBe('FORBIDDEN');
    });

    it('should return 503 safe error when GEMINI_API_KEY is not configured', async () => {
      const originalKey = env.GEMINI_API_KEY;
      (env as any).GEMINI_API_KEY = '';

      const authHeader = createTestAuthHeader({
        role: AppRole.STUDENT,
        userId: 'usr_student_1',
        collegeId: testCollege.id,
      });

      const res = await request(app)
        .post('/api/v1/ai/chat')
        .set(authHeader)
        .send({ message: 'Hello AI' });

      (env as any).GEMINI_API_KEY = originalKey;

      expect(res.status).toBe(503);
      expect(res.body.error.code).toBe('AI_CONFIG_ERROR');
    });
  });

  describe('Phase 2: Read-Only Academic Tool Calling', () => {
    it('should execute get_my_timetable tool and format results back to model', async () => {
      // Mock Gemini proposing get_my_timetable then answering based on the returned data
      const mockClient = {
        models: {
          generateContent: jest
            .fn()
            .mockResolvedValueOnce({
              functionCalls: [
                {
                  name: 'get_my_timetable',
                  args: { day: 'monday' },
                  id: 'call_timetable_1',
                },
              ],
            })
            .mockResolvedValueOnce({
              text: 'You have no classes scheduled for Monday.',
            }),
        },
      };
      AiService.setMockClient(mockClient);

      const authHeader = createTestAuthHeader({
        role: AppRole.FACULTY,
        userId: testFaculty.userId.toString(),
        name: testFaculty.name,
        collegeId: testCollege.id,
      });

      const res = await request(app)
        .post('/api/v1/ai/chat')
        .set(authHeader)
        .send({ message: 'What classes do I teach on Monday?' });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.answer).toContain('Monday');
      expect(mockClient.models.generateContent).toHaveBeenCalledTimes(2);
    });

    it('should execute get_my_assignments tool for faculty', async () => {
      const mockClient = {
        models: {
          generateContent: jest
            .fn()
            .mockResolvedValueOnce({
              functionCalls: [
                {
                  name: 'get_my_assignments',
                  args: { status: 'published' },
                  id: 'call_assign_1',
                },
              ],
            })
            .mockResolvedValueOnce({
              text: 'Here are your current assignments: none found in published state.',
            }),
        },
      };
      AiService.setMockClient(mockClient);

      const authHeader = createTestAuthHeader({
        role: AppRole.FACULTY,
        userId: testFaculty.userId.toString(),
        collegeId: testCollege.id,
      });

      const res = await request(app)
        .post('/api/v1/ai/chat')
        .set(authHeader)
        .send({ message: 'Show me my published assignments.' });

      expect(res.status).toBe(200);
      expect(res.body.data.answer).toContain('assignments');
    });

    it('should execute get_calendar_events tool', async () => {
      const mockClient = {
        models: {
          generateContent: jest
            .fn()
            .mockResolvedValueOnce({
              functionCalls: [
                {
                  name: 'get_calendar_events',
                  args: { startDate: '2026-10-01', endDate: '2026-10-31' },
                  id: 'call_cal_1',
                },
              ],
            })
            .mockResolvedValueOnce({
              text: 'There are no calendar events scheduled for October 2026.',
            }),
        },
      };
      AiService.setMockClient(mockClient);

      const authHeader = createTestAuthHeader({
        role: AppRole.STUDENT,
        userId: testStudentUser.id,
        collegeId: testCollege.id,
      });

      const res = await request(app)
        .post('/api/v1/ai/chat')
        .set(authHeader)
        .send({ message: 'Any holidays or exams in October?' });

      expect(res.status).toBe(200);
      expect(res.body.data.answer).toContain('October');
    });

    it('should safely handle unknown tool calls by reporting limitation to model', async () => {
      const mockClient = {
        models: {
          generateContent: jest
            .fn()
            .mockResolvedValueOnce({
              functionCalls: [
                {
                  name: 'hack_database_records',
                  args: {},
                  id: 'call_bad_1',
                },
              ],
            })
            .mockResolvedValueOnce({
              text: 'I cannot perform direct database operations.',
            }),
        },
      };
      AiService.setMockClient(mockClient);

      const authHeader = createTestAuthHeader({
        role: AppRole.STUDENT,
        userId: 'usr_student_1',
        collegeId: testCollege.id,
      });

      const res = await request(app)
        .post('/api/v1/ai/chat')
        .set(authHeader)
        .send({ message: 'Modify grades directly' });

      expect(res.status).toBe(200);
      expect(res.body.data.answer).toContain('database');
    });
  });

  describe('Phase 3: Assignment Creation Workflow (Confirmed Write)', () => {
    it('should reject student attempt to propose assignment creation', async () => {
      const mockClient = {
        models: {
          generateContent: jest
            .fn()
            .mockResolvedValueOnce({
              functionCalls: [
                {
                  name: 'propose_create_assignment',
                  args: {
                    title: 'Student Created Assignment',
                    subject: 'IoT',
                    section: 'A',
                    dueDate: '2026-11-15',
                  },
                  id: 'call_asgn_stu',
                },
              ],
            })
            .mockResolvedValueOnce({
              text: 'Students are not authorized to create assignments.',
            }),
        },
      };
      AiService.setMockClient(mockClient);

      const authHeader = createTestAuthHeader({
        role: AppRole.STUDENT,
        userId: 'usr_stu_forbidden',
        collegeId: testCollege.id,
      });

      const res = await request(app)
        .post('/api/v1/ai/chat')
        .set(authHeader)
        .send({ message: 'Create an assignment for Section A' });

      expect(res.status).toBe(200);
      expect(res.body.data.proposal).toBeUndefined();
      expect(await Assignment.countDocuments()).toBe(0);
      expect(await PendingAction.countDocuments()).toBe(0);
    });

    it('should return error when faculty tries to create assignment for an unauthorized subject/section', async () => {
      const mockClient = {
        models: {
          generateContent: jest
            .fn()
            .mockResolvedValueOnce({
              functionCalls: [
                {
                  name: 'propose_create_assignment',
                  args: {
                    title: 'Quantum Physics Homework',
                    subject: 'Physics',
                    section: 'Z',
                    dueDate: '2026-11-20',
                  },
                  id: 'call_asgn_unauth',
                },
              ],
            })
            .mockResolvedValueOnce({
              text: 'You are not assigned to teach Physics in Section Z.',
            }),
        },
      };
      AiService.setMockClient(mockClient);

      const authHeader = createTestAuthHeader({
        role: AppRole.FACULTY,
        userId: testFaculty.userId.toString(),
        collegeId: testCollege.id,
      });

      const res = await request(app)
        .post('/api/v1/ai/chat')
        .set(authHeader)
        .send({ message: 'Create physics assignment for Section Z' });

      expect(res.status).toBe(200);
      expect(res.body.data.proposal).toBeUndefined();
      expect(await Assignment.countDocuments()).toBe(0);
    });

    it('should generate proposal preview WITHOUT writing to DB when faculty proposes valid assignment', async () => {
      const mockClient = {
        models: {
          generateContent: jest.fn().mockResolvedValueOnce({
            functionCalls: [
              {
                name: 'propose_create_assignment',
                args: {
                  title: 'Smart City Sensor Analysis',
                  subject: 'Internet of Things',
                  section: 'Section A',
                  dueDate: '2026-11-25',
                  dueTime: '05:00 PM',
                  maximumMarks: 50,
                  description: 'Analyze MQTT protocol data packets from urban sensor network.',
                },
                id: 'call_asgn_valid',
              },
            ],
          }),
        },
      };
      AiService.setMockClient(mockClient);

      const authHeader = createTestAuthHeader({
        role: AppRole.FACULTY,
        userId: testFaculty.userId.toString(),
        name: testFaculty.name,
        collegeId: testCollege.id,
      });

      const res = await request(app)
        .post('/api/v1/ai/chat')
        .set(authHeader)
        .send({ message: 'Create an IoT assignment for Section A due Nov 25 at 5 PM' });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);

      // Verify proposal is returned with preview
      const proposal = res.body.data.proposal;
      expect(proposal).toBeDefined();
      expect(proposal.actionId).toBeDefined();
      expect(proposal.actionType).toBe('CREATE_ASSIGNMENT');
      expect(proposal.preview.title).toBe('Smart City Sensor Analysis');
      expect(proposal.preview.subject).toBe('Internet of Things');
      expect(proposal.preview.section).toBe('Section A');
      expect(proposal.preview.dueDate).toBe('2026-11-25');
      expect(proposal.preview.maximumMarks).toBe(50);

      // CRITICAL: Verify NO assignment is written to Assignment collection before confirmation!
      const assignmentCount = await Assignment.countDocuments();
      expect(assignmentCount).toBe(0);

      // Verify pending action was saved in DB with PENDING status
      const pendingDoc = await PendingAction.findOne({ actionId: proposal.actionId });
      expect(pendingDoc).not.toBeNull();
      expect(pendingDoc?.status).toBe('PENDING');
      expect(pendingDoc?.userId).toBe(testFaculty.userId.toString());
    });

    it('should successfully persist assignment only when user explicitly confirms pending action', async () => {
      // 1. Create a pending action in database
      const pendingAction = await PendingAction.create({
        actionId: 'asgn-action-confirm-123',
        userId: testFaculty.userId.toString(),
        userRole: AppRole.FACULTY,
        collegeId: testCollege.id,
        actionType: 'CREATE_ASSIGNMENT',
        status: 'PENDING',
        draftPayload: {
          facultyAssignmentId: testFa.id,
          title: 'Embedded System Architecture Project',
          description: 'Design a micro-controller circuit on breadboard.',
          assignmentType: 'project',
          dueDate: '2026-11-30',
          dueTime: '11:59 PM',
          maximumMarks: 100,
          status: 'published',
        },
        summary: 'Create project assignment "Embedded System Architecture Project"',
        preview: {
          title: 'Embedded System Architecture Project',
          subject: 'Internet of Things',
          section: 'Section A',
        },
        expiresAt: new Date(Date.now() + 10 * 60 * 1000),
      });

      const authHeader = createTestAuthHeader({
        role: AppRole.FACULTY,
        userId: testFaculty.userId.toString(),
        name: testFaculty.name,
        collegeId: testCollege.id,
      });

      // 2. Confirm the pending action
      const res = await request(app)
        .post('/api/v1/ai/action/confirm')
        .set(authHeader)
        .send({
          actionId: pendingAction.actionId,
          idempotencyKey: 'idem-key-asgn-1',
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.status).toBe('EXECUTED');
      expect(res.body.data.result.assignmentId).toBeDefined();

      // 3. Verify actual persistent write in Assignment collection
      const savedAssignment = await Assignment.findById(res.body.data.result.assignmentId);
      expect(savedAssignment).not.toBeNull();
      expect(savedAssignment?.title).toBe('Embedded System Architecture Project');
      expect(savedAssignment?.status).toBe(AssignmentStatus.PUBLISHED);
      expect(savedAssignment?.collegeId.toString()).toBe(testCollege.id);

      // 4. Verify replay prevention: calling confirm again must fail with 409 Conflict
      const duplicateRes = await request(app)
        .post('/api/v1/ai/action/confirm')
        .set(authHeader)
        .send({ actionId: pendingAction.actionId });

      expect(duplicateRes.status).toBe(409);
      expect(duplicateRes.body.error.code).toBe('CONFLICT');
    });

    it('should reject confirmation attempt from a different user with 403 Forbidden', async () => {
      const pendingAction = await PendingAction.create({
        actionId: 'asgn-action-diff-user',
        userId: testFaculty.userId.toString(),
        userRole: AppRole.FACULTY,
        collegeId: testCollege.id,
        actionType: 'CREATE_ASSIGNMENT',
        status: 'PENDING',
        draftPayload: {
          facultyAssignmentId: testFa.id,
          title: 'Test',
          dueDate: '2026-11-30',
          dueTime: '11:59 PM',
          maximumMarks: 100,
        },
        summary: 'Test',
        preview: { title: 'Test' },
        expiresAt: new Date(Date.now() + 10 * 60 * 1000),
      });

      // Different faculty member tries to confirm
      const imposterHeader = createTestAuthHeader({
        role: AppRole.FACULTY,
        userId: testImposterUser.id,
        collegeId: testCollege.id,
      });

      const res = await request(app)
        .post('/api/v1/ai/action/confirm')
        .set(imposterHeader)
        .send({ actionId: pendingAction.actionId });

      expect(res.status).toBe(403);
      expect(res.body.error.code).toBe('FORBIDDEN');
    });

    it('should reject confirmation of an expired action with 400 Bad Request', async () => {
      const expiredAction = await PendingAction.create({
        actionId: 'asgn-action-expired',
        userId: testFaculty.userId.toString(),
        userRole: AppRole.FACULTY,
        collegeId: testCollege.id,
        actionType: 'CREATE_ASSIGNMENT',
        status: 'PENDING',
        draftPayload: {
          facultyAssignmentId: testFa.id,
          title: 'Old Assignment',
          dueDate: '2026-11-30',
          dueTime: '11:59 PM',
          maximumMarks: 100,
        },
        summary: 'Old',
        preview: { title: 'Old' },
        expiresAt: new Date(Date.now() - 5000), // Already expired 5s ago
      });

      const authHeader = createTestAuthHeader({
        role: AppRole.FACULTY,
        userId: testFaculty.userId.toString(),
        collegeId: testCollege.id,
      });

      const res = await request(app)
        .post('/api/v1/ai/action/confirm')
        .set(authHeader)
        .send({ actionId: expiredAction.actionId });

      expect(res.status).toBe(400);
      expect(res.body.error.message).toContain('expired');
    });

    it('should allow user to cancel a pending action', async () => {
      const cancelAction = await PendingAction.create({
        actionId: 'asgn-action-to-cancel',
        userId: testFaculty.userId.toString(),
        userRole: AppRole.FACULTY,
        collegeId: testCollege.id,
        actionType: 'CREATE_ASSIGNMENT',
        status: 'PENDING',
        draftPayload: {
          facultyAssignmentId: testFa.id,
          title: 'Draft to cancel',
          dueDate: '2026-11-30',
        },
        summary: 'Draft to cancel',
        preview: { title: 'Draft to cancel' },
        expiresAt: new Date(Date.now() + 10 * 60 * 1000),
      });

      const authHeader = createTestAuthHeader({
        role: AppRole.FACULTY,
        userId: testFaculty.userId.toString(),
        collegeId: testCollege.id,
      });

      const res = await request(app)
        .post('/api/v1/ai/action/cancel')
        .set(authHeader)
        .send({ actionId: cancelAction.actionId });

      expect(res.status).toBe(200);
      expect(res.body.data.status).toBe('CANCELLED');

      const updated = await PendingAction.findOne({ actionId: cancelAction.actionId });
      expect(updated?.status).toBe('CANCELLED');
    });
  });

  describe('Phase 3: Calendar Event Creation Workflow (Confirmed Write)', () => {
    it('should generate proposal preview WITHOUT writing to CalendarEvent collection', async () => {
      const mockClient = {
        models: {
          generateContent: jest.fn().mockResolvedValueOnce({
            functionCalls: [
              {
                name: 'propose_create_calendar_event',
                args: {
                  title: 'Department Curriculum Review Meeting',
                  startDate: '2026-11-20',
                  startTime: '10:00 AM',
                  endTime: '11:30 AM',
                  eventType: 'meeting',
                  location: 'Seminar Hall 1',
                  description: 'Review updated semester course syllabi.',
                },
                id: 'call_cal_valid',
              },
            ],
          }),
        },
      };
      AiService.setMockClient(mockClient);

      const authHeader = createTestAuthHeader({
        role: AppRole.HOD,
        userId: testHodUser.id,
        departmentId: testDept.id,
        name: 'Dr. Claude Shannon',
        collegeId: testCollege.id,
      });

      const res = await request(app)
        .post('/api/v1/ai/chat')
        .set(authHeader)
        .send({ message: 'Schedule a curriculum review meeting on Nov 20 at 10 AM in Seminar Hall 1' });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);

      const proposal = res.body.data.proposal;
      expect(proposal).toBeDefined();
      expect(proposal.actionType).toBe('CREATE_CALENDAR_EVENT');
      expect(proposal.preview.title).toBe('Department Curriculum Review Meeting');
      expect(proposal.preview.startDate).toBe('2026-11-20');
      expect(proposal.preview.startTime).toBe('10:00 AM');
      expect(proposal.preview.location).toBe('Seminar Hall 1');

      // CRITICAL: Verify NO event is written to CalendarEvent collection before confirmation!
      const eventCount = await CalendarEvent.countDocuments();
      expect(eventCount).toBe(0);
    });

    it('should successfully persist calendar event when user confirms pending action', async () => {
      const pendingAction = await PendingAction.create({
        actionId: 'cal-action-confirm-456',
        userId: testHodUser.id,
        userRole: AppRole.HOD,
        collegeId: testCollege.id,
        actionType: 'CREATE_CALENDAR_EVENT',
        status: 'PENDING',
        draftPayload: {
          title: 'Annual Faculty Development Workshop',
          description: 'Hands-on pedagogy session',
          eventType: 'ACADEMIC_EVENT',
          startDate: '2026-12-05',
          endDate: '2026-12-05',
          startTime: '09:00',
          endTime: '17:00',
          location: 'Main Auditorium',
          departmentId: testDept.id,
        },
        summary: 'Schedule workshop on Dec 5',
        preview: {
          title: 'Annual Faculty Development Workshop',
          startDate: '2026-12-05',
        },
        expiresAt: new Date(Date.now() + 10 * 60 * 1000),
      });

      const authHeader = createTestAuthHeader({
        role: AppRole.HOD,
        userId: testHodUser.id,
        departmentId: testDept.id,
        collegeId: testCollege.id,
      });

      const res = await request(app)
        .post('/api/v1/ai/action/confirm')
        .set(authHeader)
        .send({ actionId: pendingAction.actionId });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.status).toBe('EXECUTED');
      expect(res.body.data.result.eventId).toBeDefined();

      // Verify actual persistent write in CalendarEvent collection
      const savedEvent = await CalendarEvent.findById(res.body.data.result.eventId);
      expect(savedEvent).not.toBeNull();
      expect(savedEvent?.title).toBe('Annual Faculty Development Workshop');
      expect(savedEvent?.collegeId.toString()).toBe(testCollege.id);
    });
  });

  describe('Phase 4: Context-Aware Academic Intelligence', () => {
    it('should support timetable query with periodTarget (first, last, next)', async () => {
      const mockClient = {
        models: {
          generateContent: jest
            .fn()
            .mockResolvedValueOnce({
              functionCalls: [
                {
                  name: 'get_my_timetable',
                  args: { day: 'today', periodTarget: 'first' },
                  id: 'call_tt_first',
                },
              ],
            })
            .mockResolvedValueOnce({
              text: 'Your first period is scheduled for today.',
            }),
        },
      };
      AiService.setMockClient(mockClient);

      const authHeader = createTestAuthHeader({
        role: AppRole.STUDENT,
        userId: testStudentUser.id,
        name: testStudentUser.name,
        collegeId: testCollege.id,
      });

      const res = await request(app)
        .post('/api/v1/ai/chat')
        .set(authHeader)
        .send({ message: 'What is my first class today?' });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.answer).toBe('Your first period is scheduled for today.');
    });

    it('should filter assignments by subject and dueSoon, calculating daysRemaining', async () => {
      const in3Days = new Date(Date.now() + 3 * 24 * 60 * 60 * 1000);
      const dueDateStr = in3Days.toISOString().split('T')[0];

      await AssignmentService.createAssignment(
        testCollege.id,
        {
          id: testFacultyUser.id,
          name: testFaculty.name,
          role: AppRole.FACULTY,
          email: testFaculty.email,
          departmentId: testDept.id,
        },
        {
          facultyAssignmentId: testFa._id.toString(),
          title: 'Microservices Quiz 1',
          description: 'Complete quiz on architecture',
          assignmentType: AssignmentType.QUIZ,
          dueDate: dueDateStr,
          dueTime: '11:59 PM',
          maximumMarks: 20,
          status: AssignmentStatus.PUBLISHED,
        }
      );

      const mockClient = {
        models: {
          generateContent: jest
            .fn()
            .mockResolvedValueOnce({
              functionCalls: [
                {
                  name: 'get_my_assignments',
                  args: { subject: 'Internet of Things', dueSoon: true },
                  id: 'call_asgn_due',
                },
              ],
            })
            .mockResolvedValueOnce({
              text: 'You have 1 quiz due in 3 days for Internet of Things.',
            }),
        },
      };
      AiService.setMockClient(mockClient);

      const authHeader = createTestAuthHeader({
        role: AppRole.FACULTY,
        userId: testFacultyUser.id,
        name: testFacultyUser.name,
        collegeId: testCollege.id,
      });

      const res = await request(app)
        .post('/api/v1/ai/chat')
        .set(authHeader)
        .send({ message: 'Which IoT assignments are due soon?' });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.answer).toContain('Internet of Things');
    });

    it('should detect scheduling conflict on proposed calendar event', async () => {
      await AcademicCalendarService.createEvent(
        {
          title: 'Existing Department Review',
          description: 'Department review session',
          eventType: CalendarEventType.EVENT,
          scope: CalendarEventScope.DEPARTMENT,
          departmentId: testDept.id,
          startDate: '2026-11-20',
          endDate: '2026-11-20',
          startTime: '10:00 AM',
          endTime: '11:30 AM',
          location: 'Seminar Hall 1',
        },
        {
          id: testHodUser.id,
          name: testHodUser.name,
          role: AppRole.HOD,
          email: testHodUser.email,
          collegeId: testCollege.id,
          departmentId: testDept.id,
          instituteId: testHodUser.instituteId,
          accountStatus: AccountStatus.ACTIVE,
        } as any
      );

      const mockClient = {
        models: {
          generateContent: jest.fn().mockResolvedValueOnce({
            functionCalls: [
              {
                name: 'propose_create_calendar_event',
                args: {
                  title: 'Conflicting Seminar',
                  startDate: '2026-11-20',
                  startTime: '10:00 AM',
                  location: 'Seminar Hall 1',
                  eventType: 'meeting',
                },
                id: 'call_conflict_event',
              },
            ],
          }),
        },
      };
      AiService.setMockClient(mockClient);

      const authHeader = createTestAuthHeader({
        role: AppRole.HOD,
        userId: testHodUser.id,
        departmentId: testDept.id,
        collegeId: testCollege.id,
      });

      const res = await request(app)
        .post('/api/v1/ai/chat')
        .set(authHeader)
        .send({ message: 'Schedule seminar on Nov 20 at 10 AM in Seminar Hall 1' });

      expect(res.status).toBe(200);
      expect(res.body.data.proposal).toBeDefined();
      expect(res.body.data.proposal.preview.conflictWarning).toBeDefined();
      expect(res.body.data.proposal.preview.conflictWarning).toContain('conflict');
    });

    it('should support bounded conversation history in chat requests', async () => {
      const mockClient = {
        models: {
          generateContent: jest.fn().mockResolvedValueOnce({
            text: 'Tomorrow you have 3 classes scheduled.',
          }),
        },
      };
      AiService.setMockClient(mockClient);

      const authHeader = createTestAuthHeader({
        role: AppRole.STUDENT,
        userId: testStudentUser.id,
        name: testStudentUser.name,
        collegeId: testCollege.id,
      });

      const res = await request(app)
        .post('/api/v1/ai/chat')
        .set(authHeader)
        .send({
          message: 'What about tomorrow?',
          history: [
            { role: 'user', content: 'What classes do I have today?' },
            { role: 'assistant', content: 'You have 2 classes today.' },
          ],
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.answer).toBe('Tomorrow you have 3 classes scheduled.');
    });

    it('should prevent repeated tool execution loops for identical tool invocations', async () => {
      const mockClient = {
        models: {
          generateContent: jest
            .fn()
            .mockResolvedValueOnce({
              functionCalls: [
                {
                  name: 'get_my_timetable',
                  args: { day: 'friday' },
                  id: 'call_loop_1',
                },
              ],
            })
            .mockResolvedValueOnce({
              functionCalls: [
                {
                  name: 'get_my_timetable',
                  args: { day: 'friday' },
                  id: 'call_loop_2',
                },
              ],
            })
            .mockResolvedValueOnce({
              text: 'Here is your Friday timetable after tool loop interception.',
            }),
        },
      };
      AiService.setMockClient(mockClient);

      const authHeader = createTestAuthHeader({
        role: AppRole.STUDENT,
        userId: testStudentUser.id,
        name: testStudentUser.name,
        collegeId: testCollege.id,
      });

      const res = await request(app)
        .post('/api/v1/ai/chat')
        .set(authHeader)
        .send({ message: 'Check my timetable for Friday' });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(mockClient.models.generateContent).toHaveBeenCalledTimes(3);
    });
  });

  describe('Phase 5: Production Hardening, Idempotency & Auditability', () => {
    it('should return cached execution result when confirming with identical idempotencyKey (Replay Protection)', async () => {
      const pendingAction = await PendingAction.create({
        actionId: 'idempotent-action-123',
        userId: testFacultyUser.id,
        userRole: AppRole.FACULTY,
        collegeId: testCollege.id,
        actionType: 'CREATE_ASSIGNMENT',
        status: 'PENDING',
        draftPayload: {
          facultyAssignmentId: testFa._id.toString(),
          title: 'Idempotency Test Assignment',
          description: 'Testing safe replay',
          assignmentType: 'homework',
          dueDate: '2026-11-30',
          dueTime: '11:59 PM',
          maximumMarks: 100,
          status: AssignmentStatus.PUBLISHED,
        },
        summary: 'Create test assignment',
        preview: {
          title: 'Idempotency Test Assignment',
          dueDate: '2026-11-30',
        },
        expiresAt: new Date(Date.now() + 10 * 60 * 1000),
      });

      const authHeader = createTestAuthHeader({
        role: AppRole.FACULTY,
        userId: testFacultyUser.id,
        departmentId: testDept.id,
        collegeId: testCollege.id,
      });

      // First confirmation request with idempotency key
      const firstRes = await request(app)
        .post('/api/v1/ai/action/confirm')
        .set(authHeader)
        .send({
          actionId: pendingAction.actionId,
          idempotencyKey: 'key-replay-abc-123',
        });

      expect(firstRes.status).toBe(200);
      expect(firstRes.body.data.status).toBe('EXECUTED');
      const firstResult = firstRes.body.data.result;

      // Second confirmation request with identical idempotency key (network retry simulation)
      const secondRes = await request(app)
        .post('/api/v1/ai/action/confirm')
        .set(authHeader)
        .send({
          actionId: pendingAction.actionId,
          idempotencyKey: 'key-replay-abc-123',
        });

      expect(secondRes.status).toBe(200);
      expect(secondRes.body.data.status).toBe('EXECUTED');
      expect(secondRes.body.data.result.assignmentId).toBe(firstResult.assignmentId);

      // Verify only ONE assignment was created in the database
      const count = await Assignment.countDocuments({ title: 'Idempotency Test Assignment' });
      expect(count).toBe(1);
    });

    it('should reject replay with 409 conflict when idempotencyKey differs or is not provided', async () => {
      const pendingAction = await PendingAction.create({
        actionId: 'executed-conflict-action',
        userId: testFacultyUser.id,
        userRole: AppRole.FACULTY,
        collegeId: testCollege.id,
        actionType: 'CREATE_ASSIGNMENT',
        status: 'EXECUTED',
        idempotencyKey: 'original-key',
        draftPayload: {},
        summary: 'Already executed',
        preview: {},
        expiresAt: new Date(Date.now() + 10 * 60 * 1000),
      });

      const authHeader = createTestAuthHeader({
        role: AppRole.FACULTY,
        userId: testFacultyUser.id,
        departmentId: testDept.id,
        collegeId: testCollege.id,
      });

      const res = await request(app)
        .post('/api/v1/ai/action/confirm')
        .set(authHeader)
        .send({
          actionId: pendingAction.actionId,
          idempotencyKey: 'different-key-xyz',
        });

      expect(res.status).toBe(409);
    });

    it('should record an AuditLog entry when an action proposal is confirmed and executed', async () => {
      const pendingAction = await PendingAction.create({
        actionId: 'audit-confirm-action',
        userId: testFacultyUser.id,
        userRole: AppRole.FACULTY,
        collegeId: testCollege.id,
        actionType: 'CREATE_ASSIGNMENT',
        status: 'PENDING',
        draftPayload: {
          facultyAssignmentId: testFa._id.toString(),
          title: 'Audited Assignment',
          description: 'Audited assignment description',
          assignmentType: AssignmentType.HOMEWORK,
          dueDate: '2026-11-28',
          dueTime: '11:59 PM',
          maximumMarks: 50,
          status: AssignmentStatus.PUBLISHED,
        },
        summary: 'Create audited assignment',
        preview: { title: 'Audited Assignment' },
        expiresAt: new Date(Date.now() + 10 * 60 * 1000),
      });

      const authHeader = createTestAuthHeader({
        role: AppRole.FACULTY,
        userId: testFacultyUser.id,
        name: testFacultyUser.name,
        departmentId: testDept.id,
        collegeId: testCollege.id,
      });

      const res = await request(app)
        .post('/api/v1/ai/action/confirm')
        .set(authHeader)
        .send({ actionId: pendingAction.actionId });

      expect(res.status).toBe(200);

      // Verify AuditLog persistence
      const auditEntry = await AuditLog.findOne({
        action: 'AI_CREATE_ASSIGNMENT_CONFIRMED',
        actorUserId: testFacultyUser.id,
      });

      expect(auditEntry).not.toBeNull();
      expect(auditEntry?.collegeId).toBe(testCollege.id);
      expect(auditEntry?.entityType).toBe('Assignment');
      expect(auditEntry?.newValue).toBeDefined();
    });

    it('should record an AuditLog entry when an action proposal is cancelled', async () => {
      const pendingAction = await PendingAction.create({
        actionId: 'audit-cancel-action',
        userId: testFacultyUser.id,
        userRole: AppRole.FACULTY,
        collegeId: testCollege.id,
        actionType: 'CREATE_ASSIGNMENT',
        status: 'PENDING',
        draftPayload: {
          title: 'Cancelled Assignment',
        },
        summary: 'Cancelled assignment draft',
        preview: { title: 'Cancelled Assignment' },
        expiresAt: new Date(Date.now() + 10 * 60 * 1000),
      });

      const authHeader = createTestAuthHeader({
        role: AppRole.FACULTY,
        userId: testFacultyUser.id,
        departmentId: testDept.id,
        collegeId: testCollege.id,
      });

      const res = await request(app)
        .post('/api/v1/ai/action/cancel')
        .set(authHeader)
        .send({ actionId: pendingAction.actionId });

      expect(res.status).toBe(200);

      const auditEntry = await AuditLog.findOne({
        action: 'AI_CREATE_ASSIGNMENT_CANCELLED',
        actorUserId: testFacultyUser.id,
      });

      expect(auditEntry).not.toBeNull();
      expect(auditEntry?.entityType).toBe('PendingAction');
      expect(auditEntry?.entityId).toBe(pendingAction.actionId);
    });
  });

  describe('Phase 6: End-to-End Reliability, Timezone & Academic Intelligence', () => {
    it('should support timetable query with relative day "yesterday" in IST', async () => {
      const mockClient = {
        models: {
          generateContent: jest
            .fn()
            .mockResolvedValueOnce({
              functionCalls: [
                {
                  name: 'get_my_timetable',
                  args: { day: 'yesterday' },
                  id: 'call_tt_yesterday',
                },
              ],
            })
            .mockResolvedValueOnce({
              text: 'Here is your timetable from yesterday.',
            }),
        },
      };
      AiService.setMockClient(mockClient);

      const authHeader = createTestAuthHeader({
        role: AppRole.STUDENT,
        userId: testStudentUser.id,
        name: testStudentUser.name,
        collegeId: testCollege.id,
      });

      const res = await request(app)
        .post('/api/v1/ai/chat')
        .set(authHeader)
        .send({ message: 'What classes did I have yesterday?' });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.answer).toBe('Here is your timetable from yesterday.');
    });

    it('should support timetable query with periodTarget "morning" and "afternoon"', async () => {
      const mockClient = {
        models: {
          generateContent: jest
            .fn()
            .mockResolvedValueOnce({
              functionCalls: [
                {
                  name: 'get_my_timetable',
                  args: { day: 'today', periodTarget: 'morning' },
                  id: 'call_tt_morning',
                },
              ],
            })
            .mockResolvedValueOnce({
              text: 'You have 2 morning classes before 12:00 PM.',
            }),
        },
      };
      AiService.setMockClient(mockClient);

      const authHeader = createTestAuthHeader({
        role: AppRole.STUDENT,
        userId: testStudentUser.id,
        name: testStudentUser.name,
        collegeId: testCollege.id,
      });

      const res = await request(app)
        .post('/api/v1/ai/chat')
        .set(authHeader)
        .send({ message: 'Show only my morning classes.' });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.answer).toContain('morning');
    });

    it('should handle timetable query with unrecognized day safely', async () => {
      const mockClient = {
        models: {
          generateContent: jest
            .fn()
            .mockResolvedValueOnce({
              functionCalls: [
                {
                  name: 'get_my_timetable',
                  args: { day: 'someday_invalid' },
                  id: 'call_tt_invalid',
                },
              ],
            })
            .mockResolvedValueOnce({
              text: 'Please specify a valid weekday or relative day.',
            }),
        },
      };
      AiService.setMockClient(mockClient);

      const authHeader = createTestAuthHeader({
        role: AppRole.STUDENT,
        userId: testStudentUser.id,
        name: testStudentUser.name,
        collegeId: testCollege.id,
      });

      const res = await request(app)
        .post('/api/v1/ai/chat')
        .set(authHeader)
        .send({ message: 'What is my schedule on someday?' });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
    });

    it('should detect calendar conflict when new event interval overlaps existing event in same room', async () => {
      // Create existing event from 10:00 to 11:30 in Room 101
      await CalendarEvent.create({
        collegeId: testCollege._id,
        title: 'Existing IoT Lab',
        description: 'Lab Session',
        sourceType: CalendarSourceType.MANUAL,
        eventType: CalendarEventType.EVENT,
        scope: CalendarEventScope.COLLEGE,
        startDate: '2026-11-28',
        endDate: '2026-11-28',
        startTime: '10:00 AM',
        endTime: '11:30 AM',
        allDay: false,
        location: 'Room 101',
        isRecurring: false,
        recurrence: 'NONE',
        status: CalendarEventStatus.PUBLISHED,
        createdBy: testFacultyUser._id,
        creatorRole: AppRole.FACULTY,
        creatorName: testFacultyUser.name,
      });

      const mockClient = {
        models: {
          generateContent: jest.fn().mockResolvedValueOnce({
            functionCalls: [
              {
                name: 'propose_create_calendar_event',
                args: {
                  title: 'Embedded Systems Workshop',
                  startDate: '2026-11-28',
                  startTime: '10:30 AM',
                  endTime: '12:00 PM',
                  location: 'Room 101',
                  eventType: 'meeting',
                },
                id: 'call_cal_overlap',
              },
            ],
          }),
        },
      };
      AiService.setMockClient(mockClient);

      const authHeader = createTestAuthHeader({
        role: AppRole.FACULTY,
        userId: testFacultyUser.id,
        departmentId: testDept.id,
        collegeId: testCollege.id,
      });

      const res = await request(app)
        .post('/api/v1/ai/chat')
        .set(authHeader)
        .send({ message: 'Schedule workshop on 2026-11-28 from 10:30 AM in Room 101' });

      expect(res.status).toBe(200);
      const proposal = res.body.data.proposal;
      expect(proposal).toBeDefined();
      expect(proposal.preview.conflictWarning).toBeDefined();
      expect(proposal.preview.conflictWarning).toContain('conflict detected');
      expect(proposal.preview.conflictWarning).toContain('Room 101');
    });

    it('should NOT detect calendar conflict when intervals are adjacent (10:00-11:00 vs 11:00-12:00)', async () => {
      await CalendarEvent.create({
        collegeId: testCollege._id,
        title: 'Morning Class',
        description: 'Morning Lecture',
        sourceType: CalendarSourceType.MANUAL,
        eventType: CalendarEventType.EVENT,
        scope: CalendarEventScope.COLLEGE,
        startDate: '2026-11-29',
        endDate: '2026-11-29',
        startTime: '10:00 AM',
        endTime: '11:00 AM',
        allDay: false,
        location: 'Room 202',
        isRecurring: false,
        recurrence: 'NONE',
        status: CalendarEventStatus.PUBLISHED,
        createdBy: testFacultyUser._id,
        creatorRole: AppRole.FACULTY,
        creatorName: testFacultyUser.name,
      });

      const mockClient = {
        models: {
          generateContent: jest.fn().mockResolvedValueOnce({
            functionCalls: [
              {
                name: 'propose_create_calendar_event',
                args: {
                  title: 'Subsequent Lecture',
                  startDate: '2026-11-29',
                  startTime: '11:00 AM',
                  endTime: '12:00 PM',
                  location: 'Room 202',
                  eventType: 'meeting',
                },
                id: 'call_cal_adjacent',
              },
            ],
          }),
        },
      };
      AiService.setMockClient(mockClient);

      const authHeader = createTestAuthHeader({
        role: AppRole.FACULTY,
        userId: testFacultyUser.id,
        departmentId: testDept.id,
        collegeId: testCollege.id,
      });

      const res = await request(app)
        .post('/api/v1/ai/chat')
        .set(authHeader)
        .send({ message: 'Schedule subsequent lecture from 11:00 AM to 12:00 PM in Room 202' });

      expect(res.status).toBe(200);
      const proposal = res.body.data.proposal;
      expect(proposal).toBeDefined();
      expect(proposal.preview.conflictWarning).toBeUndefined();
    });

    it('should exclude CANCELLED events from conflict detection', async () => {
      await CalendarEvent.create({
        collegeId: testCollege._id,
        title: 'Cancelled Lecture',
        description: 'Cancelled',
        sourceType: CalendarSourceType.MANUAL,
        eventType: CalendarEventType.EVENT,
        scope: CalendarEventScope.COLLEGE,
        startDate: '2026-11-30',
        endDate: '2026-11-30',
        startTime: '10:00 AM',
        endTime: '11:30 AM',
        allDay: false,
        location: 'Room 303',
        isRecurring: false,
        recurrence: 'NONE',
        status: CalendarEventStatus.CANCELLED,
        createdBy: testFacultyUser._id,
        creatorRole: AppRole.FACULTY,
        creatorName: testFacultyUser.name,
      });

      const mockClient = {
        models: {
          generateContent: jest.fn().mockResolvedValueOnce({
            functionCalls: [
              {
                name: 'propose_create_calendar_event',
                args: {
                  title: 'Fresh Lecture',
                  startDate: '2026-11-30',
                  startTime: '10:00 AM',
                  endTime: '11:30 AM',
                  location: 'Room 303',
                  eventType: 'meeting',
                },
                id: 'call_cal_cancelled_check',
              },
            ],
          }),
        },
      };
      AiService.setMockClient(mockClient);

      const authHeader = createTestAuthHeader({
        role: AppRole.FACULTY,
        userId: testFacultyUser.id,
        departmentId: testDept.id,
        collegeId: testCollege.id,
      });

      const res = await request(app)
        .post('/api/v1/ai/chat')
        .set(authHeader)
        .send({ message: 'Schedule fresh lecture in Room 303' });

      expect(res.status).toBe(200);
      const proposal = res.body.data.proposal;
      expect(proposal).toBeDefined();
      expect(proposal.preview.conflictWarning).toBeUndefined();
    });
  });

  describe('Phase 7: Production Readiness, Action Reconciliation & Release Assurance', () => {
    it('should allow action creator to retrieve action status via GET /api/v1/ai/action/:actionId', async () => {
      const pendingAction = await PendingAction.create({
        actionId: 'recon-action-123',
        userId: testFacultyUser.id,
        userRole: AppRole.FACULTY,
        collegeId: testCollege.id,
        actionType: 'CREATE_ASSIGNMENT',
        status: 'PENDING',
        draftPayload: { title: 'Reconciliation Test' },
        summary: 'Reconciliation Test Summary',
        preview: { title: 'Reconciliation Test' },
        expiresAt: new Date(Date.now() + 10 * 60 * 1000),
      });

      const authHeader = createTestAuthHeader({
        role: AppRole.FACULTY,
        userId: testFacultyUser.id,
        departmentId: testDept.id,
        collegeId: testCollege.id,
      });

      const res = await request(app)
        .get(`/api/v1/ai/action/${pendingAction.actionId}`)
        .set(authHeader);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.actionId).toBe(pendingAction.actionId);
      expect(res.body.data.status).toBe('PENDING');
      expect(res.body.data.summary).toBe('Reconciliation Test Summary');
    });

    it('should reject cross-user action status retrieval with 403 Forbidden', async () => {
      const pendingAction = await PendingAction.create({
        actionId: 'recon-action-forbidden',
        userId: testFacultyUser.id,
        userRole: AppRole.FACULTY,
        collegeId: testCollege.id,
        actionType: 'CREATE_ASSIGNMENT',
        status: 'PENDING',
        draftPayload: { title: 'Private Assignment' },
        summary: 'Private Assignment',
        preview: { title: 'Private Assignment' },
        expiresAt: new Date(Date.now() + 10 * 60 * 1000),
      });

      // Attempt to access with different user (Ada Lovelace)
      const authHeader = createTestAuthHeader({
        role: AppRole.STUDENT,
        userId: testStudentUser.id,
        collegeId: testCollege.id,
      });

      const res = await request(app)
        .get(`/api/v1/ai/action/${pendingAction.actionId}`)
        .set(authHeader);

      expect(res.status).toBe(403);
      expect(res.body.success).toBe(false);
    });

    it('should dynamically mark action as EXPIRED when inspected after expiresAt', async () => {
      const expiredPendingAction = await PendingAction.create({
        actionId: 'recon-action-expired',
        userId: testFacultyUser.id,
        userRole: AppRole.FACULTY,
        collegeId: testCollege.id,
        actionType: 'CREATE_ASSIGNMENT',
        status: 'PENDING',
        draftPayload: { title: 'Expired Assignment' },
        summary: 'Expired Assignment Summary',
        preview: { title: 'Expired Assignment' },
        expiresAt: new Date(Date.now() - 5000), // In the past!
      });

      const authHeader = createTestAuthHeader({
        role: AppRole.FACULTY,
        userId: testFacultyUser.id,
        departmentId: testDept.id,
        collegeId: testCollege.id,
      });

      const res = await request(app)
        .get(`/api/v1/ai/action/${expiredPendingAction.actionId}`)
        .set(authHeader);

      expect(res.status).toBe(200);
      expect(res.body.data.status).toBe('EXPIRED');

      // Verify DB document was updated to EXPIRED
      const updatedDoc = await PendingAction.findOne({ actionId: expiredPendingAction.actionId });
      expect(updatedDoc?.status).toBe('EXPIRED');
    });

    it('should record an AuditLog entry with status FAILURE when write execution fails', async () => {
      const failingAction = await PendingAction.create({
        actionId: 'fail-action-audit',
        userId: testFacultyUser.id,
        userRole: AppRole.FACULTY,
        collegeId: testCollege.id,
        actionType: 'CREATE_ASSIGNMENT',
        status: 'PENDING',
        draftPayload: {
          facultyAssignmentId: new mongoose.Types.ObjectId().toString(), // Non-existent teaching assignment
          title: 'Will Fail Persistence',
          dueDate: '2026-12-01',
        },
        summary: 'Failing Assignment Draft',
        preview: { title: 'Will Fail' },
        expiresAt: new Date(Date.now() + 10 * 60 * 1000),
      });

      const authHeader = createTestAuthHeader({
        role: AppRole.FACULTY,
        userId: testFacultyUser.id,
        departmentId: testDept.id,
        collegeId: testCollege.id,
      });

      const res = await request(app)
        .post('/api/v1/ai/action/confirm')
        .set(authHeader)
        .send({ actionId: failingAction.actionId });

      expect(res.status).toBeGreaterThanOrEqual(400);

      // Verify action was reverted to PENDING
      const docAfter = await PendingAction.findOne({ actionId: failingAction.actionId });
      expect(docAfter?.status).toBe('PENDING');

      // Verify AuditLog failure entry was created
      const auditEntry = await AuditLog.findOne({
        action: 'AI_CREATE_ASSIGNMENT_FAILED',
        entityId: failingAction.actionId,
      });
      expect(auditEntry).not.toBeNull();
      expect(auditEntry?.actorUserId).toBe(testFacultyUser.id);
    });
  });
});
