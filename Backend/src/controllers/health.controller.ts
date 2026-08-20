import { Request, Response } from 'express';
import { getDatabaseStatus } from '../db/connection';
import { env } from '../config/env';

export class HealthController {
  public static async getHealth(_req: Request, res: Response): Promise<Response> {
    const dbStatus = getDatabaseStatus();

    const isHealthy = dbStatus.connected;
    const statusCode = isHealthy ? 200 : 503;

    return res.status(statusCode).json({
      status: isHealthy ? 'ok' : 'degraded',
      service: 'acadex-backend',
      version: '1.0.0',
      environment: env.NODE_ENV,
      database: dbStatus.connected ? 'connected' : dbStatus.state,
      databaseName: dbStatus.databaseName,
      timestamp: new Date().toISOString(),
    });
  }
}
