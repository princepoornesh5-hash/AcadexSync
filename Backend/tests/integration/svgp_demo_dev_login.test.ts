import request from 'supertest';
import { app } from '../../src/app';
import { connectDB, disconnectDB } from '../../src/db/connection';
import { AppRole } from '../../src/constants/roles';
import { env } from '../../src/config/env';
import { AuthService } from '../../src/services/auth.service';

describe('SVGP Demo Environment & Authoritative Dev-Login Integration Tests', () => {
  beforeAll(async () => {
    await connectDB();
  });

  afterAll(async () => {
    await disconnectDB();
  });

  describe('1. Authoritative Development Login (POST /api/v1/auth/dev-login)', () => {
    const rolesToTest = [
      { role: AppRole.SUPER_ADMIN, expectedEmail: 'admin@acadex.com' },
      { role: AppRole.COLLEGE_ADMIN, expectedEmail: 'college@acadex.com' },
      { role: AppRole.HOD, expectedEmail: 'hod@acadex.com' },
      { role: AppRole.FACULTY, expectedEmail: 'faculty@acadex.com' },
      { role: AppRole.STUDENT, expectedEmail: 'student@acadex.com' },
    ];

    for (const { role, expectedEmail } of rolesToTest) {
      it(`should successfully authenticate as ${role} and return valid JWT tokens and workspace`, async () => {
        const res = await request(app)
          .post('/api/v1/auth/dev-login')
          .send({ role })
          .expect(200);

        expect(res.body.success).toBe(true);
        expect(res.body.data).toHaveProperty('accessToken');
        expect(res.body.data).toHaveProperty('refreshToken');
        expect(res.body.data).toHaveProperty('user');
        expect(res.body.data.user.email).toBe(expectedEmail);
        expect(res.body.data.user.role).toBe(role);

        if (role !== AppRole.SUPER_ADMIN) {
          expect(res.body.data).toHaveProperty('workspaceId');
          expect(res.body.data.workspaceId).toBeTruthy();
        }
      });
    }

    it('should reject invalid or missing role payloads', async () => {
      const res = await request(app)
        .post('/api/v1/auth/dev-login')
        .send({ role: 'NON_EXISTENT_ROLE' })
        .expect(400);

      expect(res.body.success).toBe(false);
    });
  });

  describe('2. End-to-End Operational Dashboard Verification with SVGP Session', () => {
    let collegeAdminToken: string;
    let svgpWorkspaceId: string;

    beforeAll(async () => {
      const loginRes = await request(app)
        .post('/api/v1/auth/dev-login')
        .send({ role: AppRole.COLLEGE_ADMIN });

      collegeAdminToken = loginRes.body.data.accessToken;
      svgpWorkspaceId = loginRes.body.data.workspaceId;
    });

    it('should successfully access /dashboard/home without session expiration', async () => {
      const res = await request(app)
        .get('/api/v1/dashboard/home')
        .set('Authorization', `Bearer ${collegeAdminToken}`)
        .set('X-Workspace-Id', svgpWorkspaceId)
        .expect(200);

      expect(res.body.success).toBe(true);
      expect(res.body.data.role).toBe(AppRole.COLLEGE_ADMIN);
      expect(res.body.data.context.collegeCode).toBe('SVGP');
      expect(res.body.data.summary.departmentsCount).toBe(6);
      expect(res.body.data.summary.facultyCount).toBeGreaterThanOrEqual(18);
      expect(res.body.data.summary.studentsCount).toBeGreaterThanOrEqual(36);
    });

    it('should successfully access /reports/dashboard with relational metrics', async () => {
      const res = await request(app)
        .get('/api/v1/reports/dashboard')
        .set('Authorization', `Bearer ${collegeAdminToken}`)
        .set('X-Workspace-Id', svgpWorkspaceId)
        .expect(200);

      expect(res.body.success).toBe(true);
      expect(res.body.data.metrics.departmentsCount).toBe(6);
      expect(res.body.data.metrics.collegeAttendancePercentage).toBeGreaterThan(0);
      expect(res.body.data.recentActivity.length).toBe(6);
    });

    it('should reject unauthenticated requests with dummy "dev-token" (reproducing original failure)', async () => {
      const res = await request(app)
        .get('/api/v1/dashboard/home')
        .set('Authorization', 'Bearer dev-token')
        .set('X-Workspace-Id', svgpWorkspaceId)
        .expect(401);

      expect(res.body.success).toBe(false);
    });
  });

  describe('3. Production Security Gating & Fail-Closed Safeguard', () => {
    it('should fail-closed if NODE_ENV is set to production', async () => {
      const originalEnv = env.NODE_ENV;
      try {
        (env as any).NODE_ENV = 'production';
        await expect(AuthService.devLogin(AppRole.COLLEGE_ADMIN)).rejects.toThrow(
          'Development login is disabled in non-development environments'
        );
      } finally {
        (env as any).NODE_ENV = originalEnv;
      }
    });
  });
});
