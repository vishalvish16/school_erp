import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

const convertBigInts = (obj) => {
    return JSON.parse(
        JSON.stringify(obj, (key, value) =>
            typeof value === 'bigint' ? value.toString() : value
        )
    );
};

export const findSchoolById = async (id) => {
    return prisma.school.findUnique({
        where: { id: BigInt(id) }
    });
};

export const findPlanById = async (id) => {
    return prisma.platformPlan.findUnique({
        where: { id: BigInt(id) }
    });
};

export const deactivateActiveSubscriptions = async (schoolId) => {
    return prisma.schoolSubscription.updateMany({
        where: {
            schoolId: BigInt(schoolId),
            status: 'ACTIVE'
        },
        data: {
            status: 'EXPIRED' // Or 'DEACTIVATED'
        }
    });
};

export const createSubscription = async (data) => {
    const subscription = await prisma.schoolSubscription.create({
        data: {
            schoolId: BigInt(data.schoolId),
            planId: BigInt(data.planId),
            startDate: data.startDate,
            endDate: data.endDate,
            billingCycle: data.billingCycle,
            priceAmount: data.priceAmount,
            status: 'ACTIVE'
        }
    });

    // Also update the school's current plan info
    await prisma.school.update({
        where: { id: BigInt(data.schoolId) },
        data: {
            planId: BigInt(data.planId),
            subscriptionStart: data.startDate,
            subscriptionEnd: data.endDate
        }
    });

    return convertBigInts(subscription);
};
