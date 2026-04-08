const { successResponse, errorResponse } = require('../utils/apiResponse');
const riderActiveRideService = require('../services/riderActiveRideService');

const updateAvailability = async (req, res) => {
  try {
    const io = req.app.get('io');
    const riderId = req.user.userId;
    const { isActive, latitude, longitude } = req.body;

    const data = await riderActiveRideService.updateAvailability({
      riderId,
      body: {
        isActive,
        latitude,
        longitude,
      },
      io,
    });

    return successResponse(res, 'Rider availability updated successfully.', data);
  } catch (error) {
    return errorResponse(
      res,
      error.message || 'Failed to update availability.',
      500
    );
  }
};

const getDashboard = async (req, res) => {
  try {
    const riderId = req.user.userId;
    const data = await riderActiveRideService.getDashboard({ riderId });

    return successResponse(res, 'Active ride dashboard fetched successfully.', data);
  } catch (error) {
    return errorResponse(res, error.message || 'Failed to fetch dashboard.', 500);
  }
};

const getPendingRequests = async (req, res) => {
  try {
    const riderId = req.user.userId;
    const data = await riderActiveRideService.getPendingRequests({ riderId });
    return successResponse(res, 'Pending requests fetched successfully.', data);
  } catch (error) {
    return errorResponse(res, error.message || 'Failed to fetch pending requests.', 500);
  }
};

const acceptRideRequest = async (req, res) => {
  try {
    const io = req.app.get('io');
    const riderId = req.user.userId;
    const { requestId } = req.params;

    const data = await riderActiveRideService.acceptRideRequest({
      riderId,
      requestId,
      io,
    });

    return successResponse(res, data.message, data);
  } catch (error) {
    return errorResponse(res, error.message || 'Failed to accept ride request.', 400);
  }
};

const rejectRideRequest = async (req, res) => {
  try {
    const io = req.app.get('io');
    const riderId = req.user.userId;
    const { requestId } = req.params;

    const data = await riderActiveRideService.rejectRideRequest({
      riderId,
      requestId,
      io,
    });

    return successResponse(res, data.message, data);
  } catch (error) {
    return errorResponse(res, error.message || 'Failed to reject ride request.', 400);
  }
};

const cancelConfirmedRide = async (req, res) => {
  try {
    const io = req.app.get('io');
    const riderId = req.user.userId;
    const { requestId } = req.params;
    const { cancelReason } = req.body;

    const data = await riderActiveRideService.cancelConfirmedRide({
      riderId,
      requestId,
      cancelReason,
      io,
    });

    return successResponse(res, data.message, data);
  } catch (error) {
    return errorResponse(res, error.message || 'Failed to cancel confirmed ride.', 400);
  }
};

const startRide = async (req, res) => {
  try {
    const io = req.app.get('io');
    const riderId = req.user.userId;
    const { rideId } = req.params;

    const data = await riderActiveRideService.startRide({
      riderId,
      rideId,
      io,
    });

    return successResponse(res, data.message, data);
  } catch (error) {
    return errorResponse(res, error.message || 'Failed to start ride.', 400);
  }
};

const completeRide = async (req, res) => {
  try {
    const io = req.app.get('io');
    const riderId = req.user.userId;
    const { rideId } = req.params;

    const data = await riderActiveRideService.completeRide({
      riderId,
      rideId,
      io,
    });

    return successResponse(res, data.message, data);
  } catch (error) {
    return errorResponse(res, error.message || 'Failed to complete ride.', 400);
  }
};

module.exports = {
  updateAvailability,
  getDashboard,
  getPendingRequests,
  acceptRideRequest,
  rejectRideRequest,
  cancelConfirmedRide,
  startRide,
  completeRide,
};
