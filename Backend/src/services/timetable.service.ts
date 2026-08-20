import mongoose from 'mongoose';
import { Timetable, ITimetable, ITimetableGridEntry } from '../models/timetable.model';
import { Room, IRoom } from '../models/room.model';
import { Section } from '../models/section.model';
import { Subject } from '../models/subject.model';
import { Faculty } from '../models/faculty.model';
import { Course } from '../models/course.model';
import { AcademicYear } from '../models/academicYear.model';
import { Semester } from '../models/semester.model';
import { Student } from '../models/student.model';
import { StudentEnrollment } from '../models/studentEnrollment.model';
import { AuditLog } from '../models/auditLog.model';
import { College } from '../models/college.model';
import { Department } from '../models/department.model';
import { AppRole } from '../constants/roles';
import { TimetableStatus, TimetableDay, CollegeStatus } from '../constants/status';
import { NotificationService } from './notification.service';
import { NotificationType, NotificationCategory } from '../constants/notification.constants';
import { logger } from '../utils/logger';
import { ApiError } from '../utils/apiError';
import { AuthenticatedUser } from '../types/auth.types';

export function isTimeOverlapping(s1: string, e1: string, s2: string, e2: string): boolean {
  return s1 < e2 && e1 > s2;
}

export function normalizeDay(day?: string): TimetableDay | undefined {
  if (!day) return undefined;
  const lower = day.toLowerCase();
  if (Object.values(TimetableDay).includes(lower as TimetableDay)) {
    return lower as TimetableDay;
  }
  return undefined;
}

export class TimetableService {
  // =========================================================================
  // 1. ROOM MANAGEMENT
  // =========================================================================

  static async createRoom(
    collegeId: string,
    data: { departmentId?: string; name: string; code: string; capacity?: number; type?: string },
    requester: AuthenticatedUser
  ): Promise<IRoom> {
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN].includes(requester.role)) {
      throw ApiError.forbidden('Only administrators have permission to create classrooms/rooms');
    }

    if (requester.role === AppRole.COLLEGE_ADMIN && requester.collegeId !== collegeId) {
      throw ApiError.forbidden('Cross-college room creation is strictly prohibited');
    }

    const college = await College.findById(collegeId);
    if (!college || college.status === CollegeStatus.INACTIVE || !college.isActive) {
      throw ApiError.forbidden('Cannot create room for an inactive college');
    }

    const normalizedCode = data.code.trim().toUpperCase();
    const existing = await Room.findOne({
      collegeId: new mongoose.Types.ObjectId(collegeId),
      code: normalizedCode,
    });
    if (existing) {
      throw ApiError.conflict(`Room with code "${normalizedCode}" already exists in this college`);
    }

    let deptId: mongoose.Types.ObjectId | null = null;
    if (data.departmentId) {
      if (!mongoose.Types.ObjectId.isValid(data.departmentId)) throw ApiError.badRequest('Invalid departmentId');
      const dept = await Department.findById(data.departmentId);
      if (!dept || dept.collegeId.toString() !== collegeId) {
        throw ApiError.badRequest('Department does not belong to the specified college');
      }
      deptId = dept._id;
    }

    const room = await Room.create({
      collegeId: new mongoose.Types.ObjectId(collegeId),
      departmentId: deptId,
      name: data.name.trim(),
      code: normalizedCode,
      capacity: data.capacity || 60,
      type: data.type || 'lecture',
      status: 'active',
      isActive: true,
    });

    await AuditLog.create({
      collegeId,
      actorUserId: requester.id,
      action: 'ROOM_CREATED',
      entityType: 'Room',
      entityId: room.id,
      newValue: room.toJSON(),
    });

    return room;
  }

  static async listRooms(
    requester: AuthenticatedUser,
    query: { collegeId?: string; departmentId?: string; type?: string; search?: string; page?: number; limit?: number } = {}
  ): Promise<{ items: IRoom[]; page: number; limit: number; total: number; totalPages: number }> {
    const mongoQuery: Record<string, unknown> = {};

    if (requester.role !== AppRole.SUPER_ADMIN) {
      if (!requester.collegeId) return { items: [], page: 1, limit: 1, total: 0, totalPages: 0 };
      mongoQuery.collegeId = new mongoose.Types.ObjectId(requester.collegeId);
    } else if (query.collegeId) {
      if (!mongoose.Types.ObjectId.isValid(query.collegeId)) throw ApiError.badRequest('Invalid collegeId');
      mongoQuery.collegeId = new mongoose.Types.ObjectId(query.collegeId);
    }

    if (query.departmentId) {
      if (!mongoose.Types.ObjectId.isValid(query.departmentId)) throw ApiError.badRequest('Invalid departmentId');
      mongoQuery.departmentId = new mongoose.Types.ObjectId(query.departmentId);
    }
    if (query.type) mongoQuery.type = query.type;

    if (query.search && query.search.trim() !== '') {
      const searchRegex = new RegExp(query.search.trim(), 'i');
      mongoQuery.$or = [{ name: searchRegex }, { code: searchRegex }];
    }

    const page = Math.max(1, query.page || 1);
    const limit = Math.min(100, Math.max(1, query.limit || 20));
    const skip = (page - 1) * limit;

    const [items, total] = await Promise.all([
      Room.find(mongoQuery).sort({ code: 1 }).skip(skip).limit(limit),
      Room.countDocuments(mongoQuery),
    ]);

    return { items, page, limit, total, totalPages: Math.ceil(total / limit) };
  }

  static async getRoomById(id: string, requester: AuthenticatedUser): Promise<IRoom> {
    if (!mongoose.Types.ObjectId.isValid(id)) throw ApiError.badRequest('Invalid Room ID');
    const room = await Room.findById(id);
    if (!room) throw ApiError.notFound('Room not found');

    if (requester.role !== AppRole.SUPER_ADMIN && room.collegeId.toString() !== requester.collegeId) {
      throw ApiError.forbidden('Cross-college access is strictly prohibited');
    }

    return room;
  }

  static async updateRoom(
    id: string,
    update: { name?: string; code?: string; capacity?: number; type?: string; isActive?: boolean },
    requester: AuthenticatedUser
  ): Promise<IRoom> {
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN].includes(requester.role)) {
      throw ApiError.forbidden('Unauthorized to update room');
    }

    const room = await this.getRoomById(id, requester);
    const prev = room.toJSON();

    if (update.name) room.name = update.name.trim();
    if (update.capacity) room.capacity = update.capacity;
    if (update.type) room.type = update.type;
    if (update.isActive !== undefined) {
      room.isActive = update.isActive;
      room.status = update.isActive ? 'active' : 'inactive';
    }

    if (update.code) {
      const normalizedCode = update.code.trim().toUpperCase();
      if (normalizedCode !== room.code) {
        const existing = await Room.findOne({
          collegeId: room.collegeId,
          code: normalizedCode,
          _id: { $ne: room._id },
        });
        if (existing) {
          throw ApiError.conflict(`Room code "${normalizedCode}" already exists in this college`);
        }
        room.code = normalizedCode;
      }
    }

    await room.save();

    await AuditLog.create({
      collegeId: room.collegeId.toString(),
      actorUserId: requester.id,
      action: 'ROOM_UPDATED',
      entityType: 'Room',
      entityId: room.id,
      previousValue: prev,
      newValue: room.toJSON(),
    });

    return room;
  }

  // =========================================================================
  // 2. CONFLICT & HIERARCHY VALIDATION
  // =========================================================================

  static async validateAcademicHierarchy(
    collegeId: string,
    data: { departmentId: string; courseId: string; academicYearId: string; semesterId: string; sectionId: string }
  ): Promise<{ section: InstanceType<typeof Section>; semester: InstanceType<typeof Semester> }> {
    const [dept, course, academicYear, semester, section] = await Promise.all([
      Department.findById(data.departmentId),
      Course.findById(data.courseId),
      AcademicYear.findById(data.academicYearId),
      Semester.findById(data.semesterId),
      Section.findById(data.sectionId),
    ]);

    if (!dept) throw ApiError.notFound('Department not found');
    if (!course) throw ApiError.notFound('Course not found');
    if (!academicYear) throw ApiError.notFound('Academic Year not found');
    if (!semester) throw ApiError.notFound('Semester not found');
    if (!section) throw ApiError.notFound('Section not found');

    if (
      dept.collegeId.toString() !== collegeId ||
      course.collegeId.toString() !== collegeId ||
      academicYear.collegeId.toString() !== collegeId ||
      semester.collegeId.toString() !== collegeId ||
      section.collegeId.toString() !== collegeId
    ) {
      throw ApiError.badRequest('Academic hierarchy entities must belong to the specified college');
    }

    if (course.departmentId.toString() !== dept.id) {
      throw ApiError.badRequest('Course does not belong to the specified department');
    }
    if (semester.courseId.toString() !== course.id || semester.academicYearId.toString() !== academicYear.id) {
      throw ApiError.badRequest('Semester does not match the course or academic year');
    }
    if (section.semesterId.toString() !== semester.id || section.courseId.toString() !== course.id) {
      throw ApiError.badRequest('Section does not match the semester or course');
    }

    if (!section.isActive || section.status === 'inactive') {
      throw ApiError.forbidden('Cannot create or publish timetable for an inactive section');
    }

    return { section, semester };
  }

  static async validateTimetableEntries(
    collegeId: string,
    semesterId: string,
    courseId: string,
    section: InstanceType<typeof Section>,
    entries: ITimetableGridEntry[],
    currentTimetableId?: string
  ): Promise<void> {
    // 1. Internal Overlap Checks (within the timetable itself)
    for (let i = 0; i < entries.length; i++) {
      const e1 = entries[i];
      if (e1.startTime >= e1.endTime) {
        throw ApiError.badRequest(`Entry has invalid time range: ${e1.startTime} - ${e1.endTime}`);
      }

      for (let j = i + 1; j < entries.length; j++) {
        const e2 = entries[j];
        if (e1.dayOfWeek === e2.dayOfWeek) {
          const overlaps = isTimeOverlapping(e1.startTime, e1.endTime, e2.startTime, e2.endTime);
          if (overlaps) {
            // Section Conflict
            throw ApiError.conflict(
              `Section conflict: Multiple entries scheduled simultaneously on ${e1.dayOfWeek} (${e1.startTime}-${e1.endTime} and ${e2.startTime}-${e2.endTime})`
            );
          }
        }
      }
    }

    // 2. Validate Subject, Faculty, Room and External Conflicts
    for (const entry of entries) {
      // Validate Subject
      const subject = await Subject.findById(entry.subjectId);
      if (!subject) throw ApiError.notFound(`Subject with ID "${entry.subjectId}" not found`);
      if (subject.collegeId.toString() !== collegeId) {
        throw ApiError.badRequest(`Subject "${subject.code}" does not belong to this college`);
      }
      if (subject.semesterId.toString() !== semesterId.toString()) {
        throw ApiError.badRequest(`Subject "${subject.code}" does not belong to the scheduled semester`);
      }
      if (subject.courseId && subject.courseId.toString() !== courseId.toString()) {
        throw ApiError.badRequest(`Subject "${subject.code}" does not belong to the scheduled course`);
      }

      // Validate Faculty
      const faculty = await Faculty.findById(entry.facultyId);
      if (!faculty) throw ApiError.notFound(`Faculty with ID "${entry.facultyId}" not found`);
      if (faculty.collegeId.toString() !== collegeId) {
        throw ApiError.badRequest(`Faculty "${faculty.name}" does not belong to this college`);
      }

      // Validate Room
      if (entry.roomId) {
        const room = await Room.findById(entry.roomId);
        if (!room) throw ApiError.notFound(`Room with ID "${entry.roomId}" not found`);
        if (room.collegeId.toString() !== collegeId) {
          throw ApiError.badRequest(`Room "${room.code}" does not belong to this college`);
        }
        if (!room.isActive || room.status === 'inactive') {
          throw ApiError.forbidden(`Room "${room.code}" is deactivated and cannot be scheduled`);
        }
        if (room.capacity < section.capacity) {
          throw ApiError.badRequest(
            `Room capacity (${room.capacity}) is insufficient for section capacity (${section.capacity})`
          );
        }
      }

      // 3. External Conflict Detection against other Published Timetables
      const otherPublished = await Timetable.find({
        collegeId: new mongoose.Types.ObjectId(collegeId),
        status: TimetableStatus.PUBLISHED,
        _id: currentTimetableId ? { $ne: new mongoose.Types.ObjectId(currentTimetableId) } : { $exists: true },
        'entries.dayOfWeek': entry.dayOfWeek,
      });

      for (const other of otherPublished) {
        for (const otherEntry of other.entries) {
          if (otherEntry.dayOfWeek === entry.dayOfWeek) {
            const overlaps = isTimeOverlapping(
              entry.startTime,
              entry.endTime,
              otherEntry.startTime,
              otherEntry.endTime
            );
            if (overlaps) {
              // Check Faculty Overlap
              if (otherEntry.facultyId.toString() === entry.facultyId.toString()) {
                throw ApiError.conflict(
                  `Faculty conflict: Faculty member is already scheduled on ${entry.dayOfWeek} between ${otherEntry.startTime} and ${otherEntry.endTime}`
                );
              }
              // Check Room Overlap (if roomId matching or roomNumber matching)
              if (
                (entry.roomId && otherEntry.roomId && entry.roomId.toString() === otherEntry.roomId.toString()) ||
                (entry.roomNumber && otherEntry.roomNumber && entry.roomNumber === otherEntry.roomNumber)
              ) {
                throw ApiError.conflict(
                  `Room conflict: Room is already booked on ${entry.dayOfWeek} between ${otherEntry.startTime} and ${otherEntry.endTime}`
                );
              }
              // Check Section Overlap
              if (other.sectionId.toString() === section.id.toString()) {
                throw ApiError.conflict(
                  `Section conflict: Section is already scheduled on ${entry.dayOfWeek} between ${otherEntry.startTime} and ${otherEntry.endTime}`
                );
              }
            }
          }
        }
      }
    }
  }

  // =========================================================================
  // 3. TIMETABLE CRUD & LIFECYCLE
  // =========================================================================

  static async createTimetable(
    collegeId: string,
    data: Partial<ITimetable> & {
      departmentId?: any;
      courseId?: any;
      academicYearId?: any;
      semesterId?: any;
      sectionId?: any;
    },
    requester?: AuthenticatedUser
  ): Promise<ITimetable> {
    if (requester && ![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD].includes(requester.role)) {
      throw ApiError.forbidden('Only administrators and HODs have permission to create timetables');
    }

    if (requester?.role === AppRole.COLLEGE_ADMIN && requester.collegeId !== collegeId) {
      throw ApiError.forbidden('Cross-college timetable creation is strictly prohibited');
    }

    // Hierarchy validation
    if (data.departmentId && data.courseId && data.academicYearId && data.semesterId && data.sectionId) {
      const deptExists = await Department.findById(data.departmentId);
      if (deptExists) {
        const { section } = await this.validateAcademicHierarchy(collegeId, {
          departmentId: data.departmentId.toString(),
          courseId: data.courseId.toString(),
          academicYearId: data.academicYearId.toString(),
          semesterId: data.semesterId.toString(),
          sectionId: data.sectionId.toString(),
        });

        if (requester?.role === AppRole.HOD && requester.departmentId !== data.departmentId.toString()) {
          throw ApiError.forbidden('HOD can only create timetables within their assigned department');
        }

        // Validate entries if provided
        if (data.entries && data.entries.length > 0) {
          await this.validateTimetableEntries(
            collegeId,
            data.semesterId.toString(),
            data.courseId.toString(),
            section,
            data.entries
          );
        }
      }
    }

    const timetable = await Timetable.create({
      ...data,
      collegeId: new mongoose.Types.ObjectId(collegeId),
      status: data.status || TimetableStatus.DRAFT,
      version: data.version || 1,
    });

    if (requester) {
      await AuditLog.create({
        collegeId,
        actorUserId: requester.id,
        action: 'TIMETABLE_CREATED',
        entityType: 'Timetable',
        entityId: timetable.id,
        newValue: timetable.toJSON(),
      });
    }

    return timetable;
  }

  static async getTimetableById(id: string, collegeId?: string, isSuperAdmin = false): Promise<ITimetable> {
    if (!mongoose.Types.ObjectId.isValid(id)) throw ApiError.badRequest('Invalid Timetable ID');
    const query: Record<string, unknown> = { _id: id };
    if (!isSuperAdmin && collegeId) {
      query.collegeId = collegeId;
    }
    const timetable = await Timetable.findOne(query);
    if (!timetable) {
      throw ApiError.notFound(`Timetable with ID "${id}" not found`);
    }
    return timetable;
  }

  static async listTimetables(
    requester?: AuthenticatedUser,
    query: {
      collegeId?: string;
      departmentId?: string;
      courseId?: string;
      academicYearId?: string;
      semesterId?: string;
      sectionId?: string;
      status?: TimetableStatus;
      page?: number;
      limit?: number;
    } = {}
  ): Promise<{ items: ITimetable[]; page: number; limit: number; total: number; totalPages: number } | ITimetable[]> {
    const mongoQuery: Record<string, unknown> = {};

    if (requester && requester.role !== AppRole.SUPER_ADMIN) {
      if (!requester.collegeId) return { items: [], page: 1, limit: 1, total: 0, totalPages: 0 };
      mongoQuery.collegeId = new mongoose.Types.ObjectId(requester.collegeId);
      if (requester.role === AppRole.HOD && requester.departmentId) {
        mongoQuery.departmentId = new mongoose.Types.ObjectId(requester.departmentId);
      }
    } else if (query.collegeId) {
      if (!mongoose.Types.ObjectId.isValid(query.collegeId)) throw ApiError.badRequest('Invalid collegeId');
      mongoQuery.collegeId = new mongoose.Types.ObjectId(query.collegeId);
    }

    if (query.departmentId) mongoQuery.departmentId = new mongoose.Types.ObjectId(query.departmentId);
    if (query.courseId) mongoQuery.courseId = new mongoose.Types.ObjectId(query.courseId);
    if (query.academicYearId) mongoQuery.academicYearId = new mongoose.Types.ObjectId(query.academicYearId);
    if (query.semesterId) mongoQuery.semesterId = new mongoose.Types.ObjectId(query.semesterId);
    if (query.sectionId) mongoQuery.sectionId = new mongoose.Types.ObjectId(query.sectionId);
    if (query.status) mongoQuery.status = query.status;

    // Backwards-compatibility for unauthenticated direct calls without pagination params
    if (!requester && !query.page && !query.limit) {
      return Timetable.find(mongoQuery).sort({ updatedAt: -1 });
    }

    const page = Math.max(1, query.page || 1);
    const limit = Math.min(100, Math.max(1, query.limit || 20));
    const skip = (page - 1) * limit;

    const [items, total] = await Promise.all([
      Timetable.find(mongoQuery).sort({ updatedAt: -1 }).skip(skip).limit(limit),
      Timetable.countDocuments(mongoQuery),
    ]);

    return { items, page, limit, total, totalPages: Math.ceil(total / limit) };
  }

  static async updateTimetable(
    id: string,
    update: Partial<ITimetable>,
    requester: AuthenticatedUser
  ): Promise<ITimetable> {
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD].includes(requester.role)) {
      throw ApiError.forbidden('Unauthorized to update timetable');
    }

    const timetable = await this.getTimetableById(
      id,
      requester.collegeId,
      requester.role === AppRole.SUPER_ADMIN
    );

    if (requester.role === AppRole.HOD && timetable.departmentId.toString() !== requester.departmentId) {
      throw ApiError.forbidden('Cross-department timetable updates are prohibited');
    }

    if (timetable.status === TimetableStatus.PUBLISHED) {
      throw ApiError.badRequest('Published timetable cannot be directly edited. Please unpublish or revise first.');
    }

    const prev = timetable.toJSON();

    if (update.name) timetable.name = update.name.trim();
    if (update.activeDays) timetable.activeDays = update.activeDays;
    if (update.timingMode) timetable.timingMode = update.timingMode;
    if (update.periods) timetable.periods = update.periods;
    if (update.breaks) timetable.breaks = update.breaks;

    if (update.entries) {
      const section = await Section.findById(timetable.sectionId);
      if (!section) throw ApiError.notFound('Section not found');

      await this.validateTimetableEntries(
        timetable.collegeId.toString(),
        timetable.semesterId.toString(),
        timetable.courseId.toString(),
        section,
        update.entries,
        timetable.id
      );

      timetable.entries = update.entries;
    }

    await timetable.save();

    await AuditLog.create({
      collegeId: timetable.collegeId.toString(),
      actorUserId: requester.id,
      action: 'TIMETABLE_UPDATED',
      entityType: 'Timetable',
      entityId: timetable.id,
      previousValue: prev,
      newValue: timetable.toJSON(),
    });

    return timetable;
  }

  static async publishTimetable(
    id: string,
    publishedBy: string,
    collegeId?: string,
    isSuperAdmin = false,
    requester?: AuthenticatedUser
  ): Promise<ITimetable> {
    const timetable = await this.getTimetableById(id, collegeId, isSuperAdmin);

    if (requester && ![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD].includes(requester.role)) {
      throw ApiError.forbidden('Unauthorized to publish timetables');
    }

    if (timetable.status === TimetableStatus.PUBLISHED) {
      return timetable;
    }

    // Run full conflict validation before publishing if section exists in DB
    const section = await Section.findById(timetable.sectionId);
    if (section) {
      await this.validateAcademicHierarchy(timetable.collegeId.toString(), {
        departmentId: timetable.departmentId.toString(),
        courseId: timetable.courseId.toString(),
        academicYearId: timetable.academicYearId.toString(),
        semesterId: timetable.semesterId.toString(),
        sectionId: timetable.sectionId.toString(),
      });

      if (timetable.entries && timetable.entries.length > 0) {
        await this.validateTimetableEntries(
          timetable.collegeId.toString(),
          timetable.semesterId.toString(),
          timetable.courseId.toString(),
          section,
          timetable.entries,
          timetable.id
        );
      }
    }

    timetable.status = TimetableStatus.PUBLISHED;
    timetable.publishedAt = new Date();
    timetable.publishedBy = publishedBy;
    await timetable.save();

    if (requester) {
      await AuditLog.create({
        collegeId: timetable.collegeId.toString(),
        actorUserId: requester.id,
        action: 'TIMETABLE_PUBLISHED',
        entityType: 'Timetable',
        entityId: timetable.id,
      });
    }

    await this.notifyTimetableRecipients(timetable, NotificationType.TIMETABLE_PUBLISHED).catch((err) =>
      logger.warn(`Failed to notify timetable recipients: ${err.message}`)
    );

    return timetable;
  }

  static async unpublishTimetable(id: string, requester: AuthenticatedUser): Promise<ITimetable> {
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD].includes(requester.role)) {
      throw ApiError.forbidden('Unauthorized to unpublish timetable');
    }

    const timetable = await this.getTimetableById(
      id,
      requester.collegeId,
      requester.role === AppRole.SUPER_ADMIN
    );

    timetable.status = TimetableStatus.DRAFT;
    await timetable.save();

    await AuditLog.create({
      collegeId: timetable.collegeId.toString(),
      actorUserId: requester.id,
      action: 'TIMETABLE_UNPUBLISHED',
      entityType: 'Timetable',
      entityId: timetable.id,
    });

    await this.notifyTimetableRecipients(timetable, NotificationType.TIMETABLE_CANCELLED).catch((err) =>
      logger.warn(`Failed to notify timetable unpublish: ${err.message}`)
    );

    return timetable;
  }

  static async archiveTimetable(id: string, requester: AuthenticatedUser): Promise<ITimetable> {
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD].includes(requester.role)) {
      throw ApiError.forbidden('Unauthorized to archive timetable');
    }

    const timetable = await this.getTimetableById(
      id,
      requester.collegeId,
      requester.role === AppRole.SUPER_ADMIN
    );

    timetable.status = TimetableStatus.ARCHIVED;
    await timetable.save();

    await AuditLog.create({
      collegeId: timetable.collegeId.toString(),
      actorUserId: requester.id,
      action: 'TIMETABLE_ARCHIVED',
      entityType: 'Timetable',
      entityId: timetable.id,
    });

    await this.notifyTimetableRecipients(timetable, NotificationType.TIMETABLE_CANCELLED).catch((err) =>
      logger.warn(`Failed to notify timetable archive: ${err.message}`)
    );

    return timetable;
  }

  // =========================================================================
  // 4. SPECIALIZED TIMETABLE RETRIEVAL
  // =========================================================================

  static async getSectionTimetable(
    sectionId: string,
    day?: string,
    requester?: AuthenticatedUser
  ): Promise<ITimetableGridEntry[]> {
    if (!mongoose.Types.ObjectId.isValid(sectionId)) throw ApiError.badRequest('Invalid sectionId');

    const section = await Section.findById(sectionId);
    if (!section) throw ApiError.notFound('Section not found');

    if (requester && requester.role === AppRole.COLLEGE_ADMIN && section.collegeId.toString() !== requester.collegeId) {
      throw ApiError.forbidden('Cross-college access is strictly prohibited');
    }
    if (requester && requester.role === AppRole.STUDENT) {
      const studentProfile = await Student.findOne({ userId: requester.id });
      if (!studentProfile) throw ApiError.notFound('Student profile not found');
      if (studentProfile.sectionId?.toString() !== sectionId) {
        throw ApiError.forbidden('Students can only view the timetable for their enrolled section');
      }
    }

    const timetable = await Timetable.findOne({
      sectionId: new mongoose.Types.ObjectId(sectionId),
      status: TimetableStatus.PUBLISHED,
    }).sort({ version: -1 });

    if (!timetable) return [];

    let entries = timetable.entries;
    const targetDay = normalizeDay(day);
    if (targetDay) {
      entries = entries.filter((e) => e.dayOfWeek === targetDay);
    }

    return entries.sort((a, b) => a.startTime.localeCompare(b.startTime));
  }

  static async getFacultyTimetable(
    facultyId: string,
    day?: string,
    requester?: AuthenticatedUser
  ): Promise<ITimetableGridEntry[]> {
    if (!mongoose.Types.ObjectId.isValid(facultyId)) throw ApiError.badRequest('Invalid facultyId');

    const faculty = await Faculty.findById(facultyId);
    if (!faculty) throw ApiError.notFound('Faculty not found');

    if (requester && requester.role === AppRole.STUDENT) {
      throw ApiError.forbidden('Students are not permitted to query arbitrary faculty schedules');
    }
    if (requester && requester.role === AppRole.COLLEGE_ADMIN && faculty.collegeId.toString() !== requester.collegeId) {
      throw ApiError.forbidden('Cross-college access is strictly prohibited');
    }

    const timetables = await Timetable.find({
      collegeId: faculty.collegeId,
      status: TimetableStatus.PUBLISHED,
      'entries.facultyId': new mongoose.Types.ObjectId(facultyId),
    });

    const targetDay = normalizeDay(day);
    const entries: ITimetableGridEntry[] = [];
    for (const t of timetables) {
      for (const e of t.entries) {
        if (e.facultyId.toString() === facultyId) {
          if (!targetDay || e.dayOfWeek === targetDay) {
            entries.push(e);
          }
        }
      }
    }

    return entries.sort((a, b) => a.startTime.localeCompare(b.startTime));
  }

  static async getStudentTimetable(
    requester: AuthenticatedUser,
    day?: string
  ): Promise<ITimetableGridEntry[]> {
    if (requester.role !== AppRole.STUDENT) {
      throw ApiError.forbidden('Only students can access this endpoint');
    }

    const studentProfile = await Student.findOne({ userId: requester.id });
    if (!studentProfile) throw ApiError.notFound('Student profile not found');

    // Find current active enrollment
    const activeEnrollment = await StudentEnrollment.findOne({
      studentId: studentProfile._id,
      status: 'active',
    }).sort({ createdAt: -1 });

    const sectionId = activeEnrollment ? activeEnrollment.sectionId : studentProfile.sectionId;
    if (!sectionId) {
      return [];
    }

    return this.getSectionTimetable(sectionId.toString(), day, requester);
  }

  private static async notifyTimetableRecipients(
    timetable: ITimetable,
    notificationType: NotificationType
  ): Promise<void> {
    try {
      const section = await Section.findById(timetable.sectionId);
      const sectionName = section?.name || 'Section';

      // 1. Find enrolled students
      const enrollments = await StudentEnrollment.find({
        collegeId: timetable.collegeId,
        sectionId: timetable.sectionId,
        status: 'active',
      }).select('studentId');

      const studentIds = enrollments.map((e) => e.studentId);
      const students = await Student.find({ _id: { $in: studentIds } }).select('userId');

      const studentUserIds = Array.from(
        new Set(students.map((s) => s.userId?.toString()).filter(Boolean))
      );

      // 2. Find assigned faculty
      const facultyIds = Array.from(
        new Set(timetable.entries.map((e) => e.facultyId?.toString()).filter(Boolean))
      );
      const facultyDocs = await Faculty.find({
        _id: { $in: facultyIds },
      }).select('userId');
      const facultyUserIds = Array.from(
        new Set(facultyDocs.map((f) => f.userId?.toString()).filter(Boolean))
      );

      const notifInputs: any[] = [];

      for (const userId of studentUserIds) {
        notifInputs.push({
          collegeId: timetable.collegeId.toString(),
          departmentId: timetable.departmentId.toString(),
          recipientUserId: userId,
          recipientRole: AppRole.STUDENT,
          title:
            notificationType === NotificationType.TIMETABLE_PUBLISHED
              ? 'New Timetable Published'
              : notificationType === NotificationType.TIMETABLE_UPDATED
              ? 'Timetable Updated'
              : 'Timetable Cancelled',
          body: `Timetable for Section ${sectionName} has been ${
            notificationType === NotificationType.TIMETABLE_PUBLISHED
              ? 'published'
              : notificationType === NotificationType.TIMETABLE_UPDATED
              ? 'updated'
              : 'cancelled'
          }.`,
          notificationType,
          category: NotificationCategory.TIMETABLE,
          entityType: 'Timetable',
          entityId: timetable.id,
          deepLink: '/timetable',
          idempotencyKey: `tt_${notificationType}_${timetable.id}_${userId}_${Date.now().toString().substring(0, 7)}`,
        });
      }

      for (const userId of facultyUserIds) {
        notifInputs.push({
          collegeId: timetable.collegeId.toString(),
          departmentId: timetable.departmentId.toString(),
          recipientUserId: userId,
          recipientRole: AppRole.FACULTY,
          title:
            notificationType === NotificationType.TIMETABLE_PUBLISHED
              ? 'New Timetable Published'
              : notificationType === NotificationType.TIMETABLE_UPDATED
              ? 'Timetable Updated'
              : 'Timetable Cancelled',
          body: `Schedule for Section ${sectionName} has been ${
            notificationType === NotificationType.TIMETABLE_PUBLISHED
              ? 'published'
              : notificationType === NotificationType.TIMETABLE_UPDATED
              ? 'updated'
              : 'cancelled'
          }.`,
          notificationType,
          category: NotificationCategory.TIMETABLE,
          entityType: 'Timetable',
          entityId: timetable.id,
          deepLink: '/timetable',
          idempotencyKey: `tt_${notificationType}_${timetable.id}_${userId}_${Date.now().toString().substring(0, 7)}`,
        });
      }

      if (notifInputs.length > 0) {
        await NotificationService.createBatchNotifications(notifInputs);
      }
    } catch (err) {
      logger.warn(`Failed to dispatch timetable notifications: ${(err as Error).message}`);
    }
  }
}
