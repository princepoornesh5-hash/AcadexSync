import mongoose from 'mongoose';
import { ApiError } from '../utils/apiError';
import { AppRole } from '../constants/roles';
import {
  RequestStatus,
  RequestType,
  ALLOWED_REQUEST_TYPES_BY_ROLE,
  VALID_STATUS_TRANSITIONS,
} from '../constants/request.constants';
import { RequestModel, IRequest } from '../models/request.model';
import { Department } from '../models/department.model';
import { FacultyAssignment } from '../models/facultyAssignment.model';
import { Faculty } from '../models/faculty.model';
import { AttendanceSession } from '../models/attendanceSession.model';
import { Assignment } from '../models/assignment.model';
import { InternalAssessment } from '../models/internalAssessment.model';
import { PracticalSession } from '../models/practicalSession.model';
import { StudentEnrollment } from '../models/studentEnrollment.model';
import { requestEvents } from '../events/request.events';
import { AuthenticatedUser } from '../types/auth.types';

export interface CreateRequestInput {
  requestType: RequestType;
  title?: string;
  description: string;
  status?: RequestStatus.DRAFT | RequestStatus.SUBMITTED;
  relatedEntityType?: string;
  relatedEntityId?: string;
  academicContext?: {
    courseId?: string;
    academicYearId?: string;
    semesterId?: string;
    sectionId?: string;
    subjectId?: string;
    facultyAssignmentId?: string;
    courseName?: string;
    sectionName?: string;
    subjectName?: string;
  };
  details?: {
    startDate?: Date | string;
    endDate?: Date | string;
    date?: Date | string;
    resourceName?: string;
    requestedChange?: string;
    documentType?: string;
    reason?: string;
    metadata?: Record<string, unknown>;
  };
}

export interface RespondRequestInput {
  action: 'APPROVED' | 'REJECTED' | 'RESOLVED';
  message?: string | null;
}

export class RequestService {
  /**
   * Helper to format request type enum to readable string
   */
  private static formatRequestType(type: string): string {
    return type
      .replace(/_/g, ' ')
      .toLowerCase()
      .replace(/\b\w/g, (c) => c.toUpperCase());
  }

  /**
   * Resolves routing authority based on role, department, and academic context
   */
  private static async resolveTarget(
    user: AuthenticatedUser,
    input: CreateRequestInput
  ): Promise<{
    targetRole: AppRole;
    targetUserId?: string | null;
    targetName: string;
    departmentId?: string | null;
  }> {
    const collegeId = user.collegeId;
    if (!collegeId) {
      throw ApiError.badRequest("We couldn't find the responsible person for this request.");
    }

    let departmentId = user.departmentId || null;

    // Student Flow
    if (user.role === AppRole.STUDENT) {
      // 1. Attendance correction or Academic issue -> Route to Class Faculty if subject & section context is present
      if (
        (input.requestType === 'ATTENDANCE_CORRECTION' || input.requestType === 'ACADEMIC_ISSUE') &&
        input.academicContext?.sectionId &&
        input.academicContext?.subjectId &&
        mongoose.Types.ObjectId.isValid(input.academicContext.sectionId) &&
        mongoose.Types.ObjectId.isValid(input.academicContext.subjectId)
      ) {
        const assignment = await FacultyAssignment.findOne({
          collegeId: new mongoose.Types.ObjectId(collegeId),
          sectionId: new mongoose.Types.ObjectId(input.academicContext.sectionId),
          subjectId: new mongoose.Types.ObjectId(input.academicContext.subjectId),
          isActive: true,
        });

        if (assignment) {
          // Resolve faculty user ID if possible
          const facultyDoc = await Faculty.findById(assignment.facultyId);
          const facultyUserId = facultyDoc?.userId
            ? facultyDoc.userId.toString()
            : assignment.facultyId.toString();

          return {
            targetRole: AppRole.FACULTY,
            targetUserId: facultyUserId,
            targetName: assignment.facultyName || 'Class Faculty',
            departmentId: assignment.departmentId?.toString() || departmentId,
          };
        }
      }

      // 2. Department-level requests (Leave, Complaint, or fallback academic issues) -> HOD
      if (
        input.requestType === 'LEAVE' ||
        input.requestType === 'COMPLAINT_ISSUE' ||
        input.requestType === 'ATTENDANCE_CORRECTION' ||
        input.requestType === 'ACADEMIC_ISSUE'
      ) {
        if (departmentId && mongoose.Types.ObjectId.isValid(departmentId)) {
          const dept = await Department.findById(departmentId);
          if (dept && dept.hodId) {
            return {
              targetRole: AppRole.HOD,
              targetUserId: dept.hodId.toString(),
              targetName: `${dept.name} HOD`,
              departmentId,
            };
          }
        }
        // If department doesn't have an assigned HOD, route to College Admin
        return {
          targetRole: AppRole.COLLEGE_ADMIN,
          targetUserId: null,
          targetName: 'College Administration',
          departmentId,
        };
      }

      // 3. Document or General request -> College Admin
      return {
        targetRole: AppRole.COLLEGE_ADMIN,
        targetUserId: null,
        targetName: 'College Administration',
        departmentId,
      };
    }

    // Faculty Flow -> All Faculty requests route to HOD of their department
    if (user.role === AppRole.FACULTY) {
      if (departmentId && mongoose.Types.ObjectId.isValid(departmentId)) {
        const dept = await Department.findById(departmentId);
        if (dept && dept.hodId) {
          return {
            targetRole: AppRole.HOD,
            targetUserId: dept.hodId.toString(),
            targetName: `${dept.name} HOD`,
            departmentId,
          };
        }
      }
      // If HOD not found or department missing, route to College Admin
      return {
        targetRole: AppRole.COLLEGE_ADMIN,
        targetUserId: null,
        targetName: 'College Administration',
        departmentId,
      };
    }

    // HOD Flow -> All HOD requests route to College Admin / Principal
    if (user.role === AppRole.HOD) {
      return {
        targetRole: AppRole.COLLEGE_ADMIN,
        targetUserId: null,
        targetName: 'College Administration',
        departmentId,
      };
    }

    // College Admin Flow -> Route to Super Admin / College Principal
    if (user.role === AppRole.COLLEGE_ADMIN || user.role === AppRole.SUPER_ADMIN) {
      return {
        targetRole: AppRole.COLLEGE_ADMIN,
        targetUserId: null,
        targetName: 'College Administration',
        departmentId,
      };
    }

    throw ApiError.badRequest("We couldn't find the responsible person for this request.");
  }

  /**
   * Validates linked entity belongs to the same tenant and exists
   */
  private static async validateLinkedEntity(
    entityType: string,
    entityId: string,
    collegeId: string
  ): Promise<void> {
    if (!mongoose.Types.ObjectId.isValid(entityId)) {
      throw ApiError.badRequest('Invalid relatedEntityId provided.');
    }
    const objId = new mongoose.Types.ObjectId(entityId);

    switch (entityType.toUpperCase()) {
      case 'ATTENDANCE_SESSION':
      case 'ATTENDANCE': {
        const session = await AttendanceSession.findById(objId);
        if (!session || session.collegeId.toString() !== collegeId) {
          throw ApiError.badRequest('Referenced attendance session does not exist in your college.');
        }
        break;
      }
      case 'ASSIGNMENT': {
        const assignment = await Assignment.findById(objId);
        if (!assignment || assignment.collegeId.toString() !== collegeId) {
          throw ApiError.badRequest('Referenced assignment does not exist in your college.');
        }
        break;
      }
      case 'INTERNAL_ASSESSMENT':
      case 'ASSESSMENT': {
        const assessment = await InternalAssessment.findById(objId);
        if (!assessment || assessment.collegeId.toString() !== collegeId) {
          throw ApiError.badRequest('Referenced assessment does not exist in your college.');
        }
        break;
      }
      case 'PRACTICAL_SESSION':
      case 'PRACTICAL': {
        const practical = await PracticalSession.findById(objId);
        if (!practical || practical.collegeId.toString() !== collegeId) {
          throw ApiError.badRequest('Referenced practical session does not exist in your college.');
        }
        break;
      }
      case 'STUDENT_ENROLLMENT':
      case 'ENROLLMENT': {
        const enrollment = await StudentEnrollment.findById(objId);
        if (!enrollment || enrollment.collegeId.toString() !== collegeId) {
          throw ApiError.badRequest('Referenced enrollment does not exist in your college.');
        }
        break;
      }
      default:
        // Accept other custom entity types
        break;
    }
  }

  /**
   * Helper to verify responder permission on a request
   */
  private static verifyReviewerPermission(request: IRequest, user: AuthenticatedUser): void {
    if (
      user.role !== AppRole.SUPER_ADMIN &&
      request.collegeId.toString() !== user.collegeId?.toString()
    ) {
      throw ApiError.forbidden('You no longer have access to this request.');
    }

    if (request.requesterUserId.toString() === user.id.toString()) {
      throw ApiError.forbidden('Requesters cannot respond to or resolve their own request.');
    }

    const isSuperAdmin = user.role === AppRole.SUPER_ADMIN;
    const isCollegeAdmin = user.role === AppRole.COLLEGE_ADMIN;
    const isAssignedHOD =
      user.role === AppRole.HOD &&
      (request.targetUserId?.toString() === user.id.toString() ||
        (request.departmentId && request.departmentId.toString() === user.departmentId?.toString()) ||
        request.targetRole === AppRole.HOD);
    const isAssignedFaculty =
      user.role === AppRole.FACULTY &&
      (request.targetUserId?.toString() === user.id.toString() ||
        request.targetRole === AppRole.FACULTY);

    if (!isSuperAdmin && !isCollegeAdmin && !isAssignedHOD && !isAssignedFaculty) {
      throw ApiError.forbidden('You do not have permission to respond to this request.');
    }
  }

  /**
   * 1. CREATE REQUEST
   */
  static async createRequest(
    input: CreateRequestInput,
    user: AuthenticatedUser
  ): Promise<IRequest> {
    const allowedTypes = ALLOWED_REQUEST_TYPES_BY_ROLE[user.role] || [];
    if (!allowedTypes.includes(input.requestType)) {
      throw ApiError.forbidden(
        `Role "${user.role}" is not permitted to create request type "${input.requestType}".`
      );
    }

    const collegeId = user.collegeId;
    if (!collegeId) {
      throw ApiError.badRequest("We couldn't find the responsible person for this request.");
    }

    const initialStatus =
      input.status === RequestStatus.DRAFT ? RequestStatus.DRAFT : RequestStatus.SUBMITTED;

    // Validate linked entity if supplied
    if (input.relatedEntityType && input.relatedEntityId) {
      await this.validateLinkedEntity(input.relatedEntityType, input.relatedEntityId, collegeId);
    }

    if (initialStatus === RequestStatus.SUBMITTED) {
      // Prevent duplicate re-entrant submissions (same user, same type, within 30 seconds)
      const thirtySecondsAgo = new Date(Date.now() - 30 * 1000);
      const recentDuplicate = await RequestModel.findOne({
        collegeId: new mongoose.Types.ObjectId(collegeId),
        requesterUserId: user.id,
        requestType: input.requestType,
        status: { $in: [RequestStatus.SUBMITTED, RequestStatus.IN_REVIEW, RequestStatus.UNDER_REVIEW] },
        createdAt: { $gte: thirtySecondsAgo },
      });

      if (recentDuplicate) {
        throw ApiError.conflict(
          'A similar request was recently submitted and is currently being processed.'
        );
      }
    }

    // Resolve routing
    const target = await this.resolveTarget(user, input);

    const title = input.title?.trim() || `${this.formatRequestType(input.requestType)} Request`;
    const requestId = `REQ-${Date.now().toString().slice(-6)}-${Math.floor(1000 + Math.random() * 9000)}`;

    const initialHistory = [
      {
        status: initialStatus,
        changedBy: user.id,
        changedByName: user.name,
        note: initialStatus === RequestStatus.DRAFT ? 'Request draft saved' : 'Request submitted',
        timestamp: new Date(),
      },
    ];

    const newRequest = await RequestModel.create({
      requestId,
      collegeId: new mongoose.Types.ObjectId(collegeId),
      departmentId: target.departmentId && mongoose.Types.ObjectId.isValid(target.departmentId)
        ? new mongoose.Types.ObjectId(target.departmentId)
        : null,
      requesterUserId: user.id,
      requesterName: user.name,
      requesterRole: user.role,
      targetRole: target.targetRole,
      targetUserId: target.targetUserId || null,
      targetName: target.targetName,
      requestType: input.requestType,
      title,
      description: input.description.trim(),
      relatedEntityType: input.relatedEntityType || null,
      relatedEntityId: input.relatedEntityId || null,
      academicContext: input.academicContext || null,
      details: input.details || null,
      status: initialStatus,
      history: initialHistory,
    });

    if (initialStatus === RequestStatus.SUBMITTED) {
      requestEvents.emitCreated(newRequest);
    }
    return newRequest;
  }

  /**
   * 1b. SUBMIT DRAFT REQUEST
   */
  static async submitRequest(id: string, user: AuthenticatedUser): Promise<IRequest> {
    const query = mongoose.Types.ObjectId.isValid(id) ? { _id: id } : { requestId: id };
    const request = await RequestModel.findOne(query);
    if (!request) {
      throw ApiError.notFound('The requested record could not be found.');
    }

    if (request.requesterUserId.toString() !== user.id.toString()) {
      throw ApiError.forbidden('Only the requester can submit their draft request.');
    }

    if (request.status !== RequestStatus.DRAFT) {
      throw ApiError.badRequest(`Cannot submit a request that is in ${request.status} status.`);
    }

    const historyEntry = {
      status: RequestStatus.SUBMITTED,
      changedBy: user.id,
      changedByName: user.name,
      note: 'Request submitted',
      timestamp: new Date(),
    };

    const updated = await RequestModel.findOneAndUpdate(
      { _id: request._id, status: RequestStatus.DRAFT },
      {
        $set: { status: RequestStatus.SUBMITTED },
        $push: { history: historyEntry },
      },
      { new: true }
    );

    if (!updated) {
      throw ApiError.conflict('The request was concurrently modified. Please refresh.');
    }

    requestEvents.emitSubmitted(updated);
    return updated;
  }

  /**
   * 1c. CANCEL REQUEST (Requester or Admin)
   */
  static async cancelRequest(
    id: string,
    reason: string | undefined,
    user: AuthenticatedUser
  ): Promise<IRequest> {
    const query = mongoose.Types.ObjectId.isValid(id) ? { _id: id } : { requestId: id };
    const request = await RequestModel.findOne(query);
    if (!request) {
      throw ApiError.notFound('The requested record could not be found.');
    }

    const isRequester = request.requesterUserId.toString() === user.id.toString();
    const isAdmin = user.role === AppRole.COLLEGE_ADMIN || user.role === AppRole.SUPER_ADMIN;

    if (!isRequester && !isAdmin) {
      throw ApiError.forbidden('You do not have permission to cancel this request.');
    }

    const allowedCancelStatuses = [
      RequestStatus.DRAFT,
      RequestStatus.SUBMITTED,
      RequestStatus.RECEIVED,
      RequestStatus.IN_REVIEW,
      RequestStatus.UNDER_REVIEW,
    ];

    if (!allowedCancelStatuses.includes(request.status)) {
      throw ApiError.badRequest(`Cannot cancel a request that is already ${request.status}.`);
    }

    const historyEntry = {
      status: RequestStatus.CANCELLED,
      changedBy: user.id,
      changedByName: user.name,
      note: reason?.trim() || 'Request cancelled by requester',
      timestamp: new Date(),
    };

    const updated = await RequestModel.findOneAndUpdate(
      { _id: request._id, status: { $in: allowedCancelStatuses } },
      {
        $set: { status: RequestStatus.CANCELLED },
        $push: { history: historyEntry },
      },
      { new: true }
    );

    if (!updated) {
      throw ApiError.conflict('The request was concurrently modified or resolved. Please refresh.');
    }

    requestEvents.emitCancelled(updated);
    return updated;
  }

  /**
   * 1d. START REVIEW (Authorized Responder moves request to UNDER_REVIEW)
   */
  static async startReview(id: string, user: AuthenticatedUser): Promise<IRequest> {
    const query = mongoose.Types.ObjectId.isValid(id) ? { _id: id } : { requestId: id };
    const request = await RequestModel.findOne(query);
    if (!request) {
      throw ApiError.notFound('The requested record could not be found.');
    }

    this.verifyReviewerPermission(request, user);

    const validStatuses = [RequestStatus.SUBMITTED, RequestStatus.RECEIVED];
    if (!validStatuses.includes(request.status)) {
      if (request.status === RequestStatus.UNDER_REVIEW || request.status === RequestStatus.IN_REVIEW) {
        return request; // Idempotent
      }
      throw ApiError.badRequest(`Cannot move request from ${request.status} to UNDER_REVIEW.`);
    }

    const historyEntry = {
      status: RequestStatus.UNDER_REVIEW,
      changedBy: user.id,
      changedByName: user.name,
      note: 'Request taken under review by responsible authority',
      timestamp: new Date(),
    };

    const updated = await RequestModel.findOneAndUpdate(
      { _id: request._id, status: { $in: validStatuses } },
      {
        $set: { status: RequestStatus.UNDER_REVIEW },
        $push: { history: historyEntry },
      },
      { new: true }
    );

    if (!updated) {
      throw ApiError.conflict('The request was concurrently updated. Please refresh.');
    }

    requestEvents.emitStatusChanged(updated, request.status, RequestStatus.UNDER_REVIEW);
    return updated;
  }

  /**
   * 2. LIST MY REQUESTS (Requester View)
   */
  static async listMyRequests(
    query: { status?: RequestStatus; requestType?: string; page?: number; limit?: number },
    user: AuthenticatedUser
  ): Promise<{ items: IRequest[]; total: number; page: number; limit: number }> {
    const collegeId = user.collegeId;
    if (!collegeId && user.role !== AppRole.SUPER_ADMIN) {
      return { items: [], total: 0, page: 1, limit: 20 };
    }

    const filter: Record<string, unknown> = {
      requesterUserId: user.id,
    };

    if (collegeId) {
      filter.collegeId = new mongoose.Types.ObjectId(collegeId);
    }

    if (query.status) {
      filter.status = query.status;
    }
    if (query.requestType) {
      filter.requestType = query.requestType;
    }

    const page = query.page || 1;
    const limit = query.limit || 20;
    const skip = (page - 1) * limit;

    const [items, total] = await Promise.all([
      RequestModel.find(filter)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
      RequestModel.countDocuments(filter),
    ]);

    return { items, total, page, limit };
  }

  /**
   * 3. LIST INCOMING REQUESTS (Responsible Person View)
   */
  static async listIncomingRequests(
    query: { status?: RequestStatus; requestType?: string; page?: number; limit?: number },
    user: AuthenticatedUser
  ): Promise<{ items: IRequest[]; total: number; page: number; limit: number }> {
    // Students never receive incoming operational requests
    if (user.role === AppRole.STUDENT) {
      return { items: [], total: 0, page: 1, limit: 20 };
    }

    const collegeId = user.collegeId;
    if (!collegeId && user.role !== AppRole.SUPER_ADMIN) {
      return { items: [], total: 0, page: 1, limit: 20 };
    }

    const filter: Record<string, unknown> = {};
    if (collegeId) {
      filter.collegeId = new mongoose.Types.ObjectId(collegeId);
    }

    // Role-specific incoming scoping
    if (user.role === AppRole.FACULTY) {
      filter.targetRole = AppRole.FACULTY;
      // Faculty sees requests assigned to their userId or where targetUserId matches
      filter.$or = [
        { targetUserId: user.id },
        { targetUserId: null }, // unassigned faculty requests in same scope
      ];
    } else if (user.role === AppRole.HOD) {
      filter.targetRole = AppRole.HOD;
      const orConditions: Record<string, unknown>[] = [{ targetUserId: user.id }];
      if (user.departmentId && mongoose.Types.ObjectId.isValid(user.departmentId)) {
        orConditions.push({ departmentId: new mongoose.Types.ObjectId(user.departmentId) });
      }
      filter.$or = orConditions;
    } else if (user.role === AppRole.COLLEGE_ADMIN) {
      filter.targetRole = AppRole.COLLEGE_ADMIN;
    }

    if (query.status) {
      filter.status = query.status;
    }
    if (query.requestType) {
      filter.requestType = query.requestType;
    }

    const page = query.page || 1;
    const limit = query.limit || 20;
    const skip = (page - 1) * limit;

    const [items, total] = await Promise.all([
      RequestModel.find(filter)
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
      RequestModel.countDocuments(filter),
    ]);

    return { items, total, page, limit };
  }

  /**
   * 4. GET SUMMARY COUNTS (Dashboard integration)
   */
  static async getSummaryCounts(
    user: AuthenticatedUser
  ): Promise<{ myPendingCount: number; incomingCount: number }> {
    const collegeId = user.collegeId;
    const pendingStatuses = [
      RequestStatus.SUBMITTED,
      RequestStatus.RECEIVED,
      RequestStatus.IN_REVIEW,
      RequestStatus.UNDER_REVIEW,
    ];

    const myPendingFilter: Record<string, unknown> = {
      requesterUserId: user.id,
      status: { $in: pendingStatuses },
    };
    if (collegeId) {
      myPendingFilter.collegeId = new mongoose.Types.ObjectId(collegeId);
    }

    const myPendingCount = await RequestModel.countDocuments(myPendingFilter);

    let incomingCount = 0;
    if (user.role !== AppRole.STUDENT) {
      const incomingFilter: Record<string, unknown> = {
        status: { $in: pendingStatuses },
      };
      if (collegeId) {
        incomingFilter.collegeId = new mongoose.Types.ObjectId(collegeId);
      }

      if (user.role === AppRole.FACULTY) {
        incomingFilter.targetRole = AppRole.FACULTY;
        incomingFilter.$or = [{ targetUserId: user.id }, { targetUserId: null }];
      } else if (user.role === AppRole.HOD) {
        incomingFilter.targetRole = AppRole.HOD;
        const orConditions: Record<string, unknown>[] = [{ targetUserId: user.id }];
        if (user.departmentId && mongoose.Types.ObjectId.isValid(user.departmentId)) {
          orConditions.push({ departmentId: new mongoose.Types.ObjectId(user.departmentId) });
        }
        incomingFilter.$or = orConditions;
      } else if (user.role === AppRole.COLLEGE_ADMIN) {
        incomingFilter.targetRole = AppRole.COLLEGE_ADMIN;
      }

      incomingCount = await RequestModel.countDocuments(incomingFilter);
    }

    return { myPendingCount, incomingCount };
  }

  /**
   * 5. GET REQUEST BY ID (Authorization Enforced)
   */
  static async getRequestById(id: string, user: AuthenticatedUser): Promise<IRequest> {
    const query = mongoose.Types.ObjectId.isValid(id)
      ? { _id: id }
      : { requestId: id };

    const request = await RequestModel.findOne(query);
    if (!request) {
      throw ApiError.notFound('The requested record could not be found.');
    }

    // Tenant Check: User must belong to same college (unless Super Admin)
    if (
      user.role !== AppRole.SUPER_ADMIN &&
      request.collegeId.toString() !== user.collegeId?.toString()
    ) {
      throw ApiError.forbidden('You no longer have access to this request.');
    }

    // Visibility Check
    const isRequester = request.requesterUserId.toString() === user.id.toString();
    const isSuperAdmin = user.role === AppRole.SUPER_ADMIN;
    const isCollegeAdmin = user.role === AppRole.COLLEGE_ADMIN;
    const isAssignedHOD =
      user.role === AppRole.HOD &&
      (request.targetUserId?.toString() === user.id.toString() ||
        (request.departmentId && request.departmentId.toString() === user.departmentId?.toString()) ||
        request.targetRole === AppRole.HOD);
    const isAssignedFaculty =
      user.role === AppRole.FACULTY &&
      (request.targetUserId?.toString() === user.id.toString() ||
        request.targetRole === AppRole.FACULTY);

    if (!isRequester && !isSuperAdmin && !isCollegeAdmin && !isAssignedHOD && !isAssignedFaculty) {
      throw ApiError.forbidden('You no longer have access to this request.');
    }

    // Auto-mark RECEIVED when authorized responder views a SUBMITTED request
    if (
      !isRequester &&
      request.status === RequestStatus.SUBMITTED
    ) {
      request.status = RequestStatus.RECEIVED;
      request.history.push({
        status: RequestStatus.RECEIVED,
        changedBy: user.id,
        changedByName: user.name,
        note: 'Request received and opened by responsible authority',
        timestamp: new Date(),
      });
      await request.save();
      requestEvents.emitReceived(request);
    }

    return request;
  }

  /**
   * 6. RESPOND TO REQUEST (Approve, Reject, Resolve)
   */
  static async respondToRequest(
    id: string,
    input: RespondRequestInput,
    user: AuthenticatedUser
  ): Promise<IRequest> {
    const query = mongoose.Types.ObjectId.isValid(id)
      ? { _id: id }
      : { requestId: id };

    const request = await RequestModel.findOne(query);
    if (!request) {
      throw ApiError.notFound('The requested record could not be found.');
    }

    // Tenant Check
    if (
      user.role !== AppRole.SUPER_ADMIN &&
      request.collegeId.toString() !== user.collegeId?.toString()
    ) {
      throw ApiError.forbidden('You no longer have access to this request.');
    }

    // Requesters CANNOT approve/reject their own request
    if (request.requesterUserId.toString() === user.id.toString()) {
      throw ApiError.forbidden('Requesters cannot respond to or resolve their own request.');
    }

    // Verify authorized responder
    const isSuperAdmin = user.role === AppRole.SUPER_ADMIN;
    const isCollegeAdmin = user.role === AppRole.COLLEGE_ADMIN;
    const isAssignedHOD =
      user.role === AppRole.HOD &&
      (request.targetUserId?.toString() === user.id.toString() ||
        (request.departmentId && request.departmentId.toString() === user.departmentId?.toString()) ||
        request.targetRole === AppRole.HOD);
    const isAssignedFaculty =
      user.role === AppRole.FACULTY &&
      (request.targetUserId?.toString() === user.id.toString() ||
        request.targetRole === AppRole.FACULTY);

    if (!isSuperAdmin && !isCollegeAdmin && !isAssignedHOD && !isAssignedFaculty) {
      throw ApiError.forbidden('You do not have permission to respond to this request.');
    }

    // Integrity Check: Closed request cannot be mutated
    if (request.status === RequestStatus.CLOSED) {
      throw ApiError.conflict('This request has already been processed.');
    }

    // Transition validation
    const targetStatus = input.action as RequestStatus;
    const allowedTransitions = VALID_STATUS_TRANSITIONS[request.status] || [];
    if (!allowedTransitions.includes(targetStatus)) {
      throw ApiError.badRequest(
        `Invalid status transition from ${request.status} to ${targetStatus}.`
      );
    }

    // Rejection reason check: Meaningful reason (at least 5 characters) required
    if (targetStatus === RequestStatus.REJECTED) {
      if (!input.message || input.message.trim().length < 5) {
        throw ApiError.badRequest('A meaningful rejection reason (at least 5 characters) is required.');
      }
    }

    const defaultMessage =
      targetStatus === RequestStatus.APPROVED
        ? 'Request approved.'
        : targetStatus === RequestStatus.REJECTED
        ? 'Request rejected.'
        : 'Request resolved.';

    const responseMessage = input.message?.trim() || defaultMessage;

    const historyEntry = {
      status: targetStatus,
      changedBy: user.id,
      changedByName: user.name,
      note: responseMessage,
      timestamp: new Date(),
    };

    // Atomic update with status condition to protect against concurrent reviews
    const updated = await RequestModel.findOneAndUpdate(
      { _id: request._id, status: request.status },
      {
        $set: {
          status: targetStatus,
          respondedAt: new Date(),
          respondedBy: user.id,
          respondedByName: user.name,
          responseMessage,
        },
        $push: {
          history: historyEntry,
        },
      },
      { new: true }
    );

    if (!updated) {
      throw ApiError.conflict('The request was concurrently updated or resolved by another action. Please refresh.');
    }

    requestEvents.emitResponded(updated);
    return updated;
  }

  /**
   * 7. UPDATE STATUS (In Review, Close, etc.)
   */
  static async updateStatus(
    id: string,
    newStatus: RequestStatus,
    note: string | undefined | null,
    user: AuthenticatedUser
  ): Promise<IRequest> {
    const query = mongoose.Types.ObjectId.isValid(id)
      ? { _id: id }
      : { requestId: id };

    const request = await RequestModel.findOne(query);
    if (!request) {
      throw ApiError.notFound('The requested record could not be found.');
    }

    // Tenant check
    if (
      user.role !== AppRole.SUPER_ADMIN &&
      request.collegeId.toString() !== user.collegeId?.toString()
    ) {
      throw ApiError.forbidden('You no longer have access to this request.');
    }

    // If closing, both requester and authorized responder can close
    const isRequester = request.requesterUserId.toString() === user.id.toString();
    const isSuperAdmin = user.role === AppRole.SUPER_ADMIN;
    const isCollegeAdmin = user.role === AppRole.COLLEGE_ADMIN;
    const isAssignedHOD =
      user.role === AppRole.HOD &&
      (request.targetUserId?.toString() === user.id.toString() ||
        (request.departmentId && request.departmentId.toString() === user.departmentId?.toString()) ||
        request.targetRole === AppRole.HOD);
    const isAssignedFaculty =
      user.role === AppRole.FACULTY &&
      (request.targetUserId?.toString() === user.id.toString() ||
        request.targetRole === AppRole.FACULTY);

    const isResponder = isSuperAdmin || isCollegeAdmin || isAssignedHOD || isAssignedFaculty;

    if (newStatus === RequestStatus.CLOSED) {
      if (!isRequester && !isResponder) {
        throw ApiError.forbidden('You do not have permission to close this request.');
      }
    } else {
      // Any other transition requires authorized responder
      if (!isResponder) {
        throw ApiError.forbidden('You do not have permission to modify this request status.');
      }
    }

    // Closed requests cannot be mutated
    if (request.status === RequestStatus.CLOSED) {
      throw ApiError.conflict('This request has already been processed.');
    }

    // Validate transition
    const allowedTransitions = VALID_STATUS_TRANSITIONS[request.status] || [];
    if (!allowedTransitions.includes(newStatus)) {
      throw ApiError.badRequest(
        `Invalid status transition from ${request.status} to ${newStatus}.`
      );
    }

    const previousStatus = request.status;
    const historyEntry = {
      status: newStatus,
      changedBy: user.id,
      changedByName: user.name,
      note: note?.trim() || `Status updated to ${newStatus}`,
      timestamp: new Date(),
    };

    // Atomic update with status condition to protect against concurrent transitions
    const updated = await RequestModel.findOneAndUpdate(
      { _id: request._id, status: request.status },
      {
        $set: { status: newStatus },
        $push: { history: historyEntry },
      },
      { new: true }
    );

    if (!updated) {
      throw ApiError.conflict('The request was concurrently updated by another action. Please refresh.');
    }

    requestEvents.emitStatusChanged(updated, previousStatus, newStatus);
    return updated;
  }
}
