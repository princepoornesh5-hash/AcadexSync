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
  AssessmentStatus,
  AssessmentType,
  StudentMarkStatus,
  AssessmentMark,
  AssessmentSchedule,
  AuditLog,
} from '../../src/models';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';
import { AppRole } from '../../src/constants/roles';

describe('PROMPT 3/6 — Marks Entry, Submission, Locking & Controlled Corrections Integration Tests', () => {
  let collegeA: any;
  let collegeB: any;
  let departmentA: any;
  let courseA: any;
  let academicYearA: any;
  let semesterA: any;
  let sectionA: any;
  let sectionB: any;
  let subjectIME: any;

  let facultyAUser: any;
  let facultyADoc: any;
  let facultyAssignmentA: any;

  let facultyBUser: any;
  let facultyBDoc: any;

  let hodUser: any;
  let collegeAdminUser: any;

  let studentUsers: any[] = [];
  let studentDocs: any[] = [];
  let studentEnrollmentsA: any[] = [];
  let studentEnrollmentB: any;

  let assessment: any;

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

    // 2. Department & Academic Hierarchy in College A
    departmentA = await Department.create({
      collegeId: collegeA._id,
      name: 'Computer Science & Engineering',
      code: 'CSE',
    });

    courseA = await Course.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      name: 'B.Tech CSE',
      code: 'BT-CSE',
      durationYears: 4,
    });

    academicYearA = await AcademicYear.create({
      collegeId: collegeA._id,
      name: '2026-2027',
      startDate: new Date('2026-06-01'),
      endDate: new Date('2027-05-31'),
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

    sectionB = await Section.create({
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

    // 3. Faculty A (Assigned to Section A for subject IME)
    facultyAUser = await User.create({
      collegeId: collegeA._id,
      email: 'fac_a@cola.edu',
      password: 'password123',
      name: 'Prof. Alan Turing',
      role: AppRole.FACULTY,
    });

    facultyADoc = await Faculty.create({
      collegeId: collegeA._id,
      userId: facultyAUser._id,
      departmentId: departmentA._id,
      name: 'Prof. Alan Turing',
      email: 'fac_a@cola.edu',
      facultyId: 'FAC-A-001',
      designation: 'Professor',
      status: 'active',
    });

    facultyAssignmentA = await FacultyAssignment.create({
      collegeId: collegeA._id,
      facultyId: facultyADoc._id,
      departmentId: departmentA._id,
      courseId: courseA._id,
      subjectId: subjectIME._id,
      sectionId: sectionA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      facultyName: 'Prof. Alan Turing',
      isPrimary: true,
      isActive: true,
      status: 'active',
    });

    // 4. Faculty B (Assigned to Section B for subject IME)
    facultyBUser = await User.create({
      collegeId: collegeA._id,
      email: 'fac_b@cola.edu',
      password: 'password123',
      name: 'Prof. Barbara Liskov',
      role: AppRole.FACULTY,
    });

    facultyBDoc = await Faculty.create({
      collegeId: collegeA._id,
      userId: facultyBUser._id,
      departmentId: departmentA._id,
      name: 'Prof. Barbara Liskov',
      email: 'fac_b@cola.edu',
      facultyId: 'FAC-B-002',
      designation: 'Associate Professor',
      status: 'active',
    });

    await FacultyAssignment.create({
      collegeId: collegeA._id,
      facultyId: facultyBDoc._id,
      departmentId: departmentA._id,
      courseId: courseA._id,
      subjectId: subjectIME._id,
      sectionId: sectionB._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      facultyName: 'Prof. Barbara Liskov',
      isPrimary: true,
      isActive: true,
      status: 'active',
    });

    // 5. HOD, Admin, Super Admin
    hodUser = await User.create({
      collegeId: collegeA._id,
      email: 'hod.cse@cola.edu',
      password: 'password123',
      name: 'Dr. Claude Shannon',
      role: AppRole.HOD,
      departmentId: departmentA._id,
    });

    collegeAdminUser = await User.create({
      collegeId: collegeA._id,
      email: 'admin@cola.edu',
      password: 'password123',
      name: 'Admin Alice',
      role: AppRole.COLLEGE_ADMIN,
    });

    await User.create({
      collegeId: collegeA._id,
      email: 'superadmin@acadex.edu',
      password: 'password123',
      name: 'Super Admin Sam',
      role: AppRole.SUPER_ADMIN,
    });

    // 6. Students in Section A (5 students)
    studentUsers = [];
    studentDocs = [];
    studentEnrollmentsA = [];

    for (let i = 1; i <= 5; i++) {
      const u = await User.create({
        collegeId: collegeA._id,
        email: `student${i}@cola.edu`,
        password: 'password123',
        name: `Student ${i}`,
        role: AppRole.STUDENT,
      });
      studentUsers.push(u);

      const s = await Student.create({
        collegeId: collegeA._id,
        userId: u._id,
        departmentId: departmentA._id,
        courseId: courseA._id,
        name: `Student ${i}`,
        email: `student${i}@cola.edu`,
        admissionNumber: `ADM-2026-00${i}`,
        rollNumber: `CS50${i}`,
        status: 'active',
        academicYearId: academicYearA._id,
      });
      studentDocs.push(s);

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

    // Student 6 in Section B (Outside Section A boundary)
    const u6 = await User.create({
      collegeId: collegeA._id,
      email: 'student6@cola.edu',
      password: 'password123',
      name: 'Student 6 Outside',
      role: AppRole.STUDENT,
    });
    const s6 = await Student.create({
      collegeId: collegeA._id,
      userId: u6._id,
      departmentId: departmentA._id,
      courseId: courseA._id,
      name: 'Student 6 Outside',
      email: 'student6@cola.edu',
      admissionNumber: 'ADM-2026-006',
      rollNumber: 'CS506-B',
      status: 'active',
      academicYearId: academicYearA._id,
    });
    studentEnrollmentB = await StudentEnrollment.create({
      collegeId: collegeA._id,
      studentId: s6._id,
      departmentId: departmentA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionB._id,
      rollNumber: 'CS506-B',
      status: 'active',
      enrollmentDate: new Date('2026-06-01'),
    });

    // 7. Base Assessment for Section A owned by Faculty A
    assessment = await InternalAssessment.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      subjectId: subjectIME._id,
      facultyAssignmentId: facultyAssignmentA._id,
      facultyId: facultyADoc._id,
      title: 'IME Unit Test 1',
      assessmentType: AssessmentType.INTERNAL_EXAM,
      maximumMarks: 25,
      passMarks: 10,
      status: AssessmentStatus.MARKS_ENTRY,
      entries: [],
    });
  });

  // ============================================================
  // TEST SUITE: 24 TARGETED PROMPT 3 REQUIREMENTS
  // ============================================================

  // 1. Faculty can view own assessment roster
  test('1. Faculty can view own assessment roster', async () => {
    const res = await request(app)
      .get(`/api/v1/assessments/${assessment._id}/roster`)
      .set('Authorization', authHeader(facultyAUser));

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.summary.totalStudents).toBe(5);
    expect(res.body.data.roster).toHaveLength(5);
    expect(res.body.data.roster[0]).toHaveProperty('studentEnrollmentId');
    expect(res.body.data.roster[0]).toHaveProperty('studentName');
    expect(res.body.data.roster[0].maximumMarks).toBe(25);
  });

  // 2. Faculty can save valid draft marks
  test('2. Faculty can save valid draft marks', async () => {
    const payload = {
      entries: [
        {
          studentId: studentDocs[0]._id.toString(),
          studentEnrollmentId: studentEnrollmentsA[0]._id.toString(),
          studentName: 'Student 1',
          marks: 20,
          status: StudentMarkStatus.PRESENT,
          remarks: 'Good performance',
        },
      ],
    };

    const res = await request(app)
      .put(`/api/v1/assessments/${assessment._id}/draft`)
      .set('Authorization', authHeader(facultyAUser))
      .send(payload);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);

    const mark = await AssessmentMark.findOne({
      assessmentId: assessment._id,
      studentEnrollmentId: studentEnrollmentsA[0]._id,
    });
    expect(mark).toBeDefined();
    expect(mark?.marks).toBe(20);
    expect(mark?.status).toBe(StudentMarkStatus.PRESENT);
    expect(mark?.isLocked).toBe(false);
  });

  // 3. Faculty cannot save marks before marks-entry eligibility
  test('3. Faculty cannot save marks before marks-entry eligibility (future exam)', async () => {
    // Set up assessment in SCHEDULED status with exam in future
    const futureAssessment = await InternalAssessment.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      subjectId: subjectIME._id,
      facultyAssignmentId: facultyAssignmentA._id,
      facultyId: facultyADoc._id,
      title: 'Future Exam',
      assessmentType: AssessmentType.INTERNAL_EXAM,
      maximumMarks: 25,
      status: AssessmentStatus.SCHEDULED,
      entries: [],
    });

    const tomorrow = new Date();
    tomorrow.setDate(tomorrow.getDate() + 1);
    const dateStr = tomorrow.toISOString().split('T')[0];

    await AssessmentSchedule.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      facultyAssignmentId: facultyAssignmentA._id,
      subjectId: subjectIME._id,
      assessmentId: futureAssessment._id,
      date: tomorrow,
      dateString: dateStr,
      startTime: '10:00',
      endTime: '12:00',
      status: 'SCHEDULED',
    });

    const res = await request(app)
      .put(`/api/v1/assessments/${futureAssessment._id}/draft`)
      .set('Authorization', authHeader(facultyAUser))
      .send({
        entries: [
          {
            studentId: studentDocs[0]._id.toString(),
            studentEnrollmentId: studentEnrollmentsA[0]._id.toString(),
            studentName: 'Student 1',
            marks: 18,
            status: StudentMarkStatus.PRESENT,
          },
        ],
      });

    expect(res.status).toBe(400);
    expect(getErrorMessage(res)).toContain('Assessment exam has not completed yet');
  });

  // 4. Faculty cannot save marks after lock
  test('4. Faculty cannot save marks after lock', async () => {
    await InternalAssessment.findByIdAndUpdate(assessment._id, {
      status: AssessmentStatus.LOCKED,
      lockedAt: new Date(),
    });

    const res = await request(app)
      .put(`/api/v1/assessments/${assessment._id}/draft`)
      .set('Authorization', authHeader(facultyAUser))
      .send({
        entries: [
          {
            studentId: studentDocs[0]._id.toString(),
            studentEnrollmentId: studentEnrollmentsA[0]._id.toString(),
            studentName: 'Student 1',
            marks: 22,
            status: StudentMarkStatus.PRESENT,
          },
        ],
      });

    expect(res.status).toBe(400);
    expect(getErrorMessage(res)).toContain('Assessment is locked');
  });

  // 5. 0 is accepted as a valid mark
  test('5. 0 is accepted as a valid mark and not treated as absent or missing', async () => {
    const res = await request(app)
      .put(`/api/v1/assessments/${assessment._id}/draft`)
      .set('Authorization', authHeader(facultyAUser))
      .send({
        entries: [
          {
            studentId: studentDocs[1]._id.toString(),
            studentEnrollmentId: studentEnrollmentsA[1]._id.toString(),
            studentName: 'Student 2',
            marks: 0,
            status: StudentMarkStatus.PRESENT,
          },
        ],
      });

    expect(res.status).toBe(200);

    const mark = await AssessmentMark.findOne({
      assessmentId: assessment._id,
      studentEnrollmentId: studentEnrollmentsA[1]._id,
    });
    expect(mark).toBeDefined();
    expect(mark?.marks).toBe(0);
    expect(mark?.status).toBe(StudentMarkStatus.PRESENT);
  });

  // 6. Negative marks are rejected
  test('6. Negative marks are rejected', async () => {
    const res = await request(app)
      .put(`/api/v1/assessments/${assessment._id}/draft`)
      .set('Authorization', authHeader(facultyAUser))
      .send({
        entries: [
          {
            studentId: studentDocs[0]._id.toString(),
            studentEnrollmentId: studentEnrollmentsA[0]._id.toString(),
            studentName: 'Student 1',
            marks: -1,
            status: StudentMarkStatus.PRESENT,
          },
        ],
      });

    expect(res.status).toBe(400);
    expect(getErrorMessage(res)).toContain('cannot be negative');
  });

  // 7. Marks above maximum are rejected
  test('7. Marks above maximum are rejected', async () => {
    const res = await request(app)
      .put(`/api/v1/assessments/${assessment._id}/draft`)
      .set('Authorization', authHeader(facultyAUser))
      .send({
        entries: [
          {
            studentId: studentDocs[0]._id.toString(),
            studentEnrollmentId: studentEnrollmentsA[0]._id.toString(),
            studentName: 'Student 1',
            marks: 26,
            status: StudentMarkStatus.PRESENT,
          },
        ],
      });

    expect(res.status).toBe(400);
    expect(getErrorMessage(res)).toContain('cannot exceed maximum allowed');
  });

  // 8. ABSENT can be stored without treating it as zero
  test('8. ABSENT can be stored without treating it as zero', async () => {
    const res = await request(app)
      .put(`/api/v1/assessments/${assessment._id}/draft`)
      .set('Authorization', authHeader(facultyAUser))
      .send({
        entries: [
          {
            studentId: studentDocs[2]._id.toString(),
            studentEnrollmentId: studentEnrollmentsA[2]._id.toString(),
            studentName: 'Student 3',
            marks: null,
            status: StudentMarkStatus.ABSENT,
          },
        ],
      });

    expect(res.status).toBe(200);

    const mark = await AssessmentMark.findOne({
      assessmentId: assessment._id,
      studentEnrollmentId: studentEnrollmentsA[2]._id,
    });
    expect(mark).toBeDefined();
    expect(mark?.marks).toBeNull();
    expect(mark?.status).toBe(StudentMarkStatus.ABSENT);
  });

  // 9. Student enrollment outside the assessment section is rejected
  test('9. Student enrollment outside the assessment section is rejected', async () => {
    const res = await request(app)
      .put(`/api/v1/assessments/${assessment._id}/draft`)
      .set('Authorization', authHeader(facultyAUser))
      .send({
        entries: [
          {
            studentId: studentEnrollmentB.studentId.toString(),
            studentEnrollmentId: studentEnrollmentB._id.toString(),
            studentName: 'Student 6 Outside',
            marks: 15,
            status: StudentMarkStatus.PRESENT,
          },
        ],
      });

    expect(res.status).toBe(400);
    expect(getErrorMessage(res)).toContain('does not belong to this assessment');
  });

  // 10. Faculty B cannot modify Faculty A's assessment
  test('10. Faculty B cannot modify Faculty A assessment', async () => {
    const res = await request(app)
      .put(`/api/v1/assessments/${assessment._id}/draft`)
      .set('Authorization', authHeader(facultyBUser))
      .send({
        entries: [
          {
            studentId: studentDocs[0]._id.toString(),
            studentEnrollmentId: studentEnrollmentsA[0]._id.toString(),
            studentName: 'Student 1',
            marks: 18,
            status: StudentMarkStatus.PRESENT,
          },
        ],
      });

    expect(res.status).toBe(403);
    expect(getErrorMessage(res)).toContain('Only the assigned teaching faculty may enter or modify marks');
  });

  // 11. HOD cannot directly modify faculty-owned marks
  test('11. HOD cannot directly modify faculty-owned marks', async () => {
    const res = await request(app)
      .put(`/api/v1/assessments/${assessment._id}/draft`)
      .set('Authorization', authHeader(hodUser))
      .send({
        entries: [
          {
            studentId: studentDocs[0]._id.toString(),
            studentEnrollmentId: studentEnrollmentsA[0]._id.toString(),
            studentName: 'Student 1',
            marks: 20,
            status: StudentMarkStatus.PRESENT,
          },
        ],
      });

    expect(res.status).toBe(403);
    expect(getErrorMessage(res)).toContain('HOD cannot enter or modify marks');
  });

  // 12. College Admin cannot directly modify faculty-owned marks
  test('12. College Admin cannot directly modify faculty-owned marks', async () => {
    const res = await request(app)
      .put(`/api/v1/assessments/${assessment._id}/draft`)
      .set('Authorization', authHeader(collegeAdminUser))
      .send({
        entries: [
          {
            studentId: studentDocs[0]._id.toString(),
            studentEnrollmentId: studentEnrollmentsA[0]._id.toString(),
            studentName: 'Student 1',
            marks: 20,
            status: StudentMarkStatus.PRESENT,
          },
        ],
      });

    expect(res.status).toBe(403);
    expect(getErrorMessage(res)).toContain('Administrative roles');
  });

  // 13. Submit rejects incomplete required roster
  test('13. Submit rejects incomplete required roster', async () => {
    // Only student 1 entered, remaining 4 are not entered
    await request(app)
      .put(`/api/v1/assessments/${assessment._id}/draft`)
      .set('Authorization', authHeader(facultyAUser))
      .send({
        entries: [
          {
            studentId: studentDocs[0]._id.toString(),
            studentEnrollmentId: studentEnrollmentsA[0]._id.toString(),
            studentName: 'Student 1',
            marks: 20,
            status: StudentMarkStatus.PRESENT,
          },
        ],
      });

    const res = await request(app)
      .post(`/api/v1/assessments/${assessment._id}/submit`)
      .set('Authorization', authHeader(facultyAUser))
      .send();

    expect(res.status).toBe(400);
    expect(getErrorMessage(res)).toContain('require a mark or attendance status');
    expect(res.body.error?.details?.unresolvedStudents).toBeDefined();
    expect(res.body.error.details.unresolvedStudents.length).toBeGreaterThan(0);
  });

  // 14. Successful submission transitions assessment correctly
  test('14. Successful submission transitions assessment correctly', async () => {
    // Enter all 5 students with explicit outcomes
    const fullDraftPayload = {
      entries: [
        {
          studentId: studentDocs[0]._id.toString(),
          studentEnrollmentId: studentEnrollmentsA[0]._id.toString(),
          studentName: 'Student 1',
          marks: 20,
          status: StudentMarkStatus.PRESENT,
        },
        {
          studentId: studentDocs[1]._id.toString(),
          studentEnrollmentId: studentEnrollmentsA[1]._id.toString(),
          studentName: 'Student 2',
          marks: 0,
          status: StudentMarkStatus.PRESENT,
        },
        {
          studentId: studentDocs[2]._id.toString(),
          studentEnrollmentId: studentEnrollmentsA[2]._id.toString(),
          studentName: 'Student 3',
          marks: null,
          status: StudentMarkStatus.ABSENT,
        },
        {
          studentId: studentDocs[3]._id.toString(),
          studentEnrollmentId: studentEnrollmentsA[3]._id.toString(),
          studentName: 'Student 4',
          marks: null,
          status: StudentMarkStatus.EXEMPTED,
        },
        {
          studentId: studentDocs[4]._id.toString(),
          studentEnrollmentId: studentEnrollmentsA[4]._id.toString(),
          studentName: 'Student 5',
          marks: null,
          status: StudentMarkStatus.NOT_APPEARED,
        },
      ],
    };

    await request(app)
      .put(`/api/v1/assessments/${assessment._id}/draft`)
      .set('Authorization', authHeader(facultyAUser))
      .send(fullDraftPayload);

    const res = await request(app)
      .post(`/api/v1/assessments/${assessment._id}/submit`)
      .set('Authorization', authHeader(facultyAUser))
      .send();

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);

    const updated = await InternalAssessment.findById(assessment._id);
    expect(updated?.status).toBe(AssessmentStatus.SUBMITTED);
    expect(updated?.submittedAt).toBeDefined();
    expect(updated?.submittedBy?.toString()).toBe(facultyAUser._id.toString());
  });

  // 15. Submitted marks cannot be normally edited
  test('15. Submitted marks cannot be normally edited', async () => {
    await InternalAssessment.findByIdAndUpdate(assessment._id, {
      status: AssessmentStatus.SUBMITTED,
      submittedAt: new Date(),
    });

    const res = await request(app)
      .put(`/api/v1/assessments/${assessment._id}/draft`)
      .set('Authorization', authHeader(facultyAUser))
      .send({
        entries: [
          {
            studentId: studentDocs[0]._id.toString(),
            studentEnrollmentId: studentEnrollmentsA[0]._id.toString(),
            studentName: 'Student 1',
            marks: 24,
            status: StudentMarkStatus.PRESENT,
          },
        ],
      });

    expect(res.status).toBe(400);
    expect(getErrorMessage(res)).toContain('submitted');
  });

  // 16. Locked marks cannot be directly edited
  test('16. Locked marks cannot be directly edited', async () => {
    await InternalAssessment.findByIdAndUpdate(assessment._id, {
      status: AssessmentStatus.LOCKED,
      lockedAt: new Date(),
    });
    await AssessmentMark.updateMany({ assessmentId: assessment._id }, { isLocked: true });

    const res = await request(app)
      .put(`/api/v1/assessments/${assessment._id}/draft`)
      .set('Authorization', authHeader(facultyAUser))
      .send({
        entries: [
          {
            studentId: studentDocs[0]._id.toString(),
            studentEnrollmentId: studentEnrollmentsA[0]._id.toString(),
            studentName: 'Student 1',
            marks: 24,
            status: StudentMarkStatus.PRESENT,
          },
        ],
      });

    expect(res.status).toBe(400);
    expect(getErrorMessage(res)).toContain('Assessment is locked');
  });

  // 17. Correction request requires authorization
  test('17. Correction request requires authorization', async () => {
    // Set status to SUBMITTED for correction request flow
    await InternalAssessment.findByIdAndUpdate(assessment._id, {
      status: AssessmentStatus.SUBMITTED,
      submittedAt: new Date(),
    });

    // 17a: Student cannot request mark correction
    const studentRes = await request(app)
      .post(`/api/v1/assessments/${assessment._id}/corrections/request`)
      .set('Authorization', authHeader(studentUsers[0]))
      .send({
        studentEnrollmentId: studentEnrollmentsA[0]._id.toString(),
        reason: 'Please increase my marks',
        newMark: 25,
      });

    expect(studentRes.status).toBe(403);

    // 17b: Faculty A can submit correction request
    const facRes = await request(app)
      .post(`/api/v1/assessments/${assessment._id}/corrections/request`)
      .set('Authorization', authHeader(facultyAUser))
      .send({
        studentEnrollmentId: studentEnrollmentsA[0]._id.toString(),
        reason: 'Recalculation adjustment for Question 3',
        newMark: 24,
        newStatus: StudentMarkStatus.PRESENT,
      });

    expect(facRes.status).toBe(201);
    expect(facRes.body.success).toBe(true);
    expect(facRes.body.data.request).toBeDefined();
    expect(facRes.body.data.request.requestType).toBe('ASSESSMENT_MARK_CORRECTION');
  });

  // 18. Unauthorized user cannot approve correction
  test('18. Unauthorized user / Requester cannot approve correction', async () => {
    await InternalAssessment.findByIdAndUpdate(assessment._id, {
      status: AssessmentStatus.SUBMITTED,
      submittedAt: new Date(),
    });

    // Faculty A creates correction request
    const reqRes = await request(app)
      .post(`/api/v1/assessments/${assessment._id}/corrections/request`)
      .set('Authorization', authHeader(facultyAUser))
      .send({
        studentEnrollmentId: studentEnrollmentsA[0]._id.toString(),
        reason: 'Re-evaluation correction',
        newMark: 22,
      });

    const requestId = reqRes.body.data.request._id;

    // Faculty A attempts to approve own request
    const selfApproveRes = await request(app)
      .post(`/api/v1/assessments/corrections/${requestId}/respond`)
      .set('Authorization', authHeader(facultyAUser))
      .send({
        action: 'APPROVE',
        message: 'Self approved',
      });

    expect(selfApproveRes.status).toBe(403);
    expect(getErrorMessage(selfApproveRes)).toContain('Requester cannot approve their own correction request');
  });

  // 19. Approved correction permits only the intended correction scope
  test('19. Approved correction permits only the intended correction scope', async () => {
    // First lock the assessment and mark for student 0 & student 1
    await InternalAssessment.findByIdAndUpdate(assessment._id, {
      status: AssessmentStatus.LOCKED,
      lockedAt: new Date(),
    });
    await AssessmentMark.create({
      collegeId: collegeA._id,
      assessmentId: assessment._id,
      facultyAssignmentId: facultyAssignmentA._id,
      subjectId: subjectIME._id,
      studentEnrollmentId: studentEnrollmentsA[0]._id,
      studentId: studentDocs[0]._id,
      studentName: 'Student 1',
      marks: 20,
      maximumMarks: 25,
      status: StudentMarkStatus.PRESENT,
      isLocked: true,
      sourceType: 'LIVE',
    });
    await AssessmentMark.create({
      collegeId: collegeA._id,
      assessmentId: assessment._id,
      facultyAssignmentId: facultyAssignmentA._id,
      subjectId: subjectIME._id,
      studentEnrollmentId: studentEnrollmentsA[1]._id,
      studentId: studentDocs[1]._id,
      studentName: 'Student 2',
      marks: 15,
      maximumMarks: 25,
      status: StudentMarkStatus.PRESENT,
      isLocked: true,
      sourceType: 'LIVE',
    });

    // Request correction for Student 0 only
    const reqRes = await request(app)
      .post(`/api/v1/assessments/${assessment._id}/corrections/request`)
      .set('Authorization', authHeader(facultyAUser))
      .send({
        studentEnrollmentId: studentEnrollmentsA[0]._id.toString(),
        reason: 'Correction for Student 1 only',
        newMark: 23,
      });

    const requestId = reqRes.body.data.request._id;

    // HOD approves the request
    const approveRes = await request(app)
      .post(`/api/v1/assessments/corrections/${requestId}/respond`)
      .set('Authorization', authHeader(hodUser))
      .send({
        action: 'APPROVE',
        message: 'Approved re-evaluation',
      });

    expect(approveRes.status).toBe(200);

    // Assessment is now reopened to MARKS_ENTRY with correctionScope
    const reassessment = await InternalAssessment.findById(assessment._id);
    expect(reassessment?.status).toBe(AssessmentStatus.MARKS_ENTRY);
    expect(
      reassessment?.correctionScope?.studentEnrollmentIds?.map((id: any) => id.toString())
    ).toContain(studentEnrollmentsA[0]._id.toString());

    // Faculty A can edit Student 0
    const editAllowedRes = await request(app)
      .put(`/api/v1/assessments/${assessment._id}/draft`)
      .set('Authorization', authHeader(facultyAUser))
      .send({
        entries: [
          {
            studentId: studentDocs[0]._id.toString(),
            studentEnrollmentId: studentEnrollmentsA[0]._id.toString(),
            studentName: 'Student 1',
            marks: 23,
            status: StudentMarkStatus.PRESENT,
          },
        ],
      });
    expect(editAllowedRes.status).toBe(200);

    // Faculty A CANNOT edit Student 1 (outside approved correction scope)
    const editBlockedRes = await request(app)
      .put(`/api/v1/assessments/${assessment._id}/draft`)
      .set('Authorization', authHeader(facultyAUser))
      .send({
        entries: [
          {
            studentId: studentDocs[1]._id.toString(),
            studentEnrollmentId: studentEnrollmentsA[1]._id.toString(),
            studentName: 'Student 2',
            marks: 18,
            status: StudentMarkStatus.PRESENT,
          },
        ],
      });
    expect(editBlockedRes.status).toBe(403);
    expect(getErrorMessage(editBlockedRes)).toContain('approved correction scope');
  });

  // 20. Corrected marks are audited
  test('20. Corrected marks are audited in AssessmentMark history and AuditLog', async () => {
    await InternalAssessment.findByIdAndUpdate(assessment._id, {
      status: AssessmentStatus.SUBMITTED,
      submittedAt: new Date(),
    });
    await AssessmentMark.create({
      collegeId: collegeA._id,
      assessmentId: assessment._id,
      facultyAssignmentId: facultyAssignmentA._id,
      subjectId: subjectIME._id,
      studentEnrollmentId: studentEnrollmentsA[0]._id,
      studentId: studentDocs[0]._id,
      studentName: 'Student 1',
      marks: 20,
      maximumMarks: 25,
      status: StudentMarkStatus.PRESENT,
      isLocked: true,
      sourceType: 'LIVE',
    });

    const reqRes = await request(app)
      .post(`/api/v1/assessments/${assessment._id}/corrections/request`)
      .set('Authorization', authHeader(facultyAUser))
      .send({
        studentEnrollmentId: studentEnrollmentsA[0]._id.toString(),
        reason: 'Recalculation Question 3',
        newMark: 23,
      });

    const requestId = reqRes.body.data.request._id;
    await request(app)
      .post(`/api/v1/assessments/corrections/${requestId}/respond`)
      .set('Authorization', authHeader(hodUser))
      .send({ action: 'APPROVE', message: 'Approved' });

    await request(app)
      .put(`/api/v1/assessments/${assessment._id}/draft`)
      .set('Authorization', authHeader(facultyAUser))
      .send({
        entries: [
          {
            studentId: studentDocs[0]._id.toString(),
            studentEnrollmentId: studentEnrollmentsA[0]._id.toString(),
            studentName: 'Student 1',
            marks: 23,
            status: StudentMarkStatus.PRESENT,
          },
        ],
      });

    const mark = await AssessmentMark.findOne({
      assessmentId: assessment._id,
      studentEnrollmentId: studentEnrollmentsA[0]._id,
    });

    expect(mark?.auditHistory).toBeDefined();
    expect(mark?.auditHistory?.length).toBeGreaterThan(0);
    const lastAudit = mark?.auditHistory?.[mark.auditHistory.length - 1];
    expect(lastAudit?.action).toBe('CORRECTION_APPLIED');
    expect(lastAudit?.previousMarks).toBe(20);
    expect(lastAudit?.newMarks).toBe(23);

    // Check AuditLog collection
    const auditLogs = await AuditLog.find({
      collegeId: collegeA._id.toString(),
      entityType: 'AssessmentMark',
      action: 'ASSESSMENT_MARK_CORRECTED',
    });
    expect(auditLogs.length).toBeGreaterThan(0);
    expect((auditLogs[0].previousValue as any)?.marks).toBe(20);
    expect((auditLogs[0].newValue as any)?.marks).toBe(23);
  });

  // 21. Corrected assessment can be resubmitted
  test('21. Corrected assessment can be resubmitted', async () => {
    const fullEntries = studentEnrollmentsA.map((se, i) => ({
      studentId: studentDocs[i]._id.toString(),
      studentEnrollmentId: se._id.toString(),
      studentName: `Student ${i + 1}`,
      marks: i === 0 ? 23 : 15,
      status: StudentMarkStatus.PRESENT,
    }));

    await request(app)
      .put(`/api/v1/assessments/${assessment._id}/draft`)
      .set('Authorization', authHeader(facultyAUser))
      .send({ entries: fullEntries });

    const res = await request(app)
      .post(`/api/v1/assessments/${assessment._id}/submit`)
      .set('Authorization', authHeader(facultyAUser))
      .send();

    expect(res.status).toBe(200);
    const updated = await InternalAssessment.findById(assessment._id);
    expect(updated?.status).toBe(AssessmentStatus.SUBMITTED);
  });

  // 22. Final relock prevents direct modification
  test('22. Final relock prevents direct modification', async () => {
    await AssessmentMark.create({
      collegeId: collegeA._id,
      assessmentId: assessment._id,
      facultyAssignmentId: facultyAssignmentA._id,
      subjectId: subjectIME._id,
      studentEnrollmentId: studentEnrollmentsA[0]._id,
      studentId: studentDocs[0]._id,
      studentName: 'Student 1',
      marks: 20,
      maximumMarks: 25,
      status: StudentMarkStatus.PRESENT,
      isLocked: false,
      sourceType: 'LIVE',
    });

    const lockRes = await request(app)
      .post(`/api/v1/assessments/${assessment._id}/lock`)
      .set('Authorization', authHeader(facultyAUser))
      .send();

    expect(lockRes.status).toBe(200);

    const checkAssessment = await InternalAssessment.findById(assessment._id);
    expect(checkAssessment?.status).toBe(AssessmentStatus.LOCKED);

    const allMarks = await AssessmentMark.find({ assessmentId: assessment._id });
    expect(allMarks.length).toBeGreaterThan(0);
    expect(allMarks.every((m) => m.isLocked)).toBe(true);

    // Any direct modification must be blocked
    const mutateRes = await request(app)
      .put(`/api/v1/assessments/${assessment._id}/draft`)
      .set('Authorization', authHeader(facultyAUser))
      .send({
        entries: [
          {
            studentId: studentDocs[0]._id.toString(),
            studentEnrollmentId: studentEnrollmentsA[0]._id.toString(),
            studentName: 'Student 1',
            marks: 25,
            status: StudentMarkStatus.PRESENT,
          },
        ],
      });

    expect(mutateRes.status).toBe(400);
    expect(getErrorMessage(mutateRes)).toContain('Assessment is locked');
  });

  // 23. Duplicate submission is safely handled
  test('23. Duplicate submission is safely handled', async () => {
    await InternalAssessment.findByIdAndUpdate(assessment._id, {
      status: AssessmentStatus.SUBMITTED,
      submittedAt: new Date(),
    });

    // Current status is already LOCKED / SUBMITTED
    const res = await request(app)
      .post(`/api/v1/assessments/${assessment._id}/submit`)
      .set('Authorization', authHeader(facultyAUser))
      .send();

    // Must return safe 200 with current state without erroring or corrupting
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.message).toContain('already been submitted');
  });

  // 24. College/tenant isolation remains enforced
  test('24. College/tenant isolation remains enforced', async () => {
    const facultyCollegeBUser = await User.create({
      collegeId: collegeB._id,
      email: 'fac_colb@colb.edu',
      password: 'password123',
      name: 'Prof. College B',
      role: AppRole.FACULTY,
    });

    // Faculty from College B tries to view College A's assessment roster
    const rosterRes = await request(app)
      .get(`/api/v1/assessments/${assessment._id}/roster`)
      .set('Authorization', authHeader(facultyCollegeBUser, collegeB._id.toString()));

    expect([403, 404]).toContain(rosterRes.status);

    // Faculty from College B tries to submit marks for College A's assessment
    const submitRes = await request(app)
      .post(`/api/v1/assessments/${assessment._id}/submit`)
      .set('Authorization', authHeader(facultyCollegeBUser, collegeB._id.toString()))
      .send();

    expect([403, 404]).toContain(submitRes.status);
  });
});
