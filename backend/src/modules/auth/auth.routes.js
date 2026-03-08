import { Router } from 'express';
import { loginController, forgotPasswordController, resetPasswordController } from './auth.controller.js';
import {
    resolveSubdomainController,
    verifyDeviceOtpController,
    sessionCheckController,
    logoutController,
    myDevicesController,
    removeDeviceController
} from './smart-login.controller.js';
import { verify2faController, groupAdminLoginController, qrLoginController } from './portal-auth.controller.js';
import {
    validate,
    loginSchema,
    forgotPasswordSchema,
    resetPasswordSchema,
    resolveSubdomainSchema,
    verifyDeviceOtpSchema,
    verify2faSchema,
    groupAdminLoginSchema,
    qrLoginSchema,
    resolveUserByPhoneSchema
} from './auth.validation.js';
import { verifyAccessToken } from '../../middleware/auth.middleware.js';
import { resolveUserByPhoneController } from './resolve-user-by-phone.controller.js';

const router = Router();

router.post('/resolve-user-by-phone', validate(resolveUserByPhoneSchema), resolveUserByPhoneController);
router.post('/login', validate(loginSchema), loginController);
router.post('/super-admin/verify-2fa', validate(verify2faSchema), verify2faController);
router.post('/group-admin/login', validate(groupAdminLoginSchema), groupAdminLoginController);
router.post('/qr-login', validate(qrLoginSchema), qrLoginController);
router.post('/forgot-password', validate(forgotPasswordSchema), forgotPasswordController);
router.post('/reset-password', validate(resetPasswordSchema), resetPasswordController);

// Smart Login endpoints
router.post('/resolve-subdomain', validate(resolveSubdomainSchema), resolveSubdomainController);
router.post('/verify-device-otp', validate(verifyDeviceOtpSchema), verifyDeviceOtpController);

router.get('/session-check', sessionCheckController);

router.delete('/logout', logoutController);

router.get('/my-devices', verifyAccessToken, myDevicesController);
router.delete('/devices/:device_id', verifyAccessToken, removeDeviceController);

export default router;
