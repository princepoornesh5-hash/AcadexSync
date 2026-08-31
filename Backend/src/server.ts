import http from 'http';
import { app } from './app';
import { env } from './config/env';
import { connectDB, disconnectDB } from './db/connection';
import { Logger } from './utils/logger';

async function startServer(): Promise<http.Server | void> {
  return new Promise((resolve) => {
    Logger.info(`Starting ACADEX Backend in ${env.NODE_ENV} mode...`);

    const server = http.createServer(app);

    server.on('error', async (error: NodeJS.ErrnoException) => {
      if (error.code === 'EADDRINUSE') {
        try {
          const controller = new AbortController();
          const timeout = setTimeout(() => controller.abort(), 2000);
          const response = await fetch(`http://localhost:${env.PORT}/health`, {
            signal: controller.signal,
          });
          clearTimeout(timeout);

          if (response.ok) {
            const data = (await response.json()) as any;
            if (data?.service === 'acadex-backend') {
              console.log(`\nℹ️  ACADEX Backend is already running on http://localhost:${env.PORT}`);
              console.log(`   Health:  http://localhost:${env.PORT}/api/v1/health`);
              console.log(`   MongoDB: ${data.database ?? 'connected'}`);
              console.log(`\n✅ No second backend instance is required.\n`);
              process.exit(0);
            }
          }
        } catch (_) {}

        console.error(`\n❌ Port conflict detected on port ${env.PORT}:`);
        console.error(`   Port ${env.PORT} is already occupied by another process.`);
        console.error(`   Please free port ${env.PORT} or configure PORT=xxxx in your environment.\n`);
        process.exit(1);
      } else {
        Logger.error('Fatal error during backend startup', error);
        process.exit(1);
      }
    });

    server.listen(env.PORT, '0.0.0.0', async () => {
      try {
        // Connect to MongoDB Atlas after port is successfully bound
        if (env.MONGODB_URI) {
          await connectDB();
          Logger.info('MongoDB Atlas database connection initialized.');
        } else {
          Logger.warn(
            'MONGODB_URI not configured. Database will connect on-demand or when configured.'
          );
        }

        Logger.info(`🚀 ACADEX Backend running on port ${env.PORT}`);
        Logger.info(`   Health check: http://localhost:${env.PORT}/health`);
        Logger.info(`   API v1 Root:  http://localhost:${env.PORT}/api/v1`);

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

        resolve(server);
      } catch (dbError) {
        Logger.error('Fatal error connecting to database during startup', dbError);
        server.close(() => {
          process.exit(1);
        });
      }
    });
  });
}

if (require.main === module) {
  startServer();
}

export { startServer };
