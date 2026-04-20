const { errorResponse } = require('../utils/apiResponse');

const adminMiddleware = (req, res, next) => {
  if (!req.user || !req.user.isAdmin) {
    return errorResponse(res, 'Admin access only.', 403);
  }

  next();
};

module.exports = adminMiddleware;