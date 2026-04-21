const asyncHandler = require('../utils/asyncHandler');
const { successResponse, errorResponse } = require('../utils/apiResponse');
const offerService = require('../services/offerService');

// Get all active offers
const getActiveOffers = asyncHandler(async (req, res) => {
  const data = await offerService.getActiveOffers();

  const message =
    data.length > 0
      ? 'Active offers fetched successfully.'
      : 'No offers available right now.';

  return successResponse(res, message, data);
});

// Apply / validate promo code
const applyOffer = asyncHandler(async (req, res) => {
  const { promo_code } = req.body;

  if (!promo_code || promo_code.trim() === '') {
    return errorResponse(res, 'Promo code is required.', 400);
  }

  try {
    const data = await offerService.applyOffer(promo_code.trim());

    return successResponse(res, 'Offer code applied successfully.', data);
  } catch (err) {
    return errorResponse(res, err.message, 400);
  }
});

// Get active offers count
const getActiveOffersCount = asyncHandler(async (req, res) => {
  // Create offer (ADMIN)
  const createOffer = asyncHandler(async (req, res) => {
    const {
      offer_name,
      offer_type,
      reward_percentage,
      eligible_user,
      start_date,
      end_date,
      promo_code,
      conditions,
    } = req.body;

    const data = await offerService.createOffer({
      offer_name,
      offer_type,
      reward_percentage,
      eligible_user,
      start_date,
      end_date,
      promo_code,
      conditions,
    });

    return successResponse(res, 'Offer created successfully.', data);
  });
  const count = await offerService.getActiveOffersCount();

  return successResponse(
    res,
    'Active offer count fetched successfully.',
    { offerCount: count }
  );
});

module.exports = {
  getActiveOffers,
  applyOffer,
  getActiveOffersCount,
  createOffer,
};
