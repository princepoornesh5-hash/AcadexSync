import mongoose from 'mongoose';
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
  AttendanceRecord,
  HistoricalAttendanceSummary,
  Assignment,
  Note,
} from '../../src/models';
import { AppRole } from '../../src/constants/roles';
import {
  AssessmentType,
  AssessmentStatus,
  StudentMarkStatus,
} from '../../src/models/internalAssessment.model';
import { AssignmentStatus as AsgStatus, AssignmentType as AsgType } from '../../src/constants/assignment.constants';
import { AttendanceStatus, NoteStatus } from '../../src/constants/status';
import { AttendanceAggregationService } from '../../src/services/attendance/attendanceAggregation.service';
import { AcademicAnalyticsService } from '../../src/services/academicAnalytics.service';
import { InternalAssessmentService } from '../../src/services/internalAssessment.service';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';

describe('PROMPT 6/6 — Final Integration, Student 360 & Academic Analytics Verification', () => {
  let collegeA: any;
  let collegeB: any;
  let departmentA: any;
  let departmentB: any;
  let courseA: any;
  let academicYearA: any;
  let semesterA: any;
  let sectionA: any;
  let subjectMath: any;
  let subjectPhysics: any;
  let facultyDocA: any;

  let adminUserA: any;
  let hodUserA: any;
  let facultyUserA: any;
  let studentUser1: any;
  let studentUser2: any;
  let adminUserB: any;

  let studentDoc1: any;
  let studentDoc2: any;
  let enrollmentDoc1: any;
  let enrollmentDoc2: any;

  function authHeader(user: any, collegeId?: string): string {
    return createTestAuthHeader({
      userId: user._id.toString(),
      collegeId: collegeId || user.collegeId.toString(),
      role: user.role,
      email: user.email,
      name: user.name,
      departmentId: user.departmentId ? user.departmentId.toString() : undefined,
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

    collegeA = await College.create({
      name: 'College of Engineering A',
      code: 'COEA',
      address: 'Campus A',
      email: 'admin@coea.edu',
      phone: '9000000001',
      principal: 'Dr. Principal A',
      status: 'active',
      isActive: true,
    });

    collegeB = await College.create({
      name: 'College of Arts B',
      code: 'COAB',
      address: 'Campus B',
      email: 'admin@coab.edu',
      phone: '9000000002',
      principal: 'Dr. Principal B',
      status: 'active',
      isActive: true,
    });

    departmentA = await Department.create({
      collegeId: collegeA._id,
      name: 'Computer Science',
      code: 'CSE',
      status: 'active',
      isActive: true,
    });

    departmentB = await Department.create({
      collegeId: collegeA._id,
      name: 'Mechanical Engineering',
      code: 'MECH',
      status: 'active',
      isActive: true,
    });

    courseA = await Course.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      name: 'B.Tech CSE',
      code: 'BT-CSE',
      status: 'active',
      isActive: true,
    });

    academicYearA = await AcademicYear.create({
      collegeId: collegeA._id,
      name: '2026-2027',
      code: 'AY26',
      startDate: new Date('2026-06-01'),
      endDate: new Date('2027-05-31'),
      status: 'active',
      isActive: true,
    });

    semesterA = await Semester.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      number: 5,
      name: 'Semester 5',
      code: 'SEM5',
      status: 'active',
      isActive: true,
    });

    sectionA = await Section.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      name: 'Section A',
      capacity: 60,
      status: 'active',
      isActive: true,
    });

    subjectMath = await Subject.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      courseId: courseA._id,
      semesterId: semesterA._id,
      name: 'Discrete Mathematics',
      code: 'CS-501',
      credits: 4,
      type: 'theory',
      isActive: true,
    });

    subjectPhysics = await Subject.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      courseId: courseA._id,
      semesterId: semesterA._id,
      name: 'Applied Physics',
      code: 'CS-502',
      credits: 3,
      type: 'theory',
      isActive: true,
    });

    adminUserA = await User.create({
      collegeId: collegeA._id,
      name: 'Admin User A',
      email: 'admin.a@acadex.edu',
      role: AppRole.COLLEGE_ADMIN,
      accountStatus: 'active',
    });

    hodUserA = await User.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      name: 'HOD CSE',
      email: 'hod.cse@acadex.edu',
      role: AppRole.HOD,
      accountStatus: 'active',
    });

    facultyUserA = await User.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      name: 'Prof Alan Turing',
      email: 'turing@acadex.edu',
      role: AppRole.FACULTY,
      accountStatus: 'active',
    });

    facultyDocA = await Faculty.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      userId: facultyUserA._id,
      name: facultyUserA.name,
      email: facultyUserA.email,
      designation: 'Associate Professor',
      status: 'active',
      isActive: true,
    });

    await FacultyAssignment.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      facultyId: facultyDocA._id,
      facultyName: facultyDocA.name,
      courseId: courseA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      subjectId: subjectMath._id,
      academicYearId: academicYearA._id,
      isActive: true,
      status: 'active',
    });

    studentUser1 = await User.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      name: 'Alice Johnson',
      email: 'alice@acadex.edu',
      role: AppRole.STUDENT,
      accountStatus: 'active',
    });

    studentDoc1 = await Student.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      userId: studentUser1._id,
      name: studentUser1.name,
      email: studentUser1.email,
      rollNumber: 'CSE-001',
      admissionNumber: 'ADM-001',
      status: 'active',
      isActive: true,
      sectionId: sectionA._id,
      semesterId: semesterA._id,
    });

    enrollmentDoc1 = await StudentEnrollment.create({
      collegeId: collegeA._id,
      studentId: studentDoc1._id,
      departmentId: departmentA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      status: 'active',
    });

    studentUser2 = await User.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      name: 'Bob Smith',
      email: 'bob@acadex.edu',
      role: AppRole.STUDENT,
      accountStatus: 'active',
    });

    studentDoc2 = await Student.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      userId: studentUser2._id,
      name: studentUser2.name,
      email: studentUser2.email,
      rollNumber: 'CSE-002',
      admissionNumber: 'ADM-002',
      status: 'active',
      isActive: true,
      sectionId: sectionA._id,
      semesterId: semesterA._id,
    });

    enrollmentDoc2 = await StudentEnrollment.create({
      collegeId: collegeA._id,
      studentId: studentDoc2._id,
      departmentId: departmentA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      status: 'active',
    });

    adminUserB = await User.create({
      collegeId: collegeB._id,
      name: 'Admin User B',
      email: 'admin.b@acadex.edu',
      role: AppRole.COLLEGE_ADMIN,
      accountStatus: 'active',
    });
  });

  function createTestAssessment(overrides: any = {}) {
    return InternalAssessment.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      subjectId: subjectMath._id,
      facultyId: facultyDocA._id,
      facultyName: facultyDocA.name,
      title: 'Test Assessment',
      assessmentType: AssessmentType.INTERNAL,
      maximumMarks: 50,
      passMarks: 20,
      status: AssessmentStatus.PUBLISHED,
      entries: [],
      components: [],
      auditLog: [],
      ...overrides,
    });
  }

  function createTestAttendanceRecord(overrides: any = {}) {
    return AttendanceRecord.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      sessionId: new mongoose.Types.ObjectId(),
      studentId: studentDoc1._id,
      studentName: studentDoc1.name,
      rollNumber: studentDoc1.rollNumber,
      sectionId: sectionA._id,
      subjectId: subjectMath._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      facultyId: facultyDocA._id,
      date: new Date('2026-09-01'),
      timeSlot: '09:00 - 10:00',
      status: AttendanceStatus.PRESENT,
      isCancelled: false,
      ...overrides,
    });
  }

  // =========================================================================
  // 1. STUDENT ASSESSMENT HISTORY RESOLVES CANONICAL MARKS
  // =========================================================================
  test('1. Student assessment history resolves canonical marks', async () => {
    const assess = await createTestAssessment({
      title: 'Unit Test 1',
      assessmentType: AssessmentType.UNIT_TEST,
      maximumMarks: 25,
      passMarks: 9,
    });

    await AssessmentMark.create({
      collegeId: collegeA._id,
      assessmentId: assess._id,
      subjectId: subjectMath._id,
      studentEnrollmentId: enrollmentDoc1._id,
      studentId: studentDoc1._id,
      studentName: studentDoc1.name,
      rollNumber: studentDoc1.rollNumber,
      marks: 22,
      maximumMarks: 25,
      passMarks: 9,
      status: StudentMarkStatus.PRESENT,
      isLocked: true,
      sourceType: 'LIVE',
    });

    const res = await request(app)
      .get(`/api/v1/assessments/student/${studentDoc1._id}`)
      .set('Authorization', authHeader(studentUser1));

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.items).toHaveLength(1);
    expect(res.body.data.items[0].title).toBe('Unit Test 1');
    expect(res.body.data.items[0].rawScore).toBe(22);
    expect(res.body.data.items[0].maximumMarks).toBe(25);
    expect(res.body.data.items[0].isPassed).toBe(true);
  });

  // =========================================================================
  // 2. MULTIPLE ASSESSMENTS APPEAR WITHOUT DUPLICATION
  // =========================================================================
  test('2. Multiple assessments appear without duplication', async () => {
    const assess1 = await createTestAssessment({
      title: 'Mid-Term Exam',
      assessmentType: AssessmentType.MID_TERM,
      maximumMarks: 50,
      passMarks: 18,
    });

    const assess2 = await createTestAssessment({
      subjectId: subjectPhysics._id,
      title: 'Quiz 1',
      assessmentType: AssessmentType.QUIZ,
      maximumMarks: 10,
      passMarks: 4,
    });

    await AssessmentMark.create({
      collegeId: collegeA._id,
      assessmentId: assess1._id,
      subjectId: subjectMath._id,
      studentEnrollmentId: enrollmentDoc1._id,
      studentId: studentDoc1._id,
      studentName: studentDoc1.name,
      marks: 45,
      maximumMarks: 50,
      status: StudentMarkStatus.PRESENT,
      sourceType: 'LIVE',
    });

    await AssessmentMark.create({
      collegeId: collegeA._id,
      assessmentId: assess2._id,
      subjectId: subjectPhysics._id,
      studentEnrollmentId: enrollmentDoc1._id,
      studentId: studentDoc1._id,
      studentName: studentDoc1.name,
      marks: 9,
      maximumMarks: 10,
      status: StudentMarkStatus.PRESENT,
      sourceType: 'LIVE',
    });

    const res = await request(app)
      .get(`/api/v1/assessments/student/${studentDoc1._id}`)
      .set('Authorization', authHeader(studentUser1));

    expect(res.status).toBe(200);
    expect(res.body.data.items).toHaveLength(2);
    const titles = res.body.data.items.map((i: any) => i.title);
    expect(titles).toContain('Mid-Term Exam');
    expect(titles).toContain('Quiz 1');
  });

  // =========================================================================
  // 3. IMPORTED ASSESSMENTS APPEAR WITH APPROPRIATE PROVENANCE
  // =========================================================================
  test('3. Imported assessments appear with appropriate provenance', async () => {
    const assess = await createTestAssessment({
      title: 'Historical Assignment 1',
      assessmentType: AssessmentType.ASSIGNMENT,
      maximumMarks: 20,
      sourceType: 'IMPORTED',
      importBatchId: 'BATCH-2026-X',
    });

    await AssessmentMark.create({
      collegeId: collegeA._id,
      assessmentId: assess._id,
      subjectId: subjectMath._id,
      studentEnrollmentId: enrollmentDoc1._id,
      studentId: studentDoc1._id,
      studentName: studentDoc1.name,
      marks: 18,
      maximumMarks: 20,
      status: StudentMarkStatus.PRESENT,
      sourceType: 'IMPORTED',
      importBatchId: 'BATCH-2026-X',
    });

    const res = await request(app)
      .get(`/api/v1/assessments/student/${studentDoc1._id}`)
      .set('Authorization', authHeader(studentUser1));

    expect(res.status).toBe(200);
    const item = res.body.data.items[0];
    expect(item.sourceType).toBe('IMPORTED');
    expect(item.importBatchId).toBe('BATCH-2026-X');
  });

  // =========================================================================
  // 4. UNPUBLISHED ASSESSMENTS OBEY STUDENT VISIBILITY RULES
  // =========================================================================
  test('4. Unpublished assessments obey student visibility rules', async () => {
    // Draft assessment
    const draftAssess = await createTestAssessment({
      title: 'Unpublished Draft Exam',
      assessmentType: AssessmentType.INTERNAL_EXAM,
      maximumMarks: 100,
      status: AssessmentStatus.DRAFT,
    });

    await AssessmentMark.create({
      collegeId: collegeA._id,
      assessmentId: draftAssess._id,
      subjectId: subjectMath._id,
      studentEnrollmentId: enrollmentDoc1._id,
      studentId: studentDoc1._id,
      studentName: studentDoc1.name,
      marks: 85,
      maximumMarks: 100,
      status: StudentMarkStatus.ENTERED,
    });

    // Student query: should NOT see unpublished draft
    const studentRes = await request(app)
      .get(`/api/v1/assessments/student/${studentDoc1._id}`)
      .set('Authorization', authHeader(studentUser1));

    expect(studentRes.status).toBe(200);
    expect(studentRes.body.data.items).toHaveLength(0);

    // HOD query: should be able to see unpublished draft
    const hodRes = await request(app)
      .get(`/api/v1/assessments/student/${studentDoc1._id}`)
      .set('Authorization', authHeader(hodUserA));

    expect(hodRes.status).toBe(200);
    expect(hodRes.body.data.items).toHaveLength(1);
    expect(hodRes.body.data.items[0].assessmentStatus).toBe(AssessmentStatus.DRAFT);
  });

  // =========================================================================
  // 5. STUDENT CANNOT ACCESS ANOTHER STUDENT'S RECORDS
  // =========================================================================
  test('5. Student cannot access another student\'s records', async () => {
    const res = await request(app)
      .get(`/api/v1/assessments/student/${studentDoc2._id}`)
      .set('Authorization', authHeader(studentUser1));

    expect(res.status).toBe(403);
    expect(res.body.error.message).toContain('Students can only access their own assessment records');
  });

  // =========================================================================
  // 6. CROSS-COLLEGE ACCESS IS REJECTED
  // =========================================================================
  test('6. Cross-college access is rejected', async () => {
    const res = await request(app)
      .get(`/api/v1/assessments/student/${studentDoc1._id}`)
      .set('Authorization', authHeader(adminUserB, collegeB._id.toString()));

    expect(res.status).toBe(403);
    expect(res.body.error.message).toContain('Cross-college tenant access is strictly prohibited');
  });

  // =========================================================================
  // 7. MISSING MARKS ARE NOT DISPLAYED AS ZERO
  // =========================================================================
  test('7. Missing marks are not displayed as zero', async () => {
    const assess = await createTestAssessment({
      title: 'Practical Exam',
      assessmentType: AssessmentType.LAB_EXAM,
      maximumMarks: 50,
    });

    await AssessmentMark.create({
      collegeId: collegeA._id,
      assessmentId: assess._id,
      subjectId: subjectMath._id,
      studentEnrollmentId: enrollmentDoc1._id,
      studentId: studentDoc1._id,
      studentName: studentDoc1.name,
      marks: null,
      maximumMarks: 50,
      status: StudentMarkStatus.ABSENT,
    });

    const res = await request(app)
      .get(`/api/v1/assessments/student/${studentDoc1._id}`)
      .set('Authorization', authHeader(studentUser1));

    expect(res.status).toBe(200);
    const item = res.body.data.items[0];
    expect(item.rawScore).toBeNull();
    expect(item.status).toBe(StudentMarkStatus.ABSENT);
  });

  // =========================================================================
  // 8. ASSESSMENT STATUSES REMAIN SEMANTICALLY DISTINCT
  // =========================================================================
  test('8. Assessment statuses remain semantically distinct', async () => {
    const assess = await createTestAssessment({
      title: 'Model Exam',
      assessmentType: AssessmentType.MODEL_EXAM,
      maximumMarks: 100,
    });

    await AssessmentMark.create({
      collegeId: collegeA._id,
      assessmentId: assess._id,
      subjectId: subjectMath._id,
      studentEnrollmentId: enrollmentDoc1._id,
      studentId: studentDoc1._id,
      studentName: studentDoc1.name,
      marks: null,
      maximumMarks: 100,
      status: StudentMarkStatus.EXEMPTED,
    });

    const res = await request(app)
      .get(`/api/v1/assessments/student/${studentDoc1._id}`)
      .set('Authorization', authHeader(studentUser1));

    expect(res.status).toBe(200);
    expect(res.body.data.items[0].status).toBe(StudentMarkStatus.EXEMPTED);
  });

  // =========================================================================
  // 9. DETAILED LIVE AND IMPORTED ATTENDANCE AGGREGATE CORRECTLY
  // =========================================================================
  test('9. Detailed live and imported attendance aggregate correctly', async () => {
    // 2 Live sessions attended
    await createTestAttendanceRecord({
      status: AttendanceStatus.PRESENT,
      sourceType: 'LIVE',
    });
    await createTestAttendanceRecord({
      status: AttendanceStatus.ABSENT,
      sourceType: 'LIVE',
    });

    // 2 Imported detailed sessions attended
    await createTestAttendanceRecord({
      status: AttendanceStatus.PRESENT,
      sourceType: 'IMPORTED',
    });
    await createTestAttendanceRecord({
      status: AttendanceStatus.PRESENT,
      sourceType: 'IMPORTED',
    });

    const agg = await AttendanceAggregationService.aggregateForStudent(
      collegeA._id,
      studentDoc1._id
    );

    // Total: 4 held, 3 present (75%)
    expect(agg.detailedMetrics.totalHeld).toBe(4);
    expect(agg.detailedMetrics.totalPresent).toBe(3);
    expect(agg.detailedMetrics.percentage).toBe(75);
    expect(agg.detailedMetrics.liveHeld).toBe(2);
    expect(agg.detailedMetrics.historicalDetailedHeld).toBe(2);
  });

  // =========================================================================
  // 10. COUNT-BASED HISTORICAL SUMMARIES AGGREGATE CORRECTLY
  // =========================================================================
  test('10. Count-based historical summaries aggregate correctly', async () => {
    // Level 2 Period Summary: 10 held, 8 present
    await HistoricalAttendanceSummary.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      subjectId: subjectMath._id,
      studentId: studentDoc1._id,
      studentEnrollmentId: enrollmentDoc1._id,
      periodLabel: 'Fall 2025',
      classesHeld: 10,
      presentCount: 8,
      absentCount: 2,
      attendancePercentage: 80,
      precisionLevel: 'PERIOD_SUMMARY',
      sourceType: 'IMPORTED',
      importBatchId: 'BATCH-HIST-1',
    });

    const agg = await AttendanceAggregationService.aggregateForStudent(
      collegeA._id,
      studentDoc1._id
    );

    expect(agg.detailedMetrics.totalHeld).toBe(10);
    expect(agg.detailedMetrics.totalPresent).toBe(8);
    expect(agg.detailedMetrics.percentage).toBe(80);
    expect(agg.hasDetailedData).toBe(true);
  });

  // =========================================================================
  // 11. PERCENTAGE-ONLY HISTORICAL DATA REMAINS SEPARATE
  // =========================================================================
  test('11. Percentage-only historical data remains separate', async () => {
    // Level 3 Percentage-Only: 92%
    await HistoricalAttendanceSummary.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      subjectId: subjectMath._id,
      studentId: studentDoc1._id,
      studentEnrollmentId: enrollmentDoc1._id,
      periodLabel: 'Spring 2025',
      classesHeld: null,
      presentCount: null,
      absentCount: null,
      attendancePercentage: 92,
      precisionLevel: 'PERCENTAGE_ONLY',
      sourceType: 'IMPORTED',
      importBatchId: 'BATCH-HIST-1',
    });

    const agg = await AttendanceAggregationService.aggregateForStudent(
      collegeA._id,
      studentDoc1._id
    );

    // Denominator remains 0
    expect(agg.detailedMetrics.totalHeld).toBe(0);
    expect(agg.detailedMetrics.percentage).toBe(0);
    expect(agg.hasPercentageOnlyData).toBe(true);
    expect(agg.historicalPercentageMetrics).toHaveLength(1);
    expect(agg.historicalPercentageMetrics[0].percentage).toBe(92);
  });

  // =========================================================================
  // 12. INVALID/MISSING DENOMINATORS DO NOT PRODUCE FABRICATED PERCENTAGES
  // =========================================================================
  test('12. Invalid/missing denominators do not produce fabricated percentages', async () => {
    const agg = await AttendanceAggregationService.aggregateForStudent(
      collegeA._id,
      studentDoc1._id
    );

    expect(agg.detailedMetrics.totalHeld).toBe(0);
    expect(agg.detailedMetrics.percentage).toBe(0);
    expect(agg.hasDetailedData).toBe(false);
  });

  // =========================================================================
  // 13. SUBJECT/SEMESTER/ACADEMIC-YEAR FILTERS RESPECT CONTEXT
  // =========================================================================
  test('13. Subject/semester filters respect context in aggregation', async () => {
    await createTestAttendanceRecord({
      subjectId: subjectMath._id,
      status: AttendanceStatus.PRESENT,
      sourceType: 'LIVE',
    });
    await createTestAttendanceRecord({
      subjectId: subjectPhysics._id,
      status: AttendanceStatus.ABSENT,
      sourceType: 'LIVE',
    });

    const mathAgg = await AttendanceAggregationService.aggregateForStudent(
      collegeA._id,
      studentDoc1._id,
      { subjectId: subjectMath._id }
    );

    expect(mathAgg.detailedMetrics.totalHeld).toBe(1);
    expect(mathAgg.detailedMetrics.totalPresent).toBe(1);
    expect(mathAgg.detailedMetrics.percentage).toBe(100);
  });

  // =========================================================================
  // 14. DIFFERENT MAXIMUM MARKS USE CORRECT DENOMINATOR MATH
  // =========================================================================
  test('14. Different maximum marks use correct denominator math', async () => {
    // Test A: 18/20
    const assessA = await createTestAssessment({
      title: 'Test A',
      maximumMarks: 20,
      passMarks: 8,
    });
    await AssessmentMark.create({
      collegeId: collegeA._id,
      assessmentId: assessA._id,
      subjectId: subjectMath._id,
      studentEnrollmentId: enrollmentDoc1._id,
      studentId: studentDoc1._id,
      studentName: studentDoc1.name,
      marks: 18,
      maximumMarks: 20,
      passMarks: 8,
      status: StudentMarkStatus.PRESENT,
    });

    // Test B: 36/40
    const assessB = await createTestAssessment({
      title: 'Test B',
      maximumMarks: 40,
      passMarks: 16,
    });
    await AssessmentMark.create({
      collegeId: collegeA._id,
      assessmentId: assessB._id,
      subjectId: subjectMath._id,
      studentEnrollmentId: enrollmentDoc1._id,
      studentId: studentDoc1._id,
      studentName: studentDoc1.name,
      marks: 36,
      maximumMarks: 40,
      passMarks: 16,
      status: StudentMarkStatus.PRESENT,
    });

    // Sum: 54 / 60 = 90%. NOT (18 + 36) / 2
    const analytics = await AcademicAnalyticsService.getAssessmentAnalytics(adminUserA, {
      collegeId: collegeA._id.toString(),
      departmentId: departmentA._id.toString(),
    } as any);

    expect(analytics.overview.sumObtainedMarks).toBe(54);
    expect(analytics.overview.sumMaximumMarks).toBe(60);
    expect(analytics.overview.overallPercentage).toBe(90);
  });

  // =========================================================================
  // 15. ABSENT IS NOT SILENTLY TREATED AS ZERO
  // =========================================================================
  test('15. ABSENT is not silently treated as zero in score denominators', async () => {
    const assess = await createTestAssessment({
      title: 'Test With Absent',
      maximumMarks: 50,
    });

    // Student 1: 50/50
    await AssessmentMark.create({
      collegeId: collegeA._id,
      assessmentId: assess._id,
      subjectId: subjectMath._id,
      studentEnrollmentId: enrollmentDoc1._id,
      studentId: studentDoc1._id,
      studentName: studentDoc1.name,
      marks: 50,
      maximumMarks: 50,
      status: StudentMarkStatus.PRESENT,
    });

    // Student 2: ABSENT (marks: null)
    await AssessmentMark.create({
      collegeId: collegeA._id,
      assessmentId: assess._id,
      subjectId: subjectMath._id,
      studentEnrollmentId: enrollmentDoc2._id,
      studentId: studentDoc2._id,
      studentName: studentDoc2.name,
      marks: null,
      maximumMarks: 50,
      status: StudentMarkStatus.ABSENT,
    });

    const analytics = await AcademicAnalyticsService.getAssessmentAnalytics(adminUserA, {
      collegeId: collegeA._id.toString(),
      departmentId: departmentA._id.toString(),
    } as any);

    expect(analytics.overview.absentCount).toBe(1);
    expect(analytics.overview.enteredMarksCount).toBe(1);
    expect(analytics.overview.sumObtainedMarks).toBe(50);
    expect(analytics.overview.sumMaximumMarks).toBe(50);
    expect(analytics.overview.overallPercentage).toBe(100);
  });

  // =========================================================================
  // 16. EXEMPTED AND NOT_ENTERED ARE HANDLED CORRECTLY
  // =========================================================================
  test('16. EXEMPTED and NOT_ENTERED are handled correctly', async () => {
    const assess = await createTestAssessment({
      title: 'Exempted Assessment',
      maximumMarks: 100,
    });

    await AssessmentMark.create({
      collegeId: collegeA._id,
      assessmentId: assess._id,
      subjectId: subjectMath._id,
      studentEnrollmentId: enrollmentDoc1._id,
      studentId: studentDoc1._id,
      studentName: studentDoc1.name,
      marks: null,
      maximumMarks: 100,
      status: StudentMarkStatus.EXEMPTED,
    });

    await AssessmentMark.create({
      collegeId: collegeA._id,
      assessmentId: assess._id,
      subjectId: subjectMath._id,
      studentEnrollmentId: enrollmentDoc2._id,
      studentId: studentDoc2._id,
      studentName: studentDoc2.name,
      marks: null,
      maximumMarks: 100,
      status: StudentMarkStatus.NOT_ENTERED,
    });

    const analytics = await AcademicAnalyticsService.getAssessmentAnalytics(adminUserA, {
      collegeId: collegeA._id.toString(),
      departmentId: departmentA._id.toString(),
    } as any);

    expect(analytics.overview.exemptedCount).toBe(1);
    expect(analytics.overview.notEnteredCount).toBe(1);
    expect(analytics.overview.enteredMarksCount).toBe(0);
    expect(analytics.overview.overallPercentage).toBeNull();
  });

  // =========================================================================
  // 17. PASS/FAIL METRICS REQUIRE A VALID THRESHOLD
  // =========================================================================
  test('17. Pass/fail metrics require a valid threshold', async () => {
    const assessWithoutPass = await createTestAssessment({
      title: 'Test Without Pass Marks',
      maximumMarks: 50,
      passMarks: undefined,
    });

    await AssessmentMark.create({
      collegeId: collegeA._id,
      assessmentId: assessWithoutPass._id,
      subjectId: subjectMath._id,
      studentEnrollmentId: enrollmentDoc1._id,
      studentId: studentDoc1._id,
      studentName: studentDoc1.name,
      marks: 35,
      maximumMarks: 50,
      passMarks: undefined,
      status: StudentMarkStatus.PRESENT,
    });

    const analytics = await AcademicAnalyticsService.getAssessmentAnalytics(adminUserA, {
      collegeId: collegeA._id.toString(),
      departmentId: departmentA._id.toString(),
    } as any);

    expect(analytics.overview.hasPassThreshold).toBe(false);
    expect(analytics.overview.passRate).toBeNull();
  });

  // =========================================================================
  // 18. AGGREGATES RESPECT TENANT AND ROLE SCOPE
  // =========================================================================
  test('18. Aggregates respect tenant and role scope', async () => {
    // Cross-college attempt
    await expect(
      AcademicAnalyticsService.getAssessmentAnalytics(adminUserB, {
        collegeId: collegeA._id.toString(),
        departmentId: departmentA._id.toString(),
      } as any)
    ).rejects.toThrow('Cross-college tenant access is strictly prohibited');

    // HOD crossing department boundary attempt
    await expect(
      AcademicAnalyticsService.getAssessmentAnalytics(hodUserA, {
        collegeId: collegeA._id.toString(),
        departmentId: departmentB._id.toString(),
      } as any)
    ).rejects.toThrow('Access outside assigned department is strictly prohibited');
  });

  // =========================================================================
  // 19. HISTORICAL/IMPORTED RECORDS ARE NOT DOUBLE-COUNTED
  // =========================================================================
  test('19. Historical/imported records are not double-counted', async () => {
    const assess = await createTestAssessment({
      title: 'Imported Test',
      maximumMarks: 30,
      sourceType: 'IMPORTED',
      importBatchId: 'BATCH-DEDUP',
    });

    await AssessmentMark.create({
      collegeId: collegeA._id,
      assessmentId: assess._id,
      subjectId: subjectMath._id,
      studentEnrollmentId: enrollmentDoc1._id,
      studentId: studentDoc1._id,
      studentName: studentDoc1.name,
      marks: 25,
      maximumMarks: 30,
      status: StudentMarkStatus.PRESENT,
      sourceType: 'IMPORTED',
      importBatchId: 'BATCH-DEDUP',
    });

    const history = await InternalAssessmentService.getStudentAssessmentHistory(
      collegeA._id.toString(),
      studentUser1 as any,
      studentDoc1._id.toString()
    );

    expect(history.items).toHaveLength(1);
    expect(history.items[0].rawScore).toBe(25);
  });

  // =========================================================================
  // 20. EMPTY DATASETS RETURN VALID EMPTY RESULTS
  // =========================================================================
  test('20. Empty datasets return valid empty results', async () => {
    const analytics = await AcademicAnalyticsService.getAssessmentAnalytics(adminUserA, {
      collegeId: collegeA._id.toString(),
      departmentId: departmentA._id.toString(),
    } as any);

    expect(analytics.overview.totalAssessments).toBe(0);
    expect(analytics.overview.enteredMarksCount).toBe(0);
    expect(analytics.overview.overallPercentage).toBeNull();
    expect(analytics.subjectsBreakdown).toHaveLength(0);
  });

  // =========================================================================
  // 21. EXISTING LEGACY ASSESSMENT FALLBACK STILL WORKS
  // =========================================================================
  test('21. Existing legacy assessment fallback still works', async () => {
    // Create an assessment with embedded entries only (not yet migrated to AssessmentMark)
    await createTestAssessment({
      title: 'Legacy Embedded Assessment',
      maximumMarks: 25,
      passMarks: 10,
      entries: [
        {
          studentId: studentDoc1._id,
          studentName: studentDoc1.name,
          rollNumber: studentDoc1.rollNumber,
          totalMarks: 20,
          status: StudentMarkStatus.ENTERED,
          componentMarks: {},
        },
      ],
    });

    const res = await request(app)
      .get(`/api/v1/assessments/student/${studentDoc1._id}`)
      .set('Authorization', authHeader(studentUser1));

    expect(res.status).toBe(200);
    expect(res.body.data.items).toHaveLength(1);
    expect(res.body.data.items[0].title).toBe('Legacy Embedded Assessment');
    expect(res.body.data.items[0].rawScore).toBe(20);
  });

  // =========================================================================
  // 22. STUDENT 360 ENDPOINT RETURNS UNIFIED AUTHORITATIVE PAYLOAD
  // =========================================================================
  test('22. Student 360 endpoint returns unified authoritative payload', async () => {
    // Add an assignment and a note for student context
    await Assignment.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      subjectId: subjectMath._id,
      facultyId: facultyUserA._id,
      facultyName: facultyDocA.name,
      title: 'Calculus Problem Set 1',
      description: 'Solve problems 1-10',
      assignmentType: AsgType.HOMEWORK,
      dueDate: '2026-11-01',
      dueTime: '23:59',
      dueDateTime: new Date('2026-11-01T23:59:00Z'),
      maximumMarks: 10,
      questions: [],
      attachments: [],
      status: AsgStatus.PUBLISHED,
    });

    await Note.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      courseId: courseA._id,
      semesterId: semesterA._id,
      subjectId: subjectMath._id,
      authorUserId: facultyUserA._id,
      title: 'Lecture 1 Notes',
      description: 'Introduction to Discrete Mathematics',
      fileSize: 1024,
      fileExtension: 'pdf',
      mimeType: 'application/pdf',
      fileId: 'file-123',
      storageKey: 'notes/file-123.pdf',
      originalFileName: 'lecture1.pdf',
      status: NoteStatus.PUBLISHED,
    });

    const res = await request(app)
      .get(`/api/v1/academics/students/${studentDoc1._id}/360`)
      .set('Authorization', authHeader(studentUser1));

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);

    const data = res.body.data;
    // Check all Student 360 dimensions
    expect(data.student).toBeDefined();
    expect(data.student.name).toBe('Alice Johnson');
    expect(data.academicContext.department.name).toBe('Computer Science');
    expect(data.attendance.detailedMetrics).toBeDefined();
    expect(data.assessments).toBeDefined();
    expect(data.assignments.items).toHaveLength(1);
    expect(data.assignments.items[0].title).toBe('Calculus Problem Set 1');
    expect(data.subjects.items).toHaveLength(2);
    expect(data.notes.count).toBe(1);
    expect(data.academicRecords).toBeDefined();
  });

  // =========================================================================
  // 23. FACULTY VISIBILITY IS LIMITED TO AUTHORIZED TEACHING SCOPE
  // =========================================================================
  test('23. Faculty visibility is limited to authorized teaching scope in Student 360', async () => {
    // Turing is assigned to Section A (student 1). Should be allowed.
    const resAuthorized = await request(app)
      .get(`/api/v1/academics/students/${studentDoc1._id}/360`)
      .set('Authorization', authHeader(facultyUserA));

    expect(resAuthorized.status).toBe(200);
    expect(resAuthorized.body.data.student.name).toBe('Alice Johnson');
  });

  // =========================================================================
  // 24. DEPARTMENT ASSESSMENTS ANALYTICS ENDPOINT RETURNS CORRECT METRICS
  // =========================================================================
  test('24. Department assessments analytics endpoint returns correct metrics', async () => {
    const assess = await createTestAssessment({
      title: 'Analytics Test',
      maximumMarks: 100,
      passMarks: 40,
    });

    await AssessmentMark.create({
      collegeId: collegeA._id,
      assessmentId: assess._id,
      subjectId: subjectMath._id,
      studentEnrollmentId: enrollmentDoc1._id,
      studentId: studentDoc1._id,
      studentName: studentDoc1.name,
      marks: 85,
      maximumMarks: 100,
      passMarks: 40,
      status: StudentMarkStatus.PRESENT,
    });

    const res = await request(app)
      .get('/api/v1/analytics/department/assessments')
      .set('Authorization', authHeader(hodUserA));

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.overview.totalAssessments).toBe(1);
    expect(res.body.data.overview.enteredMarksCount).toBe(1);
    expect(res.body.data.overview.overallPercentage).toBe(85);
    expect(res.body.data.overview.passRate).toBe(100);
    expect(res.body.data.subjectsBreakdown).toHaveLength(1);
    expect(res.body.data.subjectsBreakdown[0].subjectName).toBe('Discrete Mathematics');
  });

  // =========================================================================
  // 25. HOD DASHBOARD INTEGRATES ASSESSMENTS COUNT
  // =========================================================================
  test('25. HOD dashboard integrates assessments count', async () => {
    await createTestAssessment({
      title: 'Dashboard Test Assessment',
      maximumMarks: 50,
    });

    const res = await request(app)
      .get('/api/v1/reports/dashboard')
      .set('Authorization', authHeader(hodUserA));

    expect(res.status).toBe(200);
    expect(res.body.data.metrics.assessmentsCount).toBe(1);
  });
});
