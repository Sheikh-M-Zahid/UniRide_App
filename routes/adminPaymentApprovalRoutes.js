const express = require('express');
const router = express.Router();

const adminAuthMiddleware = require('../middlewares/adminAuthMiddleware');
const adminPaymentApprovalController = require('../controllers/adminPaymentApprovalController');

router.use(adminAuthMiddleware);

router.get('/', adminPaymentApprovalController.getPaymentRequests);
router.patch('/:paymentDbId/confirm', adminPaymentApprovalController.confirmPayment);
router.patch('/:paymentDbId/decline', adminPaymentApprovalController.declinePayment);

module.exports = router;