import * as subscriptionRepository from './subscription.repository.js';
import { AppError } from '../../utils/response.js';

export const createSubscription = async (data) => {
    const { school_id, plan_id, billing_cycle, start_date } = data;

    const plan = await subscriptionRepository.getPlanById(plan_id);
    if (!plan) {
        throw new AppError('Plan not found', 404);
    }

    const startDate = new Date(start_date);
    let endDate = new Date(startDate);
    let priceAmount = 0;

    if (billing_cycle === 'MONTHLY') {
        endDate.setMonth(endDate.getMonth() + 1);
        priceAmount = plan.priceMonthly;
    } else if (billing_cycle === 'YEARLY') {
        endDate.setFullYear(endDate.getFullYear() + 1);
        priceAmount = plan.priceYearly || (plan.priceMonthly * 12);
    }

    const subscriptionData = {
        schoolId: school_id,
        planId: plan_id,
        startDate: startDate,
        endDate: endDate,
        billingCycle: billing_cycle,
        priceAmount: priceAmount,
        currency: data.currency || 'INR',
        status: data.status || 'ACTIVE',
        autoRenew: data.auto_renew || false
    };

    return await subscriptionRepository.createSubscription(subscriptionData);
};

export const upgradeSubscription = async (oldSubscriptionId, newData) => {
    const oldSub = await subscriptionRepository.getSubscriptionById(oldSubscriptionId);
    if (!oldSub) {
        throw new AppError('Existing subscription not found', 404);
    }

    const plan = await subscriptionRepository.getPlanById(newData.plan_id);
    if (!plan) {
        throw new AppError('Plan not found', 404);
    }

    const startDate = new Date(newData.start_date || new Date());
    let endDate = new Date(startDate);
    let priceAmount = 0;

    if (newData.billing_cycle === 'MONTHLY') {
        endDate.setMonth(endDate.getMonth() + 1);
        priceAmount = plan.priceMonthly;
    } else if (newData.billing_cycle === 'YEARLY') {
        endDate.setFullYear(endDate.getFullYear() + 1);
        priceAmount = plan.priceYearly || (plan.priceMonthly * 12);
    }

    const subscriptionData = {
        schoolId: oldSub.schoolId,
        planId: newData.plan_id,
        startDate: startDate,
        endDate: endDate,
        billingCycle: newData.billing_cycle,
        priceAmount: priceAmount,
        currency: newData.currency || 'INR',
        autoRenew: newData.auto_renew || false
    };

    return await subscriptionRepository.upgradeSubscription(oldSubscriptionId, subscriptionData);
};

export const getActiveSubscriptionBySchool = async (schoolId) => {
    return await subscriptionRepository.getActiveSubscriptionBySchool(schoolId);
};

export const toggleSubscriptionStatus = async (id) => {
    const subscription = await subscriptionRepository.getSubscriptionById(id);
    if (!subscription) {
        throw new AppError('Subscription not found', 404);
    }

    if (subscription.status === 'EXPIRED') {
        throw new AppError('Cannot toggle status of an expired subscription', 400);
    }

    const newStatus = subscription.status === 'ACTIVE' ? 'SUSPENDED' : 'ACTIVE';

    return await subscriptionRepository.updateSubscriptionStatus(id, newStatus);
};

export const extendSubscription = async (id, extendMonths) => {
    const subscription = await subscriptionRepository.getSubscriptionById(id);
    if (!subscription) {
        throw new AppError('Subscription not found', 404);
    }

    const currentEndDate = new Date(subscription.endDate);
    const newEndDate = new Date(currentEndDate);
    newEndDate.setMonth(newEndDate.getMonth() + extendMonths);

    return await subscriptionRepository.extendSubscriptionEndDate(id, newEndDate);
};
