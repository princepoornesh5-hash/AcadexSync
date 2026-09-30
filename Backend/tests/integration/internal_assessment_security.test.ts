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
  LabSubmissionStatus,
} from '../../src/models';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';
import { AppRole } from '../../src/constants/roles';

describe('PROMPT 30 — Internal Assessment Security, Data Protection & Workflow Tests', () => {
  let college: any;
  let department: any;
  let course: any;
  let academicYear: any;
  let semester: any;
  let section: any;
  let subjectTheory: any;
  let subjectLab: any;

  let facultyAUser: any;
  let facultyBUser: any;
  let facultyADoc: any;
  let facultyBDoc: any;

  let hodUser: any;
  let adminUser: any;
  let studentUser1: any;
  let studentUser2: any;
  let studentDoc1: any;
  let studentDoc2: any;

  function authHeader(user: any): string {
    return createTestAuthHeader({
      userId: user._id.toString(),
      collegeId: user.collegeId.toString(),
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

    // 1. Institution Setup
    college = await College.create({
      name: 'Acadex Engineering College',
      code: 'AEC',
      address: 'Main Campus',
      email: 'admin@aec.edu',
      phone: '9876543210',
      principal: 'Dr. Principal A',
    });

    department = await Department.create({
      collegeId: college._id,
      name: 'Computer Science & Engineering',
      code: 'CSE',
    });

    course = await Course.create({
      collegeId: college._id,
      departmentId: department._id,
      name: 'B.Tech Computer Science',
      code: 'CS101',
      duration: 4,
    });

    academicYear = await AcademicYear.create({
      collegeId: college._id,
      name: '2026-2027',
      startDate: new Date('2026-08-01'),
      endDate: new Date('2027-05-31'),
    });

    semester = await Semester.create({
      collegeId: college._id,
      departmentId: department._id,
      courseId: course._id,
      academicYearId: academicYear._id,
      name: 'Semester 5',
      number: 5,
    });

    section = await Section.create({
      collegeId: college._id,
      departmentId: department._id,
      courseId: course._id,
      academicYearId: academicYear._id,
      semesterId: semester._id,
      name: 'A',
      capacity: 60,
    });

    subjectTheory = await Subject.create({
      collegeId: college._id,
      departmentId: department._id,
      courseId: course._id,
      semesterId: semester._id,
      name: 'Database Management Systems',
      code: 'CS501',
      type: 'Theory',
      credits: 4,
    });

    subjectLab = await Subject.create({
      collegeId: college._id,
      departmentId: department._id,
      courseId: course._id,
      semesterId: semester._id,
      name: 'DBMS Laboratory',
      code: 'CS502',
      type: 'Practical',
      credits: 2,
    });

    // 2. Users Setup
    adminUser = await User.create({
      collegeId: college._id,
      instituteId: 'ADMIN-001',
      name: 'College Administrator',
      email: 'admin@aec.edu',
      role: AppRole.COLLEGE_ADMIN,
      password: 'Password123!',
      accountStatus: 'active',
      isActive: true,
    });

    hodUser = await User.create({
      collegeId: college._id,
      departmentId: department._id,
      instituteId: 'HOD-001',
      name: 'Dr. Alan HOD',
      email: 'hod.cse@aec.edu',
      role: AppRole.HOD,
      password: 'Password123!',
      accountStatus: 'active',
      isActive: true,
    });

    facultyAUser = await User.create({
      collegeId: college._id,
      departmentId: department._id,
      instituteId: 'FACA-001',
      name: 'Prof. Alice Turing',
      email: 'alice@aec.edu',
      role: AppRole.FACULTY,
      password: 'Password123!',
      accountStatus: 'active',
      isActive: true,
    });

    facultyBUser = await User.create({
      collegeId: college._id,
      departmentId: department._id,
      instituteId: 'FACB-001',
      name: 'Prof. Bob Hopper',
      email: 'bob@aec.edu',
      role: AppRole.FACULTY,
      password: 'Password123!',
      accountStatus: 'active',
      isActive: true,
    });

    facultyADoc = await Faculty.create({
      collegeId: college._id,
      departmentId: department._id,
      userId: facultyAUser._id,
      name: facultyAUser.name,
      email: facultyAUser.email,
      status: 'active',
      isActive: true,
    });

    facultyBDoc = await Faculty.create({
      collegeId: college._id,
      departmentId: department._id,
      userId: facultyBUser._id,
      name: facultyBUser.name,
      email: facultyBUser.email,
      status: 'active',
      isActive: true,
    });

    studentUser1 = await User.create({
      collegeId: college._id,
      departmentId: department._id,
      instituteId: 'STU-001',
      name: 'John Doe',
      email: 'john@aec.edu',
      role: AppRole.STUDENT,
      password: 'Password123!',
      accountStatus: 'active',
      isActive: true,
    });

    studentUser2 = await User.create({
      collegeId: college._id,
      departmentId: department._id,
      instituteId: 'STU-002',
      name: 'Jane Smith',
      email: 'jane@aec.edu',
      role: AppRole.STUDENT,
      password: 'Password123!',
      accountStatus: 'active',
      isActive: true,
    });

    studentDoc1 = await Student.create({
      collegeId: college._id,
      departmentId: department._id,
      userId: studentUser1._id,
      name: studentUser1.name,
      email: studentUser1.email,
      rollNumber: 'CS001',
      admissionNumber: 'ADM-2024-001',
      sectionId: section._id,
      semesterId: semester._id,
      status: 'active',
      isActive: true,
    });

    studentDoc2 = await Student.create({
      collegeId: college._id,
      departmentId: department._id,
      userId: studentUser2._id,
      name: studentUser2.name,
      email: studentUser2.email,
      rollNumber: 'CS002',
      admissionNumber: 'ADM-2024-002',
      sectionId: section._id,
      semesterId: semester._id,
      status: 'active',
      isActive: true,
    });

    // Student enrollments
    await StudentEnrollment.create({
      collegeId: college._id,
      studentId: studentDoc1._id,
      departmentId: department._id,
      courseId: course._id,
      academicYearId: new mongoose.Types.ObjectId(),
      semesterId: semester._id,
      sectionId: section._id,
      status: 'active',
    });

    await StudentEnrollment.create({
      collegeId: college._id,
      studentId: studentDoc2._id,
      departmentId: department._id,
      courseId: course._id,
      academicYearId: new mongoose.Types.ObjectId(),
      semesterId: semester._id,
      sectionId: section._id,
      status: 'active',
    });

    // 3. Faculty Assignments:
    // Faculty A teaches DBMS Theory (CS501) to Section A
    await FacultyAssignment.create({
      collegeId: college._id,
      departmentId: department._id,
      facultyId: facultyADoc._id,
      facultyName: facultyADoc.name,
      courseId: course._id,
      semesterId: semester._id,
      sectionId: section._id,
      subjectId: subjectTheory._id,
      academicYearId: new mongoose.Types.ObjectId(),
      isActive: true,
      assignedBy: adminUser._id.toString(),
    });

    // Faculty B teaches DBMS Lab (CS502) to Section A
    await FacultyAssignment.create({
      collegeId: college._id,
      departmentId: department._id,
      facultyId: facultyBDoc._id,
      facultyName: facultyBDoc.name,
      courseId: course._id,
      semesterId: semester._id,
      sectionId: section._id,
      subjectId: subjectLab._id,
      academicYearId: new mongoose.Types.ObjectId(),
      isActive: true,
      assignedBy: adminUser._id.toString(),
    });
  });

  describe('Security Scenario 1: Teaching Context Authorization & Cross-Faculty Rejection', () => {
    it('Faculty A can access assessment context for their assigned subject CS501', async () => {
      const res = await request(app)
        .get(`/api/v1/assessments/context?sectionId=${section._id}&subjectId=${subjectTheory._id}`)
        .set('Authorization', authHeader(facultyAUser));

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.subject.code).toBe('CS501');
      expect(res.body.data.components).toBeDefined();
      expect(res.body.data.components.length).toBeGreaterThan(0);
    });

    it('Faculty B is REJECTED with HTTP 403 when attempting to access/edit Faculty A teaching context', async () => {
      // Faculty B attempts to view or save marks for CS501 (owned by Faculty A)
      const resContext = await request(app)
        .get(`/api/v1/assessments/context?sectionId=${section._id}&subjectId=${subjectTheory._id}`)
        .set('Authorization', authHeader(facultyBUser));

      expect(resContext.status).toBe(403);
      expect(getErrorMessage(resContext)).toContain('You are not authorized to manage assessments for this teaching context.');

      // Faculty B attempts to save draft marks for CS501
      const resSave = await request(app)
        .post('/api/v1/assessments/draft')
        .set('Authorization', authHeader(facultyBUser))
        .send({
          sectionId: section._id.toString(),
          subjectId: subjectTheory._id.toString(),
          entries: [
            {
              studentId: studentDoc1._id.toString(),
              componentMarks: { test1: 20 },
            },
          ],
        });

      expect(resSave.status).toBe(403);
      expect(getErrorMessage(resSave)).toContain('You are not authorized to manage assessments for this teaching context.');
    });

    it('HOD and College Admin have institution oversight and can access context', async () => {
      const resHod = await request(app)
        .get(`/api/v1/assessments/context?sectionId=${section._id}&subjectId=${subjectTheory._id}`)
        .set('Authorization', authHeader(hodUser));

      expect(resHod.status).toBe(200);
      expect(resHod.body.success).toBe(true);

      const resAdmin = await request(app)
        .get(`/api/v1/assessments/context?sectionId=${section._id}&subjectId=${subjectTheory._id}`)
        .set('Authorization', authHeader(adminUser));

      expect(resAdmin.status).toBe(200);
      expect(resAdmin.body.success).toBe(true);
    });
  });

  describe('Security Scenario 2 & 3: Component Validation & Lifecycle Lock Protection', () => {
    it('Rejects negative marks or marks exceeding configured component maxMarks', async () => {
      // Try to enter 26 marks for a component with maxMarks 25
      const resOver = await request(app)
        .post('/api/v1/assessments/draft')
        .set('Authorization', authHeader(facultyAUser))
        .send({
          sectionId: section._id.toString(),
          subjectId: subjectTheory._id.toString(),
          entries: [
            {
              studentId: studentDoc1._id.toString(),
              componentMarks: { internalTest: 26 }, // Exceeds default max 20
            },
          ],
        });

      expect(resOver.status).toBe(400);
      expect(getErrorMessage(resOver)).toContain('cannot exceed maximum allowed');

      // Try to enter negative marks
      const resNegative = await request(app)
        .post('/api/v1/assessments/draft')
        .set('Authorization', authHeader(facultyAUser))
        .send({
          sectionId: section._id.toString(),
          subjectId: subjectTheory._id.toString(),
          entries: [
            {
              studentId: studentDoc1._id.toString(),
              componentMarks: { internalTest: -5 },
            },
          ],
        });

      expect(resNegative.status).toBe(400);
      expect(getErrorMessage(resNegative)).toContain('cannot be negative');
    });

    it('Faculty saves valid draft marks, marks as reviewed, and publishes/locks', async () => {
      // 1. Save Draft
      const resDraft = await request(app)
        .post('/api/v1/assessments/draft')
        .set('Authorization', authHeader(facultyAUser))
        .send({
          sectionId: section._id.toString(),
          subjectId: subjectTheory._id.toString(),
          entries: [
            {
              studentId: studentDoc1._id.toString(),
              componentMarks: { internalTest: 18, assignment: 9 },
            },
            {
              studentId: studentDoc2._id.toString(),
              componentMarks: { internalTest: 19, assignment: 10 },
            },
          ],
        });

      expect(resDraft.status).toBe(200);
      expect(resDraft.body.data.status).toBe(AssessmentStatus.DRAFT);
      expect(resDraft.body.data.entries[0].totalMarks).toBe(27);

      // 2. Review
      const resReview = await request(app)
        .post('/api/v1/assessments/review')
        .set('Authorization', authHeader(facultyAUser))
        .send({
          sectionId: section._id.toString(),
          subjectId: subjectTheory._id.toString(),
          comments: 'All answer sheets evaluated and verified',
        });

      expect(resReview.status).toBe(200);
      expect(resReview.body.data.status).toBe(AssessmentStatus.REVIEWED);

      // 3. Publish & Lock
      const resPublish = await request(app)
        .post('/api/v1/assessments/publish')
        .set('Authorization', authHeader(facultyAUser))
        .send({
          sectionId: section._id.toString(),
          subjectId: subjectTheory._id.toString(),
        });

      expect(resPublish.status).toBe(200);
      expect(resPublish.body.data.status).toBe(AssessmentStatus.PUBLISHED);
      expect(resPublish.body.data.lockedAt).toBeDefined();

      // 4. Attempt to modify published marks without unlocking must be REJECTED with HTTP 403
      const resEditAfterLock = await request(app)
        .post('/api/v1/assessments/draft')
        .set('Authorization', authHeader(facultyAUser))
        .send({
          sectionId: section._id.toString(),
          subjectId: subjectTheory._id.toString(),
          entries: [
            {
              studentId: studentDoc1._id.toString(),
              componentMarks: { internalTest: 20 },
            },
          ],
        });

      expect(resEditAfterLock.status).toBe(403);
      expect(getErrorMessage(resEditAfterLock)).toContain('Assessment marks have been published and locked. Contact your HOD or Administrator to unlock for revisions.');
    });

    it('HOD/Admin can unlock published marks with an audit reason', async () => {
      // First publish
      await InternalAssessment.create({
        collegeId: college._id,
        departmentId: department._id,
        courseId: course._id,
        academicYearId: new mongoose.Types.ObjectId(),
        semesterId: semester._id,
        sectionId: section._id,
        subjectId: subjectTheory._id,
        title: 'DBMS Assessment',
        components: [{ key: 'test1', name: 'Test 1', maxMarks: 25 }],
        entries: [{ studentId: studentDoc1._id, studentName: 'John', componentMarks: { test1: 20 }, totalMarks: 20 }],
        status: AssessmentStatus.PUBLISHED,
        lockedAt: new Date(),
      });

      // Faculty cannot unlock
      const resFacultyUnlock = await request(app)
        .post('/api/v1/assessments/unlock')
        .set('Authorization', authHeader(facultyAUser))
        .send({
          sectionId: section._id.toString(),
          subjectId: subjectTheory._id.toString(),
          reason: 'Correction required',
        });

      expect(resFacultyUnlock.status).toBe(403);

      // HOD unlocks with reason
      const resHodUnlock = await request(app)
        .post('/api/v1/assessments/unlock')
        .set('Authorization', authHeader(hodUser))
        .send({
          sectionId: section._id.toString(),
          subjectId: subjectTheory._id.toString(),
          reason: 'Authorized re-checking of question 3 for John Doe',
        });

      expect(resHodUnlock.status).toBe(200);
      expect(resHodUnlock.body.data.status).toBe(AssessmentStatus.DRAFT);
      expect(resHodUnlock.body.data.lockedAt).toBeUndefined();

      // Check audit log recorded the unlock reason
      const updatedAssessment = await InternalAssessment.findOne({ sectionId: section._id, subjectId: subjectTheory._id });
      const lastAudit = updatedAssessment!.auditLog[updatedAssessment!.auditLog.length - 1];
      expect(lastAudit.action).toBe('UNLOCKED');
      expect(lastAudit.details).toContain('Authorized re-checking of question 3');
    });
  });

  describe('Security Scenario 4: Student Mark Privacy & Visibility Control', () => {
    it('Students CANNOT see marks while in DRAFT or REVIEWED status', async () => {
      // Create draft assessment
      await InternalAssessment.create({
        collegeId: college._id,
        departmentId: department._id,
        courseId: course._id,
        academicYearId: new mongoose.Types.ObjectId(),
        semesterId: semester._id,
        sectionId: section._id,
        subjectId: subjectTheory._id,
        title: 'DBMS Draft Assessment',
        components: [{ key: 'test1', name: 'Test 1', maxMarks: 25, isStudentVisible: true }],
        entries: [
          { studentId: studentDoc1._id, studentName: 'John', componentMarks: { test1: 20 }, totalMarks: 20 },
          { studentId: studentDoc2._id, studentName: 'Jane', componentMarks: { test1: 24 }, totalMarks: 24 },
        ],
        status: AssessmentStatus.DRAFT,
      });

      // Student 1 queries context
      const res = await request(app)
        .get(`/api/v1/assessments/context?sectionId=${section._id}&subjectId=${subjectTheory._id}`)
        .set('Authorization', authHeader(studentUser1));

      expect(res.status).toBe(200);
      expect(res.body.data.isPublished).toBe(false);
      expect(res.body.data.entry).toBeNull();
      expect(res.body.data.message).toContain('not yet published');

      // Student 1 queries my-marks
      const resMyMarks = await request(app)
        .get('/api/v1/assessments/student/my-marks')
        .set('Authorization', authHeader(studentUser1));

      expect(resMyMarks.status).toBe(200);
      expect(resMyMarks.body.data.items).toHaveLength(0); // Unpublished assessment is omitted
    });

    it('When published, student ONLY sees their own score, NEVER other students scores', async () => {
      // Publish the assessment
      await InternalAssessment.create({
        collegeId: college._id,
        departmentId: department._id,
        courseId: course._id,
        academicYearId: new mongoose.Types.ObjectId(),
        semesterId: semester._id,
        sectionId: section._id,
        subjectId: subjectTheory._id,
        title: 'DBMS Published Assessment',
        components: [
          { key: 'test1', name: 'Test 1', maxMarks: 25, isStudentVisible: true },
          { key: 'internal_secret', name: 'Faculty Note', maxMarks: 5, isStudentVisible: false },
        ],
        entries: [
          { studentId: studentDoc1._id, studentName: 'John', componentMarks: { test1: 20, internal_secret: 3 }, totalMarks: 23 },
          { studentId: studentDoc2._id, studentName: 'Jane', componentMarks: { test1: 24, internal_secret: 5 }, totalMarks: 29 },
        ],
        status: AssessmentStatus.PUBLISHED,
        publishedAt: new Date(),
      });

      // Student 1 views context
      const res1 = await request(app)
        .get(`/api/v1/assessments/context?sectionId=${section._id}&subjectId=${subjectTheory._id}`)
        .set('Authorization', authHeader(studentUser1));

      expect(res1.status).toBe(200);
      expect(res1.body.data.isPublished).toBe(true);
      expect(res1.body.data.entry.studentName).toBe('John Doe');
      expect(res1.body.data.entry.marks.test1).toBe(20);
      // Student 1 cannot see Student 2 marks
      expect(JSON.stringify(res1.body.data)).not.toContain('Jane');
      expect(JSON.stringify(res1.body.data)).not.toContain('24');
      // Hidden components (isStudentVisible: false) are filtered out
      expect(res1.body.data.entry.marks.internal_secret).toBeUndefined();
      expect(res1.body.data.components.some((c: any) => c.key === 'internal_secret')).toBe(false);

      // Student 2 views context
      const res2 = await request(app)
        .get(`/api/v1/assessments/context?sectionId=${section._id}&subjectId=${subjectTheory._id}`)
        .set('Authorization', authHeader(studentUser2));

      expect(res2.status).toBe(200);
      expect(res2.body.data.isPublished).toBe(true);
      expect(res2.body.data.entry.studentName).toBe('Jane Smith');
      expect(res2.body.data.entry.marks.test1).toBe(24);
      expect(JSON.stringify(res2.body.data)).not.toContain('John');
    });
  });

  describe('Lab / Practical Observation, Record Verification & Sync', () => {
    it('Creates lab experiment, verifies student record book, and syncs into assessment', async () => {
      // 1. Faculty B creates Lab Experiment 1
      const resCreateExp = await request(app)
        .post('/api/v1/assessments/labs/experiments')
        .set('Authorization', authHeader(facultyBUser))
        .send({
          sectionId: section._id.toString(),
          subjectId: subjectLab._id.toString(),
          experimentNumber: 1,
          title: 'ER Diagram & Schema Design',
          maxMarks: { observation: 10, record: 10, viva: 5 },
        });

      expect(resCreateExp.status).toBe(201);
      const expId = resCreateExp.body.data._id;

      // 2. Faculty B verifies and grades Student 1 submission
      const resGrading = await request(app)
        .put(`/api/v1/assessments/labs/experiments/${expId}/submissions`)
        .set('Authorization', authHeader(facultyBUser))
        .send({
          updates: [
            {
              studentId: studentDoc1._id.toString(),
              status: LabSubmissionStatus.VERIFIED,
              observationMarks: 9,
              recordMarks: 10,
              vivaMarks: 4,
            },
          ],
        });

      expect(resGrading.status).toBe(200);
      const sub1 = resGrading.body.data.submissions.find((s: any) => s.studentId.toString() === studentDoc1._id.toString());
      expect(sub1.status).toBe(LabSubmissionStatus.VERIFIED);
      expect(sub1.totalMarks).toBe(23);

      // 3. Initialize assessment draft for subjectLab
      await request(app)
        .get(`/api/v1/assessments/context?sectionId=${section._id}&subjectId=${subjectLab._id}`)
        .set('Authorization', authHeader(facultyBUser));

      // 4. Sync Lab Scores into Internal Assessment
      const resSync = await request(app)
        .post('/api/v1/assessments/sync-lab')
        .set('Authorization', authHeader(facultyBUser))
        .send({
          sectionId: section._id.toString(),
          subjectId: subjectLab._id.toString(),
        });

      expect(resSync.status).toBe(200);
      expect(resSync.body.data.message).toContain('Successfully synchronized lab scores');

      // Verify assessment entry for Student 1 has synced lab and record scores
      const labAssessment = await InternalAssessment.findOne({ sectionId: section._id, subjectId: subjectLab._id });
      const entry1 = labAssessment!.entries.find((e) => e.studentId.toString() === studentDoc1._id.toString());
      expect(entry1?.componentMarks['lab']).toBe(9);
      expect(entry1?.componentMarks['record']).toBe(10);
      expect(entry1?.componentMarks['viva']).toBe(4);
    });
  });
});
