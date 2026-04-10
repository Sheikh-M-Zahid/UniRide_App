const { successResponse, errorResponse } = require('../utils/apiResponse');
const rideService = require('../services/rideService');

const createRide = async (req, res) => {
  try {
    const data = await rideService.createRide(req.user.userId, req.body);
    return successResponse(res, 'Ride created successfully.', data, 201);
  } catch (error) {
    return errorResponse(res, error.message || 'Failed to create ride.', 400);
  }
};

const listActiveRides = async (req, res) => {
  try {
    const data = await rideService.listActiveRides();
    return successResponse(res, 'Active rides fetched successfully.', data);
  } catch (error) {
    return errorResponse(res, error.message || 'Failed to fetch rides.', 500);
  }
};

const getRideDetails = async (req, res) => {
  try {
    const data = await rideService.getRideDetails(req.params.rideId);
    return successResponse(res, 'Ride details fetched successfully.', data);
  } catch (error) {
    return errorResponse(res, error.message || 'Failed to fetch ride details.', 404);
  }
};

const joinRide = async (req, res) => {
  try {
    const { fare } = req.body;
    const data = await rideService.joinRide(
      req.params.rideId,
      req.user.userId,
      fare
    );
    return successResponse(res, 'Ride joined successfully.', data, 201);
  } catch (error) {
    return errorResponse(res, error.message || 'Failed to join ride.', 400);
  }
};

const confirmParticipant = async (req, res) => {
  try {
    const data = await rideService.confirmParticipant(
      req.params.rideId,
      req.user.userId,
      req.params.participantId
    );
    return successResponse(res, 'Participant confirmed successfully.', data);
  } catch (error) {
    return errorResponse(res, error.message || 'Failed to confirm participant.', 400);
  }
};

const changeRideStatus = async (req, res) => {
  try {
    const { status } = req.body;
    const data = await rideService.changeRideStatus(
      req.params.rideId,
      req.user.userId,
      status
    );
    return successResponse(res, 'Ride status updated successfully.', data);
  } catch (error) {
    return errorResponse(res, error.message || 'Failed to update ride status.', 400);
  }
};

const listMyCreatedRides = async (req, res) => {
  try {
    const data = await rideService.listMyCreatedRides(req.user.userId);
    return successResponse(res, 'Created rides fetched successfully.', data);
  } catch (error) {
    return errorResponse(res, error.message || 'Failed to fetch created rides.', 500);
  }
};

const listJoinedRides = async (req, res) => {
  try {
    const data = await rideService.listJoinedRides(req.user.userId);
    return successResponse(res, 'Joined rides fetched successfully.', data);
  } catch (error) {
    return errorResponse(res, error.message || 'Failed to fetch joined rides.', 500);
  }
};

const searchRides = async (req, res) => {
  try {
    const data = await rideService.searchRides(req.body);
    return successResponse(res, 'Ride search completed successfully.', data);
  } catch (error) {
    return errorResponse(res, error.message || 'Failed to search rides.', 400);
  }
};

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