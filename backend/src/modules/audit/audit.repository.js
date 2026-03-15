/**
 * Audit repository — persists super admin actions to database
 */
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

/**
 * Insert audit log. Uses raw SQL for flexibility (table may exist from migrations).
 * @param {Object} data
 * @param {string} data.actorId - User ID (UUID)
 * @param {string} [data.actorName] - User display name
 * @param {string} [data.actorRole] - Role name
 * @param {string} data.action - Action name (e.g. CREATE_SCHOOL, UPDATE_PLAN)
 * @param {string} [data.entityType] - Entity type (school, plan, billing, etc.)
 * @param {string} [data.entityId] - Entity ID
 * @param {string} [data.entityName] - Entity display name
 * @param {string} [data.ipAddress] - Client IP
 * @param {Object} [data.requestData] - Additional metadata
 */
const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export const insertAuditLog = async (data) => {
    const actorId = data.actorId || null;
    const actorName = (data.actorName || '').substring(0, 100);
    const actorRole = (data.actorRole || '').substring(0, 30);
    const action = (data.action || 'UNKNOWN').substring(0, 80);
    const entityType = (data.entityType || '').substring(0, 30) || null;
    const rawEntityId = data.entityId != null ? String(data.entityId) : null;
    const entityId = rawEntityId && UUID_REGEX.test(rawEntityId) ? rawEntityId : null;
    const entityName = (data.entityName || '').substring(0, 150) || null;
    const ipAddress = data.ipAddress || '0.0.0.0';
    const reqData = data.requestData || {};
    if (rawEntityId && !entityId) reqData.entity_id = rawEntityId;
    const requestData = JSON.stringify(reqData);

    try {
        await prisma.$executeRawUnsafe(`
            INSERT INTO audit_super_admin_logs (
                actor_id, actor_name, actor_role, action,
                entity_type, entity_id, entity_name, ip_address, request_data
            ) VALUES (
                $1::uuid, $2, $3, $4, $5, $6::uuid, $7, $8::inet, $9::jsonb
            )
        `, actorId, actorName, actorRole, action, entityType, entityId, entityName, ipAddress, requestData);
        return true;
    } catch (err) {
        if (err.code === '42P01' || err.message?.includes('does not exist')) {
            try {
                await prisma.$executeRawUnsafe(`
                    CREATE TABLE IF NOT EXISTS audit_super_admin_logs (
                        id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
                        actor_id UUID REFERENCES users(id) ON DELETE SET NULL,
                        actor_name VARCHAR(100),
                        actor_role VARCHAR(30),
                        action VARCHAR(80) NOT NULL,
                        entity_type VARCHAR(30),
                        entity_id UUID,
                        entity_name VARCHAR(150),
                        ip_address INET DEFAULT '0.0.0.0'::inet,
                        request_data JSONB DEFAULT '{}',
                        created_at TIMESTAMPTZ DEFAULT NOW()
                    )
                `);
                await prisma.$executeRawUnsafe(`
                    INSERT INTO audit_super_admin_logs (
                        actor_id, actor_name, actor_role, action,
                        entity_type, entity_id, entity_name, ip_address, request_data
                    ) VALUES (
                        $1::uuid, $2, $3, $4, $5, $6::uuid, $7, $8::inet, $9::jsonb
                    )
                `, actorId, actorName, actorRole, action, entityType, entityId, entityName, ipAddress, requestData);
                return true;
            } catch (retryErr) {
                console.error('[Audit] Insert failed:', retryErr.message);
                return false;
            }
        }
        console.error('[Audit] Insert failed:', err.message);
        return false;
    }
};
