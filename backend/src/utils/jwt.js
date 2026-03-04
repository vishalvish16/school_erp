import jwt from 'jsonwebtoken';
import { env } from '../config/env.js';

/**
 * Generate a short-lived Access Token
 * @param {Object} payload Data to encode in the token
 * @returns {string} JWT Access Token
 */
export const generateAccessToken = (payload) => {
    return jwt.sign(payload, env.JWT_ACCESS_SECRET, { expiresIn: '7d' });
};

/**
 * Generate a long-lived Refresh Token
 * @param {Object} payload Data to encode in the token
 * @returns {string} JWT Refresh Token
 */
export const generateRefreshToken = (payload) => {
    return jwt.sign(payload, env.JWT_REFRESH_SECRET, { expiresIn: '7d' });
};

/**
 * Verify a JWT Token
 * @param {string} token Token to verify
 * @param {boolean} isRefresh Whether it is a refresh token (determines which secret to use)
 * @returns {Object} Decoded payload
 * @throws {Error} If token is invalid or expired
 */
export const verifyToken = (token, isRefresh = false) => {
    const secret = isRefresh ? env.JWT_REFRESH_SECRET : env.JWT_ACCESS_SECRET;
    return jwt.verify(token, secret);
};
