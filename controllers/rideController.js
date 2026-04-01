const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/apiResponse');
const rideService = require('../services/rideService');

const createRide = asyncHandler(async (req, res) => {
  const data = await rideService.createRide(req.user.userId, req.body);
  return successResponse(res, 'Ride created successfully.', data, 201);
});

const listActiveRides = asyncHandler(async (req, res) => {
  const data = await rideService.listActiveRides();
  return successResponse(res, 'Active rides fetched successfully.', data);
});

const getRideDetails = asyncHandler(async (req, res) => {
  const data = await rideService.getRideDetails(req.params.rideId);
  return successResponse(res, 'Ride details fetched successfully.', data);
});

const joinRide = asyncHandler(async (req, res) => {
  const data = await rideService.joinRide(
    req.params.rideId,
    req.user.userId,
    req.body.fare
  );
  return successResponse(res, 'Ride joined successfully.', data, 201);
});

const confirmParticipant = asyncHandler(async (req, res) => {
  const data = await rideService.confirmParticipant(
    req.params.rideId,
    req.user.userId,
    req.params.participantId
  );
  return successResponse(res, 'Participant confirmed successfully.', data);
});

const changeRideStatus = asyncHandler(async (req, res) => {
  const data = await rideService.changeRideStatus(
    req.params.rideId,
    req.user.userId,
    req.body.status
  );
  return successResponse(res, 'Ride status changed successfully.', data);
});

const listMyCreatedRides = asyncHandler(async (req, res) => {
  const data = await rideService.listMyCreatedRides(req.user.userId);
  return successResponse(res, 'Created rides fetched successfully.', data);
});

const listJoinedRides = asyncHandler(async (req, res) => {
  const data = await rideService.listJoinedRides(req.user.userId);
  return successResponse(res, 'Joined rides fetched successfully.', data);
});
const searchRides = asyncHandler(async (req, res) => {
  try {
    const data = await rideService.searchRides(req.body);

    return successResponse(
      res,
      'Ride search completed successfully.',
      data
    );
  } catch (error) {
    return errorResponse(res, error.message, 400);
  }
});
module.exports = {
  createRide,
  listActiveRides,
  getRideDetails,
  joinRide,
  confirmParticipant,
  changeRideStatus,
  listMyCreatedRides,
  listJoinedRides,
  searchRides,
};