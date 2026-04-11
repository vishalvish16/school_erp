/**
 * Theme Service — business logic for theme configuration
 */
import * as repo from './theme.repository.js';
import { AppError } from '../../utils/response.js';

const VALID_PORTALS = ['school_admin', 'group_admin', 'staff', 'teacher', 'parent', 'student', 'driver'];

export async function getSuperAdminTheme() {
  return repo.getThemeByRole('super_admin');
}

export async function saveSuperAdminTheme(lightTokens, darkTokens, presetName, updatedBy) {
  return repo.upsertTheme('super_admin', lightTokens, darkTokens, presetName, updatedBy);
}

export async function applyThemeToPortals(portals, lightTokens, darkTokens, updatedBy) {
  const validPortals = portals.filter(p => VALID_PORTALS.includes(p));
  if (validPortals.length === 0) throw new AppError('No valid portals specified', 400);
  return repo.upsertThemeForRoles(validPortals, lightTokens, darkTokens, updatedBy);
}

export async function getThemeForRole(role) {
  return repo.getThemeByRole(role);
}
