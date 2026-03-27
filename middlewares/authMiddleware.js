const { errorResponse } = require('../utils/apiResponse');
const { verifyToken } = require('../utils/jwt');

const authMiddleware = (req, res, next) => {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return errorResponse(res, 'Unauthorized. Token missing.', 401);
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = verifyToken(token);

    req.user = {
      userId: decoded.userId,
      email: decoded.email,
      isAdmin: decoded.isAdmin || false,
    };

    next();
  } catch (error) {
    return errorResponse(res, 'Invalid or expired token.', 401);
  }
};

module.exports = authMiddleware;