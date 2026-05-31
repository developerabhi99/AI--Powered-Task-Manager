"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.errorHandler = void 0;
const errors_1 = require("../utils/errors");
const logger_1 = require("../utils/logger");
const env_1 = require("../config/env");
const errorHandler = (err, req, res, _next) => {
    // Determine if error is operational or programming/unknown
    const isOperational = err instanceof errors_1.AppError ? err.isOperational : false;
    const statusCode = err instanceof errors_1.AppError ? err.statusCode : 500;
    // Create structured log details
    const logDetails = {
        method: req.method,
        url: req.originalUrl,
        statusCode,
        message: err.message,
        stack: err.stack,
    };
    if (statusCode >= 500) {
        logger_1.logger.error('💥 Internal Server Error:', logDetails);
    }
    else {
        logger_1.logger.warn('⚠️ Client Request Warning:', logDetails);
    }
    // Response payload
    const response = {
        status: 'error',
        message: isOperational ? err.message : 'Something went wrong on the server',
    };
    // Add validation details if applicable
    if (err instanceof errors_1.ValidationError) {
        response.errors = err.errors;
    }
    // Include stack trace only in development
    if (env_1.env.NODE_ENV === 'development') {
        response.stack = err.stack;
        response.rawError = err.message;
    }
    res.status(statusCode).json(response);
};
exports.errorHandler = errorHandler;
