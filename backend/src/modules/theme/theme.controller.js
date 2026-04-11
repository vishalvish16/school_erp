/**
 * Theme Controller — HTTP handlers for theme configuration API
 */
import * as service from './theme.service.js';
import { successResponse } from '../../utils/response.js';

export async function getSuperAdminTheme(req, res, next) {
  try {
    const config = await service.getSuperAdminTheme();
    return successResponse(res, 200, 'Theme retrieved', config);
  } catch (err) {
    next(err);
  }
}

export async function saveSuperAdminTheme(req, res, next) {
  try {
    const { light, dark, presetName } = req.body;
    const updatedBy = req.user?.email || String(req.user?.id ?? '');
    const config = await service.saveSuperAdminTheme(light, dark, presetName, updatedBy);
    return successResponse(res, 200, 'Theme saved successfully', config);
  } catch (err) {
    next(err);
  }
}

export async function applyThemeToPortals(req, res, next) {
  try {
    const { portals, light, dark } = req.body;
    const updatedBy = req.user?.email || String(req.user?.id ?? '');
    const applied = await service.applyThemeToPortals(portals, light, dark, updatedBy);
    return successResponse(res, 200, `Theme applied to ${applied.length} portals`, { applied });
  } catch (err) {
    next(err);
  }
}

export async function getSchoolPortalTheme(req, res, next) {
  try {
    const roleName = (req.user?.role_name ?? '').toLowerCase().replace(/ /g, '_');
    const roleMap = {
      school_admin: 'school_admin',
      staff: 'staff',
      clerk: 'staff',
      teacher: 'teacher',
      student: 'student',
    };
    const themeRole = roleMap[roleName] ?? 'school_admin';
    const config = await service.getThemeForRole(themeRole);
    const data = config ? { light: config.lightTokens, dark: config.darkTokens } : null;
    return successResponse(res, 200, 'Theme retrieved', data);
  } catch (err) {
    next(err);
  }
}

export async function getParentTheme(req, res, next) {
  try {
    const config = await service.getThemeForRole('parent');
    const data = config ? { light: config.lightTokens, dark: config.darkTokens } : null;
    return successResponse(res, 200, 'Theme retrieved', data);
  } catch (err) {
    next(err);
  }
}
