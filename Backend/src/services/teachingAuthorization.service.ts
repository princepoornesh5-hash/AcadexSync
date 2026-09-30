import { Types } from 'mongoose';
import { ApiError } from '../utils/apiError';
import { Faculty, FacultyAssignment, IFacultyAssignment, Subject } from '../models';

export interface AuthUserContext {
  id: string;
  role?: string;
  name?: string;
  email?: string;
  collegeId?: string;
  departmentId?: string;
}

export class TeachingAuthorizationService {
  /**
   * Resolves the Faculty document (if any) corresponding to the authenticated user.
   * Resolves via canonical userId, _id, or verified user email.
   * Never uses name matching.
   */
  static async resolveFacultyProfile(collegeId: string, user: AuthUserContext) {
    if (!user.id) return null;
    let faculty = await Faculty.findOne({
      collegeId: new Types.ObjectId(collegeId),
      userId: new Types.ObjectId(user.id),
    });
    if (!faculty && Types.ObjectId.isValid(user.id)) {
      faculty = await Faculty.findOne({
        collegeId: new Types.ObjectId(collegeId),
        _id: new Types.ObjectId(user.id),
      });
    }
    if (!faculty && user.email) {
      faculty = await Faculty.findOne({
        collegeId: new Types.ObjectId(collegeId),
        email: user.email.toLowerCase(),
      });
    }
    return faculty;
  }

  /**
   * Checks if a given faculty user canonically owns a faculty assignment record.
   * Strictly enforces canonical database identifiers (userId, facultyId, _id).
   * Unsafe name matching fallback has been completely removed to prevent impersonation.
   */
  static async isFacultyOwner(
    collegeId: string,
    user: AuthUserContext,
    fa: IFacultyAssignment
  ): Promise<boolean> {
    if (!fa) return false;

    // Direct user ID match
    if (fa.facultyId && fa.facultyId.toString() === user.id) {
      return true;
    }

    // Resolve faculty document and verify canonical _id or userId
    const faculty = await this.resolveFacultyProfile(collegeId, user);
    if (faculty) {
      if (fa.facultyId && fa.facultyId.toString() === faculty._id.toString()) {
        return true;
      }
      if (faculty.userId && fa.facultyId && fa.facultyId.toString() === faculty.userId.toString()) {
        return true;
      }
    }

    // Fail closed: No name matching, no display name matching, no initials.
    return false;
  }

  /**
   * Asserts that the authenticated user is authorized to manage the given FacultyAssignment.
   * - SUPER_ADMIN & COLLEGE_ADMIN: permitted across institution.
   * - HOD: permitted for sections/subjects in their department.
   * - FACULTY: permitted ONLY for classes they own.
   * Throws HTTP 403 Forbidden with human-readable message if unauthorized.
   */
  static async assertFacultyAssignmentAccess(
    collegeId: string,
    user: AuthUserContext,
    facultyAssignmentId: string | Types.ObjectId,
    activityLabel: string = 'this teaching context'
  ): Promise<IFacultyAssignment> {
    const roleUpper = (user.role || '').toUpperCase();

    const fa = await FacultyAssignment.findOne({
      _id: new Types.ObjectId(facultyAssignmentId),
      collegeId: new Types.ObjectId(collegeId),
    });

    if (!fa) {
      throw ApiError.notFound('Teaching context (Faculty Assignment) not found for this college.');
    }

    if (roleUpper === 'SUPER_ADMIN' || roleUpper === 'COLLEGE_ADMIN') {
      return fa;
    }

    if (roleUpper === 'HOD') {
      if (user.departmentId && fa.departmentId && fa.departmentId.toString() !== user.departmentId.toString()) {
        throw ApiError.forbidden(`You are not authorized to manage ${activityLabel} outside your department.`);
      }
      return fa;
    }

    if (roleUpper === 'FACULTY') {
      const isOwner = await this.isFacultyOwner(collegeId, user, fa);
      if (!isOwner) {
        throw ApiError.forbidden(`You are not authorized to manage ${activityLabel}. This context is not assigned to you.`);
      }
      return fa;
    }

    throw ApiError.forbidden(`You are not authorized to manage ${activityLabel}.`);
  }

  /**
   * Asserts teaching context authorization for a subject and optional section.
   * Supports institutions where section concept is disabled.
   */
  static async assertSubjectSectionAccess(
    collegeId: string,
    user: AuthUserContext,
    subjectId: string | Types.ObjectId,
    sectionId?: string | Types.ObjectId | null,
    activityLabel: string = 'this teaching context'
  ): Promise<IFacultyAssignment | null> {
    const roleUpper = (user.role || '').toUpperCase();

    const query: any = {
      collegeId: new Types.ObjectId(collegeId),
      subjectId: new Types.ObjectId(subjectId),
      isActive: true,
    };

    if (sectionId && Types.ObjectId.isValid(sectionId.toString())) {
      query.sectionId = new Types.ObjectId(sectionId);
    }

    const assignments = await FacultyAssignment.find(query);
    const fa = assignments[0] || null;

    if (roleUpper === 'SUPER_ADMIN' || roleUpper === 'COLLEGE_ADMIN') {
      return fa;
    }

    if (roleUpper === 'HOD') {
      if (user.departmentId) {
        if (fa && fa.departmentId && fa.departmentId.toString() !== user.departmentId.toString()) {
          throw ApiError.forbidden(`You are not authorized to manage ${activityLabel} outside your department.`);
        }
        const subject = await Subject.findById(subjectId);
        if (subject && subject.departmentId.toString() !== user.departmentId.toString()) {
          throw ApiError.forbidden(`You are not authorized to manage ${activityLabel} outside your department.`);
        }
      }
      return fa;
    }

    if (roleUpper === 'FACULTY') {
      if (!assignments || assignments.length === 0) {
        throw ApiError.forbidden(`You are not authorized to manage ${activityLabel}. No teaching assignment found.`);
      }
      for (const item of assignments) {
        const isOwner = await this.isFacultyOwner(collegeId, user, item);
        if (isOwner) {
          return item;
        }
      }
      throw ApiError.forbidden(`You are not authorized to manage ${activityLabel}. This context is not assigned to you.`);
    }

    throw ApiError.forbidden(`You are not authorized to manage ${activityLabel}.`);
  }

  /**
   * Asserts teaching authorization for a Subject (and optional Section) across academic modules
   * such as Notes, Assignments, Assessments, and Labs.
   */
  static async assertSubjectTeachingAccess(
    collegeId: string,
    user: AuthUserContext,
    subjectId: string | Types.ObjectId,
    sectionId?: string | Types.ObjectId | null,
    activityName: string = 'this academic resource'
  ): Promise<IFacultyAssignment | null> {
    const roleUpper = (user.role || '').toUpperCase();

    const subject = await Subject.findOne({
      _id: new Types.ObjectId(subjectId),
      collegeId: new Types.ObjectId(collegeId),
    });
    if (!subject) {
      throw ApiError.notFound('Subject not found for this college.');
    }

    if (roleUpper === 'SUPER_ADMIN' || roleUpper === 'COLLEGE_ADMIN') {
      return null;
    }

    if (roleUpper === 'HOD') {
      if (user.departmentId && subject.departmentId.toString() !== user.departmentId.toString()) {
        throw ApiError.forbidden(`HOD can only manage ${activityName} within their assigned department.`);
      }
      return null;
    }

    if (roleUpper === 'FACULTY') {
      const faculty = await this.resolveFacultyProfile(collegeId, user);
      if (!faculty) {
        throw ApiError.forbidden(`You are not authorized to manage ${activityName}. Faculty profile not found.`);
      }

      if (faculty.departmentId && subject.departmentId.toString() !== faculty.departmentId.toString()) {
        throw ApiError.forbidden(`Faculty cannot manage ${activityName} for subjects in another department.`);
      }

      const query: any = {
        collegeId: new Types.ObjectId(collegeId),
        subjectId: new Types.ObjectId(subjectId),
        isActive: true,
      };

      if (sectionId && Types.ObjectId.isValid(sectionId.toString())) {
        query.sectionId = new Types.ObjectId(sectionId);
      }

      const assignments = await FacultyAssignment.find(query);
      if (!assignments || assignments.length === 0) {
        throw ApiError.forbidden(`You are not authorized to manage ${activityName}. This subject is not assigned to you.`);
      }

      for (const fa of assignments) {
        const isOwner = await this.isFacultyOwner(collegeId, user, fa);
        if (isOwner) {
          return fa;
        }
      }

      throw ApiError.forbidden(`You are not authorized to manage ${activityName}. This subject is not assigned to you.`);
    }

    throw ApiError.forbidden(`You are not authorized to manage ${activityName}.`);
  }

  /**
   * Asserts teaching context authorization for a specific assignment record.
   */
  static async assertAssignmentAccess(
    collegeId: string,
    user: AuthUserContext,
    assignment: any
  ): Promise<void> {
    const roleUpper = (user.role || '').toUpperCase();
    if (roleUpper === 'SUPER_ADMIN' || roleUpper === 'COLLEGE_ADMIN') {
      return;
    }
    if (roleUpper === 'HOD') {
      if (user.departmentId && assignment.departmentId && assignment.departmentId.toString() !== user.departmentId.toString()) {
        throw ApiError.forbidden('You are not authorized to manage assignments outside your department.');
      }
      return;
    }
    if (roleUpper === 'FACULTY') {
      if (assignment.facultyAssignmentId) {
        await this.assertFacultyAssignmentAccess(collegeId, user, assignment.facultyAssignmentId, 'this assignment');
        return;
      }
      if (assignment.facultyId && assignment.facultyId.toString() === user.id) {
        return;
      }
      const faculty = await this.resolveFacultyProfile(collegeId, user);
      if (faculty && assignment.facultyId && assignment.facultyId.toString() === faculty._id.toString()) {
        return;
      }
      throw ApiError.forbidden('You are not authorized to manage this assignment.');
    }
    throw ApiError.forbidden('You are not authorized to manage this assignment.');
  }
}
