import { z } from 'zod';
import { AppError } from '../../utils/response.js';

export const getPlansQuerySchema = z.object({
    query: z.object({
        isActive: z.preprocess((val) => val === 'true' ? true : val === 'false' ? false : undefined, z.boolean().optional())
    })
});

export const deletePlanSchema = z.object({
    params: z.object({
        id: z.string()
    })
});

export const togglePlanStatusSchema = z.object({
    params: z.object({
        id: z.string()
    })
});

export const createPlanSchema = z.object({
    body: z.object({
        name: z.string().min(2),
        maxStudents: z.number().int().positive(),
        maxTeachers: z.number().int().positive(),
        maxBranches: z.number().int().nonnegative().optional().default(1),
        priceMonthly: z.number().positive(),
        priceYearly: z.number().positive().optional(),
        isActive: z.boolean().optional().default(true)
    })
});

export const updatePlanSchema = z.object({
    params: z.object({
        id: z.string()
    }),
    body: z.object({
        name: z.string().min(2).optional(),
        maxStudents: z.number().int().positive().optional(),
        maxTeachers: z.number().int().positive().optional(),
        maxBranches: z.number().int().nonnegative().optional(),
        priceMonthly: z.number().positive().optional(),
        priceYearly: z.number().positive().optional(),
        isActive: z.boolean().optional()
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
