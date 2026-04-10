const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/apiResponse');
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

module.exports = {
  getFaqs,
};