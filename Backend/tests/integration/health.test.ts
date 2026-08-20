import request from 'supertest';
import { app } from '../../src/app';
import { setupTestDB, teardownTestDB } from '../setup';

describe('GET /health and GET /api/v1/health API Endpoints', () => {
  beforeAll(async () => {
    await setupTestDB();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  it('should return 200 OK with connected database status at root /health', async () => {
    const res = await request(app).get('/health');

    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
    expect(res.body.service).toBe('acadex-backend');
    expect(res.body.database).toBe('connected');
    expect(res.body.timestamp).toBeDefined();
  });

  it('should return 200 OK with connected database status at versioned /api/v1/health', async () => {
    const res = await request(app).get('/api/v1/health');

    expect(res.status).toBe(200);
    expect(res.body.status).toBe('ok');
    expect(res.body.service).toBe('acadex-backend');
    expect(res.body.database).toBe('connected');
    expect(res.body.timestamp).toBeDefined();
  });

  it('should return 404 for unknown endpoints with structured error response', async () => {
    const res = await request(app).get('/api/v1/unknown-route-non-existent');

    expect(res.status).toBe(404);
    expect(res.body.success).toBe(false);
    expect(res.body.error.code).toBe('ROUTE_NOT_FOUND');
    expect(res.body.error.message).toContain('Route not found');
  });
});
