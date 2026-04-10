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

// Get active offers count
const getActiveOffersCount = asyncHandler(async (req, res) => {
  const count = await offerService.getActiveOffersCount();

  return successResponse(
    res,
    'Active offer count fetched successfully.',
    { offerCount: count }
  );
});

// Apply / validate promo code
const applyOffer = asyncHandler(async (req, res) => {
  const { promo_code, fare } = req.body;
  const user = req.user;

  if (!promo_code || promo_code.trim() === '') {
    return errorResponse(res, 'Promo code is required.', 400);
  }

  if (fare === undefined || fare === null || Number(fare) <= 0) {
    return errorResponse(res, 'Valid fare is required.', 400);
  }

  try {
    const data = await offerService.applyOffer({
      promoCode: promo_code.trim(),
      fare: Number(fare),
      user,
    });

    return successResponse(res, 'Offer code applied successfully.', data);
  } catch (err) {
    return errorResponse(res, err.message, 400);
  }
});

// Admin: create offer
const createOffer = asyncHandler(async (req, res) => {
  try {
    const data = await offerService.createOffer(req.body);

    return successResponse(res, 'Offer created successfully.', data, 201);
  } catch (err) {
    return errorResponse(res, err.message, 400);
  }
});

// Admin: get all offers
const getAllOffers = asyncHandler(async (req, res) => {
  const data = await offerService.listOffers();

  return successResponse(res, 'All offers fetched successfully.', data);
});

module.exports = {
  getActiveOffers,
  getActiveOffersCount,
  applyOffer,
  createOffer,
  getAllOffers,
};