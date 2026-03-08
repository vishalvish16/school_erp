import crypto from 'crypto';
import bcrypt from 'bcrypt';
import * as authRepository from './auth.repository.js';
import { AppError } from '../../utils/response.js';
import * as jwtUtils from '../../utils/jwt.js';
import { sendEmail } from '../../config/mailer.js';

export const login = async (email, password) => {
    const user = await authRepository.findUserByEmail(email);

    if (!user) {
        throw new AppError('Invalid email or password', 401);
    }

    if (!user.isActive) {
        throw new AppError('Account is inactive. Please contact support.', 403);
    }

    // Allow both PLATFORM and SCHOOL role types
    if (user.role.roleType !== 'PLATFORM' && user.role.roleType !== 'SCHOOL') {
        throw new AppError('Access denied. Invalid account type.', 403);
    }

    const isPasswordValid = await bcrypt.compare(password, user.passwordHash);
    if (!isPasswordValid) {
        throw new AppError('Invalid email or password', 401);
    }

    const accessToken = jwtUtils.generateAccessToken({
        userId: user.id.toString(),
        email: user.email,
        role: user.role.roleType,
        school_id: user.schoolId ? user.schoolId.toString() : null
    });

    const refreshToken = jwtUtils.generateRefreshToken({
        userId: user.id.toString(),
        school_id: user.schoolId ? user.schoolId.toString() : null
    });

    return {
        access_token: accessToken,
        refresh_token: refreshToken,
        user: {
            user_id: user.id.toString(),
            first_name: user.firstName,
            last_name: user.lastName,
            email: user.email,
            role: user.role.roleType,
            school_id: user.schoolId ? user.schoolId.toString() : null
        }
    };
};

export const forgotPassword = async (email, origin) => {
    const smartRepo = await import('./smart-login.repository.js');
    const recentCount = await smartRepo.countRecentForgotPasswordByEmail(email, 60);
    if (recentCount >= 3) {
        throw new AppError('Too many attempts. Try again in 60 minutes.', 429);
    }

    const user = await authRepository.findUserByEmail(email);
    if (!user) {
        return { message: 'If a user with that email exists, a reset link has been sent.' };
    }

    await smartRepo.trackForgotPasswordRequest(email).catch(() => {});

    const token = crypto.randomBytes(32).toString('hex');
    const expiry = new Date(Date.now() + 3600000); // 1 hour

    await authRepository.updateUserResetToken(email, token, expiry);

    // const resetLink = `schoolerp://reset-password?token=${token}`; // Deep link for Flutter
    const resetLink = `${origin}/#/reset-password?token=${token}`; // Deep link using dynamic origin

    try {
        await sendEmail({
            to: email,
            subject: 'Secure Password Reset — School AI ERP',
            html: `
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <style>
        body { font-family: 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; background-color: #f8fafc; margin: 0; padding: 0; }
        .container { max-width: 600px; margin: 40px auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 10px 25px rgba(0,0,0,0.05); border: 1px solid #e2e8f0; }
        .header { background: linear-gradient(135deg, #6366f1 0%, #3b82f6 100%); padding: 40px 20px; text-align: center; }
        .header h1 { color: #ffffff; margin: 0; font-size: 24px; font-weight: 700; letter-spacing: -0.5px; }
        .content { padding: 40px 30px; color: #334155; line-height: 1.6; }
        .content h2 { color: #1e293b; margin-top: 0; font-size: 20px; }
        .button-container { text-align: center; margin: 35px 0; }
        .button { background: linear-gradient(to right, #6366f1, #3b82f6); color: #ffffff !important; padding: 14px 32px; border-radius: 10px; text-decoration: none; font-weight: 600; font-size: 16px; display: inline-block; box-shadow: 0 4px 12px rgba(59, 130, 246, 0.3); }
        .footer { background-color: #f1f5f9; padding: 20px; text-align: center; font-size: 12px; color: #64748b; }
        .token-box { background: #f8fafc; border: 1px dashed #cbd5e1; padding: 15px; border-radius: 8px; margin-top: 25px; text-align: center; }
        .token-text { font-family: monospace; font-size: 14px; color: #475569; word-break: break-all; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>School AI ERP</h1>
        </div>
        <div class="content">
            <h2>Security Key Recovery</h2>
            <p>We received a request to reset the password for your account associated with <strong>${email}</strong>. If you made this request, click the button below to set a new security key:</p>
            
            <div class="button-container">
                <a href="${resetLink}" class="button" target="_blank">Reset Password</a>
            </div>

            <p>This link will expire in 1 hour for your security. If you did not request this change, you can safely ignore this email.</p>

            <div class="token-box">
                <p style="margin-top:0; font-weight:600; font-size:12px; text-transform:uppercase; color:#94a3b8;">Manual Backup Token</p>
                <div class="token-text">${token}</div>
            </div>
        </div>
        <div class="footer">
            &copy; 2026 School AI ERP &bull; Virtualized Education Infrastructure<br>
            Secure Platform Access System
        </div>
    </div>
</body>
</html>
            `
        });
    } catch (error) {
        console.warn('⚠️ SMTP Email delivery failed. Is your .env configured?');
        console.log('🔗 RESET LINK FOR TESTING:', resetLink);
        // During development, we return success so the user can see the console link
        return {
            message: 'Reset instructions generated (Email delivery failed, check server logs for link).',
            debug_link: resetLink
        };
    }

    return { message: 'Reset link sent to your email.' };
};

export const resetPassword = async (token, newPassword) => {
    const user = await authRepository.findUserByResetToken(token);
    if (!user) {
        throw new AppError('Invalid or expired reset token', 400);
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);
    await authRepository.updateUserPassword(user.id, hashedPassword);

    return { message: 'Password has been reset successfully.' };
};
