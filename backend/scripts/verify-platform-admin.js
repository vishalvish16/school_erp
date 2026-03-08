#!/usr/bin/env node
/**
 * Verify and fix platform admin user for Super Admin login.
 * Run: node scripts/verify-platform-admin.js
 * (from backend folder, or set DATABASE_URL)
 *
 * Uses raw SQL to work with both migration schema (users.id) and
 * platform schema (users.user_id).
 *
 * Checks that vishal.vish16@gmail.com has:
 * - school_id: null
 * - role.role_type: PLATFORM
 */

import 'dotenv/config';
if (!process.env.DATABASE_URL) {
  process.env.DATABASE_URL = 'postgresql://postgres:postgres@localhost:5432/school_erp';
  console.log('Using default DATABASE_URL (create backend/.env to override)');
}

import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();
const ADMIN_EMAIL = 'vishal.vish16@gmail.com';

async function main() {
  console.log('Checking platform admin user:', ADMIN_EMAIL);

  // Query users only (no role join — roles table may have different column names)
  let users = await prisma.$queryRawUnsafe(
    `SELECT id as user_id, school_id, role_id, email FROM users WHERE email = $1 LIMIT 1`,
    ADMIN_EMAIL
  ).catch(() => null);

  if (!users || users.length === 0) {
    // Try platform schema (user_id column)
    const platformUsers = await prisma.$queryRawUnsafe(
      `SELECT u.user_id, u.school_id, u.role_id, u.email, r.role_type, r.role_name
       FROM platform.users u
       LEFT JOIN platform.roles r ON r.role_id = u.role_id
       WHERE u.email = $1
       LIMIT 1`,
      ADMIN_EMAIL
    ).catch(() => null);

    if (!platformUsers || platformUsers.length === 0) {
      console.error('❌ User not found. Run: npx prisma db seed');
      process.exit(1);
    }

    const u = platformUsers[0];
    const hasSchool = u.school_id != null;
    const isPlatform = String(u.role_type || '').toUpperCase() === 'PLATFORM';
    console.log('  school_id:', u.school_id ?? 'null');
    console.log('  role:', u.role_name, '| role_type:', u.role_type);

    if (!hasSchool && isPlatform) {
      console.log('✅ User is correctly configured as platform admin.');
      return;
    }

    let platformRole = await prisma.$queryRawUnsafe(
      `SELECT role_id FROM platform.roles WHERE school_id IS NULL AND role_type = 'PLATFORM' LIMIT 1`
    ).catch(() => []);
    if (!platformRole || platformRole.length === 0) {
      await prisma.$executeRawUnsafe(
        `INSERT INTO platform.roles (school_id, role_name, role_type, description) VALUES (NULL, 'Super Admin', 'PLATFORM', 'Root access')`
      );
      platformRole = await prisma.$queryRawUnsafe(
        `SELECT role_id FROM platform.roles WHERE school_id IS NULL AND role_type = 'PLATFORM' ORDER BY role_id DESC LIMIT 1`
      );
    }
    const roleId = platformRole[0]?.role_id;
    if (roleId) {
      await prisma.$executeRawUnsafe(
        `UPDATE platform.users SET school_id = NULL, branch_id = NULL, role_id = $1 WHERE user_id = $2`,
        roleId,
        u.user_id
      );
      console.log('✅ Updated user to platform admin.');
    }
    return;
  }

  const u = users[0];
  const hasSchool = u.school_id != null;

  // Get role type if roles table has role_type column
  let roleType = null;
  try {
    const r2 = await prisma.$queryRawUnsafe(
      `SELECT role_type FROM roles WHERE id = $1 LIMIT 1`,
      u.role_id
    );
    if (r2?.[0]) roleType = r2[0].role_type;
  } catch (_) {}
  const isPlatform = String(roleType || '').toUpperCase() === 'PLATFORM';

  console.log('  school_id:', u.school_id ?? 'null');
  console.log('  role_id:', u.role_id, '| role_type:', roleType ?? '(unknown)');

  if (!hasSchool && isPlatform) {
    console.log('✅ User is correctly configured as platform admin.');
    return;
  }

  // Find platform role — roles table may lack school_id or role_type
  let platformRoleId = null;
  const strategies = [
    () => prisma.$queryRawUnsafe(`SELECT id FROM roles WHERE role_type = 'PLATFORM' LIMIT 1`),
    () => prisma.$queryRawUnsafe(`SELECT id FROM roles WHERE name = 'Super Admin' LIMIT 1`),
    () => prisma.$queryRawUnsafe(`SELECT id FROM roles WHERE name ILIKE '%platform%' OR name ILIKE '%admin%' LIMIT 1`),
  ];
  for (const fn of strategies) {
    try {
      const rows = await fn();
      if (rows?.[0]?.id) {
        platformRoleId = rows[0].id;
        break;
      }
    } catch (_) {}
  }

  // Update user: set school_id = NULL (required for platform admin)
  // Cast id to uuid if needed (users.id may be UUID type)
  const updateParams = platformRoleId ? [platformRoleId, u.user_id] : [u.user_id];
  let updateSql = platformRoleId
    ? `UPDATE users SET school_id = NULL, branch_id = NULL, role_id = $1 WHERE id = $2::uuid`
    : `UPDATE users SET school_id = NULL, branch_id = NULL WHERE id = $1::uuid`;
  try {
    await prisma.$executeRawUnsafe(updateSql, ...updateParams);
  } catch (e) {
    updateSql = platformRoleId
      ? `UPDATE users SET school_id = NULL, role_id = $1 WHERE id = $2::uuid`
      : `UPDATE users SET school_id = NULL WHERE id = $1::uuid`;
    await prisma.$executeRawUnsafe(updateSql, ...updateParams);
  }

  console.log('✅ Updated user to platform admin (school_id=null' + (platformRoleId ? ', role=PLATFORM' : '') + ').');
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
