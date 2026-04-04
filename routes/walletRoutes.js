const express = require('express');
const router = express.Router();

const auth = require('../middlewares/authMiddleware');
const controller = require('../controllers/walletController');

router.use(auth);

router.get('/summary', controller.getWalletSummary);
router.post('/pay', controller.submitPayment);

module.exports = router;