const { successResponse, errorResponse } = require('../utils/apiResponse');
const riderRideHistoryService = require('../services/riderRideHistoryService');

const getRideHistory = async (req, res) => {
  try {
    const riderId = req.user.userId;

    const {
      search = '',
      range = '',      // today | week | month
      month = '',      // 1-12
      year = '',       // 2026
      page = 1,
      limit = 20,
    } = req.query;

    const data = await riderRideHistoryService.getRideHistory({
      riderId,
      search,
      range,
      month,
      year,
      page: Number(page),
      limit: Number(limit),
    });

    return successResponse(res, 'Ride history fetched successfully.', data);
  } catch (error) {
    console.error('getRideHistory error:', error);
    return errorResponse(res, error.message || 'Failed to fetch ride history.', 500);
  }
};

module.exports = {
  getRideHistory,
};