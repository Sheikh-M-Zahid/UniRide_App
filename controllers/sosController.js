const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/apiResponse');
const service = require('../services/sosService');

// CoRide Host SOS
const coRideSosHost = asyncHandler(async (req, res) => {
  const userId = req.user.userId || req.user.user_id;
  const { sessionId } = req.body;
  const baseUrl = process.env.FRONTEND_BASE_URL || `${req.protocol}://${req.get('host')}`;

  const data = await service.triggerCoRideSosHost({ userId, sessionId, baseUrl });
  return successResponse(res, data.message, data);
});

// CoRide Participant SOS
const coRideSosParticipant = asyncHandler(async (req, res) => {
  const userId = req.user.userId || req.user.user_id;
  const { sessionId } = req.body;
  const baseUrl = process.env.FRONTEND_BASE_URL || `${req.protocol}://${req.get('host')}`;

  const data = await service.triggerCoRideSosParticipant({ userId, sessionId, baseUrl });
  return successResponse(res, data.message, data);
});

// Rider SOS
const riderSos = asyncHandler(async (req, res) => {
  const userId = req.user.userId || req.user.user_id;
  const { rideId } = req.body;
  const baseUrl = process.env.FRONTEND_BASE_URL || `${req.protocol}://${req.get('host')}`;

  const data = await service.triggerRiderSos({ userId, rideId, baseUrl });
  return successResponse(res, data.message, data);
});

// Passenger SOS
const passengerSos = asyncHandler(async (req, res) => {
  const userId = req.user.userId || req.user.user_id;
  const { rideId } = req.body;
  const baseUrl = process.env.FRONTEND_BASE_URL || `${req.protocol}://${req.get('host')}`;

  const data = await service.triggerPassengerSos({ userId, rideId, baseUrl });
  return successResponse(res, data.message, data);
});

// Public tracking page (no auth)
const getSosTrackingInfo = asyncHandler(async (req, res) => {
  const { token } = req.params;
  const data = await service.getSosTrackingInfo(token);
  return successResponse(res, 'Tracking info fetched.', data);
});

module.exports = {
  coRideSosHost,
  coRideSosParticipant,
  riderSos,
  passengerSos,
  getSosTrackingInfo,
};
