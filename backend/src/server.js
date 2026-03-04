import app from './app.js';
import { env } from './config/env.js';
import { logger } from './config/logger.js';

// Global Uncaught Exception Handling
process.on('uncaughtException', (err) => {
    logger.error(`[UNCAUGHT EXCEPTION] 💥 Shutting down... ${err.name}: ${err.message}`);
    process.exit(1);
});

const PORT = env.PORT || 3000;

const server = app.listen(PORT, '0.0.0.0', () => {
    logger.info(`Server is running in ${env.NODE_ENV} mode on port ${PORT} across all network interfaces`);
});

// Global Unhandled Rejection Handling
process.on('unhandledRejection', (err) => {
    logger.error(`[UNHANDLED REJECTION] 💥 Shutting down... ${err.name}: ${err.message}`);
    server.close(() => {
        process.exit(1);
    });
});
