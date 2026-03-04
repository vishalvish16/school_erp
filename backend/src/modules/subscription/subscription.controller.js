import * as subscriptionService from './subscription.service.js';
import { successResponse } from '../../utils/response.js';

export const createSubscription = async (req, res, next) => {
    try {
        const data = await subscriptionService.createSubscription(req.body);
        return successResponse(res, 201, 'Subscription created successfully', data);
    } catch (error) {
        next(error);
    }
};

export const upgradeSubscription = async (req, res, next) => {
    try {
        const { id } = req.params;
        const data = await subscriptionService.upgradeSubscription(id, req.body);
        return successResponse(res, 200, 'Subscription upgraded successfully', data);
    } catch (error) {
        next(error);
    }
};

export const getSchoolSubscription = async (req, res, next) => {
    try {
        const { school_id } = req.params;
        const data = await subscriptionService.getActiveSubscriptionBySchool(school_id);
        return successResponse(res, 200, 'Active subscription retrieved successfully', data);
    } catch (error) {
        next(error);
    }
};

export const toggleSubscriptionStatus = async (req, res, next) => {
    try {
        const { id } = req.params;
        const data = await subscriptionService.toggleSubscriptionStatus(id);
        return successResponse(res, 200, `Subscription status toggled to ${data.status}`, data);
    } catch (error) {
        next(error);
    }
};

export const extendSubscription = async (req, res, next) => {
    try {
        const { id } = req.params;
        const { extend_months } = req.body;
        const data = await subscriptionService.extendSubscription(id, extend_months);
        return successResponse(res, 200, 'Subscription extended successfully', data);
    } catch (error) {
        next(error);
    }
};

