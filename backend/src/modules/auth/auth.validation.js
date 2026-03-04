import { z } from 'zod';

export const loginSchema = z.object({
    body: z.object({
        email: z.string().email('Invalid email format'),
        password: z.string().min(1, 'Password is required')
    })
});

export const forgotPasswordSchema = z.object({
    body: z.object({
        email: z.string().email('Invalid email format'),
    })
});

export const resetPasswordSchema = z.object({
    body: z.object({
        token: z.string().min(1, 'Token is required'),
        newPassword: z.string().min(6, 'Password must be at least 6 characters')
    })
});

// Generic validation middleware
export const validate = (schema) => (req, res, next) => {
    try {
        const parsed = schema.parse({
            body: req.body,
            query: req.query,
            params: req.params,
        });
        req.body = parsed.body;
        req.query = parsed.query;
        req.params = parsed.params;
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
