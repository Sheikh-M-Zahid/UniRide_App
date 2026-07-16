const asyncHandler = require('../utils/asyncHandler');
const { successResponse, errorResponse } = require('../utils/apiResponse');
const offerService = require('../services/offerService');

//GET ACTIVE OFFERS
const getActiveOffers = asyncHandler(async (req, res) => {
  const userId = req.user?.user_id || req.user?.userId || null;
  const data = await offerService.getActiveOffers(userId);
  const message =
    data.length > 0
      ? 'Active offers fetched successfully.'
      : 'No offers available right now.';
  return successResponse(res, message, data);
});

//APPLY PROMO CODE
const applyOffer = asyncHandler(async (req, res) => {
  const { promo_code, fare, ride_type } = req.body;
  const userId = req.user?.user_id;

  if (!promo_code || promo_code.trim() === '') {
    return errorResponse(res, 'Promo code is required.', 400);
  }
  if (!userId) {
    return errorResponse(res, 'User authentication required.', 401);
  }

  try {
    const data = await offerService.applyOffer(
      promo_code.trim(),
      userId,
      fare ? parseFloat(fare) : null,
      ride_type || 'ride'
    );
    return successResponse(res, 'Offer code applied successfully.', data);
  } catch (err) {
    return errorResponse(res, err.message, 400);
  }
});

//CREATE OFFER (ADMIN)
const createOffer = asyncHandler(async (req, res) => {
  // ✅ নতুন fields সহ destructure
  const {
    offer_name,
    offer_type,
    offer_category,
    reward_percentage,
    eligible_user,
    start_date,
    end_date,
    promo_code,
    conditions,
    usage_limit_type,
    condition_type,
    condition_value,
    eligible_ride_type,
    max_total_uses,
  } = req.body;

  // ✅ validation আগে, service call পরে
  if (
    !offer_name ||
    !offer_type ||
    reward_percentage === undefined ||
    !eligible_user ||
    !start_date ||
    !end_date ||
    !promo_code
  ) {
    return errorResponse(res, 'All required offer fields must be provided.', 400);
  }

  // ✅ bonus offer এর জন্য নতুন validation
  if (offer_category === 'bonus' && !max_total_uses) {
    return errorResponse(res, 'Bonus offer must have max_total_uses defined.', 400);
  }

  // ✅ নতুন fields সহ service call
  const data = await offerService.createOffer({
    offer_name, offer_type, offer_category,
    reward_percentage, eligible_user,
    start_date, end_date, promo_code, conditions,
    usage_limit_type, condition_type,
    condition_value, eligible_ride_type, max_total_uses,
  });

  return successResponse(res, 'Offer created successfully.', data);
});

//GET ACTIVE OFFER COUNT
const getActiveOffersCount = asyncHandler(async (req, res) => {
  const count = await offerService.getActiveOffersCount();
  return successResponse(
    res,
    'Active offer count fetched successfully.',
    { offerCount: count }
  );
});

//GET RECENT OFFERS (active + expired within 30 days)
const getRecentOffers = asyncHandler(async (req, res) => {
  const userId = req.user?.user_id || req.user?.userId || null;
  const data = await offerService.getRecentOffers(userId);
  const message =
    data.length > 0
      ? 'Recent offers fetched successfully.'
      : 'No offers found.';
  return successResponse(res, message, data);
});

//EXPORTS
module.exports = {
  getActiveOffers,
  applyOffer,
  createOffer,
  getActiveOffersCount,
  getRecentOffers,
};
