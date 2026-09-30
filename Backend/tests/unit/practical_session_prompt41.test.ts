import { Types } from 'mongoose';
import { PracticalService } from '../../src/services/practical.service';
import {
  PracticalSession,
  PracticalParticipation,
  Subject,
  StudentEnrollment,
  Student,
  Room,
} from '../../src/models';
import {
  PracticalSessionStatus,
  PracticalParticipationStatus,
} from '../../src/constants/practical.constants';
import { TeachingAuthorizationService } from '../../src/services/teachingAuthorization.service';
import { NotificationService } from '../../src/services/notification.service';
import { realtimeEventBus } from '../../src/realtime';

describe('PROMPT 41 — Practical / Labs Session Module Unit Tests', () => {
  const collegeId = new Types.ObjectId().toString();
  const departmentId = new Types.ObjectId();
  const courseId = new Types.ObjectId();
  const semesterId = new Types.ObjectId();
  const academicYearId = new Types.ObjectId();
  const sectionId = new Types.ObjectId();
  const subjectId = new Types.ObjectId();
  const facultyAssignmentId = new Types.ObjectId();
  const facultyUserId = new Types.ObjectId().toString();
  const studentUserId = new Types.ObjectId().toString();
  const studentId = new Types.ObjectId();

  const mockFacultyUser = {
    id: facultyUserId,
    role: 'faculty',
    collegeId,
    departmentId: departmentId.toString(),
  };

  const mockPracticalSubject: any = {
    _id: subjectId,
    name: 'Operating Systems & Linux Lab',
    code: 'CS302L',
    type: 'Practical',
    collegeId: new Types.ObjectId(collegeId),
    departmentId,
  };

  const mockTheorySubject: any = {
    _id: new Types.ObjectId(),
    name: 'Discrete Mathematics',
    code: 'MA201',
    type: 'Theory',
    collegeId: new Types.ObjectId(collegeId),
    departmentId,
  };

  const mockFacultyAssignment: any = {
    _id: facultyAssignmentId,
    collegeId: new Types.ObjectId(collegeId),
    departmentId,
    courseId,
    semesterId,
    academicYearId,
    sectionId,
    subjectId,
    facultyId: new Types.ObjectId(facultyUserId),
    isActive: true,
  };

  beforeEach(() => {
    jest.clearAllMocks();
    jest.spyOn(NotificationService, 'createNotification').mockResolvedValue({} as any);
    jest.spyOn(realtimeEventBus, 'publish').mockImplementation((evt: any) => evt);
  });

  describe('1. Subject Capability & Authorization', () => {
    it('rejects practical session creation for a non-practical Theory subject', async () => {
      jest.spyOn(TeachingAuthorizationService, 'assertFacultyAssignmentAccess').mockResolvedValue({
        ...mockFacultyAssignment,
        subjectId: mockTheorySubject._id,
      } as any);
      jest.spyOn(Subject, 'findById').mockResolvedValue(mockTheorySubject);

      await expect(
        PracticalService.createSession(collegeId, mockFacultyUser, {
          facultyAssignmentId: facultyAssignmentId.toString(),
          topic: 'Proof by Induction Lab',
          scheduledDate: new Date(),
        })
      ).rejects.toThrow(/not configured as a practical or lab course/);
    });

    it('rejects session creation when faculty does not own the FacultyAssignment', async () => {
      jest.spyOn(TeachingAuthorizationService, 'assertFacultyAssignmentAccess').mockRejectedValue(
        new Error('You are not authorized to manage classes for another faculty member')
      );

      await expect(
        PracticalService.createSession(collegeId, mockFacultyUser, {
          facultyAssignmentId: facultyAssignmentId.toString(),
          topic: 'System Calls Lab',
          scheduledDate: new Date(),
        })
      ).rejects.toThrow(/not authorized/);
    });
  });

  describe('2. Room Validation & Scheduling', () => {
    it('rejects session scheduling if specified room is inactive or retired', async () => {
      jest.spyOn(TeachingAuthorizationService, 'assertFacultyAssignmentAccess').mockResolvedValue(mockFacultyAssignment);
      jest.spyOn(Subject, 'findById').mockResolvedValue(mockPracticalSubject);

      const roomId = new Types.ObjectId();
      jest.spyOn(Room, 'findById').mockResolvedValue({
        _id: roomId,
        collegeId: new Types.ObjectId(collegeId),
        code: 'LAB-101',
        status: 'retired',
        isActive: false,
      } as any);

      await expect(
        PracticalService.createSession(collegeId, mockFacultyUser, {
          facultyAssignmentId: facultyAssignmentId.toString(),
          topic: 'Processes & Forking',
          scheduledDate: new Date(),
          roomId: roomId.toString(),
        })
      ).rejects.toThrow(/inactive or retired/);
    });
  });

  describe('3. Roster Resolution & Session Creation', () => {
    it('creates practical session and initializes participation records for enrolled roster', async () => {
      jest.spyOn(TeachingAuthorizationService, 'assertFacultyAssignmentAccess').mockResolvedValue(mockFacultyAssignment);
      jest.spyOn(Subject, 'findById').mockResolvedValue(mockPracticalSubject);

      const activeEnrollments = [
        { _id: new Types.ObjectId(), studentId, status: 'active' },
        { _id: new Types.ObjectId(), studentId: new Types.ObjectId(), status: 'active' },
      ];
      jest.spyOn(StudentEnrollment, 'find').mockResolvedValue(activeEnrollments as any);

      const mockSessionId = new Types.ObjectId();
      const mockCreatedSession: any = {
        _id: mockSessionId,
        collegeId: new Types.ObjectId(collegeId),
        topic: 'IPC via Pipes & Shared Memory',
        status: PracticalSessionStatus.PLANNED,
        totalEnrolled: 2,
        scheduledDate: new Date(),
      };
      jest.spyOn(PracticalSession, 'create').mockResolvedValue(mockCreatedSession);
      const insertManySpy = jest.spyOn(PracticalParticipation, 'insertMany').mockResolvedValue([] as any);

      const session = await PracticalService.createSession(collegeId, mockFacultyUser, {
        facultyAssignmentId: facultyAssignmentId.toString(),
        topic: 'IPC via Pipes & Shared Memory',
        scheduledDate: new Date().toISOString(),
      });

      expect(session).toBeDefined();
      expect(insertManySpy).toHaveBeenCalledTimes(1);
      expect(insertManySpy.mock.calls[0][0]).toHaveLength(2);
      expect(realtimeEventBus.publish).toHaveBeenCalled();
    });
  });

  describe('4. Session Execution & Lifecycle Transitions', () => {
    it('opens planned session and sets actualDate', async () => {
      const sessionId = new Types.ObjectId();
      const sessionDoc: any = {
        _id: sessionId,
        collegeId: new Types.ObjectId(collegeId),
        departmentId,
        courseId,
        semesterId,
        academicYearId,
        sectionId,
        facultyAssignmentId,
        status: PracticalSessionStatus.PLANNED,
        topic: 'Threads and Mutexes',
        save: jest.fn().mockResolvedValue(true),
      };

      jest.spyOn(PracticalSession, 'findOne').mockResolvedValue(sessionDoc);
      jest.spyOn(TeachingAuthorizationService, 'assertFacultyAssignmentAccess').mockResolvedValue(mockFacultyAssignment);
      jest.spyOn(StudentEnrollment, 'find').mockResolvedValue([{ studentId, _id: new Types.ObjectId() }] as any);
      jest.spyOn(PracticalParticipation, 'find').mockReturnValue({
        select: jest.fn().mockResolvedValue([{ studentId: studentId.toString() }]),
      } as any);

      const opened = await PracticalService.openSession(collegeId, mockFacultyUser, sessionId.toString());
      expect(opened.status).toBe(PracticalSessionStatus.OPEN);
      expect(sessionDoc.save).toHaveBeenCalled();
      expect(realtimeEventBus.publish).toHaveBeenCalledWith(
        expect.objectContaining({ action: 'OPENED' })
      );
    });

    it('rejects opening an already completed or cancelled session', async () => {
      const sessionId = new Types.ObjectId();
      const completedSession: any = {
        _id: sessionId,
        collegeId: new Types.ObjectId(collegeId),
        facultyAssignmentId,
        status: PracticalSessionStatus.COMPLETED,
      };

      jest.spyOn(PracticalSession, 'findOne').mockResolvedValue(completedSession);
      jest.spyOn(TeachingAuthorizationService, 'assertFacultyAssignmentAccess').mockResolvedValue(mockFacultyAssignment);

      await expect(
        PracticalService.openSession(collegeId, mockFacultyUser, sessionId.toString())
      ).rejects.toThrow(/already completed/);
    });

    it('completes an open practical session', async () => {
      const sessionId = new Types.ObjectId();
      const openSessionDoc: any = {
        _id: sessionId,
        collegeId: new Types.ObjectId(collegeId),
        departmentId,
        facultyAssignmentId,
        status: PracticalSessionStatus.OPEN,
        save: jest.fn().mockResolvedValue(true),
      };

      jest.spyOn(PracticalSession, 'findOne').mockResolvedValue(openSessionDoc);
      jest.spyOn(TeachingAuthorizationService, 'assertFacultyAssignmentAccess').mockResolvedValue(mockFacultyAssignment);
      jest.spyOn(PracticalParticipation, 'aggregate').mockResolvedValue([
        { _id: PracticalParticipationStatus.COMPLETED, count: 18 },
        { _id: PracticalParticipationStatus.ABSENT, count: 2 },
      ] as any);
      jest.spyOn(PracticalSession, 'findByIdAndUpdate').mockResolvedValue({} as any);

      const completed = await PracticalService.completeSession(collegeId, mockFacultyUser, sessionId.toString());
      expect(completed.status).toBe(PracticalSessionStatus.COMPLETED);
      expect(realtimeEventBus.publish).toHaveBeenCalledWith(
        expect.objectContaining({ action: 'COMPLETED' })
      );
    });
  });

  describe('5. Student Participation Updates', () => {
    it('updates participation status and sets timestamps', async () => {
      const sessionId = new Types.ObjectId();
      const sessionDoc: any = {
        _id: sessionId,
        collegeId: new Types.ObjectId(collegeId),
        facultyAssignmentId,
        status: PracticalSessionStatus.OPEN,
      };

      const participationDoc: any = {
        _id: new Types.ObjectId(),
        collegeId: new Types.ObjectId(collegeId),
        practicalSessionId: sessionId,
        studentId,
        status: PracticalParticipationStatus.NOT_STARTED,
        save: jest.fn().mockResolvedValue(true),
      };

      jest.spyOn(PracticalSession, 'findOne').mockResolvedValue(sessionDoc);
      jest.spyOn(TeachingAuthorizationService, 'assertFacultyAssignmentAccess').mockResolvedValue(mockFacultyAssignment);
      jest.spyOn(PracticalParticipation, 'findOne').mockResolvedValue(participationDoc);
      jest.spyOn(PracticalParticipation, 'aggregate').mockResolvedValue([]);
      jest.spyOn(PracticalSession, 'findByIdAndUpdate').mockResolvedValue({} as any);

      const updated = await PracticalService.updateParticipation(
        collegeId,
        mockFacultyUser,
        sessionId.toString(),
        studentId.toString(),
        {
          status: PracticalParticipationStatus.COMPLETED,
          notes: 'Completed linked list insertion task successfully',
        }
      );

      expect(updated.status).toBe(PracticalParticipationStatus.COMPLETED);
      expect(participationDoc.completedAt).toBeDefined();
      expect(participationDoc.save).toHaveBeenCalled();
    });

    it('rejects participation updates on cancelled sessions', async () => {
      const sessionId = new Types.ObjectId();
      const cancelledSession: any = {
        _id: sessionId,
        collegeId: new Types.ObjectId(collegeId),
        facultyAssignmentId,
        status: PracticalSessionStatus.CANCELLED,
      };

      jest.spyOn(PracticalSession, 'findOne').mockResolvedValue(cancelledSession);
      jest.spyOn(TeachingAuthorizationService, 'assertFacultyAssignmentAccess').mockResolvedValue(mockFacultyAssignment);

      await expect(
        PracticalService.updateParticipation(
          collegeId,
          mockFacultyUser,
          sessionId.toString(),
          studentId.toString(),
          { status: PracticalParticipationStatus.COMPLETED }
        )
      ).rejects.toThrow(/cancelled session/);
    });
  });

  describe('6. Student Practical History & Isolation', () => {
    it('restricts students to reading only their own practical participation records', async () => {
      const studentContext = {
        id: studentUserId,
        role: 'student',
        collegeId,
      };

      jest.spyOn(Student, 'findOne').mockResolvedValue({
        _id: studentId,
        userId: new Types.ObjectId(studentUserId),
      } as any);

      const findMock = jest.fn().mockReturnValue({
        populate: jest.fn().mockReturnValue({
          sort: jest.fn().mockResolvedValue([
            {
              _id: new Types.ObjectId(),
              status: PracticalParticipationStatus.COMPLETED,
              practicalSessionId: {
                _id: new Types.ObjectId(),
                topic: 'Binary Search Trees Lab',
                sessionNumber: 4,
                scheduledDate: new Date(),
                status: PracticalSessionStatus.COMPLETED,
                subjectId: { name: 'Data Structures Lab', code: 'CS202L' },
              },
            },
          ]),
        }),
      });

      jest.spyOn(PracticalParticipation, 'find').mockImplementation(findMock as any);

      const history = await PracticalService.getStudentPracticalHistory(collegeId, studentContext);

      expect(history).toHaveLength(1);
      expect(history[0].topic).toBe('Binary Search Trees Lab');
      expect(history[0].participationStatus).toBe(PracticalParticipationStatus.COMPLETED);
      expect(findMock).toHaveBeenCalledWith(
        expect.objectContaining({ studentId })
      );
    });
  });
});
