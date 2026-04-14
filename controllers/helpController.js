const asyncHandler = require('../utils/asyncHandler');
const { successResponse, errorResponse } = require('../utils/apiResponse');
const helpService = require('../services/helpService');

const getFaqs = asyncHandler(async (req, res) => {
  const faqs = await helpService.getFaqs();

  return successResponse(
    res,
    faqs.length
      ? 'Help FAQs fetched successfully'
      : 'No help FAQs found',
    faqs
  );
});

const submitHelpRequest = asyncHandler(async (req, res) => {
  try {
    const data = await helpService.submitHelpRequest({
      userId: req.user.userId,
      message: req.body.message,
    });

    return successResponse(
      res,
      'Help request submitted successfully',
      data,
      201
    );
  } catch (error) {
    return errorResponse(
      res,
      error.message || 'Failed to submit help request',
      400
    );
  }
});

module.exports = {
  getFaqs,
  submitHelpRequest,
};
