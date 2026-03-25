const { errorResponse } = require('../utils/apiResponse');

const errorMiddleware = (err, req, res, next) => {
  console.error(err);

  if (err.code === '23505') {
    return errorResponse(res, 'Duplicate value error.', 409, err.detail);
  }

  if (err.code === '23503') {
    return errorResponse(res, 'Referenced data not found.', 400, err.detail);
  }

  return errorResponse(
    res,
    err.message || 'Internal server error.',
    err.statusCode || 500
  );
};

module.exports = errorMiddleware;