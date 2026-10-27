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
  Notification,
} from '../../src/models';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';
import { AppRole } from '../../src/constants/roles';

describe('ACADEX WORKSTREAM 3 — Common Assessments, Multi-Department Scope & Lifecycle Integration Tests', () => {
  let college: any;
  let deptCSE: any;
  let deptMECH: any;
  let deptCIVIL: any;

  let courseCSE: any;
  let courseMECH: any;
  let courseCIVIL: any;

  let academicYear: any;
  let sem3CSE: any;
  let sem3MECH: any;
  let sem3CIVIL: any;

  let secA_CSE: any;
  let secA_MECH: any;
  let secA_CIVIL: any;

  let subjectMath: any;
  let room101: any;
  let room102: any;

  // Multi-department Mathematics Teacher
  let mathTeacherUser: any;
  let mathTeacherDoc: any;
  let faCSE: any;
  let faMECH: any;
  let faCIVIL: any;

  // HOD CSE
  let hodCSEUser: any;

  // Single-department Teacher (Civil only)
  let civilTeacherUser: any;
  let civilTeacherDoc: any;
  let faCivilOnly: any;

  // Students in CSE, MECH, CIVIL
  let student1_CSE: any;
  let student3_MECH: any;
  // Student enrolled in both CSE and a dual elective
  let dualEnrolledStudent: any;

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

    college = await College.create({
      name: 'Acadex Institute of Technology',
      code: 'AIT',
      address: 'Campus A, Tech Park',
      email: 'admin@ait.edu',
      phone: '9000000000',
      principal: 'Dr. Principal',
    });

    deptCSE = await Department.create({
      collegeId: college._id,
      name: 'Computer Science & Engineering',
      code: 'CSE',
    });
    deptMECH = await Department.create({
      collegeId: college._id,
      name: 'Mechanical Engineering',
      code: 'MECH',
    });
    deptCIVIL = await Department.create({
      collegeId: college._id,
      name: 'Civil Engineering',
      code: 'CIVIL',
    });

    courseCSE = await Course.create({
      collegeId: college._id,
      departmentId: deptCSE._id,
      name: 'B.Tech CSE',
      code: 'BTCSE',
      durationYears: 4,
    });
    courseMECH = await Course.create({
      collegeId: college._id,
      departmentId: deptMECH._id,
      name: 'B.Tech MECH',
      code: 'BTMECH',
      durationYears: 4,
    });
    courseCIVIL = await Course.create({
      collegeId: college._id,
      departmentId: deptCIVIL._id,
      name: 'B.Tech CIVIL',
      code: 'BTCIVIL',
      durationYears: 4,
    });

    academicYear = await AcademicYear.create({
      collegeId: college._id,
      name: '2026-2027',
      startDate: new Date('2026-08-01'),
      endDate: new Date('2027-05-31'),
    });

    sem3CSE = await Semester.create({
      collegeId: college._id,
      departmentId: deptCSE._id,
      courseId: courseCSE._id,
      name: 'Semester 3',
      number: 3,
      academicYearId: academicYear._id,
      status: 'active',
    });
    sem3MECH = await Semester.create({
      collegeId: college._id,
      departmentId: deptMECH._id,
      courseId: courseMECH._id,
      name: 'Semester 3',
      number: 3,
      academicYearId: academicYear._id,
      status: 'active',
    });
    sem3CIVIL = await Semester.create({
      collegeId: college._id,
      departmentId: deptCIVIL._id,
      courseId: courseCIVIL._id,
      name: 'Semester 3',
      number: 3,
      academicYearId: academicYear._id,
      status: 'active',
    });

    secA_CSE = await Section.create({
      collegeId: college._id,
      departmentId: deptCSE._id,
      courseId: courseCSE._id,
      academicYearId: academicYear._id,
      semesterId: sem3CSE._id,
      name: 'Section A',
      capacity: 60,
    });
    secA_MECH = await Section.create({
      collegeId: college._id,
      departmentId: deptMECH._id,
      courseId: courseMECH._id,
      academicYearId: academicYear._id,
      semesterId: sem3MECH._id,
      name: 'Section A',
      capacity: 60,
    });
    secA_CIVIL = await Section.create({
      collegeId: college._id,
      departmentId: deptCIVIL._id,
      courseId: courseCIVIL._id,
      academicYearId: academicYear._id,
      semesterId: sem3CIVIL._id,
      name: 'Section A',
      capacity: 60,
    });

    subjectMath = await Subject.create({
      collegeId: college._id,
      departmentId: deptCSE._id,
      courseId: courseCSE._id,
      semesterId: sem3CSE._id,
      name: 'Engineering Mathematics III',
      code: 'MATH301',
      credits: 4,
      type: 'THEORY',
    });

    room101 = await Room.create({
      collegeId: college._id,
      name: 'Auditorium Hall 101',
      code: 'AUD-101',
      capacity: 200,
    });
    room102 = await Room.create({
      collegeId: college._id,
      name: 'Seminar Hall 102',
      code: 'SEM-102',
      capacity: 100,
    });

    // 1. Math Teacher assigned across all 3 departments
    mathTeacherUser = await User.create({
      collegeId: college._id,
      departmentId: deptCSE._id,
      name: 'Prof. Ramanujan',
      email: 'ramanujan@ait.edu',
      role: AppRole.FACULTY,
      isActive: true,
    });
    mathTeacherDoc = await Faculty.create({
      collegeId: college._id,
      departmentId: deptCSE._id,
      userId: mathTeacherUser._id,
      name: mathTeacherUser.name,
      email: mathTeacherUser.email,
      isActive: true,
    });

    faCSE = await FacultyAssignment.create({
      collegeId: college._id,
      departmentId: deptCSE._id,
      facultyId: mathTeacherDoc._id,
      facultyName: mathTeacherDoc.name,
      courseId: courseCSE._id,
      semesterId: sem3CSE._id,
      sectionId: secA_CSE._id,
      subjectId: subjectMath._id,
      academicYearId: academicYear._id,
      isActive: true,
      assignedBy: mathTeacherUser._id.toString(),
    });

    faMECH = await FacultyAssignment.create({
      collegeId: college._id,
      departmentId: deptMECH._id,
      facultyId: mathTeacherDoc._id,
      facultyName: mathTeacherDoc.name,
      courseId: courseMECH._id,
      semesterId: sem3MECH._id,
      sectionId: secA_MECH._id,
      subjectId: subjectMath._id,
      academicYearId: academicYear._id,
      isActive: true,
      assignedBy: mathTeacherUser._id.toString(),
    });

    faCIVIL = await FacultyAssignment.create({
      collegeId: college._id,
      departmentId: deptCIVIL._id,
      facultyId: mathTeacherDoc._id,
      facultyName: mathTeacherDoc.name,
      courseId: courseCIVIL._id,
      semesterId: sem3CIVIL._id,
      sectionId: secA_CIVIL._id,
      subjectId: subjectMath._id,
      academicYearId: academicYear._id,
      isActive: true,
      assignedBy: mathTeacherUser._id.toString(),
    });

    // 2. HOD CSE
    hodCSEUser = await User.create({
      collegeId: college._id,
      departmentId: deptCSE._id,
      name: 'Dr. Turing (HOD CSE)',
      email: 'turing.hod@ait.edu',
      role: AppRole.HOD,
      isActive: true,
    });

    // 3. Civil-only Teacher
    civilTeacherUser = await User.create({
      collegeId: college._id,
      departmentId: deptCIVIL._id,
      name: 'Prof. Visvesvaraya',
      email: 'visvesvaraya@ait.edu',
      role: AppRole.FACULTY,
      isActive: true,
    });
    civilTeacherDoc = await Faculty.create({
      collegeId: college._id,
      departmentId: deptCIVIL._id,
      userId: civilTeacherUser._id,
      name: civilTeacherUser.name,
      email: civilTeacherUser.email,
      isActive: true,
    });
    faCivilOnly = await FacultyAssignment.create({
      collegeId: college._id,
      departmentId: deptCIVIL._id,
      facultyId: civilTeacherDoc._id,
      facultyName: civilTeacherDoc.name,
      courseId: courseCIVIL._id,
      semesterId: sem3CIVIL._id,
      sectionId: secA_CIVIL._id,
      subjectId: subjectMath._id,
      academicYearId: academicYear._id,
      isActive: true,
      assignedBy: civilTeacherUser._id.toString(),
    });

    // 4. Create Students & Enrollments
    const createStudentAndEnroll = async (name: string, email: string, roll: string, dept: any, course: any, sem: any, sec: any) => {
      const u = await User.create({
        collegeId: college._id,
        departmentId: dept._id,
        name,
        email,
        role: AppRole.STUDENT,
        isActive: true,
      });
      const s = await Student.create({
        collegeId: college._id,
        departmentId: dept._id,
        userId: u._id,
        name: u.name,
        email: u.email,
        rollNumber: roll,
        admissionNumber: `ADM-${roll}`,
        sectionId: sec._id,
        semesterId: sem._id,
        isActive: true,
      });
      const e = await StudentEnrollment.create({
        collegeId: college._id,
        studentId: s._id,
        departmentId: dept._id,
        courseId: course._id,
        academicYearId: academicYear._id,
        semesterId: sem._id,
        sectionId: sec._id,
        status: 'active',
      });
      return { user: u, student: s, enrollment: e };
    };

    student1_CSE = await createStudentAndEnroll('Alice CSE', 'alice@ait.edu', 'CS301', deptCSE, courseCSE, sem3CSE, secA_CSE);
    await createStudentAndEnroll('Bob CSE', 'bob@ait.edu', 'CS302', deptCSE, courseCSE, sem3CSE, secA_CSE);
    student3_MECH = await createStudentAndEnroll('Charlie MECH', 'charlie@ait.edu', 'ME301', deptMECH, courseMECH, sem3MECH, secA_MECH);
    await createStudentAndEnroll('Diana CIVIL', 'diana@ait.edu', 'CE301', deptCIVIL, courseCIVIL, sem3CIVIL, secA_CIVIL);

    // Dual enrolled student (e.g. transferred or dual-programme student enrolled in both MECH and CIVIL)
    const dualUser = await User.create({
      collegeId: college._id,
      departmentId: deptMECH._id,
      name: 'Evan Dual',
      email: 'evan@ait.edu',
      role: AppRole.STUDENT,
      isActive: true,
    });
    const dualDoc = await Student.create({
      collegeId: college._id,
      departmentId: deptMECH._id,
      userId: dualUser._id,
      name: dualUser.name,
      email: dualUser.email,
      rollNumber: 'DUAL01',
      admissionNumber: 'ADM-DUAL01',
      sectionId: secA_MECH._id,
      semesterId: sem3MECH._id,
      isActive: true,
    });
    await StudentEnrollment.create({
      collegeId: college._id,
      studentId: dualDoc._id,
      departmentId: deptMECH._id,
      courseId: courseMECH._id,
      academicYearId: academicYear._id,
      semesterId: sem3MECH._id,
      sectionId: secA_MECH._id,
      status: 'active',
    });
    await StudentEnrollment.create({
      collegeId: college._id,
      studentId: dualDoc._id,
      departmentId: deptCIVIL._id,
      courseId: courseCIVIL._id,
      academicYearId: academicYear._id,
      semesterId: sem3CIVIL._id,
      sectionId: secA_CIVIL._id,
      status: 'active',
    });
    dualEnrolledStudent = { user: dualUser, student: dualDoc };
  });

  describe('1. Scope Preview & Authorization Validation', () => {
    it('1.1 Previews multi-department scope and deduplicates dual-enrolled students accurately', async () => {
      const authHeader = createTestAuthHeader({
        userId: mathTeacherUser._id.toString(),
        role: AppRole.FACULTY,
        collegeId: college._id.toString(),
      });

      const res = await request(app)
        .post('/api/v1/assessments/preview-scope')
        .set(authHeader)
        .send({
          subjectId: subjectMath._id.toString(),
          academicScopes: [
            {
              departmentId: deptCSE._id.toString(),
              courseId: courseCSE._id.toString(),
              academicYearId: academicYear._id.toString(),
              semesterId: sem3CSE._id.toString(),
              sectionId: secA_CSE._id.toString(),
              facultyAssignmentId: faCSE._id.toString(),
            },
            {
              departmentId: deptMECH._id.toString(),
              courseId: courseMECH._id.toString(),
              academicYearId: academicYear._id.toString(),
              semesterId: sem3MECH._id.toString(),
              sectionId: secA_MECH._id.toString(),
              facultyAssignmentId: faMECH._id.toString(),
            },
            {
              departmentId: deptCIVIL._id.toString(),
              courseId: courseCIVIL._id.toString(),
              academicYearId: academicYear._id.toString(),
              semesterId: sem3CIVIL._id.toString(),
              sectionId: secA_CIVIL._id.toString(),
              facultyAssignmentId: faCIVIL._id.toString(),
            },
          ],
        });

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      expect(res.body.data.authorizedScopes.length).toBe(3);
      // Total enrollments: 2 (CSE) + 2 (MECH: Charlie + Evan) + 2 (CIVIL: Diana + Evan) = 6
      // Evan is dual-enrolled in MECH and CIVIL -> 5 unique students!
      expect(res.body.data.totalEligibleStudents).toBe(5);
      expect(res.body.data.duplicateStudentCount).toBe(1);
      expect(res.body.data.studentsPreview.length).toBe(5);
    });

    it('1.2 Rejects scope preview if faculty tries to include an unassigned department', async () => {
      // Civil teacher attempts to create an exam that includes CSE
      const authHeader = createTestAuthHeader({
        userId: civilTeacherUser._id.toString(),
        role: AppRole.FACULTY,
        collegeId: college._id.toString(),
      });

      const res = await request(app)
        .post('/api/v1/assessments/preview-scope')
        .set(authHeader)
        .send({
          subjectId: subjectMath._id.toString(),
          academicScopes: [
            {
              departmentId: deptCIVIL._id.toString(),
              courseId: courseCIVIL._id.toString(),
              academicYearId: academicYear._id.toString(),
              semesterId: sem3CIVIL._id.toString(),
              sectionId: secA_CIVIL._id.toString(),
              facultyAssignmentId: faCivilOnly._id.toString(),
            },
            {
              departmentId: deptCSE._id.toString(),
              courseId: courseCSE._id.toString(),
              academicYearId: academicYear._id.toString(),
              semesterId: sem3CSE._id.toString(),
              sectionId: secA_CSE._id.toString(),
              // NOT assigned to Civil teacher
            },
          ],
        });

      expect(res.status).toBe(403);
      expect(getErrorMessage(res)).toContain('not authorized');
    });

    it('1.3 HOD CSE cannot create common assessment across MECH or CIVIL without authorization', async () => {
      const authHeader = createTestAuthHeader({
        userId: hodCSEUser._id.toString(),
        role: AppRole.HOD,
        collegeId: college._id.toString(),
        departmentId: deptCSE._id.toString(),
      });

      const res = await request(app)
        .post('/api/v1/assessments/preview-scope')
        .set(authHeader)
        .send({
          subjectId: subjectMath._id.toString(),
          academicScopes: [
            {
              departmentId: deptCSE._id.toString(),
              courseId: courseCSE._id.toString(),
              academicYearId: academicYear._id.toString(),
              semesterId: sem3CSE._id.toString(),
              sectionId: secA_CSE._id.toString(),
            },
            {
              departmentId: deptMECH._id.toString(),
              courseId: courseMECH._id.toString(),
              academicYearId: academicYear._id.toString(),
              semesterId: sem3MECH._id.toString(),
              sectionId: secA_MECH._id.toString(),
            },
          ],
        });

      expect(res.status).toBe(403);
      expect(getErrorMessage(res)).toContain('outside your department');
    });
  });

  describe('2. Multi-Department Common Assessment Creation', () => {
    it('2.1 Creates one common assessment linking all 3 departments with deduplicated student rosters', async () => {
      const authHeader = createTestAuthHeader({
        userId: mathTeacherUser._id.toString(),
        role: AppRole.FACULTY,
        collegeId: college._id.toString(),
      });

      const res = await request(app)
        .post('/api/v1/assessments')
        .set(authHeader)
        .send({
          subjectId: subjectMath._id.toString(),
          title: 'Mathematics Common Unit Test 1',
          assessmentType: AssessmentType.UNIT_TEST,
          maximumMarks: 50,
          passMarks: 20,
          academicScopes: [
            {
              departmentId: deptCSE._id.toString(),
              courseId: courseCSE._id.toString(),
              academicYearId: academicYear._id.toString(),
              semesterId: sem3CSE._id.toString(),
              sectionId: secA_CSE._id.toString(),
              facultyAssignmentId: faCSE._id.toString(),
            },
            {
              departmentId: deptMECH._id.toString(),
              courseId: courseMECH._id.toString(),
              academicYearId: academicYear._id.toString(),
              semesterId: sem3MECH._id.toString(),
              sectionId: secA_MECH._id.toString(),
              facultyAssignmentId: faMECH._id.toString(),
            },
            {
              departmentId: deptCIVIL._id.toString(),
              courseId: courseCIVIL._id.toString(),
              academicYearId: academicYear._id.toString(),
              semesterId: sem3CIVIL._id.toString(),
              sectionId: secA_CIVIL._id.toString(),
              facultyAssignmentId: faCIVIL._id.toString(),
            },
          ],
        });

      expect(res.status).toBe(201);
      const assessment = res.body.data;
      expect(assessment.isCommonExam).toBe(true);
      expect(assessment.academicScopes.length).toBe(3);
      expect(assessment.entries.length).toBe(5); // Deduplicated 5 unique students!

      // Verify canonical AssessmentMark documents created in database
      const marks = await AssessmentMark.find({ assessmentId: assessment.id });
      expect(marks.length).toBe(5);

      // Verify Evan Dual has exactly one mark document, not two
      const evanMarks = marks.filter((m) => m.studentId.toString() === dualEnrolledStudent.student._id.toString());
      expect(evanMarks.length).toBe(1);
    });
  });

  describe('3. Schedule Conflict Checking across Multi-Department Scopes', () => {
    let createdAssessment: any;

    beforeEach(async () => {
      createdAssessment = await InternalAssessment.create({
        collegeId: college._id,
        departmentId: deptCSE._id,
        courseId: courseCSE._id,
        academicYearId: academicYear._id,
        semesterId: sem3CSE._id,
        sectionId: secA_CSE._id,
        subjectId: subjectMath._id,
        facultyAssignmentId: faCSE._id,
        facultyId: mathTeacherDoc._id,
        facultyName: mathTeacherDoc.name,
        academicScopes: [
          {
            departmentId: deptCSE._id,
            courseId: courseCSE._id,
            academicYearId: academicYear._id,
            semesterId: sem3CSE._id,
            sectionId: secA_CSE._id,
          },
          {
            departmentId: deptMECH._id,
            courseId: courseMECH._id,
            academicYearId: academicYear._id,
            semesterId: sem3MECH._id,
            sectionId: secA_MECH._id,
          },
          {
            departmentId: deptCIVIL._id,
            courseId: courseCIVIL._id,
            academicYearId: academicYear._id,
            semesterId: sem3CIVIL._id,
            sectionId: secA_CIVIL._id,
          },
        ],
        isCommonExam: true,
        title: 'Mathematics Midterm Common',
        assessmentType: AssessmentType.MID_TERM,
        maximumMarks: 100,
        passMarks: 40,
        entries: [],
        status: AssessmentStatus.DRAFT,
        createdBy: mathTeacherUser._id,
      });
    });

    it('3.1 Detects and returns detailed conflict when room is already booked', async () => {
      // Create an existing schedule in Room 101 on 2026-11-15 from 10:00 to 12:00
      await AssessmentSchedule.create({
        collegeId: college._id,
        assessmentId: new mongoose.Types.ObjectId(),
        facultyAssignmentId: faCSE._id,
        departmentId: deptCSE._id,
        courseId: courseCSE._id,
        academicYearId: academicYear._id,
        semesterId: sem3CSE._id,
        sectionId: secA_CSE._id,
        subjectId: subjectMath._id,
        date: new Date('2026-11-15'),
        dateString: '2026-11-15',
        startTime: '10:00',
        endTime: '12:00',
        roomId: room101._id,
        status: 'SCHEDULED',
      });

      const authHeader = createTestAuthHeader({
        userId: mathTeacherUser._id.toString(),
        role: AppRole.FACULTY,
        collegeId: college._id.toString(),
      });

      const res = await request(app)
        .post('/api/v1/assessments/check-conflicts')
        .set(authHeader)
        .send({
          date: '2026-11-15',
          startTime: '11:00',
          endTime: '13:00',
          roomId: room101._id.toString(),
          targetSectionIds: [secA_CSE._id.toString(), secA_MECH._id.toString()],
        });

      expect(res.status).toBe(200);
      expect(res.body.data.hasConflicts).toBe(true);
      expect(res.body.data.conflicts.some((c: any) => c.type === 'ROOM')).toBe(true);
    });

    it('3.2 Rejects scheduleAssessment when any target section has an overlapping exam', async () => {
      // Existing exam for Mechanical Section A on 2026-11-20 09:00 - 11:00
      await AssessmentSchedule.create({
        collegeId: college._id,
        assessmentId: new mongoose.Types.ObjectId(),
        facultyAssignmentId: faMECH._id,
        departmentId: deptMECH._id,
        courseId: courseMECH._id,
        academicYearId: academicYear._id,
        semesterId: sem3MECH._id,
        sectionId: secA_MECH._id,
        subjectId: subjectMath._id,
        date: new Date('2026-11-20'),
        dateString: '2026-11-20',
        startTime: '09:00',
        endTime: '11:00',
        roomId: room102._id,
        status: 'SCHEDULED',
      });

      const authHeader = createTestAuthHeader({
        userId: mathTeacherUser._id.toString(),
        role: AppRole.FACULTY,
        collegeId: college._id.toString(),
      });

      // Scheduling the common exam at 10:00 - 12:00 overlaps with MECH Section A!
      const res = await request(app)
        .post(`/api/v1/assessments/${createdAssessment._id}/schedule`)
        .set(authHeader)
        .send({
          date: '2026-11-20',
          startTime: '10:00',
          endTime: '12:00',
          roomId: room101._id.toString(),
          instructions: 'Common exam instructions',
        });

      expect(res.status).toBe(409);
      expect(getErrorMessage(res)).toContain('already has another assessment scheduled');
    });

    it('3.3 Successfully schedules and publishes exam with targeted student notifications', async () => {
      // Populate student entries on assessment
      createdAssessment.entries = [
        {
          studentId: student1_CSE.student._id,
          studentName: student1_CSE.student.name,
          rollNumber: student1_CSE.student.rollNumber,
          componentMarks: {},
          totalMarks: 0,
          status: StudentMarkStatus.NOT_ENTERED,
        },
        {
          studentId: student3_MECH.student._id,
          studentName: student3_MECH.student.name,
          rollNumber: student3_MECH.student.rollNumber,
          componentMarks: {},
          totalMarks: 0,
          status: StudentMarkStatus.NOT_ENTERED,
        },
      ];
      await createdAssessment.save();

      const authHeader = createTestAuthHeader({
        userId: mathTeacherUser._id.toString(),
        role: AppRole.FACULTY,
        collegeId: college._id.toString(),
      });

      // 1. Schedule exam
      const resSchedule = await request(app)
        .post(`/api/v1/assessments/${createdAssessment._id}/schedule`)
        .set(authHeader)
        .send({
          date: '2026-11-25',
          startTime: '10:00',
          endTime: '12:00',
          roomId: room101._id.toString(),
          instructions: 'Bring non-programmable calculators',
        });

      expect(resSchedule.status).toBe(200);

      // 2. Publish exam to students
      const resPublish = await request(app)
        .post(`/api/v1/assessments/${createdAssessment._id}/publish-exam`)
        .set(authHeader)
        .send();

      expect(resPublish.status).toBe(200);
      expect(resPublish.body.data.isPublishedToStudents).toBe(true);
      expect(resPublish.body.data.status).toBe(AssessmentStatus.SCHEDULED);

      // 3. Verify targeted notifications created for enrolled students
      const notifications = await Notification.find({
        collegeId: college._id,
        recipientUserId: { $in: [student1_CSE.user._id, student3_MECH.user._id] },
      });
      expect(notifications.length).toBe(2);
      expect(notifications[0].title).toContain('Exam Scheduled');
      expect(notifications[0].deepLink).toBe('/assessments');
    });
  });

  describe('4. Student Assessment Experience & Isolation', () => {
    it('4.1 Student sees their scheduled exam but CANNOT see un-published marks or drafts', async () => {
      // 1. Draft assessment
      const draftExam = await InternalAssessment.create({
        collegeId: college._id,
        departmentId: deptCSE._id,
        courseId: courseCSE._id,
        academicYearId: academicYear._id,
        semesterId: sem3CSE._id,
        sectionId: secA_CSE._id,
        subjectId: subjectMath._id,
        title: 'Secret Draft Exam',
        maximumMarks: 50,
        status: AssessmentStatus.DRAFT,
        entries: [{ studentId: student1_CSE.student._id, studentName: 'Alice', componentMarks: {}, totalMarks: 0 }],
      });

      const studentAuthHeader = createTestAuthHeader({
        userId: student1_CSE.user._id.toString(),
        role: AppRole.STUDENT,
        collegeId: college._id.toString(),
      });

      // Student tries to access draft directly -> 403 Forbidden!
      const resDraft = await request(app)
        .get(`/api/v1/assessments/${draftExam._id}`)
        .set(studentAuthHeader);

      expect(resDraft.status).toBe(403);
      expect(getErrorMessage(resDraft)).toContain('draft');

      // Student listing assessments: draft does NOT appear
      const resList = await request(app)
        .get('/api/v1/assessments')
        .set(studentAuthHeader);

      expect(resList.status).toBe(200);
      const ids = resList.body.data.map((a: any) => a.id);
      expect(ids).not.toContain(draftExam._id.toString());
    });
  });
});
