
import prisma from '../../config/prisma.js';

const convertBigInts = (obj) => {
    return JSON.parse(
        JSON.stringify(obj, (key, value) =>
            typeof value === 'bigint' ? value.toString() : value
        )
    );
};

export const getAllPlans = async (filters = {}) => {
    const where = {};

    // 1. Fetch all plans (platform_plans has: name, description, price, max_branches, max_users)
    const plans = await prisma.platformPlan.findMany({
        where,
        orderBy: {
            id: 'asc'
        }
    });

    // 2. Map counts (school_subscriptions may not exist; use 0 if unavailable)
    let countsMap = {};
    try {
        const activeCounts = await prisma.schoolSubscription.groupBy({
            by: ['planId'],
            where: { status: 'ACTIVE' },
            _count: { schoolId: true }
        });
        countsMap = activeCounts.reduce((acc, curr) => {
            acc[curr.planId.toString()] = curr._count.schoolId;
            return acc;
        }, {});
    } catch (_) {
        // school_subscriptions table may not exist
    }

    const results = plans.map(plan => ({
        ...plan,
        active_school_count: countsMap[plan.id.toString()] || 0
    }));

    return convertBigInts(results);
};

export const findPlanById = async (id) => {
    const plan = await prisma.platformPlan.findUnique({
        where: { id: BigInt(id) }
    });
    return plan ? convertBigInts(plan) : null;
};

export const checkActiveSchoolsForPlan = async (planId) => {
    const count = await prisma.schoolSubscription.count({
        where: {
            planId: BigInt(planId),
            status: 'ACTIVE'
        }
    });
    return count > 0;
};

export const deletePlan = async (id) => {
    return await prisma.platformPlan.delete({
        where: { id: BigInt(id) }
    });
};

export const updatePlanStatus = async (id, isActive) => {
    const updated = await prisma.platformPlan.update({
        where: { id: BigInt(id) },
        data: { isActive }
    });
    return convertBigInts(updated);
};

export const createPlan = async (data) => {
    const plan = await prisma.platformPlan.create({
        data
    });
    return convertBigInts(plan);
};

export const updatePlan = async (id, data) => {
    const plan = await prisma.platformPlan.update({
        where: { id: BigInt(id) },
        data
    });
    return convertBigInts(plan);
};
