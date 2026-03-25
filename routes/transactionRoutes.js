const express = require('express');
const router = express.Router();
const transactionController = require('../controllers/transactionController');
const authMiddleware = require('../middlewares/authMiddleware');
const { validateRequiredFields } = require('../middlewares/validateMiddleware');

router.post(
  '/',
  authMiddleware,
  validateRequiredFields(['amount', 'type', 'method']),
  transactionController.createPaymentRecord
);

router.get('/my', authMiddleware, transactionController.listMyTransactions);
router.get('/due-balance', authMiddleware, transactionController.fetchDueBalance);
router.get('/wallet-status', authMiddleware, transactionController.walletPaymentStatus);

module.exports = router;