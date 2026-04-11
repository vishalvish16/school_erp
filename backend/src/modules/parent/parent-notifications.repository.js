/**
 * Parent Notifications Repository — CRUD for parent_notifications table.
 * Uses raw SQL since parent_notifications is not in Prisma schema.
 */

import prisma from '../../config/prisma.js';

export async function create({ parentId, schoolId, type, title, body, link, entityType, entityId }) {
    const result = await prisma.$queryRawUnsafe(`
        INSERT INTO parent_notifications (parent_id, school_id, type, title, body, link, entity_type, entity_id)
        VALUES ($1::uuid, $2::uuid, $3, $4, $5, $6, $7, $8::uuid)
        RETURNING id, parent_id, school_id, type, title, body, is_read, link, entity_type, entity_id, created_at
    `, parentId, schoolId, type || 'info', title, body || null, link || null, entityType || null, entityId || null);
    const row = Array.isArray(result) ? result[0] : result;
    return row;
}

export async function findByParent({ parentId, schoolId, page = 1, limit = 20 }) {
    const skip = (page - 1) * limit;
    const rows = await prisma.$queryRawUnsafe(`
        SELECT id, parent_id, school_id, type, title, body, is_read, link, entity_type, entity_id, created_at
        FROM parent_notifications
        WHERE parent_id = $1::uuid AND school_id = $2::uuid
        ORDER BY created_at DESC
        LIMIT $3 OFFSET $4
    `, parentId, schoolId, limit, skip);
    const countResult = await prisma.$queryRawUnsafe(`
        SELECT COUNT(*)::int AS count FROM parent_notifications
        WHERE parent_id = $1::uuid AND school_id = $2::uuid
    `, parentId, schoolId);
    const count = Array.isArray(countResult) && countResult[0]?.count != null
        ? countResult[0].count
        : 0;
    return { data: rows || [], total: count, page, total_pages: Math.ceil(count / limit) || 1 };
}

export async function countUnread(parentId, schoolId) {
    const result = await prisma.$queryRawUnsafe(`
        SELECT COUNT(*)::int AS count FROM parent_notifications
        WHERE parent_id = $1::uuid AND school_id = $2::uuid AND is_read = FALSE
    `, parentId, schoolId);
    const row = Array.isArray(result) ? result[0] : result;
    return row?.count ?? 0;
}

export async function markRead(id, parentId, schoolId) {
    await prisma.$executeRawUnsafe(`
        UPDATE parent_notifications SET is_read = TRUE
        WHERE id = $1::uuid AND parent_id = $2::uuid AND school_id = $3::uuid
    `, id, parentId, schoolId);
}
