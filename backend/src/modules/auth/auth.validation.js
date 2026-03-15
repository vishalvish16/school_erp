import { z } from 'zod';

export const loginSchema = z.object({
    body: z.object({
        email: z.string().optional(),
        identifier: z.string().optional(),
        password: z.string().min(1, 'Password is required'),
        portal_type: z.string().optional(),
        school_id: z.union([z.string(), z.number()]).optional(),
        device_fingerprint: z.string().optional(),
        device_meta: z.record(z.any()).optional()
    }).refine(data => {
        const loginId = data.email || data.identifier;
        if (!loginId || String(loginId).trim() === '') return false;
        if (data.email && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(data.email)) return false;
        return true;
    }, { message: 'Valid email or identifier is required' })
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

export const resolveSubdomainSchema = z.object({
    body: z.object({
        subdomain: z.string().optional(),
        slug: z.string().optional()
    }).refine(data => (data.subdomain && data.subdomain.trim()) || (data.slug && data.slug.trim()), {
        message: 'Subdomain or slug is required'
    })
});

export const verifyDeviceOtpSchema = z.object({
    body: z.object({
        otp_session_id: z.string().min(1, 'OTP session is required'),
        otp_code: z.string().min(6).max(6, 'OTP must be 6 digits'),
        trust_device: z.boolean().optional(),
        device_fingerprint: z.string().optional(),
        device_meta: z.record(z.any()).optional(),
        portal_type: z.string().optional()
    })
});

export const resendDeviceOtpSchema = z.object({
    body: z.object({
        otp_session_id: z.string().min(1, 'OTP session is required'),
        device_fingerprint: z.string().optional()
    })
});

export const verify2faSchema = z.object({
    body: z.object({
        totp_code: z.string().min(6, 'TOTP code is required'),
        temp_token: z.string().min(1, 'Temp token is required'),
        device_fingerprint: z.string().optional(),
        device_meta: z.record(z.any()).optional()
    })
});

export const groupAdminLoginSchema = z.object({
    body: z.object({
        identifier: z.string().min(1, 'Identifier is required'),
        password: z.string().optional(),
        otp_code: z.string().optional(),
        group_id: z.string().min(1, 'Group ID is required'),
        device_fingerprint: z.string().optional(),
        device_meta: z.record(z.any()).optional(),
        trust_device: z.boolean().optional()
    }).refine(data => data.password || data.otp_code, { message: 'Password or OTP required' })
});

export const resolveUserByPhoneSchema = z.object({
    body: z.object({
        phone: z.string().min(10, 'Phone number required'),
        user_type: z.enum(['parent', 'student']).optional().default('parent'),
        school_id: z.string().uuid().optional().nullable()
    })
});

export const verifyParentOtpSchema = z.object({
    body: z.object({
        otp_session_id: z.string().uuid('Invalid OTP session'),
        otp: z.string().length(6, 'OTP must be 6 digits'),
        phone: z.string().min(10, 'Phone required'),
        school_id: z.string().uuid('School ID required')
    })
});

export const groupAdminForgotPasswordSchema = z.object({
    body: z.object({
        email: z.string().email('Valid email required'),
    }),
});

export const groupAdminResetPasswordSchema = z.object({
    body: z.object({
        token: z.string().min(1, 'Token is required'),
        new_password: z.string().min(6, 'Password must be at least 6 characters'),
    }),
});

export const qrLoginSchema = z.object({
    body: z.object({
        qr_token: z.string().min(1, 'QR token is required'),
        school_id: z.union([z.string(), z.number()]),
        device_fingerprint: z.string().optional(),
        device_meta: z.record(z.any()).optional()
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
