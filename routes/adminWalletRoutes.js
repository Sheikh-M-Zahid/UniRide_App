const express = require('express');
const router = express.Router();

const controller = require('../controllers/adminWalletController');

router.get('/pending-payments', controller.getPendingPayments);
router.post('/verify/:id', controller.verifyPayment);
router.post('/reject/:id', controller.rejectPayment);

module.exports = router;