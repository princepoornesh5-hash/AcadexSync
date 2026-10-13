import request from 'supertest';
import * as XLSX from 'xlsx';
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
  StudentEnrollment,
} from '../../src/models';
import { AppRole } from '../../src/constants/roles';
import {
  ImportDataType,
  ImportBatchStatus,
  RowValidationStatus,
} from '../../src/constants/import.constants';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';

describe('PROMPT 4/6 — Legacy Excel/CSV Import Foundation & Context Resolution', () => {
  let collegeA: any;
  let collegeB: any;
  let departmentA: any;
  let courseA: any;
  let academicYearA: any;
  let semesterA: any;
  let sectionA: any;
  let sectionB: any;
  let subjectIME: any;

  let adminUserA: any;
  let facultyUserA: any;
  let studentUserA: any;
  let adminUserB: any;

  let studentDocsA: any[] = [];
  let studentEnrollmentsA: any[] = [];
  let studentDocB: any;
  let studentEnrollmentB: any;

  function authHeader(user: any, collegeId?: string): string {
    return createTestAuthHeader({
      userId: user._id.toString(),
      collegeId: collegeId || user.collegeId.toString(),
      role: user.role,
      email: user.email,
      name: user.name,
    }).Authorization;
  }

  const getErrorMessage = (res: request.Response): string => {
    return res.body?.error?.message || res.body?.message || JSON.stringify(res.body);
  };

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
      code: 'COLA-IMP',
      address: 'Campus A',
      email: 'admin@cola-imp.edu',
      phone: '9000000001',
      principal: 'Dr. Principal A',
      status: 'active',
    });

    collegeB = await College.create({
      name: 'College of Technology B',
      code: 'COLB-IMP',
      address: 'Campus B',
      email: 'admin@colb-imp.edu',
      phone: '9000000002',
      principal: 'Dr. Principal B',
      status: 'active',
    });

    // 2. Hierarchy in College A
    departmentA = await Department.create({
      collegeId: collegeA._id,
      name: 'Computer Science & Engineering',
      code: 'CSE-IMP',
      status: 'active',
    });

    courseA = await Course.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      name: 'Diploma in Computer Engineering',
      code: 'DCE-IMP',
      durationYears: 3,
      status: 'active',
    });

    academicYearA = await AcademicYear.create({
      collegeId: collegeA._id,
      name: '2026-2027',
      code: 'AY26-27-IMP',
      startDate: new Date('2026-06-01'),
      endDate: new Date('2027-05-31'),
      status: 'active',
      isCurrent: true,
    });

    semesterA = await Semester.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      name: 'Semester 5',
      number: 5,
      type: 'ODD',
      startDate: new Date('2026-06-01'),
      endDate: new Date('2026-11-30'),
      isCurrent: true,
      status: 'active',
    });

    sectionA = await Section.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      name: 'A',
      capacity: 60,
    });

    sectionB = await Section.create({
      collegeId: collegeA._id,
      departmentId: departmentA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      name: 'B',
      capacity: 60,
    });

    subjectIME = await Subject.create({
      collegeId: collegeA._id,
      courseId: courseA._id,
      departmentId: departmentA._id,
      semesterId: semesterA._id,
      name: 'Information Management & Enterprise Systems',
      code: 'IME-501',
      type: 'THEORY',
      credits: 4,
    });

    // 3. Users in College A
    adminUserA = await User.create({
      collegeId: collegeA._id,
      email: 'admin@cola-imp.edu',
      password: 'password123',
      name: 'Dean Admin A',
      role: AppRole.COLLEGE_ADMIN,
    });

    facultyUserA = await User.create({
      collegeId: collegeA._id,
      email: 'faculty@cola-imp.edu',
      password: 'password123',
      name: 'Prof. Ada Lovelace',
      role: AppRole.FACULTY,
    });

    studentUserA = await User.create({
      collegeId: collegeA._id,
      email: 'student@cola-imp.edu',
      password: 'password123',
      name: 'Student Unauthorized',
      role: AppRole.STUDENT,
    });

    // 4. User in College B
    adminUserB = await User.create({
      collegeId: collegeB._id,
      email: 'admin@colb-imp.edu',
      password: 'password123',
      name: 'Dean Admin B',
      role: AppRole.COLLEGE_ADMIN,
    });

    // 5. Students in Section A (Students 1 to 5)
    studentDocsA = [];
    studentEnrollmentsA = [];
    for (let i = 1; i <= 5; i++) {
      const u = await User.create({
        collegeId: collegeA._id,
        email: `student_imp${i}@cola.edu`,
        password: 'password123',
        name: `Student ${i}`,
        role: AppRole.STUDENT,
      });

      const s = await Student.create({
        collegeId: collegeA._id,
        userId: u._id,
        departmentId: departmentA._id,
        courseId: courseA._id,
        name: `Student ${i}`,
        email: `student_imp${i}@cola.edu`,
        admissionNumber: `ADM-2026-00${i}`,
        instituteId: `23A00${i}`, // Student PIN
        rollNumber: `CS50${i}`,
        status: 'active',
        academicYearId: academicYearA._id,
      });
      studentDocsA.push(s);

      const se = await StudentEnrollment.create({
        collegeId: collegeA._id,
        studentId: s._id,
        departmentId: departmentA._id,
        courseId: courseA._id,
        academicYearId: academicYearA._id,
        semesterId: semesterA._id,
        sectionId: sectionA._id,
        rollNumber: `CS50${i}`,
        status: 'active',
        enrollmentDate: new Date('2026-06-01'),
      });
      studentEnrollmentsA.push(se);
    }

    // 6. Student in Section B (Out-of-context for Section A imports)
    const uB = await User.create({
      collegeId: collegeA._id,
      email: 'student_sec_b@cola.edu',
      password: 'password123',
      name: 'Student Section B',
      role: AppRole.STUDENT,
    });
    studentDocB = await Student.create({
      collegeId: collegeA._id,
      userId: uB._id,
      departmentId: departmentA._id,
      courseId: courseA._id,
      name: 'Student Section B',
      email: 'student_sec_b@cola.edu',
      admissionNumber: 'ADM-2026-099',
      instituteId: '23B099', // PIN in Section B
      rollNumber: 'CS599',
      status: 'active',
      academicYearId: academicYearA._id,
    });
    studentEnrollmentB = await StudentEnrollment.create({
      collegeId: collegeA._id,
      studentId: studentDocB._id,
      departmentId: departmentA._id,
      courseId: courseA._id,
      academicYearId: academicYearA._id,
      semesterId: semesterA._id,
      sectionId: sectionB._id,
      rollNumber: 'CS599',
      status: 'active',
      enrollmentDate: new Date('2026-06-01'),
    });
  });

  // ============================================================
  // TEST SUITE: 20 TARGETED PROMPT 4 REQUIREMENTS
  // ============================================================

  // 1. CSV parsing
  test('1. CSV parsing: successfully parses clean CSV buffer with headers and quotes', async () => {
    const csvContent =
      'PIN,Student Name,Marks,Status\n' +
      '"23A001","Student 1",20,PRESENT\n' +
      '"23A002","Student 2",0,PRESENT\n' +
      '"23A003","Student 3",,ABSENT\n';

    const base64 = Buffer.from(csvContent).toString('base64');

    const res = await request(app)
      .post('/api/v1/imports/upload')
      .set('Authorization', authHeader(adminUserA))
      .send({
        fileName: 'internal_marks.csv',
        fileBase64: base64,
        dataType: ImportDataType.ASSESSMENT,
        sectionId: sectionA._id.toString(),
        academicYearId: academicYearA._id.toString(),
        semesterId: semesterA._id.toString(),
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.batch.fileType).toBe('CSV');
    expect(res.body.data.batch.rowCount).toBe(3);
    expect(res.body.data.batch.headers).toEqual(['PIN', 'Student Name', 'Marks', 'Status']);
  });

  // 2. XLSX parsing
  test('2. XLSX parsing: successfully parses Excel workbook buffer', async () => {
    const wb = XLSX.utils.book_new();
    const wsData = [
      ['Student PIN', 'Full Name', 'Internal Marks'],
      ['23A001', 'Student 1', 22],
      ['23A002', 'Student 2', 18],
    ];
    const ws = XLSX.utils.aoa_to_sheet(wsData);
    XLSX.utils.book_append_sheet(wb, ws, 'MarksSheet');
    const xlsxBuffer = XLSX.write(wb, { type: 'buffer', bookType: 'xlsx' });
    const base64 = Buffer.from(xlsxBuffer).toString('base64');

    const res = await request(app)
      .post('/api/v1/imports/upload')
      .set('Authorization', authHeader(adminUserA))
      .send({
        fileName: 'marks_2026.xlsx',
        fileBase64: base64,
        dataType: ImportDataType.ASSESSMENT,
      });

    expect(res.status).toBe(201);
    expect(res.body.success).toBe(true);
    expect(res.body.data.batch.fileType).toBe('XLSX');
    expect(res.body.data.batch.rowCount).toBe(2);
    expect(res.body.data.batch.selectedSheet).toBe('MarksSheet');
  });

  // 3. Multi-sheet detection
  test('3. Multi-sheet detection: inspects all sheets and returns sheet metadata', async () => {
    const wb = XLSX.utils.book_new();
    const ws1 = XLSX.utils.aoa_to_sheet([['PIN', 'Marks'], ['23A001', 25]]);
    const ws2 = XLSX.utils.aoa_to_sheet([['Roll No', 'Attendance'], ['CS501', 'P']]);
    XLSX.utils.book_append_sheet(wb, ws1, 'InternalMarks');
    XLSX.utils.book_append_sheet(wb, ws2, 'AttendanceRecord');
    const buffer = XLSX.write(wb, { type: 'buffer', bookType: 'xlsx' });

    const res = await request(app)
      .post('/api/v1/imports/upload')
      .set('Authorization', authHeader(adminUserA))
      .send({
        fileName: 'multi_sheet.xlsx',
        fileBase64: Buffer.from(buffer).toString('base64'),
        dataType: ImportDataType.ASSESSMENT,
      });

    expect(res.status).toBe(201);
    expect(res.body.data.batch.sheetNames).toEqual(['InternalMarks', 'AttendanceRecord']);
    expect(res.body.data.sheetMetadata).toHaveLength(2);
    expect(res.body.data.sheetMetadata[0].sheetName).toBe('InternalMarks');
    expect(res.body.data.sheetMetadata[1].sheetName).toBe('AttendanceRecord');
  });

  // 4. Header detection
  test('4. Header detection: detects real table header row below title/college banner rows', async () => {
    const wb = XLSX.utils.book_new();
    const wsData = [
      ['SRI VENKATESWARA GOVERNMENT POLYTECHNIC'], // Row 1: College Banner
      ['Department of Computer Engineering - 5th Semester'], // Row 2: Metadata title
      ['PIN', 'Student Name', 'IME UT1', 'Status'], // Row 3: Real Header (0-indexed row 2)
      ['23A001', 'Student 1', 24, 'PRESENT'],
      ['23A002', 'Student 2', 19, 'PRESENT'],
    ];
    const ws = XLSX.utils.aoa_to_sheet(wsData);
    XLSX.utils.book_append_sheet(wb, ws, 'Marks');
    const buffer = XLSX.write(wb, { type: 'buffer', bookType: 'xlsx' });

    const res = await request(app)
      .post('/api/v1/imports/upload')
      .set('Authorization', authHeader(adminUserA))
      .send({
        fileName: 'banner_header.xlsx',
        fileBase64: Buffer.from(buffer).toString('base64'),
        dataType: ImportDataType.ASSESSMENT,
      });

    expect(res.status).toBe(201);
    expect(res.body.data.batch.detectedHeaderRow).toBe(2); // 0-indexed row 2
    expect(res.body.data.batch.headers).toEqual(['PIN', 'Student Name', 'IME UT1', 'Status']);
    expect(res.body.data.batch.rowCount).toBe(2);
  });

  // 5. Column normalization
  test('5. Column normalization: automatically maps common aliases to canonical target fields', async () => {
    const csvContent = 'Pin No,Candidate Name,UT-1,Max Marks\n23A001,Student 1,22,25\n';
    const res = await request(app)
      .post('/api/v1/imports/upload')
      .set('Authorization', authHeader(adminUserA))
      .send({
        fileName: 'norm.csv',
        fileBase64: Buffer.from(csvContent).toString('base64'),
        dataType: ImportDataType.ASSESSMENT,
      });

    expect(res.status).toBe(201);
    const mappings = res.body.data.batch.columnMappings;

    const pinMapping = mappings.find((m: any) => m.sourceColumn === 'Pin No');
    expect(pinMapping?.targetField).toBe('studentPin');

    const nameMapping = mappings.find((m: any) => m.sourceColumn === 'Candidate Name');
    expect(nameMapping?.targetField).toBe('studentName');

    const marksMapping = mappings.find((m: any) => m.sourceColumn === 'UT-1');
    expect(marksMapping?.targetField).toBe('marks');
  });

  // 6. Ambiguous column handling
  test('6. Ambiguous column handling: flags duplicate or ambiguous target field columns', async () => {
    // Both 'UT1' and 'UT2' could match 'marks'
    const csvContent = 'PIN,UT1,UT2\n23A001,20,22\n';
    const res = await request(app)
      .post('/api/v1/imports/upload')
      .set('Authorization', authHeader(adminUserA))
      .send({
        fileName: 'ambiguous.csv',
        fileBase64: Buffer.from(csvContent).toString('base64'),
        dataType: ImportDataType.ASSESSMENT,
      });

    expect(res.status).toBe(201);
    const mappings = res.body.data.batch.columnMappings;
    const ut2Mapping = mappings.find((m: any) => m.sourceColumn === 'UT2');
    expect(ut2Mapping?.status).toBe('AMBIGUOUS');
  });

  // 7. Context resolution
  test('7. Context resolution: validates and resolves academic hierarchy by ID and name', async () => {
    const csvContent = 'PIN,Marks\n23A001,20\n';
    const uploadRes = await request(app)
      .post('/api/v1/imports/upload')
      .set('Authorization', authHeader(adminUserA))
      .send({
        fileName: 'ctx.csv',
        fileBase64: Buffer.from(csvContent).toString('base64'),
        dataType: ImportDataType.ASSESSMENT,
      });

    const batchId = uploadRes.body.data.batch._id;

    const previewRes = await request(app)
      .post(`/api/v1/imports/${batchId}/validate`)
      .set('Authorization', authHeader(adminUserA))
      .send({
        academicYearId: academicYearA._id.toString(),
        semesterId: semesterA._id.toString(),
        sectionId: sectionA._id.toString(),
        subjectId: subjectIME._id.toString(),
      });

    expect(previewRes.status).toBe(200);
    expect(previewRes.body.data.resolvedContext.sectionId).toBe(sectionA._id.toString());
    expect(previewRes.body.data.resolvedContext.semesterId).toBe(semesterA._id.toString());
  });

  // 8. Student PIN resolution
  test('8. Student PIN resolution: resolves student using canonical institution PIN', async () => {
    const csvContent = 'PIN,Marks\n23A001,23\n';
    const uploadRes = await request(app)
      .post('/api/v1/imports/upload')
      .set('Authorization', authHeader(adminUserA))
      .send({
        fileName: 'pin_test.csv',
        fileBase64: Buffer.from(csvContent).toString('base64'),
        dataType: ImportDataType.ASSESSMENT,
      });

    const batchId = uploadRes.body.data.batch._id;

    const previewRes = await request(app)
      .post(`/api/v1/imports/${batchId}/validate`)
      .set('Authorization', authHeader(adminUserA))
      .send({
        sectionId: sectionA._id.toString(),
        academicYearId: academicYearA._id.toString(),
        semesterId: semesterA._id.toString(),
      });

    expect(previewRes.status).toBe(200);
    expect(previewRes.body.data.summary.validCount).toBe(1);
    expect(previewRes.body.data.previewRows[0].studentResolution.studentEnrollmentId).toBe(
      studentEnrollmentsA[0]._id.toString()
    );
    expect(previewRes.body.data.previewRows[0].status).toBe(RowValidationStatus.VALID);
  });

  // 9. Student context mismatch
  test('9. Student context mismatch: marks student as INVALID if enrolled in another section', async () => {
    // 23B099 belongs to Section B, but we validate against Section A
    const csvContent = 'PIN,Marks\n23B099,20\n';
    const uploadRes = await request(app)
      .post('/api/v1/imports/upload')
      .set('Authorization', authHeader(adminUserA))
      .send({
        fileName: 'mismatch.csv',
        fileBase64: Buffer.from(csvContent).toString('base64'),
        dataType: ImportDataType.ASSESSMENT,
      });

    const batchId = uploadRes.body.data.batch._id;

    const previewRes = await request(app)
      .post(`/api/v1/imports/${batchId}/validate`)
      .set('Authorization', authHeader(adminUserA))
      .send({
        sectionId: sectionA._id.toString(),
        academicYearId: academicYearA._id.toString(),
        semesterId: semesterA._id.toString(),
      });

    expect(studentDocB.instituteId).toBe('23B099');
    expect(studentEnrollmentB.sectionId).toEqual(sectionB._id);
    expect(studentDocsA).toHaveLength(5);
    expect(previewRes.status).toBe(200);
    expect(previewRes.body.data.summary.errorCount).toBe(1);
    expect(previewRes.body.data.previewRows[0].status).toBe(RowValidationStatus.INVALID);
    expect(previewRes.body.data.previewRows[0].issues[0].message).toContain('not enrolled in the selected academic section');
  });

  // 10. Unresolved student handling
  test('10. Unresolved student handling: unknown PIN produces STUDENT_NOT_FOUND error', async () => {
    const csvContent = 'PIN,Marks\nUNKNOWN_PIN_999,20\n';
    const uploadRes = await request(app)
      .post('/api/v1/imports/upload')
      .set('Authorization', authHeader(adminUserA))
      .send({
        fileName: 'unknown.csv',
        fileBase64: Buffer.from(csvContent).toString('base64'),
        dataType: ImportDataType.ASSESSMENT,
      });

    const batchId = uploadRes.body.data.batch._id;

    const previewRes = await request(app)
      .post(`/api/v1/imports/${batchId}/validate`)
      .set('Authorization', authHeader(adminUserA))
      .send({
        sectionId: sectionA._id.toString(),
        academicYearId: academicYearA._id.toString(),
        semesterId: semesterA._id.toString(),
      });

    expect(previewRes.status).toBe(200);
    expect(previewRes.body.data.summary.errorCount).toBe(1);
    expect(previewRes.body.data.previewRows[0].issues[0].code).toBe('STUDENT_NOT_FOUND');
  });

  // 11. Duplicate row detection
  test('11. Duplicate row detection: identical duplicate rows are flagged with DUPLICATE_ROW warning', async () => {
    const csvContent =
      'PIN,Marks\n' +
      '23A001,20\n' +
      '23A001,20\n'; // Identical values for same student

    const uploadRes = await request(app)
      .post('/api/v1/imports/upload')
      .set('Authorization', authHeader(adminUserA))
      .send({
        fileName: 'dups.csv',
        fileBase64: Buffer.from(csvContent).toString('base64'),
        dataType: ImportDataType.ASSESSMENT,
      });

    const batchId = uploadRes.body.data.batch._id;

    const previewRes = await request(app)
      .post(`/api/v1/imports/${batchId}/validate`)
      .set('Authorization', authHeader(adminUserA))
      .send({
        sectionId: sectionA._id.toString(),
        academicYearId: academicYearA._id.toString(),
        semesterId: semesterA._id.toString(),
      });

    expect(previewRes.status).toBe(200);
    expect(previewRes.body.data.summary.warningCount).toBeGreaterThanOrEqual(1);
    expect(previewRes.body.data.previewRows[0].issues.some((i: any) => i.code === 'DUPLICATE_ROW')).toBe(true);
  });

  // 12. Conflicting row detection
  test('12. Conflicting row detection: conflicting marks across rows flagged as DUPLICATE_CONFLICT', async () => {
    const csvContent =
      'PIN,Marks\n' +
      '23A001,20\n' +
      '23A001,15\n'; // Conflicting marks (20 vs 15)

    const uploadRes = await request(app)
      .post('/api/v1/imports/upload')
      .set('Authorization', authHeader(adminUserA))
      .send({
        fileName: 'conflict.csv',
        fileBase64: Buffer.from(csvContent).toString('base64'),
        dataType: ImportDataType.ASSESSMENT,
      });

    const batchId = uploadRes.body.data.batch._id;

    const previewRes = await request(app)
      .post(`/api/v1/imports/${batchId}/validate`)
      .set('Authorization', authHeader(adminUserA))
      .send({
        sectionId: sectionA._id.toString(),
        academicYearId: academicYearA._id.toString(),
        semesterId: semesterA._id.toString(),
      });

    expect(previewRes.status).toBe(200);
    expect(previewRes.body.data.summary.conflictCount).toBeGreaterThanOrEqual(1);
    expect(previewRes.body.data.previewRows[0].status).toBe(RowValidationStatus.DUPLICATE_CONFLICT);
  });

  // 13. Preview generation
  test('13. Preview generation: summarizes valid, warning, error, and conflict counts with sample rows', async () => {
    const csvContent =
      'PIN,Marks\n' +
      '23A001,20\n' + // Valid
      '23A002,25\n' + // Valid
      'INVALID_PIN,15\n'; // Invalid

    const uploadRes = await request(app)
      .post('/api/v1/imports/upload')
      .set('Authorization', authHeader(adminUserA))
      .send({
        fileName: 'preview_test.csv',
        fileBase64: Buffer.from(csvContent).toString('base64'),
        dataType: ImportDataType.ASSESSMENT,
      });

    const batchId = uploadRes.body.data.batch._id;

    const previewRes = await request(app)
      .post(`/api/v1/imports/${batchId}/validate`)
      .set('Authorization', authHeader(adminUserA))
      .send({
        sectionId: sectionA._id.toString(),
        academicYearId: academicYearA._id.toString(),
        semesterId: semesterA._id.toString(),
      });

    expect(previewRes.status).toBe(200);
    expect(previewRes.body.data.summary.rowCount).toBe(3);
    expect(previewRes.body.data.summary.validCount).toBe(2);
    expect(previewRes.body.data.summary.errorCount).toBe(1);
    expect(previewRes.body.data.previewRows).toHaveLength(3);
  });

  // 14. Import confirmation
  test('14. Import confirmation: successful explicit confirmation transitions batch to COMPLETED', async () => {
    const csvContent = 'PIN,Marks\n23A001,21\n23A002,19\n';
    const uploadRes = await request(app)
      .post('/api/v1/imports/upload')
      .set('Authorization', authHeader(adminUserA))
      .send({
        fileName: 'confirm_test.csv',
        fileBase64: Buffer.from(csvContent).toString('base64'),
        dataType: ImportDataType.ASSESSMENT,
      });

    const batchId = uploadRes.body.data.batch._id;

    // Must validate first
    await request(app)
      .post(`/api/v1/imports/${batchId}/validate`)
      .set('Authorization', authHeader(adminUserA))
      .send({
        sectionId: sectionA._id.toString(),
        academicYearId: academicYearA._id.toString(),
        semesterId: semesterA._id.toString(),
      });

    const confirmRes = await request(app)
      .post(`/api/v1/imports/${batchId}/confirm`)
      .set('Authorization', authHeader(adminUserA))
      .send({ allowPartial: false });

    expect(confirmRes.status).toBe(200);
    expect(confirmRes.body.data.importedCount).toBe(2);
    expect(confirmRes.body.data.failedCount).toBe(0);
    expect(confirmRes.body.data.batch.status).toBe(ImportBatchStatus.COMPLETED);
  });

  // 15. Partial import accounting
  test('15. Partial import accounting: imports only valid rows when allowPartial=true and records counts', async () => {
    const csvContent =
      'PIN,Marks\n' +
      '23A001,20\n' + // Valid
      'INVALID_PIN,15\n'; // Invalid

    const uploadRes = await request(app)
      .post('/api/v1/imports/upload')
      .set('Authorization', authHeader(adminUserA))
      .send({
        fileName: 'partial_test.csv',
        fileBase64: Buffer.from(csvContent).toString('base64'),
        dataType: ImportDataType.ASSESSMENT,
      });

    const batchId = uploadRes.body.data.batch._id;

    await request(app)
      .post(`/api/v1/imports/${batchId}/validate`)
      .set('Authorization', authHeader(adminUserA))
      .send({
        sectionId: sectionA._id.toString(),
        academicYearId: academicYearA._id.toString(),
        semesterId: semesterA._id.toString(),
      });

    // 1. Without allowPartial: rejected
    const blockedRes = await request(app)
      .post(`/api/v1/imports/${batchId}/confirm`)
      .set('Authorization', authHeader(adminUserA))
      .send({ allowPartial: false });
    expect(blockedRes.status).toBe(400);

    // 2. With allowPartial: true: succeeds with partial accounting
    const partialRes = await request(app)
      .post(`/api/v1/imports/${batchId}/confirm`)
      .set('Authorization', authHeader(adminUserA))
      .send({ allowPartial: true });

    expect(partialRes.status).toBe(200);
    expect(partialRes.body.data.importedCount).toBe(1);
    expect(partialRes.body.data.failedCount).toBe(1);
    expect(partialRes.body.data.batch.status).toBe(ImportBatchStatus.PARTIALLY_COMPLETED);
  });

  // 16. Tenant isolation
  test('16. Tenant isolation: College B cannot resolve, view, or confirm College A import batch', async () => {
    const csvContent = 'PIN,Marks\n23A001,20\n';
    const uploadRes = await request(app)
      .post('/api/v1/imports/upload')
      .set('Authorization', authHeader(adminUserA))
      .send({
        fileName: 'tenant_test.csv',
        fileBase64: Buffer.from(csvContent).toString('base64'),
        dataType: ImportDataType.ASSESSMENT,
      });

    const batchId = uploadRes.body.data.batch._id;

    // Admin B from College B attempts to view Batch A
    const crossRes = await request(app)
      .get(`/api/v1/imports/${batchId}`)
      .set('Authorization', authHeader(adminUserB));

    expect(crossRes.status).toBe(404);
  });

  // 17. Import batch ownership & role authorization
  test('17. Import batch authorization: Students are strictly forbidden from import APIs', async () => {
    const csvContent = 'PIN,Marks\n23A001,20\n';
    const res = await request(app)
      .post('/api/v1/imports/upload')
      .set('Authorization', authHeader(studentUserA))
      .send({
        fileName: 'student_illegal.csv',
        fileBase64: Buffer.from(csvContent).toString('base64'),
        dataType: ImportDataType.ASSESSMENT,
      });

    expect(res.status).toBe(403);

    // Faculty is permitted
    const facRes = await request(app)
      .post('/api/v1/imports/upload')
      .set('Authorization', authHeader(facultyUserA))
      .send({
        fileName: 'faculty_allowed.csv',
        fileBase64: Buffer.from(csvContent).toString('base64'),
        dataType: ImportDataType.ASSESSMENT,
      });
    expect(facRes.status).toBe(201);
  });

  // 18. Malformed file rejection
  test('18. Malformed file rejection: rejects corrupted or unreadable file buffer', async () => {
    const corruptBase64 = Buffer.from('NOT_A_VALID_EXCEL_OR_CSV_FILE_CORRUPTED_STREAM').toString('base64');
    const res = await request(app)
      .post('/api/v1/imports/upload')
      .set('Authorization', authHeader(adminUserA))
      .send({
        fileName: 'corrupt.xlsx',
        fileBase64: corruptBase64,
        dataType: ImportDataType.ASSESSMENT,
      });

    expect(res.status).toBe(400);
  });

  // 19. File-size limits
  test('19. File-size limits: rejects files exceeding maximum size limit', async () => {
    // 11 MB buffer
    const hugeBuffer = Buffer.alloc(11 * 1024 * 1024, 'a');
    const res = await request(app)
      .post('/api/v1/imports/upload')
      .set('Authorization', authHeader(adminUserA))
      .send({
        fileName: 'huge.csv',
        fileBase64: hugeBuffer.toString('base64'),
        dataType: ImportDataType.ASSESSMENT,
      });

    expect(res.status).toBe(400);
    expect(getErrorMessage(res)).toContain('exceeds maximum permitted limit');
  });

  // 20. Idempotent / repeat import protection foundation
  test('20. Idempotent repeat confirmation: repeating confirm on completed batch is safe and does not double-count', async () => {
    const csvContent = 'PIN,Marks\n23A001,20\n';
    const uploadRes = await request(app)
      .post('/api/v1/imports/upload')
      .set('Authorization', authHeader(adminUserA))
      .send({
        fileName: 'idempotent.csv',
        fileBase64: Buffer.from(csvContent).toString('base64'),
        dataType: ImportDataType.ASSESSMENT,
      });

    const batchId = uploadRes.body.data.batch._id;

    await request(app)
      .post(`/api/v1/imports/${batchId}/validate`)
      .set('Authorization', authHeader(adminUserA))
      .send({
        sectionId: sectionA._id.toString(),
        academicYearId: academicYearA._id.toString(),
        semesterId: semesterA._id.toString(),
      });

    // First confirm
    const firstConfirm = await request(app)
      .post(`/api/v1/imports/${batchId}/confirm`)
      .set('Authorization', authHeader(adminUserA))
      .send({ allowPartial: false });
    expect(firstConfirm.status).toBe(200);

    // Second confirm on same batch
    const secondConfirm = await request(app)
      .post(`/api/v1/imports/${batchId}/confirm`)
      .set('Authorization', authHeader(adminUserA))
      .send({ allowPartial: false });

    expect(secondConfirm.status).toBe(200);
    expect(secondConfirm.body.data.message).toContain('already been completed');
    expect(secondConfirm.body.data.importedCount).toBe(1);
  });
});
