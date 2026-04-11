
import prisma from '../../config/prisma.js';

export const getPlatformMetrics = async () => {
    const currentDate = new Date();

    // Expiration threshold (30 days from now)
    const expirationThreshold = new Date();
    expirationThreshold.setDate(currentDate.getDate() + 30);

    // Use Promise.all to fetch counts fully concurrently without N+1
    const [
        totalSchools,
        activeSchools,
        totalUsers,
        expiringSubscriptions,
        activeSchoolsWithPlans
    ] = await Promise.all([
        // 1. Total schools count
        prisma.school.count(),

        // 2. Active schools count
        prisma.school.count({
            where: { isActive: true }
        }),

        // 3. Total users count
        prisma.user.count(),

        // 4. Expiring subscriptions count (only active schools, expiring within 30 days)
        prisma.school.count({
            where: {
                isActive: true,
                subscriptionEnd: {
                    gte: currentDate,
                    lte: expirationThreshold
                }
            }
        }),

        // 5. Optimized fetch for Monthly Revenue 
        // Pulls only the price decimal for active schools instead of the whole object tree.
        prisma.school.findMany({
            where: { isActive: true },
            select: {
                plan: {
                    select: { priceMonthly: true }
                }
            }
        })
    ]);

    // Aggregate monthly revenue directly
    const monthlyRevenue = activeSchoolsWithPlans.reduce((sum, school) => {
        return sum + (school.plan?.priceMonthly ? parseFloat(school.plan.priceMonthly) : 0);
    }, 0);

    return {
        total_schools: totalSchools,
        active_schools: activeSchools,
        total_users: totalUsers,
        monthly_revenue: monthlyRevenue,
        expiring_subscriptions: expiringSubscriptions
    };
};
