import request from 'supertest';
import { app } from '../../src/app';
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
  InternalAssessment,
  AssessmentMark,
  AttendanceSession,
  AttendanceRecord,
  HistoricalAttendanceSummary,
  ImportBatch,
} from '../../src/models';
import { AppRole } from '../../src/constants/roles';
import {
  ImportDataType,
  ImportBatchStatus,
  RowValidationStatus,
} from '../../src/constants/import.constants';
import {
  AssessmentType,
  AssessmentStatus,
  StudentMarkStatus,
} from '../../src/models/internalAssessment.model';
import { AttendanceStatus, AttendanceSessionStatus } from '../../src/constants/status';
import { normalizeAssessmentCategory } from '../../src/services/import/adapters/assessmentImportAdapter';
import { AttendanceAggregationService } from '../../src/services/attendance/attendanceAggregation.service';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';

describe('PROMPT 5/6 — Production-Grade Historical-Data Ingestion Layer (Assessment & Attendance)', () => {
  let collegeA: any;
  let collegeB: any;
  let departmentA: any;
  let courseA: any;
  let academicYearA: any;
  let semesterA: any;
  let sectionA: any;
  let subjectIME: any;
  let facultyDocA: any;
  let facultyAssignmentA: any;

  let adminUserA: any;
  let facultyUserA: any;
  let studentUserA: any;
  let adminUserB: any;

  let studentDocsA: any[] = [];
  let studentEnrollmentsA: any[] = [];

  function authHeader(user: any, collegeId?: string): string {
    return createTestAuthHeader({
      userId: user._id.toString(),
      collegeId: collegeId || user.collegeId.toString(),
      role: user.role,
      email: user.email,
      name: user.name,
    }).Authorization;
  }

  beforeAll(async () => {
    await setupTestDB();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();

    // 1. Colleges
    collegeA = await College.create({
      name: 'College of Engineering A',
      code: 'COLA-HIST',
      address: 'Campus A',
      email: 'admin@cola-hist.edu',
      phone: '9000000001',
      principal: 'Dr. Principal A',
      status: 'active',
    });

    collegeB = await College.create({
      name: 'College of Technology B',
      code: 'COLB-HIST',
      address: 'Campus B',
      email: 'admin@colb-hist.edu',
      phone: '9000000002',
      principal: 'Dr. Principal B',
      status: 'active',
    });

    // 2. Hierarchy in College A
    departmentA = await Department.create({
      collegeId: collegeA._id,
      name: 'Computer Science & Engineering',
      code: 'CSE-HIST',
      status: 'active',
    });

    courseA = await Course.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      name: 'Diploma in Computer Engineering',
      code: 'DCE-HIST',
      durationYears: 3,
      status: 'active',
    });

    academicYearA = await AcademicYear.create({
      collegeId: collegeA._id,
      name: '2026-2027',
      code: 'AY26-27-HIST',
      startDate: new Date('2026-06-01'),
      endDate: new Date('2027-05-31'),
      status: 'active',
      isCurrent: true,
    });

    semesterA = await Semester.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      name: 'Semester 5',
      number: 5,
      type: 'ODD',
      startDate: new Date('2026-06-01'),
      endDate: new Date('2026-11-30'),
      isCurrent: true,
      status: 'active',
    });

    sectionA = await Section.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      name: 'A',
      capacity: 60,
    });

    await Section.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      name: 'B',
      capacity: 60,
    });

    subjectIME = await Subject.create({
      collegeId: collegeA._id,
      courseId: courseA._id,
      departmentId: departmentA._id,
      semesterId: semesterA._id,
      name: 'Information Management & Enterprise Systems',
      code: 'IME-501',
      type: 'THEORY',
      credits: 4,
    });

    // 3. Users in College A
    adminUserA = await User.create({
      collegeId: collegeA._id,
      email: 'admin@cola-hist.edu',
      password: 'password123',
      name: 'Dean Admin A',
      role: AppRole.COLLEGE_ADMIN,
    });

    facultyUserA = await User.create({
      collegeId: collegeA._id,
      email: 'faculty@cola-hist.edu',
      password: 'password123',
      name: 'Prof. Alan Turing',
      role: AppRole.FACULTY,
    });

    facultyDocA = await Faculty.create({
      collegeId: collegeA._id,
      userId: facultyUserA._id,
      departmentId: departmentA._id,
      name: 'Prof. Alan Turing',
      email: 'faculty@cola-hist.edu',
      employeeId: 'EMP-HIST-001',
      designation: 'Professor',
      status: 'active',
    });

    facultyAssignmentA = await FacultyAssignment.create({
      collegeId: collegeA._id,
      facultyId: facultyDocA._id,
      facultyName: facultyDocA.name,
      courseId: courseA._id,
      subjectId: subjectIME._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      departmentId: departmentA._id,
      role: 'PRIMARY',
      status: 'active',
      isActive: true,
    });

    studentUserA = await User.create({
      collegeId: collegeA._id,
      email: 'student@cola-hist.edu',
      password: 'password123',
      name: 'Student Unauthorized',
      role: AppRole.STUDENT,
    });

    // 4. User in College B
    adminUserB = await User.create({
      collegeId: collegeB._id,
      email: 'admin@colb-hist.edu',
      password: 'password123',
      name: 'Dean Admin B',
      role: AppRole.COLLEGE_ADMIN,
    });

    // 5. Students in Section A (Students 1 to 5)
    studentDocsA = [];
    studentEnrollmentsA = [];
    for (let i = 1; i <= 5; i++) {
      const u = await User.create({
        collegeId: collegeA._id,
        email: `student_hist${i}@cola.edu`,
        password: 'password123',
        name: `Student ${i}`,
        role: AppRole.STUDENT,
      });

      const s = await Student.create({
        collegeId: collegeA._id,
        userId: u._id,
        departmentId: departmentA._id,
        courseId: courseA._id,
        name: `Student ${i}`,
        email: `student_hist${i}@cola.edu`,
        admissionNumber: `ADM-2026-00${i}`,
        instituteId: `23A00${i}`, // Student PIN
        rollNumber: `CS50${i}`,
        status: 'active',
        academicYearId: academicYearA._id,
      });
      studentDocsA.push(s);

      const se = await StudentEnrollment.create({
        collegeId: collegeA._id,
        studentId: s._id,
        departmentId: departmentA._id,
        courseId: courseA._id,
        academicYearId: academicYearA._id,
        semesterId: semesterA._id,
        sectionId: sectionA._id,
        rollNumber: `CS50${i}`,
        status: 'active',
        enrollmentDate: new Date('2026-06-01'),
      });
      studentEnrollmentsA.push(se);
    }
  });

  // Helper to run full upload -> validate -> confirm pipeline
  async function runImportPipeline(opts: {
    fileName: string;
    csvContent: string;
    dataType: ImportDataType;
    defaultMaxMarks?: number;
    allowPartial?: boolean;
    user?: any;
    academicContext?: Record<string, string>;
  }) {
    const user = opts.user || adminUserA;
    const uploadRes = await request(app)
      .post('/api/v1/imports/upload')
      .set('Authorization', authHeader(user))
      .send({
        fileName: opts.fileName,
        fileBase64: Buffer.from(opts.csvContent).toString('base64'),
        dataType: opts.dataType,
        defaultMaxMarks: opts.defaultMaxMarks,
      });

    if (uploadRes.status !== 201) return uploadRes;

    const batchId = uploadRes.body.data.batch._id;

    const validateRes = await request(app)
      .post(`/api/v1/imports/${batchId}/validate`)
      .set('Authorization', authHeader(user))
      .send({
        sectionId: sectionA._id.toString(),
        academicYearId: academicYearA._id.toString(),
        semesterId: semesterA._id.toString(),
        subjectId: subjectIME._id.toString(),
        facultyAssignmentId: facultyAssignmentA._id.toString(),
        ...opts.academicContext,
      });

    if (validateRes.status !== 200) return validateRes;

    const confirmRes = await request(app)
      .post(`/api/v1/imports/${batchId}/confirm`)
      .set('Authorization', authHeader(user))
      .send({ allowPartial: opts.allowPartial ?? false });

    return confirmRes;
  }

  // =========================================================================
  // SCENARIO 1: Historical assessment import creates canonical Assessment
  // =========================================================================
  test('1. Historical assessment import creates canonical Assessment', async () => {
    const csvContent = 'PIN,Marks\n23A001,22\n23A002,24\n';
    const res = await runImportPipeline({
      fileName: 'Unit_Test_1.csv',
      csvContent,
      dataType: ImportDataType.ASSESSMENT,
      defaultMaxMarks: 25,
    });

    expect(res.status).toBe(200);
    expect(res.body.data.importedCount).toBe(2);

    const assessment = await InternalAssessment.findOne({
      collegeId: collegeA._id,
      subjectId: subjectIME._id,
      sectionId: sectionA._id,
    });

    expect(assessment).not.toBeNull();
    expect(assessment!.title).toBe('Unit_Test_1');
    expect(assessment!.maximumMarks).toBe(25);
    expect(assessment!.status).toBe(AssessmentStatus.LOCKED);
  });

  // =========================================================================
  // SCENARIO 2: Historical assessment marks resolve to StudentEnrollment
  // =========================================================================
  test('2. Historical assessment marks resolve to StudentEnrollment', async () => {
    const csvContent = 'PIN,Marks\n23A001,21\n23A002,23\n';
    await runImportPipeline({
      fileName: 'UT1_marks.csv',
      csvContent,
      dataType: ImportDataType.ASSESSMENT,
      defaultMaxMarks: 25,
    });

    const marks = await AssessmentMark.find({
      collegeId: collegeA._id,
      subjectId: subjectIME._id,
    });

    expect(marks).toHaveLength(2);
    const enrollmentIds = marks.map((m) => m.studentEnrollmentId.toString());
    expect(enrollmentIds).toContain(studentEnrollmentsA[0]._id.toString());
    expect(enrollmentIds).toContain(studentEnrollmentsA[1]._id.toString());
  });

  // =========================================================================
  // SCENARIO 3: Historical assessment carries IMPORTED provenance
  // =========================================================================
  test('3. Historical assessment carries IMPORTED provenance', async () => {
    const csvContent = 'PIN,Marks\n23A001,22\n';
    const res = await runImportPipeline({
      fileName: 'UT_provenance.csv',
      csvContent,
      dataType: ImportDataType.ASSESSMENT,
      defaultMaxMarks: 25,
    });

    const batch = res.body.data.batch;
    const assessment = await InternalAssessment.findOne({ collegeId: collegeA._id, subjectId: subjectIME._id });
    const mark = await AssessmentMark.findOne({ collegeId: collegeA._id, subjectId: subjectIME._id });

    expect(assessment!.sourceType).toBe('IMPORTED');
    expect(assessment!.importBatchId).toBe(batch.importBatchId);
    expect(mark!.sourceType).toBe('IMPORTED');
    expect(mark!.importBatchId).toBe(batch.importBatchId);
  });

  // =========================================================================
  // SCENARIO 4: Assessment category mapping works for UT/Internal variants
  // =========================================================================
  test('4. Assessment category mapping works for UT/Internal variants', () => {
    expect(normalizeAssessmentCategory('Unit Test 1').category).toBe(AssessmentType.UNIT_TEST);
    expect(normalizeAssessmentCategory('Unit Test 1').title).toBe('Unit Test 1');

    expect(normalizeAssessmentCategory('UT-1').category).toBe(AssessmentType.UNIT_TEST);
    expect(normalizeAssessmentCategory('UT 1').category).toBe(AssessmentType.UNIT_TEST);
    expect(normalizeAssessmentCategory('First Unit Test').category).toBe(AssessmentType.UNIT_TEST);

    expect(normalizeAssessmentCategory('Internal 1').category).toBe(AssessmentType.INTERNAL);
    expect(normalizeAssessmentCategory('IA-1').category).toBe(AssessmentType.INTERNAL);
    expect(normalizeAssessmentCategory('Internal Assessment 2').category).toBe(AssessmentType.INTERNAL);

    expect(normalizeAssessmentCategory('Mid-Term Exam').category).toBe(AssessmentType.MID_TERM);
    expect(normalizeAssessmentCategory('Model Exam').category).toBe(AssessmentType.MODEL_EXAM);
    expect(normalizeAssessmentCategory('Lab Exam 1').category).toBe(AssessmentType.LAB_EXAM);
    expect(normalizeAssessmentCategory('Practical Test').category).toBe(AssessmentType.PRACTICAL);
  });

  // =========================================================================
  // SCENARIO 5: Assessment zero marks remain valid
  // =========================================================================
  test('5. Assessment zero marks remain valid', async () => {
    const csvContent = 'PIN,Marks\n23A001,0\n';
    const res = await runImportPipeline({
      fileName: 'UT_zero_marks.csv',
      csvContent,
      dataType: ImportDataType.ASSESSMENT,
      defaultMaxMarks: 25,
    });

    expect(res.status).toBe(200);
    const mark = await AssessmentMark.findOne({
      collegeId: collegeA._id,
      studentEnrollmentId: studentEnrollmentsA[0]._id,
    });

    expect(mark).not.toBeNull();
    expect(mark!.marks).toBe(0);
    expect(mark!.status).toBe(StudentMarkStatus.PRESENT);
  });

  // =========================================================================
  // SCENARIO 6: Assessment ABSENT does not become mark 0
  // =========================================================================
  test('6. Assessment ABSENT does not become mark 0', async () => {
    const csvContent = 'PIN,Marks,Status\n23A001,,ABSENT\n23A002,ABS,\n';
    const res = await runImportPipeline({
      fileName: 'UT_absent.csv',
      csvContent,
      dataType: ImportDataType.ASSESSMENT,
      defaultMaxMarks: 25,
    });

    expect(res.status).toBe(200);

    const mark1 = await AssessmentMark.findOne({
      collegeId: collegeA._id,
      studentEnrollmentId: studentEnrollmentsA[0]._id,
    });
    const mark2 = await AssessmentMark.findOne({
      collegeId: collegeA._id,
      studentEnrollmentId: studentEnrollmentsA[1]._id,
    });

    expect(mark1!.status).toBe(StudentMarkStatus.ABSENT);
    expect(mark1!.marks).toBeNull();

    expect(mark2!.status).toBe(StudentMarkStatus.ABSENT);
    expect(mark2!.marks).toBeNull();
  });

  // =========================================================================
  // SCENARIO 7: Ambiguous faculty assignment is rejected
  // =========================================================================
  test('7. Ambiguous faculty assignment is rejected', async () => {
    // Create second faculty and second faculty assignment for the same subject & section
    const secondUser = await User.create({
      collegeId: collegeA._id,
      email: 'second_faculty@cola.edu',
      password: 'password123',
      name: 'Prof. Second Faculty',
      role: AppRole.FACULTY,
    });
    const secondFaculty = await Faculty.create({
      collegeId: collegeA._id,
      userId: secondUser._id,
      departmentId: departmentA._id,
      name: 'Prof. Second Faculty',
      email: 'second_faculty@cola.edu',
      employeeId: 'EMP-HIST-002',
      designation: 'Assistant Professor',
      status: 'active',
    });
    await FacultyAssignment.create({
      collegeId: collegeA._id,
      facultyId: secondFaculty._id,
      facultyName: secondFaculty.name,
      courseId: courseA._id,
      subjectId: subjectIME._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      departmentId: departmentA._id,
      role: 'CO_TEACHER',
      status: 'active',
      isActive: true,
    });

    // Run import pipeline WITHOUT facultyAssignmentId
    const csvContent = 'PIN,Marks\n23A001,20\n';
    const uploadRes = await request(app)
      .post('/api/v1/imports/upload')
      .set('Authorization', authHeader(adminUserA))
      .send({
        fileName: 'ambiguous_faculty.csv',
        fileBase64: Buffer.from(csvContent).toString('base64'),
        dataType: ImportDataType.ASSESSMENT,
        defaultMaxMarks: 25,
      });

    const batchId = uploadRes.body.data.batch._id;

    await request(app)
      .post(`/api/v1/imports/${batchId}/validate`)
      .set('Authorization', authHeader(adminUserA))
      .send({
        sectionId: sectionA._id.toString(),
        academicYearId: academicYearA._id.toString(),
        semesterId: semesterA._id.toString(),
        subjectId: subjectIME._id.toString(),
        // facultyAssignmentId omitted!
      });

    const confirmRes = await request(app)
      .post(`/api/v1/imports/${batchId}/confirm`)
      .set('Authorization', authHeader(adminUserA))
      .send({ allowPartial: false });

    expect(confirmRes.status).toBe(400);
    expect(confirmRes.body.error?.message).toContain('Multiple FacultyAssignments match this subject and section');
  });

  // =========================================================================
  // SCENARIO 8: Historical assessment duplicate import is idempotent
  // =========================================================================
  test('8. Historical assessment duplicate import is idempotent', async () => {
    const csvContent = 'PIN,Marks\n23A001,22\n23A002,24\n';

    // First import
    const res1 = await runImportPipeline({
      fileName: 'idempotent_test.csv',
      csvContent,
      dataType: ImportDataType.ASSESSMENT,
      defaultMaxMarks: 25,
    });
    expect(res1.status).toBe(200);

    // Second import with identical marks
    const res2 = await runImportPipeline({
      fileName: 'idempotent_test.csv',
      csvContent,
      dataType: ImportDataType.ASSESSMENT,
      defaultMaxMarks: 25,
    });
    expect(res2.status).toBe(200);

    // Marks count remains exactly 2 (no duplicates!)
    const totalMarks = await AssessmentMark.countDocuments({
      collegeId: collegeA._id,
      subjectId: subjectIME._id,
    });
    expect(totalMarks).toBe(2);
  });

  // =========================================================================
  // SCENARIO 9: Historical assessment conflict with existing live mark is rejected safely
  // =========================================================================
  test('9. Historical assessment conflict with existing live mark is rejected safely', async () => {
    // 1. Create a live assessment and mark
    const liveAssessment = await InternalAssessment.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      subjectId: subjectIME._id,
      facultyAssignmentId: facultyAssignmentA._id,
      title: 'Conflict_Assessment',
      assessmentType: AssessmentType.UNIT_TEST,
      maximumMarks: 25,
      passMarks: 10,
      status: AssessmentStatus.SUBMITTED,
      sourceType: 'LIVE',
    });

    await AssessmentMark.create({
      collegeId: collegeA._id,
      assessmentId: liveAssessment._id,
      facultyAssignmentId: facultyAssignmentA._id,
      subjectId: subjectIME._id,
      studentEnrollmentId: studentEnrollmentsA[0]._id,
      studentId: studentDocsA[0]._id,
      studentName: 'Student 1',
      marks: 22, // Live mark is 22
      maximumMarks: 25,
      status: StudentMarkStatus.PRESENT,
      isLocked: false,
      sourceType: 'LIVE',
    });

    // 2. Try to import historical spreadsheet with CONFLICTING mark (18 instead of 22)
    const csvContent = 'PIN,Marks\n23A001,18\n';
    const uploadRes = await request(app)
      .post('/api/v1/imports/upload')
      .set('Authorization', authHeader(adminUserA))
      .send({
        fileName: 'Conflict_Assessment.csv',
        fileBase64: Buffer.from(csvContent).toString('base64'),
        dataType: ImportDataType.ASSESSMENT,
        defaultMaxMarks: 25,
      });

    const batchId = uploadRes.body.data.batch._id;

    await request(app)
      .post(`/api/v1/imports/${batchId}/validate`)
      .set('Authorization', authHeader(adminUserA))
      .send({
        sectionId: sectionA._id.toString(),
        academicYearId: academicYearA._id.toString(),
        semesterId: semesterA._id.toString(),
        subjectId: subjectIME._id.toString(),
        facultyAssignmentId: facultyAssignmentA._id.toString(),
      });

    const confirmRes = await request(app)
      .post(`/api/v1/imports/${batchId}/confirm`)
      .set('Authorization', authHeader(adminUserA))
      .send({ allowPartial: false });

    expect(confirmRes.status).toBe(400);
    expect(confirmRes.body.error?.message).toContain('IMPORT_CONFLICT_WITH_EXISTING_RECORD');

    // Live mark was NOT overwritten
    const preservedMark = await AssessmentMark.findOne({
      collegeId: collegeA._id,
      assessmentId: liveAssessment._id,
      studentEnrollmentId: studentEnrollmentsA[0]._id,
    });
    expect(preservedMark!.marks).toBe(22);
    expect(preservedMark!.sourceType).toBe('LIVE');
  });

  // =========================================================================
  // SCENARIO 10: Detailed historical attendance imports into canonical attendance structures
  // =========================================================================
  test('10. Detailed historical attendance imports into canonical attendance structures', async () => {
    const csvContent =
      'PIN,Date,Status\n' +
      '23A001,2026-02-03,P\n' +
      '23A002,2026-02-03,A\n';

    const res = await runImportPipeline({
      fileName: 'detailed_attendance.csv',
      csvContent,
      dataType: ImportDataType.ATTENDANCE,
    });

    expect(res.status).toBe(200);
    expect(res.body.data.importedCount).toBe(2);

    const session = await AttendanceSession.findOne({
      collegeId: collegeA._id,
      subjectId: subjectIME._id,
      sectionId: sectionA._id,
    });

    expect(session).not.toBeNull();
    expect(session!.date).toEqual(new Date('2026-02-03T00:00:00.000Z'));
    expect(session!.records).toHaveLength(2);

    const records = await AttendanceRecord.find({ sessionId: session!._id });
    expect(records).toHaveLength(2);

    const pRecord = records.find((r) => r.studentId.toString() === studentDocsA[0]._id.toString());
    const aRecord = records.find((r) => r.studentId.toString() === studentDocsA[1]._id.toString());

    expect(pRecord!.status).toBe(AttendanceStatus.PRESENT);
    expect(aRecord!.status).toBe(AttendanceStatus.ABSENT);
  });

  // =========================================================================
  // SCENARIO 11: Detailed historical attendance carries provenance
  // =========================================================================
  test('11. Detailed historical attendance carries provenance', async () => {
    const csvContent = 'PIN,Date,Status\n23A001,2026-02-04,P\n';
    const res = await runImportPipeline({
      fileName: 'detailed_provenance.csv',
      csvContent,
      dataType: ImportDataType.ATTENDANCE,
    });

    const batch = res.body.data.batch;
    const session = await AttendanceSession.findOne({ collegeId: collegeA._id, date: new Date('2026-02-04T00:00:00.000Z') });
    const record = await AttendanceRecord.findOne({ collegeId: collegeA._id, sessionId: session!._id });

    expect(session!.sourceType).toBe('IMPORTED');
    expect(session!.importBatchId).toBe(batch.importBatchId);
    expect(record!.sourceType).toBe('IMPORTED');
    expect(record!.importBatchId).toBe(batch.importBatchId);
  });

  // =========================================================================
  // SCENARIO 12: Historical attendance summary does not create fake sessions
  // =========================================================================
  test('12. Historical attendance summary does not create fake sessions', async () => {
    const csvContent =
      'PIN,ClassesHeld,PresentCount,Period\n' +
      '23A001,20,18,January 2026\n' +
      '23A002,20,15,January 2026\n';

    const res = await runImportPipeline({
      fileName: 'monthly_attendance_summary.csv',
      csvContent,
      dataType: ImportDataType.ATTENDANCE,
    });

    expect(res.status).toBe(200);
    expect(res.body.data.importedCount).toBe(2);

    // Strictly verify NO AttendanceSession documents were manufactured
    const sessionCount = await AttendanceSession.countDocuments({ collegeId: collegeA._id });
    expect(sessionCount).toBe(0);

    const summaries = await HistoricalAttendanceSummary.find({ collegeId: collegeA._id });
    expect(summaries).toHaveLength(2);

    const s1 = summaries.find((s) => s.studentId.toString() === studentDocsA[0]._id.toString());
    expect(s1!.classesHeld).toBe(20);
    expect(s1!.presentCount).toBe(18);
    expect(s1!.absentCount).toBe(2);
    expect(s1!.attendancePercentage).toBe(90);
    expect(s1!.precisionLevel).toBe('PERIOD_SUMMARY');
    expect(s1!.periodLabel).toBe('January 2026');
  });

  // =========================================================================
  // SCENARIO 13: Percentage-only attendance does not create fake sessions
  // =========================================================================
  test('13. Percentage-only attendance does not create fake sessions', async () => {
    const csvContent =
      'PIN,AttendancePercentage,Period\n' +
      '23A001,88%,Jan-Jun 2026\n' +
      '23A002,92%,Jan-Jun 2026\n';

    const res = await runImportPipeline({
      fileName: 'pct_only_attendance.csv',
      csvContent,
      dataType: ImportDataType.ATTENDANCE,
    });

    expect(res.status).toBe(200);

    // Strictly verify NO AttendanceSession documents were manufactured
    const sessionCount = await AttendanceSession.countDocuments({ collegeId: collegeA._id });
    expect(sessionCount).toBe(0);

    const summaries = await HistoricalAttendanceSummary.find({ collegeId: collegeA._id });
    expect(summaries).toHaveLength(2);

    const s1 = summaries.find((s) => s.studentId.toString() === studentDocsA[0]._id.toString());
    expect(s1!.attendancePercentage).toBe(88);
    expect(s1!.classesHeld).toBeNull();
    expect(s1!.presentCount).toBeNull();
    expect(s1!.absentCount).toBeNull();
    expect(s1!.precisionLevel).toBe('PERCENTAGE_ONLY');
  });

  // =========================================================================
  // SCENARIO 14: Percentage-only attendance does not participate in denominator aggregation
  // =========================================================================
  test('14. Percentage-only attendance does not participate in denominator aggregation', async () => {
    // Ingest percentage-only historical summary of 90%
    await HistoricalAttendanceSummary.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      subjectId: subjectIME._id,
      studentEnrollmentId: studentEnrollmentsA[0]._id,
      studentId: studentDocsA[0]._id,
      periodLabel: 'H1 2026',
      attendancePercentage: 90,
      classesHeld: null,
      presentCount: null,
      absentCount: null,
      precisionLevel: 'PERCENTAGE_ONLY',
      sourceType: 'IMPORTED',
      importBatchId: 'IMP-PCT-001',
    });

    const agg = await AttendanceAggregationService.aggregateForStudent(
      collegeA._id,
      studentDocsA[0]._id,
      { subjectId: subjectIME._id }
    );

    // Denominator counts remain 0
    expect(agg.detailedMetrics.totalHeld).toBe(0);
    expect(agg.detailedMetrics.totalPresent).toBe(0);
    expect(agg.detailedMetrics.percentage).toBe(0);
    expect(agg.hasDetailedData).toBe(false);

    // Percentage-only data is returned separately without corruption
    expect(agg.hasPercentageOnlyData).toBe(true);
    expect(agg.historicalPercentageMetrics).toHaveLength(1);
    expect(agg.historicalPercentageMetrics[0].percentage).toBe(90);
    expect(agg.historicalPercentageMetrics[0].periodLabel).toBe('H1 2026');
  });

  // =========================================================================
  // SCENARIO 15: Detailed historical attendance combines correctly with live counts
  // =========================================================================
  test('15. Detailed historical attendance combines correctly with live counts', async () => {
    const student1 = studentDocsA[0];
    const enrollment1 = studentEnrollmentsA[0];

    // Historical Period Summary: Held = 120, Present = 108 (90%)
    await HistoricalAttendanceSummary.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      subjectId: subjectIME._id,
      studentEnrollmentId: enrollment1._id,
      studentId: student1._id,
      periodLabel: 'Jan-Apr 2026',
      classesHeld: 120,
      presentCount: 108,
      absentCount: 12,
      attendancePercentage: 90,
      precisionLevel: 'PERIOD_SUMMARY',
      sourceType: 'IMPORTED',
      importBatchId: 'IMP-SUM-120',
    });

    // Live Records: Held = 60, Present = 54 (90%)
    const session = await AttendanceSession.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      subjectId: subjectIME._id,
      subjectName: 'IME',
      sectionId: sectionA._id,
      facultyId: facultyDocA._id,
      timeSlot: 'Slot 1',
      date: new Date('2026-07-15'),
      status: AttendanceSessionStatus.LOCKED,
      isSubmitted: true,
      isLocked: true,
      sourceType: 'LIVE',
      records: [],
    });

    // Simulate 54 Present and 6 Absent live records
    const recordsToInsert = [];
    for (let i = 0; i < 60; i++) {
      recordsToInsert.push({
        collegeId: collegeA._id,
        sessionId: session._id,
        studentId: student1._id,
        studentEnrollmentId: enrollment1._id,
        studentName: student1.name,
        rollNumber: student1.rollNumber,
        subjectId: subjectIME._id,
        facultyId: facultyDocA._id,
        date: new Date('2026-07-15'),
        timeSlot: 'Slot 1',
        status: i < 54 ? AttendanceStatus.PRESENT : AttendanceStatus.ABSENT,
        sourceType: 'LIVE',
        isCancelled: false,
      });
    }
    await AttendanceRecord.insertMany(recordsToInsert);

    const agg = await AttendanceAggregationService.aggregateForStudent(
      collegeA._id,
      student1._id,
      { subjectId: subjectIME._id }
    );

    // Overall: Held = 180 (120 + 60), Present = 162 (108 + 54), Percentage = 90%
    expect(agg.detailedMetrics.totalHeld).toBe(180);
    expect(agg.detailedMetrics.totalPresent).toBe(162);
    expect(agg.detailedMetrics.totalAbsent).toBe(18);
    expect(agg.detailedMetrics.percentage).toBe(90);
    expect(agg.detailedMetrics.historicalDetailedHeld).toBe(120);
    expect(agg.detailedMetrics.liveHeld).toBe(60);
  });

  // =========================================================================
  // SCENARIO 16: Tenant isolation blocks cross-college imports
  // =========================================================================
  test('16. Tenant isolation blocks cross-college imports', async () => {
    const csvContent = 'PIN,Marks\n23A001,20\n';
    const uploadRes = await request(app)
      .post('/api/v1/imports/upload')
      .set('Authorization', authHeader(adminUserA))
      .send({
        fileName: 'tenant_isolation.csv',
        fileBase64: Buffer.from(csvContent).toString('base64'),
        dataType: ImportDataType.ASSESSMENT,
        defaultMaxMarks: 25,
      });

    const batchId = uploadRes.body.data.batch._id;

    // College B Admin attempts to confirm Batch A
    const crossRes = await request(app)
      .post(`/api/v1/imports/${batchId}/confirm`)
      .set('Authorization', authHeader(adminUserB))
      .send({ allowPartial: false });

    expect(crossRes.status).toBe(404);
  });

  // =========================================================================
  // SCENARIO 17: Unauthorized users cannot confirm historical imports
  // =========================================================================
  test('17. Unauthorized users cannot confirm historical imports', async () => {
    const csvContent = 'PIN,Marks\n23A001,20\n';
    const uploadRes = await request(app)
      .post('/api/v1/imports/upload')
      .set('Authorization', authHeader(adminUserA))
      .send({
        fileName: 'unauthorized_check.csv',
        fileBase64: Buffer.from(csvContent).toString('base64'),
        dataType: ImportDataType.ASSESSMENT,
        defaultMaxMarks: 25,
      });

    const batchId = uploadRes.body.data.batch._id;

    // Student attempts to confirm
    const studentRes = await request(app)
      .post(`/api/v1/imports/${batchId}/confirm`)
      .set('Authorization', authHeader(studentUserA))
      .send({ allowPartial: false });

    expect(studentRes.status).toBe(403);
  });

  // =========================================================================
  // SCENARIO 18: ImportBatch remains traceable
  // =========================================================================
  test('18. ImportBatch remains traceable', async () => {
    const csvContent = 'PIN,Marks\n23A001,20\n';
    const res = await runImportPipeline({
      fileName: 'traceable.csv',
      csvContent,
      dataType: ImportDataType.ASSESSMENT,
      defaultMaxMarks: 25,
    });

    const batchId = res.body.data.batch._id;
    const batch = await ImportBatch.findById(batchId);

    expect(batch).not.toBeNull();
    expect(batch!.status).toBe(ImportBatchStatus.COMPLETED);
    expect(batch!.importedCount).toBe(1);
    expect(batch!.failedCount).toBe(0);
    expect(batch!.importBatchId).toMatch(/^IMP-\d{8}-[A-Z0-9]{4}$/);
  });

  // =========================================================================
  // SCENARIO 19: Repeated confirmation does not duplicate records
  // =========================================================================
  test('19. Repeated confirmation does not duplicate records', async () => {
    const csvContent = 'PIN,Marks\n23A001,20\n';
    const res = await runImportPipeline({
      fileName: 'repeated_confirm.csv',
      csvContent,
      dataType: ImportDataType.ASSESSMENT,
      defaultMaxMarks: 25,
    });

    expect(res.status).toBe(200);
    const batchId = res.body.data.batch._id;

    // Repeated confirmation attempt
    const repeatRes = await request(app)
      .post(`/api/v1/imports/${batchId}/confirm`)
      .set('Authorization', authHeader(adminUserA))
      .send({ allowPartial: false });

    expect(repeatRes.status).toBe(200);
    expect(repeatRes.body.data.message).toContain('already been completed');

    const marksCount = await AssessmentMark.countDocuments({
      collegeId: collegeA._id,
      subjectId: subjectIME._id,
    });
    expect(marksCount).toBe(1);
  });

  // =========================================================================
  // SCENARIO 20: Malformed/ambiguous historical data remains reviewable instead of being silently guessed
  // =========================================================================
  test('20. Malformed/ambiguous historical data remains reviewable instead of being silently guessed', async () => {
    const csvContent =
      'PIN,Marks\n' +
      'UNKNOWN_PIN_999,20\n' + // Unresolved student
      '23A001,-5\n' + // Negative marks
      '23A002,50\n'; // Exceeds max marks 25

    const uploadRes = await request(app)
      .post('/api/v1/imports/upload')
      .set('Authorization', authHeader(adminUserA))
      .send({
        fileName: 'malformed_data.csv',
        fileBase64: Buffer.from(csvContent).toString('base64'),
        dataType: ImportDataType.ASSESSMENT,
        defaultMaxMarks: 25,
      });

    const batchId = uploadRes.body.data.batch._id;

    const validateRes = await request(app)
      .post(`/api/v1/imports/${batchId}/validate`)
      .set('Authorization', authHeader(adminUserA))
      .send({
        sectionId: sectionA._id.toString(),
        academicYearId: academicYearA._id.toString(),
        semesterId: semesterA._id.toString(),
        subjectId: subjectIME._id.toString(),
        facultyAssignmentId: facultyAssignmentA._id.toString(),
      });

    expect(validateRes.status).toBe(200);
    const summary = validateRes.body.data.summary;
    const previewRows = validateRes.body.data.previewRows;

    expect(summary.errorCount).toBeGreaterThanOrEqual(2);
    expect(previewRows[0].status).toBe(RowValidationStatus.INVALID);
    expect(previewRows[1].issues[0].message).toContain('Negative marks');
    expect(previewRows[2].issues[0].message).toContain('exceed maximum marks');
  });
});
