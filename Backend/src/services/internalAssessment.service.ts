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
  IAcademicScopeTarget,
  Department,
  Course,
  Section,
  Subject,
  StudentEnrollment,
  Student,
  LabExperiment,
  FacultyAssignment,
  AssessmentMark,
  AssessmentSchedule,
  Room,
  CalendarEvent,
} from '../models';
import { isValidAssessmentTransition } from '../constants/assessment.constants';
import {
  CalendarSourceType,
  CalendarEventType,
  CalendarEventScope,
} from '../constants/calendar.constants';
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
import { RequestModel } from '../models/request.model';
import { RequestStatus } from '../constants/request.constants';
import { AuditService } from './audit.service';
import { formatDateToCalendarString, DEFAULT_INSTITUTION_TIMEZONE } from '../utils/dateTime';

export interface SaveMarksPayload {
  assessmentId?: string;
  sectionId?: string;
  subjectId?: string;
  academicYearId?: string;
  title?: string;
  entries: Array<{
    studentEnrollmentId?: string;
    studentId?: string;
    studentName?: string;
    rollNumber?: string;
    admissionNumber?: string;
    componentMarks?: Record<string, number | null>;
    marks?: number | null;
    obtainedMarks?: number;
    totalMarks?: number;
    status?: StudentMarkStatus;
    remarks?: string;
  }>;
}

export interface AcademicScopeTargetDTO {
  departmentId: string;
  courseId: string;
  academicYearId: string;
  semesterId: string;
  sectionId?: string | null;
  facultyAssignmentId?: string | null;
  departmentName?: string | null;
  sectionName?: string | null;
  semesterNumber?: number | null;
  studentCount?: number;
}

export interface CreateAssessmentPayload {
  departmentId?: string;
  courseId?: string;
  academicYearId?: string;
  semesterId?: string;
  sectionId?: string | null;
  subjectId?: string;
  facultyAssignmentId?: string | null;
  academicScopes?: AcademicScopeTargetDTO[];
  title: string;
  description?: string;
  assessmentType?: AssessmentType | string;
  maximumMarks: number;
  passMarks?: number;
  weightage?: number;
  assessmentDate?: Date | string;
  components?: IAssessmentComponent[];
  sourceType?: 'LIVE' | 'IMPORTED' | 'HISTORICAL_MANUAL';
  isHistorical?: boolean;
}

export interface PreviewScopePayload {
  subjectId: string;
  academicScopes: AcademicScopeTargetDTO[];
}

export interface CheckScheduleConflictsPayload {
  date: string | Date;
  startTime: string;
  endTime: string;
  roomId?: string | null;
  invigilatorFacultyId?: string | null;
  targetSectionIds?: string[];
  assessmentId?: string | null;
}

export interface ScheduleAssessmentPayload {
  assessmentId: string;
  date: string | Date;
  startTime: string;
  endTime: string;
  roomId?: string | null;
  invigilatorFacultyId?: string | null;
  instructions?: string;
}

export interface MigrationReport {
  recordsDiscovered: number;
  assessmentsProcessed: number;
  assessmentsMigrated: number;
  marksMigrated: number;
  unresolvedStudents: Array<{
    assessmentId: string;
    studentId: string;
    studentName?: string;
    reason: string;
  }>;
  duplicateConflicts: number;
  invalidRecords: number;
  skippedRecords: number;
  dryRun: boolean;
  errors: string[];
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
   * Retrieves or initializes the assessment context for a given section and subject, or specific assessment ID.
   */
  static async getAssessmentContext(
    collegeId: string,
    user: AuthUserContext,
    params: {
      sectionId?: string;
      subjectId?: string;
      academicYearId?: string;
      assessmentId?: string;
      facultyAssignmentId?: string;
    }
  ) {
    let { sectionId, subjectId, academicYearId, assessmentId, facultyAssignmentId } = params;

    let targetAssessment: IInternalAssessment | null = null;
    if (assessmentId && Types.ObjectId.isValid(assessmentId)) {
      targetAssessment = await InternalAssessment.findOne({
        _id: new Types.ObjectId(assessmentId),
        collegeId: new Types.ObjectId(collegeId),
      });
      if (targetAssessment) {
        sectionId = targetAssessment.sectionId ? targetAssessment.sectionId.toString() : sectionId;
        subjectId = targetAssessment.subjectId.toString();
        academicYearId = targetAssessment.academicYearId ? targetAssessment.academicYearId.toString() : academicYearId;
      }
    }

    if (facultyAssignmentId && (!sectionId || !subjectId) && Types.ObjectId.isValid(facultyAssignmentId)) {
      const fa = await FacultyAssignment.findOne({
        _id: new Types.ObjectId(facultyAssignmentId),
        collegeId: new Types.ObjectId(collegeId),
      });
      if (fa) {
        sectionId = fa.sectionId ? fa.sectionId.toString() : sectionId;
        subjectId = fa.subjectId.toString();
        academicYearId = fa.academicYearId ? fa.academicYearId.toString() : academicYearId;
      }
    }

    if (!sectionId || !subjectId || !Types.ObjectId.isValid(sectionId) || !Types.ObjectId.isValid(subjectId)) {
      throw ApiError.badRequest('Valid section ID and subject ID (or assessment ID) are required');
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

    if (!applicableComponents.some((c) => c.key === 'test1')) {
      applicableComponents.push(
        { key: 'test1', name: 'Internal Test 1', maxMarks: 25, weightage: 25, isStudentVisible: true },
        { key: 'test2', name: 'Internal Test 2', maxMarks: 25, weightage: 25, isStudentVisible: true }
      );
    }

    // Fallback if no components configured
    if (applicableComponents.length === 0) {
      applicableComponents.push(
        { key: 'test1', name: 'Internal Test 1', maxMarks: 25, weightage: 30, isStudentVisible: true },
        { key: 'test2', name: 'Internal Test 2', maxMarks: 25, weightage: 30, isStudentVisible: true },
        { key: 'assignment', name: 'Assignment', maxMarks: 10, weightage: 20, isStudentVisible: true }
      );
    }

    // Compute default maximum marks from configuration and components
    const componentsSum = applicableComponents.reduce((acc, c) => acc + (c.maxMarks || 0), 0);
    const defaultMaxMarks = Math.max(assessmentConfig?.maxTotalMarks || 50, componentsSum);

    // 4. Fetch or initialize InternalAssessment record
    let assessment = targetAssessment || (await InternalAssessment.findOne({
      collegeId: new Types.ObjectId(collegeId),
      sectionId: new Types.ObjectId(sectionId),
      subjectId: new Types.ObjectId(subjectId),
    }));

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
   * Derives canonical academic context from FacultyAssignment when available.
   * Enforces business duplicate prevention for title within section/subject/semester.
   */
  static async createAssessment(
    collegeId: string,
    user: AuthUserContext,
    payload: CreateAssessmentPayload
  ) {
    let {
      departmentId,
      courseId,
      academicYearId,
      semesterId,
      sectionId,
      subjectId,
      facultyAssignmentId,
      title,
      description,
      assessmentType,
      maximumMarks,
      passMarks,
      weightage,
      assessmentDate,
      components,
      sourceType,
    } = payload;

    let faDoc: any = null;
    const validatedScopes: IAcademicScopeTarget[] = [];
    const scopeEnrollmentQueries: any[] = [];

    if (payload.academicScopes && payload.academicScopes.length > 0) {
      for (const sc of payload.academicScopes) {
        if (!sc.departmentId || !sc.courseId || !sc.academicYearId || !sc.semesterId) {
          throw ApiError.badRequest('Incomplete academic hierarchy in one of the selected academic scopes');
        }

        const scopeSubId = subjectId || (sc as any).subjectId;
        if (!scopeSubId) {
          throw ApiError.badRequest('Subject is required for all academic scopes');
        }

        let scFa: any = null;
        if (sc.facultyAssignmentId) {
          scFa = await TeachingAuthorizationService.assertAssessmentCreationAccess(
            collegeId,
            user,
            sc.facultyAssignmentId
          );
        } else {
          scFa = await TeachingAuthorizationService.assertSubjectSectionAccess(
            collegeId,
            user,
            scopeSubId,
            sc.sectionId || null,
            'assessments for this teaching context'
          );
        }

        const deptDoc = await Department.findById(sc.departmentId).select('name');
        const secDoc = sc.sectionId ? await Section.findById(sc.sectionId).select('name') : null;

        validatedScopes.push({
          departmentId: new Types.ObjectId(sc.departmentId),
          courseId: new Types.ObjectId(sc.courseId),
          academicYearId: new Types.ObjectId(sc.academicYearId),
          semesterId: new Types.ObjectId(sc.semesterId),
          sectionId: sc.sectionId ? new Types.ObjectId(sc.sectionId) : null,
          facultyAssignmentId: scFa?._id ? new Types.ObjectId(scFa._id) : (sc.facultyAssignmentId ? new Types.ObjectId(sc.facultyAssignmentId) : null),
          departmentName: deptDoc?.name || sc.departmentName || null,
          sectionName: secDoc?.name || sc.sectionName || null,
          semesterNumber: sc.semesterNumber || null,
        });

        const scQuery: any = {
          collegeId: new Types.ObjectId(collegeId),
          semesterId: new Types.ObjectId(sc.semesterId),
          academicYearId: new Types.ObjectId(sc.academicYearId),
          status: 'active',
        };
        if (sc.sectionId) {
          scQuery.sectionId = new Types.ObjectId(sc.sectionId);
        }
        scopeEnrollmentQueries.push(scQuery);
      }

      if (validatedScopes.length > 0) {
        departmentId = departmentId || validatedScopes[0].departmentId.toString();
        courseId = courseId || validatedScopes[0].courseId.toString();
        academicYearId = academicYearId || validatedScopes[0].academicYearId.toString();
        semesterId = semesterId || validatedScopes[0].semesterId.toString();
        sectionId = sectionId || (validatedScopes[0].sectionId ? validatedScopes[0].sectionId.toString() : null);
        if (!facultyAssignmentId && validatedScopes[0].facultyAssignmentId) {
          facultyAssignmentId = validatedScopes[0].facultyAssignmentId.toString();
        }
        if (!faDoc && facultyAssignmentId) {
          faDoc = await FacultyAssignment.findById(facultyAssignmentId);
        }
      }
    } else if (facultyAssignmentId) {
      faDoc = await TeachingAuthorizationService.assertAssessmentCreationAccess(
        collegeId,
        user,
        facultyAssignmentId
      );
      departmentId = faDoc.departmentId ? faDoc.departmentId.toString() : departmentId;
      courseId = faDoc.courseId ? faDoc.courseId.toString() : courseId;
      academicYearId = faDoc.academicYearId ? faDoc.academicYearId.toString() : academicYearId;
      semesterId = faDoc.semesterId ? faDoc.semesterId.toString() : semesterId;
      sectionId = faDoc.sectionId ? faDoc.sectionId.toString() : sectionId;
      subjectId = faDoc.subjectId ? faDoc.subjectId.toString() : subjectId;
    } else if (sectionId && subjectId) {
      faDoc = await TeachingAuthorizationService.assertSubjectSectionAccess(
        collegeId,
        user,
        subjectId,
        sectionId,
        'assessments for this teaching context'
      );
      if (faDoc && !facultyAssignmentId) {
        facultyAssignmentId = faDoc._id.toString();
      }
    }

    if (!departmentId || !courseId || !academicYearId || !semesterId || !subjectId) {
      throw ApiError.badRequest('Incomplete academic hierarchy context for assessment creation');
    }

    // Business-level Duplicate Prevention:
    // Prevent duplicate assessment title within the same section/scope, subject, and semester
    const targetSectionIdsToCheck = [
      sectionId ? new Types.ObjectId(sectionId) : null,
      ...validatedScopes.map((s) => s.sectionId || null),
    ].filter(Boolean);

    const duplicateQuery: any = {
      collegeId: new Types.ObjectId(collegeId),
      subjectId: new Types.ObjectId(subjectId),
      semesterId: new Types.ObjectId(semesterId),
      title: new RegExp(`^${title.trim()}$`, 'i'),
      status: { $ne: AssessmentStatus.ARCHIVED },
    };
    if (targetSectionIdsToCheck.length > 0) {
      duplicateQuery.$or = [
        { sectionId: { $in: targetSectionIdsToCheck } },
        { 'academicScopes.sectionId': { $in: targetSectionIdsToCheck } },
      ];
    } else {
      duplicateQuery.sectionId = null;
    }

    const existingAssessment = await InternalAssessment.findOne(duplicateQuery);
    if (existingAssessment) {
      throw ApiError.conflict(`An assessment with title '${title.trim()}' already exists for this subject and scope.`);
    }

    const isHistoricalEntry = payload.isHistorical === true || sourceType === 'HISTORICAL_MANUAL';
    const finalSourceType = isHistoricalEntry ? 'HISTORICAL_MANUAL' : (sourceType || 'LIVE');

    // Enrolled students roster: query scopes or single section, deduplicate students
    let enrollments: any[] = [];
    if (scopeEnrollmentQueries.length > 0) {
      const allFound = await StudentEnrollment.find({
        $or: scopeEnrollmentQueries,
      }).populate('studentId');

      const seenStudentIds = new Set<string>();
      for (const e of allFound) {
        if (!e.studentId) continue;
        const s = e.studentId as any;
        const sId = (s._id ? s._id : s).toString();
        if (!seenStudentIds.has(sId)) {
          seenStudentIds.add(sId);
          enrollments.push(e);
        }
      }
    } else {
      const query: any = {
        collegeId: new Types.ObjectId(collegeId),
        semesterId: new Types.ObjectId(semesterId),
        academicYearId: new Types.ObjectId(academicYearId),
        status: 'active',
      };
      if (sectionId) {
        query.sectionId = new Types.ObjectId(sectionId);
      }
      enrollments = await StudentEnrollment.find(query).populate('studentId');
    }

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

    const parsedDate = assessmentDate ? new Date(assessmentDate) : undefined;
    const isPastDate = parsedDate ? parsedDate.getTime() <= Date.now() : false;
    const initialStatus = isHistoricalEntry || isPastDate
      ? AssessmentStatus.MARKS_ENTRY
      : (parsedDate ? AssessmentStatus.SCHEDULED : AssessmentStatus.DRAFT);

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
      academicScopes: validatedScopes,
      isCommonExam: validatedScopes.length > 1,
      title: title.trim(),
      description: description || '',
      assessmentType: (assessmentType as any) || AssessmentType.INTERNAL_EXAM,
      maximumMarks,
      passMarks: passMarks ?? Math.round(maximumMarks * 0.4),
      weightage: weightage ?? 0,
      assessmentDate: parsedDate,
      components: components || [],
      entries: initialEntries,
      status: initialStatus,
      sourceType: finalSourceType,
      createdBy: new Types.ObjectId(user.id),
      auditLog: [
        {
          action: isHistoricalEntry ? 'HISTORICAL_MANUAL_CREATED' : 'CREATED',
          performedBy: new Types.ObjectId(user.id),
          performedByName: user.name || 'User',
          performedByRole: user.role || 'FACULTY',
          timestamp: new Date(),
          details: isHistoricalEntry
            ? `Historical assessment '${title}' created for manual marks entry`
            : `Assessment '${title}' created in ${initialStatus} status`,
        },
      ],
    });

    await AuditService.logAction({
      collegeId,
      actorUserId: user.id,
      actorEmail: user.email,
      actorRole: user.role,
      action: isHistoricalEntry ? 'HISTORICAL_ASSESSMENT_CREATED' : 'ASSESSMENT_CREATED',
      entityType: 'InternalAssessment',
      entityId: assessment._id.toString(),
      metadata: {
        title: assessment.title,
        assessmentType: assessment.assessmentType,
        sourceType: finalSourceType,
        maximumMarks: assessment.maximumMarks,
        academicYearId: assessment.academicYearId?.toString(),
        semesterId: assessment.semesterId?.toString(),
        sectionId: assessment.sectionId?.toString(),
        subjectId: assessment.subjectId?.toString(),
      },
      timestamp: new Date(),
    });

    // Populate initial canonical AssessmentMark records for each active enrollment
    for (const enrollment of enrollments) {
      if (!enrollment.studentId) continue;
      const s = enrollment.studentId as any;
      const studentId = s._id ? s._id : s.id;
      await AssessmentMark.create({
        collegeId: new Types.ObjectId(collegeId),
        assessmentId: assessment._id,
        facultyAssignmentId: assessment.facultyAssignmentId || null,
        subjectId: assessment.subjectId,
        studentEnrollmentId: enrollment._id,
        studentId: new Types.ObjectId(studentId),
        studentName: s.name || 'Student',
        rollNumber: s.rollNumber,
        admissionNumber: s.admissionNumber,
        marks: null,
        maximumMarks: assessment.maximumMarks,
        passMarks: assessment.passMarks,
        status: StudentMarkStatus.NOT_ENTERED,
        isLocked: false,
        sourceType: finalSourceType,
        auditHistory: [
          {
            action: 'INITIALIZED',
            performedBy: new Types.ObjectId(user.id),
            performedByName: user.name || 'User',
            performedByRole: user.role || 'FACULTY',
            timestamp: new Date(),
          },
        ],
      }).catch((err) => {
        logger.debug(`Initial mark record init: ${err?.message}`);
      });
    }

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
   * Resolves canonical AssessmentSchedule record either from embedded subdoc or collection.
   */
  static async resolveAssessmentSchedule(assessment: any): Promise<any> {
    if (
      assessment.schedule &&
      (assessment.schedule.date || assessment.schedule.dateString || assessment.schedule.endTime)
    ) {
      return assessment.schedule;
    }
    const dbSched = await AssessmentSchedule.findOne({ assessmentId: assessment._id }).lean();
    return dbSched || assessment.schedule;
  }

  /**
   * Resolves the scheduled exam end Date/Time in Asia/Kolkata timezone and determines
   * if the exam has concluded according to authoritative server time.
   */
  static checkExamCompletionEligibility(
    schedule?: { date?: Date | string; dateString?: string; endTime?: string | null } | null,
    timeZone: string = DEFAULT_INSTITUTION_TIMEZONE
  ): { isEligible: boolean; examEndDateTime?: Date; reason?: string } {
    if (!schedule) {
      return { isEligible: true };
    }

    const { date, dateString, endTime } = schedule;
    if (!endTime) {
      if (date) {
        const scheduledDate = new Date(date);
        const now = new Date();
        if (now < scheduledDate) {
          return {
            isEligible: false,
            reason: 'Assessment exam has not completed yet. Scheduled exam date has not arrived yet.',
          };
        }
      }
      return { isEligible: true };
    }

    let ymd = dateString;
    if (!ymd && date) {
      try {
        ymd = formatDateToCalendarString(date, timeZone);
      } catch {
        ymd = new Date(date).toISOString().split('T')[0];
      }
    }

    if (!ymd) {
      return { isEligible: true };
    }

    let examEnd: Date;
    if (timeZone === 'Asia/Kolkata' || !timeZone) {
      examEnd = new Date(`${ymd}T${endTime}:00+05:30`);
    } else {
      examEnd = new Date(`${ymd}T${endTime}:00Z`);
    }

    const now = new Date();
    if (now < examEnd) {
      return {
        isEligible: false,
        examEndDateTime: examEnd,
        reason: `Assessment exam has not completed yet. Marks entry is locked until the scheduled exam concludes at ${endTime} (${timeZone}).`,
      };
    }

    return { isEligible: true, examEndDateTime: examEnd };
  }

  /**
   * Retrieves the authoritative enrolled student marks roster for an assessment.
   * Derives roster strictly from Assessment -> Section -> active StudentEnrollment.
   */
  static async getMarksRoster(
    collegeId: string,
    user: AuthUserContext,
    assessmentId: string
  ) {
    if (!Types.ObjectId.isValid(assessmentId)) {
      throw ApiError.badRequest('Invalid assessment ID format');
    }

    const assessment = await InternalAssessment.findOne({
      _id: new Types.ObjectId(assessmentId),
      collegeId: new Types.ObjectId(collegeId),
    });
    if (!assessment) {
      throw ApiError.notFound('Assessment not found');
    }

    // Authorize viewing access
    await TeachingAuthorizationService.assertAssessmentManagementAccess(
      collegeId,
      user,
      assessment,
      'viewing this assessment marks roster'
    );

    const schedule = await this.resolveAssessmentSchedule(assessment);
    const eligibility = this.checkExamCompletionEligibility(schedule);

    // Query active student enrollments
    const enrollmentFilter: any = {
      collegeId: new Types.ObjectId(collegeId),
      semesterId: assessment.semesterId,
      academicYearId: assessment.academicYearId,
      status: 'active',
    };
    if (assessment.sectionId) {
      enrollmentFilter.sectionId = assessment.sectionId;
    }

    const enrollments = await StudentEnrollment.find(enrollmentFilter)
      .populate('studentId', 'name rollNumber admissionNumber status')
      .sort({ 'studentId.rollNumber': 1, 'studentId.name': 1 });

    const marks = await AssessmentMark.find({
      collegeId: new Types.ObjectId(collegeId),
      assessmentId: assessment._id,
    });

    const markMap = new Map<string, any>();
    for (const m of marks) {
      markMap.set(m.studentEnrollmentId.toString(), m);
    }

    const roster: any[] = [];
    let enteredCount = 0;
    let presentCount = 0;
    let absentCount = 0;
    let exemptedCount = 0;
    let notAppearedCount = 0;
    let unresolvedCount = 0;

    for (const enr of enrollments) {
      const student = enr.studentId as any;
      if (student?.status === 'ARCHIVED') continue;

      const m = markMap.get(enr._id.toString());
      const status: StudentMarkStatus = m?.status || StudentMarkStatus.NOT_ENTERED;
      const studentMarks: number | null = m ? m.marks : null;
      const isLocked: boolean =
        assessment.status === AssessmentStatus.LOCKED ||
        assessment.status === AssessmentStatus.PUBLISHED ||
        (m ? m.isLocked : false);

      if (status === StudentMarkStatus.PRESENT) presentCount++;
      else if (status === StudentMarkStatus.ABSENT) absentCount++;
      else if (status === StudentMarkStatus.EXEMPTED || status === StudentMarkStatus.EXCUSED) exemptedCount++;
      else if (status === StudentMarkStatus.NOT_APPEARED) notAppearedCount++;

      if (status !== StudentMarkStatus.NOT_ENTERED) enteredCount++;
      else unresolvedCount++;

      roster.push({
        studentEnrollmentId: enr._id.toString(),
        studentId: student?._id?.toString() || enr.studentId.toString(),
        studentName: student?.name || 'Student',
        rollNumber: student?.rollNumber || null,
        admissionNumber: student?.admissionNumber || null,
        marks: studentMarks,
        maximumMarks: assessment.maximumMarks,
        passMarks: assessment.passMarks || 0,
        status,
        remarks: m?.remarks || null,
        isLocked,
        lockedAt: m?.lockedAt || null,
      });
    }

    return {
      assessment: {
        id: assessment._id.toString(),
        title: assessment.title,
        assessmentType: assessment.assessmentType,
        maximumMarks: assessment.maximumMarks,
        passMarks: assessment.passMarks || 0,
        status: assessment.status,
        schedule: assessment.schedule,
        isLocked: assessment.status === AssessmentStatus.LOCKED || assessment.status === AssessmentStatus.PUBLISHED,
        isSubmitted: assessment.status === AssessmentStatus.SUBMITTED,
        isMarksEntryEligible: eligibility.isEligible,
        examEndDateTime: eligibility.examEndDateTime,
        correctionScope: assessment.correctionScope,
        facultyName: assessment.facultyName,
        submittedAt: assessment.submittedAt,
        lockedAt: assessment.lockedAt,
      },
      summary: {
        totalStudents: roster.length,
        enteredCount,
        presentCount,
        absentCount,
        exemptedCount,
        notAppearedCount,
        unresolvedCount,
      },
      roster,
    };
  }

  /**
   * Explicitly completes an assessment when the scheduled exam finishes.
   * Verifies schedule and authoritative server time before opening marks entry.
   */
  static async completeAssessment(
    collegeId: string,
    user: AuthUserContext,
    assessmentId: string
  ) {
    if (!Types.ObjectId.isValid(assessmentId)) {
      throw ApiError.badRequest('Invalid assessment ID format');
    }

    const assessment = await InternalAssessment.findOne({
      _id: new Types.ObjectId(assessmentId),
      collegeId: new Types.ObjectId(collegeId),
    });
    if (!assessment) {
      throw ApiError.notFound('Assessment not found');
    }

    await TeachingAuthorizationService.assertAssessmentManagementAccess(
      collegeId,
      user,
      assessment,
      'completing this assessment'
    );

    if (assessment.status === AssessmentStatus.LOCKED || assessment.status === AssessmentStatus.PUBLISHED) {
      throw ApiError.badRequest('Cannot complete an assessment that is already locked or published.');
    }

    if (assessment.schedule?.status === 'CANCELLED') {
      throw ApiError.badRequest('Cannot complete a cancelled assessment schedule.');
    }

    const schedule = await this.resolveAssessmentSchedule(assessment);
    const eligibility = this.checkExamCompletionEligibility(schedule);
    if (!eligibility.isEligible) {
      throw ApiError.badRequest(
        eligibility.reason ||
          'Cannot complete assessment before the scheduled exam has ended. Marks entry opens after exam completion.'
      );
    }

    assessment.status = AssessmentStatus.MARKS_ENTRY;
    if (assessment.schedule) {
      assessment.schedule.status = 'COMPLETED';
    }
    assessment.auditLog.push({
      action: 'EXAM_COMPLETED',
      performedBy: new Types.ObjectId(user.id),
      performedByName: user.name || 'User',
      performedByRole: user.role || 'FACULTY',
      timestamp: new Date(),
      details: 'Assessment marked as completed. Marks entry opened.',
    });

    await assessment.save();

    await AssessmentSchedule.updateOne(
      { collegeId: new Types.ObjectId(collegeId), assessmentId: assessment._id },
      { $set: { status: 'COMPLETED' } }
    );

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
        status: assessment.status,
      },
    });

    return assessment;
  }

  /**
   * Saves or updates draft marks in DRAFT, OPEN, or MARKS_ENTRY state.
   * Strictly enforces teaching ownership, exam completion eligibility, and section boundaries.
   */
  static async saveDraftMarks(
    collegeId: string,
    user: AuthUserContext,
    payload: SaveMarksPayload
  ) {
    const { sectionId, subjectId, entries, title, assessmentId } = payload;

    // 1. Resolve assessment
    let assessment = await this.resolveAssessment(collegeId, { assessmentId, sectionId, subjectId });
    if (!assessment) {
      if (sectionId && subjectId) {
        // Assert teaching authorization first so unauthorized users get 403, not 404
        await TeachingAuthorizationService.assertSubjectSectionAccess(
          collegeId,
          user,
          subjectId,
          sectionId,
          'assessments for this teaching context'
        );
        // If authorized, initialize the assessment draft automatically
        await this.getAssessmentContext(collegeId, user, { sectionId, subjectId });
        assessment = await this.resolveAssessment(collegeId, { assessmentId, sectionId, subjectId });
      }
      if (!assessment) {
        throw ApiError.notFound('Assessment not found');
      }
    }

    // 2. Strict teaching ownership check
    await TeachingAuthorizationService.assertAssessmentMarkingAccess(collegeId, user, assessment);

    // 3. Status and lifecycle lock enforcement
    if (assessment.status === AssessmentStatus.PUBLISHED) {
      throw ApiError.forbidden(
        'Assessment marks have been published and locked. Contact your HOD or Administrator to unlock for revisions.'
      );
    }

    if (assessment.status === AssessmentStatus.LOCKED) {
      throw ApiError.badRequest(
        'Assessment is locked. Direct modifications are strictly prohibited. Use the controlled correction workflow.'
      );
    }

    if (assessment.status === AssessmentStatus.SUBMITTED) {
      throw ApiError.badRequest(
        'Assessment has been submitted. Marks cannot be modified without an approved correction request.'
      );
    }

    if (assessment.status === AssessmentStatus.SCHEDULED) {
      const isHistorical =
        assessment.sourceType === 'HISTORICAL_MANUAL' ||
        (assessment.assessmentDate && new Date(assessment.assessmentDate).getTime() <= Date.now());
      if (isHistorical) {
        assessment.status = AssessmentStatus.MARKS_ENTRY;
      } else {
        const schedule = await this.resolveAssessmentSchedule(assessment);
        if (!schedule) {
          throw ApiError.badRequest(
            'Assessment exam has not completed yet. Exam schedule has not concluded.'
          );
        }
        const eligibility = this.checkExamCompletionEligibility(schedule);
        if (!eligibility.isEligible) {
          throw ApiError.badRequest(
            eligibility.reason ||
              'Assessment exam has not completed yet. Marks entry opens after the scheduled exam concludes.'
          );
        }
        assessment.status = AssessmentStatus.MARKS_ENTRY;
      }
    } else if (
      assessment.status === AssessmentStatus.OPEN ||
      assessment.status === AssessmentStatus.COMPLETED
    ) {
      assessment.status = AssessmentStatus.MARKS_ENTRY;
    }

    // 4. Resolve active StudentEnrollment roster strictly belonging to this assessment context
    const enrollmentFilter: any = {
      collegeId: new Types.ObjectId(collegeId),
      status: 'active',
    };
    if (assessment.sectionId) {
      enrollmentFilter.sectionId = assessment.sectionId;
    } else {
      if (assessment.semesterId) enrollmentFilter.semesterId = assessment.semesterId;
      if (assessment.academicYearId) enrollmentFilter.academicYearId = assessment.academicYearId;
    }

    const validEnrollments = await StudentEnrollment.find(enrollmentFilter)
      .populate('studentId', 'name rollNumber admissionNumber status')
      .lean();

    const validEnrollmentMap = new Map<string, any>();
    const studentIdToEnrollmentMap = new Map<string, any>();
    for (const enr of validEnrollments) {
      validEnrollmentMap.set(enr._id.toString(), enr);
      const sId = (enr.studentId as any)?._id?.toString() || enr.studentId?.toString();
      if (sId) {
        studentIdToEnrollmentMap.set(sId, enr);
      }
    }

    // Enforce correction scope boundary if assessment is in a correction window
    if (assessment.correctionScope && assessment.correctionScope.studentEnrollmentIds?.length > 0) {
      const allowedEnrollmentIds = new Set(
        assessment.correctionScope.studentEnrollmentIds.map((id: any) => id.toString())
      );
      for (const item of entries) {
        let enrId = item.studentEnrollmentId?.toString();
        if (!enrId && item.studentId) {
          const matchedEnr = studentIdToEnrollmentMap.get(item.studentId.toString());
          if (matchedEnr) enrId = matchedEnr._id.toString();
        }
        if (enrId && !allowedEnrollmentIds.has(enrId)) {
          const existing = await AssessmentMark.findOne({
            collegeId: new Types.ObjectId(collegeId),
            assessmentId: assessment._id,
            studentEnrollmentId: new Types.ObjectId(enrId),
          });
          const proposed =
            item.marks !== undefined
              ? item.marks
              : item.obtainedMarks !== undefined
              ? item.obtainedMarks
              : item.totalMarks;
          if (existing && proposed !== undefined && proposed !== existing.marks) {
            throw ApiError.forbidden(
              'Student is outside the approved correction scope. Only students within the approved correction scope can be modified.'
            );
          }
        }
      }
    }

    // 5. Validate entries and academic enrollment boundary
    for (const item of entries) {
      if (item.studentEnrollmentId) {
        if (!validEnrollmentMap.has(item.studentEnrollmentId.toString())) {
          throw ApiError.badRequest(
            `Student enrollment '${item.studentEnrollmentId}' does not belong to this assessment's active section roster.`
          );
        }
      } else if (item.studentId) {
        let enr = studentIdToEnrollmentMap.get(item.studentId.toString());
        if (!enr && assessment.sectionId) {
          // Check direct section match on student as fallback
          const directStudent = await Student.findOne({
            _id: new Types.ObjectId(item.studentId.toString()),
            collegeId: new Types.ObjectId(collegeId),
            sectionId: assessment.sectionId,
            isActive: true,
          });
          if (directStudent) {
            let foundEnr = await StudentEnrollment.findOne({
              collegeId: new Types.ObjectId(collegeId),
              studentId: directStudent._id,
              status: 'active',
            });
            if (!foundEnr) {
              foundEnr = await StudentEnrollment.create({
                collegeId: new Types.ObjectId(collegeId),
                studentId: directStudent._id,
                departmentId: assessment.departmentId,
                courseId: assessment.courseId,
                semesterId: assessment.semesterId,
                academicYearId: assessment.academicYearId,
                sectionId: assessment.sectionId,
                status: 'active',
              });
            }
            enr = foundEnr;
            validEnrollmentMap.set(foundEnr._id.toString(), foundEnr);
            studentIdToEnrollmentMap.set(item.studentId.toString(), foundEnr);
          }
        }
        if (!enr) {
          if (item.studentId && Types.ObjectId.isValid(item.studentId.toString())) {
            const directStudent = await Student.findById(item.studentId);
            if (directStudent && directStudent.collegeId && directStudent.collegeId.toString() !== collegeId) {
              throw ApiError.badRequest(
                `Student '${item.studentId}' is not eligible for this college/assessment context.`
              );
            }
          }
          throw ApiError.badRequest(
            `Student '${item.studentId}' does not belong to this assessment's active section roster.`
          );
        }
        item.studentEnrollmentId = enr._id.toString();
      } else {
        throw ApiError.badRequest('Either studentEnrollmentId or studentId is required for each mark entry.');
      }
    }

    // 6. Validate marks values and semantic attendance/marking states
    const validatedMarks: Array<{
      enrollment: any;
      marks: number | null;
      componentMarks?: Record<string, number | null> | null;
      status: StudentMarkStatus;
      remarks?: string | null;
    }> = [];

    for (const item of entries) {
      const enr = validEnrollmentMap.get(item.studentEnrollmentId!.toString());
      const markStatus = item.status || StudentMarkStatus.ENTERED;
      let markValue: number | null = null;
      let finalStatus: StudentMarkStatus = markStatus;

      if (markStatus === StudentMarkStatus.ABSENT) {
        markValue = null;
        finalStatus = StudentMarkStatus.ABSENT;
      } else if (markStatus === StudentMarkStatus.EXEMPTED) {
        markValue = null;
        finalStatus = StudentMarkStatus.EXEMPTED;
      } else if (markStatus === StudentMarkStatus.EXCUSED) {
        markValue = null;
        finalStatus = StudentMarkStatus.EXCUSED;
      } else if (markStatus === StudentMarkStatus.NOT_APPEARED) {
        markValue = null;
        finalStatus = StudentMarkStatus.NOT_APPEARED;
      } else {
        let raw = item.marks;
        if (raw === undefined && item.obtainedMarks !== undefined) raw = item.obtainedMarks;
        if (raw === undefined && item.totalMarks !== undefined) raw = item.totalMarks;
        if (raw === undefined && item.componentMarks && Object.keys(item.componentMarks).length > 0) {
          let compSum = 0;
          let hasVal = false;
          for (const [ck, cv] of Object.entries(item.componentMarks)) {
            if (cv !== null && cv !== undefined && cv !== ('' as any)) {
              const num = Number(cv);
              if (isNaN(num) || num < 0) {
                throw ApiError.badRequest(`Marks for component '${ck}' cannot be negative or non-numeric.`);
              }
              const compDef = assessment.components?.find((c: any) => c.key === ck);
              if (compDef && num > compDef.maxMarks) {
                throw ApiError.badRequest(
                  `Marks for component '${ck}' (${num}) cannot exceed maximum allowed (${compDef.maxMarks}).`
                );
              }
              compSum += num;
              hasVal = true;
            }
          }
          raw = hasVal ? compSum : null;
        }

        if (raw === null || raw === undefined || raw === ('' as any)) {
          markValue = null;
          finalStatus =
            markStatus === StudentMarkStatus.PRESENT ? StudentMarkStatus.PRESENT : StudentMarkStatus.NOT_ENTERED;
        } else {
          const markNum = Number(raw);
          if (isNaN(markNum) || markNum < 0) {
            throw ApiError.badRequest('Marks cannot be negative or non-numeric.');
          }
          if (markNum > assessment.maximumMarks) {
            throw ApiError.badRequest(
              `Marks (${markNum}) cannot exceed maximum allowed (${assessment.maximumMarks}).`
            );
          }
          markValue = Math.round(markNum * 100) / 100;
          finalStatus =
            markStatus === StudentMarkStatus.PRESENT ? StudentMarkStatus.PRESENT : StudentMarkStatus.ENTERED;
        }
      }

      validatedMarks.push({
        enrollment: enr,
        marks: markValue,
        componentMarks: item.componentMarks || null,
        status: finalStatus,
        remarks: item.remarks || null,
      });
    }

    if (title) assessment.title = title;

    // 7. Persist AssessmentMark records and audit trail
    for (const vm of validatedMarks) {
      const enr = vm.enrollment;
      const studentObj = enr.studentId as any;

      const existingMark = await AssessmentMark.findOne({
        collegeId: new Types.ObjectId(collegeId),
        assessmentId: assessment._id,
        studentEnrollmentId: enr._id,
      });

      if (existingMark?.isLocked && !assessment.correctionScope) {
        throw ApiError.badRequest(
          'Assessment mark is locked against modifications. Use the controlled correction workflow.'
        );
      }

      const prevMarks = existingMark?.marks ?? null;
      const prevStatus = existingMark?.status ?? StudentMarkStatus.NOT_ENTERED;

      const markAction = assessment.sourceType === 'HISTORICAL_MANUAL'
        ? 'HISTORICAL_MARK_SAVED'
        : (assessment.correctionScope ? 'CORRECTION_APPLIED' : 'MARKS_SAVED');

      const updatedMark = await AssessmentMark.findOneAndUpdate(
        {
          collegeId: new Types.ObjectId(collegeId),
          assessmentId: assessment._id,
          studentEnrollmentId: enr._id,
        },
        {
          $set: {
            facultyAssignmentId: assessment.facultyAssignmentId || null,
            subjectId: assessment.subjectId,
            studentId: studentObj._id || studentObj,
            studentName: studentObj.name || 'Student',
            rollNumber: studentObj.rollNumber || null,
            admissionNumber: studentObj.admissionNumber || null,
            marks: vm.marks,
            maximumMarks: assessment.maximumMarks,
            passMarks: assessment.passMarks || 0,
            status: vm.status,
            remarks: vm.remarks || null,
            isLocked: false,
            sourceType: assessment.sourceType || 'LIVE',
          },
          $push: {
            auditHistory: {
              action: markAction,
              previousMarks: prevMarks,
              newMarks: vm.marks,
              previousStatus: prevStatus,
              newStatus: vm.status,
              performedBy: new Types.ObjectId(user.id),
              performedByName: user.name || 'Faculty',
              performedByRole: user.role || 'FACULTY',
              reason: assessment.correctionScope?.reason || vm.remarks || undefined,
              timestamp: new Date(),
            },
          },
        },
        { upsert: true, new: true }
      );

      // Audit correction if this was an approved correction
      if (assessment.correctionScope && prevMarks !== vm.marks) {
        await AuditService.logAction({
          collegeId,
          actorUserId: user.id,
          actorEmail: user.email,
          actorRole: user.role,
          action: 'ASSESSMENT_MARK_CORRECTED',
          entityType: 'AssessmentMark',
          entityId: updatedMark._id.toString(),
          previousValue: { marks: prevMarks, status: prevStatus },
          newValue: { marks: vm.marks, status: vm.status },
          metadata: {
            assessmentId: assessment._id.toString(),
            studentEnrollmentId: enr._id.toString(),
            requestId: assessment.correctionScope.requestId?.toString(),
            reason: assessment.correctionScope.reason,
          },
          timestamp: new Date(),
        });
      }

      // Synchronize embedded entry for backward compatibility
      const existingEntryIndex = assessment.entries.findIndex(
        (e) => e.studentId.toString() === (studentObj._id || studentObj).toString()
      );
      const entryObj: IStudentAssessmentEntry = {
        studentId: studentObj._id || studentObj,
        studentName: studentObj.name || 'Student',
        rollNumber: studentObj.rollNumber || undefined,
        admissionNumber: studentObj.admissionNumber || undefined,
        componentMarks: vm.componentMarks || (vm.marks !== null ? { total: vm.marks } : {}),
        totalMarks: vm.marks || 0,
        status: vm.status,
        remarks: vm.remarks || undefined,
      };

      if (existingEntryIndex >= 0) {
        assessment.entries[existingEntryIndex] = entryObj;
      } else {
        assessment.entries.push(entryObj);
      }
    }

    assessment.auditLog.push({
      action: assessment.correctionScope ? 'CORRECTION_APPLIED' : 'UPDATED_DRAFT',
      performedBy: new Types.ObjectId(user.id),
      performedByName: user.name || 'User',
      performedByRole: user.role || 'FACULTY',
      timestamp: new Date(),
      details: `Saved marks draft for ${validatedMarks.length} students`,
    });

    assessment.markModified('entries');
    await assessment.save();

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
        updatedCount: validatedMarks.length,
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
   * Submits marks and transitions assessment to SUBMITTED.
   * Validates roster completeness so no students remain unentered.
   */
  static async submitMarks(
    collegeId: string,
    user: AuthUserContext,
    assessmentId: string,
    payload?: SaveMarksPayload
  ) {
    if (!Types.ObjectId.isValid(assessmentId)) {
      throw ApiError.badRequest('Invalid assessment ID format');
    }

    const assessment = await InternalAssessment.findOne({
      _id: new Types.ObjectId(assessmentId),
      collegeId: new Types.ObjectId(collegeId),
    });
    if (!assessment) {
      throw ApiError.notFound('Assessment not found');
    }

    // Strict teaching ownership
    await TeachingAuthorizationService.assertAssessmentMarkingAccess(collegeId, user, assessment);

    if (assessment.status === AssessmentStatus.LOCKED || assessment.status === AssessmentStatus.PUBLISHED) {
      throw ApiError.badRequest('Assessment is already locked.');
    }

    // Safe handling for duplicate submissions
    if (assessment.status === AssessmentStatus.SUBMITTED) {
      return { assessment, message: 'Assessment has already been submitted.' };
    }

    if (assessment.status === AssessmentStatus.SCHEDULED) {
      const isHistorical =
        assessment.sourceType === 'HISTORICAL_MANUAL' ||
        (assessment.assessmentDate && new Date(assessment.assessmentDate).getTime() <= Date.now());
      if (!isHistorical) {
        const schedule = await this.resolveAssessmentSchedule(assessment);
        const eligibility = this.checkExamCompletionEligibility(schedule);
        if (!eligibility.isEligible) {
          throw ApiError.badRequest(
            eligibility.reason ||
              'Assessment exam has not completed yet. Marks cannot be submitted before the scheduled exam has concluded.'
          );
        }
      }
    }

    // Save payload first if provided
    if (payload?.entries && payload.entries.length > 0) {
      await this.saveDraftMarks(collegeId, user, { ...payload, assessmentId });
    }

    // Validate completeness of active roster
    const enrollmentFilter: any = {
      collegeId: new Types.ObjectId(collegeId),
      semesterId: assessment.semesterId,
      academicYearId: assessment.academicYearId,
      status: 'active',
    };
    if (assessment.sectionId) {
      enrollmentFilter.sectionId = assessment.sectionId;
    }

    const activeEnrollments = await StudentEnrollment.find(enrollmentFilter)
      .populate('studentId', 'name rollNumber admissionNumber status')
      .lean();

    const marks = await AssessmentMark.find({
      collegeId: new Types.ObjectId(collegeId),
      assessmentId: assessment._id,
    });

    const markMap = new Map<string, any>();
    for (const m of marks) {
      markMap.set(m.studentEnrollmentId.toString(), m);
    }

    const unresolvedStudents: Array<{
      studentEnrollmentId: string;
      studentId: string;
      studentName: string;
      rollNumber?: string | null;
      reason: string;
    }> = [];

    for (const enr of activeEnrollments) {
      const student = enr.studentId as any;
      if (student?.status === 'ARCHIVED') continue;

      const m = markMap.get(enr._id.toString());
      if (!m || m.status === StudentMarkStatus.NOT_ENTERED) {
        unresolvedStudents.push({
          studentEnrollmentId: enr._id.toString(),
          studentId: student?._id?.toString() || enr.studentId.toString(),
          studentName: student?.name || 'Student',
          rollNumber: student?.rollNumber || null,
          reason: 'No mark or status entered',
        });
      } else if (
        m.status === StudentMarkStatus.PRESENT &&
        (m.marks === null || m.marks === undefined)
      ) {
        unresolvedStudents.push({
          studentEnrollmentId: enr._id.toString(),
          studentId: student?._id?.toString() || enr.studentId.toString(),
          studentName: student?.name || 'Student',
          rollNumber: student?.rollNumber || null,
          reason: 'Marks required for present student',
        });
      }
    }

    if (unresolvedStudents.length > 0) {
      throw ApiError.badRequest(
        `${unresolvedStudents.length} student(s) still require a mark or attendance status before submission.`,
        'INCOMPLETE_ROSTER',
        { unresolvedStudents }
      );
    }

    // Atomic update to transition to SUBMITTED and clear any temporary correction scope
    const updated = await InternalAssessment.findOneAndUpdate(
      {
        _id: assessment._id,
        collegeId: new Types.ObjectId(collegeId),
        status: {
          $in: [
            AssessmentStatus.MARKS_ENTRY,
            AssessmentStatus.COMPLETED,
            AssessmentStatus.OPEN,
            AssessmentStatus.DRAFT,
          ],
        },
      },
      {
        $set: {
          status: AssessmentStatus.SUBMITTED,
          submittedAt: new Date(),
          submittedBy: new Types.ObjectId(user.id),
          correctionScope: null,
          updatedBy: new Types.ObjectId(user.id),
        },
        $push: {
          auditLog: {
            action: 'SUBMITTED',
            performedBy: new Types.ObjectId(user.id),
            performedByName: user.name || 'Faculty',
            performedByRole: user.role || 'FACULTY',
            timestamp: new Date(),
            details: `Assessment marks submitted for ${activeEnrollments.length} enrolled students`,
          },
        },
      },
      { new: true }
    );

    if (!updated) {
      const current = await InternalAssessment.findById(assessment._id);
      if (current?.status === AssessmentStatus.SUBMITTED) {
        return { assessment: current, message: 'Assessment has already been submitted.' };
      }
      throw ApiError.conflict('Concurrent modification detected during submission.');
    }

    await AuditService.logAction({
      collegeId,
      actorUserId: user.id,
      actorEmail: user.email,
      actorRole: user.role,
      action: 'ASSESSMENT_MARKS_SUBMITTED',
      entityType: 'InternalAssessment',
      entityId: assessment._id.toString(),
      metadata: {
        studentCount: activeEnrollments.length,
      },
      timestamp: new Date(),
    });

    realtimeEventBus.publish({
      eventId: new Types.ObjectId().toString(),
      eventVersion: 1,
      eventType: AcadexEventType.ASSESSMENT_UPDATED,
      aggregateType: 'InternalAssessment',
      aggregateId: assessment._id.toString(),
      action: 'SUBMITTED',
      occurredAt: new Date().toISOString(),
      collegeId,
      scope: {
        type: 'department',
        collegeId,
        departmentId: assessment.departmentId.toString(),
      },
      payload: {
        assessmentId: assessment._id.toString(),
        status: AssessmentStatus.SUBMITTED,
      },
    });

    return { assessment: updated, message: 'Assessment marks submitted successfully.' };
  }

  /**
   * Locks the assessment and all underlying AssessmentMark records.
   */
  static async lockAssessment(
    collegeId: string,
    user: AuthUserContext,
    assessmentId: string
  ) {
    if (!Types.ObjectId.isValid(assessmentId)) {
      throw ApiError.badRequest('Invalid assessment ID format');
    }

    const assessment = await InternalAssessment.findOne({
      _id: new Types.ObjectId(assessmentId),
      collegeId: new Types.ObjectId(collegeId),
    });
    if (!assessment) {
      throw ApiError.notFound('Assessment not found');
    }

    await TeachingAuthorizationService.assertAssessmentManagementAccess(
      collegeId,
      user,
      assessment,
      'locking this assessment'
    );

    if (assessment.status === AssessmentStatus.DRAFT) {
      throw ApiError.badRequest('Cannot lock a draft assessment. Marks must be entered and submitted first.');
    }

    if (assessment.status === AssessmentStatus.LOCKED) {
      return assessment; // Idempotent
    }

    assessment.status = AssessmentStatus.LOCKED;
    assessment.lockedAt = new Date();
    assessment.lockedBy = new Types.ObjectId(user.id);
    assessment.auditLog.push({
      action: 'LOCKED',
      performedBy: new Types.ObjectId(user.id),
      performedByName: user.name || 'User',
      performedByRole: user.role || 'ADMIN',
      timestamp: new Date(),
      details: 'Assessment finalized and locked against direct edits',
    });

    await assessment.save();

    await AssessmentMark.updateMany(
      {
        collegeId: new Types.ObjectId(collegeId),
        assessmentId: assessment._id,
      },
      {
        $set: {
          isLocked: true,
          lockedAt: new Date(),
          lockedBy: new Types.ObjectId(user.id),
        },
      }
    );

    await AuditService.logAction({
      collegeId,
      actorUserId: user.id,
      actorEmail: user.email,
      actorRole: user.role,
      action: 'ASSESSMENT_LOCKED',
      entityType: 'InternalAssessment',
      entityId: assessment._id.toString(),
      timestamp: new Date(),
    });

    realtimeEventBus.publish({
      eventId: new Types.ObjectId().toString(),
      eventVersion: 1,
      eventType: AcadexEventType.ASSESSMENT_UPDATED,
      aggregateType: 'InternalAssessment',
      aggregateId: assessment._id.toString(),
      action: 'LOCKED',
      occurredAt: new Date().toISOString(),
      collegeId,
      scope: {
        type: 'department',
        collegeId,
        departmentId: assessment.departmentId.toString(),
      },
      payload: {
        assessmentId: assessment._id.toString(),
        status: AssessmentStatus.LOCKED,
      },
    });

    return assessment;
  }

  /**
   * Requests a mark correction through the canonical Request architecture.
   */
  static async requestAssessmentCorrection(
    collegeId: string,
    user: AuthUserContext,
    payload: {
      assessmentId: string;
      studentEnrollmentId: string;
      newMark?: number | null;
      newStatus?: StudentMarkStatus;
      reason: string;
    }
  ) {
    const { assessmentId, studentEnrollmentId, newMark, newStatus, reason } = payload;

    if (!reason || reason.trim().length < 5) {
      throw ApiError.badRequest('Correction reason must be at least 5 characters long.');
    }

    if (!Types.ObjectId.isValid(assessmentId) || !Types.ObjectId.isValid(studentEnrollmentId)) {
      throw ApiError.badRequest('Invalid ID format');
    }

    const assessment = await InternalAssessment.findOne({
      _id: new Types.ObjectId(assessmentId),
      collegeId: new Types.ObjectId(collegeId),
    });
    if (!assessment) {
      throw ApiError.notFound('Assessment not found');
    }

    // Authorize requester: Must be assigned faculty or HOD of department
    const roleUpper = (user.role || '').toUpperCase();
    let isAuthorizedRequester = false;
    if (roleUpper === 'HOD') {
      if (!user.departmentId || user.departmentId.toString() === assessment.departmentId.toString()) {
        isAuthorizedRequester = true;
      }
    } else if (roleUpper === 'FACULTY') {
      try {
        await TeachingAuthorizationService.assertAssessmentMarkingAccess(collegeId, user, assessment);
        isAuthorizedRequester = true;
      } catch {
        isAuthorizedRequester = false;
      }
    }

    if (!isAuthorizedRequester) {
      throw ApiError.forbidden(
        'Only the assigned faculty or department HOD can initiate a mark correction request.'
      );
    }

    if (
      assessment.status !== AssessmentStatus.SUBMITTED &&
      assessment.status !== AssessmentStatus.LOCKED &&
      assessment.status !== AssessmentStatus.PUBLISHED &&
      assessment.status !== AssessmentStatus.CLOSED
    ) {
      throw ApiError.badRequest(
        'Correction requests can only be initiated for submitted, locked, or published assessments.'
      );
    }

    const enrollment = await StudentEnrollment.findOne({
      _id: new Types.ObjectId(studentEnrollmentId),
      collegeId: new Types.ObjectId(collegeId),
    });
    if (!enrollment) {
      throw ApiError.badRequest('Referenced student enrollment does not exist.');
    }

    const mark = await AssessmentMark.findOne({
      collegeId: new Types.ObjectId(collegeId),
      assessmentId: assessment._id,
      studentEnrollmentId: enrollment._id,
    });

    const previousMarks = mark ? mark.marks : null;
    const previousStatus = mark ? mark.status : StudentMarkStatus.NOT_ENTERED;
    const studentName = mark ? mark.studentName : 'Student';

    const correctionReq = await RequestModel.create({
      requestId: `REQ-${Date.now().toString().slice(-6)}-${Math.floor(1000 + Math.random() * 9000)}`,
      collegeId: new Types.ObjectId(collegeId),
      departmentId: assessment.departmentId,
      requesterUserId: user.id,
      requesterName: user.name || 'Faculty',
      requesterRole: (user.role as AppRole) || AppRole.FACULTY,
      targetRole: roleUpper === 'HOD' ? AppRole.COLLEGE_ADMIN : AppRole.HOD,
      requestType: 'ASSESSMENT_MARK_CORRECTION' as any,
      title: `Mark Correction Request: ${assessment.title} - ${studentName}`,
      description: reason.trim(),
      relatedEntityType: 'ASSESSMENT',
      relatedEntityId: assessment._id.toString(),
      academicContext: {
        courseId: assessment.courseId,
        academicYearId: assessment.academicYearId,
        semesterId: assessment.semesterId,
        sectionId: assessment.sectionId,
        subjectId: assessment.subjectId,
        facultyAssignmentId: assessment.facultyAssignmentId,
      },
      details: {
        reason: reason.trim(),
        metadata: {
          assessmentId: assessment._id.toString(),
          studentEnrollmentId: enrollment._id.toString(),
          studentId: enrollment.studentId.toString(),
          studentName,
          previousMarks,
          previousStatus,
          requestedMarks: newMark !== undefined ? newMark : null,
          requestedStatus: newStatus || StudentMarkStatus.PRESENT,
        },
      },
      status: RequestStatus.SUBMITTED,
      history: [
        {
          status: RequestStatus.SUBMITTED,
          changedBy: user.id,
          changedByName: user.name,
          note: reason.trim(),
          timestamp: new Date(),
        },
      ],
    });

    return {
      request: correctionReq,
      ...correctionReq.toObject(),
    };
  }

  /**
   * Responds to a mark correction request (Approve/Reject).
   * Authorized reviewer approves, temporarily opening correction scope for assigned faculty.
   */
  static async respondAssessmentCorrection(
    collegeId: string,
    user: AuthUserContext,
    requestId: string,
    action: string,
    message?: string
  ) {
    if (!Types.ObjectId.isValid(requestId)) {
      throw ApiError.badRequest('Invalid request ID format');
    }

    const req = await RequestModel.findOne({
      _id: new Types.ObjectId(requestId),
      collegeId: new Types.ObjectId(collegeId),
    });
    if (!req) {
      throw ApiError.notFound('Correction request not found');
    }

    // Requesters CANNOT approve or reject their own request!
    if (req.requesterUserId.toString() === user.id.toString()) {
      throw ApiError.forbidden('Requester cannot approve their own correction request.');
    }

    // Reviewer authority check
    const roleUpper = (user.role || '').toUpperCase();
    if (roleUpper === 'SUPER_ADMIN' || roleUpper === 'COLLEGE_ADMIN') {
      // Allowed
    } else if (roleUpper === 'HOD') {
      if (user.departmentId && req.departmentId && req.departmentId.toString() !== user.departmentId.toString()) {
        throw ApiError.forbidden('HOD can only respond to correction requests within their assigned department.');
      }
    } else {
      throw ApiError.forbidden('Only an authorized HOD or Administrator can respond to mark correction requests.');
    }

    if (
      req.status !== RequestStatus.SUBMITTED &&
      req.status !== RequestStatus.RECEIVED &&
      req.status !== RequestStatus.UNDER_REVIEW
    ) {
      throw ApiError.badRequest(`Cannot respond to a request in '${req.status}' status.`);
    }

    if (action === 'REJECTED') {
      req.status = RequestStatus.REJECTED;
      req.respondedAt = new Date();
      req.respondedBy = user.id;
      req.respondedByName = user.name;
      req.responseMessage = message || 'Correction request rejected.';
      req.history.push({
        status: RequestStatus.REJECTED,
        changedBy: user.id,
        changedByName: user.name,
        note: message || 'Rejected',
        timestamp: new Date(),
      });
      await req.save();
      return req;
    }

    // APPROVED: Reopen assessment and unlock the specific mark
    req.status = RequestStatus.APPROVED;
    req.respondedAt = new Date();
    req.respondedBy = user.id;
    req.respondedByName = user.name;
    req.responseMessage = message || 'Correction request approved.';
    req.history.push({
      status: RequestStatus.APPROVED,
      changedBy: user.id,
      changedByName: user.name,
      note: message || 'Approved',
      timestamp: new Date(),
    });
    await req.save();

    const meta = req.details?.metadata as any;
    const assessmentId = meta?.assessmentId || req.relatedEntityId;
    const studentEnrollmentId = meta?.studentEnrollmentId;

    if (assessmentId && studentEnrollmentId) {
      const assessment = await InternalAssessment.findOne({
        _id: new Types.ObjectId(assessmentId),
        collegeId: new Types.ObjectId(collegeId),
      });

      if (assessment) {
        assessment.status = AssessmentStatus.MARKS_ENTRY;
        assessment.correctionScope = {
          requestId: req._id,
          studentEnrollmentIds: [new Types.ObjectId(studentEnrollmentId)],
          unlockedAt: new Date(),
          unlockedBy: new Types.ObjectId(user.id),
          reason: req.details?.reason || message || 'Approved mark correction',
        };
        assessment.auditLog.push({
          action: 'CORRECTION_APPROVED',
          performedBy: new Types.ObjectId(user.id),
          performedByName: user.name || 'Reviewer',
          performedByRole: user.role || 'HOD',
          timestamp: new Date(),
          details: `Mark correction approved for student enrollment ${studentEnrollmentId}. Assessment reopened for correction.`,
        });
        await assessment.save();

        await AssessmentMark.updateOne(
          {
            collegeId: new Types.ObjectId(collegeId),
            assessmentId: assessment._id,
            studentEnrollmentId: new Types.ObjectId(studentEnrollmentId),
          },
          { $set: { isLocked: false } }
        );
      }
    }

    await AuditService.logAction({
      collegeId,
      actorUserId: user.id,
      actorEmail: user.email,
      actorRole: user.role,
      action: 'ASSESSMENT_CORRECTION_APPROVED',
      entityType: 'InternalAssessment',
      entityId: assessmentId,
      metadata: {
        requestId: req._id.toString(),
        studentEnrollmentId,
        reason: req.details?.reason,
      },
      timestamp: new Date(),
    });

    return req;
  }

  /**
   * Retrieves summary submission and lock state of an assessment.
   */
  static async getAssessmentSubmissionState(
    collegeId: string,
    user: AuthUserContext,
    assessmentId: string
  ) {
    if (!Types.ObjectId.isValid(assessmentId)) {
      throw ApiError.badRequest('Invalid assessment ID format');
    }

    const assessment = await InternalAssessment.findOne({
      _id: new Types.ObjectId(assessmentId),
      collegeId: new Types.ObjectId(collegeId),
    });
    if (!assessment) {
      throw ApiError.notFound('Assessment not found');
    }

    await TeachingAuthorizationService.assertAssessmentManagementAccess(
      collegeId,
      user,
      assessment,
      'viewing submission state'
    );

    const schedule = await this.resolveAssessmentSchedule(assessment);
    const eligibility = this.checkExamCompletionEligibility(schedule);

    const enrollmentFilter: any = {
      collegeId: new Types.ObjectId(collegeId),
      semesterId: assessment.semesterId,
      academicYearId: assessment.academicYearId,
      status: 'active',
    };
    if (assessment.sectionId) {
      enrollmentFilter.sectionId = assessment.sectionId;
    }

    const activeEnrollments = await StudentEnrollment.find(enrollmentFilter);
    const marks = await AssessmentMark.find({
      collegeId: new Types.ObjectId(collegeId),
      assessmentId: assessment._id,
    });

    const markMap = new Map<string, any>();
    for (const m of marks) {
      markMap.set(m.studentEnrollmentId.toString(), m);
    }

    let enteredCount = 0;
    let presentCount = 0;
    let absentCount = 0;
    let exemptedCount = 0;
    let notAppearedCount = 0;
    let unresolvedCount = 0;

    for (const enr of activeEnrollments) {
      const m = markMap.get(enr._id.toString());
      const status = m?.status || StudentMarkStatus.NOT_ENTERED;

      if (status === StudentMarkStatus.PRESENT) presentCount++;
      else if (status === StudentMarkStatus.ABSENT) absentCount++;
      else if (status === StudentMarkStatus.EXEMPTED || status === StudentMarkStatus.EXCUSED) exemptedCount++;
      else if (status === StudentMarkStatus.NOT_APPEARED) notAppearedCount++;

      if (status !== StudentMarkStatus.NOT_ENTERED) enteredCount++;
      else unresolvedCount++;
    }

    return {
      assessmentId: assessment._id.toString(),
      title: assessment.title,
      status: assessment.status,
      isLocked: assessment.status === AssessmentStatus.LOCKED || assessment.status === AssessmentStatus.PUBLISHED,
      isSubmitted: assessment.status === AssessmentStatus.SUBMITTED,
      isMarksEntryEligible: eligibility.isEligible,
      examEndDateTime: eligibility.examEndDateTime,
      submittedAt: assessment.submittedAt,
      lockedAt: assessment.lockedAt,
      correctionScope: assessment.correctionScope,
      counts: {
        totalStudents: activeEnrollments.length,
        enteredCount,
        presentCount,
        absentCount,
        exemptedCount,
        notAppearedCount,
        unresolvedCount,
      },
    };
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

    // VULNERABILITY FIX: Strict Faculty Assignment marking ownership
    // HOD, Super Admin, and College Admin cannot enter or modify marks!
    await TeachingAuthorizationService.assertAssessmentMarkingAccess(
      collegeId,
      user,
      assessment
    );

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

    // Synchronize canonical AssessmentMark record
    const enrollment = await StudentEnrollment.findOne({
      collegeId: new Types.ObjectId(collegeId),
      studentId: new Types.ObjectId(studentId),
      semesterId: assessment.semesterId,
      ...(assessment.sectionId ? { sectionId: assessment.sectionId } : {}),
    });

    if (enrollment) {
      await AssessmentMark.findOneAndUpdate(
        {
          collegeId: new Types.ObjectId(collegeId),
          assessmentId: assessment._id,
          studentEnrollmentId: enrollment._id,
        },
        {
          $set: {
            marks: entry.totalMarks,
            status: entry.status,
          },
          $push: {
            auditHistory: {
              action: 'MARK_CORRECTED',
              previousMarks: previousTotal,
              newMarks: cleanNewMark,
              previousStatus: previousStatus,
              newStatus: entry.status,
              performedBy: new Types.ObjectId(user.id),
              performedByName: user.name || 'User',
              performedByRole: user.role,
              reason: reason.trim(),
              timestamp: new Date(),
            },
          },
        }
      ).catch((err) => {
        logger.debug(`Failed to update AssessmentMark on correction: ${err?.message}`);
      });
    }

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
        type: a.assessmentType as AssessmentType,
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
   * Retrieves comprehensive student assessment history across canonical AssessmentMark records
   * and legacy embedded assessment entries, respecting RBAC, tenant isolation, and publication visibility.
   */
  static async getStudentAssessmentHistory(
    collegeId: string,
    user: AuthUserContext,
    targetStudentId: string,
    params?: { semesterId?: string; subjectId?: string }
  ) {
    if (!collegeId) {
      throw ApiError.unauthorized('College context missing');
    }

    const collegeObjId = new Types.ObjectId(collegeId);
    const roleUpper = (user.role || '').toUpperCase();

    // 1. Resolve Target Student
    let student: any = null;
    if (!targetStudentId || targetStudentId === 'me' || targetStudentId === user.id) {
      student = await Student.findOne({
        userId: new Types.ObjectId(user.id),
      });
    } else if (Types.ObjectId.isValid(targetStudentId)) {
      student = await Student.findOne({
        $or: [
          { _id: new Types.ObjectId(targetStudentId) },
          { userId: new Types.ObjectId(targetStudentId) },
        ],
      });
    }

    if (!student) {
      throw ApiError.notFound('Student profile not found');
    }

    // Tenant Isolation
    if (student.collegeId.toString() !== collegeId) {
      throw ApiError.forbidden('Cross-college tenant access is strictly prohibited');
    }

    // 2. Strict Role-Based Access Control
    if (roleUpper === 'STUDENT') {
      if (student.userId.toString() !== user.id) {
        throw ApiError.forbidden('Students can only access their own assessment records');
      }
    } else if (roleUpper === 'COLLEGE_ADMIN') {
      if (user.collegeId && user.collegeId.toString() !== collegeId) {
        throw ApiError.forbidden('Cross-college tenant access is strictly prohibited');
      }
    } else if (roleUpper === 'HOD') {
      if (user.collegeId && user.collegeId.toString() !== collegeId) {
        throw ApiError.forbidden('Cross-college tenant access is strictly prohibited');
      }
      if (user.departmentId && student.departmentId.toString() !== user.departmentId.toString()) {
        throw ApiError.forbidden('HOD cannot access student assessment history outside assigned department');
      }
    } else if (roleUpper === 'FACULTY') {
      if (user.collegeId && user.collegeId.toString() !== collegeId) {
        throw ApiError.forbidden('Cross-college access is strictly prohibited');
      }
      if (user.departmentId && student.departmentId.toString() !== user.departmentId.toString()) {
        throw ApiError.forbidden('Cross-department access is strictly prohibited for faculty');
      }

      // Check faculty teaching scope
      const facultyDoc = await TeachingAuthorizationService.resolveFacultyProfile(collegeId, user);
      if (facultyDoc) {
        const assignments = await FacultyAssignment.find({
          facultyId: facultyDoc._id,
          collegeId: collegeObjId,
          isActive: true,
        });
        const assignedSectionIds = assignments.map((a) => a.sectionId?.toString()).filter(Boolean);
        const assignedSemesterIds = assignments.map((a) => a.semesterId?.toString()).filter(Boolean);

        const activeEnrollment = await StudentEnrollment.findOne({
          studentId: student._id,
          status: 'active',
        });

        const hasTeaching =
          (activeEnrollment &&
            ((activeEnrollment.sectionId &&
              assignedSectionIds.includes(activeEnrollment.sectionId.toString())) ||
              (!activeEnrollment.sectionId &&
                assignedSemesterIds.includes(activeEnrollment.semesterId.toString())))) ||
          (student.sectionId && assignedSectionIds.includes(student.sectionId.toString())) ||
          (!student.sectionId &&
            student.semesterId &&
            assignedSemesterIds.includes(student.semesterId.toString()));

        if (!hasTeaching) {
          throw ApiError.forbidden('Faculty student visibility is limited to authorized teaching contexts');
        }
      }
    }

    // 3. Query Canonical AssessmentMark records
    const markQuery: any = {
      collegeId: collegeObjId,
      studentId: student._id,
    };
    if (params?.subjectId && Types.ObjectId.isValid(params.subjectId)) {
      markQuery.subjectId = new Types.ObjectId(params.subjectId);
    }

    const canonicalMarks = await AssessmentMark.find(markQuery)
      .populate('subjectId', 'name code credits type')
      .sort({ createdAt: -1 })
      .lean();

    const canonicalAssessmentIds = canonicalMarks.map((m) => m.assessmentId);
    const assessments = await InternalAssessment.find({
      _id: { $in: canonicalAssessmentIds },
      collegeId: collegeObjId,
    })
      .populate('subjectId', 'name code credits type')
      .populate('sectionId', 'name')
      .populate('semesterId', 'number')
      .lean();

    const assessmentMap = new Map<string, any>();
    for (const a of assessments) {
      assessmentMap.set(a._id.toString(), a);
    }

    // 4. Query Legacy Embedded Assessment entries (fallback/compatibility)
    const legacyQuery: any = {
      collegeId: collegeObjId,
      'entries.studentId': student._id,
      _id: { $nin: canonicalAssessmentIds },
    };
    if (params?.subjectId && Types.ObjectId.isValid(params.subjectId)) {
      legacyQuery.subjectId = new Types.ObjectId(params.subjectId);
    }

    const legacyAssessments = await InternalAssessment.find(legacyQuery)
      .populate('subjectId', 'name code credits type')
      .populate('sectionId', 'name')
      .populate('semesterId', 'number')
      .lean();

    // 5. Assemble and apply student visibility rules
    const isStudentRole = roleUpper === 'STUDENT';
    const items: any[] = [];
    const processedAssessmentIds = new Set<string>();

    // Process canonical marks
    for (const mark of canonicalMarks) {
      const assessIdStr = mark.assessmentId.toString();
      const assessment = assessmentMap.get(assessIdStr);
      if (!assessment) continue;

      // Semester filter if provided
      if (params?.semesterId && Types.ObjectId.isValid(params.semesterId)) {
        const semId = (assessment.semesterId as any)?._id?.toString() || assessment.semesterId?.toString();
        if (semId !== params.semesterId) {
          continue;
        }
      }

      // Student visibility rule: only PUBLISHED assessments or finalized/locked historical assessments are visible to students
      const isHistorical =
        assessment.sourceType === 'IMPORTED' || assessment.sourceType === 'HISTORICAL_MANUAL';
      const isStudentVisible =
        assessment.status === AssessmentStatus.PUBLISHED ||
        (isHistorical && assessment.status === AssessmentStatus.LOCKED);
      if (isStudentRole && !isStudentVisible) {
        continue;
      }

      processedAssessmentIds.add(assessIdStr);

      const maxMarks = mark.maximumMarks || assessment.maximumMarks || 100;
      const passMarks = mark.passMarks !== undefined ? mark.passMarks : assessment.passMarks;
      const rawMarks = mark.marks; // null if absent/exempted/etc. 0 is valid score!
      const status = mark.status || StudentMarkStatus.ENTERED;

      const isPassed =
        rawMarks !== null && rawMarks !== undefined && passMarks !== undefined && passMarks !== null
          ? rawMarks >= passMarks
          : null;

      const percentage =
        rawMarks !== null && rawMarks !== undefined && maxMarks > 0
          ? Math.round((rawMarks / maxMarks) * 10000) / 100
          : null;

      const subjectObj = assessment.subjectId || mark.subjectId;
      const visibleComponents = (assessment.components || []).filter(
        (c: any) => !isStudentRole || c.isStudentVisible
      );

      const marksMap: Record<string, number | null> = {};
      if (visibleComponents.length > 0) {
        for (const comp of visibleComponents) {
          marksMap[comp.key] = rawMarks;
        }
      }

      items.push({
        id: mark._id.toString(),
        assessmentId: assessIdStr,
        title: assessment.title,
        category: assessment.assessmentType,
        subject: subjectObj,
        section: assessment.sectionId || null,
        semester: assessment.semesterId || null,
        publishedAt: assessment.publishedAt || null,
        examDate: (assessment as any).date || (assessment as any).schedule?.date || assessment.createdAt,
        marks: marksMap,
        rawScore: rawMarks,
        totalMarks: rawMarks !== null ? rawMarks : 0,
        maximumMarks: maxMarks,
        passMarks: passMarks ?? null,
        status,
        isPassed,
        percentage,
        isLocked: mark.isLocked || false,
        assessmentStatus: assessment.status,
        sourceType: mark.sourceType || assessment.sourceType || 'LIVE',
        importBatchId: mark.importBatchId || assessment.importBatchId || null,
        remarks: mark.remarks || null,
        components: visibleComponents,
        auditHistory: !isStudentRole ? mark.auditHistory : undefined,
      });
    }

    // Process legacy embedded marks
    for (const a of legacyAssessments) {
      const assessIdStr = a._id.toString();
      if (processedAssessmentIds.has(assessIdStr)) continue;

      if (params?.semesterId && Types.ObjectId.isValid(params.semesterId)) {
        const semId = (a.semesterId as any)?._id?.toString() || a.semesterId?.toString();
        if (semId !== params.semesterId) {
          continue;
        }
      }

      if (isStudentRole && a.status !== AssessmentStatus.PUBLISHED) {
        continue;
      }

      const entry = a.entries.find((e: any) => e.studentId.toString() === student._id.toString());
      if (!entry) continue;

      processedAssessmentIds.add(assessIdStr);

      const maxMarks = a.maximumMarks || 100;
      const passMarks = a.passMarks;
      const rawMarks = entry.totalMarks !== undefined ? entry.totalMarks : null;
      const status = entry.status || StudentMarkStatus.ENTERED;

      const isPassed =
        rawMarks !== null && rawMarks !== undefined && passMarks !== undefined && passMarks !== null
          ? rawMarks >= passMarks
          : null;

      const percentage =
        rawMarks !== null && rawMarks !== undefined && maxMarks > 0
          ? Math.round((rawMarks / maxMarks) * 10000) / 100
          : null;

      const visibleComponents = (a.components || []).filter(
        (c: any) => !isStudentRole || c.isStudentVisible
      );

      const marksMap: Record<string, number | null> = {};
      for (const comp of visibleComponents) {
        marksMap[comp.key] = entry.componentMarks ? entry.componentMarks[comp.key] ?? null : null;
      }

      items.push({
        id: `${assessIdStr}_legacy`,
        assessmentId: assessIdStr,
        title: a.title,
        category: a.assessmentType,
        subject: a.subjectId,
        section: a.sectionId || null,
        semester: a.semesterId || null,
        publishedAt: a.publishedAt || null,
        examDate: (a as any).date || (a as any).schedule?.date || a.createdAt,
        marks: marksMap,
        rawScore: rawMarks,
        totalMarks: rawMarks !== null ? rawMarks : 0,
        maximumMarks: maxMarks,
        passMarks: passMarks ?? null,
        status,
        isPassed,
        percentage,
        isLocked: a.status === AssessmentStatus.LOCKED,
        assessmentStatus: a.status,
        sourceType: a.sourceType || 'LIVE',
        importBatchId: a.importBatchId || null,
        remarks: entry.remarks || null,
        components: visibleComponents,
      });
    }

    return {
      student: {
        id: student._id.toString(),
        name: student.name,
        rollNumber: student.rollNumber,
      },
      items,
      totalCount: items.length,
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
    const history = await this.getStudentAssessmentHistory(collegeId, user, 'me', params);
    return { items: history.items };
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
        $or: [
          { sectionId: new Types.ObjectId(params.sectionId) },
          { 'academicScopes.sectionId': new Types.ObjectId(params.sectionId) },
        ],
        subjectId: new Types.ObjectId(params.subjectId),
        status: { $ne: AssessmentStatus.ARCHIVED },
      }).sort({ createdAt: -1 });
    }

    return null;
  }

  /**
   * Helper: Emit persistent notification to students when marks are published
   */
  /**
   * Lists accessible assessments matching filters for the college.
   */
  static async listAssessments(
    collegeId: string,
    user: AuthUserContext,
    filters: {
      facultyAssignmentId?: string;
      sectionId?: string;
      subjectId?: string;
      semesterId?: string;
      academicYearId?: string;
      status?: AssessmentStatus;
      assessmentType?: AssessmentType;
    }
  ) {
    const query: any = { collegeId: new Types.ObjectId(collegeId) };
    if (filters.facultyAssignmentId && Types.ObjectId.isValid(filters.facultyAssignmentId)) {
      query.facultyAssignmentId = new Types.ObjectId(filters.facultyAssignmentId);
    }
    if (filters.sectionId && Types.ObjectId.isValid(filters.sectionId)) {
      query.$or = [
        { sectionId: new Types.ObjectId(filters.sectionId) },
        { 'academicScopes.sectionId': new Types.ObjectId(filters.sectionId) },
      ];
    }
    if (filters.subjectId && Types.ObjectId.isValid(filters.subjectId)) {
      query.subjectId = new Types.ObjectId(filters.subjectId);
    }
    if (filters.semesterId && Types.ObjectId.isValid(filters.semesterId)) {
      query.semesterId = new Types.ObjectId(filters.semesterId);
    }
    if (filters.academicYearId && Types.ObjectId.isValid(filters.academicYearId)) {
      query.academicYearId = new Types.ObjectId(filters.academicYearId);
    }
    if (filters.status) {
      query.status = filters.status;
    }
    if (filters.assessmentType) {
      query.assessmentType = filters.assessmentType;
    }

    const roleUpper = (user.role || '').toUpperCase();
    if (roleUpper === 'STUDENT') {
      const student = await Student.findOne({
        collegeId: new Types.ObjectId(collegeId),
        userId: new Types.ObjectId(user.id),
      });

      const studentAllowedStatuses = [
        AssessmentStatus.SCHEDULED,
        AssessmentStatus.PUBLISHED,
        AssessmentStatus.COMPLETED,
        AssessmentStatus.MARKS_ENTRY,
        AssessmentStatus.SUBMITTED,
        AssessmentStatus.REVIEWED,
      ];

      if (student) {
        const enrollments = await StudentEnrollment.find({
          collegeId: new Types.ObjectId(collegeId),
          studentId: student._id,
          status: 'active',
        });
        const sectionIds = enrollments.map((e) => e.sectionId).filter(Boolean) as Types.ObjectId[];
        const semesterIds = enrollments.map((e) => e.semesterId).filter(Boolean) as Types.ObjectId[];

        query.$and = [
          { status: { $in: studentAllowedStatuses } },
          {
            $or: [
              { sectionId: { $in: sectionIds } },
              { 'academicScopes.sectionId': { $in: sectionIds } },
              { 'entries.studentId': student._id },
              { semesterId: { $in: semesterIds }, sectionId: null },
            ],
          },
        ];
      } else {
        query.status = AssessmentStatus.PUBLISHED;
      }
    }

    return InternalAssessment.find(query)
      .select('-entries')
      .populate('subjectId', 'name code type')
      .populate('sectionId', 'name')
      .populate('facultyAssignmentId', 'facultyName')
      .sort({ createdAt: -1 });
  }

  /**
   * Retrieves an Assessment by ID, including its date-specific schedule if any.
   */
  static async getAssessmentById(
    collegeId: string,
    user: AuthUserContext,
    assessmentId: string
  ) {
    if (!Types.ObjectId.isValid(assessmentId)) {
      throw ApiError.badRequest('Invalid assessment ID format');
    }

    const assessment = await InternalAssessment.findOne({
      _id: new Types.ObjectId(assessmentId),
      collegeId: new Types.ObjectId(collegeId),
    })
      .populate('subjectId')
      .populate('sectionId')
      .populate('facultyAssignmentId');

    if (!assessment) {
      throw ApiError.notFound('Assessment not found');
    }

    const roleUpper = (user.role || '').toUpperCase();
    if (roleUpper === 'STUDENT') {
      if (assessment.status === AssessmentStatus.DRAFT) {
        throw ApiError.forbidden('This assessment is currently in draft and not accessible to students.');
      }
      const student = await Student.findOne({
        collegeId: new Types.ObjectId(collegeId),
        userId: new Types.ObjectId(user.id),
      });

      if (assessment.status === AssessmentStatus.PUBLISHED && student) {
        assessment.entries = assessment.entries.filter(
          (e) => e.studentId.toString() === student._id.toString()
        );
      } else {
        // Strip other students' marks while evaluation is ongoing
        assessment.entries = [];
      }
    }

    const schedule = await AssessmentSchedule.findOne({
      collegeId: new Types.ObjectId(collegeId),
      assessmentId: assessment._id,
    })
      .populate('roomId', 'name code capacity')
      .populate('invigilatorFacultyId', 'name email');

    return {
      assessment,
      schedule,
    };
  }

  /**
   * Updates assessment metadata.
   */
  static async updateAssessment(
    collegeId: string,
    user: AuthUserContext,
    assessmentId: string,
    updates: Partial<CreateAssessmentPayload> & { status?: AssessmentStatus }
  ) {
    if (!Types.ObjectId.isValid(assessmentId)) {
      throw ApiError.badRequest('Invalid assessment ID format');
    }

    const assessment = await InternalAssessment.findOne({
      _id: new Types.ObjectId(assessmentId),
      collegeId: new Types.ObjectId(collegeId),
    });

    if (!assessment) {
      throw ApiError.notFound('Assessment not found');
    }

    await TeachingAuthorizationService.assertAssessmentManagementAccess(
      collegeId,
      user,
      assessment,
      'updating this assessment'
    );

    if (
      assessment.status === AssessmentStatus.PUBLISHED ||
      assessment.status === AssessmentStatus.LOCKED
    ) {
      const roleUpper = (user.role || '').toUpperCase();
      if (roleUpper !== 'SUPER_ADMIN' && roleUpper !== 'COLLEGE_ADMIN') {
        throw ApiError.forbidden(
          'Only administrators can update a published or locked assessment.'
        );
      }
    }

    if (updates.title) assessment.title = updates.title.trim();
    if (updates.description !== undefined) assessment.description = updates.description;
    if (updates.assessmentType) assessment.assessmentType = updates.assessmentType;
    if (updates.maximumMarks !== undefined) assessment.maximumMarks = updates.maximumMarks;
    if (updates.passMarks !== undefined) assessment.passMarks = updates.passMarks;
    if (updates.weightage !== undefined) assessment.weightage = updates.weightage;
    if (updates.components) assessment.components = updates.components;
    if (updates.assessmentDate) {
      assessment.assessmentDate = new Date(updates.assessmentDate);
    }

    assessment.auditLog.push({
      action: 'METADATA_UPDATED',
      performedBy: new Types.ObjectId(user.id),
      performedByName: user.name || 'User',
      performedByRole: user.role,
      timestamp: new Date(),
      details: 'Assessment metadata updated',
    });

    await assessment.save();
    return assessment;
  }

  /**
   * Schedules a date-specific assessment occurrence.
   * Performs real date-time conflict detection across rooms, sections, and invigilators.
   * Projects authoritative event to CalendarEvent without making Calendar the source of truth.
   */
  static async scheduleAssessment(
    collegeId: string,
    user: AuthUserContext,
    payload: ScheduleAssessmentPayload
  ) {
    const { assessmentId, date, startTime, endTime, roomId, invigilatorFacultyId, instructions } =
      payload;

    if (!Types.ObjectId.isValid(assessmentId)) {
      throw ApiError.badRequest('Invalid assessment ID format');
    }

    const assessment = await InternalAssessment.findOne({
      _id: new Types.ObjectId(assessmentId),
      collegeId: new Types.ObjectId(collegeId),
    });

    if (!assessment) {
      throw ApiError.notFound('Assessment not found');
    }

    // Authorize management access (Admin, HOD in department, or assigned Faculty)
    await TeachingAuthorizationService.assertAssessmentManagementAccess(
      collegeId,
      user,
      assessment,
      'scheduling this assessment'
    );

    if (!startTime || !endTime) {
      throw ApiError.badRequest('startTime and endTime are required for exam schedule');
    }
    const [sh, sm] = startTime.split(':').map(Number);
    const [eh, em] = endTime.split(':').map(Number);
    if (isNaN(sh) || isNaN(sm) || isNaN(eh) || isNaN(em) || eh * 60 + em <= sh * 60 + sm) {
      throw ApiError.badRequest('endTime must be strictly later than startTime');
    }

    const dateObj = new Date(date);
    if (isNaN(dateObj.getTime())) {
      throw ApiError.badRequest('Invalid date format for exam schedule');
    }
    const dateString =
      typeof date === 'string' && date.length === 10
        ? date
        : dateObj.toISOString().split('T')[0];

    if (roomId) {
      if (!Types.ObjectId.isValid(roomId)) {
        throw ApiError.badRequest('Invalid room ID format');
      }
      const roomDoc = await Room.findOne({
        _id: new Types.ObjectId(roomId),
        collegeId: new Types.ObjectId(collegeId),
      });
      if (!roomDoc) {
        throw ApiError.notFound('Exam room not found in this college');
      }
    }

    // Conflict detection across dateString and [startTime, endTime)
    const potentialConflicts = await AssessmentSchedule.find({
      collegeId: new Types.ObjectId(collegeId),
      dateString,
      status: 'SCHEDULED',
      assessmentId: { $ne: assessment._id },
    });

    for (const conf of potentialConflicts) {
      const isOverlapping = conf.startTime < endTime && conf.endTime > startTime;
      if (!isOverlapping) continue;

      if (roomId && conf.roomId && conf.roomId.toString() === roomId.toString()) {
        throw ApiError.conflict(
          'The selected room is already booked for another assessment during this time slot.'
        );
      }
      
      const thisSectionIds = [
        assessment.sectionId ? assessment.sectionId.toString() : null,
        ...((assessment.academicScopes || []).map((s) => (s.sectionId ? s.sectionId.toString() : null))),
      ].filter(Boolean) as string[];

      const confSectionIds = [
        conf.sectionId ? conf.sectionId.toString() : null,
        ...((conf.targetSectionIds || []).map((s: any) => (s ? s.toString() : null))),
      ].filter(Boolean) as string[];

      const hasSectionOverlap = thisSectionIds.length > 0 && confSectionIds.length > 0 && thisSectionIds.some((id) => confSectionIds.includes(id));
      if (hasSectionOverlap) {
        throw ApiError.conflict(
          'The selected section already has another assessment scheduled during this time slot.'
        );
      }

      if (
        invigilatorFacultyId &&
        conf.invigilatorFacultyId &&
        conf.invigilatorFacultyId.toString() === invigilatorFacultyId.toString()
      ) {
        throw ApiError.conflict(
          'The assigned invigilator is already scheduled for another assessment during this time slot.'
        );
      }
    }

    const allSectionObjectIds = [
      assessment.sectionId ? assessment.sectionId : null,
      ...((assessment.academicScopes || []).map((s) => s.sectionId || null)),
    ].filter(Boolean) as Types.ObjectId[];

    const allDeptObjectIds = [
      assessment.departmentId ? assessment.departmentId : null,
      ...((assessment.academicScopes || []).map((s) => s.departmentId || null)),
    ].filter(Boolean) as Types.ObjectId[];

    // Upsert AssessmentSchedule record
    const schedule = await AssessmentSchedule.findOneAndUpdate(
      { collegeId: new Types.ObjectId(collegeId), assessmentId: assessment._id },
      {
        $set: {
          departmentId: assessment.departmentId,
          courseId: assessment.courseId,
          academicYearId: assessment.academicYearId,
          semesterId: assessment.semesterId,
          sectionId: assessment.sectionId,
          targetSectionIds: allSectionObjectIds,
          targetDepartmentIds: allDeptObjectIds,
          subjectId: assessment.subjectId,
          facultyAssignmentId: assessment.facultyAssignmentId,
          date: dateObj,
          dateString,
          startTime,
          endTime,
          roomId: roomId && Types.ObjectId.isValid(roomId) ? new Types.ObjectId(roomId) : null,
          invigilatorFacultyId:
            invigilatorFacultyId && Types.ObjectId.isValid(invigilatorFacultyId)
              ? new Types.ObjectId(invigilatorFacultyId)
              : null,
          instructions: instructions || '',
          status: 'SCHEDULED',
          updatedBy: new Types.ObjectId(user.id),
        },
        $setOnInsert: {
          createdBy: new Types.ObjectId(user.id),
        },
      },
      { upsert: true, new: true }
    );

    // Synchronize assessment state and embedded schedule
    if (assessment.status === AssessmentStatus.DRAFT) {
      assessment.status = AssessmentStatus.SCHEDULED;
    }
    assessment.schedule = {
      date: dateObj,
      startTime,
      endTime,
      roomId: roomId && Types.ObjectId.isValid(roomId) ? new Types.ObjectId(roomId) : undefined,
      invigilatorFacultyId:
        invigilatorFacultyId && Types.ObjectId.isValid(invigilatorFacultyId)
          ? new Types.ObjectId(invigilatorFacultyId)
          : undefined,
      instructions,
    };
    assessment.assessmentDate = dateObj;
    await assessment.save();

    // Authoritative CalendarEvent projection
    try {
      await CalendarEvent.findOneAndUpdate(
        {
          collegeId: new Types.ObjectId(collegeId),
          sourceType: CalendarSourceType.ASSESSMENT,
          sourceId: assessment._id.toString(),
        },
        {
          $set: {
            title: `Assessment: ${assessment.title}`,
            description:
              instructions ||
              `Scheduled exam for ${assessment.title} (${startTime} - ${endTime})`,
            eventType: CalendarEventType.INTERNAL_ASSESSMENT,
            scope: CalendarEventScope.CLASS,
            startDate: dateString,
            endDate: dateString,
            startTime,
            endTime,
            allDay: false,
            departmentId: assessment.departmentId,
            courseId: assessment.courseId,
            academicYearId: assessment.academicYearId,
            semesterId: assessment.semesterId,
            sectionId: assessment.sectionId,
            subjectId: assessment.subjectId,
            facultyAssignmentId: assessment.facultyAssignmentId,
            location: roomId ? `Room ${roomId}` : null,
            status: 'PUBLISHED',
            academicContext: assessment.title,
          },
          $setOnInsert: {
            createdBy: new Types.ObjectId(user.id),
            creatorRole: user.role || 'FACULTY',
            creatorName: user.name || 'Faculty',
          },
        },
        { upsert: true }
      );
    } catch (e: any) {
      logger.warn(`Failed to project CalendarEvent for assessment ${assessment._id}: ${e?.message}`);
    }

    return schedule;
  }

  /**
   * Retrieves the schedule for a specific assessment.
   */
  static async getAssessmentSchedule(collegeId: string, assessmentId: string) {
    if (!Types.ObjectId.isValid(assessmentId)) {
      throw ApiError.badRequest('Invalid assessment ID format');
    }

    return AssessmentSchedule.findOne({
      collegeId: new Types.ObjectId(collegeId),
      assessmentId: new Types.ObjectId(assessmentId),
    })
      .populate('roomId', 'name code capacity')
      .populate('invigilatorFacultyId', 'name email');
  }

  /**
   * Cancels a scheduled assessment.
   */
  static async cancelAssessmentSchedule(
    collegeId: string,
    user: AuthUserContext,
    assessmentId: string
  ) {
    if (!Types.ObjectId.isValid(assessmentId)) {
      throw ApiError.badRequest('Invalid assessment ID format');
    }

    const assessment = await InternalAssessment.findOne({
      _id: new Types.ObjectId(assessmentId),
      collegeId: new Types.ObjectId(collegeId),
    });

    if (!assessment) {
      throw ApiError.notFound('Assessment not found');
    }

    await TeachingAuthorizationService.assertAssessmentManagementAccess(
      collegeId,
      user,
      assessment,
      'cancelling schedule'
    );

    await AssessmentSchedule.deleteOne({
      collegeId: new Types.ObjectId(collegeId),
      assessmentId: assessment._id,
    });

    assessment.schedule = undefined;
    if (assessment.status === AssessmentStatus.SCHEDULED) {
      assessment.status = AssessmentStatus.DRAFT;
    }
    assessment.auditLog.push({
      action: 'SCHEDULE_CANCELLED',
      performedBy: new Types.ObjectId(user.id),
      performedByName: user.name || 'User',
      performedByRole: user.role || 'FACULTY',
      timestamp: new Date(),
      details: 'Assessment schedule was cancelled',
    });
    await assessment.save();

    await CalendarEvent.deleteOne({
      collegeId: new Types.ObjectId(collegeId),
      sourceType: CalendarSourceType.ASSESSMENT,
      sourceId: assessment._id.toString(),
    });

    // Notify enrolled students of cancellation
    try {
      const studentIds = assessment.entries.map((e) => e.studentId);
      const students = await Student.find({
        _id: { $in: studentIds },
        userId: { $ne: null },
      }).select('userId');

      for (const s of students) {
        if (s.userId) {
          await NotificationService.createNotification({
            collegeId,
            recipientUserId: s.userId.toString(),
            recipientRole: AppRole.STUDENT,
            notificationType: NotificationType.TIMETABLE_CANCELLED,
            category: NotificationCategory.ASSESSMENT,
            priority: NotificationPriority.HIGH,
            title: `Exam Cancelled: ${assessment.title}`,
            body: `The examination scheduled for ${assessment.title} has been cancelled.`,
            deepLink: '/assessments',
            metadata: { assessmentId: assessment._id.toString() },
          }).catch((err: any) => logger.warn(`Failed to send cancellation notification: ${err?.message}`));
        }
      }
    } catch (err: any) {
      logger.warn(`Error emitting cancellation notification: ${err?.message}`);
    }

    return { message: 'Assessment schedule cancelled successfully' };
  }

  /**
   * Previews scope resolution, student counts, and detects duplicate students across scopes
   * for common examinations spanning multiple departments/sections.
   */
  static async previewScope(
    collegeId: string,
    user: AuthUserContext,
    payload: PreviewScopePayload
  ) {
    const { subjectId, academicScopes } = payload;
    if (!subjectId || !Types.ObjectId.isValid(subjectId)) {
      throw ApiError.badRequest('Invalid or missing subjectId');
    }
    if (!Array.isArray(academicScopes) || academicScopes.length === 0) {
      throw ApiError.badRequest('At least one academic scope must be provided');
    }

    const authorizedScopes: Array<{
      departmentId: string;
      departmentName: string;
      courseId: string;
      courseName?: string;
      semesterId: string;
      semesterNumber?: number;
      sectionId?: string | null;
      sectionName?: string | null;
      studentCount: number;
    }> = [];

    const allEnrollmentQueries: any[] = [];
    let grossStudentCount = 0;

    for (const sc of academicScopes) {
      if (!sc.departmentId || !sc.courseId || !sc.academicYearId || !sc.semesterId) {
        throw ApiError.badRequest('Incomplete academic hierarchy in one of the scopes');
      }

      // Assert teaching context authorization for this scope
      if (sc.facultyAssignmentId) {
        await TeachingAuthorizationService.assertAssessmentCreationAccess(
          collegeId,
          user,
          sc.facultyAssignmentId
        );
      } else {
        await TeachingAuthorizationService.assertSubjectSectionAccess(
          collegeId,
          user,
          subjectId,
          sc.sectionId || null,
          'assessments for this teaching context'
        );
      }

      const deptDoc = await Department.findById(sc.departmentId).select('name');
      const secDoc = sc.sectionId ? await Section.findById(sc.sectionId).select('name') : null;
      const courseDoc = await Course.findById(sc.courseId).select('name');

      const scQuery: any = {
        collegeId: new Types.ObjectId(collegeId),
        semesterId: new Types.ObjectId(sc.semesterId),
        academicYearId: new Types.ObjectId(sc.academicYearId),
        status: 'active',
      };
      if (sc.sectionId) {
        scQuery.sectionId = new Types.ObjectId(sc.sectionId);
      }
      allEnrollmentQueries.push(scQuery);

      const count = await StudentEnrollment.countDocuments(scQuery);
      grossStudentCount += count;

      authorizedScopes.push({
        departmentId: sc.departmentId,
        departmentName: deptDoc?.name || sc.departmentName || 'Department',
        courseId: sc.courseId,
        courseName: courseDoc?.name || undefined,
        semesterId: sc.semesterId,
        semesterNumber: sc.semesterNumber || undefined,
        sectionId: sc.sectionId || null,
        sectionName: secDoc?.name || sc.sectionName || null,
        studentCount: count,
      });
    }

    // Resolve unique students across all scopes to detect duplicates
    const allEnrollments = await StudentEnrollment.find({
      $or: allEnrollmentQueries,
    }).populate('studentId', 'name rollNumber admissionNumber');

    const seenIds = new Set<string>();
    const studentsPreview: Array<{
      studentId: string;
      name: string;
      rollNumber?: string;
      admissionNumber?: string;
    }> = [];

    for (const enr of allEnrollments) {
      if (!enr.studentId) continue;
      const s = enr.studentId as any;
      const sId = (s._id ? s._id : s).toString();
      if (!seenIds.has(sId)) {
        seenIds.add(sId);
        if (studentsPreview.length < 50) {
          studentsPreview.push({
            studentId: sId,
            name: s.name || 'Student',
            rollNumber: s.rollNumber || undefined,
            admissionNumber: s.admissionNumber || undefined,
          });
        }
      }
    }

    const totalEligibleStudents = seenIds.size;
    const duplicateStudentCount = grossStudentCount - totalEligibleStudents;

    return {
      authorizedScopes,
      totalEligibleStudents,
      duplicateStudentCount: duplicateStudentCount > 0 ? duplicateStudentCount : 0,
      studentsPreview,
    };
  }

  /**
   * Conflict detection checking room, invigilator, and student group / section overlap.
   */
  static async checkScheduleConflicts(
    collegeId: string,
    _user: AuthUserContext,
    payload: CheckScheduleConflictsPayload
  ) {
    const { date, startTime, endTime, roomId, invigilatorFacultyId, targetSectionIds, assessmentId } =
      payload;

    if (!startTime || !endTime) {
      throw ApiError.badRequest('startTime and endTime are required');
    }
    const [sh, sm] = startTime.split(':').map(Number);
    const [eh, em] = endTime.split(':').map(Number);
    if (isNaN(sh) || isNaN(sm) || isNaN(eh) || isNaN(em) || eh * 60 + em <= sh * 60 + sm) {
      throw ApiError.badRequest('endTime must be strictly later than startTime');
    }

    const dateObj = new Date(date);
    if (isNaN(dateObj.getTime())) {
      throw ApiError.badRequest('Invalid date format');
    }
    const dateString =
      typeof date === 'string' && date.length === 10
        ? date
        : dateObj.toISOString().split('T')[0];

    const query: any = {
      collegeId: new Types.ObjectId(collegeId),
      dateString,
      status: 'SCHEDULED',
    };
    if (assessmentId && Types.ObjectId.isValid(assessmentId)) {
      query.assessmentId = { $ne: new Types.ObjectId(assessmentId) };
    }

    const potentialConflicts = await AssessmentSchedule.find(query).populate('assessmentId', 'title');
    const conflicts: Array<{
      type: 'ROOM' | 'INVIGILATOR' | 'SECTION';
      entityId?: string;
      conflictingAssessmentId: string;
      conflictingTitle: string;
      timeSlot: string;
      message: string;
    }> = [];

    for (const conf of potentialConflicts) {
      const isOverlapping = conf.startTime < endTime && conf.endTime > startTime;
      if (!isOverlapping) continue;

      const title = (conf.assessmentId as any)?.title || 'Assessment';
      const timeSlot = `${conf.startTime} - ${conf.endTime}`;

      if (roomId && conf.roomId && conf.roomId.toString() === roomId.toString()) {
        conflicts.push({
          type: 'ROOM',
          entityId: roomId.toString(),
          conflictingAssessmentId: conf.assessmentId?._id?.toString() || conf.assessmentId?.toString() || '',
          conflictingTitle: title,
          timeSlot,
          message: `The selected room is booked for '${title}' during ${timeSlot}.`,
        });
      }

      if (
        invigilatorFacultyId &&
        conf.invigilatorFacultyId &&
        conf.invigilatorFacultyId.toString() === invigilatorFacultyId.toString()
      ) {
        conflicts.push({
          type: 'INVIGILATOR',
          entityId: invigilatorFacultyId.toString(),
          conflictingAssessmentId: conf.assessmentId?._id?.toString() || conf.assessmentId?.toString() || '',
          conflictingTitle: title,
          timeSlot,
          message: `The assigned invigilator is scheduled for '${title}' during ${timeSlot}.`,
        });
      }

      if (targetSectionIds && targetSectionIds.length > 0) {
        const confSections = [
          conf.sectionId ? conf.sectionId.toString() : null,
          ...((conf.targetSectionIds || []).map((s: any) => (s ? s.toString() : null))),
        ].filter(Boolean);

        for (const secId of targetSectionIds) {
          if (confSections.includes(secId.toString())) {
            conflicts.push({
              type: 'SECTION',
              entityId: secId.toString(),
              conflictingAssessmentId: conf.assessmentId?._id?.toString() || conf.assessmentId?.toString() || '',
              conflictingTitle: title,
              timeSlot,
              message: `An academic section included in this assessment already has another examination ('${title}') scheduled during ${timeSlot}.`,
            });
            break;
          }
        }
      }
    }

    return {
      hasConflicts: conflicts.length > 0,
      conflicts,
    };
  }

  /**
   * Publishes an assessment to students and triggers targeted notifications.
   */
  static async publishAssessment(
    collegeId: string,
    user: AuthUserContext,
    assessmentId: string
  ) {
    if (!Types.ObjectId.isValid(assessmentId)) {
      throw ApiError.badRequest('Invalid assessment ID format');
    }
    const assessment = await InternalAssessment.findOne({
      _id: new Types.ObjectId(assessmentId),
      collegeId: new Types.ObjectId(collegeId),
    }).populate('subjectId', 'name code');

    if (!assessment) {
      throw ApiError.notFound('Assessment not found');
    }

    await TeachingAuthorizationService.assertAssessmentManagementAccess(
      collegeId,
      user,
      assessment,
      'publishing this assessment'
    );

    if (assessment.status === AssessmentStatus.ARCHIVED) {
      throw ApiError.badRequest('Cannot publish an archived assessment');
    }

    assessment.status = AssessmentStatus.SCHEDULED;
    assessment.isPublishedToStudents = true;
    assessment.auditLog.push({
      action: 'EXAM_PUBLISHED',
      performedBy: new Types.ObjectId(user.id),
      performedByName: user.name || 'User',
      performedByRole: user.role || 'FACULTY',
      timestamp: new Date(),
      details: `Assessment '${assessment.title}' published to students and schedule confirmed.`,
    });
    await assessment.save();

    // Idempotent Notification to all enrolled students
    try {
      const studentIds = assessment.entries.map((e) => e.studentId);
      const students = await Student.find({
        _id: { $in: studentIds },
        userId: { $ne: null },
      }).select('userId');

      const subjectName = (assessment.subjectId as any)?.name || 'Subject';
      const scheduleInfo = assessment.schedule
        ? ` on ${assessment.schedule.date ? new Date(assessment.schedule.date).toLocaleDateString() : ''} (${assessment.schedule.startTime || ''} - ${assessment.schedule.endTime || ''})`
        : '';

      for (const s of students) {
        if (s.userId) {
          await NotificationService.createNotification({
            collegeId,
            recipientUserId: s.userId.toString(),
            recipientRole: AppRole.STUDENT,
            notificationType: NotificationType.ASSESSMENT_PUBLISHED,
            category: NotificationCategory.ASSESSMENT,
            priority: NotificationPriority.HIGH,
            title: `Exam Scheduled: ${assessment.title}`,
            body: `${assessment.title} for ${subjectName} has been scheduled${scheduleInfo}. Tap to view venue and instructions.`,
            deepLink: `/assessments`,
            metadata: {
              assessmentId: assessment._id.toString(),
              subjectId: assessment.subjectId ? (assessment.subjectId as any)._id?.toString() || assessment.subjectId.toString() : '',
            },
            idempotencyKey: `assessment_pub_${assessment._id.toString()}_${s.userId.toString()}`,
          }).catch((err: any) => logger.warn(`Failed to send exam published notification: ${err?.message}`));
        }
      }
    } catch (err: any) {
      logger.warn(`Error emitting assessment published notifications: ${err?.message}`);
    }

    return assessment;
  }

  /**
   * Queries date-specific exam timetables across sections, semesters, and date ranges.
   */
  static async getExamTimetable(
    collegeId: string,
    params: { sectionId?: string; semesterId?: string; dateFrom?: string; dateTo?: string }
  ) {
    const query: any = {
      collegeId: new Types.ObjectId(collegeId),
      status: 'SCHEDULED',
    };

    if (params.sectionId && Types.ObjectId.isValid(params.sectionId)) {
      query.$or = [
        { sectionId: new Types.ObjectId(params.sectionId) },
        { targetSectionIds: new Types.ObjectId(params.sectionId) },
      ];
    }
    if (params.semesterId && Types.ObjectId.isValid(params.semesterId)) {
      query.semesterId = new Types.ObjectId(params.semesterId);
    }
    if (params.dateFrom || params.dateTo) {
      query.dateString = {};
      if (params.dateFrom) query.dateString.$gte = params.dateFrom;
      if (params.dateTo) query.dateString.$lte = params.dateTo;
    }

    return AssessmentSchedule.find(query)
      .populate('assessmentId', 'title maximumMarks passMarks assessmentType status')
      .populate('subjectId', 'name code credits type')
      .populate('roomId', 'name code capacity')
      .populate('invigilatorFacultyId', 'name email')
      .sort({ dateString: 1, startTime: 1 });
  }

  /**
   * Idempotent migration utility from legacy InternalAssessment embedded entries to canonical AssessmentMark records.
   * Resolves StudentEnrollment for each studentId within exact academic context.
   * Supports dry-run and detailed reporting of unresolved students.
   */
  static async runMigration(
    collegeId?: string,
    dryRun: boolean = true
  ): Promise<MigrationReport> {
    const query: any = {};
    if (collegeId && Types.ObjectId.isValid(collegeId)) {
      query.collegeId = new Types.ObjectId(collegeId);
    }

    const legacyAssessments = await InternalAssessment.find(query);

    const report: MigrationReport = {
      recordsDiscovered: legacyAssessments.length,
      assessmentsProcessed: 0,
      assessmentsMigrated: 0,
      marksMigrated: 0,
      unresolvedStudents: [],
      duplicateConflicts: 0,
      invalidRecords: 0,
      skippedRecords: 0,
      dryRun,
      errors: [],
    };

    for (const assess of legacyAssessments) {
      report.assessmentsProcessed++;

      // 1. Resolve missing facultyAssignmentId if possible
      if (!assess.facultyAssignmentId && assess.subjectId && assess.sectionId) {
        const fa = await FacultyAssignment.findOne({
          collegeId: assess.collegeId,
          subjectId: assess.subjectId,
          sectionId: assess.sectionId,
          isActive: true,
        });
        if (fa && !dryRun) {
          assess.facultyAssignmentId = fa._id;
          await assess.save();
        }
      }

      // 2. Migrate embedded marks to canonical AssessmentMark records
      let assessMarksCount = 0;
      for (const entry of assess.entries || []) {
        if (!entry.studentId) {
          report.invalidRecords++;
          continue;
        }

        // Canonical enrollment resolution: exact college + semester + section
        const enrollmentQuery: any = {
          collegeId: assess.collegeId,
          studentId: entry.studentId,
          semesterId: assess.semesterId,
        };
        if (assess.sectionId) {
          enrollmentQuery.sectionId = assess.sectionId;
        }

        const enrollment = await StudentEnrollment.findOne(enrollmentQuery);

        if (!enrollment) {
          report.unresolvedStudents.push({
            assessmentId: assess._id.toString(),
            studentId: entry.studentId.toString(),
            studentName: entry.studentName,
            reason: `Active StudentEnrollment not found for semester ${assess.semesterId} and section ${assess.sectionId}`,
          });
          continue;
        }

        // Check idempotency: does canonical record already exist?
        const existingMark = await AssessmentMark.findOne({
          collegeId: assess.collegeId,
          assessmentId: assess._id,
          studentEnrollmentId: enrollment._id,
        });

        if (existingMark) {
          report.skippedRecords++;
          continue;
        }

        if (!dryRun) {
          try {
            await AssessmentMark.create({
              collegeId: assess.collegeId,
              assessmentId: assess._id,
              facultyAssignmentId: assess.facultyAssignmentId || null,
              subjectId: assess.subjectId,
              studentEnrollmentId: enrollment._id,
              studentId: entry.studentId,
              studentName: entry.studentName || 'Student',
              rollNumber: entry.rollNumber,
              admissionNumber: entry.admissionNumber,
              marks:
                entry.totalMarks !== undefined && entry.totalMarks !== null
                  ? entry.totalMarks
                  : null,
              maximumMarks: assess.maximumMarks || 100,
              passMarks: assess.passMarks,
              status: entry.status || StudentMarkStatus.ENTERED,
              remarks: entry.remarks,
              isLocked:
                assess.status === AssessmentStatus.PUBLISHED ||
                assess.status === AssessmentStatus.CLOSED ||
                assess.status === AssessmentStatus.LOCKED,
              sourceType: 'LIVE',
              auditHistory: [
                {
                  action: 'MIGRATED_FROM_INTERNAL_ASSESSMENT',
                  previousMarks: null,
                  newMarks: entry.totalMarks,
                  newStatus: entry.status,
                  performedBy: assess.createdBy || new Types.ObjectId(),
                  reason: 'Idempotent canonical migration from legacy embedded entries',
                  timestamp: new Date(),
                },
              ],
            });
            report.marksMigrated++;
            assessMarksCount++;
          } catch (err: any) {
            report.errors.push(
              `Failed migrating mark for assessment ${assess._id}, student ${entry.studentId}: ${err?.message}`
            );
          }
        } else {
          // Dry-run preview count
          report.marksMigrated++;
          assessMarksCount++;
        }
      }

      if (assessMarksCount > 0) {
        report.assessmentsMigrated++;
      }
    }

    return report;
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
            deepLink: `/assessments/${assessment._id.toString()}`,
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
