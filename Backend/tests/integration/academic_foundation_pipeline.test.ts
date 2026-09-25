import request from 'supertest';
import { app } from '../../src/app';
import { College } from '../../src/models/college.model';
import { Department } from '../../src/models/department.model';
import { Course } from '../../src/models/course.model';
import { AcademicYear } from '../../src/models/academicYear.model';
import { Semester } from '../../src/models/semester.model';
import { Section } from '../../src/models/section.model';
import { Room } from '../../src/models/room.model';
import { Timetable } from '../../src/models/timetable.model';
import { User } from '../../src/models/user.model';
import { AppRole } from '../../src/constants/roles';
import { AccountStatus, TimetableStatus, TimetableDay } from '../../src/constants/status';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';

describe('Academic Foundation Pipeline & HOD Room Provisioning (Prompt 14)', () => {
  let college: any;
  let department: any;
  let hodUser: any;
  let hodHeader: { Authorization: string };

  beforeAll(async () => {
    await setupTestDB();
    await College.init();
    await Department.init();
    await Course.init();
    await AcademicYear.init();
    await Semester.init();
    await Section.init();
    await Room.init();
    await Timetable.init();
    await User.init();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();

    college = await College.create({
      name: 'Pinnacle Institute of Technology',
      code: 'PIT',
      address: 'Tech Avenue',
      email: 'admin@pit.edu',
      phone: '9876543210',
      principal: 'Dr. Principal',
    });

    department = await Department.create({
      collegeId: college._id,
      name: 'Computer Engineering',
      code: 'CSE',
    });

    hodUser = await User.create({
      collegeId: college._id,
      departmentId: department._id,
      name: 'Prof. Alan Turing',
      email: 'hod.cse@pit.edu',
      passwordHash: 'dummyHash123',
      role: AppRole.HOD,
      accountStatus: AccountStatus.ACTIVE,
    });

    hodHeader = createTestAuthHeader({
      userId: hodUser.id,
      role: AppRole.HOD,
      collegeId: college.id,
      departmentId: department.id,
    });
  });

  it('1. Allows HOD to create and retrieve rooms for their department', async () => {
    const createRes = await request(app)
      .post('/api/v1/timetables/rooms')
      .set(hodHeader)
      .send({
        name: 'Lab 201 Computer Lab',
        code: 'L201',
        capacity: 45,
        type: 'LAB',
        departmentId: department.id,
      });

    expect(createRes.status).toBe(201);
    expect(createRes.body.success).toBe(true);
    expect(createRes.body.data.name).toBe('Lab 201 Computer Lab');
    expect(createRes.body.data.departmentId.toString()).toBe(department.id.toString());

    const getRes = await request(app)
      .get(`/api/v1/timetables/rooms?departmentId=${department.id}`)
      .set(hodHeader);

    expect(getRes.status).toBe(200);
    expect(getRes.body.success).toBe(true);
    const rooms = getRes.body.data.items || getRes.body.data;
    expect(Array.isArray(rooms)).toBe(true);
    expect(rooms.some((r: any) => r.code === 'L201')).toBe(true);
  });

  it('2. Enforces academic foundation integrity: blocks publish if prerequisite elements are missing', async () => {
    const course = await Course.create({
      collegeId: college._id,
      departmentId: department._id,
      name: 'B.Tech CSE',
      code: 'BTCSE',
      duration: 4,
    });

    const academicYear = await AcademicYear.create({
      collegeId: college._id,
      name: '2026-2027',
      startDate: new Date('2026-06-01'),
      endDate: new Date('2027-05-31'),
      isActive: true,
    });

    const semester = await Semester.create({
      collegeId: college._id,
      departmentId: department._id,
      courseId: course._id,
      academicYearId: academicYear._id,
      name: 'Semester 1',
      number: 1,
      startDate: new Date('2026-06-01'),
      endDate: new Date('2026-11-30'),
      isActive: true,
    });

    const section = await Section.create({
      collegeId: college._id,
      departmentId: department._id,
      courseId: course._id,
      semesterId: semester._id,
      academicYearId: academicYear._id,
      name: 'A',
      capacity: 60,
      isActive: true,
    });

    const timetable = await Timetable.create({
      collegeId: college._id,
      departmentId: department._id,
      courseId: course._id,
      academicYearId: academicYear._id,
      semesterId: semester._id,
      sectionId: section._id,
      name: 'BTCSE Sem 1 Sec A Timetable',
      activeDays: [
        TimetableDay.MONDAY,
        TimetableDay.TUESDAY,
        TimetableDay.WEDNESDAY,
        TimetableDay.THURSDAY,
        TimetableDay.FRIDAY,
      ],
      status: TimetableStatus.DRAFT,
      entries: [
        {
          id: 'slot_1',
          dayOfWeek: TimetableDay.MONDAY,
          startTime: '09:00',
          endTime: '10:00',
          subjectId: '507f1f77bcf86cd799439011',
          facultyId: hodUser.id,
          facultyAssignmentId: '507f1f77bcf86cd799439012',
          roomNumber: 'L201',
          periodNumber: 1,
        },
      ],
    });

    const publishRes = await request(app)
      .post(`/api/v1/timetables/${timetable.id}/publish`)
      .set(hodHeader);

    // Must be rejected because prerequisites (valid subject, assignment) do not exist
    expect([400, 422]).toContain(publishRes.status);
    expect(publishRes.body.success).toBe(false);
  });
});
