import { Types } from 'mongoose';
import {
  Student,
  StudentEnrollment,
  AcademicYear,
  Semester,
  Section,
  Subject,
  FacultyAssignment,
} from '../../models';
import { ApiError } from '../../utils/apiError';
import { ImportIssueCode, RowValidationStatus } from '../../constants/import.constants';

export interface IAcademicContextOptions {
  collegeId: string;
  academicYearId?: string;
  semesterId?: string;
  sectionId?: string;
  departmentId?: string;
  courseId?: string;
  subjectId?: string;
  facultyAssignmentId?: string;
  academicYearName?: string;
  semesterName?: string;
  sectionName?: string;
  subjectCode?: string;
}

export interface IResolvedAcademicContext {
  collegeId: Types.ObjectId;
  academicYearId?: Types.ObjectId;
  semesterId?: Types.ObjectId;
  sectionId?: Types.ObjectId;
  departmentId?: Types.ObjectId;
  courseId?: Types.ObjectId;
  subjectId?: Types.ObjectId;
  facultyAssignmentId?: Types.ObjectId;
}

export interface IStudentResolutionResult {
  status: RowValidationStatus;
  issueCode?: ImportIssueCode;
  reason?: string;
  studentId?: string;
  studentEnrollmentId?: string;
  studentName?: string;
  studentPin?: string;
  rollNumber?: string;
  sectionName?: string;
}

export class ContextResolutionService {
  /**
   * Resolves academic hierarchy entities strictly within tenant boundary.
   */
  static async resolveAcademicContext(
    options: IAcademicContextOptions
  ): Promise<IResolvedAcademicContext> {
    const collegeObjectId = new Types.ObjectId(options.collegeId);
    const resolved: IResolvedAcademicContext = { collegeId: collegeObjectId };

    // 1. Academic Year
    if (options.academicYearId) {
      const ay = await AcademicYear.findOne({
        _id: new Types.ObjectId(options.academicYearId),
        collegeId: collegeObjectId,
      });
      if (!ay) throw ApiError.badRequest(`Academic Year '${options.academicYearId}' not found in college`);
      resolved.academicYearId = ay._id as Types.ObjectId;
    } else if (options.academicYearName) {
      const ay = await AcademicYear.findOne({
        collegeId: collegeObjectId,
        name: { $regex: new RegExp(`^${options.academicYearName.trim()}$`, 'i') },
      });
      if (ay) resolved.academicYearId = ay._id as Types.ObjectId;
    }

    // 2. Semester
    if (options.semesterId) {
      const sem = await Semester.findOne({
        _id: new Types.ObjectId(options.semesterId),
        collegeId: collegeObjectId,
      });
      if (!sem) throw ApiError.badRequest(`Semester '${options.semesterId}' not found in college`);
      resolved.semesterId = sem._id as Types.ObjectId;
      resolved.departmentId = sem.departmentId as Types.ObjectId;
      resolved.courseId = sem.courseId as Types.ObjectId;
      if (!resolved.academicYearId) resolved.academicYearId = sem.academicYearId as Types.ObjectId;
    } else if (options.semesterName) {
      const query: any = {
        collegeId: collegeObjectId,
        name: { $regex: new RegExp(`^${options.semesterName.trim()}$`, 'i') },
      };
      if (resolved.academicYearId) query.academicYearId = resolved.academicYearId;
      const sem = await Semester.findOne(query);
      if (sem) {
        resolved.semesterId = sem._id as Types.ObjectId;
        resolved.departmentId = sem.departmentId as Types.ObjectId;
        resolved.courseId = sem.courseId as Types.ObjectId;
      }
    }

    // 3. Section
    if (options.sectionId) {
      const sec = await Section.findOne({
        _id: new Types.ObjectId(options.sectionId),
        collegeId: collegeObjectId,
      });
      if (!sec) throw ApiError.badRequest(`Section '${options.sectionId}' not found in college`);
      resolved.sectionId = sec._id as Types.ObjectId;
      if (!resolved.semesterId) resolved.semesterId = sec.semesterId as Types.ObjectId;
    } else if (options.sectionName) {
      const query: any = {
        collegeId: collegeObjectId,
        name: { $regex: new RegExp(`^${options.sectionName.trim()}$`, 'i') },
      };
      if (resolved.semesterId) query.semesterId = resolved.semesterId;
      const sec = await Section.findOne(query);
      if (sec) resolved.sectionId = sec._id as Types.ObjectId;
    }

    // 4. Subject
    if (options.subjectId) {
      const sub = await Subject.findOne({
        _id: new Types.ObjectId(options.subjectId),
        collegeId: collegeObjectId,
      });
      if (!sub) throw ApiError.badRequest(`Subject '${options.subjectId}' not found in college`);
      resolved.subjectId = sub._id as Types.ObjectId;
    } else if (options.subjectCode) {
      const sub = await Subject.findOne({
        collegeId: collegeObjectId,
        code: { $regex: new RegExp(`^${options.subjectCode.trim()}$`, 'i') },
      });
      if (sub) resolved.subjectId = sub._id as Types.ObjectId;
    }

    // 5. Faculty Assignment
    if (options.facultyAssignmentId) {
      const fa = await FacultyAssignment.findOne({
        _id: new Types.ObjectId(options.facultyAssignmentId),
        collegeId: collegeObjectId,
      });
      if (!fa) throw ApiError.badRequest(`FacultyAssignment '${options.facultyAssignmentId}' not found in college`);
      resolved.facultyAssignmentId = fa._id as Types.ObjectId;
    }

    return resolved;
  }

  /**
   * Prepares batched in-memory lookup maps for resolving students against the active section enrollment roster.
   */
  static async prepareStudentResolutionContext(
    collegeId: Types.ObjectId,
    resolvedAcademicContext: IResolvedAcademicContext
  ) {
    const { academicYearId, semesterId, sectionId } = resolvedAcademicContext;

    // Filter for active enrollments in target section
    const targetFilter: any = {
      collegeId,
      status: 'active',
    };
    if (academicYearId) targetFilter.academicYearId = academicYearId;
    if (semesterId) targetFilter.semesterId = semesterId;
    if (sectionId) targetFilter.sectionId = sectionId;

    const targetEnrollments = await StudentEnrollment.find(targetFilter)
      .populate('studentId')
      .populate('sectionId', 'name')
      .lean();

    // Maps for target section
    const byEnrollmentId = new Map<string, any>();
    const byPin = new Map<string, any>();
    const byRollNumber = new Map<string, any>();
    const byAdmissionNumber = new Map<string, any>();
    const byStudentObjectId = new Map<string, any>();
    const byName = new Map<string, any[]>();

    for (const enr of targetEnrollments) {
      const s = enr.studentId as any;
      if (!s) continue;

      const enrId = enr._id.toString();
      byEnrollmentId.set(enrId, enr);

      const sId = s._id.toString();
      byStudentObjectId.set(sId, enr);

      if (s.instituteId) byPin.set(s.instituteId.trim().toUpperCase(), enr);
      if (s.rollNumber) byRollNumber.set(s.rollNumber.trim().toUpperCase(), enr);
      if ((enr as any).rollNumber) byRollNumber.set((enr as any).rollNumber.trim().toUpperCase(), enr);
      if (s.admissionNumber) byAdmissionNumber.set(s.admissionNumber.trim().toUpperCase(), enr);

      const nameKey = (s.name || '').trim().toLowerCase();
      if (nameKey) {
        if (!byName.has(nameKey)) byName.set(nameKey, []);
        byName.get(nameKey)!.push(enr);
      }
    }

    // Also build a broad college-level index to detect students enrolled in other sections
    const collegeStudents = await Student.find({ collegeId }, 'instituteId rollNumber admissionNumber name').lean();
    const collegeStudentMap = new Map<string, any>();

    for (const cs of collegeStudents) {
      if (cs.instituteId) collegeStudentMap.set(`PIN:${cs.instituteId.trim().toUpperCase()}`, cs);
      if (cs.rollNumber) collegeStudentMap.set(`ROLL:${cs.rollNumber.trim().toUpperCase()}`, cs);
      if (cs.admissionNumber) collegeStudentMap.set(`ADM:${cs.admissionNumber.trim().toUpperCase()}`, cs);
    }

    return {
      targetEnrollments,
      byEnrollmentId,
      byPin,
      byRollNumber,
      byAdmissionNumber,
      byStudentObjectId,
      byName,
      collegeStudentMap,
    };
  }

  /**
   * Resolves a single student row against the prepared context.
   */
  static resolveStudentRow(
    rowRaw: {
      studentPin?: string;
      rollNumber?: string;
      admissionNumber?: string;
      studentEnrollmentId?: string;
      studentId?: string;
      studentName?: string;
    },
    context: Awaited<ReturnType<typeof ContextResolutionService.prepareStudentResolutionContext>>
  ): IStudentResolutionResult {
    const {
      byEnrollmentId,
      byPin,
      byRollNumber,
      byAdmissionNumber,
      byStudentObjectId,
      byName,
      collegeStudentMap,
    } = context;

    // 1. StudentEnrollment ID (explicit & trusted)
    if (rowRaw.studentEnrollmentId) {
      const enr = byEnrollmentId.get(rowRaw.studentEnrollmentId.trim());
      if (enr) {
        const s = enr.studentId as any;
        return {
          status: RowValidationStatus.VALID,
          studentId: s._id.toString(),
          studentEnrollmentId: enr._id.toString(),
          studentName: s.name,
          studentPin: s.instituteId || s.rollNumber,
          rollNumber: enr.rollNumber || s.rollNumber,
          sectionName: (enr.sectionId as any)?.name || '',
        };
      }
      return {
        status: RowValidationStatus.INVALID,
        issueCode: ImportIssueCode.STUDENT_CONTEXT_MISMATCH,
        reason: `StudentEnrollment '${rowRaw.studentEnrollmentId}' does not belong to active section roster`,
      };
    }

    // 2. PIN / instituteId / Roll / Admission No
    const identifier = (rowRaw.studentPin || rowRaw.rollNumber || rowRaw.admissionNumber || '').trim().toUpperCase();

    if (identifier) {
      let matchedEnr =
        byPin.get(identifier) ||
        byRollNumber.get(identifier) ||
        byAdmissionNumber.get(identifier);

      if (matchedEnr) {
        const s = matchedEnr.studentId as any;
        return {
          status: RowValidationStatus.VALID,
          studentId: s._id.toString(),
          studentEnrollmentId: matchedEnr._id.toString(),
          studentName: s.name,
          studentPin: s.instituteId || s.rollNumber,
          rollNumber: matchedEnr.rollNumber || s.rollNumber,
          sectionName: (matchedEnr.sectionId as any)?.name || '',
        };
      }

      // Check if student exists in the college, but not in target section -> CONTEXT_MISMATCH
      const collegeMatch =
        collegeStudentMap.get(`PIN:${identifier}`) ||
        collegeStudentMap.get(`ROLL:${identifier}`) ||
        collegeStudentMap.get(`ADM:${identifier}`);

      if (collegeMatch) {
        return {
          status: RowValidationStatus.INVALID,
          issueCode: ImportIssueCode.STUDENT_CONTEXT_MISMATCH,
          reason: `Student '${identifier}' exists in college but is not enrolled in the selected academic section`,
        };
      }

      return {
        status: RowValidationStatus.INVALID,
        issueCode: ImportIssueCode.STUDENT_NOT_FOUND,
        reason: `No student found matching identifier '${identifier}'`,
      };
    }

    // 3. Student Object ID
    if (rowRaw.studentId) {
      const matchedEnr = byStudentObjectId.get(rowRaw.studentId.trim());
      if (matchedEnr) {
        const s = matchedEnr.studentId as any;
        return {
          status: RowValidationStatus.VALID,
          studentId: s._id.toString(),
          studentEnrollmentId: matchedEnr._id.toString(),
          studentName: s.name,
          studentPin: s.instituteId || s.rollNumber,
          rollNumber: matchedEnr.rollNumber || s.rollNumber,
        };
      }
      return {
        status: RowValidationStatus.INVALID,
        issueCode: ImportIssueCode.STUDENT_CONTEXT_MISMATCH,
        reason: `Student ID '${rowRaw.studentId}' not found in active section enrollment roster`,
      };
    }

    // 4. Name only (weak supporting signal)
    if (rowRaw.studentName) {
      const nameKey = rowRaw.studentName.trim().toLowerCase();
      const candidates = byName.get(nameKey) || [];

      if (candidates.length === 1) {
        const enr = candidates[0];
        const s = enr.studentId as any;
        return {
          status: RowValidationStatus.WARNING,
          studentId: s._id.toString(),
          studentEnrollmentId: enr._id.toString(),
          studentName: s.name,
          studentPin: s.instituteId || s.rollNumber,
          rollNumber: enr.rollNumber || s.rollNumber,
          reason: 'Resolved using name only. Consider verifying student identifier.',
        };
      } else if (candidates.length > 1) {
        return {
          status: RowValidationStatus.UNRESOLVED,
          issueCode: ImportIssueCode.STUDENT_AMBIGUOUS,
          reason: `Multiple (${candidates.length}) students match name '${rowRaw.studentName}'. Explicit PIN/Roll resolution required.`,
        };
      }

      return {
        status: RowValidationStatus.INVALID,
        issueCode: ImportIssueCode.STUDENT_NOT_FOUND,
        reason: `No student found with name '${rowRaw.studentName}' in selected section`,
      };
    }

    return {
      status: RowValidationStatus.INVALID,
      issueCode: ImportIssueCode.MISSING_REQUIRED_FIELD,
      reason: 'No student identifier (PIN, Roll Number, Admission No, or Name) provided',
    };
  }
}
