const { successResponse, errorResponse } = require('../utils/apiResponse');
const service = require('../services/walletService');

const getWalletSummary = async (req, res) => {
  try {
    const data = await service.getWalletSummary(req.user.userId);
    return successResponse(res, 'Wallet summary', data);
  } catch (err) {
    return errorResponse(res, err.message, 500);
  }
};

const submitPayment = async (req, res) => {
  try {
    const { method, transactionId, amount } = req.body;

    const data = await service.submitPayment({
      userId: req.user.userId,
      method,
      transactionId,
      amount,
    });

    return successResponse(res, 'Payment submitted', data);
  } catch (err) {
    return errorResponse(res, err.message, 400);
  }
};

module.exports = {
  getWalletSummary,
  submitPayment,
};