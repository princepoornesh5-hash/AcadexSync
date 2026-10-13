import request from 'supertest';
import mongoose from 'mongoose';
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
} from '../../src/models';
import { AppRole } from '../../src/constants/roles';
import {
  AssessmentType,
  AssessmentStatus,
  StudentMarkStatus,
} from '../../src/models/internalAssessment.model';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';

describe('PROMPT 1 OF 3 — Manual Historical Unit Test Marks Entry Integration Tests', () => {
  let collegeA: any;
  let collegeB: any;
  let departmentA: any;
  let courseA: any;
  let academicYearA: any;
  let semesterA: any;
  let sectionA: any;
  let subjectMath: any;
  let facultyDocA: any;
  let facultyAssignmentA: any;

  let adminUserA: any;
  let hodUserA: any;
  let facultyUserA: any;
  let facultyUserB: any;
  let studentUser1: any;
  let studentUser2: any;
  let studentDoc1: any;
  let studentDoc2: any;
  let enrollmentDoc1: any;
  let enrollmentDoc2: any;

  let crossCollegeStudent: any;
  let crossCollegeEnrollment: any;

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
      code: 'COEA-HIST',
      address: 'Main Campus A',
      email: 'admin@coea-hist.edu',
      phone: '9000000001',
      principal: 'Dr. Principal A',
      status: 'active',
      isActive: true,
    });

    collegeB = await College.create({
      name: 'College of Science B',
      code: 'COEB-HIST',
      address: 'North Campus B',
      email: 'admin@coeb-hist.edu',
      phone: '9000000002',
      principal: 'Dr. Principal B',
      status: 'active',
      isActive: true,
    });

    departmentA = await Department.create({
      collegeId: collegeA._id,
      name: 'Computer Science & Engineering',
      code: 'CSE-HIST',
      status: 'active',
      isActive: true,
    });

    await Department.create({
      collegeId: collegeA._id,
      name: 'Mechanical Engineering',
      code: 'MECH-HIST',
      status: 'active',
      isActive: true,
    });

    courseA = await Course.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      name: 'B.Tech CSE',
      code: 'BT-CSE-HIST',
      durationYears: 4,
      status: 'active',
      isActive: true,
    });

    academicYearA = await AcademicYear.create({
      collegeId: collegeA._id,
      name: '2024-2025',
      code: 'AY24-25',
      startDate: new Date('2024-06-01'),
      endDate: new Date('2025-05-31'),
      status: 'active',
      isActive: true,
      isCurrent: false, // historical year
    });

    semesterA = await Semester.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      name: 'Semester 3',
      number: 3,
      type: 'ODD',
      startDate: new Date('2024-06-01'),
      endDate: new Date('2024-11-30'),
      status: 'active',
      isActive: true,
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

    subjectMath = await Subject.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      courseId: courseA._id,
      semesterId: semesterA._id,
      name: 'Discrete Mathematics',
      code: 'CS301-HIST',
      credits: 4,
      type: 'theory',
      isActive: true,
    });

    adminUserA = await User.create({
      collegeId: collegeA._id,
      email: 'admin@coea-hist.edu',
      password: 'password123',
      name: 'College Admin A',
      role: AppRole.COLLEGE_ADMIN,
    });

    hodUserA = await User.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      email: 'hod.cse@coea-hist.edu',
      password: 'password123',
      name: 'HOD CSE',
      role: AppRole.HOD,
    });

    facultyUserA = await User.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      email: 'prof.smith@coea-hist.edu',
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

    facultyUserB = await User.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      email: 'prof.unauthorized@coea-hist.edu',
      password: 'password123',
      name: 'Prof. Bob Jones',
      role: AppRole.FACULTY,
    });

    await Faculty.create({
      collegeId: collegeA._id,
      userId: facultyUserB._id,
      departmentId: departmentA._id,
      name: facultyUserB.name,
      email: facultyUserB.email,
      designation: 'Assistant Professor',
      status: 'active',
    });

    facultyAssignmentA = await FacultyAssignment.create({
      collegeId: collegeA._id,
      facultyId: facultyDocA._id,
      facultyName: facultyDocA.name,
      courseId: courseA._id,
      subjectId: subjectMath._id,
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
      email: 'student1@coea-hist.edu',
      password: 'password123',
      name: 'John Doe',
      role: AppRole.STUDENT,
    });

    studentDoc1 = await Student.create({
      collegeId: collegeA._id,
      userId: studentUser1._id,
      departmentId: departmentA._id,
      courseId: courseA._id,
      name: studentUser1.name,
      email: studentUser1.email,
      rollNumber: 'CS2401',
      admissionNumber: 'ADM-2401',
      instituteId: 'PIN2401',
      status: 'active',
      academicYearId: academicYearA._id,
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

    studentUser2 = await User.create({
      collegeId: collegeA._id,
      email: 'student2@coea-hist.edu',
      password: 'password123',
      name: 'Jane Roe',
      role: AppRole.STUDENT,
    });

    studentDoc2 = await Student.create({
      collegeId: collegeA._id,
      userId: studentUser2._id,
      departmentId: departmentA._id,
      courseId: courseA._id,
      name: studentUser2.name,
      email: studentUser2.email,
      rollNumber: 'CS2402',
      admissionNumber: 'ADM-2402',
      instituteId: 'PIN2402',
      status: 'active',
      academicYearId: academicYearA._id,
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

    // Cross-college student & user
    await User.create({
      collegeId: collegeB._id,
      email: 'admin@coeb-hist.edu',
      password: 'password123',
      name: 'Admin B',
      role: AppRole.COLLEGE_ADMIN,
    });

    crossCollegeStudent = await Student.create({
      collegeId: collegeB._id,
      userId: new mongoose.Types.ObjectId(),
      departmentId: new mongoose.Types.ObjectId(),
      courseId: new mongoose.Types.ObjectId(),
      name: 'Cross College Student',
      email: 'cross@colb.edu',
      rollNumber: 'B2401',
      admissionNumber: 'ADM-B2401',
      status: 'active',
    });

    crossCollegeEnrollment = await StudentEnrollment.create({
      collegeId: collegeB._id,
      studentId: crossCollegeStudent._id,
      departmentId: new mongoose.Types.ObjectId(),
      courseId: new mongoose.Types.ObjectId(),
      academicYearId: new mongoose.Types.ObjectId(),
      semesterId: new mongoose.Types.ObjectId(),
      sectionId: new mongoose.Types.ObjectId(),
      rollNumber: 'B2401',
      status: 'active',
      enrollmentDate: new Date('2024-06-01'),
    });
  });

  // =========================================================================
  // 1. Authorized manual historical assessment creation
  // =========================================================================
  test('1. Authorized manual historical assessment creation sets HISTORICAL_MANUAL provenance', async () => {
    const historicalDate = '2024-09-15';
    const res = await request(app)
      .post('/api/v1/assessments')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        facultyAssignmentId: facultyAssignmentA._id.toString(),
        title: 'Unit Test 1',
        assessmentType: AssessmentType.UNIT_TEST,
        maximumMarks: 25,
        passMarks: 10,
        assessmentDate: historicalDate,
        sourceType: 'HISTORICAL_MANUAL',
        isHistorical: true,
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.title).toBe('Unit Test 1');
    expect(res.body.data.sourceType).toBe('HISTORICAL_MANUAL');
    expect(res.body.data.maximumMarks).toBe(25);
    expect(res.body.data.status).toBe(AssessmentStatus.MARKS_ENTRY);

    // Verify database document
    const doc = await InternalAssessment.findById(res.body.data._id || res.body.data.id);
    expect(doc).not.toBeNull();
    expect(doc!.sourceType).toBe('HISTORICAL_MANUAL');
    expect(doc!.status).toBe(AssessmentStatus.MARKS_ENTRY);
    expect(doc!.auditLog).toHaveLength(1);
    expect(doc!.auditLog[0].action).toBe('HISTORICAL_MANUAL_CREATED');
  });

  // =========================================================================
  // 2. Correct StudentEnrollment roster resolution
  // =========================================================================
  test('2. Correct StudentEnrollment roster resolution derived from section & academic period', async () => {
    const createRes = await request(app)
      .post('/api/v1/assessments')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        facultyAssignmentId: facultyAssignmentA._id.toString(),
        title: 'Unit Test 1',
        assessmentType: AssessmentType.UNIT_TEST,
        maximumMarks: 25,
        assessmentDate: '2024-09-15',
        sourceType: 'HISTORICAL_MANUAL',
        isHistorical: true,
      });

    const assessmentId = createRes.body.data._id || createRes.body.data.id;

    const rosterRes = await request(app)
      .get(`/api/v1/assessments/${assessmentId}/roster`)
      .set('Authorization', authHeader(facultyUserA));

    expect(rosterRes.status).toBe(200);
    expect(rosterRes.body.success).toBe(true);
    expect(rosterRes.body.data.roster).toHaveLength(2);

    const enrollmentIds = rosterRes.body.data.roster.map((r: any) => r.studentEnrollmentId);
    expect(enrollmentIds).toContain(enrollmentDoc1._id.toString());
    expect(enrollmentIds).toContain(enrollmentDoc2._id.toString());

    // Verified marks initialized with HISTORICAL_MANUAL
    const marks = await AssessmentMark.find({ assessmentId });
    expect(marks).toHaveLength(2);
    expect(marks[0].sourceType).toBe('HISTORICAL_MANUAL');
    expect(marks[1].sourceType).toBe('HISTORICAL_MANUAL');
  });

  // =========================================================================
  // 3. Valid marks entry
  // =========================================================================
  test('3. Valid marks entry updates marks and preserves HISTORICAL_MANUAL provenance', async () => {
    const createRes = await request(app)
      .post('/api/v1/assessments')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        facultyAssignmentId: facultyAssignmentA._id.toString(),
        title: 'Unit Test 1',
        assessmentType: AssessmentType.UNIT_TEST,
        maximumMarks: 25,
        sourceType: 'HISTORICAL_MANUAL',
        isHistorical: true,
      });

    const assessmentId = createRes.body.data._id || createRes.body.data.id;

    const saveRes = await request(app)
      .post(`/api/v1/assessments/${assessmentId}/draft`)
      .set('Authorization', authHeader(facultyUserA))
      .send({
        entries: [
          {
            studentEnrollmentId: enrollmentDoc1._id.toString(),
            marks: 22.5,
            status: StudentMarkStatus.PRESENT,
          },
          {
            studentEnrollmentId: enrollmentDoc2._id.toString(),
            marks: 18,
            status: StudentMarkStatus.PRESENT,
          },
        ],
      });

    expect(saveRes.status).toBe(200);

    const mark1 = await AssessmentMark.findOne({
      assessmentId,
      studentEnrollmentId: enrollmentDoc1._id,
    });
    expect(mark1).not.toBeNull();
    expect(mark1!.marks).toBe(22.5);
    expect(mark1!.status).toBe(StudentMarkStatus.PRESENT);
    expect(mark1!.sourceType).toBe('HISTORICAL_MANUAL');
  });

  // =========================================================================
  // 4. Zero marks are valid numerical marks
  // =========================================================================
  test('4. 0 is accepted as a valid numerical mark and not treated as absent or missing', async () => {
    const createRes = await request(app)
      .post('/api/v1/assessments')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        facultyAssignmentId: facultyAssignmentA._id.toString(),
        title: 'Unit Test 1',
        maximumMarks: 25,
        sourceType: 'HISTORICAL_MANUAL',
        isHistorical: true,
      });

    const assessmentId = createRes.body.data._id || createRes.body.data.id;

    const saveRes = await request(app)
      .post(`/api/v1/assessments/${assessmentId}/draft`)
      .set('Authorization', authHeader(facultyUserA))
      .send({
        entries: [
          {
            studentEnrollmentId: enrollmentDoc1._id.toString(),
            marks: 0,
            status: StudentMarkStatus.PRESENT,
          },
        ],
      });

    expect(saveRes.status).toBe(200);

    const mark1 = await AssessmentMark.findOne({
      assessmentId,
      studentEnrollmentId: enrollmentDoc1._id,
    });
    expect(mark1!.marks).toBe(0);
    expect(mark1!.status).toBe(StudentMarkStatus.PRESENT);
  });

  // =========================================================================
  // 5. Negative marks rejection
  // =========================================================================
  test('5. Negative marks are strictly rejected', async () => {
    const createRes = await request(app)
      .post('/api/v1/assessments')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        facultyAssignmentId: facultyAssignmentA._id.toString(),
        title: 'Unit Test 1',
        maximumMarks: 25,
        sourceType: 'HISTORICAL_MANUAL',
        isHistorical: true,
      });

    const assessmentId = createRes.body.data._id || createRes.body.data.id;

    const saveRes = await request(app)
      .post(`/api/v1/assessments/${assessmentId}/draft`)
      .set('Authorization', authHeader(facultyUserA))
      .send({
        entries: [
          {
            studentEnrollmentId: enrollmentDoc1._id.toString(),
            marks: -5,
            status: StudentMarkStatus.PRESENT,
          },
        ],
      });

    expect(saveRes.status).toBe(400);
    expect(saveRes.body.error?.message).toMatch(/cannot be negative/i);
  });

  // =========================================================================
  // 6. Marks exceeding maximum rejection
  // =========================================================================
  test('6. Marks exceeding maximum marks are strictly rejected', async () => {
    const createRes = await request(app)
      .post('/api/v1/assessments')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        facultyAssignmentId: facultyAssignmentA._id.toString(),
        title: 'Unit Test 1',
        maximumMarks: 25,
        sourceType: 'HISTORICAL_MANUAL',
        isHistorical: true,
      });

    const assessmentId = createRes.body.data._id || createRes.body.data.id;

    const saveRes = await request(app)
      .post(`/api/v1/assessments/${assessmentId}/draft`)
      .set('Authorization', authHeader(facultyUserA))
      .send({
        entries: [
          {
            studentEnrollmentId: enrollmentDoc1._id.toString(),
            marks: 30,
            status: StudentMarkStatus.PRESENT,
          },
        ],
      });

    expect(saveRes.status).toBe(400);
    expect(saveRes.body.error?.message).toMatch(/cannot exceed maximum/i);
  });

  // =========================================================================
  // 7. Empty marks not converted to zero
  // =========================================================================
  test('7. Empty marks input must not silently become zero', async () => {
    const createRes = await request(app)
      .post('/api/v1/assessments')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        facultyAssignmentId: facultyAssignmentA._id.toString(),
        title: 'Unit Test 1',
        maximumMarks: 25,
        sourceType: 'HISTORICAL_MANUAL',
        isHistorical: true,
      });

    const assessmentId = createRes.body.data._id || createRes.body.data.id;

    const saveRes = await request(app)
      .post(`/api/v1/assessments/${assessmentId}/draft`)
      .set('Authorization', authHeader(facultyUserA))
      .send({
        entries: [
          {
            studentEnrollmentId: enrollmentDoc1._id.toString(),
            marks: null,
            status: StudentMarkStatus.NOT_ENTERED,
          },
        ],
      });

    expect(saveRes.status).toBe(200);

    const mark1 = await AssessmentMark.findOne({
      assessmentId,
      studentEnrollmentId: enrollmentDoc1._id,
    });
    expect(mark1!.marks).toBeNull();
    expect(mark1!.status).toBe(StudentMarkStatus.NOT_ENTERED);
  });

  // =========================================================================
  // 8. ABSENT handling
  // =========================================================================
  test('8. ABSENT marks are stored with null numeric score without becoming zero', async () => {
    const createRes = await request(app)
      .post('/api/v1/assessments')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        facultyAssignmentId: facultyAssignmentA._id.toString(),
        title: 'Unit Test 1',
        maximumMarks: 25,
        sourceType: 'HISTORICAL_MANUAL',
        isHistorical: true,
      });

    const assessmentId = createRes.body.data._id || createRes.body.data.id;

    const saveRes = await request(app)
      .post(`/api/v1/assessments/${assessmentId}/draft`)
      .set('Authorization', authHeader(facultyUserA))
      .send({
        entries: [
          {
            studentEnrollmentId: enrollmentDoc1._id.toString(),
            marks: null,
            status: StudentMarkStatus.ABSENT,
          },
        ],
      });

    expect(saveRes.status).toBe(200);

    const mark1 = await AssessmentMark.findOne({
      assessmentId,
      studentEnrollmentId: enrollmentDoc1._id,
    });
    expect(mark1!.marks).toBeNull();
    expect(mark1!.status).toBe(StudentMarkStatus.ABSENT);
  });

  // =========================================================================
  // 9. EXEMPTED handling
  // =========================================================================
  test('9. EXEMPTED students are stored without assigned numerical marks', async () => {
    const createRes = await request(app)
      .post('/api/v1/assessments')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        facultyAssignmentId: facultyAssignmentA._id.toString(),
        title: 'Unit Test 1',
        maximumMarks: 25,
        sourceType: 'HISTORICAL_MANUAL',
        isHistorical: true,
      });

    const assessmentId = createRes.body.data._id || createRes.body.data.id;

    const saveRes = await request(app)
      .post(`/api/v1/assessments/${assessmentId}/draft`)
      .set('Authorization', authHeader(facultyUserA))
      .send({
        entries: [
          {
            studentEnrollmentId: enrollmentDoc1._id.toString(),
            status: StudentMarkStatus.EXEMPTED,
          },
        ],
      });

    expect(saveRes.status).toBe(200);

    const mark1 = await AssessmentMark.findOne({
      assessmentId,
      studentEnrollmentId: enrollmentDoc1._id,
    });
    expect(mark1!.marks).toBeNull();
    expect(mark1!.status).toBe(StudentMarkStatus.EXEMPTED);
  });

  // =========================================================================
  // 10. Duplicate submission protection
  // =========================================================================
  test('10. Duplicate submission protection handles retries safely without duplicating marks', async () => {
    const createRes = await request(app)
      .post('/api/v1/assessments')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        facultyAssignmentId: facultyAssignmentA._id.toString(),
        title: 'Unit Test 1',
        maximumMarks: 25,
        sourceType: 'HISTORICAL_MANUAL',
        isHistorical: true,
      });

    const assessmentId = createRes.body.data._id || createRes.body.data.id;

    // Enter marks for all active students
    await request(app)
      .post(`/api/v1/assessments/${assessmentId}/draft`)
      .set('Authorization', authHeader(facultyUserA))
      .send({
        entries: [
          { studentEnrollmentId: enrollmentDoc1._id.toString(), marks: 20, status: StudentMarkStatus.PRESENT },
          { studentEnrollmentId: enrollmentDoc2._id.toString(), marks: 15, status: StudentMarkStatus.PRESENT },
        ],
      });

    // First submit
    const submit1 = await request(app)
      .post(`/api/v1/assessments/${assessmentId}/submit`)
      .set('Authorization', authHeader(facultyUserA));

    expect(submit1.status).toBe(200);
    expect(submit1.body.data.assessment.status).toBe(AssessmentStatus.SUBMITTED);

    // Duplicate retry submit
    const submit2 = await request(app)
      .post(`/api/v1/assessments/${assessmentId}/submit`)
      .set('Authorization', authHeader(facultyUserA));

    expect(submit2.status).toBe(200);
    expect(submit2.body.data.message).toMatch(/already been submitted/i);

    // Marks count unchanged
    const marksCount = await AssessmentMark.countDocuments({ assessmentId });
    expect(marksCount).toBe(2);
  });

  // =========================================================================
  // 11. Existing mark conflict handling
  // =========================================================================
  test('11. Locked marks cannot be silently modified or overwritten', async () => {
    const createRes = await request(app)
      .post('/api/v1/assessments')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        facultyAssignmentId: facultyAssignmentA._id.toString(),
        title: 'Unit Test 1',
        maximumMarks: 25,
        sourceType: 'HISTORICAL_MANUAL',
        isHistorical: true,
      });

    const assessmentId = createRes.body.data._id || createRes.body.data.id;

    await request(app)
      .post(`/api/v1/assessments/${assessmentId}/draft`)
      .set('Authorization', authHeader(facultyUserA))
      .send({
        entries: [
          { studentEnrollmentId: enrollmentDoc1._id.toString(), marks: 20, status: StudentMarkStatus.PRESENT },
          { studentEnrollmentId: enrollmentDoc2._id.toString(), marks: 15, status: StudentMarkStatus.PRESENT },
        ],
      });

    await request(app)
      .post(`/api/v1/assessments/${assessmentId}/submit`)
      .set('Authorization', authHeader(facultyUserA));

    await request(app)
      .post(`/api/v1/assessments/${assessmentId}/lock`)
      .set('Authorization', authHeader(adminUserA));

    // Attempting direct draft update on locked assessment is rejected
    const editRes = await request(app)
      .post(`/api/v1/assessments/${assessmentId}/draft`)
      .set('Authorization', authHeader(facultyUserA))
      .send({
        entries: [
          { studentEnrollmentId: enrollmentDoc1._id.toString(), marks: 25, status: StudentMarkStatus.PRESENT },
        ],
      });

    expect(editRes.status).toBe(400);
    expect(editRes.body.error?.message).toMatch(/locked/i);
  });

  // =========================================================================
  // 12. Cross-college student rejection
  // =========================================================================
  test('12. Student enrollment from another college is rejected', async () => {
    const createRes = await request(app)
      .post('/api/v1/assessments')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        facultyAssignmentId: facultyAssignmentA._id.toString(),
        title: 'Unit Test 1',
        maximumMarks: 25,
        sourceType: 'HISTORICAL_MANUAL',
        isHistorical: true,
      });

    const assessmentId = createRes.body.data._id || createRes.body.data.id;

    const crossRes = await request(app)
      .post(`/api/v1/assessments/${assessmentId}/draft`)
      .set('Authorization', authHeader(facultyUserA))
      .send({
        entries: [
          {
            studentEnrollmentId: crossCollegeEnrollment._id.toString(),
            marks: 20,
            status: StudentMarkStatus.PRESENT,
          },
        ],
      });

    expect(crossRes.status).toBe(400);
    expect(crossRes.body.error?.message).toMatch(/does not belong to this assessment's active section roster/i);
  });

  // =========================================================================
  // 13. Unauthorized FacultyAssignment rejection
  // =========================================================================
  test('13. Faculty B cannot enter marks for Faculty A assessment', async () => {
    const createRes = await request(app)
      .post('/api/v1/assessments')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        facultyAssignmentId: facultyAssignmentA._id.toString(),
        title: 'Unit Test 1',
        maximumMarks: 25,
        sourceType: 'HISTORICAL_MANUAL',
        isHistorical: true,
      });

    const assessmentId = createRes.body.data._id || createRes.body.data.id;

    const unauthorizedRes = await request(app)
      .post(`/api/v1/assessments/${assessmentId}/draft`)
      .set('Authorization', authHeader(facultyUserB))
      .send({
        entries: [
          {
            studentEnrollmentId: enrollmentDoc1._id.toString(),
            marks: 20,
            status: StudentMarkStatus.PRESENT,
          },
        ],
      });

    expect(unauthorizedRes.status).toBe(403);
    expect(unauthorizedRes.body.error?.message).toMatch(/assigned teaching faculty/i);
  });

  // =========================================================================
  // 14. Assessment lifecycle enforcement
  // =========================================================================
  test('14. Full assessment lifecycle: MARKS_ENTRY -> SUBMITTED -> LOCKED', async () => {
    const createRes = await request(app)
      .post('/api/v1/assessments')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        facultyAssignmentId: facultyAssignmentA._id.toString(),
        title: 'Unit Test 1',
        maximumMarks: 25,
        sourceType: 'HISTORICAL_MANUAL',
        isHistorical: true,
      });

    const assessmentId = createRes.body.data._id || createRes.body.data.id;
    expect(createRes.body.data.status).toBe(AssessmentStatus.MARKS_ENTRY);

    // Save marks for entire active roster
    await request(app)
      .post(`/api/v1/assessments/${assessmentId}/draft`)
      .set('Authorization', authHeader(facultyUserA))
      .send({
        entries: [
          { studentEnrollmentId: enrollmentDoc1._id.toString(), marks: 21, status: StudentMarkStatus.PRESENT },
          { studentEnrollmentId: enrollmentDoc2._id.toString(), status: StudentMarkStatus.ABSENT },
        ],
      });

    // Submit
    const submitRes = await request(app)
      .post(`/api/v1/assessments/${assessmentId}/submit`)
      .set('Authorization', authHeader(facultyUserA));
    expect(submitRes.status).toBe(200);
    expect(submitRes.body.data.assessment.status).toBe(AssessmentStatus.SUBMITTED);

    // Lock
    const lockRes = await request(app)
      .post(`/api/v1/assessments/${assessmentId}/lock`)
      .set('Authorization', authHeader(adminUserA));
    expect(lockRes.status).toBe(200);
    expect(lockRes.body.data.status).toBe(AssessmentStatus.LOCKED);

    // Marks locked
    const m1 = await AssessmentMark.findOne({ assessmentId, studentEnrollmentId: enrollmentDoc1._id });
    expect(m1!.isLocked).toBe(true);
  });

  // =========================================================================
  // 15. Audit and provenance preservation
  // =========================================================================
  test('15. Audit history records HISTORICAL_MARK_SAVED and preserves HISTORICAL_MANUAL provenance', async () => {
    const createRes = await request(app)
      .post('/api/v1/assessments')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        facultyAssignmentId: facultyAssignmentA._id.toString(),
        title: 'Unit Test 1',
        maximumMarks: 25,
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
            marks: 24,
            status: StudentMarkStatus.PRESENT,
            remarks: 'Historical manual entry verified',
          },
        ],
      });

    const mark = await AssessmentMark.findOne({
      assessmentId,
      studentEnrollmentId: enrollmentDoc1._id,
    });
    expect(mark!.sourceType).toBe('HISTORICAL_MANUAL');
    expect(mark!.auditHistory.length).toBeGreaterThanOrEqual(1);

    const savedAudit = mark!.auditHistory.find((a: any) => a.action === 'HISTORICAL_MARK_SAVED');
    expect(savedAudit).toBeDefined();
    expect(savedAudit!.newMarks).toBe(24);
  });

  // =========================================================================
  // 16. Student 360 visibility
  // =========================================================================
  test('16. Finalized historical marks are visible in Student Assessment History', async () => {
    const createRes = await request(app)
      .post('/api/v1/assessments')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        facultyAssignmentId: facultyAssignmentA._id.toString(),
        title: 'Unit Test 1',
        maximumMarks: 25,
        passMarks: 10,
        sourceType: 'HISTORICAL_MANUAL',
        isHistorical: true,
      });

    const assessmentId = createRes.body.data._id || createRes.body.data.id;

    await request(app)
      .post(`/api/v1/assessments/${assessmentId}/draft`)
      .set('Authorization', authHeader(facultyUserA))
      .send({
        entries: [
          { studentEnrollmentId: enrollmentDoc1._id.toString(), marks: 22, status: StudentMarkStatus.PRESENT },
          { studentEnrollmentId: enrollmentDoc2._id.toString(), marks: 19, status: StudentMarkStatus.PRESENT },
        ],
      });

    await request(app)
      .post(`/api/v1/assessments/${assessmentId}/submit`)
      .set('Authorization', authHeader(facultyUserA));

    await request(app)
      .post(`/api/v1/assessments/${assessmentId}/lock`)
      .set('Authorization', authHeader(adminUserA));

    // Student 1 views their history
    const historyRes = await request(app)
      .get(`/api/v1/assessments/student/${studentDoc1._id}`)
      .set('Authorization', authHeader(studentUser1));

    expect(historyRes.status).toBe(200);
    expect(historyRes.body.data.items).toHaveLength(1);
    expect(historyRes.body.data.items[0].title).toBe('Unit Test 1');
    expect(historyRes.body.data.items[0].rawScore).toBe(22);
    expect(historyRes.body.data.items[0].maximumMarks).toBe(25);
    expect(historyRes.body.data.items[0].sourceType).toBe('HISTORICAL_MANUAL');
    expect(historyRes.body.data.items[0].isPassed).toBe(true);
  });

  // =========================================================================
  // 17. Analytics consistency
  // =========================================================================
  test('17. Department assessments analytics reflects historical manual assessments without double counting', async () => {
    const createRes = await request(app)
      .post('/api/v1/assessments')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        facultyAssignmentId: facultyAssignmentA._id.toString(),
        title: 'Unit Test 1',
        maximumMarks: 25,
        passMarks: 10,
        sourceType: 'HISTORICAL_MANUAL',
        isHistorical: true,
      });

    const assessmentId = createRes.body.data._id || createRes.body.data.id;

    await request(app)
      .post(`/api/v1/assessments/${assessmentId}/draft`)
      .set('Authorization', authHeader(facultyUserA))
      .send({
        entries: [
          { studentEnrollmentId: enrollmentDoc1._id.toString(), marks: 20, status: StudentMarkStatus.PRESENT },
          { studentEnrollmentId: enrollmentDoc2._id.toString(), marks: 0, status: StudentMarkStatus.PRESENT },
        ],
      });

    const analyticsRes = await request(app)
      .get('/api/v1/analytics/department/assessments')
      .set('Authorization', authHeader(hodUserA));

    expect(analyticsRes.status).toBe(200);
    expect(analyticsRes.body.data.overview.totalAssessments).toBe(1);
    expect(analyticsRes.body.data.overview.historicalManualAssessmentsCount).toBe(1);
    expect(analyticsRes.body.data.overview.totalMarksEntries).toBe(2);
    expect(analyticsRes.body.data.overview.enteredMarksCount).toBe(2);
    // Student 1 (20) passed, Student 2 (0) failed threshold of 10
    expect(analyticsRes.body.data.overview.passedCount).toBe(1);
    expect(analyticsRes.body.data.overview.failedCount).toBe(1);
  });

  // =========================================================================
  // 18. Partial failure / incomplete roster behavior on final submission
  // =========================================================================
  test('18. Submission is rejected if any enrolled student is unresolved', async () => {
    const createRes = await request(app)
      .post('/api/v1/assessments')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        facultyAssignmentId: facultyAssignmentA._id.toString(),
        title: 'Unit Test 1',
        maximumMarks: 25,
        sourceType: 'HISTORICAL_MANUAL',
        isHistorical: true,
      });

    const assessmentId = createRes.body.data._id || createRes.body.data.id;

    // Only student 1 has a mark entered, student 2 remains NOT_ENTERED
    await request(app)
      .post(`/api/v1/assessments/${assessmentId}/draft`)
      .set('Authorization', authHeader(facultyUserA))
      .send({
        entries: [
          { studentEnrollmentId: enrollmentDoc1._id.toString(), marks: 22, status: StudentMarkStatus.PRESENT },
        ],
      });

    const submitRes = await request(app)
      .post(`/api/v1/assessments/${assessmentId}/submit`)
      .set('Authorization', authHeader(facultyUserA));

    expect(submitRes.status).toBe(400);
    expect(submitRes.body.error?.code).toBe('INCOMPLETE_ROSTER');
    const unresolved = submitRes.body.error?.details?.unresolvedStudents;
    expect(unresolved).toHaveLength(1);
    expect(unresolved[0].studentEnrollmentId).toBe(
      enrollmentDoc2._id.toString()
    );
  });
});
