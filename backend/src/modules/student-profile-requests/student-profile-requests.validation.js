/**
 * Validation schemas for Student Profile Update Requests module.
 * Uses Zod (consistent with existing project validation pattern).
 */
import { z } from 'zod';

// ── Parent: Submit a profile update request ─────────────────────────────────

export const submitRequestSchema = z.object({
    body: z.object({
        studentId: z.string().uuid('studentId must be a valid UUID'),
        requestedChanges: z.object({
            firstName: z.string().min(1).max(100).optional(),
            lastName: z.string().min(1).max(100).optional(),
            dateOfBirth: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'dateOfBirth must be YYYY-MM-DD').optional(),
            bloodGroup: z.string().max(5).optional(),
            address: z.string().max(500).optional(),
            parentName: z.string().max(200).optional(),
            parentPhone: z.string().max(20).optional(),
            parentEmail: z.string().email().optional(),
            photoUrl: z.string().url().optional(),
        }).refine(
            (obj) => Object.keys(obj).length > 0,
            { message: 'requestedChanges must have at least one field' }
        ),
    }),
});

// ── School Admin: Approve a request ─────────────────────────────────────────

export const approveRequestSchema = z.object({
    body: z.object({
        note: z.string().max(500).optional(),
    }),
});

// ── School Admin: Reject a request ──────────────────────────────────────────

export const rejectRequestSchema = z.object({
    body: z.object({
        note: z.string().min(1, 'Rejection note is required').max(500),
    }),
});

// ── Generic validate middleware (Zod) ───────────────────────────────────────

export const validate = (schema) => (req, res, next) => {
    try {
        const parsed = schema.parse({
            body: req.body,
            query: req.query,
            params: req.params,
        });
        req.body = parsed.body;
        if (parsed.query) req.query = parsed.query;
        if (parsed.params) req.params = parsed.params;
        next();
    } catch (error) {
        if (error instanceof z.ZodError) {
            return res.status(400).json({
                success: false,
                message: 'Validation failed',
                error_code: 'ERR_VALIDATION',
                errors: error.errors.map((err) => ({
                    field: err.path.join('.'),
                    message: err.message,
                })),
            });
        }
        next(error);
    }
};
