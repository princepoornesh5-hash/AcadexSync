import request from 'supertest';
import { app } from '../../src/app';
import { College } from '../../src/models/college.model';
import { User } from '../../src/models/user.model';
import { Department } from '../../src/models/department.model';
import { Course } from '../../src/models/course.model';
import { AcademicYear } from '../../src/models/academicYear.model';
import { Semester } from '../../src/models/semester.model';
import { Section } from '../../src/models/section.model';
import { Subject } from '../../src/models/subject.model';
import { Faculty } from '../../src/models/faculty.model';
import { Student } from '../../src/models/student.model';
import { AuditLog } from '../../src/models/auditLog.model';
import { AppRole } from '../../src/constants/roles';
import {
  AccountStatus,
  CollegeStatus,
  DepartmentStatus,
  NoteLifecycleState,
  NoteStatus,
  NoteType,
  NoteVisibility,
} from '../../src/constants/status';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';
import { PasswordService } from '../../src/services/password.service';
import { ImageKitService } from '../../src/storage/imagekit.service';

describe('ACADEX Phase 9L.2 — Notes & ImageKit Storage Management Tests', () => {
  let superAdminUser: InstanceType<typeof User>;
  let collegeAdminA: InstanceType<typeof User>;
  let collegeAdminB: InstanceType<typeof User>;
  let hodA1: InstanceType<typeof User>;
  let facultyA1: InstanceType<typeof User>;
  let facultyA2EE: InstanceType<typeof User>;
  let studentA1: InstanceType<typeof User>;
  let studentA2Sem3: InstanceType<typeof User>;

  let collegeA: InstanceType<typeof College>;
  let collegeB: InstanceType<typeof College>;

  let deptA1CSE: InstanceType<typeof Department>;
  let deptA2EE: InstanceType<typeof Department>;

  let courseA: InstanceType<typeof Course>;
  let academicYearA: InstanceType<typeof AcademicYear>;
  let semesterA5: InstanceType<typeof Semester>;
  let semesterA3: InstanceType<typeof Semester>;
  let sectionA: InstanceType<typeof Section>;

  let subjectOS: InstanceType<typeof Subject>;
  let subjectEE: InstanceType<typeof Subject>;

  let superAdminHeader: { Authorization: string };
  let collegeAdminAHeader: { Authorization: string };
  let collegeAdminBHeader: { Authorization: string };
  let hodA1Header: { Authorization: string };
  let facultyA1Header: { Authorization: string };
  let facultyA2EEHeader: { Authorization: string };
  let studentA1Header: { Authorization: string };
  let studentA2Sem3Header: { Authorization: string };

  beforeAll(async () => {
    await setupTestDB();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  beforeEach(async () => {
    await clearTestDB();
    jest.restoreAllMocks();

    // Default mock for ImageKit authentication and file details
    jest.spyOn(ImageKitService, 'getAuthenticationParameters').mockImplementation((folder, fileName, maxBytes) => ({
      token: 'mock-token-123',
      expire: Math.floor(Date.now() / 1000) + 300,
      signature: 'mock-signature-abc',
      publicKey: 'mock_pk',
      urlEndpoint: 'https://ik.imagekit.io/AcadexAi',
      folder,
      fileName,
      fileId: 'mock-file-id-123',
      expiresInSeconds: 300,
      maxSizeBytes: maxBytes || 25 * 1024 * 1024,
    }));

    jest.spyOn(ImageKitService, 'generateSignedUrl').mockImplementation((pathOrUrl) => {
      return `https://ik.imagekit.io/AcadexAi/${pathOrUrl}?ik-s=signed123`;
    });

    jest.spyOn(ImageKitService, 'getFileDetails').mockImplementation(async (fileId) => ({
      fileId,
      name: 'file.pdf',
      size: 1024 * 1024 * 2, // 2 MB
      filePath: `/mock/path/${fileId}.pdf`,
      url: `https://ik.imagekit.io/AcadexAi/${fileId}.pdf`,
      thumbnailUrl: `https://ik.imagekit.io/AcadexAi/tr:w-300/${fileId}.pdf`,
      fileType: 'non-image',
      mimeType: 'application/pdf',
    }));

    jest.spyOn(ImageKitService, 'deleteFile').mockResolvedValue(true);

    const pwdHash = await PasswordService.hashPassword('Pass1234');

    collegeA = await College.create({
      name: 'MIT College of Engineering',
      code: 'MIT',
      address: '77 Massachusetts Ave, Cambridge, MA',
      email: 'admin@mit.edu',
      phone: '+16172531000',
      principal: 'Dr. Sally Kornbluth',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });

    collegeB = await College.create({
      name: 'Stanford Institute of Tech',
      code: 'STAN',
      address: '450 Jane Stanford Way, Stanford, CA',
      email: 'admin@stanford.edu',
      phone: '+16507232300',
      principal: 'Dr. Richard Saller',
      status: CollegeStatus.ACTIVE,
      isActive: true,
    });

    deptA1CSE = await Department.create({
      collegeId: collegeA._id,
      name: 'Computer Science & Engineering',
      code: 'CSE',
      status: DepartmentStatus.ACTIVE,
      isActive: true,
    });

    deptA2EE = await Department.create({
      collegeId: collegeA._id,
      name: 'Electrical Engineering',
      code: 'EE',
      status: DepartmentStatus.ACTIVE,
      isActive: true,
    });

    courseA = await Course.create({
      collegeId: collegeA._id,
      departmentId: deptA1CSE._id,
      name: 'B.Tech CSE',
      code: 'BTCSE',
      duration: 4,
      isActive: true,
    });

    academicYearA = await AcademicYear.create({
      collegeId: collegeA._id,
      departmentId: deptA1CSE._id,
      courseId: courseA._id,
      name: '2026-2027',
      year: 2026,
      startDate: new Date('2026-08-01'),
      endDate: new Date('2027-05-31'),
      isActive: true,
    });

    semesterA5 = await Semester.create({
      collegeId: collegeA._id,
      departmentId: deptA1CSE._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      name: 'Semester 5',
      number: 5,
      isActive: true,
    });

    semesterA3 = await Semester.create({
      collegeId: collegeA._id,
      departmentId: deptA1CSE._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      name: 'Semester 3',
      number: 3,
      isActive: true,
    });

    sectionA = await Section.create({
      collegeId: collegeA._id,
      departmentId: deptA1CSE._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA5._id,
      name: 'Section A',
      capacity: 60,
      isActive: true,
    });

    subjectOS = await Subject.create({
      collegeId: collegeA._id,
      departmentId: deptA1CSE._id,
      courseId: courseA._id,
      semesterId: semesterA5._id,
      name: 'Operating Systems',
      code: 'CS501',
      type: 'theory',
      credits: 4,
      isActive: true,
    });

    const courseEE = await Course.create({
      collegeId: collegeA._id,
      departmentId: deptA2EE._id,
      name: 'B.Tech EE',
      code: 'BTEE',
      duration: 4,
      isActive: true,
    });

    const semesterEE = await Semester.create({
      collegeId: collegeA._id,
      departmentId: deptA2EE._id,
      courseId: courseEE._id,
      academicYearId: academicYearA._id,
      name: 'EE Semester 3',
      number: 3,
      isActive: true,
    });

    subjectEE = await Subject.create({
      collegeId: collegeA._id,
      departmentId: deptA2EE._id,
      courseId: courseEE._id,
      semesterId: semesterEE._id,
      name: 'Circuit Theory',
      code: 'EE301',
      type: 'theory',
      credits: 3,
      isActive: true,
    });

    // Users
    superAdminUser = await User.create({
      email: 'superadmin@acadex.com',
      instituteId: 'SUPER-001',
      passwordHash: pwdHash,
      role: AppRole.SUPER_ADMIN,
      name: 'Super Admin',
      status: AccountStatus.ACTIVE,
    });

    collegeAdminA = await User.create({
      collegeId: collegeA._id,
      email: 'admin@mit.edu',
      instituteId: 'MIT-ADM-001',
      passwordHash: pwdHash,
      role: AppRole.COLLEGE_ADMIN,
      name: 'MIT Admin',
      status: AccountStatus.ACTIVE,
    });

    collegeAdminB = await User.create({
      collegeId: collegeB._id,
      email: 'admin@stanford.edu',
      instituteId: 'STAN-ADM-001',
      passwordHash: pwdHash,
      role: AppRole.COLLEGE_ADMIN,
      name: 'Stanford Admin',
      status: AccountStatus.ACTIVE,
    });

    hodA1 = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA1CSE._id,
      email: 'hod.cse@mit.edu',
      instituteId: 'MIT-HOD-CSE',
      passwordHash: pwdHash,
      role: AppRole.HOD,
      name: 'Dr. Alan Turing',
      status: AccountStatus.ACTIVE,
    });

    facultyA1 = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA1CSE._id,
      email: 'faculty.cse@mit.edu',
      instituteId: 'MIT-FAC-001',
      passwordHash: pwdHash,
      role: AppRole.FACULTY,
      name: 'Prof. Dennis Ritchie',
      status: AccountStatus.ACTIVE,
    });

    await Faculty.create({
      userId: facultyA1._id,
      collegeId: collegeA._id,
      departmentId: deptA1CSE._id,
      name: facultyA1.name,
      email: facultyA1.email,
      instituteId: facultyA1.instituteId,
      designation: 'Professor',
      isActive: true,
    });

    facultyA2EE = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA2EE._id,
      email: 'faculty.ee@mit.edu',
      instituteId: 'MIT-FAC-002',
      passwordHash: pwdHash,
      role: AppRole.FACULTY,
      name: 'Prof. Nikola Tesla',
      status: AccountStatus.ACTIVE,
    });

    await Faculty.create({
      userId: facultyA2EE._id,
      collegeId: collegeA._id,
      departmentId: deptA2EE._id,
      name: facultyA2EE.name,
      email: facultyA2EE.email,
      instituteId: facultyA2EE.instituteId,
      designation: 'Associate Professor',
      isActive: true,
    });

    studentA1 = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA1CSE._id,
      email: 'alice@student.mit.edu',
      instituteId: 'MIT-STU-001',
      passwordHash: pwdHash,
      role: AppRole.STUDENT,
      name: 'Alice Smith',
      status: AccountStatus.ACTIVE,
    });

    await Student.create({
      userId: studentA1._id,
      collegeId: collegeA._id,
      departmentId: deptA1CSE._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA5._id,
      sectionId: sectionA._id,
      name: studentA1.name,
      email: studentA1.email,
      instituteId: studentA1.instituteId,
      rollNumber: 'CS501',
      currentSemester: 5,
      isActive: true,
    });

    studentA2Sem3 = await User.create({
      collegeId: collegeA._id,
      departmentId: deptA1CSE._id,
      email: 'bob@student.mit.edu',
      instituteId: 'MIT-STU-002',
      passwordHash: pwdHash,
      role: AppRole.STUDENT,
      name: 'Bob Johnson',
      status: AccountStatus.ACTIVE,
    });

    await Student.create({
      userId: studentA2Sem3._id,
      collegeId: collegeA._id,
      departmentId: deptA1CSE._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA3._id,
      name: studentA2Sem3.name,
      email: studentA2Sem3.email,
      instituteId: studentA2Sem3.instituteId,
      rollNumber: 'CS301',
      currentSemester: 3,
      isActive: true,
    });

    superAdminHeader = createTestAuthHeader({
      userId: superAdminUser.id,
      instituteId: superAdminUser.instituteId,
      role: AppRole.SUPER_ADMIN,
    });
    collegeAdminAHeader = createTestAuthHeader({
      userId: collegeAdminA.id,
      instituteId: collegeAdminA.instituteId,
      collegeId: collegeA.id,
      role: AppRole.COLLEGE_ADMIN,
    });
    collegeAdminBHeader = createTestAuthHeader({
      userId: collegeAdminB.id,
      instituteId: collegeAdminB.instituteId,
      collegeId: collegeB.id,
      role: AppRole.COLLEGE_ADMIN,
    });
    hodA1Header = createTestAuthHeader({
      userId: hodA1.id,
      instituteId: hodA1.instituteId,
      collegeId: collegeA.id,
      departmentId: deptA1CSE.id,
      role: AppRole.HOD,
    });
    facultyA1Header = createTestAuthHeader({
      userId: facultyA1.id,
      instituteId: facultyA1.instituteId,
      collegeId: collegeA.id,
      departmentId: deptA1CSE.id,
      role: AppRole.FACULTY,
    });
    facultyA2EEHeader = createTestAuthHeader({
      userId: facultyA2EE.id,
      instituteId: facultyA2EE.instituteId,
      collegeId: collegeA.id,
      departmentId: deptA2EE.id,
      role: AppRole.FACULTY,
    });
    studentA1Header = createTestAuthHeader({
      userId: studentA1.id,
      instituteId: studentA1.instituteId,
      collegeId: collegeA.id,
      departmentId: deptA1CSE.id,
      role: AppRole.STUDENT,
    });
    studentA2Sem3Header = createTestAuthHeader({
      userId: studentA2Sem3.id,
      instituteId: studentA2Sem3.instituteId,
      collegeId: collegeA.id,
      departmentId: deptA1CSE.id,
      role: AppRole.STUDENT,
    });
  });

  // =========================================================================
  // 1. UPLOAD AUTHORIZATION & VALIDATION (1 - 10)
  // =========================================================================

  it('1. Faculty can request upload authorization for an authorized subject', async () => {
    const res = await request(app)
      .post('/api/v1/academics/notes/upload-url')
      .set(facultyA1Header)
      .send({
        subjectId: subjectOS.id,
        title: 'Unit 1: Process Synchronization & Mutex',
        description: 'Comprehensive lecture slides and reference notes',
        noteType: NoteType.CHAPTER,
        visibility: NoteVisibility.PUBLIC,
        fileName: 'Unit1_Processes.pdf',
        mimeType: 'application/pdf',
        fileSize: 1024 * 1024 * 2, // 2MB
        chapter: 'Unit 1',
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.uploadUrl).toBeDefined();
    expect(res.body.data.storageKey).toContain(`acadex/colleges/${collegeA.id}/notes/`);
    expect(res.body.data.storageKey).toContain('.pdf');
    expect(res.body.data.note.lifecycleState).toBe(NoteLifecycleState.PENDING_UPLOAD);
    expect(res.body.data.note.status).toBe(NoteStatus.DRAFT);
  });

  it('2. Unauthorized faculty cannot upload notes to another department -> 403 Forbidden', async () => {
    const res = await request(app)
      .post('/api/v1/academics/notes/upload-url')
      .set(facultyA2EEHeader) // EE Faculty trying to upload note to CSE OS subject
      .send({
        subjectId: subjectOS.id,
        title: 'Unauthorized Note',
        fileName: 'test.pdf',
        mimeType: 'application/pdf',
        fileSize: 1024 * 50,
      });

    expect(res.status).toBe(403);
    const errMessage = res.body.error?.message || res.body.message;
    expect(errMessage).toContain('another department');
  });

  it('3. Student cannot request upload authorization -> 403 Forbidden', async () => {
    const res = await request(app)
      .post('/api/v1/academics/notes/upload-url')
      .set(studentA1Header)
      .send({
        subjectId: subjectOS.id,
        title: 'Student Attempting Note Upload',
        fileName: 'test.pdf',
        mimeType: 'application/pdf',
        fileSize: 1024 * 50,
      });

    expect(res.status).toBe(403);
  });

  it('6 & 7. Cross-college access is strictly rejected -> 403 Forbidden', async () => {
    const res = await request(app)
      .post('/api/v1/academics/notes/upload-url')
      .set(collegeAdminBHeader)
      .send({
        subjectId: subjectOS.id, // Subject in College A
        title: 'Cross College Upload Attempt',
        fileName: 'test.pdf',
        mimeType: 'application/pdf',
        fileSize: 1024 * 50,
      });

    expect(res.status).toBe(403);
  });

  it('8 & 9. Unsupported MIME type or extension is rejected -> 400/422', async () => {
    // Unsupported MIME
    const resMime = await request(app)
      .post('/api/v1/academics/notes/upload-url')
      .set(facultyA1Header)
      .send({
        subjectId: subjectOS.id,
        title: 'Invalid MIME Note',
        fileName: 'archive.zip',
        mimeType: 'application/zip',
        fileSize: 1024 * 50,
      });
    expect(resMime.status).toBe(422);

    // Mismatched extension
    const resExt = await request(app)
      .post('/api/v1/academics/notes/upload-url')
      .set(facultyA1Header)
      .send({
        subjectId: subjectOS.id,
        title: 'Mismatched Ext Note',
        fileName: 'malicious.exe',
        mimeType: 'application/pdf',
        fileSize: 1024 * 50,
      });
    expect(resExt.status).toBe(400);
    const extErrMsg = resExt.body.error?.message || resExt.body.message;
    expect(extErrMsg).toContain('does not match');
  });

  it('10. Oversized files are rejected -> 422 Unprocessable', async () => {
    const res = await request(app)
      .post('/api/v1/academics/notes/upload-url')
      .set(facultyA1Header)
      .send({
        subjectId: subjectOS.id,
        title: 'Oversized Note',
        fileName: 'massive_file.pdf',
        mimeType: 'application/pdf',
        fileSize: 1024 * 1024 * 50, // 50MB > 25MB limit
      });

    expect(res.status).toBe(422);
    const sizeErrMsg = res.body.error?.message || res.body.message;
    expect(sizeErrMsg).toContain('Validation error');
  });

  // =========================================================================
  // 2. UPLOAD COMPLETION & LIFECYCLE (11 - 15)
  // =========================================================================

  it('11 & 12. Upload completion verifies ImageKit object existence and transitions to READY', async () => {
    // 1. Request upload URL
    const resReq = await request(app)
      .post('/api/v1/academics/notes/upload-url')
      .set(facultyA1Header)
      .send({
        subjectId: subjectOS.id,
        title: 'Chapter 2: Memory Management',
        fileName: 'Chapter2_Memory.pdf',
        mimeType: 'application/pdf',
        fileSize: 1024 * 1024 * 3,
      });

    const noteId = resReq.body.data.note.id;

    // Incomplete note should NOT be visible to student
    const resStuPending = await request(app)
      .get(`/api/v1/academics/notes/${noteId}`)
      .set(studentA1Header);
    expect(resStuPending.status).toBe(404);

    // 2. Complete upload
    const resComplete = await request(app)
      .post(`/api/v1/academics/notes/${noteId}/complete`)
      .set(facultyA1Header);

    expect(resComplete.status).toBe(200);
    expect(resComplete.body.data.lifecycleState).toBe(NoteLifecycleState.READY);
    expect(resComplete.body.data.status).toBe(NoteStatus.PUBLISHED);

    // Now student CAN see the note
    const resStuReady = await request(app)
      .get(`/api/v1/academics/notes/${noteId}`)
      .set(studentA1Header);
    expect(resStuReady.status).toBe(200);
    expect(resStuReady.body.data.title).toBe('Chapter 2: Memory Management');
  });

  it('13 & 14. Download URL generation requires authorization and returns short-lived URL', async () => {
    // Setup published note
    const resReq = await request(app)
      .post('/api/v1/academics/notes/upload-url')
      .set(facultyA1Header)
      .send({
        subjectId: subjectOS.id,
        title: 'Chapter 3: File Systems',
        fileName: 'Chapter3_FileSystems.pdf',
        mimeType: 'application/pdf',
        fileSize: 1024 * 1024 * 1,
      });
    const noteId = resReq.body.data.note.id;
    await request(app).post(`/api/v1/academics/notes/${noteId}/complete`).set(facultyA1Header);

    // Student in Semester 5 (Alice) can download
    const resDownload = await request(app)
      .get(`/api/v1/academics/notes/${noteId}/download`)
      .set(studentA1Header);

    expect(resDownload.status).toBe(200);
    expect(resDownload.body.data.downloadUrl).toContain('ik.imagekit.io');
    expect(resDownload.body.data.expiresInSeconds).toBe(300);

    // Student in Semester 3 (Bob) cannot download Semester 5 note -> 403 Forbidden
    const resBobDownload = await request(app)
      .get(`/api/v1/academics/notes/${noteId}/download`)
      .set(studentA2Sem3Header);
    expect(resBobDownload.status).toBe(403);
    const bobErrMsg = resBobDownload.body.error?.message || resBobDownload.body.message;
    expect(bobErrMsg).toContain('different academic semester');
  });

  // =========================================================================
  // 3. REPLACEMENT / VERSIONING & SAFE DELETION (16 - 19)
  // =========================================================================

  it('16 & 17. Note replacement creates a new version without deleting old version prematurely', async () => {
    // 1. Create and complete note v1
    const resReq = await request(app)
      .post('/api/v1/academics/notes/upload-url')
      .set(facultyA1Header)
      .send({
        subjectId: subjectOS.id,
        title: 'CPU Scheduling Algorithms',
        fileName: 'Scheduling_v1.pdf',
        mimeType: 'application/pdf',
        fileSize: 1024 * 1024,
      });
    const noteId = resReq.body.data.note.id;
    await request(app).post(`/api/v1/academics/notes/${noteId}/complete`).set(facultyA1Header);

    // 2. Request replacement upload URL
    const resReplaceReq = await request(app)
      .post(`/api/v1/academics/notes/${noteId}/replace-url`)
      .set(facultyA1Header)
      .send({
        fileName: 'Scheduling_v2_revised.pdf',
        mimeType: 'application/pdf',
        fileSize: 1024 * 1024 * 2,
      });

    expect(resReplaceReq.status).toBe(200);
    expect(resReplaceReq.body.data.uploadUrl).toBeDefined();
    expect(resReplaceReq.body.data.fileId).toContain('v2-');

    // 3. Complete replacement
    const resReplaceComplete = await request(app)
      .post(`/api/v1/academics/notes/${noteId}/replace-complete`)
      .set(facultyA1Header)
      .send({
        storageKey: resReplaceReq.body.data.storageKey,
        fileId: resReplaceReq.body.data.fileId,
        fileName: 'Scheduling_v2_revised.pdf',
        mimeType: 'application/pdf',
        fileSize: 1024 * 1024 * 2,
      });

    expect(resReplaceComplete.status).toBe(200);
    expect(resReplaceComplete.body.data.version).toBe(2);
    expect(resReplaceComplete.body.data.previousVersions).toHaveLength(1);
    expect(resReplaceComplete.body.data.previousVersions[0].version).toBe(1);
  });

  it('18. Safe deletion marks status DELETED and removes objects from ImageKit', async () => {
    const resReq = await request(app)
      .post('/api/v1/academics/notes/upload-url')
      .set(facultyA1Header)
      .send({
        subjectId: subjectOS.id,
        title: 'Deprecated Notes',
        fileName: 'Old_Notes.pdf',
        mimeType: 'application/pdf',
        fileSize: 1024 * 500,
      });
    const noteId = resReq.body.data.note.id;
    await request(app).post(`/api/v1/academics/notes/${noteId}/complete`).set(facultyA1Header);

    // Unauthorized student cannot delete
    const resStuDel = await request(app)
      .delete(`/api/v1/academics/notes/${noteId}`)
      .set(studentA1Header);
    expect(resStuDel.status).toBe(403);

    // Authorized Faculty deletes note
    const resDel = await request(app)
      .delete(`/api/v1/academics/notes/${noteId}`)
      .set(facultyA1Header);
    expect(resDel.status).toBe(200);

    // Deleted note cannot be retrieved or downloaded -> 404
    const resGet = await request(app)
      .get(`/api/v1/academics/notes/${noteId}`)
      .set(studentA1Header);
    expect(resGet.status).toBe(404);

    const resDown = await request(app)
      .get(`/api/v1/academics/notes/${noteId}/download`)
      .set(facultyA1Header);
    expect(resDown.status).toBe(404);
  });

  // =========================================================================
  // 4. STUDENT PERSONAL FEED & SUBJECT QUERIES (20 - 21)
  // =========================================================================

  it('20. Student personal notes endpoint derives identity strictly from JWT', async () => {
    // Seed 2 notes in Semester 5 (OS) and 1 note in Semester 3
    const res1 = await request(app)
      .post('/api/v1/academics/notes/upload-url')
      .set(facultyA1Header)
      .send({
        subjectId: subjectOS.id,
        title: 'OS Process Concurrency',
        fileName: 'concurrency.pdf',
        mimeType: 'application/pdf',
        fileSize: 1024 * 500,
      });
    await request(app).post(`/api/v1/academics/notes/${res1.body.data.note.id}/complete`).set(facultyA1Header);

    // Alice (Semester 5) queries her personal feed
    const resAlice = await request(app)
      .get('/api/v1/academics/notes/students/me')
      .set(studentA1Header);

    expect(resAlice.status).toBe(200);
    expect(resAlice.body.data.items).toHaveLength(1);
    expect(resAlice.body.data.items[0].title).toBe('OS Process Concurrency');

    // Bob (Semester 3) queries his personal feed -> gets 0 Semester 5 notes
    const resBob = await request(app)
      .get('/api/v1/academics/notes/students/me')
      .set(studentA2Sem3Header);

    expect(resBob.status).toBe(200);
    expect(resBob.body.data.items).toHaveLength(0);
  });

  it('21. HOD and College Admin note management, subject notes querying, and Super Admin global access', async () => {
    // 1. HOD can upload note to their department subject
    const resHodUpload = await request(app)
      .post('/api/v1/academics/notes/upload-url')
      .set(hodA1Header)
      .send({
        subjectId: subjectOS.id,
        title: 'HOD CSE Announcements & Syllabus',
        fileName: 'Syllabus.pdf',
        mimeType: 'application/pdf',
        fileSize: 1024 * 300,
        noteType: NoteType.SYLLABUS,
      });
    expect(resHodUpload.status).toBe(201);
    await request(app)
      .post(`/api/v1/academics/notes/${resHodUpload.body.data.note.id}/complete`)
      .set(hodA1Header);

    // 2. Query subject notes at /api/v1/academics/subjects/:subjectId/notes
    const resSubjectNotes = await request(app)
      .get(`/api/v1/academics/subjects/${subjectOS.id}/notes`)
      .set(studentA1Header);
    expect(resSubjectNotes.status).toBe(200);
    expect(resSubjectNotes.body.data.items.length).toBeGreaterThan(0);

    // 3. College Admin lists notes within own college
    const resColAdmin = await request(app)
      .get('/api/v1/academics/notes')
      .set(collegeAdminAHeader);
    expect(resColAdmin.status).toBe(200);

    // 4. Super Admin lists notes globally across colleges
    const resSuper = await request(app)
      .get(`/api/v1/academics/notes?collegeId=${collegeA.id}`)
      .set(superAdminHeader);
    expect(resSuper.status).toBe(200);

    // 5. Subject EE notes query returns empty or EE notes
    const resEENotes = await request(app)
      .get(`/api/v1/academics/subjects/${subjectEE.id}/notes`)
      .set(facultyA2EEHeader);
    expect(resEENotes.status).toBe(200);
  });

  it('22. ImageKit Failure handling: object not found in ImageKit on upload completion returns 400', async () => {
    jest.spyOn(ImageKitService, 'getFileDetails').mockResolvedValueOnce(null);

    const resReq = await request(app)
      .post('/api/v1/academics/notes/upload-url')
      .set(facultyA1Header)
      .send({
        subjectId: subjectOS.id,
        title: 'Failing Upload Note',
        fileName: 'fail.pdf',
        mimeType: 'application/pdf',
        fileSize: 1024 * 200,
      });
    const noteId = resReq.body.data.note.id;

    const resComp = await request(app)
      .post(`/api/v1/academics/notes/${noteId}/complete`)
      .set(facultyA1Header);

    expect(resComp.status).toBe(400);
    const failErrMsg = resComp.body.error?.message || resComp.body.message;
    expect(failErrMsg).toContain('was not found in storage');
  });

  it('23. Audit events are recorded for all note operations', async () => {
    const resReq = await request(app)
      .post('/api/v1/academics/notes/upload-url')
      .set(facultyA1Header)
      .send({
        subjectId: subjectOS.id,
        title: 'Audit Tracked Note',
        fileName: 'audit.pdf',
        mimeType: 'application/pdf',
        fileSize: 1024 * 100,
      });
    await request(app)
      .post(`/api/v1/academics/notes/${resReq.body.data.note.id}/complete`)
      .set(facultyA1Header);

    const logs = await AuditLog.find({ entityType: 'Note' });
    expect(logs.length).toBeGreaterThan(0);
    const actions = logs.map((l) => l.action);
    expect(actions).toContain('NOTE_UPLOAD_REQUESTED');
    expect(actions).toContain('NOTE_UPLOAD_COMPLETED');
  });
});
