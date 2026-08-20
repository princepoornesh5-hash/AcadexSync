import { AcademicService } from '../../src/services/academic.service';
import { College } from '../../src/models/college.model';
import { Department } from '../../src/models/department.model';
import { Course } from '../../src/models/course.model';
import { AcademicYear } from '../../src/models/academicYear.model';
import { Semester } from '../../src/models/semester.model';
import { Section } from '../../src/models/section.model';
import { Subject } from '../../src/models/subject.model';
import { Faculty } from '../../src/models/faculty.model';
import { Student } from '../../src/models/student.model';
import { User } from '../../src/models/user.model';
import { AppRole } from '../../src/constants/roles';
import { AccountStatus } from '../../src/constants/status';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { AuthenticatedUser } from '../../src/types/auth.types';

describe('Academic Hierarchy Relationships Integration Tests', () => {
  let collegeId: string;
  let departmentId: string;
  let adminRequester: AuthenticatedUser;

  beforeAll(async () => {
    await setupTestDB();
    await College.init();
    await Department.init();
    await Course.init();
    await AcademicYear.init();
    await Semester.init();
    await Section.init();
    await Subject.init();
    await Faculty.init();
    await Student.init();
    await User.init();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();

    const college = await College.create({
      name: 'Apex Engineering Institute',
      code: 'AEI',
      address: 'Knowledge City',
      email: 'contact@apex.edu',
      phone: '1234567890',
      principal: 'Dr. Principal',
    });
    collegeId = college.id;

    const dept = await Department.create({
      collegeId: college._id,
      name: 'Information Technology',
      code: 'IT',
    });
    departmentId = dept.id;

    adminRequester = {
      id: new User().id,
      instituteId: 'ADMIN-01',
      role: AppRole.COLLEGE_ADMIN,
      collegeId: college.id,
      name: 'Apex Admin',
      accountStatus: AccountStatus.ACTIVE,
    };
  });

  it('should construct full academic chain: Course -> AcademicYear -> Semester -> Section', async () => {
    // 1. Course
    const course = await AcademicService.createCourse(
      collegeId,
      {
        departmentId,
        name: 'Bachelor of Technology in IT',
        code: 'BTECH-IT',
        duration: 4,
      },
      adminRequester
    );
    expect(course.code).toBe('BTECH-IT');

    // 2. Academic Year
    const academicYear = await AcademicService.createAcademicYear(
      collegeId,
      {
        name: '2026-2027',
        startDate: '2026-08-01T00:00:00.000Z',
        endDate: '2027-05-31T23:59:59.000Z',
        isCurrent: true,
      },
      adminRequester
    );
    expect(academicYear.name).toBe('2026-2027');

    // 3. Semester
    const semester = await AcademicService.createSemester(
      collegeId,
      {
        courseId: course.id,
        academicYearId: academicYear.id,
        name: 'Semester 5',
        number: 5,
      },
      adminRequester
    );
    expect(semester.number).toBe(5);

    // 4. Section
    const section = await AcademicService.createSection(
      collegeId,
      {
        courseId: course.id,
        academicYearId: academicYear.id,
        semesterId: semester.id,
        name: 'Section A',
        capacity: 60,
      },
      adminRequester
    );
    expect(section.name).toBe('SECTION A');

    // 5. Subject
    const subject = await AcademicService.createSubject(
      collegeId,
      {
        courseId: course.id,
        semesterId: semester.id,
        name: 'Database Management Systems',
        code: 'CS501',
        credits: 4,
      },
      adminRequester
    );
    expect(subject.code).toBe('CS501');

    // 6. Student
    const studentUser = await User.create({
      instituteId: 'STU-IT-001',
      name: 'John Connor',
      email: 'john.connor@student.apex.edu',
      passwordHash: 'hash',
      role: AppRole.STUDENT,
      collegeId: collegeId,
      departmentId: departmentId,
      accountStatus: AccountStatus.ACTIVE,
    });
    const student = await Student.create({
      collegeId: collegeId,
      departmentId: departmentId,
      userId: studentUser._id,
      instituteId: studentUser.instituteId,
      name: studentUser.name,
      rollNumber: '2026-IT-001',
      status: 'active',
      isActive: true,
    });
    expect(student.rollNumber).toBe('2026-IT-001');

    // 7. Student Enrollment
    const enrollment = await AcademicService.enrollStudent(
      collegeId,
      {
        studentId: student.id,
        courseId: course.id,
        academicYearId: academicYear.id,
        semesterId: semester.id,
        sectionId: section.id,
      },
      adminRequester
    );
    expect(enrollment.status).toBe('active');
  });
});
