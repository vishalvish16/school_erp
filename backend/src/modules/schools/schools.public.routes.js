// =============================================================================
// FILE: schools.public.routes.js
// PURPOSE: Public school endpoints (no auth) for mobile app
// =============================================================================

import { Router } from 'express';
import { searchSchools } from './schools.public.controller.js';

const router = Router();

// No auth — for mobile school setup
router.get('/search', searchSchools);

export default router;
