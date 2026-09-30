import mongoose from 'mongoose';
import { User } from '../models/user.model';
import { Course, ICourse } from '../models/course.model';
import { AcademicYear, IAcademicYear, validateAcademicYearOperationalCycle } from '../models/academicYear.model';
import { InstitutionConfiguration } from '../models/institutionConfiguration.model';
import { Semester, ISemester } from '../models/semester.model';
import { Section, ISection } from '../models/section.model';
import { Subject, ISubject } from '../models/subject.model';
import { Student } from '../models/student.model';
import { StudentEnrollment, IStudentEnrollment } from '../models/studentEnrollment.model';
import { Faculty } from '../models/faculty.model';
import { FacultyAssignment, IFacultyAssignment } from '../models/facultyAssignment.model';
import { College } from '../models/college.model';
import { Department } from '../models/department.model';
import { AttendanceSession } from '../models/attendanceSession.model';
import { Timetable } from '../models/timetable.model';
import { AuditLog } from '../models/auditLog.model';
import { AppRole } from '../constants/roles';
import { CollegeStatus, DepartmentStatus, AccountStatus, TimetableStatus, AcademicYearStatus } from '../constants/status';
import { ApiError } from '../utils/apiError';
import { AuthenticatedUser } from '../types/auth.types';
import { realtimeEventBus, AcadexEventType } from '../realtime';

export class AcademicService {
  // =========================================================================
  // 1. COURSE MANAGEMENT
  // =========================================================================

  static async createCourse(
    collegeId: string,
    data: { departmentId: string; name: string; code: string; duration?: number },
    requester: AuthenticatedUser
  ): Promise<ICourse> {
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD].includes(requester.role)) {
      throw ApiError.forbidden('Only administrators and HODs have permission to create courses');
    }

    if (!mongoose.Types.ObjectId.isValid(data.departmentId)) {
      throw ApiError.badRequest(`Invalid Department ID format: "${data.departmentId}"`);
    }

    const dept = await Department.findById(data.departmentId);
    if (!dept) {
      throw ApiError.notFound('Department not found or is no longer available');
    }

    if (dept.status === DepartmentStatus.INACTIVE || !dept.isActive) {
      throw ApiError.forbidden('Cannot create course for an inactive department');
    }

    if (dept.collegeId.toString() !== collegeId) {
      throw ApiError.badRequest('Department does not belong to the specified college');
    }

    if (requester.role === AppRole.COLLEGE_ADMIN && requester.collegeId !== collegeId) {
      throw ApiError.forbidden('Cross-college course creation is strictly prohibited');
    }

    if (requester.role === AppRole.HOD && requester.departmentId !== dept.id) {
      throw ApiError.forbidden('HOD can only create courses within their assigned department');
    }

    const college = await College.findById(collegeId);
    if (!college || college.status === CollegeStatus.INACTIVE || !college.isActive) {
      throw ApiError.forbidden('Cannot create course for an inactive college');
    }

    const normalizedCode = data.code.trim().toUpperCase();
    const existing = await Course.findOne({
      collegeId: new mongoose.Types.ObjectId(collegeId),
      code: normalizedCode,
    });
    if (existing) {
      throw ApiError.conflict(`Course with code "${normalizedCode}" already exists in this college`);
    }

    const course = await Course.create({
      collegeId: new mongoose.Types.ObjectId(collegeId),
      departmentId: dept._id,
      name: data.name.trim(),
      code: normalizedCode,
      duration: data.duration || 3,
      isActive: true,
    });

    await AuditLog.create({
      collegeId,
      actorUserId: requester.id,
      action: 'COURSE_CREATED',
      entityType: 'Course',
      entityId: course.id,
      newValue: course.toJSON(),
    });

    return course;
  }

  static async listCourses(
    requester: AuthenticatedUser,
    query: { collegeId?: string; departmentId?: string; search?: string; isActive?: string | boolean; page?: number; limit?: number } = {}
  ): Promise<{ items: ICourse[]; page: number; limit: number; total: number; totalPages: number }> {
    const mongoQuery: Record<string, unknown> = {};

    if (requester.role === AppRole.COLLEGE_ADMIN) {
      if (!requester.collegeId) return { items: [], page: 1, limit: 1, total: 0, totalPages: 0 };
      if (query.collegeId && query.collegeId !== requester.collegeId) {
        throw ApiError.forbidden('Cross-college access is strictly prohibited');
      }
      mongoQuery.collegeId = new mongoose.Types.ObjectId(requester.collegeId);
    } else if (requester.role === AppRole.HOD || requester.role === AppRole.FACULTY) {
      if (!requester.collegeId || !requester.departmentId) return { items: [], page: 1, limit: 1, total: 0, totalPages: 0 };
      if (query.collegeId && query.collegeId !== requester.collegeId) {
        throw ApiError.forbidden('Cross-college access is strictly prohibited');
      }
      if (query.departmentId && query.departmentId !== requester.departmentId) {
        throw ApiError.forbidden('Cross-department access is strictly prohibited');
      }
      mongoQuery.collegeId = new mongoose.Types.ObjectId(requester.collegeId);
      mongoQuery.departmentId = new mongoose.Types.ObjectId(requester.departmentId);
    } else if (requester.role === AppRole.STUDENT) {
      if (!requester.collegeId) return { items: [], page: 1, limit: 1, total: 0, totalPages: 0 };
      if (query.collegeId && query.collegeId !== requester.collegeId) {
        throw ApiError.forbidden('Cross-college access is strictly prohibited');
      }
      mongoQuery.collegeId = new mongoose.Types.ObjectId(requester.collegeId);

      const studentProfile = await Student.findOne({ userId: requester.id });
      if (studentProfile) {
        const activeEnrollments = await StudentEnrollment.find({
          studentId: studentProfile._id,
          status: 'active',
        }).select('courseId');
        if (activeEnrollments.length > 0) {
          const courseIds = activeEnrollments.map((e) => e.courseId);
          mongoQuery._id = { $in: courseIds };
        } else if (studentProfile.courseId) {
          mongoQuery._id = studentProfile.courseId;
        } else if (requester.departmentId) {
          mongoQuery.departmentId = new mongoose.Types.ObjectId(requester.departmentId);
        }
      } else if (requester.departmentId) {
        mongoQuery.departmentId = new mongoose.Types.ObjectId(requester.departmentId);
      }
    } else if (query.collegeId) {
      if (!mongoose.Types.ObjectId.isValid(query.collegeId)) throw ApiError.badRequest('Invalid collegeId');
      mongoQuery.collegeId = new mongoose.Types.ObjectId(query.collegeId);
    }

    if (query.departmentId && ![AppRole.HOD, AppRole.FACULTY, AppRole.STUDENT].includes(requester.role)) {
      if (!mongoose.Types.ObjectId.isValid(query.departmentId)) throw ApiError.badRequest('Invalid departmentId');
      mongoQuery.departmentId = new mongoose.Types.ObjectId(query.departmentId);
    }

    if (query.isActive !== undefined && query.isActive !== 'all') {
      mongoQuery.isActive = query.isActive === true || query.isActive === 'true';
    }

    if (query.search && query.search.trim() !== '') {
      const searchRegex = new RegExp(query.search.trim(), 'i');
      mongoQuery.$or = [{ name: searchRegex }, { code: searchRegex }];
    }

    const page = Math.max(1, query.page || 1);
    const limit = Math.min(100, Math.max(1, query.limit || 20));
    const skip = (page - 1) * limit;

    const [items, total] = await Promise.all([
      Course.find(mongoQuery).sort({ name: 1 }).skip(skip).limit(limit),
      Course.countDocuments(mongoQuery),
    ]);

    return { items, page, limit, total, totalPages: Math.ceil(total / limit) };
  }

  static async getCourseById(id: string, requester: AuthenticatedUser): Promise<ICourse> {
    if (!mongoose.Types.ObjectId.isValid(id)) throw ApiError.badRequest('Invalid Course ID');
    const course = await Course.findById(id);
    if (!course) throw ApiError.notFound('Course not found');

    if (requester.role === AppRole.COLLEGE_ADMIN && course.collegeId.toString() !== requester.collegeId) {
      throw ApiError.forbidden('Cross-college access is strictly prohibited');
    }
    if ([AppRole.HOD, AppRole.FACULTY].includes(requester.role) && course.departmentId.toString() !== requester.departmentId) {
      throw ApiError.forbidden('Cross-department access is strictly prohibited');
    }
    if (requester.role === AppRole.STUDENT) {
      if (course.collegeId.toString() !== requester.collegeId) {
        throw ApiError.forbidden('Cross-college access is strictly prohibited');
      }
      const studentProfile = await Student.findOne({ userId: requester.id });
      if (studentProfile) {
        const activeEnrollments = await StudentEnrollment.find({
          studentId: studentProfile._id,
          status: 'active',
        }).select('courseId');
        if (activeEnrollments.length > 0) {
          const isEnrolled = activeEnrollments.some((e) => e.courseId.toString() === course.id);
          if (!isEnrolled) {
            throw ApiError.forbidden('Access denied to course outside active enrollment');
          }
        } else if (studentProfile.courseId && studentProfile.courseId.toString() !== course.id) {
          throw ApiError.forbidden('Access denied to course outside active enrollment');
        } else if (requester.departmentId && course.departmentId.toString() !== requester.departmentId) {
          throw ApiError.forbidden('Cross-department access is strictly prohibited');
        }
      } else if (requester.departmentId && course.departmentId.toString() !== requester.departmentId) {
        throw ApiError.forbidden('Cross-department access is strictly prohibited');
      }
    }

    return course;
  }

  static async updateCourse(
    id: string,
    update: { name?: string; code?: string; duration?: number; isActive?: boolean },
    requester: AuthenticatedUser
  ): Promise<ICourse> {
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD].includes(requester.role)) {
      throw ApiError.forbidden('Unauthorized to update courses');
    }

    const course = await this.getCourseById(id, requester);
    const prev = course.toJSON();

    if (update.name) course.name = update.name.trim();
    if (update.duration) course.duration = update.duration;
    if (update.isActive !== undefined) course.isActive = update.isActive;

    if (update.code) {
      const normalizedCode = update.code.trim().toUpperCase();
      if (normalizedCode !== course.code) {
        const existing = await Course.findOne({
          collegeId: course.collegeId,
          code: normalizedCode,
          _id: { $ne: course._id },
        });
        if (existing) {
          throw ApiError.conflict(`Course code "${normalizedCode}" is already in use`);
        }
        course.code = normalizedCode;
      }
    }

    await course.save();

    await AuditLog.create({
      collegeId: course.collegeId.toString(),
      actorUserId: requester.id,
      action: 'COURSE_UPDATED',
      entityType: 'Course',
      entityId: course.id,
      previousValue: prev,
      newValue: course.toJSON(),
    });

    return course;
  }

  // =========================================================================
  // 2. ACADEMIC YEAR MANAGEMENT
  // =========================================================================

  static async createAcademicYear(
    collegeId: string,
    data: { name: string; startDate: string; endDate: string; isCurrent?: boolean },
    requester: AuthenticatedUser
  ): Promise<IAcademicYear> {
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD].includes(requester.role)) {
      throw ApiError.forbidden('Only administrators and HODs have permission to create academic years');
    }

    if ((requester.role === AppRole.COLLEGE_ADMIN || requester.role === AppRole.HOD) && requester.collegeId !== collegeId) {
      throw ApiError.forbidden('Cross-college access is strictly prohibited');
    }

    const start = new Date(data.startDate);
    const end = new Date(data.endDate);
    if (start >= end) {
      throw ApiError.badRequest('startDate must be before endDate');
    }

    validateAcademicYearOperationalCycle(data.name, start, end);

    const college = await College.findById(collegeId);
    if (!college || college.status === CollegeStatus.INACTIVE || !college.isActive) {
      throw ApiError.forbidden('Cannot create academic year for an inactive college');
    }

    const normalizedName = data.name.trim();
    const existing = await AcademicYear.findOne({
      collegeId: new mongoose.Types.ObjectId(collegeId),
      name: normalizedName,
    });
    if (existing) {
      throw ApiError.conflict(`Academic Year "${normalizedName}" already exists in this college`);
    }

    if (data.isCurrent) {
      await AcademicYear.updateMany(
        { collegeId: new mongoose.Types.ObjectId(collegeId), isCurrent: true },
        { isCurrent: false }
      );
    }

    const academicYear = await AcademicYear.create({
      collegeId: new mongoose.Types.ObjectId(collegeId),
      name: normalizedName,
      startDate: start,
      endDate: end,
      isCurrent: data.isCurrent || false,
      isActive: true,
    });

    await AuditLog.create({
      collegeId,
      actorUserId: requester.id,
      action: 'ACADEMIC_YEAR_CREATED',
      entityType: 'AcademicYear',
      entityId: academicYear.id,
      newValue: academicYear.toJSON(),
    });

    return academicYear;
  }

  static async listAcademicYears(
    requester: AuthenticatedUser,
    query: { collegeId?: string; page?: number; limit?: number } = {}
  ): Promise<{ items: IAcademicYear[]; page: number; limit: number; total: number; totalPages: number }> {
    const mongoQuery: Record<string, unknown> = {};

    if (requester.role === AppRole.COLLEGE_ADMIN || requester.role === AppRole.HOD || requester.role === AppRole.FACULTY) {
      if (!requester.collegeId) return { items: [], page: 1, limit: 1, total: 0, totalPages: 0 };
      if (query.collegeId && query.collegeId !== requester.collegeId) {
        throw ApiError.forbidden('Cross-college access is strictly prohibited');
      }
      mongoQuery.collegeId = new mongoose.Types.ObjectId(requester.collegeId);
    } else if (query.collegeId) {
      if (!mongoose.Types.ObjectId.isValid(query.collegeId)) throw ApiError.badRequest('Invalid collegeId');
      mongoQuery.collegeId = new mongoose.Types.ObjectId(query.collegeId);
    }

    const page = Math.max(1, query.page || 1);
    const limit = Math.min(100, Math.max(1, query.limit || 20));
    const skip = (page - 1) * limit;

    const [items, total] = await Promise.all([
      AcademicYear.find(mongoQuery).sort({ startDate: -1 }).skip(skip).limit(limit),
      AcademicYear.countDocuments(mongoQuery),
    ]);

    return { items, page, limit, total, totalPages: Math.ceil(total / limit) };
  }

  static async getAcademicYearById(id: string, requester: AuthenticatedUser): Promise<IAcademicYear> {
    if (!mongoose.Types.ObjectId.isValid(id)) throw ApiError.badRequest('Invalid Academic Year ID');
    const year = await AcademicYear.findById(id);
    if (!year) throw ApiError.notFound('Academic Year not found');

    if ((requester.role === AppRole.COLLEGE_ADMIN || requester.role === AppRole.HOD) && year.collegeId.toString() !== requester.collegeId) {
      throw ApiError.forbidden('Cross-college access is strictly prohibited');
    }

    return year;
  }

  static async updateAcademicYear(
    id: string,
    update: { name?: string; startDate?: string; endDate?: string; isCurrent?: boolean; isActive?: boolean },
    requester: AuthenticatedUser
  ): Promise<IAcademicYear> {
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD].includes(requester.role)) {
      throw ApiError.forbidden('Unauthorized to update academic years');
    }

    const year = await this.getAcademicYearById(id, requester);
    const prev = year.toJSON();

    if (update.name) year.name = update.name.trim();
    if (update.startDate) year.startDate = new Date(update.startDate);
    if (update.endDate) year.endDate = new Date(update.endDate);
    if (year.startDate >= year.endDate) {
      throw ApiError.badRequest('startDate must be before endDate');
    }

    validateAcademicYearOperationalCycle(year.name, year.startDate, year.endDate);

    if (update.isCurrent) {
      await AcademicYear.updateMany(
        { collegeId: year.collegeId, isCurrent: true, _id: { $ne: year._id } },
        { isCurrent: false }
      );
      year.isCurrent = true;
    } else if (update.isCurrent === false) {
      year.isCurrent = false;
    }

    if (update.isActive !== undefined) year.isActive = update.isActive;

    await year.save();

    await AuditLog.create({
      collegeId: year.collegeId.toString(),
      actorUserId: requester.id,
      action: 'ACADEMIC_YEAR_UPDATED',
      entityType: 'AcademicYear',
      entityId: year.id,
      previousValue: prev,
      newValue: year.toJSON(),
    });

    return year;
  }

  // =========================================================================
  // 3. SEMESTER MANAGEMENT
  // =========================================================================

  static async createSemester(
    collegeId: string,
    data: { courseId: string; academicYearId: string; name: string; number: number; startDate?: string; endDate?: string; isCurrent?: boolean },
    requester: AuthenticatedUser
  ): Promise<ISemester> {
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD].includes(requester.role)) {
      throw ApiError.forbidden('Only administrators and HODs have permission to create semesters');
    }

    if (!mongoose.Types.ObjectId.isValid(data.courseId)) throw ApiError.badRequest('Invalid courseId');
    if (!mongoose.Types.ObjectId.isValid(data.academicYearId)) throw ApiError.badRequest('Invalid academicYearId');

    const [course, academicYear] = await Promise.all([
      Course.findById(data.courseId),
      AcademicYear.findById(data.academicYearId),
    ]);

    if (!course) throw ApiError.notFound('Course not found');
    if (!academicYear) throw ApiError.notFound('Academic Year not found');

    if (course.collegeId.toString() !== collegeId || academicYear.collegeId.toString() !== collegeId) {
      throw ApiError.badRequest('Course and Academic Year must belong to the specified college');
    }

    if (requester.role === AppRole.COLLEGE_ADMIN && requester.collegeId !== collegeId) {
      throw ApiError.forbidden('Cross-college semester creation is strictly prohibited');
    }
    if (requester.role === AppRole.HOD && requester.departmentId !== course.departmentId.toString()) {
      throw ApiError.forbidden('HOD can only create semesters for courses in their own department');
    }

    if (data.startDate && data.endDate) {
      const start = new Date(data.startDate);
      const end = new Date(data.endDate);
      if (start >= end) {
        throw ApiError.badRequest('startDate must be before endDate');
      }
    }

    const existing = await Semester.findOne({
      collegeId: new mongoose.Types.ObjectId(collegeId),
      courseId: course._id,
      academicYearId: academicYear._id,
      number: data.number,
    });
    if (existing) {
      throw ApiError.conflict(`Semester ${data.number} already exists for this course and academic year`);
    }

    const semester = await Semester.create({
      collegeId: new mongoose.Types.ObjectId(collegeId),
      departmentId: course.departmentId,
      courseId: course._id,
      academicYearId: academicYear._id,
      name: data.name.trim(),
      number: data.number,
      startDate: data.startDate ? new Date(data.startDate) : undefined,
      endDate: data.endDate ? new Date(data.endDate) : undefined,
      isCurrent: data.isCurrent || false,
      isActive: true,
    });

    await AuditLog.create({
      collegeId,
      actorUserId: requester.id,
      action: 'SEMESTER_CREATED',
      entityType: 'Semester',
      entityId: semester.id,
      newValue: semester.toJSON(),
    });

    return semester;
  }

  static async listSemesters(
    requester: AuthenticatedUser,
    query: { collegeId?: string; courseId?: string; academicYearId?: string; page?: number; limit?: number } = {}
  ): Promise<{ items: ISemester[]; page: number; limit: number; total: number; totalPages: number }> {
    const mongoQuery: Record<string, unknown> = {};

    if (requester.role === AppRole.COLLEGE_ADMIN) {
      if (!requester.collegeId) return { items: [], page: 1, limit: 1, total: 0, totalPages: 0 };
      mongoQuery.collegeId = new mongoose.Types.ObjectId(requester.collegeId);
    } else if (requester.role === AppRole.HOD || requester.role === AppRole.FACULTY) {
      if (!requester.collegeId || !requester.departmentId) return { items: [], page: 1, limit: 1, total: 0, totalPages: 0 };
      if (query.collegeId && query.collegeId !== requester.collegeId) {
        throw ApiError.forbidden('Cross-college access is strictly prohibited');
      }
      mongoQuery.collegeId = new mongoose.Types.ObjectId(requester.collegeId);
      mongoQuery.departmentId = new mongoose.Types.ObjectId(requester.departmentId);
    } else if (query.collegeId) {
      if (!mongoose.Types.ObjectId.isValid(query.collegeId)) throw ApiError.badRequest('Invalid collegeId');
      mongoQuery.collegeId = new mongoose.Types.ObjectId(query.collegeId);
    }

    if (query.courseId) {
      if (!mongoose.Types.ObjectId.isValid(query.courseId)) throw ApiError.badRequest('Invalid courseId');
      mongoQuery.courseId = new mongoose.Types.ObjectId(query.courseId);
    }
    if (query.academicYearId) {
      if (!mongoose.Types.ObjectId.isValid(query.academicYearId)) throw ApiError.badRequest('Invalid academicYearId');
      mongoQuery.academicYearId = new mongoose.Types.ObjectId(query.academicYearId);
    }

    const page = Math.max(1, query.page || 1);
    const limit = Math.min(100, Math.max(1, query.limit || 20));
    const skip = (page - 1) * limit;

    const [items, total] = await Promise.all([
      Semester.find(mongoQuery).sort({ number: 1 }).skip(skip).limit(limit),
      Semester.countDocuments(mongoQuery),
    ]);

    return { items, page, limit, total, totalPages: Math.ceil(total / limit) };
  }

  static async getSemesterById(id: string, requester: AuthenticatedUser): Promise<ISemester> {
    if (!mongoose.Types.ObjectId.isValid(id)) throw ApiError.badRequest('Invalid Semester ID');
    const semester = await Semester.findById(id);
    if (!semester) throw ApiError.notFound('Semester not found');

    if (requester.role === AppRole.COLLEGE_ADMIN && semester.collegeId.toString() !== requester.collegeId) {
      throw ApiError.forbidden('Cross-college access is strictly prohibited');
    }
    if ([AppRole.HOD, AppRole.FACULTY].includes(requester.role) && semester.departmentId.toString() !== requester.departmentId) {
      throw ApiError.forbidden('Cross-department access is strictly prohibited');
    }

    return semester;
  }

  static async updateSemester(
    id: string,
    update: { name?: string; number?: number; startDate?: string; endDate?: string; isCurrent?: boolean; isActive?: boolean },
    requester: AuthenticatedUser
  ): Promise<ISemester> {
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD].includes(requester.role)) {
      throw ApiError.forbidden('Unauthorized to update semesters');
    }

    const semester = await this.getSemesterById(id, requester);
    const prev = semester.toJSON();

    if (update.name) semester.name = update.name.trim();

    if (update.number && update.number !== semester.number) {
      const duplicate = await Semester.findOne({
        collegeId: semester.collegeId,
        courseId: semester.courseId,
        academicYearId: semester.academicYearId,
        number: update.number,
        _id: { $ne: semester._id },
      });
      if (duplicate) {
        throw ApiError.conflict(`Semester ${update.number} already exists for this course and academic year`);
      }
      semester.number = update.number;
    }

    const finalStart = update.startDate ? new Date(update.startDate) : semester.startDate;
    const finalEnd = update.endDate ? new Date(update.endDate) : semester.endDate;
    if (finalStart && finalEnd && finalStart >= finalEnd) {
      throw ApiError.badRequest('startDate must be before endDate');
    }

    if (update.startDate) semester.startDate = new Date(update.startDate);
    if (update.endDate) semester.endDate = new Date(update.endDate);
    if (update.isCurrent !== undefined) semester.isCurrent = update.isCurrent;
    if (update.isActive !== undefined) semester.isActive = update.isActive;

    await semester.save();

    await AuditLog.create({
      collegeId: semester.collegeId.toString(),
      actorUserId: requester.id,
      action: 'SEMESTER_UPDATED',
      entityType: 'Semester',
      entityId: semester.id,
      previousValue: prev,
      newValue: semester.toJSON(),
    });

    return semester;
  }

  // =========================================================================
  // 4. SECTION MANAGEMENT
  // =========================================================================

  static async createSection(
    collegeId: string,
    data: { courseId: string; academicYearId?: string; semesterId: string; name: string; capacity?: number },
    requester: AuthenticatedUser
  ): Promise<ISection> {
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD].includes(requester.role)) {
      throw ApiError.forbidden('Only administrators and HODs have permission to create sections');
    }

    if (!mongoose.Types.ObjectId.isValid(data.courseId)) throw ApiError.badRequest('Invalid courseId');
    if (!mongoose.Types.ObjectId.isValid(data.semesterId)) throw ApiError.badRequest('Invalid semesterId');

    const [course, semester] = await Promise.all([
      Course.findById(data.courseId),
      Semester.findById(data.semesterId),
    ]);

    if (!course) throw ApiError.notFound('Course not found');
    if (!semester) throw ApiError.notFound('Semester not found');

    const resolvedAcademicYearId = data.academicYearId || semester.academicYearId?.toString();
    if (!resolvedAcademicYearId || !mongoose.Types.ObjectId.isValid(resolvedAcademicYearId)) {
      throw ApiError.badRequest('Invalid academicYearId');
    }

    const academicYear = await AcademicYear.findById(resolvedAcademicYearId);
    if (!academicYear) throw ApiError.notFound('Academic Year not found');

    if (semester.courseId.toString() !== course.id || semester.academicYearId.toString() !== academicYear.id) {
      throw ApiError.badRequest('Semester does not match the provided course or academic year');
    }

    if (course.collegeId.toString() !== collegeId) {
      throw ApiError.badRequest('Academic hierarchy does not belong to the specified college');
    }
    if (academicYear.collegeId.toString() !== collegeId) {
      throw ApiError.badRequest('Academic Year does not belong to the specified college');
    }
    if (semester.collegeId && semester.collegeId.toString() !== collegeId) {
      throw ApiError.badRequest('Semester does not belong to the specified college');
    }

    if (requester.role === AppRole.COLLEGE_ADMIN && requester.collegeId !== collegeId) {
      throw ApiError.forbidden('Cross-college section creation is strictly prohibited');
    }
    if (requester.role === AppRole.HOD) {
      if (requester.collegeId && requester.collegeId !== collegeId) {
        throw ApiError.forbidden('Cross-college section creation is strictly prohibited');
      }
      if (requester.departmentId !== course.departmentId.toString()) {
        throw ApiError.forbidden('HOD can only create sections within their assigned department');
      }
    }

    const normalizedName = data.name.trim().toUpperCase();
    const existing = await Section.findOne({
      collegeId: new mongoose.Types.ObjectId(collegeId),
      departmentId: course.departmentId,
      semesterId: semester._id,
      name: normalizedName,
    });
    if (existing) {
      throw ApiError.conflict(`Section "${normalizedName}" already exists in this semester`);
    }

    const section = await Section.create({
      collegeId: new mongoose.Types.ObjectId(collegeId),
      departmentId: course.departmentId,
      courseId: course._id,
      academicYearId: academicYear._id,
      semesterId: semester._id,
      name: normalizedName,
      capacity: data.capacity || 60,
      isActive: true,
    });

    await AuditLog.create({
      collegeId,
      actorUserId: requester.id,
      action: 'SECTION_CREATED',
      entityType: 'Section',
      entityId: section.id,
      newValue: section.toJSON(),
    });

    return section;
  }

  static async listSections(
    requester: AuthenticatedUser,
    query: { collegeId?: string; semesterId?: string; courseId?: string; academicYearId?: string; page?: number; limit?: number } = {}
  ): Promise<{ items: ISection[]; page: number; limit: number; total: number; totalPages: number }> {
    const mongoQuery: Record<string, unknown> = {};

    if (requester.role === AppRole.COLLEGE_ADMIN) {
      if (!requester.collegeId) return { items: [], page: 1, limit: 1, total: 0, totalPages: 0 };
      mongoQuery.collegeId = new mongoose.Types.ObjectId(requester.collegeId);
    } else if (requester.role === AppRole.HOD || requester.role === AppRole.FACULTY) {
      if (!requester.collegeId || !requester.departmentId) return { items: [], page: 1, limit: 1, total: 0, totalPages: 0 };
      if (query.collegeId && query.collegeId !== requester.collegeId) {
        throw ApiError.forbidden('Cross-college access is strictly prohibited');
      }
      mongoQuery.collegeId = new mongoose.Types.ObjectId(requester.collegeId);
      mongoQuery.departmentId = new mongoose.Types.ObjectId(requester.departmentId);
    } else if (query.collegeId) {
      if (!mongoose.Types.ObjectId.isValid(query.collegeId)) throw ApiError.badRequest('Invalid collegeId');
      mongoQuery.collegeId = new mongoose.Types.ObjectId(query.collegeId);
    }

    if (query.semesterId) {
      if (!mongoose.Types.ObjectId.isValid(query.semesterId)) throw ApiError.badRequest('Invalid semesterId');
      mongoQuery.semesterId = new mongoose.Types.ObjectId(query.semesterId);
    }
    if (query.courseId) {
      if (!mongoose.Types.ObjectId.isValid(query.courseId)) throw ApiError.badRequest('Invalid courseId');
      mongoQuery.courseId = new mongoose.Types.ObjectId(query.courseId);
    }
    if (query.academicYearId) {
      if (!mongoose.Types.ObjectId.isValid(query.academicYearId)) throw ApiError.badRequest('Invalid academicYearId');
      mongoQuery.academicYearId = new mongoose.Types.ObjectId(query.academicYearId);
    }

    const page = Math.max(1, query.page || 1);
    const limit = Math.min(100, Math.max(1, query.limit || 20));
    const skip = (page - 1) * limit;

    const [items, total] = await Promise.all([
      Section.find(mongoQuery).sort({ name: 1 }).skip(skip).limit(limit),
      Section.countDocuments(mongoQuery),
    ]);

    return { items, page, limit, total, totalPages: Math.ceil(total / limit) };
  }

  static async getSectionById(id: string, requester: AuthenticatedUser): Promise<ISection> {
    if (!mongoose.Types.ObjectId.isValid(id)) throw ApiError.badRequest('Invalid Section ID');
    const section = await Section.findById(id);
    if (!section) throw ApiError.notFound('Section not found');

    if (requester.role === AppRole.COLLEGE_ADMIN && section.collegeId.toString() !== requester.collegeId) {
      throw ApiError.forbidden('Cross-college access is strictly prohibited');
    }
    if ([AppRole.HOD, AppRole.FACULTY].includes(requester.role)) {
      if (requester.collegeId && section.collegeId.toString() !== requester.collegeId) {
        throw ApiError.forbidden('Cross-college access is strictly prohibited');
      }
      if (section.departmentId.toString() !== requester.departmentId) {
        throw ApiError.forbidden('Cross-department access is strictly prohibited');
      }
    }

    return section;
  }

  static async updateSection(
    id: string,
    update: { name?: string; capacity?: number; isActive?: boolean },
    requester: AuthenticatedUser
  ): Promise<ISection> {
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD].includes(requester.role)) {
      throw ApiError.forbidden('Unauthorized to update sections');
    }

    const section = await this.getSectionById(id, requester);
    const prev = section.toJSON();

    if (update.capacity !== undefined) {
      if (update.capacity <= 0) {
        throw ApiError.badRequest('Capacity must be at least 1');
      }
      section.capacity = update.capacity;
    }

    if (update.name) {
      const normalizedName = update.name.trim().toUpperCase();
      if (normalizedName !== section.name) {
        const existing = await Section.findOne({
          collegeId: section.collegeId,
          departmentId: section.departmentId,
          semesterId: section.semesterId,
          name: normalizedName,
          _id: { $ne: section._id },
        });
        if (existing) {
          throw ApiError.conflict(`Section "${normalizedName}" already exists in this semester`);
        }
        section.name = normalizedName;
      }
    }

    if (update.isActive !== undefined) section.isActive = update.isActive;

    await section.save();

    await AuditLog.create({
      collegeId: section.collegeId.toString(),
      actorUserId: requester.id,
      action: 'SECTION_UPDATED',
      entityType: 'Section',
      entityId: section.id,
      previousValue: prev,
      newValue: section.toJSON(),
    });

    return section;
  }

  // =========================================================================
  // 5. SUBJECT MANAGEMENT
  // =========================================================================

  static async createSubject(
    collegeId: string,
    data: { courseId: string; semesterId: string; name: string; code: string; credits?: number; type?: string; academicYearId?: string },
    requester: AuthenticatedUser
  ): Promise<ISubject> {
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD].includes(requester.role)) {
      throw ApiError.forbidden('Only administrators and HODs have permission to create subjects');
    }

    if (!mongoose.Types.ObjectId.isValid(data.courseId)) throw ApiError.badRequest('Invalid courseId');
    if (!mongoose.Types.ObjectId.isValid(data.semesterId)) throw ApiError.badRequest('Invalid semesterId');
    if (data.academicYearId && !mongoose.Types.ObjectId.isValid(data.academicYearId)) {
      throw ApiError.badRequest('Invalid academicYearId');
    }

    const [course, semester] = await Promise.all([
      Course.findById(data.courseId),
      Semester.findById(data.semesterId),
    ]);

    if (!course) throw ApiError.notFound('Course not found');
    if (!semester) throw ApiError.notFound('Semester not found');

    if (semester.courseId.toString() !== course.id) {
      throw ApiError.badRequest('Semester does not belong to the specified course');
    }
    if (data.academicYearId && semester.academicYearId && semester.academicYearId.toString() !== data.academicYearId) {
      throw ApiError.badRequest('Semester does not match the provided academic year');
    }
    if (course.collegeId.toString() !== collegeId) {
      throw ApiError.badRequest('Course does not belong to the specified college');
    }
    if (semester.collegeId && semester.collegeId.toString() !== collegeId) {
      throw ApiError.badRequest('Semester does not belong to the specified college');
    }

    if (requester.role === AppRole.COLLEGE_ADMIN && requester.collegeId !== collegeId) {
      throw ApiError.forbidden('Cross-college subject creation is strictly prohibited');
    }
    if (requester.role === AppRole.HOD) {
      if (requester.collegeId && requester.collegeId !== collegeId) {
        throw ApiError.forbidden('Cross-college subject creation is strictly prohibited');
      }
      if (requester.departmentId !== course.departmentId.toString()) {
        throw ApiError.forbidden('HOD can only create subjects within their assigned department');
      }
    }

    const normalizedCode = data.code.trim().toUpperCase();
    const existing = await Subject.findOne({
      collegeId: new mongoose.Types.ObjectId(collegeId),
      departmentId: course.departmentId,
      semesterId: semester._id,
      code: normalizedCode,
    });
    if (existing) {
      throw ApiError.conflict(`Subject with code "${normalizedCode}" already exists in this semester`);
    }

    const subject = await Subject.create({
      collegeId: new mongoose.Types.ObjectId(collegeId),
      departmentId: course.departmentId,
      courseId: course._id,
      semesterId: semester._id,
      name: data.name.trim(),
      code: normalizedCode,
      credits: data.credits !== undefined ? data.credits : 3,
      type: data.type || 'Theory',
      isActive: true,
    });

    await AuditLog.create({
      collegeId,
      actorUserId: requester.id,
      action: 'SUBJECT_CREATED',
      entityType: 'Subject',
      entityId: subject.id,
      newValue: subject.toJSON(),
    });

    return subject;
  }

  static async listSubjects(
    requester: AuthenticatedUser,
    query: { collegeId?: string; semesterId?: string; courseId?: string; academicYearId?: string; page?: number; limit?: number } = {}
  ): Promise<{ items: ISubject[]; page: number; limit: number; total: number; totalPages: number }> {
    const mongoQuery: Record<string, unknown> = {};

    if (requester.role === AppRole.COLLEGE_ADMIN) {
      if (!requester.collegeId) return { items: [], page: 1, limit: 1, total: 0, totalPages: 0 };
      mongoQuery.collegeId = new mongoose.Types.ObjectId(requester.collegeId);
    } else if (requester.role === AppRole.HOD || requester.role === AppRole.FACULTY) {
      if (!requester.collegeId || !requester.departmentId) return { items: [], page: 1, limit: 1, total: 0, totalPages: 0 };
      if (query.collegeId && query.collegeId !== requester.collegeId) {
        throw ApiError.forbidden('Cross-college access is strictly prohibited');
      }
      mongoQuery.collegeId = new mongoose.Types.ObjectId(requester.collegeId);
      mongoQuery.departmentId = new mongoose.Types.ObjectId(requester.departmentId);
    } else if (query.collegeId) {
      if (!mongoose.Types.ObjectId.isValid(query.collegeId)) throw ApiError.badRequest('Invalid collegeId');
      mongoQuery.collegeId = new mongoose.Types.ObjectId(query.collegeId);
    }

    if (query.semesterId) {
      if (!mongoose.Types.ObjectId.isValid(query.semesterId)) throw ApiError.badRequest('Invalid semesterId');
      mongoQuery.semesterId = new mongoose.Types.ObjectId(query.semesterId);
    }
    if (query.courseId) {
      if (!mongoose.Types.ObjectId.isValid(query.courseId)) throw ApiError.badRequest('Invalid courseId');
      mongoQuery.courseId = new mongoose.Types.ObjectId(query.courseId);
    }
    if (query.academicYearId) {
      if (!mongoose.Types.ObjectId.isValid(query.academicYearId)) throw ApiError.badRequest('Invalid academicYearId');
      const sems = await Semester.find({ academicYearId: new mongoose.Types.ObjectId(query.academicYearId) }).select('_id');
      const semIds = sems.map((s) => s._id);
      if (mongoQuery.semesterId) {
        const semStr = mongoQuery.semesterId.toString();
        if (!semIds.some((id) => id.toString() === semStr)) {
          return { items: [], page: 1, limit: query.limit || 20, total: 0, totalPages: 0 };
        }
      } else {
        mongoQuery.semesterId = { $in: semIds };
      }
    }

    const page = Math.max(1, query.page || 1);
    const limit = Math.min(100, Math.max(1, query.limit || 20));
    const skip = (page - 1) * limit;

    const [items, total] = await Promise.all([
      Subject.find(mongoQuery).sort({ code: 1 }).skip(skip).limit(limit),
      Subject.countDocuments(mongoQuery),
    ]);

    return { items, page, limit, total, totalPages: Math.ceil(total / limit) };
  }

  static async getSubjectById(id: string, requester: AuthenticatedUser): Promise<ISubject> {
    if (!mongoose.Types.ObjectId.isValid(id)) throw ApiError.badRequest('Invalid Subject ID');
    const subject = await Subject.findById(id);
    if (!subject) throw ApiError.notFound('Subject not found');

    if (requester.role === AppRole.COLLEGE_ADMIN && subject.collegeId.toString() !== requester.collegeId) {
      throw ApiError.forbidden('Cross-college access is strictly prohibited');
    }
    if ([AppRole.HOD, AppRole.FACULTY].includes(requester.role)) {
      if (requester.collegeId && subject.collegeId.toString() !== requester.collegeId) {
        throw ApiError.forbidden('Cross-college access is strictly prohibited');
      }
      if (subject.departmentId.toString() !== requester.departmentId) {
        throw ApiError.forbidden('Cross-department access is strictly prohibited');
      }
    }

    return subject;
  }

  static async updateSubject(
    id: string,
    update: { name?: string; code?: string; credits?: number; type?: string; isActive?: boolean },
    requester: AuthenticatedUser
  ): Promise<ISubject> {
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD].includes(requester.role)) {
      throw ApiError.forbidden('Unauthorized to update subjects');
    }

    const subject = await this.getSubjectById(id, requester);
    const prev = subject.toJSON();

    if (update.name) subject.name = update.name.trim();
    if (update.credits !== undefined) subject.credits = update.credits;
    if (update.type) subject.type = update.type;
    if (update.isActive !== undefined) subject.isActive = update.isActive;

    if (update.code) {
      const normalizedCode = update.code.trim().toUpperCase();
      if (normalizedCode !== subject.code) {
        const existing = await Subject.findOne({
          collegeId: subject.collegeId,
          departmentId: subject.departmentId,
          semesterId: subject.semesterId,
          code: normalizedCode,
          _id: { $ne: subject._id },
        });
        if (existing) {
          throw ApiError.conflict(`Subject code "${normalizedCode}" already exists in this semester`);
        }
        subject.code = normalizedCode;
      }
    }

    await subject.save();

    await AuditLog.create({
      collegeId: subject.collegeId.toString(),
      actorUserId: requester.id,
      action: 'SUBJECT_UPDATED',
      entityType: 'Subject',
      entityId: subject.id,
      previousValue: prev,
      newValue: subject.toJSON(),
    });

    return subject;
  }

  // =========================================================================
  // 6. STUDENT ENROLLMENT FOUNDATION
  // =========================================================================

  static async enrollStudent(
    collegeId: string,
    data: { studentId: string; sectionId?: string | null; courseId?: string; academicYearId?: string; semesterId?: string; enrollmentDate?: string; cohort?: string; academicStage?: string },
    requester: AuthenticatedUser
  ): Promise<IStudentEnrollment> {
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD].includes(requester.role)) {
      throw ApiError.forbidden('Only administrators and HODs have permission to enroll students');
    }

    if (!mongoose.Types.ObjectId.isValid(data.studentId)) throw ApiError.badRequest('Invalid studentId');

    const effectiveCollegeId = requester.role === AppRole.HOD || requester.role === AppRole.COLLEGE_ADMIN
      ? requester.collegeId || collegeId
      : collegeId;

    const student = await Student.findById(data.studentId);
    if (!student) throw ApiError.notFound('Student not found');

    if (requester.role === AppRole.HOD && requester.departmentId !== student.departmentId.toString()) {
      throw ApiError.forbidden('HOD can only enroll students within their assigned department');
    }

    const config = await InstitutionConfiguration.findOne({ collegeId: effectiveCollegeId });
    const isSectionEnabled = config?.academicStructure?.section ?? true;

    if (isSectionEnabled && (!data.sectionId || !mongoose.Types.ObjectId.isValid(data.sectionId))) {
      throw ApiError.badRequest('Invalid or missing sectionId');
    }

    const section = (data.sectionId && mongoose.Types.ObjectId.isValid(data.sectionId))
      ? await Section.findById(data.sectionId)
      : null;

    if (isSectionEnabled && !section) throw ApiError.notFound('Section not found');

    const courseId = data.courseId || section?.courseId?.toString();
    const semesterId = data.semesterId || section?.semesterId?.toString();
    const academicYearId = data.academicYearId || section?.academicYearId?.toString();

    if (!courseId || !mongoose.Types.ObjectId.isValid(courseId)) throw ApiError.badRequest('Invalid courseId');
    if (!academicYearId || !mongoose.Types.ObjectId.isValid(academicYearId)) throw ApiError.badRequest('Invalid academicYearId');
    if (!semesterId || !mongoose.Types.ObjectId.isValid(semesterId)) throw ApiError.badRequest('Invalid semesterId');

    const [course, academicYear, semester] = await Promise.all([
      Course.findById(courseId),
      AcademicYear.findById(academicYearId),
      Semester.findById(semesterId),
    ]);

    if (!course) throw ApiError.notFound('Course not found');
    if (!academicYear) throw ApiError.notFound('Academic Year not found');
    if (!semester) throw ApiError.notFound('Semester not found');

    // Status safety: Inactive / archived entities must not become valid current enrollment context
    if (!course.isActive || (course as any).status === 'archived' || (course as any).status === 'inactive') {
      throw ApiError.badRequest('Cannot enroll student in an inactive or archived course');
    }
    if (!academicYear.isActive || (academicYear as any).status === 'archived' || (academicYear as any).status === 'inactive') {
      throw ApiError.badRequest('Cannot enroll student in an inactive or archived academic year');
    }
    if (!semester.isActive || (semester as any).status === 'archived' || (semester as any).status === 'inactive') {
      throw ApiError.badRequest('Cannot enroll student in an inactive or archived semester');
    }
    if (section && (!section.isActive || (section as any).status === 'archived' || (section as any).status === 'inactive')) {
      throw ApiError.badRequest('Cannot enroll student in an inactive or archived section');
    }

    // College Isolation
    if (student.collegeId.toString() !== effectiveCollegeId ||
        course.collegeId.toString() !== effectiveCollegeId ||
        (section && section.collegeId.toString() !== effectiveCollegeId) ||
        academicYear.collegeId.toString() !== effectiveCollegeId ||
        semester.collegeId.toString() !== effectiveCollegeId) {
      throw ApiError.badRequest('All entities must belong to the specified college');
    }

    // Role & Scope Authorization
    if (requester.role === AppRole.COLLEGE_ADMIN && requester.collegeId !== effectiveCollegeId) {
      throw ApiError.forbidden('Cross-college enrollment is strictly prohibited');
    }
    if (requester.role === AppRole.HOD) {
      if (requester.departmentId !== student.departmentId.toString() ||
          requester.departmentId !== course.departmentId.toString() ||
          (section && requester.departmentId !== section.departmentId.toString())) {
        throw ApiError.forbidden('HOD can only enroll students within their assigned department');
      }
    }

    // Hierarchy Consistency Checks
    if (student.departmentId.toString() !== course.departmentId.toString() ||
        (section && section.departmentId.toString() !== course.departmentId.toString())) {
      throw ApiError.badRequest('Student, Course, and Section must belong to the same department');
    }
    if (semester.courseId.toString() !== course.id || semester.academicYearId.toString() !== academicYear.id) {
      throw ApiError.badRequest('Semester does not match the course or academic year');
    }
    if (section) {
      if (section.semesterId.toString() !== semester.id || section.courseId.toString() !== course.id) {
        throw ApiError.badRequest('Section does not match the semester or course');
      }
      if (section.academicYearId && section.academicYearId.toString() !== academicYear.id) {
        throw ApiError.badRequest('Section does not match the academic year');
      }
    }

    // Section Capacity Check
    if (section) {
      const currentEnrollmentsCount = await StudentEnrollment.countDocuments({
        sectionId: section._id,
        status: 'active',
      });
      if (currentEnrollmentsCount >= section.capacity) {
        throw ApiError.conflict(`Section "${section.name}" is full (capacity: ${section.capacity})`);
      }
    }

    // Duplicate Concurrent Enrollment Check: Prevent contradictory active enrollments
    const existingActive = await StudentEnrollment.findOne({
      studentId: student._id,
      semesterId: semester._id,
      status: 'active',
    });
    if (existingActive) {
      throw ApiError.conflict('Student is already actively enrolled in this semester and academic year');
    }

    const conflictingDeptActive = await StudentEnrollment.findOne({
      studentId: student._id,
      academicYearId: academicYear._id,
      departmentId: { $ne: course.departmentId },
      status: 'active',
    });
    if (conflictingDeptActive) {
      throw ApiError.conflict('Student has an active enrollment in another department for this academic year. Please transfer the student first.');
    }

    let cohort = (data as any).cohort;
    let academicStage = (data as any).academicStage;
    if (!cohort || !academicStage) {
      const match = academicYear.name.match(/(\d{4})/);
      const ayStartYear = match ? parseInt(match[1], 10) : new Date(academicYear.startDate).getFullYear();
      const duration = course.duration || 3;
      const stageNumber = Math.max(1, Math.ceil(semester.number / 2));
      const entryYear = ayStartYear - (stageNumber - 1);
      const gradYear = entryYear + duration;
      if (!cohort) cohort = `${entryYear}–${gradYear.toString().slice(-2)}`;
      if (!academicStage) academicStage = `${stageNumber}${stageNumber === 1 ? 'st' : stageNumber === 2 ? 'nd' : stageNumber === 3 ? 'rd' : 'th'} Year`;
    }

    const enrollment = await StudentEnrollment.create({
      collegeId: new mongoose.Types.ObjectId(effectiveCollegeId),
      studentId: student._id,
      departmentId: course.departmentId,
      courseId: course._id,
      academicYearId: academicYear._id,
      semesterId: semester._id,
      sectionId: section ? section._id : null,
      cohort,
      academicStage,
      enrollmentDate: data.enrollmentDate ? new Date(data.enrollmentDate) : new Date(),
      status: 'active',
    });

    // Update current enrollment pointers on Student profile (derived cache)
    student.courseId = course._id;
    student.academicYearId = academicYear._id;
    student.semesterId = semester._id;
    if (section) {
      student.sectionId = section._id;
    } else {
      student.sectionId = undefined;
    }
    student.cohort = cohort;
    student.academicStage = academicStage;
    await student.save();

    if (student.userId) {
      await User.findByIdAndUpdate(student.userId, {
        courseId: course._id,
        semesterId: semester._id,
        sectionId: section ? section._id : undefined,
      });
    }

    await AuditLog.create({
      collegeId: effectiveCollegeId,
      actorUserId: requester.id,
      action: 'STUDENT_ENROLLED',
      entityType: 'StudentEnrollment',
      entityId: enrollment.id,
      newValue: enrollment.toJSON(),
    });

    // Emit Realtime Domain Event (Persistence-First)
    realtimeEventBus.publish({
      eventType: AcadexEventType.STUDENT_ENROLLMENT_CREATED,
      aggregateType: 'StudentEnrollment',
      aggregateId: enrollment.id,
      action: 'CREATED',
      collegeId: effectiveCollegeId,
      scope: {
        type: 'user',
        collegeId: effectiveCollegeId,
        userId: student.userId?.toString(),
        departmentId: student.departmentId?.toString(),
      },
      payload: {
        enrollmentId: enrollment.id,
        studentId: student.id,
        sectionId: section?._id?.toString(),
        courseId,
        semesterId,
        status: enrollment.status,
      },
    });

    return enrollment;
  }

  static async listEnrollments(
    requester: AuthenticatedUser,
    query: {
      studentId?: string;
      sectionId?: string;
      semesterId?: string;
      courseId?: string;
      academicYearId?: string;
      departmentId?: string;
      collegeId?: string;
      status?: string;
      page?: number;
      limit?: number;
    } = {}
  ): Promise<{ items: IStudentEnrollment[]; page: number; limit: number; total: number; totalPages: number }> {
    const mongoQuery: Record<string, unknown> = {};

    if (requester.role === AppRole.STUDENT) {
      const studentProfile = await Student.findOne({ userId: requester.id });
      if (!studentProfile) return { items: [], page: 1, limit: 1, total: 0, totalPages: 0 };
      mongoQuery.studentId = studentProfile._id;
    } else if (requester.role === AppRole.COLLEGE_ADMIN) {
      if (!requester.collegeId) return { items: [], page: 1, limit: 1, total: 0, totalPages: 0 };
      mongoQuery.collegeId = new mongoose.Types.ObjectId(requester.collegeId);
    } else if (requester.role === AppRole.HOD || requester.role === AppRole.FACULTY) {
      if (!requester.collegeId || !requester.departmentId) return { items: [], page: 1, limit: 1, total: 0, totalPages: 0 };
      mongoQuery.collegeId = new mongoose.Types.ObjectId(requester.collegeId);
      mongoQuery.departmentId = new mongoose.Types.ObjectId(requester.departmentId);
    } else if (query.collegeId) {
      if (!mongoose.Types.ObjectId.isValid(query.collegeId)) throw ApiError.badRequest('Invalid collegeId');
      mongoQuery.collegeId = new mongoose.Types.ObjectId(query.collegeId);
    }

    if (query.departmentId && requester.role !== AppRole.HOD && requester.role !== AppRole.FACULTY) {
      if (!mongoose.Types.ObjectId.isValid(query.departmentId)) throw ApiError.badRequest('Invalid departmentId');
      mongoQuery.departmentId = new mongoose.Types.ObjectId(query.departmentId);
    }
    if (query.courseId) {
      if (!mongoose.Types.ObjectId.isValid(query.courseId)) throw ApiError.badRequest('Invalid courseId');
      mongoQuery.courseId = new mongoose.Types.ObjectId(query.courseId);
    }
    if (query.academicYearId) {
      if (!mongoose.Types.ObjectId.isValid(query.academicYearId)) throw ApiError.badRequest('Invalid academicYearId');
      mongoQuery.academicYearId = new mongoose.Types.ObjectId(query.academicYearId);
    }
    if (query.studentId && requester.role !== AppRole.STUDENT) {
      if (!mongoose.Types.ObjectId.isValid(query.studentId)) throw ApiError.badRequest('Invalid studentId');
      mongoQuery.studentId = new mongoose.Types.ObjectId(query.studentId);
    }
    if (query.sectionId) {
      if (!mongoose.Types.ObjectId.isValid(query.sectionId)) throw ApiError.badRequest('Invalid sectionId');
      mongoQuery.sectionId = new mongoose.Types.ObjectId(query.sectionId);
    }
    if (query.semesterId) {
      if (!mongoose.Types.ObjectId.isValid(query.semesterId)) throw ApiError.badRequest('Invalid semesterId');
      mongoQuery.semesterId = new mongoose.Types.ObjectId(query.semesterId);
    }
    if (query.status) {
      mongoQuery.status = query.status;
    }

    const page = Math.max(1, query.page || 1);
    const limit = Math.min(100, Math.max(1, query.limit || 50));
    const skip = (page - 1) * limit;

    const [items, total] = await Promise.all([
      StudentEnrollment.find(mongoQuery)
        .populate('studentId', 'name rollNumber admissionNumber email phone status isActive lifecycleState')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
      StudentEnrollment.countDocuments(mongoQuery),
    ]);

    return { items, page, limit, total, totalPages: Math.ceil(total / limit) };
  }

  static async getEnrollmentById(id: string, requester: AuthenticatedUser): Promise<IStudentEnrollment> {
    if (!mongoose.Types.ObjectId.isValid(id)) throw ApiError.badRequest('Invalid Enrollment ID');
    const enrollment = await StudentEnrollment.findById(id).populate(
      'studentId',
      'name rollNumber admissionNumber email phone status isActive lifecycleState'
    );
    if (!enrollment) throw ApiError.notFound('Enrollment not found');

    if (requester.role === AppRole.STUDENT) {
      const studentProfile = await Student.findOne({ userId: requester.id });
      if (!studentProfile || enrollment.studentId.toString() !== studentProfile.id) {
        throw ApiError.forbidden('Students can only view their own enrollment records');
      }
    } else if (requester.role === AppRole.COLLEGE_ADMIN && enrollment.collegeId.toString() !== requester.collegeId) {
      throw ApiError.forbidden('Cross-college access is strictly prohibited');
    } else if ([AppRole.HOD, AppRole.FACULTY].includes(requester.role) && enrollment.departmentId.toString() !== requester.departmentId) {
      throw ApiError.forbidden('Cross-department access is strictly prohibited');
    }

    return enrollment;
  }

  static async updateEnrollment(
    id: string,
    update: { status?: string; sectionId?: string | null; cohort?: string; academicStage?: string },
    requester: AuthenticatedUser
  ): Promise<IStudentEnrollment> {
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD].includes(requester.role)) {
      throw ApiError.forbidden('Unauthorized to update enrollment records');
    }

    const enrollment = await this.getEnrollmentById(id, requester);
    const prev = enrollment.toJSON();

    if (update.status) enrollment.status = update.status;
    if (update.cohort) enrollment.cohort = update.cohort;
    if (update.academicStage) enrollment.academicStage = update.academicStage;
    if (update.sectionId !== undefined) {
      if (update.sectionId === null) {
        enrollment.sectionId = undefined;
      } else {
        if (!mongoose.Types.ObjectId.isValid(update.sectionId)) throw ApiError.badRequest('Invalid sectionId');
        const targetSection = await Section.findById(update.sectionId);
        if (!targetSection || targetSection.semesterId.toString() !== enrollment.semesterId.toString()) {
          throw ApiError.badRequest('Target section must exist and belong to the same semester');
        }
        if (requester.role === AppRole.HOD && targetSection.departmentId.toString() !== requester.departmentId) {
          throw ApiError.forbidden('Target section must belong to your assigned department');
        }
        enrollment.sectionId = targetSection._id;
      }
    }

    await enrollment.save();

    await AuditLog.create({
      collegeId: enrollment.collegeId.toString(),
      actorUserId: requester.id,
      action: 'STUDENT_ENROLLMENT_UPDATED',
      entityType: 'StudentEnrollment',
      entityId: enrollment.id,
      previousValue: prev,
      newValue: enrollment.toJSON(),
    });

    return enrollment;
  }

  static async deleteEnrollment(id: string, requester: AuthenticatedUser): Promise<void> {
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD].includes(requester.role)) {
      throw ApiError.forbidden('Unauthorized to withdraw student enrollment');
    }

    const enrollment = await this.getEnrollmentById(id, requester);
    const prev = enrollment.toJSON();

    // Safe deactivation / withdrawal instead of destructive deletion
    enrollment.status = 'withdrawn';
    await enrollment.save();

    await AuditLog.create({
      collegeId: enrollment.collegeId.toString(),
      actorUserId: requester.id,
      action: 'STUDENT_ENROLLMENT_WITHDRAWN',
      entityType: 'StudentEnrollment',
      entityId: enrollment.id,
      previousValue: prev,
      newValue: enrollment.toJSON(),
    });
  }

  /**
   * Canonical resolver for a student's authoritative current enrollment and academic context.
   */
  static async getStudentCurrentEnrollment(
    studentIdOrUserId: string,
    requester: AuthenticatedUser
  ): Promise<{
    enrollment: IStudentEnrollment | null;
    academicContext: {
      departmentId: string | null;
      departmentName: string | null;
      courseId: string | null;
      courseName: string | null;
      courseCode: string | null;
      academicYearId: string | null;
      academicYearName: string | null;
      semesterId: string | null;
      semesterName: string | null;
      semesterNumber: number | null;
      sectionId: string | null;
      sectionName: string | null;
      cohort: string | null;
      academicStage: string | null;
      formattedContext: string;
      status: string;
      enrollmentDate?: Date | null;
    } | null;
  }> {
    if (!mongoose.Types.ObjectId.isValid(studentIdOrUserId)) {
      throw ApiError.badRequest('Invalid student ID format');
    }

    let student = await Student.findById(studentIdOrUserId);
    if (!student) {
      student = await Student.findOne({ userId: studentIdOrUserId });
    }
    if (!student) {
      throw ApiError.notFound('Student profile not found');
    }

    // Role Scoping
    if (requester.role === AppRole.STUDENT) {
      if (student.userId?.toString() !== requester.id && student.id !== requester.id) {
        throw ApiError.forbidden('Students can only view their own enrollment records');
      }
    } else if (requester.role === AppRole.COLLEGE_ADMIN) {
      if (student.collegeId.toString() !== requester.collegeId) {
        throw ApiError.forbidden('Cross-college access is strictly prohibited');
      }
    } else if (requester.role === AppRole.HOD) {
      if (student.collegeId.toString() !== requester.collegeId) {
        throw ApiError.forbidden('Cross-college access is strictly prohibited');
      }
      if (student.departmentId.toString() !== requester.departmentId) {
        throw ApiError.forbidden('HOD can only view students within their assigned department');
      }
    } else if (requester.role === AppRole.FACULTY) {
      if (student.collegeId.toString() !== requester.collegeId) {
        throw ApiError.forbidden('Cross-college access is strictly prohibited');
      }
      const facultyDoc = await Faculty.findOne({
        $or: [{ userId: requester.id }, { _id: requester.id }],
        collegeId: requester.collegeId,
      });
      if (!facultyDoc) {
        throw ApiError.forbidden('Faculty profile not found');
      }
      const assignments = await FacultyAssignment.find({
        facultyId: facultyDoc._id,
        collegeId: requester.collegeId,
        isActive: true,
      });
      const assignedSectionIds = assignments.map((a) => a.sectionId?.toString()).filter(Boolean);
      const assignedSemesterIds = assignments.map((a) => a.semesterId?.toString()).filter(Boolean);

      const activeEnrollmentCheck = await StudentEnrollment.findOne({
        studentId: student._id,
        status: 'active',
      }).sort({ createdAt: -1 });

      const hasTeachingAccess = activeEnrollmentCheck && (
        (activeEnrollmentCheck.sectionId && assignedSectionIds.includes(activeEnrollmentCheck.sectionId.toString())) ||
        (!activeEnrollmentCheck.sectionId && assignedSemesterIds.includes(activeEnrollmentCheck.semesterId.toString()))
      );

      if (!hasTeachingAccess && student.departmentId.toString() !== requester.departmentId) {
        throw ApiError.forbidden('Faculty can only view students within their authorized teaching contexts');
      }
    }

    const enrollment = await StudentEnrollment.findOne({
      studentId: student._id,
      status: 'active',
    })
      .populate('departmentId', 'name code')
      .populate('courseId', 'name code duration')
      .populate('academicYearId', 'name isCurrent startDate endDate')
      .populate('semesterId', 'name number isCurrent')
      .populate('sectionId', 'name capacity')
      .sort({ createdAt: -1 });

    if (!enrollment) {
      return {
        enrollment: null,
        academicContext: null,
      };
    }

    const dept: any = enrollment.departmentId;
    const course: any = enrollment.courseId;
    const ay: any = enrollment.academicYearId;
    const sem: any = enrollment.semesterId;
    const sec: any = enrollment.sectionId;

    const coursePart = course?.code || course?.name || '';
    const stagePart = enrollment.academicStage || '';
    const semPart = sem?.name || (sem?.number ? `Semester ${sem.number}` : '');
    const cohortPart = enrollment.cohort ? `Cohort ${enrollment.cohort}` : '';
    const ayPart = ay?.name ? `(AY ${ay.name})` : '';
    const secPart = sec?.name ? `Section ${sec.name}` : '';

    const parts = [coursePart, stagePart, semPart, cohortPart, ayPart, secPart].filter(Boolean);
    const formattedContext = parts.join(' • ');

    return {
      enrollment,
      academicContext: {
        departmentId: dept?._id?.toString() || enrollment.departmentId.toString(),
        departmentName: dept?.name || null,
        courseId: course?._id?.toString() || enrollment.courseId.toString(),
        courseName: course?.name || null,
        courseCode: course?.code || null,
        academicYearId: ay?._id?.toString() || enrollment.academicYearId.toString(),
        academicYearName: ay?.name || null,
        semesterId: sem?._id?.toString() || enrollment.semesterId.toString(),
        semesterName: sem?.name || null,
        semesterNumber: sem?.number ?? null,
        sectionId: sec?._id?.toString() || (enrollment.sectionId?.toString() ?? null),
        sectionName: sec?.name || null,
        cohort: enrollment.cohort || null,
        academicStage: enrollment.academicStage || null,
        formattedContext,
        status: enrollment.status,
        enrollmentDate: enrollment.enrollmentDate,
      },
    };
  }

  /**
   * Faculty student roster derived strictly from active FacultyAssignment teaching contexts.
   */
  static async listFacultyStudents(
    requester: AuthenticatedUser,
    query: { sectionId?: string; subjectId?: string; semesterId?: string; page?: number; limit?: number } = {}
  ): Promise<{ items: any[]; total: number; page: number; limit: number; totalPages: number }> {
    if (requester.role !== AppRole.FACULTY && requester.role !== AppRole.HOD) {
      throw ApiError.forbidden('Only teaching faculty and HODs have access to teaching class rosters');
    }

    if (!requester.collegeId) {
      return { items: [], total: 0, page: 1, limit: 50, totalPages: 0 };
    }

    let allowedSectionIds: mongoose.Types.ObjectId[] = [];
    let allowedSemesterIds: mongoose.Types.ObjectId[] = [];

    if (requester.role === AppRole.FACULTY) {
      const facultyDoc = await Faculty.findOne({
        $or: [{ userId: requester.id }, { _id: requester.id }],
        collegeId: requester.collegeId,
      });

      if (!facultyDoc) {
        return { items: [], total: 0, page: 1, limit: 50, totalPages: 0 };
      }

      const assignmentFilter: Record<string, any> = {
        facultyId: facultyDoc._id,
        collegeId: requester.collegeId,
        isActive: true,
      };
      if (query.subjectId && mongoose.Types.ObjectId.isValid(query.subjectId)) {
        assignmentFilter.subjectId = new mongoose.Types.ObjectId(query.subjectId);
      }
      if (query.sectionId && mongoose.Types.ObjectId.isValid(query.sectionId)) {
        assignmentFilter.sectionId = new mongoose.Types.ObjectId(query.sectionId);
      }
      if (query.semesterId && mongoose.Types.ObjectId.isValid(query.semesterId)) {
        assignmentFilter.semesterId = new mongoose.Types.ObjectId(query.semesterId);
      }

      const assignments = await FacultyAssignment.find(assignmentFilter);
      if (assignments.length === 0) {
        return { items: [], total: 0, page: 1, limit: 50, totalPages: 0 };
      }

      allowedSectionIds = assignments
        .map((a) => a.sectionId)
        .filter((id): id is mongoose.Types.ObjectId => Boolean(id));
      allowedSemesterIds = assignments
        .map((a) => a.semesterId)
        .filter((id): id is mongoose.Types.ObjectId => Boolean(id));
    }

    const enrollmentQuery: Record<string, any> = {
      collegeId: new mongoose.Types.ObjectId(requester.collegeId),
      status: 'active',
    };

    if (requester.role === AppRole.FACULTY) {
      const orConditions: any[] = [];
      if (allowedSectionIds.length > 0) {
        orConditions.push({ sectionId: { $in: allowedSectionIds } });
      }
      if (allowedSemesterIds.length > 0) {
        orConditions.push({ semesterId: { $in: allowedSemesterIds }, sectionId: null });
      }
      if (orConditions.length === 0) {
        return { items: [], total: 0, page: 1, limit: 50, totalPages: 0 };
      }
      enrollmentQuery.$or = orConditions;
    } else if (requester.role === AppRole.HOD) {
      if (!requester.departmentId) return { items: [], total: 0, page: 1, limit: 50, totalPages: 0 };
      enrollmentQuery.departmentId = new mongoose.Types.ObjectId(requester.departmentId);
      if (query.sectionId && mongoose.Types.ObjectId.isValid(query.sectionId)) {
        enrollmentQuery.sectionId = new mongoose.Types.ObjectId(query.sectionId);
      }
      if (query.semesterId && mongoose.Types.ObjectId.isValid(query.semesterId)) {
        enrollmentQuery.semesterId = new mongoose.Types.ObjectId(query.semesterId);
      }
    }

    const page = Math.max(1, query.page || 1);
    const limit = Math.min(100, Math.max(1, query.limit || 50));
    const skip = (page - 1) * limit;

    const [enrollments, total] = await Promise.all([
      StudentEnrollment.find(enrollmentQuery)
        .populate('studentId', 'name rollNumber admissionNumber email phone status isActive lifecycleState')
        .populate('courseId', 'name code')
        .populate('semesterId', 'name number')
        .populate('sectionId', 'name')
        .sort({ createdAt: -1 })
        .skip(skip)
        .limit(limit),
      StudentEnrollment.countDocuments(enrollmentQuery),
    ]);

    const items = enrollments.map((e: any) => ({
      enrollmentId: e.id,
      student: e.studentId,
      course: e.courseId,
      semester: e.semesterId,
      section: e.sectionId,
      cohort: e.cohort,
      academicStage: e.academicStage,
      status: e.status,
    }));

    return {
      items,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    };
  }

  // =========================================================================
  // 7. ACADEMIC TREE & HIERARCHY
  // =========================================================================

  static async getAcademicTree(requester: AuthenticatedUser): Promise<Record<string, unknown>> {
    let collegeFilter: Record<string, unknown> = {};

    if (requester.role !== AppRole.SUPER_ADMIN) {
      if (!requester.collegeId) throw ApiError.forbidden('No college scope assigned');
      collegeFilter = { _id: new mongoose.Types.ObjectId(requester.collegeId) };
    }

    const colleges = await College.find(collegeFilter);

    const tree = await Promise.all(
      colleges.map(async (col) => {
        let deptFilter: Record<string, unknown> = { collegeId: col._id, isActive: true };
        if ([AppRole.HOD, AppRole.FACULTY].includes(requester.role) && requester.departmentId) {
          deptFilter._id = new mongoose.Types.ObjectId(requester.departmentId);
        }

        const [depts, academicYears] = await Promise.all([
          Department.find(deptFilter),
          AcademicYear.find({ collegeId: col._id, isActive: true }).sort({ startDate: -1 }),
        ]);

        const deptTrees = await Promise.all(
          depts.map(async (dept) => {
            const courses = await Course.find({ departmentId: dept._id, isActive: true });

            const courseTrees = await Promise.all(
              courses.map(async (course) => {
                const semesters = await Semester.find({ courseId: course._id, isActive: true }).sort({ number: 1 });

                const semesterTrees = await Promise.all(
                  semesters.map(async (sem) => {
                    const [sections, subjects] = await Promise.all([
                      Section.find({ semesterId: sem._id, isActive: true }),
                      Subject.find({ semesterId: sem._id, isActive: true }),
                    ]);

                    return {
                      ...sem.toJSON(),
                      sections: sections.map((s) => s.toJSON()),
                      subjects: subjects.map((sub) => sub.toJSON()),
                    };
                  })
                );

                return {
                  ...course.toJSON(),
                  semesters: semesterTrees,
                };
              })
            );

            return {
              ...dept.toJSON(),
              courses: courseTrees,
            };
          })
        );

        return {
          ...col.toJSON(),
          academicYears: academicYears.map((a) => a.toJSON()),
          departments: deptTrees,
        };
      })
    );

    return { tree };
  }

  // =========================================================================
  // 8. FACULTY ASSIGNMENTS & WORKLOAD (MODULE 5B)
  // =========================================================================

  static async createFacultyAssignment(
    collegeId: string,
    data: {
      facultyId: string;
      subjectId: string;
      sectionId?: string | null;
      courseId?: string;
      semesterId?: string;
      academicYearId?: string;
      departmentId?: string;
      roomId?: string;
      maxStudents?: number;
      assignmentType?: string;
      cohort?: string;
      academicStage?: string;
      status?: 'active' | 'inactive' | 'ended' | 'archived';
    },
    requester: AuthenticatedUser
  ): Promise<IFacultyAssignment> {
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD].includes(requester.role)) {
      throw ApiError.forbidden('Only administrators and HODs have permission to create faculty assignments');
    }

    const effectiveCollegeId = requester.role === AppRole.HOD || requester.role === AppRole.COLLEGE_ADMIN
      ? requester.collegeId || collegeId
      : collegeId;

    if (requester.role === AppRole.COLLEGE_ADMIN && requester.collegeId !== effectiveCollegeId) {
      throw ApiError.forbidden('Cross-college assignment creation is strictly prohibited');
    }

    if (!mongoose.Types.ObjectId.isValid(data.facultyId)) throw ApiError.badRequest('Invalid facultyId format');
    if (!mongoose.Types.ObjectId.isValid(data.subjectId)) throw ApiError.badRequest('Invalid subjectId format');

    const config = await InstitutionConfiguration.findOne({ collegeId: effectiveCollegeId });
    const isSectionEnabled = config?.academicStructure?.section ?? true;

    if (isSectionEnabled && (!data.sectionId || !mongoose.Types.ObjectId.isValid(data.sectionId))) {
      throw ApiError.badRequest('Invalid or missing sectionId format');
    }

    let faculty = await Faculty.findById(data.facultyId);
    if (!faculty) {
      faculty = await Faculty.findOne({ userId: data.facultyId });
    }
    if (!faculty && mongoose.Types.ObjectId.isValid(data.facultyId)) {
      faculty = await Faculty.findOne({
        $or: [{ userId: new mongoose.Types.ObjectId(data.facultyId) }, { _id: new mongoose.Types.ObjectId(data.facultyId) }],
      });
    }

    if (!faculty) throw ApiError.notFound('Faculty record was not found or is no longer available. Please refresh the faculty list and try again.');

    if (faculty.collegeId.toString() !== effectiveCollegeId) {
      throw ApiError.badRequest('Faculty does not belong to the specified college');
    }

    if (!faculty.isActive || faculty.status === 'inactive') {
      throw ApiError.badRequest('Cannot assign an inactive faculty member');
    }
    if (faculty.userId) {
      const userDoc = await User.findById(faculty.userId);
      if (!userDoc || userDoc.accountStatus === AccountStatus.DEACTIVATED) {
        throw ApiError.badRequest('Cannot assign a faculty member whose user account has been deactivated');
      }
    }

    // Role and Department Scoping (HOD)
    if (requester.role === AppRole.HOD) {
      if (requester.departmentId !== faculty.departmentId.toString()) {
        throw ApiError.forbidden('HOD can only assign faculty within their assigned department');
      }
    }

    const [subject, section] = await Promise.all([
      Subject.findById(data.subjectId),
      (data.sectionId && mongoose.Types.ObjectId.isValid(data.sectionId))
        ? Section.findById(data.sectionId)
        : null,
    ]);

    if (!subject) throw ApiError.notFound('Selected subject was not found or is no longer available. Please refresh the subject list.');
    if (isSectionEnabled && !section) throw ApiError.notFound('Selected section was not found or is no longer available. Please refresh the section list.');

    if (subject.collegeId.toString() !== effectiveCollegeId) {
      throw ApiError.badRequest('Subject does not belong to the specified college');
    }
    if (section && section.collegeId.toString() !== effectiveCollegeId) {
      throw ApiError.badRequest('Section does not belong to the specified college');
    }

    if (!subject.isActive) {
      throw ApiError.badRequest('Cannot assign an inactive subject');
    }
    if (section && (!section.isActive || section.status === 'inactive')) {
      throw ApiError.badRequest('Cannot assign to an inactive section');
    }

    if (requester.role === AppRole.HOD) {
      if (requester.departmentId !== subject.departmentId.toString()) {
        throw ApiError.forbidden('HOD can only assign subjects within their assigned department');
      }
      if (section && requester.departmentId !== section.departmentId.toString()) {
        throw ApiError.forbidden('HOD can only assign sections within their assigned department');
      }
    }

    // Department match check
    if (faculty.departmentId.toString() !== subject.departmentId.toString() ||
        (section && section.departmentId.toString() !== subject.departmentId.toString())) {
      throw ApiError.badRequest('Faculty, Subject, and Section must belong to the same department');
    }

    // Academic Year validation
    let ayId = data.academicYearId || section?.academicYearId;
    if (!ayId) {
      const currentAy = await AcademicYear.findOne({ collegeId: effectiveCollegeId, isCurrent: true, isActive: true });
      ayId = currentAy?._id.toString();
    }
    if (!ayId || !mongoose.Types.ObjectId.isValid(ayId)) {
      throw ApiError.badRequest('Valid academicYearId is required for faculty assignment');
    }
    const ayDoc = await AcademicYear.findById(ayId);
    if (!ayDoc || ayDoc.collegeId.toString() !== effectiveCollegeId) {
      throw ApiError.badRequest('Academic Year does not belong to the specified college');
    }
    if (ayDoc.status === 'archived' || !ayDoc.isActive) {
      throw ApiError.badRequest('Cannot assign to an inactive or archived academic year');
    }

    const courseId = section?.courseId || data.courseId || subject.courseId;
    const semesterId = section?.semesterId || data.semesterId || subject.semesterId;

    if (!courseId || !mongoose.Types.ObjectId.isValid(courseId.toString())) {
      throw ApiError.badRequest('Valid courseId is required');
    }
    if (!semesterId || !mongoose.Types.ObjectId.isValid(semesterId.toString())) {
      throw ApiError.badRequest('Valid semesterId is required');
    }

    const [courseDoc, semDoc] = await Promise.all([
      Course.findById(courseId),
      Semester.findById(semesterId),
    ]);

    if (!courseDoc || courseDoc.collegeId.toString() !== effectiveCollegeId) {
      throw ApiError.badRequest('Course does not belong to the specified college');
    }
    if (courseDoc.departmentId.toString() !== faculty.departmentId.toString()) {
      throw ApiError.badRequest('Course must belong to the faculty department');
    }
    if (!semDoc || (semDoc.collegeId && semDoc.collegeId.toString() !== effectiveCollegeId)) {
      throw ApiError.badRequest('Semester does not belong to the specified college');
    }
    if (semDoc.courseId.toString() !== courseDoc._id.toString()) {
      throw ApiError.badRequest('Semester does not belong to the specified course');
    }
    if (semDoc.status === 'archived' || !semDoc.isActive) {
      throw ApiError.badRequest('Cannot assign to an inactive or archived semester');
    }
    if (semDoc.academicYearId && semDoc.academicYearId.toString() !== ayDoc._id.toString()) {
      throw ApiError.badRequest('Semester does not match the provided academic year');
    }

    // Verify Subject belongs to Course & Semester
    if (subject.courseId && subject.courseId.toString() !== courseDoc._id.toString()) {
      throw ApiError.badRequest('Subject does not belong to the specified course');
    }
    if (subject.semesterId && subject.semesterId.toString() !== semDoc._id.toString()) {
      throw ApiError.badRequest('Subject does not belong to the specified semester');
    }

    // Verify Section lineage
    if (section) {
      if (section.courseId.toString() !== courseDoc._id.toString()) {
        throw ApiError.badRequest('Section course does not match selected course');
      }
      if (section.semesterId.toString() !== semDoc._id.toString()) {
        throw ApiError.badRequest('Section semester does not match selected semester');
      }
      if (section.academicYearId && section.academicYearId.toString() !== ayDoc._id.toString()) {
        throw ApiError.badRequest('Section academic year does not match selected academic year');
      }
    }

    // Check duplicate active assignment
    const duplicateQuery: Record<string, unknown> = {
      collegeId: new mongoose.Types.ObjectId(effectiveCollegeId),
      facultyId: faculty._id,
      subjectId: subject._id,
      academicYearId: ayDoc._id,
      semesterId: semDoc._id,
      status: 'active',
      sectionId: section ? section._id : null,
    };
    const existing = await FacultyAssignment.findOne(duplicateQuery);
    if (existing) {
      const secMsg = section ? ` for section "${section.name}"` : '';
      throw ApiError.conflict(
        `Faculty "${faculty.name}" is already assigned to "${subject.name}"${secMsg}`
      );
    }

    let cohort = (data as any).cohort;
    let academicStage = (data as any).academicStage;
    if (!cohort || !academicStage) {
      const match = ayDoc.name.match(/(\d{4})/);
      const ayStartYear = match ? parseInt(match[1], 10) : new Date(ayDoc.startDate).getFullYear();
      const duration = courseDoc.duration || 3;
      const stageNumber = Math.max(1, Math.ceil(semDoc.number / 2));
      const entryYear = ayStartYear - (stageNumber - 1);
      const gradYear = entryYear + duration;
      if (!cohort) cohort = `${entryYear}–${gradYear.toString().slice(-2)}`;
      if (!academicStage) academicStage = `${stageNumber}${stageNumber === 1 ? 'st' : stageNumber === 2 ? 'nd' : stageNumber === 3 ? 'rd' : 'th'} Year`;
    }

    const assignment = await FacultyAssignment.create({
      collegeId: new mongoose.Types.ObjectId(effectiveCollegeId),
      departmentId: faculty.departmentId,
      facultyId: faculty._id,
      facultyName: faculty.name,
      courseId: courseDoc._id,
      semesterId: semDoc._id,
      sectionId: section ? section._id : null,
      subjectId: subject._id,
      academicYearId: ayDoc._id,
      cohort,
      academicStage,
      roomId: data.roomId || null,
      maxStudents: data.maxStudents || (section ? section.capacity : null),
      assignmentType: data.assignmentType || 'lecture',
      assignedBy: requester.id,
      status: 'active',
      isActive: true,
      assignedAt: new Date(),
    });

    // Update Faculty references
    const facultyUpdate: Record<string, unknown> = {
      $addToSet: {
        subjectIds: subject._id,
        ...(section ? { sectionIds: section._id } : {}),
      },
    };
    await Faculty.updateOne(
      { _id: faculty._id },
      facultyUpdate
    );

    await AuditLog.create({
      collegeId: effectiveCollegeId,
      actorUserId: requester.id,
      action: 'FACULTY_ASSIGNMENT_CREATED',
      entityType: 'FacultyAssignment',
      entityId: assignment.id,
      newValue: assignment.toJSON(),
    });

    // Emit Realtime Domain Event (Persistence-First)
    realtimeEventBus.publish({
      eventType: AcadexEventType.FACULTY_ASSIGNMENT_CREATED,
      aggregateType: 'FacultyAssignment',
      aggregateId: assignment.id,
      action: 'CREATED',
      collegeId: effectiveCollegeId,
      scope: {
        type: 'college',
        collegeId: effectiveCollegeId,
        departmentId: assignment.departmentId?.toString(),
      },
      payload: {
        assignmentId: assignment.id,
        facultyId: faculty.id,
        facultyUserId: faculty.userId?.toString(),
        subjectId: subject.id,
        sectionId: section?._id?.toString(),
      },
    });

    return assignment;
  }

  static async updateFacultyAssignment(
    id: string,
    update: {
      facultyId?: string;
      subjectId?: string;
      sectionId?: string | null;
      courseId?: string;
      semesterId?: string;
      academicYearId?: string;
      departmentId?: string;
      roomId?: string;
      maxStudents?: number;
      assignmentType?: string;
      cohort?: string;
      academicStage?: string;
      status?: 'active' | 'inactive' | 'ended' | 'archived';
      isActive?: boolean;
    },
    requester: AuthenticatedUser
  ): Promise<IFacultyAssignment> {
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD].includes(requester.role)) {
      throw ApiError.forbidden('Only administrators and HODs have permission to update faculty assignments');
    }

    const assignment = await this.getFacultyAssignmentById(id, requester);
    const prev = assignment.toJSON();

    if (requester.role === AppRole.HOD && assignment.departmentId.toString() !== requester.departmentId) {
      throw ApiError.forbidden('HOD can only update assignments within their assigned department');
    }

    const effectiveCollegeId = assignment.collegeId.toString();

    // Revalidate entire relationship if any identity/academic context field changes
    const isRelationshipChanged =
      (update.facultyId && update.facultyId !== assignment.facultyId.toString()) ||
      (update.subjectId && update.subjectId !== assignment.subjectId.toString()) ||
      (update.courseId && update.courseId !== assignment.courseId?.toString()) ||
      (update.semesterId && update.semesterId !== assignment.semesterId?.toString()) ||
      (update.academicYearId && update.academicYearId !== assignment.academicYearId?.toString()) ||
      (update.sectionId !== undefined && update.sectionId !== assignment.sectionId?.toString());

    if (isRelationshipChanged) {
      const targetFacultyId = update.facultyId || assignment.facultyId.toString();
      const targetSubjectId = update.subjectId || assignment.subjectId.toString();
      const targetCourseId = update.courseId || assignment.courseId?.toString();
      const targetSemesterId = update.semesterId || assignment.semesterId?.toString();
      const targetAyId = update.academicYearId || assignment.academicYearId?.toString();
      const targetSectionId = update.sectionId !== undefined ? update.sectionId : assignment.sectionId?.toString();

      const faculty = await Faculty.findById(targetFacultyId);
      if (!faculty || faculty.collegeId.toString() !== effectiveCollegeId) {
        throw ApiError.badRequest('Faculty does not belong to the specified college');
      }
      if (!faculty.isActive || faculty.status === 'inactive') {
        throw ApiError.badRequest('Cannot assign an inactive faculty member');
      }
      if (requester.role === AppRole.HOD && requester.departmentId !== faculty.departmentId.toString()) {
        throw ApiError.forbidden('HOD can only assign faculty within their assigned department');
      }

      const subject = await Subject.findById(targetSubjectId);
      if (!subject || subject.collegeId.toString() !== effectiveCollegeId) {
        throw ApiError.badRequest('Subject does not belong to the specified college');
      }
      if (subject.departmentId.toString() !== faculty.departmentId.toString()) {
        throw ApiError.badRequest('Faculty and Subject must belong to the same department');
      }

      const course = await Course.findById(targetCourseId);
      if (!course || course.collegeId.toString() !== effectiveCollegeId) {
        throw ApiError.badRequest('Course does not belong to the specified college');
      }

      const semester = await Semester.findById(targetSemesterId);
      if (!semester || (semester.collegeId && semester.collegeId.toString() !== effectiveCollegeId)) {
        throw ApiError.badRequest('Semester does not belong to the specified college');
      }
      if (semester.courseId.toString() !== course._id.toString()) {
        throw ApiError.badRequest('Semester does not belong to the specified course');
      }

      if (subject.courseId && subject.courseId.toString() !== course._id.toString()) {
        throw ApiError.badRequest('Subject does not belong to the selected course and semester');
      }
      if (subject.semesterId && subject.semesterId.toString() !== semester._id.toString()) {
        throw ApiError.badRequest('Subject does not belong to the selected course and semester');
      }

      const ay = await AcademicYear.findById(targetAyId);
      if (!ay || ay.collegeId.toString() !== effectiveCollegeId) {
        throw ApiError.badRequest('Academic Year does not belong to the specified college');
      }

      let sectionDoc = null;
      if (targetSectionId) {
        sectionDoc = await Section.findById(targetSectionId);
        if (!sectionDoc || sectionDoc.collegeId.toString() !== effectiveCollegeId) {
          throw ApiError.badRequest('Section does not belong to the specified college');
        }
        if (sectionDoc.departmentId.toString() !== faculty.departmentId.toString()) {
          throw ApiError.badRequest('Section must belong to the faculty department');
        }
        if (sectionDoc.semesterId.toString() !== semester._id.toString()) {
          throw ApiError.badRequest('Section semester does not match selected semester');
        }
      }

      // Check duplicate
      const duplicate = await FacultyAssignment.findOne({
        _id: { $ne: assignment._id },
        collegeId: assignment.collegeId,
        facultyId: faculty._id,
        subjectId: subject._id,
        academicYearId: ay._id,
        semesterId: semester._id,
        sectionId: sectionDoc ? sectionDoc._id : null,
        status: 'active',
      });
      if (duplicate) {
        throw ApiError.conflict('An active assignment already exists for this faculty, subject, and context');
      }

      assignment.facultyId = faculty._id;
      assignment.facultyName = faculty.name;
      assignment.departmentId = faculty.departmentId;
      assignment.subjectId = subject._id;
      assignment.courseId = course._id;
      assignment.semesterId = semester._id;
      assignment.academicYearId = ay._id;
      assignment.sectionId = sectionDoc ? sectionDoc._id : null;
    }

    if (update.roomId !== undefined) assignment.roomId = update.roomId;
    if (update.maxStudents !== undefined) assignment.maxStudents = update.maxStudents;
    if (update.assignmentType !== undefined) assignment.assignmentType = update.assignmentType;
    if (update.cohort !== undefined) assignment.cohort = update.cohort;
    if (update.academicStage !== undefined) assignment.academicStage = update.academicStage;

    if (update.status !== undefined) {
      assignment.status = update.status;
      assignment.isActive = update.status === 'active';
      if (update.status !== 'active') {
        assignment.endedAt = new Date();
      } else {
        assignment.endedAt = null;
      }
    } else if (update.isActive !== undefined) {
      assignment.isActive = update.isActive;
      assignment.status = update.isActive ? 'active' : 'inactive';
      if (!update.isActive) {
        assignment.endedAt = new Date();
      } else {
        assignment.endedAt = null;
      }
    }

    await assignment.save();

    // Sync faculty subjectIds / sectionIds caches
    if (assignment.isActive) {
      await Faculty.updateOne(
        { _id: assignment.facultyId },
        {
          $addToSet: {
            subjectIds: assignment.subjectId,
            ...(assignment.sectionId ? { sectionIds: assignment.sectionId } : {}),
          },
        }
      );
    } else {
      const remSub = await FacultyAssignment.countDocuments({
        facultyId: assignment.facultyId,
        subjectId: assignment.subjectId,
        isActive: true,
        _id: { $ne: assignment._id },
      });
      if (remSub === 0) {
        await Faculty.updateOne({ _id: assignment.facultyId }, { $pull: { subjectIds: assignment.subjectId } });
      }
      if (assignment.sectionId) {
        const remSec = await FacultyAssignment.countDocuments({
          facultyId: assignment.facultyId,
          sectionId: assignment.sectionId,
          isActive: true,
          _id: { $ne: assignment._id },
        });
        if (remSec === 0) {
          await Faculty.updateOne({ _id: assignment.facultyId }, { $pull: { sectionIds: assignment.sectionId } });
        }
      }
    }

    await AuditLog.create({
      collegeId: assignment.collegeId.toString(),
      actorUserId: requester.id,
      action: 'FACULTY_ASSIGNMENT_UPDATED',
      entityType: 'FacultyAssignment',
      entityId: assignment.id,
      previousValue: prev,
      newValue: assignment.toJSON(),
    });

    // Emit Realtime Domain Event (Persistence-First)
    realtimeEventBus.publish({
      eventType: AcadexEventType.FACULTY_ASSIGNMENT_UPDATED,
      aggregateType: 'FacultyAssignment',
      aggregateId: assignment.id,
      action: 'UPDATED',
      collegeId: assignment.collegeId.toString(),
      scope: {
        type: 'college',
        collegeId: assignment.collegeId.toString(),
        departmentId: assignment.departmentId?.toString(),
      },
      payload: {
        assignmentId: assignment.id,
        facultyId: assignment.facultyId?.toString(),
        status: assignment.status,
        isActive: assignment.isActive,
      },
    });

    return assignment;
  }

  static async listFacultyAssignments(
    requester: AuthenticatedUser,
    query: {
      collegeId?: string;
      departmentId?: string;
      facultyId?: string;
      courseId?: string;
      semesterId?: string;
      sectionId?: string;
      subjectId?: string;
      academicYearId?: string;
      status?: 'active' | 'inactive' | 'ended' | 'archived';
      isActive?: boolean;
      page?: number;
      limit?: number;
    } = {}
  ): Promise<{ items: IFacultyAssignment[]; page: number; limit: number; total: number; totalPages: number }> {
    const mongoQuery: Record<string, unknown> = {};

    if (requester.role === AppRole.STUDENT) {
      let student = await Student.findOne({ userId: requester.id });
      if (!student && mongoose.Types.ObjectId.isValid(requester.id)) {
        student = await Student.findById(requester.id);
      }
      if (!student) return { items: [], page: 1, limit: 1, total: 0, totalPages: 0 };

      const activeEnrollment = await StudentEnrollment.findOne({
        collegeId: new mongoose.Types.ObjectId(requester.collegeId),
        studentId: student._id,
        status: 'active',
      });

      if (!activeEnrollment) {
        if (student.sectionId) {
          mongoQuery.collegeId = new mongoose.Types.ObjectId(requester.collegeId);
          mongoQuery.sectionId = student.sectionId;
        } else {
          return { items: [], page: 1, limit: 1, total: 0, totalPages: 0 };
        }
      } else {
        mongoQuery.collegeId = new mongoose.Types.ObjectId(requester.collegeId);
        if (activeEnrollment.sectionId) {
          mongoQuery.sectionId = activeEnrollment.sectionId;
        } else {
          mongoQuery.semesterId = activeEnrollment.semesterId;
        }
      }
    } else if (requester.role === AppRole.FACULTY) {
      let facultyProfile = await Faculty.findOne({ userId: requester.id });
      if (!facultyProfile && mongoose.Types.ObjectId.isValid(requester.id)) {
        facultyProfile = await Faculty.findOne({
          $or: [{ userId: new mongoose.Types.ObjectId(requester.id) }, { _id: new mongoose.Types.ObjectId(requester.id) }],
        });
      }
      if (!facultyProfile && requester.email) {
        facultyProfile = await Faculty.findOne({ email: requester.email.toLowerCase() });
      }
      if (!facultyProfile) return { items: [], page: 1, limit: 1, total: 0, totalPages: 0 };
      mongoQuery.collegeId = new mongoose.Types.ObjectId(requester.collegeId);
      mongoQuery.facultyId = {
        $in: [
          facultyProfile._id,
          ...(facultyProfile.userId ? [facultyProfile.userId] : []),
          ...(mongoose.Types.ObjectId.isValid(requester.id) ? [new mongoose.Types.ObjectId(requester.id)] : []),
        ],
      };
    } else if (requester.role === AppRole.HOD) {
      if (!requester.collegeId || !requester.departmentId) return { items: [], page: 1, limit: 1, total: 0, totalPages: 0 };
      mongoQuery.collegeId = new mongoose.Types.ObjectId(requester.collegeId);
      mongoQuery.departmentId = new mongoose.Types.ObjectId(requester.departmentId);
    } else if (requester.role === AppRole.COLLEGE_ADMIN) {
      if (!requester.collegeId) return { items: [], page: 1, limit: 1, total: 0, totalPages: 0 };
      mongoQuery.collegeId = new mongoose.Types.ObjectId(requester.collegeId);
    } else if (query.collegeId) {
      if (!mongoose.Types.ObjectId.isValid(query.collegeId)) throw ApiError.badRequest('Invalid collegeId');
      mongoQuery.collegeId = new mongoose.Types.ObjectId(query.collegeId);
    }

    if (query.departmentId) mongoQuery.departmentId = new mongoose.Types.ObjectId(query.departmentId);
    if (query.facultyId && requester.role !== AppRole.FACULTY) {
      mongoQuery.facultyId = new mongoose.Types.ObjectId(query.facultyId);
    }
    if (query.courseId) mongoQuery.courseId = new mongoose.Types.ObjectId(query.courseId);
    if (query.semesterId) mongoQuery.semesterId = new mongoose.Types.ObjectId(query.semesterId);
    if (query.sectionId && requester.role !== AppRole.STUDENT) {
      mongoQuery.sectionId = new mongoose.Types.ObjectId(query.sectionId);
    }
    if (query.subjectId) mongoQuery.subjectId = new mongoose.Types.ObjectId(query.subjectId);
    if (query.academicYearId) {
      mongoQuery.academicYearId = new mongoose.Types.ObjectId(query.academicYearId);
    }
    if (query.status) {
      mongoQuery.status = query.status;
    } else if (query.isActive !== undefined) {
      mongoQuery.isActive = query.isActive;
    } else if (requester.role === AppRole.FACULTY) {
      mongoQuery.status = 'active';
    }

    const page = Math.max(1, query.page || 1);
    const limit = Math.min(100, Math.max(1, query.limit || 50));
    const skip = (page - 1) * limit;

    const [items, total] = await Promise.all([
      FacultyAssignment.find(mongoQuery).sort({ createdAt: -1 }).skip(skip).limit(limit),
      FacultyAssignment.countDocuments(mongoQuery),
    ]);

    for (const item of items) {
      if (!item.cohort || !item.academicStage) {
        if (item.academicYearId && item.courseId && item.semesterId) {
          const [ay, crs, sem] = await Promise.all([
            AcademicYear.findById(item.academicYearId),
            Course.findById(item.courseId),
            Semester.findById(item.semesterId),
          ]);
          if (ay && crs && sem) {
            const match = ay.name.match(/(\d{4})/);
            const ayStart = match ? parseInt(match[1], 10) : new Date(ay.startDate).getFullYear();
            const stage = Math.max(1, Math.ceil(sem.number / 2));
            const entry = ayStart - (stage - 1);
            const grad = entry + (crs.duration || 3);
            item.cohort = `${entry}–${grad.toString().slice(-2)}`;
            item.academicStage = `${stage}${stage === 1 ? 'st' : stage === 2 ? 'nd' : stage === 3 ? 'rd' : 'th'} Year`;
          }
        }
      }
    }

    return { items, page, limit, total, totalPages: Math.ceil(total / limit) };
  }

  static async getFacultyAssignmentById(id: string, requester: AuthenticatedUser): Promise<IFacultyAssignment> {
    if (!mongoose.Types.ObjectId.isValid(id)) throw ApiError.badRequest('Invalid FacultyAssignment ID');
    const assignment = await FacultyAssignment.findById(id);
    if (!assignment) throw ApiError.notFound('Faculty Assignment not found');

    if (requester.role === AppRole.COLLEGE_ADMIN && assignment.collegeId.toString() !== requester.collegeId) {
      throw ApiError.forbidden('Cross-college access is strictly prohibited');
    }
    if (requester.role === AppRole.HOD && assignment.departmentId.toString() !== requester.departmentId) {
      throw ApiError.forbidden('Cross-department access is strictly prohibited');
    }
    if (requester.role === AppRole.FACULTY) {
      const faculty = await Faculty.findOne({ userId: requester.id });
      if (!faculty || assignment.facultyId.toString() !== faculty.id) {
        throw ApiError.forbidden('Faculty can only access their own assignments');
      }
    }

    return assignment;
  }

  static async deleteFacultyAssignment(
    id: string,
    requester: AuthenticatedUser
  ): Promise<{ action: 'archived' | 'deleted'; message: string }> {
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD].includes(requester.role)) {
      throw ApiError.forbidden('Only administrators and HODs have permission to remove faculty assignments');
    }

    const assignment = await this.getFacultyAssignmentById(id, requester);
    const prev = assignment.toJSON();

    // Check if historical attendance sessions or published timetables reference this assignment
    const [hasAttendance, hasPublishedTimetable] = await Promise.all([
      AttendanceSession.exists({ facultyAssignmentId: assignment._id }),
      Timetable.exists({ 'entries.facultyAssignmentId': assignment._id, status: TimetableStatus.PUBLISHED }),
    ]);

    let action: 'archived' | 'deleted';
    let message: string;

    if (hasAttendance || hasPublishedTimetable) {
      // Safe deactivation / archive: preserve historical attendance and audit record
      assignment.status = 'archived';
      assignment.isActive = false;
      assignment.endedAt = new Date();
      await assignment.save();
      action = 'archived';
      message = 'Teaching assignment archived to preserve historical records';
    } else {
      await FacultyAssignment.findByIdAndDelete(id);
      action = 'deleted';
      message = 'Teaching assignment deleted successfully';
    }

    // Pull assignment from draft timetables so future unpublished authoring does not reference it
    await Timetable.updateMany(
      { collegeId: assignment.collegeId, status: TimetableStatus.DRAFT },
      { $pull: { entries: { facultyAssignmentId: assignment._id } } }
    );

    // Check if faculty still has other ACTIVE assignments for this subject/section
    const remainingForFacultySubject = await FacultyAssignment.countDocuments({
      facultyId: assignment.facultyId,
      subjectId: assignment.subjectId,
      isActive: true,
      _id: { $ne: assignment._id },
    });
    if (remainingForFacultySubject === 0) {
      await Faculty.updateOne({ _id: assignment.facultyId }, { $pull: { subjectIds: assignment.subjectId } });
    }

    if (assignment.sectionId) {
      const remainingForFacultySection = await FacultyAssignment.countDocuments({
        facultyId: assignment.facultyId,
        sectionId: assignment.sectionId,
        isActive: true,
        _id: { $ne: assignment._id },
      });
      if (remainingForFacultySection === 0) {
        await Faculty.updateOne({ _id: assignment.facultyId }, { $pull: { sectionIds: assignment.sectionId } });
      }
    }

    await AuditLog.create({
      collegeId: assignment.collegeId.toString(),
      actorUserId: requester.id,
      action: hasAttendance || hasPublishedTimetable ? 'FACULTY_ASSIGNMENT_DEACTIVATED' : 'FACULTY_ASSIGNMENT_DELETED',
      entityType: 'FacultyAssignment',
      entityId: assignment.id,
      previousValue: prev,
      newValue: hasAttendance || hasPublishedTimetable ? assignment.toJSON() : undefined,
    });

    // Emit Realtime Domain Event (Persistence-First)
    realtimeEventBus.publish({
      eventType: AcadexEventType.FACULTY_ASSIGNMENT_ENDED,
      aggregateType: 'FacultyAssignment',
      aggregateId: assignment.id,
      action: 'CLOSED',
      collegeId: assignment.collegeId.toString(),
      scope: {
        type: 'college',
        collegeId: assignment.collegeId.toString(),
        departmentId: assignment.departmentId?.toString(),
      },
      payload: {
        assignmentId: assignment.id,
        facultyId: assignment.facultyId?.toString(),
      },
    });

    return { action, message };
  }

  static async getFacultyWorkload(
    requester: AuthenticatedUser,
    departmentId?: string
  ): Promise<any[]> {
    const mongoQuery: Record<string, unknown> = {};

    if (requester.role === AppRole.FACULTY) {
      const faculty = await Faculty.findOne({ userId: requester.id });
      if (!faculty) return [];
      mongoQuery._id = faculty._id;
    } else if (requester.role === AppRole.HOD) {
      if (!requester.collegeId || !requester.departmentId) return [];
      mongoQuery.collegeId = new mongoose.Types.ObjectId(requester.collegeId);
      mongoQuery.departmentId = new mongoose.Types.ObjectId(requester.departmentId);
    } else if (requester.role === AppRole.COLLEGE_ADMIN) {
      if (!requester.collegeId) return [];
      mongoQuery.collegeId = new mongoose.Types.ObjectId(requester.collegeId);
      if (departmentId) mongoQuery.departmentId = new mongoose.Types.ObjectId(departmentId);
    } else if (departmentId) {
      mongoQuery.departmentId = new mongoose.Types.ObjectId(departmentId);
    }

    const facultyList = await Faculty.find(mongoQuery).sort({ name: 1 });

    const workloads = await Promise.all(
      facultyList.map(async (fac) => {
        const assignments = await FacultyAssignment.find({ facultyId: fac._id, isActive: true });
        const distinctSubjects = new Set(assignments.map((a) => a.subjectId.toString())).size;
        const distinctSections = new Set(assignments.map((a) => a.sectionId?.toString()).filter(Boolean)).size;

        return {
          facultyId: fac.id,
          facultyName: fac.name,
          employeeId: fac.employeeId || fac.instituteId,
          departmentId: fac.departmentId?.toString(),
          assignedSubjectCount: distinctSubjects,
          assignedSectionCount: distinctSections,
          subjectsAssigned: distinctSubjects,
          sectionsAssigned: distinctSections,
          weeklyClasses: assignments.length * 4,
          hasAttendanceResponsibility: assignments.length > 0,
          totalAssignments: assignments.length,
          assignments: assignments.map((a) => a.toJSON()),
        };
      })
    );

    return workloads;
  }

  // =========================================================================
  // AUTHORITATIVE CURRENT ACADEMIC CONTEXT & PROGRESSION ARCHITECTURE (PROMPT 24)
  // =========================================================================

  static async getCurrentAcademicContext(
    requester: AuthenticatedUser,
    options: { departmentId?: string; courseId?: string } = {}
  ): Promise<{
    collegeId: string;
    academicYear: IAcademicYear | null;
    isCurrentAuthoritative: boolean;
    activeCohorts: any[];
    totalActiveCohorts: number;
    departmentScope?: string | null;
  }> {
    const collegeId = requester.role === AppRole.SUPER_ADMIN
      ? (requester.collegeId && requester.collegeId !== 'global'
          ? requester.collegeId
          : options.departmentId
          ? (await Department.findById(options.departmentId))?.collegeId.toString()
          : null)
      : requester.collegeId;

    if (!collegeId) {
      return {
        collegeId: '',
        academicYear: null,
        isCurrentAuthoritative: false,
        activeCohorts: [],
        totalActiveCohorts: 0,
      };
    }

    let departmentId = options.departmentId;
    if (requester.role === AppRole.HOD) {
      departmentId = requester.departmentId || undefined;
    } else if (requester.role === AppRole.FACULTY || requester.role === AppRole.STUDENT) {
      departmentId = requester.departmentId || undefined;
    }

    // Find authoritative current academic year
    let academicYear = await AcademicYear.findOne({
      collegeId: new mongoose.Types.ObjectId(collegeId),
      isCurrent: true,
      isActive: true,
    });

    let isCurrentAuthoritative = true;

    if (!academicYear) {
      academicYear = await AcademicYear.findOne({
        collegeId: new mongoose.Types.ObjectId(collegeId),
        status: AcademicYearStatus.ACTIVE,
        isActive: true,
      }).sort({ startDate: -1 });
      isCurrentAuthoritative = false;
    }

    if (!academicYear) {
      academicYear = await AcademicYear.findOne({
        collegeId: new mongoose.Types.ObjectId(collegeId),
        isActive: true,
      }).sort({ startDate: -1 });
      isCurrentAuthoritative = false;
    }

    if (!academicYear) {
      return {
        collegeId,
        academicYear: null,
        isCurrentAuthoritative: false,
        activeCohorts: [],
        totalActiveCohorts: 0,
        departmentScope: departmentId || null,
      };
    }

    // Determine start year
    const match = academicYear.name.match(/(\d{4})/);
    const ayStartYear = match ? parseInt(match[1], 10) : new Date(academicYear.startDate).getFullYear();

    // Query courses for this institution/department
    const courseQuery: Record<string, unknown> = {
      collegeId: new mongoose.Types.ObjectId(collegeId),
      isActive: true,
    };
    if (departmentId && mongoose.Types.ObjectId.isValid(departmentId)) {
      courseQuery.departmentId = new mongoose.Types.ObjectId(departmentId);
    }
    if (options.courseId && mongoose.Types.ObjectId.isValid(options.courseId)) {
      courseQuery._id = new mongoose.Types.ObjectId(options.courseId);
    }

    const courses = await Course.find(courseQuery).sort({ name: 1 });
    const activeCohorts: any[] = [];

    for (const course of courses) {
      const duration = course.duration || 3;
      const progressionType = course.progressionType || 'YEAR_SEMESTER';

      // Find semesters for this course
      const semesters = await Semester.find({
        collegeId: new mongoose.Types.ObjectId(collegeId),
        courseId: course._id,
        isActive: true,
      }).sort({ number: 1 });

      const semesterIds = semesters.map((s) => s._id);
      const sections = await Section.find({
        collegeId: new mongoose.Types.ObjectId(collegeId),
        courseId: course._id,
        semesterId: { $in: semesterIds },
        isActive: true,
      }).sort({ name: 1 });

      for (let stage = 1; stage <= duration; stage++) {
        const entryYear = ayStartYear - (stage - 1);
        const gradYear = entryYear + duration;
        const cohort = `${entryYear}–${gradYear.toString().length === 4 ? gradYear.toString().slice(-2) : gradYear}`;
        const stageName = `${stage}${stage === 1 ? 'st' : stage === 2 ? 'nd' : stage === 3 ? 'rd' : 'th'} Year`;

        // Match periods (semesters/terms) based on progression structure
        let matchedSemesters: any[] = [];
        if (progressionType === 'COMBINED_FIRST_YEAR') {
          if (stage === 1) {
            matchedSemesters = semesters.filter(
              (s) => s.number === 1 || s.name.toLowerCase().includes('combined') || s.name.toLowerCase().includes('first year')
            );
          } else {
            const oddNum = stage * 2 - 1;
            const evenNum = stage * 2;
            matchedSemesters = semesters.filter((s) => s.number === oddNum || s.number === evenNum);
          }
        } else if (progressionType === 'YEAR_ONLY') {
          matchedSemesters = semesters.filter((s) => s.number === stage);
        } else if (progressionType === 'YEAR_TERM') {
          const t1 = (stage - 1) * 3 + 1;
          const t2 = (stage - 1) * 3 + 2;
          const t3 = (stage - 1) * 3 + 3;
          matchedSemesters = semesters.filter((s) => [t1, t2, t3].includes(s.number));
        } else {
          // Standard YEAR_SEMESTER
          const oddNum = stage * 2 - 1;
          const evenNum = stage * 2;
          matchedSemesters = semesters.filter((s) => s.number === oddNum || s.number === evenNum);
        }

        const periods = matchedSemesters.map((sem) => {
          const semSections = sections
            .filter((sec) => sec.semesterId.toString() === sem._id.toString())
            .map((sec) => ({
              sectionId: sec.id,
              name: sec.name,
              capacity: sec.capacity,
            }));

          return {
            semesterId: sem.id,
            name: sem.name,
            number: sem.number,
            isCurrent: sem.isCurrent,
            status: sem.status,
            sections: semSections,
          };
        });

        activeCohorts.push({
          cohort,
          courseId: course.id,
          courseName: course.name,
          courseCode: course.code,
          departmentId: course.departmentId.toString(),
          academicStage: stageName,
          stageNumber: stage,
          entryYear,
          expectedGraduationYear: gradYear,
          progressionType,
          periods,
        });
      }
    }

    return {
      collegeId,
      academicYear,
      isCurrentAuthoritative,
      activeCohorts,
      totalActiveCohorts: activeCohorts.length,
      departmentScope: departmentId || null,
    };
  }

  static async getAcademicHistory(
    requester: AuthenticatedUser,
    options: { departmentId?: string; courseId?: string } = {}
  ): Promise<any[]> {
    const collegeId = requester.role === AppRole.SUPER_ADMIN
      ? (requester.collegeId && requester.collegeId !== 'global'
          ? requester.collegeId
          : options.departmentId
          ? (await Department.findById(options.departmentId))?.collegeId.toString()
          : null)
      : requester.collegeId;

    if (!collegeId) return [];

    const historicalYears = await AcademicYear.find({
      collegeId: new mongoose.Types.ObjectId(collegeId),
      isCurrent: false,
    }).sort({ startDate: -1 });

    return historicalYears.map((ay) => ({
      academicYear: ay.toJSON(),
      isCurrent: false,
      name: ay.name,
      startDate: ay.startDate,
      endDate: ay.endDate,
      status: ay.status,
    }));
  }
}
