import mongoose, { Connection } from 'mongoose';
import { env } from '../config/env';
import { Logger } from '../utils/logger';


export interface DatabaseStatus {
  connected: boolean;
  state: 'disconnected' | 'connected' | 'connecting' | 'disconnecting' | 'uninitialized';
  databaseName: string;
  host?: string;
  readyState: number;
}

class DatabaseConnectionManager {
  private static instance: DatabaseConnectionManager;
  private isConnecting = false;

  private constructor() {
    this.setupMongooseEvents();
  }

  public static getInstance(): DatabaseConnectionManager {
    if (!DatabaseConnectionManager.instance) {
      DatabaseConnectionManager.instance = new DatabaseConnectionManager();
    }
    return DatabaseConnectionManager.instance;
  }

  private setupMongooseEvents(): void {
    mongoose.connection.on('connected', () => {
      Logger.info(`MongoDB connected to database "${this.getDatabaseName()}"`);
    });

    mongoose.connection.on('error', (err) => {
      Logger.error('MongoDB connection error', err);
    });

    mongoose.connection.on('disconnected', () => {
      Logger.info('MongoDB disconnected');
    });
  }

  public async connect(customUri?: string, customDbName?: string): Promise<Connection> {
    const uri = customUri !== undefined ? customUri : env.MONGODB_URI;
    const dbName = customDbName || env.MONGODB_DATABASE || 'acadex';

    if (!uri) {
      throw new Error(
        'MONGODB_URI is not set. Please provide a valid MongoDB connection string in environment variables or configuration.'
      );
    }

    // Reuse existing connection if already connected
    if (mongoose.connection.readyState === 1) {
      return mongoose.connection;
    }

    if (this.isConnecting) {
      Logger.info('MongoDB connection is already in progress, awaiting resolution...');
      await new Promise<void>((resolve) => {
        const check = () => {
          if (mongoose.connection.readyState === 1 || mongoose.connection.readyState === 0) {
            resolve();
          } else {
            setTimeout(check, 100);
          }
        };
        check();
      });
      return mongoose.connection;
    }

    try {
      this.isConnecting = true;
      Logger.info(`Connecting to MongoDB database "${dbName}"...`);

      await mongoose.connect(uri, {
        dbName,
        maxPoolSize: 10,
        minPoolSize: 2,
        serverSelectionTimeoutMS: 10000,
        socketTimeoutMS: 45000,
      });

      return mongoose.connection;
    } catch (error) {
      Logger.error('Failed to establish MongoDB connection', error);
      throw error;
    } finally {
      this.isConnecting = false;
    }
  }

  public async disconnect(): Promise<void> {
    if (mongoose.connection.readyState !== 0) {
      Logger.info('Closing MongoDB connection...');
      await mongoose.disconnect();
    }
  }

  public getConnection(): Connection {
    return mongoose.connection;
  }

  public isConnected(): boolean {
    return mongoose.connection.readyState === 1;
  }

  public getDatabaseName(): string {
    return mongoose.connection.name || env.MONGODB_DATABASE || 'acadex';
  }

  public getStatus(): DatabaseStatus {
    const stateMap: Record<number, DatabaseStatus['state']> = {
      0: 'disconnected',
      1: 'connected',
      2: 'connecting',
      3: 'disconnecting',
    };

    const readyState = mongoose.connection.readyState;
    return {
      connected: readyState === 1,
      state: stateMap[readyState] || 'uninitialized',
      databaseName: this.getDatabaseName(),
      host: mongoose.connection.host || undefined,
      readyState,
    };
  }
}

export const dbManager = DatabaseConnectionManager.getInstance();
export const connectDB = (uri?: string, dbName?: string) => dbManager.connect(uri, dbName);
export const disconnectDB = () => dbManager.disconnect();
export const getDatabaseStatus = () => dbManager.getStatus();
