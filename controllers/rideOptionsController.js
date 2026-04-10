const { successResponse, errorResponse } = require('../utils/apiResponse');
const rideOptionsService = require('../services/rideOptionsService');

const getRideOptions = async (req, res) => {
  try {
    const data = await rideOptionsService.getRideOptions({
      body: req.body,
      user: req.user,
    });

    return successResponse(
      res,
      'Ride options fetched successfully.',
      data
    );
  } catch (error) {
    console.error('getRideOptions error:', error);
    return errorResponse(
      res,
      error.message || 'Failed to fetch ride options.',
      400
    );
  }
};

module.exports = {
  getRideOptions,
};