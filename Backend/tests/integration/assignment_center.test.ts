import request from 'supertest';
import { app } from '../../src/app';
import { College } from '../../src/models/college.model';
import { Department } from '../../src/models/department.model';
import { Course } from '../../src/models/course.model';
import { AcademicYear } from '../../src/models/academicYear.model';
import { Semester } from '../../src/models/semester.model';
import { Section } from '../../src/models/section.model';
import { Subject } from '../../src/models/subject.model';
import { User } from '../../src/models/user.model';
import { Student } from '../../src/models/student.model';
import { FacultyAssignment } from '../../src/models/facultyAssignment.model';
import { StudentEnrollment } from '../../src/models/studentEnrollment.model';
import { Assignment } from '../../src/models/assignment.model';
import { AssignmentSubmission } from '../../src/models/assignmentSubmission.model';
import { Notification } from '../../src/models/notification.model';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';
import { AppRole } from '../../src/constants/roles';
import {
  AssignmentStatus,
  FacultyReviewStatus,
  StudentTaskStatus,
} from '../../src/constants/assignment.constants';
import { NotificationType } from '../../src/constants/notification.constants';

describe('Assignment Center Core Integration Tests', () => {
  let collegeA: InstanceType<typeof College>;
  let collegeB: InstanceType<typeof College>;
  let deptCSE: InstanceType<typeof Department>;
  let courseCS: InstanceType<typeof Course>;
  let acadYear: InstanceType<typeof AcademicYear>;
  let semester1: InstanceType<typeof Semester>;
  let sectionA: InstanceType<typeof Section>;
  let sectionB: InstanceType<typeof Section>;
  let subjectDS: InstanceType<typeof Subject>;

  let facultyAUser: InstanceType<typeof User>;
  let facultyBUser: InstanceType<typeof User>;
  let student1User: InstanceType<typeof User>;
  let student2User: InstanceType<typeof User>;
  let student1Doc: InstanceType<typeof Student>;
  let student2Doc: InstanceType<typeof Student>;
  let facultyAssignmentA: InstanceType<typeof FacultyAssignment>;

  beforeAll(async () => {
    await setupTestDB();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();

    // 1. Colleges
    collegeA = await College.create({
      name: 'College of Engineering A',
      code: 'COE-A',
      email: 'admin@coea.edu',
      address: '123 Campus Road',
      phone: '+1-555-0101',
      principal: 'Dr. Principal A',
    });

    collegeB = await College.create({
      name: 'College of Tech B',
      code: 'COT-B',
      email: 'admin@cotb.edu',
      address: '456 Campus Road',
      phone: '+1-555-0102',
      principal: 'Dr. Principal B',
    });

    // 2. Department & Academic hierarchy
    deptCSE = await Department.create({
      collegeId: collegeA._id,
      name: 'Computer Science & Engineering',
      code: 'CSE',
    });

    courseCS = await Course.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      name: 'B.Tech Computer Science',
      code: 'BT-CS',
    });

    acadYear = await AcademicYear.create({
      collegeId: collegeA._id,
      name: '2026-2027',
      startDate: new Date('2026-08-01'),
      endDate: new Date('2027-05-31'),
    });

    semester1 = await Semester.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      courseId: courseCS._id,
      academicYearId: acadYear._id,
      name: 'Semester 1',
      number: 1,
    });

    sectionA = await Section.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      courseId: courseCS._id,
      academicYearId: acadYear._id,
      semesterId: semester1._id,
      name: 'CSE-A',
      capacity: 60,
    });

    sectionB = await Section.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      courseId: courseCS._id,
      academicYearId: acadYear._id,
      semesterId: semester1._id,
      name: 'CSE-B',
      capacity: 60,
    });

    subjectDS = await Subject.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      courseId: courseCS._id,
      semesterId: semester1._id,
      name: 'Data Structures',
      code: 'CS201',
      credits: 4,
    });

    // 3. Faculty Users
    facultyAUser = await User.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      instituteId: 'FAC-001',
      name: 'Prof. Donald Knuth',
      email: 'knuth@coea.edu',
      role: AppRole.FACULTY,
      status: 'active',
    });

    facultyBUser = await User.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      instituteId: 'FAC-002',
      name: 'Prof. Barbara Liskov',
      email: 'liskov@coea.edu',
      role: AppRole.FACULTY,
      status: 'active',
    });

    // 4. Teaching Assignment: Faculty A teaches Data Structures to CSE-A
    facultyAssignmentA = await FacultyAssignment.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      facultyId: facultyAUser._id,
      facultyName: facultyAUser.name,
      courseId: courseCS._id,
      semesterId: semester1._id,
      sectionId: sectionA._id,
      subjectId: subjectDS._id,
      academicYearId: acadYear._id,
      isActive: true,
    });

    // 5. Students & Enrollments
    student1User = await User.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      instituteId: 'STU-001',
      name: 'Ravi Kumar',
      email: 'ravi@coea.edu',
      role: AppRole.STUDENT,
      status: 'active',
    });

    student1Doc = await Student.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      userId: student1User._id,
      name: student1User.name,
      rollNumber: 'CS-01',
      instituteId: student1User.instituteId,
      status: 'active',
      isActive: true,
    });

    await StudentEnrollment.create({
      collegeId: collegeA._id,
      studentId: student1Doc._id,
      departmentId: deptCSE._id,
      courseId: courseCS._id,
      academicYearId: acadYear._id,
      semesterId: semester1._id,
      sectionId: sectionA._id,
      status: 'active',
    });

    student2User = await User.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      instituteId: 'STU-002',
      name: 'Priya Sharma',
      email: 'priya@coea.edu',
      role: AppRole.STUDENT,
      status: 'active',
    });

    student2Doc = await Student.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      userId: student2User._id,
      name: student2User.name,
      rollNumber: 'CS-02',
      instituteId: student2User.instituteId,
      status: 'active',
    });

    await StudentEnrollment.create({
      collegeId: collegeA._id,
      studentId: student2Doc._id,
      departmentId: deptCSE._id,
      courseId: courseCS._id,
      academicYearId: acadYear._id,
      semesterId: semester1._id,
      sectionId: sectionA._id,
      status: 'active',
    });
  });

  // 1. Faculty can create assignment for authorized teaching context
  it('1. Faculty can create assignment for authorized teaching context', async () => {
    const auth = createTestAuthHeader({
      userId: facultyAUser._id.toString(),
      collegeId: collegeA._id.toString(),
      role: AppRole.FACULTY,
    });

    const res = await request(app)
      .post('/api/v1/assignments')
      .set(auth)
      .send({
        facultyAssignmentId: facultyAssignmentA._id.toString(),
        title: 'Linked List Problems',
        description: 'Complete singly and doubly linked list problems.',
        questions: ['Q1: Reverse a linked list.', 'Q2: Detect a cycle.'],
        dueDate: '2026-09-30',
        dueTime: '11:59 PM',
        maximumMarks: 10,
        assignmentType: 'Homework',
        status: 'DRAFT',
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.title).toBe('Linked List Problems');
    expect(res.body.data.maximumMarks).toBe(10);
    expect(res.body.data.status).toBe(AssignmentStatus.DRAFT);
    expect(res.body.data.sectionId).toBe(sectionA._id.toString());
  });

  // 2. Unauthorized Faculty cannot create assignment for another context
  it('2. Unauthorized Faculty cannot create assignment for another context', async () => {
    const auth = createTestAuthHeader({
      userId: facultyBUser._id.toString(),
      collegeId: collegeA._id.toString(),
      role: AppRole.FACULTY,
    });

    const res = await request(app)
      .post('/api/v1/assignments')
      .set(auth)
      .send({
        facultyAssignmentId: facultyAssignmentA._id.toString(),
        title: 'Unauthorized Assignment',
        description: 'Trying to post for Faculty A class',
        dueDate: '2026-09-30',
        dueTime: '11:59 PM',
        maximumMarks: 10,
      });

    expect(res.status).toBe(403);
    expect(res.body.success).toBe(false);
  });

  // 3 & 5. Published assignment resolves correct enrolled student audience & is visible
  it('3 & 5. Published assignment resolves correct enrolled student audience and is visible', async () => {
    // Create and publish assignment
    const authFaculty = createTestAuthHeader({
      userId: facultyAUser._id.toString(),
      collegeId: collegeA._id.toString(),
      role: AppRole.FACULTY,
    });

    const createRes = await request(app)
      .post('/api/v1/assignments')
      .set(authFaculty)
      .send({
        facultyAssignmentId: facultyAssignmentA._id.toString(),
        title: 'Binary Tree Traversal',
        description: 'Implement inorder, preorder, and postorder traversals.',
        dueDate: '2026-10-15',
        dueTime: '11:59 PM',
        maximumMarks: 15,
        status: 'PUBLISHED',
      });

    expect(createRes.status).toBe(201);
    const assignmentId = createRes.body.data.id;

    // Student 1 (Enrolled in CSE-A) queries /api/v1/assignments/my
    const authStudent = createTestAuthHeader({
      userId: student1User._id.toString(),
      collegeId: collegeA._id.toString(),
      role: AppRole.STUDENT,
    });

    const studentRes = await request(app)
      .get('/api/v1/assignments/my')
      .set(authStudent);

    expect(studentRes.status).toBe(200);
    expect(studentRes.body.data.length).toBe(1);
    expect(studentRes.body.data[0].id).toBe(assignmentId);
    expect(studentRes.body.data[0].studentStatus).toBe(StudentTaskStatus.PENDING);
  });

  // 4. Draft assignment is invisible to students
  it('4. Draft assignment is invisible to students', async () => {
    const authFaculty = createTestAuthHeader({
      userId: facultyAUser._id.toString(),
      collegeId: collegeA._id.toString(),
      role: AppRole.FACULTY,
    });

    await request(app)
      .post('/api/v1/assignments')
      .set(authFaculty)
      .send({
        facultyAssignmentId: facultyAssignmentA._id.toString(),
        title: 'Draft Quiz 1',
        description: 'Not published yet',
        dueDate: '2026-10-15',
        dueTime: '11:59 PM',
        maximumMarks: 10,
        status: 'DRAFT',
      });

    const authStudent = createTestAuthHeader({
      userId: student1User._id.toString(),
      collegeId: collegeA._id.toString(),
      role: AppRole.STUDENT,
    });

    const studentRes = await request(app)
      .get('/api/v1/assignments/my')
      .set(authStudent);

    expect(studentRes.status).toBe(200);
    expect(studentRes.body.data.length).toBe(0);
  });

  // 6. Student can mark own assignment Done
  it('6. Student can mark own assignment Done', async () => {
    const asgn = await Assignment.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      courseId: courseCS._id,
      academicYearId: acadYear._id,
      semesterId: semester1._id,
      sectionId: sectionA._id,
      subjectId: subjectDS._id,
      facultyId: facultyAUser._id,
      facultyAssignmentId: facultyAssignmentA._id,
      facultyName: facultyAUser.name,
      title: 'Graph Algorithms',
      description: 'Implement BFS and DFS',
      dueDate: '2026-10-20',
      dueTime: '11:59 PM',
      dueDateTime: new Date('2026-10-20T23:59:00.000Z'),
      maximumMarks: 20,
      status: AssignmentStatus.PUBLISHED,
      publishedAt: new Date(),
    });

    const authStudent = createTestAuthHeader({
      userId: student1User._id.toString(),
      collegeId: collegeA._id.toString(),
      role: AppRole.STUDENT,
    });

    const completeRes = await request(app)
      .post(`/api/v1/assignments/${asgn._id}/complete`)
      .set(authStudent);

    expect(completeRes.status).toBe(200);
    expect(completeRes.body.data.status).toBe(StudentTaskStatus.COMPLETED);
    expect(completeRes.body.data.completedAt).toBeDefined();
    expect(completeRes.body.data.reviewStatus).toBe(FacultyReviewStatus.NOT_REVIEWED);
    expect(completeRes.body.data.marks).toBeNull();
  });

  // 7. Student cannot mark another student's assignment Done
  it("7. Student cannot mark another student's assignment Done", async () => {
    // Student in Section B (not enrolled in Section A)
    const outsiderStudentUser = await User.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      instituteId: 'STU-OUTSIDER',
      name: 'Outsider Student',
      email: 'outsider@coea.edu',
      role: AppRole.STUDENT,
      status: 'active',
    });

    const outsiderStudentDoc = await Student.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      userId: outsiderStudentUser._id,
      name: outsiderStudentUser.name,
      instituteId: outsiderStudentUser.instituteId,
      status: 'active',
      isActive: true,
    });

    await StudentEnrollment.create({
      collegeId: collegeA._id,
      studentId: outsiderStudentDoc._id,
      departmentId: deptCSE._id,
      courseId: courseCS._id,
      academicYearId: acadYear._id,
      semesterId: semester1._id,
      sectionId: sectionB._id, // Enrolled in Section B, not A!
      status: 'active',
    });

    const asgn = await Assignment.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      courseId: courseCS._id,
      academicYearId: acadYear._id,
      semesterId: semester1._id,
      sectionId: sectionA._id,
      subjectId: subjectDS._id,
      facultyId: facultyAUser._id,
      facultyAssignmentId: facultyAssignmentA._id,
      facultyName: facultyAUser.name,
      title: 'Section A Only Task',
      description: 'Only for Section A',
      dueDate: '2026-10-20',
      dueTime: '11:59 PM',
      dueDateTime: new Date('2026-10-20T23:59:00.000Z'),
      maximumMarks: 10,
      status: AssignmentStatus.PUBLISHED,
      publishedAt: new Date(),
    });

    const authOutsider = createTestAuthHeader({
      userId: outsiderStudentUser._id.toString(),
      collegeId: collegeA._id.toString(),
      role: AppRole.STUDENT,
    });

    const res = await request(app)
      .post(`/api/v1/assignments/${asgn._id}/complete`)
      .set(authOutsider);

    expect(res.status).toBe(403);
    const msg = res.body.error?.message || res.body.message || '';
    expect(msg).toContain('not enrolled in the section');
  });

  // 8. Student cannot modify marks
  it('8. Student cannot modify marks', async () => {
    const asgn = await Assignment.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      courseId: courseCS._id,
      academicYearId: acadYear._id,
      semesterId: semester1._id,
      sectionId: sectionA._id,
      subjectId: subjectDS._id,
      facultyId: facultyAUser._id,
      facultyAssignmentId: facultyAssignmentA._id,
      facultyName: facultyAUser.name,
      title: 'Grading Test Task',
      description: 'Test',
      dueDate: '2026-10-20',
      dueTime: '11:59 PM',
      dueDateTime: new Date('2026-10-20T23:59:00.000Z'),
      maximumMarks: 10,
      status: AssignmentStatus.PUBLISHED,
      publishedAt: new Date(),
    });

    const authStudent = createTestAuthHeader({
      userId: student1User._id.toString(),
      collegeId: collegeA._id.toString(),
      role: AppRole.STUDENT,
    });

    const res = await request(app)
      .patch(`/api/v1/assignments/${asgn._id}/marks`)
      .set(authStudent)
      .send({
        marks: [{ studentId: student1Doc._id.toString(), marks: 10 }],
      });

    // Students are not the assigned faculty for this assignment
    expect(res.status).toBe(403);
  });

  // 9. Faculty can retrieve activity for own assignment
  it('9. Faculty can retrieve activity for own assignment', async () => {
    const asgn = await Assignment.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      courseId: courseCS._id,
      academicYearId: acadYear._id,
      semesterId: semester1._id,
      sectionId: sectionA._id,
      subjectId: subjectDS._id,
      facultyId: facultyAUser._id,
      facultyAssignmentId: facultyAssignmentA._id,
      facultyName: facultyAUser.name,
      title: 'Activity Test Task',
      description: 'Check activity',
      dueDate: '2026-10-20',
      dueTime: '11:59 PM',
      dueDateTime: new Date('2026-10-20T23:59:00.000Z'),
      maximumMarks: 10,
      status: AssignmentStatus.PUBLISHED,
      publishedAt: new Date(),
    });

    // Student 1 marks completed
    await AssignmentSubmission.create({
      collegeId: collegeA._id,
      assignmentId: asgn._id,
      studentId: student1Doc._id,
      studentUserId: student1User._id,
      studentName: student1User.name,
      status: StudentTaskStatus.COMPLETED,
      completedAt: new Date(),
      reviewStatus: FacultyReviewStatus.NOT_REVIEWED,
    });

    const authFaculty = createTestAuthHeader({
      userId: facultyAUser._id.toString(),
      collegeId: collegeA._id.toString(),
      role: AppRole.FACULTY,
    });

    const res = await request(app)
      .get(`/api/v1/assignments/${asgn._id}/activity`)
      .set(authFaculty);

    expect(res.status).toBe(200);
    expect(res.body.data.summary.totalStudents).toBe(2);
    expect(res.body.data.summary.completedCount).toBe(1);
    expect(res.body.data.summary.pendingCount).toBe(1);
    expect(res.body.data.completed.length).toBe(1);
    expect(res.body.data.pending.length).toBe(1);
  });

  // 10. Faculty can save marks for completed students
  it('10. Faculty can save marks for completed students', async () => {
    const asgn = await Assignment.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      courseId: courseCS._id,
      academicYearId: acadYear._id,
      semesterId: semester1._id,
      sectionId: sectionA._id,
      subjectId: subjectDS._id,
      facultyId: facultyAUser._id,
      facultyAssignmentId: facultyAssignmentA._id,
      facultyName: facultyAUser.name,
      title: 'Marks Saving Task',
      description: 'Check marks save',
      dueDate: '2026-10-20',
      dueTime: '11:59 PM',
      dueDateTime: new Date('2026-10-20T23:59:00.000Z'),
      maximumMarks: 10,
      status: AssignmentStatus.PUBLISHED,
      publishedAt: new Date(),
    });

    await AssignmentSubmission.create({
      collegeId: collegeA._id,
      assignmentId: asgn._id,
      studentId: student1Doc._id,
      studentUserId: student1User._id,
      studentName: student1User.name,
      status: StudentTaskStatus.COMPLETED,
      completedAt: new Date(),
      reviewStatus: FacultyReviewStatus.NOT_REVIEWED,
    });

    const authFaculty = createTestAuthHeader({
      userId: facultyAUser._id.toString(),
      collegeId: collegeA._id.toString(),
      role: AppRole.FACULTY,
    });

    const res = await request(app)
      .patch(`/api/v1/assignments/${asgn._id}/marks`)
      .set(authFaculty)
      .send({
        marks: [{ studentId: student1Doc._id.toString(), marks: 8 }],
      });

    expect(res.status).toBe(200);
    expect(res.body.data.summary.reviewedCount).toBe(1);
    expect(res.body.data.summary.averageMarks).toBe(8);

    const sub = await AssignmentSubmission.findOne({
      assignmentId: asgn._id,
      studentId: student1Doc._id,
    });
    expect(sub?.marks).toBe(8);
    expect(sub?.reviewStatus).toBe(FacultyReviewStatus.REVIEWED);
  });

  // 11. Marks cannot exceed maximum marks
  it('11. Marks cannot exceed maximum marks', async () => {
    const asgn = await Assignment.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      courseId: courseCS._id,
      academicYearId: acadYear._id,
      semesterId: semester1._id,
      sectionId: sectionA._id,
      subjectId: subjectDS._id,
      facultyId: facultyAUser._id,
      facultyAssignmentId: facultyAssignmentA._id,
      facultyName: facultyAUser.name,
      title: 'Max Marks Limit Task',
      description: 'Check limit',
      dueDate: '2026-10-20',
      dueTime: '11:59 PM',
      dueDateTime: new Date('2026-10-20T23:59:00.000Z'),
      maximumMarks: 10,
      status: AssignmentStatus.PUBLISHED,
      publishedAt: new Date(),
    });

    const authFaculty = createTestAuthHeader({
      userId: facultyAUser._id.toString(),
      collegeId: collegeA._id.toString(),
      role: AppRole.FACULTY,
    });

    const res = await request(app)
      .patch(`/api/v1/assignments/${asgn._id}/marks`)
      .set(authFaculty)
      .send({
        marks: [{ studentId: student1Doc._id.toString(), marks: 15 }], // 15 > 10!
      });

    expect(res.status).toBe(400);
    const msg = res.body.error?.message || res.body.message || '';
    expect(msg).toContain('cannot exceed maximum marks');
  });

  // 12. Negative marks are rejected
  it('12. Negative marks are rejected', async () => {
    const asgn = await Assignment.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      courseId: courseCS._id,
      academicYearId: acadYear._id,
      semesterId: semester1._id,
      sectionId: sectionA._id,
      subjectId: subjectDS._id,
      facultyId: facultyAUser._id,
      facultyAssignmentId: facultyAssignmentA._id,
      facultyName: facultyAUser.name,
      title: 'Negative Marks Task',
      description: 'Check negative',
      dueDate: '2026-10-20',
      dueTime: '11:59 PM',
      dueDateTime: new Date('2026-10-20T23:59:00.000Z'),
      maximumMarks: 10,
      status: AssignmentStatus.PUBLISHED,
      publishedAt: new Date(),
    });

    const authFaculty = createTestAuthHeader({
      userId: facultyAUser._id.toString(),
      collegeId: collegeA._id.toString(),
      role: AppRole.FACULTY,
    });

    const res = await request(app)
      .patch(`/api/v1/assignments/${asgn._id}/marks`)
      .set(authFaculty)
      .send({
        marks: [{ studentId: student1Doc._id.toString(), marks: -2 }],
      });

    // 400 or 422 validation failure
    expect([400, 422]).toContain(res.status);
  });

  // 13. Duplicate completion cannot create duplicate activity
  it('13. Duplicate completion cannot create duplicate activity', async () => {
    const asgn = await Assignment.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      courseId: courseCS._id,
      academicYearId: acadYear._id,
      semesterId: semester1._id,
      sectionId: sectionA._id,
      subjectId: subjectDS._id,
      facultyId: facultyAUser._id,
      facultyAssignmentId: facultyAssignmentA._id,
      facultyName: facultyAUser.name,
      title: 'Idempotent Complete Task',
      description: 'Check duplicate complete',
      dueDate: '2026-10-20',
      dueTime: '11:59 PM',
      dueDateTime: new Date('2026-10-20T23:59:00.000Z'),
      maximumMarks: 10,
      status: AssignmentStatus.PUBLISHED,
      publishedAt: new Date(),
    });

    const authStudent = createTestAuthHeader({
      userId: student1User._id.toString(),
      collegeId: collegeA._id.toString(),
      role: AppRole.STUDENT,
    });

    // Complete once
    await request(app)
      .post(`/api/v1/assignments/${asgn._id}/complete`)
      .set(authStudent);

    // Complete second time
    const secondRes = await request(app)
      .post(`/api/v1/assignments/${asgn._id}/complete`)
      .set(authStudent);

    expect(secondRes.status).toBe(200);

    const submissionCount = await AssignmentSubmission.countDocuments({
      assignmentId: asgn._id,
      studentId: student1Doc._id,
    });
    expect(submissionCount).toBe(1);
  });

  // 14. Duplicate publish does not create duplicate assignment
  it('14. Duplicate publish does not create duplicate assignment', async () => {
    const authFaculty = createTestAuthHeader({
      userId: facultyAUser._id.toString(),
      collegeId: collegeA._id.toString(),
      role: AppRole.FACULTY,
    });

    const payload = {
      facultyAssignmentId: facultyAssignmentA._id.toString(),
      title: 'Concurrent Publish Problem',
      description: 'Test deduplication',
      dueDate: '2026-10-25',
      dueTime: '11:59 PM',
      maximumMarks: 10,
      status: 'PUBLISHED',
    };

    // First publish
    const res1 = await request(app).post('/api/v1/assignments').set(authFaculty).send(payload);
    // Rapid immediate second publish with same payload
    const res2 = await request(app).post('/api/v1/assignments').set(authFaculty).send(payload);

    expect(res1.status).toBe(201);
    expect(res2.status).toBe(201);
    expect(res1.body.data.id).toBe(res2.body.data.id);

    const total = await Assignment.countDocuments({
      collegeId: collegeA._id,
      title: 'Concurrent Publish Problem',
    });
    expect(total).toBe(1);
  });

  // 15. Assignment tenant isolation is enforced
  it('15. Assignment tenant isolation is enforced', async () => {
    // Assignment created in College A
    const asgnA = await Assignment.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      courseId: courseCS._id,
      academicYearId: acadYear._id,
      semesterId: semester1._id,
      sectionId: sectionA._id,
      subjectId: subjectDS._id,
      facultyId: facultyAUser._id,
      facultyAssignmentId: facultyAssignmentA._id,
      facultyName: facultyAUser.name,
      title: 'College A Only Assignment',
      description: 'Confidential to College A',
      dueDate: '2026-10-20',
      dueTime: '11:59 PM',
      dueDateTime: new Date('2026-10-20T23:59:00.000Z'),
      maximumMarks: 10,
      status: AssignmentStatus.PUBLISHED,
      publishedAt: new Date(),
    });

    // College B user attempts to retrieve Assignment A
    const collegeBUser = await User.create({
      collegeId: collegeB._id,
      instituteId: 'COL-B-USER',
      name: 'College B Faculty',
      email: 'user@cotb.edu',
      role: AppRole.FACULTY,
      status: 'active',
    });

    const authCollegeB = createTestAuthHeader({
      userId: collegeBUser._id.toString(),
      collegeId: collegeB._id.toString(),
      role: AppRole.FACULTY,
    });

    const res = await request(app)
      .get(`/api/v1/assignments/${asgnA._id}`)
      .set(authCollegeB);

    // Cross-tenant access is rejected with 404
    expect(res.status).toBe(404);
  });

  // 16. Assignment lifecycle transitions are validated
  it('16. Assignment lifecycle transitions are validated', async () => {
    const authFaculty = createTestAuthHeader({
      userId: facultyAUser._id.toString(),
      collegeId: collegeA._id.toString(),
      role: AppRole.FACULTY,
    });

    const draft = await Assignment.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      courseId: courseCS._id,
      academicYearId: acadYear._id,
      semesterId: semester1._id,
      sectionId: sectionA._id,
      subjectId: subjectDS._id,
      facultyId: facultyAUser._id,
      facultyAssignmentId: facultyAssignmentA._id,
      facultyName: facultyAUser.name,
      title: 'Lifecycle State Machine',
      description: 'Draft -> Published -> Closed',
      dueDate: '2026-10-20',
      dueTime: '11:59 PM',
      dueDateTime: new Date('2026-10-20T23:59:00.000Z'),
      maximumMarks: 10,
      status: AssignmentStatus.DRAFT,
    });

    // 1. Publish
    const pubRes = await request(app)
      .post(`/api/v1/assignments/${draft._id}/publish`)
      .set(authFaculty);
    expect(pubRes.status).toBe(200);
    expect(pubRes.body.data.status).toBe(AssignmentStatus.PUBLISHED);

    // 2. Close
    const closeRes = await request(app)
      .post(`/api/v1/assignments/${draft._id}/close`)
      .set(authFaculty);
    expect(closeRes.status).toBe(200);
    expect(closeRes.body.data.status).toBe(AssignmentStatus.CLOSED);

    // 3. Cannot re-publish closed assignment
    const rePubRes = await request(app)
      .post(`/api/v1/assignments/${draft._id}/publish`)
      .set(authFaculty);
    expect(rePubRes.status).toBe(400);
  });

  // 17. Assignment notification event is emitted once/idempotently
  it('17. Assignment notification event is emitted once and creates persistent notifications for students', async () => {
    const authFaculty = createTestAuthHeader({
      userId: facultyAUser._id.toString(),
      collegeId: collegeA._id.toString(),
      role: AppRole.FACULTY,
    });

    await request(app)
      .post('/api/v1/assignments')
      .set(authFaculty)
      .send({
        facultyAssignmentId: facultyAssignmentA._id.toString(),
        title: 'Heaps & Priority Queues',
        description: 'Complete questions',
        dueDate: '2026-10-30',
        dueTime: '11:59 PM',
        maximumMarks: 10,
        status: 'PUBLISHED',
      });

    // Wait 100ms for async notifications to insert
    await new Promise((r) => setTimeout(r, 150));

    // Both enrolled students in Section A should receive a notification
    const student1Notifs = await Notification.find({
      recipientUserId: student1User._id,
      notificationType: NotificationType.ASSIGNMENT_PUBLISHED,
    });
    expect(student1Notifs.length).toBe(1);
    expect(student1Notifs[0].title).toBe('New Assignment');
    expect(student1Notifs[0].body).toContain('Heaps & Priority Queues');

    const student2Notifs = await Notification.find({
      recipientUserId: student2User._id,
      notificationType: NotificationType.ASSIGNMENT_PUBLISHED,
    });
    expect(student2Notifs.length).toBe(1);
  });

  // 18. Completed student is excluded from pending reminder eligibility
  it('18. Completed student is excluded from pending reminder eligibility in Activity', async () => {
    const asgn = await Assignment.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      courseId: courseCS._id,
      academicYearId: acadYear._id,
      semesterId: semester1._id,
      sectionId: sectionA._id,
      subjectId: subjectDS._id,
      facultyId: facultyAUser._id,
      facultyAssignmentId: facultyAssignmentA._id,
      facultyName: facultyAUser.name,
      title: 'Reminder Filter Task',
      description: 'Completed student must not be pending',
      dueDate: '2026-10-20',
      dueTime: '11:59 PM',
      dueDateTime: new Date('2026-10-20T23:59:00.000Z'),
      maximumMarks: 10,
      status: AssignmentStatus.PUBLISHED,
      publishedAt: new Date(),
    });

    // Student 1 completed
    await AssignmentSubmission.create({
      collegeId: collegeA._id,
      assignmentId: asgn._id,
      studentId: student1Doc._id,
      studentUserId: student1User._id,
      studentName: student1User.name,
      status: StudentTaskStatus.COMPLETED,
      completedAt: new Date(),
    });

    const authFaculty = createTestAuthHeader({
      userId: facultyAUser._id.toString(),
      collegeId: collegeA._id.toString(),
      role: AppRole.FACULTY,
    });

    const res = await request(app)
      .get(`/api/v1/assignments/${asgn._id}/activity`)
      .set(authFaculty);

    expect(res.status).toBe(200);
    // Student 1 is in completed list, NOT pending
    const completedStudentIds = res.body.data.completed.map((c: any) => c.studentId);
    const pendingStudentIds = res.body.data.pending.map((p: any) => p.studentId);

    expect(completedStudentIds).toContain(student1Doc._id.toString());
    expect(pendingStudentIds).not.toContain(student1Doc._id.toString());
    expect(pendingStudentIds).toContain(student2Doc._id.toString());
  });

  // 19. Overdue state is calculated correctly
  it('19. Overdue state is calculated correctly when deadline has passed', async () => {
    // Past deadline
    const pastDate = new Date(Date.now() - 3600000 * 24); // 1 day ago
    const asgn = await Assignment.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      courseId: courseCS._id,
      academicYearId: acadYear._id,
      semesterId: semester1._id,
      sectionId: sectionA._id,
      subjectId: subjectDS._id,
      facultyId: facultyAUser._id,
      facultyAssignmentId: facultyAssignmentA._id,
      facultyName: facultyAUser.name,
      title: 'Expired Assignment',
      description: 'Past due',
      dueDate: '2026-09-01',
      dueTime: '11:59 PM',
      dueDateTime: pastDate,
      maximumMarks: 10,
      status: AssignmentStatus.PUBLISHED,
      publishedAt: new Date('2026-08-25'),
    });

    // Student 2 has not submitted
    const authFaculty = createTestAuthHeader({
      userId: facultyAUser._id.toString(),
      collegeId: collegeA._id.toString(),
      role: AppRole.FACULTY,
    });

    const res = await request(app)
      .get(`/api/v1/assignments/${asgn._id}/activity`)
      .set(authFaculty);

    expect(res.status).toBe(200);
    expect(res.body.data.summary.overdueCount).toBe(2); // Both students overdue
    expect(res.body.data.pending[0].status).toBe(StudentTaskStatus.OVERDUE);
  });
});
