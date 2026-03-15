import * as smartLoginService from './smart-login.service.js';
import { successResponse } from '../../utils/response.js';

export const resolveSubdomainController = async (req, res, next) => {
    try {
        const { subdomain, slug } = req.body;
        const subdomainOrSlug = (subdomain && String(subdomain).trim()) || (slug && String(slug).trim());
        const result = await smartLoginService.resolveSubdomain(subdomainOrSlug);
        return successResponse(res, 200, 'Subdomain resolved', result);
    } catch (error) {
        next(error);
    }
};

export const smartLoginController = async (req, res, next) => {
    try {
        const ip = req.ip || req.connection?.remoteAddress || null;
        const body = { ...req.body, ip_address: ip };
        const result = await smartLoginService.smartLogin(body);
        return successResponse(res, 200, 'Login successful', result);
    } catch (error) {
        next(error);
    }
};

export const verifyDeviceOtpController = async (req, res, next) => {
    try {
        const ip = req.ip || req.connection?.remoteAddress || null;
        const meta = req.body.device_meta || {};
        meta.ip_address = meta.ip_address || ip;
        const body = { ...req.body, device_meta: meta };
        const result = await smartLoginService.verifyDeviceOtp(body);
        return successResponse(res, 200, 'Device verified', result);
    } catch (error) {
        next(error);
    }
};

export const resendDeviceOtpController = async (req, res, next) => {
    try {
        const body = { ...req.body };
        const result = await smartLoginService.resendDeviceOtp(body);
        return successResponse(res, 200, 'New code sent to your phone and email', result);
    } catch (error) {
        next(error);
    }
};

export const sessionCheckController = async (req, res, next) => {
    try {
        const token = req.headers.authorization?.replace('Bearer ', '');
        const result = await smartLoginService.sessionCheck(token);
        if (!result) {
            return res.status(401).json({ success: false, message: 'Session expired or invalid' });
        }
        return successResponse(res, 200, 'Session valid', result);
    } catch (error) {
        next(error);
    }
};

export const logoutController = async (req, res, next) => {
    try {
        const token = req.headers.authorization?.replace('Bearer ', '');
        const { remove_device_trust } = req.body || {};
        await smartLoginService.logout(token, remove_device_trust);
        return successResponse(res, 200, 'Logged out successfully');
    } catch (error) {
        next(error);
    }
};

export const myDevicesController = async (req, res, next) => {
    try {
        const userId = req.user?.userId;
        if (!userId) {
            return res.status(401).json({ success: false, message: 'Unauthorized' });
        }
        const result = await smartLoginService.getMyDevices(userId);
        return successResponse(res, 200, 'Devices retrieved', result);
    } catch (error) {
        next(error);
    }
};

export const removeDeviceController = async (req, res, next) => {
    try {
        const userId = req.user?.userId;
        const { device_id } = req.params;
        if (!userId) {
            return res.status(401).json({ success: false, message: 'Unauthorized' });
        }
        await smartLoginService.removeDevice(device_id, userId);
        return successResponse(res, 200, 'Device trust removed');
    } catch (error) {
        next(error);
    }
};
