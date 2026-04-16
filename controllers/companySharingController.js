const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/apiResponse');
const companySharingService = require('../services/companySharingService');

// Create sharing session
const createSession = asyncHandler(async (req, res) => {
  const data = await companySharingService.createSession(req.body, req.user);

  return successResponse(
    res,
    'Ride shared successfully. Notification sent.',
    data,
    201
  );
});

// Get active sessions
const getActiveSessions = asyncHandler(async (req, res) => {
  const data = await companySharingService.getActiveSessions(req.user, req.query);

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
  const data = await companySharingService.getHistory(req.user, req.query);

  return successResponse(
    res,
    data.length
      ? 'Sharing & Caring history fetched successfully.'
      : 'No shared trip history found.',
    data
  );
});

// Join session
const joinSession = asyncHandler(async (req, res) => {
  const data = await companySharingService.joinSession(
    req.params.sessionId,
    req.user.userId
  );

  return successResponse(
    res,
    'Session joined successfully.',
    data,
    201
  );
});

// List sessions
const listSessions = asyncHandler(async (req, res) => {
  const data = await companySharingService.listSessions();

  return successResponse(
    res,
    'Sessions fetched successfully.',
    data
  );
});

// Send company chat message
const sendCompanyChatMessage = asyncHandler(async (req, res) => {
  const data = await companySharingService.sendCompanyChatMessage(
    req.params.sessionId,
    req.user.userId,
    req.body.message_text
  );

  return successResponse(
    res,
    'Company chat message sent successfully.',
    data,
    201
  );
});

// Fetch company chat messages
const fetchCompanyChatMessages = asyncHandler(async (req, res) => {
  const data = await companySharingService.fetchCompanyChatMessages(
    req.params.sessionId
  );

  return successResponse(
    res,
    'Company chat messages fetched successfully.',
    data
  );
});

module.exports = {
  createSession,
  getActiveSessions,
  getHistory,
  joinSession,
  listSessions,
  sendCompanyChatMessage,
  fetchCompanyChatMessages,
};