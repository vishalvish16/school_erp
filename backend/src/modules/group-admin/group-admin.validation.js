import Joi from 'joi';

export const changePasswordSchema = Joi.object({
  current_password: Joi.string().min(6).required(),
  new_password: Joi.string().min(8).required(),
});
