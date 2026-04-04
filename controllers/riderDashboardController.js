const { successResponse, errorResponse } = require('../utils/apiResponse');
const riderDashboardService = require('../services/riderDashboardService');

const getRiderDashboard = async (req, res) => {
  try {
    const riderId = req.user.userId;

    const data = await riderDashboardService.getRiderDashboard({ riderId });

    return successResponse(res, 'Rider dashboard fetched successfully.', data);
  } catch (error) {
    console.error('getRiderDashboard error:', error);
    return errorResponse(
      res,
      error.message || 'Failed to fetch rider dashboard.',
      500
    );
  }
};

module.exports = {
  getRiderDashboard,
};