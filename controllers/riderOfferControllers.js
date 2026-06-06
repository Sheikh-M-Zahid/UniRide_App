const asyncHandler = require('../utils/asyncHandler');
const { successResponse, errorResponse } = require('../utils/apiResponse');
const riderOfferService = require('../services/riderOfferServices');

//GET RIDER OFFERS
const getRiderOffers = asyncHandler(async (req, res) => {
  const data = await riderOfferService.getOffersForRider();

  const message =
    data.length > 0
      ? 'Offers fetched successfully.'
      : 'No offers available right now.';

  return successResponse(res, message, data);
});

module.exports = {
  getRiderOffers,
};
