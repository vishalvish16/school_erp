import { z } from 'zod';

export const createSchoolSchema = z.object({
    body: z.object({
        name: z.string().min(1, 'Name is required'),
        schoolCode: z.string().min(1, 'School code is required'),
        subdomain: z.string().optional(),
        contactEmail: z.string().email('Invalid email').optional().or(z.literal('')),
        planId: z.string().or(z.number()),
        phone: z.string().or(z.number()).transform(v => String(v)).optional(),
        address: z.string().optional(),
        city: z.string().optional(),
        state: z.string().optional(),
        country: z.string().optional(),
        pincode: z.string().optional(),
        status: z.string().optional(),
        subscriptionStart: z.coerce.date().optional(),
        subscriptionEnd: z.coerce.date().optional()
    })
});

export const updateSchoolSchema = z.object({
    body: z.object({
        name: z.string().min(1).optional(),
        schoolCode: z.string().min(1).optional(),
        subdomain: z.string().optional(),
        contactEmail: z.string().email().optional().or(z.literal('')),
        planId: z.string().or(z.number()).optional(),
        phone: z.string().or(z.number()).transform(v => String(v)).optional(),
        address: z.string().optional(),
        city: z.string().optional(),
        state: z.string().optional(),
        country: z.string().optional(),
        pincode: z.string().optional(),
        isActive: z.boolean().optional(),
        status: z.string().optional(),
        subscriptionStart: z.coerce.date().optional(),
        subscriptionEnd: z.coerce.date().optional()
    }),
    params: z.object({
        id: z.string().min(1, 'ID is required')
    })
});

export const schoolIdParamSchema = z.object({
    params: z.object({
        id: z.string().min(1, 'ID is required')
    })
});

export const getSchoolsQuerySchema = z.object({
    query: z.object({
        page: z.string().optional(),
        limit: z.string().optional(),
        search: z.string().optional(),
        status: z.string().optional()
    })
});

export const assignPlanSchema = z.object({
    params: z.object({
        id: z.string()
    }),
    body: z.object({
        plan_id: z.string(),
        billing_cycle: z.enum(['MONTHLY', 'YEARLY']),
        duration_months: z.number().int().positive().optional()
    })
});

export const validate = (schema) => (req, res, next) => {
    try {
        const parsed = schema.parse({
            body: req.body,
            query: req.query,
            params: req.params,
        });
        if (parsed.body) req.body = parsed.body;
        if (parsed.query) req.query = parsed.query;
        if (parsed.params) req.params = parsed.params;
        next();
    } catch (error) {
        if (error instanceof z.ZodError) {
            return res.status(400).json({
                success: false,
                message: 'Validation failed',
                error_code: 'ERR_VALIDATION',
                errors: error.errors.map(err => ({ field: err.path.join('.'), message: err.message }))
            });
        }
        next(error);
    }
};
