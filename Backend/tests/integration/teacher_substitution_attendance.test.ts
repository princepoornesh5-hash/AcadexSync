import request from 'supertest';
import mongoose from 'mongoose';
import { app } from '../../src/app';
import { College } from '../../src/models/college.model';
import { User } from '../../src/models/user.model';
import { Department } from '../../src/models/department.model';
import { Course } from '../../src/models/course.model';
import { AcademicYear } from '../../src/models/academicYear.model';
import { Semester } from '../../src/models/semester.model';
import { Section } from '../../src/models/section.model';
import { Subject } from '../../src/models/subject.model';
import { Faculty } from '../../src/models/faculty.model';
import { Student } from '../../src/models/student.model';
import { StudentEnrollment } from '../../src/models/studentEnrollment.model';
import { FacultyAssignment } from '../../src/models/facultyAssignment.model';
import { Timetable } from '../../src/models/timetable.model';
import { AttendanceSession } from '../../src/models/attendanceSession.model';
import { CalendarOverride, CalendarOverrideType, CalendarOverrideScope } from '../../src/models/calendarOverride.model';
import { TeacherSubstitution, TeacherSubstitutionStatus } from '../../src/models/teacherSubstitution.model';
import { AppRole } from '../../src/constants/roles';
import {
  CollegeStatus,
  DepartmentStatus,
  TimetableDay,
  TimetableStatus,
  AccountStatus,
} from '../../src/constants/status';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';
import { PasswordService } from '../../src/services/password.service';

describe('ACADEX Timetable Module — Prompt 5 Teacher Substitution & Attendance Tests', () => {
  let collegeA: InstanceType<typeof College>;
  let collegeB: InstanceType<typeof College>;
  let deptA: InstanceType<typeof Department>;
  let deptB: InstanceType<typeof Department>;
  let courseA: InstanceType<typeof Course>;
  let academicYearA: InstanceType<typeof AcademicYear>;
  let semesterA: InstanceType<typeof Semester>;
  let sectionA: InstanceType<typeof Section>;
  let sectionB: InstanceType<typeof Section>;
  let subjectMath: InstanceType<typeof Subject>;
  let subjectPhysics: InstanceType<typeof Subject>;
  let facultyA1: InstanceType<typeof Faculty>; // Original teacher
  let facultyA2: InstanceType<typeof Faculty>; // Available substitute teacher
  let facultyA3: InstanceType<typeof Faculty>; // Teacher with overlapping class
  let facultyB1: InstanceType<typeof Faculty>; // Different department teacher
  let studentProfile: InstanceType<typeof Student>;
  let assignmentMathA1: InstanceType<typeof FacultyAssignment>;
  let assignmentPhysicsA1: InstanceType<typeof FacultyAssignment>;
  let assignmentMathA3: InstanceType<typeof FacultyAssignment>;
  let publishedTimetableA: InstanceType<typeof Timetable>;
  let mondayEntryId: string;
  let tuesdayEntryId: string;

  let collegeAdminAUser: InstanceType<typeof User>;
  let collegeAdminAHeader: { Authorization: string };
  let hodAHeader: { Authorization: string };
  let hodBHeader: { Authorization: string };
  let facultyA1Header: { Authorization: string };
  let facultyA2Header: { Authorization: string };
  let studentHeader: { Authorization: string };

  const getErrorMessage = (res: any): string => {
    return res.body?.error?.message || res.body?.message || '';
  };

  beforeAll(async () => {
    await setupTestDB();
    await TeacherSubstitution.init();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();

    const defaultPasswordHash = await PasswordService.hashPassword('Password123');

    // 1. Colleges
    collegeA = await College.create({
      name: 'Alpha Engineering College',
      code: 'ALPHA',
      address: 'Alpha Campus, Bangalore',
      email: 'admin@alpha.edu',
      phone: '+919900000001',
      principal: 'Dr. Alpha Principal',
      status: CollegeStatus.ACTIVE,
      timezone: 'Asia/Kolkata',
    });

    collegeB = await College.create({
      name: 'Beta Institute of Technology',
      code: 'BETA',
      address: 'Beta Campus, Mysore',
      email: 'admin@beta.edu',
      phone: '+919900000002',
      principal: 'Dr. Beta Principal',
      status: CollegeStatus.ACTIVE,
      timezone: 'Asia/Kolkata',
    });

    // 2. Departments
    deptA = await Department.create({
      name: 'Computer Science and Engineering',
      code: 'CSE',
      collegeId: collegeA._id,
      status: DepartmentStatus.ACTIVE,
    });

    deptB = await Department.create({
      name: 'Mechanical Engineering',
      code: 'MECH',
      collegeId: collegeA._id,
      status: DepartmentStatus.ACTIVE,
    });

    // 3. Academic Structure
    courseA = await Course.create({
      name: 'B.Tech CSE',
      code: 'BT-CSE',
      departmentId: deptA._id,
      collegeId: collegeA._id,
    });

    academicYearA = await AcademicYear.create({
      name: '2026-2027',
      year: '2026-2027',
      startDate: new Date('2026-07-01'),
      endDate: new Date('2027-06-30'),
      collegeId: collegeA._id,
    });

    semesterA = await Semester.create({
      name: 'Semester 5',
      number: 5,
      departmentId: deptA._id,
      academicYearId: academicYearA._id,
      courseId: courseA._id,
      collegeId: collegeA._id,
    });

    sectionA = await Section.create({
      name: 'Section A',
      semesterId: semesterA._id,
      courseId: courseA._id,
      collegeId: collegeA._id,
      departmentId: deptA._id,
    });

    sectionB = await Section.create({
      name: 'Section B',
      semesterId: semesterA._id,
      courseId: courseA._id,
      collegeId: collegeA._id,
      departmentId: deptA._id,
    });

    subjectMath = await Subject.create({
      name: 'Advanced Calculus',
      code: 'MATH-301',
      departmentId: deptA._id,
      collegeId: collegeA._id,
      courseId: courseA._id,
      semesterId: semesterA._id,
    });

    subjectPhysics = await Subject.create({
      name: 'Quantum Physics',
      code: 'PHY-301',
      departmentId: deptA._id,
      collegeId: collegeA._id,
      courseId: courseA._id,
      semesterId: semesterA._id,
    });

    collegeAdminAUser = await User.create({
      instituteId: 'ADM-A-01',
      collegeId: collegeA._id,
      name: 'College Admin A',
      email: 'admin@alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.COLLEGE_ADMIN,
      accountStatus: AccountStatus.ACTIVE,
      isEmailVerified: true,
    });
    collegeAdminAHeader = createTestAuthHeader({
      userId: collegeAdminAUser.id,
      instituteId: collegeAdminAUser.instituteId,
      role: AppRole.COLLEGE_ADMIN,
      collegeId: collegeA.id,
    });

    const hodAUser = await User.create({
      instituteId: 'HOD-A-01',
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'HOD CSE',
      email: 'hod.cse@alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.HOD,
      accountStatus: AccountStatus.ACTIVE,
      isEmailVerified: true,
    });
    hodAHeader = createTestAuthHeader({
      userId: hodAUser.id,
      instituteId: hodAUser.instituteId,
      role: AppRole.HOD,
      collegeId: collegeA.id,
      departmentId: deptA.id,
    });

    const hodBUser = await User.create({
      instituteId: 'HOD-B-01',
      collegeId: collegeA._id,
      departmentId: deptB._id,
      name: 'HOD Mech',
      email: 'hod.mech@alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.HOD,
      accountStatus: AccountStatus.ACTIVE,
      isEmailVerified: true,
    });
    hodBHeader = createTestAuthHeader({
      userId: hodBUser.id,
      instituteId: hodBUser.instituteId,
      role: AppRole.HOD,
      collegeId: collegeA.id,
      departmentId: deptB.id,
    });

    // Faculty A1 (Original Teacher)
    const facultyA1User = await User.create({
      instituteId: 'FAC-A-01',
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'Prof. Alan Turing',
      email: 'turing@alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.FACULTY,
      accountStatus: AccountStatus.ACTIVE,
      isEmailVerified: true,
    });
    facultyA1 = await Faculty.create({
      userId: facultyA1User._id,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'Prof. Alan Turing',
      email: 'turing@alpha.edu',
      employeeId: 'FAC-ALPHA-001',
      status: 'active',
      isActive: true,
    });
    facultyA1Header = createTestAuthHeader({
      userId: facultyA1User.id,
      instituteId: facultyA1User.instituteId,
      role: AppRole.FACULTY,
      collegeId: collegeA.id,
      departmentId: deptA.id,
    });

    // Faculty A2 (Substitute Candidate)
    const facultyA2User = await User.create({
      instituteId: 'FAC-A-02',
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'Prof. Grace Hopper',
      email: 'hopper@alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.FACULTY,
      accountStatus: AccountStatus.ACTIVE,
      isEmailVerified: true,
    });
    facultyA2 = await Faculty.create({
      userId: facultyA2User._id,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'Prof. Grace Hopper',
      email: 'hopper@alpha.edu',
      employeeId: 'FAC-ALPHA-002',
      status: 'active',
      isActive: true,
    });
    facultyA2Header = createTestAuthHeader({
      userId: facultyA2User.id,
      instituteId: facultyA2User.instituteId,
      role: AppRole.FACULTY,
      collegeId: collegeA.id,
      departmentId: deptA.id,
    });

    // Faculty A3 (Teacher with potential conflict)
    const facultyA3User = await User.create({
      instituteId: 'FAC-A-03',
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'Prof. John von Neumann',
      email: 'neumann@alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.FACULTY,
      accountStatus: AccountStatus.ACTIVE,
      isEmailVerified: true,
    });
    facultyA3 = await Faculty.create({
      userId: facultyA3User._id,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'Prof. John von Neumann',
      email: 'neumann@alpha.edu',
      employeeId: 'FAC-ALPHA-003',
      status: 'active',
      isActive: true,
    });

    // Faculty B1 (Department MECH)
    const facultyB1User = await User.create({
      instituteId: 'FAC-B-01',
      collegeId: collegeA._id,
      departmentId: deptB._id,
      name: 'Prof. James Watt',
      email: 'watt@alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.FACULTY,
      accountStatus: AccountStatus.ACTIVE,
      isEmailVerified: true,
    });
    facultyB1 = await Faculty.create({
      userId: facultyB1User._id,
      collegeId: collegeA._id,
      departmentId: deptB._id,
      name: 'Prof. James Watt',
      email: 'watt@alpha.edu',
      employeeId: 'FAC-BETA-001',
      status: 'active',
      isActive: true,
    });

    // Student
    const studentUser = await User.create({
      instituteId: 'STU-01',
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'Student John Doe',
      email: 'john@student.alpha.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.STUDENT,
      accountStatus: AccountStatus.ACTIVE,
      isEmailVerified: true,
    });
    studentProfile = await Student.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      userId: studentUser._id,
      instituteId: studentUser.instituteId,
      name: studentUser.name,
      email: studentUser.email,
      rollNumber: 'CSE-2026-001',
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      status: 'active',
      isActive: true,
    });
    await StudentEnrollment.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      studentId: studentProfile._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      status: 'active',
    });
    studentHeader = createTestAuthHeader({
      userId: studentUser.id,
      instituteId: studentUser.instituteId,
      role: AppRole.STUDENT,
      collegeId: collegeA.id,
    });

    // Faculty Assignments
    assignmentMathA1 = await FacultyAssignment.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      facultyId: facultyA1._id,
      facultyName: facultyA1.name,
      subjectId: subjectMath._id,
      courseId: courseA._id,
      semesterId: semesterA._id,
      academicYearId: academicYearA._id,
      sectionId: sectionA._id,
      status: 'active',
      isActive: true,
    });

    assignmentPhysicsA1 = await FacultyAssignment.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      facultyId: facultyA1._id,
      facultyName: facultyA1.name,
      subjectId: subjectPhysics._id,
      courseId: courseA._id,
      semesterId: semesterA._id,
      academicYearId: academicYearA._id,
      sectionId: sectionA._id,
      status: 'active',
      isActive: true,
    });

    assignmentMathA3 = await FacultyAssignment.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      facultyId: facultyA3._id,
      facultyName: facultyA3.name,
      subjectId: subjectMath._id,
      courseId: courseA._id,
      semesterId: semesterA._id,
      academicYearId: academicYearA._id,
      sectionId: sectionB._id,
      status: 'active',
      isActive: true,
    });

    // Master Timetables
    mondayEntryId = new mongoose.Types.ObjectId().toString();
    tuesdayEntryId = new mongoose.Types.ObjectId().toString();

    publishedTimetableA = await Timetable.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      semesterId: semesterA._id,
      academicYearId: academicYearA._id,
      sectionId: sectionA._id,
      name: 'CSE Section A Schedule',
      status: TimetableStatus.PUBLISHED,
      version: 1,
      periods: [
        { index: 1, name: 'P1', startTime: '10:00', endTime: '11:00' },
        { index: 2, name: 'P2', startTime: '11:00', endTime: '12:00' },
      ],
      breaks: [],
      entries: [
        {
          _id: new mongoose.Types.ObjectId(mondayEntryId),
          dayOfWeek: TimetableDay.MONDAY,
          startTime: '10:00',
          endTime: '11:00',
          subjectId: subjectMath._id,
          facultyId: facultyA1._id,
          facultyAssignmentId: assignmentMathA1._id,
          roomNumber: 'LHC-101',
          building: 'Main Block',
        },
        {
          _id: new mongoose.Types.ObjectId(tuesdayEntryId),
          dayOfWeek: TimetableDay.TUESDAY,
          startTime: '11:00',
          endTime: '12:00',
          subjectId: subjectPhysics._id,
          facultyId: facultyA1._id,
          facultyAssignmentId: assignmentPhysicsA1._id,
          roomNumber: 'LHC-102',
          building: 'Main Block',
        },
      ],
      createdBy: hodAUser._id,
    });

    // Second timetable with Faculty A3 teaching on Monday 10:30-11:30 (for double-booking test)
    await Timetable.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      semesterId: semesterA._id,
      academicYearId: academicYearA._id,
      sectionId: sectionB._id,
      name: 'CSE Section B Schedule',
      status: TimetableStatus.PUBLISHED,
      version: 1,
      periods: [
        { index: 1, name: 'P1', startTime: '10:30', endTime: '11:30' },
      ],
      breaks: [],
      entries: [
        {
          _id: new mongoose.Types.ObjectId(),
          dayOfWeek: TimetableDay.MONDAY,
          startTime: '10:30',
          endTime: '11:30',
          subjectId: subjectMath._id,
          facultyId: facultyA3._id,
          facultyAssignmentId: assignmentMathA3._id,
          roomNumber: 'LHC-103',
          building: 'Main Block',
        },
      ],
      createdBy: hodAUser._id,
    });
  });

  describe('Date-Specific Teacher Substitution Scenarios (A to S)', () => {
    // 2026-09-28 is a Monday in the civil calendar
    const normalMondayStr = '2026-09-28';
    // 2026-10-05 is the following Monday
    const followingMondayStr = '2026-10-05';
    // 2026-09-29 is Tuesday
    const normalTuesdayStr = '2026-09-29';

    it('A. create valid substitution', async () => {
      const res = await request(app)
        .post('/api/v1/teacher-substitutions')
        .set(hodAHeader)
        .send({
          timetableId: publishedTimetableA._id.toString(),
          timetableEntryId: mondayEntryId,
          date: normalMondayStr,
          substituteFacultyId: facultyA2._id.toString(),
          reason: 'Prof. Turing on duty attending ACM SIGMOD conference',
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.substituteFacultyId).toBe(facultyA2._id.toString());
      expect(res.body.data.originalFacultyId).toBe(facultyA1._id.toString());
      expect(res.body.data.status).toBe(TeacherSubstitutionStatus.ACTIVE);

      // College Admin A can also create valid substitution for Tuesday
      const adminRes = await request(app)
        .post('/api/v1/teacher-substitutions')
        .set(collegeAdminAHeader)
        .send({
          timetableId: publishedTimetableA._id.toString(),
          timetableEntryId: tuesdayEntryId,
          date: normalTuesdayStr,
          substituteFacultyId: facultyA2._id.toString(),
          reason: 'Admin assigned substitute',
        });
      expect(adminRes.status).toBe(201);
      expect(adminRes.body.data.substituteFacultyId).toBe(facultyA2._id.toString());
    });

    it('B. master timetable remains unchanged', async () => {
      // Create substitution
      await request(app)
        .post('/api/v1/teacher-substitutions')
        .set(hodAHeader)
        .send({
          timetableId: publishedTimetableA._id.toString(),
          timetableEntryId: mondayEntryId,
          date: normalMondayStr,
          substituteFacultyId: facultyA2._id.toString(),
          reason: 'Medical Leave coverage',
        });

      // Query master recurring timetable directly
      const currentTt = await Timetable.findById(publishedTimetableA._id);
      expect(currentTt).not.toBeNull();
      expect(currentTt!.status).toBe(TimetableStatus.PUBLISHED);
      expect(currentTt!.entries.length).toBe(2);
      // Faculty on entry MUST still be original faculty A1
      expect(currentTt!.entries[0].facultyId.toString()).toBe(facultyA1._id.toString());
      expect(currentTt!.entries[0].facultyAssignmentId?.toString()).toBe(assignmentMathA1._id.toString());
    });

    it('C. substitution applies only to specified date', async () => {
      await request(app)
        .post('/api/v1/teacher-substitutions')
        .set(hodAHeader)
        .send({
          timetableId: publishedTimetableA._id.toString(),
          timetableEntryId: mondayEntryId,
          date: normalMondayStr,
          substituteFacultyId: facultyA2._id.toString(),
          reason: 'Single-day substitution',
        });

      // Verify active substitution exists for 2026-09-28
      const sub = await TeacherSubstitution.findOne({
        timetableId: publishedTimetableA._id,
        timetableEntryId: mondayEntryId,
        date: normalMondayStr,
      });
      expect(sub).not.toBeNull();
      expect(sub!.substituteFacultyId.toString()).toBe(facultyA2._id.toString());

      // Query for another Monday (2026-10-05) has no substitution
      const followingSub = await TeacherSubstitution.findOne({
        timetableId: publishedTimetableA._id,
        timetableEntryId: mondayEntryId,
        date: followingMondayStr,
      });
      expect(followingSub).toBeNull();
    });

    it('D. following occurrence returns to original faculty', async () => {
      await request(app)
        .post('/api/v1/teacher-substitutions')
        .set(hodAHeader)
        .send({
          timetableId: publishedTimetableA._id.toString(),
          timetableEntryId: mondayEntryId,
          date: normalMondayStr,
          substituteFacultyId: facultyA2._id.toString(),
          reason: 'Single-day substitution',
        });

      // Query student view for following Monday: original teacher A1
      const followingStudentView = await request(app)
        .get(`/api/v1/timetables/students/me?date=${followingMondayStr}`)
        .set(studentHeader);
      expect(followingStudentView.status).toBe(200);
      expect(followingStudentView.body.data.length).toBe(1);
      expect(followingStudentView.body.data[0].facultyId).toBe(facultyA1._id.toString());
    });

    it('E. substitute faculty sees operational class on target date', async () => {
      await request(app)
        .post('/api/v1/teacher-substitutions')
        .set(hodAHeader)
        .send({
          timetableId: publishedTimetableA._id.toString(),
          timetableEntryId: mondayEntryId,
          date: normalMondayStr,
          substituteFacultyId: facultyA2._id.toString(),
          reason: 'Conference coverage',
        });

      // Substitute faculty A2 queries timetable for 2026-09-28
      const subFacultyView = await request(app)
        .get(`/api/v1/timetables/faculty/me?date=${normalMondayStr}`)
        .set(facultyA2Header);
      expect(subFacultyView.status).toBe(200);
      expect(subFacultyView.body.data.length).toBe(1);
      expect(subFacultyView.body.data[0].timetableId).toBe(publishedTimetableA._id.toString());
      expect(subFacultyView.body.data[0].isSubstituted).toBe(true);

      // Original faculty A1 queries timetable for 2026-09-28: replaced, sees 0 operational classes!
      const origFacultyView = await request(app)
        .get(`/api/v1/timetables/faculty/me?date=${normalMondayStr}`)
        .set(facultyA1Header);
      expect(origFacultyView.status).toBe(200);
      expect(origFacultyView.body.data.length).toBe(0);
    });

    it('F. original faculty loses attendance authorization on target date', async () => {
      await request(app)
        .post('/api/v1/teacher-substitutions')
        .set(hodAHeader)
        .send({
          timetableId: publishedTimetableA._id.toString(),
          timetableEntryId: mondayEntryId,
          date: normalMondayStr,
          substituteFacultyId: facultyA2._id.toString(),
          reason: 'Conference coverage',
        });

      // Original faculty A1 attempts to take attendance on substitution date: 403 Forbidden!
      const origAtt = await request(app)
        .post('/api/v1/attendance/sessions')
        .set(facultyA1Header)
        .send({
          timetableId: publishedTimetableA._id.toString(),
          timetableEntryId: mondayEntryId,
          date: normalMondayStr,
          timeSlot: '10:00 - 11:00',
          records: [{ studentId: studentProfile._id.toString(), status: 'present' }],
        });

      expect(origAtt.status).toBe(403);
      expect(getErrorMessage(origAtt)).toContain('assigned to another faculty');
    });

    it('G. substitute faculty can start attendance on target date', async () => {
      await request(app)
        .post('/api/v1/teacher-substitutions')
        .set(hodAHeader)
        .send({
          timetableId: publishedTimetableA._id.toString(),
          timetableEntryId: mondayEntryId,
          date: normalMondayStr,
          substituteFacultyId: facultyA2._id.toString(),
          reason: 'Conference coverage',
        });

      // Substitute faculty A2 opens attendance session on substitution date: 201 Created!
      const subAtt = await request(app)
        .post('/api/v1/attendance/sessions')
        .set(facultyA2Header)
        .send({
          timetableId: publishedTimetableA._id.toString(),
          timetableEntryId: mondayEntryId,
          date: normalMondayStr,
          timeSlot: '10:00 - 11:00',
          records: [{ studentId: studentProfile._id.toString(), status: 'present' }],
        });

      expect(subAtt.status).toBe(201);
      expect(subAtt.body.success).toBe(true);
      expect(subAtt.body.data.facultyId).toBe(facultyA2._id.toString());
    });

    it('H. substitute faculty cannot start attendance on another date', async () => {
      // Substitute created only for 2026-09-28
      await request(app)
        .post('/api/v1/teacher-substitutions')
        .set(hodAHeader)
        .send({
          timetableId: publishedTimetableA._id.toString(),
          timetableEntryId: mondayEntryId,
          date: normalMondayStr,
          substituteFacultyId: facultyA2._id.toString(),
          reason: 'Single day cover',
        });

      // Substitute faculty A2 attempts to take attendance on following Monday 2026-10-05: 403 Forbidden!
      const unauthorizedAtt = await request(app)
        .post('/api/v1/attendance/sessions')
        .set(facultyA2Header)
        .send({
          timetableId: publishedTimetableA._id.toString(),
          timetableEntryId: mondayEntryId,
          date: followingMondayStr,
          timeSlot: '10:00 - 11:00',
          records: [{ studentId: studentProfile._id.toString(), status: 'present' }],
        });

      expect(unauthorizedAtt.status).toBe(403);
    });

    it('I. substitute cannot be double-booked', async () => {
      // Faculty A3 already has class from 10:30 - 11:30 on Monday in publishedTimetableB
      // Attempting to assign Faculty A3 as substitute for class 10:00 - 11:00 on Monday must fail!
      const res = await request(app)
        .post('/api/v1/teacher-substitutions')
        .set(hodAHeader)
        .send({
          timetableId: publishedTimetableA._id.toString(),
          timetableEntryId: mondayEntryId,
          date: normalMondayStr,
          substituteFacultyId: facultyA3._id.toString(),
          reason: 'Double-booking attempt',
        });

      expect(res.status).toBe(409);
      expect(getErrorMessage(res)).toContain('Substitute faculty has a schedule conflict');
    });

    it('J. duplicate substitution rejected', async () => {
      // Create first substitution
      const res1 = await request(app)
        .post('/api/v1/teacher-substitutions')
        .set(hodAHeader)
        .send({
          timetableId: publishedTimetableA._id.toString(),
          timetableEntryId: mondayEntryId,
          date: normalMondayStr,
          substituteFacultyId: facultyA2._id.toString(),
          reason: 'First substitution',
        });
      expect(res1.status).toBe(201);

      // Attempt duplicate substitution for same timetable entry on same date
      const res2 = await request(app)
        .post('/api/v1/teacher-substitutions')
        .set(hodAHeader)
        .send({
          timetableId: publishedTimetableA._id.toString(),
          timetableEntryId: mondayEntryId,
          date: normalMondayStr,
          substituteFacultyId: facultyA2._id.toString(),
          reason: 'Duplicate substitution attempt',
        });

      expect(res2.status).toBe(409);
      expect(getErrorMessage(res2)).toContain('An active substitution already exists');
    });

    it('K. removing substitution restores original faculty', async () => {
      // 1. Create substitution
      const createRes = await request(app)
        .post('/api/v1/teacher-substitutions')
        .set(hodAHeader)
        .send({
          timetableId: publishedTimetableA._id.toString(),
          timetableEntryId: mondayEntryId,
          date: normalMondayStr,
          substituteFacultyId: facultyA2._id.toString(),
          reason: 'Temporary cover',
        });
      expect(createRes.status).toBe(201);
      const subId = createRes.body.data.id;

      // 2. Delete substitution
      const deleteRes = await request(app)
        .delete(`/api/v1/teacher-substitutions/${subId}`)
        .set(hodAHeader);
      expect(deleteRes.status).toBe(204);

      // 3. Original faculty A1 can now take attendance on that date again!
      const allowedAtt = await request(app)
        .post('/api/v1/attendance/sessions')
        .set(facultyA1Header)
        .send({
          timetableId: publishedTimetableA._id.toString(),
          timetableEntryId: mondayEntryId,
          date: normalMondayStr,
          timeSlot: '10:00 - 11:00',
          records: [{ studentId: studentProfile._id.toString(), status: 'present' }],
        });
      expect(allowedAtt.status).toBe(201);
      expect(allowedAtt.body.data.facultyId).toBe(facultyA1._id.toString());
    });

    it('L. cancelled class overrides substitution', async () => {
      // 1. Create substitution
      await request(app)
        .post('/api/v1/teacher-substitutions')
        .set(hodAHeader)
        .send({
          timetableId: publishedTimetableA._id.toString(),
          timetableEntryId: mondayEntryId,
          date: normalMondayStr,
          substituteFacultyId: facultyA2._id.toString(),
          reason: 'Temporary cover',
        });

      // 2. Class is cancelled on that date via CalendarOverride
      await CalendarOverride.create({
        collegeId: collegeA._id,
        departmentId: deptA._id,
        sectionId: sectionA._id,
        timetableEntryId: new mongoose.Types.ObjectId(mondayEntryId),
        date: normalMondayStr,
        type: CalendarOverrideType.CANCELLED,
        scope: CalendarOverrideScope.ENTRY,
        reason: 'Symposium cancellation',
        createdBy: collegeAdminAUser._id,
      });

      // 3. Substitute attempts attendance: rejected due to cancellation taking precedence!
      const attRes = await request(app)
        .post('/api/v1/attendance/sessions')
        .set(facultyA2Header)
        .send({
          timetableId: publishedTimetableA._id.toString(),
          timetableEntryId: mondayEntryId,
          date: normalMondayStr,
          timeSlot: '10:00 - 11:00',
          records: [{ studentId: studentProfile._id.toString(), status: 'present' }],
        });

      expect(attRes.status).toBe(400);
      expect(getErrorMessage(attRes)).toContain('Class has been cancelled for this date');
    });

    it('M. holiday overrides substitution', async () => {
      // 1. Create substitution
      await request(app)
        .post('/api/v1/teacher-substitutions')
        .set(hodAHeader)
        .send({
          timetableId: publishedTimetableA._id.toString(),
          timetableEntryId: mondayEntryId,
          date: normalMondayStr,
          substituteFacultyId: facultyA2._id.toString(),
          reason: 'Temporary cover',
        });

      // 2. College holiday declared
      await CalendarOverride.create({
        collegeId: collegeA._id,
        date: normalMondayStr,
        type: CalendarOverrideType.HOLIDAY,
        scope: CalendarOverrideScope.COLLEGE,
        reason: 'National Holiday',
        createdBy: collegeAdminAUser._id,
      });

      // 3. Attendance creation blocked by holiday precedence
      const attRes = await request(app)
        .post('/api/v1/attendance/sessions')
        .set(facultyA2Header)
        .send({
          timetableId: publishedTimetableA._id.toString(),
          timetableEntryId: mondayEntryId,
          date: normalMondayStr,
          timeSlot: '10:00 - 11:00',
          records: [{ studentId: studentProfile._id.toString(), status: 'present' }],
        });

      expect(attRes.status).toBe(400);
      expect(getErrorMessage(attRes)).toContain('declared holiday');
    });

    it('N. HOD cross-department substitution rejected', async () => {
      // HOD B (Mech) attempts to create substitution for CSE timetable
      const res = await request(app)
        .post('/api/v1/teacher-substitutions')
        .set(hodBHeader)
        .send({
          timetableId: publishedTimetableA._id.toString(),
          timetableEntryId: mondayEntryId,
          date: normalMondayStr,
          substituteFacultyId: facultyA2._id.toString(),
          reason: 'Cross department tampering attempt',
        });

      expect(res.status).toBe(403);
      expect(getErrorMessage(res)).toContain('assigned department');
    });

    it('O. HOD cross-college substitution rejected', async () => {
      // Create HOD in College B
      const hodCollegeBUser = await User.create({
        instituteId: 'HOD-COL-B',
        collegeId: collegeB._id,
        departmentId: new mongoose.Types.ObjectId(),
        name: 'HOD College B',
        email: 'hod.b@beta.edu',
        passwordHash: 'hash',
        role: AppRole.HOD,
        accountStatus: AccountStatus.ACTIVE,
      });
      const hodCollegeBHeader = createTestAuthHeader({
        userId: hodCollegeBUser.id,
        instituteId: hodCollegeBUser.instituteId,
        role: AppRole.HOD,
        collegeId: collegeB.id,
        departmentId: hodCollegeBUser.departmentId?.toString(),
      });

      const res = await request(app)
        .post('/api/v1/teacher-substitutions')
        .set(hodCollegeBHeader)
        .send({
          timetableId: publishedTimetableA._id.toString(),
          timetableEntryId: mondayEntryId,
          date: normalMondayStr,
          substituteFacultyId: facultyA2._id.toString(),
          reason: 'Cross college tampering',
        });

      expect(res.status).toBe(403);
      expect(getErrorMessage(res)).toContain('Cross-college');
    });

    it('P. Faculty cannot create substitution', async () => {
      const res = await request(app)
        .post('/api/v1/teacher-substitutions')
        .set(facultyA1Header)
        .send({
          timetableId: publishedTimetableA._id.toString(),
          timetableEntryId: mondayEntryId,
          date: normalMondayStr,
          substituteFacultyId: facultyA2._id.toString(),
          reason: 'Faculty self-arranging substitution',
        });

      expect(res.status).toBe(403);
    });

    it('Q. Student cannot create substitution', async () => {
      const res = await request(app)
        .post('/api/v1/teacher-substitutions')
        .set(studentHeader)
        .send({
          timetableId: publishedTimetableA._id.toString(),
          timetableEntryId: mondayEntryId,
          date: normalMondayStr,
          substituteFacultyId: facultyA2._id.toString(),
          reason: 'Student unauthorized substitution',
        });

      expect(res.status).toBe(403);
    });

    it('R. historical attendance remains unchanged', async () => {
      // 1. Session created by original faculty on 2026-09-28
      const sessionRes = await request(app)
        .post('/api/v1/attendance/sessions')
        .set(facultyA1Header)
        .send({
          timetableId: publishedTimetableA._id.toString(),
          timetableEntryId: mondayEntryId,
          date: normalMondayStr,
          timeSlot: '10:00 - 11:00',
          records: [{ studentId: studentProfile._id.toString(), status: 'present' }],
        });
      expect(sessionRes.status).toBe(201);
      const pastSessionId = sessionRes.body.data.id;

      // 2. Future substitution created for 2026-10-05
      await request(app)
        .post('/api/v1/teacher-substitutions')
        .set(hodAHeader)
        .send({
          timetableId: publishedTimetableA._id.toString(),
          timetableEntryId: mondayEntryId,
          date: followingMondayStr,
          substituteFacultyId: facultyA2._id.toString(),
          reason: 'Future substitution',
        });

      // 3. Past session remains completely intact
      const pastSession = await AttendanceSession.findById(pastSessionId);
      expect(pastSession).not.toBeNull();
      expect(pastSession!.facultyId.toString()).toBe(facultyA1._id.toString());
      expect(pastSession!.records.length).toBe(1);
    });

    it('S. timezone/date boundary behaves correctly', async () => {
      // 2026-09-28T19:00:00.000Z in UTC is 00:30 AM Tuesday 2026-09-29 in Asia/Kolkata
      const istEarlyTuesdayTimestamp = '2026-09-28T19:00:00.000Z';

      // Creating a substitution on Tuesday 2026-09-29 for Tuesday class
      const res = await request(app)
        .post('/api/v1/teacher-substitutions')
        .set(hodAHeader)
        .send({
          timetableId: publishedTimetableA._id.toString(),
          timetableEntryId: tuesdayEntryId,
          date: normalTuesdayStr,
          substituteFacultyId: facultyA2._id.toString(),
          reason: 'Tuesday substitute',
        });
      expect(res.status).toBe(201);

      // Substitute faculty A2 takes attendance using the UTC timestamp that falls into Tuesday IST
      const attRes = await request(app)
        .post('/api/v1/attendance/sessions')
        .set(facultyA2Header)
        .send({
          timetableId: publishedTimetableA._id.toString(),
          timetableEntryId: tuesdayEntryId,
          date: istEarlyTuesdayTimestamp,
          timeSlot: '11:00 - 12:00',
          records: [{ studentId: studentProfile._id.toString(), status: 'present' }],
        });

      expect(attRes.status).toBe(201);
      expect(attRes.body.data.facultyId).toBe(facultyA2._id.toString());
    });

    it('Tampering: rejects mismatched originalFacultyId, inactive substitute, and cross-department substitute', async () => {
      // 1. Mismatched originalFacultyId tampering
      const resMismatch = await request(app)
        .post('/api/v1/teacher-substitutions')
        .set(hodAHeader)
        .send({
          timetableId: publishedTimetableA._id.toString(),
          timetableEntryId: mondayEntryId,
          date: normalMondayStr,
          substituteFacultyId: facultyA2._id.toString(),
          originalFacultyId: facultyA3._id.toString(), // Wrong original faculty!
          reason: 'Tampered original faculty',
        });
      expect(resMismatch.status).toBe(400);
      expect(getErrorMessage(resMismatch)).toContain('Provided original faculty ID does not match');

      // 2. Inactive substitute faculty
      const inactiveFaculty = await Faculty.create({
        userId: new mongoose.Types.ObjectId(),
        collegeId: collegeA._id,
        departmentId: deptA._id,
        name: 'Inactive Prof',
        email: 'inactive@alpha.edu',
        status: 'inactive',
        isActive: false,
      });
      const resInactive = await request(app)
        .post('/api/v1/teacher-substitutions')
        .set(hodAHeader)
        .send({
          timetableId: publishedTimetableA._id.toString(),
          timetableEntryId: mondayEntryId,
          date: normalMondayStr,
          substituteFacultyId: inactiveFaculty._id.toString(),
          reason: 'Inactive sub attempt',
        });
      expect(resInactive.status).toBe(400);
      expect(getErrorMessage(resInactive)).toContain('inactive');

      // 3. HOD assigning substitute from another department (MECH faculty B1)
      const resCrossDept = await request(app)
        .post('/api/v1/teacher-substitutions')
        .set(hodAHeader)
        .send({
          timetableId: publishedTimetableA._id.toString(),
          timetableEntryId: mondayEntryId,
          date: normalMondayStr,
          substituteFacultyId: facultyB1._id.toString(),
          reason: 'Cross dept sub attempt',
        });
      expect(resCrossDept.status).toBe(403);
      expect(getErrorMessage(resCrossDept)).toContain('assigned department');
    });
  });
});
