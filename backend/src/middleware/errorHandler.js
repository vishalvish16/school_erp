import { logger } from '../config/logger.js';
import { errorResponse } from '../utils/response.js';

export const errorHandler = (err, req, res, next) => {
    let { statusCode, message, errorCode } = err;

    if (!err.isOperational) {
        statusCode = 500;
        message = err.message || 'Internal Server Error';
        errorCode = 'ERR_500';
        logger.error(`[UNHANDLED ERROR] ${err.message}`, { stack: err.stack, url: req.originalUrl, method: req.method });
    } else {
        logger.warn(`[OPERATIONAL ERROR] ${err.message}`, { url: req.originalUrl, method: req.method });
    }

    const details = err.stack;

    errorResponse(res, statusCode || 500, message, errorCode || `ERR_${statusCode || 500}`, details);
};
