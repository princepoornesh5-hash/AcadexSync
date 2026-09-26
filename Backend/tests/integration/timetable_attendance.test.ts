import { TimetableService } from '../../src/services/timetable.service';
import { AttendanceService } from '../../src/services/attendance.service';
import { TimetableDay, TimetableSessionType, TimetableBreakType, AttendanceStatus, TimetableStatus } from '../../src/constants/status';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import mongoose from 'mongoose';
import { Student } from '../../src/models/student.model';
import { StudentEnrollment } from '../../src/models/studentEnrollment.model';

describe('Timetable & Attendance Integration Tests', () => {
  const collegeId = new mongoose.Types.ObjectId().toString();
  const departmentId = new mongoose.Types.ObjectId().toString();
  const courseId = new mongoose.Types.ObjectId().toString();
  const academicYearId = new mongoose.Types.ObjectId().toString();
  const semesterId = new mongoose.Types.ObjectId().toString();
  const sectionId = new mongoose.Types.ObjectId().toString();
  const subjectId = new mongoose.Types.ObjectId().toString();
  const facultyId = new mongoose.Types.ObjectId().toString();
  const studentId = new mongoose.Types.ObjectId().toString();

  beforeAll(async () => {
    await setupTestDB();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();
  });

  it('should create and publish timetable with periods, breaks, and merged entries', async () => {
    const timetable = await TimetableService.createTimetable(collegeId, {
      departmentId: new mongoose.Types.ObjectId(departmentId),
      courseId: new mongoose.Types.ObjectId(courseId),
      academicYearId: new mongoose.Types.ObjectId(academicYearId),
      semesterId: new mongoose.Types.ObjectId(semesterId),
      sectionId: new mongoose.Types.ObjectId(sectionId),
      name: 'Fall 2026 CS-A Timetable',
      activeDays: [
        TimetableDay.MONDAY,
        TimetableDay.TUESDAY,
        TimetableDay.WEDNESDAY,
        TimetableDay.THURSDAY,
        TimetableDay.FRIDAY,
      ],
      periods: [
        { index: 1, name: 'Period 1', startTime: '09:00', endTime: '10:00' },
        { index: 2, name: 'Period 2', startTime: '10:00', endTime: '11:00' },
        { index: 3, name: 'Period 3', startTime: '11:15', endTime: '12:15' },
      ],
      breaks: [
        {
          name: 'Tea Break',
          startTime: '10:00',
          endTime: '10:15',
          appliesToDays: [TimetableDay.MONDAY, TimetableDay.TUESDAY],
          isVerticalSpan: true,
          breakType: TimetableBreakType.TEA,
        },
      ],
      entries: [
        {
          dayOfWeek: TimetableDay.MONDAY,
          startPeriodIndex: 1,
          periodSpan: 2,
          startTime: '09:00',
          endTime: '11:00',
          subjectId: new mongoose.Types.ObjectId(subjectId),
          facultyId: new mongoose.Types.ObjectId(facultyId),
          roomNumber: 'Lab 301',
          sessionType: TimetableSessionType.LAB,
        },
      ],
    });

    expect(timetable.name).toBe('Fall 2026 CS-A Timetable');
    expect(timetable.status).toBe(TimetableStatus.DRAFT);
    expect(timetable.periods).toHaveLength(3);
    expect(timetable.breaks).toHaveLength(1);
    expect(timetable.entries).toHaveLength(1);
    expect(timetable.entries[0].periodSpan).toBe(2);

    // Publish timetable
    const published = await TimetableService.publishTimetable(
      timetable.id,
      'faculty_author_123',
      collegeId
    );
    expect(published.status).toBe(TimetableStatus.PUBLISHED);
    expect(published.publishedAt).toBeDefined();
    expect(published.publishedBy).toBe('faculty_author_123');
  });

  it('should submit attendance session and compute accurate student summary', async () => {
    // 0. Seed Student & Enrollment
    await Student.create({
      _id: new mongoose.Types.ObjectId(studentId),
      userId: new mongoose.Types.ObjectId(),
      collegeId: new mongoose.Types.ObjectId(collegeId),
      departmentId: new mongoose.Types.ObjectId(departmentId),
      courseId: new mongoose.Types.ObjectId(courseId),
      academicYearId: new mongoose.Types.ObjectId(academicYearId),
      semesterId: new mongoose.Types.ObjectId(semesterId),
      sectionId: new mongoose.Types.ObjectId(sectionId),
      instituteId: 'CS-042',
      rollNumber: 'CS-042',
      name: 'Bob Dylan',
      status: 'active',
    });

    await StudentEnrollment.create({
      collegeId: new mongoose.Types.ObjectId(collegeId),
      departmentId: new mongoose.Types.ObjectId(departmentId),
      courseId: new mongoose.Types.ObjectId(courseId),
      academicYearId: new mongoose.Types.ObjectId(academicYearId),
      semesterId: new mongoose.Types.ObjectId(semesterId),
      sectionId: new mongoose.Types.ObjectId(sectionId),
      studentId: new mongoose.Types.ObjectId(studentId),
      status: 'active',
    });

    // 1. Submit Session 1 (Present)
    await AttendanceService.createOrSubmitSession(
      collegeId,
      {
        departmentId: new mongoose.Types.ObjectId(departmentId),
        facultyId: new mongoose.Types.ObjectId(facultyId),
        subjectId: new mongoose.Types.ObjectId(subjectId),
        subjectName: 'Operating Systems',
        sectionId: new mongoose.Types.ObjectId(sectionId),
        sectionName: 'Section A',
        timeSlot: '09:00 - 10:00',
        date: new Date('2026-08-10'),
        records: [
          {
            studentId: new mongoose.Types.ObjectId(studentId),
            studentName: 'Bob Dylan',
            rollNumber: 'CS-042',
            sectionId: new mongoose.Types.ObjectId(sectionId),
            status: AttendanceStatus.PRESENT,
          },
        ],
      },
      'faculty_123'
    );

    // 2. Submit Session 2 (Late -> counts towards attendance)
    await AttendanceService.createOrSubmitSession(
      collegeId,
      {
        departmentId: new mongoose.Types.ObjectId(departmentId),
        facultyId: new mongoose.Types.ObjectId(facultyId),
        subjectId: new mongoose.Types.ObjectId(subjectId),
        subjectName: 'Operating Systems',
        sectionId: new mongoose.Types.ObjectId(sectionId),
        sectionName: 'Section A',
        timeSlot: '10:00 - 11:00',
        date: new Date('2026-08-11'),
        records: [
          {
            studentId: new mongoose.Types.ObjectId(studentId),
            studentName: 'Bob Dylan',
            rollNumber: 'CS-042',
            sectionId: new mongoose.Types.ObjectId(sectionId),
            status: AttendanceStatus.LATE,
          },
        ],
      },
      'faculty_123'
    );

    // 3. Submit Session 3 (Absent)
    await AttendanceService.createOrSubmitSession(
      collegeId,
      {
        departmentId: new mongoose.Types.ObjectId(departmentId),
        facultyId: new mongoose.Types.ObjectId(facultyId),
        subjectId: new mongoose.Types.ObjectId(subjectId),
        subjectName: 'Operating Systems',
        sectionId: new mongoose.Types.ObjectId(sectionId),
        sectionName: 'Section A',
        timeSlot: '11:00 - 12:00',
        date: new Date('2026-08-12'),
        records: [
          {
            studentId: new mongoose.Types.ObjectId(studentId),
            studentName: 'Bob Dylan',
            rollNumber: 'CS-042',
            sectionId: new mongoose.Types.ObjectId(sectionId),
            status: AttendanceStatus.ABSENT,
          },
        ],
      },
      'faculty_123'
    );

    // 4. Calculate Summary for Student
    const summary = await AttendanceService.getStudentAttendanceSummary(collegeId, studentId);
    expect(summary.totalClasses).toBe(3);
    expect(summary.presentCount).toBe(1);
    expect(summary.lateCount).toBe(1);
    expect(summary.absentCount).toBe(1);
    // (1 + 1) / 3 * 100 = 66.67%
    expect(summary.percentage).toBeCloseTo(66.67, 1);
  });
});
