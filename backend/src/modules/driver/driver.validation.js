/**
 * Joi validation schemas for the Driver Portal module.
 */
import Joi from 'joi';
import { AppError } from '../../utils/response.js';

export const updateProfileSchema = Joi.object({
  phone: Joi.string().max(20).optional().allow(null, ''),
  emergencyContactName: Joi.string().max(100).optional().allow(null, ''),
  emergencyContactPhone: Joi.string().max(20).optional().allow(null, ''),
  address: Joi.string().max(500).optional().allow(null, ''),
}).min(1);

export const changePasswordSchema = Joi.object({
  currentPassword: Joi.string().min(8).required(),
  newPassword: Joi.string().min(8).required(),
});

export const validate = (schema) => (req, res, next) => {
  const { error, value } = schema.validate(req.body, { abortEarly: false, stripUnknown: true });
  if (error) {
    const details = error.details.map((d) => d.message).join('; ');
    return next(new AppError(`Validation error: ${details}`, 422));
  }
  req.body = value;
  next();
};
