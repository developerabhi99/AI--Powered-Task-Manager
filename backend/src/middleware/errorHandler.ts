import { Request, Response, NextFunction } from 'express';
import { AppError, ValidationError } from '../utils/errors';
import { logger } from '../utils/logger';
import { env } from '../config/env';

export const errorHandler = (
  err: Error | AppError | ValidationError,
  req: Request,
  res: Response,
  _next: NextFunction
): void => {
  // Determine if error is operational or programming/unknown
  const isOperational = err instanceof AppError ? err.isOperational : false;
  const statusCode = err instanceof AppError ? err.statusCode : 500;
  
  // Create structured log details
  const logDetails = {
    method: req.method,
    url: req.originalUrl,
    statusCode,
    message: err.message,
    stack: err.stack,
  };

  if (statusCode >= 500) {
    logger.error('💥 Internal Server Error:', logDetails);
  } else {
    logger.warn('⚠️ Client Request Warning:', logDetails);
  }

  // Response payload
  const response: Record<string, unknown> = {
    status: 'error',
    message: isOperational ? err.message : 'Something went wrong on the server',
  };

  // Add validation details if applicable
  if (err instanceof ValidationError) {
    response.errors = err.errors;
  }

  // Include stack trace only in development
  if (env.NODE_ENV === 'development') {
    response.stack = err.stack;
    response.rawError = err.message;
  }

  res.status(statusCode).json(response);
};
