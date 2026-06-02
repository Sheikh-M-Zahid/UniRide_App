const express = require('express');
const router = express.Router();

const authMiddleware = require('../middlewares/authMiddleware');
const riderDeliveryController = require('../controllers/riderDeliveryController');

router.use(authMiddleware);

router.get('/dashboard', riderDeliveryController.getDashboard);

router.post('/requests/:id/accept', riderDeliveryController.acceptRequest);
router.post('/requests/:id/reject', riderDeliveryController.rejectRequest);

// ওটিপি জেনারেশন এবং সাবমিট রাউটস
router.post('/:id/send-otp', riderDeliveryController.sendDeliveryOTP);
router.post('/:id/mark-delivered', riderDeliveryController.markDelivered);
router.post('/:id/mark-picked-up', riderDeliveryController.markPickedUp);

module.exports = router;
