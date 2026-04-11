/**
 * Joi validation schemas for the Transport module.
 */
import Joi from 'joi';
import { AppError } from '../../utils/response.js';

// ── Vehicle Schemas ──────────────────────────────────────────────────────────

export const createVehicleSchema = Joi.object({
  vehicleNo: Joi.string().max(50).required(),
  vehicleType: Joi.string().max(20).optional().allow(null, ''),
  capacity: Joi.number().integer().min(1).max(100).optional().default(30),
  make: Joi.string().max(50).optional().allow(null, ''),
  model: Joi.string().max(50).optional().allow(null, ''),
  year: Joi.number().integer().min(1900).max(2100).optional().allow(null),
  color: Joi.string().max(30).optional().allow(null, ''),
  rcNumber: Joi.string().max(50).optional().allow(null, ''),
  insuranceExpiry: Joi.string().isoDate().optional().allow(null, ''),
  fitnessExpiry: Joi.string().isoDate().optional().allow(null, ''),
  gpsDeviceId: Joi.string().max(100).optional().allow(null, ''),
});

export const updateVehicleSchema = Joi.object({
  vehicleNo: Joi.string().max(50).optional(),
  vehicleType: Joi.string().max(20).optional().allow(null, ''),
  capacity: Joi.number().integer().min(1).max(100).optional(),
  make: Joi.string().max(50).optional().allow(null, ''),
  model: Joi.string().max(50).optional().allow(null, ''),
  year: Joi.number().integer().min(1900).max(2100).optional().allow(null),
  color: Joi.string().max(30).optional().allow(null, ''),
  rcNumber: Joi.string().max(50).optional().allow(null, ''),
  insuranceExpiry: Joi.string().isoDate().optional().allow(null, ''),
  fitnessExpiry: Joi.string().isoDate().optional().allow(null, ''),
  gpsDeviceId: Joi.string().max(100).optional().allow(null, ''),
  isActive: Joi.boolean().optional(),
}).min(1);

export const assignDriverSchema = Joi.object({
  driver_id: Joi.string().uuid().required(),
});

export const assignStudentSchema = Joi.object({
  student_id: Joi.string().uuid().required(),
  pickup_stop_name: Joi.string().max(100).optional().allow(null, ''),
  pickup_lat: Joi.number().min(-90).max(90).optional().allow(null),
  pickup_lng: Joi.number().min(-180).max(180).optional().allow(null),
  drop_stop_name: Joi.string().max(100).optional().allow(null, ''),
  drop_lat: Joi.number().min(-90).max(90).optional().allow(null),
  drop_lng: Joi.number().min(-180).max(180).optional().allow(null),
});

// ── Driver Schemas ───────────────────────────────────────────────────────────

export const createDriverSchema = Joi.object({
  firstName: Joi.string().min(1).max(100).required(),
  lastName: Joi.string().min(1).max(100).required(),
  gender: Joi.string().valid('MALE', 'FEMALE', 'OTHER').required(),
  phone: Joi.string().max(20).required(),
  email: Joi.string().email().max(255).optional().allow(null, ''),
  licenseNumber: Joi.string().max(50).optional().allow(null, ''),
  licenseExpiry: Joi.string().isoDate().optional().allow(null, ''),
  dateOfBirth: Joi.string().isoDate().optional().allow(null, ''),
  address: Joi.string().max(500).optional().allow(null, ''),
  emergencyContactName: Joi.string().max(100).optional().allow(null, ''),
  emergencyContactPhone: Joi.string().max(20).optional().allow(null, ''),
});

export const updateDriverSchema = Joi.object({
  firstName: Joi.string().min(1).max(100).optional(),
  lastName: Joi.string().min(1).max(100).optional(),
  gender: Joi.string().valid('MALE', 'FEMALE', 'OTHER').optional(),
  phone: Joi.string().max(20).optional(),
  email: Joi.string().email().max(255).optional().allow(null, ''),
  licenseNumber: Joi.string().max(50).optional().allow(null, ''),
  licenseExpiry: Joi.string().isoDate().optional().allow(null, ''),
  dateOfBirth: Joi.string().isoDate().optional().allow(null, ''),
  address: Joi.string().max(500).optional().allow(null, ''),
  emergencyContactName: Joi.string().max(100).optional().allow(null, ''),
  emergencyContactPhone: Joi.string().max(20).optional().allow(null, ''),
  isActive: Joi.boolean().optional(),
}).min(1);

// ── Trip Event Schema ────────────────────────────────────────────────────────

export const recordTripEventSchema = Joi.object({
  student_id: Joi.string().uuid().required(),
  event_type: Joi.string().valid('pickup', 'dropoff').required(),
  lat: Joi.number().min(-90).max(90).optional().allow(null),
  lng: Joi.number().min(-180).max(180).optional().allow(null),
});

// ── Driver Auth Schemas ──────────────────────────────────────────────────────

export const driverLoginByVehicleSchema = Joi.object({
  vehicle_number: Joi.string().max(50).required(),
  school_id: Joi.string().uuid().required(),
  password: Joi.string().min(1).required(),
});

export const driverSendOtpSchema = Joi.object({
  vehicle_number: Joi.string().max(50).required(),
  school_id: Joi.string().uuid().required(),
});

export const driverVerifyOtpSchema = Joi.object({
  vehicle_number: Joi.string().max(50).required(),
  school_id: Joi.string().uuid().required(),
  otp: Joi.string().length(6).required(),
});

// ── Validate middleware (Joi) ────────────────────────────────────────────────

export const validate = (schema) => (req, res, next) => {
  const { error, value } = schema.validate(req.body, { abortEarly: false, stripUnknown: true });
  if (error) {
    const details = error.details.map((d) => d.message).join('; ');
    return next(new AppError(`Validation error: ${details}`, 422));
  }
  req.body = value;
  next();
};
