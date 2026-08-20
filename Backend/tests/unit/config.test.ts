import { env } from '../../src/config/env';

describe('Environment Configuration', () => {
  it('should load default environment configurations safely', () => {
    expect(env).toBeDefined();
    expect(typeof env.PORT).toBe('number');
    expect(env.PORT).toBeGreaterThan(0);
    expect(env.MONGODB_DATABASE).toBe('acadex');
    expect(['development', 'test', 'production']).toContain(env.NODE_ENV);
  });

  it('should provide fallback JWT secret for testing/development', () => {
    expect(env.JWT_SECRET).toBeDefined();
    expect(env.JWT_SECRET.length).toBeGreaterThanOrEqual(16);
  });
});
