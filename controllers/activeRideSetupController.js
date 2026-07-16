const { successResponse, errorResponse } = require('../utils/apiResponse');
const service = require('../services/activeRideSetupService');

const getCurrentActiveRide = async (req, res) => {
  try {
    const data = await service.getCurrentActiveRide(req.user.userId);

    return successResponse(
      res,
      'Current active ride fetched successfully.',
      data
    );
  } catch (error) {
    console.error('getCurrentActiveRide error:', error);
    return errorResponse(
      res,
      error.message || 'Failed to fetch current active ride.',
      500
    );
  }
};

const getActiveRideSetupData = async (req, res) => {
  try {
    const data = await service.getActiveRideSetupData(req.user.userId);

    return successResponse(
      res,
      'Active ride setup data fetched successfully.',
      data
    );
  } catch (error) {
    console.error('getActiveRideSetupData error:', error);
    return errorResponse(
      res,
      error.message || 'Failed to fetch active ride setup data.',
      500
    );
  }
};

const activateRide = async (req, res) => {
  try {
    const data = await service.activateRide({
      userId: req.user.userId,
      body: req.body,
    });

    return successResponse(
      res,
      'Ride activated successfully.',
      data,
      201
    );
  } catch (error) {
    console.error('activateRide error:', error);
    return errorResponse(
      res,
      error.message || 'Failed to activate ride.',
      400
    );
  }
};

const updateCurrentLocation = async (req, res) => {
  try {
    const data = await service.updateCurrentLocation({
      userId: req.user.userId,
      body: req.body,
    });

    return successResponse(
      res,
      'Current location updated successfully.',
      data
    );
  } catch (error) {
    console.error('updateCurrentLocation error:', error);
    return errorResponse(
      res,
      error.message || 'Failed to update current location.',
      400
    );
  }
};

const cancelCurrentRide = async (req, res) => {
  try {
    const data = await service.cancelCurrentRide({
      userId: req.user.userId,
    });

    return successResponse(
      res,
      'Current active ride cancelled successfully.',
      data
    );
  } catch (error) {
    console.error('cancelCurrentRide error:', error);
    return errorResponse(
      res,
      error.message || 'Failed to cancel current active ride.',
      400
    );
  }
};

const getRouteAlternatives = async (req, res) => {
  try {
    const data = await service.getRouteAlternatives(req.body);
    return successResponse(res, 'Route alternatives fetched successfully.', data);
  } catch (error) {
    console.error('getRouteAlternatives error:', error);
    return errorResponse(res, error.message || 'Failed to fetch route alternatives.', 400);
  }
};

module.exports = {
  getCurrentActiveRide,
  getRouteAlternatives,
  getActiveRideSetupData,
  activateRide,
  cancelCurrentRide,
  updateCurrentLocation,
};
