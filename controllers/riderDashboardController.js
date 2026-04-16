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

const updateRiderStatus = async (req, res) => {
  try {
    const riderId = req.user.userId;
    const { is_online } = req.body;

    const data = await riderDashboardService.updateRiderStatus({
      riderId,
      isOnline: is_online,
    });

    return successResponse(res, 'Rider status updated successfully.', data);
  } catch (error) {
    console.error('updateRiderStatus error:', error);
    return errorResponse(
      res,
      error.message || 'Failed to update rider status.',
      500
    );
  }
};

module.exports = {
  getRiderDashboard,
  updateRiderStatus,
};
