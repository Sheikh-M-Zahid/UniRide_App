const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/apiResponse');
const rideChatService = require('../services/rideChatService');

const sendMessage = asyncHandler(async (req, res) => {
  const data = await rideChatService.sendMessage(
    req.params.rideId,
    req.user.userId,
    req.body.message_text
  );
  return successResponse(res, 'Message sent successfully.', data, 201);
});

const getChatMessagesByRide = asyncHandler(async (req, res) => {
  const data = await rideChatService.getChatMessagesByRide(req.params.rideId);
  return successResponse(res, 'Ride chat messages fetched successfully.', data);
});

module.exports = {
  sendMessage,
  getChatMessagesByRide,
};