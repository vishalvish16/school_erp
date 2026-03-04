import * as authService from './auth.service.js';
import { successResponse } from '../../utils/response.js';

export const loginController = async (req, res, next) => {
    try {
        const { email, password } = req.body;
        const result = await authService.login(email, password);

        return successResponse(res, 200, 'Login successful', result);
    } catch (error) {
        next(error);
    }
};

export const forgotPasswordController = async (req, res, next) => {
    try {
        const { email } = req.body;
        // Get the frontend origin from request headers, fallback to localhost for safety
        const origin = req.headers.origin || 'http://localhost:3000';
        const result = await authService.forgotPassword(email, origin);
        return successResponse(res, 200, result.message);
    } catch (error) {
        next(error);
    }
};

export const resetPasswordController = async (req, res, next) => {
    try {
        const { token, newPassword } = req.body;
        const result = await authService.resetPassword(token, newPassword);
        return successResponse(res, 200, result.message);
    } catch (error) {
        next(error);
    }
};
