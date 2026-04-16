const { successResponse, errorResponse } = require('../utils/apiResponse');
const service = require('../services/rideAvailabilityAlertService');

const createAvailabilityAlert = async (req, res) => {
  try {
    const data = await service.createAvailabilityAlert({
      userId: req.user.userId,
      body: req.body,
    });

    return successResponse(
      res,
      'Availability alert created successfully.',
      data,
      201
    );
  } catch (error) {
    console.error('createAvailabilityAlert error:', error);
    return errorResponse(res, error.message || 'Failed to create alert.', 400);
  }
};

const getMyAvailabilityAlerts = async (req, res) => {
  try {
    const data = await service.getMyAvailabilityAlerts(req.user.userId);

    return successResponse(
      res,
      'Availability alerts fetched successfully.',
      data
    );
  } catch (error) {
    console.error('getMyAvailabilityAlerts error:', error);
    return errorResponse(res, error.message || 'Failed to fetch alerts.', 500);
  }
};

const deactivateAvailabilityAlert = async (req, res) => {
  try {
    const data = await service.deactivateAvailabilityAlert({
      userId: req.user.userId,
      alertId: req.params.alertId,
    });

    return successResponse(
      res,
      'Availability alert deactivated successfully.',
      data
    );
  } catch (error) {
    console.error('deactivateAvailabilityAlert error:', error);
    return errorResponse(res, error.message || 'Failed to deactivate alert.', 400);
  }
};

module.exports = {
  createAvailabilityAlert,
  getMyAvailabilityAlerts,
  deactivateAvailabilityAlert,
};