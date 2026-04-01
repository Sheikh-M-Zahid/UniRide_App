const { errorResponse } = require('../utils/apiResponse');
const { verifyToken } = require('../utils/jwt');

const authMiddleware = (req, res, next) => {
  const authHeader = req.headers.authorization || req.headers.Authorization;

  if (!authHeader) {
    return errorResponse(res, 'Unauthorized. Authorization header missing.', 401);
  }

  if (typeof authHeader !== 'string' || !authHeader.startsWith('Bearer ')) {
    return errorResponse(res, 'Unauthorized. Bearer token required.', 401);
  }

  const token = authHeader.split(' ')[1];

  if (!token) {
    return errorResponse(res, 'Unauthorized. Token missing.', 401);
  }

  try {
    const decoded = verifyToken(token);

    req.user = {
      userId: decoded.userId || decoded.user_id || null,
      email: decoded.email || decoded.university_email || null,
      isAdmin: Boolean(decoded.isAdmin),
    };

    if (!req.user.userId) {
      return errorResponse(res, 'Unauthorized. Invalid token payload.', 401);
    }

    next();
  } catch (error) {
    return errorResponse(res, 'Invalid or expired token.', 401);
  }
};

module.exports = authMiddleware;