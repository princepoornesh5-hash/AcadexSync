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
  AssessmentStatus,
  AssessmentType,
  StudentMarkStatus,
  AssessmentMark,
  AssessmentSchedule,
  Room,
  AcademicRuleConfiguration,
} from '../../src/models';
import { PRESET_UGC_10_POINT_SCALE } from '../../src/constants/academicResult.constants';
import { AcademicResultService } from '../../src/services/academicResult.service';
import { InternalAssessmentService } from '../../src/services/internalAssessment.service';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';
import { AppRole } from '../../src/constants/roles';

describe('PROMPT 2/6 — Canonical Assessment Engine, Exam Scheduling & Safe Migration Integration Tests', () => {
  let collegeA: any;
  let collegeB: any;
  let department: any;
  let course: any;
  let academicYear: any;
  let semester: any;
  let section: any;
  let subject: any;
  let room1: any;
  let room2: any;

  let facultyAUser: any;
  let facultyADoc: any;
  let facultyAssignmentA: any;

  let facultyBUser: any;

  let hodUser: any;
  let adminUser: any;
  let studentUser1: any;
  let studentDoc1: any;
  let studentEnrollment1: any;
  let studentUser2: any;
  let studentDoc2: any;

  function authHeader(user: any, collegeId?: string): string {
    return createTestAuthHeader({
      userId: user._id.toString(),
      collegeId: collegeId || user.collegeId.toString(),
      role: user.role,
      email: user.email,
      name: user.name,
    }).Authorization;
  }

  function getErrorMessage(res: any): string {
    return res.body?.error?.message || res.body?.message || '';
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
      name: 'College A Engineering',
      code: 'COLA',
      address: 'Campus A',
      email: 'admin@cola.edu',
      phone: '9000000001',
      principal: 'Dr. Principal A',
    });

    collegeB = await College.create({
      name: 'College B Engineering',
      code: 'COLB',
      address: 'Campus B',
      email: 'admin@colb.edu',
      phone: '9000000002',
      principal: 'Dr. Principal B',
    });

    // 2. Academic Structure for College A
    department = await Department.create({
      collegeId: collegeA._id,
      name: 'Computer Science & Engineering',
      code: 'CSE',
    });

    course = await Course.create({
      collegeId: collegeA._id,
      departmentId: department._id,
      name: 'B.Tech Computer Science',
      code: 'BT-CSE',
    });

    academicYear = await AcademicYear.create({
      collegeId: collegeA._id,
      name: '2026-2027',
      year: '2026-2027',
      startDate: new Date('2026-06-01'),
      endDate: new Date('2027-05-31'),
      status: 'active',
    });

    semester = await Semester.create({
      collegeId: collegeA._id,
      departmentId: department._id,
      courseId: course._id,
      academicYearId: academicYear._id,
      name: 'Semester 5',
      number: 5,
      status: 'active',
    });

    section = await Section.create({
      collegeId: collegeA._id,
      departmentId: department._id,
      courseId: course._id,
      academicYearId: academicYear._id,
      semesterId: semester._id,
      name: 'Section A',
      capacity: 60,
    });

    subject = await Subject.create({
      collegeId: collegeA._id,
      departmentId: department._id,
      courseId: course._id,
      semesterId: semester._id,
      name: 'Database Management Systems',
      code: 'CS501',
      type: 'theory',
      credits: 4,
      status: 'active',
    });

    room1 = await Room.create({
      collegeId: collegeA._id,
      departmentId: department._id,
      name: 'Hall 101',
      code: 'H101',
      capacity: 60,
      type: 'lecture',
      status: 'active',
    });

    room2 = await Room.create({
      collegeId: collegeA._id,
      departmentId: department._id,
      name: 'Hall 102',
      code: 'H102',
      capacity: 60,
      type: 'lecture',
      status: 'active',
    });

    // 3. Faculty A (Assigned Owner of CS501 in Section A)
    facultyAUser = await User.create({
      collegeId: collegeA._id,
      name: 'Prof. Alice DBMS',
      email: 'alice@cola.edu',
      role: AppRole.FACULTY,
      status: 'active',
    });
    facultyADoc = await Faculty.create({
      collegeId: collegeA._id,
      userId: facultyAUser._id,
      departmentId: department._id,
      name: 'Prof. Alice DBMS',
      email: 'alice@cola.edu',
      status: 'active',
    });
    facultyAssignmentA = await FacultyAssignment.create({
      collegeId: collegeA._id,
      facultyId: facultyADoc._id,
      departmentId: department._id,
      courseId: course._id,
      academicYearId: academicYear._id,
      semesterId: semester._id,
      sectionId: section._id,
      subjectId: subject._id,
      facultyName: facultyADoc.name,
      isActive: true,
      status: 'active',
    });

    // 4. Faculty B (Other Faculty)
    facultyBUser = await User.create({
      collegeId: collegeA._id,
      name: 'Prof. Bob OS',
      email: 'bob@cola.edu',
      role: AppRole.FACULTY,
      status: 'active',
    });
    await Faculty.create({
      collegeId: collegeA._id,
      userId: facultyBUser._id,
      departmentId: department._id,
      name: 'Prof. Bob OS',
      email: 'bob@cola.edu',
      status: 'active',
    });

    // 5. Admin and HOD
    adminUser = await User.create({
      collegeId: collegeA._id,
      name: 'Dean Administrator',
      email: 'admin@cola.edu',
      role: AppRole.COLLEGE_ADMIN,
      status: 'active',
    });

    hodUser = await User.create({
      collegeId: collegeA._id,
      departmentId: department._id,
      name: 'Dr. Head of Dept',
      email: 'hod@cola.edu',
      role: AppRole.HOD,
      status: 'active',
    });

    // 6. Students & Canonical Enrollments
    studentUser1 = await User.create({
      collegeId: collegeA._id,
      name: 'John Doe',
      email: 'john@cola.edu',
      role: AppRole.STUDENT,
      status: 'active',
    });
    studentDoc1 = await Student.create({
      collegeId: collegeA._id,
      userId: studentUser1._id,
      departmentId: department._id,
      courseId: course._id,
      name: 'John Doe',
      rollNumber: 'CSE-001',
      admissionNumber: 'ADM-2026-001',
      status: 'active',
    });
    studentEnrollment1 = await StudentEnrollment.create({
      collegeId: collegeA._id,
      studentId: studentDoc1._id,
      departmentId: department._id,
      academicYearId: academicYear._id,
      courseId: course._id,
      semesterId: semester._id,
      sectionId: section._id,
      status: 'active',
    });

    studentUser2 = await User.create({
      collegeId: collegeA._id,
      name: 'Jane Smith',
      email: 'jane@cola.edu',
      role: AppRole.STUDENT,
      status: 'active',
    });
    studentDoc2 = await Student.create({
      collegeId: collegeA._id,
      userId: studentUser2._id,
      departmentId: department._id,
      courseId: course._id,
      name: 'Jane Smith',
      rollNumber: 'CSE-002',
      admissionNumber: 'ADM-2026-002',
      status: 'active',
    });
    await StudentEnrollment.create({
      collegeId: collegeA._id,
      studentId: studentDoc2._id,
      departmentId: department._id,
      academicYearId: academicYear._id,
      courseId: course._id,
      semesterId: semester._id,
      sectionId: section._id,
      status: 'active',
    });
  });

  describe('1. Canonical Assessment Creation & Ownership', () => {
    it('Assigned faculty successfully creates Assessment using facultyAssignmentId', async () => {
      const res = await request(app)
        .post('/api/v1/assessments')
        .set('Authorization', authHeader(facultyAUser))
        .send({
          facultyAssignmentId: facultyAssignmentA._id.toString(),
          title: 'Unit Test 1',
          maximumMarks: 25,
          passMarks: 10,
          assessmentType: 'UNIT_TEST',
        });

      expect(res.status).toBe(201);
      expect(res.body.data.title).toBe('Unit Test 1');
      expect(res.body.data.subjectId.toString()).toBe(subject._id.toString());
      expect(res.body.data.sectionId.toString()).toBe(section._id.toString());
      expect(res.body.data.facultyAssignmentId.toString()).toBe(facultyAssignmentA._id.toString());

      // Canonical AssessmentMark records should be automatically initialized for enrolled students
      const marks = await AssessmentMark.find({ assessmentId: res.body.data._id });
      expect(marks.length).toBe(2);
      expect(marks.map((m) => m.studentEnrollmentId.toString())).toContain(
        studentEnrollment1._id.toString()
      );
    });

    it('Allows multiple distinct assessments for the SAME subject and section (e.g. Unit Test 1 and Unit Test 2)', async () => {
      // 1. Create Unit Test 1
      const res1 = await request(app)
        .post('/api/v1/assessments')
        .set('Authorization', authHeader(facultyAUser))
        .send({
          facultyAssignmentId: facultyAssignmentA._id.toString(),
          title: 'Unit Test 1',
          maximumMarks: 25,
          assessmentType: 'UNIT_TEST',
        });
      expect(res1.status).toBe(201);

      // 2. Create Unit Test 2 for the same class and subject (Previously prevented by monolithic unique index)
      const res2 = await request(app)
        .post('/api/v1/assessments')
        .set('Authorization', authHeader(facultyAUser))
        .send({
          facultyAssignmentId: facultyAssignmentA._id.toString(),
          title: 'Unit Test 2',
          maximumMarks: 25,
          assessmentType: 'UNIT_TEST',
        });
      expect(res2.status).toBe(201);
      expect(res2.body.data.title).toBe('Unit Test 2');

      // 3. Create Model Exam
      const res3 = await request(app)
        .post('/api/v1/assessments')
        .set('Authorization', authHeader(facultyAUser))
        .send({
          facultyAssignmentId: facultyAssignmentA._id.toString(),
          title: 'Model Exam',
          maximumMarks: 100,
          assessmentType: 'MODEL_EXAM',
        });
      expect(res3.status).toBe(201);

      // Verify all 3 discrete assessments exist simultaneously in DB
      const allAssessments = await InternalAssessment.find({
        collegeId: collegeA._id,
        sectionId: section._id,
        subjectId: subject._id,
      });
      expect(allAssessments.length).toBe(3);
    });

    it('Rejects duplicate assessment title within the same section and subject', async () => {
      await request(app)
        .post('/api/v1/assessments')
        .set('Authorization', authHeader(facultyAUser))
        .send({
          facultyAssignmentId: facultyAssignmentA._id.toString(),
          title: 'Internal Assessment 1',
          maximumMarks: 50,
        });

      // Attempt to create identical title for the same class context
      const resDup = await request(app)
        .post('/api/v1/assessments')
        .set('Authorization', authHeader(facultyAUser))
        .send({
          facultyAssignmentId: facultyAssignmentA._id.toString(),
          title: 'Internal Assessment 1',
          maximumMarks: 50,
        });

      expect(resDup.status).toBe(409);
      expect(getErrorMessage(resDup)).toContain(
        "An assessment with title 'Internal Assessment 1' already exists"
      );
    });

    it('Faculty B CANNOT create an assessment for Faculty A teaching assignment (Wrong FacultyAssignment)', async () => {
      const res = await request(app)
        .post('/api/v1/assessments')
        .set('Authorization', authHeader(facultyBUser))
        .send({
          facultyAssignmentId: facultyAssignmentA._id.toString(),
          title: 'Unauthorized Test',
          maximumMarks: 25,
        });

      expect(res.status).toBe(403);
      expect(getErrorMessage(res)).toContain('This context is not assigned to you');
    });
  });

  describe('2. Strict Faculty Marking Ownership & Vulnerability Fix', () => {
    let testAssessment: any;

    beforeEach(async () => {
      testAssessment = await InternalAssessment.create({
        collegeId: collegeA._id,
        departmentId: department._id,
        courseId: course._id,
        academicYearId: academicYear._id,
        semesterId: semester._id,
        sectionId: section._id,
        subjectId: subject._id,
        facultyAssignmentId: facultyAssignmentA._id,
        facultyId: facultyADoc._id,
        facultyName: facultyADoc.name,
        title: 'Mid Term Exam',
        assessmentType: AssessmentType.MID_TERM,
        maximumMarks: 50,
        status: AssessmentStatus.DRAFT,
        entries: [
          {
            studentId: studentDoc1._id,
            studentName: studentDoc1.name,
            totalMarks: 0,
            status: StudentMarkStatus.NOT_ENTERED,
          },
        ],
      });
    });

    it('Assigned faculty CAN save draft marks', async () => {
      const res = await request(app)
        .post('/api/v1/assessments/draft')
        .set('Authorization', authHeader(facultyAUser))
        .send({
          assessmentId: testAssessment._id.toString(),
          entries: [
            {
              studentId: studentDoc1._id.toString(),
              obtainedMarks: 42,
              status: StudentMarkStatus.ENTERED,
            },
          ],
        });

      expect(res.status).toBe(200);

      // Verify canonical AssessmentMark record was upserted
      const mark = await AssessmentMark.findOne({
        assessmentId: testAssessment._id,
        studentId: studentDoc1._id,
      });
      expect(mark).toBeDefined();
      expect(mark!.marks).toBe(42);
      expect(mark!.studentEnrollmentId.toString()).toBe(studentEnrollment1._id.toString());
    });

    it('CRITICAL VULNERABILITY FIX: HOD CANNOT enter or modify marks for faculty-owned assessment', async () => {
      const res = await request(app)
        .post('/api/v1/assessments/draft')
        .set('Authorization', authHeader(hodUser))
        .send({
          assessmentId: testAssessment._id.toString(),
          entries: [
            {
              studentId: studentDoc1._id.toString(),
              obtainedMarks: 45,
            },
          ],
        });

      expect(res.status).toBe(403);
      expect(getErrorMessage(res)).toContain(
        'HOD cannot enter or modify marks for faculty-owned assessments'
      );
    });

    it('CRITICAL VULNERABILITY FIX: College Admin CANNOT enter or modify marks for faculty-owned assessment', async () => {
      const res = await request(app)
        .post('/api/v1/assessments/draft')
        .set('Authorization', authHeader(adminUser))
        .send({
          assessmentId: testAssessment._id.toString(),
          entries: [
            {
              studentId: studentDoc1._id.toString(),
              obtainedMarks: 50,
            },
          ],
        });

      expect(res.status).toBe(403);
      expect(getErrorMessage(res)).toContain(
        'Administrative roles (Super Admin, College Admin) cannot enter or modify marks'
      );
    });

    it('Non-assigned faculty (Faculty B) CANNOT enter or modify marks for Faculty A assessment', async () => {
      const res = await request(app)
        .post('/api/v1/assessments/draft')
        .set('Authorization', authHeader(facultyBUser))
        .send({
          assessmentId: testAssessment._id.toString(),
          entries: [
            {
              studentId: studentDoc1._id.toString(),
              obtainedMarks: 35,
            },
          ],
        });

      expect(res.status).toBe(403);
      expect(getErrorMessage(res)).toContain(
        'Only the assigned teaching faculty may enter or modify marks'
      );
    });
  });

  describe('3. Date-Specific Exam Scheduling & Conflict Detection', () => {
    let testAssessment1: any;
    let testAssessment2: any;

    beforeEach(async () => {
      testAssessment1 = await InternalAssessment.create({
        collegeId: collegeA._id,
        departmentId: department._id,
        courseId: course._id,
        academicYearId: academicYear._id,
        semesterId: semester._id,
        sectionId: section._id,
        subjectId: subject._id,
        facultyAssignmentId: facultyAssignmentA._id,
        facultyId: facultyADoc._id,
        title: 'Mid Term DBMS',
        maximumMarks: 50,
        status: AssessmentStatus.DRAFT,
      });

      testAssessment2 = await InternalAssessment.create({
        collegeId: collegeA._id,
        departmentId: department._id,
        courseId: course._id,
        academicYearId: academicYear._id,
        semesterId: semester._id,
        sectionId: section._id,
        subjectId: subject._id,
        facultyAssignmentId: facultyAssignmentA._id,
        facultyId: facultyADoc._id,
        title: 'Model Exam DBMS',
        maximumMarks: 100,
        status: AssessmentStatus.DRAFT,
      });
    });

    it('Successfully schedules exam with valid date, room, and time', async () => {
      const res = await request(app)
        .post(`/api/v1/assessments/${testAssessment1._id}/schedule`)
        .set('Authorization', authHeader(facultyAUser))
        .send({
          date: '2026-11-20',
          startTime: '09:30',
          endTime: '11:30',
          roomId: room1._id.toString(),
          instructions: 'No calculators allowed',
        });

      expect(res.status).toBe(200);
      expect(res.body.data.dateString).toBe('2026-11-20');
      expect(res.body.data.startTime).toBe('09:30');
      expect(res.body.data.endTime).toBe('11:30');
      expect(res.body.data.roomId.toString()).toBe(room1._id.toString());

      // Verify assessment status transitioned to SCHEDULED
      const updatedAssess = await InternalAssessment.findById(testAssessment1._id);
      expect(updatedAssess!.status).toBe(AssessmentStatus.SCHEDULED);

      // Verify canonical AssessmentSchedule document exists in DB
      const scheduleDoc = await AssessmentSchedule.findOne({ assessmentId: testAssessment1._id });
      expect(scheduleDoc).toBeDefined();
      expect(scheduleDoc!.startTime).toBe('09:30');
    });

    it('Rejects invalid exam time (endTime before startTime)', async () => {
      const res = await request(app)
        .post(`/api/v1/assessments/${testAssessment1._id}/schedule`)
        .set('Authorization', authHeader(facultyAUser))
        .send({
          date: '2026-11-20',
          startTime: '11:30',
          endTime: '09:30', // Invalid: end earlier than start
          roomId: room1._id.toString(),
        });

      expect([400, 422]).toContain(res.status);
      expect(JSON.stringify(res.body)).toContain('endTime must be strictly later than startTime');
    });

    it('Detects and rejects Room Double-Booking Conflict', async () => {
      // 1. Schedule Assessment 1 in Room 1 (09:30 - 11:30)
      await request(app)
        .post(`/api/v1/assessments/${testAssessment1._id}/schedule`)
        .set('Authorization', authHeader(facultyAUser))
        .send({
          date: '2026-11-20',
          startTime: '09:30',
          endTime: '11:30',
          roomId: room1._id.toString(),
        });

      // 2. Attempt to schedule Assessment 2 in Room 1 overlapping (10:00 - 12:00)
      const resConflict = await request(app)
        .post(`/api/v1/assessments/${testAssessment2._id}/schedule`)
        .set('Authorization', authHeader(facultyAUser))
        .send({
          date: '2026-11-20',
          startTime: '10:00',
          endTime: '12:00',
          roomId: room1._id.toString(),
        });

      expect(resConflict.status).toBe(409);
      expect(getErrorMessage(resConflict)).toContain(
        'The selected room is already booked for another assessment'
      );
    });

    it('Detects and rejects Section Overlapping Conflict', async () => {
      // 1. Schedule Assessment 1 for Section A in Room 1 (09:30 - 11:30)
      await request(app)
        .post(`/api/v1/assessments/${testAssessment1._id}/schedule`)
        .set('Authorization', authHeader(facultyAUser))
        .send({
          date: '2026-11-20',
          startTime: '09:30',
          endTime: '11:30',
          roomId: room1._id.toString(),
        });

      // 2. Attempt to schedule Assessment 2 for the same section in Room 2 at the same time
      const resSectionConflict = await request(app)
        .post(`/api/v1/assessments/${testAssessment2._id}/schedule`)
        .set('Authorization', authHeader(facultyAUser))
        .send({
          date: '2026-11-20',
          startTime: '09:30',
          endTime: '11:30',
          roomId: room2._id.toString(),
        });

      expect(resSectionConflict.status).toBe(409);
      expect(getErrorMessage(resSectionConflict)).toContain(
        'The selected section already has another assessment scheduled'
      );
    });
  });

  describe('4. Tenant Isolation', () => {
    it('Blocks user from College B from querying or modifying College A assessments', async () => {
      const userColB = await User.create({
        collegeId: collegeB._id,
        name: 'College B Faculty',
        email: 'colb@faculty.edu',
        role: AppRole.FACULTY,
        status: 'active',
      });

      const assessColA = await InternalAssessment.create({
        collegeId: collegeA._id,
        departmentId: department._id,
        courseId: course._id,
        academicYearId: academicYear._id,
        semesterId: semester._id,
        sectionId: section._id,
        subjectId: subject._id,
        title: 'College A Exam',
        maximumMarks: 50,
      });

      const res = await request(app)
        .get(`/api/v1/assessments/${assessColA._id}`)
        .set('Authorization', authHeader(userColB, collegeB._id.toString()));

      expect(res.status).toBe(404);
      expect(getErrorMessage(res)).toContain('Assessment not found');
    });
  });

  describe('5. AcademicResultService Compatibility', () => {
    it('AcademicResultService consumes canonical AssessmentMark records when calculating grades', async () => {
      // 1. Create Published Assessment
      const assess = await InternalAssessment.create({
        collegeId: collegeA._id,
        departmentId: department._id,
        courseId: course._id,
        academicYearId: academicYear._id,
        semesterId: semester._id,
        sectionId: section._id,
        subjectId: subject._id,
        title: 'Published Final Test',
        maximumMarks: 100,
        status: AssessmentStatus.PUBLISHED,
        entries: [],
      });

      // 2. Create canonical AssessmentMark with 85 marks for Student 1
      await AssessmentMark.create({
        collegeId: collegeA._id,
        assessmentId: assess._id,
        subjectId: subject._id,
        studentEnrollmentId: studentEnrollment1._id,
        studentId: studentDoc1._id,
        studentName: studentDoc1.name,
        marks: 85,
        maximumMarks: 100,
        status: StudentMarkStatus.ENTERED,
        isLocked: true,
        sourceType: 'LIVE',
      });

      // 3. Configure AcademicRuleConfiguration
      await AcademicRuleConfiguration.create({
        collegeId: collegeA._id,
        courseId: course._id,
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

      // 4. Invoke AcademicResultService calculation
      const { result } = await AcademicResultService.calculateSemesterResult({
        collegeId: collegeA._id.toString(),
        studentId: studentDoc1._id.toString(),
        semesterId: semester._id.toString(),
        academicYearId: academicYear._id.toString(),
        user: { id: adminUser._id.toString(), name: adminUser.name, role: adminUser.role },
      });

      expect(result).toBeDefined();
      expect(result.subjectResults.length).toBeGreaterThan(0);
      const subjRes = result.subjectResults.find(
        (sr: any) => sr.subjectId.toString() === subject._id.toString()
      );
      expect(subjRes).toBeDefined();
      expect(subjRes!.totalObtainedMarks).toBe(85);
      expect(subjRes!.status).toBe('PASS');
    });
  });

  describe('6. Safe InternalAssessment Migration Utility', () => {
    it('Idempotently migrates legacy embedded entries to canonical AssessmentMark records and reports unresolved enrollments', async () => {
      // Create a legacy assessment with 1 resolved student and 1 unresolvable student
      const unresolvableStudentId = new mongoose.Types.ObjectId();

      const legacyAssess = await InternalAssessment.create({
        collegeId: collegeA._id,
        departmentId: department._id,
        courseId: course._id,
        academicYearId: academicYear._id,
        semesterId: semester._id,
        sectionId: section._id,
        subjectId: subject._id,
        title: 'Legacy Assessment 2025',
        maximumMarks: 50,
        status: AssessmentStatus.PUBLISHED,
        entries: [
          {
            studentId: studentDoc1._id,
            studentName: studentDoc1.name,
            totalMarks: 45,
            status: StudentMarkStatus.ENTERED,
          },
          {
            studentId: unresolvableStudentId,
            studentName: 'Ghost Student',
            totalMarks: 30,
            status: StudentMarkStatus.ENTERED,
          },
        ],
      });

      // 1. Dry-Run Migration
      const dryReport = await InternalAssessmentService.runMigration(
        collegeA._id.toString(),
        true // dryRun
      );

      expect(dryReport.recordsDiscovered).toBeGreaterThanOrEqual(1);
      expect(dryReport.marksMigrated).toBe(1);
      expect(dryReport.unresolvedStudents.length).toBe(1);
      expect(dryReport.unresolvedStudents[0].studentId).toBe(unresolvableStudentId.toString());

      // In dry-run, no documents should be inserted into DB
      const dbMarksDry = await AssessmentMark.find({ assessmentId: legacyAssess._id });
      expect(dbMarksDry.length).toBe(0);

      // 2. Real Migration Execution
      const realReport = await InternalAssessmentService.runMigration(
        collegeA._id.toString(),
        false // real migration
      );

      expect(realReport.marksMigrated).toBe(1);
      const dbMarksReal = await AssessmentMark.find({ assessmentId: legacyAssess._id });
      expect(dbMarksReal.length).toBe(1);
      expect(dbMarksReal[0].marks).toBe(45);
      expect(dbMarksReal[0].studentEnrollmentId.toString()).toBe(studentEnrollment1._id.toString());

      // 3. Second Execution (Idempotency Check)
      const repeatReport = await InternalAssessmentService.runMigration(
        collegeA._id.toString(),
        false
      );
      expect(repeatReport.marksMigrated).toBe(0);
      expect(repeatReport.skippedRecords).toBe(1); // Safely skipped existing record
    });
  });
});
