import mongoose, { Types } from 'mongoose';
import { ApiError } from '../utils/apiError';
import { AuthenticatedUser } from '../types/auth.types';
import { AcademicScopeType, ValidatedAcademicScope } from '../types/academicScope.types';
import {
  Department,
  Course,
  AcademicYear,
  Semester,
  Section,
  Subject,
  FacultyAssignment,
} from '../models';
import { TeachingAuthorizationService } from './teachingAuthorization.service';

export interface ScopeInputDTO {
  scope?: string | null;
  departmentId?: string | null;
  courseId?: string | null;
  academicYearId?: string | null;
  semesterId?: string | null;
  sectionId?: string | null;
  subjectId?: string | null;
  facultyAssignmentId?: string | null;
}

export class AcademicScopeService {
  /**
   * Helper to resolve HOD department ID reliably
   */
  public static async resolveHodDepartmentId(
    requester: AuthenticatedUser,
    collegeId: string
  ): Promise<string> {
    if (requester.departmentId) {
      return requester.departmentId.toString();
    }
    const dept = await Department.findOne({
      collegeId: new mongoose.Types.ObjectId(collegeId),
      hodId: new mongoose.Types.ObjectId(requester.id),
    });
    if (dept) {
      return dept._id.toString();
    }
    throw ApiError.forbidden('HOD is not assigned to a department');
  }

  /**
   * Authoritatively validate and resolve the academic scope for assignment or event creation.
   * Enforces role boundaries:
   * - STUDENT: forbidden.
   * - SUPER_ADMIN & COLLEGE_ADMIN: validated against institution hierarchy.
   * - HOD: restricted to own department.
   * - FACULTY: restricted strictly to active teaching assignments.
   */
  public static async validateAndResolveScope(
    collegeId: string,
    requester: AuthenticatedUser,
    input: ScopeInputDTO,
    activityLabel: string = 'this academic resource'
  ): Promise<ValidatedAcademicScope> {
    const roleUpper = (requester.role || '').toUpperCase();

    if (roleUpper === 'STUDENT') {
      throw ApiError.forbidden(`Students are not authorized to create ${activityLabel}.`);
    }

    if (!collegeId) {
      throw ApiError.badRequest('College scope context is required.');
    }

    let departmentId: string | null = null;
    let courseId: string | null = null;
    let academicYearId: string | null = null;
    let semesterId: string | null = null;
    let sectionId: string | null = null;
    let subjectId: string | null = null;
    let facultyAssignmentId: string | null = null;
    let scopeType: AcademicScopeType = AcademicScopeType.SECTION;

    // Normalize scope type if passed
    if (input.scope) {
      const normalized = input.scope.toUpperCase();
      if (Object.values(AcademicScopeType).includes(normalized as AcademicScopeType)) {
        scopeType = normalized as AcademicScopeType;
      }
    }

    // ─────────────────────────────────────────────────────────────
    // 1. FACULTY ROLE VALIDATION
    // ─────────────────────────────────────────────────────────────
    if (roleUpper === 'FACULTY') {
      if (scopeType === AcademicScopeType.COLLEGE || scopeType === AcademicScopeType.DEPARTMENT) {
        throw ApiError.forbidden(`Faculty cannot publish college or department-wide ${activityLabel}.`);
      }

      let faDoc: any = null;

      if (input.facultyAssignmentId && Types.ObjectId.isValid(input.facultyAssignmentId)) {
        faDoc = await TeachingAuthorizationService.assertFacultyAssignmentAccess(
          collegeId,
          requester,
          input.facultyAssignmentId,
          activityLabel
        );
      } else if (input.subjectId && Types.ObjectId.isValid(input.subjectId)) {
        faDoc = await TeachingAuthorizationService.assertSubjectTeachingAccess(
          collegeId,
          requester,
          input.subjectId,
          input.sectionId,
          activityLabel
        );
      } else {
        throw ApiError.badRequest(`Faculty must select an authorized teaching context for ${activityLabel}.`);
      }

      if (!faDoc) {
        throw ApiError.forbidden(`Faculty is not assigned to this subject or teaching context.`);
      }

      if (!faDoc.isActive || (faDoc.status && faDoc.status.toLowerCase() !== 'active')) {
        throw ApiError.badRequest('This teaching assignment is no longer active.');
      }

      facultyAssignmentId = faDoc._id.toString();
      departmentId = faDoc.departmentId ? faDoc.departmentId.toString() : null;
      courseId = faDoc.courseId ? faDoc.courseId.toString() : null;
      academicYearId = faDoc.academicYearId ? faDoc.academicYearId.toString() : null;
      semesterId = faDoc.semesterId ? faDoc.semesterId.toString() : null;
      sectionId = faDoc.sectionId ? faDoc.sectionId.toString() : null;
      subjectId = faDoc.subjectId ? faDoc.subjectId.toString() : null;
      scopeType = sectionId ? AcademicScopeType.SECTION : AcademicScopeType.SEMESTER;

      return {
        scope: scopeType,
        collegeId,
        departmentId,
        courseId,
        academicYearId,
        semesterId,
        sectionId,
        subjectId,
        facultyAssignmentId,
        facultyId: requester.id,
      };
    }

    // ─────────────────────────────────────────────────────────────
    // 2. HOD ROLE VALIDATION
    // ─────────────────────────────────────────────────────────────
    if (roleUpper === 'HOD') {
      const hodDeptId = await this.resolveHodDepartmentId(requester, collegeId);

      if (scopeType === AcademicScopeType.COLLEGE) {
        throw ApiError.forbidden(`HOD is not permitted to create college-wide ${activityLabel}.`);
      }

      if (input.departmentId && input.departmentId !== hodDeptId) {
        throw ApiError.forbidden(`HOD can only create ${activityLabel} within their own department.`);
      }

      departmentId = hodDeptId;

      // If facultyAssignmentId passed, verify it belongs to this HOD's department
      if (input.facultyAssignmentId && Types.ObjectId.isValid(input.facultyAssignmentId)) {
        const fa = await FacultyAssignment.findOne({
          _id: new Types.ObjectId(input.facultyAssignmentId),
          collegeId: new Types.ObjectId(collegeId),
          departmentId: new Types.ObjectId(hodDeptId),
          isActive: true,
        });
        if (!fa) {
          throw ApiError.notFound('Teaching assignment context not found in your department.');
        }
        facultyAssignmentId = fa._id.toString();
        courseId = fa.courseId.toString();
        academicYearId = fa.academicYearId ? fa.academicYearId.toString() : null;
        semesterId = fa.semesterId.toString();
        sectionId = fa.sectionId ? fa.sectionId.toString() : null;
        subjectId = fa.subjectId.toString();
      } else {
        // Validate individual identifiers within HOD's department
        if (input.courseId && Types.ObjectId.isValid(input.courseId)) {
          const course = await Course.findOne({
            _id: new Types.ObjectId(input.courseId),
            departmentId: new Types.ObjectId(hodDeptId),
            collegeId: new Types.ObjectId(collegeId),
          });
          if (!course) {
            throw ApiError.notFound('Course/Program not found in your department.');
          }
          courseId = course._id.toString();
        }

        if (input.semesterId && Types.ObjectId.isValid(input.semesterId)) {
          const sem = await Semester.findOne({
            _id: new Types.ObjectId(input.semesterId),
            departmentId: new Types.ObjectId(hodDeptId),
            collegeId: new Types.ObjectId(collegeId),
          });
          if (!sem) {
            throw ApiError.notFound('Semester not found in your department.');
          }
          semesterId = sem._id.toString();
          if (!academicYearId && sem.academicYearId) {
            academicYearId = sem.academicYearId.toString();
          }
          if (!courseId && sem.courseId) {
            courseId = sem.courseId.toString();
          }
        }

        if (input.sectionId && Types.ObjectId.isValid(input.sectionId)) {
          const sec = await Section.findOne({
            _id: new Types.ObjectId(input.sectionId),
            departmentId: new Types.ObjectId(hodDeptId),
            collegeId: new Types.ObjectId(collegeId),
          });
          if (!sec) {
            throw ApiError.notFound('Section not found in your department.');
          }
          sectionId = sec._id.toString();
        }

        if (input.subjectId && Types.ObjectId.isValid(input.subjectId)) {
          const subj = await Subject.findOne({
            _id: new Types.ObjectId(input.subjectId),
            departmentId: new Types.ObjectId(hodDeptId),
            collegeId: new Types.ObjectId(collegeId),
          });
          if (!subj) {
            throw ApiError.notFound('Subject not found in your department.');
          }
          subjectId = subj._id.toString();
        }
      }

      if (!input.scope) {
        scopeType = sectionId
          ? AcademicScopeType.SECTION
          : semesterId
          ? AcademicScopeType.SEMESTER
          : AcademicScopeType.DEPARTMENT;
      }

      return {
        scope: scopeType,
        collegeId,
        departmentId,
        courseId,
        academicYearId,
        semesterId,
        sectionId,
        subjectId,
        facultyAssignmentId,
        facultyId: requester.id,
      };
    }

    // ─────────────────────────────────────────────────────────────
    // 3. COLLEGE ADMIN / SUPER ADMIN VALIDATION
    // ─────────────────────────────────────────────────────────────
    if (roleUpper === 'SUPER_ADMIN' || roleUpper === 'COLLEGE_ADMIN') {
      if (input.facultyAssignmentId && Types.ObjectId.isValid(input.facultyAssignmentId)) {
        const fa = await FacultyAssignment.findOne({
          _id: new Types.ObjectId(input.facultyAssignmentId),
          collegeId: new Types.ObjectId(collegeId),
          isActive: true,
        });
        if (!fa) {
          throw ApiError.notFound('Teaching assignment context not found in this institution.');
        }
        facultyAssignmentId = fa._id.toString();
        departmentId = fa.departmentId.toString();
        courseId = fa.courseId.toString();
        academicYearId = fa.academicYearId ? fa.academicYearId.toString() : null;
        semesterId = fa.semesterId.toString();
        sectionId = fa.sectionId ? fa.sectionId.toString() : null;
        subjectId = fa.subjectId.toString();
      } else {
        if (input.departmentId && Types.ObjectId.isValid(input.departmentId)) {
          const dept = await Department.findOne({
            _id: new Types.ObjectId(input.departmentId),
            collegeId: new Types.ObjectId(collegeId),
          });
          if (!dept) {
            throw ApiError.notFound('Department not found in this institution.');
          }
          departmentId = dept._id.toString();
        }

        if (input.courseId && Types.ObjectId.isValid(input.courseId)) {
          const course = await Course.findOne({
            _id: new Types.ObjectId(input.courseId),
            collegeId: new Types.ObjectId(collegeId),
          });
          if (!course) {
            throw ApiError.notFound('Course/Program not found in this institution.');
          }
          courseId = course._id.toString();
          if (!departmentId && course.departmentId) {
            departmentId = course.departmentId.toString();
          }
        }

        if (input.semesterId && Types.ObjectId.isValid(input.semesterId)) {
          const sem = await Semester.findOne({
            _id: new Types.ObjectId(input.semesterId),
            collegeId: new Types.ObjectId(collegeId),
          });
          if (!sem) {
            throw ApiError.notFound('Semester not found in this institution.');
          }
          semesterId = sem._id.toString();
          if (!academicYearId && sem.academicYearId) {
            academicYearId = sem.academicYearId.toString();
          }
          if (!courseId && sem.courseId) {
            courseId = sem.courseId.toString();
          }
          if (!departmentId && sem.departmentId) {
            departmentId = sem.departmentId.toString();
          }
        }

        if (input.sectionId && Types.ObjectId.isValid(input.sectionId)) {
          const sec = await Section.findOne({
            _id: new Types.ObjectId(input.sectionId),
            collegeId: new Types.ObjectId(collegeId),
          });
          if (!sec) {
            throw ApiError.notFound('Section not found in this institution.');
          }
          sectionId = sec._id.toString();
        }

        if (input.subjectId && Types.ObjectId.isValid(input.subjectId)) {
          const subj = await Subject.findOne({
            _id: new Types.ObjectId(input.subjectId),
            collegeId: new Types.ObjectId(collegeId),
          });
          if (!subj) {
            throw ApiError.notFound('Subject not found in this institution.');
          }
          subjectId = subj._id.toString();
        }
      }

      if (!scopeType) {
        scopeType = sectionId
          ? AcademicScopeType.SECTION
          : semesterId
          ? AcademicScopeType.SEMESTER
          : departmentId
          ? AcademicScopeType.DEPARTMENT
          : AcademicScopeType.COLLEGE;
      }

      // If academicYearId still not resolved, lookup active academic year for college
      if (!academicYearId) {
        const activeAy = await AcademicYear.findOne({
          collegeId: new Types.ObjectId(collegeId),
          status: 'active',
        });
        if (activeAy) {
          academicYearId = activeAy._id.toString();
        }
      }

      return {
        scope: scopeType,
        collegeId,
        departmentId,
        courseId,
        academicYearId,
        semesterId,
        sectionId,
        subjectId,
        facultyAssignmentId,
        facultyId: requester.id,
      };
    }

    throw ApiError.forbidden(`Role ${requester.role} is not authorized to create ${activityLabel}.`);
  }
}
