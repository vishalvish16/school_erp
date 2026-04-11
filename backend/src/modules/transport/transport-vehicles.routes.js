/**
 * Transport Vehicles Routes — /api/school/transport/*
 * Vehicle CRUD, driver/student assignment, and student/parent bus tracking.
 */
import express from 'express';
import { verifyAccessToken } from '../../middleware/auth.middleware.js';
import * as ctrl from './transport-vehicles.controller.js';
import { validate, createVehicleSchema, updateVehicleSchema, assignDriverSchema, assignStudentSchema } from './transport.validation.js';

const router = express.Router();
router.use(verifyAccessToken);

// Unassigned students (before /:id to avoid conflict)
router.get('/students/unassigned', ctrl.listUnassignedStudents);

// Student/Parent bus tracking
router.get('/my-vehicle', ctrl.getMyVehicle);
router.get('/my-trips', ctrl.getMyTrips);
router.get('/child/:studentId/vehicle', ctrl.getChildVehicle);
router.get('/child/:studentId/trips', ctrl.getChildTrips);

// Vehicles CRUD
router.get('/vehicles/live', ctrl.getLiveVehicles);
router.get('/vehicles', ctrl.listVehicles);
router.post('/vehicles', validate(createVehicleSchema), ctrl.createVehicle);
router.get('/vehicles/:id', ctrl.getVehicle);
router.put('/vehicles/:id', validate(updateVehicleSchema), ctrl.updateVehicle);
router.delete('/vehicles/:id', ctrl.deleteVehicle);

// Driver assignment
router.post('/vehicles/:id/assign-driver', validate(assignDriverSchema), ctrl.assignDriver);
router.delete('/vehicles/:id/unassign-driver', ctrl.unassignDriver);

// Student assignment
router.get('/vehicles/:id/students', ctrl.listVehicleStudents);
router.post('/vehicles/:id/students', validate(assignStudentSchema), ctrl.assignStudent);
router.delete('/vehicles/:id/students/:studentId', ctrl.removeStudent);

export default router;
