// =============================================================================
// FILE: schools.public.controller.js
// PURPOSE: Public school search for mobile app (no auth required)
// =============================================================================

import * as schoolService from './schools.service.js';
import { successResponse } from '../../utils/response.js';

/**
 * GET /schools/search?q=...&limit=10
 * Public endpoint for mobile school setup — search by name, city, or code
 * Rate limit: 30 req/min per IP (handled by express-rate-limit if configured)
 */
export const searchSchools = async (req, res, next) => {
    try {
        const q = (req.query.q || '').toString().trim();
        const limit = Math.min(parseInt(req.query.limit, 10) || 10, 20);

        if (q.length < 2) {
            return successResponse(res, 200, 'Search requires at least 2 characters', []);
        }

        const schools = await schoolService.searchSchoolsPublic(q, limit);
        return successResponse(res, 200, 'Schools retrieved', schools);
    } catch (error) {
        next(error);
    }
};
