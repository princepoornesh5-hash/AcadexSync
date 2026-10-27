import request from 'supertest';
import mongoose from 'mongoose';
import { app } from '../../src/app';
import { College } from '../../src/models/college.model';
import { Department } from '../../src/models/department.model';
import { setupTestDB, teardownTestDB, clearTestDB } from '../setup';
import { createTestAuthHeader } from '../helpers/auth.helper';
import { User } from '../../src/models/user.model';
import { AccountStatus } from '../../src/constants/status';
import { AppRole } from '../../src/constants/roles';
import { AiService } from '../../src/services/ai.service';

describe('AI Chat Streaming Endpoint Integration Tests (SSE)', () => {
  let testCollege: InstanceType<typeof College>;
  let testDept: InstanceType<typeof Department>;
  let testFacultyUser: InstanceType<typeof User>;
  let otherCollege: InstanceType<typeof College>;
  let imposterUser: InstanceType<typeof User>;

  beforeAll(async () => {
    await setupTestDB();
  });

  afterAll(async () => {
    await teardownTestDB();
    AiService.clearMockClient();
  });

  beforeEach(async () => {
    await clearTestDB();
    AiService.clearMockClient();

    testCollege = await College.create({
      name: 'ACADEX Stream Institute',
      code: 'ASI',
      address: '100 Streaming Boulevard',
      email: 'contact@asi.edu',
      phone: '+1-555-0199',
      principal: 'Dr. Stream Director',
    });

    otherCollege = await College.create({
      name: 'Other Campus Institute',
      code: 'OCI',
      address: '200 Other Boulevard',
      email: 'contact@oci.edu',
      phone: '+1-555-0299',
      principal: 'Dr. Imposter Principal',
    });

    testDept = await Department.create({
      collegeId: testCollege._id,
      name: 'Computer Engineering',
      code: 'COE',
    });

    testFacultyUser = await User.create({
      _id: new mongoose.Types.ObjectId('65a123456789abcdef123450'),
      instituteId: 'FAC-STREAM-01',
      name: 'Prof. Dennis Ritchie',
      email: 'dennis.ritchie@asi.edu',
      role: AppRole.FACULTY,
      collegeId: testCollege._id,
      departmentId: testDept._id,
      accountStatus: AccountStatus.ACTIVE,
      activationStatus: 'activated',
    });

    imposterUser = await User.create({
      _id: new mongoose.Types.ObjectId('65a123456789abcdef123459'),
      instituteId: 'FAC-IMPOSTER-01',
      name: 'Prof. Cross Tenant',
      email: 'cross.tenant@oci.edu',
      role: AppRole.FACULTY,
      collegeId: otherCollege._id,
      accountStatus: AccountStatus.ACTIVE,
      activationStatus: 'activated',
    });
  });

  it('should reject unauthenticated stream request with 401 Unauthorized', async () => {
    const res = await request(app)
      .post('/api/v1/ai/chat/stream')
      .send({ message: 'Hello stream' });

    expect(res.status).toBe(401);
  });

  it('should reject cross-tenant stream request with 403 Forbidden', async () => {
    const authHeader = createTestAuthHeader({
      role: AppRole.FACULTY,
      userId: imposterUser.id,
      collegeId: otherCollege.id,
    });

    const res = await request(app)
      .post('/api/v1/ai/chat/stream')
      .set(authHeader)
      .send({
        message: 'Hello across tenant boundary',
        collegeId: testCollege.id, // attempting access to other college
      });

    expect(res.status).toBe(403);
  });

  it('should return SSE headers and stream chunks progressively via MockClient', async () => {
    const authHeader = createTestAuthHeader({
      role: AppRole.FACULTY,
      userId: testFacultyUser.id,
      collegeId: testCollege.id,
    });

    // Setup mock client that yields chunks
    const fakeChunks = [
      { text: 'Hello ' },
      { text: 'world! ' },
      { text: 'This is a genuine ' },
      { text: 'streamed response.' },
    ];

    async function* makeGenerator() {
      for (const chunk of fakeChunks) {
        yield chunk;
      }
    }

    AiService.setMockClient({
      models: {
        generateContentStream: jest.fn().mockResolvedValue(makeGenerator()),
      },
    } as any);

    const res = await request(app)
      .post('/api/v1/ai/chat/stream')
      .set(authHeader)
      .send({ message: 'Write a greeting' });

    expect(res.status).toBe(200);
    expect(res.headers['content-type']).toContain('text/event-stream');
    expect(res.headers['cache-control']).toBe('no-cache, no-transform');
    expect(res.headers['x-accel-buffering']).toBe('no');

    const bodyText = res.text;
    expect(bodyText).toContain('event: start');
    expect(bodyText).toContain('event: delta');
    expect(bodyText).toContain('Hello ');
    expect(bodyText).toContain('world! ');
    expect(bodyText).toContain('event: done');
  });

  it('should stream event: error when upstream Gemini generation throws', async () => {
    const authHeader = createTestAuthHeader({
      role: AppRole.FACULTY,
      userId: testFacultyUser.id,
      collegeId: testCollege.id,
    });

    AiService.setMockClient({
      models: {
        generateContentStream: jest.fn().mockRejectedValue(new Error('Upstream model unavailable')),
      },
    } as any);

    const res = await request(app)
      .post('/api/v1/ai/chat/stream')
      .set(authHeader)
      .send({ message: 'Trigger error' });

    expect(res.status).toBe(200); // SSE connections start 200, errors streamed as SSE event
    expect(res.text).toContain('event: error');
    expect(res.text).toContain('AI_PROVIDER_UNAVAILABLE');
  });
});
