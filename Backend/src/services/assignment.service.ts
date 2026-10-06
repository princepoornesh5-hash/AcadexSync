import { EventEmitter } from 'events';
import { Types } from 'mongoose';
import {
  AssignmentEvent,
  AssignmentStatus,
  AssignmentType,
  FacultyReviewStatus,
  StudentTaskStatus,
} from '../constants/assignment.constants';
import {
  NotificationCategory,
  NotificationPriority,
  NotificationType,
} from '../constants/notification.constants';
import { ApiError } from '../utils/apiError';
import {
  Assignment,
  IAssignment,
  AssignmentSubmission,
  IAssignmentSubmission,
  FacultyAssignment,
  Student,
  StudentEnrollment,
  Subject,
} from '../models';
import { ISubmissionAttachment } from '../models/assignmentSubmission.model';
import { ImageKitService } from '../storage/imagekit.service';
import { NotificationService } from './notification.service';
import { TeachingAuthorizationService } from './teachingAuthorization.service';
import { logger } from '../utils/logger';
import { realtimeEventBus, AcadexEventType, RealtimeAction } from '../realtime';

export const assignmentEvents = new EventEmitter();

function parseDueDateTime(dueDate: string, dueTime: string): Date {
  try {
    let hours = 23;
    let minutes = 59;
    const timeTrimmed = dueTime.trim().toUpperCase();
    const isPm = timeTrimmed.includes('PM');
    const isAm = timeTrimmed.includes('AM');
    const cleanTime = timeTrimmed.replace(/AM|PM/g, '').trim();
    const parts = cleanTime.split(':');

    if (parts.length >= 2) {
      const h = parseInt(parts[0], 10);
      const m = parseInt(parts[1], 10);
      if (!isNaN(h) && !isNaN(m)) {
        let adjustedH = h;
        if (isPm && h < 12) adjustedH += 12;
        if (isAm && h === 12) adjustedH = 0;
        hours = adjustedH;
        minutes = m;
      }
    }

    const date = new Date(dueDate);
    if (isNaN(date.getTime())) {
      const now = new Date();
      now.setHours(hours, minutes, 0, 0);
      return now;
    }
    date.setHours(hours, minutes, 0, 0);
    return date;
  } catch {
    const fallback = new Date();
    fallback.setDate(fallback.getDate() + 7);
    return fallback;
  }
}

export class AssignmentService {
  /**
   * 1. Create Assignment (Draft or Published)
   */
  static async createAssignment(
    collegeId: string,
    user: { id: string; name?: string; role?: string; email?: string; departmentId?: string },
    data: {
      facultyAssignmentId: string;
      title: string;
      description: string;
      questions?: string[];
      assignmentType?: AssignmentType;
      dueDate: string;
      dueTime: string;
      maximumMarks: number;
      attachments?: Array<{ name: string; url: string; fileType?: string; fileSize?: number }>;
      status?: AssignmentStatus;
    }
  ): Promise<IAssignment> {
    if (data.maximumMarks <= 0) {
      throw ApiError.badRequest('Maximum marks must be greater than 0.');
    }

    if (!data.title || data.title.trim().length === 0) {
      throw ApiError.badRequest('Assignment title is required.');
    }

    // 1. Resolve and verify canonical teaching context
    const fa = await TeachingAuthorizationService.assertFacultyAssignmentAccess(
      collegeId,
      user,
      data.facultyAssignmentId,
      'this assignment'
    );

    // 2. Validate that teaching assignment is active
    if (!fa.isActive || fa.status !== 'active') {
      throw ApiError.badRequest('This teaching assignment is no longer active.');
    }

    const dueDateTime = parseDueDateTime(data.dueDate, data.dueTime);
    const status = data.status || AssignmentStatus.DRAFT;

    if (status === AssignmentStatus.PUBLISHED && dueDateTime <= new Date()) {
      throw ApiError.badRequest('Cannot publish an assignment with a due date in the past.');
    }

    // 3. Duplicate protection (deterministic 5-second window)
    const existingRecent = await Assignment.findOne({
      collegeId: new Types.ObjectId(collegeId),
      facultyAssignmentId: fa._id,
      title: data.title.trim(),
      dueDate: data.dueDate,
      createdAt: { $gte: new Date(Date.now() - 5000) },
    });
    if (existingRecent) {
      return existingRecent;
    }

    const publishedAt = status === AssignmentStatus.PUBLISHED ? new Date() : null;

    // 4. Derive academic context strictly from canonical FacultyAssignment
    const assignment = await Assignment.create({
      collegeId: new Types.ObjectId(collegeId),
      departmentId: fa.departmentId,
      courseId: fa.courseId,
      academicYearId: fa.academicYearId,
      semesterId: fa.semesterId,
      sectionId: fa.sectionId || null,
      subjectId: fa.subjectId,
      facultyId: new Types.ObjectId(user.id),
      facultyAssignmentId: fa._id,
      facultyName: user.name || fa.facultyName || 'Faculty',
      title: data.title.trim(),
      description: data.description.trim(),
      questions: data.questions || [],
      assignmentType: data.assignmentType || AssignmentType.HOMEWORK,
      dueDate: data.dueDate,
      dueTime: data.dueTime,
      dueDateTime,
      maximumMarks: Math.floor(data.maximumMarks),
      attachments: data.attachments || [],
      status,
      publishedAt,
    });

    if (status === AssignmentStatus.PUBLISHED) {
      this.emitAssignmentPublished(assignment);
    } else {
      this.emitAssignmentCreated(assignment);
    }

    return assignment;
  }

  /**
   * 2. Update an Assignment (Draft or Published)
   */
  static async updateAssignment(
    collegeId: string,
    user: { id: string; role?: string; departmentId?: string },
    assignmentId: string,
    updateData: {
      title?: string;
      description?: string;
      questions?: string[];
      assignmentType?: AssignmentType;
      dueDate?: string;
      dueTime?: string;
      maximumMarks?: number;
      attachments?: Array<{ name: string; url: string; fileType?: string; fileSize?: number }>;
    }
  ): Promise<IAssignment> {
    const assignment = await Assignment.findOne({
      _id: new Types.ObjectId(assignmentId),
      collegeId: new Types.ObjectId(collegeId),
    });

    if (!assignment) {
      throw ApiError.notFound('Assignment not found.');
    }

    await TeachingAuthorizationService.assertAssignmentAccess(collegeId, user, assignment);

    if (assignment.status === AssignmentStatus.CLOSED) {
      throw ApiError.badRequest('Cannot edit a closed assignment.');
    }
    if (assignment.status === AssignmentStatus.ARCHIVED) {
      throw ApiError.badRequest('Cannot edit an archived assignment.');
    }

    if (updateData.maximumMarks !== undefined) {
      if (updateData.maximumMarks <= 0) {
        throw ApiError.badRequest('Maximum marks must be greater than 0.');
      }
      assignment.maximumMarks = Math.floor(updateData.maximumMarks);
    }

    if (updateData.title !== undefined) {
      if (updateData.title.trim().length === 0) {
        throw ApiError.badRequest('Assignment title cannot be empty.');
      }
      assignment.title = updateData.title.trim();
    }

    if (updateData.description !== undefined) {
      assignment.description = updateData.description.trim();
    }

    if (updateData.questions !== undefined) {
      assignment.questions = updateData.questions;
    }

    if (updateData.assignmentType !== undefined) {
      assignment.assignmentType = updateData.assignmentType;
    }

    if (updateData.attachments !== undefined) {
      assignment.attachments = updateData.attachments;
    }

    if (updateData.dueDate || updateData.dueTime) {
      if (updateData.dueDate) assignment.dueDate = updateData.dueDate;
      if (updateData.dueTime) assignment.dueTime = updateData.dueTime;
      assignment.dueDateTime = parseDueDateTime(assignment.dueDate, assignment.dueTime);
    }

    await assignment.save();

    this.emitAssignmentUpdated(assignment);
    return assignment;
  }

  /**
   * 3. Publish a Draft Assignment
   */
  static async publishAssignment(
    collegeId: string,
    user: { id: string; role?: string; departmentId?: string },
    assignmentId: string
  ): Promise<IAssignment> {
    const assignment = await Assignment.findOne({
      _id: new Types.ObjectId(assignmentId),
      collegeId: new Types.ObjectId(collegeId),
    });

    if (!assignment) {
      throw ApiError.notFound('Assignment not found.');
    }

    await TeachingAuthorizationService.assertAssignmentAccess(collegeId, user, assignment);

    if (assignment.status === AssignmentStatus.PUBLISHED) {
      return assignment; // Idempotent
    }
    if (assignment.status === AssignmentStatus.CLOSED) {
      throw ApiError.badRequest('Cannot publish a closed assignment.');
    }
    if (assignment.status === AssignmentStatus.ARCHIVED) {
      throw ApiError.badRequest('Cannot publish an archived assignment.');
    }

    // Revalidate that associated FacultyAssignment is still active
    if (assignment.facultyAssignmentId) {
      const fa = await FacultyAssignment.findById(assignment.facultyAssignmentId);
      if (!fa || !fa.isActive || fa.status !== 'active') {
        throw ApiError.badRequest('The associated teaching context is no longer active.');
      }
    }

    if (!assignment.title || assignment.title.trim().length === 0) {
      throw ApiError.badRequest('Assignment title cannot be empty.');
    }

    if (assignment.dueDateTime <= new Date()) {
      throw ApiError.badRequest('Cannot publish an assignment with a due date in the past.');
    }

    assignment.status = AssignmentStatus.PUBLISHED;
    assignment.publishedAt = new Date();
    await assignment.save();

    this.emitAssignmentPublished(assignment);
    return assignment;
  }

  /**
   * 4. Close an Assignment
   */
  static async closeAssignment(
    collegeId: string,
    user: { id: string; role?: string; departmentId?: string },
    assignmentId: string
  ): Promise<IAssignment> {
    const assignment = await Assignment.findOne({
      _id: new Types.ObjectId(assignmentId),
      collegeId: new Types.ObjectId(collegeId),
    });

    if (!assignment) {
      throw ApiError.notFound('Assignment not found.');
    }

    await TeachingAuthorizationService.assertAssignmentAccess(collegeId, user, assignment);

    if (assignment.status === AssignmentStatus.ARCHIVED) {
      throw ApiError.badRequest('Cannot close an archived assignment.');
    }

    assignment.status = AssignmentStatus.CLOSED;
    assignment.closedAt = new Date();
    await assignment.save();

    this.emitAssignmentClosed(assignment);
    return assignment;
  }

  /**
   * 5. Archive an Assignment
   */
  static async archiveAssignment(
    collegeId: string,
    user: { id: string; role?: string; departmentId?: string },
    assignmentId: string
  ): Promise<IAssignment> {
    const assignment = await Assignment.findOne({
      _id: new Types.ObjectId(assignmentId),
      collegeId: new Types.ObjectId(collegeId),
    });

    if (!assignment) {
      throw ApiError.notFound('Assignment not found.');
    }

    await TeachingAuthorizationService.assertAssignmentAccess(collegeId, user, assignment);

    assignment.status = AssignmentStatus.ARCHIVED;
    await assignment.save();

    this.emitAssignmentUpdated(assignment, 'ARCHIVED');
    return assignment;
  }

  /**
   * 6. Safe Delete Assignment (Drafts with no submissions only)
   */
  static async deleteAssignment(
    collegeId: string,
    user: { id: string; role?: string; departmentId?: string },
    assignmentId: string
  ): Promise<{ success: boolean; message: string }> {
    const assignment = await Assignment.findOne({
      _id: new Types.ObjectId(assignmentId),
      collegeId: new Types.ObjectId(collegeId),
    });

    if (!assignment) {
      throw ApiError.notFound('Assignment not found.');
    }

    await TeachingAuthorizationService.assertAssignmentAccess(collegeId, user, assignment);

    const submissionCount = await AssignmentSubmission.countDocuments({
      assignmentId: assignment._id,
    });

    if (submissionCount > 0 || assignment.status === AssignmentStatus.PUBLISHED || assignment.status === AssignmentStatus.CLOSED) {
      throw ApiError.badRequest(
        'Cannot delete an assignment that is published or has student submission history. Please archive it instead.'
      );
    }

    await Assignment.deleteOne({ _id: assignment._id });

    this.emitAssignmentUpdated(assignment, 'DELETED');
    return { success: true, message: 'Draft assignment deleted successfully.' };
  }

  /**
   * 7. Get Assignments for Faculty / Admin
   */
  static async getFacultyAssignments(
    collegeId: string,
    user: { id: string; role?: string; departmentId?: string },
    query?: { status?: string; sectionId?: string; subjectId?: string }
  ): Promise<any[]> {
    const filter: Record<string, any> = {
      collegeId: new Types.ObjectId(collegeId),
    };

    const roleUpper = user.role?.toUpperCase();
    if (roleUpper === 'FACULTY') {
      filter.facultyId = new Types.ObjectId(user.id);
    } else if (roleUpper === 'HOD' && user.departmentId) {
      filter.departmentId = new Types.ObjectId(user.departmentId);
    }

    if (query?.status) {
      filter.status = query.status;
    } else {
      filter.status = { $ne: AssignmentStatus.ARCHIVED };
    }

    if (query?.sectionId && Types.ObjectId.isValid(query.sectionId)) {
      filter.sectionId = new Types.ObjectId(query.sectionId);
    }
    if (query?.subjectId && Types.ObjectId.isValid(query.subjectId)) {
      filter.subjectId = new Types.ObjectId(query.subjectId);
    }

    const assignments = await Assignment.find(filter)
      .populate('subjectId', 'name code')
      .populate('sectionId', 'name')
      .populate('semesterId', 'name number')
      .sort({ createdAt: -1 });

    const results = await Promise.all(
      assignments.map(async (asgn) => {
        const enrollmentQuery: any = {
          collegeId: asgn.collegeId,
          semesterId: asgn.semesterId,
          courseId: asgn.courseId,
          status: 'active',
        };
        if (asgn.sectionId) {
          enrollmentQuery.sectionId = asgn.sectionId;
        }

        const totalEnrolled = await StudentEnrollment.countDocuments(enrollmentQuery);
        const completedCount = await AssignmentSubmission.countDocuments({
          assignmentId: asgn._id,
          status: StudentTaskStatus.COMPLETED,
        });

        const json: any = asgn.toJSON();
        json.totalStudents = totalEnrolled;
        json.completedCount = completedCount;
        json.pendingCount = Math.max(0, totalEnrolled - completedCount);
        return json;
      })
    );

    return results;
  }

  /**
   * 8. Get Assignments for Enrolled Student (Section-Aware & Section-Disabled)
   */
  static async getStudentAssignments(
    collegeId: string,
    studentUser: { id: string }
  ): Promise<any[]> {
    // 1. Resolve student profile
    let student = await Student.findOne({
      collegeId: new Types.ObjectId(collegeId),
      userId: new Types.ObjectId(studentUser.id),
    });

    if (!student && Types.ObjectId.isValid(studentUser.id)) {
      student = await Student.findById(studentUser.id);
    }

    if (!student) {
      return [];
    }

    // 2. Resolve active student enrollments
    const enrollments = await StudentEnrollment.find({
      collegeId: new Types.ObjectId(collegeId),
      studentId: student._id,
      status: 'active',
    });

    if (enrollments.length === 0) {
      return [];
    }

    // 3. Build section-aware and section-disabled matching criteria
    const audienceConditions = enrollments.map((enr) => {
      const cond: any = {
        semesterId: enr.semesterId,
        courseId: enr.courseId,
      };
      if (enr.sectionId) {
        cond.$or = [
          { sectionId: enr.sectionId },
          { sectionId: null },
          { sectionId: { $exists: false } },
        ];
      } else {
        cond.$or = [
          { sectionId: null },
          { sectionId: { $exists: false } },
        ];
      }
      return cond;
    });

    // 4. Find published assignments matching audience
    const assignments = await Assignment.find({
      collegeId: new Types.ObjectId(collegeId),
      status: AssignmentStatus.PUBLISHED,
      $or: audienceConditions,
    })
      .populate('subjectId', 'name code')
      .populate('sectionId', 'name')
      .sort({ dueDateTime: 1 });

    const assignmentIds = assignments.map((a) => a._id);

    // 5. Find student's submissions
    const submissions = await AssignmentSubmission.find({
      assignmentId: { $in: assignmentIds },
      studentId: student._id,
    });
    const subMap = new Map<string, IAssignmentSubmission>();
    submissions.forEach((s) => subMap.set(s.assignmentId.toString(), s));

    const now = new Date();

    return assignments.map((asgn) => {
      const sub = subMap.get(asgn._id.toString());
      const json: any = asgn.toJSON();

      if (sub && sub.status === StudentTaskStatus.COMPLETED) {
        json.studentStatus = StudentTaskStatus.COMPLETED;
        json.completedAt = sub.completedAt;
        json.isLate = sub.isLate;
        json.reviewStatus = sub.reviewStatus;
        json.marks = sub.marks;
      } else {
        const isOverdue = asgn.dueDateTime < now;
        json.studentStatus = isOverdue ? StudentTaskStatus.OVERDUE : StudentTaskStatus.PENDING;
        json.completedAt = null;
        json.isLate = false;
        json.reviewStatus = FacultyReviewStatus.NOT_REVIEWED;
        json.marks = null;
      }

      return json;
    });
  }

  /**
   * 9. Get Single Assignment Detail (Scoped & Authorized)
   */
  static async getAssignmentDetail(
    collegeId: string,
    user: { id: string; role?: string; departmentId?: string },
    assignmentId: string
  ): Promise<any> {
    const assignment = await Assignment.findOne({
      _id: new Types.ObjectId(assignmentId),
      collegeId: new Types.ObjectId(collegeId),
    })
      .populate('subjectId', 'name code')
      .populate('sectionId', 'name')
      .populate('departmentId', 'name')
      .populate('semesterId', 'name number');

    if (!assignment) {
      throw ApiError.notFound('Assignment not found.');
    }

    const roleUpper = user.role?.toUpperCase();

    if (roleUpper === 'STUDENT') {
      if (assignment.status !== AssignmentStatus.PUBLISHED) {
        throw ApiError.forbidden('Assignment is not accessible.');
      }

      let student = await Student.findOne({
        collegeId: new Types.ObjectId(collegeId),
        userId: new Types.ObjectId(user.id),
      });
      if (!student && Types.ObjectId.isValid(user.id)) {
        student = await Student.findById(user.id);
      }

      if (!student) {
        throw ApiError.forbidden('Student profile not found.');
      }

      // Verify active enrollment eligibility
      const enrollmentQuery: any = {
        collegeId: new Types.ObjectId(collegeId),
        studentId: student._id,
        semesterId: assignment.semesterId,
        courseId: assignment.courseId,
        status: 'active',
      };
      if (assignment.sectionId) {
        enrollmentQuery.sectionId = assignment.sectionId;
      }

      const isEnrolled = await StudentEnrollment.exists(enrollmentQuery);
      if (!isEnrolled) {
        throw ApiError.forbidden('You are not eligible to view this assignment.');
      }

      const json: any = assignment.toJSON();
      const sub = await AssignmentSubmission.findOne({
        assignmentId: assignment._id,
        studentId: student._id,
      });

      if (sub && sub.status === StudentTaskStatus.COMPLETED) {
        json.studentStatus = StudentTaskStatus.COMPLETED;
        json.completedAt = sub.completedAt;
        json.isLate = sub.isLate;
        json.reviewStatus = sub.reviewStatus;
        json.marks = sub.marks;
      } else {
        const isOverdue = assignment.dueDateTime < new Date();
        json.studentStatus = isOverdue ? StudentTaskStatus.OVERDUE : StudentTaskStatus.PENDING;
        json.completedAt = null;
        json.isLate = false;
        json.reviewStatus = FacultyReviewStatus.NOT_REVIEWED;
        json.marks = null;
      }

      return json;
    }

    // Role is Faculty / HOD / Admin
    if (roleUpper === 'HOD' && user.departmentId) {
      if (assignment.departmentId.toString() !== user.departmentId.toString()) {
        throw ApiError.forbidden('You are not authorized to view assignments outside your department.');
      }
    } else if (roleUpper === 'FACULTY') {
      await TeachingAuthorizationService.assertAssignmentAccess(collegeId, user, assignment);
    }

    return assignment.toJSON();
  }

  /**
   * Helper: Resolve student record from authenticated user identity
   */
  private static async resolveStudentForUser(
    collegeId: string,
    studentUser: { id: string; name?: string }
  ): Promise<any> {
    let student = await Student.findOne({
      collegeId: new Types.ObjectId(collegeId),
      userId: new Types.ObjectId(studentUser.id),
    });
    if (!student && Types.ObjectId.isValid(studentUser.id)) {
      student = await Student.findById(studentUser.id);
    }
    if (!student) {
      throw ApiError.forbidden('Student record not found.');
    }
    return student;
  }

  /**
   * Helper: Assert active student enrollment in assignment academic context
   */
  private static async assertStudentAudienceEligibility(
    assignment: IAssignment,
    student: any
  ): Promise<void> {
    const enrollmentQuery: any = {
      collegeId: assignment.collegeId,
      studentId: student._id,
      semesterId: assignment.semesterId,
      courseId: assignment.courseId,
      status: 'active',
    };
    if (assignment.sectionId) {
      enrollmentQuery.sectionId = assignment.sectionId;
    }

    const enrollment = await StudentEnrollment.findOne(enrollmentQuery);
    if (!enrollment) {
      if (assignment.sectionId) {
        throw ApiError.forbidden('You are not enrolled in the section for this assignment.');
      }
      throw ApiError.forbidden('You are not enrolled in the academic context for this assignment.');
    }
  }

  /**
   * 10. Student marks assignment as Done (Legacy & quick submit)
   */
  static async completeAssignment(
    collegeId: string,
    studentUser: { id: string; name?: string },
    assignmentId: string
  ): Promise<IAssignmentSubmission> {
    const assignment = await Assignment.findOne({
      _id: new Types.ObjectId(assignmentId),
      collegeId: new Types.ObjectId(collegeId),
    });

    if (!assignment) {
      throw ApiError.notFound('Assignment not found.');
    }

    if (assignment.status !== AssignmentStatus.PUBLISHED) {
      throw ApiError.badRequest('This assignment is not currently open for completion.');
    }

    const student = await this.resolveStudentForUser(collegeId, studentUser);
    await this.assertStudentAudienceEligibility(assignment, student);

    const now = new Date();
    const isLate = assignment.dueDateTime < now;

    // Idempotent upsert submission
    let submission = await AssignmentSubmission.findOne({
      assignmentId: assignment._id,
      studentId: student._id,
    });

    if (submission && (submission.status === StudentTaskStatus.COMPLETED || submission.status === StudentTaskStatus.SUBMITTED)) {
      return submission; // Already marked done / submitted
    }

    if (!submission) {
      submission = new AssignmentSubmission({
        collegeId: new Types.ObjectId(collegeId),
        assignmentId: assignment._id,
        studentId: student._id,
        studentUserId: new Types.ObjectId(studentUser.id),
        studentName: student.name || studentUser.name || 'Student',
        rollNumber: student.rollNumber || null,
        status: StudentTaskStatus.COMPLETED,
        completedAt: now,
        submittedAt: now,
        isLate,
        version: 1,
        reviewStatus: FacultyReviewStatus.NOT_REVIEWED,
        marks: null,
      });
    } else {
      submission.status = StudentTaskStatus.COMPLETED;
      submission.completedAt = now;
      submission.submittedAt = now;
      submission.isLate = isLate;
    }

    await submission.save();

    this.emitSubmissionSubmitted(submission, assignment);

    assignmentEvents.emit(AssignmentEvent.ASSIGNMENT_COMPLETED, {
      assignmentId: assignment._id.toString(),
      studentId: student._id.toString(),
      studentUserId: studentUser.id,
    });

    return submission;
  }

  /**
   * 10a. Request secure upload authorization for submission file
   */
  static async getSubmissionUploadAuth(
    collegeId: string,
    user: { id: string; name?: string; role?: string },
    assignmentId: string,
    data: { fileName: string; mimeType: string; fileSize?: number }
  ): Promise<any> {
    const assignment = await Assignment.findOne({
      _id: new Types.ObjectId(assignmentId),
      collegeId: new Types.ObjectId(collegeId),
    });
    if (!assignment) {
      throw ApiError.notFound('Assignment not found.');
    }
    if (assignment.status !== AssignmentStatus.PUBLISHED) {
      throw ApiError.badRequest('Submissions are only accepted for published assignments.');
    }

    const student = await this.resolveStudentForUser(collegeId, user);
    await this.assertStudentAudienceEligibility(assignment, student);

    const validation = ImageKitService.validateMimeAndExtension(data.mimeType, data.fileName);
    if (!validation.valid) {
      throw ApiError.badRequest(validation.error || 'Invalid file type or extension.');
    }

    const maxSizeBytes = 25 * 1024 * 1024;
    if (data.fileSize && data.fileSize > maxSizeBytes) {
      throw ApiError.badRequest('File size cannot exceed 25MB.');
    }

    const folder = ImageKitService.buildAssignmentSubmissionFolder(
      collegeId,
      assignment._id.toString(),
      student._id.toString()
    );

    const authParams = ImageKitService.getAuthenticationParameters(
      folder,
      data.fileName,
      maxSizeBytes
    );

    return {
      ...authParams,
      storageKey: `${folder}/${data.fileName}`,
    };
  }

  /**
   * 10b. Fetch student's own submission
   */
  static async getStudentSubmission(
    collegeId: string,
    user: { id: string; name?: string },
    assignmentId: string
  ): Promise<IAssignmentSubmission | null> {
    const assignment = await Assignment.findOne({
      _id: new Types.ObjectId(assignmentId),
      collegeId: new Types.ObjectId(collegeId),
    });
    if (!assignment) {
      throw ApiError.notFound('Assignment not found.');
    }

    const student = await this.resolveStudentForUser(collegeId, user);
    await this.assertStudentAudienceEligibility(assignment, student);

    const submission = await AssignmentSubmission.findOne({
      assignmentId: assignment._id,
      studentId: student._id,
      collegeId: new Types.ObjectId(collegeId),
    });

    return submission;
  }

  /**
   * 10c. Save draft submission
   */
  static async saveDraftSubmission(
    collegeId: string,
    user: { id: string; name?: string },
    assignmentId: string,
    data: { textResponse?: string; attachments?: ISubmissionAttachment[] }
  ): Promise<IAssignmentSubmission> {
    const assignment = await Assignment.findOne({
      _id: new Types.ObjectId(assignmentId),
      collegeId: new Types.ObjectId(collegeId),
    });
    if (!assignment) {
      throw ApiError.notFound('Assignment not found.');
    }
    if (assignment.status !== AssignmentStatus.PUBLISHED) {
      throw ApiError.badRequest('Drafts can only be saved for published assignments.');
    }

    const student = await this.resolveStudentForUser(collegeId, user);
    await this.assertStudentAudienceEligibility(assignment, student);

    let submission = await AssignmentSubmission.findOne({
      assignmentId: assignment._id,
      studentId: student._id,
      collegeId: new Types.ObjectId(collegeId),
    });

    if (submission && (submission.status === StudentTaskStatus.COMPLETED || submission.status === StudentTaskStatus.SUBMITTED)) {
      throw ApiError.badRequest('This submission has already been finalized. Use submit to submit a revision.');
    }

    if (!submission) {
      submission = new AssignmentSubmission({
        collegeId: new Types.ObjectId(collegeId),
        assignmentId: assignment._id,
        studentId: student._id,
        studentUserId: new Types.ObjectId(user.id),
        studentName: student.name || user.name || 'Student',
        rollNumber: student.rollNumber || null,
        status: StudentTaskStatus.DRAFT,
        textResponse: data.textResponse || null,
        attachments: data.attachments || [],
        version: 1,
        isLate: false,
        reviewStatus: FacultyReviewStatus.NOT_REVIEWED,
      });
    } else {
      submission.textResponse = data.textResponse || null;
      submission.attachments = data.attachments || [];
      submission.status = StudentTaskStatus.DRAFT;
    }

    await submission.save();
    return submission;
  }

  /**
   * 10d. Finalize student submission (supports first submit & resubmissions)
   */
  static async submitAssignment(
    collegeId: string,
    user: { id: string; name?: string },
    assignmentId: string,
    data: { textResponse?: string; attachments?: ISubmissionAttachment[] }
  ): Promise<IAssignmentSubmission> {
    const assignment = await Assignment.findOne({
      _id: new Types.ObjectId(assignmentId),
      collegeId: new Types.ObjectId(collegeId),
    });
    if (!assignment) {
      throw ApiError.notFound('Assignment not found.');
    }
    if (assignment.status === AssignmentStatus.CLOSED) {
      throw ApiError.badRequest('Submissions are closed for this assignment.');
    }
    if (assignment.status === AssignmentStatus.ARCHIVED) {
      throw ApiError.badRequest('Cannot submit to an archived assignment.');
    }
    if (assignment.status !== AssignmentStatus.PUBLISHED) {
      throw ApiError.badRequest('This assignment is not currently open for submission.');
    }

    const student = await this.resolveStudentForUser(collegeId, user);
    await this.assertStudentAudienceEligibility(assignment, student);

    const now = new Date();
    const isLate = assignment.dueDateTime < now;

    let submission = await AssignmentSubmission.findOne({
      assignmentId: assignment._id,
      studentId: student._id,
      collegeId: new Types.ObjectId(collegeId),
    });

    if (
      submission &&
      (submission.status === StudentTaskStatus.COMPLETED ||
        submission.status === StudentTaskStatus.SUBMITTED ||
        submission.status === StudentTaskStatus.RESUBMITTED)
    ) {
      // Resubmission: preserve historical version
      submission.submissionHistory.push({
        version: submission.version || 1,
        textResponse: submission.textResponse,
        attachments: submission.attachments,
        submittedAt: submission.submittedAt || submission.completedAt || now,
        isLate: submission.isLate,
        marks: submission.marks,
        feedback: submission.feedback,
        reviewStatus: submission.reviewStatus,
        reviewedAt: submission.reviewedAt,
        reviewedBy: submission.reviewedBy,
      });

      submission.version = (submission.version || 1) + 1;
      submission.textResponse = data.textResponse || submission.textResponse || null;
      submission.attachments = data.attachments || submission.attachments || [];
      submission.submittedAt = now;
      submission.completedAt = now;
      submission.isLate = isLate;
      submission.status = StudentTaskStatus.RESUBMITTED;
      submission.reviewStatus = FacultyReviewStatus.NOT_REVIEWED;
      submission.marks = null;
      submission.feedback = null;
      submission.reviewedAt = null;
      submission.reviewedBy = null;
    } else if (!submission) {
      submission = new AssignmentSubmission({
        collegeId: new Types.ObjectId(collegeId),
        assignmentId: assignment._id,
        studentId: student._id,
        studentUserId: new Types.ObjectId(user.id),
        studentName: student.name || user.name || 'Student',
        rollNumber: student.rollNumber || null,
        status: StudentTaskStatus.SUBMITTED,
        textResponse: data.textResponse || null,
        attachments: data.attachments || [],
        submittedAt: now,
        completedAt: now,
        isLate,
        version: 1,
        reviewStatus: FacultyReviewStatus.NOT_REVIEWED,
        marks: null,
      });
    } else {
      // Transition from DRAFT to SUBMITTED
      submission.status = StudentTaskStatus.SUBMITTED;
      submission.textResponse = data.textResponse || submission.textResponse || null;
      submission.attachments = data.attachments || submission.attachments || [];
      submission.submittedAt = now;
      submission.completedAt = now;
      submission.isLate = isLate;
    }

    await submission.save();

    // Persistence-First Realtime Event
    this.emitSubmissionSubmitted(submission, assignment);

    assignmentEvents.emit(AssignmentEvent.SUBMISSION_SUBMITTED, {
      assignmentId: assignment._id.toString(),
      submissionId: submission._id.toString(),
      studentId: student._id.toString(),
      facultyId: assignment.facultyId.toString(),
    });

    // Notify faculty asynchronously
    setImmediate(async () => {
      try {
        const idempotencyKey = `sub_rec_${submission._id}_v${submission.version}`;
        await NotificationService.createNotification({
          collegeId: assignment.collegeId.toString(),
          recipientUserId: assignment.facultyId.toString(),
          notificationType: NotificationType.SUBMISSION_RECEIVED,
          category: NotificationCategory.ASSIGNMENT,
          title: 'Assignment Submission Received',
          body: `${submission.studentName} has submitted work for ${assignment.title}${isLate ? ' (Late)' : ''}.`,
          priority: NotificationPriority.NORMAL,
          relatedEntityType: 'ASSIGNMENT_SUBMISSION',
          relatedEntityId: submission._id.toString(),
          deepLink: `/assignments/${assignment._id.toString()}/activity`,
          idempotencyKey,
          metadata: {
            assignmentId: assignment._id.toString(),
            submissionId: submission._id.toString(),
            studentId: student._id.toString(),
            isLate,
          },
        }).catch((err) => {
          logger.warn(`Failed to notify faculty of submission: ${err.message}`);
        });
      } catch (err: any) {
        logger.warn(`Error in submission notification dispatch: ${err.message}`);
      }
    });

    return submission;
  }

  /**
   * 11. Faculty Activity & Student Submissions
   */
  static async getAssignmentActivity(
    collegeId: string,
    user: { id: string; role?: string; departmentId?: string },
    assignmentId: string
  ): Promise<{
    assignment: any;
    summary: {
      totalStudents: number;
      completedCount: number;
      pendingCount: number;
      overdueCount: number;
      reviewedCount: number;
      averageMarks: number | null;
      maximumMarks: number;
    };
    completed: any[];
    pending: any[];
  }> {
    const assignment = await Assignment.findOne({
      _id: new Types.ObjectId(assignmentId),
      collegeId: new Types.ObjectId(collegeId),
    })
      .populate('subjectId', 'name code')
      .populate('sectionId', 'name')
      .populate('semesterId', 'name number');

    if (!assignment) {
      throw ApiError.notFound('Assignment not found.');
    }

    await TeachingAuthorizationService.assertAssignmentAccess(collegeId, user, assignment);

    // 1. Resolve all active enrolled students in this academic context
    const enrollmentQuery: any = {
      collegeId: new Types.ObjectId(collegeId),
      semesterId: assignment.semesterId,
      courseId: assignment.courseId,
      status: 'active',
    };
    if (assignment.sectionId) {
      enrollmentQuery.sectionId = assignment.sectionId;
    }

    const enrollments = await StudentEnrollment.find(enrollmentQuery).populate(
      'studentId',
      'name rollNumber userId'
    );

    // 2. Fetch all existing submissions
    const submissions = await AssignmentSubmission.find({
      assignmentId: assignment._id,
    });
    const subMap = new Map<string, IAssignmentSubmission>();
    submissions.forEach((s) => subMap.set(s.studentId.toString(), s));

    const completed: any[] = [];
    const pending: any[] = [];
    const now = new Date();
    const isDeadlinePassed = assignment.dueDateTime < now;

    let totalMarksSum = 0;
    let reviewedCount = 0;

    for (const enr of enrollments) {
      const student = enr.studentId as any;
      if (!student) continue;

      const studentIdStr = student._id.toString();
      const sub = subMap.get(studentIdStr);

      const isCompletedStatus =
        sub &&
        (sub.status === StudentTaskStatus.COMPLETED ||
          sub.status === StudentTaskStatus.SUBMITTED ||
          sub.status === StudentTaskStatus.RESUBMITTED);

      if (isCompletedStatus) {
        if (sub.reviewStatus === FacultyReviewStatus.REVIEWED && typeof sub.marks === 'number') {
          totalMarksSum += sub.marks;
          reviewedCount++;
        }
        completed.push({
          submissionId: sub._id?.toString(),
          studentId: studentIdStr,
          studentName: student.name,
          rollNumber: student.rollNumber || null,
          status: sub.status,
          textResponse: sub.textResponse || null,
          attachments: sub.attachments || [],
          submittedAt: sub.submittedAt || sub.completedAt || null,
          completedAt: sub.completedAt || sub.submittedAt || null,
          isLate: sub.isLate,
          version: sub.version || 1,
          submissionHistory: sub.submissionHistory || [],
          reviewStatus: sub.reviewStatus,
          marks: sub.marks,
          feedback: sub.feedback || null,
          reviewedAt: sub.reviewedAt || null,
          maximumMarks: assignment.maximumMarks,
        });
      } else {
        const studentStatus = isDeadlinePassed ? StudentTaskStatus.OVERDUE : StudentTaskStatus.PENDING;
        pending.push({
          studentId: studentIdStr,
          studentName: student.name,
          rollNumber: student.rollNumber || null,
          status: studentStatus,
          isDraft: sub?.status === StudentTaskStatus.DRAFT,
          reviewStatus: FacultyReviewStatus.NOT_REVIEWED,
          marks: null,
          maximumMarks: assignment.maximumMarks,
        });
      }
    }

    const averageMarks =
      reviewedCount > 0 ? Math.round((totalMarksSum / reviewedCount) * 10) / 10 : null;

    const overdueCount = pending.filter((p) => p.status === StudentTaskStatus.OVERDUE).length;
    const pendingCount = pending.filter((p) => p.status === StudentTaskStatus.PENDING).length;

    return {
      assignment: assignment.toJSON(),
      summary: {
        totalStudents: enrollments.length,
        completedCount: completed.length,
        pendingCount,
        overdueCount,
        reviewedCount,
        averageMarks,
        maximumMarks: assignment.maximumMarks,
      },
      completed,
      pending,
    };
  }

  /**
   * 12. Faculty records marks for completed students
   */
  static async recordMarks(
    collegeId: string,
    user: { id: string; role?: string; departmentId?: string },
    assignmentId: string,
    marksList: Array<{ studentId: string; marks: number; feedback?: string }>
  ): Promise<any> {
    const assignment = await Assignment.findOne({
      _id: new Types.ObjectId(assignmentId),
      collegeId: new Types.ObjectId(collegeId),
    });

    if (!assignment) {
      throw ApiError.notFound('Assignment not found.');
    }

    const roleUpper = user.role?.toUpperCase();
    if (roleUpper === 'STUDENT') {
      throw ApiError.forbidden('Students cannot grade assignments.');
    }
    await TeachingAuthorizationService.assertAssignmentMarkingAccess(collegeId, user, assignment);

    for (const item of marksList) {
      const marksVal = Math.floor(item.marks);
      if (marksVal < 0) {
        throw ApiError.badRequest('Marks cannot be negative.');
      }
      if (marksVal > assignment.maximumMarks) {
        throw ApiError.badRequest(
          `Marks (${marksVal}) cannot exceed maximum marks (${assignment.maximumMarks}).`
        );
      }

      // Canonical StudentEnrollment validation
      const enrollment = await StudentEnrollment.findOne({
        collegeId: new Types.ObjectId(collegeId),
        studentId: new Types.ObjectId(item.studentId),
        semesterId: assignment.semesterId,
        courseId: assignment.courseId,
        ...(assignment.sectionId ? { sectionId: assignment.sectionId } : {}),
        status: { $in: ['active', 'ACTIVE'] },
      });
      if (!enrollment) {
        throw ApiError.forbidden('Student is not enrolled in the academic context of this assignment.');
      }

      const updatedSub = await AssignmentSubmission.findOneAndUpdate(
        {
          assignmentId: assignment._id,
          studentId: new Types.ObjectId(item.studentId),
        },
        {
          $set: {
            marks: marksVal,
            reviewStatus: FacultyReviewStatus.REVIEWED,
            reviewedAt: new Date(),
            reviewedBy: new Types.ObjectId(user.id),
            feedback: item.feedback || null,
          },
        },
        { new: true, upsert: false }
      );

      if (updatedSub) {
        this.emitSubmissionReviewed(updatedSub, assignment);
      }
    }

    return this.getAssignmentActivity(collegeId, user, assignmentId);
  }

  /**
   * 13. Securely generate download URL for submission file
   */
  static async getSubmissionFileDownloadUrl(
    collegeId: string,
    user: { id: string; role?: string; departmentId?: string },
    assignmentId: string,
    fileIdOrStorageKey: string
  ): Promise<{ downloadUrl: string; fileName: string; mimeType: string }> {
    const assignment = await Assignment.findOne({
      _id: new Types.ObjectId(assignmentId),
      collegeId: new Types.ObjectId(collegeId),
    });
    if (!assignment) {
      throw ApiError.notFound('Assignment not found.');
    }

    // Find submission matching this file
    const submission = await AssignmentSubmission.findOne({
      assignmentId: assignment._id,
      collegeId: new Types.ObjectId(collegeId),
      $or: [
        { 'attachments.fileId': fileIdOrStorageKey },
        { 'attachments.storageKey': fileIdOrStorageKey },
        { 'attachments.url': fileIdOrStorageKey },
        { 'submissionHistory.attachments.fileId': fileIdOrStorageKey },
      ],
    });

    if (!submission) {
      throw ApiError.notFound('Submission or file not found.');
    }

    const roleUpper = user.role?.toUpperCase();
    if (roleUpper === 'STUDENT') {
      if (submission.studentUserId.toString() !== user.id) {
        throw ApiError.forbidden('You cannot access another student\'s submission files.');
      }
    } else {
      await TeachingAuthorizationService.assertAssignmentAccess(collegeId, user, assignment);
    }

    // Locate the attachment
    let attachment: ISubmissionAttachment | undefined = submission.attachments.find(
      (a) =>
        a.fileId === fileIdOrStorageKey ||
        a.storageKey === fileIdOrStorageKey ||
        a.url === fileIdOrStorageKey
    );

    if (!attachment && submission.submissionHistory) {
      for (const hist of submission.submissionHistory) {
        const found = hist.attachments.find(
          (a) =>
            a.fileId === fileIdOrStorageKey ||
            a.storageKey === fileIdOrStorageKey ||
            a.url === fileIdOrStorageKey
        );
        if (found) {
          attachment = found;
          break;
        }
      }
    }

    if (!attachment) {
      throw ApiError.notFound('Attachment metadata not found.');
    }

    const downloadUrl = ImageKitService.generateSignedUrl(
      attachment.storageKey || attachment.url,
      3600 // 1 hour expiration
    );

    return {
      downloadUrl,
      fileName: attachment.name,
      mimeType: attachment.mimeType || 'application/octet-stream',
    };
  }

  /**
   * 14. Faculty reviews and grades a single student submission
   */
  static async reviewSingleSubmission(
    collegeId: string,
    user: { id: string; role?: string; departmentId?: string },
    assignmentId: string,
    submissionId: string,
    data: { marks: number; feedback?: string }
  ): Promise<IAssignmentSubmission> {
    const assignment = await Assignment.findOne({
      _id: new Types.ObjectId(assignmentId),
      collegeId: new Types.ObjectId(collegeId),
    });
    if (!assignment) {
      throw ApiError.notFound('Assignment not found.');
    }

    const roleUpper = user.role?.toUpperCase();
    if (roleUpper === 'STUDENT') {
      throw ApiError.forbidden('Students cannot review or grade submissions.');
    }
    await TeachingAuthorizationService.assertAssignmentMarkingAccess(collegeId, user, assignment);

    if (data.marks < 0) {
      throw ApiError.badRequest('Marks cannot be negative.');
    }
    if (data.marks > assignment.maximumMarks) {
      throw ApiError.badRequest(
        `Marks (${data.marks}) cannot exceed maximum marks (${assignment.maximumMarks}).`
      );
    }

    const submission = await AssignmentSubmission.findOne({
      _id: new Types.ObjectId(submissionId),
      assignmentId: assignment._id,
      collegeId: new Types.ObjectId(collegeId),
    });
    if (!submission) {
      throw ApiError.notFound('Submission not found.');
    }

    // Canonical StudentEnrollment validation
    const enrollment = await StudentEnrollment.findOne({
      collegeId: new Types.ObjectId(collegeId),
      studentId: submission.studentId,
      semesterId: assignment.semesterId,
      courseId: assignment.courseId,
      ...(assignment.sectionId ? { sectionId: assignment.sectionId } : {}),
      status: { $in: ['active', 'ACTIVE'] },
    });
    if (!enrollment) {
      throw ApiError.forbidden('Student is not enrolled in the academic context of this assignment.');
    }

    submission.marks = data.marks;
    submission.feedback = data.feedback || null;
    submission.reviewStatus = FacultyReviewStatus.REVIEWED;
    submission.reviewedAt = new Date();
    submission.reviewedBy = new Types.ObjectId(user.id);

    await submission.save();

    // Realtime persistence-first event
    this.emitSubmissionReviewed(submission, assignment);

    assignmentEvents.emit(AssignmentEvent.ASSIGNMENT_GRADED, {
      assignmentId: assignment._id.toString(),
      submissionId: submission._id.toString(),
      studentId: submission.studentId.toString(),
      studentUserId: submission.studentUserId.toString(),
      marks: submission.marks,
    });

    // Notify student asynchronously
    setImmediate(async () => {
      try {
        const studentUserId = submission.studentUserId.toString();
        const idempotencyKey = `sub_rev_${submission._id}_v${submission.version}`;
        await NotificationService.createNotification({
          collegeId: assignment.collegeId.toString(),
          recipientUserId: studentUserId,
          notificationType: NotificationType.ASSIGNMENT_GRADED,
          category: NotificationCategory.ASSIGNMENT,
          title: 'Assignment Graded',
          body: `Your submission for ${assignment.title} was reviewed: ${submission.marks}/${assignment.maximumMarks} Marks.`,
          priority: NotificationPriority.NORMAL,
          relatedEntityType: 'ASSIGNMENT_SUBMISSION',
          relatedEntityId: submission._id.toString(),
          deepLink: `/assignments/${assignment._id.toString()}`,
          idempotencyKey,
          metadata: {
            assignmentId: assignment._id.toString(),
            submissionId: submission._id.toString(),
            marks: submission.marks,
            maximumMarks: assignment.maximumMarks,
          },
        }).catch((err) => {
          logger.warn(`Failed to notify student of grade: ${err.message}`);
        });
      } catch (err: any) {
        logger.warn(`Error in grade notification dispatch: ${err.message}`);
      }
    });

    return submission;
  }

  /**
   * Helper: Emit ASSIGNMENT_CREATED realtime event
   */
  private static emitAssignmentCreated(assignment: IAssignment): void {
    try {
      const collegeIdStr = assignment.collegeId?.toString() ?? '';
      realtimeEventBus.publish({
        eventType: AcadexEventType.ASSIGNMENT_CREATED,
        aggregateType: 'Assignment',
        aggregateId: assignment.id,
        action: 'CREATED',
        collegeId: collegeIdStr,
        scope: {
          type: 'channel',
          collegeId: collegeIdStr,
          channel: assignment.sectionId
            ? `section:${collegeIdStr}:${assignment.sectionId.toString()}`
            : `college:${collegeIdStr}`,
        },
        payload: {
          assignmentId: assignment.id,
          title: assignment.title,
          status: assignment.status,
          sectionId: assignment.sectionId ? assignment.sectionId.toString() : null,
          subjectId: assignment.subjectId ? assignment.subjectId.toString() : null,
        },
      });
    } catch (err: any) {
      logger.warn(`Error in emitAssignmentCreated: ${err.message}`);
    }
  }

  /**
   * Helper: Emit ASSIGNMENT_UPDATED realtime event
   */
  private static emitAssignmentUpdated(assignment: IAssignment, action: RealtimeAction = 'UPDATED'): void {
    try {
      const collegeIdStr = assignment.collegeId?.toString() ?? '';
      realtimeEventBus.publish({
        eventType: AcadexEventType.ASSIGNMENT_UPDATED,
        aggregateType: 'Assignment',
        aggregateId: assignment.id,
        action,
        collegeId: collegeIdStr,
        scope: {
          type: 'channel',
          collegeId: collegeIdStr,
          channel: assignment.sectionId
            ? `section:${collegeIdStr}:${assignment.sectionId.toString()}`
            : `college:${collegeIdStr}`,
        },
        payload: {
          assignmentId: assignment.id,
          title: assignment.title,
          status: assignment.status,
          sectionId: assignment.sectionId ? assignment.sectionId.toString() : null,
          subjectId: assignment.subjectId ? assignment.subjectId.toString() : null,
        },
      });
    } catch (err: any) {
      logger.warn(`Error in emitAssignmentUpdated: ${err.message}`);
    }
  }

  /**
   * Helper: Emit ASSIGNMENT_CLOSED realtime event
   */
  private static emitAssignmentClosed(assignment: IAssignment): void {
    try {
      const collegeIdStr = assignment.collegeId?.toString() ?? '';
      realtimeEventBus.publish({
        eventType: AcadexEventType.ASSIGNMENT_CLOSED,
        aggregateType: 'Assignment',
        aggregateId: assignment.id,
        action: 'CLOSED',
        collegeId: collegeIdStr,
        scope: {
          type: 'channel',
          collegeId: collegeIdStr,
          channel: assignment.sectionId
            ? `section:${collegeIdStr}:${assignment.sectionId.toString()}`
            : `college:${collegeIdStr}`,
        },
        payload: {
          assignmentId: assignment.id,
          title: assignment.title,
          status: assignment.status,
          sectionId: assignment.sectionId ? assignment.sectionId.toString() : null,
          subjectId: assignment.subjectId ? assignment.subjectId.toString() : null,
        },
      });
    } catch (err: any) {
      logger.warn(`Error in emitAssignmentClosed: ${err.message}`);
    }
  }

  /**
   * Helper: Emit SUBMISSION_SUBMITTED realtime event
   */
  private static emitSubmissionSubmitted(
    submission: IAssignmentSubmission,
    assignment: IAssignment
  ): void {
    try {
      const collegeIdStr = submission.collegeId?.toString() ?? '';
      realtimeEventBus.publish({
        eventType: AcadexEventType.SUBMISSION_SUBMITTED,
        aggregateType: 'AssignmentSubmission',
        aggregateId: submission.id,
        action: 'SUBMITTED',
        collegeId: collegeIdStr,
        scope: {
          type: 'channel',
          collegeId: collegeIdStr,
          channel: assignment.sectionId
            ? `section:${collegeIdStr}:${assignment.sectionId.toString()}`
            : `college:${collegeIdStr}`,
        },
        payload: {
          assignmentId: assignment.id,
          submissionId: submission.id,
          studentId: submission.studentId.toString(),
          studentUserId: submission.studentUserId.toString(),
          status: submission.status,
          isLate: submission.isLate,
          submittedAt: submission.submittedAt,
        },
      });
    } catch (err: any) {
      logger.warn(`Error in emitSubmissionSubmitted: ${err.message}`);
    }
  }

  /**
   * Helper: Emit SUBMISSION_REVIEWED realtime event
   */
  private static emitSubmissionReviewed(
    submission: IAssignmentSubmission,
    assignment: IAssignment
  ): void {
    try {
      const collegeIdStr = submission.collegeId?.toString() ?? '';
      realtimeEventBus.publish({
        eventType: AcadexEventType.SUBMISSION_REVIEWED,
        aggregateType: 'AssignmentSubmission',
        aggregateId: submission.id,
        action: 'REVIEWED',
        collegeId: collegeIdStr,
        scope: {
          type: 'user',
          collegeId: collegeIdStr,
          userId: submission.studentUserId.toString(),
        },
        payload: {
          assignmentId: assignment.id,
          submissionId: submission.id,
          studentId: submission.studentId.toString(),
          studentUserId: submission.studentUserId.toString(),
          marks: submission.marks,
          maximumMarks: assignment.maximumMarks,
          feedback: submission.feedback,
          reviewStatus: submission.reviewStatus,
          reviewedAt: submission.reviewedAt,
        },
      });
    } catch (err: any) {
      logger.warn(`Error in emitSubmissionReviewed: ${err.message}`);
    }
  }

  /**
   * Helper: Emit ASSIGNMENT_PUBLISHED notification & realtime events
   */
  private static async emitAssignmentPublished(assignment: IAssignment): Promise<void> {
    try {
      assignmentEvents.emit(AssignmentEvent.ASSIGNMENT_PUBLISHED, assignment);

      // Emit Realtime Domain Event (Persistence-First)
      realtimeEventBus.publish({
        eventType: AcadexEventType.ASSIGNMENT_PUBLISHED,
        aggregateType: 'Assignment',
        aggregateId: assignment.id,
        action: 'PUBLISHED',
        collegeId: assignment.collegeId.toString(),
        scope: {
          type: 'channel',
          collegeId: assignment.collegeId.toString(),
          channel: assignment.sectionId
            ? `section:${assignment.collegeId.toString()}:${assignment.sectionId.toString()}`
            : `college:${assignment.collegeId.toString()}`,
        },
        payload: {
          assignmentId: assignment.id,
          facultyAssignmentId: assignment.facultyAssignmentId ? assignment.facultyAssignmentId.toString() : null,
          title: assignment.title,
          sectionId: assignment.sectionId ? assignment.sectionId.toString() : null,
          subjectId: assignment.subjectId.toString(),
          semesterId: assignment.semesterId.toString(),
          academicYearId: assignment.academicYearId.toString(),
          dueDate: assignment.dueDate,
          dueTime: assignment.dueTime,
          version: 1,
        },
      });

      // Async dispatch in-app notifications to eligible students
      setImmediate(async () => {
        try {
          const subject = await Subject.findById(assignment.subjectId);
          const subjectName = subject?.name || 'Subject';

          // Find eligible active students in this academic context
          const enrollmentQuery: any = {
            collegeId: assignment.collegeId,
            semesterId: assignment.semesterId,
            courseId: assignment.courseId,
            status: 'active',
          };
          if (assignment.sectionId) {
            enrollmentQuery.sectionId = assignment.sectionId;
          }

          const enrollments = await StudentEnrollment.find(enrollmentQuery).populate(
            'studentId',
            'userId name'
          );

          for (const enr of enrollments) {
            const student = enr.studentId as any;
            if (!student || !student.userId) continue;

            const studentUserId = student.userId.toString();
            const idempotencyKey = `asgn_pub_${assignment._id}_${studentUserId}`;

            await NotificationService.createNotification({
              collegeId: assignment.collegeId.toString(),
              recipientUserId: studentUserId,
              notificationType: NotificationType.ASSIGNMENT_PUBLISHED,
              category: NotificationCategory.ASSIGNMENT,
              title: 'New Assignment',
              body: `${assignment.title} has been posted for ${subjectName}.`,
              priority: NotificationPriority.NORMAL,
              relatedEntityType: 'ASSIGNMENT',
              relatedEntityId: assignment._id.toString(),
              deepLink: `/assignments/${assignment._id.toString()}`,
              idempotencyKey,
              metadata: {
                assignmentId: assignment._id.toString(),
                dueDate: assignment.dueDate,
                dueTime: assignment.dueTime,
              },
            }).catch((err) => {
              logger.warn(`Failed to dispatch assignment notification to ${studentUserId}: ${err.message}`);
            });
          }
        } catch (err: any) {
          logger.warn(`Failed to process assignment notification event: ${err.message}`);
        }
      });
    } catch (err: any) {
      logger.warn(`Error in emitAssignmentPublished: ${err.message}`);
    }
  }
}
