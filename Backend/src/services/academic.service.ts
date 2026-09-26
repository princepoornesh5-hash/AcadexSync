import mongoose from 'mongoose';
import { User } from '../models/user.model';
import { Course, ICourse } from '../models/course.model';
import { AcademicYear, IAcademicYear } from '../models/academicYear.model';
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
import { CollegeStatus, DepartmentStatus, AccountStatus, TimetableStatus } from '../constants/status';
import { ApiError } from '../utils/apiError';
import { AuthenticatedUser } from '../types/auth.types';

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
      throw ApiError.notFound(`Department with ID "${data.departmentId}" not found`);
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
    data: { studentId: string; sectionId: string; courseId?: string; academicYearId?: string; semesterId?: string; enrollmentDate?: string },
    requester: AuthenticatedUser
  ): Promise<IStudentEnrollment> {
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD, AppRole.FACULTY].includes(requester.role)) {
      throw ApiError.forbidden('Only staff and administrators have permission to enroll students');
    }

    if (!mongoose.Types.ObjectId.isValid(data.studentId)) throw ApiError.badRequest('Invalid studentId');
    if (!mongoose.Types.ObjectId.isValid(data.sectionId)) throw ApiError.badRequest('Invalid sectionId');

    const effectiveCollegeId = requester.role === AppRole.HOD || requester.role === AppRole.COLLEGE_ADMIN
      ? requester.collegeId || collegeId
      : collegeId;

    const [student, section] = await Promise.all([
      Student.findById(data.studentId),
      Section.findById(data.sectionId),
    ]);

    if (!student) throw ApiError.notFound('Student not found');
    if (!section) throw ApiError.notFound('Section not found');

    const courseId = data.courseId || section.courseId?.toString();
    const semesterId = data.semesterId || section.semesterId?.toString();
    const academicYearId = data.academicYearId || section.academicYearId?.toString();

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

    // College Isolation
    if (student.collegeId.toString() !== effectiveCollegeId ||
        course.collegeId.toString() !== effectiveCollegeId ||
        section.collegeId.toString() !== effectiveCollegeId ||
        academicYear.collegeId.toString() !== effectiveCollegeId ||
        semester.collegeId.toString() !== effectiveCollegeId) {
      throw ApiError.badRequest('All entities must belong to the specified college');
    }

    // Hierarchy Consistency Checks
    if (student.departmentId.toString() !== course.departmentId.toString() ||
        section.departmentId.toString() !== course.departmentId.toString()) {
      throw ApiError.badRequest('Student, Course, and Section must belong to the same department');
    }
    if (semester.courseId.toString() !== course.id || semester.academicYearId.toString() !== academicYear.id) {
      throw ApiError.badRequest('Semester does not match the course or academic year');
    }
    if (section.semesterId.toString() !== semester.id || section.courseId.toString() !== course.id) {
      throw ApiError.badRequest('Section does not match the semester or course');
    }
    if (section.academicYearId && section.academicYearId.toString() !== academicYear.id) {
      throw ApiError.badRequest('Section does not match the academic year');
    }

    // Role Scoping
    if (requester.role === AppRole.COLLEGE_ADMIN && requester.collegeId !== effectiveCollegeId) {
      throw ApiError.forbidden('Cross-college enrollment is strictly prohibited');
    }
    if (requester.role === AppRole.HOD) {
      if (requester.departmentId !== course.departmentId.toString() ||
          requester.departmentId !== student.departmentId.toString() ||
          requester.departmentId !== section.departmentId.toString()) {
        throw ApiError.forbidden('HOD can only enroll students within their assigned department');
      }
    } else if (requester.role === AppRole.FACULTY && requester.departmentId !== course.departmentId.toString()) {
      throw ApiError.forbidden('Staff can only enroll students within their assigned department');
    }

    // Section Capacity Check
    const currentEnrollmentsCount = await StudentEnrollment.countDocuments({
      sectionId: section._id,
      status: 'active',
    });
    if (currentEnrollmentsCount >= section.capacity) {
      throw ApiError.conflict(`Section "${section.name}" is full (capacity: ${section.capacity})`);
    }

    // Duplicate Concurrent Enrollment Check
    const existingActive = await StudentEnrollment.findOne({
      studentId: student._id,
      academicYearId: academicYear._id,
      semesterId: semester._id,
      status: 'active',
    });
    if (existingActive) {
      throw ApiError.conflict('Student is already actively enrolled in this semester and academic year');
    }

    const enrollment = await StudentEnrollment.create({
      collegeId: new mongoose.Types.ObjectId(effectiveCollegeId),
      studentId: student._id,
      departmentId: course.departmentId,
      courseId: course._id,
      academicYearId: academicYear._id,
      semesterId: semester._id,
      sectionId: section._id,
      enrollmentDate: data.enrollmentDate ? new Date(data.enrollmentDate) : new Date(),
      status: 'active',
    });

    // Update current enrollment pointers on Student profile
    student.courseId = course._id;
    student.academicYearId = academicYear._id;
    student.semesterId = semester._id;
    student.sectionId = section._id;
    await student.save();

    await AuditLog.create({
      collegeId: effectiveCollegeId,
      actorUserId: requester.id,
      action: 'STUDENT_ENROLLED',
      entityType: 'StudentEnrollment',
      entityId: enrollment.id,
      newValue: enrollment.toJSON(),
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
    update: { status?: string; sectionId?: string },
    requester: AuthenticatedUser
  ): Promise<IStudentEnrollment> {
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD].includes(requester.role)) {
      throw ApiError.forbidden('Unauthorized to update enrollment records');
    }

    const enrollment = await this.getEnrollmentById(id, requester);
    const prev = enrollment.toJSON();

    if (update.status) enrollment.status = update.status;
    if (update.sectionId) {
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
      sectionId: string;
      courseId?: string;
      semesterId?: string;
      academicYearId?: string;
      departmentId?: string;
      roomId?: string;
      maxStudents?: number;
      assignmentType?: string;
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
    if (!mongoose.Types.ObjectId.isValid(data.sectionId)) throw ApiError.badRequest('Invalid sectionId format');

    const [faculty, subject, section] = await Promise.all([
      Faculty.findById(data.facultyId),
      Subject.findById(data.subjectId),
      Section.findById(data.sectionId),
    ]);

    if (!faculty) throw ApiError.notFound(`Faculty with ID "${data.facultyId}" not found`);
    if (!subject) throw ApiError.notFound(`Subject with ID "${data.subjectId}" not found`);
    if (!section) throw ApiError.notFound(`Section with ID "${data.sectionId}" not found`);

    if (
      faculty.collegeId.toString() !== effectiveCollegeId ||
      subject.collegeId.toString() !== effectiveCollegeId ||
      section.collegeId.toString() !== effectiveCollegeId
    ) {
      throw ApiError.badRequest('Faculty, Subject, and Section must all belong to the specified college');
    }

    if (!faculty.isActive || faculty.status === 'inactive') {
      throw ApiError.forbidden('Cannot assign an inactive faculty member');
    }
    if (faculty.userId) {
      const userDoc = await User.findById(faculty.userId);
      if (!userDoc || userDoc.accountStatus !== AccountStatus.ACTIVE) {
        throw ApiError.forbidden('Cannot assign a faculty member with an inactive user account');
      }
    }
    if (!subject.isActive) {
      throw ApiError.forbidden('Cannot assign an inactive subject');
    }
    if (!section.isActive || section.status === 'inactive') {
      throw ApiError.forbidden('Cannot assign to an inactive section');
    }

    // Role and Department Scoping
    if (requester.role === AppRole.HOD) {
      if (requester.departmentId !== faculty.departmentId.toString()) {
        throw ApiError.forbidden('HOD can only assign faculty within their assigned department');
      }
      if (requester.departmentId !== subject.departmentId.toString()) {
        throw ApiError.forbidden('HOD can only assign subjects within their assigned department');
      }
      if (requester.departmentId !== section.departmentId.toString()) {
        throw ApiError.forbidden('HOD can only assign sections within their assigned department');
      }
    }

    // Department match check
    if (faculty.departmentId.toString() !== subject.departmentId.toString() ||
        section.departmentId.toString() !== subject.departmentId.toString()) {
      throw ApiError.badRequest('Faculty, Subject, and Section must belong to the same department');
    }

    // Verify academic lineage
    if (subject.semesterId?.toString() !== section.semesterId?.toString()) {
      throw ApiError.badRequest('Subject semester does not match Section semester');
    }
    if (subject.courseId && section.courseId && subject.courseId.toString() !== section.courseId.toString()) {
      throw ApiError.badRequest('Subject course does not match Section course');
    }
    if (data.courseId && section.courseId && data.courseId !== section.courseId.toString()) {
      throw ApiError.badRequest('Course does not match section course');
    }
    if (data.semesterId && section.semesterId && data.semesterId !== section.semesterId.toString()) {
      throw ApiError.badRequest('Semester does not match section semester');
    }
    if (data.academicYearId && section.academicYearId && data.academicYearId !== section.academicYearId.toString()) {
      throw ApiError.badRequest('Academic Year does not match section academic year');
    }

    // Check duplicate assignment
    const existing = await FacultyAssignment.findOne({
      collegeId: new mongoose.Types.ObjectId(effectiveCollegeId),
      facultyId: faculty._id,
      sectionId: section._id,
      subjectId: subject._id,
      isActive: true,
    });
    if (existing) {
      throw ApiError.conflict(
        `Faculty "${faculty.name}" is already assigned to "${subject.name}" for section "${section.name}"`
      );
    }

    const assignment = await FacultyAssignment.create({
      collegeId: new mongoose.Types.ObjectId(effectiveCollegeId),
      departmentId: faculty.departmentId,
      facultyId: faculty._id,
      facultyName: faculty.name,
      courseId: section.courseId,
      semesterId: section.semesterId,
      sectionId: section._id,
      subjectId: subject._id,
      academicYearId: section.academicYearId,
      roomId: data.roomId || null,
      maxStudents: data.maxStudents || section.capacity,
      assignmentType: data.assignmentType || 'lecture',
      assignedBy: requester.id,
      isActive: true,
      assignedAt: new Date(),
    });

    // Update Faculty references
    await Faculty.updateOne(
      { _id: faculty._id },
      { $addToSet: { subjectIds: subject._id, sectionIds: section._id } }
    );

    await AuditLog.create({
      collegeId: effectiveCollegeId,
      actorUserId: requester.id,
      action: 'FACULTY_ASSIGNMENT_CREATED',
      entityType: 'FacultyAssignment',
      entityId: assignment.id,
      newValue: assignment.toJSON(),
    });

    return assignment;
  }

  static async updateFacultyAssignment(
    id: string,
    update: { roomId?: string; maxStudents?: number; assignmentType?: string; isActive?: boolean },
    requester: AuthenticatedUser
  ): Promise<IFacultyAssignment> {
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN, AppRole.HOD].includes(requester.role)) {
      throw ApiError.forbidden('Only administrators and HODs have permission to update faculty assignments');
    }

    const assignment = await this.getFacultyAssignmentById(id, requester);
    const prev = assignment.toJSON();

    if (update.roomId !== undefined) assignment.roomId = update.roomId;
    if (update.maxStudents !== undefined) assignment.maxStudents = update.maxStudents;
    if (update.assignmentType !== undefined) assignment.assignmentType = update.assignmentType;
    if (update.isActive !== undefined) assignment.isActive = update.isActive;

    await assignment.save();

    await AuditLog.create({
      collegeId: assignment.collegeId.toString(),
      actorUserId: requester.id,
      action: 'FACULTY_ASSIGNMENT_UPDATED',
      entityType: 'FacultyAssignment',
      entityId: assignment.id,
      previousValue: prev,
      newValue: assignment.toJSON(),
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
      isActive?: boolean;
      page?: number;
      limit?: number;
    } = {}
  ): Promise<{ items: IFacultyAssignment[]; page: number; limit: number; total: number; totalPages: number }> {
    const mongoQuery: Record<string, unknown> = {};

    if (requester.role === AppRole.STUDENT) {
      const studentProfile = await Student.findOne({ userId: requester.id });
      if (!studentProfile || !studentProfile.sectionId) return { items: [], page: 1, limit: 1, total: 0, totalPages: 0 };
      mongoQuery.collegeId = new mongoose.Types.ObjectId(requester.collegeId);
      mongoQuery.sectionId = studentProfile.sectionId;
    } else if (requester.role === AppRole.FACULTY) {
      const facultyProfile = await Faculty.findOne({ userId: requester.id });
      if (!facultyProfile) return { items: [], page: 1, limit: 1, total: 0, totalPages: 0 };
      mongoQuery.collegeId = new mongoose.Types.ObjectId(requester.collegeId);
      mongoQuery.facultyId = facultyProfile._id;
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
    if (query.academicYearId) mongoQuery.academicYearId = new mongoose.Types.ObjectId(query.academicYearId);
    if (query.isActive !== undefined) mongoQuery.isActive = query.isActive;

    const page = Math.max(1, query.page || 1);
    const limit = Math.min(100, Math.max(1, query.limit || 50));
    const skip = (page - 1) * limit;

    const [items, total] = await Promise.all([
      FacultyAssignment.find(mongoQuery).sort({ createdAt: -1 }).skip(skip).limit(limit),
      FacultyAssignment.countDocuments(mongoQuery),
    ]);

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

  static async deleteFacultyAssignment(id: string, requester: AuthenticatedUser): Promise<void> {
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

    if (hasAttendance || hasPublishedTimetable) {
      // Safe deactivation: preserve historical attendance and audit record
      assignment.isActive = false;
      await assignment.save();
    } else {
      await FacultyAssignment.findByIdAndDelete(id);
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

    const remainingForFacultySection = await FacultyAssignment.countDocuments({
      facultyId: assignment.facultyId,
      sectionId: assignment.sectionId,
      isActive: true,
      _id: { $ne: assignment._id },
    });
    if (remainingForFacultySection === 0) {
      await Faculty.updateOne({ _id: assignment.facultyId }, { $pull: { sectionIds: assignment.sectionId } });
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
        const distinctSections = new Set(assignments.map((a) => a.sectionId.toString())).size;

        return {
          facultyId: fac.id,
          facultyName: fac.name,
          employeeId: fac.employeeId || fac.instituteId,
          departmentId: fac.departmentId?.toString(),
          assignedSubjectCount: distinctSubjects,
          assignedSectionCount: distinctSections,
          totalAssignments: assignments.length,
          assignments: assignments.map((a) => a.toJSON()),
        };
      })
    );

    return workloads;
  }
}
