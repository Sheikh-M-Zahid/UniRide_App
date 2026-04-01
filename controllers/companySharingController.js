const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/apiResponse');
const service = require('../services/companySharingService');

// Create sharing session
const createSession = asyncHandler(async (req, res) => {
  const data = await service.createSession(req.body, req.user);

  return successResponse(
    res,
    'Ride shared successfully. Notification sent.',
    data,
    201
  );
});

// Get active sessions
const getActiveSessions = asyncHandler(async (req, res) => {
  const data = await service.getActiveSessions(req.user, req.query);

  return successResponse(
    res,
    data.length
      ? 'Active co-rides fetched successfully.'
      : 'No active co-rides found.',
    data
  );
});

// Get sharing history
const getHistory = asyncHandler(async (req, res) => {
  const data = await service.getHistory(req.user, req.query);

  return successResponse(
    res,
    data.length
      ? 'Sharing & Caring history fetched successfully.'
      : 'No shared trip history found.',
    data
  );
});

module.exports = {
  createSession,
  getActiveSessions,
  getHistory,
};