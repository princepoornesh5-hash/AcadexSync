import { Types } from 'mongoose';
import { ApiError } from '../utils/apiError';
import {
  PracticalSessionStatus,
  PracticalParticipationStatus,
  isSubjectPracticalCapable,
} from '../constants/practical.constants';
import {
  PracticalDefinition,
  IPracticalDefinition,
  PracticalSession,
  IPracticalSession,
  PracticalParticipation,
  IPracticalParticipation,
  Subject,
  StudentEnrollment,
  Student,
  Room,
} from '../models';
import { TeachingAuthorizationService, AuthUserContext } from './teachingAuthorization.service';
import { AuditService } from './audit.service';
import { NotificationService } from './notification.service';
import { NotificationType } from '../constants/notification.constants';
import { realtimeEventBus } from '../realtime';
import { AcadexEventType } from '../realtime/contracts/eventRegistry';
import { Logger } from '../utils/logger';

export interface CreatePracticalDefinitionPayload {
  subjectId: string;
  courseId: string;
  academicYearId: string;
  semesterId: string;
  sectionId?: string | null;
  departmentId: string;
  title: string;
  code?: string | null;
  description?: string | null;
  plannedSessions?: number;
}

export interface CreatePracticalSessionPayload {
  facultyAssignmentId: string;
  topic: string;
  instructions?: string | null;
  scheduledDate: string | Date;
  startTime?: string | null;
  endTime?: string | null;
  roomId?: string | null;
  timetableEntryId?: string | null;
  sessionNumber?: number;
  practicalDefinitionId?: string | null;
}

export interface UpdatePracticalSessionPayload {
  topic?: string;
  instructions?: string | null;
  scheduledDate?: string | Date;
  startTime?: string | null;
  endTime?: string | null;
  roomId?: string | null;
}

export interface UpdateParticipationPayload {
  status: PracticalParticipationStatus;
  notes?: string | null;
}

export interface BulkParticipationItem {
  studentId: string;
  status: PracticalParticipationStatus;
  notes?: string | null;
}

export class PracticalService {
  // =========================================================================
  // 1. PRACTICAL DEFINITIONS
  // =========================================================================

  /**
   * Creates a canonical practical definition for a subject.
   */
  static async createDefinition(
    collegeId: string,
    user: AuthUserContext,
    payload: CreatePracticalDefinitionPayload
  ): Promise<IPracticalDefinition> {
    const { subjectId, departmentId, courseId, academicYearId, semesterId, sectionId, title, code, description, plannedSessions } = payload;

    const subject = await Subject.findById(subjectId);
    if (!subject || subject.collegeId.toString() !== collegeId) {
      throw ApiError.notFound('Subject not found or does not belong to this college');
    }

    if (!isSubjectPracticalCapable(subject.type)) {
      throw ApiError.badRequest(
        `Subject "${subject.name}" (${subject.code}) is configured as "${subject.type || 'Theory'}" and does not support practical sessions.`
      );
    }

    // Role check: HOD must match department, Admin can manage institution
    if (user.role === 'hod' && user.departmentId && user.departmentId !== departmentId) {
      throw ApiError.forbidden('HOD can only create practical definitions within their department');
    }

    const definition = await PracticalDefinition.create({
      collegeId: new Types.ObjectId(collegeId),
      departmentId: new Types.ObjectId(departmentId),
      courseId: new Types.ObjectId(courseId),
      academicYearId: new Types.ObjectId(academicYearId),
      semesterId: new Types.ObjectId(semesterId),
      sectionId: sectionId ? new Types.ObjectId(sectionId) : null,
      subjectId: new Types.ObjectId(subjectId),
      title: title.trim(),
      code: code ? code.trim().toUpperCase() : null,
      description: description?.trim() || null,
      plannedSessions: plannedSessions || 10,
      createdBy: Types.ObjectId.isValid(user.id) ? new Types.ObjectId(user.id) : null,
      updatedBy: Types.ObjectId.isValid(user.id) ? new Types.ObjectId(user.id) : null,
    });

    return definition;
  }

  /**
   * Lists practical definitions with optional academic filters.
   */
  static async listDefinitions(
    collegeId: string,
    query: {
      departmentId?: string;
      courseId?: string;
      semesterId?: string;
      sectionId?: string;
      subjectId?: string;
    }
  ): Promise<IPracticalDefinition[]> {
    const filter: Record<string, any> = {
      collegeId: new Types.ObjectId(collegeId),
      isActive: true,
    };

    if (query.departmentId && Types.ObjectId.isValid(query.departmentId)) {
      filter.departmentId = new Types.ObjectId(query.departmentId);
    }
    if (query.courseId && Types.ObjectId.isValid(query.courseId)) {
      filter.courseId = new Types.ObjectId(query.courseId);
    }
    if (query.semesterId && Types.ObjectId.isValid(query.semesterId)) {
      filter.semesterId = new Types.ObjectId(query.semesterId);
    }
    if (query.subjectId && Types.ObjectId.isValid(query.subjectId)) {
      filter.subjectId = new Types.ObjectId(query.subjectId);
    }

    return PracticalDefinition.find(filter).sort({ createdAt: -1 });
  }

  // =========================================================================
  // 2. PRACTICAL SESSIONS
  // =========================================================================

  /**
   * Creates a new practical lab session tied to an authoritative FacultyAssignment.
   */
  static async createSession(
    collegeId: string,
    user: AuthUserContext,
    payload: CreatePracticalSessionPayload
  ): Promise<IPracticalSession> {
    const { facultyAssignmentId, topic, instructions, scheduledDate, startTime, endTime, roomId, timetableEntryId, sessionNumber, practicalDefinitionId } = payload;

    if (!Types.ObjectId.isValid(facultyAssignmentId)) {
      throw ApiError.badRequest('Invalid facultyAssignmentId format');
    }

    // 1. Authoritative FacultyAssignment check
    const fa = await TeachingAuthorizationService.assertFacultyAssignmentAccess(
      collegeId,
      user,
      facultyAssignmentId
    );

    if (!fa.isActive) {
      throw ApiError.badRequest('Cannot schedule a practical session for an inactive faculty assignment');
    }

    // 2. Verify Subject exists and is practical-capable
    const subject = await Subject.findById(fa.subjectId);
    if (!subject) {
      throw ApiError.notFound('Associated Subject not found');
    }

    if (!isSubjectPracticalCapable(subject.type)) {
      throw ApiError.badRequest(
        `Subject "${subject.name}" (${subject.code}) is not configured as a practical or lab course (current type: ${subject.type || 'Theory'}).`
      );
    }

    // 3. Optional Room validation
    let roomDoc = null;
    let roomNumber = null;
    let building = null;

    if (roomId && Types.ObjectId.isValid(roomId)) {
      roomDoc = await Room.findById(roomId);
      if (!roomDoc || roomDoc.collegeId.toString() !== collegeId) {
        throw ApiError.notFound('Specified room not found in this college');
      }
      if (roomDoc.status !== 'active' && !roomDoc.isActive) {
        throw ApiError.badRequest(`Room "${roomDoc.code}" is currently inactive or retired`);
      }
      roomNumber = roomDoc.name || roomDoc.code;
      building = roomDoc.building || null;
    }

    // 4. Resolve Active Enrolled Students Roster
    const enrollmentFilter: Record<string, any> = {
      collegeId: new Types.ObjectId(collegeId),
      courseId: fa.courseId,
      semesterId: fa.semesterId,
      academicYearId: fa.academicYearId,
      status: 'active',
    };
    if (fa.sectionId) {
      enrollmentFilter.sectionId = fa.sectionId;
    }

    const activeEnrollments = await StudentEnrollment.find(enrollmentFilter);
    const totalEnrolled = activeEnrollments.length;

    // 5. Create PracticalSession in PLANNED state
    const sessionDate = new Date(scheduledDate);
    if (isNaN(sessionDate.getTime())) {
      throw ApiError.badRequest('Invalid scheduledDate format');
    }

    const session = await PracticalSession.create({
      collegeId: new Types.ObjectId(collegeId),
      departmentId: fa.departmentId,
      courseId: fa.courseId,
      academicYearId: fa.academicYearId,
      semesterId: fa.semesterId,
      sectionId: fa.sectionId || null,
      subjectId: fa.subjectId,
      practicalDefinitionId: practicalDefinitionId && Types.ObjectId.isValid(practicalDefinitionId) ? new Types.ObjectId(practicalDefinitionId) : null,
      facultyAssignmentId: fa._id,
      facultyId: fa.facultyId,
      timetableEntryId: timetableEntryId || null,
      roomId: roomDoc ? roomDoc._id : null,
      roomNumber,
      building,
      sessionNumber: sessionNumber || 1,
      topic: topic.trim(),
      instructions: instructions?.trim() || null,
      scheduledDate: sessionDate,
      startTime: startTime || null,
      endTime: endTime || null,
      status: PracticalSessionStatus.PLANNED,
      totalEnrolled,
      completedCount: 0,
      inProgressCount: 0,
      absentCount: 0,
      createdBy: Types.ObjectId.isValid(user.id) ? new Types.ObjectId(user.id) : null,
      updatedBy: Types.ObjectId.isValid(user.id) ? new Types.ObjectId(user.id) : null,
    });

    // 6. Initialize Participation records for all active enrolled students
    if (activeEnrollments.length > 0) {
      const participationDocs = activeEnrollments.map((enr) => ({
        collegeId: new Types.ObjectId(collegeId),
        practicalSessionId: session._id,
        studentId: enr.studentId,
        studentEnrollmentId: enr._id,
        status: PracticalParticipationStatus.NOT_STARTED,
        notes: null,
      }));

      await PracticalParticipation.insertMany(participationDocs, { ordered: false });
    }

    // 7. Audit Log
    AuditService.logAction({
      collegeId,
      entityType: 'PracticalSession',
      entityId: session._id.toString(),
      action: 'PRACTICAL_SESSION_CREATED',
      actorUserId: user.id || 'system',
      metadata: {
        topic: session.topic,
        subjectId: fa.subjectId.toString(),
        facultyAssignmentId: fa._id.toString(),
        totalEnrolled,
      },
    }).catch((err) => Logger.warn('Failed to audit practical session creation', err));

    // 8. Realtime Event Emission
    realtimeEventBus.publish({
      eventId: new Types.ObjectId().toString(),
      eventVersion: 1,
      eventType: AcadexEventType.PRACTICAL_SESSION_CREATED,
      aggregateType: 'PracticalSession',
      aggregateId: session._id.toString(),
      action: 'CREATED',
      occurredAt: new Date().toISOString(),
      collegeId,
      scope: {
        type: 'department',
        collegeId,
        departmentId: fa.departmentId.toString(),
      },
      payload: {
        sessionId: session._id.toString(),
        topic: session.topic,
        subjectId: fa.subjectId.toString(),
        facultyAssignmentId: fa._id.toString(),
        status: session.status,
        scheduledDate: session.scheduledDate.toISOString(),
      },
    });

    // 9. Persistent Notifications to Enrolled Students
    if (activeEnrollments.length > 0) {
      setImmediate(async () => {
        try {
          const studentIds = activeEnrollments.map((e) => e.studentId);
          const studentDocs = await Student.find({ _id: { $in: studentIds } }, { userId: 1 });
          for (const s of studentDocs) {
            if (s.userId) {
              await NotificationService.createNotification({
                collegeId,
                recipientUserId: s.userId.toString(),
                title: `Practical Session Scheduled: ${session.topic}`,
                body: `Practical lab session for ${subject.name} has been scheduled on ${session.scheduledDate.toLocaleDateString()}.`,
                notificationType: NotificationType.PRACTICAL_SESSION_SCHEDULED,
                metadata: {
                  sessionId: session._id.toString(),
                  subjectId: fa.subjectId.toString(),
                },
              });
            }
          }
        } catch (err) {
          Logger.warn('Failed to notify students of practical session schedule', err);
        }
      });
    }

    return session;
  }

  /**
   * Lists practical sessions matching scope and filters.
   */
  static async listSessions(
    collegeId: string,
    user: AuthUserContext,
    query: {
      facultyAssignmentId?: string;
      subjectId?: string;
      sectionId?: string;
      semesterId?: string;
      status?: string;
      from?: string;
      to?: string;
    }
  ): Promise<IPracticalSession[]> {
    const filter: Record<string, any> = {
      collegeId: new Types.ObjectId(collegeId),
    };

    // Role-based visibility
    if (user.role === 'faculty') {
      const faculty = await TeachingAuthorizationService.resolveFacultyProfile(collegeId, user);
      if (faculty) {
        filter.$or = [
          { facultyId: faculty._id },
          { facultyId: faculty.userId },
        ];
      }
    } else if (user.role === 'hod' && user.departmentId) {
      filter.departmentId = new Types.ObjectId(user.departmentId);
    } else if (user.role === 'student') {
      const student = await Student.findOne({
        collegeId: new Types.ObjectId(collegeId),
        userId: new Types.ObjectId(user.id),
      });
      if (!student) return [];
      const enrollments = await StudentEnrollment.find({
        collegeId: new Types.ObjectId(collegeId),
        studentId: student._id,
        status: 'active',
      });
      if (enrollments.length === 0) return [];

      const orClauses = enrollments.map((enr) => {
        const clause: Record<string, any> = {
          courseId: enr.courseId,
          semesterId: enr.semesterId,
          academicYearId: enr.academicYearId,
        };
        if (enr.sectionId) clause.sectionId = enr.sectionId;
        return clause;
      });
      filter.$or = orClauses;
    }

    if (query.facultyAssignmentId && Types.ObjectId.isValid(query.facultyAssignmentId)) {
      filter.facultyAssignmentId = new Types.ObjectId(query.facultyAssignmentId);
    }
    if (query.subjectId && Types.ObjectId.isValid(query.subjectId)) {
      filter.subjectId = new Types.ObjectId(query.subjectId);
    }
    if (query.sectionId && Types.ObjectId.isValid(query.sectionId)) {
      filter.sectionId = new Types.ObjectId(query.sectionId);
    }
    if (query.semesterId && Types.ObjectId.isValid(query.semesterId)) {
      filter.semesterId = new Types.ObjectId(query.semesterId);
    }
    if (query.status) {
      filter.status = query.status.toUpperCase();
    }
    if (query.from || query.to) {
      filter.scheduledDate = {};
      if (query.from) filter.scheduledDate.$gte = new Date(query.from);
      if (query.to) filter.scheduledDate.$lte = new Date(query.to);
    }

    return PracticalSession.find(filter)
      .populate('subjectId', 'name code type')
      .populate('facultyId', 'name email employeeId')
      .populate('roomId', 'name code building capacity')
      .sort({ scheduledDate: -1, sessionNumber: 1 });
  }

  /**
   * Retrieves a single practical session along with its enrolled roster participation details.
   */
  static async getSessionById(
    collegeId: string,
    user: AuthUserContext,
    sessionId: string
  ): Promise<{
    session: IPracticalSession;
    participations: Array<{
      participationId: string;
      studentId: string;
      studentName: string;
      rollNumber?: string;
      status: PracticalParticipationStatus;
      notes?: string | null;
      startedAt?: Date | null;
      completedAt?: Date | null;
    }>;
  }> {
    if (!Types.ObjectId.isValid(sessionId)) {
      throw ApiError.badRequest('Invalid sessionId format');
    }

    const session = await PracticalSession.findOne({
      _id: new Types.ObjectId(sessionId),
      collegeId: new Types.ObjectId(collegeId),
    })
      .populate('subjectId', 'name code type')
      .populate('facultyId', 'name email employeeId')
      .populate('roomId', 'name code building capacity');

    if (!session) {
      throw ApiError.notFound('Practical session not found');
    }

    // Role security check
    if (user.role === 'faculty') {
      const isOwner = await TeachingAuthorizationService.isFacultyOwner(
        collegeId,
        user,
        { facultyId: session.facultyId } as any
      );
      if (!isOwner) {
        throw ApiError.forbidden('You are not authorized to view another faculty member\'s practical session');
      }
    } else if (user.role === 'hod' && user.departmentId) {
      if (session.departmentId.toString() !== user.departmentId) {
        throw ApiError.forbidden('HOD can only view practical sessions within their own department');
      }
    }

    // Load participation records
    const participations = await PracticalParticipation.find({
      collegeId: new Types.ObjectId(collegeId),
      practicalSessionId: session._id,
    })
      .populate('studentId', 'name rollNumber')
      .sort({ createdAt: 1 });

    const roster = participations.map((p) => {
      const studentObj: any = p.studentId;
      return {
        participationId: p._id.toString(),
        studentId: studentObj?._id ? studentObj._id.toString() : p.studentId.toString(),
        studentName: studentObj?.name || 'Unknown Student',
        rollNumber: studentObj?.rollNumber || undefined,
        status: p.status,
        notes: p.notes,
        startedAt: p.startedAt,
        completedAt: p.completedAt,
      };
    });

    return { session, participations: roster };
  }

  /**
   * Opens a planned practical session for execution.
   */
  static async openSession(
    collegeId: string,
    user: AuthUserContext,
    sessionId: string
  ): Promise<IPracticalSession> {
    if (!Types.ObjectId.isValid(sessionId)) throw ApiError.badRequest('Invalid sessionId format');

    const session = await PracticalSession.findOne({
      _id: new Types.ObjectId(sessionId),
      collegeId: new Types.ObjectId(collegeId),
    });

    if (!session) throw ApiError.notFound('Practical session not found');

    // Assert authorization via FacultyAssignment
    await TeachingAuthorizationService.assertFacultyAssignmentAccess(
      collegeId,
      user,
      session.facultyAssignmentId.toString()
    );

    if (session.status === PracticalSessionStatus.CANCELLED) {
      throw ApiError.badRequest('Cannot open a cancelled practical session');
    }
    if (session.status === PracticalSessionStatus.COMPLETED) {
      throw ApiError.badRequest('This practical session is already completed');
    }

    // Synchronize Roster in case new students enrolled since planning
    const enrollmentFilter: Record<string, any> = {
      collegeId: new Types.ObjectId(collegeId),
      courseId: session.courseId,
      semesterId: session.semesterId,
      academicYearId: session.academicYearId,
      status: 'active',
    };
    if (session.sectionId) enrollmentFilter.sectionId = session.sectionId;

    const activeEnrollments = await StudentEnrollment.find(enrollmentFilter);
    const existingParticipations = await PracticalParticipation.find({
      practicalSessionId: session._id,
    }).select('studentId');
    const existingStudentIds = new Set(existingParticipations.map((p) => p.studentId.toString()));

    const missingEnrollments = activeEnrollments.filter((e) => !existingStudentIds.has(e.studentId.toString()));
    if (missingEnrollments.length > 0) {
      const newDocs = missingEnrollments.map((enr) => ({
        collegeId: new Types.ObjectId(collegeId),
        practicalSessionId: session._id,
        studentId: enr.studentId,
        studentEnrollmentId: enr._id,
        status: PracticalParticipationStatus.NOT_STARTED,
        notes: null,
      }));
      await PracticalParticipation.insertMany(newDocs, { ordered: false });
    }

    session.status = PracticalSessionStatus.OPEN;
    session.actualDate = new Date();
    session.totalEnrolled = activeEnrollments.length;
    session.updatedBy = Types.ObjectId.isValid(user.id) ? new Types.ObjectId(user.id) : null;
    await session.save();

    // Realtime Event
    realtimeEventBus.publish({
      eventId: new Types.ObjectId().toString(),
      eventVersion: 1,
      eventType: AcadexEventType.PRACTICAL_SESSION_OPENED,
      aggregateType: 'PracticalSession',
      aggregateId: session._id.toString(),
      action: 'OPENED',
      occurredAt: new Date().toISOString(),
      collegeId,
      scope: {
        type: 'department',
        collegeId,
        departmentId: session.departmentId.toString(),
      },
      payload: {
        sessionId: session._id.toString(),
        status: session.status,
        topic: session.topic,
      },
    });

    return session;
  }

  /**
   * Updates participation status and notes for a single student.
   */
  static async updateParticipation(
    collegeId: string,
    user: AuthUserContext,
    sessionId: string,
    studentId: string,
    payload: UpdateParticipationPayload
  ): Promise<IPracticalParticipation> {
    if (!Types.ObjectId.isValid(sessionId) || !Types.ObjectId.isValid(studentId)) {
      throw ApiError.badRequest('Invalid sessionId or studentId format');
    }

    const session = await PracticalSession.findOne({
      _id: new Types.ObjectId(sessionId),
      collegeId: new Types.ObjectId(collegeId),
    });

    if (!session) throw ApiError.notFound('Practical session not found');

    await TeachingAuthorizationService.assertFacultyAssignmentAccess(
      collegeId,
      user,
      session.facultyAssignmentId.toString()
    );

    if (session.status === PracticalSessionStatus.CANCELLED) {
      throw ApiError.badRequest('Cannot record participation on a cancelled session');
    }

    let participation = await PracticalParticipation.findOne({
      collegeId: new Types.ObjectId(collegeId),
      practicalSessionId: session._id,
      studentId: new Types.ObjectId(studentId),
    });

    if (!participation) {
      // Find active enrollment
      const enrollment = await StudentEnrollment.findOne({
        collegeId: new Types.ObjectId(collegeId),
        studentId: new Types.ObjectId(studentId),
        courseId: session.courseId,
        semesterId: session.semesterId,
        status: 'active',
      });
      if (!enrollment) {
        throw ApiError.notFound('Student is not enrolled in this practical class roster');
      }

      participation = new PracticalParticipation({
        collegeId: new Types.ObjectId(collegeId),
        practicalSessionId: session._id,
        studentId: new Types.ObjectId(studentId),
        studentEnrollmentId: enrollment._id,
      });
    }

    participation.status = payload.status;
    if (payload.notes !== undefined) participation.notes = payload.notes?.trim() || null;
    if (payload.status === PracticalParticipationStatus.IN_PROGRESS && !participation.startedAt) {
      participation.startedAt = new Date();
    }
    if (payload.status === PracticalParticipationStatus.COMPLETED) {
      if (!participation.startedAt) participation.startedAt = new Date();
      participation.completedAt = new Date();
    } else {
      participation.completedAt = null;
    }
    participation.updatedBy = Types.ObjectId.isValid(user.id) ? new Types.ObjectId(user.id) : null;
    await participation.save();

    // Recalculate summary counters
    await this.recalculateSessionSummary(session._id);

    // Realtime Event
    realtimeEventBus.publish({
      eventId: new Types.ObjectId().toString(),
      eventVersion: 1,
      eventType: AcadexEventType.PRACTICAL_PARTICIPATION_UPDATED,
      aggregateType: 'PracticalParticipation',
      aggregateId: session._id.toString(),
      action: 'BATCH_UPDATED',
      occurredAt: new Date().toISOString(),
      collegeId,
      scope: {
        type: 'user',
        collegeId,
        userId: user.id,
      },
      payload: {
        sessionId: session._id.toString(),
        studentId,
        status: participation.status,
      },
    });

    return participation;
  }

  /**
   * Bulk updates participation states for multiple students in a single atomic/batch operation.
   */
  static async bulkUpdateParticipation(
    collegeId: string,
    user: AuthUserContext,
    sessionId: string,
    updates: BulkParticipationItem[]
  ): Promise<{ updatedCount: number; session: IPracticalSession }> {
    if (!Types.ObjectId.isValid(sessionId)) throw ApiError.badRequest('Invalid sessionId format');
    if (!Array.isArray(updates) || updates.length === 0) {
      throw ApiError.badRequest('Updates array must not be empty');
    }

    const session = await PracticalSession.findOne({
      _id: new Types.ObjectId(sessionId),
      collegeId: new Types.ObjectId(collegeId),
    });

    if (!session) throw ApiError.notFound('Practical session not found');

    await TeachingAuthorizationService.assertFacultyAssignmentAccess(
      collegeId,
      user,
      session.facultyAssignmentId.toString()
    );

    if (session.status === PracticalSessionStatus.CANCELLED) {
      throw ApiError.badRequest('Cannot update participation on a cancelled session');
    }

    const bulkOps = updates.map((item) => {
      if (!Types.ObjectId.isValid(item.studentId)) {
        throw ApiError.badRequest(`Invalid studentId format: ${item.studentId}`);
      }

      const updateFields: Record<string, any> = {
        status: item.status,
        updatedBy: Types.ObjectId.isValid(user.id) ? new Types.ObjectId(user.id) : null,
      };

      if (item.notes !== undefined) {
        updateFields.notes = item.notes?.trim() || null;
      }

      if (item.status === PracticalParticipationStatus.COMPLETED) {
        updateFields.completedAt = new Date();
      } else {
        updateFields.completedAt = null;
      }

      return {
        updateOne: {
          filter: {
            collegeId: new Types.ObjectId(collegeId),
            practicalSessionId: session._id,
            studentId: new Types.ObjectId(item.studentId),
          },
          update: {
            $set: updateFields,
          },
        },
      };
    });

    const result = await PracticalParticipation.bulkWrite(bulkOps);

    // Recalculate summary counters
    await this.recalculateSessionSummary(session._id);

    const refreshedSession = (await PracticalSession.findById(session._id))!;

    // Realtime Event
    realtimeEventBus.publish({
      eventId: new Types.ObjectId().toString(),
      eventVersion: 1,
      eventType: AcadexEventType.PRACTICAL_PARTICIPATION_UPDATED,
      aggregateType: 'PracticalParticipation',
      aggregateId: session._id.toString(),
      action: 'BATCH_UPDATED',
      occurredAt: new Date().toISOString(),
      collegeId,
      scope: {
        type: 'department',
        collegeId,
        departmentId: session.departmentId.toString(),
      },
      payload: {
        sessionId: session._id.toString(),
        totalUpdated: result.modifiedCount,
      },
    });

    return { updatedCount: result.modifiedCount, session: refreshedSession };
  }

  /**
   * Completes and finalizes a practical lab session.
   */
  static async completeSession(
    collegeId: string,
    user: AuthUserContext,
    sessionId: string
  ): Promise<IPracticalSession> {
    if (!Types.ObjectId.isValid(sessionId)) throw ApiError.badRequest('Invalid sessionId format');

    const session = await PracticalSession.findOne({
      _id: new Types.ObjectId(sessionId),
      collegeId: new Types.ObjectId(collegeId),
    });

    if (!session) throw ApiError.notFound('Practical session not found');

    await TeachingAuthorizationService.assertFacultyAssignmentAccess(
      collegeId,
      user,
      session.facultyAssignmentId.toString()
    );

    if (session.status === PracticalSessionStatus.CANCELLED) {
      throw ApiError.badRequest('Cannot complete a cancelled practical session');
    }

    session.status = PracticalSessionStatus.COMPLETED;
    session.updatedBy = Types.ObjectId.isValid(user.id) ? new Types.ObjectId(user.id) : null;
    await session.save();

    await this.recalculateSessionSummary(session._id);

    // Realtime Event
    realtimeEventBus.publish({
      eventId: new Types.ObjectId().toString(),
      eventVersion: 1,
      eventType: AcadexEventType.PRACTICAL_SESSION_COMPLETED,
      aggregateType: 'PracticalSession',
      aggregateId: session._id.toString(),
      action: 'COMPLETED',
      occurredAt: new Date().toISOString(),
      collegeId,
      scope: {
        type: 'department',
        collegeId,
        departmentId: session.departmentId.toString(),
      },
      payload: {
        sessionId: session._id.toString(),
        topic: session.topic,
        status: session.status,
      },
    });

    return session;
  }

  /**
   * Cancels a practical lab session.
   */
  static async cancelSession(
    collegeId: string,
    user: AuthUserContext,
    sessionId: string,
    reason?: string
  ): Promise<IPracticalSession> {
    if (!Types.ObjectId.isValid(sessionId)) throw ApiError.badRequest('Invalid sessionId format');

    const session = await PracticalSession.findOne({
      _id: new Types.ObjectId(sessionId),
      collegeId: new Types.ObjectId(collegeId),
    });

    if (!session) throw ApiError.notFound('Practical session not found');

    await TeachingAuthorizationService.assertFacultyAssignmentAccess(
      collegeId,
      user,
      session.facultyAssignmentId.toString()
    );

    if (session.status === PracticalSessionStatus.COMPLETED) {
      throw ApiError.badRequest('Cannot cancel a session that is already completed');
    }

    session.status = PracticalSessionStatus.CANCELLED;
    if (reason) {
      session.instructions = session.instructions
        ? `${session.instructions}\n[Cancelled]: ${reason.trim()}`
        : `[Cancelled]: ${reason.trim()}`;
    }
    session.updatedBy = Types.ObjectId.isValid(user.id) ? new Types.ObjectId(user.id) : null;
    await session.save();

    // Realtime Event
    realtimeEventBus.publish({
      eventId: new Types.ObjectId().toString(),
      eventVersion: 1,
      eventType: AcadexEventType.PRACTICAL_SESSION_CANCELLED,
      aggregateType: 'PracticalSession',
      aggregateId: session._id.toString(),
      action: 'CANCELLED',
      occurredAt: new Date().toISOString(),
      collegeId,
      scope: {
        type: 'department',
        collegeId,
        departmentId: session.departmentId.toString(),
      },
      payload: {
        sessionId: session._id.toString(),
        status: session.status,
        reason: reason || null,
      },
    });

    return session;
  }

  /**
   * Retrieves practical lab history for a student.
   * Students can strictly view their own records; faculty/admin can inspect student records within authorized scope.
   */
  static async getStudentPracticalHistory(
    collegeId: string,
    user: AuthUserContext,
    targetStudentId?: string,
    query?: { subjectId?: string }
  ): Promise<Array<{
    sessionId: string;
    topic: string;
    sessionNumber: number;
    scheduledDate: Date;
    subjectName: string;
    subjectCode: string;
    sessionStatus: PracticalSessionStatus;
    participationStatus: PracticalParticipationStatus;
    notes?: string | null;
    completedAt?: Date | null;
    roomNumber?: string | null;
  }>> {
    let resolvedStudentId: Types.ObjectId;

    if (user.role === 'student') {
      const student = await Student.findOne({
        collegeId: new Types.ObjectId(collegeId),
        userId: new Types.ObjectId(user.id),
      });
      if (!student) throw ApiError.notFound('Student record not found');
      resolvedStudentId = student._id;
    } else {
      if (!targetStudentId || !Types.ObjectId.isValid(targetStudentId)) {
        throw ApiError.badRequest('targetStudentId is required for non-student inquiries');
      }
      resolvedStudentId = new Types.ObjectId(targetStudentId);
    }

    const filter: Record<string, any> = {
      collegeId: new Types.ObjectId(collegeId),
      studentId: resolvedStudentId,
    };

    const participations = await PracticalParticipation.find(filter)
      .populate({
        path: 'practicalSessionId',
        populate: [
          { path: 'subjectId', select: 'name code' },
          { path: 'roomId', select: 'name code' },
        ],
      })
      .sort({ createdAt: -1 });

    const results = [];
    for (const p of participations) {
      const sess: any = p.practicalSessionId;
      if (!sess) continue;

      if (query?.subjectId && sess.subjectId?._id?.toString() !== query.subjectId) {
        continue;
      }

      results.push({
        sessionId: sess._id.toString(),
        topic: sess.topic,
        sessionNumber: sess.sessionNumber,
        scheduledDate: sess.scheduledDate,
        subjectName: sess.subjectId?.name || 'Practical Subject',
        subjectCode: sess.subjectId?.code || '',
        sessionStatus: sess.status,
        participationStatus: p.status,
        notes: p.notes,
        completedAt: p.completedAt,
        roomNumber: sess.roomNumber || sess.roomId?.name || null,
      });
    }

    return results;
  }

  /**
   * Helper to recalculate session participation counters.
   */
  private static async recalculateSessionSummary(sessionId: Types.ObjectId): Promise<void> {
    const counts = await PracticalParticipation.aggregate([
      { $match: { practicalSessionId: sessionId } },
      { $group: { _id: '$status', count: { $sum: 1 } } },
    ]);

    let completedCount = 0;
    let inProgressCount = 0;
    let absentCount = 0;

    for (const c of counts) {
      if (c._id === PracticalParticipationStatus.COMPLETED) completedCount = c.count;
      else if (c._id === PracticalParticipationStatus.IN_PROGRESS) inProgressCount = c.count;
      else if (c._id === PracticalParticipationStatus.ABSENT) absentCount = c.count;
    }

    await PracticalSession.findByIdAndUpdate(sessionId, {
      completedCount,
      inProgressCount,
      absentCount,
    });
  }
}
