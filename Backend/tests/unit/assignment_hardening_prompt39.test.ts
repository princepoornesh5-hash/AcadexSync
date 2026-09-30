import { Types } from 'mongoose';
import { TeachingAuthorizationService } from '../../src/services/teachingAuthorization.service';
import { FacultyAssignment } from '../../src/models/facultyAssignment.model';
import { Assignment } from '../../src/models/assignment.model';
import { AssignmentSubmission } from '../../src/models/assignmentSubmission.model';
import { AssignmentService } from '../../src/services/assignment.service';
import { AssignmentStatus } from '../../src/constants/assignment.constants';

// Mock Mongoose models for unit isolation
jest.mock('../../src/models/facultyAssignment.model');
jest.mock('../../src/models/assignment.model');
jest.mock('../../src/models/assignmentSubmission.model');
jest.mock('../../src/models/studentEnrollment.model');
jest.mock('../../src/models/student.model');
jest.mock('../../src/models/faculty.model');
jest.mock('../../src/models/subject.model');

describe('PROMPT 39 — Assignment Hardening & Authorization Test Suite', () => {
  const collegeIdA = new Types.ObjectId().toString();
  const deptCSE = new Types.ObjectId().toString();
  const deptECE = new Types.ObjectId().toString();
  const facultyUserId = new Types.ObjectId().toString();
  const otherFacultyUserId = new Types.ObjectId().toString();
  const assignmentId = new Types.ObjectId().toString();
  const facultyAssignmentId = new Types.ObjectId().toString();

  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('Security & Teaching Authorization Boundaries', () => {
    it('TEST S1: Authorized Faculty can access their owned FacultyAssignment', async () => {
      const mockFa = {
        _id: new Types.ObjectId(facultyAssignmentId),
        collegeId: new Types.ObjectId(collegeIdA),
        departmentId: new Types.ObjectId(deptCSE),
        facultyId: new Types.ObjectId(facultyUserId),
        facultyName: 'Dr. Alan Turing',
        isActive: true,
        status: 'active',
      };

      (FacultyAssignment.findOne as jest.Mock).mockResolvedValue(mockFa);

      const result = await TeachingAuthorizationService.assertFacultyAssignmentAccess(
        collegeIdA,
        { id: facultyUserId, role: 'FACULTY' },
        facultyAssignmentId
      );

      expect(result).toBeDefined();
      expect(result._id.toString()).toBe(facultyAssignmentId);
    });

    it('TEST S3: Faculty cannot access another Faculty teaching context', async () => {
      const mockFa = {
        _id: new Types.ObjectId(facultyAssignmentId),
        collegeId: new Types.ObjectId(collegeIdA),
        departmentId: new Types.ObjectId(deptCSE),
        facultyId: new Types.ObjectId(otherFacultyUserId),
        facultyName: 'Prof. Other',
        isActive: true,
        status: 'active',
      };

      (FacultyAssignment.findOne as jest.Mock).mockResolvedValue(mockFa);

      await expect(
        TeachingAuthorizationService.assertFacultyAssignmentAccess(
          collegeIdA,
          { id: facultyUserId, role: 'FACULTY' },
          facultyAssignmentId
        )
      ).rejects.toThrow('You are not authorized to manage this teaching context. This context is not assigned to you.');
    });

    it('TEST S5: HOD of Department A cannot access Department B teaching context', async () => {
      const mockFa = {
        _id: new Types.ObjectId(facultyAssignmentId),
        collegeId: new Types.ObjectId(collegeIdA),
        departmentId: new Types.ObjectId(deptECE), // Different department
        facultyId: new Types.ObjectId(facultyUserId),
        isActive: true,
        status: 'active',
      };

      (FacultyAssignment.findOne as jest.Mock).mockResolvedValue(mockFa);

      await expect(
        TeachingAuthorizationService.assertFacultyAssignmentAccess(
          collegeIdA,
          { id: 'hod_user_id', role: 'HOD', departmentId: deptCSE },
          facultyAssignmentId
        )
      ).rejects.toThrow('You are not authorized to manage this teaching context outside your department.');
    });

    it('TEST S6: Cross-tenant access is rejected when FacultyAssignment belongs to another College', async () => {
      // Query looks for collegeIdA, but record is in collegeIdB -> findOne returns null
      (FacultyAssignment.findOne as jest.Mock).mockResolvedValue(null);

      await expect(
        TeachingAuthorizationService.assertFacultyAssignmentAccess(
          collegeIdA,
          { id: facultyUserId, role: 'FACULTY' },
          facultyAssignmentId
        )
      ).rejects.toThrow('Teaching context (Faculty Assignment) not found for this college.');
    });

    it('TEST S8: Student is forbidden from asserting assignment management access', async () => {
      const mockFa = {
        _id: new Types.ObjectId(facultyAssignmentId),
        collegeId: new Types.ObjectId(collegeIdA),
        departmentId: new Types.ObjectId(deptCSE),
        facultyId: new Types.ObjectId(facultyUserId),
        isActive: true,
        status: 'active',
      };

      (FacultyAssignment.findOne as jest.Mock).mockResolvedValue(mockFa);

      await expect(
        TeachingAuthorizationService.assertFacultyAssignmentAccess(
          collegeIdA,
          { id: 'student_user_1', role: 'STUDENT' },
          facultyAssignmentId
        )
      ).rejects.toThrow('You are not authorized to manage this teaching context.');
    });
  });

  describe('Lifecycle & State Transition Hardening', () => {
    it('TEST S4: Inactive or ended FacultyAssignment cannot be used to create new Assignment', async () => {
      const mockEndedFa = {
        _id: new Types.ObjectId(facultyAssignmentId),
        collegeId: new Types.ObjectId(collegeIdA),
        departmentId: new Types.ObjectId(deptCSE),
        facultyId: new Types.ObjectId(facultyUserId),
        isActive: false, // Inactive!
        status: 'ended',
      };

      (FacultyAssignment.findOne as jest.Mock).mockResolvedValue(mockEndedFa);

      await expect(
        AssignmentService.createAssignment(
          collegeIdA,
          { id: facultyUserId, role: 'FACULTY' },
          {
            facultyAssignmentId,
            title: 'Quiz 1',
            description: 'Chapter 1 quiz',
            dueDate: '2026-10-15',
            dueTime: '11:59 PM',
            maximumMarks: 20,
          }
        )
      ).rejects.toThrow('This teaching assignment is no longer active.');
    });

    it('TEST L2 & L5: Closed or Archived assignment rejects edits', async () => {
      const mockClosedAssignment = {
        _id: new Types.ObjectId(assignmentId),
        collegeId: new Types.ObjectId(collegeIdA),
        facultyId: new Types.ObjectId(facultyUserId),
        status: AssignmentStatus.CLOSED,
      };

      (Assignment.findOne as jest.Mock).mockResolvedValue(mockClosedAssignment);

      await expect(
        AssignmentService.updateAssignment(
          collegeIdA,
          { id: facultyUserId, role: 'FACULTY' },
          assignmentId,
          { title: 'New Title' }
        )
      ).rejects.toThrow('Cannot edit a closed assignment.');
    });

    it('TEST L3: Cannot publish an assignment with a due date in the past', async () => {
      const mockPastAssignment = {
        _id: new Types.ObjectId(assignmentId),
        collegeId: new Types.ObjectId(collegeIdA),
        facultyId: new Types.ObjectId(facultyUserId),
        facultyAssignmentId: new Types.ObjectId(facultyAssignmentId),
        title: 'Overdue Assignment',
        status: AssignmentStatus.DRAFT,
        dueDateTime: new Date(Date.now() - 3600000), // 1 hour ago
      };

      const mockFa = {
        _id: new Types.ObjectId(facultyAssignmentId),
        collegeId: new Types.ObjectId(collegeIdA),
        facultyId: new Types.ObjectId(facultyUserId),
        isActive: true,
        status: 'active',
      };

      (Assignment.findOne as jest.Mock).mockResolvedValue(mockPastAssignment);
      (FacultyAssignment.findById as jest.Mock).mockResolvedValue(mockFa);

      await expect(
        AssignmentService.publishAssignment(
          collegeIdA,
          { id: facultyUserId, role: 'FACULTY' },
          assignmentId
        )
      ).rejects.toThrow('Cannot publish an assignment with a due date in the past.');
    });

    it('TEST L7: Published or submitted assignment cannot be destroyed; must be archived', async () => {
      const mockPublishedAssignment = {
        _id: new Types.ObjectId(assignmentId),
        collegeId: new Types.ObjectId(collegeIdA),
        facultyId: new Types.ObjectId(facultyUserId),
        status: AssignmentStatus.PUBLISHED,
      };

      (Assignment.findOne as jest.Mock).mockResolvedValue(mockPublishedAssignment);
      (AssignmentSubmission.countDocuments as jest.Mock).mockResolvedValue(5); // Has 5 submissions

      await expect(
        AssignmentService.deleteAssignment(
          collegeIdA,
          { id: facultyUserId, role: 'FACULTY' },
          assignmentId
        )
      ).rejects.toThrow('Cannot delete an assignment that is published or has student submission history. Please archive it instead.');
    });

    it('TEST L1 & L7: Draft assignment with no submissions can be safely deleted', async () => {
      const mockDraftAssignment = {
        _id: new Types.ObjectId(assignmentId),
        collegeId: new Types.ObjectId(collegeIdA),
        facultyId: new Types.ObjectId(facultyUserId),
        status: AssignmentStatus.DRAFT,
      };

      (Assignment.findOne as jest.Mock).mockResolvedValue(mockDraftAssignment);
      (AssignmentSubmission.countDocuments as jest.Mock).mockResolvedValue(0);
      (Assignment.deleteOne as jest.Mock).mockResolvedValue({ deletedCount: 1 });

      const result = await AssignmentService.deleteAssignment(
        collegeIdA,
        { id: facultyUserId, role: 'FACULTY' },
        assignmentId
      );

      expect(result.success).toBe(true);
      expect(result.message).toContain('Draft assignment deleted successfully.');
    });
  });

  describe('Section Optionality & Data Integrity', () => {
    it('TEST S10 & C1: Section-disabled assignment functions correctly with sectionId null', async () => {
      const mockFaWithoutSection = {
        _id: new Types.ObjectId(facultyAssignmentId),
        collegeId: new Types.ObjectId(collegeIdA),
        departmentId: new Types.ObjectId(deptCSE),
        courseId: new Types.ObjectId(),
        academicYearId: new Types.ObjectId(),
        semesterId: new Types.ObjectId(),
        sectionId: null, // Section Disabled!
        subjectId: new Types.ObjectId(),
        facultyId: new Types.ObjectId(facultyUserId),
        facultyName: 'Dr. Sectionless',
        isActive: true,
        status: 'active',
      };

      (FacultyAssignment.findOne as jest.Mock).mockResolvedValue(mockFaWithoutSection);
      (Assignment.findOne as jest.Mock).mockResolvedValue(null); // No recent duplicate
      (Assignment.create as jest.Mock).mockImplementation((data) => Promise.resolve({
        id: new Types.ObjectId().toString(),
        ...data,
      }));

      const futureDate = new Date();
      futureDate.setDate(futureDate.getDate() + 7);
      const dueDateStr = futureDate.toISOString().split('T')[0];

      const assignment = await AssignmentService.createAssignment(
        collegeIdA,
        { id: facultyUserId, role: 'FACULTY' },
        {
          facultyAssignmentId,
          title: 'Sectionless Coursework',
          description: 'Applicable to entire semester',
          dueDate: dueDateStr,
          dueTime: '11:59 PM',
          maximumMarks: 50,
          status: AssignmentStatus.DRAFT,
        }
      );

      expect(assignment).toBeDefined();
      expect(assignment.sectionId).toBeNull();
      expect(assignment.title).toBe('Sectionless Coursework');
    });
  });
});
