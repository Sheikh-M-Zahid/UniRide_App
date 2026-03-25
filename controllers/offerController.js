const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/apiResponse');
const offerService = require('../services/offerService');

const getActiveOffers = asyncHandler(async (req, res) => {
  const data = await offerService.getActiveOffers();
  return successResponse(res, 'Active offers fetched successfully.', data);
});

const validatePromoCode = asyncHandler(async (req, res) => {
  const data = await offerService.validatePromoCode(req.body.promo_code);
  return successResponse(res, 'Promo code is valid.', data);
});

module.exports = {
  getActiveOffers,
  validatePromoCode,
};