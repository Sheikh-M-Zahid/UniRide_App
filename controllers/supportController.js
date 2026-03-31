const asyncHandler = require('../utils/asyncHandler');
const { successResponse, errorResponse } = require('../utils/apiResponse');
const supportService = require('../services/supportService');

const submitHelpRequest = asyncHandler(async (req, res) => {
  const { message } = req.body;

  if (!message || message.trim() === '') {
    return errorResponse(res, 'Message is required.', 400);
  }

  await supportService.submitHelpRequest(
    req.user.userId,
    req.user.email,
    message.trim()
  );

  return successResponse(res, 'Help request submitted successfully.');
});

const getMyRequests = asyncHandler(async (req, res) => {
  const data = await supportService.getMyRequests(req.user.userId);

  return successResponse(res, 'Help requests fetched successfully.', data);
});

module.exports = {
  submitHelpRequest,
  getMyRequests,
};