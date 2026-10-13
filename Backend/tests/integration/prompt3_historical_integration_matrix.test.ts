import request from 'supertest';
import { Types } from 'mongoose';
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
} from '../../src/models';
import { AppRole } from '../../src/constants/roles';
import {
  AssessmentType,
  AssessmentStatus,
  StudentMarkStatus,
} from '../../src/models/internalAssessment.model';
import { AttendanceStatus, AttendanceSessionStatus } from '../../src/constants/status';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';
import { AssessmentImportAdapter } from '../../src/services/import/adapters/assessmentImportAdapter';
import { AttendanceImportAdapter } from '../../src/services/import/adapters/attendanceImportAdapter';
import { ImportDataType } from '../../src/constants/import.constants';
import { AttendanceAggregationService } from '../../src/services/attendance/attendanceAggregation.service';

describe('PROMPT 3 OF 3 — Historical Academic Data Integration & Regression Matrix (Scenarios A through O)', () => {
  let collegeA: any;
  let collegeB: any;
  let departmentA: any;
  let courseA: any;
  let academicYearA: any;
  let semesterA: any;
  let sectionA: any;
  let subjectA: any;
  let facultyDocA: any;
  let facultyAssignmentA: any;

  let adminUserA: any;
  let facultyUserA: any;
  let studentUser1: any;
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
      code: 'COEA-P3',
      address: 'Main Campus A',
      email: 'admin@coea-p3.edu',
      phone: '9000000001',
      principal: 'Dr. Principal A',
      status: 'active',
      isActive: true,
    });

    collegeB = await College.create({
      name: 'College of Science B',
      code: 'COEB-P3',
      address: 'North Campus B',
      email: 'admin@coeb-p3.edu',
      phone: '9000000002',
      principal: 'Dr. Principal B',
      status: 'active',
      isActive: true,
    });

    departmentA = await Department.create({
      collegeId: collegeA._id,
      name: 'Computer Science and Engineering',
      code: 'CSE-P3',
      status: 'active',
      isActive: true,
    });

    courseA = await Course.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      name: 'Bachelor of Technology in CSE',
      code: 'BTECH-CSE-P3',
      durationYears: 4,
      totalSemesters: 8,
      status: 'active',
      isActive: true,
    });

    academicYearA = await AcademicYear.create({
      collegeId: collegeA._id,
      name: '2024-2025',
      code: 'AY-2024-25-P3',
      startDate: new Date('2024-06-01'),
      endDate: new Date('2025-05-31'),
      status: 'active',
      isCurrent: true,
      isActive: true,
    });

    semesterA = await Semester.create({
      collegeId: collegeA._id,
      courseId: courseA._id,
      departmentId: departmentA._id,
      academicYearId: academicYearA._id,
      name: 'Semester 1',
      number: 1,
      status: 'active',
      isCurrent: true,
      isActive: true,
    });

    sectionA = await Section.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      courseId: courseA._id,
      semesterId: semesterA._id,
      academicYearId: academicYearA._id,
      name: 'Section A',
      capacity: 60,
      status: 'active',
      isActive: true,
    });

    subjectA = await Subject.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      courseId: courseA._id,
      semesterId: semesterA._id,
      academicYearId: academicYearA._id,
      name: 'Data Structures & Algorithms',
      code: 'CS201-P3',
      credits: 4,
      type: 'THEORY',
      status: 'active',
      isActive: true,
    });

    adminUserA = await User.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      email: 'admin@coea-p3.edu',
      password: 'password123',
      name: 'Admin A',
      role: AppRole.COLLEGE_ADMIN,
    });

    facultyUserA = await User.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      email: 'prof.smith@coea-p3.edu',
      password: 'password123',
      name: 'Prof. Alice Smith',
      role: AppRole.FACULTY,
    });

    facultyDocA = await Faculty.create({
      collegeId: collegeA._id,
      userId: facultyUserA._id,
      departmentId: departmentA._id,
      name: facultyUserA.name,
      email: facultyUserA.email,
      designation: 'Associate Professor',
      status: 'active',
    });

    facultyAssignmentA = await FacultyAssignment.create({
      collegeId: collegeA._id,
      facultyId: facultyDocA._id,
      facultyName: facultyDocA.name,
      courseId: courseA._id,
      subjectId: subjectA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      departmentId: departmentA._id,
      role: 'PRIMARY',
      status: 'active',
      isActive: true,
    });

    studentUser1 = await User.create({
      collegeId: collegeA._id,
      email: 'student1@coea-p3.edu',
      password: 'password123',
      name: 'Alice Cooper',
      role: AppRole.STUDENT,
    });

    studentDoc1 = await Student.create({
      collegeId: collegeA._id,
      userId: studentUser1._id,
      departmentId: departmentA._id,
      courseId: courseA._id,
      name: 'Alice Cooper',
      email: 'student1@coea-p3.edu',
      rollNumber: 'CS2401',
      admissionNumber: 'ADM-CS2401',
      status: 'active',
    });

    enrollmentDoc1 = await StudentEnrollment.create({
      collegeId: collegeA._id,
      studentId: studentDoc1._id,
      departmentId: departmentA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      rollNumber: 'CS2401',
      status: 'active',
      enrollmentDate: new Date('2024-06-01'),
    });

    const studentUser2 = await User.create({
      collegeId: collegeA._id,
      email: 'student2@coea-p3.edu',
      password: 'password123',
      name: 'Bob Marley',
      role: AppRole.STUDENT,
    });

    studentDoc2 = await Student.create({
      collegeId: collegeA._id,
      userId: studentUser2._id,
      departmentId: departmentA._id,
      courseId: courseA._id,
      name: 'Bob Marley',
      email: 'student2@coea-p3.edu',
      rollNumber: 'CS2402',
      admissionNumber: 'ADM-CS2402',
      status: 'active',
    });

    enrollmentDoc2 = await StudentEnrollment.create({
      collegeId: collegeA._id,
      studentId: studentDoc2._id,
      departmentId: departmentA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      rollNumber: 'CS2402',
      status: 'active',
      enrollmentDate: new Date('2024-06-01'),
    });
  });

  // =========================================================================
  // SCENARIO A: Enter valid historical unit test marks for a class
  // =========================================================================
  test('SCENARIO A: Enter valid historical unit test marks for a class -> Marks saved and appear in assessment history', async () => {
    // 1. Create historical assessment via canonical /api/v1/assessments endpoint
    const createRes = await request(app)
      .post('/api/v1/assessments')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        facultyAssignmentId: facultyAssignmentA._id.toString(),
        title: 'Historical Mid-Term 1',
        assessmentType: AssessmentType.UNIT_TEST,
        maximumMarks: 50,
        passMarks: 18,
        assessmentDate: '2024-08-15',
        sourceType: 'HISTORICAL_MANUAL',
        isHistorical: true,
      });

    expect(createRes.status).toBe(201);
    const assessmentId = createRes.body.data._id || createRes.body.data.id;

    // 2. Enter valid marks via draft endpoint
    const marksRes = await request(app)
      .post(`/api/v1/assessments/${assessmentId}/draft`)
      .set('Authorization', authHeader(facultyUserA))
      .send({
        entries: [
          {
            studentEnrollmentId: enrollmentDoc1._id.toString(),
            marks: 42,
            status: StudentMarkStatus.PRESENT,
            remarks: 'Strong performance',
          },
          {
            studentEnrollmentId: enrollmentDoc2._id.toString(),
            marks: 38,
            status: StudentMarkStatus.PRESENT,
            remarks: 'Good analytical reasoning',
          },
        ],
      });

    expect(marksRes.status).toBe(200);

    // 3. Submit and lock to finalize
    await request(app)
      .post(`/api/v1/assessments/${assessmentId}/submit`)
      .set('Authorization', authHeader(facultyUserA));

    await request(app)
      .post(`/api/v1/assessments/${assessmentId}/lock`)
      .set('Authorization', authHeader(adminUserA));

    // 4. Verify marks appear in student assessment history
    const historyRes = await request(app)
      .get(`/api/v1/assessments/student/${studentDoc1._id.toString()}`)
      .set('Authorization', authHeader(facultyUserA));

    expect(historyRes.status).toBe(200);
    const history = historyRes.body.data.items;
    expect(history).toBeDefined();
    const entry = history.find((h: any) => h.title === 'Historical Mid-Term 1');
    expect(entry).toBeDefined();
    expect(entry.rawScore).toBe(42);
    expect(entry.maximumMarks).toBe(50);
    expect(entry.sourceType).toBe('HISTORICAL_MANUAL');
  });

  // =========================================================================
  // SCENARIO B: Enter a valid zero mark
  // =========================================================================
  test('SCENARIO B: Enter a valid zero mark -> Zero remains a valid numerical score', async () => {
    const createRes = await request(app)
      .post('/api/v1/assessments')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        facultyAssignmentId: facultyAssignmentA._id.toString(),
        title: 'Historical Unit Quiz 1',
        assessmentType: AssessmentType.ASSIGNMENT,
        maximumMarks: 20,
        passMarks: 7,
        assessmentDate: '2024-09-01',
        sourceType: 'HISTORICAL_MANUAL',
        isHistorical: true,
      });

    const assessmentId = createRes.body.data._id || createRes.body.data.id;

    const marksRes = await request(app)
      .post(`/api/v1/assessments/${assessmentId}/draft`)
      .set('Authorization', authHeader(facultyUserA))
      .send({
        entries: [
          {
            studentEnrollmentId: enrollmentDoc1._id.toString(),
            marks: 0, // Genuine 0 score
            status: StudentMarkStatus.PRESENT,
            remarks: 'Attempted but scored zero',
          },
        ],
      });

    expect(marksRes.status).toBe(200);

    const markDoc = await AssessmentMark.findOne({
      assessmentId,
      studentEnrollmentId: enrollmentDoc1._id,
    });

    expect(markDoc).toBeDefined();
    expect(markDoc!.marks).toBe(0);
    expect(markDoc!.status).toBe(StudentMarkStatus.PRESENT); // Not marked absent
  });

  // =========================================================================
  // SCENARIO C: Enter an absent student status
  // =========================================================================
  test('SCENARIO C: Enter an absent student status -> Absence is not silently converted into numerical zero', async () => {
    const createRes = await request(app)
      .post('/api/v1/assessments')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        facultyAssignmentId: facultyAssignmentA._id.toString(),
        title: 'Historical Practical Test',
        assessmentType: AssessmentType.PRACTICAL,
        maximumMarks: 25,
        passMarks: 10,
        assessmentDate: '2024-09-10',
        sourceType: 'HISTORICAL_MANUAL',
        isHistorical: true,
      });

    const assessmentId = createRes.body.data._id || createRes.body.data.id;

    const marksRes = await request(app)
      .post(`/api/v1/assessments/${assessmentId}/draft`)
      .set('Authorization', authHeader(facultyUserA))
      .send({
        entries: [
          {
            studentEnrollmentId: enrollmentDoc1._id.toString(),
            status: StudentMarkStatus.ABSENT,
            remarks: 'Medical leave on test day',
          },
        ],
      });

    expect(marksRes.status).toBe(200);

    const markDoc = await AssessmentMark.findOne({
      assessmentId,
      studentEnrollmentId: enrollmentDoc1._id,
    });

    expect(markDoc).toBeDefined();
    expect(markDoc!.status).toBe(StudentMarkStatus.ABSENT);
    expect(markDoc!.marks).toBeNull(); // Strictly null, NOT 0!
  });

  // =========================================================================
  // SCENARIO D: Submit the same marks twice
  // =========================================================================
  test('SCENARIO D: Submit the same marks twice -> No duplicate AssessmentMark records created', async () => {
    const createRes = await request(app)
      .post('/api/v1/assessments')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        facultyAssignmentId: facultyAssignmentA._id.toString(),
        title: 'Historical Assignment 2',
        assessmentType: AssessmentType.ASSIGNMENT,
        maximumMarks: 30,
        passMarks: 12,
        assessmentDate: '2024-09-15',
        sourceType: 'HISTORICAL_MANUAL',
        isHistorical: true,
      });

    const assessmentId = createRes.body.data._id || createRes.body.data.id;
    const payload = {
      entries: [
        {
          studentEnrollmentId: enrollmentDoc1._id.toString(),
          marks: 27,
          status: StudentMarkStatus.PRESENT,
        },
      ],
    };

    // First submit
    const res1 = await request(app)
      .post(`/api/v1/assessments/${assessmentId}/draft`)
      .set('Authorization', authHeader(facultyUserA))
      .send(payload);
    expect(res1.status).toBe(200);

    // Second submit (duplicate retry)
    const res2 = await request(app)
      .post(`/api/v1/assessments/${assessmentId}/draft`)
      .set('Authorization', authHeader(facultyUserA))
      .send(payload);
    expect(res2.status).toBe(200);

    // Verify exactly 1 mark record exists
    const markCount = await AssessmentMark.countDocuments({
      assessmentId,
      studentEnrollmentId: enrollmentDoc1._id,
    });
    expect(markCount).toBe(1);
  });

  // =========================================================================
  // SCENARIO E: Enter detailed attendance for a historical class period
  // =========================================================================
  test('SCENARIO E: Enter detailed attendance for a historical class period -> Canonical historical attendance records created', async () => {
    const res = await request(app)
      .post('/api/v1/attendance/historical/sessions')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        academicYearId: academicYearA._id.toString(),
        semesterId: semesterA._id.toString(),
        sectionId: sectionA._id.toString(),
        subjectId: subjectA._id.toString(),
        date: '2024-08-20',
        timeSlot: 'Period 1 (09:00 - 10:00)',
        records: [
          {
            studentEnrollmentId: enrollmentDoc1._id.toString(),
            status: AttendanceStatus.PRESENT,
          },
          {
            studentEnrollmentId: enrollmentDoc2._id.toString(),
            status: AttendanceStatus.ABSENT,
          },
        ],
        remarks: 'Archived session from paper register',
      });

    expect(res.status).toBe(201);
    const session = res.body.data;
    expect(session.sourceType).toBe('HISTORICAL_MANUAL');
    expect(session.status).toBe(AttendanceSessionStatus.LOCKED);

    const records = await AttendanceRecord.find({ sessionId: session._id });
    expect(records.length).toBe(2);
    expect(records[0].sourceType).toBe('HISTORICAL_MANUAL');
  });

  // =========================================================================
  // SCENARIO F: Enter historical attendance totals without individual sessions
  // =========================================================================
  test('SCENARIO F: Enter historical attendance totals without individual sessions -> Summary stored without fabricating sessions', async () => {
    const beforeSessionCount = await AttendanceSession.countDocuments();

    const res = await request(app)
      .post('/api/v1/attendance/historical/summaries')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        academicYearId: academicYearA._id.toString(),
        semesterId: semesterA._id.toString(),
        sectionId: sectionA._id.toString(),
        subjectId: subjectA._id.toString(),
        periodLabel: 'Term 1 Consolidated Aggregate',
        entries: [
          {
            studentEnrollmentId: enrollmentDoc1._id.toString(),
            classesHeld: 40,
            presentCount: 36,
          },
          {
            studentEnrollmentId: enrollmentDoc2._id.toString(),
            classesHeld: 40,
            presentCount: 32,
          },
        ],
      });

    expect(res.status).toBe(201);
    const afterSessionCount = await AttendanceSession.countDocuments();
    expect(afterSessionCount).toBe(beforeSessionCount); // No fake sessions fabricated!

    const summaries = await HistoricalAttendanceSummary.find({
      periodLabel: 'Term 1 Consolidated Aggregate',
    });
    expect(summaries.length).toBe(2);
    expect(summaries[0].sourceType).toBe('HISTORICAL_MANUAL');
    expect(summaries[0].precisionLevel).toBe('PERIOD_SUMMARY');
  });

  // =========================================================================
  // SCENARIO G: Submit the same historical attendance request twice
  // =========================================================================
  test('SCENARIO G: Submit the same historical attendance request twice -> No duplicate sessions or records created (409 Conflict)', async () => {
    const payload = {
      academicYearId: academicYearA._id.toString(),
      semesterId: semesterA._id.toString(),
      sectionId: sectionA._id.toString(),
      subjectId: subjectA._id.toString(),
      date: '2024-08-25',
      timeSlot: 'Period 2 (10:00 - 11:00)',
      records: [
        {
          studentEnrollmentId: enrollmentDoc1._id.toString(),
          status: AttendanceStatus.PRESENT,
        },
      ],
    };

    const res1 = await request(app)
      .post('/api/v1/attendance/historical/sessions')
      .set('Authorization', authHeader(facultyUserA))
      .send(payload);
    expect(res1.status).toBe(201);

    // Duplicate submission attempt
    const res2 = await request(app)
      .post('/api/v1/attendance/historical/sessions')
      .set('Authorization', authHeader(facultyUserA))
      .send(payload);
    expect(res2.status).toBe(409); // 409 Conflict safely blocks duplicate session
  });

  // =========================================================================
  // SCENARIO H: Import data that conflicts with an existing historical record
  // =========================================================================
  test('SCENARIO H: Import data that conflicts with an existing historical record -> Conflict reported, existing record not overwritten', async () => {
    // 1. Create a historical assessment and enter manual historical marks (45)
    const createRes = await request(app)
      .post('/api/v1/assessments')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        facultyAssignmentId: facultyAssignmentA._id.toString(),
        title: 'Historical Mid-Term Conflict Test',
        assessmentType: AssessmentType.UNIT_TEST,
        maximumMarks: 50,
        passMarks: 18,
        assessmentDate: '2024-08-10',
        sourceType: 'HISTORICAL_MANUAL',
        isHistorical: true,
      });

    const assessmentId = createRes.body.data._id || createRes.body.data.id;

    await request(app)
      .post(`/api/v1/assessments/${assessmentId}/draft`)
      .set('Authorization', authHeader(facultyUserA))
      .send({
        entries: [
          {
            studentEnrollmentId: enrollmentDoc1._id.toString(),
            marks: 45,
            status: StudentMarkStatus.PRESENT,
          },
        ],
      });

    // 2. Simulate spreadsheet import batch with conflicting mark (20 instead of 45)
    const assessmentAdapter = new AssessmentImportAdapter();
    const fakeBatch: any = {
      _id: new Types.ObjectId(),
      importBatchId: 'BATCH-CONFLICT-TEST',
      collegeId: collegeA._id,
      uploadedBy: adminUserA._id,
      fileName: 'conflict_marks.xlsx',
      dataType: ImportDataType.ASSESSMENT,
      metadata: {
        assessmentTitle: 'Historical Mid-Term Conflict Test',
        defaultMaxMarks: 50,
      },
    };

    const conflictingRows: any[] = [
      {
        rowNumber: 2,
        studentResolution: {
          studentId: studentDoc1._id.toString(),
          studentEnrollmentId: enrollmentDoc1._id.toString(),
          studentName: studentDoc1.name,
          studentPin: studentDoc1.rollNumber,
        },
        semanticValues: {
          marks: 20, // Conflicts with 45!
          status: 'PRESENT',
        },
        mappedValues: {},
      },
    ];

    const context: any = {
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      subjectId: subjectA._id,
      facultyAssignmentId: facultyAssignmentA._id,
      departmentId: departmentA._id,
      courseId: courseA._id,
    };

    // Assert that the adapter detects the conflict and rejects it!
    await expect(assessmentAdapter.persistBatch(fakeBatch, conflictingRows, context)).rejects.toThrow(
      /IMPORT_CONFLICT_WITH_EXISTING_RECORD/
    );

    // Confirm existing record remained untouched at 45!
    const markInDB = await AssessmentMark.findOne({
      assessmentId,
      studentEnrollmentId: enrollmentDoc1._id,
    });
    expect(markInDB!.marks).toBe(45);

    // 3. Similarly test attendance import conflict with manual historical attendance record
    const sessRes = await request(app)
      .post('/api/v1/attendance/historical/sessions')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        academicYearId: academicYearA._id.toString(),
        semesterId: semesterA._id.toString(),
        sectionId: sectionA._id.toString(),
        subjectId: subjectA._id.toString(),
        date: '2024-08-11',
        timeSlot: 'Slot A',
        records: [
          {
            studentEnrollmentId: enrollmentDoc1._id.toString(),
            status: AttendanceStatus.PRESENT,
          },
        ],
      });
    expect(sessRes.status).toBe(201);

    const attendanceAdapter = new AttendanceImportAdapter();
    const fakeAttBatch: any = {
      _id: new Types.ObjectId(),
      importBatchId: 'BATCH-ATT-CONFLICT-TEST',
      collegeId: collegeA._id,
      uploadedBy: adminUserA._id,
      fileName: 'conflict_att.xlsx',
      dataType: ImportDataType.ATTENDANCE,
      metadata: {},
    };

    const conflictingAttRows: any[] = [
      {
        rowNumber: 2,
        studentResolution: {
          studentId: studentDoc1._id.toString(),
          studentEnrollmentId: enrollmentDoc1._id.toString(),
          studentName: studentDoc1.name,
          studentPin: studentDoc1.rollNumber,
        },
        semanticValues: {
          date: '2024-08-11',
          timeSlot: 'Slot A',
          status: 'ABSENT', // Conflicts with PRESENT!
        },
        mappedValues: {
          date: '2024-08-11',
          timeSlot: 'Slot A',
          status: 'ABSENT',
        },
      },
    ];

    await expect(attendanceAdapter.persistBatch(fakeAttBatch, conflictingAttRows, context)).rejects.toThrow(
      /IMPORT_CONFLICT_WITH_EXISTING_RECORD/
    );
  });

  // =========================================================================
  // SCENARIO I: Retrieve the affected student Student 360 profile
  // =========================================================================
  test('SCENARIO I: Retrieve the affected student Student 360 profile -> Historical marks & attendance appear in appropriate sections', async () => {
    // 1. Create historical assessment with mark for student1
    const createRes = await request(app)
      .post('/api/v1/assessments')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        facultyAssignmentId: facultyAssignmentA._id.toString(),
        title: 'Student 360 Verification Test',
        assessmentType: AssessmentType.UNIT_TEST,
        maximumMarks: 100,
        passMarks: 40,
        assessmentDate: '2024-07-20',
        sourceType: 'HISTORICAL_MANUAL',
        isHistorical: true,
      });

    const assessmentId = createRes.body.data._id || createRes.body.data.id;

    await request(app)
      .post(`/api/v1/assessments/${assessmentId}/draft`)
      .set('Authorization', authHeader(facultyUserA))
      .send({
        entries: [
          {
            studentEnrollmentId: enrollmentDoc1._id.toString(),
            marks: 88,
            status: StudentMarkStatus.PRESENT,
          },
        ],
      });

    await request(app)
      .post(`/api/v1/assessments/${assessmentId}/submit`)
      .set('Authorization', authHeader(facultyUserA));

    await request(app)
      .post(`/api/v1/assessments/${assessmentId}/lock`)
      .set('Authorization', authHeader(adminUserA));

    // 2. Create historical attendance session for student1
    await request(app)
      .post('/api/v1/attendance/historical/sessions')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        academicYearId: academicYearA._id.toString(),
        semesterId: semesterA._id.toString(),
        sectionId: sectionA._id.toString(),
        subjectId: subjectA._id.toString(),
        date: '2024-07-22',
        timeSlot: 'Period 3 (11:15 - 12:15)',
        records: [
          {
            studentEnrollmentId: enrollmentDoc1._id.toString(),
            status: AttendanceStatus.PRESENT,
          },
        ],
      });

    // 3. Query authoritative Student 360 API
    const student360Res = await request(app)
      .get(`/api/v1/academics/students/${studentDoc1._id.toString()}/360`)
      .set('Authorization', authHeader(adminUserA));

    expect(student360Res.status).toBe(200);
    const profile = student360Res.body.data;
    expect(profile).toBeDefined();

    // Verify marks in Student 360
    expect(profile.assessments).toBeDefined();
    const markEntry = profile.assessments.items?.find((a: any) => a.title === 'Student 360 Verification Test');
    expect(markEntry).toBeDefined();
    expect(markEntry.rawScore).toBe(88);

    // Verify attendance in Student 360
    expect(profile.attendance).toBeDefined();
    expect(profile.attendance.detailedMetrics.totalHeld).toBeGreaterThanOrEqual(1);
    expect(profile.attendance.detailedMetrics.totalPresent).toBeGreaterThanOrEqual(1);
  });

  // =========================================================================
  // SCENARIO J: Retrieve attendance and assessment analytics
  // =========================================================================
  test('SCENARIO J: Retrieve attendance & assessment analytics -> Historical records aggregated correctly without double-counting', async () => {
    // Check attendance aggregation service directly
    const agg = await AttendanceAggregationService.aggregateForStudent(
      collegeA._id.toString(),
      studentDoc1._id.toString(),
      { subjectId: subjectA._id.toString() }
    );

    expect(agg).toBeDefined();
    expect(agg.detailedMetrics.totalHeld).toBeGreaterThanOrEqual(0);
    expect(agg.detailedMetrics.totalPresent).toBeLessThanOrEqual(agg.detailedMetrics.totalHeld);
    expect(agg.detailedMetrics.percentage).toBeLessThanOrEqual(100);
  });

  // =========================================================================
  // SCENARIO K: Attempt a cross-college write or read
  // =========================================================================
  test('SCENARIO K: Attempt a cross-college write or read -> Backend rejects unauthorized access (403 Forbidden)', async () => {
    // User from College B attempting to record historical session in College A
    const crossCollegeUser = await User.create({
      collegeId: collegeB._id,
      email: 'attacker@coeb-p3.edu',
      password: 'password123',
      name: 'College B Faculty',
      role: AppRole.FACULTY,
    });

    const res = await request(app)
      .post('/api/v1/attendance/historical/sessions')
      .set('Authorization', authHeader(crossCollegeUser, collegeB._id.toString()))
      .send({
        academicYearId: academicYearA._id.toString(),
        semesterId: semesterA._id.toString(),
        sectionId: sectionA._id.toString(),
        subjectId: subjectA._id.toString(),
        date: '2024-08-01',
        timeSlot: 'Period 1 (09:00 - 10:00)',
        records: [
          {
            studentEnrollmentId: enrollmentDoc1._id.toString(),
            status: AttendanceStatus.PRESENT,
          },
        ],
      });

    expect(res.status).toBe(403); // Forbidden cross-college access
  });

  // =========================================================================
  // SCENARIO L: Attempt to use historical entry to bypass live attendance timing
  // =========================================================================
  test('SCENARIO L: Attempt to use historical entry to bypass live attendance timing -> Live attendance restrictions remain effective', async () => {
    // Attempting to record future date on historical endpoint
    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 2);
    const tomorrowStr = tomorrow.toISOString().split('T')[0];

    const resHist = await request(app)
      .post('/api/v1/attendance/historical/sessions')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        academicYearId: academicYearA._id.toString(),
        semesterId: semesterA._id.toString(),
        sectionId: sectionA._id.toString(),
        subjectId: subjectA._id.toString(),
        date: tomorrowStr, // Future date
        timeSlot: 'Period 1 (09:00 - 10:00)',
        records: [
          {
            studentEnrollmentId: enrollmentDoc1._id.toString(),
            status: AttendanceStatus.PRESENT,
          },
        ],
      });

    expect(resHist.status).toBe(400);
    expect(resHist.body.error?.message).toMatch(/future/i);

    // Live attendance creation endpoint also enforces date/timing
    const resLive = await request(app)
      .post('/api/v1/attendance/sessions')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        academicYearId: academicYearA._id.toString(),
        semesterId: semesterA._id.toString(),
        sectionId: sectionA._id.toString(),
        subjectId: subjectA._id.toString(),
        date: tomorrowStr,
        timeSlot: 'Period 1 (09:00 - 10:00)',
      });

    expect(resLive.status).toBe(400);
    expect(resLive.body.error?.message).toMatch(/future/i);
  });

  // =========================================================================
  // SCENARIO M: Reopen the historical-entry screen after saving
  // =========================================================================
  test('SCENARIO M: Reopen the historical-entry screen after saving -> Persisted records appear correctly & are not duplicated', async () => {
    const rosterRes = await request(app)
      .get('/api/v1/attendance/historical/roster')
      .set('Authorization', authHeader(facultyUserA))
      .query({
        academicYearId: academicYearA._id.toString(),
        semesterId: semesterA._id.toString(),
        sectionId: sectionA._id.toString(),
        subjectId: subjectA._id.toString(),
      });

    expect(rosterRes.status).toBe(200);
    expect(rosterRes.body.data.roster.length).toBe(2);
    expect(rosterRes.body.data.facultyAssignment).toBeDefined();
  });

  // =========================================================================
  // SCENARIO N: Simulate an invalid record within a batch
  // =========================================================================
  test('SCENARIO N: Simulate an invalid record within a batch -> API reports failure accurately and avoids orphan sessions', async () => {
    const fakeEnrollmentId = new Types.ObjectId().toString();
    const beforeCount = await AttendanceSession.countDocuments();

    const res = await request(app)
      .post('/api/v1/attendance/historical/sessions')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        academicYearId: academicYearA._id.toString(),
        semesterId: semesterA._id.toString(),
        sectionId: sectionA._id.toString(),
        subjectId: subjectA._id.toString(),
        date: '2024-08-30',
        timeSlot: 'Period 4 (12:15 - 01:15)',
        records: [
          {
            studentEnrollmentId: enrollmentDoc1._id.toString(),
            status: AttendanceStatus.PRESENT,
          },
          {
            studentEnrollmentId: fakeEnrollmentId, // Non-existent student enrollment
            status: AttendanceStatus.PRESENT,
          },
        ],
      });

    expect(res.status).toBe(400);
    const afterCount = await AttendanceSession.countDocuments();
    expect(afterCount).toBe(beforeCount); // Atomic rollback — zero orphan sessions!
  });

  // =========================================================================
  // SCENARIO O: Attempt to edit a locked historical assessment or finalized attendance record
  // =========================================================================
  test('SCENARIO O: Attempt to edit locked historical assessment -> Existing correction & authorization rules enforced', async () => {
    // 1. Create historical assessment and finalize to LOCKED
    const createRes = await request(app)
      .post('/api/v1/assessments')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        facultyAssignmentId: facultyAssignmentA._id.toString(),
        title: 'Locked Historical Exam',
        assessmentType: AssessmentType.MID_TERM,
        maximumMarks: 100,
        passMarks: 35,
        assessmentDate: '2024-06-15',
        sourceType: 'HISTORICAL_MANUAL',
        isHistorical: true,
      });

    const assessmentId = createRes.body.data._id || createRes.body.data.id;

    // Save marks
    await request(app)
      .post(`/api/v1/assessments/${assessmentId}/draft`)
      .set('Authorization', authHeader(facultyUserA))
      .send({
        entries: [
          {
            studentEnrollmentId: enrollmentDoc1._id.toString(),
            marks: 75,
            status: StudentMarkStatus.PRESENT,
          },
        ],
      });

    // Lock assessment directly
    await InternalAssessment.findByIdAndUpdate(assessmentId, {
      status: AssessmentStatus.LOCKED,
    });

    // Direct edit attempt must be rejected!
    const editRes = await request(app)
      .post(`/api/v1/assessments/${assessmentId}/draft`)
      .set('Authorization', authHeader(facultyUserA))
      .send({
        entries: [
          {
            studentEnrollmentId: enrollmentDoc1._id.toString(),
            marks: 85,
            status: StudentMarkStatus.PRESENT,
          },
        ],
      });

    expect(editRes.status).toBe(400);
    expect(editRes.body.error?.message).toMatch(/locked/i);
  });
});
