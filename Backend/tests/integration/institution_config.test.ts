import request from 'supertest';
import { app } from '../../src/app';
import { College } from '../../src/models/college.model';
import { User } from '../../src/models/user.model';
import { InstitutionConfiguration } from '../../src/models/institutionConfiguration.model';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';
import { AppRole } from '../../src/constants/roles';
import { InstitutionType } from '../../src/constants/institutionConfig.constants';

describe('Institution & Academic Configuration Core Integration Tests', () => {
  let collegeA: InstanceType<typeof College>;
  let collegeB: InstanceType<typeof College>;

  let collegeAdminA: InstanceType<typeof User>;
  let collegeAdminB: InstanceType<typeof User>;
  let hodUserA: InstanceType<typeof User>;
  let facultyUserA: InstanceType<typeof User>;
  let studentUserA: InstanceType<typeof User>;
  let superAdminUser: InstanceType<typeof User>;

  function authFor(user: any) {
    return createTestAuthHeader({
      userId: user._id.toString(),
      collegeId: user.collegeId ? user.collegeId.toString() : undefined,
      role: user.role,
      email: user.email,
      name: user.name,
    });
  }

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
      address: 'Campus A Road',
      email: 'admin@coea.edu',
      phone: '9876543210',
      principal: 'Dr. Principal A',
    });

    collegeB = await College.create({
      name: 'Polytechnic Institute B',
      code: 'POLY-B',
      address: 'Campus B Road',
      email: 'admin@polyb.edu',
      phone: '9876543211',
      principal: 'Dr. Principal B',
    });

    collegeAdminA = await User.create({
      instituteId: 'ADM-001',
      name: 'Admin A',
      email: 'admin@coea.edu',
      password: 'password123',
      role: AppRole.COLLEGE_ADMIN,
      collegeId: collegeA._id,
      phone: '9876543210',
    });

    collegeAdminB = await User.create({
      instituteId: 'ADM-002',
      name: 'Admin B',
      email: 'admin@polyb.edu',
      password: 'password123',
      role: AppRole.COLLEGE_ADMIN,
      collegeId: collegeB._id,
      phone: '9876543211',
    });

    hodUserA = await User.create({
      instituteId: 'HOD-001',
      name: 'Dr. HOD A',
      email: 'hod@coea.edu',
      password: 'password123',
      role: AppRole.HOD,
      collegeId: collegeA._id,
      phone: '9876543212',
    });

    facultyUserA = await User.create({
      instituteId: 'FAC-001',
      name: 'Prof. Faculty A',
      email: 'faculty@coea.edu',
      password: 'password123',
      role: AppRole.FACULTY,
      collegeId: collegeA._id,
      phone: '9876543213',
    });

    studentUserA = await User.create({
      instituteId: 'STU-001',
      name: 'Student A',
      email: 'student@coea.edu',
      password: 'password123',
      role: AppRole.STUDENT,
      collegeId: collegeA._id,
      phone: '9876543214',
    });

    superAdminUser = await User.create({
      instituteId: 'SUP-001',
      name: 'Super Admin',
      email: 'superadmin@acadex.edu',
      password: 'password123',
      role: AppRole.SUPER_ADMIN,
      phone: '9876543219',
    });
  });

  it('1. Default/legacy configuration works when no explicit configuration exists', async () => {
    const res = await request(app)
      .get('/api/v1/institution-config')
      .set(authFor(facultyUserA));

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.collegeId).toBe(collegeA._id.toString());
    expect(res.body.data.isConfigured).toBe(false);
    expect(res.body.data.institutionType).toBe(InstitutionType.ENGINEERING);
    expect(res.body.data.academicStructure.section).toBe(true);
    expect(res.body.data.terminology.program.singular).toBe('Course');
    expect(res.body.data.terminology.semester.singular).toBe('Semester');
  });

  it('2. College Admin can update institution configuration and terminology', async () => {
    const updatePayload = {
      institutionType: InstitutionType.POLYTECHNIC,
      academicStructure: {
        section: false,
        building: false,
        room: false,
      },
      terminology: {
        program: { singular: 'Diploma Program', plural: 'Diploma Programs' },
        semester: { singular: 'Term', plural: 'Terms' },
        section: { singular: 'Batch', plural: 'Batches' },
      },
    };

    const res = await request(app)
      .put('/api/v1/institution-config')
      .set(authFor(collegeAdminA))
      .send(updatePayload);

    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.isConfigured).toBe(true);
    expect(res.body.data.institutionType).toBe(InstitutionType.POLYTECHNIC);
    expect(res.body.data.academicStructure.section).toBe(false);
    expect(res.body.data.academicStructure.building).toBe(false);
    expect(res.body.data.academicStructure.room).toBe(false);
    expect(res.body.data.terminology.program.singular).toBe('Diploma Program');
    expect(res.body.data.terminology.semester.singular).toBe('Term');
  });

  it('3. Effective configuration is visible to students and faculty in the college', async () => {
    // Explicitly configure College A
    await InstitutionConfiguration.create({
      collegeId: collegeA._id,
      institutionType: InstitutionType.ARTS_AND_SCIENCE,
      academicStructure: {
        program: true,
        academicYear: true,
        semester: true,
        section: true,
        subject: true,
        building: true,
        room: true,
      },
      terminology: {
        program: { singular: 'Major', plural: 'Majors' },
        subject: { singular: 'Paper', plural: 'Papers' },
        section: { singular: 'Class', plural: 'Classes' },
      },
      isConfigured: true,
      updatedBy: collegeAdminA._id,
    });

    const res = await request(app)
      .get('/api/v1/institution-config')
      .set(authFor(studentUserA));

    expect(res.status).toBe(200);
    expect(res.body.data.isConfigured).toBe(true);
    expect(res.body.data.terminology.program.singular).toBe('Major');
    expect(res.body.data.terminology.subject.singular).toBe('Paper');
  });

  it('4. HOD cannot modify institution configuration', async () => {
    const res = await request(app)
      .put('/api/v1/institution-config')
      .set(authFor(hodUserA))
      .send({
        academicStructure: { section: false },
      });

    expect(res.status).toBe(403);
  });

  it('5. Faculty cannot modify institution configuration', async () => {
    const res = await request(app)
      .put('/api/v1/institution-config')
      .set(authFor(facultyUserA))
      .send({
        academicStructure: { section: false },
      });

    expect(res.status).toBe(403);
  });

  it('6. Student cannot modify institution configuration', async () => {
    const res = await request(app)
      .put('/api/v1/institution-config')
      .set(authFor(studentUserA))
      .send({
        academicStructure: { section: false },
      });

    expect(res.status).toBe(403);
  });

  it('7. Tenant isolation is enforced: College Admin of College A cannot mutate College B', async () => {
    // Attempt cross-college mutation
    const res = await request(app)
      .put('/api/v1/institution-config')
      .set(authFor(collegeAdminA))
      .send({
        collegeId: collegeB._id.toString(),
        academicStructure: { section: false },
      });

    expect(res.status).toBe(403);
  });

  it('8. College A configuration never leaks to College B', async () => {
    // Configure College A with section disabled
    await InstitutionConfiguration.create({
      collegeId: collegeA._id,
      institutionType: InstitutionType.POLYTECHNIC,
      academicStructure: {
        program: true,
        academicYear: true,
        semester: true,
        section: false,
        subject: true,
        building: false,
        room: false,
      },
      terminology: {
        program: { singular: 'Diploma', plural: 'Diplomas' },
      },
      isConfigured: true,
      updatedBy: collegeAdminA._id,
    });

    // College Admin B fetches their config (unconfigured, defaults)
    const resB = await request(app)
      .get('/api/v1/institution-config')
      .set(authFor(collegeAdminB));

    expect(resB.status).toBe(200);
    expect(resB.body.data.collegeId).toBe(collegeB._id.toString());
    // College B has default section = true, not College A's false
    expect(resB.body.data.academicStructure.section).toBe(true);
    expect(resB.body.data.terminology.program.singular).toBe('Course');
  });

  it('9. Presets endpoint returns standard onboarding templates', async () => {
    const res = await request(app)
      .get('/api/v1/institution-config/presets')
      .set(authFor(collegeAdminA));

    expect(res.status).toBe(200);
    expect(Array.isArray(res.body.data)).toBe(true);
    expect(res.body.data.some((p: any) => p.id === InstitutionType.ENGINEERING)).toBe(true);
    expect(res.body.data.some((p: any) => p.id === InstitutionType.POLYTECHNIC)).toBe(true);
    expect(res.body.data.some((p: any) => p.id === InstitutionType.ARTS_AND_SCIENCE)).toBe(true);
  });

  it('10. Validation rejects empty terminology labels', async () => {
    const res = await request(app)
      .put('/api/v1/institution-config')
      .set(authFor(collegeAdminA))
      .send({
        terminology: {
          program: { singular: '', plural: '' },
        },
      });

    expect(res.status).toBe(422);
  });

  it('11. Super Admin can update institution configuration with collegeId query parameter', async () => {
    const res = await request(app)
      .put(`/api/v1/institution-config?collegeId=${collegeA._id.toString()}`)
      .set(authFor(superAdminUser))
      .send({
        academicStructure: { building: false },
      });

    expect(res.status).toBe(200);
    expect(res.body.data.academicStructure.building).toBe(false);
  });
});
