import request from 'supertest';
import { app } from '../../src/app';
import { College } from '../../src/models/college.model';
import { User } from '../../src/models/user.model';
import { Department } from '../../src/models/department.model';
import { Course } from '../../src/models/course.model';
import { AcademicYear } from '../../src/models/academicYear.model';
import { Semester } from '../../src/models/semester.model';
import { Subject } from '../../src/models/subject.model';
import { Student } from '../../src/models/student.model';
import { Faculty } from '../../src/models/faculty.model';
import { FacultyAssignment } from '../../src/models/facultyAssignment.model';
import { StudentEnrollment } from '../../src/models/studentEnrollment.model';
import { InstitutionConfiguration } from '../../src/models/institutionConfiguration.model';
import { Section } from '../../src/models/section.model';
import { Note } from '../../src/models/note.model';
import { TeachingAuthorizationService } from '../../src/services/teachingAuthorization.service';
import { AppRole } from '../../src/constants/roles';
import { AccountStatus, CollegeStatus, DepartmentStatus } from '../../src/constants/status';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';
import { PasswordService } from '../../src/services/password.service';

describe('PROMPT 34 — Academic Foundation, College Configuration & Prerequisite Engine Tests', () => {
  let adminUser: InstanceType<typeof User>;
  let facultyUser: InstanceType<typeof User>;
  let facultyDoc: InstanceType<typeof Faculty>;
  let college: InstanceType<typeof College>;
  let dept: InstanceType<typeof Department>;
  let adminHeader: { Authorization: string };

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
    await Student.init();
    await Faculty.init();
    await FacultyAssignment.init();
    await StudentEnrollment.init();
    await InstitutionConfiguration.init();
    await Note.init();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();

    college = await College.create({
      name: 'P34 Engineering College',
      code: 'P34EC',
      address: '100 Innovation Park, Tech City',
      email: 'admin@p34.edu',
      phone: '+919876543210',
      principal: 'Dr. Katherine Johnson',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });

    const defaultPasswordHash = await PasswordService.hashPassword('AdminPass123');

    adminUser = await User.create({
      instituteId: 'ADMIN-P34-01',
      collegeId: college._id,
      name: 'College Admin',
      email: 'admin@p34.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.COLLEGE_ADMIN,
      accountStatus: AccountStatus.ACTIVE,
      isActive: true,
    });

    dept = await Department.create({
      collegeId: college._id,
      name: 'Computer Science',
      code: 'CSE',
      status: DepartmentStatus.ACTIVE,
      isActive: true,
    });

    facultyUser = await User.create({
      instituteId: 'FAC-P34-01',
      collegeId: college._id,
      departmentId: dept._id,
      name: 'Dr. Alan Turing',
      email: 'alan@p34.edu',
      passwordHash: defaultPasswordHash,
      role: AppRole.FACULTY,
      accountStatus: AccountStatus.ACTIVE,
      isActive: true,
    });

    facultyDoc = await Faculty.create({
      collegeId: college._id,
      departmentId: dept._id,
      userId: facultyUser._id,
      name: facultyUser.name,
      email: facultyUser.email,
      isActive: true,
      status: 'active',
      subjectIds: [],
      sectionIds: [],
    });

    adminHeader = createTestAuthHeader({
      userId: adminUser.id,
      role: AppRole.COLLEGE_ADMIN,
      collegeId: college.id,
    });
  });

  describe('1. Academic Year Operational Cycle vs Cohort Validation', () => {
    it('rejects multi-year cohort string (e.g. 2024-2028) for Academic Year creation', async () => {
      const res = await request(app)
        .post('/api/v1/academics/academic-years')
        .set(adminHeader)
        .send({
          collegeId: college.id,
          name: '2024-2028',
          startDate: '2024-08-01T00:00:00.000Z',
          endDate: '2025-06-30T23:59:59.000Z',
        });

      expect(res.status).toBe(400);
      expect(res.body.error.message).toContain('represents a multi-year student cohort/batch intake');
    });

    it('rejects multi-year cohort short notation (e.g. 2024-27) for Academic Year creation', async () => {
      const res = await request(app)
        .post('/api/v1/academics/academic-years')
        .set(adminHeader)
        .send({
          collegeId: college.id,
          name: '2024-27',
          startDate: '2024-08-01T00:00:00.000Z',
          endDate: '2025-06-30T23:59:59.000Z',
        });

      expect(res.status).toBe(400);
      expect(res.body.error.message).toContain('represents a multi-year student cohort/batch intake');
    });

    it('rejects date duration longer than 15 months (cohort duration)', async () => {
      const res = await request(app)
        .post('/api/v1/academics/academic-years')
        .set(adminHeader)
        .send({
          collegeId: college.id,
          name: '2026-27',
          startDate: '2024-01-01T00:00:00.000Z',
          endDate: '2027-12-31T23:59:59.000Z',
        });

      expect(res.status).toBe(400);
      expect(res.body.error.message).toContain('exceeds the maximum allowed 15 months');
    });

    it('accepts valid operational cycle (e.g. 2026-27) and enforces single isCurrent', async () => {
      const res1 = await request(app)
        .post('/api/v1/academics/academic-years')
        .set(adminHeader)
        .send({
          collegeId: college.id,
          name: '2025-26',
          startDate: '2025-07-01T00:00:00.000Z',
          endDate: '2026-06-30T23:59:59.000Z',
          isCurrent: true,
        });

      expect(res1.status).toBe(201);
      expect(res1.body.data.isCurrent).toBe(true);

      const res2 = await request(app)
        .post('/api/v1/academics/academic-years')
        .set(adminHeader)
        .send({
          collegeId: college.id,
          name: '2026-27',
          startDate: '2026-07-01T00:00:00.000Z',
          endDate: '2027-06-30T23:59:59.000Z',
          isCurrent: true,
        });

      expect(res2.status).toBe(201);
      expect(res2.body.data.isCurrent).toBe(true);

      // Verify previous year was atomically unset
      const oldYear = await AcademicYear.findById(res1.body.data.id);
      expect(oldYear?.isCurrent).toBe(false);
    });
  });

  describe('2. Section Optionality when Disabled in Institution Configuration', () => {
    it('allows student enrollment and faculty assignment without sections when section=false', async () => {
      // 1. Configure institution with academicStructure.section = false
      await InstitutionConfiguration.create({
        collegeId: college._id,
        institutionType: 'POLYTECHNIC',
        academicStructure: {
          program: true,
          academicYear: true,
          semester: true,
          section: false,
          subject: true,
          building: false,
          room: false,
        },
        terminology: {
          semester: { singular: 'Term', plural: 'Terms' },
          program: { singular: 'Diploma', plural: 'Diplomas' },
        },
        isConfigured: true,
      });

      // 2. Setup Academic foundation: Academic Year, Course, Semester, Subject
      const ay = await AcademicYear.create({
        collegeId: college._id,
        name: '2026-27',
        startDate: new Date('2026-07-01'),
        endDate: new Date('2027-06-30'),
        isCurrent: true,
        isActive: true,
      });

      const course = await Course.create({
        collegeId: college._id,
        departmentId: dept._id,
        name: 'Diploma in Computer Engineering',
        code: 'DCE',
        duration: 3,
        isActive: true,
      });

      const sem = await Semester.create({
        collegeId: college._id,
        departmentId: dept._id,
        courseId: course._id,
        academicYearId: ay._id,
        name: 'Term 1',
        number: 1,
        startDate: new Date('2026-07-01'),
        endDate: new Date('2026-12-31'),
        isActive: true,
      });

      const subject = await Subject.create({
        collegeId: college._id,
        departmentId: dept._id,
        courseId: course._id,
        semesterId: sem._id,
        name: 'Operating Systems',
        code: 'CS201',
        type: 'THEORY',
        credits: 4,
        isActive: true,
      });

      // Create student profile
      const defaultPasswordHash = await PasswordService.hashPassword('StudentPass123');
      const studentUser = await User.create({
        instituteId: 'STU-P34-01',
        collegeId: college._id,
        departmentId: dept._id,
        name: 'Ada Lovelace',
        email: 'ada@p34.edu',
        passwordHash: defaultPasswordHash,
        role: AppRole.STUDENT,
        accountStatus: AccountStatus.ACTIVE,
        isActive: true,
      });

      const studentDoc = await Student.create({
        collegeId: college._id,
        departmentId: dept._id,
        userId: studentUser._id,
        instituteId: studentUser.instituteId,
        name: studentUser.name,
        lifecycleState: 'active',
        isActive: true,
        status: 'active',
      });

      // 3. Enroll student without sectionId
      const enrollRes = await request(app)
        .post('/api/v1/academics/enrollments')
        .set(adminHeader)
        .send({
          collegeId: college.id,
          studentId: studentDoc.id,
          courseId: course.id,
          semesterId: sem.id,
          academicYearId: ay.id,
        });

      expect(enrollRes.status).toBe(201);
      expect(enrollRes.body.data.studentId).toBe(studentDoc.id);
      expect(enrollRes.body.data.sectionId).toBeFalsy();
      expect(enrollRes.body.data.academicStage).toBe('1st Year');
      expect(enrollRes.body.data.cohort).toBe('2026–29');

      // 4. Assign faculty without sectionId
      const facAssignmentRes = await request(app)
        .post('/api/v1/academics/faculty-assignments')
        .set(adminHeader)
        .send({
          collegeId: college.id,
          facultyId: facultyUser.id,
          subjectId: subject.id,
          courseId: course.id,
          semesterId: sem.id,
          academicYearId: ay.id,
        });

      expect(facAssignmentRes.status).toBe(201);
      expect(facAssignmentRes.body.data.facultyId).toBe(facultyDoc.id);
      expect(facAssignmentRes.body.data.subjectId).toBe(subject.id);
      expect(facAssignmentRes.body.data.sectionId).toBeFalsy();
      expect(facAssignmentRes.body.data.academicStage).toBe('1st Year');
      expect(facAssignmentRes.body.data.cohort).toBe('2026–29');
    });
  });

  describe('3. Teaching Authorization Security Hardening & Canonical Identity', () => {
    let facultyAUser: InstanceType<typeof User>;
    let facultyADoc: InstanceType<typeof Faculty>;
    let facultyBUser: InstanceType<typeof User>;
    let facultyBDoc: InstanceType<typeof Faculty>;
    let subjectDbms: InstanceType<typeof Subject>;
    let subjectMath: InstanceType<typeof Subject>;
    let deptA: InstanceType<typeof Department>;
    let deptB: InstanceType<typeof Department>;
    let hodUserB: InstanceType<typeof User>;

    beforeEach(async () => {
      deptA = dept;
      deptB = await Department.create({
        collegeId: college._id,
        name: 'Electrical Engineering',
        code: 'EE',
        status: DepartmentStatus.ACTIVE,
        isActive: true,
      });

      const pwdHash = await PasswordService.hashPassword('Pass12345');

      // Faculty A and Faculty B both have identical name: "Dr. Alan Turing"
      facultyAUser = await User.create({
        instituteId: 'FAC-A-01',
        collegeId: college._id,
        departmentId: deptA._id,
        name: 'Dr. Alan Turing',
        email: 'alan.a@p34.edu',
        passwordHash: pwdHash,
        role: AppRole.FACULTY,
        accountStatus: AccountStatus.ACTIVE,
        isActive: true,
      });

      facultyADoc = await Faculty.create({
        collegeId: college._id,
        departmentId: deptA._id,
        userId: facultyAUser._id,
        name: facultyAUser.name,
        email: facultyAUser.email,
        isActive: true,
        status: 'active',
      });

      facultyBUser = await User.create({
        instituteId: 'FAC-B-01',
        collegeId: college._id,
        departmentId: deptA._id,
        name: 'Dr. Alan Turing', // Identical name!
        email: 'alan.b@p34.edu',
        passwordHash: pwdHash,
        role: AppRole.FACULTY,
        accountStatus: AccountStatus.ACTIVE,
        isActive: true,
      });

      facultyBDoc = await Faculty.create({
        collegeId: college._id,
        departmentId: deptA._id,
        userId: facultyBUser._id,
        name: facultyBUser.name,
        email: facultyBUser.email,
        isActive: true,
        status: 'active',
      });

      const courseA = await Course.create({
        collegeId: college._id,
        departmentId: deptA._id,
        name: 'B.Tech CSE',
        code: 'CSE-BT',
        duration: 4,
        isActive: true,
      });

      const ay = await AcademicYear.create({
        collegeId: college._id,
        name: '2026-27',
        startDate: new Date('2026-07-01'),
        endDate: new Date('2027-06-30'),
        isCurrent: true,
        isActive: true,
      });

      const semA = await Semester.create({
        collegeId: college._id,
        departmentId: deptA._id,
        courseId: courseA._id,
        academicYearId: ay._id,
        name: 'Semester 3',
        number: 3,
        startDate: new Date('2026-07-01'),
        endDate: new Date('2026-12-31'),
        isActive: true,
      });

      subjectDbms = await Subject.create({
        collegeId: college._id,
        departmentId: deptA._id,
        courseId: courseA._id,
        semesterId: semA._id,
        name: 'Database Management Systems',
        code: 'CS301',
        type: 'THEORY',
        credits: 4,
        isActive: true,
      });

      subjectMath = await Subject.create({
        collegeId: college._id,
        departmentId: deptA._id,
        courseId: courseA._id,
        semesterId: semA._id,
        name: 'Discrete Mathematics',
        code: 'CS302',
        type: 'THEORY',
        credits: 4,
        isActive: true,
      });

      // Faculty A teaches DBMS
      await FacultyAssignment.create({
        collegeId: college._id,
        departmentId: deptA._id,
        courseId: courseA._id,
        semesterId: semA._id,
        academicYearId: ay._id,
        subjectId: subjectDbms._id,
        facultyId: facultyADoc._id,
        facultyName: facultyADoc.name,
        isActive: true,
      });

      // Faculty B teaches Mathematics
      await FacultyAssignment.create({
        collegeId: college._id,
        departmentId: deptA._id,
        courseId: courseA._id,
        semesterId: semA._id,
        academicYearId: ay._id,
        subjectId: subjectMath._id,
        facultyId: facultyBDoc._id,
        facultyName: facultyBDoc.name,
        isActive: true,
      });

      // HOD in Dept B
      hodUserB = await User.create({
        instituteId: 'HOD-EE-01',
        collegeId: college._id,
        departmentId: deptB._id,
        name: 'Dr. Nikola Tesla',
        email: 'tesla@p34.edu',
        passwordHash: pwdHash,
        role: AppRole.HOD,
        accountStatus: AccountStatus.ACTIVE,
        isActive: true,
      });
    });

    it('TEST A — Name Matching Rejection: Faculty B cannot authorize access to Faculty A assignment despite identical name', async () => {
      const faDbms = await FacultyAssignment.findOne({ subjectId: subjectDbms._id });
      expect(faDbms).toBeTruthy();

      // Faculty B attempts isFacultyOwner check on Faculty A's assignment
      const isOwnerB = await TeachingAuthorizationService.isFacultyOwner(
        college.id,
        {
          id: facultyBUser.id,
          role: AppRole.FACULTY,
          name: 'Dr. Alan Turing', // Matches faDbms.facultyName
          email: facultyBUser.email,
        },
        faDbms!
      );

      // Must fail closed based on canonical identity!
      expect(isOwnerB).toBe(false);

      // Faculty A correctly owns it
      const isOwnerA = await TeachingAuthorizationService.isFacultyOwner(
        college.id,
        {
          id: facultyAUser.id,
          role: AppRole.FACULTY,
          name: 'Dr. Alan Turing',
          email: facultyAUser.email,
        },
        faDbms!
      );
      expect(isOwnerA).toBe(true);
    });

    it('TEST B & C — Notes Teaching Context Authorization: Faculty A cannot upload notes for Mathematics', async () => {
      const facultyAHeader = createTestAuthHeader({
        userId: facultyAUser.id,
        role: AppRole.FACULTY,
        collegeId: college.id,
      });

      // Faculty A attempts to upload notes for Mathematics (taught by Faculty B)
      const res = await request(app)
        .post('/api/v1/notes/upload-url')
        .set(facultyAHeader)
        .send({
          subjectId: subjectMath.id,
          title: 'Mathematics Unit 1',
          fileName: 'discrete_math.pdf',
          mimeType: 'application/pdf',
          fileSize: 2048,
        });

      expect(res.status).toBe(403);
      expect(res.body.error.message).toContain('This subject is not assigned to you');

      // Faculty A can upload for DBMS (which they teach)
      const resAllowed = await request(app)
        .post('/api/v1/notes/upload-url')
        .set(facultyAHeader)
        .send({
          subjectId: subjectDbms.id,
          title: 'DBMS Unit 1',
          fileName: 'dbms_intro.pdf',
          mimeType: 'application/pdf',
          fileSize: 2048,
        });

      expect([200, 201]).toContain(resAllowed.status);
      expect(resAllowed.body.data.note).toBeTruthy();
    });

    it('TEST D — Cross Department Scope: HOD of Dept B cannot manage notes for Dept A', async () => {
      const hodBHeader = createTestAuthHeader({
        userId: hodUserB.id,
        role: AppRole.HOD,
        collegeId: college.id,
      });

      const res = await request(app)
        .post('/api/v1/notes/upload-url')
        .set(hodBHeader)
        .send({
          subjectId: subjectDbms.id, // In Dept A
          title: 'HOD Test',
          fileName: 'hod_test.pdf',
          mimeType: 'application/pdf',
          fileSize: 2048,
        });

      expect(res.status).toBe(403);
      expect(res.body.error.message).toContain('within their assigned department');
    });

    it('TEST E — Cross Tenant Isolation: User from College 2 cannot access College 1 notes', async () => {
      const college2 = await College.create({
        name: 'Another College',
        code: 'COL2',
        address: '200 Science Way, City 2',
        email: 'contact@col2.edu',
        phone: '+919876543211',
        principal: 'Dr. John Doe',
        status: CollegeStatus.ACTIVE,
        isActive: true,
      });

      const pwdHash = await PasswordService.hashPassword('Pass12345');
      const userCol2 = await User.create({
        instituteId: 'COL2-FAC-01',
        collegeId: college2._id,
        name: 'External Faculty',
        email: 'ext@col2.edu',
        passwordHash: pwdHash,
        role: AppRole.FACULTY,
        accountStatus: AccountStatus.ACTIVE,
        isActive: true,
      });

      const col2Header = createTestAuthHeader({
        userId: userCol2.id,
        role: AppRole.FACULTY,
        collegeId: college2.id,
      });

      const res = await request(app)
        .post('/api/v1/notes/upload-url')
        .set(col2Header)
        .send({
          subjectId: subjectDbms.id, // College 1
          title: 'Cross Tenant Exploit',
          fileName: 'exploit.pdf',
          mimeType: 'application/pdf',
          fileSize: 2048,
        });

      expect(res.status).toBe(403);
    });
  });

  describe('4. Section Optionality Configuration A vs B', () => {
    it('Configuration A: Section enabled allows FacultyAssignment with sectionId', async () => {
      const course = await Course.create({
        collegeId: college._id,
        departmentId: dept._id,
        name: 'B.Tech IT',
        code: 'IT-BT',
        duration: 4,
        isActive: true,
      });

      const ay = await AcademicYear.create({
        collegeId: college._id,
        name: '2026-27',
        startDate: new Date('2026-07-01'),
        endDate: new Date('2027-06-30'),
        isActive: true,
      });

      const sem = await Semester.create({
        collegeId: college._id,
        departmentId: dept._id,
        courseId: course._id,
        academicYearId: ay._id,
        name: 'Semester 1',
        number: 1,
        startDate: new Date('2026-07-01'),
        endDate: new Date('2026-12-31'),
        isActive: true,
      });

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

      const sub = await Subject.create({
        collegeId: college._id,
        departmentId: dept._id,
        courseId: course._id,
        semesterId: sem._id,
        name: 'C Programming',
        code: 'IT101',
        type: 'THEORY',
        credits: 3,
        isActive: true,
      });

      const res = await request(app)
        .post('/api/v1/academics/faculty-assignments')
        .set(adminHeader)
        .send({
          collegeId: college.id,
          facultyId: facultyUser.id,
          subjectId: sub.id,
          courseId: course.id,
          semesterId: sem.id,
          academicYearId: ay.id,
          sectionId: sec.id,
        });

      expect(res.status).toBe(201);
      expect(res.body.data.sectionId).toBe(sec.id);
    });
  });
});
