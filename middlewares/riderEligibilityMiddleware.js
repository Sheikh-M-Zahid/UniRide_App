const rideDb = require('../config/rideDb');
const { errorResponse } = require('../utils/apiResponse');

const requireVerifiedRider = async (req, res, next) => {
  try {
    const userId = req.user.userId || req.user.user_id;

    const result = await rideDb.query(
      `
      SELECT 1
      FROM vehicles
      WHERE user_id = $1
        AND verified = true
        AND verification_status = 'approved'
      LIMIT 1
      `,
      [userId]
    );

    if (!result.rows.length) {
      return errorResponse(
        res,
        'You are not an approved rider yet. Please submit vehicle documents and wait for admin approval.',
        403
      );
    }

    next();
  } catch (error) {
    console.error('requireVerifiedRider error:', error);
    return errorResponse(res, 'Rider eligibility check failed.', 500);
  }
};

module.exports = {
  requireVerifiedRider,
};