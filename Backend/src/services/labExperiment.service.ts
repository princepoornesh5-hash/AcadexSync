import { Types } from 'mongoose';
import { ApiError } from '../utils/apiError';
import {
  LabExperiment,
  ILabExperiment,
  LabSubmissionStatus,
  Section,
  Subject,
  StudentEnrollment,
  Student,
} from '../models';
import { TeachingAuthorizationService, AuthUserContext } from './teachingAuthorization.service';

export interface CreateLabExperimentPayload {
  sectionId: string;
  subjectId: string;
  experimentNumber: number;
  title: string;
  description?: string;
  date?: string | Date;
  maxMarks?: {
    observation: number;
    record: number;
    viva: number;
  };
}

export class LabExperimentService {
  /**
   * Creates a new lab experiment for a subject and section.
   */
  static async createExperiment(
    collegeId: string,
    user: AuthUserContext,
    payload: CreateLabExperimentPayload
  ): Promise<ILabExperiment> {
    const { sectionId, subjectId, experimentNumber, title, description, date, maxMarks } = payload;
    if (!Types.ObjectId.isValid(sectionId) || !Types.ObjectId.isValid(subjectId)) {
      throw ApiError.badRequest('Invalid section ID or subject ID format');
    }

    const faDoc = await TeachingAuthorizationService.assertSubjectSectionAccess(
      collegeId,
      user,
      subjectId,
      sectionId
    );

    const section = await Section.findById(sectionId);
    const subject = await Subject.findById(subjectId);
    if (!section || !subject) throw ApiError.notFound('Section or Subject not found');

    // Check duplicate experiment number
    const existing = await LabExperiment.findOne({
      collegeId: new Types.ObjectId(collegeId),
      sectionId: new Types.ObjectId(sectionId),
      subjectId: new Types.ObjectId(subjectId),
      experimentNumber,
    });

    if (existing) {
      throw ApiError.badRequest(`Experiment number ${experimentNumber} already exists for this lab.`);
    }

    // Load active enrolled students
    let enrolledStudents: Array<{ id: string; name: string; rollNumber?: string }> = [];
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
          };
        });
    } else {
      const directStudents = await Student.find({
        collegeId: new Types.ObjectId(collegeId),
        sectionId: new Types.ObjectId(sectionId),
        isActive: true,
      });
      enrolledStudents = directStudents.map((s) => ({
        id: s._id.toString(),
        name: s.name,
        rollNumber: s.rollNumber || undefined,
      }));
    }

    const initialSubmissions = enrolledStudents.map((s) => ({
      studentId: new Types.ObjectId(s.id),
      studentName: s.name,
      rollNumber: s.rollNumber,
      status: LabSubmissionStatus.PENDING,
      observationMarks: 0,
      recordMarks: 0,
      vivaMarks: 0,
      totalMarks: 0,
    }));

    const experiment = await LabExperiment.create({
      collegeId: new Types.ObjectId(collegeId),
      departmentId: section.departmentId,
      courseId: section.courseId,
      academicYearId: section.academicYearId,
      semesterId: section.semesterId,
      sectionId: section._id,
      subjectId: subject._id,
      facultyAssignmentId: faDoc?._id || null,
      facultyId: faDoc?.facultyId || null,
      facultyName: faDoc?.facultyName || user.name || 'Faculty',
      experimentNumber,
      title: title.trim(),
      description: description?.trim() || null,
      date: date ? new Date(date) : new Date(),
      maxMarks: {
        observation: maxMarks?.observation ?? 10,
        record: maxMarks?.record ?? 10,
        viva: maxMarks?.viva ?? 5,
      },
      submissions: initialSubmissions,
    });

    return experiment;
  }

  /**
   * Retrieves all experiments for a subject and section.
   */
  static async getExperiments(
    collegeId: string,
    user: AuthUserContext,
    params: { sectionId: string; subjectId: string }
  ) {
    const { sectionId, subjectId } = params;
    if (!Types.ObjectId.isValid(sectionId) || !Types.ObjectId.isValid(subjectId)) {
      throw ApiError.badRequest('Invalid section ID or subject ID format');
    }

    const roleUpper = (user.role || '').toUpperCase();
    const isStudent = roleUpper === 'STUDENT';

    if (!isStudent) {
      await TeachingAuthorizationService.assertSubjectSectionAccess(
        collegeId,
        user,
        subjectId,
        sectionId
      );
    }

    const experiments = await LabExperiment.find({
      collegeId: new Types.ObjectId(collegeId),
      sectionId: new Types.ObjectId(sectionId),
      subjectId: new Types.ObjectId(subjectId),
    }).sort({ experimentNumber: 1 });

    if (isStudent) {
      const studentProfile = await Student.findOne({
        collegeId: new Types.ObjectId(collegeId),
        userId: new Types.ObjectId(user.id),
      });
      const sId = studentProfile ? studentProfile._id.toString() : user.id;

      return experiments.map((exp) => {
        const sub = exp.submissions.find((s) => s.studentId.toString() === sId);
        return {
          id: exp._id.toString(),
          experimentNumber: exp.experimentNumber,
          title: exp.title,
          description: exp.description,
          date: exp.date,
          maxMarks: exp.maxMarks,
          mySubmission: sub || null,
        };
      });
    }

    return experiments;
  }

  /**
   * Updates record submission, verification, and grading for students in a lab experiment.
   */
  static async updateSubmissions(
    collegeId: string,
    user: AuthUserContext,
    experimentId: string,
    updates: Array<{
      studentId: string;
      status?: LabSubmissionStatus;
      observationMarks?: number;
      recordMarks?: number;
      vivaMarks?: number;
      remarks?: string;
    }>
  ) {
    const experiment = await LabExperiment.findOne({
      _id: new Types.ObjectId(experimentId),
      collegeId: new Types.ObjectId(collegeId),
    });

    if (!experiment) {
      throw ApiError.notFound('Lab experiment not found');
    }

    await TeachingAuthorizationService.assertSubjectSectionAccess(
      collegeId,
      user,
      experiment.subjectId,
      experiment.sectionId
    );

    const submissionMap = new Map<string, any>();
    for (const sub of experiment.submissions) {
      submissionMap.set(sub.studentId.toString(), sub);
    }

    for (const upd of updates) {
      const sub = submissionMap.get(upd.studentId);
      if (sub) {
        if (upd.status) {
          sub.status = upd.status;
          if (upd.status === LabSubmissionStatus.SUBMITTED && !sub.submissionDate) {
            sub.submissionDate = new Date();
          }
          if (upd.status === LabSubmissionStatus.VERIFIED || upd.status === LabSubmissionStatus.GRADED) {
            sub.verifiedAt = new Date();
            sub.verifiedBy = new Types.ObjectId(user.id);
          }
        }

        if (upd.observationMarks !== undefined) {
          const obs = Number(upd.observationMarks);
          if (obs < 0 || obs > experiment.maxMarks.observation) {
            throw ApiError.badRequest(
              `Observation marks (${obs}) must be between 0 and ${experiment.maxMarks.observation}`
            );
          }
          sub.observationMarks = obs;
        }

        if (upd.recordMarks !== undefined) {
          const rec = Number(upd.recordMarks);
          if (rec < 0 || rec > experiment.maxMarks.record) {
            throw ApiError.badRequest(
              `Record marks (${rec}) must be between 0 and ${experiment.maxMarks.record}`
            );
          }
          sub.recordMarks = rec;
        }

        if (upd.vivaMarks !== undefined) {
          const viva = Number(upd.vivaMarks);
          if (viva < 0 || viva > experiment.maxMarks.viva) {
            throw ApiError.badRequest(
              `Viva marks (${viva}) must be between 0 and ${experiment.maxMarks.viva}`
            );
          }
          sub.vivaMarks = viva;
        }

        sub.totalMarks =
          (sub.observationMarks || 0) + (sub.recordMarks || 0) + (sub.vivaMarks || 0);

        if (upd.remarks !== undefined) {
          sub.remarks = upd.remarks;
        }
      }
    }

    await experiment.save();
    return experiment;
  }
}
