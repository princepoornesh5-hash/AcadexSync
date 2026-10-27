import mongoose from 'mongoose';
import { TransferCredit, ITransferCredit } from '../models/transferCredit.model';
import { Student } from '../models/student.model';
import { StudentEnrollment } from '../models/studentEnrollment.model';
import { College } from '../models/college.model';
import { AuditLog } from '../models/auditLog.model';
import { AppRole } from '../constants/roles';
import { TransferCreditStatus, CollegeStatus } from '../constants/status';
import { ApiError } from '../utils/apiError';
import { AuthenticatedUser } from '../types/auth.types';
import { CreateTransferCreditInput, UpdateTransferCreditStatusInput } from '../validations/transferCredit.validation';

export class TransferCreditService {
  /**
   * Authoritatively records a verified transfer credit or recognized prior qualification.
   * Strictly enforces tenant isolation and server-side association validation.
   */
  static async recordTransferCredit(
    requester: AuthenticatedUser,
    input: CreateTransferCreditInput,
    overrideCollegeId?: string
  ): Promise<ITransferCredit> {
    // 1. Authorize actor
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN].includes(requester.role)) {
      throw ApiError.forbidden('Only College Administrators or Super Admins can record transfer credits');
    }

    // 2. Resolve destination college
    const collegeIdStr = requester.role === AppRole.SUPER_ADMIN && overrideCollegeId
      ? overrideCollegeId
      : requester.collegeId;

    if (!collegeIdStr || !mongoose.Types.ObjectId.isValid(collegeIdStr)) {
      throw ApiError.badRequest('A valid institutional college identifier is required');
    }

    const collegeId = new mongoose.Types.ObjectId(collegeIdStr);
    const college = await College.findById(collegeId);
    if (!college || college.status === CollegeStatus.INACTIVE || !college.isActive) {
      throw ApiError.notFound('Target institution does not exist or is inactive');
    }

    // 3. Authorize student reference within this tenant
    if (!mongoose.Types.ObjectId.isValid(input.studentId)) {
      throw ApiError.badRequest('Invalid studentId format');
    }

    const student = await Student.findOne({
      _id: new mongoose.Types.ObjectId(input.studentId),
      collegeId,
    });

    if (!student) {
      throw ApiError.notFound('Student profile not found in this college');
    }

    if (!student.userId) {
      throw ApiError.badRequest('Student must have an active global user account to receive transfer credits');
    }

    // 4. Verify enrollment reference within this tenant
    if (!mongoose.Types.ObjectId.isValid(input.studentEnrollmentId)) {
      throw ApiError.badRequest('Invalid studentEnrollmentId format');
    }

    const enrollment = await StudentEnrollment.findOne({
      _id: new mongoose.Types.ObjectId(input.studentEnrollmentId),
      studentId: student._id,
      collegeId,
    });

    if (!enrollment) {
      throw ApiError.notFound('Referenced student enrollment not found in this college');
    }

    // 5. If originCollegeId is provided, validate it
    let originCollegeObjectId: mongoose.Types.ObjectId | null = null;
    if (input.originCollegeId) {
      if (!mongoose.Types.ObjectId.isValid(input.originCollegeId)) {
        throw ApiError.badRequest('Invalid originCollegeId format');
      }
      if (input.originCollegeId.toString() === collegeId.toString()) {
        throw ApiError.badRequest('originCollegeId cannot be identical to destination collegeId');
      }
      const originCollege = await College.findById(input.originCollegeId);
      if (!originCollege) {
        throw ApiError.notFound('Referenced origin college does not exist');
      }
      originCollegeObjectId = originCollege._id;
    }

    // 6. Map transferred subjects safely
    const formattedSubjects = (input.transferredSubjects || []).map((s) => ({
      subjectCode: s.subjectCode.trim().toUpperCase(),
      subjectName: s.subjectName.trim(),
      credits: s.credits,
      grade: s.grade ? s.grade.trim() : null,
      gradePoints: s.gradePoints ?? null,
      equivalentSubjectId: s.equivalentSubjectId && mongoose.Types.ObjectId.isValid(s.equivalentSubjectId)
        ? new mongoose.Types.ObjectId(s.equivalentSubjectId)
        : null,
      remarks: s.remarks ? s.remarks.trim() : null,
    }));

    // 7. Persist TransferCredit record
    const record = await TransferCredit.create({
      collegeId,
      studentId: student._id,
      studentEnrollmentId: enrollment._id,
      userId: student.userId,
      originCollegeId: originCollegeObjectId,
      originInstitutionName: input.originInstitutionName.trim(),
      priorProgramOrDegree: input.priorProgramOrDegree ? input.priorProgramOrDegree.trim() : null,
      admissionType: input.admissionType,
      entrySemesterNumber: input.entrySemesterNumber,
      recognizedCredits: input.recognizedCredits,
      recognizedGradePoints: input.recognizedGradePoints ?? null,
      transferredSubjects: formattedSubjects,
      verificationStatus: TransferCreditStatus.PENDING,
      verificationDocumentUrl: input.verificationDocumentUrl || null,
      remarks: input.remarks ? input.remarks.trim() : null,
      auditHistory: [
        {
          action: 'RECORDED',
          performedBy: new mongoose.Types.ObjectId(requester.id),
          performedByName: requester.name,
          performedByRole: requester.role,
          timestamp: new Date(),
          details: `Recorded transfer credit from ${input.originInstitutionName}`,
          previousStatus: null,
          newStatus: TransferCreditStatus.PENDING,
        },
      ],
    });

    // 8. Canonical audit log
    await AuditLog.create({
      collegeId: collegeId.toString(),
      actorUserId: requester.id,
      action: 'TRANSFER_CREDIT_RECORDED',
      entityType: 'TransferCredit',
      entityId: record.id,
      newValue: {
        studentId: student.id,
        userId: student.userId.toString(),
        originInstitutionName: record.originInstitutionName,
        recognizedCredits: record.recognizedCredits,
        admissionType: record.admissionType,
      },
    });

    return record;
  }

  /**
   * Updates verification/approval status of a transfer credit record.
   */
  static async updateStatus(
    id: string,
    requester: AuthenticatedUser,
    input: UpdateTransferCreditStatusInput
  ): Promise<ITransferCredit> {
    if (![AppRole.SUPER_ADMIN, AppRole.COLLEGE_ADMIN].includes(requester.role)) {
      throw ApiError.forbidden('Only administrators can approve or reject transfer credits');
    }

    if (!mongoose.Types.ObjectId.isValid(id)) {
      throw ApiError.badRequest('Invalid transfer credit ID');
    }

    const query: Record<string, unknown> = { _id: new mongoose.Types.ObjectId(id) };
    if (requester.role !== AppRole.SUPER_ADMIN) {
      if (!requester.collegeId) throw ApiError.unauthorized('Missing institutional context');
      query.collegeId = new mongoose.Types.ObjectId(requester.collegeId);
    }

    const record = await TransferCredit.findOne(query);
    if (!record) {
      throw ApiError.notFound('Transfer credit record not found for this college');
    }

    const previousStatus = record.verificationStatus;
    record.verificationStatus = input.status;

    const actorId = new mongoose.Types.ObjectId(requester.id);

    if (input.status === TransferCreditStatus.APPROVED) {
      record.approvedBy = actorId;
      record.approvedAt = new Date();
      if (!record.verifiedAt) record.verifiedAt = new Date();
    } else if (input.status === TransferCreditStatus.VERIFIED) {
      record.verifiedAt = new Date();
    } else if (input.status === TransferCreditStatus.REJECTED) {
      record.rejectedAt = new Date();
      record.rejectionReason = input.rejectionReason || null;
    }

    if (input.remarks) {
      record.remarks = input.remarks;
    }

    record.auditHistory.push({
      action: `STATUS_UPDATED_${input.status.toUpperCase()}`,
      performedBy: actorId,
      performedByName: requester.name,
      performedByRole: requester.role,
      timestamp: new Date(),
      details: input.remarks || input.rejectionReason || undefined,
      previousStatus,
      newStatus: input.status,
    });

    await record.save();

    await AuditLog.create({
      collegeId: record.collegeId.toString(),
      actorUserId: requester.id,
      action: 'TRANSFER_CREDIT_STATUS_UPDATED',
      entityType: 'TransferCredit',
      entityId: record.id,
      previousValue: { status: previousStatus },
      newValue: { status: input.status },
    });

    return record;
  }

  /**
   * Retrieves all transfer credit records for a student within the tenant scope.
   */
  static async getByStudent(
    studentId: string,
    requester: AuthenticatedUser
  ): Promise<ITransferCredit[]> {
    if (!mongoose.Types.ObjectId.isValid(studentId)) {
      throw ApiError.badRequest('Invalid studentId');
    }

    const query: Record<string, unknown> = {
      studentId: new mongoose.Types.ObjectId(studentId),
    };

    if (requester.role !== AppRole.SUPER_ADMIN) {
      if (!requester.collegeId) throw ApiError.unauthorized('Missing institutional context');
      query.collegeId = new mongoose.Types.ObjectId(requester.collegeId);
    }

    return TransferCredit.find(query).sort({ createdAt: -1 });
  }

  /**
   * Retrieves single transfer credit record by ID with tenant verification.
   */
  static async getById(
    id: string,
    requester: AuthenticatedUser
  ): Promise<ITransferCredit> {
    if (!mongoose.Types.ObjectId.isValid(id)) {
      throw ApiError.badRequest('Invalid transfer credit ID');
    }

    const query: Record<string, unknown> = { _id: new mongoose.Types.ObjectId(id) };
    if (requester.role !== AppRole.SUPER_ADMIN) {
      if (!requester.collegeId) throw ApiError.unauthorized('Missing institutional context');
      query.collegeId = new mongoose.Types.ObjectId(requester.collegeId);
    }

    const record = await TransferCredit.findOne(query);
    if (!record) {
      throw ApiError.notFound('Transfer credit record not found for this college');
    }

    return record;
  }

  /**
   * List transfer credits with tenant scoping.
   */
  static async list(
    requester: AuthenticatedUser,
    options: { collegeId?: string; studentId?: string; verificationStatus?: string } = {}
  ): Promise<ITransferCredit[]> {
    const query: Record<string, unknown> = {};

    const collegeIdStr = requester.role === AppRole.SUPER_ADMIN && options.collegeId
      ? options.collegeId
      : requester.collegeId;

    if (collegeIdStr && mongoose.Types.ObjectId.isValid(collegeIdStr)) {
      query.collegeId = new mongoose.Types.ObjectId(collegeIdStr);
    }
    if (options.studentId && mongoose.Types.ObjectId.isValid(options.studentId)) {
      query.studentId = new mongoose.Types.ObjectId(options.studentId);
    }
    if (options.verificationStatus) {
      query.verificationStatus = options.verificationStatus;
    }
    if (requester.role === AppRole.STUDENT) {
      query.userId = new mongoose.Types.ObjectId(requester.id);
    }

    return TransferCredit.find(query).sort({ createdAt: -1 });
  }
}
