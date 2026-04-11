/**
 * Transport Drivers Routes — /api/school/transport/drivers/*
 * School admin / clerk: manage drivers.
 */
import express from 'express';
import * as ctrl from './transport-drivers.controller.js';
import { validate, createDriverSchema, updateDriverSchema } from './transport.validation.js';

const router = express.Router({ mergeParams: true });

router.get('/', ctrl.listDrivers);
router.post('/', validate(createDriverSchema), ctrl.createDriver);
router.get('/:id', ctrl.getDriver);
router.put('/:id', validate(updateDriverSchema), ctrl.updateDriver);
router.delete('/:id', ctrl.deleteDriver);

export default router;
