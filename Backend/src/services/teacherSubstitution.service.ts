import mongoose from 'mongoose';
import {
  TeacherSubstitution,
  ITeacherSubstitution,
  TeacherSubstitutionStatus,
} from '../models/teacherSubstitution.model';
import { Timetable } from '../models/timetable.model';
import { Faculty } from '../models/faculty.model';
import { College } from '../models/college.model';
import { CalendarOverrideService } from './calendarOverride.service';
import { CalendarOverrideType } from '../models/calendarOverride.model';
import { AppRole } from '../constants/roles';
import { TimetableStatus } from '../constants/status';
import { AuthenticatedUser } from '../types/auth.types';
import { ApiError } from '../utils/apiError';
import {
  DEFAULT_INSTITUTION_TIMEZONE,
  formatDateToCalendarString,
  getTimetableDayFromDate,
  isTimeOverlapping,
} from '../utils/dateTime';

export class TeacherSubstitutionService {
  /**
   * Resolves the active teacher substitution for a specific timetable entry and calendar date.
   */
  static async resolveActiveSubstitution(params: {
    timetableId: mongoose.Types.ObjectId | string;
    timetableEntryId?: mongoose.Types.ObjectId | string | null;
    date: string;
  }): Promise<ITeacherSubstitution | null> {
    if (!params.timetableEntryId) return null;
    return TeacherSubstitution.findOne({
      timetableId: new mongoose.Types.ObjectId(params.timetableId.toString()),
      timetableEntryId: new mongoose.Types.ObjectId(params.timetableEntryId.toString()),
      date: params.date,
      status: TeacherSubstitutionStatus.ACTIVE,
    });
  }

  /**
   * Checks whether the substitute faculty has an operational schedule conflict on this date/time.
   */
  static async checkSubstituteConflict(params: {
    collegeId: mongoose.Types.ObjectId | string;
    substituteFacultyId: mongoose.Types.ObjectId | string;
    date: string;
    startTime: string;
    endTime: string;
    excludeSubstitutionId?: mongoose.Types.ObjectId | string;
    excludeEntryId?: mongoose.Types.ObjectId | string;
  }): Promise<void> {
    const collegeDoc = await College.findById(params.collegeId);
    const tz = collegeDoc?.timezone || DEFAULT_INSTITUTION_TIMEZONE;
    const dateDay = getTimetableDayFromDate(params.date, tz);

    // 1. Check published recurring timetable entries where substitute is the assigned faculty
    const publishedTimetables = await Timetable.find({
      collegeId: new mongoose.Types.ObjectId(params.collegeId.toString()),
      status: TimetableStatus.PUBLISHED,
      'entries.facultyId': new mongoose.Types.ObjectId(params.substituteFacultyId.toString()),
      'entries.dayOfWeek': dateDay,
    });

    for (const tt of publishedTimetables) {
      for (const entry of tt.entries) {
        if (
          entry.facultyId.toString() === params.substituteFacultyId.toString() &&
          entry.dayOfWeek === dateDay
        ) {
          if (params.excludeEntryId && entry._id?.toString() === params.excludeEntryId.toString()) {
            continue;
          }

          // Check if this class is cancelled or a holiday on this date
          const activeOverride = await CalendarOverrideService.resolveActiveOverride({
            collegeId: tt.collegeId,
            departmentId: tt.departmentId,
            sectionId: tt.sectionId,
            timetableEntryId: entry._id,
            date: params.date,
          });

          if (activeOverride) {
            // Cancelled or holiday - class is not operational on this date
            continue;
          }

          // Check if substitute faculty was replaced by another substitute in their own class on this date
          const replacedSub = await TeacherSubstitution.findOne({
            timetableId: tt._id,
            timetableEntryId: entry._id,
            date: params.date,
            status: TeacherSubstitutionStatus.ACTIVE,
          });
          if (replacedSub && replacedSub.substituteFacultyId.toString() !== params.substituteFacultyId.toString()) {
            // Substitute faculty was replaced in this class on this date
            continue;
          }

          if (isTimeOverlapping(params.startTime, params.endTime, entry.startTime, entry.endTime)) {
            throw ApiError.conflict(
              `Substitute faculty has a schedule conflict with another class (${entry.startTime} - ${entry.endTime}) on this date`
            );
          }
        }
      }
    }

    // 2. Check existing active substitutions where substitute faculty is already acting as substitute on this date
    const existingSubQuery: Record<string, any> = {
      collegeId: new mongoose.Types.ObjectId(params.collegeId.toString()),
      substituteFacultyId: new mongoose.Types.ObjectId(params.substituteFacultyId.toString()),
      date: params.date,
      status: TeacherSubstitutionStatus.ACTIVE,
    };

    if (params.excludeSubstitutionId) {
      existingSubQuery._id = { $ne: new mongoose.Types.ObjectId(params.excludeSubstitutionId.toString()) };
    }

    const otherSubs = await TeacherSubstitution.find(existingSubQuery);
    for (const otherSub of otherSubs) {
      const otherTt = await Timetable.findById(otherSub.timetableId);
      if (!otherTt) continue;
      const otherEntry = otherTt.entries.find(
        (e) => e._id?.toString() === otherSub.timetableEntryId.toString()
      );
      if (!otherEntry) continue;

      // Check if that other substituted class was cancelled or a holiday on this date
      const otherOverride = await CalendarOverrideService.resolveActiveOverride({
        collegeId: otherTt.collegeId,
        departmentId: otherTt.departmentId,
        sectionId: otherTt.sectionId,
        timetableEntryId: otherEntry._id,
        date: params.date,
      });
      if (otherOverride) continue;

      if (isTimeOverlapping(params.startTime, params.endTime, otherEntry.startTime, otherEntry.endTime)) {
        throw ApiError.conflict(
          `Substitute faculty is already assigned as a substitute for another overlapping class (${otherEntry.startTime} - ${otherEntry.endTime}) on this date`
        );
      }
    }
  }

  /**
   * Creates a new date-specific teacher substitution.
   */
  static async createSubstitution(
    data: {
      timetableId: string;
      timetableEntryId: string;
      date: string;
      substituteFacultyId: string;
      originalFacultyId?: string;
      reason: string;
    },
    requester: AuthenticatedUser
  ): Promise<ITeacherSubstitution> {
    // 1. Authorization: Only SUPER_ADMIN, COLLEGE_ADMIN, and HOD can manage substitutions
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD].includes(requester.role)) {
      throw ApiError.forbidden('Only administrators and HODs are permitted to manage teacher substitutions');
    }

    // 2. Resolve target Timetable
    const timetable = await Timetable.findById(data.timetableId);
    if (!timetable) {
      throw ApiError.notFound('Timetable not found');
    }

    if (timetable.status !== TimetableStatus.PUBLISHED) {
      throw ApiError.badRequest('Substitutions can only be created for PUBLISHED timetables');
    }

    // Tenant / College verification
    if (requester.role !== AppRole.SUPER_ADMIN && requester.collegeId && timetable.collegeId.toString() !== requester.collegeId) {
      throw ApiError.forbidden('Cross-college teacher substitution is strictly prohibited');
    }

    // Department verification for HOD
    if (requester.role === AppRole.HOD && requester.departmentId && timetable.departmentId.toString() !== requester.departmentId) {
      throw ApiError.forbidden('HOD can only manage teacher substitutions within their assigned department');
    }

    // 3. Resolve target timetable entry
    const entry = timetable.entries.find(
      (e) => e._id?.toString() === data.timetableEntryId
    );
    if (!entry) {
      throw ApiError.badRequest('Timetable entry does not belong to the specified timetable');
    }

    const authoritativeOriginalFacultyId = entry.facultyId;

    // Verify client-supplied originalFacultyId if provided
    if (data.originalFacultyId && data.originalFacultyId !== authoritativeOriginalFacultyId.toString()) {
      throw ApiError.badRequest('Provided original faculty ID does not match authoritative timetable entry');
    }

    // 4. Resolve institution timezone & date
    const collegeDoc = await College.findById(timetable.collegeId);
    const tz = collegeDoc?.timezone || DEFAULT_INSTITUTION_TIMEZONE;
    const canonicalDateStr = formatDateToCalendarString(data.date, tz);
    const dateDay = getTimetableDayFromDate(data.date, tz);

    if (entry.dayOfWeek !== dateDay) {
      throw ApiError.badRequest(
        `Scheduled day mismatch: Timetable entry is for ${entry.dayOfWeek}, but date is ${dateDay}`
      );
    }

    // 5. Calendar Override Check: CANCELLED or HOLIDAY takes precedence
    const activeOverride = await CalendarOverrideService.resolveActiveOverride({
      collegeId: timetable.collegeId,
      departmentId: timetable.departmentId,
      sectionId: timetable.sectionId,
      timetableEntryId: entry._id,
      date: canonicalDateStr,
    });

    if (activeOverride) {
      if (activeOverride.type === CalendarOverrideType.HOLIDAY) {
        throw ApiError.badRequest(
          `Cannot create substitution: The selected date is a declared holiday (${activeOverride.reason})`
        );
      } else if (activeOverride.type === CalendarOverrideType.CANCELLED) {
        throw ApiError.badRequest(
          `Cannot create substitution: Class has been cancelled for this date (${activeOverride.reason})`
        );
      }
    }

    // 6. Check duplicate active substitution
    const existingActive = await TeacherSubstitution.findOne({
      timetableId: timetable._id,
      timetableEntryId: entry._id,
      date: canonicalDateStr,
      status: TeacherSubstitutionStatus.ACTIVE,
    });
    if (existingActive) {
      throw ApiError.conflict('An active substitution already exists for this class on this date');
    }

    // 7. Validate substitute faculty
    const substituteFaculty = await Faculty.findById(data.substituteFacultyId);
    if (!substituteFaculty) {
      throw ApiError.notFound('Substitute faculty not found');
    }

    if (!substituteFaculty.isActive || substituteFaculty.status !== 'active') {
      throw ApiError.badRequest('Substitute faculty is inactive');
    }

    if (substituteFaculty.collegeId.toString() !== timetable.collegeId.toString()) {
      throw ApiError.forbidden('Cross-college teacher substitution is strictly prohibited');
    }

    if (requester.role === AppRole.HOD && requester.departmentId && substituteFaculty.departmentId.toString() !== requester.departmentId) {
      throw ApiError.forbidden('HOD can only assign substitute faculty from their assigned department');
    }

    if (substituteFaculty._id.toString() === authoritativeOriginalFacultyId.toString()) {
      throw ApiError.badRequest('Substitute faculty cannot be the same as the original faculty');
    }

    // 8. Substitution Conflict Check: verify substitute is not double-booked
    await this.checkSubstituteConflict({
      collegeId: timetable.collegeId,
      substituteFacultyId: substituteFaculty._id,
      date: canonicalDateStr,
      startTime: entry.startTime,
      endTime: entry.endTime,
      excludeEntryId: entry._id,
    });

    // 9. Persist TeacherSubstitution
    const substitution = await TeacherSubstitution.create({
      collegeId: timetable.collegeId,
      departmentId: timetable.departmentId,
      sectionId: timetable.sectionId,
      timetableId: timetable._id,
      timetableEntryId: entry._id,
      date: canonicalDateStr,
      originalFacultyId: authoritativeOriginalFacultyId,
      substituteFacultyId: substituteFaculty._id,
      reason: data.reason.trim(),
      status: TeacherSubstitutionStatus.ACTIVE,
      createdBy: new mongoose.Types.ObjectId(requester.id),
    });

    return substitution;
  }

  /**
   * List substitutions with filtering.
   */
  static async listSubstitutions(
    query: {
      collegeId?: string;
      departmentId?: string;
      date?: string;
      timetableId?: string;
      timetableEntryId?: string;
      substituteFacultyId?: string;
      status?: TeacherSubstitutionStatus;
    },
    requester: AuthenticatedUser
  ): Promise<ITeacherSubstitution[]> {
    const filter: Record<string, any> = {};

    if (requester.role !== AppRole.SUPER_ADMIN && requester.collegeId) {
      filter.collegeId = new mongoose.Types.ObjectId(requester.collegeId);
    } else if (query.collegeId) {
      filter.collegeId = new mongoose.Types.ObjectId(query.collegeId);
    }

    if (requester.role === AppRole.HOD && requester.departmentId) {
      filter.departmentId = new mongoose.Types.ObjectId(requester.departmentId);
    } else if (query.departmentId) {
      filter.departmentId = new mongoose.Types.ObjectId(query.departmentId);
    }

    if (query.date) filter.date = query.date;
    if (query.timetableId) filter.timetableId = new mongoose.Types.ObjectId(query.timetableId);
    if (query.timetableEntryId) filter.timetableEntryId = new mongoose.Types.ObjectId(query.timetableEntryId);
    if (query.substituteFacultyId) filter.substituteFacultyId = new mongoose.Types.ObjectId(query.substituteFacultyId);
    if (query.status) filter.status = query.status;

    return TeacherSubstitution.find(filter)
      .populate('originalFacultyId', 'name employeeId email designation')
      .populate('substituteFacultyId', 'name employeeId email designation')
      .sort({ date: 1, createdAt: -1 });
  }

  /**
   * Get single substitution by ID.
   */
  static async getSubstitutionById(
    id: string,
    requester: AuthenticatedUser
  ): Promise<ITeacherSubstitution> {
    if (!mongoose.Types.ObjectId.isValid(id)) {
      throw ApiError.badRequest('Invalid substitution ID');
    }

    const substitution = await TeacherSubstitution.findById(id)
      .populate('originalFacultyId', 'name employeeId email designation')
      .populate('substituteFacultyId', 'name employeeId email designation');

    if (!substitution) {
      throw ApiError.notFound('Teacher substitution not found');
    }

    if (requester.role !== AppRole.SUPER_ADMIN && requester.collegeId && substitution.collegeId.toString() !== requester.collegeId) {
      throw ApiError.forbidden('Cross-college access is strictly prohibited');
    }

    if (requester.role === AppRole.HOD && requester.departmentId && substitution.departmentId.toString() !== requester.departmentId) {
      throw ApiError.forbidden('HOD can only view substitutions within their assigned department');
    }

    return substitution;
  }

  /**
   * Delete substitution, restoring operational teacher to original faculty for that date.
   */
  static async deleteSubstitution(
    id: string,
    requester: AuthenticatedUser
  ): Promise<void> {
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD].includes(requester.role)) {
      throw ApiError.forbidden('Only administrators and HODs are permitted to delete teacher substitutions');
    }

    if (!mongoose.Types.ObjectId.isValid(id)) {
      throw ApiError.badRequest('Invalid substitution ID');
    }

    const substitution = await TeacherSubstitution.findById(id);
    if (!substitution) {
      throw ApiError.notFound('Teacher substitution not found');
    }

    if (requester.role !== AppRole.SUPER_ADMIN && requester.collegeId && substitution.collegeId.toString() !== requester.collegeId) {
      throw ApiError.forbidden('Cross-college teacher substitution deletion is strictly prohibited');
    }

    if (requester.role === AppRole.HOD && requester.departmentId && substitution.departmentId.toString() !== requester.departmentId) {
      throw ApiError.forbidden('HOD can only delete teacher substitutions within their assigned department');
    }

    await substitution.deleteOne();
  }
}
