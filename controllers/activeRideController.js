const { successResponse, errorResponse } = require('../utils/apiResponse');
const activeRideService = require('../services/activeRideService');
const { emitActiveRideUpdate } = require('../utils/activeRideEmitter');
const { emitActiveRidersUpdate } = require('../utils/activeRiderEmitter');

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

    await emitActiveRideUpdate(req.user.userId);
    await emitActiveRidersUpdate();

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