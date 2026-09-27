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
import { Timetable } from '../models/timetable.model';
import { User } from '../models/user.model';
import { PasswordService } from '../services/password.service';
import { AppRole } from '../constants/roles';
import {
  AccountStatus,
  StudentLifecycleState,
  AcademicYearStatus,
  SemesterStatus,
  SectionStatus,
  TimetableStatus,
  TimetableDay,
  TimetableTimingMode,
  TimetableSessionType,
} from '../constants/status';
import { connectDB, disconnectDB } from '../db/connection';

export async function seedPilotReadiness() {
  await connectDB();
  console.log('====================================================');
  console.log('[PILOT SEED] Seeding Minimal 5-Mobile Physical Pilot Scenario');
  console.log('====================================================');

  const defaultPassword = process.env.PILOT_USER_PASSWORD || 'Pilot@2026';
  const passwordHash = await PasswordService.hashPassword(defaultPassword);

  // 1. College
  let college = await College.findOne({ code: 'API-001' });
  if (!college) {
    college = await College.create({
      name: 'Acadex Polytechnic Institute',
      code: 'API-001',
      address: 'Central Campus, Knowledge Park',
      email: 'admin@acadex-pilot.edu',
      phone: '9876543210',
      principal: 'Dr. Ramesh Gupta',
    });
    console.log(`[+] College created: ${college.name} (${college.code})`);
  } else {
    console.log(`[=] College exists: ${college.name} (${college.code})`);
  }

  // 2. Department
  let department = await Department.findOne({ collegeId: college._id, code: 'CSE' });
  if (!department) {
    department = await Department.create({
      collegeId: college._id,
      name: 'Computer Engineering',
      code: 'CSE',
    });
    console.log(`[+] Department created: ${department.name}`);
  } else {
    console.log(`[=] Department exists: ${department.name}`);
  }

  // 3. Academic Years (Current 2026–27 + Historical 2025–26)
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
    console.log(`[+] Current Academic Year created: ${currentAY.name}`);
  } else {
    console.log(`[=] Current Academic Year exists: ${currentAY.name}`);
  }

  let historicalAY = await AcademicYear.findOne({ collegeId: college._id, name: '2025–26' });
  if (!historicalAY) {
    historicalAY = await AcademicYear.create({
      collegeId: college._id,
      name: '2025–26',
      startDate: new Date('2025-06-01T00:00:00.000Z'),
      endDate: new Date('2026-05-31T23:59:59.000Z'),
      status: AcademicYearStatus.COMPLETED,
      isCurrent: false,
      isActive: true,
    });
    console.log(`[+] Historical Academic Year created: ${historicalAY.name}`);
  }

  // 4. Program / Course
  let course = await Course.findOne({ collegeId: college._id, code: 'DCSE' });
  if (!course) {
    course = await Course.create({
      collegeId: college._id,
      departmentId: department._id,
      name: 'Diploma in Computer Engineering',
      code: 'DCSE',
      duration: 3,
      progressionType: 'YEAR_SEMESTER',
      isActive: true,
    });
    console.log(`[+] Course created: ${course.name} (Progression: ${course.progressionType})`);
  } else {
    console.log(`[=] Course exists: ${course.name}`);
  }

  // 5. Semesters
  let sem5 = await Semester.findOne({ collegeId: college._id, courseId: course._id, number: 5 });
  if (!sem5) {
    sem5 = await Semester.create({
      collegeId: college._id,
      departmentId: department._id,
      courseId: course._id,
      academicYearId: currentAY._id,
      name: 'Semester 5',
      number: 5,
      isCurrent: true,
      status: SemesterStatus.ACTIVE,
      isActive: true,
    });
    console.log(`[+] Semester created: ${sem5.name}`);
  }

  // 6. Section A
  let sectionA = await Section.findOne({ collegeId: college._id, semesterId: sem5._id, name: 'A' });
  if (!sectionA) {
    sectionA = await Section.create({
      collegeId: college._id,
      departmentId: department._id,
      courseId: course._id,
      academicYearId: currentAY._id,
      semesterId: sem5._id,
      name: 'A',
      capacity: 60,
      status: SectionStatus.ACTIVE,
      isActive: true,
    });
    console.log(`[+] Section created: Class ${sectionA.name}`);
  }

  // 7. Subject
  let subjectDBMS = await Subject.findOne({ collegeId: college._id, code: 'CS501' });
  if (!subjectDBMS) {
    subjectDBMS = await Subject.create({
      collegeId: college._id,
      departmentId: department._id,
      courseId: course._id,
      semesterId: sem5._id,
      name: 'Database Management Systems',
      code: 'CS501',
      credits: 4,
      type: 'THEORY',
      isActive: true,
    });
    console.log(`[+] Subject created: ${subjectDBMS.name} (${subjectDBMS.code})`);
  }

  // 8. Users & Roles for 5 Phones
  // PHONE 1: College Admin
  let adminUser = await User.findOne({ email: 'admin@acadex-pilot.edu' });
  if (!adminUser) {
    adminUser = await User.create({
      collegeId: college._id,
      name: 'College Admin',
      email: 'admin@acadex-pilot.edu',
      instituteId: 'INST-ADMIN-001',
      passwordHash,
      role: AppRole.COLLEGE_ADMIN,
      accountStatus: AccountStatus.ACTIVE,
    });
    console.log(`[+] PHONE 1 User: admin@acadex-pilot.edu`);
  }

  // PHONE 2: HOD
  let hodUser = await User.findOne({ email: 'hod.cse@acadex-pilot.edu' });
  if (!hodUser) {
    hodUser = await User.create({
      collegeId: college._id,
      departmentId: department._id,
      name: 'Prof. Suresh Verma',
      email: 'hod.cse@acadex-pilot.edu',
      instituteId: 'INST-HOD-001',
      passwordHash,
      role: AppRole.HOD,
      accountStatus: AccountStatus.ACTIVE,
    });
    console.log(`[+] PHONE 2 User: hod.cse@acadex-pilot.edu`);
  }

  // Link HOD to Department
  department.hodId = hodUser._id.toString();
  await department.save();

  // PHONE 3: Faculty
  let facultyUser = await User.findOne({ email: 'faculty.dbms@acadex-pilot.edu' });
  if (!facultyUser) {
    facultyUser = await User.create({
      collegeId: college._id,
      departmentId: department._id,
      name: 'Prof. Rajesh Kumar',
      email: 'faculty.dbms@acadex-pilot.edu',
      instituteId: 'INST-FAC-001',
      passwordHash,
      role: AppRole.FACULTY,
      accountStatus: AccountStatus.ACTIVE,
    });
    console.log(`[+] PHONE 3 User: faculty.dbms@acadex-pilot.edu`);
  }

  let facultyDoc = await Faculty.findOne({ userId: facultyUser._id });
  if (!facultyDoc) {
    facultyDoc = await Faculty.create({
      collegeId: college._id,
      departmentId: department._id,
      userId: facultyUser._id,
      name: 'Prof. Rajesh Kumar',
      email: facultyUser.email,
      employeeId: 'FAC-CSE-001',
      designation: 'Assistant Professor',
      status: 'active',
      isActive: true,
    });
    console.log(`[+] Faculty Profile created: ${facultyDoc.name} (${facultyDoc.employeeId})`);
  }

  // PHONE 4: Student A
  let studentAUser = await User.findOne({ email: 'student.a@acadex-pilot.edu' });
  if (!studentAUser) {
    studentAUser = await User.create({
      collegeId: college._id,
      departmentId: department._id,
      name: 'Aarav Sharma',
      email: 'student.a@acadex-pilot.edu',
      instituteId: 'INST-STU-001',
      passwordHash,
      role: AppRole.STUDENT,
      accountStatus: AccountStatus.ACTIVE,
    });
    console.log(`[+] PHONE 4 User: student.a@acadex-pilot.edu`);
  }
  let studentADoc = await Student.findOne({ userId: studentAUser._id });
  if (!studentADoc) {
    studentADoc = await Student.create({
      collegeId: college._id,
      departmentId: department._id,
      userId: studentAUser._id,
      name: 'Aarav Sharma',
      rollNumber: 'CSE-24-001',
      admissionNumber: 'ADM-2024-001',
      email: studentAUser.email,
      courseId: course._id,
      academicYearId: currentAY._id,
      semesterId: sem5._id,
      sectionId: sectionA._id,
      cohort: '2024–27',
      academicStage: '3rd Year',
      lifecycleState: StudentLifecycleState.ACTIVE,
      status: 'active',
      isActive: true,
    });
  }

  // PHONE 5: Student B & Student C
  let studentBUser = await User.findOne({ email: 'student.b@acadex-pilot.edu' });
  if (!studentBUser) {
    studentBUser = await User.create({
      collegeId: college._id,
      departmentId: department._id,
      name: 'Bhavya Patel',
      email: 'student.b@acadex-pilot.edu',
      instituteId: 'INST-STU-002',
      passwordHash,
      role: AppRole.STUDENT,
      accountStatus: AccountStatus.ACTIVE,
    });
    console.log(`[+] PHONE 5 (Student B) User: student.b@acadex-pilot.edu`);
  }
  let studentBDoc = await Student.findOne({ userId: studentBUser._id });
  if (!studentBDoc) {
    studentBDoc = await Student.create({
      collegeId: college._id,
      departmentId: department._id,
      userId: studentBUser._id,
      name: 'Bhavya Patel',
      rollNumber: 'CSE-24-002',
      admissionNumber: 'ADM-2024-002',
      email: studentBUser.email,
      courseId: course._id,
      academicYearId: currentAY._id,
      semesterId: sem5._id,
      sectionId: sectionA._id,
      cohort: '2024–27',
      academicStage: '3rd Year',
      lifecycleState: StudentLifecycleState.ACTIVE,
      status: 'active',
      isActive: true,
    });
  }

  let studentCUser = await User.findOne({ email: 'student.c@acadex-pilot.edu' });
  if (!studentCUser) {
    studentCUser = await User.create({
      collegeId: college._id,
      departmentId: department._id,
      name: 'Chirag Verma',
      email: 'student.c@acadex-pilot.edu',
      instituteId: 'INST-STU-003',
      passwordHash,
      role: AppRole.STUDENT,
      accountStatus: AccountStatus.ACTIVE,
    });
    console.log(`[+] PHONE 5 (Student C) User: student.c@acadex-pilot.edu`);
  }
  let studentCDoc = await Student.findOne({ userId: studentCUser._id });
  if (!studentCDoc) {
    studentCDoc = await Student.create({
      collegeId: college._id,
      departmentId: department._id,
      userId: studentCUser._id,
      name: 'Chirag Verma',
      rollNumber: 'CSE-24-003',
      admissionNumber: 'ADM-2024-003',
      email: studentCUser.email,
      courseId: course._id,
      academicYearId: currentAY._id,
      semesterId: sem5._id,
      sectionId: sectionA._id,
      cohort: '2024–27',
      academicStage: '3rd Year',
      lifecycleState: StudentLifecycleState.ACTIVE,
      status: 'active',
      isActive: true,
    });
  }

  // 9. FacultyAssignment
  let facultyAssignment = await FacultyAssignment.findOne({
    collegeId: college._id,
    facultyId: facultyDoc._id,
    subjectId: subjectDBMS._id,
    sectionId: sectionA._id,
  });
  if (!facultyAssignment) {
    facultyAssignment = await FacultyAssignment.create({
      collegeId: college._id,
      departmentId: department._id,
      facultyId: facultyDoc._id,
      facultyName: facultyDoc.name,
      subjectId: subjectDBMS._id,
      courseId: course._id,
      semesterId: sem5._id,
      sectionId: sectionA._id,
      academicYearId: currentAY._id,
      cohort: '2024–27',
      academicStage: '3rd Year',
      status: 'active',
      isActive: true,
    });
    console.log(`[+] FacultyAssignment created: DBMS -> Prof. Rajesh Kumar (${facultyAssignment.cohort} · ${facultyAssignment.academicStage})`);
  }

  // 10. Student Enrollments for exactly 3 students
  const studentDocs = [studentADoc, studentBDoc, studentCDoc];
  for (const stu of studentDocs) {
    let enrollment = await StudentEnrollment.findOne({
      collegeId: college._id,
      studentId: stu._id,
      sectionId: sectionA._id,
    });
    if (!enrollment) {
      enrollment = await StudentEnrollment.create({
        collegeId: college._id,
        departmentId: department._id,
        studentId: stu._id,
        courseId: course._id,
        semesterId: sem5._id,
        sectionId: sectionA._id,
        academicYearId: currentAY._id,
        cohort: '2024–27',
        academicStage: '3rd Year',
        status: 'active',
      });
      console.log(`[+] Enrolled ${stu.name} (${stu.rollNumber}) in Section A`);
    }
  }

  // 11. Published Timetable for Class A
  // Determine today's TimetableDay so it directly appears in today's classes
  const daysOfWeek: TimetableDay[] = [
    TimetableDay.SUNDAY,
    TimetableDay.MONDAY,
    TimetableDay.TUESDAY,
    TimetableDay.WEDNESDAY,
    TimetableDay.THURSDAY,
    TimetableDay.FRIDAY,
    TimetableDay.SATURDAY,
  ];
  const todayDay = daysOfWeek[new Date().getDay()];

  let timetable = await Timetable.findOne({
    collegeId: college._id,
    sectionId: sectionA._id,
    semesterId: sem5._id,
  });

  const entryDays = Array.from(new Set([TimetableDay.MONDAY, todayDay]));

  const entries = entryDays.map((day) => ({
    dayOfWeek: day,
    startTime: '10:00',
    endTime: '11:00',
    subjectId: subjectDBMS._id,
    facultyId: facultyDoc._id,
    facultyAssignmentId: facultyAssignment._id,
    roomNumber: 'Lab 2',
    building: 'Main Block',
    sessionType: TimetableSessionType.LECTURE,
  }));

  if (!timetable) {
    timetable = await Timetable.create({
      collegeId: college._id,
      departmentId: department._id,
      courseId: course._id,
      academicYearId: currentAY._id,
      semesterId: sem5._id,
      sectionId: sectionA._id,
      name: 'Class A - Timetable 2026-27',
      status: TimetableStatus.PUBLISHED,
      version: 1,
      activeDays: [TimetableDay.MONDAY, TimetableDay.TUESDAY, TimetableDay.WEDNESDAY, TimetableDay.THURSDAY, TimetableDay.FRIDAY, TimetableDay.SATURDAY, TimetableDay.SUNDAY],
      timingMode: TimetableTimingMode.SAME_EVERY_DAY,
      periods: [],
      breaks: [],
      entries,
      publishedAt: new Date(),
    });
    console.log(`[+] Timetable created and PUBLISHED for Class A (Active Days: ${entryDays.join(', ')})`);
  } else {
    timetable.status = TimetableStatus.PUBLISHED;
    timetable.entries = entries as any;
    await timetable.save();
    console.log(`[=] Timetable updated and PUBLISHED for Class A`);
  }

  console.log('====================================================');
  console.log('[SUCCESS] Pilot Dataset Provisioned Successfully!');
  console.log('Credentials Summary:');
  console.log('  Password (all users): ' + defaultPassword);
  console.log('  PHONE 1 (College Admin): admin@acadex-pilot.edu');
  console.log('  PHONE 2 (HOD):           hod.cse@acadex-pilot.edu');
  console.log('  PHONE 3 (Faculty):       faculty.dbms@acadex-pilot.edu');
  console.log('  PHONE 4 (Student A):     student.a@acadex-pilot.edu');
  console.log('  PHONE 5 (Student B/C):   student.b@acadex-pilot.edu / student.c@acadex-pilot.edu');
  console.log('====================================================');

  await disconnectDB();
}

if (require.main === module) {
  seedPilotReadiness()
    .then(() => process.exit(0))
    .catch((err) => {
      console.error('[!] Error seeding pilot data:', err);
      process.exit(1);
    });
}
