import { createServer } from 'http';
import { Server } from 'socket.io';
import app from './app.js';
import { env } from './config/env.js';
import { logger } from './config/logger.js';
import { verifyToken } from './utils/jwt.js';
import { setIO } from './socket.js';

// Global Uncaught Exception Handling
process.on('uncaughtException', (err) => {
    logger.error(`[UNCAUGHT EXCEPTION] Shutting down... ${err.name}: ${err.message}`);
    process.exit(1);
});

const PORT = env.PORT || 3000;

// Create HTTP server wrapping the Express app
const httpServer = createServer(app);

// Create Socket.IO server with CORS
const io = new Server(httpServer, {
    cors: {
        origin: '*',
        methods: ['GET', 'POST'],
    },
});

// Store the io instance so controllers can import it
setIO(io);

// Socket.IO authentication middleware — verify JWT from handshake
io.use((socket, next) => {
    try {
        const token = socket.handshake.auth?.token;
        if (!token) {
            return next(new Error('Authentication required'));
        }
        const decoded = verifyToken(token);
        socket.user = decoded;
        next();
    } catch (err) {
        next(new Error('Invalid or expired token'));
    }
});

// Socket.IO connection handler
io.on('connection', (socket) => {
    const schoolId = socket.user.school_id || socket.user.schoolId;
    if (schoolId) {
        socket.join(`school:${schoolId}`);
        logger.info(`[Socket.IO] User ${socket.user.userId || socket.user.id} joined room school:${schoolId}`);
    }

    socket.on('disconnect', () => {
        logger.info(`[Socket.IO] User ${socket.user.userId || socket.user.id} disconnected`);
    });
});

const server = httpServer.listen(PORT, '0.0.0.0', () => {
    logger.info(`Server is running in ${env.NODE_ENV} mode on port ${PORT} across all network interfaces`);
    logger.info(`[Socket.IO] WebSocket server ready`);
});

// Global Unhandled Rejection Handling
process.on('unhandledRejection', (err) => {
    logger.error(`[UNHANDLED REJECTION] Shutting down... ${err.name}: ${err.message}`);
    server.close(() => {
        process.exit(1);
    });
});
