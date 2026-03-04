import { Router } from 'express';
import { loginController, forgotPasswordController, resetPasswordController } from './auth.controller.js';
import { validate, loginSchema, forgotPasswordSchema, resetPasswordSchema } from './auth.validation.js';

const router = Router();

router.post('/login', validate(loginSchema), loginController);
router.post('/forgot-password', validate(forgotPasswordSchema), forgotPasswordController);
router.post('/reset-password', validate(resetPasswordSchema), resetPasswordController);

export default router;
