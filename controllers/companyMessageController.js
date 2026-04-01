const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/apiResponse');
const service = require('../services/companyMessageService');

const getMessages = asyncHandler(async (req, res) => {
  const { sessionId } = req.params;
  const userId = req.user.user_id;

  const data = await service.getMessages(sessionId, userId);

  return successResponse(res, 'Chat messages fetched successfully', data);
});

const sendMessage = asyncHandler(async (req, res) => {
  const { sessionId } = req.params;
  const userId = req.user.user_id;

  const data = await service.sendMessage(req, sessionId, userId);

  return successResponse(res, 'Message sent successfully', data);
});

module.exports = {
  getMessages,
  sendMessage,
};