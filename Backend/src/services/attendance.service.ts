import mongoose from 'mongoose';
import {
  AttendanceSession,
  IAttendanceSession,
  IAttendanceRecordItem,
} from '../models/attendanceSession.model';
import { AttendanceRecord, IAttendanceRecord } from '../models/attendanceRecord.model';
import { Timetable } from '../models/timetable.model';
import { Section } from '../models/section.model';
import { Subject } from '../models/subject.model';
import { Faculty } from '../models/faculty.model';
import { Student } from '../models/student.model';
import { StudentEnrollment } from '../models/studentEnrollment.model';
import { AuditLog } from '../models/auditLog.model';
import { AppRole } from '../constants/roles';
import {
  AttendanceStatus,
  AttendanceSessionStatus,
  TimetableStatus,
  TimetableDay,
} from '../constants/status';
import { NotificationService } from './notification.service';
import { NotificationType, NotificationCategory } from '../constants/notification.constants';
import { logger } from '../utils/logger';
import { ApiError } from '../utils/apiError';
import { AuthenticatedUser } from '../types/auth.types';

export function getTimetableDayFromDate(date: Date): TimetableDay {
  const days = [
    TimetableDay.SUNDAY,
    TimetableDay.MONDAY,
    TimetableDay.TUESDAY,
    TimetableDay.WEDNESDAY,
    TimetableDay.THURSDAY,
    TimetableDay.FRIDAY,
    TimetableDay.SATURDAY,
  ];
  return days[date.getUTCDay()];
}

export function startOfDay(date: Date): Date {
  const d = new Date(date);
  d.setUTCHours(0, 0, 0, 0);
  return d;
}

export function endOfDay(date: Date): Date {
  const d = new Date(date);
  d.setUTCHours(23, 59, 59, 999);
  return d;
}

export class AttendanceService {
  // =========================================================================
  // 1. SESSION CREATION & TIMETABLE VALIDATION
  // =========================================================================

  static async createOrSubmitSession(
    collegeId: string,
    data: Partial<IAttendanceSession> & { records?: any[] },
    actorUserId?: string,
    requester?: AuthenticatedUser
  ): Promise<IAttendanceSession> {
    if (requester && requester.role === AppRole.COLLEGE_ADMIN && requester.collegeId !== collegeId) {
      throw ApiError.forbidden('Cross-college attendance creation is strictly prohibited');
    }

    const sessionDate = data.date ? new Date(data.date) : new Date();

    let sectionDoc: InstanceType<typeof Section> | null = null;
    let subjectDoc: InstanceType<typeof Subject> | null = null;
    let facultyDoc: InstanceType<typeof Faculty> | null = null;

    if (data.sectionId) {
      sectionDoc = await Section.findById(data.sectionId);
      if (sectionDoc && (!sectionDoc.isActive || sectionDoc.status === 'inactive')) {
        throw ApiError.forbidden('Cannot create attendance session for an inactive section');
      }
      if (sectionDoc && sectionDoc.collegeId.toString() !== collegeId) {
        throw ApiError.badRequest('Section does not belong to the specified college');
      }
    }

    if (data.subjectId) {
      subjectDoc = await Subject.findById(data.subjectId);
      if (subjectDoc && (!subjectDoc.isActive || (subjectDoc as any).status === 'inactive')) {
        throw ApiError.forbidden('Cannot create attendance session for an inactive subject');
      }
      if (subjectDoc && subjectDoc.collegeId.toString() !== collegeId) {
        throw ApiError.badRequest('Subject does not belong to the specified college');
      }
    }

    if (data.facultyId) {
      facultyDoc = await Faculty.findById(data.facultyId);
      if (facultyDoc && (!facultyDoc.isActive || facultyDoc.status === 'inactive')) {
        throw ApiError.forbidden('Cannot create attendance session for an inactive faculty');
      }
    }

    // Timetable Validation
    if (data.timetableId) {
      const timetable = await Timetable.findById(data.timetableId);
      if (!timetable) throw ApiError.notFound('Timetable not found');
      if (timetable.status !== TimetableStatus.PUBLISHED) {
        throw ApiError.badRequest('Attendance session can only be created for a PUBLISHED timetable');
      }
      if (timetable.collegeId.toString() !== collegeId) {
        throw ApiError.badRequest('Timetable does not belong to the specified college');
      }

      // If timetableEntryId is specified, validate day of week and subject/faculty
      if (data.timetableEntryId) {
        const entry = timetable.entries.find(
          (e) => e._id?.toString() === data.timetableEntryId || (e as any).id === data.timetableEntryId
        );
        if (!entry) {
          throw ApiError.badRequest('Timetable entry does not exist in the specified timetable');
        }

        const scheduledDay = entry.dayOfWeek;
        const dateDay = getTimetableDayFromDate(sessionDate);
        if (scheduledDay !== dateDay) {
          throw ApiError.badRequest(
            `Scheduled day mismatch: Timetable entry is for ${scheduledDay}, but date is ${dateDay}`
          );
        }

        if (data.subjectId && entry.subjectId.toString() !== data.subjectId.toString()) {
          throw ApiError.badRequest('Subject mismatch with timetable entry');
        }
        if (data.facultyId && entry.facultyId.toString() !== data.facultyId.toString()) {
          throw ApiError.badRequest('Faculty mismatch with timetable entry');
        }
      }
    }

    // Role-based Department scope check for HOD
    if (requester && requester.role === AppRole.HOD && sectionDoc) {
      if (sectionDoc.departmentId.toString() !== requester.departmentId) {
        throw ApiError.forbidden('HOD can only manage attendance within their assigned department');
      }
    }

    // Check duplicate session for the same section, subject, date, timeSlot
    if (data.sectionId && data.subjectId && data.timeSlot) {
      const existing = await AttendanceSession.findOne({
        collegeId: new mongoose.Types.ObjectId(collegeId),
        sectionId: new mongoose.Types.ObjectId(data.sectionId),
        subjectId: new mongoose.Types.ObjectId(data.subjectId),
        date: sessionDate,
        timeSlot: data.timeSlot,
        status: { $ne: AttendanceSessionStatus.CANCELLED },
      });
      if (existing) {
        throw ApiError.conflict('An active attendance session already exists for this section, subject, date, and timeslot');
      }
    }

    // Roster Validation & Enrollment checks
    const populatedRecords: IAttendanceRecordItem[] = [];
    if (data.records && data.records.length > 0 && data.sectionId) {
      // Find all active enrollments in this section
      const activeEnrollments = await StudentEnrollment.find({
        sectionId: new mongoose.Types.ObjectId(data.sectionId),
        status: 'active',
      });
      const validStudentIds = new Set(activeEnrollments.map((e) => e.studentId.toString()));

      const seenStudents = new Set<string>();
      for (const rec of data.records) {
        const studentIdStr = rec.studentId.toString();
        if (seenStudents.has(studentIdStr)) {
          throw ApiError.conflict(`Duplicate attendance record for student ${studentIdStr}`);
        }
        seenStudents.add(studentIdStr);

        let student = await Student.findById(rec.studentId);
        if (!student && mongoose.Types.ObjectId.isValid(rec.studentId)) {
          student = await Student.findOne({ userId: rec.studentId });
        }

        const resolvedStudentId = student ? student._id : (mongoose.Types.ObjectId.isValid(rec.studentId) ? new mongoose.Types.ObjectId(rec.studentId) : new mongoose.Types.ObjectId());
        const resolvedName = student ? student.name : (rec.studentName || 'Student');
        const resolvedRoll = student ? (student.rollNumber || 'N/A') : (rec.rollNumber || 'N/A');

        // Validate that student is enrolled in this section (if enrollments exist)
        if (student && validStudentIds.size > 0 && !validStudentIds.has(student._id.toString())) {
          throw ApiError.badRequest(`Student "${student.name}" is not enrolled in section "${sectionDoc?.name || data.sectionId}"`);
        }

        populatedRecords.push({
          studentId: resolvedStudentId,
          studentName: resolvedName,
          rollNumber: resolvedRoll,
          sectionId: sectionDoc ? sectionDoc._id : (data.sectionId ? new mongoose.Types.ObjectId(data.sectionId) : new mongoose.Types.ObjectId()),
          status: rec.status || AttendanceStatus.PRESENT,
          remarks: rec.remarks || undefined,
          lastModified: new Date(),
          modifiedBy: actorUserId,
        });
      }
    }

    const session = await AttendanceSession.create({
      ...data,
      collegeId: new mongoose.Types.ObjectId(collegeId),
      departmentId: sectionDoc ? sectionDoc.departmentId : data.departmentId,
      courseId: sectionDoc ? sectionDoc.courseId : data.courseId,
      academicYearId: sectionDoc ? sectionDoc.academicYearId : data.academicYearId,
      semesterId: sectionDoc ? sectionDoc.semesterId : data.semesterId,
      sectionName: sectionDoc ? sectionDoc.name : data.sectionName || 'Section',
      subjectName: subjectDoc ? subjectDoc.name : data.subjectName || 'Subject',
      date: sessionDate,
      records: populatedRecords,
      status: data.status || AttendanceSessionStatus.OPEN,
      createdBy: actorUserId,
      isSubmitted: data.isSubmitted ?? true,
      isLocked: data.isLocked ?? false,
    });

    if (populatedRecords.length > 0) {
      const recordsToInsert = populatedRecords.map((r) => ({
        collegeId: session.collegeId,
        sessionId: session._id,
        studentId: r.studentId,
        studentName: r.studentName,
        rollNumber: r.rollNumber,
        sectionId: session.sectionId,
        subjectId: session.subjectId,
        courseId: session.courseId,
        academicYearId: session.academicYearId,
        semesterId: session.semesterId,
        facultyId: session.facultyId,
        date: sessionDate,
        timeSlot: session.timeSlot || data.timeSlot || '09:00 - 10:00',
        status: r.status,
        oldStatus: r.oldStatus,
        remarks: r.remarks || undefined,
        lastModified: new Date(),
        modifiedBy: actorUserId,
        isCancelled: false,
      }));

      await AttendanceRecord.insertMany(recordsToInsert);
    }

    if (actorUserId) {
      await AuditLog.create({
        collegeId,
        actorUserId,
        action: 'ATTENDANCE_SESSION_CREATED',
        entityType: 'AttendanceSession',
        entityId: session.id,
        newValue: {
          sectionId: session.sectionId?.toString(),
          subjectId: session.subjectId?.toString(),
          date: session.date,
          recordsCount: populatedRecords.length,
        },
      });
    }

    if (populatedRecords.length > 0) {
      await this.dispatchAttendanceNotifications(session, populatedRecords).catch((err) =>
        logger.warn(`Failed to dispatch attendance notifications: ${err.message}`)
      );
    }

    return session;
  }

  // =========================================================================
  // 2. SESSION RETRIEVAL & LISTING
  // =========================================================================

  static async getSessionById(
    id: string,
    collegeId?: string,
    isSuperAdmin = false,
    requester?: AuthenticatedUser
  ): Promise<IAttendanceSession> {
    if (!mongoose.Types.ObjectId.isValid(id)) throw ApiError.badRequest('Invalid Session ID');
    const query: Record<string, unknown> = { _id: id };
    if (!isSuperAdmin && collegeId) {
      query.collegeId = collegeId;
    }
    const session = await AttendanceSession.findOne(query);
    if (!session) {
      throw ApiError.notFound(`Attendance session with ID "${id}" not found`);
    }

    if (requester && requester.role === AppRole.COLLEGE_ADMIN && session.collegeId.toString() !== requester.collegeId) {
      throw ApiError.forbidden('Cross-college access is strictly prohibited');
    }
    if (requester && requester.role === AppRole.HOD && session.departmentId.toString() !== requester.departmentId) {
      throw ApiError.forbidden('Cross-department access is strictly prohibited');
    }

    return session;
  }

  static async listSessions(
    requester?: AuthenticatedUser,
    query: {
      collegeId?: string;
      departmentId?: string;
      courseId?: string;
      academicYearId?: string;
      semesterId?: string;
      sectionId?: string;
      facultyId?: string;
      subjectId?: string;
      from?: Date;
      to?: Date;
      status?: AttendanceSessionStatus;
      page?: number;
      limit?: number;
    } = {}
  ): Promise<{ items: IAttendanceSession[]; page: number; limit: number; total: number; totalPages: number } | IAttendanceSession[]> {
    const filter: Record<string, unknown> = {};

    if (requester && requester.role !== AppRole.SUPER_ADMIN) {
      if (!requester.collegeId) return { items: [], page: 1, limit: 1, total: 0, totalPages: 0 };
      filter.collegeId = new mongoose.Types.ObjectId(requester.collegeId);
      if (requester.role === AppRole.HOD && requester.departmentId) {
        filter.departmentId = new mongoose.Types.ObjectId(requester.departmentId);
      }
    } else if (query.collegeId) {
      if (!mongoose.Types.ObjectId.isValid(query.collegeId)) throw ApiError.badRequest('Invalid collegeId');
      filter.collegeId = new mongoose.Types.ObjectId(query.collegeId);
    }

    if (query.departmentId) filter.departmentId = new mongoose.Types.ObjectId(query.departmentId);
    if (query.courseId) filter.courseId = new mongoose.Types.ObjectId(query.courseId);
    if (query.academicYearId) filter.academicYearId = new mongoose.Types.ObjectId(query.academicYearId);
    if (query.semesterId) filter.semesterId = new mongoose.Types.ObjectId(query.semesterId);
    if (query.sectionId) filter.sectionId = new mongoose.Types.ObjectId(query.sectionId);
    if (query.facultyId) filter.facultyId = new mongoose.Types.ObjectId(query.facultyId);
    if (query.subjectId) filter.subjectId = new mongoose.Types.ObjectId(query.subjectId);
    if (query.status) filter.status = query.status;

    if (query.from || query.to) {
      filter.date = {};
      if (query.from) (filter.date as Record<string, unknown>).$gte = startOfDay(query.from);
      if (query.to) (filter.date as Record<string, unknown>).$lte = endOfDay(query.to);
    }

    if (!requester && !query.page && !query.limit) {
      return AttendanceSession.find(filter).sort({ date: -1 });
    }

    const page = Math.max(1, query.page || 1);
    const limit = Math.min(100, Math.max(1, query.limit || 20));
    const skip = (page - 1) * limit;

    const [items, total] = await Promise.all([
      AttendanceSession.find(filter).sort({ date: -1 }).skip(skip).limit(limit),
      AttendanceSession.countDocuments(filter),
    ]);

    return { items, page, limit, total, totalPages: Math.ceil(total / limit) };
  }

  // =========================================================================
  // 3. MARKING ATTENDANCE & BULK SUBMISSION
  // =========================================================================

  static async submitRecords(
    sessionId: string,
    records: Array<{ studentId: string; status: AttendanceStatus; remarks?: string }>,
    requester: AuthenticatedUser
  ): Promise<IAttendanceSession> {
    const session = await this.getSessionById(sessionId, requester.collegeId, requester.role === AppRole.SUPER_ADMIN, requester);

    if (session.status === AttendanceSessionStatus.LOCKED || session.isLocked) {
      throw ApiError.badRequest('Cannot mark attendance on a LOCKED session');
    }
    if (session.status === AttendanceSessionStatus.CLOSED) {
      throw ApiError.badRequest('Cannot mark attendance on a CLOSED session');
    }
    if (session.status === AttendanceSessionStatus.CANCELLED) {
      throw ApiError.badRequest('Cannot mark attendance on a CANCELLED session');
    }

    // Role check: Faculty can only mark their own sessions unless HOD / Admin
    if (
      requester.role === AppRole.FACULTY &&
      session.facultyId.toString() !== requester.id
    ) {
      const facultyProfile = await Faculty.findOne({ userId: requester.id });
      if (!facultyProfile || session.facultyId.toString() !== facultyProfile._id.toString()) {
        throw ApiError.forbidden('Faculty is not authorized to submit attendance for this session');
      }
    }

    // Validate students belong to the section
    const activeEnrollments = await StudentEnrollment.find({
      sectionId: session.sectionId,
      status: 'active',
    });
    const validStudentIds = new Set(activeEnrollments.map((e) => e.studentId.toString()));

    const populatedItems: IAttendanceRecordItem[] = [];
    const seenStudents = new Set<string>();

    for (const rec of records) {
      const studentIdStr = rec.studentId.toString();
      if (seenStudents.has(studentIdStr)) {
        throw ApiError.conflict(`Duplicate attendance record for student ${studentIdStr}`);
      }
      seenStudents.add(studentIdStr);

      let student = await Student.findById(rec.studentId);
      if (!student) {
        student = await Student.findOne({ userId: rec.studentId });
      }
      if (!student) {
        throw ApiError.notFound(`Student with ID "${rec.studentId}" not found`);
      }

      if (validStudentIds.size > 0 && !validStudentIds.has(student._id.toString())) {
        throw ApiError.badRequest(`Student "${student.name}" is not enrolled in this section`);
      }

      populatedItems.push({
        studentId: student._id,
        studentName: student.name,
        rollNumber: student.rollNumber || 'N/A',
        sectionId: session.sectionId,
        status: rec.status,
        remarks: rec.remarks || undefined,
        lastModified: new Date(),
        modifiedBy: requester.id,
      });
    }

    // Update Session
    session.records = populatedItems;
    session.isSubmitted = true;
    session.lastModifiedBy = requester.id;
    await session.save();

    // Replace granular AttendanceRecord documents for this session
    await AttendanceRecord.deleteMany({ sessionId: session._id });
    const recordsToInsert = populatedItems.map((r) => ({
      collegeId: session.collegeId,
      sessionId: session._id,
      studentId: r.studentId,
      studentName: r.studentName,
      rollNumber: r.rollNumber,
      sectionId: session.sectionId,
      subjectId: session.subjectId,
      courseId: session.courseId,
      academicYearId: session.academicYearId,
      semesterId: session.semesterId,
      facultyId: session.facultyId,
      date: session.date,
      timeSlot: session.timeSlot || '09:00 - 10:00',
      status: r.status,
      remarks: r.remarks || undefined,
      lastModified: new Date(),
      modifiedBy: requester.id,
      isCancelled: false,
    }));
    await AttendanceRecord.insertMany(recordsToInsert);

    await AuditLog.create({
      collegeId: session.collegeId.toString(),
      actorUserId: requester.id,
      action: 'ATTENDANCE_MARKED',
      entityType: 'AttendanceSession',
      entityId: session.id,
      newValue: {
        recordsCount: populatedItems.length,
      },
    });

    return session;
  }

  // =========================================================================
  // 4. LIFECYCLE: LOCK, CLOSE, CANCEL
  // =========================================================================

  static async lockSession(sessionId: string, requester: AuthenticatedUser): Promise<IAttendanceSession> {
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD, AppRole.FACULTY].includes(requester.role)) {
      throw ApiError.forbidden('Unauthorized to lock attendance session');
    }

    const session = await this.getSessionById(sessionId, requester.collegeId, requester.role === AppRole.SUPER_ADMIN, requester);

    session.status = AttendanceSessionStatus.LOCKED;
    session.isLocked = true;
    session.lastModifiedBy = requester.id;
    await session.save();

    await AuditLog.create({
      collegeId: session.collegeId.toString(),
      actorUserId: requester.id,
      action: 'ATTENDANCE_SESSION_LOCKED',
      entityType: 'AttendanceSession',
      entityId: session.id,
    });

    return session;
  }

  static async closeSession(sessionId: string, requester: AuthenticatedUser): Promise<IAttendanceSession> {
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD].includes(requester.role)) {
      throw ApiError.forbidden('Unauthorized to close attendance session');
    }

    const session = await this.getSessionById(sessionId, requester.collegeId, requester.role === AppRole.SUPER_ADMIN, requester);

    session.status = AttendanceSessionStatus.CLOSED;
    session.isLocked = true;
    session.lastModifiedBy = requester.id;
    await session.save();

    await AuditLog.create({
      collegeId: session.collegeId.toString(),
      actorUserId: requester.id,
      action: 'ATTENDANCE_SESSION_CLOSED',
      entityType: 'AttendanceSession',
      entityId: session.id,
    });

    return session;
  }

  static async cancelSession(sessionId: string, requester: AuthenticatedUser): Promise<IAttendanceSession> {
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD].includes(requester.role)) {
      throw ApiError.forbidden('Unauthorized to cancel attendance session');
    }

    const session = await this.getSessionById(sessionId, requester.collegeId, requester.role === AppRole.SUPER_ADMIN, requester);

    session.status = AttendanceSessionStatus.CANCELLED;
    session.lastModifiedBy = requester.id;
    await session.save();

    await AttendanceRecord.updateMany(
      { sessionId: session._id },
      { isCancelled: true }
    );

    await AuditLog.create({
      collegeId: session.collegeId.toString(),
      actorUserId: requester.id,
      action: 'ATTENDANCE_SESSION_CANCELLED',
      entityType: 'AttendanceSession',
      entityId: session.id,
    });

    return session;
  }

  // =========================================================================
  // 5. ATTENDANCE CORRECTION FLOW
  // =========================================================================

  static async correctRecord(
    recordId: string,
    newStatus: AttendanceStatus,
    reason: string,
    requester: AuthenticatedUser
  ): Promise<IAttendanceRecord> {
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD].includes(requester.role)) {
      throw ApiError.forbidden('Only administrators and HODs have permission to correct attendance records');
    }

    if (!mongoose.Types.ObjectId.isValid(recordId)) throw ApiError.badRequest('Invalid Record ID');
    const record = await AttendanceRecord.findById(recordId);
    if (!record) throw ApiError.notFound('Attendance record not found');

    if (requester.role === AppRole.COLLEGE_ADMIN && record.collegeId.toString() !== requester.collegeId) {
      throw ApiError.forbidden('Cross-college attendance correction is strictly prohibited');
    }

    if (requester.role === AppRole.HOD) {
      if (record.collegeId.toString() !== requester.collegeId) {
        throw ApiError.forbidden('Cross-college attendance correction is strictly prohibited');
      }
      const session = await AttendanceSession.findById(record.sessionId);
      if (!session || session.departmentId.toString() !== requester.departmentId) {
        throw ApiError.forbidden('HOD can only correct attendance records within their own department');
      }
    }

    const previousStatus = record.status;
    record.oldStatus = previousStatus;
    record.status = newStatus;
    record.remarks = reason;
    record.lastModified = new Date();
    record.modifiedBy = requester.id;
    await record.save();

    // Also update parent session record item
    await AttendanceSession.updateOne(
      { _id: record.sessionId, 'records.studentId': record.studentId },
      {
        $set: {
          'records.$.oldStatus': previousStatus,
          'records.$.status': newStatus,
          'records.$.remarks': reason,
          'records.$.lastModified': new Date(),
          'records.$.modifiedBy': requester.id,
        },
      }
    );

    await AuditLog.create({
      collegeId: record.collegeId.toString(),
      actorUserId: requester.id,
      action: 'ATTENDANCE_CORRECTED',
      entityType: 'AttendanceRecord',
      entityId: record.id,
      previousValue: { status: previousStatus },
      newValue: {
        status: newStatus,
        reason,
        studentId: record.studentId.toString(),
        sessionId: record.sessionId.toString(),
      },
    });

    return record;
  }

  // =========================================================================
  // 6. STUDENT VIEWS & SUMMARY
  // =========================================================================

  static async getStudentHistory(
    requester: AuthenticatedUser,
    query: { subjectId?: string; semesterId?: string; from?: Date; to?: Date; page?: number; limit?: number } = {}
  ): Promise<{ items: IAttendanceRecord[]; page: number; limit: number; total: number; totalPages: number }> {
    if (requester.role !== AppRole.STUDENT) {
      throw ApiError.forbidden('Only students can access their personal attendance history');
    }

    const studentProfile = await Student.findOne({ userId: requester.id });
    if (!studentProfile) throw ApiError.notFound('Student profile not found');

    const filter: Record<string, unknown> = {
      studentId: studentProfile._id,
      collegeId: studentProfile.collegeId,
      isCancelled: { $ne: true },
    };

    if (query.subjectId) filter.subjectId = new mongoose.Types.ObjectId(query.subjectId);
    if (query.semesterId) filter.semesterId = new mongoose.Types.ObjectId(query.semesterId);
    if (query.from || query.to) {
      filter.date = {};
      if (query.from) (filter.date as Record<string, unknown>).$gte = startOfDay(query.from);
      if (query.to) (filter.date as Record<string, unknown>).$lte = endOfDay(query.to);
    }

    const page = Math.max(1, query.page || 1);
    const limit = Math.min(100, Math.max(1, query.limit || 20));
    const skip = (page - 1) * limit;

    const [items, total] = await Promise.all([
      AttendanceRecord.find(filter)
        .populate('subjectId', 'name code')
        .populate('facultyId', 'name')
        .sort({ date: -1 })
        .skip(skip)
        .limit(limit),
      AttendanceRecord.countDocuments(filter),
    ]);

    return { items, page, limit, total, totalPages: Math.ceil(total / limit) };
  }

  static async getStudentSubjectsBreakdown(
    requester: AuthenticatedUser,
    semesterId?: string
  ): Promise<Array<{
    subjectId: string;
    subjectName: string;
    totalClasses: number;
    presentCount: number;
    lateCount: number;
    absentCount: number;
    excusedCount: number;
    percentage: number;
  }>> {
    if (requester.role !== AppRole.STUDENT) {
      throw ApiError.forbidden('Only students can access their personal subject breakdown');
    }

    const studentProfile = await Student.findOne({ userId: requester.id });
    if (!studentProfile) throw ApiError.notFound('Student profile not found');

    const match: Record<string, unknown> = {
      studentId: studentProfile._id,
      isCancelled: { $ne: true },
    };
    if (semesterId) match.semesterId = new mongoose.Types.ObjectId(semesterId);

    const pipeline = [
      { $match: match },
      {
        $group: {
          _id: '$subjectId',
          totalClasses: { $sum: 1 },
          presentCount: {
            $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.PRESENT] }, 1, 0] },
          },
          lateCount: {
            $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.LATE] }, 1, 0] },
          },
          absentCount: {
            $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.ABSENT] }, 1, 0] },
          },
          excusedCount: {
            $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.EXCUSED] }, 1, 0] },
          },
        },
      },
    ];

    const results = await AttendanceRecord.aggregate(pipeline);
    const subjectsMap = new Map<string, string>();
    const subjectIds = results.map((r) => r._id);
    const subjects = await Subject.find({ _id: { $in: subjectIds } });
    subjects.forEach((s) => subjectsMap.set(s._id.toString(), s.name));

    return results.map((r) => {
      const subjectId = r._id.toString();
      const attended = r.presentCount + r.lateCount;
      const total = r.totalClasses;
      const percentage = total === 0 ? 0 : Math.round((attended / total) * 10000) / 100;
      return {
        subjectId,
        subjectName: subjectsMap.get(subjectId) || 'Subject',
        totalClasses: total,
        presentCount: r.presentCount,
        lateCount: r.lateCount,
        absentCount: r.absentCount,
        excusedCount: r.excusedCount,
        percentage,
      };
    });
  }

  static async getStudentAttendanceSummary(
    collegeId: string,
    studentId: string
  ): Promise<{
    totalClasses: number;
    presentCount: number;
    absentCount: number;
    lateCount: number;
    excusedCount: number;
    percentage: number;
  }> {
    let studentObjId: mongoose.Types.ObjectId | null = null;
    if (mongoose.Types.ObjectId.isValid(studentId)) {
      const student = await Student.findOne({
        $or: [
          { _id: new mongoose.Types.ObjectId(studentId) },
          { userId: new mongoose.Types.ObjectId(studentId) },
        ],
      });
      if (student) {
        studentObjId = student._id;
      } else {
        studentObjId = new mongoose.Types.ObjectId(studentId);
      }
    } else {
      const student = await Student.findOne({ userId: studentId });
      if (student) {
        studentObjId = student._id;
      }
    }

    if (!studentObjId) {
      return { totalClasses: 0, presentCount: 0, absentCount: 0, lateCount: 0, excusedCount: 0, percentage: 0 };
    }

    const records = await AttendanceRecord.find({
      collegeId: new mongoose.Types.ObjectId(collegeId),
      studentId: studentObjId,
      isCancelled: { $ne: true },
    });

    const totalClasses = records.length;
    if (totalClasses === 0) {
      return { totalClasses: 0, presentCount: 0, absentCount: 0, lateCount: 0, excusedCount: 0, percentage: 0 };
    }

    const presentCount = records.filter((r) => r.status === AttendanceStatus.PRESENT).length;
    const lateCount = records.filter((r) => r.status === AttendanceStatus.LATE).length;
    const absentCount = records.filter((r) => r.status === AttendanceStatus.ABSENT).length;
    const excusedCount = records.filter((r) => r.status === AttendanceStatus.EXCUSED).length;
    const percentage = Math.round(((presentCount + lateCount) / totalClasses) * 10000) / 100;

    return {
      totalClasses,
      presentCount,
      absentCount,
      lateCount,
      excusedCount,
      percentage,
    };
  }

  // =========================================================================
  // 7. SECTION & FACULTY AGGREGATES
  // =========================================================================

  static async getSectionAttendance(
    sectionId: string,
    requester: AuthenticatedUser
  ): Promise<{
    sectionId: string;
    totalSessions: number;
    totalRecords: number;
    presentCount: number;
    lateCount: number;
    absentCount: number;
    percentage: number;
    students: Array<{ studentId: string; studentName: string; rollNumber: string; percentage: number }>;
  }> {
    if (!mongoose.Types.ObjectId.isValid(sectionId)) throw ApiError.badRequest('Invalid sectionId');
    const section = await Section.findById(sectionId);
    if (!section) throw ApiError.notFound('Section not found');

    if (requester.role === AppRole.COLLEGE_ADMIN && section.collegeId.toString() !== requester.collegeId) {
      throw ApiError.forbidden('Cross-college access is strictly prohibited');
    }
    if (requester.role === AppRole.HOD && section.departmentId.toString() !== requester.departmentId) {
      throw ApiError.forbidden('Cross-department access is strictly prohibited');
    }

    const records = await AttendanceRecord.find({
      sectionId: new mongoose.Types.ObjectId(sectionId),
      isCancelled: { $ne: true },
    });

    const sessionsCount = await AttendanceSession.countDocuments({
      sectionId: new mongoose.Types.ObjectId(sectionId),
      status: { $ne: AttendanceSessionStatus.CANCELLED },
    });

    const totalRecords = records.length;
    const presentCount = records.filter((r) => r.status === AttendanceStatus.PRESENT).length;
    const lateCount = records.filter((r) => r.status === AttendanceStatus.LATE).length;
    const absentCount = records.filter((r) => r.status === AttendanceStatus.ABSENT).length;
    const percentage = totalRecords === 0 ? 0 : Math.round(((presentCount + lateCount) / totalRecords) * 10000) / 100;

    // Student-wise breakdown
    const studentMap = new Map<string, { studentName: string; rollNumber: string; attended: number; total: number }>();
    records.forEach((r) => {
      const sid = r.studentId.toString();
      const current = studentMap.get(sid) || {
        studentName: r.studentName,
        rollNumber: r.rollNumber,
        attended: 0,
        total: 0,
      };
      current.total += 1;
      if (r.status === AttendanceStatus.PRESENT || r.status === AttendanceStatus.LATE) {
        current.attended += 1;
      }
      studentMap.set(sid, current);
    });

    const students = Array.from(studentMap.entries()).map(([studentId, data]) => ({
      studentId,
      studentName: data.studentName,
      rollNumber: data.rollNumber,
      percentage: data.total === 0 ? 0 : Math.round((data.attended / data.total) * 10000) / 100,
    }));

    return {
      sectionId,
      totalSessions: sessionsCount,
      totalRecords,
      presentCount,
      lateCount,
      absentCount,
      percentage,
      students,
    };
  }

  static async getFacultySessions(
    requester: AuthenticatedUser
  ): Promise<IAttendanceSession[]> {
    if (requester.role !== AppRole.FACULTY) {
      throw ApiError.forbidden('Only faculty can access their sessions via this endpoint');
    }

    const faculty = await Faculty.findOne({ userId: requester.id });
    if (!faculty) throw ApiError.notFound('Faculty profile not found');

    return AttendanceSession.find({
      facultyId: faculty._id,
      collegeId: faculty.collegeId,
    }).sort({ date: -1 });
  }

  // =========================================================================
  // 8. COMPREHENSIVE ATTENDANCE ANALYTICS
  // =========================================================================

  static async getAttendanceAnalytics(
    requester: AuthenticatedUser,
    query: {
      collegeId?: string;
      departmentId?: string;
      courseId?: string;
      academicYearId?: string;
      semesterId?: string;
      sectionId?: string;
      subjectId?: string;
      facultyId?: string;
      from?: Date;
      to?: Date;
      threshold?: number;
    } = {}
  ): Promise<{
    overallPercentage: number;
    totalSessions: number;
    totalRecords: number;
    presentCount: number;
    lateCount: number;
    absentCount: number;
    excusedCount: number;
    lowAttendanceThreshold: number;
    lowAttendanceCount: number;
    lowAttendanceStudents: Array<{
      studentId: string;
      studentName: string;
      rollNumber: string;
      totalClasses: number;
      attended: number;
      percentage: number;
    }>;
  }> {
    const match: Record<string, unknown> = {
      isCancelled: { $ne: true },
    };

    if (requester.role !== AppRole.SUPER_ADMIN) {
      if (!requester.collegeId) throw ApiError.forbidden('College scope is required');
      match.collegeId = new mongoose.Types.ObjectId(requester.collegeId);
      if (requester.role === AppRole.HOD && requester.departmentId) {
        match.departmentId = new mongoose.Types.ObjectId(requester.departmentId);
      }
    } else if (query.collegeId) {
      match.collegeId = new mongoose.Types.ObjectId(query.collegeId);
    }

    if (query.departmentId) match.departmentId = new mongoose.Types.ObjectId(query.departmentId);
    if (query.courseId) match.courseId = new mongoose.Types.ObjectId(query.courseId);
    if (query.academicYearId) match.academicYearId = new mongoose.Types.ObjectId(query.academicYearId);
    if (query.semesterId) match.semesterId = new mongoose.Types.ObjectId(query.semesterId);
    if (query.sectionId) match.sectionId = new mongoose.Types.ObjectId(query.sectionId);
    if (query.subjectId) match.subjectId = new mongoose.Types.ObjectId(query.subjectId);
    if (query.facultyId) match.facultyId = new mongoose.Types.ObjectId(query.facultyId);

    if (query.from || query.to) {
      match.date = {};
      if (query.from) (match.date as Record<string, unknown>).$gte = startOfDay(query.from);
      if (query.to) (match.date as Record<string, unknown>).$lte = endOfDay(query.to);
    }

    const threshold = query.threshold !== undefined ? query.threshold : 75;

    const [aggregateStats, studentStats, totalSessions] = await Promise.all([
      AttendanceRecord.aggregate([
        { $match: match },
        {
          $group: {
            _id: null,
            totalRecords: { $sum: 1 },
            presentCount: { $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.PRESENT] }, 1, 0] } },
            lateCount: { $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.LATE] }, 1, 0] } },
            absentCount: { $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.ABSENT] }, 1, 0] } },
            excusedCount: { $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.EXCUSED] }, 1, 0] } },
          },
        },
      ]),
      AttendanceRecord.aggregate([
        { $match: match },
        {
          $group: {
            _id: '$studentId',
            studentName: { $first: '$studentName' },
            rollNumber: { $first: '$rollNumber' },
            totalClasses: { $sum: 1 },
            attended: {
              $sum: {
                $cond: [
                  { $in: ['$status', [AttendanceStatus.PRESENT, AttendanceStatus.LATE]] },
                  1,
                  0,
                ],
              },
            },
          },
        },
      ]),
      AttendanceSession.countDocuments({
        ...match,
        status: { $ne: AttendanceSessionStatus.CANCELLED },
      }),
    ]);

    const stats = aggregateStats[0] || {
      totalRecords: 0,
      presentCount: 0,
      lateCount: 0,
      absentCount: 0,
      excusedCount: 0,
    };

    const overallPercentage =
      stats.totalRecords === 0
        ? 0
        : Math.round(((stats.presentCount + stats.lateCount) / stats.totalRecords) * 10000) / 100;

    const lowAttendanceStudents: Array<{
      studentId: string;
      studentName: string;
      rollNumber: string;
      totalClasses: number;
      attended: number;
      percentage: number;
    }> = [];

    studentStats.forEach((s) => {
      const percentage = s.totalClasses === 0 ? 0 : Math.round((s.attended / s.totalClasses) * 10000) / 100;
      if (percentage < threshold) {
        lowAttendanceStudents.push({
          studentId: s._id.toString(),
          studentName: s.studentName,
          rollNumber: s.rollNumber,
          totalClasses: s.totalClasses,
          attended: s.attended,
          percentage,
        });
      }
    });

    return {
      overallPercentage,
      totalSessions,
      totalRecords: stats.totalRecords,
      presentCount: stats.presentCount,
      lateCount: stats.lateCount,
      absentCount: stats.absentCount,
      excusedCount: stats.excusedCount,
      lowAttendanceThreshold: threshold,
      lowAttendanceCount: lowAttendanceStudents.length,
      lowAttendanceStudents,
    };
  }

  private static async dispatchAttendanceNotifications(
    session: IAttendanceSession,
    records: IAttendanceRecordItem[]
  ): Promise<void> {
    try {
      const studentIds = records.map((r) => r.studentId);
      const students = await Student.find({ _id: { $in: studentIds } }).select('userId');
      const studentMap = new Map<string, string>();
      students.forEach((s) => {
        if (s.userId) studentMap.set(s._id.toString(), s.userId.toString());
      });

      const notifInputs: any[] = [];

      for (const record of records) {
        const userId = studentMap.get(record.studentId.toString());
        if (!userId) continue;

        if (record.status === AttendanceStatus.ABSENT || record.status === AttendanceStatus.LATE) {
          notifInputs.push({
            collegeId: session.collegeId.toString(),
            departmentId: session.departmentId?.toString(),
            recipientUserId: userId,
            recipientRole: AppRole.STUDENT,
            title: record.status === AttendanceStatus.ABSENT ? 'Marked Absent' : 'Marked Late',
            body: `You were marked ${record.status} for ${session.subjectName || 'Class'} on ${new Date(
              session.date
            ).toLocaleDateString()}.`,
            notificationType: NotificationType.ATTENDANCE_MARKED,
            category: NotificationCategory.ATTENDANCE,
            entityType: 'AttendanceSession',
            entityId: session.id,
            deepLink: '/attendance',
            idempotencyKey: `att_${session.id}_${userId}_${record.status}`,
          });
        }
      }

      if (notifInputs.length > 0) {
        await NotificationService.createBatchNotifications(notifInputs);
      }
    } catch (err) {
      logger.warn(`Failed to dispatch attendance notifications: ${(err as Error).message}`);
    }
  }
}
