import { Types } from 'mongoose';
import { ApiError } from '../utils/apiError';
import { AppRole } from '../constants/roles';
import { AuthenticatedUser } from '../types/auth.types';
import { AttendanceStatus, AttendanceSessionStatus } from '../constants/status';
import { AttendanceSession } from '../models/attendanceSession.model';
import { AttendanceRecord } from '../models/attendanceRecord.model';
import { StudentEnrollment } from '../models/studentEnrollment.model';
import { Student } from '../models/student.model';
import { Course } from '../models/course.model';
import { Semester } from '../models/semester.model';
import { Section } from '../models/section.model';
import { Subject } from '../models/subject.model';
import { Department } from '../models/department.model';
import { DepartmentAnalyticsQueryInput } from '../validations/departmentAnalytics.validation';

export const DEFAULT_ATTENDANCE_RISK_THRESHOLD = 75.0;

export interface AttendanceMetrics {
  totalSessions: number;
  totalRecords: number;
  presentCount: number;
  absentCount: number;
  lateCount: number;
  excusedCount: number;
  medicalLeaveCount: number;
  onDutyCount: number;
  attendedCount: number;
  attendancePercentage: number;
  atRiskCount: number;
}

export class DepartmentAnalyticsService {
  /**
   * Resolves and authorizes tenant scope (collegeId, departmentId) and validates all filter parameters.
   */
  public static async resolveAndAuthorizeScope(
    requester: AuthenticatedUser,
    query: DepartmentAnalyticsQueryInput
  ): Promise<{
    collegeId: Types.ObjectId;
    departmentId: Types.ObjectId;
    threshold: number;
    filters: {
      courseId?: Types.ObjectId;
      academicYearId?: Types.ObjectId;
      semesterId?: Types.ObjectId;
      sectionId?: Types.ObjectId;
      subjectId?: Types.ObjectId;
      studentId?: Types.ObjectId;
      startDate?: Date;
      endDate?: Date;
    };
  }> {
    if (!requester) {
      throw ApiError.unauthorized('Authentication required');
    }

    if (requester.role === AppRole.FACULTY || requester.role === AppRole.STUDENT) {
      throw ApiError.forbidden('Access denied. Department analytics requires HOD or higher role.');
    }

    let collegeIdStr: string | undefined;
    let departmentIdStr: string | undefined;

    if (requester.role === AppRole.HOD) {
      if (!requester.collegeId || !requester.departmentId) {
        throw ApiError.forbidden('HOD profile is missing college or department assignment');
      }

      // Detect and reject cross-college attempts
      if (query.collegeId && query.collegeId !== requester.collegeId.toString()) {
        throw ApiError.forbidden('Cross-college tenant access is strictly prohibited');
      }

      // Detect and reject cross-department attempts
      if (query.departmentId && query.departmentId !== requester.departmentId.toString()) {
        throw ApiError.forbidden('HOD cannot access analytics of another department');
      }

      collegeIdStr = requester.collegeId.toString();
      departmentIdStr = requester.departmentId.toString();
    } else if (requester.role === AppRole.COLLEGE_ADMIN) {
      if (!requester.collegeId) {
        throw ApiError.forbidden('College admin must have an assigned college');
      }

      if (query.collegeId && query.collegeId !== requester.collegeId.toString()) {
        throw ApiError.forbidden('Cross-college tenant access is strictly prohibited');
      }

      collegeIdStr = requester.collegeId.toString();
      departmentIdStr = query.departmentId;

      if (!departmentIdStr) {
        const firstDept = await Department.findOne({
          collegeId: new Types.ObjectId(collegeIdStr),
        });
        if (!firstDept) {
          throw ApiError.notFound('No department found for this college');
        }
        departmentIdStr = firstDept._id.toString();
      }
    } else if (requester.role === AppRole.SUPER_ADMIN) {
      collegeIdStr = query.collegeId || requester.collegeId?.toString();
      if (!collegeIdStr) {
        throw ApiError.badRequest('collegeId is required for Super Admin');
      }
      departmentIdStr = query.departmentId;
      if (!departmentIdStr) {
        const firstDept = await Department.findOne({
          collegeId: new Types.ObjectId(collegeIdStr),
        });
        if (!firstDept) {
          throw ApiError.notFound('No department found for the specified college');
        }
        departmentIdStr = firstDept._id.toString();
      }
    } else {
      throw ApiError.forbidden('Access denied');
    }

    const collegeId = new Types.ObjectId(collegeIdStr);
    const departmentId = new Types.ObjectId(departmentIdStr);

    // Verify department exists in the college
    const deptExists = await Department.findOne({ _id: departmentId, collegeId });
    if (!deptExists) {
      throw ApiError.forbidden('Department not found in the authorized college scope');
    }

    // Validate filters against authorized scope
    const filters: {
      courseId?: Types.ObjectId;
      academicYearId?: Types.ObjectId;
      semesterId?: Types.ObjectId;
      sectionId?: Types.ObjectId;
      subjectId?: Types.ObjectId;
      studentId?: Types.ObjectId;
      startDate?: Date;
      endDate?: Date;
    } = {};

    if (query.courseId) {
      if (!Types.ObjectId.isValid(query.courseId)) {
        throw ApiError.badRequest('Invalid courseId format');
      }
      const course = await Course.findOne({
        _id: new Types.ObjectId(query.courseId),
        collegeId,
        departmentId,
      });
      if (!course) {
        throw ApiError.badRequest('Invalid courseId: course does not belong to your department');
      }
      filters.courseId = course._id as Types.ObjectId;
    }

    if (query.academicYearId) {
      if (!Types.ObjectId.isValid(query.academicYearId)) {
        throw ApiError.badRequest('Invalid academicYearId format');
      }
      filters.academicYearId = new Types.ObjectId(query.academicYearId);
    }

    if (query.semesterId) {
      if (!Types.ObjectId.isValid(query.semesterId)) {
        throw ApiError.badRequest('Invalid semesterId format');
      }
      const semester = await Semester.findOne({
        _id: new Types.ObjectId(query.semesterId),
        collegeId,
      });
      if (!semester) {
        throw ApiError.badRequest('Invalid semesterId: semester not found');
      }
      // If courseId was provided, verify semester matches
      if (filters.courseId && semester.courseId.toString() !== filters.courseId.toString()) {
        throw ApiError.badRequest('Invalid semesterId: semester does not belong to selected course');
      }
      // Verify semester's course belongs to this department
      const courseOfSemester = await Course.findOne({
        _id: semester.courseId,
        collegeId,
        departmentId,
      });
      if (!courseOfSemester) {
        throw ApiError.badRequest('Invalid semesterId: semester does not belong to your department');
      }
      filters.semesterId = semester._id as Types.ObjectId;
      if (!filters.courseId) {
        filters.courseId = courseOfSemester._id as Types.ObjectId;
      }
    }

    if (query.sectionId) {
      if (!Types.ObjectId.isValid(query.sectionId)) {
        throw ApiError.badRequest('Invalid sectionId format');
      }
      const section = await Section.findOne({
        _id: new Types.ObjectId(query.sectionId),
        collegeId,
      });
      if (!section) {
        throw ApiError.badRequest('Invalid sectionId: section not found');
      }
      if (filters.courseId && section.courseId.toString() !== filters.courseId.toString()) {
        throw ApiError.badRequest('Invalid sectionId: section does not belong to selected course');
      }
      if (filters.semesterId && section.semesterId.toString() !== filters.semesterId.toString()) {
        throw ApiError.badRequest('Invalid sectionId: section does not belong to selected semester');
      }
      const courseOfSection = await Course.findOne({
        _id: section.courseId,
        collegeId,
        departmentId,
      });
      if (!courseOfSection) {
        throw ApiError.badRequest('Invalid sectionId: section does not belong to your department');
      }
      filters.sectionId = section._id as Types.ObjectId;
    }

    if (query.subjectId) {
      if (!Types.ObjectId.isValid(query.subjectId)) {
        throw ApiError.badRequest('Invalid subjectId format');
      }
      const subject = await Subject.findOne({
        _id: new Types.ObjectId(query.subjectId),
        collegeId,
        departmentId,
      });
      if (!subject) {
        throw ApiError.badRequest('Invalid subjectId: subject does not belong to your department');
      }
      filters.subjectId = subject._id as Types.ObjectId;
    }

    if (query.studentId) {
      if (!Types.ObjectId.isValid(query.studentId)) {
        throw ApiError.badRequest('Invalid studentId format');
      }
      const student = await Student.findOne({
        _id: new Types.ObjectId(query.studentId),
        collegeId,
        departmentId,
      });
      if (!student) {
        throw ApiError.badRequest('Invalid studentId: student does not belong to your department');
      }
      filters.studentId = student._id as Types.ObjectId;
    }

    if (query.startDate) {
      const d = new Date(query.startDate);
      d.setUTCHours(0, 0, 0, 0);
      filters.startDate = d;
    }

    if (query.endDate) {
      const d = new Date(query.endDate);
      d.setUTCHours(23, 59, 59, 999);
      filters.endDate = d;
    }

    const threshold =
      query.atRiskThreshold !== undefined
        ? Number(query.atRiskThreshold)
        : DEFAULT_ATTENDANCE_RISK_THRESHOLD;

    return {
      collegeId,
      departmentId,
      threshold,
      filters,
    };
  }

  /**
   * Helper: Build AttendanceSession mongo match filter from authorized scope & filters.
   */
  private static buildSessionFilter(
    collegeId: Types.ObjectId,
    departmentId: Types.ObjectId,
    filters: {
      courseId?: Types.ObjectId;
      academicYearId?: Types.ObjectId;
      semesterId?: Types.ObjectId;
      sectionId?: Types.ObjectId;
      subjectId?: Types.ObjectId;
      startDate?: Date;
      endDate?: Date;
    }
  ): Record<string, unknown> {
    const filter: Record<string, unknown> = {
      collegeId,
      departmentId,
      isCancelled: { $ne: true },
      status: { $ne: AttendanceSessionStatus.CANCELLED },
    };

    if (filters.courseId) filter.courseId = filters.courseId;
    if (filters.academicYearId) filter.academicYearId = filters.academicYearId;
    if (filters.semesterId) filter.semesterId = filters.semesterId;
    if (filters.sectionId) filter.sectionId = filters.sectionId;
    if (filters.subjectId) filter.subjectId = filters.subjectId;

    if (filters.startDate || filters.endDate) {
      const dateFilter: Record<string, unknown> = {};
      if (filters.startDate) dateFilter.$gte = filters.startDate;
      if (filters.endDate) dateFilter.$lte = filters.endDate;
      filter.date = dateFilter;
    }

    return filter;
  }

  /**
   * Helper: compute aggregated stats over records of given session IDs.
   */
  private static async aggregateSessionRecords(
    sessionIds: Types.ObjectId[],
    studentIdFilter?: Types.ObjectId,
    threshold: number = DEFAULT_ATTENDANCE_RISK_THRESHOLD
  ): Promise<AttendanceMetrics> {
    if (sessionIds.length === 0) {
      return {
        totalSessions: 0,
        totalRecords: 0,
        presentCount: 0,
        absentCount: 0,
        lateCount: 0,
        excusedCount: 0,
        medicalLeaveCount: 0,
        onDutyCount: 0,
        attendedCount: 0,
        attendancePercentage: 0.0,
        atRiskCount: 0,
      };
    }

    const match: Record<string, unknown> = {
      sessionId: { $in: sessionIds },
      isCancelled: { $ne: true },
    };
    if (studentIdFilter) {
      match.studentId = studentIdFilter;
    }

    const [counts] = await AttendanceRecord.aggregate([
      { $match: match },
      {
        $group: {
          _id: null,
          total: { $sum: 1 },
          present: { $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.PRESENT] }, 1, 0] } },
          late: { $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.LATE] }, 1, 0] } },
          onDuty: { $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.ON_DUTY] }, 1, 0] } },
          absent: { $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.ABSENT] }, 1, 0] } },
          excused: { $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.EXCUSED] }, 1, 0] } },
          medicalLeave: {
            $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.MEDICAL_LEAVE] }, 1, 0] },
          },
        },
      },
    ]);

    const totalRecords = counts?.total ?? 0;
    const presentCount = counts?.present ?? 0;
    const lateCount = counts?.late ?? 0;
    const onDutyCount = counts?.onDuty ?? 0;
    const absentCount = counts?.absent ?? 0;
    const excusedCount = counts?.excused ?? 0;
    const medicalLeaveCount = counts?.medicalLeave ?? 0;
    const attendedCount = presentCount + lateCount + onDutyCount;

    const attendancePercentage =
      totalRecords === 0 ? 0.0 : Math.round((attendedCount / totalRecords) * 10000) / 100;

    // Calculate at-risk students count across these session records
    const studentStats = await AttendanceRecord.aggregate([
      { $match: match },
      {
        $group: {
          _id: '$studentId',
          total: { $sum: 1 },
          attended: {
            $sum: {
              $cond: [
                {
                  $in: ['$status', [AttendanceStatus.PRESENT, AttendanceStatus.LATE, AttendanceStatus.ON_DUTY]],
                },
                1,
                0,
              ],
            },
          },
        },
      },
    ]);

    let atRiskCount = 0;
    for (const stat of studentStats) {
      if (stat.total > 0) {
        const pct = (stat.attended / stat.total) * 100;
        if (pct < threshold) {
          atRiskCount++;
        }
      }
    }

    return {
      totalSessions: sessionIds.length,
      totalRecords,
      presentCount,
      absentCount,
      lateCount,
      excusedCount,
      medicalLeaveCount,
      onDutyCount,
      attendedCount,
      attendancePercentage,
      atRiskCount,
    };
  }

  // =========================================================================
  // 1. DEPARTMENT OVERVIEW
  // =========================================================================
  public static async getDepartmentOverview(
    requester: AuthenticatedUser,
    query: DepartmentAnalyticsQueryInput
  ) {
    const { collegeId, departmentId, threshold, filters } =
      await this.resolveAndAuthorizeScope(requester, query);

    const department = await Department.findById(departmentId).lean();
    const departmentName = department?.name || 'Department';

    // Total active enrolled students in department
    const enrollmentFilter: Record<string, unknown> = {
      collegeId,
      departmentId,
      status: { $regex: /^active$/i },
    };
    if (filters.courseId) enrollmentFilter.courseId = filters.courseId;
    if (filters.academicYearId) enrollmentFilter.academicYearId = filters.academicYearId;
    if (filters.semesterId) enrollmentFilter.semesterId = filters.semesterId;
    if (filters.sectionId) enrollmentFilter.sectionId = filters.sectionId;

    const totalStudents = await StudentEnrollment.countDocuments(enrollmentFilter);

    // Find all sessions matching filters
    const sessionFilter = this.buildSessionFilter(collegeId, departmentId, filters);
    const sessions = await AttendanceSession.find(sessionFilter)
      .select('_id courseId semesterId sectionId subjectId date')
      .lean();

    const sessionIds = sessions.map((s) => s._id as Types.ObjectId);
    const metrics = await this.aggregateSessionRecords(sessionIds, filters.studentId, threshold);

    // Course breakdown
    const courses = await Course.find({
      collegeId,
      departmentId,
      ...(filters.courseId ? { _id: filters.courseId } : {}),
    }).lean();

    const courseBreakdown = await Promise.all(
      courses.map(async (c) => {
        const cSessions = sessions.filter(
          (s) => s.courseId && s.courseId.toString() === c._id.toString()
        );
        const cSessionIds = cSessions.map((s) => s._id as Types.ObjectId);
        const cMetrics = await this.aggregateSessionRecords(
          cSessionIds,
          filters.studentId,
          threshold
        );
        const studentCount = await StudentEnrollment.countDocuments({
          collegeId,
          departmentId,
          courseId: c._id,
          status: { $regex: /^active$/i },
        });

        return {
          courseId: c._id.toString(),
          courseName: c.name,
          courseCode: c.code,
          studentCount,
          sessionCount: cSessions.length,
          attendancePercentage: cMetrics.attendancePercentage,
          present: cMetrics.presentCount,
          absent: cMetrics.absentCount,
          atRiskCount: cMetrics.atRiskCount,
        };
      })
    );

    // Semester breakdown
    const semesterFilter: Record<string, unknown> = {
      collegeId,
      ...(filters.courseId ? { courseId: filters.courseId } : { courseId: { $in: courses.map((c) => c._id) } }),
      ...(filters.semesterId ? { _id: filters.semesterId } : {}),
    };
    const semesters = await Semester.find(semesterFilter).lean();

    const semesterBreakdown = await Promise.all(
      semesters.map(async (sem) => {
        const semSessions = sessions.filter(
          (s) => s.semesterId && s.semesterId.toString() === sem._id.toString()
        );
        const semSessionIds = semSessions.map((s) => s._id as Types.ObjectId);
        const semMetrics = await this.aggregateSessionRecords(
          semSessionIds,
          filters.studentId,
          threshold
        );
        const studentCount = await StudentEnrollment.countDocuments({
          collegeId,
          departmentId,
          semesterId: sem._id,
          status: { $regex: /^active$/i },
        });

        return {
          semesterId: sem._id.toString(),
          semesterNumber: sem.number,
          courseId: sem.courseId?.toString(),
          studentCount,
          sessionCount: semSessions.length,
          attendancePercentage: semMetrics.attendancePercentage,
          present: semMetrics.presentCount,
          absent: semMetrics.absentCount,
          atRiskCount: semMetrics.atRiskCount,
        };
      })
    );

    // Section breakdown
    const sectionFilter: Record<string, unknown> = {
      collegeId,
      ...(filters.courseId ? { courseId: filters.courseId } : { courseId: { $in: courses.map((c) => c._id) } }),
      ...(filters.semesterId ? { semesterId: filters.semesterId } : {}),
      ...(filters.sectionId ? { _id: filters.sectionId } : {}),
    };
    const sections = await Section.find(sectionFilter).lean();

    const sectionBreakdown = await Promise.all(
      sections.map(async (sec) => {
        const secSessions = sessions.filter(
          (s) => s.sectionId && s.sectionId.toString() === sec._id.toString()
        );
        const secSessionIds = secSessions.map((s) => s._id as Types.ObjectId);
        const secMetrics = await this.aggregateSessionRecords(
          secSessionIds,
          filters.studentId,
          threshold
        );
        const studentCount = await StudentEnrollment.countDocuments({
          collegeId,
          departmentId,
          sectionId: sec._id,
          status: { $regex: /^active$/i },
        });

        return {
          sectionId: sec._id.toString(),
          sectionName: sec.name,
          courseId: sec.courseId?.toString(),
          semesterId: sec.semesterId?.toString(),
          studentCount,
          sessionCount: secSessions.length,
          attendancePercentage: secMetrics.attendancePercentage,
          present: secMetrics.presentCount,
          absent: secMetrics.absentCount,
          atRiskCount: secMetrics.atRiskCount,
        };
      })
    );

    // Subject breakdown
    const subjects = await Subject.find({
      collegeId,
      departmentId,
      ...(filters.courseId ? { courseId: filters.courseId } : {}),
      ...(filters.semesterId ? { semesterId: filters.semesterId } : {}),
      ...(filters.subjectId ? { _id: filters.subjectId } : {}),
    }).lean();

    const subjectBreakdown = await Promise.all(
      subjects.map(async (sub) => {
        const subSessions = sessions.filter(
          (s) => s.subjectId && s.subjectId.toString() === sub._id.toString()
        );
        const subSessionIds = subSessions.map((s) => s._id as Types.ObjectId);
        const subMetrics = await this.aggregateSessionRecords(
          subSessionIds,
          filters.studentId,
          threshold
        );

        return {
          subjectId: sub._id.toString(),
          subjectName: sub.name,
          subjectCode: sub.code,
          sessionCount: subSessions.length,
          attendancePercentage: subMetrics.attendancePercentage,
          present: subMetrics.presentCount,
          absent: subMetrics.absentCount,
          atRiskCount: subMetrics.atRiskCount,
        };
      })
    );

    return {
      collegeId: collegeId.toString(),
      departmentId: departmentId.toString(),
      departmentName,
      overallAttendancePercentage: metrics.attendancePercentage,
      totalStudents,
      totalSessions: metrics.totalSessions,
      totalRecords: metrics.totalRecords,
      presentCount: metrics.presentCount,
      absentCount: metrics.absentCount,
      lateCount: metrics.lateCount,
      excusedCount: metrics.excusedCount,
      medicalLeaveCount: metrics.medicalLeaveCount,
      onDutyCount: metrics.onDutyCount,
      atRiskCount: metrics.atRiskCount,
      atRiskThreshold: threshold,
      courseBreakdown,
      semesterBreakdown,
      sectionBreakdown,
      subjectBreakdown,
    };
  }

  // =========================================================================
  // 2. COURSE ANALYTICS
  // =========================================================================
  public static async getCourseAnalytics(
    requester: AuthenticatedUser,
    query: DepartmentAnalyticsQueryInput
  ) {
    const { collegeId, departmentId, threshold, filters } =
      await this.resolveAndAuthorizeScope(requester, query);

    const courses = await Course.find({
      collegeId,
      departmentId,
      ...(filters.courseId ? { _id: filters.courseId } : {}),
    }).lean();

    const sessionFilter = this.buildSessionFilter(collegeId, departmentId, filters);
    const sessions = await AttendanceSession.find(sessionFilter)
      .select('_id courseId date')
      .lean();

    const results = await Promise.all(
      courses.map(async (c) => {
        const cSessions = sessions.filter(
          (s) => s.courseId && s.courseId.toString() === c._id.toString()
        );
        const cSessionIds = cSessions.map((s) => s._id as Types.ObjectId);
        const metrics = await this.aggregateSessionRecords(
          cSessionIds,
          filters.studentId,
          threshold
        );
        const studentCount = await StudentEnrollment.countDocuments({
          collegeId,
          departmentId,
          courseId: c._id,
          status: { $regex: /^active$/i },
        });

        return {
          courseId: c._id.toString(),
          courseName: c.name,
          courseCode: c.code,
          studentCount,
          sessionCount: cSessions.length,
          attendancePercentage: metrics.attendancePercentage,
          present: metrics.presentCount,
          absent: metrics.absentCount,
          late: metrics.lateCount,
          excused: metrics.excusedCount,
          medicalLeave: metrics.medicalLeaveCount,
          onDuty: metrics.onDutyCount,
          atRiskCount: metrics.atRiskCount,
        };
      })
    );

    return results;
  }

  // =========================================================================
  // 3. SECTION ANALYTICS
  // =========================================================================
  public static async getSectionAnalytics(
    requester: AuthenticatedUser,
    query: DepartmentAnalyticsQueryInput
  ) {
    const { collegeId, departmentId, threshold, filters } =
      await this.resolveAndAuthorizeScope(requester, query);

    const courses = await Course.find({
      collegeId,
      departmentId,
      ...(filters.courseId ? { _id: filters.courseId } : {}),
    }).lean();
    const courseMap = new Map<string, string>(courses.map((c) => [c._id.toString(), c.name]));

    const sectionFilter: Record<string, unknown> = {
      collegeId,
      courseId: { $in: courses.map((c) => c._id) },
      ...(filters.semesterId ? { semesterId: filters.semesterId } : {}),
      ...(filters.sectionId ? { _id: filters.sectionId } : {}),
    };
    const sections = await Section.find(sectionFilter).lean();

    const semesters = await Semester.find({
      _id: { $in: sections.map((s) => s.semesterId) },
    }).lean();
    const semMap = new Map<string, number>(
      semesters.map((s) => [s._id.toString(), s.number])
    );

    const sessionFilter = this.buildSessionFilter(collegeId, departmentId, filters);
    const sessions = await AttendanceSession.find(sessionFilter)
      .select('_id sectionId date')
      .lean();

    const results = await Promise.all(
      sections.map(async (sec) => {
        const secSessions = sessions.filter(
          (s) => s.sectionId && s.sectionId.toString() === sec._id.toString()
        );
        const secSessionIds = secSessions.map((s) => s._id as Types.ObjectId);
        const metrics = await this.aggregateSessionRecords(
          secSessionIds,
          filters.studentId,
          threshold
        );
        const enrolledStudents = await StudentEnrollment.countDocuments({
          collegeId,
          departmentId,
          sectionId: sec._id,
          status: { $regex: /^active$/i },
        });

        return {
          sectionId: sec._id.toString(),
          sectionName: sec.name,
          courseId: sec.courseId?.toString(),
          courseName: courseMap.get(sec.courseId?.toString() || '') || '',
          semesterId: sec.semesterId?.toString(),
          semesterNumber: semMap.get(sec.semesterId?.toString() || '') || 0,
          enrolledStudents,
          totalSessions: secSessions.length,
          attendancePercentage: metrics.attendancePercentage,
          present: metrics.presentCount,
          absent: metrics.absentCount,
          late: metrics.lateCount,
          excused: metrics.excusedCount,
          medicalLeave: metrics.medicalLeaveCount,
          onDuty: metrics.onDutyCount,
          atRiskStudents: metrics.atRiskCount,
        };
      })
    );

    return results;
  }

  // =========================================================================
  // 4. SUBJECT ANALYTICS
  // =========================================================================
  public static async getSubjectAnalytics(
    requester: AuthenticatedUser,
    query: DepartmentAnalyticsQueryInput
  ) {
    const { collegeId, departmentId, threshold, filters } =
      await this.resolveAndAuthorizeScope(requester, query);

    const courses = await Course.find({
      collegeId,
      departmentId,
      ...(filters.courseId ? { _id: filters.courseId } : {}),
    }).lean();
    const courseMap = new Map<string, string>(courses.map((c) => [c._id.toString(), c.name]));

    const subjects = await Subject.find({
      collegeId,
      departmentId,
      ...(filters.courseId ? { courseId: filters.courseId } : {}),
      ...(filters.semesterId ? { semesterId: filters.semesterId } : {}),
      ...(filters.subjectId ? { _id: filters.subjectId } : {}),
    }).lean();

    const semesters = await Semester.find({
      _id: { $in: subjects.map((s) => s.semesterId) },
    }).lean();
    const semMap = new Map<string, number>(
      semesters.map((s) => [s._id.toString(), s.number])
    );

    const sessionFilter = this.buildSessionFilter(collegeId, departmentId, filters);
    const sessions = await AttendanceSession.find(sessionFilter)
      .select('_id subjectId sectionName date')
      .lean();

    const results = await Promise.all(
      subjects.map(async (sub) => {
        const subSessions = sessions.filter(
          (s) => s.subjectId && s.subjectId.toString() === sub._id.toString()
        );
        const subSessionIds = subSessions.map((s) => s._id as Types.ObjectId);
        const metrics = await this.aggregateSessionRecords(
          subSessionIds,
          filters.studentId,
          threshold
        );

        const assignedSectionsSet = new Set<string>();
        subSessions.forEach((s) => {
          if (s.sectionName) assignedSectionsSet.add(s.sectionName);
        });

        return {
          subjectId: sub._id.toString(),
          subjectName: sub.name,
          subjectCode: sub.code,
          courseId: sub.courseId?.toString(),
          courseName: courseMap.get(sub.courseId?.toString() || '') || '',
          semesterId: sub.semesterId?.toString(),
          semesterNumber: semMap.get(sub.semesterId?.toString() || '') || 0,
          assignedSections: Array.from(assignedSectionsSet),
          sessionCount: subSessions.length,
          attendancePercentage: metrics.attendancePercentage,
          present: metrics.presentCount,
          absent: metrics.absentCount,
          late: metrics.lateCount,
          excused: metrics.excusedCount,
          medicalLeave: metrics.medicalLeaveCount,
          onDuty: metrics.onDutyCount,
          atRiskCount: metrics.atRiskCount,
        };
      })
    );

    return results;
  }

  // =========================================================================
  // 5. STUDENT ATTENDANCE ANALYTICS
  // =========================================================================
  public static async getStudentAnalytics(
    requester: AuthenticatedUser,
    query: DepartmentAnalyticsQueryInput
  ) {
    const { collegeId, departmentId, threshold, filters } =
      await this.resolveAndAuthorizeScope(requester, query);

    // Get active enrollments for the department
    const enrollmentFilter: Record<string, unknown> = {
      collegeId,
      departmentId,
      status: { $regex: /^active$/i },
    };
    if (filters.courseId) enrollmentFilter.courseId = filters.courseId;
    if (filters.academicYearId) enrollmentFilter.academicYearId = filters.academicYearId;
    if (filters.semesterId) enrollmentFilter.semesterId = filters.semesterId;
    if (filters.sectionId) enrollmentFilter.sectionId = filters.sectionId;
    if (filters.studentId) enrollmentFilter.studentId = filters.studentId;

    const enrollments = await StudentEnrollment.find(enrollmentFilter).lean();
    if (enrollments.length === 0) {
      return {
        students: [],
        total: 0,
        page: query.page,
        limit: query.limit,
      };
    }

    const studentIds = enrollments.map((e) => e.studentId);
    const students = await Student.find({
      _id: { $in: studentIds },
      collegeId,
      departmentId,
    }).lean();
    const studentMap = new Map<string, (typeof students)[0]>(
      students.map((st) => [st._id.toString(), st])
    );

    const courseIds = enrollments.map((e) => e.courseId);
    const courses = await Course.find({ _id: { $in: courseIds } }).lean();
    const courseMap = new Map<string, string>(courses.map((c) => [c._id.toString(), c.name]));

    const semesterIds = enrollments.map((e) => e.semesterId);
    const semesters = await Semester.find({ _id: { $in: semesterIds } }).lean();
    const semMap = new Map<string, number>(
      semesters.map((s) => [s._id.toString(), s.number])
    );

    const sectionIds = enrollments.map((e) => e.sectionId);
    const sections = await Section.find({ _id: { $in: sectionIds } }).lean();
    const secMap = new Map<string, string>(sections.map((s) => [s._id.toString(), s.name]));

    // Find all sessions matching filters
    const sessionFilter = this.buildSessionFilter(collegeId, departmentId, filters);
    const sessions = await AttendanceSession.find(sessionFilter).select('_id').lean();
    const sessionIds = sessions.map((s) => s._id as Types.ObjectId);

    // Aggregate attendance per student
    let studentStatsMap = new Map<
      string,
      {
        total: number;
        present: number;
        late: number;
        onDuty: number;
        absent: number;
        excused: number;
        medicalLeave: number;
      }
    >();

    if (sessionIds.length > 0) {
      const stats = await AttendanceRecord.aggregate([
        {
          $match: {
            sessionId: { $in: sessionIds },
            studentId: { $in: studentIds },
            isCancelled: { $ne: true },
          },
        },
        {
          $group: {
            _id: '$studentId',
            total: { $sum: 1 },
            present: { $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.PRESENT] }, 1, 0] } },
            late: { $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.LATE] }, 1, 0] } },
            onDuty: { $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.ON_DUTY] }, 1, 0] } },
            absent: { $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.ABSENT] }, 1, 0] } },
            excused: { $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.EXCUSED] }, 1, 0] } },
            medicalLeave: {
              $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.MEDICAL_LEAVE] }, 1, 0] },
            },
          },
        },
      ]);

      stats.forEach((s) => {
        studentStatsMap.set(s._id.toString(), s);
      });
    }

    let studentResults = enrollments
      .map((enrollment) => {
        const student = studentMap.get(enrollment.studentId.toString());
        if (!student) return null;

        const stat = studentStatsMap.get(enrollment.studentId.toString());
        const total = stat?.total ?? 0;
        const present = stat?.present ?? 0;
        const late = stat?.late ?? 0;
        const onDuty = stat?.onDuty ?? 0;
        const absent = stat?.absent ?? 0;
        const excused = stat?.excused ?? 0;
        const medicalLeave = stat?.medicalLeave ?? 0;
        const attended = present + late + onDuty;

        const pct = total === 0 ? 0.0 : Math.round((attended / total) * 10000) / 100;
        const isAtRisk = total > 0 && pct < threshold;

        return {
          studentId: student._id.toString(),
          studentName: student.name,
          rollNumber: student.rollNumber || '',
          admissionNumber: student.admissionNumber || '',
          courseId: enrollment.courseId.toString(),
          courseName: courseMap.get(enrollment.courseId.toString()) || '',
          semesterId: enrollment.semesterId.toString(),
          semesterNumber: semMap.get(enrollment.semesterId.toString()) || 0,
          sectionId: enrollment.sectionId.toString(),
          sectionName: secMap.get(enrollment.sectionId.toString()) || '',
          overallAttendancePercentage: pct,
          present,
          absent,
          late,
          excused,
          medicalLeave,
          onDuty,
          sessionsConsidered: total,
          isAtRisk,
        };
      })
      .filter((s): s is NonNullable<typeof s> => s !== null);

    // Apply search filter if present
    if (query.search) {
      const q = query.search.toLowerCase();
      studentResults = studentResults.filter(
        (s) =>
          s.studentName.toLowerCase().includes(q) ||
          s.rollNumber.toLowerCase().includes(q) ||
          s.admissionNumber.toLowerCase().includes(q)
      );
    }

    // Apply at-risk only filter if requested
    if (query.atRiskOnly) {
      studentResults = studentResults.filter((s) => s.isAtRisk);
    }

    // Pagination
    const total = studentResults.length;
    const startIndex = (query.page - 1) * query.limit;
    const paginated = studentResults.slice(startIndex, startIndex + query.limit);

    return {
      students: paginated,
      total,
      page: query.page,
      limit: query.limit,
      threshold,
    };
  }

  // =========================================================================
  // 6. TREND ANALYTICS
  // =========================================================================
  public static async getTrendAnalytics(
    requester: AuthenticatedUser,
    query: DepartmentAnalyticsQueryInput
  ) {
    const { collegeId, departmentId, filters } = await this.resolveAndAuthorizeScope(
      requester,
      query
    );

    const sessionFilter = this.buildSessionFilter(collegeId, departmentId, filters);
    const sessions = await AttendanceSession.find(sessionFilter)
      .select('_id date')
      .sort({ date: 1 })
      .lean();

    if (sessions.length === 0) {
      return {
        trends: [],
      };
    }

    const sessionIds = sessions.map((s) => s._id as Types.ObjectId);
    const records = await AttendanceRecord.aggregate([
      {
        $match: {
          sessionId: { $in: sessionIds },
          isCancelled: { $ne: true },
        },
      },
      {
        $project: {
          sessionId: 1,
          dateStr: { $dateToString: { format: '%Y-%m-%d', date: '$date' } },
          status: 1,
        },
      },
      {
        $group: {
          _id: '$dateStr',
          totalRecords: { $sum: 1 },
          present: { $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.PRESENT] }, 1, 0] } },
          late: { $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.LATE] }, 1, 0] } },
          onDuty: { $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.ON_DUTY] }, 1, 0] } },
          absent: { $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.ABSENT] }, 1, 0] } },
        },
      },
      { $sort: { _id: 1 } },
    ]);

    // Count sessions per date
    const sessionDateCounts = new Map<string, number>();
    sessions.forEach((s) => {
      const dStr = new Date(s.date).toISOString().slice(0, 10);
      sessionDateCounts.set(dStr, (sessionDateCounts.get(dStr) || 0) + 1);
    });

    const trends = records.map((r) => {
      const dateStr = r._id;
      const totalRecs = r.totalRecords;
      const attended = r.present + r.late + r.onDuty;
      const pct = totalRecs === 0 ? 0.0 : Math.round((attended / totalRecs) * 10000) / 100;
      const totalSessions = sessionDateCounts.get(dateStr) || 1;

      return {
        date: dateStr,
        label: dateStr.slice(5), // "MM-DD"
        totalSessions,
        totalRecords: totalRecs,
        present: r.present,
        absent: r.absent,
        attendancePercentage: pct,
      };
    });

    return {
      trends,
    };
  }
}
