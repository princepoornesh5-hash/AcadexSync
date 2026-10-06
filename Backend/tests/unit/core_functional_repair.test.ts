import { Types } from 'mongoose';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { AcademicService } from '../../src/services/academic.service';
import { AssignmentService } from '../../src/services/assignment.service';
import { InvitationService } from '../../src/services/invitation.service';
import { AttendanceService } from '../../src/services/attendance.service';
import { AcademicCalendarService } from '../../src/services/academicCalendar.service';
import { DashboardService } from '../../src/services/dashboard.service';
import { TeachingAuthorizationService } from '../../src/services/teachingAuthorization.service';
import {
  College,
  Department,
  Course,
  AcademicYear,
  Semester,
  Section,
  Subject,
  Faculty,
  Student,
  StudentEnrollment,
  FacultyAssignment,
  Assignment,
  AssignmentSubmission,
  User,
  Timetable,
  CalendarEvent,
} from '../../src/models';
import { AppRole } from '../../src/constants/roles';
import { TimetableDay, TimetableStatus, TimetableSessionType } from '../../src/constants/status';
import {
  CalendarEventType,
  CalendarSourceType,
  CalendarEventScope,
  CalendarEventStatus,
} from '../../src/constants/calendar.constants';
import { AssignmentStatus, StudentTaskStatus } from '../../src/constants/assignment.constants';

describe('ACADEX Core Functional Repair Tests', () => {
  let collegeId: string;
  let college2Id: string;
  let deptId: string;
  let dept2Id: string;
  let courseId: string;
  let ayId: string;
  let semId: string;
  let sectionId: string;

  let superAdminUser: any;
  let collegeAdminUser: any;
  let hodUser: any;
  let facultyUser: any;
  let otherFacultyUser: any;
  let studentUser: any;

  let facultyDoc: any;
  let studentDoc: any;
  let otherStudentDoc: any;

  beforeAll(async () => {
    await setupTestDB();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();

    const college = await College.create({
      name: 'Engineering College Alpha',
      code: 'ECA',
      address: 'North Campus, City Alpha',
      email: 'admin@alpha.edu',
      phone: '9000000001',
      principal: 'Dr. Alpha Principal',
      status: 'active',
      isActive: true,
    });
    collegeId = college._id.toString();

    const college2 = await College.create({
      name: 'College Beta',
      code: 'ECB',
      address: 'South Campus, City Beta',
      email: 'admin@beta.edu',
      phone: '9000000002',
      principal: 'Dr. Beta Principal',
      status: 'active',
      isActive: true,
    });
    college2Id = college2._id.toString();

    const dept = await Department.create({
      collegeId: college._id,
      name: 'Computer Science',
      code: 'CSE',
      isActive: true,
      status: 'active',
    });
    deptId = dept._id.toString();

    const dept2 = await Department.create({
      collegeId: college._id,
      name: 'Mechanical Engineering',
      code: 'MECH',
      isActive: true,
      status: 'active',
    });
    dept2Id = dept2._id.toString();

    const course = await Course.create({
      collegeId: college._id,
      departmentId: dept._id,
      name: 'B.Tech CSE',
      code: 'BTCSE',
      duration: 4,
      isActive: true,
    });
    courseId = course._id.toString();

    const ay = await AcademicYear.create({
      collegeId: college._id,
      name: '2026-2027',
      startDate: new Date('2026-06-01'),
      endDate: new Date('2027-05-31'),
      isCurrent: true,
      isActive: true,
      status: 'active',
    });
    ayId = ay._id.toString();

    const sem = await Semester.create({
      collegeId: college._id,
      departmentId: dept._id,
      courseId: course._id,
      academicYearId: ay._id,
      name: 'Semester 1',
      number: 1,
      isActive: true,
      status: 'active',
    });
    semId = sem._id.toString();

    const sec = await Section.create({
      collegeId: college._id,
      departmentId: dept._id,
      courseId: course._id,
      semesterId: sem._id,
      academicYearId: ay._id,
      name: 'Section A',
      capacity: 60,
      isActive: true,
    });
    sectionId = sec._id.toString();

    // Create users & profiles
    const superAdminUserDoc = await User.create({
      name: 'Super Admin',
      email: 'super@acadex.edu',
      role: AppRole.SUPER_ADMIN,
      isActive: true,
    });
    superAdminUser = { id: superAdminUserDoc._id.toString(), role: AppRole.SUPER_ADMIN };

    const collegeAdminUserDoc = await User.create({
      collegeId: college._id,
      name: 'College Admin',
      email: 'admin@alpha.edu',
      role: AppRole.COLLEGE_ADMIN,
      isActive: true,
    });
    collegeAdminUser = { id: collegeAdminUserDoc._id.toString(), role: AppRole.COLLEGE_ADMIN, collegeId };

    const hodUserDoc = await User.create({
      collegeId: college._id,
      departmentId: dept._id,
      name: 'Dr. Alan HOD',
      email: 'hod.cse@alpha.edu',
      role: AppRole.HOD,
      isActive: true,
    });
    hodUser = { id: hodUserDoc._id.toString(), role: AppRole.HOD, collegeId, departmentId: deptId };

    const facultyUserDoc = await User.create({
      collegeId: college._id,
      departmentId: dept._id,
      name: 'Prof. Ada Lovelace',
      email: 'ada@alpha.edu',
      role: AppRole.FACULTY,
      isActive: true,
    });
    facultyDoc = await Faculty.create({
      userId: facultyUserDoc._id,
      collegeId: college._id,
      departmentId: dept._id,
      name: 'Prof. Ada Lovelace',
      email: 'ada@alpha.edu',
      isActive: true,
      status: 'active',
    });
    facultyUser = { id: facultyUserDoc._id.toString(), role: AppRole.FACULTY, collegeId, departmentId: deptId, email: 'ada@alpha.edu' };

    const otherFacultyUserDoc = await User.create({
      collegeId: college._id,
      departmentId: dept._id,
      name: 'Prof. Charles Babbage',
      email: 'charles@alpha.edu',
      role: AppRole.FACULTY,
      isActive: true,
    });
    await Faculty.create({
      userId: otherFacultyUserDoc._id,
      collegeId: college._id,
      departmentId: dept._id,
      name: 'Prof. Charles Babbage',
      email: 'charles@alpha.edu',
      isActive: true,
      status: 'active',
    });
    otherFacultyUser = { id: otherFacultyUserDoc._id.toString(), role: AppRole.FACULTY, collegeId, departmentId: deptId, email: 'charles@alpha.edu' };

    const studentUserDoc = await User.create({
      collegeId: college._id,
      departmentId: dept._id,
      name: 'Grace Hopper',
      email: 'grace@alpha.edu',
      role: AppRole.STUDENT,
      isActive: true,
    });
    studentDoc = await Student.create({
      userId: studentUserDoc._id,
      collegeId: college._id,
      departmentId: dept._id,
      name: 'Grace Hopper',
      email: 'grace@alpha.edu',
      rollNumber: '2026-CSE-001',
      isActive: true,
      status: 'active',
    });
    studentUser = { id: studentUserDoc._id.toString(), role: AppRole.STUDENT, collegeId };

    await StudentEnrollment.create({
      collegeId: college._id,
      departmentId: dept._id,
      courseId: course._id,
      academicYearId: ay._id,
      semesterId: sem._id,
      sectionId: sec._id,
      studentId: studentDoc._id,
      status: 'active',
    });

    const otherStudentUserDoc = await User.create({
      collegeId: college._id,
      departmentId: dept2._id,
      name: 'Outside Student',
      email: 'outside@alpha.edu',
      role: AppRole.STUDENT,
      isActive: true,
    });
    otherStudentDoc = await Student.create({
      userId: otherStudentUserDoc._id,
      collegeId: college._id,
      departmentId: dept2._id,
      name: 'Outside Student',
      email: 'outside@alpha.edu',
      rollNumber: '2026-MECH-001',
      isActive: true,
      status: 'active',
    });
  });

  // =========================================================================
  // DOMAIN 1: SUBJECT CREATION
  // =========================================================================
  describe('Domain 1: Subject Creation & Semester Reuse', () => {
    it('1. Reuses existing semester without attempting duplicate semester creation', async () => {
      const semCountBefore = await Semester.countDocuments();
      const subject = await AcademicService.createSubject(
        collegeId,
        {
          courseId,
          semesterId: semId,
          name: 'Data Structures',
          code: 'CS101',
          credits: 4,
          type: 'Theory',
        },
        hodUser
      );

      expect(subject).toBeDefined();
      expect(subject.semesterId.toString()).toBe(semId);
      expect(subject.code).toBe('CS101');
      const semCountAfter = await Semester.countDocuments();
      expect(semCountAfter).toBe(semCountBefore); // No new semester created
    });

    it('2. Distinguishes subject duplicate from semester duplicate (throws subject conflict)', async () => {
      await AcademicService.createSubject(
        collegeId,
        {
          courseId,
          semesterId: semId,
          name: 'Data Structures',
          code: 'CS101',
          credits: 4,
          type: 'Theory',
        },
        hodUser
      );

      await expect(
        AcademicService.createSubject(
          collegeId,
          {
            courseId,
            semesterId: semId,
            name: 'Advanced Data Structures',
            code: 'CS101',
            credits: 4,
            type: 'Theory',
          },
          hodUser
        )
      ).rejects.toThrow(/Subject with code "CS101" already exists in this semester/);
    });

    it('3. Allows same subject code in different semesters', async () => {
      const sem2 = await Semester.create({
        collegeId: new Types.ObjectId(collegeId),
        departmentId: new Types.ObjectId(deptId),
        courseId: new Types.ObjectId(courseId),
        academicYearId: new Types.ObjectId(ayId),
        name: 'Semester 2',
        number: 2,
        isActive: true,
        status: 'active',
      });

      await AcademicService.createSubject(
        collegeId,
        {
          courseId,
          semesterId: semId,
          name: 'Data Structures',
          code: 'CS101',
          credits: 4,
          type: 'Theory',
        },
        hodUser
      );

      const subSem2 = await AcademicService.createSubject(
        collegeId,
        {
          courseId,
          semesterId: sem2._id.toString(),
          name: 'Data Structures Lab',
          code: 'CS101',
          credits: 2,
          type: 'Practical',
        },
        hodUser
      );

      expect(subSem2.semesterId.toString()).toBe(sem2._id.toString());
    });

    it('4. Rejects subject creation across colleges (Tenant isolation)', async () => {
      await expect(
        AcademicService.createSubject(
          college2Id,
          {
            courseId,
            semesterId: semId,
            name: 'Data Structures',
            code: 'CS101',
          },
          hodUser
        )
      ).rejects.toThrow(/(Cross-college subject creation is strictly prohibited|Course does not belong to the specified college)/);
    });
  });

  // =========================================================================
  // DOMAIN 2 & 3: FACULTY ASSIGNMENT & CANONICAL IDENTITY
  // =========================================================================
  describe('Domain 2 & 3: Faculty Assignment & Canonical Teaching Authority', () => {
    let subjectDoc: any;

    beforeEach(async () => {
      subjectDoc = await Subject.create({
        collegeId: new Types.ObjectId(collegeId),
        departmentId: new Types.ObjectId(deptId),
        courseId: new Types.ObjectId(courseId),
        semesterId: new Types.ObjectId(semId),
        name: 'Algorithms',
        code: 'CS201',
        credits: 4,
        type: 'Theory',
        isActive: true,
      });
    });

    it('1. Creates valid FacultyAssignment referencing Faculty._id', async () => {
      const assignment = await AcademicService.createFacultyAssignment(
        collegeId,
        {
          facultyId: facultyDoc._id.toString(),
          subjectId: subjectDoc._id.toString(),
          courseId,
          semesterId: semId,
          academicYearId: ayId,
          sectionId,
        },
        hodUser
      );

      expect(assignment).toBeDefined();
      expect(assignment.facultyId.toString()).toBe(facultyDoc._id.toString());
      expect(assignment.facultyId.toString()).not.toBe(facultyUser.id); // Faculty._id != User._id
    });

    it('2. Correctly resolves FacultyAssignment ownership via User -> Faculty profile', async () => {
      const assignment = await AcademicService.createFacultyAssignment(
        collegeId,
        {
          facultyId: facultyDoc._id.toString(),
          subjectId: subjectDoc._id.toString(),
          courseId,
          semesterId: semId,
          academicYearId: ayId,
          sectionId,
        },
        hodUser
      );

      // Owning faculty resolves true
      const isOwner = await TeachingAuthorizationService.isFacultyOwner(collegeId, facultyUser, assignment);
      expect(isOwner).toBe(true);

      // Different faculty resolves false
      const isOtherOwner = await TeachingAuthorizationService.isFacultyOwner(collegeId, otherFacultyUser, assignment);
      expect(isOtherOwner).toBe(false);
    });

    it('3. Rejects duplicate active assignment for same faculty, subject, and section', async () => {
      await AcademicService.createFacultyAssignment(
        collegeId,
        {
          facultyId: facultyDoc._id.toString(),
          subjectId: subjectDoc._id.toString(),
          courseId,
          semesterId: semId,
          academicYearId: ayId,
          sectionId,
        },
        hodUser
      );

      await expect(
        AcademicService.createFacultyAssignment(
          collegeId,
          {
            facultyId: facultyDoc._id.toString(),
            subjectId: subjectDoc._id.toString(),
            courseId,
            semesterId: semId,
            academicYearId: ayId,
            sectionId,
          },
          hodUser
        )
      ).rejects.toThrow(/already assigned/);
    });
  });

  // =========================================================================
  // DOMAIN 4 & 5: ASSIGNMENT OWNERSHIP & MARKING AUTHORIZATION
  // =========================================================================
  describe('Domain 4 & 5: Assignment Ownership & Marking Authorization', () => {
    let subjectDoc: any;
    let facultyAssignmentDoc: any;
    let assignmentDoc: any;

    beforeEach(async () => {
      subjectDoc = await Subject.create({
        collegeId: new Types.ObjectId(collegeId),
        departmentId: new Types.ObjectId(deptId),
        courseId: new Types.ObjectId(courseId),
        semesterId: new Types.ObjectId(semId),
        name: 'Mathematics',
        code: 'MATH101',
        credits: 4,
        type: 'Theory',
        isActive: true,
      });

      facultyAssignmentDoc = await FacultyAssignment.create({
        collegeId: new Types.ObjectId(collegeId),
        departmentId: new Types.ObjectId(deptId),
        facultyId: facultyDoc._id,
        facultyName: facultyDoc.name,
        courseId: new Types.ObjectId(courseId),
        semesterId: new Types.ObjectId(semId),
        sectionId: new Types.ObjectId(sectionId),
        subjectId: subjectDoc._id,
        academicYearId: new Types.ObjectId(ayId),
        status: 'active',
        isActive: true,
      });

      assignmentDoc = await Assignment.create({
        collegeId: new Types.ObjectId(collegeId),
        departmentId: new Types.ObjectId(deptId),
        courseId: new Types.ObjectId(courseId),
        academicYearId: new Types.ObjectId(ayId),
        semesterId: new Types.ObjectId(semId),
        sectionId: new Types.ObjectId(sectionId),
        subjectId: subjectDoc._id,
        facultyAssignmentId: facultyAssignmentDoc._id,
        facultyId: new Types.ObjectId(facultyUser.id),
        facultyName: facultyDoc.name,
        title: 'Maths Assignment 1',
        description: 'First calculus homework',
        maximumMarks: 100,
        dueDateTime: new Date('2026-11-01T23:59:59.000Z'),
        dueDate: '2026-11-01',
        dueTime: '23:59',
        status: AssignmentStatus.PUBLISHED,
        createdBy: new Types.ObjectId(facultyUser.id),
      });

      await AssignmentSubmission.create({
        collegeId: new Types.ObjectId(collegeId),
        assignmentId: assignmentDoc._id,
        studentId: studentDoc._id,
        studentUserId: studentDoc.userId,
        studentName: studentDoc.name,
        rollNumber: studentDoc.rollNumber,
        status: StudentTaskStatus.SUBMITTED,
        version: 1,
      });
    });

    it('1. Owning faculty is authorized to mark assignments', async () => {
      const result = await AssignmentService.recordMarks(
        collegeId,
        facultyUser,
        assignmentDoc._id.toString(),
        [{ studentId: studentDoc._id.toString(), marks: 95, feedback: 'Excellent work' }]
      );

      expect(result).toBeDefined();
      const updated = await AssignmentSubmission.findOne({
        assignmentId: assignmentDoc._id,
        studentId: studentDoc._id,
      });
      expect(updated?.marks).toBe(95);
    });

    it('2. Different faculty cannot mark assignment (Forbidden 403)', async () => {
      await expect(
        AssignmentService.recordMarks(
          collegeId,
          otherFacultyUser,
          assignmentDoc._id.toString(),
          [{ studentId: studentDoc._id.toString(), marks: 80 }]
        )
      ).rejects.toThrow(/Only the assigned teaching faculty may mark or grade this assignment/);
    });

    it('3. HOD-only user cannot mark faculty-owned assignment (Forbidden 403)', async () => {
      await expect(
        AssignmentService.recordMarks(
          collegeId,
          hodUser,
          assignmentDoc._id.toString(),
          [{ studentId: studentDoc._id.toString(), marks: 85 }]
        )
      ).rejects.toThrow(/Only the assigned teaching faculty may mark or grade this assignment/);
    });

    it('4. College Admin cannot mark faculty-owned assignment (Forbidden 403)', async () => {
      await expect(
        AssignmentService.recordMarks(
          collegeId,
          collegeAdminUser,
          assignmentDoc._id.toString(),
          [{ studentId: studentDoc._id.toString(), marks: 90 }]
        )
      ).rejects.toThrow(/Administrative roles cannot mark faculty-owned assignments/);
    });

    it('5. Super Admin cannot mark faculty-owned assignment (Forbidden 403)', async () => {
      await expect(
        AssignmentService.recordMarks(
          collegeId,
          superAdminUser,
          assignmentDoc._id.toString(),
          [{ studentId: studentDoc._id.toString(), marks: 90 }]
        )
      ).rejects.toThrow(/Administrative roles cannot mark faculty-owned assignments/);
    });

    it('6. Student outside enrollment context cannot be marked (Forbidden 403)', async () => {
      await expect(
        AssignmentService.recordMarks(
          collegeId,
          facultyUser,
          assignmentDoc._id.toString(),
          [{ studentId: otherStudentDoc._id.toString(), marks: 75 }]
        )
      ).rejects.toThrow(/Student is not enrolled in the academic context of this assignment/);
    });
  });

  // =========================================================================
  // DOMAIN 6: HOD ADD STUDENT ROLE ESCALATION
  // =========================================================================
  describe('Domain 6: HOD User Creation Role Escalation Prevention', () => {
    it('1. HOD creates Student = ALLOW', async () => {
      const result = await InvitationService.createInvitation(hodUser, {
        name: 'New Student',
        instituteId: 'STU-2026-001',
        email: 'newstudent@alpha.edu',
        role: AppRole.STUDENT,
        departmentId: deptId,
      });

      expect(result).toBeDefined();
      expect(result.user.role).toBe(AppRole.STUDENT);
    });

    it('2. HOD creates Faculty = DENY (Forbidden 403)', async () => {
      await expect(
        InvitationService.createInvitation(hodUser, {
          name: 'New Faculty',
          instituteId: 'FAC-2026-001',
          email: 'newfaculty@alpha.edu',
          role: AppRole.FACULTY,
          departmentId: deptId,
        })
      ).rejects.toThrow(/HOD cannot provision accounts with role "FACULTY". Only Student accounts can be created/);
    });

    it('3. HOD creates HOD = DENY (Forbidden 403)', async () => {
      await expect(
        InvitationService.createInvitation(hodUser, {
          name: 'Another HOD',
          instituteId: 'HOD-2026-002',
          email: 'newhod@alpha.edu',
          role: AppRole.HOD,
          departmentId: deptId,
        })
      ).rejects.toThrow(/HOD cannot provision accounts with role "HOD"/);
    });

    it('4. HOD creates College Admin = DENY (Forbidden 403)', async () => {
      await expect(
        InvitationService.createInvitation(hodUser, {
          name: 'Escalated Admin',
          instituteId: 'ADM-2026-001',
          email: 'escalated@alpha.edu',
          role: AppRole.COLLEGE_ADMIN,
          departmentId: deptId,
        })
      ).rejects.toThrow(/HOD cannot provision accounts with role "COLLEGE_ADMIN"/);
    });

    it('5. HOD creates Super Admin = DENY (Forbidden 403)', async () => {
      await expect(
        InvitationService.createInvitation(hodUser, {
          name: 'Super Admin Exploit',
          instituteId: 'SUP-2026-001',
          email: 'exploit@alpha.edu',
          role: AppRole.SUPER_ADMIN,
          departmentId: deptId,
        })
      ).rejects.toThrow(/HOD cannot provision accounts with role "SUPER_ADMIN"/);
    });

    it('6. HOD cross-department student creation = DENY (Forbidden 403)', async () => {
      await expect(
        InvitationService.createInvitation(hodUser, {
          name: 'Cross Dept Student',
          instituteId: 'STU-2026-999',
          email: 'cross@alpha.edu',
          role: AppRole.STUDENT,
          departmentId: dept2Id,
        })
      ).rejects.toThrow(/HOD cannot create invitations outside their assigned department/);
    });

    it('7. College Admin can still provision HOD, Faculty, Student', async () => {
      const facResult = await InvitationService.createInvitation(collegeAdminUser, {
        name: 'Legit Faculty',
        instituteId: 'FAC-LEGIT-01',
        email: 'legitfac@alpha.edu',
        role: AppRole.FACULTY,
        departmentId: deptId,
      });
      expect(facResult.user.role).toBe(AppRole.FACULTY);
    });
  });

  // =========================================================================
  // DOMAIN 7: ATTENDANCE AUTHORIZATION FOR HOD
  // =========================================================================
  describe('Domain 7: Attendance Teaching Authorization', () => {
    it('1. HOD without assigned teaching profile cannot mark attendance (Forbidden 403)', async () => {
      await expect(
        AttendanceService.createOrSubmitSession(
          collegeId,
          {
            sectionId: new Types.ObjectId(sectionId) as any,
            subjectId: new Types.ObjectId() as any,
            date: new Date(),
            records: [],
          },
          hodUser.id,
          hodUser
        )
      ).rejects.toThrow(/Authenticated user does not have a linked faculty profile/);
    });

    it('2. Unrelated faculty cannot mark attendance for class assigned to another faculty', async () => {
      const subject = await Subject.create({
        collegeId: new Types.ObjectId(collegeId),
        departmentId: new Types.ObjectId(deptId),
        courseId: new Types.ObjectId(courseId),
        semesterId: new Types.ObjectId(semId),
        name: 'Operating Systems',
        code: 'CS301',
        credits: 4,
        type: 'Theory',
        isActive: true,
      });

      // Timetable entry assigned to facultyDoc (Ada Lovelace)
      const tt = await Timetable.create({
        name: 'CSE Section A Timetable',
        collegeId: new Types.ObjectId(collegeId),
        departmentId: new Types.ObjectId(deptId),
        courseId: new Types.ObjectId(courseId),
        academicYearId: new Types.ObjectId(ayId),
        semesterId: new Types.ObjectId(semId),
        sectionId: new Types.ObjectId(sectionId),
        status: TimetableStatus.PUBLISHED,
        entries: [
          {
            dayOfWeek: TimetableDay.MONDAY,
            startTime: '09:00',
            endTime: '10:00',
            subjectId: subject._id,
            facultyId: facultyDoc._id,
            sessionType: TimetableSessionType.LECTURE,
          },
        ],
      });

      // otherFacultyUser (Charles Babbage) attempts to mark attendance for Ada's timetable entry
      await expect(
        AttendanceService.createOrSubmitSession(
          collegeId,
          {
            timetableId: tt._id.toString() as any,
            timetableEntryId: tt.entries[0]!._id!.toString() as any,
            date: new Date('2026-10-12T09:15:00Z'),
            records: [],
          },
          otherFacultyUser.id,
          otherFacultyUser
        )
      ).rejects.toThrow(/Faculty is not authorized to mark attendance for this class/);
    });
  });

  // =========================================================================
  // DOMAIN 8 & 9: CALENDAR SEPARATION & STUDENT UPCOMING PERIODS
  // =========================================================================
  describe('Domain 8 & 9: Calendar Separation & Student Upcoming Periods', () => {
    let subject: any;

    beforeEach(async () => {
      subject = await Subject.create({
        collegeId: new Types.ObjectId(collegeId),
        departmentId: new Types.ObjectId(deptId),
        courseId: new Types.ObjectId(courseId),
        semesterId: new Types.ObjectId(semId),
        name: 'Database Systems',
        code: 'CS401',
        credits: 4,
        type: 'Theory',
        isActive: true,
      });

      // Create Published Timetable
      await Timetable.create({
        name: 'CSE Section A Timetable',
        collegeId: new Types.ObjectId(collegeId),
        departmentId: new Types.ObjectId(deptId),
        courseId: new Types.ObjectId(courseId),
        academicYearId: new Types.ObjectId(ayId),
        semesterId: new Types.ObjectId(semId),
        sectionId: new Types.ObjectId(sectionId),
        status: TimetableStatus.PUBLISHED,
        entries: [
          {
            dayOfWeek: TimetableDay.MONDAY,
            startTime: '09:00',
            endTime: '10:00',
            subjectId: subject._id,
            subjectName: 'Database Systems',
            facultyId: facultyDoc._id,
            facultyName: 'Prof. Ada Lovelace',
            roomNumber: 'LH-101',
            sessionType: TimetableSessionType.LECTURE,
          },
        ],
      });

      // Create genuine Calendar event
      await CalendarEvent.create({
        collegeId: new Types.ObjectId(collegeId),
        title: 'Midterm Examination Week',
        description: 'Odd semester midterm exams',
        eventType: CalendarEventType.EXAM,
        sourceType: CalendarSourceType.MANUAL,
        scope: CalendarEventScope.COLLEGE,
        startDate: '2026-10-15',
        endDate: '2026-10-20',
        allDay: true,
        createdBy: new Types.ObjectId(collegeAdminUser.id),
        creatorRole: AppRole.COLLEGE_ADMIN,
        creatorName: 'College Admin',
        status: CalendarEventStatus.PUBLISHED,
      });
    });

    it('1. Calendar contains genuine academic events, but NOT timetable classes', async () => {
      const calendarEvents = await AcademicCalendarService.getCalendarForUser(studentUser, {
        startDate: '2026-10-12',
        endDate: '2026-10-18',
      });

      // Midterm exam must appear
      const examEvent = calendarEvents.find((e) => e.eventType === CalendarEventType.EXAM);
      expect(examEvent).toBeDefined();
      expect(examEvent?.title).toBe('Midterm Examination Week');

      // Timetable classes must NOT appear in Calendar
      const timetableEvent = calendarEvents.find((e) => e.sourceType === CalendarSourceType.TIMETABLE || (e.id && e.id.startsWith('derived_timetable_')));
      expect(timetableEvent).toBeUndefined();
    });

    it('2. Student Dashboard retrieves upcoming periods directly from Timetable', async () => {
      const dashboard = await DashboardService.getHomeDashboard(
        studentUser,
        { date: '2026-10-12T08:30:00Z' } // A Monday morning
      );

      expect(dashboard).toBeDefined();
      expect(dashboard.upcoming).toBeDefined();

      // Should contain the Database Systems class from Timetable
      const classItem = dashboard.upcoming.find((u: any) => u.type === 'CLASS');
      expect(classItem).toBeDefined();
      expect(classItem?.title).toBe('Database Systems');
      expect(classItem?.route).toBe('/timetable');
      expect(classItem?.location).toBe('Room LH-101');
    });
  });
});
