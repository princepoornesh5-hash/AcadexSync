import request from 'supertest';
import mongoose from 'mongoose';
import { app } from '../../src/app';
import { College } from '../../src/models/college.model';
import { Department } from '../../src/models/department.model';
import { FacultyAssignment } from '../../src/models/facultyAssignment.model';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';
import { AppRole } from '../../src/constants/roles';
import { RequestStatus } from '../../src/constants/request.constants';

describe('Request Center Core Integration Tests', () => {
  let collegeA: InstanceType<typeof College>;
  let collegeB: InstanceType<typeof College>;
  let deptCSE: InstanceType<typeof Department>;

  const studentUserId = 'usr_student_101';
  const otherStudentUserId = 'usr_student_102';
  const facultyUserId = 'usr_faculty_201';
  const hodUserId = 'usr_hod_301';
  const collegeAdminUserId = 'usr_admin_401';
  const collegeBAdminUserId = 'usr_admin_b_402';

  beforeAll(async () => {
    await setupTestDB();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();

    collegeA = await College.create({
      name: 'College of Engineering A',
      code: 'COE-A',
      email: 'admin@coea.edu',
      address: '123 Campus Road, City A',
      phone: '+1-555-0101',
      principal: 'Dr. Principal A',
    });

    collegeB = await College.create({
      name: 'Institute of Tech B',
      code: 'IOT-B',
      email: 'admin@iotb.edu',
      address: '456 Tech Ave, City B',
      phone: '+1-555-0202',
      principal: 'Dr. Principal B',
    });

    deptCSE = await Department.create({
      collegeId: collegeA._id,
      name: 'Computer Science & Engineering',
      code: 'CSE',
      hodId: hodUserId,
    });
  });

  // 1 & 2: Student creates Leave Request -> routes to HOD
  it('1 & 2: Student can create valid Leave Request and it routes to HOD', async () => {
    const studentHeader = createTestAuthHeader({
      userId: studentUserId,
      name: 'Ravi Kumar',
      role: AppRole.STUDENT,
      collegeId: collegeA.id,
      departmentId: deptCSE.id,
    });

    const res = await request(app)
      .post('/api/v1/requests')
      .set(studentHeader)
      .send({
        requestType: 'LEAVE',
        description: 'Need leave for 2 days due to fever',
        details: {
          startDate: new Date('2026-10-01').toISOString(),
          endDate: new Date('2026-10-02').toISOString(),
          reason: 'Medical fever',
        },
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.requesterRole).toBe('STUDENT');
    expect(res.body.data.targetRole).toBe('HOD');
    expect(res.body.data.targetUserId).toBe(hodUserId);
    expect(res.body.data.status).toBe(RequestStatus.SUBMITTED);
    expect(res.body.data.history).toHaveLength(1);
  });

  // 3: Student sees only own requests
  it('3: Student sees only own requests', async () => {
    const studentHeader1 = createTestAuthHeader({
      userId: studentUserId,
      role: AppRole.STUDENT,
      collegeId: collegeA.id,
      departmentId: deptCSE.id,
    });

    const studentHeader2 = createTestAuthHeader({
      userId: otherStudentUserId,
      role: AppRole.STUDENT,
      collegeId: collegeA.id,
      departmentId: deptCSE.id,
    });

    // Student 1 submits request
    await request(app)
      .post('/api/v1/requests')
      .set(studentHeader1)
      .send({
        requestType: 'LEAVE',
        description: 'Student 1 leave',
      });

    // Student 2 submits request
    await request(app)
      .post('/api/v1/requests')
      .set(studentHeader2)
      .send({
        requestType: 'LEAVE',
        description: 'Student 2 leave',
      });

    // Student 1 lists requests
    const res = await request(app)
      .get('/api/v1/requests/my')
      .set(studentHeader1);

    expect(res.status).toBe(200);
    expect(res.body.data.items).toHaveLength(1);
    expect(res.body.data.items[0].description).toBe('Student 1 leave');
  });

  // 4 & 5: Faculty can create Leave Request to HOD and receives only authorized incoming
  it('4 & 5: Faculty creates Leave Request to HOD and receives authorized incoming', async () => {
    const facultyHeader = createTestAuthHeader({
      userId: facultyUserId,
      name: 'Prof. Sharma',
      role: AppRole.FACULTY,
      collegeId: collegeA.id,
      departmentId: deptCSE.id,
    });

    // Faculty creates leave request
    const createRes = await request(app)
      .post('/api/v1/requests')
      .set(facultyHeader)
      .send({
        requestType: 'LEAVE',
        description: 'Attending IEEE conference',
      });

    expect(createRes.status).toBe(201);
    expect(createRes.body.data.targetRole).toBe('HOD');
    expect(createRes.body.data.targetUserId).toBe(hodUserId);

    // Faculty checks incoming (should have 0 since no student request was routed to them yet)
    const incomingRes = await request(app)
      .get('/api/v1/requests/incoming')
      .set(facultyHeader);

    expect(incomingRes.status).toBe(200);
    expect(incomingRes.body.data.items).toHaveLength(0);
  });

  // 6: HOD creates request to College Admin
  it('6: HOD can create request to College Admin', async () => {
    const hodHeader = createTestAuthHeader({
      userId: hodUserId,
      name: 'Dr. HOD CSE',
      role: AppRole.HOD,
      collegeId: collegeA.id,
      departmentId: deptCSE.id,
    });

    const res = await request(app)
      .post('/api/v1/requests')
      .set(hodHeader)
      .send({
        requestType: 'FACULTY_REQUIREMENT',
        title: 'Need 2 Assistant Professors',
        description: 'Increased intake in CSE department',
      });

    expect(res.status).toBe(201);
    expect(res.body.data.targetRole).toBe('COLLEGE_ADMIN');
  });

  // 7: HOD receives and handles department requests
  it('7: HOD receives and handles department requests', async () => {
    const studentHeader = createTestAuthHeader({
      userId: studentUserId,
      name: 'Ravi',
      role: AppRole.STUDENT,
      collegeId: collegeA.id,
      departmentId: deptCSE.id,
    });

    const createRes = await request(app)
      .post('/api/v1/requests')
      .set(studentHeader)
      .send({
        requestType: 'LEAVE',
        description: 'Family function leave',
      });

    const requestId = createRes.body.data.id;

    const hodHeader = createTestAuthHeader({
      userId: hodUserId,
      name: 'Dr. HOD CSE',
      role: AppRole.HOD,
      collegeId: collegeA.id,
      departmentId: deptCSE.id,
    });

    // HOD lists incoming
    const incomingRes = await request(app)
      .get('/api/v1/requests/incoming')
      .set(hodHeader);

    expect(incomingRes.status).toBe(200);
    expect(incomingRes.body.data.items.length).toBeGreaterThanOrEqual(1);

    // HOD views detail -> status transitions to RECEIVED
    const viewRes = await request(app)
      .get(`/api/v1/requests/${requestId}`)
      .set(hodHeader);

    expect(viewRes.status).toBe(200);
    expect(viewRes.body.data.status).toBe(RequestStatus.RECEIVED);

    // HOD responds with APPROVED
    const respondRes = await request(app)
      .post(`/api/v1/requests/${requestId}/respond`)
      .set(hodHeader)
      .send({
        action: 'APPROVED',
        message: 'Leave approved. Please catch up on notes.',
      });

    expect(respondRes.status).toBe(200);
    expect(respondRes.body.data.status).toBe(RequestStatus.APPROVED);
    expect(respondRes.body.data.responseMessage).toBe('Leave approved. Please catch up on notes.');
  });

  // 8: Unauthorized user cannot view another user's request
  it("8: Unauthorized user cannot view another user's request", async () => {
    const studentHeader1 = createTestAuthHeader({
      userId: studentUserId,
      role: AppRole.STUDENT,
      collegeId: collegeA.id,
      departmentId: deptCSE.id,
    });

    const createRes = await request(app)
      .post('/api/v1/requests')
      .set(studentHeader1)
      .send({
        requestType: 'COMPLAINT_ISSUE',
        description: 'Private complaint about lab equipment',
      });

    const reqId = createRes.body.data.id;

    // Another student tries to view it
    const studentHeader2 = createTestAuthHeader({
      userId: otherStudentUserId,
      role: AppRole.STUDENT,
      collegeId: collegeA.id,
      departmentId: deptCSE.id,
    });

    const viewRes = await request(app)
      .get(`/api/v1/requests/${reqId}`)
      .set(studentHeader2);

    expect(viewRes.status).toBe(403);
    expect(viewRes.body.success).toBe(false);
  });

  // 9: Unauthorized user cannot mutate request status
  it('9: Requester cannot approve or reject their own request', async () => {
    const studentHeader = createTestAuthHeader({
      userId: studentUserId,
      role: AppRole.STUDENT,
      collegeId: collegeA.id,
      departmentId: deptCSE.id,
    });

    const createRes = await request(app)
      .post('/api/v1/requests')
      .set(studentHeader)
      .send({
        requestType: 'LEAVE',
        description: 'Self approving leave?',
      });

    const reqId = createRes.body.data.id;

    // Student attempts to approve own request
    const mutateRes = await request(app)
      .post(`/api/v1/requests/${reqId}/respond`)
      .set(studentHeader)
      .send({
        action: 'APPROVED',
        message: 'I approve myself',
      });

    expect(mutateRes.status).toBe(403);
    expect(mutateRes.body.success).toBe(false);
  });

  // 10 & 11: Valid status transitions succeed, invalid transitions rejected
  it('10 & 11: Valid status transitions succeed and invalid transitions rejected', async () => {
    const studentHeader = createTestAuthHeader({
      userId: studentUserId,
      role: AppRole.STUDENT,
      collegeId: collegeA.id,
      departmentId: deptCSE.id,
    });

    const createRes = await request(app)
      .post('/api/v1/requests')
      .set(studentHeader)
      .send({
        requestType: 'DOCUMENT_REQUEST',
        description: 'Need bonafide certificate',
      });

    const reqId = createRes.body.data.id;

    const adminHeader = createTestAuthHeader({
      userId: collegeAdminUserId,
      role: AppRole.COLLEGE_ADMIN,
      collegeId: collegeA.id,
    });

    // Valid: Mark IN_REVIEW
    const inReviewRes = await request(app)
      .patch(`/api/v1/requests/${reqId}/status`)
      .set(adminHeader)
      .send({ status: 'IN_REVIEW', note: 'Processing with office' });

    expect(inReviewRes.status).toBe(200);
    expect(inReviewRes.body.data.status).toBe('IN_REVIEW');

    // Valid: RESOLVED
    const resolveRes = await request(app)
      .post(`/api/v1/requests/${reqId}/respond`)
      .set(adminHeader)
      .send({ action: 'RESOLVED', message: 'Certificate is ready for pickup at office counter.' });

    expect(resolveRes.status).toBe(200);
    expect(resolveRes.body.data.status).toBe('RESOLVED');

    // Invalid: Transition from RESOLVED back to IN_REVIEW is rejected
    const invalidRes = await request(app)
      .patch(`/api/v1/requests/${reqId}/status`)
      .set(adminHeader)
      .send({ status: 'IN_REVIEW' });

    expect(invalidRes.status).toBe(400);

    // Valid: Requester or responder can close resolved request
    const closeRes = await request(app)
      .patch(`/api/v1/requests/${reqId}/status`)
      .set(studentHeader)
      .send({ status: 'CLOSED' });

    expect(closeRes.status).toBe(200);
    expect(closeRes.body.data.status).toBe('CLOSED');

    // Mutating a closed request is rejected with 409 conflict
    const postCloseRes = await request(app)
      .post(`/api/v1/requests/${reqId}/respond`)
      .set(adminHeader)
      .send({ action: 'APPROVED' });

    expect(postCloseRes.status).toBe(409);
  });

  // 12: Request response is persisted
  it('12: Request response details and history are persisted', async () => {
    const studentHeader = createTestAuthHeader({
      userId: studentUserId,
      name: 'Ravi',
      role: AppRole.STUDENT,
      collegeId: collegeA.id,
      departmentId: deptCSE.id,
    });

    const createRes = await request(app)
      .post('/api/v1/requests')
      .set(studentHeader)
      .send({
        requestType: 'LEAVE',
        description: 'Leave request for verification',
      });

    const reqId = createRes.body.data.id;

    const hodHeader = createTestAuthHeader({
      userId: hodUserId,
      name: 'Dr. HOD CSE',
      role: AppRole.HOD,
      collegeId: collegeA.id,
      departmentId: deptCSE.id,
    });

    await request(app)
      .post(`/api/v1/requests/${reqId}/respond`)
      .set(hodHeader)
      .send({
        action: 'APPROVED',
        message: 'Leave approved for 28 September.',
      });

    const verifyRes = await request(app)
      .get(`/api/v1/requests/${reqId}`)
      .set(studentHeader);

    expect(verifyRes.status).toBe(200);
    expect(verifyRes.body.data.respondedByName).toBe('Dr. HOD CSE');
    expect(verifyRes.body.data.responseMessage).toBe('Leave approved for 28 September.');
    expect(verifyRes.body.data.history.length).toBeGreaterThanOrEqual(2);
  });

  // 13: Duplicate submission is prevented
  it('13: Repeated submission within 30 seconds is rejected', async () => {
    const studentHeader = createTestAuthHeader({
      userId: studentUserId,
      role: AppRole.STUDENT,
      collegeId: collegeA.id,
      departmentId: deptCSE.id,
    });

    const res1 = await request(app)
      .post('/api/v1/requests')
      .set(studentHeader)
      .send({
        requestType: 'GENERAL_REQUEST',
        description: 'Repeated query',
      });

    expect(res1.status).toBe(201);

    const res2 = await request(app)
      .post('/api/v1/requests')
      .set(studentHeader)
      .send({
        requestType: 'GENERAL_REQUEST',
        description: 'Repeated query',
      });

    expect(res2.status).toBe(409);
    expect(res2.body.error.message).toContain('A similar request was recently submitted');
  });

  // 14: Academic context is preserved
  it('14: Academic context is preserved on Attendance Correction request', async () => {
    const sectionId = new mongoose.Types.ObjectId();
    const subjectId = new mongoose.Types.ObjectId();

    // Setup faculty assignment
    await FacultyAssignment.create({
      collegeId: collegeA._id,
      departmentId: deptCSE._id,
      facultyId: new mongoose.Types.ObjectId(),
      facultyName: 'Dr. Alan Turing',
      courseId: new mongoose.Types.ObjectId(),
      semesterId: new mongoose.Types.ObjectId(),
      sectionId,
      subjectId,
      academicYearId: new mongoose.Types.ObjectId(),
      isActive: true,
    });

    const studentHeader = createTestAuthHeader({
      userId: studentUserId,
      role: AppRole.STUDENT,
      collegeId: collegeA.id,
      departmentId: deptCSE.id,
    });

    const res = await request(app)
      .post('/api/v1/requests')
      .set(studentHeader)
      .send({
        requestType: 'ATTENDANCE_CORRECTION',
        description: 'Was present in class, marked absent by mistake',
        academicContext: {
          sectionId: sectionId.toString(),
          subjectId: subjectId.toString(),
          subjectName: 'Data Structures',
          sectionName: 'CSE-A',
        },
        details: {
          date: new Date('2026-09-25').toISOString(),
        },
      });

    expect(res.status).toBe(201);
    expect(res.body.data.targetRole).toBe('FACULTY');
    expect(res.body.data.targetName).toBe('Dr. Alan Turing');
    expect(res.body.data.academicContext.subjectName).toBe('Data Structures');
  });

  // 15: Tenant isolation is preserved
  it('15: Tenant isolation prevents College B user from accessing College A request', async () => {
    const studentHeaderA = createTestAuthHeader({
      userId: studentUserId,
      role: AppRole.STUDENT,
      collegeId: collegeA.id,
      departmentId: deptCSE.id,
    });

    const createRes = await request(app)
      .post('/api/v1/requests')
      .set(studentHeaderA)
      .send({
        requestType: 'LEAVE',
        description: 'College A private leave',
      });

    const reqId = createRes.body.data.id;

    // College B Admin attempts to access College A request
    const adminHeaderB = createTestAuthHeader({
      userId: collegeBAdminUserId,
      role: AppRole.COLLEGE_ADMIN,
      collegeId: collegeB.id,
    });

    const viewRes = await request(app)
      .get(`/api/v1/requests/${reqId}`)
      .set(adminHeaderB);

    expect(viewRes.status).toBe(403);
    expect(viewRes.body.success).toBe(false);
  });

  // 16: Safe handling when target cannot be resolved (no college)
  it('16: Safe handling when user has no college context', async () => {
    const unassignedUserHeader = createTestAuthHeader({
      userId: 'usr_orphan',
      role: AppRole.STUDENT,
    });

    const res = await request(app)
      .post('/api/v1/requests')
      .set(unassignedUserHeader)
      .send({
        requestType: 'LEAVE',
        description: 'Orphan request',
      });

    expect(res.status).toBe(403); // blocked by requireCollegeScope
  });

  // 17: Request counts API returns correct values
  it('17: Summary counts API returns active counts for dashboard', async () => {
    const studentHeader = createTestAuthHeader({
      userId: studentUserId,
      role: AppRole.STUDENT,
      collegeId: collegeA.id,
      departmentId: deptCSE.id,
    });

    await request(app)
      .post('/api/v1/requests')
      .set(studentHeader)
      .send({
        requestType: 'LEAVE',
        description: 'Count test leave',
      });

    const countRes = await request(app)
      .get('/api/v1/requests/counts')
      .set(studentHeader);

    expect(countRes.status).toBe(200);
    expect(countRes.body.data.myPendingCount).toBeGreaterThanOrEqual(1);
  });
});
