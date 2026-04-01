const { successResponse, errorResponse } = require('../utils/apiResponse');
const activeRideService = require('../services/activeRideService');

const getActiveRideDashboard = async (req, res) => {
  try {
    const data = await activeRideService.getActiveRideDashboard(req.user.userId);

    return successResponse(
      res,
      'Active ride dashboard fetched successfully.',
      data
    );
  } catch (error) {
    console.error('getActiveRideDashboard error:', error);
    return errorResponse(
      res,
      error.message || 'Failed to fetch active ride dashboard.',
      500
    );
  }
};

const toggleActiveRideStatus = async (req, res) => {
  try {
    const { isActive } = req.body;

    const data = await activeRideService.toggleActiveRideStatus(
      req.user.userId,
      isActive
    );

    return successResponse(
      res,
      'Rider active status updated successfully.',
      data
    );
  } catch (error) {
    console.error('toggleActiveRideStatus error:', error);
    return errorResponse(
      res,
      error.message || 'Failed to update rider active status.',
      500
    );
  }
};

module.exports = {
  getActiveRideDashboard,
  toggleActiveRideStatus,
};