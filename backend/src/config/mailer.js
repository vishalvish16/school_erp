import nodemailer from 'nodemailer';
import { env } from './env.js';
import { logger } from './logger.js';

const hasSmtpCredentials = env.SMTP_USER && env.SMTP_PASS;

const transporter = hasSmtpCredentials
    ? nodemailer.createTransport({
        host: env.SMTP_HOST || 'smtp.gmail.com',
        port: parseInt(env.SMTP_PORT || '587'),
        secure: env.SMTP_SECURE === 'true',
        auth: {
            user: env.SMTP_USER,
            pass: env.SMTP_PASS,
        },
    })
    : null;

export const sendEmail = async ({ to, subject, text, html }) => {
    if (!hasSmtpCredentials || !transporter) {
        logger.warn('SMTP not configured (SMTP_USER/SMTP_PASS missing in .env). Email skipped.');
        return null;
    }
    try {
        const info = await transporter.sendMail({
            from: `"School AI ERP" <${env.SMTP_USER}>`,
            to,
            subject,
            text,
            html,
        });
        logger.info(`Message sent: ${info.messageId}`);
        return info;
    } catch (error) {
        logger.error('Error sending email:', error);
        throw error;
    }
};
