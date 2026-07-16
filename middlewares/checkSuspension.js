const { verifyToken } = require('../utils/jwt');
const rideDb = require('../config/rideDb');
const { errorResponse } = require('../utils/apiResponse');

// এই path গুলো suspended অবস্থাতেও allow করা হবে
const ALLOWED_PREFIXES = [
  '/api/auth',
  '/api/wallet',
  '/api/settings',
  '/api/users/profile',
  '/api/profile',
  '/api/security',
  '/api/privacy-data',
  '/api/rider/settings',
  '/api/rider/profile',
  '/api/admin',
];

const checkSuspension = async (req, res, next) => {
  try {
    const isAllowed = ALLOWED_PREFIXES.some((prefix) =>
      req.path.startsWith(prefix)
    );
    if (isAllowed) return next();

    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return next();
    }

    const token = authHeader.split(' ')[1];

    let decoded;
    try {
      decoded = verifyToken(token);
    } catch (e) {
      return next();
    }

    const userId = decoded.userId || decoded.user_id || decoded.id;
    if (!userId) return next();

    const result = await rideDb.query(
      `SELECT account_status FROM users WHERE user_id = $1`,
      [userId]
    );

    const status = result.rows[0]?.account_status;

    if (status === 'suspended') {
      return errorResponse(
        res,
        'Your account has been suspended due to a pending due payment. Please clear your due to continue using the app.',
        403,
        { code: 'ACCOUNT_SUSPENDED' }
      );
    }

    next();
  } catch (error) {
    next();
  }
};

module.exports = checkSuspension;
