import * as plansRepository from './plans.repository.js';

export const getPlans = async (filters) => {
    return await plansRepository.getAllPlans(filters);
};

export const deletePlan = async (id) => {
    const plan = await plansRepository.findPlanById(id);
    if (!plan) {
        throw new Error('Plan not found'); // Should be captured by controller as 404
    }

    // Safeguard: Check if it's the Enterprise default plan
    if (plan.name.toLowerCase().includes('enterprise')) {
        throw new Error('ENTERPRISE_PROTECTED');
    }

    // Check for active schools
    const hasActiveSchools = await plansRepository.checkActiveSchoolsForPlan(id);
    if (hasActiveSchools) {
        throw new Error('IN_USE_ACTIVE');
    }

    return await plansRepository.deletePlan(id);
};

export const togglePlanStatus = async (id) => {
    const plan = await plansRepository.findPlanById(id);
    if (!plan) {
        throw new Error('Plan not found');
    }

    const newStatus = !plan.isActive;
    return await plansRepository.updatePlanStatus(id, newStatus);
};

export const createPlan = async (data) => {
    return await plansRepository.createPlan(data);
};

export const updatePlan = async (id, data) => {
    const plan = await plansRepository.findPlanById(id);
    if (!plan) {
        throw new Error('Plan not found');
    }
    return await plansRepository.updatePlan(id, data);
};
