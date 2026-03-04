import { z } from 'zod';
import { AppError } from '../../utils/response.js';

export const createSubscriptionSchema = z.object({
    body: z.object({
        school_id: z.string().or(z.number()),
        plan_id: z.string().or(z.number()),
        billing_cycle: z.enum(['MONTHLY', 'YEARLY']),
        start_date: z.coerce.date().optional().default(() => new Date()),
        status: z.string().optional().default('ACTIVE'),
        auto_renew: z.boolean().optional().default(false),
        currency: z.string().optional().default('INR')
    })
});

export const upgradeSubscriptionSchema = z.object({
    params: z.object({
        id: z.string()
    }),
    body: z.object({
        plan_id: z.string().or(z.number()),
        billing_cycle: z.enum(['MONTHLY', 'YEARLY']),
        start_date: z.coerce.date().optional().default(() => new Date())
    })
});

export const getSchoolSubscriptionSchema = z.object({
    params: z.object({
        school_id: z.string()
    })
});

export const extendSubscriptionSchema = z.object({
    params: z.object({
        id: z.string()
    }),
    body: z.object({
        extend_months: z.number().int().positive()
    })
});

export const idParamSchema = z.object({
    params: z.object({
        id: z.string()
    })
});


export const validate = (schema) => (req, res, next) => {
    try {
        schema.parse({
            body: req.body,
            query: req.query,
            params: req.params
        });
        next();
    } catch (error) {
        const message = error.errors.map((i) => i.message).join(', ');
        next(new AppError(message, 400));
    }
};
