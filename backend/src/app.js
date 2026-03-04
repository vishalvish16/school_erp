import express from 'express';
import cors from 'cors';
import { env } from './config/env.js';
import { logger } from './config/logger.js';
import { errorHandler } from './middleware/errorHandler.js';
import { AppError } from './utils/response.js';

import authRoutes from './modules/auth/auth.routes.js';
import dashboardRoutes from './modules/dashboard/dashboard.routes.js';
import schoolRoutes from './modules/schools/schools.routes.js';
import subscriptionRoutes from './modules/subscription/subscription.routes.js';
import plansRoutes from './modules/plans/plans.routes.js';
import schoolManagementRoutes from './modules/school/school.routes.js';

const app = express();

// Secure CORS Config
const allowedOrigins = env.CORS_ORIGIN.split(',').map(o => o.trim());
app.use(cors({
    origin: (origin, callback) => {
        // allow requests with no origin (like mobile apps or curl requests)
        if (!origin || allowedOrigins.includes('*') || allowedOrigins.includes(origin)) {
            return callback(null, true);
        }
        return callback(new AppError('CORS policy violation', 403), false);
    },
    credentials: true,
}));

// Body Parser Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Http request logging
app.use((req, res, next) => {
    logger.info(`[${req.method}] ${req.url}`);
    next();
});

// Modular Routes mount point
const API_PREFIX = '/api/platform';

app.use(`${API_PREFIX}/auth`, authRoutes);
app.use(`${API_PREFIX}/dashboard`, dashboardRoutes);
app.use(`${API_PREFIX}/schools`, schoolRoutes);
app.use(`${API_PREFIX}/subscriptions`, subscriptionRoutes);
app.use(`${API_PREFIX}/plans`, plansRoutes);

// School-level operations (e.g., student/teacher/branch management)
app.use('/api/school', schoolManagementRoutes);

// 404 handler
app.all('*', (req, res, next) => {
    next(new AppError(`Can't find ${req.originalUrl} on this server!`, 404));
});

// Global Error Handling Middleware
app.use(errorHandler);

export default app;
