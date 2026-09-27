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
import { NotificationService } from './notification.service';
import { logger } from '../utils/logger';

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
      let h = parseInt(parts[0], 10);
      const m = parseInt(parts[1], 10);
      if (!isNaN(h) && !isNaN(m)) {
        if (isPm && h < 12) h += 12;
        if (isAm && h === 12) h = 0;
        hours = h;
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
    user: { id: string; name?: string; role?: string },
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

    // 1. Resolve and verify authorized teaching context
    const fa = await FacultyAssignment.findOne({
      _id: new Types.ObjectId(data.facultyAssignmentId),
      collegeId: new Types.ObjectId(collegeId),
    });

    if (!fa) {
      throw ApiError.notFound('Teaching context (Faculty Assignment) not found for this college.');
    }

    // Authorization: Faculty user must match the teaching assignment, or be HOD / Admin
    const roleUpper = user.role?.toUpperCase();
    const isFacultyUser = roleUpper === 'FACULTY';
    if (isFacultyUser) {
      const facultyDoc = await FacultyAssignment.findOne({
        _id: fa._id,
        $or: [
          { facultyId: new Types.ObjectId(user.id) },
          { facultyName: user.name },
        ],
      });
      if (!facultyDoc) {
        throw ApiError.forbidden('You are not authorized to create assignments for this teaching context.');
      }
    }

    // 2. Duplicate submission protection (deterministic 5-second window)
    const dueDateTime = parseDueDateTime(data.dueDate, data.dueTime);
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

    const status = data.status || AssignmentStatus.DRAFT;
    const publishedAt = status === AssignmentStatus.PUBLISHED ? new Date() : null;

    const assignment = await Assignment.create({
      collegeId: new Types.ObjectId(collegeId),
      departmentId: fa.departmentId,
      courseId: fa.courseId,
      academicYearId: fa.academicYearId,
      semesterId: fa.semesterId,
      sectionId: fa.sectionId,
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
    }

    return assignment;
  }

  /**
   * 2. Publish a Draft Assignment
   */
  static async publishAssignment(
    collegeId: string,
    user: { id: string; role?: string },
    assignmentId: string
  ): Promise<IAssignment> {
    const assignment = await Assignment.findOne({
      _id: new Types.ObjectId(assignmentId),
      collegeId: new Types.ObjectId(collegeId),
    });

    if (!assignment) {
      throw ApiError.notFound('Assignment not found.');
    }

    // Authorization
    const roleUpper = user.role?.toUpperCase();
    if (roleUpper === 'FACULTY' && assignment.facultyId.toString() !== user.id) {
      throw ApiError.forbidden('You are not authorized to publish this assignment.');
    }

    if (assignment.status === AssignmentStatus.PUBLISHED) {
      return assignment; // Idempotent
    }
    if (assignment.status === AssignmentStatus.CLOSED) {
      throw ApiError.badRequest('Cannot publish a closed assignment.');
    }

    assignment.status = AssignmentStatus.PUBLISHED;
    assignment.publishedAt = new Date();
    await assignment.save();

    this.emitAssignmentPublished(assignment);
    return assignment;
  }

  /**
   * 3. Close an Assignment
   */
  static async closeAssignment(
    collegeId: string,
    user: { id: string; role?: string },
    assignmentId: string
  ): Promise<IAssignment> {
    const assignment = await Assignment.findOne({
      _id: new Types.ObjectId(assignmentId),
      collegeId: new Types.ObjectId(collegeId),
    });

    if (!assignment) {
      throw ApiError.notFound('Assignment not found.');
    }

    const roleUpper = user.role?.toUpperCase();
    if (roleUpper === 'FACULTY' && assignment.facultyId.toString() !== user.id) {
      throw ApiError.forbidden('You are not authorized to close this assignment.');
    }

    assignment.status = AssignmentStatus.CLOSED;
    assignment.closedAt = new Date();
    await assignment.save();

    return assignment;
  }

  /**
   * 4. Get Assignments for Faculty
   */
  static async getFacultyAssignments(
    collegeId: string,
    user: { id: string; role?: string },
    query?: { status?: string; sectionId?: string; subjectId?: string }
  ): Promise<any[]> {
    const filter: Record<string, any> = {
      collegeId: new Types.ObjectId(collegeId),
    };

    const roleUpper = user.role?.toUpperCase();
    if (roleUpper === 'FACULTY') {
      filter.facultyId = new Types.ObjectId(user.id);
    }
    if (query?.status) {
      filter.status = query.status;
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
      .sort({ createdAt: -1 });

    // Attach basic activity counts
    const results = await Promise.all(
      assignments.map(async (asgn) => {
        const totalEnrolled = await StudentEnrollment.countDocuments({
          collegeId: asgn.collegeId,
          sectionId: asgn.sectionId,
          status: 'active',
        });
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
   * 5. Get Assignments for Enrolled Student
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

    const sectionIds = enrollments.map((e) => e.sectionId);

    // 3. Find published assignments for enrolled sections
    const assignments = await Assignment.find({
      collegeId: new Types.ObjectId(collegeId),
      sectionId: { $in: sectionIds },
      status: AssignmentStatus.PUBLISHED,
    })
      .populate('subjectId', 'name code')
      .populate('sectionId', 'name')
      .sort({ dueDateTime: 1 });

    const assignmentIds = assignments.map((a) => a._id);

    // 4. Find student's submissions
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
   * 6. Get Single Assignment Detail
   */
  static async getAssignmentDetail(
    collegeId: string,
    user: { id: string; role?: string },
    assignmentId: string
  ): Promise<any> {
    const assignment = await Assignment.findOne({
      _id: new Types.ObjectId(assignmentId),
      collegeId: new Types.ObjectId(collegeId),
    })
      .populate('subjectId', 'name code')
      .populate('sectionId', 'name')
      .populate('departmentId', 'name');

    if (!assignment) {
      throw ApiError.notFound('Assignment not found.');
    }

    const json: any = assignment.toJSON();

    if (user.role === 'student') {
      let student = await Student.findOne({
        collegeId: new Types.ObjectId(collegeId),
        userId: new Types.ObjectId(user.id),
      });
      if (!student && Types.ObjectId.isValid(user.id)) {
        student = await Student.findById(user.id);
      }

      if (student) {
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
      }
    }

    return json;
  }

  /**
   * 7. Student marks assignment as Done
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

    // Resolve student
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

    // Verify enrollment in section
    const enrollment = await StudentEnrollment.findOne({
      collegeId: new Types.ObjectId(collegeId),
      studentId: student._id,
      sectionId: assignment.sectionId,
      status: 'active',
    });

    if (!enrollment) {
      throw ApiError.forbidden('You are not enrolled in the section for this assignment.');
    }

    const now = new Date();
    const isLate = assignment.dueDateTime < now;

    // Idempotent upsert submission
    let submission = await AssignmentSubmission.findOne({
      assignmentId: assignment._id,
      studentId: student._id,
    });

    if (submission && submission.status === StudentTaskStatus.COMPLETED) {
      return submission; // Already marked done
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
        isLate,
        reviewStatus: FacultyReviewStatus.NOT_REVIEWED,
        marks: null,
      });
    } else {
      submission.status = StudentTaskStatus.COMPLETED;
      submission.completedAt = now;
      submission.isLate = isLate;
    }

    await submission.save();

    assignmentEvents.emit(AssignmentEvent.ASSIGNMENT_COMPLETED, {
      assignmentId: assignment._id.toString(),
      studentId: student._id.toString(),
      studentUserId: studentUser.id,
    });

    return submission;
  }

  /**
   * 8. Faculty Activity & Student Submissions
   */
  static async getAssignmentActivity(
    collegeId: string,
    user: { id: string; role?: string },
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
      .populate('sectionId', 'name');

    if (!assignment) {
      throw ApiError.notFound('Assignment not found.');
    }

    const roleUpper = user.role?.toUpperCase();
    if (roleUpper === 'FACULTY' && assignment.facultyId.toString() !== user.id) {
      throw ApiError.forbidden('You are not authorized to view activity for this assignment.');
    }

    // 1. Resolve all active enrolled students in this section
    const enrollments = await StudentEnrollment.find({
      collegeId: new Types.ObjectId(collegeId),
      sectionId: assignment.sectionId,
      status: 'active',
    }).populate('studentId', 'name rollNumber userId');

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

      if (sub && sub.status === StudentTaskStatus.COMPLETED) {
        if (sub.reviewStatus === FacultyReviewStatus.REVIEWED && typeof sub.marks === 'number') {
          totalMarksSum += sub.marks;
          reviewedCount++;
        }
        completed.push({
          studentId: studentIdStr,
          studentName: student.name,
          rollNumber: student.rollNumber || null,
          status: StudentTaskStatus.COMPLETED,
          completedAt: sub.completedAt,
          isLate: sub.isLate,
          reviewStatus: sub.reviewStatus,
          marks: sub.marks,
          maximumMarks: assignment.maximumMarks,
        });
      } else {
        const studentStatus = isDeadlinePassed ? StudentTaskStatus.OVERDUE : StudentTaskStatus.PENDING;
        pending.push({
          studentId: studentIdStr,
          studentName: student.name,
          rollNumber: student.rollNumber || null,
          status: studentStatus,
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
   * 9. Faculty records marks for completed students
   */
  static async recordMarks(
    collegeId: string,
    user: { id: string; role?: string },
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
    if (roleUpper === 'FACULTY' && assignment.facultyId.toString() !== user.id) {
      throw ApiError.forbidden('You are not authorized to grade this assignment.');
    }

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

      await AssignmentSubmission.findOneAndUpdate(
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
        { upsert: false }
      );
    }

    return this.getAssignmentActivity(collegeId, user, assignmentId);
  }

  /**
   * Helper: Emit ASSIGNMENT_PUBLISHED notification event
   */
  private static async emitAssignmentPublished(assignment: IAssignment): Promise<void> {
    try {
      assignmentEvents.emit(AssignmentEvent.ASSIGNMENT_PUBLISHED, assignment);

      // Async dispatch in-app notifications to eligible students
      setImmediate(async () => {
        try {
          const subject = await Subject.findById(assignment.subjectId);
          const subjectName = subject?.name || 'Subject';

          // Find eligible active students in this section
          const enrollments = await StudentEnrollment.find({
            collegeId: assignment.collegeId,
            sectionId: assignment.sectionId,
            status: 'active',
          }).populate('studentId', 'userId name');

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
