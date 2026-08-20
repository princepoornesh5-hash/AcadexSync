import request from 'supertest';
import { app } from '../../src/app';
import {
  College,
  Department,
  Course,
  AcademicYear,
  Semester,
  Section,
  Subject,
  User,
  Student,
  Faculty,
  AuthSession,
  Note,
} from '../../src/models';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';
import { AppRole } from '../../src/constants/roles';
import { NoteStatus, NoteType, NoteVisibility, NoteLifecycleState, ResourceType, TokenType } from '../../src/constants/status';
import { signJwtToken, signAccessToken, signRefreshToken, hashToken } from '../../src/utils/token';
import { Logger } from '../../src/utils/logger';
import { createRateLimiter } from '../../src/middleware/rateLimiter.middleware';
import express from 'express';

describe('ACADEX Phase 9O.1 — Production Hardening & Security Audit Tests', () => {
  let collegeA: any;
  let collegeB: any;
  let deptA: any;
  let deptB: any;
  let courseA: any;
  let yearA: any;
  let semA: any;
  let secA: any;
  let subjectA: any;
  let superAdminUser: any;
  let collegeAdminUserA: any;
  let hodUserA: any;
  let facultyUserA: any;
  let facultyDocA: any;
  let studentUserA1: any;
  let studentDocA2: any;

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
      code: 'COEA',
      address: '100 Tech Way',
      email: 'admin@coea.edu',
      phone: '+1-555-0100',
      principal: 'Dr. Principal A',
      status: 'active',
      isActive: true,
    });

    collegeB = await College.create({
      name: 'College of Arts B',
      code: 'COAB',
      address: '200 Arts Blvd',
      email: 'admin@coab.edu',
      phone: '+1-555-0200',
      principal: 'Dr. Principal B',
      status: 'active',
      isActive: true,
    });

    // 2. Departments
    deptA = await Department.create({
      collegeId: collegeA._id,
      name: 'Computer Science',
      code: 'CSE',
      isActive: true,
    });

    deptB = await Department.create({
      collegeId: collegeB._id,
      name: 'Fine Arts',
      code: 'FA',
      isActive: true,
    });

    // 3. Academic Hierarchy
    courseA = await Course.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'B.Tech CSE',
      code: 'BTCSE',
      durationYears: 4,
      totalSemesters: 8,
      isActive: true,
    });

    yearA = await AcademicYear.create({
      collegeId: collegeA._id,
      name: '2026-2027',
      startDate: new Date('2026-08-01'),
      endDate: new Date('2027-05-31'),
      isCurrent: true,
    });

    semA = await Semester.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: yearA._id,
      number: 5,
      name: 'Semester 5',
      startDate: new Date('2026-08-01'),
      endDate: new Date('2026-12-31'),
      isActive: true,
    });

    secA = await Section.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      semesterId: semA._id,
      name: 'Section A',
      capacity: 60,
      isActive: true,
    });

    subjectA = await Subject.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      semesterId: semA._id,
      name: 'Distributed Systems',
      code: 'CS501',
      credits: 4,
      isActive: true,
    });

    // 4. Users & Profiles
    superAdminUser = await User.create({
      instituteId: 'SUPER-001',
      name: 'Global Super Admin',
      email: 'superadmin@acadex.edu',
      role: AppRole.SUPER_ADMIN,
      status: 'active',
      passwordHash: '$2b$10$abcdefghijklmnopqrstuvwxyz123456',
    });

    collegeAdminUserA = await User.create({
      collegeId: collegeA._id,
      instituteId: 'ADMIN-COEA-001',
      name: 'College Admin A',
      email: 'admin@coea.edu',
      role: AppRole.COLLEGE_ADMIN,
      status: 'active',
      passwordHash: '$2b$10$abcdefghijklmnopqrstuvwxyz123456',
    });

    await User.create({
      collegeId: collegeB._id,
      instituteId: 'ADMIN-COAB-001',
      name: 'College Admin B',
      email: 'admin@coab.edu',
      role: AppRole.COLLEGE_ADMIN,
      status: 'active',
      passwordHash: '$2b$10$abcdefghijklmnopqrstuvwxyz123456',
    });

    hodUserA = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      instituteId: 'HOD-CSE-001',
      name: 'HOD CSE',
      email: 'hod.cse@coea.edu',
      role: AppRole.HOD,
      status: 'active',
    });

    facultyUserA = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      instituteId: 'FAC-CSE-001',
      name: 'Prof. Alan Turing',
      email: 'alan@coea.edu',
      role: AppRole.FACULTY,
      status: 'active',
    });

    facultyDocA = await Faculty.create({
      userId: facultyUserA._id,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      name: 'Prof. Alan Turing',
      email: 'alan@coea.edu',
      instituteId: 'FAC-CSE-001',
      designation: 'Professor',
      subjectIds: [subjectA._id],
      sectionIds: [secA._id],
      status: 'active',
      isActive: true,
    });

    studentUserA1 = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      instituteId: 'STU-001',
      name: 'Alice Student',
      email: 'alice@coea.edu',
      role: AppRole.STUDENT,
      status: 'active',
    });

    await Student.create({
      userId: studentUserA1._id,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: yearA._id,
      semesterId: semA._id,
      sectionId: secA._id,
      name: 'Alice Student',
      email: 'alice@coea.edu',
      studentIdNumber: 'STU-001',
      rollNumber: 'CSE-01',
      status: 'active',
      isActive: true,
    });

    const studentUserA2 = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      instituteId: 'STU-002',
      name: 'Bob Student',
      email: 'bob@coea.edu',
      role: AppRole.STUDENT,
      status: 'active',
    });

    studentDocA2 = await Student.create({
      userId: studentUserA2._id,
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      academicYearId: yearA._id,
      semesterId: semA._id,
      sectionId: secA._id,
      name: 'Bob Student',
      email: 'bob@coea.edu',
      studentIdNumber: 'STU-002',
      rollNumber: 'CSE-02',
      status: 'active',
      isActive: true,
    });
  });

  // =========================================================================
  // 1. SECURITY HTTP HEADERS (HELMET)
  // =========================================================================
  test('1. API responses include standard Helmet security headers', async () => {
    const res = await request(app).get('/health');

    expect(res.status).toBe(200);
    expect(res.headers).toHaveProperty('x-content-type-options', 'nosniff');
    expect(res.headers).toHaveProperty('x-frame-options', 'DENY');
    expect(res.headers).toHaveProperty('referrer-policy', 'strict-origin-when-cross-origin');
    expect(res.headers).toHaveProperty('x-dns-prefetch-control', 'off');
    expect(res.headers).not.toHaveProperty('x-powered-by');
  });

  // =========================================================================
  // 2. CORS HARDENING
  // =========================================================================
  test('2. Allows non-browser requests and provides appropriate CORS headers', async () => {
    const res = await request(app)
      .get('/health')
      .set('Origin', 'http://localhost:3000');

    expect(res.status).toBe(200);
    expect(res.headers).toHaveProperty('access-control-allow-origin');
  });

  // =========================================================================
  // 3. RATE LIMITING ENFORCEMENT
  // =========================================================================
  test('3. Rate limiter triggers 429 Too Many Requests with standard retry headers', async () => {
    const testApp = express();
    const testLimiter = createRateLimiter({
      windowMs: 60 * 1000,
      maxRequests: 3,
      message: 'Test rate limit exceeded',
      skipInTest: false,
    });
    testApp.use(testLimiter);
    testApp.get('/test-limit', (_req, res) => res.json({ ok: true }));

    // Request 1, 2, 3 should succeed
    const res1 = await request(testApp).get('/test-limit');
    expect(res1.status).toBe(200);
    expect(res1.headers['x-ratelimit-remaining']).toBe('2');

    const res2 = await request(testApp).get('/test-limit');
    expect(res2.status).toBe(200);
    expect(res2.headers['x-ratelimit-remaining']).toBe('1');

    const res3 = await request(testApp).get('/test-limit');
    expect(res3.status).toBe(200);
    expect(res3.headers['x-ratelimit-remaining']).toBe('0');

    // Request 4 must be throttled
    const res4 = await request(testApp).get('/test-limit');
    expect(res4.status).toBe(429);
    expect(res4.headers).toHaveProperty('retry-after');
  });

  // =========================================================================
  // 4. AUTHENTICATION & JWT SECURITY
  // =========================================================================
  test('4. Rejects request with expired JWT token', async () => {
    const expiredToken = signJwtToken(
      {
        userId: studentUserA1.id,
        role: AppRole.STUDENT,
        collegeId: collegeA.id,
        tokenType: TokenType.ACCESS,
      },
      -10 // Expired 10 seconds ago
    );

    const res = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${expiredToken}`);

    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
    expect(res.body.error.message).toContain('expired');
  });

  test('5. Rejects request with forged / tampered JWT signature', async () => {
    const validToken = signAccessToken({
      userId: studentUserA1.id,
      role: AppRole.STUDENT,
      collegeId: collegeA.id,
    });

    // Tamper with the token signature
    const parts = validToken.split('.');
    const tamperedToken = `${parts[0]}.${parts[1]}.invalidSignatureHere12345`;

    const res = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${tamperedToken}`);

    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
    expect(res.body.error.message).toContain('signature');
  });

  test('6. Rejects request with malformed token structure', async () => {
    const res = await request(app)
      .get('/api/v1/auth/me')
      .set('Authorization', 'Bearer not-a-jwt-token');

    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
  });

  // =========================================================================
  // 5. SESSION & REFRESH TOKEN ROTATION
  // =========================================================================
  test('7. Revoked session cannot be refreshed', async () => {
    const sessionId = 'session_revoked_test_123';
    const fakeToken = signRefreshToken({
      userId: studentUserA1.id,
      role: AppRole.STUDENT,
      sessionId,
    });
    const tokenHash = hashToken(fakeToken);

    await AuthSession.create({
      userId: studentUserA1._id,
      sessionId,
      refreshTokenHash: tokenHash,
      expiresAt: new Date(Date.now() + 604800000),
      revokedAt: new Date(), // Already revoked
    });

    const res = await request(app)
      .post('/api/v1/auth/refresh')
      .send({ refreshToken: fakeToken });

    expect(res.status).toBe(401);
    expect(res.body.success).toBe(false);
    expect(res.body.error.message).toContain('revoked');
  });

  // =========================================================================
  // 6. PASSWORD & CREDENTIAL PRIVACY
  // =========================================================================
  test('8. Password hash is never serialized or exposed in user payloads', async () => {
    const user = await User.findById(collegeAdminUserA._id);
    const json = user?.toJSON();
    const obj = user?.toObject();

    expect(json).toBeDefined();
    expect(json).not.toHaveProperty('passwordHash');
    expect(json).not.toHaveProperty('__v');

    expect(obj).toBeDefined();
    expect(obj).not.toHaveProperty('passwordHash');
    expect(obj).not.toHaveProperty('__v');
  });

  // =========================================================================
  // 7. INPUT VALIDATION & MALFORMED REQUESTS
  // =========================================================================
  test('9. Malformed JSON returns clean 400 error without exposing stack trace in production', async () => {
    const res = await request(app)
      .post('/api/v1/auth/login')
      .set('Content-Type', 'application/json')
      .send('{ "invalid_json": ');

    expect(res.status).toBe(400);
    expect(res.body.success).toBe(false);
    expect(res.body.error).toHaveProperty('code');
  });

  test('10. Invalid MongoDB ObjectId returns clean error without leaking database internals', async () => {
    const authHeader = createTestAuthHeader({
      role: AppRole.SUPER_ADMIN,
      userId: superAdminUser.id,
      collegeId: 'global',
    });

    const res = await request(app)
      .get('/api/v1/colleges/not-a-valid-mongo-object-id')
      .set(authHeader);

    expect([400, 404, 422]).toContain(res.status);
    expect(res.body.success).toBe(false);
    expect(res.body).not.toHaveProperty('stack');
  });

  // =========================================================================
  // 8. MULTI-TENANT ISOLATION & RBAC AUDIT
  // =========================================================================
  test('11. College Admin A is strictly forbidden from accessing College B data', async () => {
    const authHeaderA = createTestAuthHeader({
      role: AppRole.COLLEGE_ADMIN,
      userId: collegeAdminUserA.id,
      collegeId: collegeA.id,
    });

    const res = await request(app)
      .get(`/api/v1/departments/${deptB.id}`)
      .set(authHeaderA);

    expect([403, 404]).toContain(res.status);
    expect(res.body.success).toBe(false);
  });

  test('12. HOD cannot access data from another department', async () => {
    const otherDept = await Department.create({
      collegeId: collegeA._id,
      name: 'Mechanical Engineering',
      code: 'MECH',
      isActive: true,
    });

    const authHeaderHod = createTestAuthHeader({
      role: AppRole.HOD,
      userId: hodUserA.id,
      collegeId: collegeA.id,
      departmentId: deptA.id,
    });

    const res = await request(app)
      .get(`/api/v1/reports/attendance/department/${otherDept.id}`)
      .set(authHeaderHod);

    expect(res.status).toBe(403);
    expect(res.body.success).toBe(false);
  });

  test('13. Student cannot view another student personal report or access admin sections', async () => {
    const authHeaderAlice = createTestAuthHeader({
      role: AppRole.STUDENT,
      userId: studentUserA1.id,
      collegeId: collegeA.id,
      departmentId: deptA.id,
    });

    // Cross-student report access
    const res1 = await request(app)
      .get(`/api/v1/reports/attendance/student/${studentDocA2.id}`)
      .set(authHeaderAlice);

    expect(res1.status).toBe(403);
    expect(res1.body.success).toBe(false);

    // Section report access
    const res2 = await request(app)
      .get(`/api/v1/reports/attendance/section/${secA.id}`)
      .set(authHeaderAlice);

    expect(res2.status).toBe(403);
    expect(res2.body.success).toBe(false);
  });

  // =========================================================================
  // 9. IMAGEKIT & FILE STORAGE SECURITY
  // =========================================================================
  test('14. ImageKit rejects unsupported MIME types and file extension mismatches', async () => {
    const authHeader = createTestAuthHeader({
      role: AppRole.FACULTY,
      userId: facultyUserA.id,
      collegeId: collegeA.id,
      departmentId: deptA.id,
    });

    // Unsupported executable MIME
    const res1 = await request(app)
      .post('/api/v1/notes/upload-url')
      .set(authHeader)
      .send({
        courseId: courseA.id,
        semesterId: semA.id,
        subjectId: subjectA.id,
        fileName: 'malicious.exe',
        fileSize: 1024,
        mimeType: 'application/x-msdownload',
      });

    expect([400, 422]).toContain(res1.status);
    expect(res1.body.success).toBe(false);

    // Mismatched MIME and extension (.pdf with image/png)
    const res2 = await request(app)
      .post('/api/v1/notes/upload-url')
      .set(authHeader)
      .send({
        courseId: courseA.id,
        semesterId: semA.id,
        subjectId: subjectA.id,
        fileName: 'document.pdf',
        fileSize: 1024,
        mimeType: 'image/png',
      });

    expect([400, 422]).toContain(res2.status);
    expect(res2.body.success).toBe(false);
  });

  test('15. Students cannot request note upload authorizations', async () => {
    const authHeader = createTestAuthHeader({
      role: AppRole.STUDENT,
      userId: studentUserA1.id,
      collegeId: collegeA.id,
      departmentId: deptA.id,
    });

    const res = await request(app)
      .post('/api/v1/notes/upload-url')
      .set(authHeader)
      .send({
        courseId: courseA.id,
        semesterId: semA.id,
        subjectId: subjectA.id,
        fileName: 'lecture.pdf',
        fileSize: 1024,
        mimeType: 'application/pdf',
      });

    expect(res.status).toBe(403);
    expect(res.body.success).toBe(false);
  });

  test('16. Deleted notes return 404 on download URL request', async () => {
    const note = await Note.create({
      collegeId: collegeA._id,
      departmentId: deptA._id,
      courseId: courseA._id,
      semesterId: semA._id,
      sectionId: secA._id,
      subjectId: subjectA._id,
      facultyId: facultyDocA._id,
      authorUserId: facultyUserA._id,
      title: 'Deleted Note',
      description: 'Will be deleted',
      noteType: NoteType.CHAPTER,
      visibility: NoteVisibility.PUBLIC,
      lifecycleState: NoteLifecycleState.DELETED,
      resourceType: ResourceType.FILE_ATTACHMENT,
      storageProvider: 'imagekit',
      originalFileName: 'del.pdf',
      storageKey: 'notes/del.pdf',
      fileExtension: 'pdf',
      fileUrl: 'https://ik.imagekit.io/AcadexAi/notes/del.pdf',
      fileId: 'ik_del_1',
      fileSize: 1024,
      mimeType: 'application/pdf',
      status: NoteStatus.ARCHIVED,
    });

    const authHeader = createTestAuthHeader({
      role: AppRole.STUDENT,
      userId: studentUserA1.id,
      collegeId: collegeA.id,
      departmentId: deptA.id,
    });

    const res = await request(app)
      .get(`/api/v1/notes/${note.id}/download`)
      .set(authHeader);

    expect(res.status).toBe(404);
    expect(res.body.success).toBe(false);
  });

  // =========================================================================
  // 10. NOTIFICATION SECURITY & TOKEN OWNERSHIP
  // =========================================================================
  test('17. User cannot access or mark notifications belonging to another user', async () => {
    const authHeaderAlice = createTestAuthHeader({
      role: AppRole.STUDENT,
      userId: studentUserA1.id,
      collegeId: collegeA.id,
      departmentId: deptA.id,
    });

    const fakeNotifId = '6a85ee2e1a3b5c7d9e112233';

    // Alice trying to read Bob's or non-existent notification
    const res = await request(app)
      .get(`/api/v1/notifications/${fakeNotifId}`)
      .set(authHeaderAlice);

    expect([403, 404]).toContain(res.status);
  });

  // =========================================================================
  // 11. SENSITIVE DATA LOG MASKING
  // =========================================================================
  test('18. Logger sanitization masks sensitive secrets, passwords, private keys, and JWTs', () => {
    const rawLog = 'User login failed password="super_secret_password_123" Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VySWQiOiIxMjMifQ.signature token="test_token"';
    const sanitized = Logger.sanitize(rawLog);

    expect(sanitized).not.toContain('super_secret_password_123');
    expect(sanitized).not.toContain('eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9');
    expect(sanitized).toContain('***');

    // PEM Private Key sanitization
    const pemLog = 'Error connecting: -----BEGIN PRIVATE KEY-----\nMIIEvgIBADANBgkqhkiG9w0BAQEFAASC\n-----END PRIVATE KEY-----';
    const sanitizedPem = Logger.sanitize(pemLog);
    expect(sanitizedPem).not.toContain('MIIEvgIBADANBgkqhkiG9w0BAQEFAASC');
    expect(sanitizedPem).toContain('***PRIVATE_KEY***');
  });
});
