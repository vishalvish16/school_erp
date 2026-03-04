import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

const convertBigInts = (obj) => {
    return JSON.parse(
        JSON.stringify(obj, (key, value) =>
            typeof value === 'bigint' ? value.toString() : value
        )
    );
};

export const createSubscription = async (data) => {
    return await prisma.$transaction(async (tx) => {
        // Create the subscription
        const subscription = await tx.schoolSubscription.create({
            data: {
                schoolId: BigInt(data.schoolId),
                planId: BigInt(data.planId),
                startDate: new Date(data.startDate),
                endDate: new Date(data.endDate),
                billingCycle: data.billingCycle,
                priceAmount: data.priceAmount,
                currency: data.currency || 'INR',
                status: data.status,
                autoRenew: data.autoRenew || false
            }
        });

        // Update the school with the current subscription ID
        await tx.school.update({
            where: { id: BigInt(data.schoolId) },
            data: {
                currentSubscriptionId: subscription.id,
                planId: BigInt(data.planId),
                subscriptionStart: new Date(data.startDate),
                subscriptionEnd: new Date(data.endDate)
            }
        });

        return convertBigInts(subscription);
    });
};

export const upgradeSubscription = async (oldSubscriptionId, newData) => {
    return await prisma.$transaction(async (tx) => {
        // 1. Mark the old subscription as EXPIRED
        await tx.schoolSubscription.update({
            where: { id: BigInt(oldSubscriptionId) },
            data: { status: 'EXPIRED' }
        });

        // 2. Create the new subscription
        const newSubscription = await tx.schoolSubscription.create({
            data: {
                schoolId: BigInt(newData.schoolId),
                planId: BigInt(newData.planId),
                startDate: new Date(newData.startDate),
                endDate: new Date(newData.endDate),
                billingCycle: newData.billingCycle,
                priceAmount: newData.priceAmount,
                currency: newData.currency || 'INR',
                status: 'ACTIVE',
                autoRenew: newData.autoRenew || false
            }
        });

        // 3. Update the school
        await tx.school.update({
            where: { id: BigInt(newData.schoolId) },
            data: {
                currentSubscriptionId: newSubscription.id,
                planId: BigInt(newData.planId),
                subscriptionStart: new Date(newData.startDate),
                subscriptionEnd: new Date(newData.endDate)
            }
        });

        return convertBigInts(newSubscription);
    });
};

export const getActiveSubscriptionBySchool = async (schoolId) => {
    const subscription = await prisma.schoolSubscription.findFirst({
        where: {
            schoolId: BigInt(schoolId),
            status: 'ACTIVE'
        },
        include: {
            plan: true
        },
        orderBy: {
            createdAt: 'desc'
        }
    });
    return subscription ? convertBigInts(subscription) : null;
};

export const getSubscriptionById = async (id) => {
    const subscription = await prisma.schoolSubscription.findUnique({
        where: { id: BigInt(id) }
    });
    return subscription ? convertBigInts(subscription) : null;
};

export const getPlanById = async (id) => {
    const plan = await prisma.platformPlan.findUnique({
        where: { id: BigInt(id) }
    });
    return plan ? convertBigInts(plan) : null;
};

export const updateSubscriptionStatus = async (id, status) => {
    const updated = await prisma.schoolSubscription.update({
        where: { id: BigInt(id) },
        data: { status }
    });
    return convertBigInts(updated);
};

export const extendSubscriptionEndDate = async (id, newEndDate) => {
    return await prisma.$transaction(async (tx) => {
        const updatedSub = await tx.schoolSubscription.update({
            where: { id: BigInt(id) },
            data: { endDate: new Date(newEndDate) }
        });

        // Also update the school's cached end date if this is their current subscription
        await tx.school.updateMany({
            where: { currentSubscriptionId: BigInt(id) },
            data: { subscriptionEnd: new Date(newEndDate) }
        });

        return convertBigInts(updatedSub);
    });
};


