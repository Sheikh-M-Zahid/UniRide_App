const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/apiResponse');
const ratingService = require('../services/ratingService');

const passengerRatesRider = asyncHandler(async (req, res) => {
  const data = await ratingService.passengerRatesRider(
    req.body.ride_id,
    req.user.userId,
    req.body.rating
  );
  return successResponse(res, 'Rider rated successfully.', data, 201);
});

const riderRatesParticipants = asyncHandler(async (req, res) => {
  const data = await ratingService.riderRatesParticipants(
    req.body.ride_id,
    req.user.userId,
    req.body.rating
  );
  return successResponse(res, 'Participants rated successfully.', data, 201);
});

const fetchRatingSummary = asyncHandler(async (req, res) => {
  const data = await ratingService.fetchRatingSummary(req.params.userId);
  return successResponse(res, 'Rating summary fetched successfully.', data);
});

module.exports = {
  passengerRatesRider,
  riderRatesParticipants,
  fetchRatingSummary,
};