import dotenv from 'dotenv';
import { z } from 'zod';

dotenv.config();

const envSchema = z.object({
    PORT: z.string().default('3000'),
    NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
    DATABASE_URL: z.string().url().default('postgresql://user:password@localhost:5432/school_erp'),
    JWT_ACCESS_SECRET: z.string().min(32).default('super_secret_access_key_replace_in_prod'),
    JWT_REFRESH_SECRET: z.string().min(32).default('super_secret_refresh_key_replace_in_prod'),
    CORS_ORIGIN: z.string().default('http://localhost:3000,http://localhost:5000,http://localhost:8080,http://localhost:5173,http://127.0.0.1:8080,http://127.0.0.1:5173'),
    SMTP_HOST: z.string().optional(),
    SMTP_PORT: z.string().optional(),
    SMTP_SECURE: z.string().optional(),
    SMTP_USER: z.string().optional(),
    SMTP_PASS: z.string().optional(),
});

const _env = envSchema.safeParse(process.env);

if (!_env.success) {
    console.error('❌ Invalid environment variables:', _env.error.format());
    process.exit(1);
}

export const env = _env.data;
