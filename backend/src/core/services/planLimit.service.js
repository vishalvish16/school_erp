import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

/**
 * Reusable service to enforce plan limits before creating entities (Student, Teacher, Branch).
 * 
 * Logic:
 * 1. Finds the school's current ACTIVE subscription.
 * 2. Retrieves the associated Platform Plan.
 * 3. Calculates current usage of the requested entity type.
 * 4. Compares usage against plan maximums.
 * 5. Throws an error if the limit is reached.
 * 
 * @param {Object} params
 * @param {string|number|bigint} params.schoolId - The ID of the school to check.
 * @param {'STUDENT'|'TEACHER'|'BRANCH'} params.entityType - Type of record being evaluated.
 * @returns {Promise<Object>} Returns { limit, current } if check passes.
 * @throws {Error} if limits are exceeded.
 */
export async function checkLimit({ schoolId, entityType }) {
    if (!schoolId) throw new Error('schoolId is required for limit enforcement.');
    if (!entityType) throw new Error('entityType is required for limit enforcement.');

    // 1 & 2) Get school's ACTIVE subscription and related plan
    const subscription = await prisma.schoolSubscription.findFirst({
        where: {
            schoolId: BigInt(schoolId),
            status: 'ACTIVE'
        },
        include: {
            plan: true
        }
    });

    if (!subscription || !subscription.plan) {
        throw new Error('No active subscription found. Access restricted.');
    }

    const plan = subscription.plan;
    let currentUsage = 0;
    let maxLimit = 0;

    const normalizedType = entityType.toUpperCase();

    // 3) Count current usage
    switch (normalizedType) {
        case 'BRANCH':
            currentUsage = await prisma.branch.count({
                where: {
                    schoolId: BigInt(schoolId),
                    // We don't usually soft-delete branches in standard setup yet,
                    // but if we do, filter them here.
                }
            });
            maxLimit = plan.maxBranches;
            break;

        case 'STUDENT':
            // Count users with Student role. Supporting both uppercase and proper case names.
            currentUsage = await prisma.user.count({
                where: {
                    schoolId: BigInt(schoolId),
                    role: {
                        name: {
                            in: ['STUDENT', 'Student']
                        }
                    },
                    deletedAt: null // Only count non-soft-deleted identities
                }
            });
            maxLimit = plan.maxStudents;
            break;

        case 'TEACHER':
            // Count users in any teaching capacity roles.
            currentUsage = await prisma.user.count({
                where: {
                    schoolId: BigInt(schoolId),
                    role: {
                        name: {
                            in: ['TEACHER', 'Teacher', 'Class Teacher', 'Subject Teacher']
                        }
                    },
                    deletedAt: null
                }
            });
            maxLimit = plan.maxTeachers;
            break;

        default:
            throw new Error(`Unsupported entity type for limit check: ${entityType}`);
    }

    // 4 & 5) Compare and enforce
    // If currentUsage >= maxLimit, then adding 1 more would exceed the limit.
    if (currentUsage >= maxLimit) {
        const error = new Error(`Plan limit exceeded for ${normalizedType}. Upgrade your plan.`);
        error.limit = maxLimit;
        error.current = currentUsage;
        error.entityType = normalizedType;
        error.statusCode = 403; // Forbidden due to plan limits
        throw error;
    }

    return {
        limit: maxLimit,
        current: currentUsage,
        remaining: maxLimit - currentUsage
    };
}
