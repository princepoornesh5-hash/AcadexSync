import mongoose from 'mongoose';
import { AcademicService } from '../../src/services/academic.service';
import { College } from '../../src/models/college.model';
import { Department } from '../../src/models/department.model';
import { Course } from '../../src/models/course.model';
import { User } from '../../src/models/user.model';
import { Student } from '../../src/models/student.model';
import { StudentEnrollment } from '../../src/models/studentEnrollment.model';
import { AppRole } from '../../src/constants/roles';
import { AccountStatus, CollegeStatus, DepartmentStatus, StudentLifecycleState } from '../../src/constants/status';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { AuthenticatedUser } from '../../src/types/auth.types';

describe('Course Management Module Integration Tests (Prompt 11)', () => {
  let collegeA: any;
  let collegeB: any;
  let deptA1: any;
  let deptA2: any;
  let deptB1: any;

  let collegeAdminA: AuthenticatedUser;
  let hodA1: AuthenticatedUser;
  let facultyA1: AuthenticatedUser;
  let studentA: AuthenticatedUser;

  beforeAll(async () => {
    await setupTestDB();
    await College.init();
    await Department.init();
    await Course.init();
    await User.init();
    await Student.init();
    await StudentEnrollment.init();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();

    collegeA = await College.create({
      name: 'College Alpha',
      code: 'COL-A',
      address: 'North Campus',
      email: 'admin@col-a.edu',
      phone: '1111111111',
      principal: 'Dr. Alpha',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });

    collegeB = await College.create({
      name: 'College Beta',
      code: 'COL-B',
      address: 'South Campus',
      email: 'admin@col-b.edu',
      phone: '2222222222',
      principal: 'Dr. Beta',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });

    deptA1 = await Department.create({
      collegeId: collegeA._id,
      name: 'Computer Science',
      code: 'CS',
      status: DepartmentStatus.ACTIVE,
      isActive: true,
    });

    deptA2 = await Department.create({
      collegeId: collegeA._id,
      name: 'Mechanical Engineering',
      code: 'ME',
      status: DepartmentStatus.ACTIVE,
      isActive: true,
    });

    deptB1 = await Department.create({
      collegeId: collegeB._id,
      name: 'Information Technology',
      code: 'IT',
      status: DepartmentStatus.ACTIVE,
      isActive: true,
    });

    collegeAdminA = {
      id: new mongoose.Types.ObjectId().toString(),
      instituteId: 'ADMIN-A',
      role: AppRole.COLLEGE_ADMIN,
      collegeId: collegeA.id,
      name: 'Admin Alpha',
      accountStatus: AccountStatus.ACTIVE,
    };

    hodA1 = {
      id: new mongoose.Types.ObjectId().toString(),
      instituteId: 'HOD-CS',
      role: AppRole.HOD,
      collegeId: collegeA.id,
      departmentId: deptA1.id,
      name: 'Dr. HOD CS',
      accountStatus: AccountStatus.ACTIVE,
    };

    facultyA1 = {
      id: new mongoose.Types.ObjectId().toString(),
      instituteId: 'FAC-01',
      role: AppRole.FACULTY,
      collegeId: collegeA.id,
      departmentId: deptA1.id,
      name: 'Prof. Ada',
      accountStatus: AccountStatus.ACTIVE,
    };

    studentA = {
      id: new mongoose.Types.ObjectId().toString(),
      instituteId: 'STU-A-01',
      role: AppRole.STUDENT,
      collegeId: collegeA.id,
      departmentId: deptA1.id,
      name: 'Student Alpha',
      accountStatus: AccountStatus.ACTIVE,
    };
  });

  // =========================================================================
  // 1. COURSE CREATION & AUTHORIZATION
  // =========================================================================

  it('1. College Admin can create a course within their own college', async () => {
    const course = await AcademicService.createCourse(
      collegeA.id,
      {
        departmentId: deptA1.id,
        name: 'Bachelor of Technology in CS',
        code: 'BTECH-CS',
        duration: 4,
      },
      collegeAdminA
    );

    expect(course.id).toBeDefined();
    expect(course.name).toBe('Bachelor of Technology in CS');
    expect(course.code).toBe('BTECH-CS');
    expect(course.duration).toBe(4);
    expect(course.isActive).toBe(true);
    expect(course.collegeId.toString()).toBe(collegeA.id);
    expect(course.departmentId.toString()).toBe(deptA1.id);
  });

  it('2. HOD can create a course within their assigned department', async () => {
    const course = await AcademicService.createCourse(
      collegeA.id,
      {
        departmentId: deptA1.id,
        name: 'Diploma in Computer Science',
        code: 'DIP-CS',
        duration: 3,
      },
      hodA1
    );

    expect(course.id).toBeDefined();
    expect(course.name).toBe('Diploma in Computer Science');
    expect(course.code).toBe('DIP-CS');
  });

  it('3. HOD cannot create a course for another department (403 Forbidden)', async () => {
    await expect(
      AcademicService.createCourse(
        collegeA.id,
        {
          departmentId: deptA2.id, // ME department, not CS
          name: 'Diploma in Mechanical',
          code: 'DIP-ME',
          duration: 3,
        },
        hodA1
      )
    ).rejects.toThrow('HOD can only create courses within their assigned department');
  });

  it('4. College Admin cannot create a course for another college (403 Forbidden)', async () => {
    await expect(
      AcademicService.createCourse(
        collegeB.id, // Cross-college target
        {
          departmentId: deptB1.id,
          name: 'BTech in IT',
          code: 'BTECH-IT',
          duration: 4,
        },
        collegeAdminA
      )
    ).rejects.toThrow('Cross-college course creation is strictly prohibited');
  });

  it('5. Unauthorized Faculty mutation is rejected (403 Forbidden)', async () => {
    await expect(
      AcademicService.createCourse(
        collegeA.id,
        {
          departmentId: deptA1.id,
          name: 'Unauthorized Course',
          code: 'UNAUTH-01',
          duration: 3,
        },
        facultyA1
      )
    ).rejects.toThrow('Only administrators and HODs have permission to create courses');
  });

  it('6. Unauthorized Student mutation is rejected (403 Forbidden)', async () => {
    await expect(
      AcademicService.createCourse(
        collegeA.id,
        {
          departmentId: deptA1.id,
          name: 'Student Course',
          code: 'STU-01',
          duration: 3,
        },
        studentA
      )
    ).rejects.toThrow('Only administrators and HODs have permission to create courses');
  });

  // =========================================================================
  // 2. DUPLICATE CODE & TENANT ISOLATION
  // =========================================================================

  it('7. Duplicate course code within same college is rejected (409 Conflict)', async () => {
    await AcademicService.createCourse(
      collegeA.id,
      {
        departmentId: deptA1.id,
        name: 'BTech Computer Science',
        code: 'BTECH-CS',
        duration: 4,
      },
      collegeAdminA
    );

    // Attempt second creation with same code in same college
    await expect(
      AcademicService.createCourse(
        collegeA.id,
        {
          departmentId: deptA2.id,
          name: 'Another BTech',
          code: 'btech-cs', // Case-insensitive normalized
          duration: 4,
        },
        collegeAdminA
      )
    ).rejects.toThrow('Course with code "BTECH-CS" already exists in this college');
  });

  it('8. Different colleges can have courses with the same code (tenant isolation)', async () => {
    const courseA = await AcademicService.createCourse(
      collegeA.id,
      {
        departmentId: deptA1.id,
        name: 'BTech CS College A',
        code: 'BTECH-CS',
        duration: 4,
      },
      collegeAdminA
    );

    const collegeAdminB: AuthenticatedUser = {
      id: new mongoose.Types.ObjectId().toString(),
      instituteId: 'ADMIN-B',
      role: AppRole.COLLEGE_ADMIN,
      collegeId: collegeB.id,
      name: 'Admin Beta',
      accountStatus: AccountStatus.ACTIVE,
    };

    const courseB = await AcademicService.createCourse(
      collegeB.id,
      {
        departmentId: deptB1.id,
        name: 'BTech CS College B',
        code: 'BTECH-CS',
        duration: 4,
      },
      collegeAdminB
    );

    expect(courseA.id).toBeDefined();
    expect(courseB.id).toBeDefined();
    expect(courseA.id).not.toBe(courseB.id);
  });

  // =========================================================================
  // 3. EDIT COURSE & LIFECYCLE MANAGEMENT
  // =========================================================================

  it('9. Edit course updates name, duration, code and enforces uniqueness check', async () => {
    const course = await AcademicService.createCourse(
      collegeA.id,
      {
        departmentId: deptA1.id,
        name: 'BTech CSE Initial',
        code: 'BTECH-INIT',
        duration: 3,
      },
      collegeAdminA
    );

    const updated = await AcademicService.updateCourse(
      course.id,
      {
        name: 'BTech Computer Engineering Updated',
        code: 'BTECH-ENG',
        duration: 4,
      },
      collegeAdminA
    );

    expect(updated.name).toBe('BTech Computer Engineering Updated');
    expect(updated.code).toBe('BTECH-ENG');
    expect(updated.duration).toBe(4);
  });

  it('10. Edit course code collision with another existing course is rejected (409 Conflict)', async () => {
    await AcademicService.createCourse(
      collegeA.id,
      {
        departmentId: deptA1.id,
        name: 'First Course',
        code: 'CRS-01',
      },
      collegeAdminA
    );

    const course2 = await AcademicService.createCourse(
      collegeA.id,
      {
        departmentId: deptA1.id,
        name: 'Second Course',
        code: 'CRS-02',
      },
      collegeAdminA
    );

    // Try to update course2 code to CRS-01
    await expect(
      AcademicService.updateCourse(
        course2.id,
        {
          code: 'CRS-01',
        },
        collegeAdminA
      )
    ).rejects.toThrow('Course code "CRS-01" is already in use');
  });

  it('11. Safe deactivation via isActive: false toggles status without deleting entity', async () => {
    const course = await AcademicService.createCourse(
      collegeA.id,
      {
        departmentId: deptA1.id,
        name: 'Temporary Course',
        code: 'TEMP-01',
      },
      collegeAdminA
    );
    expect(course.isActive).toBe(true);

    const deactivated = await AcademicService.updateCourse(
      course.id,
      { isActive: false },
      collegeAdminA
    );
    expect(deactivated.isActive).toBe(false);

    // Document is still present in database for historical reference
    const fetched = await AcademicService.getCourseById(course.id, collegeAdminA);
    expect(fetched.id).toBe(course.id);
    expect(fetched.isActive).toBe(false);
  });

  it('12. Inactive department cannot host new courses (403 Forbidden)', async () => {
    const inactiveDept = await Department.create({
      collegeId: collegeA._id,
      name: 'Archived Dept',
      code: 'ARCH',
      status: DepartmentStatus.INACTIVE,
      isActive: false,
    });

    await expect(
      AcademicService.createCourse(
        collegeA.id,
        {
          departmentId: inactiveDept.id,
          name: 'Archived Program',
          code: 'ARCH-01',
        },
        collegeAdminA
      )
    ).rejects.toThrow('Cannot create course for an inactive department');
  });

  // =========================================================================
  // 4. STUDENT & ROLE ACCESS ISOLATION
  // =========================================================================

  it('13. Student listing courses is scoped to their college and department', async () => {
    await AcademicService.createCourse(
      collegeA.id,
      {
        departmentId: deptA1.id,
        name: 'CS Program Alpha',
        code: 'CS-ALPHA',
      },
      collegeAdminA
    );

    await AcademicService.createCourse(
      collegeA.id,
      {
        departmentId: deptA2.id,
        name: 'ME Program Alpha',
        code: 'ME-ALPHA',
      },
      collegeAdminA
    );

    const result = await AcademicService.listCourses(studentA);
    // Student A is in collegeA and deptA1 -> only CS-ALPHA is visible
    expect(result.items.length).toBe(1);
    expect(result.items[0].code).toBe('CS-ALPHA');
  });

  it('14. Student accessing a course from another college is rejected (403 Forbidden)', async () => {
    const collegeAdminB: AuthenticatedUser = {
      id: new mongoose.Types.ObjectId().toString(),
      instituteId: 'ADMIN-B',
      role: AppRole.COLLEGE_ADMIN,
      collegeId: collegeB.id,
      name: 'Admin Beta',
      accountStatus: AccountStatus.ACTIVE,
    };

    const courseB = await AcademicService.createCourse(
      collegeB.id,
      {
        departmentId: deptB1.id,
        name: 'Beta Program',
        code: 'BETA-01',
      },
      collegeAdminB
    );

    // Student A from College A attempts to view Course B
    await expect(
      AcademicService.getCourseById(courseB.id, studentA)
    ).rejects.toThrow('Cross-college access is strictly prohibited');
  });

  it('15. College Admin cross-college list query is rejected (403 Forbidden)', async () => {
    await expect(
      AcademicService.listCourses(collegeAdminA, { collegeId: collegeB.id })
    ).rejects.toThrow('Cross-college access is strictly prohibited');
  });

  it('16. Enrolled student is strictly scoped to courses from their active StudentEnrollment', async () => {
    const course1 = await AcademicService.createCourse(
      collegeA.id,
      {
        departmentId: deptA1.id,
        name: 'BTech Computer Science',
        code: 'BTECH-CS-ENR',
      },
      collegeAdminA
    );

    const course2 = await AcademicService.createCourse(
      collegeA.id,
      {
        departmentId: deptA1.id,
        name: 'MTech Computer Science',
        code: 'MTECH-CS-ENR',
      },
      collegeAdminA
    );

    const studentUser = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      email: 'student.enrolled@col-a.edu',
      passwordHash: 'dummyhash123',
      name: 'Enrolled Student',
      instituteId: 'ENR-STU-01',
      role: AppRole.STUDENT,
      accountStatus: AccountStatus.ACTIVE,
    });

    const studentDoc = await Student.create({
      userId: studentUser._id,
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      instituteId: studentUser.instituteId,
      name: studentUser.name,
      rollNumber: 'ROLL-CS-001',
      admissionNumber: 'ADM-CS-001',
      status: 'active',
      isActive: true,
      lifecycleState: StudentLifecycleState.ACTIVE,
    });

    await StudentEnrollment.create({
      collegeId: collegeA._id,
      studentId: studentDoc._id,
      departmentId: deptA1._id,
      courseId: course1._id,
      academicYearId: new mongoose.Types.ObjectId(),
      semesterId: new mongoose.Types.ObjectId(),
      sectionId: new mongoose.Types.ObjectId(),
      status: 'active',
    });

    const enrolledRequester: AuthenticatedUser = {
      id: studentUser.id,
      instituteId: studentUser.instituteId,
      role: AppRole.STUDENT,
      collegeId: collegeA.id,
      departmentId: deptA1.id,
      name: studentUser.name,
      accountStatus: AccountStatus.ACTIVE,
    };

    const result = await AcademicService.listCourses(enrolledRequester);
    expect(result.items.length).toBe(1);
    expect(result.items[0].code).toBe('BTECH-CS-ENR');
    expect(result.items.some((c) => c.id === course2.id)).toBe(false);
  });

  it('17. Enrolled student accessing non-enrolled course in same department is rejected (403 Forbidden)', async () => {
    const course1 = await AcademicService.createCourse(
      collegeA.id,
      {
        departmentId: deptA1.id,
        name: 'BTech Software Eng',
        code: 'BTECH-SE',
      },
      collegeAdminA
    );

    const course2 = await AcademicService.createCourse(
      collegeA.id,
      {
        departmentId: deptA1.id,
        name: 'PhD Computer Science',
        code: 'PHD-CS',
      },
      collegeAdminA
    );

    const studentUser = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      email: 'student.se@col-a.edu',
      passwordHash: 'dummyhash123',
      name: 'SE Student',
      instituteId: 'SE-STU-01',
      role: AppRole.STUDENT,
      accountStatus: AccountStatus.ACTIVE,
    });

    const studentDoc = await Student.create({
      userId: studentUser._id,
      collegeId: collegeA._id,
      departmentId: deptA1._id,
      instituteId: studentUser.instituteId,
      name: studentUser.name,
      rollNumber: 'ROLL-SE-001',
      admissionNumber: 'ADM-SE-001',
      status: 'active',
      isActive: true,
      lifecycleState: StudentLifecycleState.ACTIVE,
    });

    await StudentEnrollment.create({
      collegeId: collegeA._id,
      studentId: studentDoc._id,
      departmentId: deptA1._id,
      courseId: course1._id,
      academicYearId: new mongoose.Types.ObjectId(),
      semesterId: new mongoose.Types.ObjectId(),
      sectionId: new mongoose.Types.ObjectId(),
      status: 'active',
    });

    const enrolledRequester: AuthenticatedUser = {
      id: studentUser.id,
      instituteId: studentUser.instituteId,
      role: AppRole.STUDENT,
      collegeId: collegeA.id,
      departmentId: deptA1.id,
      name: studentUser.name,
      accountStatus: AccountStatus.ACTIVE,
    };

    // Allowed: viewing their enrolled course
    const fetchedEnrolled = await AcademicService.getCourseById(course1.id, enrolledRequester);
    expect(fetchedEnrolled.id).toBe(course1.id);

    // Rejected: viewing unenrolled course in same department
    await expect(
      AcademicService.getCourseById(course2.id, enrolledRequester)
    ).rejects.toThrow('Access denied to course outside active enrollment');
  });

  it('18. listCourses filters accurately by isActive status ("true", "false", "all")', async () => {
    const activeCourse = await AcademicService.createCourse(
      collegeA.id,
      {
        departmentId: deptA1.id,
        name: 'Active Program',
        code: 'ACT-01',
      },
      collegeAdminA
    );

    const inactiveCourse = await AcademicService.createCourse(
      collegeA.id,
      {
        departmentId: deptA1.id,
        name: 'Inactive Program',
        code: 'INACT-01',
      },
      collegeAdminA
    );
    await AcademicService.updateCourse(inactiveCourse.id, { isActive: false }, collegeAdminA);

    const activeList = await AcademicService.listCourses(collegeAdminA, { isActive: 'true' });
    expect(activeList.items.some((c) => c.id === activeCourse.id)).toBe(true);
    expect(activeList.items.some((c) => c.id === inactiveCourse.id)).toBe(false);

    const inactiveList = await AcademicService.listCourses(collegeAdminA, { isActive: 'false' });
    expect(inactiveList.items.some((c) => c.id === activeCourse.id)).toBe(false);
    expect(inactiveList.items.some((c) => c.id === inactiveCourse.id)).toBe(true);

    const allList = await AcademicService.listCourses(collegeAdminA, { isActive: 'all' });
    expect(allList.items.some((c) => c.id === activeCourse.id)).toBe(true);
    expect(allList.items.some((c) => c.id === inactiveCourse.id)).toBe(true);
  });
});
