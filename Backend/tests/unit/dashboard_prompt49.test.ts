import mongoose, { Types } from 'mongoose';
import { MongoMemoryServer } from 'mongodb-memory-server';
import {
  User,
  Student,
  Faculty,
  StudentEnrollment,
  FacultyAssignment,
  Department,
  College,
  Course,
  Semester,
  AcademicYear,
  Section,
  Subject,
} from '../../src/models';
import { AttendanceSession } from '../../src/models/attendanceSession.model';
import { AttendanceRecord } from '../../src/models/attendanceRecord.model';
import { Assignment } from '../../src/models/assignment.model';
import { AssignmentSubmission } from '../../src/models/assignmentSubmission.model';
import { InternalAssessment, AssessmentStatus } from '../../src/models/internalAssessment.model';
import { AcademicResult } from '../../src/models/academicResult.model';
import { ResultLifecycleStatus, OverallResultStatus } from '../../src/constants/academicResult.constants';
import { RequestModel } from '../../src/models/request.model';
import { RequestStatus } from '../../src/constants/request.constants';
import { AssignmentType } from '../../src/constants/assignment.constants';
import {
  AudienceScope,
  AnnouncementStatus,
  NotificationType,
} from '../../src/constants/notification.constants';
import { Announcement } from '../../src/models/announcement.model';
import { Notification } from '../../src/models/notification.model';
import { AppRole } from '../../src/constants/roles';
import { AccountStatus, CollegeStatus, AttendanceSessionStatus, AttendanceStatus } from '../../src/constants/status';
import { DashboardService } from '../../src/services/dashboard.service';
import { AuthenticatedUser } from '../../src/types/auth.types';

describe('PROMPT 49 — Role-Aware Home Dashboard & Daily Action Center Tests', () => {
  let mongoServer: MongoMemoryServer;

  // Colleges & Departments
  let collegeAId: Types.ObjectId;
  let collegeBId: Types.ObjectId;
  let deptAId: Types.ObjectId;
  let deptBId: Types.ObjectId;

  // Academic Structure
  let courseAId: Types.ObjectId;
  let academicYearAId: Types.ObjectId;
  let semesterAId: Types.ObjectId;
  let sectionAId: Types.ObjectId;
  let subjectAId: Types.ObjectId;

  // Users
  let student1UserId: Types.ObjectId;
  let student1ProfileId: Types.ObjectId;
  let student2UserId: Types.ObjectId;
  let student2ProfileId: Types.ObjectId;

  let faculty1UserId: Types.ObjectId;
  let faculty1ProfileId: Types.ObjectId;
  let faculty2UserId: Types.ObjectId;
  let faculty2ProfileId: Types.ObjectId;

  let hodAUserId: Types.ObjectId;
  let hodBUserId: Types.ObjectId;
  let adminAUserId: Types.ObjectId;
  let superAdminUserId: Types.ObjectId;

  // Auth Contexts
  let authStudent1: AuthenticatedUser;
  let authStudent2: AuthenticatedUser;
  let authFaculty1: AuthenticatedUser;
  let authFaculty2: AuthenticatedUser;
  let authHodA: AuthenticatedUser;
  let authHodB: AuthenticatedUser;
  let authAdminA: AuthenticatedUser;
  let authSuperAdmin: AuthenticatedUser;

  beforeAll(async () => {
    mongoServer = await MongoMemoryServer.create();
    await mongoose.connect(mongoServer.getUri());

    collegeAId = new Types.ObjectId();
    collegeBId = new Types.ObjectId();
    deptAId = new Types.ObjectId();
    deptBId = new Types.ObjectId();

    courseAId = new Types.ObjectId();
    academicYearAId = new Types.ObjectId();
    semesterAId = new Types.ObjectId();
    sectionAId = new Types.ObjectId();
    subjectAId = new Types.ObjectId();

    student1UserId = new Types.ObjectId();
    student1ProfileId = new Types.ObjectId();
    student2UserId = new Types.ObjectId();
    student2ProfileId = new Types.ObjectId();

    faculty1UserId = new Types.ObjectId();
    faculty1ProfileId = new Types.ObjectId();
    faculty2UserId = new Types.ObjectId();
    faculty2ProfileId = new Types.ObjectId();

    hodAUserId = new Types.ObjectId();
    hodBUserId = new Types.ObjectId();
    adminAUserId = new Types.ObjectId();
    superAdminUserId = new Types.ObjectId();

    // 1. Seed Colleges
    await College.create([
      {
        _id: collegeAId,
        name: 'Apex Institute of Technology',
        code: 'AIT',
        principal: 'Dr. Apex',
        phone: '1234567890',
        email: 'info@ait.edu',
        address: '1 Tech Park',
        status: CollegeStatus.ACTIVE,
      },
      {
        _id: collegeBId,
        name: 'Beacon College of Engineering',
        code: 'BCE',
        principal: 'Dr. Beacon',
        phone: '9876543210',
        email: 'info@bce.edu',
        address: '2 Science Blvd',
        status: CollegeStatus.ACTIVE,
      },
    ]);

    // 2. Seed Departments
    await Department.create([
      {
        _id: deptAId,
        collegeId: collegeAId,
        name: 'Computer Science and Engineering',
        code: 'CSE',
      },
      {
        _id: deptBId,
        collegeId: collegeBId,
        name: 'Mechanical Engineering',
        code: 'MECH',
      },
    ]);

    // 3. Seed Course, Semester, AcademicYear, Section, Subject
    await AcademicYear.create({
      _id: academicYearAId,
      collegeId: collegeAId,
      name: '2025-2026',
      startDate: new Date('2025-06-01'),
      endDate: new Date('2026-05-31'),
    });

    await Course.create({
      _id: courseAId,
      collegeId: collegeAId,
      departmentId: deptAId,
      name: 'Bachelor of Technology in CS',
      code: 'BTECH_CS',
    });

    await Semester.create({
      _id: semesterAId,
      collegeId: collegeAId,
      departmentId: deptAId,
      courseId: courseAId,
      academicYearId: academicYearAId,
      name: 'Semester 4',
      number: 4,
    });

    await Section.create({
      _id: sectionAId,
      collegeId: collegeAId,
      departmentId: deptAId,
      courseId: courseAId,
      semesterId: semesterAId,
      name: 'Section A',
      capacity: 60,
    });

    await Subject.create({
      _id: subjectAId,
      collegeId: collegeAId,
      departmentId: deptAId,
      courseId: courseAId,
      semesterId: semesterAId,
      name: 'Data Structures & Algorithms',
      code: 'CS201',
    });

    // 4. Seed Users
    await User.create([
      {
        _id: student1UserId,
        email: 'student1@ait.edu',
        name: 'Student One',
        role: AppRole.STUDENT,
        collegeId: collegeAId,
        isActive: true,
      },
      {
        _id: student2UserId,
        email: 'student2@ait.edu',
        name: 'Student Two',
        role: AppRole.STUDENT,
        collegeId: collegeAId,
        isActive: true,
      },
      {
        _id: faculty1UserId,
        email: 'faculty1@ait.edu',
        name: 'Prof. Alice Smith',
        role: AppRole.FACULTY,
        collegeId: collegeAId,
        isActive: true,
      },
      {
        _id: faculty2UserId,
        email: 'faculty2@ait.edu',
        name: 'Prof. Bob Jones',
        role: AppRole.FACULTY,
        collegeId: collegeAId,
        isActive: true,
      },
      {
        _id: hodAUserId,
        email: 'hod.cse@ait.edu',
        name: 'Dr. Carol Danvers',
        role: AppRole.HOD,
        collegeId: collegeAId,
        departmentId: deptAId,
        isActive: true,
      },
      {
        _id: hodBUserId,
        email: 'hod.mech@bce.edu',
        name: 'Dr. Bruce Banner',
        role: AppRole.HOD,
        collegeId: collegeBId,
        departmentId: deptBId,
        isActive: true,
      },
      {
        _id: adminAUserId,
        email: 'admin@ait.edu',
        name: 'Admin Apex',
        role: AppRole.COLLEGE_ADMIN,
        collegeId: collegeAId,
        isActive: true,
      },
      {
        _id: superAdminUserId,
        email: 'superadmin@acadex.io',
        name: 'Super Admin',
        role: AppRole.SUPER_ADMIN,
        isActive: true,
      },
    ]);

    // 5. Seed Profiles
    await Student.create([
      {
        _id: student1ProfileId,
        userId: student1UserId,
        collegeId: collegeAId,
        departmentId: deptAId,
        name: 'Student One',
        rollNumber: 'AIT2024CS001',
      },
      {
        _id: student2ProfileId,
        userId: student2UserId,
        collegeId: collegeAId,
        departmentId: deptAId,
        name: 'Student Two',
        rollNumber: 'AIT2024CS002',
      },
    ]);

    await Faculty.create([
      {
        _id: faculty1ProfileId,
        userId: faculty1UserId,
        collegeId: collegeAId,
        departmentId: deptAId,
        name: 'Prof. Alice Smith',
        email: 'faculty1@ait.edu',
        designation: 'Associate Professor',
        employeeId: 'EMP_FAC_1',
      },
      {
        _id: faculty2ProfileId,
        userId: faculty2UserId,
        collegeId: collegeAId,
        departmentId: deptAId,
        name: 'Prof. Bob Jones',
        email: 'faculty2@ait.edu',
        designation: 'Assistant Professor',
        employeeId: 'EMP_FAC_2',
      },
      {
        userId: hodAUserId,
        collegeId: collegeAId,
        departmentId: deptAId,
        name: 'Dr. Carol Danvers',
        email: 'hod.cse@ait.edu',
        designation: 'Head of Department',
        employeeId: 'EMP_HOD_A',
      },
      {
        userId: hodBUserId,
        collegeId: collegeBId,
        departmentId: deptBId,
        name: 'Dr. Bruce Banner',
        email: 'hod.mech@bce.edu',
        designation: 'Head of Department',
        employeeId: 'EMP_HOD_B',
      },
    ]);

    // 6. Active Student Enrollment for Student 1
    await StudentEnrollment.create({
      collegeId: collegeAId,
      studentId: student1ProfileId,
      departmentId: deptAId,
      academicYearId: academicYearAId,
      courseId: courseAId,
      semesterId: semesterAId,
      sectionId: sectionAId,
      status: 'active',
      enrollmentDate: new Date('2025-06-15'),
    });

    // 7. Active Faculty Assignment for Faculty 1
    await FacultyAssignment.create({
      collegeId: collegeAId,
      departmentId: deptAId,
      facultyId: faculty1ProfileId,
      facultyName: 'Prof. Alice Smith',
      academicYearId: academicYearAId,
      courseId: courseAId,
      semesterId: semesterAId,
      sectionId: sectionAId,
      subjectId: subjectAId,
      status: 'active',
      isActive: true,
      assignedAt: new Date('2025-06-10'),
    });

    // Setup Auth Objects
    authStudent1 = {
      id: student1UserId.toString(),
      instituteId: collegeAId.toString(),
      name: 'Student One',
      email: 'student1@ait.edu',
      role: AppRole.STUDENT,
      collegeId: collegeAId.toString(),
      accountStatus: AccountStatus.ACTIVE,
    };

    authStudent2 = {
      id: student2UserId.toString(),
      instituteId: collegeAId.toString(),
      name: 'Student Two',
      email: 'student2@ait.edu',
      role: AppRole.STUDENT,
      collegeId: collegeAId.toString(),
      accountStatus: AccountStatus.ACTIVE,
    };

    authFaculty1 = {
      id: faculty1UserId.toString(),
      instituteId: collegeAId.toString(),
      name: 'Prof. Alice Smith',
      email: 'faculty1@ait.edu',
      role: AppRole.FACULTY,
      collegeId: collegeAId.toString(),
      accountStatus: AccountStatus.ACTIVE,
    };

    authFaculty2 = {
      id: faculty2UserId.toString(),
      instituteId: collegeAId.toString(),
      name: 'Prof. Bob Jones',
      email: 'faculty2@ait.edu',
      role: AppRole.FACULTY,
      collegeId: collegeAId.toString(),
      accountStatus: AccountStatus.ACTIVE,
    };

    authHodA = {
      id: hodAUserId.toString(),
      instituteId: collegeAId.toString(),
      name: 'Dr. Carol Danvers',
      email: 'hod.cse@ait.edu',
      role: AppRole.HOD,
      collegeId: collegeAId.toString(),
      departmentId: deptAId.toString(),
      accountStatus: AccountStatus.ACTIVE,
    };

    authHodB = {
      id: hodBUserId.toString(),
      instituteId: collegeBId.toString(),
      name: 'Dr. Bruce Banner',
      email: 'hod.mech@bce.edu',
      role: AppRole.HOD,
      collegeId: collegeBId.toString(),
      departmentId: deptBId.toString(),
      accountStatus: AccountStatus.ACTIVE,
    };

    authAdminA = {
      id: adminAUserId.toString(),
      instituteId: collegeAId.toString(),
      name: 'Admin Apex',
      email: 'admin@ait.edu',
      role: AppRole.COLLEGE_ADMIN,
      collegeId: collegeAId.toString(),
      accountStatus: AccountStatus.ACTIVE,
    };

    authSuperAdmin = {
      id: superAdminUserId.toString(),
      instituteId: 'global',
      name: 'Super Admin',
      email: 'superadmin@acadex.io',
      role: AppRole.SUPER_ADMIN,
      accountStatus: AccountStatus.ACTIVE,
    };
  });

  afterAll(async () => {
    await mongoose.disconnect();
    await mongoServer.stop();
  });

  describe('1. Student Home Dashboard Composition & Context', () => {
    it('should aggregate student home with canonical StudentEnrollment context', async () => {
      const dashboard = await DashboardService.getHomeDashboard(authStudent1);

      expect(dashboard).toBeDefined();
      expect(dashboard.role).toBe(AppRole.STUDENT);
      expect(dashboard.greeting.displayName).toBe('Student One');

      const ctx = dashboard.context as any;
      expect(ctx.isEnrollmentAvailable).toBe(true);
      expect(ctx.courseName).toBe('Bachelor of Technology in CS');
      expect(ctx.semesterNumber).toBe(4);
      expect(ctx.sectionName).toBe('Section A');

      expect(dashboard.quickActions.length).toBeGreaterThan(0);
      expect(dashboard.quickActions.some((a) => a.id === 'qa_assignments')).toBe(true);
      expect(dashboard.quickActions.some((a) => a.id === 'qa_academic_records')).toBe(true);
    });

    it('should handle student without active enrollment gracefully without crashing', async () => {
      const dashboard = await DashboardService.getHomeDashboard(authStudent2);

      expect(dashboard).toBeDefined();
      expect(dashboard.role).toBe(AppRole.STUDENT);

      const ctx = dashboard.context as any;
      expect(ctx.isEnrollmentAvailable).toBe(false);

      // Summary indicates unavailable
      const summary = dashboard.summary as any;
      expect(summary.attendancePercentage).toBeNull();
    });

    it('should compute attendance percentage accurately from canonical attendance records', async () => {
      const session1 = await AttendanceSession.create({
        collegeId: collegeAId,
        departmentId: deptAId,
        courseId: courseAId,
        semesterId: semesterAId,
        sectionId: sectionAId,
        subjectId: subjectAId,
        subjectName: 'Data Structures & Algorithms',
        timeSlot: '09:00 - 10:00',
        facultyId: faculty1ProfileId,
        date: new Date(),
        records: [],
        version: 1,
        isSubmitted: true,
        isLocked: true,
        status: AttendanceSessionStatus.LOCKED,
      });

      const session2 = await AttendanceSession.create({
        collegeId: collegeAId,
        departmentId: deptAId,
        courseId: courseAId,
        semesterId: semesterAId,
        sectionId: sectionAId,
        subjectId: subjectAId,
        subjectName: 'Data Structures & Algorithms',
        timeSlot: '10:00 - 11:00',
        facultyId: faculty1ProfileId,
        date: new Date(),
        records: [],
        version: 1,
        isSubmitted: true,
        isLocked: true,
        status: AttendanceSessionStatus.LOCKED,
      });

      await AttendanceRecord.create([
        {
          collegeId: collegeAId,
          departmentId: deptAId,
          sessionId: session1._id,
          studentId: student1ProfileId,
          studentName: 'Student One',
          rollNumber: 'AIT2024CS001',
          subjectId: subjectAId,
          facultyId: faculty1ProfileId,
          date: new Date(),
          timeSlot: '09:00 - 10:00',
          status: AttendanceStatus.PRESENT,
          isCancelled: false,
        },
        {
          collegeId: collegeAId,
          departmentId: deptAId,
          sessionId: session2._id,
          studentId: student1ProfileId,
          studentName: 'Student One',
          rollNumber: 'AIT2024CS001',
          subjectId: subjectAId,
          facultyId: faculty1ProfileId,
          date: new Date(),
          timeSlot: '10:00 - 11:00',
          status: AttendanceStatus.ABSENT,
          isCancelled: false,
        },
      ]);

      const dashboard = await DashboardService.getHomeDashboard(authStudent1);
      const summary = dashboard.summary as any;

      expect(summary.attendancePercentage).toBe(50);
    });
  });

  describe('2. Student Data Privacy & Unpublished Data Exclusion', () => {
    it('should exclude unpublished assessments from student view', async () => {
      // Create one published and one draft assessment
      await InternalAssessment.create([
        {
          collegeId: collegeAId,
          departmentId: deptAId,
          courseId: courseAId,
          academicYearId: academicYearAId,
          semesterId: semesterAId,
          subjectId: subjectAId,
          title: 'Midterm Exam - Published',
          assessmentType: 'UNIT_TEST',
          maxMarks: 50,
          weightage: 20,
          status: AssessmentStatus.PUBLISHED,
          createdBy: faculty1UserId,
        },
        {
          collegeId: collegeAId,
          departmentId: deptAId,
          courseId: courseAId,
          academicYearId: academicYearAId,
          semesterId: semesterAId,
          subjectId: subjectAId,
          title: 'Quiz 2 - Draft/Unpublished',
          assessmentType: 'QUIZ',
          maxMarks: 20,
          weightage: 10,
          status: AssessmentStatus.DRAFT,
          createdBy: faculty1UserId,
        },
      ]);

      const dashboard = await DashboardService.getHomeDashboard(authStudent1);
      const summary = dashboard.summary as any;

      // Student summary should only count the published assessment
      expect(summary.publishedAssessmentsCount).toBe(1);
    });

    it('should exclude unpublished official academic results from student view', async () => {
      const dummyRecordId = new Types.ObjectId();
      const dummyEnrollmentId = new Types.ObjectId();

      // Create a draft result for student 1
      await AcademicResult.create({
        collegeId: collegeAId,
        studentId: student1ProfileId,
        academicRecordId: dummyRecordId,
        studentEnrollmentId: dummyEnrollmentId,
        departmentId: deptAId,
        courseId: courseAId,
        academicYearId: academicYearAId,
        semesterId: semesterAId,
        status: ResultLifecycleStatus.DRAFT,
        version: 1,
        calculatedAt: new Date(),
        summary: {
          totalSubjects: 1,
          passedSubjects: 1,
          failedSubjects: 0,
          incompleteSubjects: 0,
          totalCreditsAttempted: 4,
          totalCreditsEarned: 4,
          totalMaxMarks: 100,
          totalObtainedMarks: 90,
          overallResult: OverallResultStatus.PASS,
        },
        subjectResults: [],
        publicationSnapshots: [],
        reopenHistory: [],
        auditLog: [],
      });

      let dashboard = await DashboardService.getHomeDashboard(authStudent1);
      let summary = dashboard.summary as any;
      expect(summary.latestResultStatus).toBe('NOT_YET_PUBLISHED');

      // Now publish a result
      await AcademicResult.create({
        collegeId: collegeAId,
        studentId: student1ProfileId,
        academicRecordId: dummyRecordId,
        studentEnrollmentId: dummyEnrollmentId,
        departmentId: deptAId,
        courseId: courseAId,
        academicYearId: academicYearAId,
        semesterId: semesterAId,
        status: ResultLifecycleStatus.PUBLISHED,
        version: 1,
        calculatedAt: new Date(),
        publishedAt: new Date(),
        summary: {
          totalSubjects: 1,
          passedSubjects: 1,
          failedSubjects: 0,
          incompleteSubjects: 0,
          totalCreditsAttempted: 4,
          totalCreditsEarned: 4,
          totalMaxMarks: 100,
          totalObtainedMarks: 85,
          overallResult: OverallResultStatus.PASS,
        },
        subjectResults: [],
        publicationSnapshots: [],
        reopenHistory: [],
        auditLog: [],
      });

      dashboard = await DashboardService.getHomeDashboard(authStudent1);
      summary = dashboard.summary as any;
      expect(summary.latestResultStatus).toBe('AVAILABLE');
    });

    it('should isolate private requests between students', async () => {
      // Student 1 submits a request
      await RequestModel.create({
        requestId: 'REQ-001',
        collegeId: collegeAId,
        departmentId: deptAId,
        requesterUserId: student1UserId,
        requesterName: 'Student One',
        requesterRole: AppRole.STUDENT,
        targetRole: AppRole.COLLEGE_ADMIN,
        requestType: 'BONAFIDE_CERTIFICATE',
        title: 'Need Bonafide for Passport',
        description: 'Applying for passport',
        status: RequestStatus.SUBMITTED,
        history: [],
      });

      // Student 2 submits a different request
      await RequestModel.create({
        requestId: 'REQ-002',
        collegeId: collegeAId,
        departmentId: deptAId,
        requesterUserId: student2UserId,
        requesterName: 'Student Two',
        requesterRole: AppRole.STUDENT,
        targetRole: AppRole.COLLEGE_ADMIN,
        requestType: 'FEE_CONCESSION',
        title: 'Fee Concession Request',
        description: 'Financial hardship',
        status: RequestStatus.SUBMITTED,
        history: [],
      });

      const dash1 = await DashboardService.getHomeDashboard(authStudent1);
      const dash2 = await DashboardService.getHomeDashboard(authStudent2);

      const r1 = dash1.recent.filter((r) => r.type === 'REQUEST');
      const r2 = dash2.recent.filter((r) => r.type === 'REQUEST');

      expect(r1.length).toBe(1);
      expect(r2.length).toBe(1);
      expect(r1[0].title).toBe('Need Bonafide for Passport');
      expect(r2[0].title).toBe('Fee Concession Request');
    });
  });

  describe('3. Faculty Home Dashboard Composition & Teaching Scope', () => {
    it('should aggregate faculty home with active FacultyAssignments context', async () => {
      const dashboard = await DashboardService.getHomeDashboard(authFaculty1);

      expect(dashboard).toBeDefined();
      expect(dashboard.role).toBe(AppRole.FACULTY);
      expect(dashboard.greeting.displayName).toBe('Prof. Alice Smith');

      const ctx = dashboard.context as any;
      expect(ctx.designation).toBe('Associate Professor');
      expect(ctx.departmentName).toBe('Computer Science and Engineering');
      expect(ctx.activeTeachingAssignmentsCount).toBe(1);

      expect(dashboard.quickActions.some((a) => a.id === 'qa_mark_attendance')).toBe(true);
      expect(dashboard.quickActions.some((a) => a.id === 'qa_assignments')).toBe(true);
    });

    it('should compute pending reviews and pending marks for faculty', async () => {
      // Create an assignment created by Faculty 1
      const assignment = await Assignment.create({
        collegeId: collegeAId,
        departmentId: deptAId,
        courseId: courseAId,
        academicYearId: academicYearAId,
        semesterId: semesterAId,
        subjectId: subjectAId,
        facultyId: faculty1ProfileId,
        facultyName: 'Prof. Alice Smith',
        title: 'Assignment 1 - Stacks and Queues',
        description: 'Complete questions 1 to 5',
        questions: ['Q1', 'Q2'],
        assignmentType: AssignmentType.HOMEWORK,
        dueDate: '2026-04-01',
        dueTime: '23:59',
        dueDateTime: new Date(Date.now() + 86400000 * 3),
        maximumMarks: 100,
        attachments: [],
        status: 'PUBLISHED',
      });

      // Submission awaiting review
      await AssignmentSubmission.create({
        collegeId: collegeAId,
        assignmentId: assignment._id,
        studentId: student1ProfileId,
        studentUserId: student1UserId,
        studentName: 'Student One',
        status: 'SUBMITTED',
        submittedAt: new Date(),
      });

      const dashboard = await DashboardService.getHomeDashboard(authFaculty1);
      const summary = dashboard.summary as any;

      expect(summary.submissionsAwaitingReview).toBe(1);
      expect(dashboard.pendingActions.some((p) => p.type === 'REVIEW_SUBMISSION')).toBe(true);
    });

    it('should isolate faculty with no assignments gracefully', async () => {
      const dashboard = await DashboardService.getHomeDashboard(authFaculty2);

      expect(dashboard).toBeDefined();
      expect(dashboard.role).toBe(AppRole.FACULTY);

      const ctx = dashboard.context as any;
      expect(ctx.activeTeachingAssignmentsCount).toBe(0);
    });
  });

  describe('4. HOD Dashboard Department Isolation', () => {
    it('should aggregate HOD dashboard scoped strictly to their department', async () => {
      const dashboardA = await DashboardService.getHomeDashboard(authHodA);

      expect(dashboardA).toBeDefined();
      expect(dashboardA.role).toBe(AppRole.HOD);

      const ctxA = dashboardA.context as any;
      expect(ctxA.departmentName).toBe('Computer Science and Engineering');
      expect(ctxA.departmentCode).toBe('CSE');

      const sumA = dashboardA.summary as any;
      expect(sumA.activeStudentsCount).toBe(2); // Student 1 and Student 2 in CSE
      expect(sumA.activeFacultyCount).toBe(3); // Faculty 1, Faculty 2, HOD A in CSE

      expect(dashboardA.quickActions.some((a) => a.id === 'qa_attendance')).toBe(true);
      expect(dashboardA.quickActions.some((a) => a.id === 'qa_requests')).toBe(true);
    });

    it('should not leak Department A metrics into Department B HOD dashboard', async () => {
      const dashboardB = await DashboardService.getHomeDashboard(authHodB);

      expect(dashboardB).toBeDefined();
      expect(dashboardB.role).toBe(AppRole.HOD);

      const ctxB = dashboardB.context as any;
      expect(ctxB.departmentName).toBe('Mechanical Engineering');

      const sumB = dashboardB.summary as any;
      expect(sumB.activeStudentsCount).toBe(0);
      expect(sumB.activeFacultyCount).toBe(1); // Only HOD B
    });
  });

  describe('5. College Admin Dashboard Tenant Isolation', () => {
    it('should aggregate college-wide metrics strictly bounded to College A', async () => {
      const dashboard = await DashboardService.getHomeDashboard(authAdminA);

      expect(dashboard).toBeDefined();
      expect(dashboard.role).toBe(AppRole.COLLEGE_ADMIN);

      const ctx = dashboard.context as any;
      expect(ctx.collegeName).toBe('Apex Institute of Technology');
      expect(ctx.collegeCode).toBe('AIT');

      const summary = dashboard.summary as any;
      expect(summary.departmentsCount).toBe(1);
      expect(summary.studentsCount).toBe(2);
      expect(summary.facultyCount).toBe(3);

      expect(dashboard.quickActions.some((a) => a.id === 'qa_students')).toBe(true);
      expect(dashboard.quickActions.some((a) => a.id === 'qa_faculty')).toBe(true);
      expect(dashboard.quickActions.some((a) => a.id === 'qa_departments')).toBe(true);
    });
  });

  describe('6. Super Admin Dashboard Scope & Platform Summary', () => {
    it('should aggregate global platform statistics for Super Admin without collegeId', async () => {
      const dashboard = await DashboardService.getHomeDashboard(authSuperAdmin);

      expect(dashboard).toBeDefined();
      expect(dashboard.role).toBe(AppRole.SUPER_ADMIN);

      const ctx = dashboard.context as any;
      expect(ctx.scope).toBe('GLOBAL');

      const summary = dashboard.summary as any;
      expect(summary.collegesCount).toBe(2);
      expect(summary.activeCollegesCount).toBe(2);
      expect(summary.usersCount).toBeGreaterThanOrEqual(8);

      expect(dashboard.quickActions.some((a) => a.id === 'qa_colleges')).toBe(true);
      expect(dashboard.quickActions.some((a) => a.id === 'qa_users')).toBe(true);
    });
  });

  describe('7. Announcements & Notifications Integration', () => {
    it('should filter announcements by audience and college tenant', async () => {
      // College A Announcement for ALL
      await Announcement.create({
        collegeId: collegeAId,
        title: 'Campus Spring Fest 2026',
        body: 'Annual festival is starting next week!',
        audienceScope: AudienceScope.COLLEGE,
        createdBy: adminAUserId,
        status: AnnouncementStatus.PUBLISHED,
        publishAt: new Date(),
        publishedAt: new Date(),
        recipientCount: 10,
      });

      // College A Announcement for FACULTY only
      await Announcement.create({
        collegeId: collegeAId,
        title: 'Faculty Meeting Tomorrow',
        body: 'Mandatory faculty briefing at 4 PM.',
        audienceScope: AudienceScope.ROLE,
        targetRole: AppRole.FACULTY,
        createdBy: adminAUserId,
        status: AnnouncementStatus.PUBLISHED,
        publishAt: new Date(),
        publishedAt: new Date(),
        recipientCount: 3,
      });

      // College B Announcement (should never leak to College A users)
      await Announcement.create({
        collegeId: collegeBId,
        title: 'Beacon Sports Meet',
        body: 'Sports day announcement',
        audienceScope: AudienceScope.COLLEGE,
        createdBy: hodBUserId,
        status: AnnouncementStatus.PUBLISHED,
        publishAt: new Date(),
        publishedAt: new Date(),
        recipientCount: 5,
      });

      const studentDash = await DashboardService.getHomeDashboard(authStudent1);
      const facultyDash = await DashboardService.getHomeDashboard(authFaculty1);

      // Student should see Spring Fest but NOT Faculty Meeting or College B
      const studentAnnouncements = studentDash.recent.filter((r) => r.type === 'ANNOUNCEMENT');
      expect(studentAnnouncements.some((a) => a.title === 'Campus Spring Fest 2026')).toBe(true);
      expect(studentAnnouncements.some((a) => a.title === 'Faculty Meeting Tomorrow')).toBe(false);
      expect(studentAnnouncements.some((a) => a.title === 'Beacon Sports Meet')).toBe(false);

      // Faculty should see both College A announcements
      const facultyAnnouncements = facultyDash.recent.filter((r) => r.type === 'ANNOUNCEMENT');
      expect(facultyAnnouncements.some((a) => a.title === 'Campus Spring Fest 2026')).toBe(true);
      expect(facultyAnnouncements.some((a) => a.title === 'Faculty Meeting Tomorrow')).toBe(true);
      expect(facultyAnnouncements.some((a) => a.title === 'Beacon Sports Meet')).toBe(false);
    });

    it('should accurately count unread notifications for requester', async () => {
      await Notification.create([
        {
          collegeId: collegeAId,
          recipientUserId: student1UserId,
          title: 'Grade Updated',
          body: 'Your DSA assignment was graded.',
          notificationType: NotificationType.ASSIGNMENT_GRADED,
          isRead: false,
        },
        {
          collegeId: collegeAId,
          recipientUserId: student1UserId,
          title: 'Attendance Warning',
          body: 'Check your attendance status.',
          notificationType: NotificationType.ATTENDANCE_LOW,
          isRead: false,
        },
        {
          collegeId: collegeAId,
          recipientUserId: student1UserId,
          title: 'Old Notification',
          body: 'Welcome to ACADEX',
          notificationType: NotificationType.SYSTEM,
          isRead: true, // Read
        },
      ]);

      const dashboard = await DashboardService.getHomeDashboard(authStudent1);
      const unreadAlert = dashboard.alerts.find((a) => a.id === 'unread_notifications');

      expect(unreadAlert).toBeDefined();
      expect(unreadAlert?.message).toContain('2 unread notifications');
    });
  });

  describe('8. Edge Cases & Resilience', () => {
    it('should throw ApiError if user is not in database', async () => {
      const fakeAuth: AuthenticatedUser = {
        id: new Types.ObjectId().toString(),
        instituteId: collegeAId.toString(),
        name: 'Ghost User',
        email: 'ghost@ait.edu',
        role: AppRole.STUDENT,
        collegeId: collegeAId.toString(),
        accountStatus: AccountStatus.ACTIVE,
      };

      await expect(DashboardService.getHomeDashboard(fakeAuth)).rejects.toThrow(
        'Authenticated user document not found'
      );
    });

    it('should throw ApiError if non-superadmin has no collegeId', async () => {
      const noCollegeAuth: AuthenticatedUser = {
        id: student1UserId.toString(),
        instituteId: '',
        name: 'No College User',
        email: 'student1@ait.edu',
        role: AppRole.STUDENT,
        accountStatus: AccountStatus.ACTIVE,
        // missing collegeId
      };

      await expect(DashboardService.getHomeDashboard(noCollegeAuth)).rejects.toThrow(
        'Tenant college ID is required for role dashboard'
      );
    });
  });
});
