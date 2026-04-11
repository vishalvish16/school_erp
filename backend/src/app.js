import express from 'express';
import path from 'path';
import { fileURLToPath } from 'url';
import cors from 'cors';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
import { env } from './config/env.js';
import { logger } from './config/logger.js';
import { errorHandler } from './middleware/errorHandler.js';
import { AppError } from './utils/response.js';

import authRoutes from './modules/auth/auth.routes.js';
import dashboardRoutes from './modules/dashboard/dashboard.routes.js';
import schoolRoutes from './modules/schools/schools.routes.js';
import { searchSchools } from './modules/schools/schools.public.controller.js';
import subscriptionRoutes from './modules/subscription/subscription.routes.js';
import plansRoutes from './modules/plans/plans.routes.js';
import schoolManagementRoutes from './modules/school/school.routes.js';
import superAdminRoutes from './modules/super-admin/super-admin.routes.js';
import groupAdminRoutes from './modules/group-admin/group-admin.routes.js';
import schoolAdminRoutes from './modules/school-admin/school-admin.routes.js';
import teacherRoutes from './modules/teacher/teacher.routes.js';
import staffPortalRoutes from './modules/staff/staff-portal.routes.js';
import studentRoutes from './modules/student/student.routes.js';
import nonTeachingStaffRoutes from './modules/non-teaching-staff/non-teaching-staff.routes.js';
import driverRoutes from './modules/driver/driver.routes.js';
import parentRoutes from './modules/parent/parent.routes.js';
import transportRoutes from './modules/transport/transport.routes.js';
import studentProfileRequestsSchoolRoutes, { studentPhotoRouter } from './modules/student-profile-requests/student-profile-requests.routes.js';
import studentProfileRequestsParentRoutes from './modules/student-profile-requests/student-profile-requests-parent.routes.js';
import { superAdminThemeRouter, schoolThemeRouter, parentThemeRouter } from './modules/theme/theme.routes.js';

const app = express();

// Secure CORS Config — in development allow all origins for Flutter web
const allowedOrigins = env.CORS_ORIGIN.split(',').map(o => o.trim());
app.use(cors({
    origin: (origin, callback) => {
        if (!origin) return callback(null, true);
        if (allowedOrigins.includes('*') || allowedOrigins.includes(origin)) {
            return callback(null, true);
        }
        // In development: allow ALL origins (Flutter web, any port, HTTP/HTTPS)
        if (env.NODE_ENV === 'development') {
            return callback(null, true);
        }
        return callback(new AppError('CORS policy violation', 403), false);
    },
    credentials: true,
}));

// Body Parser Middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Static files for avatars
const uploadsPath = path.join(__dirname, '..', 'uploads');
app.use('/uploads', express.static(uploadsPath));

// Http request logging
app.use((req, res, next) => {
    logger.info(`[${req.method}] ${req.url}`);
    next();
});

// Modular Routes mount point
const API_PREFIX = '/api/platform';

app.use(`${API_PREFIX}/auth`, authRoutes);
app.use(`${API_PREFIX}/dashboard`, dashboardRoutes);
// Public school search — separate path, no auth (for mobile app)
app.get('/api/public/schools/search', searchSchools);
app.use(`${API_PREFIX}/schools`, schoolRoutes);
app.use(`${API_PREFIX}/subscriptions`, subscriptionRoutes);
app.use(`${API_PREFIX}/plans`, plansRoutes);
app.use(`${API_PREFIX}/super-admin`, superAdminRoutes);
app.use(`${API_PREFIX}/group-admin`, groupAdminRoutes);

// Non-Teaching Staff module — mounted BEFORE generic /api/school to avoid prefix conflict
app.use('/api/school/non-teaching', nonTeachingStaffRoutes);

// Transport — school admin live vehicle tracking (mounted BEFORE generic /api/school)
app.use('/api/school/transport', transportRoutes);

// Student Profile Update Requests — mounted BEFORE generic /api/school to avoid prefix conflict
app.use('/api/school/student-profile-requests', studentProfileRequestsSchoolRoutes);

// Student profile photo upload (school admin) — mounted before generic /api/school
app.use('/api/school/students/:id/profile-photo', studentPhotoRouter);

// School Admin portal — full CRUD for students, staff, classes, attendance, fees, timetable, notices
app.use('/api/school', schoolAdminRoutes);

// Teacher portal — attendance, homework, diary, dashboard
app.use('/api/teacher', teacherRoutes);

// Staff/Clerk portal — fee collection, student lookup, notices (read-only)
app.use('/api/staff', staffPortalRoutes);

// Student portal — profile, dashboard, attendance, fees, timetable, notices, documents
app.use('/api/student', studentRoutes);

// Driver portal — dashboard, profile, change password
app.use('/api/driver', driverRoutes);

// Theme — dynamic color tokens for all portals (mounted BEFORE generic portal routes)
app.use(`${API_PREFIX}/theme`, superAdminThemeRouter);
app.use('/api/school/theme', schoolThemeRouter);
app.use('/api/parent/theme', parentThemeRouter);

// Parent — profile update requests (mounted BEFORE generic /api/parent to avoid prefix conflict)
app.use('/api/parent/student-profile-requests', studentProfileRequestsParentRoutes);

// Parent portal — profile, children, attendance, fees, notices
app.use('/api/parent', parentRoutes);

// Legacy school-level operations (kept for backwards compat — student/teacher/branch management)
app.use('/api/school/legacy', schoolManagementRoutes);

// 404 handler
app.all('*', (req, res, next) => {
    next(new AppError(`Can't find ${req.originalUrl} on this server!`, 404));
});

// Global Error Handling Middleware
app.use(errorHandler);

export default app;
