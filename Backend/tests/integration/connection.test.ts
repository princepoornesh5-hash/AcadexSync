import { dbManager } from '../../src/db/connection';
import { setupTestDB, teardownTestDB } from '../setup';

describe('Database Connection Manager', () => {
  beforeAll(async () => {
    await setupTestDB();
  });

  afterAll(async () => {
    await teardownTestDB();
  });

  it('should report correct connected state and status', () => {
    const status = dbManager.getStatus();
    expect(status.connected).toBe(true);
    expect(status.state).toBe('connected');
    expect(status.readyState).toBe(1);
  });

  it('should expose active mongoose database connection', () => {
    const conn = dbManager.getConnection();
    expect(conn).toBeDefined();
    expect(conn.readyState).toBe(1);
  });

  it('should fail with a clear descriptive message when URI is missing', async () => {
    await expect(dbManager.connect('', 'testdb')).rejects.toThrow(
      /MONGODB_URI is not set/
    );
  });
});
