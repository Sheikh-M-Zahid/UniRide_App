const express = require('express');
const router = express.Router();
const sendItemController = require('../controllers/sendItemController');
const authMiddleware = require('../middlewares/authMiddleware');
const { validateRequiredFields } = require('../middlewares/validateMiddleware');

router.post(
  '/',
  authMiddleware,
  validateRequiredFields(['receiver_email', 'item_type', 'sender_name', 'sender_phone']),
  sendItemController.createSendItemRequest
);

router.get('/', authMiddleware, sendItemController.listSendItemRequests);
router.patch('/:sId/accept', authMiddleware, sendItemController.acceptItemRequest);
router.patch('/:sId/cancel', authMiddleware, sendItemController.cancelItemRequest);
router.patch('/:sId/deliver', authMiddleware, sendItemController.deliverItemRequest);

module.exports = router;