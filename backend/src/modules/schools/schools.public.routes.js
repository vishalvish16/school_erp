// =============================================================================
// FILE: schools.public.routes.js
// PURPOSE: Public school endpoints (no auth) for mobile app
// =============================================================================

import { Router } from 'express';
import { searchSchools } from './schools.public.controller.js';

const router = Router();

// Mounted at /api/public, so full path is /api/public/schools/search
router.get('/schools/search', searchSchools);

export default router;
