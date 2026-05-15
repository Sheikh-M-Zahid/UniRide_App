const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/apiResponse');
const reserveService = require('../services/reserveService');

// Create reserve
const createReserve = asyncHandler(async (req, res) => {
  const result = await reserveService.createReserve(req.body, req.user);

  return successResponse(
    res,
    'Reserve request submitted successfully.',
    result,
    201
  );
});

// Validate reserve schedule
const validateSchedule = asyncHandler(async (req, res) => {
  const result = await reserveService.validateSchedule(req.body, req.user);

  return successResponse(res, 'Reserve schedule is valid.', result);
});

// Validate reserve preferences
const validatePreferences = asyncHandler(async (req, res) => {
  const data = await reserveService.validatePreferences(req.body, req.user);

  return successResponse(res, 'Reserve preferences are valid.', data);
});

// Get upcoming reserved rides
const getUpcomingReserve = asyncHandler(async (req, res) => {
  const data = await reserveService.getUpcomingReserve(req.user.userId);

  const message =
    data.length > 0
      ? 'Upcoming reserves fetched successfully'
      : 'No active booking found';

  return successResponse(res, message, data);
});

// Cancel reserve
const cancelReserve = asyncHandler(async (req, res) => {
  const data = await reserveService.cancelReserve(
    req.params.reserveId,
    req.user.userId
  );

  return successResponse(res, 'Reserve request cancelled successfully.', data);
});

// Assign rider to reserve
const assignRiderToReserve = asyncHandler(async (req, res) => {
  const data = await reserveService.assignRiderToReserve({
    reserveId: req.params.reserveId,
    riderId: req.user.userId,
  });

  return successResponse(res, 'Reserve request accepted successfully.', data);
});

// Calculate reserve ride fare
const calculateReserveRide = asyncHandler(async (req, res) => {
  const data = await reserveService.calculateReserveRide(req.body);

  return successResponse(res, 'Calculation successful', data);
});

// Get vehicle rates from DB
const getVehicleRates = asyncHandler(async (req, res) => {
  const data = await reserveService.getVehicleRates();

  return successResponse(res, 'Vehicle rates fetched successfully.', data);
});

module.exports = {
  createReserve,
  validateSchedule,
  validatePreferences,
  getUpcomingReserve,
  calculateReserveRide,
  cancelReserve,
  assignRiderToReserve,
  getVehicleRates,
};
