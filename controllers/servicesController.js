const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/apiResponse');
const servicesService = require('../services/servicesService');

const getServicesSummary = asyncHandler(async (req, res) => {
  const data = await servicesService.getServicesSummary();

  const message = data.hasAdminOffer
    ? 'Services summary fetched successfully'
    : 'No active offer found';

  return successResponse(res, message, data);
});

module.exports = {
  getServicesSummary,
};