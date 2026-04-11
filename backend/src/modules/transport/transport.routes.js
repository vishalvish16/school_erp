/**
 * Transport Routes — /api/school/transport/*
 * Aggregates vehicle CRUD, driver CRUD, student assignment, and live tracking.
 */
import express from 'express';
import { verifyAccessToken } from '../../middleware/auth.middleware.js';
import vehicleRoutes from './transport-vehicles.routes.js';
import driverRoutes from './transport-drivers.routes.js';

const router = express.Router();
router.use(verifyAccessToken);

// Mount sub-routers
router.use('/drivers', driverRoutes);
router.use('/', vehicleRoutes);

export default router;
