import mongoose from 'mongoose';
import {
  College,
  Department,
  Course,
  AcademicYear,
  Semester,
  Section,
  Subject,
  User,
  Faculty,
  FacultyAssignment,
  Student,
  StudentEnrollment,
  AssessmentStatus,
  AssessmentType,
  StudentMarkStatus,
} from '../../src/models';
import { InternalAssessmentService } from '../../src/services/internalAssessment.service';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { AppRole } from '../../src/constants/roles';

describe('PROMPT 43 — Internal Assessment, Marks & Subject Evaluation Unit Tests', () => {
  let collegeA: any;
  let collegeB: any;
  let deptA: any;
  let deptB: any;
  let courseA: any;
  let academicYearA: any;
  let semesterA: any;
  let sectionA: any;
  let subjectTheory: any;

  let facultyUserA: any;
  let facultyUserB: any;
  let facultyDocA: any;

  let hodUserB: any;
  let adminUserA: any;

  let studentUser1: any;
  let studentUser2: any;
  let studentDoc1: any;
  let studentDoc2: any;
  let studentCrossTenant: any;

  beforeAll(async () => {
    await setupTestDB();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();

    // Colleges
    collegeA = await College.create({
      name: 'Alpha Engineering College',
      code: 'AEC',
      address: 'North Campus',
      email: 'admin@alpha.edu',
      phone: '9000000001',
      principal: 'Dr. Alpha Principal',
    });

    collegeB = await College.create({
      name: 'Beta Technology College',
      code: 'BTC',
      address: 'South Campus',
      email: 'admin@beta.edu',
      phone: '9000000002',
      principal: 'Dr. Beta Principal',
    });

    // Departments
    deptA = await Department.create({
      collegeId: collegeA._id,
      name: 'Computer Science',
      code: 'CSE',
    });

    deptB = await Department.create({
      collegeId: collegeA._id,
      name: 'Mechanical Engineering',
      code: 'MECH',
    });

    // Academic Structure
    courseA = await Course.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'B.Tech CSE',
      code: 'CS100',
      duration: 4,
    });

    academicYearA = await AcademicYear.create({
      collegeId: collegeA._id,
      name: '2026-2027',
      startDate: new Date('2026-08-01'),
      endDate: new Date('2027-05-31'),
    });

    semesterA = await Semester.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      name: 'Semester 5',
      number: 5,
    });

    sectionA = await Section.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      name: 'Section A',
      capacity: 60,
    });

    subjectTheory = await Subject.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      semesterId: semesterA._id,
      name: 'Computer Networks',
      code: 'CS503',
      type: 'Theory',
      credits: 4,
    });

    // Users
    adminUserA = await User.create({
      collegeId: collegeA._id,
      instituteId: 'ADMIN-01',
      name: 'Admin Alpha',
      email: 'admin@alpha.edu',
      role: AppRole.COLLEGE_ADMIN,
      isActive: true,
    });

    await User.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      instituteId: 'HOD-A',
      name: 'HOD CSE',
      email: 'hod.cse@alpha.edu',
      role: AppRole.HOD,
      isActive: true,
    });

    hodUserB = await User.create({
      collegeId: collegeA._id,
      departmentId: deptB._id,
      instituteId: 'HOD-B',
      name: 'HOD MECH',
      email: 'hod.mech@alpha.edu',
      role: AppRole.HOD,
      isActive: true,
    });

    facultyUserA = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      instituteId: 'FAC-A',
      name: 'Prof. Alice',
      email: 'alice@alpha.edu',
      role: AppRole.FACULTY,
      isActive: true,
    });

    facultyUserB = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      instituteId: 'FAC-B',
      name: 'Prof. Bob',
      email: 'bob@alpha.edu',
      role: AppRole.FACULTY,
      isActive: true,
    });

    facultyDocA = await Faculty.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      userId: facultyUserA._id,
      name: facultyUserA.name,
      email: facultyUserA.email,
      isActive: true,
    });

    await Faculty.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      userId: facultyUserB._id,
      name: facultyUserB.name,
      email: facultyUserB.email,
      isActive: true,
    });

    // Faculty Assignment: Faculty A is assigned to subjectTheory for Section A
    await FacultyAssignment.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      facultyId: facultyDocA._id,
      facultyName: facultyDocA.name,
      courseId: courseA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      subjectId: subjectTheory._id,
      academicYearId: academicYearA._id,
      isActive: true,
      assignedBy: adminUserA._id.toString(),
    });

    // Students
    studentUser1 = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      instituteId: 'STU-01',
      name: 'Charlie Student',
      email: 'charlie@alpha.edu',
      role: AppRole.STUDENT,
      isActive: true,
    });

    studentUser2 = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      instituteId: 'STU-02',
      name: 'Daisy Student',
      email: 'daisy@alpha.edu',
      role: AppRole.STUDENT,
      isActive: true,
    });

    studentDoc1 = await Student.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      userId: studentUser1._id,
      name: studentUser1.name,
      email: studentUser1.email,
      rollNumber: 'CS101',
      admissionNumber: 'ADM-101',
      sectionId: sectionA._id,
      semesterId: semesterA._id,
      isActive: true,
    });

    studentDoc2 = await Student.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      userId: studentUser2._id,
      name: studentUser2.name,
      email: studentUser2.email,
      rollNumber: 'CS102',
      admissionNumber: 'ADM-102',
      sectionId: sectionA._id,
      semesterId: semesterA._id,
      isActive: true,
    });

    // Cross-tenant student
    studentCrossTenant = await Student.create({
      collegeId: collegeB._id,
      departmentId: new mongoose.Types.ObjectId(),
      name: 'Cross Tenant Student',
      email: 'cross@beta.edu',
      rollNumber: 'BETA01',
      isActive: true,
    });

    // Enrollments
    await StudentEnrollment.create({
      collegeId: collegeA._id,
      studentId: studentDoc1._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      status: 'active',
    });

    await StudentEnrollment.create({
      collegeId: collegeA._id,
      studentId: studentDoc2._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      status: 'active',
    });
  });

  describe('1. Assessment Lifecycle & Transitions', () => {
    it('1.1 Creates assessment in DRAFT status with FacultyAssignment ownership', async () => {
      const assessment = await InternalAssessmentService.createAssessment(
        collegeA._id.toString(),
        { id: facultyUserA._id.toString(), role: AppRole.FACULTY, name: facultyUserA.name },
        {
          departmentId: deptA._id.toString(),
          courseId: courseA._id.toString(),
          academicYearId: academicYearA._id.toString(),
          semesterId: semesterA._id.toString(),
          sectionId: sectionA._id.toString(),
          subjectId: subjectTheory._id.toString(),
          title: 'Internal Exam 1',
          assessmentType: AssessmentType.INTERNAL_EXAM,
          maximumMarks: 50,
        }
      );

      expect(assessment).toBeDefined();
      expect(assessment.status).toBe(AssessmentStatus.DRAFT);
      expect(assessment.maximumMarks).toBe(50);
      expect(assessment.entries.length).toBe(2);
      expect(assessment.entries[0].status).toBe(StudentMarkStatus.NOT_ENTERED);
    });

    it('1.2 Rejects assessment creation if faculty is not assigned to teaching context', async () => {
      await expect(
        InternalAssessmentService.createAssessment(
          collegeA._id.toString(),
          { id: facultyUserB._id.toString(), role: AppRole.FACULTY, name: facultyUserB.name },
          {
            departmentId: deptA._id.toString(),
            courseId: courseA._id.toString(),
            academicYearId: academicYearA._id.toString(),
            semesterId: semesterA._id.toString(),
            sectionId: sectionA._id.toString(),
            subjectId: subjectTheory._id.toString(),
            title: 'Unauthorized Assessment',
            maximumMarks: 50,
          }
        )
      ).rejects.toThrow(/You are not authorized to manage assessments for this teaching context/);
    });

    it('1.3 Enforces valid lifecycle transitions: DRAFT -> OPEN -> CLOSED -> PUBLISHED', async () => {
      // 1. Get or create draft context
      await InternalAssessmentService.getAssessmentContext(
        collegeA._id.toString(),
        { id: facultyUserA._id.toString(), role: AppRole.FACULTY, name: facultyUserA.name },
        { sectionId: sectionA._id.toString(), subjectId: subjectTheory._id.toString() }
      );

      // 2. Open assessment
      const opened = await InternalAssessmentService.openAssessment(
        collegeA._id.toString(),
        { id: facultyUserA._id.toString(), role: AppRole.FACULTY, name: facultyUserA.name },
        { sectionId: sectionA._id.toString(), subjectId: subjectTheory._id.toString() }
      );
      expect(opened.status).toBe(AssessmentStatus.OPEN);

      // 3. Close assessment
      const closed = await InternalAssessmentService.closeAssessment(
        collegeA._id.toString(),
        { id: facultyUserA._id.toString(), role: AppRole.FACULTY, name: facultyUserA.name },
        { sectionId: sectionA._id.toString(), subjectId: subjectTheory._id.toString() }
      );
      expect(closed.status).toBe(AssessmentStatus.CLOSED);

      // 4. Publish assessment
      const published = await InternalAssessmentService.publishMarks(
        collegeA._id.toString(),
        { id: facultyUserA._id.toString(), role: AppRole.FACULTY, name: facultyUserA.name },
        { sectionId: sectionA._id.toString(), subjectId: subjectTheory._id.toString() }
      );
      expect(published.status).toBe(AssessmentStatus.PUBLISHED);
      expect(published.publishedAt).toBeDefined();

      // 5. Direct invalid jump from PUBLISHED to OPEN must fail
      await expect(
        InternalAssessmentService.openAssessment(
          collegeA._id.toString(),
          { id: facultyUserA._id.toString(), role: AppRole.FACULTY, name: facultyUserA.name },
          { sectionId: sectionA._id.toString(), subjectId: subjectTheory._id.toString() }
        )
      ).rejects.toThrow(/Cannot open assessment in 'PUBLISHED' status/);
    });

    it('1.4 HOD cannot cross departments to view or manage assessments', async () => {
      // HOD B (MECH) tries to access CSE context
      await expect(
        InternalAssessmentService.getAssessmentContext(
          collegeA._id.toString(),
          { id: hodUserB._id.toString(), role: AppRole.HOD, name: hodUserB.name, departmentId: deptB._id.toString() },
          { sectionId: sectionA._id.toString(), subjectId: subjectTheory._id.toString() }
        )
      ).rejects.toThrow(/outside your department/);
    });
  });

  describe('2. Marks Entry, Decimal Precision & Validation', () => {
    it('2.1 Correctly preserves decimal marks (e.g., 37.5)', async () => {
      const assessment = await InternalAssessmentService.saveDraftMarks(
        collegeA._id.toString(),
        { id: facultyUserA._id.toString(), role: AppRole.FACULTY, name: facultyUserA.name },
        {
          sectionId: sectionA._id.toString(),
          subjectId: subjectTheory._id.toString(),
          entries: [
            {
              studentId: studentDoc1._id.toString(),
              componentMarks: { test1: 22.5, test2: 15 },
            },
          ],
        }
      );

      const entry = assessment.entries.find((e) => e.studentId.toString() === studentDoc1._id.toString());
      expect(entry).toBeDefined();
      expect(entry!.componentMarks['test1']).toBe(22.5);
      expect(entry!.totalMarks).toBe(37.5);
      expect(entry!.status).toBe(StudentMarkStatus.ENTERED);
    });

    it('2.2 Rejects negative marks', async () => {
      await expect(
        InternalAssessmentService.saveDraftMarks(
          collegeA._id.toString(),
          { id: facultyUserA._id.toString(), role: AppRole.FACULTY, name: facultyUserA.name },
          {
            sectionId: sectionA._id.toString(),
            subjectId: subjectTheory._id.toString(),
            entries: [
              {
                studentId: studentDoc1._id.toString(),
                componentMarks: { test1: -5 },
              },
            ],
          }
        )
      ).rejects.toThrow(/cannot be negative/);
    });

    it('2.3 Rejects marks greater than component maximumMarks', async () => {
      await expect(
        InternalAssessmentService.saveDraftMarks(
          collegeA._id.toString(),
          { id: facultyUserA._id.toString(), role: AppRole.FACULTY, name: facultyUserA.name },
          {
            sectionId: sectionA._id.toString(),
            subjectId: subjectTheory._id.toString(),
            entries: [
              {
                studentId: studentDoc1._id.toString(),
                componentMarks: { test1: 999 }, // Max is 25
              },
            ],
          }
        )
      ).rejects.toThrow(/cannot exceed maximum allowed/);
    });

    it('2.4 Preserves distinct ABSENT and EXCUSED semantics without coercing to ordinary zero', async () => {
      const assessment = await InternalAssessmentService.saveDraftMarks(
        collegeA._id.toString(),
        { id: facultyUserA._id.toString(), role: AppRole.FACULTY, name: facultyUserA.name },
        {
          sectionId: sectionA._id.toString(),
          subjectId: subjectTheory._id.toString(),
          entries: [
            {
              studentId: studentDoc1._id.toString(),
              status: StudentMarkStatus.ABSENT,
              remarks: 'Medical absence',
            },
            {
              studentId: studentDoc2._id.toString(),
              status: StudentMarkStatus.EXCUSED,
              remarks: 'Sports duty exemption',
            },
          ],
        }
      );

      const entry1 = assessment.entries.find((e) => e.studentId.toString() === studentDoc1._id.toString());
      const entry2 = assessment.entries.find((e) => e.studentId.toString() === studentDoc2._id.toString());

      expect(entry1?.status).toBe(StudentMarkStatus.ABSENT);
      expect(entry1?.totalMarks).toBe(0);
      expect(entry1?.remarks).toBe('Medical absence');

      expect(entry2?.status).toBe(StudentMarkStatus.EXCUSED);
      expect(entry2?.totalMarks).toBe(0);
      expect(entry2?.remarks).toBe('Sports duty exemption');
    });

    it('2.5 Rejects cross-tenant student during mark entry', async () => {
      await expect(
        InternalAssessmentService.saveDraftMarks(
          collegeA._id.toString(),
          { id: facultyUserA._id.toString(), role: AppRole.FACULTY, name: facultyUserA.name },
          {
            sectionId: sectionA._id.toString(),
            subjectId: subjectTheory._id.toString(),
            entries: [
              {
                studentId: studentCrossTenant._id.toString(),
                componentMarks: { test1: 20 },
              },
            ],
          }
        )
      ).rejects.toThrow(/not eligible for this college\/assessment context/);
    });

    it('2.6 Supports idempotent bulk saves without creating duplicate entries', async () => {
      // First save
      await InternalAssessmentService.bulkSaveMarks(
        collegeA._id.toString(),
        { id: facultyUserA._id.toString(), role: AppRole.FACULTY, name: facultyUserA.name },
        {
          sectionId: sectionA._id.toString(),
          subjectId: subjectTheory._id.toString(),
          entries: [
            { studentId: studentDoc1._id.toString(), componentMarks: { test1: 18 } },
            { studentId: studentDoc2._id.toString(), componentMarks: { test1: 20 } },
          ],
        }
      );

      // Repeated save
      const repeated = await InternalAssessmentService.bulkSaveMarks(
        collegeA._id.toString(),
        { id: facultyUserA._id.toString(), role: AppRole.FACULTY, name: facultyUserA.name },
        {
          sectionId: sectionA._id.toString(),
          subjectId: subjectTheory._id.toString(),
          entries: [
            { studentId: studentDoc1._id.toString(), componentMarks: { test1: 19 } },
            { studentId: studentDoc2._id.toString(), componentMarks: { test1: 20 } },
          ],
        }
      );

      expect(repeated.entries.length).toBe(2);
      const entry1 = repeated.entries.find((e) => e.studentId.toString() === studentDoc1._id.toString());
      expect(entry1?.componentMarks['test1']).toBe(19);
    });
  });

  describe('3. Controlled Mark Correction Workflow & Audit', () => {
    it('3.1 Requires a valid reason (>= 5 chars) to correct a student mark', async () => {
      // Initialize and publish assessment
      await InternalAssessmentService.saveDraftMarks(
        collegeA._id.toString(),
        { id: facultyUserA._id.toString(), role: AppRole.FACULTY, name: facultyUserA.name },
        {
          sectionId: sectionA._id.toString(),
          subjectId: subjectTheory._id.toString(),
          entries: [{ studentId: studentDoc1._id.toString(), componentMarks: { test1: 15 } }],
        }
      );

      await InternalAssessmentService.publishMarks(
        collegeA._id.toString(),
        { id: facultyUserA._id.toString(), role: AppRole.FACULTY, name: facultyUserA.name },
        { sectionId: sectionA._id.toString(), subjectId: subjectTheory._id.toString() }
      );

      // Attempt correction with too short reason
      await expect(
        InternalAssessmentService.correctStudentMark(
          collegeA._id.toString(),
          { id: adminUserA._id.toString(), role: AppRole.COLLEGE_ADMIN, name: adminUserA.name },
          {
            sectionId: sectionA._id.toString(),
            subjectId: subjectTheory._id.toString(),
            studentId: studentDoc1._id.toString(),
            componentKey: 'test1',
            newMark: 22,
            reason: 'err', // Less than 5 characters
          }
        )
      ).rejects.toThrow(/Correction reason must be at least 5 characters long/);
    });

    it('3.2 Audits previousValue and newValue accurately during correction', async () => {
      // Initialize and publish
      await InternalAssessmentService.saveDraftMarks(
        collegeA._id.toString(),
        { id: facultyUserA._id.toString(), role: AppRole.FACULTY, name: facultyUserA.name },
        {
          sectionId: sectionA._id.toString(),
          subjectId: subjectTheory._id.toString(),
          entries: [{ studentId: studentDoc1._id.toString(), componentMarks: { test1: 15 } }],
        }
      );

      await InternalAssessmentService.publishMarks(
        collegeA._id.toString(),
        { id: facultyUserA._id.toString(), role: AppRole.FACULTY, name: facultyUserA.name },
        { sectionId: sectionA._id.toString(), subjectId: subjectTheory._id.toString() }
      );

      const correction = await InternalAssessmentService.correctStudentMark(
        collegeA._id.toString(),
        { id: facultyUserA._id.toString(), role: AppRole.FACULTY, name: facultyUserA.name },
        {
          sectionId: sectionA._id.toString(),
          subjectId: subjectTheory._id.toString(),
          studentId: studentDoc1._id.toString(),
          componentKey: 'test1',
          newMark: 23.5,
          reason: 'Typographical error in retotaling',
        }
      );

      expect(correction.entry.componentMarks['test1']).toBe(23.5);
      expect(correction.entry.totalMarks).toBe(23.5);

      const audit = correction.assessment.auditLog.find((a) => a.action === 'MARK_CORRECTED');
      expect(audit).toBeDefined();
      expect(audit!.previousValue).toEqual(expect.objectContaining({ mark: 15 }));
      expect(audit!.newValue).toEqual(expect.objectContaining({ mark: 23.5 }));
      expect(audit!.details).toContain('Typographical error in retotaling');
    });
  });

  describe('4. Subject Assessment Summary Integration', () => {
    it('4.1 Aggregates published assessments for subject-level history without raw mark duplication', async () => {
      // Save and publish assessment
      await InternalAssessmentService.saveDraftMarks(
        collegeA._id.toString(),
        { id: facultyUserA._id.toString(), role: AppRole.FACULTY, name: facultyUserA.name },
        {
          sectionId: sectionA._id.toString(),
          subjectId: subjectTheory._id.toString(),
          entries: [
            { studentId: studentDoc1._id.toString(), componentMarks: { test1: 20, test2: 20 } },
          ],
        }
      );

      await InternalAssessmentService.publishMarks(
        collegeA._id.toString(),
        { id: facultyUserA._id.toString(), role: AppRole.FACULTY, name: facultyUserA.name },
        { sectionId: sectionA._id.toString(), subjectId: subjectTheory._id.toString() }
      );

      const summary = await InternalAssessmentService.getSubjectAssessmentSummary(
        collegeA._id.toString(),
        {
          subjectId: subjectTheory._id.toString(),
          semesterId: semesterA._id.toString(),
          studentId: studentDoc1._id.toString(),
        }
      );

      expect(summary).toBeDefined();
      expect(summary.totalAssessments).toBe(1);
      expect(summary.publishedAssessments).toBe(1);
      expect(summary.totalObtainedMarks).toBe(40);
      expect(summary.percentage).toBeGreaterThan(0);
      expect(summary.assessments.length).toBe(1);
      expect(summary.assessments[0].obtainedMarks).toBe(40);
    });
  });
});
