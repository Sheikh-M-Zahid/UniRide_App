const { successResponse, errorResponse } = require('../utils/apiResponse');
const adminPassengerService = require('../services/adminPassengerService');

const getAllPassengers = async (req, res) => {
  try {
    const {
      search = '',
      filter = 'all',
      page = 1,
      limit = 20,
    } = req.query;

    const data = await adminPassengerService.getAllPassengers({
      search,
      filter,
      page: Number(page),
      limit: Number(limit),
    });

    return successResponse(res, 'Passengers fetched successfully.', data);
  } catch (error) {
    console.error('getAllPassengers error:', error);
    return errorResponse(
      res,
      error.message || 'Failed to fetch passengers.',
      500
    );
  }
};

module.exports = {
  getAllPassengers,
};