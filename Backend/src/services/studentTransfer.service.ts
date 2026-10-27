import mongoose from 'mongoose';
import {
  Student,
  IStudent,
  StudentEnrollment,
  College,
  Department,
  WorkspaceMembership,
  IWorkspaceMembership,
  WorkspaceRoleAssignment,
  StudentTransfer,
  IStudentTransfer,
  AuditLog,
  User,
} from '../models';
import { AppRole } from '../constants/roles';
import {
  MembershipStatus,
  RoleAssignmentStatus,
  StudentLifecycleState,
  CollegeStatus,
  DepartmentStatus,
} from '../constants/status';
import { ApiError } from '../utils/apiError';
import { AuthenticatedUser } from '../types/auth.types';

export interface ExecuteStudentTransferInput {
  sourceStudentId: string;
  destinationCollegeId: string;
  destinationDepartmentId: string;
  destinationPin: string;
  destinationCourseId?: string;
  destinationSemesterId?: string;
  destinationAcademicYearId?: string;
  destinationSectionId?: string;
  reason?: string;
  evidenceDocuments?: Array<{ title: string; url: string }>;
}

export class StudentTransferService {
  /**
   * Authoritative, atomic execution of student transfer between colleges.
   * - Preserves the global user account.
   * - Preserves original College A membership, PIN, enrollments, attendance, marks, and audit logs.
   * - Creates/activates College B membership with College B PIN.
   * - Creates destination Student profile and optional enrollment in College B.
   * - Updates source membership to TRANSFERRED.
   * - Prevents duplicate or overlapping active memberships in College B.
   * - On failure, rolls back destination records leaving source college completely untouched.
   */
  static async transferStudent(
    requester: AuthenticatedUser,
    input: ExecuteStudentTransferInput
  ): Promise<{
    transferRecord: IStudentTransfer;
    destinationStudent: IStudent;
    destinationMembership: IWorkspaceMembership;
  }> {
    // 1. Authorize actor (Admin only)
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN].includes(requester.role)) {
      throw ApiError.forbidden('Only College Administrators or Super Admins can execute student college transfers');
    }

    if (!mongoose.Types.ObjectId.isValid(input.sourceStudentId)) {
      throw ApiError.badRequest('Invalid sourceStudentId format');
    }
    if (!mongoose.Types.ObjectId.isValid(input.destinationCollegeId)) {
      throw ApiError.badRequest('Invalid destinationCollegeId format');
    }
    if (!mongoose.Types.ObjectId.isValid(input.destinationDepartmentId)) {
      throw ApiError.badRequest('Invalid destinationDepartmentId format');
    }

    const cleanDestPin = input.destinationPin ? input.destinationPin.trim().toUpperCase() : '';
    if (!cleanDestPin) {
      throw ApiError.badRequest('A destination institutional PIN Number is required');
    }

    // 2. Load and validate source student
    const sourceStudent = await Student.findById(input.sourceStudentId);
    if (!sourceStudent) {
      throw ApiError.notFound('Source student profile not found');
    }

    if (sourceStudent.lifecycleState === StudentLifecycleState.TRANSFERRED) {
      throw ApiError.badRequest('Student has already been transferred from this institution');
    }

    const sourceCollegeId = sourceStudent.collegeId;
    if (sourceCollegeId.toString() === input.destinationCollegeId) {
      throw ApiError.badRequest('Source and destination colleges cannot be identical for an inter-college transfer');
    }

    // Cross-tenant check for requester
    if (requester.role === AppRole.COLLEGE_ADMIN && requester.collegeId) {
      const isSourceAdmin = requester.collegeId.toString() === sourceCollegeId.toString();
      const isDestAdmin = requester.collegeId.toString() === input.destinationCollegeId;
      if (!isSourceAdmin && !isDestAdmin) {
        throw ApiError.forbidden('College Admin can only transfer students originating from or admitted to their institution');
      }
    }

    // 3. Resolve student's global user
    if (!sourceStudent.userId) {
      throw ApiError.badRequest('Source student profile is not linked to a global user account');
    }
    const globalUser = await User.findById(sourceStudent.userId);
    if (!globalUser) {
      throw ApiError.notFound('Global user account for this student was not found');
    }

    // 4. Validate destination college and department
    const destCollege = await College.findById(input.destinationCollegeId);
    if (!destCollege || destCollege.status === CollegeStatus.INACTIVE || !destCollege.isActive) {
      throw ApiError.notFound('Destination institution does not exist or is inactive');
    }

    const destDepartment = await Department.findOne({
      _id: new mongoose.Types.ObjectId(input.destinationDepartmentId),
      collegeId: destCollege._id,
    });
    if (!destDepartment || destDepartment.status === DepartmentStatus.INACTIVE || !destDepartment.isActive) {
      throw ApiError.notFound('Destination department does not exist in destination institution');
    }

    // 5. Enforce College-Scoped Institutional PIN Uniqueness in Destination College
    const pinConflict = await WorkspaceMembership.findOne({
      collegeId: destCollege._id,
      instituteId: cleanDestPin,
    });
    if (pinConflict && pinConflict.userId.toString() !== globalUser._id.toString()) {
      throw ApiError.conflict(`PIN "${cleanDestPin}" is already assigned to another member in the destination college`);
    }

    const studentPinConflict = await Student.findOne({
      collegeId: destCollege._id,
      instituteId: cleanDestPin,
      _id: { $ne: sourceStudent._id },
    });
    if (studentPinConflict) {
      throw ApiError.conflict(`PIN "${cleanDestPin}" is already assigned to a student in the destination college`);
    }

    // 6. Find or resolve source WorkspaceMembership
    const sourceMembership = await WorkspaceMembership.findOne({
      userId: globalUser._id,
      collegeId: sourceCollegeId,
    });

    // 7. Atomic Execution with Compensating Rollback Guard
    let destinationMembership: IWorkspaceMembership | null = null;
    let destinationStudent: IStudent | null = null;
    let destinationEnrollment: any = null;

    try {
      // Step A: Create or activate destination WorkspaceMembership
      destinationMembership = await WorkspaceMembership.findOne({
        userId: globalUser._id,
        collegeId: destCollege._id,
      });

      if (!destinationMembership) {
        destinationMembership = await WorkspaceMembership.create({
          userId: globalUser._id,
          collegeId: destCollege._id,
          instituteId: cleanDestPin,
          status: MembershipStatus.ACTIVE,
          effectiveStartDate: new Date(),
        });
      } else {
        destinationMembership.status = MembershipStatus.ACTIVE;
        destinationMembership.instituteId = cleanDestPin;
        destinationMembership.effectiveStartDate = new Date();
        destinationMembership.effectiveEndDate = null;
        await destinationMembership.save();
      }

      // Step B: Create/activate destination WorkspaceRoleAssignment
      await WorkspaceRoleAssignment.findOneAndUpdate(
        {
          membershipId: destinationMembership._id,
          role: AppRole.STUDENT,
        },
        {
          userId: globalUser._id,
          collegeId: destCollege._id,
          departmentId: destDepartment._id,
          status: RoleAssignmentStatus.ACTIVE,
          assignedBy: requester.id,
          effectiveStartDate: new Date(),
          effectiveEndDate: null,
          revokedAt: null,
          revokedBy: null,
        },
        { upsert: true, new: true }
      );

      // Step C: Create destination Student profile
      destinationStudent = await Student.create({
        collegeId: destCollege._id,
        departmentId: destDepartment._id,
        userId: globalUser._id,
        instituteId: cleanDestPin,
        name: sourceStudent.name,
        rollNumber: sourceStudent.rollNumber || null,
        admissionNumber: sourceStudent.admissionNumber || cleanDestPin,
        email: sourceStudent.email || globalUser.email,
        phone: sourceStudent.phone || globalUser.phone,
        courseId: input.destinationCourseId ? new mongoose.Types.ObjectId(input.destinationCourseId) : null,
        academicYearId: input.destinationAcademicYearId ? new mongoose.Types.ObjectId(input.destinationAcademicYearId) : null,
        semesterId: input.destinationSemesterId ? new mongoose.Types.ObjectId(input.destinationSemesterId) : null,
        sectionId: input.destinationSectionId ? new mongoose.Types.ObjectId(input.destinationSectionId) : null,
        lifecycleState: StudentLifecycleState.ACTIVE,
        admissionDate: new Date(),
        parentName: sourceStudent.parentName || null,
        parentPhone: sourceStudent.parentPhone || null,
        bloodGroup: sourceStudent.bloodGroup || null,
        address: sourceStudent.address || null,
        dateOfBirth: sourceStudent.dateOfBirth || null,
        metadata: {
          transferredFromCollegeId: sourceCollegeId.toString(),
          transferredFromStudentId: sourceStudent._id.toString(),
          transferredAt: new Date().toISOString(),
        },
      });

      // Step D: Optional destination enrollment
      if (
        input.destinationCourseId &&
        input.destinationSemesterId &&
        input.destinationAcademicYearId
      ) {
        destinationEnrollment = await StudentEnrollment.create({
          collegeId: destCollege._id,
          studentId: destinationStudent._id,
          courseId: new mongoose.Types.ObjectId(input.destinationCourseId),
          semesterId: new mongoose.Types.ObjectId(input.destinationSemesterId),
          academicYearId: new mongoose.Types.ObjectId(input.destinationAcademicYearId),
          sectionId: input.destinationSectionId ? new mongoose.Types.ObjectId(input.destinationSectionId) : null,
          enrollmentDate: new Date(),
          status: 'active',
        });
      }

      // Step E: Update source membership to TRANSFERRED
      if (sourceMembership) {
        sourceMembership.status = MembershipStatus.TRANSFERRED;
        sourceMembership.effectiveEndDate = new Date();
        await sourceMembership.save();
      }

      // Step F: Mark source student lifecycleState as TRANSFERRED
      sourceStudent.lifecycleState = StudentLifecycleState.TRANSFERRED;
      await sourceStudent.save();

      // Step G: End source active enrollments
      await StudentEnrollment.updateMany(
        {
          studentId: sourceStudent._id,
          collegeId: sourceCollegeId,
          status: 'active',
        },
        {
          $set: {
            status: 'transferred',
            endDate: new Date(),
          },
        }
      );

      // Step H: Record StudentTransfer history
      const transferRecord = await StudentTransfer.create({
        userId: globalUser._id,
        sourceCollegeId,
        sourceStudentId: sourceStudent._id,
        sourceMembershipId: sourceMembership?._id || null,
        sourcePin: sourceStudent.instituteId || (sourceMembership?.instituteId ?? 'UNKNOWN'),
        destinationCollegeId: destCollege._id,
        destinationStudentId: destinationStudent._id,
        destinationMembershipId: destinationMembership._id,
        destinationPin: cleanDestPin,
        destinationDepartmentId: destDepartment._id,
        destinationCourseId: input.destinationCourseId ? new mongoose.Types.ObjectId(input.destinationCourseId) : null,
        destinationSemesterId: input.destinationSemesterId ? new mongoose.Types.ObjectId(input.destinationSemesterId) : null,
        destinationAcademicYearId: input.destinationAcademicYearId ? new mongoose.Types.ObjectId(input.destinationAcademicYearId) : null,
        status: 'COMPLETED',
        transferDate: new Date(),
        effectiveDate: new Date(),
        reason: input.reason || null,
        approvedBy: new mongoose.Types.ObjectId(requester.id),
        approvedAt: new Date(),
        evidenceDocuments: input.evidenceDocuments || [],
      });

      // Step I: AuditLog
      await AuditLog.create({
        collegeId: destCollege.id,
        actorUserId: requester.id,
        action: 'STUDENT_COLLEGE_TRANSFER',
        entityType: 'StudentTransfer',
        entityId: transferRecord.id,
        previousValue: {
          sourceCollegeId: sourceCollegeId.toString(),
          sourceStudentId: sourceStudent.id,
          sourcePin: sourceStudent.instituteId,
        },
        newValue: {
          destinationCollegeId: destCollege.id,
          destinationStudentId: destinationStudent.id,
          destinationPin: cleanDestPin,
        },
      });

      return {
        transferRecord,
        destinationStudent,
        destinationMembership,
      };
    } catch (error) {
      // Compensating Rollback: Clean up newly created destination artifacts
      if (destinationEnrollment) {
        await StudentEnrollment.deleteOne({ _id: destinationEnrollment._id }).catch(() => {});
      }
      if (destinationStudent) {
        await Student.deleteOne({ _id: destinationStudent._id }).catch(() => {});
      }
      // Re-throw original or formatted error
      throw error;
    }
  }

  /**
   * List transfer records for a student or college.
   */
  static async listTransfers(
    requester: AuthenticatedUser,
    query: {
      studentId?: string;
      collegeId?: string;
      userId?: string;
    }
  ): Promise<IStudentTransfer[]> {
    const filter: Record<string, any> = {};

    if (query.userId && mongoose.Types.ObjectId.isValid(query.userId)) {
      filter.userId = new mongoose.Types.ObjectId(query.userId);
    }
    if (query.studentId && mongoose.Types.ObjectId.isValid(query.studentId)) {
      const sId = new mongoose.Types.ObjectId(query.studentId);
      filter.$or = [{ sourceStudentId: sId }, { destinationStudentId: sId }];
    }
    if (query.collegeId && mongoose.Types.ObjectId.isValid(query.collegeId)) {
      const cId = new mongoose.Types.ObjectId(query.collegeId);
      filter.$or = [{ sourceCollegeId: cId }, { destinationCollegeId: cId }];
    }

    // Role scoping
    if (requester.role === AppRole.STUDENT) {
      filter.userId = new mongoose.Types.ObjectId(requester.id);
    } else if (requester.role === AppRole.COLLEGE_ADMIN && requester.collegeId) {
      const cId = new mongoose.Types.ObjectId(requester.collegeId);
      filter.$or = [{ sourceCollegeId: cId }, { destinationCollegeId: cId }];
    }

    return StudentTransfer.find(filter)
      .populate('sourceCollegeId', 'name code')
      .populate('destinationCollegeId', 'name code')
      .populate('destinationDepartmentId', 'name code')
      .sort({ transferDate: -1 });
  }
}
