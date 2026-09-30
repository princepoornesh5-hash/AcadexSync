import { Types } from 'mongoose';
import { AssignmentService } from '../../src/services/assignment.service';
import {
  Assignment,
  AssignmentSubmission,
  Student,
  StudentEnrollment,
} from '../../src/models';
import {
  AssignmentStatus,
  FacultyReviewStatus,
  StudentTaskStatus,
} from '../../src/constants/assignment.constants';
import { TeachingAuthorizationService } from '../../src/services/teachingAuthorization.service';
import { realtimeEventBus } from '../../src/realtime';
import { NotificationService } from '../../src/services/notification.service';

describe('PROMPT 40 — Assignment Submission, File Upload, Review & Marking Unit Tests', () => {
  const collegeId = new Types.ObjectId().toString();
  const studentUserId = new Types.ObjectId().toString();
  const studentId = new Types.ObjectId();
  const facultyUserId = new Types.ObjectId().toString();
  const facultyAssignmentId = new Types.ObjectId();
  const semesterId = new Types.ObjectId();
  const courseId = new Types.ObjectId();
  const subjectId = new Types.ObjectId();

  const mockAssignmentDoc: any = {
    _id: new Types.ObjectId(),
    id: 'asgn_p40_1',
    collegeId: new Types.ObjectId(collegeId),
    facultyId: new Types.ObjectId(facultyUserId),
    facultyAssignmentId,
    semesterId,
    courseId,
    subjectId,
    title: 'Data Structures Lab 1',
    maximumMarks: 20,
    status: AssignmentStatus.PUBLISHED,
    dueDateTime: new Date(Date.now() + 86400000), // Tomorrow
  };

  beforeEach(() => {
    jest.clearAllMocks();
    jest.spyOn(NotificationService, 'createNotification').mockResolvedValue({} as any);
  });

  describe('Student Eligibility & Submission Lifecycle', () => {
    it('TEST S1: Student can save a draft submission with text and attachments', async () => {
      jest.spyOn(Assignment, 'findOne').mockResolvedValue(mockAssignmentDoc);
      jest.spyOn(Student, 'findOne').mockResolvedValue({
        _id: studentId,
        userId: new Types.ObjectId(studentUserId),
        name: 'Ada Lovelace',
      } as any);
      jest.spyOn(StudentEnrollment, 'findOne').mockResolvedValue({
        _id: new Types.ObjectId(),
        status: 'active',
      } as any);
      jest.spyOn(AssignmentSubmission, 'findOne').mockResolvedValue(null);

      const saveSpy = jest.fn().mockResolvedValue(true);
      jest.spyOn(AssignmentSubmission.prototype, 'save').mockImplementation(saveSpy);

      const draft = await AssignmentService.saveDraftSubmission(
        collegeId,
        { id: studentUserId, name: 'Ada Lovelace' },
        mockAssignmentDoc._id.toString(),
        {
          textResponse: 'Draft solution notes...',
          attachments: [
            {
              name: 'solution.pdf',
              url: 'https://ik.imagekit.io/acadex/solution.pdf',
              fileId: 'file_1',
            },
          ],
        }
      );

      expect(draft.status).toBe(StudentTaskStatus.DRAFT);
      expect(draft.textResponse).toBe('Draft solution notes...');
      expect(draft.attachments.length).toBe(1);
      expect(saveSpy).toHaveBeenCalled();
    });

    it('TEST S2 & S8: Submitting after due date correctly flags isLate = true', async () => {
      const pastDueAssignment = {
        ...mockAssignmentDoc,
        _id: new Types.ObjectId(),
        dueDateTime: new Date(Date.now() - 3600000), // 1 hour ago
      };

      jest.spyOn(Assignment, 'findOne').mockResolvedValue(pastDueAssignment);
      jest.spyOn(Student, 'findOne').mockResolvedValue({
        _id: studentId,
        userId: new Types.ObjectId(studentUserId),
        name: 'Ada Lovelace',
      } as any);
      jest.spyOn(StudentEnrollment, 'findOne').mockResolvedValue({
        _id: new Types.ObjectId(),
        status: 'active',
      } as any);
      jest.spyOn(AssignmentSubmission, 'findOne').mockResolvedValue(null);

      const publishSpy = jest.spyOn(realtimeEventBus, 'publish').mockImplementation();
      jest.spyOn(AssignmentSubmission.prototype, 'save').mockResolvedValue(true as any);

      const submission = await AssignmentService.submitAssignment(
        collegeId,
        { id: studentUserId, name: 'Ada Lovelace' },
        pastDueAssignment._id.toString(),
        {
          textResponse: 'Submitted work',
          attachments: [],
        }
      );

      expect(submission.isLate).toBe(true);
      expect(submission.status).toBe(StudentTaskStatus.SUBMITTED);
      expect(submission.submittedAt).toBeDefined();
      expect(publishSpy).toHaveBeenCalled();
    });

    it('TEST S10: Resubmission increments version and preserves previous version in submissionHistory', async () => {
      const initialSubmission: any = {
        _id: new Types.ObjectId(),
        collegeId: new Types.ObjectId(collegeId),
        assignmentId: mockAssignmentDoc._id,
        studentId,
        studentUserId: new Types.ObjectId(studentUserId),
        studentName: 'Ada Lovelace',
        status: StudentTaskStatus.SUBMITTED,
        textResponse: 'Version 1 Response',
        attachments: [{ name: 'v1.pdf', url: 'https://ik.imagekit.io/v1.pdf' }],
        submittedAt: new Date(Date.now() - 7200000),
        isLate: false,
        version: 1,
        submissionHistory: [],
        reviewStatus: FacultyReviewStatus.REVIEWED,
        marks: 18,
        feedback: 'Good v1',
        save: jest.fn().mockResolvedValue(true),
      };

      jest.spyOn(Assignment, 'findOne').mockResolvedValue(mockAssignmentDoc);
      jest.spyOn(Student, 'findOne').mockResolvedValue({
        _id: studentId,
        userId: new Types.ObjectId(studentUserId),
      } as any);
      jest.spyOn(StudentEnrollment, 'findOne').mockResolvedValue({
        _id: new Types.ObjectId(),
        status: 'active',
      } as any);
      jest.spyOn(AssignmentSubmission, 'findOne').mockResolvedValue(initialSubmission);

      const resubmission = await AssignmentService.submitAssignment(
        collegeId,
        { id: studentUserId, name: 'Ada Lovelace' },
        mockAssignmentDoc._id.toString(),
        {
          textResponse: 'Version 2 Updated Response',
          attachments: [{ name: 'v2.pdf', url: 'https://ik.imagekit.io/v2.pdf' }],
        }
      );

      expect(resubmission.version).toBe(2);
      expect(resubmission.status).toBe(StudentTaskStatus.RESUBMITTED);
      expect(resubmission.reviewStatus).toBe(FacultyReviewStatus.NOT_REVIEWED);
      expect(resubmission.marks).toBeNull();
      expect(resubmission.submissionHistory.length).toBe(1);
      expect(resubmission.submissionHistory[0].version).toBe(1);
      expect(resubmission.submissionHistory[0].textResponse).toBe('Version 1 Response');
      expect(resubmission.submissionHistory[0].marks).toBe(18);
    });

    it('TEST S3: Student not enrolled in academic context is forbidden from submitting', async () => {
      jest.spyOn(Assignment, 'findOne').mockResolvedValue(mockAssignmentDoc);
      jest.spyOn(Student, 'findOne').mockResolvedValue({
        _id: studentId,
        userId: new Types.ObjectId(studentUserId),
      } as any);
      jest.spyOn(StudentEnrollment, 'findOne').mockResolvedValue(null); // Not enrolled!

      await expect(
        AssignmentService.submitAssignment(
          collegeId,
          { id: studentUserId },
          mockAssignmentDoc._id.toString(),
          { textResponse: 'Test' }
        )
      ).rejects.toThrow('You are not enrolled in the academic context for this assignment.');
    });

    it('TEST S6 & S7: Cannot submit to DRAFT or ARCHIVED assignment', async () => {
      const draftAssignment = { ...mockAssignmentDoc, status: AssignmentStatus.DRAFT };
      jest.spyOn(Assignment, 'findOne').mockResolvedValue(draftAssignment);

      await expect(
        AssignmentService.submitAssignment(
          collegeId,
          { id: studentUserId },
          mockAssignmentDoc._id.toString(),
          { textResponse: 'Test' }
        )
      ).rejects.toThrow('This assignment is not currently open for submission.');

      const archivedAssignment = { ...mockAssignmentDoc, status: AssignmentStatus.ARCHIVED };
      jest.spyOn(Assignment, 'findOne').mockResolvedValue(archivedAssignment);

      await expect(
        AssignmentService.submitAssignment(
          collegeId,
          { id: studentUserId },
          mockAssignmentDoc._id.toString(),
          { textResponse: 'Test' }
        )
      ).rejects.toThrow('Cannot submit to an archived assignment.');
    });
  });

  describe('Secure File Upload & Storage Abstraction', () => {
    it('TEST F1 & F3: Upload authorization validates MIME type and generates tenant-isolated params', async () => {
      jest.spyOn(Assignment, 'findOne').mockResolvedValue(mockAssignmentDoc);
      jest.spyOn(Student, 'findOne').mockResolvedValue({
        _id: studentId,
        userId: new Types.ObjectId(studentUserId),
      } as any);
      jest.spyOn(StudentEnrollment, 'findOne').mockResolvedValue({ _id: new Types.ObjectId() } as any);

      const auth = await AssignmentService.getSubmissionUploadAuth(
        collegeId,
        { id: studentUserId, role: 'STUDENT' },
        mockAssignmentDoc._id.toString(),
        {
          fileName: 'code.pdf',
          mimeType: 'application/pdf',
          fileSize: 1024 * 50,
        }
      );

      expect(auth.storageKey).toContain(collegeId);
      expect(auth.storageKey).toContain(mockAssignmentDoc._id.toString());
      expect(auth.storageKey).toContain(studentId.toString());
      expect(auth.token).toBeDefined();

      // Invalid mime type rejected
      await expect(
        AssignmentService.getSubmissionUploadAuth(
          collegeId,
          { id: studentUserId, role: 'STUDENT' },
          mockAssignmentDoc._id.toString(),
          {
            fileName: 'malicious.exe',
            mimeType: 'application/x-msdownload',
          }
        )
      ).rejects.toThrow('Unsupported MIME type');
    });

    it('TEST F7 & F8: File download URL generation enforces ownership and authorization', async () => {
      const otherStudentUserId = new Types.ObjectId().toString();
      const mockSubWithFile: any = {
        _id: new Types.ObjectId(),
        assignmentId: mockAssignmentDoc._id,
        collegeId: new Types.ObjectId(collegeId),
        studentUserId: new Types.ObjectId(studentUserId),
        attachments: [
          {
            name: 'lab1.pdf',
            fileId: 'file_lab1',
            storageKey: '/acadex/submissions/file_lab1.pdf',
            url: 'https://ik.imagekit.io/file_lab1.pdf',
          },
        ],
      };

      jest.spyOn(Assignment, 'findOne').mockResolvedValue(mockAssignmentDoc);
      jest.spyOn(AssignmentSubmission, 'findOne').mockResolvedValue(mockSubWithFile);

      // Student who owns submission can download
      const studentDownload = await AssignmentService.getSubmissionFileDownloadUrl(
        collegeId,
        { id: studentUserId, role: 'STUDENT' },
        mockAssignmentDoc._id.toString(),
        'file_lab1'
      );
      expect(studentDownload.downloadUrl).toBeDefined();
      expect(studentDownload.fileName).toBe('lab1.pdf');

      // Another student is forbidden from downloading
      await expect(
        AssignmentService.getSubmissionFileDownloadUrl(
          collegeId,
          { id: otherStudentUserId, role: 'STUDENT' },
          mockAssignmentDoc._id.toString(),
          'file_lab1'
        )
      ).rejects.toThrow("You cannot access another student's submission files.");

      // Authorized faculty can download
      jest.spyOn(TeachingAuthorizationService, 'assertAssignmentAccess').mockResolvedValue();
      const facultyDownload = await AssignmentService.getSubmissionFileDownloadUrl(
        collegeId,
        { id: facultyUserId, role: 'FACULTY' },
        mockAssignmentDoc._id.toString(),
        'file_lab1'
      );
      expect(facultyDownload.downloadUrl).toBeDefined();
    });
  });

  describe('Faculty Review & Single Marking', () => {
    it('TEST R4 & R5: Reviewing submission enforces marks <= maximumMarks and persists review', async () => {
      const mockSub: any = {
        _id: new Types.ObjectId(),
        assignmentId: mockAssignmentDoc._id,
        collegeId: new Types.ObjectId(collegeId),
        studentId,
        studentUserId: new Types.ObjectId(studentUserId),
        marks: null,
        feedback: null,
        reviewStatus: FacultyReviewStatus.NOT_REVIEWED,
        save: jest.fn().mockResolvedValue(true),
      };

      jest.spyOn(Assignment, 'findOne').mockResolvedValue(mockAssignmentDoc);
      jest.spyOn(TeachingAuthorizationService, 'assertAssignmentAccess').mockResolvedValue();
      jest.spyOn(AssignmentSubmission, 'findOne').mockResolvedValue(mockSub);
      const publishSpy = jest.spyOn(realtimeEventBus, 'publish').mockImplementation();

      // Reject marks > maximumMarks (20)
      await expect(
        AssignmentService.reviewSingleSubmission(
          collegeId,
          { id: facultyUserId, role: 'FACULTY' },
          mockAssignmentDoc._id.toString(),
          mockSub._id.toString(),
          { marks: 25 } // Above max 20!
        )
      ).rejects.toThrow('cannot exceed maximum marks');

      // Valid marks accepted
      const reviewed = await AssignmentService.reviewSingleSubmission(
        collegeId,
        { id: facultyUserId, role: 'FACULTY' },
        mockAssignmentDoc._id.toString(),
        mockSub._id.toString(),
        { marks: 19, feedback: 'Excellent analysis of algorithmic complexity.' }
      );

      expect(reviewed.marks).toBe(19);
      expect(reviewed.feedback).toBe('Excellent analysis of algorithmic complexity.');
      expect(reviewed.reviewStatus).toBe(FacultyReviewStatus.REVIEWED);
      expect(reviewed.reviewedAt).toBeDefined();
      expect(publishSpy).toHaveBeenCalled();
    });

    it('TEST R6: Student cannot review or mark submissions', async () => {
      jest.spyOn(Assignment, 'findOne').mockResolvedValue(mockAssignmentDoc);

      await expect(
        AssignmentService.reviewSingleSubmission(
          collegeId,
          { id: studentUserId, role: 'STUDENT' },
          mockAssignmentDoc._id.toString(),
          new Types.ObjectId().toString(),
          { marks: 20 }
        )
      ).rejects.toThrow('Students cannot review or grade submissions.');
    });
  });
});
