import mongoose, { Types } from 'mongoose';
import { MongoMemoryServer } from 'mongodb-memory-server';
import {
  User,
  Student,
  Faculty,
  StudentEnrollment,
  FacultyAssignment,
  Department,
  College,
  Course,
  Semester,
  AcademicYear,
  Section,
  Subject,
  AuditLog,
} from '../../src/models';
import { AppRole } from '../../src/constants/roles';
import { ProfileService } from '../../src/services/profile.service';
import { realtimeEventBus } from '../../src/realtime';
import { AuthenticatedUser } from '../../src/types/auth.types';

describe('PROMPT 48 — Role-Aware Profiles, Identity & Profile Management Tests', () => {
  let mongoServer: MongoMemoryServer;

  let collegeAId: Types.ObjectId;
  let collegeBId: Types.ObjectId;
  let deptAId: Types.ObjectId;
  let deptBId: Types.ObjectId;

  let courseAId: Types.ObjectId;
  let academicYearAId: Types.ObjectId;
  let semesterAId: Types.ObjectId;
  let sectionAId: Types.ObjectId;
  let subjectAId: Types.ObjectId;

  let student1UserId: Types.ObjectId;
  let student1ProfileId: Types.ObjectId;
  let student2UserId: Types.ObjectId;
  let student2ProfileId: Types.ObjectId;

  let faculty1UserId: Types.ObjectId;
  let faculty1ProfileId: Types.ObjectId;
  let faculty2UserId: Types.ObjectId;
  let faculty2ProfileId: Types.ObjectId;

  let hodAUserId: Types.ObjectId;
  let adminAUserId: Types.ObjectId;
  let studentBUserId: Types.ObjectId;
  let superAdminUserId: Types.ObjectId;

  let authStudent1: AuthenticatedUser;
  let authStudent2: AuthenticatedUser;
  let authFaculty1: AuthenticatedUser;
  let authFaculty2: AuthenticatedUser;
  let authHodA: AuthenticatedUser;
  let authAdminA: AuthenticatedUser;
  let authStudentB: AuthenticatedUser;
  let authSuperAdmin: AuthenticatedUser;

  const capturedRealtimeEvents: any[] = [];
  let eventHandler: any;

  beforeAll(async () => {
    mongoServer = await MongoMemoryServer.create();
    await mongoose.connect(mongoServer.getUri());

    eventHandler = (event: any) => {
      capturedRealtimeEvents.push(event);
    };
    realtimeEventBus.on('*', eventHandler);

    collegeAId = new Types.ObjectId();
    collegeBId = new Types.ObjectId();
    deptAId = new Types.ObjectId();
    deptBId = new Types.ObjectId();

    courseAId = new Types.ObjectId();
    academicYearAId = new Types.ObjectId();
    semesterAId = new Types.ObjectId();
    sectionAId = new Types.ObjectId();
    subjectAId = new Types.ObjectId();

    student1UserId = new Types.ObjectId();
    student1ProfileId = new Types.ObjectId();
    student2UserId = new Types.ObjectId();
    student2ProfileId = new Types.ObjectId();

    faculty1UserId = new Types.ObjectId();
    faculty1ProfileId = new Types.ObjectId();
    faculty2UserId = new Types.ObjectId();
    faculty2ProfileId = new Types.ObjectId();

    hodAUserId = new Types.ObjectId();
    adminAUserId = new Types.ObjectId();
    studentBUserId = new Types.ObjectId();
    superAdminUserId = new Types.ObjectId();

    // Create Colleges
    await College.create([
      {
        _id: collegeAId,
        name: 'Apex Institute of Technology',
        code: 'AIT',
        principal: 'Dr. Apex',
        phone: '1234567890',
        email: 'info@ait.edu',
        address: '1 Tech Park',
      },
      {
        _id: collegeBId,
        name: 'Beacon College of Engineering',
        code: 'BCE',
        principal: 'Dr. Beacon',
        phone: '9876543210',
        email: 'info@bce.edu',
        address: '2 Science Blvd',
      },
    ]);

    // Create Departments
    await Department.create([
      {
        _id: deptAId,
        collegeId: collegeAId,
        name: 'Computer Science & Engineering',
        code: 'CSE',
        hodId: hodAUserId.toString(),
      },
      {
        _id: deptBId,
        collegeId: collegeAId,
        name: 'Mechanical Engineering',
        code: 'MECH',
      },
    ]);

    // Academic Structure for College A
    await Course.create({
      _id: courseAId,
      collegeId: collegeAId,
      departmentId: deptAId,
      name: 'B.Tech CSE',
      code: 'BTCSE',
      durationYears: 4,
    });

    await AcademicYear.create({
      _id: academicYearAId,
      collegeId: collegeAId,
      name: '2025-2026',
      startDate: new Date('2025-08-01'),
      endDate: new Date('2026-06-30'),
      status: 'active',
    });

    await Semester.create({
      _id: semesterAId,
      collegeId: collegeAId,
      departmentId: deptAId,
      courseId: courseAId,
      academicYearId: academicYearAId,
      name: 'Semester 5',
      number: 5,
    });

    await Section.create({
      _id: sectionAId,
      collegeId: collegeAId,
      departmentId: deptAId,
      courseId: courseAId,
      semesterId: semesterAId,
      name: 'Section Alpha',
    });

    await Subject.create({
      _id: subjectAId,
      collegeId: collegeAId,
      departmentId: deptAId,
      courseId: courseAId,
      semesterId: semesterAId,
      name: 'Distributed Systems',
      code: 'CS501',
    });

    // Create Users
    await User.create([
      {
        _id: student1UserId,
        instituteId: 'P48_STU_1',
        collegeId: collegeAId,
        departmentId: deptAId,
        name: 'Aarav Sharma',
        email: 'aarav@ait.edu',
        phone: '+919876543210',
        role: AppRole.STUDENT,
        bio: 'Passionate about algorithms and cloud architecture.',
      },
      {
        _id: student2UserId,
        instituteId: 'P48_STU_2',
        collegeId: collegeAId,
        departmentId: deptAId,
        name: 'Bhavna Patel',
        email: 'bhavna@ait.edu',
        phone: '+919876543211',
        role: AppRole.STUDENT,
      },
      {
        _id: faculty1UserId,
        instituteId: 'P48_FAC_1',
        collegeId: collegeAId,
        departmentId: deptAId,
        name: 'Dr. Chetan Kumar',
        email: 'chetan@ait.edu',
        phone: '+919876543220',
        role: AppRole.FACULTY,
      },
      {
        _id: faculty2UserId,
        instituteId: 'P48_FAC_2',
        collegeId: collegeAId,
        departmentId: deptBId, // In Dept B
        name: 'Dr. Deepa Nair',
        email: 'deepa@ait.edu',
        phone: '+919876543221',
        role: AppRole.FACULTY,
      },
      {
        _id: hodAUserId,
        instituteId: 'P48_HOD_1',
        collegeId: collegeAId,
        departmentId: deptAId,
        name: 'Prof. Eswar Rao',
        email: 'eswar@ait.edu',
        phone: '+919876543230',
        role: AppRole.HOD,
      },
      {
        _id: adminAUserId,
        instituteId: 'P48_ADM_1',
        collegeId: collegeAId,
        name: 'Farhan Ali (Admin)',
        email: 'admin@ait.edu',
        phone: '+919876543240',
        role: AppRole.COLLEGE_ADMIN,
      },
      {
        _id: studentBUserId,
        instituteId: 'P48_STU_B',
        collegeId: collegeBId,
        name: 'Gaurav Sen',
        email: 'gaurav@bce.edu',
        phone: '+919876543250',
        role: AppRole.STUDENT,
      },
      {
        _id: superAdminUserId,
        instituteId: 'P48_SUPER',
        name: 'Root System Admin',
        email: 'super@acadex.edu',
        phone: '+919876543299',
        role: AppRole.SUPER_ADMIN,
      },
    ]);

    // Create Student Domain Profiles
    await Student.create([
      {
        _id: student1ProfileId,
        userId: student1UserId,
        instituteId: 'P48_STU_1',
        collegeId: collegeAId,
        departmentId: deptAId,
        name: 'Aarav Sharma',
        rollNumber: 'CS2025-001',
        admissionNumber: 'ADM-001',
        academicStage: 'Undergraduate',
        cohort: '2023-2027',
      },
      {
        _id: student2ProfileId,
        userId: student2UserId,
        instituteId: 'P48_STU_2',
        collegeId: collegeAId,
        departmentId: deptAId,
        name: 'Bhavna Patel',
        rollNumber: 'CS2025-002',
        admissionNumber: 'ADM-002',
        academicStage: 'Undergraduate',
        cohort: '2023-2027',
      },
    ]);

    // Create Active StudentEnrollment for Student 1
    await StudentEnrollment.create({
      collegeId: collegeAId,
      studentId: student1ProfileId,
      departmentId: deptAId,
      courseId: courseAId,
      academicYearId: academicYearAId,
      semesterId: semesterAId,
      sectionId: sectionAId,
      academicStage: 'Semester 5',
      cohort: '2023-2027',
      status: 'active',
    });

    // Create Faculty Profiles
    await Faculty.create([
      {
        _id: faculty1ProfileId,
        userId: faculty1UserId,
        instituteId: 'P48_FAC_1',
        collegeId: collegeAId,
        departmentId: deptAId,
        name: 'Dr. Chetan Kumar',
        employeeId: 'EMP-CS-101',
        email: 'chetan@ait.edu',
        designation: 'Associate Professor',
        qualification: 'Ph.D in Computer Science',
        specialization: 'Distributed Systems & Cloud Computing',
        joiningDate: new Date('2020-07-01'),
        status: 'active',
        isActive: true,
        subjectIds: [],
        sectionIds: [],
      },
      {
        _id: faculty2ProfileId,
        userId: faculty2UserId,
        instituteId: 'P48_FAC_2',
        collegeId: collegeAId,
        departmentId: deptBId,
        name: 'Dr. Deepa Nair',
        employeeId: 'EMP-ME-201',
        email: 'deepa@ait.edu',
        designation: 'Assistant Professor',
        qualification: 'M.Tech in Thermal Engineering',
        specialization: 'Thermodynamics',
        status: 'active',
        isActive: true,
        subjectIds: [],
        sectionIds: [],
      },
    ]);

    // Create Active Teaching Assignment for Faculty 1 in Section Alpha
    await FacultyAssignment.create([
      {
        collegeId: collegeAId,
        departmentId: deptAId,
        facultyId: faculty1ProfileId,
        facultyName: 'Dr. Chetan Kumar',
        courseId: courseAId,
        semesterId: semesterAId,
        sectionId: sectionAId,
        subjectId: subjectAId,
        academicYearId: academicYearAId,
        assignmentType: 'lecture',
        status: 'active',
        isActive: true,
      },
      {
        // An INACTIVE assignment to test filtering
        collegeId: collegeAId,
        departmentId: deptAId,
        facultyId: faculty1ProfileId,
        facultyName: 'Dr. Chetan Kumar',
        courseId: courseAId,
        semesterId: semesterAId,
        sectionId: sectionAId,
        subjectId: subjectAId,
        academicYearId: academicYearAId,
        assignmentType: 'lab',
        status: 'archived',
        isActive: false,
      },
    ]);

    authStudent1 = {
      id: student1UserId.toString(),
      role: AppRole.STUDENT,
      collegeId: collegeAId.toString(),
      departmentId: deptAId.toString(),
    } as any;

    authStudent2 = {
      id: student2UserId.toString(),
      role: AppRole.STUDENT,
      collegeId: collegeAId.toString(),
      departmentId: deptAId.toString(),
    } as any;

    authFaculty1 = {
      id: faculty1UserId.toString(),
      role: AppRole.FACULTY,
      collegeId: collegeAId.toString(),
      departmentId: deptAId.toString(),
    } as any;

    authFaculty2 = {
      id: faculty2UserId.toString(),
      role: AppRole.FACULTY,
      collegeId: collegeAId.toString(),
      departmentId: deptBId.toString(),
    } as any;

    authHodA = {
      id: hodAUserId.toString(),
      role: AppRole.HOD,
      collegeId: collegeAId.toString(),
      departmentId: deptAId.toString(),
    } as any;

    authAdminA = {
      id: adminAUserId.toString(),
      role: AppRole.COLLEGE_ADMIN,
      collegeId: collegeAId.toString(),
    } as any;

    authStudentB = {
      id: studentBUserId.toString(),
      role: AppRole.STUDENT,
      collegeId: collegeBId.toString(),
    } as any;

    authSuperAdmin = {
      id: superAdminUserId.toString(),
      role: AppRole.SUPER_ADMIN,
    } as any;
  });

  afterAll(async () => {
    realtimeEventBus.off('*', eventHandler);
    await mongoose.disconnect();
    await mongoServer.stop();
  });

  beforeEach(() => {
    capturedRealtimeEvents.length = 0;
  });

  describe('1. Profile Composition', () => {
    it('1.1 Student profile resolves User + Student + current StudentEnrollment', async () => {
      const profile = await ProfileService.getComposedProfile(student1UserId.toString(), authStudent1);

      expect(profile.user.name).toBe('Aarav Sharma');
      expect(profile.user.email).toBe('aarav@ait.edu');
      expect(profile.user.collegeName).toBe('Apex Institute of Technology');
      expect(profile.user.departmentName).toBe('Computer Science & Engineering');

      expect(profile.roleProfile.student).toBeDefined();
      expect(profile.roleProfile.student?.rollNumber).toBe('CS2025-001');
      expect(profile.roleProfile.student?.isEnrollmentAvailable).toBe(true);
      expect(profile.roleProfile.student?.currentEnrollment?.courseName).toBe('B.Tech CSE');
      expect(profile.roleProfile.student?.currentEnrollment?.semesterName).toBe('Semester 5');
      expect(profile.roleProfile.student?.currentEnrollment?.sectionName).toBe('Section Alpha');
    });

    it('1.2 Faculty profile resolves User + Faculty + active FacultyAssignments', async () => {
      const profile = await ProfileService.getComposedProfile(faculty1UserId.toString(), authFaculty1);

      expect(profile.user.name).toBe('Dr. Chetan Kumar');
      expect(profile.roleProfile.faculty).toBeDefined();
      expect(profile.roleProfile.faculty?.employeeId).toBe('EMP-CS-101');
      expect(profile.roleProfile.faculty?.designation).toBe('Associate Professor');
      expect(profile.roleProfile.faculty?.specialization).toBe('Distributed Systems & Cloud Computing');

      // Must have exactly 1 active assignment (inactive archived one was excluded)
      expect(profile.roleProfile.faculty?.activeAssignments).toHaveLength(1);
      expect(profile.roleProfile.faculty?.activeAssignments[0].subjectName).toBe('Distributed Systems');
      expect(profile.roleProfile.faculty?.activeAssignments[0].sectionName).toBe('Section Alpha');
    });

    it('1.3 HOD profile resolves department scope and management metrics', async () => {
      const profile = await ProfileService.getComposedProfile(hodAUserId.toString(), authHodA);

      expect(profile.user.name).toBe('Prof. Eswar Rao');
      expect(profile.roleProfile.hod).toBeDefined();
      expect(profile.roleProfile.hod?.departmentName).toBe('Computer Science & Engineering');
      expect(profile.roleProfile.hod?.managedScope.facultyCount).toBeGreaterThanOrEqual(1);
      expect(profile.roleProfile.hod?.managedScope.studentsCount).toBeGreaterThanOrEqual(2);
      expect(profile.roleProfile.hod?.managedScope.programsCount).toBeGreaterThanOrEqual(1);
    });

    it('1.4 Admin profile resolves tenant scope summary', async () => {
      const profile = await ProfileService.getComposedProfile(adminAUserId.toString(), authAdminA);

      expect(profile.user.name).toBe('Farhan Ali (Admin)');
      expect(profile.roleProfile.collegeAdmin).toBeDefined();
      expect(profile.roleProfile.collegeAdmin?.collegeName).toBe('Apex Institute of Technology');
      expect(profile.roleProfile.collegeAdmin?.administrativeScope.departmentsCount).toBe(2);
      expect(profile.roleProfile.collegeAdmin?.administrativeScope.facultyCount).toBe(2);
    });
  });

  describe('2. Security & Cross-Role Scoping', () => {
    it('2.1 Student cannot access another student private profile', async () => {
      await expect(
        ProfileService.getComposedProfile(student2UserId.toString(), authStudent1)
      ).rejects.toThrow('Students cannot access other student profiles');
    });

    it('2.2 Faculty cannot access student outside active teaching context', async () => {
      // Faculty 2 is in Dept B and does not teach Student 1
      await expect(
        ProfileService.getComposedProfile(student1UserId.toString(), authFaculty2)
      ).rejects.toThrow('Faculty access to student profiles is strictly limited to active teaching contexts');
    });

    it('2.3 Faculty CAN access student inside active teaching context', async () => {
      // Faculty 1 teaches Section Alpha which Student 1 is actively enrolled in
      const profile = await ProfileService.getComposedProfile(student1UserId.toString(), authFaculty1);
      expect(profile.user.name).toBe('Aarav Sharma');
      expect(profile.roleProfile.student?.rollNumber).toBe('CS2025-001');
    });

    it('2.4 HOD cannot access another department restricted profiles', async () => {
      // Faculty 2 is in Dept B, while HOD A is in Dept A
      await expect(
        ProfileService.getComposedProfile(faculty2UserId.toString(), authHodA)
      ).rejects.toThrow('HOD profile access is strictly scoped to their department');
    });

    it('2.5 College Admin cannot cross tenants (College B user accessed by College A admin)', async () => {
      await expect(
        ProfileService.getComposedProfile(studentBUserId.toString(), authAdminA)
      ).rejects.toThrow('Cross-college tenant profile access is strictly prohibited');
    });

    it('2.5.1 Student B can view their own profile in College B', async () => {
      const profile = await ProfileService.getComposedProfile(studentBUserId.toString(), authStudentB);
      expect(profile.user.name).toBe('Gaurav Sen');
      expect(profile.user.collegeName).toBe('Beacon College of Engineering');
    });

    it('2.6 Super Admin can view profiles across all colleges', async () => {
      const profileA = await ProfileService.getComposedProfile(student1UserId.toString(), authSuperAdmin);
      const profileB = await ProfileService.getComposedProfile(studentBUserId.toString(), authSuperAdmin);

      expect(profileA.user.name).toBe('Aarav Sharma');
      expect(profileB.user.name).toBe('Gaurav Sen');
    });
  });

  describe('3. Update Security & Protected Field Rejection', () => {
    it('3.1 User can update allowed personal fields (name, phone, bio)', async () => {
      const updated = await ProfileService.updateProfile(
        student1UserId.toString(),
        {
          name: 'Aarav Sharma Updated',
          phone: '+919999999999',
          bio: 'Updated bio with interest in distributed systems.',
        },
        authStudent1
      );

      expect(updated.user.name).toBe('Aarav Sharma Updated');
      expect(updated.user.phone).toBe('+919999999999');
      expect(updated.user.bio).toBe('Updated bio with interest in distributed systems.');

      // Verify synchronization to Student collection
      const studentDoc = await Student.findOne({ userId: student1UserId });
      expect(studentDoc?.name).toBe('Aarav Sharma Updated');
    });

    it('3.2 Rejects attempts to change role', async () => {
      await expect(
        ProfileService.updateProfile(
          student1UserId.toString(),
          { role: AppRole.FACULTY },
          authStudent1
        )
      ).rejects.toThrow(/Protected field 'role' cannot be modified/);
    });

    it('3.3 Rejects attempts to change collegeId', async () => {
      await expect(
        ProfileService.updateProfile(
          student1UserId.toString(),
          { collegeId: collegeBId.toString() },
          authStudent1
        )
      ).rejects.toThrow(/Protected field 'collegeId' cannot be modified/);
    });

    it('3.4 Rejects attempts to mutate academic enrollment context', async () => {
      await expect(
        ProfileService.updateProfile(
          student1UserId.toString(),
          { semesterId: semesterAId.toString() },
          authStudent1
        )
      ).rejects.toThrow(/Protected field 'semesterId' cannot be modified/);
    });

    it('3.5 Faculty cannot change FacultyAssignment fields via profile update', async () => {
      await expect(
        ProfileService.updateProfile(
          faculty1UserId.toString(),
          { assignments: [] },
          authFaculty1
        )
      ).rejects.toThrow(/Protected field 'assignments' cannot be modified/);
    });

    it('3.6 Rejects attempts to modify rollNumber or employeeId', async () => {
      await expect(
        ProfileService.updateProfile(
          student1UserId.toString(),
          { rollNumber: 'CS-HACKED' },
          authStudent1
        )
      ).rejects.toThrow(/Protected field 'rollNumber' cannot be modified/);

      await expect(
        ProfileService.updateProfile(
          faculty1UserId.toString(),
          { employeeId: 'EMP-HACKED' },
          authFaculty1
        )
      ).rejects.toThrow(/Protected field 'employeeId' cannot be modified/);
    });
  });

  describe('4. Student Academic Context & Enrollment Truth', () => {
    it('4.1 If student has no active enrollment, isEnrollmentAvailable is false', async () => {
      // Student 2 has no StudentEnrollment created in beforeAll
      const profile = await ProfileService.getComposedProfile(student2UserId.toString(), authStudent2);

      expect(profile.roleProfile.student?.isEnrollmentAvailable).toBe(false);
      expect(profile.roleProfile.student?.currentEnrollment).toBeNull();
    });

    it('4.2 Stale student pointers are not used as authoritative profile context', async () => {
      // Put a stale courseId on Student doc that differs from active StudentEnrollment
      const fakeCourseId = new Types.ObjectId();
      await Student.updateOne({ userId: student1UserId }, { $set: { courseId: fakeCourseId } });

      const profile = await ProfileService.getComposedProfile(student1UserId.toString(), authStudent1);

      // Current enrollment must still resolve to the real course from StudentEnrollment
      expect(profile.roleProfile.student?.currentEnrollment?.courseName).toBe('B.Tech CSE');
      expect(profile.roleProfile.student?.currentEnrollment?.courseId).toBe(courseAId.toString());
    });
  });

  describe('5. Avatar Validation & Security', () => {
    it('5.1 Avatar upload auth requires valid image MIME type', async () => {
      await expect(
        ProfileService.requestAvatarUploadAuth(
          student1UserId.toString(),
          { fileName: 'malicious.pdf', mimeType: 'application/pdf', fileSize: 1024 },
          authStudent1
        )
      ).rejects.toThrow('Only JPEG, PNG, and WebP images are allowed');
    });

    it('5.2 Rejects oversized avatar file (> 5MB)', async () => {
      await expect(
        ProfileService.requestAvatarUploadAuth(
          student1UserId.toString(),
          { fileName: 'huge.png', mimeType: 'image/png', fileSize: 10 * 1024 * 1024 },
          authStudent1
        )
      ).rejects.toThrow(/File size exceeds maximum limit/);
    });

    it('5.3 User B cannot request avatar upload for User A', async () => {
      await expect(
        ProfileService.requestAvatarUploadAuth(
          student1UserId.toString(),
          { fileName: 'avatar.png', mimeType: 'image/png', fileSize: 1024 },
          authStudent2
        )
      ).rejects.toThrow('You are not authorized to upload an avatar for this profile');
    });
  });

  describe('6. Audit & Realtime Event Guarantees', () => {
    it('6.1 Meaningful profile mutation creates an audit log entry', async () => {
      await ProfileService.updateProfile(
        student1UserId.toString(),
        { name: 'Aarav Audited' },
        authStudent1
      );

      const log = await AuditLog.findOne({
        actorUserId: student1UserId.toString(),
        action: 'PROFILE_UPDATED',
      }).sort({ timestamp: -1 });

      expect(log).not.toBeNull();
      expect(log?.entityType).toBe('UserProfile');
      expect(log?.newValue?.name).toBe('Aarav Audited');
    });

    it('6.2 Profile update emits realtime event with minimal metadata', async () => {
      await ProfileService.updateProfile(
        student1UserId.toString(),
        { bio: 'New realtime bio' },
        authStudent1
      );

      expect(capturedRealtimeEvents.length).toBeGreaterThan(0);
      const updateEvent = capturedRealtimeEvents.find(
        (e) => e.payload?.userId === student1UserId.toString() || e.userId === student1UserId.toString()
      );
      expect(updateEvent).toBeDefined();
      const payload = updateEvent.payload || updateEvent;
      expect(payload.role).toBe(AppRole.STUDENT);
    });
  });

  describe('7. Scoped Directory Discovery', () => {
    it('7.1 Student directory only exposes Faculty (not other students)', async () => {
      const directory = await ProfileService.getDirectory({}, authStudent1);

      expect(directory.items.length).toBeGreaterThan(0);
      // All items returned must have role FACULTY
      for (const item of directory.items) {
        expect(item.role).toBe(AppRole.FACULTY);
      }
    });

    it('7.2 College Admin directory sees all users within college tenant', async () => {
      const directory = await ProfileService.getDirectory({}, authAdminA);

      expect(directory.total).toBeGreaterThanOrEqual(6);
      const names = directory.items.map((i) => i.name);
      expect(names).toContain('Aarav Audited');
      expect(names).toContain('Dr. Chetan Kumar');
      // Must NOT contain College B student
      expect(names).not.toContain('Gaurav Sen');
    });
  });
});
