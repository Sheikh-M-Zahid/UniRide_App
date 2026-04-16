const asyncHandler = require('../utils/asyncHandler');
const { successResponse, errorResponse } = require('../utils/apiResponse');
const mapsService = require('../services/mapsService');

const autocomplete = asyncHandler(async (req, res) => {
  const { input } = req.query;

  if (!input || !String(input).trim()) {
    return errorResponse(res, 'input is required.', 400);
  }

  const data = await mapsService.autocomplete(String(input).trim());

  return successResponse(res, 'Autocomplete fetched successfully.', data);
});

const placeDetails = asyncHandler(async (req, res) => {
  const { placeId } = req.query;

  if (!placeId || !String(placeId).trim()) {
    return errorResponse(res, 'placeId is required.', 400);
  }

  const data = await mapsService.getPlaceDetails(String(placeId).trim());

  return successResponse(res, 'Place details fetched successfully.', data);
});

const reverseGeocode = asyncHandler(async (req, res) => {
  const { lat, lng } = req.query;

  if (lat === undefined || lng === undefined) {
    return errorResponse(res, 'lat and lng are required.', 400);
  }

  const data = await mapsService.reverseGeocode({
    lat: Number(lat),
    lng: Number(lng),
  });

  return successResponse(res, 'Reverse geocode fetched successfully.', data);
});

module.exports = {
  autocomplete,
  placeDetails,
  reverseGeocode,
};