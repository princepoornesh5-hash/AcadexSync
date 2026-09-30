import mongoose, { Types } from 'mongoose';
import { MongoMemoryServer } from 'mongodb-memory-server';
import {
  AcademicResult,
  AcademicRuleConfiguration,
  AcademicRecord,
  SubjectAcademicRecord,
  InternalAssessment,
  StudentEnrollment,
  Student,
  Subject,
  Course,
  Semester,
  AcademicYear,
  Department,
  College,
  User,
} from '../../src/models';
import {
  ResultLifecycleStatus,
  SubjectResultStatus,
  OverallResultStatus,
  PRESET_UGC_10_POINT_SCALE,
} from '../../src/constants/academicResult.constants';
import { AcademicResultService } from '../../src/services/academicResult.service';

describe('PROMPT 44 — Academic Finalization, Result Calculation & Official Publication Tests', () => {
  let mongoServer: MongoMemoryServer;
  let collegeId: Types.ObjectId;
  let departmentId: Types.ObjectId;
  let courseId: Types.ObjectId;
  let academicYearId: Types.ObjectId;
  let semesterId: Types.ObjectId;
  let studentUser: any;
  let studentDoc: any;
  let adminUser: any;
  let subject1: any;
  let subject2: any;

  beforeAll(async () => {
    mongoServer = await MongoMemoryServer.create();
    const uri = mongoServer.getUri();
    await mongoose.connect(uri);

    collegeId = new Types.ObjectId();
    departmentId = new Types.ObjectId();
    courseId = new Types.ObjectId();
    academicYearId = new Types.ObjectId();
    semesterId = new Types.ObjectId();

    // Create Course and Semester
    await College.create({
      _id: collegeId,
      name: 'Acadex Engineering College',
      code: 'AEC',
      principal: 'Dr. John Principal',
      phone: '9876543210',
      email: 'principal@aec.edu',
      address: '123 Campus Road',
    });
    await Department.create({ _id: departmentId, collegeId, name: 'Computer Science', code: 'CSE' });
    await Course.create({ _id: courseId, collegeId, departmentId, name: 'B.Tech CSE', code: 'CS', duration: 4 });
    await AcademicYear.create({
      _id: academicYearId,
      collegeId,
      name: '2026-2027',
      startDate: new Date('2026-08-01'),
      endDate: new Date('2027-05-31'),
    });
    await Semester.create({
      _id: semesterId,
      collegeId,
      departmentId,
      courseId,
      academicYearId,
      name: 'Semester 4',
      number: 4,
    });

    // Create Subjects
    subject1 = await Subject.create({
      collegeId,
      departmentId,
      courseId,
      semesterId,
      name: 'Advanced Algorithms',
      code: 'CS401',
      credits: 4,
      status: 'active',
      type: 'theory',
    });

    subject2 = await Subject.create({
      collegeId,
      departmentId,
      courseId,
      semesterId,
      name: 'Database Systems',
      code: 'CS402',
      credits: 3,
      status: 'active',
      type: 'theory',
    });

    // Create Users
    studentUser = await User.create({
      collegeId,
      name: 'Alan Turing',
      email: 'alan@acadex.edu',
      role: 'STUDENT',
      status: 'active',
    });

    studentDoc = await Student.create({
      collegeId,
      departmentId,
      userId: studentUser._id,
      name: 'Alan Turing',
      rollNumber: 'CS4001',
      admissionNumber: 'ADM4001',
      email: 'alan@acadex.edu',
    });

    adminUser = {
      id: new Types.ObjectId().toString(),
      name: 'Dean Academic',
      role: 'COLLEGE_ADMIN',
      collegeId: collegeId.toString(),
    };
  });

  afterAll(async () => {
    await mongoose.disconnect();
    await mongoServer.stop();
  });

  beforeEach(async () => {
    // Reset results & assessments
    await AcademicResult.deleteMany({});
    await InternalAssessment.deleteMany({});
    await AcademicRecord.deleteMany({});
    await SubjectAcademicRecord.deleteMany({});
    await StudentEnrollment.deleteMany({});
    await AcademicRuleConfiguration.deleteMany({});
  });

  describe('1. Academic Rule Configuration & Prerequisite Safety', () => {
    it('1.1 Blocks calculation when no academic rule is configured', async () => {
      // Create Enrollment
      await StudentEnrollment.create({
        collegeId,
        studentId: studentDoc._id,
        departmentId,
        courseId,
        academicYearId,
        semesterId,
        status: 'active',
      });

      await expect(
        AcademicResultService.calculateSemesterResult({
          collegeId,
          studentId: studentDoc._id,
          semesterId,
          academicYearId,
          user: adminUser,
        })
      ).rejects.toThrow('Result grading rules are not configured for this academic program.');
    });

    it('1.2 Successfully configures and resolves default UGC 10-point scale', async () => {
      await AcademicRuleConfiguration.create({
        collegeId,
        name: 'Standard UGC 10-Point Scale',
        isDefault: true,
        gradingScale: PRESET_UGC_10_POINT_SCALE,
        passCriteria: {
          minSubjectPercentage: 40,
        },
        gpaPolicy: {
          enabled: true,
          scale: 10.0,
          formula: 'CREDIT_WEIGHTED',
          passingGradePointMin: 4.0,
        },
        cgpaPolicy: {
          enabled: true,
          calculationPeriod: 'CUMULATIVE_ACROSS_SEMESTERS',
        },
        isConfigured: true,
      });

      const resolved = await AcademicResultService.getEffectiveRuleConfig(collegeId, courseId);
      expect(resolved).not.toBeNull();
      expect(resolved?.name).toBe('Standard UGC 10-Point Scale');
      expect(resolved?.gradingScale.length).toBe(PRESET_UGC_10_POINT_SCALE.length);
    });

    it('1.3 Correctly maps exact boundary grades (e.g., 90.0% -> O, 89.99% -> A+, 40.0% -> P, 39.9% -> F)', () => {
      const scale = PRESET_UGC_10_POINT_SCALE;

      expect(AcademicResultService.matchGrade(100, scale).grade).toBe('O');
      expect(AcademicResultService.matchGrade(90.0, scale).grade).toBe('O');
      expect(AcademicResultService.matchGrade(90.0, scale).gradePoint).toBe(10.0);

      expect(AcademicResultService.matchGrade(89.99, scale).grade).toBe('A+');
      expect(AcademicResultService.matchGrade(80.0, scale).grade).toBe('A+');

      expect(AcademicResultService.matchGrade(75.5, scale).grade).toBe('A');
      expect(AcademicResultService.matchGrade(40.0, scale).grade).toBe('P');
      expect(AcademicResultService.matchGrade(40.0, scale).isPassing).toBe(true);

      expect(AcademicResultService.matchGrade(39.9, scale).grade).toBe('F');
      expect(AcademicResultService.matchGrade(39.9, scale).isPassing).toBe(false);
      expect(AcademicResultService.matchGrade(0, scale).gradePoint).toBe(0.0);
    });
  });

  describe('2. Result Calculation Engine & GPA Evaluation', () => {
    beforeEach(async () => {
      // Set up default rule
      await AcademicRuleConfiguration.create({
        collegeId,
        name: 'Standard UGC 10-Point Scale',
        isDefault: true,
        gradingScale: PRESET_UGC_10_POINT_SCALE,
        passCriteria: { minSubjectPercentage: 40 },
        gpaPolicy: { enabled: true, scale: 10.0, formula: 'CREDIT_WEIGHTED', passingGradePointMin: 4.0 },
        cgpaPolicy: { enabled: true, calculationPeriod: 'CUMULATIVE_ACROSS_SEMESTERS' },
        isConfigured: true,
      });

      // Enrollment & Academic Records
      const enroll = await StudentEnrollment.create({
        collegeId,
        studentId: studentDoc._id,
        departmentId,
        courseId,
        academicYearId,
        semesterId,
        status: 'active',
      });

      const acadRecord = await AcademicRecord.create({
        collegeId,
        studentId: studentDoc._id,
        studentEnrollmentId: enroll._id,
        departmentId,
        courseId,
        academicYearId,
        semesterId,
      });

      await SubjectAcademicRecord.create({
        collegeId,
        academicRecordId: acadRecord._id,
        studentId: studentDoc._id,
        subjectId: subject1._id,
        credits: 4,
      });

      await SubjectAcademicRecord.create({
        collegeId,
        academicRecordId: acadRecord._id,
        studentId: studentDoc._id,
        subjectId: subject2._id,
        credits: 3,
      });
    });

    it('2.1 Aggregates only published assessments and preserves decimal marks', async () => {
      // Create Published Assessment for Subject 1 (obtained: 42.5 / 50 = 85%)
      await InternalAssessment.create({
        collegeId,
        departmentId,
        courseId,
        academicYearId,
        semesterId,
        subjectId: subject1._id,
        title: 'Midterm 1',
        assessmentType: 'INTERNAL_EXAM',
        maximumMarks: 50,
        status: 'PUBLISHED',
        entries: [
          {
            studentId: studentDoc._id,
            studentName: 'Alan Turing',
            rollNumber: 'CS4001',
            totalMarks: 42.5,
            status: 'ENTERED',
          },
        ],
      });

      // Create Draft Assessment for Subject 1 (MUST NOT BE INCLUDED)
      await InternalAssessment.create({
        collegeId,
        departmentId,
        courseId,
        academicYearId,
        semesterId,
        subjectId: subject1._id,
        title: 'Draft Quiz',
        assessmentType: 'QUIZ',
        maximumMarks: 20,
        status: 'DRAFT',
        entries: [
          {
            studentId: studentDoc._id,
            studentName: 'Alan Turing',
            rollNumber: 'CS4001',
            totalMarks: 18,
            status: 'ENTERED',
          },
        ],
      });

      // Create Published Assessment for Subject 2 (obtained: 38 / 50 = 76%)
      await InternalAssessment.create({
        collegeId,
        departmentId,
        courseId,
        academicYearId,
        semesterId,
        subjectId: subject2._id,
        title: 'Midterm DB',
        assessmentType: 'INTERNAL_EXAM',
        maximumMarks: 50,
        status: 'PUBLISHED',
        entries: [
          {
            studentId: studentDoc._id,
            studentName: 'Alan Turing',
            rollNumber: 'CS4001',
            totalMarks: 38.0,
            status: 'ENTERED',
          },
        ],
      });

      const { result, warnings } = await AcademicResultService.calculateSemesterResult({
        collegeId,
        studentId: studentDoc._id,
        semesterId,
        academicYearId,
        user: adminUser,
      });

      expect(result.status).toBe(ResultLifecycleStatus.CALCULATED);
      expect(result.summary.overallResult).toBe(OverallResultStatus.PASS);
      expect(result.subjectResults.length).toBe(2);

      // Subject 1: 42.5 / 50 = 85.0% -> Grade A+, GradePoint 9.0, credits 4
      const res1 = result.subjectResults.find((s) => s.subjectCode === 'CS401');
      expect(res1).toBeDefined();
      expect(res1?.totalObtainedMarks).toBe(42.5);
      expect(res1?.percentage).toBe(85.0);
      expect(res1?.grade).toBe('A+');
      expect(res1?.gradePoint).toBe(9.0);
      expect(res1?.status).toBe(SubjectResultStatus.PASS);
      expect(res1?.earnedCredits).toBe(4);

      // Subject 2: 38.0 / 50 = 76.0% -> Grade A, GradePoint 8.0, credits 3
      const res2 = result.subjectResults.find((s) => s.subjectCode === 'CS402');
      expect(res2).toBeDefined();
      expect(res2?.totalObtainedMarks).toBe(38.0);
      expect(res2?.percentage).toBe(76.0);
      expect(res2?.grade).toBe('A');
      expect(res2?.gradePoint).toBe(8.0);
      expect(res2?.status).toBe(SubjectResultStatus.PASS);
      expect(res2?.earnedCredits).toBe(3);

      // GPA: ((9.0 * 4) + (8.0 * 3)) / (4 + 3) = (36 + 24) / 7 = 60 / 7 = 8.57
      expect(result.summary.gpa).toBe(8.57);
      expect(result.summary.totalCreditsEarned).toBe(7);
      expect(result.summary.totalCreditsAttempted).toBe(7);
      expect(warnings.length).toBe(0);
    });

    it('2.2 Accurately flags missing assessment as INCOMPLETE', async () => {
      // Only publish assessment for Subject 1, leave Subject 2 empty
      await InternalAssessment.create({
        collegeId,
        departmentId,
        courseId,
        academicYearId,
        semesterId,
        subjectId: subject1._id,
        title: 'Midterm 1',
        assessmentType: 'INTERNAL_EXAM',
        maximumMarks: 50,
        status: 'PUBLISHED',
        entries: [
          {
            studentId: studentDoc._id,
            studentName: 'Alan Turing',
            rollNumber: 'CS4001',
            totalMarks: 40,
            status: 'ENTERED',
          },
        ],
      });

      const { result, warnings } = await AcademicResultService.calculateSemesterResult({
        collegeId,
        studentId: studentDoc._id,
        semesterId,
        academicYearId,
        user: adminUser,
      });

      expect(result.summary.overallResult).toBe(OverallResultStatus.INCOMPLETE);
      expect(result.summary.incompleteSubjects).toBe(1);
      expect(warnings.length).toBeGreaterThan(0);
      expect(warnings[0]).toContain('CS402');
    });
  });

  describe('3. Review, Finalization, Publication & Reopening Lifecycle', () => {
    let testResult: any;

    beforeEach(async () => {
      await AcademicRuleConfiguration.create({
        collegeId,
        name: 'Standard UGC 10-Point Scale',
        isDefault: true,
        gradingScale: PRESET_UGC_10_POINT_SCALE,
        passCriteria: { minSubjectPercentage: 40 },
        gpaPolicy: { enabled: true, scale: 10.0, formula: 'CREDIT_WEIGHTED', passingGradePointMin: 4.0 },
        isConfigured: true,
      });

      const enroll = await StudentEnrollment.create({
        collegeId,
        studentId: studentDoc._id,
        departmentId,
        courseId,
        academicYearId,
        semesterId,
        status: 'active',
      });

      const acadRecord = await AcademicRecord.create({
        collegeId,
        studentId: studentDoc._id,
        studentEnrollmentId: enroll._id,
        departmentId,
        courseId,
        academicYearId,
        semesterId,
      });

      await SubjectAcademicRecord.create({
        collegeId,
        academicRecordId: acadRecord._id,
        studentId: studentDoc._id,
        subjectId: subject1._id,
        credits: 4,
      });

      // Complete published assessment
      await InternalAssessment.create({
        collegeId,
        departmentId,
        courseId,
        academicYearId,
        semesterId,
        subjectId: subject1._id,
        title: 'Final Exam',
        assessmentType: 'INTERNAL_EXAM',
        maximumMarks: 100,
        status: 'PUBLISHED',
        entries: [
          {
            studentId: studentDoc._id,
            studentName: 'Alan Turing',
            rollNumber: 'CS4001',
            totalMarks: 85,
            status: 'ENTERED',
          },
        ],
      });

      const { result } = await AcademicResultService.calculateSemesterResult({
        collegeId,
        studentId: studentDoc._id,
        semesterId,
        academicYearId,
        user: adminUser,
      });
      testResult = result;
    });

    it('3.1 Blocks finalization if any subject is INCOMPLETE', async () => {
      // Manually set a subject to INCOMPLETE
      testResult.subjectResults[0].status = SubjectResultStatus.INCOMPLETE;
      await testResult.save();

      await expect(
        AcademicResultService.finalizeResult({
          collegeId,
          resultId: testResult._id,
          user: adminUser,
        })
      ).rejects.toThrow('Cannot finalize result with incomplete subjects');
    });

    it('3.2 Successfully transitions: CALCULATED -> UNDER_REVIEW -> FINALIZED -> PUBLISHED', async () => {
      // 1. Move to UNDER_REVIEW
      const reviewed = await AcademicResultService.reviewResult({
        collegeId,
        resultId: testResult._id,
        user: adminUser,
        reviewNotes: 'Verified all subject marks with HOD',
      });
      expect(reviewed.status).toBe(ResultLifecycleStatus.UNDER_REVIEW);
      expect(reviewed.reviewNotes).toBe('Verified all subject marks with HOD');

      // 2. Finalize
      const finalized = await AcademicResultService.finalizeResult({
        collegeId,
        resultId: testResult._id,
        user: adminUser,
      });
      expect(finalized.status).toBe(ResultLifecycleStatus.FINALIZED);
      expect(finalized.finalizedAt).toBeDefined();

      // 3. Attempting recalculation on finalized result must FAIL without reopening
      await expect(
        AcademicResultService.calculateSemesterResult({
          collegeId,
          studentId: studentDoc._id,
          semesterId,
          academicYearId,
          user: adminUser,
        })
      ).rejects.toThrow('This academic result is finalized and locked.');

      // 4. Publish
      const published = await AcademicResultService.publishResult({
        collegeId,
        resultId: testResult._id,
        user: adminUser,
      });
      expect(published.status).toBe(ResultLifecycleStatus.PUBLISHED);
      expect(published.publishedAt).toBeDefined();
      expect(published.currentPublishedSnapshot).not.toBeNull();
      expect(published.currentPublishedSnapshot?.version).toBe(1);
      expect(published.publicationSnapshots.length).toBe(1);
    });

    it('3.3 Controlled Reopening requires valid reason and creates Version 2', async () => {
      // Finalize and publish
      await AcademicResultService.finalizeResult({
        collegeId,
        resultId: testResult._id,
        user: adminUser,
      });
      await AcademicResultService.publishResult({
        collegeId,
        resultId: testResult._id,
        user: adminUser,
      });

      // Attempt reopening without reason (must FAIL)
      await expect(
        AcademicResultService.reopenResult({
          collegeId,
          resultId: testResult._id,
          user: adminUser,
          reason: 'abc', // < 5 chars
        })
      ).rejects.toThrow('A valid reopening reason of at least 5 characters is required.');

      // Reopen with valid reason
      const reopened = await AcademicResultService.reopenResult({
        collegeId,
        resultId: testResult._id,
        user: adminUser,
        reason: 'Authorized re-evaluation requested by examination committee',
      });

      expect(reopened.status).toBe(ResultLifecycleStatus.REOPENED);
      expect(reopened.version).toBe(2);
      expect(reopened.reopenHistory.length).toBe(1);
      expect(reopened.reopenHistory[0].reason).toContain('Authorized re-evaluation');

      // Crucial: Student still sees published snapshot version 1 until new version is published!
      const studentView = await AcademicResultService.getStudentOfficialResult({
        collegeId,
        studentUserId: studentUser._id,
        semesterId,
      });
      expect(studentView.hasPublishedResult).toBe(true);
      expect(studentView.result?.version).toBe(1);
    });
  });

  describe('4. Student Result Visibility & Privacy Boundary', () => {
    it('4.1 Student CANNOT see unpublished or draft results', async () => {
      await AcademicRuleConfiguration.create({
        collegeId,
        name: 'Standard UGC 10-Point Scale',
        isDefault: true,
        gradingScale: PRESET_UGC_10_POINT_SCALE,
        passCriteria: { minSubjectPercentage: 40 },
        isConfigured: true,
      });

      const enroll = await StudentEnrollment.create({
        collegeId,
        studentId: studentDoc._id,
        departmentId,
        courseId,
        academicYearId,
        semesterId,
        status: 'active',
      });

      const acadRecord = await AcademicRecord.create({
        collegeId,
        studentId: studentDoc._id,
        studentEnrollmentId: enroll._id,
        departmentId,
        courseId,
        academicYearId,
        semesterId,
      });

      await SubjectAcademicRecord.create({
        collegeId,
        academicRecordId: acadRecord._id,
        studentId: studentDoc._id,
        subjectId: subject1._id,
        credits: 4,
      });

      // Calculate draft result
      await AcademicResultService.calculateSemesterResult({
        collegeId,
        studentId: studentDoc._id,
        semesterId,
        academicYearId,
        user: adminUser,
      });

      // Student views result: MUST BE NULL because not published!
      const view = await AcademicResultService.getStudentOfficialResult({
        collegeId,
        studentUserId: studentUser._id,
        semesterId,
      });

      expect(view.hasPublishedResult).toBe(false);
      expect(view.result).toBeNull();
    });
  });
});
