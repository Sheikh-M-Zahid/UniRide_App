const { errorResponse } = require('../utils/apiResponse');

const errorMiddleware = (err, req, res, next) => {
  console.error('ERROR:', err);

  // PostgreSQL Errors
  if (err.code === '23505') {
    return errorResponse(res, 'Duplicate value error.', 409, err.detail);
  }

  if (err.code === '23503') {
    return errorResponse(res, 'Referenced data not found.', 400, err.detail);
  }

  if (err.code === '23502') {
    return errorResponse(res, 'Missing required field.', 400, err.detail);
  }

  // JWT Errors (optional but useful)
  if (err.name === 'JsonWebTokenError') {
    return errorResponse(res, 'Invalid token.', 401);
  }

  if (err.name === 'TokenExpiredError') {
    return errorResponse(res, 'Token expired.', 401);
  }

  // Custom error handling
  if (err.statusCode) {
    return errorResponse(res, err.message, err.statusCode);
  }

  // Default fallback
  return errorResponse(
    res,
    err.message || 'Internal server error.',
    500
  );
};

module.exports = errorMiddleware;