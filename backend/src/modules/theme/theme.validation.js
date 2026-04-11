/**
 * Theme Validation — Joi schemas for 50-token theme objects
 */
import Joi from 'joi';

const hexColor = Joi.string().pattern(/^#[0-9A-Fa-f]{3,8}$/).required();
const hexOrTransparent = Joi.string().pattern(/^(#[0-9A-Fa-f]{3,8}|transparent)$/).required();

const tokenShape = Joi.object({
  // Surface
  surfaceBg: hexColor,
  cardBg: hexColor,
  sidebarBg: hexColor,
  topbarBg: hexColor,
  // Text
  textPrimary: hexColor,
  textSecondary: hexColor,
  textHint: hexColor,
  textLink: hexColor,
  // Primary
  primary: hexColor,
  primaryLight: hexColor,
  primaryDark: hexColor,
  onPrimary: hexColor,
  // Tables
  tableHeaderBg: hexColor,
  tableHeaderText: hexColor,
  tableRowEvenBg: hexColor,
  tableRowOddBg: hexColor,
  tableBorder: hexColor,
  tableHoverBg: hexColor,
  // Inputs
  inputBg: hexColor,
  inputBorder: hexColor,
  inputFocusBorder: hexColor,
  inputLabel: hexColor,
  // Buttons
  buttonPrimaryBg: hexColor,
  buttonPrimaryText: hexColor,
  buttonSecondaryBg: hexColor,
  buttonSecondaryText: hexColor,
  buttonDangerBg: hexColor,
  // Chips
  chipActiveBg: hexColor,
  chipActiveText: hexColor,
  chipInactiveBg: hexColor,
  // Status
  successBg: hexColor,
  successText: hexColor,
  warningBg: hexColor,
  warningText: hexColor,
  errorBg: hexColor,
  errorText: hexColor,
  infoBg: hexColor,
  infoText: hexColor,
  // Navigation
  navItemBg: hexOrTransparent,
  navItemActiveBg: hexColor,
  navItemText: hexColor,
  navItemActiveText: hexColor,
  navItemIcon: hexColor,
  navItemActiveIcon: hexColor,
  // Borders
  divider: hexColor,
  cardBorder: hexColor,
  shadowColor: hexColor,
  // Shimmer
  shimmerBase: hexColor,
  shimmerHighlight: hexColor,
}).unknown(true); // allow extra keys for forward-compat

export const saveThemeSchema = Joi.object({
  light: tokenShape.required(),
  dark: tokenShape.required(),
  presetName: Joi.string().max(100).optional(),
});

export const applyThemeSchema = Joi.object({
  portals: Joi.array()
    .items(Joi.string().valid('school_admin', 'group_admin', 'staff', 'teacher', 'parent', 'student', 'driver'))
    .min(1)
    .required(),
  light: tokenShape.required(),
  dark: tokenShape.required(),
});

export function validateBody(schema) {
  return (req, res, next) => {
    const { error } = schema.validate(req.body, { abortEarly: false });
    if (error) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        details: error.details.map(d => d.message),
      });
    }
    next();
  };
}
