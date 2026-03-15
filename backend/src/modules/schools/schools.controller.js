import * as schoolService from './schools.service.js';
import { successResponse } from '../../utils/response.js';

export const createSchool = async (req, res, next) => {
    try {
        const adminUser = req.user || {};
        const school = await schoolService.createSchool(req.body, adminUser, { req });
        return successResponse(res, 201, 'School created successfully', school);
    } catch (error) {
        next(error);
    }
};

export const getSchools = async (req, res, next) => {
    try {
        const result = await schoolService.getSchools(req.query);
        return successResponse(res, 200, 'Schools retrieved successfully', result);
    } catch (error) {
        next(error);
    }
};

export const getSchoolById = async (req, res, next) => {
    try {
        const { id } = req.params;
        const school = await schoolService.getSchoolById(id);
        return successResponse(res, 200, 'School retrieved successfully', school);
    } catch (error) {
        next(error);
    }
};

export const updateSchool = async (req, res, next) => {
    try {
        const adminUser = req.user || {};
        const { id } = req.params;
        const school = await schoolService.updateSchool(id, req.body, adminUser, { req });
        return successResponse(res, 200, 'School updated successfully', school);
    } catch (error) {
        next(error);
    }
};

export const deleteSchool = async (req, res, next) => {
    try {
        const adminUser = req.user || {};
        const { id } = req.params;
        await schoolService.deleteSchool(id, adminUser, { req });
        return successResponse(res, 200, 'School suspended successfully');
    } catch (error) {
        next(error);
    }
};

export const assignPlan = async (req, res, next) => {
    try {
        const adminUser = req.user || {};
        const { id } = req.params;
        const subscription = await schoolService.assignPlan(id, req.body, adminUser, { req });
        return successResponse(res, 201, 'Plan assigned successfully', subscription);
    } catch (error) {
        next(error);
    }
};
