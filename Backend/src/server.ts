import { app } from './app';
import { env } from './config/env';
import { connectDB, disconnectDB } from './db/connection';
import { Logger } from './utils/logger';

async function startServer() {
  try {
    Logger.info(`Starting ACADEX Backend in ${env.NODE_ENV} mode...`);

    // Connect to MongoDB Atlas
    if (env.MONGODB_URI) {
      await connectDB();
      Logger.info('MongoDB Atlas database connection initialized.');
    } else {
      Logger.warn(
        'MONGODB_URI not configured. Database will connect on-demand or when configured.'
      );
    }

    const server = app.listen(env.PORT, () => {
      Logger.info(`🚀 ACADEX Backend running on port ${env.PORT}`);
      Logger.info(`   Health check: http://localhost:${env.PORT}/health`);
      Logger.info(`   API v1 Root:  http://localhost:${env.PORT}/api/v1`);
    });

    const shutdown = async (signal: string) => {
      Logger.info(`Received ${signal}. Shutting down gracefully...`);
      server.close(async () => {
        Logger.info('HTTP server closed.');
        try {
          await disconnectDB();
          Logger.info('Database connection closed.');
          process.exit(0);
        } catch (err) {
          Logger.error('Error during database disconnect', err);
          process.exit(1);
        }
      });

      // Force shutdown after 10s if hanging
      setTimeout(() => {
        Logger.error('Forced shutdown after timeout.');
        process.exit(1);
      }, 10000);
    };

    process.on('SIGINT', () => shutdown('SIGINT'));
    process.on('SIGTERM', () => shutdown('SIGTERM'));
  } catch (error) {
    Logger.error('Fatal error during backend startup', error);
    process.exit(1);
  }
}

if (require.main === module) {
  startServer();
}

export { startServer };
