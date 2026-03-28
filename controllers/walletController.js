const asyncHandler = require('../utils/asyncHandler');
const { successResponse } = require('../utils/apiResponse');
const walletService = require('../services/walletService');

const getWalletSummary = asyncHandler(async (req, res) => {
  const data = await walletService.getWalletSummary(req.user.userId);

  return successResponse(
    res,
    'Wallet summary fetched successfully',
    data
  );
});

const payDue = asyncHandler(async (req, res) => {
  const data = await walletService.payDue(req.user.userId, req.body);

  return successResponse(
    res,
    'Due payment submitted successfully.',
    data
  );
});

module.exports = {
  getWalletSummary,
  payDue,
};