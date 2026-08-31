import request from 'supertest';
import { createApp } from '../../src/app';
import { setupTestDB, teardownTestDB } from '../setup';

describe('ACADEX — Backend CORS & Preflight Integration Tests', () => {
  const app = createApp();

  beforeAll(async () => {
    await setupTestDB();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  describe('1. Dynamic Localhost Origin Handling (Flutter Web)', () => {
    it('allows OPTIONS preflight from dynamic localhost ports', async () => {
      const dynamicPorts = ['51218', '3000', '49152', '65535'];

      for (const port of dynamicPorts) {
        const origin = `http://localhost:${port}`;
        const res = await request(app)
          .options('/api/v1/auth/login')
          .set('Origin', origin)
          .set('Access-Control-Request-Method', 'POST')
          .set('Access-Control-Request-Headers', 'content-type,authorization,x-college-id');

        expect(res.status).toBe(204);
        expect(res.headers['access-control-allow-origin']).toBe(origin);
        expect(res.headers['access-control-allow-credentials']).toBe('true');
        expect(res.headers['access-control-allow-methods']).toContain('POST');
        expect(res.headers['access-control-allow-headers']).toContain('Content-Type');
        expect(res.headers['access-control-allow-headers']).toContain('Authorization');
      }
    });

    it('allows OPTIONS preflight from 127.0.0.1 IP origins', async () => {
      const origin = 'http://127.0.0.1:51218';
      const res = await request(app)
        .options('/api/v1/auth/login')
        .set('Origin', origin)
        .set('Access-Control-Request-Method', 'POST')
        .set('Access-Control-Request-Headers', 'content-type,authorization');

      expect(res.status).toBe(204);
      expect(res.headers['access-control-allow-origin']).toBe(origin);
      expect(res.headers['access-control-allow-credentials']).toBe('true');
    });

    it('returns CORS headers on actual POST /api/v1/auth/login response', async () => {
      const origin = 'http://localhost:51218';
      const res = await request(app)
        .post('/api/v1/auth/login')
        .set('Origin', origin)
        .send({
          identifier: 'invalid@acadex.edu',
          password: 'WrongPassword123!',
        });

      // Even on 401 Unauthorized, CORS headers MUST be present so browser doesn't throw XMLHttpRequest error
      expect(res.status).toBe(401);
      expect(res.headers['access-control-allow-origin']).toBe(origin);
      expect(res.headers['access-control-allow-credentials']).toBe('true');
    });
  });

  describe('2. Academic & Protected Endpoints Preflight', () => {
    it('handles preflight OPTIONS on GET /api/v1/academics/colleges', async () => {
      const origin = 'http://localhost:51218';
      const res = await request(app)
        .options('/api/v1/academics/colleges')
        .set('Origin', origin)
        .set('Access-Control-Request-Method', 'GET')
        .set('Access-Control-Request-Headers', 'authorization');

      expect(res.status).toBe(204);
      expect(res.headers['access-control-allow-origin']).toBe(origin);
      expect(res.headers['access-control-allow-methods']).toContain('GET');
    });

    it('handles preflight OPTIONS on PUT /api/v1/users/123', async () => {
      const origin = 'http://localhost:51218';
      const res = await request(app)
        .options('/api/v1/users/123')
        .set('Origin', origin)
        .set('Access-Control-Request-Method', 'PUT')
        .set('Access-Control-Request-Headers', 'content-type,authorization');

      expect(res.status).toBe(204);
      expect(res.headers['access-control-allow-origin']).toBe(origin);
      expect(res.headers['access-control-allow-methods']).toContain('PUT');
    });
  });

  describe('3. Non-Browser Clients & Server-to-Server Requests', () => {
    it('allows requests without Origin header (cURL, mobile native, health checks)', async () => {
      const res = await request(app).get('/health');
      expect(res.status).toBe(200);
      expect(res.body.status).toBe('ok');
    });
  });
});
