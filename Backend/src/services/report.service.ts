import mongoose from 'mongoose';
import {
  College,
  Department,
  Course,
  Semester,
  Section,
  Subject,
  User,
  Student,
  Faculty,
  AttendanceSession,
  AttendanceRecord,
  Timetable,
  Note,
  AuditLog,
} from '../models';
import { AppRole } from '../constants/roles';
import { AuthenticatedUser } from '../types/auth.types';
import { ApiError } from '../utils/apiError';
import {
  DateRangePreset,
  ATTENDANCE_THRESHOLDS,
} from '../constants/report.constants';
import {
  AttendanceSummaryMetrics,
  StudentAttendanceReport,
  SectionAttendanceReport,
  DepartmentAttendanceReport,
  CollegeAttendanceReport,
  SubjectAttendanceMetrics,
  StudentAttendanceRankItem,
  FacultyActivityReport,
  AcademicHierarchyReport,
  NotesReport,
  RoleDashboardReport,
} from '../types/report.types';
import { DateRangeQueryInput } from '../validations/report.validation';
import { AttendanceStatus, AttendanceSessionStatus, TimetableStatus, NoteStatus, AccountStatus } from '../constants/status';

export class ReportService {
  /**
   * Resolves date bounds from preset or custom dates
   */
  static resolveDateBounds(input: DateRangeQueryInput): { fromDate?: Date; toDate?: Date } {
    const now = new Date();

    if (input.preset) {
      switch (input.preset) {
        case DateRangePreset.TODAY: {
          const start = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 0, 0, 0, 0);
          const end = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);
          return { fromDate: start, toDate: end };
        }
        case DateRangePreset.THIS_WEEK: {
          const day = now.getDay();
          const diffToMonday = (day === 0 ? -6 : 1) - day;
          const start = new Date(now.getFullYear(), now.getMonth(), now.getDate() + diffToMonday, 0, 0, 0, 0);
          const end = new Date(start.getFullYear(), start.getMonth(), start.getDate() + 6, 23, 59, 59, 999);
          return { fromDate: start, toDate: end };
        }
        case DateRangePreset.THIS_MONTH: {
          const start = new Date(now.getFullYear(), now.getMonth(), 1, 0, 0, 0, 0);
          const end = new Date(now.getFullYear(), now.getMonth() + 1, 0, 23, 59, 59, 999);
          return { fromDate: start, toDate: end };
        }
        default:
          break;
      }
    }

    const fromDate = input.startDate ? new Date(input.startDate) : undefined;
    const toDate = input.endDate ? new Date(input.endDate) : undefined;
    if (toDate && !input.endDate?.includes('T')) {
      toDate.setHours(23, 59, 59, 999);
    }
    return { fromDate, toDate };
  }

  // =========================================================================
  // 1. ROLE-AWARE DASHBOARD ANALYTICS
  // =========================================================================

  static async getDashboard(
    requester: AuthenticatedUser,
    query: DateRangeQueryInput
  ): Promise<RoleDashboardReport> {
    const { fromDate, toDate } = this.resolveDateBounds(query);
    const dateMatch: Record<string, unknown> = {};
    if (fromDate || toDate) {
      dateMatch.date = {};
      if (fromDate) (dateMatch.date as any).$gte = fromDate;
      if (toDate) (dateMatch.date as any).$lte = toDate;
    }

    if (requester.role === AppRole.SUPER_ADMIN) {
      return this.getSuperAdminDashboard(dateMatch);
    } else if (requester.role === AppRole.COLLEGE_ADMIN) {
      if (!requester.collegeId) throw ApiError.badRequest('College ID is required for college admin dashboard');
      return this.getCollegeAdminDashboard(requester.collegeId, dateMatch);
    } else if (requester.role === AppRole.HOD) {
      if (!requester.departmentId) throw ApiError.badRequest('Department ID is required for HOD dashboard');
      return this.getHodDashboard(requester.departmentId, dateMatch);
    } else if (requester.role === AppRole.FACULTY) {
      return this.getFacultyDashboard(requester, dateMatch);
    } else if (requester.role === AppRole.STUDENT) {
      return this.getStudentDashboard(requester, dateMatch);
    }

    throw ApiError.forbidden('Unauthorized role for dashboard report');
  }

  private static async getSuperAdminDashboard(dateMatch: Record<string, unknown>): Promise<RoleDashboardReport> {
    const activeCollegesDocs = await College.find({ status: 'active', isActive: true }, '_id');
    const activeCollegeIds = activeCollegesDocs.map((c) => c._id);

    const [
      totalColleges,
      activeColleges,
      totalDepartments,
      totalCourses,
      totalSections,
      totalSubjects,
      totalStudents,
      totalFaculty,
      totalCollegeAdmins,
      totalHODs,
      totalNotes,
      totalSessions,
      attendanceStats,
      collegesList,
    ] = await Promise.all([
      College.countDocuments(),
      College.countDocuments({ status: 'active', isActive: true }),
      Department.countDocuments({ collegeId: { $in: activeCollegeIds }, isActive: true }),
      Course.countDocuments({ collegeId: { $in: activeCollegeIds }, isActive: true }),
      Section.countDocuments({ collegeId: { $in: activeCollegeIds }, isActive: true }),
      Subject.countDocuments({ collegeId: { $in: activeCollegeIds }, isActive: true }),
      Student.countDocuments({ collegeId: { $in: activeCollegeIds }, status: 'active', isActive: true }),
      Faculty.countDocuments({ collegeId: { $in: activeCollegeIds }, status: 'active', isActive: true }),
      User.countDocuments({ role: AppRole.COLLEGE_ADMIN, collegeId: { $in: activeCollegeIds }, accountStatus: { $ne: AccountStatus.DEACTIVATED } }),
      User.countDocuments({ role: AppRole.HOD, collegeId: { $in: activeCollegeIds }, accountStatus: { $ne: AccountStatus.DEACTIVATED } }),
      Note.countDocuments({ collegeId: { $in: activeCollegeIds }, status: NoteStatus.PUBLISHED }),
      AttendanceSession.countDocuments({ collegeId: { $in: activeCollegeIds }, status: { $ne: AttendanceSessionStatus.CANCELLED }, ...dateMatch }),
      AttendanceRecord.aggregate([
        { $match: { collegeId: { $in: activeCollegeIds }, isCancelled: { $ne: true }, ...dateMatch } },
        {
          $group: {
            _id: null,
            totalRecords: { $sum: 1 },
            present: { $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.PRESENT] }, 1, 0] } },
            late: { $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.LATE] }, 1, 0] } },
          },
        },
      ]),
      College.find({ isActive: true }).select('name code status').limit(20),
    ]);

    const attSummary = attendanceStats[0] || { totalRecords: 0, present: 0, late: 0 };
    const systemAttendancePercentage =
      attSummary.totalRecords > 0
        ? Math.round(((attSummary.present + attSummary.late) / attSummary.totalRecords) * 10000) / 100
        : 0;

    // Cross-college metrics summary
    const collegeComparison = await Promise.all(
      collegesList.map(async (col) => {
        const [depts, stu, fac, colAtt] = await Promise.all([
          Department.countDocuments({ collegeId: col._id, isActive: true }),
          Student.countDocuments({ collegeId: col._id, status: 'active', isActive: true }),
          Faculty.countDocuments({ collegeId: col._id, status: 'active', isActive: true }),
          AttendanceRecord.aggregate([
            { $match: { collegeId: col._id, isCancelled: { $ne: true }, ...dateMatch } },
            {
              $group: {
                _id: null,
                total: { $sum: 1 },
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
        ]);
        const colAttData = colAtt[0] || { total: 0, attended: 0 };
        const percentage = colAttData.total > 0 ? Math.round((colAttData.attended / colAttData.total) * 10000) / 100 : 0;
        return {
          collegeId: col.id,
          name: col.name,
          code: col.code,
          departmentsCount: depts,
          studentsCount: stu,
          facultyCount: fac,
          attendancePercentage: percentage,
        };
      })
    );

    return {
      role: AppRole.SUPER_ADMIN,
      metrics: {
        totalColleges,
        activeColleges,
        totalDepartments,
        totalCourses,
        totalSections,
        totalSubjects,
        totalStudents,
        totalFaculty,
        totalCollegeAdmins,
        totalHODs,
        totalNotes,
        totalSessions,
        systemAttendancePercentage,
      },
      quickStats: {
        collegesCount: totalColleges,
        activeCollegesCount: activeColleges,
        overallAttendanceRate: systemAttendancePercentage,
        collegeAdminsCount: totalCollegeAdmins,
        facultyCount: totalFaculty,
        studentsCount: totalStudents,
      },
      recentActivity: collegeComparison,
    };
  }

  private static async getCollegeAdminDashboard(
    collegeId: string,
    dateMatch: Record<string, unknown>
  ): Promise<RoleDashboardReport> {
    const colObjId = new mongoose.Types.ObjectId(collegeId);

    const [
      departmentsCount,
      coursesCount,
      sectionsCount,
      subjectsCount,
      studentsCount,
      facultyCount,
      hodsCount,
      notesCount,
      sessionsCount,
      attendanceStats,
      departmentsList,
    ] = await Promise.all([
      Department.countDocuments({ collegeId: colObjId, isActive: true }),
      Course.countDocuments({ collegeId: colObjId, isActive: true }),
      Section.countDocuments({ collegeId: colObjId, isActive: true }),
      Subject.countDocuments({ collegeId: colObjId, isActive: true }),
      Student.countDocuments({ collegeId: colObjId, status: 'active', isActive: true }),
      Faculty.countDocuments({ collegeId: colObjId, status: 'active', isActive: true }),
      User.countDocuments({ collegeId: colObjId, role: AppRole.HOD }),
      Note.countDocuments({ collegeId: colObjId, status: NoteStatus.PUBLISHED }),
      AttendanceSession.countDocuments({ collegeId: colObjId, status: { $ne: AttendanceSessionStatus.CANCELLED }, ...dateMatch }),
      AttendanceRecord.aggregate([
        { $match: { collegeId: colObjId, isCancelled: { $ne: true }, ...dateMatch } },
        {
          $group: {
            _id: null,
            totalRecords: { $sum: 1 },
            present: { $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.PRESENT] }, 1, 0] } },
            late: { $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.LATE] }, 1, 0] } },
          },
        },
      ]),
      Department.find({ collegeId: colObjId, isActive: true }).select('name code'),
    ]);

    const attSummary = attendanceStats[0] || { totalRecords: 0, present: 0, late: 0 };
    const collegeAttendancePercentage =
      attSummary.totalRecords > 0
        ? Math.round(((attSummary.present + attSummary.late) / attSummary.totalRecords) * 10000) / 100
        : 0;

    // Department breakdown
    const departmentBreakdown = await Promise.all(
      departmentsList.map(async (dept) => {
        const deptSections = await Section.find({ departmentId: dept._id, isActive: true }).select('_id');
        const secIds = deptSections.map((s) => s._id);

        const [stu, fac, deptAtt] = await Promise.all([
          Student.countDocuments({ departmentId: dept._id, status: 'active', isActive: true }),
          Faculty.countDocuments({ departmentId: dept._id, status: 'active', isActive: true }),
          AttendanceRecord.aggregate([
            { $match: { sectionId: { $in: secIds }, isCancelled: { $ne: true }, ...dateMatch } },
            {
              $group: {
                _id: null,
                total: { $sum: 1 },
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
        ]);
        const deptAttData = deptAtt[0] || { total: 0, attended: 0 };
        const percentage = deptAttData.total > 0 ? Math.round((deptAttData.attended / deptAttData.total) * 10000) / 100 : 0;
        return {
          departmentId: dept.id,
          name: dept.name,
          code: dept.code,
          studentsCount: stu,
          facultyCount: fac,
          attendancePercentage: percentage,
        };
      })
    );

    return {
      role: AppRole.COLLEGE_ADMIN,
      metrics: {
        departmentsCount,
        coursesCount,
        sectionsCount,
        subjectsCount,
        studentsCount,
        facultyCount,
        hodsCount,
        notesCount,
        sessionsCount,
        collegeAttendancePercentage,
      },
      quickStats: {
        totalStudents: studentsCount,
        totalFaculty: facultyCount,
        attendanceRate: collegeAttendancePercentage,
      },
      recentActivity: departmentBreakdown,
    };
  }

  private static async getHodDashboard(
    departmentId: string,
    dateMatch: Record<string, unknown> = {}
  ): Promise<RoleDashboardReport> {
    if (!departmentId) throw ApiError.badRequest('HOD is not assigned to a department');
    const deptObjId = new mongoose.Types.ObjectId(departmentId);

    const sectionsList = await Section.find({ departmentId: deptObjId, isActive: true }).select('name capacity courseId semesterId');
    const secIds = sectionsList.map((s) => s._id);

    const [
      coursesCount,
      sectionsCount,
      subjectsCount,
      studentsCount,
      facultyCount,
      notesCount,
      sessionsCount,
      attendanceStats,
    ] = await Promise.all([
      Course.countDocuments({ departmentId: deptObjId, isActive: true }),
      Section.countDocuments({ departmentId: deptObjId, isActive: true }),
      Subject.countDocuments({ departmentId: deptObjId, isActive: true }),
      Student.countDocuments({ departmentId: deptObjId, status: 'active', isActive: true }),
      Faculty.countDocuments({ departmentId: deptObjId, status: 'active', isActive: true }),
      Note.countDocuments({ departmentId: deptObjId, status: NoteStatus.PUBLISHED }),
      AttendanceSession.countDocuments({ departmentId: deptObjId, status: { $ne: AttendanceSessionStatus.CANCELLED }, ...dateMatch }),
      AttendanceRecord.aggregate([
        { $match: { sectionId: { $in: secIds }, isCancelled: { $ne: true }, ...dateMatch } },
        {
          $group: {
            _id: null,
            totalRecords: { $sum: 1 },
            present: { $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.PRESENT] }, 1, 0] } },
            late: { $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.LATE] }, 1, 0] } },
          },
        },
      ]),
    ]);

    const attSummary = attendanceStats[0] || { totalRecords: 0, present: 0, late: 0 };
    const departmentAttendancePercentage =
      attSummary.totalRecords > 0
        ? Math.round(((attSummary.present + attSummary.late) / attSummary.totalRecords) * 10000) / 100
        : 0;

    // Section-wise breakdown
    const sectionBreakdown = await Promise.all(
      sectionsList.map(async (sec) => {
        const [secStudents, secAtt] = await Promise.all([
          Student.countDocuments({ sectionId: sec._id, status: 'active', isActive: true }),
          AttendanceRecord.aggregate([
            { $match: { sectionId: sec._id, isCancelled: { $ne: true }, ...dateMatch } },
            {
              $group: {
                _id: null,
                total: { $sum: 1 },
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
        ]);
        const secAttData = secAtt[0] || { total: 0, attended: 0 };
        const percentage = secAttData.total > 0 ? Math.round((secAttData.attended / secAttData.total) * 10000) / 100 : 0;
        return {
          sectionId: sec.id,
          name: sec.name,
          studentsCount: secStudents,
          capacity: sec.capacity,
          attendancePercentage: percentage,
        };
      })
    );

    return {
      role: AppRole.HOD,
      metrics: {
        coursesCount,
        sectionsCount,
        subjectsCount,
        studentsCount,
        facultyCount,
        notesCount,
        sessionsCount,
        departmentAttendancePercentage,
      },
      quickStats: {
        departmentStudents: studentsCount,
        departmentFaculty: facultyCount,
        attendanceRate: departmentAttendancePercentage,
      },
      recentActivity: sectionBreakdown,
    };
  }

  private static async getFacultyDashboard(
    requester: AuthenticatedUser,
    dateMatch: Record<string, unknown>
  ): Promise<RoleDashboardReport> {
    const faculty = await Faculty.findOne({ userId: requester.id });
    if (!faculty) throw ApiError.notFound('Faculty profile not found');

    const [
      conductedSessions,
      notesCount,
      attendanceStats,
      recentSessions,
    ] = await Promise.all([
      AttendanceSession.countDocuments({ facultyId: faculty._id, status: { $ne: AttendanceSessionStatus.CANCELLED }, ...dateMatch }),
      Note.countDocuments({ facultyId: faculty._id, status: NoteStatus.PUBLISHED }),
      AttendanceRecord.aggregate([
        { $match: { facultyId: faculty._id, isCancelled: { $ne: true }, ...dateMatch } },
        {
          $group: {
            _id: null,
            totalRecords: { $sum: 1 },
            present: { $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.PRESENT] }, 1, 0] } },
            late: { $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.LATE] }, 1, 0] } },
          },
        },
      ]),
      AttendanceSession.find({ facultyId: faculty._id, status: { $ne: AttendanceSessionStatus.CANCELLED } })
        .sort({ date: -1 })
        .limit(10)
        .select('date subjectName sectionName timeSlot status recordsCount'),
    ]);

    const attSummary = attendanceStats[0] || { totalRecords: 0, present: 0, late: 0 };
    const overallAttendanceRate =
      attSummary.totalRecords > 0
        ? Math.round(((attSummary.present + attSummary.late) / attSummary.totalRecords) * 10000) / 100
        : 0;

    return {
      role: AppRole.FACULTY,
      metrics: {
        assignedSubjectsCount: faculty.subjectIds?.length || 0,
        assignedSectionsCount: faculty.sectionIds?.length || 0,
        conductedSessionsCount: conductedSessions,
        notesPublishedCount: notesCount,
        overallAttendanceRate,
      },
      quickStats: {
        conductedClasses: conductedSessions,
        publishedNotes: notesCount,
        attendanceRate: overallAttendanceRate,
      },
      recentActivity: recentSessions.map((s) => s.toJSON()),
    };
  }

  private static async getStudentDashboard(
    requester: AuthenticatedUser,
    dateMatch: Record<string, unknown>
  ): Promise<RoleDashboardReport> {
    const student = await Student.findOne({ userId: requester.id });
    if (!student) throw ApiError.notFound('Student profile not found');

    const [attendanceSummary, notesCount, subjectsBreakdown] = await Promise.all([
      this.computeStudentAttendanceSummary(student._id, dateMatch),
      Note.countDocuments({
        $or: [
          { sectionId: student.sectionId },
          { semesterId: student.semesterId },
          { courseId: student.courseId },
        ],
        status: NoteStatus.PUBLISHED,
      }),
      this.computeStudentSubjectsBreakdown(student._id, dateMatch),
    ]);

    return {
      role: AppRole.STUDENT,
      metrics: {
        ...attendanceSummary,
        availableNotesCount: notesCount,
        enrolledSectionId: student.sectionId?.toString(),
        enrolledCourseId: student.courseId?.toString(),
        enrolledSemesterId: student.semesterId?.toString(),
      },
      quickStats: {
        overallAttendance: attendanceSummary.percentage,
        totalClasses: attendanceSummary.totalClasses,
        lowAttendanceAlert: attendanceSummary.percentage < ATTENDANCE_THRESHOLDS.LOW_PERCENTAGE_ALERT,
      },
      recentActivity: subjectsBreakdown as any,
    };
  }

  // =========================================================================
  // 2. ATTENDANCE REPORT METHODS
  // =========================================================================

  /**
   * Generates a comprehensive Student Attendance Report with RBAC and tenant enforcement.
   */
  static async getStudentAttendanceReport(
    targetStudentId: string,
    requester: AuthenticatedUser,
    query: DateRangeQueryInput
  ): Promise<StudentAttendanceReport> {
    // 1. Identify target student
    let studentDoc: any;
    if (targetStudentId === 'me') {
      studentDoc = await Student.findOne({ userId: requester.id });
    } else if (mongoose.Types.ObjectId.isValid(targetStudentId)) {
      studentDoc = await Student.findOne({
        $or: [
          { _id: new mongoose.Types.ObjectId(targetStudentId) },
          { userId: new mongoose.Types.ObjectId(targetStudentId) },
        ],
      });
    }

    if (!studentDoc) {
      throw ApiError.notFound('Student profile not found');
    }

    // 2. Strict RBAC checks
    if (requester.role === AppRole.STUDENT) {
      if (studentDoc.userId.toString() !== requester.id) {
        throw ApiError.forbidden('Students cannot access attendance reports of other students');
      }
    } else if (requester.role === AppRole.COLLEGE_ADMIN) {
      if (studentDoc.collegeId.toString() !== requester.collegeId) {
        throw ApiError.forbidden('Cross-college student report access is strictly prohibited');
      }
    } else if (requester.role === AppRole.HOD) {
      if (
        studentDoc.collegeId.toString() !== requester.collegeId ||
        studentDoc.departmentId.toString() !== requester.departmentId
      ) {
        throw ApiError.forbidden('HOD cannot access reports of students outside assigned department');
      }
    } else if (requester.role === AppRole.FACULTY) {
      if (studentDoc.collegeId.toString() !== requester.collegeId) {
        throw ApiError.forbidden('Cross-college access is strictly prohibited');
      }
    }

    // 3. Date range match
    const { fromDate, toDate } = this.resolveDateBounds(query);
    const dateMatch: Record<string, unknown> = {};
    if (fromDate || toDate) {
      dateMatch.date = {};
      if (fromDate) (dateMatch.date as any).$gte = fromDate;
      if (toDate) (dateMatch.date as any).$lte = toDate;
    }

    // 4. Compute Metrics
    const [summary, subjectsBreakdown] = await Promise.all([
      this.computeStudentAttendanceSummary(studentDoc._id, dateMatch),
      this.computeStudentSubjectsBreakdown(studentDoc._id, dateMatch),
    ]);

    await this.logReportAudit(requester, 'ATTENDANCE_STUDENT', studentDoc.id, {
      studentId: studentDoc.id,
      from: fromDate?.toISOString(),
      to: toDate?.toISOString(),
    });

    return {
      student: {
        id: studentDoc.id,
        studentIdNumber: studentDoc.studentIdNumber,
        rollNumber: studentDoc.rollNumber,
        name: studentDoc.name,
        departmentId: studentDoc.departmentId?.toString(),
        courseId: studentDoc.courseId?.toString(),
        semesterId: studentDoc.semesterId?.toString(),
        sectionId: studentDoc.sectionId?.toString(),
      },
      summary,
      subjectsBreakdown,
      lowAttendanceAlert: summary.percentage < ATTENDANCE_THRESHOLDS.LOW_PERCENTAGE_ALERT,
      dateRange: {
        from: fromDate?.toISOString(),
        to: toDate?.toISOString(),
      },
    };
  }

  /**
   * Generates a Section Attendance Report with student ranking and low-attendance detection.
   */
  static async getSectionAttendanceReport(
    sectionId: string,
    requester: AuthenticatedUser,
    query: DateRangeQueryInput
  ): Promise<SectionAttendanceReport> {
    if (!mongoose.Types.ObjectId.isValid(sectionId)) throw ApiError.badRequest('Invalid Section ID');
    const section = await Section.findById(sectionId);
    if (!section) throw ApiError.notFound('Section not found');

    // RBAC & Tenant Verification
    if (requester.role === AppRole.STUDENT) {
      throw ApiError.forbidden('Students are not authorized to access section-wide attendance reports');
    }
    if (requester.role === AppRole.COLLEGE_ADMIN && section.collegeId.toString() !== requester.collegeId) {
      throw ApiError.forbidden('Cross-college access is strictly prohibited');
    }
    if (requester.role === AppRole.HOD) {
      if (section.collegeId.toString() !== requester.collegeId || section.departmentId.toString() !== requester.departmentId) {
        throw ApiError.forbidden('HOD cannot access section reports outside their department');
      }
    }

    const { fromDate, toDate } = this.resolveDateBounds(query);
    const dateMatch: Record<string, unknown> = {};
    if (fromDate || toDate) {
      dateMatch.date = {};
      if (fromDate) (dateMatch.date as any).$gte = fromDate;
      if (toDate) (dateMatch.date as any).$lte = toDate;
    }

    const secObjId = section._id;

    // 1. Overall Summary & Sessions
    const [records, sessionsCount, subjectAgg] = await Promise.all([
      AttendanceRecord.find({ sectionId: secObjId, isCancelled: { $ne: true }, ...dateMatch }),
      AttendanceSession.countDocuments({
        sectionId: secObjId,
        status: { $ne: AttendanceSessionStatus.CANCELLED },
        ...dateMatch,
      }),
      AttendanceRecord.aggregate([
        { $match: { sectionId: secObjId, isCancelled: { $ne: true }, ...dateMatch } },
        {
          $group: {
            _id: '$subjectId',
            totalClasses: { $sum: 1 },
            attended: {
              $sum: { $cond: [{ $in: ['$status', [AttendanceStatus.PRESENT, AttendanceStatus.LATE]] }, 1, 0] },
            },
          },
        },
      ]),
    ]);

    const totalClasses = records.length;
    const present = records.filter((r) => r.status === AttendanceStatus.PRESENT).length;
    const late = records.filter((r) => r.status === AttendanceStatus.LATE).length;
    const absent = records.filter((r) => r.status === AttendanceStatus.ABSENT).length;
    const excused = records.filter((r) => r.status === AttendanceStatus.EXCUSED).length;
    const percentage = totalClasses === 0 ? 0 : Math.round(((present + late) / totalClasses) * 10000) / 100;

    // 2. Student Rankings
    const studentMap = new Map<string, { name: string; rollNumber: string; total: number; present: number; late: number; absent: number }>();
    records.forEach((r) => {
      const sid = r.studentId.toString();
      const curr = studentMap.get(sid) || {
        name: r.studentName,
        rollNumber: r.rollNumber,
        total: 0,
        present: 0,
        late: 0,
        absent: 0,
      };
      curr.total += 1;
      if (r.status === AttendanceStatus.PRESENT) curr.present += 1;
      if (r.status === AttendanceStatus.LATE) curr.late += 1;
      if (r.status === AttendanceStatus.ABSENT) curr.absent += 1;
      studentMap.set(sid, curr);
    });

    const students: StudentAttendanceRankItem[] = Array.from(studentMap.entries()).map(([sid, data]) => {
      const stuPerc = data.total === 0 ? 0 : Math.round(((data.present + data.late) / data.total) * 10000) / 100;
      return {
        studentId: sid,
        name: data.name,
        rollNumber: data.rollNumber,
        totalClasses: data.total,
        present: data.present,
        late: data.late,
        absent: data.absent,
        percentage: stuPerc,
        isLowAttendance: stuPerc < ATTENDANCE_THRESHOLDS.LOW_PERCENTAGE_ALERT,
      };
    });

    // Sort by attendance percentage descending
    students.sort((a, b) => b.percentage - a.percentage);
    const lowAttendanceCount = students.filter((s) => s.isLowAttendance).length;

    // 3. Subject Breakdown
    const subjects = await Subject.find({ _id: { $in: subjectAgg.map((s) => s._id) } });
    const subMap = new Map<string, { name: string; code: string }>();
    subjects.forEach((s) => subMap.set(s._id.toString(), { name: s.name, code: s.code }));

    const subjectBreakdown = subjectAgg.map((s) => {
      const subInfo = subMap.get(s._id.toString()) || { name: 'Subject', code: 'SUB' };
      const subPerc = s.totalClasses === 0 ? 0 : Math.round((s.attended / s.totalClasses) * 10000) / 100;
      return {
        subjectId: s._id.toString(),
        subjectName: subInfo.name,
        subjectCode: subInfo.code,
        totalSessions: s.totalClasses,
        attendancePercentage: subPerc,
      };
    });

    await this.logReportAudit(requester, 'ATTENDANCE_SECTION', section.id, { sectionId: section.id });

    return {
      section: {
        id: section.id,
        name: section.name,
        departmentId: section.departmentId.toString(),
        courseId: section.courseId.toString(),
        semesterId: section.semesterId.toString(),
      },
      summary: {
        totalClasses,
        present,
        late,
        absent,
        excused,
        percentage,
        totalSessions: sessionsCount,
      },
      subjectBreakdown,
      students,
      lowAttendanceCount,
    };
  }

  /**
   * Generates a Department Attendance Report comparing all sections and subjects.
   */
  static async getDepartmentAttendanceReport(
    departmentId: string,
    requester: AuthenticatedUser,
    query: DateRangeQueryInput
  ): Promise<DepartmentAttendanceReport> {
    if (!mongoose.Types.ObjectId.isValid(departmentId)) throw ApiError.badRequest('Invalid Department ID');
    const department = await Department.findById(departmentId);
    if (!department) throw ApiError.notFound('Department not found');

    // RBAC & Tenant Check
    if (requester.role === AppRole.STUDENT || requester.role === AppRole.FACULTY) {
      throw ApiError.forbidden('Unauthorized role for department attendance report');
    }
    if (requester.role === AppRole.COLLEGE_ADMIN && department.collegeId.toString() !== requester.collegeId) {
      throw ApiError.forbidden('Cross-college access is strictly prohibited');
    }
    if (requester.role === AppRole.HOD && department.id !== requester.departmentId) {
      throw ApiError.forbidden('HOD cannot access reports of another department');
    }

    const { fromDate, toDate } = this.resolveDateBounds(query);
    const dateMatch: Record<string, unknown> = {};
    if (fromDate || toDate) {
      dateMatch.date = {};
      if (fromDate) (dateMatch.date as any).$gte = fromDate;
      if (toDate) (dateMatch.date as any).$lte = toDate;
    }

    const deptObjId = department._id;

    // 1. Overall Summary
    const [sections, subjects] = await Promise.all([
      Section.find({ departmentId: deptObjId, isActive: true }),
      Subject.find({ departmentId: deptObjId, isActive: true }),
    ]);
    const secIds = sections.map((s) => s._id);

    const deptRecords = await AttendanceRecord.aggregate([
      { $match: { sectionId: { $in: secIds }, isCancelled: { $ne: true }, ...dateMatch } },
      {
        $group: {
          _id: null,
          total: { $sum: 1 },
          present: { $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.PRESENT] }, 1, 0] } },
          late: { $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.LATE] }, 1, 0] } },
          absent: { $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.ABSENT] }, 1, 0] } },
          excused: { $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.EXCUSED] }, 1, 0] } },
        },
      },
    ]);

    const summaryData = deptRecords[0] || { total: 0, present: 0, late: 0, absent: 0, excused: 0 };
    const percentage =
      summaryData.total > 0
        ? Math.round(((summaryData.present + summaryData.late) / summaryData.total) * 10000) / 100
        : 0;

    // 2. Sections comparison
    const sectionsComparison = await Promise.all(
      sections.map(async (sec) => {
        const [stuCount, secAtt] = await Promise.all([
          Student.countDocuments({ sectionId: sec._id, status: 'active', isActive: true }),
          AttendanceRecord.aggregate([
            { $match: { sectionId: sec._id, isCancelled: { $ne: true }, ...dateMatch } },
            {
              $group: {
                _id: null,
                total: { $sum: 1 },
                attended: { $sum: { $cond: [{ $in: ['$status', [AttendanceStatus.PRESENT, AttendanceStatus.LATE]] }, 1, 0] } },
              },
            },
          ]),
        ]);
        const secData = secAtt[0] || { total: 0, attended: 0 };
        const secPerc = secData.total > 0 ? Math.round((secData.attended / secData.total) * 10000) / 100 : 0;
        return {
          sectionId: sec.id,
          sectionName: sec.name,
          totalStudents: stuCount,
          attendancePercentage: secPerc,
        };
      })
    );

    // 3. Subjects comparison
    const subjectsComparison = await Promise.all(
      subjects.map(async (sub) => {
        const subAtt = await AttendanceRecord.aggregate([
          { $match: { subjectId: sub._id, isCancelled: { $ne: true }, ...dateMatch } },
          {
            $group: {
              _id: null,
              total: { $sum: 1 },
              attended: { $sum: { $cond: [{ $in: ['$status', [AttendanceStatus.PRESENT, AttendanceStatus.LATE]] }, 1, 0] } },
            },
          },
        ]);
        const subData = subAtt[0] || { total: 0, attended: 0 };
        const subPerc = subData.total > 0 ? Math.round((subData.attended / subData.total) * 10000) / 100 : 0;
        return {
          subjectId: sub.id,
          subjectName: sub.name,
          subjectCode: sub.code,
          attendancePercentage: subPerc,
        };
      })
    );

    // 4. Low attendance students count in department
    const studentAgg = await AttendanceRecord.aggregate([
      { $match: { sectionId: { $in: secIds }, isCancelled: { $ne: true }, ...dateMatch } },
      {
        $group: {
          _id: '$studentId',
          total: { $sum: 1 },
          attended: { $sum: { $cond: [{ $in: ['$status', [AttendanceStatus.PRESENT, AttendanceStatus.LATE]] }, 1, 0] } },
        },
      },
    ]);
    const lowAttendanceStudentsCount = studentAgg.filter(
      (s) => s.total > 0 && (s.attended / s.total) * 100 < ATTENDANCE_THRESHOLDS.LOW_PERCENTAGE_ALERT
    ).length;

    await this.logReportAudit(requester, 'ATTENDANCE_DEPARTMENT', department.id, { departmentId: department.id });

    const [totalFaculty, totalStudents] = await Promise.all([
      User.countDocuments({
        collegeId: department.collegeId,
        departmentId: deptObjId,
        role: AppRole.FACULTY,
        accountStatus: AccountStatus.ACTIVE,
      }),
      Student.countDocuments({
        collegeId: department.collegeId,
        departmentId: deptObjId,
        status: 'active',
        isActive: true,
      }),
    ]);

    return {
      department: {
        id: department.id,
        name: department.name,
        code: department.code,
      },
      summary: {
        totalClasses: summaryData.total,
        present: summaryData.present,
        late: summaryData.late,
        absent: summaryData.absent,
        excused: summaryData.excused,
        percentage,
        totalFaculty,
        totalStudents,
      },
      sectionsComparison,
      subjectsComparison,
      lowAttendanceStudentsCount,
    };
  }

  /**
   * Generates a College Attendance Report comparing all departments.
   */
  static async getCollegeAttendanceReport(
    collegeId: string,
    requester: AuthenticatedUser,
    query: DateRangeQueryInput
  ): Promise<CollegeAttendanceReport> {
    if (!mongoose.Types.ObjectId.isValid(collegeId)) throw ApiError.badRequest('Invalid College ID');
    const college = await College.findById(collegeId);
    if (!college) throw ApiError.notFound('College not found');

    // RBAC & Tenant Check
    if (requester.role !== AppRole.SUPER_ADMIN && (requester.role !== AppRole.COLLEGE_ADMIN || requester.collegeId !== collegeId)) {
      throw ApiError.forbidden('Unauthorized to access college-wide attendance report');
    }

    const { fromDate, toDate } = this.resolveDateBounds(query);
    const dateMatch: Record<string, unknown> = {};
    if (fromDate || toDate) {
      dateMatch.date = {};
      if (fromDate) (dateMatch.date as any).$gte = fromDate;
      if (toDate) (dateMatch.date as any).$lte = toDate;
    }

    const colObjId = college._id;

    const [collegeRecords, totalSessions, departments] = await Promise.all([
      AttendanceRecord.aggregate([
        { $match: { collegeId: colObjId, isCancelled: { $ne: true }, ...dateMatch } },
        {
          $group: {
            _id: null,
            total: { $sum: 1 },
            present: { $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.PRESENT] }, 1, 0] } },
            late: { $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.LATE] }, 1, 0] } },
            absent: { $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.ABSENT] }, 1, 0] } },
            excused: { $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.EXCUSED] }, 1, 0] } },
          },
        },
      ]),
      AttendanceSession.countDocuments({
        collegeId: colObjId,
        status: { $ne: AttendanceSessionStatus.CANCELLED },
        ...dateMatch,
      }),
      Department.find({ collegeId: colObjId, isActive: true }),
    ]);

    const summaryData = collegeRecords[0] || { total: 0, present: 0, late: 0, absent: 0, excused: 0 };
    const percentage =
      summaryData.total > 0
        ? Math.round(((summaryData.present + summaryData.late) / summaryData.total) * 10000) / 100
        : 0;

    const lowAttendanceDepartments: string[] = [];
    const departmentComparison = await Promise.all(
      departments.map(async (dept) => {
        const deptSections = await Section.find({ departmentId: dept._id, isActive: true }).select('_id');
        const secIds = deptSections.map((s) => s._id);

        const [stuCount, deptAtt] = await Promise.all([
          Student.countDocuments({ departmentId: dept._id, status: 'active', isActive: true }),
          AttendanceRecord.aggregate([
            { $match: { sectionId: { $in: secIds }, isCancelled: { $ne: true }, ...dateMatch } },
            {
              $group: {
                _id: null,
                total: { $sum: 1 },
                attended: { $sum: { $cond: [{ $in: ['$status', [AttendanceStatus.PRESENT, AttendanceStatus.LATE]] }, 1, 0] } },
              },
            },
          ]),
        ]);
        const deptData = deptAtt[0] || { total: 0, attended: 0 };
        const deptPerc = deptData.total > 0 ? Math.round((deptData.attended / deptData.total) * 10000) / 100 : 0;
        if (deptPerc > 0 && deptPerc < ATTENDANCE_THRESHOLDS.LOW_PERCENTAGE_ALERT) {
          lowAttendanceDepartments.push(dept.name);
        }
        return {
          departmentId: dept.id,
          departmentName: dept.name,
          departmentCode: dept.code,
          totalStudents: stuCount,
          attendancePercentage: deptPerc,
        };
      })
    );

    await this.logReportAudit(requester, 'ATTENDANCE_COLLEGE', college.id, { collegeId: college.id });

    return {
      college: {
        id: college.id,
        name: college.name,
        code: college.code,
      },
      summary: {
        totalClasses: summaryData.total,
        present: summaryData.present,
        late: summaryData.late,
        absent: summaryData.absent,
        excused: summaryData.excused,
        percentage,
      },
      departmentComparison,
      totalSessionsConducted: totalSessions,
      lowAttendanceDepartments,
    };
  }

  /**
   * Generates a Subject Attendance Report across sections.
   */
  static async getSubjectAttendanceReport(
    subjectId: string,
    requester: AuthenticatedUser,
    query: DateRangeQueryInput
  ): Promise<{
    subject: { id: string; name: string; code: string };
    summary: AttendanceSummaryMetrics;
    sectionsBreakdown: Array<{
      sectionId: string;
      sectionName: string;
      totalClasses: number;
      attendancePercentage: number;
    }>;
  }> {
    if (!mongoose.Types.ObjectId.isValid(subjectId)) throw ApiError.badRequest('Invalid Subject ID');
    const subject = await Subject.findById(subjectId);
    if (!subject) throw ApiError.notFound('Subject not found');

    // RBAC & Tenant Check
    if (requester.role === AppRole.COLLEGE_ADMIN && subject.collegeId.toString() !== requester.collegeId) {
      throw ApiError.forbidden('Cross-college access is strictly prohibited');
    }
    if (requester.role === AppRole.HOD) {
      if (subject.collegeId.toString() !== requester.collegeId || subject.departmentId.toString() !== requester.departmentId) {
        throw ApiError.forbidden('HOD cannot access reports of subjects outside assigned department');
      }
    }

    const { fromDate, toDate } = this.resolveDateBounds(query);
    const dateMatch: Record<string, unknown> = {};
    if (fromDate || toDate) {
      dateMatch.date = {};
      if (fromDate) (dateMatch.date as any).$gte = fromDate;
      if (toDate) (dateMatch.date as any).$lte = toDate;
    }

    const subObjId = subject._id;

    const [records, sectionAgg] = await Promise.all([
      AttendanceRecord.aggregate([
        { $match: { subjectId: subObjId, isCancelled: { $ne: true }, ...dateMatch } },
        {
          $group: {
            _id: null,
            total: { $sum: 1 },
            present: { $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.PRESENT] }, 1, 0] } },
            late: { $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.LATE] }, 1, 0] } },
            absent: { $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.ABSENT] }, 1, 0] } },
            excused: { $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.EXCUSED] }, 1, 0] } },
          },
        },
      ]),
      AttendanceRecord.aggregate([
        { $match: { subjectId: subObjId, isCancelled: { $ne: true }, ...dateMatch } },
        {
          $group: {
            _id: '$sectionId',
            total: { $sum: 1 },
            attended: { $sum: { $cond: [{ $in: ['$status', [AttendanceStatus.PRESENT, AttendanceStatus.LATE]] }, 1, 0] } },
          },
        },
      ]),
    ]);

    const summaryData = records[0] || { total: 0, present: 0, late: 0, absent: 0, excused: 0 };
    const percentage =
      summaryData.total > 0
        ? Math.round(((summaryData.present + summaryData.late) / summaryData.total) * 10000) / 100
        : 0;

    const sections = await Section.find({ _id: { $in: sectionAgg.map((s) => s._id) } });
    const secMap = new Map<string, string>();
    sections.forEach((sec) => secMap.set(sec._id.toString(), sec.name));

    const sectionsBreakdown = sectionAgg.map((s) => {
      const secName = secMap.get(s._id.toString()) || 'Section';
      const secPerc = s.total > 0 ? Math.round((s.attended / s.total) * 10000) / 100 : 0;
      return {
        sectionId: s._id.toString(),
        sectionName: secName,
        totalClasses: s.total,
        attendancePercentage: secPerc,
      };
    });

    await this.logReportAudit(requester, 'ATTENDANCE_SUBJECT', subject.id, { subjectId: subject.id });

    return {
      subject: {
        id: subject.id,
        name: subject.name,
        code: subject.code,
      },
      summary: {
        totalClasses: summaryData.total,
        present: summaryData.present,
        late: summaryData.late,
        absent: summaryData.absent,
        excused: summaryData.excused,
        percentage,
      },
      sectionsBreakdown,
    };
  }

  // =========================================================================
  // 3. FACULTY ACTIVITY REPORTS
  // =========================================================================

  static async getFacultyReport(
    targetFacultyId: string,
    requester: AuthenticatedUser,
    query: DateRangeQueryInput
  ): Promise<FacultyActivityReport> {
    let facultyDoc: any;

    if (targetFacultyId === 'me') {
      facultyDoc = await Faculty.findOne({ userId: requester.id });
    } else if (mongoose.Types.ObjectId.isValid(targetFacultyId)) {
      facultyDoc = await Faculty.findOne({
        $or: [
          { _id: new mongoose.Types.ObjectId(targetFacultyId) },
          { userId: new mongoose.Types.ObjectId(targetFacultyId) },
        ],
      });
    }

    if (!facultyDoc) {
      throw ApiError.notFound('Faculty profile not found');
    }

    // RBAC & Tenant Check
    if (requester.role === AppRole.FACULTY) {
      if (facultyDoc.userId.toString() !== requester.id) {
        throw ApiError.forbidden('Faculty cannot access activity reports of other faculty members');
      }
    } else if (requester.role === AppRole.COLLEGE_ADMIN) {
      if (facultyDoc.collegeId.toString() !== requester.collegeId) {
        throw ApiError.forbidden('Cross-college access is strictly prohibited');
      }
    } else if (requester.role === AppRole.HOD) {
      if (
        facultyDoc.collegeId.toString() !== requester.collegeId ||
        facultyDoc.departmentId.toString() !== requester.departmentId
      ) {
        throw ApiError.forbidden('HOD cannot access reports of faculty outside assigned department');
      }
    } else if (requester.role === AppRole.STUDENT) {
      throw ApiError.forbidden('Students are not authorized to view faculty activity reports');
    }

    const { fromDate, toDate } = this.resolveDateBounds(query);
    const dateMatch: Record<string, unknown> = {};
    if (fromDate || toDate) {
      dateMatch.date = {};
      if (fromDate) (dateMatch.date as any).$gte = fromDate;
      if (toDate) (dateMatch.date as any).$lte = toDate;
    }

    const facObjId = facultyDoc._id;

    const [
      sessionsCount,
      attSummaryAgg,
      uniqueStudentsAgg,
      subjectAgg,
      sectionAgg,
      recentSessions,
    ] = await Promise.all([
      AttendanceSession.countDocuments({
        facultyId: facObjId,
        status: { $ne: AttendanceSessionStatus.CANCELLED },
        ...dateMatch,
      }),
      AttendanceRecord.aggregate([
        { $match: { facultyId: facObjId, isCancelled: { $ne: true }, ...dateMatch } },
        {
          $group: {
            _id: null,
            total: { $sum: 1 },
            attended: { $sum: { $cond: [{ $in: ['$status', [AttendanceStatus.PRESENT, AttendanceStatus.LATE]] }, 1, 0] } },
          },
        },
      ]),
      AttendanceRecord.distinct('studentId', { facultyId: facObjId, isCancelled: { $ne: true }, ...dateMatch }),
      AttendanceRecord.aggregate([
        { $match: { facultyId: facObjId, isCancelled: { $ne: true }, ...dateMatch } },
        {
          $group: {
            _id: '$subjectId',
            total: { $sum: 1 },
            attended: { $sum: { $cond: [{ $in: ['$status', [AttendanceStatus.PRESENT, AttendanceStatus.LATE]] }, 1, 0] } },
          },
        },
      ]),
      AttendanceRecord.aggregate([
        { $match: { facultyId: facObjId, isCancelled: { $ne: true }, ...dateMatch } },
        {
          $group: {
            _id: '$sectionId',
            total: { $sum: 1 },
            attended: { $sum: { $cond: [{ $in: ['$status', [AttendanceStatus.PRESENT, AttendanceStatus.LATE]] }, 1, 0] } },
          },
        },
      ]),
      AttendanceSession.find({
        facultyId: facObjId,
        status: { $ne: AttendanceSessionStatus.CANCELLED },
        ...dateMatch,
      })
        .sort({ date: -1 })
        .limit(10),
    ]);

    const attSummary = attSummaryAgg[0] || { total: 0, attended: 0 };
    const overallAttendanceRate =
      attSummary.total > 0 ? Math.round((attSummary.attended / attSummary.total) * 10000) / 100 : 0;

    // Subjects lookup
    const subjectIds = subjectAgg.map((s) => s._id);
    const subjects = await Subject.find({ _id: { $in: subjectIds } }).select('name code');
    const subMap = new Map<string, { name: string; code: string }>();
    subjects.forEach((sub) => subMap.set(sub._id.toString(), { name: sub.name, code: sub.code }));

    const subjectsBreakdown = subjectAgg.map((s) => {
      const subInfo = subMap.get(s._id.toString()) || { name: 'Subject', code: 'SUB' };
      const subPerc = s.total > 0 ? Math.round((s.attended / s.total) * 10000) / 100 : 0;
      return {
        subjectId: s._id.toString(),
        subjectName: subInfo.name,
        subjectCode: subInfo.code,
        sessionsCount: s.total,
        averageAttendancePercentage: subPerc,
      };
    });

    // Sections lookup
    const sectionIds = sectionAgg.map((s) => s._id);
    const sections = await Section.find({ _id: { $in: sectionIds } }).select('name');
    const secMap = new Map<string, string>();
    sections.forEach((sec) => secMap.set(sec._id.toString(), sec.name));

    const sectionsBreakdown = sectionAgg.map((s) => {
      const secName = secMap.get(s._id.toString()) || 'Section';
      const secPerc = s.total > 0 ? Math.round((s.attended / s.total) * 10000) / 100 : 0;
      return {
        sectionId: s._id.toString(),
        sectionName: secName,
        sessionsCount: s.total,
        averageAttendancePercentage: secPerc,
      };
    });

    await this.logReportAudit(requester, 'FACULTY_ACTIVITY', facultyDoc.id, { facultyId: facultyDoc.id });

    return {
      faculty: {
        id: facultyDoc.id,
        name: facultyDoc.name,
        instituteId: facultyDoc.instituteId,
        designation: facultyDoc.designation,
        departmentId: facultyDoc.departmentId.toString(),
      },
      conductedSessionsCount: sessionsCount,
      overallAttendanceRate,
      uniqueStudentsTaught: uniqueStudentsAgg.length,
      subjectsBreakdown,
      sectionsBreakdown,
      recentSessions: recentSessions.map((s) => ({
        sessionId: s.id,
        date: s.date ? s.date.toISOString() : '',
        subjectName: (s as any).subjectName || '',
        sectionName: (s as any).sectionName || '',
        markedCount: (s as any).recordsCount || 0,
      })),
    };
  }

  // =========================================================================
  // 4. ACADEMIC HIERARCHY & TIMETABLE COVERAGE REPORT
  // =========================================================================

  static async getAcademicReport(
    requester: AuthenticatedUser,
    query: DateRangeQueryInput
  ): Promise<AcademicHierarchyReport> {
    const filter: Record<string, unknown> = {};

    if (requester.role === AppRole.COLLEGE_ADMIN) {
      filter.collegeId = new mongoose.Types.ObjectId(requester.collegeId);
    } else if (requester.role === AppRole.HOD) {
      filter.collegeId = new mongoose.Types.ObjectId(requester.collegeId);
      filter.departmentId = new mongoose.Types.ObjectId(requester.departmentId);
    } else if (requester.role === AppRole.SUPER_ADMIN) {
      if (query.collegeId && mongoose.Types.ObjectId.isValid(query.collegeId)) {
        filter.collegeId = new mongoose.Types.ObjectId(query.collegeId);
      }
    } else {
      throw ApiError.forbidden('Unauthorized role for academic hierarchy report');
    }

    const [
      totalDepartments,
      totalCourses,
      totalSemesters,
      totalSections,
      totalSubjects,
      totalStudents,
      totalFaculty,
      totalHod,
      sectionsList,
      timetables,
    ] = await Promise.all([
      Department.countDocuments({ ...filter, isActive: true }),
      Course.countDocuments({ ...filter, isActive: true }),
      Semester.countDocuments({ ...filter, isActive: true }),
      Section.countDocuments({ ...filter, isActive: true }),
      Subject.countDocuments({ ...filter, isActive: true }),
      Student.countDocuments({ ...filter, status: 'active', isActive: true }),
      Faculty.countDocuments({ ...filter, status: 'active', isActive: true }),
      User.countDocuments({ ...filter, role: AppRole.HOD }),
      Section.find({ ...filter, isActive: true }).select('capacity'),
      Timetable.find(filter).select('sectionId status'),
    ]);

    const totalCapacity = sectionsList.reduce((acc, curr) => acc + (curr.capacity || 0), 0);
    const utilizationRate = totalCapacity > 0 ? Math.round((totalStudents / totalCapacity) * 10000) / 100 : 0;

    const publishedTimetables = timetables.filter((t) => t.status === TimetableStatus.PUBLISHED).length;
    const draftTimetables = timetables.filter((t) => t.status === TimetableStatus.DRAFT).length;
    const coveragePercentage = totalSections > 0 ? Math.round((publishedTimetables / totalSections) * 10000) / 100 : 0;

    await this.logReportAudit(requester, 'ACADEMIC_HIERARCHY', 'academic', { filter });

    return {
      collegeId: filter.collegeId ? filter.collegeId.toString() : undefined,
      summary: {
        totalDepartments,
        totalCourses,
        totalSemesters,
        totalSections,
        totalSubjects,
        totalStudents,
        totalFaculty,
        totalHod,
      },
      enrollmentCapacity: {
        totalCapacity,
        totalEnrolled: totalStudents,
        utilizationRate,
      },
      timetableCoverage: {
        totalSections,
        publishedTimetables,
        draftTimetables,
        coveragePercentage,
      },
    };
  }

  // =========================================================================
  // 5. NOTES / CONTENT METRICS REPORT
  // =========================================================================

  static async getNotesReport(
    requester: AuthenticatedUser,
    query: DateRangeQueryInput
  ): Promise<NotesReport> {
    const filter: Record<string, unknown> = {};

    if (requester.role === AppRole.COLLEGE_ADMIN) {
      filter.collegeId = new mongoose.Types.ObjectId(requester.collegeId);
    } else if (requester.role === AppRole.HOD) {
      filter.collegeId = new mongoose.Types.ObjectId(requester.collegeId);
      filter.departmentId = new mongoose.Types.ObjectId(requester.departmentId);
    } else if (requester.role === AppRole.SUPER_ADMIN) {
      if (query.collegeId && mongoose.Types.ObjectId.isValid(query.collegeId)) {
        filter.collegeId = new mongoose.Types.ObjectId(query.collegeId);
      }
    } else if (requester.role === AppRole.FACULTY) {
      filter.facultyId = new mongoose.Types.ObjectId(requester.id);
    } else {
      throw ApiError.forbidden('Unauthorized role for notes analytics report');
    }

    const [
      totalNotes,
      publishedNotes,
      archivedNotes,
      storageAgg,
      bySubjectAgg,
      byDeptAgg,
      recentNotes,
    ] = await Promise.all([
      Note.countDocuments(filter),
      Note.countDocuments({ ...filter, status: NoteStatus.PUBLISHED }),
      Note.countDocuments({ ...filter, status: NoteStatus.ARCHIVED }),
      Note.aggregate([
        { $match: { ...filter, status: NoteStatus.PUBLISHED } },
        { $group: { _id: null, totalBytes: { $sum: '$fileSize' } } },
      ]),
      Note.aggregate([
        { $match: { ...filter, status: NoteStatus.PUBLISHED } },
        { $group: { _id: '$subjectId', count: { $sum: 1 }, bytes: { $sum: '$fileSize' } } },
      ]),
      Note.aggregate([
        { $match: { ...filter, status: NoteStatus.PUBLISHED } },
        { $group: { _id: '$departmentId', count: { $sum: 1 } } },
      ]),
      Note.find({ ...filter, status: NoteStatus.PUBLISHED })
        .sort({ createdAt: -1 })
        .limit(10)
        .select('title subjectName facultyName createdAt fileSize'),
    ]);

    const totalStorageBytes = storageAgg[0]?.totalBytes || 0;

    // Resolve subjects
    const subjects = await Subject.find({ _id: { $in: bySubjectAgg.map((s) => s._id) } });
    const subMap = new Map<string, string>();
    subjects.forEach((s) => subMap.set(s._id.toString(), s.name));

    const bySubject = bySubjectAgg.map((s) => ({
      subjectId: s._id ? s._id.toString() : '',
      subjectName: subMap.get(s._id ? s._id.toString() : '') || 'Subject',
      notesCount: s.count,
      totalBytes: s.bytes || 0,
    }));

    // Resolve departments
    const departments = await Department.find({ _id: { $in: byDeptAgg.map((d) => d._id) } });
    const deptMap = new Map<string, string>();
    departments.forEach((d) => deptMap.set(d._id.toString(), d.name));

    const byDepartment = byDeptAgg.map((d) => ({
      departmentId: d._id ? d._id.toString() : '',
      departmentName: deptMap.get(d._id ? d._id.toString() : '') || 'Department',
      notesCount: d.count,
    }));

    await this.logReportAudit(requester, 'NOTES_CONTENT', 'notes', { filter });

    return {
      collegeId: filter.collegeId ? filter.collegeId.toString() : undefined,
      summary: {
        totalNotes,
        publishedNotes,
        archivedNotes,
        totalStorageBytes,
      },
      bySubject,
      byDepartment,
      recentNotes: recentNotes.map((n) => ({
        id: n.id,
        title: n.title,
        subjectName: (n as any).subjectName || '',
        facultyName: (n as any).facultyName || '',
        createdAt: n.createdAt ? n.createdAt.toISOString() : '',
        fileSize: n.fileSize || 0,
      })),
    };
  }

  // =========================================================================
  // HELPER AGGREGATIONS & AUDIT
  // =========================================================================

  private static async computeStudentAttendanceSummary(
    studentId: mongoose.Types.ObjectId,
    dateMatch: Record<string, unknown> = {}
  ): Promise<AttendanceSummaryMetrics> {
    const stats = await AttendanceRecord.aggregate([
      { $match: { studentId, isCancelled: { $ne: true }, ...dateMatch } },
      {
        $group: {
          _id: null,
          total: { $sum: 1 },
          present: { $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.PRESENT] }, 1, 0] } },
          late: { $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.LATE] }, 1, 0] } },
          absent: { $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.ABSENT] }, 1, 0] } },
          excused: { $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.EXCUSED] }, 1, 0] } },
        },
      },
    ]);

    const data = stats[0] || { total: 0, present: 0, late: 0, absent: 0, excused: 0 };
    const percentage = data.total === 0 ? 0 : Math.round(((data.present + data.late) / data.total) * 10000) / 100;

    return {
      totalClasses: data.total,
      present: data.present,
      late: data.late,
      absent: data.absent,
      excused: data.excused,
      percentage,
    };
  }

  private static async computeStudentSubjectsBreakdown(
    studentId: mongoose.Types.ObjectId,
    dateMatch: Record<string, unknown> = {}
  ): Promise<SubjectAttendanceMetrics[]> {
    const results = await AttendanceRecord.aggregate([
      { $match: { studentId, isCancelled: { $ne: true }, ...dateMatch } },
      {
        $group: {
          _id: '$subjectId',
          total: { $sum: 1 },
          present: { $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.PRESENT] }, 1, 0] } },
          late: { $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.LATE] }, 1, 0] } },
          absent: { $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.ABSENT] }, 1, 0] } },
          excused: { $sum: { $cond: [{ $eq: ['$status', AttendanceStatus.EXCUSED] }, 1, 0] } },
        },
      },
    ]);

    const subjects = await Subject.find({ _id: { $in: results.map((r) => r._id) } });
    const subMap = new Map<string, { name: string; code: string }>();
    subjects.forEach((s) => subMap.set(s._id.toString(), { name: s.name, code: s.code }));

    return results.map((r) => {
      const subId = r._id ? r._id.toString() : '';
      const subInfo = subMap.get(subId) || { name: 'Subject', code: 'SUB' };
      const attended = r.present + r.late;
      const percentage = r.total === 0 ? 0 : Math.round((attended / r.total) * 10000) / 100;
      return {
        subjectId: subId,
        subjectName: subInfo.name,
        subjectCode: subInfo.code,
        totalClasses: r.total,
        present: r.present,
        late: r.late,
        absent: r.absent,
        excused: r.excused,
        percentage,
        isLowAttendance: percentage < ATTENDANCE_THRESHOLDS.LOW_PERCENTAGE_ALERT,
      };
    });
  }

  private static async logReportAudit(
    requester: AuthenticatedUser,
    reportType: string,
    entityId: string,
    filters?: Record<string, unknown>
  ): Promise<void> {
    try {
      await AuditLog.create({
        collegeId: requester.collegeId && requester.collegeId !== 'global' ? requester.collegeId : undefined,
        actorUserId: requester.id,
        action: 'REPORT_GENERATED',
        entityType: 'Report',
        entityId,
        newValue: {
          reportType,
          role: requester.role,
          filters,
        },
      });
    } catch {
      // Non-blocking audit failure
    }
  }
}
