/**
 * Theme Repository — Prisma queries for ThemeConfig CRUD
 */
import prisma from '../../config/prisma.js';

const VALID_ROLES = new Set([
  'super_admin', 'school_admin', 'group_admin',
  'staff', 'teacher', 'parent', 'student', 'driver',
]);

export async function getThemeByRole(role) {
  return prisma.themeConfig.findUnique({ where: { role } });
}

export async function upsertTheme(role, lightTokens, darkTokens, presetName, updatedBy) {
  return prisma.themeConfig.upsert({
    where: { role },
    create: { role, lightTokens, darkTokens, presetName: presetName ?? 'Custom', updatedBy },
    update: { lightTokens, darkTokens, presetName: presetName ?? 'Custom', updatedBy },
  });
}

export async function upsertThemeForRoles(roles, lightTokens, darkTokens, updatedBy) {
  const applied = [];
  for (const role of roles) {
    if (!VALID_ROLES.has(role)) continue;
    await prisma.themeConfig.upsert({
      where: { role },
      create: { role, lightTokens, darkTokens, presetName: 'Applied from Super Admin', updatedBy },
      update: { lightTokens, darkTokens, updatedBy },
    });
    applied.push(role);
  }
  return applied;
}
