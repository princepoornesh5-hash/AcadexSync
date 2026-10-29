import 'dotenv/config';
import fs from 'fs';
import path from 'path';
import { env } from '../config/env';
import { connectDB, disconnectDB } from '../db/connection';
import { PasswordService } from '../services/password.service';
import { AppRole } from '../constants/roles';
import {
  AccountStatus,
  MembershipStatus,
  MembershipType,
  RoleAssignmentStatus,
  AcademicYearStatus,
  SemesterStatus,
  CollegeStatus,
  DepartmentStatus,
  TimetableStatus,
  TimetableDay,
  TimetableTimingMode,
  TimetableSessionType,
  AttendanceStatus,
  AttendanceSessionStatus,
  StudentLifecycleState,
  NoteStatus,
  NoteType,
  NoteLifecycleState,
  NoteVisibility,
  ResourceType,
  InvitationStatus,
} from '../constants/status';
import {
  AssignmentStatus,
  AssignmentType,
  StudentTaskStatus,
  FacultyReviewStatus,
} from '../constants/assignment.constants';
import { AssessmentStatus, AssessmentType, StudentMarkStatus } from '../models/internalAssessment.model';
import {
  AnnouncementStatus,
  AudienceScope,
  NotificationCategory,
  NotificationPriority,
  NotificationStatus,
  NotificationType,
} from '../constants/notification.constants';
import { RequestStatus, StudentRequestType } from '../constants/request.constants';
import {
  AcademicCalendarStatus,
  CalendarEventScope,
  CalendarEventStatus,
  CalendarEventType,
  CalendarRecurrence,
  CalendarSourceType,
} from '../constants/calendar.constants';
import { PracticalSessionStatus } from '../constants/practical.constants';
import { generateActivationCode, hashActivationCode } from '../utils/activationCode';

// Models
import { College } from '../models/college.model';
import { Department } from '../models/department.model';
import { AcademicYear } from '../models/academicYear.model';
import { Course } from '../models/course.model';
import { Semester } from '../models/semester.model';
import { Section } from '../models/section.model';
import { Subject } from '../models/subject.model';
import { Room } from '../models/room.model';
import { User } from '../models/user.model';
import { WorkspaceMembership } from '../models/workspaceMembership.model';
import { WorkspaceRoleAssignment } from '../models/workspaceRoleAssignment.model';
import { Faculty } from '../models/faculty.model';
import { Student } from '../models/student.model';
import { StudentEnrollment } from '../models/studentEnrollment.model';
import { FacultyAssignment } from '../models/facultyAssignment.model';
import { Timetable } from '../models/timetable.model';
import { AttendanceSession } from '../models/attendanceSession.model';
import { AttendanceRecord } from '../models/attendanceRecord.model';
import { Note } from '../models/note.model';
import { Assignment } from '../models/assignment.model';
import { AssignmentSubmission } from '../models/assignmentSubmission.model';
import { InternalAssessment } from '../models/internalAssessment.model';
import { Announcement } from '../models/announcement.model';
import { Notification } from '../models/notification.model';
import { RequestModel } from '../models/request.model';
import { Invitation } from '../models/invitation.model';
import { AcademicCalendar } from '../models/academicCalendar.model';
import { CalendarEvent } from '../models/calendarEvent.model';
import { PracticalSession } from '../models/practicalSession.model';

export interface SeedPolytechnicSummary {
  collegeName: string;
  collegeCode: string;
  counts: Record<string, { created: number; updated: number; total: number }>;
  testAccounts: Array<{ name: string; email: string; role: AppRole; instituteId: string; status: string }>;
  userActivationStatus: {
    email: string;
    accountStatus: AccountStatus;
    hasInvitation: boolean;
    activationCodeReady: boolean;
  };
}

export async function runPolytechnicSeeder(): Promise<SeedPolytechnicSummary> {
  // 1. Safety Guard: Refuse execution in production environment
  if (env.NODE_ENV === 'production') {
    console.error('CRITICAL: Seed execution rejected. Cannot run seed script in production environment.');
    process.exit(1);
  }

  await connectDB();
  console.log('Connected to MongoDB database for ACADEXSYNC Demo Polytechnic seed execution.');

  const isReset = process.argv.includes('--reset');
  const demoCode = 'DEMO-POLY';

  const counts: Record<string, { created: number; updated: number; total: number }> = {};
  const track = (module: string, isNew: boolean) => {
    if (!counts[module]) counts[module] = { created: 0, updated: 0, total: 0 };
    if (isNew) counts[module].created++;
    else counts[module].updated++;
    counts[module].total++;
  };

  let college = await College.findOne({ code: demoCode });

  // 2. Safe Targeted Reset
  if (isReset) {
    console.log('====================================================');
    console.log('RESETTING ACADEXSYNC DEMO POLYTECHNIC (SCOPED)');
    console.log('====================================================');

    if (college) {
      const cId = college._id;
      await Promise.all([
        RequestModel.deleteMany({ collegeId: cId }),
        Notification.deleteMany({ collegeId: cId }),
        Announcement.deleteMany({ collegeId: cId }),
        CalendarEvent.deleteMany({ collegeId: cId }),
        AcademicCalendar.deleteMany({ collegeId: cId }),
        PracticalSession.deleteMany({ collegeId: cId }),
        InternalAssessment.deleteMany({ collegeId: cId }),
        AssignmentSubmission.deleteMany({ collegeId: cId }),
        Assignment.deleteMany({ collegeId: cId }),
        Note.deleteMany({ collegeId: cId }),
        AttendanceRecord.deleteMany({ collegeId: cId }),
        AttendanceSession.deleteMany({ collegeId: cId }),
        Timetable.deleteMany({ collegeId: cId }),
        FacultyAssignment.deleteMany({ collegeId: cId }),
        StudentEnrollment.deleteMany({ collegeId: cId }),
        Student.deleteMany({ collegeId: cId }),
        Faculty.deleteMany({ collegeId: cId }),
        WorkspaceRoleAssignment.deleteMany({ collegeId: cId }),
        WorkspaceMembership.deleteMany({ collegeId: cId }),
        Invitation.deleteMany({ collegeId: cId }),
        Room.deleteMany({ collegeId: cId }),
        Subject.deleteMany({ collegeId: cId }),
        Section.deleteMany({ collegeId: cId }),
        Semester.deleteMany({ collegeId: cId }),
        Course.deleteMany({ collegeId: cId }),
        Department.deleteMany({ collegeId: cId }),
        AcademicYear.deleteMany({ collegeId: cId }),
      ]);

      // Remove demo identities scoped to demo domains or demo PIN prefix
      await User.deleteMany({
        $or: [
          { email: { $regex: /@example\.com$/ } },
          { email: { $regex: /@demo\.acadex\.edu$/ } },
          { instituteId: { $regex: /^DEMO-/ } },
          { instituteId: { $regex: /^26CME/ } },
          { email: 'ragoorupoornesh@gmail.com', collegeId: cId },
        ],
      });

      await College.deleteOne({ _id: cId });
      console.log(`[✓] Cleaned up all records strictly scoped to college "${demoCode}". Real colleges remain untouched.`);
    } else {
      console.log(`No existing "${demoCode}" institution found to reset.`);
    }

    await disconnectDB();
    return {
      collegeName: 'ACADEXSYNC Demo Polytechnic',
      collegeCode: demoCode,
      counts: {},
      testAccounts: [],
      userActivationStatus: {
        email: 'ragoorupoornesh@gmail.com',
        accountStatus: AccountStatus.PENDING_ACTIVATION,
        hasInvitation: false,
        activationCodeReady: false,
      },
    };
  }

  console.log('====================================================');
  console.log('SEEDING ACADEXSYNC DEMO POLYTECHNIC (IDEMPOTENT)');
  console.log('====================================================');

  const defaultPassword = 'acadex123';
  const defaultPasswordHash = await PasswordService.hashPassword(defaultPassword);

  // 3. College Record
  let isCollegeNew = false;
  if (!college) {
    college = await College.create({
      name: 'ACADEXSYNC Demo Polytechnic',
      code: demoCode,
      address: 'Plot 104, Institutional Area, Knowledge City, Hyderabad, Telangana 500081',
      email: 'demo.polytechnic@acadex.edu',
      phone: '+919999900000',
      principal: 'Dr. S. K. Narayana',
      timezone: 'Asia/Kolkata',
      status: CollegeStatus.ACTIVE,
      isActive: true,
      metadata: {
        institutionType: 'Polytechnic',
        isDemoInstitution: true,
        demoTag: 'demo_polytechnic_2026',
        approvedBy: 'State Board of Technical Education and Training (SBTET)',
      },
    });
    isCollegeNew = true;
  } else {
    college.name = 'ACADEXSYNC Demo Polytechnic';
    college.address = 'Plot 104, Institutional Area, Knowledge City, Hyderabad, Telangana 500081';
    college.email = 'demo.polytechnic@acadex.edu';
    college.phone = '+919999900000';
    college.principal = 'Dr. S. K. Narayana';
    college.status = CollegeStatus.ACTIVE;
    college.isActive = true;
    college.metadata = {
      institutionType: 'Polytechnic',
      isDemoInstitution: true,
      demoTag: 'demo_polytechnic_2026',
      approvedBy: 'State Board of Technical Education and Training (SBTET)',
    };
    await college.save();
  }
  track('College', isCollegeNew);
  console.log(`[+] College: ${college.name} (${college.code})`);

  // 4. Academic Years (Current 2026-27 & Historical 2025-26)
  let currentAY = await AcademicYear.findOne({ collegeId: college._id, name: '2026–27' });
  const isAyNew = !currentAY;
  if (!currentAY) {
    currentAY = await AcademicYear.create({
      collegeId: college._id,
      name: '2026–27',
      startDate: new Date('2026-06-01T00:00:00.000Z'),
      endDate: new Date('2027-05-31T23:59:59.000Z'),
      status: AcademicYearStatus.ACTIVE,
      isCurrent: true,
      isActive: true,
    });
  } else {
    currentAY.status = AcademicYearStatus.ACTIVE;
    currentAY.isCurrent = true;
    currentAY.isActive = true;
    await currentAY.save();
  }
  track('AcademicYear', isAyNew);

  let pastAY = await AcademicYear.findOne({ collegeId: college._id, name: '2025–26' });
  const isPastAyNew = !pastAY;
  if (!pastAY) {
    pastAY = await AcademicYear.create({
      collegeId: college._id,
      name: '2025–26',
      startDate: new Date('2025-06-01T00:00:00.000Z'),
      endDate: new Date('2026-05-31T23:59:59.000Z'),
      status: AcademicYearStatus.COMPLETED,
      isCurrent: false,
      isActive: true,
    });
  }
  track('AcademicYear', isPastAyNew);

  // 5. Departments Configuration
  const departmentsConfig = [
    { name: 'Computer Engineering', code: 'CME', courseCode: 'DCME', courseName: 'Diploma in Computer Engineering' },
    { name: 'Electronics and Communication Engineering', code: 'ECE', courseCode: 'DECE', courseName: 'Diploma in Electronics & Communication Engineering' },
    { name: 'Electrical and Electronics Engineering', code: 'EEE', courseCode: 'DEEE', courseName: 'Diploma in Electrical & Electronics Engineering' },
    { name: 'Mechanical Engineering', code: 'MEC', courseCode: 'DMEC', courseName: 'Diploma in Mechanical Engineering' },
    { name: 'Civil Engineering', code: 'CIV', courseCode: 'DCIV', courseName: 'Diploma in Civil Engineering' },
  ];

  const deptMap = new Map<string, any>();
  const courseMap = new Map<string, any>();
  const semesterMap = new Map<string, any>(); // key: CME_5
  const sectionMap = new Map<string, any>();  // key: CME_5_A

  for (const conf of departmentsConfig) {
    let dept = await Department.findOne({ collegeId: college._id, code: conf.code });
    const isDeptNew = !dept;
    if (!dept) {
      dept = await Department.create({
        collegeId: college._id,
        name: conf.name,
        code: conf.code,
        status: DepartmentStatus.ACTIVE,
        isActive: true,
      });
    } else {
      dept.name = conf.name;
      dept.status = DepartmentStatus.ACTIVE;
      dept.isActive = true;
      await dept.save();
    }
    deptMap.set(conf.code, dept);
    track('Department', isDeptNew);

    // Course
    let course = await Course.findOne({ collegeId: college._id, code: conf.courseCode });
    const isCourseNew = !course;
    if (!course) {
      course = await Course.create({
        collegeId: college._id,
        departmentId: dept._id,
        name: conf.courseName,
        code: conf.courseCode,
        durationYears: 3,
        totalSemesters: 6,
        status: 'active',
        isActive: true,
      });
    }
    courseMap.set(conf.code, course);
    track('Course', isCourseNew);

    // Semesters 1 to 6
    for (let semNum = 1; semNum <= 6; semNum++) {
      const semKey = `${conf.code}_${semNum}`;
      let sem = await Semester.findOne({
        collegeId: college._id,
        courseId: course._id,
        number: semNum,
      });
      const isSemNew = !sem;
      const isOdd = semNum % 2 !== 0;
      const isCurrentSem = semNum === 5; // Year 3, Odd Semester for 2026-27

      if (!sem) {
        sem = await Semester.create({
          collegeId: college._id,
          departmentId: dept._id,
          courseId: course._id,
          academicYearId: currentAY._id,
          number: semNum,
          name: `Semester ${semNum}`,
          startDate: isOdd ? new Date('2026-06-15T00:00:00.000Z') : new Date('2026-12-01T00:00:00.000Z'),
          endDate: isOdd ? new Date('2026-11-15T23:59:59.000Z') : new Date('2027-04-30T23:59:59.000Z'),
          status: isCurrentSem ? SemesterStatus.ACTIVE : SemesterStatus.UPCOMING,
          isCurrent: isCurrentSem,
          isActive: true,
        });
      } else {
        sem.status = isCurrentSem ? SemesterStatus.ACTIVE : sem.status;
        sem.isCurrent = isCurrentSem;
        sem.isActive = true;
        await sem.save();
      }
      semesterMap.set(semKey, sem);
      track('Semester', isSemNew);

      // Seed Sections A & B for Semester 5
      if (semNum === 5) {
        for (const secLetter of ['A', 'B']) {
          const secKey = `${conf.code}_5_${secLetter}`;
          let sec = await Section.findOne({
            collegeId: college._id,
            semesterId: sem._id,
            name: secLetter,
          });
          const isSecNew = !sec;
          if (!sec) {
            sec = await Section.create({
              collegeId: college._id,
              departmentId: dept._id,
              courseId: course._id,
              semesterId: sem._id,
              academicYearId: currentAY._id,
              name: secLetter,
              capacity: 60,
              status: 'active',
              isActive: true,
            });
          }
          sectionMap.set(secKey, sec);
          track('Section', isSecNew);
        }
      }
    }
  }

  // 6. Subjects for CME Semester 5
  const cmeDept = deptMap.get('CME');
  const cmeCourse = courseMap.get('CME');
  const cmeSem5 = semesterMap.get('CME_5');
  const cmeSecA = sectionMap.get('CME_5_A');

  const cmeSubjectsConfig = [
    { code: 'CME-501', name: 'Database Management Systems', type: 'THEORY', credits: 4, hoursPerWeek: 4, maxMarks: 100 },
    { code: 'CME-502', name: 'Computer Networks', type: 'THEORY', credits: 4, hoursPerWeek: 4, maxMarks: 100 },
    { code: 'CME-503', name: 'Operating Systems', type: 'THEORY', credits: 4, hoursPerWeek: 4, maxMarks: 100 },
    { code: 'CME-504', name: 'Web Technologies', type: 'THEORY', credits: 4, hoursPerWeek: 4, maxMarks: 100 },
    { code: 'CME-505', name: 'DBMS & Web Technologies Lab', type: 'PRACTICAL', credits: 2, hoursPerWeek: 3, maxMarks: 50 },
  ];

  const subjectMap = new Map<string, any>();
  for (const s of cmeSubjectsConfig) {
    let subj = await Subject.findOne({ collegeId: college._id, code: s.code });
    const isSubjNew = !subj;
    if (!subj) {
      subj = await Subject.create({
        collegeId: college._id,
        departmentId: cmeDept._id,
        courseId: cmeCourse._id,
        semesterId: cmeSem5._id,
        code: s.code,
        name: s.name,
        type: s.type === 'THEORY' ? 'Theory' : 'Practical',
        credits: s.credits,
        isActive: true,
      });
    }
    subjectMap.set(s.code, subj);
    track('Subject', isSubjNew);
  }

  // 7. Rooms
  const roomsConfig = [
    { code: 'ROOM-101', name: 'Room 101', building: 'Academic Block A', capacity: 60, type: 'lecture' },
    { code: 'ROOM-102', name: 'Room 102', building: 'Academic Block A', capacity: 60, type: 'lecture' },
    { code: 'LAB-1', name: 'Lab 1', building: 'Computing Center', capacity: 45, type: 'lab' },
    { code: 'SEM-HALL', name: 'Seminar Hall', building: 'Main Administrative Block', capacity: 150, type: 'seminar' },
  ];

  const roomMap = new Map<string, any>();
  for (const r of roomsConfig) {
    let room = await Room.findOne({ collegeId: college._id, code: r.code });
    const isRoomNew = !room;
    if (!room) {
      room = await Room.create({
        collegeId: college._id,
        name: r.name,
        code: r.code,
        building: r.building,
        capacity: r.capacity,
        type: r.type,
        status: 'active',
        isActive: true,
      });
    }
    roomMap.set(r.name, room);
    track('Room', isRoomNew);
  }

  // 8. Academic Calendar & Holidays
  let academicCal = await AcademicCalendar.findOne({ collegeId: college._id, academicYearId: currentAY._id });
  const isCalNew = !academicCal;
  if (!academicCal) {
    academicCal = await AcademicCalendar.create({
      collegeId: college._id,
      academicYearId: currentAY._id,
      title: 'Academic Calendar 2026–27 (Diploma Programs)',
      description: 'Official academic schedule for Odd and Even semesters including assessments and breaks.',
      startDate: '2026-06-15',
      endDate: '2027-04-30',
      status: AcademicCalendarStatus.ACTIVE,
      workingDays: [1, 2, 3, 4, 5, 6],
      holidays: [
        { date: '2026-08-15', name: 'Independence Day', isFullDay: true },
        { date: '2026-10-02', name: 'Gandhi Jayanti', isFullDay: true },
        { date: '2026-10-20', name: 'Dussehra / Vijayadashami Break', isFullDay: true },
        { date: '2026-11-09', name: 'Diwali Festival Break', isFullDay: true },
        { date: '2027-01-26', name: 'Republic Day', isFullDay: true },
      ],
      createdBy: college._id,
    });
  }
  track('AcademicCalendar', isCalNew);

  // 9. College Admin Test Account
  let collegeAdmin = await User.findOne({ email: 'admin.demo@example.com' });
  const isAdmNew = !collegeAdmin;
  if (!collegeAdmin) {
    collegeAdmin = await User.create({
      collegeId: college._id,
      name: 'Prof. Rajesh Sharma (College Admin)',
      email: 'admin.demo@example.com',
      phone: '+919999900001',
      instituteId: 'DEMO-ADM-001',
      passwordHash: defaultPasswordHash,
      role: AppRole.COLLEGE_ADMIN,
      accountStatus: AccountStatus.ACTIVE,
      activationStatus: 'activated',
      termsAccepted: true,
      termsAcceptedVersion: '1.0',
    });
  } else {
    collegeAdmin.collegeId = college._id;
    collegeAdmin.passwordHash = defaultPasswordHash;
    collegeAdmin.accountStatus = AccountStatus.ACTIVE;
    await collegeAdmin.save();
  }
  track('User', isAdmNew);

  let adminMembership = await WorkspaceMembership.findOne({ userId: collegeAdmin._id, collegeId: college._id });
  const isAdmMemNew = !adminMembership;
  if (!adminMembership) {
    adminMembership = await WorkspaceMembership.create({
      userId: collegeAdmin._id,
      collegeId: college._id,
      instituteId: 'DEMO-ADM-001',
      memberType: MembershipType.ADMINISTRATOR,
      status: MembershipStatus.ACTIVE,
      isDefault: true,
      title: 'Principal & College Admin',
      joinedAt: new Date(),
    });
  } else {
    adminMembership.status = MembershipStatus.ACTIVE;
    await adminMembership.save();
  }
  track('WorkspaceMembership', isAdmMemNew);

  let adminRoleAssignment = await WorkspaceRoleAssignment.findOne({ membershipId: adminMembership._id, role: AppRole.COLLEGE_ADMIN });
  const isAdmRaNew = !adminRoleAssignment;
  if (!adminRoleAssignment) {
    adminRoleAssignment = await WorkspaceRoleAssignment.create({
      membershipId: adminMembership._id,
      userId: collegeAdmin._id,
      collegeId: college._id,
      role: AppRole.COLLEGE_ADMIN,
      status: RoleAssignmentStatus.ACTIVE,
      assignedAt: new Date(),
    });
  }
  track('WorkspaceRoleAssignment', isAdmRaNew);

  // 10. Department HODs
  const hodsConfig = [
    { email: 'hod.cme.demo@example.com', name: 'Dr. K. V. Ramanathan', deptCode: 'CME', instId: 'DEMO-HOD-CME-01', phone: '+919999900010' },
    { email: 'hod.ece.demo@example.com', name: 'Dr. P. Aruna', deptCode: 'ECE', instId: 'DEMO-HOD-ECE-01', phone: '+919999900011' },
    { email: 'hod.civ.demo@example.com', name: 'Dr. S. Bhaskar', deptCode: 'CIV', instId: 'DEMO-HOD-CIV-01', phone: '+919999900012' },
  ];

  const hodUserMap = new Map<string, any>();
  for (const h of hodsConfig) {
    const dept = deptMap.get(h.deptCode);
    let hodUser = await User.findOne({ email: h.email });
    const isHodNew = !hodUser;
    if (!hodUser) {
      hodUser = await User.create({
        collegeId: college._id,
        departmentId: dept._id,
        name: h.name,
        email: h.email,
        phone: h.phone,
        instituteId: h.instId,
        passwordHash: defaultPasswordHash,
        role: AppRole.HOD,
        accountStatus: AccountStatus.ACTIVE,
        activationStatus: 'activated',
        termsAccepted: true,
        termsAcceptedVersion: '1.0',
      });
    } else {
      hodUser.collegeId = college._id;
      hodUser.departmentId = dept._id;
      hodUser.passwordHash = defaultPasswordHash;
      hodUser.accountStatus = AccountStatus.ACTIVE;
      await hodUser.save();
    }
    track('User', isHodNew);
    hodUserMap.set(h.deptCode, hodUser);

    // Link dept hodId
    dept.hodId = hodUser._id.toString();
    await dept.save();

    // Membership & Role Assignment
    let mem = await WorkspaceMembership.findOne({ userId: hodUser._id, collegeId: college._id });
    const isHodMemNew = !mem;
    if (!mem) {
      mem = await WorkspaceMembership.create({
        userId: hodUser._id,
        collegeId: college._id,
        instituteId: h.instId,
        memberType: MembershipType.FACULTY,
        status: MembershipStatus.ACTIVE,
        isDefault: true,
        title: `Head of Department (${h.deptCode})`,
      });
    }
    track('WorkspaceMembership', isHodMemNew);

    let ra = await WorkspaceRoleAssignment.findOne({ membershipId: mem._id, role: AppRole.HOD });
    const isHodRaNew = !ra;
    if (!ra) {
      ra = await WorkspaceRoleAssignment.create({
        membershipId: mem._id,
        userId: hodUser._id,
        collegeId: college._id,
        departmentId: dept._id,
        role: AppRole.HOD,
        status: RoleAssignmentStatus.ACTIVE,
      });
    }
    track('WorkspaceRoleAssignment', isHodRaNew);

    // Faculty profile for HOD
    let facProfile = await Faculty.findOne({ userId: hodUser._id });
    const isFacProfNew = !facProfile;
    if (!facProfile) {
      facProfile = await Faculty.create({
        collegeId: college._id,
        departmentId: dept._id,
        userId: hodUser._id,
        instituteId: h.instId,
        name: h.name,
        email: h.email,
        phone: h.phone,
        employeeId: h.instId,
        designation: 'Professor & Head of Department',
        status: 'active',
        isActive: true,
      });
    }
    track('Faculty', isFacProfNew);
  }

  // 11. CME Faculty Members
  const facultyConfig = [
    { email: 'faculty.cme01.demo@example.com', name: 'Prof. Ananya Sen', deptCode: 'CME', instId: 'DEMO-FAC-CME-01', desig: 'Associate Professor', phone: '+919999900021' },
    { email: 'faculty.cme02.demo@example.com', name: 'Prof. Vikram Malhotra', deptCode: 'CME', instId: 'DEMO-FAC-CME-02', desig: 'Assistant Professor', phone: '+919999900022' },
  ];

  const facultyDocMap = new Map<string, any>();
  for (const f of facultyConfig) {
    const dept = deptMap.get(f.deptCode);
    let facUser = await User.findOne({ email: f.email });
    const isFacUserNew = !facUser;
    if (!facUser) {
      facUser = await User.create({
        collegeId: college._id,
        departmentId: dept._id,
        name: f.name,
        email: f.email,
        phone: f.phone,
        instituteId: f.instId,
        passwordHash: defaultPasswordHash,
        role: AppRole.FACULTY,
        accountStatus: AccountStatus.ACTIVE,
        activationStatus: 'activated',
        termsAccepted: true,
        termsAcceptedVersion: '1.0',
      });
    }
    track('User', isFacUserNew);

    let mem = await WorkspaceMembership.findOne({ userId: facUser._id, collegeId: college._id });
    const isFacMemNew = !mem;
    if (!mem) {
      mem = await WorkspaceMembership.create({
        userId: facUser._id,
        collegeId: college._id,
        instituteId: f.instId,
        memberType: MembershipType.FACULTY,
        status: MembershipStatus.ACTIVE,
        isDefault: true,
        title: f.desig,
      });
    }
    track('WorkspaceMembership', isFacMemNew);

    let ra = await WorkspaceRoleAssignment.findOne({ membershipId: mem._id, role: AppRole.FACULTY });
    const isFacRaNew = !ra;
    if (!ra) {
      ra = await WorkspaceRoleAssignment.create({
        membershipId: mem._id,
        userId: facUser._id,
        collegeId: college._id,
        departmentId: dept._id,
        role: AppRole.FACULTY,
        status: RoleAssignmentStatus.ACTIVE,
      });
    }
    track('WorkspaceRoleAssignment', isFacRaNew);

    let facDoc = await Faculty.findOne({ userId: facUser._id });
    const isFacDocNew = !facDoc;
    if (!facDoc) {
      facDoc = await Faculty.create({
        collegeId: college._id,
        departmentId: dept._id,
        userId: facUser._id,
        instituteId: f.instId,
        name: f.name,
        email: f.email,
        phone: f.phone,
        employeeId: f.instId,
        designation: f.desig,
        status: 'active',
        isActive: true,
      });
    }
    track('Faculty', isFacDocNew);
    facultyDocMap.set(f.email, facDoc);
  }

  // 12. Teaching Allocations / Faculty Assignments
  const fac1 = facultyDocMap.get('faculty.cme01.demo@example.com');
  const fac2 = facultyDocMap.get('faculty.cme02.demo@example.com');

  const cmeAssignments = [
    { faculty: fac1, subjCode: 'CME-501', stage: '3rd Year', cohort: '2024–27' },
    { faculty: fac1, subjCode: 'CME-502', stage: '3rd Year', cohort: '2024–27' },
    { faculty: fac2, subjCode: 'CME-503', stage: '3rd Year', cohort: '2024–27' },
    { faculty: fac2, subjCode: 'CME-504', stage: '3rd Year', cohort: '2024–27' },
    { faculty: fac2, subjCode: 'CME-505', stage: '3rd Year', cohort: '2024–27' },
  ];

  const facultyAssignmentMap = new Map<string, any>();
  for (const a of cmeAssignments) {
    const subj = subjectMap.get(a.subjCode);
    let fa = await FacultyAssignment.findOne({
      collegeId: college._id,
      departmentId: cmeDept._id,
      subjectId: subj._id,
      sectionId: cmeSecA._id,
    });
    const isFaNew = !fa;
    if (!fa) {
      fa = await FacultyAssignment.create({
        collegeId: college._id,
        departmentId: cmeDept._id,
        courseId: cmeCourse._id,
        semesterId: cmeSem5._id,
        sectionId: cmeSecA._id,
        subjectId: subj._id,
        facultyId: a.faculty._id,
        facultyName: a.faculty.name,
        academicYearId: currentAY._id,
        academicStage: a.stage,
        cohort: a.cohort,
        status: 'active',
        isActive: true,
        assignedAt: new Date(),
      });
    }
    track('FacultyAssignment', isFaNew);
    facultyAssignmentMap.set(a.subjCode, fa);
  }

  // 13. CME Students (Including Ragooru Poornesh for Real Activation Test)
  const studentsConfig = [
    {
      name: 'Ragooru Poornesh',
      email: 'ragoorupoornesh@gmail.com',
      roll: '26CME001',
      phone: '+919999900031',
      isTargetUser: true,
    },
    {
      name: 'Arjun Mehta',
      email: 'student.cme02.demo@example.com',
      roll: '26CME002',
      phone: '+919999900032',
      isTargetUser: false,
    },
    {
      name: 'Sneha Reddy',
      email: 'student.cme03.demo@example.com',
      roll: '26CME003',
      phone: '+919999900033',
      isTargetUser: false,
    },
    {
      name: 'Rohan Verma',
      email: 'student.cme04.demo@example.com',
      roll: '26CME004',
      phone: '+919999900034',
      isTargetUser: false,
    },
    {
      name: 'Deepika Iyer',
      email: 'student.cme05.demo@example.com',
      roll: '26CME005',
      phone: '+919999900035',
      isTargetUser: false,
    },
    {
      name: 'Kiran Kumar',
      email: 'student.cme06.demo@example.com',
      roll: '26CME006',
      phone: '+919999900036',
      isTargetUser: false,
    },
  ];

  const studentDocs: any[] = [];
  let targetUserActivationCode: string | null = null;
  let targetUserAccountStatus = AccountStatus.PENDING_ACTIVATION;

  for (const s of studentsConfig) {
    let stuUser = await User.findOne({ email: s.email });
    const isStuUserNew = !stuUser;

    if (!stuUser) {
      if (s.isTargetUser) {
        // Target account for activation test: PENDING_ACTIVATION
        stuUser = await User.create({
          collegeId: college._id,
          departmentId: cmeDept._id,
          name: s.name,
          email: s.email,
          phone: s.phone,
          instituteId: s.roll,
          role: AppRole.STUDENT,
          passwordHash: null,
          accountStatus: AccountStatus.PENDING_ACTIVATION,
          activationStatus: 'pending',
        });
      } else {
        // Regular active demo students
        stuUser = await User.create({
          collegeId: college._id,
          departmentId: cmeDept._id,
          name: s.name,
          email: s.email,
          phone: s.phone,
          instituteId: s.roll,
          passwordHash: defaultPasswordHash,
          role: AppRole.STUDENT,
          accountStatus: AccountStatus.ACTIVE,
          activationStatus: 'activated',
          termsAccepted: true,
          termsAcceptedVersion: '1.0',
        });
      }
    } else {
      stuUser.collegeId = college._id;
      stuUser.departmentId = cmeDept._id;
      stuUser.instituteId = s.roll;
      stuUser.name = s.name;
      stuUser.phone = s.phone;
      if (!s.isTargetUser) {
        stuUser.passwordHash = defaultPasswordHash;
        stuUser.accountStatus = AccountStatus.ACTIVE;
      }
      await stuUser.save();
    }
    track('User', isStuUserNew);

    if (s.isTargetUser) {
      targetUserAccountStatus = stuUser.accountStatus;
    }

    // Membership
    let mem = await WorkspaceMembership.findOne({ userId: stuUser._id, collegeId: college._id });
    const isStuMemNew = !mem;
    if (!mem) {
      mem = await WorkspaceMembership.create({
        userId: stuUser._id,
        collegeId: college._id,
        instituteId: s.roll,
        memberType: MembershipType.STUDENT,
        status: stuUser.accountStatus === AccountStatus.ACTIVE ? MembershipStatus.ACTIVE : MembershipStatus.PENDING,
        isDefault: true,
        title: `Student (${s.roll})`,
        joinedAt: new Date(),
      });
    }
    track('WorkspaceMembership', isStuMemNew);

    // Role Assignment
    let ra = await WorkspaceRoleAssignment.findOne({ membershipId: mem._id, role: AppRole.STUDENT });
    const isStuRaNew = !ra;
    if (!ra) {
      ra = await WorkspaceRoleAssignment.create({
        membershipId: mem._id,
        userId: stuUser._id,
        collegeId: college._id,
        departmentId: cmeDept._id,
        role: AppRole.STUDENT,
        status: mem.status === MembershipStatus.ACTIVE ? RoleAssignmentStatus.ACTIVE : RoleAssignmentStatus.PENDING,
      });
    }
    track('WorkspaceRoleAssignment', isStuRaNew);

    // Student Profile
    let stuDoc = await Student.findOne({ userId: stuUser._id });
    const isStuDocNew = !stuDoc;
    if (!stuDoc) {
      stuDoc = await Student.create({
        collegeId: college._id,
        departmentId: cmeDept._id,
        userId: stuUser._id,
        name: s.name,
        rollNumber: s.roll,
        admissionNumber: `ADM-${s.roll}`,
        email: s.email,
        phone: s.phone,
        courseId: cmeCourse._id,
        academicYearId: currentAY._id,
        semesterId: cmeSem5._id,
        sectionId: cmeSecA._id,
        cohort: '2024–27',
        academicStage: '3rd Year',
        lifecycleState: StudentLifecycleState.ACTIVE,
        status: 'active',
        isActive: true,
      });
    }
    track('Student', isStuDocNew);
    studentDocs.push(stuDoc);

    // Enrollment
    let enrollment = await StudentEnrollment.findOne({
      collegeId: college._id,
      studentId: stuDoc._id,
      sectionId: cmeSecA._id,
    });
    const isEnrNew = !enrollment;
    if (!enrollment) {
      enrollment = await StudentEnrollment.create({
        collegeId: college._id,
        departmentId: cmeDept._id,
        studentId: stuDoc._id,
        courseId: cmeCourse._id,
        semesterId: cmeSem5._id,
        sectionId: cmeSecA._id,
        academicYearId: currentAY._id,
        cohort: '2024–27',
        academicStage: '3rd Year',
        status: 'active',
      });
    }
    track('StudentEnrollment', isEnrNew);

    // If target test account and in pending activation, ensure Invitation exists
    if (s.isTargetUser && stuUser.accountStatus === AccountStatus.PENDING_ACTIVATION) {
      let inv = await Invitation.findOne({
        userId: stuUser._id,
        collegeId: college._id,
        status: InvitationStatus.PENDING,
      });

      const scratchDir = '/Users/poornesh/.gemini/antigravity/brain/9b210023-f19b-4371-b0b1-e7222561dba6/scratch';
      const codeFilePath = path.join(scratchDir, 'demo_activation_code.txt');

      if (!inv || inv.isExpired()) {
        const rawCode = generateActivationCode();
        const codeHash = hashActivationCode(rawCode);
        const expiresAt = new Date(Date.now() + 7 * 86400000); // 7 days

        if (inv) {
          inv.codeHash = codeHash;
          inv.expiresAt = expiresAt;
          inv.status = InvitationStatus.PENDING;
          await inv.save();
        } else {
          inv = await Invitation.create({
            userId: stuUser._id,
            collegeId: college._id,
            departmentId: cmeDept._id,
            role: AppRole.STUDENT,
            codeHash,
            status: InvitationStatus.PENDING,
            expiresAt,
            createdBy: collegeAdmin._id,
            lastSentAt: new Date(),
          });
        }
        track('Invitation', true);
        targetUserActivationCode = rawCode;

        // Persist code safely to private conversation scratch for test execution
        try {
          if (!fs.existsSync(scratchDir)) fs.mkdirSync(scratchDir, { recursive: true });
          fs.writeFileSync(codeFilePath, rawCode, 'utf8');
        } catch {}
      } else {
        track('Invitation', false);
        // Try reading existing raw code if cached in scratch
        try {
          if (fs.existsSync(codeFilePath)) {
            targetUserActivationCode = fs.readFileSync(codeFilePath, 'utf8').trim();
          }
        } catch {}
      }
    }
  }

  // 14. Published Timetable for CME Section A
  let timetable = await Timetable.findOne({
    collegeId: college._id,
    sectionId: cmeSecA._id,
    semesterId: cmeSem5._id,
  });
  const isTtNew = !timetable;

  const dbmsAssignment = facultyAssignmentMap.get('CME-501');
  const cnAssignment = facultyAssignmentMap.get('CME-502');
  const osAssignment = facultyAssignmentMap.get('CME-503');
  const webAssignment = facultyAssignmentMap.get('CME-504');
  const labAssignment = facultyAssignmentMap.get('CME-505');

  const timetableEntries = [
    // Monday
    { dayOfWeek: TimetableDay.MONDAY, startTime: '09:00', endTime: '10:00', subjectId: subjectMap.get('CME-501')._id, facultyId: fac1._id, facultyAssignmentId: dbmsAssignment._id, roomNumber: '101', building: 'Academic Block A', sessionType: TimetableSessionType.LECTURE },
    { dayOfWeek: TimetableDay.MONDAY, startTime: '10:00', endTime: '11:00', subjectId: subjectMap.get('CME-502')._id, facultyId: fac1._id, facultyAssignmentId: cnAssignment._id, roomNumber: '101', building: 'Academic Block A', sessionType: TimetableSessionType.LECTURE },
    { dayOfWeek: TimetableDay.MONDAY, startTime: '11:15', endTime: '12:15', subjectId: subjectMap.get('CME-503')._id, facultyId: fac2._id, facultyAssignmentId: osAssignment._id, roomNumber: '101', building: 'Academic Block A', sessionType: TimetableSessionType.LECTURE },
    // Tuesday
    { dayOfWeek: TimetableDay.TUESDAY, startTime: '09:00', endTime: '10:00', subjectId: subjectMap.get('CME-504')._id, facultyId: fac2._id, facultyAssignmentId: webAssignment._id, roomNumber: '101', building: 'Academic Block A', sessionType: TimetableSessionType.LECTURE },
    { dayOfWeek: TimetableDay.TUESDAY, startTime: '10:00', endTime: '11:00', subjectId: subjectMap.get('CME-501')._id, facultyId: fac1._id, facultyAssignmentId: dbmsAssignment._id, roomNumber: '101', building: 'Academic Block A', sessionType: TimetableSessionType.LECTURE },
    { dayOfWeek: TimetableDay.TUESDAY, startTime: '13:15', endTime: '16:15', subjectId: subjectMap.get('CME-505')._id, facultyId: fac2._id, facultyAssignmentId: labAssignment._id, roomNumber: 'Lab 1', building: 'Computing Center', sessionType: TimetableSessionType.LAB },
    // Wednesday
    { dayOfWeek: TimetableDay.WEDNESDAY, startTime: '09:00', endTime: '10:00', subjectId: subjectMap.get('CME-502')._id, facultyId: fac1._id, facultyAssignmentId: cnAssignment._id, roomNumber: '101', building: 'Academic Block A', sessionType: TimetableSessionType.LECTURE },
    { dayOfWeek: TimetableDay.WEDNESDAY, startTime: '10:00', endTime: '11:00', subjectId: subjectMap.get('CME-503')._id, facultyId: fac2._id, facultyAssignmentId: osAssignment._id, roomNumber: '101', building: 'Academic Block A', sessionType: TimetableSessionType.LECTURE },
    // Thursday
    { dayOfWeek: TimetableDay.THURSDAY, startTime: '09:00', endTime: '10:00', subjectId: subjectMap.get('CME-501')._id, facultyId: fac1._id, facultyAssignmentId: dbmsAssignment._id, roomNumber: '101', building: 'Academic Block A', sessionType: TimetableSessionType.LECTURE },
    { dayOfWeek: TimetableDay.THURSDAY, startTime: '10:00', endTime: '11:00', subjectId: subjectMap.get('CME-504')._id, facultyId: fac2._id, facultyAssignmentId: webAssignment._id, roomNumber: '101', building: 'Academic Block A', sessionType: TimetableSessionType.LECTURE },
    // Friday
    { dayOfWeek: TimetableDay.FRIDAY, startTime: '09:00', endTime: '10:00', subjectId: subjectMap.get('CME-502')._id, facultyId: fac1._id, facultyAssignmentId: cnAssignment._id, roomNumber: '101', building: 'Academic Block A', sessionType: TimetableSessionType.LECTURE },
    { dayOfWeek: TimetableDay.FRIDAY, startTime: '10:00', endTime: '11:00', subjectId: subjectMap.get('CME-503')._id, facultyId: fac2._id, facultyAssignmentId: osAssignment._id, roomNumber: '101', building: 'Academic Block A', sessionType: TimetableSessionType.LECTURE },
    // Saturday
    { dayOfWeek: TimetableDay.SATURDAY, startTime: '09:00', endTime: '10:00', subjectId: subjectMap.get('CME-504')._id, facultyId: fac2._id, facultyAssignmentId: webAssignment._id, roomNumber: '101', building: 'Academic Block A', sessionType: TimetableSessionType.LECTURE },
  ];

  if (!timetable) {
    timetable = await Timetable.create({
      collegeId: college._id,
      departmentId: cmeDept._id,
      courseId: cmeCourse._id,
      academicYearId: currentAY._id,
      semesterId: cmeSem5._id,
      sectionId: cmeSecA._id,
      name: 'Class CME-5A Timetable 2026-27',
      status: TimetableStatus.PUBLISHED,
      version: 1,
      activeDays: [
        TimetableDay.MONDAY,
        TimetableDay.TUESDAY,
        TimetableDay.WEDNESDAY,
        TimetableDay.THURSDAY,
        TimetableDay.FRIDAY,
        TimetableDay.SATURDAY,
      ],
      timingMode: TimetableTimingMode.SAME_EVERY_DAY,
      periods: [],
      breaks: [],
      entries: timetableEntries,
      publishedAt: new Date(),
    });
  } else {
    timetable.status = TimetableStatus.PUBLISHED;
    timetable.entries = timetableEntries as any;
    await timetable.save();
  }
  track('Timetable', isTtNew);

  // 15. Attendance Sessions & Student Records (Past 14 Days)
  const dbmsSubj = subjectMap.get('CME-501');
  const now = new Date();

  for (let d = 14; d >= 0; d--) {
    const sessionDate = new Date(now);
    sessionDate.setDate(now.getDate() - d);
    sessionDate.setHours(9, 0, 0, 0);

    // Skip Sundays
    if (sessionDate.getDay() === 0) continue;

    const timeSlot = '09:00 - 10:00';
    const startOfDay = new Date(sessionDate);
    startOfDay.setUTCHours(0, 0, 0, 0);
    const endOfDay = new Date(sessionDate);
    endOfDay.setUTCHours(23, 59, 59, 999);

    let attSession = await AttendanceSession.findOne({
      collegeId: college._id,
      sectionId: cmeSecA._id,
      subjectId: dbmsSubj._id,
      date: { $gte: startOfDay, $lte: endOfDay },
    });

    const records = studentDocs.map((stu, idx) => {
      // Varied attendance distributions:
      // idx 0 (Ragooru Poornesh): absent on d=7 (~92% attendance)
      // idx 1 (Arjun Mehta): 100% present
      // idx 2 (Sneha Reddy): absent on d=3, 10 (~85% attendance)
      // idx 3 (Rohan Verma): absent on d=2, 6, 12 (~77% attendance)
      // idx 4 (Deepika Iyer): absent on d=8 (~92% attendance)
      // idx 5 (Kiran Kumar): absent on d=1, 4, 9, 13 (~69% attendance)
      let isAbsent = false;
      if (idx === 0 && d === 7) isAbsent = true;
      else if (idx === 2 && (d === 3 || d === 10)) isAbsent = true;
      else if (idx === 3 && (d === 2 || d === 6 || d === 12)) isAbsent = true;
      else if (idx === 4 && d === 8) isAbsent = true;
      else if (idx === 5 && (d === 1 || d === 4 || d === 9 || d === 13)) isAbsent = true;

      return {
        studentId: stu._id,
        studentName: stu.name,
        rollNumber: stu.rollNumber,
        sectionId: cmeSecA._id,
        status: isAbsent ? AttendanceStatus.ABSENT : AttendanceStatus.PRESENT,
      };
    });

    const isAttSessionNew = !attSession;
    if (!attSession) {
      attSession = await AttendanceSession.create({
        collegeId: college._id,
        departmentId: cmeDept._id,
        courseId: cmeCourse._id,
        academicYearId: currentAY._id,
        semesterId: cmeSem5._id,
        sectionId: cmeSecA._id,
        sectionName: 'A',
        facultyId: fac1._id,
        facultyAssignmentId: dbmsAssignment._id,
        subjectId: dbmsSubj._id,
        subjectName: dbmsSubj.name,
        timeSlot,
        date: sessionDate,
        records,
        roomNumber: '101',
        building: 'Academic Block A',
        status: AttendanceSessionStatus.LOCKED,
        isSubmitted: true,
        isLocked: true,
        version: 1,
      });

      for (const rec of records) {
        await AttendanceRecord.create({
          collegeId: college._id,
          departmentId: cmeDept._id,
          sessionId: attSession._id,
          studentId: rec.studentId,
          studentName: rec.studentName,
          rollNumber: rec.rollNumber,
          sectionId: cmeSecA._id,
          subjectId: dbmsSubj._id,
          courseId: cmeCourse._id,
          academicYearId: currentAY._id,
          semesterId: cmeSem5._id,
          facultyId: fac1._id,
          date: sessionDate,
          timeSlot,
          status: rec.status,
          isCancelled: false,
        });
        track('AttendanceRecord', true);
      }
    }
    track('AttendanceSession', isAttSessionNew);
  }

  // 16. Practical Session (Lab)
  let practicalSession = await PracticalSession.findOne({
    collegeId: college._id,
    subjectId: subjectMap.get('CME-505')._id,
    sessionNumber: 1,
  });
  const isPracNew = !practicalSession;
  if (!practicalSession) {
    practicalSession = await PracticalSession.create({
      collegeId: college._id,
      departmentId: cmeDept._id,
      courseId: cmeCourse._id,
      academicYearId: currentAY._id,
      semesterId: cmeSem5._id,
      sectionId: cmeSecA._id,
      subjectId: subjectMap.get('CME-505')._id,
      facultyAssignmentId: labAssignment._id,
      facultyId: fac2._id,
      sessionNumber: 1,
      topic: 'Experiment 1: Database Schema Creation, Integrity Constraints, and DDL Commands',
      instructions: 'Create tables for student database with primary key, foreign key, check constraints, and load sample records.',
      scheduledDate: new Date(Date.now() - 2 * 86400000),
      startTime: '13:15',
      endTime: '16:15',
      status: PracticalSessionStatus.COMPLETED,
      totalEnrolled: studentDocs.length,
      completedCount: studentDocs.length,
      inProgressCount: 0,
      absentCount: 0,
      roomNumber: 'Lab 1',
      building: 'Computing Center',
    });
  }
  track('PracticalSession', isPracNew);

  // 17. Curriculum Notes & Academic Materials
  const notesConfig = [
    {
      title: 'Unit 1: Relational Database Architecture & ER Modeling',
      description: 'Comprehensive study notes on entity-relationship diagrams, cardinalities, relational models, and relational algebra.',
      subj: subjectMap.get('CME-501'),
      chapter: 'Unit 1',
    },
    {
      title: 'Unit 2: SQL Mastery & Advanced Normalization (1NF to BCNF)',
      description: 'Practical guide to SQL queries, joins, subqueries, functional dependencies, and lossless decomposition.',
      subj: subjectMap.get('CME-501'),
      chapter: 'Unit 2',
    },
    {
      title: 'Unit 1: Computer Network Fundamentals & OSI vs TCP/IP',
      description: 'Detailed analysis of protocol stacks, network topologies, physical layers, and framing protocols.',
      subj: subjectMap.get('CME-502'),
      chapter: 'Unit 1',
    },
    {
      title: 'Unit 1: Operating System Structures & Process Management',
      description: 'In-depth coverage of OS architecture, system calls, process scheduling algorithms, and inter-process communication.',
      subj: subjectMap.get('CME-503'),
      chapter: 'Unit 1',
    },
  ];

  for (const n of notesConfig) {
    let noteDoc = await Note.findOne({ collegeId: college._id, title: n.title });
    const isNoteNew = !noteDoc;
    if (!noteDoc) {
      noteDoc = await Note.create({
        collegeId: college._id,
        departmentId: cmeDept._id,
        courseId: cmeCourse._id,
        academicYearId: currentAY._id,
        semesterId: cmeSem5._id,
        sectionId: cmeSecA._id,
        subjectId: n.subj._id,
        facultyId: fac1._id,
        facultyAssignmentId: dbmsAssignment._id,
        authorUserId: fac1.userId,
        title: n.title,
        description: n.description,
        noteType: NoteType.STUDY_MATERIAL,
        visibility: NoteVisibility.PUBLIC,
        lifecycleState: NoteLifecycleState.READY,
        status: NoteStatus.PUBLISHED,
        resourceType: ResourceType.FILE_ATTACHMENT,
        storageProvider: 'IMAGEKIT',
        originalFileName: `${n.title.substring(0, 20)}.pdf`,
        storageKey: `demo/notes/${n.subj.code}_${Date.now()}.pdf`,
        fileId: `file_${Date.now()}`,
        fileUrl: 'https://ik.imagekit.io/AcadexAi/demo_study_material.pdf',
        mimeType: 'application/pdf',
        fileExtension: 'pdf',
        fileSize: 1048576,
        version: 1,
        previousVersions: [],
        chapter: n.chapter,
        publishedAt: new Date(),
      });
    }
    track('Note', isNoteNew);
  }

  // 18. Course Assignments & Submissions
  let assignment1 = await Assignment.findOne({
    collegeId: college._id,
    subjectId: dbmsSubj._id,
    title: 'Assignment 1: Complex SQL Queries & Database Schema Design',
  });
  const isAsg1New = !assignment1;
  if (!assignment1) {
    const dueDate = new Date(Date.now() + 7 * 86400000);
    assignment1 = await Assignment.create({
      collegeId: college._id,
      departmentId: cmeDept._id,
      courseId: cmeCourse._id,
      academicYearId: currentAY._id,
      semesterId: cmeSem5._id,
      sectionId: cmeSecA._id,
      subjectId: dbmsSubj._id,
      facultyId: fac1.userId,
      facultyAssignmentId: dbmsAssignment._id,
      facultyName: fac1.name,
      title: 'Assignment 1: Complex SQL Queries & Database Schema Design',
      description: 'Implement complex nested joins, group by aggregate pipelines, and schema normalization for a library management system.',
      questions: [
        '1. Design an ER diagram for a campus library management system.',
        '2. Write SQL DDL statements with primary and foreign key constraints.',
        '3. Formulate SQL queries to calculate student overdue fines using window functions.',
      ],
      assignmentType: AssignmentType.HOMEWORK,
      dueDate: dueDate.toISOString().split('T')[0],
      dueTime: '23:59',
      dueDateTime: dueDate,
      maximumMarks: 25,
      attachments: [],
      status: AssignmentStatus.PUBLISHED,
      publishedAt: new Date(),
    });

    // Seed submissions
    for (const [idx, stu] of studentDocs.slice(0, 3).entries()) {
      await AssignmentSubmission.create({
        assignmentId: assignment1._id,
        collegeId: college._id,
        studentId: stu._id,
        studentUserId: stu.userId,
        studentName: stu.name,
        rollNumber: stu.rollNumber,
        status: StudentTaskStatus.COMPLETED,
        reviewStatus: FacultyReviewStatus.REVIEWED,
        textResponse: `Completed assignment problems 1-3. Submitted queries for ${stu.name}.`,
        attachments: [
          {
            name: `${stu.rollNumber}_Assignment1.sql`,
            url: 'https://ik.imagekit.io/AcadexAi/demo_submission.sql',
            fileSize: 8192,
          },
        ],
        submittedAt: new Date(Date.now() - 24 * 3600000),
        completedAt: new Date(Date.now() - 24 * 3600000),
        isLate: false,
        version: 1,
        submissionHistory: [],
        marks: 23 - idx,
        reviewedBy: fac1.userId,
        reviewedAt: new Date(),
        feedback: 'Good query structures and sound understanding of constraints.',
      });
      track('AssignmentSubmission', true);
    }
  }
  track('Assignment', isAsg1New);

  // 19. Internal Assessments (Mid-Term Assessment 1)
  let internalExam = await InternalAssessment.findOne({
    collegeId: college._id,
    subjectId: dbmsSubj._id,
    title: 'Mid-Term Assessment 1',
  });
  const isIaNew = !internalExam;
  if (!internalExam) {
    const studentEntries = studentDocs.map((stu, i) => ({
      studentId: stu._id,
      studentName: stu.name,
      rollNumber: stu.rollNumber,
      admissionNumber: stu.admissionNumber,
      componentMarks: { theory: 23 - (i % 4), viva: 5 },
      totalMarks: 28 - (i % 4),
      status: StudentMarkStatus.ENTERED,
      remarks: 'Demonstrated solid grasp of ER modeling and query fundamentals.',
    }));

    internalExam = await InternalAssessment.create({
      collegeId: college._id,
      departmentId: cmeDept._id,
      courseId: cmeCourse._id,
      academicYearId: currentAY._id,
      semesterId: cmeSem5._id,
      sectionId: cmeSecA._id,
      subjectId: dbmsSubj._id,
      facultyId: fac1.userId,
      facultyAssignmentId: dbmsAssignment._id,
      facultyName: fac1.name,
      title: 'Mid-Term Assessment 1',
      assessmentType: AssessmentType.MID_TERM,
      maximumMarks: 30,
      passMarks: 12,
      components: [
        { key: 'theory', name: 'Written Examination', maxMarks: 25, isStudentVisible: true },
        { key: 'viva', name: 'Viva & Practical Questions', maxMarks: 5, isStudentVisible: true },
      ],
      entries: studentEntries,
      status: AssessmentStatus.CLOSED,
      publishedAt: new Date(),
      publishedBy: fac1.userId,
      auditLog: [],
    });
  }
  track('InternalAssessment', isIaNew);

  // 20. Calendar Events
  const eventsConfig = [
    {
      title: 'State Level Technical Symposium & Hackathon 2026',
      description: 'Annual inter-polytechnic coding contest, robotics challenge, and circuit design symposium.',
      eventType: CalendarEventType.EVENT,
      scope: CalendarEventScope.COLLEGE,
      startDate: '2026-11-20',
      endDate: '2026-11-21',
      location: 'Seminar Hall & Computing Center',
    },
    {
      title: 'First Mid-Term Examinations',
      description: 'Internal examinations for all 1st, 2nd, and 3rd year diploma branches.',
      eventType: CalendarEventType.EXAM,
      scope: CalendarEventScope.COLLEGE,
      startDate: '2026-11-02',
      endDate: '2026-11-06',
      location: 'Academic Block Classrooms',
    },
  ];

  for (const ev of eventsConfig) {
    let calEv = await CalendarEvent.findOne({ collegeId: college._id, title: ev.title });
    const isCalEvNew = !calEv;
    if (!calEv) {
      calEv = await CalendarEvent.create({
        collegeId: college._id,
        title: ev.title,
        description: ev.description,
        sourceType: CalendarSourceType.MANUAL,
        eventType: ev.eventType,
        scope: ev.scope,
        startDate: ev.startDate,
        endDate: ev.endDate,
        allDay: true,
        location: ev.location,
        isRecurring: false,
        recurrence: CalendarRecurrence.NONE,
        status: CalendarEventStatus.PUBLISHED,
        createdBy: collegeAdmin._id,
        creatorRole: AppRole.COLLEGE_ADMIN,
        creatorName: collegeAdmin.name,
      });
    }
    track('CalendarEvent', isCalEvNew);
  }

  // 21. Institutional Announcements
  const announcementsConfig = [
    {
      title: 'ACADEXSYNC Demo Polytechnic Annual Technical Fest & Hackathon 2026',
      body: 'State-level technical competitions, coding hackathons, and web application showcases will be held on November 20-21, 2026. Teams from all diploma branches are encouraged to register with their respective HODs.',
      category: NotificationCategory.ANNOUNCEMENT,
      priority: NotificationPriority.HIGH,
    },
    {
      title: 'State Board Diploma Odd-Semester Examination Guidelines 2026-27',
      body: 'Students are advised that 75% minimum aggregate attendance across all registered theory and lab subjects is mandatory to appear for SBTET state board end-semester examinations.',
      category: NotificationCategory.ACADEMIC,
      priority: NotificationPriority.HIGH,
    },
    {
      title: 'AI-Powered Academic Support & Digital Library Orientation',
      body: 'Students and faculty can now access the ACADEXSYNC AI assistant for timetable queries, attendance breakdown, notes exploration, and instant academic tracking.',
      category: NotificationCategory.ANNOUNCEMENT,
      priority: NotificationPriority.NORMAL,
    },
  ];

  for (const an of announcementsConfig) {
    let existingAn = await Announcement.findOne({ collegeId: college._id, title: an.title });
    const isAnNew = !existingAn;
    if (!existingAn) {
      existingAn = await Announcement.create({
        collegeId: college._id,
        title: an.title,
        body: an.body,
        category: an.category,
        audienceScope: AudienceScope.COLLEGE,
        priority: an.priority,
        isPinned: true,
        status: AnnouncementStatus.PUBLISHED,
        createdBy: collegeAdmin._id,
        publishAt: new Date(),
        publishedAt: new Date(),
        recipientCount: 50,
      });
    }
    track('Announcement', isAnNew);
  }

  // 22. User Notifications (Scoped to Ragooru Poornesh and CME students)
  const targetStudentUser = await User.findOne({ email: 'ragoorupoornesh@gmail.com' });
  if (targetStudentUser) {
    const notifsConfig = [
      {
        title: 'Attendance Recorded for DBMS',
        body: 'Your attendance for today\'s Database Management Systems lecture has been recorded as PRESENT.',
        type: NotificationType.ATTENDANCE_MARKED,
        cat: NotificationCategory.ATTENDANCE,
      },
      {
        title: 'New Assignment Published: Complex SQL Queries',
        body: 'Prof. Ananya Sen published Assignment 1 for Database Management Systems. Due date: 7 days.',
        type: NotificationType.ASSIGNMENT_PUBLISHED,
        cat: NotificationCategory.ACADEMIC,
      },
    ];

    for (const n of notifsConfig) {
      let notif = await Notification.findOne({
        collegeId: college._id,
        recipientUserId: targetStudentUser._id,
        title: n.title,
      });
      const isNotifNew = !notif;
      if (!notif) {
        notif = await Notification.create({
          collegeId: college._id,
          departmentId: cmeDept._id,
          recipientUserId: targetStudentUser._id,
          recipientRole: AppRole.STUDENT,
          title: n.title,
          body: n.body,
          notificationType: n.type,
          category: n.cat,
          priority: NotificationPriority.NORMAL,
          status: NotificationStatus.UNREAD,
          isRead: false,
        });
      }
      track('Notification', isNotifNew);
    }
  }

  // 23. Student & Faculty Requests
  if (targetStudentUser) {
    const requestsConfig = [
      {
        title: 'Bonafide Certificate for Bus Pass Concession',
        description: 'Requesting institutional bonafide certificate for TSRTC student bus pass pass renewal for 2026-27.',
        status: RequestStatus.SUBMITTED,
        type: StudentRequestType.DOCUMENT_REQUEST,
        targetRole: AppRole.HOD,
      },
      {
        title: 'On-Duty Approval for Inter-Polytechnic Hackathon',
        description: 'Selected to represent our polytechnic at the State Technical Hackathon at JNTU Hyderabad on Nov 12.',
        status: RequestStatus.APPROVED,
        type: StudentRequestType.LEAVE,
        targetRole: AppRole.HOD,
      },
    ];

    for (const req of requestsConfig) {
      let existingReq = await RequestModel.findOne({
        collegeId: college._id,
        requesterUserId: targetStudentUser._id,
        title: req.title,
      });
      const isReqNew = !existingReq;
      if (!existingReq) {
        existingReq = await RequestModel.create({
          requestId: `REQ-${Date.now()}-${Math.floor(Math.random() * 1000)}`,
          collegeId: college._id,
          departmentId: cmeDept._id,
          requesterUserId: targetStudentUser._id,
          requesterName: targetStudentUser.name,
          requesterRole: AppRole.STUDENT,
          targetRole: req.targetRole,
          requestType: req.type,
          title: req.title,
          description: req.description,
          status: req.status,
          academicContext: {
            courseId: cmeCourse._id,
            courseName: cmeCourse.name,
            semesterId: cmeSem5._id,
            sectionId: cmeSecA._id,
            sectionName: 'A',
          },
          details: {
            documentType: 'BONAFIDE_STUDENT',
            reason: 'Transportation and academic competition participation',
          },
          history: [
            {
              status: RequestStatus.SUBMITTED,
              changedBy: targetStudentUser._id,
              changedByName: targetStudentUser.name,
              note: 'Application submitted online via student portal',
              timestamp: new Date(Date.now() - 48 * 3600000),
            },
            ...(req.status === RequestStatus.APPROVED
              ? [
                  {
                    status: RequestStatus.APPROVED,
                    changedBy: hodUserMap.get('CME')._id,
                    changedByName: hodUserMap.get('CME').name,
                    note: 'Approved for institutional representation with OD attendance waiver.',
                    timestamp: new Date(Date.now() - 12 * 3600000),
                  },
                ]
              : []),
          ],
        });
      }
      track('Request', isReqNew);
    }
  }

  console.log('====================================================');
  console.log('ACADEXSYNC DEMO POLYTECHNIC SEED COMPLETED');
  console.log('====================================================');
  console.log(`Institution: ${college.name} (${college.code})`);
  console.log(`Academic Year: 2026–27 (Current, Active)`);
  console.log(`Departments: 5 (CME, ECE, EEE, MEC, CIV)`);
  console.log(`Primary Class: CME Semester 5, Section A`);
  console.log(`College Admin: admin.demo@example.com (PIN: DEMO-ADM-001)`);
  console.log(`User Test Account: ragoorupoornesh@gmail.com (PIN: 26CME001, Status: ${targetUserAccountStatus})`);
  if (targetUserActivationCode) {
    console.log(`Activation code for ragoorupoornesh@gmail.com generated and cached in private conversation scratch.`);
  }

  const resultSummary: SeedPolytechnicSummary = {
    collegeName: college.name,
    collegeCode: college.code,
    counts,
    testAccounts: [
      { name: 'Prof. Rajesh Sharma (College Admin)', email: 'admin.demo@example.com', role: AppRole.COLLEGE_ADMIN, instituteId: 'DEMO-ADM-001', status: 'ACTIVE' },
      { name: 'Dr. K. V. Ramanathan (CME HOD)', email: 'hod.cme.demo@example.com', role: AppRole.HOD, instituteId: 'DEMO-HOD-CME-01', status: 'ACTIVE' },
      { name: 'Prof. Ananya Sen (CME Faculty)', email: 'faculty.cme01.demo@example.com', role: AppRole.FACULTY, instituteId: 'DEMO-FAC-CME-01', status: 'ACTIVE' },
      { name: 'Prof. Vikram Malhotra (CME Faculty)', email: 'faculty.cme02.demo@example.com', role: AppRole.FACULTY, instituteId: 'DEMO-FAC-CME-02', status: 'ACTIVE' },
      { name: 'Ragooru Poornesh (CME Student)', email: 'ragoorupoornesh@gmail.com', role: AppRole.STUDENT, instituteId: '26CME001', status: targetUserAccountStatus },
      { name: 'Arjun Mehta (CME Student)', email: 'student.cme02.demo@example.com', role: AppRole.STUDENT, instituteId: '26CME002', status: 'ACTIVE' },
      { name: 'Sneha Reddy (CME Student)', email: 'student.cme03.demo@example.com', role: AppRole.STUDENT, instituteId: '26CME003', status: 'ACTIVE' },
    ],
    userActivationStatus: {
      email: 'ragoorupoornesh@gmail.com',
      accountStatus: targetUserAccountStatus,
      hasInvitation: true,
      activationCodeReady: !!targetUserActivationCode,
    },
  };

  await disconnectDB();
  return resultSummary;
}

if (require.main === module) {
  runPolytechnicSeeder().catch((err) => {
    console.error('Fatal error during seed execution:', err);
    process.exit(1);
  });
}
