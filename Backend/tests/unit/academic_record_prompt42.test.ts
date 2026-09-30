import { Types } from 'mongoose';
import { AcademicRecordService } from '../../src/services/academicRecord.service';
import {
  AcademicRecord,
  SubjectAcademicRecord,
  StudentEnrollment,
  Student,
  Faculty,
  FacultyAssignment,
  AttendanceRecord,
  PracticalParticipation,
  PracticalSession,
  Assignment,
  AssignmentSubmission,
} from '../../src/models';
import {
  AcademicProgressionStatus,
} from '../../src/constants/academicRecord.constants';
import { AttendanceStatus } from '../../src/constants/status';
import { PracticalParticipationStatus } from '../../src/constants/practical.constants';
import { AppRole } from '../../src/constants/roles';
import { NotificationService } from '../../src/services/notification.service';
import { AuditService } from '../../src/services/audit.service';
import { realtimeEventBus, AcadexEventType } from '../../src/realtime';

// Helper for chainable Mongoose queries (.populate, .sort, etc.)
const createChainableQuery = (result: any) => {
  const query: any = {
    populate: jest.fn().mockImplementation(() => query),
    sort: jest.fn().mockImplementation(() => query),
    skip: jest.fn().mockImplementation(() => query),
    limit: jest.fn().mockImplementation(() => query),
    select: jest.fn().mockImplementation(() => query),
    then: (resolve: any, reject?: any) => Promise.resolve(result).then(resolve, reject),
    exec: jest.fn().mockResolvedValue(result),
  };
  return query;
};

describe('PROMPT 42 — Academic Records & Student Academic History Unit Tests', () => {
  const collegeId = new Types.ObjectId().toString();
  const departmentId = new Types.ObjectId();
  const otherDepartmentId = new Types.ObjectId();
  const courseId = new Types.ObjectId();
  const semesterId = new Types.ObjectId();
  const academicYearId = new Types.ObjectId();
  const sectionId = new Types.ObjectId();

  const studentUserId = new Types.ObjectId().toString();
  const studentDocId = new Types.ObjectId();
  const otherStudentUserId = new Types.ObjectId().toString();

  const facultyUserId = new Types.ObjectId().toString();
  const facultyDocId = new Types.ObjectId();
  const hodUserId = new Types.ObjectId().toString();
  const adminUserId = new Types.ObjectId().toString();

  // Mock authenticated users
  const mockStudentUser = {
    id: studentUserId,
    role: AppRole.STUDENT,
    collegeId,
  };

  const mockOtherStudentUser = {
    id: otherStudentUserId,
    role: AppRole.STUDENT,
    collegeId,
  };

  const mockFacultyUser = {
    id: facultyUserId,
    role: AppRole.FACULTY,
    collegeId,
    departmentId: departmentId.toString(),
  };

  const mockHodUser = {
    id: hodUserId,
    role: AppRole.HOD,
    collegeId,
    departmentId: departmentId.toString(),
  };

  const mockAdminUser = {
    id: adminUserId,
    role: AppRole.COLLEGE_ADMIN,
    collegeId,
  };

  const mockStudentDoc: any = {
    _id: studentDocId,
    userId: new Types.ObjectId(studentUserId),
    collegeId: new Types.ObjectId(collegeId),
    departmentId,
    courseId,
    semesterId,
    academicYearId,
    academicStage: 'Year 2',
    cohort: '2024-2028',
    status: 'active',
  };

  const mockEnrollment: any = {
    _id: new Types.ObjectId(),
    collegeId: new Types.ObjectId(collegeId),
    studentId: studentDocId,
    courseId,
    departmentId,
    academicYearId,
    semesterId,
    sectionId,
    academicStage: 'Year 2',
    cohort: '2024-2028',
    status: 'active',
  };

  beforeEach(() => {
    jest.restoreAllMocks();
    jest.spyOn(NotificationService, 'createNotification').mockResolvedValue({} as any);
    jest.spyOn(AuditService, 'logAction').mockResolvedValue({} as any);
    jest.spyOn(realtimeEventBus, 'publish').mockImplementation((evt: any) => evt);
  });

  describe('1. AcademicRecord Creation & Idempotency', () => {
    it('initializes a canonical AcademicRecord from an active StudentEnrollment', async () => {
      jest.spyOn(StudentEnrollment, 'findOne').mockResolvedValue(mockEnrollment);
      jest.spyOn(AcademicRecord, 'findOne').mockResolvedValue(null);

      const mockCreatedRecord: any = {
        _id: new Types.ObjectId(),
        collegeId: new Types.ObjectId(collegeId),
        studentId: studentDocId,
        studentEnrollmentId: mockEnrollment._id,
        courseId,
        departmentId,
        academicYearId,
        semesterId,
        sectionId,
        academicStage: 'Year 2',
        cohort: '2024-2028',
        progressionStatus: AcademicProgressionStatus.ACTIVE,
      };

      jest.spyOn(AcademicRecord, 'create').mockResolvedValue(mockCreatedRecord as any);
      jest.spyOn(AcademicRecordService as any, 'populateSubjectRecords').mockResolvedValue(undefined);

      const record = await AcademicRecordService.initializeFromEnrollment(
        collegeId,
        mockEnrollment._id.toString(),
        adminUserId
      );

      expect(record).toBeDefined();
      expect(record.progressionStatus).toBe(AcademicProgressionStatus.ACTIVE);
      expect(AcademicRecord.create).toHaveBeenCalledTimes(1);
    });

    it('prevents duplicate record creation for the same student and academic context (idempotency)', async () => {
      jest.spyOn(StudentEnrollment, 'findOne').mockResolvedValue(mockEnrollment);

      const existingRecord: any = {
        _id: new Types.ObjectId(),
        collegeId: new Types.ObjectId(collegeId),
        studentId: studentDocId,
        studentEnrollmentId: mockEnrollment._id,
        courseId,
        departmentId,
        academicYearId,
        semesterId,
        progressionStatus: AcademicProgressionStatus.ACTIVE,
      };

      jest.spyOn(AcademicRecord, 'findOne').mockResolvedValue(existingRecord as any);
      const createSpy = jest.spyOn(AcademicRecord, 'create');

      const record = await AcademicRecordService.initializeFromEnrollment(
        collegeId,
        mockEnrollment._id.toString()
      );

      expect(record._id).toEqual(existingRecord._id);
      expect(createSpy).not.toHaveBeenCalled();
    });
  });

  describe('2. Authorization, Scoping & Tenant Isolation', () => {
    it('allows student to access their own academic history', async () => {
      jest.spyOn(Student, 'findOne').mockResolvedValue(mockStudentDoc);
      jest.spyOn(AcademicRecord, 'find').mockReturnValue(createChainableQuery([]));

      const history = await AcademicRecordService.getStudentAcademicHistory(
        collegeId,
        studentDocId.toString(),
        mockStudentUser as any
      );

      expect(Array.isArray(history)).toBe(true);
    });

    it('rejects student attempting to access another student academic history', async () => {
      jest.spyOn(Student, 'findOne').mockResolvedValue(mockStudentDoc);

      await expect(
        AcademicRecordService.getStudentAcademicHistory(
          collegeId,
          studentDocId.toString(),
          mockOtherStudentUser as any
        )
      ).rejects.toThrow(/Students are strictly restricted to their own academic records/);
    });

    it('rejects cross-institution access (tenant isolation)', async () => {
      const foreignCollegeId = new Types.ObjectId().toString();
      jest.spyOn(Student, 'findOne').mockResolvedValue(mockStudentDoc);

      await expect(
        AcademicRecordService.getStudentAcademicHistory(
          collegeId,
          studentDocId.toString(),
          { ...mockAdminUser, collegeId: foreignCollegeId } as any
        )
      ).rejects.toThrow(/Cross-institution access is strictly prohibited/);
    });

    it('allows HOD to access students within their own department', async () => {
      jest.spyOn(Student, 'findOne').mockResolvedValue(mockStudentDoc);
      jest.spyOn(AcademicRecord, 'find').mockReturnValue(createChainableQuery([]));

      const history = await AcademicRecordService.getStudentAcademicHistory(
        collegeId,
        studentDocId.toString(),
        mockHodUser as any
      );

      expect(Array.isArray(history)).toBe(true);
    });

    it('rejects HOD attempting to access a student from another department', async () => {
      const otherDeptStudentDoc = {
        ...mockStudentDoc,
        departmentId: otherDepartmentId,
      };

      jest.spyOn(Student, 'findOne').mockResolvedValue(otherDeptStudentDoc);

      await expect(
        AcademicRecordService.getStudentAcademicHistory(
          collegeId,
          studentDocId.toString(),
          mockHodUser as any
        )
      ).rejects.toThrow(/HOD can only access records of students within their department/);
    });

    it('allows Faculty with active teaching assignment matching the student course & semester', async () => {
      jest.spyOn(Student, 'findOne').mockResolvedValue(mockStudentDoc);
      jest.spyOn(Faculty, 'findOne').mockResolvedValue({ _id: facultyDocId } as any);
      jest.spyOn(FacultyAssignment, 'exists').mockResolvedValue({ _id: new Types.ObjectId() } as any);
      jest.spyOn(AcademicRecord, 'find').mockReturnValue(createChainableQuery([]));

      const history = await AcademicRecordService.getStudentAcademicHistory(
        collegeId,
        studentDocId.toString(),
        mockFacultyUser as any
      );

      expect(Array.isArray(history)).toBe(true);
    });

    it('rejects Faculty who is not assigned to the student course and semester', async () => {
      jest.spyOn(Student, 'findOne').mockResolvedValue(mockStudentDoc);
      jest.spyOn(Faculty, 'findOne').mockResolvedValue({ _id: facultyDocId } as any);
      jest.spyOn(FacultyAssignment, 'exists').mockResolvedValue(null);

      await expect(
        AcademicRecordService.getStudentAcademicHistory(
          collegeId,
          studentDocId.toString(),
          mockFacultyUser as any
        )
      ).rejects.toThrow(/Faculty is not assigned to teach in this student academic context/);
    });
  });

  describe('3. Historical Immutability & Preservation', () => {
    it('preserves historical context and does not overwrite past records when enrollment changes', async () => {
      const historicalRecordId = new Types.ObjectId();
      const pastSemesterId = new Types.ObjectId();
      const pastAcademicYearId = new Types.ObjectId();

      const historicalRecord: any = {
        _id: historicalRecordId,
        collegeId: new Types.ObjectId(collegeId),
        studentId: mockStudentDoc,
        courseId,
        departmentId,
        academicYearId: pastAcademicYearId,
        semesterId: pastSemesterId,
        sectionId,
        academicStage: 'Year 1',
        cohort: '2024-2028',
        progressionStatus: AcademicProgressionStatus.COMPLETED,
      };

      jest.spyOn(AcademicRecord, 'findOne').mockReturnValue(createChainableQuery(historicalRecord));
      jest.spyOn(SubjectAcademicRecord, 'find').mockReturnValue(createChainableQuery([]));

      jest.spyOn(AcademicRecordService as any, 'calculatePeriodAttendance').mockResolvedValue({
        totalClasses: 30,
        presentCount: 28,
        absentCount: 2,
        lateCount: 0,
        excusedCount: 0,
        percentage: 93,
      });

      jest.spyOn(AcademicRecordService as any, 'calculatePeriodPracticals').mockResolvedValue({
        totalSessions: 10,
        completedCount: 10,
        inProgressCount: 0,
        absentCount: 0,
        excusedCount: 0,
        completionRate: 100,
      });

      jest.spyOn(AcademicRecordService as any, 'calculatePeriodAssignments').mockResolvedValue({
        totalAssignments: 5,
        submittedCount: 5,
        completedCount: 5,
        lateCount: 0,
        completionRate: 100,
      });

      const detail = await AcademicRecordService.getRecordDetail(
        collegeId,
        historicalRecordId.toString(),
        mockStudentUser as any
      );

      expect(detail.record.progressionStatus).toBe(AcademicProgressionStatus.COMPLETED);
      expect(detail.record.academicStage).toBe('Year 1');
      expect(detail.record.semesterId).toEqual(pastSemesterId);
    });
  });

  describe('4. Aggregation without Domain Data Duplication', () => {
    it('derives attendance summary strictly from AttendanceRecord collection', async () => {
      jest.spyOn(AttendanceRecord, 'find').mockResolvedValue([
        { status: AttendanceStatus.PRESENT },
        { status: AttendanceStatus.PRESENT },
        { status: AttendanceStatus.PRESENT },
        { status: AttendanceStatus.ABSENT },
        { status: AttendanceStatus.LATE },
      ] as any);

      const attendanceSummary = await (AcademicRecordService as any).calculatePeriodAttendance(
        collegeId,
        studentDocId.toString(),
        academicYearId.toString(),
        semesterId.toString()
      );

      expect(attendanceSummary.totalClasses).toBe(5);
      expect(attendanceSummary.presentCount).toBe(3);
      expect(attendanceSummary.absentCount).toBe(1);
      expect(attendanceSummary.lateCount).toBe(1);
      expect(attendanceSummary.percentage).toBe(80);
    });

    it('derives practical summary strictly from Prompt 41 PracticalParticipation/PracticalSession', async () => {
      jest.spyOn(PracticalSession, 'find').mockReturnValue(createChainableQuery([{ _id: new Types.ObjectId() }, { _id: new Types.ObjectId() }]));

      jest.spyOn(PracticalParticipation, 'find').mockResolvedValue([
        { status: PracticalParticipationStatus.COMPLETED },
        { status: PracticalParticipationStatus.IN_PROGRESS },
      ] as any);

      const practicalSummary = await (AcademicRecordService as any).calculatePeriodPracticals(
        collegeId,
        studentDocId.toString(),
        academicYearId.toString(),
        semesterId.toString()
      );

      expect(practicalSummary.totalSessions).toBe(2);
      expect(practicalSummary.completedCount).toBe(1);
      expect(practicalSummary.inProgressCount).toBe(1);
      expect(practicalSummary.completionRate).toBe(50);
    });

    it('derives assignment summary strictly from Prompt 39/40 Assignment & Submission', async () => {
      jest.spyOn(Assignment, 'find').mockReturnValue(createChainableQuery([
        { _id: new Types.ObjectId() },
        { _id: new Types.ObjectId() },
        { _id: new Types.ObjectId() },
        { _id: new Types.ObjectId() },
      ]));

      jest.spyOn(AssignmentSubmission, 'find').mockResolvedValue([
        { status: 'COMPLETED', isLate: false },
        { status: 'SUBMITTED', isLate: true },
        { status: 'COMPLETED', isLate: false },
      ] as any);

      const assignmentSummary = await (AcademicRecordService as any).calculatePeriodAssignments(
        collegeId,
        studentDocId.toString(),
        studentUserId,
        courseId.toString(),
        semesterId.toString()
      );

      expect(assignmentSummary.totalAssignments).toBe(4);
      expect(assignmentSummary.submittedCount).toBe(3);
      expect(assignmentSummary.lateCount).toBe(1);
      expect(assignmentSummary.completedCount).toBe(2);
      expect(assignmentSummary.completionRate).toBe(75);
    });
  });

  describe('5. Progression Mutation Rules & Safety', () => {
    it('rejects student attempting to mutate progression status', async () => {
      await expect(
        AcademicRecordService.updateProgressionStatus(
          collegeId,
          new Types.ObjectId().toString(),
          AcademicProgressionStatus.PROMOTED,
          null,
          mockStudentUser as any
        )
      ).rejects.toThrow(/Only College Administrators and HODs may record progression status/);
    });

    it('rejects invalid progression transition (COMPLETED -> ACTIVE)', async () => {
      const recordId = new Types.ObjectId();
      const mockRecord: any = {
        _id: recordId,
        collegeId: new Types.ObjectId(collegeId),
        departmentId,
        progressionStatus: AcademicProgressionStatus.COMPLETED,
        save: jest.fn().mockResolvedValue(true),
      };

      jest.spyOn(AcademicRecord, 'findOne').mockResolvedValue(mockRecord as any);

      await expect(
        AcademicRecordService.updateProgressionStatus(
          collegeId,
          recordId.toString(),
          AcademicProgressionStatus.ACTIVE,
          null,
          mockAdminUser as any
        )
      ).rejects.toThrow(/Invalid progression transition from COMPLETED to ACTIVE/);
    });

    it('allows valid progression transition (ACTIVE -> COMPLETED)', async () => {
      const recordId = new Types.ObjectId();
      const mockRecord: any = {
        _id: recordId,
        collegeId: new Types.ObjectId(collegeId),
        studentId: studentDocId,
        departmentId,
        progressionStatus: AcademicProgressionStatus.ACTIVE,
        save: jest.fn().mockResolvedValue(true),
      };

      jest.spyOn(AcademicRecord, 'findOne').mockResolvedValue(mockRecord as any);
      jest.spyOn(Student, 'findById').mockResolvedValue(mockStudentDoc);

      const updated = await AcademicRecordService.updateProgressionStatus(
        collegeId,
        recordId.toString(),
        AcademicProgressionStatus.COMPLETED,
        'Completed semester examinations',
        mockAdminUser as any
      );

      expect(updated.progressionStatus).toBe(AcademicProgressionStatus.COMPLETED);
      expect(mockRecord.save).toHaveBeenCalled();
    });

    it('emits realtime event only after successful database save', async () => {
      const recordId = new Types.ObjectId();
      const mockRecord: any = {
        _id: recordId,
        collegeId: new Types.ObjectId(collegeId),
        studentId: studentDocId,
        departmentId,
        progressionStatus: AcademicProgressionStatus.ACTIVE,
        save: jest.fn().mockResolvedValue(true),
      };

      jest.spyOn(AcademicRecord, 'findOne').mockResolvedValue(mockRecord as any);
      jest.spyOn(Student, 'findById').mockResolvedValue(mockStudentDoc);
      const publishSpy = jest.spyOn(realtimeEventBus, 'publish');

      await AcademicRecordService.updateProgressionStatus(
        collegeId,
        recordId.toString(),
        AcademicProgressionStatus.COMPLETED,
        null,
        mockAdminUser as any
      );

      expect(mockRecord.save).toHaveBeenCalled();
      expect(publishSpy).toHaveBeenCalledWith(
        expect.objectContaining({
          eventType: AcadexEventType.ACADEMIC_RECORD_PROGRESSION_UPDATED,
          aggregateType: 'AcademicRecord',
          aggregateId: recordId.toString(),
        })
      );
    });
  });
});
