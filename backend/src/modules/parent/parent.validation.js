import { z } from 'zod';

export const updateParentProfileSchema = z.object({
    body: z.object({
        firstName: z.string().min(1).max(100).optional(),
        lastName: z.string().min(1).max(100).optional(),
        email: z.string().email().nullable().optional(),
    })
});
