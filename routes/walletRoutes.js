const express = require('express');
const router = express.Router();

const walletController = require('../controllers/walletController');
const authMiddleware = require('../middlewares/authMiddleware');

router.get('/summary', authMiddleware, walletController.getWalletSummary);
router.post('/pay-due', authMiddleware, walletController.payDue);

module.exports = router;