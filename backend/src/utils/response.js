export class AppError extends Error {
    constructor(message, statusCode, errorCode = null) {
        super(message);
        this.statusCode = statusCode;
        this.errorCode = errorCode || `ERR_${statusCode}`;
        this.isOperational = true;
        Error.captureStackTrace(this, this.constructor);
    }
}

export const successResponse = (res, statusCode, message, data = null) => {
    return res.status(statusCode).json({
        success: true,
        message,
        data,
    });
};

export const errorResponse = (res, statusCode, message, errorCode = null, errorDetails = null) => {
    const payload = {
        success: false,
        message,
        error_code: errorCode || `ERR_${statusCode}`,
    };

    if (errorDetails) {
        payload.details = errorDetails;
    }

    return res.status(statusCode).json(payload);
};
