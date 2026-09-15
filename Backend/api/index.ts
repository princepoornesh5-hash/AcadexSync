import type { Request, Response } from 'express';
import { app } from '../src/app';
import { connectDB } from '../src/db/connection';

export default async function handler(req: Request, res: Response): Promise<void> {
  if (process.env.MONGODB_URI) {
    try {
      await connectDB();
    } catch (err) {
      console.error('MongoDB connection error in Vercel function handler:', err);
    }
  }
  return app(req as any, res as any);
}
