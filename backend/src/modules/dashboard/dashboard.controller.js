import * as dashboardService from './dashboard.service.js';
import { successResponse } from '../../utils/response.js';

export const getDashboardDataController = async (req, res, next) => {
    try {
        const data = await dashboardService.getPlatformMetrics();

        return successResponse(
            res,
            200,
            'Super Admin dashboard metrics retrieved successfully',
            {
                metrics: {
                    total_schools: data.total_schools,
                    active_schools: data.active_schools,
                    total_users: data.total_users,
                    monthly_revenue: data.monthly_revenue,
                    expiring_soon: data.expiring_subscriptions
                },
                recent_activities: []
            }
        );
    } catch (error) {
        next(error);
    }
};
