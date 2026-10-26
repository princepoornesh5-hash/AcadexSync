 import 'dotenv/config';
import { env } from '../config/env';
import { connectDB, disconnectDB } from '../db/connection';
import { PasswordService } from '../services/password.service';
import { AppRole } from '../constants/roles';
import {
  AccountStatus,
  MembershipStatus,
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

export async function runSvgpSeeder() {
  // 1. Gating verification
  if (env.NODE_ENV !== 'development') {
    console.error('CRITICAL: Seed execution rejected. NODE_ENV must be "development".');
    process.exit(1);
  }

  await connectDB();
  console.log('Connected to database for SVGP demo management');

  const isReset = process.argv.includes('--reset');

  // Find college
  let college = await College.findOne({ code: 'SVGP' });

  if (isReset) {
    console.log('====================================================');
    console.log('RESETTING SVGP DEMO ENVIRONMENT');
    console.log('====================================================');

    if (college) {
      const cId = college._id;
      await Promise.all([
        RequestModel.deleteMany({ collegeId: cId }),
        Notification.deleteMany({ collegeId: cId }),
        Announcement.deleteMany({ collegeId: cId }),
        InternalAssessment.deleteMany({ collegeId: cId }),
        AssignmentSubmission.deleteMany({}),
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
        Room.deleteMany({ collegeId: cId }),
        Subject.deleteMany({ collegeId: cId }),
        Section.deleteMany({ collegeId: cId }),
        Semester.deleteMany({ collegeId: cId }),
        Course.deleteMany({ collegeId: cId }),
        Department.deleteMany({ collegeId: cId }),
        AcademicYear.deleteMany({ collegeId: cId }),
      ]);

      // Delete demo users created for SVGP demo
      await User.deleteMany({
        email: {
          $in: [
            'admin@acadex.com',
            'college@acadex.com',
            'hod@acadex.com',
            'hod.cse@acadex.com',
            'hod.ece@acadex.com',
            'hod.eee@acadex.com',
            'hod.mec@acadex.com',
            'hod.civ@acadex.com',
            'faculty@acadex.com',
            'faculty.cme2@acadex.com',
            'faculty.cse@acadex.com',
            'faculty.cse2@acadex.com',
            'faculty.ece@acadex.com',
            'faculty.ece2@acadex.com',
            'faculty.eee@acadex.com',
            'faculty.eee2@acadex.com',
            'faculty.mec@acadex.com',
            'faculty.mec2@acadex.com',
            'faculty.civ@acadex.com',
            'faculty.civ2@acadex.com',
            'student@acadex.com',
          ],
        },
      });

      await User.deleteMany({ email: { $regex: /@svgp\.acadex\.edu$/ } });
      await College.deleteOne({ _id: cId });
      console.log('[✓] Cleaned up all SVGP demo records and associated demo users');
    } else {
      console.log('No SVGP institution found to reset.');
    }

    await disconnectDB();
    return;
  }

  console.log('====================================================');
  console.log('SEEDING SVGP DEMO ENVIRONMENT (IDEMPOTENT)');
  console.log('====================================================');

  const defaultPassword = 'acadex123';
  const passwordHash = await PasswordService.hashPassword(defaultPassword);

  // 1. College
  if (!college) {
    college = await College.create({
      name: 'Sri Venkateswara Government Polytechnic, Tirupati',
      code: 'SVGP',
      address: 'K.T. Road, Tirupati, Andhra Pradesh 517507',
      email: 'principal.svgp@acadex.edu',
      phone: '08772248555',
      principal: 'Dr. K. Srinivasulu',
      timezone: 'Asia/Kolkata',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });
    console.log(`[+] College created: ${college.name} (${college.code})`);
  } else {
    college.name = 'Sri Venkateswara Government Polytechnic, Tirupati';
    college.address = 'K.T. Road, Tirupati, Andhra Pradesh 517507';
    college.email = 'principal.svgp@acadex.edu';
    college.phone = '08772248555';
    college.principal = 'Dr. K. Srinivasulu';
    college.status = CollegeStatus.ACTIVE;
    college.isActive = true;
    await college.save();
    console.log(`[=] College verified: ${college.name} (${college.code})`);
  }

  // 2. Academic Years
  let currentAY = await AcademicYear.findOne({ collegeId: college._id, name: '2026–27' });
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
    console.log(`[+] Academic Year created: ${currentAY.name}`);
  } else {
    currentAY.status = AcademicYearStatus.ACTIVE;
    currentAY.isCurrent = true;
    currentAY.isActive = true;
    await currentAY.save();
  }

  let pastAY = await AcademicYear.findOne({ collegeId: college._id, name: '2025–26' });
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
    console.log(`[+] Historical Academic Year verified: ${pastAY.name}`);
  }

  // 3. Departments Configuration
  const departmentsConfig = [
    { name: 'Computer Engineering', code: 'CME', courseCode: 'DCME', courseName: 'Diploma in Computer Engineering' },
    { name: 'Computer Science and Engineering', code: 'CSE', courseCode: 'DCSE', courseName: 'Diploma in Computer Science & Engineering' },
    { name: 'Electronics and Communication Engineering', code: 'ECE', courseCode: 'DECE', courseName: 'Diploma in Electronics & Communication Engineering' },
    { name: 'Electrical and Electronics Engineering', code: 'EEE', courseCode: 'DEEE', courseName: 'Diploma in Electrical & Electronics Engineering' },
    { name: 'Mechanical Engineering', code: 'MEC', courseCode: 'DMEC', courseName: 'Diploma in Mechanical Engineering' },
    { name: 'Civil Engineering', code: 'CIV', courseCode: 'DCIV', courseName: 'Diploma in Civil Engineering' },
  ];

  const deptMap = new Map<string, any>();
  const courseMap = new Map<string, any>();
  const semesterMap = new Map<string, any>();
  const sectionMap = new Map<string, any>();

  for (const conf of departmentsConfig) {
    let dept = await Department.findOne({ collegeId: college._id, code: conf.code });
    if (!dept) {
      dept = await Department.create({
        collegeId: college._id,
        name: conf.name,
        code: conf.code,
        status: DepartmentStatus.ACTIVE,
      });
      console.log(`[+] Department created: ${dept.name} (${dept.code})`);
    } else {
      dept.name = conf.name;
      dept.status = DepartmentStatus.ACTIVE;
      await dept.save();
    }
    deptMap.set(conf.code, dept);

    // Course
    let course = await Course.findOne({ collegeId: college._id, code: conf.courseCode });
    if (!course) {
      course = await Course.create({
        collegeId: college._id,
        departmentId: dept._id,
        name: conf.courseName,
        code: conf.courseCode,
        durationYears: 3,
        totalSemesters: 6,
        status: 'active',
      });
      console.log(`[+] Course created: ${course.name} (${course.code})`);
    }
    courseMap.set(conf.code, course);

    // Semesters (1 to 6)
    for (let semNum = 1; semNum <= 6; semNum++) {
      let sem = await Semester.findOne({
        collegeId: college._id,
        courseId: course._id,
        number: semNum,
      });
      if (!sem) {
        sem = await Semester.create({
          collegeId: college._id,
          departmentId: dept._id,
          academicYearId: currentAY._id,
          courseId: course._id,
          number: semNum,
          name: `Semester ${semNum}`,
          status: semNum === 5 ? SemesterStatus.ACTIVE : SemesterStatus.UPCOMING,
          isCurrent: semNum === 5,
          isActive: true,
        });
      }
      if (semNum === 5) {
        semesterMap.set(conf.code, sem);
      }
    }

    // Sections for Sem 5: Section A and Section B
    const sem5 = semesterMap.get(conf.code);
    let sectionA = await Section.findOne({
      collegeId: college._id,
      courseId: course._id,
      semesterId: sem5._id,
      name: 'A',
    });
    if (!sectionA) {
      sectionA = await Section.create({
        collegeId: college._id,
        departmentId: dept._id,
        courseId: course._id,
        academicYearId: currentAY._id,
        semesterId: sem5._id,
        name: 'A',
        capacity: 60,
        status: 'active',
      });
    }
    sectionMap.set(`${conf.code}_A`, sectionA);

    let sectionB = await Section.findOne({
      collegeId: college._id,
      courseId: course._id,
      semesterId: sem5._id,
      name: 'B',
    });
    if (!sectionB) {
      sectionB = await Section.create({
        collegeId: college._id,
        departmentId: dept._id,
        courseId: course._id,
        academicYearId: currentAY._id,
        semesterId: sem5._id,
        name: 'B',
        capacity: 60,
        status: 'active',
      });
    }
    sectionMap.set(`${conf.code}_B`, sectionB);
  }

  // 4. Classrooms & Labs
  const roomsConfig = [
    { code: 'ROOM-101', name: 'Room 101', building: 'Main Block', capacity: 60, type: 'lecture' },
    { code: 'ROOM-102', name: 'Room 102', building: 'Main Block', capacity: 60, type: 'lecture' },
    { code: 'ROOM-103', name: 'Room 103', building: 'Main Block', capacity: 60, type: 'lecture' },
    { code: 'ROOM-104', name: 'Room 104', building: 'Main Block', capacity: 60, type: 'lecture' },
    { code: 'ROOM-105', name: 'Room 105', building: 'Main Block', capacity: 60, type: 'lecture' },
    { code: 'ROOM-106', name: 'Room 106', building: 'Main Block', capacity: 60, type: 'lecture' },
    { code: 'LAB-1', name: 'Lab 1', building: 'Main Block', capacity: 40, type: 'lab' },
    { code: 'LAB-2', name: 'Lab 2', building: 'Main Block', capacity: 40, type: 'lab' },
  ];

  const roomMap = new Map<string, any>();
  for (const r of roomsConfig) {
    let room = await Room.findOne({ collegeId: college._id, code: r.code });
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
  }

  // 5. Subjects for Semester 5
  const subjectsData: Record<string, Array<{ name: string; code: string; type: 'theory' | 'practical'; credits: number }>> = {
    CME: [
      { name: 'Database Management Systems', code: 'CME-501', type: 'theory', credits: 4 },
      { name: 'Computer Networks', code: 'CME-502', type: 'theory', credits: 4 },
      { name: 'Operating Systems', code: 'CME-503', type: 'theory', credits: 3 },
      { name: 'Web Development Technologies', code: 'CME-504', type: 'theory', credits: 3 },
      { name: 'DBMS & Web Lab', code: 'CME-505', type: 'practical', credits: 2 },
    ],
    CSE: [
      { name: 'Software Engineering', code: 'CSE-501', type: 'theory', credits: 4 },
      { name: 'Cloud Computing Architecture', code: 'CSE-502', type: 'theory', credits: 4 },
      { name: 'Information & Network Security', code: 'CSE-503', type: 'theory', credits: 3 },
      { name: 'Full Stack Development Lab', code: 'CSE-504', type: 'practical', credits: 2 },
    ],
    ECE: [
      { name: 'Digital Signal Processing', code: 'ECE-501', type: 'theory', credits: 4 },
      { name: 'Microcontrollers & Embedded Systems', code: 'ECE-502', type: 'theory', credits: 4 },
      { name: 'VLSI Circuit Design', code: 'ECE-503', type: 'theory', credits: 3 },
      { name: 'DSP & Microcontroller Lab', code: 'ECE-504', type: 'practical', credits: 2 },
    ],
    EEE: [
      { name: 'Power Electronics', code: 'EEE-501', type: 'theory', credits: 4 },
      { name: 'Power System Operation & Control', code: 'EEE-502', type: 'theory', credits: 4 },
      { name: 'Control Systems Engineering', code: 'EEE-503', type: 'theory', credits: 3 },
      { name: 'Power Electronics & Drives Lab', code: 'EEE-504', type: 'practical', credits: 2 },
    ],
    MEC: [
      { name: 'Thermal Engineering II', code: 'MEC-501', type: 'theory', credits: 4 },
      { name: 'Design of Machine Elements', code: 'MEC-502', type: 'theory', credits: 4 },
      { name: 'Industrial Engineering & Operations', code: 'MEC-503', type: 'theory', credits: 3 },
      { name: 'CAD/CAM Simulation Lab', code: 'MEC-504', type: 'practical', credits: 2 },
    ],
    CIV: [
      { name: 'Design of Steel Structures', code: 'CIV-501', type: 'theory', credits: 4 },
      { name: 'Geotechnical Engineering', code: 'CIV-502', type: 'theory', credits: 4 },
      { name: 'Water Resources & Irrigation', code: 'CIV-503', type: 'theory', credits: 3 },
      { name: 'Soil Mechanics & Materials Lab', code: 'CIV-504', type: 'practical', credits: 2 },
    ],
  };

  const subjectMap = new Map<string, any>();
  for (const [deptCode, subjs] of Object.entries(subjectsData)) {
    const dept = deptMap.get(deptCode);
    const course = courseMap.get(deptCode);
    const sem = semesterMap.get(deptCode);

    for (const s of subjs) {
      let subj = await Subject.findOne({ collegeId: college._id, code: s.code });
      if (!subj) {
        subj = await Subject.create({
          collegeId: college._id,
          departmentId: dept._id,
          courseId: course._id,
          semesterId: sem._id,
          name: s.name,
          code: s.code,
          credits: s.credits,
          type: s.type,
          status: 'active',
        });
      }
      subjectMap.set(s.code, subj);
    }
  }

  // 6. Super Admin & College Admin
  let superAdmin = await User.findOne({ email: 'admin@acadex.com' });
  if (!superAdmin) {
    superAdmin = await User.create({
      name: 'Poornesh (Platform Owner)',
      email: 'admin@acadex.com',
      instituteId: 'ADM-SUPER-001',
      passwordHash,
      role: AppRole.SUPER_ADMIN,
      accountStatus: AccountStatus.ACTIVE,
      activationStatus: 'activated',
    });
    console.log(`[+] Super Admin created: ${superAdmin.email}`);
  } else {
    superAdmin.passwordHash = passwordHash;
    superAdmin.accountStatus = AccountStatus.ACTIVE;
    await superAdmin.save();
  }

  let collegeAdmin = await User.findOne({ email: 'college@acadex.com' });
  if (!collegeAdmin) {
    collegeAdmin = await User.create({
      collegeId: college._id,
      name: 'Dr. K. Srinivasulu',
      email: 'college@acadex.com',
      instituteId: 'SVGP-ADM-001',
      passwordHash,
      role: AppRole.COLLEGE_ADMIN,
      accountStatus: AccountStatus.ACTIVE,
      activationStatus: 'activated',
    });
    console.log(`[+] College Admin created: ${collegeAdmin.email}`);
  } else {
    collegeAdmin.collegeId = college._id;
    collegeAdmin.passwordHash = passwordHash;
    collegeAdmin.accountStatus = AccountStatus.ACTIVE;
    await collegeAdmin.save();
  }

  // Authoritative Membership & Role Assignment for College Admin
  let adminMembership = await WorkspaceMembership.findOne({
    userId: collegeAdmin._id,
    collegeId: college._id,
  });
  if (!adminMembership) {
    adminMembership = await WorkspaceMembership.create({
      userId: collegeAdmin._id,
      collegeId: college._id,
      status: MembershipStatus.ACTIVE,
      isDefault: true,
      title: 'Principal & College Admin',
    });
  } else {
    adminMembership.status = MembershipStatus.ACTIVE;
    await adminMembership.save();
  }

  let adminRoleAssignment = await WorkspaceRoleAssignment.findOne({
    membershipId: adminMembership._id,
    role: AppRole.COLLEGE_ADMIN,
  });
  if (!adminRoleAssignment) {
    await WorkspaceRoleAssignment.create({
      membershipId: adminMembership._id,
      userId: collegeAdmin._id,
      collegeId: college._id,
      role: AppRole.COLLEGE_ADMIN,
      status: RoleAssignmentStatus.ACTIVE,
    });
  }

  // 7. Department HODs
  const hodsConfig = [
    { email: 'hod@acadex.com', name: 'Dr. V. Radha Krishna', deptCode: 'CME', instId: 'HOD-CME-001' },
    { email: 'hod.cse@acadex.com', name: 'Dr. P. Suresh', deptCode: 'CSE', instId: 'HOD-CSE-001' },
    { email: 'hod.ece@acadex.com', name: 'Dr. M. Lakshmi', deptCode: 'ECE', instId: 'HOD-ECE-001' },
    { email: 'hod.eee@acadex.com', name: 'Dr. R. Ramanujan', deptCode: 'EEE', instId: 'HOD-EEE-001' },
    { email: 'hod.mec@acadex.com', name: 'Dr. K. Venkatesh', deptCode: 'MEC', instId: 'HOD-MEC-001' },
    { email: 'hod.civ@acadex.com', name: 'Dr. G. Ramesh', deptCode: 'CIV', instId: 'HOD-CIV-001' },
  ];

  const hodUserMap = new Map<string, any>();
  for (const h of hodsConfig) {
    const dept = deptMap.get(h.deptCode);
    let hodUser = await User.findOne({ email: h.email });
    if (!hodUser) {
      hodUser = await User.create({
        collegeId: college._id,
        departmentId: dept._id,
        name: h.name,
        email: h.email,
        instituteId: h.instId,
        passwordHash,
        role: AppRole.HOD,
        accountStatus: AccountStatus.ACTIVE,
        activationStatus: 'activated',
      });
      console.log(`[+] HOD created: ${hodUser.email} (${dept.code})`);
    } else {
      hodUser.collegeId = college._id;
      hodUser.departmentId = dept._id;
      hodUser.passwordHash = passwordHash;
      hodUser.accountStatus = AccountStatus.ACTIVE;
      await hodUser.save();
    }
    hodUserMap.set(h.deptCode, hodUser);

    // Update dept hodId
    dept.hodId = hodUser._id.toString();
    await dept.save();

    // Membership & Role Assignment
    let mem = await WorkspaceMembership.findOne({ userId: hodUser._id, collegeId: college._id });
    if (!mem) {
      mem = await WorkspaceMembership.create({
        userId: hodUser._id,
        collegeId: college._id,
        status: MembershipStatus.ACTIVE,
        isDefault: true,
        title: `HOD - ${dept.name}`,
      });
    } else {
      mem.status = MembershipStatus.ACTIVE;
      await mem.save();
    }

    let ra = await WorkspaceRoleAssignment.findOne({ membershipId: mem._id, role: AppRole.HOD });
    if (!ra) {
      await WorkspaceRoleAssignment.create({
        membershipId: mem._id,
        userId: hodUser._id,
        collegeId: college._id,
        role: AppRole.HOD,
        departmentId: dept._id,
        status: RoleAssignmentStatus.ACTIVE,
      });
    }

    // Faculty Profile for HOD
    let facProfile = await Faculty.findOne({ userId: hodUser._id });
    if (!facProfile) {
      await Faculty.create({
        collegeId: college._id,
        departmentId: dept._id,
        userId: hodUser._id,
        name: h.name,
        email: h.email,
        employeeId: h.instId,
        designation: 'Professor & Head of Department',
        status: 'active',
        isActive: true,
      });
    }
  }

  // 8. Teaching Faculty (2 per department)
  const facultyConfig = [
    { email: 'faculty@acadex.com', name: 'Prof. S. Murali Mohan', deptCode: 'CME', instId: 'FAC-CME-001', desig: 'Associate Professor' },
    { email: 'faculty.cme2@acadex.com', name: 'Prof. K. Anitha', deptCode: 'CME', instId: 'FAC-CME-002', desig: 'Assistant Professor' },
    { email: 'faculty.cse@acadex.com', name: 'Prof. N. Harish', deptCode: 'CSE', instId: 'FAC-CSE-001', desig: 'Associate Professor' },
    { email: 'faculty.cse2@acadex.com', name: 'Prof. T. Swathi', deptCode: 'CSE', instId: 'FAC-CSE-002', desig: 'Assistant Professor' },
    { email: 'faculty.ece@acadex.com', name: 'Prof. D. Venkat', deptCode: 'ECE', instId: 'FAC-ECE-001', desig: 'Associate Professor' },
    { email: 'faculty.ece2@acadex.com', name: 'Prof. B. Rekha', deptCode: 'ECE', instId: 'FAC-ECE-002', desig: 'Assistant Professor' },
    { email: 'faculty.eee@acadex.com', name: 'Prof. C. Naresh', deptCode: 'EEE', instId: 'FAC-EEE-001', desig: 'Associate Professor' },
    { email: 'faculty.eee2@acadex.com', name: 'Prof. P. Sunita', deptCode: 'EEE', instId: 'FAC-EEE-002', desig: 'Assistant Professor' },
    { email: 'faculty.mec@acadex.com', name: 'Prof. A. Vijay', deptCode: 'MEC', instId: 'FAC-MEC-001', desig: 'Associate Professor' },
    { email: 'faculty.mec2@acadex.com', name: 'Prof. M. Prakash', deptCode: 'MEC', instId: 'FAC-MEC-002', desig: 'Assistant Professor' },
    { email: 'faculty.civ@acadex.com', name: 'Prof. J. Mohan', deptCode: 'CIV', instId: 'FAC-CIV-001', desig: 'Associate Professor' },
    { email: 'faculty.civ2@acadex.com', name: 'Prof. K. Divya', deptCode: 'CIV', instId: 'FAC-CIV-002', desig: 'Assistant Professor' },
  ];

  const facultyDocMap = new Map<string, any>();
  for (const f of facultyConfig) {
    const dept = deptMap.get(f.deptCode);
    let facUser = await User.findOne({ email: f.email });
    if (!facUser) {
      facUser = await User.create({
        collegeId: college._id,
        departmentId: dept._id,
        name: f.name,
        email: f.email,
        instituteId: f.instId,
        passwordHash,
        role: AppRole.FACULTY,
        accountStatus: AccountStatus.ACTIVE,
        activationStatus: 'activated',
      });
      console.log(`[+] Faculty created: ${facUser.email} (${dept.code})`);
    } else {
      facUser.collegeId = college._id;
      facUser.departmentId = dept._id;
      facUser.passwordHash = passwordHash;
      facUser.accountStatus = AccountStatus.ACTIVE;
      await facUser.save();
    }

    // Membership & Role Assignment
    let mem = await WorkspaceMembership.findOne({ userId: facUser._id, collegeId: college._id });
    if (!mem) {
      mem = await WorkspaceMembership.create({
        userId: facUser._id,
        collegeId: college._id,
        status: MembershipStatus.ACTIVE,
        isDefault: true,
        title: f.desig,
      });
    } else {
      mem.status = MembershipStatus.ACTIVE;
      await mem.save();
    }

    let ra = await WorkspaceRoleAssignment.findOne({ membershipId: mem._id, role: AppRole.FACULTY });
    if (!ra) {
      await WorkspaceRoleAssignment.create({
        membershipId: mem._id,
        userId: facUser._id,
        collegeId: college._id,
        role: AppRole.FACULTY,
        departmentId: dept._id,
        status: RoleAssignmentStatus.ACTIVE,
      });
    }

    // Faculty Profile
    let facDoc = await Faculty.findOne({ userId: facUser._id });
    if (!facDoc) {
      facDoc = await Faculty.create({
        collegeId: college._id,
        departmentId: dept._id,
        userId: facUser._id,
        name: f.name,
        email: f.email,
        employeeId: f.instId,
        designation: f.desig,
        status: 'active',
        isActive: true,
      });
    }
    facultyDocMap.set(f.email, facDoc);
  }

  // 9. Faculty Assignments & Teaching Allocations
  // CME Department Teaching Allocations:
  const cmeDept = deptMap.get('CME');
  const cmeCourse = courseMap.get('CME');
  const cmeSem5 = semesterMap.get('CME');
  const cmeSecA = sectionMap.get('CME_A');

  const fac1 = facultyDocMap.get('faculty@acadex.com');
  const fac2 = facultyDocMap.get('faculty.cme2@acadex.com');

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
      facultyId: a.faculty._id,
      subjectId: subj._id,
      sectionId: cmeSecA._id,
    });
    if (!fa) {
      fa = await FacultyAssignment.create({
        collegeId: college._id,
        departmentId: cmeDept._id,
        facultyId: a.faculty._id,
        facultyName: a.faculty.name,
        subjectId: subj._id,
        courseId: cmeCourse._id,
        semesterId: cmeSem5._id,
        sectionId: cmeSecA._id,
        academicYearId: currentAY._id,
        cohort: a.cohort,
        academicStage: a.stage,
        status: 'active',
        isActive: true,
      });
    }
    facultyAssignmentMap.set(a.subjCode, fa);
  }

  // 10. Students (6 per department = 36 total)
  const studentsConfig: Record<string, Array<{ name: string; email: string; roll: string }>> = {
    CME: [
      { name: 'R. Sai Teja', email: 'student@acadex.com', roll: '24CME001' },
      { name: 'P. Harshitha', email: 'harshitha.cme@svgp.acadex.edu', roll: '24CME002' },
      { name: 'M. Dinesh', email: 'dinesh.cme@svgp.acadex.edu', roll: '24CME003' },
      { name: 'K. Sneha', email: 'sneha.cme@svgp.acadex.edu', roll: '24CME004' },
      { name: 'G. Tharun', email: 'tharun.cme@svgp.acadex.edu', roll: '24CME005' },
      { name: 'S. Deepthi', email: 'deepthi.cme@svgp.acadex.edu', roll: '24CME006' },
    ],
    CSE: [
      { name: 'B. Akhil', email: 'akhil.cse@svgp.acadex.edu', roll: '24CSE001' },
      { name: 'T. Kavya', email: 'kavya.cse@svgp.acadex.edu', roll: '24CSE002' },
      { name: 'N. Praneeth', email: 'praneeth.cse@svgp.acadex.edu', roll: '24CSE003' },
      { name: 'V. Bhavana', email: 'bhavana.cse@svgp.acadex.edu', roll: '24CSE004' },
      { name: 'R. Chetan', email: 'chetan.cse@svgp.acadex.edu', roll: '24CSE005' },
      { name: 'M. Lavanya', email: 'lavanya.cse@svgp.acadex.edu', roll: '24CSE006' },
    ],
    ECE: [
      { name: 'A. Rahul', email: 'rahul.ece@svgp.acadex.edu', roll: '24ECE001' },
      { name: 'K. Ramya', email: 'ramya.ece@svgp.acadex.edu', roll: '24ECE002' },
      { name: 'S. Manoj', email: 'manoj.ece@svgp.acadex.edu', roll: '24ECE003' },
      { name: 'P. Geetha', email: 'geetha.ece@svgp.acadex.edu', roll: '24ECE004' },
      { name: 'D. Lokesh', email: 'lokesh.ece@svgp.acadex.edu', roll: '24ECE005' },
      { name: 'C. Sushma', email: 'sushma.ece@svgp.acadex.edu', roll: '24ECE006' },
    ],
    EEE: [
      { name: 'G. Sandeep', email: 'sandeep.eee@svgp.acadex.edu', roll: '24EEE001' },
      { name: 'M. Anusha', email: 'anusha.eee@svgp.acadex.edu', roll: '24EEE002' },
      { name: 'T. Vinay', email: 'vinay.eee@svgp.acadex.edu', roll: '24EEE003' },
      { name: 'K. Manasa', email: 'manasa.eee@svgp.acadex.edu', roll: '24EEE004' },
      { name: 'P. Karthik', email: 'karthik.eee@svgp.acadex.edu', roll: '24EEE005' },
      { name: 'R. Navya', email: 'navya.eee@svgp.acadex.edu', roll: '24EEE006' },
    ],
    MEC: [
      { name: 'K. Charan', email: 'charan.mec@svgp.acadex.edu', roll: '24MEC001' },
      { name: 'D. Swetha', email: 'swetha.mec@svgp.acadex.edu', roll: '24MEC002' },
      { name: 'S. Varun', email: 'varun.mec@svgp.acadex.edu', roll: '24MEC003' },
      { name: 'N. Priyanka', email: 'priyanka.mec@svgp.acadex.edu', roll: '24MEC004' },
      { name: 'B. Rajesh', email: 'rajesh.mec@svgp.acadex.edu', roll: '24MEC005' },
      { name: 'A. Sindhu', email: 'sindhu.mec@svgp.acadex.edu', roll: '24MEC006' },
    ],
    CIV: [
      { name: 'V. Kalyan', email: 'kalyan.civ@svgp.acadex.edu', roll: '24CIV001' },
      { name: 'M. Pooja', email: 'pooja.civ@svgp.acadex.edu', roll: '24CIV002' },
      { name: 'T. Naveen', email: 'naveen.civ@svgp.acadex.edu', roll: '24CIV003' },
      { name: 'G. Harika', email: 'harika.civ@svgp.acadex.edu', roll: '24CIV004' },
      { name: 'C. Ajay', email: 'ajay.civ@svgp.acadex.edu', roll: '24CIV005' },
      { name: 'S. Yamini', email: 'yamini.civ@svgp.acadex.edu', roll: '24CIV006' },
    ],
  };

  const studentDocs: any[] = [];
  const cmeStudentDocs: any[] = [];

  for (const [deptCode, stuList] of Object.entries(studentsConfig)) {
    const dept = deptMap.get(deptCode);
    const course = courseMap.get(deptCode);
    const sem = semesterMap.get(deptCode);
    const secA = sectionMap.get(`${deptCode}_A`);

    for (const s of stuList) {
      let stuUser = await User.findOne({ email: s.email });
      if (!stuUser) {
        stuUser = await User.create({
          collegeId: college._id,
          departmentId: dept._id,
          name: s.name,
          email: s.email,
          instituteId: s.roll,
          passwordHash,
          role: AppRole.STUDENT,
          accountStatus: AccountStatus.ACTIVE,
          activationStatus: 'activated',
        });
      } else {
        stuUser.collegeId = college._id;
        stuUser.departmentId = dept._id;
        stuUser.passwordHash = passwordHash;
        stuUser.accountStatus = AccountStatus.ACTIVE;
        await stuUser.save();
      }

      // Membership & Role Assignment
      let mem = await WorkspaceMembership.findOne({ userId: stuUser._id, collegeId: college._id });
      if (!mem) {
        mem = await WorkspaceMembership.create({
          userId: stuUser._id,
          collegeId: college._id,
          status: MembershipStatus.ACTIVE,
          isDefault: true,
          title: `Student (${s.roll})`,
        });
      } else {
        mem.status = MembershipStatus.ACTIVE;
        await mem.save();
      }

      let ra = await WorkspaceRoleAssignment.findOne({ membershipId: mem._id, role: AppRole.STUDENT });
      if (!ra) {
        await WorkspaceRoleAssignment.create({
          membershipId: mem._id,
          userId: stuUser._id,
          collegeId: college._id,
          role: AppRole.STUDENT,
          departmentId: dept._id,
          status: RoleAssignmentStatus.ACTIVE,
        });
      }

      // Student Profile
      let stuDoc = await Student.findOne({ userId: stuUser._id });
      if (!stuDoc) {
        stuDoc = await Student.create({
          collegeId: college._id,
          departmentId: dept._id,
          userId: stuUser._id,
          name: s.name,
          rollNumber: s.roll,
          admissionNumber: `ADM-${s.roll}`,
          email: s.email,
          courseId: course._id,
          academicYearId: currentAY._id,
          semesterId: sem._id,
          sectionId: secA._id,
          cohort: '2024–27',
          academicStage: '3rd Year',
          lifecycleState: StudentLifecycleState.ACTIVE,
          status: 'active',
          isActive: true,
        });
      }
      studentDocs.push(stuDoc);
      if (deptCode === 'CME') {
        cmeStudentDocs.push(stuDoc);
      }

      // Enrollment
      let enrollment = await StudentEnrollment.findOne({
        collegeId: college._id,
        studentId: stuDoc._id,
        sectionId: secA._id,
      });
      if (!enrollment) {
        await StudentEnrollment.create({
          collegeId: college._id,
          departmentId: dept._id,
          studentId: stuDoc._id,
          courseId: course._id,
          semesterId: sem._id,
          sectionId: secA._id,
          academicYearId: currentAY._id,
          cohort: '2024–27',
          academicStage: '3rd Year',
          status: 'active',
        });
      }
    }
  }
  console.log(`[+] Seeded ${studentDocs.length} total students across 6 departments with active enrollments`);

  // 11. Published Timetable for CME Section A
  let timetable = await Timetable.findOne({
    collegeId: college._id,
    sectionId: cmeSecA._id,
    semesterId: cmeSem5._id,
  });

  const dbmsAssignment = facultyAssignmentMap.get('CME-501');
  const cnAssignment = facultyAssignmentMap.get('CME-502');
  const osAssignment = facultyAssignmentMap.get('CME-503');
  const webAssignment = facultyAssignmentMap.get('CME-504');
  const labAssignment = facultyAssignmentMap.get('CME-505');

  const timetableEntries = [
    // Monday
    { dayOfWeek: TimetableDay.MONDAY, startTime: '09:00', endTime: '10:00', subjectId: subjectMap.get('CME-501')._id, facultyId: fac1._id, facultyAssignmentId: dbmsAssignment._id, roomNumber: '101', building: 'Main Block', sessionType: TimetableSessionType.LECTURE },
    { dayOfWeek: TimetableDay.MONDAY, startTime: '10:00', endTime: '11:00', subjectId: subjectMap.get('CME-502')._id, facultyId: fac1._id, facultyAssignmentId: cnAssignment._id, roomNumber: '101', building: 'Main Block', sessionType: TimetableSessionType.LECTURE },
    { dayOfWeek: TimetableDay.MONDAY, startTime: '11:15', endTime: '12:15', subjectId: subjectMap.get('CME-503')._id, facultyId: fac2._id, facultyAssignmentId: osAssignment._id, roomNumber: '101', building: 'Main Block', sessionType: TimetableSessionType.LECTURE },
    // Tuesday
    { dayOfWeek: TimetableDay.TUESDAY, startTime: '09:00', endTime: '10:00', subjectId: subjectMap.get('CME-504')._id, facultyId: fac2._id, facultyAssignmentId: webAssignment._id, roomNumber: '101', building: 'Main Block', sessionType: TimetableSessionType.LECTURE },
    { dayOfWeek: TimetableDay.TUESDAY, startTime: '10:00', endTime: '11:00', subjectId: subjectMap.get('CME-501')._id, facultyId: fac1._id, facultyAssignmentId: dbmsAssignment._id, roomNumber: '101', building: 'Main Block', sessionType: TimetableSessionType.LECTURE },
    { dayOfWeek: TimetableDay.TUESDAY, startTime: '13:15', endTime: '16:15', subjectId: subjectMap.get('CME-505')._id, facultyId: fac2._id, facultyAssignmentId: labAssignment._id, roomNumber: 'Lab 1', building: 'Main Block', sessionType: TimetableSessionType.LAB },
    // Wednesday
    { dayOfWeek: TimetableDay.WEDNESDAY, startTime: '09:00', endTime: '10:00', subjectId: subjectMap.get('CME-502')._id, facultyId: fac1._id, facultyAssignmentId: cnAssignment._id, roomNumber: '101', building: 'Main Block', sessionType: TimetableSessionType.LECTURE },
    { dayOfWeek: TimetableDay.WEDNESDAY, startTime: '10:00', endTime: '11:00', subjectId: subjectMap.get('CME-503')._id, facultyId: fac2._id, facultyAssignmentId: osAssignment._id, roomNumber: '101', building: 'Main Block', sessionType: TimetableSessionType.LECTURE },
    // Thursday
    { dayOfWeek: TimetableDay.THURSDAY, startTime: '09:00', endTime: '10:00', subjectId: subjectMap.get('CME-501')._id, facultyId: fac1._id, facultyAssignmentId: dbmsAssignment._id, roomNumber: '101', building: 'Main Block', sessionType: TimetableSessionType.LECTURE },
    { dayOfWeek: TimetableDay.THURSDAY, startTime: '10:00', endTime: '11:00', subjectId: subjectMap.get('CME-504')._id, facultyId: fac2._id, facultyAssignmentId: webAssignment._id, roomNumber: '101', building: 'Main Block', sessionType: TimetableSessionType.LECTURE },
    // Friday
    { dayOfWeek: TimetableDay.FRIDAY, startTime: '09:00', endTime: '10:00', subjectId: subjectMap.get('CME-502')._id, facultyId: fac1._id, facultyAssignmentId: cnAssignment._id, roomNumber: '101', building: 'Main Block', sessionType: TimetableSessionType.LECTURE },
    { dayOfWeek: TimetableDay.FRIDAY, startTime: '10:00', endTime: '11:00', subjectId: subjectMap.get('CME-503')._id, facultyId: fac2._id, facultyAssignmentId: osAssignment._id, roomNumber: '101', building: 'Main Block', sessionType: TimetableSessionType.LECTURE },
    // Saturday
    { dayOfWeek: TimetableDay.SATURDAY, startTime: '09:00', endTime: '10:00', subjectId: subjectMap.get('CME-504')._id, facultyId: fac2._id, facultyAssignmentId: webAssignment._id, roomNumber: '101', building: 'Main Block', sessionType: TimetableSessionType.LECTURE },
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
    console.log(`[+] Timetable created and PUBLISHED for CME Section A`);
  } else {
    timetable.status = TimetableStatus.PUBLISHED;
    timetable.entries = timetableEntries as any;
    await timetable.save();
  }

  // 12. Attendance Sessions & Records (Historical 14 days + Today)
  const dbmsSubj = subjectMap.get('CME-501');
  const now = new Date();
  let seededSessionsCount = 0;

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

    const records = cmeStudentDocs.map((stu, idx) => {
      // 85% attendance: student at idx 5 absent every 3rd day
      const isAbsent = idx === 5 && d % 3 === 0;
      return {
        studentId: stu._id,
        studentName: stu.name,
        rollNumber: stu.rollNumber,
        sectionId: cmeSecA._id,
        status: isAbsent ? AttendanceStatus.ABSENT : AttendanceStatus.PRESENT,
      };
    });

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
        building: 'Main Block',
        status: AttendanceSessionStatus.LOCKED,
        isSubmitted: true,
        isLocked: true,
        version: 1,
      });
      seededSessionsCount++;

      // Create matching AttendanceRecord documents
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
      }
    }
  }
  console.log(`[+] Seeded ${seededSessionsCount} attendance sessions with comprehensive student records`);

  // 13. Curated Notes & Learning Materials
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
  ];

  for (const n of notesConfig) {
    let noteDoc = await Note.findOne({ collegeId: college._id, title: n.title });
    if (!noteDoc) {
      await Note.create({
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
        storageKey: `svgp/notes/${n.subj.code}_${Date.now()}.pdf`,
        fileId: `file_${Date.now()}`,
        fileUrl: 'https://ik.imagekit.io/AcadexAi/demo_study_material.pdf',
        mimeType: 'application/pdf',
        fileExtension: 'pdf',
        fileSize: 2048576,
        version: 1,
        previousVersions: [],
        chapter: n.chapter,
        publishedAt: new Date(),
      });
    }
  }
  console.log(`[+] Seeded curriculum notes for CME courses`);

  // 14. Course Assignments & Submissions
  let assignment = await Assignment.findOne({
    collegeId: college._id,
    subjectId: dbmsSubj._id,
    title: 'Assignment 1: Complex SQL Queries & Database Schema Design',
  });

  if (!assignment) {
    const dueDate = new Date(Date.now() + 7 * 86400000);
    assignment = await Assignment.create({
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

    // Seed student submissions
    const demoStudent = cmeStudentDocs[0];
    await AssignmentSubmission.create({
      assignmentId: assignment._id,
      collegeId: college._id,
      studentId: demoStudent._id,
      studentUserId: demoStudent.userId,
      studentName: demoStudent.name,
      rollNumber: demoStudent.rollNumber,
      status: StudentTaskStatus.COMPLETED,
      reviewStatus: FacultyReviewStatus.REVIEWED,
      textResponse: 'Completed all 3 SQL queries and attached ER diagram schema documentation.',
      attachments: [
        {
          name: 'SQL_Library_Schema.sql',
          url: 'https://ik.imagekit.io/AcadexAi/demo_submission.sql',
          fileSize: 10240,
        },
      ],
      submittedAt: new Date(),
      completedAt: new Date(),
      isLate: false,
      version: 1,
      submissionHistory: [],
      marks: 24,
      reviewedBy: fac1.userId,
      reviewedAt: new Date(),
      feedback: 'Excellent normalization and clean SQL indexing implementation.',
    });
  }
  console.log(`[+] Seeded assignment and student submissions`);

  // 15. Internal Assessments & Mark Entries
  let internalExam = await InternalAssessment.findOne({
    collegeId: college._id,
    subjectId: dbmsSubj._id,
    title: 'Mid-Term Assessment 1',
  });

  if (!internalExam) {
    const studentEntries = cmeStudentDocs.map((stu, i) => ({
      studentId: stu._id,
      studentName: stu.name,
      rollNumber: stu.rollNumber,
      admissionNumber: stu.admissionNumber,
      componentMarks: { theory: 24 - (i % 5), viva: 5 },
      totalMarks: 29 - (i % 5),
      status: StudentMarkStatus.ENTERED,
      remarks: 'Good analytical understanding',
    }));

    await InternalAssessment.create({
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
        { key: 'viva', name: 'Viva & Assignment', maxMarks: 5, isStudentVisible: true },
      ],
      entries: studentEntries,
      status: AssessmentStatus.CLOSED,
      publishedAt: new Date(),
      publishedBy: fac1.userId,
      auditLog: [],
    });
  }
  console.log(`[+] Seeded internal assessment scores and marks`);

  // 16. Institutional Announcements
  const announcementsConfig = [
    {
      title: 'SVGP Campus Technical Symposium 2026',
      body: 'State-level technical competitions, coding hackathons, and robotics exhibitions will be held on December 15, 2026. All departments are encouraged to register project teams.',
      category: NotificationCategory.ANNOUNCEMENT,
      priority: NotificationPriority.HIGH,
    },
    {
      title: 'Mid-Term Examination Schedule - Academic Year 2026-27',
      body: 'The First Mid-Term examinations for all diploma programs will commence from the 2nd week of November. Check the academic calendar for detailed timetables.',
      category: NotificationCategory.ACADEMIC,
      priority: NotificationPriority.HIGH,
    },
    {
      title: 'Library Digital Resource Center Upgrade',
      body: 'IEEE and ACM digital libraries are now accessible across campus Wi-Fi and the central computer lab.',
      category: NotificationCategory.ANNOUNCEMENT,
      priority: NotificationPriority.NORMAL,
    },
  ];

  for (const an of announcementsConfig) {
    let existingAn = await Announcement.findOne({ collegeId: college._id, title: an.title });
    if (!existingAn) {
      await Announcement.create({
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
  }

  // 17. User Notifications
  const demoStudentUser = await User.findOne({ email: 'student@acadex.com' });
  if (demoStudentUser) {
    const existingNotif = await Notification.findOne({
      recipientUserId: demoStudentUser._id,
      title: 'Attendance Recorded for DBMS',
    });
    if (!existingNotif) {
      await Notification.create({
        collegeId: college._id,
        departmentId: cmeDept._id,
        recipientUserId: demoStudentUser._id,
        recipientRole: AppRole.STUDENT,
        title: 'Attendance Recorded for DBMS',
        body: 'Your attendance for today\'s Database Management Systems lecture has been recorded as PRESENT.',
        notificationType: NotificationType.ATTENDANCE_MARKED,
        category: NotificationCategory.ATTENDANCE,
        priority: NotificationPriority.NORMAL,
        status: NotificationStatus.UNREAD,
        isRead: false,
      });
    }
  }

  // 18. Student & Faculty Requests
  const existingReq = await RequestModel.findOne({
    collegeId: college._id,
    title: 'Bonafide Certificate for Bus Pass Concession',
  });
  if (!existingReq && demoStudentUser) {
    await RequestModel.create({
      requestId: `REQ-${Date.now()}`,
      collegeId: college._id,
      departmentId: cmeDept._id,
      requesterUserId: demoStudentUser._id,
      requesterName: demoStudentUser.name,
      requesterRole: AppRole.STUDENT,
      targetRole: AppRole.HOD,
      requestType: StudentRequestType.DOCUMENT_REQUEST,
      title: 'Bonafide Certificate for Bus Pass Concession',
      description: 'Requesting institutional bonafide certificate for APSRTC student bus pass renewal.',
      status: RequestStatus.SUBMITTED,
      academicContext: {
        courseId: cmeCourse._id,
        courseName: cmeCourse.name,
        semesterId: cmeSem5._id,
        sectionId: cmeSecA._id,
        sectionName: 'A',
      },
      details: {
        documentType: 'BONAFIDE_STUDENT',
        reason: 'Public transport concession card',
      },
      history: [
        {
          status: RequestStatus.SUBMITTED,
          changedBy: demoStudentUser._id,
          changedByName: demoStudentUser.name,
          note: 'Application submitted online',
          timestamp: new Date(),
        },
      ],
    });
  }

  console.log('====================================================');
  console.log('SVGP DEMO SEEDING COMPLETED SUCCESSFULLY');
  console.log('====================================================');
  console.log('Institution: Sri Venkateswara Government Polytechnic, Tirupati (SVGP)');
  console.log('Total Departments: 6 (CME, CSE, ECE, EEE, MEC, CIV)');
  console.log('Total Faculty: 18 (6 HODs + 12 Teaching Faculty)');
  console.log('Total Students: 36 (Enrolled in Semester 5, Section A)');
  console.log('Default Password for All Demo Accounts: acadex123');
  console.log('');
  console.log('Primary Demo Credentials:');
  console.log('- Super Admin:   admin@acadex.com   / acadex123');
  console.log('- College Admin: college@acadex.com / acadex123');
  console.log('- CME HOD:       hod@acadex.com     / acadex123');
  console.log('- CME Faculty:   faculty@acadex.com / acadex123');
  console.log('- CME Student:   student@acadex.com / acadex123');
  console.log('====================================================');

  await disconnectDB();
}

// Run when executed directly
if (require.main === module) {
  runSvgpSeeder().catch((err) => {
    console.error('Seed execution error:', err);
    process.exit(1);
  });
}
