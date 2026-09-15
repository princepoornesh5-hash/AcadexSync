import request from 'supertest';
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
import { Room } from '../../src/models/room.model';
import { Timetable } from '../../src/models/timetable.model';
import { AppRole } from '../../src/constants/roles';
import { CollegeStatus, DepartmentStatus, TimetableDay, TimetableStatus, AccountStatus } from '../../src/constants/status';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';
import { PasswordService } from '../../src/services/password.service';

describe('ACADEX — HOD Timetable Authoring Integration (Prompt 4 of 6)', () => {
  let collegeA: InstanceType<typeof College>;
  let collegeB: InstanceType<typeof College>;

  let deptA: InstanceType<typeof Department>;
  let deptB: InstanceType<typeof Department>;

  let courseA: InstanceType<typeof Course>;
  let courseOther: InstanceType<typeof Course>;

  let academicYearA: InstanceType<typeof AcademicYear>;
  let semesterA: InstanceType<typeof Semester>;
  let semesterOther: InstanceType<typeof Semester>;

  let sectionA: InstanceType<typeof Section>;
  let sectionB: InstanceType<typeof Section>;

  let subjectDBMS: InstanceType<typeof Subject>;
  let subjectOS: InstanceType<typeof Subject>;
  let subjectOtherSem: InstanceType<typeof Subject>;
  let subjectOtherCourse: InstanceType<typeof Subject>;

  let facultyA: InstanceType<typeof Faculty>;
  let facultyB: InstanceType<typeof Faculty>;
  let facultyOtherDept: InstanceType<typeof Faculty>;

  let studentUser: InstanceType<typeof User>;
  let studentDoc: InstanceType<typeof Student>;

  let room101: InstanceType<typeof Room>;
  let room102: InstanceType<typeof Room>;

  let assignmentDBMS_SecA: InstanceType<typeof FacultyAssignment>;
  let assignmentOS_SecA: InstanceType<typeof FacultyAssignment>;
  let assignmentInactive: InstanceType<typeof FacultyAssignment>;
  let assignmentSecB: InstanceType<typeof FacultyAssignment>;
  let assignmentOtherDept: InstanceType<typeof FacultyAssignment>;
  let assignmentOtherCollege: InstanceType<typeof FacultyAssignment>;
  let assignmentOtherSem: InstanceType<typeof FacultyAssignment>;
  let assignmentOtherCourse: InstanceType<typeof FacultyAssignment>;

  let hodAHeader: { Authorization: string };
  let hodBHeader: { Authorization: string };
  let facultyAHeader: { Authorization: string };
  let facultyBHeader: { Authorization: string };
  let studentHeader: { Authorization: string };
  let collegeAdminAHeader: { Authorization: string };

  beforeAll(async () => {
    await setupTestDB();
    await College.init();
    await User.init();
    await Department.init();
    await Course.init();
    await AcademicYear.init();
    await Semester.init();
    await Section.init();
    await Subject.init();
    await Faculty.init();
    await Student.init();
    await StudentEnrollment.init();
    await FacultyAssignment.init();
    await Room.init();
    await Timetable.init();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();
    const defaultPasswordHash = await PasswordService.hashPassword('Password123');

    // 1. Colleges
    collegeA = await College.create({
      name: 'Engineering College Alpha',
      code: 'ECA',
      address: 'Tech Park 1',
      email: 'admin@eca.edu',
      phone: '+919876543210',
      principal: 'Dr. Principal',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });

    collegeB = await College.create({
      name: 'Beta Tech Institute',
      code: 'BTI',
      address: 'Tech Park 2',
      email: 'admin@bti.edu',
      phone: '+919876543211',
      principal: 'Dr. Beta',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });

    // 2. Departments
    deptA = await Department.create({
      collegeId: collegeA._id,
      name: 'Computer Science & Engineering',
      code: 'CSE',
      status: DepartmentStatus.ACTIVE,
      isActive: true,
    });

    deptB = await Department.create({
      collegeId: collegeA._id,
      name: 'Mechanical Engineering',
      code: 'MECH',
      status: DepartmentStatus.ACTIVE,
      isActive: true,
    });

    const deptCollegeB = await Department.create({
      collegeId: collegeB._id,
      name: 'CSE Beta',
      code: 'CSE-B',
      status: DepartmentStatus.ACTIVE,
      isActive: true,
    });

    // 3. Courses
    courseA = await Course.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'B.Tech Computer Science',
      code: 'BT-CSE',
      durationYears: 4,
      totalSemesters: 8,
      status: 'active',
      isActive: true,
    });

    courseOther = await Course.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'B.Tech AI & Data Science',
      code: 'BT-AIDS',
      durationYears: 4,
      totalSemesters: 8,
      status: 'active',
      isActive: true,
    });

    // 4. Academic Year & Semesters
    academicYearA = await AcademicYear.create({
      collegeId: collegeA._id,
      name: '2026-2027',
      startDate: new Date('2026-07-01'),
      endDate: new Date('2027-06-30'),
      isCurrent: true,
      status: 'active',
      isActive: true,
    });

    semesterA = await Semester.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      name: 'Semester 5',
      number: 5,
      startDate: new Date('2026-07-15'),
      endDate: new Date('2026-12-15'),
      isCurrent: true,
      status: 'active',
      isActive: true,
    });

    semesterOther = await Semester.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      name: 'Semester 6',
      number: 6,
      startDate: new Date('2027-01-05'),
      endDate: new Date('2027-05-30'),
      isCurrent: false,
      status: 'active',
      isActive: true,
    });

    // 5. Sections
    sectionA = await Section.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      name: 'Section A',
      capacity: 60,
      status: 'active',
      isActive: true,
    });

    sectionB = await Section.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      name: 'Section B',
      capacity: 60,
      status: 'active',
      isActive: true,
    });

    // 6. Subjects
    subjectDBMS = await Subject.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      name: 'Database Management Systems',
      code: 'CS501',
      credits: 4,
      type: 'Theory',
      status: 'Active',
      isActive: true,
    });

    subjectOS = await Subject.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      name: 'Operating Systems',
      code: 'CS502',
      credits: 4,
      type: 'Theory',
      status: 'Active',
      isActive: true,
    });

    subjectOtherSem = await Subject.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterOther._id,
      name: 'Compiler Design',
      code: 'CS601',
      credits: 4,
      type: 'Theory',
      status: 'Active',
      isActive: true,
    });

    subjectOtherCourse = await Subject.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseOther._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      name: 'Mechanical Vibrations',
      code: 'ME501',
      credits: 4,
      type: 'Theory',
      status: 'Active',
      isActive: true,
    });

    // 7. Faculty Users & Profiles
    const userFacultyA = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      instituteId: 'FAC-ECA-01',
      name: 'Prof. Alan Turing',
      email: 'alan.turing@eca.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.FACULTY,
      status: AccountStatus.ACTIVE,
      isActive: true,
    });

    facultyA = await Faculty.create({
      userId: userFacultyA._id,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: userFacultyA.name,
      email: userFacultyA.email,
      phone: '+919811111111',
      designation: 'Professor',
      status: 'Active',
      isActive: true,
    });

    const userFacultyB = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      instituteId: 'FAC-ECA-02',
      name: 'Prof. Grace Hopper',
      email: 'grace.hopper@eca.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.FACULTY,
      status: AccountStatus.ACTIVE,
      isActive: true,
    });

    facultyB = await Faculty.create({
      userId: userFacultyB._id,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: userFacultyB.name,
      email: userFacultyB.email,
      phone: '+919822222222',
      designation: 'Associate Professor',
      status: 'Active',
      isActive: true,
    });

    const userFacultyOtherDept = await User.create({
      collegeId: collegeA._id,
      departmentId: deptB._id,
      instituteId: 'FAC-ECA-03',
      name: 'Prof. James Watt',
      email: 'james.watt@eca.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.FACULTY,
      status: AccountStatus.ACTIVE,
      isActive: true,
    });

    facultyOtherDept = await Faculty.create({
      userId: userFacultyOtherDept._id,
      collegeId: collegeA._id,
      departmentId: deptB._id,
      name: userFacultyOtherDept.name,
      email: userFacultyOtherDept.email,
      phone: '+919833333333',
      designation: 'Professor',
      status: 'Active',
      isActive: true,
    });

    // 8. HOD Users
    const userHodA = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      instituteId: 'HOD-ECA-01',
      name: 'Dr. Ada Lovelace',
      email: 'hod.cse@eca.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.HOD,
      status: AccountStatus.ACTIVE,
      isActive: true,
    });

    const userHodB = await User.create({
      collegeId: collegeA._id,
      departmentId: deptB._id,
      instituteId: 'HOD-ECA-02',
      name: 'Dr. Nikola Tesla',
      email: 'hod.mech@eca.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.HOD,
      status: AccountStatus.ACTIVE,
      isActive: true,
    });

    const userCollegeAdminA = await User.create({
      collegeId: collegeA._id,
      instituteId: 'ADM-ECA-01',
      name: 'College Admin ECA',
      email: 'admin.eca@eca.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.COLLEGE_ADMIN,
      status: AccountStatus.ACTIVE,
      isActive: true,
    });

    // 9. Student & Active Enrollment
    studentUser = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      instituteId: 'STU-ECA-01',
      name: 'Student Dennis Ritchie',
      email: 'dennis.ritchie@eca.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.STUDENT,
      status: AccountStatus.ACTIVE,
      isActive: true,
    });

    studentDoc = await Student.create({
      userId: studentUser._id,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: studentUser.name,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      admissionNumber: 'ADM-2026-001',
      rollNumber: 'CSE-2026-01',
      status: 'active',
      isActive: true,
    });

    await StudentEnrollment.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      studentId: studentDoc._id,
      status: 'active',
      enrollmentDate: new Date(),
    });

    // 10. Rooms
    room101 = await Room.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'Lecture Hall 101',
      code: 'LH-101',
      capacity: 70,
      type: 'lecture',
      status: 'active',
      isActive: true,
    });

    room102 = await Room.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'Lecture Hall 102',
      code: 'LH-102',
      capacity: 70,
      type: 'lecture',
      status: 'active',
      isActive: true,
    });

    // 11. Faculty Assignments (Authoritative)
    assignmentDBMS_SecA = await FacultyAssignment.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      subjectId: subjectDBMS._id,
      facultyId: facultyA._id,
      facultyName: facultyA.name,
      assignmentType: 'primary',
      status: 'active',
      isActive: true,
    });

    assignmentOS_SecA = await FacultyAssignment.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      subjectId: subjectOS._id,
      facultyId: facultyB._id,
      facultyName: facultyB.name,
      assignmentType: 'primary',
      status: 'active',
      isActive: true,
    });

    assignmentInactive = await FacultyAssignment.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      subjectId: subjectDBMS._id,
      facultyId: facultyB._id,
      facultyName: facultyB.name,
      assignmentType: 'assistant',
      status: 'completed',
      isActive: false, // Inactive!
    });

    assignmentSecB = await FacultyAssignment.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionB._id, // Section B!
      subjectId: subjectDBMS._id,
      facultyId: facultyA._id,
      facultyName: facultyA.name,
      assignmentType: 'primary',
      status: 'active',
      isActive: true,
    });

    assignmentOtherDept = await FacultyAssignment.create({
      collegeId: collegeA._id,
      departmentId: deptB._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      subjectId: subjectDBMS._id,
      facultyId: facultyOtherDept._id,
      facultyName: facultyOtherDept.name,
      assignmentType: 'primary',
      status: 'active',
      isActive: true,
    });

    assignmentOtherCollege = await FacultyAssignment.create({
      collegeId: collegeB._id,
      departmentId: deptCollegeB._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      subjectId: subjectDBMS._id,
      facultyId: facultyA._id,
      facultyName: facultyA.name,
      assignmentType: 'primary',
      status: 'active',
      isActive: true,
    });

    assignmentOtherSem = await FacultyAssignment.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterOther._id, // Semester 6!
      sectionId: sectionA._id,
      subjectId: subjectOtherSem._id,
      facultyId: facultyA._id,
      facultyName: facultyA.name,
      assignmentType: 'primary',
      status: 'active',
      isActive: true,
    });

    assignmentOtherCourse = await FacultyAssignment.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseOther._id, // Course Other!
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      subjectId: subjectOtherCourse._id,
      facultyId: facultyA._id,
      facultyName: facultyA.name,
      assignmentType: 'primary',
      status: 'active',
      isActive: true,
    });

    // 12. Auth Headers
    hodAHeader = createTestAuthHeader({
      userId: userHodA._id.toString(),
      collegeId: collegeA._id.toString(),
      role: AppRole.HOD,
      departmentId: deptA._id.toString(),
    });
    hodBHeader = createTestAuthHeader({
      userId: userHodB._id.toString(),
      collegeId: collegeA._id.toString(),
      role: AppRole.HOD,
      departmentId: deptB._id.toString(),
    });
    facultyAHeader = createTestAuthHeader({
      userId: userFacultyA._id.toString(),
      collegeId: collegeA._id.toString(),
      role: AppRole.FACULTY,
      departmentId: deptA._id.toString(),
    });
    facultyBHeader = createTestAuthHeader({
      userId: userFacultyB._id.toString(),
      collegeId: collegeA._id.toString(),
      role: AppRole.FACULTY,
      departmentId: deptA._id.toString(),
    });
    studentHeader = createTestAuthHeader({
      userId: studentUser._id.toString(),
      collegeId: collegeA._id.toString(),
      role: AppRole.STUDENT,
      departmentId: deptA._id.toString(),
    });
    collegeAdminAHeader = createTestAuthHeader({
      userId: userCollegeAdminA._id.toString(),
      collegeId: collegeA._id.toString(),
      role: AppRole.COLLEGE_ADMIN,
    });
  });

  // =========================================================================
  // 1. HOD Timetable Authoring with FacultyAssignment
  // =========================================================================
  it('1. HOD creates timetable entry using valid FacultyAssignment in own department', async () => {
    const res = await request(app)
      .post('/api/v1/timetables')
      .set(hodAHeader)
      .send({
        departmentId: deptA.id,
        courseId: courseA.id,
        academicYearId: academicYearA.id,
        semesterId: semesterA.id,
        sectionId: sectionA.id,
        name: 'CSE Sem 5 Section A Timetable',
        entries: [
          {
            dayOfWeek: TimetableDay.MONDAY,
            startTime: '09:00',
            endTime: '10:00',
            facultyAssignmentId: assignmentDBMS_SecA.id,
            roomId: room101.id,
            roomNumber: 'LH-101',
          },
        ],
      });

    expect(res.status).toBe(201);
    expect(res.body.data.status).toBe(TimetableStatus.DRAFT);
    expect(res.body.data.entries).toHaveLength(1);
    // Verified authoritative resolution
    expect(res.body.data.entries[0].subjectId).toBe(subjectDBMS.id);
    expect(res.body.data.entries[0].facultyId).toBe(facultyA.id);
    expect(res.body.data.entries[0].facultyAssignmentId).toBe(assignmentDBMS_SecA.id);
  });

  it('2. Invalid FacultyAssignment ID is rejected', async () => {
    const res = await request(app)
      .post('/api/v1/timetables')
      .set(hodAHeader)
      .send({
        departmentId: deptA.id,
        courseId: courseA.id,
        academicYearId: academicYearA.id,
        semesterId: semesterA.id,
        sectionId: sectionA.id,
        name: 'Invalid Assignment Test',
        entries: [
          {
            dayOfWeek: TimetableDay.MONDAY,
            startTime: '09:00',
            endTime: '10:00',
            facultyAssignmentId: '507f1f77bcf86cd799439011', // Non-existent
            roomId: room101.id,
            roomNumber: 'LH-101',
          },
        ],
      });

    expect(res.status).toBe(400);
    expect(res.body.error.message).toMatch(/Faculty assignment does not match/i);
  });

  it('3. Assignment from another section is rejected', async () => {
    const res = await request(app)
      .post('/api/v1/timetables')
      .set(hodAHeader)
      .send({
        departmentId: deptA.id,
        courseId: courseA.id,
        academicYearId: academicYearA.id,
        semesterId: semesterA.id,
        sectionId: sectionA.id,
        name: 'Wrong Section Assignment Test',
        entries: [
          {
            dayOfWeek: TimetableDay.MONDAY,
            startTime: '09:00',
            endTime: '10:00',
            facultyAssignmentId: assignmentSecB.id, // Section B assignment into Section A!
            roomId: room101.id,
            roomNumber: 'LH-101',
          },
        ],
      });

    expect(res.status).toBe(400);
    expect(res.body.error.message).toMatch(/Faculty assignment does not match this section/i);
  });

  it('4. Assignment from another semester is rejected', async () => {
    const res = await request(app)
      .post('/api/v1/timetables')
      .set(hodAHeader)
      .send({
        departmentId: deptA.id,
        courseId: courseA.id,
        academicYearId: academicYearA.id,
        semesterId: semesterA.id,
        sectionId: sectionA.id,
        name: 'Wrong Semester Assignment Test',
        entries: [
          {
            dayOfWeek: TimetableDay.MONDAY,
            startTime: '09:00',
            endTime: '10:00',
            facultyAssignmentId: assignmentOtherSem.id, // Semester 6 assignment into Semester 5!
            roomId: room101.id,
            roomNumber: 'LH-101',
          },
        ],
      });

    expect(res.status).toBe(400);
    expect(res.body.error.message).toMatch(/Faculty assignment does not match this semester/i);
  });

  it('5. Assignment from another course is rejected', async () => {
    const res = await request(app)
      .post('/api/v1/timetables')
      .set(hodAHeader)
      .send({
        departmentId: deptA.id,
        courseId: courseA.id,
        academicYearId: academicYearA.id,
        semesterId: semesterA.id,
        sectionId: sectionA.id,
        name: 'Wrong Course Assignment Test',
        entries: [
          {
            dayOfWeek: TimetableDay.MONDAY,
            startTime: '09:00',
            endTime: '10:00',
            facultyAssignmentId: assignmentOtherCourse.id, // Course Other into Course A!
            roomId: room101.id,
            roomNumber: 'LH-101',
          },
        ],
      });

    expect(res.status).toBe(400);
    expect(res.body.error.message).toMatch(/Faculty assignment does not match this course/i);
  });

  it('6. Assignment from another department is rejected', async () => {
    const res = await request(app)
      .post('/api/v1/timetables')
      .set(hodAHeader)
      .send({
        departmentId: deptA.id,
        courseId: courseA.id,
        academicYearId: academicYearA.id,
        semesterId: semesterA.id,
        sectionId: sectionA.id,
        name: 'Wrong Department Assignment Test',
        entries: [
          {
            dayOfWeek: TimetableDay.MONDAY,
            startTime: '09:00',
            endTime: '10:00',
            facultyAssignmentId: assignmentOtherDept.id, // Dept B assignment into Dept A section!
            roomId: room101.id,
            roomNumber: 'LH-101',
          },
        ],
      });

    expect(res.status).toBe(400);
    expect(res.body.error.message).toMatch(/Faculty assignment does not match this department/i);
  });

  it('7. Assignment from another college is rejected', async () => {
    const res = await request(app)
      .post('/api/v1/timetables')
      .set(hodAHeader)
      .send({
        departmentId: deptA.id,
        courseId: courseA.id,
        academicYearId: academicYearA.id,
        semesterId: semesterA.id,
        sectionId: sectionA.id,
        name: 'Wrong College Assignment Test',
        entries: [
          {
            dayOfWeek: TimetableDay.MONDAY,
            startTime: '09:00',
            endTime: '10:00',
            facultyAssignmentId: assignmentOtherCollege.id, // College B assignment into College A!
            roomId: room101.id,
            roomNumber: 'LH-101',
          },
        ],
      });

    expect(res.status).toBe(400);
    expect(res.body.error.message).toMatch(/Faculty assignment does not match this college/i);
  });

  it('8. Inactive FacultyAssignment is rejected', async () => {
    const res = await request(app)
      .post('/api/v1/timetables')
      .set(hodAHeader)
      .send({
        departmentId: deptA.id,
        courseId: courseA.id,
        academicYearId: academicYearA.id,
        semesterId: semesterA.id,
        sectionId: sectionA.id,
        name: 'Inactive Assignment Test',
        entries: [
          {
            dayOfWeek: TimetableDay.MONDAY,
            startTime: '09:00',
            endTime: '10:00',
            facultyAssignmentId: assignmentInactive.id, // Inactive!
            roomId: room101.id,
            roomNumber: 'LH-101',
          },
        ],
      });

    expect(res.status).toBe(400);
    expect(res.body.error.message).toMatch(/Faculty assignment does not match this subject and section or is inactive/i);
  });

  it('9. Faculty conflict is rejected when faculty is already scheduled in published timetable', async () => {
    // 1. Publish timetable where Faculty A teaches Monday 09:00-10:00 in Section B
    await Timetable.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionB._id,
      name: 'Published Section B',
      status: TimetableStatus.PUBLISHED,
      entries: [
        {
          dayOfWeek: TimetableDay.MONDAY,
          startTime: '09:00',
          endTime: '10:00',
          subjectId: subjectDBMS._id,
          facultyId: facultyA._id,
          facultyAssignmentId: assignmentSecB._id,
          roomId: room102._id,
          roomNumber: 'LH-102',
          sessionType: 'lecture',
        },
      ],
    });

    // 2. Try to schedule Faculty A in Section A on Monday 09:30-10:30 (overlapping)
    const res = await request(app)
      .post('/api/v1/timetables')
      .set(hodAHeader)
      .send({
        departmentId: deptA.id,
        courseId: courseA.id,
        academicYearId: academicYearA.id,
        semesterId: semesterA.id,
        sectionId: sectionA.id,
        name: 'Section A Overlapping Faculty',
        entries: [
          {
            dayOfWeek: TimetableDay.MONDAY,
            startTime: '09:30',
            endTime: '10:30',
            facultyAssignmentId: assignmentDBMS_SecA.id,
            roomId: room101.id,
            roomNumber: 'LH-101',
          },
        ],
      });

    expect(res.status).toBe(409);
    expect(res.body.error.message).toMatch(/Faculty conflict/i);
  });

  it('10. Section conflict is rejected when multiple entries overlap simultaneously in the section', async () => {
    const res = await request(app)
      .post('/api/v1/timetables')
      .set(hodAHeader)
      .send({
        departmentId: deptA.id,
        courseId: courseA.id,
        academicYearId: academicYearA.id,
        semesterId: semesterA.id,
        sectionId: sectionA.id,
        name: 'Internal Section Overlap',
        entries: [
          {
            dayOfWeek: TimetableDay.MONDAY,
            startTime: '09:00',
            endTime: '10:00',
            facultyAssignmentId: assignmentDBMS_SecA.id,
            roomId: room101.id,
            roomNumber: 'LH-101',
          },
          {
            dayOfWeek: TimetableDay.MONDAY,
            startTime: '09:30', // Overlaps with 09:00-10:00!
            endTime: '10:30',
            facultyAssignmentId: assignmentOS_SecA.id,
            roomId: room102.id,
            roomNumber: 'LH-102',
          },
        ],
      });

    expect(res.status).toBe(409);
    expect(res.body.error.message).toMatch(/Section conflict/i);
  });

  it('11. Room conflict is rejected when room is already booked in published timetable', async () => {
    // 1. Publish Section B in Room 101 on Monday 11:00-12:00
    await Timetable.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionB._id,
      name: 'Published Section B Room 101',
      status: TimetableStatus.PUBLISHED,
      entries: [
        {
          dayOfWeek: TimetableDay.MONDAY,
          startTime: '11:00',
          endTime: '12:00',
          subjectId: subjectDBMS._id,
          facultyId: facultyA._id,
          facultyAssignmentId: assignmentSecB._id,
          roomId: room101._id,
          roomNumber: 'LH-101',
          sessionType: 'lecture',
        },
      ],
    });

    // 2. Section A tries to book Room 101 on Monday 11:30-12:30 (overlapping)
    const res = await request(app)
      .post('/api/v1/timetables')
      .set(hodAHeader)
      .send({
        departmentId: deptA.id,
        courseId: courseA.id,
        academicYearId: academicYearA.id,
        semesterId: semesterA.id,
        sectionId: sectionA.id,
        name: 'Section A Room Overlap',
        entries: [
          {
            dayOfWeek: TimetableDay.MONDAY,
            startTime: '11:30',
            endTime: '12:30',
            facultyAssignmentId: assignmentOS_SecA.id,
            roomId: room101.id,
            roomNumber: 'LH-101',
          },
        ],
      });

    expect(res.status).toBe(409);
    expect(res.body.error.message).toMatch(/Room conflict/i);
  });

  it('12. Invalid time range (startTime >= endTime) is rejected', async () => {
    const res = await request(app)
      .post('/api/v1/timetables')
      .set(hodAHeader)
      .send({
        departmentId: deptA.id,
        courseId: courseA.id,
        academicYearId: academicYearA.id,
        semesterId: semesterA.id,
        sectionId: sectionA.id,
        name: 'Invalid Time Test',
        entries: [
          {
            dayOfWeek: TimetableDay.MONDAY,
            startTime: '11:00',
            endTime: '10:00', // start > end!
            facultyAssignmentId: assignmentDBMS_SecA.id,
            roomId: room101.id,
            roomNumber: 'LH-101',
          },
        ],
      });

    expect([400, 422]).toContain(res.status);
  });

  it('13. Valid draft timetable saves successfully without publishing', async () => {
    const res = await request(app)
      .post('/api/v1/timetables')
      .set(hodAHeader)
      .send({
        departmentId: deptA.id,
        courseId: courseA.id,
        academicYearId: academicYearA.id,
        semesterId: semesterA.id,
        sectionId: sectionA.id,
        name: 'Draft Schedule 1',
        status: TimetableStatus.DRAFT,
        entries: [
          {
            dayOfWeek: TimetableDay.TUESDAY,
            startTime: '09:00',
            endTime: '10:00',
            facultyAssignmentId: assignmentDBMS_SecA.id,
            roomId: room101.id,
            roomNumber: 'LH-101',
          },
        ],
      });

    expect(res.status).toBe(201);
    expect(res.body.data.status).toBe(TimetableStatus.DRAFT);
    expect(res.body.data.publishedAt).toBeNull();
  });

  it('14. Invalid draft cannot publish (atomic failure preserves previous draft state)', async () => {
    // 1. Create a draft with Faculty A scheduled on Wednesday 09:00-10:00
    const draft = await Timetable.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      name: 'To Fail Publish',
      status: TimetableStatus.DRAFT,
      entries: [
        {
          dayOfWeek: TimetableDay.WEDNESDAY,
          startTime: '09:00',
          endTime: '10:00',
          subjectId: subjectDBMS._id,
          facultyId: facultyA._id,
          facultyAssignmentId: assignmentDBMS_SecA._id,
          roomId: room101._id,
          roomNumber: 'LH-101',
          sessionType: 'lecture',
        },
      ],
    });

    // 2. Publish another timetable in Section B with Faculty A on Wednesday 09:00-10:00
    await Timetable.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionB._id,
      name: 'Section B Wednesday Conflicting',
      status: TimetableStatus.PUBLISHED,
      entries: [
        {
          dayOfWeek: TimetableDay.WEDNESDAY,
          startTime: '09:00',
          endTime: '10:00',
          subjectId: subjectDBMS._id,
          facultyId: facultyA._id,
          facultyAssignmentId: assignmentSecB._id,
          roomId: room102._id,
          roomNumber: 'LH-102',
          sessionType: 'lecture',
        },
      ],
    });

    // 3. Attempt publish of draft
    const res = await request(app)
      .post(`/api/v1/timetables/${draft.id}/publish`)
      .set(hodAHeader);

    expect(res.status).toBe(409);
    expect(res.body.error.message).toMatch(/Faculty conflict/i);

    // Verify draft remains strictly DRAFT
    const persisted = await Timetable.findById(draft.id);
    expect(persisted?.status).toBe(TimetableStatus.DRAFT);
    expect(persisted?.publishedAt).toBeNull();
  });

  it('15. Valid draft publishes successfully with full validation', async () => {
    const draft = await Timetable.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      name: 'Clean Draft To Publish',
      status: TimetableStatus.DRAFT,
      entries: [
        {
          dayOfWeek: TimetableDay.THURSDAY,
          startTime: '09:00',
          endTime: '10:00',
          subjectId: subjectDBMS._id,
          facultyId: facultyA._id,
          facultyAssignmentId: assignmentDBMS_SecA._id,
          roomId: room101._id,
          roomNumber: 'LH-101',
          sessionType: 'lecture',
        },
      ],
    });

    const res = await request(app)
      .post(`/api/v1/timetables/${draft.id}/publish`)
      .set(hodAHeader);

    expect(res.status).toBe(200);
    expect(res.body.data.status).toBe(TimetableStatus.PUBLISHED);
    expect(res.body.data.publishedAt).toBeDefined();
  });

  it('16. Publishing a new timetable for a section auto-drafts the previous published timetable', async () => {
    // 1. Create and publish version 1
    const v1 = await Timetable.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      name: 'Timetable v1',
      version: 1,
      status: TimetableStatus.PUBLISHED,
      publishedAt: new Date('2026-08-01'),
      entries: [
        {
          dayOfWeek: TimetableDay.FRIDAY,
          startTime: '09:00',
          endTime: '10:00',
          subjectId: subjectDBMS._id,
          facultyId: facultyA._id,
          facultyAssignmentId: assignmentDBMS_SecA._id,
          roomId: room101._id,
          roomNumber: 'LH-101',
          sessionType: 'lecture',
        },
      ],
    });

    // 2. Create version 2 draft
    const v2 = await Timetable.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      name: 'Timetable v2',
      version: 2,
      status: TimetableStatus.DRAFT,
      entries: [
        {
          dayOfWeek: TimetableDay.FRIDAY,
          startTime: '10:00',
          endTime: '11:00',
          subjectId: subjectOS._id,
          facultyId: facultyB._id,
          facultyAssignmentId: assignmentOS_SecA._id,
          roomId: room102._id,
          roomNumber: 'LH-102',
          sessionType: 'lecture',
        },
      ],
    });

    // 3. Publish v2
    const res = await request(app)
      .post(`/api/v1/timetables/${v2.id}/publish`)
      .set(hodAHeader);

    expect(res.status).toBe(200);
    expect(res.body.data.status).toBe(TimetableStatus.PUBLISHED);

    // Verify v1 has been automatically demoted to DRAFT
    const reloadedV1 = await Timetable.findById(v1.id);
    expect(reloadedV1?.status).toBe(TimetableStatus.DRAFT);
  });

  it('17. Unpublish transitions published timetable back to DRAFT', async () => {
    const published = await Timetable.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      name: 'To Unpublish',
      status: TimetableStatus.PUBLISHED,
      publishedAt: new Date(),
      entries: [],
    });

    const res = await request(app)
      .post(`/api/v1/timetables/${published.id}/unpublish`)
      .set(hodAHeader);

    expect(res.status).toBe(200);
    expect(res.body.data.status).toBe(TimetableStatus.DRAFT);

    const doc = await Timetable.findById(published.id);
    expect(doc?.status).toBe(TimetableStatus.DRAFT);
  });

  it('18. Archive transition behaves safely without destructive deletion', async () => {
    const timetable = await Timetable.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      name: 'To Archive',
      status: TimetableStatus.DRAFT,
      entries: [],
    });

    const res = await request(app)
      .post(`/api/v1/timetables/${timetable.id}/archive`)
      .set(hodAHeader);

    expect(res.status).toBe(200);
    expect(res.body.data.status).toBe(TimetableStatus.ARCHIVED);

    const doc = await Timetable.findById(timetable.id);
    expect(doc).not.toBeNull();
    expect(doc?.status).toBe(TimetableStatus.ARCHIVED);
  });

  it('19. HOD cannot manipulate another department timetable', async () => {
    const timetableDeptA = await Timetable.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      name: 'Dept A Schedule',
      status: TimetableStatus.DRAFT,
      entries: [],
    });

    // HOD B (Mechanical) attempts to update Dept A timetable
    const updateRes = await request(app)
      .put(`/api/v1/timetables/${timetableDeptA.id}`)
      .set(hodBHeader)
      .send({ name: 'Hacked by Mech' });

    expect(updateRes.status).toBe(403);
    expect(updateRes.body.error.message).toMatch(/Cross-department timetable updates are prohibited/i);

    // HOD B attempts to publish Dept A timetable
    const pubRes = await request(app)
      .post(`/api/v1/timetables/${timetableDeptA.id}/publish`)
      .set(hodBHeader);

    expect(pubRes.status).toBe(403);
  });

  it('20. Unauthorized roles (Faculty and Student) cannot author timetables', async () => {
    // Faculty attempts to create
    const facultyRes = await request(app)
      .post('/api/v1/timetables')
      .set(facultyAHeader)
      .send({
        departmentId: deptA.id,
        courseId: courseA.id,
        academicYearId: academicYearA.id,
        semesterId: semesterA.id,
        sectionId: sectionA.id,
        name: 'Faculty Created',
      });

    expect(facultyRes.status).toBe(403);

    // Student attempts to create
    const studentRes = await request(app)
      .post('/api/v1/timetables')
      .set(studentHeader)
      .send({
        departmentId: deptA.id,
        courseId: courseA.id,
        academicYearId: academicYearA.id,
        semesterId: semesterA.id,
        sectionId: sectionA.id,
        name: 'Student Created',
      });

    expect(studentRes.status).toBe(403);
  });

  // =========================================================================
  // 2. Cross-Module Integrity & Retrieval Contracts
  // =========================================================================
  it('21-25. Timetable entry references real FacultyAssignment, Subject, Faculty, Section and consistent context', async () => {
    const res = await request(app)
      .post('/api/v1/timetables')
      .set(hodAHeader)
      .send({
        departmentId: deptA.id,
        courseId: courseA.id,
        academicYearId: academicYearA.id,
        semesterId: semesterA.id,
        sectionId: sectionA.id,
        name: 'Integrity Contract Schedule',
        entries: [
          {
            dayOfWeek: TimetableDay.MONDAY,
            startTime: '14:00',
            endTime: '15:00',
            facultyAssignmentId: assignmentDBMS_SecA.id,
            roomId: room101.id,
            roomNumber: 'LH-101',
          },
        ],
      });

    expect(res.status).toBe(201);
    const entry = res.body.data.entries[0];

    // Contract 21: Real FacultyAssignment
    const assignment = await FacultyAssignment.findById(entry.facultyAssignmentId);
    expect(assignment).not.toBeNull();

    // Contract 22: Real Faculty
    const faculty = await Faculty.findById(entry.facultyId);
    expect(faculty?.name).toBe('Prof. Alan Turing');

    // Contract 23: Real Subject
    const subject = await Subject.findById(entry.subjectId);
    expect(subject?.code).toBe('CS501');

    // Contract 24: Real Section
    const section = await Section.findById(res.body.data.sectionId);
    expect(section?.name).toBe('Section A');

    // Contract 25: Consistent Academic Context
    expect(assignment?.courseId.toString()).toBe(res.body.data.courseId);
    expect(assignment?.semesterId.toString()).toBe(res.body.data.semesterId);
    expect(assignment?.sectionId.toString()).toBe(res.body.data.sectionId);
  });

  it('26. Published timetable can be retrieved by intended consumer roles', async () => {
    // Publish a clean timetable for Section A
    const published = await Timetable.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      name: 'Published Section A Final',
      status: TimetableStatus.PUBLISHED,
      publishedAt: new Date(),
      entries: [
        {
          dayOfWeek: TimetableDay.MONDAY,
          startTime: '09:00',
          endTime: '10:00',
          subjectId: subjectDBMS._id,
          facultyId: facultyA._id,
          facultyAssignmentId: assignmentDBMS_SecA._id,
          roomId: room101._id,
          roomNumber: 'LH-101',
          sessionType: 'lecture',
        },
      ],
    });

    // College Admin queries
    const adminRes = await request(app)
      .get(`/api/v1/timetables/${published.id}`)
      .set(collegeAdminAHeader);
    expect(adminRes.status).toBe(200);
    expect(adminRes.body.data.name).toBe('Published Section A Final');

    // HOD queries
    const hodRes = await request(app)
      .get(`/api/v1/timetables/${published.id}`)
      .set(hodAHeader);
    expect(hodRes.status).toBe(200);
  });

  it('27. Faculty-scoped retrieval returns only the authenticated faculty member’s assigned entries', async () => {
    // Published timetable has 2 entries:
    // Entry 1: Monday 09:00-10:00 Faculty A (DBMS)
    // Entry 2: Monday 10:15-11:15 Faculty B (OS)
    await Timetable.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      name: 'Multi-Faculty Published',
      status: TimetableStatus.PUBLISHED,
      publishedAt: new Date(),
      entries: [
        {
          dayOfWeek: TimetableDay.MONDAY,
          startTime: '09:00',
          endTime: '10:00',
          subjectId: subjectDBMS._id,
          facultyId: facultyA._id,
          facultyAssignmentId: assignmentDBMS_SecA._id,
          roomId: room101._id,
          roomNumber: 'LH-101',
          sessionType: 'lecture',
        },
        {
          dayOfWeek: TimetableDay.MONDAY,
          startTime: '10:15',
          endTime: '11:15',
          subjectId: subjectOS._id,
          facultyId: facultyB._id,
          facultyAssignmentId: assignmentOS_SecA._id,
          roomId: room102._id,
          roomNumber: 'LH-102',
          sessionType: 'lecture',
        },
      ],
    });

    // Faculty A queries their schedule
    const resA = await request(app)
      .get('/api/v1/timetables/faculty/me')
      .set(facultyAHeader);

    expect(resA.status).toBe(200);
    expect(resA.body.data).toHaveLength(1);
    expect(resA.body.data[0].facultyId).toBe(facultyA.id);
    expect(resA.body.data[0].subjectId).toBe(subjectDBMS.id);

    // Faculty B queries their schedule
    const resB = await request(app)
      .get('/api/v1/timetables/faculty/me')
      .set(facultyBHeader);

    expect(resB.status).toBe(200);
    expect(resB.body.data).toHaveLength(1);
    expect(resB.body.data[0].facultyId).toBe(facultyB.id);
    expect(resB.body.data[0].subjectId).toBe(subjectOS.id);
  });

  it('28. Student timetable retrieval resolves published schedule for their active enrolled section read-only', async () => {
    // Published timetable for Section A (where student Dennis Ritchie is actively enrolled)
    await Timetable.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionA._id,
      name: 'Section A Official Timetable',
      status: TimetableStatus.PUBLISHED,
      publishedAt: new Date(),
      entries: [
        {
          dayOfWeek: TimetableDay.MONDAY,
          startTime: '09:00',
          endTime: '10:00',
          subjectId: subjectDBMS._id,
          facultyId: facultyA._id,
          facultyAssignmentId: assignmentDBMS_SecA._id,
          roomId: room101._id,
          roomNumber: 'LH-101',
          sessionType: 'lecture',
        },
      ],
    });

    const res = await request(app)
      .get('/api/v1/timetables/students/me')
      .set(studentHeader);

    expect(res.status).toBe(200);
    expect(res.body.data).toHaveLength(1);
    expect(res.body.data[0].subjectId).toBe(subjectDBMS.id);
    expect(res.body.data[0].roomNumber).toBe('LH-101');
  });
});
