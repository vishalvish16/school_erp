import nodemailer from 'nodemailer';
import { env } from './env.js';
import { logger } from './logger.js';

const transporter = nodemailer.createTransport({
    host: env.SMTP_HOST || 'smtp.gmail.com',
    port: parseInt(env.SMTP_PORT || '587'),
    secure: env.SMTP_SECURE === 'true', // true for 465, false for other ports
    auth: {
        user: env.SMTP_USER,
        pass: env.SMTP_PASS,
    },
});

export const sendEmail = async ({ to, subject, text, html }) => {
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
