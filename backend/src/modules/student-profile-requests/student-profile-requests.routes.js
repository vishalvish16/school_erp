/**
 * School Admin / Staff routes for Student Profile Update Requests.
 * Mounted at: /api/school/student-profile-requests
 * All routes require: verifyAccessToken + requireSchoolAdmin
 */
import express from 'express';
import multer from 'multer';
import path from 'path';
import fs from 'fs';
import { fileURLToPath } from 'url';
import { verifyAccessToken } from '../../middleware/auth.middleware.js';
import { requireSchoolAdmin } from '../../middleware/school-admin-guard.middleware.js';
import * as ctrl from './student-profile-requests.controller.js';
import {
    validate,
    approveRequestSchema,
    rejectRequestSchema,
} from './student-profile-requests.validation.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

// Ensure uploads directory exists
const uploadDir = path.join(__dirname, '..', '..', '..', 'uploads', 'student-photos');
if (!fs.existsSync(uploadDir)) {
    fs.mkdirSync(uploadDir, { recursive: true });
}

// Multer config for student profile photos
const storage = multer.diskStorage({
    destination: (_req, _file, cb) => cb(null, uploadDir),
    filename: (_req, file, cb) => {
        const uniqueSuffix = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
        const ext = path.extname(file.originalname);
        cb(null, `student-${uniqueSuffix}${ext}`);
    },
});

const upload = multer({
    storage,
    limits: { fileSize: 5 * 1024 * 1024 }, // 5 MB
    fileFilter: (_req, file, cb) => {
        const allowed = /\.(jpg|jpeg|png|webp)$/i;
        if (allowed.test(path.extname(file.originalname))) {
            return cb(null, true);
        }
        cb(new Error('Only JPG, PNG, and WebP images are allowed'));
    },
});

const router = express.Router();

router.use(verifyAccessToken, requireSchoolAdmin);

// GET /pending-count — pending count for badge (specific path before :id)
router.get('/pending-count', ctrl.getPendingCount);

// GET /              — list all requests
router.get('/', ctrl.getSchoolRequests);

// GET /:id           — single request detail
router.get('/:id', ctrl.getRequestById);

// POST /:id/approve  — approve a request
router.post('/:id/approve', validate(approveRequestSchema), ctrl.approveRequest);

// POST /:id/reject   — reject a request
router.post('/:id/reject', validate(rejectRequestSchema), ctrl.rejectRequest);

export default router;

// Separate router for student profile photo upload
// Mounted at: /api/school/students/:id/profile-photo
const photoRouter = express.Router({ mergeParams: true });
photoRouter.use(verifyAccessToken, requireSchoolAdmin);
photoRouter.post('/', upload.single('photo'), ctrl.uploadProfilePhoto);
export { photoRouter as studentPhotoRouter };
