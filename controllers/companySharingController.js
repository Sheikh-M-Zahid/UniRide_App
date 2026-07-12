const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/apiResponse');
const service = require('../services/companySharingService');

const createSession = asyncHandler(async (req, res) => {
  const data = await service.createSession(req.user.userId, req.body);
  return successResponse(res, 'Session created successfully.', data, 201);
});

const getSessionById = asyncHandler(async (req, res) => {
  const data = await service.getSessionById(req.params.sessionId);
  return successResponse(res, 'Session fetched.', data);
});

const getMyActiveSession = asyncHandler(async (req, res) => {
  const data = await service.getMyActiveSession(req.user.userId);
  return successResponse(res, 'My active session.', data);
});

const joinSession = asyncHandler(async (req, res) => {
  const data = await service.joinSession(req.params.sessionId, req.user.userId);
  return successResponse(res, 'Session joined successfully.', data, 201);
});

const cancelSession = asyncHandler(async (req, res) => {
  const data = await service.cancelSession(req.params.sessionId, req.user.userId);
  return successResponse(res, 'Session cancelled.', data);
});

const startSession = asyncHandler(async (req, res) => {
  const data = await service.startSession(req.params.sessionId, req.user.userId);
  return successResponse(res, 'Journey started.', data);
});

const updateLiveLocation = asyncHandler(async (req, res) => {
  const { lat, lng } = req.body;
  const data = await service.updateLiveLocation(
    req.params.sessionId, req.user.userId, lat, lng
  );
  return successResponse(res, 'Location updated.', data);
});

const getLiveLocation = asyncHandler(async (req, res) => {
  const data = await service.getLiveLocation(req.params.sessionId);
  return successResponse(res, 'Live location fetched.', data);
});

const listSessions = asyncHandler(async (req, res) => {
  const data = await service.listSessions(req.user.userId);
  return successResponse(res, 'Sessions fetched successfully.', data);
});

const sendCompanyChatMessage = asyncHandler(async (req, res) => {
  const data = await service.sendCompanyChatMessage(
    req.params.sessionId, req.user.userId, req.body.message_text
  );
  return successResponse(res, 'Message sent.', data, 201);
});

const fetchCompanyChatMessages = asyncHandler(async (req, res) => {
  const data = await service.fetchCompanyChatMessages(req.params.sessionId);
  return successResponse(res, 'Messages fetched.', data);
});

const removeParticipant = asyncHandler(async (req, res) => {
  const data = await service.removeParticipant(
    req.params.sessionId,
    req.user.userId,
    req.params.participantUserId
  );
  return successResponse(res, 'Participant removed.', data);
});

const getSessionWithParticipants = asyncHandler(async (req, res) => {
  const data = await service.getSessionWithParticipants(
    req.params.sessionId,
    req.user.userId
  );
  return successResponse(res, 'Session details fetched.', data);
});

module.exports = {
  createSession,
  getSessionById,
  getMyActiveSession,
  joinSession,
  cancelSession,
  startSession,
  updateLiveLocation,
  getLiveLocation,
  listSessions,
  sendCompanyChatMessage,
  fetchCompanyChatMessages,
  removeParticipant,
  getSessionWithParticipants,
};
