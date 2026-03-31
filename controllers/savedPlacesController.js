const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/apiResponse');
const savedPlacesService = require('../services/savedPlacesService');

const getSavedPlaces = asyncHandler(async (req, res) => {
  const data = await savedPlacesService.getSavedPlaces(req.user.userId);

  return successResponse(
    res,
    'Saved places fetched successfully',
    data
  );
});

const updateSavedPlaces = asyncHandler(async (req, res) => {
  await savedPlacesService.updateSavedPlaces(req.user.userId, req.body);

  return successResponse(
    res,
    'Saved places updated successfully'
  );
});

module.exports = {
  getSavedPlaces,
  updateSavedPlaces,
};