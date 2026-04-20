const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/apiResponse');
const companySharingService = require('../services/companySharingService');

const createSession = asyncHandler(async (req, res) => {
  const data = await companySharingService.createSession(req.user.userId, req.body);
  return successResponse(res, 'Session created successfully.', data, 201);
});

const joinSession = asyncHandler(async (req, res) => {
  const data = await companySharingService.joinSession(
    req.params.sessionId,
    req.user.userId
  );
  return successResponse(res, 'Session joined successfully.', data, 201);
});

const listSessions = asyncHandler(async (req, res) => {
  const data = await companySharingService.listSessions();
  return successResponse(res, 'Sessions fetched successfully.', data);
});

const sendCompanyChatMessage = asyncHandler(async (req, res) => {
  const data = await companySharingService.sendCompanyChatMessage(
    req.params.sessionId,
    req.user.userId,
    req.body.message_text
  );
  return successResponse(res, 'Company chat message sent successfully.', data, 201);
});

const fetchCompanyChatMessages = asyncHandler(async (req, res) => {
  const data = await companySharingService.fetchCompanyChatMessages(req.params.sessionId);
  return successResponse(res, 'Company chat messages fetched successfully.', data);
});

module.exports = {
  createSession,
  joinSession,
  listSessions,
  sendCompanyChatMessage,
  fetchCompanyChatMessages,
};