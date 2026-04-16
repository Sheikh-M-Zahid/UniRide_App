const asyncHandler = require('../utils/asyncHandler');
const { successResponse, errorResponse } = require('../utils/apiResponse');
const ratingService = require('../services/ratingService');

const checkRatingStatus = asyncHandler(async (req, res) => {
  const { rideId, toUserId } = req.query;

  if (!rideId || !toUserId) {
    return errorResponse(res, 'rideId and toUserId are required.', 400);
  }

  const alreadyRated = await ratingService.hasUserRated({
    rideId,
    fromUserId: req.user.userId,
    toUserId,
  });

  return successResponse(res, 'Rating check completed.', {
    alreadyRated,
  });
});

const passengerRatesRider = asyncHandler(async (req, res) => {
  const { ride_id, rating, note = null } = req.body;

  const data = await ratingService.passengerRatesRider({
    rideId: ride_id,
    passengerId: req.user.userId,
    rating,
    note,
  });

  return successResponse(res, 'Rider rated successfully.', data, 201);
});

const riderRatesParticipant = asyncHandler(async (req, res) => {
  const { ride_id, participant_id, rating, note = null } = req.body;

  const data = await ratingService.riderRatesParticipant({
    rideId: ride_id,
    riderId: req.user.userId,
    passengerId: participant_id,
    rating,
    note,
  });

  return successResponse(res, 'Passenger rated successfully.', data, 201);
});

const fetchRatingSummary = asyncHandler(async (req, res) => {
  const data = await ratingService.fetchRatingSummary(req.params.userId);
  return successResponse(res, 'Rating summary fetched successfully.', data);
});

module.exports = {
  checkRatingStatus,
  passengerRatesRider,
  riderRatesParticipant,
  fetchRatingSummary,
};