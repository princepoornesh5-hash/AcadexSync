import 'dotenv/config';
import { College } from '../models/college.model';
import { Department } from '../models/department.model';
import { Course } from '../models/course.model';
import { AcademicYear } from '../models/academicYear.model';
import { Semester } from '../models/semester.model';
import { Section } from '../models/section.model';
import { Subject } from '../models/subject.model';
import { Faculty } from '../models/faculty.model';
import { FacultyAssignment } from '../models/facultyAssignment.model';
import { Student } from '../models/student.model';
import { StudentEnrollment } from '../models/studentEnrollment.model';
import { User } from '../models/user.model';
import { PasswordService } from '../services/password.service';
import { AppRole } from '../constants/roles';
import { AccountStatus, StudentLifecycleState, AcademicYearStatus, SemesterStatus, SectionStatus } from '../constants/status';
import { connectDB, disconnectDB } from '../db/connection';

async function seed() {
  await connectDB();
  console.log('[SEED] Connected to MongoDB Atlas');

  // 1. Fetch Existing College & Department
  const college = await College.findOne({ code: 'SVGP-018' });
  if (!college) {
    throw new Error('College SVGP-018 not found');
  }
  console.log(`[SEED] College: ${college.name} (${college._id})`);

  const department = await Department.findOne({ collegeId: college._id, code: 'CS-01' });
  if (!department) {
    throw new Error('Department CS-01 not found');
  }
  console.log(`[SEED] Department: ${department.name} (${department._id})`);

  // Default shared password for QA test users
  const defaultPassword = process.env.QA_USER_PASSWORD || 'Acadex@123456';
  const passwordHash = await PasswordService.hashPassword(defaultPassword);

  // 2. Course
  let course = await Course.findOne({ collegeId: college._id, departmentId: department._id, code: 'CSE-BTECH' });
  if (!course) {
    course = await Course.create({
      collegeId: college._id,
      departmentId: department._id,
      name: 'Computer Science and Engineering',
      code: 'CSE-BTECH',
      duration: 4,
      isActive: true,
    });
    console.log(`[SEED] Created Course: ${course.name} (${course._id})`);
  } else {
    console.log(`[SEED] Reused Course: ${course.name} (${course._id})`);
  }

  // 3. Academic Year
  let academicYear = await AcademicYear.findOne({ collegeId: college._id, name: '2026-2027' });
  if (!academicYear) {
    academicYear = await AcademicYear.create({
      collegeId: college._id,
      name: '2026-2027',
      startDate: new Date('2026-06-01T00:00:00.000Z'),
      endDate: new Date('2027-05-31T23:59:59.000Z'),
      status: AcademicYearStatus.ACTIVE,
      isCurrent: true,
      isActive: true,
    });
    console.log(`[SEED] Created AcademicYear: ${academicYear.name} (${academicYear._id})`);
  } else {
    console.log(`[SEED] Reused AcademicYear: ${academicYear.name} (${academicYear._id})`);
  }

  // 4. Semester
  let semester = await Semester.findOne({ collegeId: college._id, courseId: course._id, number: 4 });
  if (!semester) {
    semester = await Semester.create({
      collegeId: college._id,
      departmentId: department._id,
      courseId: course._id,
      academicYearId: academicYear._id,
      name: 'Semester 4',
      number: 4,
      startDate: new Date('2026-06-01T00:00:00.000Z'),
      endDate: new Date('2027-05-31T23:59:59.000Z'),
      status: SemesterStatus.ACTIVE,
      isCurrent: true,
      isActive: true,
    });
    console.log(`[SEED] Created Semester: ${semester.name} (${semester._id})`);
  } else {
    console.log(`[SEED] Reused Semester: ${semester.name} (${semester._id})`);
  }

  // 5. Section
  let section = await Section.findOne({ collegeId: college._id, semesterId: semester._id, name: 'Section A' });
  if (!section) {
    section = await Section.create({
      collegeId: college._id,
      departmentId: department._id,
      courseId: course._id,
      academicYearId: academicYear._id,
      semesterId: semester._id,
      name: 'Section A',
      capacity: 60,
      status: SectionStatus.ACTIVE,
      isActive: true,
    });
    console.log(`[SEED] Created Section: ${section.name} (${section._id})`);
  } else {
    console.log(`[SEED] Reused Section: ${section.name} (${section._id})`);
  }

  // 6. Subject
  let subject = await Subject.findOne({ collegeId: college._id, semesterId: semester._id, code: 'WT-401' });
  if (!subject) {
    subject = await Subject.create({
      collegeId: college._id,
      departmentId: department._id,
      courseId: course._id,
      semesterId: semester._id,
      name: 'Web Technologies',
      code: 'WT-401',
      credits: 4,
      type: 'Theory',
      isActive: true,
    });
    console.log(`[SEED] Created Subject: ${subject.name} (${subject._id})`);
  } else {
    console.log(`[SEED] Reused Subject: ${subject.name} (${subject._id})`);
  }

  // 7. Verify / Fetch Faculty A (MOHAN)
  const facultyAUser = await User.findOne({ email: 'mohan@gmail.com' });
  if (!facultyAUser) {
    throw new Error('Faculty A MOHAN user not found in database');
  }
  let facultyADoc = await Faculty.findOne({ userId: facultyAUser._id });
  if (!facultyADoc) {
    facultyADoc = await Faculty.create({
      collegeId: college._id,
      departmentId: department._id,
      userId: facultyAUser._id,
      instituteId: 'MOH-01',
      name: 'MOHAN',
      email: 'mohan@gmail.com',
      designation: 'Assistant Professor',
      status: 'active',
      isActive: true,
    });
    console.log(`[SEED] Created Faculty A Doc for MOHAN (${facultyADoc._id})`);
  } else {
    console.log(`[SEED] Reused Faculty A Doc: ${facultyADoc.name} (${facultyADoc._id})`);
  }

  // 8. Create or Reuse Faculty B (SURESH)
  let facultyBUser = await User.findOne({ email: 'suresh.faculty@gmail.com' });
  if (!facultyBUser) {
    facultyBUser = await User.create({
      name: 'SURESH',
      email: 'suresh.faculty@gmail.com',
      instituteId: 'SUR-01',
      role: AppRole.FACULTY,
      passwordHash,
      accountStatus: AccountStatus.ACTIVE,
      activationStatus: 'activated',
      collegeId: college._id,
      departmentId: department._id,
    });
    console.log(`[SEED] Created Faculty B User: ${facultyBUser.email} (${facultyBUser._id})`);
  } else {
    console.log(`[SEED] Reused Faculty B User: ${facultyBUser.email} (${facultyBUser._id})`);
  }

  let facultyBDoc = await Faculty.findOne({ userId: facultyBUser._id });
  if (!facultyBDoc) {
    facultyBDoc = await Faculty.create({
      collegeId: college._id,
      departmentId: department._id,
      userId: facultyBUser._id,
      instituteId: 'SUR-01',
      name: 'SURESH',
      employeeId: 'EMP-SUR-02',
      email: 'suresh.faculty@gmail.com',
      designation: 'Associate Professor',
      status: 'active',
      isActive: true,
    });
    console.log(`[SEED] Created Faculty B Doc: ${facultyBDoc.name} (${facultyBDoc._id})`);
  } else {
    console.log(`[SEED] Reused Faculty B Doc: ${facultyBDoc.name} (${facultyBDoc._id})`);
  }

  // 9. Create or Reuse Student 1 (RAMESH)
  let student1User = await User.findOne({ email: 'ramesh.student@gmail.com' });
  if (!student1User) {
    student1User = await User.create({
      name: 'RAMESH',
      email: 'ramesh.student@gmail.com',
      instituteId: 'STD-2022-01',
      role: AppRole.STUDENT,
      passwordHash,
      accountStatus: AccountStatus.ACTIVE,
      activationStatus: 'activated',
      collegeId: college._id,
      departmentId: department._id,
      courseId: course._id,
      semesterId: semester._id,
      sectionId: section._id,
    });
    console.log(`[SEED] Created Student 1 User: ${student1User.email} (${student1User._id})`);
  } else {
    console.log(`[SEED] Reused Student 1 User: ${student1User.email} (${student1User._id})`);
  }

  let student1Doc = await Student.findOne({ userId: student1User._id });
  if (!student1Doc) {
    student1Doc = await Student.create({
      collegeId: college._id,
      departmentId: department._id,
      userId: student1User._id,
      instituteId: 'STD-2022-01',
      name: 'RAMESH',
      rollNumber: '22018-CS-001',
      admissionNumber: 'ADM-2022-001',
      email: 'ramesh.student@gmail.com',
      courseId: course._id,
      academicYearId: academicYear._id,
      semesterId: semester._id,
      sectionId: section._id,
      lifecycleState: StudentLifecycleState.ACTIVE,
      status: 'active',
      isActive: true,
    });
    console.log(`[SEED] Created Student 1 Doc: ${student1Doc.name} (${student1Doc._id})`);
  } else {
    console.log(`[SEED] Reused Student 1 Doc: ${student1Doc.name} (${student1Doc._id})`);
  }

  let enrollment1 = await StudentEnrollment.findOne({
    collegeId: college._id,
    studentId: student1Doc._id,
    sectionId: section._id,
  });
  if (!enrollment1) {
    enrollment1 = await StudentEnrollment.create({
      collegeId: college._id,
      studentId: student1Doc._id,
      departmentId: department._id,
      courseId: course._id,
      academicYearId: academicYear._id,
      semesterId: semester._id,
      sectionId: section._id,
      enrollmentDate: new Date('2026-06-01T00:00:00.000Z'),
      status: 'active',
    });
    console.log(`[SEED] Created Student 1 Enrollment: (${enrollment1._id})`);
  } else {
    console.log(`[SEED] Reused Student 1 Enrollment: (${enrollment1._id})`);
  }

  // 10. Create or Reuse Student 2 (SITA)
  let student2User = await User.findOne({ email: 'sita.student@gmail.com' });
  if (!student2User) {
    student2User = await User.create({
      name: 'SITA',
      email: 'sita.student@gmail.com',
      instituteId: 'STD-2022-02',
      role: AppRole.STUDENT,
      passwordHash,
      accountStatus: AccountStatus.ACTIVE,
      activationStatus: 'activated',
      collegeId: college._id,
      departmentId: department._id,
      courseId: course._id,
      semesterId: semester._id,
      sectionId: section._id,
    });
    console.log(`[SEED] Created Student 2 User: ${student2User.email} (${student2User._id})`);
  } else {
    console.log(`[SEED] Reused Student 2 User: ${student2User.email} (${student2User._id})`);
  }

  let student2Doc = await Student.findOne({ userId: student2User._id });
  if (!student2Doc) {
    student2Doc = await Student.create({
      collegeId: college._id,
      departmentId: department._id,
      userId: student2User._id,
      instituteId: 'STD-2022-02',
      name: 'SITA',
      rollNumber: '22018-CS-002',
      admissionNumber: 'ADM-2022-002',
      email: 'sita.student@gmail.com',
      courseId: course._id,
      academicYearId: academicYear._id,
      semesterId: semester._id,
      sectionId: section._id,
      lifecycleState: StudentLifecycleState.ACTIVE,
      status: 'active',
      isActive: true,
    });
    console.log(`[SEED] Created Student 2 Doc: ${student2Doc.name} (${student2Doc._id})`);
  } else {
    console.log(`[SEED] Reused Student 2 Doc: ${student2Doc.name} (${student2Doc._id})`);
  }

  let enrollment2 = await StudentEnrollment.findOne({
    collegeId: college._id,
    studentId: student2Doc._id,
    sectionId: section._id,
  });
  if (!enrollment2) {
    enrollment2 = await StudentEnrollment.create({
      collegeId: college._id,
      studentId: student2Doc._id,
      departmentId: department._id,
      courseId: course._id,
      academicYearId: academicYear._id,
      semesterId: semester._id,
      sectionId: section._id,
      enrollmentDate: new Date('2026-06-01T00:00:00.000Z'),
      status: 'active',
    });
    console.log(`[SEED] Created Student 2 Enrollment: (${enrollment2._id})`);
  } else {
    console.log(`[SEED] Reused Student 2 Enrollment: (${enrollment2._id})`);
  }

  // 11. Create or Reuse FacultyAssignment for Faculty A (MOHAN)
  let assignment = await FacultyAssignment.findOne({
    collegeId: college._id,
    departmentId: department._id,
    facultyId: facultyADoc._id,
    subjectId: subject._id,
    sectionId: section._id,
  });
  if (!assignment) {
    assignment = await FacultyAssignment.create({
      collegeId: college._id,
      departmentId: department._id,
      facultyId: facultyADoc._id,
      facultyName: facultyADoc.name,
      courseId: course._id,
      semesterId: semester._id,
      sectionId: section._id,
      subjectId: subject._id,
      academicYearId: academicYear._id,
      roomId: 'LHC-101',
      maxStudents: 60,
      assignmentType: 'lecture',
      isActive: true,
      assignedAt: new Date(),
    });
    console.log(`[SEED] Created FacultyAssignment for MOHAN: (${assignment._id})`);
  } else {
    console.log(`[SEED] Reused FacultyAssignment: (${assignment._id})`);
  }

  console.log('\n======================================================');
  console.log('TIMETABLE QA FIXTURES READY');
  console.log('======================================================');
  console.log('College ID:        ', college._id.toString());
  console.log('Department ID:     ', department._id.toString(), '(CSE)');
  console.log('Course ID:         ', course._id.toString(), '(CSE-BTECH)');
  console.log('Academic Year ID:  ', academicYear._id.toString(), '(2026-2027)');
  console.log('Semester ID:       ', semester._id.toString(), '(Semester 4)');
  console.log('Section ID:        ', section._id.toString(), '(Section A)');
  console.log('Subject ID:        ', subject._id.toString(), '(WT-401)');
  console.log('Faculty A (MOHAN): ', facultyADoc._id.toString(), '| User:', facultyAUser.email);
  console.log('Faculty B (SURESH):', facultyBDoc._id.toString(), '| User:', facultyBUser.email);
  console.log('Student 1 (RAMESH):', student1Doc._id.toString(), '| User:', student1User.email);
  console.log('Student 2 (SITA):  ', student2Doc._id.toString(), '| User:', student2User.email);
  console.log('FacultyAssignment: ', assignment._id.toString());
  console.log('QA Accounts Password:', defaultPassword);
  console.log('======================================================\n');

  await disconnectDB();
}

seed().catch(async (err) => {
  console.error('[SEED ERROR]:', err);
  await disconnectDB();
  process.exit(1);
});
