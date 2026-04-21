const { successResponse, errorResponse } = require('../utils/apiResponse');
const riderVerificationService = require('../services/riderVerificationService');

const getMyRiderVerificationStatus = async (req, res) => {
  try {
    const userId = req.user.userId || req.user.user_id;
    const data = await riderVerificationService.getMyRiderVerificationStatus(userId);
    return successResponse(res, 'Rider verification status fetched successfully.', data);
  } catch (error) {
    console.error('getMyRiderVerificationStatus error:', error);
    return errorResponse(res, error.message || 'Failed to fetch status', 400);
  }
};

module.exports = {
  getMyRiderVerificationStatus,
};