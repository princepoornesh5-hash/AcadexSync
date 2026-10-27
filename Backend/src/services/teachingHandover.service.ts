import mongoose from 'mongoose';
import {
  FacultyAssignment,
  IFacultyAssignment,
  TeachingHandover,
  ITeachingHandover,
  Faculty,
  Assignment,
  AttendanceSession,
  AuditLog,
} from '../models';
import { AppRole } from '../constants/roles';
import { AssignmentStatus } from '../constants/assignment.constants';
import { ApiError } from '../utils/apiError';
import { AuthenticatedUser } from '../types/auth.types';

export interface ExecuteTeachingHandoverInput {
  collegeId?: string;
  sourceAssignmentId: string;
  successorFacultyId: string;
  reassignPendingWork?: boolean;
  notes?: string;
}

export class TeachingHandoverService {
  /**
   * Safely hand over a teaching assignment to a successor faculty member.
   * - Preserves immutable historical attribution on past sessions and submitted marks.
   * - Safely transitions active status to the successor.
   * - Reassigns open/draft pending assignments and unsubmitted attendance if requested.
   * - Retains original author references on reassigned work.
   */
  static async handoverTeachingAssignment(
    requester: AuthenticatedUser,
    input: ExecuteTeachingHandoverInput
  ): Promise<{
    handover: ITeachingHandover;
    targetAssignment: IFacultyAssignment;
    sourceAssignment: IFacultyAssignment;
  }> {
    // 1. Resolve college scope
    const collegeIdStr = requester.role === AppRole.SUPER_ADMIN && input.collegeId
      ? input.collegeId
      : requester.collegeId;

    if (!collegeIdStr || !mongoose.Types.ObjectId.isValid(collegeIdStr)) {
      throw ApiError.badRequest('Valid college identifier is required');
    }
    const collegeId = new mongoose.Types.ObjectId(collegeIdStr);

    if (!mongoose.Types.ObjectId.isValid(input.sourceAssignmentId)) {
      throw ApiError.badRequest('Invalid sourceAssignmentId format');
    }
    if (!mongoose.Types.ObjectId.isValid(input.successorFacultyId)) {
      throw ApiError.badRequest('Invalid successorFacultyId format');
    }

    // 2. Fetch and validate source assignment
    const sourceAssignment = await FacultyAssignment.findOne({
      _id: new mongoose.Types.ObjectId(input.sourceAssignmentId),
      collegeId,
    });

    if (!sourceAssignment) {
      throw ApiError.notFound('Source teaching assignment not found in this institution');
    }

    if (sourceAssignment.status !== 'active' || !sourceAssignment.isActive) {
      throw ApiError.badRequest('Cannot hand over an inactive or already completed teaching assignment');
    }

    // 3. Authorization check
    if (requester.role === AppRole.HOD) {
      if (
        !requester.departmentId ||
        requester.departmentId.toString() !== sourceAssignment.departmentId.toString()
      ) {
        throw ApiError.forbidden('HOD can only hand over teaching assignments within their department');
      }
    } else if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN].includes(requester.role)) {
      throw ApiError.forbidden('Only College Administrators or Department HODs can initiate teaching handovers');
    }

    // 4. Validate successor faculty
    const successorFaculty = await Faculty.findOne({
      _id: new mongoose.Types.ObjectId(input.successorFacultyId),
      collegeId,
    });

    if (!successorFaculty) {
      throw ApiError.notFound('Successor faculty profile not found in this institution');
    }

    if (successorFaculty._id.toString() === sourceAssignment.facultyId.toString()) {
      throw ApiError.badRequest('Successor faculty cannot be the current assigned faculty');
    }

    // 5. Prevent duplicate active assignment for successor
    const existingActive = await FacultyAssignment.findOne({
      collegeId,
      facultyId: successorFaculty._id,
      subjectId: sourceAssignment.subjectId,
      academicYearId: sourceAssignment.academicYearId,
      semesterId: sourceAssignment.semesterId,
      sectionId: sourceAssignment.sectionId || null,
      status: 'active',
    });

    if (existingActive) {
      throw ApiError.conflict('Successor faculty already has an active assignment for this course context');
    }

    // 6. Close source assignment
    sourceAssignment.status = 'ended';
    sourceAssignment.isActive = false;
    sourceAssignment.endedAt = new Date();
    await sourceAssignment.save();

    // 7. Create successor assignment
    const targetAssignment = await FacultyAssignment.create({
      collegeId: sourceAssignment.collegeId,
      departmentId: sourceAssignment.departmentId,
      facultyId: successorFaculty._id,
      facultyName: successorFaculty.name,
      courseId: sourceAssignment.courseId,
      semesterId: sourceAssignment.semesterId,
      sectionId: sourceAssignment.sectionId || null,
      subjectId: sourceAssignment.subjectId,
      academicYearId: sourceAssignment.academicYearId,
      cohort: sourceAssignment.cohort,
      academicStage: sourceAssignment.academicStage,
      roomId: sourceAssignment.roomId,
      maxStudents: sourceAssignment.maxStudents,
      assignmentType: sourceAssignment.assignmentType,
      assignedBy: requester.id,
      status: 'active',
      isActive: true,
      assignedAt: new Date(),
      handoverFromAssignmentId: sourceAssignment._id,
      handoverFromFacultyId: sourceAssignment.facultyId,
      handoverDate: new Date(),
    });

    // 8. Reassign pending work if requested
    let reassignedAssignmentsCount = 0;
    let reassignedSessionsCount = 0;

    if (input.reassignPendingWork) {
      // Reassign open / pending assignments
      const pendingAssignments = await Assignment.find({
        collegeId,
        facultyAssignmentId: sourceAssignment._id,
        status: { $in: [AssignmentStatus.DRAFT, AssignmentStatus.PUBLISHED] },
      });

      for (const asgn of pendingAssignments) {
        if (!asgn.originalFacultyId) {
          asgn.originalFacultyId = asgn.facultyId;
        }
        if (!asgn.originalFacultyAssignmentId) {
          asgn.originalFacultyAssignmentId = asgn.facultyAssignmentId;
        }
        if (successorFaculty.userId) {
          asgn.facultyId = successorFaculty.userId;
        }
        asgn.facultyAssignmentId = targetAssignment._id;
        asgn.facultyName = successorFaculty.name;
        await asgn.save();
        reassignedAssignmentsCount++;
      }

      // Reassign unsubmitted scheduled attendance sessions
      const pendingSessions = await AttendanceSession.find({
        collegeId,
        facultyAssignmentId: sourceAssignment._id,
        isSubmitted: false,
        isLocked: false,
      });

      for (const sess of pendingSessions) {
        if (!sess.originalFacultyId) {
          sess.originalFacultyId = sess.facultyId;
        }
        if (!sess.originalFacultyAssignmentId) {
          sess.originalFacultyAssignmentId = sess.facultyAssignmentId;
        }
        sess.facultyId = successorFaculty._id;
        sess.facultyAssignmentId = targetAssignment._id;
        await sess.save();
        reassignedSessionsCount++;
      }
    }

    // 9. Create TeachingHandover audit record
    const prevFacultyDoc = await Faculty.findById(sourceAssignment.facultyId);
    const handover = await TeachingHandover.create({
      collegeId: sourceAssignment.collegeId,
      departmentId: sourceAssignment.departmentId,
      subjectId: sourceAssignment.subjectId,
      sectionId: sourceAssignment.sectionId || null,
      academicYearId: sourceAssignment.academicYearId,
      semesterId: sourceAssignment.semesterId,
      courseId: sourceAssignment.courseId,
      sourceAssignmentId: sourceAssignment._id,
      targetAssignmentId: targetAssignment._id,
      previousFacultyId: sourceAssignment.facultyId,
      previousFacultyUserId: prevFacultyDoc?.userId || null,
      successorFacultyId: successorFaculty._id,
      successorFacultyUserId: successorFaculty.userId || null,
      status: 'COMPLETED',
      reassignedPendingWork: !!input.reassignPendingWork,
      reassignedCounts: {
        assignments: reassignedAssignmentsCount,
        sessions: reassignedSessionsCount,
      },
      handedOverBy: new mongoose.Types.ObjectId(requester.id),
      handedOverAt: new Date(),
      notes: input.notes || null,
    });

    // 10. Audit log
    await AuditLog.create({
      collegeId: collegeId.toString(),
      actorUserId: requester.id,
      action: 'FACULTY_TEACHING_HANDOVER',
      entityType: 'TeachingHandover',
      entityId: handover.id,
      previousValue: {
        sourceAssignmentId: sourceAssignment.id,
        previousFacultyId: sourceAssignment.facultyId.toString(),
      },
      newValue: {
        targetAssignmentId: targetAssignment.id,
        successorFacultyId: successorFaculty.id,
        reassignedAssignmentsCount,
        reassignedSessionsCount,
      },
    });

    return {
      handover,
      targetAssignment,
      sourceAssignment,
    };
  }

  /**
   * List teaching handovers for a college, filtered optionally by subject, department, or faculty.
   */
  static async listHandovers(
    requester: AuthenticatedUser,
    query: {
      collegeId?: string;
      departmentId?: string;
      subjectId?: string;
      facultyId?: string;
    }
  ): Promise<ITeachingHandover[]> {
    const collegeIdStr = requester.role === AppRole.SUPER_ADMIN && query.collegeId
      ? query.collegeId
      : requester.collegeId;

    if (!collegeIdStr || !mongoose.Types.ObjectId.isValid(collegeIdStr)) {
      throw ApiError.badRequest('Valid college identifier is required');
    }
    const collegeId = new mongoose.Types.ObjectId(collegeIdStr);

    const filter: Record<string, any> = { collegeId };

    if (query.departmentId && mongoose.Types.ObjectId.isValid(query.departmentId)) {
      filter.departmentId = new mongoose.Types.ObjectId(query.departmentId);
    }
    if (query.subjectId && mongoose.Types.ObjectId.isValid(query.subjectId)) {
      filter.subjectId = new mongoose.Types.ObjectId(query.subjectId);
    }
    if (query.facultyId && mongoose.Types.ObjectId.isValid(query.facultyId)) {
      const facId = new mongoose.Types.ObjectId(query.facultyId);
      filter.$or = [{ previousFacultyId: facId }, { successorFacultyId: facId }];
    }

    if (requester.role === AppRole.HOD && requester.departmentId) {
      filter.departmentId = new mongoose.Types.ObjectId(requester.departmentId);
    }

    return TeachingHandover.find(filter).sort({ handedOverAt: -1 }).limit(100);
  }
}
