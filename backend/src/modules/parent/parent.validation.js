import { z } from 'zod';

export const updateParentProfileSchema = z.object({
    body: z.object({
        firstName: z.string().min(1).max(100).optional(),
        lastName: z.string().min(1).max(100).optional(),
        email: z.string().email().nullable().optional(),
    })
});

export const changePasswordSchema = z.object({
    body: z.object({
        current_password: z.string().min(1, 'Current password is required'),
        new_password: z.string().min(8, 'New password must be at least 8 characters'),
    })
});
