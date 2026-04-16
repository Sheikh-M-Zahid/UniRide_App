const { successResponse, errorResponse } = require('../utils/apiResponse');
const passengerRideRequestService = require('../services/passengerRideRequestService');

const createRideRequest = async (req, res) => {
  try {
    const io = req.app.get('io');
    const passengerId = req.user.userId;

    const data = await passengerRideRequestService.createRideRequest({
      passengerId,
      body: req.body,
      io,
    });

    return successResponse(res, 'Ride request sent successfully.', data);
  } catch (error) {
    return errorResponse(res, error.message || 'Failed to create ride request.', 400);
  }
};

module.exports = {
  createRideRequest,
};