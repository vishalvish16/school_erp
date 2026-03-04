import { z } from 'zod';
import { AppError } from '../../utils/response.js';

export const createStudentSchema = z.object({
    body: z.object({
        firstName: z.string().min(1),
        lastName: z.string().min(1),
        email: z.string().email(),
        phone: z.string().optional()
    })
});

export const createTeacherSchema = z.object({
    body: z.object({
        firstName: z.string().min(1),
        lastName: z.string().min(1),
        email: z.string().email(),
        phone: z.string().optional()
    })
});

export const createBranchSchema = z.object({
    body: z.object({
        name: z.string().min(1),
        branchCode: z.string().min(1),
        address: z.string().optional(),
        city: z.string().optional(),
        state: z.string().optional()
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
