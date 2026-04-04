const { successResponse } = require('../utils/apiResponse');
const service = require('../services/walletService');

const getPendingPayments = async (req, res) => {
  const data = await service.getPendingPayments();
  return successResponse(res, 'Pending payments', data);
};

const verifyPayment = async (req, res) => {
  const data = await service.verifyPayment(req.params.id);
  return successResponse(res, 'Payment verified', data);
};

const rejectPayment = async (req, res) => {
  const data = await service.rejectPayment(req.params.id);
  return successResponse(res, 'Payment rejected', data);
};

module.exports = {
  getPendingPayments,
  verifyPayment,
  rejectPayment,
};