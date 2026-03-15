import { Router } from 'express';
import { loginController, forgotPasswordController, resetPasswordController } from './auth.controller.js';
import {
    resolveSubdomainController,
    verifyDeviceOtpController,
    resendDeviceOtpController,
    sessionCheckController,
    logoutController,
    myDevicesController,
    removeDeviceController
} from './smart-login.controller.js';
import { verify2faController, groupAdminLoginController, groupAdminForgotPasswordController, groupAdminResetPasswordController, qrLoginController } from './portal-auth.controller.js';
import {
    validate,
    loginSchema,
    forgotPasswordSchema,
    resetPasswordSchema,
    resolveSubdomainSchema,
    verifyDeviceOtpSchema,
    resendDeviceOtpSchema,
    verify2faSchema,
    groupAdminLoginSchema,
    groupAdminForgotPasswordSchema,
    groupAdminResetPasswordSchema,
    qrLoginSchema,
    resolveUserByPhoneSchema,
    verifyParentOtpSchema
} from './auth.validation.js';
import { verifyAccessToken } from '../../middleware/auth.middleware.js';
import { resolveUserByPhoneController } from './resolve-user-by-phone.controller.js';
import { verifyParentOtpController } from './verify-parent-otp.controller.js';

const router = Router();

router.post('/resolve-user-by-phone', validate(resolveUserByPhoneSchema), resolveUserByPhoneController);
router.post('/verify-parent-otp', validate(verifyParentOtpSchema), verifyParentOtpController);
router.post('/login', validate(loginSchema), loginController);
router.post('/super-admin/verify-2fa', validate(verify2faSchema), verify2faController);
router.post('/group-admin/login', validate(groupAdminLoginSchema), groupAdminLoginController);
router.post('/group-admin/forgot-password', validate(groupAdminForgotPasswordSchema), groupAdminForgotPasswordController);
router.post('/group-admin/reset-password', validate(groupAdminResetPasswordSchema), groupAdminResetPasswordController);
router.post('/qr-login', validate(qrLoginSchema), qrLoginController);
router.post('/forgot-password', validate(forgotPasswordSchema), forgotPasswordController);
router.post('/reset-password', validate(resetPasswordSchema), resetPasswordController);

// Smart Login endpoints
router.post('/resolve-subdomain', validate(resolveSubdomainSchema), resolveSubdomainController);
router.post('/verify-device-otp', validate(verifyDeviceOtpSchema), verifyDeviceOtpController);
router.post('/resend-device-otp', validate(resendDeviceOtpSchema), resendDeviceOtpController);

router.get('/session-check', sessionCheckController);

router.delete('/logout', logoutController);

router.get('/my-devices', verifyAccessToken, myDevicesController);
router.delete('/devices/:device_id', verifyAccessToken, removeDeviceController);

export default router;
