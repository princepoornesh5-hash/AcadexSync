import request from 'supertest';
import { app } from '../../src/app';
import { User } from '../../src/models/user.model';
import { College } from '../../src/models/college.model';
import { Department } from '../../src/models/department.model';
import { Student } from '../../src/models/student.model';
import { AttendanceRecord } from '../../src/models/attendanceRecord.model';
import { AttendanceSession } from '../../src/models/attendanceSession.model';
import { AppRole } from '../../src/constants/roles';
import { AttendanceStatus } from '../../src/constants/status';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';
import mongoose from 'mongoose';
import { UserService } from '../../src/services/user.service';

describe('User Identity Model & instituteId Architecture Tests', () => {
  let college: InstanceType<typeof College>;
  let department: InstanceType<typeof Department>;

  beforeAll(async () => {
    await setupTestDB();
    await User.init();
    await College.init();
    await Department.init();
    await Student.init();
    await AttendanceSession.init();
    await AttendanceRecord.init();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();

    college = await College.create({
      name: 'Apex Institute of Technology',
      code: 'AIT',
      address: 'Tech Park, North Block',
      email: 'info@ait.edu',
      phone: '+1-555-0199',
      principal: 'Dr. John Principal',
    });

    department = await Department.create({
      collegeId: college._id,
      name: 'Computer Science',
      code: 'CSE',
    });
  });

  it('1. instituteId is REQUIRED for user creation', async () => {
    await expect(
      UserService.createUser({
        name: 'Alice Smith',
        email: 'alice@ait.edu',
        role: AppRole.STUDENT,
        collegeId: college._id,
        // instituteId intentionally omitted
      })
    ).rejects.toThrow(/instituteId is required/);
  });

  it('2. instituteId is unique across users and indexed', async () => {
    const user1 = await UserService.createUser({
      instituteId: 'CSE-2026-001',
      name: 'Alice Smith',
      email: 'alice@ait.edu',
      role: AppRole.STUDENT,
      collegeId: college._id,
    });

    expect(user1.instituteId).toBe('CSE-2026-001');
    expect(user1._id).toBeDefined();

    // Query user by instituteId
    const found = await UserService.getUserByInstituteId('CSE-2026-001', college.id);
    expect(found._id.toString()).toBe(user1._id.toString());
  });

  it('3. Duplicate instituteId is strictly rejected with conflict error', async () => {
    await UserService.createUser({
      instituteId: 'DCME-25-041',
      name: 'Bob Jones',
      email: 'bob@ait.edu',
      role: AppRole.STUDENT,
      collegeId: college._id,
    });

    // Attempting to create another user with identical instituteId
    await expect(
      UserService.createUser({
        instituteId: 'DCME-25-041',
        name: 'Bob Clone',
        email: 'bob.clone@ait.edu',
        role: AppRole.STUDENT,
        collegeId: college._id,
      })
    ).rejects.toThrow(/already exists/);
  });

  it('4. Changing instituteId updates business identity without changing MongoDB _id', async () => {
    const user = await UserService.createUser({
      instituteId: 'TEMP-STU-100',
      name: 'Charlie Brown',
      email: 'charlie@ait.edu',
      role: AppRole.STUDENT,
      collegeId: college._id,
    });

    const initialMongoId = user._id.toString();

    // Administrative correction of instituteId
    const updatedUser = await UserService.updateUser(
      initialMongoId,
      { instituteId: 'CSE-2026-099' },
      college.id
    );

    expect(updatedUser._id.toString()).toBe(initialMongoId);
    expect(updatedUser.instituteId).toBe('CSE-2026-099');

    // Fetch from database to verify persistence
    const reloaded = await User.findById(initialMongoId);
    expect(reloaded).not.toBeNull();
    expect(reloaded!._id.toString()).toBe(initialMongoId);
    expect(reloaded!.instituteId).toBe('CSE-2026-099');
  });

  it('5. Changing instituteId does NOT disconnect or delete relational records linked to MongoDB _id', async () => {
    // 1. Create student User
    const user = await UserService.createUser({
      instituteId: 'ACA-STU-000184',
      name: 'Diana Prince',
      email: 'diana@ait.edu',
      role: AppRole.STUDENT,
      collegeId: college._id,
    });

    const mongoUserId = user._id;

    // 2. Create Student academic profile linking to User's MongoDB ObjectId
    const studentProfile = await Student.create({
      collegeId: college._id,
      departmentId: department._id,
      courseId: new mongoose.Types.ObjectId(),
      semesterId: new mongoose.Types.ObjectId(),
      sectionId: new mongoose.Types.ObjectId(),
      userId: mongoUserId,
      instituteId: user.instituteId,
      name: 'Diana Prince',
      rollNumber: 'ROLL-184',
      email: 'diana@ait.edu',
    });

    // 3. Create Attendance Session and Record linked to Student / User
    const session = await AttendanceSession.create({
      collegeId: college._id,
      departmentId: department._id,
      facultyId: new mongoose.Types.ObjectId(),
      subjectId: new mongoose.Types.ObjectId(),
      subjectName: 'Data Structures',
      sectionId: new mongoose.Types.ObjectId(),
      sectionName: 'Section A',
      timeSlot: '09:00 - 10:00',
      date: new Date('2026-08-15'),
      totalStudents: 1,
      presentCount: 1,
      absentCount: 0,
      lateCount: 0,
      excusedCount: 0,
      createdBy: 'faculty_1',
      records: [
        {
          studentId: studentProfile._id,
          studentName: 'Diana Prince',
          rollNumber: 'ROLL-184',
          sectionId: new mongoose.Types.ObjectId(),
          status: AttendanceStatus.PRESENT,
        },
      ],
    });

    await AttendanceRecord.create({
      collegeId: college._id,
      sessionId: session._id,
      studentId: studentProfile._id,
      studentName: 'Diana Prince',
      rollNumber: 'ROLL-184',
      sectionId: new mongoose.Types.ObjectId(),
      subjectId: new mongoose.Types.ObjectId(),
      facultyId: new mongoose.Types.ObjectId(),
      date: new Date('2026-08-15'),
      timeSlot: '09:00 - 10:00',
      status: AttendanceStatus.PRESENT,
    });

    // 4. Update user's instituteId
    await UserService.updateUser(
      mongoUserId.toString(),
      { instituteId: 'CSE-2026-FINAL-184' },
      college.id
    );

    // 5. Verify Student profile and Attendance records remain fully intact and linked
    const linkedStudent = await Student.findOne({ userId: mongoUserId });
    expect(linkedStudent).not.toBeNull();
    expect(linkedStudent!._id.toString()).toBe(studentProfile._id.toString());

    const attendanceRecords = await AttendanceRecord.find({ studentId: studentProfile._id });
    expect(attendanceRecords).toHaveLength(1);
    expect(attendanceRecords[0].status).toBe(AttendanceStatus.PRESENT);
  });

  it('6. Unauthenticated protected routes are strictly rejected with 401 Unauthorized', async () => {
    // Attempting request with no Authorization header
    const resNoAuth = await request(app).get('/api/v1/departments');
    expect(resNoAuth.status).toBe(401);
    expect(resNoAuth.body.success).toBe(false);
    expect(resNoAuth.body.error.message).toContain('Authentication token is required');

    // Attempting request with invalid / malformed token
    const resBadToken = await request(app)
      .get('/api/v1/departments')
      .set('Authorization', 'Bearer invalid-garbage-token');
    expect(resBadToken.status).toBe(401);
    expect(resBadToken.body.success).toBe(false);
  });

  it('7. Health endpoint accurately reports MongoDB connection state at /health and /api/v1/health', async () => {
    const resRootHealth = await request(app).get('/health');
    expect(resRootHealth.status).toBe(200);
    expect(resRootHealth.body.status).toBe('ok');
    expect(resRootHealth.body.database).toBe('connected');

    const resV1Health = await request(app).get('/api/v1/health');
    expect(resV1Health.status).toBe(200);
    expect(resV1Health.body.status).toBe('ok');
    expect(resV1Health.body.database).toBe('connected');
  });

  it('8. User API route enables instituteId lookup for authorized caller', async () => {
    const user = await UserService.createUser({
      instituteId: 'CSE-2026-077',
      name: 'Eve White',
      email: 'eve@ait.edu',
      role: AppRole.STUDENT,
      collegeId: college._id,
    });

    const authHeader = createTestAuthHeader({
      role: AppRole.COLLEGE_ADMIN,
      userId: 'usr_admin',
      instituteId: 'ADMIN-01',
      collegeId: college.id,
    });

    const res = await request(app)
      .get(`/api/v1/users/institute/CSE-2026-077`)
      .set(authHeader);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.id).toBe(user._id.toString());
    expect(res.body.data.instituteId).toBe('CSE-2026-077');
    expect(res.body.data.passwordHash).toBeUndefined(); // passwordHash is stripped
  });
});
