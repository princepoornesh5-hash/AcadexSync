import request from 'supertest';
import { app } from '../../src/app';
import { College } from '../../src/models/college.model';
import { Department } from '../../src/models/department.model';
import { Course } from '../../src/models/course.model';
import { AcademicYear } from '../../src/models/academicYear.model';
import { Semester } from '../../src/models/semester.model';
import { Section } from '../../src/models/section.model';
import { User } from '../../src/models/user.model';
import { Announcement } from '../../src/models/announcement.model';
import { AppRole } from '../../src/constants/roles';
import { AcademicYearStatus, SemesterStatus, SectionStatus, AccountStatus } from '../../src/constants/status';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';

describe('Prompt 24: Core Workflow Consolidation & Pilot Readiness', () => {
  let collegeA: any;
  let collegeB: any;
  let deptA: any;
  let courseA: any;
  let courseCombined: any;
  let currentAY: any;

  let adminAHeader: { Authorization: string };
  let adminBHeader: { Authorization: string };
  let hodAHeader: { Authorization: string };
  let facultyAHeader: { Authorization: string };

  beforeAll(async () => {
    await setupTestDB();
    await College.init();
    await Department.init();
    await Course.init();
    await AcademicYear.init();
    await Semester.init();
    await Section.init();
    await User.init();
    await Announcement.init();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();

    // 1. College A setup
    collegeA = await College.create({
      name: 'Alpha Engineering Institute',
      code: 'AEI',
      address: 'North Campus',
      email: 'admin@alpha.edu',
      phone: '9876543210',
      principal: 'Dr. Alpha Principal',
    });

    // College B setup (for cross-tenant tests)
    collegeB = await College.create({
      name: 'Beta Technology College',
      code: 'BTC',
      address: 'South Campus',
      email: 'admin@beta.edu',
      phone: '9123456780',
      principal: 'Dr. Beta Principal',
    });

    deptA = await Department.create({
      collegeId: collegeA._id,
      name: 'Computer Engineering',
      code: 'CSE',
    });

    await Department.create({
      collegeId: collegeB._id,
      name: 'Mechanical Engineering',
      code: 'MECH',
    });

    // 2. Academic Years: One current, one historical
    currentAY = await AcademicYear.create({
      collegeId: collegeA._id,
      name: '2026–27',
      startDate: new Date('2026-06-01'),
      endDate: new Date('2027-05-31'),
      status: AcademicYearStatus.ACTIVE,
      isCurrent: true,
      isActive: true,
    });

    await AcademicYear.create({
      collegeId: collegeA._id,
      name: '2025–26',
      startDate: new Date('2025-06-01'),
      endDate: new Date('2026-05-31'),
      status: AcademicYearStatus.COMPLETED,
      isCurrent: false,
      isActive: true,
    });

    // 3. Courses:
    // Course A: Standard 3-year Diploma in Computer Engineering (YEAR_SEMESTER)
    courseA = await Course.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'Diploma in Computer Engineering',
      code: 'DCSE',
      duration: 3,
      progressionType: 'YEAR_SEMESTER',
      isActive: true,
    });

    // Course Combined: 3-year Diploma with COMBINED_FIRST_YEAR
    courseCombined = await Course.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'Diploma in Civil Engineering',
      code: 'DCIV',
      duration: 3,
      progressionType: 'COMBINED_FIRST_YEAR',
      isActive: true,
    });

    // 4. Semesters & Sections for Course A (Sem 1 to 6)
    for (let semNum = 1; semNum <= 6; semNum++) {
      const sem = await Semester.create({
        collegeId: collegeA._id,
        departmentId: deptA._id,
        courseId: courseA._id,
        academicYearId: currentAY._id,
        name: `Semester ${semNum}`,
        number: semNum,
        isCurrent: semNum === 5 || semNum === 3 || semNum === 1,
        status: SemesterStatus.ACTIVE,
        isActive: true,
      });

      await Section.create({
        collegeId: collegeA._id,
        departmentId: deptA._id,
        courseId: courseA._id,
        academicYearId: currentAY._id,
        semesterId: sem._id,
        name: 'A',
        capacity: 60,
        status: SectionStatus.ACTIVE,
        isActive: true,
      });
    }

    // Combined first year semester for Course Combined
    const combinedSem1 = await Semester.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseCombined._id,
      academicYearId: currentAY._id,
      name: 'Combined First Year',
      number: 1,
      isCurrent: true,
      status: SemesterStatus.ACTIVE,
      isActive: true,
    });
    await Section.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseCombined._id,
      academicYearId: currentAY._id,
      semesterId: combinedSem1._id,
      name: 'A',
      capacity: 60,
      status: SectionStatus.ACTIVE,
      isActive: true,
    });

    // 5. Create real users in MongoDB
    const adminAUser = await User.create({
      collegeId: collegeA._id,
      name: 'Admin Alpha',
      email: 'admin@alpha.edu',
      instituteId: 'INST-ADMIN-A',
      passwordHash: 'hash123',
      role: AppRole.COLLEGE_ADMIN,
      accountStatus: AccountStatus.ACTIVE,
    });

    const adminBUser = await User.create({
      collegeId: collegeB._id,
      name: 'Admin Beta',
      email: 'admin@beta.edu',
      instituteId: 'INST-ADMIN-B',
      passwordHash: 'hash123',
      role: AppRole.COLLEGE_ADMIN,
      accountStatus: AccountStatus.ACTIVE,
    });

    const hodAUser = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'HOD Alpha CSE',
      email: 'hod.cse@alpha.edu',
      instituteId: 'INST-HOD-A',
      passwordHash: 'hash123',
      role: AppRole.HOD,
      accountStatus: AccountStatus.ACTIVE,
    });

    const facultyAUser = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'Faculty Alpha',
      email: 'faculty@alpha.edu',
      instituteId: 'INST-FAC-A',
      passwordHash: 'hash123',
      role: AppRole.FACULTY,
      accountStatus: AccountStatus.ACTIVE,
    });

    // 6. Auth headers with valid user IDs
    adminAHeader = createTestAuthHeader({
      role: AppRole.COLLEGE_ADMIN,
      collegeId: collegeA._id.toString(),
      userId: adminAUser.id,
    });

    adminBHeader = createTestAuthHeader({
      role: AppRole.COLLEGE_ADMIN,
      collegeId: collegeB._id.toString(),
      userId: adminBUser.id,
    });

    hodAHeader = createTestAuthHeader({
      role: AppRole.HOD,
      collegeId: collegeA._id.toString(),
      departmentId: deptA._id.toString(),
      userId: hodAUser.id,
    });

    facultyAHeader = createTestAuthHeader({
      role: AppRole.FACULTY,
      collegeId: collegeA._id.toString(),
      departmentId: deptA._id.toString(),
      userId: facultyAUser.id,
    });
  });

  describe('1. Authoritative Current Academic Context Architecture', () => {
    it('resolves the authoritative current Academic Year and active cohorts coexisting', async () => {
      const res = await request(app)
        .get('/api/v1/academics/current-context')
        .set(adminAHeader);

      expect(res.status).toBe(200);
      expect(res.body.success).toBe(true);
      const data = res.body.data;

      // Authoritative academic year
      expect(data.academicYear).toBeDefined();
      expect(data.academicYear.name).toBe('2026–27');
      expect(data.isCurrentAuthoritative).toBe(true);

      // Verify active cohorts for Course A (3-year duration)
      // Current year 2026:
      // Stage 1 (1st Year) -> Cohort 2026–29
      // Stage 2 (2nd Year) -> Cohort 2025–28
      // Stage 3 (3rd Year) -> Cohort 2024–27
      const courseACohorts = data.activeCohorts.filter(
        (c: any) => c.courseCode === 'DCSE'
      );
      expect(courseACohorts.length).toBe(3);

      const stage3 = courseACohorts.find((c: any) => c.stageNumber === 3);
      expect(stage3).toBeDefined();
      expect(stage3.academicStage).toBe('3rd Year');
      expect(stage3.cohort).toBe('2024–27');
      // In 3rd Year, semesters are 5 and 6
      expect(stage3.periods.map((p: any) => p.name)).toEqual(
        expect.arrayContaining(['Semester 5', 'Semester 6'])
      );

      const stage2 = courseACohorts.find((c: any) => c.stageNumber === 2);
      expect(stage2).toBeDefined();
      expect(stage2.academicStage).toBe('2nd Year');
      expect(stage2.cohort).toBe('2025–28');

      const stage1 = courseACohorts.find((c: any) => c.stageNumber === 1);
      expect(stage1).toBeDefined();
      expect(stage1.academicStage).toBe('1st Year');
      expect(stage1.cohort).toBe('2026–29');
    });

    it('separates Academic Stage from Academic Period cleanly', async () => {
      const res = await request(app)
        .get('/api/v1/academics/current-context')
        .set(hodAHeader);

      expect(res.status).toBe(200);
      const data = res.body.data;
      const stage3 = data.activeCohorts.find(
        (c: any) => c.courseCode === 'DCSE' && c.stageNumber === 3
      );

      expect(stage3.academicStage).toBe('3rd Year');
      expect(stage3.periods.length).toBeGreaterThan(0);
      expect(stage3.periods[0].name).toMatch(/Semester/);
      expect(stage3.academicStage).not.toEqual(stage3.periods[0].name);
    });

    it('supports flexible program progression (COMBINED_FIRST_YEAR vs YEAR_SEMESTER)', async () => {
      const res = await request(app)
        .get('/api/v1/academics/current-context')
        .set(adminAHeader);

      expect(res.status).toBe(200);
      const data = res.body.data;

      // Find the combined first year course
      const combinedCohorts = data.activeCohorts.filter(
        (c: any) => c.courseCode === 'DCIV'
      );
      expect(combinedCohorts.length).toBe(3);

      const stage1 = combinedCohorts.find((c: any) => c.stageNumber === 1);
      expect(stage1.progressionType).toBe('COMBINED_FIRST_YEAR');
      expect(stage1.periods[0].name).toBe('Combined First Year');
    });

    it('auto-scopes HOD to their own department without redundant params', async () => {
      const res = await request(app)
        .get('/api/v1/academics/current-context')
        .set(hodAHeader);

      expect(res.status).toBe(200);
      expect(res.body.data.departmentScope).toBe(deptA._id.toString());
    });
  });

  describe('2. Historical Context & Separation', () => {
    it('excludes historical academic years from default current view but serves them via history endpoint', async () => {
      // 1. Current context only contains current academic year
      const currentRes = await request(app)
        .get('/api/v1/academics/current-context')
        .set(adminAHeader);

      expect(currentRes.status).toBe(200);
      expect(currentRes.body.data.academicYear.name).toBe('2026–27');
      expect(currentRes.body.data.academicYear.isCurrent).toBe(true);

      // 2. History endpoint retrieves past academic years
      const historyRes = await request(app)
        .get('/api/v1/academics/context/history')
        .set(adminAHeader);

      expect(historyRes.status).toBe(200);
      expect(historyRes.body.success).toBe(true);
      expect(Array.isArray(historyRes.body.data)).toBe(true);
      expect(historyRes.body.data.length).toBe(1);
      expect(historyRes.body.data[0].name).toBe('2025–26');
      expect(historyRes.body.data[0].isCurrent).toBe(false);
    });
  });

  describe('3. Cross-Tenant and Role Boundary Enforcement', () => {
    it('strictly isolates academic context between different colleges', async () => {
      // College B has no academic year setup yet
      const resB = await request(app)
        .get('/api/v1/academics/current-context')
        .set(adminBHeader);

      expect(resB.status).toBe(200);
      expect(resB.body.data.academicYear).toBeNull();
      expect(resB.body.data.activeCohorts.length).toBe(0);
      expect(resB.body.data.collegeId).toBe(collegeB._id.toString());
    });
  });

  describe('4. Announcement Resilience & Discoverability Fixes', () => {
    it('accepts both uppercase and lowercase enum values via Zod preprocessing', async () => {
      const res = await request(app)
        .post('/api/v1/announcements')
        .set(adminAHeader)
        .send({
          title: 'Campus Orientation 2026',
          body: 'Welcome to the new academic year 2026-27.',
          audienceScope: 'COLLEGE',
          category: 'ACADEMIC', // Uppercase from frontend form
          priority: 'HIGH', // Uppercase from frontend form
          status: 'PUBLISHED',
        });

      expect(res.status).toBe(201);
      expect(res.body.success).toBe(true);
      expect(res.body.data.category).toBe('academic');
      expect(res.body.data.priority).toBe('high');
    });

    it('enforces backend authority: Faculty cannot publish institution-level announcement', async () => {
      const res = await request(app)
        .post('/api/v1/announcements')
        .set(facultyAHeader)
        .send({
          title: 'Unauthorized Announcement',
          body: 'Testing faculty announcement boundaries.',
          audienceScope: 'COLLEGE',
          category: 'general',
          priority: 'normal',
        });

      // Backend permission restricts announcement creation to Super Admin, College Admin, and HOD
      expect(res.status).toBe(403);
    });
  });
});
