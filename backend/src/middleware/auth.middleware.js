import { verifyToken } from '../utils/jwt.js';
import { AppError } from '../utils/response.js';

/**
 * Middleware to verify JWT Access Token
 * Extracts token from Authorization header and attaches decoded payload to req.user.
 */
export const verifyAccessToken = (req, res, next) => {
    try {
        let token;

        // Check if the Authorization header exists and follows the Bearer pattern
        if (
            req.headers.authorization &&
            req.headers.authorization.startsWith('Bearer ')
        ) {
            // Extract the token part
            token = req.headers.authorization.split(' ')[1];
        }

        if (!token) {
            throw new AppError('You are not logged in. Please log in to get access.', 401);
        }

        // Verify the token using the utility function
        try {
            const decoded = verifyToken(token);

            // Attach the decoded user information to the request object for downstream use
            req.user = decoded;

            // Successfully authenticated
            next();
        } catch (error) {
            if (error.name === 'TokenExpiredError') {
                throw new AppError('Your token has expired. Please log in again.', 401);
            }
            throw new AppError('Invalid token. Please log in again.', 401);
        }
    } catch (error) {
        next(error);
    }
};

/**
 * Future Placeholder: Middleware for Role-Based Access Control (RBAC)
 * Example usage: router.get('/', verifyAccessToken, restrictTo('PLATFORM', 'SUPER_ADMIN'), controller)
 */
export const restrictTo = (...roles) => {
    return (req, res, next) => {
        // Determine if req.user.role exists and matches the allowed roles
        if (!req.user || !roles.includes(req.user.role)) {
            return next(
                new AppError('You do not have permission to perform this action', 403)
            );
        }
        next();
    };
};
