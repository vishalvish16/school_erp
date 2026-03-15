/**
 * Audit service — logs super admin actions for audit trail
 */
import * as auditRepo from './audit.repository.js';

/**
 * Log an audit event. Fire-and-forget; never throws.
 * @param {Object} ctx - Audit context
 * @param {string} ctx.actorId - User ID (from req.user.userId)
 * @param {string} [ctx.actorName] - User display name
 * @param {string} [ctx.actorRole] - Role (e.g. super_admin)
 * @param {string} ctx.action - Action name (CREATE_SCHOOL, UPDATE_PLAN, etc.)
 * @param {string} [ctx.entityType] - schools | plans | billing | features | groups
 * @param {string} [ctx.entityId] - Entity UUID
 * @param {string} [ctx.entityName] - Entity display name
 * @param {string} [ctx.ipAddress] - Client IP (from req.ip)
 * @param {Object} [ctx.extra] - Additional metadata
 */
export const logAudit = async (ctx) => {
    if (!ctx?.action) return;
    try {
        await auditRepo.insertAuditLog({
            actorId: ctx.actorId,
            actorName: ctx.actorName,
            actorRole: ctx.actorRole,
            action: ctx.action,
            entityType: ctx.entityType,
            entityId: ctx.entityId,
            entityName: ctx.entityName,
            ipAddress: ctx.ipAddress || '0.0.0.0',
            requestData: ctx.extra,
        });
    } catch (err) {
        console.error('[Audit] logAudit failed:', err.message);
    }
};
