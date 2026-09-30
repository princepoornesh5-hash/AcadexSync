import { Types } from 'mongoose';
import { ApiError } from '../utils/apiError';
import {
  InternalAssessment,
  IInternalAssessment,
  AssessmentStatus,
  AssessmentType,
  StudentMarkStatus,
  IAssessmentComponent,
  IStudentAssessmentEntry,
  Section,
  Subject,
  StudentEnrollment,
  Student,
  LabExperiment,
} from '../models';
import { isValidAssessmentTransition } from '../constants/assessment.constants';
import { institutionConfigService } from './institutionConfig.service';
import { TeachingAuthorizationService, AuthUserContext } from './teachingAuthorization.service';
import { NotificationService } from './notification.service';
import {
  NotificationCategory,
  NotificationPriority,
  NotificationType,
} from '../constants/notification.constants';
import { AppRole } from '../constants/roles';
import { logger } from '../utils/logger';
import { realtimeEventBus, AcadexEventType } from '../realtime';

export interface SaveMarksPayload {
  assessmentId?: string;
  sectionId?: string;
  subjectId?: string;
  academicYearId?: string;
  title?: string;
  entries: Array<{
    studentId: string;
    studentName?: string;
    rollNumber?: string;
    admissionNumber?: string;
    componentMarks?: Record<string, number | null>;
    obtainedMarks?: number;
    totalMarks?: number;
    status?: StudentMarkStatus;
    remarks?: string;
  }>;
}

export interface CreateAssessmentPayload {
  departmentId: string;
  courseId: string;
  academicYearId: string;
  semesterId: string;
  sectionId?: string | null;
  subjectId: string;
  facultyAssignmentId?: string | null;
  title: string;
  assessmentType?: AssessmentType;
  maximumMarks: number;
  assessmentDate?: Date | string;
  components?: IAssessmentComponent[];
}

export interface CorrectMarkPayload {
  assessmentId?: string;
  sectionId?: string;
  subjectId?: string;
  studentId: string;
  componentKey?: string;
  newMark: number;
  status?: StudentMarkStatus;
  reason: string;
}

export class InternalAssessmentService {
  /**
   * Retrieves or initializes the assessment context for a given section and subject.
   */
  static async getAssessmentContext(
    collegeId: string,
    user: AuthUserContext,
    params: { sectionId: string; subjectId: string; academicYearId?: string }
  ) {
    const { sectionId, subjectId } = params;
    if (!Types.ObjectId.isValid(sectionId) || !Types.ObjectId.isValid(subjectId)) {
      throw ApiError.badRequest('Invalid section ID or subject ID format');
    }

    const roleUpper = (user.role || '').toUpperCase();
    const isStudent = roleUpper === 'STUDENT';

    // 1. Authorization check
    let faDoc = null;
    if (!isStudent) {
      faDoc = await TeachingAuthorizationService.assertSubjectSectionAccess(
        collegeId,
        user,
        subjectId,
        sectionId,
        'assessments for this teaching context'
      );
    }

    // 2. Fetch section & subject metadata
    const section = await Section.findOne({
      _id: new Types.ObjectId(sectionId),
      collegeId: new Types.ObjectId(collegeId),
    });
    if (!section) {
      throw ApiError.notFound('Section not found');
    }

    const subject = await Subject.findOne({
      _id: new Types.ObjectId(subjectId),
      collegeId: new Types.ObjectId(collegeId),
    });
    if (!subject) {
      throw ApiError.notFound('Subject not found');
    }

    // 3. Load effective institution assessment configuration
    const config = await institutionConfigService.getEffectiveConfiguration(collegeId);
    const assessmentConfig = config.assessmentConfig;

    // Filter components applicable to this subject type
    const subjectTypeLower = (subject.type || 'theory').toLowerCase();
    const isPracticalSubject =
      subjectTypeLower.includes('lab') ||
      subjectTypeLower.includes('practical') ||
      subjectTypeLower.includes('integrated');

    const applicableComponents: IAssessmentComponent[] = (assessmentConfig.components || [])
      .filter((c: any) => {
        if (!c.enabled) return false;
        if (c.appliesTo === 'all') return true;
        if (c.appliesTo === 'practical' && isPracticalSubject) return true;
        if (c.appliesTo === 'theory' && !isPracticalSubject) return true;
        return false;
      })
      .map((c: any) => ({
        key: c.key,
        name: c.name,
        maxMarks: c.maxMarks,
        weightage: c.weightage,
        isStudentVisible: c.visibleToStudents !== false,
      }));

    // Fallback if no components configured
    if (applicableComponents.length === 0) {
      applicableComponents.push(
        { key: 'test1', name: 'Internal Test 1', maxMarks: 25, weightage: 30, isStudentVisible: true },
        { key: 'test2', name: 'Internal Test 2', maxMarks: 25, weightage: 30, isStudentVisible: true },
        { key: 'assignment', name: 'Assignment', maxMarks: 10, weightage: 20, isStudentVisible: true }
      );
    }

    // Compute default maximum marks from components
    const defaultMaxMarks = applicableComponents.reduce((acc, c) => acc + (c.maxMarks || 0), 0);

    // 4. Fetch or initialize InternalAssessment record
    let assessment = await InternalAssessment.findOne({
      collegeId: new Types.ObjectId(collegeId),
      sectionId: new Types.ObjectId(sectionId),
      subjectId: new Types.ObjectId(subjectId),
    });

    // 5. Fetch enrolled students
    let enrolledStudents: Array<{
      id: string;
      name: string;
      rollNumber?: string;
      admissionNumber?: string;
      userId?: string;
    }> = [];

    const enrollments = await StudentEnrollment.find({
      collegeId: new Types.ObjectId(collegeId),
      sectionId: new Types.ObjectId(sectionId),
      status: 'active',
    }).populate('studentId');

    if (enrollments.length > 0) {
      enrolledStudents = enrollments
        .filter((e) => e.studentId != null)
        .map((e) => {
          const s = e.studentId as any;
          return {
            id: s._id ? s._id.toString() : s.id,
            name: s.name || 'Student',
            rollNumber: s.rollNumber || undefined,
            admissionNumber: s.admissionNumber || undefined,
            userId: s.userId ? s.userId.toString() : undefined,
          };
        });
    } else {
      // Fallback to direct sectionId on Student model
      const directStudents = await Student.find({
        collegeId: new Types.ObjectId(collegeId),
        sectionId: new Types.ObjectId(sectionId),
        isActive: true,
      });
      enrolledStudents = directStudents.map((s) => ({
        id: s._id.toString(),
        name: s.name,
        rollNumber: s.rollNumber || undefined,
        admissionNumber: s.admissionNumber || undefined,
        userId: s.userId ? s.userId.toString() : undefined,
      }));
    }

    // Sort students deterministically by rollNumber or name
    enrolledStudents.sort((a, b) => {
      if (a.rollNumber && b.rollNumber) {
        return a.rollNumber.localeCompare(b.rollNumber, undefined, { numeric: true });
      }
      return a.name.localeCompare(b.name);
    });

    // If assessment does not exist yet and user is faculty/admin, prepare initial draft structure
    if (!assessment) {
      const initialEntries: IStudentAssessmentEntry[] = enrolledStudents.map((s) => {
        const componentMarks: Record<string, number | null> = {};
        for (const comp of applicableComponents) {
          componentMarks[comp.key] = null;
        }
        return {
          studentId: new Types.ObjectId(s.id),
          studentName: s.name,
          rollNumber: s.rollNumber,
          admissionNumber: s.admissionNumber,
          componentMarks,
          totalMarks: 0,
          status: StudentMarkStatus.NOT_ENTERED,
        };
      });

      if (!isStudent) {
        assessment = await InternalAssessment.create({
          collegeId: new Types.ObjectId(collegeId),
          departmentId: section.departmentId,
          courseId: section.courseId,
          academicYearId: section.academicYearId || params.academicYearId,
          semesterId: section.semesterId,
          sectionId: section._id,
          subjectId: subject._id,
          facultyAssignmentId: faDoc?._id || null,
          facultyId: faDoc?.facultyId || null,
          facultyName: faDoc?.facultyName || user.name || 'Faculty',
          title: `${subject.name} - Internal Assessment`,
          assessmentType: AssessmentType.INTERNAL_EXAM,
          maximumMarks: defaultMaxMarks,
          components: applicableComponents,
          entries: initialEntries,
          status: AssessmentStatus.DRAFT,
          auditLog: [
            {
              action: 'INITIALIZED',
              performedBy: new Types.ObjectId(user.id),
              performedByName: user.name || 'User',
              performedByRole: user.role || 'FACULTY',
              timestamp: new Date(),
              details: 'Assessment roster initialized from active student enrollments',
            },
          ],
        });
      }
    } else {
      // Synchronize enrolled students with existing entries (preserve existing marks)
      const existingEntriesMap = new Map<string, IStudentAssessmentEntry>();
      for (const entry of assessment.entries) {
        existingEntriesMap.set(entry.studentId.toString(), entry);
      }

      let updated = false;
      const syncedEntries: IStudentAssessmentEntry[] = [];
      for (const s of enrolledStudents) {
        const existing = existingEntriesMap.get(s.id);
        if (existing) {
          // Ensure all current components have a key in componentMarks
          for (const comp of applicableComponents) {
            if (existing.componentMarks[comp.key] === undefined) {
              existing.componentMarks[comp.key] = null;
              updated = true;
            }
          }
          existing.studentName = s.name;
          if (s.rollNumber) existing.rollNumber = s.rollNumber;
          if (!existing.status) {
            existing.status = StudentMarkStatus.NOT_ENTERED;
          }
          syncedEntries.push(existing);
        } else {
          // New student enrolled
          const componentMarks: Record<string, number | null> = {};
          for (const comp of applicableComponents) {
            componentMarks[comp.key] = null;
          }
          syncedEntries.push({
            studentId: new Types.ObjectId(s.id),
            studentName: s.name,
            rollNumber: s.rollNumber,
            admissionNumber: s.admissionNumber,
            componentMarks,
            totalMarks: 0,
            status: StudentMarkStatus.NOT_ENTERED,
          });
          updated = true;
        }
      }

      if (updated && assessment.status !== AssessmentStatus.PUBLISHED) {
        assessment.entries = syncedEntries;
        assessment.components = applicableComponents;
        if (!assessment.maximumMarks || assessment.maximumMarks === 0) {
          assessment.maximumMarks = defaultMaxMarks;
        }
        await assessment.save();
      }
    }

    // 6. Student View Security:
    if (isStudent) {
      if (!assessment || assessment.status !== AssessmentStatus.PUBLISHED) {
        return {
          isPublished: false,
          status: assessment ? assessment.status : AssessmentStatus.DRAFT,
          subject: { id: subject._id.toString(), name: subject.name, code: subject.code, type: subject.type },
          section: { id: section._id.toString(), name: section.name },
          message: 'Internal assessment marks are not yet published for this subject.',
          components: [],
          entry: null,
        };
      }

      // Find the student's entry
      const studentProfile = await Student.findOne({
        collegeId: new Types.ObjectId(collegeId),
        userId: new Types.ObjectId(user.id),
      });

      const studentDocId = studentProfile ? studentProfile._id.toString() : user.id;
      const studentEntry = assessment.entries.find(
        (e) => e.studentId.toString() === studentDocId
      );

      // Filter visible components
      const visibleComponents = assessment.components.filter((c) => c.isStudentVisible);
      const filteredMarks: Record<string, number | null> = {};
      if (studentEntry) {
        for (const comp of visibleComponents) {
          filteredMarks[comp.key] = studentEntry.componentMarks[comp.key] ?? null;
        }
      }

      return {
        isPublished: true,
        status: assessment.status,
        subject: { id: subject._id.toString(), name: subject.name, code: subject.code, type: subject.type },
        section: { id: section._id.toString(), name: section.name },
        components: visibleComponents,
        entry: studentEntry
          ? {
              studentName: studentEntry.studentName,
              rollNumber: studentEntry.rollNumber,
              marks: filteredMarks,
              totalMarks: studentEntry.totalMarks,
              status: studentEntry.status || StudentMarkStatus.ENTERED,
              remarks: studentEntry.remarks,
            }
          : null,
      };
    }

    // 7. Faculty / Admin View
    return {
      assessment,
      subject: {
        id: subject._id.toString(),
        name: subject.name,
        code: subject.code,
        type: subject.type,
        credits: subject.credits,
      },
      section: {
        id: section._id.toString(),
        name: section.name,
        capacity: section.capacity,
      },
      facultyAssignment: faDoc ? { id: faDoc._id.toString(), facultyName: faDoc.facultyName } : null,
      components: assessment?.components || applicableComponents,
      isLocked: assessment?.status === AssessmentStatus.PUBLISHED || assessment?.status === AssessmentStatus.CLOSED,
      gradingConfig: (assessmentConfig as any)?.gradingScale || null,
    };
  }

  /**
   * Creates an explicit Internal Assessment record.
   */
  static async createAssessment(
    collegeId: string,
    user: AuthUserContext,
    payload: CreateAssessmentPayload
  ) {
    const {
      departmentId,
      courseId,
      academicYearId,
      semesterId,
      sectionId,
      subjectId,
      facultyAssignmentId,
      title,
      assessmentType,
      maximumMarks,
      assessmentDate,
      components,
    } = payload;

    // Teaching authorization
    let faDoc = null;
    if (sectionId) {
      faDoc = await TeachingAuthorizationService.assertSubjectSectionAccess(
        collegeId,
        user,
        subjectId,
        sectionId,
        'assessments for this teaching context'
      );
    }

    // Enrolled students roster
    const query: any = {
      collegeId: new Types.ObjectId(collegeId),
      semesterId: new Types.ObjectId(semesterId),
      status: 'active',
    };
    if (sectionId) {
      query.sectionId = new Types.ObjectId(sectionId);
    }

    const enrollments = await StudentEnrollment.find(query).populate('studentId');
    const initialEntries: IStudentAssessmentEntry[] = enrollments
      .filter((e) => e.studentId != null)
      .map((e) => {
        const s = e.studentId as any;
        return {
          studentId: new Types.ObjectId(s._id ? s._id.toString() : s.id),
          studentName: s.name || 'Student',
          rollNumber: s.rollNumber || undefined,
          admissionNumber: s.admissionNumber || undefined,
          componentMarks: {},
          totalMarks: 0,
          status: StudentMarkStatus.NOT_ENTERED,
        };
      });

    const assessment = await InternalAssessment.create({
      collegeId: new Types.ObjectId(collegeId),
      departmentId: new Types.ObjectId(departmentId),
      courseId: new Types.ObjectId(courseId),
      academicYearId: new Types.ObjectId(academicYearId),
      semesterId: new Types.ObjectId(semesterId),
      sectionId: sectionId ? new Types.ObjectId(sectionId) : null,
      subjectId: new Types.ObjectId(subjectId),
      facultyAssignmentId: facultyAssignmentId ? new Types.ObjectId(facultyAssignmentId) : faDoc?._id || null,
      facultyId: faDoc?.facultyId || null,
      facultyName: faDoc?.facultyName || user.name || 'Faculty',
      title: title.trim(),
      assessmentType: assessmentType || AssessmentType.INTERNAL_EXAM,
      maximumMarks,
      assessmentDate: assessmentDate ? new Date(assessmentDate) : undefined,
      components: components || [],
      entries: initialEntries,
      status: AssessmentStatus.DRAFT,
      auditLog: [
        {
          action: 'CREATED',
          performedBy: new Types.ObjectId(user.id),
          performedByName: user.name || 'User',
          performedByRole: user.role || 'FACULTY',
          timestamp: new Date(),
          details: `Assessment '${title}' created in DRAFT status`,
        },
      ],
    });

    realtimeEventBus.publish({
      eventId: new Types.ObjectId().toString(),
      eventVersion: 1,
      eventType: AcadexEventType.ASSESSMENT_CREATED,
      aggregateType: 'InternalAssessment',
      aggregateId: assessment._id.toString(),
      action: 'CREATED',
      occurredAt: new Date().toISOString(),
      collegeId,
      scope: {
        type: 'department',
        collegeId,
        departmentId,
      },
      payload: {
        assessmentId: assessment._id.toString(),
        subjectId,
        sectionId,
        title: assessment.title,
        status: assessment.status,
      },
    });

    return assessment;
  }

  /**
   * Opens an assessment for mark entry (DRAFT -> OPEN).
   */
  static async openAssessment(
    collegeId: string,
    user: AuthUserContext,
    params: { assessmentId?: string; sectionId?: string; subjectId?: string }
  ) {
    const assessment = await this.resolveAssessment(collegeId, params);
    if (!assessment) throw ApiError.notFound('Assessment not found');

    if (assessment.sectionId) {
      await TeachingAuthorizationService.assertSubjectSectionAccess(
        collegeId,
        user,
        assessment.subjectId,
        assessment.sectionId,
        'assessments for this teaching context'
      );
    }

    if (!isValidAssessmentTransition(assessment.status, AssessmentStatus.OPEN)) {
      throw ApiError.badRequest(
        `Cannot open assessment in '${assessment.status}' status. Allowed transitions are strictly enforced.`
      );
    }

    assessment.status = AssessmentStatus.OPEN;
    assessment.auditLog.push({
      action: 'OPENED',
      performedBy: new Types.ObjectId(user.id),
      performedByName: user.name || 'User',
      performedByRole: user.role || 'FACULTY',
      timestamp: new Date(),
      details: 'Assessment opened for marks entry',
    });

    await assessment.save();

    realtimeEventBus.publish({
      eventId: new Types.ObjectId().toString(),
      eventVersion: 1,
      eventType: AcadexEventType.ASSESSMENT_OPENED,
      aggregateType: 'InternalAssessment',
      aggregateId: assessment._id.toString(),
      action: 'OPENED',
      occurredAt: new Date().toISOString(),
      collegeId,
      scope: {
        type: 'department',
        collegeId,
        departmentId: assessment.departmentId.toString(),
      },
      payload: {
        assessmentId: assessment._id.toString(),
        subjectId: assessment.subjectId.toString(),
        sectionId: assessment.sectionId?.toString(),
        status: assessment.status,
      },
    });

    return assessment;
  }

  /**
   * Closes an assessment to lock mark entries prior to publication (OPEN -> CLOSED).
   */
  static async closeAssessment(
    collegeId: string,
    user: AuthUserContext,
    params: { assessmentId?: string; sectionId?: string; subjectId?: string }
  ) {
    const assessment = await this.resolveAssessment(collegeId, params);
    if (!assessment) throw ApiError.notFound('Assessment not found');

    if (assessment.sectionId) {
      await TeachingAuthorizationService.assertSubjectSectionAccess(
        collegeId,
        user,
        assessment.subjectId,
        assessment.sectionId,
        'assessments for this teaching context'
      );
    }

    if (!isValidAssessmentTransition(assessment.status, AssessmentStatus.CLOSED)) {
      throw ApiError.badRequest(
        `Cannot close assessment in '${assessment.status}' status.`
      );
    }

    assessment.status = AssessmentStatus.CLOSED;
    assessment.lockedAt = new Date();
    assessment.lockedBy = new Types.ObjectId(user.id);
    assessment.auditLog.push({
      action: 'CLOSED',
      performedBy: new Types.ObjectId(user.id),
      performedByName: user.name || 'User',
      performedByRole: user.role || 'FACULTY',
      timestamp: new Date(),
      details: 'Assessment closed and locked for review',
    });

    await assessment.save();

    realtimeEventBus.publish({
      eventId: new Types.ObjectId().toString(),
      eventVersion: 1,
      eventType: AcadexEventType.ASSESSMENT_CLOSED,
      aggregateType: 'InternalAssessment',
      aggregateId: assessment._id.toString(),
      action: 'CLOSED',
      occurredAt: new Date().toISOString(),
      collegeId,
      scope: {
        type: 'department',
        collegeId,
        departmentId: assessment.departmentId.toString(),
      },
      payload: {
        assessmentId: assessment._id.toString(),
        subjectId: assessment.subjectId.toString(),
        sectionId: assessment.sectionId?.toString(),
        status: assessment.status,
      },
    });

    return assessment;
  }

  /**
   * Saves or updates marks in DRAFT or OPEN state (single or bulk entry).
   */
  static async saveDraftMarks(
    collegeId: string,
    user: AuthUserContext,
    payload: SaveMarksPayload
  ) {
    const { sectionId, subjectId, entries, title, assessmentId } = payload;

    // 1. Authorize teaching context
    let faDoc = null;
    if (sectionId && subjectId) {
      if (!Types.ObjectId.isValid(sectionId) || !Types.ObjectId.isValid(subjectId)) {
        throw ApiError.badRequest('Invalid section ID or subject ID');
      }
      faDoc = await TeachingAuthorizationService.assertSubjectSectionAccess(
        collegeId,
        user,
        subjectId,
        sectionId,
        'assessments for this teaching context'
      );
    }

    // 2. Fetch assessment
    let assessment = await this.resolveAssessment(collegeId, { assessmentId, sectionId, subjectId });

    if (assessment && assessment.status === AssessmentStatus.PUBLISHED) {
      const roleUpper = (user.role || '').toUpperCase();
      if (roleUpper !== 'SUPER_ADMIN' && roleUpper !== 'COLLEGE_ADMIN') {
        throw ApiError.forbidden(
          'Assessment marks have been published and locked. Contact your HOD or Administrator to unlock for revisions.'
        );
      }
    }

    if (assessment && assessment.status === AssessmentStatus.CLOSED) {
      const roleUpper = (user.role || '').toUpperCase();
      if (roleUpper !== 'SUPER_ADMIN' && roleUpper !== 'COLLEGE_ADMIN' && roleUpper !== 'HOD') {
        throw ApiError.badRequest(
          'Assessment is closed. You must re-open it to make changes.'
        );
      }
    }

    // 3. Resolve components and maximum marks
    const componentMap = new Map<string, IAssessmentComponent>();
    if (assessment && assessment.components && assessment.components.length > 0) {
      for (const comp of assessment.components) {
        componentMap.set(comp.key, comp);
      }
    } else {
      const config = await institutionConfigService.getEffectiveConfiguration(collegeId);
      const subject = await Subject.findById(subjectId);
      const subjectTypeLower = (subject?.type || 'theory').toLowerCase();
      const isPracticalSubject =
        subjectTypeLower.includes('lab') ||
        subjectTypeLower.includes('practical') ||
        subjectTypeLower.includes('integrated');

      for (const c of config.assessmentConfig?.components || []) {
        if (!c.enabled) continue;
        if (c.appliesTo === 'all') componentMap.set(c.key, c);
        else if (c.appliesTo === 'practical' && isPracticalSubject) componentMap.set(c.key, c);
        else if (c.appliesTo === 'theory' && !isPracticalSubject) componentMap.set(c.key, c);
      }
    }

    // Verify eligible students in this college
    const studentIds = entries.map((e) => e.studentId);
    const validStudents = await Student.find({
      _id: { $in: studentIds.map((id) => new Types.ObjectId(id)) },
      collegeId: new Types.ObjectId(collegeId),
    }).select('_id name rollNumber admissionNumber sectionId');

    const validStudentMap = new Map<string, any>();
    for (const vs of validStudents) {
      validStudentMap.set(vs._id.toString(), vs);
    }

    // 4. Validate and compute marks for each entry
    const validatedEntries: IStudentAssessmentEntry[] = [];
    for (const item of entries) {
      if (!Types.ObjectId.isValid(item.studentId)) {
        throw ApiError.badRequest(`Invalid student ID format: ${item.studentId}`);
      }

      const verifiedStudent = validStudentMap.get(item.studentId.toString());
      if (!verifiedStudent) {
        throw ApiError.badRequest(`Student '${item.studentId}' is not eligible for this college/assessment context.`);
      }

      const markStatus = item.status || StudentMarkStatus.ENTERED;
      let studentTotal = 0;
      const cleanMarks: Record<string, number | null> = {};

      // Preserve Absent / Excused semantics
      if (markStatus === StudentMarkStatus.ABSENT) {
        for (const [key] of Object.entries(item.componentMarks || {})) {
          cleanMarks[key] = null;
        }
        validatedEntries.push({
          studentId: new Types.ObjectId(item.studentId),
          studentName: item.studentName || verifiedStudent.name || 'Student',
          rollNumber: item.rollNumber || verifiedStudent.rollNumber,
          admissionNumber: item.admissionNumber || verifiedStudent.admissionNumber,
          componentMarks: cleanMarks,
          totalMarks: 0,
          status: StudentMarkStatus.ABSENT,
          remarks: item.remarks || 'Absent for assessment',
        });
        continue;
      }

      if (markStatus === StudentMarkStatus.EXCUSED) {
        for (const [key] of Object.entries(item.componentMarks || {})) {
          cleanMarks[key] = null;
        }
        validatedEntries.push({
          studentId: new Types.ObjectId(item.studentId),
          studentName: item.studentName || verifiedStudent.name || 'Student',
          rollNumber: item.rollNumber || verifiedStudent.rollNumber,
          admissionNumber: item.admissionNumber || verifiedStudent.admissionNumber,
          componentMarks: cleanMarks,
          totalMarks: 0,
          status: StudentMarkStatus.EXCUSED,
          remarks: item.remarks || 'Excused from assessment',
        });
        continue;
      }

      // Check numeric marks
      for (const [key, rawMark] of Object.entries(item.componentMarks || {})) {
        if (rawMark === null || rawMark === undefined || rawMark === ('' as any)) {
          cleanMarks[key] = null;
          continue;
        }

        const markNum = Number(rawMark);
        if (isNaN(markNum) || markNum < 0) {
          throw ApiError.badRequest(`Marks for component '${key}' cannot be negative or non-numeric.`);
        }

        let comp = componentMap.get(key);
        if (!comp) {
          if (key === 'test1' || key === 'test2') {
            comp = {
              key,
              name: key === 'test1' ? 'Internal Test 1' : 'Internal Test 2',
              maxMarks: 25,
              weightage: 30,
              isStudentVisible: true,
            };
            componentMap.set(key, comp);
          } else {
            throw ApiError.badRequest(`Component '${key}' is not valid for this assessment.`);
          }
        }
        if (markNum > comp.maxMarks) {
          throw ApiError.badRequest(
            `Marks (${markNum}) for '${comp.name}' cannot exceed maximum allowed (${comp.maxMarks}).`
          );
        }

        // Preserve decimal precision (e.g. 37.5)
        cleanMarks[key] = Math.round(markNum * 100) / 100;
        studentTotal += cleanMarks[key]!;
      }

      // If item has a direct obtainedMarks or totalMarks provided, preserve precision
      let computedTotal = Math.round(studentTotal * 100) / 100;
      if (item.obtainedMarks !== undefined && Object.keys(cleanMarks).length === 0) {
        computedTotal = Math.round(item.obtainedMarks * 100) / 100;
      }

      const hasEnteredMarks = Object.values(cleanMarks).some((v) => v !== null) || item.obtainedMarks !== undefined;

      validatedEntries.push({
        studentId: new Types.ObjectId(item.studentId),
        studentName: item.studentName || verifiedStudent.name || 'Student',
        rollNumber: item.rollNumber || verifiedStudent.rollNumber,
        admissionNumber: item.admissionNumber || verifiedStudent.admissionNumber,
        componentMarks: cleanMarks,
        totalMarks: computedTotal,
        status: hasEnteredMarks ? StudentMarkStatus.ENTERED : (item.status || StudentMarkStatus.NOT_ENTERED),
        remarks: item.remarks || undefined,
      });
    }

    // 5. Update or create document
    if (!assessment) {
      if (!sectionId || !subjectId) {
        throw ApiError.badRequest('sectionId and subjectId are required to create a new assessment');
      }
      const section = await Section.findById(sectionId);
      const subject = await Subject.findById(subjectId);
      if (!section || !subject) throw ApiError.notFound('Section or Subject not found');

      const maxMarks = Array.from(componentMap.values()).reduce((sum, c) => sum + (c.maxMarks || 0), 0);

      assessment = await InternalAssessment.create({
        collegeId: new Types.ObjectId(collegeId),
        departmentId: section.departmentId,
        courseId: section.courseId,
        academicYearId: section.academicYearId || payload.academicYearId,
        semesterId: section.semesterId,
        sectionId: section._id,
        subjectId: subject._id,
        facultyAssignmentId: faDoc?._id || null,
        facultyId: faDoc?.facultyId || null,
        facultyName: faDoc?.facultyName || user.name || 'Faculty',
        title: title || `${subject.name} - Internal Assessment`,
        assessmentType: AssessmentType.INTERNAL_EXAM,
        maximumMarks: maxMarks,
        components: Array.from(componentMap.values()),
        entries: validatedEntries,
        status: AssessmentStatus.DRAFT,
        auditLog: [
          {
            action: 'CREATED_DRAFT',
            performedBy: new Types.ObjectId(user.id),
            performedByName: user.name || 'User',
            performedByRole: user.role || 'FACULTY',
            timestamp: new Date(),
            details: `Initial marks draft saved for ${validatedEntries.length} students`,
          },
        ],
      });
    } else {
      if (title) assessment.title = title;
      // Merge entries idempotently
      const existingEntriesMap = new Map<string, IStudentAssessmentEntry>();
      for (const entry of assessment.entries) {
        existingEntriesMap.set(entry.studentId.toString(), entry);
      }
      for (const validEntry of validatedEntries) {
        existingEntriesMap.set(validEntry.studentId.toString(), validEntry);
      }
      assessment.entries = Array.from(existingEntriesMap.values());

      assessment.auditLog.push({
        action: 'UPDATED_DRAFT',
        performedBy: new Types.ObjectId(user.id),
        performedByName: user.name || 'User',
        performedByRole: user.role || 'FACULTY',
        timestamp: new Date(),
        details: `Updated marks draft for ${validatedEntries.length} students`,
      });
      assessment.markModified('entries');
      await assessment.save();
    }

    realtimeEventBus.publish({
      eventId: new Types.ObjectId().toString(),
      eventVersion: 1,
      eventType: AcadexEventType.ASSESSMENT_UPDATED,
      aggregateType: 'InternalAssessment',
      aggregateId: assessment._id.toString(),
      action: 'UPDATED',
      occurredAt: new Date().toISOString(),
      collegeId,
      scope: {
        type: 'department',
        collegeId,
        departmentId: assessment.departmentId.toString(),
      },
      payload: {
        assessmentId: assessment._id.toString(),
        subjectId: assessment.subjectId.toString(),
        sectionId: assessment.sectionId?.toString(),
        updatedCount: validatedEntries.length,
      },
    });

    return assessment;
  }

  /**
   * Bulk saves marks (alias with identical safety guarantees).
   */
  static async bulkSaveMarks(
    collegeId: string,
    user: AuthUserContext,
    payload: SaveMarksPayload
  ) {
    return this.saveDraftMarks(collegeId, user, payload);
  }

  /**
   * Controlled Mark Correction Workflow for published/closed assessments.
   */
  static async correctStudentMark(
    collegeId: string,
    user: AuthUserContext,
    payload: CorrectMarkPayload
  ) {
    const { assessmentId, sectionId, subjectId, studentId, componentKey, newMark, status, reason } = payload;

    if (!reason || reason.trim().length < 5) {
      throw ApiError.badRequest('Correction reason must be at least 5 characters long.');
    }

    const assessment = await this.resolveAssessment(collegeId, { assessmentId, sectionId, subjectId });
    if (!assessment) throw ApiError.notFound('Assessment not found');

    // Only Admin, HOD, or assigned Faculty can correct marks
    if (assessment.sectionId) {
      await TeachingAuthorizationService.assertSubjectSectionAccess(
        collegeId,
        user,
        assessment.subjectId,
        assessment.sectionId,
        'assessments for this teaching context'
      );
    }

    const entry = assessment.entries.find((e) => e.studentId.toString() === studentId);
    if (!entry) {
      throw ApiError.notFound(`Student mark entry not found in assessment`);
    }

    // Range validation
    const compKey = componentKey || 'internalTest';
    const comp = assessment.components.find((c) => c.key === compKey);
    const maxAllowed = comp ? comp.maxMarks : assessment.maximumMarks || 100;

    if (newMark < 0 || newMark > maxAllowed) {
      throw ApiError.badRequest(
        `New mark (${newMark}) cannot be negative or exceed maximum allowed (${maxAllowed}).`
      );
    }

    const previousComponentMark = entry.componentMarks[compKey] ?? null;
    const previousTotal = entry.totalMarks;
    const previousStatus = entry.status;

    // Apply decimal precision
    const cleanNewMark = Math.round(newMark * 100) / 100;
    entry.componentMarks[compKey] = cleanNewMark;

    // Recalculate total marks
    let total = 0;
    for (const m of Object.values(entry.componentMarks)) {
      if (typeof m === 'number') total += m;
    }
    entry.totalMarks = Math.round(total * 100) / 100;
    if (status) {
      entry.status = status;
    } else {
      entry.status = StudentMarkStatus.ENTERED;
    }

    // Audit trail for correction
    assessment.auditLog.push({
      action: 'MARK_CORRECTED',
      performedBy: new Types.ObjectId(user.id),
      performedByName: user.name || 'User',
      performedByRole: user.role,
      timestamp: new Date(),
      details: `Corrected mark for student ${entry.studentName} (${entry.rollNumber || studentId}). Reason: ${reason.trim()}`,
      previousValue: {
        componentKey: compKey,
        mark: previousComponentMark,
        totalMarks: previousTotal,
        status: previousStatus,
      },
      newValue: {
        componentKey: compKey,
        mark: cleanNewMark,
        totalMarks: entry.totalMarks,
        status: entry.status,
      },
    });

    assessment.markModified('entries');
    await assessment.save();

    realtimeEventBus.publish({
      eventId: new Types.ObjectId().toString(),
      eventVersion: 1,
      eventType: AcadexEventType.ASSESSMENT_MARK_CORRECTED,
      aggregateType: 'InternalAssessment',
      aggregateId: assessment._id.toString(),
      action: 'UPDATED',
      occurredAt: new Date().toISOString(),
      collegeId,
      scope: {
        type: 'department',
        collegeId,
        departmentId: assessment.departmentId.toString(),
      },
      payload: {
        assessmentId: assessment._id.toString(),
        subjectId: assessment.subjectId.toString(),
        studentId,
        newMark: cleanNewMark,
        totalMarks: entry.totalMarks,
        reason: reason.trim(),
      },
    });

    return {
      message: 'Student mark successfully corrected and audited',
      entry,
      assessment,
    };
  }

  /**
   * Reviews and marks an assessment as REVIEWED.
   */
  static async reviewMarks(
    collegeId: string,
    user: AuthUserContext,
    params: { sectionId: string; subjectId: string; comments?: string; assessmentId?: string }
  ) {
    const assessment = await this.resolveAssessment(collegeId, params);
    if (!assessment) throw ApiError.notFound('Internal assessment record not found');

    if (assessment.sectionId) {
      await TeachingAuthorizationService.assertSubjectSectionAccess(
        collegeId,
        user,
        assessment.subjectId,
        assessment.sectionId,
        'assessments for this teaching context'
      );
    }

    if (assessment.status === AssessmentStatus.PUBLISHED) {
      throw ApiError.badRequest('Assessment has already been published.');
    }

    assessment.status = AssessmentStatus.REVIEWED;
    assessment.reviewedAt = new Date();
    assessment.reviewedBy = new Types.ObjectId(user.id);
    assessment.auditLog.push({
      action: 'REVIEWED',
      performedBy: new Types.ObjectId(user.id),
      performedByName: user.name || 'User',
      performedByRole: user.role || 'HOD',
      timestamp: new Date(),
      details: params.comments ? `Reviewed with comment: ${params.comments}` : 'Assessment reviewed',
    });

    await assessment.save();
    return assessment;
  }

  /**
   * Finalizes and PUBLISHES marks, locking them and making them visible to students.
   */
  static async publishMarks(
    collegeId: string,
    user: AuthUserContext,
    params: { sectionId?: string; subjectId?: string; assessmentId?: string }
  ) {
    const assessment = await this.resolveAssessment(collegeId, params);
    if (!assessment) throw ApiError.notFound('Internal assessment record not found');

    if (assessment.sectionId) {
      await TeachingAuthorizationService.assertSubjectSectionAccess(
        collegeId,
        user,
        assessment.subjectId,
        assessment.sectionId,
        'assessments for this teaching context'
      );
    }

    const config = await institutionConfigService.getEffectiveConfiguration(collegeId);
    if (config.assessmentConfig?.requireHodApproval) {
      const roleUpper = (user.role || '').toUpperCase();
      if (roleUpper !== 'SUPER_ADMIN' && roleUpper !== 'COLLEGE_ADMIN' && roleUpper !== 'HOD') {
        throw ApiError.forbidden(
          'Institution policy requires HOD approval before publishing internal marks.'
        );
      }
    }

    assessment.status = AssessmentStatus.PUBLISHED;
    assessment.publishedAt = new Date();
    assessment.publishedBy = new Types.ObjectId(user.id);
    assessment.lockedAt = new Date();
    assessment.lockedBy = new Types.ObjectId(user.id);
    assessment.auditLog.push({
      action: 'PUBLISHED',
      performedBy: new Types.ObjectId(user.id),
      performedByName: user.name || 'User',
      performedByRole: user.role || 'FACULTY',
      timestamp: new Date(),
      details: 'Assessment finalized, locked, and published to students',
    });

    await assessment.save();

    // Emit Realtime event
    realtimeEventBus.publish({
      eventId: new Types.ObjectId().toString(),
      eventVersion: 1,
      eventType: AcadexEventType.ASSESSMENT_PUBLISHED,
      aggregateType: 'InternalAssessment',
      aggregateId: assessment._id.toString(),
      action: 'PUBLISHED',
      occurredAt: new Date().toISOString(),
      collegeId,
      scope: {
        type: 'department',
        collegeId,
        departmentId: assessment.departmentId.toString(),
      },
      payload: {
        assessmentId: assessment._id.toString(),
        subjectId: assessment.subjectId.toString(),
        sectionId: assessment.sectionId?.toString(),
        title: assessment.title,
      },
    });

    // Trigger persistent notifications to enrolled students
    this.emitMarksPublishedNotification(assessment);

    return assessment;
  }

  /**
   * Archives an assessment.
   */
  static async archiveAssessment(
    collegeId: string,
    user: AuthUserContext,
    params: { assessmentId?: string; sectionId?: string; subjectId?: string }
  ) {
    const roleUpper = (user.role || '').toUpperCase();
    if (roleUpper !== 'SUPER_ADMIN' && roleUpper !== 'COLLEGE_ADMIN' && roleUpper !== 'HOD') {
      throw ApiError.forbidden('Only Administrators or HODs can archive historical assessments.');
    }

    const assessment = await this.resolveAssessment(collegeId, params);
    if (!assessment) throw ApiError.notFound('Assessment not found');

    assessment.status = AssessmentStatus.ARCHIVED;
    assessment.auditLog.push({
      action: 'ARCHIVED',
      performedBy: new Types.ObjectId(user.id),
      performedByName: user.name || 'User',
      performedByRole: user.role,
      timestamp: new Date(),
      details: 'Assessment moved to historical archived state',
    });

    await assessment.save();
    return assessment;
  }

  /**
   * Unlocks a published assessment for edits (Admin/HOD only).
   */
  static async unlockMarks(
    collegeId: string,
    user: AuthUserContext,
    params: { sectionId?: string; subjectId?: string; assessmentId?: string; reason: string }
  ) {
    const { reason } = params;
    if (!reason || reason.trim().length < 5) {
      throw ApiError.badRequest('A valid reason (at least 5 characters) is required to unlock published marks.');
    }

    const roleUpper = (user.role || '').toUpperCase();
    if (roleUpper !== 'SUPER_ADMIN' && roleUpper !== 'COLLEGE_ADMIN' && roleUpper !== 'HOD') {
      throw ApiError.forbidden('Only College Administrators or HODs can unlock published assessment marks.');
    }

    const assessment = await this.resolveAssessment(collegeId, params);
    if (!assessment) throw ApiError.notFound('Internal assessment record not found');

    assessment.status = AssessmentStatus.DRAFT;
    assessment.lockedAt = undefined;
    assessment.lockedBy = undefined;
    assessment.auditLog.push({
      action: 'UNLOCKED',
      performedBy: new Types.ObjectId(user.id),
      performedByName: user.name || 'User',
      performedByRole: user.role,
      timestamp: new Date(),
      details: `Unlocked for revision. Reason: ${reason.trim()}`,
    });

    await assessment.save();
    return assessment;
  }

  /**
   * Calculates subject-level assessment summaries for integration with AcademicRecord / SubjectAcademicRecord.
   */
  static async getSubjectAssessmentSummary(
    collegeId: string,
    params: { subjectId: string; semesterId: string; studentId?: string }
  ) {
    const { subjectId, semesterId, studentId } = params;

    const assessments = await InternalAssessment.find({
      collegeId: new Types.ObjectId(collegeId),
      subjectId: new Types.ObjectId(subjectId),
      semesterId: new Types.ObjectId(semesterId),
      status: AssessmentStatus.PUBLISHED,
    });

    let totalMaxMarks = 0;
    let totalObtainedMarks = 0;
    const items: Array<{
      assessmentId: string;
      title: string;
      type: AssessmentType;
      maxMarks: number;
      obtainedMarks?: number;
      status?: StudentMarkStatus;
    }> = [];

    for (const a of assessments) {
      totalMaxMarks += a.maximumMarks || 0;
      let obtained: number | undefined = undefined;
      let markStatus: StudentMarkStatus | undefined = undefined;

      if (studentId) {
        const studentEntry = a.entries.find((e) => e.studentId.toString() === studentId);
        if (studentEntry) {
          obtained = studentEntry.totalMarks || 0;
          markStatus = studentEntry.status || StudentMarkStatus.ENTERED;
          if (markStatus !== StudentMarkStatus.ABSENT && markStatus !== StudentMarkStatus.EXCUSED) {
            totalObtainedMarks += obtained;
          }
        }
      }

      items.push({
        assessmentId: a._id.toString(),
        title: a.title,
        type: a.assessmentType,
        maxMarks: a.maximumMarks,
        obtainedMarks: obtained,
        status: markStatus,
      });
    }

    const percentage = totalMaxMarks > 0
      ? Math.round((totalObtainedMarks / totalMaxMarks) * 1000) / 10
      : 0;

    return {
      subjectId,
      semesterId,
      studentId,
      totalAssessments: assessments.length,
      publishedAssessments: assessments.length,
      totalMaxMarks,
      totalObtainedMarks: Math.round(totalObtainedMarks * 100) / 100,
      percentage,
      assessments: items,
    };
  }

  /**
   * Retrieves all published marks for an enrolled student across subjects.
   */
  static async getStudentAllMarks(
    collegeId: string,
    user: AuthUserContext,
    params?: { semesterId?: string }
  ) {
    const student = await Student.findOne({
      collegeId: new Types.ObjectId(collegeId),
      userId: new Types.ObjectId(user.id),
    });

    if (!student) {
      return { items: [], message: 'Student profile not linked' };
    }

    const filter: Record<string, any> = {
      collegeId: new Types.ObjectId(collegeId),
      status: AssessmentStatus.PUBLISHED,
      'entries.studentId': student._id,
    };

    if (params?.semesterId && Types.ObjectId.isValid(params.semesterId)) {
      filter.semesterId = new Types.ObjectId(params.semesterId);
    } else {
      const activeEnrollment = await StudentEnrollment.findOne({
        studentId: student._id,
        status: 'active',
      }).sort({ createdAt: -1 });
      if (activeEnrollment?.semesterId) {
        filter.semesterId = activeEnrollment.semesterId;
      } else if (student.semesterId) {
        filter.semesterId = student.semesterId;
      }
    }

    const assessments = await InternalAssessment.find(filter)
      .populate('subjectId', 'name code credits type')
      .populate('sectionId', 'name')
      .populate('semesterId', 'number');

    const results = assessments.map((a) => {
      const entry = a.entries.find((e) => e.studentId.toString() === student._id.toString());
      const visibleComponents = a.components.filter((c) => c.isStudentVisible);
      const marksMap: Record<string, number | null> = {};
      if (entry) {
        for (const comp of visibleComponents) {
          marksMap[comp.key] = entry.componentMarks[comp.key] ?? null;
        }
      }

      return {
        id: a._id.toString(),
        subject: a.subjectId,
        section: a.sectionId,
        semester: a.semesterId,
        publishedAt: a.publishedAt,
        components: visibleComponents,
        marks: marksMap,
        totalMarks: entry?.totalMarks || 0,
        status: entry?.status || StudentMarkStatus.ENTERED,
        remarks: entry?.remarks,
      };
    });

    return { items: results };
  }

  /**
   * Helper: sync lab experiments and record book scores into InternalAssessment
   */
  static async syncLabScoresToAssessment(
    collegeId: string,
    user: AuthUserContext,
    params: { sectionId: string; subjectId: string }
  ) {
    const { sectionId, subjectId } = params;
    await TeachingAuthorizationService.assertSubjectSectionAccess(
      collegeId,
      user,
      subjectId,
      sectionId,
      'assessments for this teaching context'
    );

    const experiments = await LabExperiment.find({
      collegeId: new Types.ObjectId(collegeId),
      sectionId: new Types.ObjectId(sectionId),
      subjectId: new Types.ObjectId(subjectId),
    });

    if (experiments.length === 0) {
      return { message: 'No lab experiments found for this subject and section' };
    }

    // Aggregate average observation, record, and viva scores per student
    const studentAggregates = new Map<
      string,
      { obsTotal: number; recTotal: number; vivaTotal: number; count: number }
    >();

    for (const exp of experiments) {
      for (const sub of exp.submissions) {
        const sid = sub.studentId.toString();
        const current = studentAggregates.get(sid) || {
          obsTotal: 0,
          recTotal: 0,
          vivaTotal: 0,
          count: 0,
        };
        current.obsTotal += sub.observationMarks || 0;
        current.recTotal += sub.recordMarks || 0;
        current.vivaTotal += sub.vivaMarks || 0;
        current.count += 1;
        studentAggregates.set(sid, current);
      }
    }

    const assessment = await InternalAssessment.findOne({
      collegeId: new Types.ObjectId(collegeId),
      sectionId: new Types.ObjectId(sectionId),
      subjectId: new Types.ObjectId(subjectId),
    });

    if (!assessment) {
      throw ApiError.notFound('Internal assessment record not found. Please initialize draft first.');
    }

    if (assessment.status === AssessmentStatus.PUBLISHED) {
      throw ApiError.badRequest('Cannot sync lab scores into a published assessment.');
    }

    let modified = false;
    for (const entry of assessment.entries) {
      const agg = studentAggregates.get(entry.studentId.toString());
      if (agg && agg.count > 0) {
        const avgObs = Math.round((agg.obsTotal / agg.count) * 10) / 10;
        const avgRec = Math.round((agg.recTotal / agg.count) * 10) / 10;
        const avgViva = Math.round((agg.vivaTotal / agg.count) * 10) / 10;

        const updatedMarks = { ...entry.componentMarks };
        updatedMarks['lab'] = avgObs;
        updatedMarks['record'] = avgRec;
        updatedMarks['viva'] = avgViva;
        entry.componentMarks = updatedMarks;
        modified = true;

        // Recompute student total
        let total = 0;
        for (const m of Object.values(entry.componentMarks)) {
          if (typeof m === 'number') total += m;
        }
        entry.totalMarks = Math.round(total * 10) / 10;
      }
    }

    if (modified) {
      assessment.auditLog.push({
        action: 'SYNCED_LAB_SCORES',
        performedBy: new Types.ObjectId(user.id),
        performedByName: user.name || 'Faculty',
        performedByRole: user.role || 'FACULTY',
        timestamp: new Date(),
        details: `Synced aggregate lab & record scores from ${experiments.length} experiments`,
      });
      assessment.markModified('entries');
      await assessment.save();
    }

    return {
      message: `Successfully synchronized lab scores from ${experiments.length} experiments`,
      assessment,
    };
  }

  /**
   * Helper: Resolves InternalAssessment either by ID or by sectionId + subjectId.
   */
  private static async resolveAssessment(
    collegeId: string,
    params: { assessmentId?: string; sectionId?: string; subjectId?: string }
  ): Promise<IInternalAssessment | null> {
    if (params.assessmentId && Types.ObjectId.isValid(params.assessmentId)) {
      return InternalAssessment.findOne({
        _id: new Types.ObjectId(params.assessmentId),
        collegeId: new Types.ObjectId(collegeId),
      });
    }

    if (params.sectionId && params.subjectId) {
      return InternalAssessment.findOne({
        collegeId: new Types.ObjectId(collegeId),
        sectionId: new Types.ObjectId(params.sectionId),
        subjectId: new Types.ObjectId(params.subjectId),
      });
    }

    return null;
  }

  /**
   * Helper: Emit persistent notification to students when marks are published
   */
  private static async emitMarksPublishedNotification(assessment: IInternalAssessment) {
    try {
      const subject = await Subject.findById(assessment.subjectId);
      const subjectName = subject?.name || 'Subject';

      // Find userIds of all students in this assessment
      const studentIds = assessment.entries.map((e) => e.studentId);
      const students = await Student.find({
        _id: { $in: studentIds },
        userId: { $ne: null },
      }).select('userId');

      for (const s of students) {
        if (s.userId) {
          await NotificationService.createNotification({
            collegeId: assessment.collegeId.toString(),
            recipientUserId: s.userId.toString(),
            recipientRole: AppRole.STUDENT,
            notificationType: NotificationType.ASSESSMENT_PUBLISHED,
            category: NotificationCategory.ACADEMIC,
            priority: NotificationPriority.HIGH,
            title: `Internal Marks Published: ${subjectName}`,
            body: `Your marks for ${assessment.title || subjectName} have been published. Tap to view your score.`,
            deepLink: `/academics/assessments/${assessment._id.toString()}`,
            metadata: {
              assessmentId: assessment._id.toString(),
              subjectId: assessment.subjectId.toString(),
            },
          }).catch((err: any) => logger.warn(`Failed to send marks notification: ${err?.message}`));
        }
      }
    } catch (err: any) {
      logger.warn(`Error emitting marks published notification: ${err?.message}`);
    }
  }
}
