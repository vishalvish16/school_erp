import * as plansService from './plans.service.js';
import { successResponse } from '../../utils/response.js';

export const getPlans = async (req, res, next) => {
    try {
        const filters = req.query;
        const data = await plansService.getPlans(filters);

        // Format the response as requested
        const formattedData = data.map(plan => ({
            plan_id: plan.id,
            plan_name: plan.name,
            max_students: plan.maxStudents,
            max_teachers: plan.maxTeachers,
            max_branches: plan.maxBranches,
            price_monthly: plan.priceMonthly,
            price_yearly: plan.priceYearly,
            is_active: plan.isActive,
            active_school_count: plan.active_school_count
        }));

        return successResponse(
            res,
            200,
            'Platform plans retrieved successfully',
            formattedData
        );
    } catch (error) {
        next(error);
    }
};

export const deletePlan = async (req, res, next) => {
    try {
        const { id } = req.params;
        await plansService.deletePlan(id);

        return successResponse(
            res,
            200,
            'Plan deleted successfully'
        );
    } catch (error) {
        if (error.message === 'Plan not found') {
            return res.status(404).json({
                success: false,
                message: 'Plan not found'
            });
        }
        if (error.message === 'IN_USE_ACTIVE') {
            return res.status(400).json({
                success: false,
                message: 'Cannot delete plan. It is currently assigned to active schools.'
            });
        }
        if (error.message === 'ENTERPRISE_PROTECTED') {
            return res.status(403).json({
                success: false,
                message: 'Protected system plans (Enterprise) cannot be deleted.'
            });
        }
        next(error);
    }
};

export const togglePlanStatus = async (req, res, next) => {
    try {
        const { id } = req.params;
        const updatedPlan = await plansService.togglePlanStatus(id);

        return successResponse(
            res,
            200,
            `Plan ${updatedPlan.isActive ? 'activated' : 'deactivated'} successfully`,
            {
                plan_id: updatedPlan.id,
                plan_name: updatedPlan.name,
                is_active: updatedPlan.isActive
            }
        );
    } catch (error) {
        if (error.message === 'Plan not found') {
            return res.status(404).json({
                success: false,
                message: 'Plan not found'
            });
        }
        next(error);
    }
};

export const createPlan = async (req, res, next) => {
    try {
        const data = await plansService.createPlan(req.body);

        return successResponse(
            res,
            201,
            'Plan created successfully',
            {
                plan_id: data.id,
                plan_name: data.name
            }
        );
    } catch (error) {
        next(error);
    }
};

export const updatePlan = async (req, res, next) => {
    try {
        const { id } = req.params;
        const data = await plansService.updatePlan(id, req.body);

        return successResponse(
            res,
            200,
            'Plan updated successfully',
            {
                plan_id: data.id,
                plan_name: data.name
            }
        );
    } catch (error) {
        if (error.message === 'Plan not found') {
            return res.status(404).json({
                success: false,
                message: 'Plan not found'
            });
        }
        next(error);
    }
};
