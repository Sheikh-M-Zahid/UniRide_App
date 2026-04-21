const jwt = require('jsonwebtoken');
const { errorResponse } = require('../utils/apiResponse');

const adminAuthMiddleware = (req, res, next) => {
  try {
    const authHeader = req.headers.authorization || req.headers.Authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return errorResponse(res, 'Admin authorization token is required.', 401);
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    if (!decoded) {
      return errorResponse(res, 'Invalid admin token.', 401);
    }

    const isAdminUser =
      decoded.isAdmin === true || decoded.role === 'admin';

    if (!isAdminUser) {
      return errorResponse(res, 'Unauthorized admin access.', 403);
    }

    req.admin = {
      id: decoded.userId || decoded.user_id || decoded.id || decoded.adminId,
      email: decoded.email || decoded.university_email || '',
      role: decoded.role || 'admin',
      isAdmin: true,
    };

    next();
  } catch (error) {
    return errorResponse(res, 'Invalid or expired admin token.', 401);
  }
};

module.exports = adminAuthMiddleware;
